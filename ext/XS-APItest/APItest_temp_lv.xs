MODULE = XS::APItest:TempLv         PACKAGE = XS::APItest::TempLv

void
make_temp_mg_lv(sv)
SV* sv
    PREINIT:
        SV * const lv = newSV_type(SVt_PVLV);
        STRLEN len;
    PPCODE:
        SvPV(sv, len);

        sv_magic(lv, NULL, PERL_MAGIC_substr, NULL, 0);
        LvTYPE(lv) = 'x';
        LvTARG(lv) = SvREFCNT_inc_simple(sv);
        LvTARGOFF(lv) = len == 0 ? 0 : 1;
        LvTARGLEN(lv) = len < 2 ? 0 : len-2;

        EXTEND(SP, 1);
        ST(0) = sv_2mortal(lv);
        XSRETURN(1);
