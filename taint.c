/*
 * "...we will have peace, when you and all your works have perished--and
 * the works of your dark master to whom you would deliver us.  You are a
 * liar, Saruman, and a corrupter of men's hearts."  --Theoden
 */

#include "EXTERN.h"
#include "perl.h"

void
taint_proper(f, s)
char *f;
char *s;
{
    char *ug;

    if (tainted) {
	DEBUG_u(PerlIO_printf(PerlIO_stderr(),
			      "%s %d %d %d\n", s, tainted, uid, euid));
	if (euid != uid)
	    ug = " while running setuid";
	else if (egid != gid)
	    ug = " while running setgid";
	else
	    ug = " while running with -T switch";
	if (!unsafe)
	    croak(f, s, ug);
	else if (dowarn)
	    warn(f, s, ug);
    }
}

void
taint_env()
{
    SV** svp;
    MAGIC *mg = 0;

    svp = hv_fetch(GvHVn(envgv),"PATH",4,FALSE);
    if (!svp || *svp == &sv_undef ||
	((mg = mg_find(*svp, 't')) && mg->mg_len & 1))
    {
	TAINT;
	if (mg && MgTAINTEDDIR(mg))
	    taint_proper("Insecure directory in %s%s", "$ENV{PATH}");
	else
	    taint_proper("Insecure %s%s", "$ENV{PATH}");
    }

    svp = hv_fetch(GvHVn(envgv),"IFS",3,FALSE);
    if (svp && *svp != &sv_undef &&
	(mg = mg_find(*svp, 't')) && mg->mg_len & 1)
    {
	TAINT;
	taint_proper("Insecure %s%s", "$ENV{IFS}");
    }
}
