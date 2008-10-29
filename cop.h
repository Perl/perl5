/*    cop.h
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000,
 *    2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * Control ops (cops) are one of the three ops OP_NEXTSTATE, OP_DBSTATE,
 * and OP_SETSTATE that (loosely speaking) are separate statements.
 * They hold information important for lexical state and error reporting.
 * At run time, PL_curcop is set to point to the most recently executed cop,
 * and thus can be used to determine our current state.
 */

/* A jmpenv packages the state required to perform a proper non-local jump.
 * Note that there is a start_env initialized when perl starts, and top_env
 * points to this initially, so top_env should always be non-null.
 *
 * Existence of a non-null top_env->je_prev implies it is valid to call
 * longjmp() at that runlevel (we make sure start_env.je_prev is always
 * null to ensure this).
 *
 * je_mustcatch, when set at any runlevel to TRUE, means eval ops must
 * establish a local jmpenv to handle exception traps.  Care must be taken
 * to restore the previous value of je_mustcatch before exiting the
 * stack frame iff JMPENV_PUSH was not called in that stack frame.
 * GSAR 97-03-27
 */

struct jmpenv {
    struct jmpenv *	je_prev;
    Sigjmp_buf		je_buf;		/* only for use if !je_throw */
    int			je_ret;		/* last exception thrown */
    bool		je_mustcatch;	/* need to call longjmp()? */
#ifdef PERL_FLEXIBLE_EXCEPTIONS
    void		(*je_throw)(int v); /* last for bincompat */
    bool		je_noset;	/* no need for setjmp() */
#endif
};

typedef struct jmpenv JMPENV;

#ifdef OP_IN_REGISTER
#define OP_REG_TO_MEM	PL_opsave = op
#define OP_MEM_TO_REG	op = PL_opsave
#else
#define OP_REG_TO_MEM	NOOP
#define OP_MEM_TO_REG	NOOP
#endif

/*
 * How to build the first jmpenv.
 *
 * top_env needs to be non-zero. It points to an area
 * in which longjmp() stuff is stored, as C callstack
 * info there at least is thread specific this has to
 * be per-thread. Otherwise a 'die' in a thread gives
 * that thread the C stack of last thread to do an eval {}!
 */

#define JMPENV_BOOTSTRAP \
    STMT_START {				\
	Zero(&PL_start_env, 1, JMPENV);		\
	PL_start_env.je_ret = -1;		\
	PL_start_env.je_mustcatch = TRUE;	\
	PL_top_env = &PL_start_env;		\
    } STMT_END

#ifdef PERL_FLEXIBLE_EXCEPTIONS

/*
 * These exception-handling macros are split up to
 * ease integration with C++ exceptions.
 *
 * To use C++ try+catch to catch Perl exceptions, an extension author
 * needs to first write an extern "C" function to throw an appropriate
 * exception object; typically it will be or contain an integer,
 * because Perl's internals use integers to track exception types:
 *    extern "C" { static void thrower(int i) { throw i; } }
 *
 * Then (as shown below) the author needs to use, not the simple
 * JMPENV_PUSH, but several of its constitutent macros, to arrange for
 * the Perl internals to call thrower() rather than longjmp() to
 * report exceptions:
 *
 *    dJMPENV;
 *    JMPENV_PUSH_INIT(thrower);
 *    try {
 *        ... stuff that may throw exceptions ...
 *    }
 *    catch (int why) {  // or whatever matches thrower()
 *        JMPENV_POST_CATCH;
 *        EXCEPT_SET(why);
 *        switch (why) {
 *          ... // handle various Perl exception codes
 *        }
 *    }
 *    JMPENV_POP;  // don't forget this!
 */

/*
 * Function that catches/throws, and its callback for the
 *  body of protected processing.
 */
typedef void *(CPERLscope(*protect_body_t)) (pTHX_ va_list);
typedef void *(CPERLscope(*protect_proc_t)) (pTHX_ volatile JMPENV *pcur_env,
					     int *, protect_body_t, ...);

#define dJMPENV	JMPENV cur_env;	\
		volatile JMPENV *pcur_env = ((cur_env.je_noset = 0),&cur_env)

#define JMPENV_PUSH_INIT_ENV(ce,THROWFUNC) \
    STMT_START {					\
	(ce).je_throw = (THROWFUNC);			\
	(ce).je_ret = -1;				\
	(ce).je_mustcatch = FALSE;			\
	(ce).je_prev = PL_top_env;			\
	PL_top_env = &(ce);				\
	OP_REG_TO_MEM;					\
    } STMT_END

#define JMPENV_PUSH_INIT(THROWFUNC) JMPENV_PUSH_INIT_ENV(*(JMPENV*)pcur_env,THROWFUNC)

#define JMPENV_POST_CATCH_ENV(ce) \
    STMT_START {					\
	OP_MEM_TO_REG;					\
	PL_top_env = &(ce);				\
    } STMT_END

#define JMPENV_POST_CATCH JMPENV_POST_CATCH_ENV(*(JMPENV*)pcur_env)

#define JMPENV_PUSH_ENV(ce,v) \
    STMT_START {						\
	if (!(ce).je_noset) {					\
	    DEBUG_l(Perl_deb(aTHX_ "Setting up jumplevel %p, was %p\n",	\
			     (void*)ce, (void*)PL_top_env));	\
	    JMPENV_PUSH_INIT_ENV(ce,NULL);			\
	    EXCEPT_SET_ENV(ce,PerlProc_setjmp((ce).je_buf, SCOPE_SAVES_SIGNAL_MASK));\
	    (ce).je_noset = 1;					\
	}							\
	else							\
	    EXCEPT_SET_ENV(ce,0);				\
	JMPENV_POST_CATCH_ENV(ce);				\
	(v) = EXCEPT_GET_ENV(ce);				\
    } STMT_END

#define JMPENV_PUSH(v) JMPENV_PUSH_ENV(*(JMPENV*)pcur_env,v)

#define JMPENV_POP_ENV(ce) \
    STMT_START {						\
	if (PL_top_env == &(ce))				\
	    PL_top_env = (ce).je_prev;				\
    } STMT_END

#define JMPENV_POP  JMPENV_POP_ENV(*(JMPENV*)pcur_env)

#define JMPENV_JUMP(v) \
    STMT_START {						\
	OP_REG_TO_MEM;						\
	if (PL_top_env->je_prev) {				\
	    if (PL_top_env->je_throw)				\
		PL_top_env->je_throw(v);			\
	    else						\
		PerlProc_longjmp(PL_top_env->je_buf, (v));	\
	}							\
	if ((v) == 2)						\
	    PerlProc_exit(STATUS_EXIT);				\
	PerlIO_printf(Perl_error_log, "panic: top_env\n");	\
	PerlProc_exit(1);					\
    } STMT_END

#define EXCEPT_GET_ENV(ce)	((ce).je_ret)
#define EXCEPT_GET		EXCEPT_GET_ENV(*(JMPENV*)pcur_env)
#define EXCEPT_SET_ENV(ce,v)	((ce).je_ret = (v))
#define EXCEPT_SET(v)		EXCEPT_SET_ENV(*(JMPENV*)pcur_env,v)

#else /* !PERL_FLEXIBLE_EXCEPTIONS */

#define dJMPENV		JMPENV cur_env

#define JMPENV_PUSH(v) \
    STMT_START {							\
	DEBUG_l(Perl_deb(aTHX_ "Setting up jumplevel %p, was %p\n",	\
			 (void*)&cur_env, (void*)PL_top_env));		\
	cur_env.je_prev = PL_top_env;					\
	OP_REG_TO_MEM;							\
	cur_env.je_ret = PerlProc_setjmp(cur_env.je_buf, SCOPE_SAVES_SIGNAL_MASK);		\
	OP_MEM_TO_REG;							\
	PL_top_env = &cur_env;						\
	cur_env.je_mustcatch = FALSE;					\
	(v) = cur_env.je_ret;						\
    } STMT_END

#define JMPENV_POP \
    STMT_START { PL_top_env = cur_env.je_prev; } STMT_END

#define JMPENV_JUMP(v) \
    STMT_START {						\
	OP_REG_TO_MEM;						\
	if (PL_top_env->je_prev)				\
	    PerlProc_longjmp(PL_top_env->je_buf, (v));		\
	if ((v) == 2)						\
	    PerlProc_exit(STATUS_EXIT);				\
	PerlIO_printf(PerlIO_stderr(), "panic: top_env\n");	\
	PerlProc_exit(1);					\
    } STMT_END

#endif /* PERL_FLEXIBLE_EXCEPTIONS */

#define CATCH_GET		(PL_top_env->je_mustcatch)
#define CATCH_SET(v)		(PL_top_env->je_mustcatch = (v))


struct cop {
    BASEOP
    char *	cop_label;	/* label for this construct */
#ifdef USE_ITHREADS
    char *	cop_stashpv;	/* package line was compiled in */
    char *	cop_file;	/* file name the following line # is from */
#else
    HV *	cop_stash;	/* package line was compiled in */
    GV *	cop_filegv;	/* file the following line # is from */
#endif
    U32		cop_seq;	/* parse sequence number */
    I32		cop_arybase;	/* array base this line was compiled with */
    line_t      cop_line;       /* line # of this command */
    SV *	cop_warnings;	/* lexical warnings bitmask */
    SV *	cop_io;		/* lexical IO defaults */
};

#ifdef USE_ITHREADS
#  define CopFILE(c)		((c)->cop_file)
#  define CopFILEGV(c)		(CopFILE(c) \
				 ? gv_fetchfile(CopFILE(c)) : NULL)
				 
#  ifdef NETWARE
#    define CopFILE_set(c,pv)	((c)->cop_file = savepv(pv))
#    define CopFILE_setn(c,pv,l)  ((c)->cop_file = savepv((pv),(l)))
#  else
#    define CopFILE_set(c,pv)	((c)->cop_file = savesharedpv(pv))
#    define CopFILE_setn(c,pv,l)  ((c)->cop_file = savesharedpvn((pv),(l)))
#  endif

#  define CopFILESV(c)		(CopFILE(c) \
				 ? GvSV(gv_fetchfile(CopFILE(c))) : NULL)
#  define CopFILEAV(c)		(CopFILE(c) \
				 ? GvAV(gv_fetchfile(CopFILE(c))) : NULL)
#  define CopFILEAVx(c)		(GvAV(gv_fetchfile(CopFILE(c))))
#  define CopSTASHPV(c)		((c)->cop_stashpv)

#  ifdef NETWARE
#    define CopSTASHPV_set(c,pv)	((c)->cop_stashpv = ((pv) ? savepv(pv) : NULL))
#  else
#    define CopSTASHPV_set(c,pv)	((c)->cop_stashpv = savesharedpv(pv))
#  endif

#  define CopSTASH(c)		(CopSTASHPV(c) \
				 ? gv_stashpv(CopSTASHPV(c),GV_ADD) : NULL)
#  define CopSTASH_set(c,hv)	CopSTASHPV_set(c, (hv) ? HvNAME_get(hv) : NULL)
#  define CopSTASH_eq(c,hv)	((hv) && stashpv_hvname_match(c,hv))
#  ifdef NETWARE
#    define CopSTASH_free(c) SAVECOPSTASH_FREE(c)
#    define CopFILE_free(c) SAVECOPFILE_FREE(c)
#  else
#    define CopSTASH_free(c)	PerlMemShared_free(CopSTASHPV(c))
#    define CopFILE_free(c)	(PerlMemShared_free(CopFILE(c)),(CopFILE(c) = NULL))
#  endif
#else
#  define CopFILEGV(c)		((c)->cop_filegv)
#  define CopFILEGV_set(c,gv)	((c)->cop_filegv = (GV*)SvREFCNT_inc(gv))
#  define CopFILE_set(c,pv)	CopFILEGV_set((c), gv_fetchfile(pv))
#  define CopFILE_setn(c,pv,l)	CopFILEGV_set((c), gv_fetchfile_flags((pv),(l),0))
#  define CopFILESV(c)		(CopFILEGV(c) ? GvSV(CopFILEGV(c)) : NULL)
#  define CopFILEAV(c)		(CopFILEGV(c) ? GvAV(CopFILEGV(c)) : NULL)
#  define CopFILEAVx(c)		(GvAV(CopFILEGV(c)))
#  define CopFILE(c)		(CopFILEGV(c) && GvSV(CopFILEGV(c)) \
				    ? SvPVX(GvSV(CopFILEGV(c))) : NULL)
#  define CopSTASH(c)		((c)->cop_stash)
#  define CopSTASH_set(c,hv)	((c)->cop_stash = (hv))
#  define CopSTASHPV(c)		(CopSTASH(c) ? HvNAME_get(CopSTASH(c)) : NULL)
   /* cop_stash is not refcounted */
#  define CopSTASHPV_set(c,pv)	CopSTASH_set((c), gv_stashpv(pv,GV_ADD))
#  define CopSTASH_eq(c,hv)	(CopSTASH(c) == (hv))
#  define CopSTASH_free(c)	
#  define CopFILE_free(c)	(SvREFCNT_dec(CopFILEGV(c)),(CopFILEGV(c) = NULL))

#endif /* USE_ITHREADS */

#define CopSTASH_ne(c,hv)	(!CopSTASH_eq(c,hv))
#define CopLINE(c)		((c)->cop_line)
#define CopLINE_inc(c)		(++CopLINE(c))
#define CopLINE_dec(c)		(--CopLINE(c))
#define CopLINE_set(c,l)	(CopLINE(c) = (l))

/* OutCopFILE() is CopFILE for output (caller, die, warn, etc.) */
#ifdef MACOS_TRADITIONAL
#  define OutCopFILE(c) MacPerl_MPWFileName(CopFILE(c))
#else
#  define OutCopFILE(c) CopFILE(c)
#endif

/* CopARYBASE is likely to be removed soon.  */
#define CopARYBASE(c)		((c)->cop_arybase)
#define CopARYBASE_get(c)	((c)->cop_arybase + 0)
#define CopARYBASE_set(c, b)	STMT_START { (c)->cop_arybase = (b); } STMT_END

/* FIXME NATIVE_HINTS if this is changed from op_private (see perl.h)  */
#define CopHINTS_get(c)		((U32)(c)->op_private + 0)
#define CopHINTS_set(c, h)	STMT_START {				\
				    (c)->op_private			\
					 = (U8)((h) & HINT_PRIVATE_MASK); \
				} STMT_END

/*
 * Here we have some enormously heavy (or at least ponderous) wizardry.
 */

/* subroutine context */
struct block_sub {
    CV *	cv;
    GV *	gv;
    GV *	dfoutgv;
#ifndef USE_5005THREADS
    AV *	savearray;
#endif /* USE_5005THREADS */
    AV *	argarray;
    long	olddepth;
    U8		hasargs;
    U8		lval;		/* XXX merge lval and hasargs? */
    PAD		*oldcomppad;
};

/* base for the next two macros. Don't use directly.
 * Note that the refcnt of the cv is incremented twice;  The CX one is
 * decremented by LEAVESUB, the other by LEAVE. */

#define PUSHSUB_BASE(cx)						\
	cx->blk_sub.cv = cv;						\
	cx->blk_sub.olddepth = CvDEPTH(cv);				\
	cx->blk_sub.hasargs = hasargs;					\
	if (!CvDEPTH(cv)) {						\
	    SvREFCNT_inc_simple_void_NN(cv);				\
	    SvREFCNT_inc_simple_void_NN(cv);				\
	    SAVEFREESV(cv);						\
	}


#define PUSHSUB(cx)							\
	PUSHSUB_BASE(cx)						\
	cx->blk_sub.lval = PL_op->op_private &                          \
	                      (OPpLVAL_INTRO|OPpENTERSUB_INARGS);

/* variant for use by OP_DBSTATE, where op_private holds hint bits */
#define PUSHSUB_DB(cx)							\
	PUSHSUB_BASE(cx)						\
	cx->blk_sub.lval = 0;


#define PUSHFORMAT(cx)							\
	cx->blk_sub.cv = cv;						\
	cx->blk_sub.gv = gv;						\
	cx->blk_sub.hasargs = 0;					\
	cx->blk_sub.dfoutgv = PL_defoutgv;				\
	SvREFCNT_inc_void(cx->blk_sub.dfoutgv)

#ifdef USE_5005THREADS
#  define POP_SAVEARRAY() NOOP
#else
#  define POP_SAVEARRAY()						\
    STMT_START {							\
	SvREFCNT_dec(GvAV(PL_defgv));					\
	GvAV(PL_defgv) = cx->blk_sub.savearray;				\
    } STMT_END
#endif /* USE_5005THREADS */

/* junk in @_ spells trouble when cloning CVs and in pp_caller(), so don't
 * leave any (a fast av_clear(ary), basically) */
#define CLEAR_ARGARRAY(ary) \
    STMT_START {							\
	AvMAX(ary) += AvARRAY(ary) - AvALLOC(ary);			\
	SvPV_set(ary, (char*)AvALLOC(ary));				\
	AvFILLp(ary) = -1;						\
    } STMT_END

#define POPSUB(cx,sv)							\
    STMT_START {							\
	if (CxHASARGS(cx)) {						\
	    POP_SAVEARRAY();						\
	    /* abandon @_ if it got reified */				\
	    if (AvREAL(cx->blk_sub.argarray)) {				\
		const SSize_t fill = AvFILLp(cx->blk_sub.argarray);	\
		SvREFCNT_dec(cx->blk_sub.argarray);			\
		cx->blk_sub.argarray = newAV();				\
		av_extend(cx->blk_sub.argarray, fill);			\
		AvFLAGS(cx->blk_sub.argarray) = AVf_REIFY;		\
		CX_CURPAD_SV(cx->blk_sub, 0) = (SV*)cx->blk_sub.argarray;	\
	    }								\
	    else {							\
		CLEAR_ARGARRAY(cx->blk_sub.argarray);			\
	    }								\
	}								\
	sv = (SV*)cx->blk_sub.cv;					\
	if (sv && (CvDEPTH((CV*)sv) = cx->blk_sub.olddepth))		\
	    sv = NULL;						\
    } STMT_END

#define LEAVESUB(sv)							\
    STMT_START {							\
	if (sv)								\
	    SvREFCNT_dec(sv);						\
    } STMT_END

#define POPFORMAT(cx)							\
	setdefout(cx->blk_sub.dfoutgv);					\
	SvREFCNT_dec(cx->blk_sub.dfoutgv);

/* eval context */
struct block_eval {
    I32		old_in_eval;
    I32		old_op_type;
    SV *	old_namesv;
    OP *	old_eval_root;
    SV *	cur_text;
    CV *	cv;
    JMPENV *	cur_top_env; /* value of PL_top_env when eval CX created */
};

#define CxOLD_IN_EVAL(cx)	(0 + (cx)->blk_eval.old_in_eval)
#define CxOLD_OP_TYPE(cx)	(0 + (cx)->blk_eval.old_op_type)

#define PUSHEVAL(cx,n,fgv)						\
    STMT_START {							\
	cx->blk_eval.old_in_eval = PL_in_eval;				\
	cx->blk_eval.old_op_type = PL_op->op_type;			\
	cx->blk_eval.old_namesv = (n ? newSVpv(n,0) : NULL);		\
	cx->blk_eval.old_eval_root = PL_eval_root;			\
	cx->blk_eval.cur_text = PL_linestr;				\
	cx->blk_eval.cv = NULL; /* set by doeval(), as applicable */	\
	cx->blk_eval.cur_top_env = PL_top_env; 				\
    } STMT_END

#define POPEVAL(cx)							\
    STMT_START {							\
	PL_in_eval = CxOLD_IN_EVAL(cx);					\
	optype = CxOLD_OP_TYPE(cx);					\
	PL_eval_root = cx->blk_eval.old_eval_root;			\
	if (cx->blk_eval.old_namesv)					\
	    sv_2mortal(cx->blk_eval.old_namesv);			\
    } STMT_END

/* loop context */
struct block_loop {
    char *	label;
    I32		resetsp;
    OP *	redo_op;
    OP *	next_op;
    OP *	last_op;
#ifdef USE_ITHREADS
    void *	iterdata;
    PAD		*oldcomppad;
#else
    SV **	itervar;
#endif
    /* Eliminated in blead by change 33080, but for binary compatibility
       reasons we can't remove it from the middle of a struct in a maintenance
       release, so it gets to stay, and be set to NULL.  */
    SV *	itersave;
    SV *	iterlval;
    AV *	iterary;
    IV		iterix;
    IV		itermax;
};

#ifdef USE_ITHREADS
#  define CxITERVAR(c)							\
	((c)->blk_loop.iterdata						\
	 ? (CxPADLOOP(cx) 						\
	    ? &CX_CURPAD_SV( (c)->blk_loop, 				\
		    INT2PTR(PADOFFSET, (c)->blk_loop.iterdata))		\
	    : &GvSV((GV*)(c)->blk_loop.iterdata))			\
	 : (SV**)NULL)
#  define CX_ITERDATA_SET(cx,idata)					\
	CX_CURPAD_SAVE(cx->blk_loop);					\
	cx->blk_loop.itersave = NULL;					\
	cx->blk_loop.iterdata = (idata);
#else
#  define CxITERVAR(c)		((c)->blk_loop.itervar)
#  define CX_ITERDATA_SET(cx,ivar)					\
	cx->blk_loop.itersave = NULL;					\
	cx->blk_loop.itervar = (SV**)(ivar);
#endif
#define CxLABEL(c)	(0 + (c)->blk_loop.label)
#define CxHASARGS(c)	(0 + (c)->blk_sub.hasargs)
#define CxLVAL(c)	(0 + (c)->blk_sub.lval)

#define PUSHLOOP(cx, dat, s)						\
	cx->blk_loop.label = PL_curcop->cop_label;			\
	cx->blk_loop.resetsp = s - PL_stack_base;			\
	cx->blk_loop.redo_op = cLOOP->op_redoop;			\
	cx->blk_loop.next_op = cLOOP->op_nextop;			\
	cx->blk_loop.last_op = cLOOP->op_lastop;			\
	cx->blk_loop.iterlval = NULL;					\
	cx->blk_loop.iterary = NULL;					\
	cx->blk_loop.iterix = -1;					\
	CX_ITERDATA_SET(cx,dat);

#define POPLOOP(cx)							\
	SvREFCNT_dec(cx->blk_loop.iterlval);				\
	if (cx->blk_loop.iterary && cx->blk_loop.iterary != PL_curstack)\
	    SvREFCNT_dec(cx->blk_loop.iterary);

/* context common to subroutines, evals and loops */
struct block {
    I32		blku_oldsp;	/* stack pointer to copy stuff down to */
    COP *	blku_oldcop;	/* old curcop pointer */
    I32		blku_oldretsp;	/* return stack index */
    I32		blku_oldmarksp;	/* mark stack index */
    I32		blku_oldscopesp;	/* scope stack index */
    PMOP *	blku_oldpm;	/* values of pattern match vars */
    U8		blku_gimme;	/* is this block running in list context? */

    union {
	struct block_sub	blku_sub;
	struct block_eval	blku_eval;
	struct block_loop	blku_loop;
    } blk_u;
};
#define blk_oldsp	cx_u.cx_blk.blku_oldsp
#define blk_oldcop	cx_u.cx_blk.blku_oldcop
#define blk_oldretsp	cx_u.cx_blk.blku_oldretsp
#define blk_oldmarksp	cx_u.cx_blk.blku_oldmarksp
#define blk_oldscopesp	cx_u.cx_blk.blku_oldscopesp
#define blk_oldpm	cx_u.cx_blk.blku_oldpm
#define blk_gimme	cx_u.cx_blk.blku_gimme
#define blk_sub		cx_u.cx_blk.blk_u.blku_sub
#define blk_eval	cx_u.cx_blk.blk_u.blku_eval
#define blk_loop	cx_u.cx_blk.blk_u.blku_loop

/* Enter a block. */
#define PUSHBLOCK(cx,t,sp) CXINC, cx = &cxstack[cxstack_ix],		\
	cx->cx_type		= t,					\
	cx->blk_oldsp		= sp - PL_stack_base,			\
	cx->blk_oldcop		= PL_curcop,				\
	cx->blk_oldmarksp	= PL_markstack_ptr - PL_markstack,	\
	cx->blk_oldscopesp	= PL_scopestack_ix,			\
	cx->blk_oldretsp	= PL_retstack_ix,			\
	cx->blk_oldpm		= PL_curpm,				\
	cx->blk_gimme		= (U8)gimme;				\
	DEBUG_l( PerlIO_printf(Perl_debug_log, "Entering block %ld, type %s\n",	\
		    (long)cxstack_ix, PL_block_type[CxTYPE(cx)]); )

/* Exit a block (RETURN and LAST). */
#define POPBLOCK(cx,pm) cx = &cxstack[cxstack_ix--],			\
	newsp		 = PL_stack_base + cx->blk_oldsp,		\
	PL_curcop	 = cx->blk_oldcop,				\
	PL_markstack_ptr = PL_markstack + cx->blk_oldmarksp,		\
	PL_scopestack_ix = cx->blk_oldscopesp,				\
	PL_retstack_ix	 = cx->blk_oldretsp,				\
	pm		 = cx->blk_oldpm,				\
	gimme		 = cx->blk_gimme;				\
	DEBUG_SCOPE("POPBLOCK");					\
	DEBUG_l( PerlIO_printf(Perl_debug_log, "Leaving block %ld, type %s\n",		\
		    (long)cxstack_ix+1,PL_block_type[CxTYPE(cx)]); )

/* Continue a block elsewhere (NEXT and REDO). */
#define TOPBLOCK(cx) cx  = &cxstack[cxstack_ix],			\
	PL_stack_sp	 = PL_stack_base + cx->blk_oldsp,		\
	PL_markstack_ptr = PL_markstack + cx->blk_oldmarksp,		\
	PL_scopestack_ix = cx->blk_oldscopesp,				\
	PL_retstack_ix	 = cx->blk_oldretsp,				\
	PL_curpm         = cx->blk_oldpm;				\
	DEBUG_SCOPE("TOPBLOCK");

/* substitution context */
struct subst {
    I32		sbu_iters;
    I32		sbu_maxiters;
    I32		sbu_rflags;
    I32		sbu_oldsave;
    bool	sbu_once;
    bool	sbu_rxtainted;
    char *	sbu_orig;
    SV *	sbu_dstr;
    SV *	sbu_targ;
    char *	sbu_s;
    char *	sbu_m;
    char *	sbu_strend;
    void *	sbu_rxres;
    REGEXP *	sbu_rx;
};
#define sb_iters	cx_u.cx_subst.sbu_iters
#define sb_maxiters	cx_u.cx_subst.sbu_maxiters
#define sb_rflags	cx_u.cx_subst.sbu_rflags
#define sb_oldsave	cx_u.cx_subst.sbu_oldsave
#define sb_once		cx_u.cx_subst.sbu_once
#define sb_rxtainted	cx_u.cx_subst.sbu_rxtainted
#define sb_orig		cx_u.cx_subst.sbu_orig
#define sb_dstr		cx_u.cx_subst.sbu_dstr
#define sb_targ		cx_u.cx_subst.sbu_targ
#define sb_s		cx_u.cx_subst.sbu_s
#define sb_m		cx_u.cx_subst.sbu_m
#define sb_strend	cx_u.cx_subst.sbu_strend
#define sb_rxres	cx_u.cx_subst.sbu_rxres
#define sb_rx		cx_u.cx_subst.sbu_rx

#define PUSHSUBST(cx) CXINC, cx = &cxstack[cxstack_ix],			\
	cx->sb_iters		= iters,				\
	cx->sb_maxiters		= maxiters,				\
	cx->sb_rflags		= r_flags,				\
	cx->sb_oldsave		= oldsave,				\
	cx->sb_once		= once,					\
	cx->sb_rxtainted	= rxtainted,				\
	cx->sb_orig		= orig,					\
	cx->sb_dstr		= dstr,					\
	cx->sb_targ		= targ,					\
	cx->sb_s		= s,					\
	cx->sb_m		= m,					\
	cx->sb_strend		= strend,				\
	cx->sb_rxres		= NULL,					\
	cx->sb_rx		= rx,					\
	cx->cx_type		= CXt_SUBST;				\
	rxres_save(&cx->sb_rxres, rx);					\
	(void)ReREFCNT_inc(rx)

#define CxONCE(cx)		(0 + cx->sb_once)

#define POPSUBST(cx) cx = &cxstack[cxstack_ix--];			\
	rxres_free(&cx->sb_rxres);					\
	ReREFCNT_dec(cx->sb_rx)

struct context {
    U32		cx_type;	/* what kind of context this is */
    union {
	struct block	cx_blk;
	struct subst	cx_subst;
    } cx_u;
};

#define CXTYPEMASK	0xff
#define CXt_NULL	0
#define CXt_SUB		1
#define CXt_EVAL	2
#define CXt_LOOP	3
#define CXt_SUBST	4
#define CXt_BLOCK	5
#define CXt_FORMAT	6

/* private flags for CXt_SUB and CXt_NULL */
#define CXp_MULTICALL	0x00000400	/* part of a multicall (so don't
					   tear down context on exit). */ 

/* private flags for CXt_EVAL */
#define CXp_REAL	0x00000100	/* truly eval'', not a lookalike */
#define CXp_TRYBLOCK	0x00000200	/* eval{}, not eval'' or similar */

/* private flags for CXt_LOOP */
#define CXp_FOREACH	0x00000200	/* a foreach loop */
#define CXp_FOR_DEF	0x00000400	/* foreach using $_ */
#ifdef USE_ITHREADS
#  define CXp_PADVAR	0x00000100	/* itervar lives on pad, iterdata
					   has pad offset; if not set,
					   iterdata holds GV* */
#  define CxPADLOOP(c)	(((c)->cx_type & (CXt_LOOP|CXp_PADVAR))		\
			 == (CXt_LOOP|CXp_PADVAR))
#endif

#define CxTYPE(c)	((c)->cx_type & CXTYPEMASK)
#define CxMULTICALL(c)	(((c)->cx_type & CXp_MULTICALL)			\
			 == CXp_MULTICALL)
#define CxREALEVAL(c)	(((c)->cx_type & (CXTYPEMASK|CXp_REAL))		\
			 == (CXt_EVAL|CXp_REAL))
#define CxTRYBLOCK(c)	(((c)->cx_type & (CXTYPEMASK|CXp_TRYBLOCK))	\
			 == (CXt_EVAL|CXp_TRYBLOCK))
#define CxFOREACH(c)	(((c)->cx_type & (CXTYPEMASK|CXp_FOREACH))	\
                         == (CXt_LOOP|CXp_FOREACH))
#define CxFOREACHDEF(c)	(((c)->cx_type & (CXTYPEMASK|CXp_FOREACH|CXp_FOR_DEF))\
			 == (CXt_LOOP|CXp_FOREACH|CXp_FOR_DEF))

#define CXINC (cxstack_ix < cxstack_max ? ++cxstack_ix : (cxstack_ix = cxinc()))

/* 
=head1 "Gimme" Values
*/

/*
=for apidoc AmU||G_SCALAR
Used to indicate scalar context.  See C<GIMME_V>, C<GIMME>, and
L<perlcall>.

=for apidoc AmU||G_ARRAY
Used to indicate list context.  See C<GIMME_V>, C<GIMME> and
L<perlcall>.

=for apidoc AmU||G_VOID
Used to indicate void context.  See C<GIMME_V> and L<perlcall>.

=for apidoc AmU||G_DISCARD
Indicates that arguments returned from a callback should be discarded.  See
L<perlcall>.

=for apidoc AmU||G_EVAL

Used to force a Perl C<eval> wrapper around a callback.  See
L<perlcall>.

=for apidoc AmU||G_NOARGS

Indicates that no arguments are being sent to a callback.  See
L<perlcall>.

=cut
*/

#define G_SCALAR	0
#define G_ARRAY		1
#define G_VOID		128	/* skip this bit when adding flags below */

/* extra flags for Perl_call_* routines */
#define G_DISCARD	2	/* Call FREETMPS.
				   Don't change this without consulting the
				   hash actions codes defined in hv.h */
#define G_EVAL		4	/* Assume eval {} around subroutine call. */
#define G_NOARGS	8	/* Don't construct a @_ array. */
#define G_KEEPERR      16	/* Append errors to $@, don't overwrite it */
#define G_NODEBUG      32	/* Disable debugging at toplevel.  */
#define G_METHOD       64       /* Calling method. */
#define G_FAKINGEVAL  256	/* Faking an eval context for call_sv or
				   fold_constants. */

/* flag bits for PL_in_eval */
#define EVAL_NULL	0	/* not in an eval */
#define EVAL_INEVAL	1	/* some enclosing scope is an eval */
#define EVAL_WARNONLY	2	/* used by yywarn() when calling yyerror() */
#define EVAL_KEEPERR	4	/* set by Perl_call_sv if G_KEEPERR */
#define EVAL_INREQUIRE	8	/* The code is being required. */

/* Support for switching (stack and block) contexts.
 * This ensures magic doesn't invalidate local stack and cx pointers.
 */

#define PERLSI_UNKNOWN		-1
#define PERLSI_UNDEF		0
#define PERLSI_MAIN		1
#define PERLSI_MAGIC		2
#define PERLSI_SORT		3
#define PERLSI_SIGNAL		4
#define PERLSI_OVERLOAD		5
#define PERLSI_DESTROY		6
#define PERLSI_WARNHOOK		7
#define PERLSI_DIEHOOK		8
#define PERLSI_REQUIRE		9

struct stackinfo {
    AV *		si_stack;	/* stack for current runlevel */
    PERL_CONTEXT *	si_cxstack;	/* context stack for runlevel */
    I32			si_cxix;	/* current context index */
    I32			si_cxmax;	/* maximum allocated index */
    I32			si_type;	/* type of runlevel */
    struct stackinfo *	si_prev;
    struct stackinfo *	si_next;
    I32			si_markoff;	/* offset where markstack begins for us.
					 * currently used only with DEBUGGING,
					 * but not #ifdef-ed for bincompat */
};

typedef struct stackinfo PERL_SI;

#define cxstack		(PL_curstackinfo->si_cxstack)
#define cxstack_ix	(PL_curstackinfo->si_cxix)
#define cxstack_max	(PL_curstackinfo->si_cxmax)

#ifdef DEBUGGING
#  define	SET_MARK_OFFSET \
    PL_curstackinfo->si_markoff = PL_markstack_ptr - PL_markstack
#else
#  define	SET_MARK_OFFSET NOOP
#endif

#define PUSHSTACKi(type) \
    STMT_START {							\
	PERL_SI *next = PL_curstackinfo->si_next;			\
	if (!next) {							\
	    next = new_stackinfo(32, 2048/sizeof(PERL_CONTEXT) - 1);	\
	    next->si_prev = PL_curstackinfo;				\
	    PL_curstackinfo->si_next = next;				\
	}								\
	next->si_type = type;						\
	next->si_cxix = -1;						\
	AvFILLp(next->si_stack) = 0;					\
	SWITCHSTACK(PL_curstack,next->si_stack);			\
	PL_curstackinfo = next;						\
	SET_MARK_OFFSET;						\
    } STMT_END

#define PUSHSTACK PUSHSTACKi(PERLSI_UNKNOWN)

/* POPSTACK works with PL_stack_sp, so it may need to be bracketed by
 * PUTBACK/SPAGAIN to flush/refresh any local SP that may be active */
#define POPSTACK \
    STMT_START {							\
	dSP;								\
	PERL_SI * const prev = PL_curstackinfo->si_prev;		\
	if (!prev) {							\
	    PerlIO_printf(Perl_error_log, "panic: POPSTACK\n");		\
	    my_exit(1);							\
	}								\
	SWITCHSTACK(PL_curstack,prev->si_stack);			\
	/* don't free prev here, free them all at the END{} */		\
	PL_curstackinfo = prev;						\
    } STMT_END

#define POPSTACK_TO(s) \
    STMT_START {							\
	while (PL_curstack != s) {					\
	    dounwind(-1);						\
	    POPSTACK;							\
	}								\
    } STMT_END

#define IN_PERL_COMPILETIME	(PL_curcop == &PL_compiling)
#define IN_PERL_RUNTIME		(PL_curcop != &PL_compiling)

/*
=head1 Multicall Functions

=for apidoc Ams||dMULTICALL
Declare local variables for a multicall. See L<perlcall/Lightweight Callbacks>.

=for apidoc Ams||PUSH_MULTICALL
Opening bracket for a lightweight callback.
See L<perlcall/Lightweight Callbacks>.

=for apidoc Ams||MULTICALL
Make a lightweight callback. See L<perlcall/Lightweight Callbacks>.

=for apidoc Ams||POP_MULTICALL
Closing bracket for a lightweight callback.
See L<perlcall/Lightweight Callbacks>.

=cut
*/

#define dMULTICALL \
    SV **newsp;			/* set by POPBLOCK */			\
    PERL_CONTEXT *cx;							\
    CV *multicall_cv;							\
    OP *multicall_cop;							\
    bool multicall_oldcatch; 						\
    U8 hasargs = 0		/* used by PUSHSUB */

#define PUSH_MULTICALL(the_cv) \
    STMT_START {							\
	CV * const _nOnclAshIngNamE_ = the_cv;				\
	CV * const cv = _nOnclAshIngNamE_;				\
	AV * const padlist = CvPADLIST(cv);				\
	ENTER;								\
 	multicall_oldcatch = CATCH_GET;					\
	SAVETMPS; SAVEVPTR(PL_op);					\
	CATCH_SET(TRUE);						\
	PUSHBLOCK(cx, CXt_SUB|CXp_MULTICALL, PL_stack_sp);		\
	PUSHSUB(cx);							\
	if (++CvDEPTH(cv) >= 2) {					\
	    PERL_STACK_OVERFLOW_CHECK();				\
	    Perl_pad_push(aTHX_ padlist, CvDEPTH(cv), 1);		\
	}								\
	SAVECOMPPAD();							\
	PAD_SET_CUR_NOSAVE(padlist, CvDEPTH(cv));			\
	multicall_cv = cv;						\
	multicall_cop = CvSTART(cv);					\
    } STMT_END

#define MULTICALL \
    STMT_START {							\
	PL_op = multicall_cop;						\
	CALLRUNOPS(aTHX);						\
    } STMT_END

#define POP_MULTICALL \
    STMT_START {							\
	LEAVESUB(multicall_cv);						\
	CvDEPTH(multicall_cv)--;					\
	POPBLOCK(cx,PL_curpm);						\
	CATCH_SET(multicall_oldcatch);					\
	LEAVE;								\
    } STMT_END
