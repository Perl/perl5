#define SAVEt_ITEM	0
#define SAVEt_SV	1
#define SAVEt_AV	2
#define SAVEt_HV	3
#define SAVEt_INT	4
#define SAVEt_LONG	5
#define SAVEt_I32	6
#define SAVEt_IV	7
#define SAVEt_SPTR	8
#define SAVEt_APTR	9
#define SAVEt_HPTR	10
#define SAVEt_PPTR	11
#define SAVEt_NSTAB	12
#define SAVEt_SVREF	13
#define SAVEt_GP	14
#define SAVEt_FREESV	15
#define SAVEt_FREEOP	16
#define SAVEt_FREEPV	17
#define SAVEt_CLEARSV	18
#define SAVEt_DELETE	19
#define SAVEt_DESTRUCTOR 20
#define SAVEt_REGCONTEXT 21
#define SAVEt_STACK_POS  22
#define SAVEt_I16	23
#define SAVEt_AELEM     24
#define SAVEt_HELEM     25
#define SAVEt_OP	26

#define SSCHECK(need) if (savestack_ix + need > savestack_max) savestack_grow()
#define SSPUSHINT(i) (savestack[savestack_ix++].any_i32 = (I32)(i))
#define SSPUSHLONG(i) (savestack[savestack_ix++].any_long = (long)(i))
#define SSPUSHIV(i) (savestack[savestack_ix++].any_iv = (IV)(i))
#define SSPUSHPTR(p) (savestack[savestack_ix++].any_ptr = (void*)(p))
#define SSPUSHDPTR(p) (savestack[savestack_ix++].any_dptr = (p))
#define SSPOPINT (savestack[--savestack_ix].any_i32)
#define SSPOPLONG (savestack[--savestack_ix].any_long)
#define SSPOPIV (savestack[--savestack_ix].any_iv)
#define SSPOPPTR (savestack[--savestack_ix].any_ptr)
#define SSPOPDPTR (savestack[--savestack_ix].any_dptr)

#define SAVETMPS save_int((int*)&tmps_floor), tmps_floor = tmps_ix
#define FREETMPS if (tmps_ix > tmps_floor) free_tmps()

#ifdef DEBUGGING
#define ENTER							\
    STMT_START {						\
	push_scope();						\
	DEBUG_l(WITH_THR(deb("ENTER scope %ld at %s:%d\n",	\
		    scopestack_ix, __FILE__, __LINE__)));	\
    } STMT_END
#define LEAVE							\
    STMT_START {						\
	DEBUG_l(WITH_THR(deb("LEAVE scope %ld at %s:%d\n",	\
		    scopestack_ix, __FILE__, __LINE__)));	\
	pop_scope();						\
    } STMT_END
#else
#define ENTER push_scope()
#define LEAVE pop_scope()
#endif
#define LEAVE_SCOPE(old) if (savestack_ix > old) leave_scope(old)

/*
 * Not using SOFT_CAST on SAVEFREESV and SAVEFREESV
 * because these are used for several kinds of pointer values
 */
#define SAVEI16(i)	save_I16(SOFT_CAST(I16*)&(i))
#define SAVEI32(i)	save_I32(SOFT_CAST(I32*)&(i))
#define SAVEINT(i)	save_int(SOFT_CAST(int*)&(i))
#define SAVEIV(i)	save_iv(SOFT_CAST(IV*)&(i))
#define SAVELONG(l)	save_long(SOFT_CAST(long*)&(l))
#define SAVESPTR(s)	save_sptr((SV**)&(s))
#define SAVEPPTR(s)	save_pptr(SOFT_CAST(char**)&(s))
#define SAVEFREESV(s)	save_freesv((SV*)(s))
#define SAVEFREEOP(o)	save_freeop(SOFT_CAST(OP*)(o))
#define SAVEFREEPV(p)	save_freepv(SOFT_CAST(char*)(p))
#define SAVECLEARSV(sv)	save_clearsv(SOFT_CAST(SV**)&(sv))
#define SAVEDELETE(h,k,l) \
	  save_delete(SOFT_CAST(HV*)(h), SOFT_CAST(char*)(k), (I32)(l))
#ifdef PERL_OBJECT
#define CALLDESTRUCTOR this->*SSPOPDPTR
#define SAVEDESTRUCTOR(f,p) \
	  save_destructor((DESTRUCTORFUNC)(FUNC_NAME_TO_PTR(f)),	\
			  SOFT_CAST(void*)(p))
#else
#define CALLDESTRUCTOR *SSPOPDPTR
#define SAVEDESTRUCTOR(f,p) \
	  save_destructor(SOFT_CAST(void(*)_((void*)))(FUNC_NAME_TO_PTR(f)), \
			  SOFT_CAST(void*)(p))
#endif
#define SAVESTACK_POS() STMT_START {	\
    SSCHECK(2);				\
    SSPUSHINT(stack_sp - stack_base);	\
    SSPUSHINT(SAVEt_STACK_POS);		\
 } STMT_END
#define SAVEOP()	save_op()

/* A jmpenv packages the state required to perform a proper non-local jump.
 * Note that there is a start_env initialized when perl starts, and top_env
 * points to this initially, so top_env should always be non-null.
 *
 * Existence of a non-null top_env->je_prev implies it is valid to call
 * (*je_jump)() at that runlevel.  Always use the macros below!  They
 * manage most of the complexity for you.
 *
 * je_mustcatch, when set at any runlevel to TRUE, means eval ops must
 * establish a local jmpenv to handle exception traps.  Care must be taken
 * to restore the previous value of je_mustcatch before exiting the
 * stack frame iff JMPENV_PUSH was not called in that stack frame.
 *
 * The support for C++ try/throw causes a small loss of flexibility.
 * No longer is it possible to place the body of exception-protected
 * code in the same C function as JMPENV_PUSH &etc.  Older code that
 * does this will continue to work with set/longjmp, but cannot use
 * C++ exceptions.
 *
 * GSAR  19970327
 * JPRIT 19980613 (C++ update)
 */

#define JMP_NORMAL	0
#define JMP_ABNORMAL	1	/* shouldn't happen */
#define JMP_MYEXIT	2	/* exit */
#define JMP_EXCEPTION	3	/* die */

/* None of the JMPENV fields should be accessed directly.
   Please use the macros below! */
struct jmpenv {
    struct jmpenv *	je_prev;
    int			je_stat;	/* JMP_* reason for setjmp() */
    bool		je_mustcatch;	/* will need a new TRYBLOCK? */
    void		(*je_jump) _((CPERLproto));
};
typedef struct jmpenv JMPENV;

struct tryvtbl {
    /* [0] executed before JMPENV_POP
       [1] executed after JMPENV_POP
           (NULL pointers are OK) */
    char *try_context;
    void (*try_normal    [2]) _((CPERLproto_ void*));
    void (*try_abnormal  [2]) _((CPERLproto_ void*));
    void (*try_exception [2]) _((CPERLproto_ void*));
    void (*try_myexit    [2]) _((CPERLproto_ void*));
};
typedef struct tryvtbl TRYVTBL;

typedef void (*tryblock_f) _((CPERLproto_ TRYVTBL *vtbl, void *locals));
#define TRYBLOCK(mytry,vars) \
	(*tryblock_function)(PERL_OBJECT_THIS_ &mytry, &vars)

#ifdef OP_IN_REGISTER
#define OP_REG_TO_MEM	opsave = op
#define OP_MEM_TO_REG	op = opsave
#else
#define OP_REG_TO_MEM	NOOP
#define OP_MEM_TO_REG	NOOP
#endif

#define JMPENV_TOPINIT(top)			\
STMT_START {					\
    top.je_prev = NULL;				\
    top.je_stat = JMP_ABNORMAL;			\
    top.je_mustcatch = TRUE;			\
    top_env = &top;				\
} STMT_END

#define JMPENV_INIT(env, jmp)			\
STMT_START {					\
    ((JMPENV*)&env)->je_prev = top_env;		\
    ((JMPENV*)&env)->je_stat = JMP_NORMAL;	\
    ((JMPENV*)&env)->je_jump = jmp;		\
    OP_REG_TO_MEM;				\
} STMT_END

#define JMPENV_TRY(env)				\
STMT_START {					\
    OP_MEM_TO_REG;				\
    ((JMPENV*)&env)->je_mustcatch = FALSE;	\
    top_env = (JMPENV*)&env;			\
} STMT_END

#define JMPENV_POP_JE(env)			\
STMT_START {					\
	assert(top_env == (JMPENV*)&env);	\
	top_env = ((JMPENV*)&env)->je_prev;	\
} STMT_END

#define JMPENV_STAT(env) ((JMPENV*)&env)->je_stat

#define JMPENV_JUMP(v) \
    STMT_START {						\
	assert((v) != JMP_NORMAL);				\
	OP_REG_TO_MEM;						\
	if (top_env->je_prev) {					\
	    top_env->je_stat = (v);				\
	    (*top_env->je_jump)(PERL_OBJECT_THIS);		\
	}							\
	if ((v) == JMP_MYEXIT)					\
	    PerlProc_exit(STATUS_NATIVE_EXPORT);		\
	PerlIO_printf(PerlIO_stderr(), no_top_env);		\
	PerlProc_exit(1);					\
    } STMT_END
   
#define CATCH_GET	(top_env->je_mustcatch)
#define CATCH_SET(v)	(top_env->je_mustcatch = (v))



/*******************************************************************
 * JMPENV_PUSH is the old depreciated API.  See perl.c for examples
 *  of the new API.
 */

struct setjmpenv {
    /* move to scope.c once JMPENV_PUSH is no longer needed XXX */
    JMPENV		je0;
    Sigjmp_buf		je_buf;		
};
typedef struct setjmpenv SETJMPENV;

#define dJMPENV		SETJMPENV cur_env

extern void setjmp_jump();

#define JMPENV_PUSH(v) \
    STMT_START {					\
	JMPENV_INIT(cur_env, setjmp_jump);		\
	PerlProc_setjmp(cur_env.je_buf, 1);		\
	JMPENV_TRY(cur_env);				\
	(v) = JMPENV_STAT(cur_env);			\
    } STMT_END

#define JMPENV_POP				\
STMT_START {					\
	assert(top_env == (JMPENV*) &cur_env);	\
	top_env = cur_env.je0.je_prev;		\
} STMT_END

