/*    attributes.h
 *
 *    Copyright (C) 2025, by Paul Evans and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

enum {
    PERL_ATTRf_MAY_VALUE  = 0,
    PERL_ATTRf_NO_VALUE   = (1<<0),
    PERL_ATTRf_MUST_VALUE = (1<<1),
};

enum PerlAttributeTargetKind {
    /* avoid zero */
    PERL_ATTRTARGET_SV = 1, /* a direct SV of unknown storage. we should try to avoid this */
    PERL_ATTRTARGET_PKGSCOPED,
    PERL_ATTRTARGET_LEXICAL,
};

struct PerlAttributeTarget {
    enum PerlAttributeTargetKind kind;
    union {
        SV *sv;
        struct { SV *sv; GV *namegv;                        } pkgscoped;
        struct { SV *sv; PADOFFSET padix; PADNAME *padname; } lexical;
    };
};

struct PerlAttributeDefinition
{
    U32 ver;
    U32 flags;
    SV * (*parse)(pTHX_ const SV *text, void *data);   /* optional, may be NULL */
    void (*apply)(pTHX_ struct PerlAttributeTarget *target,
            SV *attrvalue, void *data);
};

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
