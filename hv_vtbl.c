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

/*
STATIC SV **
S_hv_mock_std_vtable_fetch(pTHX_ HV *hv, SV *keysv, const char *key,
                            STRLEN klen, int key_flags,
                            I32 is_lvalue_fetch, U32 hash)
{
    return NULL;
}
*/

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

HV_VTBL PL_mock_std_vtable = {
        S_hv_mock_std_vtable_init,
        S_hv_mock_std_vtable_destroy,
        /* S_hv_mock_std_vtable_fetch, */
        S_hv_mock_std_vtable_exists,
	S_hv_mock_std_vtable_delete,
	S_hv_mock_std_vtable_clear
};

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
