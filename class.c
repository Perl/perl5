/*    class.c
 *
 *    Copyright (C) 2022 by Paul Evans and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/* This file contains the code that implements perl's new `use feature 'class'`
 * object model
 */

#include "EXTERN.h"
#define PERL_IN_CLASS_C
#include "perl.h"

#include "XSUB.h"

enum {
    PADIX_SELF   = 1,
    PADIX_PARAMS = 2,
};

void
Perl_croak_kw_unless_class(pTHX_ const char *kw)
{
    PERL_ARGS_ASSERT_CROAK_KW_UNLESS_CLASS;

    if(!HvSTASH_IS_CLASS(PL_curstash))
        croak("Cannot '%s' outside of a 'class'", kw);
}

#define newSVobject(fieldcount)  Perl_newSVobject(aTHX_ fieldcount)
SV *
Perl_newSVobject(pTHX_ Size_t fieldcount)
{
    SV *sv = newSV_type(SVt_PVOBJ);

    if (fieldcount) {
        ObjectMAXFIELD(sv) = fieldcount - 1;
        Newx(ObjectFIELDS(sv), fieldcount, SV *);
        Zero(ObjectFIELDS(sv), fieldcount, SV *);
    }
#ifdef DEBUGGING
    else {
        assert(!ObjectFIELDS(sv));
        assert(ObjectMAXFIELD(sv) == -1);
    }
#endif
    return sv;
}

PP(pp_initfield)
{
    UNOP_AUX_item *aux = cUNOP_AUX->op_aux;

    SV *self = PAD_SVl(PADIX_SELF);
    assert(SvTYPE(SvRV(self)) == SVt_PVOBJ);
    SV *instance = SvRV(self);

    SV **fields = ObjectFIELDS(instance);

    PADOFFSET fieldix = aux[0].uv;

    SV *val = NULL;

    switch(PL_op->op_private & (OPpINITFIELD_AV|OPpINITFIELD_HV)) {
        case 0:
            if(PL_op->op_flags & OPf_STACKED) {
                val = newSVsv(*PL_stack_sp);
                rpp_popfree_1();
            }
            else
                val = newSV(0);
            break;

        case OPpINITFIELD_AV:
        {
            AV *av;
            if(PL_op->op_flags & OPf_STACKED) {
                SV **svp = PL_stack_base + POPMARK + 1;
                STRLEN count = PL_stack_sp - svp + 1;

                if (count != 0) {
                    av = newAV_alloc_x(count);

                    while(svp <= PL_stack_sp) {
                        av_push_simple(av, newSVsv(*svp));
                        svp++;
                    }
                    rpp_popfree_to(PL_stack_sp - count);
                }
                else
                    av = newAV();
            }
            else
                av = newAV();
            val = (SV *)av;
            break;
        }

        case OPpINITFIELD_HV:
        {
            HV *hv = newHV();
            if(PL_op->op_flags & OPf_STACKED) {
                SV **svp = PL_stack_base + POPMARK + 1;
                STRLEN svcount = PL_stack_sp - svp + 1;

                if(svcount % 2)
                    warner(packWARN(WARN_MISC), "Odd number of elements in hash field initialization");

                while(svp <= PL_stack_sp) {
                    SV *key = *svp; svp++;
                    SV *val = svp <= PL_stack_sp ? *svp : &PL_sv_undef; svp++;

                    (void)hv_store_ent(hv, key, newSVsv(val), 0);
                }
                rpp_popfree_to(PL_stack_sp - svcount);
            }
            val = (SV *)hv;
            break;
        }
    }

    fields[fieldix] = val;

    PADOFFSET padix = PL_op->op_targ;
    if(padix) {
        SAVESPTR(PAD_SVl(padix));
        SV *sv = PAD_SVl(padix) = SvREFCNT_inc(val);
        save_freesv(sv);
    }

    return NORMAL;
}

XS(injected_constructor);
XS(injected_constructor)
{
    dXSARGS;

    HV *stash = CvSTASH(cv);
    assert(HvSTASH_IS_CLASS(stash));

    struct xpvhv_aux *aux = HvAUX(stash);

    if((items - 1) % 2)
        warn("Odd number of arguments passed to %" HvNAMEf_QUOTEDPREFIX " constructor",
                HvNAMEfARG(stash));

    if (!aux->xhv_class_initfields_cv) {
        croak("Cannot create an object of incomplete class %" HvNAMEf_QUOTEDPREFIX,
                   HvNAMEfARG(stash));
    }

    HV *params = NULL;
    {
        /* Set up params HV */
        params = newHV();
        SAVEFREESV((SV *)params);

        for(SSize_t i = 1; i < items; i += 2) {
            SV *name = ST(i);
            SV *val  = (i+1 < items) ? ST(i+1) : &PL_sv_undef;

            /* TODO: think about sanity-checking name for being 
             *   defined
             *   not ref (but overloaded objects?? boo)
             *   not duplicate
             * But then,  %params = @_;  wouldn't do that
             */

            (void)hv_store_ent(params, name, SvREFCNT_inc(val), 0);
        }
    }

    SV *instance = newSVobject(aux->xhv_class_next_fieldix);
    SvOBJECT_on(instance);
    SvSTASH_set(instance, HvREFCNT_inc_simple(stash));

    SV *self = sv_2mortal(newRV_noinc(instance));

    PUSHSTACKi(PERLSI_CONSTRUCTOR);

    assert(aux->xhv_class_initfields_cv);
    {
        ENTER;
        SAVETMPS;

        EXTEND(SP, 2);
        PUSHMARK(SP);
        PUSHs(self);
        if(params)
            PUSHs((SV *)params); // yes a raw HV
        else
            PUSHs(&PL_sv_undef);
        PUTBACK;

        call_sv((SV *)aux->xhv_class_initfields_cv, G_VOID);

        SPAGAIN;

        FREETMPS;
        LEAVE;
    }

    if(aux->xhv_class_adjust_blocks) {
        CV **cvp = (CV **)AvARRAY(aux->xhv_class_adjust_blocks);
        U32 nblocks = av_count(aux->xhv_class_adjust_blocks);

        for(U32 i = 0; i < nblocks; i++) {
            ENTER;
            SAVETMPS;
            SPAGAIN;

            EXTEND(SP, 2);

            PUSHMARK(SP);
            PUSHs(self);  /* I don't believe this needs to be an sv_mortalcopy() */
            PUTBACK;

            call_sv((SV *)cvp[i], G_VOID);

            SPAGAIN;

            FREETMPS;
            LEAVE;
        }
    }

    POPSTACK;
    SPAGAIN;

    if(params && hv_iterinit(params) > 0) {
        /* TODO: consider sorting these into a canonical order, but that's awkward */
        HE *he = hv_iternext(params);

        SV *paramnames = newSVsv(HeSVKEY_force(he));
        SAVEFREESV(paramnames);

        while((he = hv_iternext(params)))
            sv_catpvf(paramnames, ", %" SVf, SVfARG(HeSVKEY_force(he)));

        croak("Unrecognized parameters for %" HvNAMEf_QUOTEDPREFIX " constructor: %" SVf,
                HvNAMEfARG(stash), SVfARG(paramnames));
    }

    EXTEND(SP, 1);
    ST(0) = self;
    XSRETURN(1);
}

/* OP_METHSTART is an UNOP_AUX whose AUX list contains
 *   [0].uv = count of fieldbinding pairs
 *   [1].uv = maximum fieldidx found in the binding list
 *   [...] = pairs of (padix, fieldix) to bind in .uv fields
 */

/* TODO: People would probably expect to find this in pp.c  ;) */
PP(pp_methstart)
{
    bool self_in_pad = PL_op->op_private & OPpSELF_IN_PAD;
    SV *self;
    if (self_in_pad)
        self = PAD_SVl(PADIX_SELF);
    else
        /* note that if AvREAL(@_), be careful not to leak self:
         * so keep it in @_ for now, and only shift it later */
        self = *(av_fetch(GvAV(PL_defgv), 0, 1));
    SV *rv = NULL;

    /* pp_methstart happens before the first OP_NEXTSTATE of the method body,
     * meaning PL_curcop still points at the callsite. This is useful for
     * croak() messages. However, it means we have to find our current stash
     * via a different technique.
     */
    CV *curcv;
    if(LIKELY(CxTYPE(CX_CUR()) == CXt_SUB))
        curcv = CX_CUR()->blk_sub.cv;
    else
        curcv = find_runcv(NULL);

    if(!SvROK(self) ||
        !SvOBJECT((rv = SvRV(self))) ||
        SvTYPE(rv) != SVt_PVOBJ) {
        HEK *namehek = CvGvNAME_HEK(curcv);
        croak(
            namehek ? "Cannot invoke method %" HEKf_QUOTEDPREFIX " on a non-instance" :
                      "Cannot invoke method on a non-instance",
            namehek);
    }

    if(CvSTASH(curcv) != SvSTASH(rv) &&
        !sv_derived_from_hv(self, CvSTASH(curcv)))
        croak("Cannot invoke a method of %" HvNAMEf_QUOTEDPREFIX " on an instance of %" HvNAMEf_QUOTEDPREFIX,
            HvNAMEfARG(CvSTASH(curcv)), HvNAMEfARG(SvSTASH(rv)));

    if (!self_in_pad) {
        save_clearsv(&PAD_SVl(PADIX_SELF));
        sv_setsv(PAD_SVl(PADIX_SELF), self);
    }

    UNOP_AUX_item *aux = cUNOP_AUX->op_aux;
    if(aux) {
        assert(SvTYPE(SvRV(self)) == SVt_PVOBJ);
        SV *instance = SvRV(self);
        SV **fieldp = ObjectFIELDS(instance);

        U32 fieldcount = (aux++)->uv;
        U32 max_fieldix = (aux++)->uv;

        assert((U32)(ObjectMAXFIELD(instance)+1) > max_fieldix);
        PERL_UNUSED_VAR(max_fieldix);

        for(Size_t i = 0; i < fieldcount; i++) {
            PADOFFSET padix   = (aux++)->uv;
            U32       fieldix = (aux++)->uv;

            /* Defend against fields that don't yet exist; e.g. because of
             * method invoked during DESTROY of an aborted constructor
             *   See also https://github.com/Perl/perl5/issues/22278
             */
            if(fieldp[fieldix]) {
                save_padsv(padix);
                PAD_SVl(padix) = SvREFCNT_inc(fieldp[fieldix]);
            }
        }
    }

    if (!self_in_pad) {
        /* safe to shift and free self now */
        self = av_shift(GvAV(PL_defgv));
        if (AvREAL(GvAV(PL_defgv)))
            SvREFCNT_dec_NN(self);
    }

    if(PL_op->op_private & OPpINITFIELDS) {
        SV *params = *av_fetch(GvAV(PL_defgv), 0, 0);
        if(params && SvTYPE(params) == SVt_PVHV) {
            save_padsv(PADIX_PARAMS);
            PAD_SVl(PADIX_PARAMS) = SvREFCNT_inc(params);
        }
    }

    return NORMAL;
}

static void
invoke_class_seal(pTHX_ void *arg_)
{
    class_seal_stash((HV *)arg_);
}

void
Perl_class_setup_stash(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_CLASS_SETUP_STASH;

    assert(HvHasAUX(stash));

    if(HvSTASH_IS_CLASS(stash)) {
        croak("Cannot reopen existing class %" HvNAMEf_QUOTEDPREFIX,
            HvNAMEfARG(stash));
    }

    {
        SV *isaname = newSVpvf("%" HEKf "::ISA", HvNAME_HEK(stash));
        sv_2mortal(isaname);

        AV *isa = get_av(SvPV_nolen(isaname), (SvFLAGS(isaname) & SVf_UTF8));

        if(isa && av_count(isa) > 0)
            croak("Cannot create class %" HEKf " as it already has a non-empty @ISA",
                HvNAME_HEK(stash));
    }

    char *classname = HvNAME(stash);
    U32 nameflags = HvNAMEUTF8(stash) ? SVf_UTF8 : 0;

    /* TODO:
     *   Set some kind of flag on the stash to point out it's a class
     *   Allocate storage for all the extra things a class needs
     *     See https://github.com/leonerd/perl5/discussions/1
     */

    /* Inject the constructor */
    {
        SV *newname = newSVpvf("%s::new", classname);
        SAVEFREESV(newname);

        CV *newcv = newXS_flags(SvPV_nolen(newname), injected_constructor, __FILE__, NULL, nameflags);
        CvSTASH_set(newcv, stash);
    }

    /* TODO:
     *   DOES method
     */

    struct xpvhv_aux *aux = HvAUX(stash);
    aux->xhv_class_flags         = 0;
    aux->xhv_class_superclass    = NULL;
    aux->xhv_class_initfields_cv = NULL;
    aux->xhv_class_adjust_blocks = NULL;
    aux->xhv_class_fields        = NULL;
    aux->xhv_class_next_fieldix  = 0;
    aux->xhv_class_param_map     = NULL;
    aux->xhv_class_subclasses_pending_seal = NULL;

    aux->xhv_aux_flags |= HvAUXf_IS_CLASS;

    SAVEDESTRUCTOR_X(invoke_class_seal, stash);

    /* Prepare a suspended compcv for parsing field init expressions */
    {
        I32 floor_ix = start_subparse(FALSE, 0);

        CvIsMETHOD_on(PL_compcv);

        /* We don't want to make `$self` visible during the expression but we
         * still need to give it a name. Make it unusable from pure perl
         */
        PADOFFSET padix = pad_add_name_pvs("$(self)", 0, NULL, NULL);
        assert(padix == PADIX_SELF);

        padix = pad_add_name_pvs("%(params)", 0, NULL, NULL);
        assert(padix == PADIX_PARAMS);

        PERL_UNUSED_VAR(padix);

        Newx(aux->xhv_class_suspended_initfields_compcv, 1, struct suspended_compcv);
        suspend_compcv(aux->xhv_class_suspended_initfields_compcv);

        LEAVE_SCOPE(floor_ix);
    }
}

#define split_package_ver(value, pkgname, pkgversion)  S_split_package_ver(aTHX_ value, pkgname, pkgversion)
static const char *S_split_package_ver(pTHX_ SV *value, SV *pkgname, SV *pkgversion)
{
    const char *start = SvPVX(value),
               *p     = start,
               *end   = start + SvCUR(value);

    while(*p && !isSPACE_utf8_safe(p, end))
        p += UTF8SKIP(p);

    sv_setpvn(pkgname, start, p - start);
    if(SvUTF8(value))
        SvUTF8_on(pkgname);

    Size_t advance;
    while(*p && (advance = isSPACE_utf8_safe(p, end)))
        p += advance;

    if(*p) {
        /* scan_version() gets upset about trailing content. We need to extract
         * exactly what it wants
         */
        start = p;
        if(*p == 'v')
            p++;
        while(*p && strchr("0123456789._", *p))
            p++;
        SV *tmpsv = newSVpvn(start, p - start);
        SAVEFREESV(tmpsv);

        scan_version(SvPVX(tmpsv), pkgversion, FALSE);
    }

    while(*p && (advance = isSPACE_utf8_safe(p, end)))
        p += advance;

    return p;
}

#define ensure_module_version(module, version)  S_ensure_module_version(aTHX_ module, version)
static void S_ensure_module_version(pTHX_ SV *module, SV *version)
{
    ENTER;

    PUSHMARK(PL_stack_sp);
    rpp_xpush_2(module, version);
    call_method("VERSION", G_VOID);

    LEAVE;
}

void
Perl_apply_attribute_isa(pTHX_
        struct PerlAttributeTarget *target,
        SV *attrvalue, void *data)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTE_ISA;
    PERL_UNUSED_ARG(data);

    HV *stash = attrtarget_class(target, "isa");
    struct xpvhv_aux *aux = HvAUX(stash);

    /* Parse `value` into name + version */
    SV *superclassname = sv_newmortal(), *superclassver = sv_newmortal();
    const char *end = split_package_ver(attrvalue, superclassname, superclassver);
    if(*end)
        croak("Unexpected characters while parsing class :isa attribute: %s", end);

    if(aux->xhv_class_superclass)
        croak("Class already has a superclass, cannot add another");

    HV *superstash = gv_stashsv(superclassname, 0);
    if (!superstash || !HvSTASH_IS_CLASS(superstash)) {
        /* Try to `require` the module then attempt a second time */
        load_module(PERL_LOADMOD_NOIMPORT, newSVsv(superclassname), NULL, NULL);
        superstash = gv_stashsv(superclassname, 0);
    }
    if(!superstash || !HvSTASH_IS_CLASS(superstash))
        croak("Class :isa attribute requires a class but %" SVf_QUOTEDPREFIX " is not one",
            superclassname);

    if(superclassver && SvOK(superclassver))
        ensure_module_version(superclassname, superclassver);

    /* TODO: Suuuurely there's a way to fetch this neatly with stash + "ISA"
     * You'd think that GvAV() of hv_fetchs() would do it, but no, because it
     * won't lazily create a proper (magical) GV if one didn't already exist.
     */
    {
        SV *isaname = newSVpvf("%" HEKf "::ISA", HvNAME_HEK(stash));
        sv_2mortal(isaname);

        AV *isa = get_av(SvPV_nolen(isaname), GV_ADD | (SvFLAGS(isaname) & SVf_UTF8));

        ENTER;

        /* Temporarily remove the SVf_READONLY flag */
        SAVESETSVFLAGS((SV *)isa, SVf_READONLY|SVf_PROTECT, SVf_READONLY|SVf_PROTECT);
        SvREADONLY_off((SV *)isa);

        av_push(isa, newSVsv(superclassname));

        LEAVE;
    }

    aux->xhv_class_superclass = (HV *)SvREFCNT_inc(superstash);

    struct xpvhv_aux *superaux = HvAUX(superstash);

    aux->xhv_class_next_fieldix = superaux->xhv_class_next_fieldix;

    if(superaux->xhv_class_adjust_blocks) {
        if(!aux->xhv_class_adjust_blocks)
            aux->xhv_class_adjust_blocks = newAV();

        for(SSize_t i = 0; i <= AvFILL(superaux->xhv_class_adjust_blocks); i++)
            av_push(aux->xhv_class_adjust_blocks, AvARRAY(superaux->xhv_class_adjust_blocks)[i]);
    }

    if(superaux->xhv_class_param_map) {
        aux->xhv_class_param_map = newHVhv(superaux->xhv_class_param_map);
    }
}

/*

Called when a compilation failure occurs when defining a class.

Returns the given stash to a clean state, as if none of the class has
been defined so a new attempt can be made.

*/

static void
S_class_cleanup_definition(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_CLASS_CLEANUP_DEFINITION;

    struct xpvhv_aux *aux = HvAUX(stash);

    SvREFCNT_dec(aux->xhv_class_superclass);
    aux->xhv_class_superclass = NULL;

    /* clean up adjust blocks */
    SvREFCNT_dec(aux->xhv_class_adjust_blocks);
    aux->xhv_class_adjust_blocks = NULL;

    /* name to slot index */
    SvREFCNT_dec(aux->xhv_class_param_map);
    aux->xhv_class_param_map = NULL;

    SvREFCNT_dec(aux->xhv_class_subclasses_pending_seal);
    aux->xhv_class_subclasses_pending_seal = NULL;

    /* need to release the saved initializer ops in the context
       of the CV any pad entries were created in */
    resume_compcv_final(aux->xhv_class_suspended_initfields_compcv);

    /* clean up the ops for defaults for fields, if any, since
       padname_free() doesn't.
    */
    PADNAMELIST *fieldnames = aux->xhv_class_fields;
    if (fieldnames) {
        for(SSize_t i = PadnamelistMAX(fieldnames); i >= 0 ; i--) {
            PADNAME *pn = PadnamelistARRAY(fieldnames)[i];
            op_free(PadnameFIELDINFO(pn)->defop);
            PadnameFIELDINFO(pn)->defop = NULL;
        }
        PadnamelistREFCNT_dec(fieldnames);
        aux->xhv_class_fields = NULL;
    }

    /* clean up methods */
    /* should we keep a separate list of these instead? */
    if (hv_iterinit(stash)) {
        HE *he;
        while ((he = hv_iternext(stash)) != NULL) {
            STRLEN klen;
            const char * const kpv = HePV(he, klen);
            SV *entry = HeVAL(he);
            CV *cv = NULL;
            if (SvTYPE(entry) == SVt_PVGV
                && (cv = GvCV((GV*)entry))
                && (CvIsMETHOD(cv) || memEQs(kpv, klen, "new"))) {
                SvREFCNT_dec_NN(cv);
                GvCV_set((GV*)entry, NULL);
            }
            else if (SvTYPE(entry) == SVt_PVCV
                     && (CvIsMETHOD((CV*)entry) || memEQs(kpv, klen, "new"))) {
                (void)hv_delete(stash, kpv, HeUTF8(he) ? -(I32)klen : (I32)klen,
                                G_DISCARD);
            }
        }
        ++PL_sub_generation;
    }

    /* field clean up */
    SvREFCNT_dec(PL_compcv);
    Safefree(aux->xhv_class_suspended_initfields_compcv);
    aux->xhv_class_suspended_initfields_compcv = NULL;

    /* remove any ISA entries */
    SV *isaname = sv_2mortal(newSVpvf("%" HEKf "::ISA", HvNAME_HEK(stash)));

    AV *isa = get_av(SvPV_nolen(isaname), (SvFLAGS(isaname) & SVf_UTF8));
    if (isa) {
        /* we make this read-only above since class-keyword
           classes manage ISA themselves, the class has failed to
           load, so we no longer manage it.
        */
        SvREADONLY_off((SV *)isa);
        av_clear(isa);
    }

    /* no longer a class */
    aux->xhv_aux_flags &= ~HvAUXf_IS_CLASS;
}

void
Perl_class_seal_stash(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_CLASS_SEAL_STASH;

    assert(HvSTASH_IS_CLASS(stash));

    if (PL_parser->error_count) {
        /* we had errors, clean up */
        class_cleanup_definition(stash);
        return;
    }

    if(HvCLASS_IS_SEALED(stash))
        /* idempotent */
        return;

    struct xpvhv_aux *aux = HvAUX(stash);
    struct xpvhv_aux *superaux = NULL;

    if(aux->xhv_class_superclass) {
        HV *superstash = aux->xhv_class_superclass;
        assert(HvSTASH_IS_CLASS(superstash));
        superaux = HvAUX(superstash);

        if(!HvCLASS_IS_SEALED(superstash)) {
            if(!superaux->xhv_class_subclasses_pending_seal)
                superaux->xhv_class_subclasses_pending_seal = newAV();
            /* tut tut this will be an AV whose elements are HV *s directly.
             * That's fine. perl code won't ever see this array so there's no
             * point us wrapping them in newRV_inc()s
             */
            av_push(superaux->xhv_class_subclasses_pending_seal, SvREFCNT_inc((SV *)stash));
            return;
        }
    }

    /* generate initfields CV */
    I32 floor_ix = PL_savestack_ix;
    SAVEI32(PL_subline);
    save_item(PL_subname);

    resume_compcv_final(aux->xhv_class_suspended_initfields_compcv);

    /* Some OP_INITFIELD ops will need to populate the pad with their
     * result because later ops will rely on it. There's no need to do
     * this for every op though. Store a mapping to work out which ones
     * we'll need.
     */
    PADNAMELIST *pnl = PadlistNAMES(CvPADLIST(PL_compcv));
    HV *fieldix_to_padix = newHV();
    SAVEFREESV((SV *)fieldix_to_padix);

    /* padix 0 == @_; padix 1 == $self. Start at 2 */
    for(PADOFFSET padix = 2; padix <= PadnamelistMAX(pnl); padix++) {
        PADNAME *pn = PadnamelistARRAY(pnl)[padix];
        if(!pn || !PadnameIsFIELD(pn))
            continue;

        U32 fieldix = PadnameFIELDINFO(pn)->fieldix;
        (void)hv_store_ent(fieldix_to_padix, sv_2mortal(newSVuv(fieldix)), newSVuv(padix), 0);
    }

    OP *ops = NULL;

    ops = op_append_list(OP_LINESEQ, ops,
         newUNOP_AUX(OP_METHSTART, OPpINITFIELDS << 8, NULL, NULL));

    if(superaux) {
        assert(superaux->xhv_class_initfields_cv);
        /* Build an OP_ENTERSUB */
        OP *o = newLISTOPn(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED,
            newPADxVOP(OP_PADSV, 0, PADIX_SELF),
            newPADxVOP(OP_PADHV, OPf_REF, PADIX_PARAMS),
            /* TODO: This won't work at all well under `use threads` because
             * it embeds the CV * to the superclass initfields CV right into
             * the optree. Maybe we'll have to pop it in the pad or something
             */
            newSVOP(OP_CONST, 0, (SV *)superaux->xhv_class_initfields_cv),
            NULL);

        ops = op_append_list(OP_LINESEQ, ops, o);
    }

    PADNAMELIST *fieldnames = aux->xhv_class_fields;

    for(SSize_t i = 0; fieldnames && i <= PadnamelistMAX(fieldnames); i++) {
        PADNAME *pn = PadnamelistARRAY(fieldnames)[i];
        char sigil = PadnamePV(pn)[0];
        PADOFFSET fieldix = PadnameFIELDINFO(pn)->fieldix;

        /* Extract the OP_{NEXT,DB}STATE op from the defop so we can
         * splice it in
         */
        OP *valop = PadnameFIELDINFO(pn)->defop;
        if(valop && valop->op_type == OP_LINESEQ) {
            OP *o = cLISTOPx(valop)->op_first;
            cLISTOPx(valop)->op_first = NULL;
            cLISTOPx(valop)->op_last = NULL;
            /* have to clear the OPf_KIDS flag or op_free() will get upset */
            valop->op_flags &= ~OPf_KIDS;
            op_free(valop);

            OP *fieldcop = o;
            assert(fieldcop->op_type == OP_NEXTSTATE || fieldcop->op_type == OP_DBSTATE);
            o = OpSIBLING(o);
            OpLASTSIB_set(fieldcop, NULL);

            valop = o;
            OpLASTSIB_set(valop, NULL);

            ops = op_append_list(OP_LINESEQ, ops, fieldcop);
        }

        SV *paramname = PadnameFIELDINFO(pn)->paramname;

        U8 op_priv = 0;
        switch(sigil) {
        case '$':
            if(paramname) {
                if(!valop) {
                    SV *message =
                        newSVpvf("Required parameter '%" SVf "' is missing for "
                                 "%" HvNAMEf_QUOTEDPREFIX " constructor",
                                 SVfARG(paramname), HvNAMEfARG(stash));
                    valop = newLISTOPn(OP_DIE, 0,
                                       newSVOP(OP_CONST, 0, message),
                                       NULL);
                }

                OP *helemop =
                    newBINOP(OP_HELEM, 0,
                             newPADxVOP(OP_PADHV, OPf_REF, PADIX_PARAMS),
                             newSVOP(OP_CONST, 0, SvREFCNT_inc(paramname)));

                if(PadnameFIELDINFO(pn)->def_if_undef) {
                    /* delete $params{$paramname} // DEFOP */
                    valop = newLOGOP(OP_DOR, 0,
                                     newUNOP(OP_DELETE, 0, helemop), valop);
                }
                else if(PadnameFIELDINFO(pn)->def_if_false) {
                    /* delete $params{$paramname} || DEFOP */
                    valop = newLOGOP(OP_OR, 0,
                                     newUNOP(OP_DELETE, 0, helemop), valop);
                }
                else {
                    /* exists $params{$paramname} ? delete $params{$paramname} : DEFOP */
                    /* more efficient with the new OP_HELEMEXISTSOR */
                    valop = newLOGOP(OP_HELEMEXISTSOR, OPpHELEMEXISTSOR_DELETE << 8,
                                     helemop, valop);
                }

                valop = op_contextualize(valop, G_SCALAR);
            }
            break;

        case '@':
            op_priv = OPpINITFIELD_AV;
            break;

        case '%':
            op_priv = OPpINITFIELD_HV;
            break;

        default:
            NOT_REACHED;
        }

        UNOP_AUX_item *aux;
        aux = (UNOP_AUX_item *)PerlMemShared_malloc(sizeof(UNOP_AUX_item) * 2);

        aux[0].uv = fieldix;

        OP *fieldop = newUNOP_AUX(OP_INITFIELD, valop ? OPf_STACKED : 0, valop, aux);
        fieldop->op_private = op_priv;

        HE *he;
        if((he = hv_fetch_ent(fieldix_to_padix, sv_2mortal(newSVuv(fieldix)), 0, 0)) &&
           SvOK(HeVAL(he))) {
            fieldop->op_targ = SvUV(HeVAL(he));
        }

        ops = op_append_list(OP_LINESEQ, ops, fieldop);
    }

    /* initfields CV should not get class_wrap_method_body() called on its
     * body. pretend it isn't a method for now */
    CvIsMETHOD_off(PL_compcv);
    CV *initfields = newATTRSUB(floor_ix, NULL, NULL, NULL, ops);
    CvIsMETHOD_on(initfields);

    aux->xhv_class_initfields_cv = initfields;

    aux->xhv_class_flags |= HvCLASSf_SEALED;

    if(aux->xhv_class_subclasses_pending_seal) {
        AV *subclasses = aux->xhv_class_subclasses_pending_seal;
        for (UV idx = 0; idx < av_count(subclasses); idx++)
            class_seal_stash((HV *)AvARRAY(subclasses)[idx]);

        SvREFCNT_dec(subclasses);
        aux->xhv_class_subclasses_pending_seal = NULL;
    }
}

void
Perl_class_prepare_initfield_parse(pTHX)
{
    PERL_ARGS_ASSERT_CLASS_PREPARE_INITFIELD_PARSE;

    assert(HvSTASH_IS_CLASS(PL_curstash));
    struct xpvhv_aux *aux = HvAUX(PL_curstash);

    resume_compcv_and_save(aux->xhv_class_suspended_initfields_compcv);
    CvOUTSIDE_SEQ(PL_compcv) = PL_cop_seqmax;
}

void
Perl_class_prepare_method_parse(pTHX_ CV *cv)
{
    PERL_ARGS_ASSERT_CLASS_PREPARE_METHOD_PARSE;

    assert(cv == PL_compcv);
    assert(HvSTASH_IS_CLASS(PL_curstash));

    /* We expect this to be at the start of sub parsing, so there won't be
     * anything in the pad yet
     */
    assert(PL_comppad_name_fill == 0);

    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    assert(padix == PADIX_SELF);
    PERL_UNUSED_VAR(padix);

    intro_my();

    CvNOWARN_AMBIGUOUS_on(cv);
    CvIsMETHOD_on(cv);
}

#define find_op_methstart(o)  S_find_op_methstart(aTHX_ o)
static OP *
S_find_op_methstart(pTHX_ OP *o)
{
    if(o->op_type == OP_METHSTART)
        return o;

    if(!(o->op_flags & OPf_KIDS))
        return NULL;

    for(OP *kid = cUNOPo->op_first; kid; kid = OpSIBLING(kid)) {
        OP *methstart = find_op_methstart(kid);
        if(methstart)
            return methstart;
    }

    return NULL;
}

OP *
Perl_class_wrap_method_body(pTHX_ OP *o)
{
    PERL_ARGS_ASSERT_CLASS_WRAP_METHOD_BODY;

    if(!o)
        return o;

    /* Walk the pad of this CV looking for lexicals with field info. These
     * will be the fields used by this particular method, which we build into
     * a list for the OP_METHSTART op. This ensures we only set up the fields
     * needed by this particular method body, rather than every available
     * field in the whole class
     */

    PADNAMELIST *pnl = PadlistNAMES(CvPADLIST(PL_compcv));

    AV *fieldmap = newAV();
    UV max_fieldix = 0;
    SAVEFREESV((SV *)fieldmap);

    /* padix 0 == @_; padix 1 == $self. Start at 2 */
    for(PADOFFSET padix = 2; padix <= PadnamelistMAX(pnl); padix++) {
        PADNAME *pn = PadnamelistARRAY(pnl)[padix];
        if(!pn || !PadnameIsFIELD(pn))
            continue;

        U32 fieldix = PadnameFIELDINFO(pn)->fieldix;
        if(fieldix > max_fieldix)
            max_fieldix = fieldix;

        av_push_simple(fieldmap, newSVuv(padix));
        av_push_simple(fieldmap, newSVuv(fieldix));
    }

    UNOP_AUX_item *aux = NULL;

    if(av_count(fieldmap)) {
        aux = (UNOP_AUX_item *)PerlMemShared_malloc(
                                    sizeof(UNOP_AUX_item)
                                    *  (2 + av_count(fieldmap))
                                );

        UNOP_AUX_item *ap = aux;

        (ap++)->uv = av_count(fieldmap) / 2;
        (ap++)->uv = max_fieldix;

        for(Size_t i = 0; i < av_count(fieldmap); i++)
            (ap++)->uv = SvUV(AvARRAY(fieldmap)[i]);
    }

    /* If this is an empty method body then o will be an OP_STUB and not a
     * list. This will confuse op_sibling_splice() */
    if(o->op_type != OP_LINESEQ)
        o = newLISTOP(OP_LINESEQ, 0, o, NULL);

    if(CvSIGNATURE(PL_compcv)) {
        /* A signatured method has already injected the OP_METHSTART; we just
         * have to find it and attach the aux structure to it
         */
        OP *methstartop = find_op_methstart(o);
        assert(methstartop);
        assert(!cUNOP_AUXx(methstartop)->op_aux);

        cUNOP_AUXx(methstartop)->op_aux = aux;
    }
    else
        op_sibling_splice(o, NULL, 0, newUNOP_AUX(OP_METHSTART, 0, NULL, aux));

    return o;
}

void
Perl_class_add_field(pTHX_ HV *stash, PADNAME *pn)
{
    PERL_ARGS_ASSERT_CLASS_ADD_FIELD;

    assert(HvSTASH_IS_CLASS(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    PADOFFSET fieldix = aux->xhv_class_next_fieldix;
    aux->xhv_class_next_fieldix++;

    struct padname_fieldinfo *fieldinfo;
    Newxz(fieldinfo, 1, struct padname_fieldinfo);

    fieldinfo->refcount = 1;
    fieldinfo->fieldix = fieldix;
    fieldinfo->fieldstash = HvREFCNT_inc(stash);

    PadnameFIELDINFO(pn) = fieldinfo;
    PadnameFLAGS(pn) |= PADNAMEf_FIELD;

    if(!aux->xhv_class_fields)
        aux->xhv_class_fields = newPADNAMELIST(0);

    padnamelist_store(aux->xhv_class_fields, PadnamelistMAX(aux->xhv_class_fields)+1, pn);
    PadnameREFCNT_inc(pn);
}

/* Adds a pad entry to PL_compcv to make the given field visible. This works
 * even before the field has been properly `intro_my()`'ed and is thus usable
 * during attributes declared on the same newly-field.
 */

#define pad_import_field(fieldpn)  S_pad_import_field(aTHX_ fieldpn)
static PADOFFSET
S_pad_import_field(pTHX_ PADNAME *fieldpn)
{
    assert(PadnameIsFIELD(fieldpn));

    /* We can't just pad_findmy_pvn() because the actual field may not have been
     * intro_my()'ed yet */
    PADNAME *name = newPADNAMEouter(fieldpn);
    PADOFFSET padix = pad_alloc(OP_PADSV, SVs_PADMY|padalloc_NO_SV);
    padnamelist_store(PL_comppad_name, padix, name);

    return padix;
}

static void
padname_skip_underscore(const PADNAME *pn, const char **pname, STRLEN *plen) {
    /* skip sigil */
    const char *name = PadnamePV(pn) + 1;
    STRLEN len = PadnameLEN(pn) - 1;
    if (len > 0 && *name == '_') {
        name++;
        len--;
    }
    *pname = name;
    *plen = len;
}

void
Perl_apply_attribute_param(pTHX_ struct PerlAttributeTarget *target, SV *value, void *data)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTE_PARAM;
    PERL_UNUSED_ARG(data);

    PADNAME *pn = attrtarget_padname(target, "param");

    if(!value) {
        /* Default to name minus the sigil (and one underscore if present) */
        const char *name;
        STRLEN len;
        padname_skip_underscore(pn, &name, &len);
        value = newSVpvn_utf8(name, len, PadnameUTF8(pn));
    }

    if(PadnamePV(pn)[0] != '$')
        croak("Only scalar fields can take a :param attribute");

    if(PadnameFIELDINFO(pn)->paramname)
        croak("Field already has a parameter name, cannot add another");

    HV *stash = PadnameFIELDINFO(pn)->fieldstash;
    assert(HvSTASH_IS_CLASS(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    if(aux->xhv_class_param_map &&
            hv_exists_ent(aux->xhv_class_param_map, value, 0))
        croak("Cannot assign :param(%" SVf ") to field %" SVf " because that name is already in use",
                SVfARG(value), SVfARG(PadnameSV(pn)));

    PadnameFIELDINFO(pn)->paramname = SvREFCNT_inc(value);

    if(!aux->xhv_class_param_map)
        aux->xhv_class_param_map = newHV();

    (void)hv_store_ent(aux->xhv_class_param_map, value, newSVuv(PadnameFIELDINFO(pn)->fieldix), 0);
}

void
Perl_apply_attribute_reader(pTHX_ struct PerlAttributeTarget *target, SV *value, void *data)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTE_READER;
    PERL_UNUSED_ARG(data);

    PADNAME *pn = attrtarget_padname(target, "reader");

    if(value)
        SvREFCNT_inc(value);
    else {
        /* Default to name minus the sigil (and one underscore if present) */
        const char *name;
        STRLEN len;
        padname_skip_underscore(pn, &name, &len);
        value = newSVpvn_utf8(name, len, PadnameUTF8(pn));
    }

    if(!valid_identifier_sv(value))
        croak("%" SVf_QUOTEDPREFIX " is not a valid name for a generated method", value);

    I32 floor_ix = start_subparse(FALSE, 0);
    SAVEFREESV(PL_compcv);
    CvIsMETHOD_on(PL_compcv);

    I32 save_ix = block_start(TRUE);

    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    assert(padix == PADIX_SELF);

    subsignature_start();
    CvSIGNATURE_on(PL_compcv);

    OP *sigop = subsignature_finish();

    padix = pad_import_field(pn);
    intro_my();

    OP *retop;
    {
        OPCODE optype = 0;
        switch(PadnamePV(pn)[0]) {
            case '$': optype = OP_PADSV; break;
            case '@': optype = OP_PADAV; break;
            case '%': optype = OP_PADHV; break;
            default: NOT_REACHED;
        }

        retop = newLISTOP(OP_RETURN, 0,
            newOP(OP_PUSHMARK, 0),
            newPADxVOP(optype, 0, padix));
    }

    OP *ops = newLISTOPn(OP_LINESEQ, 0,
            sigop,
            retop,
            NULL);

    SvREFCNT_inc(PL_compcv);
    ops = block_end(save_ix, ops);

    OP *nameop = newSVOP(OP_CONST, 0, value);

    CV *cv = newATTRSUB(floor_ix, nameop, NULL, NULL, ops);
    if (cv)
        CvIsMETHOD_on(cv);
}

void
Perl_apply_attribute_writer(pTHX_ struct PerlAttributeTarget *target, SV *value, void *data)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTE_WRITER;
    PERL_UNUSED_ARG(data);

    PADNAME *pn = attrtarget_padname(target, "param");

    char sigil = PadnamePV(pn)[0];
    if(sigil != '$')
        croak("Cannot apply a :writer attribute to a non-scalar field");

    if(value)
        SvREFCNT_inc(value);
    else {
        /* Default to "set_" . name minus the sigil (and one underscore if present) */
        const char *name;
        STRLEN len;
        padname_skip_underscore(pn, &name, &len);
        value = newSVpvs("set_");
        sv_catpvn_flags(value, name, len, PadnameUTF8(pn) ? SV_CATUTF8 : 0);
    }

    if(!valid_identifier_sv(value))
        croak("%" SVf_QUOTEDPREFIX " is not a valid name for a generated method", value);

    I32 floor_ix = start_subparse(FALSE, 0);
    SAVEFREESV(PL_compcv);
    CvIsMETHOD_on(PL_compcv);

    I32 save_ix = block_start(TRUE);

    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    assert(padix == PADIX_SELF);

    subsignature_start();
    CvSIGNATURE_on(PL_compcv);

    /* param pad variable doesn't technically need a name, so don't bother as
     * reusing the field name will provoke a warning */
    PADOFFSET param_padix = padix = pad_add_name_pvn("$", 1, 0, NULL, NULL);
    intro_my();

    subsignature_append_positional(param_padix, 0, NULL);

    OP *sigop = subsignature_finish();

    padix = pad_import_field(pn);
    intro_my();

    OP *assignop = newBINOP(OP_SASSIGN, 0,
            newPADxVOP(OP_PADSV, 0, param_padix),
            newPADxVOP(OP_PADSV, OPf_MOD|OPf_REF, padix));

    OP *retop = newLISTOP(OP_RETURN, 0,
            newOP(OP_PUSHMARK, 0),
            newPADxVOP(OP_PADSV, 0, PADIX_SELF));

    OP *ops = newLISTOPn(OP_LINESEQ, 0,
            sigop,
            assignop,
            retop,
            NULL);

    SvREFCNT_inc(PL_compcv);
    ops = block_end(save_ix, ops);

    OP *nameop = newSVOP(OP_CONST, 0, value);

    CV *cv = newATTRSUB(floor_ix, nameop, NULL, NULL, ops);
    if (cv)
        CvIsMETHOD_on(cv);
}

void
Perl_class_set_field_defop(pTHX_ PADNAME *pn, OPCODE defmode, OP *defop)
{
    PERL_ARGS_ASSERT_CLASS_SET_FIELD_DEFOP;

    assert(defmode == 0 || defmode == OP_ORASSIGN || defmode == OP_DORASSIGN);

    assert(HvSTASH_IS_CLASS(PL_curstash));

    op_free(PadnameFIELDINFO(pn)->defop);

    /* set here to ensure clean up if forbid_outofblock_ops() throws */
    PadnameFIELDINFO(pn)->defop = defop;

    forbid_outofblock_ops(defop, "field initialiser expression");

    char sigil = PadnamePV(pn)[0];
    switch(sigil) {
        case '$':
            defop = op_contextualize(defop, G_SCALAR);
            break;

        case '@':
        case '%':
            defop = op_contextualize(op_force_list(defop), G_LIST);
            break;
    }

    PadnameFIELDINFO(pn)->defop = newLISTOP(OP_LINESEQ, 0,
        newSTATEOP(0, NULL, NULL), defop);
    switch(defmode) {
        case OP_DORASSIGN:
            PadnameFIELDINFO(pn)->def_if_undef = true;
            break;
        case OP_ORASSIGN:
            PadnameFIELDINFO(pn)->def_if_false = true;
            break;
    }
}

void
Perl_class_add_ADJUST(pTHX_ HV *stash, CV *cv)
{
    PERL_ARGS_ASSERT_CLASS_ADD_ADJUST;

    assert(HvSTASH_IS_CLASS(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    if(!aux->xhv_class_adjust_blocks)
        aux->xhv_class_adjust_blocks = newAV();

    av_push(aux->xhv_class_adjust_blocks, (SV *)cv);
}

OP *
Perl_ck_classname(pTHX_ OP *o)
{
    PERL_ARGS_ASSERT_CK_CLASSNAME;

    if(!CvIsMETHOD(PL_compcv))
        croak("Cannot use __CLASS__ outside of a method or field initializer expression");

    return o;
}

PP(pp_classname)
{
    dTARGET;

    SV *self = PAD_SVl(PADIX_SELF);
    assert(SvTYPE(SvRV(self)) == SVt_PVOBJ);

    rpp_xpush_1(TARG);
    sv_ref(TARG, SvRV(self), true);

    return NORMAL;
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
