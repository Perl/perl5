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

struct BuiltinFuncDescriptor {
    const char *name;
    XSUBADDR_t xsub;
    OP *(*checker)(pTHX_ OP *, GV *, SV *);
    IV ckval;
};

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

enum {
    BUILTIN_CONST_FALSE,
    BUILTIN_CONST_TRUE,
};

static OP *ck_builtin_const(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    const struct BuiltinFuncDescriptor *builtin = NUM2PTR(const struct BuiltinFuncDescriptor *, SvUV(ckobj));

    SV *prototype = newSVpvs("");
    SAVEFREESV(prototype);

    assert(entersubop->op_type == OP_ENTERSUB);

    entersubop = ck_entersub_args_proto(entersubop, namegv, prototype);

    SV *constval;
    switch(builtin->ckval) {
        case BUILTIN_CONST_FALSE: constval = &PL_sv_no; break;
        case BUILTIN_CONST_TRUE:  constval = &PL_sv_yes; break;
        default:
            DIE(aTHX_ "panic: unrecognised builtin_const value %" IVdf, builtin->ckval);
            break;
    }

    op_free(entersubop);

    return newSVOP(OP_CONST, 0, constval);
}

XS(XS_builtin_func1_scalar);
XS(XS_builtin_func1_scalar)
{
    dXSARGS;
    dXSI32;

    if(items != 1)
        croak_xs_usage(cv, "arg");

    switch(ix) {
        case OP_ISBOOL:
            Perl_pp_isbool(aTHX);
            break;

        case OP_ISWEAK:
            Perl_pp_isweak(aTHX);
            break;

        default:
            Perl_die(aTHX_ "panic: unhandled opcode %d for xs_builtin_func1_scalar()", ix);
    }

    XSRETURN(1);
}

XS(XS_builtin_func1_void);
XS(XS_builtin_func1_void)
{
    dXSARGS;
    dXSI32;

    if(items != 1)
        croak_xs_usage(cv, "arg");

    switch(ix) {
        case OP_WEAKEN:
            Perl_pp_weaken(aTHX);
            break;

        case OP_UNWEAKEN:
            Perl_pp_unweaken(aTHX);
            break;

        default:
            Perl_die(aTHX_ "panic: unhandled opcode %d for xs_builtin_func1_void()", ix);
    }

    XSRETURN(0);
}

static OP *ck_builtin_func1(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    const struct BuiltinFuncDescriptor *builtin = NUM2PTR(const struct BuiltinFuncDescriptor *, SvUV(ckobj));

    SV *prototype = newSVpvs("$");
    SAVEFREESV(prototype);

    assert(entersubop->op_type == OP_ENTERSUB);

    entersubop = ck_entersub_args_proto(entersubop, namegv, prototype);

    OP *parent = entersubop, *pushop, *argop;

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    argop = OpSIBLING(pushop);

    if (!argop || !OpHAS_SIBLING(argop) || OpHAS_SIBLING(OpSIBLING(argop)))
        return entersubop;

    (void)op_sibling_splice(parent, pushop, 1, NULL);

    U8 wantflags = entersubop->op_flags & OPf_WANT;

    op_free(entersubop);

    OPCODE opcode = builtin->ckval;

    return newUNOP(opcode, wantflags, argop);
}

static const char builtin_not_recognised[] = "'%" SVf "' is not recognised as a builtin function";

static const struct BuiltinFuncDescriptor builtins[] = {
    /* constants */
    { "builtin::true",   &XS_builtin_true,   &ck_builtin_const, BUILTIN_CONST_TRUE  },
    { "builtin::false",  &XS_builtin_false,  &ck_builtin_const, BUILTIN_CONST_FALSE },

    /* unary functions */
    { "builtin::isbool",   &XS_builtin_func1_scalar, &ck_builtin_func1, OP_ISBOOL   },
    { "builtin::weaken",   &XS_builtin_func1_void,   &ck_builtin_func1, OP_WEAKEN   },
    { "builtin::unweaken", &XS_builtin_func1_void,   &ck_builtin_func1, OP_UNWEAKEN },
    { "builtin::isweak",   &XS_builtin_func1_scalar, &ck_builtin_func1, OP_ISWEAK   },
    { 0 }
};

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
        if(strEQ(SvPV_nolen(sym), "import"))
            Perl_croak(aTHX_ builtin_not_recognised, sym);

        SV *ampname = sv_2mortal(Perl_newSVpvf(aTHX_ "&%" SVf, SVfARG(sym)));
        SV *fqname  = sv_2mortal(Perl_newSVpvf(aTHX_ "builtin::%" SVf, SVfARG(sym)));

        CV *cv = get_cv(SvPV_nolen(fqname), SvUTF8(fqname) ? SVf_UTF8 : 0);
        if(!cv)
            Perl_croak(aTHX_ builtin_not_recognised, sym);

        PADOFFSET off = pad_add_name_sv(ampname, padadd_STATE, 0, 0);
        SvREFCNT_dec(PL_curpad[off]);
        PL_curpad[off] = SvREFCNT_inc(cv);
    }

    intro_my();

    LEAVE;
}

void
Perl_boot_core_builtin(pTHX)
{
    I32 i;
    for(i = 0; builtins[i].name; i++) {
        const struct BuiltinFuncDescriptor *builtin = &builtins[i];

        const char *proto = NULL;
        if(builtin->checker == &ck_builtin_const)
            proto = "";
        else if(builtin->checker == &ck_builtin_func1)
            proto = "$";

        CV *cv = newXS_flags(builtin->name, builtin->xsub, __FILE__, proto, 0);
        XSANY.any_i32 = builtin->ckval;

        if(builtin->checker) {
            cv_set_call_checker_flags(cv, builtin->checker, newSVuv(PTR2UV(builtin)), 0);
        }
    }

    newXS_flags("builtin::import", &XS_builtin_import, __FILE__, NULL, 0);
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
