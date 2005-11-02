/*    multicall.h		(version 1.0)
 *
 * Implements a poor-man's MULTICALL interface for old versions
 * of perl that don't offer a proper one. Intended to be compatible
 * with 5.6.0 and later.
 *
 */

#ifdef dMULTICALL
#define REAL_MULTICALL
#else
#undef REAL_MULTICALL

/* In versions of perl where MULTICALL is not defined (i.e. prior
 * to 5.9.4), Perl_pad_push is not exported either. It also has
 * an extra argument in older versions; certainly in the 5.8 series.
 * So we redefine it here.
 */

#ifndef AVf_REIFY
#  ifdef SVpav_REIFY
#    define AVf_REIFY SVpav_REIFY
#  else
#    error Neither AVf_REIFY nor SVpav_REIFY is defined
#  endif
#endif

#ifndef AvFLAGS
#  define AvFLAGS SvFLAGS
#endif

static void
multicall_pad_push(pTHX_ AV *padlist, int depth)
{
    if (depth <= AvFILLp(padlist))
	return;

    {
	SV** const svp = AvARRAY(padlist);
	AV* const newpad = newAV();
	SV** const oldpad = AvARRAY(svp[depth-1]);
	I32 ix = AvFILLp((AV*)svp[1]);
        const I32 names_fill = AvFILLp((AV*)svp[0]);
	SV** const names = AvARRAY(svp[0]);
	AV *av;

	for ( ;ix > 0; ix--) {
	    if (names_fill >= ix && names[ix] != &PL_sv_undef) {
		const char sigil = SvPVX(names[ix])[0];
		if ((SvFLAGS(names[ix]) & SVf_FAKE) || sigil == '&') {
		    /* outer lexical or anon code */
		    av_store(newpad, ix, SvREFCNT_inc(oldpad[ix]));
		}
		else {		/* our own lexical */
		    SV *sv; 
		    if (sigil == '@')
			sv = (SV*)newAV();
		    else if (sigil == '%')
			sv = (SV*)newHV();
		    else
			sv = NEWSV(0, 0);
		    av_store(newpad, ix, sv);
		    SvPADMY_on(sv);
		}
	    }
	    else if (IS_PADGV(oldpad[ix]) || IS_PADCONST(oldpad[ix])) {
		av_store(newpad, ix, SvREFCNT_inc(oldpad[ix]));
	    }
	    else {
		/* save temporaries on recursion? */
		SV * const sv = NEWSV(0, 0);
		av_store(newpad, ix, sv);
		SvPADTMP_on(sv);
	    }
	}
	av = newAV();
	av_extend(av, 0);
	av_store(newpad, 0, (SV*)av);
	AvFLAGS(av) = AVf_REIFY;

	av_store(padlist, depth, (SV*)newpad);
	AvFILLp(padlist) = depth;
    }
}

#define dMULTICALL \
    SV **newsp;			/* set by POPBLOCK */			\
    PERL_CONTEXT *cx;							\
    CV *cv;								\
    OP *multicall_cop;							\
    bool multicall_oldcatch;						\
    U8 hasargs = 0

/* Between 5.9.1 and 5.9.2 the retstack was removed, and the
   return op is now stored on the cxstack. */
#define HAS_RETSTACK (\
  PERL_REVISION < 5 || \
  (PERL_REVISION == 5 && PERL_VERSION < 9) || \
  (PERL_REVISION == 5 && PERL_VERSION == 9 && PERL_SUBVERSION < 2) \
)


/* PUSHSUB is defined so differently on different versions of perl
 * that it's easier to define our own version than code for all the
 * different possibilities.
 */
#if HAS_RETSTACK
#  define PUSHSUB_RETSTACK(cx)
#else
#  define PUSHSUB_RETSTACK(cx) cx->blk_sub.retop = Nullop;
#endif
#undef PUSHSUB
#define PUSHSUB(cx)                                                     \
        cx->blk_sub.cv = cv;                                            \
        cx->blk_sub.olddepth = CvDEPTH(cv);                             \
        cx->blk_sub.hasargs = hasargs;                                  \
        cx->blk_sub.lval = PL_op->op_private &                          \
                              (OPpLVAL_INTRO|OPpENTERSUB_INARGS);	\
	PUSHSUB_RETSTACK(cx)						\
        if (!CvDEPTH(cv)) {                                             \
            (void)SvREFCNT_inc(cv);                                     \
            (void)SvREFCNT_inc(cv);                                     \
            SAVEFREESV(cv);                                             \
        }

#define PUSH_MULTICALL \
    STMT_START {							\
	AV* padlist = CvPADLIST(cv);					\
	ENTER;								\
 	multicall_oldcatch = CATCH_GET;					\
	SAVESPTR(CvROOT(cv)->op_ppaddr);				\
	CvROOT(cv)->op_ppaddr = PL_ppaddr[OP_NULL];			\
	SAVETMPS; SAVEVPTR(PL_op);					\
	CATCH_SET(TRUE);						\
	PUSHSTACKi(PERLSI_SORT);					\
	PUSHBLOCK(cx, CXt_SUB, PL_stack_sp);				\
	PUSHSUB(cx);							\
	if (++CvDEPTH(cv) >= 2) {					\
	    PERL_STACK_OVERFLOW_CHECK();				\
	    multicall_pad_push(aTHX_ padlist, CvDEPTH(cv));		\
	}								\
	SAVECOMPPAD();							\
	PL_comppad = (AV*) (AvARRAY(padlist)[CvDEPTH(cv)]);		\
	PL_curpad = AvARRAY(PL_comppad);				\
	multicall_cop = CvSTART(cv);					\
    } STMT_END

#define MULTICALL \
    STMT_START {							\
	PL_op = multicall_cop;						\
	CALLRUNOPS(aTHX);						\
    } STMT_END

#define POP_MULTICALL \
    STMT_START {							\
	CvDEPTH(cv)--;							\
	LEAVESUB(cv);							\
	POPBLOCK(cx,PL_curpm);						\
	POPSTACK;							\
	CATCH_SET(multicall_oldcatch);					\
	LEAVE;								\
    } STMT_END

#endif
