/* $RCSfile: hash.c,v $$Revision: 4.1 $$Date: 92/08/07 18:21:48 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	hash.c,v $
 * Revision 4.1  92/08/07  18:21:48  lwall
 * 
 * Revision 4.0.1.3  92/06/08  13:26:29  lwall
 * patch20: removed implicit int declarations on functions
 * patch20: delete could cause %array to give too low a count of buckets filled
 * patch20: hash tables now split only if the memory is available to do so
 * 
 * Revision 4.0.1.2  91/11/05  17:24:13  lwall
 * patch11: saberized perl
 * 
 * Revision 4.0.1.1  91/06/07  11:10:11  lwall
 * patch4: new copyright notice
 * 
 * Revision 4.0  91/03/20  01:22:26  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

static void hsplit();

static void hfreeentries();

SV**
hv_fetch(hv,key,klen,lval)
HV *hv;
char *key;
U32 klen;
I32 lval;
{
    register XPVHV* xhv;
    register char *s;
    register I32 i;
    register I32 hash;
    register HE *entry;
    register I32 maxi;
    SV *sv;
#ifdef SOME_DBM
    datum dkey,dcontent;
#endif

    if (!hv)
	return 0;
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array) {
	if (lval)
	    Newz(503,xhv->xhv_array, xhv->xhv_max + 1, HE*);
	else
	    return 0;
    }

    /* The hash function we use on symbols has to be equal to the first
     * character when taken modulo 128, so that sv_reset() can be implemented
     * efficiently.  We throw in the second character and the last character
     * (times 128) so that long chains of identifiers starting with the
     * same letter don't have to be strEQ'ed within hv_fetch(), since it
     * compares hash values before trying strEQ().
     */
    if (!xhv->xhv_coeffsize && klen)
	hash = klen ? *key + 128 * key[1] + 128 * key[klen-1] : 0;
    else {	/* use normal coefficients */
	if (klen < xhv->xhv_coeffsize)
	    maxi = klen;
	else
	    maxi = xhv->xhv_coeffsize;
	for (s=key,		i=0,	hash = 0;
			    i < maxi;			/*SUPPRESS 8*/
	     s++,		i++,	hash *= 5) {
	    hash += *s * coeff[i];
	}
    }

    entry = xhv->xhv_array[hash & xhv->xhv_max];
    for (; entry; entry = entry->hent_next) {
	if (entry->hent_hash != hash)		/* strings can't be equal */
	    continue;
	if (entry->hent_klen != klen)
	    continue;
	if (bcmp(entry->hent_key,key,klen))	/* is this it? */
	    continue;
	return &entry->hent_val;
    }
#ifdef SOME_DBM
    if (xhv->xhv_dbm) {
	dkey.dptr = key;
	dkey.dsize = klen;
#ifdef HAS_GDBM
	dcontent = gdbm_fetch(xhv->xhv_dbm,dkey);
#else
	dcontent = dbm_fetch(xhv->xhv_dbm,dkey);
#endif
	if (dcontent.dptr) {			/* found one */
	    sv = NEWSV(60,dcontent.dsize);
	    sv_setpvn(sv,dcontent.dptr,dcontent.dsize);
	    return hv_store(hv,key,klen,sv,hash);		/* cache it */
	}
    }
#endif
    if (lval) {		/* gonna assign to this, so it better be there */
	sv = NEWSV(61,0);
	return hv_store(hv,key,klen,sv,hash);
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
    register char *s;
    register I32 i;
    register HE *entry;
    register HE **oentry;
    register I32 maxi;

    if (!hv)
	return 0;

    xhv = (XPVHV*)SvANY(hv);
    if (hash)
	/*SUPPRESS 530*/
	;
    else if (!xhv->xhv_coeffsize && klen)
	hash = klen ? *key + 128 * key[1] + 128 * key[klen-1] : 0;
    else {	/* use normal coefficients */
	if (klen < xhv->xhv_coeffsize)
	    maxi = klen;
	else
	    maxi = xhv->xhv_coeffsize;
	for (s=key,		i=0,	hash = 0;
			    i < maxi;			/*SUPPRESS 8*/
	     s++,		i++,	hash *= 5) {
	    hash += *s * coeff[i];
	}
    }

    if (!xhv->xhv_array)
	Newz(505,xhv->xhv_array, xhv->xhv_max + 1, HE*);

    oentry = &(xhv->xhv_array[hash & xhv->xhv_max]);
    i = 1;

    if (SvMAGICAL(hv)) {
	MAGIC* mg = SvMAGIC(hv);
	sv_magic(val, (SV*)hv, tolower(mg->mg_type), key, klen);
    }
    for (entry = *oentry; entry; i=0, entry = entry->hent_next) {
	if (entry->hent_hash != hash)		/* strings can't be equal */
	    continue;
	if (entry->hent_klen != klen)
	    continue;
	if (bcmp(entry->hent_key,key,klen))	/* is this it? */
	    continue;
	sv_free(entry->hent_val);
	entry->hent_val = val;
	return &entry->hent_val;
    }
    New(501,entry, 1, HE);

    entry->hent_klen = klen;
    entry->hent_key = nsavestr(key,klen);
    entry->hent_val = val;
    entry->hent_hash = hash;
    entry->hent_next = *oentry;
    *oentry = entry;

    /* hv_dbmstore not necessary here because it's called from sv_setmagic() */

    if (i) {				/* initial entry? */
	xhv->xhv_fill++;
#ifdef SOME_DBM
	if (xhv->xhv_dbm && xhv->xhv_max >= DBM_CACHE_MAX)
	    return &entry->hent_val;
#endif
	if (xhv->xhv_fill > xhv->xhv_dosplit)
	    hsplit(hv);
    }
#ifdef SOME_DBM
    else if (xhv->xhv_dbm) {		/* is this just a cache for dbm file? */
	void he_delayfree();
	HE* ent;

	ent = xhv->xhv_array[hash & xhv->xhv_max];
	oentry = &ent->hent_next;
	ent = *oentry;
	while (ent) {	/* trim chain down to 1 entry */
	    *oentry = ent->hent_next;
	    he_delayfree(ent);	/* no doubt they'll want this next, sigh... */
	    ent = *oentry;
	}
    }
#endif

    return &entry->hent_val;
}

SV *
hv_delete(hv,key,klen)
HV *hv;
char *key;
U32 klen;
{
    register XPVHV* xhv;
    register char *s;
    register I32 i;
    register I32 hash;
    register HE *entry;
    register HE **oentry;
    SV *sv;
    I32 maxi;
#ifdef SOME_DBM
    datum dkey;
#endif

    if (!hv)
	return Nullsv;
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return Nullsv;
    if (!xhv->xhv_coeffsize && klen)
	hash = klen ? *key + 128 * key[1] + 128 * key[klen-1] : 0;
    else {	/* use normal coefficients */
	if (klen < xhv->xhv_coeffsize)
	    maxi = klen;
	else
	    maxi = xhv->xhv_coeffsize;
	for (s=key,		i=0,	hash = 0;
			    i < maxi;			/*SUPPRESS 8*/
	     s++,		i++,	hash *= 5) {
	    hash += *s * coeff[i];
	}
    }

    oentry = &(xhv->xhv_array[hash & xhv->xhv_max]);
    entry = *oentry;
    i = 1;
    for (; entry; i=0, oentry = &entry->hent_next, entry = *oentry) {
	if (entry->hent_hash != hash)		/* strings can't be equal */
	    continue;
	if (entry->hent_klen != klen)
	    continue;
	if (bcmp(entry->hent_key,key,klen))	/* is this it? */
	    continue;
	*oentry = entry->hent_next;
	if (i && !*oentry)
	    xhv->xhv_fill--;
	sv = sv_mortalcopy(entry->hent_val);
	he_free(entry);
#ifdef SOME_DBM
      do_dbm_delete:
	if (xhv->xhv_dbm) {
	    dkey.dptr = key;
	    dkey.dsize = klen;
#ifdef HAS_GDBM
	    gdbm_delete(xhv->xhv_dbm,dkey);
#else
	    dbm_delete(xhv->xhv_dbm,dkey);
#endif
	}
#endif
	return sv;
    }
#ifdef SOME_DBM
    sv = Nullsv;
    goto do_dbm_delete;
#else
    return Nullsv;
#endif
}

static void
hsplit(hv)
HV *hv;
{
    register XPVHV* xhv = (XPVHV*)SvANY(hv);
    I32 oldsize = xhv->xhv_max + 1;
    register I32 newsize = oldsize * 2;
    register I32 i;
    register HE **a;
    register HE **b;
    register HE *entry;
    register HE **oentry;

    a = xhv->xhv_array;
    nomemok = TRUE;
    Renew(a, newsize, HE*);
    nomemok = FALSE;
    if (!a) {
	xhv->xhv_dosplit = xhv->xhv_max + 1;	/* never split again */
	return;
    }
    Zero(&a[oldsize], oldsize, HE*);		/* zero 2nd half*/
    xhv->xhv_max = --newsize;
    xhv->xhv_dosplit = xhv->xhv_max * FILLPCT / 100;
    xhv->xhv_array = a;

    for (i=0; i<oldsize; i++,a++) {
	if (!*a)				/* non-existent */
	    continue;
	b = a+oldsize;
	for (oentry = a, entry = *a; entry; entry = *oentry) {
	    if ((entry->hent_hash & newsize) != i) {
		*oentry = entry->hent_next;
		entry->hent_next = *b;
		if (!*b)
		    xhv->xhv_fill++;
		*b = entry;
		continue;
	    }
	    else
		oentry = &entry->hent_next;
	}
	if (!*a)				/* everything moved */
	    xhv->xhv_fill--;
    }
}

HV *
newHV(lookat)
U32 lookat;
{
    register HV *hv;
    register XPVHV* xhv;

    Newz(502,hv, 1, HV);
    SvREFCNT(hv) = 1;
    sv_upgrade(hv, SVt_PVHV);
    xhv = (XPVHV*)SvANY(hv);
    SvPOK_off(hv);
    SvNOK_off(hv);
    if (lookat) {
	xhv->xhv_coeffsize = lookat;
	xhv->xhv_max = 7;		/* it's a normal associative array */
	xhv->xhv_dosplit = xhv->xhv_max * FILLPCT / 100;
    }
    else {
	xhv->xhv_max = 127;		/* it's a symbol table */
	xhv->xhv_dosplit = 128;		/* so never split */
    }
    xhv->xhv_fill = 0;
    xhv->xhv_pmroot = 0;
#ifdef SOME_DBM
    xhv->xhv_dbm = 0;
#endif
    (void)hv_iterinit(hv);	/* so each() will start off right */
    return hv;
}

void
he_free(hent)
register HE *hent;
{
    if (!hent)
	return;
    sv_free(hent->hent_val);
    Safefree(hent->hent_key);
    Safefree(hent);
}

void
he_delayfree(hent)
register HE *hent;
{
    if (!hent)
	return;
    sv_2mortal(hent->hent_val);	/* free between statements */
    Safefree(hent->hent_key);
    Safefree(hent);
}

void
hv_clear(hv,dodbm)
HV *hv;
I32 dodbm;
{
    register XPVHV* xhv;
    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    hfreeentries(hv,dodbm);
    xhv->xhv_fill = 0;
#ifndef lint
    if (xhv->xhv_array)
	(void)memzero((char*)xhv->xhv_array, (xhv->xhv_max + 1) * sizeof(HE*));
#endif
}

static void
hfreeentries(hv,dodbm)
HV *hv;
I32 dodbm;
{
    register XPVHV* xhv;
    register HE *hent;
    register HE *ohent = Null(HE*);
#ifdef SOME_DBM
    datum dkey;
    datum nextdkey;
#ifdef HAS_GDBM
    GDBM_FILE old_dbm;
#else
#ifdef HAS_NDBM
    DBM *old_dbm;
#else
    I32 old_dbm;
#endif
#endif
#endif

    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return;
#ifdef SOME_DBM
    if ((old_dbm = xhv->xhv_dbm) && dodbm) {
#ifdef HAS_GDBM
	while (dkey = gdbm_firstkey(xhv->xhv_dbm), dkey.dptr) {
#else
	while (dkey = dbm_firstkey(xhv->xhv_dbm), dkey.dptr) {
#endif
	    do {
#ifdef HAS_GDBM
		nextdkey = gdbm_nextkey(xhv->xhv_dbm, dkey);
#else
#ifdef HAS_NDBM
#ifdef _CX_UX
		nextdkey = dbm_nextkey(xhv->xhv_dbm, dkey);
#else
		nextdkey = dbm_nextkey(xhv->xhv_dbm);
#endif
#else
		nextdkey = nextkey(dkey);
#endif
#endif
#ifdef HAS_GDBM
		gdbm_delete(xhv->xhv_dbm,dkey);
#else
		dbm_delete(xhv->xhv_dbm,dkey);
#endif
		dkey = nextdkey;
	    } while (dkey.dptr);	/* one way or another, this works */
	}
    }
    xhv->xhv_dbm = 0;			/* now clear just cache */
#endif
    (void)hv_iterinit(hv);
    /*SUPPRESS 560*/
    while (hent = hv_iternext(hv)) {	/* concise but not very efficient */
	he_free(ohent);
	ohent = hent;
    }
    he_free(ohent);
#ifdef SOME_DBM
    xhv->xhv_dbm = old_dbm;
#endif
    if (SvMAGIC(hv))
	mg_clear(hv);
}

void
hv_undef(hv,dodbm)
HV *hv;
I32 dodbm;
{
    register XPVHV* xhv;
    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    hfreeentries(hv,dodbm);
    Safefree(xhv->xhv_array);
    xhv->xhv_array = 0;
    if (xhv->xhv_coeffsize) {
	xhv->xhv_max = 7;		/* it's a normal associative array */
	xhv->xhv_dosplit = xhv->xhv_max * FILLPCT / 100;
    }
    else {
	xhv->xhv_max = 127;		/* it's a symbol table */
	xhv->xhv_dosplit = 128;		/* so never split */
    }
    xhv->xhv_fill = 0;
#ifdef SOME_DBM
    xhv->xhv_dbm = 0;
#endif
    (void)hv_iterinit(hv);	/* so each() will start off right */
}

void
hv_free(hv,dodbm)
register HV *hv;
I32 dodbm;
{
    if (!hv)
	return;
    hfreeentries(hv,dodbm);
    Safefree(HvARRAY(hv));
    Safefree(hv);
}

I32
hv_iterinit(hv)
HV *hv;
{
    register XPVHV* xhv = (XPVHV*)SvANY(hv);
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
#ifdef SOME_DBM
    datum key;
#endif

    if (!hv)
	fatal("Bad associative array");
    xhv = (XPVHV*)SvANY(hv);
    entry = xhv->xhv_eiter;
#ifdef SOME_DBM
    if (xhv->xhv_dbm) {
	if (entry) {
#ifdef HAS_GDBM
	    key.dptr = entry->hent_key;
	    key.dsize = entry->hent_klen;
	    key = gdbm_nextkey(xhv->xhv_dbm, key);
#else
#ifdef HAS_NDBM
#ifdef _CX_UX
	    key.dptr = entry->hent_key;
	    key.dsize = entry->hent_klen;
	    key = dbm_nextkey(xhv->xhv_dbm, key);
#else
	    key = dbm_nextkey(xhv->xhv_dbm);
#endif /* _CX_UX */
#else
	    key.dptr = entry->hent_key;
	    key.dsize = entry->hent_klen;
	    key = nextkey(key);
#endif
#endif
	}
	else {
	    Newz(504,entry, 1, HE);
	    xhv->xhv_eiter = entry;
#ifdef HAS_GDBM
	    key = gdbm_firstkey(xhv->xhv_dbm);
#else
	    key = dbm_firstkey(xhv->xhv_dbm);
#endif
	}
	entry->hent_key = key.dptr;
	entry->hent_klen = key.dsize;
	if (!key.dptr) {
	    if (entry->hent_val)
		sv_free(entry->hent_val);
	    Safefree(entry);
	    xhv->xhv_eiter = Null(HE*);
	    return Null(HE*);
	}
	return entry;
    }
#endif
    if (!xhv->xhv_array)
	Newz(506,xhv->xhv_array, xhv->xhv_max + 1, HE*);
    do {
	if (entry)
	    entry = entry->hent_next;
	if (!entry) {
	    xhv->xhv_riter++;
	    if (xhv->xhv_riter > xhv->xhv_max) {
		xhv->xhv_riter = -1;
		break;
	    }
	    entry = xhv->xhv_array[xhv->xhv_riter];
	}
    } while (!entry);

    xhv->xhv_eiter = entry;
    return entry;
}

char *
hv_iterkey(entry,retlen)
register HE *entry;
I32 *retlen;
{
    *retlen = entry->hent_klen;
    return entry->hent_key;
}

SV *
hv_iterval(hv,entry)
HV *hv;
register HE *entry;
{
#ifdef SOME_DBM
    register XPVHV* xhv;
    datum key, content;

    if (!hv)
	fatal("Bad associative array");
    xhv = (XPVHV*)SvANY(hv);
    if (xhv->xhv_dbm) {
	key.dptr = entry->hent_key;
	key.dsize = entry->hent_klen;
#ifdef HAS_GDBM
	content = gdbm_fetch(xhv->xhv_dbm,key);
#else
	content = dbm_fetch(xhv->xhv_dbm,key);
#endif
	if (!entry->hent_val)
	    entry->hent_val = NEWSV(62,0);
	sv_setpvn(entry->hent_val,content.dptr,content.dsize);
    }
#endif
    return entry->hent_val;
}

#ifdef SOME_DBM

#ifndef OP_CREAT
#  ifdef I_FCNTL
#    include <fcntl.h>
#  endif
#  ifdef I_SYS_FILE
#    include <sys/file.h>
#  endif
#endif

#ifndef OP_RDONLY
#define OP_RDONLY 0
#endif
#ifndef OP_RDWR
#define OP_RDWR 2
#endif
#ifndef OP_CREAT
#define OP_CREAT 01000
#endif

bool
hv_dbmopen(hv,fname,mode)
HV *hv;
char *fname;
I32 mode;
{
    register XPVHV* xhv;
    if (!hv)
	return FALSE;
    xhv = (XPVHV*)SvANY(hv);
#ifdef HAS_ODBM
    if (xhv->xhv_dbm)	/* never really closed it */
	return TRUE;
#endif
    if (xhv->xhv_dbm) {
	hv_dbmclose(hv);
	xhv->xhv_dbm = 0;
    }
    hv_clear(hv, FALSE);	/* clear cache */
#ifdef HAS_GDBM
    if (mode >= 0)
	xhv->xhv_dbm = gdbm_open(fname, 0, GDBM_WRCREAT,mode, (void *) NULL);
    if (!xhv->xhv_dbm)
	xhv->xhv_dbm = gdbm_open(fname, 0, GDBM_WRITER, mode, (void *) NULL);
    if (!xhv->xhv_dbm)
	xhv->xhv_dbm = gdbm_open(fname, 0, GDBM_READER, mode, (void *) NULL);
#else
#ifdef HAS_NDBM
    if (mode >= 0)
	xhv->xhv_dbm = dbm_open(fname, OP_RDWR|OP_CREAT, mode);
    if (!xhv->xhv_dbm)
	xhv->xhv_dbm = dbm_open(fname, OP_RDWR, mode);
    if (!xhv->xhv_dbm)
	xhv->xhv_dbm = dbm_open(fname, OP_RDONLY, mode);
#else
    if (dbmrefcnt++)
	fatal("Old dbm can only open one database");
    sprintf(buf,"%s.dir",fname);
    if (stat(buf, &statbuf) < 0) {
	if (mode < 0 || close(creat(buf,mode)) < 0)
	    return FALSE;
	sprintf(buf,"%s.pag",fname);
	if (close(creat(buf,mode)) < 0)
	    return FALSE;
    }
    xhv->xhv_dbm = dbminit(fname) >= 0;
#endif
#endif
    if (!xhv->xhv_array && xhv->xhv_dbm != 0)
	Newz(507,xhv->xhv_array, xhv->xhv_max + 1, HE*);
    hv_magic(hv, 0, 'D');
    return xhv->xhv_dbm != 0;
}

void
hv_dbmclose(hv)
HV *hv;
{
    register XPVHV* xhv;
    if (!hv)
	fatal("Bad associative array");
    xhv = (XPVHV*)SvANY(hv);
    if (xhv->xhv_dbm) {
#ifdef HAS_GDBM
	gdbm_close(xhv->xhv_dbm);
	xhv->xhv_dbm = 0;
#else
#ifdef HAS_NDBM
	dbm_close(xhv->xhv_dbm);
	xhv->xhv_dbm = 0;
#else
	/* dbmrefcnt--;  */	/* doesn't work, rats */
#endif
#endif
    }
    else if (dowarn)
	warn("Close on unopened dbm file");
}

bool
hv_dbmstore(hv,key,klen,sv)
HV *hv;
char *key;
U32 klen;
register SV *sv;
{
    register XPVHV* xhv;
    datum dkey, dcontent;
    I32 error;

    if (!hv)
	return FALSE;
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_dbm)
	return FALSE;
    dkey.dptr = key;
    dkey.dsize = klen;
    dcontent.dptr = SvPVn(sv);
    dcontent.dsize = SvCUR(sv);
#ifdef HAS_GDBM
    error = gdbm_store(xhv->xhv_dbm, dkey, dcontent, GDBM_REPLACE);
#else
    error = dbm_store(xhv->xhv_dbm, dkey, dcontent, DBM_REPLACE);
#endif
    if (error) {
	if (errno == EPERM)
	    fatal("No write permission to dbm file");
	fatal("dbm store returned %d, errno %d, key \"%s\"",error,errno,key);
#ifdef HAS_NDBM
        dbm_clearerr(xhv->xhv_dbm);
#endif
    }
    return !error;
}
#endif /* SOME_DBM */

#ifdef XXX
		magictype = MgTYPE(magic);
		switch (magictype) {
		case 'E':
		    environ[0] = Nullch;
		    break;
		case 'S':
#ifndef NSIG
#define NSIG 32
#endif
		    for (i = 1; i < NSIG; i++)
			signal(i, SIG_DFL);	/* crunch, crunch, crunch */
		    break;
		}

		    if (magic) {
			sv_magic(tmpstr, (SV*)tmpgv, magic, tmps, SvCUR(sv));
			sv_magicset(tmpstr, magic);
		    }

	if (hv->hv_sv.sv_rare && !sv->sv_magic)
	    sv_magic(sv, (GV*)hv, hv->hv_sv.sv_rare, key, keylen);
#endif

void
hv_magic(hv, gv, how)
HV* hv;
GV* gv;
I32 how;
{
    sv_magic(hv, gv, how, 0, 0);
}
