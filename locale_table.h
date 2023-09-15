/*    locale_entry.h
 *
 *    Copyright (C) 2023 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * This defines a macro for each individual locale category used on the this
 * system.  (The congomerate category LC_ALL is not included.)  This
 * file will be #included as the interior of various parallel arrays and in
 * other constructs; each usage will re-#define the macro to generate its
 * appropriate data.
 *
 * This guarantees the arrays will be parallel, and populated in the order
 * given here.  That order is mostly arbitrary.  LC_CTYPE is first because when
 * we are setting multiple categories, CTYPE often needs to match the other(s),
 * and the way the code is constructed, if we set the other category first, we
 * might otherwise have to set CTYPE twice.
 *
 * Each entry takes the token giving the category name, and either the name of
 * a function to call that does specialized set up for this category when it is
 * changed into, or NULL if no such set up is needed
 */

#ifdef LC_CTYPE
#  ifdef NO_LOCALE_CTYPE

    PERL_LOCALE_TABLE_ENTRY(CTYPE, NULL)

#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_CTYPE_AVAIL_  false
#  else

    PERL_LOCALE_TABLE_ENTRY(CTYPE, S_new_ctype)

#    define LC_CTYPE_AVAIL_  true
#    define USE_LOCALE_CTYPE
#  endif
#endif
#ifdef LC_NUMERIC
#  ifdef NO_LOCALE_NUMERIC

    PERL_LOCALE_TABLE_ENTRY(NUMERIC, NULL)

#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_NUMERIC_AVAIL_  false
#  else

    PERL_LOCALE_TABLE_ENTRY(NUMERIC, S_new_numeric)

#    define LC_NUMERIC_AVAIL_  true
#    define USE_LOCALE_NUMERIC
#  endif
#endif
#ifdef LC_COLLATE

        /* Perl outsources all its collation efforts to the libc strxfrm(), so
         * if it isn't available on the system, default "C" locale collation
         * gets used */
#  if defined(NO_LOCALE_COLLATE) || ! defined(HAS_STRXFRM)

    PERL_LOCALE_TABLE_ENTRY(COLLATE, NULL)

#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_COLLATE_AVAIL_  false
#  else

    PERL_LOCALE_TABLE_ENTRY(COLLATE, S_new_collate)

#    define LC_COLLATE_AVAIL_  true
#    define USE_LOCALE_COLLATE
#  endif
#endif
#ifdef LC_TIME

    PERL_LOCALE_TABLE_ENTRY(TIME, NULL)

#  ifdef NO_LOCALE_TIME
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_TIME_AVAIL_  false
#  else
#    define LC_TIME_AVAIL_  true
#    define USE_LOCALE_TIME
#  endif
#endif
#ifdef LC_MESSAGES

    PERL_LOCALE_TABLE_ENTRY(MESSAGES, NULL)

#  ifdef NO_LOCALE_MESSAGES
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_MESSAGES_AVAIL_  false
#  else
#    define LC_MESSAGES_AVAIL_  true
#    define USE_LOCALE_MESSAGES
#  endif
#endif
#ifdef LC_MONETARY

    PERL_LOCALE_TABLE_ENTRY(MONETARY, NULL)

#  ifdef NO_LOCALE_MONETARY
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_MONETARY_AVAIL_  false
#  else
#    define LC_MONETARY_AVAIL_  true
#    define USE_LOCALE_MONETARY
#  endif
#endif
#ifdef LC_ADDRESS

    PERL_LOCALE_TABLE_ENTRY(ADDRESS, NULL)

#  ifdef NO_LOCALE_ADDRESS
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_ADDRESS_AVAIL_  false
#  else
#    define LC_ADDRESS_AVAIL_  true
#    define USE_LOCALE_ADDRESS
#  endif
#endif
#ifdef LC_IDENTIFICATION

    PERL_LOCALE_TABLE_ENTRY(IDENTIFICATION, NULL)

#  ifdef NO_LOCALE_IDENTIFICATION
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_IDENTIFICATION_AVAIL_  false
#  else
#    define LC_IDENTIFICATION_AVAIL_  true
#    define USE_LOCALE_IDENTIFICATION
#  endif
#endif
#ifdef LC_MEASUREMENT

    PERL_LOCALE_TABLE_ENTRY(MEASUREMENT, NULL)

#  ifdef NO_LOCALE_MEASUREMENT
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_MEASUREMENT_AVAIL_  false
#  else
#    define LC_MEASUREMENT_AVAIL_  true
#    define USE_LOCALE_MEASUREMENT
#  endif
#endif
#ifdef LC_PAPER

    PERL_LOCALE_TABLE_ENTRY(PAPER, NULL)

#  ifdef NO_LOCALE_PAPER
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_PAPER_AVAIL_  false
#  else
#    define LC_PAPER_AVAIL_  true
#    define USE_LOCALE_PAPER
#  endif
#endif
#ifdef LC_TELEPHONE

    PERL_LOCALE_TABLE_ENTRY(TELEPHONE, NULL)

#  ifdef NO_LOCALE_TELEPHONE
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_TELEPHONE_AVAIL_  false
#  else
#    define LC_TELEPHONE_AVAIL_  true
#    define USE_LOCALE_TELEPHONE
#  endif
#endif
#ifdef LC_NAME

    PERL_LOCALE_TABLE_ENTRY(NAME, NULL)

#  ifdef NO_LOCALE_NAME
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_NAME_AVAIL_  false
#  else
#    define LC_NAME_AVAIL_  true
#    define USE_LOCALE_NAME
#  endif
#endif
#ifdef LC_SYNTAX

    PERL_LOCALE_TABLE_ENTRY(SYNTAX, NULL)

#  ifdef NO_LOCALE_SYNTAX
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_SYNTAX_AVAIL_  false
#  else
#    define LC_SYNTAX_AVAIL_  true
#    define USE_LOCALE_SYNTAX
#  endif
#endif
#ifdef LC_TOD

    PERL_LOCALE_TABLE_ENTRY(TOD, NULL)

#  ifdef NO_LOCALE_TOD
#    define HAS_IGNORED_LOCALE_CATEGORIES_
#    define LC_TOD_AVAIL_  false
#  else
#    define LC_TOD_AVAIL_  true
#    define USE_LOCALE_TOD
#  endif
#endif
