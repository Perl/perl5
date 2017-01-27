/*    hv_vtbl.h
 *
 *    Copyright (C) 2017 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

struct hv_vtbl {
    /* Called when allocating a new HV of this type */
    void	(*hvt_init)(pTHX_ HV *hv);
    /* Called before deallocating the HV in the traditional HV implementation. */
    void	(*hvt_destroy)(pTHX_ HV *hv);

    /* Implements hv_fetch (and hv_fetchs) */
    SV **	(*hvt_fetch)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, I32 is_lvalue_fetch, U32 hash);
    /* Implements hv_fetch_ent */
    /* fetch_flags can contain at least HV_FETCH_LVALUE and HV_FETCH_EMPTY_HE */
    HE *	(*hvt_fetch_ent)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, I32 fetch_flags, U32 hash);

    /* store */

    /* Implements the equivalent of hv_exists(_ent) */
    bool	(*hvt_exists)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, U32 hash);
    /* Implements the various forms of hv_delete/etc */
    SV *	(*hvt_delete)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, int delete_flags, U32 hash);
    /* Implements the equivalent of hv_clear */
    void	(*hvt_clear)(pTHX_ HV *hv);
};
typedef struct hv_vtbl HV_VTBL;

extern HV_VTBL PL_mock_std_vtable;


/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
