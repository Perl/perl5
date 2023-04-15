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
 * All C programs have an underlying locale.  Perl code generally doesn't pay
 * any attention to it except within the scope of a 'use locale'.  For most
 * categories, it accomplishes this by just using different operations if it is
 * in such scope than if not.  However, various libc functions called by Perl
 * are affected by the LC_NUMERIC category, so there are macros in perl.h that
 * are used to toggle between the current locale and the C locale depending on
 * the desired behavior of those functions at the moment.  And, LC_MESSAGES is
 * switched to the C locale for outputting the message unless within the scope
 * of 'use locale'.
 *
 * There is more than the typical amount of variation between platforms with
 * regard to locale handling.  At the end of these introductory comments, are
 * listed various relevent Configuration options, including some that can be
 * used to pretend to some extent that this is being developed on a different
 * platform than it actually is.  This allows you to make changes and catch
 * some errors without having access to those other platforms.
 *
 * This code now has multi-thread-safe locale handling on systems that support
 * that.  This is completely transparent to most XS code.  On earlier systems,
 * it would be possible to emulate thread-safe locales, but this likely would
 * involve a lot of locale switching, and would require XS code changes.
 * Macros could be written so that the code wouldn't have to know which type of
 * system is being used.
 *
 * Table-driven code is used for simplicity and clarity, as many operations
 * differ only in which category is being worked on.  However the system
 * categories need not be small contiguous integers, so do not lend themselves
 * to table lookup.  Instead we have created our own equivalent values which
 * are all small contiguous non-negative integers, and translation functions
 * between the two sets.  For category 'LC_foo', the name of our index is
 * LC_foo_INDEX_.  Various parallel tables, indexed by these, are used for the
 * translation.  The tables are generated at compile-time based on platform
 * characteristics and Configure options.  They hide from the code many of the
 * vagaries of the different locale implementations out there.
 *
 * On unthreaded perls, most operations expand out to just the basic
 * setlocale() calls.  That sort of is true on threaded perls on modern Windows
 * systems where the same API, after set up, is used for thread-safe locale
 * handling.  (But there are complications on Windows due to internal character
 * set issues.)  On other systems, there is a completely different API,
 * specified in POSIX 2008, to do thread-safe locales.  On these systems, our
 * bool_setlocale_2008_i() function is used to hide the different API from the
 * outside.  This makes it completely transparent to most XS code.
 *
 * A huge complicating factor is that the LC_NUMERIC category is normally held
 * in the C locale, except during those relatively rare times when it needs to
 * be in the underlying locale.  There is a bunch of code to accomplish this,
 * and to allow easy switches from one state to the other.
 *
 * In addition, the setlocale equivalents have versions for the return context,
 * 'void' and 'bool', besides the full return value.  This can present
 * opportunities for avoiding work.  We don't have to necessarily create a safe
 * copy to return if no return is desired.
 *
 * There are 3.5 major implementations here; which one chosen depends on what
 * the platform has available, and Configuration options.
 *
 * 1) Raw posix_setlocale().  This implementation is basically the libc
 *    setlocale(), with possibly minor tweaks.  This is used for startup, and
 *    always for unthreaded perls, and when the API for safe locale threading
 *    is identical to the unsafe API (Windows, currently).
 *
 *    This implementation is composed of two layers:
 *      a)  posix_setlocale() implements the libc setlocale().  In most cases,
 *          it is just an alias for the libc version.  But Windows doesn't
 *          fully conform to the POSIX standard, and this is a layer on top of
 *          libc to bring it more into conformance.
 *      b)  stdized_setlocale() is a layer above a) that fixes some vagaries in
 *          the return value of the libc setlocale().  On most platforms this
 *          layer is empty; it requires perl to be Configured with a parameter
 *          indicating the platform's defect, in order to be activated.  The
 *          current ones are listed at the definition of the macro.
 *
 * 2) An implementation that adds a minimal layer above implementation 1),
 *    making that implementation uninterruptible and returning a
 *    per-thread/per-category value.
 *
 * 3a and 3b) An implementation of POSIX 2008 thread-safe locale handling,
 *    hiding from the programmer the completely different API for this.
 *    This automatically makes almost all code thread-safe without need for
 *    changes.  This implementation is chosen on threaded perls when the
 *    platform properly supports the POSIX 2008 functions, and when there is no
 *    manual override to the contrary passed to Configure.
 *
 *    3a) is when the platform has a documented reliable querylocale() function
 *        or equivalent that is selected to be used.
 *    3b) is when we have to emulate that functionality.
 *
 *    Unfortunately, it seems that some platforms that claim to support these
 *    are buggy, in one way or another.  There are workarounds encoded here,
 *    where feasible, for platforms where the bugs are amenable to that
 *    (glibc, for example).  But other platforms instead don't use this
 *    implementation.
 *
 * z/OS (os390) is an outlier.  Locales really don't work under threads when
 * either the radix character isn't a dot, or attempts are made to change
 * locales after the first thread is created.  The reason is that IBM has made
 * it thread-safe by refusing to change locales (returning failure if
 * attempted) any time after an application has called pthread_create() to
 * create another thread.  The expectation is that an application will set up
 * its locale information before the first fork, and be stable thereafter.  But
 * perl toggles LC_NUMERIC if the locale's radix character isn't a dot, as do
 * the other toggles, which are less common.
 *
 * Associated with each implementation are three sets of macros that translate
 * a consistent API into what that implementation needs.  Each set consists of
 * three macros with the suffixes:
 *  _c  Means the argument is a locale category number known at compile time.
 *          An example would be LC_TIME.  This token is a compile-time constant
 *          and can be passed to a '_c' macro.
 *  _r  Means the argument is a locale category number whose value might not be
 *      known until runtime
 *  _i  Means the argument is our internal index of a locale category
 *
 * The three sets are:    ('_X'  means one of '_c', '_r', '_i')
 * 1) bool_setlocale_X()
 *      This calls the appropriate setlocale()-equivalent for the
 *      implementation, with the category and new locale.  The input locale is
 *      not necessarily valid, so the return is true or false depending on
 *      whether or not the setlocale() succeeded.  This is not used for
 *      querying the locale, so the input locale must not be NULL.
 *
 *      This macro is suitable for toggling the locale back and forth during an
 *      operation.  For example, the names of days and months under LC_TIME are
 *      strings that are also subject to LC_CTYPE.  If the locales of these two
 *      categories differ, mojibake can result on many platforms.  The code
 *      here will toggle LC_CTYPE into the locale of LC_TIME temporarily to
 *      avoid this.
 *
 *      Several categories require extra work when their locale is changed.
 *      LC_CTYPE, for example, requires the calculation of the table of which
 *      characters fold to which others under /i pattern matching or fc(), as
 *      folding is not a concept in POSIX.  This table isn't needed when the
 *      LC_CTYPE locale gets toggled during an operation, and will be toggled
 *      back before return to the caller.  To save work that would be
 *      discarded, the bool_setlocale_X() implementations don't do this extra
 *      work.  Instead, there is a separate function for just this purpose to
 *      be done before control is transferred back to the external caller.  All
 *      categories that have such requirements have such a function.  The
 *      update_functions[] array contains pointers to them (or NULL for
 *      categories which don't need a function).
 *
 *      Care must be taken to remember to call the separate function before
 *      returning to an external caller, and to not use things it updates
 *      before its call.  An alternative approach would be to have
 *      bool_setlocale_X() always call the update, which would return
 *      immediately if a flag wasn't set indicating it was time to actually
 *      perform it.
 *
 * 2) void_setlocale_X()
 *      This is like bool_setlocale_X(), but it is used only when it is
 *      expected that the call must succeed, or something is seriously wrong.
 *      A panic is issued if it fails.  The caller uses this form when it just
 *      wants to assume things worked.
 *
 * 3) querylocale_X()
 *      This returns a string that specifies the current locale for the given
 *      category given by the input argument.  The string is safe from other
 *      threads zapping it, and the caller need not worry about freeing it, but
 *      it may be mortalized, so must be copied if you need to preserve it
 *      across calls, or long term.  This returns the actual current locale,
 *      not the nominal.  These differ, for example, when LC_NUMERIC is
 *      supposed to be a locale whose decimal radix character is a comma.  As
 *      mentioned above, Perl actually keeps this category set to C in such
 *      circumstances so that XS code can just assume a dot radix character.
 *      querylocale_X() returns the locale that libc has stored at this moment,
 *      so most of the time will return a locale whose radix character is a
 *      dot.  The macro query_nominal_locale_i() can be used to get the nominal
 *      locale that an external caller would expect, for all categories except
 *      LC_ALL.  For that, you can use the function
 *      S_calculate_LC_ALL_string().
 *
 * The underlying C API that this implements uses category numbers, hence the
 * code is structured to use '_r' at the API level to convert to indexes, which
 * are then used internally with the '_i' forms.
 *
 * The splitting apart into setting vs querying means that the return value of
 * the bool macros is not subject to potential clashes with other threads,
 * eliminating any need for the calling code to worry about that and get it
 * wrong.  Whereas, you do have to think about thread interactions when using a
 * query.
 *
 * There are also a few other macros herein that use this naming convention to
 * describe their category parameter.
 *
 * Relevant Configure options
 *
 *      -Accflags=-DNO_LOCALE
 *          This compiles perl to always use the C locale, ignoring any
 *          attempts to change it.  This could be useful on platforms with a
 *          crippled locale implementation.
 *
 *      -Accflags=-DNO_THREAD_SAFE_LOCALE
 *          Even if thread-safe operations are available on this platform and
 *          would otherwise be used (because this is a perl with multiplicity),
 *          perl is compiled to not use them.  This could be useful on
 *          platforms where the libc is buggy.
 *
 *      -Accflags=-DNO_POSIX_2008_LOCALE
 *          Even if the libc locale operations specified by the Posix 2008
 *          Standard are available on this platform and would otherwise be used
 *          (because this is a perl with multiplicity), perl is compiled to not
 *          use them.  This could be useful on platforms where the libc is
 *          buggy.  This is like NO_THREAD_SAFE_LOCALE, but has no effect on
 *          platforms that don't have these functions.
 *
 *      -Accflags=-DUSE_POSIX_2008_LOCALE
 *          Normally, setlocale() is used for locale operations on perls
 *          compiled without multiplicity.  This option causes the locale
 *          operations defined by the Posix 2008 Standard to always be used
 *          instead.  This could be useful on platforms where the libc
 *          setlocale() is buggy.
 *
 *      -Accflags=-DNO_THREAD_SAFE_QUERYLOCALE
 *          This applies only to platforms that have a querylocale() libc
 *          function.  perl assumes that that function is thread-safe, unless
 *          overridden by this, typically in a hints file.  When overridden,
 *          querylocale() is called only while the locale mutex is locked, and
 *          the result is copied to a per-thread place before unlocking.
 *
 *      -Accflags=-DHAS_BROKEN_SETLOCALE_QUERY_LC_ALL
 *          This would be set in a hints file to tell perl that doing a libc
 *              setlocale(LC_ALL, NULL)
 *          can give erroneous results, and perl will compensate to get the
 *          correct results.  This is known to be a problem in earlier AIX
 *          versions
 *
 *      -Accflags=-DHAS_LF_IN_SETLOCALE_RETURN
 *          This would be set in a hints file to tell perl that a libc
 *          setlocale() can return results containing \n characters that need
 *          to be stripped off.  khw believes there aren't any such platforms
 *          still in existence.
 *
 *      -Accflags=USE_FAKE_LC_ALL_POSITIONAL_NOTATION
 *          This is used when developing Perl on a platform that uses
 *          'name=value;' notation to represent LC_ALL when not all categories
 *          are the same.  When so compiled, much of the code gets compiled
 *          and exercised that applies to platforms that instead use positional
 *          notation.  This allows for finding many bugs in that portion of the
 *          implementation, without having to access such a platform.
 *
 *      -Accflags=-DWIN32_USE_FAKE_OLD_MINGW_LOCALES
 *          This is used when developing Perl on a non-Windows platform to
 *          compile and exercise much of the locale-related code that instead
 *          applies to MingW platforms that don't use the more modern UCRT
 *          library.  This allows for finding many bugs in that portion of the
 *          implementation, without having to access such a platform.
 */

/* If the environment says to, we can output debugging information during
 * initialization.  This is done before option parsing, and before any thread
 * creation, so can be a file-level static.  (Must come before #including
 * perl.h) */
#include "config.h"
#ifdef DEBUGGING
static int debug_initialization = 0;
#  define DEBUG_INITIALIZATION_set(v) (debug_initialization = v)
#  define DEBUG_LOCALE_INITIALIZATION_  debug_initialization
#  if defined(USE_ITHREADS) && ! defined(NO_LOCALE_THREADS)
#    define DEBUG_PRE_STMTS                                                     \
     dSAVE_ERRNO; dTHX; PerlIO_printf(Perl_debug_log,"\n%s: %" LINE_Tf ": 0x%p: ",\
                                      __FILE__, (line_t)__LINE__, aTHX);
#  else
#    define DEBUG_PRE_STMTS                                                     \
     dSAVE_ERRNO; dTHX; PerlIO_printf(Perl_debug_log, "\n%s: %" LINE_Tf ": ",   \
                                      __FILE__, (line_t)__LINE__);
#  endif
#  define DEBUG_POST_STMTS  RESTORE_ERRNO;
#else
#  define debug_initialization 0
#  define DEBUG_INITIALIZATION_set(v)
#  define DEBUG_PRE_STMTS
#  define DEBUG_POST_STMTS
#endif

#include "EXTERN.h"
#define PERL_IN_LOCALE_C
#include "perl.h"

#ifdef WIN32_USE_FAKE_OLD_MINGW_LOCALES

   /* Use -Accflags=-DWIN32_USE_FAKE_OLD_MINGW_LOCALES on a POSIX or *nix box
    * to get a semblance of pretending the locale handling is that of a MingW
    * that doesn't use UCRT (hence 'OLD' in the name).  This exercizes code
    * paths that are not compiled on non-Windows boxes, and allows for ASAN.
    * This is thus a way to see if locale.c on Windows is likely going to
    * compile, without having to use a real Win32 box.  And running the test
    * suite will verify to a large extent our logic and memory allocation
    * handling for such boxes.  And access to ASAN and PERL_MEMLOG Of course the underlying calls are to the POSIX
    * libc, so any differences in implementation between those and the Windows
    * versions will not be caught by this. */

#  define WIN32
#  undef P_CS_PRECEDES
#  undef CURRENCY_SYMBOL
#  define CP_UTF8 -1
#  undef _configthreadlocale
#  define _configthreadlocale(arg) NOOP

#  define MultiByteToWideChar(cp, flags, byte_string, m1, wstring, req_size) \
                    (mbsrtowcs(wstring, &(byte_string), req_size, NULL) + 1)
#  define WideCharToMultiByte(cp, flags, wstring, m1, byte_string,          \
                              req_size, default_char, found_default_char)   \
                    (wcsrtombs(byte_string, &(wstring), req_size, NULL) + 1)

#  ifdef USE_LOCALE

static const wchar_t * wsetlocale_buf = NULL;
static Size_t wsetlocale_buf_size = 0;
static PerlInterpreter * wsetlocale_buf_aTHX = NULL;

STATIC
const wchar_t *
S_wsetlocale(const int category, const wchar_t * wlocale)
{
    /* Windows uses a setlocale that takes a wchar_t* locale.  Other boxes
     * don't have this, so this Windows replacement converts the wchar_t input
     * to plain 'char*', calls plain setlocale(), and converts the result back
     * to 'wchar_t*' */

    const char * byte_locale = NULL;
    if (wlocale) {
        byte_locale = Win_wstring_to_byte_string(CP_UTF8, wlocale);
    }

    const char * byte_result = setlocale(category, byte_locale);
    Safefree(byte_locale);
    if (byte_result == NULL) {
        return NULL;
    }

    const wchar_t * wresult = Win_byte_string_to_wstring(CP_UTF8, byte_result);

    if (! wresult) {
        return NULL;
    }

    /* Emulate a global static memory return from wsetlocale().  This currently
     * leaks at process end; would require changing LOCALE_TERM to fix that */
    Size_t string_size = wcslen(wresult) + 1;

    if (wsetlocale_buf_size == 0) {
        Newx(wsetlocale_buf, string_size, wchar_t);
        wsetlocale_buf_size = string_size;

#  ifdef MULTIPLICITY

        dTHX;
        wsetlocale_buf_aTHX = aTHX;

#  endif

    }
    else if (string_size > wsetlocale_buf_size) {
        Renew(wsetlocale_buf, string_size, wchar_t);
        wsetlocale_buf_size = string_size;
    }

    Copy(wresult, wsetlocale_buf, string_size, wchar_t);
    Safefree(wresult);

    return wsetlocale_buf;
}

#  define _wsetlocale(category, wlocale)  S_wsetlocale(category, wlocale)
#  endif
#endif  /* WIN32_USE_FAKE_OLD_MINGW_LOCALES */

#ifdef USE_LOCALE
#  if defined(USE_FAKE_LC_ALL_POSITIONAL_NOTATION) && defined(LC_ALL)

/* This simulates an underlying positional notation for LC_ALL when compiled on
 * a system that uses name=value notation.  Use this to develop on Linux and
 * make a quick check that things have some chance of working on a positional
 * box.  Enable by adding to the Congfigure parameters:
 *      -Accflags=USE_FAKE_LC_ALL_POSITIONAL_NOTATION
 *
 * NOTE it redefines setlocale() and usequerylocale()
 * */

STATIC const char *
S_positional_name_value_xlation(const char * locale, bool direction)
{   /* direction == 1 is from name=value to positional
       direction == 0 is from positional to name=value */
    assert(locale);

    dTHX;
    const char * individ_locales[LC_ALL_INDEX_] = { NULL };

    /* This parses either notation */
    switch (parse_LC_ALL_string(locale,
                                (const char **) &individ_locales,
                                false,      /* Return only [0] if suffices */
                                false,      /* Don't panic on error */
                                __LINE__))
    {
      default:      /* Some compilers don't realize that below is the complete
                       list of the available enum values */
      case invalid:
        return NULL;

      case no_array:
        return locale;
      case only_element_0:
        SAVEFREEPV(individ_locales[0]);
        return individ_locales[0];
      case full_array:
       {
        calc_LC_ALL_format  format = (direction)
                                     ? EXTERNAL_FORMAT_FOR_SET
                                     : INTERNAL_FORMAT;
        const char * retval = calculate_LC_ALL_string(individ_locales,
                                                      format, __LINE__);

        for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
            Safefree(individ_locales[i]);
        }

        return retval;
       }
    }
}

STATIC const char *
S_positional_setlocale(int cat, const char * locale)
{
    if (cat != LC_ALL) return setlocale(cat, locale);

    if (locale && strNE(locale, "")) {
        locale = S_positional_name_value_xlation(locale, 0);
        if (! locale) return NULL;
    }

    locale = setlocale(cat, locale);
    if (locale == NULL) return NULL;
    return S_positional_name_value_xlation(locale, 1);
}

#    undef setlocale
#    define setlocale(a,b)  S_positional_setlocale(a,b)
#    ifdef USE_POSIX_2008_LOCALE

STATIC locale_t
S_positional_newlocale(int mask, const char * locale, locale_t base)
{
    assert(locale);

    if (mask != LC_ALL_MASK) return newlocale(mask, locale, base);

    if (strNE(locale, "")) locale = S_positional_name_value_xlation(locale, 0);
    if (locale == NULL) return NULL;
    return newlocale(LC_ALL_MASK, locale, base);
}

#    undef newlocale
#    define newlocale(a,b,c)  S_positional_newlocale(a,b,c)
#    endif
#  endif
#endif  /* End of fake positional notation */

#include "reentr.h"

#ifdef I_WCHAR
#  include <wchar.h>
#endif
#ifdef I_WCTYPE
#  include <wctype.h>
#endif

 /* The main errno that gets used is this one, on platforms that support it */
#ifdef EINVAL
#  define SET_EINVAL  SETERRNO(EINVAL, LIB_INVARG)
#else
#  define SET_EINVAL
#endif

/* If we have any of these library functions, we can reliably determine is a
 * locale is a UTF-8 one or not.  And if we aren't using locales at all, we act
 * as if everything is the C locale, so the answer there is always "No, it
 * isn't UTF-8"; this too is reliably accurate */
#if   defined(HAS_SOME_LANGINFO) || defined(HAS_MBTOWC)                 \
   || defined(HAS_MBRTOWC) || ! defined(USE_LOCALE)
#  define HAS_RELIABLE_UTF8NESS_DETERMINATION
#endif

/* This is a starting guess as to when this is true.  It definititely isn't
 * true on *BSD where positional LC_ALL notation is used.  Likely this will end
 * up being defined in hints files. */
#ifdef PERL_LC_ALL_USES_NAME_VALUE_PAIRS
#  define NEWLOCALE_HANDLES_DISPARATE_LC_ALL
#endif
#ifdef USE_LOCALE

/* Not all categories need be set to the same locale.  This macro determines if
 * 'name' which represents LC_ALL is uniform or disparate.  There are two
 * situations: 1) the platform uses unordered name=value pairs; 2) the platform
 * uses ordered positional values, with a separator string between them */
#  ifdef PERL_LC_ALL_SEPARATOR   /* positional */
#    define is_disparate_LC_ALL(name)  cBOOL(instr(name, PERL_LC_ALL_SEPARATOR))
#  else     /* name=value */

    /* In the, hopefully never occurring, event that the platform doesn't use
     * either mechanism for disparate LC_ALL's, assume the name=value pairs
     * form, rather than taking the extreme step of refusing to compile.  Many
     * programs won't have disparate locales, so will generally work */
#    define PERL_LC_ALL_SEPARATOR  ";"
#    define is_disparate_LC_ALL(name)  cBOOL(   strchr(name, ';')   \
                                             && strchr(name, '='))
#  endif

PERL_STATIC_INLINE const char *
S_mortalized_pv_copy(pTHX_ const char * const pv)
{
    PERL_ARGS_ASSERT_MORTALIZED_PV_COPY;

    /* Copies the input pv, and arranges for it to be freed at an unspecified
     * later time. */

    if (pv == NULL) {
        return NULL;
    }

    const char * copy = savepv(pv);
    SAVEFREEPV(copy);
    return copy;
}

#endif

/* Returns the Unix errno portion; ignoring any others.  This is a macro here
 * instead of putting it into perl.h, because unclear to khw what should be
 * done generally. */
#define GET_ERRNO   saved_errno

/* Default values come from the C locale */
#define C_codeset "ANSI_X3.4-1968" /* Only in some Configurations, and usually
                                      a single instance, so is a #define */
static const char C_decimal_point[] = ".";

#if (defined(USE_LOCALE_NUMERIC) && ! defined(TS_W32_BROKEN_LOCALECONV))    \
 || ! (   defined(USE_LOCALE_NUMERIC)                                       \
       && (defined(HAS_SOME_LANGINFO) || defined(HAS_LOCALECONV)))
static const char C_thousands_sep[] = "";
#endif

/* Is the C string input 'name' "C" or "POSIX"?  If so, and 'name' is the
 * return of setlocale(), then this is extremely likely to be the C or POSIX
 * locale.  However, the output of setlocale() is documented to be opaque, but
 * the odds are extremely small that it would return these two strings for some
 * other locale.  Note that VMS includes many non-ASCII characters in these two
 * locales as controls and punctuation (below are hex bytes):
 *   cntrl:  84-97 9B-9F
 *   punct:  A1-A3 A5 A7-AB B0-B3 B5-B7 B9-BD BF-CF D1-DD DF-EF F1-FD
 * Oddly, none there are listed as alphas, though some represent alphabetics
 * http://www.nntp.perl.org/group/perl.perl5.porters/2013/02/msg198753.html */
#define isNAME_C_OR_POSIX(name)                                              \
                             (   (name) != NULL                              \
                              && (( *(name) == 'C' && (*(name + 1)) == '\0') \
                                   || strEQ((name), "POSIX")))

#if defined(HAS_NL_LANGINFO_L) || defined(HAS_NL_LANGINFO)
#  define HAS_SOME_LANGINFO
#endif

#define my_langinfo_c(item, category, locale, retbufp, retbuf_sizep, utf8ness) \
            my_langinfo_i(item, category##_INDEX_, locale, retbufp,            \
                                                      retbuf_sizep,  utf8ness)
#ifdef USE_LOCALE
#  ifdef DEBUGGING
#    define setlocale_debug_string_i(index, locale, result)                 \
            my_setlocale_debug_string_i(index, locale, result, __LINE__)
#    define setlocale_debug_string_c(category, locale, result)              \
                setlocale_debug_string_i(category##_INDEX_, locale, result)
#    define setlocale_debug_string_r(category, locale, result)              \
             setlocale_debug_string_i(get_category_index(category),         \
                                      locale, result)
#  endif

#  define toggle_locale_i(index, locale)                                    \
                 S_toggle_locale_i(aTHX_ index, locale, __LINE__)
#  define toggle_locale_c(cat, locale)  toggle_locale_i(cat##_INDEX_, locale)
#  define restore_toggled_locale_i(index, locale)                           \
                 S_restore_toggled_locale_i(aTHX_ index, locale, __LINE__)
#  define restore_toggled_locale_c(cat, locale)                             \
                             restore_toggled_locale_i(cat##_INDEX_, locale)

/* On systems without LC_ALL, pretending it exists anyway simplifies things.
 * Choose a value for it that is very unlikely to clash with any actual
 * category */
#  define FAKE_LC_ALL  PERL_INT_MIN

/* Below are parallel arrays for locale information indexed by our mapping of
 * category numbers into small non-negative indexes.  locale_table.h contains
 * an entry like this for each individual category used on this system:
 *      PERL_LOCALE_TABLE_ENTRY(LC_CTYPE, S_new_ctype)
 *
 * Each array redefines PERL_LOCALE_TABLE_ENTRY to generate the information
 * needed for that array, and #includes locale_table.h to get the valid
 * categories.
 *
 * An entry for the conglomerate category LC_ALL is added here, immediately
 * following the individual categories.  (The treatment for it varies, so can't
 * be in locale_table.h.)
 *
 * Following this, each array ends with an entry for illegal categories.  All
 * category numbers unknown to perl get mapped to this entry.  This is likely
 * to be a parameter error from the calling program; but it could be that this
 * platform has a category we don't know about, in which case it needs to be
 * added, using the paradigm of one of the existing categories. */

/* The first array is the locale categories perl uses on this system, used to
 * map our index back to the system's category number. */
STATIC const int categories[] = {

#  undef PERL_LOCALE_TABLE_ENTRY
#  define PERL_LOCALE_TABLE_ENTRY(name, call_back)  name,
#  include "locale_table.h"

#  ifdef LC_ALL
    LC_ALL,
#  else
    FAKE_LC_ALL,
#  endif

   (FAKE_LC_ALL + 1)    /* Entry for unknown category; this number is unlikely
                           to clash with a real category */
};

/* The second array is the category names. */
STATIC const char * const category_names[] = {

#  undef PERL_LOCALE_TABLE_ENTRY
#  define PERL_LOCALE_TABLE_ENTRY(name, call_back)  # name,
#  include "locale_table.h"

#  ifdef LC_ALL
#    define LC_ALL_STRING  "LC_ALL"
#  else
#    define LC_ALL_STRING  "If you see this, it is a bug in perl;"      \
                           " please report it via perlbug"
#  endif

    LC_ALL_STRING,

#  define LC_UNKNOWN_STRING  "Locale category unknown to Perl; if you see"  \
                             " this, it is a bug in perl; please report it" \
                             " via perlbug"
    LC_UNKNOWN_STRING
};

STATIC const Size_t category_name_lengths[] = {

#  undef PERL_LOCALE_TABLE_ENTRY
#  define PERL_LOCALE_TABLE_ENTRY(name, call_back)  STRLENs(# name),
#  include "locale_table.h"

    STRLENs(LC_ALL_STRING),
    STRLENs(LC_UNKNOWN_STRING)
};

/* Each entry includes space for the '=' and ';' */
#  undef PERL_LOCALE_TABLE_ENTRY
#  define PERL_LOCALE_TABLE_ENTRY(name, call_back)  + STRLENs(# name) + 2

STATIC const Size_t lc_all_boiler_plate_length = 1  /* space for trailing NUL */
#  include "locale_table.h"
;

/* A few categories require additional setup when they are changed.  This table
 * points to the functions that do that setup */
STATIC void (*update_functions[]) (pTHX_ const char *, bool force) = {

#  undef PERL_LOCALE_TABLE_ENTRY
#  define PERL_LOCALE_TABLE_ENTRY(index, call_back)  call_back,
#  include "locale_table.h"

    S_new_LC_ALL,
    NULL,   /* No update for unknown category */
};

#  if defined(USE_POSIX_2008_LOCALE)

STATIC const int category_masks[] = {

#    undef PERL_LOCALE_TABLE_ENTRY
#    define PERL_LOCALE_TABLE_ENTRY(name, call_back)  name ## _MASK,
#    include "locale_table.h"

    LC_ALL_MASK,    /* Will rightly refuse to compile unless this is defined */
    0               /* Empty mask for unknown category */
};

#  endif
#  if ! defined(PERL_LC_ALL_USES_NAME_VALUE_PAIRS)

/* On platforms that use positional notation for expressing LC_ALL, this maps
 * the position of each category to our corresponding internal index for it.
 * This is initialized at run time if needed */
STATIC
unsigned int
map_LC_ALL_position_to_index[LC_ALL_INDEX_] = { PERL_UINT_MAX };

#  endif
#endif
#if defined(USE_LOCALE) || defined(DEBUGGING)

STATIC const char *
S_get_displayable_string(pTHX_
                         const char * const s,
                         const char * const e,
                         const bool is_utf8)
{
    PERL_ARGS_ASSERT_GET_DISPLAYABLE_STRING;

    if (e <= s) {
        return "";
    }

    const char * t = s;
    bool prev_was_printable = TRUE;
    bool first_time = TRUE;
    char * ret;

    /* Worst case scenario: All are non-printable so have a blank between each.
     * If UTF-8, all are the largest possible code point; otherwise all are a
     * single byte.  '(2 + 1)'  is from each byte takes 2 characters to
     * display, and a blank (or NUL for the final one) after it */
    const Size_t size = (e - s) * (2 + 1) * ((is_utf8) ? UVSIZE : 1);
    Newxz(ret, size, char);
    SAVEFREEPV(ret);

    while (t < e) {
        UV cp = (is_utf8)
                ?  utf8_to_uvchr_buf((U8 *) t, e, NULL)
                : * (U8 *) t;
        if (isPRINT(cp)) {
            if (! prev_was_printable) {
                my_strlcat(ret, " ", size);
            }

            /* Escape these to avoid any ambiguity */
            if (cp == ' ' || cp == '\\') {
                my_strlcat(ret, "\\", size);
            }
            my_strlcat(ret, Perl_form(aTHX_ "%c", (U8) cp), size);
            prev_was_printable = TRUE;
        }
        else {
            if (! first_time) {
                my_strlcat(ret, " ", size);
            }
            my_strlcat(ret, Perl_form(aTHX_ "%02" UVXf, cp), size);
            prev_was_printable = FALSE;
        }
        t += (is_utf8) ? UTF8SKIP(t) : 1;
        first_time = FALSE;
    }

    return ret;
}

#endif
#ifdef USE_LOCALE

# define get_category_index(cat) get_category_index_helper(cat, NULL, __LINE__)

STATIC unsigned int
S_get_category_index_helper(pTHX_ const int category, bool * succeeded,
                                  const line_t caller_line)
{
    PERL_ARGS_ASSERT_GET_CATEGORY_INDEX_HELPER;

    /* Given a category, return the equivalent internal index we generally use
     * instead, warn or panic if not found. */

    unsigned int i;

#  undef PERL_LOCALE_TABLE_ENTRY
#  define PERL_LOCALE_TABLE_ENTRY(name, call_back)                          \
                                    case name: i =  name ## _INDEX_; break;

    switch (category) {

#  include "locale_table.h"
#  ifdef LC_ALL
      case LC_ALL: i =  LC_ALL_INDEX_; break;
#  endif

      default: goto unknown_locale;
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "index of category %d (%s) is %d;"
                           " called from %" LINE_Tf "\n",
                           category, category_names[i], i, caller_line));

    if (succeeded) {
        *succeeded = true;
    }

    return i;

  unknown_locale:

    if (succeeded) {
        *succeeded = false;
        return 0;   /* Arbitrary */
    }

    locale_panic_via_(Perl_form(aTHX_ "Unknown locale category %d", category),
                      __FILE__, caller_line);
    NOT_REACHED; /* NOTREACHED */
}

#endif /* ifdef USE_LOCALE */

void
Perl_force_locale_unlock(pTHX)
{
    /* Remove any locale mutex, in preperation for an inglorious termination,
     * typically a  panic */

#if defined(USE_LOCALE_THREADS)

    /* If recursively locked, clear all at once */
    if (PL_locale_mutex_depth > 1) {
        PL_locale_mutex_depth = 1;
    }

    if (PL_locale_mutex_depth > 0) {
        LOCALE_UNLOCK_;
    }

#endif

}

#ifdef USE_POSIX_2008_LOCALE

STATIC locale_t
S_use_curlocale_scratch(pTHX)
{
    /* This function is used to hide from the caller the case where the current
     * locale_t object in POSIX 2008 is the global one, which is illegal in
     * many of the P2008 API calls.  This checks for that and, if necessary
     * creates a proper P2008 object.  Any prior object is deleted, as is any
     * remaining object during global destruction. */

    locale_t cur = uselocale((locale_t) 0);

    if (cur != LC_GLOBAL_LOCALE) {
        return cur;
    }

    if (PL_scratch_locale_obj) {
        freelocale(PL_scratch_locale_obj);
    }

    PL_scratch_locale_obj = duplocale(LC_GLOBAL_LOCALE);
    return PL_scratch_locale_obj;
}

#endif

void
Perl_locale_panic(const char * msg,
                  const line_t immediate_caller_line,
                  const char * const higher_caller_file,
                  const line_t higher_caller_line)
{
    PERL_ARGS_ASSERT_LOCALE_PANIC;
    dTHX;
    dSAVE_ERRNO;

    force_locale_unlock();

#ifdef USE_C_BACKTRACE
    dump_c_backtrace(Perl_debug_log, 20, 1);
#endif

    const char * called_by = "";
    if (   strNE(__FILE__, higher_caller_file)
        || immediate_caller_line != higher_caller_line)
    {
        called_by = Perl_form(aTHX_ "\nCalled by %s: %" LINE_Tf "\n",
                                    higher_caller_file, higher_caller_line);
    }

    RESTORE_ERRNO;

    const char * errno_text;

#ifdef HAS_EXTENDED_OS_ERRNO

    const int extended_errnum = get_extended_os_errno();
    if (errno != extended_errnum) {
        errno_text = Perl_form(aTHX_ "; errno=%d, $^E=%d",
                                     errno, extended_errnum);
    }
    else

#endif

    {
        errno_text = Perl_form(aTHX_ "; errno=%d", errno);
    }

    /* diag_listed_as: panic: %s */
    Perl_croak(aTHX_ "%s: %" LINE_Tf ": panic: %s%s%s\n",
                     __FILE__, immediate_caller_line,
                     msg, errno_text, called_by);
}

/* Macros to report and croak on an unexpected failure to set the locale.  The
 * via version has more stack trace information */
#define setlocale_failure_panic_i(i, cur, fail, line, higher_line)          \
    setlocale_failure_panic_via_i(i, cur, fail, __LINE__, line,             \
                                  __FILE__, higher_line)

#define setlocale_failure_panic_c(cat, cur, fail, line, higher_line)        \
   setlocale_failure_panic_i(cat##_INDEX_, cur, fail, line, higher_line)

#if defined(LC_ALL) && defined(USE_LOCALE)

STATIC parse_LC_ALL_string_return
S_parse_LC_ALL_string(pTHX_ const char * string,
                            const char ** output,
                            bool always_use_full_array,
                            const bool panic_on_error,
                            const line_t caller_line)
{
    /* This function parses the value of the input 'string' which is expected
     * to be the representation of an LC_ALL locale, and splits the result into
     * the values for the individual component categories, returning those in
     * the 'output' array.  Each array value will be a savepv() copy that is
     * the responsibility of the caller to make sure gets freed
     *
     * The locale for each category is independent of the other categories.
     * Often, they are all the same, but certainly not always.  Perl, in fact,
     * usually keeps LC_NUMERIC in the C locale, regardless of the underlying
     * locale.  LC_ALL has to be able to represent the case of when not all
     * categories have the same locale.  Platforms have differing ways of
     * representing this.  Internally, this file uses the 'name=value;'
     * representation found on some platforms, so this function always looks
     * for and parses that.  Other platforms use a positional notation.  On
     * those platforms, this function also parses that form.  It examines the
     * input to see which form is being parsed.
     *
     * Often, all categories will have the same locale.  This is special cased
     * if 'always_use_full_array' is false on input:
     *      1) If the input 'string' is a single value, this function doesn't
     *         store anything into 'output', and returns 'no_array'
     *      2) Some platforms will return multiple occurrences of the same
     *         value rather than coalescing them down to a single one.  HP-UX
     *         is such a one.  This function will do that collapsing for you,
     *         returning 'only_element_0' and saving the single value in
     *         output[0], which the caller will need to arrange to be freed.
     *         The rest of output[] is undefined, and does not need to be
     *         freed.
     *
     * Otherwise, the input 'string' may not be valid.  This function looks
     * mainly for syntactic errors, and if found, returns 'invalid'.  'output'
     * will not be filled in in that case, but the input state of it isn't
     * necessarily preserved.  Turning on -DL debugging will give details as to
     * the error.  If 'panic_on_error' is 'true', the function panics instead
     * of returning on error, with a message giving the details.
     *
     * Otherwise, output[] will be filled with the individual locale names for
     * all categories on the system, 'full_array' will be returned, and the
     * caller needs to arrange for each to be freed.  This means that either at
     * least one category differed from the others, or 'always_use_full_array' was
     * true on input.
     */

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "Entering parse_LC_ALL_string; called from %"    \
                           LINE_Tf "\nnew='%s'\n", caller_line, string));

#  ifdef PERL_LC_ALL_USES_NAME_VALUE_PAIRS

    const char separator[] = ";";
    const Size_t separator_len = 1;
    const bool single_component = (strchr(string, ';') == NULL);

#  else

    /* It's possible (but quite unlikely) that the separator string is an '='
     * or a ';'.  Requiring both to be present for using the 'name=value;' form
     * properly handles those possibilities */
    const bool name_value = strchr(string, '=') && strchr(string, ';');
    const char * separator;
    Size_t separator_len;
    bool single_component;
    if (name_value) {
        separator = ";";
        separator_len = 1;
        single_component = false;   /* Since has both [;=], must be multi */
    }
    else {
        separator = PERL_LC_ALL_SEPARATOR;
        separator_len = STRLENs(PERL_LC_ALL_SEPARATOR);
        single_component = instr(string, separator) == NULL;
    }

    Size_t component_number = 0;    /* Position in the parsing loop below */

#  endif

    if (single_component) {
        if (! always_use_full_array) {
            return no_array;
        }

        for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
            output[i] = savepv(string);
        }

        return full_array;
    }

    /* Here the input is multiple components.  Parse through them.  (It is
     * possible that these components are all the same, so we check, and if so,
     * return just the 0th component (unless 'always_use_full_array' is true)
     *
     * This enum notes the possible errors findable in parsing */
    enum {
            incomplete,
            no_equals,
            unknown_category,
            contains_LC_ALL_element
    } error;

    /* Keep track of the categories we have encountered so far */
    bool seen[LC_ALL_INDEX_] = { false };

    Size_t index;           /* Our internal index for the current category */
    const char * s = string;
    const char * e = s + strlen(string);
    const char * category_end = NULL;
    const char * saved_first = NULL;

    /* Parse the input locale string */
    while (s < e) {

        /* 'separator' has been set up to delimit the components */
        const char * next_sep = instr(s, separator);
        if (! next_sep) {   /* At the end of the input */
            next_sep = e;
        }

#  ifndef PERL_LC_ALL_USES_NAME_VALUE_PAIRS

        if (! name_value) {
            /* Get the index of the category in this position */
            index = map_LC_ALL_position_to_index[component_number++];
        }
        else

#  endif

        {   /* Get the category part when each component is the
             * 'category=locale' form */

            category_end = strchr(s, '=');

            /* The '=' terminates the category name.  If no '=', is improper
             * form */
            if (! category_end) {
                error = no_equals;
                goto failure;
            }

            /* Find our internal index of the category name; uses a linear
             * search.  (XXX This could be avoided by various means, but the
             * maximum likely search is 6 items, and khw doesn't think the
             * added complexity would save very much at all.) */
            const unsigned int name_len = (unsigned int) (category_end - s);
            for (index = 0; index < C_ARRAY_LENGTH(category_names); index++) {
                if (   name_len == category_name_lengths[index]
                    && memEQ(s, category_names[index], name_len))
                {
                    goto found_category;
                }
            }

            /* Here, the category is not in our list. */
            error = unknown_category;
            goto failure;

          found_category:   /* The system knows about this category. */

            if (index == LC_ALL_INDEX_) {
                error = contains_LC_ALL_element;
                goto failure;
            }

            /* The locale name starts just beyond the '=' */
            s = category_end + 1;

            /* Linux (and maybe others) doesn't treat a duplicate category in
             * the string as an error.  Instead it uses the final occurrence as
             * the intended value.  So if this is a duplicate, free the former
             * value before setting the new one */
            if (seen[index]) {
                Safefree(output[index]);
            }
            else {
                seen[index] = true;
            }
        }

        /* Here, 'index' contains our internal index number for the current
         * category, and 's' points to the beginning of the locale name for
         * that category. */
        output[index] = savepvn(s, next_sep - s);

        if (! always_use_full_array) {
            if (! saved_first) {
                saved_first = output[index];
            }
            else {
                if (strNE(saved_first, output[index])) {
                    always_use_full_array = true;
                }
            }
        }

        /* Next time start from the new position */
        s = next_sep + separator_len;
    }

    /* Finished looping through all the categories
     *
     * Check if the input was incomplete. */

#  ifndef PERL_LC_ALL_USES_NAME_VALUE_PAIRS

    if (! name_value) {     /* Positional notation */
        if (component_number != LC_ALL_INDEX_) {
            error = incomplete;
            goto failure;
        }
    }
    else

#  endif

    {   /* Here is the name=value notation */
        for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
            if (! seen[i]) {
                error = incomplete;
                goto failure;
            }
        }
    }

    /* In the loop above, we changed 'always_use_full_array' to true iff not all
     * categories have the same locale.  Hence, if it is still 'false', all of
     * them are the same. */
    if (always_use_full_array) {
        return full_array;
    }

    /* Free the dangling ones */
    for (unsigned int i = 1; i < LC_ALL_INDEX_; i++) {
        Safefree(output[i]);
        output[i] = NULL;
    }

    return only_element_0;

  failure:

    /* Don't leave memory dangling that we allocated before the failure */
    for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
        if (seen[i]) {
            Safefree(output[i]);
            output[i] = NULL;
        }
    }

    const char * msg;
    const char * display_start = s;
    const char * display_end = e;

    switch (error) {
        case incomplete:
            msg = "doesn't list every locale category";
            display_start = string;
            break;
        case no_equals:
            msg = "needs an '=' to split name=value";
            break;
        case unknown_category:
            msg = "is an unknown category";
            display_end = (category_end && category_end > display_start)
                          ? category_end
                          : e;
            break;
        case contains_LC_ALL_element:
            msg = "has LC_ALL, which is illegal here";
            break;
    }

    msg = Perl_form(aTHX_ "'%.*s' %s\n",
                          (int) (display_end - display_start),
                          display_start, msg);

    DEBUG_L(PerlIO_printf(Perl_debug_log, "%s", msg));

    if (panic_on_error) {
        locale_panic_via_(msg, __FILE__, caller_line);
    }

    return invalid;
}

#endif

/*==========================================================================
 * Here starts the code that gives a uniform interface to its callers, hiding
 * the differences between platforms.
 *
 * posix_setlocale() presents a consistent POSIX-compliant interface to
 * setlocale().   Windows requres a customized base-level setlocale().  Any
 * necessary mutex locking needs to be done at a higher level.  The
 * returns may be overwritten by the next call to the macro. */
#ifdef WIN32
#  define posix_setlocale(cat, locale) win32_setlocale(cat, locale)
#else
#  define posix_setlocale(cat, locale) ((const char *) setlocale(cat, locale))
#endif

/* End of posix layer
 *==========================================================================
 *
 * The next layer up is to catch vagaries and bugs in the libc setlocale return
 * value.  The return is not guaranteed to be stable.
 *
 * Any necessary mutex locking needs to be done at a higher level.
 *
 * On most platforms this layer is empty, expanding to just the layer
 * below.   To enable it, call Configure with either or both:
 * -Accflags=-DHAS_LF_IN_SETLOCALE_RETURN
 *                  to indicate that extraneous \n characters can be returned
 *                  by setlocale()
 * -Accflags=-DHAS_BROKEN_SETLOCALE_QUERY_LC_ALL
 *                  to indicate that setlocale(LC_ALL, NULL) cannot be relied
 *                  on
 */

#define STDIZED_SETLOCALE_LOCK    POSIX_SETLOCALE_LOCK
#define STDIZED_SETLOCALE_UNLOCK  POSIX_SETLOCALE_UNLOCK
#if ! defined(USE_LOCALE)                                                   \
 || ! (   defined(HAS_LF_IN_SETLOCALE_RETURN)                               \
       || defined(HAS_BROKEN_SETLOCALE_QUERY_LC_ALL))
#  define stdized_setlocale(cat, locale)  posix_setlocale(cat, locale)
#  define stdize_locale(cat, locale)  (locale)
#else
#  define stdized_setlocale(cat, locale)                                    \
        S_stdize_locale(aTHX_ cat, posix_setlocale(cat, locale), __LINE__)

STATIC const char *
S_stdize_locale(pTHX_ const int category,
                      const char *input_locale,
                      const line_t caller_line)
{
    /* The return value of setlocale() is opaque, but is required to be usable
     * as input to a future setlocale() to create the same state.
     * Unfortunately not all systems are compliant.  This function brings those
     * outliers into conformance.  It is based on what problems have arisen in
     * the field.
     *
     * This has similar constraints as the posix layer.  You need to lock
     * around it until its return is safely copied or no longer needed. (The
     * return may point to a global static buffer or may be mortalized.)
     *
     * The current things this corrects are:
     * 1) A new-line.  This function chops any \n characters
     * 2) A broken 'setlocale(LC_ALL, foo)'  This constructs a proper returned
     *                 string from the constituent categories
     *
     * If no changes were made, the input is returned as-is */

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                          "Entering stdize_locale(%d, '%s');"
                          " called from %" LINE_Tf "\n",
                          category, input_locale, caller_line));

    if (input_locale == NULL) {
        SET_EINVAL;
        return NULL;
    }

    char * retval = (char *) input_locale;

#  if defined(LC_ALL) && defined(HAS_BROKEN_SETLOCALE_QUERY_LC_ALL)

        /* If setlocale(LC_ALL, NULL) is broken, compute what the system
         * actually thinks it should be from its individual components */
    if (category == LC_ALL) {
        retval = (char *) calculate_LC_ALL_string(
                                     NULL,  /* query each individ locale */
                                     EXTERNAL_FORMAT_FOR_SET,
                                     caller_line);
    }

#  endif
#  ifdef HAS_NL_IN_SETLOCALE_RETURN

    char * first_bad = NULL;

#    ifndef LC_ALL

    PERL_UNUSED_ARG(category);
    PERL_UNUSED_ARG(caller_line);

#      define INPUT_LOCALE  retval
#      define MARK_CHANGED
#    else

    char * individ_locales[LC_ALL_INDEX_] = { NULL };
    bool made_changes = false;
    Size_t upper;
    if (category != LC_ALL) {
        individ_locales[0] = retval;
        upper = 0;
    }
    else {

        /* And parse the locale string, splitting into its individual
         * components. */
        switch (parse_LC_ALL_string(retval,
                                    (const char **) &individ_locales,
                                    false,    /* Return only [0] if suffices */
                                    false,    /* Don't panic on error */
                                    caller_line))
        {
          case invalid:
            SET_EINVAL;
            return NULL;

          case full_array: /* Loop below through all the component categories.
                            */
            upper = LC_ALL_INDEX_ - 1;
            break;

          case no_array:
            /* All categories here are set to the same locale, and the parse
             * didn't fill in any of 'individ_locales'.  Set the 0th element to
             * that locale. */
            individ_locales[0] = retval;
            /* FALLTHROUGH */

          case only_element_0: /* Element 0 is the only element we need to look
                                  at */
            upper = 0;
            break;
        }
    }

    for (unsigned int i = 0; i <= upper; i++)

#      define INPUT_LOCALE  individ_locales[i]
#      define MARK_CHANGED  made_changes = true;
#    endif    /* Has LC_ALL */

    {
        first_bad = (char *) strchr(INPUT_LOCALE, '\n');

        /* Most likely, there isn't a problem with the input */
        if (UNLIKELY(first_bad)) {

            /* This element will need to be adjusted.  Create a modifiable
             * copy. */
            MARK_CHANGED
            retval = savepv(INPUT_LOCALE);
            SAVEFREEPV(retval);

            /* Translate the found position into terms of the copy */
            first_bad = retval + (first_bad - INPUT_LOCALE);

            /* Get rid of the \n and what follows.  (Originally, only a
             * trailing \n was stripped.  Unsure what to do if not trailing) */
            *((char *) first_bad) = '\0';
        }   /* End of needs adjusting */
    }   /* End of looking for problems */

#    ifdef LC_ALL

    /* If we had multiple elements, extra work is required */
    if (upper != 0) {

        /* If no changes were made to the input, 'retval' already contains it
         * */
        if (made_changes) {

            /* But if did make changes, need to calculate the new value */
            retval = (char *) calculate_LC_ALL_string(
                                            (const char **) &individ_locales,
                                            EXTERNAL_FORMAT_FOR_SET,
                                            caller_line);
        }

        /* And free the no-longer needed memory */
        for (unsigned int i = 0; i <= upper; i++) {
            Safefree(individ_locales[i]);
        }
    }

#    endif
#    undef INPUT_LOCALE
#    undef MARK_CHANGED
#  endif    /* HAS_NL_IN_SETLOCALE_RETURN */

    return (const char *) retval;
}

#endif  /* USE_LOCALE */

/* End of stdize_locale layer
 *
 * ==========================================================================
 *
 * The next many lines form several implementations of a layer above the
 * close-to-the-metal 'posix' and 'stdized' macros.  They are used to present a
 * uniform API to the rest of the code in this file in spite of the disparate
 * underlying implementations.  Which implementation gets compiled depends on
 * the platform capabilities (and some user choice) as determined by Configure.
 *
 * As more fully described in the introductory comments in this file, the
 * API of each implementation consists of three sets of macros.  Each set has
 * three variants with suffixes '_c', '_r', and '_i'.  In the list below '_X'
 * is to be replaced by any of these suffixes.
 *
 * 1) bool_setlocale_X  attempts to set the given category's locale to the
 *                      given value, returning if it worked or not.
 * 2) void_setlocale_X  is like the corresponding bool_setlocale, but used when
 *                      success is the only sane outcome, so failure causes it
 *                      to panic.
 * 3) querylocale_X     to see what the given category's locale is
 *
 * Each implementation below is separated by ==== lines, and includes bool,
 * void, and query macros.  The query macros are first, followed by any
 * functions needed to implement them.  Then come the bool, again followed by
 * any implementing functions  Then are the void macros.  Finally are any
 * helper functions.  The sets in each implementation are separated by ----
 * lines.
 *
 * The returned strings from all the querylocale...() forms in all
 * implementations are thread-safe, and the caller should not free them,
 * but each may be a mortalized copy.  If you need something stable across
 * calls, you need to savepv() the result yourself.
 *
 *===========================================================================*/

#if    (! defined(USE_LOCALE_THREADS) && ! defined(USE_POSIX_2008_LOCALE))    \
    || (  defined(WIN32) && defined(USE_THREAD_SAFE_LOCALE))

/* For non-threaded perls, the implementation just expands to the base-level
 * functions (except if we are Configured to nonetheless use the POSIX 2008
 * interface) This implementation is also used on threaded perls where
 * threading is invisible to us.  Currently this is only on later Windows
 * versions. */

#  define querylocale_r(cat)  mortalized_pv_copy(stdized_setlocale(cat, NULL))
#  define querylocale_c(cat)  querylocale_r(cat)
#  define querylocale_i(i)    querylocale_c(categories[i])

/*---------------------------------------------------------------------------*/

#  define bool_setlocale_r(cat, locale) cBOOL(posix_setlocale(cat, locale))
#  define bool_setlocale_i(i, locale)                                       \
                                   bool_setlocale_c(categories[i], locale)
#  define bool_setlocale_c(cat, locale)      bool_setlocale_r(cat, locale)

/*---------------------------------------------------------------------------*/

#  define void_setlocale_r_with_caller(cat, locale, file, line)             \
     STMT_START {                                                           \
        if (! bool_setlocale_r(cat, locale))                                \
            setlocale_failure_panic_via_i(get_category_index(cat),          \
                                          NULL, locale, __LINE__, 0,        \
                                          file, line);                      \
     } STMT_END

#  define void_setlocale_c_with_caller(cat, locale, file, line)             \
                    void_setlocale_r_with_caller(cat, locale, file, line)

#  define void_setlocale_i_with_caller(i, locale, file, line)               \
          void_setlocale_r_with_caller(categories[i], locale, file, line)

#  define void_setlocale_r(cat, locale)                                     \
            void_setlocale_r_with_caller(cat, locale, __FILE__, __LINE__)
#  define void_setlocale_c(cat, locale) void_setlocale_r(cat, locale)
#  define void_setlocale_i(i, locale)   void_setlocale_r(categories[i], locale)

/*===========================================================================*/

#elif   defined(USE_LOCALE_THREADS)                 \
   && ! defined(USE_THREAD_SAFE_LOCALE)

   /* Here, there are threads, and there is no support for thread-safe
    * operation.  This is a dangerous situation, which perl is documented as
    * not supporting, but it arises in practice.  We can do a modicum of
    * automatic mitigation by making sure there is a per-thread return from
    * setlocale(), and that a mutex protects it from races */

#  define querylocale_r(cat)                                                \
                      mortalized_pv_copy(less_dicey_setlocale_r(cat, NULL))
#  define querylocale_c(cat)  querylocale_r(cat)
#  define querylocale_i(i)    querylocale_r(categories[i])

STATIC const char *
S_less_dicey_setlocale_r(pTHX_ const int category, const char * locale)
{
    const char * retval;

    PERL_ARGS_ASSERT_LESS_DICEY_SETLOCALE_R;

    STDIZED_SETLOCALE_LOCK;

    retval = save_to_buffer(stdized_setlocale(category, locale),
                            &PL_less_dicey_locale_buf,
                            &PL_less_dicey_locale_bufsize);

    STDIZED_SETLOCALE_UNLOCK;

    return retval;
}

/*---------------------------------------------------------------------------*/

#  define bool_setlocale_r(cat, locale)                                     \
                               less_dicey_bool_setlocale_r(cat, locale)
#  define bool_setlocale_i(i, locale)                                       \
                                bool_setlocale_r(categories[i], locale)
#  define bool_setlocale_c(cat, locale) bool_setlocale_r(cat, locale)

STATIC bool
S_less_dicey_bool_setlocale_r(pTHX_ const int cat, const char * locale)
{
    bool retval;

    PERL_ARGS_ASSERT_LESS_DICEY_BOOL_SETLOCALE_R;

    /* Unlikely, but potentially possible that another thread could zap the
     * buffer from true to false or vice-versa, so need to lock here */
    POSIX_SETLOCALE_LOCK;
    retval = cBOOL(posix_setlocale(cat, locale));
    POSIX_SETLOCALE_UNLOCK;

    return retval;
}

/*---------------------------------------------------------------------------*/

#  define void_setlocale_r_with_caller(cat, locale, file, line)             \
     STMT_START {                                                           \
        if (! bool_setlocale_r(cat, locale))                                \
            setlocale_failure_panic_via_i(get_category_index(cat),          \
                                          NULL, locale, __LINE__, 0,        \
                                          file, line);                      \
     } STMT_END

#  define void_setlocale_c_with_caller(cat, locale, file, line)             \
                    void_setlocale_r_with_caller(cat, locale, file, line)

#  define void_setlocale_i_with_caller(i, locale, file, line)               \
          void_setlocale_r_with_caller(categories[i], locale, file, line)

#  define void_setlocale_r(cat, locale)                                     \
            void_setlocale_r_with_caller(cat, locale, __FILE__, __LINE__)
#  define void_setlocale_c(cat, locale) void_setlocale_r(cat, locale)
#  define void_setlocale_i(i, locale)   void_setlocale_r(categories[i], locale)

/*===========================================================================*/

#elif defined(USE_POSIX_2008_LOCALE)
#  ifndef LC_ALL
#    error This code assumes that LC_ALL is available on a system modern enough to have POSIX 2008
#  endif

/* Here, there is a completely different API to get thread-safe locales.  We
 * emulate the setlocale() API with our own function(s).  setlocale categories,
 * like LC_NUMERIC, are not valid here for the POSIX 2008 API.  Instead, there
 * are equivalents, like LC_NUMERIC_MASK, which we use instead, which we find
 * by table lookup. */

#  if defined(__GLIBC__) && defined(USE_LOCALE_MESSAGES)
            /* https://sourceware.org/bugzilla/show_bug.cgi?id=24936 */
#    define HAS_GLIBC_LC_MESSAGES_BUG
#    include <libintl.h>
#  endif

#  define querylocale_i(i)    querylocale_2008_i(i, __LINE__)
#  define querylocale_c(cat)  querylocale_i(cat##_INDEX_)
#  define querylocale_r(cat)  querylocale_i(get_category_index(cat))

STATIC const char *
S_querylocale_2008_i(pTHX_ const unsigned int index, const line_t caller_line)
{
    PERL_ARGS_ASSERT_QUERYLOCALE_2008_I;
    assert(index <= LC_ALL_INDEX_);

    /* This function returns the name of the locale category given by the input
     * 'index' into our parallel tables of them.
     *
     * POSIX 2008, for some sick reason, chose not to provide a method to find
     * the category name of a locale, disregarding a basic linguistic tenet
     * that for any object, people will create a name for it.  (The next
     * version of the POSIX standard is proposed to fix this.)  Some vendors
     * have created a querylocale() function to do this in the meantime.  On
     * systems without querylocale(), we have to keep track of what the locale
     * has been set to, so that we can return its name so as to emulate
     * setlocale().  There are potential problems with this:
     *
     *  1)  We don't know what calling newlocale() with the locale argument ""
     *      actually does.  It gets its values from the program's environment.
     *      find_locale_from_environment() is used to work around this.  But it
     *      isn't fool-proof.  See the comments for that function for details.
     *  2)  It's possible for C code in some library to change the locale
     *      without us knowing it, and thus our records become wrong;
     *      querylocale() would catch this.  But as of September 2017, there
     *      are no occurrences in CPAN of uselocale().  Some libraries do use
     *      setlocale(), but that changes the global locale, and threads using
     *      per-thread locales will just ignore those changes.
     *  3)  Many systems have multiple names for the same locale.  Generally,
     *      there is an underlying base name, with aliases that evaluate to it.
     *      On some systems, if you set the locale to an alias, and then
     *      retrieve the name, you get the alias as expected; but on others you
     *      get the base name, not the alias you used.  And sometimes the
     *      charade is incomplete.  See
     *      https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=269375.
     *
     *      The code is structured so that the returned locale name when the
     *      locale is changed is whatever the result of querylocale() on the
     *      new locale is.  This effectively gives the result the system
     *      expects.  Without querylocale, the name returned is always the
     *      input name.  Theoretically this could cause problems, but khw knows
     *      of none so far, but mentions it here in case you are trying to
     *      debug something.  (This could be worked around by messing with the
     *      global locale temporarily, using setlocale() to get the base name;
     *      but that could cause a race.  The comments for
     *      find_locale_from_environment() give details on the potential race.)
     */

    const locale_t cur_obj = uselocale((locale_t) 0);
    const char * retval;

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "querylocale_2008_i(%s) on %p;"
                                           " called from %" LINE_Tf "\n",
                                           category_names[index], cur_obj,
                                           caller_line));

    if (UNLIKELY(cur_obj == LC_GLOBAL_LOCALE)) {

        /* Even on platforms that have querylocale(), it is unclear if they
         * work in the global locale, and we have the means to get the correct
         * answer anyway.  khw is unsure this situation even comes up these
         * days, hence the branch prediction */
        POSIX_SETLOCALE_LOCK;
        retval = mortalized_pv_copy(posix_setlocale(categories[index], NULL));
        POSIX_SETLOCALE_UNLOCK;
    }

    /* Here we have handled the case of the the current locale being the global
     * one.  Below is the 'else' case of that.  There are two different
     * implementations, depending on USE_PL_CURLOCALES */

#  ifdef USE_PL_CURLOCALES

    else {

        /* PL_curlocales[] is kept up-to-date for all categories except LC_ALL,
         * which may have been invalidated by setting it to NULL, and if so,
         * should now be calculated.  (The called function updates that
         * element.) */
        if (index == LC_ALL_INDEX_ && PL_curlocales[LC_ALL_INDEX_] == NULL) {
            calculate_LC_ALL_string((const char **) &PL_curlocales,
                                    INTERNAL_FORMAT, caller_line);
        }

        if (cur_obj == PL_C_locale_obj) {

            /* If the current locale object is the C object, then the answer is
             * "C" or POSIX, regardless of the category.  Handling this
             * reasonably likely case specially shortcuts extra effort, and
             * hides some bugs from us in OS's that alias other locales to C,
             * but do so incompletely.  If our records say it is POSIX, use
             * that; otherwise use C.  See
             * https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=269375 */
            retval = mortalized_pv_copy((strEQ(PL_curlocales[index], "POSIX"))
                                        ? "POSIX"
                                        : "C");
        }
        else {
            retval = mortalized_pv_copy(PL_curlocales[index]);
        }
    }

#  else

    /* Below is the implementation of the 'else' clause which handles the case
     * of the current locale not being the global one on platforms where
     * USE_PL_CURLOCALES is NOT in effect.  That means the system must have
     * some form of querylocale.  But these have varying characteristics, so
     * first create some #defines to make the actual 'else' clause uniform.
     *
     * First, glibc has a function that implements querylocale(), but is called
     * something else, and takes the category number; the others take the mask.
     * */
#    if defined(USE_QUERYLOCALE) && (   defined(_NL_LOCALE_NAME)            \
                                     && defined(HAS_NL_LANGINFO_L))
#      define my_querylocale(index, cur_obj)                                \
                nl_langinfo_l(_NL_LOCALE_NAME(categories[index]), cur_obj)

       /* Experience so far shows it is thread-safe, as well as glibc's
        * nl_langinfo_l(), so unless overridden, mark it so */
#      ifdef NO_THREAD_SAFE_QUERYLOCALE
#        undef HAS_THREAD_SAFE_QUERYLOCALE
#      else
#        define HAS_THREAD_SAFE_QUERYLOCALE
#      endif
#    else   /* below, ! glibc */

       /* Otherwise, use the system's querylocale(). */
#      define my_querylocale(index, cur_obj)                                \
                               querylocale(category_masks[index], cur_obj)

       /* There is no standard for this function, and khw has never seen
        * anything beyond minimal vendor documentation, lacking important
        * details.  Experience has shown that some implementations have race
        * condiions, and their returns may not be thread safe.  It would be
        * unreliable to test for complete thread safety in Configure.  What we
        * do instead is to assume that it is thread-safe, unless overriden by,
        * say, a hints file specifying
        * -Accflags='-DNO_THREAD_SAFE_QUERYLOCALE */
#      ifdef NO_THREAD_SAFE_QUERYLOCALE
#        undef HAS_THREAD_SAFE_QUERYLOCALE
#      else
#        define HAS_THREAD_SAFE_QUERYLOCALE
#      endif
#    endif

     /* Here, we have set up enough information to know if this querylocale()
      * is thread-safe, or needs to use a mutex */
#    ifdef HAS_THREAD_SAFE_QUERYLOCALE
#      define QUERYLOCALE_LOCK
#      define QUERYLOCALE_UNLOCK
#    else
#      define QUERYLOCALE_LOCK    gwLOCALE_LOCK
#      define QUERYLOCALE_UNLOCK  gwLOCALE_UNLOCK
#    endif

    /* Finally, everything is ready, so here is the 'else' clause to implement
     * the case of the current locale not being the global one on systems that
     * have some form of querylocale().  (POSIX will presumably eventually
     * publish their next version in their pipeline, which will define a
     * precisely specified querylocale equivalent, and there can be a new
     * #ifdef to use it without having to guess at its characteristics) */

    else {
        /* We don't keep records when there is querylocale(), so as to avoid the
         * pitfalls mentioned at the beginning of this function.
         *
         * That means LC_ALL has to be calculated from all its constituent
         * categories each time, since the querylocale() forms on many (if not
         * all) platforms only work on individual categories */
        if (index == LC_ALL_INDEX_) {
            retval = calculate_LC_ALL_string(NULL, INTERNAL_FORMAT,
                                             caller_line);
        }
        else {

            QUERYLOCALE_LOCK;
            retval = savepv(my_querylocale(index, cur_obj));
            QUERYLOCALE_UNLOCK;

            /* querylocale() may conflate the C locale with something that
             * isn't exactly the same.  See for example
             * https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=269375
             * We know that if the locale object is the C one, we
             * are in the C locale, which may go by the name POSIX, as both, by
             * definition, are equivalent.  But we consider any other name
             * spurious, so override with "C".  As in the PL_CURLOCALES case
             * above, this hides those glitches, for the most part, from the
             * rest of our code.  (The code is ordered this way so that if the
             * system distinugishes "C" from "POSIX", we do too.) */
            if (cur_obj == PL_C_locale_obj && ! isNAME_C_OR_POSIX(retval)) {
                Safefree(retval);
                retval = savepv("C");
            }

            SAVEFREEPV(retval);
        }
    }

#    undef QUERYLOCALE_LOCK
#    undef QUERYLOCALE_UNLOCK
#  endif

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "querylocale_2008_i(%s) returning '%s'\n",
                           category_names[index], retval));
    assert(strNE(retval, ""));
    return retval;
}

/*---------------------------------------------------------------------------*/

#  define bool_setlocale_i(i, locale)                                       \
                              bool_setlocale_2008_i(i, locale, __LINE__)
#  define bool_setlocale_c(cat, locale)                                     \
                                  bool_setlocale_i(cat##_INDEX_, locale)
#  define bool_setlocale_r(cat, locale)                                     \
                 bool_setlocale_i(get_category_index(cat, NULL), locale)

/* If this doesn't exist on this platform, make it a no-op (to save #ifdefs) */
#  ifndef update_PL_curlocales_i
#    define update_PL_curlocales_i(index, new_locale, caller_line)
#  endif

STATIC bool
S_bool_setlocale_2008_i(pTHX_

        /* Our internal index of the 'category' setlocale is called with */
        const unsigned int index,
        const char * new_locale,    /* The locale to set the category to */
        const line_t caller_line    /* Called from this line number */
       )
{
    PERL_ARGS_ASSERT_BOOL_SETLOCALE_2008_I;
    assert(index <= LC_ALL_INDEX_);

    /* This function effectively performs a setlocale() on just the current
     * thread; thus it is thread-safe.  It does this by using the POSIX 2008
     * locale functions to emulate the behavior of setlocale().  Similar to
     * regular setlocale(), the return from this function points to memory that
     * can be overwritten by other system calls, so needs to be copied
     * immediately if you need to retain it.  The difference here is that
     * system calls besides another setlocale() can overwrite it.
     *
     * By doing this, most locale-sensitive functions become thread-safe.  The
     * exceptions are mostly those that return a pointer to static memory.
     */

    int mask = category_masks[index];
    const locale_t entry_obj = uselocale((locale_t) 0);
    const char * locale_on_entry = querylocale_i(index);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "bool_setlocale_2008_i: input=%d (%s), mask=0x%x,"
                           " new locale=\"%s\", current locale=\"%s\","
                           " index=%d, entry object=%p;"
                           " called from %" LINE_Tf "\n",
                           categories[index], category_names[index], mask,
                           ((new_locale == NULL) ? "(nil)" : new_locale),
                           locale_on_entry, index, entry_obj, caller_line));

    /* Here, trying to change the locale, but it is a no-op if the new boss is
     * the same as the old boss.  Except this routine is called when converting
     * from the global locale, so in that case we will create a per-thread
     * locale below (with the current values).  It also seemed that newlocale()
     * could free up the basis locale memory if we called it with the new and
     * old being the same, but khw now thinks that this was due to some other
     * bug, since fixed, as there are other places where newlocale() gets
     * similarly called without problems. */
    if (   entry_obj != LC_GLOBAL_LOCALE
        && locale_on_entry
        && strEQ(new_locale, locale_on_entry))
    {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "bool_setlocale_2008_i: no-op to change to"
                               " what it already was\n"));
        return true;
    }

#  ifndef USE_QUERYLOCALE

    /* Without a querylocale() mechanism, we have to figure out ourselves what
     * happens with setting a locale to "" */

    if (strEQ(new_locale, "")) {
        new_locale = find_locale_from_environment(index);
        if (! new_locale) {
            SET_EINVAL;
            return false;
        }
    }

#  endif
#  ifdef NEWLOCALE_HANDLES_DISPARATE_LC_ALL

    const bool need_loop = false;

#  else

    bool need_loop = false;
    const char * new_locales[LC_ALL_INDEX_] = { NULL };

    /* If we're going to have to parse the LC_ALL string, might as well do it
     * now before we have made changes that we would have to back out of if the
     * parse fails */
    if (index == LC_ALL_INDEX_) {
        switch (parse_LC_ALL_string(new_locale,
                                    (const char **) &new_locales,
                                    false,    /* Return only [0] if suffices */
                                    false,    /* Don't panic on error */
                                    caller_line))
        {
          case invalid:
            SET_EINVAL;
            return false;

          case no_array:
            need_loop = false;
            break;

          case only_element_0:
            SAVEFREEPV(new_locales[0]);
            new_locale = new_locales[0];
            need_loop = false;
            break;

          case full_array:
            need_loop = true;
            break;
        }
    }

#  endif
#  ifdef HAS_GLIBC_LC_MESSAGES_BUG

    /* For this bug, if the LC_MESSAGES locale changes, we have to do an
     * expensive workaround.  Save the current value so we can later determine
     * if it changed. */
    const char * old_messages_locale = NULL;
    if (   (index == LC_MESSAGES_INDEX_ || index == LC_ALL_INDEX_)
        &&  LIKELY(PL_phase != PERL_PHASE_CONSTRUCT))
    {
        old_messages_locale = querylocale_c(LC_MESSAGES);
    }

#  endif

    assert(PL_C_locale_obj);

    /* Now ready to switch to the input 'new_locale' */

    /* Switching locales generally entails freeing the current one's space (at
     * the C library's discretion), hence we can't be using that locale at the
     * time of the switch (this wasn't obvious to khw from the man pages).  So
     * switch to a known locale object that we don't otherwise mess with. */
    if (! uselocale(PL_C_locale_obj)) {

        /* Not being able to change to the C locale is severe; don't keep
         * going.  */
        setlocale_failure_panic_i(index, locale_on_entry, "C",
                                  __LINE__, caller_line);
        NOT_REACHED; /* NOTREACHED */
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "bool_setlocale_2008_i: now using C"
                           " object=%p\n", PL_C_locale_obj));

    /* These two objects are special:
     *  LC_GLOBAL_LOCALE    because it is undefined behavior to call
     *                      newlocale() with it as a parameter.
     *  PL_C_locale_obj     because newlocale() generally destroys its locale
     *                      object parameter when it succeeds; and we don't
     *                      want that happening to this immutable object.
     * Copies will be made for them to use instead if we get so far as to call
     * newlocale(). */
    bool entry_obj_is_special = (   entry_obj == LC_GLOBAL_LOCALE
                                 || entry_obj == PL_C_locale_obj);
    locale_t new_obj;

    /* PL_C_locale_obj is LC_ALL set to the C locale.  If this call is to
     * switch to LC_ALL => C, simply use that object.  But in fact, we already
     * have switched to it just above, in preparation for the general case.
     * Since we're already there, no need to do further switching. */
    if (mask == LC_ALL_MASK && isNAME_C_OR_POSIX(new_locale)) {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "bool_setlocale_2008_i: will stay in C"
                               " object\n"));
        new_obj = PL_C_locale_obj;

        /* 'entry_obj' is now dangling, of no further use to anyone (unless it
         * is one of the special ones).  Free it to avoid a leak */
        if (! entry_obj_is_special) {
            freelocale(entry_obj);
        }

        update_PL_curlocales_i(index, new_locale, caller_line);
    }
    else {  /* Here is the general case, not to LC_ALL => C */

        /* The newlocale() call(s) below take a basis object to build upon to
         * create the changed locale, trashing it iff successful.
         *
         * For the objects that are not to be modified by this function, we
         * create a duplicate that gets trashed instead.
         *
         * Also if we will have to loop doing multiple newlocale()s, there is a
         * chance we will succeed for the first few, and then fail, having to
         * back out.  We need to duplicate 'entry_obj' in this case as well, so
         * it remains valid as something to back out to. */
        locale_t basis_obj = entry_obj;

        if (entry_obj_is_special || need_loop) {
            basis_obj = duplocale(basis_obj);
            if (! basis_obj) {
                locale_panic_via_("duplocale failed", __FILE__, caller_line);
                NOT_REACHED; /* NOTREACHED */
            }

            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                   "bool_setlocale_2008_i created %p by"
                                   " duping the input\n", basis_obj));
        }

#  define DEBUG_NEW_OBJECT_CREATED(category, locale, new, old, caller_line) \
      DEBUG_Lv(PerlIO_printf(Perl_debug_log,                                \
                             "bool_setlocale_2008_i(%s, %s): created %p"    \
                             " while freeing %p; called from %" LINE_Tf     \
                             " via %" LINE_Tf "\n",                         \
                             category, locale, new, old,                    \
                             caller_line, __LINE__))
#  define DEBUG_NEW_OBJECT_FAILED(category, locale, basis_obj)              \
      DEBUG_L(PerlIO_printf(Perl_debug_log,                                 \
                            "bool_setlocale_2008_i: creating new object"    \
                            " for (%s '%s') from %p failed; called from %"  \
                            LINE_Tf " via %" LINE_Tf "\n",                  \
                            category, locale, basis_obj,                    \
                            caller_line, __LINE__));

        /* Ready to create a new locale by modification of the existing one.
         *
         * NOTE: This code may incorrectly show up as a leak under the address
         * sanitizer. We do not free this object under normal teardown, however
         * you can set PERL_DESTRUCT_LEVEL=2 to cause it to be freed.
         */

#  ifdef NEWLOCALE_HANDLES_DISPARATE_LC_ALL

        /* Some platforms have a newlocale() that can handle disparate LC_ALL
         * input, so on these a single call to newlocale() always works */
#  else

        /* If a single call to newlocale() will do */
        if (! need_loop)

#  endif

        {
            new_obj = newlocale(mask, new_locale, basis_obj);
            if (! new_obj) {
                DEBUG_NEW_OBJECT_FAILED(category_names[index], new_locale,
                                        basis_obj);

                /* Since the call failed, it didn't trash 'basis_obj', which is
                 * a dup for these objects, and hence would leak if we don't
                 * free it.  XXX However, something is seriously wrong if we
                 * can't switch to C or the global locale, so maybe should
                 * panic instead */
                if (entry_obj_is_special) {
                    freelocale(basis_obj);
                }

                goto must_restore_state;
            }

            DEBUG_NEW_OBJECT_CREATED(category_names[index], new_locale,
                                     new_obj, basis_obj, caller_line);

            update_PL_curlocales_i(index, new_locale, caller_line);
        }

#  ifndef NEWLOCALE_HANDLES_DISPARATE_LC_ALL

        else {  /* Need multiple newlocale() calls */

            /* Loop through the individual categories, setting the locale of
             * each to the corresponding name previously populated into
             * newlocales[].  Each iteration builds on the previous one, adding
             * its category to what's already been calculated, and taking as a
             * basis for what's been calculated 'basis_obj', which is updated
             * each iteration to be the result of the previous one.  Upon
             * success, newlocale() trashes the 'basis_obj' parameter to it.
             * If any iteration fails, we immediately give up, restore the
             * locale to what it was at the time this function was called
             * (saved in 'entry_obj'), and return failure. */

            /* Loop, using the previous iteration's result as the basis for the
             * next one.  (The first time we effectively use the locale in
             * force upon entry to this function.) */
            for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
                new_obj = newlocale(category_masks[i],
                                    new_locales[i],
                                    basis_obj);
                if (new_obj) {
                    DEBUG_NEW_OBJECT_CREATED(category_names[i],
                                             new_locales[i],
                                             new_obj, basis_obj,
                                             caller_line);
                    basis_obj = new_obj;
                    continue;
                }

                /* Failed.  Likely this is because the proposed new locale
                 * isn't valid on this system. */

                DEBUG_NEW_OBJECT_FAILED(category_names[i],
                                        new_locales[i],
                                        basis_obj);

                /* newlocale() didn't trash this, since the function call
                 * failed */
                freelocale(basis_obj);

                for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
                    Safefree(new_locales[j]);
                }

                goto must_restore_state;
            }

            /* Success for all categories. */
            for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
                update_PL_curlocales_i(i, new_locales[i], caller_line);
                Safefree(new_locales[i]);
            }

            /* We dup'd entry_obj in case we had to fall back to it.  The
             * newlocale() above destroyed the dup when it first succeeded, but
             * entry_obj itself is left dangling, so free it */
            if (! entry_obj_is_special) {
                freelocale(entry_obj);
            }
        }

#  endif    /* End of newlocale can't handle disparate LC_ALL input */

    }

#  undef DEBUG_NEW_OBJECT_CREATED
#  undef DEBUG_NEW_OBJECT_FAILED

    /* Here, successfully created an object representing the desired locale;
     * now switch into it */
    if (! uselocale(new_obj)) {
        freelocale(new_obj);
        locale_panic_(Perl_form(aTHX_ "(called from %" LINE_Tf "):"
                                      " bool_setlocale_2008_i: switching"
                                      " into new locale failed",
                                      caller_line));
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "bool_setlocale_2008_i: now using %p\n", new_obj));

#  ifdef MULTIPLICITY   /* Unlikely, but POSIX 2008 functions could be
                           Configured to be used on unthreaded perls, in which
                           case this object doesn't exist */

    if (DEBUG_Lv_TEST) {
        if (PL_cur_locale_obj != new_obj) {
            PerlIO_printf(Perl_debug_log,
                          "bool_setlocale_2008_i: PL_cur_locale_obj"
                          " was %p, now is %p\n",
                          PL_cur_locale_obj, new_obj);
        }
    }

    /* Update the current object */
    PL_cur_locale_obj = new_obj;

#  endif
#  ifdef HAS_GLIBC_LC_MESSAGES_BUG

    /* Invalidate the glibc cache of loaded translations if the locale has
     * changed, see [perl #134264] and
     * https://sourceware.org/bugzilla/show_bug.cgi?id=24936 */
    if (old_messages_locale) {
        if (strNE(old_messages_locale, querylocale_c(LC_MESSAGES))) {
            textdomain(textdomain(NULL));
        }
    }

#  endif

    return true;

  must_restore_state:

    /* We earlier switched to the LC_ALL => C locale in anticipation of it
     * succeeding,  Now have to switch back to the state upon entry.  */
    if (! uselocale(entry_obj)) {
        setlocale_failure_panic_i(index, "switching back to",
                                  locale_on_entry, __LINE__, caller_line);
    }

    return false;
}

/*---------------------------------------------------------------------------*/

#  define void_setlocale_i_with_caller(i, locale, file, line)               \
     STMT_START {                                                           \
        if (! bool_setlocale_i(i, locale))                                  \
            setlocale_failure_panic_via_i(i, NULL, locale, __LINE__, 0,     \
                                          file, line);                      \
     } STMT_END

#  define void_setlocale_r_with_caller(cat, locale, file, line)             \
        void_setlocale_i_with_caller(get_category_index(cat, NULL), locale, \
                                     file, line)

#  define void_setlocale_c_with_caller(cat, locale, file, line)             \
            void_setlocale_i_with_caller(cat##_INDEX_, locale, file, line)

#  define void_setlocale_i(i, locale)                                       \
                void_setlocale_i_with_caller(i, locale, __FILE__, __LINE__)
#  define void_setlocale_c(cat, locale)                                     \
                                  void_setlocale_i(cat##_INDEX_, locale)
#  define void_setlocale_r(cat, locale)                                     \
                  void_setlocale_i(get_category_index(cat, NULL), locale)

/*---------------------------------------------------------------------------*/
/* helper functions for POSIX 2008 */

#  ifdef USE_PL_CURLOCALES

STATIC void
S_update_PL_curlocales_i(pTHX_
                         const unsigned int index,
                         const char * new_locale,
                         const line_t caller_line)
{
    /* Update PL_curlocales[], which is parallel to the other ones indexed by
     * our mapping of libc category number to our internal equivalents. */

    PERL_ARGS_ASSERT_UPDATE_PL_CURLOCALES_I;
    assert(index <= LC_ALL_INDEX_);

    if (index == LC_ALL_INDEX_) {

        /* For LC_ALL, we change all individual categories to correspond,
         * including the LC_ALL element */
        for (unsigned int i = 0; i <= LC_ALL_INDEX_; i++) {
            Safefree(PL_curlocales[i]);
            PL_curlocales[i] = NULL;
        }

        switch (parse_LC_ALL_string(new_locale,
                                    (const char **) &PL_curlocales,
                                    true,   /* Always fill array */
                                    true,   /* Panic if fails, as to get here
                                               it earlier had to have succeeded
                                               */
                                   caller_line))

        {
          case invalid:
          case no_array:
          case only_element_0:
            locale_panic_via_("Unexpected return from parse_LC_ALL_string",
                              __FILE__, caller_line);

          case full_array:
            /* parse_LC_ALL_string() has already filled PL_curlocales properly,
             * except for the LC_ALL element, which should be set to
             * 'new_locale'. */
            PL_curlocales[LC_ALL_INDEX_] = savepv(new_locale);
        }
    }
    else {  /* Not LC_ALL */

        /* Update the single category's record */
        Safefree(PL_curlocales[index]);
        PL_curlocales[index] = savepv(new_locale);

        /* Invalidate LC_ALL */
        Safefree(PL_curlocales[LC_ALL_INDEX_]);
        PL_curlocales[LC_ALL_INDEX_] = NULL;
    }
}

#  endif  /* Need PL_curlocales[] */

/*===========================================================================*/

#else
#  error Unexpected Configuration
#endif   /* End of the various implementations of the setlocale and
            querylocale macros used in the remainder of this program */

/* query_nominal_locale_i() is used when the caller needs the locale that an
 * external caller would be expecting, and not what we're secretly using
 * behind the scenes.  It deliberately doesn't handle LC_ALL; use
 * calculate_LC_ALL_string() for that. */
#ifdef USE_LOCALE_NUMERIC
#  define query_nominal_locale_i(i)                                         \
      (__ASSERT_(i != LC_ALL_INDEX_)                                        \
       ((i == LC_NUMERIC_INDEX_) ? PL_numeric_name : querylocale_i(i)))
#else
#  define query_nominal_locale_i(i)                                         \
      (__ASSERT_(i != LC_ALL_INDEX_) querylocale_i(i))
#endif

#if defined(USE_LOCALE)

/* This paradigm is needed in several places in the function below.  We have to
 * substitute the nominal locale for LC_NUMERIC when returning a value for
 * external consumption */
#  ifndef USE_LOCALE_NUMERIC
#    define ENTRY(i, array, format)  array[i]
#  else
#    define ENTRY(i, array, format)                         \
       (UNLIKELY(   format == EXTERNAL_FORMAT_FOR_QUERY     \
                 && i == LC_NUMERIC_INDEX_)                 \
        ? PL_numeric_name                                   \
        : array[i])
#  endif

STATIC
const char *
S_calculate_LC_ALL_string(pTHX_ const char ** category_locales_list,
                                const calc_LC_ALL_format format,
                                const line_t caller_line)
{
    PERL_ARGS_ASSERT_CALCULATE_LC_ALL_STRING;

    /* NOTE: On Configurations that have PL_curlocales[], this function has the
     * side effect of updating the LC_ALL_INDEX_ element with its result.
     *
     * This function returns a string that defines the locale(s) LC_ALL is set
     * to, in either:
     *  1)  Our internal format if 'format' is set to INTERNAL_FORMAT.
     *  2)  The external format returned by Perl_setlocale() if 'format' is set
     *      to EXTERNAL_FORMAT_FOR_QUERY or EXTERNAL_FORMAT_FOR_SET.
     *
     *      These two are distinguished by:
     *       a) EXTERNAL_FORMAT_FOR_SET returns the actual locale currently in
     *          effect.
     *       b) EXTERNAL_FORMAT_FOR_QUERY returns the nominal locale.
     *          Currently this can differ only from the actual locale in the
     *          LC_NUMERIC category when it is set to a locale whose radix is
     *          not a dot.  (The actual locale is kept as a dot to accommodate
     *          the large corpus of XS code that expects it to be that;
     *          switched to a non-dot temporarily during certain operations
     *          that require the actual radix.)
     *
     * In both 1) and 2), LC_ALL's values are passed to this function by
     * 'category_locales_list' which is either:
     *  1) a pointer to an array of strings with up-to-date values of all the
     *     individual categories; or
     *  2) NULL, to indicate to use querylocale_i() to get each individual
     *     value.
     *
     * This function returns a mortalized string containing the locale name(s)
     * of LC_ALL.
     *
     * querylocale(), on systems that have it, doesn't tend to work for LC_ALL.
     * So we have to construct the answer ourselves based on the passed in
     * data.
     *
     * If all individual categories are the same locale, we can just set LC_ALL
     * to that locale.  But if not, we have to create an aggregation of all the
     * categories on the system.  Platforms differ as to the syntax they use
     * for these non-uniform locales for LC_ALL.  Some, like glibc and Windows,
     * use an unordered series of name=value pairs, like
     *      LC_NUMERIC=C;LC_TIME=en_US.UTF-8;...
     * to specify LC_ALL; others, like *BSD, use a positional notation with a
     * delimitter, typically a single '/' character:
     *      C/en_UK.UTF-8/...
     *
     * When the external format is desired, this function returns whatever the
     * system expects.  The internal format is always name=value pairs.
     *
     * For systems that have categories we don't know about, the algorithm
     * below won't know about those missing categories, leading to potential
     * bugs for code that looks at them.  If there is an environment variable
     * that sets that category, we won't know to look for it, and so our use of
     * LANG or "C" improperly overrides it.  On the other hand, if we don't do
     * what is done here, and there is no environment variable, the category's
     * locale should be set to LANG or "C".  So there is no good solution.  khw
     * thinks the best is to make sure we have a complete list of possible
     * categories, adding new ones as they show up on obscure platforms.
     */

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "Entering calculate_LC_ALL_string(%s);"
                           " called from %" LINE_Tf "\n",
                           ((format == EXTERNAL_FORMAT_FOR_QUERY)
                            ? "EXTERNAL_FORMAT_FOR_QUERY"
                            : ((format == EXTERNAL_FORMAT_FOR_SET)
                               ? "EXTERNAL_FORMAT_FOR_SET"
                               : "INTERNAL_FORMAT")),
                           caller_line));

    /* If there was no input category list, construct a temporary one
     * ourselves. */
    const char * my_category_locales_list[LC_ALL_INDEX_];
    const char ** locales_list = category_locales_list;
    if (locales_list == NULL) {
        locales_list = my_category_locales_list;

        if (format == EXTERNAL_FORMAT_FOR_QUERY) {
            for (unsigned i = 0; i < LC_ALL_INDEX_; i++) {
                locales_list[i] = query_nominal_locale_i(i);
            }
        }
        else {
            for (unsigned i = 0; i < LC_ALL_INDEX_; i++) {
                locales_list[i] = querylocale_i(i);
            }
        }
    }

    /* While we are calculating LC_ALL, we see if every category's locale is
     * the same as every other's or not. */

    /* We assume they are all the same until proven different */
    bool disparate = false;

    /* Calculate the needed size for the string listing the individual locales.
     * Initialize with values known at compile time. */
    Size_t total_len;
    const char *separator;

#  ifdef PERL_LC_ALL_USES_NAME_VALUE_PAIRS  /* Positional formatted LC_ALL */
    PERL_UNUSED_ARG(format);
#  else

    if (format != INTERNAL_FORMAT) {

        /* Here, we will be using positional notation.  it includes n-1
         * separators */
        total_len = (  LOCALE_CATEGORIES_COUNT_ - 1)
                     * STRLENs(PERL_LC_ALL_SEPARATOR)
                  + 1;   /* And a trailing NUL */
        separator = PERL_LC_ALL_SEPARATOR;
    }
    else

#  endif

    {
        /* name=value output is always used in internal format, and when
         * positional isn't available on the platform. */
        total_len = lc_all_boiler_plate_length;
        separator = ";";
    }

    /* The total length then is just the sum of the above boiler-plate plus the
     * total strlen()s of the locale name of each individual category. */
    for (unsigned int i = 0;  i < LC_ALL_INDEX_; i++) {
        const char * entry = ENTRY(i, locales_list, format);

        total_len += strlen(entry);
        if (! disparate && strNE(entry, locales_list[0])) {
            disparate = true;
        }
    }

    /* Done iterating through all the categories. */
    const char * retval;

    /* If all categories have the same locale, we already know the answer */
    if (! disparate) {
            retval = savepv(locales_list[0]);
            SAVEFREEPV(retval);
    }
    else {  /* Here, not all categories have the same locale */
        char * writable_alias;

            Newx(writable_alias, total_len, char);
            SAVEFREEPV(writable_alias);

        writable_alias[0] = '\0';

        /* Loop through all the categories */
        for (unsigned j = 0; j < LC_ALL_INDEX_; j++) {

            /* Add a separator, except before the first one */
            if (j != 0) {
                my_strlcat(writable_alias, separator, total_len);
            }

            const char * entry;
            Size_t needed_len;
            unsigned int i = j;

#  ifndef PERL_LC_ALL_USES_NAME_VALUE_PAIRS

            if (UNLIKELY(format != INTERNAL_FORMAT)) {

                /* In positional notation 'j' means the position, and we have
                 * to convert to the index 'i' */
                i = map_LC_ALL_position_to_index[j];

                entry = ENTRY(i, locales_list, format);
                needed_len = my_strlcat(writable_alias, entry, total_len);
            }
            else

#  endif
            {
                /* Below, we are to use name=value notation, either because
                 * that's what the platform uses, or because this is the
                 * internal format, which uses that notation regardless of the
                 * external form */

                entry = ENTRY(i, locales_list, format);

                /* "name=locale;" */
                my_strlcat(writable_alias, category_names[i], total_len);
                my_strlcat(writable_alias, "=", total_len);
                needed_len = my_strlcat(writable_alias, entry, total_len);
            }

            if (LIKELY(needed_len <= total_len)) {
                continue;
            }

            /* If would have overflowed, panic */
            locale_panic_via_(Perl_form(aTHX_
                                        "Internal length calculation wrong.\n"
                                        "\"%s\" was not entirely added to"
                                        " \"%.*s\"; needed=%zu, had=%zu",
                                        entry, (int) total_len,
                                        writable_alias,
                                        needed_len, total_len),
                                __FILE__,
                                caller_line);
        } /* End of loop through the categories */

        retval = (const char *) writable_alias;

    } /* End of the categories' locales are displarate */

#  if defined(USE_PL_CURLOCALES) && defined(LC_ALL)

    if (format == INTERNAL_FORMAT) {

        /* PL_curlocales[LC_ALL_INDEX_] is updated as a side-effect of this
         * function for internal format. */
        Safefree(PL_curlocales[LC_ALL_INDEX_]);
        PL_curlocales[LC_ALL_INDEX_] = savepv(retval);
    }

#  endif

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "calculate_LC_ALL_string returning '%s'\n",
                           retval));
    return retval;
}

#  if defined(WIN32) || (     defined(USE_POSIX_2008_LOCALE)        \
                         && ! defined(USE_QUERYLOCALE))

STATIC const char *
S_find_locale_from_environment(pTHX_ const unsigned int index)
{
    /* NB: This function may actually change the locale on Windows.
     *
     * On Windows systems, the concept of the POSIX ordering of environment
     * variables is missing.  To increase portability of programs across
     * platforms, the POSIX ordering is emulated on Windows.
     *
     * And on POSIX 2008 systems without querylocale(), it is problematic
     * getting the results of the POSIX 2008 equivalent of
     *      setlocale(category,  "")
     * (which gets the locale from the environment).
     *
     * To ensure that we know exactly what those values are, we do the setting
     * ourselves, using the documented algorithm (assuming the documentation is
     * correct) rather than use "" as the locale.  This will lead to results
     * that differ from native behavior if the native behavior differs from the
     * standard documented value, but khw believes it is better to know what's
     * going on, even if different from native, than to just guess.
     *
     * Another option for the POSIX 2008 case would be, in a critical section,
     * to save the global locale's current value, and do a straight
     * setlocale(LC_ALL, "").  That would return our desired values, destroying
     * the global locale's, which we would then restore.  But that could cause
     * races with any other thread that is using the global locale and isn't
     * using the mutex.  And, the only reason someone would have done that is
     * because they are calling a library function, like in gtk, that calls
     * setlocale(), and which can't be changed to use the mutex.  That wouldn't
     * be a problem if this were to be done before any threads had switched,
     * say during perl construction time.  But this code would still be needed
     * for the general case.
     *
     * The Windows and POSIX 2008 differ in that the ultimate fallback is "C"
     * in POSIX, and is the system default locale in Windows.  To get that
     * system default value, we actually have to call setlocale() on Windows.
     */

    /* We rely on PerlEnv_getenv() returning a mortalized copy */
    const char * const lc_all = PerlEnv_getenv("LC_ALL");

    /* Use any "LC_ALL" environment variable, as it overrides everything
     * else. */
    if (lc_all && strNE(lc_all, "")) {
        return lc_all;
    }

    /* If setting an individual category, use its corresponding value found in
     * the environment, if any */
    if (index != LC_ALL_INDEX_) {
        const char * const new_value = PerlEnv_getenv(category_names[index]);

        if (new_value && strNE(new_value, "")) {
            return new_value;
        }

        /* If no corresponding environment variable, see if LANG exists.  If
         * so, use it. */
        const char * default_name = PerlEnv_getenv("LANG");
        if (default_name && strNE(default_name, "")) {
            return default_name;
        }

        /* If no LANG, use "C" on POSIX 2008, the system default on Windows */
#    ifndef WIN32
        return "C";
#    else
        return wrap_wsetlocale(categories[index], ".ACP");
#    endif

    }

    /* Here is LC_ALL, and no LC_ALL environment variable.  LANG is used as a
     * default, but overridden for individual categories that have
     * corresponding environment variables.  If no LANG exists, the default is
     * "C" on POSIX 2008, or the system default for the category on Windows. */
    const char * default_name = PerlEnv_getenv("LANG");

    /* Convert "" to NULL to save conditionals in the loop below */
    if (default_name != NULL && strEQ(default_name, "")) {
        default_name = NULL;
    }

    /* Loop through all the individual categories, setting each to any
     * corresponding environment variable; or to the default if none exists for
     * the category */
    const char * locale_names[LC_ALL_INDEX_];
    for (unsigned i = 0; i < LC_ALL_INDEX_; i++) {
        const char * const env_override = PerlEnv_getenv(category_names[i]);

        if (env_override && strNE(env_override, "")) {
            locale_names[i] = env_override;
        }
        else if (default_name) {
            locale_names[i] = default_name;
        }
        else {

#    ifndef WIN32
            locale_names[i] = "C";
#    else
            locale_names[i] = wrap_wsetlocale(categories[index], ".ACP");
#    endif

        }

        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                 "find_locale_from_environment i=%d, name=%s, locale=%s\n",
                 i, category_names[i], locale_names[i]));
    }

    return calculate_LC_ALL_string(locale_names, INTERNAL_FORMAT, __LINE__);
}

#  endif
#  if defined(DEBUGGING) || defined(USE_PERL_SWITCH_LOCALE_CONTEXT)

STATIC const char *
S_get_LC_ALL_display(pTHX)
{
    return calculate_LC_ALL_string(NULL, INTERNAL_FORMAT,
                                   __LINE__);
}

#  endif

STATIC void
S_setlocale_failure_panic_via_i(pTHX_
                                const unsigned int cat_index,
                                const char * current,
                                const char * failed,
                                const line_t proxy_caller_line,
                                const line_t immediate_caller_line,
                                const char * const higher_caller_file,
                                const line_t higher_caller_line)
{
    PERL_ARGS_ASSERT_SETLOCALE_FAILURE_PANIC_VIA_I;

    /* Called to panic when a setlocale form unexpectedly failed for the
     * category determined by 'cat_index', and the locale that was in effect
     * (and likely still is) is 'current'.  'current' may be NULL, which causes
     * this function to query what it is.
     *
     * The extra caller information is used for when a function acts as a
     * stand-in for another function, which a typical reader would more likely
     * think would be the caller
     *
     * If a line number is 0, its stack (sort-of) frame is omitted; same if
     * it's the same line number as the next higher caller. */

    const int cat = categories[cat_index];
    const char * name = category_names[cat_index];

    dSAVE_ERRNO;

    if (current == NULL) {
        current = querylocale_i(cat_index);
    }

    const char * proxy_text = "";
    if (proxy_caller_line != 0 && proxy_caller_line != immediate_caller_line)
    {
        proxy_text = Perl_form(aTHX_ "\nCalled via %s: %" LINE_Tf,
                                      __FILE__, proxy_caller_line);
    }
    if (   strNE(__FILE__, higher_caller_file)
        || (   immediate_caller_line != 0
            && immediate_caller_line != higher_caller_line))
    {
        proxy_text = Perl_form(aTHX_ "%s\nCalled via %s: %" LINE_Tf,
                                      proxy_text, __FILE__,
                                      immediate_caller_line);
    }

    /* 'false' in the get_displayable_string() calls makes it not think the
     * locale is UTF-8, so just dumps bytes.  Actually figuring it out can be
     * too complicated for a panic situation. */
    const char * msg = Perl_form(aTHX_
                            "Can't change locale for %s (%d) from '%s' to '%s'"
                            " %s",
                            name, cat,
                            get_displayable_string(current,
                                                   current + strlen(current),
                                                   false),
                            get_displayable_string(failed,
                                                   failed + strlen(failed),
                                                   false),
                            proxy_text);
    RESTORE_ERRNO;

    Perl_locale_panic(msg, __LINE__, higher_caller_file, higher_caller_line);
    NOT_REACHED; /* NOTREACHED */
}

/* Any of these will allow us to find the RADIX */
#  if defined(USE_LOCALE_NUMERIC) && (   defined(HAS_SOME_LANGINFO)         \
                                      || defined(HAS_LOCALECONV)            \
                                      || defined(HAS_SNPRINTF))
#    define CAN_CALCULATE_RADIX
#  endif
#  ifdef USE_LOCALE_NUMERIC

STATIC void
S_new_numeric(pTHX_ const char *newnum, bool force)
{
    PERL_ARGS_ASSERT_NEW_NUMERIC;

    /* Called after each libc setlocale() or uselocale() call affecting
     * LC_NUMERIC, to tell core Perl this and that 'newnum' is the name of the
     * new locale, and we are switched into it.  It installs this locale as the
     * current underlying default, and then switches to the C locale, if
     * necessary, so that the code that has traditionally expected the radix
     * character to be a dot may continue to do so.
     *
     * The default locale and the C locale can be toggled between by use of the
     * set_numeric_underlying() and set_numeric_standard() functions, which
     * should probably not be called directly, but only via macros like
     * SET_NUMERIC_STANDARD() in perl.h.
     *
     * The toggling is necessary mainly so that a non-dot radix decimal point
     * character can be input and output, while allowing internal calculations
     * to use a dot.
     *
     * This sets several interpreter-level variables:
     * PL_numeric_name  The underlying locale's name: a copy of 'newnum'
     * PL_numeric_underlying   A boolean indicating if the toggled state is
     *                  such that the current locale is the program's
     *                  underlying locale
     * PL_numeric_standard   An int indicating if the toggled state is such
     *                  that the current locale is the C locale or
     *                  indistinguishable from the C locale.  If non-zero, it
     *                  is in C; if > 1, it means it may not be toggled away
     *                  from C.
     * PL_numeric_underlying_is_standard   A bool kept by this function
     *                  indicating that the underlying locale and the standard
     *                  C locale are indistinguishable for the purposes of
     *                  LC_NUMERIC.  This happens when both of the above two
     *                  variables are true at the same time.  (Toggling is a
     *                  no-op under these circumstances.)  This variable is
     *                  used to avoid having to recalculate.
     * PL_numeric_radix_sv   Contains the string that code should use for the
     *                  decimal point.  It is set to either a dot or the
     *                  program's underlying locale's radix character string,
     *                  depending on the situation.
     * PL_underlying_radix_sv   Contains the program's underlying locale's
     *                  radix character string.  This is copied into
     *                  PL_numeric_radix_sv when the situation warrants.  It
     *                  exists to avoid having to recalculate it when toggling.
     * PL_underlying_numeric_obj = (only on POSIX 2008 platforms)  An object
     *                  with everything set up properly so as to avoid work on
     *                  such platforms.
     */

    DEBUG_L( PerlIO_printf(Perl_debug_log,
                           "Called new_numeric with %s, PL_numeric_name=%s\n",
                           newnum, PL_numeric_name));

    /* If not forcing this procedure, and there isn't actually a change from
     * our records, do nothing.  (Our records can be wrong when sync'ing to the
     * locale set up by an external library, hence the 'force' parameter) */
    if (! force && strEQ(PL_numeric_name, newnum)) {
        return;
    }

    Safefree(PL_numeric_name);
    PL_numeric_name = savepv(newnum);

    /* Handle the trivial case.  Since this is called at process
     * initialization, be aware that this bit can't rely on much being
     * available. */
    if (isNAME_C_OR_POSIX(PL_numeric_name)) {
        PL_numeric_standard = TRUE;
        PL_numeric_underlying_is_standard = TRUE;
        PL_numeric_underlying = TRUE;
        sv_setpv(PL_numeric_radix_sv, C_decimal_point);
        SvUTF8_off(PL_numeric_radix_sv);
        sv_setpv(PL_underlying_radix_sv, C_decimal_point);
        SvUTF8_off(PL_underlying_radix_sv);
        return;
    }

    /* We are in the underlying locale until changed at the end of this
     * function */
    PL_numeric_underlying = TRUE;

#    ifdef USE_POSIX_2008_LOCALE

    /* We keep a special object for easy switching to.
     *
     * NOTE: This code may incorrectly show up as a leak under the address
     * sanitizer. We do not free this object under normal teardown, however
     * you can set PERL_DESTRUCT_LEVEL=2 to cause it to be freed.
     */
    PL_underlying_numeric_obj = newlocale(LC_NUMERIC_MASK,
                                          PL_numeric_name,
                                          PL_underlying_numeric_obj);

#      endif

    const char * radix = NULL;
    utf8ness_t utf8ness = UTF8NESS_IMMATERIAL;

    /* Find and save this locale's radix character. */
    my_langinfo_c(RADIXCHAR, LC_NUMERIC, PL_numeric_name,
                  &radix, NULL, &utf8ness);
    sv_setpv(PL_underlying_radix_sv, radix);

    if (utf8ness == UTF8NESS_YES) {
        SvUTF8_on(PL_underlying_radix_sv);
    }
    else {
        SvUTF8_off(PL_underlying_radix_sv);
    }

    DEBUG_L(PerlIO_printf(Perl_debug_log,
                          "Locale radix is '%s', ?UTF-8=%d\n",
                          SvPVX(PL_underlying_radix_sv),
                          cBOOL(SvUTF8(PL_underlying_radix_sv))));

    /* This locale is indistinguishable from C (for numeric purposes) if both
     * the radix character and the thousands separator are the same as C's.
     * Start with the radix. */
    PL_numeric_underlying_is_standard = strEQ(C_decimal_point, radix);
    Safefree(radix);

#    ifndef TS_W32_BROKEN_LOCALECONV

    /* If the radix isn't the same as C's, we know it is distinguishable from
     * C; otherwise check the thousands separator too.  Only if both are the
     * same as C's is the locale indistinguishable from C.
     *
     * But on earlier Windows versions, there is a potential race.  This code
     * knows that localeconv() (elsewhere in this file) will be used to extract
     * the needed value, and localeconv() was buggy for quite a while, and that
     * code in this file hence uses a workaround.  And that workaround may have
     * an (unlikely) race.  Gathering the radix uses a different workaround on
     * Windows that doesn't involve a race.  It might be possible to do the
     * same for this (patches welcome).
     *
     * Until then khw doesn't think it's worth even the small risk of a race to
     * get this value, which doesn't appear to be used in any of the Microsoft
     * library routines anyway. */

    const char * scratch_buffer = NULL;
    if (PL_numeric_underlying_is_standard) {
        PL_numeric_underlying_is_standard = strEQ(C_thousands_sep,
                                             my_langinfo_c(THOUSEP, LC_NUMERIC,
                                                           PL_numeric_name,
                                                           &scratch_buffer,
                                                           NULL, NULL));
    }
    Safefree(scratch_buffer);

#    endif

    PL_numeric_standard = PL_numeric_underlying_is_standard;

    /* Keep LC_NUMERIC so that it has the C locale radix and thousands
     * separator.  This is for XS modules, so they don't have to worry about
     * the radix being a non-dot.  (Core operations that need the underlying
     * locale change to it temporarily). */
    if (! PL_numeric_standard) {
        set_numeric_standard(__FILE__, __LINE__);
    }
}

#  endif

void
Perl_set_numeric_standard(pTHX_ const char * const file, const line_t line)
{
    PERL_ARGS_ASSERT_SET_NUMERIC_STANDARD;
    PERL_UNUSED_ARG(file);      /* Some Configurations ignore these */
    PERL_UNUSED_ARG(line);

#  ifdef USE_LOCALE_NUMERIC

    /* Unconditionally toggle the LC_NUMERIC locale to the C locale
     *
     * Most code should use the macro SET_NUMERIC_STANDARD() in perl.h
     * instead of calling this directly.  The macro avoids calling this routine
     * if toggling isn't necessary according to our records (which could be
     * wrong if some XS code has changed the locale behind our back) */

    DEBUG_L(PerlIO_printf(Perl_debug_log, "Setting LC_NUMERIC locale to"
                                          " standard C; called from %s: %"
                                          LINE_Tf "\n", file, line));

    void_setlocale_c_with_caller(LC_NUMERIC, "C", file, line);
    PL_numeric_standard = TRUE;
    sv_setpv(PL_numeric_radix_sv, C_decimal_point);
    SvUTF8_off(PL_numeric_radix_sv);

    PL_numeric_underlying = PL_numeric_underlying_is_standard;

#  endif /* USE_LOCALE_NUMERIC */

}

void
Perl_set_numeric_underlying(pTHX_ const char * const file, const line_t line)
{
    PERL_ARGS_ASSERT_SET_NUMERIC_UNDERLYING;
    PERL_UNUSED_ARG(file);      /* Some Configurations ignore these */
    PERL_UNUSED_ARG(line);

#  ifdef USE_LOCALE_NUMERIC

    /* Unconditionally toggle the LC_NUMERIC locale to the current underlying
     * default.
     *
     * Most code should use the macro SET_NUMERIC_UNDERLYING() in perl.h
     * instead of calling this directly.  The macro avoids calling this routine
     * if toggling isn't necessary according to our records (which could be
     * wrong if some XS code has changed the locale behind our back) */

    DEBUG_L(PerlIO_printf(Perl_debug_log, "Setting LC_NUMERIC locale to %s;"
                                          " called from %s: %" LINE_Tf "\n",
                                          PL_numeric_name, file, line));
    /* Maybe not in init? assert(PL_locale_mutex_depth > 0);*/

    void_setlocale_c_with_caller(LC_NUMERIC, PL_numeric_name, file, line);
    PL_numeric_underlying = TRUE;
    sv_setsv_nomg(PL_numeric_radix_sv, PL_underlying_radix_sv);

    PL_numeric_standard = PL_numeric_underlying_is_standard;

#  endif /* USE_LOCALE_NUMERIC */

}

#  ifdef USE_LOCALE_CTYPE

STATIC void
S_new_ctype(pTHX_ const char *newctype, bool force)
{
    PERL_ARGS_ASSERT_NEW_CTYPE;
    PERL_UNUSED_ARG(force);

    /* Called after each libc setlocale() call affecting LC_CTYPE, to tell
     * core Perl this and that 'newctype' is the name of the new locale.
     *
     * This function sets up the folding arrays for all 256 bytes, assuming
     * that tofold() is tolc() since fold case is not a concept in POSIX,
     */

    DEBUG_L(PerlIO_printf(Perl_debug_log, "Entering new_ctype(%s)\n",
                                          newctype));

    /* No change means no-op */
    if (strEQ(PL_ctype_name, newctype)) {
        return;
    }

    /* We will replace any bad locale warning with
     *  1)  nothing if the new one is ok; or
     *  2)  a new warning for the bad new locale */
    if (PL_warn_locale) {
        SvREFCNT_dec_NN(PL_warn_locale);
        PL_warn_locale = NULL;
    }

    /* Clear cache */
    Safefree(PL_ctype_name);
    PL_ctype_name = "";

    PL_in_utf8_turkic_locale = FALSE;

    /* For the C locale, just use the standard folds, and we know there are no
     * glitches possible, so return early.  Since this is called at process
     * initialization, be aware that this bit can't rely on much being
     * available. */
    if (isNAME_C_OR_POSIX(newctype)) {
        Copy(PL_fold, PL_fold_locale, 256, U8);
        PL_ctype_name = savepv(newctype);
        PL_in_utf8_CTYPE_locale = FALSE;
        return;
    }

    /* The cache being cleared signals the called function to compute a new
     * value */
    PL_in_utf8_CTYPE_locale = is_locale_utf8(newctype);

    PL_ctype_name = savepv(newctype);
    bool maybe_utf8_turkic = FALSE;

    /* Don't check for problems if we are suppressing the warnings */
    bool check_for_problems = ckWARN_d(WARN_LOCALE) || UNLIKELY(DEBUG_L_TEST);

    if (PL_in_utf8_CTYPE_locale) {

        /* A UTF-8 locale gets standard rules.  But note that code still has to
         * handle this specially because of the three problematic code points
         * */
        Copy(PL_fold_latin1, PL_fold_locale, 256, U8);

        /* UTF-8 locales can have special handling for 'I' and 'i' if they are
         * Turkic.  Make sure these two are the only anomalies.  (We don't
         * require towupper and towlower because they aren't in C89.) */

#    if defined(HAS_TOWUPPER) && defined (HAS_TOWLOWER)

        if (towupper('i') == 0x130 && towlower('I') == 0x131)

#    else

        if (toU8_UPPER_LC('i') == 'i' && toU8_LOWER_LC('I') == 'I')

#    endif

        {
            /* This is how we determine it really is Turkic */
            check_for_problems = TRUE;
            maybe_utf8_turkic = TRUE;
        }
    }
    else {  /* Not a canned locale we know the values for.  Compute them */

#    ifdef DEBUGGING

        bool has_non_ascii_fold = FALSE;
        bool found_unexpected = FALSE;

        /* Under -DLv, see if there are any folds outside the ASCII range.
         * This factoid is used below */
        if (DEBUG_Lv_TEST) {
            for (unsigned i = 128; i < 256; i++) {
                int j = LATIN1_TO_NATIVE(i);
                if (toU8_LOWER_LC(j) != j || toU8_UPPER_LC(j) != j) {
                    has_non_ascii_fold = TRUE;
                    break;
                }
            }
        }

#    endif

        for (unsigned i = 0; i < 256; i++) {
            if (isU8_UPPER_LC(i))
                PL_fold_locale[i] = (U8) toU8_LOWER_LC(i);
            else if (isU8_LOWER_LC(i))
                PL_fold_locale[i] = (U8) toU8_UPPER_LC(i);
            else
                PL_fold_locale[i] = (U8) i;

#    ifdef DEBUGGING

            /* Most locales these days are supersets of ASCII.  When debugging
             * with -DLv, it is helpful to know what the exceptions to that are
             * in this locale */
            if (DEBUG_Lv_TEST) {
                bool unexpected = FALSE;

                if (isUPPER_L1(i)) {
                    if (isUPPER_A(i)) {
                        if (PL_fold_locale[i] != toLOWER_A(i)) {
                            unexpected = TRUE;
                        }
                    }
                    else if (has_non_ascii_fold) {
                        if (PL_fold_locale[i] != toLOWER_L1(i)) {
                            unexpected = TRUE;
                        }
                    }
                    else if (PL_fold_locale[i] != i) {
                        unexpected = TRUE;
                    }
                }
                else if (   isLOWER_L1(i)
                         && i != LATIN_SMALL_LETTER_SHARP_S
                         && i != MICRO_SIGN)
                {
                    if (isLOWER_A(i)) {
                        if (PL_fold_locale[i] != toUPPER_A(i)) {
                            unexpected = TRUE;
                        }
                    }
                    else if (has_non_ascii_fold) {
                        if (PL_fold_locale[i] != toUPPER_LATIN1_MOD(i)) {
                            unexpected = TRUE;
                        }
                    }
                    else if (PL_fold_locale[i] != i) {
                        unexpected = TRUE;
                    }
                }
                else if (PL_fold_locale[i] != i) {
                    unexpected = TRUE;
                }

                if (unexpected) {
                    found_unexpected = TRUE;
                    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                           "For %s, fold of %02x is %02x\n",
                                           newctype, i, PL_fold_locale[i]));
                }
            }
        }

        if (found_unexpected) {
            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "All bytes not mentioned above either fold to"
                               " themselves or are the expected ASCII or"
                               " Latin1 ones\n"));
        }
        else {
            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                   "No nonstandard folds were found\n"));
#    endif

        }
    }

#    ifdef MB_CUR_MAX

    /* We only handle single-byte locales (outside of UTF-8 ones); so if this
     * locale requires more than one byte, there are going to be BIG problems.
     * */

    if (MB_CUR_MAX > 1 && ! PL_in_utf8_CTYPE_locale

            /* Some platforms return MB_CUR_MAX > 1 for even the "C" locale.
             * Just assume that the implementation for them (plus for POSIX) is
             * correct and the > 1 value is spurious.  (Since these are
             * specially handled to never be considered UTF-8 locales, as long
             * as this is the only problem, everything should work fine */
        && ! isNAME_C_OR_POSIX(newctype))
    {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "Unsupported, MB_CUR_MAX=%d\n", (int) MB_CUR_MAX));

        Perl_ck_warner_d(aTHX_ packWARN(WARN_LOCALE),
                         "Locale '%s' is unsupported, and may crash the"
                         " interpreter",
                         newctype);
    }

#    endif

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "check_for_problems=%d\n",
                                           check_for_problems));

    /* We don't populate the other lists if a UTF-8 locale, but do check that
     * everything works as expected, unless checking turned off */
    if (check_for_problems) {
        /* Assume enough space for every character being bad.  4 spaces each
         * for the 94 printable characters that are output like "'x' "; and 5
         * spaces each for "'\\' ", "'\t' ", and "'\n' "; plus a terminating
         * NUL */
        char bad_chars_list[ (94 * 4) + (3 * 5) + 1 ] = { '\0' };
        unsigned int bad_count = 0;         /* Count of bad characters */

        for (unsigned i = 0; i < 256; i++) {

            /* If checking for locale problems, see if the native ASCII-range
             * printables plus \n and \t are in their expected categories in
             * the new locale.  If not, this could mean big trouble, upending
             * Perl's and most programs' assumptions, like having a
             * metacharacter with special meaning become a \w.  Fortunately,
             * it's very rare to find locales that aren't supersets of ASCII
             * nowadays.  It isn't a problem for most controls to be changed
             * into something else; we check only \n and \t, though perhaps \r
             * could be an issue as well. */
            if (isGRAPH_A(i) || isBLANK_A(i) || i == '\n') {
                bool is_bad = FALSE;
                char name[4] = { '\0' };

                /* Convert the name into a string */
                if (isGRAPH_A(i)) {
                    name[0] = i;
                    name[1] = '\0';
                }
                else if (i == '\n') {
                    my_strlcpy(name, "\\n", sizeof(name));
                }
                else if (i == '\t') {
                    my_strlcpy(name, "\\t", sizeof(name));
                }
                else {
                    assert(i == ' ');
                    my_strlcpy(name, "' '", sizeof(name));
                }

                /* Check each possibe class */
                if (UNLIKELY(cBOOL(isU8_ALPHANUMERIC_LC(i)) !=
                                                    cBOOL(isALPHANUMERIC_A(i))))
                {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                        "isalnum('%s') unexpectedly is %x\n",
                                        name, cBOOL(isU8_ALPHANUMERIC_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_ALPHA_LC(i)) != cBOOL(isALPHA_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isalpha('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_ALPHA_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_DIGIT_LC(i)) != cBOOL(isDIGIT_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isdigit('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_DIGIT_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_GRAPH_LC(i)) != cBOOL(isGRAPH_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isgraph('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_GRAPH_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_LOWER_LC(i)) != cBOOL(isLOWER_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "islower('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_LOWER_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_PRINT_LC(i)) != cBOOL(isPRINT_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isprint('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_PRINT_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_PUNCT_LC(i)) != cBOOL(isPUNCT_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "ispunct('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_PUNCT_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_SPACE_LC(i)) != cBOOL(isSPACE_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isspace('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_SPACE_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_UPPER_LC(i)) != cBOOL(isUPPER_A(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isupper('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_UPPER_LC(i))));
                }
                if (UNLIKELY(cBOOL(isU8_XDIGIT_LC(i))!= cBOOL(isXDIGIT_A(i)))) {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                          "isxdigit('%s') unexpectedly is %x\n",
                                          name, cBOOL(isU8_XDIGIT_LC(i))));
                }
                if (UNLIKELY(toU8_LOWER_LC(i) != (int) toLOWER_A(i))) {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "tolower('%s')=0x%x instead of the expected 0x%x\n",
                            name, toU8_LOWER_LC(i), (int) toLOWER_A(i)));
                }
                if (UNLIKELY(toU8_UPPER_LC(i) != (int) toUPPER_A(i))) {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "toupper('%s')=0x%x instead of the expected 0x%x\n",
                            name, toU8_UPPER_LC(i), (int) toUPPER_A(i)));
                }
                if (UNLIKELY((i == '\n' && ! isCNTRL_LC(i))))  {
                    is_bad = TRUE;
                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                "'\\n' (=%02X) is not a control\n", (int) i));
                }

                /* Add to the list;  Separate multiple entries with a blank */
                if (is_bad) {
                    if (bad_count) {
                        my_strlcat(bad_chars_list, " ", sizeof(bad_chars_list));
                    }
                    my_strlcat(bad_chars_list, name, sizeof(bad_chars_list));
                    bad_count++;
                }
            }
        }

        if (bad_count == 2 && maybe_utf8_turkic) {
            bad_count = 0;
            *bad_chars_list = '\0';

            /* The casts are because otherwise some compilers warn:
                gcc.gnu.org/bugzilla/show_bug.cgi?id=99950
                gcc.gnu.org/bugzilla/show_bug.cgi?id=94182
             */
            PL_fold_locale[ (U8) 'I' ] = 'I';
            PL_fold_locale[ (U8) 'i' ] = 'i';
            PL_in_utf8_turkic_locale = TRUE;
            DEBUG_L(PerlIO_printf(Perl_debug_log, "%s is turkic\n", newctype));
        }

        /* If we found problems and we want them output, do so */
        if (   (UNLIKELY(bad_count))
            && (LIKELY(ckWARN_d(WARN_LOCALE)) || UNLIKELY(DEBUG_L_TEST)))
        {
            /* WARNING.  If you change the wording of these; be sure to update
             * t/loc_tools.pl correspondingly */

            if (PL_in_utf8_CTYPE_locale) {
                PL_warn_locale = Perl_newSVpvf(aTHX_
                     "Locale '%s' contains (at least) the following characters"
                     " which have\nunexpected meanings: %s\nThe Perl program"
                     " will use the expected meanings",
                      newctype, bad_chars_list);
            }
            else {
                PL_warn_locale =
                    Perl_newSVpvf(aTHX_
                                  "\nThe following characters (and maybe"
                                  " others) may not have the same meaning as"
                                  " the Perl program expects: %s\n",
                                  bad_chars_list
                            );
            }

#    if defined(HAS_SOME_LANGINFO) || defined(WIN32)

            const char * scratch_buffer = NULL;
            Perl_sv_catpvf(aTHX_ PL_warn_locale, "; codeset=%s",
                                 my_langinfo_c(CODESET, LC_CTYPE,
                                               newctype,
                                               &scratch_buffer, NULL,
                                               NULL));
            Safefree(scratch_buffer);

#    endif

            Perl_sv_catpvf(aTHX_ PL_warn_locale, "\n");

            /* If we are actually in the scope of the locale or are debugging,
             * output the message now.  If not in that scope, we save the
             * message to be output at the first operation using this locale,
             * if that actually happens.  Most programs don't use locales, so
             * they are immune to bad ones.  */
            if (IN_LC(LC_CTYPE) || UNLIKELY(DEBUG_L_TEST)) {

                /* The '0' below suppresses a bogus gcc compiler warning */
                Perl_warner(aTHX_ packWARN(WARN_LOCALE), SvPVX(PL_warn_locale),
                                                                            0);
                if (IN_LC(LC_CTYPE)) {
                    SvREFCNT_dec_NN(PL_warn_locale);
                    PL_warn_locale = NULL;
                }
            }
        }
    }
}

void
Perl_warn_problematic_locale()
{
    dTHX;

    /* Core-only function that outputs the message in PL_warn_locale,
     * and then NULLS it.  Should be called only through the macro
     * CHECK_AND_WARN_PROBLEMATIC_LOCALE_ */

    if (PL_warn_locale) {
        Perl_ck_warner(aTHX_ packWARN(WARN_LOCALE),
                             SvPVX(PL_warn_locale),
                             0 /* dummy to avoid compiler warning */ );
        SvREFCNT_dec_NN(PL_warn_locale);
        PL_warn_locale = NULL;
    }
}

#  endif /* USE_LOCALE_CTYPE */

STATIC void
S_new_LC_ALL(pTHX_ const char *unused, bool force)
{
    PERL_ARGS_ASSERT_NEW_LC_ALL;
    PERL_UNUSED_ARG(unused);

    /* new_LC_ALL() updates all the things we care about.  Note that this is
     * called just after a change, so uses the actual underlying locale just
     * set, and not the nominal one (should they differ, as they may in
     * LC_NUMERIC). */

    for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
        if (update_functions[i]) {
            const char * this_locale = querylocale_i(i);
            update_functions[i](aTHX_ this_locale, force);
        }
    }
}

#  ifdef USE_LOCALE_COLLATE

STATIC void
S_new_collate(pTHX_ const char *newcoll, bool force)
{
    PERL_ARGS_ASSERT_NEW_COLLATE;
    PERL_UNUSED_ARG(force);

    /* Called after each libc setlocale() call affecting LC_COLLATE, to tell
     * core Perl this and that 'newcoll' is the name of the new locale.
     *
     * The design of locale collation is that every locale change is given an
     * index 'PL_collation_ix'.  The first time a string participates in an
     * operation that requires collation while locale collation is active, it
     * is given PERL_MAGIC_collxfrm magic (via sv_collxfrm_flags()).  That
     * magic includes the collation index, and the transformation of the string
     * by strxfrm(), q.v.  That transformation is used when doing comparisons,
     * instead of the string itself.  If a string changes, the magic is
     * cleared.  The next time the locale changes, the index is incremented,
     * and so we know during a comparison that the transformation is not
     * necessarily still valid, and so is recomputed.  Note that if the locale
     * changes enough times, the index could wrap, and it is possible that a
     * transformation would improperly be considered valid, leading to an
     * unlikely bug.  The value is declared to the widest possible type on this
     * platform. */

    /* Return if the locale isn't changing */
    if (strEQ(PL_collation_name, newcoll)) {
        return;
    }

    Safefree(PL_collation_name);
    PL_collation_name = savepv(newcoll);
    ++PL_collation_ix;

    /* Set the new one up if trivial.  Since this is called at process
     * initialization, be aware that this bit can't rely on much being
     * available. */
    PL_collation_standard = isNAME_C_OR_POSIX(newcoll);
    if (PL_collation_standard) {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "Setting PL_collation name='%s'\n",
                               PL_collation_name));
        PL_collxfrm_base = 0;
        PL_collxfrm_mult = 2;
        PL_in_utf8_COLLATE_locale = FALSE;
        PL_strxfrm_NUL_replacement = '\0';
        PL_strxfrm_max_cp = 0;
        return;
    }

    /* Flag that the remainder of the set up is being deferred until first
     * need. */
    PL_collxfrm_mult = 0;
    PL_collxfrm_base = 0;

}

#  endif /* USE_LOCALE_COLLATE */

#  ifdef WIN32

STATIC wchar_t *
S_Win_byte_string_to_wstring(const UINT code_page, const char * byte_string)
{
    /* Caller must arrange to free the returned string */

    int req_size = MultiByteToWideChar(code_page, 0, byte_string, -1, NULL, 0);
    if (! req_size) {
        SET_EINVAL;
        return NULL;
    }

    wchar_t *wstring;
    Newx(wstring, req_size, wchar_t);

    if (! MultiByteToWideChar(code_page, 0, byte_string, -1, wstring, req_size))
    {
        Safefree(wstring);
        SET_EINVAL;
        return NULL;
    }

    return wstring;
}

#    define Win_utf8_string_to_wstring(s)                                   \
                                    Win_byte_string_to_wstring(CP_UTF8, (s))

STATIC char *
S_Win_wstring_to_byte_string(const UINT code_page, const wchar_t * wstring)
{
    /* Caller must arrange to free the returned string */

    int req_size =
            WideCharToMultiByte(code_page, 0, wstring, -1, NULL, 0, NULL, NULL);

    char *byte_string;
    Newx(byte_string, req_size, char);

    if (! WideCharToMultiByte(code_page, 0, wstring, -1, byte_string,
                                                         req_size, NULL, NULL))
    {
        Safefree(byte_string);
        SET_EINVAL;
        return NULL;
    }

    return byte_string;
}

#    define Win_wstring_to_utf8_string(ws)                                  \
                                   Win_wstring_to_byte_string(CP_UTF8, (ws))

STATIC const char *
S_wrap_wsetlocale(pTHX_ const int category, const char *locale)
{
    PERL_ARGS_ASSERT_WRAP_WSETLOCALE;

    /* Calls _wsetlocale(), converting the parameters/return to/from
     * Perl-expected forms as if plain setlocale() were being called instead.
     */

    const wchar_t * wlocale = NULL;

    if (locale) {
        wlocale = Win_utf8_string_to_wstring(locale);
        if (! wlocale) {
            return NULL;
        }
    }

    WSETLOCALE_LOCK;
    const wchar_t * wresult = _wsetlocale(category, wlocale);

    if (! wresult) {
        WSETLOCALE_UNLOCK;
        Safefree(wlocale);
        return NULL;
    }

    const char * result = Win_wstring_to_utf8_string(wresult);
    WSETLOCALE_UNLOCK;

    Safefree(wlocale);
    SAVEFREEPV(result); /* is there something better we can do here?  Answer:
                           Without restructuring, returning a unique value each
                           call is required.  See GH #20434 */
    return result;
}

STATIC const char *
S_win32_setlocale(pTHX_ int category, const char* locale)
{
    /* This, for Windows, emulates POSIX setlocale() behavior.  There is no
     * difference between the two unless the input locale is "", which normally
     * means on Windows to get the machine default, which is set via the
     * computer's "Regional and Language Options" (or its current equivalent).
     * In POSIX, it instead means to find the locale from the user's
     * environment.  This routine changes the Windows behavior to first look in
     * the environment, and, if anything is found, use that instead of going to
     * the machine default.  If there is no environment override, the machine
     * default is used, by calling the real setlocale() with "".
     *
     * The POSIX behavior is to use the LC_ALL variable if set; otherwise to
     * use the particular category's variable if set; otherwise to use the LANG
     * variable. */

    if (locale == NULL) {
        return wrap_wsetlocale(category, NULL);
    }

    if (strEQ(locale, "")) {
        /* Note this function may change the locale, but that's ok because we
         * are about to change it anyway */
        locale = find_locale_from_environment(get_category_index(category));
        if (locale == NULL) {
            SET_EINVAL;
            return NULL;
        }
    }

    const char * result = wrap_wsetlocale(category, locale);
    DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                          setlocale_debug_string_r(category, locale, result)));

#    ifdef USE_PL_CUR_LC_ALL

    /* If we need to keep track of LC_ALL, update it to the new value.  */
    Safefree(PL_cur_LC_ALL);
    if (category == LC_ALL) {
        PL_cur_LC_ALL = savepv(result);
    }
    else {
        PL_cur_LC_ALL = savepv(wrap_wsetlocale(LC_ALL, NULL));
    }

#    endif

    return result;
}

#  endif
#endif  /* USE_LOCALE */

/*
=for apidoc Perl_setlocale

This is an (almost) drop-in replacement for the system L<C<setlocale(3)>>,
taking the same parameters, and returning the same information, except that it
returns the correct underlying C<LC_NUMERIC> locale.  Regular C<setlocale> will
instead return C<C> if the underlying locale has a non-dot decimal point
character, or a non-empty thousands separator for displaying floating point
numbers.  This is because perl keeps that locale category such that it has a
dot and empty separator, changing the locale briefly during the operations
where the underlying one is required. C<Perl_setlocale> knows about this, and
compensates; regular C<setlocale> doesn't.

Another reason it isn't completely a drop-in replacement is that it is
declared to return S<C<const char *>>, whereas the system setlocale omits the
C<const> (presumably because its API was specified long ago, and can't be
updated; it is illegal to change the information C<setlocale> returns; doing
so leads to segfaults.)

Finally, C<Perl_setlocale> works under all circumstances, whereas plain
C<setlocale> can be completely ineffective on some platforms under some
configurations.

Changing the locale is not a good idea when more than one thread is running,
except on systems where the predefined variable C<${^SAFE_LOCALES}> is
non-zero.  This is because on such systems the locale is global to the whole
process and not local to just the thread calling the function.  So changing it
in one thread instantaneously changes it in all.  On some such systems, the
system C<setlocale()> is ineffective, returning the wrong information, and
failing to actually change the locale.  z/OS refuses to try to change the
locale once a second thread is created.  C<Perl_setlocale>, should give you
accurate results of what actually happened on these problematic platforms,
returning NULL if the system forbade the locale change.

The return points to a per-thread static buffer, which is overwritten the next
time C<Perl_setlocale> is called from the same thread.

=cut

*/

#ifndef USE_LOCALE_NUMERIC
#  define affects_LC_NUMERIC(cat) 0
#elif defined(LC_ALL)
#  define affects_LC_NUMERIC(cat) (cat == LC_NUMERIC || cat == LC_ALL)
#else
#  define affects_LC_NUMERIC(cat) (cat == LC_NUMERIC)
#endif

const char *
Perl_setlocale(const int category, const char * locale)
{
    /* This wraps POSIX::setlocale() */

#ifndef USE_LOCALE

    PERL_UNUSED_ARG(category);
    PERL_UNUSED_ARG(locale);

    return "C";

#else

    const char * retval;
    dTHX;

    DEBUG_L(PerlIO_printf(Perl_debug_log,
                          "Entering Perl_setlocale(%d, \"%s\")\n",
                          category, locale));

    bool valid_category;
    unsigned int cat_index = get_category_index_helper(category,
                                                       &valid_category,
                                                       __LINE__);
    if (! valid_category) {
        if (ckWARN(WARN_LOCALE)) {
            const char * conditional_warn_text;
            if (locale == NULL) {
                conditional_warn_text = "";
                locale = "";
            }
            else {
                conditional_warn_text = "; can't set it to ";
            }

            /* diag_listed_as: Unknown locale category %d; can't set it to %s */
            Perl_warner(aTHX_
                           packWARN(WARN_LOCALE),
                           "Unknown locale category %d%s%s",
                           category, conditional_warn_text, locale);
        }

        SET_EINVAL;
        return NULL;
    }

    /* A NULL locale means only query what the current one is. */
    if (locale == NULL) {

#  ifndef USE_LOCALE_NUMERIC

        /* Without LC_NUMERIC, it's trivial; we just return the value */
        return save_to_buffer(querylocale_i(cat_index),
                              &PL_setlocale_buf, &PL_setlocale_bufsize);
#  else

        /* We have the LC_NUMERIC name saved, because we are normally switched
         * into the C locale (or equivalent) for it. */
        if (category == LC_NUMERIC) {
            DEBUG_L(PerlIO_printf(Perl_debug_log,
                    "Perl_setlocale(LC_NUMERIC, NULL) returning stashed '%s'\n",
                    PL_numeric_name));

            /* We don't have to copy this return value, as it is a per-thread
             * variable, and won't change until a future setlocale */
            return PL_numeric_name;
        }

#    ifndef LC_ALL

        /* Without LC_ALL, just return the value */
        return save_to_buffer(querylocale_i(cat_index),
                              &PL_setlocale_buf, &PL_setlocale_bufsize);

#    else

        /* Here, LC_ALL is available on this platform.  It's the one
         * complicating category (because it can contain a toggled LC_NUMERIC
         * value), for all the remaining ones (we took care of LC_NUMERIC
         * above), just return the value */
        if (category != LC_ALL) {
            return save_to_buffer(querylocale_i(cat_index),
                                  &PL_setlocale_buf, &PL_setlocale_bufsize);
        }

        bool toggled = FALSE;

        /* For an LC_ALL query, switch back to the underlying numeric locale
         * (if we aren't there already) so as to get the correct results.  Our
         * records for all the other categories are valid without switching */
        if (! PL_numeric_underlying) {
            set_numeric_underlying(__FILE__, __LINE__);
            toggled = TRUE;
        }

        retval = querylocale_c(LC_ALL);

        if (toggled) {
            set_numeric_standard(__FILE__, __LINE__);
        }

        DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                           setlocale_debug_string_i(cat_index, locale, retval)));

        return save_to_buffer(retval, &PL_setlocale_buf, &PL_setlocale_bufsize);

#    endif      /* Has LC_ALL */
#  endif        /* Has LC_NUMERIC */

    } /* End of querying the current locale */

    retval = querylocale_i(cat_index);

    /* If the new locale is the same as the current one, nothing is actually
     * being changed, so do nothing. */
    if (      strEQ(retval, locale)
        && (   ! affects_LC_NUMERIC(category)

#  ifdef USE_LOCALE_NUMERIC

            || strEQ(locale, PL_numeric_name)

#  endif

    )) {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                              "Already in requested locale: no action taken\n"));
        return save_to_buffer(retval, &PL_setlocale_buf, &PL_setlocale_bufsize);
    }

    /* Here, an actual change is being requested.  Do it */
    if (! bool_setlocale_i(cat_index, locale)) {
        DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                          setlocale_debug_string_i(cat_index, locale, "NULL")));
        return NULL;
    }

    assert(strNE(retval, ""));
    retval = save_to_buffer(querylocale_i(cat_index),
                            &PL_setlocale_buf, &PL_setlocale_bufsize);

    /* Now that have changed locales, we have to update our records to
     * correspond.  Only certain categories have extra work to update. */
    if (update_functions[cat_index]) {
        update_functions[cat_index](aTHX_ retval, false);
    }

    DEBUG_L(PerlIO_printf(Perl_debug_log, "returning '%s'\n", retval));

    return retval;

#endif

}

STATIC utf8ness_t
S_get_locale_string_utf8ness_i(pTHX_ const char * string,
                                     const locale_utf8ness_t known_utf8,
                                     const char * locale,
                                     const unsigned cat_index)
{
    PERL_ARGS_ASSERT_GET_LOCALE_STRING_UTF8NESS_I;

#  ifndef USE_LOCALE

    return UTF8NESS_NO;
    PERL_UNUSED_ARG(string);
    PERL_UNUSED_ARG(known_utf8);
    PERL_UNUSED_ARG(locale);
    PERL_UNUSED_ARG(cat_index);

#  else

    assert(cat_index <= LC_ALL_INDEX_);

    /* Return to indicate if 'string' in the locale given by the input
     * arguments should be considered UTF-8 or not.
     *
     * If the input 'locale' is not NULL, use that for the locale; otherwise
     * use the current locale for the category specified by 'cat_index'.
     */

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "Entering get_locale_string_utf8ness_i; locale=%s,"
                           " index=%u(%s), string=%s, known_utf8=%d\n",
                           locale, cat_index, category_names[cat_index],
                           ((string)
                            ?  _byte_dump_string((U8 *) string,
                                                 strlen(string),
                                                 0)
                            : "nil"),
                           known_utf8));
    if (string == NULL) {
        return UTF8NESS_IMMATERIAL;
    }

    if (IN_BYTES) { /* respect 'use bytes' */
        return UTF8NESS_NO;
    }

    Size_t len = strlen(string);

    /* UTF8ness is immaterial if the representation doesn't vary */
    const U8 * first_variant = NULL;
    if (is_utf8_invariant_string_loc((U8 *) string, len, &first_variant)) {
        return UTF8NESS_IMMATERIAL;
    }

    /* Can't be UTF-8 if invalid */
    if (! is_utf8_string((U8 *) first_variant,
                         len - ((char *) first_variant - string)))
    {
        return UTF8NESS_NO;
    }

    /* Here and below, we know the string is legal UTF-8, containing at least
     * one character requiring a sequence of two or more bytes.  It is quite
     * likely to be UTF-8.  But it pays to be paranoid and do further checking.
     *
     * If we already know the UTF-8ness of the locale, then we immediately know
     * what the string is */
    if (UNLIKELY(known_utf8 != LOCALE_UTF8NESS_UNKNOWN)) {
        if (known_utf8 == LOCALE_IS_UTF8) {
            return UTF8NESS_YES;
        }
        else {
            return UTF8NESS_NO;
        }
    }

#    ifdef HAS_RELIABLE_UTF8NESS_DETERMINATION

    /* Here, we have available the libc functions that can be used to
     * accurately determine the UTF8ness of the underlying locale.  If it is a
     * UTF-8 locale, the string is UTF-8;  otherwise it was coincidental that
     * the string is legal UTF-8
     *
     * However, if the perl is compiled to not pay attention to the category
     * being passed in, you might think that that locale is essentially always
     * the C locale, so it would make sense to say it isn't UTF-8.  But to get
     * here, the string has to contain characters unknown in the C locale.  And
     * in fact, Windows boxes are compiled without LC_MESSAGES, as their
     * message catalog isn't really a part of the locale system.  But those
     * messages really could be UTF-8, and given that the odds are rather small
     * of something not being UTF-8 but being syntactically valid UTF-8, khw
     * has decided to call such strings as UTF-8. */

    if (locale == NULL) {
        locale = querylocale_i(cat_index);
    }

    if (is_locale_utf8(locale)) {
        return UTF8NESS_YES;
    }

    return UTF8NESS_NO;

#    else

    /* Here, we have a valid UTF-8 string containing non-ASCII characters, and
     * don't have access to functions to check if the locale is UTF-8 or not.
     * Assume that it is.  khw tried adding a check that the string is entirely
     * in a single Unicode script, but discovered the strftime() timezone is
     * user-settable through the environment, which may be in a different
     * script than the locale-expected value. */
    PERL_UNUSED_ARG(locale);
    PERL_UNUSED_ARG(cat_index);

    return UTF8NESS_YES;

#  endif
#endif

}

STATIC bool
S_is_locale_utf8(pTHX_ const char * locale)
{
    /* Returns TRUE if the locale 'locale' is UTF-8; FALSE otherwise.  It uses
     * my_langinfo(), which employs various methods to get this information
     * if nl_langinfo() isn't available, using heuristics as a last resort, in
     * which case, the result will very likely be correct for locales for
     * languages that have commonly used non-ASCII characters, but for notably
     * English, it comes down to if the locale's name ends in something like
     * "UTF-8".  It errs on the side of not being a UTF-8 locale.
     *
     * Systems conforming to C99 should have the needed libc calls to give us a
     * completely reliable result. */

#  if ! defined(USE_LOCALE)                                                   \
   || ! defined(USE_LOCALE_CTYPE)                                             \
   ||   defined(EBCDIC) /* There aren't any real UTF-8 locales at this time */

    PERL_UNUSED_ARG(locale);

    return FALSE;

#  else

    const char * scratch_buffer = NULL;
    const char * codeset;
    bool retval;

    PERL_ARGS_ASSERT_IS_LOCALE_UTF8;

    if (strEQ(locale, PL_ctype_name)) {
        return PL_in_utf8_CTYPE_locale;
    }

    codeset = my_langinfo_c(CODESET, LC_CTYPE, locale,
                            &scratch_buffer, NULL, NULL);
    retval = is_codeset_name_UTF8(codeset);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "found codeset=%s, is_utf8=%d\n", codeset, retval));

    Safefree(scratch_buffer);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "is_locale_utf8(%s) returning %d\n",
                                                            locale, retval));
    return retval;

#  endif

}

#ifdef USE_LOCALE

STATIC const char *
S_save_to_buffer(pTHX_ const char * string, const char **buf, Size_t *buf_size)
{
    /* Copy the NUL-terminated 'string' to a buffer whose address before this
     * call began at *buf, and whose available length before this call was
     * *buf_size.
     *
     * If the length of 'string' is greater than the space available, the
     * buffer is grown accordingly, which may mean that it gets relocated.
     * *buf and *buf_size will be updated to reflect this.
     *
     * Regardless, the function returns a pointer to where 'string' is now
     * stored.
     *
     * 'string' may be NULL, which means no action gets taken, and NULL is
     * returned.
     *
     * 'buf_size' being NULL is to be used when this is a single use buffer,
     * which will shortly be freed by the caller.
     *
     * If *buf or 'buf_size' are NULL or *buf_size is 0, the buffer is assumed
     * empty, and memory is malloc'd.
     */

    Size_t string_size;

    PERL_ARGS_ASSERT_SAVE_TO_BUFFER;

    if (! string) {
        return NULL;
    }

    /* No-op to copy over oneself */
    if (string == *buf) {
        return string;
    }

    string_size = strlen(string) + 1;

    if (buf_size == NULL) {
        Newx(*buf, string_size, char);
    }
    else if (*buf_size == 0) {
        Newx(*buf, string_size, char);
        *buf_size = string_size;
    }
    else if (string_size > *buf_size) {
        Renew(*buf, string_size, char);
        *buf_size = string_size;
    }

#    ifdef DEBUGGING

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                         "Copying '%s' to %p\n",
                         ((is_utf8_string((U8 *) string, 0))
                          ? string
                          :_byte_dump_string((U8 *) string, strlen(string), 0)),
                          *buf));

    /* Catch glitches.  Usually this is because LC_CTYPE needs to be the same
     * locale as whatever is being worked on */
    if (UNLIKELY(instr(string, REPLACEMENT_CHARACTER_UTF8))) {
        locale_panic_(Perl_form(aTHX_
                                "Unexpected REPLACEMENT_CHARACTER in '%s'\n%s",
                                string, get_LC_ALL_display()));
    }

#  endif

    Copy(string, *buf, string_size, char);
    return *buf;
}

#  ifdef WIN32

bool
Perl_get_win32_message_utf8ness(pTHX_ const char * string)
{
    /* This is because Windows doesn't have LC_MESSAGES. */

#    ifdef USE_LOCALE_CTYPE

    return get_locale_string_utf8ness_i(string, LOCALE_IS_UTF8,
                                        NULL, LC_CTYPE_INDEX_);
#    else

    return false;

#    endif

}

#  endif
#endif  /* USE_LOCALE */

int
Perl_mbtowc_(pTHX_ const wchar_t * pwc, const char * s, const Size_t len)
{

#if ! defined(HAS_MBRTOWC) && ! defined(HAS_MBTOWC)

    PERL_UNUSED_ARG(pwc);
    PERL_UNUSED_ARG(s);
    PERL_UNUSED_ARG(len);
    return -1;

#else   /* Below we have some form of mbtowc() */
#  if defined(HAS_MBRTOWC)                                      \
   && (defined(USE_LOCALE_THREADS) || ! defined(HAS_MBTOWC))
#    define USE_MBRTOWC
#  else
#    undef USE_MBRTOWC
#  endif

    int retval = -1;

    if (s == NULL) { /* Initialize the shift state to all zeros in
                        PL_mbrtowc_ps. */

#  if defined(USE_MBRTOWC)

        memzero(&PL_mbrtowc_ps, sizeof(PL_mbrtowc_ps));
        return 0;

#  else

        SETERRNO(0, 0);
        MBTOWC_LOCK_;
        retval = mbtowc(NULL, NULL, 0);
        MBTOWC_UNLOCK_;
        return retval;

#  endif

    }

#  if defined(USE_MBRTOWC)

    SETERRNO(0, 0);
    MBRTOWC_LOCK_;
    retval = (SSize_t) mbrtowc((wchar_t *) pwc, s, len, &PL_mbrtowc_ps);
    MBRTOWC_UNLOCK_;

#  else

    /* Locking prevents races, but locales can be switched out without locking,
     * so this isn't a cure all */
    SETERRNO(0, 0);
    MBTOWC_LOCK_;
    retval = mbtowc((wchar_t *) pwc, s, len);
    MBTOWC_UNLOCK_;

#  endif

    return retval;

#endif

}

/*
=for apidoc Perl_localeconv

This is a thread-safe version of the libc L<localeconv(3)>.  It is the same as
L<POSIX::localeconv|POSIX/localeconv> (returning a hash of the C<localeconv()>
fields), but directly callable from XS code.

=cut
*/

HV *
Perl_localeconv(pTHX)
{

#if  ! defined(HAS_LOCALECONV)

    return newHV();

#else

    return my_localeconv(0);

#endif

}

#if  defined(HAS_LOCALECONV)

HV *
S_my_localeconv(pTHX_ const int item)
{
    PERL_ARGS_ASSERT_MY_LOCALECONV;

    /* This returns a mortalized hash containing all or certain elements
     * returned by localeconv().  It is used by Perl_localeconv() and
     * POSIX::localeconv() and is thread-safe.
     *
     * There are two use cases:
     * 1) Called from POSIX::locale_conv().  This returns the lconv structure
     *    copied to a hash, based on the current underlying locales for
     *    LC_NUMERIC and LC_MONETARY. An input item==0 signifies this case, or
     *    on many platforms it is the only use case compiled.
     * 2) Certain items that nl_langinfo() provides are also derivable from
     *    the return of localeconv().  Windows notably doesn't have
     *    nl_langinfo(), so on that, and actually any platform lacking it,
     *    my_localeconv() is used also to emulate it for those particular
     *    items.  The code to do this is compiled only on such platforms.
     *    Rather than going to the expense of creating a full hash when only
     *    one item is needed, the returned hash has just the desired item in
     *    it.
     *
     * To access all the localeconv() struct lconv fields, there is a data
     * structure that contains every commonly documented field in it.  (Maybe
     * some minority platforms have extra fields.  Those could be added here
     * without harm; they would just be ignored on platforms lacking them.)
     *
     * Our structure is compiled to make looping through the fields easier by
     * pointing each name to its value's offset within lconv, e.g.,
        { "thousands_sep", STRUCT_OFFSET(struct lconv, thousands_sep) }
     */
#  define LCONV_ENTRY(name)                                                 \
                       {STRINGIFY(name), STRUCT_OFFSET(struct lconv, name)}

    /* These synonyms are just for clarity, and to make it easier in case
     * something needs to change in the future */
#  define LCONV_NUMERIC_ENTRY(name)  LCONV_ENTRY(name)
#  define LCONV_MONETARY_ENTRY(name) LCONV_ENTRY(name)

    /* There are just a few fields for NUMERIC strings */
    const lconv_offset_t lconv_numeric_strings[] = {
#  ifndef NO_LOCALECONV_GROUPING
        LCONV_NUMERIC_ENTRY(grouping),
#   endif
        LCONV_NUMERIC_ENTRY(thousands_sep),
        LCONV_NUMERIC_ENTRY(decimal_point),
        {NULL, 0}
    };

    /* When used to implement nl_langinfo(), we save time by only populating
     * the hash with the field(s) needed.  Thus we would need a data structure
     * of just:
     *  LCONV_NUMERIC_ENTRY(decimal_point),
     *  {NULL, 0}
     *
     * By placing the decimal_point field last in the full structure, we can
     * use just the tail for this bit of it, saving space.  This macro yields
     * the address of the sub structure. */
#  define DECIMAL_POINT_ADDRESS                                             \
        &lconv_numeric_strings[(C_ARRAY_LENGTH(lconv_numeric_strings) - 2)]

    /* And the MONETARY string fields */
    const lconv_offset_t lconv_monetary_strings[] = {
        LCONV_MONETARY_ENTRY(int_curr_symbol),
        LCONV_MONETARY_ENTRY(mon_decimal_point),
#  ifndef NO_LOCALECONV_MON_THOUSANDS_SEP
        LCONV_MONETARY_ENTRY(mon_thousands_sep),
#  endif
#  ifndef NO_LOCALECONV_MON_GROUPING
        LCONV_MONETARY_ENTRY(mon_grouping),
#  endif
        LCONV_MONETARY_ENTRY(positive_sign),
        LCONV_MONETARY_ENTRY(negative_sign),
        LCONV_MONETARY_ENTRY(currency_symbol),
        {NULL, 0}
    };

    /* Like above, this field being last can be used as a sub structure */
#  define CURRENCY_SYMBOL_ADDRESS                                            \
      &lconv_monetary_strings[(C_ARRAY_LENGTH(lconv_monetary_strings) - 2)]

    /* Finally there are integer fields, all are for monetary purposes */
    const lconv_offset_t lconv_integers[] = {
        LCONV_ENTRY(int_frac_digits),
        LCONV_ENTRY(frac_digits),
        LCONV_ENTRY(p_sep_by_space),
        LCONV_ENTRY(n_cs_precedes),
        LCONV_ENTRY(n_sep_by_space),
        LCONV_ENTRY(p_sign_posn),
        LCONV_ENTRY(n_sign_posn),
#  ifdef HAS_LC_MONETARY_2008
        LCONV_ENTRY(int_p_cs_precedes),
        LCONV_ENTRY(int_p_sep_by_space),
        LCONV_ENTRY(int_n_cs_precedes),
        LCONV_ENTRY(int_n_sep_by_space),
        LCONV_ENTRY(int_p_sign_posn),
        LCONV_ENTRY(int_n_sign_posn),
#  endif
        LCONV_ENTRY(p_cs_precedes),
        {NULL, 0}
    };

    /* Like above, this field being last can be used as a sub structure */
#  define P_CS_PRECEDES_ADDRESS                                       \
      &lconv_integers[(C_ARRAY_LENGTH(lconv_integers) - 2)]

    /* If we aren't paying attention to a given category, use LC_CTYPE instead;
     * If not paying attention to that either, the code below should end up not
     * using this.  Make sure that things blow up if that avoidance gets lost,
     * by setting the category to an out-of-bounds value */
    unsigned int numeric_index;
    unsigned int monetary_index;

#  ifdef USE_LOCALE_NUMERIC
    numeric_index = LC_NUMERIC_INDEX_;
#  elif defined(USE_LOCALE_CTYPE)
    numeric_index = LC_CTYPE_INDEX_;
#  else
    numeric_index = (unsigned) -1;
#  endif
#  ifdef USE_LOCALE_MONETARY
    monetary_index = LC_MONETARY_INDEX_;
#  elif defined(USE_LOCALE_CTYPE)
    monetary_index = LC_CTYPE_INDEX_;
#  else
    monetary_index = (unsigned) -1;
#  endif

    /* Some platforms, for correct non-mojibake results, require LC_CTYPE's
     * locale to match LC_NUMERIC's for the numeric fields, and LC_MONETARY's
     * for the monetary ones.  What happens if LC_NUMERIC and LC_MONETARY
     * aren't compatible?  Wrong results.  To avoid that, we call localeconv()
     * twice, once for each locale, setting LC_CTYPE to match the category.
     * But if the locales of both categories are the same, there is no need for
     * a second call.  Assume this is the case unless overridden below */
    bool requires_2nd_localeconv = false;

    /* The actual hash populating is done by S_populate_hash_from_localeconv().
     * It gets passed an array of length two containing the data structure it
     * is supposed to use to get the key names to fill the hash with.  One
     * element is always for the NUMERIC strings (or NULL if none to use), and
     * the other element similarly for the MONETARY ones. */
#  define NUMERIC_STRING_OFFSET   0
#  define MONETARY_STRING_OFFSET  1
    const lconv_offset_t * strings[2] = { NULL, NULL };

    /* This is a mask, with one bit to tell S_populate_hash_from_localeconv to
     * populate the NUMERIC items; another bit for the MONETARY ones.  This way
     * it can choose which (or both) to populate from */
    U32 index_bits = 0;

    /* This converts from a locale index to its bit position in the above mask.
     * */
#  define INDEX_TO_BIT(i)  (1 << (i))

    /* The two categories can have disparate locales.  Initialize them to C and
     * override later whichever one(s) we pay attention to */
    const char * numeric_locale = "C";
    const char * monetary_locale = "C";

    /* This will be either 'numeric_locale' or 'monetary_locale' depending on
     * what we are working on at the moment */
    const char * locale;

    /* The LC_MONETARY category also has some integer-valued fields, whose
     * information is kept in a separate list */
    const lconv_offset_t * integers;

#  ifdef HAS_SOME_LANGINFO

    /* If the only use-case for this is the full localeconv(), the 'item'
     * parameter is ignored. */
    PERL_UNUSED_ARG(item);

#  else

    /* This only gets compiled for the use-case of using localeconv() to
     * emulate an nl_langinfo() missing from the platform. */

#    ifdef USE_LOCALE_NUMERIC

    /* We need this substructure to only return this field for the THOUSEP
     * item.  The other items also need substructures, but they were handled
     * above by placing the substructure's item at the end of the full one, so
     * the data structure could do double duty.  However, both this and
     * RADIXCHAR would need to be in the final position of the same full
     * structure; an impossibility.  So make this into a separate structure */
    const lconv_offset_t  thousands_sep_string[] = {
        LCONV_NUMERIC_ENTRY(thousands_sep),
        {NULL, 0}
    };

#    endif

    /* End of all the initialization of data structures.  Now for actual code.
     *
     * Without nl_langinfo(), the call to my_localeconv() could be for just one
     * of the following 3 items to emulate nl_langinfo().  This is compiled
     * only when using perl_langinfo.h, which we control, and it has been
     * constructed so that no item is numbered 0.
     *
     * For each, set up the appropriate parameters for the call below to
     * S_populate_hash_from_localeconv() */
    if (item != 0) switch (item) {
      default:
        locale_panic_(Perl_form(aTHX_
                    "Unexpected item passed to my_localeconv: %d", item));
        break;

#    ifdef USE_LOCALE_NUMERIC

      case RADIXCHAR:
        locale = numeric_locale = PL_numeric_name;
        index_bits = INDEX_TO_BIT(LC_NUMERIC_INDEX_);
        strings[NUMERIC_STRING_OFFSET] = DECIMAL_POINT_ADDRESS;
        integers = NULL;
        break;

      case THOUSEP:
        index_bits = INDEX_TO_BIT(LC_NUMERIC_INDEX_);
        locale = numeric_locale = PL_numeric_name;
        strings[NUMERIC_STRING_OFFSET] = thousands_sep_string;
        integers = NULL;
        break;

#    endif
#    ifdef USE_LOCALE_MONETARY

      case CRNCYSTR:
        index_bits = INDEX_TO_BIT(LC_MONETARY_INDEX_);
        locale = monetary_locale = querylocale_i(LC_MONETARY_INDEX_);

        /* This item needs the values for both the currency symbol, and another
         * one used to construct the nl_langino()-compatible return */
        strings[MONETARY_STRING_OFFSET] = CURRENCY_SYMBOL_ADDRESS;
        integers = P_CS_PRECEDES_ADDRESS;
        break;

#    endif

    } /* End of switch() */

    else    /* End of for just one item to emulate nl_langinfo() */

#  endif

    {   /* Here, the call is for all of localeconv().  It has a bunch of
         * items.  As in the individual item case, set up the parameters for
         * S_populate_hash_from_localeconv(); */

#  ifdef USE_LOCALE_NUMERIC
        numeric_locale = PL_numeric_name;
#  elif defined(USE_LOCALE_CTYPE)
        numeric_locale = querylocale_i(numeric_index);
#  endif
#  if defined(USE_LOCALE_MONETARY) || defined(USE_LOCALE_CTYPE)
        monetary_locale = querylocale_i(monetary_index);
#  endif

        /* The first call to S_populate_hash_from_localeconv() will be for the
         * MONETARY values */
        index_bits = INDEX_TO_BIT(monetary_index);
        locale = monetary_locale;

        /* And if the locales for the two categories are the same, we can also
         * do the NUMERIC values in the same call */
        if (strEQ(numeric_locale, monetary_locale)) {
            index_bits |= INDEX_TO_BIT(numeric_index);
        }
        else {
            requires_2nd_localeconv = true;
        }

        /* We always pass both sets of strings. 'index_bits' tells
         * S_populate_hash_from_localeconv which to actually look at */
        strings[NUMERIC_STRING_OFFSET] = lconv_numeric_strings;
        strings[MONETARY_STRING_OFFSET] = lconv_monetary_strings;

        /* And pass the integer values to populate; again 'index_bits' will
         * say to use them or not */
        integers = lconv_integers;

    }   /* End of call is for localeconv() */

    /* The code above has determined the parameters to
       S_populate_hash_from_localeconv() for both cases of an individual item
       and for the entire structure.  Below is code common to both */

    HV * hv = newHV();      /* The returned hash, initially empty */
    sv_2mortal((SV*)hv);

    /* Call localeconv() and copy its results into the hash.  All the
     * parameters have been initialized above */
    populate_hash_from_localeconv(hv,
                                  locale,
                                  index_bits,
                                  strings,
                                  integers
                                 );

    /* The above call may have done all the hash fields, but not always, as
     * already explained.  If we need a second call it is always for the
     * NUMERIC fields */
    if (requires_2nd_localeconv) {
        populate_hash_from_localeconv(hv,
                                      numeric_locale,
                                      INDEX_TO_BIT(numeric_index),
                                      strings,
                                      NULL      /* There are no NUMERIC integer
                                                   fields */
                                     );
    }

    /* Here, the hash has been completely populated.
     *
     * Now go through all the items and:
     *  a) For string items, see if they should be marked as UTF-8 or not.
     *     This would have been more convenient and faster to do while
     *     populating the hash in the first place, but that operation has to be
     *     done within a critical section, keeping other threads from
     *     executing, so only the minimal amount of work necessary is done at
     *     that time.
     *  b) For integer items, convert the C CHAR_MAX value into -1.  Again,
     *     this could have been done in the critical section, but was deferred
     *     to here to keep to the bare minimum amount the time spent owning the
     *     processor. CHAR_MAX is a C concept for an 8-bit character type.
     *     Perl has no such type; the closest fit is a -1.
     *
     * XXX On unthreaded perls, this code could be #ifdef'd out, and the
     * corrections determined at hash population time, at an extra maintenance
     * cost which khw doesn't think is worth it
     */
    for (unsigned int i = 0; i < 2; i++) {  /* Try both types of strings */
        if (! strings[i]) {     /* Skip if no strings of this type */
            continue;
        }

        locale = (i == NUMERIC_STRING_OFFSET)
                 ? numeric_locale
                 : monetary_locale;

        locale_utf8ness_t locale_is_utf8 = LOCALE_UTF8NESS_UNKNOWN;

#  ifdef HAS_RELIABLE_UTF8NESS_DETERMINATION

        /* It saves time in the loop below to have predetermined the UTF8ness
         * of the locale.  But only do so if the platform reliably has this
         * information; otherwise to do it, this could recurse indefinitely.
         *
         * When we don't do it here, it will be done on a per-element basis in
         * the loop.  The per-element check is intelligent enough to not
         * recurse */

        locale_is_utf8 = (is_locale_utf8(locale))
                         ? LOCALE_IS_UTF8
                         : LOCALE_NOT_UTF8;

        if (locale_is_utf8 == LOCALE_NOT_UTF8) {
            continue;   /* No string can be UTF-8 if the locale isn't */
        }

#  endif

        /* Examine each string */
        while (1) {
            const char * name = strings[i]->name;

            if (! name) {   /* Reached the end */
                break;
            }

            /* 'value' will contain the string that may need to be marked as
             * UTF-8 */
            SV ** value = hv_fetch(hv, name, strlen(name), true);
            if (! value) {
                continue;
            }

            /* Determine if the string should be marked as UTF-8. */
            if (UTF8NESS_YES == (get_locale_string_utf8ness_i(SvPVX(*value),
                                                              locale_is_utf8,
                                                              NULL, 0)))
            {
                SvUTF8_on(*value);
            }

            strings[i]++;   /* Iterate */
        }
    }   /* End of fixing up UTF8ness */


    /* Examine each integer */
    if (integers) while (1) {
        const char * name = integers->name;

        if (! name) {   /* Reached the end */
            break;
        }

        SV ** value = hv_fetch(hv, name, strlen(name), true);
        if (! value) {
            continue;
        }

        /* Change CHAR_MAX to -1 */
        if (SvIV(*value) == CHAR_MAX) {
            sv_setiv(*value, -1);
        }

        integers++;   /* Iterate */
    }

    return hv;
}

STATIC void
S_populate_hash_from_localeconv(pTHX_ HV * hv,

                                      /* Switch to this locale to run
                                       * localeconv() from */
                                      const char * locale,

                                      /* bit mask of which categories to
                                       * populate */
                                      const U32 which_mask,

                                      /* strings[0] points to the numeric
                                       * string fields; [1] to the monetary */
                                      const lconv_offset_t * strings[2],

                                      /* And to the monetary integer fields */
                                      const lconv_offset_t * integers)
{
    PERL_ARGS_ASSERT_POPULATE_HASH_FROM_LOCALECONV;
    PERL_UNUSED_ARG(which_mask);    /* Some configurations don't use this;
                                       complicated to figure out which */

    /* Run localeconv() and copy some or all of its results to the input 'hv'
     * hash.  Most localeconv() implementations return the values in a global
     * static buffer, so the operation must be performed in a critical section,
     * ending only after the copy is completed.  There are so many locks
     * because localeconv() deals with two categories, and returns in a single
     * global static buffer.  Some locks might be no-ops on this platform, but
     * not others.  We need to lock if any one isn't a no-op. */

#  ifdef USE_LOCALE_CTYPE

    /* Some platforms require LC_CTYPE to be congruent with the category we are
     * looking for */
    const char * orig_CTYPE_locale = toggle_locale_c(LC_CTYPE, locale);

#  endif
#  ifdef USE_LOCALE_NUMERIC

    /* We need to toggle to the underlying NUMERIC locale if we are getting
     * NUMERIC strings */
    const char * orig_NUMERIC_locale = NULL;
    if (which_mask & INDEX_TO_BIT(LC_NUMERIC_INDEX_)) {
        LC_NUMERIC_LOCK(0);

#    if defined(WIN32)

        /* There is a bug in Windows in which setting LC_CTYPE after the others
         * doesn't actually take effect for localeconv().  See commit
         * 418efacd1950763f74ed3cc22f8cf9206661b892 for details.  Thus we have
         * to make sure that the locale we want is set after LC_CTYPE.  We
         * unconditionally toggle away from and back to the current locale
         * prior to calling localeconv().
         *
         * This code will have no effect if we already are in C, but khw
         * hasn't seen any cases where this causes problems when we are in the
         * C locale. */
        orig_NUMERIC_locale = toggle_locale_i(LC_NUMERIC_INDEX_, "C");
        toggle_locale_i(LC_NUMERIC_INDEX_, locale);

#    else

        /* No need for the extra toggle when not on Windows */
        orig_NUMERIC_locale = toggle_locale_i(LC_NUMERIC_INDEX_, locale);

#    endif

    }

#  endif
#  if defined(USE_LOCALE_MONETARY) && defined(WIN32)

    /* Same Windows bug as described just above for NUMERIC.  Otherwise, no
     * need to toggle LC_MONETARY, as it is kept in the underlying locale */
    const char * orig_MONETARY_locale = NULL;
    if (which_mask & INDEX_TO_BIT(LC_MONETARY_INDEX_)) {
        orig_MONETARY_locale = toggle_locale_i(LC_MONETARY_INDEX_, "C");
        toggle_locale_i(LC_MONETARY_INDEX_, locale);
    }

#  endif

    /* Finally ready to do the actual localeconv().  Lock to prevent other
     * accesses until we have made a copy of its returned static buffer */
    gwLOCALE_LOCK;

#  if defined(TS_W32_BROKEN_LOCALECONV) && defined(USE_THREAD_SAFE_LOCALE)

    /* This is a workaround for another bug in Windows.  localeconv() was
     * broken with thread-safe locales prior to VS 15.  It looks at the global
     * locale instead of the thread one.  As a work-around, we toggle to the
     * global locale; populate the return; then toggle back.  We have to use
     * LC_ALL instead of the individual categories because of yet another bug
     * in Windows.  And this all has to be done in a critical section.
     *
     * This introduces a potential race with any other thread that has also
     * converted to use the global locale, and doesn't protect its locale calls
     * with mutexes.  khw can't think of any reason for a thread to do so on
     * Windows, as the locale API is the same regardless of thread-safety,
     * except if the code is ported from working on another platform where
     * there might be some reason to do this.  But this is typically due to
     * some alien-to-Perl library that thinks it owns locale setting.  Such a
     * library isn't likely to exist on Windows, so such an application is
     * unlikely to be run on Windows
     */
    bool restore_per_thread = FALSE;

    /* Save the per-thread locale state */
    const char * save_thread = querylocale_c(LC_ALL);

    /* Change to the global locale, and note if we already were there */
    int config_return = _configthreadlocale(_DISABLE_PER_THREAD_LOCALE);
    if (config_return != _DISABLE_PER_THREAD_LOCALE) {
        if (config_return == -1) {
            locale_panic_("_configthreadlocale returned an error");
        }

        restore_per_thread = TRUE;
    }

    /* Save the state of the global locale; then convert to our desired
     * state.  */
    const char * save_global = querylocale_c(LC_ALL);
    void_setlocale_c(LC_ALL, save_thread);

#  endif  /* TS_W32_BROKEN_LOCALECONV */

    /* Finally, do the actual localeconv */
    const char *lcbuf_as_string = (const char *) localeconv();

    /* Fill in the string fields of the HV* */
    for (unsigned int i = 0; i < 2; i++) {

        /* One iteration is only for the numeric string fields.  Skip these
         * unless we are compiled to care about those fields and the input
         * parameters indicate we want their values */
        if (   i == NUMERIC_STRING_OFFSET

#  ifdef USE_LOCALE_NUMERIC

            && (which_mask & INDEX_TO_BIT(LC_NUMERIC_INDEX_)) == 0

#  endif

        ) {
            continue;
        }

        /* The other iteration is only for the monetary string fields.  Again
         * skip it unless we want those values */
        if (   i == MONETARY_STRING_OFFSET

#  ifdef USE_LOCALE_MONETARY

            && (which_mask & INDEX_TO_BIT(LC_MONETARY_INDEX_)) == 0

#  endif
        ) {

            continue;
        }

        /* For each field for the given category ... */
        const lconv_offset_t * category_strings = strings[i];
        while (1) {
            const char * name = category_strings->name;
            if (! name) {   /* Quit at the end */
                break;
            }

            /* we have set things up so that we know where in the returned
             * structure, when viewed as a string, the corresponding value is.
             * */
            const char *value = *((const char **)(  lcbuf_as_string
                                                  + category_strings->offset));

            /* Set to get next string on next iteration */
            category_strings++;

            /* Skip if this platform doesn't have this field. */
            if (! value) {
                continue;
            }

            /* Copy to the hash */
            (void) hv_store(hv,
                            name, strlen(name),
                            newSVpv(value, strlen(value)),
                            0);
        }

        /* Add any int fields to the HV* */
        if (i == MONETARY_STRING_OFFSET && integers) {
            while (integers->name) {
                const char value = *((const char *)(  lcbuf_as_string
                                                    + integers->offset));
                (void) hv_store(hv, integers->name,
                                strlen(integers->name), newSViv(value), 0);
                integers++;
            }
        }
    }   /* End of loop through the fields */

    /* Done with copying to the hash.  Can unwind the critical section locks */

#  if defined(TS_W32_BROKEN_LOCALECONV) && defined(USE_THREAD_SAFE_LOCALE)

    /* Restore the global locale's prior state */
    void_setlocale_c(LC_ALL, save_global);

    /* And back to per-thread locales */
    if (restore_per_thread) {
        if (_configthreadlocale(_ENABLE_PER_THREAD_LOCALE) == -1) {
            locale_panic_("_configthreadlocale returned an error");
        }
    }

    /* Restore the per-thread locale state */
    void_setlocale_c(LC_ALL, save_thread);

#  endif  /* TS_W32_BROKEN_LOCALECONV */

    gwLOCALE_UNLOCK;    /* Finished with the critical section of a
                           globally-accessible buffer */

#  if defined(USE_LOCALE_MONETARY) && defined(WIN32)

    restore_toggled_locale_i(LC_MONETARY_INDEX_, orig_MONETARY_locale);

#  endif
#  ifdef USE_LOCALE_NUMERIC

    restore_toggled_locale_i(LC_NUMERIC_INDEX_, orig_NUMERIC_locale);
    if (which_mask & INDEX_TO_BIT(LC_NUMERIC_INDEX_)) {
        LC_NUMERIC_UNLOCK;
    }

#  endif
#  ifdef USE_LOCALE_CTYPE

    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);

#  endif

}

#endif /* defined(HAS_LOCALECONV) */
#ifndef HAS_SOME_LANGINFO

typedef int nl_item;    /* Substitute 'int' for emulated nl_langinfo() */

#endif

/*

=for apidoc      Perl_langinfo
=for apidoc_item Perl_langinfo8

C<Perl_langinfo> is an (almost) drop-in replacement for the system
C<L<nl_langinfo(3)>>, taking the same C<item> parameter values, and returning
the same information.  But it is more thread-safe than regular
C<nl_langinfo()>, and hides the quirks of Perl's locale handling from your
code, and can be used on systems that lack a native C<nl_langinfo>.

However, you should instead use the improved version of this:
L</Perl_langinfo8>, which behaves identically except for an additional
parameter, a pointer to a variable declared as L</C<utf8ness_t>>, into which it
returns to you how you should treat the returned string with regards to it
being encoded in UTF-8 or not.

Concerning the differences between these and plain C<nl_langinfo()>:

=over

=item a.

C<Perl_langinfo8> has an extra parameter, described above.  Besides this, the
other reason they aren't quite a drop-in replacement is actually an advantage.
The C<const>ness of the return allows the compiler to catch attempts to write
into the returned buffer, which is illegal and could cause run-time crashes.

=item b.

They deliver the correct results for the C<RADIXCHAR> and C<THOUSEP> items,
without you having to write extra code.  The reason for the extra code would be
because these are from the C<LC_NUMERIC> locale category, which is normally
kept set by Perl so that the radix is a dot, and the separator is the empty
string, no matter what the underlying locale is supposed to be, and so to get
the expected results, you have to temporarily toggle into the underlying
locale, and later toggle back.  (You could use plain C<nl_langinfo> and
C<L</STORE_LC_NUMERIC_FORCE_TO_UNDERLYING>> for this but then you wouldn't get
the other advantages of C<Perl_langinfo()>; not keeping C<LC_NUMERIC> in the C
(or equivalent) locale would break a lot of CPAN, which is expecting the radix
(decimal point) character to be a dot.)

=item c.

The system function they replace can have its static return buffer trashed,
not only by a subsequent call to that function, but by a C<freelocale>,
C<setlocale>, or other locale change.  The returned buffer of these functions
is not changed until the next call to one or the other, so the buffer is never
in a trashed state.

=item d.

The return buffer is per-thread, so it also is never overwritten by a call to
these functions from another thread;  unlike the function it replaces.

=item e.

But most importantly, they work on systems that don't have C<nl_langinfo>, such
as Windows, hence making your code more portable.  Of the fifty-some possible
items specified by the POSIX 2008 standard,
L<http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/langinfo.h.html>,
only one is completely unimplemented, though on non-Windows platforms, another
significant one is not fully implemented).  They use various techniques to
recover the other items, including calling C<L<localeconv(3)>>, and
C<L<strftime(3)>>, both of which are specified in C89, so should be always be
available.  Later C<strftime()> versions have additional capabilities.
If an item is not available on your system, this returns either the value
associated with the C locale, or simply C<"">, whichever is more appropriate.

It is important to note that, when called with an item that is recovered by
using C<localeconv>, the buffer from any previous explicit call to
C<L<localeconv(3)>> will be overwritten.  But you shouldn't be using
C<localeconv> anyway because it is is very much not thread-safe, and suffers
from the same problems outlined in item 'b.' above for the fields it returns
that are controlled by the LC_NUMERIC locale category.  Instead, avoid all of
those problems by calling L</Perl_localeconv>, which is thread-safe; or by
using the methods given in L<perlcall>  to call
L<C<POSIX::localeconv()>|POSIX/localeconv>, which is also thread-safe.

=back

The details for those items which may deviate from what this emulation returns
and what a native C<nl_langinfo()> would return are specified in
L<I18N::Langinfo>.

When using C<Perl_langinfo8> (or plain C<Perl_langinfo>) on systems that don't
have a native C<nl_langinfo()>, you must

 #include "perl_langinfo.h"

before the C<perl.h> C<#include>.  You can replace your F<langinfo.h>
C<#include> with this one.  (Doing it this way keeps out the symbols that plain
F<langinfo.h> would try to import into the namespace for code that doesn't need
it.)

=cut

*/

const char *
Perl_langinfo(const nl_item item)
{
    return Perl_langinfo8(item, NULL);
}

const char *
Perl_langinfo8(const nl_item item, utf8ness_t * utf8ness)
{
    dTHX;
    unsigned cat_index;

    PERL_ARGS_ASSERT_PERL_LANGINFO8;

    if (utf8ness) {     /* Assume for now */
        *utf8ness = UTF8NESS_IMMATERIAL;
    }

    /* Find the locale category that controls the input 'item'.  If we are not
     * paying attention to that category, instead return a default value.  Also
     * return the default value if there is no way for us to figure out the
     * correct value.  If we have some form of nl_langinfo(), we can always
     * figure it out, but lacking that, there may be alternative methods that
     * can be used to recover most of the possible items.  Some of those
     * methods need libc functions, which may or may not be available.  If
     * unavailable, we can't compute the correct value, so must here return the
     * default. */
    switch (item) {

      case CODESET:

#ifdef USE_LOCALE_CTYPE

        cat_index = LC_CTYPE_INDEX_;
        break;

#else
        return C_codeset;
#endif
#if defined(USE_LOCALE_MESSAGES) && defined(HAS_SOME_LANGINFO)

      case YESEXPR: case YESSTR: case NOEXPR: case NOSTR:
        cat_index = LC_MESSAGES_INDEX_;
        break;
#else
      case YESEXPR:   return "^[+1yY]";
      case YESSTR:    return "yes";
      case NOEXPR:    return "^[-0nN]";
      case NOSTR:     return "no";
#endif

      case CRNCYSTR:

#if  defined(USE_LOCALE_MONETARY)                                   \
 && (defined(HAS_SOME_LANGINFO) || defined(HAS_LOCALECONV))

        cat_index = LC_MONETARY_INDEX_;
        break;
#else
        return "-";
#endif

      case RADIXCHAR:

#ifdef CAN_CALCULATE_RADIX

        cat_index = LC_NUMERIC_INDEX_;
        break;
#else
        return C_decimal_point;
#endif

      case THOUSEP:

#if  defined(USE_LOCALE_NUMERIC)                                    \
 && (defined(HAS_SOME_LANGINFO) || defined(HAS_LOCALECONV))

        cat_index = LC_NUMERIC_INDEX_;
        break;
#else
        return C_thousands_sep;
#endif

/* The other possible items are all in LC_TIME. */
#ifdef USE_LOCALE_TIME

      default:
        cat_index = LC_TIME_INDEX_;
        break;

#endif
#if ! defined(USE_LOCALE_TIME) || ! defined(HAS_SOME_LANGINFO)

    /* If not using LC_TIME, hard code the rest.  Or, if there is no
     * nl_langinfo(), we use strftime() as an alternative, and it is missing
     * functionality to get every single one, so hard-code those */

      case ERA: return "";  /* Unimplemented; for use with strftime() %E
                               modifier */

      /* These formats are defined by C89, so we assume that strftime supports
       * them, and so are returned unconditionally; they may not be what the
       * locale actually says, but should give good enough results for someone
       * using them as formats (as opposed to trying to parse them to figure
       * out what the locale says).  The other format items are actually tested
       * to verify they work on the platform */
      case D_FMT:         return "%x";
      case T_FMT:         return "%X";
      case D_T_FMT:       return "%c";

#  if defined(WIN32) || ! defined(USE_LOCALE_TIME)

      /* strftime() on Windows doesn't have the POSIX (beyond C89) extensions
       * that would allow it to recover these */
      case ERA_D_FMT:     return "%x";
      case ERA_T_FMT:     return "%X";
      case ERA_D_T_FMT:   return "%c";
      case ALT_DIGITS:    return "0";

#  endif
#  ifndef USE_LOCALE_TIME

      case T_FMT_AMPM:    return "%r";
      case ABDAY_1:       return "Sun";
      case ABDAY_2:       return "Mon";
      case ABDAY_3:       return "Tue";
      case ABDAY_4:       return "Wed";
      case ABDAY_5:       return "Thu";
      case ABDAY_6:       return "Fri";
      case ABDAY_7:       return "Sat";
      case AM_STR:        return "AM";
      case PM_STR:        return "PM";
      case ABMON_1:       return "Jan";
      case ABMON_2:       return "Feb";
      case ABMON_3:       return "Mar";
      case ABMON_4:       return "Apr";
      case ABMON_5:       return "May";
      case ABMON_6:       return "Jun";
      case ABMON_7:       return "Jul";
      case ABMON_8:       return "Aug";
      case ABMON_9:       return "Sep";
      case ABMON_10:      return "Oct";
      case ABMON_11:      return "Nov";
      case ABMON_12:      return "Dec";
      case DAY_1:         return "Sunday";
      case DAY_2:         return "Monday";
      case DAY_3:         return "Tuesday";
      case DAY_4:         return "Wednesday";
      case DAY_5:         return "Thursday";
      case DAY_6:         return "Friday";
      case DAY_7:         return "Saturday";
      case MON_1:         return "January";
      case MON_2:         return "February";
      case MON_3:         return "March";
      case MON_4:         return "April";
      case MON_5:         return "May";
      case MON_6:         return "June";
      case MON_7:         return "July";
      case MON_8:         return "August";
      case MON_9:         return "September";
      case MON_10:        return "October";
      case MON_11:        return "November";
      case MON_12:        return "December";

#  endif
#endif

    } /* End of switch on item */

#ifndef USE_LOCALE

    Perl_croak_nocontext("panic: Unexpected nl_langinfo() item %d", item);
    NOT_REACHED; /* NOTREACHED */
    PERL_UNUSED_VAR(cat_index);

#else

    return my_langinfo_i(item, cat_index, query_nominal_locale_i(cat_index),
                         &PL_langinfo_buf, &PL_langinfo_bufsize, utf8ness);
#endif

}

#ifdef USE_LOCALE

/* There are several implementations of my_langinfo, depending on the
 * Configuration.  They all share the same beginning of the function */
STATIC const char *
S_my_langinfo_i(pTHX_
                const nl_item item,           /* The item to look up */
                const unsigned int cat_index, /* The locale category that
                                                 controls it */
                /* The locale to look up 'item' in. */
                const char * locale,

                /* Where to store the result, and where the size of that buffer
                 * is stored, updated on exit. retbuf_sizep may be NULL for an
                 * empty-on-entry, single use buffer whose size we don't need
                 * to keep track of */
                const char ** retbufp,
                Size_t * retbuf_sizep,

                /* If not NULL, the location to store the UTF8-ness of 'item's
                 * value, as documented */
                utf8ness_t * utf8ness)
{
    const char * retval = NULL;

    PERL_ARGS_ASSERT_MY_LANGINFO_I;
    assert(cat_index < LC_ALL_INDEX_);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "Entering my_langinfo item=%ld, using locale %s\n",
                           (long) item, locale));
/*--------------------------------------------------------------------------*/
/* Above is the common beginning to all the implementations of my_langinfo().
 * Below are the various completions.
 *
 * Some platforms don't deal well with non-ASCII strings in locale X when
 * LC_CTYPE is not in X.  (Actually it is probably when X is UTF-8 and LC_CTYPE
 * isn't, or vice versa).  There is explicit code to bring the categories into
 * sync.  This doesn't seem to be a problem with nl_langinfo(), so that
 * implementation doesn't currently worry about it.  But it is a problem on
 * Windows boxes, which don't have nl_langinfo(). */

/*--------------------------------------------------------------------------*/
#  if defined(HAS_NL_LANGINFO) /* nl_langinfo() is available.  */
#    ifdef USE_LOCALE_CTYPE

    /* This function sorts out if things actually have to be switched or not,
     * for both save and restore. */
    const char * orig_CTYPE_locale = toggle_locale_c(LC_CTYPE, locale);

#    endif

    const char * orig_switched_locale = toggle_locale_i(cat_index, locale);

    gwLOCALE_LOCK;
    retval = save_to_buffer(nl_langinfo(item), retbufp, retbuf_sizep);
    gwLOCALE_UNLOCK;

    if (utf8ness) {
        *utf8ness = get_locale_string_utf8ness_i(retval,
                                                 LOCALE_UTF8NESS_UNKNOWN,
                                                 locale, cat_index);
    }

    restore_toggled_locale_i(cat_index, orig_switched_locale);

#    ifdef USE_LOCALE_CTYPE

    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);

#    endif

    return retval;
/*--------------------------------------------------------------------------*/
#  else   /* Below, emulate nl_langinfo as best we can */

    /* The other completion is where we have to emulate nl_langinfo().  There
     * are various possibilities depending on the Configuration */

#    ifdef USE_LOCALE_CTYPE

    const char * orig_CTYPE_locale = toggle_locale_c(LC_CTYPE, locale);

#    endif

    const char * orig_switched_locale = toggle_locale_i(cat_index, locale);

    /* Here, we are in the locale we want information about */

    /* Almost all the items will have ASCII return values.  Set that here, and
     * override if necessary */
    utf8ness_t is_utf8 = UTF8NESS_IMMATERIAL;

    switch (item) {
      default:
        assert(item < 0);   /* Make sure using perl_langinfo.h */
        retval = "";
        break;

      case RADIXCHAR:

#    if      defined(HAS_SNPRINTF)                                          \
       && (! defined(HAS_LOCALECONV) || defined(TS_W32_BROKEN_LOCALECONV))

        {
            /* snprintf() can be used to find the radix character by outputting
             * a known simple floating point number to a buffer, and parsing
             * it, inferring the radix as the bytes separating the integer and
             * fractional parts.  But localeconv() is more direct, not
             * requiring inference, so use it instead of the code just below,
             * if (likely) it is available and works ok */

            char * floatbuf = NULL;
            const Size_t initial_size = 10;

            Newx(floatbuf, initial_size, char);

            /* 1.5 is exactly representable on binary computers */
            Size_t needed_size = snprintf(floatbuf, initial_size, "%.1f", 1.5);

            /* If our guess wasn't big enough, increase and try again, based on
             * the real number that snprintf() is supposed to return */
            if (UNLIKELY(needed_size >= initial_size)) {
                needed_size++;  /* insurance */
                Renew(floatbuf, needed_size, char);
                Size_t new_needed = snprintf(floatbuf, needed_size, "%.1f", 1.5);
                assert(new_needed <= needed_size);
                needed_size = new_needed;
            }

            char * s = floatbuf;
            char * e = floatbuf + needed_size;

            /* Find the '1' */
            while (s < e && *s != '1') {
                s++;
            }

            if (LIKELY(s < e)) {
                s++;
            }

            /* Find the '5' */
            char * item_start = s;
            while (s < e && *s != '5') {
                s++;
            }

            /* Everything in between is the radix string */
            if (LIKELY(s < e)) {
                *s = '\0';
                retval = save_to_buffer(item_start, retbufp, retbuf_sizep);
                Safefree(floatbuf);

                if (utf8ness) {
                    is_utf8 = get_locale_string_utf8ness_i(retval,
                                                        LOCALE_UTF8NESS_UNKNOWN,
                                                        locale, cat_index);
                }

                break;
            }

            Safefree(floatbuf);
        }

#      ifdef HAS_LOCALECONV /* snprintf() failed; drop down to use
                               localeconv() */

        /* FALLTHROUGH */

#      else                      /* snprintf() failed and no localeconv() */

        retval = C_decimal_point;
        break;

#      endif
#    endif
#    ifdef HAS_LOCALECONV

    /* These items are available from localeconv().  (To avoid using
     * TS_W32_BROKEN_LOCALECONV, one could use GetNumberFormat and
     * GetCurrencyFormat; patches welcome) */

#      define P_CS_PRECEDES    "p_cs_precedes"
#      define CURRENCY_SYMBOL  "currency_symbol"

   /* case RADIXCHAR:   // May drop down to here in some configurations */
      case THOUSEP:
      case CRNCYSTR:
       {

        /* The hash gets populated with just the field(s) related to 'item'. */
        HV * result_hv = my_localeconv(item);

        SV* string;
        if (item != CRNCYSTR) {

            /* These items have been populated with just one key => value */
            (void) hv_iterinit(result_hv);
            HE * entry = hv_iternext(result_hv);
            string = hv_iterval(result_hv, entry);
        }
        else {

            /* But CRNCYSTR localeconv() returns a slightly different value
             * than the nl_langinfo() API calls for, so have to modify this one
             * to conform.  We need another value from localeconv() to know
             * what to change it to.  my_localeconv() has populated the hash
             * with exactly both fields.  Delete this one, leaving just the
             * CRNCYSTR one in the hash */
            SV* precedes = hv_delete(result_hv,
                                     P_CS_PRECEDES, STRLENs(P_CS_PRECEDES),
                                     0);
            if (! precedes) {
                locale_panic_("my_localeconv() unexpectedly didn't return"
                              " a value for " P_CS_PRECEDES);
            }

            /* The modification is to prefix the localeconv() return with a
             * single byte, calculated as follows: */
            char prefix = (LIKELY(SvIV(precedes) != -1))
                          ? ((precedes != 0) ?  '-' : '+')

                            /* khw couldn't find any documentation that
                             * CHAR_MAX (which we modify to -1) is the signal,
                             * but cygwin uses it thusly, and it makes sense
                             * given that CHAR_MAX indicates the value isn't
                             * used, so it neither precedes nor succeeds */
                          : '.';

            /* Now get CRNCYSTR */
            (void) hv_iterinit(result_hv);
            HE * entry = hv_iternext(result_hv);
            string = hv_iterval(result_hv, entry);

            /* And perform the modification */
            Perl_sv_setpvf(aTHX_ string, "%c%s", prefix, SvPV_nolen(string));
        }

        /* Here, 'string' contains the value we want to return */
        retval = save_to_buffer(SvPV_nolen(string), retbufp, retbuf_sizep);

        if (utf8ness) {
            is_utf8 = (SvUTF8(string))
                      ? UTF8NESS_YES
                      : (is_utf8_invariant_string( (U8 *) retval,
                                                  strlen(retval)))
                        ? UTF8NESS_IMMATERIAL
                        : UTF8NESS_NO;
        }

        break;

       }

#    endif  /* Some form of localeconv */
#    ifdef HAS_STRFTIME

      /* These formats are only available in later strftime's */
      case ERA_D_FMT: case ERA_T_FMT: case ERA_D_T_FMT: case T_FMT_AMPM:

      /* The rest can be gotten from most versions of strftime(). */
      case ABDAY_1: case ABDAY_2: case ABDAY_3:
      case ABDAY_4: case ABDAY_5: case ABDAY_6: case ABDAY_7:
      case ALT_DIGITS:
      case AM_STR: case PM_STR:
      case ABMON_1: case ABMON_2: case ABMON_3: case ABMON_4:
      case ABMON_5: case ABMON_6: case ABMON_7: case ABMON_8:
      case ABMON_9: case ABMON_10: case ABMON_11: case ABMON_12:
      case DAY_1: case DAY_2: case DAY_3: case DAY_4:
      case DAY_5: case DAY_6: case DAY_7:
      case MON_1: case MON_2: case MON_3: case MON_4:
      case MON_5: case MON_6: case MON_7: case MON_8:
      case MON_9: case MON_10: case MON_11: case MON_12:
        {
            const char * format;
            bool return_format = FALSE;
            int mon = 0;
            int mday = 1;
            int hour = 6;

            GCC_DIAG_IGNORE_STMT(-Wimplicit-fallthrough);

            switch (item) {
              default:
                locale_panic_(Perl_form(aTHX_ "switch case: %d problem", item));
                NOT_REACHED; /* NOTREACHED */

              case PM_STR: hour = 18;
              case AM_STR:
                format = "%p";
                break;
              case ABDAY_7: mday++;
              case ABDAY_6: mday++;
              case ABDAY_5: mday++;
              case ABDAY_4: mday++;
              case ABDAY_3: mday++;
              case ABDAY_2: mday++;
              case ABDAY_1:
                format = "%a";
                break;
              case DAY_7: mday++;
              case DAY_6: mday++;
              case DAY_5: mday++;
              case DAY_4: mday++;
              case DAY_3: mday++;
              case DAY_2: mday++;
              case DAY_1:
                format = "%A";
                break;
              case ABMON_12: mon++;
              case ABMON_11: mon++;
              case ABMON_10: mon++;
              case ABMON_9:  mon++;
              case ABMON_8:  mon++;
              case ABMON_7:  mon++;
              case ABMON_6:  mon++;
              case ABMON_5:  mon++;
              case ABMON_4:  mon++;
              case ABMON_3:  mon++;
              case ABMON_2:  mon++;
              case ABMON_1:
                format = "%b";
                break;
              case MON_12: mon++;
              case MON_11: mon++;
              case MON_10: mon++;
              case MON_9:  mon++;
              case MON_8:  mon++;
              case MON_7:  mon++;
              case MON_6:  mon++;
              case MON_5:  mon++;
              case MON_4:  mon++;
              case MON_3:  mon++;
              case MON_2:  mon++;
              case MON_1:
                format = "%B";
                break;
              case T_FMT_AMPM:
                format = "%r";
                return_format = TRUE;
                break;
              case ERA_D_FMT:
                format = "%Ex";
                return_format = TRUE;
                break;
              case ERA_T_FMT:
                format = "%EX";
                return_format = TRUE;
                break;
              case ERA_D_T_FMT:
                format = "%Ec";
                return_format = TRUE;
                break;
              case ALT_DIGITS:
                format = "%Ow"; /* Find the alternate digit for 0 */
                break;
            }

            GCC_DIAG_RESTORE_STMT;

            /* The year was deliberately chosen so that January 1 is on the
             * first day of the week.  Since we're only getting one thing at a
             * time, it all works */
            const char * temp = my_strftime8_temp(format, 30, 30, hour, mday, mon,
                                             2011, 0, 0, 0, &is_utf8);
            retval = save_to_buffer(temp, retbufp, retbuf_sizep);
            Safefree(temp);

            /* If the item is 'ALT_DIGITS', '*retbuf' contains the alternate
             * format for wday 0.  If the value is the same as the normal 0,
             * there isn't an alternate, so clear the buffer.
             *
             * (wday was chosen because its range is all a single digit.
             * Things like tm_sec have two digits as the minimum: '00'.) */
            if (item == ALT_DIGITS && strEQ(*retbufp, "0")) {
                retval = "";
                break;
            }

            /* ALT_DIGITS is problematic.  Experiments on it showed that
             * strftime() did not always work properly when going from alt-9 to
             * alt-10.  Only a few locales have this item defined, and in all
             * of them on Linux that khw was able to find, nl_langinfo() merely
             * returned the alt-0 character, possibly doubled.  Most Unicode
             * digits are in blocks of 10 consecutive code points, so that is
             * sufficient information for such scripts, as we can infer alt-1,
             * alt-2, ....  But for a Japanese locale, a CJK ideographic 0 is
             * returned, and the CJK digits are not in code point order, so you
             * can't really infer anything.  The localedef for this locale did
             * specify the succeeding digits, so that strftime() works properly
             * on them, without needing to infer anything.  But the
             * nl_langinfo() return did not give sufficient information for the
             * caller to understand what's going on.  So until there is
             * evidence that it should work differently, this returns the alt-0
             * string for ALT_DIGITS. */

            if (return_format) {

                /* If to return the format, not the value, overwrite the buffer
                 * with it.  But some strftime()s will keep the original format
                 * if illegal, so change those to "" */
                if (strEQ(*retbufp, format)) {
                    retval = "";
                }
                else {
                    retval = format;
                }

                /* A format is always in ASCII */
                is_utf8 = UTF8NESS_IMMATERIAL;
            }

            break;
        }

#    endif
#    ifdef USE_LOCALE_CTYPE

      case CODESET:

        /* The trivial case */
        if (isNAME_C_OR_POSIX(locale)) {
            retval = C_codeset;
            break;
        }

#      ifdef WIN32

        /* This function retrieves the code page.  It is subject to change, but
         * is documented and has been stable for many releases */
        UINT ___lc_codepage_func(void);

#        ifndef WIN32_USE_FAKE_OLD_MINGW_LOCALES

        retval = save_to_buffer(Perl_form(aTHX_ "%d", ___lc_codepage_func()),
                                retbufp, retbuf_sizep);
#        else

        retval = save_to_buffer(nl_langinfo(CODESET),
                                retbufp, retbuf_sizep);
#        endif

        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "locale='%s' cp=%s\n",
                                               locale, retval));
        break;

#      else

        /* The codeset is important, but khw did not figure out a way for it to
         * be retrieved on non-Windows boxes without nl_langinfo().  But even
         * if we can't get it directly, we can usually determine if it is a
         * UTF-8 locale or not.  If it is UTF-8, we (correctly) use that for
         * the code set. */

#        if defined(HAS_MBTOWC) || defined(HAS_MBRTOWC)

        /* If libc mbtowc() evaluates the bytes that form the REPLACEMENT
         * CHARACTER as that Unicode code point, this has to be a UTF-8 locale.
         * */
        wchar_t wc = 0;
        (void) Perl_mbtowc_(aTHX_ NULL, NULL, 0);/* Reset shift state */
        int mbtowc_ret = Perl_mbtowc_(aTHX_ &wc,
                                      STR_WITH_LEN(REPLACEMENT_CHARACTER_UTF8));
        if (mbtowc_ret >= 0 && wc == UNICODE_REPLACEMENT) {
            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                   "mbtowc returned REPLACEMENT\n"));
            retval = "UTF-8";
            break;
        }

        /* Here, it isn't a UTF-8 locale. */

#        else   /* mbtowc() is not available.  The chances of this code getting
                   compiled are very small, as it is a C99 required function,
                   and we are now requiring C99; perhaps if it is a defective
                   implementation.  But if so, there are other libc functions
                   that could be used instead. */

        /* Sling together several possibilities, depending on platform
         * capabilities and what we found.
         *
         * For non-English locales or non-dollar currency locales, we likely
         * will find out whether a locale is UTF-8 or not */

        utf8ness_t is_utf8 = UTF8NESS_UNKNOWN;
        const char * scratch_buf = NULL;

#          if defined(USE_LOCALE_MONETARY) && defined(HAS_LOCALECONV)

        /* Can't use this method unless localeconv() is available, as that's
         * the way we find out the currency symbol.
         *
         * First try looking at the currency symbol (via a recursive call) to
         * see if it disambiguates things.  Often that will be in the native
         * script, and if the symbol isn't legal UTF-8, we know that the locale
         * isn't either. */
        (void) my_langinfo_c(CRNCYSTR, LC_MONETARY, locale, &scratch_buf, NULL,
                             &is_utf8);
        Safefree(scratch_buf);

#          endif
#          ifdef USE_LOCALE_TIME

        /* If we have ruled out being UTF-8, no point in checking further. */
        if (is_utf8 != UTF8NESS_NO) {

            /* But otherwise do check more.  This is done even if the currency
             * symbol looks to be UTF-8, just in case that's a false positive.
             *
             * Look at the LC_TIME entries, like the names of the months or
             * weekdays.  We quit at the first one that is illegal UTF-8 */

            utf8ness_t this_is_utf8 = UTF8NESS_UNKNOWN;
            const int times[] = {
                DAY_1, DAY_2, DAY_3, DAY_4, DAY_5, DAY_6, DAY_7,
                MON_1, MON_2, MON_3, MON_4, MON_5, MON_6, MON_7, MON_8,
                                            MON_9, MON_10, MON_11, MON_12,
                ALT_DIGITS, AM_STR, PM_STR,
                ABDAY_1, ABDAY_2, ABDAY_3, ABDAY_4, ABDAY_5, ABDAY_6,
                                                             ABDAY_7,
                ABMON_1, ABMON_2, ABMON_3, ABMON_4, ABMON_5, ABMON_6,
                ABMON_7, ABMON_8, ABMON_9, ABMON_10, ABMON_11, ABMON_12
            };

            /* The code in the recursive call can handle switching the locales,
             * but by doing it here, we avoid switching each iteration of the
             * loop */
            const char * orig_TIME_locale = toggle_locale_c(LC_TIME, locale);

            for (PERL_UINT_FAST8_T i = 0; i < C_ARRAY_LENGTH(times); i++) {
                scratch_buf = NULL;
                (void) my_langinfo_c(times[i], LC_TIME, locale, &scratch_buf,
                                     NULL, &this_is_utf8);
                Safefree(scratch_buf);
                if (this_is_utf8 == UTF8NESS_NO) {
                    is_utf8 = UTF8NESS_NO;
                    break;
                }

                if (this_is_utf8 == UTF8NESS_YES) {
                    is_utf8 = UTF8NESS_YES;
                }
            }

            /* Here we have gone through all the LC_TIME elements.  is_utf8 has
             * been set as follows:
             *      UTF8NESS_NO           If at least one isn't legal UTF-8
             *      UTF8NESS_IMMMATERIAL  If all are ASCII
             *      UTF8NESS_YES          If all are legal UTF-8 (including
             *                            ASCII), and at least one isn't
             *                            ASCII. */

            restore_toggled_locale_c(LC_TIME, orig_TIME_locale);
        }

#          endif    /* LC_TIME */

        /* If nothing examined above rules out it being UTF-8, and at least one
         * thing fits as UTF-8 (and not plain ASCII), assume the codeset is
         * UTF-8. */
        if (is_utf8 == UTF8NESS_YES) {
            retval = "UTF-8";
            break;
        }

        /* Here, nothing examined indicates that the codeset is UTF-8.  But
         * what is it?  The other locale categories are not likely to be of
         * further help:
         *
         * LC_NUMERIC   Only a few locales in the world have a non-ASCII radix
         *              or group separator.
         * LC_CTYPE     This code wouldn't be compiled if mbtowc() existed and
         *              was reliable.  This is unlikely in C99.  There are
         *              other functions that could be used instead, but are
         *              they going to exist, and be able to distinguish between
         *              UTF-8 and 8859-1?  Deal with this only if it becomes
         *              necessary.
         * LC_MESSAGES  The strings returned from strerror() would seem likely
         *              candidates, but experience has shown that many systems
         *              don't actually have translations installed for them.
         *              They are instead always in English, so everything in
         *              them is ASCII, which is of no help to us.  A Configure
         *              probe could possibly be written to see if this platform
         *              has non-ASCII error messages.  But again, wait until it
         *              turns out to be an actual problem. */

#        endif    /* ! mbtowc() */

        /* Rejoin the mbtowc available/not-available cases.
         *
         * We got here only because we haven't been able to find the codeset.
         * The only other option khw could think of is to see if the codeset is
         * part of the locale name.  This is very less than ideal; often there
         * is no code set in the name; and at other times they even lie.
         *
         * But there is an XPG standard syntax, which many locales follow:
         *
         * language[_territory[.codeset]][@modifier]
         *
         * So we take the part between the dot and any '@' */
        retval = (const char *) strchr(locale, '.');
        if (! retval) {
            retval = "";  /* Alas, no dot */
            break;
        }

        /* Don't include the dot */
        retval++;

        /* And stop before any '@' */
        const char * modifier = strchr(retval, '@');
        if (modifier) {
            char * code_set_name;
            const Size_t name_len = modifier - retval;
            Newx(code_set_name, name_len + 1, char);         /* +1 for NUL */
            my_strlcpy(code_set_name, retval, name_len + 1);
            SAVEFREEPV(code_set_name);
            retval = code_set_name;
        }

#        if defined(HAS_MBTOWC) || defined(HAS_MBRTOWC)

        /* When these functions, are available, they were tried earlier and
         * indicated that the locale did not act like a proper UTF-8 one.  So
         * if it claims to be UTF-8, it is a lie */
        if (is_codeset_name_UTF8(retval)) {
            retval = "";
            break;
        }

#        endif

        /* Otherwise the code set name is considered to be everything between
         * the dot and the '@' */
        retval = save_to_buffer(retval, retbufp, retbuf_sizep);

        break;

#      endif    /* ! WIN32 */
#    endif      /* USE_LOCALE_CTYPE */

    } /* Giant switch() of nl_langinfo() items */

    restore_toggled_locale_i(cat_index, orig_switched_locale);

#    ifdef USE_LOCALE_CTYPE
    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);
#    endif

    if (utf8ness) {
        *utf8ness = is_utf8;
    }

    return retval;

#  endif    /* All the implementations of my_langinfo() */

/*--------------------------------------------------------------------------*/

}   /* my_langinfo() */

#endif      /* USE_LOCALE */

char *
Perl_my_strftime(pTHX_ const char *fmt, int sec, int min, int hour, int mday, int mon, int year, int wday, int yday, int isdst)
{
#ifdef HAS_STRFTIME

/*
=for apidoc_section $time
=for apidoc      my_strftime

strftime(), but with a different API so that the return value is a pointer
to the formatted result (which MUST be arranged to be FREED BY THE
CALLER).  This allows this function to increase the buffer size as needed,
so that the caller doesn't have to worry about that.

On failure it returns NULL.

Note that yday and wday effectively are ignored by this function, as
mini_mktime() overwrites them.

Also note that it is always executed in the underlying C<LC_TIME> locale of
the program, giving results based on that locale.

=cut
 */
    PERL_ARGS_ASSERT_MY_STRFTIME;

    /* An empty format yields an empty result */
    const int fmtlen = strlen(fmt);
    if (fmtlen == 0) {
        char *ret;
        Newxz (ret, 1, char);
        return ret;
    }

    /* Set mytm to now */
    struct tm mytm;
    init_tm(&mytm);	/* XXX workaround - see Perl_init_tm() */

    /* Override with the passed-in values */
    mytm.tm_sec = sec;
    mytm.tm_min = min;
    mytm.tm_hour = hour;
    mytm.tm_mday = mday;
    mytm.tm_mon = mon;
    mytm.tm_year = year;
    mytm.tm_wday = wday;
    mytm.tm_yday = yday;
    mytm.tm_isdst = isdst;
    mini_mktime(&mytm);

    /* use libc to get the values for tm_gmtoff and tm_zone on platforms that
     * have them [perl #18238] */
#  if  defined(HAS_MKTIME)                                      \
   && (defined(HAS_TM_TM_GMTOFF) || defined(HAS_TM_TM_ZONE))
    struct tm mytm2;
    mytm2 = mytm;
    MKTIME_LOCK;
    mktime(&mytm2);
    MKTIME_UNLOCK;
#    ifdef HAS_TM_TM_GMTOFF
    mytm.tm_gmtoff = mytm2.tm_gmtoff;
#    endif
#    ifdef HAS_TM_TM_ZONE
    mytm.tm_zone = mytm2.tm_zone;
#    endif
#  endif
#  if defined(USE_LOCALE_CTYPE) && defined(USE_LOCALE_TIME)

    const char * orig_CTYPE_LOCALE = toggle_locale_c(LC_CTYPE,
                                                     querylocale_c(LC_TIME));
#  endif

    /* Guess an initial size for the returned string based on an expansion
     * factor of the input format, but with a minimum that should handle most
     * common cases.  If this guess is too small, we will try again with a
     * larger one */
    int bufsize = MAX(fmtlen * 2, 64);

    char *buf = NULL;   /* Makes Renew() act as Newx() on the first iteration */
    do {
        Renew(buf, bufsize, char);

        /* allowing user-supplied (rather than literal) formats is normally
         * frowned upon as a potential security risk; but this is part of the
         * API so we have to allow it (and the available formats have a much
         * lower chance of doing something bad than the ones for printf etc. */
        GCC_DIAG_IGNORE_STMT(-Wformat-nonliteral);

        STRFTIME_LOCK;
        int len = strftime(buf, bufsize, fmt, &mytm);
        STRFTIME_UNLOCK;

        GCC_DIAG_RESTORE_STMT;

        /* A non-zero return indicates success.  But to make sure we're not
         * dealing with some rogue strftime that returns how much space it
         * needs instead of 0 when there isn't enough, check that the return
         * indicates we have at least one byte of spare space (which will be
         * used for the terminating NUL). */
        if (inRANGE(len, 1, bufsize - 1)) {
            goto strftime_return;
        }

        /* There are several possible reasons for a 0 return code for a
         * non-empty format, and they are not trivial to tease apart.  This
         * issue is a known bug in the strftime() API.  What we do to cope is
         * to assume that the reason is not enough space in the buffer, so
         * increase it and try again. */
        bufsize *= 2;

        /* But don't just keep increasing the size indefinitely.  Stop when it
         * becomes obvious that the reason for failure is something besides not
         * enough space.  The most likely largest expanding format is %c.  On
         * khw's Linux box, the maximum result of this is 67 characters, in the
         * km_KH locale.  If a new script comes along that uses 4 UTF-8 bytes
         * per character, and with a similar expansion factor, that would be a
         * 268:2 byte ratio, or a bit more than 128:1 = 2**7:1.  Some strftime
         * implementations allow you to say %1000c to pad to 1000 bytes.  This
         * shows that it is impossible to implement this without a heuristic
         * (which can fail).  But it indicates we need to be generous in the
         * upper limit before failing.  The previous heuristic used was too
         * stingy.  Since the size doubles per iteration, it doesn't take many
         * to reach the limit */
    } while (bufsize < ((1 << 11) + 1) * fmtlen);

    /* Here, strftime() returned 0, and it likely wasn't for lack of space.
     * There are two possible reasons:
     *
     * First is that the result is legitimately 0 length.  This can happen
     * when the format is precisely "%p".  That is the only documented format
     * that can have an empty result. */
    if (strEQ(fmt, "%p")) {
        Renew(buf, 1, char);
        *buf = '\0';
        goto strftime_return;
    }

    /* The other reason is that the format string is malformed.  Probably it is
     * that the string is syntactically invalid for the locale.  On some
     * platforms an invalid conversion specifier '%?' (for all illegal '?') is
     * treated as a literal, but others may fail when '?' is illegal */
    Safefree(buf);
    SET_EINVAL;
    buf = NULL;

  strftime_return:

#  if defined(USE_LOCALE_CTYPE) && defined(USE_LOCALE_TIME)

    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_LOCALE);

#  endif
    return buf;

#else
    Perl_croak(aTHX_ "panic: no strftime");
#endif

}

char *
Perl_my_strftime8_temp(pTHX_ const char *fmt, int sec, int min, int hour, int mday,
                         int mon, int year, int wday, int yday, int isdst,
                         utf8ness_t * utf8ness)
{   /* Documented above */
    char * retval = my_strftime(fmt, sec, min, hour, mday, mon, year, wday,
                                yday, isdst);

    PERL_ARGS_ASSERT_MY_STRFTIME8_TEMP;

    if (utf8ness) {

#ifdef USE_LOCALE_TIME
        *utf8ness = get_locale_string_utf8ness_i(retval,
                                                 LOCALE_UTF8NESS_UNKNOWN,
                                                 NULL, LC_TIME_INDEX_);
#else
        *utf8ness = UTF8NESS_IMMATERIAL;
#endif

    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                        "fmt=%s, retval=%s", fmt,
                        ((is_utf8_string((U8 *) retval, 0))
                         ? retval
                         :_byte_dump_string((U8 *) retval, strlen(retval), 0)));
             if (utf8ness) PerlIO_printf(Perl_debug_log, "; utf8ness=%d",
                                                         (int) *utf8ness);
             PerlIO_printf(Perl_debug_log, "\n");
            );

    return retval;
}

#ifdef USE_LOCALE

STATIC void
S_give_perl_locale_control(pTHX_
#  ifdef LC_ALL
                           const char * lc_all_string,
#  else
                           const char ** locales,
#  endif
                           const line_t caller_line)
{
    PERL_UNUSED_ARG(caller_line);


    /* This is called when the program is in the global locale and are
     * switching to per-thread (if available).  And it is called at
     * initialization time to do the same.
     */

#  if defined(WIN32) && defined(USE_THREAD_SAFE_LOCALE)

    /* On Windows, convert to per-thread behavior.  This isn't necessary in
     * POSIX 2008, as the conversion gets done automatically in the
     * void_setlocale_i() calls below. */
    if (_configthreadlocale(_ENABLE_PER_THREAD_LOCALE) == -1) {
        locale_panic_("_configthreadlocale returned an error");
    }

#  endif
#  if ! defined(USE_THREAD_SAFE_LOCALE)                               \
   && ! defined(USE_POSIX_2008_LOCALE)
#    if defined(LC_ALL)
    PERL_UNUSED_ARG(lc_all_string);
#    else
    PERL_UNUSED_ARG(locales);
#    endif
#  else

    /* This platform has per-thread locale handling.  Do the conversion. */

#    if defined(LC_ALL)

    void_setlocale_c_with_caller(LC_ALL, lc_all_string, __FILE__, caller_line);

#    else

    for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
        void_setlocale_i_with_caller(i, locales[i], __FILE__, caller_line);
    }

#    endif
#  endif

    /* Finally, update our remaining records.  'true' => force recalculation.
     * This is needed because we don't know what's happened while Perl hasn't
     * had control, so we need to figure out the current state */
    new_LC_ALL(NULL, true);
}

STATIC void
S_output_check_environment_warning(pTHX_ const char * const language,
                                         const char * const lc_all,
                                         const char * const lang)
{
    PerlIO_printf(Perl_error_log,
                  "perl: warning: Please check that your locale settings:\n");

#  ifdef __GLIBC__

    PerlIO_printf(Perl_error_log, "\tLANGUAGE = %c%s%c,\n",
                                  language ? '"' : '(',
                                  language ? language : "unset",
                                  language ? '"' : ')');
#  else
    PERL_UNUSED_ARG(language);
#  endif

    PerlIO_printf(Perl_error_log, "\tLC_ALL = %c%s%c,\n",
                                  lc_all ? '"' : '(',
                                  lc_all ? lc_all : "unset",
                                  lc_all ? '"' : ')');

#  if defined(USE_ENVIRON_ARRAY)

    {
        char **e;

        /* Look through the environment for any variables of the
         * form qr/ ^ LC_ [A-Z]+ = /x, except LC_ALL which was
         * already handled above.  These are assumed to be locale
         * settings.  Output them and their values. */

        ENV_READ_LOCK;

        for (e = environ; *e; e++) {
            const STRLEN prefix_len = sizeof("LC_") - 1;
            STRLEN uppers_len;

            if (     strBEGINs(*e, "LC_")
                && ! strBEGINs(*e, "LC_ALL=")
                && (uppers_len = strspn(*e + prefix_len,
                                 "ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
                && ((*e)[prefix_len + uppers_len] == '='))
            {
                PerlIO_printf(Perl_error_log, "\t%.*s = \"%s\",\n",
                    (int) (prefix_len + uppers_len), *e,
                    *e + prefix_len + uppers_len + 1);
            }
        }

        ENV_READ_UNLOCK;
    }

#  else

    PerlIO_printf(Perl_error_log,
                  "\t(possibly more locale environment variables)\n");

#  endif

    PerlIO_printf(Perl_error_log, "\tLANG = %c%s%c\n",
                                  lang ? '"' : '(',
                                  lang ? lang : "unset",
                                  lang ? '"' : ')');
    PerlIO_printf(Perl_error_log,
                  "    are supported and installed on your system.\n");
}

#endif

/* A helper macro for the next function.  Needed because would be called in two
 * places.  Knows about the internal workings of the function */
#define GET_DESCRIPTION(trial, name)                                    \
    ((isNAME_C_OR_POSIX(name))                                          \
     ? "the standard locale"                                            \
     : ((trial == (system_default_trial)                                \
                  ? "the system default locale"                         \
                  : "a fallback locale")))

/*
 * Initialize locale awareness.
 */
int
Perl_init_i18nl10n(pTHX_ int printwarn)
{
    /* printwarn is:
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
     * This routine effectively does the following in most cases:
     *
     *      basic initialization;
     *      asserts that the compiled tables are consistent;
     *      initialize data structures;
     *      make sure we are in the global locale;
     *      setlocale(LC_ALL, "");
     *      switch to per-thread locale if applicable;
     *
     * The "" causes the locale to be set to what the environment variables at
     * the time say it should be.
     *
     * To handle possible failures, the setlocale is expanded to be like:
     *
     *      trial_locale = pre-first-trial;
     *      while (has_another_trial()) {
     *          trial_locale = next_trial();
     *          if setlocale(LC_ALL, trial_locale) {
     *              ok = true;
     *              break;
     *          }
     *
     *          had_failure = true;
     *          warn();
     *      }
     *
     *      if (had_failure) {
     *          warn_even_more();
     *          if (! ok) warn_still_more();
     *      }
     *
     * The first trial is either:
     *      ""      to examine the environment variables for the locale
     *      NULL    to use the values already set for the locale by the program
     *              embedding this perl instantiation.
     *
     * Something is wrong if this trial fails, but there is a sequence of
     * fallbacks to try should that happen.  They are given in the enum below.

     * If there is no LC_ALL defined on the system, the setlocale() above is
     * replaced by a loop setting each individual category separately.
     *
     * In a non-embeded environment, this code is executed exactly once.  It
     * sets up the global locale environment.  At the end, if some sort of
     * thread-safety is in effect, it will turn thread 0 into using that, with
     * the same locale as the global initially.  thread 0 can then change its
     * locale at will without affecting the global one.
     *
     * At destruction time, thread 0 will revert to the global locale as the
     * other threads die.
     *
     * Care must be taken in an embedded environment.  This code will be
     * executed for each instantiation.  Since it changes the global locale, it
     * could clash with another running instantiation that isn't using
     * per-thread locales.  perlembed suggests having the controlling program
     * set each instantiation's locale and set PERL_SKIP_LOCALE_INIT so this
     * code uses that without actually changing anything.  Then the onus is on
     * the controlling program to prevent any races.  The code below does
     * enough locking so as to prevent system calls from overwriting data
     * before it is safely copied here, but that isn't a general solution.
     */

#ifndef USE_LOCALE

    PERL_UNUSED_ARG(printwarn);
    const int ok = 1;

#else  /* USE_LOCALE to near the end of the routine */

    int ok = 0;

#  ifdef __GLIBC__

    const char * const language = PerlEnv_getenv("LANGUAGE");

#  else
    const char * const language = NULL;     /* Unused placeholder */
#  endif

    /* A later getenv() could zap this, so only use here */
    const char * const bad_lang_use_once = PerlEnv_getenv("PERL_BADLANG");

    const bool locwarn = (printwarn > 1
                          || (          printwarn
                              && (    ! bad_lang_use_once
                                  || (
                                         /* disallow with "" or "0" */
                                         *bad_lang_use_once
                                       && strNE("0", bad_lang_use_once)))));

#  ifndef DEBUGGING
#    define DEBUG_LOCALE_INIT(a,b,c)
#  else

    DEBUG_INITIALIZATION_set(cBOOL(PerlEnv_getenv("PERL_DEBUG_LOCALE_INIT")));

#    define DEBUG_LOCALE_INIT(cat_index, locale, result)                    \
        DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",                       \
                    setlocale_debug_string_i(cat_index, locale, result)));

#    ifdef LC_ALL
    assert(categories[LC_ALL_INDEX_] == LC_ALL);
    assert(strEQ(category_names[LC_ALL_INDEX_], "LC_ALL"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_ALL_INDEX_] == LC_ALL_MASK);
#      endif
#    endif
#  endif    /* DEBUGGING */

    /* Initialize the per-thread mbrFOO() state variables.  See POSIX.xs for
     * why these particular incantations are used. */
#  ifdef HAS_MBRLEN
    memzero(&PL_mbrlen_ps, sizeof(PL_mbrlen_ps));
#  endif
#  ifdef HAS_MBRTOWC
    memzero(&PL_mbrtowc_ps, sizeof(PL_mbrtowc_ps));
#  endif
#  ifdef HAS_WCTOMBR
    wcrtomb(NULL, L'\0', &PL_wcrtomb_ps);
#  endif
#  ifdef USE_PL_CURLOCALES

    for (unsigned int i = 0; i <= LC_ALL_INDEX_; i++) {
        PL_curlocales[i] = savepv("C");
    }

#  endif
#  if ! defined(PERL_LC_ALL_USES_NAME_VALUE_PAIRS) && defined(LC_ALL)

    LOCALE_LOCK;

    /* If we haven't done so already, translate the LC_ALL positions of
     * categories into our internal indices. */
    if (map_LC_ALL_position_to_index[0] == PERL_UINT_MAX) {

        /* Use this array, initialized by a config.h constant */
        int lc_all_category_positions[] = PERL_LC_ALL_CATEGORY_POSITIONS_INIT;
        STATIC_ASSERT_STMT(   C_ARRAY_LENGTH(lc_all_category_positions)
                           == LC_ALL_INDEX_);

        for (unsigned int i = 0;
             i < C_ARRAY_LENGTH(lc_all_category_positions);
             i++)
        {
            map_LC_ALL_position_to_index[i] =
                              get_category_index(lc_all_category_positions[i]);
        }
    }

    LOCALE_UNLOCK;

#  endif
#  ifdef USE_POSIX_2008_LOCALE

    if (! PL_C_locale_obj) {
        PL_C_locale_obj = newlocale(LC_ALL_MASK, "C", (locale_t) 0);
    }
    if (! PL_C_locale_obj) {
        locale_panic_(Perl_form(aTHX_
                                "Cannot create POSIX 2008 C locale object"));
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "created C object %p\n",
                           PL_C_locale_obj));

    /* Switch to using the POSIX 2008 interface now.  This would happen below
     * anyway, but deferring it can lead to leaks of memory that would also get
     * malloc'd in the interim */
    uselocale(PL_C_locale_obj);

#    ifdef USE_LOCALE_NUMERIC

    PL_underlying_numeric_obj = duplocale(PL_C_locale_obj);

#    endif
#  endif
#  ifdef USE_LOCALE_NUMERIC

    PL_numeric_radix_sv    = newSV(1);
    PL_underlying_radix_sv = newSV(1);
    Newxz(PL_numeric_name, 1, char);    /* Single NUL character */
    new_numeric("C", false);

#  endif
#  ifdef USE_LOCALE_COLLATE

    Newxz(PL_collation_name, 1, char);
    new_collate("C", false);

#  endif
#  ifdef USE_LOCALE_CTYPE

    Newxz(PL_ctype_name, 1, char);
    new_ctype("C", false);

#  endif

/*===========================================================================*/

    /* Now ready to override the initialization with the values that the user
     * wants.  This is done in the global locale as explained in the
     * introductory comments to this function */
    switch_to_global_locale();

    const char * const lc_all     = PerlEnv_getenv("LC_ALL");
    const char * const lang       = PerlEnv_getenv("LANG");

    /* We try each locale in the enum, in order, until we get one that works,
     * or exhaust the list.  Normally the loop is executed just once.
     *
     * Each enum value is +1 from the previous */
    typedef enum {
            dummy_trial       = -1,
            environment_trial =  0,     /* "" or NULL; code below assumes value
                                           0 is the first real trial */
            LC_ALL_trial,               /* ENV{LC_ALL} */
            LANG_trial,                 /* ENV{LANG} */
            system_default_trial,       /* Windows .ACP */
            C_trial,                    /* C locale */
            beyond_final_trial,
    } trials;

    trials trial;
    SSize_t already_checked = 0;
    const char * checked[C_trial];

#  ifdef LC_ALL
    const char * lc_all_string;
#  else
    const char * curlocales[LC_ALL_INDEX_];
#  endif

    /* Loop through the initial setting and all the possible fallbacks,
     * breaking out of the loop on success */
    trial = dummy_trial;
    while (trial != beyond_final_trial) {

        /* Each time through compute the next trial to use based on the one in
         * the previous iteration and switch to the new one.  This enforces the
         * order in which the fallbacks are applied */
      next_trial:
        trial = (trials) ((int) trial + 1);     /* Casts are needed for g++ */

        const char * locale = NULL;

        /* Set up the parameters for this trial */
        switch (trial) {
          case dummy_trial:
            locale_panic_("Unexpectedly got 'dummy_trial");
            break;

          case environment_trial:
            /* This is either "" to get the values from the environment, or
             * NULL if the calling program has initialized the values already.
             * */
            locale = (PerlEnv_getenv("PERL_SKIP_LOCALE_INIT"))
                     ? NULL
                     : "";
            break;

          case LC_ALL_trial:
            if (! lc_all || strEQ(lc_all, "")) {
                continue;   /* No-op */
            }

            locale = lc_all;
            break;

          case LANG_trial:
            if (! lang || strEQ(lang, "")) {
                continue;   /* No-op */
            }

            locale = lang;
            break;

          case system_default_trial:

#  if ! defined(WIN32) || ! defined(LC_ALL)

            continue;   /* No-op */

#  else
            /* For Windows, we also try the system default locale before "C".
             * (If there exists a Windows without LC_ALL we skip this because
             * it gets too complicated.  For those, "C" is the next fallback
             * possibility). */
            locale = ".ACP";
#  endif
            break;

          case C_trial:
            locale = "C";
            break;

          case beyond_final_trial:
            continue;     /* No-op, causes loop to exit */
        }

        /* If the locale is a substantive name, don't try the same locale
         * twice. */
        if (locale && strNE(locale, "")) {
            for (unsigned int i = 0; i < already_checked; i++) {
                if (strEQ(checked[i], locale)) {
                    goto next_trial;
                }
            }

            /* And, for future iterations, indicate we've tried this locale */
            checked[already_checked] = savepv(locale);
            SAVEFREEPV(checked[already_checked]);
            already_checked++;
        }

#  ifdef LC_ALL

        STDIZED_SETLOCALE_LOCK;
        lc_all_string = savepv(stdized_setlocale(LC_ALL, locale));
        STDIZED_SETLOCALE_UNLOCK;

        DEBUG_LOCALE_INIT(LC_ALL_INDEX_, locale, lc_all_string);

        if (LIKELY(lc_all_string)) {     /* Succeeded */
            ok = 1;
            break;
        }

        if (trial == 0 && locwarn) {
            PerlIO_printf(Perl_error_log,
                                  "perl: warning: Setting locale failed.\n");
            output_check_environment_warning(language, lc_all, lang);
        }

#  else /* Below is ! LC_ALL */

        bool setlocale_failure = FALSE;  /* This trial hasn't failed so far */
        bool dowarn = trial == 0 && locwarn;

        for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
            STDIZED_SETLOCALE_LOCK;
            curlocales[j] = savepv(stdized_setlocale(categories[j], locale));
            STDIZED_SETLOCALE_UNLOCK;

            DEBUG_LOCALE_INIT(j, locale, curlocales[j]);

            if (UNLIKELY(! curlocales[j])) {
                setlocale_failure = TRUE;

                /* If are going to warn below, continue to loop so all failures
                 * are included in the message */
                if (! dowarn) {
                    break;
                }
            }
        }

        if (LIKELY(! setlocale_failure)) {  /* All succeeded */
            ok = 1;
            break;  /* Exit trial_locales loop */
        }

        /* Here, this trial failed */

        if (dowarn) {
            PerlIO_printf(Perl_error_log,
                "perl: warning: Setting locale failed for the categories:\n");

            for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
                if (! curlocales[j]) {
                    PerlIO_printf(Perl_error_log, "\t%s\n", category_names[j]);
                }
            }

            output_check_environment_warning(language, lc_all, lang);
        }   /* end of warning on first failure */

#  endif /* LC_ALL */

    }   /* end of looping through the trial locales */

    /* If we had to do more than the first trial, it means that one failed, and
     * we may need to output a warning, and, if none worked, do more */
    if (UNLIKELY(trial != 0)) {
        if (locwarn) {
            const char * description = "a fallback locale";
            const char * name = NULL;;

            /* If we didn't find a good fallback, list all we tried */
            if (! ok && already_checked > 0) {
                PerlIO_printf(Perl_error_log, "perl: warning: Failed to fall"
                                              " back to ");
                if (already_checked > 1) {  /* more than one was tried */
                    PerlIO_printf(Perl_error_log, "any of:\n");
                }

                while (already_checked > 0) {
                    name = checked[--already_checked];
                    description = GET_DESCRIPTION(trial, name);
                    PerlIO_printf(Perl_error_log, "%s (\"%s\")\n",
                                                  description, name);
                }
            }

            if (ok) {

                /* Here, a fallback worked.  So we have saved its name, and the
                 * trial that succeeded is still valid */
#  ifdef LC_ALL
                const char * individ_locales[LC_ALL_INDEX_] = { NULL };

                /* Even though we know the valid string for LC_ALL that worked,
                 * translate it into our internal format, which is the
                 * name=value pairs notation.  This is easier for a human to
                 * decipher than the positional notation.  Some platforms
                 * can return "C C C C C C" for LC_ALL.  This code also
                 * standardizes that result into plain "C". */
                switch (parse_LC_ALL_string(lc_all_string,
                                            (const char **) &individ_locales,
                                            false,   /* Return only [0] if
                                                        suffices */
                                            false,   /* Don't panic on error */
                                            __LINE__))
                {
                  case invalid:

                    /* Here, the parse failed, which shouldn't happen, but if
                     * it does, we have an easy fallback that allows us to keep
                     * going. */
                    name = lc_all_string;
                    break;

                  case no_array:    /* The original is a single locale */
                    name = lc_all_string;
                    break;

                  case only_element_0:  /* element[0] is a single locale valid
                                           for all categories */
                    SAVEFREEPV(individ_locales[0]);
                    name = individ_locales[0];
                    break;

                  case full_array:
                    name = calculate_LC_ALL_string(individ_locales,
                                                   INTERNAL_FORMAT,
                                                   __LINE__);
                    for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
                        Safefree(individ_locales[j]);
                    }
                }
#  else
                name = calculate_LC_ALL_string(curlocales,
                                               INTERNAL_FORMAT,
                                               __LINE__);
#  endif
                description = GET_DESCRIPTION(trial, name);
            }
            else {

                /* Nothing seems to be working, yet we want to continue
                 * executing.  It may well be that locales are mostly
                 * irrelevant to this particular program, and there must be
                 * some locale underlying the program.  Figure it out as best
                 * we can, by querying the system's current locale */

#  ifdef LC_ALL

                STDIZED_SETLOCALE_LOCK;
                name = stdized_setlocale(LC_ALL, NULL);
                STDIZED_SETLOCALE_UNLOCK;

                if (UNLIKELY(! name)) {
                    name = "locale name not determinable";
                }

#  else /* Below is ! LC_ALL */

                const char * system_locales[LC_ALL_INDEX_] = { NULL };

                for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
                    STDIZED_SETLOCALE_LOCK;
                    system_locales[j] = savepv(stdized_setlocale(categories[j],
                                                                 NULL));
                    STDIZED_SETLOCALE_UNLOCK;

                    if (UNLIKELY(! system_locales[j])) {
                        system_locales[j] = "not determinable";
                    }
                }

                /* We use the name=value form for the string, as that is more
                 * human readable than the positional notation */
                name = calculate_LC_ALL_string(system_locales,
                                               INTERNAL_FORMAT,
                                               __LINE__);
                description = "what the system says";

                for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
                    Safefree(system_locales[j]);
                }
#  endif
            }

            PerlIO_printf(Perl_error_log,
                          "perl: warning: Falling back to %s (\"%s\").\n",
                          description, name);

            /* Here, ok being true indicates that the first attempt failed, but
             * a fallback succeeded; false => nothing working.  Translate to
             * API return values. */
            ok = (ok) ? 0 : -1;
        }
    }

#  ifdef LC_ALL

    give_perl_locale_control(lc_all_string, __LINE__);
    Safefree(lc_all_string);

#  else

    give_perl_locale_control((const char **) &curlocales, __LINE__);

    for (unsigned int j = 0; j < LC_ALL_INDEX_; j++) {
        Safefree(curlocales[j]);
    }

#  endif
#  if defined(USE_PERLIO) && defined(USE_LOCALE_CTYPE)

    /* Set PL_utf8locale to TRUE if using PerlIO _and_ the current LC_CTYPE
     * locale is UTF-8.  give_perl_locale_control() just above has already
     * calculated the latter value and saved it in PL_in_utf8_CTYPE_locale. If
     * both PL_utf8locale and PL_unicode (set by -C or by $ENV{PERL_UNICODE})
     * are true, perl.c:S_parse_body() will turn on the PerlIO :utf8 layer on
     * STDIN, STDOUT, STDERR, _and_ the default open discipline.  */
    PL_utf8locale = PL_in_utf8_CTYPE_locale;

    /* Set PL_unicode to $ENV{PERL_UNICODE} if using PerlIO.
       This is an alternative to using the -C command line switch
       (the -C if present will override this). */
    {
         const char *p = PerlEnv_getenv("PERL_UNICODE");
         PL_unicode = p ? parse_unicode_opts(&p) : 0;
         if (PL_unicode & PERL_UNICODE_UTF8CACHEASSERT_FLAG)
             PL_utf8cache = -1;
    }

#  endif
#  if defined(USE_POSIX_2008_LOCALE) && defined(MULTIPLICITY)
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "finished Perl_init_i18nl10n; actual obj=%p,"
                           " expected obj=%p, initial=%s\n",
                           uselocale(0), PL_cur_locale_obj,
                           get_LC_ALL_display()));
#  endif

    /* So won't continue to output stuff */
    DEBUG_INITIALIZATION_set(FALSE);

#endif /* USE_LOCALE */

    return ok;
}

#undef GET_DESCRIPTION
#ifdef USE_LOCALE_COLLATE

STATIC void
S_compute_collxfrm_coefficients(pTHX)
{

    /* A locale collation definition includes primary, secondary, tertiary,
     * etc. weights for each character.  To sort, the primary weights are used,
     * and only if they compare equal, then the secondary weights are used, and
     * only if they compare equal, then the tertiary, etc.
     *
     * strxfrm() works by taking the input string, say ABC, and creating an
     * output transformed string consisting of first the primary weights,
     * A¹B¹C¹ followed by the secondary ones, A²B²C²; and then the tertiary,
     * etc, yielding A¹B¹C¹ A²B²C² A³B³C³ ....  Some characters may not have
     * weights at every level.  In our example, let's say B doesn't have a
     * tertiary weight, and A doesn't have a secondary weight.  The constructed
     * string is then going to be
     *  A¹B¹C¹ B²C² A³C³ ....
     * This has the desired effect that strcmp() will look at the secondary or
     * tertiary weights only if the strings compare equal at all higher
     * priority weights.  The spaces shown here, like in
     *  "A¹B¹C¹ A²B²C² "
     * are not just for readability.  In the general case, these must actually
     * be bytes, which we will call here 'separator weights'; and they must be
     * smaller than any other weight value, but since these are C strings, only
     * the terminating one can be a NUL (some implementations may include a
     * non-NUL separator weight just before the NUL).  Implementations tend to
     * reserve 01 for the separator weights.  They are needed so that a shorter
     * string's secondary weights won't be misconstrued as primary weights of a
     * longer string, etc.  By making them smaller than any other weight, the
     * shorter string will sort first.  (Actually, if all secondary weights are
     * smaller than all primary ones, there is no need for a separator weight
     * between those two levels, etc.)
     *
     * The length of the transformed string is roughly a linear function of the
     * input string.  It's not exactly linear because some characters don't
     * have weights at all levels.  When we call strxfrm() we have to allocate
     * some memory to hold the transformed string.  The calculations below try
     * to find coefficients 'm' and 'b' for this locale so that m*x + b equals
     * how much space we need, given the size of the input string in 'x'.  If
     * we calculate too small, we increase the size as needed, and call
     * strxfrm() again, but it is better to get it right the first time to
     * avoid wasted expensive string transformations.
     *
     * We use the string below to find how long the transformation of it is.
     * Almost all locales are supersets of ASCII, or at least the ASCII
     * letters.  We use all of them, half upper half lower, because if we used
     * fewer, we might hit just the ones that are outliers in a particular
     * locale.  Most of the strings being collated will contain a preponderance
     * of letters, and even if they are above-ASCII, they are likely to have
     * the same number of weight levels as the ASCII ones.  It turns out that
     * digits tend to have fewer levels, and some punctuation has more, but
     * those are relatively sparse in text, and khw believes this gives a
     * reasonable result, but it could be changed if experience so dictates. */
    const char longer[] = "ABCDEFGHIJKLMnopqrstuvwxyz";
    char * x_longer;        /* Transformed 'longer' */
    Size_t x_len_longer;    /* Length of 'x_longer' */

    char * x_shorter;   /* We also transform a substring of 'longer' */
    Size_t x_len_shorter;

    PL_in_utf8_COLLATE_locale = (PL_collation_standard)
                                ? 0
                                : is_locale_utf8(PL_collation_name);
    PL_strxfrm_NUL_replacement = '\0';
    PL_strxfrm_max_cp = 0;

    /* mem_collxfrm_() is used get the transformation (though here we are
     * interested only in its length).  It is used because it has the
     * intelligence to handle all cases, but to work, it needs some values of
     * 'm' and 'b' to get it started.  For the purposes of this calculation we
     * use a very conservative estimate of 'm' and 'b'.  This assumes a weight
     * can be multiple bytes, enough to hold any UV on the platform, and there
     * are 5 levels, 4 weight bytes, and a trailing NUL.  */
    PL_collxfrm_base = 5;
    PL_collxfrm_mult = 5 * sizeof(UV);

    /* Find out how long the transformation really is */
    x_longer = mem_collxfrm_(longer,
                             sizeof(longer) - 1,
                             &x_len_longer,

                             /* We avoid converting to UTF-8 in the called
                              * function by telling it the string is in UTF-8
                              * if the locale is a UTF-8 one.  Since the string
                              * passed here is invariant under UTF-8, we can
                              * claim it's UTF-8 even if it isn't.  */
                              PL_in_utf8_COLLATE_locale);
    Safefree(x_longer);

    /* Find out how long the transformation of a substring of 'longer' is.
     * Together the lengths of these transformations are sufficient to
     * calculate 'm' and 'b'.  The substring is all of 'longer' except the
     * first character.  This minimizes the chances of being swayed by outliers
     * */
    x_shorter = mem_collxfrm_(longer + 1,
                              sizeof(longer) - 2,
                              &x_len_shorter,
                              PL_in_utf8_COLLATE_locale);
    Safefree(x_shorter);

    /* If the results are nonsensical for this simple test, the whole locale
     * definition is suspect.  Mark it so that locale collation is not active
     * at all for it.  XXX Should we warn? */
    if (   x_len_shorter == 0
        || x_len_longer == 0
        || x_len_shorter >= x_len_longer)
    {
        PL_collxfrm_mult = 0;
        PL_collxfrm_base = 1;
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                "Disabling locale collation for LC_COLLATE='%s';"
                " length for shorter sample=%zu; longer=%zu\n",
                PL_collation_name, x_len_shorter, x_len_longer));
    }
    else {
        SSize_t base;       /* Temporary */

        /* We have both: m * strlen(longer)  + b = x_len_longer
         *               m * strlen(shorter) + b = x_len_shorter;
         * subtracting yields:
         *          m * (strlen(longer) - strlen(shorter))
         *                             = x_len_longer - x_len_shorter
         * But we have set things up so that 'shorter' is 1 byte smaller than
         * 'longer'.  Hence:
         *          m = x_len_longer - x_len_shorter
         *
         * But if something went wrong, make sure the multiplier is at least 1.
         */
        if (x_len_longer > x_len_shorter) {
            PL_collxfrm_mult = (STRLEN) x_len_longer - x_len_shorter;
        }
        else {
            PL_collxfrm_mult = 1;
        }

        /*     mx + b = len
         * so:      b = len - mx
         * but in case something has gone wrong, make sure it is non-negative
         * */
        base = x_len_longer - PL_collxfrm_mult * (sizeof(longer) - 1);
        if (base < 0) {
            base = 0;
        }

        /* Add 1 for the trailing NUL */
        PL_collxfrm_base = base + 1;
    }

    DEBUG_L(PerlIO_printf(Perl_debug_log,
                          "?UTF-8 locale=%d; x_len_shorter=%zu, "
                          "x_len_longer=%zu,"
                          " collate multipler=%zu, collate base=%zu\n",
                          PL_in_utf8_COLLATE_locale,
                          x_len_shorter, x_len_longer,
                          PL_collxfrm_mult, PL_collxfrm_base));
}

char *
Perl_mem_collxfrm_(pTHX_ const char *input_string,
                         STRLEN len,    /* Length of 'input_string' */
                         STRLEN *xlen,  /* Set to length of returned string
                                           (not including the collation index
                                           prefix) */
                         bool utf8      /* Is the input in UTF-8? */
                   )
{
    /* mem_collxfrm_() is like strxfrm() but with two important differences.
     * First, it handles embedded NULs. Second, it allocates a bit more memory
     * than needed for the transformed data itself.  The real transformed data
     * begins at offset COLLXFRM_HDR_LEN.  *xlen is set to the length of that,
     * and doesn't include the collation index size.
     *
     * It is the caller's responsibility to eventually free the memory returned
     * by this function.
     *
     * Please see sv_collxfrm() to see how this is used. */

#  define COLLXFRM_HDR_LEN    sizeof(PL_collation_ix)

    char * s = (char *) input_string;
    STRLEN s_strlen = strlen(input_string);
    char *xbuf = NULL;
    STRLEN xAlloc;          /* xalloc is a reserved word in VC */
    STRLEN length_in_chars;
    bool first_time = TRUE; /* Cleared after first loop iteration */

#  ifdef USE_LOCALE_CTYPE
        const char * orig_CTYPE_locale = NULL;
#  endif

#  if defined(USE_POSIX_2008_LOCALE) && defined HAS_STRXFRM_L
    locale_t constructed_locale = (locale_t) 0;
#  endif

    PERL_ARGS_ASSERT_MEM_COLLXFRM_;

    /* Must be NUL-terminated */
    assert(*(input_string + len) == '\0');

    if (PL_collxfrm_mult == 0) {     /* unknown or bad */
        if (PL_collxfrm_base != 0) { /* bad collation => skip */
            DEBUG_L(PerlIO_printf(Perl_debug_log,
                          "mem_collxfrm_: locale's collation is defective\n"));
            goto bad;
        }

        /* (mult, base) == (0,0) means we need to calculate mult and base
         * before proceeding */
        S_compute_collxfrm_coefficients(aTHX);
    }

    /* Replace any embedded NULs with the control that sorts before any others.
     * This will give as good as possible results on strings that don't
     * otherwise contain that character, but otherwise there may be
     * less-than-perfect results with that character and NUL.  This is
     * unavoidable unless we replace strxfrm with our own implementation. */
    if (UNLIKELY(s_strlen < len)) {   /* Only execute if there is an embedded
                                         NUL */
        char * e = s + len;
        char * sans_nuls;
        STRLEN sans_nuls_len;
        int try_non_controls;
        char this_replacement_char[] = "?\0";   /* Room for a two-byte string,
                                                   making sure 2nd byte is NUL.
                                                 */
        STRLEN this_replacement_len;

        /* If we don't know what non-NUL control character sorts lowest for
         * this locale, find it */
        if (PL_strxfrm_NUL_replacement == '\0') {
            int j;
            char * cur_min_x = NULL;    /* The min_char's xfrm, (except it also
                                           includes the collation index
                                           prefixed. */

            DEBUG_Lv(PerlIO_printf(Perl_debug_log, "Looking to replace NUL\n"));

            /* Unlikely, but it may be that no control will work to replace
             * NUL, in which case we instead look for any character.  Controls
             * are preferred because collation order is, in general, context
             * sensitive, with adjoining characters affecting the order, and
             * controls are less likely to have such interactions, allowing the
             * NUL-replacement to stand on its own.  (Another way to look at it
             * is to imagine what would happen if the NUL were replaced by a
             * combining character; it wouldn't work out all that well.) */
            for (try_non_controls = 0;
                 try_non_controls < 2;
                 try_non_controls++)
            {

#  ifdef USE_LOCALE_CTYPE

                /* In this case we use isCNTRL_LC() below, which relies on
                 * LC_CTYPE, so that must be switched to correspond with the
                 * LC_COLLATE locale */
                if (! try_non_controls && ! PL_in_utf8_COLLATE_locale) {
                    orig_CTYPE_locale = toggle_locale_c(LC_CTYPE,
                                                        PL_collation_name);
                }
#  endif
                /* Look through all legal code points (NUL isn't) */
                for (j = 1; j < 256; j++) {
                    char * x;       /* j's xfrm plus collation index */
                    STRLEN x_len;   /* length of 'x' */
                    STRLEN trial_len = 1;
                    char cur_source[] = { '\0', '\0' };

                    /* Skip non-controls the first time through the loop.  The
                     * controls in a UTF-8 locale are the L1 ones */
                    if (! try_non_controls && (PL_in_utf8_COLLATE_locale)
                                               ? ! isCNTRL_L1(j)
                                               : ! isCNTRL_LC(j))
                    {
                        continue;
                    }

                    /* Create a 1-char string of the current code point */
                    cur_source[0] = (char) j;

                    /* Then transform it */
                    x = mem_collxfrm_(cur_source, trial_len, &x_len,
                                      0 /* The string is not in UTF-8 */);

                    /* Ignore any character that didn't successfully transform.
                     * */
                    if (! x) {
                        continue;
                    }

                    /* If this character's transformation is lower than
                     * the current lowest, this one becomes the lowest */
                    if (   cur_min_x == NULL
                        || strLT(x         + COLLXFRM_HDR_LEN,
                                 cur_min_x + COLLXFRM_HDR_LEN))
                    {
                        PL_strxfrm_NUL_replacement = j;
                        Safefree(cur_min_x);
                        cur_min_x = x;
                    }
                    else {
                        Safefree(x);
                    }
                } /* end of loop through all 255 characters */

#  ifdef USE_LOCALE_CTYPE
                restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);
#  endif

                /* Stop looking if found */
                if (cur_min_x) {
                    break;
                }

                /* Unlikely, but possible, if there aren't any controls that
                 * work in the locale, repeat the loop, looking for any
                 * character that works */
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                "mem_collxfrm_: No control worked.  Trying non-controls\n"));
            } /* End of loop to try first the controls, then any char */

            if (! cur_min_x) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                    "mem_collxfrm_: Couldn't find any character to replace"
                    " embedded NULs in locale %s with", PL_collation_name));
                goto bad;
            }

            DEBUG_L(PerlIO_printf(Perl_debug_log,
                    "mem_collxfrm_: Replacing embedded NULs in locale %s with "
                    "0x%02X\n", PL_collation_name, PL_strxfrm_NUL_replacement));

            Safefree(cur_min_x);
        } /* End of determining the character that is to replace NULs */

        /* If the replacement is variant under UTF-8, it must match the
         * UTF8-ness of the original */
        if ( ! UVCHR_IS_INVARIANT(PL_strxfrm_NUL_replacement) && utf8) {
            this_replacement_char[0] =
                                UTF8_EIGHT_BIT_HI(PL_strxfrm_NUL_replacement);
            this_replacement_char[1] =
                                UTF8_EIGHT_BIT_LO(PL_strxfrm_NUL_replacement);
            this_replacement_len = 2;
        }
        else {
            this_replacement_char[0] = PL_strxfrm_NUL_replacement;
            /* this_replacement_char[1] = '\0' was done at initialization */
            this_replacement_len = 1;
        }

        /* The worst case length for the replaced string would be if every
         * character in it is NUL.  Multiply that by the length of each
         * replacement, and allow for a trailing NUL */
        sans_nuls_len = (len * this_replacement_len) + 1;
        Newx(sans_nuls, sans_nuls_len, char);
        *sans_nuls = '\0';

        /* Replace each NUL with the lowest collating control.  Loop until have
         * exhausted all the NULs */
        while (s + s_strlen < e) {
            my_strlcat(sans_nuls, s, sans_nuls_len);

            /* Do the actual replacement */
            my_strlcat(sans_nuls, this_replacement_char, sans_nuls_len);

            /* Move past the input NUL */
            s += s_strlen + 1;
            s_strlen = strlen(s);
        }

        /* And add anything that trails the final NUL */
        my_strlcat(sans_nuls, s, sans_nuls_len);

        /* Switch so below we transform this modified string */
        s = sans_nuls;
        len = strlen(s);
    } /* End of replacing NULs */

    /* Make sure the UTF8ness of the string and locale match */
    if (utf8 != PL_in_utf8_COLLATE_locale) {
        /* XXX convert above Unicode to 10FFFF? */
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
                        char cur_source[] = { '\0', '\0' };

                        /* Create a 1-char string of the current code point */
                        cur_source[0] = (char) j;

                        /* Then transform it */
                        x = mem_collxfrm_(cur_source, 1, &x_len, FALSE);

                        /* If something went wrong (which it shouldn't), just
                         * ignore this code point */
                        if (! x) {
                            continue;
                        }

                        /* If this character's transformation is higher than
                         * the current highest, this one becomes the highest */
                        if (   cur_max_x == NULL
                            || strGT(x         + COLLXFRM_HDR_LEN,
                                     cur_max_x + COLLXFRM_HDR_LEN))
                        {
                            PL_strxfrm_max_cp = j;
                            Safefree(cur_max_x);
                            cur_max_x = x;
                        }
                        else {
                            Safefree(x);
                        }
                    }

                    if (! cur_max_x) {
                        DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "mem_collxfrm_: Couldn't find any character to"
                            " replace above-Latin1 chars in locale %s with",
                            PL_collation_name));
                        goto bad;
                    }

                    DEBUG_L(PerlIO_printf(Perl_debug_log,
                            "mem_collxfrm_: highest 1-byte collating character"
                            " in locale %s is 0x%02X\n",
                            PL_collation_name,
                            PL_strxfrm_max_cp));

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
                    char * e = (char *) t + len;

                    for (i = 0; i < len; i+= UTF8SKIP(t + i)) {
                        U8 cur_char = t[i];
                        if (UTF8_IS_INVARIANT(cur_char)) {
                            s[d++] = cur_char;
                        }
                        else if (UTF8_IS_NEXT_CHAR_DOWNGRADEABLE(t + i, e)) {
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
    if (UNLIKELY(! xbuf)) {
        DEBUG_L(PerlIO_printf(Perl_debug_log,
                      "mem_collxfrm_: Couldn't malloc %zu bytes\n", xAlloc));
        goto bad;
    }

    /* Store the collation id */
    *(PERL_UINTMAX_T *)xbuf = PL_collation_ix;

#  if defined(USE_POSIX_2008_LOCALE) && defined HAS_STRXFRM_L
#    ifdef USE_LOCALE_CTYPE

    constructed_locale = newlocale(LC_CTYPE_MASK, PL_collation_name,
                                   duplocale(use_curlocale_scratch()));
#    else

    constructed_locale = duplocale(use_curlocale_scratch());

#    endif
#    define my_strxfrm(dest, src, n)  strxfrm_l(dest, src, n,           \
                                                constructed_locale)
#    define CLEANUP_STRXFRM                                             \
        STMT_START {                                                    \
            if (constructed_locale != (locale_t) 0)                     \
                freelocale(constructed_locale);                         \
        } STMT_END
#  else
#    define my_strxfrm(dest, src, n)  strxfrm(dest, src, n)
#    ifdef USE_LOCALE_CTYPE

    orig_CTYPE_locale = toggle_locale_c(LC_CTYPE, PL_collation_name);

#      define CLEANUP_STRXFRM                                           \
                restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale)
#    else
#      define CLEANUP_STRXFRM  NOOP
#    endif
#  endif

    /* Then the transformation of the input.  We loop until successful, or we
     * give up */
    for (;;) {

        errno = 0;
        *xlen = my_strxfrm(xbuf + COLLXFRM_HDR_LEN,
                           s,
                           xAlloc - COLLXFRM_HDR_LEN);


        /* If the transformed string occupies less space than we told strxfrm()
         * was available, it means it transformed the whole string. */
        if (*xlen < xAlloc - COLLXFRM_HDR_LEN) {

            /* But there still could have been a problem */
            if (errno != 0) {
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                       "strxfrm failed for LC_COLLATE=%s; errno=%d, input=%s\n",
                       PL_collation_name, errno,
                       _byte_dump_string((U8 *) s, len, 0)));
                goto bad;
            }

            /* Here, the transformation was successful.  Some systems include a
             * trailing NUL in the returned length.  Ignore it, using a loop in
             * case multiple trailing NULs are returned. */
            while (   (*xlen) > 0
                   && *(xbuf + COLLXFRM_HDR_LEN + (*xlen) - 1) == '\0')
            {
                (*xlen)--;
            }

            /* If the first try didn't get it, it means our prediction was low.
             * Modify the coefficients so that we predict a larger value in any
             * future transformations */
            if (! first_time) {
                STRLEN needed = *xlen + 1;   /* +1 For trailing NUL */
                STRLEN computed_guess = PL_collxfrm_base
                                      + (PL_collxfrm_mult * length_in_chars);

                /* On zero-length input, just keep current slope instead of
                 * dividing by 0 */
                const STRLEN new_m = (length_in_chars != 0)
                                     ? needed / length_in_chars
                                     : PL_collxfrm_mult;

                DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                    "initial size of %zu bytes for a length "
                    "%zu string was insufficient, %zu needed\n",
                    computed_guess, length_in_chars, needed));

                /* If slope increased, use it, but discard this result for
                 * length 1 strings, as we can't be sure that it's a real slope
                 * change */
                if (length_in_chars > 1 && new_m  > PL_collxfrm_mult) {

#  ifdef DEBUGGING

                    STRLEN old_m = PL_collxfrm_mult;
                    STRLEN old_b = PL_collxfrm_base;

#  endif

                    PL_collxfrm_mult = new_m;
                    PL_collxfrm_base = 1;   /* +1 For trailing NUL */
                    computed_guess = PL_collxfrm_base
                                    + (PL_collxfrm_mult * length_in_chars);
                    if (computed_guess < needed) {
                        PL_collxfrm_base += needed - computed_guess;
                    }

                    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                    "slope is now %zu; was %zu, base "
                        "is now %zu; was %zu\n",
                        PL_collxfrm_mult, old_m,
                        PL_collxfrm_base, old_b));
                }
                else {  /* Slope didn't change, but 'b' did */
                    const STRLEN new_b = needed
                                        - computed_guess
                                        + PL_collxfrm_base;
                    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                        "base is now %zu; was %zu\n", new_b, PL_collxfrm_base));
                    PL_collxfrm_base = new_b;
                }
            }

            break;
        }

        if (UNLIKELY(*xlen >= PERL_INT_MAX)) {
            DEBUG_L(PerlIO_printf(Perl_debug_log,
                  "mem_collxfrm_: Needed %zu bytes, max permissible is %u\n",
                  *xlen, PERL_INT_MAX));
            goto bad;
        }

        /* A well-behaved strxfrm() returns exactly how much space it needs
         * (usually not including the trailing NUL) when it fails due to not
         * enough space being provided.  Assume that this is the case unless
         * it's been proven otherwise */
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
                * Increase the buffer size by a fixed percentage and try again.
                * */
            xAlloc += (xAlloc / 4) + 1;
            PL_strxfrm_is_behaved = FALSE;

            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                     "mem_collxfrm_ required more space than previously"
                     " calculated for locale %s, trying again with new"
                     " guess=%zu+%zu\n",
                PL_collation_name,  COLLXFRM_HDR_LEN,
                     xAlloc - COLLXFRM_HDR_LEN));
        }

        Renew(xbuf, xAlloc, char);
        if (UNLIKELY(! xbuf)) {
            DEBUG_L(PerlIO_printf(Perl_debug_log,
                      "mem_collxfrm_: Couldn't realloc %zu bytes\n", xAlloc));
            goto bad;
        }

        first_time = FALSE;
    }

    CLEANUP_STRXFRM;

    DEBUG_L(print_collxfrm_input_and_return(s, s + len, xbuf, *xlen, utf8));

    /* Free up unneeded space; retain enough for trailing NUL */
    Renew(xbuf, COLLXFRM_HDR_LEN + *xlen + 1, char);

    if (s != input_string) {
        Safefree(s);
    }

    return xbuf;

  bad:

    CLEANUP_STRXFRM;
    DEBUG_L(print_collxfrm_input_and_return(s, s + len, NULL, 0, utf8));

    Safefree(xbuf);
    if (s != input_string) {
        Safefree(s);
    }
    *xlen = 0;

    return NULL;
}

#  ifdef DEBUGGING

STATIC void
S_print_collxfrm_input_and_return(pTHX_
                                  const char * s,
                                  const char * e,
                                  const char * xbuf,
                                  const STRLEN xlen,
                                  const bool is_utf8)
{

    PERL_ARGS_ASSERT_PRINT_COLLXFRM_INPUT_AND_RETURN;

    PerlIO_printf(Perl_debug_log,
                  "mem_collxfrm_[ix %" UVuf "] for locale '%s':\n"
                  "     input=%s\n    return=%s\n    return len=%zu\n",
                  (UV) PL_collation_ix, PL_collation_name,
                  get_displayable_string(s, e, is_utf8),
                  ((xbuf == NULL)
                   ? "(null)"
                   : ((xlen == 0)
                      ? "(empty)"
                      : _byte_dump_string((U8 *) xbuf + COLLXFRM_HDR_LEN,
                                          xlen, 0))),
                  xlen);
}

#  endif    /* DEBUGGING */

SV *
Perl_strxfrm(pTHX_ SV * src)
{
    PERL_ARGS_ASSERT_STRXFRM;

    /* For use by POSIX::strxfrm().  If they differ, toggle LC_CTYPE to
     * LC_COLLATE to avoid potential mojibake.
     *
     * If we can't calculate a collation, 'src' is instead returned, so that
     * future comparisons will be by code point order */

#  ifdef USE_LOCALE_CTYPE

    const char * orig_ctype = toggle_locale_c(LC_CTYPE,
                                              querylocale_c(LC_COLLATE));
#  endif

    SV * dst = src;
    STRLEN dstlen;
    STRLEN srclen;
    const char *p = SvPV_const(src, srclen);
    const U32 utf8_flag = SvUTF8(src);
    char *d = mem_collxfrm_(p, srclen, &dstlen, cBOOL(utf8_flag));

    assert(utf8_flag == 0 || utf8_flag == SVf_UTF8);

    if (d != NULL) {
        assert(dstlen > 0);
        dst =newSVpvn_flags(d + COLLXFRM_HDR_LEN,
                            dstlen, SVs_TEMP|utf8_flag);
        Safefree(d);
    }

#  ifdef USE_LOCALE_CTYPE

    restore_toggled_locale_c(LC_CTYPE, orig_ctype);

#  endif

    return dst;
}

#endif /* USE_LOCALE_COLLATE */
#ifdef USE_LOCALE

STATIC const char *
S_toggle_locale_i(pTHX_ const unsigned cat_index,
                        const char * new_locale,
                        const line_t caller_line)
{
    PERL_ARGS_ASSERT_TOGGLE_LOCALE_I;
    assert(cat_index <= LC_ALL_INDEX_);

    /* Changes the locale for the category specified by 'index' to 'new_locale,
     * if they aren't already the same.
     *
     * Returns a copy of the name of the original locale for 'cat_index'
     * so can be switched back to with the companion function
     * restore_toggled_locale_i(),  (NULL if no restoral is necessary.) */

    /* Find the original locale of the category we may need to change, so that
     * it can be restored to later */
    const char * locale_to_restore_to = querylocale_i(cat_index);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
             "(%" LINE_Tf "): toggle_locale_i: index=%d(%s), wanted=%s,"
             " actual=%s\n",
             caller_line, cat_index, category_names[cat_index],
             new_locale, locale_to_restore_to));

    if (! locale_to_restore_to) {
        locale_panic_via_(Perl_form(aTHX_
                                    "Could not find current %s locale",
                                    category_names[cat_index]),
                         __FILE__, caller_line);
    }

    /* If the locales are the same, there's nothing to do */
    if (strEQ(locale_to_restore_to, new_locale)) {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "(%" LINE_Tf "): %s locale unchanged as %s\n",
                               caller_line, category_names[cat_index],
                               new_locale));

        return NULL;
    }

    /* Finally, change the locale to the new one */
    void_setlocale_i_with_caller(cat_index, new_locale, __FILE__, caller_line);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "(%" LINE_Tf "): %s locale switched to %s\n",
                           caller_line, category_names[cat_index], new_locale));

    return locale_to_restore_to;

#  ifndef DEBUGGING
    PERL_UNUSED_ARG(caller_line);
#  endif

}

STATIC void
S_restore_toggled_locale_i(pTHX_ const unsigned int cat_index,
                                 const char * restore_locale,
                                 const line_t caller_line)
{
    /* Restores the locale for LC_category corresponding to cat_index to
     * 'restore_locale' (which is a copy that will be freed by this function),
     * or do nothing if the latter parameter is NULL */

    PERL_ARGS_ASSERT_RESTORE_TOGGLED_LOCALE_I;
    assert(cat_index <= LC_ALL_INDEX_);

    if (restore_locale == NULL) {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "(%" LINE_Tf "): No need to restore %s\n",
                               caller_line, category_names[cat_index]));
        return;
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "(%" LINE_Tf "): %s restoring locale to %s\n",
                           caller_line, category_names[cat_index],
                           restore_locale));

    void_setlocale_i_with_caller(cat_index, restore_locale,
                                  __FILE__, caller_line);

#  ifndef DEBUGGING
    PERL_UNUSED_ARG(caller_line);
#  endif

}

#  ifdef USE_LOCALE_CTYPE

STATIC bool
S_is_codeset_name_UTF8(const char * name)
{
    /* Return a boolean as to if the passed-in name indicates it is a UTF-8
     * code set.  Several variants are possible */
    const Size_t len = strlen(name);

    PERL_ARGS_ASSERT_IS_CODESET_NAME_UTF8;

#    ifdef WIN32

    /* http://msdn.microsoft.com/en-us/library/windows/desktop/dd317756.aspx */
    if (memENDs(name, len, "65001")) {
        return TRUE;
    }

#    endif
               /* 'UTF8' or 'UTF-8' */
    return (    inRANGE(len, 4, 5)
            &&  name[len-1] == '8'
            && (   memBEGINs(name, len, "UTF")
                || memBEGINs(name, len, "utf"))
            && (len == 4 || name[3] == '-'));
}

#  endif
#endif  /* USE_LOCALE */

bool
Perl__is_in_locale_category(pTHX_ const bool compiling, const int category)
{
    /* Internal function which returns if we are in the scope of a pragma that
     * enables the locale category 'category'.  'compiling' should indicate if
     * this is during the compilation phase (TRUE) or not (FALSE). */

    const COP * const cop = (compiling) ? &PL_compiling : PL_curcop;

    SV *these_categories = cop_hints_fetch_pvs(cop, "locale", 0);
    if (! these_categories || these_categories == &PL_sv_placeholder) {
        return FALSE;
    }

    /* The pseudo-category 'not_characters' is -1, so just add 1 to each to get
     * a valid unsigned */
    assert(category >= -1);
    return cBOOL(SvUV(these_categories) & (1U << (category + 1)));
}

/* my_strerror() returns a mortalized copy of the text of the error message
 * associated with 'errnum'.
 *
 * If not called from within the scope of 'use locale', it uses the text from
 * the C locale.  If Perl is compiled to not pay attention to LC_CTYPE nor
 * LC_MESSAGES, it uses whatever strerror() returns.  Otherwise the text is
 * derived from the locale, LC_MESSAGES if we have that; LC_CTYPE if not.
 *
 * It returns in *utf8ness the result's UTF-8ness
 *
 * The function just calls strerror(), but temporarily switches locales, if
 * needed.  Many platforms require LC_CTYPE and LC_MESSAGES to be in the same
 * CODESET in order for the return from strerror() to not contain '?' symbols,
 * or worse, mojibaked.  It's cheaper to just use the stricter criteria of
 * being in the same locale.  So the code below uses a common locale for both
 * categories.  Again, that is C if not within 'use locale' scope; or the
 * LC_MESSAGES locale if in scope and we have that category; and LC_CTYPE if we
 * don't have LC_MESSAGES; and whatever strerror returns if we don't have
 * either category.
 *
 * There are two sets of implementations.  The first below is if we have
 * strerror_l().  This is the simpler.  We just use the already-built C locale
 * object if not in locale scope, or build up a custom one otherwise.
 *
 * When strerror_l() is not available, we may have to swap locales temporarily
 * to bring the two categories into sync with each other, and possibly to the C
 * locale.
 *
 * Because the prepropessing directives to conditionally compile this function
 * would greatly obscure the logic of the various implementations, the whole
 * function is repeated for each configuration, with some common macros. */

/* Used to shorten the definitions of the following implementations of
 * my_strerror() */
#define DEBUG_STRERROR_ENTER(errnum, in_locale)                             \
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,                                  \
                           "my_strerror called with errnum %d;"             \
                           " Within locale scope=%d\n",                     \
                           errnum, in_locale))

#define DEBUG_STRERROR_RETURN(errstr, utf8ness)                             \
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,                                  \
                           "Strerror returned; saving a copy: '%s';"        \
                           " utf8ness=%d\n",                                \
                           get_displayable_string(errstr,                   \
                                                  errstr + strlen(errstr),  \
                                                  *utf8ness),               \
                           (int) *utf8ness))

/* On platforms that have precisely one of these categories (Windows
 * qualifies), these yield the correct one */
#if defined(USE_LOCALE_CTYPE)
#  define WHICH_LC_INDEX LC_CTYPE_INDEX_
#elif defined(USE_LOCALE_MESSAGES)
#  define WHICH_LC_INDEX LC_MESSAGES_INDEX_
#endif

/*===========================================================================*/
/* First set of implementations, when have strerror_l() */

#if defined(USE_POSIX_2008_LOCALE) && defined(HAS_STRERROR_L)

#  if ! defined(USE_LOCALE_CTYPE) && ! defined(USE_LOCALE_MESSAGES)

/* Here, neither category is defined: use the C locale */
const char *
Perl_my_strerror(pTHX_ const int errnum, utf8ness_t * utf8ness)
{
    PERL_ARGS_ASSERT_MY_STRERROR;

    DEBUG_STRERROR_ENTER(errnum, 0);

    const char *errstr = savepv(strerror_l(errnum, PL_C_locale_obj));
    *utf8ness = UTF8NESS_IMMATERIAL;

    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}

#  elif ! defined(USE_LOCALE_CTYPE) || ! defined(USE_LOCALE_MESSAGES)

/*--------------------------------------------------------------------------*/

/* Here one or the other of CTYPE or MESSAGES is defined, but not both.  If we
 * are not within 'use locale' scope of the only one defined, we use the C
 * locale; otherwise use the current locale object */

const char *
Perl_my_strerror(pTHX_ const int errnum, utf8ness_t * utf8ness)
{
    PERL_ARGS_ASSERT_MY_STRERROR;

    DEBUG_STRERROR_ENTER(errnum, IN_LC(categories[WHICH_LC_INDEX]));

    /* Use C if not within locale scope;  Otherwise, use current locale */
    const locale_t which_obj = (IN_LC(categories[WHICH_LC_INDEX]))
                               ? PL_C_locale_obj
                               : use_curlocale_scratch();

    const char *errstr = savepv(strerror_l(errnum, which_obj));
    *utf8ness = get_locale_string_utf8ness_i(errstr, LOCALE_UTF8NESS_UNKNOWN,
                                             NULL, WHICH_LC_INDEX);
    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}

/*--------------------------------------------------------------------------*/
#  else     /* Are using both categories.  Place them in the same CODESET,
             * either C or the LC_MESSAGES locale */

const char *
Perl_my_strerror(pTHX_ const int errnum, utf8ness_t * utf8ness)
{
    PERL_ARGS_ASSERT_MY_STRERROR;

    DEBUG_STRERROR_ENTER(errnum, IN_LC(LC_MESSAGES));

    const char *errstr;
    if (! IN_LC(LC_MESSAGES)) {    /* Use C if not within locale scope */
        errstr = savepv(strerror_l(errnum, PL_C_locale_obj));
        *utf8ness = UTF8NESS_IMMATERIAL;
    }
    else {  /* Otherwise, use the LC_MESSAGES locale, making sure LC_CTYPE
               matches */
        locale_t cur = duplocale(use_curlocale_scratch());

        cur = newlocale(LC_CTYPE_MASK, querylocale_c(LC_MESSAGES), cur);
        errstr = savepv(strerror_l(errnum, cur));
        *utf8ness = get_locale_string_utf8ness_i(errstr,
                                                 LOCALE_UTF8NESS_UNKNOWN,
                                                 NULL, LC_MESSAGES_INDEX_);
        freelocale(cur);
    }

    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}
#  endif    /* Above is using strerror_l */
/*===========================================================================*/
#else       /* Below is not using strerror_l */
#  if ! defined(USE_LOCALE_CTYPE) && ! defined(USE_LOCALE_MESSAGES)

/* If not using using either of the categories, return plain, unadorned
 * strerror */

const char *
Perl_my_strerror(pTHX_ const int errnum, utf8ness_t * utf8ness)
{
    PERL_ARGS_ASSERT_MY_STRERROR;

    DEBUG_STRERROR_ENTER(errnum, 0);

    const char *errstr = savepv(Strerror(errnum));
    *utf8ness = UTF8NESS_IMMATERIAL;

    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}

/*--------------------------------------------------------------------------*/
#  elif ! defined(USE_LOCALE_CTYPE) || ! defined(USE_LOCALE_MESSAGES)

/* Here one or the other of CTYPE or MESSAGES is defined, but not both.  If we
 * are not within 'use locale' scope of the only one defined, we use the C
 * locale; otherwise use the current locale */

const char *
Perl_my_strerror(pTHX_ const int errnum, utf8ness_t * utf8ness)
{
    PERL_ARGS_ASSERT_MY_STRERROR;

    DEBUG_STRERROR_ENTER(errnum, IN_LC(categories[WHICH_LC_INDEX]));

    const char *errstr;
    if (IN_LC(categories[WHICH_LC_INDEX])) {
        errstr = savepv(Strerror(errnum));
        *utf8ness = get_locale_string_utf8ness_i(errstr,
                                                 LOCALE_UTF8NESS_UNKNOWN,
                                                 NULL, WHICH_LC_INDEX);
    }
    else {

        LOCALE_LOCK;

        const char * orig_locale = toggle_locale_i(WHICH_LC_INDEX, "C");

        errstr = savepv(Strerror(errnum));

        restore_toggled_locale_i(WHICH_LC_INDEX, orig_locale);

        LOCALE_UNLOCK;

        *utf8ness = UTF8NESS_IMMATERIAL;
    }

    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}

/*--------------------------------------------------------------------------*/
#  else

/* Below, have both LC_CTYPE and LC_MESSAGES.  Place them in the same CODESET,
 * either C or the LC_MESSAGES locale */

const char *
Perl_my_strerror(pTHX_ const int errnum, utf8ness_t * utf8ness)
{
    PERL_ARGS_ASSERT_MY_STRERROR;

    DEBUG_STRERROR_ENTER(errnum, IN_LC(LC_MESSAGES));

    const char * desired_locale = (IN_LC(LC_MESSAGES))
                                  ? querylocale_c(LC_MESSAGES)
                                  : "C";
    /* XXX Can fail on z/OS */

    LOCALE_LOCK;

    const char* orig_CTYPE_locale    = toggle_locale_c(LC_CTYPE,
                                                       desired_locale);
    const char* orig_MESSAGES_locale = toggle_locale_c(LC_MESSAGES,
                                                       desired_locale);
    const char *errstr = savepv(Strerror(errnum));

    restore_toggled_locale_c(LC_MESSAGES, orig_MESSAGES_locale);
    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);

    LOCALE_UNLOCK;

    *utf8ness = get_locale_string_utf8ness_i(errstr, LOCALE_UTF8NESS_UNKNOWN,
                                             NULL, LC_MESSAGES_INDEX_);
    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}

/*--------------------------------------------------------------------------*/
#  endif /* end of not using strerror_l() */
#endif   /* end of all the my_strerror() implementations */

/*

=for apidoc switch_to_global_locale

This function copies the locale state of the calling thread into the program's
global locale, and converts the thread to use that global locale.

It is intended so that Perl can safely be used with C libraries that access the
global locale and which can't be converted to not access it.  Effectively, this
means libraries that call C<L<setlocale(3)>> on non-Windows systems.  (For
portability, it is a good idea to use it on Windows as well.)

A downside of using it is that it disables the services that Perl provides to
hide locale gotchas from your code.  The service you most likely will miss
regards the radix character (decimal point) in floating point numbers.  Code
executed after this function is called can no longer just assume that this
character is correct for the current circumstances.

To return to Perl control, and restart the gotcha prevention services, call
C<L</sync_locale>>.  Behavior is undefined for any pure Perl code that executes
while the switch is in effect.

The global locale and the per-thread locales are independent.  As long as just
one thread converts to the global locale, everything works smoothly.  But if
more than one does, they can easily interfere with each other, and races are
likely.  On Windows systems prior to Visual Studio 15 (at which point Microsoft
fixed a bug), races can occur (even if only one thread has been converted to
the global locale), but only if you use the following operations:

=over

=item L<POSIX::localeconv|POSIX/localeconv>

=item L<I18N::Langinfo>, items C<CRNCYSTR> and C<THOUSEP>

=item L<perlapi/Perl_langinfo>, items C<CRNCYSTR> and C<THOUSEP>

=back

The first item is not fixable (except by upgrading to a later Visual Studio
release), but it would be possible to work around the latter two items by
having Perl change its algorithm for calculating these to use Windows API
functions (likely C<GetNumberFormat> and C<GetCurrencyFormat>); patches
welcome.

XS code should never call plain C<setlocale>, but should instead be converted
to either call L<C<Perl_setlocale>|perlapi/Perl_setlocale> (which is a drop-in
for the system C<setlocale>) or use the methods given in L<perlcall> to call
L<C<POSIX::setlocale>|POSIX/setlocale>.  Either one will transparently properly
handle all cases of single- vs multi-thread, POSIX 2008-supported or not.

=cut
*/

void
Perl_switch_to_global_locale(pTHX)
{

#ifdef USE_LOCALE

    DEBUG_L(PerlIO_printf(Perl_debug_log, "Entering switch_to_global; %s\n",
                                          get_LC_ALL_display()));
    bool perl_controls = false;

#  ifdef USE_THREAD_SAFE_LOCALE

   /* In these cases, we use the system state to determine if we are in the
    * global locale or not. */

#    ifdef USE_POSIX_2008_LOCALE

    perl_controls = (LC_GLOBAL_LOCALE != uselocale((locale_t) 0));

#    elif defined(WIN32)

    int config_return = _configthreadlocale(0);
    if (config_return == -1) {
        locale_panic_("_configthreadlocale returned an error");
    }
    perl_controls = (config_return == _ENABLE_PER_THREAD_LOCALE);

#    else
#      error Unexpected Configuration
#    endif
#  endif

    /* No-op if already in global */
    if (! perl_controls) {
        return;
    }

#  ifdef USE_THREAD_SAFE_LOCALE
#    if defined(WIN32)

    const char * thread_locale = posix_setlocale(LC_ALL, NULL);
    if (_configthreadlocale(_DISABLE_PER_THREAD_LOCALE) == -1) {
        locale_panic_("_configthreadlocale returned an error");
    }
    posix_setlocale(LC_ALL, thread_locale);

#    else   /* Must be USE_POSIX_2008_LOCALE) */

    const char * cur_thread_locales[LC_ALL_INDEX_ + 1];

    /* Save each category's current per-thread state */
    for (unsigned i = 0; i < LC_ALL_INDEX_; i++) {
        cur_thread_locales[i] = querylocale_i(i);
    }

    /* Now switch to global */
    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "Switching to global locale\n"));

    locale_t old_locale = uselocale(LC_GLOBAL_LOCALE);
    if (! old_locale) {
        locale_panic_("Could not change to global locale");
    }

    /* Free the per-thread memory */
    if (old_locale != LC_GLOBAL_LOCALE && old_locale != PL_C_locale_obj) {
        freelocale(old_locale);
    }

    /* Set the global to what was our per-thread state */
    POSIX_SETLOCALE_LOCK;
    for (unsigned int i = 0; i < LC_ALL_INDEX_; i++) {
        posix_setlocale(categories[i], cur_thread_locales[i]);
    }
    POSIX_SETLOCALE_UNLOCK;

#    endif
#  endif
#  ifdef USE_LOCALE_NUMERIC

    /* Switch to the underlying C numeric locale; the application is on its
     * own. */
    POSIX_SETLOCALE_LOCK;
    posix_setlocale(LC_NUMERIC, PL_numeric_name);
    POSIX_SETLOCALE_UNLOCK;

#  endif
#endif

}

/*

=for apidoc sync_locale

This function copies the state of the program global locale into the calling
thread, and converts that thread to using per-thread locales, if it wasn't
already, and the platform supports them.  The LC_NUMERIC locale is toggled into
the standard state (using the C locale's conventions), if not within the
lexical scope of S<C<use locale>>.

Perl will now consider itself to have control of the locale.

Since unthreaded perls have only a global locale, this function is a no-op
without threads.

This function is intended for use with C libraries that do locale manipulation.
It allows Perl to accommodate the use of them.  Call this function before
transferring back to Perl space so that it knows what state the C code has left
things in.

XS code should not manipulate the locale on its own.  Instead,
L<C<Perl_setlocale>|perlapi/Perl_setlocale> can be used at any time to query or
change the locale (though changing the locale is antisocial and dangerous on
multi-threaded systems that don't have multi-thread safe locale operations.
(See L<perllocale/Multi-threaded operation>).

Using the libc L<C<setlocale(3)>> function should be avoided.  Nevertheless,
certain non-Perl libraries called from XS, do call it, and their behavior may
not be able to be changed.  This function, along with
C<L</switch_to_global_locale>>, can be used to get seamless behavior in these
circumstances, as long as only one thread is involved.

If the library has an option to turn off its locale manipulation, doing that is
preferable to using this mechanism.  C<Gtk> is such a library.

The return value is a boolean: TRUE if the global locale at the time of call
was in effect for the caller; and FALSE if a per-thread locale was in effect.

=cut
*/

bool
Perl_sync_locale(pTHX)
{

#ifndef USE_LOCALE

    return TRUE;

#else

    bool was_in_global = TRUE;

#  ifdef USE_THREAD_SAFE_LOCALE
#    if defined(WIN32)

    int config_return = _configthreadlocale(_DISABLE_PER_THREAD_LOCALE);
    if (config_return == -1) {
        locale_panic_("_configthreadlocale returned an error");
    }
    was_in_global = (config_return == _DISABLE_PER_THREAD_LOCALE);

#    elif defined(USE_POSIX_2008_LOCALE)

    was_in_global = (LC_GLOBAL_LOCALE == uselocale(LC_GLOBAL_LOCALE));

#    else
#      error Unexpected Configuration
#    endif
#  endif    /* USE_THREAD_SAFE_LOCALE */

    /* Here, we are in the global locale.  Get and save the values for each
     * category, and convert the current thread to use them */

#  ifdef LC_ALL

    STDIZED_SETLOCALE_LOCK;
    const char * lc_all_string = savepv(stdized_setlocale(LC_ALL, NULL));
    STDIZED_SETLOCALE_UNLOCK;

    give_perl_locale_control(lc_all_string, __LINE__);
    Safefree(lc_all_string);

#  else

    const char * current_globals[LC_ALL_INDEX_];
    for (unsigned i = 0; i < LC_ALL_INDEX_; i++) {
        STDIZED_SETLOCALE_LOCK;
        current_globals[i] = savepv(stdized_setlocale(categories[i], NULL));
        STDIZED_SETLOCALE_UNLOCK;
    }

    give_perl_locale_control((const char **) &current_globals, __LINE__);

    for (unsigned i = 0; i < LC_ALL_INDEX_; i++) {
        Safefree(current_globals[i]);
    }

#  endif

    return was_in_global;

#endif

}

#if defined(DEBUGGING) && defined(USE_LOCALE)

STATIC char *
S_my_setlocale_debug_string_i(pTHX_
                              const unsigned cat_index,
                              const char* locale, /* Optional locale name */

                              /* return value from setlocale() when attempting
                               * to set 'category' to 'locale' */
                              const char* retval,

                              const line_t line)
{
    /* Returns a pointer to a NUL-terminated string in static storage with
     * added text about the info passed in.  This is not thread safe and will
     * be overwritten by the next call, so this should be used just to
     * formulate a string to immediately print or savepv() on. */

    const char * locale_quote;
    const char * retval_quote;

    assert(cat_index <= LC_ALL_INDEX_);

    if (locale == NULL) {
        locale_quote = "";
        locale = "NULL";
    }
    else {
        locale_quote = "\"";
    }

    if (retval == NULL) {
        retval_quote = "";
        retval = "NULL";
    }
    else {
        retval_quote = "\"";
    }

#  ifdef USE_LOCALE_THREADS
#    define THREAD_FORMAT "%p:"
#    define THREAD_ARGUMENT aTHX_
#  else
#    define THREAD_FORMAT
#    define THREAD_ARGUMENT
#  endif

    return Perl_form(aTHX_
                     "%s:%" LINE_Tf ": " THREAD_FORMAT
                     " setlocale(%s[%d], %s%s%s) returned %s%s%s\n",

                     __FILE__, line, THREAD_ARGUMENT
                     category_names[cat_index], categories[cat_index],
                     locale_quote, locale, locale_quote,
                     retval_quote, retval, retval_quote);
}

#endif
#ifdef USE_PERL_SWITCH_LOCALE_CONTEXT

void
Perl_switch_locale_context()
{
    /* libc keeps per-thread locale status information in some configurations.
     * So, we can't just switch out aTHX to switch to a new thread.  libc has
     * to follow along.  This routine does that based on per-interpreter
     * variables we keep just for this purpose */

    /* Can't use pTHX, because we may be called from a place where that
     * isn't available */
    dTHX;

    if (UNLIKELY(   aTHX == NULL
                 || PL_veto_switch_non_tTHX_context
                 || PL_phase == PERL_PHASE_CONSTRUCT))
    {
        return;
    }

#  ifdef USE_POSIX_2008_LOCALE

    if (! uselocale(PL_cur_locale_obj)) {
        locale_panic_(Perl_form(aTHX_
                                "Can't uselocale(%p), LC_ALL supposed to"
                                " be '%s'",
                                PL_cur_locale_obj, get_LC_ALL_display()));
    }

#  elif defined(WIN32)

    if (! bool_setlocale_c(LC_ALL, PL_cur_LC_ALL)) {
        locale_panic_(Perl_form(aTHX_ "Can't setlocale(%s)", PL_cur_LC_ALL));
    }

#  endif

}

#endif

void
Perl_thread_locale_init(pTHX)
{

#ifdef USE_THREAD_SAFE_LOCALE
#  ifdef USE_POSIX_2008_LOCALE

    /* Called from a thread on startup.
     *
     * The operations here have to be done from within the calling thread, as
     * they affect libc's knowledge of the thread; libc has no knowledge of
     * aTHX */

     DEBUG_L(PerlIO_printf(Perl_debug_log,
                           "new thread, initial locale is %s;"
                           " calling setlocale(LC_ALL, \"C\")\n",
                           get_LC_ALL_display()));

    if (! uselocale(PL_C_locale_obj)) {

        /* Not being able to change to the C locale is severe; don't keep
         * going.  */
        locale_panic_(Perl_form(aTHX_
                                "Can't uselocale(%p), 'C'", PL_C_locale_obj));
        NOT_REACHED; /* NOTREACHED */
    }

#    ifdef MULTIPLICITY

    PL_cur_locale_obj = PL_C_locale_obj;

#    endif
#  elif defined(WIN32)

    /* On Windows, make sure new thread has per-thread locales enabled */
    if (_configthreadlocale(_ENABLE_PER_THREAD_LOCALE) == -1) {
        locale_panic_("_configthreadlocale returned an error");
    }
    void_setlocale_c(LC_ALL, "C");

#  endif
#endif

}

void
Perl_thread_locale_term(pTHX)
{
    /* Called from a thread as it gets ready to terminate.
     *
     * The operations here have to be done from within the calling thread, as
     * they affect libc's knowledge of the thread; libc has no knowledge of
     * aTHX */

#if defined(USE_POSIX_2008_LOCALE) && defined(USE_THREADS)

    /* Switch to the global locale, so can free up the per-thread object */
    locale_t actual_obj = uselocale(LC_GLOBAL_LOCALE);
    if (actual_obj != LC_GLOBAL_LOCALE && actual_obj != PL_C_locale_obj) {
        freelocale(actual_obj);
    }

    /* Prevent leaks even if something has gone wrong */
    locale_t expected_obj = PL_cur_locale_obj;
    if (UNLIKELY(   expected_obj != actual_obj
                 && expected_obj != LC_GLOBAL_LOCALE
                 && expected_obj != PL_C_locale_obj))
    {
        freelocale(expected_obj);
    }

    PL_cur_locale_obj = LC_GLOBAL_LOCALE;

#endif
#ifdef WIN32_USE_FAKE_OLD_MINGW_LOCALES

    /* When faking the mingw implementation, we coerce this function into doing
     * something completely different from its intent -- namely to free up our
     * static buffer to avoid a leak.  This function gets called for each
     * thread that is terminating, so will give us a chance to free the buffer
     * from the appropriate pool.  On unthreaded systems, it gets called by the
     * mutex termination code. */

#  ifdef MULTIPLICITY

    if (aTHX != wsetlocale_buf_aTHX) {
        return;
    }

#  endif

    if (wsetlocale_buf_size > 0) {
        Safefree(wsetlocale_buf);
        wsetlocale_buf_size = 0;
    }

#endif

}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
