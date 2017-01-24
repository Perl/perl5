/*    hv_vtbl.h
 *
 *    Copyright (C) 2017 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

struct hv_vtbl {
    SV *	(*hvt_delete)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, I32 delete_flags, U32 hash);
};
typedef struct hv_vtbl HV_VTBL;

extern HV_VTBL PL_mock_std_vtable;


/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
