/*    hv.c
 *
 *    Copyright (c) 1991-1994, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "I sit beside the fire and think of all that I have seen."  --Bilbo
 */

#include "EXTERN.h"
#include "perl.h"

static void hsplit _((HV *hv));
static void hfreeentries _((HV *hv));

static HE* more_he();

static HE*
new_he()
{
    HE* he;
    if (he_root) {
        he = he_root;
        he_root = HeNEXT(he);
        return he;
    }
    return more_he();
}

static void
del_he(p)
HE* p;
{
    HeNEXT(p) = (HE*)he_root;
    he_root = p;
}

static HE*
more_he()
{
    register HE* he;
    register HE* heend;
    he_root = (HE*)safemalloc(1008);
    he = he_root;
    heend = &he[1008 / sizeof(HE) - 1];
    while (he < heend) {
        HeNEXT(he) = (HE*)(he + 1);
        he++;
    }
    HeNEXT(he) = 0;
    return new_he();
}

/* (klen == HEf_SVKEY) is special for MAGICAL hv entries, meaning key slot
 * contains an SV* */

SV**
hv_fetch(hv,key,klen,lval)
HV *hv;
char *key;
U32 klen;
I32 lval;
{
    register XPVHV* xhv;
    register U32 hash;
    register HE *entry;
    SV *sv;

    if (!hv)
	return 0;

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv,'P')) {
	    sv = sv_newmortal();
	    mg_copy((SV*)hv, sv, key, klen);
	    Sv = sv;
	    return &Sv;
	}
    }

    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array) {
	if (lval 
#ifdef DYNAMIC_ENV_FETCH  /* if it's an %ENV lookup, we may get it on the fly */
	         || (HvNAME(hv) && strEQ(HvNAME(hv),ENV_HV_NAME))
#endif
	                                                          )
	    Newz(503,xhv->xhv_array, sizeof(HE*) * (xhv->xhv_max + 1), char);
	else
	    return 0;
    }

    PERL_HASH(hash, key, klen);

    entry = ((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	return &HeVAL(entry);
    }
#ifdef DYNAMIC_ENV_FETCH  /* %ENV lookup?  If so, try to fetch the value now */
    if (HvNAME(hv) && strEQ(HvNAME(hv),ENV_HV_NAME)) {
      char *gotenv;

      gotenv = my_getenv(key);
      if (gotenv != NULL) {
        sv = newSVpv(gotenv,strlen(gotenv));
        return hv_store(hv,key,klen,sv,hash);
      }
    }
#endif
    if (lval) {		/* gonna assign to this, so it better be there */
	sv = NEWSV(61,0);
	return hv_store(hv,key,klen,sv,hash);
    }
    return 0;
}

/* returns a HE * structure with the all fields set */
/* note that hent_val will be a mortal sv for MAGICAL hashes */
HE *
hv_fetch_ent(hv,keysv,lval,hash)
HV *hv;
SV *keysv;
I32 lval;
register U32 hash;
{
    register XPVHV* xhv;
    register char *key;
    STRLEN klen;
    register HE *entry;
    SV *sv;

    if (!hv)
	return 0;

    if (SvRMAGICAL(hv) && mg_find((SV*)hv,'P')) {
	sv = sv_newmortal();
	keysv = sv_2mortal(newSVsv(keysv));
	mg_copy((SV*)hv, sv, (char*)keysv, HEf_SVKEY);
	entry = &He;
	HeVAL(entry) = sv;
	HeKEY(entry) = (char*)keysv;
	HeKLEN(entry) = HEf_SVKEY;		/* hent_key is holding an SV* */
	return entry;
    }

    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array) {
	if (lval 
#ifdef DYNAMIC_ENV_FETCH  /* if it's an %ENV lookup, we may get it on the fly */
	         || (HvNAME(hv) && strEQ(HvNAME(hv),ENV_HV_NAME))
#endif
	                                                          )
	    Newz(503,xhv->xhv_array, sizeof(HE*) * (xhv->xhv_max + 1), char);
	else
	    return 0;
    }

    key = SvPV(keysv, klen);
    
    if (!hash)
	PERL_HASH(hash, key, klen);

    entry = ((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	return entry;
    }
#ifdef DYNAMIC_ENV_FETCH  /* %ENV lookup?  If so, try to fetch the value now */
    if (HvNAME(hv) && strEQ(HvNAME(hv),ENV_HV_NAME)) {
      char *gotenv;

      gotenv = my_getenv(key);
      if (gotenv != NULL) {
        sv = newSVpv(gotenv,strlen(gotenv));
        return hv_store_ent(hv,keysv,sv,hash);
      }
    }
#endif
    if (lval) {		/* gonna assign to this, so it better be there */
	sv = NEWSV(61,0);
	return hv_store_ent(hv,keysv,sv,hash);
    }
    return 0;
}

SV**
hv_store(hv,key,klen,val,hash)
HV *hv;
char *key;
U32 klen;
SV *val;
register U32 hash;
{
    register XPVHV* xhv;
    register I32 i;
    register HE *entry;
    register HE **oentry;

    if (!hv)
	return 0;

    xhv = (XPVHV*)SvANY(hv);
    if (SvMAGICAL(hv)) {
	mg_copy((SV*)hv, val, key, klen);
#ifndef OVERLOAD
	if (!xhv->xhv_array)
	    return 0;
#else
	if (!xhv->xhv_array && (SvMAGIC(hv)->mg_type != 'A'
				|| SvMAGIC(hv)->mg_moremagic))
	  return 0;
#endif /* OVERLOAD */
    }
    if (!hash)
	PERL_HASH(hash, key, klen);

    if (!xhv->xhv_array)
	Newz(505, xhv->xhv_array, sizeof(HE**) * (xhv->xhv_max + 1), char);

    oentry = &((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    i = 1;

    for (entry = *oentry; entry; i=0, entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	SvREFCNT_dec(HeVAL(entry));
	HeVAL(entry) = val;
	return &HeVAL(entry);
    }

    entry = new_he();
    HeKLEN(entry) = klen;
    if (HvSHAREKEYS(hv))
	HeKEY(entry) = sharepvn(key, klen, hash);
    else                                       /* gotta do the real thing */
	HeKEY(entry) = savepvn(key,klen);
    HeVAL(entry) = val;
    HeHASH(entry) = hash;
    HeNEXT(entry) = *oentry;
    *oentry = entry;

    xhv->xhv_keys++;
    if (i) {				/* initial entry? */
	++xhv->xhv_fill;
	if (xhv->xhv_keys > xhv->xhv_max)
	    hsplit(hv);
    }

    return &HeVAL(entry);
}

HE *
hv_store_ent(hv,keysv,val,hash)
HV *hv;
SV *keysv;
SV *val;
register U32 hash;
{
    register XPVHV* xhv;
    register char *key;
    STRLEN klen;
    register I32 i;
    register HE *entry;
    register HE **oentry;

    if (!hv)
	return 0;

    xhv = (XPVHV*)SvANY(hv);
    if (SvMAGICAL(hv)) {
	keysv = sv_2mortal(newSVsv(keysv));
	mg_copy((SV*)hv, val, (char*)keysv, HEf_SVKEY);
#ifndef OVERLOAD
	if (!xhv->xhv_array)
	    return Nullhe;
#else
	if (!xhv->xhv_array && (SvMAGIC(hv)->mg_type != 'A'
				|| SvMAGIC(hv)->mg_moremagic))
	  return Nullhe;
#endif /* OVERLOAD */
    }

    key = SvPV(keysv, klen);
    
    if (!hash)
	PERL_HASH(hash, key, klen);

    if (!xhv->xhv_array)
	Newz(505, xhv->xhv_array, sizeof(HE**) * (xhv->xhv_max + 1), char);

    oentry = &((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    i = 1;

    for (entry = *oentry; entry; i=0, entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	SvREFCNT_dec(HeVAL(entry));
	HeVAL(entry) = val;
	return entry;
    }

    entry = new_he();
    HeKLEN(entry) = klen;
    if (HvSHAREKEYS(hv))
	HeKEY(entry) = sharepvn(key, klen, hash);
    else                                       /* gotta do the real thing */
	HeKEY(entry) = savepvn(key,klen);
    HeVAL(entry) = val;
    HeHASH(entry) = hash;
    HeNEXT(entry) = *oentry;
    *oentry = entry;

    xhv->xhv_keys++;
    if (i) {				/* initial entry? */
	++xhv->xhv_fill;
	if (xhv->xhv_keys > xhv->xhv_max)
	    hsplit(hv);
    }

    return entry;
}

SV *
hv_delete(hv,key,klen,flags)
HV *hv;
char *key;
U32 klen;
I32 flags;
{
    register XPVHV* xhv;
    register I32 i;
    register U32 hash;
    register HE *entry;
    register HE **oentry;
    SV *sv;

    if (!hv)
	return Nullsv;
    if (SvRMAGICAL(hv)) {
	sv = *hv_fetch(hv, key, klen, TRUE);
	mg_clear(sv);
	if (mg_find(sv, 's')) {
	    return Nullsv;		/* %SIG elements cannot be deleted */
	}
	if (mg_find(sv, 'p')) {
	    sv_unmagic(sv, 'p');	/* No longer an element */
	    return sv;
	}
    }
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return Nullsv;

    PERL_HASH(hash, key, klen);

    oentry = &((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    entry = *oentry;
    i = 1;
    for (; entry; i=0, oentry = &HeNEXT(entry), entry = *oentry) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	*oentry = HeNEXT(entry);
	if (i && !*oentry)
	    xhv->xhv_fill--;
	if (flags & G_DISCARD)
	    sv = Nullsv;
	else
	    sv = sv_mortalcopy(HeVAL(entry));
	if (entry == xhv->xhv_eiter)
	    HvLAZYDEL_on(hv);
	else
	    he_free(entry, HvSHAREKEYS(hv));
	--xhv->xhv_keys;
	return sv;
    }
    return Nullsv;
}

SV *
hv_delete_ent(hv,keysv,flags,hash)
HV *hv;
SV *keysv;
I32 flags;
U32 hash;
{
    register XPVHV* xhv;
    register I32 i;
    register char *key;
    STRLEN klen;
    register HE *entry;
    register HE **oentry;
    SV *sv;
    
    if (!hv)
	return Nullsv;
    if (SvRMAGICAL(hv)) {
	entry = hv_fetch_ent(hv, keysv, TRUE, hash);
	sv = HeVAL(entry);
	mg_clear(sv);
	if (mg_find(sv, 'p')) {
	    sv_unmagic(sv, 'p');	/* No longer an element */
	    return sv;
	}
    }
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return Nullsv;

    key = SvPV(keysv, klen);
    
    if (!hash)
	PERL_HASH(hash, key, klen);

    oentry = &((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    entry = *oentry;
    i = 1;
    for (; entry; i=0, oentry = &HeNEXT(entry), entry = *oentry) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	*oentry = HeNEXT(entry);
	if (i && !*oentry)
	    xhv->xhv_fill--;
	if (flags & G_DISCARD)
	    sv = Nullsv;
	else
	    sv = sv_mortalcopy(HeVAL(entry));
	if (entry == xhv->xhv_eiter)
	    HvLAZYDEL_on(hv);
	else
	    he_free(entry, HvSHAREKEYS(hv));
	--xhv->xhv_keys;
	return sv;
    }
    return Nullsv;
}

bool
hv_exists(hv,key,klen)
HV *hv;
char *key;
U32 klen;
{
    register XPVHV* xhv;
    register U32 hash;
    register HE *entry;
    SV *sv;

    if (!hv)
	return 0;

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv,'P')) {
	    sv = sv_newmortal();
	    mg_copy((SV*)hv, sv, key, klen); 
	    magic_existspack(sv, mg_find(sv, 'p'));
	    return SvTRUE(sv);
	}
    }

    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return 0; 

    PERL_HASH(hash, key, klen);

    entry = ((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	return TRUE;
    }
    return FALSE;
}


bool
hv_exists_ent(hv,keysv,hash)
HV *hv;
SV *keysv;
U32 hash;
{
    register XPVHV* xhv;
    register char *key;
    STRLEN klen;
    register HE *entry;
    SV *sv;

    if (!hv)
	return 0;

    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv,'P')) {
	    sv = sv_newmortal();
	    keysv = sv_2mortal(newSVsv(keysv));
	    mg_copy((SV*)hv, sv, (char*)keysv, HEf_SVKEY); 
	    magic_existspack(sv, mg_find(sv, 'p'));
	    return SvTRUE(sv);
	}
    }

    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return 0; 

    key = SvPV(keysv, klen);
    if (!hash)
	PERL_HASH(hash, key, klen);

    entry = ((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    for (; entry; entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != klen)
	    continue;
	if (memcmp(HeKEY(entry),key,klen))	/* is this it? */
	    continue;
	return TRUE;
    }
    return FALSE;
}

static void
hsplit(hv)
HV *hv;
{
    register XPVHV* xhv = (XPVHV*)SvANY(hv);
    I32 oldsize = (I32) xhv->xhv_max + 1; /* sic(k) */
    register I32 newsize = oldsize * 2;
    register I32 i;
    register HE **a;
    register HE **b;
    register HE *entry;
    register HE **oentry;
#ifndef STRANGE_MALLOC
    I32 tmp;
#endif

    a = (HE**)xhv->xhv_array;
    nomemok = TRUE;
#ifdef STRANGE_MALLOC
    Renew(a, newsize, HE*);
#else
    i = newsize * sizeof(HE*);
#define MALLOC_OVERHEAD 16
    tmp = MALLOC_OVERHEAD;
    while (tmp - MALLOC_OVERHEAD < i)
	tmp += tmp;
    tmp -= MALLOC_OVERHEAD;
    tmp /= sizeof(HE*);
    assert(tmp >= newsize);
    New(2,a, tmp, HE*);
    Copy(xhv->xhv_array, a, oldsize, HE*);
    if (oldsize >= 64 && !nice_chunk) {
	nice_chunk = (char*)xhv->xhv_array;
	nice_chunk_size = oldsize * sizeof(HE*) * 2 - MALLOC_OVERHEAD;
    }
    else
	Safefree(xhv->xhv_array);
#endif

    nomemok = FALSE;
    Zero(&a[oldsize], oldsize, HE*);		/* zero 2nd half*/
    xhv->xhv_max = --newsize;
    xhv->xhv_array = (char*)a;

    for (i=0; i<oldsize; i++,a++) {
	if (!*a)				/* non-existent */
	    continue;
	b = a+oldsize;
	for (oentry = a, entry = *a; entry; entry = *oentry) {
	    if ((HeHASH(entry) & newsize) != i) {
		*oentry = HeNEXT(entry);
		HeNEXT(entry) = *b;
		if (!*b)
		    xhv->xhv_fill++;
		*b = entry;
		continue;
	    }
	    else
		oentry = &HeNEXT(entry);
	}
	if (!*a)				/* everything moved */
	    xhv->xhv_fill--;
    }
}

void
hv_ksplit(hv, newmax)
HV *hv;
IV newmax;
{
    register XPVHV* xhv = (XPVHV*)SvANY(hv);
    I32 oldsize = (I32) xhv->xhv_max + 1; /* sic(k) */
    register I32 newsize;
    register I32 i;
    register I32 j;
    register HE **a;
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

    a = (HE**)xhv->xhv_array;
    if (a) {
	nomemok = TRUE;
#ifdef STRANGE_MALLOC
	Renew(a, newsize, HE*);
#else
	i = newsize * sizeof(HE*);
	j = MALLOC_OVERHEAD;
	while (j - MALLOC_OVERHEAD < i)
	    j += j;
	j -= MALLOC_OVERHEAD;
	j /= sizeof(HE*);
	assert(j >= newsize);
	New(2, a, j, HE*);
	Copy(xhv->xhv_array, a, oldsize, HE*);
	if (oldsize >= 64 && !nice_chunk) {
	    nice_chunk = (char*)xhv->xhv_array;
	    nice_chunk_size = oldsize * sizeof(HE*) * 2 - MALLOC_OVERHEAD;
	}
	else
	    Safefree(xhv->xhv_array);
#endif
	nomemok = FALSE;
	Zero(&a[oldsize], newsize-oldsize, HE*); /* zero 2nd half*/
    }
    else {
	Newz(0, a, newsize, HE*);
    }
    xhv->xhv_max = --newsize;
    xhv->xhv_array = (char*)a;
    if (!xhv->xhv_fill)				/* skip rest if no entries */
	return;

    for (i=0; i<oldsize; i++,a++) {
	if (!*a)				/* non-existent */
	    continue;
	for (oentry = a, entry = *a; entry; entry = *oentry) {
	    if ((j = (HeHASH(entry) & newsize)) != i) {
		j -= i;
		*oentry = HeNEXT(entry);
		if (!(HeNEXT(entry) = a[j]))
		    xhv->xhv_fill++;
		a[j] = entry;
		continue;
	    }
	    else
		oentry = &HeNEXT(entry);
	}
	if (!*a)				/* everything moved */
	    xhv->xhv_fill--;
    }
}

HV *
newHV()
{
    register HV *hv;
    register XPVHV* xhv;

    hv = (HV*)NEWSV(502,0);
    sv_upgrade((SV *)hv, SVt_PVHV);
    xhv = (XPVHV*)SvANY(hv);
    SvPOK_off(hv);
    SvNOK_off(hv);
#ifndef NODEFAULT_SHAREKEYS    
    HvSHAREKEYS_on(hv);         /* key-sharing on by default */
#endif    
    xhv->xhv_max = 7;		/* start with 8 buckets */
    xhv->xhv_fill = 0;
    xhv->xhv_pmroot = 0;
    (void)hv_iterinit(hv);	/* so each() will start off right */
    return hv;
}

void
he_free(hent, shared)
register HE *hent;
I32 shared;
{
    if (!hent)
	return;
    SvREFCNT_dec(HeVAL(hent));
    if (HeKLEN(hent) == HEf_SVKEY)
	SvREFCNT_dec((SV*)HeKEY(hent));
    else if (shared)
	unsharepvn(HeKEY(hent), HeKLEN(hent), HeHASH(hent));
    else
	Safefree(HeKEY(hent));
    del_he(hent);
}

void
he_delayfree(hent, shared)
register HE *hent;
I32 shared;
{
    if (!hent)
	return;
    sv_2mortal(HeVAL(hent));	/* free between statements */
    if (HeKLEN(hent) == HEf_SVKEY)
	sv_2mortal((SV*)HeKEY(hent));
    else if (shared)
	unsharepvn(HeKEY(hent), HeKLEN(hent), HeHASH(hent));
    else
	Safefree(HeKEY(hent));
    del_he(hent);
}

void
hv_clear(hv)
HV *hv;
{
    register XPVHV* xhv;
    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    hfreeentries(hv);
    xhv->xhv_fill = 0;
    xhv->xhv_keys = 0;
    if (xhv->xhv_array)
	(void)memzero(xhv->xhv_array, (xhv->xhv_max + 1) * sizeof(HE*));

    if (SvRMAGICAL(hv))
	mg_clear((SV*)hv); 
}

static void
hfreeentries(hv)
HV *hv;
{
    register HE **array;
    register HE *hent;
    register HE *ohent = Null(HE*);
    I32 riter;
    I32 max;
    I32 shared;

    if (!hv)
	return;
    if (!HvARRAY(hv))
	return;

    riter = 0;
    max = HvMAX(hv);
    array = HvARRAY(hv);
    hent = array[0];
    shared = HvSHAREKEYS(hv);
    for (;;) {
	if (hent) {
	    ohent = hent;
	    hent = HeNEXT(hent);
	    he_free(ohent, shared);
	}
	if (!hent) {
	    if (++riter > max)
		break;
	    hent = array[riter];
	} 
    }
    (void)hv_iterinit(hv);
}

void
hv_undef(hv)
HV *hv;
{
    register XPVHV* xhv;
    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    hfreeentries(hv);
    Safefree(xhv->xhv_array);
    if (HvNAME(hv)) {
	Safefree(HvNAME(hv));
	HvNAME(hv) = 0;
    }
    xhv->xhv_array = 0;
    xhv->xhv_max = 7;		/* it's a normal associative array */
    xhv->xhv_fill = 0;
    xhv->xhv_keys = 0;

    if (SvRMAGICAL(hv))
	mg_clear((SV*)hv); 
}

I32
hv_iterinit(hv)
HV *hv;
{
    register XPVHV* xhv = (XPVHV*)SvANY(hv);
    HE *entry = xhv->xhv_eiter;
#ifdef DYNAMIC_ENV_FETCH  /* set up %ENV for iteration */
    if (HvNAME(hv) && strEQ(HvNAME(hv),ENV_HV_NAME)) prime_env_iter();
#endif
    if (entry && HvLAZYDEL(hv)) {	/* was deleted earlier? */
	HvLAZYDEL_off(hv);
	he_free(entry, HvSHAREKEYS(hv));
    }
    xhv->xhv_riter = -1;
    xhv->xhv_eiter = Null(HE*);
    return xhv->xhv_fill;
}

HE *
hv_iternext(hv)
HV *hv;
{
    register XPVHV* xhv;
    register HE *entry;
    HE *oldentry;
    MAGIC* mg;

    if (!hv)
	croak("Bad associative array");
    xhv = (XPVHV*)SvANY(hv);
    oldentry = entry = xhv->xhv_eiter;

    if (SvRMAGICAL(hv) && (mg = mg_find((SV*)hv,'P'))) {
	SV *key = sv_newmortal();
	if (entry) {
	    sv_setsv(key, HeSVKEY_force(entry));
	    SvREFCNT_dec(HeSVKEY(entry));	/* get rid of previous key */
	}
	else {
	    xhv->xhv_eiter = entry = new_he();	/* only one HE per MAGICAL hash */
	    Zero(entry, 1, HE);
	    HeKLEN(entry) = HEf_SVKEY;
	}
	magic_nextpack((SV*) hv,mg,key);
        if (SvOK(key)) {
	    /* force key to stay around until next time */
	    HeKEY(entry) = (char*)SvREFCNT_inc(key);
	    return entry;			/* beware, hent_val is not set */
        }
	if (HeVAL(entry))
	    SvREFCNT_dec(HeVAL(entry));
	del_he(entry);
	xhv->xhv_eiter = Null(HE*);
	return Null(HE*);
    }

    if (!xhv->xhv_array)
	Newz(506,xhv->xhv_array, sizeof(HE*) * (xhv->xhv_max + 1), char);
    if (entry)
	entry = HeNEXT(entry);
    while (!entry) {
	++xhv->xhv_riter;
	if (xhv->xhv_riter > xhv->xhv_max) {
	    xhv->xhv_riter = -1;
	    break;
	}
	entry = ((HE**)xhv->xhv_array)[xhv->xhv_riter];
    }

    if (oldentry && HvLAZYDEL(hv)) {		/* was deleted earlier? */
	HvLAZYDEL_off(hv);
	he_free(oldentry, HvSHAREKEYS(hv));
    }

    xhv->xhv_eiter = entry;
    return entry;
}

char *
hv_iterkey(entry,retlen)
register HE *entry;
I32 *retlen;
{
    if (HeKLEN(entry) == HEf_SVKEY) {
	return SvPV((SV*)HeKEY(entry), *(STRLEN*)retlen);
    }
    else {
	*retlen = HeKLEN(entry);
	return HeKEY(entry);
    }
}

/* unlike hv_iterval(), this always returns a mortal copy of the key */
SV *
hv_iterkeysv(entry)
register HE *entry;
{
    if (HeKLEN(entry) == HEf_SVKEY)
	return sv_mortalcopy((SV*)HeKEY(entry));
    else
	return sv_2mortal(newSVpv((HeKLEN(entry) ? HeKEY(entry) : ""),
				  HeKLEN(entry)));
}

SV *
hv_iterval(hv,entry)
HV *hv;
register HE *entry;
{
    if (SvRMAGICAL(hv)) {
	if (mg_find((SV*)hv,'P')) {
	    SV* sv = sv_newmortal();
	    mg_copy((SV*)hv, sv, HeKEY(entry), HeKLEN(entry));
	    return sv;
	}
    }
    return HeVAL(entry);
}

SV *
hv_iternextsv(hv, key, retlen)
    HV *hv;
    char **key;
    I32 *retlen;
{
    HE *he;
    if ( (he = hv_iternext(hv)) == NULL)
	return NULL;
    *key = hv_iterkey(he, retlen);
    return hv_iterval(hv, he);
}

void
hv_magic(hv, gv, how)
HV* hv;
GV* gv;
int how;
{
    sv_magic((SV*)hv, (SV*)gv, how, Nullch, 0);
}

/* get a (constant) string ptr from the global string table
 * string will get added if it is not already there.
 * len and hash must both be valid for str.
 */
char *
sharepvn(str, len, hash)
char *str;
I32 len;
register U32 hash;
{
    register XPVHV* xhv;
    register HE *entry;
    register HE **oentry;
    register I32 i = 1;
    I32 found = 0;

    /* what follows is the moral equivalent of:
       
    if (!(Svp = hv_fetch(strtab, str, len, FALSE)))
    	hv_store(strtab, str, len, Nullsv, hash);
    */
    xhv = (XPVHV*)SvANY(strtab);
    /* assert(xhv_array != 0) */
    oentry = &((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    for (entry = *oentry; entry; i=0, entry = HeNEXT(entry)) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != len)
	    continue;
	if (memcmp(HeKEY(entry),str,len))		/* is this it? */
	    continue;
	found = 1;
	break;
    }
    if (!found) {
	entry = new_he();
	HeKLEN(entry) = len;
	HeKEY(entry) = savepvn(str,len);
	HeVAL(entry) = Nullsv;
	HeHASH(entry) = hash;
	HeNEXT(entry) = *oentry;
	*oentry = entry;
	xhv->xhv_keys++;
	if (i) {				/* initial entry? */
	    ++xhv->xhv_fill;
	    if (xhv->xhv_keys > xhv->xhv_max)
		hsplit(strtab);
	}
    }

    ++HeVAL(entry);				/* use value slot as REFCNT */
    return HeKEY(entry);
}

/* possibly free a shared string if no one has access to it
 * len and hash must both be valid for str.
 */
void
unsharepvn(str, len, hash)
char *str;
I32 len;
register U32 hash;
{
    register XPVHV* xhv;
    register HE *entry;
    register HE **oentry;
    register I32 i = 1;
    I32 found = 0;
    
    /* what follows is the moral equivalent of:
    if ((Svp = hv_fetch(strtab, tmpsv, FALSE, hash))) {
	if (--*Svp == Nullsv)
	    hv_delete(strtab, str, len, G_DISCARD, hash);
    } */
    xhv = (XPVHV*)SvANY(strtab);
    /* assert(xhv_array != 0) */
    oentry = &((HE**)xhv->xhv_array)[hash & (I32) xhv->xhv_max];
    for (entry = *oentry; entry; i=0, oentry = &HeNEXT(entry), entry = *oentry) {
	if (HeHASH(entry) != hash)		/* strings can't be equal */
	    continue;
	if (HeKLEN(entry) != len)
	    continue;
	if (memcmp(HeKEY(entry),str,len))		/* is this it? */
	    continue;
	found = 1;
	if (--HeVAL(entry) == Nullsv) {
	    *oentry = HeNEXT(entry);
	    if (i && !*oentry)
		xhv->xhv_fill--;
	    Safefree(HeKEY(entry));
	    del_he(entry);
	    --xhv->xhv_keys;
	}
	break;
    }
    
    if (!found)
	warn("Attempt to free non-existent shared string");    
}

