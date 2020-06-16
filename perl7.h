/*    perl7.h
 *
 *    Copyright (C) 2020 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef H_PERL_7
#define H_PERL_7 1

/* this is used by toke.c to setup a Perl7 flavor */
/* #define P7_TOKE_SETUP "use p7;" */

#define P7_TOKE_SETUP "BEGIN { "\
                      "   ${^WARNING_BITS} = pack( 'H*', '555555555555555555555555150001500101' );"\
                      "   $^H |= 0x00000602;"\
                      "   require feature;"\
                      "   feature->import(':7.0');"\
                      "}"

/*

bitwise current_sub declared_refs evalbytes fc postderef_qq refaliasing say signatures state switch unicode_eval
*/

#endif /* Include guard */

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
