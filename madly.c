/*    madly.c
 *
 *    Copyright (c) 2004, 2005, 2006 Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 * 
 *    Note that this file was originally generated as an output from
 *    GNU bison version 1.875, but now the code is statically maintained
 *    and edited; the bits that are dependent on perly.y/madly.y are now
 *    #included from the files perly.tab/madly.tab and perly.act/madly.act.
 *
 *    Here is an important copyright statement from the original, generated
 *    file:
 *
 *	As a special exception, when this file is copied by Bison into a
 *	Bison output file, you may use that output file without
 *	restriction.  This special exception was added by the Free
 *	Software Foundation in version 1.24 of Bison.
 * 
 * Note that this file is essentially empty, and just #includes perly.c,
 * to allow compilation of a second parser, Perl_madparse, that is
 * identical to Perl_yyparse, but which includes the parser tables from
 * madly.{tab,act} rather than perly.{tab,act}. This is controlled by
 * the PERL_IN_MADLY_C define.
 */

#define PERL_IN_MADLY_C

#include "perly.c"

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
