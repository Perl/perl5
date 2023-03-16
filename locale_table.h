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

#ifdef USE_LOCALE_CTYPE
    PERL_LOCALE_TABLE_ENTRY(LC_CTYPE, S_new_ctype)
#endif
#ifdef USE_LOCALE_NUMERIC
    PERL_LOCALE_TABLE_ENTRY(LC_NUMERIC, S_new_numeric)
#endif
#ifdef USE_LOCALE_COLLATE
    PERL_LOCALE_TABLE_ENTRY(LC_COLLATE, S_new_collate)
#endif
#ifdef USE_LOCALE_TIME
    PERL_LOCALE_TABLE_ENTRY(LC_TIME, NULL)
#endif
#ifdef USE_LOCALE_MESSAGES
    PERL_LOCALE_TABLE_ENTRY(LC_MESSAGES, NULL)
#endif
#ifdef USE_LOCALE_MONETARY
    PERL_LOCALE_TABLE_ENTRY(LC_MONETARY, NULL)
#endif
#ifdef USE_LOCALE_ADDRESS
    PERL_LOCALE_TABLE_ENTRY(LC_ADDRESS, NULL)
#endif
#ifdef USE_LOCALE_IDENTIFICATION
    PERL_LOCALE_TABLE_ENTRY(LC_IDENTIFICATION, NULL)
#endif
#ifdef USE_LOCALE_MEASUREMENT
    PERL_LOCALE_TABLE_ENTRY(LC_MEASUREMENT, NULL)
#endif
#ifdef USE_LOCALE_PAPER
    PERL_LOCALE_TABLE_ENTRY(LC_PAPER, NULL)
#endif
#ifdef USE_LOCALE_TELEPHONE
    PERL_LOCALE_TABLE_ENTRY(LC_TELEPHONE, NULL)
#endif
#ifdef USE_LOCALE_NAME
    PERL_LOCALE_TABLE_ENTRY(LC_NAME, NULL)
#endif
#ifdef USE_LOCALE_SYNTAX
    PERL_LOCALE_TABLE_ENTRY(LC_SYNTAX, NULL)
#endif
#ifdef USE_LOCALE_TOD
    PERL_LOCALE_TABLE_ENTRY(LC_TOD, NULL)
#endif
