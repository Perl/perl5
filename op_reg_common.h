/*    op_reg_common.h
 *
 *    Definitions common to by op.h and regexp.h
 *
 *    Copyright (C) 2010 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/* These defines are used in both op.h and regexp.h  The definitions use the
 * shift form so that ext/B/defsubs_h.PL will pick them up */
#define RXf_PMf_MULTILINE	(1 << 0)	/* /m */
#define RXf_PMf_SINGLELINE	(1 << 1)	/* /s */
#define RXf_PMf_FOLD	        (1 << 2)	/* /i */
#define RXf_PMf_EXTENDED	(1 << 3)	/* /x */
#define RXf_PMf_KEEPCOPY	(1 << 4)	/* /p */
#define RXf_PMf_LOCALE		(1 << 5)

/* Next available bit after the above.  Name begins with '_' so won't be
 * exported by B */
#define _RXf_PMf_SHIFT_NEXT 6


/* These copies need to be numerical or defsubs_h.PL won't know about them. */
#define PMf_MULTILINE    1<<0
#define PMf_SINGLELINE   1<<1
#define PMf_FOLD         1<<2
#define PMf_EXTENDED     1<<3
#define PMf_KEEPCOPY     1<<4
#define PMf_LOCALE       1<<5

#if PMf_MULTILINE != RXf_PMf_MULTILINE || PMf_SINGLELINE != RXf_PMf_SINGLELINE || PMf_FOLD != RXf_PMf_FOLD || PMf_EXTENDED != RXf_PMf_EXTENDED || PMf_KEEPCOPY != RXf_PMf_KEEPCOPY || PMf_LOCALE != RXf_PMf_LOCALE
#   error RXf_PMf defines are wrong
#endif
