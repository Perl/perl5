void
call_sv_C()
PREINIT:
    CV * i_sub;
    GV * i_gv;
    I32 retcnt;
    SV * errsv;
    char * errstr;
    STRLEN errlen;
    SV * miscsv = sv_newmortal();
    HV * hv = MUTABLE_HV(newSV_type_mortal(SVt_PVHV));
CODE:
    i_sub = get_cv("i", 0);
    PUSHMARK(SP);
    /* PUTBACK not needed since this sub was called with 0 args, and is calling
      0 args, so global SP doesn't need to be moved before a call_* */
    retcnt = call_sv((SV*)i_sub, 0); /* try a CV* */
    SPAGAIN;
    SP -= retcnt; /* dont care about return count, wipe everything off */
    sv_setpvs(miscsv, "i");
    PUSHMARK(SP);
    retcnt = call_sv(miscsv, 0); /* try a PV */
    SPAGAIN;
    SP -= retcnt;
    /* no add and SVt_NULL are intentional, sub i should be defined already */
    i_gv = gv_fetchpvn_flags("i", sizeof("i")-1, 0, SVt_NULL);
    PUSHMARK(SP);
    retcnt = call_sv((SV*)i_gv, 0); /* try a GV* */
    SPAGAIN;
    SP -= retcnt;
    /* the tests below are not declaring this being public API behavior,
       only current internal behavior, these tests can be changed in the
       future if necessery */
    PUSHMARK(SP);
    retcnt = call_sv(&PL_sv_yes, G_EVAL);
    SPAGAIN;
    SP -= retcnt;
    errsv = ERRSV;
    errstr = SvPV(errsv, errlen);
    if(memBEGINs(errstr, errlen, "Undefined subroutine &main::1 called at")) {
        PUSHMARK(SP);
        retcnt = call_sv((SV*)i_sub, 0); /* call again to increase counter */
        SPAGAIN;
        SP -= retcnt;
    }
    PUSHMARK(SP);
    retcnt = call_sv(&PL_sv_no, G_EVAL);
    SPAGAIN;
    SP -= retcnt;
    errsv = ERRSV;
    errstr = SvPV(errsv, errlen);
    if(memBEGINs(errstr, errlen, "Undefined subroutine &main:: called at")) {
        PUSHMARK(SP);
        retcnt = call_sv((SV*)i_sub, 0); /* call again to increase counter */
        SPAGAIN;
        SP -= retcnt;
    }
    PUSHMARK(SP);
    retcnt = call_sv(&PL_sv_undef,  G_EVAL);
    SPAGAIN;
    SP -= retcnt;
    errsv = ERRSV;
    errstr = SvPV(errsv, errlen);
    if(memBEGINs(errstr, errlen, "Can't use an undefined value as a subroutine reference at")) {
        PUSHMARK(SP);
        retcnt = call_sv((SV*)i_sub, 0); /* call again to increase counter */
        SPAGAIN;
        SP -= retcnt;
    }
    PUSHMARK(SP);
    retcnt = call_sv((SV*)hv,  G_EVAL);
    SPAGAIN;
    SP -= retcnt;
    errsv = ERRSV;
    errstr = SvPV(errsv, errlen);
    if(memBEGINs(errstr, errlen, "Not a CODE reference at")) {
        PUSHMARK(SP);
        retcnt = call_sv((SV*)i_sub, 0); /* call again to increase counter */
        SPAGAIN;
        SP -= retcnt;
    }

void
call_sv(sv, flags, ...)
    SV* sv
    I32 flags
    PREINIT:
        SSize_t i;
    PPCODE:
        for (i=0; i<items-2; i++)
            ST(i) = ST(i+2); /* pop first two args */
        PUSHMARK(SP);
        SP += items - 2;
        PUTBACK;
        i = call_sv(sv, flags);
        SPAGAIN;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(i)));

void
call_pv(subname, flags, ...)
    char* subname
    I32 flags
    PREINIT:
        I32 i;
    PPCODE:
        for (i=0; i<items-2; i++)
            ST(i) = ST(i+2); /* pop first two args */
        PUSHMARK(SP);
        SP += items - 2;
        PUTBACK;
        i = call_pv(subname, flags);
        SPAGAIN;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(i)));

void
call_argv(subname, flags, ...)
    char* subname
    I32 flags
    PREINIT:
        I32 i;
        char *tmpary[4];
    PPCODE:
        for (i=0; i<items-2; i++)
            tmpary[i] = SvPV_nolen(ST(i+2)); /* ignore first two args */
        tmpary[i] = NULL;
        PUTBACK;
        i = call_argv(subname, flags, tmpary);
        SPAGAIN;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(i)));

bool
call_argv_cleanup()
  CODE:
    IV old_count = PL_sv_count;
    char one[] = "one"; /* non const strings */
    char two[] = "two";
    char *args[] = { one, two, NULL };
    Perl_call_argv(aTHX_ "called_by_argv_cleanup", G_DISCARD | G_LIST, args);
    RETVAL = PL_sv_count == old_count;
  OUTPUT:
    RETVAL

void
call_method(methname, flags, ...)
    char* methname
    I32 flags
    PREINIT:
        I32 i;
    PPCODE:
        for (i=0; i<items-2; i++)
            ST(i) = ST(i+2); /* pop first two args */
        PUSHMARK(SP);
        SP += items - 2;
        PUTBACK;
        i = call_method(methname, flags);
        SPAGAIN;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(i)));

void
newCONSTSUB(stash, name, flags, sv)
    HV* stash
    SV* name
    I32 flags
    SV* sv
    ALIAS:
        newCONSTSUB_flags = 1
    PREINIT:
        CV* mycv = NULL;
        STRLEN len;
        const char *pv = SvPV(name, len);
    PPCODE:
        switch (ix) {
           case 0:
               mycv = newCONSTSUB(stash, pv, SvOK(sv) ? SvREFCNT_inc(sv) : NULL);
               break;
           case 1:
               mycv = newCONSTSUB_flags(
                 stash, pv, len, flags | SvUTF8(name), SvOK(sv) ? SvREFCNT_inc(sv) : NULL
               );
               break;
        }
        EXTEND(SP, 2);
        assert(mycv);
        PUSHs( CvCONST(mycv) ? &PL_sv_yes : &PL_sv_no );
        PUSHs((SV*)CvGV(mycv));

void
gv_init_type(namesv, multi, flags, type)
    SV* namesv
    int multi
    I32 flags
    int type
    PREINIT:
        STRLEN len;
        const char * const name = SvPV_const(namesv, len);
        GV *gv = *(GV**)hv_fetch(PL_defstash, name, len, TRUE);
    PPCODE:
        if (SvTYPE(gv) == SVt_PVGV)
            Perl_croak(aTHX_ "GV is already a PVGV");
        if (multi) flags |= GV_ADDMULTI;
        switch (type) {
           case 0:
               gv_init(gv, PL_defstash, name, len, multi);
               break;
           case 1:
               gv_init_sv(gv, PL_defstash, namesv, flags);
               break;
           case 2:
               gv_init_pv(gv, PL_defstash, name, flags | SvUTF8(namesv));
               break;
           case 3:
               gv_init_pvn(gv, PL_defstash, name, len, flags | SvUTF8(namesv));
               break;
        }
        XPUSHs( gv ? (SV*)gv : &PL_sv_undef);

void
gv_fetchmeth_type(stash, methname, type, level, flags)
    HV* stash
    SV* methname
    int type
    I32 level
    I32 flags
    PREINIT:
        STRLEN len;
        const char * const name = SvPV_const(methname, len);
        GV* gv = NULL;
    PPCODE:
        switch (type) {
           case 0:
               gv = gv_fetchmeth(stash, name, len, level);
               break;
           case 1:
               gv = gv_fetchmeth_sv(stash, methname, level, flags);
               break;
           case 2:
               gv = gv_fetchmeth_pv(stash, name, level, flags | SvUTF8(methname));
               break;
           case 3:
               gv = gv_fetchmeth_pvn(stash, name, len, level, flags | SvUTF8(methname));
               break;
        }
        XPUSHs( gv ? MUTABLE_SV(gv) : &PL_sv_undef );

void
gv_fetchmeth_autoload_type(stash, methname, type, level, flags)
    HV* stash
    SV* methname
    int type
    I32 level
    I32 flags
    PREINIT:
        STRLEN len;
        const char * const name = SvPV_const(methname, len);
        GV* gv = NULL;
    PPCODE:
        switch (type) {
           case 0:
               gv = gv_fetchmeth_autoload(stash, name, len, level);
               break;
           case 1:
               gv = gv_fetchmeth_sv_autoload(stash, methname, level, flags);
               break;
           case 2:
               gv = gv_fetchmeth_pv_autoload(stash, name, level, flags | SvUTF8(methname));
               break;
           case 3:
               gv = gv_fetchmeth_pvn_autoload(stash, name, len, level, flags | SvUTF8(methname));
               break;
        }
        XPUSHs( gv ? MUTABLE_SV(gv) : &PL_sv_undef );

void
gv_fetchmethod_flags_type(stash, methname, type, flags)
    HV* stash
    SV* methname
    int type
    I32 flags
    PREINIT:
        GV* gv = NULL;
    PPCODE:
        switch (type) {
           case 0:
               gv = gv_fetchmethod_flags(stash, SvPVX_const(methname), flags);
               break;
           case 1:
               gv = gv_fetchmethod_sv_flags(stash, methname, flags);
               break;
           case 2:
               gv = gv_fetchmethod_pv_flags(stash, SvPV_nolen(methname), flags | SvUTF8(methname));
               break;
           case 3: {
               STRLEN len;
               const char * const name = SvPV_const(methname, len);
               gv = gv_fetchmethod_pvn_flags(stash, name, len, flags | SvUTF8(methname));
               break;
            }
           case 4:
               gv = gv_fetchmethod_pvn_flags(stash, SvPV_nolen(methname),
                                             flags, SvUTF8(methname));
        }
        XPUSHs( gv ? (SV*)gv : &PL_sv_undef);

void
gv_autoload_type(stash, methname, type, method)
    HV* stash
    SV* methname
    int type
    I32 method
    PREINIT:
        STRLEN len;
        const char * const name = SvPV_const(methname, len);
        GV* gv = NULL;
        I32 flags = method ? GV_AUTOLOAD_ISMETHOD : 0;
    PPCODE:
        switch (type) {
           case 0:
               gv = gv_autoload4(stash, name, len, method);
               break;
           case 1:
               gv = gv_autoload_sv(stash, methname, flags);
               break;
           case 2:
               gv = gv_autoload_pv(stash, name, flags | SvUTF8(methname));
               break;
           case 3:
               gv = gv_autoload_pvn(stash, name, len, flags | SvUTF8(methname));
               break;
        }
        XPUSHs( gv ? (SV*)gv : &PL_sv_undef);

SV *
gv_const_sv(SV *name)
    PREINIT:
        GV *gv;
    CODE:
        if (SvPOK(name)) {
            HV *stash = gv_stashpv("main",0);
            HE *he = hv_fetch_ent(stash, name, 0, 0);
            gv = (GV *)HeVAL(he);
        }
        else {
            gv = (GV *)name;
        }
        RETVAL = gv_const_sv(gv);
        if (!RETVAL)
            XSRETURN_EMPTY;
        RETVAL = newSVsv(RETVAL);
    OUTPUT:
        RETVAL

void
whichsig_type(namesv, type)
    SV* namesv
    int type
    PREINIT:
        STRLEN len;
        const char * const name = SvPV_const(namesv, len);
        I32 i = 0;
    PPCODE:
        switch (type) {
           case 0:
              i = whichsig(name);
               break;
           case 1:
               i = whichsig_sv(namesv);
               break;
           case 2:
               i = whichsig_pv(name);
               break;
           case 3:
               i = whichsig_pvn(name, len);
               break;
        }
        XPUSHs(sv_2mortal(newSViv(i)));

void
eval_sv(sv, flags)
    SV* sv
    I32 flags
    PREINIT:
        SSize_t i;
    PPCODE:
        PUTBACK;
        i = eval_sv(sv, flags);
        SPAGAIN;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(i)));

void
eval_pv(p, croak_on_error)
    const char* p
    I32 croak_on_error
    PPCODE:
        PUTBACK;
        EXTEND(SP, 1);
        PUSHs(eval_pv(p, croak_on_error));

void
require_pv(pv)
    const char* pv
    PPCODE:
        PUTBACK;
        require_pv(pv);
