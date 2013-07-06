/*    inline_invlist.c
 *
 *    Copyright (C) 2012 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#if defined(PERL_IN_UTF8_C) || defined(PERL_IN_REGCOMP_C) || defined(PERL_IN_REGEXEC_C)

/* An element is in an inversion list iff its index is even numbered: 0, 2, 4,
 * etc */
#define ELEMENT_RANGE_MATCHES_INVLIST(i) (! ((i) & 1))
#define PREV_RANGE_MATCHES_INVLIST(i) (! ELEMENT_RANGE_MATCHES_INVLIST(i))

PERL_STATIC_INLINE STRLEN*
S__get_invlist_len_addr(pTHX_ SV* invlist)
{
    /* Return the address of the UV that contains the current number
     * of used elements in the inversion list */

    PERL_ARGS_ASSERT__GET_INVLIST_LEN_ADDR;

    return &(LvTARGLEN(invlist));
}

PERL_STATIC_INLINE UV
S__invlist_len(pTHX_ SV* const invlist)
{
    /* Returns the current number of elements stored in the inversion list's
     * array */

    PERL_ARGS_ASSERT__INVLIST_LEN;

    return *_get_invlist_len_addr(invlist);
}

PERL_STATIC_INLINE bool
S__invlist_contains_cp(pTHX_ SV* const invlist, const UV cp)
{
    /* Does <invlist> contain code point <cp> as part of the set? */

    IV index = _invlist_search(invlist, cp);

    PERL_ARGS_ASSERT__INVLIST_CONTAINS_CP;

    return index >= 0 && ELEMENT_RANGE_MATCHES_INVLIST(index);
}

#endif
