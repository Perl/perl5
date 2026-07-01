AV *
test_delimcpy(SV * from_sv, STRLEN trunc_from, char delim, STRLEN to_len, STRLEN trunc_to, char poison = '?')
    PREINIT:
        char * from;
        I32 retlen;
        char * from_pos_after_copy;
        char * to;
    CODE:
        from = SvPV_nolen(from_sv);
        Newx(to, to_len, char);
        PoisonWith(to, to_len, char, poison);
        assert(trunc_from <= SvCUR(from_sv));
        /* trunc_to allows us to throttle the output size available */
        assert(trunc_to <= to_len);
        from_pos_after_copy = delimcpy(to, to + trunc_to,
                                       from, from + trunc_from,
                                       delim, &retlen);
        RETVAL = newAV_mortal();
        av_push_simple(RETVAL, newSVpvn(to, to_len));
        av_push_simple(RETVAL, newSVuv(retlen));
        av_push_simple(RETVAL, newSVuv(from_pos_after_copy - from));
        Safefree(to);
    OUTPUT:
        RETVAL

AV *
test_delimcpy_no_escape(SV * from_sv, STRLEN trunc_from, char delim, STRLEN to_len, STRLEN trunc_to, char poison = '?')
    PREINIT:
        char * from;
        AV *av;
        I32 retlen;
        char * from_pos_after_copy;
        char * to;
    CODE:
        from = SvPV_nolen(from_sv);
        Newx(to, to_len, char);
        PoisonWith(to, to_len, char, poison);
        assert(trunc_from <= SvCUR(from_sv));
        /* trunc_to allows us to throttle the output size available */
        assert(trunc_to <= to_len);
        from_pos_after_copy = delimcpy_no_escape(to, to + trunc_to,
                                       from, from + trunc_from,
                                       delim, &retlen);
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVpvn(to, to_len));
        av_push_simple(av, newSVuv(retlen));
        av_push_simple(av, newSVuv(from_pos_after_copy - from));
        Safefree(to);
        RETVAL = av;
    OUTPUT:
        RETVAL

SV *
test_Gconvert(SV * number, SV * num_digits)
    PREINIT:
        char buffer[100];
        int len;
        int extras;
    CODE:
        len = (int) SvIV(num_digits);
        /* To silence a -Wformat-overflow compiler warning we     *
         * make allowance for the following characters that may   *
         * appear, in addition to the digits of the significand:  *
         * a leading "-", a single byte radix point, "e-", the    *
         * terminating NULL, and a 3 or 4 digit exponent.         *
         * Ie, allow 8 bytes if nvtype is "double", otherwise 9   *
         * bytes (as the exponent could then contain 4 digits ).  */
        extras = sizeof(NV) == 8 ? 8 : 9;
        if(len > 100 - extras)
            croak("Too long a number for test_Gconvert");
        if (len < 0)
            croak("Too short a number for test_Gconvert");
        PERL_UNUSED_RESULT(Gconvert(SvNV(number), len,
                 0,    /* No trailing zeroes */
                 buffer));
        RETVAL = newSVpv(buffer, 0);
    OUTPUT:
        RETVAL

SV *
test_Perl_langinfo(SV * item)
    CODE:
        RETVAL = newSVpv(Perl_langinfo(SvIV(item)), 0);
    OUTPUT:
        RETVAL

SV *
gimme()
    CODE:
        /* facilitate tests that GIMME_V gives the right result
         * in XS calls */
        int gimme = GIMME_V;
        SV* sv = get_sv("XS::APItest::GIMME_V", GV_ADD);
        sv_setiv_mg(sv, (IV)gimme);
        RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

bool
valid_identifier(SV *s)
    CODE:
        RETVAL = valid_identifier_sv(s);
    OUTPUT:
        RETVAL

const char *
svtypename(U8 type)
