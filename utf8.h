/*    utf8.h
 *
 *    Copyright (c) 1998-2000, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

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

#define UTF8_MAXLEN 13 /* how wide can a single UTF8 encoded character become */

#define IN_UTF8 (PL_curcop->op_private & HINT_UTF8)
#define IN_BYTE (PL_curcop->op_private & HINT_BYTE)
#define DO_UTF8(sv) (SvUTF8(sv) && !IN_BYTE)

#define UTF8SKIP(s) PL_utf8skip[*(U8*)s]

#ifdef HAS_QUAD
#define UNISKIP(uv) ( (uv) < 0x80           ? 1 : \
		      (uv) < 0x800          ? 2 : \
		      (uv) < 0x10000        ? 3 : \
		      (uv) < 0x200000       ? 4 : \
		      (uv) < 0x4000000      ? 5 : \
		      (uv) < 0x80000000     ? 6 : \
                      (uv) < 0x1000000000LL ? 7 : 13 ) 
#else
/* No, I'm not even going to *TRY* putting #ifdef inside a #define */
#define UNISKIP(uv) ( (uv) < 0x80           ? 1 : \
		      (uv) < 0x800          ? 2 : \
		      (uv) < 0x10000        ? 3 : \
		      (uv) < 0x200000       ? 4 : \
		      (uv) < 0x4000000      ? 5 : \
		      (uv) < 0x80000000     ? 6 : 7 )
#endif

#define UNICODE_REPLACEMENT_CHARACTER	0xfffd

/*
 * Note: we try to be careful never to call the isXXX_utf8() functions
 * unless we're pretty sure we've seen the beginning of a UTF-8 character
 * (that is, the two high bits are set).  Otherwise we risk loading in the
 * heavy-duty SWASHINIT and SWASHGET routines unnecessarily.
 */
#ifdef EBCDIC
#define isIDFIRST_lazy_if(p,c) isIDFIRST(*(p))
#define isALNUM_lazy_if(p,c)   isALNUM(*(p))
#else
#define isIDFIRST_lazy_if(p,c) ((IN_BYTE || (!c || (*((U8*)p) < 0xc0))) \
				? isIDFIRST(*(p)) \
				: isIDFIRST_utf8((U8*)p))
#define isALNUM_lazy_if(p,c)   ((IN_BYTE || (!c || (*((U8*)p) < 0xc0))) \
				? isALNUM(*(p)) \
				: isALNUM_utf8((U8*)p))
#endif
#define isIDFIRST_lazy(p)	isIDFIRST_lazy_if(p,1)
#define isALNUM_lazy(p)		isALNUM_lazy_if(p,1)
