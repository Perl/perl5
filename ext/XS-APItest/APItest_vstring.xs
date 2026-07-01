MODULE = XS::APItest            PACKAGE = XS::APItest::vstring

bool
SvVOK(SV *sv)

SV *
SvVSTRING(SV *sv)
    CODE:
    {
        const char *vstr_pv;
        STRLEN vstr_len;
        if((vstr_pv = SvVSTRING(sv, vstr_len)))
            RETVAL = newSVpvn(vstr_pv, vstr_len);
        else
            RETVAL = &PL_sv_undef;
    }
    OUTPUT:
        RETVAL
