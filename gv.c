/* $RCSfile: gv.c,v $$Revision: 4.1 $$Date: 92/08/07 18:26:39 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	gv.c,v $
 * Revision 4.1  92/08/07  18:26:39  lwall
 * 
 * Revision 4.0.1.4  92/06/08  15:32:19  lwall
 * patch20: fixed confusion between a *var's real name and its effective name
 * patch20: the debugger now warns you on lines that can't set a breakpoint
 * patch20: the debugger made perl forget the last pattern used by //
 * patch20: paragraph mode now skips extra newlines automatically
 * patch20: ($<,$>) = ... didn't work on some architectures
 * 
 * Revision 4.0.1.3  91/11/05  18:35:33  lwall
 * patch11: length($x) was sometimes wrong for numeric $x
 * patch11: perl now issues warning if $SIG{'ALARM'} is referenced
 * patch11: *foo = undef coredumped
 * patch11: solitary subroutine references no longer trigger typo warnings
 * patch11: local(*FILEHANDLE) had a memory leak
 * 
 * Revision 4.0.1.2  91/06/07  11:55:53  lwall
 * patch4: new copyright notice
 * patch4: added $^P variable to control calling of perldb routines
 * patch4: added $^F variable to specify maximum system fd, default 2
 * patch4: $` was busted inside s///
 * patch4: default top-of-form run_format is now FILEHANDLE_TOP
 * patch4: length($`), length($&), length($') now optimized to avoid string copy
 * patch4: $^D |= 1024 now does syntax tree dump at run-time
 * 
 * Revision 4.0.1.1  91/04/12  09:10:24  lwall
 * patch1: Configure now differentiates getgroups() type from getgid() type
 * patch1: you may now use "die" and "caller" in a signal handler
 * 
 * Revision 4.0  91/03/20  01:39:41  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

extern char* rcsid;

GV *
gv_AVadd(gv)
register GV *gv;
{
    if (!GvAV(gv))
	GvAV(gv) = newAV();
    return gv;
}

GV *
gv_HVadd(gv)
register GV *gv;
{
    if (!GvHV(gv))
	GvHV(gv) = newHV(COEFFSIZE);
    return gv;
}

GV *
gv_fetchfile(name)
char *name;
{
    char tmpbuf[1200];
    GV *gv;

    sprintf(tmpbuf,"'_<%s", name);
    gv = gv_fetchpv(tmpbuf, TRUE);
    sv_setpv(GvSV(gv), name);
    if (perldb)
	hv_magic(GvHVn(gv_AVadd(gv)), gv, 'L');
    return gv;
}

GV *
gv_fetchmethod(stash, name)
HV* stash;
char* name;
{
    AV* av;
    GV* gv;
    GV** gvp = (GV**)hv_fetch(stash,name,strlen(name),FALSE);
    if (gvp && (gv = *gvp) != (GV*)&sv_undef && GvCV(gv))
	return gv;

    gvp = (GV**)hv_fetch(stash,"ISA",3,FALSE);
    if (gvp && (gv = *gvp) != (GV*)&sv_undef && (av = GvAV(gv))) {
	SV** svp = AvARRAY(av);
	I32 items = AvFILL(av) + 1;
	while (items--) {
	    char tmpbuf[512];
	    SV* sv = *svp++;
	    *tmpbuf = '_';
	    SvUPGRADE(sv, SVt_PV);
	    strcpy(tmpbuf+1,SvPVn(sv));
	    gv = gv_fetchpv(tmpbuf,FALSE);
	    if (!gv || !(stash = GvHV(gv))) {
		if (dowarn)
		    warn("Can't locate package %s for @%s'ISA",
			SvPV(sv), HvNAME(stash));
		continue;
	    }
	    gv = gv_fetchmethod(stash, name);
	    if (gv)
		return gv;
	}
    }
    return 0;
}

GV *
gv_fetchpv(name,add)
register char *name;
I32 add;
{
    register GV *gv;
    GV**gvp;
    register GP *gp;
    I32 len;
    register char *namend;
    HV *stash;
    char *sawquote = Nullch;
    char *prevquote = Nullch;
    bool global = FALSE;

    if (isUPPER(*name)) {
	if (*name > 'I') {
	    if (*name == 'S' && (
	      strEQ(name, "SIG") ||
	      strEQ(name, "STDIN") ||
	      strEQ(name, "STDOUT") ||
	      strEQ(name, "STDERR") ))
		global = TRUE;
	}
	else if (*name > 'E') {
	    if (*name == 'I' && strEQ(name, "INC"))
		global = TRUE;
	}
	else if (*name > 'A') {
	    if (*name == 'E' && strEQ(name, "ENV"))
		global = TRUE;
	}
	else if (*name == 'A' && (
	  strEQ(name, "ARGV") ||
	  strEQ(name, "ARGVOUT") ))
	    global = TRUE;
    }
    for (namend = name; *namend; namend++) {
	if (*namend == '\'' && namend[1])
	    prevquote = sawquote, sawquote = namend;
    }
    if (sawquote == name && name[1]) {
	stash = defstash;
	sawquote = Nullch;
	name++;
    }
    else if (!isALPHA(*name) || global)
	stash = defstash;
    else if ((COP*)curcop == &compiling)
	stash = curstash;
    else
	stash = curcop->cop_stash;
    if (sawquote) {
	char tmpbuf[256];
	char *s, *d;

	*sawquote = '\0';
	/*SUPPRESS 560*/
	if (s = prevquote) {
	    strncpy(tmpbuf,name,s-name+1);
	    d = tmpbuf+(s-name+1);
	    *d++ = '_';
	    strcpy(d,s+1);
	}
	else {
	    *tmpbuf = '_';
	    strcpy(tmpbuf+1,name);
	}
	gv = gv_fetchpv(tmpbuf,TRUE);
	if (!(stash = GvHV(gv)))
	    stash = GvHV(gv) = newHV(0);
	if (!HvNAME(stash))
	    HvNAME(stash) = savestr(name);
	name = sawquote+1;
	*sawquote = '\'';
    }
    if (!stash)
	fatal("Global symbol \"%s\" requires explicit package name", name);
    len = namend - name;
    gvp = (GV**)hv_fetch(stash,name,len,add);
    if (!gvp || *gvp == (GV*)&sv_undef)
	return Nullgv;
    gv = *gvp;
    if (SvTYPE(gv) == SVt_PVGV) {
	SvMULTI_on(gv);
	return gv;
    }

    /* Adding a new symbol */

    sv_upgrade(gv, SVt_PVGV);
    if (SvLEN(gv))
	Safefree(SvPV(gv));
    Newz(602,gp, 1, GP);
    GvGP(gv) = gp;
    GvREFCNT(gv) = 1;
    GvSV(gv) = NEWSV(72,0);
    GvLINE(gv) = curcop->cop_line;
    GvEGV(gv) = gv;
    sv_magic((SV*)gv, (SV*)gv, '*', name, len);
    GvSTASH(gv) = stash;
    GvNAME(gv) = nsavestr(name, len);
    GvNAMELEN(gv) = len;
    if (isDIGIT(*name) && *name != '0')
	sv_magic(GvSV(gv), (SV*)gv, 0, name, len);
    if (add & 2)
	SvMULTI_on(gv);

    /* set up magic where warranted */
    switch (*name) {
    case 'S':
	if (strEQ(name, "SIG")) {
	    HV *hv;
	    siggv = gv;
	    SvMULTI_on(siggv);
	    hv = GvHVn(siggv);
	    hv_magic(hv, siggv, 'S');

	    /* initialize signal stack */
	    signalstack = newAV();
	    av_store(signalstack, 32, Nullsv);
	    av_clear(signalstack);
	    AvREAL_off(signalstack);
	}
	break;

    case '&':
	ampergv = gv;
	sawampersand = TRUE;
	goto magicalize;

    case '`':
	leftgv = gv;
	sawampersand = TRUE;
	goto magicalize;

    case '\'':
	rightgv = gv;
	sawampersand = TRUE;
	goto magicalize;

    case ':':
	sv_setpv(GvSV(gv),chopset);
	goto magicalize;

    case '!':
    case '#':
    case '?':
    case '^':
    case '~':
    case '=':
    case '-':
    case '%':
    case '.':
    case '+':
    case '*':
    case '(':
    case ')':
    case '<':
    case '>':
    case ',':
    case '\\':
    case '/':
    case '[':
    case '|':
    case '\004':
    case '\t':
    case '\020':
    case '\024':
    case '\027':
    case '\006':
      magicalize:
	sv_magic(GvSV(gv), (SV*)gv, 0, name, 1);
	break;

    case '\014':
	sv_setpv(GvSV(gv),"\f");
	formfeed = GvSV(gv);
	break;
    case ';':
	sv_setpv(GvSV(gv),"\034");
	break;
    case ']': {
	    SV *sv;
	    sv = GvSV(gv);
	    sv_upgrade(sv, SVt_PVNV);
	    sv_setpv(sv,rcsid);
	    SvNV(sv) = atof(patchlevel);
	    SvNOK_on(sv);
	}
	break;
    }
    return gv;
}

void
gv_fullname(sv,gv)
SV *sv;
GV *gv;
{
    HV *hv = GvSTASH(gv);

    if (!hv)
	return;
    sv_setpv(sv, sv == (SV*)gv ? "*" : "");
    sv_catpv(sv,HvNAME(hv));
    sv_catpvn(sv,"'", 1);
    sv_catpvn(sv,GvNAME(gv),GvNAMELEN(gv));
}

void
gv_efullname(sv,gv)
SV *sv;
GV *gv;
{
    GV* egv = GvEGV(gv);
    HV *hv = GvSTASH(egv);

    if (!hv)
	return;
    sv_setpv(sv, sv == (SV*)gv ? "*" : "");
    sv_catpv(sv,HvNAME(hv));
    sv_catpvn(sv,"'", 1);
    sv_catpvn(sv,GvNAME(egv),GvNAMELEN(egv));
}

IO *
newIO()
{
    IO *io;

    Newz(603,io,1,IO);
    io->page_len = 60;
    return io;
}

void
gv_check(min,max)
I32 min;
register I32 max;
{
    register HE *entry;
    register I32 i;
    register GV *gv;

    for (i = min; i <= max; i++) {
	for (entry = HvARRAY(defstash)[i]; entry; entry = entry->hent_next) {
	    gv = (GV*)entry->hent_val;
	    if (SvMULTI(gv))
		continue;
	    curcop->cop_line = GvLINE(gv);
	    warn("Possible typo: \"%s\"", GvNAME(gv));
	}
    }
}

GV *
newGVgen()
{
    (void)sprintf(tokenbuf,"_GEN_%d",gensym++);
    return gv_fetchpv(tokenbuf,TRUE);
}

/* hopefully this is only called on local symbol table entries */

GP*
gp_ref(gp)
GP* gp;
{
    gp->gp_refcnt++;
    return gp;

}

void
gp_free(gv)
GV* gv;
{
    IO *io;
    CV *cv;
    GP* gp;

    if (!gv || !(gp = GvGP(gv)))
	return;
    if (gp->gp_refcnt == 0) {
        warn("Attempt to free unreferenced glob pointers");
        return;
    }
    if (--gp->gp_refcnt > 0)
        return;

    sv_free(gp->gp_sv);
    sv_free(gp->gp_av);
    sv_free(gp->gp_hv);
    if (io = gp->gp_io) {
	do_close(gv,FALSE);
	Safefree(io->top_name);
	Safefree(io->fmt_name);
	Safefree(io);
    }
    if (cv = gp->gp_cv)
	sv_free(cv);
    Safefree(gp);
    GvGP(gv) = 0;
}

#if defined(CRIPPLED_CC) && (defined(iAPX286) || defined(M_I286) || defined(I80286))
#define MICROPORT
#endif

#ifdef	MICROPORT	/* Microport 2.4 hack */
AV *GvAVn(gv)
register GV *gv;
{
    if (GvGP(gv)->gp_av) 
	return GvGP(gv)->gp_av;
    else
	return GvGP(gv_AVadd(gv))->gp_av;
}

HV *GvHVn(gv)
register GV *gv;
{
    if (GvGP(gv)->gp_hv)
	return GvGP(gv)->gp_hv;
    else
	return GvGP(gv_HVadd(gv))->gp_hv;
}
#endif			/* Microport 2.4 hack */

GV *
fetch_gv(op,num)
OP *op;
I32 num;
{
    if (op->op_private < num)
	return 0;
    if (op->op_flags & OPf_STACKED)
        return gv_fetchpv(SvPVnx(*(stack_sp--)),TRUE);
    else
        return cGVOP->op_gv;
}

IO *
fetch_io(op,num)
OP *op;
I32 num;
{
    GV *gv;

    if (op->op_private < num)
	return 0;
    if (op->op_flags & OPf_STACKED)
        gv = gv_fetchpv(SvPVnx(*(stack_sp--)),TRUE);
    else
        gv = cGVOP->op_gv;

    if (!gv)
	return 0;

    return GvIOn(gv);
}
