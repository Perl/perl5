MODULE = XS::APItest            PACKAGE = XS::APItest::utf8

int
bytes_cmp_utf8(bytes, utf8)
        SV *bytes
        SV *utf8
    PREINIT:
        const U8 *b;
        STRLEN blen;
        const U8 *u;
        STRLEN ulen;
    CODE:
        b = (const U8 *)SvPVbyte(bytes, blen);
        u = (const U8 *)SvPVbyte(utf8, ulen);
        RETVAL = bytes_cmp_utf8(b, blen, u, ulen);
    OUTPUT:
        RETVAL

AV *
test_utf8_to_bytes(bytes, len)
        U8 * bytes
        STRLEN len
    PREINIT:
        char * ret;
    CODE:
        RETVAL = newAV_mortal();

        ret = (char *) utf8_to_bytes(bytes, &len);
        av_push_simple(RETVAL, newSVpv(ret, 0));

        /* utf8_to_bytes uses (STRLEN)-1 to signal errors, and we want to
         * return that as -1 to perl, so cast to SSize_t in case
         * sizeof(IV) > sizeof(STRLEN) */
        av_push_simple(RETVAL, newSViv((SSize_t)len));
        av_push_simple(RETVAL, newSVpv((const char *) bytes, 0));

    OUTPUT:
        RETVAL

AV *
test_utf8n_to_uvchr_msgs(s, len, flags)
        char *s
        STRLEN len
        U32 flags
    PREINIT:
        STRLEN retlen;
        UV ret;
        U32 errors;
        AV *msgs = NULL;

    CODE:
        RETVAL = newAV_mortal();

        ret = utf8n_to_uvchr_msgs((U8*)  s,
                                         len,
                                         &retlen,
                                         flags,
                                         &errors,
                                         &msgs);

        /* Returns the return value in [0]; <retlen> in [1], <errors> in [2] */
        av_push_simple(RETVAL, newSVuv(ret));
        if (retlen == (STRLEN) -1) {
            av_push_simple(RETVAL, newSViv(-1));
        }
        else {
            av_push_simple(RETVAL, newSVuv(retlen));
        }
        av_push_simple(RETVAL, newSVuv(errors));

        /* And any messages in [3] */
        if (msgs) {
            av_push_simple(RETVAL, newRV_noinc((SV*)msgs));
        }

    OUTPUT:
        RETVAL

AV *
test_utf8n_to_uvchr_error(s, len, flags)

        char *s
        STRLEN len
        U32 flags
    PREINIT:
        STRLEN retlen;
        UV ret;
        U32 errors;

    CODE:
        /* Now that utf8n_to_uvchr() is a trivial wrapper for
         * utf8n_to_uvchr_error(), call the latter with the inputs.  It always
         * asks for the actual length to be returned and errors to be returned
         *
         * Length to assume <s> is; not checked, so could have buffer overflow
         */
        RETVAL = newAV_mortal();

        ret = utf8n_to_uvchr_error((U8*) s,
                                         len,
                                         &retlen,
                                         flags,
                                         &errors);

        /* Returns the return value in [0]; <retlen> in [1], <errors> in [2] */
        av_push_simple(RETVAL, newSVuv(ret));
        if (retlen == (STRLEN) -1) {
            av_push_simple(RETVAL, newSViv(-1));
        }
        else {
            av_push_simple(RETVAL, newSVuv(retlen));
        }
        av_push_simple(RETVAL, newSVuv(errors));

    OUTPUT:
        RETVAL

AV *
test_valid_utf8_to_uvchr(s)

        SV *s
    PREINIT:
        STRLEN retlen;
        UV ret;

    CODE:
        /* Call utf8n_to_uvchr() with the inputs.  It always asks for the
         * actual length to be returned
         *
         * Length to assume <s> is; not checked, so could have buffer overflow
         */
        RETVAL = newAV_mortal();

        ret = valid_utf8_to_uv((U8*) SvPV_nolen(s), &retlen);

        /* Returns the return value in [0]; <retlen> in [1] */
        av_push_simple(RETVAL, newSVuv(ret));
        av_push_simple(RETVAL, newSVuv(retlen));

    OUTPUT:
        RETVAL

SV *
test_uvchr_to_utf8_flags(uv, flags)

        SV *uv
        SV *flags
    PREINIT:
        U8 dest[UTF8_MAXBYTES + 1];
        U8 *ret;

    CODE:
        /* Call uvchr_to_utf8_flags() with the inputs.  */
        ret = uvchr_to_utf8_flags(dest, SvUV(uv), SvUV(flags));
        if (! ret) {
            XSRETURN_UNDEF;
        }
        RETVAL = newSVpvn((char *) dest, ret - dest);

    OUTPUT:
        RETVAL

AV *
test_uvchr_to_utf8_flags_msgs(uv, flags)

        SV *uv
        SV *flags
    PREINIT:
        U8 dest[UTF8_MAXBYTES + 1];
        U8 *ret;

    CODE:
        HV *msgs = NULL;
        RETVAL = newAV_mortal();

        ret = uvchr_to_utf8_flags_msgs(dest, SvUV(uv), SvUV(flags), &msgs);

        if (ret) {
            av_push_simple(RETVAL, newSVpvn((char *) dest, ret - dest));
        }
        else {
            av_push_simple(RETVAL,  &PL_sv_undef);
        }

        if (msgs) {
            av_push_simple(RETVAL, newRV_noinc((SV*)msgs));
        }

    OUTPUT:
        RETVAL
