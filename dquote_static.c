/*    dquote_static.c
 *
 * This file contains static inline functions that are related to
 * parsing double-quotish expressions, but are used in more than
 * one file.
 *
 * It is currently #included by regcomp.c and toke.c.
*/

/*
 - regcurly - a little FSA that accepts {\d+,?\d*}
    Pulled from regcomp.c.
 */

/* embed.pl doesn't yet know how to handle static inline functions, so
   manually decorate it here with gcc-style attributes.
*/
PERL_STATIC_INLINE I32
regcurly(register const char *s)
    __attribute__warn_unused_result__
    __attribute__pure__
    __attribute__nonnull__(1);

PERL_STATIC_INLINE I32
regcurly(register const char *s)
{
    assert(s);

    if (*s++ != '{')
	return FALSE;
    if (!isDIGIT(*s))
	return FALSE;
    while (isDIGIT(*s))
	s++;
    if (*s == ',')
	s++;
    while (isDIGIT(*s))
	s++;
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
