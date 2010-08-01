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
 * shift form so that ext/B/defsubs_h.PL will pick them up.
 *
 * Data structures used in the two headers have common fields, and in fact one
 * is copied onto the other.  This makes it easy to keep them in sync */

/* This tells where the first of these bits is.  Setting it to 0 saved cycles
 * and memory.  I (khw) think the code will work if changed back, but haven't
 * tested it */
#define RXf_PMf_STD_PMMOD_SHIFT 0

/* The bits need to be ordered so that the msix are contiguous starting at bit
 * RXf_PMf_STD_PMMOD_SHIFT, followed by the p.  See STD_PAT_MODS and
 * INT_PAT_MODS in regexp.h for the reason contiguity is needed */
#define RXf_PMf_MULTILINE      (1 << (RXf_PMf_STD_PMMOD_SHIFT+0))    /* /m */
#define RXf_PMf_SINGLELINE     (1 << (RXf_PMf_STD_PMMOD_SHIFT+1))    /* /s */
#define RXf_PMf_FOLD           (1 << (RXf_PMf_STD_PMMOD_SHIFT+2))    /* /i */
#define RXf_PMf_EXTENDED       (1 << (RXf_PMf_STD_PMMOD_SHIFT+3))    /* /x */
#define RXf_PMf_KEEPCOPY       (1 << (RXf_PMf_STD_PMMOD_SHIFT+4))    /* /p */
#define RXf_PMf_LOCALE         (1 << (RXf_PMf_STD_PMMOD_SHIFT+5))

/* Next available bit after the above.  Name begins with '_' so won't be
 * exported by B */
#define _RXf_PMf_SHIFT_NEXT (RXf_PMf_STD_PMMOD_SHIFT+6)

/* Mask of the above bits.  These need to be transferred from op_pmflags to
 * re->extflags during compilation */
#define RXf_PMf_COMPILETIME    (RXf_PMf_MULTILINE|RXf_PMf_SINGLELINE|RXf_PMf_LOCALE|RXf_PMf_FOLD|RXf_PMf_EXTENDED|RXf_PMf_KEEPCOPY)

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

#define PMf_COMPILETIME RXf_PMf_COMPILETIME

/*  Error check that haven't left something out of this.  This isn't done
 *  directly in the #define because doing so confuses regcomp.pl.
 *  (2**n - 1) is n 1 bits, so the below gets the contiguous bits between the
 *  beginning and ending shifts */
#if RXf_PMf_COMPILETIME != (((1 << (_RXf_PMf_SHIFT_NEXT))-1) \
                            & (~((1 << RXf_PMf_STD_PMMOD_SHIFT)-1)))
#   error RXf_PMf_COMPILETIME is invalid
#endif
