#define DOOP(ppname) PUTBACK; op = ppname(); SPAGAIN

#define PP_LIST(g) do {			\
	dMARK;				\
	if (g != G_ARRAY) {		\
	    if (++MARK <= SP)		\
		*MARK = *SP;		\
	    else			\
		*MARK = &sv_undef;	\
	    SP = MARK;			\
	}				\
   } while (0)

#define MAYBE_TAINT_SASSIGN_SRC(sv) \
    if (tainting && tainted && (!SvGMAGICAL(left) || !SvSMAGICAL(left) || \
                                !((mg=mg_find(left, 't')) && mg->mg_len & 1)))\
        TAINT_NOT

#define PP_PREINC(sv) do {	\
	if (SvIOK(sv)) {	\
            ++SvIVX(sv);	\
	    SvFLAGS(sv) &= ~(SVf_NOK|SVf_POK|SVp_NOK|SVp_POK); \
	}			\
	else			\
	    sv_inc(sv);		\
	SvSETMAGIC(sv);		\
    } while (0)

#define PP_UNSTACK do {		\
	TAINT_NOT;		\
	stack_sp = stack_base + cxstack[cxstack_ix].blk_oldsp;	\
	FREETMPS;		\
	oldsave = scopestack[scopestack_ix - 1]; \
	LEAVE_SCOPE(oldsave);	\
	SPAGAIN;		\
    } while(0)

#if PATCHLEVEL < 3
#define RUN() run()
#else
#define RUN() runops()
#endif

/* Anyone using eval "" deserves this mess */
#define PP_EVAL(ppaddr, nxt) do {		\
	Sigjmp_buf oldtop;			\
	Copy(top_env,oldtop,1,Sigjmp_buf);	\
	PUTBACK;				\
	switch (Sigsetjmp(top_env,1)) {		\
	case 0:					\
	    op = ppaddr();			\
	    retstack[retstack_ix - 1] = Nullop;	\
	    Copy(oldtop,top_env,1,Sigjmp_buf);	\
	    if (op != nxt) RUN();		\
	    break;				\
	case 1: Copy(oldtop,top_env,1,Sigjmp_buf); Siglongjmp(top_env,1); \
	case 2: Copy(oldtop,top_env,1,Sigjmp_buf); Siglongjmp(top_env,2); \
	case 3:					\
	    Copy(oldtop,top_env,1,Sigjmp_buf);	\
	    if (restartop != nxt)		\
		Siglongjmp(top_env, 3);		\
	}					\
	op = nxt;				\
	SPAGAIN;				\
    } while (0)

#define PP_ENTERTRY(jmpbuf,label) do {		\
	Copy(top_env,jmpbuf,1,Sigjmp_buf);	\
	switch (Sigsetjmp(top_env,1)) {		\
	case 1: Copy(jmpbuf,top_env,1,Sigjmp_buf); Siglongjmp(top_env,1); \
	case 2: Copy(jmpbuf,top_env,1,Sigjmp_buf); Siglongjmp(top_env,2); \
	case 3: Copy(jmpbuf,top_env,1,Sigjmp_buf); SPAGAIN; goto label;	\
	}					\
    } while (0)
