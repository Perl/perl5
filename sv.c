/* $RCSfile: sv.c,v $$Revision: 4.1 $$Date: 92/08/07 18:26:45 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	sv.c,v $
 * Revision 4.1  92/08/07  18:26:45  lwall
 * 
 * Revision 4.0.1.6  92/06/11  21:14:21  lwall
 * patch34: quotes containing subscripts containing variables didn't parse right
 * 
 * Revision 4.0.1.5  92/06/08  15:40:43  lwall
 * patch20: removed implicit int declarations on functions
 * patch20: Perl now distinguishes overlapped copies from non-overlapped
 * patch20: paragraph mode now skips extra newlines automatically
 * patch20: fixed memory leak in doube-quote interpretation
 * patch20: made /\$$foo/ look for literal '$foo'
 * patch20: "$var{$foo'bar}" didn't scan subscript correctly
 * patch20: a splice on non-existent array elements could dump core
 * patch20: running taintperl explicitly now does checks even if $< == $>
 * 
 * Revision 4.0.1.4  91/11/05  18:40:51  lwall
 * patch11: $foo .= <BAR> could overrun malloced memory
 * patch11: \$ didn't always make it through double-quoter to regexp routines
 * patch11: prepared for ctype implementations that don't define isascii()
 * 
 * Revision 4.0.1.3  91/06/10  01:27:54  lwall
 * patch10: $) and $| incorrectly handled in run-time patterns
 * 
 * Revision 4.0.1.2  91/06/07  11:58:13  lwall
 * patch4: new copyright notice
 * patch4: taint check on undefined string could cause core dump
 * 
 * Revision 4.0.1.1  91/04/12  09:15:30  lwall
 * patch1: fixed undefined environ problem
 * patch1: substr($ENV{"PATH"},0,0) = "/foo:" didn't modify environment
 * patch1: $foo .= <BAR> could cause core dump for certain lengths of $foo
 * 
 * Revision 4.0  91/03/20  01:39:55  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include "perly.h"

static void ucase();
static void lcase();

bool
sv_upgrade(sv, mt)
register SV* sv;
U32 mt;
{
    char*	pv;
    U32		cur;
    U32		len;
    I32		iv;
    double	nv;
    MAGIC*	magic;
    HV*		stash;

    if (SvTYPE(sv) == mt)
	return TRUE;

    switch (SvTYPE(sv)) {
    case SVt_NULL:
	pv	= 0;
	cur	= 0;
	len	= 0;
	iv	= 0;
	nv	= 0.0;
	magic	= 0;
	stash	= 0;
	break;
    case SVt_REF:
	sv_free((SV*)SvANY(sv));
	pv	= 0;
	cur	= 0;
	len	= 0;
	iv	= SvANYI32(sv);
	nv	= (double)SvANYI32(sv);
	SvNOK_only(sv);
	magic	= 0;
	stash	= 0;
	if (mt == SVt_PV)
	    mt = SVt_PVIV;
	break;
    case SVt_IV:
	pv	= 0;
	cur	= 0;
	len	= 0;
	iv	= SvIV(sv);
	nv	= (double)SvIV(sv);
	del_XIV(SvANY(sv));
	magic	= 0;
	stash	= 0;
	if (mt == SVt_PV)
	    mt = SVt_PVIV;
	break;
    case SVt_NV:
	pv	= 0;
	cur	= 0;
	len	= 0;
	if (SvIOK(sv))
	    iv	= SvIV(sv);
	else
	    iv	= (I32)SvNV(sv);
	nv	= SvNV(sv);
	magic	= 0;
	stash	= 0;
	del_XNV(SvANY(sv));
	SvANY(sv) = 0;
	if (mt == SVt_PV || mt == SVt_PVIV)
	    mt = SVt_PVNV;
	break;
    case SVt_PV:
	nv = 0.0;
	pv	= SvPV(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= 0;
	nv	= 0.0;
	magic	= 0;
	stash	= 0;
	del_XPV(SvANY(sv));
	break;
    case SVt_PVIV:
	nv = 0.0;
	pv	= SvPV(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= SvIV(sv);
	nv	= 0.0;
	magic	= 0;
	stash	= 0;
	del_XPVIV(SvANY(sv));
	break;
    case SVt_PVNV:
	nv = SvNV(sv);
	pv	= SvPV(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= SvIV(sv);
	nv	= SvNV(sv);
	magic	= 0;
	stash	= 0;
	del_XPVNV(SvANY(sv));
	break;
    case SVt_PVMG:
	pv	= SvPV(sv);
	cur	= SvCUR(sv);
	len	= SvLEN(sv);
	iv	= SvIV(sv);
	nv	= SvNV(sv);
	magic	= SvMAGIC(sv);
	stash	= SvSTASH(sv);
	del_XPVMG(SvANY(sv));
	break;
    default:
	fatal("Can't upgrade that kind of scalar");
    }

    switch (mt) {
    case SVt_NULL:
	fatal("Can't upgrade to undef");
    case SVt_REF:
	SvIOK_on(sv);
	break;
    case SVt_IV:
	SvANY(sv) = new_XIV();
	SvIV(sv)	= iv;
	break;
    case SVt_NV:
	SvANY(sv) = new_XNV();
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	break;
    case SVt_PV:
	SvANY(sv) = new_XPV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	break;
    case SVt_PVIV:
	SvANY(sv) = new_XPVIV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	if (SvNIOK(sv))
	    SvIOK_on(sv);
	SvNOK_off(sv);
	break;
    case SVt_PVNV:
	SvANY(sv) = new_XPVNV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	break;
    case SVt_PVMG:
	SvANY(sv) = new_XPVMG();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	break;
    case SVt_PVLV:
	SvANY(sv) = new_XPVLV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	LvTARGOFF(sv)	= 0;
	LvTARGLEN(sv)	= 0;
	LvTARG(sv)	= 0;
	LvTYPE(sv)	= 0;
	break;
    case SVt_PVAV:
	SvANY(sv) = new_XPVAV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	AvMAGIC(sv)	= 0;
	AvARRAY(sv)	= 0;
	AvALLOC(sv)	= 0;
	AvMAX(sv)	= 0;
	AvFILL(sv)	= 0;
	AvARYLEN(sv)	= 0;
	AvFLAGS(sv)	= 0;
	break;
    case SVt_PVHV:
	SvANY(sv) = new_XPVHV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	HvMAGIC(sv)	= 0;
	HvARRAY(sv)	= 0;
	HvMAX(sv)	= 0;
	HvDOSPLIT(sv)	= 0;
	HvFILL(sv)	= 0;
	HvRITER(sv)	= 0;
	HvEITER(sv)	= 0;
	HvPMROOT(sv)	= 0;
	HvNAME(sv)	= 0;
	HvDBM(sv)	= 0;
	HvCOEFFSIZE(sv)	= 0;
	break;
    case SVt_PVCV:
	SvANY(sv) = new_XPVCV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	CvSTASH(sv)	= 0;
	CvSTART(sv)	= 0;
	CvROOT(sv)	= 0;
	CvUSERSUB(sv)	= 0;
	CvUSERINDEX(sv)	= 0;
	CvFILEGV(sv)	= 0;
	CvDEPTH(sv)	= 0;
	CvPADLIST(sv)	= 0;
	CvDELETED(sv)	= 0;
	break;
    case SVt_PVGV:
	SvANY(sv) = new_XPVGV();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	GvGP(sv)	= 0;
	GvNAME(sv)	= 0;
	GvNAMELEN(sv)	= 0;
	GvSTASH(sv)	= 0;
	break;
    case SVt_PVBM:
	SvANY(sv) = new_XPVBM();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	BmRARE(sv)	= 0;
	BmUSEFUL(sv)	= 0;
	BmPREVIOUS(sv)	= 0;
	break;
    case SVt_PVFM:
	SvANY(sv) = new_XPVFM();
	SvPV(sv)	= pv;
	SvCUR(sv)	= cur;
	SvLEN(sv)	= len;
	SvIV(sv)	= iv;
	SvNV(sv)	= nv;
	SvMAGIC(sv)	= magic;
	SvSTASH(sv)	= stash;
	FmLINES(sv)	= 0;
	break;
    }
    SvTYPE(sv) = mt;
    return TRUE;
}

char *
sv_peek(sv)
register SV *sv;
{
    char *t = tokenbuf;
    *t = '\0';

  retry:
    if (!sv) {
	strcpy(t, "VOID");
	return tokenbuf;
    }
    else if (sv == (SV*)0x55555555 || SvTYPE(sv) == 'U') {
	strcpy(t, "WILD");
	return tokenbuf;
    }
    else if (SvREFCNT(sv) == 0 && !SvREADONLY(sv)) {
	strcpy(t, "UNREF");
	return tokenbuf;
    }
    else {
	switch (SvTYPE(sv)) {
	default:
	    strcpy(t,"FREED");
	    return tokenbuf;
	    break;

	case SVt_NULL:
	    strcpy(t,"UNDEF");
	    return tokenbuf;
	case SVt_REF:
	    *t++ = '\\';
	    if (t - tokenbuf > 10) {
		strcpy(tokenbuf + 3,"...");
		return tokenbuf;
	    }
	    sv = (SV*)SvANY(sv);
	    goto retry;
	case SVt_IV:
	    strcpy(t,"IV");
	    break;
	case SVt_NV:
	    strcpy(t,"NV");
	    break;
	case SVt_PV:
	    strcpy(t,"PV");
	    break;
	case SVt_PVIV:
	    strcpy(t,"PVIV");
	    break;
	case SVt_PVNV:
	    strcpy(t,"PVNV");
	    break;
	case SVt_PVMG:
	    strcpy(t,"PVMG");
	    break;
	case SVt_PVLV:
	    strcpy(t,"PVLV");
	    break;
	case SVt_PVAV:
	    strcpy(t,"AV");
	    break;
	case SVt_PVHV:
	    strcpy(t,"HV");
	    break;
	case SVt_PVCV:
	    strcpy(t,"CV");
	    break;
	case SVt_PVGV:
	    strcpy(t,"GV");
	    break;
	case SVt_PVBM:
	    strcpy(t,"BM");
	    break;
	case SVt_PVFM:
	    strcpy(t,"FM");
	    break;
	}
    }
    t += strlen(t);

    if (SvPOK(sv)) {
	if (!SvPV(sv))
	    return "(null)";
	if (SvOOK(sv))
	    sprintf(t,"(%d+\"%0.127s\")",SvIV(sv),SvPV(sv));
	else
	    sprintf(t,"(\"%0.127s\")",SvPV(sv));
    }
    else if (SvNOK(sv))
	sprintf(t,"(%g)",SvNV(sv));
    else if (SvIOK(sv))
	sprintf(t,"(%ld)",(long)SvIV(sv));
    else
	strcpy(t,"()");
    return tokenbuf;
}

int
sv_backoff(sv)
register SV *sv;
{
    assert(SvOOK(sv));
    if (SvIV(sv)) {
	char *s = SvPV(sv);
	SvLEN(sv) += SvIV(sv);
	SvPV(sv) -= SvIV(sv);
	SvIV_set(sv, 0);
	Move(s, SvPV(sv), SvCUR(sv)+1, char);
    }
    SvFLAGS(sv) &= ~SVf_OOK;
}

char *
sv_grow(sv,newlen)
register SV *sv;
#ifndef DOSISH
register I32 newlen;
#else
unsigned long newlen;
#endif
{
    register char *s;

#ifdef MSDOS
    if (newlen >= 0x10000) {
	fprintf(stderr, "Allocation too large: %lx\n", newlen);
	my_exit(1);
    }
#endif /* MSDOS */
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvTYPE(sv) < SVt_PV) {
	sv_upgrade(sv, SVt_PV);
	s = SvPV(sv);
    }
    else if (SvOOK(sv)) {	/* pv is offset? */
	sv_backoff(sv);
	s = SvPV(sv);
	if (newlen > SvLEN(sv))
	    newlen += 10 * (newlen - SvCUR(sv)); /* avoid copy each time */
    }
    else
	s = SvPV(sv);
    if (newlen > SvLEN(sv)) {		/* need more room? */
        if (SvLEN(sv))
	    Renew(s,newlen,char);
        else
	    New(703,s,newlen,char);
	SvPV_set(sv, s);
        SvLEN_set(sv, newlen);
    }
    return s;
}

void
sv_setiv(sv,i)
register SV *sv;
I32 i;
{
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvTYPE(sv) < SVt_IV)
	sv_upgrade(sv, SVt_IV);
    else if (SvTYPE(sv) == SVt_PV)
	sv_upgrade(sv, SVt_PVIV);
    SvIV(sv) = i;
    SvIOK_only(sv);			/* validate number */
    SvTDOWN(sv);
}

void
sv_setnv(sv,num)
register SV *sv;
double num;
{
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvTYPE(sv) < SVt_NV)
	sv_upgrade(sv, SVt_NV);
    else if (SvTYPE(sv) < SVt_PVNV)
	sv_upgrade(sv, SVt_PVNV);
    else if (SvPOK(sv)) {
	SvOOK_off(sv);
    }
    SvNV(sv) = num;
    SvNOK_only(sv);			/* validate number */
    SvTDOWN(sv);
}

I32
sv_2iv(sv)
register SV *sv;
{
    if (!sv)
	return 0;
    if (SvREADONLY(sv)) {
	if (SvNOK(sv))
	    return (I32)SvNV(sv);
	if (SvPOK(sv) && SvLEN(sv))
	    return atof(SvPV(sv));
	if (dowarn)
	    warn("Use of uninitialized variable");
	return 0;
    }
    if (SvTYPE(sv) < SVt_IV) {
	if (SvTYPE(sv) == SVt_REF)
	    return (I32)SvANYI32(sv);
	sv_upgrade(sv, SVt_IV);
	DEBUG_c((stderr,"0x%lx num(%g)\n",sv,SvIV(sv)));
	return SvIV(sv);
    }
    else if (SvTYPE(sv) == SVt_PV)
	sv_upgrade(sv, SVt_PVIV);
    if (SvNOK(sv))
	SvIV(sv) = (I32)SvNV(sv);
    else if (SvPOK(sv) && SvLEN(sv)) {
	if (dowarn && !looks_like_number(sv)) {
	    if (op)
		warn("Argument wasn't numeric for \"%s\"",op_name[op->op_type]);
	    else
		warn("Argument wasn't numeric");
	}
	SvIV(sv) = atol(SvPV(sv));
    }
    else  {
	if (dowarn)
	    warn("Use of uninitialized variable");
	SvUPGRADE(sv, SVt_IV);
	SvIV(sv) = 0;
    }
    SvIOK_on(sv);
    DEBUG_c((stderr,"0x%lx 2iv(%d)\n",sv,SvIV(sv)));
    return SvIV(sv);
}

double
sv_2nv(sv)
register SV *sv;
{
    if (!sv)
	return 0.0;
    if (SvREADONLY(sv)) {
	if (SvPOK(sv) && SvLEN(sv))
	    return atof(SvPV(sv));
	if (dowarn)
	    warn("Use of uninitialized variable");
	return 0.0;
    }
    if (SvTYPE(sv) < SVt_NV) {
	if (SvTYPE(sv) == SVt_REF)
	    return (double)SvANYI32(sv);
	sv_upgrade(sv, SVt_NV);
	DEBUG_c((stderr,"0x%lx num(%g)\n",sv,SvNV(sv)));
	return SvNV(sv);
    }
    else if (SvTYPE(sv) < SVt_PVNV)
	sv_upgrade(sv, SVt_PVNV);
    if (SvIOK(sv) &&
	    (!SvPOK(sv) || !strchr(SvPV(sv),'.') || !looks_like_number(sv)))
    {
	SvNV(sv) = (double)SvIV(sv);
    }
    else if (SvPOK(sv) && SvLEN(sv)) {
	if (dowarn && !SvIOK(sv) && !looks_like_number(sv)) {
	    if (op)
		warn("Argument wasn't numeric for \"%s\"",op_name[op->op_type]);
	    else
		warn("Argument wasn't numeric");
	}
	SvNV(sv) = atof(SvPV(sv));
    }
    else  {
	if (dowarn)
	    warn("Use of uninitialized variable");
	SvNV(sv) = 0.0;
    }
    SvNOK_on(sv);
    DEBUG_c((stderr,"0x%lx 2nv(%g)\n",sv,SvNV(sv)));
    return SvNV(sv);
}

char *
sv_2pv(sv)
register SV *sv;
{
    register char *s;
    int olderrno;

    if (!sv)
	return "";
    if (SvTYPE(sv) == SVt_REF) {
	sv = (SV*)SvANY(sv);
	if (!sv)
	    return "<Empty reference>";
	switch (SvTYPE(sv)) {
	case SVt_NULL:	s = "an undefined value";		break;
	case SVt_REF:	s = "a reference";			break;
	case SVt_IV:	s = "an integer value";			break;
	case SVt_NV:	s = "a numeric value";			break;
	case SVt_PV:	s = "a string value";			break;
	case SVt_PVIV:	s = "a string+integer value";		break;
	case SVt_PVNV:	s = "a scalar value";			break;
	case SVt_PVMG:	s = "a magic value";			break;
	case SVt_PVLV:	s = "an lvalue";			break;
	case SVt_PVAV:	s = "an array value";			break;
	case SVt_PVHV:	s = "an associative array value";	break;
	case SVt_PVCV:	s = "a code value";			break;
	case SVt_PVGV:	s = "a glob value";			break;
	case SVt_PVBM:	s = "a search string";			break;
	case SVt_PVFM:	s = "a formatline";			break;
	default:	s = "something weird";			break;
	}
	sprintf(tokenbuf,"<Reference to %s at 0x%lx>", s, (unsigned long)sv);
	return tokenbuf;
    }
    if (SvREADONLY(sv)) {
	if (SvIOK(sv)) {
	    (void)sprintf(tokenbuf,"%ld",SvIV(sv));
	    return tokenbuf;
	}
	if (SvNOK(sv)) {
	    (void)sprintf(tokenbuf,"%.20g",SvNV(sv));
	    return tokenbuf;
	}
	if (dowarn)
	    warn("Use of uninitialized variable");
	return "";
    }
    if (!SvUPGRADE(sv, SVt_PV))
	return 0;
    if (SvNOK(sv)) {
	if (SvTYPE(sv) < SVt_PVNV)
	    sv_upgrade(sv, SVt_PVNV);
	SvGROW(sv, 28);
	s = SvPV(sv);
	olderrno = errno;	/* some Xenix systems wipe out errno here */
#if defined(scs) && defined(ns32000)
	gcvt(SvNV(sv),20,s);
#else
#ifdef apollo
	if (SvNV(sv) == 0.0)
	    (void)strcpy(s,"0");
	else
#endif /*apollo*/
	(void)sprintf(s,"%.20g",SvNV(sv));
#endif /*scs*/
	errno = olderrno;
	while (*s) s++;
#ifdef hcx
	if (s[-1] == '.')
	    s--;
#endif
    }
    else if (SvIOK(sv)) {
	if (SvTYPE(sv) < SVt_PVIV)
	    sv_upgrade(sv, SVt_PVIV);
	SvGROW(sv, 11);
	s = SvPV(sv);
	olderrno = errno;	/* some Xenix systems wipe out errno here */
	(void)sprintf(s,"%ld",SvIV(sv));
	errno = olderrno;
	while (*s) s++;
    }
    else {
	if (dowarn)
	    warn("Use of uninitialized variable");
	sv_grow(sv, 1);
	s = SvPV(sv);
    }
    *s = '\0';
    SvCUR_set(sv, s - SvPV(sv));
    SvPOK_on(sv);
    DEBUG_c((stderr,"0x%lx 2pv(%s)\n",sv,SvPV(sv)));
    return SvPV(sv);
}

/* Note: sv_setsv() should not be called with a source string that needs
 * be reused, since it may destroy the source string if it is marked
 * as temporary.
 */

void
sv_setsv(dstr,sstr)
SV *dstr;
register SV *sstr;
{
    if (sstr == dstr)
	return;
    if (SvREADONLY(dstr))
	fatal(no_modify);
    if (!sstr)
	sstr = &sv_undef;

    if (SvTYPE(dstr) < SvTYPE(sstr))
	sv_upgrade(dstr, SvTYPE(sstr));
    else if (SvTYPE(dstr) == SVt_PV && SvTYPE(sstr) <= SVt_NV) {
	if (SvTYPE(sstr) <= SVt_IV)
	    sv_upgrade(dstr, SVt_PVIV);		/* handle discontinuities */
	else
	    sv_upgrade(dstr, SVt_PVNV);
    }
    else if (SvTYPE(dstr) == SVt_PVIV && SvTYPE(sstr) == SVt_NV)
	sv_upgrade(dstr, SVt_PVNV);

    switch (SvTYPE(sstr)) {
    case SVt_NULL:
	if (SvTYPE(dstr) == SVt_REF) {
	    sv_free((SV*)SvANY(dstr));
	    SvANY(dstr) = 0;
	    SvTYPE(dstr) = SVt_NULL;
	}
	else
	    SvOK_off(dstr);
	return;
    case SVt_REF:
	SvTUP(sstr);
	if (SvTYPE(dstr) == SVt_REF) {
	    SvANY(dstr) = (void*)sv_ref((SV*)SvANY(sstr));
	}
	else {
	    if (SvMAGICAL(dstr))
		fatal("Can't assign a reference to a magical variable");
	    sv_clear(dstr);
	    SvTYPE(dstr) = SVt_REF;
	    SvANY(dstr) = (void*)sv_ref((SV*)SvANY(sstr));
	    SvOK_off(dstr);
	}
	SvTDOWN(sstr);
	return;
    case SVt_PVGV:
	SvTUP(sstr);
	if (SvTYPE(dstr) == SVt_PVGV) {
	    SvOK_off(dstr);
	    if (!GvAV(sstr))
		gv_AVadd(sstr);
	    if (!GvHV(sstr))
		gv_HVadd(sstr);
	    if (!GvIO(sstr))
		GvIO(sstr) = newIO();
	    if (GvGP(dstr))
		gp_free(dstr);
	    GvGP(dstr) = gp_ref(GvGP(sstr));
	    SvTDOWN(sstr);
	    return;
	}
	/* FALL THROUGH */

    default:
	if (SvMAGICAL(sstr))
	    mg_get(sstr);
	/* XXX */
	break;
    }

    SvPRIVATE(dstr)	= SvPRIVATE(sstr);
    SvSTORAGE(dstr)	= SvSTORAGE(sstr);

    if (SvPOK(sstr)) {

	SvTUP(sstr);

	/*
	 * Check to see if we can just swipe the string.  If so, it's a
	 * possible small lose on short strings, but a big win on long ones.
	 * It might even be a win on short strings if SvPV(dstr)
	 * has to be allocated and SvPV(sstr) has to be freed.
	 */

	if (SvTEMP(sstr)) {		/* slated for free anyway? */
	    if (SvPOK(dstr)) {
		SvOOK_off(dstr);
		Safefree(SvPV(dstr));
	    }
	    SvPV_set(dstr, SvPV(sstr));
	    SvLEN_set(dstr, SvLEN(sstr));
	    SvCUR_set(dstr, SvCUR(sstr));
	    SvTYPE(dstr) = SvTYPE(sstr);
	    SvPOK_only(dstr);
	    SvTEMP_off(dstr);
	    SvPV_set(sstr, Nullch);
	    SvLEN_set(sstr, 0);
	    SvPOK_off(sstr);			/* wipe out any weird flags */
	    SvTYPE(sstr) = 0;			/* so sstr frees uneventfully */
	}
	else {					/* have to copy actual string */
	    if (SvPV(dstr)) { /* XXX ck type */
		SvOOK_off(dstr);
	    }
	    sv_setpvn(dstr,SvPV(sstr),SvCUR(sstr));
	}
	/*SUPPRESS 560*/
	if (SvNOK(sstr)) {
	    SvNOK_on(dstr);
	    SvNV(dstr) = SvNV(sstr);
	}
	if (SvIOK(sstr)) {
	    SvIOK_on(dstr);
	    SvIV(dstr) = SvIV(sstr);
	}
    }
    else if (SvNOK(sstr)) {
	SvTUP(sstr);
	SvNV(dstr) = SvNV(sstr);
	SvNOK_only(dstr);
	if (SvIOK(sstr)) {
	    SvIOK_on(dstr);
	    SvIV(dstr) = SvIV(sstr);
	}
    }
    else if (SvIOK(sstr)) {
	SvTUP(sstr);
	SvIOK_only(dstr);
	SvIV(dstr) = SvIV(sstr);
    }
    else {
	SvTUP(sstr);
	SvOK_off(dstr);
    }
    SvTDOWN(dstr);
}

void
sv_setpvn(sv,ptr,len)
register SV *sv;
register char *ptr;
register STRLEN len;
{
    if (!SvUPGRADE(sv, SVt_PV))
	return;
    SvGROW(sv, len + 1);
    if (ptr)
	Move(ptr,SvPV(sv),len,char);
    SvCUR_set(sv, len);
    *SvEND(sv) = '\0';
    SvPOK_only(sv);		/* validate pointer */
    SvTDOWN(sv);
}

void
sv_setpv(sv,ptr)
register SV *sv;
register char *ptr;
{
    register STRLEN len;

    if (SvREADONLY(sv))
	fatal(no_modify);
    if (!ptr)
	ptr = "";
    len = strlen(ptr);
    if (!SvUPGRADE(sv, SVt_PV))
	return;
    SvGROW(sv, len + 1);
    Move(ptr,SvPV(sv),len+1,char);
    SvCUR_set(sv, len);
    SvPOK_only(sv);		/* validate pointer */
    SvTDOWN(sv);
}

void
sv_chop(sv,ptr)	/* like set but assuming ptr is in sv */
register SV *sv;
register char *ptr;
{
    register STRLEN delta;

    if (!ptr || !SvPOK(sv))
	return;
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvTYPE(sv) < SVt_PVIV)
	sv_upgrade(sv,SVt_PVIV);

    if (!SvOOK(sv)) {
	SvIV(sv) = 0;
	SvFLAGS(sv) |= SVf_OOK;
    }
    SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK);
    delta = ptr - SvPV(sv);
    SvLEN(sv) -= delta;
    SvCUR(sv) -= delta;
    SvPV(sv) += delta;
    SvIV(sv) += delta;
}

void
sv_catpvn(sv,ptr,len)
register SV *sv;
register char *ptr;
register STRLEN len;
{
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (!(SvPOK(sv)))
	(void)sv_2pv(sv);
    SvGROW(sv, SvCUR(sv) + len + 1);
    Move(ptr,SvPV(sv)+SvCUR(sv),len,char);
    SvCUR(sv) += len;
    *SvEND(sv) = '\0';
    SvPOK_only(sv);		/* validate pointer */
    SvTDOWN(sv);
}

void
sv_catsv(dstr,sstr)
SV *dstr;
register SV *sstr;
{
    char *s;
    if (!sstr)
	return;
    if (s = SvPVn(sstr)) {
	if (SvPOK(sstr))
	    sv_catpvn(dstr,s,SvCUR(sstr));
	else
	    sv_catpv(dstr,s);
    }
}

void
sv_catpv(sv,ptr)
register SV *sv;
register char *ptr;
{
    register STRLEN len;

    if (SvREADONLY(sv))
	fatal(no_modify);
    if (!ptr)
	return;
    if (!(SvPOK(sv)))
	(void)sv_2pv(sv);
    len = strlen(ptr);
    SvGROW(sv, SvCUR(sv) + len + 1);
    Move(ptr,SvPV(sv)+SvCUR(sv),len+1,char);
    SvCUR(sv) += len;
    SvPOK_only(sv);		/* validate pointer */
    SvTDOWN(sv);
}

SV *
#ifdef LEAKTEST
newSV(x,len)
I32 x;
#else
newSV(len)
#endif
STRLEN len;
{
    register SV *sv;
    
    sv = (SV*)new_SV();
    Zero(sv, 1, SV);
    SvREFCNT(sv)++;
    if (len) {
	sv_upgrade(sv, SVt_PV);
	SvGROW(sv, len + 1);
    }
    return sv;
}

void
sv_magic(sv, obj, how, name, namlen)
register SV *sv;
SV *obj;
char how;
char *name;
STRLEN namlen;
{
    MAGIC* mg;
    
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (!SvUPGRADE(sv, SVt_PVMG))
	return;
    Newz(702,mg, 1, MAGIC);
    mg->mg_moremagic = SvMAGIC(sv);
    SvMAGICAL_on(sv);
    SvMAGIC(sv) = mg;
    mg->mg_obj = obj;
    mg->mg_type = how;
    if (name) {
	mg->mg_ptr = nsavestr(name, namlen);
	mg->mg_len = namlen;
    }
    switch (how) {
    case 0:
	mg->mg_virtual = &vtbl_sv;
	break;
    case 'B':
	mg->mg_virtual = &vtbl_bm;
	break;
    case 'D':
	mg->mg_virtual = &vtbl_dbm;
	break;
    case 'd':
	mg->mg_virtual = &vtbl_dbmelem;
	break;
    case 'E':
	mg->mg_virtual = &vtbl_env;
	break;
    case 'e':
	mg->mg_virtual = &vtbl_envelem;
	break;
    case 'g':
	mg->mg_virtual = &vtbl_mglob;
	break;
    case 'L':
	mg->mg_virtual = 0;
	break;
    case 'l':
	mg->mg_virtual = &vtbl_dbline;
	break;
    case 'S':
	mg->mg_virtual = &vtbl_sig;
	break;
    case 's':
	mg->mg_virtual = &vtbl_sigelem;
	break;
    case 'U':
	mg->mg_virtual = &vtbl_uvar;
	break;
    case 'v':
	mg->mg_virtual = &vtbl_vec;
	break;
    case 'x':
	mg->mg_virtual = &vtbl_substr;
	break;
    case '*':
	mg->mg_virtual = &vtbl_glob;
	break;
    case '#':
	mg->mg_virtual = &vtbl_arylen;
	break;
    default:
	fatal("Don't know how to handle magic of type '%c'", how);
    }
}

void
sv_insert(bigstr,offset,len,little,littlelen)
SV *bigstr;
STRLEN offset;
STRLEN len;
char *little;
STRLEN littlelen;
{
    register char *big;
    register char *mid;
    register char *midend;
    register char *bigend;
    register I32 i;

    if (SvREADONLY(bigstr))
	fatal(no_modify);
    SvPOK_only(bigstr);

    i = littlelen - len;
    if (i > 0) {			/* string might grow */
	if (!SvUPGRADE(bigstr, SVt_PV))
	    return;
	SvGROW(bigstr, SvCUR(bigstr) + i + 1);
	big = SvPV(bigstr);
	mid = big + offset + len;
	midend = bigend = big + SvCUR(bigstr);
	bigend += i;
	*bigend = '\0';
	while (midend > mid)		/* shove everything down */
	    *--bigend = *--midend;
	Move(little,big+offset,littlelen,char);
	SvCUR(bigstr) += i;
	SvSETMAGIC(bigstr);
	return;
    }
    else if (i == 0) {
	Move(little,SvPV(bigstr)+offset,len,char);
	SvSETMAGIC(bigstr);
	return;
    }

    big = SvPV(bigstr);
    mid = big + offset;
    midend = mid + len;
    bigend = big + SvCUR(bigstr);

    if (midend > bigend)
	fatal("panic: sv_insert");

    if (mid - big > bigend - midend) {	/* faster to shorten from end */
	if (littlelen) {
	    Move(little, mid, littlelen,char);
	    mid += littlelen;
	}
	i = bigend - midend;
	if (i > 0) {
	    Move(midend, mid, i,char);
	    mid += i;
	}
	*mid = '\0';
	SvCUR_set(bigstr, mid - big);
    }
    /*SUPPRESS 560*/
    else if (i = mid - big) {	/* faster from front */
	midend -= littlelen;
	mid = midend;
	sv_chop(bigstr,midend-i);
	big += i;
	while (i--)
	    *--midend = *--big;
	if (littlelen)
	    Move(little, mid, littlelen,char);
    }
    else if (littlelen) {
	midend -= littlelen;
	sv_chop(bigstr,midend);
	Move(little,midend,littlelen,char);
    }
    else {
	sv_chop(bigstr,midend);
    }
    SvSETMAGIC(bigstr);
}

/* make sv point to what nstr did */

void
sv_replace(sv,nsv)
register SV *sv;
register SV *nsv;
{
    U32 refcnt = SvREFCNT(sv);
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvREFCNT(nsv) != 1)
	warn("Reference miscount in sv_replace()");
    if (SvMAGICAL(sv)) {
	SvUPGRADE(nsv, SVt_PVMG);
	SvMAGIC(nsv) = SvMAGIC(sv);
	SvMAGICAL_on(nsv);
	SvMAGICAL_off(sv);
	SvMAGIC(sv) = 0;
    }
    SvREFCNT(sv) = 0;
    sv_clear(sv);
    StructCopy(nsv,sv,SV);
    SvREFCNT(sv) = refcnt;
    Safefree(nsv);
}

void
sv_clear(sv)
register SV *sv;
{
    assert(sv);
    assert(SvREFCNT(sv) == 0);

    switch (SvTYPE(sv)) {
    case SVt_PVFM:
	goto freemagic;
    case SVt_PVBM:
	goto freemagic;
    case SVt_PVGV:
	gp_free(sv);
	goto freemagic;
    case SVt_PVCV:
	op_free(CvSTART(sv));
	goto freemagic;
    case SVt_PVHV:
	hv_clear(sv, FALSE);
	goto freemagic;
    case SVt_PVAV:
	av_clear(sv);
	goto freemagic;
    case SVt_PVLV:
	goto freemagic;
    case SVt_PVMG:
      freemagic:
	if (SvMAGICAL(sv))
	    mg_freeall(sv);
    case SVt_PVNV:
    case SVt_PVIV:
	SvOOK_off(sv);
	/* FALL THROUGH */
    case SVt_PV:
	if (SvPV(sv))
	    Safefree(SvPV(sv));
	break;
    case SVt_NV:
	break;
    case SVt_IV:
	break;
    case SVt_REF:
	sv_free((SV*)SvANY(sv));
	break;
    case SVt_NULL:
	break;
    }

    switch (SvTYPE(sv)) {
    case SVt_NULL:
	break;
    case SVt_REF:
	break;
    case SVt_IV:
	del_XIV(SvANY(sv));
	break;
    case SVt_NV:
	del_XNV(SvANY(sv));
	break;
    case SVt_PV:
	del_XPV(SvANY(sv));
	break;
    case SVt_PVIV:
	del_XPVIV(SvANY(sv));
	break;
    case SVt_PVNV:
	del_XPVNV(SvANY(sv));
	break;
    case SVt_PVMG:
	del_XPVMG(SvANY(sv));
	break;
    case SVt_PVLV:
	del_XPVLV(SvANY(sv));
	break;
    case SVt_PVAV:
	del_XPVAV(SvANY(sv));
	break;
    case SVt_PVHV:
	del_XPVHV(SvANY(sv));
	break;
    case SVt_PVCV:
	del_XPVCV(SvANY(sv));
	break;
    case SVt_PVGV:
	del_XPVGV(SvANY(sv));
	break;
    case SVt_PVBM:
	del_XPVBM(SvANY(sv));
	break;
    case SVt_PVFM:
	del_XPVFM(SvANY(sv));
	break;
    }
    DEB(SvTYPE(sv) = 0xff;)
}

SV *
sv_ref(sv)
SV* sv;
{
    SvREFCNT(sv)++;
    return sv;
}

void
sv_free(sv)
SV *sv;
{
    if (!sv)
	return;
    if (SvREADONLY(sv)) {
	if (sv == &sv_undef || sv == &sv_yes || sv == &sv_no)
	    return;
    }
    if (SvREFCNT(sv) == 0) {
	warn("Attempt to free unreferenced scalar");
	return;
    }
    if (--SvREFCNT(sv) > 0)
	return;
    if (SvSTORAGE(sv) == 'O') {
	dSP;
	BINOP myop;		/* fake syntax tree node */
	GV* destructor;

	SvSTORAGE(sv) = 0;		/* Curse the object. */

	ENTER;
	SAVESPTR(curcop);
	SAVESPTR(op);
	curcop = &compiling;
	curstash = SvSTASH(sv);
	destructor = gv_fetchpv("DESTROY", FALSE);

	if (GvCV(destructor)) {
	    SV* ref = sv_mortalcopy(&sv_undef);
	    SvREFCNT(ref) = 1;
	    sv_upgrade(ref, SVt_REF);
	    SvANY(ref) = (void*)sv_ref(sv);

	    op = (OP*)&myop;
	    Zero(op, 1, OP);
	    myop.op_last = (OP*)&myop;
	    myop.op_flags = OPf_STACKED;
	    myop.op_next = Nullop;

	    EXTEND(SP, 2);
	    PUSHs((SV*)destructor);
	    pp_pushmark();
	    PUSHs(ref);
	    PUTBACK;
	    op = pp_entersubr();
	    run();
	    stack_sp--;
	    LEAVE;	/* Will eventually free sv as ordinary item. */
	    return;	
	}
	LEAVE;
    }
    sv_clear(sv);
    DEB(SvTYPE(sv) = 0xff;)
    del_SV(sv);
}

STRLEN
sv_len(sv)
register SV *sv;
{
    I32 paren;
    I32 i;
    char *s;

    if (!sv)
	return 0;

    if (SvMAGICAL(sv))
	return mg_len(sv);

    if (!(SvPOK(sv))) {
	(void)sv_2pv(sv);
	if (!SvOK(sv))
	    return 0;
    }
    if (SvPV(sv))
	return SvCUR(sv);
    else
	return 0;
}

I32
sv_eq(str1,str2)
register SV *str1;
register SV *str2;
{
    char *pv1;
    U32 cur1;
    char *pv2;
    U32 cur2;

    if (!str1) {
	pv1 = "";
	cur1 = 0;
    }
    else {
	if (SvMAGICAL(str1))
	    mg_get(str1);
	if (!SvPOK(str1)) {
	    (void)sv_2pv(str1);
	    if (!SvPOK(str1))
		str1 = &sv_no;
	}
	pv1 = SvPV(str1);
	cur1 = SvCUR(str1);
    }

    if (!str2)
	return !cur1;
    else {
	if (SvMAGICAL(str2))
	    mg_get(str2);
	if (!SvPOK(str2)) {
	    (void)sv_2pv(str2);
	    if (!SvPOK(str2))
		return !cur1;
	}
	pv2 = SvPV(str2);
	cur2 = SvCUR(str2);
    }

    if (cur1 != cur2)
	return 0;

    return !bcmp(pv1, pv2, cur1);
}

I32
sv_cmp(str1,str2)
register SV *str1;
register SV *str2;
{
    I32 retval;
    char *pv1;
    U32 cur1;
    char *pv2;
    U32 cur2;

    if (!str1) {
	pv1 = "";
	cur1 = 0;
    }
    else {
	if (SvMAGICAL(str1))
	    mg_get(str1);
	if (!SvPOK(str1)) {
	    (void)sv_2pv(str1);
	    if (!SvPOK(str1))
		str1 = &sv_no;
	}
	pv1 = SvPV(str1);
	cur1 = SvCUR(str1);
    }

    if (!str2) {
	pv2 = "";
	cur2 = 0;
    }
    else {
	if (SvMAGICAL(str2))
	    mg_get(str2);
	if (!SvPOK(str2)) {
	    (void)sv_2pv(str2);
	    if (!SvPOK(str2))
		str2 = &sv_no;
	}
	pv2 = SvPV(str2);
	cur2 = SvCUR(str2);
    }

    if (!cur1)
	return cur2 ? -1 : 0;
    if (!cur2)
	return 1;

    if (cur1 < cur2) {
	/*SUPPRESS 560*/
	if (retval = memcmp(pv1, pv2, cur1))
	    return retval < 0 ? -1 : 1;
	else
	    return -1;
    }
    /*SUPPRESS 560*/
    else if (retval = memcmp(pv1, pv2, cur2))
	return retval < 0 ? -1 : 1;
    else if (cur1 == cur2)
	return 0;
    else
	return 1;
}

char *
sv_gets(sv,fp,append)
register SV *sv;
register FILE *fp;
I32 append;
{
    register char *bp;		/* we're going to steal some values */
    register I32 cnt;		/*  from the stdio struct and put EVERYTHING */
    register STDCHAR *ptr;	/*   in the innermost loop into registers */
    register I32 newline = rschar;/* (assuming >= 6 registers) */
    I32 i;
    STRLEN bpx;
    I32 shortbuffered;

    if (SvREADONLY(sv))
	fatal(no_modify);
    if (!SvUPGRADE(sv, SVt_PV))
	return;
    if (rspara) {		/* have to do this both before and after */
	do {			/* to make sure file boundaries work right */
	    i = getc(fp);
	    if (i != '\n') {
		ungetc(i,fp);
		break;
	    }
	} while (i != EOF);
    }
#ifdef STDSTDIO		/* Here is some breathtakingly efficient cheating */
    cnt = fp->_cnt;			/* get count into register */
    SvPOK_only(sv);			/* validate pointer */
    if (SvLEN(sv) - append <= cnt + 1) { /* make sure we have the room */
	if (cnt > 80 && SvLEN(sv) > append) {
	    shortbuffered = cnt - SvLEN(sv) + append + 1;
	    cnt -= shortbuffered;
	}
	else {
	    shortbuffered = 0;
	    SvGROW(sv, append+cnt+2);/* (remembering cnt can be -1) */
	}
    }
    else
	shortbuffered = 0;
    bp = SvPV(sv) + append;		/* move these two too to registers */
    ptr = fp->_ptr;
    for (;;) {
      screamer:
	if (cnt > 0) {
	    while (--cnt >= 0) {		 /* this */	/* eat */
		if ((*bp++ = *ptr++) == newline) /* really */	/* dust */
		    goto thats_all_folks;	 /* screams */	/* sed :-) */ 
	    }
	}
	
	if (shortbuffered) {			/* oh well, must extend */
	    cnt = shortbuffered;
	    shortbuffered = 0;
	    bpx = bp - SvPV(sv);	/* prepare for possible relocation */
	    SvCUR_set(sv, bpx);
	    SvGROW(sv, SvLEN(sv) + append + cnt + 2);
	    bp = SvPV(sv) + bpx;	/* reconstitute our pointer */
	    continue;
	}

	fp->_cnt = cnt;			/* deregisterize cnt and ptr */
	fp->_ptr = ptr;
	i = _filbuf(fp);		/* get more characters */
	cnt = fp->_cnt;
	ptr = fp->_ptr;			/* reregisterize cnt and ptr */

	bpx = bp - SvPV(sv);	/* prepare for possible relocation */
	SvCUR_set(sv, bpx);
	SvGROW(sv, bpx + cnt + 2);
	bp = SvPV(sv) + bpx;	/* reconstitute our pointer */

	if (i == newline) {		/* all done for now? */
	    *bp++ = i;
	    goto thats_all_folks;
	}
	else if (i == EOF)		/* all done for ever? */
	    goto thats_really_all_folks;
	*bp++ = i;			/* now go back to screaming loop */
    }

thats_all_folks:
    if (rslen > 1 && (bp - SvPV(sv) < rslen || bcmp(bp - rslen, rs, rslen)))
	goto screamer;	/* go back to the fray */
thats_really_all_folks:
    if (shortbuffered)
	cnt += shortbuffered;
    fp->_cnt = cnt;			/* put these back or we're in trouble */
    fp->_ptr = ptr;
    *bp = '\0';
    SvCUR_set(sv, bp - SvPV(sv));	/* set length */

#else /* !STDSTDIO */	/* The big, slow, and stupid way */

    {
	char buf[8192];
	register char * bpe = buf + sizeof(buf) - 3;

screamer:
	bp = buf;
	while ((i = getc(fp)) != EOF && (*bp++ = i) != newline && bp < bpe) ;

	if (append)
	    sv_catpvn(sv, buf, bp - buf);
	else
	    sv_setpvn(sv, buf, bp - buf);
	if (i != EOF			/* joy */
	    &&
	    (i != newline
	     ||
	     (rslen > 1
	      &&
	      (SvCUR(sv) < rslen
	       ||
	       bcmp(SvPV(sv) + SvCUR(sv) - rslen, rs, rslen)
	      )
	     )
	    )
	   )
	{
	    append = -1;
	    goto screamer;
	}
    }

#endif /* STDSTDIO */

    if (rspara) {
        while (i != EOF) {
	    i = getc(fp);
	    if (i != '\n') {
		ungetc(i,fp);
		break;
	    }
	}
    }
    return SvCUR(sv) - append ? SvPV(sv) : Nullch;
}

void
sv_inc(sv)
register SV *sv;
{
    register char *d;

    if (!sv)
	return;
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvMAGICAL(sv))
	mg_get(sv);
    if (SvIOK(sv)) {
	++SvIV(sv);
	SvIOK_only(sv);
	return;
    }
    if (SvNOK(sv)) {
	SvNV(sv) += 1.0;
	SvNOK_only(sv);
	return;
    }
    if (!SvPOK(sv) || !*SvPV(sv)) {
	if (!SvUPGRADE(sv, SVt_NV))
	    return;
	SvNV(sv) = 1.0;
	SvNOK_only(sv);
	return;
    }
    d = SvPV(sv);
    while (isALPHA(*d)) d++;
    while (isDIGIT(*d)) d++;
    if (*d) {
        sv_setnv(sv,atof(SvPV(sv)) + 1.0);  /* punt */
	return;
    }
    d--;
    while (d >= SvPV(sv)) {
	if (isDIGIT(*d)) {
	    if (++*d <= '9')
		return;
	    *(d--) = '0';
	}
	else {
	    ++*d;
	    if (isALPHA(*d))
		return;
	    *(d--) -= 'z' - 'a' + 1;
	}
    }
    /* oh,oh, the number grew */
    SvGROW(sv, SvCUR(sv) + 2);
    SvCUR(sv)++;
    for (d = SvPV(sv) + SvCUR(sv); d > SvPV(sv); d--)
	*d = d[-1];
    if (isDIGIT(d[1]))
	*d = '1';
    else
	*d = d[1];
}

void
sv_dec(sv)
register SV *sv;
{
    if (!sv)
	return;
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (SvMAGICAL(sv))
	mg_get(sv);
    if (SvIOK(sv)) {
	--SvIV(sv);
	SvIOK_only(sv);
	return;
    }
    if (SvNOK(sv)) {
	SvNV(sv) -= 1.0;
	SvNOK_only(sv);
	return;
    }
    if (!SvPOK(sv)) {
	if (!SvUPGRADE(sv, SVt_NV))
	    return;
	SvNV(sv) = -1.0;
	SvNOK_only(sv);
	return;
    }
    sv_setnv(sv,atof(SvPV(sv)) - 1.0);
}

/* Make a string that will exist for the duration of the expression
 * evaluation.  Actually, it may have to last longer than that, but
 * hopefully we won't free it until it has been assigned to a
 * permanent location. */

SV *
sv_mortalcopy(oldstr)
SV *oldstr;
{
    register SV *sv = NEWSV(78,0);

    sv_setsv(sv,oldstr);
    if (++tmps_ix > tmps_max) {
	tmps_max = tmps_ix;
	if (!(tmps_max & 127)) {
	    if (tmps_max)
		Renew(tmps_stack, tmps_max + 128, SV*);
	    else
		New(702,tmps_stack, 128, SV*);
	}
    }
    tmps_stack[tmps_ix] = sv;
    if (SvPOK(sv))
	SvTEMP_on(sv);
    return sv;
}

/* same thing without the copying */

SV *
sv_2mortal(sv)
register SV *sv;
{
    if (!sv)
	return sv;
    if (SvREADONLY(sv))
	fatal(no_modify);
    if (++tmps_ix > tmps_max) {
	tmps_max = tmps_ix;
	if (!(tmps_max & 127)) {
	    if (tmps_max)
		Renew(tmps_stack, tmps_max + 128, SV*);
	    else
		New(704,tmps_stack, 128, SV*);
	}
    }
    tmps_stack[tmps_ix] = sv;
    if (SvPOK(sv))
	SvTEMP_on(sv);
    return sv;
}

SV *
newSVpv(s,len)
char *s;
STRLEN len;
{
    register SV *sv = NEWSV(79,0);

    if (!len)
	len = strlen(s);
    sv_setpvn(sv,s,len);
    return sv;
}

SV *
newSVnv(n)
double n;
{
    register SV *sv = NEWSV(80,0);

    sv_setnv(sv,n);
    return sv;
}

SV *
newSViv(i)
I32 i;
{
    register SV *sv = NEWSV(80,0);

    sv_setiv(sv,i);
    return sv;
}

/* make an exact duplicate of old */

SV *
newSVsv(old)
register SV *old;
{
    register SV *new;

    if (!old)
	return Nullsv;
    if (SvTYPE(old) == 0xff) {
	warn("semi-panic: attempt to dup freed string");
	return Nullsv;
    }
    new = NEWSV(80,0);
    if (SvTEMP(old)) {
	SvTEMP_off(old);
	sv_setsv(new,old);
	SvTEMP_on(old);
    }
    else
	sv_setsv(new,old);
    return new;
}

void
sv_reset(s,stash)
register char *s;
HV *stash;
{
    register HE *entry;
    register GV *gv;
    register SV *sv;
    register I32 i;
    register PMOP *pm;
    register I32 max;

    if (!*s) {		/* reset ?? searches */
	for (pm = HvPMROOT(stash); pm; pm = pm->op_pmnext) {
	    pm->op_pmflags &= ~PMf_USED;
	}
	return;
    }

    /* reset variables */

    if (!HvARRAY(stash))
	return;
    while (*s) {
	i = *s;
	if (s[1] == '-') {
	    s += 2;
	}
	max = *s++;
	for ( ; i <= max; i++) {
	    for (entry = HvARRAY(stash)[i];
	      entry;
	      entry = entry->hent_next) {
		gv = (GV*)entry->hent_val;
		sv = GvSV(gv);
		SvOK_off(sv);
		if (SvTYPE(sv) >= SVt_PV) {
		    SvCUR_set(sv, 0);
		    SvTDOWN(sv);
		    if (SvPV(sv) != Nullch)
			*SvPV(sv) = '\0';
		}
		if (GvAV(gv)) {
		    av_clear(GvAV(gv));
		}
		if (GvHV(gv)) {
		    hv_clear(GvHV(gv), FALSE);
		    if (gv == envgv)
			environ[0] = Nullch;
		}
	    }
	}
    }
}

#ifdef OLD
AV *
sv_2av(sv, st, gvp, lref)
SV *sv;
HV **st;
GV **gvp;
I32 lref;
{
    GV *gv;

    switch (SvTYPE(sv)) {
    case SVt_PVAV:
	*st = sv->sv_u.sv_stash;
	*gvp = Nullgv;
	return sv->sv_u.sv_av;
    case SVt_PVHV:
    case SVt_PVCV:
	*gvp = Nullgv;
	return Nullav;
    default:
	if (isGV(sv))
	    gv = (GV*)sv;
	else
	    gv = gv_fetchpv(SvPVn(sv), lref);
	*gvp = gv;
	if (!gv)
	    return Nullav;
	*st = GvESTASH(gv);
	if (lref)
	    return GvAVn(gv);
	else
	    return GvAV(gv);
    }
}

HV *
sv_2hv(sv, st, gvp, lref)
SV *sv;
HV **st;
GV **gvp;
I32 lref;
{
    GV *gv;

    switch (SvTYPE(sv)) {
    case SVt_PVHV:
	*st = sv->sv_u.sv_stash;
	*gvp = Nullgv;
	return sv->sv_u.sv_hv;
    case SVt_PVAV:
    case SVt_PVCV:
	*gvp = Nullgv;
	return Nullhv;
    default:
	if (isGV(sv))
	    gv = (GV*)sv;
	else
	    gv = gv_fetchpv(SvPVn(sv), lref);
	*gvp = gv;
	if (!gv)
	    return Nullhv;
	*st = GvESTASH(gv);
	if (lref)
	    return GvHVn(gv);
	else
	    return GvHV(gv);
    }
}
#endif;

CV *
sv_2cv(sv, st, gvp, lref)
SV *sv;
HV **st;
GV **gvp;
I32 lref;
{
    GV *gv;
    CV *cv;

    if (!sv)
	return *gvp = Nullgv, Nullcv;
    switch (SvTYPE(sv)) {
    case SVt_REF:
	cv = (CV*)SvANY(sv);
	if (SvTYPE(cv) != SVt_PVCV)
	    fatal("Not a subroutine reference");
	*gvp = Nullgv;
	*st = CvSTASH(cv);
	return cv;
    case SVt_PVCV:
	*st = CvSTASH(sv);
	*gvp = Nullgv;
	return (CV*)sv;
    case SVt_PVHV:
    case SVt_PVAV:
	*gvp = Nullgv;
	return Nullcv;
    default:
	if (isGV(sv))
	    gv = (GV*)sv;
	else
	    gv = gv_fetchpv(SvPVn(sv), lref);
	*gvp = gv;
	if (!gv)
	    return Nullcv;
	*st = GvESTASH(gv);
	return GvCV(gv);
    }
}

#ifndef SvTRUE
I32
SvTRUE(sv)
register SV *sv;
{
    if (SvMAGICAL(sv))
	mg_get(sv);
    if (SvPOK(sv)) {
	register XPV* Xpv;
	if ((Xpv = (XPV*)SvANY(sv)) &&
		(*Xpv->xpv_pv > '0' ||
		Xpv->xpv_cur > 1 ||
		(Xpv->xpv_cur && *Xpv->xpv_pv != '0')))
	    return 1;
	else
	    return 0;
    }
    else {
	if (SvIOK(sv))
	    return SvIV(sv) != 0;
	else {
	    if (SvNOK(sv))
		return SvNV(sv) != 0.0;
	    else
		return 0;
	}
    }
}
#endif /* SvTRUE */

#ifndef SvNVn
double SvNVn(Sv)
register SV *Sv;
{
    SvTUP(Sv);
    if (SvMAGICAL(sv))
	mg_get(sv);
    if (SvNOK(Sv))
	return SvNV(Sv);
    if (SvIOK(Sv))
	return (double)SvIV(Sv);
    return sv_2nv(Sv);
}
#endif /* SvNVn */

#ifndef SvPVn
char *
SvPVn(sv)
SV *sv;
{
    SvTUP(sv);
    if (SvMAGICAL(sv))
	mg_get(sv);
    return SvPOK(sv) ? SvPV(sv) : sv_2pv(sv);
}
#endif

