MODULE = XS::APItest            PACKAGE = XS::APItest::BoolInternals

UV
test_bool_internals()
    CODE:
    {
        U32 failed = 0;
        SV *true_sv_setsv = newSV(0);
        SV *false_sv_setsv = newSV(0);
        SV *true_sv_set_true = newSV(0);
        SV *false_sv_set_false = newSV(0);
        SV *true_sv_set_bool = newSV(0);
        SV *false_sv_set_bool = newSV(0);
        SV *sviv = newSViv(1);
        SV *svpv = newSVpvs("whatever");
        TEST_EXPR(SvIOK(sviv) && !SvIandPOK(sviv));
        TEST_EXPR(SvPOK(svpv) && !SvIandPOK(svpv));
        TEST_EXPR(SvIOK(sviv) && !SvBoolFlagsOK(sviv));
        TEST_EXPR(SvPOK(svpv) && !SvBoolFlagsOK(svpv));
        sv_setsv(true_sv_setsv, &PL_sv_yes);
        sv_setsv(false_sv_setsv, &PL_sv_no);
        sv_set_true(true_sv_set_true);
        sv_set_false(false_sv_set_false);
        sv_set_bool(true_sv_set_bool, true);
        sv_set_bool(false_sv_set_bool, false);
        /* note that test_bool_internals_macro() SvREFCNT_dec's its arguments
         * after the tests */
        failed += test_bool_internals_macro(newSVsv(&PL_sv_yes), newSVsv(&PL_sv_no));
        failed += test_bool_internals_macro(newSV_true(), newSV_false());
        failed += test_bool_internals_macro(newSVbool(1), newSVbool(0));
        failed += test_bool_internals_macro(true_sv_setsv, false_sv_setsv);
        failed += test_bool_internals_macro(true_sv_set_true, false_sv_set_false);
        failed += test_bool_internals_macro(true_sv_set_bool, false_sv_set_bool);
        SvREFCNT_dec(sviv);
        SvREFCNT_dec(svpv);
        RETVAL = failed;
    }
    OUTPUT:
        RETVAL
