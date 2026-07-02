MODULE = XS::APItest            PACKAGE = XS::APItest

PROTOTYPES: DISABLE

BOOT:
    mymro.resolve = myget_linear_isa;
    mymro.name    = "justisa";
    mymro.length  = 7;
    mymro.kflags  = 0;
    mymro.hash    = 0;
    Perl_mro_register(aTHX_ &mymro);

HV *
xop_custom_ops ()
    CODE:
        RETVAL = PL_custom_ops;
    OUTPUT:
        RETVAL

HV *
xop_custom_op_names ()
    CODE:
        PL_custom_op_names = newHV();
        RETVAL = PL_custom_op_names;
    OUTPUT:
        RETVAL

HV *
xop_custom_op_descs ()
    CODE:
        PL_custom_op_descs = newHV();
        RETVAL = PL_custom_op_descs;
    OUTPUT:
        RETVAL

void
xop_register ()
    CODE:
        XopENTRY_set(&my_xop, xop_name, "my_xop");
        XopENTRY_set(&my_xop, xop_desc, "XOP for testing");
        XopENTRY_set(&my_xop, xop_class, OA_UNOP);
        XopENTRY_set(&my_xop, xop_peep, peep_xop);
        Perl_custom_op_register(aTHX_ pp_xop, &my_xop);

void
xop_clear ()
    CODE:
        XopDISABLE(&my_xop, xop_name);
        XopDISABLE(&my_xop, xop_desc);
        XopDISABLE(&my_xop, xop_class);
        XopDISABLE(&my_xop, xop_peep);

IV
xop_my_xop ()
    CODE:
        RETVAL = PTR2IV(&my_xop);
    OUTPUT:
        RETVAL

IV
xop_ppaddr ()
    CODE:
        RETVAL = PTR2IV(pp_xop);
    OUTPUT:
        RETVAL

IV
xop_OA_UNOP ()
    CODE:
        RETVAL = OA_UNOP;
    OUTPUT:
        RETVAL

AV *
xop_build_optree ()
    CODE:
        dMY_CXT;
        UNOP *unop;
        OP *kid;

        MY_CXT.xop_record = newAV_alloc_x(5);

        kid = newSVOP(OP_CONST, 0, newSViv(42));

        unop = (UNOP*)mkUNOP(OP_CUSTOM, kid);
        unop->op_ppaddr     = pp_xop;
        unop->op_private    = 0;
        unop->op_next       = NULL;
        kid->op_next        = (OP*)unop;

        av_push_simple(MY_CXT.xop_record, newSVpvf("unop:%" UVxf, PTR2UV(unop)));
        av_push_simple(MY_CXT.xop_record, newSVpvf("kid:%" UVxf, PTR2UV(kid)));

        av_push_simple(MY_CXT.xop_record, newSVpvf("NAME:%s", OP_NAME((OP*)unop)));
        av_push_simple(MY_CXT.xop_record, newSVpvf("DESC:%s", OP_DESC((OP*)unop)));
        av_push_simple(MY_CXT.xop_record, newSVpvf("CLASS:%d", (int)OP_CLASS((OP*)unop)));

        PL_rpeepp(aTHX_ kid);

        FreeOp(kid);
        FreeOp(unop);

        RETVAL = MY_CXT.xop_record;
        MY_CXT.xop_record = NULL;
    OUTPUT:
        RETVAL

IV
xop_from_custom_op ()
    CODE:
/* author note: this test doesn't imply Perl_custom_op_xop is or isn't public
   API or that Perl_custom_op_xop is known to be used outside the core */
        UNOP *unop;
        XOP *xop;

        unop = (UNOP*)mkUNOP(OP_CUSTOM, NULL);
        unop->op_ppaddr     = pp_xop;
        unop->op_private    = 0;
        unop->op_next       = NULL;

        xop = Perl_custom_op_xop(aTHX_ (OP *)unop);
        FreeOp(unop);
        RETVAL = PTR2IV(xop);
    OUTPUT:
        RETVAL

BOOT:
{
    MY_CXT_INIT;

    MY_CXT.i  = 99;
    MY_CXT.sv = newSVpv("initial",0);

    MY_CXT.bhkav = get_av("XS::APItest::bhkav", GV_ADDMULTI);
    MY_CXT.bhk_record = 0;

    BhkENTRY_set(&bhk_test, bhk_start, blockhook_test_start);
    BhkENTRY_set(&bhk_test, bhk_pre_end, blockhook_test_pre_end);
    BhkENTRY_set(&bhk_test, bhk_post_end, blockhook_test_post_end);
    BhkENTRY_set(&bhk_test, bhk_eval, blockhook_test_eval);
    Perl_blockhook_register(aTHX_ &bhk_test);

    MY_CXT.cscgv = gv_fetchpvs("XS::APItest::COMPILE_SCOPE_CONTAINER",
        GV_ADDMULTI, SVt_PVAV);
    MY_CXT.cscav = GvAV(MY_CXT.cscgv);

    BhkENTRY_set(&bhk_csc, bhk_start, blockhook_csc_start);
    BhkENTRY_set(&bhk_csc, bhk_pre_end, blockhook_csc_pre_end);
    Perl_blockhook_register(aTHX_ &bhk_csc);

    MY_CXT.peep_recorder = newAV();
    MY_CXT.rpeep_recorder = newAV();

    MY_CXT.orig_peep = PL_peepp;
    MY_CXT.orig_rpeep = PL_rpeepp;
    PL_peepp = my_peep;
    PL_rpeepp = my_rpeep;
}

void
CLONE(...)
    CODE:
    MY_CXT_CLONE;
    PERL_UNUSED_VAR(items);
    MY_CXT.sv = newSVpv("initial_clone",0);
    MY_CXT.cscgv = gv_fetchpvs("XS::APItest::COMPILE_SCOPE_CONTAINER",
        GV_ADDMULTI, SVt_PVAV);
    MY_CXT.cscav = NULL;
    MY_CXT.bhkav = get_av("XS::APItest::bhkav", GV_ADDMULTI);
    MY_CXT.bhk_record = 0;
    MY_CXT.peep_recorder = newAV();
    MY_CXT.rpeep_recorder = newAV();
