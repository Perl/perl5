/*    run.c
 *
 *    Copyright (c) 1991-1997, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "EXTERN.h"
#include "perl.h"

/*
 * "Away now, Shadowfax!  Run, greatheart, run as you have never run before!
 * Now we are come to the lands where you were foaled, and every stone you
 * know.  Run now!  Hope is in speed!"  --Gandalf
 */

dEXT char **watchaddr = 0;
dEXT char *watchok;

int
runops_standard(void) {
    dTHR;

    while ( op = (*op->op_ppaddr)(ARGS) ) ;

    TAINT_NOT;
    return 0;
}

#ifdef DEBUGGING
static void debprof _((OP*o));

int
runops_debug(void) {
    dTHR;
    if (!op) {
	warn("NULL OP IN RUN");
	return 0;
    }

    do {
	if (debug) {
	    if (watchaddr != 0 && *watchaddr != watchok)
		PerlIO_printf(Perl_debug_log, "WARNING: %lx changed from %lx to %lx\n",
		    (long)watchaddr, (long)watchok, (long)*watchaddr);
	    DEBUG_s(debstack());
	    DEBUG_t(debop(op));
	    DEBUG_P(debprof(op));
	}
    } while ( op = (*op->op_ppaddr)(ARGS) );

    TAINT_NOT;
    return 0;
}

I32
debop(OP *o)
{
    SV *sv;
    deb("%s", op_name[o->op_type]);
    switch (o->op_type) {
    case OP_CONST:
	PerlIO_printf(Perl_debug_log, "(%s)", SvPEEK(cSVOPo->op_sv));
	break;
    case OP_GVSV:
    case OP_GV:
	if (cGVOPo->op_gv) {
	    sv = NEWSV(0,0);
	    gv_fullname3(sv, cGVOPo->op_gv, Nullch);
	    PerlIO_printf(Perl_debug_log, "(%s)", SvPV(sv, na));
	    SvREFCNT_dec(sv);
	}
	else
	    PerlIO_printf(Perl_debug_log, "(NULL)");
	break;
    default:
	break;
    }
    PerlIO_printf(Perl_debug_log, "\n");
    return 0;
}

void
watch(char **addr)
{
    watchaddr = addr;
    watchok = *addr;
    PerlIO_printf(Perl_debug_log, "WATCHING, %lx is currently %lx\n",
	(long)watchaddr, (long)watchok);
}

static void
debprof(OP *o)
{
    if (!profiledata)
	New(000, profiledata, MAXO, U32);
    ++profiledata[o->op_type];
}

void
debprofdump(void)
{
    unsigned i;
    if (!profiledata)
	return;
    for (i = 0; i < MAXO; i++) {
	if (profiledata[i])
	    PerlIO_printf(Perl_debug_log,
			  "%u\t%lu\n", i, (unsigned long)profiledata[i]);
    }
}

#endif

