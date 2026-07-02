static XOP my_xop;

static OP *
pp_xop(pTHX)
{
    return PL_op->op_next;
}

static void
peep_xop(pTHX_ OP *o, OP *oldop)
{
    dMY_CXT;
    av_push(MY_CXT.xop_record, newSVpvf("peep:%" UVxf, PTR2UV(o)));
    av_push(MY_CXT.xop_record, newSVpvf("oldop:%" UVxf, PTR2UV(oldop)));
}

static I32
filter_call(pTHX_ int idx, SV *buf_sv, int maxlen)
{
    char *p;
    char *end;
    int n = FILTER_READ(idx + 1, buf_sv, maxlen);

    if (n<=0) return n;

    p = SvPV_force_nolen(buf_sv);
    end = p + SvCUR(buf_sv);
    while (p < end) {
        if (*p == 'o') *p = 'e';
        p++;
    }
    return SvCUR(buf_sv);
}

static AV *
myget_linear_isa(pTHX_ HV *stash, U32 level) {
    GV **gvp = (GV **)hv_fetchs(stash, "ISA", 0);
    PERL_UNUSED_ARG(level);
    return gvp && *gvp && GvAV(*gvp)
         ? GvAV(*gvp)
         : newAV_mortal();
}


XS_EXTERNAL(XS_XS__APItest__XSUB_XS_VERSION_undef);
XS_EXTERNAL(XS_XS__APItest__XSUB_XS_VERSION_empty);
XS_EXTERNAL(XS_XS__APItest__XSUB_XS_APIVERSION_invalid);

static struct mro_alg mymro;

static Perl_check_t addissub_nxck_add;

static OP *
addissub_myck_add(pTHX_ OP *op)
{
    SV **flag_svp = hv_fetchs(GvHV(PL_hintgv), "XS::APItest/addissub", 0);
    OP *aop, *bop;
    U8 flags;
    if (!(flag_svp && SvTRUE(*flag_svp) && (op->op_flags & OPf_KIDS) &&
            (aop = cBINOPx(op)->op_first) && (bop = OpSIBLING(aop)) &&
            !OpHAS_SIBLING(bop)))
        return addissub_nxck_add(aTHX_ op);
    flags = op->op_flags;
    op_sibling_splice(op, NULL, 1, NULL); /* excise aop */
    op_sibling_splice(op, NULL, 1, NULL); /* excise bop */
    op_free(op); /* free the empty husk */
    flags &= ~OPf_KIDS;
    return newBINOP(OP_SUBTRACT, flags, aop, bop);
}

static Perl_check_t old_ck_rv2cv;

static OP *
my_ck_rv2cv(pTHX_ OP *o)
{
    SV *ref;
    SV **flag_svp = hv_fetchs(GvHV(PL_hintgv), "XS::APItest/addunder", 0);
    OP *aop;

    if (flag_svp && SvTRUE(*flag_svp) && (o->op_flags & OPf_KIDS)
     && (aop = cUNOPx(o)->op_first) && aop->op_type == OP_CONST
     && aop->op_private & (OPpCONST_ENTERED|OPpCONST_BARE)
     && (ref = cSVOPx(aop)->op_sv) && SvPOK(ref) && SvCUR(ref)
     && *(SvEND(ref)-1) == 'o')
    {
        SvGROW(ref, SvCUR(ref)+2);
        *SvEND(ref) = '_';
        SvCUR(ref)++; /* Not _set, so we don't accidentally break non-PERL_CORE */
        *SvEND(ref) = '\0';
    }
    return old_ck_rv2cv(aTHX_ o);
}

#define test_bool_internals_macro(true_sv, false_sv) \
    test_bool_internals_func(true_sv, false_sv,\
        #true_sv " and " #false_sv)

U32
test_bool_internals_func(SV *true_sv, SV *false_sv, const char *msg) {
    U32 failed = 0;
    printf("# Testing '%s'\n", msg);
    TEST_EXPR(SvCUR(true_sv) == 1);
    TEST_EXPR(SvCUR(false_sv) == 0);
    TEST_EXPR(SvLEN(true_sv) == 0);
    TEST_EXPR(SvLEN(false_sv) == 0);
    TEST_EXPR(SvIV(true_sv) == 1);
    TEST_EXPR(SvIV(false_sv) == 0);
    TEST_EXPR(SvIsCOW(true_sv));
    TEST_EXPR(SvIsCOW(false_sv));
    TEST_EXPR(strEQ(SvPV_nolen(true_sv),"1"));
    TEST_EXPR(strEQ(SvPV_nolen(false_sv),""));
    TEST_EXPR(SvIOK(true_sv));
    TEST_EXPR(SvIOK(false_sv));
    TEST_EXPR(SvPOK(true_sv));
    TEST_EXPR(SvPOK(false_sv));
    TEST_EXPR(SvBoolFlagsOK(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv));
    TEST_EXPR(SvTYPE(true_sv) >= SVt_PVNV);
    TEST_EXPR(SvTYPE(false_sv) >= SVt_PVNV);
    TEST_EXPR(SvBoolFlagsOK(true_sv) && BOOL_INTERNALS_sv_isbool(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv) && BOOL_INTERNALS_sv_isbool(false_sv));
    TEST_EXPR(SvBoolFlagsOK(true_sv) && BOOL_INTERNALS_sv_isbool_true(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv) && BOOL_INTERNALS_sv_isbool_false(false_sv));
    TEST_EXPR(SvBoolFlagsOK(true_sv) && !BOOL_INTERNALS_sv_isbool_false(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv) && !BOOL_INTERNALS_sv_isbool_true(false_sv));
    TEST_EXPR(SvTRUE(true_sv));
    TEST_EXPR(!SvTRUE(false_sv));
    if (failed) {
        PerlIO_printf(Perl_debug_log, "# '%s' the tested true_sv:\n", msg);
        sv_dump(true_sv);
        PerlIO_printf(Perl_debug_log, "# PL_sv_yes:\n");
        sv_dump(&PL_sv_yes);
        PerlIO_printf(Perl_debug_log, "# '%s' tested false_sv:\n",msg);
        sv_dump(false_sv);
        PerlIO_printf(Perl_debug_log, "# PL_sv_no:\n");
        sv_dump(&PL_sv_no);
    }
    fflush(stdout);
    SvREFCNT_dec(true_sv);
    SvREFCNT_dec(false_sv);
    return failed;
}


/* A simplified/fake replacement for pp_add, which tests the pp
 * function wrapping API, XSPP_wrapped() for a fixed number of args*/

XSPP_wrapped(my_pp_add, 2, 0)
{
    SV *ret;
    dSP;
    SV *r = POPs;
    SV *l = TOPs;
    if (SvROK(l))
        l = SvRV(l);
    if (SvROK(r))
        r = SvRV(r);
    ret = newSViv( SvIV(l) + SvIV(r));
    sv_2mortal(ret);
    SETs(ret);
    RETURN;
}


/* A copy of pp_anonlist, which tests the pp
 * function wrapping API, XSPP_wrapped()  for a list*/

XSPP_wrapped(my_pp_anonlist, 0, 1)
{
    dSP; dMARK;
    const I32 items = SP - MARK;
    SV * const av = MUTABLE_SV(av_make(items, MARK+1));
    SP = MARK;
    mXPUSHs((PL_op->op_flags & OPf_SPECIAL)
            ? newRV_noinc(av) : av);
    RETURN;
}


void
destruct_test(pTHX_ SV *p) {
    warn("In destruct_test: %" SVf "\n", p);
}

#if defined(USE_ITHREADS) && !defined(WIN32)

static void *
signal_thread_start(void *arg) {
  PERL_UNUSED_ARG(arg);
  raise(SIGUSR1);
  return NULL;
}

#endif

#ifdef PERL_USE_HWM
#  define hwm_checks_enabled() true
#else
#  define hwm_checks_enabled() false
#endif
