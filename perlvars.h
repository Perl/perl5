/* This file describes the "global" variables used by perl  */
/* This used to be in perl.h directly but we want to        */
/* abstract out which are per-thread per-interpreter really */
/* global and how initialized into one file                 */

/****************/
/* Truly global */
/****************/

/* global state */
PERLVAR(curinterp,	PerlInterpreter *)		/* currently running interpreter */
#ifdef USE_THREADS
PERLVAR(thr_key,	perl_key)		/* For per-thread struct perl_thread* */
PERLVAR(sv_mutex,	perl_mutex)		/* Mutex for allocating SVs in sv.c */
PERLVAR(malloc_mutex,	perl_mutex)		/* Mutex for malloc */
PERLVAR(eval_mutex,	perl_mutex)		/* Mutex for doeval */
PERLVAR(eval_cond,	perl_cond)		/* Condition variable for doeval */
PERLVAR(eval_owner,	struct perl_thread *)		/* Owner thread for doeval */
PERLVAR(nthreads,	int)		/* Number of threads currently */
PERLVAR(threads_mutex,	perl_mutex)		/* Mutex for nthreads and thread list */
PERLVAR(nthreads_cond,	perl_cond)		/* Condition variable for nthreads */
PERLVARI(threadsv_names,	char *,	THREADSV_NAMES)	
#ifdef FAKE_THREADS
PERLVAR(thr,	struct perl_thread *)		/* Currently executing (fake) thread */
#endif
#endif /* USE_THREADS */

PERLVAR(uid,	int)		/* current real user id */
PERLVAR(euid,	int)		/* current effective user id */
PERLVAR(gid,	int)		/* current real group id */
PERLVAR(egid,	int)		/* current effective group id */
PERLVAR(nomemok,	bool)		/* let malloc context handle nomem */
PERLVAR(an,	U32)		/* malloc sequence number */
PERLVAR(cop_seqmax,	U32)		/* statement sequence number */
PERLVAR(op_seqmax,	U16)		/* op sequence number */
PERLVAR(evalseq,	U32)		/* eval sequence number */
PERLVAR(sub_generation,	U32)		/* inc to force methods to be looked up again */
PERLVAR(origenviron,	char **)		
PERLVAR(origalen,	U32)		
PERLVAR(pidstatus,	HV *)		/* pid-to-status mappings for waitpid */
PERLVAR(profiledata,	U32 *)		
PERLVARI(maxo,	int,	MAXO)	/* Number of ops */
PERLVAR(osname,	char *)		/* operating system */
PERLVARI(sh_path,	char *,	SH_PATH)	/* full path of shell */
PERLVAR(sighandlerp,	Sighandler_t)		

PERLVAR(xiv_arenaroot,	XPV*)		/* list of allocated xiv areas */
PERLVAR(xiv_root,	IV **)		/* free xiv list--shared by interpreters */
PERLVAR(xnv_root,	double *)		/* free xnv list--shared by interpreters */
PERLVAR(xrv_root,	XRV *)		/* free xrv list--shared by interpreters */
PERLVAR(xpv_root,	XPV *)		/* free xpv list--shared by interpreters */
PERLVAR(he_root,	HE *)		/* free he list--shared by interpreters */
PERLVAR(nice_chunk,	char *)		/* a nice chunk of memory to reuse */
PERLVAR(nice_chunk_size,	U32)		/* how nice the chunk of memory is */

/* Stack for currently executing thread--context switch must handle this.     */
PERLVAR(stack_base,	SV **)		/* stack->array_ary */
PERLVAR(stack_sp,	SV **)		/* stack pointer now */
PERLVAR(stack_max,	SV **)		/* stack->array_ary + stack->array_max */

/* likewise for these */

#ifdef OP_IN_REGISTER
PERLVAR(opsave,	OP *)		/* save current op register across longjmps */
#else
PERLVAR(op,	OP *)		/* current op--when not in a global register */
#endif
PERLVARI(runops,	runops_proc_t *,	RUNOPS_DEFAULT)	
PERLVAR(scopestack,	I32 *)		/* blocks we've entered */
PERLVAR(scopestack_ix,	I32)		
PERLVAR(scopestack_max,	I32)		

PERLVAR(savestack,	ANY*)		/* to save non-local values on */
PERLVAR(savestack_ix,	I32)		
PERLVAR(savestack_max,	I32)		

PERLVAR(retstack,	OP **)		/* returns we've pushed */
PERLVAR(retstack_ix,	I32)		
PERLVAR(retstack_max,	I32)		

PERLVAR(markstack,	I32 *)		/* stackmarks we're remembering */
PERLVAR(markstack_ptr,	I32 *)		/* stackmarks we're remembering */
PERLVAR(markstack_max,	I32 *)		/* stackmarks we're remembering */

PERLVAR(curpad,	SV **)		

/* temp space */
PERLVAR(Sv,	SV *)		
PERLVAR(Xpv,	XPV *)		
PERLVAR(tokenbuf[256],	char)		
PERLVAR(statbuf,	struct stat)		
#ifdef HAS_TIMES
PERLVAR(timesbuf,	struct tms)		
#endif
#if defined(WIN32) && defined(__GNUC__)
PERLVAR(na,	static STRLEN)		
#else
PERLVAR(na,	STRLEN)		/* for use in SvPV when length is Not Applicable */
#endif

PERLVAR(sv_undef,	SV)		
PERLVAR(sv_no,	SV)		
PERLVAR(sv_yes,	SV)		
#ifdef CSH
PERLVARI(cshname,	char *,	CSH)	
PERLVAR(cshlen,	I32)		
#endif

PERLVAR(lex_state,	U32)		/* next token is determined */
PERLVAR(lex_defer,	U32)		/* state after determined token */
PERLVAR(lex_expect,	expectation)		/* expect after determined token */
PERLVAR(lex_brackets,	I32)		/* bracket count */
PERLVAR(lex_formbrack,	I32)		/* bracket count at outer format level */
PERLVAR(lex_fakebrack,	I32)		/* outer bracket is mere delimiter */
PERLVAR(lex_casemods,	I32)		/* casemod count */
PERLVAR(lex_dojoin,	I32)		/* doing an array interpolation */
PERLVAR(lex_starts,	I32)		/* how many interps done on level */
PERLVAR(lex_stuff,	SV *)		/* runtime pattern from m// or s/// */
PERLVAR(lex_repl,	SV *)		/* runtime replacement from s/// */
PERLVAR(lex_op,	OP *)		/* extra info to pass back on op */
PERLVAR(lex_inpat,	OP *)		/* in pattern $) and $| are special */
PERLVAR(lex_inwhat,	I32)		/* what kind of quoting are we in */
PERLVAR(lex_brackstack,	char *)		/* what kind of brackets to pop */
PERLVAR(lex_casestack,	char *)		/* what kind of case mods in effect */

/* What we know when we're in LEX_KNOWNEXT state. */
PERLVAR(nextval[5],	YYSTYPE)		/* value of next token, if any */
PERLVAR(nexttype[5],	I32)		/* type of next token */
PERLVAR(nexttoke,	I32)		

PERLVARI(rsfp,	PerlIO * VOL,	Nullfp)	
PERLVAR(linestr,	SV *)		
PERLVAR(bufptr,	char *)		
PERLVAR(oldbufptr,	char *)		
PERLVAR(oldoldbufptr,	char *)		
PERLVAR(bufend,	char *)		
PERLVARI(expect,	expectation,	XSTATE)	/* how to interpret ambiguous tokens */
PERLVAR(rsfp_filters,	AV *)		

PERLVAR(multi_start,	I32)		/* 1st line of multi-line string */
PERLVAR(multi_end,	I32)		/* last line of multi-line string */
PERLVAR(multi_open,	I32)		/* delimiter of said string */
PERLVAR(multi_close,	I32)		/* delimiter of said string */

PERLVAR(scrgv,	GV *)		
PERLVAR(error_count,	I32)		/* how many errors so far, max 10 */
PERLVAR(subline,	I32)		/* line this subroutine began on */
PERLVAR(subname,	SV *)		/* name of current subroutine */

PERLVAR(compcv,	CV *)		/* currently compiling subroutine */
PERLVAR(comppad,	AV *)		/* storage for lexically scoped temporaries */
PERLVAR(comppad_name,	AV *)		/* variable names for "my" variables */
PERLVAR(comppad_name_fill,	I32)		/* last "introduced" variable offset */
PERLVAR(comppad_name_floor,	I32)		/* start of vars in innermost block */
PERLVAR(min_intro_pending,	I32)		/* start of vars to introduce */
PERLVAR(max_intro_pending,	I32)		/* end of vars to introduce */
PERLVAR(padix,	I32)		/* max used index in current "register" pad */
PERLVAR(padix_floor,	I32)		/* how low may inner block reset padix */
PERLVAR(pad_reset_pending,	I32)		/* reset pad on next attempted alloc */
PERLVAR(compiling,	COP)		

PERLVAR(thisexpr,	I32)		/* name id for nothing_in_common() */
PERLVAR(last_uni,	char *)		/* position of last named-unary operator */
PERLVAR(last_lop,	char *)		/* position of last list operator */
PERLVAR(last_lop_op,	OPCODE)		/* last list operator */
PERLVAR(in_my,	bool)		/* we're compiling a "my" declaration */
PERLVAR(in_my_stash,	HV *)		/* declared class of this "my" declaration */
#ifdef FCRYPT
PERLVAR(cryptseen,	I32)		/* has fast crypt() been initialized? */
#endif

PERLVAR(hints,	U32)		/* various compilation flags */

PERLVAR(do_undump,	bool)		/* -u or dump seen? */
PERLVAR(debug,	VOL U32)		


#ifdef OVERLOAD

PERLVAR(amagic_generation,	long)		

#endif

#ifdef USE_LOCALE_COLLATE
PERLVAR(collation_ix,	U32)		/* Collation generation index */
PERLVAR(collation_name,	char *)		/* Name of current collation */
PERLVARI(collation_standard,	bool,	TRUE)	/* Assume simple collation */
PERLVAR(collxfrm_base,	Size_t)		/* Basic overhead in *xfrm() */
PERLVARI(collxfrm_mult,	Size_t,	2)	/* Expansion factor in *xfrm() */
#endif /* USE_LOCALE_COLLATE */

#ifdef USE_LOCALE_NUMERIC

PERLVAR(numeric_name,	char *)		/* Name of current numeric locale */
PERLVARI(numeric_standard,	bool,	TRUE)	/* Assume simple numerics */
PERLVARI(numeric_local,	bool,	TRUE)	/* Assume local numerics */

#endif /* !USE_LOCALE_NUMERIC */

#ifndef MULTIPLICITY
#define IEXT EXT
#define IINIT(x) INIT(x)
#include "intrpvar.h"
#undef IEXT
#undef IINIT
#endif