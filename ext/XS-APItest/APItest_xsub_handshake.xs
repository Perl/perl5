MODULE = XS::APItest            PACKAGE = XS::APItest::XSUB

BOOT:
    newXS("XS::APItest::XSUB::XS_VERSION_undef", XS_XS__APItest__XSUB_XS_VERSION_undef, __FILE__);
    newXS("XS::APItest::XSUB::XS_VERSION_empty", XS_XS__APItest__XSUB_XS_VERSION_empty, __FILE__);
    newXS("XS::APItest::XSUB::XS_APIVERSION_invalid", XS_XS__APItest__XSUB_XS_APIVERSION_invalid, __FILE__);

void
XS_VERSION_defined(...)
    PPCODE:
        XS_VERSION_BOOTCHECK;
        XSRETURN_EMPTY;

void
XS_APIVERSION_valid(...)
    PPCODE:
        XS_APIVERSION_BOOTCHECK;
        XSRETURN_EMPTY;

void
xsreturn( int len )
    PPCODE:
        int i = 0;
        EXTEND( SP, len );
        for ( ; i < len; i++ ) {
            ST(i) = sv_2mortal( newSViv(i) );
        }
        XSRETURN( len );

void
xsreturn_iv()
    PPCODE:
        XSRETURN_IV(I32_MIN + 1);

void
xsreturn_uv()
    PPCODE:
        XSRETURN_UV( (U32)((1U<<31) + 1) );

void
xsreturn_nv()
    PPCODE:
        XSRETURN_NV(0.25);

void
xsreturn_pv()
    PPCODE:
        XSRETURN_PV("returned");

void
xsreturn_pvn()
    PPCODE:
        XSRETURN_PVN("returned too much",8);

void
xsreturn_no()
    PPCODE:
        XSRETURN_NO;

void
xsreturn_yes()
    PPCODE:
        XSRETURN_YES;

void
xsreturn_undef()
    PPCODE:
        XSRETURN_UNDEF;

void
xsreturn_empty()
    PPCODE:
        XSRETURN_EMPTY;

void
test_mismatch_xs_handshake_api_ver(...)
    ALIAS:
        test_mismatch_xs_handshake_bad_struct = 1
        test_mismatch_xs_handshake_bad_struct_and_ver = 2
    PPCODE:
    if(ix == 0) {
#ifdef MULTIPLICITY
        Perl_xs_handshake(HS_KEYp(sizeof(PerlInterpreter),
                                  TRUE, NULL, FALSE,
                                  sizeof("v1.1337.0")-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v1.1337.0");
#else
        Perl_xs_handshake(HS_KEYp(sizeof(struct PerlHandShakeInterpreter),
                                  FALSE, NULL, FALSE,
                                  sizeof("v1.1337.0")-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v1.1337.0");
#endif
    }
    else if(ix == 1) {
#ifdef MULTIPLICITY
        Perl_xs_handshake(HS_KEYp(sizeof(PerlInterpreter)+1,
                                  TRUE, NULL, FALSE,
                                  sizeof("v" PERL_API_VERSION_STRING)-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v" PERL_API_VERSION_STRING);
#else
        Perl_xs_handshake(HS_KEYp(sizeof(struct PerlHandShakeInterpreter)+1,
                                  FALSE, NULL, FALSE,
                                  sizeof("v" PERL_API_VERSION_STRING)-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v" PERL_API_VERSION_STRING);
#endif
    }
    else {
#ifdef MULTIPLICITY
        Perl_xs_handshake(HS_KEYp(sizeof(PerlInterpreter)+1,
                                  TRUE, NULL, FALSE,
                                  sizeof("v1.1337.0")-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v1.1337.0");
#else
        Perl_xs_handshake(HS_KEYp(sizeof(struct PerlHandShakeInterpreter)+1,
                                    FALSE, NULL, FALSE,
                                    sizeof("v1.1337.0")-1,
                                    sizeof("")-1),
                                    HS_CXT, __FILE__, items, ax,
                                    "v1.1337.0");
#endif
    }
