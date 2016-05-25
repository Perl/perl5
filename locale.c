/*    locale.c
 *
 *    Copyright (C) 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001,
 *    2002, 2003, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *      A Elbereth Gilthoniel,
 *      silivren penna míriel
 *      o menel aglar elenath!
 *      Na-chaered palan-díriel
 *      o galadhremmin ennorath,
 *      Fanuilos, le linnathon
 *      nef aear, si nef aearon!
 *
 *     [p.238 of _The Lord of the Rings_, II/i: "Many Meetings"]
 */

/* utility functions for handling locale-specific stuff like what
 * character represents the decimal point.
 *
 * All C programs have an underlying locale.  Perl generally doesn't pay any
 * attention to it except within the scope of a 'use locale'.  For most
 * categories, it accomplishes this by just using different operations if it is
 * in such scope than if not.  However, various libc functions called by Perl
 * are affected by the LC_NUMERIC category, so there are macros in perl.h that
 * are used to toggle between the current locale and the C locale depending on
 * the desired behavior of those functions at the moment.  And, LC_MESSAGES is
 * switched to the C locale for outputting the message unless within the scope
 * of 'use locale'.
 */

#include "EXTERN.h"
#define PERL_IN_LOCALE_C
#include "perl.h"

#ifdef I_LANGINFO
#   include <langinfo.h>
#endif

#include "reentr.h"

/* If the environment says to, we can output debugging information during
 * initialization.  This is done before option parsing, and before any thread
 * creation, so can be a file-level static */
#ifdef DEBUGGING
# ifdef PERL_GLOBAL_STRUCT
  /* no global syms allowed */
#  define debug_initialization 0
#  define DEBUG_INITIALIZATION_set(v)
# else
static bool debug_initialization = FALSE;
#  define DEBUG_INITIALIZATION_set(v) (debug_initialization = v)
# endif
#endif

#ifdef USE_LOCALE

/*
 * Standardize the locale name from a string returned by 'setlocale', possibly
 * modifying that string.
 *
 * The typical return value of setlocale() is either
 * (1) "xx_YY" if the first argument of setlocale() is not LC_ALL
 * (2) "xa_YY xb_YY ..." if the first argument of setlocale() is LC_ALL
 *     (the space-separated values represent the various sublocales,
 *      in some unspecified order).  This is not handled by this function.
 *
 * In some platforms it has a form like "LC_SOMETHING=Lang_Country.866\n",
 * which is harmful for further use of the string in setlocale().  This
 * function removes the trailing new line and everything up through the '='
 *
 */
STATIC char *
S_stdize_locale(pTHX_ char *locs)
{
    const char * const s = strchr(locs, '=');
    bool okay = TRUE;

    PERL_ARGS_ASSERT_STDIZE_LOCALE;

    if (s) {
	const char * const t = strchr(s, '.');
	okay = FALSE;
	if (t) {
	    const char * const u = strchr(t, '\n');
	    if (u && (u[1] == 0)) {
		const STRLEN len = u - s;
		Move(s + 1, locs, len, char);
		locs[len] = 0;
		okay = TRUE;
	    }
	}
    }

    if (!okay)
	Perl_croak(aTHX_ "Can't fix broken locale name \"%s\"", locs);

    return locs;
}

#endif

void
Perl_set_numeric_radix(pTHX)
{
#ifdef USE_LOCALE_NUMERIC
# ifdef HAS_LOCALECONV
    const struct lconv* const lc = localeconv();

    if (lc && lc->decimal_point) {
	if (lc->decimal_point[0] == '.' && lc->decimal_point[1] == 0) {
	    SvREFCNT_dec(PL_numeric_radix_sv);
	    PL_numeric_radix_sv = NULL;
	}
	else {
	    if (PL_numeric_radix_sv)
		sv_setpv(PL_numeric_radix_sv, lc->decimal_point);
	    else
		PL_numeric_radix_sv = newSVpv(lc->decimal_point, 0);
            if (! is_invariant_string((U8 *) lc->decimal_point, 0)
                && is_utf8_string((U8 *) lc->decimal_point, 0)
                && _is_cur_LC_category_utf8(LC_NUMERIC))
            {
		SvUTF8_on(PL_numeric_radix_sv);
            }
	}
    }
    else
	PL_numeric_radix_sv = NULL;

#ifdef DEBUGGING
    if (DEBUG_L_TEST || debug_initialization) {
        PerlIO_printf(Perl_debug_log, "Locale radix is '%s', ?UTF-8=%d\n",
                                          (PL_numeric_radix_sv)
                                           ? SvPVX(PL_numeric_radix_sv)
                                           : "NULL",
                                          (PL_numeric_radix_sv)
                                           ? cBOOL(SvUTF8(PL_numeric_radix_sv))
                                           : 0);
    }
#endif

# endif /* HAS_LOCALECONV */
#endif /* USE_LOCALE_NUMERIC */
}

/* Is the C string input 'name' "C" or "POSIX"?  If so, and 'name' is the
 * return of setlocale(), then this is extremely likely to be the C or POSIX
 * locale.  However, the output of setlocale() is documented to be opaque, but
 * the odds are extremely small that it would return these two strings for some
 * other locale.  Note that VMS in these two locales includes many non-ASCII
 * characters as controls and punctuation (below are hex bytes):
 *   cntrl:  00-1F 7F 84-97 9B-9F
 *   punct:  21-2F 3A-40 5B-60 7B-7E A1-A3 A5 A7-AB B0-B3 B5-B7 B9-BD BF-CF D1-DD DF-EF F1-FD
 * Oddly, none there are listed as alphas, though some represent alphabetics
 * http://www.nntp.perl.org/group/perl.perl5.porters/2013/02/msg198753.html */
#define isNAME_C_OR_POSIX(name) ((name) != NULL                                 \
                                  && ((*(name) == 'C' && (*(name + 1)) == '\0') \
                                       || strEQ((name), "POSIX")))

void
Perl_new_numeric(pTHX_ const char *newnum)
{
#ifdef USE_LOCALE_NUMERIC

    /* Called after all libc setlocale() calls affecting LC_NUMERIC, to tell
     * core Perl this and that 'newnum' is the name of the new locale.
     * It installs this locale as the current underlying default.
     *
     * The default locale and the C locale can be toggled between by use of the
     * set_numeric_local() and set_numeric_standard() functions, which should
     * probably not be called directly, but only via macros like
     * SET_NUMERIC_STANDARD() in perl.h.
     *
     * The toggling is necessary mainly so that a non-dot radix decimal point
     * character can be output, while allowing internal calculations to use a
     * dot.
     *
     * This sets several interpreter-level variables:
     * PL_numeric_name  The underlying locale's name: a copy of 'newnum'
     * PL_numeric_local A boolean indicating if the toggled state is such
     *                  that the current locale is the program's underlying
     *                  locale
     * PL_numeric_standard An int indicating if the toggled state is such
     *                  that the current locale is the C locale.  If non-zero,
     *                  it is in C; if > 1, it means it may not be toggled away
     *                  from C.
     * Note that both of the last two variables can be true at the same time,
     * if the underlying locale is C.  (Toggling is a no-op under these
     * circumstances.)
     *
     * Any code changing the locale (outside this file) should use
     * POSIX::setlocale, which calls this function.  Therefore this function
     * should be called directly only from this file and from
     * POSIX::setlocale() */

    char *save_newnum;

    if (! newnum) {
	Safefree(PL_numeric_name);
	PL_numeric_name = NULL;
	PL_numeric_standard = TRUE;
	PL_numeric_local = TRUE;
	return;
    }

    save_newnum = stdize_locale(savepv(newnum));

    PL_numeric_standard = isNAME_C_OR_POSIX(save_newnum);
    PL_numeric_local = TRUE;

    if (! PL_numeric_name || strNE(PL_numeric_name, save_newnum)) {
	Safefree(PL_numeric_name);
	PL_numeric_name = save_newnum;
    }
    else {
	Safefree(save_newnum);
    }

    /* Keep LC_NUMERIC in the C locale.  This is for XS modules, so they don't
     * have to worry about the radix being a non-dot.  (Core operations that
     * need the underlying locale change to it temporarily). */
    set_numeric_standard();

    set_numeric_radix();

#else
    PERL_UNUSED_ARG(newnum);
#endif /* USE_LOCALE_NUMERIC */
}

void
Perl_set_numeric_standard(pTHX)
{
#ifdef USE_LOCALE_NUMERIC
    /* Toggle the LC_NUMERIC locale to C.  Most code should use the macros like
     * SET_NUMERIC_STANDARD() in perl.h instead of calling this directly.  The
     * macro avoids calling this routine if toggling isn't necessary according
     * to our records (which could be wrong if some XS code has changed the
     * locale behind our back) */

    setlocale(LC_NUMERIC, "C");
    PL_numeric_standard = TRUE;
    PL_numeric_local = isNAME_C_OR_POSIX(PL_numeric_name);
    set_numeric_radix();
#ifdef DEBUGGING
    if (DEBUG_L_TEST || debug_initialization) {
        PerlIO_printf(Perl_debug_log,
                          "Underlying LC_NUMERIC locale now is C\n");
    }
#endif

#endif /* USE_LOCALE_NUMERIC */
}

void
Perl_set_numeric_local(pTHX)
{
#ifdef USE_LOCALE_NUMERIC
    /* Toggle the LC_NUMERIC locale to the current underlying default.  Most
     * code should use the macros like SET_NUMERIC_LOCAL() in perl.h instead of
     * calling this directly.  The macro avoids calling this routine if
     * toggling isn't necessary according to our records (which could be wrong
     * if some XS code has changed the locale behind our back) */

    setlocale(LC_NUMERIC, PL_numeric_name);
    PL_numeric_standard = isNAME_C_OR_POSIX(PL_numeric_name);
    PL_numeric_local = TRUE;
    set_numeric_radix();
#ifdef DEBUGGING
    if (DEBUG_L_TEST || debug_initialization) {
        PerlIO_printf(Perl_debug_log,
                          "Underlying LC_NUMERIC locale now is %s\n",
                          PL_numeric_name);
    }
#endif

#endif /* USE_LOCALE_NUMERIC */
}

/*
 * Set up for a new ctype locale.
 */
void
Perl_new_ctype(pTHX_ const char *newctype)
{
#ifdef USE_LOCALE_CTYPE

    /* Called after all libc setlocale() calls affecting LC_CTYPE, to tell
     * core Perl this and that 'newctype' is the name of the new locale.
     *
     * This function sets up the folding arrays for all 256 bytes, assuming
     * that tofold() is tolc() since fold case is not a concept in POSIX,
     *
     * Any code changing the locale (outside this file) should use
     * POSIX::setlocale, which calls this function.  Therefore this function
     * should be called directly only from this file and from
     * POSIX::setlocale() */

    dVAR;
    UV i;

    PERL_ARGS_ASSERT_NEW_CTYPE;

    /* We will replace any bad locale warning with 1) nothing if the new one is
     * ok; or 2) a new warning for the bad new locale */
    if (PL_warn_locale) {
        SvREFCNT_dec_NN(PL_warn_locale);
        PL_warn_locale = NULL;
    }

    PL_in_utf8_CTYPE_locale = _is_cur_LC_category_utf8(LC_CTYPE);

    /* A UTF-8 locale gets standard rules.  But note that code still has to
     * handle this specially because of the three problematic code points */
    if (PL_in_utf8_CTYPE_locale) {
        Copy(PL_fold_latin1, PL_fold_locale, 256, U8);
    }
    else {
        /* Assume enough space for every character being bad.  4 spaces each
         * for the 94 printable characters that are output like "'x' "; and 5
         * spaces each for "'\\' ", "'\t' ", and "'\n' "; plus a terminating
         * NUL */
        char bad_chars_list[ (94 * 4) + (3 * 5) + 1 ];

        bool check_for_problems = ckWARN_d(WARN_LOCALE); /* No warnings means
                                                            no check */
        bool multi_byte_locale = FALSE;     /* Assume is a single-byte locale
                                               to start */
        unsigned int bad_count = 0;         /* Count of bad characters */

        for (i = 0; i < 256; i++) {
            if (isUPPER_LC((U8) i))
                PL_fold_locale[i] = (U8) toLOWER_LC((U8) i);
            else if (isLOWER_LC((U8) i))
                PL_fold_locale[i] = (U8) toUPPER_LC((U8) i);
            else
                PL_fold_locale[i] = (U8) i;

            /* If checking for locale problems, see if the native ASCII-range
             * printables plus \n and \t are in their expected categories in
             * the new locale.  If not, this could mean big trouble, upending
             * Perl's and most programs' assumptions, like having a
             * metacharacter with special meaning become a \w.  Fortunately,
             * it's very rare to find locales that aren't supersets of ASCII
             * nowadays.  It isn't a problem for most controls to be changed
             * into something else; we check only \n and \t, though perhaps \r
             * could be an issue as well. */
            if (check_for_problems
                && (isGRAPH_A(i) || isBLANK_A(i) || i == '\n'))
            {
                if ((isALPHANUMERIC_A(i) && ! isALPHANUMERIC_LC(i))
                     || (isPUNCT_A(i) && ! isPUNCT_LC(i))
                     || (isBLANK_A(i) && ! isBLANK_LC(i))
                     || (i == '\n' && ! isCNTRL_LC(i)))
                {
                    if (bad_count) {    /* Separate multiple entries with a
                                           blank */
                        bad_chars_list[bad_count++] = ' ';
                    }
                    bad_chars_list[bad_count++] = '\'';
                    if (isPRINT_A(i)) {
                        bad_chars_list[bad_count++] = (char) i;
                    }
                    else {
                        bad_chars_list[bad_count++] = '\\';
                        if (i == '\n') {
                            bad_chars_list[bad_count++] = 'n';
                        }
                        else {
                            assert(i == '\t');
                            bad_chars_list[bad_count++] = 't';
                        }
                    }
                    bad_chars_list[bad_count++] = '\'';
                    bad_chars_list[bad_count] = '\0';
                }
            }
        }

#ifdef MB_CUR_MAX
        /* We only handle single-byte locales (outside of UTF-8 ones; so if
         * this locale requires more than one byte, there are going to be
         * problems. */
        if (check_for_problems && MB_CUR_MAX > 1

               /* Some platforms return MB_CUR_MAX > 1 for even the "C"
                * locale.  Just assume that the implementation for them (plus
                * for POSIX) is correct and the > 1 value is spurious.  (Since
                * these are specially handled to never be considered UTF-8
                * locales, as long as this is the only problem, everything
                * should work fine */
            && strNE(newctype, "C") && strNE(newctype, "POSIX"))
        {
            multi_byte_locale = TRUE;
        }
#endif

        if (bad_count || multi_byte_locale) {
            PL_warn_locale = Perl_newSVpvf(aTHX_
                             "Locale '%s' may not work well.%s%s%s\n",
                             newctype,
                             (multi_byte_locale)
                              ? "  Some characters in it are not recognized by"
                                " Perl."
                              : "",
                             (bad_count)
                              ? "\nThe following characters (and maybe others)"
                                " may not have the same meaning as the Perl"
                                " program expects:\n"
                              : "",
                             (bad_count)
                              ? bad_chars_list
                              : ""
                            );
            /* If we are actually in the scope of the locale, output the
             * message now.  Otherwise we save it to be output at the first
             * operation using this locale, if that actually happens.  Most
             * programs don't use locales, so they are immune to bad ones */
            if (IN_LC(LC_CTYPE)) {

                /* We have to save 'newctype' because the setlocale() just
                 * below may destroy it.  The next setlocale() further down
                 * should restore it properly so that the intermediate change
                 * here is transparent to this function's caller */
                const char * const badlocale = savepv(newctype);

                setlocale(LC_CTYPE, "C");

                /* The '0' below suppresses a bogus gcc compiler warning */
                Perl_warner(aTHX_ packWARN(WARN_LOCALE), SvPVX(PL_warn_locale), 0);
                setlocale(LC_CTYPE, badlocale);
                Safefree(badlocale);
                SvREFCNT_dec_NN(PL_warn_locale);
                PL_warn_locale = NULL;
            }
        }
    }

#endif /* USE_LOCALE_CTYPE */
    PERL_ARGS_ASSERT_NEW_CTYPE;
    PERL_UNUSED_ARG(newctype);
    PERL_UNUSED_CONTEXT;
}

void
Perl__warn_problematic_locale()
{

#ifdef USE_LOCALE_CTYPE

    dTHX;

    /* Internal-to-core function that outputs the message in PL_warn_locale,
     * and then NULLS it.  Should be called only through the macro
     * _CHECK_AND_WARN_PROBLEMATIC_LOCALE */

    if (PL_warn_locale) {
        /*GCC_DIAG_IGNORE(-Wformat-security);   Didn't work */
        Perl_ck_warner(aTHX_ packWARN(WARN_LOCALE),
                             SvPVX(PL_warn_locale),
                             0 /* dummy to avoid compiler warning */ );
        /* GCC_DIAG_RESTORE; */
        SvREFCNT_dec_NN(PL_warn_locale);
        PL_warn_locale = NULL;
    }

#endif

}

void
Perl_new_collate(pTHX_ const char *newcoll)
{
#ifdef USE_LOCALE_COLLATE

    /* Called after all libc setlocale() calls affecting LC_COLLATE, to tell
     * core Perl this and that 'newcoll' is the name of the new locale.
     *
     * Any code changing the locale (outside this file) should use
     * POSIX::setlocale, which calls this function.  Therefore this function
     * should be called directly only from this file and from
     * POSIX::setlocale().
     *
     * The design of locale collation is that every locale change is given an
     * index 'PL_collation_ix'.  The first time a string particpates in an
     * operation that requires collation while locale collation is active, it
     * is given PERL_MAGIC_collxfrm magic (via sv_collxfrm_flags()).  That
     * magic includes the collation index, and the transformation of the string
     * by strxfrm(), q.v.  That transformation is used when doing comparisons,
     * instead of the string itself.  If a string changes, the magic is
     * cleared.  The next time the locale changes, the index is incremented,
     * and so we know during a comparison that the transformation is not
     * necessarily still valid, and so is recomputed.  Note that if the locale
     * changes enough times, the index could wrap (a U32), and it is possible
     * that a transformation would improperly be considered valid, leading to
     * an unlikely bug */

    if (! newcoll) {
	if (PL_collation_name) {
	    ++PL_collation_ix;
	    Safefree(PL_collation_name);
	    PL_collation_name = NULL;
	}
	PL_collation_standard = TRUE;
      is_standard_collation:
	PL_collxfrm_base = 0;
	PL_collxfrm_mult = 2;
        PL_in_utf8_COLLATE_locale = FALSE;
        *PL_strxfrm_min_char = '\0';
        PL_strxfrm_max_cp = 0;
	return;
    }

    /* If this is not the same locale as currently, set the new one up */
    if (! PL_collation_name || strNE(PL_collation_name, newcoll)) {
	++PL_collation_ix;
	Safefree(PL_collation_name);
	PL_collation_name = stdize_locale(savepv(newcoll));
	PL_collation_standard = isNAME_C_OR_POSIX(newcoll);
        if (PL_collation_standard) {
            goto is_standard_collation;
        }

        PL_in_utf8_COLLATE_locale = _is_cur_LC_category_utf8(LC_COLLATE);
        *PL_strxfrm_min_char = '\0';
        PL_strxfrm_max_cp = 0;

        /* A locale collation definition includes primary, secondary, tertiary,
         * etc. weights for each character.  To sort, the primary weights are
         * used, and only if they compare equal, then the secondary weights are
         * used, and only if they compare equal, then the tertiary, etc.
         *
         * strxfrm() works by taking the input string, say ABC, and creating an
         * output transformed string consisting of first the primary weights,
         * A¹B¹C¹ followed by the secondary ones, A²B²C²; and then the
         * tertiary, etc, yielding A¹B¹C¹ A²B²C² A³B³C³ ....  Some characters
         * may not have weights at every level.  In our example, let's say B
         * doesn't have a tertiary weight, and A doesn't have a secondary
         * weight.  The constructed string is then going to be
         *  A¹B¹C¹ B²C² A³C³ ....
         * This has the desired effect that strcmp() will look at the secondary
         * or tertiary weights only if the strings compare equal at all higher
         * priority weights.  The spaces shown here, like in
         *  "A¹B¹C¹ * A²B²C² "
         * are not just for readability.  In the general case, these must
         * actually be bytes, which we will call here 'separator weights'; and
         * they must be smaller than any other weight value, but since these
         * are C strings, only the terminating one can be a NUL (some
         * implementations may include a non-NUL separator weight just before
         * the NUL).  Implementations tend to reserve 01 for the separator
         * weights.  They are needed so that a shorter string's secondary
         * weights won't be misconstrued as primary weights of a longer string,
         * etc.  By making them smaller than any other weight, the shorter
         * string will sort first.  (Actually, if all secondary weights are
         * smaller than all primary ones, there is no need for a separator
         * weight between those two levels, etc.)
         *
         * The length of the transformed string is roughly a linear function of
         * the input string.  It's not exactly linear because some characters
         * don't have weights at all levels.  When we call strxfrm() we have to
         * allocate some memory to hold the transformed string.  The
         * calculations below try to find coefficients 'm' and 'b' for this
         * locale so that m*x + b equals how much space we need, given the size
         * of the input string in 'x'.  If we calculate too small, we increase
         * the size as needed, and call strxfrm() again, but it is better to
         * get it right the first time to avoid wasted expensive string
         * transformations. */

	{
            /* We use the string below to find how long the tranformation of it
             * is.  Almost all locales are supersets of ASCII, or at least the
             * ASCII letters.  We use all of them, half upper half lower,
             * because if we used fewer, we might hit just the ones that are
             * outliers in a particular locale.  Most of the strings being
             * collated will contain a preponderance of letters, and even if
             * they are above-ASCII, they are likely to have the same number of
             * weight levels as the ASCII ones.  It turns out that digits tend
             * to have fewer levels, and some punctuation has more, but those
             * are relatively sparse in text, and khw believes this gives a
             * reasonable result, but it could be changed if experience so
             * dictates. */
            const char longer[] = "ABCDEFGHIJKLMnopqrstuvwxyz";
            char * x_longer;        /* Transformed 'longer' */
            Size_t x_len_longer;    /* Length of 'x_longer' */

            char * x_shorter;   /* We also transform a substring of 'longer' */
            Size_t x_len_shorter;

            /* _mem_collxfrm() is used get the transformation (though here we
             * are interested only in its length).  It is used because it has
             * the intelligence to handle all cases, but to work, it needs some
             * values of 'm' and 'b' to get it started.  For the purposes of
             * this calculation we use a very conservative estimate of 'm' and
             * 'b'.  This assumes a weight can be multiple bytes, enough to
             * hold any UV on the platform, and there are 5 levels, 4 weight
             * bytes, and a trailing NUL.  */
            PL_collxfrm_base = 5;
            PL_collxfrm_mult = 5 * sizeof(UV);

            /* Find out how long the transformation really is */
            x_longer = _mem_collxfrm(longer,
                                     sizeof(longer) - 1,
                                     &x_len_longer,

                                     /* We avoid converting to UTF-8 in the
                                      * called function by telling it the
                                      * string is in UTF-8 if the locale is a
                                      * UTF-8 one.  Since the string passed
                                      * here is invariant under UTF-8, we can
                                      * claim it's UTF-8 even though it isn't.
                                      * */
                                     PL_in_utf8_COLLATE_locale);
            Safefree(x_longer);

            /* Find out how long the transformation of a substring of 'longer'
             * is.  Together the lengths of these transformations are
             * sufficient to calculate 'm' and 'b'.  The substring is all of
             * 'longer' except the first character.  This minimizes the chances
             * of being swayed by outliers */
            x_shorter = _mem_collxfrm(longer + 1,
                                      sizeof(longer) - 2,
                                      &x_len_shorter,
                                      PL_in_utf8_COLLATE_locale);
            Safefree(x_shorter);

            /* If the results are nonsensical for this simple test, the whole
             * locale definition is suspect.  Mark it so that locale collation
             * is not active at all for it.  XXX Should we warn? */
            if (   x_len_shorter == 0
                || x_len_longer == 0
                || x_len_shorter >= x_len_longer)
            {
                PL_collxfrm_mult = 0;
                PL_collxfrm_base = 0;
            }
            else {
                SSize_t base;       /* Temporary */

                /* We have both:    m * strlen(longer)  + b = x_len_longer
                 *                  m * strlen(shorter) + b = x_len_shorter;
                 * subtracting yields:
                 *          m * (strlen(longer) - strlen(shorter))
                 *                             = x_len_longer - x_len_shorter
                 * But we have set things up so that 'shorter' is 1 byte smaller
                 * than 'longer'.  Hence:
                 *          m = x_len_longer - x_len_shorter
                 *
                 * But if something went wrong, make sure the multiplier is at
                 * least 1.
                 */
                if (x_len_longer > x_len_shorter) {
                    PL_collxfrm_mult = (STRLEN) x_len_longer - x_len_shorter;
                }
                else {
                    PL_collxfrm_mult = 1;
                }

                /*     mx + b = len
                 * so:      b = len - mx
                 * but in case something has gone wrong, make sure it is
                 * non-negative */
                base = x_len_longer - PL_collxfrm_mult * (sizeof(longer) - 1);
                if (base < 0) {
                    base = 0;
                }

                /* Add 1 for the trailing NUL */
                PL_collxfrm_base = base + 1;
            }

#ifdef DEBUGGING
            if (DEBUG_L_TEST || debug_initialization) {
                PerlIO_printf(Perl_debug_log,
                    "%s:%d: ?UTF-8 locale=%d; x_len_shorter=%"UVuf", "
                    "x_len_longer=%"UVuf","
                    " collate multipler=%"UVuf", collate base=%"UVuf"\n",
                    __FILE__, __LINE__,
                    PL_in_utf8_COLLATE_locale,
                    x_len_shorter, x_len_longer,
                    PL_collxfrm_mult, PL_collxfrm_base);
            }
#endif
	}
    }

#else
    PERL_UNUSED_ARG(newcoll);
#endif /* USE_LOCALE_COLLATE */
}

#ifdef WIN32

char *
Perl_my_setlocale(pTHX_ int category, const char* locale)
{
    /* This, for Windows, emulates POSIX setlocale() behavior.  There is no
     * difference unless the input locale is "", which means on Windows to get
     * the machine default, which is set via the computer's "Regional and
     * Language Options" (or its current equivalent).  In POSIX, it instead
     * means to find the locale from the user's environment.  This routine
     * looks in the environment, and, if anything is found, uses that instead
     * of going to the machine default.  If there is no environment override,
     * the machine default is used, as normal, by calling the real setlocale()
     * with "".  The POSIX behavior is to use the LC_ALL variable if set;
     * otherwise to use the particular category's variable if set; otherwise to
     * use the LANG variable. */

    bool override_LC_ALL = FALSE;
    char * result;

    if (locale && strEQ(locale, "")) {
#   ifdef LC_ALL
        locale = PerlEnv_getenv("LC_ALL");
        if (! locale) {
#endif
            switch (category) {
#   ifdef LC_ALL
                case LC_ALL:
                    override_LC_ALL = TRUE;
                    break;  /* We already know its variable isn't set */
#   endif
#   ifdef USE_LOCALE_TIME
                case LC_TIME:
                    locale = PerlEnv_getenv("LC_TIME");
                    break;
#   endif
#   ifdef USE_LOCALE_CTYPE
                case LC_CTYPE:
                    locale = PerlEnv_getenv("LC_CTYPE");
                    break;
#   endif
#   ifdef USE_LOCALE_COLLATE
                case LC_COLLATE:
                    locale = PerlEnv_getenv("LC_COLLATE");
                    break;
#   endif
#   ifdef USE_LOCALE_MONETARY
                case LC_MONETARY:
                    locale = PerlEnv_getenv("LC_MONETARY");
                    break;
#   endif
#   ifdef USE_LOCALE_NUMERIC
                case LC_NUMERIC:
                    locale = PerlEnv_getenv("LC_NUMERIC");
                    break;
#   endif
#   ifdef USE_LOCALE_MESSAGES
                case LC_MESSAGES:
                    locale = PerlEnv_getenv("LC_MESSAGES");
                    break;
#   endif
                default:
                    /* This is a category, like PAPER_SIZE that we don't
                     * know about; and so can't provide a wrapper. */
                    break;
            }
            if (! locale) {
                locale = PerlEnv_getenv("LANG");
                if (! locale) {
                    locale = "";
                }
            }
#   ifdef LC_ALL
        }
#   endif
    }

    result = setlocale(category, locale);
    DEBUG_L(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n", __FILE__, __LINE__,
                            _setlocale_debug_string(category, locale, result)));

    if (! override_LC_ALL)  {
        return result;
    }

    /* Here the input category was LC_ALL, and we have set it to what is in the
     * LANG variable or the system default if there is no LANG.  But these have
     * lower priority than the other LC_foo variables, so override it for each
     * one that is set.  (If they are set to "", it means to use the same thing
     * we just set LC_ALL to, so can skip) */
#   ifdef USE_LOCALE_TIME
    result = PerlEnv_getenv("LC_TIME");
    if (result && strNE(result, "")) {
        setlocale(LC_TIME, result);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                    __FILE__, __LINE__,
                    _setlocale_debug_string(LC_TIME, result, "not captured")));
    }
#   endif
#   ifdef USE_LOCALE_CTYPE
    result = PerlEnv_getenv("LC_CTYPE");
    if (result && strNE(result, "")) {
        setlocale(LC_CTYPE, result);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                    __FILE__, __LINE__,
                    _setlocale_debug_string(LC_CTYPE, result, "not captured")));
    }
#   endif
#   ifdef USE_LOCALE_COLLATE
    result = PerlEnv_getenv("LC_COLLATE");
    if (result && strNE(result, "")) {
        setlocale(LC_COLLATE, result);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                  __FILE__, __LINE__,
                  _setlocale_debug_string(LC_COLLATE, result, "not captured")));
    }
#   endif
#   ifdef USE_LOCALE_MONETARY
    result = PerlEnv_getenv("LC_MONETARY");
    if (result && strNE(result, "")) {
        setlocale(LC_MONETARY, result);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                 __FILE__, __LINE__,
                 _setlocale_debug_string(LC_MONETARY, result, "not captured")));
    }
#   endif
#   ifdef USE_LOCALE_NUMERIC
    result = PerlEnv_getenv("LC_NUMERIC");
    if (result && strNE(result, "")) {
        setlocale(LC_NUMERIC, result);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                 __FILE__, __LINE__,
                 _setlocale_debug_string(LC_NUMERIC, result, "not captured")));
    }
#   endif
#   ifdef USE_LOCALE_MESSAGES
    result = PerlEnv_getenv("LC_MESSAGES");
    if (result && strNE(result, "")) {
        setlocale(LC_MESSAGES, result);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                 __FILE__, __LINE__,
                 _setlocale_debug_string(LC_MESSAGES, result, "not captured")));
    }
#   endif

    result = setlocale(LC_ALL, NULL);
    DEBUG_L(PerlIO_printf(Perl_debug_log, "%s:%d: %s\n",
                               __FILE__, __LINE__,
                               _setlocale_debug_string(LC_ALL, NULL, result)));

    return result;
}

#endif


/*
 * Initialize locale awareness.
 */
int
Perl_init_i18nl10n(pTHX_ int printwarn)
{
    /* printwarn is
     *
     *    0 if not to output warning when setup locale is bad
     *    1 if to output warning based on value of PERL_BADLANG
     *    >1 if to output regardless of PERL_BADLANG
     *
     * returns
     *    1 = set ok or not applicable,
     *    0 = fallback to a locale of lower priority
     *   -1 = fallback to all locales failed, not even to the C locale
     *
     * Under -DDEBUGGING, if the environment variable PERL_DEBUG_LOCALE_INIT is
     * set, debugging information is output.
     *
     * This looks more complicated than it is, mainly due to the #ifdefs.
     *
     * We try to set LC_ALL to the value determined by the environment.  If
     * there is no LC_ALL on this platform, we try the individual categories we
     * know about.  If this works, we are done.
     *
     * But if it doesn't work, we have to do something else.  We search the
     * environment variables ourselves instead of relying on the system to do
     * it.  We look at, in order, LC_ALL, LANG, a system default locale (if we
     * think there is one), and the ultimate fallback "C".  This is all done in
     * the same loop as above to avoid duplicating code, but it makes things
     * more complex.  After the original failure, we add the fallback
     * possibilities to the list of locales to try, and iterate the loop
     * through them all until one succeeds.
     *
     * On Ultrix, the locale MUST come from the environment, so there is
     * preliminary code to set it.  I (khw) am not sure that it is necessary,
     * and that this couldn't be folded into the loop, but barring any real
     * platforms to test on, it's staying as-is
     *
     * A slight complication is that in embedded Perls, the locale may already
     * be set-up, and we don't want to get it from the normal environment
     * variables.  This is handled by having a special environment variable
     * indicate we're in this situation.  We simply set setlocale's 2nd
     * parameter to be a NULL instead of "".  That indicates to setlocale that
     * it is not to change anything, but to return the current value,
     * effectively initializing perl's db to what the locale already is.
     *
     * We play the same trick with NULL if a LC_ALL succeeds.  We call
     * setlocale() on the individual categores with NULL to get their existing
     * values for our db, instead of trying to change them.
     * */

    int ok = 1;

#if defined(USE_LOCALE)
#ifdef USE_LOCALE_CTYPE
    char *curctype   = NULL;
#endif /* USE_LOCALE_CTYPE */
#ifdef USE_LOCALE_COLLATE
    char *curcoll    = NULL;
#endif /* USE_LOCALE_COLLATE */
#ifdef USE_LOCALE_NUMERIC
    char *curnum     = NULL;
#endif /* USE_LOCALE_NUMERIC */
#ifdef __GLIBC__
    const char * const language   = savepv(PerlEnv_getenv("LANGUAGE"));
#endif

    /* NULL uses the existing already set up locale */
    const char * const setlocale_init = (PerlEnv_getenv("PERL_SKIP_LOCALE_INIT"))
                                        ? NULL
                                        : "";
    const char* trial_locales[5];   /* 5 = 1 each for "", LC_ALL, LANG, "", C */
    unsigned int trial_locales_count;
    const char * const lc_all     = savepv(PerlEnv_getenv("LC_ALL"));
    const char * const lang       = savepv(PerlEnv_getenv("LANG"));
    bool setlocale_failure = FALSE;
    unsigned int i;
    char *p;

    /* A later getenv() could zap this, so only use here */
    const char * const bad_lang_use_once = PerlEnv_getenv("PERL_BADLANG");

    const bool locwarn = (printwarn > 1
                          || (printwarn
                              && (! bad_lang_use_once
                                  || (
                                    /* disallow with "" or "0" */
                                    *bad_lang_use_once
                                    && strNE("0", bad_lang_use_once)))));
    bool done = FALSE;
    char * sl_result;   /* return from setlocale() */
    char * locale_param;
#ifdef WIN32
    /* In some systems you can find out the system default locale
     * and use that as the fallback locale. */
#   define SYSTEM_DEFAULT_LOCALE
#endif
#ifdef SYSTEM_DEFAULT_LOCALE
    const char *system_default_locale = NULL;
#endif

#ifdef DEBUGGING
    DEBUG_INITIALIZATION_set((PerlEnv_getenv("PERL_DEBUG_LOCALE_INIT"))
                           ? TRUE
                           : FALSE);
#   define DEBUG_LOCALE_INIT(category, locale, result)                      \
	STMT_START {                                                        \
		if (debug_initialization) {                                 \
                    PerlIO_printf(Perl_debug_log,                           \
                                  "%s:%d: %s\n",                            \
                                  __FILE__, __LINE__,                       \
                                  _setlocale_debug_string(category,         \
                                                          locale,           \
                                                          result));         \
                }                                                           \
	} STMT_END
#else
#   define DEBUG_LOCALE_INIT(a,b,c)
#endif

#ifndef LOCALE_ENVIRON_REQUIRED
    PERL_UNUSED_VAR(done);
    PERL_UNUSED_VAR(locale_param);
#else

    /*
     * Ultrix setlocale(..., "") fails if there are no environment
     * variables from which to get a locale name.
     */

#   ifdef LC_ALL
    if (lang) {
	sl_result = my_setlocale(LC_ALL, setlocale_init);
        DEBUG_LOCALE_INIT(LC_ALL, setlocale_init, sl_result);
	if (sl_result)
	    done = TRUE;
	else
	    setlocale_failure = TRUE;
    }
    if (! setlocale_failure) {
#       ifdef USE_LOCALE_CTYPE
        locale_param = (! done && (lang || PerlEnv_getenv("LC_CTYPE")))
                       ? setlocale_init
                       : NULL;
	curctype = my_setlocale(LC_CTYPE, locale_param);
        DEBUG_LOCALE_INIT(LC_CTYPE, locale_param, sl_result);
	if (! curctype)
	    setlocale_failure = TRUE;
	else
	    curctype = savepv(curctype);
#       endif /* USE_LOCALE_CTYPE */
#       ifdef USE_LOCALE_COLLATE
        locale_param = (! done && (lang || PerlEnv_getenv("LC_COLLATE")))
                       ? setlocale_init
                       : NULL;
	curcoll = my_setlocale(LC_COLLATE, locale_param);
        DEBUG_LOCALE_INIT(LC_COLLATE, locale_param, sl_result);
	if (! curcoll)
	    setlocale_failure = TRUE;
	else
	    curcoll = savepv(curcoll);
#       endif /* USE_LOCALE_COLLATE */
#       ifdef USE_LOCALE_NUMERIC
        locale_param = (! done && (lang || PerlEnv_getenv("LC_NUMERIC")))
                       ? setlocale_init
                       : NULL;
	curnum = my_setlocale(LC_NUMERIC, locale_param);
        DEBUG_LOCALE_INIT(LC_NUMERIC, locale_param, sl_result);
	if (! curnum)
	    setlocale_failure = TRUE;
	else
	    curnum = savepv(curnum);
#       endif /* USE_LOCALE_NUMERIC */
#       ifdef USE_LOCALE_MESSAGES
        locale_param = (! done && (lang || PerlEnv_getenv("LC_MESSAGES")))
                       ? setlocale_init
                       : NULL;
	sl_result = my_setlocale(LC_MESSAGES, locale_param);
        DEBUG_LOCALE_INIT(LC_MESSAGES, locale_param, sl_result);
	if (! sl_result)
	    setlocale_failure = TRUE;
        }
#       endif /* USE_LOCALE_MESSAGES */
#       ifdef USE_LOCALE_MONETARY
        locale_param = (! done && (lang || PerlEnv_getenv("LC_MONETARY")))
                       ? setlocale_init
                       : NULL;
	sl_result = my_setlocale(LC_MONETARY, locale_param);
        DEBUG_LOCALE_INIT(LC_MONETARY, locale_param, sl_result);
	if (! sl_result) {
	    setlocale_failure = TRUE;
        }
#       endif /* USE_LOCALE_MONETARY */
    }

#   endif /* LC_ALL */

#endif /* !LOCALE_ENVIRON_REQUIRED */

    /* We try each locale in the list until we get one that works, or exhaust
     * the list.  Normally the loop is executed just once.  But if setting the
     * locale fails, inside the loop we add fallback trials to the array and so
     * will execute the loop multiple times */
    trial_locales[0] = setlocale_init;
    trial_locales_count = 1;
    for (i= 0; i < trial_locales_count; i++) {
        const char * trial_locale = trial_locales[i];

        if (i > 0) {

            /* XXX This is to preserve old behavior for LOCALE_ENVIRON_REQUIRED
             * when i==0, but I (khw) don't think that behavior makes much
             * sense */
            setlocale_failure = FALSE;

#ifdef SYSTEM_DEFAULT_LOCALE
#  ifdef WIN32
            /* On Windows machines, an entry of "" after the 0th means to use
             * the system default locale, which we now proceed to get. */
            if (strEQ(trial_locale, "")) {
                unsigned int j;

                /* Note that this may change the locale, but we are going to do
                 * that anyway just below */
                system_default_locale = setlocale(LC_ALL, "");
                DEBUG_LOCALE_INIT(LC_ALL, "", system_default_locale);

                /* Skip if invalid or it's already on the list of locales to
                 * try */
                if (! system_default_locale) {
                    goto next_iteration;
                }
                for (j = 0; j < trial_locales_count; j++) {
                    if (strEQ(system_default_locale, trial_locales[j])) {
                        goto next_iteration;
                    }
                }

                trial_locale = system_default_locale;
            }
#  endif /* WIN32 */
#endif /* SYSTEM_DEFAULT_LOCALE */
        }

#ifdef LC_ALL
        sl_result = my_setlocale(LC_ALL, trial_locale);
        DEBUG_LOCALE_INIT(LC_ALL, trial_locale, sl_result);
        if (! sl_result) {
            setlocale_failure = TRUE;
        }
        else {
            /* Since LC_ALL succeeded, it should have changed all the other
             * categories it can to its value; so we massage things so that the
             * setlocales below just return their category's current values.
             * This adequately handles the case in NetBSD where LC_COLLATE may
             * not be defined for a locale, and setting it individually will
             * fail, whereas setting LC_ALL suceeds, leaving LC_COLLATE set to
             * the POSIX locale. */
            trial_locale = NULL;
        }
#endif /* LC_ALL */

        if (!setlocale_failure) {
#ifdef USE_LOCALE_CTYPE
            Safefree(curctype);
            curctype = my_setlocale(LC_CTYPE, trial_locale);
            DEBUG_LOCALE_INIT(LC_CTYPE, trial_locale, curctype);
            if (! curctype)
                setlocale_failure = TRUE;
            else
                curctype = savepv(curctype);
#endif /* USE_LOCALE_CTYPE */
#ifdef USE_LOCALE_COLLATE
            Safefree(curcoll);
            curcoll = my_setlocale(LC_COLLATE, trial_locale);
            DEBUG_LOCALE_INIT(LC_COLLATE, trial_locale, curcoll);
            if (! curcoll)
                setlocale_failure = TRUE;
            else
                curcoll = savepv(curcoll);
#endif /* USE_LOCALE_COLLATE */
#ifdef USE_LOCALE_NUMERIC
            Safefree(curnum);
            curnum = my_setlocale(LC_NUMERIC, trial_locale);
            DEBUG_LOCALE_INIT(LC_NUMERIC, trial_locale, curnum);
            if (! curnum)
                setlocale_failure = TRUE;
            else
                curnum = savepv(curnum);
#endif /* USE_LOCALE_NUMERIC */
#ifdef USE_LOCALE_MESSAGES
            sl_result = my_setlocale(LC_MESSAGES, trial_locale);
            DEBUG_LOCALE_INIT(LC_MESSAGES, trial_locale, sl_result);
            if (! (sl_result))
                setlocale_failure = TRUE;
#endif /* USE_LOCALE_MESSAGES */
#ifdef USE_LOCALE_MONETARY
            sl_result = my_setlocale(LC_MONETARY, trial_locale);
            DEBUG_LOCALE_INIT(LC_MONETARY, trial_locale, sl_result);
            if (! (sl_result))
                setlocale_failure = TRUE;
#endif /* USE_LOCALE_MONETARY */

            if (! setlocale_failure) {  /* Success */
                break;
            }
        }

        /* Here, something failed; will need to try a fallback. */
        ok = 0;

        if (i == 0) {
            unsigned int j;

            if (locwarn) { /* Output failure info only on the first one */
#ifdef LC_ALL

                PerlIO_printf(Perl_error_log,
                "perl: warning: Setting locale failed.\n");

#else /* !LC_ALL */

                PerlIO_printf(Perl_error_log,
                "perl: warning: Setting locale failed for the categories:\n\t");
#  ifdef USE_LOCALE_CTYPE
                if (! curctype)
                    PerlIO_printf(Perl_error_log, "LC_CTYPE ");
#  endif /* USE_LOCALE_CTYPE */
#  ifdef USE_LOCALE_COLLATE
                if (! curcoll)
                    PerlIO_printf(Perl_error_log, "LC_COLLATE ");
#  endif /* USE_LOCALE_COLLATE */
#  ifdef USE_LOCALE_NUMERIC
                if (! curnum)
                    PerlIO_printf(Perl_error_log, "LC_NUMERIC ");
#  endif /* USE_LOCALE_NUMERIC */
                PerlIO_printf(Perl_error_log, "and possibly others\n");

#endif /* LC_ALL */

                PerlIO_printf(Perl_error_log,
                    "perl: warning: Please check that your locale settings:\n");

#ifdef __GLIBC__
                PerlIO_printf(Perl_error_log,
                            "\tLANGUAGE = %c%s%c,\n",
                            language ? '"' : '(',
                            language ? language : "unset",
                            language ? '"' : ')');
#endif

                PerlIO_printf(Perl_error_log,
                            "\tLC_ALL = %c%s%c,\n",
                            lc_all ? '"' : '(',
                            lc_all ? lc_all : "unset",
                            lc_all ? '"' : ')');

#if defined(USE_ENVIRON_ARRAY)
                {
                char **e;
                for (e = environ; *e; e++) {
                    if (strnEQ(*e, "LC_", 3)
                            && strnNE(*e, "LC_ALL=", 7)
                            && (p = strchr(*e, '=')))
                        PerlIO_printf(Perl_error_log, "\t%.*s = \"%s\",\n",
                                        (int)(p - *e), *e, p + 1);
                }
                }
#else
                PerlIO_printf(Perl_error_log,
                            "\t(possibly more locale environment variables)\n");
#endif

                PerlIO_printf(Perl_error_log,
                            "\tLANG = %c%s%c\n",
                            lang ? '"' : '(',
                            lang ? lang : "unset",
                            lang ? '"' : ')');

                PerlIO_printf(Perl_error_log,
                            "    are supported and installed on your system.\n");
            }

            /* Calculate what fallback locales to try.  We have avoided this
             * until we have to, because failure is quite unlikely.  This will
             * usually change the upper bound of the loop we are in.
             *
             * Since the system's default way of setting the locale has not
             * found one that works, We use Perl's defined ordering: LC_ALL,
             * LANG, and the C locale.  We don't try the same locale twice, so
             * don't add to the list if already there.  (On POSIX systems, the
             * LC_ALL element will likely be a repeat of the 0th element "",
             * but there's no harm done by doing it explicitly.
             *
             * Note that this tries the LC_ALL environment variable even on
             * systems which have no LC_ALL locale setting.  This may or may
             * not have been originally intentional, but there's no real need
             * to change the behavior. */
            if (lc_all) {
                for (j = 0; j < trial_locales_count; j++) {
                    if (strEQ(lc_all, trial_locales[j])) {
                        goto done_lc_all;
                    }
                }
                trial_locales[trial_locales_count++] = lc_all;
            }
          done_lc_all:

            if (lang) {
                for (j = 0; j < trial_locales_count; j++) {
                    if (strEQ(lang, trial_locales[j])) {
                        goto done_lang;
                    }
                }
                trial_locales[trial_locales_count++] = lang;
            }
          done_lang:

#if defined(WIN32) && defined(LC_ALL)
            /* For Windows, we also try the system default locale before "C".
             * (If there exists a Windows without LC_ALL we skip this because
             * it gets too complicated.  For those, the "C" is the next
             * fallback possibility).  The "" is the same as the 0th element of
             * the array, but the code at the loop above knows to treat it
             * differently when not the 0th */
            trial_locales[trial_locales_count++] = "";
#endif

            for (j = 0; j < trial_locales_count; j++) {
                if (strEQ("C", trial_locales[j])) {
                    goto done_C;
                }
            }
            trial_locales[trial_locales_count++] = "C";

          done_C: ;
        }   /* end of first time through the loop */

#ifdef WIN32
      next_iteration: ;
#endif

    }   /* end of looping through the trial locales */

    if (ok < 1) {   /* If we tried to fallback */
        const char* msg;
        if (! setlocale_failure) {  /* fallback succeeded */
           msg = "Falling back to";
        }
        else {  /* fallback failed */

            /* We dropped off the end of the loop, so have to decrement i to
             * get back to the value the last time through */
            i--;

            ok = -1;
            msg = "Failed to fall back to";

            /* To continue, we should use whatever values we've got */
#ifdef USE_LOCALE_CTYPE
            Safefree(curctype);
            curctype = savepv(setlocale(LC_CTYPE, NULL));
            DEBUG_LOCALE_INIT(LC_CTYPE, NULL, curctype);
#endif /* USE_LOCALE_CTYPE */
#ifdef USE_LOCALE_COLLATE
            Safefree(curcoll);
            curcoll = savepv(setlocale(LC_COLLATE, NULL));
            DEBUG_LOCALE_INIT(LC_COLLATE, NULL, curcoll);
#endif /* USE_LOCALE_COLLATE */
#ifdef USE_LOCALE_NUMERIC
            Safefree(curnum);
            curnum = savepv(setlocale(LC_NUMERIC, NULL));
            DEBUG_LOCALE_INIT(LC_NUMERIC, NULL, curnum);
#endif /* USE_LOCALE_NUMERIC */
        }

        if (locwarn) {
            const char * description;
            const char * name = "";
            if (strEQ(trial_locales[i], "C")) {
                description = "the standard locale";
                name = "C";
            }
#ifdef SYSTEM_DEFAULT_LOCALE
            else if (strEQ(trial_locales[i], "")) {
                description = "the system default locale";
                if (system_default_locale) {
                    name = system_default_locale;
                }
            }
#endif /* SYSTEM_DEFAULT_LOCALE */
            else {
                description = "a fallback locale";
                name = trial_locales[i];
            }
            if (name && strNE(name, "")) {
                PerlIO_printf(Perl_error_log,
                    "perl: warning: %s %s (\"%s\").\n", msg, description, name);
            }
            else {
                PerlIO_printf(Perl_error_log,
                                   "perl: warning: %s %s.\n", msg, description);
            }
        }
    } /* End of tried to fallback */

#ifdef USE_LOCALE_CTYPE
    new_ctype(curctype);
#endif /* USE_LOCALE_CTYPE */

#ifdef USE_LOCALE_COLLATE
    new_collate(curcoll);
#endif /* USE_LOCALE_COLLATE */

#ifdef USE_LOCALE_NUMERIC
    new_numeric(curnum);
#endif /* USE_LOCALE_NUMERIC */

#if defined(USE_PERLIO) && defined(USE_LOCALE_CTYPE)
    /* Set PL_utf8locale to TRUE if using PerlIO _and_ the current LC_CTYPE
     * locale is UTF-8.  If PL_utf8locale and PL_unicode (set by -C or by
     * $ENV{PERL_UNICODE}) are true, perl.c:S_parse_body() will turn on the
     * PerlIO :utf8 layer on STDIN, STDOUT, STDERR, _and_ the default open
     * discipline.  */
    PL_utf8locale = _is_cur_LC_category_utf8(LC_CTYPE);

    /* Set PL_unicode to $ENV{PERL_UNICODE} if using PerlIO.
       This is an alternative to using the -C command line switch
       (the -C if present will override this). */
    {
	 const char *p = PerlEnv_getenv("PERL_UNICODE");
	 PL_unicode = p ? parse_unicode_opts(&p) : 0;
	 if (PL_unicode & PERL_UNICODE_UTF8CACHEASSERT_FLAG)
	     PL_utf8cache = -1;
    }
#endif

#ifdef USE_LOCALE_CTYPE
    Safefree(curctype);
#endif /* USE_LOCALE_CTYPE */
#ifdef USE_LOCALE_COLLATE
    Safefree(curcoll);
#endif /* USE_LOCALE_COLLATE */
#ifdef USE_LOCALE_NUMERIC
    Safefree(curnum);
#endif /* USE_LOCALE_NUMERIC */

#ifdef __GLIBC__
    Safefree(language);
#endif

    Safefree(lc_all);
    Safefree(lang);

#else  /* !USE_LOCALE */
    PERL_UNUSED_ARG(printwarn);
#endif /* USE_LOCALE */

#ifdef DEBUGGING
    /* So won't continue to output stuff */
    DEBUG_INITIALIZATION_set(FALSE);
#endif

    return ok;
}

#ifdef USE_LOCALE_COLLATE

char *
Perl__mem_collxfrm(pTHX_ const char *input_string,
                         STRLEN len,    /* Length of 'input_string' */
                         STRLEN *xlen,  /* Set to length of returned string
                                           (not including the collation index
                                           prefix) */
                         bool utf8      /* Is the input in UTF-8? */
                   )
{

    /* _mem_collxfrm() is a bit like strxfrm() but with two important
     * differences. First, it handles embedded NULs. Second, it allocates a bit
     * more memory than needed for the transformed data itself.  The real
     * transformed data begins at offset COLLXFRM_HDR_LEN.  *xlen is set to
     * the length of that, and doesn't include the collation index size.
     * Please see sv_collxfrm() to see how this is used. */

#define COLLXFRM_HDR_LEN    sizeof(PL_collation_ix)

    char * s = (char *) input_string;
    STRLEN s_strlen = strlen(input_string);
    char *xbuf = NULL;
    STRLEN xAlloc;          /* xalloc is a reserved word in VC */
    STRLEN length_in_chars;
    bool first_time = TRUE; /* Cleared after first loop iteration */

    PERL_ARGS_ASSERT__MEM_COLLXFRM;

    /* Must be NUL-terminated */
    assert(*(input_string + len) == '\0');

    /* If this locale has defective collation, skip */
    if (PL_collxfrm_base == 0 && PL_collxfrm_mult == 0) {
        goto bad;
    }

    /* Replace any embedded NULs with the control that sorts before any others.
     * This will give as good as possible results on strings that don't
     * otherwise contain that character, but otherwise there may be
     * less-than-perfect results with that character and NUL.  This is
     * unavoidable unless we replace strxfrm with our own implementation.
     *
     * XXX This code may be overkill.  khw wrote it before realizing that if
     * you change a NUL into some other character, that that may change the
     * strxfrm results if that character is part of a sequence with other
     * characters for weight calculations.  To minimize the chances of this,
     * now the replacement is restricted to another control (likely to be
     * \001).  But the full generality has been retained.
     *
     * This is one of the few places in the perl core, where we can use
     * standard functions like strlen() and strcat().  It's because we're
     * looking for NULs. */
    if (s_strlen < len) {
        char * e = s + len;
        char * sans_nuls;
        STRLEN cur_min_char_len;

        /* If we don't know what control character sorts lowest for this
         * locale, find it */
        if (*PL_strxfrm_min_char == '\0') {
            int j;
#ifdef DEBUGGING
            U8     cur_min_cp = 1;  /* The code point that sorts lowest, so far */
#endif
            char * cur_min_x = NULL;    /* And its xfrm, (except it also
                                           includes the collation index
                                           prefixed. */

            /* Look through all legal code points (NUL isn't) */
            for (j = 1; j < 256; j++) {
                char * x;       /* j's xfrm plus collation index */
                STRLEN x_len;   /* length of 'x' */
                STRLEN trial_len = 1;

                /* Create a 1 byte string of the current code point, but with
                 * room to be 2 bytes */
                char cur_source[] = { (char) j, '\0' , '\0' };

                if (PL_in_utf8_COLLATE_locale) {
                    if (! isCNTRL_L1(j)) {
                        continue;
                    }

                    /* If needs to be 2 bytes, find them */
                    if (! UVCHR_IS_INVARIANT(j)) {
                        char * d = cur_source;
                        append_utf8_from_native_byte((U8) j, (U8 **) &d);
                        trial_len = 2;
                    }
                }
                else if (! isCNTRL_LC(j)) {
                    continue;
                }

                /* Then transform it */
                x = _mem_collxfrm(cur_source, trial_len, &x_len,
                                  PL_in_utf8_COLLATE_locale);

                /* If something went wrong (which it shouldn't), just
                 * ignore this code point */
                if (   x_len == 0
                    || strlen(x + COLLXFRM_HDR_LEN) < x_len)
                {
                    continue;
                }

                /* If this character's transformation is lower than
                 * the current lowest, this one becomes the lowest */
                if (   cur_min_x == NULL
                    || strLT(x         + COLLXFRM_HDR_LEN,
                             cur_min_x + COLLXFRM_HDR_LEN))
                {
                    PL_strxfrm_min_char[0] = cur_source[0];
                    PL_strxfrm_min_char[1] = cur_source[1];
                    PL_strxfrm_min_char[2] = cur_source[2];
                    cur_min_x = x;
#ifdef DEBUGGING
                    cur_min_cp = j;
#endif
                }
                else {
                    Safefree(x);
                }
            } /* end of loop through all bytes */

            /* Unlikely, but possible, if there aren't any controls in the
             * locale, arbitrarily use \001 */
            if (cur_min_x == NULL) {
                STRLEN x_len;   /* temporary */
                cur_min_x = _mem_collxfrm("\001", 1, &x_len,
                                          PL_in_utf8_COLLATE_locale);
                /* cur_min_cp was already initialized to 1 */
            }

            DEBUG_L(PerlIO_printf(Perl_debug_log,
                    "_mem_collxfrm: lowest collating control in the 0-255 "
                    "range in locale %s is 0x%02X\n",
                    PL_collation_name,
                    cur_min_cp));
            if (DEBUG_Lv_TEST) {
                unsigned i;
                PerlIO_printf(Perl_debug_log, "Its xfrm is");
                for (i = 0; i < strlen(cur_min_x + COLLXFRM_HDR_LEN); i ++) {
                    PerlIO_printf(Perl_debug_log, " %02x",
                                (U8) *(cur_min_x + COLLXFRM_HDR_LEN + i));
                }
                PerlIO_printf(Perl_debug_log, "\n");
            }

            Safefree(cur_min_x);
        }

        /* The worst case length for the replaced string would be if every
         * character in it is NUL.  Multiply that by the length of each
         * replacement, and allow for a trailing NUL */
        cur_min_char_len = strlen(PL_strxfrm_min_char);
        Newx(sans_nuls, (len * cur_min_char_len) + 1, char);
        *sans_nuls = '\0';


        /* Replace each NUL with the lowest collating control.  Loop until have
         * exhausted all the NULs */
        while (s + s_strlen < e) {
            strcat(sans_nuls, s);

            /* Do the actual replacement */
            strcat(sans_nuls, PL_strxfrm_min_char);

            /* Move past the input NUL */
            s += s_strlen + 1;
            s_strlen = strlen(s);
        }

        /* And add anything that trails the final NUL */
        strcat(sans_nuls, s);

        /* Switch so below we transform this modified string */
        s = sans_nuls;
        len = strlen(s);
    }

    /* Make sure the UTF8ness of the string and locale match */
    if (utf8 != PL_in_utf8_COLLATE_locale) {
        const char * const t = s;   /* Temporary so we can later find where the
                                       input was */

        /* Here they don't match.  Change the string's to be what the locale is
         * expecting */

        if (! utf8) { /* locale is UTF-8, but input isn't; upgrade the input */
            s = (char *) bytes_to_utf8((const U8 *) s, &len);
            utf8 = TRUE;
        }
        else {   /* locale is not UTF-8; but input is; downgrade the input */

            s = (char *) bytes_from_utf8((const U8 *) s, &len, &utf8);

            /* If the downgrade was successful we are done, but if the input
             * contains things that require UTF-8 to represent, have to do
             * damage control ... */
            if (UNLIKELY(utf8)) {

                /* What we do is construct a non-UTF-8 string with
                 *  1) the characters representable by a single byte converted
                 *     to be so (if necessary);
                 *  2) and the rest converted to collate the same as the
                 *     highest collating representable character.  That makes
                 *     them collate at the end.  This is similar to how we
                 *     handle embedded NULs, but we use the highest collating
                 *     code point instead of the smallest.  Like the NUL case,
                 *     this isn't perfect, but is the best we can reasonably
                 *     do.  Every above-255 code point will sort the same as
                 *     the highest-sorting 0-255 code point.  If that code
                 *     point can combine in a sequence with some other code
                 *     points for weight calculations, us changing something to
                 *     be it can adversely affect the results.  But in most
                 *     cases, it should work reasonably.  And note that this is
                 *     really an illegal situation: using code points above 255
                 *     on a locale where only 0-255 are valid.  If two strings
                 *     sort entirely equal, then the sort order for the
                 *     above-255 code points will be in code point order. */

                utf8 = FALSE;

                /* If we haven't calculated the code point with the maximum
                 * collating order for this locale, do so now */
                if (! PL_strxfrm_max_cp) {
                    int j;

                    /* The current transformed string that collates the
                     * highest (except it also includes the prefixed collation
                     * index. */
                    char * cur_max_x = NULL;

                    /* Look through all legal code points (NUL isn't) */
                    for (j = 1; j < 256; j++) {
                        char * x;
                        STRLEN x_len;

                        /* Create a 1-char string of the current code point. */
                        char cur_source[] = { (char) j, '\0' };

                        /* Then transform it */
                        x = _mem_collxfrm(cur_source, 1, &x_len, FALSE);

                        /* If something went wrong (which it shouldn't), just
                         * ignore this code point */
                        if (x_len == 0) {
                            Safefree(x);
                            continue;
                        }

                        /* If this character's transformation is higher than
                         * the current highest, this one becomes the highest */
                        if (   cur_max_x == NULL
                            || strGT(x         + COLLXFRM_HDR_LEN,
                                     cur_max_x + COLLXFRM_HDR_LEN))
                        {
                            PL_strxfrm_max_cp = j;
                            cur_max_x = x;
                        }
                        else {
                            Safefree(x);
                        }
                    }

                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "_mem_collxfrm: highest 1-byte collating character"
                            " in locale %s is 0x%02X\n",
                            PL_collation_name,
                            PL_strxfrm_max_cp));
                    if (DEBUG_Lv_TEST) {
                        unsigned i;
                        PerlIO_printf(Perl_debug_log, "Its xfrm is ");
                        for (i = 0;
                             i < strlen(cur_max_x + COLLXFRM_HDR_LEN);
                             i++)
                        {
                            PerlIO_printf(Perl_debug_log, " %02x",
                                        (U8) cur_max_x[i + COLLXFRM_HDR_LEN]);
                        }
                        PerlIO_printf(Perl_debug_log, "\n");
                    }

                    Safefree(cur_max_x);
                }

                /* Here we know which legal code point collates the highest.
                 * We are ready to construct the non-UTF-8 string.  The length
                 * will be at least 1 byte smaller than the input string
                 * (because we changed at least one 2-byte character into a
                 * single byte), but that is eaten up by the trailing NUL */
                Newx(s, len, char);

                {
                    STRLEN i;
                    STRLEN d= 0;

                    for (i = 0; i < len; i+= UTF8SKIP(t + i)) {
                        U8 cur_char = t[i];
                        if (UTF8_IS_INVARIANT(cur_char)) {
                            s[d++] = cur_char;
                        }
                        else if (UTF8_IS_DOWNGRADEABLE_START(cur_char)) {
                            s[d++] = EIGHT_BIT_UTF8_TO_NATIVE(cur_char, t[i+1]);
                        }
                        else {  /* Replace illegal cp with highest collating
                                   one */
                            s[d++] = PL_strxfrm_max_cp;
                        }
                    }
                    s[d++] = '\0';
                    Renew(s, d, char);   /* Free up unused space */
                }
            }
        }

        /* Here, we have constructed a modified version of the input.  It could
         * be that we already had a modified copy before we did this version.
         * If so, that copy is no longer needed */
        if (t != input_string) {
            Safefree(t);
        }
    }

    length_in_chars = (utf8)
                      ? utf8_length((U8 *) s, (U8 *) s + len)
                      : len;

    /* The first element in the output is the collation id, used by
     * sv_collxfrm(); then comes the space for the transformed string.  The
     * equation should give us a good estimate as to how much is needed */
    xAlloc = COLLXFRM_HDR_LEN
           + PL_collxfrm_base
           + (PL_collxfrm_mult * length_in_chars);
    Newx(xbuf, xAlloc, char);
    if (UNLIKELY(! xbuf))
	goto bad;

    /* Store the collation id */
    *(U32*)xbuf = PL_collation_ix;

    /* Then the transformation of the input.  We loop until successful, or we
     * give up */
    for (;;) {
        *xlen = strxfrm(xbuf + COLLXFRM_HDR_LEN, s, xAlloc - COLLXFRM_HDR_LEN);

        /* If the transformed string occupies less space than we told strxfrm()
         * was available, it means it successfully transformed the whole
         * string. */
        if (*xlen < xAlloc - COLLXFRM_HDR_LEN) {

            /* If the first try didn't get it, it means our prediction was low.
             * Modify the coefficients so that we predict a larger value in any
             * future transformations */
            if (! first_time) {
                STRLEN needed = *xlen + 1;   /* +1 For trailing NUL */
                STRLEN computed_guess = PL_collxfrm_base
                                      + (PL_collxfrm_mult * length_in_chars);
                const STRLEN new_m = needed / length_in_chars;

                DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                    "%s: %d: initial size of %"UVuf" bytes for a length "
                    "%"UVuf" string was insufficient, %"UVuf" needed\n",
                    __FILE__, __LINE__,
                    (UV) computed_guess, (UV) length_in_chars, (UV) needed));

                /* If slope increased, use it, but discard this result for
                 * length 1 strings, as we can't be sure that it's a real slope
                 * change */
                if (length_in_chars > 1 && new_m  > PL_collxfrm_mult) {
#ifdef DEBUGGING
                    STRLEN old_m = PL_collxfrm_mult;
                    STRLEN old_b = PL_collxfrm_base;
#endif
                    PL_collxfrm_mult = new_m;
                    PL_collxfrm_base = 1;   /* +1 For trailing NUL */
                    computed_guess = PL_collxfrm_base
                                    + (PL_collxfrm_mult * length_in_chars);
                    if (computed_guess < needed) {
                        PL_collxfrm_base += needed - computed_guess;
                    }

                    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                        "%s: %d: slope is now %"UVuf"; was %"UVuf", base "
                        "is now %"UVuf"; was %"UVuf"\n",
                        __FILE__, __LINE__,
                        (UV) PL_collxfrm_mult, (UV) old_m,
                        (UV) PL_collxfrm_base, (UV) old_b));
                }
                else {  /* Slope didn't change, but 'b' did */
                    const STRLEN new_b = needed
                                        - computed_guess
                                        + PL_collxfrm_base;
                    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                        "%s: %d: base is now %"UVuf"; was %"UVuf"\n",
                        __FILE__, __LINE__,
                        (UV) new_b, (UV) PL_collxfrm_base));
                    PL_collxfrm_base = new_b;
                }
            }

            break;
        }

        if (UNLIKELY(*xlen >= PERL_INT_MAX))
            goto bad;

        /* A well-behaved strxfrm() returns exactly how much space it needs
         * (not including the trailing NUL) when it fails due to not enough
         * space being provided.  Assume that this is the case unless it's been
         * proven otherwise */
        if (LIKELY(PL_strxfrm_is_behaved) && first_time) {
            xAlloc = *xlen + COLLXFRM_HDR_LEN + 1;
        }
        else { /* Here, either:
                *  1)  The strxfrm() has previously shown bad behavior; or
                *  2)  It isn't the first time through the loop, which means
                *      that the strxfrm() is now showing bad behavior, because
                *      we gave it what it said was needed in the previous
                *      iteration, and it came back saying it needed still more.
                *      (Many versions of cygwin fit this.  When the buffer size
                *      isn't sufficient, they return the input size instead of
                *      how much is needed.)
                * Increase the buffer size by a fixed percentage and try again. */
            xAlloc += (xAlloc / 4) + 1;
            PL_strxfrm_is_behaved = FALSE;

#ifdef DEBUGGING
            if (DEBUG_Lv_TEST || debug_initialization) {
                PerlIO_printf(Perl_debug_log,
                "_mem_collxfrm required more space than previously calculated"
                " for locale %s, trying again with new guess=%d+%"UVuf"\n",
                PL_collation_name, (int) COLLXFRM_HDR_LEN,
                (UV) xAlloc - COLLXFRM_HDR_LEN);
            }
#endif
        }

        Renew(xbuf, xAlloc, char);
        if (UNLIKELY(! xbuf))
            goto bad;

        first_time = FALSE;
    }


#ifdef DEBUGGING
    if (DEBUG_Lv_TEST || debug_initialization) {
        unsigned i;
        PerlIO_printf(Perl_debug_log,
            "_mem_collxfrm[%d]: returning %"UVuf" for locale %s '%s'\n",
            PL_collation_ix, *xlen, PL_collation_name, input_string);
        PerlIO_printf(Perl_debug_log, "Its xfrm is");
        for (i = COLLXFRM_HDR_LEN; i < *xlen + COLLXFRM_HDR_LEN; i++) {
            PerlIO_printf(Perl_debug_log, " %02x", (U8) xbuf[i]);
        }
        PerlIO_printf(Perl_debug_log, "\n");
    }
#endif

    /* Free up unneeded space; retain ehough for trailing NUL */
    Renew(xbuf, COLLXFRM_HDR_LEN + *xlen + 1, char);

    if (s != input_string) {
        Safefree(s);
    }

    return xbuf;

  bad:
    Safefree(xbuf);
    if (s != input_string) {
        Safefree(s);
    }
    *xlen = 0;
#ifdef DEBUGGING
    if (DEBUG_Lv_TEST || debug_initialization) {
        PerlIO_printf(Perl_debug_log, "_mem_collxfrm[%d] returning NULL\n",
                                      PL_collation_ix);
    }
#endif
    return NULL;
}

#endif /* USE_LOCALE_COLLATE */

#ifdef USE_LOCALE

bool
Perl__is_cur_LC_category_utf8(pTHX_ int category)
{
    /* Returns TRUE if the current locale for 'category' is UTF-8; FALSE
     * otherwise. 'category' may not be LC_ALL.  If the platform doesn't have
     * nl_langinfo(), nor MB_CUR_MAX, this employs a heuristic, which hence
     * could give the wrong result.  The result will very likely be correct for
     * languages that have commonly used non-ASCII characters, but for notably
     * English, it comes down to if the locale's name ends in something like
     * "UTF-8".  It errs on the side of not being a UTF-8 locale. */

    char *save_input_locale = NULL;
    STRLEN final_pos;

#ifdef LC_ALL
    assert(category != LC_ALL);
#endif

    /* First dispose of the trivial cases */
    save_input_locale = setlocale(category, NULL);
    if (! save_input_locale) {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                              "Could not find current locale for category %d\n",
                              category));
        return FALSE;   /* XXX maybe should croak */
    }
    save_input_locale = stdize_locale(savepv(save_input_locale));
    if (isNAME_C_OR_POSIX(save_input_locale)) {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                              "Current locale for category %d is %s\n",
                              category, save_input_locale));
        Safefree(save_input_locale);
        return FALSE;
    }

#if defined(USE_LOCALE_CTYPE)    \
    && (defined(MB_CUR_MAX) || (defined(HAS_NL_LANGINFO) && defined(CODESET)))

    { /* Next try nl_langinfo or MB_CUR_MAX if available */

        char *save_ctype_locale = NULL;
        bool is_utf8;

        if (category != LC_CTYPE) { /* These work only on LC_CTYPE */

            /* Get the current LC_CTYPE locale */
            save_ctype_locale = setlocale(LC_CTYPE, NULL);
            if (! save_ctype_locale) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                               "Could not find current locale for LC_CTYPE\n"));
                goto cant_use_nllanginfo;
            }
            save_ctype_locale = stdize_locale(savepv(save_ctype_locale));

            /* If LC_CTYPE and the desired category use the same locale, this
             * means that finding the value for LC_CTYPE is the same as finding
             * the value for the desired category.  Otherwise, switch LC_CTYPE
             * to the desired category's locale */
            if (strEQ(save_ctype_locale, save_input_locale)) {
                Safefree(save_ctype_locale);
                save_ctype_locale = NULL;
            }
            else if (! setlocale(LC_CTYPE, save_input_locale)) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                                    "Could not change LC_CTYPE locale to %s\n",
                                    save_input_locale));
                Safefree(save_ctype_locale);
                goto cant_use_nllanginfo;
            }
        }

        DEBUG_L(PerlIO_printf(Perl_debug_log, "Current LC_CTYPE locale=%s\n",
                                              save_input_locale));

        /* Here the current LC_CTYPE is set to the locale of the category whose
         * information is desired.  This means that nl_langinfo() and MB_CUR_MAX
         * should give the correct results */

#   if defined(HAS_NL_LANGINFO) && defined(CODESET)
        {
            char *codeset = nl_langinfo(CODESET);
            if (codeset && strNE(codeset, "")) {
                codeset = savepv(codeset);

                /* If we switched LC_CTYPE, switch back */
                if (save_ctype_locale) {
                    setlocale(LC_CTYPE, save_ctype_locale);
                    Safefree(save_ctype_locale);
                }

                is_utf8 = foldEQ(codeset, STR_WITH_LEN("UTF-8"))
                        || foldEQ(codeset, STR_WITH_LEN("UTF8"));

                DEBUG_L(PerlIO_printf(Perl_debug_log,
                       "\tnllanginfo returned CODESET '%s'; ?UTF8 locale=%d\n",
                                                     codeset,         is_utf8));
                Safefree(codeset);
                Safefree(save_input_locale);
                return is_utf8;
            }
        }

#   endif
#   ifdef MB_CUR_MAX

        /* Here, either we don't have nl_langinfo, or it didn't return a
         * codeset.  Try MB_CUR_MAX */

        /* Standard UTF-8 needs at least 4 bytes to represent the maximum
         * Unicode code point.  Since UTF-8 is the only non-single byte
         * encoding we handle, we just say any such encoding is UTF-8, and if
         * turns out to be wrong, other things will fail */
        is_utf8 = MB_CUR_MAX >= 4;

        DEBUG_L(PerlIO_printf(Perl_debug_log,
                              "\tMB_CUR_MAX=%d; ?UTF8 locale=%d\n",
                                   (int) MB_CUR_MAX,      is_utf8));

        Safefree(save_input_locale);

#       ifdef HAS_MBTOWC

        /* ... But, most system that have MB_CUR_MAX will also have mbtowc(),
         * since they are both in the C99 standard.  We can feed a known byte
         * string to the latter function, and check that it gives the expected
         * result */
        if (is_utf8) {
            wchar_t wc;
            PERL_UNUSED_RESULT(mbtowc(&wc, NULL, 0));/* Reset any shift state */
            errno = 0;
            if ((size_t)mbtowc(&wc, HYPHEN_UTF8, strlen(HYPHEN_UTF8))
                                                        != strlen(HYPHEN_UTF8)
                || wc != (wchar_t) 0x2010)
            {
                is_utf8 = FALSE;
                DEBUG_L(PerlIO_printf(Perl_debug_log, "\thyphen=U+%x\n", (unsigned int)wc));
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                        "\treturn from mbtowc=%d; errno=%d; ?UTF8 locale=0\n",
                        mbtowc(&wc, HYPHEN_UTF8, strlen(HYPHEN_UTF8)), errno));
            }
        }
#       endif

        /* If we switched LC_CTYPE, switch back */
        if (save_ctype_locale) {
            setlocale(LC_CTYPE, save_ctype_locale);
            Safefree(save_ctype_locale);
        }

        return is_utf8;
#   endif
    }

  cant_use_nllanginfo:

#else   /* nl_langinfo should work if available, so don't bother compiling this
           fallback code.  The final fallback of looking at the name is
           compiled, and will be executed if nl_langinfo fails */

    /* nl_langinfo not available or failed somehow.  Next try looking at the
     * currency symbol to see if it disambiguates things.  Often that will be
     * in the native script, and if the symbol isn't in UTF-8, we know that the
     * locale isn't.  If it is non-ASCII UTF-8, we infer that the locale is
     * too, as the odds of a non-UTF8 string being valid UTF-8 are quite small
     * */

#ifdef HAS_LOCALECONV
#   ifdef USE_LOCALE_MONETARY
    {
        char *save_monetary_locale = NULL;
        bool only_ascii = FALSE;
        bool is_utf8 = FALSE;
        struct lconv* lc;

        /* Like above for LC_CTYPE, we first set LC_MONETARY to the locale of
         * the desired category, if it isn't that locale already */

        if (category != LC_MONETARY) {

            save_monetary_locale = setlocale(LC_MONETARY, NULL);
            if (! save_monetary_locale) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Could not find current locale for LC_MONETARY\n"));
                goto cant_use_monetary;
            }
            save_monetary_locale = stdize_locale(savepv(save_monetary_locale));

            if (strEQ(save_monetary_locale, save_input_locale)) {
                Safefree(save_monetary_locale);
                save_monetary_locale = NULL;
            }
            else if (! setlocale(LC_MONETARY, save_input_locale)) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Could not change LC_MONETARY locale to %s\n",
                                                        save_input_locale));
                Safefree(save_monetary_locale);
                goto cant_use_monetary;
            }
        }

        /* Here the current LC_MONETARY is set to the locale of the category
         * whose information is desired. */

        lc = localeconv();
        if (! lc
            || ! lc->currency_symbol
            || is_invariant_string((U8 *) lc->currency_symbol, 0))
        {
            DEBUG_L(PerlIO_printf(Perl_debug_log, "Couldn't get currency symbol for %s, or contains only ASCII; can't use for determining if UTF-8 locale\n", save_input_locale));
            only_ascii = TRUE;
        }
        else {
            is_utf8 = is_utf8_string((U8 *) lc->currency_symbol, 0);
        }

        /* If we changed it, restore LC_MONETARY to its original locale */
        if (save_monetary_locale) {
            setlocale(LC_MONETARY, save_monetary_locale);
            Safefree(save_monetary_locale);
        }

        if (! only_ascii) {

            /* It isn't a UTF-8 locale if the symbol is not legal UTF-8;
             * otherwise assume the locale is UTF-8 if and only if the symbol
             * is non-ascii UTF-8. */
            DEBUG_L(PerlIO_printf(Perl_debug_log, "\t?Currency symbol for %s is UTF-8=%d\n",
                                    save_input_locale, is_utf8));
            Safefree(save_input_locale);
            return is_utf8;
        }
    }
  cant_use_monetary:

#   endif /* USE_LOCALE_MONETARY */
#endif /* HAS_LOCALECONV */

#if defined(HAS_STRFTIME) && defined(USE_LOCALE_TIME)

/* Still haven't found a non-ASCII string to disambiguate UTF-8 or not.  Try
 * the names of the months and weekdays, timezone, and am/pm indicator */
    {
        char *save_time_locale = NULL;
        int hour = 10;
        bool is_dst = FALSE;
        int dom = 1;
        int month = 0;
        int i;
        char * formatted_time;


        /* Like above for LC_MONETARY, we set LC_TIME to the locale of the
         * desired category, if it isn't that locale already */

        if (category != LC_TIME) {

            save_time_locale = setlocale(LC_TIME, NULL);
            if (! save_time_locale) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Could not find current locale for LC_TIME\n"));
                goto cant_use_time;
            }
            save_time_locale = stdize_locale(savepv(save_time_locale));

            if (strEQ(save_time_locale, save_input_locale)) {
                Safefree(save_time_locale);
                save_time_locale = NULL;
            }
            else if (! setlocale(LC_TIME, save_input_locale)) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Could not change LC_TIME locale to %s\n",
                                                        save_input_locale));
                Safefree(save_time_locale);
                goto cant_use_time;
            }
        }

        /* Here the current LC_TIME is set to the locale of the category
         * whose information is desired.  Look at all the days of the week and
         * month names, and the timezone and am/pm indicator for UTF-8 variant
         * characters.  The first such a one found will tell us if the locale
         * is UTF-8 or not */

        for (i = 0; i < 7 + 12; i++) {  /* 7 days; 12 months */
            formatted_time = my_strftime("%A %B %Z %p",
                                    0, 0, hour, dom, month, 112, 0, 0, is_dst);
            if (! formatted_time || is_invariant_string((U8 *) formatted_time, 0)) {

                /* Here, we didn't find a non-ASCII.  Try the next time through
                 * with the complemented dst and am/pm, and try with the next
                 * weekday.  After we have gotten all weekdays, try the next
                 * month */
                is_dst = ! is_dst;
                hour = (hour + 12) % 24;
                dom++;
                if (i > 6) {
                    month++;
                }
                continue;
            }

            /* Here, we have a non-ASCII.  Return TRUE is it is valid UTF8;
             * false otherwise.  But first, restore LC_TIME to its original
             * locale if we changed it */
            if (save_time_locale) {
                setlocale(LC_TIME, save_time_locale);
                Safefree(save_time_locale);
            }

            DEBUG_L(PerlIO_printf(Perl_debug_log, "\t?time-related strings for %s are UTF-8=%d\n",
                                save_input_locale,
                                is_utf8_string((U8 *) formatted_time, 0)));
            Safefree(save_input_locale);
            return is_utf8_string((U8 *) formatted_time, 0);
        }

        /* Falling off the end of the loop indicates all the names were just
         * ASCII.  Go on to the next test.  If we changed it, restore LC_TIME
         * to its original locale */
        if (save_time_locale) {
            setlocale(LC_TIME, save_time_locale);
            Safefree(save_time_locale);
        }
        DEBUG_L(PerlIO_printf(Perl_debug_log, "All time-related words for %s contain only ASCII; can't use for determining if UTF-8 locale\n", save_input_locale));
    }
  cant_use_time:

#endif

#if 0 && defined(USE_LOCALE_MESSAGES) && defined(HAS_SYS_ERRLIST)

/* This code is ifdefd out because it was found to not be necessary in testing
 * on our dromedary test machine, which has over 700 locales.  There, this
 * added no value to looking at the currency symbol and the time strings.  I
 * left it in so as to avoid rewriting it if real-world experience indicates
 * that dromedary is an outlier.  Essentially, instead of returning abpve if we
 * haven't found illegal utf8, we continue on and examine all the strerror()
 * messages on the platform for utf8ness.  If all are ASCII, we still don't
 * know the answer; but otherwise we have a pretty good indication of the
 * utf8ness.  The reason this doesn't help much is that the messages may not
 * have been translated into the locale.  The currency symbol and time strings
 * are much more likely to have been translated.  */
    {
        int e;
        bool is_utf8 = FALSE;
        bool non_ascii = FALSE;
        char *save_messages_locale = NULL;
        const char * errmsg = NULL;

        /* Like above, we set LC_MESSAGES to the locale of the desired
         * category, if it isn't that locale already */

        if (category != LC_MESSAGES) {

            save_messages_locale = setlocale(LC_MESSAGES, NULL);
            if (! save_messages_locale) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Could not find current locale for LC_MESSAGES\n"));
                goto cant_use_messages;
            }
            save_messages_locale = stdize_locale(savepv(save_messages_locale));

            if (strEQ(save_messages_locale, save_input_locale)) {
                Safefree(save_messages_locale);
                save_messages_locale = NULL;
            }
            else if (! setlocale(LC_MESSAGES, save_input_locale)) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Could not change LC_MESSAGES locale to %s\n",
                                                        save_input_locale));
                Safefree(save_messages_locale);
                goto cant_use_messages;
            }
        }

        /* Here the current LC_MESSAGES is set to the locale of the category
         * whose information is desired.  Look through all the messages.  We
         * can't use Strerror() here because it may expand to code that
         * segfaults in miniperl */

        for (e = 0; e <= sys_nerr; e++) {
            errno = 0;
            errmsg = sys_errlist[e];
            if (errno || !errmsg) {
                break;
            }
            errmsg = savepv(errmsg);
            if (! is_invariant_string((U8 *) errmsg, 0)) {
                non_ascii = TRUE;
                is_utf8 = is_utf8_string((U8 *) errmsg, 0);
                break;
            }
        }
        Safefree(errmsg);

        /* And, if we changed it, restore LC_MESSAGES to its original locale */
        if (save_messages_locale) {
            setlocale(LC_MESSAGES, save_messages_locale);
            Safefree(save_messages_locale);
        }

        if (non_ascii) {

            /* Any non-UTF-8 message means not a UTF-8 locale; if all are valid,
             * any non-ascii means it is one; otherwise we assume it isn't */
            DEBUG_L(PerlIO_printf(Perl_debug_log, "\t?error messages for %s are UTF-8=%d\n",
                                save_input_locale,
                                is_utf8));
            Safefree(save_input_locale);
            return is_utf8;
        }

        DEBUG_L(PerlIO_printf(Perl_debug_log, "All error messages for %s contain only ASCII; can't use for determining if UTF-8 locale\n", save_input_locale));
    }
  cant_use_messages:

#endif

#endif /* the code that is compiled when no nl_langinfo */

#ifndef EBCDIC  /* On os390, even if the name ends with "UTF-8', it isn't a
                   UTF-8 locale */
    /* As a last resort, look at the locale name to see if it matches
     * qr/UTF -?  * 8 /ix, or some other common locale names.  This "name", the
     * return of setlocale(), is actually defined to be opaque, so we can't
     * really rely on the absence of various substrings in the name to indicate
     * its UTF-8ness, but if it has UTF8 in the name, it is extremely likely to
     * be a UTF-8 locale.  Similarly for the other common names */

    final_pos = strlen(save_input_locale) - 1;
    if (final_pos >= 3) {
        char *name = save_input_locale;

        /* Find next 'U' or 'u' and look from there */
        while ((name += strcspn(name, "Uu") + 1)
                                            <= save_input_locale + final_pos - 2)
        {
            if (!isALPHA_FOLD_NE(*name, 't')
                || isALPHA_FOLD_NE(*(name + 1), 'f'))
            {
                continue;
            }
            name += 2;
            if (*(name) == '-') {
                if ((name > save_input_locale + final_pos - 1)) {
                    break;
                }
                name++;
            }
            if (*(name) == '8') {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                                      "Locale %s ends with UTF-8 in name\n",
                                      save_input_locale));
                Safefree(save_input_locale);
                return TRUE;
            }
        }
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                              "Locale %s doesn't end with UTF-8 in name\n",
                                save_input_locale));
    }
#endif

#ifdef WIN32
    /* http://msdn.microsoft.com/en-us/library/windows/desktop/dd317756.aspx */
    if (final_pos >= 4
        && *(save_input_locale + final_pos - 0) == '1'
        && *(save_input_locale + final_pos - 1) == '0'
        && *(save_input_locale + final_pos - 2) == '0'
        && *(save_input_locale + final_pos - 3) == '5'
        && *(save_input_locale + final_pos - 4) == '6')
    {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                        "Locale %s ends with 10056 in name, is UTF-8 locale\n",
                        save_input_locale));
        Safefree(save_input_locale);
        return TRUE;
    }
#endif

    /* Other common encodings are the ISO 8859 series, which aren't UTF-8.  But
     * since we are about to return FALSE anyway, there is no point in doing
     * this extra work */
#if 0
    if (instr(save_input_locale, "8859")) {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                             "Locale %s has 8859 in name, not UTF-8 locale\n",
                             save_input_locale));
        Safefree(save_input_locale);
        return FALSE;
    }
#endif

    DEBUG_L(PerlIO_printf(Perl_debug_log,
                          "Assuming locale %s is not a UTF-8 locale\n",
                                    save_input_locale));
    Safefree(save_input_locale);
    return FALSE;
}

#endif


bool
Perl__is_in_locale_category(pTHX_ const bool compiling, const int category)
{
    dVAR;
    /* Internal function which returns if we are in the scope of a pragma that
     * enables the locale category 'category'.  'compiling' should indicate if
     * this is during the compilation phase (TRUE) or not (FALSE). */

    const COP * const cop = (compiling) ? &PL_compiling : PL_curcop;

    SV *categories = cop_hints_fetch_pvs(cop, "locale", 0);
    if (! categories || categories == &PL_sv_placeholder) {
        return FALSE;
    }

    /* The pseudo-category 'not_characters' is -1, so just add 1 to each to get
     * a valid unsigned */
    assert(category >= -1);
    return cBOOL(SvUV(categories) & (1U << (category + 1)));
}

char *
Perl_my_strerror(pTHX_ const int errnum) {
    dVAR;

    /* Uses C locale for the error text unless within scope of 'use locale' for
     * LC_MESSAGES */

#ifdef USE_LOCALE_MESSAGES
    if (! IN_LC(LC_MESSAGES)) {
        char * save_locale;

        /* We have a critical section to prevent another thread from changing
         * the locale out from under us (or zapping the buffer returned from
         * setlocale() ) */
        LOCALE_LOCK;

        save_locale = setlocale(LC_MESSAGES, NULL);
        if (! isNAME_C_OR_POSIX(save_locale)) {
            char *errstr;

            /* The next setlocale likely will zap this, so create a copy */
            save_locale = savepv(save_locale);

            setlocale(LC_MESSAGES, "C");

            /* This points to the static space in Strerror, with all its
             * limitations */
            errstr = Strerror(errnum);

            setlocale(LC_MESSAGES, save_locale);
            Safefree(save_locale);

            LOCALE_UNLOCK;

            return errstr;
        }

        LOCALE_UNLOCK;
    }
#endif

    return Strerror(errnum);
}

/*

=head1 Locale-related functions and macros

=for apidoc sync_locale

Changing the program's locale should be avoided by XS code.  Nevertheless,
certain non-Perl libraries called from XS, such as C<Gtk> do so.  When this
happens, Perl needs to be told that the locale has changed.  Use this function
to do so, before returning to Perl.

=cut
*/

void
Perl_sync_locale(pTHX)
{

#ifdef USE_LOCALE_CTYPE
    new_ctype(setlocale(LC_CTYPE, NULL));
#endif /* USE_LOCALE_CTYPE */

#ifdef USE_LOCALE_COLLATE
    new_collate(setlocale(LC_COLLATE, NULL));
#endif

#ifdef USE_LOCALE_NUMERIC
    set_numeric_local();    /* Switch from "C" to underlying LC_NUMERIC */
    new_numeric(setlocale(LC_NUMERIC, NULL));
#endif /* USE_LOCALE_NUMERIC */

}

#if defined(DEBUGGING) && defined(USE_LOCALE)

char *
Perl__setlocale_debug_string(const int category,        /* category number,
                                                           like LC_ALL */
                            const char* const locale,   /* locale name */

                            /* return value from setlocale() when attempting to
                             * set 'category' to 'locale' */
                            const char* const retval)
{
    /* Returns a pointer to a NUL-terminated string in static storage with
     * added text about the info passed in.  This is not thread safe and will
     * be overwritten by the next call, so this should be used just to
     * formulate a string to immediately print or savepv() on. */

    /* initialise to a non-null value to keep it out of BSS and so keep
     * -DPERL_GLOBAL_STRUCT_PRIVATE happy */
    static char ret[128] = "x";

    my_strlcpy(ret, "setlocale(", sizeof(ret));

    switch (category) {
        default:
            my_snprintf(ret, sizeof(ret), "%s? %d", ret, category);
            break;
#   ifdef LC_ALL
        case LC_ALL:
            my_strlcat(ret, "LC_ALL", sizeof(ret));
            break;
#   endif
#   ifdef LC_CTYPE
        case LC_CTYPE:
            my_strlcat(ret, "LC_CTYPE", sizeof(ret));
            break;
#   endif
#   ifdef LC_NUMERIC
        case LC_NUMERIC:
            my_strlcat(ret, "LC_NUMERIC", sizeof(ret));
            break;
#   endif
#   ifdef LC_COLLATE
        case LC_COLLATE:
            my_strlcat(ret, "LC_COLLATE", sizeof(ret));
            break;
#   endif
#   ifdef LC_TIME
        case LC_TIME:
            my_strlcat(ret, "LC_TIME", sizeof(ret));
            break;
#   endif
#   ifdef LC_MONETARY
        case LC_MONETARY:
            my_strlcat(ret, "LC_MONETARY", sizeof(ret));
            break;
#   endif
#   ifdef LC_MESSAGES
        case LC_MESSAGES:
            my_strlcat(ret, "LC_MESSAGES", sizeof(ret));
            break;
#   endif
    }

    my_strlcat(ret, ", ", sizeof(ret));

    if (locale) {
        my_strlcat(ret, "\"", sizeof(ret));
        my_strlcat(ret, locale, sizeof(ret));
        my_strlcat(ret, "\"", sizeof(ret));
    }
    else {
        my_strlcat(ret, "NULL", sizeof(ret));
    }

    my_strlcat(ret, ") returned ", sizeof(ret));

    if (retval) {
        my_strlcat(ret, "\"", sizeof(ret));
        my_strlcat(ret, retval, sizeof(ret));
        my_strlcat(ret, "\"", sizeof(ret));
    }
    else {
        my_strlcat(ret, "NULL", sizeof(ret));
    }

    assert(strlen(ret) < sizeof(ret));

    return ret;
}

#endif


/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
