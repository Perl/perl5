/* $RCSfile: hash.c,v $$Revision: 4.1 $$Date: 92/08/07 18:21:48 $
 *
 *    Copyright (c) 1993, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:        hash.c,v $
 */

#include "EXTERN.h"
#include "perl.h"

int
mg_get(sv)
SV* sv;
{
    MAGIC* mg;

    SvMAGICAL_off(sv);
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    SvFLAGS(sv) |= SvPRIVATE(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
    SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);

    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
	MGVTBL* vtbl = mg->mg_virtual;
	if (vtbl && vtbl->svt_get)
	    (*vtbl->svt_get)(sv, mg);
    }

    SvMAGICAL_on(sv);
    SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    SvPRIVATE(sv) |= SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);

    return 0;
}

int
mg_set(sv)
SV* sv;
{
    MAGIC* mg;
    MAGIC* nextmg;

    SvMAGICAL_off(sv);

    for (mg = SvMAGIC(sv); mg; mg = nextmg) {
	MGVTBL* vtbl = mg->mg_virtual;
	nextmg = mg->mg_moremagic;	/* it may delete itself */
	if (vtbl && vtbl->svt_set)
	    (*vtbl->svt_set)(sv, mg);
    }

    if (SvMAGIC(sv)) {
	SvMAGICAL_on(sv);
/*	SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);  */
	SvPRIVATE(sv) |= SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
	SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    }

    return 0;
}

U32
mg_len(sv)
SV* sv;
{
    MAGIC* mg;
    char *s;
    STRLEN len;

    SvMAGICAL_off(sv);
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    SvFLAGS(sv) |= SvPRIVATE(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
    SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);

    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
	MGVTBL* vtbl = mg->mg_virtual;
	if (vtbl && vtbl->svt_len)
	    return (*vtbl->svt_len)(sv, mg);
    }
    mg_get(sv);
    s = SvPV(sv, len);

    SvMAGICAL_on(sv);
    SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    SvPRIVATE(sv) |= SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);

    return len;
}

int
mg_clear(sv)
SV* sv;
{
    MAGIC* mg;

    SvMAGICAL_off(sv);
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    SvFLAGS(sv) |= SvPRIVATE(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
    SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);

    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
	MGVTBL* vtbl = mg->mg_virtual;
	if (vtbl && vtbl->svt_clear)
	    (*vtbl->svt_clear)(sv, mg);
    }

    SvMAGICAL_on(sv);
    SvPRIVATE(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    SvPRIVATE(sv) |= SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK);
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);

    return 0;
}

MAGIC*
mg_find(sv, type)
SV* sv;
char type;
{
    MAGIC* mg;
    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
	if (mg->mg_type == type)
	    return mg;
    }
    return 0;
}

int
mg_copy(sv, nsv, key, klen)
SV* sv;
SV* nsv;
char *key;
STRLEN klen;
{
    int count = 0;
    MAGIC* mg;
    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
	if (isUPPER(mg->mg_type)) {
	    sv_magic(nsv, mg->mg_obj, tolower(mg->mg_type), key, klen);
	    count++;
	}
    }
    return count;
}

int
mg_free(sv)
SV* sv;
{
    MAGIC* mg;
    MAGIC* moremagic;
    for (mg = SvMAGIC(sv); mg; mg = moremagic) {
	MGVTBL* vtbl = mg->mg_virtual;
	moremagic = mg->mg_moremagic;
	if (vtbl && vtbl->svt_free)
	    (*vtbl->svt_free)(sv, mg);
	if (mg->mg_ptr && mg->mg_type != 'g')
	    Safefree(mg->mg_ptr);
	sv_free(mg->mg_obj);
	Safefree(mg);
    }
    SvMAGIC(sv) = 0;
    return 0;
}

#if !defined(NSIG) || defined(M_UNIX) || defined(M_XENIX)
#include <signal.h>
#endif

#ifdef VOIDSIG
#define handlertype void
#else
#define handlertype int
#endif

static handlertype sighandler();

U32
magic_len(sv, mg)
SV *sv;
MAGIC *mg;
{
    register I32 paren;
    register char *s;
    register I32 i;

    switch (*mg->mg_ptr) {
    case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9': case '&':
	if (curpm) {
	    paren = atoi(mg->mg_ptr);
	  getparen:
	    if (curpm->op_pmregexp &&
	      paren <= curpm->op_pmregexp->nparens &&
	      (s = curpm->op_pmregexp->startp[paren]) ) {
		i = curpm->op_pmregexp->endp[paren] - s;
		if (i >= 0)
		    return i;
		else
		    return 0;
	    }
	    else
		return 0;
	}
	break;
    case '+':
	if (curpm) {
	    paren = curpm->op_pmregexp->lastparen;
	    goto getparen;
	}
	break;
    case '`':
	if (curpm) {
	    if (curpm->op_pmregexp &&
	      (s = curpm->op_pmregexp->subbeg) ) {
		i = curpm->op_pmregexp->startp[0] - s;
		if (i >= 0)
		    return i;
		else
		    return 0;
	    }
	    else
		return 0;
	}
	break;
    case '\'':
	if (curpm) {
	    if (curpm->op_pmregexp &&
	      (s = curpm->op_pmregexp->endp[0]) ) {
		return (STRLEN) (curpm->op_pmregexp->subend - s);
	    }
	    else
		return 0;
	}
	break;
    case ',':
	return (STRLEN)ofslen;
    case '\\':
	return (STRLEN)orslen;
    }
    magic_get(sv,mg);
    if (!SvPOK(sv) && SvNIOK(sv))
	sv_2pv(sv, &na);
    if (SvPOK(sv))
	return SvCUR(sv);
    return 0;
}

int
magic_get(sv, mg)
SV *sv;
MAGIC *mg;
{
    register I32 paren;
    register char *s;
    register I32 i;

    switch (*mg->mg_ptr) {
    case '\004':		/* ^D */
	sv_setiv(sv,(I32)(debug & 32767));
	break;
    case '\006':		/* ^F */
	sv_setiv(sv,(I32)maxsysfd);
	break;
    case '\t':			/* ^I */
	if (inplace)
	    sv_setpv(sv, inplace);
	else
	    sv_setsv(sv,&sv_undef);
	break;
    case '\020':		/* ^P */
	sv_setiv(sv,(I32)perldb);
	break;
    case '\024':		/* ^T */
	sv_setiv(sv,(I32)basetime);
	break;
    case '\027':		/* ^W */
	sv_setiv(sv,(I32)dowarn);
	break;
    case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9': case '&':
	if (curpm) {
	    paren = atoi(GvENAME(mg->mg_obj));
	  getparen:
	    if (curpm->op_pmregexp &&
	      paren <= curpm->op_pmregexp->nparens &&
	      (s = curpm->op_pmregexp->startp[paren]) ) {
		i = curpm->op_pmregexp->endp[paren] - s;
		if (i >= 0)
		    sv_setpvn(sv,s,i);
		else
		    sv_setsv(sv,&sv_undef);
	    }
	    else
		sv_setsv(sv,&sv_undef);
	}
	break;
    case '+':
	if (curpm) {
	    paren = curpm->op_pmregexp->lastparen;
	    goto getparen;
	}
	break;
    case '`':
	if (curpm) {
	    if (curpm->op_pmregexp &&
	      (s = curpm->op_pmregexp->subbeg) ) {
		i = curpm->op_pmregexp->startp[0] - s;
		if (i >= 0)
		    sv_setpvn(sv,s,i);
		else
		    sv_setpvn(sv,"",0);
	    }
	    else
		sv_setpvn(sv,"",0);
	}
	break;
    case '\'':
	if (curpm) {
	    if (curpm->op_pmregexp &&
	      (s = curpm->op_pmregexp->endp[0]) ) {
		sv_setpvn(sv,s, curpm->op_pmregexp->subend - s);
	    }
	    else
		sv_setpvn(sv,"",0);
	}
	break;
    case '.':
#ifndef lint
	if (last_in_gv && GvIO(last_in_gv)) {
	    sv_setiv(sv,(I32)GvIO(last_in_gv)->lines);
	}
#endif
	break;
    case '?':
	sv_setiv(sv,(I32)statusvalue);
	break;
    case '^':
	s = GvIO(defoutgv)->top_name;
	if (s)
	    sv_setpv(sv,s);
	else {
	    sv_setpv(sv,GvENAME(defoutgv));
	    sv_catpv(sv,"_TOP");
	}
	break;
    case '~':
	s = GvIO(defoutgv)->fmt_name;
	if (!s)
	    s = GvENAME(defoutgv);
	sv_setpv(sv,s);
	break;
#ifndef lint
    case '=':
	sv_setiv(sv,(I32)GvIO(defoutgv)->page_len);
	break;
    case '-':
	sv_setiv(sv,(I32)GvIO(defoutgv)->lines_left);
	break;
    case '%':
	sv_setiv(sv,(I32)GvIO(defoutgv)->page);
	break;
#endif
    case ':':
	break;
    case '/':
	break;
    case '[':
	sv_setiv(sv,(I32)arybase);
	break;
    case '|':
	if (!GvIO(defoutgv))
	    GvIO(defoutgv) = newIO();
	sv_setiv(sv, (GvIO(defoutgv)->flags & IOf_FLUSH) != 0 );
	break;
    case ',':
	sv_setpvn(sv,ofs,ofslen);
	break;
    case '\\':
	sv_setpvn(sv,ors,orslen);
	break;
    case '#':
	sv_setpv(sv,ofmt);
	break;
    case '!':
	sv_setnv(sv,(double)errno);
	sv_setpv(sv, errno ? strerror(errno) : "");
	SvNOK_on(sv);	/* what a wonderful hack! */
	break;
    case '<':
	sv_setiv(sv,(I32)uid);
	break;
    case '>':
	sv_setiv(sv,(I32)euid);
	break;
    case '(':
	s = buf;
	(void)sprintf(s,"%d",(int)gid);
	goto add_groups;
    case ')':
	s = buf;
	(void)sprintf(s,"%d",(int)egid);
      add_groups:
	while (*s) s++;
#ifdef HAS_GETGROUPS
#ifndef NGROUPS
#define NGROUPS 32
#endif
	{
	    GROUPSTYPE gary[NGROUPS];

	    i = getgroups(NGROUPS,gary);
	    while (--i >= 0) {
		(void)sprintf(s," %ld", (long)gary[i]);
		while (*s) s++;
	    }
	}
#endif
	sv_setpv(sv,buf);
	break;
    case '*':
	break;
    case '0':
	break;
    }
}

int
magic_getuvar(sv, mg)
SV *sv;
MAGIC *mg;
{
    struct ufuncs *uf = (struct ufuncs *)mg->mg_ptr;

    if (uf && uf->uf_val)
	(*uf->uf_val)(uf->uf_index, sv);
    return 0;
}

int
magic_setenv(sv,mg)
SV* sv;
MAGIC* mg;
{
    register char *s;
    I32 i;
    s = SvPVX(sv);
    my_setenv(mg->mg_ptr,s);
			    /* And you'll never guess what the dog had */
			    /*   in its mouth... */
    if (tainting) {
	if (s && strEQ(mg->mg_ptr,"PATH")) {
	    char *strend = SvEND(sv);

	    while (s < strend) {
		s = cpytill(tokenbuf,s,strend,':',&i);
		s++;
		if (*tokenbuf != '/'
		  || (stat(tokenbuf,&statbuf) && (statbuf.st_mode & 2)) )
		    SvPRIVATE(sv) |= SVp_TAINTEDDIR;
	    }
	}
    }
    return 0;
}

int
magic_setsig(sv,mg)
SV* sv;
MAGIC* mg;
{
    register char *s;
    I32 i;
    s = SvPVX(sv);
    i = whichsig(mg->mg_ptr);	/* ...no, a brick */
    if (!i && (dowarn || strEQ(mg->mg_ptr,"ALARM")))
	warn("No such signal: SIG%s", mg->mg_ptr);
    if (strEQ(s,"IGNORE"))
#ifndef lint
	(void)signal(i,SIG_IGN);
#else
	;
#endif
    else if (strEQ(s,"DEFAULT") || !*s)
	(void)signal(i,SIG_DFL);
    else {
	(void)signal(i,sighandler);
	if (!strchr(s,'\'')) {
	    sprintf(tokenbuf, "main'%s",s);
	    sv_setpv(sv,tokenbuf);
	}
    }
    return 0;
}

int
magic_setisa(sv,mg)
SV* sv;
MAGIC* mg;
{
    sub_generation++;
    return 0;
}

int
magic_getpack(sv,mg)
SV* sv;
MAGIC* mg;
{
    SV* rv = mg->mg_obj;
    HV* stash = SvSTASH((SV*)SvANY(rv));
    GV* gv = gv_fetchmethod(stash, "fetch");
    dSP;
    BINOP myop;

    if (!gv || !GvCV(gv)) {
	croak("No fetch method for magical variable in package \"%s\"",
	    HvNAME(stash));
    }
    Zero(&myop, 1, BINOP);
    myop.op_last = (OP *) &myop;
    myop.op_next = Nullop;
    myop.op_flags = OPf_STACKED;

    ENTER;
    SAVESPTR(op);
    op = (OP *) &myop;
    PUTBACK;
    pp_pushmark();

    EXTEND(sp, 4);
    PUSHs(gv);
    PUSHs(rv);
    if (mg->mg_ptr)
	PUSHs(sv_mortalcopy(newSVpv(mg->mg_ptr, mg->mg_len)));
    else if (mg->mg_len >= 0)
	PUSHs(sv_mortalcopy(newSViv(mg->mg_len)));
    PUTBACK;

    if (op = pp_entersubr())
	run();
    LEAVE;
    SPAGAIN;

    sv_setsv(sv, POPs);
    PUTBACK;

    return 0;
}

int
magic_setpack(sv,mg)
SV* sv;
MAGIC* mg;
{
    SV* rv = mg->mg_obj;
    HV* stash = SvSTASH((SV*)SvANY(rv));
    GV* gv = gv_fetchmethod(stash, "store");
    dSP;
    BINOP myop;

    if (!gv || !GvCV(gv)) {
	croak("No store method for magical variable in package \"%s\"",
	    HvNAME(stash));
    }
    Zero(&myop, 1, BINOP);
    myop.op_last = (OP *) &myop;
    myop.op_next = Nullop;
    myop.op_flags = OPf_STACKED;

    ENTER;
    SAVESPTR(op);
    op = (OP *) &myop;
    PUTBACK;
    pp_pushmark();

    EXTEND(sp, 4);
    PUSHs(gv);
    PUSHs(rv);
    if (mg->mg_ptr)
	PUSHs(sv_mortalcopy(newSVpv(mg->mg_ptr, mg->mg_len)));
    else if (mg->mg_len >= 0)
	PUSHs(sv_mortalcopy(newSViv(mg->mg_len)));
    PUSHs(sv);
    PUTBACK;

    if (op = pp_entersubr())
	run();
    LEAVE;
    SPAGAIN;

    POPs;
    PUTBACK;

    return 0;
}

int
magic_clearpack(sv,mg)
SV* sv;
MAGIC* mg;
{
    SV* rv = mg->mg_obj;
    HV* stash = SvSTASH((SV*)SvANY(rv));
    GV* gv = gv_fetchmethod(stash, "delete");
    dSP;
    BINOP myop;

    if (!gv || !GvCV(gv)) {
	croak("No delete method for magical variable in package \"%s\"",
	    HvNAME(stash));
    }
    Zero(&myop, 1, BINOP);
    myop.op_last = (OP *) &myop;
    myop.op_next = Nullop;
    myop.op_flags = OPf_STACKED;

    ENTER;
    SAVESPTR(op);
    op = (OP *) &myop;
    PUTBACK;
    pp_pushmark();

    EXTEND(sp, 4);
    PUSHs(gv);
    PUSHs(rv);
    if (mg->mg_ptr)
	PUSHs(sv_mortalcopy(newSVpv(mg->mg_ptr, mg->mg_len)));
    else
	PUSHs(sv_mortalcopy(newSViv(mg->mg_len)));
    PUTBACK;

    if (op = pp_entersubr())
	run();
    LEAVE;
    SPAGAIN;

    sv_setsv(sv, POPs);
    PUTBACK;

    return 0;
}

int
magic_nextpack(sv,mg,key)
SV* sv;
MAGIC* mg;
SV* key;
{
    SV* rv = mg->mg_obj;
    HV* stash = SvSTASH((SV*)SvANY(rv));
    GV* gv = gv_fetchmethod(stash, SvOK(key) ? "nextkey" : "firstkey");
    dSP;
    BINOP myop;

    if (!gv || !GvCV(gv)) {
	croak("No fetch method for magical variable in package \"%s\"",
	    HvNAME(stash));
    }
    Zero(&myop, 1, BINOP);
    myop.op_last = (OP *) &myop;
    myop.op_next = Nullop;
    myop.op_flags = OPf_STACKED;

    ENTER;
    SAVESPTR(op);
    op = (OP *) &myop;
    PUTBACK;
    pp_pushmark();

    EXTEND(sp, 4);
    PUSHs(gv);
    PUSHs(rv);
    if (SvOK(key))
	PUSHs(key);
    PUTBACK;

    if (op = pp_entersubr())
	run();
    LEAVE;
    SPAGAIN;

    sv_setsv(key, POPs);
    PUTBACK;

    return 0;
}

int
magic_setdbline(sv,mg)
SV* sv;
MAGIC* mg;
{
    OP *o;
    I32 i;
    GV* gv;
    SV** svp;

    gv = DBline;
    i = SvTRUE(sv);
    svp = av_fetch(GvAV(gv),atoi(mg->mg_ptr), FALSE);
    if (svp && SvIOK(*svp) && (o = (OP*)SvSTASH(*svp)))
	o->op_private = i;
    else
	warn("Can't break at that line\n");
    return 0;
}

int
magic_getarylen(sv,mg)
SV* sv;
MAGIC* mg;
{
    sv_setiv(sv, AvFILL((AV*)mg->mg_obj) + arybase);
    return 0;
}

int
magic_setarylen(sv,mg)
SV* sv;
MAGIC* mg;
{
    av_fill((AV*)mg->mg_obj, (SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv)) - arybase);
    return 0;
}

int
magic_getglob(sv,mg)
SV* sv;
MAGIC* mg;
{
    gv_efullname(sv,((GV*)sv));/* a gv value, be nice */
    return 0;
}

int
magic_setglob(sv,mg)
SV* sv;
MAGIC* mg;
{
    register char *s;
    GV* gv;

    if (!SvOK(sv))
	return 0;
    s = SvPV(sv, na);
    if (*s == '*' && s[1])
	s++;
    gv = gv_fetchpv(s,TRUE);
    if (sv == (SV*)gv)
	return 0;
    if (GvGP(sv))
	gp_free(sv);
    GvGP(sv) = gp_ref(GvGP(gv));
    if (!GvAV(gv))
	gv_AVadd(gv);
    if (!GvHV(gv))
	gv_HVadd(gv);
    if (!GvIO(gv))
	GvIO(gv) = newIO();
    return 0;
}

int
magic_setsubstr(sv,mg)
SV* sv;
MAGIC* mg;
{
    char *tmps = SvPVX(sv);
    if (!tmps)
	tmps = "";
    sv_insert(LvTARG(sv),LvTARGOFF(sv),LvTARGLEN(sv), tmps,SvCUR(sv));
    return 0;
}

int
magic_gettaint(sv,mg)
SV* sv;
MAGIC* mg;
{
    tainted = TRUE;
    return 0;
}

int
magic_settaint(sv,mg)
SV* sv;
MAGIC* mg;
{
    if (!tainted)
	sv_unmagic(sv, 't');
    return 0;
}

int
magic_setvec(sv,mg)
SV* sv;
MAGIC* mg;
{
    do_vecset(sv);	/* XXX slurp this routine */
    return 0;
}

int
magic_setmglob(sv,mg)
SV* sv;
MAGIC* mg;
{
    mg->mg_ptr = 0;
    mg->mg_len = 0;
    return 0;
}

int
magic_setbm(sv,mg)
SV* sv;
MAGIC* mg;
{
    sv_unmagic(sv, 'B');
    SvVALID_off(sv);
    return 0;
}

int
magic_setuvar(sv,mg)
SV* sv;
MAGIC* mg;
{
    struct ufuncs *uf = (struct ufuncs *)mg->mg_ptr;

    if (uf && uf->uf_set)
	(*uf->uf_set)(uf->uf_index, sv);
    return 0;
}

int
magic_set(sv,mg)
SV* sv;
MAGIC* mg;
{
    register char *s;
    I32 i;
    switch (*mg->mg_ptr) {
    case '\004':	/* ^D */
	debug = (SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv)) | 32768;
	DEBUG_x(dump_all());
	break;
    case '\006':	/* ^F */
	maxsysfd = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	break;
    case '\t':	/* ^I */
	if (inplace)
	    Safefree(inplace);
	if (SvOK(sv))
	    inplace = savestr(SvPVX(sv));
	else
	    inplace = Nullch;
	break;
    case '\020':	/* ^P */
	i = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	if (i != perldb) {
	    if (perldb)
		oldlastpm = curpm;
	    else
		curpm = oldlastpm;
	}
	perldb = i;
	break;
    case '\024':	/* ^T */
	basetime = (time_t)(SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv));
	break;
    case '\027':	/* ^W */
	dowarn = (bool)(SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv));
	break;
    case '.':
	if (localizing)
	    save_sptr((SV**)&last_in_gv);
	break;
    case '^':
	Safefree(GvIO(defoutgv)->top_name);
	GvIO(defoutgv)->top_name = s = savestr(SvPVX(sv));
	GvIO(defoutgv)->top_gv = gv_fetchpv(s,TRUE);
	break;
    case '~':
	Safefree(GvIO(defoutgv)->fmt_name);
	GvIO(defoutgv)->fmt_name = s = savestr(SvPVX(sv));
	GvIO(defoutgv)->fmt_gv = gv_fetchpv(s,TRUE);
	break;
    case '=':
	GvIO(defoutgv)->page_len = (long)(SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv));
	break;
    case '-':
	GvIO(defoutgv)->lines_left = (long)(SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv));
	if (GvIO(defoutgv)->lines_left < 0L)
	    GvIO(defoutgv)->lines_left = 0L;
	break;
    case '%':
	GvIO(defoutgv)->page = (long)(SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv));
	break;
    case '|':
	if (!GvIO(defoutgv))
	    GvIO(defoutgv) = newIO();
	GvIO(defoutgv)->flags &= ~IOf_FLUSH;
	if ((SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv)) != 0) {
	    GvIO(defoutgv)->flags |= IOf_FLUSH;
	}
	break;
    case '*':
	i = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	multiline = (i != 0);
	break;
    case '/':
	if (SvPOK(sv)) {
	    nrs = rs = SvPVX(sv);
	    nrslen = rslen = SvCUR(sv);
	    if (rspara = !rslen) {
		nrs = rs = "\n\n";
		nrslen = rslen = 2;
	    }
	    nrschar = rschar = rs[rslen - 1];
	}
	else {
	    nrschar = rschar = 0777;	/* fake a non-existent char */
	    nrslen = rslen = 1;
	}
	break;
    case '\\':
	if (ors)
	    Safefree(ors);
	ors = savestr(SvPVX(sv));
	orslen = SvCUR(sv);
	break;
    case ',':
	if (ofs)
	    Safefree(ofs);
	ofs = savestr(SvPVX(sv));
	ofslen = SvCUR(sv);
	break;
    case '#':
	if (ofmt)
	    Safefree(ofmt);
	ofmt = savestr(SvPVX(sv));
	break;
    case '[':
	arybase = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	break;
    case '?':
	statusvalue = U_S(SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv));
	break;
    case '!':
	errno = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);		/* will anyone ever use this? */
	break;
    case '<':
	uid = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	if (delaymagic) {
	    delaymagic |= DM_RUID;
	    break;				/* don't do magic till later */
	}
#ifdef HAS_SETRUID
	(void)setruid((UIDTYPE)uid);
#else
#ifdef HAS_SETREUID
	(void)setreuid((UIDTYPE)uid, (UIDTYPE)-1);
#else
	if (uid == euid)		/* special case $< = $> */
	    (void)setuid(uid);
	else
	    croak("setruid() not implemented");
#endif
#endif
	uid = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	tainting |= (euid != uid || egid != gid);
	break;
    case '>':
	euid = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	if (delaymagic) {
	    delaymagic |= DM_EUID;
	    break;				/* don't do magic till later */
	}
#ifdef HAS_SETEUID
	(void)seteuid((UIDTYPE)euid);
#else
#ifdef HAS_SETREUID
	(void)setreuid((UIDTYPE)-1, (UIDTYPE)euid);
#else
	if (euid == uid)		/* special case $> = $< */
	    setuid(euid);
	else
	    croak("seteuid() not implemented");
#endif
#endif
	euid = (I32)geteuid();
	tainting |= (euid != uid || egid != gid);
	break;
    case '(':
	gid = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	if (delaymagic) {
	    delaymagic |= DM_RGID;
	    break;				/* don't do magic till later */
	}
#ifdef HAS_SETRGID
	(void)setrgid((GIDTYPE)gid);
#else
#ifdef HAS_SETREGID
	(void)setregid((GIDTYPE)gid, (GIDTYPE)-1);
#else
	if (gid == egid)			/* special case $( = $) */
	    (void)setgid(gid);
	else
	    croak("setrgid() not implemented");
#endif
#endif
	gid = (I32)getgid();
	tainting |= (euid != uid || egid != gid);
	break;
    case ')':
	egid = SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv);
	if (delaymagic) {
	    delaymagic |= DM_EGID;
	    break;				/* don't do magic till later */
	}
#ifdef HAS_SETEGID
	(void)setegid((GIDTYPE)egid);
#else
#ifdef HAS_SETREGID
	(void)setregid((GIDTYPE)-1, (GIDTYPE)egid);
#else
	if (egid == gid)			/* special case $) = $( */
	    (void)setgid(egid);
	else
	    croak("setegid() not implemented");
#endif
#endif
	egid = (I32)getegid();
	tainting |= (euid != uid || egid != gid);
	break;
    case ':':
	chopset = SvPVX(sv);
	break;
    case '0':
	if (!origalen) {
	    s = origargv[0];
	    s += strlen(s);
	    /* See if all the arguments are contiguous in memory */
	    for (i = 1; i < origargc; i++) {
		if (origargv[i] == s + 1)
		    s += strlen(++s);	/* this one is ok too */
	    }
	    if (origenviron[0] == s + 1) {	/* can grab env area too? */
		my_setenv("NoNeSuCh", Nullch);
					    /* force copy of environment */
		for (i = 0; origenviron[i]; i++)
		    if (origenviron[i] == s + 1)
			s += strlen(++s);
	    }
	    origalen = s - origargv[0];
	}
	s = SvPVX(sv);
	i = SvCUR(sv);
	if (i >= origalen) {
	    i = origalen;
	    SvCUR_set(sv, i);
	    *SvEND(sv) = '\0';
	    Copy(s, origargv[0], i, char);
	}
	else {
	    Copy(s, origargv[0], i, char);
	    s = origargv[0]+i;
	    *s++ = '\0';
	    while (++i < origalen)
		*s++ = ' ';
	}
	break;
    }
    return 0;
}

I32
whichsig(sig)
char *sig;
{
    register char **sigv;

    for (sigv = sig_name+1; *sigv; sigv++)
	if (strEQ(sig,*sigv))
	    return sigv - sig_name;
#ifdef SIGCLD
    if (strEQ(sig,"CHLD"))
	return SIGCLD;
#endif
#ifdef SIGCHLD
    if (strEQ(sig,"CLD"))
	return SIGCHLD;
#endif
    return 0;
}

static handlertype
sighandler(sig)
I32 sig;
{
    dSP;
    GV *gv;
    SV *sv;
    CV *cv;
    CONTEXT *cx;
    AV *oldstack;
    I32 hasargs = 1;
    I32 items = 1;
    I32 gimme = G_SCALAR;

#ifdef OS2		/* or anybody else who requires SIG_ACK */
    signal(sig, SIG_ACK);
#endif

    gv = gv_fetchpv(
	SvPVx(*hv_fetch(GvHVn(siggv),sig_name[sig],strlen(sig_name[sig]),
	  TRUE), na), TRUE);
    cv = GvCV(gv);
    if (!cv && *sig_name[sig] == 'C' && instr(sig_name[sig],"LD")) {
	if (sig_name[sig][1] == 'H')
	    gv = gv_fetchpv(SvPVx(*hv_fetch(GvHVn(siggv),"CLD",3,TRUE), na),
	      TRUE);
	else
	    gv = gv_fetchpv(SvPVx(*hv_fetch(GvHVn(siggv),"CHLD",4,TRUE), na),
	      TRUE);
	cv = GvCV(gv);	/* gag */
    }
    if (!cv) {
	if (dowarn)
	    warn("SIG%s handler \"%s\" not defined.\n",
		sig_name[sig], GvENAME(gv) );
	return;
    }

    oldstack = stack;
    SWITCHSTACK(stack, signalstack);

    sv = sv_mortalcopy(&sv_undef);
    sv_setpv(sv,sig_name[sig]);
    PUSHs(sv);

    ENTER;
    SAVETMPS;

    push_return(op);
    push_return(0);
    PUSHBLOCK(cx, CXt_SUB, sp);
    PUSHSUB(cx);
    cx->blk_sub.savearray = GvAV(defgv);
    cx->blk_sub.argarray = av_fake(items, sp);
    GvAV(defgv) = cx->blk_sub.argarray;
    CvDEPTH(cv)++;
    if (CvDEPTH(cv) >= 2) {
	if (CvDEPTH(cv) == 100 && dowarn)
	    warn("Deep recursion on subroutine \"%s\"",GvENAME(gv));
    }
    op = CvSTART(cv);
    PUTBACK;
    run();		/* Does the LEAVE for us. */

    SWITCHSTACK(signalstack, oldstack);
    op = pop_return();

    return;
}
