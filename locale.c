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
 * LC_foo_INDEX_.  Various parallel tables, indexed by these, are used.
 *
 * Many of the macros and functions in this file have one of the suffixes '_c',
 * '_r', or '_i'.  khw found these useful in remembering what type of locale
 * category to use as their parameter.  '_r' takes an int category number as
 * passed to setlocale(), like LC_ALL, LC_CTYPE, etc.  The 'r' indicates that
 * the value isn't known until runtime.  '_c' also indicates such a category
 * number, but its value is known at compile time.  These are both converted
 * into unsigned indexes into various tables of category information, where the
 * real work is generally done.  The tables are generated at compile-time based
 * on platform characteristics and Configure options.  They hide from the code
 * many of the vagaries of the different locale implementations out there.  You
 * may have already guessed that '_i' indicates the parameter is such an
 * unsigned index.  Converting from '_r' to '_i' requires run-time lookup.
 * '_c' is used to get cpp to do this at compile time.  To avoid the runtime
 * expense, the code is structured to use '_r' at the API level, and once
 * converted, everything possible is done using the table indexes.
 *
 * On unthreaded perls, most operations expand out to just the basic
 * setlocale() calls.  The same is true on threaded perls on modern Windows
 * systems where the same API, after set up, is used for thread-safe locale
 * handling.  On other systems, there is a completely different API, specified
 * in POSIX 2008, to do thread-safe locales.  On these systems, our
 * emulate_setlocale_i() function is used to hide the different API from the
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
 * 1) Raw my_setlocale().  Here the layer adds nothing.  This is used for
 *    unthreaded perls, and when the API for safe locale threading is identical
 *    to the unsafe API (Windows, currently).
 *
 * 2) A minimal layer that makes my_setlocale() uninterruptible and returns a
 *    per-thread/per-category value.
 *
 * 3a and 3b) A layer that implements POSIX 2008 thread-safe locale handling,
 *    mapping the setlocale() API to them.  This automatically makes almost all
 *    code thread-safe without need for changes.  This layer is chosen on
 *    threaded perls when the platform supports the POSIX 2008 functions, and
 *    when there is no manual override in Configure.
 *
 *    3a) is when the platform has a reliable querylocale() function or
 *        equivalent that is selected to be used.
 *    3b) is when we have to emulate that functionality.
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
 */

/* If the environment says to, we can output debugging information during
 * initialization.  This is done before option parsing, and before any thread
 * creation, so can be a file-level static.  (Must come before #including
 * perl.h) */
#ifdef DEBUGGING
static int debug_initialization = 0;
#  define DEBUG_INITIALIZATION_set(v) (debug_initialization = v)
#  define DEBUG_LOCALE_INITIALIZATION_  debug_initialization
#else
#  define debug_initialization 0
#  define DEBUG_INITIALIZATION_set(v)
#endif

#define DEBUG_PRE_STMTS   dSAVE_ERRNO;                                        \
    PerlIO_printf(Perl_debug_log, "%s: %" LINE_Tf ": ", __FILE__, __LINE__);
#define DEBUG_POST_STMTS  RESTORE_ERRNO;

#include "EXTERN.h"
#define PERL_IN_LOCALE_C
#include "perl.h"

#include "reentr.h"

#ifdef I_WCHAR
#  include <wchar.h>
#endif
#ifdef I_WCTYPE
#  include <wctype.h>
#endif

#ifdef USE_LOCALE

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
static const char C_thousands_sep[] = "";

/* Is the C string input 'name' "C" or "POSIX"?  If so, and 'name' is the
 * return of setlocale(), then this is extremely likely to be the C or POSIX
 * locale.  However, the output of setlocale() is documented to be opaque, but
 * the odds are extremely small that it would return these two strings for some
 * other locale.  Note that VMS in these two locales includes many non-ASCII
 * characters as controls and punctuation (below are hex bytes):
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
#if defined(HAS_LOCALECONV) || defined(HAS_LOCALECONV_L)
#  define HAS_SOME_LOCALECONV
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
             setlocale_debug_string_i(get_category_index(category, locale), \
                                      locale, result)
#  endif

#  define toggle_locale_i(index, locale)                                    \
                 S_toggle_locale_i(aTHX_ index, locale, __LINE__)
#  define toggle_locale_c(cat, locale)  toggle_locale_i(cat##_INDEX_, locale)
#  define restore_toggled_locale_i(index, locale)                           \
                 S_restore_toggled_locale_i(aTHX_ index, locale, __LINE__)
#  define restore_toggled_locale_c(cat, locale)                             \
                             restore_toggled_locale_i(cat##_INDEX_, locale)

/* Two parallel arrays indexed by our mapping of category numbers into small
 * non-negative indexes; first the locale categories Perl uses on this system,
 * used to do the inverse mapping.  The second array is their names.  These
 * arrays are in mostly arbitrary order. */

STATIC const int categories[] = {

#    ifdef USE_LOCALE_CTYPE
                             LC_CTYPE,
#    endif
#  ifdef USE_LOCALE_NUMERIC
                             LC_NUMERIC,
#  endif
#    ifdef USE_LOCALE_COLLATE
                             LC_COLLATE,
#    endif
#    ifdef USE_LOCALE_TIME
                             LC_TIME,
#    endif
#    ifdef USE_LOCALE_MESSAGES
                             LC_MESSAGES,
#    endif
#    ifdef USE_LOCALE_MONETARY
                             LC_MONETARY,
#    endif
#    ifdef USE_LOCALE_ADDRESS
                             LC_ADDRESS,
#    endif
#    ifdef USE_LOCALE_IDENTIFICATION
                             LC_IDENTIFICATION,
#    endif
#    ifdef USE_LOCALE_MEASUREMENT
                             LC_MEASUREMENT,
#    endif
#    ifdef USE_LOCALE_PAPER
                             LC_PAPER,
#    endif
#    ifdef USE_LOCALE_TELEPHONE
                             LC_TELEPHONE,
#    endif
#    ifdef USE_LOCALE_SYNTAX
                             LC_SYNTAX,
#    endif
#    ifdef USE_LOCALE_TOD
                             LC_TOD,
#    endif
#    ifdef LC_ALL
                             LC_ALL,
#    endif

   /* Placeholder as a precaution if code fails to check the return of
    * get_category_index(), which returns this element to indicate an error */
                            -1
};

/* The top-most real element is LC_ALL */

STATIC const char * const category_names[] = {

#    ifdef USE_LOCALE_CTYPE
                                 "LC_CTYPE",
#    endif
#  ifdef USE_LOCALE_NUMERIC
                                 "LC_NUMERIC",
#  endif
#    ifdef USE_LOCALE_COLLATE
                                 "LC_COLLATE",
#    endif
#    ifdef USE_LOCALE_TIME
                                 "LC_TIME",
#    endif
#    ifdef USE_LOCALE_MESSAGES
                                 "LC_MESSAGES",
#    endif
#    ifdef USE_LOCALE_MONETARY
                                 "LC_MONETARY",
#    endif
#    ifdef USE_LOCALE_ADDRESS
                                 "LC_ADDRESS",
#    endif
#    ifdef USE_LOCALE_IDENTIFICATION
                                 "LC_IDENTIFICATION",
#    endif
#    ifdef USE_LOCALE_MEASUREMENT
                                 "LC_MEASUREMENT",
#    endif
#    ifdef USE_LOCALE_PAPER
                                 "LC_PAPER",
#    endif
#    ifdef USE_LOCALE_TELEPHONE
                                 "LC_TELEPHONE",
#    endif
#    ifdef USE_LOCALE_SYNTAX
                                 "LC_SYNTAX",
#    endif
#    ifdef USE_LOCALE_TOD
                                 "LC_TOD",
#    endif
#    ifdef LC_ALL
                                 "LC_ALL",
#    endif

   /* Placeholder as a precaution if code fails to check the return of
    * get_category_index(), which returns this element to indicate an error */
                                 NULL
};

/* A few categories require additional setup when they are changed.  This table
 * points to the functions that do that setup */
STATIC void (*update_functions[]) (pTHX_ const char *) = {
#  ifdef USE_LOCALE_CTYPE
                                S_new_ctype,
#  endif
#  ifdef USE_LOCALE_NUMERIC
                                S_new_numeric,
#  endif
#  ifdef USE_LOCALE_COLLATE
                                S_new_collate,
#  endif
#  ifdef USE_LOCALE_TIME
                                NULL,
#  endif
#  ifdef USE_LOCALE_MESSAGES
                                NULL,
#  endif
#  ifdef USE_LOCALE_MONETARY
                                NULL,
#  endif
#  ifdef USE_LOCALE_ADDRESS
                                NULL,
#  endif
#  ifdef USE_LOCALE_IDENTIFICATION
                                NULL,
#  endif
#  ifdef USE_LOCALE_MEASUREMENT
                                NULL,
#  endif
#  ifdef USE_LOCALE_PAPER
                                NULL,
#  endif
#  ifdef USE_LOCALE_TELEPHONE
                                NULL,
#  endif
#  ifdef USE_LOCALE_SYNTAX
                                NULL,
#  endif
#  ifdef USE_LOCALE_TOD
                                NULL,
#  endif
    /* No harm done to have this even without an LC_ALL */
                                S_new_LC_ALL,

   /* Placeholder as a precaution if code fails to check the return of
    * get_category_index(), which returns this element to indicate an error */
                                NULL
};

#  ifdef LC_ALL

    /* On systems with LC_ALL, it is kept in the highest index position.  (-2
     * to account for the final unused placeholder element.) */
#    define NOMINAL_LC_ALL_INDEX (C_ARRAY_LENGTH(categories) - 2)
#  else

    /* On systems without LC_ALL, we pretend it is there, one beyond the real
     * top element, hence in the unused placeholder element. */
#    define NOMINAL_LC_ALL_INDEX (C_ARRAY_LENGTH(categories) - 1)
#  endif

/* Pretending there is an LC_ALL element just above allows us to avoid most
 * special cases.  Most loops through these arrays in the code below are
 * written like 'for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++)'.  They will work
 * on either type of system.  But the code must be written to not access the
 * element at 'LC_ALL_INDEX_' except on platforms that have it.  This can be
 * checked for at compile time by using the #define LC_ALL_INDEX_ which is only
 * defined if we do have LC_ALL. */

STATIC unsigned int
S_get_category_index(const int category, const char * locale)
{
    /* Given a category, return the equivalent internal index we generally use
     * instead.
     *
     * 'locale' is for use in any generated diagnostics, and may be NULL
     *
     * Some sort of hash could be used instead of this loop, but the number of
     * elements is so far at most 12 */

    unsigned int i;
    const char * conditional_warn_text = "; can't set it to ";

    PERL_ARGS_ASSERT_GET_CATEGORY_INDEX;

#  ifdef LC_ALL
    for (i = 0; i <=         LC_ALL_INDEX_; i++)
#  else
    for (i = 0; i <  NOMINAL_LC_ALL_INDEX;  i++)
#  endif
    {
        if (category == categories[i]) {
            dTHX_DEBUGGING;
            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                   "index of category %d (%s) is %d\n",
                                   category, category_names[i], i));
            return i;
        }
    }

    /* Here, we don't know about this category, so can't handle it. */

    if (! locale) {
        locale = "";
        conditional_warn_text = "";
    }

    /* diag_listed_as: Unknown locale category %d; can't set it to %s */
    Perl_warner_nocontext(packWARN(WARN_LOCALE),
                          "Unknown locale category %d%s%s",
                          category, conditional_warn_text, locale);

#  ifdef EINVAL

    SETERRNO(EINVAL, LIB_INVARG);

#  endif

    /* Return an out-of-bounds value */
    return NOMINAL_LC_ALL_INDEX + 1;
}

#endif /* ifdef USE_LOCALE */

void
Perl_force_locale_unlock()
{

#if defined(USE_LOCALE_THREADS)

    dTHX;

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
                  const char * file_name,
                  const line_t line,
                  const int errnum)
{
    dTHX;

    PERL_ARGS_ASSERT_LOCALE_PANIC;

    force_locale_unlock();

#ifdef USE_C_BACKTRACE
    dump_c_backtrace(Perl_debug_log, 20, 1);
#endif

    /* diag_listed_as: panic: %s */
    Perl_croak(aTHX_ "%s: %d: panic: %s; errno=%d\n",
                     file_name, line, msg, errnum);
}

#define setlocale_failure_panic_c(                                          \
                        cat, current, failed, caller_0_line, caller_1_line) \
        setlocale_failure_panic_i(cat##_INDEX_, current, failed,            \
                        caller_0_line, caller_1_line)

/* posix_setlocale() presents a consistent POSIX-compliant interface to
 * setlocale().   Windows requres a customized base-level setlocale() */
#ifdef WIN32
#  define posix_setlocale(cat, locale) win32_setlocale(cat, locale)
#else
#  define posix_setlocale(cat, locale) ((const char *) setlocale(cat, locale))
#endif

/* The next layer up is to catch vagaries and bugs in the libc setlocale return
 * value */
#ifdef stdize_locale
#  define stdized_setlocale(cat, locale)                                       \
     stdize_locale(cat, posix_setlocale(cat, locale),                          \
                   &PL_stdize_locale_buf, &PL_stdize_locale_bufsize, __LINE__)
#else
#  define stdized_setlocale(cat, locale)  posix_setlocale(cat, locale)
#endif

/* The next many lines form a layer above the close-to-the-metal 'posix'
 * and 'stdized' macros.  They are used to present a uniform API to the rest of
 * the code in this file in spite of the disparate underlying implementations.
 * */

#if    (! defined(USE_LOCALE_THREADS) && ! defined(USE_POSIX_2008_LOCALE))    \
    || (  defined(WIN32) && defined(USE_THREAD_SAFE_LOCALE))

/* For non-threaded perls (which we are not to use the POSIX 2008 API on), or a
 * thread-safe Windows one in which threading is invisible to us, the added
 * layer just expands to the base-level functions.  See the introductory
 * comments in this file for the meaning of the suffixes '_c', '_r', '_i'. */

#  define setlocale_r(cat, locale)        stdized_setlocale(cat, locale)
#  define setlocale_i(i, locale)      setlocale_r(categories[i], locale)
#  define setlocale_c(cat, locale)              setlocale_r(cat, locale)

#  define void_setlocale_i(i, locale)                                       \
    STMT_START {                                                            \
        if (! posix_setlocale(categories[i], locale)) {                     \
            setlocale_failure_panic_i(i, NULL, locale, __LINE__, 0);        \
            NOT_REACHED; /* NOTREACHED */                                   \
        }                                                                   \
    } STMT_END
#  define void_setlocale_c(cat, locale)                                     \
                                  void_setlocale_i(cat##_INDEX_, locale)
#  define void_setlocale_r(cat, locale)                                     \
               void_setlocale_i(get_category_index(cat, locale), locale)

#  define bool_setlocale_r(cat, locale) cBOOL(posix_setlocale(cat, locale))
#  define bool_setlocale_i(i, locale)                                       \
                                 bool_setlocale_c(categories[i], locale)
#  define bool_setlocale_c(cat, locale)    bool_setlocale_r(cat, locale)

/* All the querylocale...() forms return a mortalized copy.  If you need
 * something stable across calls, you need to savepv() the result yourself */

#  define querylocale_r(cat)        mortalized_pv_copy(setlocale_r(cat, NULL))
#  define querylocale_c(cat)        querylocale_r(cat)
#  define querylocale_i(i)          querylocale_c(categories[i])

#elif   defined(USE_LOCALE_THREADS)                 \
   && ! defined(USE_THREAD_SAFE_LOCALE)

   /* Here, there are threads, and there is no support for thread-safe
    * operation.  This is a dangerous situation, which perl is documented as
    * not supporting, but it arises in practice.  We can do a modicum of
    * automatic mitigation by making sure there is a per-thread return from
    * setlocale(), and that a mutex protects it from races */
STATIC const char *
S_less_dicey_setlocale_r(pTHX_ const int category, const char * locale)
{
    const char * retval;

    PERL_ARGS_ASSERT_LESS_DICEY_SETLOCALE_R;

    POSIX_SETLOCALE_LOCK;

    retval = stdized_setlocale(category, locale);

    /* We reuse PL_stdize_locale_buf as it doesn't conflict, but the call may
     * already have used it, in which case we don't have to do anything further
     * */
    retval = save_to_buffer(retval,
                            &PL_stdize_locale_buf, &PL_stdize_locale_bufsize);

    POSIX_SETLOCALE_UNLOCK;

    return retval;
}

#  define setlocale_r(cat, locale)  less_dicey_setlocale_r(cat, locale)
#  define setlocale_c(cat, locale)             setlocale_r(cat, locale)
#  define setlocale_i(i, locale)     setlocale_r(categories[i], locale)

#  define querylocale_r(cat)  mortalized_pv_copy(setlocale_r(cat, NULL))
#  define querylocale_c(cat)                   querylocale_r(cat)
#  define querylocale_i(i)                     querylocale_r(categories[i])

STATIC void
S_less_dicey_void_setlocale_i(pTHX_ const unsigned cat_index,
                                    const char * locale,
                                    const line_t line)
{
    PERL_ARGS_ASSERT_LESS_DICEY_VOID_SETLOCALE_I;

    POSIX_SETLOCALE_LOCK;
    if (! posix_setlocale(categories[cat_index], locale)) {
        POSIX_SETLOCALE_UNLOCK;
        setlocale_failure_panic_i(cat_index, NULL, locale, __LINE__, line);
    }
    POSIX_SETLOCALE_UNLOCK;
}

#  define void_setlocale_i(i, locale)                                       \
                          less_dicey_void_setlocale_i(i, locale, __LINE__)
#  define void_setlocale_c(cat, locale)                                     \
                          void_setlocale_i(cat##_INDEX_, locale)
#  define void_setlocale_r(cat, locale)                                     \
       void_setlocale_i(get_category_index(cat, locale), locale)

#  if 0     /* Not currently used */

STATIC bool
S_less_dicey_bool_setlocale_r(pTHX_ const int cat, const char * locale)
{
    bool retval;

    PERL_ARGS_ASSERT_LESS_DICEY_BOOL_SETLOCALE_R;

    POSIX_SETLOCALE_LOCK;
    retval = cBOOL(posix_setlocale(cat, locale));
    POSIX_SETLOCALE_UNLOCK;

    return retval;
}

#  endif
#  define bool_setlocale_r(cat, locale)                                 \
                               less_dicey_bool_setlocale_r(cat, locale)
#  define bool_setlocale_i(i, locale)                                   \
                                bool_setlocale_r(categories[i], locale)
#  define bool_setlocale_c(cat, locale) bool_setlocale_r(cat, locale)
#else

/* Here, there is a completely different API to get thread-safe locales.  We
 * emulate the setlocale() API with our own function(s).  setlocale categories,
 * like LC_NUMERIC, are not valid here for the POSIX 2008 API.  Instead, there
 * are equivalents, like LC_NUMERIC_MASK, which we use instead, converting to
 * by using get_category_index() followed by table lookup. */

#  define emulate_setlocale_c(cat, locale, recalc_LC_ALL, line)             \
           emulate_setlocale_i(cat##_INDEX_, locale, recalc_LC_ALL, line)

     /* A wrapper for the macros below. */
#  define common_emulate_setlocale(i, locale)                               \
                 emulate_setlocale_i(i, locale, YES_RECALC_LC_ALL, __LINE__)

#  define setlocale_i(i, locale)     common_emulate_setlocale(i, locale)
#  define setlocale_c(cat, locale)     setlocale_i(cat##_INDEX_, locale)
#  define setlocale_r(cat, locale)                                          \
                    setlocale_i(get_category_index(cat, locale), locale)

#  define void_setlocale_i(i, locale)     ((void) setlocale_i(i, locale))
#  define void_setlocale_c(cat, locale)                                     \
                                  void_setlocale_i(cat##_INDEX_, locale)
#  define void_setlocale_r(cat, locale) ((void) setlocale_r(cat, locale))

#  define bool_setlocale_i(i, locale)       cBOOL(setlocale_i(i, locale))
#  define bool_setlocale_c(cat, locale)                                     \
                                  bool_setlocale_i(cat##_INDEX_, locale)
#  define bool_setlocale_r(cat, locale)   cBOOL(setlocale_r(cat, locale))

#  define querylocale_i(i)      mortalized_pv_copy(my_querylocale_i(i))
#  define querylocale_c(cat)    querylocale_i(cat##_INDEX_)
#  define querylocale_r(cat)    querylocale_i(get_category_index(cat,NULL))

#  ifdef USE_QUERYLOCALE
#    define isSINGLE_BIT_SET(mask) isPOWER_OF_2(mask)

     /* This code used to think querylocale() was valid on LC_ALL.  Make sure
      * all instances of that have been removed */
#    define QUERYLOCALE_ASSERT(index)                                       \
                        __ASSERT_(isSINGLE_BIT_SET(category_masks[index]))
#    if ! defined(HAS_QUERYLOCALE) && defined(_NL_LOCALE_NAME)
#      define querylocale_l(index, locale_obj)                              \
            (QUERYLOCALE_ASSERT(index)                                      \
             mortalized_pv_copy(nl_langinfo_l(                              \
                         _NL_LOCALE_NAME(categories[index]), locale_obj)))
#    else
#      define querylocale_l(index, locale_obj)                              \
        (QUERYLOCALE_ASSERT(index)                                          \
         mortalized_pv_copy(querylocale(category_masks[index], locale_obj)))
#    endif
#  endif
#  if defined(__GLIBC__) && defined(USE_LOCALE_MESSAGES)
#    define HAS_GLIBC_LC_MESSAGES_BUG
#    include <libintl.h>
#  endif

/* A fourth array, parallel to the ones above to map from category to its
 * equivalent mask */
STATIC const int category_masks[] = {
#  ifdef USE_LOCALE_CTYPE
                                LC_CTYPE_MASK,
#  endif
#  ifdef USE_LOCALE_NUMERIC
                                LC_NUMERIC_MASK,
#  endif
#  ifdef USE_LOCALE_COLLATE
                                LC_COLLATE_MASK,
#  endif
#  ifdef USE_LOCALE_TIME
                                LC_TIME_MASK,
#  endif
#  ifdef USE_LOCALE_MESSAGES
                                LC_MESSAGES_MASK,
#  endif
#  ifdef USE_LOCALE_MONETARY
                                LC_MONETARY_MASK,
#  endif
#  ifdef USE_LOCALE_ADDRESS
                                LC_ADDRESS_MASK,
#  endif
#  ifdef USE_LOCALE_IDENTIFICATION
                                LC_IDENTIFICATION_MASK,
#  endif
#  ifdef USE_LOCALE_MEASUREMENT
                                LC_MEASUREMENT_MASK,
#  endif
#  ifdef USE_LOCALE_PAPER
                                LC_PAPER_MASK,
#  endif
#  ifdef USE_LOCALE_TELEPHONE
                                LC_TELEPHONE_MASK,
#  endif
#  ifdef USE_LOCALE_SYNTAX
                                LC_SYNTAX_MASK,
#  endif
#  ifdef USE_LOCALE_TOD
                                LC_TOD_MASK,
#  endif
                                /* LC_ALL can't be turned off by a Configure
                                 * option, and in Posix 2008, should always be
                                 * here, so compile it in unconditionally.
                                 * This could catch some glitches at compile
                                 * time */
                                LC_ALL_MASK,

   /* Placeholder as a precaution if code fails to check the return of
    * get_category_index(), which returns this element to indicate an error */
                                0
};

#  define my_querylocale_c(cat) my_querylocale_i(cat##_INDEX_)

STATIC const char *
S_my_querylocale_i(pTHX_ const unsigned int index)
{
    /* This function returns the name of the locale category given by the input
     * index into our parallel tables of them.
     *
     * POSIX 2008, for some sick reason, chose not to provide a method to find
     * the category name of a locale, discarding a basic linguistic tenet that
     * for any object, people will create a name for it.  Some vendors have
     * created a querylocale() function to do just that.  This function is a
     * lot simpler to implement on systems that have this.  Otherwise, we have
     * to keep track of what the locale has been set to, so that we can return
     * its name so as to emulate setlocale().  It's also possible for C code in
     * some library to change the locale without us knowing it, though as of
     * September 2017, there are no occurrences in CPAN of uselocale().  Some
     * libraries do use setlocale(), but that changes the global locale, and
     * threads using per-thread locales will just ignore those changes. */

    int category;
    const locale_t cur_obj = uselocale((locale_t) 0);
    const char * retval;

    PERL_ARGS_ASSERT_MY_QUERYLOCALE_I;
    assert(index <= NOMINAL_LC_ALL_INDEX);

    category = categories[index];

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "my_querylocale_i(%s) on %p\n",
                                           category_names[index], cur_obj));
    if (cur_obj == LC_GLOBAL_LOCALE) {
        POSIX_SETLOCALE_LOCK;
        retval = posix_setlocale(category, NULL);
        POSIX_SETLOCALE_UNLOCK;
    }
    else {

#  ifdef USE_QUERYLOCALE

        /* We don't currently keep records when there is querylocale(), so have
         * to get it anew each time */
        retval = (index == LC_ALL_INDEX_)
                 ? calculate_LC_ALL(cur_obj)
                 : querylocale_l(index, cur_obj);

#  else

        /* But we do have up-to-date values when we keep our own records
         * (except some times in initialization, where we get the value from
         * the system. */
        if (PL_curlocales[index] == NULL) {
            retval = stdized_setlocale(category, NULL);
            PL_curlocales[index] = savepv(retval);
        }
        else {
            retval = PL_curlocales[index];
        }

#  endif

            }

                DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "my_querylocale_i(%s) returning '%s'\n",
                           category_names[index], retval));
    assert(strNE(retval, ""));
    return retval;
}

#  ifdef USE_PL_CURLOCALES

STATIC const char *
S_update_PL_curlocales_i(pTHX_
                         const unsigned int index,
                         const char * new_locale,
                         recalc_lc_all_t recalc_LC_ALL)
{
    /* This is a helper function for emulate_setlocale_i(), mostly used to
     * make that function easier to read. */

    PERL_ARGS_ASSERT_UPDATE_PL_CURLOCALES_I;
    assert(index <= NOMINAL_LC_ALL_INDEX);

    if (index == LC_ALL_INDEX_) {
        unsigned int i;

        /* For LC_ALL, we change all individual categories to correspond */
                         /* PL_curlocales is a parallel array, so has same
                          * length as 'categories' */
        for (i = 0; i < LC_ALL_INDEX_; i++) {
            Safefree(PL_curlocales[i]);
            PL_curlocales[i] = savepv(new_locale);
        }

        recalc_LC_ALL = YES_RECALC_LC_ALL;
    }
    else {

        /* Update the single category's record */
        Safefree(PL_curlocales[index]);
        PL_curlocales[index] = savepv(new_locale);

        if (recalc_LC_ALL == RECALCULATE_LC_ALL_ON_FINAL_INTERATION) {
            recalc_LC_ALL = (index == NOMINAL_LC_ALL_INDEX - 1)
                            ? YES_RECALC_LC_ALL
                            : DONT_RECALC_LC_ALL;
        }
    }

    if (recalc_LC_ALL == YES_RECALC_LC_ALL) {
        Safefree(PL_curlocales[LC_ALL_INDEX_]);
        PL_curlocales[LC_ALL_INDEX_] =
                                    savepv(calculate_LC_ALL(PL_curlocales));
    }

    return PL_curlocales[index];
}

#  endif  /* Need PL_curlocales[] */

STATIC const char *
S_setlocale_from_aggregate_LC_ALL(pTHX_ const char * locale, const line_t line)
{
    /* This function parses the value of the LC_ALL locale, assuming glibc
     * syntax, and sets each individual category on the system to the proper
     * value.
     *
     * This is likely to only ever be called from one place, so exists to make
     * the calling function easier to read by moving this ancillary code out of
     * the main line.
     *
     * The locale for each category is independent of the other categories.
     * Often, they are all the same, but certainly not always.  Perl, in fact,
     * usually keeps LC_NUMERIC in the C locale, regardless of the underlying
     * locale.  LC_ALL has to be able to represent the case of when there are
     * varying locales.  Platforms have differing ways of representing this.
     * Because of this, the code in this file goes to lengths to avoid the
     * issue, generally looping over the component categories instead of
     * referring to them in the aggregate, wherever possible.  However, there
     * are cases where we have to parse our own constructed aggregates, which use
     * the glibc syntax. */

    const char * locale_on_entry = querylocale_c(LC_ALL);

    PERL_ARGS_ASSERT_SETLOCALE_FROM_AGGREGATE_LC_ALL;

    /* If the string that gives what to set doesn't include all categories,
     * the omitted ones get set to "C".  To get this behavior, first set
     * all the individual categories to "C", and override the furnished
     * ones below.  FALSE => No need to recalculate LC_ALL, as this is a
     * temporary state */
    if (! emulate_setlocale_c(LC_ALL, "C", DONT_RECALC_LC_ALL, line)) {
        setlocale_failure_panic_c(LC_ALL, locale_on_entry,
                                  "C", __LINE__, line);
        NOT_REACHED; /* NOTREACHED */
    }

    const char * s = locale;
    const char * e = locale + strlen(locale);
    while (s < e) {
        const char * p = s;

        /* Parse through the category */
        while (isWORDCHAR(*p)) {
            p++;
        }

        const char * category_end = p;

        if (*p++ != '=') {
            locale_panic_(Perl_form(aTHX_
                  "Unexpected character in locale category name '%02X", *(p-1)));
        }

        /* Parse through the locale name */
        const char * name_start = p;
        while (p < e && *p != ';') {
            if (! isGRAPH(*p)) {
                locale_panic_(Perl_form(aTHX_
                              "Unexpected character in locale name '%02X", *p));
            }
            p++;
        }

        const char * name_end = p;

        /* Space past the semi-colon */
        if (p < e) {
            p++;
        }

        /* Find the index of the category name in our lists */
        for (PERL_UINT_FAST8_T i = 0; i < LC_ALL_INDEX_; i++) {

            /* Keep going if this index doesn't point to the category being
             * parsed.  The strnNE() avoids a Perl_form(), but would fail if
             * ever a category name could be a substring of another one, e.g.,
             * if there were a "LC_TIME_DATE" */
            if strnNE(s, category_names[i], category_end - s) {
                continue;
            }

            /* Here i points to the category being parsed.  Now isolate the
             * locale it is being changed to */
            const char * individ_locale = Perl_form(aTHX_ "%.*s",
                                (int) (name_end - name_start), name_start);

            /* And do the change.  FALSE => Don't recalculate LC_ALL; we'll do
             * it ourselves after the loop */
            if (! emulate_setlocale_i(i, individ_locale,
                                      DONT_RECALC_LC_ALL, line))
            {

                /* But if we have to back out, do fix up LC_ALL */
                if (! emulate_setlocale_c(LC_ALL, locale_on_entry,
                                          YES_RECALC_LC_ALL, line))
                {
                    setlocale_failure_panic_i(i, individ_locale,
                                              locale, __LINE__, line);
                    NOT_REACHED; /* NOTREACHED */
                }

                /* Reverting to the entry value succeeded, but the operation
                 * failed to go to the requested locale. */
                return NULL;
            }

            /* Found and handled the desired category.  Quit the inner loop to
             * try the next category */
            break;
        }

        /* Finished with this category; iterate to the next one in the input */
        s = p;
    }

#    ifdef USE_PL_CURLOCALES

    /* Here we have set all the individual categories.  Update the LC_ALL entry
     * as well.  We can't just use the input 'locale' as the value may omit
     * categories whose locale is 'C'.  khw thinks it's better to store a
     * complete LC_ALL.  So calculate it. */
    const char * retval = savepv(calculate_LC_ALL(PL_curlocales));
    Safefree(PL_curlocales[LC_ALL_INDEX_]);
    PL_curlocales[LC_ALL_INDEX_] = retval;

#    else

    const char * retval = querylocale_c(LC_ALL);

#    endif

    return retval;
}

#  ifndef USE_QUERYLOCALE

STATIC const char *
S_find_locale_from_environment(pTHX_ const unsigned int index)
{
    /* On systems without querylocale(), it is problematic getting the results
     * of the POSIX 2008 equivalent of setlocale(category, "") (which gets the
     * locale from the environment).
     *
     * To ensure that we know exactly what those values are, we do the setting
     * ourselves, using the documented algorithm (assuming the documentation is
     * correct) rather than use "" as the locale.  This will lead to results
     * that differ from native behavior if the native behavior differs from the
     * standard documented value, but khw believes it is better to know what's
     * going on, even if different from native, than to just guess.
     *
     * Another option would be, in a critical section, to save the global
     * locale's current value, and do a straight setlocale(LC_ALL, "").  That
     * would return our desired values, destroying the global locale's, which
     * we would then restore.  But that could cause races with any other thread
     * that is using the global locale and isn't using the mutex.  And, the
     * only reason someone would have done that is because they are calling a
     * library function, like in gtk, that calls setlocale(), and which can't
     * be changed to use the mutex.  That wouldn't be a problem if this were to
     * be done before any threads had switched, say during perl construction
     * time.  But this code would still be needed for the general case. */

    const char * default_name;
    unsigned int i;
    const char * locale_names[LC_ALL_INDEX_];

    /* We rely on PerlEnv_getenv() returning a mortalized copy */
    const char * const lc_all = PerlEnv_getenv("LC_ALL");

    /* Use any "LC_ALL" environment variable, as it overrides everything
     * else. */
    if (lc_all && strNE(lc_all, "")) {
        return lc_all;
    }

    /* Otherwise, we need to dig deeper.  Unless overridden, the default is
     * the LANG environment variable; "C" if it doesn't exist. */
    default_name = PerlEnv_getenv("LANG");
    if (! default_name || strEQ(default_name, "")) {
        default_name = "C";
    }

    /* If setting an individual category, use its corresponding value found in
     * the environment, if any; otherwise use the default we already
     * calculated. */
    if (index != LC_ALL_INDEX_) {
        const char * const new_value = PerlEnv_getenv(category_names[index]);

        return (new_value && strNE(new_value, ""))
                ? new_value
                : default_name;
    }

    /* Here, we are getting LC_ALL.  Any categories that don't have a
     * corresponding environment variable set should be set to 'default_name'
     *
     * Simply find the values for all categories, and call the function to
     * compute LC_ALL. */
    for (i = 0; i < LC_ALL_INDEX_; i++) {
        const char * const env_override = PerlEnv_getenv(category_names[i]);

        locale_names[i] = (env_override && strNE(env_override, ""))
                          ? env_override
                          : default_name;

        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                 "find_locale_from_environment i=%d, name=%s, locale=%s\n",
                 i, category_names[i], locale_names[i]));
    }

    return calculate_LC_ALL(locale_names);
}

#  endif

STATIC const char *
S_emulate_setlocale_i(pTHX_

        /* Our internal index of the 'category' setlocale is
           called with */
        const unsigned int index,

        const char * new_locale, /* The locale to set the category to */
        const recalc_lc_all_t recalc_LC_ALL,  /* Explained below */
        const line_t line     /* Called from this line number */
       )
{
    PERL_ARGS_ASSERT_EMULATE_SETLOCALE_I;
    assert(index <= NOMINAL_LC_ALL_INDEX);

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
     *
     * This function may be called in a tight loop that iterates over all
     * categories.  Because LC_ALL is not a "real" category, but merely the sum
     * of all the other ones, such loops don't include LC_ALL.  On systems that
     * have querylocale() or similar, the current LC_ALL value is immediately
     * retrievable; on systems lacking that feature, we have to keep track of
     * LC_ALL ourselves.  We could do that on each iteration, only to throw it
     * away on the next, but the calculation is more than a trivial amount of
     * work.  Instead, the 'recalc_LC_ALL' parameter is set to
     * RECALCULATE_LC_ALL_ON_FINAL_INTERATION to only do the calculation once.
     * This function calls itself recursively in such a loop.
     *
     * When not in such a loop, the parameter is set to the other enum values
     * DONT_RECALC_LC_ALL or YES_RECALC_LC_ALL. */

    int mask = category_masks[index];
    const locale_t entry_obj = uselocale((locale_t) 0);
    const char * locale_on_entry = querylocale_i(index);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
             "emulate_setlocale_i input=%d (%s), mask=0x%x,"
             " new locale=\"%s\", current locale=\"%s\","
             "index=%d, object=%p\n",
             categories[index], category_names[index], mask,
             ((new_locale == NULL) ? "(nil)" : new_locale),
             locale_on_entry, index, entry_obj));

    /* Return the already-calculated info if just querying what the existing
     * locale is */
    if (new_locale == NULL) {
        return locale_on_entry;
    }

    /* Here, trying to change the locale, but it is a no-op if the new boss is
     * the same as the old boss.  Except this routine is called when converting
     * from the global locale, so in that case we will create a per-thread
     * locale below (with the current values).  Bitter experience also
     * indicates that newlocale() can free up the basis locale memory if we
     * call it with the new and old being the same. */
    if (   entry_obj != LC_GLOBAL_LOCALE
        && locale_on_entry
        && strEQ(new_locale, locale_on_entry))
    {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                 "(%" LINE_Tf "): emulate_setlocale_i"
                 " no-op to change to what it already was\n",
                 line));

#  ifdef USE_PL_CURLOCALES

       /* On the final iteration of a loop that needs to recalculate LC_ALL, do
        * so.  If no iteration changed anything, LC_ALL also doesn't change,
        * but khw believes the complexity needed to keep track of that isn't
        * worth it. */
        if (UNLIKELY(   recalc_LC_ALL == RECALCULATE_LC_ALL_ON_FINAL_INTERATION
                     && index == NOMINAL_LC_ALL_INDEX - 1))
        {
            Safefree(PL_curlocales[LC_ALL_INDEX_]);
            PL_curlocales[LC_ALL_INDEX_] =
                                        savepv(calculate_LC_ALL(PL_curlocales));
        }

#  endif

        return locale_on_entry;
    }

#  ifndef USE_QUERYLOCALE

    /* Without a querylocale() mechanism, we have to figure out ourselves what
     * happens with setting a locale to "" */
    if (strEQ(new_locale, "")) {
        new_locale = find_locale_from_environment(index);
    }

#  endif

    /* So far, it has worked that a semi-colon in the locale name means that
     * the category is LC_ALL and it subsumes categories which don't all have
     * the same locale.  This is the glibc syntax. */
    if (strchr(new_locale, ';')) {
        assert(index == LC_ALL_INDEX_);
        return setlocale_from_aggregate_LC_ALL(new_locale, line);
    }

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
        setlocale_failure_panic_i(index, locale_on_entry, "C", __LINE__, line);
        NOT_REACHED; /* NOTREACHED */
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
             "(%" LINE_Tf "): emulate_setlocale_i now using C"
             " object=%p\n", line, PL_C_locale_obj));

    locale_t new_obj;

    /* We created a (never changing) object at start-up for LC_ALL being in the
     * C locale.  If this call is to switch to LC_ALL=>C, simply use that
     * object.  But in fact, we already have switched to it just above, in
     * preparation for the general case.  Since we're already there, no need to
     * do further switching. */
    if (mask == LC_ALL_MASK && isNAME_C_OR_POSIX(new_locale)) {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "(%" LINE_Tf "):"
                                               " emulate_setlocale_i will stay"
                                               " in C object\n", line));
        new_obj = PL_C_locale_obj;

        /* And free the old object if it isn't a special one */
        if (entry_obj != LC_GLOBAL_LOCALE && entry_obj != PL_C_locale_obj) {
            freelocale(entry_obj);
        }
    }
    else {  /* Here is the general case, not to LC_ALL=>C */
        locale_t basis_obj = entry_obj;

        /* Specially handle two objects */
        if (basis_obj == LC_GLOBAL_LOCALE || basis_obj == PL_C_locale_obj) {

            /* For these two objects, we make duplicates to hand to newlocale()
             * below.  For LC_GLOBAL_LOCALE, this is because newlocale()
             * doesn't necessarily accept it as input (the results are
             * undefined).  For PL_C_locale_obj, it is so that it never gets
             * modified, as otherwise newlocale() is free to do so */
            basis_obj = duplocale(entry_obj);
            if (! basis_obj) {
                locale_panic_(Perl_form(aTHX_ "(%" LINE_Tf "): duplocale failed",
                                              line));
                NOT_REACHED; /* NOTREACHED */
            }

            DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                                   "(%" LINE_Tf "): emulate_setlocale_i"
                                   " created %p by duping the input\n",
                                   line, basis_obj));
        }

        /* Ready to create a new locale by modification of the exising one */
        new_obj = newlocale(mask, new_locale, basis_obj);

        if (! new_obj) {
            DEBUG_L(PerlIO_printf(Perl_debug_log,
                                  " (%" LINE_Tf "): emulate_setlocale_i"
                                  " creating new object from %p failed:"
                                  " errno=%d\n",
                                  line, basis_obj, GET_ERRNO));

            /* Failed.  Likely this is because the proposed new locale isn't
             * valid on this system.  But we earlier switched to the LC_ALL=>C
             * locale in anticipation of it succeeding,  Now have to switch
             * back to the state upon entry */
            if (! uselocale(entry_obj)) {
                setlocale_failure_panic_i(index, "switching back to",
                                          locale_on_entry, __LINE__, line);
                NOT_REACHED; /* NOTREACHED */
            }

#    ifdef USE_PL_CURLOCALES

            if (entry_obj == LC_GLOBAL_LOCALE) {

                /* Here, we are back in the global locale.  We may never have
                 * set PL_curlocales.  If the locale change had succeeded, the
                 * code would have then set them up, but since it didn't, do so
                 * here.  khw isn't sure if this prevents some issues or not,
                 * but tis is defensive coding.  The system setlocale() returns
                 * the desired information.  This will calculate LC_ALL's entry
                 * only on the final iteration */
                POSIX_SETLOCALE_LOCK;
                for (PERL_UINT_FAST8_T i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
                    update_PL_curlocales_i(i,
                                       posix_setlocale(categories[i], NULL),
                                       RECALCULATE_LC_ALL_ON_FINAL_INTERATION);
                }
                POSIX_SETLOCALE_UNLOCK;
            }
#    endif

            return NULL;
        }

        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "(%" LINE_Tf "): emulate_setlocale_i created %p"
                               " while freeing %p\n", line, new_obj, basis_obj));

        /* Here, successfully created an object representing the desired
         * locale; now switch into it */
        if (! uselocale(new_obj)) {
            freelocale(new_obj);
            locale_panic_(Perl_form(aTHX_ "(%" LINE_Tf "): emulate_setlocale_i"
                                          " switching into new locale failed",
                                          line));
        }
    }

    /* Here, we are using 'new_obj' which matches the input 'new_locale'. */
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
             "(%" LINE_Tf "): emulate_setlocale_i now using %p\n", line, new_obj));

    /* We are done, except for updating our records (if the system doesn't keep
     * them) and in the case of locale "", we don't actually know what the
     * locale that got switched to is, as it came from the environment.  So
     * have to find it */

#  ifdef USE_QUERYLOCALE

    if (strEQ(new_locale, "")) {
        new_locale = querylocale_i(index);
    }

    PERL_UNUSED_ARG(recalc_LC_ALL);

#  else

    new_locale = update_PL_curlocales_i(index, new_locale, recalc_LC_ALL);

#  endif
#  ifdef HAS_GLIBC_LC_MESSAGES_BUG

    /* Invalidate the glibc cache of loaded translations if the locale has changed,
     * see [perl #134264] */
    if (old_messages_locale) {
        if (strNE(old_messages_locale, my_querylocale_c(LC_MESSAGES))) {
            textdomain(textdomain(NULL));
        }
    }

#  endif

    return new_locale;
}

#endif   /* End of the various implementations of the setlocale and
            querylocale macros used in the remainder of this program */

#ifdef USE_LOCALE

/* So far, the locale strings returned by modern 2008-compliant systems have
 * been fine */

STATIC const char *
S_stdize_locale(pTHX_ const int category,
                      const char *input_locale,
                      const char **buf,
                      Size_t *buf_size,
                      const line_t caller_line)
{
    /* The return value of setlocale() is opaque, but is required to be usable
     * as input to a future setlocale() to create the same state.
     * Unfortunately not all systems are compliant.  But most often they are of
     * a very restricted set of forms that this file has been coded to expect.
     *
     * There are some outliers, though, that this function tries to tame:
     *
     * 1) A new-line.  This function chomps any \n characters
     * 2) foo=bar.     'bar' is what is generally meant, and the foo= part is
     *                 stripped.  This form is legal for LC_ALL.  When found in
     *                 that category group, the function calls itself
     *                 recursively on each possible component category to make
     *                 sure the individual categories are ok.
     *
     * If no changes to the input were made, it is returned; otherwise the
     * changed version is stored into memory at *buf, with *buf_size set to its
     * new value, and *buf is returned.
     */

    const char * first_bad;
    const char * retval;

    PERL_ARGS_ASSERT_STDIZE_LOCALE;

    if (input_locale == NULL) {
        return NULL;
    }

    first_bad = strpbrk(input_locale, "=\n");

    /* Most likely, there isn't a problem with the input */
    if (LIKELY(! first_bad)) {
        return input_locale;
    }

#    ifdef LC_ALL

    /* But if there is, and the category is LC_ALL, we have to look at each
     * component category */
    if (category == LC_ALL) {
        const char * individ_locales[LC_ALL_INDEX_];
        bool made_changes = FALSE;
        unsigned int i;

        for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
            Size_t this_size = 0;
            individ_locales[i] = stdize_locale(categories[i],
                                               posix_setlocale(categories[i],
                                                               NULL),
                                               &individ_locales[i],
                                               &this_size,
                                               caller_line);

            /* If the size didn't change, it means this category did not have
             * to be adjusted, and individ_locales[i] points to the buffer
             * returned by posix_setlocale(); we have to copy that before
             * it's called again in the next iteration */
            if (this_size == 0) {
                individ_locales[i] = savepv(individ_locales[i]);
            }
            else {
                made_changes = TRUE;
            }
        }

        /* If all the individual categories were ok as-is, this was a false
         * alarm.  We must have seen an '=' which was a legal occurrence in
         * this combination locale */
        if (! made_changes) {
            retval = input_locale;  /* The input can be returned unchanged */
        }
        else {
            retval = save_to_buffer(querylocale_c(LC_ALL), buf, buf_size);
        }

        for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
            Safefree(individ_locales[i]);
        }

        return retval;
    }

#    else   /* else no LC_ALL */

    PERL_UNUSED_ARG(category);
    PERL_UNUSED_ARG(caller_line);

#    endif

    /* Here, there was a problem in an individual category.  This means that at
     * least one adjustment will be necessary.  Create a modifiable copy */
    retval = save_to_buffer(input_locale, buf, buf_size);

    if (*first_bad != '=') {

        /* Translate the found position into terms of the copy */
        first_bad = retval + (first_bad - input_locale);
    }
    else { /* An '=' */

        /* It is unlikely that the return is so screwed-up that it contains
         * multiple equals signs, but handle that case by stripping all of
         * them.  */
        const char * final_equals = strrchr(retval, '=');

        /* The length passed here causes the move to include the terminating
         * NUL */
        Move(final_equals + 1, retval, strlen(final_equals), char);

        /* See if there are additional problems; if not, we're good to return.
         * */
        first_bad = strpbrk(retval, "\n");

        if (! first_bad) {
            return retval;
        }
    }

    /* Here, the problem must be a \n.  Get rid of it and what follows.
     * (Originally, only a trailing \n was stripped.  Unsure what to do if not
     * trailing) */
    *((char *) first_bad) = '\0';
    return retval;
}

#if defined(USE_POSIX_2008_LOCALE) || ! defined(LC_ALL)

STATIC
const char *

#  ifdef USE_QUERYLOCALE
S_calculate_LC_ALL(pTHX_ const locale_t cur_obj)
#  else
S_calculate_LC_ALL(pTHX_ const char ** individ_locales)
#  endif

{
    /* For POSIX 2008, we have to figure out LC_ALL ourselves when needed.
     * querylocale(), on systems that have it, doesn't tend to work for LC_ALL.
     * So we have to construct the answer ourselves based on the passed in
     * data, which is either a locale_t object, for systems with querylocale(),
     * or an array we keep updated to the proper values, otherwise.
     *
     * This returns a mortalized string containing the locale name(s) of
     * LC_ALL.
     *
     * If all individual categories are the same locale, we can just set LC_ALL
     * to that locale.  But if not, we have to create an aggregation of all the
     * categories on the system.  Platforms differ as to the syntax they use
     * for these non-uniform locales for LC_ALL.  Some use a '/' or other
     * delimiter of the locales with a predetermined order of categories; a
     * Configure probe would be needed to tell us how to decipher those.  glibc
     * uses a series of name=value pairs, like
     *      LC_NUMERIC=C;LC_TIME=en_US.UTF-8;...
     * The syntax we use for our aggregation doesn't much matter, as we take
     * care not to use the native setlocale() function on whatever style is
     * chosen.  But, it would be possible for someone to call Perl_setlocale()
     * using a native style we don't understand.  So far no one has complained.
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

    unsigned int i;
    Size_t names_len = 0;
    bool are_all_categories_the_same_locale = TRUE;
    char * aggregate_locale;
    char * previous_start = NULL;
    char * this_start = NULL;
    Size_t entry_len = 0;

    PERL_ARGS_ASSERT_CALCULATE_LC_ALL;

    /* First calculate the needed size for the string listing the categories
     * and their locales. */
    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {

#  ifdef USE_QUERYLOCALE
        const char * entry = querylocale_l(i, cur_obj);
#  else
        const char * entry = individ_locales[i];
#  endif

        names_len += strlen(category_names[i])
                  + 1                           /* '=' */
                  + strlen(entry)
                  + 1;                          /* ';' */
    }

    names_len++;    /* Trailing '\0' */

    /* Allocate enough space for the aggregated string */
    SAVEFREEPV(Newxz(aggregate_locale, names_len, char));

    /* Then fill it in */
    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        Size_t new_len;

#  ifdef USE_QUERYLOCALE
        const char * entry = querylocale_l(i, cur_obj);
#  else
        const char * entry = individ_locales[i];
#  endif

        new_len = my_strlcat(aggregate_locale, category_names[i], names_len);
        assert(new_len <= names_len);
        new_len = my_strlcat(aggregate_locale, "=", names_len);
        assert(new_len <= names_len);

        this_start = aggregate_locale + strlen(aggregate_locale);
        entry_len = strlen(entry);

        new_len = my_strlcat(aggregate_locale, entry, names_len);
        assert(new_len <= names_len);
        new_len = my_strlcat(aggregate_locale, ";", names_len);
        assert(new_len <= names_len);
        PERL_UNUSED_VAR(new_len);   /* Only used in DEBUGGING */

        if (   i > 0
            && are_all_categories_the_same_locale
            && memNE(previous_start, this_start, entry_len + 1))
        {
            are_all_categories_the_same_locale = FALSE;
        }
        else {
            previous_start = this_start;
        }
    }

    /* If they are all the same, just return any one of them */
    if (are_all_categories_the_same_locale) {
        aggregate_locale = this_start;
        aggregate_locale[entry_len] = '\0';
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "calculate_LC_ALL returning '%s'\n",
                           aggregate_locale));

    return aggregate_locale;
}

#endif

#if defined(USE_LOCALE) && defined(DEBUGGING)

STATIC const char *
S_get_LC_ALL_display(pTHX)
{

#  ifdef LC_ALL

    return querylocale_c(LC_ALL);

#  else

    const char * curlocales[NOMINAL_LC_ALL_INDEX];

    for (unsigned i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        curlocales[i] = querylocale_i(i);
    }

    return calculate_LC_ALL(curlocales);

#  endif

}

#endif

STATIC void
S_setlocale_failure_panic_i(pTHX_
                            const unsigned int cat_index,
                            const char * current,
                            const char * failed,
                            const line_t caller_0_line,
                            const line_t caller_1_line)
{
    dSAVE_ERRNO;
    const int cat = categories[cat_index];
    const char * name = category_names[cat_index];

    PERL_ARGS_ASSERT_SETLOCALE_FAILURE_PANIC_I;

    if (current == NULL) {
        current = querylocale_i(cat_index);
    }

    Perl_locale_panic(Perl_form(aTHX_ "(%" LINE_Tf
                                      "): Can't change locale for %s(%d)"
                                      " from '%s' to '%s'",
                                      caller_1_line, name, cat,
                                      current, failed),
                      __FILE__, caller_0_line, GET_ERRNO);
    NOT_REACHED; /* NOTREACHED */
}

/* Any of these will allow us to find the RADIX */
#  if defined(USE_LOCALE_NUMERIC) && (   defined(HAS_SOME_LANGINFO)         \
                                      || defined(HAS_SOME_LOCALECONV)       \
                                      || defined(HAS_SNPRINTF))
#    define CAN_CALCULATE_RADIX
#  endif
#  ifdef USE_LOCALE_NUMERIC

STATIC void
S_new_numeric(pTHX_ const char *newnum)
{
    PERL_ARGS_ASSERT_NEW_NUMERIC;

    /* Called after each libc setlocale() call affecting LC_NUMERIC, to tell
     * core Perl this and that 'newnum' is the name of the new locale, and we
     * are switched into it.  It installs this locale as the current underlying
     * default, and then switches to the C locale, if necessary, so that the
     * code that has traditionally expected the radix character to be a dot may
     * continue to do so.
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
     * PL_numeric_underlying  A boolean indicating if the toggled state is such
     *                  that the current locale is the program's underlying
     *                  locale
     * PL_numeric_standard An int indicating if the toggled state is such
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
     * PL_numeric_radix_sv  Contains the string that code should use for the
     *                  decimal point.  It is set to either a dot or the
     *                  program's underlying locale's radix character string,
     *                  depending on the situation.
     * PL_underlying_radix_sv  Contains the program's underlying locale's radix
     *                  character string.  This is copied into
     *                  PL_numeric_radix_sv when the situation warrants.  It
     *                  exists to avoid having to recalculate it when toggling.
     * PL_underlying_numeric_obj = (only on POSIX 2008 platforms)  An object
     *                  with everything set up properly so as to avoid work on
     *                  such platforms.
     */

    DEBUG_L( PerlIO_printf(Perl_debug_log,
                           "Called new_numeric with %s, PL_numeric_name=%s\n",
                           newnum, PL_numeric_name));

    /* If this isn't actually a change, do nothing */
    if (strEQ(PL_numeric_name, newnum)) {
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
        sv_setpv(PL_underlying_radix_sv, C_decimal_point);
        return;
    }

    /* We are in the underlying locale until changed at the end of this
     * function */
    PL_numeric_underlying = TRUE;

#  ifdef USE_POSIX_2008_LOCALE

    /* We keep a special object for easy switching to */
    PL_underlying_numeric_obj = newlocale(LC_NUMERIC_MASK,
                                          PL_numeric_name,
                                          PL_underlying_numeric_obj);

#    endif

    const char * radix = NULL;
    utf8ness_t utf8ness = UTF8NESS_IMMATERIAL;

    /* Find and save this locale's radix character. */
    my_langinfo_c(RADIXCHAR, LC_NUMERIC, PL_numeric_name,
                  &radix, NULL, &utf8ness);
    sv_setpv(PL_underlying_radix_sv, radix);

    if (utf8ness == UTF8NESS_YES) {
        SvUTF8_on(PL_underlying_radix_sv);
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
     * get this value, which in almost all locales is empty, and doesn't appear
     * to be used in any of the Micrsoft library routines anyway. */

    const char * scratch_buffer = NULL;
    PL_numeric_underlying_is_standard &= strEQ(C_thousands_sep,
                                               my_langinfo_c(THOUSEP, LC_NUMERIC,
                                                             PL_numeric_name,
                                                             &scratch_buffer,
                                                             NULL, NULL));
    Safefree(scratch_buffer);

#    endif

    PL_numeric_standard = PL_numeric_underlying_is_standard;

    /* Keep LC_NUMERIC so that it has the C locale radix and thousands
     * separator.  This is for XS modules, so they don't have to worry about
     * the radix being a non-dot.  (Core operations that need the underlying
     * locale change to it temporarily). */
    if (! PL_numeric_standard) {
        set_numeric_standard();
    }

}

#  endif

void
Perl_set_numeric_standard(pTHX)
{

#  ifdef USE_LOCALE_NUMERIC

    /* Unconditionally toggle the LC_NUMERIC locale to the current underlying
     * default.
     *
     * Most code should use the macro SET_NUMERIC_STANDARD() in perl.h
     * instead of calling this directly.  The macro avoids calling this routine
     * if toggling isn't necessary according to our records (which could be
     * wrong if some XS code has changed the locale behind our back) */

    DEBUG_L(PerlIO_printf(Perl_debug_log,
                                  "Setting LC_NUMERIC locale to standard C\n"));

    void_setlocale_c(LC_NUMERIC, "C");
    PL_numeric_standard = TRUE;
    sv_setpv(PL_numeric_radix_sv, C_decimal_point);

    PL_numeric_underlying = PL_numeric_underlying_is_standard;

#  endif /* USE_LOCALE_NUMERIC */

}

void
Perl_set_numeric_underlying(pTHX)
{

#  ifdef USE_LOCALE_NUMERIC

    /* Unconditionally toggle the LC_NUMERIC locale to the current underlying
     * default.
     *
     * Most code should use the macro SET_NUMERIC_UNDERLYING() in perl.h
     * instead of calling this directly.  The macro avoids calling this routine
     * if toggling isn't necessary according to our records (which could be
     * wrong if some XS code has changed the locale behind our back) */

    DEBUG_L(PerlIO_printf(Perl_debug_log, "Setting LC_NUMERIC locale to %s\n",
                                          PL_numeric_name));

    void_setlocale_c(LC_NUMERIC, PL_numeric_name);
    PL_numeric_underlying = TRUE;
    sv_setsv_nomg(PL_numeric_radix_sv, PL_underlying_radix_sv);

    PL_numeric_standard = PL_numeric_underlying_is_standard;

#  endif /* USE_LOCALE_NUMERIC */

}

#  ifdef USE_LOCALE_CTYPE

STATIC void
S_new_ctype(pTHX_ const char *newctype)
{
    PERL_ARGS_ASSERT_NEW_CTYPE;

    /* Called after each libc setlocale() call affecting LC_CTYPE, to tell
     * core Perl this and that 'newctype' is the name of the new locale.
     *
     * This function sets up the folding arrays for all 256 bytes, assuming
     * that tofold() is tolc() since fold case is not a concept in POSIX,
     */

    DEBUG_L(PerlIO_printf(Perl_debug_log, "Entering new_ctype(%s)\n", newctype));

    /* No change means no-op */
    if (strEQ(PL_ctype_name, newctype)) {
        return;
    }

    /* We will replace any bad locale warning with 1) nothing if the new one is
     * ok; or 2) a new warning for the bad new locale */
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

    /* The cache being cleared signals this to compute a new value */
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

    /* We only handle single-byte locales (outside of UTF-8 ones; so if this
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
                         " interpreter.\n",
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
                if (UNLIKELY(cBOOL(isU8_ALPHANUMERIC_LC(i)) != cBOOL(isALPHANUMERIC_A(i))))  {
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
                if (UNLIKELY(cBOOL(isU8_XDIGIT_LC(i))!= cBOOL(isXDIGIT_A(i))))  {
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
            PL_fold_locale['I'] = 'I';
            PL_fold_locale['i'] = 'i';
            PL_in_utf8_turkic_locale = TRUE;
            DEBUG_L(PerlIO_printf(Perl_debug_log, "%s is turkic\n", newctype));
        }

        /* If we found problems and we want them output, do so */
        if (   (UNLIKELY(bad_count))
            && (LIKELY(ckWARN_d(WARN_LOCALE)) || UNLIKELY(DEBUG_L_TEST)))
        {
            if (UNLIKELY(bad_count) && PL_in_utf8_CTYPE_locale) {
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

#    ifdef HAS_SOME_LANGINFO

            const char * scratch_buffer = NULL;
            Perl_sv_catpvf(aTHX_ PL_warn_locale, "; codeset=%s",
                                 my_langinfo_c(CODESET, LC_CTYPE,
                                               newctype,
                                               &scratch_buffer, NULL,
                                               NULL));
            Safefree(scratch_buffer);

#  endif

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

#  endif /* USE_LOCALE_CTYPE */

void
Perl__warn_problematic_locale()
{

#  ifdef USE_LOCALE_CTYPE

    dTHX;

    /* Internal-to-core function that outputs the message in PL_warn_locale,
     * and then NULLS it.  Should be called only through the macro
     * CHECK_AND_WARN_PROBLEMATIC_LOCALE_ */

    if (PL_warn_locale) {
        Perl_ck_warner(aTHX_ packWARN(WARN_LOCALE),
                             SvPVX(PL_warn_locale),
                             0 /* dummy to avoid compiler warning */ );
        SvREFCNT_dec_NN(PL_warn_locale);
        PL_warn_locale = NULL;
    }

#  endif

}

STATIC void
S_new_LC_ALL(pTHX_ const char *unused)
{
    unsigned int i;

    /* LC_ALL updates all the things we care about. */

    PERL_UNUSED_ARG(unused);

    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        if (update_functions[i]) {
            const char * this_locale = querylocale_i(i);
            update_functions[i](aTHX_ this_locale);
        }
    }
}

#  ifdef USE_LOCALE_COLLATE

STATIC void
S_new_collate(pTHX_ const char *newcoll)
{
    PERL_ARGS_ASSERT_NEW_COLLATE;


    /* Called after each libc setlocale() call affecting LC_COLLATE, to tell
     * core Perl this and that 'newcoll' is the name of the new locale.
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
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "Setting PL_collation name='%s'\n", PL_collation_name));
        PL_collxfrm_base = 0;
        PL_collxfrm_mult = 2;
        PL_in_utf8_COLLATE_locale = FALSE;
        PL_strxfrm_NUL_replacement = '\0';
        PL_strxfrm_max_cp = 0;
        return;
    }

    /* Flag that the remainder of the set up is being deferred until first need */
    PL_collxfrm_mult = 0;
    PL_collxfrm_base = 0;

}

#  endif /* USE_LOCALE_COLLATE */
#endif  /* USE_LOCALE */

#ifdef WIN32

wchar_t *
Perl_Win_utf8_string_to_wstring(const char * utf8_string)
{
    wchar_t *wstring;

    int req_size = MultiByteToWideChar(CP_UTF8, 0, utf8_string, -1, NULL, 0);
    if (! req_size) {
        errno = EINVAL;
        return NULL;
    }

    Newx(wstring, req_size, wchar_t);

    if (! MultiByteToWideChar(CP_UTF8, 0, utf8_string, -1, wstring, req_size))
    {
        Safefree(wstring);
        errno = EINVAL;
        return NULL;
    }

    return wstring;
}

char *
Perl_Win_wstring_to_utf8_string(const wchar_t * wstring)
{
    char *utf8_string;

    int req_size =
              WideCharToMultiByte(CP_UTF8, 0, wstring, -1, NULL, 0, NULL, NULL);

    Newx(utf8_string, req_size, char);

    if (! WideCharToMultiByte(CP_UTF8, 0, wstring, -1, utf8_string,
                                                         req_size, NULL, NULL))
    {
        Safefree(utf8_string);
        errno = EINVAL;
        return NULL;
    }

    return utf8_string;
}

#define USE_WSETLOCALE

#ifdef USE_WSETLOCALE

STATIC char *
S_wrap_wsetlocale(pTHX_ int category, const char *locale) {
    wchar_t *wlocale = NULL;
    wchar_t *wresult;
    char *result;

    if (locale) {
        wlocale = Win_utf8_string_to_wstring(locale);
        if (! wlocale) {
            return NULL;
        }
    }
    else {
        wlocale = NULL;
    }

    wresult = _wsetlocale(category, wlocale);
    Safefree(wlocale);

    if (! wresult) {
            return NULL;
        }

    result = Win_wstring_to_utf8_string(wresult);
    SAVEFREEPV(result); /* is there something better we can do here? */

    return result;
}

#endif

STATIC char *
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

    bool override_LC_ALL = FALSE;
    char * result;
    unsigned int i;

    if (locale && strEQ(locale, "")) {

#  ifdef LC_ALL

        locale = PerlEnv_getenv("LC_ALL");
        if (! locale) {
            if (category ==  LC_ALL) {
                override_LC_ALL = TRUE;
            }
            else {

#  endif

                for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
                    if (category == categories[i]) {
                        locale = PerlEnv_getenv(category_names[i]);
                        goto found_locale;
                    }
                }

                locale = PerlEnv_getenv("LANG");
                if (! locale) {
                    locale = "";
                }

              found_locale: ;

#  ifdef LC_ALL

            }
        }

#  endif

    }

#ifdef USE_WSETLOCALE
    result = S_wrap_wsetlocale(aTHX_ category, locale);
#else
    result = setlocale(category, locale);
#endif
    DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                          setlocale_debug_string_r(category, locale, result)));

    if (! override_LC_ALL)  {
        return result;
    }

    /* Here the input category was LC_ALL, and we have set it to what is in the
     * LANG variable or the system default if there is no LANG.  But these have
     * lower priority than the other LC_foo variables, so override it for each
     * one that is set.  (If they are set to "", it means to use the same thing
     * we just set LC_ALL to, so can skip) */

    for (i = 0; i < LC_ALL_INDEX_; i++) {
        result = PerlEnv_getenv(category_names[i]);
        if (result && strNE(result, "")) {
#ifdef USE_WSETLOCALE
            S_wrap_wsetlocale(aTHX_ categories[i], result);
#else
            setlocale(categories[i], result);
#endif
            DEBUG_Lv(PerlIO_printf(Perl_debug_log, "%s\n",
                setlocale_debug_string_i(i, result, "not captured")));
        }
    }

    result = setlocale(LC_ALL, NULL);
    DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                          setlocale_debug_string_c(LC_ALL, NULL, result)));

    return result;
}

#endif

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

C<Perl_setlocale> should not be used to change the locale except on systems
where the predefined variable C<${^SAFE_LOCALES}> is 1.  On some such systems,
the system C<setlocale()> is ineffective, returning the wrong information, and
failing to actually change the locale.  C<Perl_setlocale>, however works
properly in all circumstances.

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

    /* A NULL locale means only query what the current one is. */
    if (locale == NULL) {

#  ifndef USE_LOCALE_NUMERIC

        /* Without LC_NUMERIC, it's trivial; we just return the value */
        return save_to_buffer(querylocale_r(category),
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
        return save_to_buffer(querylocale_r(category),
                              &PL_setlocale_buf, &PL_setlocale_bufsize);

#    else

        /* Here, LC_ALL is available on this platform.  It's the one
         * complicating category (because it can contain a toggled LC_NUMERIC
         * value), for all the remaining ones (we took care of LC_NUMERIC
         * above), just return the value */
        if (category != LC_ALL) {
            return save_to_buffer(querylocale_r(category),
                                  &PL_setlocale_buf, &PL_setlocale_bufsize);
        }

        bool toggled = FALSE;

        /* For an LC_ALL query, switch back to the underlying numeric locale
         * (if we aren't there already) so as to get the correct results.  Our
         * records for all the other categories are valid without switching */
        if (! PL_numeric_underlying) {
            set_numeric_underlying();
            toggled = TRUE;
        }

        retval = querylocale_c(LC_ALL);

        if (toggled) {
            set_numeric_standard();
        }

        DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                            setlocale_debug_string_r(category, locale, retval)));

        return save_to_buffer(retval, &PL_setlocale_buf, &PL_setlocale_bufsize);

#    endif      /* Has LC_ALL */
#  endif        /* Has LC_NUMERIC */

    } /* End of querying the current locale */


    /* Here, the input has a locale to change to.  First find the current
     * locale */
    unsigned int cat_index = get_category_index(category, NULL);
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
        return save_to_buffer(setlocale_i(cat_index, locale),
                              &PL_setlocale_buf, &PL_setlocale_bufsize);
    }

    /* Here, an actual change is being requested.  Do it */
    retval = setlocale_i(cat_index, locale);

    if (! retval) {
        DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",
                          setlocale_debug_string_i(cat_index, locale, "NULL")));
        return NULL;
    }

    assert(strNE(retval, ""));
    retval = save_to_buffer(retval, &PL_setlocale_buf, &PL_setlocale_bufsize);

    /* Now that have changed locales, we have to update our records to
     * correspond.  Only certain categories have extra work to update. */
    if (update_functions[cat_index]) {
        update_functions[cat_index](aTHX_ retval);
    }

    DEBUG_L(PerlIO_printf(Perl_debug_log, "returning '%s'\n", retval));

    return retval;

#endif

}

#ifdef USE_LOCALE

STATIC const char *
S_save_to_buffer(const char * string, const char **buf, Size_t *buf_size)
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
     * If *buf or 'buf_size' are NULL or *buf_size is 0, the buffer is assumed
     * empty, and memory is malloc'd.   'buf-size' being NULL is to be used
     * when this is a single use buffer, which will shortly be freed by the
     * caller.
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

    {
        dTHX_DEBUGGING;
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                         "Copying '%s' to %p\n",
                         ((is_utf8_string((U8 *) string, 0))
                          ? string
                          :_byte_dump_string((U8 *) string, strlen(string), 0)),
                          *buf));
            }

#    ifdef DEBUGGING

    /* Catch glitches.  Usually this is because LC_CTYPE needs to be the same
     * locale as whatever is being worked on */
    if (UNLIKELY(instr(string, REPLACEMENT_CHARACTER_UTF8))) {
        dTHX_DEBUGGING;

        locale_panic_(Perl_form(aTHX_
                                "Unexpected REPLACEMENT_CHARACTER in '%s'\n%s",
                                string, get_LC_ALL_display()));
    }

#    endif

    Copy(string, *buf, string_size, char);
    return *buf;
}

STATIC utf8ness_t
S_get_locale_string_utf8ness_i(pTHX_ const char * locale,
                                     const unsigned cat_index,
                                     const char * string,
                                     const locale_utf8ness_t known_utf8)
{
    /* Return to indicate if 'string' in the locale given by the input
     * arguments should be considered UTF-8 or not.
     *
     * If the input 'locale' is not NULL, use that for the locale; otherwise
     * use the current locale for the category specified by 'cat_index'.
     */

    Size_t len;
    const U8 * first_variant = NULL;

    PERL_ARGS_ASSERT_GET_LOCALE_STRING_UTF8NESS_I;
    assert(cat_index <= NOMINAL_LC_ALL_INDEX);

    if (string == NULL) {
        return UTF8NESS_NO;
    }

    if (IN_BYTES) { /* respect 'use bytes' */
        return UTF8NESS_NO;
    }

    len = strlen(string);

    /* UTF8ness is immaterial if the representation doesn't vary */
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

#  if defined(HAS_SOME_LANGINFO) || defined(HAS_MBTOWC) || defined(HAS_MBRTOWC)

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

#  else

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

}

#  ifdef WIN32

bool
Perl_get_win32_message_utf8ness(pTHX_ const char * string)
{
    /* NULL => locale irrelevant, 0 => category irrelevant
     * so returns based on the UTF-8 legality of the input string, ignoring the
     * locale and category completely.
     *
     * This is because Windows doesn't have LC_MESSAGES */
    return get_locale_string_utf8ness_i(NULL, 0, string, LOCALE_IS_UTF8);
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
#   if defined(HAS_MBRTOWC)                                     \
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

        MBTOWC_LOCK_;
        SETERRNO(0, 0);
        retval = mbtowc(NULL, NULL, 0);
        MBTOWC_UNLOCK_;
        return retval;

#  endif

    }

#  if defined(USE_MBRTOWC)

    SETERRNO(0, 0);
    retval = (SSize_t) mbrtowc((wchar_t *) pwc, s, len, &PL_mbrtowc_ps);

#  else

    /* Locking prevents races, but locales can be switched out without locking,
     * so this isn't a cure all */
    MBTOWC_LOCK_;
    SETERRNO(0, 0);
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

#if  ! defined(HAS_SOME_LOCALECONV)                                     \
 || (! defined(USE_LOCALE_MONETARY) && ! defined(USE_LOCALE_NUMERIC))

    return newHV();

#else

    return my_localeconv(0, LOCALE_UTF8NESS_UNKNOWN);

#endif

}

#if  defined(HAS_SOME_LOCALECONV)                                   \
 && (defined(USE_LOCALE_MONETARY) || defined(USE_LOCALE_NUMERIC))

HV *
S_my_localeconv(pTHX_ const int item, const locale_utf8ness_t locale_is_utf8)
{
    HV * retval;
    locale_utf8ness_t numeric_locale_is_utf8  = LOCALE_UTF8NESS_UNKNOWN;
    locale_utf8ness_t monetary_locale_is_utf8 = LOCALE_UTF8NESS_UNKNOWN;
    HV * (*copy_localeconv)(pTHX_ const struct lconv *,
                                  const int,
                                  const locale_utf8ness_t,
                                  const locale_utf8ness_t);

    /* A thread-safe locale_conv().  The locking mechanisms vary greatly
     * depending on platform capabilities.  They all share this common set up
     * code for the function, and then conditional compilations choose one of
     * several terminations.
     *
     * There are two use cases:
     * 1) Called from POSIX::locale_conv().  This returns lconv() copied to
     *    a hash, based on the current underlying locale.
     * 2) Certain items that nl_langinfo() provides are also derivable from
     *    the return of localeconv().  Windows notably doesn't have
     *    nl_langinfo(), so on that, and actually any platform lacking it,
     *    my_localeconv() is used to emulate it for those particular items.
     *    The code to do this is compiled only on such platforms.  Rather than
     *    going to the expense of creating a full hash when only one item is
     *    needed, just the desired item is returned, in an SV cast to an HV.
     *
     * There is a helper function to accomplish each of the two tasks.  The
     * function pointer just below is set to the appropriate one, and is called
     * from each of the various implementations, in the middle of whatever
     * necessary locking/locale swapping have been done. */

#  ifdef HAS_SOME_LANGINFO

    PERL_UNUSED_ARG(item);
    PERL_UNUSED_ARG(locale_is_utf8);

#    ifdef USE_LOCALE_NUMERIC

    /* When there is a nl_langinfo, we will only be called for localeconv
     * numeric purposes. */
    const bool is_localeconv_call = true;

#    endif

#  else

    /* Note we use this sentinel; this works because this only gets compiled
     * when our perl_langinfo.h is used, and that uses negative numbers for all
     * the items */
    const bool is_localeconv_call = (item == 0);
    if (is_localeconv_call)

#  endif

    {
        copy_localeconv = S_populate_localeconv;

#    ifdef USE_LOCALE_NUMERIC

        /* Get the UTF8ness of the locales now to avoid repeating this for each
         * string returned by localeconv() */
        numeric_locale_is_utf8 = (is_locale_utf8(PL_numeric_name))
                                  ? LOCALE_IS_UTF8
                                  : LOCALE_NOT_UTF8;

#    endif
#    ifdef USE_LOCALE_MONETARY

        monetary_locale_is_utf8 = (is_locale_utf8(querylocale_c(LC_MONETARY)))
                                  ? LOCALE_IS_UTF8
                                  : LOCALE_NOT_UTF8;

#  endif

    }

#  ifndef HAS_SOME_LANGINFO

    else {
        copy_localeconv = S_get_nl_item_from_localeconv;
        numeric_locale_is_utf8 = locale_is_utf8;
    }

#  endif

    PERL_ARGS_ASSERT_MY_LOCALECONV;
/*--------------------------------------------------------------------------*/
/* Here, we are done with the common beginning of all the implementations of
 * my_localeconv().  Below are the various terminations of the function (except
 * the closing '}'.  They are separated out because the preprocessor directives
 * were making the simple logic hard to follow.  Each implementation ends with
 * the same few lines.  khw decided to keep those separate because he thought
 * it was clearer to the reader.
 *
 * The first distinct termination (of the above common code) are the
 * implementations when we have locale_conv_l() and can use it.  These are the
 * simplest cases, without any locking needed. */
#  if defined(USE_POSIX_2008_LOCALE) && defined(HAS_LOCALECONV_L)

     /* And there are two sub-cases: First (by far the most common) is where we
      * are compiled to pay attention to LC_NUMERIC */
#    ifdef USE_LOCALE_NUMERIC

    const locale_t cur = use_curlocale_scratch();
    locale_t with_numeric = duplocale(cur);

    /* Just create a new locale object with what we've got, but using the
     * underlying LC_NUMERIC locale */
    with_numeric = newlocale(LC_NUMERIC_MASK, PL_numeric_name, with_numeric);

    retval = copy_localeconv(aTHX_ localeconv_l(with_numeric),
                                   item,
                                   numeric_locale_is_utf8,
                                   monetary_locale_is_utf8);
    freelocale(with_numeric);

    return retval;

/*--------------------------------------------------------------------------*/
#    else   /* Below not paying attention to LC_NUMERIC */

    const locale_t cur = use_curlocale_scratch();

    retval = copy_localeconv(aTHX_ localeconv_l(cur),
                                   item,
                                   numeric_locale_is_utf8,
                                   monetary_locale_is_utf8);
    return retval;

#    endif  /* Above, using lconv_l(); below plain lconv() */
/*--------------------------------------------------------------------------*/
#  elif ! defined(TS_W32_BROKEN_LOCALECONV)  /* Next is regular lconv() */

    /* There are so many locks because localeconv() deals with two
     * categories, and returns in a single global static buffer.  Some
     * locks might be no-ops on this platform, but not others.  We need to
     * lock if any one isn't a no-op. */

#    ifdef USE_LOCALE_NUMERIC

    LC_NUMERIC_LOCK(0);
    const char * orig_switched_locale = NULL;

    /* When called internally, are already switched into the proper numeric
     * locale; otherwise must toggle to it */
    if (is_localeconv_call) {
        orig_switched_locale = toggle_locale_c(LC_NUMERIC, PL_numeric_name);
    }

#    endif

    gwLOCALE_LOCK;
    retval = copy_localeconv(aTHX_ localeconv(),
                                   item,
                                   numeric_locale_is_utf8,
                                   monetary_locale_is_utf8);
    gwLOCALE_UNLOCK;

#    ifdef USE_LOCALE_NUMERIC

    if (orig_switched_locale) {
        restore_toggled_locale_c(LC_NUMERIC, orig_switched_locale);
    }
    LC_NUMERIC_UNLOCK;

#    endif

    return retval;

/*--------------------------------------------------------------------------*/
#  else /* defined(TS_W32_BROKEN_LOCALECONV) */

    /* Last is a workaround for the broken localeconv() on Windows with
     * thread-safe locales prior to VS 15.  It looks at the global locale
     * instead of the thread one.  As a work-around, we toggle to the global
     * locale; populate the return; then toggle back.  We have to use LC_ALL
     * instead of the individual categories because of another bug in Windows.
     *
     * This introduces a potential race with any other thread that has also
     * converted to use the global locale, and doesn't protect its locale calls
     * with mutexes.  khw can't think of any reason for a thread to do so on
     * Windows, as the locale API is the same regardless of thread-safety, except
     * if the code is ported from working on another platform where there might
     * be some reason to do this.  But this is typically due to some
     * alien-to-Perl library that thinks it owns locale setting.  Such a
     * library usn't likely to exist on Windows, so such an application is
     * unlikely to be run on Windows
     */
    bool restore_per_thread = FALSE;

#    ifdef USE_LOCALE_NUMERIC

    const char * orig_switched_locale = NULL;

    LC_NUMERIC_LOCK(0);

    /* When called internally, are already switched into the proper numeric
     * locale; otherwise must toggle to it */
    if (is_localeconv_call) {
        orig_switched_locale = toggle_locale_c(LC_NUMERIC, PL_numeric_name);
    }

#    endif

    /* Save the per-thread locale state */
    const char * save_thread = querylocale_c(LC_ALL);

    /* Change to the global locale, and note if we already were there */
    if (_configthreadlocale(_DISABLE_PER_THREAD_LOCALE)
                         != _DISABLE_PER_THREAD_LOCALE)
    {
        restore_per_thread = TRUE;
    }

    /* Save the state of the global locale; then convert to our desired
     * state.  */
    const char * save_global = querylocale_c(LC_ALL);
    void_setlocale_c(LC_ALL, save_thread);

    /* Safely stash the desired data */
    gwLOCALE_LOCK;
    retval = copy_localeconv(aTHX_ localeconv(),
                                   item,
                                   numeric_locale_is_utf8,
                                   monetary_locale_is_utf8);
    gwLOCALE_UNLOCK;

    /* Restore the global locale's prior state */
    void_setlocale_c(LC_ALL, save_global);

    /* And back to per-thread locales */
    if (restore_per_thread) {
        _configthreadlocale(_ENABLE_PER_THREAD_LOCALE);
    }

    /* Restore the per-thread locale state */
    void_setlocale_c(LC_ALL, save_thread);

#    ifdef USE_LOCALE_NUMERIC

    if (orig_switched_locale) {
        restore_toggled_locale_c(LC_NUMERIC, orig_switched_locale);
    }
    LC_NUMERIC_UNLOCK;

#    endif

    return retval;

#  endif
/*--------------------------------------------------------------------------*/
}

STATIC HV *
S_populate_localeconv(pTHX_ const struct lconv *lcbuf,
                            const int unused,
                            const locale_utf8ness_t numeric_locale_is_utf8,
                            const locale_utf8ness_t monetary_locale_is_utf8)
{
    /* This returns a mortalized hash containing all the elements returned by
     * localeconv().  It is used by Perl_localeconv() and POSIX::localeconv()
     */
    PERL_UNUSED_ARG(unused);

    struct lconv_offset {
        const char *name;
        size_t offset;
    };

    /* Create e.g.,
        {"thousands_sep", STRUCT_OFFSET(struct lconv, thousands_sep)},
     */
#  define LCONV_ENTRY(name)                                         \
            {STRINGIFY(name), STRUCT_OFFSET(struct lconv, name)}

    /* Set up structures containing the documented fields.  One structure for
     * LC_NUMERIC-controlled strings; one for LC_MONETARY ones, and a final one
     * of just numerics. */
#  ifdef USE_LOCALE_NUMERIC

    static const struct lconv_offset lconv_numeric_strings[] = {
        LCONV_ENTRY(decimal_point),
        LCONV_ENTRY(thousands_sep),
#    ifndef NO_LOCALECONV_GROUPING
        LCONV_ENTRY(grouping),
#    endif
        {NULL, 0}
    };

#  endif
#  ifdef USE_LOCALE_MONETARY

    static const struct lconv_offset lconv_monetary_strings[] = {
        LCONV_ENTRY(int_curr_symbol),
        LCONV_ENTRY(currency_symbol),
        LCONV_ENTRY(mon_decimal_point),
#    ifndef NO_LOCALECONV_MON_THOUSANDS_SEP
        LCONV_ENTRY(mon_thousands_sep),
#    endif
#    ifndef NO_LOCALECONV_MON_GROUPING
        LCONV_ENTRY(mon_grouping),
#    endif
        LCONV_ENTRY(positive_sign),
        LCONV_ENTRY(negative_sign),
        {NULL, 0}
    };

#  endif

    static const struct lconv_offset lconv_integers[] = {
#  ifdef USE_LOCALE_MONETARY
        LCONV_ENTRY(int_frac_digits),
        LCONV_ENTRY(frac_digits),
        LCONV_ENTRY(p_cs_precedes),
        LCONV_ENTRY(p_sep_by_space),
        LCONV_ENTRY(n_cs_precedes),
        LCONV_ENTRY(n_sep_by_space),
        LCONV_ENTRY(p_sign_posn),
        LCONV_ENTRY(n_sign_posn),
#    ifdef HAS_LC_MONETARY_2008
        LCONV_ENTRY(int_p_cs_precedes),
        LCONV_ENTRY(int_p_sep_by_space),
        LCONV_ENTRY(int_n_cs_precedes),
        LCONV_ENTRY(int_n_sep_by_space),
        LCONV_ENTRY(int_p_sign_posn),
        LCONV_ENTRY(int_n_sign_posn),
#    endif
#  endif
        {NULL, 0}
    };

    static const unsigned category_indices[] = {
#  ifdef USE_LOCALE_NUMERIC
        LC_NUMERIC_INDEX_,
#  endif
#  ifdef USE_LOCALE_MONETARY
        LC_MONETARY_INDEX_,
#  endif
        (unsigned) -1   /* Just so the previous element can always end with a
                           comma => subtract 1 below for the max loop index */
    };

    const char *ptr = (const char *) lcbuf;
    const struct lconv_offset *integers = lconv_integers;

    HV * retval = newHV();
    sv_2mortal((SV*)retval);

    PERL_ARGS_ASSERT_POPULATE_LOCALECONV;

    /* For each enabled category ... */
    for (PERL_UINT_FAST8_T i = 0; i < C_ARRAY_LENGTH(category_indices) - 1; i++) {
        const unsigned cat_index = category_indices[i];
        locale_utf8ness_t locale_is_utf8 = LOCALE_UTF8NESS_UNKNOWN;
        const char *locale;

        /* ( = NULL silences a compiler warning; would segfault if it could
         * actually happen.) */
        const struct lconv_offset *strings = NULL;

#  ifdef USE_LOCALE_NUMERIC
        if (cat_index == LC_NUMERIC_INDEX_) {
            locale_is_utf8 = numeric_locale_is_utf8;
            strings = lconv_numeric_strings;
        }
#  else
        PERL_UNUSED_ARG(numeric_locale_is_utf8);
#  endif
#  ifdef USE_LOCALE_MONETARY
        if (cat_index == LC_MONETARY_INDEX_) {
            locale_is_utf8 = monetary_locale_is_utf8;
            strings = lconv_monetary_strings;
        }
#  else
        PERL_UNUSED_ARG(monetary_locale_is_utf8);
#  endif

        assert(locale_is_utf8 != LOCALE_UTF8NESS_UNKNOWN);

        /* Iterate over the strings structure for this category */
        locale = querylocale_i(cat_index);

        while (strings->name) {
            const char *value = *((const char **)(ptr + strings->offset));
            if (value && *value) {
                bool is_utf8 =  /* Only make UTF-8 if required to */
                    (UTF8NESS_YES == (get_locale_string_utf8ness_i(locale,
                                                              cat_index,
                                                              value,
                                                              locale_is_utf8)));
                (void) hv_store(retval,
                                strings->name,
                                strlen(strings->name),
                                newSVpvn_utf8(value, strlen(value), is_utf8),
                                0);
            }

            strings++;
        }
    }

    while (integers->name) {
        const char value = *((const char *)(ptr + integers->offset));

        if (value != CHAR_MAX)
            (void) hv_store(retval, integers->name,
                            strlen(integers->name), newSViv(value), 0);
        integers++;
    }

    return retval;
}

#  ifndef HAS_SOME_LANGINFO

STATIC HV *
S_get_nl_item_from_localeconv(pTHX_ const struct lconv *lcbuf,
                                    const int item,
                                    const locale_utf8ness_t unused1,
                                    const locale_utf8ness_t unused2)
{
    /* This is a helper function for my_localeconv(), which is called from
     * my_langinfo() to emulate the libc nl_langinfo() function on platforms
     * that don't have it available.
     *
     * This function acts as an extension to my_langinfo(), the intermediate
     * my_localeconv() call is to set up the locks and switch into the proper
     * locale.  That logic exists for other reasons, and by doing it this way,
     * it doesn't have to be duplicated.
     *
     * This function extracts the current value of 'item' in the current locale
     * using the localconv() result also passed in, via 'lcbuf'.  The other
     * parameter is unused, a placeholder so the signature of this function
     * matches another that does need it, and so the two functions can be
     * referred to by a single function pointer, to simplify the code below */

    const char * prefix = "";
    const char * temp = NULL;

    PERL_ARGS_ASSERT_GET_NL_ITEM_FROM_LOCALECONV;
    PERL_UNUSED_ARG(unused1);
    PERL_UNUSED_ARG(unused2);

    switch (item) {
      case CRNCYSTR:
        temp = lcbuf->currency_symbol;

        if (lcbuf->p_cs_precedes) {

            /* khw couldn't find any documentation that CHAR_MAX is the signal,
             * but cygwin uses it thusly */
            if (lcbuf->p_cs_precedes == CHAR_MAX) {
                prefix = ".";
            }
            else {
                prefix = "-";
            }
        }
        else {
            prefix = "+";
        }

        break;

      case RADIXCHAR:
        temp = lcbuf->decimal_point;
        break;

      case THOUSEP:
        temp = lcbuf->thousands_sep;
        break;

      default:
        locale_panic_(Perl_form(aTHX_
                    "Unexpected item passed to populate_localeconv: %d", item));
    }

    return (HV *) Perl_newSVpvf(aTHX_ "%s%s", prefix, temp);
}

#  endif    /* ! Has some form of langinfo() */
#endif      /*   Has some form of localeconv() and paying attn to a category it
                 traffics in */

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
other reasons they aren't quite a drop-in replacement is actually an advantage.
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
available.  Later C<strftime()> versions have additional capabilities; C<""> is
returned for any item not available on your system.

It is important to note that, when called with an item that is recovered by
using C<localeconv>, the buffer from any previous explicit call to
C<L<localeconv(3)>> will be overwritten.  But you shouldn't be using
C<localeconv> anyway because it is is very much not thread-safe, and suffers
from the same problems outlined in item 'b.' above for the fields it returns that
are controlled by the LC_NUMERIC locale category.  Instead, avoid all of those
problems by calling L</Perl_localeconv>, which is thread-safe; or by using the
methods given in L<perlcall>  to call
L<C<POSIX::localeconv()>|POSIX/localeconv>, which is also thread-safe.

=back

The details for those items which may deviate from what this emulation returns
and what a native C<nl_langinfo()> would return are specified in
L<I18N::Langinfo>.

When using C<Perl_langinfo8> (or plain C<Perl_langinfo>) on systems that don't
have a native C<nl_langinfo()>, you must

 #include "perl_langinfo.h"

before the C<perl.h> C<#include>.  You can replace your C<langinfo.h>
C<#include> with this one.  (Doing it this way keeps out the symbols that plain
C<langinfo.h> would try to import into the namespace for code that doesn't need
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
 && (defined(HAS_SOME_LANGINFO) || defined(HAS_SOME_LOCALECONV))

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
 && (defined(HAS_SOME_LANGINFO) || defined(HAS_SOME_LOCALECONV))

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
#  ifdef USE_LOCALE_NUMERIC

    /* Use either the underlying numeric, or the other underlying categories */
    if (cat_index == LC_NUMERIC_INDEX_) {
        return my_langinfo_c(item, LC_NUMERIC, PL_numeric_name,
                             &PL_langinfo_buf, &PL_langinfo_bufsize, utf8ness);
    }
    else

#  endif

    {
        return my_langinfo_i(item, cat_index, querylocale_i(cat_index),
                             &PL_langinfo_buf, &PL_langinfo_bufsize, utf8ness);
    }

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
    assert(cat_index <= NOMINAL_LC_ALL_INDEX);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                           "Entering my_langinfo item=%d, using locale %s\n",
                           item, locale));
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

#  if defined(HAS_THREAD_SAFE_NL_LANGINFO_L) && defined(USE_POSIX_2008_LOCALE)

    /* Simplest is if we can use nl_langinfo_l()
     *
     * With it, we can change LC_CTYPE in the same call as the other category */
#    ifdef USE_LOCALE_CTYPE
#      define CTYPE_SAFETY_MASK LC_CTYPE_MASK
#    else
#      define CTYPE_SAFETY_MASK 0
#    endif

    locale_t cur = newlocale((category_masks[cat_index] | CTYPE_SAFETY_MASK),
                             locale, (locale_t) 0);

    retval = save_to_buffer(nl_langinfo_l(item, cur), retbufp, retbuf_sizep);
    if (utf8ness) {
        *utf8ness = get_locale_string_utf8ness_i(locale, cat_index, retval,
                                                 LOCALE_UTF8NESS_UNKNOWN);
    }

    freelocale(cur);

    return retval;
/*--------------------------------------------------------------------------*/
#  elif defined(HAS_NL_LANGINFO) /* nl_langinfo() is available.  */

    /* The second version of my_langinfo() is if we have plain nl_langinfo() */

#    ifdef USE_LOCALE_CTYPE

    /* Ths function sorts out if things actually have to be switched or not,
     * for both calls. */
    const char * orig_CTYPE_locale = toggle_locale_c(LC_CTYPE, locale);

#    endif

    const char * orig_switched_locale = toggle_locale_i(cat_index, locale);

    gwLOCALE_LOCK;
    retval = save_to_buffer(nl_langinfo(item), retbufp, retbuf_sizep);
    gwLOCALE_UNLOCK;

    if (utf8ness) {
        *utf8ness = get_locale_string_utf8ness_i(locale, cat_index,
                                               retval, LOCALE_UTF8NESS_UNKNOWN);
    }

    restore_toggled_locale_i(cat_index, orig_switched_locale);

#    ifdef USE_LOCALE_CTYPE
    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);
#    endif

    return retval;
/*--------------------------------------------------------------------------*/
#  else   /* Below, emulate nl_langinfo as best we can */

    /* And the third and final completion is where we have to emulate
     * nl_langinfo().  There are various possibilities depending on the
     * Configuration */

#    ifdef USE_LOCALE_CTYPE

    const char * orig_CTYPE_locale =  toggle_locale_c(LC_CTYPE, locale);

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

#    if      defined(HAS_SNPRINTF)                                              \
       && (! defined(HAS_SOME_LOCALECONV) || defined(TS_W32_BROKEN_LOCALECONV))

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
             * the real number that strnprintf() is supposed to return */
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
                retval = save_to_buffer(item_start,
                                        (const char **) &PL_langinfo_buf,
                                        &PL_langinfo_bufsize);
                Safefree(floatbuf);

                if (utf8ness) {
                    is_utf8 = get_locale_string_utf8ness_i(locale, cat_index,
                                                           retval,
                                                       LOCALE_UTF8NESS_UNKNOWN);

                }

                break;
            }

            Safefree(floatbuf);
        }

#      ifdef HAS_SOME_LOCALECONV /* snprintf() failed; drop down to use
                                    localeconv() */

        /* FALLTHROUGH */                                                           \

#      else                      /* snprintf() failed and no localeconv() */

        retval = C_decimal_point;
        break;

#      endif
#    endif
#    ifdef HAS_SOME_LOCALECONV

    /* These items are available from localeconv().  (To avoid using
     * TS_W32_BROKEN_LOCALECONV, one could use GetNumberFormat and
     * GetCurrencyFormat; patches welcome) */

      case CRNCYSTR:
      case THOUSEP:
        {
            SV * string = (SV *) my_localeconv(item, LOCALE_UTF8NESS_UNKNOWN);

            retval = save_to_buffer(SvPV_nolen(string), retbufp, retbuf_sizep);

            if (utf8ness) {
                is_utf8 = get_locale_string_utf8ness_i(locale, cat_index, retval,
                                                       LOCALE_UTF8NESS_UNKNOWN);
            }

            SvREFCNT_dec_NN(string);
            break;
        }

#    endif  /* Some form of localeconv */
#    ifdef HAS_STRFTIME

      /* These formats are only available in later strfmtime's */
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
                format = "%Ow";	/* Find the alternate digit for 0 */
                break;
            }

            GCC_DIAG_RESTORE_STMT;

            /* The year was deliberately chosen so that January 1 is on the
             * first day of the week.  Since we're only getting one thing at a
             * time, it all works */
            const char * temp = my_strftime8(format, 30, 30, hour, mday, mon,
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

      case CODESET:

        /* The trivial case */
        if (isNAME_C_OR_POSIX(locale)) {
            retval = C_codeset;
            break;
        }

#    ifdef WIN32

        /* This function retrieves the code page.  It is subject to change, but
         * is documented and has been stable for many releases */
        UINT ___lc_codepage_func(void);

        retval = save_to_buffer(Perl_form(aTHX_ "%d", ___lc_codepage_func()),
                                retbufp, retbuf_sizep);
        DEBUG_Lv(PerlIO_printf(Perl_debug_log, "locale='%s' cp=%s\n",
                                               locale, retval));
        break;

#    else

        /* The codeset is important, but khw did not figure out a way for it to
         * be retrieved on non-Windows boxes without nl_langinfo().  But even
         * if we can't get it directly, we can usually determine if it is a
         * UTF-8 locale or not.  If it is UTF-8, we (correctly) use that for
         * the code set. */

#      if defined(HAS_MBTOWC) || defined(HAS_MBRTOWC)

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

#    else   /* mbtowc() is not available. */

        /* Sling together several possibilities, depending on platform
         * capabilities and what we found.
         *
         * For non-English locales or non-dollar currency locales, we likely
         * will find out whether a locale is UTF-8 or not */

        utf8ness_t is_utf8 = UTF8NESS_UNKNOWN;
        const char * scratch_buf = NULL;

#      if defined(USE_LOCALE_MONETARY) && defined(HAS_SOME_LOCALECONV)

        /* Can't use this method unless localeconv() is available, as that's
         * the way we find out the currency symbol. */

        /* First try looking at the currency symbol (via a recursive call) to
         * see if it disambiguates things.  Often that will be in the native
         * script, and if the symbol isn't legal UTF-8, we know that the locale
         * isn't either. */
        (void) my_langinfo_c(CRNCYSTR, LC_MONETARY, locale, &scratch_buf, NULL,
                             &is_utf8);
        Safefree(scratch_buf);

#      endif
#      ifdef USE_LOCALE_TIME

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
             *      UTF8NESS_NO           If any aren't legal UTF-8
             *      UTF8NESS_IMMMATERIAL  If all are ASCII
             *      UTF8NESS_YES          If all are legal UTF-8 (including
             *                            ASCIIi), and at least one isn't
             *                            ASCII. */

            restore_toggled_locale_c(LC_TIME, orig_TIME_locale);
        }

#      endif    /* LC_TIME */

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

#    endif    /* ! mbtowc() */

        /* Rejoin the mbtowc available/not-available cases.
         *
         * We got here only because we haven't been able to find the codeset.
         * The only other option khw could think of is to see if the codeset is
         * part of the locale name.  This is very less than ideal; often there
         * is no code set in the name; and at other times they even lie.
         *
         * Find any dot in the locale name */
        retval = (const char *) strchr(locale, '.');
        if (! retval) {
            retval = "";  /* Alas, no dot */
            break;
        }

        /* Use everything past the dot */
        retval++;

#      if defined(HAS_MBTOWC) || defined(HAS_MBRTOWC)

        /* When these functions, are available, they were tried earlier and
         * indicated that the locale did not act like a proper UTF-8 one.  So
         * if it claims to be UTF-8, it is a lie */
        if (is_codeset_name_UTF8(retval)) {
            retval = "";
            break;
        }

#      endif

        /* Otherwise the code set name is considered to be everything past the
         * dot. */
        retval = save_to_buffer(retval, retbufp, retbuf_sizep);

        break;

#    endif

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
Perl_my_strftime8(pTHX_ const char *fmt, int sec, int min, int hour, int mday,
                         int mon, int year, int wday, int yday, int isdst,
                         utf8ness_t * utf8ness)
{   /* Documented in util.c */
    char * retval = my_strftime(fmt, sec, min, hour, mday, mon, year, wday,
                                yday, isdst);

    PERL_ARGS_ASSERT_MY_STRFTIME8;

    if (utf8ness) {

#ifdef USE_LOCALE_TIME
        *utf8ness = get_locale_string_utf8ness_i(NULL, LC_TIME_INDEX_,
                                               retval, LOCALE_UTF8NESS_UNKNOWN);
#else
        *utf8ness = UTF8NESS_IMMATERIAL;
#endif

    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "fmt=%s, retval=%s", fmt,
                 ((is_utf8_string((U8 *) retval, 0))
                  ? retval
                  :_byte_dump_string((U8 *) retval, strlen(retval), 0)));
             if (utf8ness) PerlIO_printf(Perl_debug_log, "; utf8ness=%d",
                                                         (int) *utf8ness);
             PerlIO_printf(Perl_debug_log, "\n");
            );

    return retval;
}

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
     * This looks more complicated than it is, mainly due to the #ifdefs and
     * error handling.
     *
     * Besides some asserts, data structure initialization, and specific
     * platform complications, this routine is effectively represented by this
     * pseudo-code:
     *
     *      setlocale(LC_ALL, "");                                            x
     *      foreach (subcategory) {                                           x
     *          curlocales[f(subcategory)] = setlocale(subcategory, NULL);    x
     *      }                                                                 x
     *      if (platform_so_requires) {
     *          foreach (subcategory) {
     *            PL_curlocales[f(subcategory)] = curlocales[f(subcategory)]
     *          }
     *      }
     *      foreach (subcategory) {
     *          if (needs_special_handling[f(subcategory)] &this_subcat_handler
     *      }
     *
     * This sets all the categories to the values in the current environment,
     * saves them temporarily in curlocales[] until they can be handled and/or
     * on some platforms saved in a per-thread array PL_curlocales[].
     *
     * f(foo) is a mapping from the opaque system category numbers to small
     * non-negative integers used most everywhere in this file as indices into
     * arrays (such as curlocales[]) so the program doesn't have to otherwise
     * deal with the opaqueness.
     *
     * If the platform doesn't have LC_ALL, the lines marked 'x' above are
     * effectively replaced by:
     *      foreach (subcategory) {                                           y
     *          curlocales[f(subcategory)] = setlocale(subcategory, "");      y
     *      }                                                                 y
     *
     * The only differences being the lack of an LC_ALL call, and using ""
     * instead of NULL in the setlocale calls.
     *
     * But there are, of course, complications.
     *
     * it has to deal with if this is an embedded perl, whose locale doesn't
     * come from the environment, but has been set up by the caller.  This is
     * pretty simply handled: the "" in the setlocale calls is not a string
     * constant, but a variable which is set to NULL in the embedded case.
     *
     * But the major complication is handling failure and doing fallback.  All
     * the code marked 'x' or 'y' above is actually enclosed in an outer loop,
     * using the array trial_locales[].  On entry, trial_locales[] is
     * initialized to just one entry, containing the NULL or "" locale argument
     * shown above.  If, as is almost always the case, everything works, it
     * exits after just the one iteration, going on to the next step.
     *
     * But if there is a failure, the code tries its best to honor the
     * environment as much as possible.  It self-modifies trial_locales[] to
     * have more elements, one for each of the POSIX-specified settings from
     * the environment, such as LANG, ending in the ultimate fallback, the C
     * locale.  Thus if there is something bogus with a higher priority
     * environment variable, it will try with the next highest, until something
     * works.  If everything fails, it limps along with whatever state it got
     * to.
     *
     * A further complication is that Windows has an additional fallback, the
     * user-default ANSI code page obtained from the operating system.  This is
     * added as yet another loop iteration, just before the final "C"
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

#ifndef USE_LOCALE

    PERL_UNUSED_ARG(printwarn);

#else  /* USE_LOCALE */
#  ifdef __GLIBC__

    const char * const language = PerlEnv_getenv("LANGUAGE");

#  endif

    /* NULL uses the existing already set up locale */
    const char * const setlocale_init = (PerlEnv_getenv("PERL_SKIP_LOCALE_INIT"))
                                        ? NULL
                                        : "";
    typedef struct trial_locales_struct_s {
        const char* trial_locale;
        const char* fallback_desc;
        const char* fallback_name;
    } trial_locales_struct;
    /* 5 = 1 each for "", LC_ALL, LANG, (Win32) system default locale, C */
    trial_locales_struct trial_locales[5];
    unsigned int trial_locales_count;
    const char * const lc_all     = PerlEnv_getenv("LC_ALL");
    const char * const lang       = PerlEnv_getenv("LANG");
    bool setlocale_failure = FALSE;
    unsigned int i;

    /* A later getenv() could zap this, so only use here */
    const char * const bad_lang_use_once = PerlEnv_getenv("PERL_BADLANG");

    const bool locwarn = (printwarn > 1
                          || (          printwarn
                              && (    ! bad_lang_use_once
                                  || (
                                         /* disallow with "" or "0" */
                                         *bad_lang_use_once
                                       && strNE("0", bad_lang_use_once)))));

    /* current locale for given category; should have been copied so aren't
     * volatile */
    const char * curlocales[NOMINAL_LC_ALL_INDEX + 1];

#  ifndef DEBUGGING
#    define DEBUG_LOCALE_INIT(a,b,c)
#  else

    DEBUG_INITIALIZATION_set(cBOOL(PerlEnv_getenv("PERL_DEBUG_LOCALE_INIT")));

#    define DEBUG_LOCALE_INIT(cat_index, locale, result)                    \
        DEBUG_L(PerlIO_printf(Perl_debug_log, "%s\n",                       \
                    setlocale_debug_string_i(cat_index, locale, result)));

/* Make sure the parallel arrays are properly set up */
#    ifdef USE_LOCALE_NUMERIC
    assert(categories[LC_NUMERIC_INDEX_] == LC_NUMERIC);
    assert(strEQ(category_names[LC_NUMERIC_INDEX_], "LC_NUMERIC"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_NUMERIC_INDEX_] == LC_NUMERIC_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_CTYPE
    assert(categories[LC_CTYPE_INDEX_] == LC_CTYPE);
    assert(strEQ(category_names[LC_CTYPE_INDEX_], "LC_CTYPE"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_CTYPE_INDEX_] == LC_CTYPE_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_COLLATE
    assert(categories[LC_COLLATE_INDEX_] == LC_COLLATE);
    assert(strEQ(category_names[LC_COLLATE_INDEX_], "LC_COLLATE"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_COLLATE_INDEX_] == LC_COLLATE_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_TIME
    assert(categories[LC_TIME_INDEX_] == LC_TIME);
    assert(strEQ(category_names[LC_TIME_INDEX_], "LC_TIME"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_TIME_INDEX_] == LC_TIME_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_MESSAGES
    assert(categories[LC_MESSAGES_INDEX_] == LC_MESSAGES);
    assert(strEQ(category_names[LC_MESSAGES_INDEX_], "LC_MESSAGES"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_MESSAGES_INDEX_] == LC_MESSAGES_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_MONETARY
    assert(categories[LC_MONETARY_INDEX_] == LC_MONETARY);
    assert(strEQ(category_names[LC_MONETARY_INDEX_], "LC_MONETARY"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_MONETARY_INDEX_] == LC_MONETARY_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_ADDRESS
    assert(categories[LC_ADDRESS_INDEX_] == LC_ADDRESS);
    assert(strEQ(category_names[LC_ADDRESS_INDEX_], "LC_ADDRESS"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_ADDRESS_INDEX_] == LC_ADDRESS_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_IDENTIFICATION
    assert(categories[LC_IDENTIFICATION_INDEX_] == LC_IDENTIFICATION);
    assert(strEQ(category_names[LC_IDENTIFICATION_INDEX_], "LC_IDENTIFICATION"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_IDENTIFICATION_INDEX_] == LC_IDENTIFICATION_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_MEASUREMENT
    assert(categories[LC_MEASUREMENT_INDEX_] == LC_MEASUREMENT);
    assert(strEQ(category_names[LC_MEASUREMENT_INDEX_], "LC_MEASUREMENT"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_MEASUREMENT_INDEX_] == LC_MEASUREMENT_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_PAPER
    assert(categories[LC_PAPER_INDEX_] == LC_PAPER);
    assert(strEQ(category_names[LC_PAPER_INDEX_], "LC_PAPER"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_PAPER_INDEX_] == LC_PAPER_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_TELEPHONE
    assert(categories[LC_TELEPHONE_INDEX_] == LC_TELEPHONE);
    assert(strEQ(category_names[LC_TELEPHONE_INDEX_], "LC_TELEPHONE"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_TELEPHONE_INDEX_] == LC_TELEPHONE_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_SYNTAX
    assert(categories[LC_SYNTAX_INDEX_] == LC_SYNTAX);
    assert(strEQ(category_names[LC_SYNTAX_INDEX_], "LC_SYNTAX"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_SYNTAX_INDEX_] == LC_SYNTAX_MASK);
#      endif
#    endif
#    ifdef USE_LOCALE_TOD
    assert(categories[LC_TOD_INDEX_] == LC_TOD);
    assert(strEQ(category_names[LC_TOD_INDEX_], "LC_TOD"));
#      ifdef USE_POSIX_2008_LOCALE
    assert(category_masks[LC_TOD_INDEX_] == LC_TOD_MASK);
#      endif
#    endif
#    ifdef LC_ALL
    assert(categories[LC_ALL_INDEX_] == LC_ALL);
    assert(strEQ(category_names[LC_ALL_INDEX_], "LC_ALL"));
    STATIC_ASSERT_STMT(NOMINAL_LC_ALL_INDEX == LC_ALL_INDEX_);
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
#  ifdef USE_THREAD_SAFE_LOCALE
#    ifdef WIN32

    _configthreadlocale(_ENABLE_PER_THREAD_LOCALE);

#    endif
#  endif
#  ifdef USE_POSIX_2008_LOCALE

    PL_C_locale_obj = newlocale(LC_ALL_MASK, "C", (locale_t) 0);
    if (! PL_C_locale_obj) {
        locale_panic_(Perl_form(aTHX_
                                "Cannot create POSIX 2008 C locale object"));
    }

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "created C object %p\n",
                           PL_C_locale_obj));

#    ifdef USE_LOCALE_NUMERIC

    PL_underlying_numeric_obj = duplocale(PL_C_locale_obj);

#    endif
#  endif
#  ifdef USE_LOCALE_NUMERIC

    PL_numeric_radix_sv    = newSV(1);
    PL_underlying_radix_sv = newSV(1);
    Newxz(PL_numeric_name, 1, char);    /* Single NUL character */
    new_numeric("C");

#  endif
#  ifdef USE_LOCALE_COLLATE

    Newxz(PL_collation_name, 1, char);
    new_collate("C");

#  endif
#  ifdef USE_LOCALE_CTYPE

    Newxz(PL_ctype_name, 1, char);
    new_ctype("C");

#  endif
#  ifdef USE_PL_CURLOCALES

    /* Initialize our records. */
    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        (void) emulate_setlocale_i(i, posix_setlocale(categories[i], NULL),
                                   RECALCULATE_LC_ALL_ON_FINAL_INTERATION,
                                   __LINE__);
    }

#  endif

    /* We try each locale in the list until we get one that works, or exhaust
     * the list.  Normally the loop is executed just once.  But if setting the
     * locale fails, inside the loop we add fallback trials to the array and so
     * will execute the loop multiple times */
    trial_locales[0] = (trial_locales_struct) {
        .trial_locale = setlocale_init,
        .fallback_desc = NULL,
        .fallback_name = NULL,
    };
    trial_locales_count = 1;

    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        curlocales[i] = NULL;
    }

    for (i= 0; i < trial_locales_count; i++) {
        const char * trial_locale = trial_locales[i].trial_locale;
        setlocale_failure = FALSE;

#  ifdef LC_ALL

        /* setlocale() return vals; not copied so must be looked at
         * immediately. */
        const char * sl_result[NOMINAL_LC_ALL_INDEX + 1];
        sl_result[LC_ALL_INDEX_] = stdized_setlocale(LC_ALL, trial_locale);
        DEBUG_LOCALE_INIT(LC_ALL_INDEX_, trial_locale, sl_result[LC_ALL_INDEX_]);
        if (! sl_result[LC_ALL_INDEX_]) {
            setlocale_failure = TRUE;
        }
        else {
            /* Since LC_ALL succeeded, it should have changed all the other
             * categories it can to its value; so we massage things so that the
             * setlocales below just return their category's current values.
             * This adequately handles the case in NetBSD where LC_COLLATE may
             * not be defined for a locale, and setting it individually will
             * fail, whereas setting LC_ALL succeeds, leaving LC_COLLATE set to
             * the POSIX locale. */
            trial_locale = NULL;
        }

#  endif /* LC_ALL */

        if (! setlocale_failure) {
            unsigned int j;
            for (j = 0; j < NOMINAL_LC_ALL_INDEX; j++) {
                curlocales[j] = stdized_setlocale(categories[j], trial_locale);
                if (! curlocales[j]) {
                    setlocale_failure = TRUE;
                }
                curlocales[j] = savepv(curlocales[j]);
                DEBUG_LOCALE_INIT(j, trial_locale, curlocales[j]);
            }

            if (LIKELY(! setlocale_failure)) {  /* All succeeded */
                break;  /* Exit trial_locales loop */
            }
        }

        /* Here, something failed; will need to try a fallback. */
        ok = 0;

        if (i == 0) {
            unsigned int j;

            if (locwarn) { /* Output failure info only on the first one */

#  ifdef LC_ALL

                PerlIO_printf(Perl_error_log,
                "perl: warning: Setting locale failed.\n");

#  else /* !LC_ALL */

                PerlIO_printf(Perl_error_log,
                "perl: warning: Setting locale failed for the categories:\n");

                for (j = 0; j < NOMINAL_LC_ALL_INDEX; j++) {
                    if (! curlocales[j]) {
                        PerlIO_printf(Perl_error_log, "\t%s\n", category_names[j]);
                    }
                }

#  endif /* LC_ALL */

                PerlIO_printf(Perl_error_log,
                    "perl: warning: Please check that your locale settings:\n");

#  ifdef __GLIBC__

                PerlIO_printf(Perl_error_log,
                            "\tLANGUAGE = %c%s%c,\n",
                            language ? '"' : '(',
                            language ? language : "unset",
                            language ? '"' : ')');
#  endif

                PerlIO_printf(Perl_error_log,
                            "\tLC_ALL = %c%s%c,\n",
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
                }

#  else

                PerlIO_printf(Perl_error_log,
                            "\t(possibly more locale environment variables)\n");

#  endif

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
                    if (strEQ(lc_all, trial_locales[j].trial_locale)) {
                        goto done_lc_all;
                    }
                }
                trial_locales[trial_locales_count++] = (trial_locales_struct) {
                    .trial_locale = lc_all,
                    .fallback_desc = (strEQ(lc_all, "C")
                                      ? "the standard locale"
                                      : "a fallback locale"),
                    .fallback_name = lc_all,
                };
            }
          done_lc_all:

            if (lang) {
                for (j = 0; j < trial_locales_count; j++) {
                    if (strEQ(lang, trial_locales[j].trial_locale)) {
                        goto done_lang;
                    }
                }
                trial_locales[trial_locales_count++] = (trial_locales_struct) {
                    .trial_locale = lang,
                    .fallback_desc = (strEQ(lang, "C")
                                      ? "the standard locale"
                                      : "a fallback locale"),
                    .fallback_name = lang,
                };
            }
          done_lang:

#  if defined(WIN32) && defined(LC_ALL)

            /* For Windows, we also try the system default locale before "C".
             * (If there exists a Windows without LC_ALL we skip this because
             * it gets too complicated.  For those, the "C" is the next
             * fallback possibility). */
            {
                /* Note that this may change the locale, but we are going to do
                 * that anyway.
                 *
                 * Our normal Windows setlocale() implementation ignores the
                 * system default locale to make things work like POSIX.  This
                 * is the only place where we want to consider it, so have to
                 * use wrap_wsetlocale(). */
                const char *system_default_locale =
                                    stdize_locale(LC_ALL,
                                                  S_wrap_wsetlocale(aTHX_ LC_ALL, ""),
                                                  &PL_stdize_locale_buf,
                                                  &PL_stdize_locale_bufsize,
                                                  __LINE__);
                DEBUG_LOCALE_INIT(LC_ALL_INDEX_, "", system_default_locale);

                /* Skip if invalid or if it's already on the list of locales to
                 * try */
                if (! system_default_locale) {
                    goto done_system_default;
                }
                for (j = 0; j < trial_locales_count; j++) {
                    if (strEQ(system_default_locale, trial_locales[j].trial_locale)) {
                        goto done_system_default;
                    }
                }

                trial_locales[trial_locales_count++] = (trial_locales_struct) {
                    .trial_locale = system_default_locale,
                    .fallback_desc = (strEQ(system_default_locale, "C")
                                      ? "the standard locale"
                                      : "the system default locale"),
                    .fallback_name = system_default_locale,
                };
            }
          done_system_default:

#  endif

            for (j = 0; j < trial_locales_count; j++) {
                if (strEQ("C", trial_locales[j].trial_locale)) {
                    goto done_C;
                }
            }
            trial_locales[trial_locales_count++] = (trial_locales_struct) {
                .trial_locale = "C",
                .fallback_desc = "the standard locale",
                .fallback_name = "C",
            };

          done_C: ;
        }   /* end of first time through the loop */

#  ifdef WIN32

      next_iteration: ;

#  endif

    }   /* end of looping through the trial locales */

    if (ok < 1) {   /* If we tried to fallback */
        const char* msg;
        if (! setlocale_failure) {  /* fallback succeeded */
           msg = "Falling back to";
        }
        else {  /* fallback failed */
            unsigned int j;

            /* We dropped off the end of the loop, so have to decrement i to
             * get back to the value the last time through */
            i--;

            ok = -1;
            msg = "Failed to fall back to";

            /* To continue, we should use whatever values we've got */

            for (j = 0; j < NOMINAL_LC_ALL_INDEX; j++) {
                Safefree(curlocales[j]);
                curlocales[j] = savepv(stdized_setlocale(categories[j], NULL));
                DEBUG_LOCALE_INIT(j, NULL, curlocales[j]);
            }
        }

        if (locwarn) {
            const char * description = trial_locales[i].fallback_desc;
            const char * name = trial_locales[i].fallback_name;

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

#  ifdef USE_POSIX_2008_LOCALE

    /* The stdized setlocales haven't affected the P2008 locales.  Initialize
     * them now, calculating LC_ALL only on the final go round, when all have
     * been set. */
    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        (void) emulate_setlocale_i(i, curlocales[i],
                                   RECALCULATE_LC_ALL_ON_FINAL_INTERATION,
                                   __LINE__);
    }

#  endif

    /* Done with finding the locales; update the auxiliary records */
    new_LC_ALL(NULL);

#  if defined(USE_POSIX_2008_LOCALE) && defined(USE_LOCALE_NUMERIC)

    /* This is a temporary workaround for #20155, to avoid issues where the
     * global locale wants a radix different from the per-thread one.  This
     * restores behavior for LC_NUMERIC to what it was before a7ff7ac. */
    posix_setlocale(LC_NUMERIC, "C");

#  endif

    for (i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        Safefree(curlocales[i]);
    }

#  if defined(USE_PERLIO) && defined(USE_LOCALE_CTYPE)

    /* Set PL_utf8locale to TRUE if using PerlIO _and_ the current LC_CTYPE
     * locale is UTF-8.  The call to new_ctype() just above has already
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
#endif /* USE_LOCALE */

    /* So won't continue to output stuff */
    DEBUG_INITIALIZATION_set(FALSE);

    return ok;
}

#ifdef USE_LOCALE_COLLATE

STATIC void
S_compute_collxfrm_coefficients(pTHX)
{

        PL_in_utf8_COLLATE_locale = (PL_collation_standard)
                                    ? 0
                                    : is_locale_utf8(PL_collation_name);
        PL_strxfrm_NUL_replacement = '\0';
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
         *  "A¹B¹C¹ A²B²C² "
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

            /* mem_collxfrm_() is used get the transformation (though here we
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
            x_longer = mem_collxfrm_(longer,
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
            x_shorter = mem_collxfrm_(longer + 1,
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
                PL_collxfrm_base = 1;
                DEBUG_L(PerlIO_printf(Perl_debug_log,
                        "Disabling locale collation for LC_COLLATE='%s';"
                        " length for shorter sample=%zu; longer=%zu\n",
                        PL_collation_name, x_len_shorter, x_len_longer));
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

            DEBUG_L(PerlIO_printf(Perl_debug_log,
                                  "?UTF-8 locale=%d; x_len_shorter=%zu, "
                    "x_len_longer=%zu,"
                    " collate multipler=%zu, collate base=%zu\n",
                    PL_in_utf8_COLLATE_locale,
                    x_len_shorter, x_len_longer,
                                  PL_collxfrm_mult, PL_collxfrm_base));
        }
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
                    orig_CTYPE_locale = toggle_locale_c(LC_CTYPE, PL_collation_name);
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
    *(U32*)xbuf = PL_collation_ix;

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
        *xlen = my_strxfrm(xbuf + COLLXFRM_HDR_LEN, s, xAlloc - COLLXFRM_HDR_LEN);

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
                  "mem_collxfrm_[ix %" UVuf "] for locale '%s':\n",
                  (UV) PL_collation_ix, PL_collation_name);
    PerlIO_printf(Perl_debug_log,  "     input=");
    print_bytes_for_locale(s, e, is_utf8);
    PerlIO_printf(Perl_debug_log, "\n    return=%s\n    return len=%zu\n",
           ((xbuf == NULL)
             ? "(null)"
             : _byte_dump_string((U8 *) xbuf + COLLXFRM_HDR_LEN, xlen, 0)),
            xlen);
}

#  endif    /* DEBUGGING */
#endif /* USE_LOCALE_COLLATE */

#ifdef DEBUGGING

STATIC void
S_print_bytes_for_locale(pTHX_
                    const char * const s,
                    const char * const e,
                    const bool is_utf8)
{
    const char * t = s;
    bool prev_was_printable = TRUE;
    bool first_time = TRUE;

    PERL_ARGS_ASSERT_PRINT_BYTES_FOR_LOCALE;

    while (t < e) {
        UV cp = (is_utf8)
                ?  utf8_to_uvchr_buf((U8 *) t, e, NULL)
                : * (U8 *) t;
        if (isPRINT(cp)) {
            if (! prev_was_printable) {
                PerlIO_printf(Perl_debug_log, " ");
            }
            PerlIO_printf(Perl_debug_log, "%c", (U8) cp);
            prev_was_printable = TRUE;
        }
        else {
            if (! first_time) {
                PerlIO_printf(Perl_debug_log, " ");
            }
            PerlIO_printf(Perl_debug_log, "%02" UVXf, cp);
            prev_was_printable = FALSE;
        }
        t += (is_utf8) ? UTF8SKIP(t) : 1;
        first_time = FALSE;
    }
}

#endif   /* #ifdef DEBUGGING */
#ifdef USE_LOCALE

STATIC const char *
S_toggle_locale_i(pTHX_ const unsigned cat_index,
                        const char * new_locale,
                        const line_t caller_line)
{
    /* Changes the locale for the category specified by 'index' to 'new_locale,
     * if they aren't already the same.
     *
     * Returns a copy of the name of the original locale for 'cat_index'
     * so can be switched back to with the companion function
     * restore_toggled_locale_i(),  (NULL if no restoral is necessary.) */

    const char * locale_to_restore_to = NULL;

    PERL_ARGS_ASSERT_TOGGLE_LOCALE_I;
    assert(cat_index <= NOMINAL_LC_ALL_INDEX);

    /* Find the original locale of the category we may need to change, so that
     * it can be restored to later */

    locale_to_restore_to = querylocale_i(cat_index);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
             "(%" LINE_Tf "): toggle_locale_i: index=%d(%s), wanted=%s,"
             " actual=%s\n",
             caller_line, cat_index, category_names[cat_index],
             new_locale, locale_to_restore_to));

    if (! locale_to_restore_to) {
        locale_panic_(Perl_form(aTHX_ "Could not find current %s locale, errno=%d",
                                category_names[cat_index], errno));
    }

    /* If the locales are the same, there's nothing to do */
    if (strEQ(locale_to_restore_to, new_locale)) {
        DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                               "(%d): %s locale unchanged as %s\n",
                               caller_line, category_names[cat_index],
                               new_locale));

        return NULL;
    }

    /* Finally, change the locale to the new one */
    void_setlocale_i(cat_index, new_locale);

    DEBUG_Lv(PerlIO_printf(Perl_debug_log, "(%" LINE_Tf "): %s locale switched to %s\n",
                           caller_line, category_names[cat_index], new_locale));

    return locale_to_restore_to;

#ifndef DEBUGGING
    PERL_UNUSED_ARG(caller_line);
#endif

}

STATIC void
S_restore_toggled_locale_i(pTHX_ const unsigned int cat_index,
                                 const char * restore_locale,
                                 const line_t caller_line)
{
    /* Restores the locale for LC_category corresponding to cat_indes to
     * 'restore_locale' (which is a copy that will be freed by this function),
     * or do nothing if the latter parameter is NULL */

    PERL_ARGS_ASSERT_RESTORE_TOGGLED_LOCALE_I;
    assert(cat_index <= NOMINAL_LC_ALL_INDEX);

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

    void_setlocale_i(cat_index, restore_locale);

#ifndef DEBUGGING
    PERL_UNUSED_ARG(caller_line);
#endif

}

#ifdef USE_LOCALE_CTYPE

STATIC bool
S_is_codeset_name_UTF8(const char * name)
{
    /* Return a boolean as to if the passed-in name indicates it is a UTF-8
     * code set.  Several variants are possible */
    const Size_t len = strlen(name);

    PERL_ARGS_ASSERT_IS_CODESET_NAME_UTF8;

#  ifdef WIN32

    /* http://msdn.microsoft.com/en-us/library/windows/desktop/dd317756.aspx */
    if (memENDs(name, len, "65001")) {
        return TRUE;
    }

#  endif
               /* 'UTF8' or 'UTF-8' */
    return (    inRANGE(len, 4, 5)
            &&  name[len-1] == '8'
            && (   memBEGINs(name, len, "UTF")
                || memBEGINs(name, len, "utf"))
            && (len == 4 || name[3] == '-'));
}

#endif

STATIC bool
S_is_locale_utf8(pTHX_ const char * locale)
{
    /* Returns TRUE if the locale 'locale' is UTF-8; FALSE otherwise.  It uses
     * my_langinfo(), which employs various methods to get this information
     * if nl_langinfo() isn't available, using heuristics as a last resort, in
     * which case, the result will very likely be correct for locales for
     * languages that have commonly used non-ASCII characters, but for notably
     * English, it comes down to if the locale's name ends in something like
     * "UTF-8".  It errs on the side of not being a UTF-8 locale. */

#  if ! defined(USE_LOCALE_CTYPE)                                             \
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
    return retval;

#  endif

}

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
                           "Strerror returned; saving a copy: '");          \
       print_bytes_for_locale(errstr, errstr + strlen(errstr), 0);          \
       PerlIO_printf(Perl_debug_log, "'; utf8ness=%d\n", (int) *utf8ness);)

/* On platforms that have precisely one of these categories (Windows
 * qualifies), these yield the correct one */
#if defined(USE_LOCALE_CTYPE)
#  define WHICH_LC_INDEX LC_CTYPE_INDEX_
#elif defined(USE_LOCALE_MESSAGES)
#  define WHICH_LC_INDEX LC_MESSAGES_INDEX_
#endif

/*==========================================================================*/
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
    *utf8ness = get_locale_string_utf8ness_i(NULL, WHICH_LC_INDEX, errstr,
                                             LOCALE_UTF8NESS_UNKNOWN);
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
        *utf8ness = get_locale_string_utf8ness_i(NULL, LC_MESSAGES_INDEX_,
                                               errstr, LOCALE_UTF8NESS_UNKNOWN);
        freelocale(cur);
    }

    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}
#  endif    /* Above is using strerror_l */
/*==========================================================================*/
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
        *utf8ness = get_locale_string_utf8ness_i(NULL, WHICH_LC_INDEX, errstr,
                                                 LOCALE_UTF8NESS_UNKNOWN);
    }
    else {

        SETLOCALE_LOCK;

        const char * orig_locale = toggle_locale_i(WHICH_LC_INDEX, "C");

        errstr = savepv(Strerror(errnum));

        restore_toggled_locale_i(WHICH_LC_INDEX, orig_locale);

        SETLOCALE_UNLOCK;

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

    SETLOCALE_LOCK;

    const char* orig_CTYPE_locale    = toggle_locale_c(LC_CTYPE, desired_locale);
    const char* orig_MESSAGES_locale = toggle_locale_c(LC_MESSAGES,
                                                       desired_locale);
    const char *errstr = savepv(Strerror(errnum));

    restore_toggled_locale_c(LC_MESSAGES, orig_MESSAGES_locale);
    restore_toggled_locale_c(LC_CTYPE, orig_CTYPE_locale);

    SETLOCALE_UNLOCK;

    *utf8ness = get_locale_string_utf8ness_i(NULL, LC_MESSAGES_INDEX_, errstr,
                                             LOCALE_UTF8NESS_UNKNOWN);
    DEBUG_STRERROR_RETURN(errstr, utf8ness);

    SAVEFREEPV(errstr);
    return errstr;
}

/*--------------------------------------------------------------------------*/
#  endif /* end of not using strerror_l() */
#endif   /* end of all the my_strerror() implementations */

/*

=for apidoc switch_to_global_locale

On systems without locale support, or on typical single-threaded builds, or on
platforms that do not support per-thread locale operations, this function does
nothing.  On such systems that do have locale support, only a locale global to
the whole program is available.

On multi-threaded builds on systems that do have per-thread locale operations,
this function converts the thread it is running in to use the global locale.
This is for code that has not yet or cannot be updated to handle multi-threaded
locale operation.  As long as only a single thread is so-converted, everything
works fine, as all the other threads continue to ignore the global one, so only
this thread looks at it.

However, on Windows systems this isn't quite true prior to Visual Studio 15,
at which point Microsoft fixed a bug.  A race can occur if you use the
following operations on earlier Windows platforms:

=over

=item L<POSIX::localeconv|POSIX/localeconv>

=item L<I18N::Langinfo>, items C<CRNCYSTR> and C<THOUSEP>

=item L<perlapi/Perl_langinfo>, items C<CRNCYSTR> and C<THOUSEP>

=back

The first item is not fixable (except by upgrading to a later Visual Studio
release), but it would be possible to work around the latter two items by using
the Windows API functions C<GetNumberFormat> and C<GetCurrencyFormat>; patches
welcome.

Without this function call, threads that use the L<C<setlocale(3)>> system
function will not work properly, as all the locale-sensitive functions will
look at the per-thread locale, and C<setlocale> will have no effect on this
thread.

Perl code should convert to either call
L<C<Perl_setlocale>|perlapi/Perl_setlocale> (which is a drop-in for the system
C<setlocale>) or use the methods given in L<perlcall> to call
L<C<POSIX::setlocale>|POSIX/setlocale>.  Either one will transparently properly
handle all cases of single- vs multi-thread, POSIX 2008-supported or not.

Non-Perl libraries, such as C<gtk>, that call the system C<setlocale> can
continue to work if this function is called before transferring control to the
library.

Upon return from the code that needs to use the global locale,
L<C<sync_locale()>|perlapi/sync_locale> should be called to restore the safe
multi-thread operation.

=cut
*/

void
Perl_switch_to_global_locale()
{
    dTHX;

#ifdef USE_THREAD_SAFE_LOCALE
#  ifdef WIN32

    _configthreadlocale(_DISABLE_PER_THREAD_LOCALE);

#  else

    {
        unsigned int i;

        for (i = 0; i < LC_ALL_INDEX_; i++) {
            setlocale(categories[i], querylocale_i(i));
        }
    }

    uselocale(LC_GLOBAL_LOCALE);

#  endif
#endif

}

/*

=for apidoc sync_locale

L<C<Perl_setlocale>|perlapi/Perl_setlocale> can be used at any time to query or
change the locale (though changing the locale is antisocial and dangerous on
multi-threaded systems that don't have multi-thread safe locale operations.
(See L<perllocale/Multi-threaded operation>).  Using the system
L<C<setlocale(3)>> should be avoided.  Nevertheless, certain non-Perl libraries
called from XS, such as C<Gtk> do so, and this can't be changed.  When the
locale is changed by XS code that didn't use
L<C<Perl_setlocale>|perlapi/Perl_setlocale>, Perl needs to be told that the
locale has changed.  Use this function to do so, before returning to Perl.

The return value is a boolean: TRUE if the global locale at the time of call
was in effect; and FALSE if a per-thread locale was in effect.  This can be
used by the caller that needs to restore things as-they-were to decide whether
or not to call
L<C<Perl_switch_to_global_locale>|perlapi/switch_to_global_locale>.

=cut
*/

bool
Perl_sync_locale()
{

#ifndef USE_LOCALE

    return TRUE;

#else

    const char * newlocale;
    dTHX;

#  ifdef USE_POSIX_2008_LOCALE

    bool was_in_global_locale = FALSE;
    locale_t cur_obj = uselocale((locale_t) 0);

    /* On Windows, unless the foreign code has turned off the thread-safe
     * locale setting, any plain setlocale() will have affected what we see, so
     * no need to worry.  Otherwise, If the foreign code has done a plain
     * setlocale(), it will only affect the global locale on POSIX systems, but
     * will affect the */
    if (cur_obj == LC_GLOBAL_LOCALE) {

#    ifdef HAS_QUERY_LOCALE

        void_setlocale_c(LC_ALL, querylocale_c(LC_ALL));

#    else

        unsigned int i;

        /* We can't trust that we can read the LC_ALL format on the
         * platform, so do them individually */
        for (i = 0; i < LC_ALL_INDEX_; i++) {
            void_setlocale_i(i, querylocale_i(i));
        }

#    endif

        was_in_global_locale = TRUE;
    }

#  else

    bool was_in_global_locale = TRUE;

#  endif
#  ifdef USE_LOCALE_CTYPE

    newlocale = querylocale_c(LC_CTYPE);
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                  "%s\n", setlocale_debug_string_c(LC_CTYPE, NULL, newlocale)));
    new_ctype(newlocale);

#  endif /* USE_LOCALE_CTYPE */
#  ifdef USE_LOCALE_COLLATE

    newlocale = querylocale_c(LC_COLLATE);
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                "%s\n", setlocale_debug_string_c(LC_COLLATE, NULL, newlocale)));
    new_collate(newlocale);

#  endif
#  ifdef USE_LOCALE_NUMERIC

    newlocale = querylocale_c(LC_NUMERIC);
    DEBUG_Lv(PerlIO_printf(Perl_debug_log,
                "%s\n", setlocale_debug_string_c(LC_NUMERIC, NULL, newlocale)));
    new_numeric(newlocale);

#  endif /* USE_LOCALE_NUMERIC */

    return was_in_global_locale;

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

    assert(cat_index <= NOMINAL_LC_ALL_INDEX);

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
                     "%s:%" LINE_Tf ":" THREAD_FORMAT
                     " setlocale(%s[%d], %s%s%s) returned %s%s%s\n",

                     __FILE__, line, THREAD_ARGUMENT
                     category_names[cat_index], categories[cat_index],
                     locale_quote, locale, locale_quote,
                     retval_quote, retval, retval_quote);
}

#endif

void
Perl_thread_locale_init()
{
    /* Called from a thread on startup*/

#ifdef USE_THREAD_SAFE_LOCALE

    dTHX_DEBUGGING;

     DEBUG_L(PerlIO_printf(Perl_debug_log,
                           "new thread, initial locale is %s;"
                           " calling setlocale(LC_ALL, \"C\")\n",
                           get_LC_ALL_display()));
#  ifdef WIN32

    /* On Windows, make sure new thread has per-thread locales enabled */
    _configthreadlocale(_ENABLE_PER_THREAD_LOCALE);

#  endif
#  if defined(LC_ALL)

    /* This thread starts off in the C locale.  Use the full Perl_setlocale()
     * to make sure no ill-advised shortcuts get taken on this new thread, */
    Perl_setlocale(LC_ALL, "C");

#  else

    for (unsigned i = 0; i < NOMINAL_LC_ALL_INDEX; i++) {
        Perl_setlocale(categories[i], "C");
    }

#  endif
#endif

}

void
Perl_thread_locale_term()
{
    /* Called from a thread as it gets ready to terminate */

#ifdef USE_POSIX_2008_LOCALE

    /* C starts the new thread in the global C locale.  If we are thread-safe,
     * we want to not be in the global locale */

    {   /* Free up */
        locale_t cur_obj = uselocale(LC_GLOBAL_LOCALE);
        if (cur_obj != LC_GLOBAL_LOCALE && cur_obj != PL_C_locale_obj) {
            freelocale(cur_obj);
        }
    }

#endif

}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
