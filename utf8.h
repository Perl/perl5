/*    utf8.h
 *
 *    Copyright (c) 1998-2001, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifdef EBCDIC
/* The equivalent of these macros but implementing UTF-EBCDIC
   are in the following header file:
 */

#include "utfebcdic.h"
#else
START_EXTERN_C

#ifdef DOINIT
EXTCONST unsigned char PL_utf8skip[] = {
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* ascii */
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* ascii */
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* ascii */
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* ascii */
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* bogus */
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* bogus */
2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, /* scripts */
3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,6,6,	 /* cjk etc. */
7,13, /* Perl extended (not UTF-8).  Up to 72bit allowed (64-bit + reserved). */
};
#else
EXTCONST unsigned char PL_utf8skip[];
#endif

END_EXTERN_C
#define UTF8SKIP(s) PL_utf8skip[*(U8*)s]

/* Native character to iso-8859-1 */
#define NATIVE_TO_ASCII(ch)      (ch)
#define ASCII_TO_NATIVE(ch)      (ch)
/* Transform after encoding */
#define NATIVE_TO_UTF(ch)        (ch)
#define UTF_TO_NATIVE(ch)        (ch)
/* Transforms in wide UV chars */
#define UNI_TO_NATIVE(ch)        (ch)
#define NATIVE_TO_UNI(ch)        (ch)
/* Transforms in invariant space */
#define NATIVE_TO_NEED(enc,ch)   (ch)
#define ASCII_TO_NEED(enc,ch)    (ch)

/* As there are no translations avoid the function wrapper */
#define Perl_utf8n_to_uvchr Perl_utf8n_to_uvuni
#define Perl_uvchr_to_utf8  Perl_uvuni_to_utf8

/*

 The following table is from Unicode 3.1.

 Code Points		1st Byte  2nd Byte  3rd Byte  4th Byte

   U+0000..U+007F	00..7F   
   U+0080..U+07FF	C2..DF    80..BF   
   U+0800..U+0FFF	E0        A0..BF    80..BF  
   U+1000..U+FFFF	E1..EF    80..BF    80..BF  
  U+10000..U+3FFFF	F0        90..BF    80..BF    80..BF
  U+40000..U+FFFFF	F1..F3    80..BF    80..BF    80..BF
 U+100000..U+10FFFF	F4        80..8F    80..BF    80..BF

 */

#define UNI_IS_INVARIANT(c)		(((UV)c) <  0x80)
#define UTF8_IS_INVARIANT(c)		UNI_IS_INVARIANT(NATIVE_TO_UTF(c))
#define NATIVE_IS_INVARIANT(c)		UNI_IS_INVARIANT(NATIVE_TO_ASCII(c))
#define UTF8_IS_START(c)		(((U8)c) >= 0xc0 && (((U8)c) <= 0xfd))
#define UTF8_IS_CONTINUATION(c)		(((U8)c) >= 0x80 && (((U8)c) <= 0xbf))
#define UTF8_IS_CONTINUED(c) 		(((U8)c) &  0x80)
#define UTF8_IS_DOWNGRADEABLE_START(c)	(((U8)c & 0xfc) == 0xc0)

#define UTF_START_MARK(len) ((len >  7) ? 0xFF : (0xFE << (7-len)))
#define UTF_START_MASK(len) ((len >= 7) ? 0x00 : (0x1F >> (len-2)))

#define UTF_CONTINUATION_MARK		0x80
#define UTF_ACCUMULATION_SHIFT		6
#define UTF_CONTINUATION_MASK		((U8)0x3f)
#define UTF8_ACCUMULATE(old, new)	(((old) << UTF_ACCUMULATION_SHIFT) | (((U8)new) & UTF_CONTINUATION_MASK))

#define UTF8_EIGHT_BIT_HI(c)	((((U8)(c))>>UTF_ACCUMULATION_SHIFT)|UTF_START_MARK(2))
#define UTF8_EIGHT_BIT_LO(c)	(((((U8)(c)))&UTF_CONTINUATION_MASK)|UTF_CONTINUATION_MARK)

#ifdef HAS_QUAD
#define UNISKIP(uv) ( (uv) < 0x80           ? 1 : \
		      (uv) < 0x800          ? 2 : \
		      (uv) < 0x10000        ? 3 : \
		      (uv) < 0x200000       ? 4 : \
		      (uv) < 0x4000000      ? 5 : \
		      (uv) < 0x80000000     ? 6 : \
                      (uv) < UTF8_QUAD_MAX ? 7 : 13 )
#else
/* No, I'm not even going to *TRY* putting #ifdef inside a #define */
#define UNISKIP(uv) ( (uv) < 0x80           ? 1 : \
		      (uv) < 0x800          ? 2 : \
		      (uv) < 0x10000        ? 3 : \
		      (uv) < 0x200000       ? 4 : \
		      (uv) < 0x4000000      ? 5 : \
		      (uv) < 0x80000000     ? 6 : 7 )
#endif

/*
 * Note: we try to be careful never to call the isXXX_utf8() functions
 * unless we're pretty sure we've seen the beginning of a UTF-8 character
 * (that is, the two high bits are set).  Otherwise we risk loading in the
 * heavy-duty SWASHINIT and SWASHGET routines unnecessarily.
 */
#define isIDFIRST_lazy_if(p,c) ((IN_BYTES || (!c || (*((U8*)p) < 0xc0))) \
				? isIDFIRST(*(p)) \
				: isIDFIRST_utf8((U8*)p))
#define isALNUM_lazy_if(p,c)   ((IN_BYTES || (!c || (*((U8*)p) < 0xc0))) \
				? isALNUM(*(p)) \
				: isALNUM_utf8((U8*)p))


#endif /* EBCDIC vs ASCII */

/* Rest of these are attributes of Unicode and perl's internals rather than the encoding */

#define isIDFIRST_lazy(p)	isIDFIRST_lazy_if(p,1)
#define isALNUM_lazy(p)		isALNUM_lazy_if(p,1)

#define UTF8_MAXLEN 13 /* how wide can a single UTF8 encoded character become */

#define IN_BYTES (PL_curcop->op_private & HINT_BYTES)
#define DO_UTF8(sv) (SvUTF8(sv) && !IN_BYTES)

#define UTF8_ALLOW_EMPTY		0x0001
#define UTF8_ALLOW_CONTINUATION		0x0002
#define UTF8_ALLOW_NON_CONTINUATION	0x0004
#define UTF8_ALLOW_FE_FF		0x0008
#define UTF8_ALLOW_SHORT		0x0010
#define UTF8_ALLOW_SURROGATE		0x0020
#define UTF8_ALLOW_BOM			0x0040
#define UTF8_ALLOW_FFFF			0x0080
#define UTF8_ALLOW_LONG			0x0100
#define UTF8_ALLOW_ANYUV		(UTF8_ALLOW_EMPTY|UTF8_ALLOW_FE_FF|\
					 UTF8_ALLOW_SURROGATE|UTF8_ALLOW_BOM|\
					 UTF8_ALLOW_FFFF|UTF8_ALLOW_LONG)
#define UTF8_ALLOW_ANY			0x00ff
#define UTF8_CHECK_ONLY			0x0100

#define UNICODE_SURROGATE_FIRST		0xd800
#define UNICODE_SURROGATE_LAST		0xdfff
#define UNICODE_REPLACEMENT		0xfffd
#define UNICODE_BYTER_ORDER_MARK	0xfffe
#define UNICODE_ILLEGAL			0xffff

#define UNICODE_IS_SURROGATE(c)		((c) >= UNICODE_SURROGATE_FIRST && \
					 (c) <= UNICODE_SURROGATE_LAST)
#define UNICODE_IS_REPLACEMENT(c)	((c) == UNICODE_REPLACEMENT)
#define UNICODE_IS_BYTE_ORDER_MARK(c)	((c) == UNICODE_BYTER_ORDER_MARK)
#define UNICODE_IS_ILLEGAL(c)		((c) == UNICODE_ILLEGAL)

#ifdef HAS_QUAD
#    define UTF8_QUAD_MAX	UINT64_C(0x1000000000)
#endif

#define UTF8_IS_ASCII(c) UTF8_IS_INVARIANT(c)
