/*    attributes.c
 *
 *    Copyright (C) 2025-2026 by Paul Evans and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "EXTERN.h"
#define PERL_IN_ATTRIBUTES_C
#include "perl.h"

#define targetsv(target, type, attrname)  S_targetsv(aTHX_ target, type, attrname)
static SV *
S_targetsv(pTHX_ struct PerlAttributeTarget *target, U8 type, const char *attrname)
{
    SV *sv = NULL;
    switch(target->kind) {
        case PERL_ATTRTARGET_SV:        sv = target->sv;           break;
        case PERL_ATTRTARGET_PKGSCOPED: sv = target->pkgscoped.sv; break;
        case PERL_ATTRTARGET_LEXICAL:   sv = target->lexical.sv;   break;
    }
    assert(sv);
    switch(type) {
        case SVt_PVCV:
            if(SvTYPE(sv) != SVt_PVCV)
                croak("Can only apply the :%s attribute to CODE", attrname);
            break;
    }
    return sv;
}

/* :const */

static void
S_apply_attribute_const(pTHX_
        struct PerlAttributeTarget *target,
        SV *attrvalue, void *data)
{
    PERL_UNUSED_ARG(attrvalue);
    PERL_UNUSED_ARG(data);
    CV *cv = (CV *)targetsv(target, SVt_PVCV, "const");

    CvANONCONST_on(cv);
    if (!CvANON(cv))
        yyerror(":const is not permitted on named subroutines");
}

static const struct PerlAttributeDefinition attribute_const = {
    .flags = PERL_ATTRf_NO_VALUE,
    .apply = &S_apply_attribute_const,
};

/* :lvalue */

static void
S_apply_attribute_lvalue(pTHX_
        struct PerlAttributeTarget *target,
        SV *attrvalue, void *data)
{
    PERL_UNUSED_ARG(attrvalue);
    PERL_UNUSED_ARG(data);
    CV *cv = (CV *)targetsv(target, SVt_PVCV, "lvalue");

    CvLVALUE_on(cv);
}

static const struct PerlAttributeDefinition attribute_lvalue = {
    .flags = PERL_ATTRf_NO_VALUE,
    .apply = &S_apply_attribute_lvalue,
};

/* :method */

static void
S_apply_attribute_method(pTHX_
        struct PerlAttributeTarget *target,
        SV *attrvalue, void *data)
{
    PERL_UNUSED_ARG(attrvalue);
    PERL_UNUSED_ARG(data);
    CV *cv = (CV *)targetsv(target, SVt_PVCV, "method");

    CvNOWARN_AMBIGUOUS_on(cv);
}

static const struct PerlAttributeDefinition attribute_method = {
    .flags = PERL_ATTRf_NO_VALUE,
    .apply = &S_apply_attribute_method,
};

static const struct {
    const char *name;
    const struct PerlAttributeDefinition *def;
} builtin_attributes[] = {
    { .name = "const",  .def = &attribute_const },
    { .name = "lvalue", .def = &attribute_lvalue },
    { .name = "method", .def = &attribute_method },
    {0},
};

#define split_attr_nameval(sv, namp, valp)  S_split_attr_nameval(aTHX_ sv, namp, valp)
static void
S_split_attr_nameval(pTHX_ SV *sv, SV **namp, SV **valp)
{
    STRLEN svlen = SvCUR(sv);
    bool do_utf8 = SvUTF8(sv);

    const char *paren_at = (const char *)memchr(SvPVX(sv), '(', svlen);
    if(paren_at) {
        STRLEN namelen = paren_at - SvPVX(sv);

        if(SvPVX(sv)[svlen-1] != ')')
            /* Should be impossible to reach this by parsing regular perl code
             * but as apply_attributes() is XS-visible API it might still
             * be reachable. As it's likely unreachable by normal perl code,
             * don't bother listing it in perldiag.
             */
            /* diag_listed_as: SKIPME */
            croak("Malformed attribute string");
        *namp = sv_2mortal(newSVpvn_utf8(SvPVX(sv), namelen, do_utf8));

        const char *value_at = paren_at + 1;
        const char *value_max = SvPVX(sv) + svlen - 2;

        /* TODO: We're only obeying ASCII whitespace here */

        /* Trim whitespace at the start */
        while(value_at < value_max && isSPACE(*value_at))
            value_at += 1;
        while(value_max > value_at && isSPACE(*value_max))
            value_max -= 1;

        if(value_max >= value_at)
            *valp = sv_2mortal(newSVpvn_utf8(value_at, value_max - value_at + 1, do_utf8));
        else
            *valp = NULL;
    }
    else {
        *namp = sv;
        *valp = NULL;
    }
}

#define targetname(target)  S_targetname(aTHX_ target)
static const char *
S_targetname(pTHX_ struct PerlAttributeTarget *target)
{
    SV *sv = NULL;
    switch(target->kind) {
        case PERL_ATTRTARGET_SV:        sv = target->sv;           break;
        case PERL_ATTRTARGET_PKGSCOPED: sv = target->pkgscoped.sv; break;
        case PERL_ATTRTARGET_LEXICAL:   sv = target->lexical.sv;   break;
    }
    assert(sv);
    U8 svt = SvTYPE(sv);
    if(svt <= SVt_PVMG)
        return "SCALAR";
    switch(svt) {
        case SVt_PVAV: return "ARRAY";
        case SVt_PVHV: if(HvNAME((HV *)sv)) return "package";
                       return "HASH";
        case SVt_PVCV: return "CODE";
    }
    return "UNKNOWN";
}

/* Possible behaviours to tell S_apply_attribute what to do with a request for
 * an attribute that isn't in the builtin list
 */
enum {
    UNKNOWN_RETURN,   /* return the unrecognised ones */
    UNKNOWN_ERROR,    /* throw an exception */
};

static bool
S_apply_attribute(pTHX_ struct PerlAttributeTarget *target, OP *attr, int unknown)
{
    assert(attr->op_type == OP_CONST);
    assert(target->kind);

    SV *name, *value;
    split_attr_nameval(cSVOPx_sv(attr), &name, &value);

    const char *namepv = SvPVX(name);

    /* TODO: Hunt in lexical pads first, before falling back to global table.
     * The idea is to look for a lexical named `:$attrname`, whose value will
     * be some special SV type that contains the
     * struct PerlAttributeDefinition value directly. But we'd need an SV type
     * for that first, and to ensure all the other bits of pad infrastructure
     * can cope with these new `:` sigils.
     */

    for(int i = 0; builtin_attributes[i].name; i++) {
        /* These attribute names are not UTF-8 aware. All the builtin ones
         * are pure ASCII so that's fine and hopefully the pad structure can
         * handle non-ASCII user-defined ones. */
        if(!strEQ(namepv, builtin_attributes[i].name))
            continue;

        const struct PerlAttributeDefinition *def = builtin_attributes[i].def;

        if(def->flags & PERL_ATTRf_MUST_VALUE && !(value && SvOK(value)))
            croak("Attribute :%" SVf " on %s requires a value", SVfARG(name), targetname(target));
        if(def->flags & PERL_ATTRf_NO_VALUE && value && SvOK(value))
            croak("Attribute :%" SVf " on %s does not take a value", SVfARG(name), targetname(target));

        (*def->apply)(aTHX_ target, value, NULL);
        return true;
    }

    switch(unknown) {
        case UNKNOWN_RETURN:
            return false;

        case UNKNOWN_ERROR:
            croak("Unrecognized attribute :%" SVf " on %s", SVfARG(name), targetname(target));

        default:
            NOT_REACHED;
    }
}

/* TODO(leonerd): Ugh, while the code is in a state of being rearranged, the
 * calling conventions here are going to look messy.
 * I hope to have that all tidied up by the time this branch work is finished.
 *
 * If unknown==UNKNOWN_RETURN, the attrlist is consumed by this function, and a
 *   possibly smaller sublist of filtered elements is returned
 * If unknown!=UNKNOWN_RETURN, the attrlist is regarded as read-only, not
 *   modified, and it is the caller's responsibility to free it when finished
 */
static OP *
S_apply_attributes(pTHX_ struct PerlAttributeTarget *target, OP *attrlist, int unknown)
{
    const bool must_free_attrlist = (unknown == UNKNOWN_RETURN);

    if(!attrlist)
        return NULL;
    if(attrlist->op_type == OP_NULL) {
        if(must_free_attrlist)
            op_free(attrlist);
        return NULL;
    }

    if(attrlist->op_type != OP_LIST) {
        /* Not in fact a list but just a single attribute */
        if(S_apply_attribute(aTHX_ target, attrlist, unknown)) {
            if(must_free_attrlist)
                op_free(attrlist);
            return NULL;
        }

        return attrlist;
    }

    OP *prev = cLISTOPx(attrlist)->op_first;
    assert(prev->op_type == OP_PUSHMARK);
    OP *o = OpSIBLING(prev);

    OP *next;
    for(; o; o = next) {
        next = OpSIBLING(o);

        if(S_apply_attribute(aTHX_ target, o, unknown)) {
            if(must_free_attrlist) {
                op_sibling_splice(attrlist, prev, 1, NULL);
                op_free(o);
            }
        }
        else {
            prev = o;
        }
    }

    if(OpHAS_SIBLING(cLISTOPx(attrlist)->op_first))
        return attrlist;

    if(must_free_attrlist)
        /* The list is now entirely empty, we might as well discard it */
        op_free(attrlist);

    return NULL;
}

// Caller must free attrlist
void
Perl_apply_attributes_sv(pTHX_ SV *sv, OP *attrlist)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTES_SV;

    struct PerlAttributeTarget target = {
        .kind = PERL_ATTRTARGET_SV,
        .sv   = sv,
    };
    /* UNKNOWN_ERROR means there won't ever be a return value; we can
     * ignore it
     */
    (void)S_apply_attributes(aTHX_ &target, attrlist, UNKNOWN_ERROR);
}

// Caller must free attrlist
void
Perl_apply_attributes_pkgscoped(pTHX_ SV *sv, GV *namegv, OP *attrlist)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTES_PKGSCOPED;

    struct PerlAttributeTarget target = {
        .kind = PERL_ATTRTARGET_PKGSCOPED,
        .pkgscoped = {
            .sv     = sv,
            .namegv = namegv,
        },
    };
    /* UNKNOWN_ERROR means there won't ever be a return value; we can
     * ignore it
     */
    (void)S_apply_attributes(aTHX_ &target, attrlist, UNKNOWN_ERROR);
}

// Caller must free attrlist
void
Perl_apply_attributes_lexical(pTHX_ PADOFFSET padix, OP *attrlist)
{
    PERL_ARGS_ASSERT_APPLY_ATTRIBUTES_LEXICAL;

    struct PerlAttributeTarget target = {
        .kind        = PERL_ATTRTARGET_LEXICAL,
        .lexical = {
            .sv      = PadARRAY(PL_comppad)[padix],
            .padix   = padix,
            .padname = PadnamelistARRAY(PL_comppad_name)[padix],
        },
    };
    /* UNKNOWN_ERROR means there won't ever be a return value; we can
     * ignore it
     */
    (void)S_apply_attributes(aTHX_ &target, attrlist, UNKNOWN_ERROR);
}

/*
=for apidoc apply_builtin_cv_attributes

Given an OP_LIST containing attribute definitions, filter it for known builtin
attributes to apply to the cv, returning a possibly-smaller list containing
just the remaining ones. Any recognised attributes in I<attrlist> are consumed
by this function.

=cut
*/

OP *
Perl_apply_builtin_cv_attributes(pTHX_ CV *cv, OP *attrlist)
{
    PERL_ARGS_ASSERT_APPLY_BUILTIN_CV_ATTRIBUTES;

    struct PerlAttributeTarget target = {
        .kind = PERL_ATTRTARGET_SV,
        .sv   = (SV *)cv,
    };
    return S_apply_attributes(aTHX_ &target, attrlist, UNKNOWN_RETURN);
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
