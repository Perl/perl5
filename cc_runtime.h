#define DOOP(ppname) PUTBACK; op = ppname(ARGS); SPAGAIN

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

/* Anyone using eval "" deserves this mess */
#define PP_EVAL(ppaddr, nxt) do {		\
	dJMPENV;				\
	int jmpstat;				\
	PUTBACK;				\
	JMPENV_PUSH(jmpstat);			\
	switch (jmpstat) {			\
	case JMP_NORMAL:			\
	    op = ppaddr(ARGS);			\
	    retstack[retstack_ix - 1] = Nullop;	\
	    if (op != nxt) runops();		\
	    JMPENV_POP;				\
	    break;				\
	case JMP_ABNORMAL: JMPENV_POP; JMPENV_JUMP(JMP_ABNORMAL);	\
	case JMP_MYEXIT: JMPENV_POP; JMPENV_JUMP(JMP_MYEXIT);	\
	case JMP_EXCEPTION:					\
	    JMPENV_POP;				\
	    if (restartop != nxt)		\
		JMPENV_JUMP(JMP_EXCEPTION);			\
	}					\
	op = nxt;				\
	SPAGAIN;				\
    } while (0)

#define PP_ENTERTRY(jmpbuf,label) do {		\
	dJMPENV;				\
	int ret;				\
	JMPENV_PUSH(ret);			\
	switch (ret) {				\
	case JMP_ABNORMAL: JMPENV_POP; JMPENV_JUMP(JMP_ABNORMAL);	\
	case JMP_MYEXIT: JMPENV_POP; JMPENV_JUMP(JMP_MYEXIT);	\
	case JMP_EXCEPTION: JMPENV_POP; SPAGAIN; goto label;\
	}					\
    } while (0)
