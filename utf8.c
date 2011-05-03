/*    utf8.c
 *
 *    Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008
 *    by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * 'What a fix!' said Sam.  'That's the one place in all the lands we've ever
 *  heard of that we don't want to see any closer; and that's the one place
 *  we're trying to get to!  And that's just where we can't get, nohow.'
 *
 *     [p.603 of _The Lord of the Rings_, IV/I: "The Taming of Sméagol"]
 *
 * 'Well do I understand your speech,' he answered in the same language;
 * 'yet few strangers do so.  Why then do you not speak in the Common Tongue,
 *  as is the custom in the West, if you wish to be answered?'
 *                           --Gandalf, addressing Théoden's door wardens
 *
 *     [p.508 of _The Lord of the Rings_, III/vi: "The King of the Golden Hall"]
 *
 * ...the travellers perceived that the floor was paved with stones of many
 * hues; branching runes and strange devices intertwined beneath their feet.
 *
 *     [p.512 of _The Lord of the Rings_, III/vi: "The King of the Golden Hall"]
 */

#include "EXTERN.h"
#define PERL_IN_UTF8_C
#include "perl.h"

#ifndef EBCDIC
/* Separate prototypes needed because in ASCII systems these are
 * usually macros but they still are compiled as code, too. */
PERL_CALLCONV UV	Perl_utf8n_to_uvchr(pTHX_ const U8 *s, STRLEN curlen, STRLEN *retlen, U32 flags);
PERL_CALLCONV U8*	Perl_uvchr_to_utf8(pTHX_ U8 *d, UV uv);
#endif

static const char unees[] =
    "Malformed UTF-8 character (unexpected end of string)";

/*
=head1 Unicode Support

This file contains various utility functions for manipulating UTF8-encoded
strings. For the uninitiated, this is a method of representing arbitrary
Unicode characters as a variable number of bytes, in such a way that
characters in the ASCII range are unmodified, and a zero byte never appears
within non-zero characters.

=cut
*/

/*
=for apidoc is_ascii_string

Returns true if the first C<len> bytes of the given string are the same whether
or not the string is encoded in UTF-8 (or UTF-EBCDIC on EBCDIC machines).  That
is, if they are invariant.  On ASCII-ish machines, only ASCII characters
fit this definition, hence the function's name.

If C<len> is 0, it will be calculated using C<strlen(s)>.  

See also is_utf8_string(), is_utf8_string_loclen(), and is_utf8_string_loc().

=cut
*/

bool
Perl_is_ascii_string(const U8 *s, STRLEN len)
{
    const U8* const send = s + (len ? len : strlen((const char *)s));
    const U8* x = s;

    PERL_ARGS_ASSERT_IS_ASCII_STRING;

    for (; x < send; ++x) {
	if (!UTF8_IS_INVARIANT(*x))
	    break;
    }

    return x == send;
}

/*
=for apidoc uvuni_to_utf8_flags

Adds the UTF-8 representation of the code point C<uv> to the end
of the string C<d>; C<d> should have at least C<UTF8_MAXBYTES+1> free
bytes available. The return value is the pointer to the byte after the
end of the new character. In other words,

    d = uvuni_to_utf8_flags(d, uv, flags);

or, in most cases,

    d = uvuni_to_utf8(d, uv);

(which is equivalent to)

    d = uvuni_to_utf8_flags(d, uv, 0);

This is the recommended Unicode-aware way of saying

    *(d++) = uv;

This function will convert to UTF-8 (and not warn) even code points that aren't
legal Unicode or are problematic, unless C<flags> contains one or more of the
following flags.
If C<uv> is a Unicode surrogate code point and UNICODE_WARN_SURROGATE is set,
the function will raise a warning, provided UTF8 warnings are enabled.  If instead
UNICODE_DISALLOW_SURROGATE is set, the function will fail and return NULL.
If both flags are set, the function will both warn and return NULL.

The UNICODE_WARN_NONCHAR and UNICODE_DISALLOW_NONCHAR flags correspondingly
affect how the function handles a Unicode non-character.  And, likewise for the
UNICODE_WARN_SUPER and UNICODE_DISALLOW_SUPER flags, and code points that are
above the Unicode maximum of 0x10FFFF.  Code points above 0x7FFF_FFFF (which are
even less portable) can be warned and/or disallowed even if other above-Unicode
code points are accepted by the UNICODE_WARN_FE_FF and UNICODE_DISALLOW_FE_FF
flags.

And finally, the flag UNICODE_WARN_ILLEGAL_INTERCHANGE selects all four of the
above WARN flags; and UNICODE_DISALLOW_ILLEGAL_INTERCHANGE selects all four
DISALLOW flags.


=cut
*/

U8 *
Perl_uvuni_to_utf8_flags(pTHX_ U8 *d, UV uv, UV flags)
{
    PERL_ARGS_ASSERT_UVUNI_TO_UTF8_FLAGS;

    if (ckWARN_d(WARN_UTF8)) {
	if (UNICODE_IS_SURROGATE(uv)) {
	    if (flags & UNICODE_WARN_SURROGATE) {
		Perl_ck_warner_d(aTHX_ packWARN(WARN_SURROGATE),
					    "UTF-16 surrogate U+%04"UVXf, uv);
	    }
	    if (flags & UNICODE_DISALLOW_SURROGATE) {
		return NULL;
	    }
	}
	else if (UNICODE_IS_SUPER(uv)) {
	    if (flags & UNICODE_WARN_SUPER
		|| (UNICODE_IS_FE_FF(uv) && (flags & UNICODE_WARN_FE_FF)))
	    {
		Perl_ck_warner_d(aTHX_ packWARN(WARN_NON_UNICODE),
			  "Code point 0x%04"UVXf" is not Unicode, may not be portable", uv);
	    }
	    if (flags & UNICODE_DISALLOW_SUPER
		|| (UNICODE_IS_FE_FF(uv) && (flags & UNICODE_DISALLOW_FE_FF)))
	    {
		return NULL;
	    }
	}
	else if (UNICODE_IS_NONCHAR(uv)) {
	    if (flags & UNICODE_WARN_NONCHAR) {
		Perl_ck_warner_d(aTHX_ packWARN(WARN_NONCHAR),
		 "Unicode non-character U+%04"UVXf" is illegal for open interchange",
		 uv);
	    }
	    if (flags & UNICODE_DISALLOW_NONCHAR) {
		return NULL;
	    }
	}
    }
    if (UNI_IS_INVARIANT(uv)) {
	*d++ = (U8)UTF_TO_NATIVE(uv);
	return d;
    }
#if defined(EBCDIC)
    else {
	STRLEN len  = UNISKIP(uv);
	U8 *p = d+len-1;
	while (p > d) {
	    *p-- = (U8)UTF_TO_NATIVE((uv & UTF_CONTINUATION_MASK) | UTF_CONTINUATION_MARK);
	    uv >>= UTF_ACCUMULATION_SHIFT;
	}
	*p = (U8)UTF_TO_NATIVE((uv & UTF_START_MASK(len)) | UTF_START_MARK(len));
	return d+len;
    }
#else /* Non loop style */
    if (uv < 0x800) {
	*d++ = (U8)(( uv >>  6)         | 0xc0);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x10000) {
	*d++ = (U8)(( uv >> 12)         | 0xe0);
	*d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x200000) {
	*d++ = (U8)(( uv >> 18)         | 0xf0);
	*d++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x4000000) {
	*d++ = (U8)(( uv >> 24)         | 0xf8);
	*d++ = (U8)(((uv >> 18) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
    if (uv < 0x80000000) {
	*d++ = (U8)(( uv >> 30)         | 0xfc);
	*d++ = (U8)(((uv >> 24) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 18) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
#ifdef HAS_QUAD
    if (uv < UTF8_QUAD_MAX)
#endif
    {
	*d++ =                            0xfe;	/* Can't match U+FEFF! */
	*d++ = (U8)(((uv >> 30) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 24) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 18) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
#ifdef HAS_QUAD
    {
	*d++ =                            0xff;		/* Can't match U+FFFE! */
	*d++ =                            0x80;		/* 6 Reserved bits */
	*d++ = (U8)(((uv >> 60) & 0x0f) | 0x80);	/* 2 Reserved bits */
	*d++ = (U8)(((uv >> 54) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 48) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 42) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 36) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 30) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 24) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 18) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*d++ = (U8)(( uv        & 0x3f) | 0x80);
	return d;
    }
#endif
#endif /* Loop style */
}

/*

Tests if some arbitrary number of bytes begins in a valid UTF-8
character.  Note that an INVARIANT (i.e. ASCII) character is a valid
UTF-8 character.  The actual number of bytes in the UTF-8 character
will be returned if it is valid, otherwise 0.

This is the "slow" version as opposed to the "fast" version which is
the "unrolled" IS_UTF8_CHAR().  E.g. for t/uni/class.t the speed
difference is a factor of 2 to 3.  For lengths (UTF8SKIP(s)) of four
or less you should use the IS_UTF8_CHAR(), for lengths of five or more
you should use the _slow().  In practice this means that the _slow()
will be used very rarely, since the maximum Unicode code point (as of
Unicode 4.1) is U+10FFFF, which encodes in UTF-8 to four bytes.  Only
the "Perl extended UTF-8" (the infamous 'v-strings') will encode into
five bytes or more.

=cut */
STATIC STRLEN
S_is_utf8_char_slow(const U8 *s, const STRLEN len)
{
    U8 u = *s;
    STRLEN slen;
    UV uv, ouv;

    PERL_ARGS_ASSERT_IS_UTF8_CHAR_SLOW;

    if (UTF8_IS_INVARIANT(u))
	return 1;

    if (!UTF8_IS_START(u))
	return 0;

    if (len < 2 || !UTF8_IS_CONTINUATION(s[1]))
	return 0;

    slen = len - 1;
    s++;
#ifdef EBCDIC
    u = NATIVE_TO_UTF(u);
#endif
    u &= UTF_START_MASK(len);
    uv  = u;
    ouv = uv;
    while (slen--) {
	if (!UTF8_IS_CONTINUATION(*s))
	    return 0;
	uv = UTF8_ACCUMULATE(uv, *s);
	if (uv < ouv)
	    return 0;
	ouv = uv;
	s++;
    }

    if ((STRLEN)UNISKIP(uv) < len)
	return 0;

    return len;
}

/*
=for apidoc is_utf8_char

Tests if some arbitrary number of bytes begins in a valid UTF-8
character.  Note that an INVARIANT (i.e. ASCII on non-EBCDIC machines)
character is a valid UTF-8 character.  The actual number of bytes in the UTF-8
character will be returned if it is valid, otherwise 0.

=cut */
STRLEN
Perl_is_utf8_char(const U8 *s)
{
    const STRLEN len = UTF8SKIP(s);

    PERL_ARGS_ASSERT_IS_UTF8_CHAR;
#ifdef IS_UTF8_CHAR
    if (IS_UTF8_CHAR_FAST(len))
        return IS_UTF8_CHAR(s, len) ? len : 0;
#endif /* #ifdef IS_UTF8_CHAR */
    return is_utf8_char_slow(s, len);
}


/*
=for apidoc is_utf8_string

Returns true if first C<len> bytes of the given string form a valid
UTF-8 string, false otherwise.  If C<len> is 0, it will be calculated
using C<strlen(s)>.  Note that 'a valid UTF-8 string' does not mean 'a
string that contains code points above 0x7F encoded in UTF-8' because a
valid ASCII string is a valid UTF-8 string.

See also is_ascii_string(), is_utf8_string_loclen(), and is_utf8_string_loc().

=cut
*/

bool
Perl_is_utf8_string(const U8 *s, STRLEN len)
{
    const U8* const send = s + (len ? len : strlen((const char *)s));
    const U8* x = s;

    PERL_ARGS_ASSERT_IS_UTF8_STRING;

    while (x < send) {
	STRLEN c;
	 /* Inline the easy bits of is_utf8_char() here for speed... */
	 if (UTF8_IS_INVARIANT(*x))
	      c = 1;
	 else if (!UTF8_IS_START(*x))
	     goto out;
	 else {
	      /* ... and call is_utf8_char() only if really needed. */
#ifdef IS_UTF8_CHAR
	     c = UTF8SKIP(x);
	     if (IS_UTF8_CHAR_FAST(c)) {
	         if (!IS_UTF8_CHAR(x, c))
		     c = 0;
	     }
	     else
		c = is_utf8_char_slow(x, c);
#else
	     c = is_utf8_char(x);
#endif /* #ifdef IS_UTF8_CHAR */
	      if (!c)
		  goto out;
	 }
        x += c;
    }

 out:
    if (x != send)
	return FALSE;

    return TRUE;
}

/*
Implemented as a macro in utf8.h

=for apidoc is_utf8_string_loc

Like is_utf8_string() but stores the location of the failure (in the
case of "utf8ness failure") or the location s+len (in the case of
"utf8ness success") in the C<ep>.

See also is_utf8_string_loclen() and is_utf8_string().

=for apidoc is_utf8_string_loclen

Like is_utf8_string() but stores the location of the failure (in the
case of "utf8ness failure") or the location s+len (in the case of
"utf8ness success") in the C<ep>, and the number of UTF-8
encoded characters in the C<el>.

See also is_utf8_string_loc() and is_utf8_string().

=cut
*/

bool
Perl_is_utf8_string_loclen(const U8 *s, STRLEN len, const U8 **ep, STRLEN *el)
{
    const U8* const send = s + (len ? len : strlen((const char *)s));
    const U8* x = s;
    STRLEN c;
    STRLEN outlen = 0;

    PERL_ARGS_ASSERT_IS_UTF8_STRING_LOCLEN;

    while (x < send) {
	 /* Inline the easy bits of is_utf8_char() here for speed... */
	 if (UTF8_IS_INVARIANT(*x))
	     c = 1;
	 else if (!UTF8_IS_START(*x))
	     goto out;
	 else {
	     /* ... and call is_utf8_char() only if really needed. */
#ifdef IS_UTF8_CHAR
	     c = UTF8SKIP(x);
	     if (IS_UTF8_CHAR_FAST(c)) {
	         if (!IS_UTF8_CHAR(x, c))
		     c = 0;
	     } else
	         c = is_utf8_char_slow(x, c);
#else
	     c = is_utf8_char(x);
#endif /* #ifdef IS_UTF8_CHAR */
	     if (!c)
	         goto out;
	 }
         x += c;
	 outlen++;
    }

 out:
    if (el)
        *el = outlen;

    if (ep)
        *ep = x;
    return (x == send);
}

/*

=for apidoc utf8n_to_uvuni

Bottom level UTF-8 decode routine.
Returns the code point value of the first character in the string C<s>
which is assumed to be in UTF-8 (or UTF-EBCDIC) encoding and no longer than
C<curlen> bytes; C<retlen> will be set to the length, in bytes, of that
character.

The value of C<flags> determines the behavior when C<s> does not point to a
well-formed UTF-8 character.  If C<flags> is 0, when a malformation is found,
C<retlen> is set to the expected length of the UTF-8 character in bytes, zero
is returned, and if UTF-8 warnings haven't been lexically disabled, a warning
is raised.

Various ALLOW flags can be set in C<flags> to allow (and not warn on)
individual types of malformations, such as the sequence being overlong (that
is, when there is a shorter sequence that can express the same code point;
overlong sequences are expressly forbidden in the UTF-8 standard due to
potential security issues).  Another malformation example is the first byte of
a character not being a legal first byte.  See F<utf8.h> for the list of such
flags.  Of course, the value returned by this function under such conditions is
not reliable.

The UTF8_CHECK_ONLY flag overrides the behavior when a non-allowed (by other
flags) malformation is found.  If this flag is set, the routine assumes that
the caller will raise a warning, and this function will silently just set
C<retlen> to C<-1> and return zero.

Certain code points are considered problematic.  These are Unicode surrogates,
Unicode non-characters, and code points above the Unicode maximum of 0x10FFF.
By default these are considered regular code points, but certain situations
warrant special handling for them.  if C<flags> contains
UTF8_DISALLOW_ILLEGAL_INTERCHANGE, all three classes are treated as
malformations and handled as such.  The flags UTF8_DISALLOW_SURROGATE,
UTF8_DISALLOW_NONCHAR, and UTF8_DISALLOW_SUPER (meaning above the legal Unicode
maximum) can be set to disallow these categories individually.

The flags UTF8_WARN_ILLEGAL_INTERCHANGE, UTF8_WARN_SURROGATE,
UTF8_WARN_NONCHAR, and UTF8_WARN_SUPER will cause warning messages to be raised
for their respective categories, but otherwise the code points are considered
valid (not malformations).  To get a category to both be treated as a
malformation and raise a warning, specify both the WARN and DISALLOW flags.
(But note that warnings are not raised if lexically disabled nor if
UTF8_CHECK_ONLY is also specified.)

Very large code points (above 0x7FFF_FFFF) are considered more problematic than
the others that are above the Unicode legal maximum.  There are several
reasons, one of which is that the original UTF-8 specification never went above
this number (the current 0x10FFF limit was imposed later).  The UTF-8 encoding
on ASCII platforms for these large code point begins with a byte containing
0xFE or 0xFF.  The UTF8_DISALLOW_FE_FF flag will cause them to be treated as
malformations, while allowing smaller above-Unicode code points.  (Of course
UTF8_DISALLOW_SUPER will treat all above-Unicode code points, including these,
as malformations.) Similarly, UTF8_WARN_FE_FF acts just like the other WARN
flags, but applies just to these code points.

All other code points corresponding to Unicode characters, including private
use and those yet to be assigned, are never considered malformed and never
warn.

Most code should use utf8_to_uvchr() rather than call this directly.

=cut
*/

UV
Perl_utf8n_to_uvuni(pTHX_ const U8 *s, STRLEN curlen, STRLEN *retlen, U32 flags)
{
    dVAR;
    const U8 * const s0 = s;
    UV uv = *s, ouv = 0;
    STRLEN len = 1;
    bool dowarn = ckWARN_d(WARN_UTF8);
    const UV startbyte = *s;
    STRLEN expectlen = 0;
    U32 warning = 0;
    SV* sv = NULL;

    PERL_ARGS_ASSERT_UTF8N_TO_UVUNI;

/* This list is a superset of the UTF8_ALLOW_XXX. */

#define UTF8_WARN_EMPTY				 1
#define UTF8_WARN_CONTINUATION			 2
#define UTF8_WARN_NON_CONTINUATION	 	 3
#define UTF8_WARN_SHORT				 4
#define UTF8_WARN_OVERFLOW			 5
#define UTF8_WARN_LONG				 6

    if (curlen == 0 &&
	!(flags & UTF8_ALLOW_EMPTY)) {
	warning = UTF8_WARN_EMPTY;
	goto malformed;
    }

    if (UTF8_IS_INVARIANT(uv)) {
	if (retlen)
	    *retlen = 1;
	return (UV) (NATIVE_TO_UTF(*s));
    }

    if (UTF8_IS_CONTINUATION(uv) &&
	!(flags & UTF8_ALLOW_CONTINUATION)) {
	warning = UTF8_WARN_CONTINUATION;
	goto malformed;
    }

    if (UTF8_IS_START(uv) && curlen > 1 && !UTF8_IS_CONTINUATION(s[1]) &&
	!(flags & UTF8_ALLOW_NON_CONTINUATION)) {
	warning = UTF8_WARN_NON_CONTINUATION;
	goto malformed;
    }

#ifdef EBCDIC
    uv = NATIVE_TO_UTF(uv);
#else
    if (uv == 0xfe || uv == 0xff) {
	if (flags & (UTF8_WARN_SUPER|UTF8_WARN_FE_FF)) {
	    sv = sv_2mortal(Perl_newSVpvf(aTHX_ "Code point beginning with byte 0x%02"UVXf" is not Unicode, and not portable", uv));
	    flags &= ~UTF8_WARN_SUPER;	/* Only warn once on this problem */
	}
	if (flags & (UTF8_DISALLOW_SUPER|UTF8_DISALLOW_FE_FF)) {
	    goto malformed;
	}
    }
#endif

    if      (!(uv & 0x20))	{ len =  2; uv &= 0x1f; }
    else if (!(uv & 0x10))	{ len =  3; uv &= 0x0f; }
    else if (!(uv & 0x08))	{ len =  4; uv &= 0x07; }
    else if (!(uv & 0x04))	{ len =  5; uv &= 0x03; }
#ifdef EBCDIC
    else if (!(uv & 0x02))	{ len =  6; uv &= 0x01; }
    else			{ len =  7; uv &= 0x01; }
#else
    else if (!(uv & 0x02))	{ len =  6; uv &= 0x01; }
    else if (!(uv & 0x01))	{ len =  7; uv = 0; }
    else			{ len = 13; uv = 0; } /* whoa! */
#endif

    if (retlen)
	*retlen = len;

    expectlen = len;

    if ((curlen < expectlen) &&
	!(flags & UTF8_ALLOW_SHORT)) {
	warning = UTF8_WARN_SHORT;
	goto malformed;
    }

    len--;
    s++;
    ouv = uv;	/* ouv is the value from the previous iteration */

    while (len--) {
	if (!UTF8_IS_CONTINUATION(*s) &&
	    !(flags & UTF8_ALLOW_NON_CONTINUATION)) {
	    s--;
	    warning = UTF8_WARN_NON_CONTINUATION;
	    goto malformed;
	}
	else
	    uv = UTF8_ACCUMULATE(uv, *s);
	if (!(uv > ouv)) {  /* If the value didn't grow from the previous
			       iteration, something is horribly wrong */
	    /* These cannot be allowed. */
	    if (uv == ouv) {
		if (expectlen != 13 && !(flags & UTF8_ALLOW_LONG)) {
		    warning = UTF8_WARN_LONG;
		    goto malformed;
		}
	    }
	    else { /* uv < ouv */
		/* This cannot be allowed. */
		warning = UTF8_WARN_OVERFLOW;
		goto malformed;
	    }
	}
	s++;
	ouv = uv;
    }

    if ((expectlen > (STRLEN)UNISKIP(uv)) && !(flags & UTF8_ALLOW_LONG)) {
	warning = UTF8_WARN_LONG;
	goto malformed;
    } else if (flags & (UTF8_DISALLOW_ILLEGAL_INTERCHANGE|UTF8_WARN_ILLEGAL_INTERCHANGE)) {
	if (UNICODE_IS_SURROGATE(uv)) {
	    if ((flags & (UTF8_WARN_SURROGATE|UTF8_CHECK_ONLY)) == UTF8_WARN_SURROGATE) {
		sv = sv_2mortal(Perl_newSVpvf(aTHX_ "UTF-16 surrogate U+%04"UVXf"", uv));
	    }
	    if (flags & UTF8_DISALLOW_SURROGATE) {
		goto disallowed;
	    }
	}
	else if (UNICODE_IS_NONCHAR(uv)) {
	    if ((flags & (UTF8_WARN_NONCHAR|UTF8_CHECK_ONLY)) == UTF8_WARN_NONCHAR ) {
		sv = sv_2mortal(Perl_newSVpvf(aTHX_ "Unicode non-character U+%04"UVXf" is illegal for open interchange", uv));
	    }
	    if (flags & UTF8_DISALLOW_NONCHAR) {
		goto disallowed;
	    }
	}
	else if ((uv > PERL_UNICODE_MAX)) {
	    if ((flags & (UTF8_WARN_SUPER|UTF8_CHECK_ONLY)) == UTF8_WARN_SUPER) {
		sv = sv_2mortal(Perl_newSVpvf(aTHX_ "Code point 0x%04"UVXf" is not Unicode, may not be portable", uv));
	    }
	    if (flags & UTF8_DISALLOW_SUPER) {
		goto disallowed;
	    }
	}

	/* Here, this is not considered a malformed character, so drop through
	 * to return it */
    }

    return uv;

disallowed: /* Is disallowed, but otherwise not malformed.  'sv' will have been
	       set if there is to be a warning. */
    if (!sv) {
	dowarn = 0;
    }

malformed:

    if (flags & UTF8_CHECK_ONLY) {
	if (retlen)
	    *retlen = ((STRLEN) -1);
	return 0;
    }

    if (dowarn) {
	if (! sv) {
	    sv = newSVpvs_flags("Malformed UTF-8 character ", SVs_TEMP);
	}

	switch (warning) {
	    case 0: /* Intentionally empty. */ break;
	    case UTF8_WARN_EMPTY:
		sv_catpvs(sv, "(empty string)");
		break;
	    case UTF8_WARN_CONTINUATION:
		Perl_sv_catpvf(aTHX_ sv, "(unexpected continuation byte 0x%02"UVxf", with no preceding start byte)", uv);
		break;
	    case UTF8_WARN_NON_CONTINUATION:
		if (s == s0)
		    Perl_sv_catpvf(aTHX_ sv, "(unexpected non-continuation byte 0x%02"UVxf", immediately after start byte 0x%02"UVxf")",
				(UV)s[1], startbyte);
		else {
		    const int len = (int)(s-s0);
		    Perl_sv_catpvf(aTHX_ sv, "(unexpected non-continuation byte 0x%02"UVxf", %d byte%s after start byte 0x%02"UVxf", expected %d bytes)",
				(UV)s[1], len, len > 1 ? "s" : "", startbyte, (int)expectlen);
		}

		break;
	    case UTF8_WARN_SHORT:
		Perl_sv_catpvf(aTHX_ sv, "(%d byte%s, need %d, after start byte 0x%02"UVxf")",
				(int)curlen, curlen == 1 ? "" : "s", (int)expectlen, startbyte);
		expectlen = curlen;		/* distance for caller to skip */
		break;
	    case UTF8_WARN_OVERFLOW:
		Perl_sv_catpvf(aTHX_ sv, "(overflow at 0x%"UVxf", byte 0x%02x, after start byte 0x%02"UVxf")",
				ouv, *s, startbyte);
		break;
	    case UTF8_WARN_LONG:
		Perl_sv_catpvf(aTHX_ sv, "(%d byte%s, need %d, after start byte 0x%02"UVxf")",
				(int)expectlen, expectlen == 1 ? "": "s", UNISKIP(uv), startbyte);
		break;
	    default:
		sv_catpvs(sv, "(unknown reason)");
		break;
	}
	
	if (sv) {
	    const char * const s = SvPVX_const(sv);

	    if (PL_op)
		Perl_warner(aTHX_ packWARN(WARN_UTF8),
			    "%s in %s", s,  OP_DESC(PL_op));
	    else
		Perl_warner(aTHX_ packWARN(WARN_UTF8), "%s", s);
	}
    }

    if (retlen)
	*retlen = expectlen ? expectlen : len;

    return 0;
}

/*
=for apidoc utf8_to_uvchr

Returns the native code point of the first character in the string C<s>
which is assumed to be in UTF-8 encoding; C<retlen> will be set to the
length, in bytes, of that character.

If C<s> does not point to a well-formed UTF-8 character, zero is
returned and retlen is set, if possible, to -1.

=cut
*/


UV
Perl_utf8_to_uvchr(pTHX_ const U8 *s, STRLEN *retlen)
{
    PERL_ARGS_ASSERT_UTF8_TO_UVCHR;

    return utf8n_to_uvchr(s, UTF8_MAXBYTES, retlen,
			  ckWARN_d(WARN_UTF8) ? 0 : UTF8_ALLOW_ANY);
}

/*
=for apidoc utf8_to_uvuni

Returns the Unicode code point of the first character in the string C<s>
which is assumed to be in UTF-8 encoding; C<retlen> will be set to the
length, in bytes, of that character.

This function should only be used when the returned UV is considered
an index into the Unicode semantic tables (e.g. swashes).

If C<s> does not point to a well-formed UTF-8 character, zero is
returned and retlen is set, if possible, to -1.

=cut
*/

UV
Perl_utf8_to_uvuni(pTHX_ const U8 *s, STRLEN *retlen)
{
    PERL_ARGS_ASSERT_UTF8_TO_UVUNI;

    /* Call the low level routine asking for checks */
    return Perl_utf8n_to_uvuni(aTHX_ s, UTF8_MAXBYTES, retlen,
			       ckWARN_d(WARN_UTF8) ? 0 : UTF8_ALLOW_ANY);
}

/*
=for apidoc utf8_length

Return the length of the UTF-8 char encoded string C<s> in characters.
Stops at C<e> (inclusive).  If C<e E<lt> s> or if the scan would end
up past C<e>, croaks.

=cut
*/

STRLEN
Perl_utf8_length(pTHX_ const U8 *s, const U8 *e)
{
    dVAR;
    STRLEN len = 0;

    PERL_ARGS_ASSERT_UTF8_LENGTH;

    /* Note: cannot use UTF8_IS_...() too eagerly here since e.g.
     * the bitops (especially ~) can create illegal UTF-8.
     * In other words: in Perl UTF-8 is not just for Unicode. */

    if (e < s)
	goto warn_and_return;
    while (s < e) {
	if (!UTF8_IS_INVARIANT(*s))
	    s += UTF8SKIP(s);
	else
	    s++;
	len++;
    }

    if (e != s) {
	len--;
        warn_and_return:
	if (PL_op)
	    Perl_ck_warner_d(aTHX_ packWARN(WARN_UTF8),
			     "%s in %s", unees, OP_DESC(PL_op));
	else
	    Perl_ck_warner_d(aTHX_ packWARN(WARN_UTF8), "%s", unees);
    }

    return len;
}

/*
=for apidoc utf8_distance

Returns the number of UTF-8 characters between the UTF-8 pointers C<a>
and C<b>.

WARNING: use only if you *know* that the pointers point inside the
same UTF-8 buffer.

=cut
*/

IV
Perl_utf8_distance(pTHX_ const U8 *a, const U8 *b)
{
    PERL_ARGS_ASSERT_UTF8_DISTANCE;

    return (a < b) ? -1 * (IV) utf8_length(a, b) : (IV) utf8_length(b, a);
}

/*
=for apidoc utf8_hop

Return the UTF-8 pointer C<s> displaced by C<off> characters, either
forward or backward.

WARNING: do not use the following unless you *know* C<off> is within
the UTF-8 data pointed to by C<s> *and* that on entry C<s> is aligned
on the first byte of character or just after the last byte of a character.

=cut
*/

U8 *
Perl_utf8_hop(pTHX_ const U8 *s, I32 off)
{
    PERL_ARGS_ASSERT_UTF8_HOP;

    PERL_UNUSED_CONTEXT;
    /* Note: cannot use UTF8_IS_...() too eagerly here since e.g
     * the bitops (especially ~) can create illegal UTF-8.
     * In other words: in Perl UTF-8 is not just for Unicode. */

    if (off >= 0) {
	while (off--)
	    s += UTF8SKIP(s);
    }
    else {
	while (off++) {
	    s--;
	    while (UTF8_IS_CONTINUATION(*s))
		s--;
	}
    }
    return (U8 *)s;
}

/*
=for apidoc bytes_cmp_utf8

Compares the sequence of characters (stored as octets) in b, blen with the
sequence of characters (stored as UTF-8) in u, ulen. Returns 0 if they are
equal, -1 or -2 if the first string is less than the second string, +1 or +2
if the first string is greater than the second string.

-1 or +1 is returned if the shorter string was identical to the start of the
longer string. -2 or +2 is returned if the was a difference between characters
within the strings.

=cut
*/

int
Perl_bytes_cmp_utf8(pTHX_ const U8 *b, STRLEN blen, const U8 *u, STRLEN ulen)
{
    const U8 *const bend = b + blen;
    const U8 *const uend = u + ulen;

    PERL_ARGS_ASSERT_BYTES_CMP_UTF8;

    PERL_UNUSED_CONTEXT;

    while (b < bend && u < uend) {
        U8 c = *u++;
	if (!UTF8_IS_INVARIANT(c)) {
	    if (UTF8_IS_DOWNGRADEABLE_START(c)) {
		if (u < uend) {
		    U8 c1 = *u++;
		    if (UTF8_IS_CONTINUATION(c1)) {
			c = UNI_TO_NATIVE(TWO_BYTE_UTF8_TO_UNI(c, c1));
		    } else {
			Perl_ck_warner_d(aTHX_ packWARN(WARN_UTF8),
					 "Malformed UTF-8 character "
					 "(unexpected non-continuation byte 0x%02x"
					 ", immediately after start byte 0x%02x)"
					 /* Dear diag.t, it's in the pod.  */
					 "%s%s", c1, c,
					 PL_op ? " in " : "",
					 PL_op ? OP_DESC(PL_op) : "");
			return -2;
		    }
		} else {
		    if (PL_op)
			Perl_ck_warner_d(aTHX_ packWARN(WARN_UTF8),
					 "%s in %s", unees, OP_DESC(PL_op));
		    else
			Perl_ck_warner_d(aTHX_ packWARN(WARN_UTF8), "%s", unees);
		    return -2; /* Really want to return undef :-)  */
		}
	    } else {
		return -2;
	    }
	}
	if (*b != c) {
	    return *b < c ? -2 : +2;
	}
	++b;
    }

    if (b == bend && u == uend)
	return 0;

    return b < bend ? +1 : -1;
}

/*
=for apidoc utf8_to_bytes

Converts a string C<s> of length C<len> from UTF-8 into native byte encoding.
Unlike C<bytes_to_utf8>, this over-writes the original string, and
updates len to contain the new length.
Returns zero on failure, setting C<len> to -1.

If you need a copy of the string, see C<bytes_from_utf8>.

=cut
*/

U8 *
Perl_utf8_to_bytes(pTHX_ U8 *s, STRLEN *len)
{
    U8 * const save = s;
    U8 * const send = s + *len;
    U8 *d;

    PERL_ARGS_ASSERT_UTF8_TO_BYTES;

    /* ensure valid UTF-8 and chars < 256 before updating string */
    while (s < send) {
        U8 c = *s++;

        if (!UTF8_IS_INVARIANT(c) &&
            (!UTF8_IS_DOWNGRADEABLE_START(c) || (s >= send)
	     || !(c = *s++) || !UTF8_IS_CONTINUATION(c))) {
            *len = ((STRLEN) -1);
            return 0;
        }
    }

    d = s = save;
    while (s < send) {
        STRLEN ulen;
        *d++ = (U8)utf8_to_uvchr(s, &ulen);
        s += ulen;
    }
    *d = '\0';
    *len = d - save;
    return save;
}

/*
=for apidoc bytes_from_utf8

Converts a string C<s> of length C<len> from UTF-8 into native byte encoding.
Unlike C<utf8_to_bytes> but like C<bytes_to_utf8>, returns a pointer to
the newly-created string, and updates C<len> to contain the new
length.  Returns the original string if no conversion occurs, C<len>
is unchanged. Do nothing if C<is_utf8> points to 0. Sets C<is_utf8> to
0 if C<s> is converted or consisted entirely of characters that are invariant
in utf8 (i.e., US-ASCII on non-EBCDIC machines).

=cut
*/

U8 *
Perl_bytes_from_utf8(pTHX_ const U8 *s, STRLEN *len, bool *is_utf8)
{
    U8 *d;
    const U8 *start = s;
    const U8 *send;
    I32 count = 0;

    PERL_ARGS_ASSERT_BYTES_FROM_UTF8;

    PERL_UNUSED_CONTEXT;
    if (!*is_utf8)
        return (U8 *)start;

    /* ensure valid UTF-8 and chars < 256 before converting string */
    for (send = s + *len; s < send;) {
        U8 c = *s++;
	if (!UTF8_IS_INVARIANT(c)) {
	    if (UTF8_IS_DOWNGRADEABLE_START(c) && s < send &&
                (c = *s++) && UTF8_IS_CONTINUATION(c))
		count++;
	    else
                return (U8 *)start;
	}
    }

    *is_utf8 = FALSE;

    Newx(d, (*len) - count + 1, U8);
    s = start; start = d;
    while (s < send) {
	U8 c = *s++;
	if (!UTF8_IS_INVARIANT(c)) {
	    /* Then it is two-byte encoded */
	    c = UNI_TO_NATIVE(TWO_BYTE_UTF8_TO_UNI(c, *s++));
	}
	*d++ = c;
    }
    *d = '\0';
    *len = d - start;
    return (U8 *)start;
}

/*
=for apidoc bytes_to_utf8

Converts a string C<s> of length C<len> bytes from the native encoding into
UTF-8.
Returns a pointer to the newly-created string, and sets C<len> to
reflect the new length in bytes.

A NUL character will be written after the end of the string.

If you want to convert to UTF-8 from encodings other than
the native (Latin1 or EBCDIC),
see sv_recode_to_utf8().

=cut
*/

U8*
Perl_bytes_to_utf8(pTHX_ const U8 *s, STRLEN *len)
{
    const U8 * const send = s + (*len);
    U8 *d;
    U8 *dst;

    PERL_ARGS_ASSERT_BYTES_TO_UTF8;
    PERL_UNUSED_CONTEXT;

    Newx(d, (*len) * 2 + 1, U8);
    dst = d;

    while (s < send) {
        const UV uv = NATIVE_TO_ASCII(*s++);
        if (UNI_IS_INVARIANT(uv))
            *d++ = (U8)UTF_TO_NATIVE(uv);
        else {
            *d++ = (U8)UTF8_EIGHT_BIT_HI(uv);
            *d++ = (U8)UTF8_EIGHT_BIT_LO(uv);
        }
    }
    *d = '\0';
    *len = d-dst;
    return dst;
}

/*
 * Convert native (big-endian) or reversed (little-endian) UTF-16 to UTF-8.
 *
 * Destination must be pre-extended to 3/2 source.  Do not use in-place.
 * We optimize for native, for obvious reasons. */

U8*
Perl_utf16_to_utf8(pTHX_ U8* p, U8* d, I32 bytelen, I32 *newlen)
{
    U8* pend;
    U8* dstart = d;

    PERL_ARGS_ASSERT_UTF16_TO_UTF8;

    if (bytelen & 1)
	Perl_croak(aTHX_ "panic: utf16_to_utf8: odd bytelen %"UVuf, (UV)bytelen);

    pend = p + bytelen;

    while (p < pend) {
	UV uv = (p[0] << 8) + p[1]; /* UTF-16BE */
	p += 2;
	if (uv < 0x80) {
#ifdef EBCDIC
	    *d++ = UNI_TO_NATIVE(uv);
#else
	    *d++ = (U8)uv;
#endif
	    continue;
	}
	if (uv < 0x800) {
	    *d++ = (U8)(( uv >>  6)         | 0xc0);
	    *d++ = (U8)(( uv        & 0x3f) | 0x80);
	    continue;
	}
	if (uv >= 0xd800 && uv <= 0xdbff) {	/* surrogates */
	    if (p >= pend) {
		Perl_croak(aTHX_ "Malformed UTF-16 surrogate");
	    } else {
		UV low = (p[0] << 8) + p[1];
		p += 2;
		if (low < 0xdc00 || low > 0xdfff)
		    Perl_croak(aTHX_ "Malformed UTF-16 surrogate");
		uv = ((uv - 0xd800) << 10) + (low - 0xdc00) + 0x10000;
	    }
	} else if (uv >= 0xdc00 && uv <= 0xdfff) {
	    Perl_croak(aTHX_ "Malformed UTF-16 surrogate");
	}
	if (uv < 0x10000) {
	    *d++ = (U8)(( uv >> 12)         | 0xe0);
	    *d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	    *d++ = (U8)(( uv        & 0x3f) | 0x80);
	    continue;
	}
	else {
	    *d++ = (U8)(( uv >> 18)         | 0xf0);
	    *d++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	    *d++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	    *d++ = (U8)(( uv        & 0x3f) | 0x80);
	    continue;
	}
    }
    *newlen = d - dstart;
    return d;
}

/* Note: this one is slightly destructive of the source. */

U8*
Perl_utf16_to_utf8_reversed(pTHX_ U8* p, U8* d, I32 bytelen, I32 *newlen)
{
    U8* s = (U8*)p;
    U8* const send = s + bytelen;

    PERL_ARGS_ASSERT_UTF16_TO_UTF8_REVERSED;

    if (bytelen & 1)
	Perl_croak(aTHX_ "panic: utf16_to_utf8_reversed: odd bytelen %"UVuf,
		   (UV)bytelen);

    while (s < send) {
	const U8 tmp = s[0];
	s[0] = s[1];
	s[1] = tmp;
	s += 2;
    }
    return utf16_to_utf8(p, d, bytelen, newlen);
}

/* for now these are all defined (inefficiently) in terms of the utf8 versions */

bool
Perl_is_uni_alnum(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_alnum(tmpbuf);
}

bool
Perl_is_uni_idfirst(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_idfirst(tmpbuf);
}

bool
Perl_is_uni_alpha(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_alpha(tmpbuf);
}

bool
Perl_is_uni_ascii(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_ascii(tmpbuf);
}

bool
Perl_is_uni_space(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_space(tmpbuf);
}

bool
Perl_is_uni_digit(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_digit(tmpbuf);
}

bool
Perl_is_uni_upper(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_upper(tmpbuf);
}

bool
Perl_is_uni_lower(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_lower(tmpbuf);
}

bool
Perl_is_uni_cntrl(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_cntrl(tmpbuf);
}

bool
Perl_is_uni_graph(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_graph(tmpbuf);
}

bool
Perl_is_uni_print(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_print(tmpbuf);
}

bool
Perl_is_uni_punct(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_punct(tmpbuf);
}

bool
Perl_is_uni_xdigit(pTHX_ UV c)
{
    U8 tmpbuf[UTF8_MAXBYTES_CASE+1];
    uvchr_to_utf8(tmpbuf, c);
    return is_utf8_xdigit(tmpbuf);
}

UV
Perl_to_uni_upper(pTHX_ UV c, U8* p, STRLEN *lenp)
{
    PERL_ARGS_ASSERT_TO_UNI_UPPER;

    uvchr_to_utf8(p, c);
    return to_utf8_upper(p, p, lenp);
}

UV
Perl_to_uni_title(pTHX_ UV c, U8* p, STRLEN *lenp)
{
    PERL_ARGS_ASSERT_TO_UNI_TITLE;

    uvchr_to_utf8(p, c);
    return to_utf8_title(p, p, lenp);
}

UV
Perl_to_uni_lower(pTHX_ UV c, U8* p, STRLEN *lenp)
{
    PERL_ARGS_ASSERT_TO_UNI_LOWER;

    uvchr_to_utf8(p, c);
    return to_utf8_lower(p, p, lenp);
}

UV
Perl__to_uni_fold_flags(pTHX_ UV c, U8* p, STRLEN *lenp, U8 flags)
{
    PERL_ARGS_ASSERT__TO_UNI_FOLD_FLAGS;

    uvchr_to_utf8(p, c);
    return _to_utf8_fold_flags(p, p, lenp, flags);
}

/* for now these all assume no locale info available for Unicode > 255 */

bool
Perl_is_uni_alnum_lc(pTHX_ UV c)
{
    return is_uni_alnum(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_idfirst_lc(pTHX_ UV c)
{
    return is_uni_idfirst(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_alpha_lc(pTHX_ UV c)
{
    return is_uni_alpha(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_ascii_lc(pTHX_ UV c)
{
    return is_uni_ascii(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_space_lc(pTHX_ UV c)
{
    return is_uni_space(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_digit_lc(pTHX_ UV c)
{
    return is_uni_digit(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_upper_lc(pTHX_ UV c)
{
    return is_uni_upper(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_lower_lc(pTHX_ UV c)
{
    return is_uni_lower(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_cntrl_lc(pTHX_ UV c)
{
    return is_uni_cntrl(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_graph_lc(pTHX_ UV c)
{
    return is_uni_graph(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_print_lc(pTHX_ UV c)
{
    return is_uni_print(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_punct_lc(pTHX_ UV c)
{
    return is_uni_punct(c);	/* XXX no locale support yet */
}

bool
Perl_is_uni_xdigit_lc(pTHX_ UV c)
{
    return is_uni_xdigit(c);	/* XXX no locale support yet */
}

U32
Perl_to_uni_upper_lc(pTHX_ U32 c)
{
    /* XXX returns only the first character -- do not use XXX */
    /* XXX no locale support yet */
    STRLEN len;
    U8 tmpbuf[UTF8_MAXBYTES_CASE+1];
    return (U32)to_uni_upper(c, tmpbuf, &len);
}

U32
Perl_to_uni_title_lc(pTHX_ U32 c)
{
    /* XXX returns only the first character XXX -- do not use XXX */
    /* XXX no locale support yet */
    STRLEN len;
    U8 tmpbuf[UTF8_MAXBYTES_CASE+1];
    return (U32)to_uni_title(c, tmpbuf, &len);
}

U32
Perl_to_uni_lower_lc(pTHX_ U32 c)
{
    /* XXX returns only the first character -- do not use XXX */
    /* XXX no locale support yet */
    STRLEN len;
    U8 tmpbuf[UTF8_MAXBYTES_CASE+1];
    return (U32)to_uni_lower(c, tmpbuf, &len);
}

static bool
S_is_utf8_common(pTHX_ const U8 *const p, SV **swash,
		 const char *const swashname)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_COMMON;

    if (!is_utf8_char(p))
	return FALSE;
    if (!*swash)
	*swash = swash_init("utf8", swashname, &PL_sv_undef, 1, 0);
    return swash_fetch(*swash, p, TRUE) != 0;
}

bool
Perl_is_utf8_alnum(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_ALNUM;

    /* NOTE: "IsWord", not "IsAlnum", since Alnum is a true
     * descendant of isalnum(3), in other words, it doesn't
     * contain the '_'. --jhi */
    return is_utf8_common(p, &PL_utf8_alnum, "IsWord");
}

bool
Perl_is_utf8_idfirst(pTHX_ const U8 *p) /* The naming is historical. */
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_IDFIRST;

    if (*p == '_')
	return TRUE;
    /* is_utf8_idstart would be more logical. */
    return is_utf8_common(p, &PL_utf8_idstart, "IdStart");
}

bool
Perl_is_utf8_xidfirst(pTHX_ const U8 *p) /* The naming is historical. */
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_XIDFIRST;

    if (*p == '_')
	return TRUE;
    /* is_utf8_idstart would be more logical. */
    return is_utf8_common(p, &PL_utf8_xidstart, "XIdStart");
}

bool
Perl_is_utf8_idcont(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_IDCONT;

    if (*p == '_')
	return TRUE;
    return is_utf8_common(p, &PL_utf8_idcont, "IdContinue");
}

bool
Perl_is_utf8_xidcont(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_XIDCONT;

    if (*p == '_')
	return TRUE;
    return is_utf8_common(p, &PL_utf8_idcont, "XIdContinue");
}

bool
Perl_is_utf8_alpha(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_ALPHA;

    return is_utf8_common(p, &PL_utf8_alpha, "IsAlpha");
}

bool
Perl_is_utf8_ascii(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_ASCII;

    return is_utf8_common(p, &PL_utf8_ascii, "IsAscii");
}

bool
Perl_is_utf8_space(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_SPACE;

    return is_utf8_common(p, &PL_utf8_space, "IsSpacePerl");
}

bool
Perl_is_utf8_perl_space(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_PERL_SPACE;

    return is_utf8_common(p, &PL_utf8_perl_space, "IsPerlSpace");
}

bool
Perl_is_utf8_perl_word(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_PERL_WORD;

    return is_utf8_common(p, &PL_utf8_perl_word, "IsPerlWord");
}

bool
Perl_is_utf8_digit(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_DIGIT;

    return is_utf8_common(p, &PL_utf8_digit, "IsDigit");
}

bool
Perl_is_utf8_posix_digit(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_POSIX_DIGIT;

    return is_utf8_common(p, &PL_utf8_posix_digit, "IsPosixDigit");
}

bool
Perl_is_utf8_upper(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_UPPER;

    return is_utf8_common(p, &PL_utf8_upper, "IsUppercase");
}

bool
Perl_is_utf8_lower(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_LOWER;

    return is_utf8_common(p, &PL_utf8_lower, "IsLowercase");
}

bool
Perl_is_utf8_cntrl(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_CNTRL;

    return is_utf8_common(p, &PL_utf8_cntrl, "IsCntrl");
}

bool
Perl_is_utf8_graph(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_GRAPH;

    return is_utf8_common(p, &PL_utf8_graph, "IsGraph");
}

bool
Perl_is_utf8_print(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_PRINT;

    return is_utf8_common(p, &PL_utf8_print, "IsPrint");
}

bool
Perl_is_utf8_punct(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_PUNCT;

    return is_utf8_common(p, &PL_utf8_punct, "IsPunct");
}

bool
Perl_is_utf8_xdigit(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_XDIGIT;

    return is_utf8_common(p, &PL_utf8_xdigit, "IsXDigit");
}

bool
Perl_is_utf8_mark(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_MARK;

    return is_utf8_common(p, &PL_utf8_mark, "IsM");
}

bool
Perl_is_utf8_X_begin(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_BEGIN;

    return is_utf8_common(p, &PL_utf8_X_begin, "_X_Begin");
}

bool
Perl_is_utf8_X_extend(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_EXTEND;

    return is_utf8_common(p, &PL_utf8_X_extend, "_X_Extend");
}

bool
Perl_is_utf8_X_prepend(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_PREPEND;

    return is_utf8_common(p, &PL_utf8_X_prepend, "GCB=Prepend");
}

bool
Perl_is_utf8_X_non_hangul(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_NON_HANGUL;

    return is_utf8_common(p, &PL_utf8_X_non_hangul, "HST=Not_Applicable");
}

bool
Perl_is_utf8_X_L(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_L;

    return is_utf8_common(p, &PL_utf8_X_L, "GCB=L");
}

bool
Perl_is_utf8_X_LV(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_LV;

    return is_utf8_common(p, &PL_utf8_X_LV, "GCB=LV");
}

bool
Perl_is_utf8_X_LVT(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_LVT;

    return is_utf8_common(p, &PL_utf8_X_LVT, "GCB=LVT");
}

bool
Perl_is_utf8_X_T(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_T;

    return is_utf8_common(p, &PL_utf8_X_T, "GCB=T");
}

bool
Perl_is_utf8_X_V(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_V;

    return is_utf8_common(p, &PL_utf8_X_V, "GCB=V");
}

bool
Perl_is_utf8_X_LV_LVT_V(pTHX_ const U8 *p)
{
    dVAR;

    PERL_ARGS_ASSERT_IS_UTF8_X_LV_LVT_V;

    return is_utf8_common(p, &PL_utf8_X_LV_LVT_V, "_X_LV_LVT_V");
}

/*
=for apidoc to_utf8_case

The "p" contains the pointer to the UTF-8 string encoding
the character that is being converted.

The "ustrp" is a pointer to the character buffer to put the
conversion result to.  The "lenp" is a pointer to the length
of the result.

The "swashp" is a pointer to the swash to use.

Both the special and normal mappings are stored in lib/unicore/To/Foo.pl,
and loaded by SWASHNEW, using lib/utf8_heavy.pl.  The special (usually,
but not always, a multicharacter mapping), is tried first.

The "special" is a string like "utf8::ToSpecLower", which means the
hash %utf8::ToSpecLower.  The access to the hash is through
Perl_to_utf8_case().

The "normal" is a string like "ToLower" which means the swash
%utf8::ToLower.

=cut */

UV
Perl_to_utf8_case(pTHX_ const U8 *p, U8* ustrp, STRLEN *lenp,
			SV **swashp, const char *normal, const char *special)
{
    dVAR;
    U8 tmpbuf[UTF8_MAXBYTES_CASE+1];
    STRLEN len = 0;
    const UV uv0 = utf8_to_uvchr(p, NULL);
    /* The NATIVE_TO_UNI() and UNI_TO_NATIVE() mappings
     * are necessary in EBCDIC, they are redundant no-ops
     * in ASCII-ish platforms, and hopefully optimized away. */
    const UV uv1 = NATIVE_TO_UNI(uv0);

    PERL_ARGS_ASSERT_TO_UTF8_CASE;

    /* Note that swash_fetch() doesn't output warnings for these because it
     * assumes we will */
    if (uv1 >= UNICODE_SURROGATE_FIRST) {
	if (uv1 <= UNICODE_SURROGATE_LAST) {
	    if (ckWARN_d(WARN_SURROGATE)) {
		const char* desc = (PL_op) ? OP_DESC(PL_op) : normal;
		Perl_warner(aTHX_ packWARN(WARN_SURROGATE),
		    "Operation \"%s\" returns its argument for UTF-16 surrogate U+%04"UVXf"", desc, uv1);
	    }
	}
	else if (UNICODE_IS_SUPER(uv1)) {
	    if (ckWARN_d(WARN_NON_UNICODE)) {
		const char* desc = (PL_op) ? OP_DESC(PL_op) : normal;
		Perl_warner(aTHX_ packWARN(WARN_NON_UNICODE),
		    "Operation \"%s\" returns its argument for non-Unicode code point 0x%04"UVXf"", desc, uv1);
	    }
	}

	/* Note that non-characters are perfectly legal, so no warning should
	 * be given */
    }

    uvuni_to_utf8(tmpbuf, uv1);

    if (!*swashp) /* load on-demand */
         *swashp = swash_init("utf8", normal, &PL_sv_undef, 4, 0);
    /* This is the beginnings of a skeleton of code to read the info section
     * that is in all the swashes in case we ever want to do that, so one can
     * read things whose maps aren't code points, and whose default if missing
     * is not to the code point itself.  This was just to see if it actually
     * worked.  Details on what the possibilities are are in perluniprops.pod
	HV * const hv = get_hv("utf8::SwashInfo", 0);
	if (hv) {
	 SV **svp;
	 svp = hv_fetch(hv, (const char*)normal, strlen(normal), FALSE);
	     const char *s;

	      HV * const this_hash = SvRV(*svp);
		svp = hv_fetch(this_hash, "type", strlen("type"), FALSE);
	      s = SvPV_const(*svp, len);
	}
    }*/

    if (special) {
         /* It might be "special" (sometimes, but not always,
	  * a multicharacter mapping) */
	 HV * const hv = get_hv(special, 0);
	 SV **svp;

	 if (hv &&
	     (svp = hv_fetch(hv, (const char*)tmpbuf, UNISKIP(uv1), FALSE)) &&
	     (*svp)) {
	     const char *s;

	      s = SvPV_const(*svp, len);
	      if (len == 1)
		   len = uvuni_to_utf8(ustrp, NATIVE_TO_UNI(*(U8*)s)) - ustrp;
	      else {
#ifdef EBCDIC
		   /* If we have EBCDIC we need to remap the characters
		    * since any characters in the low 256 are Unicode
		    * code points, not EBCDIC. */
		   U8 *t = (U8*)s, *tend = t + len, *d;
		
		   d = tmpbuf;
		   if (SvUTF8(*svp)) {
			STRLEN tlen = 0;
			
			while (t < tend) {
			     const UV c = utf8_to_uvchr(t, &tlen);
			     if (tlen > 0) {
				  d = uvchr_to_utf8(d, UNI_TO_NATIVE(c));
				  t += tlen;
			     }
			     else
				  break;
			}
		   }
		   else {
			while (t < tend) {
			     d = uvchr_to_utf8(d, UNI_TO_NATIVE(*t));
			     t++;
			}
		   }
		   len = d - tmpbuf;
		   Copy(tmpbuf, ustrp, len, U8);
#else
		   Copy(s, ustrp, len, U8);
#endif
	      }
	 }
    }

    if (!len && *swashp) {
	const UV uv2 = swash_fetch(*swashp, tmpbuf, TRUE);

	 if (uv2) {
	      /* It was "normal" (a single character mapping). */
	      const UV uv3 = UNI_TO_NATIVE(uv2);
	      len = uvchr_to_utf8(ustrp, uv3) - ustrp;
	 }
    }

    if (!len) /* Neither: just copy.  In other words, there was no mapping
		 defined, which means that the code point maps to itself */
	 len = uvchr_to_utf8(ustrp, uv0) - ustrp;

    if (lenp)
	 *lenp = len;

    return len ? utf8_to_uvchr(ustrp, 0) : 0;
}

/*
=for apidoc to_utf8_upper

Convert the UTF-8 encoded character at p to its uppercase version and
store that in UTF-8 in ustrp and its length in bytes in lenp.  Note
that the ustrp needs to be at least UTF8_MAXBYTES_CASE+1 bytes since
the uppercase version may be longer than the original character.

The first character of the uppercased version is returned
(but note, as explained above, that there may be more.)

=cut */

UV
Perl_to_utf8_upper(pTHX_ const U8 *p, U8* ustrp, STRLEN *lenp)
{
    dVAR;

    PERL_ARGS_ASSERT_TO_UTF8_UPPER;

    return Perl_to_utf8_case(aTHX_ p, ustrp, lenp,
                             &PL_utf8_toupper, "ToUpper", "utf8::ToSpecUpper");
}

/*
=for apidoc to_utf8_title

Convert the UTF-8 encoded character at p to its titlecase version and
store that in UTF-8 in ustrp and its length in bytes in lenp.  Note
that the ustrp needs to be at least UTF8_MAXBYTES_CASE+1 bytes since the
titlecase version may be longer than the original character.

The first character of the titlecased version is returned
(but note, as explained above, that there may be more.)

=cut */

UV
Perl_to_utf8_title(pTHX_ const U8 *p, U8* ustrp, STRLEN *lenp)
{
    dVAR;

    PERL_ARGS_ASSERT_TO_UTF8_TITLE;

    return Perl_to_utf8_case(aTHX_ p, ustrp, lenp,
                             &PL_utf8_totitle, "ToTitle", "utf8::ToSpecTitle");
}

/*
=for apidoc to_utf8_lower

Convert the UTF-8 encoded character at p to its lowercase version and
store that in UTF-8 in ustrp and its length in bytes in lenp.  Note
that the ustrp needs to be at least UTF8_MAXBYTES_CASE+1 bytes since the
lowercase version may be longer than the original character.

The first character of the lowercased version is returned
(but note, as explained above, that there may be more.)

=cut */

UV
Perl_to_utf8_lower(pTHX_ const U8 *p, U8* ustrp, STRLEN *lenp)
{
    dVAR;

    PERL_ARGS_ASSERT_TO_UTF8_LOWER;

    return Perl_to_utf8_case(aTHX_ p, ustrp, lenp,
                             &PL_utf8_tolower, "ToLower", "utf8::ToSpecLower");
}

/*
=for apidoc to_utf8_fold

Convert the UTF-8 encoded character at p to its foldcase version and
store that in UTF-8 in ustrp and its length in bytes in lenp.  Note
that the ustrp needs to be at least UTF8_MAXBYTES_CASE+1 bytes since the
foldcase version may be longer than the original character (up to
three characters).

The first character of the foldcased version is returned
(but note, as explained above, that there may be more.)

=cut */

/* Not currently externally documented is 'flags', which currently is non-zero
 * if full case folds are to be used; otherwise simple folds */

UV
Perl__to_utf8_fold_flags(pTHX_ const U8 *p, U8* ustrp, STRLEN *lenp, U8 flags)
{
    const char *specials = (flags) ? "utf8::ToSpecFold" : NULL;

    dVAR;

    PERL_ARGS_ASSERT__TO_UTF8_FOLD_FLAGS;

    return Perl_to_utf8_case(aTHX_ p, ustrp, lenp,
                             &PL_utf8_tofold, "ToFold", specials);
}

/* Note:
 * A "swash" is a swatch hash.
 * A "swatch" is a bit vector generated by utf8.c:S_swash_get().
 * C<pkg> is a pointer to a package name for SWASHNEW, should be "utf8".
 * For other parameters, see utf8::SWASHNEW in lib/utf8_heavy.pl.
 */
SV*
Perl_swash_init(pTHX_ const char* pkg, const char* name, SV *listsv, I32 minbits, I32 none)
{
    dVAR;
    SV* retval;
    dSP;
    const size_t pkg_len = strlen(pkg);
    const size_t name_len = strlen(name);
    HV * const stash = gv_stashpvn(pkg, pkg_len, 0);
    SV* errsv_save;
    GV *method;

    PERL_ARGS_ASSERT_SWASH_INIT;

    PUSHSTACKi(PERLSI_MAGIC);
    ENTER;
    SAVEHINTS();
    save_re_context();
    method = gv_fetchmeth(stash, "SWASHNEW", 8, -1);
    if (!method) {	/* demand load utf8 */
	ENTER;
	errsv_save = newSVsv(ERRSV);
	/* It is assumed that callers of this routine are not passing in any
	   user derived data.  */
	/* Need to do this after save_re_context() as it will set PL_tainted to
	   1 while saving $1 etc (see the code after getrx: in Perl_magic_get).
	   Even line to create errsv_save can turn on PL_tainted.  */
	SAVEBOOL(PL_tainted);
	PL_tainted = 0;
	Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvn(pkg,pkg_len),
			 NULL);
	if (!SvTRUE(ERRSV))
	    sv_setsv(ERRSV, errsv_save);
	SvREFCNT_dec(errsv_save);
	LEAVE;
    }
    SPAGAIN;
    PUSHMARK(SP);
    EXTEND(SP,5);
    mPUSHp(pkg, pkg_len);
    mPUSHp(name, name_len);
    PUSHs(listsv);
    mPUSHi(minbits);
    mPUSHi(none);
    PUTBACK;
    errsv_save = newSVsv(ERRSV);
    /* If we already have a pointer to the method, no need to use call_method()
       to repeat the lookup.  */
    if (method ? call_sv(MUTABLE_SV(method), G_SCALAR)
	: call_sv(newSVpvs_flags("SWASHNEW", SVs_TEMP), G_SCALAR | G_METHOD))
	retval = newSVsv(*PL_stack_sp--);
    else
	retval = &PL_sv_undef;
    if (!SvTRUE(ERRSV))
	sv_setsv(ERRSV, errsv_save);
    SvREFCNT_dec(errsv_save);
    LEAVE;
    POPSTACK;
    if (IN_PERL_COMPILETIME) {
	CopHINTS_set(PL_curcop, PL_hints);
    }
    if (!SvROK(retval) || SvTYPE(SvRV(retval)) != SVt_PVHV) {
        if (SvPOK(retval))
	    Perl_croak(aTHX_ "Can't find Unicode property definition \"%"SVf"\"",
		       SVfARG(retval));
	Perl_croak(aTHX_ "SWASHNEW didn't return an HV ref");
    }
    return retval;
}


/* This API is wrong for special case conversions since we may need to
 * return several Unicode characters for a single Unicode character
 * (see lib/unicore/SpecCase.txt) The SWASHGET in lib/utf8_heavy.pl is
 * the lower-level routine, and it is similarly broken for returning
 * multiple values.  --jhi
 * For those, you should use to_utf8_case() instead */
/* Now SWASHGET is recasted into S_swash_get in this file. */

/* Note:
 * Returns the value of property/mapping C<swash> for the first character
 * of the string C<ptr>. If C<do_utf8> is true, the string C<ptr> is
 * assumed to be in utf8. If C<do_utf8> is false, the string C<ptr> is
 * assumed to be in native 8-bit encoding. Caches the swatch in C<swash>.
 */
UV
Perl_swash_fetch(pTHX_ SV *swash, const U8 *ptr, bool do_utf8)
{
    dVAR;
    HV *const hv = MUTABLE_HV(SvRV(swash));
    U32 klen;
    U32 off;
    STRLEN slen;
    STRLEN needents;
    const U8 *tmps = NULL;
    U32 bit;
    SV *swatch;
    U8 tmputf8[2];
    const UV c = NATIVE_TO_ASCII(*ptr);

    PERL_ARGS_ASSERT_SWASH_FETCH;

    if (!do_utf8 && !UNI_IS_INVARIANT(c)) {
	tmputf8[0] = (U8)UTF8_EIGHT_BIT_HI(c);
	tmputf8[1] = (U8)UTF8_EIGHT_BIT_LO(c);
	ptr = tmputf8;
    }
    /* Given a UTF-X encoded char 0xAA..0xYY,0xZZ
     * then the "swatch" is a vec() for all the chars which start
     * with 0xAA..0xYY
     * So the key in the hash (klen) is length of encoded char -1
     */
    klen = UTF8SKIP(ptr) - 1;
    off  = ptr[klen];

    if (klen == 0) {
      /* If char is invariant then swatch is for all the invariant chars
       * In both UTF-8 and UTF-8-MOD that happens to be UTF_CONTINUATION_MARK
       */
	needents = UTF_CONTINUATION_MARK;
	off      = NATIVE_TO_UTF(ptr[klen]);
    }
    else {
      /* If char is encoded then swatch is for the prefix */
	needents = (1 << UTF_ACCUMULATION_SHIFT);
	off      = NATIVE_TO_UTF(ptr[klen]) & UTF_CONTINUATION_MASK;
	if (UTF8_IS_SUPER(ptr) && ckWARN_d(WARN_NON_UNICODE)) {
	    const UV code_point = utf8n_to_uvuni(ptr, UTF8_MAXBYTES, 0, 0);

	    /* This outputs warnings for binary properties only, assuming that
	     * to_utf8_case() will output any.  Also, surrogates aren't checked
	     * for, as that would warn on things like /\p{Gc=Cs}/ */
	    SV** const bitssvp = hv_fetchs(hv, "BITS", FALSE);
	    if (SvUV(*bitssvp) == 1) {
		Perl_warner(aTHX_ packWARN(WARN_NON_UNICODE),
		    "Code point 0x%04"UVXf" is not Unicode, no properties match it; all inverse properties do", code_point);
	    }
	}
    }

    /*
     * This single-entry cache saves about 1/3 of the utf8 overhead in test
     * suite.  (That is, only 7-8% overall over just a hash cache.  Still,
     * it's nothing to sniff at.)  Pity we usually come through at least
     * two function calls to get here...
     *
     * NB: this code assumes that swatches are never modified, once generated!
     */

    if (hv   == PL_last_swash_hv &&
	klen == PL_last_swash_klen &&
	(!klen || memEQ((char *)ptr, (char *)PL_last_swash_key, klen)) )
    {
	tmps = PL_last_swash_tmps;
	slen = PL_last_swash_slen;
    }
    else {
	/* Try our second-level swatch cache, kept in a hash. */
	SV** svp = hv_fetch(hv, (const char*)ptr, klen, FALSE);

	/* If not cached, generate it via swash_get */
	if (!svp || !SvPOK(*svp)
		 || !(tmps = (const U8*)SvPV_const(*svp, slen))) {
	    /* We use utf8n_to_uvuni() as we want an index into
	       Unicode tables, not a native character number.
	     */
	    const UV code_point = utf8n_to_uvuni(ptr, UTF8_MAXBYTES, 0,
					   ckWARN(WARN_UTF8) ?
					   0 : UTF8_ALLOW_ANY);
	    swatch = swash_get(swash,
		    /* On EBCDIC & ~(0xA0-1) isn't a useful thing to do */
				(klen) ? (code_point & ~(needents - 1)) : 0,
				needents);

	    if (IN_PERL_COMPILETIME)
		CopHINTS_set(PL_curcop, PL_hints);

	    svp = hv_store(hv, (const char *)ptr, klen, swatch, 0);

	    if (!svp || !(tmps = (U8*)SvPV(*svp, slen))
		     || (slen << 3) < needents)
		Perl_croak(aTHX_ "panic: swash_fetch got improper swatch");
	}

	PL_last_swash_hv = hv;
	assert(klen <= sizeof(PL_last_swash_key));
	PL_last_swash_klen = (U8)klen;
	/* FIXME change interpvar.h?  */
	PL_last_swash_tmps = (U8 *) tmps;
	PL_last_swash_slen = slen;
	if (klen)
	    Copy(ptr, PL_last_swash_key, klen, U8);
    }

    switch ((int)((slen << 3) / needents)) {
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
    Perl_croak(aTHX_ "panic: swash_fetch got swatch of unexpected bit width");
    NORETURN_FUNCTION_END;
}

/* Read a single line of the main body of the swash input text.  These are of
 * the form:
 * 0053	0056	0073
 * where each number is hex.  The first two numbers form the minimum and
 * maximum of a range, and the third is the value associated with the range.
 * Not all swashes should have a third number
 *
 * On input: l	  points to the beginning of the line to be examined; it points
 *		  to somewhere in the string of the whole input text, and is
 *		  terminated by a \n or the null string terminator.
 *	     lend   points to the null terminator of that string
 *	     wants_value    is non-zero if the swash expects a third number
 *	     typestr is the name of the swash's mapping, like 'ToLower'
 * On output: *min, *max, and *val are set to the values read from the line.
 *	      returns a pointer just beyond the line examined.  If there was no
 *	      valid min number on the line, returns lend+1
 */

STATIC U8*
S_swash_scan_list_line(pTHX_ U8* l, U8* const lend, UV* min, UV* max, UV* val,
			     const bool wants_value, const U8* const typestr)
{
    const int  typeto  = typestr[0] == 'T' && typestr[1] == 'o';
    STRLEN numlen;	    /* Length of the number */
    I32 flags = PERL_SCAN_SILENT_ILLDIGIT | PERL_SCAN_DISALLOW_PREFIX;

    /* nl points to the next \n in the scan */
    U8* const nl = (U8*)memchr(l, '\n', lend - l);

    /* Get the first number on the line: the range minimum */
    numlen = lend - l;
    *min = grok_hex((char *)l, &numlen, &flags, NULL);
    if (numlen)	    /* If found a hex number, position past it */
	l += numlen;
    else if (nl) {	    /* Else, go handle next line, if any */
	return nl + 1;	/* 1 is length of "\n" */
    }
    else {		/* Else, no next line */
	return lend + 1;	/* to LIST's end at which \n is not found */
    }

    /* The max range value follows, separated by a BLANK */
    if (isBLANK(*l)) {
	++l;
	flags = PERL_SCAN_SILENT_ILLDIGIT | PERL_SCAN_DISALLOW_PREFIX;
	numlen = lend - l;
	*max = grok_hex((char *)l, &numlen, &flags, NULL);
	if (numlen)
	    l += numlen;
	else    /* If no value here, it is a single element range */
	    *max = *min;

	/* Non-binary tables have a third entry: what the first element of the
	 * range maps to */
	if (wants_value) {
	    if (isBLANK(*l)) {
		++l;
		flags = PERL_SCAN_SILENT_ILLDIGIT |
			PERL_SCAN_DISALLOW_PREFIX;
		numlen = lend - l;
		*val = grok_hex((char *)l, &numlen, &flags, NULL);
		if (numlen)
		    l += numlen;
		else
		    *val = 0;
	    }
	    else {
		*val = 0;
		if (typeto) {
		    Perl_croak(aTHX_ "%s: illegal mapping '%s'",
				     typestr, l);
		}
	    }
	}
	else
	    *val = 0; /* bits == 1, then any val should be ignored */
    }
    else { /* Nothing following range min, should be single element with no
	      mapping expected */
	*max = *min;
	if (wants_value) {
	    *val = 0;
	    if (typeto) {
		Perl_croak(aTHX_ "%s: illegal mapping '%s'", typestr, l);
	    }
	}
	else
	    *val = 0; /* bits == 1, then val should be ignored */
    }

    /* Position to next line if any, or EOF */
    if (nl)
	l = nl + 1;
    else
	l = lend;

    return l;
}

/* Note:
 * Returns a swatch (a bit vector string) for a code point sequence
 * that starts from the value C<start> and comprises the number C<span>.
 * A C<swash> must be an object created by SWASHNEW (see lib/utf8_heavy.pl).
 * Should be used via swash_fetch, which will cache the swatch in C<swash>.
 */
STATIC SV*
S_swash_get(pTHX_ SV* swash, UV start, UV span)
{
    SV *swatch;
    U8 *l, *lend, *x, *xend, *s;
    STRLEN lcur, xcur, scur;
    HV *const hv = MUTABLE_HV(SvRV(swash));

    /* The string containing the main body of the table */
    SV** const listsvp = hv_fetchs(hv, "LIST", FALSE);

    SV** const typesvp = hv_fetchs(hv, "TYPE", FALSE);
    SV** const bitssvp = hv_fetchs(hv, "BITS", FALSE);
    SV** const nonesvp = hv_fetchs(hv, "NONE", FALSE);
    SV** const extssvp = hv_fetchs(hv, "EXTRAS", FALSE);
    const U8* const typestr = (U8*)SvPV_nolen(*typesvp);
    const STRLEN bits  = SvUV(*bitssvp);
    const STRLEN octets = bits >> 3; /* if bits == 1, then octets == 0 */
    const UV     none  = SvUV(*nonesvp);
    const UV     end   = start + span;

    PERL_ARGS_ASSERT_SWASH_GET;

    if (bits != 1 && bits != 8 && bits != 16 && bits != 32) {
	Perl_croak(aTHX_ "panic: swash_get doesn't expect bits %"UVuf,
						 (UV)bits);
    }

    /* create and initialize $swatch */
    scur   = octets ? (span * octets) : (span + 7) / 8;
    swatch = newSV(scur);
    SvPOK_on(swatch);
    s = (U8*)SvPVX(swatch);
    if (octets && none) {
	const U8* const e = s + scur;
	while (s < e) {
	    if (bits == 8)
		*s++ = (U8)(none & 0xff);
	    else if (bits == 16) {
		*s++ = (U8)((none >>  8) & 0xff);
		*s++ = (U8)( none        & 0xff);
	    }
	    else if (bits == 32) {
		*s++ = (U8)((none >> 24) & 0xff);
		*s++ = (U8)((none >> 16) & 0xff);
		*s++ = (U8)((none >>  8) & 0xff);
		*s++ = (U8)( none        & 0xff);
	    }
	}
	*s = '\0';
    }
    else {
	(void)memzero((U8*)s, scur + 1);
    }
    SvCUR_set(swatch, scur);
    s = (U8*)SvPVX(swatch);

    /* read $swash->{LIST} */
    l = (U8*)SvPV(*listsvp, lcur);
    lend = l + lcur;
    while (l < lend) {
	UV min, max, val;
	l = S_swash_scan_list_line(aTHX_ l, lend, &min, &max, &val,
					 cBOOL(octets), typestr);
	if (l > lend) {
	    break;
	}

	/* If looking for something beyond this range, go try the next one */
	if (max < start)
	    continue;

	if (octets) {
	    UV key;
	    if (min < start) {
		if (!none || val < none) {
		    val += start - min;
		}
		min = start;
	    }
	    for (key = min; key <= max; key++) {
		STRLEN offset;
		if (key >= end)
		    goto go_out_list;
		/* offset must be non-negative (start <= min <= key < end) */
		offset = octets * (key - start);
		if (bits == 8)
		    s[offset] = (U8)(val & 0xff);
		else if (bits == 16) {
		    s[offset    ] = (U8)((val >>  8) & 0xff);
		    s[offset + 1] = (U8)( val        & 0xff);
		}
		else if (bits == 32) {
		    s[offset    ] = (U8)((val >> 24) & 0xff);
		    s[offset + 1] = (U8)((val >> 16) & 0xff);
		    s[offset + 2] = (U8)((val >>  8) & 0xff);
		    s[offset + 3] = (U8)( val        & 0xff);
		}

		if (!none || val < none)
		    ++val;
	    }
	}
	else { /* bits == 1, then val should be ignored */
	    UV key;
	    if (min < start)
		min = start;
	    for (key = min; key <= max; key++) {
		const STRLEN offset = (STRLEN)(key - start);
		if (key >= end)
		    goto go_out_list;
		s[offset >> 3] |= 1 << (offset & 7);
	    }
	}
    } /* while */
  go_out_list:

    /* read $swash->{EXTRAS} */
    x = (U8*)SvPV(*extssvp, xcur);
    xend = x + xcur;
    while (x < xend) {
	STRLEN namelen;
	U8 *namestr;
	SV** othersvp;
	HV* otherhv;
	STRLEN otherbits;
	SV **otherbitssvp, *other;
	U8 *s, *o, *nl;
	STRLEN slen, olen;

	const U8 opc = *x++;
	if (opc == '\n')
	    continue;

	nl = (U8*)memchr(x, '\n', xend - x);

	if (opc != '-' && opc != '+' && opc != '!' && opc != '&') {
	    if (nl) {
		x = nl + 1; /* 1 is length of "\n" */
		continue;
	    }
	    else {
		x = xend; /* to EXTRAS' end at which \n is not found */
		break;
	    }
	}

	namestr = x;
	if (nl) {
	    namelen = nl - namestr;
	    x = nl + 1;
	}
	else {
	    namelen = xend - namestr;
	    x = xend;
	}

	othersvp = hv_fetch(hv, (char *)namestr, namelen, FALSE);
	otherhv = MUTABLE_HV(SvRV(*othersvp));
	otherbitssvp = hv_fetchs(otherhv, "BITS", FALSE);
	otherbits = (STRLEN)SvUV(*otherbitssvp);
	if (bits < otherbits)
	    Perl_croak(aTHX_ "panic: swash_get found swatch size mismatch");

	/* The "other" swatch must be destroyed after. */
	other = swash_get(*othersvp, start, span);
	o = (U8*)SvPV(other, olen);

	if (!olen)
	    Perl_croak(aTHX_ "panic: swash_get got improper swatch");

	s = (U8*)SvPV(swatch, slen);
	if (bits == 1 && otherbits == 1) {
	    if (slen != olen)
		Perl_croak(aTHX_ "panic: swash_get found swatch length mismatch");

	    switch (opc) {
	    case '+':
		while (slen--)
		    *s++ |= *o++;
		break;
	    case '!':
		while (slen--)
		    *s++ |= ~*o++;
		break;
	    case '-':
		while (slen--)
		    *s++ &= ~*o++;
		break;
	    case '&':
		while (slen--)
		    *s++ &= *o++;
		break;
	    default:
		break;
	    }
	}
	else {
	    STRLEN otheroctets = otherbits >> 3;
	    STRLEN offset = 0;
	    U8* const send = s + slen;

	    while (s < send) {
		UV otherval = 0;

		if (otherbits == 1) {
		    otherval = (o[offset >> 3] >> (offset & 7)) & 1;
		    ++offset;
		}
		else {
		    STRLEN vlen = otheroctets;
		    otherval = *o++;
		    while (--vlen) {
			otherval <<= 8;
			otherval |= *o++;
		    }
		}

		if (opc == '+' && otherval)
		    NOOP;   /* replace with otherval */
		else if (opc == '!' && !otherval)
		    otherval = 1;
		else if (opc == '-' && otherval)
		    otherval = 0;
		else if (opc == '&' && !otherval)
		    otherval = 0;
		else {
		    s += octets; /* no replacement */
		    continue;
		}

		if (bits == 8)
		    *s++ = (U8)( otherval & 0xff);
		else if (bits == 16) {
		    *s++ = (U8)((otherval >>  8) & 0xff);
		    *s++ = (U8)( otherval        & 0xff);
		}
		else if (bits == 32) {
		    *s++ = (U8)((otherval >> 24) & 0xff);
		    *s++ = (U8)((otherval >> 16) & 0xff);
		    *s++ = (U8)((otherval >>  8) & 0xff);
		    *s++ = (U8)( otherval        & 0xff);
		}
	    }
	}
	sv_free(other); /* through with it! */
    } /* while */
    return swatch;
}

HV*
Perl__swash_inversion_hash(pTHX_ SV* const swash)
{

   /* Subject to change or removal.  For use only in one place in regexec.c
    *
    * Returns a hash which is the inversion and closure of a swash mapping.
    * For example, consider the input lines:
    * 004B		006B
    * 004C		006C
    * 212A		006B
    *
    * The returned hash would have two keys, the utf8 for 006B and the utf8 for
    * 006C.  The value for each key is an array.  For 006C, the array would
    * have a two elements, the utf8 for itself, and for 004C.  For 006B, there
    * would be three elements in its array, the utf8 for 006B, 004B and 212A.
    *
    * Essentially, for any code point, it gives all the code points that map to
    * it, or the list of 'froms' for that point.
    *
    * Currently it only looks at the main body of the swash, and ignores any
    * additions or deletions from other swashes */

    U8 *l, *lend;
    STRLEN lcur;
    HV *const hv = MUTABLE_HV(SvRV(swash));

    /* The string containing the main body of the table */
    SV** const listsvp = hv_fetchs(hv, "LIST", FALSE);

    SV** const typesvp = hv_fetchs(hv, "TYPE", FALSE);
    SV** const bitssvp = hv_fetchs(hv, "BITS", FALSE);
    SV** const nonesvp = hv_fetchs(hv, "NONE", FALSE);
    /*SV** const extssvp = hv_fetchs(hv, "EXTRAS", FALSE);*/
    const U8* const typestr = (U8*)SvPV_nolen(*typesvp);
    const STRLEN bits  = SvUV(*bitssvp);
    const STRLEN octets = bits >> 3; /* if bits == 1, then octets == 0 */
    const UV     none  = SvUV(*nonesvp);

    HV* ret = newHV();

    PERL_ARGS_ASSERT__SWASH_INVERSION_HASH;

    /* Must have at least 8 bits to get the mappings */
    if (bits != 8 && bits != 16 && bits != 32) {
	Perl_croak(aTHX_ "panic: swash_inversion_hash doesn't expect bits %"UVuf,
						 (UV)bits);
    }

    /* read $swash->{LIST} */
    l = (U8*)SvPV(*listsvp, lcur);
    lend = l + lcur;

    /* Go through each input line */
    while (l < lend) {
	UV min, max, val;
	UV inverse;
	l = S_swash_scan_list_line(aTHX_ l, lend, &min, &max, &val,
					 cBOOL(octets), typestr);
	if (l > lend) {
	    break;
	}

	/* Each element in the range is to be inverted */
	for (inverse = min; inverse <= max; inverse++) {
	    AV* list;
	    SV* element;
	    SV** listp;
	    IV i;
	    bool found_key = FALSE;

	    /* The key is the inverse mapping */
	    char key[UTF8_MAXBYTES+1];
	    char* key_end = (char *) uvuni_to_utf8((U8*) key, val);
	    STRLEN key_len = key_end - key;

	    /* Get the list for the map */
	    if ((listp = hv_fetch(ret, key, key_len, FALSE))) {
		list = (AV*) *listp;
	    }
	    else { /* No entry yet for it: create one */
		list = newAV();
		if (! hv_store(ret, key, key_len, (SV*) list, FALSE)) {
		    Perl_croak(aTHX_ "panic: hv_store() unexpectedly failed");
		}
	    }

	    for (i = 0; i < av_len(list); i++) {
		SV** entryp = av_fetch(list, i, FALSE);
		SV* entry;
		if (entryp == NULL) {
		    Perl_croak(aTHX_ "panic: av_fetch() unexpectedly failed");
		}
		entry = *entryp;
		if (SvUV(entry) == val) {
		    found_key = TRUE;
		    break;
		}
	    }

	    /* Make sure there is a mapping to itself on the list */
	    if (! found_key) {
		element = newSVuv(val);
		av_push(list, element);
	    }


	    /* Simply add the value to the list */
	    element = newSVuv(inverse);
	    av_push(list, element);

	    /* swash_get() increments the value of val for each element in the
	     * range.  That makes more compact tables possible.  You can
	     * express the capitalization, for example, of all consecutive
	     * letters with a single line: 0061\t007A\t0041 This maps 0061 to
	     * 0041, 0062 to 0042, etc.  I (khw) have never understood 'none',
	     * and it's not documented, and perhaps not even currently used,
	     * but I copied the semantics from swash_get(), just in case */
	    if (!none || val < none) {
		++val;
	    }
	}
    }

    return ret;
}

HV*
Perl__swash_to_invlist(pTHX_ SV* const swash)
{

   /* Subject to change or removal.  For use only in one place in regcomp.c */

    U8 *l, *lend;
    char *loc;
    STRLEN lcur;
    HV *const hv = MUTABLE_HV(SvRV(swash));
    UV elements = 0;    /* Number of elements in the inversion list */
    U8 empty[] = "";

    /* The string containing the main body of the table */
    SV** const listsvp = hv_fetchs(hv, "LIST", FALSE);
    SV** const typesvp = hv_fetchs(hv, "TYPE", FALSE);
    SV** const bitssvp = hv_fetchs(hv, "BITS", FALSE);

    const U8* const typestr = (U8*)SvPV_nolen(*typesvp);
    const STRLEN bits  = SvUV(*bitssvp);
    const STRLEN octets = bits >> 3; /* if bits == 1, then octets == 0 */

    HV* invlist;

    PERL_ARGS_ASSERT__SWASH_TO_INVLIST;

    /* read $swash->{LIST} */
    if (SvPOK(*listsvp)) {
	l = (U8*)SvPV(*listsvp, lcur);
    }
    else {
	/* LIST legitimately doesn't contain a string during compilation phases
	 * of Perl itself, before the Unicode tables are generated.  In this
	 * case, just fake things up by creating an empty list */
	l = empty;
	lcur = 0;
    }
    loc = (char *) l;
    lend = l + lcur;

    /* Scan the input to count the number of lines to preallocate array size
     * based on worst possible case, which is each line in the input creates 2
     * elements in the inversion list: 1) the beginning of a range in the list;
     * 2) the beginning of a range not in the list.  */
    while ((loc = (strchr(loc, '\n'))) != NULL) {
	elements += 2;
	loc++;
    }

    /* If the ending is somehow corrupt and isn't a new line, add another
     * element for the final range that isn't in the inversion list */
    if (! (*lend == '\n' || (*lend == '\0' && *(lend - 1) == '\n'))) {
	elements++;
    }

    invlist = _new_invlist(elements);

    /* Now go through the input again, adding each range to the list */
    while (l < lend) {
	UV start, end;
	UV val;		/* Not used by this function */

	l = S_swash_scan_list_line(aTHX_ l, lend, &start, &end, &val,
					 cBOOL(octets), typestr);

	if (l > lend) {
	    break;
	}

	_append_range_to_invlist(invlist, start, end);
    }

    return invlist;
}

/*
=for apidoc uvchr_to_utf8

Adds the UTF-8 representation of the Native code point C<uv> to the end
of the string C<d>; C<d> should be have at least C<UTF8_MAXBYTES+1> free
bytes available. The return value is the pointer to the byte after the
end of the new character. In other words,

    d = uvchr_to_utf8(d, uv);

is the recommended wide native character-aware way of saying

    *(d++) = uv;

=cut
*/

/* On ASCII machines this is normally a macro but we want a
   real function in case XS code wants it
*/
U8 *
Perl_uvchr_to_utf8(pTHX_ U8 *d, UV uv)
{
    PERL_ARGS_ASSERT_UVCHR_TO_UTF8;

    return Perl_uvuni_to_utf8_flags(aTHX_ d, NATIVE_TO_UNI(uv), 0);
}

U8 *
Perl_uvchr_to_utf8_flags(pTHX_ U8 *d, UV uv, UV flags)
{
    PERL_ARGS_ASSERT_UVCHR_TO_UTF8_FLAGS;

    return Perl_uvuni_to_utf8_flags(aTHX_ d, NATIVE_TO_UNI(uv), flags);
}

/*
=for apidoc utf8n_to_uvchr

Returns the native character value of the first character in the string
C<s>
which is assumed to be in UTF-8 encoding; C<retlen> will be set to the
length, in bytes, of that character.

length and flags are the same as utf8n_to_uvuni().

=cut
*/
/* On ASCII machines this is normally a macro but we want
   a real function in case XS code wants it
*/
UV
Perl_utf8n_to_uvchr(pTHX_ const U8 *s, STRLEN curlen, STRLEN *retlen,
U32 flags)
{
    const UV uv = Perl_utf8n_to_uvuni(aTHX_ s, curlen, retlen, flags);

    PERL_ARGS_ASSERT_UTF8N_TO_UVCHR;

    return UNI_TO_NATIVE(uv);
}

bool
Perl_check_utf8_print(pTHX_ register const U8* s, const STRLEN len)
{
    /* May change: warns if surrogates, non-character code points, or
     * non-Unicode code points are in s which has length len.  Returns TRUE if
     * none found; FALSE otherwise.  The only other validity check is to make
     * sure that this won't exceed the string's length */

    const U8* const e = s + len;
    bool ok = TRUE;

    PERL_ARGS_ASSERT_CHECK_UTF8_PRINT;

    while (s < e) {
	if (UTF8SKIP(s) > len) {
	    Perl_ck_warner_d(aTHX_ packWARN(WARN_UTF8),
			   "%s in %s", unees, PL_op ? OP_DESC(PL_op) : "print");
	    return FALSE;
	}
	if (*s >= UTF8_FIRST_PROBLEMATIC_CODE_POINT_FIRST_BYTE) {
	    STRLEN char_len;
	    if (UTF8_IS_SUPER(s)) {
		if (ckWARN_d(WARN_NON_UNICODE)) {
		    UV uv = utf8_to_uvchr(s, &char_len);
		    Perl_warner(aTHX_ packWARN(WARN_NON_UNICODE),
			"Code point 0x%04"UVXf" is not Unicode, may not be portable", uv);
		    ok = FALSE;
		}
	    }
	    else if (UTF8_IS_SURROGATE(s)) {
		if (ckWARN_d(WARN_SURROGATE)) {
		    UV uv = utf8_to_uvchr(s, &char_len);
		    Perl_warner(aTHX_ packWARN(WARN_SURROGATE),
			"Unicode surrogate U+%04"UVXf" is illegal in UTF-8", uv);
		    ok = FALSE;
		}
	    }
	    else if
		((UTF8_IS_NONCHAR_GIVEN_THAT_NON_SUPER_AND_GE_PROBLEMATIC(s))
		 && (ckWARN_d(WARN_NONCHAR)))
	    {
		UV uv = utf8_to_uvchr(s, &char_len);
		Perl_warner(aTHX_ packWARN(WARN_NONCHAR),
		    "Unicode non-character U+%04"UVXf" is illegal for open interchange", uv);
		ok = FALSE;
	    }
	}
	s += UTF8SKIP(s);
    }

    return ok;
}

/*
=for apidoc pv_uni_display

Build to the scalar dsv a displayable version of the string spv,
length len, the displayable version being at most pvlim bytes long
(if longer, the rest is truncated and "..." will be appended).

The flags argument can have UNI_DISPLAY_ISPRINT set to display
isPRINT()able characters as themselves, UNI_DISPLAY_BACKSLASH
to display the \\[nrfta\\] as the backslashed versions (like '\n')
(UNI_DISPLAY_BACKSLASH is preferred over UNI_DISPLAY_ISPRINT for \\).
UNI_DISPLAY_QQ (and its alias UNI_DISPLAY_REGEX) have both
UNI_DISPLAY_BACKSLASH and UNI_DISPLAY_ISPRINT turned on.

The pointer to the PV of the dsv is returned.

=cut */
char *
Perl_pv_uni_display(pTHX_ SV *dsv, const U8 *spv, STRLEN len, STRLEN pvlim, UV flags)
{
    int truncated = 0;
    const char *s, *e;

    PERL_ARGS_ASSERT_PV_UNI_DISPLAY;

    sv_setpvs(dsv, "");
    SvUTF8_off(dsv);
    for (s = (const char *)spv, e = s + len; s < e; s += UTF8SKIP(s)) {
	 UV u;
	  /* This serves double duty as a flag and a character to print after
	     a \ when flags & UNI_DISPLAY_BACKSLASH is true.
	  */
	 char ok = 0;

	 if (pvlim && SvCUR(dsv) >= pvlim) {
	      truncated++;
	      break;
	 }
	 u = utf8_to_uvchr((U8*)s, 0);
	 if (u < 256) {
	     const unsigned char c = (unsigned char)u & 0xFF;
	     if (flags & UNI_DISPLAY_BACKSLASH) {
	         switch (c) {
		 case '\n':
		     ok = 'n'; break;
		 case '\r':
		     ok = 'r'; break;
		 case '\t':
		     ok = 't'; break;
		 case '\f':
		     ok = 'f'; break;
		 case '\a':
		     ok = 'a'; break;
		 case '\\':
		     ok = '\\'; break;
		 default: break;
		 }
		 if (ok) {
		     const char string = ok;
		     sv_catpvs(dsv, "\\");
		     sv_catpvn(dsv, &string, 1);
		 }
	     }
	     /* isPRINT() is the locale-blind version. */
	     if (!ok && (flags & UNI_DISPLAY_ISPRINT) && isPRINT(c)) {
		 const char string = c;
		 sv_catpvn(dsv, &string, 1);
		 ok = 1;
	     }
	 }
	 if (!ok)
	     Perl_sv_catpvf(aTHX_ dsv, "\\x{%"UVxf"}", u);
    }
    if (truncated)
	 sv_catpvs(dsv, "...");

    return SvPVX(dsv);
}

/*
=for apidoc sv_uni_display

Build to the scalar dsv a displayable version of the scalar sv,
the displayable version being at most pvlim bytes long
(if longer, the rest is truncated and "..." will be appended).

The flags argument is as in pv_uni_display().

The pointer to the PV of the dsv is returned.

=cut
*/
char *
Perl_sv_uni_display(pTHX_ SV *dsv, SV *ssv, STRLEN pvlim, UV flags)
{
    PERL_ARGS_ASSERT_SV_UNI_DISPLAY;

     return Perl_pv_uni_display(aTHX_ dsv, (const U8*)SvPVX_const(ssv),
				SvCUR(ssv), pvlim, flags);
}

/*
=for apidoc foldEQ_utf8

Returns true if the leading portions of the strings s1 and s2 (either or both
of which may be in UTF-8) are the same case-insensitively; false otherwise.
How far into the strings to compare is determined by other input parameters.

If u1 is true, the string s1 is assumed to be in UTF-8-encoded Unicode;
otherwise it is assumed to be in native 8-bit encoding.  Correspondingly for u2
with respect to s2.

If the byte length l1 is non-zero, it says how far into s1 to check for fold
equality.  In other words, s1+l1 will be used as a goal to reach.  The
scan will not be considered to be a match unless the goal is reached, and
scanning won't continue past that goal.  Correspondingly for l2 with respect to
s2.

If pe1 is non-NULL and the pointer it points to is not NULL, that pointer is
considered an end pointer beyond which scanning of s1 will not continue under
any circumstances.  This means that if both l1 and pe1 are specified, and pe1
is less than s1+l1, the match will never be successful because it can never
get as far as its goal (and in fact is asserted against).  Correspondingly for
pe2 with respect to s2.

At least one of s1 and s2 must have a goal (at least one of l1 and l2 must be
non-zero), and if both do, both have to be
reached for a successful match.   Also, if the fold of a character is multiple
characters, all of them must be matched (see tr21 reference below for
'folding').

Upon a successful match, if pe1 is non-NULL,
it will be set to point to the beginning of the I<next> character of s1 beyond
what was matched.  Correspondingly for pe2 and s2.

For case-insensitiveness, the "casefolding" of Unicode is used
instead of upper/lowercasing both the characters, see
http://www.unicode.org/unicode/reports/tr21/ (Case Mappings).

=cut */

/* A flags parameter has been added which may change, and hence isn't
 * externally documented.  Currently it is:
 *  0 for as-documented above
 *  FOLDEQ_UTF8_NOMIX_ASCII meaning that if a non-ASCII character folds to an
			    ASCII one, to not match
 *  FOLDEQ_UTF8_LOCALE	    meaning that locale rules are to be used for code
 *			    points below 256; unicode rules for above 255; and
 *			    folds that cross those boundaries are disallowed,
 *			    like the NOMIX_ASCII option
 */
I32
Perl_foldEQ_utf8_flags(pTHX_ const char *s1, char **pe1, register UV l1, bool u1, const char *s2, char **pe2, register UV l2, bool u2, U32 flags)
{
    dVAR;
    register const U8 *p1  = (const U8*)s1; /* Point to current char */
    register const U8 *p2  = (const U8*)s2;
    register const U8 *g1 = NULL;       /* goal for s1 */
    register const U8 *g2 = NULL;
    register const U8 *e1 = NULL;       /* Don't scan s1 past this */
    register U8 *f1 = NULL;             /* Point to current folded */
    register const U8 *e2 = NULL;
    register U8 *f2 = NULL;
    STRLEN n1 = 0, n2 = 0;              /* Number of bytes in current char */
    U8 foldbuf1[UTF8_MAXBYTES_CASE+1];
    U8 foldbuf2[UTF8_MAXBYTES_CASE+1];
    U8 natbuf[2];               /* Holds native 8-bit char converted to utf8;
                                   these always fit in 2 bytes */

    PERL_ARGS_ASSERT_FOLDEQ_UTF8_FLAGS;

    if (pe1) {
        e1 = *(U8**)pe1;
    }

    if (l1) {
        g1 = (const U8*)s1 + l1;
    }

    if (pe2) {
        e2 = *(U8**)pe2;
    }

    if (l2) {
        g2 = (const U8*)s2 + l2;
    }

    /* Must have at least one goal */
    assert(g1 || g2);

    if (g1) {

        /* Will never match if goal is out-of-bounds */
        assert(! e1  || e1 >= g1);

        /* Here, there isn't an end pointer, or it is beyond the goal.  We
        * only go as far as the goal */
        e1 = g1;
    }
    else {
	assert(e1);    /* Must have an end for looking at s1 */
    }

    /* Same for goal for s2 */
    if (g2) {
        assert(! e2  || e2 >= g2);
        e2 = g2;
    }
    else {
	assert(e2);
    }

    /* Look through both strings, a character at a time */
    while (p1 < e1 && p2 < e2) {

        /* If at the beginning of a new character in s1, get its fold to use
	 * and the length of the fold.  (exception: locale rules just get the
	 * character to a single byte) */
        if (n1 == 0) {

	    /* If in locale matching, we use two sets of rules, depending on if
	     * the code point is above or below 255.  Here, we test for and
	     * handle locale rules */
	    if ((flags & FOLDEQ_UTF8_LOCALE)
		&& (! u1 || UTF8_IS_INVARIANT(*p1) || UTF8_IS_DOWNGRADEABLE_START(*p1)))
	    {
		/* There is no mixing of code points above and below 255. */
		if (u2 && (! UTF8_IS_INVARIANT(*p2)
		    && ! UTF8_IS_DOWNGRADEABLE_START(*p2)))
		{
		    return 0;
		}

		/* We handle locale rules by converting, if necessary, the code
		 * point to a single byte. */
		if (! u1 || UTF8_IS_INVARIANT(*p1)) {
		    *foldbuf1 = *p1;
		}
		else {
		    *foldbuf1 = TWO_BYTE_UTF8_TO_UNI(*p1, *(p1 + 1));
		}
		n1 = 1;
	    }
	    else if (isASCII(*p1)) {	/* Note, that here won't be both ASCII
					   and using locale rules */

		/* If trying to mix non- with ASCII, and not supposed to, fail */
		if ((flags & FOLDEQ_UTF8_NOMIX_ASCII) && ! isASCII(*p2)) {
		    return 0;
		}
		n1 = 1;
		*foldbuf1 = toLOWER(*p1);   /* Folds in the ASCII range are
					       just lowercased */
	    }
	    else if (u1) {
                to_utf8_fold(p1, foldbuf1, &n1);
            }
            else {  /* Not utf8, convert to it first and then get fold */
                uvuni_to_utf8(natbuf, (UV) NATIVE_TO_UNI(((UV)*p1)));
                to_utf8_fold(natbuf, foldbuf1, &n1);
            }
            f1 = foldbuf1;
        }

        if (n2 == 0) {    /* Same for s2 */
	    if ((flags & FOLDEQ_UTF8_LOCALE)
		&& (! u2 || UTF8_IS_INVARIANT(*p2) || UTF8_IS_DOWNGRADEABLE_START(*p2)))
	    {
		/* Here, the next char in s2 is < 256.  We've already worked on
		 * s1, and if it isn't also < 256, can't match */
		if (u1 && (! UTF8_IS_INVARIANT(*p1)
		    && ! UTF8_IS_DOWNGRADEABLE_START(*p1)))
		{
		    return 0;
		}
		if (! u2 || UTF8_IS_INVARIANT(*p2)) {
		    *foldbuf2 = *p2;
		}
		else {
		    *foldbuf2 = TWO_BYTE_UTF8_TO_UNI(*p2, *(p2 + 1));
		}

		/* Use another function to handle locale rules.  We've made
		 * sure that both characters to compare are single bytes */
		if (! foldEQ_locale((char *) f1, (char *) foldbuf2, 1)) {
		    return 0;
		}
		n1 = n2 = 0;
	    }
	    else if (isASCII(*p2)) {
		if (flags && ! isASCII(*p1)) {
		    return 0;
		}
		n2 = 1;
		*foldbuf2 = toLOWER(*p2);
	    }
	    else if (u2) {
                to_utf8_fold(p2, foldbuf2, &n2);
            }
            else {
                uvuni_to_utf8(natbuf, (UV) NATIVE_TO_UNI(((UV)*p2)));
                to_utf8_fold(natbuf, foldbuf2, &n2);
            }
            f2 = foldbuf2;
        }

	/* Here f1 and f2 point to the beginning of the strings to compare.
	 * These strings are the folds of the input characters, stored in utf8.
	 */

        /* While there is more to look for in both folds, see if they
        * continue to match */
        while (n1 && n2) {
            U8 fold_length = UTF8SKIP(f1);
            if (fold_length != UTF8SKIP(f2)
                || (fold_length == 1 && *f1 != *f2) /* Short circuit memNE
                                                       function call for single
                                                       character */
                || memNE((char*)f1, (char*)f2, fold_length))
            {
                return 0; /* mismatch */
            }

            /* Here, they matched, advance past them */
            n1 -= fold_length;
            f1 += fold_length;
            n2 -= fold_length;
            f2 += fold_length;
        }

        /* When reach the end of any fold, advance the input past it */
        if (n1 == 0) {
            p1 += u1 ? UTF8SKIP(p1) : 1;
        }
        if (n2 == 0) {
            p2 += u2 ? UTF8SKIP(p2) : 1;
        }
    } /* End of loop through both strings */

    /* A match is defined by each scan that specified an explicit length
    * reaching its final goal, and the other not having matched a partial
    * character (which can happen when the fold of a character is more than one
    * character). */
    if (! ((g1 == 0 || p1 == g1) && (g2 == 0 || p2 == g2)) || n1 || n2) {
        return 0;
    }

    /* Successful match.  Set output pointers */
    if (pe1) {
        *pe1 = (char*)p1;
    }
    if (pe2) {
        *pe2 = (char*)p2;
    }
    return 1;
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
