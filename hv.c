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
    SV *sv;

    if (!hv)
	return 0;

    if (SvMAGICAL(hv)) {
	if (mg_find((SV*)hv,'P')) {
	    sv = sv_2mortal(NEWSV(61,0));
	    mg_copy((SV*)hv, sv, key, klen);
	    if (!lval) {
		mg_get(sv);
		sv_unmagic(sv,'p');
	    }
	    Sv = sv;
	    return &Sv;
	}
    }

    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array) {
	if (lval)
	    Newz(503,xhv->xhv_array, sizeof(HE*) * (xhv->xhv_max + 1), char);
	else
	    return 0;
    }

    i = klen;
    hash = 0;
    s = key;
    while (i--)
	hash = hash * 33 + *s++;

    entry = ((HE**)xhv->xhv_array)[hash & xhv->xhv_max];
    for (; entry; entry = entry->hent_next) {
	if (entry->hent_hash != hash)		/* strings can't be equal */
	    continue;
	if (entry->hent_klen != klen)
	    continue;
	if (bcmp(entry->hent_key,key,klen))	/* is this it? */
	    continue;
	return &entry->hent_val;
    }
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

    if (!hv)
	return 0;

    xhv = (XPVHV*)SvANY(hv);
    if (SvMAGICAL(hv)) {
	MAGIC* mg = SvMAGIC(hv);
	mg_copy((SV*)hv, val, key, klen);
	if (!xhv->xhv_array)
	    return 0;
    }
    if (!hash) {
    i = klen;
    s = key;
    while (i--)
	hash = hash * 33 + *s++;
    }

    if (!xhv->xhv_array)
	Newz(505, xhv->xhv_array, sizeof(HE**) * (xhv->xhv_max + 1), char);

    oentry = &((HE**)xhv->xhv_array)[hash & xhv->xhv_max];
    i = 1;

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

    xhv->xhv_keys++;
    if (i) {				/* initial entry? */
	++xhv->xhv_fill;
	if (xhv->xhv_keys > xhv->xhv_max)
	    hsplit(hv);
    }

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

    if (!hv)
	return Nullsv;
    if (SvMAGICAL(hv)) {
	sv = *hv_fetch(hv, key, klen, TRUE);
	mg_clear(sv);
    }
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return Nullsv;
    i = klen;
    hash = 0;
    s = key;
    while (i--)
	hash = hash * 33 + *s++;

    oentry = &((HE**)xhv->xhv_array)[hash & xhv->xhv_max];
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
	--xhv->xhv_keys;
	return sv;
    }
    return Nullsv;
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

    a = (HE**)xhv->xhv_array;
    nomemok = TRUE;
    Renew(a, newsize, HE*);
    nomemok = FALSE;
    Zero(&a[oldsize], oldsize, HE*);		/* zero 2nd half*/
    xhv->xhv_max = --newsize;
    xhv->xhv_array = (char*)a;

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
newHV()
{
    register HV *hv;
    register XPVHV* xhv;

    Newz(502,hv, 1, HV);
    SvREFCNT(hv) = 1;
    sv_upgrade(hv, SVt_PVHV);
    xhv = (XPVHV*)SvANY(hv);
    SvPOK_off(hv);
    SvNOK_off(hv);
    xhv->xhv_max = 7;		/* start with 8 buckets */
    xhv->xhv_fill = 0;
    xhv->xhv_pmroot = 0;
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
hv_clear(hv)
HV *hv;
{
    register XPVHV* xhv;
    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    hfreeentries(hv);
    xhv->xhv_fill = 0;
    if (xhv->xhv_array)
	(void)memzero(xhv->xhv_array, (xhv->xhv_max + 1) * sizeof(HE*));
}

static void
hfreeentries(hv)
HV *hv;
{
    register XPVHV* xhv;
    register HE *hent;
    register HE *ohent = Null(HE*);

    if (!hv)
	return;
    xhv = (XPVHV*)SvANY(hv);
    if (!xhv->xhv_array)
	return;
    (void)hv_iterinit(hv);
    /*SUPPRESS 560*/
    while (hent = hv_iternext(hv)) {	/* concise but not very efficient */
	he_free(ohent);
	ohent = hent;
    }
    he_free(ohent);
    if (SvMAGIC(hv))
	mg_clear((SV*)hv);
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
    xhv->xhv_array = 0;
    xhv->xhv_max = 7;		/* it's a normal associative array */
    xhv->xhv_fill = 0;
    (void)hv_iterinit(hv);	/* so each() will start off right */
}

void
hv_free(hv)
register HV *hv;
{
    if (!hv)
	return;
    hfreeentries(hv);
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
    MAGIC* mg;

    if (!hv)
	croak("Bad associative array");
    xhv = (XPVHV*)SvANY(hv);
    entry = xhv->xhv_eiter;

    if (SvMAGICAL(hv) && (mg = mg_find((SV*)hv,'P'))) {
	SV *key = sv_2mortal(NEWSV(0,0));
        if (entry)
	    sv_setpvn(key, entry->hent_key, entry->hent_klen);
        else {
            Newz(504,entry, 1, HE);
            xhv->xhv_eiter = entry;
        }
	magic_nextpack(hv,mg,key);
        if (SvOK(key)) {
	    STRLEN len;
	    entry->hent_key = SvPV(key, len);
	    entry->hent_klen = len;
	    SvPOK_off(key);
	    SvPVX(key) = 0;
	    return entry;
        }
	if (entry->hent_val)
	    sv_free(entry->hent_val);
	Safefree(entry);
	xhv->xhv_eiter = Null(HE*);
	return Null(HE*);
    }

    if (!xhv->xhv_array)
	Newz(506,xhv->xhv_array, sizeof(HE*) * (xhv->xhv_max + 1), char);
    do {
	if (entry)
	    entry = entry->hent_next;
	if (!entry) {
	    xhv->xhv_riter++;
	    if (xhv->xhv_riter > xhv->xhv_max) {
		xhv->xhv_riter = -1;
		break;
	    }
	    entry = ((HE**)xhv->xhv_array)[xhv->xhv_riter];
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
    if (SvMAGICAL(hv)) {
	if (mg_find((SV*)hv,'P')) {
	    SV* sv = sv_2mortal(NEWSV(61,0));
	    mg_copy((SV*)hv, sv, entry->hent_key, entry->hent_klen);
	    mg_get(sv);
	    sv_unmagic(sv,'p');
	    return sv;
	}
    }
    return entry->hent_val;
}

void
hv_magic(hv, gv, how)
HV* hv;
GV* gv;
I32 how;
{
    sv_magic((SV*)hv, (SV*)gv, how, 0, 0);
}
