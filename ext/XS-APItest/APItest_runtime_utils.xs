bool
test_newFOROP_without_slab()
CODE:
    {
        const I32 floor = start_subparse(0,0);
        OP *o;
        /* The slab allocator does not like CvROOT being set. */
        CvROOT(PL_compcv) = (OP *)1;
        o = newFOROP(0, 0, newOP(OP_PUSHMARK, 0), 0, 0);
        if (cLOOPx(cUNOPo->op_first)->op_last->op_sibparent
                != cUNOPo->op_first)
        {
            Perl_warn(aTHX_ "Op parent pointer is stale");
            RETVAL = FALSE;
        }
        else
            /* If we do not crash before returning, the test passes. */
            RETVAL = TRUE;
        op_free(o);
        CvROOT(PL_compcv) = NULL;
        SvREFCNT_dec(PL_compcv);
        LEAVE_SCOPE(floor);
    }
OUTPUT:
    RETVAL

 # provide access to CALLREGEXEC, except replace pointers within the
 # string with offsets from the start of the string

I32
callregexec(SV *prog, STRLEN stringarg, STRLEN strend, I32 minend, SV *sv, U32 nosave)
CODE:
    {
        STRLEN len;
        char *strbeg;
        if (SvROK(prog))
            prog = SvRV(prog);
        strbeg = SvPV_force(sv, len);
        RETVAL = CALLREGEXEC((REGEXP *)prog,
                            strbeg + stringarg,
                            strbeg + strend,
                            strbeg,
                            minend,
                            sv,
                            NULL, /* data */
                            nosave);
    }
OUTPUT:
    RETVAL

 # provide access to pregexec, except replace pointers within the
 # string with offsets from the start of the string

I32
callpregexec(SV *prog, STRLEN stringarg, STRLEN strend, I32 minend, SV *sv, U32 nosave)
CODE:
    {
        STRLEN len;
        char *strbeg;
        if (SvROK(prog))
            prog = SvRV(prog);
        strbeg = SvPV_force(sv, len);
        RETVAL = pregexec((REGEXP *)prog,
                            strbeg + stringarg,
                            strbeg + strend,
                            strbeg,
                            minend,
                            sv,
                            nosave);
    }
OUTPUT:
    RETVAL

void
lexical_import(SV *name, CV *cv)
    CODE:
    {
        PADLIST *pl;
        PADOFFSET off;
        if (!PL_compcv)
            Perl_croak(aTHX_
                      "lexical_import can only be called at compile time");
        pl = CvPADLIST(PL_compcv);
        ENTER;
        SAVESPTR(PL_comppad_name); PL_comppad_name = PadlistNAMES(pl);
        SAVESPTR(PL_comppad);      PL_comppad      = PadlistARRAY(pl)[1];
        SAVESPTR(PL_curpad);       PL_curpad       = PadARRAY(PL_comppad);
        off = pad_add_name_sv(sv_2mortal(newSVpvf("&%" SVf,name)),
                              padadd_STATE, 0, 0);
        SvREFCNT_dec(PL_curpad[off]);
        PL_curpad[off] = SvREFCNT_inc(cv);
        intro_my();
        LEAVE;
    }

SV *
sv_mortalcopy(SV *sv)
    CODE:
        RETVAL = SvREFCNT_inc(sv_mortalcopy(sv));
    OUTPUT:
        RETVAL

SV *
newRV(SV *sv)

SV *
newAVav(AV *av)
    CODE:
        RETVAL = newRV_noinc((SV *)newAVav(av));
    OUTPUT:
        RETVAL

SV *
newAVhv(HV *hv)
    CODE:
        RETVAL = newRV_noinc((SV *)newAVhv(hv));
    OUTPUT:
        RETVAL

void
alias_av(AV *av, IV ix, SV *sv)
    CODE:
        av_store(av, ix, SvREFCNT_inc(sv));

SV *
cv_name(SVREF ref, ...)
    CODE:
        RETVAL = SvREFCNT_inc(cv_name((CV *)ref,
                                      items>1 && ST(1) != &PL_sv_undef
                                        ? ST(1)
                                        : NULL,
                                      items>2 ? SvUV(ST(2)) : 0));
    OUTPUT:
        RETVAL

void
sv_catpvn(SV *sv, SV *sv2)
    CODE:
    {
        STRLEN len;
        const char *s = SvPV(sv2,len);
        sv_catpvn_flags(sv,s,len, SvUTF8(sv2) ? SV_CATUTF8 : SV_CATBYTES);
    }

bool
test_newOP_CUSTOM()
    CODE:
    {
        OP *o = newLISTOP(OP_CUSTOM, 0, NULL, NULL);
        op_free(o);
        o = newOP(OP_CUSTOM, 0);
        op_free(o);
        o = newUNOP(OP_CUSTOM, 0, NULL);
        op_free(o);
        o = newUNOP_AUX(OP_CUSTOM, 0, NULL, NULL);
        op_free(o);
        o = newMETHOP(OP_CUSTOM, 0, newOP(OP_NULL,0));
        op_free(o);
        o = newMETHOP_named(OP_CUSTOM, 0, newSV(0));
        op_free(o);
        o = newBINOP(OP_CUSTOM, 0, NULL, NULL);
        op_free(o);
        o = newPMOP(OP_CUSTOM, 0);
        op_free(o);
        o = newSVOP(OP_CUSTOM, 0, newSV(0));
        op_free(o);
#ifdef USE_ITHREADS
        ENTER;
        lex_start(NULL, NULL, 0);
        {
            I32 ix = start_subparse(FALSE,0);
            o = newPADOP(OP_CUSTOM, 0, newSV(0));
            op_free(o);
            LEAVE_SCOPE(ix);
        }
        LEAVE;
#endif
        o = newPVOP(OP_CUSTOM, 0, NULL);
        op_free(o);
        o = newLOGOP(OP_CUSTOM, 0, newOP(OP_NULL,0), newOP(OP_NULL,0));
        op_free(o);
        o = newLOOPEX(OP_CUSTOM, newOP(OP_NULL,0));
        op_free(o);
        RETVAL = TRUE;
    }
    OUTPUT:
        RETVAL

void
test_sv_catpvf(SV *fmtsv)
    PREINIT:
        SV *sv;
        char *fmt;
    CODE:
        fmt = SvPV_nolen(fmtsv);
        sv = sv_2mortal(newSVpvn("", 0));
        sv_catpvf(sv, fmt, 5, 6, 7, 8);

void
load_module(flags, name, ...)
    U32 flags
    SV *name
CODE:
    if (items == 2) {
        Perl_load_module(aTHX_ flags, SvREFCNT_inc(name), NULL);
    } else if (items == 3) {
        Perl_load_module(aTHX_ flags, SvREFCNT_inc(name), SvREFCNT_inc(ST(2)));
    } else
        Perl_croak(aTHX_ "load_module can't yet support %" IVdf " items",
                          (IV)items);

SV *
string_without_null(SV *sv)
    CODE:
    {
        STRLEN len;
        const char *s = SvPV(sv, len);
        RETVAL = newSVpvn_flags(s, len, SvUTF8(sv));
        *SvEND(RETVAL) = 0xff;
    }
    OUTPUT:
        RETVAL

CV *
get_cv(SV *sv)
    CODE:
    {
        STRLEN len;
        const char *s = SvPV(sv, len);
        RETVAL = get_cvn_flags(s, len, 0);
    }
    OUTPUT:
        RETVAL

CV *
get_cv_flags(SV *sv, UV flags)
    CODE:
    {
        STRLEN len;
        const char *s = SvPV(sv, len);
        RETVAL = get_cvn_flags(s, len, flags);
    }
    OUTPUT:
        RETVAL

void
unshift_and_set_defav(SV *sv,...)
    CODE:
        av_unshift(GvAVn(PL_defgv), 1);
        av_store(GvAV(PL_defgv), 0, newSVuv(42));
        sv_setuv(sv, 43);

PerlIO *
PerlIO_stderr()

OutputStream
PerlIO_stdout()

InputStream
PerlIO_stdin()

#undef FILE
#define FILE NativeFile

FILE *
PerlIO_exportFILE(PerlIO *f, const char *mode)

SV *
test_MAX_types()
    CODE:
        /* tests that IV_MAX and UV_MAX have types suitable
           for the IVdf and UVdf formats.
           If this warns then don't add casts here.
        */
        RETVAL = newSVpvf("iv %" IVdf " uv %" UVuf, IV_MAX, UV_MAX);
    OUTPUT:
        RETVAL

SV *
test_HvNAMEf(sv)
    SV *sv
    CODE:
        if (!sv_isobject(sv)) XSRETURN_UNDEF;
        HV *pkg = SvSTASH(SvRV(sv));
        RETVAL = newSVpvf("class='%" HvNAMEf "'", pkg);
    OUTPUT:
        RETVAL

SV *
test_HvNAMEf_QUOTEDPREFIX(sv)
    SV *sv
    CODE:
        if (!sv_isobject(sv)) XSRETURN_UNDEF;
        HV *pkg = SvSTASH(SvRV(sv));
        RETVAL = newSVpvf("class=%" HvNAMEf_QUOTEDPREFIX, pkg);
    OUTPUT:
        RETVAL
