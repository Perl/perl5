MODULE = XS::APItest:Overload   PACKAGE = XS::APItest::Overload

void
does_amagic_apply(sv, method, flags)
    SV *sv
    int method
    int flags
    PPCODE:
        if(Perl_amagic_applies(aTHX_ sv, method, flags))
            XSRETURN_YES;
        else
            XSRETURN_NO;


void
amagic_deref_call(sv, what)
        SV *sv
        int what
    PPCODE:
        /* The reference is owned by something else.  */
        PUSHs(amagic_deref_call(sv, what));

# I'd certainly like to discourage the use of this macro, given that we now
# have amagic_deref_call

void
tryAMAGICunDEREF_var(sv, what)
        SV *sv
        int what
    PPCODE:
        {
            SV **sp = &sv;
            switch(what) {
            case to_av_amg:
                tryAMAGICunDEREF(to_av);
                break;
            case to_cv_amg:
                tryAMAGICunDEREF(to_cv);
                break;
            case to_gv_amg:
                tryAMAGICunDEREF(to_gv);
                break;
            case to_hv_amg:
                tryAMAGICunDEREF(to_hv);
                break;
            case to_sv_amg:
                tryAMAGICunDEREF(to_sv);
                break;
            default:
                croak("Invalid value %d passed to tryAMAGICunDEREF_var", what);
            }
        }
        /* The reference is owned by something else.  */
        PUSHs(sv);
