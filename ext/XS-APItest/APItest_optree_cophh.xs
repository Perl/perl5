void
test_magic_chain()
    PREINIT:
        SV *sv;
        MAGIC *callmg = NULL, *uvarmg = NULL;
    CODE:
        sv = newSV_type_mortal(SVt_NULL);
        if (SvTYPE(sv) >= SVt_PVMG) croak_fail();
        if (SvMAGICAL(sv)) croak_fail();
        sv_magic(sv, &PL_sv_yes, PERL_MAGIC_checkcall, (char*)&callmg, 0);
        if (SvTYPE(sv) < SVt_PVMG) croak_fail();
        if (!SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_uvar)) croak_fail();
        callmg = mg_find(sv, PERL_MAGIC_checkcall);
        if (!callmg) croak_fail();
        if (callmg->mg_obj != &PL_sv_yes || callmg->mg_ptr != (char*)&callmg)
            croak_fail();
        sv_magic(sv, &PL_sv_no, PERL_MAGIC_uvar, (char*)&uvarmg, 0);
        if (SvTYPE(sv) < SVt_PVMG) croak_fail();
        if (!SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_checkcall) != callmg) croak_fail();
        uvarmg = mg_find(sv, PERL_MAGIC_uvar);
        if (!uvarmg) croak_fail();
        if (callmg->mg_obj != &PL_sv_yes || callmg->mg_ptr != (char*)&callmg)
            croak_fail();
        if (uvarmg->mg_obj != &PL_sv_no || uvarmg->mg_ptr != (char*)&uvarmg)
            croak_fail();
        mg_free_type(sv, PERL_MAGIC_vec);
        if (SvTYPE(sv) < SVt_PVMG) croak_fail();
        if (!SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_checkcall) != callmg) croak_fail();
        if (mg_find(sv, PERL_MAGIC_uvar) != uvarmg) croak_fail();
        if (callmg->mg_obj != &PL_sv_yes || callmg->mg_ptr != (char*)&callmg)
            croak_fail();
        if (uvarmg->mg_obj != &PL_sv_no || uvarmg->mg_ptr != (char*)&uvarmg)
            croak_fail();
        mg_free_type(sv, PERL_MAGIC_uvar);
        if (SvTYPE(sv) < SVt_PVMG) croak_fail();
        if (!SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_checkcall) != callmg) croak_fail();
        if (mg_find(sv, PERL_MAGIC_uvar)) croak_fail();
        if (callmg->mg_obj != &PL_sv_yes || callmg->mg_ptr != (char*)&callmg)
            croak_fail();
        sv_magic(sv, &PL_sv_no, PERL_MAGIC_uvar, (char*)&uvarmg, 0);
        if (SvTYPE(sv) < SVt_PVMG) croak_fail();
        if (!SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_checkcall) != callmg) croak_fail();
        uvarmg = mg_find(sv, PERL_MAGIC_uvar);
        if (!uvarmg) croak_fail();
        if (callmg->mg_obj != &PL_sv_yes || callmg->mg_ptr != (char*)&callmg)
            croak_fail();
        if (uvarmg->mg_obj != &PL_sv_no || uvarmg->mg_ptr != (char*)&uvarmg)
            croak_fail();
        mg_free_type(sv, PERL_MAGIC_checkcall);
        if (SvTYPE(sv) < SVt_PVMG) croak_fail();
        if (!SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_uvar) != uvarmg) croak_fail();
        if (mg_find(sv, PERL_MAGIC_checkcall)) croak_fail();
        if (uvarmg->mg_obj != &PL_sv_no || uvarmg->mg_ptr != (char*)&uvarmg)
            croak_fail();
        mg_free_type(sv, PERL_MAGIC_uvar);
        if (SvMAGICAL(sv)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_checkcall)) croak_fail();
        if (mg_find(sv, PERL_MAGIC_uvar)) croak_fail();

void
test_op_contextualize()
    PREINIT:
        OP *o;
    CODE:
        o = newSVOP(OP_CONST, 0, newSViv(0));
        o->op_flags &= ~OPf_WANT;
        o = op_contextualize(o, G_SCALAR);
        if (o->op_type != OP_CONST ||
                (o->op_flags & OPf_WANT) != OPf_WANT_SCALAR)
            croak_fail();
        op_free(o);
        o = newSVOP(OP_CONST, 0, newSViv(0));
        o->op_flags &= ~OPf_WANT;
        o = op_contextualize(o, G_LIST);
        if (o->op_type != OP_CONST ||
                (o->op_flags & OPf_WANT) != OPf_WANT_LIST)
            croak_fail();
        op_free(o);
        o = newSVOP(OP_CONST, 0, newSViv(0));
        o->op_flags &= ~OPf_WANT;
        o = op_contextualize(o, G_VOID);
        if (o->op_type != OP_NULL) croak_fail();
        op_free(o);

void
test_rv2cv_op_cv()
    PROTOTYPE:
    PREINIT:
        GV *troc_gv;
        CV *troc_cv;
        OP *o;
    CODE:
        troc_gv = gv_fetchpv("XS::APItest::test_rv2cv_op_cv", 0, SVt_PVGV);
        troc_cv = get_cv("XS::APItest::test_rv2cv_op_cv", 0);
        o = newCVREF(0, newGVOP(OP_GV, 0, troc_gv));
        if (rv2cv_op_cv(o, 0) != troc_cv) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV) != (CV*)troc_gv)
            croak_fail();
        o->op_private |= OPpENTERSUB_AMPER;
        if (rv2cv_op_cv(o, 0)) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
        o->op_private &= ~OPpENTERSUB_AMPER;
        if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY) != troc_cv) croak_fail();
        if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
        op_free(o);
        o = newSVOP(OP_CONST, 0, newSVpv("XS::APItest::test_rv2cv_op_cv", 0));
        o->op_private = OPpCONST_BARE;
        o = newCVREF(0, o);
        if (rv2cv_op_cv(o, 0) != troc_cv) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV) != (CV*)troc_gv)
            croak_fail();
        o->op_private |= OPpENTERSUB_AMPER;
        if (rv2cv_op_cv(o, 0)) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
        op_free(o);
        o = newCVREF(0, newSVOP(OP_CONST, 0, newRV_inc((SV*)troc_cv)));
        if (rv2cv_op_cv(o, 0) != troc_cv) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV) != (CV*)troc_gv)
            croak_fail();
        o->op_private |= OPpENTERSUB_AMPER;
        if (rv2cv_op_cv(o, 0)) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
        o->op_private &= ~OPpENTERSUB_AMPER;
        if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY) != troc_cv) croak_fail();
        if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
        op_free(o);
        o = newCVREF(0, newUNOP(OP_RAND, 0, newSVOP(OP_CONST, 0, newSViv(0))));
        if (rv2cv_op_cv(o, 0)) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
        o->op_private |= OPpENTERSUB_AMPER;
        if (rv2cv_op_cv(o, 0)) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
        o->op_private &= ~OPpENTERSUB_AMPER;
        if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY)) croak_fail();
        if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
        op_free(o);
        o = newUNOP(OP_RAND, 0, newSVOP(OP_CONST, 0, newSViv(0)));
        if (rv2cv_op_cv(o, 0)) croak_fail();
        if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
        op_free(o);

void
test_cv_getset_call_checker()
    PREINIT:
        CV *troc_cv, *tsh_cv;
        Perl_call_checker ckfun;
        SV *ckobj;
        U32 ckflags;
    CODE:
#define check_cc(cv, xckfun, xckobj, xckflags) \
    do { \
        cv_get_call_checker((cv), &ckfun, &ckobj); \
        if (ckfun != (xckfun)) croak_fail_nep(FPTR2DPTR(void *, ckfun), xckfun); \
        if (ckobj != (xckobj)) croak_fail_nep(FPTR2DPTR(void *, ckobj), xckobj); \
        cv_get_call_checker_flags((cv), CALL_CHECKER_REQUIRE_GV, &ckfun, &ckobj, &ckflags); \
        if (ckfun != (xckfun)) croak_fail_nep(FPTR2DPTR(void *, ckfun), xckfun); \
        if (ckobj != (xckobj)) croak_fail_nep(FPTR2DPTR(void *, ckobj), xckobj); \
        if (ckflags != CALL_CHECKER_REQUIRE_GV) croak_fail_nei(ckflags, CALL_CHECKER_REQUIRE_GV); \
        cv_get_call_checker_flags((cv), 0, &ckfun, &ckobj, &ckflags); \
        if (ckfun != (xckfun)) croak_fail_nep(FPTR2DPTR(void *, ckfun), xckfun); \
        if (ckobj != (xckobj)) croak_fail_nep(FPTR2DPTR(void *, ckobj), xckobj); \
        if (ckflags != (xckflags)) croak_fail_nei(ckflags, (xckflags)); \
    } while(0)
        troc_cv = get_cv("XS::APItest::test_rv2cv_op_cv", 0);
        tsh_cv = get_cv("XS::APItest::test_savehints", 0);
        check_cc(troc_cv, Perl_ck_entersub_args_proto_or_list, (SV*)troc_cv, 0);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, (SV*)tsh_cv, 0);
        cv_set_call_checker(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    &PL_sv_yes);
        check_cc(troc_cv, Perl_ck_entersub_args_proto_or_list, (SV*)troc_cv, 0);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes, CALL_CHECKER_REQUIRE_GV);
        cv_set_call_checker(troc_cv, THX_ck_entersub_args_scalars, &PL_sv_no);
        check_cc(troc_cv, THX_ck_entersub_args_scalars, &PL_sv_no, CALL_CHECKER_REQUIRE_GV);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes, CALL_CHECKER_REQUIRE_GV);
        cv_set_call_checker(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    (SV*)tsh_cv);
        check_cc(troc_cv, THX_ck_entersub_args_scalars, &PL_sv_no, CALL_CHECKER_REQUIRE_GV);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, (SV*)tsh_cv, 0);
        cv_set_call_checker(troc_cv, Perl_ck_entersub_args_proto_or_list,
                                    (SV*)troc_cv);
        check_cc(troc_cv, Perl_ck_entersub_args_proto_or_list, (SV*)troc_cv, 0);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, (SV*)tsh_cv, 0);
        if (SvMAGICAL((SV*)troc_cv) || SvMAGIC((SV*)troc_cv)) croak_fail();
        if (SvMAGICAL((SV*)tsh_cv) || SvMAGIC((SV*)tsh_cv)) croak_fail();
        cv_set_call_checker_flags(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    &PL_sv_yes, 0);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes, 0);
        cv_set_call_checker_flags(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    &PL_sv_yes, CALL_CHECKER_REQUIRE_GV);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes, CALL_CHECKER_REQUIRE_GV);
        cv_set_call_checker_flags(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    (SV*)tsh_cv, 0);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, (SV*)tsh_cv, 0);
        if (SvMAGICAL((SV*)tsh_cv) || SvMAGIC((SV*)tsh_cv)) croak_fail();
        cv_set_call_checker_flags(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    &PL_sv_yes, CALL_CHECKER_REQUIRE_GV);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes, CALL_CHECKER_REQUIRE_GV);
        cv_set_call_checker_flags(tsh_cv, Perl_ck_entersub_args_proto_or_list,
                                    (SV*)tsh_cv, CALL_CHECKER_REQUIRE_GV);
        check_cc(tsh_cv, Perl_ck_entersub_args_proto_or_list, (SV*)tsh_cv, 0);
        if (SvMAGICAL((SV*)tsh_cv) || SvMAGIC((SV*)tsh_cv)) croak_fail();
#undef check_cc

void
cv_set_call_checker_lists(CV *cv)
    CODE:
        cv_set_call_checker(cv, THX_ck_entersub_args_lists, &PL_sv_undef);

void
cv_set_call_checker_scalars(CV *cv)
    CODE:
        cv_set_call_checker(cv, THX_ck_entersub_args_scalars, &PL_sv_undef);

void
cv_set_call_checker_proto(CV *cv, SV *proto)
    CODE:
        if (SvROK(proto))
            proto = SvRV(proto);
        cv_set_call_checker(cv, Perl_ck_entersub_args_proto, proto);

void
cv_set_call_checker_proto_or_list(CV *cv, SV *proto)
    CODE:
        if (SvROK(proto))
            proto = SvRV(proto);
        cv_set_call_checker(cv, Perl_ck_entersub_args_proto_or_list, proto);

void
cv_set_call_checker_multi_sum(CV *cv)
    CODE:
        cv_set_call_checker(cv, THX_ck_entersub_multi_sum, &PL_sv_undef);

void
test_cophh()
    PREINIT:
        COPHH *a, *b;
#ifdef EBCDIC
        SV* key_sv;
        char * key_name;
        STRLEN key_len;
#endif
    CODE:
#define check_ph(EXPR) \
            do { if((EXPR) != &PL_sv_placeholder) croak("fail"); } while(0)
#define check_iv(EXPR, EXPECT) \
            do { if(SvIV(EXPR) != (EXPECT)) croak("fail"); } while(0)
#define msvpvs(STR) sv_2mortal(newSVpvs(STR))
#define msviv(VALUE) sv_2mortal(newSViv(VALUE))
        a = cophh_new_empty();
        check_ph(cophh_fetch_pvn(a, "foo_1", 5, 0, 0));
        check_ph(cophh_fetch_pvs(a, "foo_1", 0));
        check_ph(cophh_fetch_pv(a, "foo_1", 0, 0));
        check_ph(cophh_fetch_sv(a, msvpvs("foo_1"), 0, 0));
        a = cophh_store_pvn(a, "foo_1abc", 5, 0, msviv(111), 0);
        a = cophh_store_pvs(a, "foo_2", msviv(222), 0);
        a = cophh_store_pv(a, "foo_3", 0, msviv(333), 0);
        a = cophh_store_sv(a, msvpvs("foo_4"), 0, msviv(444), 0);
        check_iv(cophh_fetch_pvn(a, "foo_1xyz", 5, 0, 0), 111);
        check_iv(cophh_fetch_pvs(a, "foo_1", 0), 111);
        check_iv(cophh_fetch_pv(a, "foo_1", 0, 0), 111);
        check_iv(cophh_fetch_sv(a, msvpvs("foo_1"), 0, 0), 111);
        check_iv(cophh_fetch_pvs(a, "foo_2", 0), 222);
        check_iv(cophh_fetch_pvs(a, "foo_3", 0), 333);
        check_iv(cophh_fetch_pvs(a, "foo_4", 0), 444);
        check_ph(cophh_fetch_pvs(a, "foo_5", 0));
        b = cophh_copy(a);
        b = cophh_store_pvs(b, "foo_1", msviv(1111), 0);
        check_iv(cophh_fetch_pvs(a, "foo_1", 0), 111);
        check_iv(cophh_fetch_pvs(a, "foo_2", 0), 222);
        check_iv(cophh_fetch_pvs(a, "foo_3", 0), 333);
        check_iv(cophh_fetch_pvs(a, "foo_4", 0), 444);
        check_ph(cophh_fetch_pvs(a, "foo_5", 0));
        check_iv(cophh_fetch_pvs(b, "foo_1", 0), 1111);
        check_iv(cophh_fetch_pvs(b, "foo_2", 0), 222);
        check_iv(cophh_fetch_pvs(b, "foo_3", 0), 333);
        check_iv(cophh_fetch_pvs(b, "foo_4", 0), 444);
        check_ph(cophh_fetch_pvs(b, "foo_5", 0));
        a = cophh_delete_pvn(a, "foo_1abc", 5, 0, 0);
        a = cophh_delete_pvs(a, "foo_2", 0);
        b = cophh_delete_pv(b, "foo_3", 0, 0);
        b = cophh_delete_sv(b, msvpvs("foo_4"), 0, 0);
        check_ph(cophh_fetch_pvs(a, "foo_1", 0));
        check_ph(cophh_fetch_pvs(a, "foo_2", 0));
        check_iv(cophh_fetch_pvs(a, "foo_3", 0), 333);
        check_iv(cophh_fetch_pvs(a, "foo_4", 0), 444);
        check_ph(cophh_fetch_pvs(a, "foo_5", 0));
        check_iv(cophh_fetch_pvs(b, "foo_1", 0), 1111);
        check_iv(cophh_fetch_pvs(b, "foo_2", 0), 222);
        check_ph(cophh_fetch_pvs(b, "foo_3", 0));
        check_ph(cophh_fetch_pvs(b, "foo_4", 0));
        check_ph(cophh_fetch_pvs(b, "foo_5", 0));
        b = cophh_delete_pvs(b, "foo_3", 0);
        b = cophh_delete_pvs(b, "foo_5", 0);
        check_iv(cophh_fetch_pvs(b, "foo_1", 0), 1111);
        check_iv(cophh_fetch_pvs(b, "foo_2", 0), 222);
        check_ph(cophh_fetch_pvs(b, "foo_3", 0));
        check_ph(cophh_fetch_pvs(b, "foo_4", 0));
        check_ph(cophh_fetch_pvs(b, "foo_5", 0));
        cophh_free(b);
        check_ph(cophh_fetch_pvs(a, "foo_1", 0));
        check_ph(cophh_fetch_pvs(a, "foo_2", 0));
        check_iv(cophh_fetch_pvs(a, "foo_3", 0), 333);
        check_iv(cophh_fetch_pvs(a, "foo_4", 0), 444);
        check_ph(cophh_fetch_pvs(a, "foo_5", 0));
        a = cophh_store_pvs(a, "foo_1", msviv(11111), COPHH_KEY_UTF8);
        a = cophh_store_pvs(a, "foo_\xaa", msviv(123), 0);
#ifndef EBCDIC
        a = cophh_store_pvs(a, "foo_\xc2\xbb", msviv(456), COPHH_KEY_UTF8);
#else
        /* On EBCDIC, we need to translate the UTF-8 in the ASCII test to the
         * equivalent UTF-EBCDIC for the code page.  This is done at runtime
         * (with the helper function in this file).  Therefore we can't use
         * cophhh_store_pvs(), as we don't have literal string */
        key_sv = sv_2mortal(newSVpvs("foo_"));
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc2\xbb"));
        key_name = SvPV(key_sv, key_len);
        a = cophh_store_pvn(a, key_name, key_len, 0, msviv(456), COPHH_KEY_UTF8);
#endif
#ifndef EBCDIC
        a = cophh_store_pvs(a, "foo_\xc3\x8c", msviv(789), COPHH_KEY_UTF8);
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc3\x8c"));
        key_name = SvPV(key_sv, key_len);
        a = cophh_store_pvn(a, key_name, key_len, 0, msviv(789), COPHH_KEY_UTF8);
#endif
#ifndef EBCDIC
        a = cophh_store_pvs(a, "foo_\xd9\xa6", msviv(666), COPHH_KEY_UTF8);
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xd9\xa6"));
        key_name = SvPV(key_sv, key_len);
        a = cophh_store_pvn(a, key_name, key_len, 0, msviv(666), COPHH_KEY_UTF8);
#endif
        check_iv(cophh_fetch_pvs(a, "foo_1", 0), 11111);
        check_iv(cophh_fetch_pvs(a, "foo_1", COPHH_KEY_UTF8), 11111);
        check_iv(cophh_fetch_pvs(a, "foo_\xaa", 0), 123);
#ifndef EBCDIC
        check_iv(cophh_fetch_pvs(a, "foo_\xc2\xaa", COPHH_KEY_UTF8), 123);
        check_ph(cophh_fetch_pvs(a, "foo_\xc2\xaa", 0));
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc2\xaa"));
        key_name = SvPV(key_sv, key_len);
        check_iv(cophh_fetch_pvn(a, key_name, key_len, 0, COPHH_KEY_UTF8), 123);
        check_ph(cophh_fetch_pvn(a, key_name, key_len, 0, 0));
#endif
        check_iv(cophh_fetch_pvs(a, "foo_\xbb", 0), 456);
#ifndef EBCDIC
        check_iv(cophh_fetch_pvs(a, "foo_\xc2\xbb", COPHH_KEY_UTF8), 456);
        check_ph(cophh_fetch_pvs(a, "foo_\xc2\xbb", 0));
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc2\xbb"));
        key_name = SvPV(key_sv, key_len);
        check_iv(cophh_fetch_pvn(a, key_name, key_len, 0, COPHH_KEY_UTF8), 456);
        check_ph(cophh_fetch_pvn(a, key_name, key_len, 0, 0));
#endif
        check_iv(cophh_fetch_pvs(a, "foo_\xcc", 0), 789);
#ifndef EBCDIC
        check_iv(cophh_fetch_pvs(a, "foo_\xc3\x8c", COPHH_KEY_UTF8), 789);
        check_ph(cophh_fetch_pvs(a, "foo_\xc2\x8c", 0));
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc3\x8c"));
        key_name = SvPV(key_sv, key_len);
        check_iv(cophh_fetch_pvn(a, key_name, key_len, 0, COPHH_KEY_UTF8), 789);
        check_ph(cophh_fetch_pvn(a, key_name, key_len, 0, 0));
#endif
#ifndef EBCDIC
        check_iv(cophh_fetch_pvs(a, "foo_\xd9\xa6", COPHH_KEY_UTF8), 666);
        check_ph(cophh_fetch_pvs(a, "foo_\xd9\xa6", 0));
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xd9\xa6"));
        key_name = SvPV(key_sv, key_len);
        check_iv(cophh_fetch_pvn(a, key_name, key_len, 0, COPHH_KEY_UTF8), 666);
        check_ph(cophh_fetch_pvn(a, key_name, key_len, 0, 0));
#endif
        ENTER;
        SAVEFREECOPHH(a);
        LEAVE;
#undef check_ph
#undef check_iv
#undef msvpvs
#undef msviv

void
test_coplabel()
    PREINIT:
        COP *cop;
        const char *label;
        STRLEN len;
        U32 utf8;
    CODE:
        cop = &PL_compiling;
        Perl_cop_store_label(aTHX_ cop, "foo", 3, 0);
        label = Perl_cop_fetch_label(aTHX_ cop, &len, &utf8);
        if (strNE(label,"foo")) croak("fail # cop_fetch_label label");
        if (len != 3) croak("fail # cop_fetch_label len");
        if (utf8) croak("fail # cop_fetch_label utf8");
        /* SMALL GERMAN UMLAUT A */
        Perl_cop_store_label(aTHX_ cop, "fo\xc3\xa4", 4, SVf_UTF8);
        label = Perl_cop_fetch_label(aTHX_ cop, &len, &utf8);
        if (strNE(label,"fo\xc3\xa4")) croak("fail # cop_fetch_label label");
        if (len != 4) croak("fail # cop_fetch_label len");
        if (!utf8) croak("fail # cop_fetch_label utf8");

void
test_cop_warnings(bool already_on)
    PREINIT:
        COP *cop = PL_curcop;
    CODE:
        if(cop_has_warning(cop, WARN_UNINITIALIZED) ^ already_on)
            croak("fail # cop_has_warning initial state");

        /* This code modfies PL_curcop which is normally quite rude, but we'll
         * allow it during the test run.
         */
        cop_enable_warning(cop, WARN_UNINITIALIZED);
        if (!cop_has_warning(cop, WARN_UNINITIALIZED))
            croak("fail # cop_enable_warning did not enable");

        cop_disable_warning(cop, WARN_UNINITIALIZED);
        if (cop_has_warning(cop, WARN_UNINITIALIZED))
            croak("fail # cop_disable_warning did not disable");


HV *
example_cophh_2hv()
    PREINIT:
        COPHH *a;
#ifdef EBCDIC
        SV* key_sv;
        char * key_name;
        STRLEN key_len;
#endif
    CODE:
#define msviv(VALUE) sv_2mortal(newSViv(VALUE))
        a = cophh_new_empty();
        a = cophh_store_pvs(a, "foo_0", msviv(999), 0);
        a = cophh_store_pvs(a, "foo_1", msviv(111), 0);
        a = cophh_store_pvs(a, "foo_\xaa", msviv(123), 0);
#ifndef EBCDIC
        a = cophh_store_pvs(a, "foo_\xc2\xbb", msviv(456), COPHH_KEY_UTF8);
#else
        key_sv = sv_2mortal(newSVpvs("foo_"));
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc2\xbb"));
        key_name = SvPV(key_sv, key_len);
        a = cophh_store_pvn(a, key_name, key_len, 0, msviv(456), COPHH_KEY_UTF8);
#endif
#ifndef EBCDIC
        a = cophh_store_pvs(a, "foo_\xc3\x8c", msviv(789), COPHH_KEY_UTF8);
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xc3\x8c"));
        key_name = SvPV(key_sv, key_len);
        a = cophh_store_pvn(a, key_name, key_len, 0, msviv(789), COPHH_KEY_UTF8);
#endif
#ifndef EBCDIC
        a = cophh_store_pvs(a, "foo_\xd9\xa6", msviv(666), COPHH_KEY_UTF8);
#else
        sv_setpvs(key_sv, "foo_");
        cat_utf8a2n(key_sv, STR_WITH_LEN("\xd9\xa6"));
        key_name = SvPV(key_sv, key_len);
        a = cophh_store_pvn(a, key_name, key_len, 0, msviv(666), COPHH_KEY_UTF8);
#endif
        a = cophh_delete_pvs(a, "foo_0", 0);
        a = cophh_delete_pvs(a, "foo_2", 0);
        RETVAL = cophh_2hv(a, 0);
        cophh_free(a);
#undef msviv
    OUTPUT:
        RETVAL

void
test_savehints()
    PREINIT:
        SV **svp, *sv;
    CODE:
#define store_hint(KEY, VALUE) \
                sv_setiv_mg(*hv_fetchs(GvHV(PL_hintgv), KEY, 1), (VALUE))
#define hint_ok(KEY, EXPECT) \
                ((svp = hv_fetchs(GvHV(PL_hintgv), KEY, 0)) && \
                    (sv = *svp) && SvIV(sv) == (EXPECT) && \
                    (sv = cop_hints_fetch_pvs(&PL_compiling, KEY, 0)) && \
                    SvIV(sv) == (EXPECT))
#define check_hint(KEY, EXPECT) \
                do { if (!hint_ok(KEY, EXPECT)) croak_fail(); } while(0)
        PL_hints |= HINT_LOCALIZE_HH;
        ENTER;
        SAVEHINTS();
        PL_hints &= HINT_INTEGER;
        store_hint("t0", 123);
        store_hint("t1", 456);
        if (PL_hints & HINT_INTEGER) croak_fail();
        check_hint("t0", 123); check_hint("t1", 456);
        ENTER;
        SAVEHINTS();
        if (PL_hints & HINT_INTEGER) croak_fail();
        check_hint("t0", 123); check_hint("t1", 456);
        PL_hints |= HINT_INTEGER;
        store_hint("t0", 321);
        if (!(PL_hints & HINT_INTEGER)) croak_fail();
        check_hint("t0", 321); check_hint("t1", 456);
        LEAVE;
        if (PL_hints & HINT_INTEGER) croak_fail();
        check_hint("t0", 123); check_hint("t1", 456);
        ENTER;
        SAVEHINTS();
        if (PL_hints & HINT_INTEGER) croak_fail();
        check_hint("t0", 123); check_hint("t1", 456);
        store_hint("t1", 654);
        if (PL_hints & HINT_INTEGER) croak_fail();
        check_hint("t0", 123); check_hint("t1", 654);
        LEAVE;
        if (PL_hints & HINT_INTEGER) croak_fail();
        check_hint("t0", 123); check_hint("t1", 456);
        LEAVE;
#undef store_hint
#undef hint_ok
#undef check_hint

void
test_copyhints()
    PREINIT:
        HV *a, *b;
    CODE:
        PL_hints |= HINT_LOCALIZE_HH;
        ENTER;
        SAVEHINTS();
        sv_setiv_mg(*hv_fetchs(GvHV(PL_hintgv), "t0", 1), 123);
        if (SvIV(cop_hints_fetch_pvs(&PL_compiling, "t0", 0)) != 123)
            croak_fail();
        a = newHVhv(GvHV(PL_hintgv));
        sv_2mortal((SV*)a);
        sv_setiv_mg(*hv_fetchs(a, "t0", 1), 456);
        if (SvIV(cop_hints_fetch_pvs(&PL_compiling, "t0", 0)) != 123)
            croak_fail();
        b = hv_copy_hints_hv(a);
        sv_2mortal((SV*)b);
        sv_setiv_mg(*hv_fetchs(b, "t0", 1), 789);
        if (SvIV(cop_hints_fetch_pvs(&PL_compiling, "t0", 0)) != 789)
            croak_fail();
        LEAVE;
