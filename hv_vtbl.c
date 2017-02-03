/*    hv_vtbl.c
 *
 *    Copyright (C) 2017 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/* TODO: Insert LotR quote here. */

#include "EXTERN.h"
#define PERL_IN_HV_VTBL_C
#define PERL_HASH_INTERNAL_ACCESS
#include "perl.h"

STATIC void
S_hv_mock_std_vtable_init(pTHX_ HV *hv)
{
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(hv);
}

STATIC void
S_hv_mock_std_vtable_destroy(pTHX_ HV *hv)
{
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(hv);
}

STATIC SV *
S_hv_mock_std_vtable_delete(pTHX_ HV *hv, SV *keysv, const char *key,
                            STRLEN klen, int key_flags, int delete_flags,
                            U32 hash)
{
    SV *retval;

    /* THIS IS PURELY FOR TESTING! */
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    ENTER;
    /* localize vtable such that hv_common takes the normal code path */
    SAVEPPTR(vtable);

    xhv->xhv_vtbl = NULL;
    retval = MUTABLE_SV(hv_common(hv, keysv, key, klen, key_flags, delete_flags, NULL, hash));

    LEAVE;

    return retval;
}

STATIC void
S_hv_mock_std_vtable_clear(pTHX_ HV *hv)
{
    /* THIS IS PURELY FOR TESTING! */
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    ENTER;
    /* localize vtable such that hv_clear takes the normal code path */
    SAVEPPTR(vtable);

    xhv->xhv_vtbl = NULL;
    hv_clear(hv);

    LEAVE;
}

STATIC void
S_hv_mock_std_vtable_undef(pTHX_ HV *hv, U32 flags)
{
    /* THIS IS PURELY FOR TESTING! */
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    ENTER;
    /* localize vtable such that hv_undef takes the normal code path */
    SAVEPPTR(vtable);

    xhv->xhv_vtbl = NULL;
    /* FIXME find a way to ditch "flags"... */
    Perl_hv_undef_flags(pTHX_ hv, flags);

    LEAVE;
}

STATIC SV **
S_hv_mock_std_vtable_fetch(pTHX_ HV *hv, SV *keysv, const char *key,
                            STRLEN klen, int key_flags,
                            I32 is_lvalue_fetch, U32 hash)
{
    /* THIS IS PURELY FOR TESTING! */
    SV **retval;
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    /* Assert that this is the only flag we're getting */
    assert((is_lvalue_fetch & ~(HV_FETCH_LVALUE) ) == 0);

    ENTER;
    /* localize vtable such that hv_common takes the normal code path */
    SAVEPPTR(vtable);
    xhv->xhv_vtbl = NULL;

    /* Technically the hv_fetch interface only accepts char/len but not the keysv
     * variant. I think hv_common supports both, so it seems sensible to allow
     * both usages. TODO re-evaluate this. */
    if (keysv) {
        retval = (SV **)hv_common(hv, keysv, key, klen, key_flags,
                                  is_lvalue_fetch
                                    ? HV_FETCH_JUST_SV | HV_FETCH_LVALUE
                                    : HV_FETCH_JUST_SV,
                                  NULL, hash);
    }
    else {
        /* reverse what hv_common_key_len does before calling hv_common... sigh */
        I32 my_klen = (key_flags & HVhek_UTF8) ? -(I32)klen : (I32)klen;
        retval = (SV **)hv_common_key_len(hv, key, my_klen,
                                          is_lvalue_fetch
                                            ? HV_FETCH_JUST_SV | HV_FETCH_LVALUE
                                            : HV_FETCH_JUST_SV,
                                          NULL, hash);
    }

    LEAVE;

    return retval;
}

/* TODO Returning a HE* is problematic for a pluggable hash implementation
 *      since HE's are specific to perl's default implementation. So a wildly
 *      different hash implementation would have to fake up HE's here. Sigh.
 *      Options? Slowly try to move all uses to use the SV-fetching variant
 *      instead? (But I assume there's some very good reasons why many places
 *      would fetch HE's.)
 */
STATIC HE *
S_hv_mock_std_vtable_fetch_ent(pTHX_ HV *hv, SV *keysv, const char *key,
                                STRLEN klen, int key_flags,
                                I32 fetch_flags, U32 hash)
{
    /* THIS IS PURELY FOR TESTING! */
    HE *retval;
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    /* Assert that this is the only flags we're getting */
    assert((fetch_flags & ~(HV_FETCH_LVALUE|HV_FETCH_EMPTY_HE) ) == 0);

    ENTER;
    /* localize vtable such that hv_common takes the normal code path */
    SAVEPPTR(vtable);
    xhv->xhv_vtbl = NULL;

    retval = (HE *)hv_common(hv, keysv, key, klen, key_flags,
                             fetch_flags, NULL, hash);

    LEAVE;

    return retval;
}

STATIC SV **
S_hv_mock_std_vtable_store(pTHX_ HV *hv, SV *keysv,
                            const char *key, STRLEN klen, int key_flags,
                            SV *val, U32 hash)
{
    /* THIS IS PURELY FOR TESTING! */
    SV **retval;
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    ENTER;
    /* localize vtable such that hv_common takes the normal code path */
    SAVEPPTR(vtable);
    xhv->xhv_vtbl = NULL;

    {
        retval = (SV **)hv_common(hv, keysv, key, klen, key_flags,
                                  HV_FETCH_ISSTORE|HV_FETCH_JUST_SV,
                                  val, hash);
    }

    LEAVE;

    return retval;
}



/* TODO Returning a HE* is problematic for a pluggable hash implementation
 *      since HE's are specific to perl's default implementation. So a wildly
 *      different hash implementation would have to fake up HE's here. Sigh.
 *      Options? Slowly try to move all uses to use the SV-fetching variant
 *      instead? (But I assume there's some very good reasons why many places
 *      would fetch HE's.)
 */
STATIC HE *
S_hv_mock_std_vtable_store_ent(pTHX_ HV *hv, SV *keysv,
                               const char *key, STRLEN klen, int key_flags,
                               SV *val, U32 hash)
{
    /* THIS IS PURELY FOR TESTING! */
    HE *retval;
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    ENTER;
    /* localize vtable such that hv_common takes the normal code path */
    SAVEPPTR(vtable);
    xhv->xhv_vtbl = NULL;

    retval = (HE *)hv_common(hv, keysv, key, klen, key_flags,
                             HV_FETCH_ISSTORE, val, hash);

    LEAVE;

    return retval;
}


STATIC bool
S_hv_mock_std_vtable_exists(pTHX_ HV *hv, SV *keysv, const char *key,
                            STRLEN klen, int key_flags, U32 hash)
{
    /* THIS IS PURELY FOR TESTING! */
    bool retval;
    XPVHV* xhv = (XPVHV *)SvANY(hv);
    HV_VTBL *vtable = xhv->xhv_vtbl;

    ENTER;
    /* localize vtable such that hv_clear takes the normal code path */
    SAVEPPTR(vtable);
    xhv->xhv_vtbl = NULL;

    retval = cBOOL(hv_common(hv, keysv, key, klen, key_flags, HV_FETCH_ISEXISTS, NULL, hash));

    LEAVE;

    return retval;
}

STATIC STRLEN
S_hv_mock_std_vtable_totalkeys(pTHX_ HV *hv)
{
    return ((XPVHV *)SvANY(hv))->xhv_keys;
}

STATIC STRLEN
S_hv_mock_std_vtable_usedkeys(pTHX_ HV *hv)
{
    /* total keys minus placeholders */
    return ((XPVHV *)SvANY(hv))->xhv_keys - HvPLACEHOLDERS_get(hv);
}

HV_VTBL PL_mock_std_vtable = {
        S_hv_mock_std_vtable_init,
        S_hv_mock_std_vtable_destroy,
        S_hv_mock_std_vtable_fetch,
        S_hv_mock_std_vtable_fetch_ent,
        S_hv_mock_std_vtable_store,
        S_hv_mock_std_vtable_store_ent,
        S_hv_mock_std_vtable_exists,
	S_hv_mock_std_vtable_delete,
	S_hv_mock_std_vtable_clear,
        S_hv_mock_std_vtable_undef,
        S_hv_mock_std_vtable_totalkeys,
        S_hv_mock_std_vtable_usedkeys
};

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
