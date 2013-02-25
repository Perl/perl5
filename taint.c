/*    taint.c
 *
 *    Copyright (C) 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001,
 *    2002, 2003, 2004, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * '...we will have peace, when you and all your works have perished--and
 *  the works of your dark master to whom you would deliver us.  You are a
 *  liar, Saruman, and a corrupter of men's hearts.'       --Théoden
 *
 *     [p.580 of _The Lord of the Rings_, III/x: "The Voice of Saruman"]
 */

/* This file used to contain a few functions for handling data tainting in Perl.
 * Taint support was removed.
 */

#include "EXTERN.h"
#define PERL_IN_TAINT_C
#include "perl.h"

void
Perl_taint_env(pTHX)
{
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 et:
 */
