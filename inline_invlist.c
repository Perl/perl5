/*    invlist.h
 *
 *    Copyright (C) 2012 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * This file is a home for static inline functions that cannot go in other
 * headers files, because they depend on proto.h (included after most other
 * headers) or struct definitions.
 *
 */

#if defined(PERL_IN_UTF8_C) || defined(PERL_IN_REGCOMP_C) || defined(PERL_IN_REGEXEC_C)

#endif
