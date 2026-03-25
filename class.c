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
#include "class.h"

enum {
    PADIX_SELF        = 1,
    PADIX_PARAMS      = 2,
    PADIX_ROLE_OFFSET = 3,
};

/* Forward declarations */
static OP *S_find_op_methstart(pTHX_ OP *o);
#define find_op_methstart(o)  S_find_op_methstart(aTHX_ o)
static AV *S_class_compose_roles(pTHX_ HV *stash);
#define class_compose_roles(stash)  S_class_compose_roles(aTHX_ stash)

/* Clone a role CV and store a fieldix offset in its pad for composition.
 * The clone gets its own padlist (via cv_clone) and shares the optree
 * (via OpREFCNT). The offset is stored in pad slot PADIX_ROLE_OFFSET,
 * read by pp_methstart and pp_initfield at runtime. */
static CV *
S_cv_clone_with_field_offset(pTHX_ CV *proto, PADOFFSET offset)
{
    CV *cv = cv_clone(proto);
    PAD *pad1 = PadlistARRAY(CvPADLIST(cv))[1];
    sv_setuv(PadARRAY(pad1)[PADIX_ROLE_OFFSET], offset);
    return cv;
}
#define cv_clone_with_field_offset(proto, offset) \
    S_cv_clone_with_field_offset(aTHX_ proto, offset)

void
Perl_croak_kw_unless_class(pTHX_ const char *kw)
{
    PERL_ARGS_ASSERT_CROAK_KW_UNLESS_CLASS;

    if(!HvSTASH_IS_CLASS_OR_ROLE(PL_curstash))
        croak("Cannot '%s' outside of a 'class' or 'role'", kw);
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

    /* Apply per-CV fieldix offset from role composition.
     * Cloned role CVs have the offset stored in pad slot PADIX_ROLE_OFFSET.
     * For non-role CVs this slot is undef (SvIOK false), so the check is
     * a single flag test — no magic walk needed. */
    {
        SV *offset_sv = PAD_SVl(PADIX_ROLE_OFFSET);
        if(UNLIKELY(SvIOK(offset_sv)))
            fieldix += SvUVX(offset_sv);
    }

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

/* Check if a class/role stash composes a given role (directly or transitively).
 * Also walks the superclass chain. */
static bool
S_class_does_role(pTHX_ HV *stash, HV *rolestash)
{
    if(!stash || !rolestash)
        return FALSE;

    /* Walk the class hierarchy */
    while(stash) {
        if(HvSTASH_IS_CLASS_OR_ROLE(stash)) {
            struct xpvhv_aux *aux = HvAUX(stash);
            if(aux->xhv_class_roles) {
                for(SSize_t i = 0; i <= AvFILL(aux->xhv_class_roles); i++) {
                    if((HV *)AvARRAY(aux->xhv_class_roles)[i] == rolestash)
                        return TRUE;
                }
            }
            stash = aux->xhv_class_superclass;
        }
        else
            break;
    }
    return FALSE;
}
#define class_does_role(stash, rolestash) S_class_does_role(aTHX_ stash, rolestash)

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
        !sv_derived_from_hv(self, CvSTASH(curcv)) &&
        /* For role methods, check if the instance's class composes the role */
        !(HvSTASH_IS_ROLE(CvSTASH(curcv)) && class_does_role(SvSTASH(rv), CvSTASH(curcv))))
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

        /* Check for a per-CV fieldix offset (set during role composition).
         * Role methods carry role-local field indices in their OP_METHSTART
         * aux; when composed into a class with existing fields, the indices
         * need to be offset. The offset is stored in pad slot
         * PADIX_ROLE_OFFSET. For non-role CVs, the slot is undef (SvIOK
         * false), so this is a single flag test. */
        PADOFFSET fieldix_offset = 0;
        {
            SV *offset_sv = PAD_SVl(PADIX_ROLE_OFFSET);
            if(UNLIKELY(SvIOK(offset_sv)))
                fieldix_offset = SvUVX(offset_sv);
        }
        U32 fieldcount = (aux++)->uv;
        U32 max_fieldix = (aux++)->uv + fieldix_offset;

        assert((U32)(ObjectMAXFIELD(instance)+1) > max_fieldix);
        PERL_UNUSED_VAR(max_fieldix);

        for(Size_t i = 0; i < fieldcount; i++) {
            PADOFFSET padix   = (aux++)->uv;
            U32       fieldix = (aux++)->uv + fieldix_offset;

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

static void
invoke_role_seal(pTHX_ void *arg_)
{
    role_seal_stash((HV *)arg_);
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
        SV *newname = Perl_newSVpvf(aTHX_ "%s::new", classname);
        SAVEFREESV(newname);

        CV *newcv = newXS_flags(SvPV_nolen(newname), injected_constructor, __FILE__, NULL, nameflags);
        CvSTASH_set(newcv, stash);
    }

    /* TODO:
     *   DOES method
     */

    struct xpvhv_aux *aux = HvAUX(stash);
    aux->xhv_class_superclass         = NULL;
    aux->xhv_class_initfields_cv      = NULL;
    aux->xhv_class_adjust_blocks      = NULL;
    aux->xhv_class_fields             = NULL;
    aux->xhv_class_next_fieldix       = 0;
    aux->xhv_class_param_map          = NULL;
    aux->xhv_class_pending_method_cvs = NULL;
    aux->xhv_class_pending_roles      = NULL;
    aux->xhv_class_roles              = NULL;
    aux->xhv_class_proto_role         = proto_role_new(stash);

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

        padix = pad_add_name_pvs("$(role_offset)", 0, NULL, NULL);
        assert(padix == PADIX_ROLE_OFFSET);

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

#define split_attr_nameval(sv, namp, valp)  S_split_attr_nameval(aTHX_ sv, namp, valp)
static void S_split_attr_nameval(pTHX_ SV *sv, SV **namp, SV **valp)
{
    STRLEN svlen = SvCUR(sv);
    U32 do_utf8 = SvUTF8(sv) ? SVf_UTF8 : 0;

    const char *paren_at = (const char *)memchr(SvPVX(sv), '(', svlen);
    if(paren_at) {
        STRLEN namelen = paren_at - SvPVX(sv);

        if(SvPVX(sv)[svlen-1] != ')')
            /* Should be impossible to reach this by parsing regular perl code
             * by as class_apply_attributes() is XS-visible API it might still
             * be reachable. As it's likely unreachable by normal perl code,
             * don't bother listing it in perldiag.
             */
            /* diag_listed_as: SKIPME */
            croak("Malformed attribute string");
        *namp = newSVpvn_flags(SvPVX(sv), namelen, SVs_TEMP|do_utf8);

        const char *value_at = paren_at + 1;
        const char *value_max = SvPVX(sv) + svlen - 2;

        /* TODO: We're only obeying ASCII whitespace here */

        /* Trim whitespace at the start */
        while(value_at < value_max && isSPACE(*value_at))
            value_at += 1;
        while(value_max > value_at && isSPACE(*value_max))
            value_max -= 1;

        if(value_max >= value_at)
            *valp = newSVpvn_flags(value_at, value_max - value_at + 1, SVs_TEMP|do_utf8);
        else
            *valp = NULL;
    }
    else {
        *namp = sv;
        *valp = NULL;
    }
}

static void
apply_class_attribute_isa(pTHX_ HV *stash, SV *value)
{
    if(HvSTASH_IS_ROLE(stash))
        croak("Roles cannot use :isa");

    assert(HvSTASH_IS_CLASS(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    /* Parse `value` into name + version */
    SV *superclassname = sv_newmortal(), *superclassver = sv_newmortal();
    const char *end = split_package_ver(value, superclassname, superclassver);
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
        /* TODO: This would be a useful feature addition */
        croak("Class :isa attribute requires a class but %" SVf_QUOTEDPREFIX " is not one",
            SVfARG(superclassname));

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

        av_push(isa, newSVsv(value));

        LEAVE;
    }

    aux->xhv_class_superclass = (HV *)SvREFCNT_inc(superstash);

    struct xpvhv_aux *superaux = HvAUX(superstash);

    /* Don't copy next_fieldix from the parent here. Field indices are now
     * assigned as class-relative values during parsing and resolved to
     * absolute indices at seal time. The base offset from the superclass
     * will be applied during class_seal_stash().
     */

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

static void
S_apply_one_role(pTHX_ struct xpvhv_aux *aux, SV *namesv)
{
    SV *rolename = sv_newmortal(), *rolever = sv_newmortal();
    const char *end = split_package_ver(namesv, rolename, rolever);
    if(*end)
        croak("Unexpected characters while parsing :does attribute: %s", end);

    HV *rolestash = gv_stashsv(rolename, 0);
    if (!rolestash) {
        load_module(PERL_LOADMOD_NOIMPORT, newSVsv(rolename), NULL, NULL);
        rolestash = gv_stashsv(rolename, 0);
    }
    if(!rolestash || !HvSTASH_IS_ROLE(rolestash))
        croak(":does attribute requires a role but %" HvNAMEf_QUOTEDPREFIX " is not one",
            rolestash ? HvNAMEfARG(rolestash) : "\"(unknown)\"");

    if(rolever && SvOK(rolever))
        ensure_module_version(rolename, rolever);

    if(!aux->xhv_class_pending_roles)
        aux->xhv_class_pending_roles = newAV();

    av_push(aux->xhv_class_pending_roles, SvREFCNT_inc((SV *)rolestash));
}

static void
apply_class_attribute_does(pTHX_ HV *stash, SV *value)
{
    assert(HvSTASH_IS_CLASS_OR_ROLE(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    /* Support comma-separated list: :does(R1, R2, R3) */
    const char *p   = SvPVX(value);
    const char *end = p + SvCUR(value);

    while(p < end) {
        /* skip leading whitespace and commas */
        while(p < end && (*p == ',' || isSPACE(*p)))
            p++;
        if(p >= end)
            break;

        /* find end of this entry (up to comma or end) */
        const char *start = p;
        while(p < end && *p != ',')
            p++;

        /* trim trailing whitespace */
        const char *entry_end = p;
        while(entry_end > start && isSPACE(*(entry_end - 1)))
            entry_end--;

        if(entry_end > start) {
            SV *entry = newSVpvn_flags(start, entry_end - start,
                                       SvUTF8(value) ? SVf_UTF8 : 0);
            sv_2mortal(entry);
            S_apply_one_role(aTHX_ aux, entry);
        }
    }
}

static struct {
    const char *name;
    bool requires_value;
    void (*apply)(pTHX_ HV *stash, SV *value);
} const class_attributes[] = {
    { .name           = "isa",
      .requires_value = true,
      .apply          = &apply_class_attribute_isa,
    },
    { .name           = "does",
      .requires_value = true,
      .apply          = &apply_class_attribute_does,
    },
    { NULL, false, NULL }
};

static void
S_class_apply_attribute(pTHX_ HV *stash, OP *attr)
{
    assert(attr->op_type == OP_CONST);

    SV *name, *value;
    split_attr_nameval(cSVOPx_sv(attr), &name, &value);

    for(int i = 0; class_attributes[i].name; i++) {
        /* TODO: These attribute names are not UTF-8 aware */
        if(!strEQ(SvPVX(name), class_attributes[i].name))
            continue;

        if(class_attributes[i].requires_value && !(value && SvOK(value)))
            croak("Class attribute %" SVf " requires a value", SVfARG(name));

        (*class_attributes[i].apply)(aTHX_ stash, value);
        return;
    }

    croak("Unrecognized class attribute %" SVf, SVfARG(name));
}

void
Perl_class_apply_attributes(pTHX_ HV *stash, OP *attrlist)
{
    PERL_ARGS_ASSERT_CLASS_APPLY_ATTRIBUTES;

    if(!attrlist)
        return;
    if(attrlist->op_type == OP_NULL) {
        op_free(attrlist);
        return;
    }

    if(attrlist->op_type == OP_LIST) {
        OP *o = cLISTOPx(attrlist)->op_first;
        assert(o->op_type == OP_PUSHMARK);
        o = OpSIBLING(o);

        for(; o; o = OpSIBLING(o))
            S_class_apply_attribute(aTHX_ stash, o);
    }
    else
        S_class_apply_attribute(aTHX_ stash, attrlist);

    op_free(attrlist);
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

    SvREFCNT_dec(aux->xhv_class_pending_method_cvs);
    aux->xhv_class_pending_method_cvs = NULL;

    /* pending roles */
    SvREFCNT_dec(aux->xhv_class_pending_roles);
    aux->xhv_class_pending_roles = NULL;

    /* composed roles */
    SvREFCNT_dec(aux->xhv_class_roles);
    aux->xhv_class_roles = NULL;

    /* proto-role */
    proto_role_free(aux->xhv_class_proto_role);
    aux->xhv_class_proto_role = NULL;

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
            else if (SvROK(entry)) {
                SV *sv = SvRV(entry);
                if (SvTYPE(sv) == SVt_PVCV
                         && (CvIsMETHOD((CV*)sv) || memEQs(kpv, klen, "new"))) {
                    (void)hv_delete(stash, kpv, HeUTF8(he) ? -(I32)klen : (I32)klen,
                                    G_DISCARD);
                }
            }
        }
        ++PL_sub_generation;
    }

    /* field clean up */
    resume_compcv_final(aux->xhv_class_suspended_initfields_compcv);
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

    /* no longer a class or role */
    aux->xhv_aux_flags &= ~(HvAUXf_IS_CLASS | HvAUXf_IS_ROLE);
}

/* Build the OP_METHSTART field-binding aux for a single method CV.
 * Scans the CV's pad for field PADNAMEs and builds an aux array of
 * (padix, fieldix) pairs. Skips CVs whose OP_METHSTART already has aux.
 */
#define class_seal_method_fieldmap(cv)  S_class_seal_method_fieldmap(aTHX_ cv)
static void
S_class_seal_method_fieldmap(pTHX_ CV *cv)
{
    assert(CvROOT(cv));

    OP *methstartop = find_op_methstart(CvROOT(cv));
    if(!methstartop)
        return;

    /* Already processed (e.g. found via both pending list and stash walk) */
    if(cUNOP_AUXx(methstartop)->op_aux)
        return;

    PADNAMELIST *pnl = PadlistNAMES(CvPADLIST(cv));

    AV *fieldmap = newAV();
    UV max_fieldix = 0;

    /* padix 0 == @_; padix 1 == $self. Start at 2 */
    for(PADOFFSET padix = 2; padix <= PadnamelistMAX(pnl); padix++) {
        PADNAME *pn = PadnamelistARRAY(pnl)[padix];
        if(!pn || !PadnameIsFIELD(pn))
            continue;

        U32 fieldix = PadnameFIELDINFO(pn)->fieldix;
        assert(fieldix != (PADOFFSET)-1); /* must be resolved */

        if(fieldix > max_fieldix)
            max_fieldix = fieldix;

        av_push_simple(fieldmap, newSVuv(padix));
        av_push_simple(fieldmap, newSVuv(fieldix));
    }

    if(av_count(fieldmap)) {
        UNOP_AUX_item *aux = (UNOP_AUX_item *)PerlMemShared_malloc(
            sizeof(UNOP_AUX_item) * (2 + av_count(fieldmap)));

        UNOP_AUX_item *ap = aux;

        (ap++)->uv = av_count(fieldmap) / 2;
        (ap++)->uv = max_fieldix;

        for(Size_t j = 0; j < av_count(fieldmap); j++)
            (ap++)->uv = SvUV(AvARRAY(fieldmap)[j]);

        cUNOP_AUXx(methstartop)->op_aux = aux;
    }

    SvREFCNT_dec_NN((SV *)fieldmap);
}

/* Collect unique role stashes for composition, deduplicating by stash pointer
 * identity (diamond case). We do NOT recurse into transitive roles because
 * each role's seal already composed its own :does roles into its stash.
 * The transitive methods are already present in the intermediate role. */
static void
S_collect_unique_roles(pTHX_ AV *pending, AV *seen, AV *unique)
{
    for(SSize_t i = 0; i <= AvFILL(pending); i++) {
        HV *rolestash = (HV *)AvARRAY(pending)[i];

        /* Check if already seen (diamond dedup) */
        bool found = FALSE;
        for(SSize_t j = 0; j <= AvFILL(seen); j++) {
            if((HV *)AvARRAY(seen)[j] == rolestash) {
                found = TRUE;
                break;
            }
        }
        if(found)
            continue;

        av_push(seen, (SV *)rolestash); /* no refcnt — just tracking pointers */
        av_push(unique, SvREFCNT_inc((SV *)rolestash));
    }
}
#define collect_unique_roles(pending, seen, unique) S_collect_unique_roles(aTHX_ pending, seen, unique)

/* Compose all pending roles into a class/role stash.
 * Called from class_seal_stash / role_seal_stash before Phase 1 (field resolution).
 * For now, this handles methods, required methods, ADJUST blocks, and @ISA.
 * Field composition is handled in Step 5. */
/* Finalize the proto-role's method slots by walking the stash and
 * pending_method_cvs to capture explicit methods and required method stubs.
 * Accessor methods and field slots are already populated during parsing.
 * This must be called before composition begins.
 *
 * Also sorts all slot arrays by name for the merge-join composition. */
static void
S_proto_role_finalize(pTHX_ HV *stash)
{
    struct xpvhv_aux *aux = HvAUX(stash);
    proto_role_t *pr = aux->xhv_class_proto_role;

    if (!pr)
        return;

    /* Walk the stash for named method CVs */
    if (hv_iterinit(stash)) {
        HE *he;
        while ((he = hv_iternext(stash)) != NULL) {
            SV *entry = HeVAL(he);
            CV *cv = NULL;

            if (SvTYPE(entry) == SVt_PVGV && isGV_with_GP(entry))
                cv = GvCV((GV *)entry);
            else if (SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVCV)
                cv = (CV *)SvRV(entry);

            if (!cv || !CvIsMETHOD(cv))
                continue;

            SV *methname = HeSVKEY_force(he);

            /* Skip if already recorded (e.g. accessor from :reader/:writer) */
            bool found = FALSE;
            for (UV i = 0; i < pr->method_count; i++) {
                if (sv_eq(pr->method_slots[i].name, methname)) {
                    found = TRUE;
                    break;
                }
            }
            if (found)
                continue;

            /* Required method stub (no body) or explicit method */
            if (!CvROOT(cv)) {
                /* Required: origins = 0, cv = NULL */
                proto_role_add_method(pr, methname, ORIGIN_SET_EMPTY,
                                     NULL, NULL);
            } else {
                /* Explicit method: from_field = NULL */
                proto_role_add_method(pr, methname, ORIGIN_SET_EMPTY,
                                     cv, NULL);
            }
        }
    }

    /* Sort method slots by name for merge-join composition */
    if (pr->method_count > 1) {
        /* Simple insertion sort — method counts are small (typically <20) */
        for (UV i = 1; i < pr->method_count; i++) {
            method_slot_t tmp = pr->method_slots[i];
            UV j = i;
            while (j > 0 && sv_cmp(pr->method_slots[j-1].name, tmp.name) > 0) {
                pr->method_slots[j] = pr->method_slots[j-1];
                j--;
            }
            pr->method_slots[j] = tmp;
        }
    }

    /* Sort field slots by name for merge-join composition */
    if (pr->field_count > 1) {
        for (UV i = 1; i < pr->field_count; i++) {
            field_slot_t tmp = pr->field_slots[i];
            UV j = i;
            while (j > 0 && sv_cmp(PadnameSV(pr->field_slots[j-1].padname),
                                    PadnameSV(tmp.padname)) > 0) {
                pr->field_slots[j] = pr->field_slots[j-1];
                j--;
            }
            pr->field_slots[j] = tmp;
        }
    }
}
#define proto_role_finalize(stash) S_proto_role_finalize(aTHX_ stash)

/* ========================================================================
 * Proto-Role Composition Pipeline
 *
 * These functions implement the composition algebra from ROLE_ALGEBRA.md.
 * They are the new pipeline that will replace S_class_compose_roles.
 * ======================================================================== */

/* Assign origin IDs (bit positions) to all participating proto-roles.
 * Consumer gets bit 0, then roles get bits 1..N.
 * Also sets the origin bits on each proto-role's own slots. */
static void
S_proto_role_assign_ids(pTHX_ proto_role_t *consumer,
                        proto_role_t **roles, UV role_count,
                        origin_map_t *map)
{
    origin_map_init(map);

    /* Consumer gets bit 0 */
    consumer->origin_id = map->next_id;
    map->stashes[map->next_id] = consumer->stash;
    map->next_id++;

    origin_set_t consumer_bit = (origin_set_t)1 << consumer->origin_id;

    /* Set consumer's own origin bits on its slots.
     * A method with cv != NULL is Defined (gets origin bit).
     * A method with cv == NULL is Required (stays at 0). */
    for (UV i = 0; i < consumer->method_count; i++) {
        if (consumer->method_slots[i].cv != NULL)
            consumer->method_slots[i].origins = consumer_bit;
        /* else: Required — leave origins at 0 */
    }
    for (UV i = 0; i < consumer->field_count; i++)
        consumer->field_slots[i].origins = consumer_bit;

    /* Assign IDs to roles */
    for (UV r = 0; r < role_count; r++) {
        if (map->next_id >= ORIGIN_SET_MAX_BITS)
            croak("Too many roles in a single composition (max %d)",
                  ORIGIN_SET_MAX_BITS);

        roles[r]->origin_id = map->next_id;
        map->stashes[map->next_id] = roles[r]->stash;
        map->next_id++;

        origin_set_t role_bit = (origin_set_t)1 << roles[r]->origin_id;

        /* Set role's origin bits on its slots */
        for (UV i = 0; i < roles[r]->method_count; i++) {
            if (roles[r]->method_slots[i].cv != NULL)
                roles[r]->method_slots[i].origins = role_bit;
        }
        for (UV i = 0; i < roles[r]->field_count; i++)
            roles[r]->field_slots[i].origins = role_bit;
    }
}
#define proto_role_assign_ids(consumer, roles, count, map) \
    S_proto_role_assign_ids(aTHX_ consumer, roles, count, map)

/* Merge two sorted method-slot arrays into a new allocated array.
 * For same-name entries, origins are OR'd together (the algebra).
 * CV from left is kept as representative. */
static method_slot_t *
S_merge_method_slots(pTHX_ method_slot_t *a, UV a_count,
                           method_slot_t *b, UV b_count,
                           UV *out_count)
{
    UV max = a_count + b_count;
    method_slot_t *out;
    Newx(out, max ? max : 1, method_slot_t);
    UV ai = 0, bi = 0, oi = 0;

    while (ai < a_count && bi < b_count) {
        int cmp = sv_cmp(a[ai].name, b[bi].name);
        if (cmp < 0) {
            out[oi] = a[ai];
            out[oi].name = SvREFCNT_inc(a[ai].name);
            out[oi].cv   = a[ai].cv ? (CV *)SvREFCNT_inc((SV *)a[ai].cv) : NULL;
            oi++; ai++;
        }
        else if (cmp > 0) {
            out[oi] = b[bi];
            out[oi].name = SvREFCNT_inc(b[bi].name);
            out[oi].cv   = b[bi].cv ? (CV *)SvREFCNT_inc((SV *)b[bi].cv) : NULL;
            oi++; bi++;
        }
        else {
            /* Same name — compose via OR */
            out[oi].name    = SvREFCNT_inc(a[ai].name);
            out[oi].origins = compose_origins(a[ai].origins, b[bi].origins);
            out[oi].from_field = a[ai].from_field ? a[ai].from_field : b[bi].from_field;

            /* Keep CV from left for Defined, either for Conflicted (arbitrary) */
            if (a[ai].cv) {
                out[oi].cv = (CV *)SvREFCNT_inc((SV *)a[ai].cv);
            } else {
                out[oi].cv = b[bi].cv ? (CV *)SvREFCNT_inc((SV *)b[bi].cv) : NULL;
            }

            oi++; ai++; bi++;
        }
    }

    /* Copy remaining from a */
    while (ai < a_count) {
        out[oi] = a[ai];
        out[oi].name = SvREFCNT_inc(a[ai].name);
        out[oi].cv   = a[ai].cv ? (CV *)SvREFCNT_inc((SV *)a[ai].cv) : NULL;
        oi++; ai++;
    }

    /* Copy remaining from b */
    while (bi < b_count) {
        out[oi] = b[bi];
        out[oi].name = SvREFCNT_inc(b[bi].name);
        out[oi].cv   = b[bi].cv ? (CV *)SvREFCNT_inc((SV *)b[bi].cv) : NULL;
        oi++; bi++;
    }

    *out_count = oi;
    return out;
}
#define merge_method_slots(a, ac, b, bc, oc) \
    S_merge_method_slots(aTHX_ a, ac, b, bc, oc)

/* Merge two sorted field-slot arrays into a new allocated array.
 * Same semantics as method slots but no Required variant. */
static field_slot_t *
S_merge_field_slots(pTHX_ field_slot_t *a, UV a_count,
                          field_slot_t *b, UV b_count,
                          UV *out_count)
{
    UV max = a_count + b_count;
    field_slot_t *out;
    Newx(out, max ? max : 1, field_slot_t);
    UV ai = 0, bi = 0, oi = 0;

    while (ai < a_count && bi < b_count) {
        int cmp = sv_cmp(PadnameSV(a[ai].padname), PadnameSV(b[bi].padname));
        if (cmp < 0) {
            out[oi].padname = PadnameREFCNT_inc(a[ai].padname);
            out[oi].origins = a[ai].origins;
            oi++; ai++;
        }
        else if (cmp > 0) {
            out[oi].padname = PadnameREFCNT_inc(b[bi].padname);
            out[oi].origins = b[bi].origins;
            oi++; bi++;
        }
        else {
            /* Same name — compose via OR */
            out[oi].padname = PadnameREFCNT_inc(a[ai].padname);
            out[oi].origins = compose_origins(a[ai].origins, b[bi].origins);
            oi++; ai++; bi++;
        }
    }

    while (ai < a_count) {
        out[oi].padname = PadnameREFCNT_inc(a[ai].padname);
        out[oi].origins = a[ai].origins;
        oi++; ai++;
    }

    while (bi < b_count) {
        out[oi].padname = PadnameREFCNT_inc(b[bi].padname);
        out[oi].origins = b[bi].origins;
        oi++; bi++;
    }

    *out_count = oi;
    return out;
}
#define merge_field_slots(a, ac, b, bc, oc) \
    S_merge_field_slots(aTHX_ a, ac, b, bc, oc)

/* Compose two proto-roles into a new proto-role.
 * The result has merged method and field slot arrays. */
static proto_role_t *
S_proto_role_compose_pair(pTHX_ proto_role_t *left, proto_role_t *right)
{
    proto_role_t *result;
    Newxz(result, 1, proto_role_t);

    result->method_slots = merge_method_slots(
        left->method_slots, left->method_count,
        right->method_slots, right->method_count,
        &result->method_count);
    result->method_alloc = result->method_count;

    result->field_slots = merge_field_slots(
        left->field_slots, left->field_count,
        right->field_slots, right->field_count,
        &result->field_count);
    result->field_alloc = result->field_count;

    return result;
}
#define proto_role_compose_pair(l, r) S_proto_role_compose_pair(aTHX_ l, r)

/* Fold N proto-roles via repeated pairwise merge.
 * roles[0] is the consumer's proto-role. */
static proto_role_t *
S_proto_role_compose_all(pTHX_ proto_role_t **roles, UV count)
{
    assert(count > 0);

    proto_role_t *result = roles[0];

    for (UV i = 1; i < count; i++) {
        proto_role_t *merged = proto_role_compose_pair(result, roles[i]);
        /* Free intermediate results (but not the originals) */
        if (i > 1)
            proto_role_free(result);
        result = merged;
    }

    return result;
}
#define proto_role_compose_all(roles, count) \
    S_proto_role_compose_all(aTHX_ roles, count)

/* Check if the consumer has an explicit method (not generated accessor)
 * with the given name. Uses binary search on sorted array. */
static bool
S_consumer_has_explicit(pTHX_ proto_role_t *consumer, SV *name)
{
    /* Binary search on sorted method_slots */
    UV lo = 0, hi = consumer->method_count;
    while (lo < hi) {
        UV mid = (lo + hi) / 2;
        int cmp = sv_cmp(consumer->method_slots[mid].name, name);
        if (cmp == 0) {
            /* Found — but only counts if explicit (not generated accessor) */
            return consumer->method_slots[mid].from_field == NULL
                && consumer->method_slots[mid].cv != NULL;
        }
        if (cmp < 0) lo = mid + 1;
        else          hi = mid;
    }
    return FALSE;
}
#define consumer_has_explicit(consumer, name) \
    S_consumer_has_explicit(aTHX_ consumer, name)

/* Check if the class inherits a method from its superclass chain */
static bool
S_class_inherits_method(pTHX_ HV *stash, SV *name)
{
    struct xpvhv_aux *aux = HvAUX(stash);
    HV *super = aux->xhv_class_superclass;
    if (!super)
        return FALSE;

    /* Walk superclass chain */
    while (super) {
        HE *he = hv_fetch_ent(super, name, 0, 0);
        if (he) {
            SV *entry = HeVAL(he);
            CV *cv = NULL;
            if (SvTYPE(entry) == SVt_PVGV && isGV_with_GP(entry))
                cv = GvCV((GV *)entry);
            else if (SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVCV)
                cv = (CV *)SvRV(entry);
            if (cv && CvROOT(cv))
                return TRUE;
        }
        if (!HvSTASH_IS_CLASS(super))
            break;
        super = HvAUX(super)->xhv_class_superclass;
    }
    return FALSE;
}
#define class_inherits_method(stash, name) \
    S_class_inherits_method(aTHX_ stash, name)

/* Resolution: check composed result against consumer's explicit methods.
 * Returns NULL if no errors, or an AV of error SVs. */
static AV *
S_proto_role_resolve(pTHX_ proto_role_t *composed,
                     proto_role_t *consumer, HV *stash,
                     origin_map_t *map, bool is_role)
{
    AV *errors = NULL;

    for (UV i = 0; i < composed->method_count; i++) {
        method_slot_t *slot = &composed->method_slots[i];
        origin_set_t origins = slot->origins;

        if (origin_is_required(origins)) {
            /* Required — check consumer explicit methods and inheritance */
            if (consumer_has_explicit(consumer, slot->name))
                continue;
            if (!is_role && class_inherits_method(stash, slot->name))
                continue;

            /* For roles, unresolved Required slots propagate (not errors) */
            if (is_role)
                continue;

            if (!errors) errors = newAV();
            av_push(errors, newSVpvf(
                "Method '%" SVf "' is required but not provided by %"
                HvNAMEf_QUOTEDPREFIX,
                SVfARG(slot->name), HvNAMEfARG(stash)));
        }
        else if (origin_is_conflicted(origins)) {
            /* Conflicted — only consumer explicit method resolves */
            if (consumer_has_explicit(consumer, slot->name))
                continue;

            /* For roles, unresolved Conflicted slots propagate */
            if (is_role)
                continue;

            /* Inherited method does NOT resolve conflicts */
            if (!errors) errors = newAV();

            /* Build list of conflicting role names */
            SV *role_names = newSVpvs("");
            bool first = TRUE;
            for (U8 bit = 0; bit < map->next_id; bit++) {
                if ((origins & ((origin_set_t)1 << bit)) && map->stashes[bit]) {
                    /* Skip consumer's own origin in the message */
                    if (map->stashes[bit] == stash)
                        continue;
                    if (!first)
                        sv_catpvs(role_names, " and ");
                    sv_catpvf(role_names, "%" HvNAMEf_QUOTEDPREFIX,
                              HvNAMEfARG(map->stashes[bit]));
                    first = FALSE;
                }
            }

            av_push(errors, newSVpvf(
                "Method '%" SVf "' conflicts between %" SVf,
                SVfARG(slot->name), SVfARG(role_names)));
            SvREFCNT_dec(role_names);
        }
        /* Defined (popcount == 1): no action needed */
    }

    /* Field conflicts are always errors */
    for (UV i = 0; i < composed->field_count; i++) {
        field_slot_t *slot = &composed->field_slots[i];
        if (origin_is_conflicted(slot->origins)) {
            if (!errors) errors = newAV();

            SV *role_names = newSVpvs("");
            bool first = TRUE;
            for (U8 bit = 0; bit < map->next_id; bit++) {
                if ((slot->origins & ((origin_set_t)1 << bit)) && map->stashes[bit]) {
                    if (!first)
                        sv_catpvs(role_names, " and ");
                    sv_catpvf(role_names, "%" HvNAMEf_QUOTEDPREFIX,
                              HvNAMEfARG(map->stashes[bit]));
                    first = FALSE;
                }
            }

            av_push(errors, newSVpvf(
                "Field '%" SVf "' conflicts between %" SVf,
                SVfARG(PadnameSV(slot->padname)), SVfARG(role_names)));
            SvREFCNT_dec(role_names);
        }
    }

    return errors; /* NULL = no errors */
}
#define proto_role_resolve(composed, consumer, stash, map, is_role) \
    S_proto_role_resolve(aTHX_ composed, consumer, stash, map, is_role)

/* Format and croak with all collected errors */
static void
S_proto_role_croak_errors(pTHX_ AV *errors, HV *stash)
{
    assert(errors && av_count(errors) > 0);

    SV *msg = newSVpvf("Role composition errors in %" HvNAMEf_QUOTEDPREFIX
                        ":\n", HvNAMEfARG(stash));

    for (SSize_t i = 0; i <= AvFILL(errors); i++) {
        sv_catpvf(msg, "  - %" SVf "\n", SVfARG(AvARRAY(errors)[i]));
    }

    SvREFCNT_dec(errors);
    croak_sv(msg);
}
#define proto_role_croak_errors(errors, stash) \
    S_proto_role_croak_errors(aTHX_ errors, stash)

/* ======================================================================== */

/* New proto-role-based composition pipeline.
 * Replaces S_class_compose_roles with algebraic composition + resolution.
 * Returns an AV of role initfields CVs (same interface as the old function). */
static AV *
S_proto_role_compose_and_install(pTHX_ HV *stash)
{
    struct xpvhv_aux *aux = HvAUX(stash);
    bool is_role = HvSTASH_IS_ROLE(stash);
    proto_role_t *consumer_pr = aux->xhv_class_proto_role;

    if (!aux->xhv_class_pending_roles || av_count(aux->xhv_class_pending_roles) == 0)
        return NULL;

    /* Step 1: Collect unique roles with diamond deduplication */
    AV *seen = newAV();
    SAVEFREESV((SV *)seen);
    AV *flat_roles = newAV();
    SAVEFREESV((SV *)flat_roles);

    collect_unique_roles(aux->xhv_class_pending_roles, seen, flat_roles);

    UV role_count = (UV)av_count(flat_roles);
    if (role_count == 0)
        return NULL;

    /* Step 2: Gather role proto-roles and assign origin IDs */
    proto_role_t **all_roles;
    /* all_roles[0] = consumer, all_roles[1..N] = roles */
    Newx(all_roles, 1 + role_count, proto_role_t *);
    all_roles[0] = consumer_pr;

    for (UV i = 0; i < role_count; i++) {
        HV *rolestash = (HV *)AvARRAY(flat_roles)[i];
        struct xpvhv_aux *roleaux = HvAUX(rolestash);

        if (!roleaux->xhv_class_proto_role) {
            /* Role doesn't have a proto-role (shouldn't happen for roles
             * sealed by this build; falling back to legacy composition) */
#ifdef DEBUGGING
            Perl_ck_warner_d(aTHX_ packWARN(WARN_DEBUGGING),
                      "proto_role_compose_and_install: role %" HvNAMEf_QUOTEDPREFIX
                      " has no proto-role; falling back to legacy composition path",
                      HvNAMEfARG(rolestash));
#endif
            Safefree(all_roles);
            goto fallback;
        }
        all_roles[1 + i] = roleaux->xhv_class_proto_role;
    }

    origin_map_t map;
    proto_role_assign_ids(consumer_pr, all_roles + 1, role_count, &map);

    /* Step 3: Compose all proto-roles */
    proto_role_t *composed = proto_role_compose_all(all_roles, 1 + role_count);

    /* Step 4: Resolve */
    AV *errors = proto_role_resolve(composed, consumer_pr, stash, &map, is_role);

    if (errors) {
        proto_role_free(composed);
        Safefree(all_roles);
        proto_role_croak_errors(errors, stash);
        /* NOTREACHED */
    }

    /* Step 5: Install — perform the same work as the old compose function:
     * field index advancement, param_map propagation, initfields chaining,
     * method installation, ADJUST blocks, role tracking for DOES.
     *
     * We iterate over the flat_roles in order (same as old code) for
     * installation, but use the composed proto-role for conflict-free
     * assurance. */
    AV *role_initfields_cvs = newAV();

    for (SSize_t ri = 0; ri <= AvFILL(flat_roles); ri++) {
        HV *rolestash = (HV *)AvARRAY(flat_roles)[ri];
        struct xpvhv_aux *roleaux = HvAUX(rolestash);

        PADOFFSET fieldix_offset = aux->xhv_class_next_fieldix;

        /* --- Compose fields (metadata only) --- */
        {
            PADNAMELIST *rolefields = roleaux->xhv_class_fields;
            if (rolefields) {
                PADNAME **pnp = PadnamelistARRAY(rolefields);
                SSize_t max = PadnamelistMAX(rolefields);

                for (SSize_t i = 0; i <= max; i++) {
                    PADNAME *rolepn = pnp[i];
                    if (!rolepn || !PadnameIsFIELD(rolepn))
                        continue;

                    /* Param map propagation */
                    if (PadnameFIELDINFO(rolepn)->paramname) {
                        PADOFFSET fieldix = PadnameFIELDINFO(rolepn)->fieldix + fieldix_offset;
                        if (!aux->xhv_class_param_map)
                            aux->xhv_class_param_map = newHV();
                        if (!hv_exists_ent(aux->xhv_class_param_map,
                                           PadnameFIELDINFO(rolepn)->paramname, 0))
                            (void)hv_store_ent(aux->xhv_class_param_map,
                                PadnameFIELDINFO(rolepn)->paramname,
                                newSVuv(fieldix), 0);
                    }
                }
            }
        }

        /* Advance next_fieldix past this role's fields */
        {
            PADOFFSET role_end = fieldix_offset + roleaux->xhv_class_next_fieldix;
            if (role_end > aux->xhv_class_next_fieldix)
                aux->xhv_class_next_fieldix = role_end;
        }

        /* Propagate transitive param_map entries */
        if (roleaux->xhv_class_param_map) {
            if (!aux->xhv_class_param_map)
                aux->xhv_class_param_map = newHV();
            hv_iterinit(roleaux->xhv_class_param_map);
            HE *he;
            while ((he = hv_iternext(roleaux->xhv_class_param_map))) {
                SV *key = HeSVKEY_force(he);
                if (!hv_exists_ent(aux->xhv_class_param_map, key, 0)) {
                    PADOFFSET fieldix = SvUV(HeVAL(he)) + fieldix_offset;
                    (void)hv_store_ent(aux->xhv_class_param_map,
                        key, newSVuv(fieldix), 0);
                }
            }
        }

        /* --- Chain the role's initfields CV --- */
        if (roleaux->xhv_class_initfields_cv) {
            CV *initcv = roleaux->xhv_class_initfields_cv;

            if (fieldix_offset > 0) {
                initcv = cv_clone_with_field_offset(initcv, fieldix_offset);
                av_push(role_initfields_cvs, (SV *)initcv);
            }
            else {
                av_push(role_initfields_cvs, SvREFCNT_inc((SV *)initcv));
            }
        }

        /* --- Install methods --- */
        {
            HE *he;
            (void)hv_iterinit(rolestash);
            while ((he = hv_iternext(rolestash))) {
                STRLEN klen;
                const char *key = HePV(he, klen);
                SV *entry = HeVAL(he);
                CV *rolecv = NULL;

                if (memEQs(key, klen, "new"))
                    continue;

                if (SvTYPE(entry) == SVt_PVGV && isGV_with_GP(entry))
                    rolecv = GvCV((GV *)entry);
                else if (SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVCV)
                    rolecv = (CV *)SvRV(entry);

                if (!rolecv || !CvIsMETHOD(rolecv))
                    continue;

                /* Required method stub — propagate to role consumers */
                if (!CvROOT(rolecv)) {
                    SV *methname = HeSVKEY_force(he);
                    HE *existing = hv_fetch_ent(stash, methname, 0, 0);

                    if (existing) {
                        SV *existentry = HeVAL(existing);
                        CV *existcv = NULL;
                        if (SvTYPE(existentry) == SVt_PVGV && isGV_with_GP(existentry))
                            existcv = GvCV((GV *)existentry);
                        else if (SvROK(existentry) && SvTYPE(SvRV(existentry)) == SVt_PVCV)
                            existcv = (CV *)SvRV(existentry);
                        if (existcv && CvROOT(existcv))
                            continue; /* satisfied */
                    }

                    /* For role consumers, install stub for transitive propagation */
                    if (is_role && !existing) {
                        (void)hv_store(stash, key,
                                       HeUTF8(he) ? -(I32)klen : (I32)klen,
                                       newRV_inc((SV *)rolecv), 0);
                    }
                    continue;
                }

                /* Check for existing method — skip if same origin (diamond) */
                HE *existing = hv_fetch_ent(stash, HeSVKEY_force(he), 0, 0);
                if (existing) {
                    SV *existentry = HeVAL(existing);
                    CV *existcv = NULL;
                    if (SvTYPE(existentry) == SVt_PVGV && isGV_with_GP(existentry))
                        existcv = GvCV((GV *)existentry);
                    else if (SvROK(existentry) && SvTYPE(SvRV(existentry)) == SVt_PVCV)
                        existcv = (CV *)SvRV(existentry);

                    /* Same CV or same origin (diamond) */
                    if (existcv == rolecv ||
                        (existcv && CvSTASH(existcv) == CvSTASH(rolecv)))
                        continue;

                    /* Consumer stub satisfied by role method */
                    if (existcv && !CvROOT(existcv))
                        goto new_install_method;

                    /* Consumer's explicit method takes precedence (conflict
                     * was already checked by proto_role_resolve) */
                    if (existcv && CvIsMETHOD(existcv) &&
                        consumer_has_explicit(consumer_pr, HeSVKEY_force(he)))
                        continue;

                    /* Remaining conflict case — should have been caught by resolve.
                     * But if another role already installed its method, skip
                     * (this role's method was conflicting but resolved by consumer). */
                    if (existcv && CvIsMETHOD(existcv))
                        continue;
                }

                new_install_method: {
                    CV *composed_cv = rolecv;
                    if (fieldix_offset > 0) {
                        OP *methstart = find_op_methstart(CvROOT(rolecv));
                        if (methstart && cUNOP_AUXx(methstart)->op_aux) {
                            U32 fieldcount = cUNOP_AUXx(methstart)->op_aux[0].uv;
                            if (fieldcount > 0)
                                composed_cv = cv_clone_with_field_offset(
                                                  rolecv, fieldix_offset);
                        }
                    }

                    SV *rv = (composed_cv == rolecv)
                        ? newRV_inc((SV *)rolecv)
                        : newRV_noinc((SV *)composed_cv);
                    (void)hv_store(stash, key,
                                   HeUTF8(he) ? -(I32)klen : (I32)klen,
                                   rv, 0);
                }
            }
        }

        /* --- Compose ADJUST blocks --- */
        if (roleaux->xhv_class_adjust_blocks) {
            if (!aux->xhv_class_adjust_blocks)
                aux->xhv_class_adjust_blocks = newAV();

            for (SSize_t i = 0; i <= AvFILL(roleaux->xhv_class_adjust_blocks); i++) {
                CV *adjust_cv = (CV *)AvARRAY(roleaux->xhv_class_adjust_blocks)[i];

                CV *composed_adjust = adjust_cv;
                if (fieldix_offset > 0) {
                    OP *methstart = find_op_methstart(CvROOT(adjust_cv));
                    if (methstart && cUNOP_AUXx(methstart)->op_aux) {
                        U32 fieldcount = cUNOP_AUXx(methstart)->op_aux[0].uv;
                        if (fieldcount > 0)
                            composed_adjust = cv_clone_with_field_offset(
                                                  adjust_cv, fieldix_offset);
                    }
                }

                av_push(aux->xhv_class_adjust_blocks,
                        SvREFCNT_inc((SV *)composed_adjust));
            }
        }

        /* --- Record role in xhv_class_roles for DOES() --- */
        {
            if (!aux->xhv_class_roles)
                aux->xhv_class_roles = newAV();

            av_push(aux->xhv_class_roles, SvREFCNT_inc((SV *)rolestash));

            /* Transitive roles */
            if (HvSTASH_IS_ROLE(rolestash)) {
                struct xpvhv_aux *raux = HvAUX(rolestash);
                if (raux->xhv_class_roles) {
                    for (SSize_t ti = 0; ti <= AvFILL(raux->xhv_class_roles); ti++) {
                        HV *transitive = (HV *)AvARRAY(raux->xhv_class_roles)[ti];
                        bool found = FALSE;
                        for (SSize_t tj = 0; tj <= AvFILL(aux->xhv_class_roles); tj++) {
                            if ((HV *)AvARRAY(aux->xhv_class_roles)[tj] == transitive) {
                                found = TRUE;
                                break;
                            }
                        }
                        if (!found)
                            av_push(aux->xhv_class_roles,
                                    SvREFCNT_inc((SV *)transitive));
                    }
                }
            }
        }
    }

    /* For roles: propagate transitively-required methods into the stored
     * proto-role so that future consumers detect unsatisfied requirements.
     * Only Required slots are propagated; Defined slots are not, because
     * the stored proto must only carry the role's own implementations
     * (the structural DOES check verifies CvSTASH == rolestash). */
    if (is_role) {
        proto_role_t *stored = aux->xhv_class_proto_role;

        /* Count new Required slots not already present */
        UV add_count = 0;
        for (UV i = 0; i < composed->method_count; i++) {
            method_slot_t *cslot = &composed->method_slots[i];
            if (!origin_is_required(cslot->origins))
                continue;
            bool found = FALSE;
            for (UV j = 0; j < stored->method_count; j++) {
                if (sv_eq(stored->method_slots[j].name, cslot->name)) {
                    found = TRUE;
                    break;
                }
            }
            if (!found) add_count++;
        }

        if (add_count > 0) {
            UV old_count = stored->method_count;
            Renew(stored->method_slots, old_count + add_count, method_slot_t);
            UV k = old_count;
            for (UV i = 0; i < composed->method_count; i++) {
                method_slot_t *cslot = &composed->method_slots[i];
                if (!origin_is_required(cslot->origins))
                    continue;
                bool found = FALSE;
                for (UV j = 0; j < old_count; j++) {
                    if (sv_eq(stored->method_slots[j].name, cslot->name)) {
                        found = TRUE;
                        break;
                    }
                }
                if (!found) {
                    stored->method_slots[k].name       = SvREFCNT_inc(cslot->name);
                    stored->method_slots[k].origins    = 0; /* Required */
                    stored->method_slots[k].cv         = NULL;
                    stored->method_slots[k].from_field = FALSE;
                    k++;
                }
            }
            stored->method_count = k;
        }
    }

    proto_role_free(composed);
    Safefree(all_roles);

    return role_initfields_cvs;

fallback:
    /* Fall back to old compose path if a role lacks proto-role */
    return class_compose_roles(stash);
}
#define proto_role_compose_and_install(stash) \
    S_proto_role_compose_and_install(aTHX_ stash)

/* Old composition function (retained for fallback). Will be removed once
 * all roles have proto-roles. */
/* Compose all pending roles into a class/role stash.
 * Called from class_seal_stash / role_seal_stash before Phase 1 (field resolution).
 * Returns an AV of (cloned) role initfields CVs with offset fieldix,
 * to be chained in the class's initfields. Caller must free. Returns NULL
 * if no roles are pending. */
static AV *
S_class_compose_roles(pTHX_ HV *stash)
{
    struct xpvhv_aux *aux = HvAUX(stash);

    if(!aux->xhv_class_pending_roles || av_count(aux->xhv_class_pending_roles) == 0)
        return NULL;

    /* Collect unique direct roles with diamond deduplication */
    AV *seen = newAV();
    SAVEFREESV((SV *)seen);
    AV *flat_roles = newAV();
    SAVEFREESV((SV *)flat_roles);

    collect_unique_roles(aux->xhv_class_pending_roles, seen, flat_roles);

    AV *role_initfields_cvs = newAV();

    /* Track composed field names -> origin stash for conflict detection */
    HV *composed_fields = newHV(); /* field name => fieldstash ptr (as UV) */
    SAVEFREESV((SV *)composed_fields);

    /* Track required methods (from role stubs: method foo;) */
    HV *required_methods = newHV(); /* method name => role stash name */
    SAVEFREESV((SV *)required_methods);

    for(SSize_t ri = 0; ri <= AvFILL(flat_roles); ri++) {
        HV *rolestash = (HV *)AvARRAY(flat_roles)[ri];
        struct xpvhv_aux *roleaux = HvAUX(rolestash);

        PADOFFSET fieldix_offset = aux->xhv_class_next_fieldix;

        /* --- Compose fields (metadata only, no pad entries) --- */
        {
            PADNAMELIST *rolefields = roleaux->xhv_class_fields;
            if(rolefields) {
                PADNAME **pnp = PadnamelistARRAY(rolefields);
                SSize_t max = PadnamelistMAX(rolefields);

                for(SSize_t i = 0; i <= max; i++) {
                    PADNAME *rolepn = pnp[i];
                    if(!rolepn || !PadnameIsFIELD(rolepn))
                        continue;

                    /* Check for field name conflicts with previously composed fields */
                    {
                        HE *fhe = hv_fetch_ent(composed_fields,
                            PadnameSV(rolepn), 0, 0);
                        if(fhe) {
                            HV *existing_stash = INT2PTR(HV *, SvUV(HeVAL(fhe)));
                            if(existing_stash == PadnameFIELDINFO(rolepn)->fieldstash)
                                goto next_field; /* idempotent (diamond) */

                            croak("Field %" SVf " conflicts between %" HvNAMEf_QUOTEDPREFIX
                                  " and %" HvNAMEf_QUOTEDPREFIX,
                                  SVfARG(PadnameSV(rolepn)),
                                  HvNAMEfARG(existing_stash),
                                  HvNAMEfARG(PadnameFIELDINFO(rolepn)->fieldstash));
                        }
                    }

                    /* Track this field for future conflict detection */
                    (void)hv_store_ent(composed_fields,
                        PadnameSV(rolepn),
                        newSVuv(PTR2UV(PadnameFIELDINFO(rolepn)->fieldstash)), 0);

                    /* Add to param_map so the constructor knows about
                     * these params (for extraction and unknown-param
                     * validation). The role's initfields CV handles the
                     * actual initialization. */
                    if(PadnameFIELDINFO(rolepn)->paramname) {
                        PADOFFSET fieldix = PadnameFIELDINFO(rolepn)->fieldix + fieldix_offset;
                        if(!aux->xhv_class_param_map)
                            aux->xhv_class_param_map = newHV();
                        (void)hv_store_ent(aux->xhv_class_param_map,
                            PadnameFIELDINFO(rolepn)->paramname,
                            newSVuv(fieldix), 0);
                    }

                    next_field: ;
                }
            }
        }

        /* Advance next_fieldix past all of this role's fields, including
         * any transitively composed fields that aren't in its own
         * xhv_class_fields list. The role's xhv_class_next_fieldix is
         * the total slot count (own + composed) determined at role seal time. */
        {
            PADOFFSET role_end = fieldix_offset + roleaux->xhv_class_next_fieldix;
            if(role_end > aux->xhv_class_next_fieldix)
                aux->xhv_class_next_fieldix = role_end;
        }

        /* Propagate the role's param_map to the consumer. This handles
         * transitively composed :param fields that are in the role's
         * param_map but not in its xhv_class_fields (because the role
         * composed them from a sub-role). */
        if(roleaux->xhv_class_param_map) {
            if(!aux->xhv_class_param_map)
                aux->xhv_class_param_map = newHV();
            hv_iterinit(roleaux->xhv_class_param_map);
            HE *he;
            while((he = hv_iternext(roleaux->xhv_class_param_map))) {
                SV *key = HeSVKEY_force(he);
                if(!hv_exists_ent(aux->xhv_class_param_map, key, 0)) {
                    PADOFFSET fieldix = SvUV(HeVAL(he)) + fieldix_offset;
                    (void)hv_store_ent(aux->xhv_class_param_map,
                        key, newSVuv(fieldix), 0);
                }
            }
        }

        /* --- Chain the role's initfields CV --- */
        if(roleaux->xhv_class_initfields_cv) {
            CV *initcv = roleaux->xhv_class_initfields_cv;

            if(fieldix_offset > 0) {
                initcv = cv_clone_with_field_offset(initcv, fieldix_offset);
                av_push(role_initfields_cvs, (SV *)initcv); /* cv_clone refcnt=1 */
            }
            else {
                av_push(role_initfields_cvs, SvREFCNT_inc((SV *)initcv));
            }
        }

        /* --- Compose methods --- */
        {
            HE *he;
            (void)hv_iterinit(rolestash);
            while((he = hv_iternext(rolestash))) {
                STRLEN klen;
                const char *key = HePV(he, klen);
                SV *entry = HeVAL(he);
                CV *rolecv = NULL;

                if(memEQs(key, klen, "new"))
                    continue;

                if(SvTYPE(entry) == SVt_PVGV && isGV_with_GP(entry))
                    rolecv = GvCV((GV *)entry);
                else if(SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVCV)
                    rolecv = (CV *)SvRV(entry);

                if(!rolecv || !CvIsMETHOD(rolecv))
                    continue;

                /* A role method with no body (method foo;) is a requirement.
                 * Track it; install the stub into role consumers so it
                 * propagates transitively. */
                if(!CvROOT(rolecv)) {
                    SV *methname = HeSVKEY_force(he);
                    /* Check if the consumer already provides this method */
                    HE *existing = hv_fetch_ent(stash, methname, 0, 0);
                    if(existing) {
                        SV *existentry = HeVAL(existing);
                        CV *existcv = NULL;

                        if(SvTYPE(existentry) == SVt_PVGV && isGV_with_GP(existentry))
                            existcv = GvCV((GV *)existentry);
                        else if(SvROK(existentry) && SvTYPE(SvRV(existentry)) == SVt_PVCV)
                            existcv = (CV *)SvRV(existentry);

                        if(existcv && CvROOT(existcv))
                            continue; /* satisfied by consumer */
                    }
                    /* Not yet satisfied — track it */
                    (void)hv_store_ent(required_methods, methname,
                                       newSVpvf("%" HEKf, HvNAME_HEK(rolestash)), 0);
                    /* Install stub into role consumers for transitive propagation */
                    if(HvSTASH_IS_ROLE(stash) && !existing) {
                        (void)hv_store(stash, key,
                                       HeUTF8(he) ? -(I32)klen : (I32)klen,
                                       newRV_inc((SV *)rolecv), 0);
                    }
                    continue;
                }

                /* A real role method also satisfies any pending requirement
                 * of the same name (from a previously composed role) */
                (void)hv_delete_ent(required_methods, HeSVKEY_force(he), G_DISCARD, 0);

                /* Check for method conflicts */
                HE *existing = hv_fetch_ent(stash, HeSVKEY_force(he), 0, 0);
                if(existing) {
                    SV *existentry = HeVAL(existing);
                    CV *existcv = NULL;

                    if(SvTYPE(existentry) == SVt_PVGV && isGV_with_GP(existentry))
                        existcv = GvCV((GV *)existentry);
                    else if(SvROK(existentry) && SvTYPE(SvRV(existentry)) == SVt_PVCV)
                        existcv = (CV *)SvRV(existentry);

                    /* Same CV or same origin (diamond case — cloned CVs
                     * from the same source share CvSTASH) */
                    if(existcv == rolecv ||
                       (existcv && CvSTASH(existcv) == CvSTASH(rolecv)))
                        continue;

                    /* Consumer stub satisfied by role method — not a conflict */
                    if(existcv && !CvROOT(existcv))
                        goto install_method;

                    if(existcv && CvIsMETHOD(existcv)) {
                        croak("Method %" SVf " conflicts between %" HvNAMEf_QUOTEDPREFIX
                              " and %" HvNAMEf_QUOTEDPREFIX,
                              SVfARG(HeSVKEY_force(he)),
                              HvNAMEfARG(CvSTASH(existcv)),
                              HvNAMEfARG(CvSTASH(rolecv)));
                    }
                }

                install_method: {
                /* If there's a fieldix offset and this method references fields,
                 * clone the CV and attach the offset as magic. pp_methstart
                 * applies the offset at runtime, so the shared optree's aux
                 * is never mutated. */
                CV *composed_cv = rolecv;
                if(fieldix_offset > 0) {
                    OP *methstart = find_op_methstart(CvROOT(rolecv));
                    if(methstart && cUNOP_AUXx(methstart)->op_aux) {
                        U32 fieldcount = cUNOP_AUXx(methstart)->op_aux[0].uv;
                        if(fieldcount > 0)
                            composed_cv = cv_clone_with_field_offset(
                                              rolecv, fieldix_offset);
                    }
                }

                /* Install the method CV into the class stash. */
                SV *rv = (composed_cv == rolecv)
                    ? newRV_inc((SV *)rolecv)
                    : newRV_noinc((SV *)composed_cv);
                (void)hv_store(stash, key,
                               HeUTF8(he) ? -(I32)klen : (I32)klen,
                               rv, 0);
                }
            }
        }

        /* --- Compose ADJUST blocks --- */
        if(roleaux->xhv_class_adjust_blocks) {
            if(!aux->xhv_class_adjust_blocks)
                aux->xhv_class_adjust_blocks = newAV();

            for(SSize_t i = 0; i <= AvFILL(roleaux->xhv_class_adjust_blocks); i++) {
                CV *adjust_cv = (CV *)AvARRAY(roleaux->xhv_class_adjust_blocks)[i];

                /* ADJUST blocks reference fields via OP_METHSTART aux.
                 * Like methods, clone and attach offset magic. */
                CV *composed_adjust = adjust_cv;
                if(fieldix_offset > 0) {
                    OP *methstart = find_op_methstart(CvROOT(adjust_cv));
                    if(methstart && cUNOP_AUXx(methstart)->op_aux) {
                        U32 fieldcount = cUNOP_AUXx(methstart)->op_aux[0].uv;
                        if(fieldcount > 0)
                            composed_adjust = cv_clone_with_field_offset(
                                                  adjust_cv, fieldix_offset);
                    }
                }

                av_push(aux->xhv_class_adjust_blocks, SvREFCNT_inc((SV *)composed_adjust));
            }
        }

        /* --- Record role in xhv_class_roles for DOES() --- */
        {
            if(!aux->xhv_class_roles)
                aux->xhv_class_roles = newAV();

            av_push(aux->xhv_class_roles, SvREFCNT_inc((SV *)rolestash));

            /* Also record transitive roles from the composed role */
            if(HvSTASH_IS_ROLE(rolestash)) {
                struct xpvhv_aux *roleaux = HvAUX(rolestash);
                if(roleaux->xhv_class_roles) {
                    for(SSize_t ri = 0; ri <= AvFILL(roleaux->xhv_class_roles); ri++) {
                        HV *transitive = (HV *)AvARRAY(roleaux->xhv_class_roles)[ri];
                        /* Dedup: check if already recorded */
                        bool found = FALSE;
                        for(SSize_t rj = 0; rj <= AvFILL(aux->xhv_class_roles); rj++) {
                            if((HV *)AvARRAY(aux->xhv_class_roles)[rj] == transitive) {
                                found = TRUE;
                                break;
                            }
                        }
                        if(!found)
                            av_push(aux->xhv_class_roles, SvREFCNT_inc((SV *)transitive));
                    }
                }
            }
        }
    }

    /* Check for unsatisfied required methods.
     * Only enforce for classes — roles propagate requirements to consumers. */
    if(!HvSTASH_IS_ROLE(stash) && HvUSEDKEYS(required_methods) > 0) {
        HE *he;
        (void)hv_iterinit(required_methods);
        he = hv_iternext(required_methods);
        croak("Method %" SVf " is required by role %" SVf
              " but not provided by %" HvNAMEf_QUOTEDPREFIX,
              SVfARG(HeSVKEY_force(he)),
              SVfARG(HeVAL(he)),
              HvNAMEfARG(stash));
    }

    return role_initfields_cvs;
}

void
Perl_class_seal_stash(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_CLASS_SEAL_STASH;

    assert(HvSTASH_IS_CLASS(stash));

    /* If this class has already been sealed (e.g. sealed on-demand by a
     * subclass before our SAVEDESTRUCTOR fires), nothing to do.
     */
    if(HvSTASH_IS_CLASS_SEALED(stash))
        return;

    if (PL_parser->error_count) {
        /* we had errors, clean up */
        class_cleanup_definition(stash);
        return;
    }

    struct xpvhv_aux *aux = HvAUX(stash);

    /* If our superclass hasn't been sealed yet (e.g. it was declared with
     * unit syntax `class A;` and its SAVEDESTRUCTOR hasn't fired), seal it
     * now. We need its field count and initfields CV to be available.
     */
    if(aux->xhv_class_superclass && !HvSTASH_IS_CLASS_SEALED(aux->xhv_class_superclass))
        Perl_class_seal_stash(aTHX_ aux->xhv_class_superclass);

    /* Initialize next_fieldix from superclass before role composition.
     * During parsing, next_fieldix counted our own fields. Now we repurpose
     * it: set it to the superclass's total so compose_roles can allocate
     * role field blocks starting from the right offset. */
    if(aux->xhv_class_superclass) {
        assert(HvSTASH_IS_CLASS(aux->xhv_class_superclass));
        struct xpvhv_aux *superaux = HvAUX(aux->xhv_class_superclass);
        aux->xhv_class_next_fieldix = superaux->xhv_class_next_fieldix;
    }
    else {
        aux->xhv_class_next_fieldix = 0;
    }

    /* Finalize proto-role: collect explicit methods from stash, sort arrays */
    proto_role_finalize(stash);

    /* Compose all pending roles using the proto-role algebra pipeline.
     * This advances next_fieldix past role fields, installs role methods/
     * ADJUST blocks into our stash, and returns role initfields CVs for
     * chaining. Conflict resolution checks consumer's explicit methods. */
    AV *role_initfields_cvs = proto_role_compose_and_install(stash);

    /* Phase 1: Resolve class-relative field indices to absolute indices.
     * base_offset = next_fieldix, which now accounts for superclass + role
     * fields (set by compose_roles, or just the superclass if no roles).
     */
    {
        PADOFFSET base_offset = aux->xhv_class_next_fieldix;

        PADNAMELIST *fieldnames = aux->xhv_class_fields;
        PADOFFSET own_field_count = 0;

        if(fieldnames) {
            for(SSize_t i = 0; i <= PadnamelistMAX(fieldnames); i++) {
                PADNAME *pn = PadnamelistARRAY(fieldnames)[i];
                struct padname_fieldinfo *fi = PadnameFIELDINFO(pn);
                assert(fi->fieldix == (PADOFFSET)-1); /* should be unresolved */
                fi->fieldix = base_offset + fi->relative_fieldix;
                own_field_count++;
            }
        }

        /* Set next_fieldix to the total count (inherited + role + own).
         * This is what the constructor uses to size the object.
         */
        aux->xhv_class_next_fieldix = base_offset + own_field_count;
    }

    /* Phase 2: Build the OP_METHSTART field-binding aux for all method CVs.
     * Field indices are now resolved, so we can build the (padix, fieldix)
     * pairs that OP_METHSTART needs at runtime.
     *
     * We process CVs from two sources:
     *   (a) The pending_method_cvs list — covers anonymous methods, lexical
     *       methods, and ADJUST blocks that aren't in the stash.
     *   (b) A walk of the stash — covers named methods, including those
     *       whose optree was transferred from PL_compcv to a pre-existing
     *       CV by newATTRSUB (e.g. forward-declared methods).
     * The NULL-aux check on OP_METHSTART prevents double-processing.
     */
    {
        /* Process pending (non-stash) method CVs */
        if(aux->xhv_class_pending_method_cvs) {
            AV *pending = aux->xhv_class_pending_method_cvs;

            for(SSize_t i = 0; i <= AvFILL(pending); i++) {
                CV *methcv = (CV *)AvARRAY(pending)[i];
                if(CvROOT(methcv))
                    class_seal_method_fieldmap(methcv);
            }

            SvREFCNT_dec_NN((SV *)pending);
            aux->xhv_class_pending_method_cvs = NULL;
        }

        /* Also walk the stash for named method CVs (catches forward-declared
         * methods where newATTRSUB transferred the optree to the existing CV)
         */
        if(hv_iterinit(stash)) {
            HE *he;
            while((he = hv_iternext(stash)) != NULL) {
                SV *entry = HeVAL(he);
                CV *cv = NULL;
                if(SvTYPE(entry) == SVt_PVGV)
                    cv = GvCV((GV *)entry);
                else if(SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVCV)
                    cv = (CV *)SvRV(entry);

                if(cv && CvIsMETHOD(cv) && CvROOT(cv))
                    class_seal_method_fieldmap(cv);
            }
        }
    }

    /* Phase 3: Generate initfields CV */
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

    if(aux->xhv_class_superclass) {
        HV *superstash = aux->xhv_class_superclass;
        assert(HvSTASH_IS_CLASS(superstash));
        struct xpvhv_aux *superaux = HvAUX(superstash);

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

    /* Chain composed role initfields CVs. These run after the superclass
     * initfields but before the class's own OP_INITFIELD ops. */
    if(role_initfields_cvs) {
        for(SSize_t i = 0; i <= AvFILL(role_initfields_cvs); i++) {
            CV *role_initcv = (CV *)AvARRAY(role_initfields_cvs)[i];

            OP *o = newLISTOPn(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED,
                newPADxVOP(OP_PADSV, 0, PADIX_SELF),
                newPADxVOP(OP_PADHV, OPf_REF, PADIX_PARAMS),
                newSVOP(OP_CONST, 0, SvREFCNT_inc((SV *)role_initcv)),
                NULL);

            ops = op_append_list(OP_LINESEQ, ops, o);
        }
        SvREFCNT_dec((SV *)role_initfields_cvs);
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

    aux->xhv_aux_flags |= HvAUXf_IS_CLASS_SEALED;
}

void
Perl_role_setup_stash(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_ROLE_SETUP_STASH;

    assert(HvHasAUX(stash));

    if(HvSTASH_IS_ROLE(stash)) {
        croak("Cannot reopen existing role %" HvNAMEf_QUOTEDPREFIX,
            HvNAMEfARG(stash));
    }

    if(HvSTASH_IS_CLASS(stash)) {
        croak("Cannot define role %" HvNAMEf_QUOTEDPREFIX " as it is already a class",
            HvNAMEfARG(stash));
    }

    {
        SV *isaname = newSVpvf("%" HEKf "::ISA", HvNAME_HEK(stash));
        sv_2mortal(isaname);

        AV *isa = get_av(SvPV_nolen(isaname), (SvFLAGS(isaname) & SVf_UTF8));

        if(isa && av_count(isa) > 0)
            croak("Cannot create role %" HEKf " as it already has a non-empty @ISA",
                HvNAME_HEK(stash));
    }

    /* Roles do NOT get a constructor injected */

    struct xpvhv_aux *aux = HvAUX(stash);
    aux->xhv_class_superclass         = NULL;
    aux->xhv_class_initfields_cv      = NULL;
    aux->xhv_class_adjust_blocks      = NULL;
    aux->xhv_class_fields             = NULL;
    aux->xhv_class_next_fieldix       = 0;
    aux->xhv_class_param_map          = NULL;
    aux->xhv_class_pending_method_cvs = NULL;
    aux->xhv_class_pending_roles      = NULL;
    aux->xhv_class_roles              = NULL;
    aux->xhv_class_proto_role         = proto_role_new(stash);

    aux->xhv_aux_flags |= HvAUXf_IS_ROLE;

    SAVEDESTRUCTOR_X(invoke_role_seal, stash);

    /* Prepare a suspended compcv for parsing field init expressions */
    {
        I32 floor_ix = start_subparse(FALSE, 0);

        CvIsMETHOD_on(PL_compcv);

        PADOFFSET padix = pad_add_name_pvs("$(self)", 0, NULL, NULL);
        assert(padix == PADIX_SELF);

        padix = pad_add_name_pvs("%(params)", 0, NULL, NULL);
        assert(padix == PADIX_PARAMS);

        padix = pad_add_name_pvs("$(role_offset)", 0, NULL, NULL);
        assert(padix == PADIX_ROLE_OFFSET);

        PERL_UNUSED_VAR(padix);

        Newx(aux->xhv_class_suspended_initfields_compcv, 1, struct suspended_compcv);
        suspend_compcv(aux->xhv_class_suspended_initfields_compcv);

        LEAVE_SCOPE(floor_ix);
    }
}

void
Perl_role_seal_stash(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_ROLE_SEAL_STASH;

    assert(HvSTASH_IS_ROLE(stash));

    if (PL_parser->error_count) {
        class_cleanup_definition(stash);
        return;
    }

    struct xpvhv_aux *aux = HvAUX(stash);

    /* Roles have no superclass, so base starts at 0 */
    aux->xhv_class_next_fieldix = 0;

    /* Finalize proto-role: collect explicit methods from stash, sort arrays */
    proto_role_finalize(stash);

    /* Compose any roles this role composes (role-composes-role).
     * Uses proto-role algebra pipeline for composition and resolution. */
    AV *role_initfields_cvs = proto_role_compose_and_install(stash);

    /* Phase 1: Resolve field indices.
     * base_offset = next_fieldix (includes any composed role fields). */
    {
        PADOFFSET base_offset = aux->xhv_class_next_fieldix;
        PADNAMELIST *fieldnames = aux->xhv_class_fields;
        PADOFFSET own_field_count = 0;

        for(SSize_t i = 0; fieldnames && i <= PadnamelistMAX(fieldnames); i++) {
            PADNAME *pn = PadnamelistARRAY(fieldnames)[i];
            if(!pn || !PadnameIsFIELD(pn))
                continue;

            struct padname_fieldinfo *fi = PadnameFIELDINFO(pn);
            assert(fi->fieldix == (PADOFFSET)-1);  /* should be unresolved */
            fi->fieldix = base_offset + fi->relative_fieldix;
            own_field_count++;
        }
        aux->xhv_class_next_fieldix = base_offset + own_field_count;
    }

    /* Phase 2: Build OP_METHSTART field binding aux for all method CVs */
    {
        /* First process pending method CVs collected during parsing */
        if(aux->xhv_class_pending_method_cvs) {
            AV *pending = aux->xhv_class_pending_method_cvs;
            for(SSize_t i = 0; i <= AvFILL(pending); i++) {
                CV *cv = (CV *)AvARRAY(pending)[i];
                if(CvROOT(cv))
                    class_seal_method_fieldmap(cv);
            }
        }

        /* Also walk the stash for any named method CVs not in the pending list */
        {
            HE *he;
            (void)hv_iterinit(stash);
            while((he = hv_iternext(stash))) {
                SV *entry = HeVAL(he);
                CV *cv = NULL;

                if(SvTYPE(entry) == SVt_PVGV && isGV_with_GP(entry))
                    cv = GvCV((GV *)entry);
                else if(SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVCV)
                    cv = (CV *)SvRV(entry);

                if(!cv || !CvIsMETHOD(cv) || !CvROOT(cv))
                    continue;

                class_seal_method_fieldmap(cv);
            }
        }

        SvREFCNT_dec(aux->xhv_class_pending_method_cvs);
        aux->xhv_class_pending_method_cvs = NULL;
    }

    /* Phase 3: Generate initfields CV */
    I32 floor_ix = PL_savestack_ix;
    SAVEI32(PL_subline);
    save_item(PL_subname);

    resume_compcv_final(aux->xhv_class_suspended_initfields_compcv);

    PADNAMELIST *pnl = PadlistNAMES(CvPADLIST(PL_compcv));
    HV *fieldix_to_padix = newHV();
    SAVEFREESV((SV *)fieldix_to_padix);

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

    /* Chain composed role initfields CVs */
    if(role_initfields_cvs) {
        for(SSize_t i = 0; i <= AvFILL(role_initfields_cvs); i++) {
            CV *role_initcv = (CV *)AvARRAY(role_initfields_cvs)[i];

            OP *o = newLISTOPn(OP_ENTERSUB, OPf_WANT_VOID|OPf_STACKED,
                newPADxVOP(OP_PADSV, 0, PADIX_SELF),
                newPADxVOP(OP_PADHV, OPf_REF, PADIX_PARAMS),
                newSVOP(OP_CONST, 0, SvREFCNT_inc((SV *)role_initcv)),
                NULL);

            ops = op_append_list(OP_LINESEQ, ops, o);
        }
        SvREFCNT_dec((SV *)role_initfields_cvs);
    }

    PADNAMELIST *fieldnames = aux->xhv_class_fields;

    for(SSize_t i = 0; fieldnames && i <= PadnamelistMAX(fieldnames); i++) {
        PADNAME *pn = PadnamelistARRAY(fieldnames)[i];
        char sigil = PadnamePV(pn)[0];
        PADOFFSET fieldix = PadnameFIELDINFO(pn)->fieldix;

        OP *valop = PadnameFIELDINFO(pn)->defop;
        if(valop && valop->op_type == OP_LINESEQ) {
            OP *o = cLISTOPx(valop)->op_first;
            cLISTOPx(valop)->op_first = NULL;
            cLISTOPx(valop)->op_last = NULL;
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
                    valop = newLOGOP(OP_DOR, 0,
                                     newUNOP(OP_DELETE, 0, helemop), valop);
                }
                else if(PadnameFIELDINFO(pn)->def_if_false) {
                    valop = newLOGOP(OP_OR, 0,
                                     newUNOP(OP_DELETE, 0, helemop), valop);
                }
                else {
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

        UNOP_AUX_item *faux;
        faux = (UNOP_AUX_item *)PerlMemShared_malloc(sizeof(UNOP_AUX_item) * 2);

        faux[0].uv = fieldix;

        OP *fieldop = newUNOP_AUX(OP_INITFIELD, valop ? OPf_STACKED : 0, valop, faux);
        fieldop->op_private = op_priv;

        HE *he;
        if((he = hv_fetch_ent(fieldix_to_padix, sv_2mortal(newSVuv(fieldix)), 0, 0)) &&
           SvOK(HeVAL(he))) {
            fieldop->op_targ = SvUV(HeVAL(he));
        }

        ops = op_append_list(OP_LINESEQ, ops, fieldop);
    }

    CvIsMETHOD_off(PL_compcv);
    CV *initfields = newATTRSUB(floor_ix, NULL, NULL, NULL, ops);
    CvIsMETHOD_on(initfields);

    aux->xhv_class_initfields_cv = initfields;
}

void
Perl_class_prepare_initfield_parse(pTHX)
{
    PERL_ARGS_ASSERT_CLASS_PREPARE_INITFIELD_PARSE;

    assert(HvSTASH_IS_CLASS_OR_ROLE(PL_curstash));
    struct xpvhv_aux *aux = HvAUX(PL_curstash);

    resume_compcv_and_save(aux->xhv_class_suspended_initfields_compcv);
    CvOUTSIDE_SEQ(PL_compcv) = PL_cop_seqmax;
}

void
Perl_class_prepare_method_parse(pTHX_ CV *cv)
{
    PERL_ARGS_ASSERT_CLASS_PREPARE_METHOD_PARSE;

    assert(cv == PL_compcv);
    assert(HvSTASH_IS_CLASS_OR_ROLE(PL_curstash));

    /* We expect this to be at the start of sub parsing, so there won't be
     * anything in the pad yet
     */
    assert(PL_comppad_name_fill == 0);

    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    assert(padix == PADIX_SELF);

    padix = pad_add_name_pvs("$(params)", 0, NULL, NULL);
    assert(padix == PADIX_PARAMS);

    padix = pad_add_name_pvs("$(role_offset)", 0, NULL, NULL);
    assert(padix == PADIX_ROLE_OFFSET);
    PERL_UNUSED_VAR(padix);

    intro_my();

    CvNOWARN_AMBIGUOUS_on(cv);
    CvIsMETHOD_on(cv);
}

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

    /* Field indices are not yet resolved (they are class-relative at this
     * point). We insert the OP_METHSTART with NULL aux and record this CV
     * for fixup at seal time, when absolute field indices are known.
     */

    /* If this is an empty method body then o will be an OP_STUB and not a
     * list. This will confuse op_sibling_splice() */
    if(o->op_type != OP_LINESEQ)
        o = newLISTOP(OP_LINESEQ, 0, o, NULL);

    if(CvSIGNATURE(PL_compcv)) {
        /* A signatured method has already injected the OP_METHSTART;
         * leave its aux as NULL for now. Just assert it exists.
         */
#ifdef DEBUGGING
        OP *methstartop = find_op_methstart(o);
        assert(methstartop);
        assert(!cUNOP_AUXx(methstartop)->op_aux);
#endif
    }
    else
        op_sibling_splice(o, NULL, 0, newUNOP_AUX(OP_METHSTART, 0, NULL, NULL));

    /* Record this method CV for field binding fixup at class seal time */
    {
        assert(HvSTASH_IS_CLASS_OR_ROLE(PL_curstash));
        struct xpvhv_aux *aux = HvAUX(PL_curstash);

        if(!aux->xhv_class_pending_method_cvs)
            aux->xhv_class_pending_method_cvs = newAV();

        av_push(aux->xhv_class_pending_method_cvs,
                SvREFCNT_inc_simple_NN((SV *)PL_compcv));
    }

    return o;
}

void
Perl_class_add_field(pTHX_ HV *stash, PADNAME *pn)
{
    PERL_ARGS_ASSERT_CLASS_ADD_FIELD;

    assert(HvSTASH_IS_CLASS_OR_ROLE(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    PADOFFSET relative_fieldix = aux->xhv_class_next_fieldix;
    aux->xhv_class_next_fieldix++;

    struct padname_fieldinfo *fieldinfo;
    Newxz(fieldinfo, 1, struct padname_fieldinfo);

    fieldinfo->refcount = 1;
    fieldinfo->relative_fieldix = relative_fieldix;
    fieldinfo->fieldix = (PADOFFSET)-1; /* sentinel; resolved at seal time */
    fieldinfo->fieldstash = HvREFCNT_inc(stash);

    PadnameFIELDINFO(pn) = fieldinfo;
    PadnameFLAGS(pn) |= PADNAMEf_FIELD;

    if(!aux->xhv_class_fields)
        aux->xhv_class_fields = newPADNAMELIST(0);

    padnamelist_store(aux->xhv_class_fields, PadnamelistMAX(aux->xhv_class_fields)+1, pn);
    PadnameREFCNT_inc(pn);

    /* Record in proto-role for composition algebra */
    if (aux->xhv_class_proto_role)
        proto_role_add_field(aux->xhv_class_proto_role, pn, ORIGIN_SET_EMPTY);
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
apply_field_attribute_param(pTHX_ PADNAME *pn, SV *value)
{
    if(!value)
        /* Default to name minus the sigil */
        value = newSVpvn_utf8(PadnamePV(pn) + 1, PadnameLEN(pn) - 1, PadnameUTF8(pn));

    if(PadnamePV(pn)[0] != '$')
        croak("Only scalar fields can take a :param attribute");

    if(PadnameFIELDINFO(pn)->paramname)
        croak("Field already has a parameter name, cannot add another");

    HV *stash = PadnameFIELDINFO(pn)->fieldstash;
    assert(HvSTASH_IS_CLASS_OR_ROLE(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    if(aux->xhv_class_param_map &&
            hv_exists_ent(aux->xhv_class_param_map, value, 0))
        croak("Cannot assign :param(%" SVf ") to field %" SVf " because that name is already in use",
                SVfARG(value), SVfARG(PadnameSV(pn)));

    PadnameFIELDINFO(pn)->paramname = SvREFCNT_inc(value);

    if(!aux->xhv_class_param_map)
        aux->xhv_class_param_map = newHV();

    /* Store into param_map for duplicate checking. The value is not
     * meaningful at this point (fieldix is unresolved); only the key's
     * existence matters for the duplicate check above.
     */
    (void)hv_store_ent(aux->xhv_class_param_map, value, newSVuv(0), 0);
}

static void
apply_field_attribute_reader(pTHX_ PADNAME *pn, SV *value)
{
    if(value)
        SvREFCNT_inc(value);
    else
        /* Default to name minus the sigil */
        value = newSVpvn_utf8(PadnamePV(pn) + 1, PadnameLEN(pn) - 1, PadnameUTF8(pn));

    if(!valid_identifier_sv(value))
        croak("%" SVf_QUOTEDPREFIX " is not a valid name for a generated method", value);

    I32 floor_ix = start_subparse(FALSE, 0);
    SAVEFREESV(PL_compcv);
    CvIsMETHOD_on(PL_compcv);

    I32 save_ix = block_start(TRUE);

    PADOFFSET padix;

    padix = pad_add_name_pvs("$self", 0, NULL, NULL);
    assert(padix == PADIX_SELF);

    padix = pad_add_name_pvs("$(params)", 0, NULL, NULL);
    assert(padix == PADIX_PARAMS);

    padix = pad_add_name_pvs("$(role_offset)", 0, NULL, NULL);
    assert(padix == PADIX_ROLE_OFFSET);

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
    if (cv) {
        CvIsMETHOD_on(cv);

        /* Record accessor in proto-role for composition algebra.
         * value was consumed by nameop, so use the CV's name. */
        if (HvSTASH_IS_CLASS_OR_ROLE(PL_curstash)) {
            struct xpvhv_aux *aux = HvAUX(PL_curstash);
            if (aux->xhv_class_proto_role) {
                SV *methname = newSVpvn_flags(
                    GvNAME(CvGV(cv)), GvNAMELEN(CvGV(cv)),
                    GvNAMEUTF8(CvGV(cv)) ? SVf_UTF8 : 0);
                proto_role_add_method(aux->xhv_class_proto_role,
                    methname, ORIGIN_SET_EMPTY, cv, pn);
                SvREFCNT_dec(methname); /* add_method incremented it */
            }
        }
    }
}

static void
apply_field_attribute_writer(pTHX_ PADNAME *pn, SV *value)
{
    char sigil = PadnamePV(pn)[0];
    if(sigil != '$')
        croak("Cannot apply a :writer attribute to a non-scalar field");

    if(value)
        SvREFCNT_inc(value);
    else {
        /* Default to "set_" . name minus the sigil */
        value = newSVpvs("set_");
        sv_catpvn_flags(value, PadnamePV(pn) + 1, PadnameLEN(pn) - 1,
                PadnameUTF8(pn) ? SV_CATUTF8 : 0);
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

    padix = pad_add_name_pvs("$(params)", 0, NULL, NULL);
    assert(padix == PADIX_PARAMS);

    padix = pad_add_name_pvs("$(role_offset)", 0, NULL, NULL);
    assert(padix == PADIX_ROLE_OFFSET);

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
    if (cv) {
        CvIsMETHOD_on(cv);

        /* Record accessor in proto-role for composition algebra */
        if (HvSTASH_IS_CLASS_OR_ROLE(PL_curstash)) {
            struct xpvhv_aux *aux = HvAUX(PL_curstash);
            if (aux->xhv_class_proto_role) {
                SV *methname = newSVpvn_flags(
                    GvNAME(CvGV(cv)), GvNAMELEN(CvGV(cv)),
                    GvNAMEUTF8(CvGV(cv)) ? SVf_UTF8 : 0);
                proto_role_add_method(aux->xhv_class_proto_role,
                    methname, ORIGIN_SET_EMPTY, cv, pn);
                SvREFCNT_dec(methname); /* add_method incremented it */
            }
        }
    }
}

static struct {
    const char *name;
    bool requires_value;
    void (*apply)(pTHX_ PADNAME *pn, SV *value);
} const field_attributes[] = {
    { .name           = "param",
      .requires_value = false,
      .apply          = &apply_field_attribute_param,
    },
    { .name           = "reader",
      .requires_value = false,
      .apply          = &apply_field_attribute_reader,
    },
    { .name           = "writer",
      .requires_value = false,
      .apply          = &apply_field_attribute_writer,
    },
    { NULL, false, NULL }
};

static void
S_class_apply_field_attribute(pTHX_ PADNAME *pn, OP *attr)
{
    assert(attr->op_type == OP_CONST);

    SV *name, *value;
    split_attr_nameval(cSVOPx_sv(attr), &name, &value);

    for(int i = 0; field_attributes[i].name; i++) {
        /* TODO: These attribute names are not UTF-8 aware */
        if(!strEQ(SvPVX(name), field_attributes[i].name))
            continue;

        if(field_attributes[i].requires_value && !(value && SvOK(value)))
            croak("Field attribute %" SVf " requires a value", SVfARG(name));

        (*field_attributes[i].apply)(aTHX_ pn, value);
        return;
    }

    croak("Unrecognized field attribute %" SVf, SVfARG(name));
}

void
Perl_class_apply_field_attributes(pTHX_ PADNAME *pn, OP *attrlist)
{
    PERL_ARGS_ASSERT_CLASS_APPLY_FIELD_ATTRIBUTES;

    if(!attrlist)
        return;
    if(attrlist->op_type == OP_NULL) {
        op_free(attrlist);
        return;
    }

    if(attrlist->op_type == OP_LIST) {
        OP *o = cLISTOPx(attrlist)->op_first;
        assert(o->op_type == OP_PUSHMARK);
        o = OpSIBLING(o);

        for(; o; o = OpSIBLING(o))
            S_class_apply_field_attribute(aTHX_ pn, o);
    }
    else
        S_class_apply_field_attribute(aTHX_ pn, attrlist);

    op_free(attrlist);
}

void
Perl_class_set_field_defop(pTHX_ PADNAME *pn, OPCODE defmode, OP *defop)
{
    PERL_ARGS_ASSERT_CLASS_SET_FIELD_DEFOP;

    assert(defmode == 0 || defmode == OP_ORASSIGN || defmode == OP_DORASSIGN);

    assert(HvSTASH_IS_CLASS_OR_ROLE(PL_curstash));

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

    assert(HvSTASH_IS_CLASS_OR_ROLE(stash));
    struct xpvhv_aux *aux = HvAUX(stash);

    if(!aux->xhv_class_adjust_blocks)
        aux->xhv_class_adjust_blocks = newAV();

    av_push(aux->xhv_class_adjust_blocks, (SV *)cv);

    /* Record in proto-role for composition algebra */
    if (aux->xhv_class_proto_role) {
        if (!aux->xhv_class_proto_role->adjust_blocks)
            aux->xhv_class_proto_role->adjust_blocks = newAV();
        av_push(aux->xhv_class_proto_role->adjust_blocks,
                SvREFCNT_inc_simple_NN((SV *)cv));
    }
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
