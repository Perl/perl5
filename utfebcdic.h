/*    utfebcdic.h
 *
 *    Copyright (C) 2001, 2002, 2003, 2005, 2006, 2007, 2009,
 *    2010, 2011 by Larry Wall, Nick Ing-Simmons, and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * Macros to implement UTF-EBCDIC as perl's internal encoding
 * Adapted from version 7.1 of Unicode Technical Report #16:
 *  http://www.unicode.org/unicode/reports/tr16
 *
 * To summarize, the way it works is:
 * To convert an EBCDIC character to UTF-EBCDIC:
 *  1)	convert to Unicode.  The table in the generated file 'ebcdic_tables.h'
 *      that does this for EBCDIC bytes is PL_e2a (with inverse PL_a2e).  The
 *      'a' stands for ASCII platform, meaning latin1.
 *  2)	convert that to a utf8-like string called I8 ('I' stands for
 *	intermediate) with variant characters occupying multiple bytes.  This
 *	step is similar to the utf8-creating step from Unicode, but the details
 *	are different.  This transformation is called UTF8-Mod.  There is a
 *	chart about the bit patterns in a comment later in this file.  But
 *	essentially here are the differences:
 *			    UTF8		I8
 *	invariant byte	    starts with 0	starts with 0 or 100
 *	continuation byte   starts with 10	starts with 101
 *	start byte	    same in both: if the code point requires N bytes,
 *			    then the leading N bits are 1, followed by a 0.  (No
 *			    trailing 0 for the very largest possible allocation
 *			    in I8, far beyond the current Unicode standard's
 *			    max, as shown in the comment later in this file.)
 *  3)	Use the algorithm in tr16 to convert each byte from step 2 into
 *	final UTF-EBCDIC.  This is done by table lookup from a table
 *	constructed from the algorithm, reproduced in ebcdic_tables.h as
 *	PL_utf2e, with its inverse being PL_e2utf.  They are constructed so that
 *	all EBCDIC invariants remain invariant, but no others do, and the first
 *	byte of a variant will always have its upper bit set.  But note that
 *	the upper bit of some invariants is also 1.
 *
 *  For example, the ordinal value of 'A' is 193 in EBCDIC, and also is 193 in
 *  UTF-EBCDIC.  Step 1) converts it to 65, Step 2 leaves it at 65, and Step 3
 *  converts it back to 193.  As an example of how a variant character works,
 *  take LATIN SMALL LETTER Y WITH DIAERESIS, which is typically 0xDF in
 *  EBCDIC.  Step 1 converts it to the Unicode value, 0xFF.  Step 2 converts
 *  that to two bytes = 11000111 10111111 = C7 BF, and Step 3 converts those to
 *  0x8B 0x73.
 *
 * If you're starting from Unicode, skip step 1.  For UTF-EBCDIC to straight
 * EBCDIC, reverse the steps.
 *
 * The EBCDIC invariants have been chosen to be those characters whose Unicode
 * equivalents have ordinal numbers less than 160, that is the same characters
 * that are expressible in ASCII, plus the C1 controls.  So there are 160
 * invariants instead of the 128 in UTF-8.
 *
 * The purpose of Step 3 is to make the encoding be invariant for the chosen
 * characters.  This messes up the convenient patterns found in step 2, so
 * generally, one has to undo step 3 into a temporary to use them.  However,
 * one "shadow", or parallel table, PL_utf8skip, has been constructed that
 * doesn't require undoing things.  It is such that for each byte, it says
 * how long the sequence is if that (UTF-EBCDIC) byte were to begin it
 *
 * There are actually 3 slightly different UTF-EBCDIC encodings in
 * ebcdic_tables.h, one for each of the code pages recognized by Perl.  That
 * means that there are actually three different sets of tables, one for each
 * code page.  (If Perl is compiled on platforms using another EBCDIC code
 * page, it may not compile, or Perl may silently mistake it for one of the
 * three.)
 *
 * Note that tr16 actually only specifies one version of UTF-EBCDIC, based on
 * the 1047 encoding, and which is supposed to be used for all code pages.
 * But this doesn't work.  To illustrate the problem, consider the '^' character.
 * On a 037 code page it is the single byte 176, whereas under 1047 UTF-EBCDIC
 * it is the single byte 95.  If Perl implemented tr16 exactly, it would mean
 * that changing a string containing '^' to UTF-EBCDIC would change that '^'
 * from 176 to 95 (and vice-versa), violating the rule that ASCII-range
 * characters are the same in UTF-8 or not.  Much code in Perl assumes this
 * rule.  See for example
 * http://grokbase.com/t/perl/mvs/025xf0yhmn/utf-ebcdic-for-posix-bc-malformed-utf-8-character
 * What Perl does is create a version of UTF-EBCDIC suited to each code page;
 * the one for the 1047 code page is identical to what's specified in tr16.
 * This complicates interchanging files between computers using different code
 * pages.  Best is to convert to I8 before sending them, as the I8
 * representation is the same no matter what the underlying code page is.
 *
 * Because of the way UTF-EBCDIC is constructed, the lowest 32 code points that
 * aren't equivalent to ASCII characters nor C1 controls form the set of
 * continuation bytes; the remaining 64 non-ASCII, non-control code points form
 * the potential start bytes, in order.  (However, the first 5 of these lead to
 * malformed overlongs, so there really are only 59 start bytes.) Hence the
 * UTF-EBCDIC for the smallest variant code point, 0x160, will have likely 0x41
 * as its continuation byte, provided 0x41 isn't an ASCII or C1 equivalent.
 * And its start byte will be the code point that is 37 (32+5) non-ASCII,
 * non-control code points past it.  (0 - 3F are controls, and 40 is SPACE,
 * leaving 41 as the first potentially available one.)  In contrast, on ASCII
 * platforms, the first 64 (not 32) non-ASCII code points are the continuation
 * bytes.  And the first 2 (not 5) potential start bytes form overlong
 * malformed sequences.
 *
 * EBCDIC characters above 0xFF are the same as Unicode in Perl's
 * implementation of all 3 encodings, so for those Step 1 is trivial.
 *
 * (Note that the entries for invariant characters are necessarily the same in
 * PL_e2a and PL_e2utf; likewise for their inverses.)
 *
 * UTF-EBCDIC strings are the same length or longer than UTF-8 representations
 * of the same string.  The maximum code point representable as 2 bytes in
 * UTF-EBCDIC is 0x3FFF, instead of 0x7FFF in UTF-8.
 */

START_EXTERN_C

#ifdef DOINIT

#include "ebcdic_tables.h"

#else
EXTCONST U8 PL_utf8skip[];
EXTCONST U8 PL_e2utf[];
EXTCONST U8 PL_utf2e[];
EXTCONST U8 PL_e2a[];
EXTCONST U8 PL_a2e[];
EXTCONST U8 PL_fold[];
EXTCONST U8 PL_fold_latin1[];
EXTCONST U8 PL_latin1_lc[];
EXTCONST U8 PL_mod_latin1_uc[];
#endif

END_EXTERN_C

/* EBCDIC-happy ways of converting native code to UTF-8 */

#define NATIVE_TO_LATIN1(ch)            PL_e2a[(U8)(ch)]
#define LATIN1_TO_NATIVE(ch)            PL_a2e[(U8)(ch)]

#define NATIVE_UTF8_TO_I8(ch)           PL_e2utf[(U8)(ch)]
#define I8_TO_NATIVE_UTF8(ch)           PL_utf2e[(U8)(ch)]

/* Transforms in wide UV chars */
#define NATIVE_TO_UNI(ch)        (((ch) > 255) ? (ch) : NATIVE_TO_LATIN1(ch))
#define UNI_TO_NATIVE(ch)        (((ch) > 255) ? (ch) : LATIN1_TO_NATIVE(ch))

/*
  The following table is adapted from tr16, it shows I8 encoding of Unicode code points.

        Unicode                             Bit pattern 1st Byte 2nd Byte 3rd Byte 4th Byte 5th Byte 6th Byte 7th byte
    U+0000..U+007F                     000000000xxxxxxx 0xxxxxxx
    U+0080..U+009F                     00000000100xxxxx 100xxxxx
    U+00A0..U+03FF                     000000yyyyyxxxxx 110yyyyy 101xxxxx
    U+0400..U+3FFF                     00zzzzyyyyyxxxxx 1110zzzz 101yyyyy 101xxxxx
    U+4000..U+3FFFF                 0wwwzzzzzyyyyyxxxxx 11110www 101zzzzz 101yyyyy 101xxxxx
   U+40000..U+3FFFFF            0vvwwwwwzzzzzyyyyyxxxxx 111110vv 101wwwww 101zzzzz 101yyyyy 101xxxxx
  U+400000..U+3FFFFFF       0uvvvvvwwwwwzzzzzyyyyyxxxxx 1111110u 101vvvvv 101wwwww 101zzzzz 101yyyyy 101xxxxx
 U+4000000..U+7FFFFFFF 0tuuuuuvvvvvwwwwwzzzzzyyyyyxxxxx 1111111t 101uuuuu 101vvvvv 101wwwww 101zzzzz 101yyyyy 101xxxxx

  Note: The I8 transformation is valid for UCS-4 values X'0' to
  X'7FFFFFFF' (the full extent of ISO/IEC 10646 coding space).

 */

/* Input is a true Unicode (not-native) code point */
#define OFFUNISKIP(uv) ( (uv) < 0xA0        ? 1 : \
		      (uv) < 0x400          ? 2 : \
		      (uv) < 0x4000         ? 3 : \
		      (uv) < 0x40000        ? 4 : \
		      (uv) < 0x400000       ? 5 : \
		      (uv) < 0x4000000      ? 6 : 7 )

#define UNI_IS_INVARIANT(c)		(((UV)(c)) <  0xA0)

/* UTF-EBCDIC semantic macros - transform back into I8 and then compare
 * Comments as to the meaning of each are given at their corresponding utf8.h
 * definitions */

#define UTF8_IS_START(c)		(NATIVE_UTF8_TO_I8(c) >= 0xC5     \
                                         && NATIVE_UTF8_TO_I8(c) != 0xE0)
#define UTF8_IS_CONTINUATION(c)		((NATIVE_UTF8_TO_I8(c) & 0xE0) == 0xA0)
#define UTF8_IS_CONTINUED(c) 		(NATIVE_UTF8_TO_I8(c) >= 0xA0)

#define UTF8_IS_DOWNGRADEABLE_START(c)	(NATIVE_UTF8_TO_I8(c) >= 0xC5     \
                                         && NATIVE_UTF8_TO_I8(c) <= 0xC7)
/* Saying it this way adds a runtime test, but removes 2 run-time lookups */
/*#define UTF8_IS_DOWNGRADEABLE_START(c)  ((c) == I8_TO_NATIVE_UTF8(0xC5)     \
                                         || (c) == I8_TO_NATIVE_UTF8(0xC6)  \
                                         || (c) == I8_TO_NATIVE_UTF8(0xC7))
*/
#define UTF8_IS_ABOVE_LATIN1(c)	(NATIVE_UTF8_TO_I8(c) >= 0xC8)

/* Can't exceed 7 on EBCDIC platforms */
#define UTF_START_MARK(len) (0xFF & (0xFE << (7-(len))))

#define UTF_START_MASK(len) (((len) >= 6) ? 0x01 : (0x1F >> ((len)-2)))
#define UTF_CONTINUATION_MARK		0xA0
#define UTF_CONTINUATION_MASK		((U8)0x1f)
#define UTF_ACCUMULATION_SHIFT		5

/* How wide can a single UTF-8 encoded character become in bytes. */
/* NOTE: Strictly speaking Perl's UTF-8 should not be called UTF-8 since UTF-8
 * is an encoding of Unicode, and Unicode's upper limit, 0x10FFFF, can be
 * expressed with 5 bytes.  However, Perl thinks of UTF-8 as a way to encode
 * non-negative integers in a binary format, even those above Unicode */
#define UTF8_MAXBYTES 7

/* The maximum number of UTF-8 bytes a single Unicode character can
 * uppercase/lowercase/fold into.  Unicode guarantees that the maximum
 * expansion is 3 characters.  On EBCDIC platforms, the highest Unicode
 * character occupies 5 bytes, therefore this number is 15 */
#define UTF8_MAXBYTES_CASE	15

/* ^? is defined to be APC on EBCDIC systems.  See the definition of toCTRL()
 * for more */
#define QUESTION_MARK_CTRL   LATIN1_TO_NATIVE(0x9F)

#define MAX_UTF8_TWO_BYTE 0x3FF

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
