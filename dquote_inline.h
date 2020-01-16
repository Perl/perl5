/*    dquote_inline.h
 *
 *    Copyright (C) 2015 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#ifndef PERL_DQUOTE_INLINE_H_ /* Guard against nested #inclusion */
#define PERL_DQUOTE_INLINE_H_

/*
 - regcurly - a little FSA that accepts {\d+,?\d*}
    Pulled from reg.c.
 */
PERL_STATIC_INLINE I32
S_regcurly(const char *s)
{
    PERL_ARGS_ASSERT_REGCURLY;

    if (*s++ != '{')
	return FALSE;
    if (!isDIGIT(*s))
	return FALSE;
    while (isDIGIT(*s))
	s++;
    if (*s == ',') {
	s++;
	while (isDIGIT(*s))
	    s++;
    }

    return *s == '}';
}

#endif  /* PERL_DQUOTE_INLINE_H_ */
