/*    mathoms.c
 *
 *    Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010,
 *    2011, 2012 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *  Anything that Hobbits had no immediate use for, but were unwilling to
 *  throw away, they called a mathom.  Their dwellings were apt to become
 *  rather crowded with mathoms, and many of the presents that passed from
 *  hand to hand were of that sort.
 *
 *     [p.5 of _The Lord of the Rings_: "Prologue"]
 */



/*
 * This file contains mathoms, various binary artifacts from previous
 * versions of Perl which we cannot completely remove from the core
 * code. There is only one reason these days for functions should be here:
 *
 * 1) A function has been replaced by a macro within a minor release,
 *    so XS modules compiled against an older release will expect to
 *    still be able to link against the function
 *
 * It used to be that this was the way to handle the case were a function
 * Perl_foo(...) had been replaced by a macro.  But see the 'm' flag discussion
 * in embed.fnc for a better way to handle this.
 *
 * This file can't just be cleaned out periodically, because that would break
 * builds with -DPERL_NO_SHORT_NAMES
 *
 * NOTE: ALL FUNCTIONS IN THIS FILE should have an entry with the 'b' flag in
 * embed.fnc.
 *
 * To move a function to this file, simply cut and paste it here, and change
 * its embed.fnc entry to additionally have the 'b' flag.  If, for some reason
 * a function you'd like to be treated as mathoms can't be moved from its
 * current place, simply enclose it between
 *
 * #ifndef NO_MATHOMS
 *    ...
 * #endif
 *
 * and add the 'b' flag in embed.fnc.
 *
 * The compilation of this file and the functions within it can be suppressed
 * by adding this option to Configure:
 *
 *      -Accflags='-DNO_MATHOMS'
 *
 * Some of the functions here are also deprecated.
 *
 */


#include "EXTERN.h"
#define PERL_IN_MATHOMS_C
#include "perl.h"

#ifdef NO_MATHOMS
/* ..." warning: ISO C forbids an empty source file"
   So make sure we have something in here by processing the headers anyway.
 */
#else

/* The functions in this file should be able to call other deprecated functions
 * without a compiler warning */
GCC_DIAG_IGNORE(-Wdeprecated-declarations)

#if defined(HUGE_VAL) || (defined(USE_LONG_DOUBLE) && defined(HUGE_VALL))
/*
 * This hack is to force load of "huge" support from libm.a
 * So it is in perl for (say) POSIX to use.
 * Needed for SunOS with Sun's 'acc' for example.
 */
NV
Perl_huge(void)
{
#  if defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)
    return HUGE_VALL;
#  else
    return HUGE_VAL;
#  endif
}
#endif

/*
=for apidoc_section $SV
=for apidoc sv_nolocking

Dummy routine which "locks" an SV when there is no locking module present.
Exists to avoid test for a C<NULL> function pointer and because it could
potentially warn under some level of strict-ness.

"Superseded" by C<sv_nosharing()>.

=cut
*/

void
Perl_sv_nolocking(pTHX_ SV *sv)
{
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(sv);
}


/*
=for apidoc_section $SV
=for apidoc sv_nounlocking

Dummy routine which "unlocks" an SV when there is no locking module present.
Exists to avoid test for a C<NULL> function pointer and because it could
potentially warn under some level of strict-ness.

"Superseded" by C<sv_nosharing()>.

=cut

PERL_UNLOCK_HOOK in intrpvar.h is the macro that refers to this, and guarantees
that mathoms gets loaded.

*/

void
Perl_sv_nounlocking(pTHX_ SV *sv)
{
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(sv);
}

I32
Perl_my_stat(pTHX)
{
    return my_stat_flags(SV_GMAGIC);
}

I32
Perl_my_lstat(pTHX)
{
    return my_lstat_flags(SV_GMAGIC);
}

CV *
Perl_newSUB(pTHX_ I32 floor, OP *o, OP *proto, OP *block)
{
    return newATTRSUB(floor, o, proto, NULL, block);
}


STRLEN
Perl_is_utf8_char_buf(const U8 *buf, const U8* buf_end)
{

    PERL_ARGS_ASSERT_IS_UTF8_CHAR_BUF;

    return isUTF8_CHAR(buf, buf_end);
}
/*
=for apidoc_section $unicode
=for apidoc utf8_to_uvuni

Returns the Unicode code point of the first character in the string C<s>
which is assumed to be in UTF-8 encoding; C<retlen> will be set to the
length, in bytes, of that character.

Some, but not all, UTF-8 malformations are detected, and in fact, some
malformed input could cause reading beyond the end of the input buffer, which
is one reason why this function is deprecated.  The other is that only in
extremely limited circumstances should the Unicode versus native code point be
of any interest to you.

If C<s> points to one of the detected malformations, and UTF8 warnings are
enabled, zero is returned and C<*retlen> is set (if C<retlen> doesn't point to
NULL) to -1.  If those warnings are off, the computed value if well-defined (or
the Unicode REPLACEMENT CHARACTER, if not) is silently returned, and C<*retlen>
is set (if C<retlen> isn't NULL) so that (S<C<s> + C<*retlen>>) is the
next possible position in C<s> that could begin a non-malformed character.
See L<perlapi/utf8n_to_uvchr> for details on when the REPLACEMENT CHARACTER is returned.

=cut
*/

UV
Perl_utf8_to_uvuni(pTHX_ const U8 *s, STRLEN *retlen)
{
    PERL_UNUSED_CONTEXT;
    PERL_ARGS_ASSERT_UTF8_TO_UVUNI;

    return NATIVE_TO_UNI(valid_utf8_to_uvchr(s, retlen));
}

U8 *
Perl_uvuni_to_utf8(pTHX_ U8 *d, UV uv)
{
    PERL_ARGS_ASSERT_UVUNI_TO_UTF8;

    return uvoffuni_to_utf8_flags(d, uv, 0);
}

/*
=for apidoc_section $unicode
=for apidoc utf8n_to_uvuni

Instead use L<perlapi/utf8_to_uvchr_buf>, or rarely, L<perlapi/utf8n_to_uvchr>.

This function was useful for code that wanted to handle both EBCDIC and
ASCII platforms with Unicode properties, but starting in Perl v5.20, the
distinctions between the platforms have mostly been made invisible to most
code, so this function is quite unlikely to be what you want.  If you do need
this precise functionality, use instead
C<L<NATIVE_TO_UNI(utf8_to_uvchr_buf(...))|perlapi/utf8_to_uvchr_buf>>
or C<L<NATIVE_TO_UNI(utf8n_to_uvchr(...))|perlapi/utf8n_to_uvchr>>.

=cut
*/

UV
Perl_utf8n_to_uvuni(pTHX_ const U8 *s, STRLEN curlen, STRLEN *retlen, U32 flags)
{
    PERL_ARGS_ASSERT_UTF8N_TO_UVUNI;

    return NATIVE_TO_UNI(utf8n_to_uvchr(s, curlen, retlen, flags));
}

/*
=for apidoc_section $unicode
=for apidoc utf8_to_uvchr

Returns the native code point of the first character in the string C<s>
which is assumed to be in UTF-8 encoding; C<retlen> will be set to the
length, in bytes, of that character.

Some, but not all, UTF-8 malformations are detected, and in fact, some
malformed input could cause reading beyond the end of the input buffer, which
is why this function is deprecated.  Use L</utf8_to_uvchr_buf> instead.

If C<s> points to one of the detected malformations, and UTF8 warnings are
enabled, zero is returned and C<*retlen> is set (if C<retlen> isn't
C<NULL>) to -1.  If those warnings are off, the computed value if well-defined (or
the Unicode REPLACEMENT CHARACTER, if not) is silently returned, and C<*retlen>
is set (if C<retlen> isn't NULL) so that (S<C<s> + C<*retlen>>) is the
next possible position in C<s> that could begin a non-malformed character.
See L</utf8n_to_uvchr> for details on when the REPLACEMENT CHARACTER is returned.

=cut
*/

UV
Perl_utf8_to_uvchr(pTHX_ const U8 *s, STRLEN *retlen)
{
    PERL_ARGS_ASSERT_UTF8_TO_UVCHR;

    /* This function is unsafe if malformed UTF-8 input is given it, which is
     * why the function is deprecated.  If the first byte of the input
     * indicates that there are more bytes remaining in the sequence that forms
     * the character than there are in the input buffer, it can read past the
     * end.  But we can make it safe if the input string happens to be
     * NUL-terminated, as many strings in Perl are, by refusing to read past a
     * NUL, which is what UTF8_CHK_SKIP() does.  A NUL indicates the start of
     * the next character anyway.  If the input isn't NUL-terminated, the
     * function remains unsafe, as it always has been. */

    return utf8_to_uvchr_buf(s, s + UTF8_CHK_SKIP(s), retlen);
}

GCC_DIAG_RESTORE

#endif /* NO_MATHOMS */

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
