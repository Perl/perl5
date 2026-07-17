MODULE = XS::APItest            PACKAGE = XS::APItest::MagicV2

void
sv_magicv2_add(SV *sv, SV *magicname, SV *auxsvref, U16 priv = 0)
    PROTOTYPE: \[$@%]$$;$
    CODE:
        const struct MagicFunctions *funcs = S_magicfuncs_by_name(aTHX_ magicname);
        SV *auxsv = NULL;
        if(auxsvref && SvROK(auxsvref))
            auxsv = SvRV(auxsvref);

        if(auxsv && !(funcs->flags & MGv2f_ALWAYS_WEAK_AUXSV))
            SvREFCNT_inc(auxsv);

        MAGIC *mg = sv_magicv2_add(SvRV(sv), funcs, 0, auxsv);

        if(priv)
            MgPRIV(mg) = priv;

        if(funcs == (const struct MagicFunctions *)&magicfuncs_userstruct) {
            struct TwoIVs *user = MgUSERSTRUCT(mg, struct TwoIVs *);
            user->x = 123;
            user->y = 456;
        }

bool
sv_magicv2_exists(SV *sv, SV *magicname)
    CODE:
        RETVAL = (bool)sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
    OUTPUT:
        RETVAL

bool
sv_magicv2_exists_by_auxsv(SV *sv, SV *auxsvref)
    CODE:
        RETVAL = (bool)sv_magicv2_find_by_auxsv(sv, SvRV(auxsvref));
    OUTPUT:
        RETVAL

SV *
MgAUXSV(SV *sv, SV *magicname)
    // args different than the C macros
    ALIAS:
        MgAUXSV = 0
        MgPRIV  = 2
        MgKEYIV = 3
        MgKEYSV = 4
    CODE:
    {
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_UNDEF;

        RETVAL = &PL_sv_undef;

        switch(ix) {
            case 0:
                if(MgAUXSV(mg))
                    RETVAL = newRV_inc(MgAUXSV(mg));
                break;

            case 2:
                RETVAL = newSVuv(MgPRIV(mg));
                break;

            case 3:
                if(!MgHasKEYIV(mg))
                    croak("This Magic does not set MgKEYIV");
                RETVAL = newSViv(MgKEYIV(mg));
                break;

            case 4:
                if(!MgHasKEYSV(mg))
                    croak("This Magic does not set MgKEYSV");
                RETVAL = newSVsv(MgKEYSV(mg));
                break;
        }
    }
    OUTPUT:
        RETVAL

void
MgAUXSV_set(SV *sv, SV *magicname, SV *newauxsvref)
    // args different than the C macro
    CODE:
    {
        const struct MagicFunctions *funcs = S_magicfuncs_by_name(aTHX_ magicname);
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, funcs);
        if(!mg)
            XSRETURN_EMPTY;

        SV *auxsv = NULL;
        if(newauxsvref && SvROK(newauxsvref))
            auxsv = SvRV(newauxsvref);

        if(auxsv && !MgWEAK_AUXSV(mg))
            SvREFCNT_inc(auxsv);

        MgAUXSV_set(mg, auxsv);
    }

SV *
MgAUXSV_value(SV *sv, SV *magicname)
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_UNDEF;

        RETVAL = newSVsv(MgAUXSV(mg));
    OUTPUT:
        RETVAL

void
MgAUXSV_values(SV *sv, SV *magicname)
    PPCODE:
        const struct MagicFunctions *funcs;
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, (funcs = S_magicfuncs_by_name(aTHX_ magicname)));
        if(!mg)
            XSRETURN(0);

        U32 count = 0;
        while(mg) {
            XPUSHs(sv_mortalcopy(MgAUXSV(mg)));
            count++;

            mg = sv_magicv2_findnext_by_funcs(sv, funcs, mg);
        }

        XSRETURN(count);

void
MgKEYIV_set(SV *sv, SV *magicname, IV newval)
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_EMPTY;

        if(!MgHasKEYIV(mg))
            croak("This Magic does not set MgKEYIV");
        MgKEYIV_set(mg, newval);

void
MgKEYSV_set(SV *sv, SV *magicname, SV *newval)
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_EMPTY;

        if(!MgHasKEYSV(mg))
            croak("This Magic does not set MgKEYSV");
        MgKEYSV_set(mg, newSVsv(newval));

SV *
MgPTR(SV *sv, SV *magicname)
    // args different than C macro
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg || !MgPTR(mg))
            RETVAL = &PL_sv_undef;
        else
            RETVAL = newSVpvn((char *)MgPTR(mg), MgPTRLEN(mg));
    OUTPUT:
        RETVAL

void
MgPTR_write(SV *sv, SV *magicname, SV *newval)
    // not actual perl API but used by magicv2.t to demonstrate independence of buffers
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_EMPTY;
        if(!MgPTR(mg) || !MgPTRLEN(mg))
            XSRETURN_EMPTY;

        STRLEN len;
        char *pv = SvPV(newval, len);
        if(len > (STRLEN)MgPTRLEN(mg))
            len = MgPTRLEN(mg);

        Copy(pv, MgPTR(mg), len, char);

STRLEN
MgPTRLEN(SV *sv, SV *magicname)
    // args different than C macro
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            RETVAL = -1;
        else
            RETVAL = MgPTRLEN(mg);

    OUTPUT:
      RETVAL

void
MgPTRLEN_set(SV *sv, SV *magicname, STRLEN len)
    // args different than C macro
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_EMPTY;

        MgPTRLEN_set(mg, len);

void
mg_ptr_store(SV *sv, SV *magicname, SV *ptr)
    // args different than C function
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
        if(!mg)
            XSRETURN_EMPTY;

        STRLEN len;
        const char *pv = SvPV(ptr, len);
        mg_ptr_store(mg, pv, len);

void
sv_magicv2_get_userstruct(SV *sv)
    PPCODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, (const struct MagicFunctions *)&magicfuncs_userstruct);
        if(!mg)
            XSRETURN(0);

        struct TwoIVs *user = MgUSERSTRUCT(mg, struct TwoIVs *);
        EXTEND(SP, 2);
        mPUSHi(user->x);
        mPUSHi(user->y);
        XSRETURN(2);

void
sv_magicv2_set_userstruct(SV *sv, IV x, IV y)
    CODE:
        MAGIC *mg = sv_magicv2_find_by_funcs(sv, (const struct MagicFunctions *)&magicfuncs_userstruct);
        if(!mg)
            XSRETURN_EMPTY;

        struct TwoIVs *user = MgUSERSTRUCT(mg, struct TwoIVs *);
        user->x = x;
        user->y = y;

void
sv_magicv2_remove(SV *sv, SV *magicname)
    CODE:
        sv_magicv2_remove_by_funcs(sv, S_magicfuncs_by_name(aTHX_ magicname));
