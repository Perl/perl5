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
    PADIX_SELF = 1,
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

    Newx(ObjectFIELDS(sv), fieldcount, SV *);
    ObjectMAXFIELD(sv) = fieldcount - 1;

    Zero(ObjectFIELDS(sv), fieldcount, SV *);

    return sv;
}

#define make_instance_fields(stash, instance)  S_make_instance_fields(aTHX_ stash, instance)
static void S_make_instance_fields(pTHX_ HV *stash, SV *instance)
{
    struct xpvhv_aux *aux = HvAUX(stash);

    if(aux->xhv_class_superclass) {
        make_instance_fields(aux->xhv_class_superclass, instance);
    }

    SV **fields = ObjectFIELDS(instance);

    PADNAMELIST *fieldnames = aux->xhv_class_fields;

    for(U32 i = 0; fieldnames && i <= PadnamelistMAX(fieldnames); i++) {
        PADNAME *pn = PadnamelistARRAY(fieldnames)[i];
        PADOFFSET fieldix = PadnameFIELDINFO(pn)->fieldix;

        SV *val = NULL;

        switch(PadnamePV(pn)[0]) {
            case '$':
                val = newSV(0);
                break;

            case '@':
                val = (SV *)newAV();
                break;

            case '%':
                val = (SV *)newHV();
                break;

            default:
                NOT_REACHED;
        }

        fields[fieldix] = val;
    }
}

XS(injected_constructor);
XS(injected_constructor)
{
    dXSARGS;

    HV *stash = (HV *)XSANY.any_ptr;
    assert(HvSTASH_IS_CLASS(stash));

    struct xpvhv_aux *aux = HvAUX(stash);

    if((items - 1) % 2)
        Perl_warn(aTHX_ "Odd number of arguments passed to %" HvNAMEf_QUOTEDPREFIX " constructor",
                HvNAMEfARG(stash));

    HV *params = NULL;
    {
        /* Set up params HV */
        params = newHV();
        SAVEFREESV((SV *)params);

        for(I32 i = 1; i < items; i += 2) {
            SV *name = ST(i);
            SV *val  = (i+1 < items) ? ST(i+1) : &PL_sv_undef;

            /* TODO: think about sanity-checking name for being 
             *   defined
             *   not ref (but overloaded objects?? boo)
             *   not duplicate
             * But then,  %params = @_;  wouldn't do that
             */

            hv_store_ent(params, name, SvREFCNT_inc(val), 0);
        }
    }

    SV *instance = newSVobject(aux->xhv_class_next_fieldix);
    SvOBJECT_on(instance);
    SvSTASH_set(instance, MUTABLE_HV(SvREFCNT_inc_simple(stash)));

    make_instance_fields(stash, instance);

    SV *self = sv_2mortal(newRV_noinc(instance));

    if(aux->xhv_class_adjust_blocks) {
        CV **cvp = (CV **)AvARRAY(aux->xhv_class_adjust_blocks);
        U32 nblocks = av_count(aux->xhv_class_adjust_blocks);

        for(U32 i = 0; i < nblocks; i++) {
            ENTER;
            SAVETMPS;
            SPAGAIN;

            EXTEND(SP, 1);

            PUSHMARK(SP);
            PUSHs(self);  /* I don't believe this needs to be an sv_mortalcopy() */
            PUTBACK;

            call_sv((SV *)cvp[i], G_VOID);

            SPAGAIN;

            FREETMPS;
            LEAVE;
        }
    }

    if(params && hv_iterinit(params) > 0) {
        /* TODO: consider sorting these into a canonical order, but that's awkward */
        HE *he = hv_iternext(params);

        SV *paramnames = newSVsv(HeSVKEY_force(he));
        SAVEFREESV(paramnames);

        while((he = hv_iternext(params)))
            Perl_sv_catpvf(aTHX_ paramnames, ", %" SVf, SVfARG(HeSVKEY_force(he)));

        croak("Unrecognised parameters for %" HvNAMEf_QUOTEDPREFIX " constructor: %" SVf,
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
    SV *self = av_shift(GvAV(PL_defgv));
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

    save_clearsv(&PAD_SVl(PADIX_SELF));
    sv_setsv(PAD_SVl(PADIX_SELF), self);

    UNOP_AUX_item *aux = cUNOP_AUX->op_aux;
    if(aux) {
        assert(SvTYPE(SvRV(self)) == SVt_PVOBJ);
        SV *instance = SvRV(self);
        SV **fieldp = ObjectFIELDS(instance);

        U32 fieldcount = (aux++)->uv;
        U32 max_fieldix = (aux++)->uv;

        assert(ObjectMAXFIELD(instance)+1 > max_fieldix);
        PERL_UNUSED_VAR(max_fieldix);

        for(Size_t i = 0; i < fieldcount; i++) {
            PADOFFSET padix   = (aux++)->uv;
            U32       fieldix = (aux++)->uv;

            assert(fieldp[fieldix]);

            /* TODO: There isn't a convenient SAVE macro for doing both these
             * steps in one go. Add one. */
            SAVESPTR(PAD_SVl(padix));
            SV *sv = PAD_SVl(padix) = SvREFCNT_inc(fieldp[fieldix]);
            save_freesv(sv);
        }
    }

    return NORMAL;
}

static void
invoke_class_seal(pTHX_ void *_arg)
{
    class_seal_stash((HV *)_arg);
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
        CvXSUBANY(newcv).any_ptr = stash;
    }

    /* TODO:
     *   DOES method
     */

    struct xpvhv_aux *aux = HvAUX(stash);
    aux->xhv_class_superclass    = NULL;
    aux->xhv_class_adjust_blocks = NULL;
    aux->xhv_class_fields        = NULL;
    aux->xhv_class_next_fieldix  = 0;

    aux->xhv_aux_flags |= HvAUXf_IS_CLASS;

    SAVEDESTRUCTOR_X(invoke_class_seal, stash);
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

    while(*p && isSPACE_utf8_safe(p, end))
        p += UTF8SKIP(p);

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

    while(*p && isSPACE_utf8_safe(p, end))
        p += UTF8SKIP(p);

    return p;
}

#define ensure_module_version(module, version)  S_ensure_module_version(aTHX_ module, version)
static void S_ensure_module_version(pTHX_ SV *module, SV *version)
{
    dSP;

    ENTER;

    PUSHMARK(SP);
    PUSHs(module);
    PUSHs(version);
    PUTBACK;

    call_method("VERSION", G_VOID);

    LEAVE;
}

static void
apply_class_attribute_isa(pTHX_ HV *stash, SV *value)
{
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
    if(!superstash) {
        /* Try to `require` the module then attempt a second time */
        load_module(PERL_LOADMOD_NOIMPORT, newSVsv(superclassname), NULL, NULL);
        superstash = gv_stashsv(superclassname, 0);
    }
    if(!superstash || !HvSTASH_IS_CLASS(superstash))
        /* TODO: This would be a useful feature addition */
        croak("Class :isa attribute requires a class but %" HvNAMEf_QUOTEDPREFIX " is not one",
            HvNAMEfARG(superstash));

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

    aux->xhv_class_next_fieldix = superaux->xhv_class_next_fieldix;

    if(superaux->xhv_class_adjust_blocks) {
        if(!aux->xhv_class_adjust_blocks)
            aux->xhv_class_adjust_blocks = newAV();

        for(U32 i = 0; i <= AvFILL(superaux->xhv_class_adjust_blocks); i++)
            av_push(aux->xhv_class_adjust_blocks, AvARRAY(superaux->xhv_class_adjust_blocks)[i]);
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
    {0}
};

static void
S_class_apply_attribute(pTHX_ HV *stash, OP *attr)
{
    assert(attr->op_type == OP_CONST);
    SV *sv = cSVOPx_sv(attr);
    STRLEN svlen = SvCUR(sv);

    /* Split the sv into name + arguments. */
    SV *name, *value = NULL;
    char *paren_at = (char *)memchr(SvPVX(sv), '(', svlen);
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
        name = sv_2mortal(newSVpvn(SvPVX(sv), namelen));

        char *value_at = paren_at + 1;
        char *value_max = SvPVX(sv) + svlen - 2;

        /* TODO: We're only obeying ASCII whitespace here */

        /* Trim whitespace at the start */
        while(value_at < value_max && isSPACE(*value_at))
            value_at += 1;
        while(value_max > value_at && isSPACE(*value_max))
            value_max -= 1;

        if(value_max >= value_at)
            value = sv_2mortal(newSVpvn(value_at, value_max - value_at + 1));
    }
    else {
        name = sv;
    }

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

    if(attrlist->op_type == OP_LIST) {
        OP *o = cLISTOPx(attrlist)->op_first;
        assert(o->op_type == OP_PUSHMARK);
        o = OpSIBLING(o);

        for(; o; o = OpSIBLING(o))
            S_class_apply_attribute(aTHX_ stash, o);
    }
    else
        S_class_apply_attribute(aTHX_ stash, attrlist);
}

void
Perl_class_seal_stash(pTHX_ HV *stash)
{
    PERL_ARGS_ASSERT_CLASS_SEAL_STASH;

    /* TODO: anything? */
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

OP *
Perl_class_wrap_method_body(pTHX_ OP *o)
{
    PERL_ARGS_ASSERT_CLASS_WRAP_METHOD_BODY;

    if(!o)
        return o;

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

        av_push(fieldmap, newSVuv(padix));
        av_push(fieldmap, newSVuv(fieldix));
    }

    UNOP_AUX_item *aux = NULL;

    if(av_count(fieldmap)) {
        Newx(aux, 2 + av_count(fieldmap), UNOP_AUX_item);

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

    Newx(PadnameFIELDINFO(pn), 1, struct padname_fieldinfo);
    PadnameFLAGS(pn) |= PADNAMEf_FIELD;

    PadnameFIELDINFO(pn)->fieldix = fieldix;
    PadnameFIELDINFO(pn)->fieldstash = (HV *)SvREFCNT_inc(stash);

    if(!aux->xhv_class_fields)
        aux->xhv_class_fields = newPADNAMELIST(0);

    padnamelist_store(aux->xhv_class_fields, PadnamelistMAX(aux->xhv_class_fields)+1, pn);
    PadnameREFCNT_inc(pn);
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

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
