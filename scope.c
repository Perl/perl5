/*    scope.c
 *
 *    Copyright (c) 1991-1997, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "For the fashion of Minas Tirith was such that it was built on seven
 * levels..."
 */

#include "EXTERN.h"
#include "perl.h"

static void setjmp_tryblock _((CPERLarg_ TRYVTBL *vtbl, void *locals));
    
void
install_tryblock_method(tryblock_f fn)
{
    if (fn)
	tryblock_function = fn;
    else
	tryblock_function = setjmp_tryblock;
}

SV**
stack_grow(SV **sp, SV **p, int n)
{
    dTHR;
#if defined(DEBUGGING) && !defined(USE_THREADS)
    static int growing = 0;
    if (growing++)
      abort();
#endif
    stack_sp = sp;
#ifndef STRESS_REALLOC
    av_extend(curstack, (p - stack_base) + (n) + 128);
#else
    av_extend(curstack, (p - stack_base) + (n) + 1);
#endif
#if defined(DEBUGGING) && !defined(USE_THREADS)
    growing--;
#endif
    return stack_sp;
}

#ifndef STRESS_REALLOC
#define GROW(old) ((old) * 3 / 2)
#else
#define GROW(old) ((old) + 1)
#endif

PERL_SI *
new_stackinfo(I32 stitems, I32 cxitems)
{
    PERL_SI *si;
    PERL_CONTEXT *cxt;
    New(56, si, 1, PERL_SI);
    si->si_stack = newAV();
    AvREAL_off(si->si_stack);
    av_extend(si->si_stack, stitems > 0 ? stitems-1 : 0);
    AvALLOC(si->si_stack)[0] = &sv_undef;
    AvFILLp(si->si_stack) = 0;
    si->si_prev = 0;
    si->si_next = 0;
    si->si_cxmax = cxitems - 1;
    si->si_cxix = -1;
    si->si_type = SI_UNDEF;
    New(56, si->si_cxstack, cxitems, PERL_CONTEXT);
    return si;
}

I32
cxinc(void)
{
    dTHR;
    cxstack_max = GROW(cxstack_max);
    Renew(cxstack, cxstack_max + 1, PERL_CONTEXT);	/* XXX should fix CXINC macro */
    return cxstack_ix + 1;
}

void
push_return(OP *retop)
{
    dTHR;
    if (retstack_ix == retstack_max) {
	retstack_max = GROW(retstack_max);
	Renew(retstack, retstack_max, OP*);
    }
    retstack[retstack_ix++] = retop;
}

OP *
pop_return(void)
{
    dTHR;
    if (retstack_ix > 0)
	return retstack[--retstack_ix];
    else
	return Nullop;
}

void
push_scope(void)
{
    dTHR;
    if (scopestack_ix == scopestack_max) {
	scopestack_max = GROW(scopestack_max);
	Renew(scopestack, scopestack_max, I32);
    }
    scopestack[scopestack_ix++] = savestack_ix;

}

void
pop_scope(void)
{
    dTHR;
    I32 oldsave = scopestack[--scopestack_ix];
    LEAVE_SCOPE(oldsave);
}

void
markstack_grow(void)
{
    dTHR;
    I32 oldmax = markstack_max - markstack;
    I32 newmax = GROW(oldmax);

    Renew(markstack, newmax, I32);
    markstack_ptr = markstack + oldmax;
    markstack_max = markstack + newmax;
}

void
savestack_grow(void)
{
    dTHR;
    savestack_max = GROW(savestack_max) + 4; 
    Renew(savestack, savestack_max, ANY);
}

#undef GROW

void
free_tmps(void)
{
    dTHR;
    /* XXX should tmps_floor live in cxstack? */
    I32 myfloor = tmps_floor;
    while (tmps_ix > myfloor) {      /* clean up after last statement */
	SV* sv = tmps_stack[tmps_ix];
	tmps_stack[tmps_ix--] = Nullsv;
	if (sv) {
#ifdef DEBUGGING
	    SvTEMP_off(sv);
#endif
	    SvREFCNT_dec(sv);		/* note, can modify tmps_ix!!! */
	}
    }
}

STATIC SV *
save_scalar_at(SV **sptr)
{
    dTHR;
    register SV *sv;
    SV *osv = *sptr;

    sv = *sptr = NEWSV(0,0);
    if (SvTYPE(osv) >= SVt_PVMG && SvMAGIC(osv) && SvTYPE(osv) != SVt_PVGV) {
	sv_upgrade(sv, SvTYPE(osv));
	if (SvGMAGICAL(osv)) {
	    MAGIC* mg;
	    bool oldtainted = tainted;
	    mg_get(osv);
	    if (tainting && tainted && (mg = mg_find(osv, 't'))) {
		SAVESPTR(mg->mg_obj);
		mg->mg_obj = osv;
	    }
	    SvFLAGS(osv) |= (SvFLAGS(osv) &
		(SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
	    tainted = oldtainted;
	}
	SvMAGIC(sv) = SvMAGIC(osv);
	SvFLAGS(sv) |= SvMAGICAL(osv);
	localizing = 1;
	SvSETMAGIC(sv);
	localizing = 0;
    }
    return sv;
}

SV *
save_scalar(GV *gv)
{
    dTHR;
    SV **sptr = &GvSV(gv);
    SSCHECK(3);
    SSPUSHPTR(SvREFCNT_inc(gv));
    SSPUSHPTR(SvREFCNT_inc(*sptr));
    SSPUSHINT(SAVEt_SV);
    return save_scalar_at(sptr);
}

SV*
save_svref(SV **sptr)
{
    dTHR;
    SSCHECK(3);
    SSPUSHPTR(sptr);
    SSPUSHPTR(SvREFCNT_inc(*sptr));
    SSPUSHINT(SAVEt_SVREF);
    return save_scalar_at(sptr);
}

void
save_gp(GV *gv, I32 empty)
{
    dTHR;
    SSCHECK(6);
    SSPUSHIV((IV)SvLEN(gv));
    SvLEN(gv) = 0; /* forget that anything was allocated here */
    SSPUSHIV((IV)SvCUR(gv));
    SSPUSHPTR(SvPVX(gv));
    SvPOK_off(gv);
    SSPUSHPTR(SvREFCNT_inc(gv));
    SSPUSHPTR(GvGP(gv));
    SSPUSHINT(SAVEt_GP);

    if (empty) {
	register GP *gp;

	if (GvCVu(gv))
	    sub_generation++;	/* taking a method out of circulation */
	Newz(602, gp, 1, GP);
	GvGP(gv) = gp_ref(gp);
	GvSV(gv) = NEWSV(72,0);
	GvLINE(gv) = curcop->cop_line;
	GvEGV(gv) = gv;
    }
    else {
	gp_ref(GvGP(gv));
	GvINTRO_on(gv);
    }
}

AV *
save_ary(GV *gv)
{
    dTHR;
    AV *oav = GvAVn(gv);
    AV *av;

    if (!AvREAL(oav) && AvREIFY(oav))
	av_reify(oav);
    SSCHECK(3);
    SSPUSHPTR(gv);
    SSPUSHPTR(oav);
    SSPUSHINT(SAVEt_AV);

    GvAV(gv) = Null(AV*);
    av = GvAVn(gv);
    if (SvMAGIC(oav)) {
	SvMAGIC(av) = SvMAGIC(oav);
	SvFLAGS(av) |= SvMAGICAL(oav);
	SvMAGICAL_off(oav);
	SvMAGIC(oav) = 0;
	localizing = 1;
	SvSETMAGIC((SV*)av);
	localizing = 0;
    }
    return av;
}

HV *
save_hash(GV *gv)
{
    dTHR;
    HV *ohv, *hv;

    SSCHECK(3);
    SSPUSHPTR(gv);
    SSPUSHPTR(ohv = GvHVn(gv));
    SSPUSHINT(SAVEt_HV);

    GvHV(gv) = Null(HV*);
    hv = GvHVn(gv);
    if (SvMAGIC(ohv)) {
	SvMAGIC(hv) = SvMAGIC(ohv);
	SvFLAGS(hv) |= SvMAGICAL(ohv);
	SvMAGICAL_off(ohv);
	SvMAGIC(ohv) = 0;
	localizing = 1;
	SvSETMAGIC((SV*)hv);
	localizing = 0;
    }
    return hv;
}

void
save_item(register SV *item)
{
    dTHR;
    register SV *sv = NEWSV(0,0);

    sv_setsv(sv,item);
    SSCHECK(3);
    SSPUSHPTR(item);		/* remember the pointer */
    SSPUSHPTR(sv);		/* remember the value */
    SSPUSHINT(SAVEt_ITEM);
}

void
save_int(int *intp)
{
    dTHR;
    SSCHECK(3);
    SSPUSHINT(*intp);
    SSPUSHPTR(intp);
    SSPUSHINT(SAVEt_INT);
}

void
save_long(long int *longp)
{
    dTHR;
    SSCHECK(3);
    SSPUSHLONG(*longp);
    SSPUSHPTR(longp);
    SSPUSHINT(SAVEt_LONG);
}

void
save_I32(I32 *intp)
{
    dTHR;
    SSCHECK(3);
    SSPUSHINT(*intp);
    SSPUSHPTR(intp);
    SSPUSHINT(SAVEt_I32);
}

void
save_I16(I16 *intp)
{
    dTHR;
    SSCHECK(3);
    SSPUSHINT(*intp);
    SSPUSHPTR(intp);
    SSPUSHINT(SAVEt_I16);
}

void
save_iv(IV *ivp)
{
    dTHR;
    SSCHECK(3);
    SSPUSHIV(*ivp);
    SSPUSHPTR(ivp);
    SSPUSHINT(SAVEt_IV);
}

/* Cannot use save_sptr() to store a char* since the SV** cast will
 * force word-alignment and we'll miss the pointer.
 */
void
save_pptr(char **pptr)
{
    dTHR;
    SSCHECK(3);
    SSPUSHPTR(*pptr);
    SSPUSHPTR(pptr);
    SSPUSHINT(SAVEt_PPTR);
}

void
save_sptr(SV **sptr)
{
    dTHR;
    SSCHECK(3);
    SSPUSHPTR(*sptr);
    SSPUSHPTR(sptr);
    SSPUSHINT(SAVEt_SPTR);
}

SV **
save_threadsv(PADOFFSET i)
{
#ifdef USE_THREADS
    dTHR;
    SV **svp = &THREADSV(i);	/* XXX Change to save by offset */
    DEBUG_L(PerlIO_printf(PerlIO_stderr(), "save_threadsv %u: %p %p:%s\n",
			  i, svp, *svp, SvPEEK(*svp)));
    save_svref(svp);
    return svp;
#else
    croak("panic: save_threadsv called in non-threaded perl");
    return 0;
#endif /* USE_THREADS */
}

void
save_nogv(GV *gv)
{
    dTHR;
    SSCHECK(2);
    SSPUSHPTR(gv);
    SSPUSHINT(SAVEt_NSTAB);
}

void
save_hptr(HV **hptr)
{
    dTHR;
    SSCHECK(3);
    SSPUSHPTR(*hptr);
    SSPUSHPTR(hptr);
    SSPUSHINT(SAVEt_HPTR);
}

void
save_aptr(AV **aptr)
{
    dTHR;
    SSCHECK(3);
    SSPUSHPTR(*aptr);
    SSPUSHPTR(aptr);
    SSPUSHINT(SAVEt_APTR);
}

void
save_freesv(SV *sv)
{
    dTHR;
    SSCHECK(2);
    SSPUSHPTR(sv);
    SSPUSHINT(SAVEt_FREESV);
}

void
save_freeop(OP *o)
{
    dTHR;
    SSCHECK(2);
    SSPUSHPTR(o);
    SSPUSHINT(SAVEt_FREEOP);
}

void
save_freepv(char *pv)
{
    dTHR;
    SSCHECK(2);
    SSPUSHPTR(pv);
    SSPUSHINT(SAVEt_FREEPV);
}

void
save_clearsv(SV **svp)
{
    dTHR;
    SSCHECK(2);
    SSPUSHLONG((long)(svp-curpad));
    SSPUSHINT(SAVEt_CLEARSV);
}

void
save_delete(HV *hv, char *key, I32 klen)
{
    dTHR;
    SSCHECK(4);
    SSPUSHINT(klen);
    SSPUSHPTR(key);
    SSPUSHPTR(SvREFCNT_inc(hv));
    SSPUSHINT(SAVEt_DELETE);
}

void
save_list(register SV **sarg, I32 maxsarg)
{
    dTHR;
    register SV *sv;
    register I32 i;

    for (i = 1; i <= maxsarg; i++) {
	sv = NEWSV(0,0);
	sv_setsv(sv,sarg[i]);
	SSCHECK(3);
	SSPUSHPTR(sarg[i]);		/* remember the pointer */
	SSPUSHPTR(sv);			/* remember the value */
	SSPUSHINT(SAVEt_ITEM);
    }
}

void
#ifdef PERL_OBJECT
save_destructor(DESTRUCTORFUNC f, void* p)
#else
save_destructor(void (*f) (void *), void *p)
#endif
{
    dTHR;
    SSCHECK(3);
    SSPUSHDPTR(f);
    SSPUSHPTR(p);
    SSPUSHINT(SAVEt_DESTRUCTOR);
}

void
save_aelem(AV *av, I32 idx, SV **sptr)
{
    dTHR;
    SSCHECK(4);
    SSPUSHPTR(SvREFCNT_inc(av));
    SSPUSHINT(idx);
    SSPUSHPTR(SvREFCNT_inc(*sptr));
    SSPUSHINT(SAVEt_AELEM);
    save_scalar_at(sptr);
}

void
save_helem(HV *hv, SV *key, SV **sptr)
{
    dTHR;
    SSCHECK(4);
    SSPUSHPTR(SvREFCNT_inc(hv));
    SSPUSHPTR(SvREFCNT_inc(key));
    SSPUSHPTR(SvREFCNT_inc(*sptr));
    SSPUSHINT(SAVEt_HELEM);
    save_scalar_at(sptr);
}

void
save_op(void)
{
    dTHR;
    SSCHECK(2);
    SSPUSHPTR(op);
    SSPUSHINT(SAVEt_OP);
}

void
leave_scope(I32 base)
{
    dTHR;
    register SV *sv;
    register SV *value;
    register GV *gv;
    register AV *av;
    register HV *hv;
    register void* ptr;
    I32 i;

    if (base < -1)
	croak("panic: corrupt saved stack index");
    while (savestack_ix > base) {
	switch (SSPOPINT) {
	case SAVEt_ITEM:			/* normal string */
	    value = (SV*)SSPOPPTR;
	    sv = (SV*)SSPOPPTR;
	    sv_replace(sv,value);
	    localizing = 2;
	    SvSETMAGIC(sv);
	    localizing = 0;
	    break;
        case SAVEt_SV:				/* scalar reference */
	    value = (SV*)SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
	    ptr = &GvSV(gv);
	    SvREFCNT_dec(gv);
	    goto restore_sv;
        case SAVEt_SVREF:			/* scalar reference */
	    value = (SV*)SSPOPPTR;
	    ptr = SSPOPPTR;
	restore_sv:
	    sv = *(SV**)ptr;
	    DEBUG_L(PerlIO_printf(PerlIO_stderr(),
				  "restore svref: %p %p:%s -> %p:%s\n",
			  	  ptr, sv, SvPEEK(sv), value, SvPEEK(value)));
	    if (SvTYPE(sv) >= SVt_PVMG && SvMAGIC(sv) &&
		SvTYPE(sv) != SVt_PVGV)
	    {
		(void)SvUPGRADE(value, SvTYPE(sv));
		SvMAGIC(value) = SvMAGIC(sv);
		SvFLAGS(value) |= SvMAGICAL(sv);
		SvMAGICAL_off(sv);
		SvMAGIC(sv) = 0;
	    }
	    else if (SvTYPE(value) >= SVt_PVMG && SvMAGIC(value) &&
		     SvTYPE(value) != SVt_PVGV)
	    {
		SvFLAGS(value) |= (SvFLAGS(value) &
				   (SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
		SvMAGICAL_off(value);
		SvMAGIC(value) = 0;
	    }
            SvREFCNT_dec(sv);
	    *(SV**)ptr = value;
	    localizing = 2;
	    SvSETMAGIC(value);
	    localizing = 0;
	    SvREFCNT_dec(value);
            break;
        case SAVEt_AV:				/* array reference */
	    av = (AV*)SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
	    if (GvAV(gv)) {
		AV *goner = GvAV(gv);
		SvMAGIC(av) = SvMAGIC(goner);
		SvFLAGS(av) |= SvMAGICAL(goner);
		SvMAGICAL_off(goner);
		SvMAGIC(goner) = 0;
		SvREFCNT_dec(goner);
	    }
            GvAV(gv) = av;
	    if (SvMAGICAL(av)) {
		localizing = 2;
		SvSETMAGIC((SV*)av);
		localizing = 0;
	    }
            break;
        case SAVEt_HV:				/* hash reference */
	    hv = (HV*)SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
	    if (GvHV(gv)) {
		HV *goner = GvHV(gv);
		SvMAGIC(hv) = SvMAGIC(goner);
		SvFLAGS(hv) |= SvMAGICAL(goner);
		SvMAGICAL_off(goner);
		SvMAGIC(goner) = 0;
		SvREFCNT_dec(goner);
	    }
            GvHV(gv) = hv;
	    if (SvMAGICAL(hv)) {
		localizing = 2;
		SvSETMAGIC((SV*)hv);
		localizing = 0;
	    }
            break;
	case SAVEt_INT:				/* int reference */
	    ptr = SSPOPPTR;
	    *(int*)ptr = (int)SSPOPINT;
	    break;
	case SAVEt_LONG:			/* long reference */
	    ptr = SSPOPPTR;
	    *(long*)ptr = (long)SSPOPLONG;
	    break;
	case SAVEt_I32:				/* I32 reference */
	    ptr = SSPOPPTR;
	    *(I32*)ptr = (I32)SSPOPINT;
	    break;
	case SAVEt_I16:				/* I16 reference */
	    ptr = SSPOPPTR;
	    *(I16*)ptr = (I16)SSPOPINT;
	    break;
	case SAVEt_IV:				/* IV reference */
	    ptr = SSPOPPTR;
	    *(IV*)ptr = (IV)SSPOPIV;
	    break;
	case SAVEt_SPTR:			/* SV* reference */
	    ptr = SSPOPPTR;
	    *(SV**)ptr = (SV*)SSPOPPTR;
	    break;
	case SAVEt_PPTR:			/* char* reference */
	    ptr = SSPOPPTR;
	    *(char**)ptr = (char*)SSPOPPTR;
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
	    (void)sv_clear((SV*)gv);
	    break;
	case SAVEt_GP:				/* scalar reference */
	    ptr = SSPOPPTR;
	    gv = (GV*)SSPOPPTR;
            if (SvPOK(gv) && SvLEN(gv) > 0) {
                Safefree(SvPVX(gv));
            }
            SvPVX(gv) = (char *)SSPOPPTR;
            SvCUR(gv) = (STRLEN)SSPOPIV;
            SvLEN(gv) = (STRLEN)SSPOPIV;
            gp_free(gv);
            GvGP(gv) = (GP*)ptr;
	    if (GvCVu(gv))
		sub_generation++;  /* putting a method back into circulation */
	    SvREFCNT_dec(gv);
            break;
	case SAVEt_FREESV:
	    ptr = SSPOPPTR;
	    SvREFCNT_dec((SV*)ptr);
	    break;
	case SAVEt_FREEOP:
	    ptr = SSPOPPTR;
	    if (comppad)
		curpad = AvARRAY(comppad);
	    op_free((OP*)ptr);
	    break;
	case SAVEt_FREEPV:
	    ptr = SSPOPPTR;
	    Safefree((char*)ptr);
	    break;
	case SAVEt_CLEARSV:
	    ptr = (void*)&curpad[SSPOPLONG];
	    sv = *(SV**)ptr;
	    /* Can clear pad variable in place? */
	    if (SvREFCNT(sv) <= 1 && !SvOBJECT(sv)) {
		if (SvTHINKFIRST(sv)) {
		    if (SvREADONLY(sv))
			croak("panic: leave_scope clearsv");
		    if (SvROK(sv))
			sv_unref(sv);
		}
		if (SvMAGICAL(sv))
		    mg_free(sv);

		switch (SvTYPE(sv)) {
		case SVt_NULL:
		    break;
		case SVt_PVAV:
		    av_clear((AV*)sv);
		    break;
		case SVt_PVHV:
		    hv_clear((HV*)sv);
		    break;
		case SVt_PVCV:
		    croak("panic: leave_scope pad code");
		case SVt_RV:
		case SVt_IV:
		case SVt_NV:
		    (void)SvOK_off(sv);
		    break;
		default:
		    (void)SvOK_off(sv);
		    (void)SvOOK_off(sv);
		    break;
		}
	    }
	    else {	/* Someone has a claim on this, so abandon it. */
		U32 padflags = SvFLAGS(sv) & (SVs_PADBUSY|SVs_PADMY|SVs_PADTMP);
		switch (SvTYPE(sv)) {	/* Console ourselves with a new value */
		case SVt_PVAV:	*(SV**)ptr = (SV*)newAV();	break;
		case SVt_PVHV:	*(SV**)ptr = (SV*)newHV();	break;
		default:	*(SV**)ptr = NEWSV(0,0);	break;
		}
		SvREFCNT_dec(sv);	/* Cast current value to the winds. */
		SvFLAGS(*(SV**)ptr) |= padflags; /* preserve pad nature */
	    }
	    break;
	case SAVEt_DELETE:
	    ptr = SSPOPPTR;
	    hv = (HV*)ptr;
	    ptr = SSPOPPTR;
	    (void)hv_delete(hv, (char*)ptr, (U32)SSPOPINT, G_DISCARD);
	    SvREFCNT_dec(hv);
	    Safefree(ptr);
	    break;
	case SAVEt_DESTRUCTOR:
	    ptr = SSPOPPTR;
	    (CALLDESTRUCTOR)(ptr);
	    break;
	case SAVEt_REGCONTEXT:
	    i = SSPOPINT;
	    savestack_ix -= i;  	/* regexp must have croaked */
	    break;
	case SAVEt_STACK_POS:		/* Position on Perl stack */
	    i = SSPOPINT;
	    stack_sp = stack_base + i;
	    break;
	case SAVEt_AELEM:		/* array element */
	    value = (SV*)SSPOPPTR;
	    i = SSPOPINT;
	    av = (AV*)SSPOPPTR;
	    ptr = av_fetch(av,i,1);
	    if (ptr) {
		sv = *(SV**)ptr;
		if (sv && sv != &sv_undef) {
		    if (SvRMAGICAL(av) && mg_find((SV*)av, 'P'))
			(void)SvREFCNT_inc(sv);
		    SvREFCNT_dec(av);
		    goto restore_sv;
		}
	    }
	    SvREFCNT_dec(av);
	    SvREFCNT_dec(value);
	    break;
	case SAVEt_HELEM:		/* hash element */
	    value = (SV*)SSPOPPTR;
	    sv = (SV*)SSPOPPTR;
	    hv = (HV*)SSPOPPTR;
	    ptr = hv_fetch_ent(hv, sv, 1, 0);
	    if (ptr) {
		SV *oval = HeVAL((HE*)ptr);
		if (oval && oval != &sv_undef) {
		    ptr = &HeVAL((HE*)ptr);
		    if (SvRMAGICAL(hv) && mg_find((SV*)hv, 'P'))
			(void)SvREFCNT_inc(*(SV**)ptr);
		    SvREFCNT_dec(hv);
		    SvREFCNT_dec(sv);
		    goto restore_sv;
		}
	    }
	    SvREFCNT_dec(hv);
	    SvREFCNT_dec(sv);
	    SvREFCNT_dec(value);
	    break;
	case SAVEt_OP:
	    op = (OP*)SSPOPPTR;
	    break;
	default:
	    croak("panic: leave_scope inconsistency");
	}
    }
}

void
cx_dump(PERL_CONTEXT *cx)
{
#ifdef DEBUGGING
    dTHR;
    PerlIO_printf(Perl_debug_log, "CX %ld = %s\n", (long)(cx - cxstack), block_type[cx->cx_type]);
    if (cx->cx_type != CXt_SUBST) {
	PerlIO_printf(Perl_debug_log, "BLK_OLDSP = %ld\n", (long)cx->blk_oldsp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDCOP = 0x%lx\n", (long)cx->blk_oldcop);
	PerlIO_printf(Perl_debug_log, "BLK_OLDMARKSP = %ld\n", (long)cx->blk_oldmarksp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDSCOPESP = %ld\n", (long)cx->blk_oldscopesp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDRETSP = %ld\n", (long)cx->blk_oldretsp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDPM = 0x%lx\n", (long)cx->blk_oldpm);
	PerlIO_printf(Perl_debug_log, "BLK_GIMME = %s\n", cx->blk_gimme ? "LIST" : "SCALAR");
    }
    switch (cx->cx_type) {
    case CXt_NULL:
    case CXt_BLOCK:
	break;
    case CXt_SUB:
	PerlIO_printf(Perl_debug_log, "BLK_SUB.CV = 0x%lx\n",
		(long)cx->blk_sub.cv);
	PerlIO_printf(Perl_debug_log, "BLK_SUB.GV = 0x%lx\n",
		(long)cx->blk_sub.gv);
	PerlIO_printf(Perl_debug_log, "BLK_SUB.DFOUTGV = 0x%lx\n",
		(long)cx->blk_sub.dfoutgv);
	PerlIO_printf(Perl_debug_log, "BLK_SUB.OLDDEPTH = %ld\n",
		(long)cx->blk_sub.olddepth);
	PerlIO_printf(Perl_debug_log, "BLK_SUB.HASARGS = %d\n",
		(int)cx->blk_sub.hasargs);
	break;
    case CXt_EVAL:
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_IN_EVAL = %ld\n",
		(long)cx->blk_eval.old_in_eval);
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_OP_TYPE = %s (%s)\n",
		op_name[cx->blk_eval.old_op_type],
		op_desc[cx->blk_eval.old_op_type]);
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_NAME = %s\n",
		cx->blk_eval.old_name);
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_EVAL_ROOT = 0x%lx\n",
		(long)cx->blk_eval.old_eval_root);
	break;

    case CXt_LOOP:
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.LABEL = %s\n",
		cx->blk_loop.label);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.RESETSP = %ld\n",
		(long)cx->blk_loop.resetsp);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.REDO_OP = 0x%lx\n",
		(long)cx->blk_loop.redo_op);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.NEXT_OP = 0x%lx\n",
		(long)cx->blk_loop.next_op);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.LAST_OP = 0x%lx\n",
		(long)cx->blk_loop.last_op);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERIX = %ld\n",
		(long)cx->blk_loop.iterix);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERARY = 0x%lx\n",
		(long)cx->blk_loop.iterary);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERVAR = 0x%lx\n",
		(long)cx->blk_loop.itervar);
	if (cx->blk_loop.itervar)
	    PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERSAVE = 0x%lx\n",
		(long)cx->blk_loop.itersave);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERLVAL = 0x%lx\n",
		(long)cx->blk_loop.iterlval);
	break;

    case CXt_SUBST:
	PerlIO_printf(Perl_debug_log, "SB_ITERS = %ld\n",
		(long)cx->sb_iters);
	PerlIO_printf(Perl_debug_log, "SB_MAXITERS = %ld\n",
		(long)cx->sb_maxiters);
	PerlIO_printf(Perl_debug_log, "SB_SAFEBASE = %ld\n",
		(long)cx->sb_safebase);
	PerlIO_printf(Perl_debug_log, "SB_ONCE = %ld\n",
		(long)cx->sb_once);
	PerlIO_printf(Perl_debug_log, "SB_ORIG = %s\n",
		cx->sb_orig);
	PerlIO_printf(Perl_debug_log, "SB_DSTR = 0x%lx\n",
		(long)cx->sb_dstr);
	PerlIO_printf(Perl_debug_log, "SB_TARG = 0x%lx\n",
		(long)cx->sb_targ);
	PerlIO_printf(Perl_debug_log, "SB_S = 0x%lx\n",
		(long)cx->sb_s);
	PerlIO_printf(Perl_debug_log, "SB_M = 0x%lx\n",
		(long)cx->sb_m);
	PerlIO_printf(Perl_debug_log, "SB_STREND = 0x%lx\n",
		(long)cx->sb_strend);
	PerlIO_printf(Perl_debug_log, "SB_RXRES = 0x%lx\n",
		(long)cx->sb_rxres);
	break;
    }
#endif	/* DEBUGGING */
}

#include "XSUB.h"

/* make 'static' once JMPENV_PUSH is no longer used (see scope.h) XXX */
void
setjmp_jump(CPERLarg)
{
    dTHR;
    PerlProc_longjmp(((SETJMPENV*)top_env)->je_buf, 1);
}

static void
setjmp_tryblock(CPERLarg_ TRYVTBL *vtbl, void *locals)
{
    dTHR;
    int jmpstat;
    SETJMPENV je;
    JMPENV_INIT(je, setjmp_jump);
    PerlProc_setjmp(je.je_buf, 1);
    JMPENV_TRY(je);
    jmpstat = JMPENV_STAT(je);
    switch (jmpstat) {
    case JMP_NORMAL:
	assert(vtbl->try_normal[0]);
	(*vtbl->try_normal[0])(PERL_OBJECT_THIS_ locals);
	break;
    case JMP_EXCEPTION:
	if (vtbl->try_exception[0])
	    (*vtbl->try_exception[0])(PERL_OBJECT_THIS_ locals);
	break;
    case JMP_MYEXIT:
	if (vtbl->try_myexit[0])
	    (*vtbl->try_myexit[0])(PERL_OBJECT_THIS_ locals);
	break;
    default:
	if (jmpstat != JMP_ABNORMAL)
	    PerlIO_printf(PerlIO_stderr(),
			  "JMPENV_JUMP(%d) is bogus\n", jmpstat);
	if (vtbl->try_abnormal[0])
	    (*vtbl->try_abnormal[0])(PERL_OBJECT_THIS_ locals);
	break;
    }
    JMPENV_POP_JE(je);
    switch (JMPENV_STAT(je)) {
    case JMP_NORMAL:
	if (vtbl->try_normal[1])
	    (*vtbl->try_normal[1])(PERL_OBJECT_THIS_ locals);
	break;
    case JMP_EXCEPTION:
	if (vtbl->try_exception[1])
	    (*vtbl->try_exception[1])(PERL_OBJECT_THIS_ locals);
	break;
    case JMP_MYEXIT:
	if (vtbl->try_myexit[1])
	    (*vtbl->try_myexit[1])(PERL_OBJECT_THIS_ locals);
	break;
    default:
	if (jmpstat != JMP_ABNORMAL)
	    PerlIO_printf(PerlIO_stderr(),
			  "JMPENV_JUMP(%d) is bogus\n", jmpstat);
	if (vtbl->try_abnormal[1])
	    (*vtbl->try_abnormal[1])(PERL_OBJECT_THIS_ locals);
	break;
    }
}

