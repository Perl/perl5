/***********************************************************
 *
 * $Header: /usr/src/local/lwall/perl5/RCS/pp.h,v 4.1 92/08/07 18:26:20 lwall Exp Locker: lwall $
 *
 * Description:
 *	Push/Pop code defs.
 *
 * Standards:
 *
 * Created:
 *	Mon Jun 15 16:47:20 1992
 *
 * Author:
 *	Larry Wall <lwall@netlabs.com>
 *
 * $Log:	pp.h,v $
 * Revision 4.1  92/08/07  18:26:20  lwall
 * 
 *
 **********************************************************/

#define ARGS
#define ARGSproto
#define dARGS
#define PP(s) OP* s(ARGS) dARGS

#define SP sp
#define MARK mark
#define TARG targ

#define POPMARK		(*markstack_ptr--)
#define dSP		register SV **sp = stack_sp
#define dMARK		register SV **mark = stack_base + POPMARK
#define dORIGMARK	I32 origmark = mark - stack_base
#define SETORIGMARK	origmark = mark - stack_base
#define ORIGMARK	stack_base + origmark

#define SPAGAIN		sp = stack_sp
#define MSPAGAIN	sp = stack_sp; mark = ORIGMARK

#define GETTARGETSTACKED targ = (op->op_flags & OPf_STACKED ? POPs : PAD_SV(op->op_targ))
#define dTARGETSTACKED SV * GETTARGETSTACKED

#define GETTARGET targ = PAD_SV(op->op_targ)
#define dTARGET SV * GETTARGET

#define GETATARGET targ = (op->op_flags & OPf_STACKED ? sp[-1] : PAD_SV(op->op_targ))
#define dATARGET SV * GETATARGET

#define dTARG SV *targ

#define GETavn(a,g,st) \
	a = sv_2av(cGVOP->op_gv ? (SV*)cGVOP->op_gv : POPs, &st, &g, 1)
#define GEThvn(h,g,st) \
	h = sv_2hv(cGVOP->op_gv ? (SV*)cGVOP->op_gv : POPs, &st, &g, 1)
#define GETav(a,g,st) \
	a = sv_2av(cGVOP->op_gv ? (SV*)cGVOP->op_gv : POPs, &st, &g, 0)
#define GEThv(h,g,st) \
	h = sv_2hv(cGVOP->op_gv ? (SV*)cGVOP->op_gv : POPs, &st, &g, 0)
#define GETcv(r,g,st) \
	r = sv_2cv(POPs, &st, &g, 0)

#define NORMAL op->op_next
#define DIE return die
#define PROP if (dying) return die("%s", dying);

#define PUTBACK		stack_sp = sp
#define RETURN		return PUTBACK, NORMAL
#define RETURNOP(o)	return PUTBACK, o
#define RETURNX(x)	return x, PUTBACK, NORMAL

#define POPs		(*sp--)
#define POPp		(SvPVnx(POPs))
#define POPn		(SvNVnx(POPs))
#define POPi		((int)SvIVnx(POPs))
#define POPl		((long)SvIVnx(POPs))

#define TOPs		(*sp)
#define TOPp		(SvPVn(TOPs))
#define TOPn		(SvNVn(TOPs))
#define TOPi		((int)SvIVn(TOPs))
#define TOPl		((long)SvIVn(TOPs))

/* Go to some pains in the rare event that we must extend the stack. */
#define EXTEND(p,n)	do { if (stack_max - p < (n)) {		  	    \
			    av_fill(stack, (p - stack_base) + (n));	    \
			    sp = AvARRAY(stack) + (sp - stack_base);	    \
			    stack_base = AvARRAY(stack);		    \
			    stack_max = stack_base + AvMAX(stack);	    \
			} } while (0)
/* Same thing, but update mark register too. */
#define MEXTEND(p,n)	do {if (stack_max - p < (n)) {			    \
			    av_fill(stack, (p - stack_base) + (n));	    \
			    sp   = AvARRAY(stack) + (sp   - stack_base);    \
			    mark = AvARRAY(stack) + (mark - stack_base);    \
			    stack_base = AvARRAY(stack);		    \
			    stack_max = stack_base + AvMAX(stack);	    \
			} } while (0)

#define PUSHs(s)	(*++sp = (s))
#define PUSHTARG	do { SvSETMAGIC(TARG); PUSHs(TARG); } while (0)
#define PUSHp(p,l)	do { sv_setpvn(TARG, (p), (l)); PUSHTARG; } while (0)
#define PUSHn(n)	do { sv_setnv(TARG, (n)); PUSHTARG; } while (0)
#define PUSHi(i)	do { sv_setiv(TARG, (i)); PUSHTARG; } while (0)

#define XPUSHs(s)	do { EXTEND(sp,1); (*++sp = (s)); } while (0)
#define XPUSHTARG	do { SvSETMAGIC(TARG); XPUSHs(TARG); } while (0)
#define XPUSHp(p,l)	do { sv_setpvn(TARG, (p), (l)); XPUSHTARG; } while (0)
#define XPUSHn(n)	do { sv_setnv(TARG, (n)); XPUSHTARG; } while (0)
#define XPUSHi(i)	do { sv_setiv(TARG, (i)); XPUSHTARG; } while (0)

#define MXPUSHs(s)	do { MEXTEND(sp,1); (*++sp = (s)); } while (0)
#define MXPUSHTARG	do { SvSETMAGIC(TARG); XPUSHs(TARG); } while (0)
#define MXPUSHp(p,l)	do { sv_setpvn(TARG, (p), (l)); XPUSHTARG; } while (0)
#define MXPUSHn(n)	do { sv_setnv(TARG, (n)); XPUSHTARG; } while (0)
#define MXPUSHi(i)	do { sv_setiv(TARG, (i)); XPUSHTARG; } while (0)

#define SETs(s)		(*sp = s)
#define SETTARG		do { SvSETMAGIC(TARG); SETs(TARG); } while (0)
#define SETp(p,l)	do { sv_setpvn(TARG, (p), (l)); SETTARG; } while (0)
#define SETn(n)		do { sv_setnv(TARG, (n)); SETTARG; } while (0)
#define SETi(i)		do { sv_setiv(TARG, (i)); SETTARG; } while (0)

#define dTOPss		SV *sv = TOPs
#define dPOPss		SV *sv = POPs
#define dTOPnv		double value = TOPn
#define dPOPnv		double value = POPn
#define dTOPiv		I32 value = TOPi
#define dPOPiv		I32 value = POPi

#define dPOPPOPssrl	SV *rstr = POPs; SV *lstr = POPs
#define dPOPPOPnnrl	double right = POPn; double left = POPn
#define dPOPPOPiirl	I32 right = POPi; I32 left = POPi

#define dPOPTOPssrl	SV *rstr = POPs; SV *lstr = TOPs
#define dPOPTOPnnrl	double right = POPn; double left = TOPn
#define dPOPTOPiirl	I32 right = POPi; I32 left = TOPi

#define RETPUSHYES	RETURNX(PUSHs(&sv_yes))
#define RETPUSHNO	RETURNX(PUSHs(&sv_no))
#define RETPUSHUNDEF	RETURNX(PUSHs(&sv_undef))

#define RETSETYES	RETURNX(SETs(&sv_yes))
#define RETSETNO	RETURNX(SETs(&sv_no))
#define RETSETUNDEF	RETURNX(SETs(&sv_undef))

#define ARGTARG		op->op_targ
#define MAXARG		op->op_private

#define SWITCHSTACK(f,t)	AvFILL(f) = sp - stack_base;		\
				stack_base = AvARRAY(t);		\
				stack_max = stack_base + AvMAX(t);	\
				sp = stack_base + AvFILL(t);		\
				stack = t;

/* XXX need to diffentiate on marked operators? */
#define FETCH_GV(s)  PUTBACK, s = fetch_gv(op,1), SPAGAIN
#define FETCH_GV1(s) PUTBACK, s = fetch_gv(op,1), SPAGAIN
#define FETCH_GV2(s) PUTBACK, s = fetch_gv(op,2), SPAGAIN
#define FETCH_IO(s)  PUTBACK, s = fetch_io(op,1), SPAGAIN
#define FETCH_IO1(s) PUTBACK, s = fetch_io(op,1), SPAGAIN
#define FETCH_IO2(s) PUTBACK, s = fetch_io(op,2), SPAGAIN

#define ENTER push_scope()
#define LEAVE pop_scope()

#define SAVEINT(i) save_int((int*)(&i));
#define SAVEI32(i) save_int((I32*)(&i));
#define SAVELONG(l) save_int((long*)(&l));
#define SAVESPTR(s) save_sptr((SV**)(&s))
#define SAVETMPS save_int(&tmps_floor), tmps_floor = tmps_ix
