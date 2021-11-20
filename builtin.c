/*    builtin.c
 *
 *    Copyright (C) 2021 by Paul Evans and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/* This file contains the code that implements functions in perl's "builtin::"
 * namespace
 */

#include "EXTERN.h"
#include "perl.h"

#include "XSUB.h"

XS(XS_builtin_true);
XS(XS_builtin_true)
{
    dXSARGS;
    if(items)
        croak_xs_usage(cv, "");
    XSRETURN_YES;
}

XS(XS_builtin_false);
XS(XS_builtin_false)
{
    dXSARGS;
    if(items)
        croak_xs_usage(cv, "");
    XSRETURN_NO;
}

XS(XS_builtin_isbool);
XS(XS_builtin_isbool)
{
    dXSARGS;
    if(items != 1)
        croak_xs_usage(cv, "sv");

    SV *sv = ST(0);
    if(SvIsBOOL(sv))
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

XS(XS_builtin_import);
XS(XS_builtin_import)
{
    dXSARGS;

    if(!PL_compcv)
        Perl_croak(aTHX_
                "builtin::import can only be called at compiletime");

    /* We need to have PL_comppad / PL_curpad set correctly for lexical importing */
    ENTER;
    SAVESPTR(PL_comppad_name); PL_comppad_name = PadlistNAMES(CvPADLIST(PL_compcv));
    SAVESPTR(PL_comppad);      PL_comppad      = PadlistARRAY(CvPADLIST(PL_compcv))[1];
    SAVESPTR(PL_curpad);       PL_curpad       = PadARRAY(PL_comppad);

    for(int i = 1; i < items; i++) {
        SV *sym = ST(i);
        if(strEQ(SvPV_nolen(sym), "import")) goto unavailable;

        SV *ampname = sv_2mortal(Perl_newSVpvf(aTHX_ "&%" SVf, SVfARG(sym)));
        SV *fqname  = sv_2mortal(Perl_newSVpvf(aTHX_ "builtin::%" SVf, SVfARG(sym)));

        CV *cv = get_cv(SvPV_nolen(fqname), SvUTF8(fqname) ? SVf_UTF8 : 0);
        if(!cv) goto unavailable;

        PADOFFSET off = pad_add_name_sv(ampname, padadd_STATE, 0, 0);
        SvREFCNT_dec(PL_curpad[off]);
        PL_curpad[off] = SvREFCNT_inc(cv);
        continue;

unavailable:
        Perl_croak(aTHX_
                "'%" SVf "' is not recognised as a builtin function", sym);
    }

    intro_my();

    LEAVE;
}

void
Perl_boot_core_builtin(pTHX)
{
    newXS_flags("builtin::true",   &XS_builtin_true,   __FILE__, NULL, 0);
    newXS_flags("builtin::false",  &XS_builtin_false,  __FILE__, NULL, 0);
    newXS_flags("builtin::isbool", &XS_builtin_isbool, __FILE__, NULL, 0);

    newXS_flags("builtin::import", &XS_builtin_import, __FILE__, NULL, 0);
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
