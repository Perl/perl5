/*    hv.c
 *
 *    Copyright (c) 1991-2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "I sit beside the fire and think of all that I have seen."  --Bilbo
 */

#include "EXTERN.h"
#define PERL_IN_HV_C
#include "perl.h"


STATIC HE*
S_new_he(pTHX)
{
    HE* he;
    LOCK_SV_MUTEX;
    if (!PL_he_root)
        more_he();
    he = PL_he_root;
    PL_he_root = HeNEXT(he);
    UNLOCK_SV_MUTEX;
    return he;
}

STATIC void
S_del_he(pTHX_ HE *p)
{
    LOCK_SV_MUTEX;
    HeNEXT(p) = (HE*)PL_he_root;
    PL_he_root = p;
    UNLOCK_SV_MUTEX;
}

STATIC void
S_more_he(pTHX)
{
    register HE* he;
    register HE* heend;
    XPV *ptr;
    New(54, ptr, 1008/sizeof(XPV), XPV);
    ptr->xpv_pv = (char*)PL_he_arenaroot;
    PL_he_arenaroot = ptr;

    he = (HE*)ptr;
    heend = &he[1008 / sizeof(HE) - 1];
    PL_he_root = ++he;
    while (he < heend) {
        HeNEXT(he) = (HE*)(he + 1);
        he++;
    }
    HeNEXT(he) = 0;
}

#ifdef PURIFY

#define new_HE() (HE*)safemalloc(sizeof(HE))
#define del_HE(p) safefree((char*)p)

#else

#define new_HE() new_he()
#define del_HE(p) del_he(p)

#endif

STATIC HEK *
S_save_hek(pTHX_ const char *str, I32 len, U32 hash)
{
    char *k;
    register HEK *hek;
    bool is_utf8 = FALSE;

    if (len < 0) {
      len = -len;
      is_utf8 = TRUE;
    }

    New(54, k, HEK_BASESIZE + len + 1, char);
    hek = (HEK*)k;
    Copy(str, HEK_KEY(hek), len, char);
    HEK_LEN(hek) = len;
    HEK_HASH(hek) = hash;
    HEK_UTF8(hek) = (char)is_utf8;
    return hek;
}

void
Perl_unshare_hek(pTHX_ HEK *hek)
{
    unsharepvn(HEK_KEY(hek),HEK_UTF8(hek)?-HEK_LEN(hek):HEK_LEN(hek),
		HEK_HASH(hek));
}

#if defined(USE_ITHREADS)
HE *
Perl_he_dup(pTHX_ HE *e, bool shared)
{
    HE *ret;

    if (!e)
	return Nullhe;
    /* look for it in the table first */
    ret = (HE*)ptr_table_fetch(PL_ptr_table, e);
    if (ret)
	return ret;

    /* create anew and remember what it is */
    ret = new_HE();
    ptr_table_store(PL_ptr_table, e, ret);

    HeNEXT(ret) = he_dup(HeNEXT(e),shared);
    if (HeKLEN(e) == HEf_SVKEY)
	HeKEY_sv(ret) = SvREFCNT_inc(sv_dup(HeKEY_sv(e)));
    else if (shared)
	HeKEY_hek(ret) = share_hek(HeKEY(e), HeKLEN_UTF8(e), HeHASH(e));
    else
	HeKEY_hek(ret) = save_hek(HeKEY(e), HeKLEN_UTF8(e), HeHASH(e));
    HeVAL(ret) = SvREFCNT_inc(sv_dup(HeVAL(e)));
    return ret;
}
#endif	/* USE_ITHREADS */

/* (klen == HEf_SVKEY) is special for MAGICAL hv entries, meaning key slot
 * contains an SV* */

/*
=for apidoc hv_fetch

Returns the SV which corresponds to the specified key in the hash.  The
C<klen> is the length of the key.  If C<lval> is set then the fetch will be
part of a store.  Check that the return value is non-null before
dereferencing it to a C<SV*>.

See L<perlguts/"Understanding the Magic of Tied Hashes and Arrays"> for more
information on how to use this function on tied hashes.

=cut
*/

SV**
Perl_hv_fetch(pTHX_ HV *hv, const char *key, I32 klen, I32 lval)
{
    register U32 hash;
    register HE *entry;
    SV *sv;
    bool is_utf8 = FALSE;
    const char *keysave = key;

    if (!hv)
	return 0;

    if (klen < 0) {
      klen = -klen;
      is_utf8 = TRUE;
    }

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv, PERL_MAGIC_tied) || SvGMAGICAL((SV*)hv)) {
	    sv = sv_newmortal();
	    mg_copy((SV*)hv, sv, key, klen);
	    PL_hv_fetch_sv = sv;
	    return &PL_hv_fetch_sv;
	}
#ifdef ENV_IS_CASELESS
	else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	    U32 i;
	    for (i = 0; i < klen; ++i)
		if (isLOWER(key[i])) {
		    char *nkey = strupr(SvPVX(sv_2mortal(newSVpvn(key,klen))));
		    SV **ret = hv_fetch(hv, nkey, klen, 0);
		    if (!ret && lval)
			ret = hv_store(hv, key, klen, NEWSV(61,0), 0);
		    return ret;
		}
	}
#endif
    }

    if (!HvARRAY(hv)) {
	if (lval
#ifdef DYNAMIC_ENV_FETCH  /* if it's an %ENV lookup, we may get it on the fly */
	         || mg_find((SV*)hv, PERL_MAGIC_env)
#endif
	                                                          )
	    Newz(503, HvARRAY(hv),
		 PERL_HV_ARRAY_ALLOC_BYTES(HvMAX(hv) + 1), char);
	else
	    return 0;
    }

    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT)) {
	STRLEN tmplen = klen;
	/* Just casting the &klen to (STRLEN) won't work well
	 * if STRLEN and I32 are of different widths. --jhi */
	key = (char*)bytes_from_utf8((U8*)key, &tmplen, &is_utf8);
	klen = tmplen;
    }

    PERL_HASH(hash, key, klen);

    entry = (HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	if (key != keysave)
	    Safefree(key);
	return &HeVAL(entry);
    }
#ifdef DYNAMIC_ENV_FETCH  /* %ENV lookup?  If so, try to fetch the value now */
    if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	unsigned long len;
	char *env = PerlEnv_ENVgetenv_len(key,&len);
	if (env) {
	    sv = newSVpvn(env,len);
	    SvTAINTED_on(sv);
	    if (key != keysave)
		Safefree(key);
	    return hv_store(hv,key,klen,sv,hash);
	}
    }
#endif
    if (lval) {		/* gonna assign to this, so it better be there */
	sv = NEWSV(61,0);
	if (key != keysave) { /* must be is_utf8 == 0 */
	    SV **ret = hv_store(hv,key,klen,sv,hash);
	    Safefree(key);
	    return ret;
	}
	else
	    return hv_store(hv,key,is_utf8?-klen:klen,sv,hash);
    }
    if (key != keysave)
	Safefree(key);
    return 0;
}

/* returns a HE * structure with the all fields set */
/* note that hent_val will be a mortal sv for MAGICAL hashes */
/*
=for apidoc hv_fetch_ent

Returns the hash entry which corresponds to the specified key in the hash.
C<hash> must be a valid precomputed hash number for the given C<key>, or 0
if you want the function to compute it.  IF C<lval> is set then the fetch
will be part of a store.  Make sure the return value is non-null before
accessing it.  The return value when C<tb> is a tied hash is a pointer to a
static location, so be sure to make a copy of the structure if you need to
store it somewhere.

See L<perlguts/"Understanding the Magic of Tied Hashes and Arrays"> for more
information on how to use this function on tied hashes.

=cut
*/

HE *
Perl_hv_fetch_ent(pTHX_ HV *hv, SV *keysv, I32 lval, register U32 hash)
{
    register char *key;
    STRLEN klen;
    register HE *entry;
    SV *sv;
    bool is_utf8;
    char *keysave;

    if (!hv)
	return 0;

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv, PERL_MAGIC_tied) || SvGMAGICAL((SV*)hv)) {
	    sv = sv_newmortal();
	    keysv = sv_2mortal(newSVsv(keysv));
	    mg_copy((SV*)hv, sv, (char*)keysv, HEf_SVKEY);
	    if (!HeKEY_hek(&PL_hv_fetch_ent_mh)) {
		char *k;
		New(54, k, HEK_BASESIZE + sizeof(SV*), char);
		HeKEY_hek(&PL_hv_fetch_ent_mh) = (HEK*)k;
	    }
	    HeSVKEY_set(&PL_hv_fetch_ent_mh, keysv);
	    HeVAL(&PL_hv_fetch_ent_mh) = sv;
	    return &PL_hv_fetch_ent_mh;
	}
#ifdef ENV_IS_CASELESS
	else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	    U32 i;
	    key = SvPV(keysv, klen);
	    for (i = 0; i < klen; ++i)
		if (isLOWER(key[i])) {
		    SV *nkeysv = sv_2mortal(newSVpvn(key,klen));
		    (void)strupr(SvPVX(nkeysv));
		    entry = hv_fetch_ent(hv, nkeysv, 0, 0);
		    if (!entry && lval)
			entry = hv_store_ent(hv, keysv, NEWSV(61,0), hash);
		    return entry;
		}
	}
#endif
    }

    if (!HvARRAY(hv)) {
	if (lval
#ifdef DYNAMIC_ENV_FETCH  /* if it's an %ENV lookup, we may get it on the fly */
	         || mg_find((SV*)hv, PERL_MAGIC_env)
#endif
	                                                          )
	    Newz(503, HvARRAY(hv),
		 PERL_HV_ARRAY_ALLOC_BYTES(HvMAX(hv) + 1), char);
	else
	    return 0;
    }

    keysave = key = SvPV(keysv, klen);
    is_utf8 = (SvUTF8(keysv)!=0);

    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT))
	key = (char*)bytes_from_utf8((U8*)key, &klen, &is_utf8);

    if (!hash)
	PERL_HASH(hash, key, klen);

    entry = (HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	if (key != keysave)
	    Safefree(key);
	return entry;
    }
#ifdef DYNAMIC_ENV_FETCH  /* %ENV lookup?  If so, try to fetch the value now */
    if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	unsigned long len;
	char *env = PerlEnv_ENVgetenv_len(key,&len);
	if (env) {
	    sv = newSVpvn(env,len);
	    SvTAINTED_on(sv);
	    return hv_store_ent(hv,keysv,sv,hash);
	}
    }
#endif
    if (key != keysave)
	Safefree(key);
    if (lval) {		/* gonna assign to this, so it better be there */
	sv = NEWSV(61,0);
	return hv_store_ent(hv,keysv,sv,hash);
    }
    return 0;
}

STATIC void
S_hv_magic_check(pTHX_ HV *hv, bool *needs_copy, bool *needs_store)
{
    MAGIC *mg = SvMAGIC(hv);
    *needs_copy = FALSE;
    *needs_store = TRUE;
    while (mg) {
	if (isUPPER(mg->mg_type)) {
	    *needs_copy = TRUE;
	    switch (mg->mg_type) {
	    case PERL_MAGIC_tied:
	    case PERL_MAGIC_sig:
		*needs_store = FALSE;
	    }
	}
	mg = mg->mg_moremagic;
    }
}

/*
=for apidoc hv_store

Stores an SV in a hash.  The hash key is specified as C<key> and C<klen> is
the length of the key.  The C<hash> parameter is the precomputed hash
value; if it is zero then Perl will compute it.  The return value will be
NULL if the operation failed or if the value did not need to be actually
stored within the hash (as in the case of tied hashes).  Otherwise it can
be dereferenced to get the original C<SV*>.  Note that the caller is
responsible for suitably incrementing the reference count of C<val> before
the call, and decrementing it if the function returned NULL.

See L<perlguts/"Understanding the Magic of Tied Hashes and Arrays"> for more
information on how to use this function on tied hashes.

=cut
*/

SV**
Perl_hv_store(pTHX_ HV *hv, const char *key, I32 klen, SV *val, register U32 hash)
{
    register I32 i;
    register HE *entry;
    register HE **oentry;
    bool is_utf8 = FALSE;
    const char *keysave = key;

    if (!hv)
	return 0;

    if (klen < 0) {
      klen = -klen;
      is_utf8 = TRUE;
    }

    if (SvMAGICAL(hv)) {
	bool needs_copy;
	bool needs_store;
	hv_magic_check (hv, &needs_copy, &needs_store);
	if (needs_copy) {
	    mg_copy((SV*)hv, val, key, klen);
	    if (!HvARRAY(hv) && !needs_store)
		return 0;
#ifdef ENV_IS_CASELESS
	    else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
                key = savepvn(key,klen);
		key = strupr(key);
		hash = 0;
	    }
#endif
	}
    }
    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT)) {
	STRLEN tmplen = klen;
	/* See the note in hv_fetch(). --jhi */
	key = (char*)bytes_from_utf8((U8*)key, &tmplen, &is_utf8);
	klen = tmplen;
    }

    if (!hash)
	PERL_HASH(hash, key, klen);

    if (!HvARRAY(hv))
	Newz(505, HvARRAY(hv),
	     PERL_HV_ARRAY_ALLOC_BYTES(HvMAX(hv) + 1), char);

    oentry = &(HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    i = 1;

    for (entry = *oentry; entry; i=0, entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	SvREFCNT_dec(HeVAL(entry));
	HeVAL(entry) = val;
	if (key != keysave)
	    Safefree(key);
	return &HeVAL(entry);
    }

    entry = new_HE();
    if (HvSHAREKEYS(hv))
	HeKEY_hek(entry) = share_hek(key, is_utf8?-klen:klen, hash);
    else                                       /* gotta do the real thing */
	HeKEY_hek(entry) = save_hek(key, is_utf8?-klen:klen, hash);
    if (key != keysave)
	Safefree(key);
    HeVAL(entry) = val;
    HeNEXT(entry) = *oentry;
    *oentry = entry;

    HvKEYS(hv)++;
    if (i) {				/* initial entry? */
	HvFILL(hv)++;
	if (HvKEYS(hv) > HvMAX(hv))
	    hsplit(hv);
    }

    return &HeVAL(entry);
}

/*
=for apidoc hv_store_ent

Stores C<val> in a hash.  The hash key is specified as C<key>.  The C<hash>
parameter is the precomputed hash value; if it is zero then Perl will
compute it.  The return value is the new hash entry so created.  It will be
NULL if the operation failed or if the value did not need to be actually
stored within the hash (as in the case of tied hashes).  Otherwise the
contents of the return value can be accessed using the C<He?> macros
described here.  Note that the caller is responsible for suitably
incrementing the reference count of C<val> before the call, and
decrementing it if the function returned NULL.

See L<perlguts/"Understanding the Magic of Tied Hashes and Arrays"> for more
information on how to use this function on tied hashes.

=cut
*/

HE *
Perl_hv_store_ent(pTHX_ HV *hv, SV *keysv, SV *val, register U32 hash)
{
    register char *key;
    STRLEN klen;
    register I32 i;
    register HE *entry;
    register HE **oentry;
    bool is_utf8;
    char *keysave;

    if (!hv)
	return 0;

    if (SvMAGICAL(hv)) {
 	bool needs_copy;
 	bool needs_store;
 	hv_magic_check (hv, &needs_copy, &needs_store);
 	if (needs_copy) {
 	    bool save_taint = PL_tainted;
 	    if (PL_tainting)
 		PL_tainted = SvTAINTED(keysv);
 	    keysv = sv_2mortal(newSVsv(keysv));
 	    mg_copy((SV*)hv, val, (char*)keysv, HEf_SVKEY);
 	    TAINT_IF(save_taint);
 	    if (!HvARRAY(hv) && !needs_store)
 		return Nullhe;
#ifdef ENV_IS_CASELESS
	    else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
		key = SvPV(keysv, klen);
		keysv = sv_2mortal(newSVpvn(key,klen));
		(void)strupr(SvPVX(keysv));
		hash = 0;
	    }
#endif
	}
    }

    keysave = key = SvPV(keysv, klen);
    is_utf8 = (SvUTF8(keysv) != 0);

    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT))
	key = (char*)bytes_from_utf8((U8*)key, &klen, &is_utf8);

    if (!hash)
	PERL_HASH(hash, key, klen);

    if (!HvARRAY(hv))
	Newz(505, HvARRAY(hv),
	     PERL_HV_ARRAY_ALLOC_BYTES(HvMAX(hv) + 1), char);

    oentry = &(HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    i = 1;

    for (entry = *oentry; entry; i=0, entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	SvREFCNT_dec(HeVAL(entry));
	HeVAL(entry) = val;
	if (key != keysave)
	    Safefree(key);
	return entry;
    }

    entry = new_HE();
    if (HvSHAREKEYS(hv))
	HeKEY_hek(entry) = share_hek(key, is_utf8?-klen:klen, hash);
    else                                       /* gotta do the real thing */
	HeKEY_hek(entry) = save_hek(key, is_utf8?-klen:klen, hash);
    if (key != keysave)
	Safefree(key);
    HeVAL(entry) = val;
    HeNEXT(entry) = *oentry;
    *oentry = entry;

    HvKEYS(hv)++;
    if (i) {				/* initial entry? */
	HvFILL(hv)++;
	if (HvKEYS(hv) > HvMAX(hv))
	    hsplit(hv);
    }

    return entry;
}

/*
=for apidoc hv_delete

Deletes a key/value pair in the hash.  The value SV is removed from the
hash and returned to the caller.  The C<klen> is the length of the key.
The C<flags> value will normally be zero; if set to G_DISCARD then NULL
will be returned.

=cut
*/

SV *
Perl_hv_delete(pTHX_ HV *hv, const char *key, I32 klen, I32 flags)
{
    register I32 i;
    register U32 hash;
    register HE *entry;
    register HE **oentry;
    SV **svp;
    SV *sv;
    bool is_utf8 = FALSE;
    const char *keysave = key;

    if (!hv)
	return Nullsv;
    if (klen < 0) {
      klen = -klen;
      is_utf8 = TRUE;
    }
    if (SvRMAGICAL(hv)) {
	bool needs_copy;
	bool needs_store;
	hv_magic_check (hv, &needs_copy, &needs_store);

	if (needs_copy && (svp = hv_fetch(hv, key, klen, TRUE))) {
	    sv = *svp;
	    mg_clear(sv);
	    if (!needs_store) {
		if (mg_find(sv, PERL_MAGIC_tiedelem)) {
		    /* No longer an element */
		    sv_unmagic(sv, PERL_MAGIC_tiedelem);
		    return sv;
		}
		return Nullsv;          /* element cannot be deleted */
	    }
#ifdef ENV_IS_CASELESS
	    else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
		sv = sv_2mortal(newSVpvn(key,klen));
		key = strupr(SvPVX(sv));
	    }
#endif
        }
    }
    if (!HvARRAY(hv))
	return Nullsv;

    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT)) {
	STRLEN tmplen = klen;
	/* See the note in hv_fetch(). --jhi */
	key = (char*)bytes_from_utf8((U8*)key, &tmplen, &is_utf8);
	klen = tmplen;
    }

    PERL_HASH(hash, key, klen);

    oentry = &(HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    entry = *oentry;
    i = 1;
    for (; entry; i=0, oentry = &HeNEXT(entry), entry = *oentry) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	if (key != keysave)
	    Safefree(key);
	*oentry = HeNEXT(entry);
	if (i && !*oentry)
	    HvFILL(hv)--;
	if (flags & G_DISCARD)
	    sv = Nullsv;
	else {
	    sv = sv_2mortal(HeVAL(entry));
	    HeVAL(entry) = &PL_sv_undef;
	}
	if (entry == HvEITER(hv))
	    HvLAZYDEL_on(hv);
	else
	    hv_free_ent(hv, entry);
	HvKEYS(hv)--;
	return sv;
    }
    if (key != keysave)
	Safefree(key);
    return Nullsv;
}

/*
=for apidoc hv_delete_ent

Deletes a key/value pair in the hash.  The value SV is removed from the
hash and returned to the caller.  The C<flags> value will normally be zero;
if set to G_DISCARD then NULL will be returned.  C<hash> can be a valid
precomputed hash value, or 0 to ask for it to be computed.

=cut
*/

SV *
Perl_hv_delete_ent(pTHX_ HV *hv, SV *keysv, I32 flags, U32 hash)
{
    register I32 i;
    register char *key;
    STRLEN klen;
    register HE *entry;
    register HE **oentry;
    SV *sv;
    bool is_utf8;
    char *keysave;

    if (!hv)
	return Nullsv;
    if (SvRMAGICAL(hv)) {
	bool needs_copy;
	bool needs_store;
	hv_magic_check (hv, &needs_copy, &needs_store);

	if (needs_copy && (entry = hv_fetch_ent(hv, keysv, TRUE, hash))) {
	    sv = HeVAL(entry);
	    mg_clear(sv);
	    if (!needs_store) {
		if (mg_find(sv, PERL_MAGIC_tiedelem)) {
		    /* No longer an element */
		    sv_unmagic(sv, PERL_MAGIC_tiedelem);
		    return sv;
		}		
		return Nullsv;		/* element cannot be deleted */
	    }
#ifdef ENV_IS_CASELESS
	    else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
		key = SvPV(keysv, klen);
		keysv = sv_2mortal(newSVpvn(key,klen));
		(void)strupr(SvPVX(keysv));
		hash = 0;
	    }
#endif
	}
    }
    if (!HvARRAY(hv))
	return Nullsv;

    keysave = key = SvPV(keysv, klen);
    is_utf8 = (SvUTF8(keysv) != 0);

    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT))
	key = (char*)bytes_from_utf8((U8*)key, &klen, &is_utf8);

    if (!hash)
	PERL_HASH(hash, key, klen);

    oentry = &(HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    entry = *oentry;
    i = 1;
    for (; entry; i=0, oentry = &HeNEXT(entry), entry = *oentry) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	if (key != keysave)
	    Safefree(key);
	*oentry = HeNEXT(entry);
	if (i && !*oentry)
	    HvFILL(hv)--;
	if (flags & G_DISCARD)
	    sv = Nullsv;
	else {
	    sv = sv_2mortal(HeVAL(entry));
	    HeVAL(entry) = &PL_sv_undef;
	}
	if (entry == HvEITER(hv))
	    HvLAZYDEL_on(hv);
	else
	    hv_free_ent(hv, entry);
	HvKEYS(hv)--;
	return sv;
    }
    if (key != keysave)
	Safefree(key);
    return Nullsv;
}

/*
=for apidoc hv_exists

Returns a boolean indicating whether the specified hash key exists.  The
C<klen> is the length of the key.

=cut
*/

bool
Perl_hv_exists(pTHX_ HV *hv, const char *key, I32 klen)
{
    register U32 hash;
    register HE *entry;
    SV *sv;
    bool is_utf8 = FALSE;
    const char *keysave = key;

    if (!hv)
	return 0;

    if (klen < 0) {
      klen = -klen;
      is_utf8 = TRUE;
    }

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv, PERL_MAGIC_tied) || SvGMAGICAL((SV*)hv)) {
	    sv = sv_newmortal();
	    mg_copy((SV*)hv, sv, key, klen);
	    magic_existspack(sv, mg_find(sv, PERL_MAGIC_tiedelem));
	    return SvTRUE(sv);
	}
#ifdef ENV_IS_CASELESS
	else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	    sv = sv_2mortal(newSVpvn(key,klen));
	    key = strupr(SvPVX(sv));
	}
#endif
    }

#ifndef DYNAMIC_ENV_FETCH
    if (!HvARRAY(hv))
	return 0;
#endif

    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT)) {
	STRLEN tmplen = klen;
	/* See the note in hv_fetch(). --jhi */
	key = (char*)bytes_from_utf8((U8*)key, &tmplen, &is_utf8);
	klen = tmplen;
    }

    PERL_HASH(hash, key, klen);

#ifdef DYNAMIC_ENV_FETCH
    if (!HvARRAY(hv)) entry = Null(HE*);
    else
#endif
    entry = (HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	if (key != keysave)
	    Safefree(key);
	return TRUE;
    }
#ifdef DYNAMIC_ENV_FETCH  /* is it out there? */
    if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	unsigned long len;
	char *env = PerlEnv_ENVgetenv_len(key,&len);
	if (env) {
	    sv = newSVpvn(env,len);
	    SvTAINTED_on(sv);
	    (void)hv_store(hv,key,klen,sv,hash);
	    return TRUE;
	}
    }
#endif
    if (key != keysave)
	Safefree(key);
    return FALSE;
}


/*
=for apidoc hv_exists_ent

Returns a boolean indicating whether the specified hash key exists. C<hash>
can be a valid precomputed hash value, or 0 to ask for it to be
computed.

=cut
*/

bool
Perl_hv_exists_ent(pTHX_ HV *hv, SV *keysv, U32 hash)
{
    register char *key;
    STRLEN klen;
    register HE *entry;
    SV *sv;
    bool is_utf8;
    char *keysave;

    if (!hv)
	return 0;

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv, PERL_MAGIC_tied) || SvGMAGICAL((SV*)hv)) {
           SV* svret = sv_newmortal();
	    sv = sv_newmortal();
	    keysv = sv_2mortal(newSVsv(keysv));
	    mg_copy((SV*)hv, sv, (char*)keysv, HEf_SVKEY);
           magic_existspack(svret, mg_find(sv, PERL_MAGIC_tiedelem));
           return SvTRUE(svret);
	}
#ifdef ENV_IS_CASELESS
	else if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	    key = SvPV(keysv, klen);
	    keysv = sv_2mortal(newSVpvn(key,klen));
	    (void)strupr(SvPVX(keysv));
	    hash = 0;
	}
#endif
    }

#ifndef DYNAMIC_ENV_FETCH
    if (!HvARRAY(hv))
	return 0;
#endif

    keysave = key = SvPV(keysv, klen);
    is_utf8 = (SvUTF8(keysv) != 0);
    if (is_utf8 && !(PL_hints & HINT_UTF8_DISTINCT))
	key = (char*)bytes_from_utf8((U8*)key, &klen, &is_utf8);
    if (!hash)
	PERL_HASH(hash, key, klen);

#ifdef DYNAMIC_ENV_FETCH
    if (!HvARRAY(hv)) entry = Null(HE*);
    else
#endif
    entry = (HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (HeKEY(entry) != key && memNE(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	if (key != keysave)
	    Safefree(key);
	return TRUE;
    }
#ifdef DYNAMIC_ENV_FETCH  /* is it out there? */
    if (mg_find((SV*)hv, PERL_MAGIC_env)) {
	unsigned long len;
	char *env = PerlEnv_ENVgetenv_len(key,&len);
	if (env) {
	    sv = newSVpvn(env,len);
	    SvTAINTED_on(sv);
	    (void)hv_store_ent(hv,keysv,sv,hash);
	    return TRUE;
	}
    }
#endif
    if (key != keysave)
	Safefree(key);
    return FALSE;
}

STATIC void
S_hsplit(pTHX_ HV *hv)
{
    I32 oldsize = (I32) HvMAX(hv) + 1; /* sic(k) */
    register I32 newsize = oldsize * 2;
    register I32 i;
    register char *a = (char *)HvARRAY(hv);
    register HE **aep;
    register HE **bep;
    register HE *entry;
    register HE **oentry;

    PL_nomemok = TRUE;
#if defined(STRANGE_MALLOC) || defined(MYMALLOC)
    Renew(a, PERL_HV_ARRAY_ALLOC_BYTES(newsize), char);
    if (!a) {
      PL_nomemok = FALSE;
      return;
    }
#else
    New(2, a, PERL_HV_ARRAY_ALLOC_BYTES(newsize), char);
    if (!a) {
      PL_nomemok = FALSE;
      return;
    }
    Copy(HvARRAY(hv), a, oldsize * sizeof(HE*), char);
    if (oldsize >= 64) {
	offer_nice_chunk(HvARRAY(hv), PERL_HV_ARRAY_ALLOC_BYTES(oldsize));
    }
    else
	Safefree(HvARRAY(hv));
#endif

    PL_nomemok = FALSE;
    Zero(&a[oldsize * sizeof(HE*)], (newsize-oldsize) * sizeof(HE*), char);	/* zero 2nd half*/
    HvMAX(hv) = --newsize;
    HvARRAY(hv) = a;
    aep = (HE**)a;

    for (i=0; i<oldsize; i++,aep++) {
	if (!*aep)				/* non-existent */
	    continue;
	bep = aep+oldsize;
	for (oentry = aep, entry = *aep; entry; entry = *oentry) {
	    if ((HeHASH(entry) & newsize) != i) {
		*oentry = HeNEXT(entry);
		HeNEXT(entry) = *bep;
		if (!*bep)
		    HvFILL(hv)++;
		*bep = entry;
		continue;
	    }
	    else
		oentry = &HeNEXT(entry);
	}
	if (!*aep)				/* everything moved */
	    HvFILL(hv)--;
    }
}

void
Perl_hv_ksplit(pTHX_ HV *hv, IV newmax)
{
    I32 oldsize = (I32) HvMAX(hv) + 1; /* sic(k) */
    register I32 newsize;
    register I32 i;
    register I32 j;
    register char *a;
    register HE **aep;
    register HE *entry;
    register HE **oentry;

    newsize = (I32) newmax;			/* possible truncation here */
    if (newsize != newmax || newmax <= oldsize)
	return;
    while ((newsize & (1 + ~newsize)) != newsize) {
	newsize &= ~(newsize & (1 + ~newsize));	/* get proper power of 2 */
    }
    if (newsize < newmax)
	newsize *= 2;
    if (newsize < newmax)
	return;					/* overflow detection */

    a = (char *)HvARRAY(hv);
    if (a) {
	PL_nomemok = TRUE;
#if defined(STRANGE_MALLOC) || defined(MYMALLOC)
	Renew(a, PERL_HV_ARRAY_ALLOC_BYTES(newsize), char);
        if (!a) {
	  PL_nomemok = FALSE;
	  return;
	}
#else
	New(2, a, PERL_HV_ARRAY_ALLOC_BYTES(newsize), char);
        if (!a) {
	  PL_nomemok = FALSE;
	  return;
	}
	Copy(HvARRAY(hv), a, oldsize * sizeof(HE*), char);
	if (oldsize >= 64) {
	    offer_nice_chunk(HvARRAY(hv), PERL_HV_ARRAY_ALLOC_BYTES(oldsize));
	}
	else
	    Safefree(HvARRAY(hv));
#endif
	PL_nomemok = FALSE;
	Zero(&a[oldsize * sizeof(HE*)], (newsize-oldsize) * sizeof(HE*), char); /* zero 2nd half*/
    }
    else {
	Newz(0, a, PERL_HV_ARRAY_ALLOC_BYTES(newsize), char);
    }
    HvMAX(hv) = --newsize;
    HvARRAY(hv) = a;
    if (!HvFILL(hv))				/* skip rest if no entries */
	return;

    aep = (HE**)a;
    for (i=0; i<oldsize; i++,aep++) {
	if (!*aep)				/* non-existent */
	    continue;
	for (oentry = aep, entry = *aep; entry; entry = *oentry) {
	    if ((j = (HeHASH(entry) & newsize)) != i) {
		j -= i;
		*oentry = HeNEXT(entry);
		if (!(HeNEXT(entry) = aep[j]))
		    HvFILL(hv)++;
		aep[j] = entry;
		continue;
	    }
	    else
		oentry = &HeNEXT(entry);
	}
	if (!*aep)				/* everything moved */
	    HvFILL(hv)--;
    }
}

/*
=for apidoc newHV

Creates a new HV.  The reference count is set to 1.

=cut
*/

HV *
Perl_newHV(pTHX)
{
    register HV *hv;

    hv = (HV*)NEWSV(502,0);
    sv_upgrade((SV *)hv, SVt_PVHV);
    SvPOK_off(hv);
    SvNOK_off(hv);
#ifndef NODEFAULT_SHAREKEYS
    HvSHAREKEYS_on(hv);         /* key-sharing on by default */
#endif
    HvMAX(hv) = 7;		/* start with 8 buckets */
    HvFILL(hv) = 0;
    HvPMROOT(hv) = 0;
    (void)hv_iterinit(hv);	/* so each() will start off right */
    return hv;
}

HV *
Perl_newHVhv(pTHX_ HV *ohv)
{
    register HV *hv;
    STRLEN hv_max = ohv ? HvMAX(ohv) : 0;
    STRLEN hv_fill = ohv ? HvFILL(ohv) : 0;

    hv = newHV();
    while (hv_max && hv_max + 1 >= hv_fill * 2)
	hv_max = hv_max / 2;	/* Is always 2^n-1 */
    HvMAX(hv) = hv_max;
    if (!hv_fill)
	return hv;

#if 0
    if (! SvTIED_mg((SV*)ohv, PERL_MAGIC_tied)) {
	/* Quick way ???*/
    }
    else
#endif
    {
	HE *entry;
	I32 hv_riter = HvRITER(ohv);	/* current root of iterator */
	HE *hv_eiter = HvEITER(ohv);	/* current entry of iterator */
	
	/* Slow way */
	hv_iterinit(ohv);
	while ((entry = hv_iternext(ohv))) {
	    hv_store(hv, HeKEY(entry), HeKLEN_UTF8(entry),
		     newSVsv(HeVAL(entry)), HeHASH(entry));
	}
	HvRITER(ohv) = hv_riter;
	HvEITER(ohv) = hv_eiter;
    }

    return hv;
}

void
Perl_hv_free_ent(pTHX_ HV *hv, register HE *entry)
{
    SV *val;

    if (!entry)
	return;
    val = HeVAL(entry);
    if (val && isGV(val) && GvCVu(val) && HvNAME(hv))
	PL_sub_generation++;	/* may be deletion of method from stash */
    SvREFCNT_dec(val);
    if (HeKLEN(entry) == HEf_SVKEY) {
	SvREFCNT_dec(HeKEY_sv(entry));
        Safefree(HeKEY_hek(entry));
    }
    else if (HvSHAREKEYS(hv))
	unshare_hek(HeKEY_hek(entry));
    else
	Safefree(HeKEY_hek(entry));
    del_HE(entry);
}

void
Perl_hv_delayfree_ent(pTHX_ HV *hv, register HE *entry)
{
    if (!entry)
	return;
    if (isGV(HeVAL(entry)) && GvCVu(HeVAL(entry)) && HvNAME(hv))
	PL_sub_generation++;	/* may be deletion of method from stash */
    sv_2mortal(HeVAL(entry));	/* free between statements */
    if (HeKLEN(entry) == HEf_SVKEY) {
	sv_2mortal(HeKEY_sv(entry));
	Safefree(HeKEY_hek(entry));
    }
    else if (HvSHAREKEYS(hv))
	unshare_hek(HeKEY_hek(entry));
    else
	Safefree(HeKEY_hek(entry));
    del_HE(entry);
}

/*
=for apidoc hv_clear

Clears a hash, making it empty.

=cut
*/

void
Perl_hv_clear(pTHX_ HV *hv)
{
    if (!hv)
	return;
    hfreeentries(hv);
    HvFILL(hv) = 0;
    HvKEYS(hv) = 0;
    if (HvARRAY(hv))
	(void)memzero(HvARRAY(hv), (HvMAX(hv) + 1) * sizeof(HE*));

    if (SvRMAGICAL(hv))
	mg_clear((SV*)hv);
}

STATIC void
S_hfreeentries(pTHX_ HV *hv)
{
    register HE **array;
    register HE *entry;
    register HE *oentry = Null(HE*);
    I32 riter;
    I32 max;

    if (!hv)
	return;
    if (!HvARRAY(hv))
	return;

    riter = 0;
    max = HvMAX(hv);
    array = HvARRAY(hv);
    entry = array[0];
    for (;;) {
	if (entry) {
	    oentry = entry;
	    entry = HeNEXT(entry);
	    hv_free_ent(hv, oentry);
	}
	if (!entry) {
	    if (++riter > max)
		break;
	    entry = array[riter];
	}
    }
    (void)hv_iterinit(hv);
}

/*
=for apidoc hv_undef

Undefines the hash.

=cut
*/

void
Perl_hv_undef(pTHX_ HV *hv)
{
    if (!hv)
	return;
    hfreeentries(hv);
    Safefree(HvARRAY(hv));
    if (HvNAME(hv)) {
	Safefree(HvNAME(hv));
	HvNAME(hv) = 0;
    }
    HvARRAY(hv) = 0;
    HvMAX(hv)   = 7;		/* it's a normal hash */
    HvFILL(hv)  = 0;
    HvKEYS(hv)  = 0;

    if (SvRMAGICAL(hv))
	mg_clear((SV*)hv);
}

/*
=for apidoc hv_iterinit

Prepares a starting point to traverse a hash table.  Returns the number of
keys in the hash (i.e. the same as C<HvKEYS(tb)>).  The return value is
currently only meaningful for hashes without tie magic.

NOTE: Before version 5.004_65, C<hv_iterinit> used to return the number of
hash buckets that happen to be in use.  If you still need that esoteric
value, you can get it through the macro C<HvFILL(tb)>.

=cut
*/

I32
Perl_hv_iterinit(pTHX_ HV *hv)
{
    HE *entry;

    if (!hv)
	Perl_croak(aTHX_ "Bad hash");
    entry = HvEITER(hv);
    if (entry && HvLAZYDEL(hv)) {	/* was deleted earlier? */
	HvLAZYDEL_off(hv);
	hv_free_ent(hv, entry);
    }
    HvRITER(hv) = -1;
    HvEITER(hv) = Null(HE*);
    return HvKEYS(hv);		/* used to be xhv->xhv_fill before 5.004_65 */
}

/*
=for apidoc hv_iternext

Returns entries from a hash iterator.  See C<hv_iterinit>.

=cut
*/

HE *
Perl_hv_iternext(pTHX_ HV *hv)
{
    register HE *entry;
    HE *oldentry;
    MAGIC* mg;

    if (!hv)
	Perl_croak(aTHX_ "Bad hash");
    oldentry = entry = HvEITER(hv);

    if ((mg = SvTIED_mg((SV*)hv, PERL_MAGIC_tied))) {
	SV *key = sv_newmortal();
	if (entry) {
	    sv_setsv(key, HeSVKEY_force(entry));
	    SvREFCNT_dec(HeSVKEY(entry));	/* get rid of previous key */
	}
	else {
	    char *k;
	    HEK *hek;

	    HvEITER(hv) = entry = new_HE();  /* one HE per MAGICAL hash */
	    Zero(entry, 1, HE);
	    Newz(54, k, HEK_BASESIZE + sizeof(SV*), char);
	    hek = (HEK*)k;
	    HeKEY_hek(entry) = hek;
	    HeKLEN(entry) = HEf_SVKEY;
	}
	magic_nextpack((SV*) hv,mg,key);
        if (SvOK(key)) {
	    /* force key to stay around until next time */
	    HeSVKEY_set(entry, SvREFCNT_inc(key));
	    return entry;		/* beware, hent_val is not set */
        }
	if (HeVAL(entry))
	    SvREFCNT_dec(HeVAL(entry));
	Safefree(HeKEY_hek(entry));
	del_HE(entry);
	HvEITER(hv) = Null(HE*);
	return Null(HE*);
    }
#ifdef DYNAMIC_ENV_FETCH  /* set up %ENV for iteration */
    if (!entry && mg_find((SV*)hv, PERL_MAGIC_env))
	prime_env_iter();
#endif

    if (!HvARRAY(hv))
	Newz(506, HvARRAY(hv),
	     PERL_HV_ARRAY_ALLOC_BYTES(HvMAX(hv) + 1), char);
    if (entry)
	entry = HeNEXT(entry);
    while (!entry) {
	HvRITER(hv)++;
	if (HvRITER(hv) > HvMAX(hv)) {
	    HvRITER(hv) = -1;
	    break;
	}
	entry = (HvARRAY(hv))[HvRITER(hv)];
    }

    if (oldentry && HvLAZYDEL(hv)) {		/* was deleted earlier? */
	HvLAZYDEL_off(hv);
	hv_free_ent(hv, oldentry);
    }

    HvEITER(hv) = entry;
    return entry;
}

/*
=for apidoc hv_iterkey

Returns the key from the current position of the hash iterator.  See
C<hv_iterinit>.

=cut
*/

char *
Perl_hv_iterkey(pTHX_ register HE *entry, I32 *retlen)
{
    if (HeKLEN(entry) == HEf_SVKEY) {
	STRLEN len;
	char *p = SvPV(HeKEY_sv(entry), len);
	*retlen = len;
	return p;
    }
    else {
	*retlen = HeKLEN(entry);
	return HeKEY(entry);
    }
}

/* unlike hv_iterval(), this always returns a mortal copy of the key */
/*
=for apidoc hv_iterkeysv

Returns the key as an C<SV*> from the current position of the hash
iterator.  The return value will always be a mortal copy of the key.  Also
see C<hv_iterinit>.

=cut
*/

SV *
Perl_hv_iterkeysv(pTHX_ register HE *entry)
{
    if (HeKLEN(entry) == HEf_SVKEY)
	return sv_mortalcopy(HeKEY_sv(entry));
    else
	return sv_2mortal(newSVpvn_share((HeKLEN(entry) ? HeKEY(entry) : ""),
					 HeKLEN_UTF8(entry), HeHASH(entry)));
}

/*
=for apidoc hv_iterval

Returns the value from the current position of the hash iterator.  See
C<hv_iterkey>.

=cut
*/

SV *
Perl_hv_iterval(pTHX_ HV *hv, register HE *entry)
{
    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv, PERL_MAGIC_tied)) {
	    SV* sv = sv_newmortal();
	    if (HeKLEN(entry) == HEf_SVKEY)
		mg_copy((SV*)hv, sv, (char*)HeKEY_sv(entry), HEf_SVKEY);
	    else mg_copy((SV*)hv, sv, HeKEY(entry), HeKLEN(entry));
	    return sv;
	}
    }
    return HeVAL(entry);
}

/*
=for apidoc hv_iternextsv

Performs an C<hv_iternext>, C<hv_iterkey>, and C<hv_iterval> in one
operation.

=cut
*/

SV *
Perl_hv_iternextsv(pTHX_ HV *hv, char **key, I32 *retlen)
{
    HE *he;
    if ( (he = hv_iternext(hv)) == NULL)
	return NULL;
    *key = hv_iterkey(he, retlen);
    return hv_iterval(hv, he);
}

/*
=for apidoc hv_magic

Adds magic to a hash.  See C<sv_magic>.

=cut
*/

void
Perl_hv_magic(pTHX_ HV *hv, GV *gv, int how)
{
    sv_magic((SV*)hv, (SV*)gv, how, Nullch, 0);
}

char*	
Perl_sharepvn(pTHX_ const char *sv, I32 len, U32 hash)
{
    return HEK_KEY(share_hek(sv, len, hash));
}

/* possibly free a shared string if no one has access to it
 * len and hash must both be valid for str.
 */
void
Perl_unsharepvn(pTHX_ const char *str, I32 len, U32 hash)
{
    HV *hv;
    register HE *entry;
    register HE **oentry;
    register I32 i = 1;
    I32 found = 0;
    bool is_utf8 = FALSE;
    const char *save = str;

    if (len < 0) {
      len = -len;
      is_utf8 = TRUE;
      if (!(PL_hints & HINT_UTF8_DISTINCT)) {
	  STRLEN tmplen = len;
	  /* See the note in hv_fetch(). --jhi */
	  str = (char*)bytes_from_utf8((U8*)str, &tmplen, &is_utf8);
	  len = tmplen;
      }
    }

    /* what follows is the moral equivalent of:
    if ((Svp = hv_fetch(PL_strtab, tmpsv, FALSE, hash))) {
	if (--*Svp == Nullsv)
	    hv_delete(PL_strtab, str, len, G_DISCARD, hash);
    } */
    /* assert(xhv_array != 0) */
    hv = PL_strtab;
    LOCK_STRTAB_MUTEX;
    oentry = &(HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    for (entry = *oentry; entry; i=0, oentry = &HeNEXT(entry), entry = *oentry) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != len)
	    continue;
	if (HeKEY(entry) != str && memNE(HeKEY(entry),str,len))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	found = 1;
	if (--HeVAL(entry) == Nullsv) {
	    *oentry = HeNEXT(entry);
	    if (i && !*oentry)
		HvFILL(hv)--;
	    Safefree(HeKEY_hek(entry));
	    del_HE(entry);
	    HvKEYS(hv)--;
	}
	break;
    }
    UNLOCK_STRTAB_MUTEX;
    if (str != save)
	Safefree(str);
    if (!found && ckWARN_d(WARN_INTERNAL))
	Perl_warner(aTHX_ WARN_INTERNAL, "Attempt to free non-existent shared string '%s'",str);
}

/* get a (constant) string ptr from the global string table
 * string will get added if it is not already there.
 * len and hash must both be valid for str.
 */
HEK *
Perl_share_hek(pTHX_ const char *str, I32 len, register U32 hash)
{
    HV *hv;
    register HE *entry;
    register HE **oentry;
    register I32 i = 1;
    I32 found = 0;
    bool is_utf8 = FALSE;
    const char *save = str;

    if (len < 0) {
      len = -len;
      is_utf8 = TRUE;
      if (!(PL_hints & HINT_UTF8_DISTINCT)) {
	  STRLEN tmplen = len;
	  /* See the note in hv_fetch(). --jhi */
	  str = (char*)bytes_from_utf8((U8*)str, &tmplen, &is_utf8);
	  len = tmplen;
      }
    }

    /* what follows is the moral equivalent of:

    if (!(Svp = hv_fetch(PL_strtab, str, len, FALSE)))
    	hv_store(PL_strtab, str, len, Nullsv, hash);
    */
    /* assert(xhv_array != 0) */
    hv = PL_strtab;
    LOCK_STRTAB_MUTEX;
    oentry = &(HvARRAY(hv))[hash & (I32) HvMAX(hv)];
    for (entry = *oentry; entry; i=0, entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != len)
	    continue;
	if (HeKEY(entry) != str && memNE(HeKEY(entry),str,len))	/* is this it? */
	    continue;
	if (HeKUTF8(entry) != (char)is_utf8)
	    continue;
	found = 1;
	break;
    }
    if (!found) {
	entry = new_HE();
	HeKEY_hek(entry) = save_hek(str, is_utf8?-len:len, hash);
	HeVAL(entry) = Nullsv;
	HeNEXT(entry) = *oentry;
	*oentry = entry;
	HvKEYS(hv)++;
	if (i) {				/* initial entry? */
	    HvFILL(hv)++;
	    if (HvKEYS(hv) > HvMAX(hv))
		hsplit(hv);
	}
    }

    ++HeVAL(entry);				/* use value slot as REFCNT */
    UNLOCK_STRTAB_MUTEX;
    if (str != save)
	Safefree(str);
    return HeKEY_hek(entry);
}
