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

    /* Implements hv_store (and hv_stores) */
    SV **	(*hvt_store)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, SV *val, U32 hash);
    /* Implements hv_store_ent */
    HE *	(*hvt_store_ent)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, SV *val, U32 hash);

    /* Implements the equivalent of hv_exists(_ent) */
    bool	(*hvt_exists)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, U32 hash);
    /* Implements the various forms of hv_delete/etc */
    SV *	(*hvt_delete)(pTHX_ HV *hv, SV *keysv, const char *key, STRLEN klen, int key_flags, int delete_flags, U32 hash);
    /* Implements the equivalent of hv_clear */
    void	(*hvt_clear)(pTHX_ HV *hv);

    /* Implements the equivalent of hv_undef (which should be at least including all that hv_clear does). */
    /* FIXME Perl_hv_undef_flags() has a flags parameter that is used when called from sv_clear, which
     *       seems to be a "no, really do away with everything" sort of corner case. Need to understand
     *       significance for this much better. Is that just for stashes? But really, I'd hate to expose
     *       some internal hack. Needs more thinking! */
    void	(*hvt_undef)(pTHX_ HV *hv, U32 flags);

    /* Implements newHVhv. It's undocumented (and barely used in core), but it's used somewhat widely
     * on CPAN. Sigh. Appears to be doing a "clone this hash without copying any magic". */
    HV *        (*hvt_clone)(pTHX_ HV *hv);

    /* Returns the total number of keys (including placeholders) */
    /* FIXME there's code that uses HvTOTALKEYS in lvalue context, eg. for hash cloning.
     *       CPAN doesn't really have anything that does that legitimately, but it exists
     *       in core.
     *       The issue is that depending on the hash implementation, such a thing is completely
     *       nonsensical, so simply exposing some potential HvTOTALKEYS_set API wouldn't make sense! */
    STRLEN	(*hvt_totalkeys)(pTHX_ HV *hv);
    /* Returns the number of keys used (ie. not including placeholders) */
    STRLEN	(*hvt_usedkeys)(pTHX_ HV *hv);
    /* Wraps hv_iterinit */
    I32		(*hvt_iterinit)(pTHX_ HV *hv);

    /* TODO also wrap all the iteration primitives! */
    /* TODO research what other primitives are missing! */
    /* TODO what about all the hash introspection macros like HvTOTALKEYS? etc etc? */
    /* TODO newHVhv for copying hashes? Can we provide a (potentially inefficient) default
     *      implementation of this so that not everyone has to reimplement before they can
     *      even test their data structure? */
    /* TODO What about hv_fill? Should we even bother implementing that? Or provide a default
     *      that returns 0? (IOW 'talk to the hand')? */
    /* TODO What about the "hash name" related stuff (for stashes?)? */
    /* TODO what about hv_magic? */
    /* TODO what about placeholders? */

    /* TODO once 'everything' is wrapped, one way to test is to use the mock vtbl implementation
     *      to 'move' or 'rotate' all struct members in some well-defined way that can be undone
     *      by the wrapper (using SAVEDESTRUCTOR and LEAVE for example to redo it). That way,
     *      one can test if all hash accesses are actually going through the wrappers. */
};
typedef struct hv_vtbl HV_VTBL;

extern HV_VTBL PL_mock_std_vtable;

/* TODO add apidoc */
#define HvVTBL(hv)      (((XPVHV*)SvANY((hv)))->xhv_vtbl)
#define HvBODYVTBL(xhv) ((xhv)->xhv_vtbl)

#define HvHASVTBL(hv)       (HvVTBL(hv) != NULL)
#define HvBODYHASVTBL(xhv)  (HvBODYVTBL(xhv) != NULL)


/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
