MODULE = XS::APItest            PACKAGE = XS::APItest::CvREFCOUNTED_ANYSV

UV
test_CvREFCOUNTED_ANYSV()
    CODE:
    {
        U32 failed = 0;

        /* Doesn't matter what actual function we wrap because we're never
         * actually going to call it. */
        CV *cv = newXS("XS::APItest::(test-cv-1)", XS_XS__APItest__XSUB_XS_VERSION_undef, __FILE__);
        SV *sv = newSV(0);
        CvXSUBANY(cv).any_sv = SvREFCNT_inc(sv);
        CvREFCOUNTED_ANYSV_on(cv);
        TEST_EXPR(SvREFCNT(sv) == 2);

        SvREFCNT_dec((SV *)cv);
        TEST_EXPR(SvREFCNT(sv) == 1);

        SvREFCNT_dec(sv);

        RETVAL = failed;
    }
    OUTPUT:
        RETVAL
