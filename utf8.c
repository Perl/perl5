/*    utf8.c
 *
 *    Copyright (c) 1998-1999, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * 'What a fix!' said Sam. 'That's the one place in all the lands we've ever
 * heard of that we don't want to see any closer; and that's the one place
 * we're trying to get to!  And that's just where we can't get, nohow.'
 *
 * 'Well do I understand your speech,' he answered in the same language;
 * 'yet few strangers do so.  Why then do you not speak in the Common Tongue,
 * as is the custom in the West, if you wish to be answered?'
 *
 * ...the travellers perceived that the floor was paved with stones of many
 * hues; branching runes and strange devices intertwined beneath their feet.
 */

#include "EXTERN.h"
#include "perl.h"

/* Unicode support */

U8 *
uv_to_utf8(U8 *d, UV uv)
{
    if (uv < 0x80) {
	*d++ = uv;
	return d;
    }
    if (uv < 0x800) {
	*d++ = (( uv >>  6)         | 0xc0);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x10000) {
	*d++ = (( uv >> 12)         | 0xe0);
	*d++ = (((uv >>  6) & 0x3f) | 0x80);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x200000) {
	*d++ = (( uv >> 18)         | 0xf0);
	*d++ = (((uv >> 12) & 0x3f) | 0x80);
	*d++ = (((uv >>  6) & 0x3f) | 0x80);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x4000000) {
	*d++ = (( uv >> 24)         | 0xf8);
	*d++ = (((uv >> 18) & 0x3f) | 0x80);
	*d++ = (((uv >> 12) & 0x3f) | 0x80);
	*d++ = (((uv >>  6) & 0x3f) | 0x80);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x80000000) {
	*d++ = (( uv >> 30)         | 0xfc);
	*d++ = (((uv >> 24) & 0x3f) | 0x80);
	*d++ = (((uv >> 18) & 0x3f) | 0x80);
	*d++ = (((uv >> 12) & 0x3f) | 0x80);
	*d++ = (((uv >>  6) & 0x3f) | 0x80);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
#ifdef Quad_t
    if (uv < 0x2000000000)
#endif
    {
	*d++ =                        0xfe;	/* Can't match U+FEFF! */
	*d++ = (((uv >> 30) & 0x3f) | 0x80);
	*d++ = (((uv >> 24) & 0x3f) | 0x80);
	*d++ = (((uv >> 18) & 0x3f) | 0x80);
	*d++ = (((uv >> 12) & 0x3f) | 0x80);
	*d++ = (((uv >>  6) & 0x3f) | 0x80);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
#ifdef Quad_t
    {
	*d++ =                        0xff;	/* Can't match U+FFFE! */
	*d++ = (((uv >> 36) & 0x3f) | 0x80);
	*d++ = (((uv >> 30) & 0x3f) | 0x80);
	*d++ = (((uv >> 24) & 0x3f) | 0x80);
	*d++ = (((uv >> 18) & 0x3f) | 0x80);
	*d++ = (((uv >> 12) & 0x3f) | 0x80);
	*d++ = (((uv >>  6) & 0x3f) | 0x80);
	*d++ = (( uv        & 0x3f) | 0x80);
	return d;
    }
#endif
}

UV
utf8_to_uv(U8* s, I32* retlen)
{
    UV uv = *s;
    int len;
    if (!(uv & 0x80)) {
	if (retlen)
	    *retlen = 1;
	return *s;
    }
    if (!(uv & 0x40)) {
	warn("Malformed UTF-8 character");
	if (retlen)
	    *retlen = 1;
	return *s;
    }

    if      (!(uv & 0x20))	{ len = 2; uv &= 0x1f; }
    else if (!(uv & 0x10))	{ len = 3; uv &= 0x0f; }
    else if (!(uv & 0x08))	{ len = 4; uv &= 0x07; }
    else if (!(uv & 0x04))	{ len = 5; uv &= 0x03; }
    else if (!(uv & 0x02))	{ len = 6; uv &= 0x01; }
    else if (!(uv & 0x01))	{ len = 7; uv &= 0x00; }
    else 			  len = 8;	/* whoa! */

    if (retlen)
	*retlen = len;
    --len;
    s++;
    while (len--) {
	if ((*s & 0xc0) != 0x80) {
	    warn("Malformed UTF-8 character");
	    if (retlen)
		*retlen -= len + 1;
	    return 0xfffd;
	}
	else
	    uv = (uv << 6) | (*s++ & 0x3f);
    }
    return uv;
}

/* utf8_distance(a,b) is intended to be a - b in pointer arithmetic */

I32
utf8_distance(U8 *a, U8 *b)
{
    I32 off = 0;
    if (a < b) {
	while (a < b) {
	    a += UTF8SKIP(a);
	    off--;
	}
    }
    else {
	while (b < a) {
	    b += UTF8SKIP(b);
	    off++;
	}
    }
    return off;
}

/* WARNING: do not use the following unless you *know* off is within bounds */

U8 *
utf8_hop(U8 *s, I32 off)
{
    if (off >= 0) {
	while (off--)
	    s += UTF8SKIP(s);
    }
    else {
	while (off++) {
	    s--;
	    if (*s & 0x80) {
		while ((*s & 0xc0) == 0x80)
		    s--;
	    }
	}
    }
    return s;
}

/* XXX NOTHING CALLS THE FOLLOWING TWO ROUTINES YET!!! */
/*
 * Convert native or reversed UTF-16 to UTF-8.
 *
 * Destination must be pre-extended to 3/2 source.  Do not use in-place.
 * We optimize for native, for obvious reasons. */

U8*
utf16_to_utf8(U16* p, U8* d, I32 bytelen)
{
    U16* pend = p + bytelen / 2;
    while (p < pend) {
	UV uv = *p++;
	if (uv < 0x80) {
	    *d++ = uv;
	    continue;
	}
	if (uv < 0x800) {
	    *d++ = (( uv >>  6)         | 0xc0);
	    *d++ = (( uv        & 0x3f) | 0x80);
	    continue;
	}
	if (uv >= 0xd800 && uv < 0xdbff) {	/* surrogates */
	    int low = *p++;
	    if (low < 0xdc00 || low >= 0xdfff) {
		warn("Malformed UTF-16 surrogate");
		p--;
		uv = 0xfffd;
	    }
	    uv = ((uv - 0xd800) << 10) + (low - 0xdc00) + 0x10000;
	}
	if (uv < 0x10000) {
	    *d++ = (( uv >> 12)         | 0xe0);
	    *d++ = (((uv >>  6) & 0x3f) | 0x80);
	    *d++ = (( uv        & 0x3f) | 0x80);
	    continue;
	}
	else {
	    *d++ = (( uv >> 18)         | 0xf0);
	    *d++ = (((uv >> 12) & 0x3f) | 0x80);
	    *d++ = (((uv >>  6) & 0x3f) | 0x80);
	    *d++ = (( uv        & 0x3f) | 0x80);
	    continue;
	}
    }
    return d;
}

/* Note: this one is slightly destructive of the source. */

U8*
utf16_to_utf8_reversed(U16* p, U8* d, I32 bytelen)
{
    U8* s = (U8*)p;
    U8* send = s + bytelen;
    while (s < send) {
	U8 tmp = s[0];
	s[0] = s[1];
	s[1] = tmp;
	s += 2;
    }
    return utf16_to_utf8(p, d, bytelen);
}

/* for now these are all defined (inefficiently) in terms of the utf8 versions */

bool
is_uni_alnum(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_alnum(tmpbuf);
}

bool
is_uni_idfirst(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_idfirst(tmpbuf);
}

bool
is_uni_alpha(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_alpha(tmpbuf);
}

bool
is_uni_space(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_space(tmpbuf);
}

bool
is_uni_digit(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_digit(tmpbuf);
}

bool
is_uni_upper(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_upper(tmpbuf);
}

bool
is_uni_lower(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_lower(tmpbuf);
}

bool
is_uni_print(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return is_utf8_print(tmpbuf);
}

U32
to_uni_upper(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return to_utf8_upper(tmpbuf);
}

U32
to_uni_title(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return to_utf8_title(tmpbuf);
}

U32
to_uni_lower(U32 c)
{
    U8 tmpbuf[10];
    uv_to_utf8(tmpbuf, (UV)c);
    return to_utf8_lower(tmpbuf);
}

/* for now these all assume no locale info available for Unicode > 255 */

bool
is_uni_alnum_lc(U32 c)
{
    return is_uni_alnum(c);	/* XXX no locale support yet */
}

bool
is_uni_idfirst_lc(U32 c)
{
    return is_uni_idfirst(c);	/* XXX no locale support yet */
}

bool
is_uni_alpha_lc(U32 c)
{
    return is_uni_alpha(c);	/* XXX no locale support yet */
}

bool
is_uni_space_lc(U32 c)
{
    return is_uni_space(c);	/* XXX no locale support yet */
}

bool
is_uni_digit_lc(U32 c)
{
    return is_uni_digit(c);	/* XXX no locale support yet */
}

bool
is_uni_upper_lc(U32 c)
{
    return is_uni_upper(c);	/* XXX no locale support yet */
}

bool
is_uni_lower_lc(U32 c)
{
    return is_uni_lower(c);	/* XXX no locale support yet */
}

bool
is_uni_print_lc(U32 c)
{
    return is_uni_print(c);	/* XXX no locale support yet */
}

U32
to_uni_upper_lc(U32 c)
{
    return to_uni_upper(c);	/* XXX no locale support yet */
}

U32
to_uni_title_lc(U32 c)
{
    return to_uni_title(c);	/* XXX no locale support yet */
}

U32
to_uni_lower_lc(U32 c)
{
    return to_uni_lower(c);	/* XXX no locale support yet */
}


bool
is_utf8_alnum(U8 *p)
{
    if (!PL_utf8_alnum)
	PL_utf8_alnum = swash_init("utf8", "IsAlnum", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_alnum, p);
/*    return *p == '_' || is_utf8_alpha(p) || is_utf8_digit(p); */
#ifdef SURPRISINGLY_SLOWER  /* probably because alpha is usually true */
    if (!PL_utf8_alnum)
	PL_utf8_alnum = swash_init("utf8", "",
	    sv_2mortal(newSVpv("+utf8::IsAlpha\n+utf8::IsDigit\n005F\n",0)), 0, 0);
    return swash_fetch(PL_utf8_alnum, p);
#endif
}

bool
is_utf8_idfirst(U8 *p)
{
    return *p == '_' || is_utf8_alpha(p);
}

bool
is_utf8_alpha(U8 *p)
{
    if (!PL_utf8_alpha)
	PL_utf8_alpha = swash_init("utf8", "IsAlpha", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_alpha, p);
}

bool
is_utf8_space(U8 *p)
{
    if (!PL_utf8_space)
	PL_utf8_space = swash_init("utf8", "IsSpace", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_space, p);
}

bool
is_utf8_digit(U8 *p)
{
    if (!PL_utf8_digit)
	PL_utf8_digit = swash_init("utf8", "IsDigit", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_digit, p);
}

bool
is_utf8_upper(U8 *p)
{
    if (!PL_utf8_upper)
	PL_utf8_upper = swash_init("utf8", "IsUpper", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_upper, p);
}

bool
is_utf8_lower(U8 *p)
{
    if (!PL_utf8_lower)
	PL_utf8_lower = swash_init("utf8", "IsLower", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_lower, p);
}

bool
is_utf8_print(U8 *p)
{
    if (!PL_utf8_print)
	PL_utf8_print = swash_init("utf8", "IsPrint", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_print, p);
}

bool
is_utf8_mark(U8 *p)
{
    if (!PL_utf8_mark)
	PL_utf8_mark = swash_init("utf8", "IsM", &PL_sv_undef, 0, 0);
    return swash_fetch(PL_utf8_mark, p);
}

UV
to_utf8_upper(U8 *p)
{
    UV uv;

    if (!PL_utf8_toupper)
	PL_utf8_toupper = swash_init("utf8", "ToUpper", &PL_sv_undef, 4, 0);
    uv = swash_fetch(PL_utf8_toupper, p);
    return uv ? uv : utf8_to_uv(p,0);
}

UV
to_utf8_title(U8 *p)
{
    UV uv;

    if (!PL_utf8_totitle)
	PL_utf8_totitle = swash_init("utf8", "ToTitle", &PL_sv_undef, 4, 0);
    uv = swash_fetch(PL_utf8_totitle, p);
    return uv ? uv : utf8_to_uv(p,0);
}

UV
to_utf8_lower(U8 *p)
{
    UV uv;

    if (!PL_utf8_tolower)
	PL_utf8_tolower = swash_init("utf8", "ToLower", &PL_sv_undef, 4, 0);
    uv = swash_fetch(PL_utf8_tolower, p);
    return uv ? uv : utf8_to_uv(p,0);
}

/* a "swash" is a swatch hash */

SV*
swash_init(char* pkg, char* name, SV *listsv, I32 minbits, I32 none)
{
    SV* retval;
    char tmpbuf[256];
    dSP;    
    PUSHSTACKi(PERLSI_MAGIC);
    PUSHMARK(SP);
    EXTEND(SP,5);
    PUSHs(sv_2mortal(newSVpvn(pkg, strlen(pkg))));
    PUSHs(sv_2mortal(newSVpvn(name, strlen(name))));
    PUSHs(listsv);
    PUSHs(sv_2mortal(newSViv(minbits)));
    PUSHs(sv_2mortal(newSViv(none)));
    PUTBACK;
    ENTER;
    SAVEI32(PL_hints);
    PL_hints = 0;
    save_re_context();
    if (PL_curcop == &PL_compiling)	/* XXX ought to be handled by lex_start */
	strncpy(tmpbuf, PL_tokenbuf, sizeof tmpbuf);
    if (perl_call_method("SWASHNEW", G_SCALAR))
	retval = newSVsv(*PL_stack_sp--);    
    else
	retval = &PL_sv_undef;
    LEAVE;
    POPSTACK;
    if (PL_curcop == &PL_compiling) {
	strncpy(PL_tokenbuf, tmpbuf, sizeof tmpbuf);
	PL_curcop->op_private = PL_hints;
    }
    if (!SvROK(retval) || SvTYPE(SvRV(retval)) != SVt_PVHV)
	croak("SWASHNEW didn't return an HV ref");
    return retval;
}

UV
swash_fetch(SV *sv, U8 *ptr)
{
    HV* hv = (HV*)SvRV(sv);
    U32 klen = UTF8SKIP(ptr) - 1;
    U32 off = ptr[klen] & 127;  /* NB: 64 bit always 0 when len > 1 */
    STRLEN slen;
    STRLEN needents = (klen ? 64 : 128);
    U8 *tmps;
    U32 bit;
    SV *retval;

    /*
     * This single-entry cache saves about 1/3 of the utf8 overhead in test
     * suite.  (That is, only 7-8% overall over just a hash cache.  Still,
     * it's nothing to sniff at.)  Pity we usually come through at least
     * two function calls to get here...
     *
     * NB: this code assumes that swatches are never modified, once generated!
     */

    if (hv == PL_last_swash_hv &&
	klen == PL_last_swash_klen &&
	(!klen || memEQ(ptr,PL_last_swash_key,klen)) )
    {
	tmps = PL_last_swash_tmps;
	slen = PL_last_swash_slen;
    }
    else {
	/* Try our second-level swatch cache, kept in a hash. */
	SV** svp = hv_fetch(hv, (char*)ptr, klen, FALSE);

	/* If not cached, generate it via utf8::SWASHGET */
	if (!svp || !SvPOK(*svp) || !(tmps = (U8*)SvPV(*svp, slen))) {
	    dSP;
	    ENTER;
	    SAVETMPS;
	    save_re_context();
	    PUSHSTACKi(PERLSI_MAGIC);
	    PUSHMARK(SP);
	    EXTEND(SP,3);
	    PUSHs((SV*)sv);
	    PUSHs(sv_2mortal(newSViv(utf8_to_uv(ptr, 0) & ~(needents - 1))));
	    PUSHs(sv_2mortal(newSViv(needents)));
	    PUTBACK;
	    if (perl_call_method("SWASHGET", G_SCALAR))
		retval = newSVsv(*PL_stack_sp--);    
	    else
		retval = &PL_sv_undef;
	    POPSTACK;
	    FREETMPS;
	    LEAVE;
	    if (PL_curcop == &PL_compiling)
		PL_curcop->op_private = PL_hints;

	    svp = hv_store(hv, (char*)ptr, klen, retval, 0);

	    if (!svp || !(tmps = (U8*)SvPV(*svp, slen)) || slen < 8)
		croak("SWASHGET didn't return result of proper length");
	}

	PL_last_swash_hv = hv;
	PL_last_swash_klen = klen;
	PL_last_swash_tmps = tmps;
	PL_last_swash_slen = slen;
	if (klen)
	    Copy(ptr, PL_last_swash_key, klen, U8);
    }

    switch ((slen << 3) / needents) {
    case 1:
	bit = 1 << (off & 7);
	off >>= 3;
	return (tmps[off] & bit) != 0;
    case 8:
	return tmps[off];
    case 16:
	off <<= 1;
	return (tmps[off] << 8) + tmps[off + 1] ;
    case 32:
	off <<= 2;
	return (tmps[off] << 24) + (tmps[off+1] << 16) + (tmps[off+2] << 8) + tmps[off + 3] ;
    }
    croak("panic: swash_fetch");
    return 0;
}
