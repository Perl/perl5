/*    mathoms.c
 *
 *    Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010,
 *    2011, 2012 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *  Anything that Hobbits had no immediate use for, but were unwilling to
 *  throw away, they called a mathom.  Their dwellings were apt to become
 *  rather crowded with mathoms, and many of the presents that passed from
 *  hand to hand were of that sort.
 *
 *     [p.5 of _The Lord of the Rings_: "Prologue"]
 */



/*
 * This file contains mathoms, various binary artifacts from previous
 * versions of Perl which we cannot completely remove from the core
 * code. The remaining reasons functions should be here are:
 *
 * 1) A function has been replaced by a macro within a minor release,
 *    so XS modules compiled against an older release will expect to
 *    still be able to link against the function
 * 2) A function is deprecated, and so placing it here will cause a compiler
 *    warning to be generated (for participating compilers).
 * 3) A few other reasons, documented with the functions below
 *
 * It used to be that this was the way to handle the case were a function
 * Perl_foo(...) had been replaced by a macro.  But see the 'm' flag discussion
 * in embed.fnc for a better way to handle this.
 *
 * This file can't just be cleaned out periodically, because that would break
 * builds with -DPERL_NO_SHORT_NAMES
 *
 * NOTE: ALL FUNCTIONS IN THIS FILE should have an entry with the 'b' flag in
 * embed.fnc.
 *
 * To move a function to this file, simply cut and paste it here, and change
 * its embed.fnc entry to additionally have the 'b' flag.  If, for some reason
 * a function you'd like to be treated as mathoms can't be moved from its
 * current place, simply enclose it between
 *
 * #ifndef NO_MATHOMS
 *    ...
 * #endif
 *
 * and add the 'b' flag in embed.fnc.
 *
 * The compilation of this file and the functions within it can be suppressed
 * by adding this option to Configure:
 *
 *      -Accflags='-DNO_MATHOMS'
 *
 * Some of the functions here are also deprecated.
 *
 */


#include "EXTERN.h"
#define PERL_IN_MATHOMS_C
#include "perl.h"

#ifdef NO_MATHOMS
/* ..." warning: ISO C forbids an empty source file"
   So make sure we have something in here by processing the headers anyway.
 */
#else

/* The functions in this file should be able to call other deprecated functions
 * without a compiler warning */
GCC_DIAG_IGNORE(-Wdeprecated-declarations)

void
Perl_load_mathoms()
{
    PERL_ARGS_ASSERT_LOAD_MATHOMS;

    /* This exists only to make sure the functions in this file get loaded, as
     * it is referred to by a structure element in intrpvar.h */
}

/* ref() is now a macro using Perl_doref;
 * this version provided for binary compatibility only.
 */
OP *
Perl_ref(pTHX_ OP *o, I32 type)
{
    PERL_ARGS_ASSERT_REF;

    return doref(o, type, TRUE);
}

#if defined(HUGE_VAL) || (defined(USE_LONG_DOUBLE) && defined(HUGE_VALL))
/*
 * This hack is to force load of "huge" support from libm.a
 * So it is in perl for (say) POSIX to use.
 * Needed for SunOS with Sun's 'acc' for example.
 */
NV
Perl_huge(void)
{
#  if defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)
    return HUGE_VALL;
#  else
    return HUGE_VAL;
#  endif
}
#endif

GCC_DIAG_RESTORE

#endif /* NO_MATHOMS */

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
