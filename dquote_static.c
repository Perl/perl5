/*    dquote_static.c
 *
 * This file contains static inline functions that are related to
 * parsing double-quotish expressions, but are used in more than
 * one file.
 *
 * It is currently #included by regcomp.c and toke.c.
*/

#define PERL_IN_DQUOTE_STATIC_C
#include "proto.h"
#include "embed.h"

/*
 - regcurly - a little FSA that accepts {\d+,?\d*}
    Pulled from regcomp.c.
 */
PERL_STATIC_INLINE I32
S_regcurly(register const char *s)
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
    if (*s != '}')
	return FALSE;
    return TRUE;
}
/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
