/* $Header: hash.c,v 3.0 89/10/18 15:18:32 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	hash.c,v $
 * Revision 3.0  89/10/18  15:18:32  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include <errno.h>

extern int errno;

STR *
hfetch(tb,key,klen,lval)
register HASH *tb;
char *key;
int klen;
int lval;
{
    register char *s;
    register int i;
    register int hash;
    register HENT *entry;
    register int maxi;
    STR *str;
#ifdef SOME_DBM
    datum dkey,dcontent;
#endif

    if (!tb)
	return Nullstr;

    /* The hash function we use on symbols has to be equal to the first
     * character when taken modulo 128, so that str_reset() can be implemented
     * efficiently.  We throw in the second character and the last character
     * (times 128) so that long chains of identifiers starting with the
     * same letter don't have to be strEQ'ed within hfetch(), since it
     * compares hash values before trying strEQ().
     */
    if (!tb->tbl_coeffsize)
	hash = *key + 128 * key[1] + 128 * key[klen-1];	/* assuming klen > 0 */
    else {	/* use normal coefficients */
	if (klen < tb->tbl_coeffsize)
	    maxi = klen;
	else
	    maxi = tb->tbl_coeffsize;
	for (s=key,		i=0,	hash = 0;
			    i < maxi;
	     s++,		i++,	hash *= 5) {
	    hash += *s * coeff[i];
	}
    }

    entry = tb->tbl_array[hash & tb->tbl_max];
    for (; entry; entry = entry->hent_next) {
	if (entry->hent_hash != hash)		/* strings can't be equal */
	    continue;
	if (entry->hent_klen != klen)
	    continue;
	if (bcmp(entry->hent_key,key,klen))	/* is this it? */
	    continue;
	return entry->hent_val;
    }
#ifdef SOME_DBM
    if (tb->tbl_dbm) {
	dkey.dptr = key;
	dkey.dsize = klen;
	dcontent = dbm_fetch(tb->tbl_dbm,dkey);
	if (dcontent.dptr) {			/* found one */
	    str = Str_new(60,dcontent.dsize);
	    str_nset(str,dcontent.dptr,dcontent.dsize);
	    hstore(tb,key,klen,str,hash);		/* cache it */
	    return str;
	}
    }
#endif
    if (lval) {		/* gonna assign to this, so it better be there */
	str = Str_new(61,0);
	hstore(tb,key,klen,str,hash);
	return str;
    }
    return Nullstr;
}

bool
hstore(tb,key,klen,val,hash)
register HASH *tb;
char *key;
int klen;
STR *val;
register int hash;
{
    register char *s;
    register int i;
    register HENT *entry;
    register HENT **oentry;
    register int maxi;

    if (!tb)
	return FALSE;

    if (hash)
	;
    else if (!tb->tbl_coeffsize)
	hash = *key + 128 * key[1] + 128 * key[klen-1];
    else {	/* use normal coefficients */
	if (klen < tb->tbl_coeffsize)
	    maxi = klen;
	else
	    maxi = tb->tbl_coeffsize;
	for (s=key,		i=0,	hash = 0;
			    i < maxi;
	     s++,		i++,	hash *= 5) {
	    hash += *s * coeff[i];
	}
    }

    oentry = &(tb->tbl_array[hash & tb->tbl_max]);
    i = 1;

    for (entry = *oentry; entry; i=0, entry = entry->hent_next) {
	if (entry->hent_hash != hash)		/* strings can't be equal */
	    continue;
	if (entry->hent_klen != klen)
	    continue;
	if (bcmp(entry->hent_key,key,klen))	/* is this it? */
	    continue;
	Safefree(entry->hent_val);
	entry->hent_val = val;
	return TRUE;
    }
    New(501,entry, 1, HENT);

    entry->hent_klen = klen;
    entry->hent_key = nsavestr(key,klen);
    entry->hent_val = val;
    entry->hent_hash = hash;
    entry->hent_next = *oentry;
    *oentry = entry;

    /* hdbmstore not necessary here because it's called from stabset() */

    if (i) {				/* initial entry? */
	tb->tbl_fill++;
#ifdef SOME_DBM
	if (tb->tbl_dbm && tb->tbl_max >= DBM_CACHE_MAX)
	    return FALSE;
#endif
	if (tb->tbl_fill > tb->tbl_dosplit)
	    hsplit(tb);
    }
#ifdef SOME_DBM
    else if (tb->tbl_dbm) {		/* is this just a cache for dbm file? */
	entry = tb->tbl_array[hash & tb->tbl_max];
	oentry = &entry->hent_next;
	entry = *oentry;
	while (entry) {	/* trim chain down to 1 entry */
	    *oentry = entry->hent_next;
	    hentfree(entry);		/* no doubt they'll want this next. */
	    entry = *oentry;
	}
    }
#endif

    return FALSE;
}

STR *
hdelete(tb,key,klen)
register HASH *tb;
char *key;
int klen;
{
    register char *s;
    register int i;
    register int hash;
    register HENT *entry;
    register HENT **oentry;
    STR *str;
    int maxi;
#ifdef SOME_DBM
    datum dkey;
#endif

    if (!tb)
	return Nullstr;
    if (!tb->tbl_coeffsize)
	hash = *key + 128 * key[1] + 128 * key[klen-1];
    else {	/* use normal coefficients */
	if (klen < tb->tbl_coeffsize)
	    maxi = klen;
	else
	    maxi = tb->tbl_coeffsize;
	for (s=key,		i=0,	hash = 0;
			    i < maxi;
	     s++,		i++,	hash *= 5) {
	    hash += *s * coeff[i];
	}
    }

    oentry = &(tb->tbl_array[hash & tb->tbl_max]);
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
	str = str_static(entry->hent_val);
	hentfree(entry);
	if (i)
	    tb->tbl_fill--;
#ifdef SOME_DBM
      do_dbm_delete:
	if (tb->tbl_dbm) {
	    dkey.dptr = key;
	    dkey.dsize = klen;
	    dbm_delete(tb->tbl_dbm,dkey);
	}
#endif
	return str;
    }
#ifdef SOME_DBM
    str = Nullstr;
    goto do_dbm_delete;
#else
    return Nullstr;
#endif
}

hsplit(tb)
HASH *tb;
{
    int oldsize = tb->tbl_max + 1;
    register int newsize = oldsize * 2;
    register int i;
    register HENT **a;
    register HENT **b;
    register HENT *entry;
    register HENT **oentry;

    a = tb->tbl_array;
    Renew(a, newsize, HENT*);
    Zero(&a[oldsize], oldsize, HENT*);		/* zero 2nd half*/
    tb->tbl_max = --newsize;
    tb->tbl_dosplit = tb->tbl_max * FILLPCT / 100;
    tb->tbl_array = a;

    for (i=0; i<oldsize; i++,a++) {
	if (!*a)				/* non-existent */
	    continue;
	b = a+oldsize;
	for (oentry = a, entry = *a; entry; entry = *oentry) {
	    if ((entry->hent_hash & newsize) != i) {
		*oentry = entry->hent_next;
		entry->hent_next = *b;
		if (!*b)
		    tb->tbl_fill++;
		*b = entry;
		continue;
	    }
	    else
		oentry = &entry->hent_next;
	}
	if (!*a)				/* everything moved */
	    tb->tbl_fill--;
    }
}

HASH *
hnew(lookat)
unsigned int lookat;
{
    register HASH *tb;

    Newz(502,tb, 1, HASH);
    if (lookat) {
	tb->tbl_coeffsize = lookat;
	tb->tbl_max = 7;		/* it's a normal associative array */
	tb->tbl_dosplit = tb->tbl_max * FILLPCT / 100;
    }
    else {
	tb->tbl_max = 127;		/* it's a symbol table */
	tb->tbl_dosplit = 128;		/* so never split */
    }
    Newz(503,tb->tbl_array, tb->tbl_max + 1, HENT*);
    tb->tbl_fill = 0;
#ifdef SOME_DBM
    tb->tbl_dbm = 0;
#endif
    (void)hiterinit(tb);	/* so each() will start off right */
    return tb;
}

void
hentfree(hent)
register HENT *hent;
{
    if (!hent)
	return;
    str_free(hent->hent_val);
    Safefree(hent->hent_key);
    Safefree(hent);
}

void
hclear(tb)
register HASH *tb;
{
    register HENT *hent;
    register HENT *ohent = Null(HENT*);

    if (!tb)
	return;
    (void)hiterinit(tb);
    while (hent = hiternext(tb)) {	/* concise but not very efficient */
	hentfree(ohent);
	ohent = hent;
    }
    hentfree(ohent);
    tb->tbl_fill = 0;
#ifndef lint
    (void)bzero((char*)tb->tbl_array, (tb->tbl_max + 1) * sizeof(HENT*));
#endif
}

void
hfree(tb)
register HASH *tb;
{
    register HENT *hent;
    register HENT *ohent = Null(HENT*);

    if (!tb)
	return;
    (void)hiterinit(tb);
    while (hent = hiternext(tb)) {
	hentfree(ohent);
	ohent = hent;
    }
    hentfree(ohent);
    Safefree(tb->tbl_array);
    Safefree(tb);
}

int
hiterinit(tb)
register HASH *tb;
{
    tb->tbl_riter = -1;
    tb->tbl_eiter = Null(HENT*);
    return tb->tbl_fill;
}

HENT *
hiternext(tb)
register HASH *tb;
{
    register HENT *entry;
#ifdef SOME_DBM
    datum key;
#endif

    entry = tb->tbl_eiter;
#ifdef SOME_DBM
    if (tb->tbl_dbm) {
	if (entry) {
#ifdef NDBM
#ifdef _CX_UX
	    key = dbm_nextkey(tb->tbl_dbm, key);
#else
	    key = dbm_nextkey(tb->tbl_dbm);
#endif /* _CX_UX */
#else
	    key.dptr = entry->hent_key;
	    key.dsize = entry->hent_klen;
	    key = nextkey(key);
#endif
	}
	else {
	    Newz(504,entry, 1, HENT);
	    tb->tbl_eiter = entry;
	    key = dbm_firstkey(tb->tbl_dbm);
	}
	entry->hent_key = key.dptr;
	entry->hent_klen = key.dsize;
	if (!key.dptr) {
	    if (entry->hent_val)
		str_free(entry->hent_val);
	    Safefree(entry);
	    tb->tbl_eiter = Null(HENT*);
	    return Null(HENT*);
	}
	return entry;
    }
#endif
    do {
	if (entry)
	    entry = entry->hent_next;
	if (!entry) {
	    tb->tbl_riter++;
	    if (tb->tbl_riter > tb->tbl_max) {
		tb->tbl_riter = -1;
		break;
	    }
	    entry = tb->tbl_array[tb->tbl_riter];
	}
    } while (!entry);

    tb->tbl_eiter = entry;
    return entry;
}

char *
hiterkey(entry,retlen)
register HENT *entry;
int *retlen;
{
    *retlen = entry->hent_klen;
    return entry->hent_key;
}

STR *
hiterval(tb,entry)
register HASH *tb;
register HENT *entry;
{
#ifdef SOME_DBM
    datum key, content;

    if (tb->tbl_dbm) {
	key.dptr = entry->hent_key;
	key.dsize = entry->hent_klen;
	content = dbm_fetch(tb->tbl_dbm,key);
	if (!entry->hent_val)
	    entry->hent_val = Str_new(62,0);
	str_nset(entry->hent_val,content.dptr,content.dsize);
    }
#endif
    return entry->hent_val;
}

#ifdef SOME_DBM
#if	defined(FCNTL) && ! defined(O_CREAT)
#include <fcntl.h>
#endif

#ifndef O_RDONLY
#define O_RDONLY 0
#endif
#ifndef O_RDWR
#define O_RDWR 2
#endif
#ifndef O_CREAT
#define O_CREAT 01000
#endif

#ifndef NDBM
static int dbmrefcnt = 0;
#endif

bool
hdbmopen(tb,fname,mode)
register HASH *tb;
char *fname;
int mode;
{
    if (!tb)
	return FALSE;
#ifndef NDBM
    if (tb->tbl_dbm)	/* never really closed it */
	return TRUE;
#endif
    if (tb->tbl_dbm)
	hdbmclose(tb);
    hclear(tb);
#ifdef NDBM
    tb->tbl_dbm = dbm_open(fname, O_RDWR|O_CREAT, mode);
    if (!tb->tbl_dbm)		/* oops, just try reading it */
	tb->tbl_dbm = dbm_open(fname, O_RDONLY, mode);
#else
    if (dbmrefcnt++)
	fatal("Old dbm can only open one database");
    sprintf(buf,"%s.dir",fname);
    if (stat(buf, &statbuf) < 0) {
	if (close(creat(buf,mode)) < 0)
	    return FALSE;
	sprintf(buf,"%s.pag",fname);
	if (close(creat(buf,mode)) < 0)
	    return FALSE;
    }
    tb->tbl_dbm = dbminit(fname) >= 0;
#endif
    return tb->tbl_dbm != 0;
}

void
hdbmclose(tb)
register HASH *tb;
{
    if (tb && tb->tbl_dbm) {
#ifdef NDBM
	dbm_close(tb->tbl_dbm);
	tb->tbl_dbm = 0;
#else
	/* dbmrefcnt--;  */	/* doesn't work, rats */
#endif
    }
    else if (dowarn)
	warn("Close on unopened dbm file");
}

bool
hdbmstore(tb,key,klen,str)
register HASH *tb;
char *key;
int klen;
register STR *str;
{
    datum dkey, dcontent;
    int error;

    if (!tb || !tb->tbl_dbm)
	return FALSE;
    dkey.dptr = key;
    dkey.dsize = klen;
    dcontent.dptr = str_get(str);
    dcontent.dsize = str->str_cur;
    error = dbm_store(tb->tbl_dbm, dkey, dcontent, DBM_REPLACE);
    if (error) {
	if (errno == EPERM)
	    fatal("No write permission to dbm file");
	warn("dbm store returned %d, errno %d, key \"%s\"",error,errno,key);
#ifdef NDBM
        dbm_clearerr(tb->tbl_dbm);
#endif
    }
    return !error;
}
#endif /* SOME_DBM */
