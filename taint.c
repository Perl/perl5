void
taint_proper(f, s)
char *f;
char *s;
{
    DEBUG_u(fprintf(stderr,"%s %d %d %d\n",s,tainted,uid, euid));
    if (tainted && (!euid || euid != uid || egid != gid || taintanyway)) {
	if (!unsafe)
	    fatal(f, s);
	else if (dowarn)
	    warn(f, s);
    }
}

void
taint_env()
{
    SV** svp;

    svp = hv_fetch(GvHVn(envgv),"PATH",4,FALSE);
    if (!svp || *svp == &sv_undef || (*svp)->sv_tainted) {
	tainted = 1;
	if ((*svp)->sv_tainted == 2)
	    taint_proper("Insecure directory in %s", "PATH");
	else
	    taint_proper("Insecure %s", "PATH");
    }
    svp = hv_fetch(GvHVn(envgv),"IFS",3,FALSE);
    if (svp && *svp != &sv_undef && (*svp)->sv_tainted) {
	tainted = 1;
	taint_proper("Insecure %s", "IFS");
    }
}

