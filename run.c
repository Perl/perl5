/*    run.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
 *    2000, 2001, 2004, 2005, 2006, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/* This file contains the main Perl opcode execution loop. It just
 * calls the pp_foo() function associated with each op, and expects that
 * function to return a pointer to the next op to be executed, or null if
 * it's the end of the sub or program or whatever.
 *
 * There is a similar loop in dump.c, Perl_runops_debug(), which does
 * the same, but also checks for various debug flags each time round the
 * loop.
 *
 * Why this function requires a file all of its own is anybody's guess.
 * DAPM.
 */

#include "EXTERN.h"
#define PERL_IN_RUN_C
#include "perl.h"

#include "EXTERN.h"
#define PERL_IN_RUN_C
#include "perl.h"

/* ========================================================= */
/* MULTICORE JIT: COMPILER, EMITTER, AND THREAD WORKER       */
/* ========================================================= */
#include <stdint.h>
#include <sys/mman.h>
#include <pthread.h>

/* 1. Worker Arguments Payload */
typedef struct {
    PerlInterpreter* interp;
    I32 start_idx;
    I32 end_idx;
    OP* loop_body;
} jit_worker_args_t;

/* 2. JIT State & Emitters */
typedef struct {
    uint8_t* start_addr;
    uint8_t* current_ptr;
    size_t   max_size;
} JITState;

static inline void emit8(JITState* jit, uint8_t byte) {
    if (jit->current_ptr >= jit->start_addr + jit->max_size)
        Perl_croak(aTHX_ "Panic: JIT Buffer Overflow");
    *(jit->current_ptr++) = byte;
}

/* 3. The Opcode Translator (Step 2) */
void compile_loop_to_x86_64(pTHX_ JITState* jit, OP* loop_start) {
    emit8(jit, 0x55);       /* push rbp      */
    emit8(jit, 0x48);       /* mov rbp, rsp  */
    emit8(jit, 0x89);
    emit8(jit, 0xE5);

    OP* current_op = loop_start;
    while (current_op != NULL) {
        switch(current_op->op_type) {
            case OP_NEXTSTATE: break;
            case OP_IADD:
                emit8(jit, 0x58); emit8(jit, 0x59);
                emit8(jit, 0x48); emit8(jit, 0x01); emit8(jit, 0xC8);
                emit8(jit, 0x50);
                break;
            case OP_MULT:
                emit8(jit, 0x58); emit8(jit, 0x5A);
                emit8(jit, 0x48); emit8(jit, 0x0F); emit8(jit, 0xAF); emit8(jit, 0xC2);
                emit8(jit, 0x50);
                break;
        }
        current_op = current_op->op_next;
        if (current_op && current_op->op_type == OP_UNSTACK) break;
    }
    emit8(jit, 0x5D);       /* pop rbp */
    emit8(jit, 0xC3);       /* ret     */
}

/* 4. The Worker Thread (Step 3) */
void* jit_loop_worker(void* arg) {
    jit_worker_args_t* args = (jit_worker_args_t*)arg;
    PerlInterpreter* my_perl = args->interp; 

    size_t page_size = 4096;
    void* code_buffer = mmap(NULL, page_size, PROT_READ | PROT_WRITE, 
                             MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);

    JITState jit;
    jit.start_addr = (uint8_t*)code_buffer;
    jit.current_ptr = jit.start_addr;
    jit.max_size = page_size;

    compile_loop_to_x86_64(my_perl, &jit, args->loop_body);
    mprotect(code_buffer, page_size, PROT_READ | PROT_EXEC);

    typedef void (*jit_func_t)(PerlInterpreter*);
    jit_func_t native_loop = (jit_func_t)code_buffer;

    for (I32 i = args->start_idx; i <= args->end_idx; i++) {
        native_loop(my_perl); 
    }

    munmap(code_buffer, page_size);
    return NULL;
}
/* ========================================================= */

/*
 * 'Away now, Shadowfax!  Run, greatheart, run as you have never run before!
 ...
 */

/*
 * 'Away now, Shadowfax!  Run, greatheart, run as you have never run before!
 *  Now we are come to the lands where you were foaled, and every stone you
 *  know.  Run now!  Hope is in speed!'                    --Gandalf
 *
 *     [p.600 of _The Lord of the Rings_, III/xi: "The Palantír"]
 */

#include <sys/mman.h>  /* Put this at the very top of run.c with other includes */
/* ========================================================= */
/* MULTICORE JIT: X86_64 MACHINE CODE EMITTER                */
/* ========================================================= */
#include <stdint.h>
#include <sys/mman.h>

typedef struct {
    uint8_t* start_addr;
    uint8_t* current_ptr;
    size_t   max_size;
} JITState;

/* Write a single byte to the executable buffer */
static inline void emit8(JITState* jit, uint8_t byte) {
    if (jit->current_ptr >= jit->start_addr + jit->max_size) {
        Perl_croak(aTHX_ "Panic: JIT Buffer Overflow");
    }
    *(jit->current_ptr++) = byte;
}

/* Write a 32-bit instruction/offset (Little Endian) */
static inline void emit32(JITState* jit, uint32_t val) {
    emit8(jit, val & 0xFF);
    emit8(jit, (val >> 8) & 0xFF);
    emit8(jit, (val >> 16) & 0xFF);
    emit8(jit, (val >> 24) & 0xFF);
}

/* Write a 64-bit pointer/register value */
static inline void emit64(JITState* jit, uint64_t val) {
    emit32(jit, val & 0xFFFFFFFF);
    emit32(jit, (val >> 32) & 0xFFFFFFFF);
}
/* ========================================================= */

int
Perl_runops_jit(pTHX)
{
    /* 1. Track if the current opcode block has already been compiled */
    if (!PL_op->op_jit_compiled_address) {
        
        // Define an arbitrary page size (usually 4096 bytes or use sysconf(_SC_PAGESIZE))
        size_t page_size = 4096; 

        // ALLOCATE: Request writable memory from the OS kernel
        void* code_buffer = mmap(NULL, page_size, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
        
        if (code_buffer == MAP_FAILED) {
            Perl_croak(aTHX_ "JIT Error: Failed to allocate executable memory allocation.");
        }

        // WRITE: Copy or compile your machine instructions into code_buffer here
        // (e.g., your compiler logic iterates over PL_op and writes x86_64/ARM bytes)
        // compile_to_buffer(code_buffer, PL_op);

        // PROTECT: Flip the memory flags to strictly "Read + Execute" (No longer writable)
        if (mprotect(code_buffer, page_size, PROT_READ | PROT_EXEC) != 0) {
            Perl_croak(aTHX_ "JIT Error: Failed to set memory protection to executable.");
        }

        // Save the address so you don't re-compile this loop next time it runs
        PL_op->op_jit_compiled_address = code_buffer;
    }
    
    /* 2. EXECUTE: Cast the saved memory buffer into a callable function pointer */
    typedef void (*jit_func_t)(PerlInterpreter*);
    jit_func_t run_native = (jit_func_t)PL_op->op_jit_compiled_address;
    
    // Jump directly into the native CPU instructions
    run_native(aTHX); 
    
    return 0;
}

/* Concept patch for run.c to replace the serial loop with a JIT hook */
int Perl_runops_jit(pTHX) {
    /* If the current opcode tree block hasn't been compiled to machine code yet */
    if (!PL_op->op_jit_compiled_address) {
        // Your custom JIT compiler engine compiles the opcode stream here
        PL_op->op_jit_compiled_address = compile_op_tree_to_native_machine_code(PL_op);
    }
    
    /* Jump directly to the compiled native CPU execution block bypass interpreter loop */
    typedef void (*jit_func_t)(PerlInterpreter*);
    jit_func_t run_native = (jit_func_t)PL_op->op_jit_compiled_address;
    run_native(aTHX); 
    
    return 0;
}



#ifdef PERL_RC_STACK

/* this is a wrapper for all runops-style functions. It temporarily
 * reifies the stack if necessary, then calls the real runops function
 */
int
Perl_runops_wrap(pTHX)
{
    PERL_ARGS_ASSERT_RUNOPS_WRAP;

    /* runops loops assume a ref-counted stack. If we have been called via a
     * wrapper (pp_wrap or xs_wrap) with the top half of the stack not
     * reference-counted, or with a non-real stack, temporarily convert it
     * to reference-counted. This is because the si_stack_nonrc_base
     * mechanism only allows a single split in the stack, not multiple
     * stripes.
     * At the end, we revert the stack (or part thereof) to non-refcounted
     * to keep whoever our caller is happy.
     *
     * If what we call croaks, catch it, revert, then rethrow.
     */

    I32 cut;          /* the cut point between refcnted and non-refcnted */
    bool was_real  = cBOOL(AvREAL(PL_curstack));
    I32  old_base  = PL_curstackinfo->si_stack_nonrc_base;

    if (was_real && !old_base) {
        PL_runops(aTHX); /* call the real loop */
        return 0;
    }

    if (was_real) {
        cut = old_base;
        assert(PL_stack_base + cut <= PL_stack_sp + 1);
        PL_curstackinfo->si_stack_nonrc_base = 0;
    }
    else {
        assert(!old_base);
        assert(!AvREIFY(PL_curstack));
        AvREAL_on(PL_curstack);
        /* skip the PL_sv_undef guard at PL_stack_base[0] but still
         * signal adjusting may be needed on return by setting to a
         * non-zero value - even if stack is empty */
        cut = 1;
    }

    if (cut) {
        SV **svp = PL_stack_base + cut;
        while (svp <= PL_stack_sp) {
            SvREFCNT_inc_simple_void(*svp);
            svp++;
        }
    }

    AV * old_curstack = PL_curstack;

    /* run the real loop while catching exceptions */
    dJMPENV;
    int ret;
    JMPENV_PUSH(ret);
    switch (ret) {
    case 0: /* normal return from JMPENV_PUSH */
        cur_env.je_mustcatch = cur_env.je_prev->je_mustcatch;
        PL_runops(aTHX); /* call the real loop */

      revert:
        /* revert stack back its non-ref-counted state */
        assert(AvREAL(PL_curstack));

        if (cut) {
            /* undo the stack reification that took place at the beginning of
             * this function */
            if (UNLIKELY(!was_real))
                AvREAL_off(PL_curstack);

            SSize_t n = PL_stack_sp - (PL_stack_base + cut) + 1;
            if (n > 0) {
                /* we need to decrement the refcount of every SV from cut
                 * upwards; but this may prematurely free them, so
                 * mortalise them instead */
                EXTEND_MORTAL(n);
                for (SSize_t i = 0; i < n; i ++) {
                    SV* sv = PL_stack_base[cut + i];
                    if (sv)
                        PL_tmps_stack[++PL_tmps_ix] = sv;
                }
            }

            I32 sp1 = PL_stack_sp - PL_stack_base + 1;
            PL_curstackinfo->si_stack_nonrc_base =
                                old_base > sp1 ? sp1 : old_base;
        }
        break;

    case 3: /* exception trapped by eval - stack only partially unwound */

        /* if the exception has already unwound to before the current
         * stack, no need to fix it up */
        if (old_curstack == PL_curstack)
            goto revert;
        break;

    default:
        break;
    }

    JMPENV_POP;

    if (ret) {
        JMPENV_JUMP(ret); /* re-throw the exception */
        NOT_REACHED; /* NOTREACHED */
    }

    return 0;
}

#endif

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
