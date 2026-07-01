int
apitest_exception(throw_e)
    int throw_e
    OUTPUT:
        RETVAL

void
mycroak(sv)
    SV* sv
    CODE:
    if (SvOK(sv)) {
        Perl_croak(aTHX_ "%s", SvPV_nolen(sv));
    }
    else {
        Perl_croak(aTHX_ NULL);
    }

SV*
strtab()
   CODE:
   RETVAL = newRV_inc((SV*)PL_strtab);
   OUTPUT:
   RETVAL

int
my_cxt_getint()
    CODE:
        dMY_CXT;
        RETVAL = my_cxt_getint_p(aMY_CXT);
    OUTPUT:
        RETVAL

void
my_cxt_setint(i)
    int i;
    CODE:
        dMY_CXT;
        my_cxt_setint_p(aMY_CXT_ i);

void
my_cxt_getsv(how)
    bool how;
    PPCODE:
        EXTEND(SP, 1);
        ST(0) = how ? my_cxt_getsv_interp_context() : my_cxt_getsv_interp();
        XSRETURN(1);

void
my_cxt_setsv(sv)
    SV *sv;
    CODE:
        dMY_CXT;
        SvREFCNT_dec(MY_CXT.sv);
        my_cxt_setsv_p(sv _aMY_CXT);
        SvREFCNT_inc(sv);

bool
sv_setsv_cow_hashkey_core()

bool
sv_setsv_cow_hashkey_notcore()

void
sv_set_deref(SV *sv, SV *sv2, int which)
    CODE:
    {
        STRLEN len;
        const char *pv = SvPV(sv2,len);
        if (!SvROK(sv)) croak("Not a ref");
        sv = SvRV(sv);
        switch (which) {
            case 0: sv_setsv(sv,sv2); break;
            case 1: sv_setpv(sv,pv); break;
            case 2: sv_setpvn(sv,pv,len); break;
        }
    }

void
rmagical_cast(sv, type)
    SV *sv;
    SV *type;
    PREINIT:
        struct ufuncs uf;
    PPCODE:
        if (!SvOK(sv) || !SvROK(sv) || !SvOK(type)) { XSRETURN_UNDEF; }
        sv = SvRV(sv);
        if (SvTYPE(sv) != SVt_PVHV) { XSRETURN_UNDEF; }
        uf.uf_val = rmagical_a_dummy;
        uf.uf_set = NULL;
        uf.uf_index = 0;
        if (SvTRUE(type)) { /* b */
            sv_magicext(sv, NULL, PERL_MAGIC_ext, &rmagical_b, NULL, 0);
        } else { /* a */
            sv_magic(sv, NULL, PERL_MAGIC_uvar, (char *) &uf, sizeof(uf));
        }
        XSRETURN_YES;

void
rmagical_flags(sv)
    SV *sv;
    PPCODE:
        if (!SvOK(sv) || !SvROK(sv)) { XSRETURN_UNDEF; }
        sv = SvRV(sv);
        EXTEND(SP, 3);
        mXPUSHu(SvFLAGS(sv) & SVs_GMG);
        mXPUSHu(SvFLAGS(sv) & SVs_SMG);
        mXPUSHu(SvFLAGS(sv) & SVs_RMG);
        XSRETURN(3);

void
my_caller(level)
        I32 level
    PREINIT:
        const PERL_CONTEXT *cx, *dbcx;
        const char *pv;
        const GV *gv;
        HV *hv;
    PPCODE:
        cx = caller_cx(level, &dbcx);
        EXTEND(SP, 8);

        pv = CopSTASHPV(cx->blk_oldcop);
        ST(0) = pv ? sv_2mortal(newSVpv(pv, 0)) : &PL_sv_undef;
        gv = CvGV(cx->blk_sub.cv);
        ST(1) = isGV(gv) ? sv_2mortal(newSVpv(GvNAME(gv), 0)) : &PL_sv_undef;

        pv = CopSTASHPV(dbcx->blk_oldcop);
        ST(2) = pv ? sv_2mortal(newSVpv(pv, 0)) : &PL_sv_undef;
        gv = CvGV(dbcx->blk_sub.cv);
        ST(3) = isGV(gv) ? sv_2mortal(newSVpv(GvNAME(gv), 0)) : &PL_sv_undef;

        ST(4) = cop_hints_fetch_pvs(cx->blk_oldcop, "foo", 0);
        ST(5) = cop_hints_fetch_pvn(cx->blk_oldcop, "foo", 3, 0, 0);
        ST(6) = cop_hints_fetch_sv(cx->blk_oldcop,
                sv_2mortal(newSVpvs("foo")), 0, 0);

        hv = cop_hints_2hv(cx->blk_oldcop, 0);
        ST(7) = hv ? sv_2mortal(newRV_noinc((SV *)hv)) : &PL_sv_undef;

        XSRETURN(8);

void
DPeek (sv)
    SV   *sv

  PPCODE:
    ST (0) = newSVpv (Perl_sv_peek (aTHX_ sv), 0);
    XSRETURN (1);

void
BEGIN()
    CODE:
        sv_inc(get_sv("XS::APItest::BEGIN_called", GV_ADD|GV_ADDMULTI));

void
CHECK()
    CODE:
        sv_inc(get_sv("XS::APItest::CHECK_called", GV_ADD|GV_ADDMULTI));

void
UNITCHECK()
    CODE:
        sv_inc(get_sv("XS::APItest::UNITCHECK_called", GV_ADD|GV_ADDMULTI));

void
INIT()
    CODE:
        sv_inc(get_sv("XS::APItest::INIT_called", GV_ADD|GV_ADDMULTI));

void
END()
    CODE:
        sv_inc(get_sv("XS::APItest::END_called", GV_ADD|GV_ADDMULTI));

SV*
utf16_to_utf8 (sv, ...)
    SV* sv
        ALIAS:
            utf16_to_utf8_reversed = 1
    PREINIT:
        STRLEN len;
        U8 *source;
        SV *dest;
        Size_t got;
    CODE:
        source = (U8 *)SvPVbyte(sv, len);
        /* Optionally only convert part of the buffer.  */
        if (items > 1) {
            len = SvUV(ST(1));
        }
        /* Mortalise this right now, as we'll be testing croak()s  */
        dest = sv_2mortal(newSV(len * 2 + 1));
        if (ix) {
            utf16_to_utf8_reversed(source, (U8 *)SvPVX(dest), len, &got);
        } else {
            utf16_to_utf8(source, (U8 *)SvPVX(dest), len, &got);
        }
        SvCUR_set(dest, got);
        SvPVX(dest)[got] = '\0';
        SvPOK_on(dest);
        /* counteract the second mortalisation the SV* OUTPUT typmap
         * is about to perform */
        SvREFCNT_inc(dest);
        RETVAL = dest;
    OUTPUT: RETVAL


SV*
utf8_to_utf16 (sv, ...)
    SV* sv
        ALIAS:
            utf8_to_utf16_reversed = 1
    PREINIT:
        STRLEN len;
        U8 *source;
        SV *dest;
        Size_t got;
    CODE:
        source = (U8 *)SvPV(sv, len);
        /* Optionally only convert part of the buffer.  */
        if (items > 1) {
            len = SvUV(ST(1));
        }
        /* Mortalise this right now, as we'll be testing croak()s  */
        dest = sv_2mortal(newSV(len * 2 + 1));
        if (ix) {
            utf8_to_utf16_reversed(source, (U8 *)SvPVX(dest), len, &got);
        } else {
            utf8_to_utf16(source, (U8 *)SvPVX(dest), len, &got);
        }
        SvCUR_set(dest, got);
        SvPVX(dest)[got] = '\0';
        SvPOK_on(dest);
        /* counteract the second mortalisation the SV* OUTPUT typmap
         * is about to perform */
        SvREFCNT_inc(dest);
        RETVAL = dest;
    OUTPUT: RETVAL

void
my_exit(int exitcode)
        PPCODE:
        my_exit(exitcode);

U8
first_byte(sv)
        SV *sv
   CODE:
    char *s;
    STRLEN len;
        s = SvPVbyte(sv, len);
        RETVAL = s[0];
   OUTPUT:
    RETVAL

I32
sv_count()
        CODE:
            RETVAL = PL_sv_count;
        OUTPUT:
            RETVAL

IV
xs_items(...)
        CODE:
            RETVAL = items;
        OUTPUT:
            RETVAL

void
wide_marks(...)
        PPCODE:
#ifdef PERL_STACK_OFFSET_SSIZET
          XSRETURN_YES;
#else
          XSRETURN_NO;
#endif

void
bhk_record(bool on)
    CODE:
        dMY_CXT;
        MY_CXT.bhk_record = on;
        if (on)
            av_clear(MY_CXT.bhkav);
