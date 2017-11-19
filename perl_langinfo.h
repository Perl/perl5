/* Replaces <langinfo.h>, and allows our code to work on systems that don't
 * have that. */

#ifndef PERL_LANGINFO_H
#define PERL_LANGINFO_H 1

#include "config.h"

#if defined(HAS_NL_LANGINFO) && defined(I_LANGINFO)
#   include <langinfo.h>
#endif

/* NOTE that this file is parsed by ext/XS-APItest/t/locale.t, so be careful
 * with changes */

/* Define PERL_foo to 'foo' if it exists; a negative number otherwise.  The
 * negatives are to minimize the possibility of collisions on platforms that
 * define some but not all of these item names (though each name is required by
 * the 2008 POSIX specification) */

#ifdef CODESET
#  define PERL_CODESET CODESET
#else
#  define PERL_CODESET -1
#endif
#ifdef D_T_FMT
#  define PERL_D_T_FMT D_T_FMT
#else
#  define PERL_D_T_FMT -2
#endif
#ifdef D_FMT
#  define PERL_D_FMT D_FMT
#else
#  define PERL_D_FMT -3
#endif
#ifdef T_FMT
#  define PERL_T_FMT T_FMT
#else
#  define PERL_T_FMT -4
#endif
#ifdef T_FMT_AMPM
#  define PERL_T_FMT_AMPM T_FMT_AMPM
#else
#  define PERL_T_FMT_AMPM -5
#endif
#ifdef AM_STR
#  define PERL_AM_STR AM_STR
#else
#  define PERL_AM_STR -6
#endif
#ifdef PM_STR
#  define PERL_PM_STR PM_STR
#else
#  define PERL_PM_STR -7
#endif
#ifdef DAY_1
#  define PERL_DAY_1 DAY_1
#else
#  define PERL_DAY_1 -8
#endif
#ifdef DAY_2
#  define PERL_DAY_2 DAY_2
#else
#  define PERL_DAY_2 -9
#endif
#ifdef DAY_3
#  define PERL_DAY_3 DAY_3
#else
#  define PERL_DAY_3 -10
#endif
#ifdef DAY_4
#  define PERL_DAY_4 DAY_4
#else
#  define PERL_DAY_4 -11
#endif
#ifdef DAY_5
#  define PERL_DAY_5 DAY_5
#else
#  define PERL_DAY_5 -12
#endif
#ifdef DAY_6
#  define PERL_DAY_6 DAY_6
#else
#  define PERL_DAY_6 -13
#endif
#ifdef DAY_7
#  define PERL_DAY_7 DAY_7
#else
#  define PERL_DAY_7 -14
#endif
#ifdef ABDAY_1
#  define PERL_ABDAY_1 ABDAY_1
#else
#  define PERL_ABDAY_1 -15
#endif
#ifdef ABDAY_2
#  define PERL_ABDAY_2 ABDAY_2
#else
#  define PERL_ABDAY_2 -16
#endif
#ifdef ABDAY_3
#  define PERL_ABDAY_3 ABDAY_3
#else
#  define PERL_ABDAY_3 -17
#endif
#ifdef ABDAY_4
#  define PERL_ABDAY_4 ABDAY_4
#else
#  define PERL_ABDAY_4 -18
#endif
#ifdef ABDAY_5
#  define PERL_ABDAY_5 ABDAY_5
#else
#  define PERL_ABDAY_5 -19
#endif
#ifdef ABDAY_6
#  define PERL_ABDAY_6 ABDAY_6
#else
#  define PERL_ABDAY_6 -20
#endif
#ifdef ABDAY_7
#  define PERL_ABDAY_7 ABDAY_7
#else
#  define PERL_ABDAY_7 -21
#endif
#ifdef MON_1
#  define PERL_MON_1 MON_1
#else
#  define PERL_MON_1 -22
#endif
#ifdef MON_2
#  define PERL_MON_2 MON_2
#else
#  define PERL_MON_2 -23
#endif
#ifdef MON_3
#  define PERL_MON_3 MON_3
#else
#  define PERL_MON_3 -24
#endif
#ifdef MON_4
#  define PERL_MON_4 MON_4
#else
#  define PERL_MON_4 -25
#endif
#ifdef MON_5
#  define PERL_MON_5 MON_5
#else
#  define PERL_MON_5 -26
#endif
#ifdef MON_6
#  define PERL_MON_6 MON_6
#else
#  define PERL_MON_6 -27
#endif
#ifdef MON_7
#  define PERL_MON_7 MON_7
#else
#  define PERL_MON_7 -28
#endif
#ifdef MON_8
#  define PERL_MON_8 MON_8
#else
#  define PERL_MON_8 -29
#endif
#ifdef MON_9
#  define PERL_MON_9 MON_9
#else
#  define PERL_MON_9 -30
#endif
#ifdef MON_10
#  define PERL_MON_10 MON_10
#else
#  define PERL_MON_10 -31
#endif
#ifdef MON_11
#  define PERL_MON_11 MON_11
#else
#  define PERL_MON_11 -32
#endif
#ifdef MON_12
#  define PERL_MON_12 MON_12
#else
#  define PERL_MON_12 -33
#endif
#ifdef ABMON_1
#  define PERL_ABMON_1 ABMON_1
#else
#  define PERL_ABMON_1 -34
#endif
#ifdef ABMON_2
#  define PERL_ABMON_2 ABMON_2
#else
#  define PERL_ABMON_2 -35
#endif
#ifdef ABMON_3
#  define PERL_ABMON_3 ABMON_3
#else
#  define PERL_ABMON_3 -36
#endif
#ifdef ABMON_4
#  define PERL_ABMON_4 ABMON_4
#else
#  define PERL_ABMON_4 -37
#endif
#ifdef ABMON_5
#  define PERL_ABMON_5 ABMON_5
#else
#  define PERL_ABMON_5 -38
#endif
#ifdef ABMON_6
#  define PERL_ABMON_6 ABMON_6
#else
#  define PERL_ABMON_6 -39
#endif
#ifdef ABMON_7
#  define PERL_ABMON_7 ABMON_7
#else
#  define PERL_ABMON_7 -40
#endif
#ifdef ABMON_8
#  define PERL_ABMON_8 ABMON_8
#else
#  define PERL_ABMON_8 -41
#endif
#ifdef ABMON_9
#  define PERL_ABMON_9 ABMON_9
#else
#  define PERL_ABMON_9 -42
#endif
#ifdef ABMON_10
#  define PERL_ABMON_10 ABMON_10
#else
#  define PERL_ABMON_10 -43
#endif
#ifdef ABMON_11
#  define PERL_ABMON_11 ABMON_11
#else
#  define PERL_ABMON_11 -44
#endif
#ifdef ABMON_12
#  define PERL_ABMON_12 ABMON_12
#else
#  define PERL_ABMON_12 -45
#endif
#ifdef ERA
#  define PERL_ERA ERA
#else
#  define PERL_ERA -46
#endif
#ifdef ERA_D_FMT
#  define PERL_ERA_D_FMT ERA_D_FMT
#else
#  define PERL_ERA_D_FMT -47
#endif
#ifdef ERA_D_T_FMT
#  define PERL_ERA_D_T_FMT ERA_D_T_FMT
#else
#  define PERL_ERA_D_T_FMT -48
#endif
#ifdef ERA_T_FMT
#  define PERL_ERA_T_FMT ERA_T_FMT
#else
#  define PERL_ERA_T_FMT -49
#endif
#ifdef ALT_DIGITS
#  define PERL_ALT_DIGITS ALT_DIGITS
#else
#  define PERL_ALT_DIGITS -50
#endif
#ifdef RADIXCHAR
#  define PERL_RADIXCHAR RADIXCHAR
#else
#  define PERL_RADIXCHAR -51
#endif
#ifdef THOUSEP
#  define PERL_THOUSEP THOUSEP
#else
#  define PERL_THOUSEP -52
#endif
#ifdef YESEXPR
#  define PERL_YESEXPR YESEXPR
#else
#  define PERL_YESEXPR -53
#endif
#ifdef YESSTR
#  define PERL_YESSTR YESSTR
#else
#  define PERL_YESSTR -54
#endif
#ifdef NOEXPR
#  define PERL_NOEXPR NOEXPR
#else
#  define PERL_NOEXPR -55
#endif
#ifdef NOSTR
#  define PERL_NOSTR NOSTR
#else
#  define PERL_NOSTR -56
#endif
#ifdef CRNCYSTR
#  define PERL_CRNCYSTR CRNCYSTR
#else
#  define PERL_CRNCYSTR -57
#endif

#endif
