/* $RCSfile: op.c,v $$Revision: 4.1 $$Date: 92/08/07 17:19:16 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	op.c,v $
 */

#include "EXTERN.h"
#include "perl.h"

I32
cxinc()
{
    cxstack_max = cxstack_max * 3 / 2;
    Renew(cxstack, cxstack_max, CONTEXT);
    return cxstack_ix + 1;
}

void
push_return(retop)
OP *retop;
{
    if (retstack_ix == retstack_max) {
	retstack_max = retstack_max * 3 / 2;
	Renew(retstack, retstack_max, OP*);
    }
    retstack[retstack_ix++] = retop;
}

OP *
pop_return()
{
    if (retstack_ix > 0)
	return retstack[--retstack_ix];
    else
	return Nullop;
}

void
push_scope()
{
    if (scopestack_ix == scopestack_max) {
	scopestack_max = scopestack_max * 3 / 2;
	Renew(scopestack, scopestack_max, I32);
    }
    scopestack[scopestack_ix++] = savestack_ix;

}

void
pop_scope()
{
    I32 oldsave = scopestack[--scopestack_ix];
    if (savestack_ix > oldsave)
	leave_scope(oldsave);
}

void
savestack_grow()
{
    savestack_max = savestack_max * 3 / 2;
    Renew(savestack, savestack_max, ANY);
}

void
free_tmps()
{
    /* XXX should tmps_floor live in cxstack? */
    I32 myfloor = tmps_floor;
    while (tmps_ix > myfloor) {      /* clean up after last statement */
	SV* sv = tmps_stack[tmps_ix];
	tmps_stack[tmps_ix--] = Nullsv;
	if (sv)
	    sv_free(sv);		/* note, can modify tmps_ix!!! */
    }
}

SV *
save_scalar(gv)
GV *gv;
{
    register SV *sv;
    SV *osv = GvSV(gv);

    SSCHECK(3);
    SSPUSHPTR(gv);
    SSPUSHPTR(osv);
    SSPUSHINT(SAVEt_SV);

    sv = GvSV(gv) = NEWSV(0,0);
    if (SvTYPE(osv) >= SVt_PVMG && SvMAGIC(osv)) {
	sv_upgrade(sv, SvTYPE(osv));
	SvMAGIC(sv) = SvMAGIC(osv);
	localizing = TRUE;
	SvSETMAGIC(sv);
	localizing = FALSE;
    }
    return sv;
}

#ifdef INLINED_ELSEWHERE
void
save_gp(gv)
GV *gv;
{
    register GP *gp;
    GP *ogp = GvGP(gv);

    SSCHECK(3);
    SSPUSHPTR(gv);
    SSPUSHPTR(ogp);
    SSPUSHINT(SAVEt_GP);

    Newz(602,gp, 1, GP);
    GvGP(gv) = gp;
    GvREFCNT(gv) = 1;
    GvSV(gv) = NEWSV(72,0);
    GvLINE(gv) = curcop->cop_line;
    GvEGV(gv) = gv;
}
#endif

SV*
save_svref(sptr)
SV **sptr;
{
    register SV *sv;
    SV *osv = *sptr;

    SSCHECK(3);
    SSPUSHPTR(*sptr);
    SSPUSHPTR(sptr);
    SSPUSHINT(SAVEt_SVREF);

    sv = *sptr = NEWSV(0,0);
    if (SvTYPE(osv) >= SVt_PVMG && SvMAGIC(sv)) {
	sv_upgrade(sv, SvTYPE(osv));
	SvMAGIC(sv) = SvMAGIC(osv);
	localizing = TRUE;
	SvSETMAGIC(sv);
	localizing = FALSE;
    }
    return sv;
}

AV *
save_ary(gv)
GV *gv;
{
    SSCHECK(3);
    SSPUSHPTR(gv);
    SSPUSHPTR(GvAVn(gv));
    SSPUSHINT(SAVEt_AV);

    GvAV(gv) = Null(AV*);
    return GvAVn(gv);
}

HV *
save_hash(gv)
GV *gv;
{
    SSCHECK(3);
    SSPUSHPTR(gv);
    SSPUSHPTR(GvHVn(gv));
    SSPUSHINT(SAVEt_HV);

    GvHV(gv) = Null(HV*);
    return GvHVn(gv);
}

void
save_item(item)
register SV *item;
{
    register SV *sv;

    SSCHECK(3);
    SSPUSHPTR(item);		/* remember the pointer */
    sv = NEWSV(0,0);
    sv_setsv(sv,item);
    SSPUSHPTR(sv);		/* remember the value */
    SSPUSHINT(SAVEt_ITEM);
}

void
save_int(intp)
int *intp;
{
    SSCHECK(3);
    SSPUSHINT(*intp);
    SSPUSHPTR(intp);
    SSPUSHINT(SAVEt_INT);
}

void
save_I32(intp)
I32 *intp;
{
    SSCHECK(3);
    SSPUSHINT(*intp);
    SSPUSHPTR(intp);
    SSPUSHINT(SAVEt_I32);
}

void
save_sptr(sptr)
SV **sptr;
{
    SSCHECK(3);
    SSPUSHPTR(*sptr);
    SSPUSHPTR(sptr);
    SSPUSHINT(SAVEt_SPTR);
}

void
save_nogv(gv)
GV *gv;
{
    SSCHECK(2);
    SSPUSHPTR(gv);
    SSPUSHINT(SAVEt_NSTAB);
}

void
save_hptr(hptr)
HV **hptr;
{
    SSCHECK(3);
    SSPUSHINT(*hptr);
    SSPUSHPTR(hptr);
    SSPUSHINT(SAVEt_HPTR);
}

void
save_aptr(aptr)
AV **aptr;
{
    SSCHECK(3);
    SSPUSHINT(*aptr);
    SSPUSHPTR(aptr);
    SSPUSHINT(SAVEt_APTR);
}

void
save_list(sarg,maxsarg)
register SV **sarg;
I32 maxsarg;
{
    register SV *sv;
    register I32 i;

    SSCHECK(3 * maxsarg);
    for (i = 1; i <= maxsarg; i++) {
	SSPUSHPTR(sarg[i]);		/* remember the pointer */
	sv = NEWSV(0,0);
	sv_setsv(sv,sarg[i]);
	SSPUSHPTR(sv);			/* remember the value */
	SSPUSHINT(SAVEt_ITEM);
    }
}

void
leave_scope(base)
I32 base;
{
    register SV *sv;
    register SV *value;
    register GV *gv;
    register AV *av;
    register HV *hv;
    register void* ptr;

    if (base < -1)
	fatal("panic: corrupt saved stack index");
    while (savestack_ix > base) {
	switch (SSPOPINT) {
	case SAVEt_ITEM:			/* normal string */
	    value = (SV*)SSPOPPTR;
	    sv = (SV*)SSPOPPTR;
	    sv_replace(sv,value);
	    SvSETMAGIC(sv);
	    break;
        case SAVEt_SV:				/* scalar reference */
	    value = (SV*)SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
	    sv = GvSV(gv);
	    if (SvTYPE(sv) >= SVt_PVMG)
		SvMAGIC(sv) = 0;
            sv_free(sv);
            GvSV(gv) = sv = value;
	    SvSETMAGIC(sv);
            break;
        case SAVEt_SVREF:			/* scalar reference */
	    ptr = SSPOPPTR;
	    sv = *(SV**)ptr;
	    if (SvTYPE(sv) >= SVt_PVMG)
		SvMAGIC(sv) = 0;
            sv_free(sv);
	    *(SV**)ptr = sv = (SV*)SSPOPPTR;
	    SvSETMAGIC(sv);
            break;
        case SAVEt_AV:				/* array reference */
	    av = (AV*)SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
            av_free(GvAV(gv));
            GvAV(gv) = av;
            break;
        case SAVEt_HV:				/* hash reference */
	    hv = (HV*)SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
            (void)hv_free(GvHV(gv), FALSE);
            GvHV(gv) = hv;
            break;
	case SAVEt_INT:				/* int reference */
	    ptr = SSPOPPTR;
	    *(int*)ptr = (int)SSPOPINT;
	    break;
	case SAVEt_I32:				/* I32 reference */
	    ptr = SSPOPPTR;
	    *(I32*)ptr = (I32)SSPOPINT;
	    break;
	case SAVEt_SPTR:			/* SV* reference */
	    ptr = SSPOPPTR;
	    *(SV**)ptr = (SV*)SSPOPPTR;
	    break;
	case SAVEt_HPTR:			/* HV* reference */
	    ptr = SSPOPPTR;
	    *(HV**)ptr = (HV*)SSPOPPTR;
	    break;
	case SAVEt_APTR:			/* AV* reference */
	    ptr = SSPOPPTR;
	    *(AV**)ptr = (AV*)SSPOPPTR;
	    break;
	case SAVEt_NSTAB:
	    gv = (GV*)SSPOPPTR;
	    (void)sv_clear(gv);
	    break;
        case SAVEt_GP:				/* scalar reference */
	    ptr = SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
            gp_free(gv);
            GvGP(gv) = (GP*)ptr;
            break;
	default:
	    fatal("panic: leave_scope inconsistency");
	}
    }
}
