/*
 * "...we will have peace, when you and all your works have perished--and
 * the works of your dark master to whom you would deliver us.  You are a
 * liar, Saruman, and a corrupter of men's hearts."  --Theoden
 */

#include "EXTERN.h"
#include "perl.h"

void
taint_proper(f, s)
const char *f;
char *s;
{
    char *ug;

    DEBUG_u(PerlIO_printf(PerlIO_stderr(),
            "%s %d %d %d\n", s, tainted, uid, euid));

    if (tainted) {
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
    MAGIC *mg;

#ifdef VMS
    int i = 0;
    char name[10 + TYPE_DIGITS(int)] = "DCL$PATH";

    while (1) {
	if (i)
	    (void)sprintf(name,"DCL$PATH;%d", i);
	svp = hv_fetch(GvHVn(envgv), name, strlen(name), FALSE);
	if (!svp || *svp == &sv_undef)
	    break;
	if (SvTAINTED(*svp)) {
	    TAINT;
	    taint_proper("Insecure %s%s", "$ENV{DCL$PATH}");
	}
	if ((mg = mg_find(*svp, 'e')) && MgTAINTEDDIR(mg)) {
	    TAINT;
	    taint_proper("Insecure directory in %s%s", "$ENV{DCL$PATH}");
	}
	i++;
    }
#endif /* VMS */

    svp = hv_fetch(GvHVn(envgv),"PATH",4,FALSE);
    if (svp && *svp) {
	if (SvTAINTED(*svp)) {
	    TAINT;
	    taint_proper("Insecure %s%s", "$ENV{PATH}");
	}
	if ((mg = mg_find(*svp, 'e')) && MgTAINTEDDIR(mg)) {
	    TAINT;
	    taint_proper("Insecure directory in %s%s", "$ENV{PATH}");
	}
    }

    svp = hv_fetch(GvHVn(envgv),"IFS",3,FALSE);
    if (svp && *svp != &sv_undef && SvTAINTED(*svp)) {
	TAINT;
	taint_proper("Insecure %s%s", "$ENV{IFS}");
    }
}
