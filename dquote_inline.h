/*    dquote_inline.h
 *
 *    Copyright (C) 2015 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#ifndef DQUOTE_INLINE_H /* Guard against nested #inclusion */
#define DQUOTE_INLINE_H

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

PERL_STATIC_INLINE bool
S_grok_bslash_x(pTHX_ char **s, UV *uv, const char** error_msg,
                      const bool output_warning, const bool strict,
                      const bool silence_non_portable,
                      const bool UTF)
{

/*  Documentation to be supplied when interface nailed down finally
 *  This returns FALSE if there is an error which the caller need not recover
 *  from; otherwise TRUE.
 *  It guarantees that the returned codepoint, *uv, when expressed as
 *  utf8 bytes, would fit within the skipped "\x{...}" bytes.
 *
 *  On input:
 *	s   is the address of a pointer to a NULL terminated string that begins
 *	    with 'x', and the previous character was a backslash.  At exit, *s
 *	    will be advanced to the byte just after those absorbed by this
 *	    function.  Hence the caller can continue parsing from there.  In
 *	    the case of an error, this routine has generally positioned *s to
 *	    point just to the right of the first bad spot, so that a message
 *	    that has a "<--" to mark the spot will be correctly positioned.
 *	uv  points to a UV that will hold the output value, valid only if the
 *	    return from the function is TRUE
 *      error_msg is a pointer that will be set to an internal buffer giving an
 *	    error message upon failure (the return is FALSE).  Untouched if
 *	    function succeeds
 *	output_warning says whether to output any warning messages, or suppress
 *	    them
 *	strict is true if anything out of the ordinary should cause this to
 *	    fail instead of warn or be silent.  For example, it requires
 *	    exactly 2 digits following the \x (when there are no braces).
 *	    3 digits could be a mistake, so is forbidden in this mode.
 *      silence_non_portable is true if to suppress warnings about the code
 *          point returned being too large to fit on all platforms.
 *	UTF is true iff the string *s is encoded in UTF-8.
 */
    char* e;
    STRLEN numbers_len;
    I32 flags = PERL_SCAN_DISALLOW_PREFIX;
#ifdef DEBUGGING
    char *start = *s - 1;
    assert(*start == '\\');
#endif

    PERL_ARGS_ASSERT_GROK_BSLASH_X;

    assert(**s == 'x');
    (*s)++;

    if (strict || ! output_warning) {
        flags |= PERL_SCAN_SILENT_ILLDIGIT;
    }

    if (**s != '{') {
        STRLEN len = (strict) ? 3 : 2;

	*uv = grok_hex(*s, &len, &flags, NULL);
	*s += len;
        if (strict && len != 2) {
            if (len < 2) {
                *s += (UTF) ? UTF8SKIP(*s) : 1;
                *error_msg = "Non-hex character";
            }
            else {
                *error_msg = "Use \\x{...} for more than two hex characters";
            }
            return FALSE;
        }
	goto ok;
    }

    e = strchr(*s, '}');
    if (!e) {
        (*s)++;  /* Move past the '{' */
        while (isXDIGIT(**s)) { /* Position beyond the legal digits */
            (*s)++;
        }
        /* XXX The corresponding message above for \o is just '\\o{'; other
         * messages for other constructs include the '}', so are inconsistent.
         */
	*error_msg = "Missing right brace on \\x{}";
	return FALSE;
    }

    (*s)++;    /* Point to expected first digit (could be first byte of utf8
                  sequence if not a digit) */
    numbers_len = e - *s;
    if (numbers_len == 0) {
        if (strict) {
            (*s)++;    /* Move past the } */
            *error_msg = "Number with no digits";
            return FALSE;
        }
        *s = e + 1;
        *uv = 0;
        goto ok;
    }

    flags |= PERL_SCAN_ALLOW_UNDERSCORES;
    if (silence_non_portable) {
        flags |= PERL_SCAN_SILENT_NON_PORTABLE;
    }

    *uv = grok_hex(*s, &numbers_len, &flags, NULL);
    /* Note that if has non-hex, will ignore everything starting with that up
     * to the '}' */

    if (strict && numbers_len != (STRLEN) (e - *s)) {
        *s += numbers_len;
        *s += (UTF) ? UTF8SKIP(*s) : 1;
        *error_msg = "Non-hex character";
        return FALSE;
    }

    /* Return past the '}' */
    *s = e + 1;

  ok:
    /* guarantee replacing "\x{...}" with utf8 bytes fits within
     * existing space */
    assert(UVCHR_SKIP(*uv) < *s - start);
    return TRUE;
}

#endif  /* DQUOTE_INLINE_H */
