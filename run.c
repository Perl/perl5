/*    run.c
 *
 *    Copyright (c) 1991-2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "EXTERN.h"
#define PERL_IN_RUN_C
#include "perl.h"

/*
 * "Away now, Shadowfax!  Run, greatheart, run as you have never run before!
 * Now we are come to the lands where you were foaled, and every stone you
 * know.  Run now!  Hope is in speed!"  --Gandalf
 */

int
Perl_runops_standard(pTHX)
{
    while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX))) {
	PERL_ASYNC_CHECK();
    }

    TAINT_NOT;
    return 0;
}

int
Perl_runops_debug(pTHX)
{
#ifdef DEBUGGING
    if (!PL_op) {
	if (ckWARN_d(WARN_DEBUGGING))
	    Perl_warner(aTHX_ WARN_DEBUGGING, "NULL OP IN RUN");
	return 0;
    }

    do {
	PERL_ASYNC_CHECK();
	if (PL_debug) {
	    if (PL_watchaddr != 0 && *PL_watchaddr != PL_watchok)
		PerlIO_printf(Perl_debug_log,
			      "WARNING: %"UVxf" changed from %"UVxf" to %"UVxf"\n",
			      PTR2UV(PL_watchaddr), PTR2UV(PL_watchok),
			      PTR2UV(*PL_watchaddr));
	    DEBUG_s(debstack());
	    DEBUG_t(debop(PL_op));
	    DEBUG_P(debprof(PL_op));
	}
    } while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));

    TAINT_NOT;
    return 0;
#else
    return runops_standard();
#endif	/* DEBUGGING */
}

I32
Perl_debop(pTHX_ OP *o)
{
#ifdef DEBUGGING
    AV *padlist, *comppad;
    CV *cv;
    SV *sv;
    STRLEN n_a;
    Perl_deb(aTHX_ "%s", PL_op_name[o->op_type]);
    switch (o->op_type) {
    case OP_CONST:
	PerlIO_printf(Perl_debug_log, "(%s)", SvPEEK(cSVOPo_sv));
	break;
    case OP_GVSV:
    case OP_GV:
	if (cGVOPo_gv) {
	    sv = NEWSV(0,0);
	    gv_fullname3(sv, cGVOPo_gv, Nullch);
	    PerlIO_printf(Perl_debug_log, "(%s)", SvPV(sv, n_a));
	    SvREFCNT_dec(sv);
	}
	else
	    PerlIO_printf(Perl_debug_log, "(NULL)");
	break;
    case OP_PADSV:
    case OP_PADAV:
    case OP_PADHV:
	/* print the lexical's name */
        cv = deb_curcv(cxstack_ix);
        if (cv) {
            padlist = CvPADLIST(cv);
            comppad = (AV*)(*av_fetch(padlist, 0, FALSE));
            sv = *av_fetch(comppad, o->op_targ, FALSE);
        } else
            sv = Nullsv;
        if (sv)
           PerlIO_printf(Perl_debug_log, "(%s)", SvPV_nolen(sv));
        else
           PerlIO_printf(Perl_debug_log, "[%"UVuf"]", (UV)o->op_targ);
        break;
    default:
	break;
    }
    PerlIO_printf(Perl_debug_log, "\n");
#endif	/* DEBUGGING */
    return 0;
}

STATIC CV*
S_deb_curcv(I32 ix)
{
#ifdef DEBUGGING
    PERL_CONTEXT *cx = &cxstack[ix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT)
        return cx->blk_sub.cv;
    else if (CxTYPE(cx) == CXt_EVAL && CxREALEVAL(cx))
        return PL_compcv;
    else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx))
        return PL_compcv;
    else if (ix == 0 && PL_curstackinfo->si_type == PERLSI_MAIN)
        return PL_main_cv;
    else if (ix <= 0)
        return Nullcv;
    else
        return deb_curcv(ix - 1);
#else
    return Nullcv;
#endif  /* DEBUGGING */
}

void
Perl_watch(pTHX_ char **addr)
{
#ifdef DEBUGGING
    PL_watchaddr = addr;
    PL_watchok = *addr;
    PerlIO_printf(Perl_debug_log, "WATCHING, %"UVxf" is currently %"UVxf"\n",
	PTR2UV(PL_watchaddr), PTR2UV(PL_watchok));
#endif	/* DEBUGGING */
}

STATIC void
S_debprof(pTHX_ OP *o)
{
#ifdef DEBUGGING
    if (!PL_profiledata)
	Newz(000, PL_profiledata, MAXO, U32);
    ++PL_profiledata[o->op_type];
#endif /* DEBUGGING */
}

void
Perl_debprofdump(pTHX)
{
#ifdef DEBUGGING
    unsigned i;
    if (!PL_profiledata)
	return;
    for (i = 0; i < MAXO; i++) {
	if (PL_profiledata[i])
	    PerlIO_printf(Perl_debug_log,
			  "%5lu %s\n", (unsigned long)PL_profiledata[i],
                                       PL_op_name[i]);
    }
#endif	/* DEBUGGING */
}
