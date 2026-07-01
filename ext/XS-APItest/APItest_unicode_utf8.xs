STRLEN
test_UTF8_IS_REPLACEMENT(char *s, STRLEN len)
    CODE:
        RETVAL = UTF8_IS_REPLACEMENT(s, s + len);
    OUTPUT:
        RETVAL

bool
test_isQUOTEMETA(UV ord)
    CODE:
        RETVAL = isQUOTEMETA(ord);
    OUTPUT:
        RETVAL

UV
test_OFFUNISKIP(UV ord)
    CODE:
        RETVAL = OFFUNISKIP(ord);
    OUTPUT:
        RETVAL

bool
test_OFFUNI_IS_INVARIANT(UV ord)
    CODE:
        RETVAL = OFFUNI_IS_INVARIANT(ord);
    OUTPUT:
        RETVAL

bool
test_UVCHR_IS_INVARIANT(UV ord)
    CODE:
        RETVAL = UVCHR_IS_INVARIANT(ord);
    OUTPUT:
        RETVAL

bool
test_UTF8_IS_INVARIANT(char ch)
    CODE:
        RETVAL = UTF8_IS_INVARIANT(ch);
    OUTPUT:
        RETVAL

UV
test_UVCHR_SKIP(UV ord)
    CODE:
        RETVAL = UVCHR_SKIP(ord);
    OUTPUT:
        RETVAL

UV
test_UTF8_SKIP(char * ch)
    CODE:
        RETVAL = UTF8_SKIP(ch);
    OUTPUT:
        RETVAL

bool
test_UTF8_IS_START(char ch)
    CODE:
        RETVAL = UTF8_IS_START(ch);
    OUTPUT:
        RETVAL

bool
test_UTF8_IS_CONTINUATION(char ch)
    CODE:
        RETVAL = UTF8_IS_CONTINUATION(ch);
    OUTPUT:
        RETVAL

bool
test_UTF8_IS_CONTINUED(char ch)
    CODE:
        RETVAL = UTF8_IS_CONTINUED(ch);
    OUTPUT:
        RETVAL

bool
test_UTF8_IS_DOWNGRADEABLE_START(char ch)
    CODE:
        RETVAL = UTF8_IS_DOWNGRADEABLE_START(ch);
    OUTPUT:
        RETVAL

bool
test_UTF8_IS_ABOVE_LATIN1(char ch)
    CODE:
        RETVAL = UTF8_IS_ABOVE_LATIN1(ch);
    OUTPUT:
        RETVAL

bool
test_isUTF8_POSSIBLY_PROBLEMATIC(char ch)
    CODE:
        RETVAL = isUTF8_POSSIBLY_PROBLEMATIC(ch);
    OUTPUT:
        RETVAL

STRLEN
test_isUTF8_CHAR(char *s, STRLEN len)
    CODE:
        RETVAL = isUTF8_CHAR((U8 *) s, (U8 *) s + len);
    OUTPUT:
        RETVAL

STRLEN
test_isUTF8_CHAR_flags(char *s, STRLEN len, U32 flags)
    CODE:
        RETVAL = isUTF8_CHAR_flags((U8 *) s, (U8 *) s + len, flags);
    OUTPUT:
        RETVAL

STRLEN
test_isSTRICT_UTF8_CHAR(char *s, STRLEN len)
    CODE:
        RETVAL = isSTRICT_UTF8_CHAR((U8 *) s, (U8 *) s + len);
    OUTPUT:
        RETVAL

STRLEN
test_isC9_STRICT_UTF8_CHAR(char *s, STRLEN len)
    CODE:
        RETVAL = isC9_STRICT_UTF8_CHAR((U8 *) s, (U8 *) s + len);
    OUTPUT:
        RETVAL

IV
test_is_utf8_valid_partial_char_flags(char *s, STRLEN len, U32 flags)
    CODE:
        /* RETVAL should be bool (here and in tests below), but making it IV
         * allows us to test it returning 0 or 1 */
        RETVAL = is_utf8_valid_partial_char_flags((U8 *) s, (U8 *) s + len, flags);
    OUTPUT:
        RETVAL

IV
test_is_utf8_string(char *s, STRLEN len)
    CODE:
        RETVAL = is_utf8_string((U8 *) s, len);
    OUTPUT:
        RETVAL

#define WORDSIZE            sizeof(PERL_UINTMAX_T)

AV *
test_is_utf8_invariant_string_loc(U8 *s, STRLEN offset, STRLEN len)
    PREINIT:
        AV *av;
        const U8 * ep = NULL;
        PERL_UINTMAX_T* copy;
    CODE:
        /* 'offset' is number of bytes past a word boundary the testing of 's'
         * is to start at.  Allocate space that does start at the word
         * boundary, and copy 's' to the correct offset past it.  Then call the
         * tested function with that position */
        Newx(copy, 1 + ((len + WORDSIZE - 1) / WORDSIZE), PERL_UINTMAX_T);
        Copy(s, (U8 *) copy + offset, len, U8);
        av = newAV_alloc_x(2);
        av_push_simple(av, newSViv(is_utf8_invariant_string_loc((U8 *) copy + offset, len, &ep)));
        av_push_simple(av, newSViv(ep - ((U8 *) copy + offset)));
        RETVAL = av;
        Safefree(copy);
    OUTPUT:
        RETVAL

STRLEN
test_variant_under_utf8_count(U8 *s, STRLEN offset, STRLEN len)
    PREINIT:
        PERL_UINTMAX_T * copy;
    CODE:
        Newx(copy, 1 + ((len + WORDSIZE - 1) / WORDSIZE), PERL_UINTMAX_T);
        Copy(s, (U8 *) copy + offset, len, U8);
        RETVAL = variant_under_utf8_count((U8 *) copy + offset, (U8 *) copy + offset + len);
        Safefree(copy);
    OUTPUT:
        RETVAL

STRLEN
test_utf8_length(U8 *s, STRLEN offset, STRLEN len)
CODE:
    RETVAL = utf8_length(s + offset, s + len);
OUTPUT:
    RETVAL

AV *
test_is_utf8_string_loc(char *s, STRLEN len)
    PREINIT:
        AV *av;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(2);
        av_push_simple(av, newSViv(is_utf8_string_loc((U8 *) s, len, &ep)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_is_utf8_string_loclen(char *s, STRLEN len)
    PREINIT:
        AV *av;
        STRLEN ret_len;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSViv(is_utf8_string_loclen((U8 *) s, len, &ep, &ret_len)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        av_push_simple(av, newSVuv(ret_len));
        RETVAL = av;
    OUTPUT:
        RETVAL

IV
test_is_utf8_string_flags(char *s, STRLEN len, U32 flags)
    CODE:
        RETVAL = is_utf8_string_flags((U8 *) s, len, flags);
    OUTPUT:
        RETVAL

AV *
test_is_utf8_string_loc_flags(char *s, STRLEN len, U32 flags)
    PREINIT:
        AV *av;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(2);
        av_push_simple(av, newSViv(is_utf8_string_loc_flags((U8 *) s, len, &ep, flags)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_is_utf8_string_loclen_flags(char *s, STRLEN len, U32 flags)
    PREINIT:
        AV *av;
        STRLEN ret_len;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSViv(is_utf8_string_loclen_flags((U8 *) s, len, &ep, &ret_len, flags)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        av_push_simple(av, newSVuv(ret_len));
        RETVAL = av;
    OUTPUT:
        RETVAL

IV
test_is_strict_utf8_string(char *s, STRLEN len)
    CODE:
        RETVAL = is_strict_utf8_string((U8 *) s, len);
    OUTPUT:
        RETVAL

AV *
test_is_strict_utf8_string_loc(char *s, STRLEN len)
    PREINIT:
        AV *av;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(2);
        av_push_simple(av, newSViv(is_strict_utf8_string_loc((U8 *) s, len, &ep)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_is_strict_utf8_string_loclen(char *s, STRLEN len)
    PREINIT:
        AV *av;
        STRLEN ret_len;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSViv(is_strict_utf8_string_loclen((U8 *) s, len, &ep, &ret_len)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        av_push_simple(av, newSVuv(ret_len));
        RETVAL = av;
    OUTPUT:
        RETVAL

IV
test_is_c9strict_utf8_string(char *s, STRLEN len)
    CODE:
        RETVAL = is_c9strict_utf8_string((U8 *) s, len);
    OUTPUT:
        RETVAL

AV *
test_is_c9strict_utf8_string_loc(char *s, STRLEN len)
    PREINIT:
        AV *av;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(2);
        av_push_simple(av, newSViv(is_c9strict_utf8_string_loc((U8 *) s, len, &ep)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_is_c9strict_utf8_string_loclen(char *s, STRLEN len)
    PREINIT:
        AV *av;
        STRLEN ret_len;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSViv(is_c9strict_utf8_string_loclen((U8 *) s, len, &ep, &ret_len)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        av_push_simple(av, newSVuv(ret_len));
        RETVAL = av;
    OUTPUT:
        RETVAL

IV
test_is_utf8_fixed_width_buf_flags(char *s, STRLEN len, U32 flags)
    CODE:
        RETVAL = is_utf8_fixed_width_buf_flags((U8 *) s, len, flags);
    OUTPUT:
        RETVAL

AV *
test_is_utf8_fixed_width_buf_loc_flags(char *s, STRLEN len, U32 flags)
    PREINIT:
        AV *av;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(2);
        av_push_simple(av, newSViv(is_utf8_fixed_width_buf_loc_flags((U8 *) s, len, &ep, flags)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_is_utf8_fixed_width_buf_loclen_flags(char *s, STRLEN len, U32 flags)
    PREINIT:
        AV *av;
        STRLEN ret_len;
        const U8 * ep;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSViv(is_utf8_fixed_width_buf_loclen_flags((U8 *) s, len, &ep, &ret_len, flags)));
        av_push_simple(av, newSViv(ep - (U8 *) s));
        av_push_simple(av, newSVuv(ret_len));
        RETVAL = av;
    OUTPUT:
        RETVAL

IV
test_utf8_hop_safe(SV *s_sv, STRLEN s_off, IV hop)
    PREINIT:
        STRLEN len;
        U8 *p;
        U8 *r;
    CODE:
        p = (U8 *)SvPV(s_sv, len);
        r = utf8_hop_safe(p + s_off, hop, p, p + len);
        RETVAL = r - p;
    OUTPUT:
        RETVAL
