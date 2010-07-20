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
#define PMf_MULTILINE	        (1 << 0)	/* /m */
#define RXf_PMf_SINGLELINE	(1 << 1)	/* /s */
#define PMf_SINGLELINE	        (1 << 1)	/* /s */
#define RXf_PMf_FOLD	        (1 << 2)	/* /i */
#define PMf_FOLD	        (1 << 2)	/* /i */
#define RXf_PMf_EXTENDED	(1 << 3)	/* /x */
#define PMf_EXTENDED	        (1 << 3)	/* /x */
#define RXf_PMf_KEEPCOPY	(1 << 4)	/* /p */
#define PMf_KEEPCOPY	        (1 << 4)	/* /p */
#define RXf_PMf_LOCALE		(1 << 5)
#define PMf_LOCALE		(1 << 5)

#define _RXf_PMf_SHIFT 5    /* Begins with '_' so won't be exported by B */
