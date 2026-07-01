MODULE = XS::APItest::AutoLoader        PACKAGE = XS::APItest::AutoLoader

SV *
AUTOLOAD()
    CODE:
        RETVAL = newSVpvn_flags(SvPVX(cv), SvCUR(cv), SvUTF8(cv));
    OUTPUT:
        RETVAL

SV *
AUTOLOADp(...)
    PROTOTYPE: *$
    CODE:
        PERL_UNUSED_ARG(items);
        RETVAL = newSVpvn_flags(SvPVX(cv), SvCUR(cv), SvUTF8(cv));
    OUTPUT:
        RETVAL
