#ifdef USE_ITHREADS

void
clone_with_stack()
CODE:
{
    PerlInterpreter *interp = aTHX; /* The original interpreter */
    PerlInterpreter *interp_dup;    /* The duplicate interpreter */
    int oldscope = 1; /* We are responsible for all scopes */

    /* push a ref-counted and non-RC stackinfo to see how they get cloned */
    push_stackinfo(PERLSI_UNKNOWN, 1);
    push_stackinfo(PERLSI_UNKNOWN, 0);

    interp_dup = perl_clone(interp, CLONEf_COPY_STACKS | CLONEf_CLONE_HOST );

    /* destroy old perl */
    PERL_SET_CONTEXT(interp);

    POPSTACK_TO(PL_mainstack);
    if (cxstack_ix >= 0) {
        dounwind(-1);
        cx_popblock(cxstack);
    }
    LEAVE_SCOPE(0);
    PL_scopestack_ix = oldscope;
    FREETMPS;

    perl_destruct(interp);
    perl_free(interp);

    /* switch to new perl */
    PERL_SET_CONTEXT(interp_dup);

    /* check and pop the stackinfo's pushed above */
#ifdef PERL_RC_STACK
    assert(!AvREAL(PL_curstack));
#endif
    pop_stackinfo();
#ifdef PERL_RC_STACK
    assert(AvREAL(PL_curstack));
#endif
    pop_stackinfo();

    /* continue after 'clone_with_stack' */
    if (interp_dup->Iop)
        interp_dup->Iop = interp_dup->Iop->op_next;

    /* run with new perl */
    CALLRUNOPS(interp_dup);

    /* We may have additional unclosed scopes if fork() was called
     * from within a BEGIN block.  See perlfork.pod for more details.
     * We cannot clean up these other scopes because they belong to a
     * different interpreter, but we also cannot leave PL_scopestack_ix
     * dangling because that can trigger an assertion in perl_destruct().
     */
    if (PL_scopestack_ix > oldscope) {
        PL_scopestack[oldscope-1] = PL_scopestack[PL_scopestack_ix-1];
        PL_scopestack_ix = oldscope;
    }

    /* the COP which PL_curcop points to is about to be freed, but might
     * still be accessed when destructors, END() blocks etc are called.
     * So point it somewhere safe.
     */
    PL_curcop = &PL_compiling;
    perl_destruct(interp_dup);
    perl_free(interp_dup);

    /* call the real 'exit' not PerlProc_exit */
#undef exit
    exit(0);
}

#  ifndef WIN32

bool
thread_id_matches()
CODE:
    /* pthread_t might not be a scalar type */
    RETVAL = pthread_equal(pthread_self(), PL_main_thread);
OUTPUT:
    RETVAL

pthread_t
make_signal_thread()
CODE:
    if (pthread_create(&RETVAL, NULL, signal_thread_start, NULL) != 0)
        XSRETURN_EMPTY;
OUTPUT:
    RETVAL

int
join_signal_thread(pthread_t tid)
CODE:
    RETVAL = pthread_join(tid, NULL);
OUTPUT:
    RETVAL

#  endif /* ifndef WIN32 */

#endif /* USE_ITHREADS */

SV*
take_svref(SVREF sv)
CODE:
    RETVAL = newRV_inc(sv);
OUTPUT:
    RETVAL

SV*
take_avref(AV* av)
CODE:
    RETVAL = newRV_inc((SV*)av);
OUTPUT:
    RETVAL

SV*
take_hvref(HV* hv)
CODE:
    RETVAL = newRV_inc((SV*)hv);
OUTPUT:
    RETVAL


SV*
take_cvref(CV* cv)
CODE:
    RETVAL = newRV_inc((SV*)cv);
OUTPUT:
    RETVAL


BOOT:
        {
        HV* stash;
        SV** meth = NULL;
        CV* cv;
        stash = gv_stashpv("XS::APItest::TempLv", 0);
        if (stash)
            meth = hv_fetchs(stash, "make_temp_mg_lv", 0);
        if (!meth)
            croak("lost method 'make_temp_mg_lv'");
        cv = GvCV(*meth);
        CvLVALUE_on(cv);
        }

BOOT:
{
    hintkey_rpn_sv = newSVpvs_share("XS::APItest/rpn");
    hintkey_calcrpn_sv = newSVpvs_share("XS::APItest/calcrpn");
    hintkey_stufftest_sv = newSVpvs_share("XS::APItest/stufftest");
    hintkey_swaptwostmts_sv = newSVpvs_share("XS::APItest/swaptwostmts");
    hintkey_looprest_sv = newSVpvs_share("XS::APItest/looprest");
    hintkey_scopelessblock_sv = newSVpvs_share("XS::APItest/scopelessblock");
    hintkey_stmtasexpr_sv = newSVpvs_share("XS::APItest/stmtasexpr");
    hintkey_stmtsasexpr_sv = newSVpvs_share("XS::APItest/stmtsasexpr");
    hintkey_loopblock_sv = newSVpvs_share("XS::APItest/loopblock");
    hintkey_blockasexpr_sv = newSVpvs_share("XS::APItest/blockasexpr");
    hintkey_swaplabel_sv = newSVpvs_share("XS::APItest/swaplabel");
    hintkey_labelconst_sv = newSVpvs_share("XS::APItest/labelconst");
    hintkey_arrayfullexpr_sv = newSVpvs_share("XS::APItest/arrayfullexpr");
    hintkey_arraylistexpr_sv = newSVpvs_share("XS::APItest/arraylistexpr");
    hintkey_arraytermexpr_sv = newSVpvs_share("XS::APItest/arraytermexpr");
    hintkey_arrayarithexpr_sv = newSVpvs_share("XS::APItest/arrayarithexpr");
    hintkey_arrayexprflags_sv = newSVpvs_share("XS::APItest/arrayexprflags");
    hintkey_subsignature_sv = newSVpvs_share("XS::APItest/subsignature");
    hintkey_DEFSV_sv = newSVpvs_share("XS::APItest/DEFSV");
    hintkey_with_vars_sv = newSVpvs_share("XS::APItest/with_vars");
    hintkey_join_with_space_sv = newSVpvs_share("XS::APItest/join_with_space");
    wrap_keyword_plugin(my_keyword_plugin, &next_keyword_plugin);
}

void
establish_cleanup(...)
PROTOTYPE: $
CODE:
    PERL_UNUSED_VAR(items);
    croak("establish_cleanup called as a function");

BOOT:
{
    CV *estcv = get_cv("XS::APItest::establish_cleanup", 0);
    cv_set_call_checker(estcv, THX_ck_entersub_establish_cleanup, (SV*)estcv);
}

void
postinc(...)
PROTOTYPE: $
CODE:
    PERL_UNUSED_VAR(items);
    croak("postinc called as a function");

void
filter()
CODE:
    filter_add(filter_call, NULL);

BOOT:
{
    CV *asscv = get_cv("XS::APItest::postinc", 0);
    cv_set_call_checker(asscv, THX_ck_entersub_postinc, (SV*)asscv);
}

SV *
lv_temp_object()
CODE:
    RETVAL =
          sv_bless(
            newRV_noinc(newSV(0)),
            gv_stashpvs("XS::APItest::TempObj",GV_ADD)
          );             /* Package defined in test script */
OUTPUT:
    RETVAL

void
fill_hash_with_nulls(HV *hv)
PREINIT:
    UV i = 0;
CODE:
    for(; i < 1000; ++i) {
        HE *entry = hv_fetch_ent(hv, sv_2mortal(newSVuv(i)), 1, 0);
        SvREFCNT_dec(HeVAL(entry));
        HeVAL(entry) = NULL;
    }

HV *
newHVhv(HV *hv)
CODE:
    RETVAL = newHVhv(hv);
OUTPUT:
    RETVAL

U32
SvIsCOW(SV *sv)
CODE:
    RETVAL = SvIsCOW(sv);
OUTPUT:
    RETVAL

void
pad_scalar(...)
PROTOTYPE: $$
CODE:
    PERL_UNUSED_VAR(items);
    croak("pad_scalar called as a function");

BOOT:
{
    CV *pscv = get_cv("XS::APItest::pad_scalar", 0);
    cv_set_call_checker(pscv, THX_ck_entersub_pad_scalar, (SV*)pscv);
}

SV*
fetch_pad_names( cv )
CV* cv
 PREINIT:
  I32 i;
  PADNAMELIST *pad_namelist;
  AV *retav = newAV();
 CODE:
  pad_namelist = PadlistNAMES(CvPADLIST(cv));

  for ( i = PadnamelistMAX(pad_namelist); i >= 0; i-- ) {
    PADNAME* name = PadnamelistARRAY(pad_namelist)[i];

    if (PadnameLEN(name)) {
        av_push_simple(retav, newSVpadname(name));
    }
  }
  RETVAL = newRV_noinc((SV*)retav);
 OUTPUT:
  RETVAL

STRLEN
underscore_length()
PROTOTYPE:
PREINIT:
    SV *u;
    U8 *pv;
    STRLEN bytelen;
CODE:
    u = find_rundefsv();
    pv = (U8*)SvPV(u, bytelen);
    RETVAL = SvUTF8(u) ? utf8_length(pv, pv+bytelen) : bytelen;
OUTPUT:
    RETVAL

void
stringify(SV *sv)
CODE:
    (void)SvPV_nolen(sv);

SV *
HvENAME(HV *hv)
CODE:
    RETVAL = hv && HvHasENAME(hv)
              ? newSVpvn_flags(
                  HvENAME(hv),HvENAMELEN(hv),
                  (HvENAMEUTF8(hv) ? SVf_UTF8 : 0)
                )
              : NULL;
OUTPUT:
    RETVAL

int
xs_cmp(int a, int b)
CODE:
    /* Odd sorting (odd numbers first), to make sure we are actually
       being called */
    RETVAL = a % 2 != b % 2
               ? a % 2 ? -1 : 1
               : a < b ? -1 : a == b ? 0 : 1;
OUTPUT:
    RETVAL

SV *
xs_cmp_undef(SV *a, SV *b)
CODE:
    PERL_UNUSED_ARG(a);
    PERL_UNUSED_ARG(b);
    RETVAL = &PL_sv_undef;
OUTPUT:
    RETVAL

char *
SvPVbyte(SV *sv, OUT STRLEN len)
CODE:
    RETVAL = SvPVbyte(sv, len);
OUTPUT:
    RETVAL

char *
SvPVbyte_nolen(SV *sv)
CODE:
    RETVAL = SvPVbyte_nolen(sv);
OUTPUT:
    RETVAL

char *
SvPVbyte_nomg(SV *sv, OUT STRLEN len)
CODE:
    RETVAL = SvPVbyte_nomg(sv, len);
OUTPUT:
    RETVAL

char *
SvPVutf8(SV *sv, OUT STRLEN len)
CODE:
    RETVAL = SvPVutf8(sv, len);
OUTPUT:
    RETVAL

char *
SvPVutf8_nolen(SV *sv)
CODE:
    RETVAL = SvPVutf8_nolen(sv);
OUTPUT:
    RETVAL

char *
SvPVutf8_nomg(SV *sv, OUT STRLEN len)
CODE:
    RETVAL = SvPVutf8_nomg(sv, len);
OUTPUT:
    RETVAL

bool
SvIsBOOL(SV *sv)
CODE:
    RETVAL = SvIsBOOL(sv);
OUTPUT:
    RETVAL

void
setup_addissub()
CODE:
    wrap_op_checker(OP_ADD, addissub_myck_add, &addissub_nxck_add);

void
setup_rv2cv_addunderbar()
CODE:
    wrap_op_checker(OP_RV2CV, my_ck_rv2cv, &old_ck_rv2cv);

#ifdef USE_ITHREADS

bool
test_alloccopstash()
CODE:
    RETVAL = PL_stashpad[alloccopstash(PL_defstash)] == PL_defstash;
OUTPUT:
    RETVAL

#endif
