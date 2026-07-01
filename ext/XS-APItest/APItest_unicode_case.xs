UV
test_toLOWER(UV ord)
    CODE:
        RETVAL = toLOWER(ord);
    OUTPUT:
        RETVAL

UV
test_toLOWER_L1(UV ord)
    CODE:
        RETVAL = toLOWER_L1(ord);
    OUTPUT:
        RETVAL

UV
test_toLOWER_LC(UV ord)
    CODE:
        RETVAL = toLOWER_LC(ord);
    OUTPUT:
        RETVAL

AV *
test_toLOWER_uni(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toLOWER_uni(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toLOWER_uvchr(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toLOWER_uvchr(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toLOWER_utf8(SV * p, int type)
    PREINIT:
        U8 *input;
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
        const U8 * e;
        UV resultant_cp = UV_MAX;   /* Initialized because of dumb compilers */
    CODE:
        input = (U8 *) SvPV(p, len);
        if (type >= 0) {
           av = newAV_alloc_x(3);
            e = input + UTF8SKIP(input) - type;
            resultant_cp = toLOWER_utf8_safe(input, e, s, &len);
            av_push_simple(av, newSVuv(resultant_cp));

            utf8 = newSVpvn((char *) s, len);
            SvUTF8_on(utf8);
            av_push_simple(av, utf8);

            av_push_simple(av, newSVuv(len));
            RETVAL = av;
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

UV
test_toFOLD(UV ord)
    CODE:
        RETVAL = toFOLD(ord);
    OUTPUT:
        RETVAL

UV
test_toFOLD_LC(UV ord)
    CODE:
        RETVAL = toFOLD_LC(ord);
    OUTPUT:
        RETVAL

AV *
test_toFOLD_uni(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toFOLD_uni(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toFOLD_uvchr(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toFOLD_uvchr(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toFOLD_utf8(SV * p, int type)
    PREINIT:
        U8 *input;
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
        const U8 * e;
        UV resultant_cp = UV_MAX;
    CODE:
        input = (U8 *) SvPV(p, len);
        if (type >= 0) {
            av = newAV_alloc_x(3);
            e = input + UTF8SKIP(input) - type;
            resultant_cp = toFOLD_utf8_safe(input, e, s, &len);
            av_push_simple(av, newSVuv(resultant_cp));

            utf8 = newSVpvn((char *) s, len);
            SvUTF8_on(utf8);
            av_push_simple(av, utf8);

            av_push_simple(av, newSVuv(len));
            RETVAL = av;
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

UV
test_toUPPER(UV ord)
    CODE:
        RETVAL = toUPPER(ord);
    OUTPUT:
        RETVAL

UV
test_toUPPER_LC(UV ord)
    CODE:
        RETVAL = toUPPER_LC(ord);
    OUTPUT:
        RETVAL

AV *
test_toUPPER_uni(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toUPPER_uni(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toUPPER_uvchr(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toUPPER_uvchr(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toUPPER_utf8(SV * p, int type)
    PREINIT:
        U8 *input;
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
        const U8 * e;
        UV resultant_cp = UV_MAX;
    CODE:
        input = (U8 *) SvPV(p, len);
        if (type >= 0) {
            av = newAV_alloc_x(3);
            e = input + UTF8SKIP(input) - type;
            resultant_cp = toUPPER_utf8_safe(input, e, s, &len);
            av_push_simple(av, newSVuv(resultant_cp));

            utf8 = newSVpvn((char *) s, len);
            SvUTF8_on(utf8);
            av_push_simple(av, utf8);

            av_push_simple(av, newSVuv(len));
            RETVAL = av;
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

UV
test_toTITLE(UV ord)
    CODE:
        RETVAL = toTITLE(ord);
    OUTPUT:
        RETVAL

AV *
test_toTITLE_uni(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toTITLE_uni(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toTITLE_uvchr(UV ord)
    PREINIT:
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
    CODE:
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVuv(toTITLE_uvchr(ord, s, &len)));

        utf8 = newSVpvn((char *) s, len);
        SvUTF8_on(utf8);
        av_push_simple(av, utf8);

        av_push_simple(av, newSVuv(len));
        RETVAL = av;
    OUTPUT:
        RETVAL

AV *
test_toTITLE_utf8(SV * p, int type)
    PREINIT:
        U8 *input;
        U8 s[UTF8_MAXBYTES_CASE + 1];
        STRLEN len;
        AV *av;
        SV *utf8;
        const U8 * e;
        UV resultant_cp = UV_MAX;
    CODE:
        input = (U8 *) SvPV(p, len);
        if (type >= 0) {
            av = newAV_alloc_x(3);
            e = input + UTF8SKIP(input) - type;
            resultant_cp = toTITLE_utf8_safe(input, e, s, &len);
            av_push_simple(av, newSVuv(resultant_cp));

            utf8 = newSVpvn((char *) s, len);
            SvUTF8_on(utf8);
            av_push_simple(av, utf8);

            av_push_simple(av, newSVuv(len));
            RETVAL = av;
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL
