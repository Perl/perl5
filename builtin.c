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
#define PERL_IN_BUILTIN_C
#include "perl.h"

#include "XSUB.h"

/* copied from op.c */
#define SHORTVER(maj,min) (((maj) << 8) | (min))

/* defines for fields in struct BuiltinFuncDescriptor */
#define PACKVER(_maj,_min) ((U8)( \
    ((((_maj)/((_maj)-5 ? 0 : 1))-1) << 8) \
  | (((_min)/((_min) < 39 ? 0 : 1))-39)    ))
#define CHKFN_NULLFNPTR 0
#define CHKFN_CONST 1
#define CHKFN_FUNC1 2
#define CHKFN_FUNCN 3
#define PACKLEN(_is_experimental, _chkfn_type, _len) ( \
    (((_len)/((_len) <= 0x1F ? 1 : 0)) << 3) \
  | (((_chkfn_type)/((_chkfn_type) <= 3 ? 1 : 0)) << 1) \
  | ((_is_experimental)?1:0))
#define UNPACK_IS_EXP(_f) ((_f)&1)
#define UNPACK_LEN(_f) ((U8)(((U8)(_f))>>3))
#define UNPACK_CHKFN(_f) ((U8)(((U8)(_f))>>1)&3)

struct BuiltinFuncDescriptor {
    const char *name;
    XSUBADDR_t xsub; /* note U32 alignment hole on 64b CPUs, fixable one day */
    U16 ckval;       /* usually PL opcodes ~<= 400s, stored in XSANY */
    U8 since_ver;    /* stored as val-39 */
    U8 name_len_f;   /* bitfield, contains
    bool U1 is_experimental
    U2 op checker cb fn "cv_set_call_checker_flags()";
    U5 max 0x1F len */
};
#define BFDIDX_is_bool 3

#define MY_CXT_KEY "builtin::_guts" XS_VERSION

typedef struct {
    SV *empty;
    SV *dollar;
    SV *at;
} my_cxt_t;

START_MY_CXT

XS(XS_builtin_export_lexically);

static const struct BuiltinFuncDescriptor * S_get_builtins_arr();

#define warn_experimental_builtin(builtin) S_warn_experimental_builtin(aTHX_ builtin)
static void S_warn_experimental_builtin(pTHX_
    const struct BuiltinFuncDescriptor * builtin)
{
    const char *name = builtin->name;
    /* diag_listed_as: Built-in function '%s' is experimental */
    Perl_ck_warner_d(aTHX_ packWARN(WARN_EXPERIMENTAL__BUILTIN),
                     "Built-in function 'builtin::%s' is experimental", name);
}

/* These three utilities might want to live elsewhere to be reused from other
 * code sometime
 */
void
Perl_prepare_export_lexical(pTHX)
{
    assert(PL_compcv);

    /* We need to have PL_comppad / PL_curpad set correctly for lexical importing */
    ENTER;
    SAVESPTR(PL_comppad_name); PL_comppad_name = PadlistNAMES(CvPADLIST(PL_compcv));
    SAVECOMPPAD();
    PL_comppad      = PadlistARRAY(CvPADLIST(PL_compcv))[1];
    PL_curpad       = PadARRAY(PL_comppad);
}

#define export_lexical(name, len, sv)  S_export_lexical(aTHX_ name, len, sv)
static void S_export_lexical(pTHX_ const char *name, U32 len, SV *sv)
{
    PADOFFSET off = pad_add_name_pvn(name, len, padadd_STATE, 0, 0);
    SV * old = PL_curpad[off]; /* batch PL_curpad modifications for perf */
    SV * new = sv;
    PL_curpad[off] = new;
    /* _inc() first b/c fn call-free, unrealistic but _dec() throws */
    SvREFCNT_inc_NN(new);
    /* XXX _dec_NN()? Can SV alloc be prevented in S_pad_alloc_name() and
       pad_alloc()? Prevent SvUPGRADE(SVt_PVCV) in pad_add_name_pvn()? */
    SvREFCNT_dec(old);
}

void
Perl_finish_export_lexical(pTHX)
{
    intro_my();

    LEAVE;
}


XS(XS_builtin_true);
XS(XS_builtin_true)
{
    dXSARGS;
    if(items)
        croak_xs_usage(cv, "");
    EXTEND(SP, 1);
    XSRETURN_YES;
}

XS(XS_builtin_false);
XS(XS_builtin_false)
{
    dXSARGS;
    if(items)
        croak_xs_usage(cv, "");
    EXTEND(SP, 1);
    XSRETURN_NO;
}

XS(XS_builtin_inf);
XS(XS_builtin_inf)
{
    dXSARGS;
    if(items)
        croak_xs_usage(cv, "");
    EXTEND(SP, 1);
    XSRETURN_NV(NV_INF);
}

XS(XS_builtin_nan);
XS(XS_builtin_nan)
{
    dXSARGS;
    if(items)
        croak_xs_usage(cv, "");
    EXTEND(SP, 1);
    XSRETURN_NV(NV_NAN);
}

enum {
    BUILTIN_CONST_FALSE,
    BUILTIN_CONST_TRUE,
    BUILTIN_CONST_INF,
    BUILTIN_CONST_NAN,
};

static OP *ck_builtin_const(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    const struct BuiltinFuncDescriptor *builtin = NUM2PTR(const struct BuiltinFuncDescriptor *, SvUVX(ckobj));

    if(UNPACK_IS_EXP(builtin->name_len_f))
        warn_experimental_builtin(builtin);

    assert(entersubop->op_type == OP_ENTERSUB);
    dMY_CXT;
    entersubop = ck_entersub_args_proto(entersubop, namegv, MY_CXT.empty);

    SV *constval;
    switch(builtin->ckval) {
        case BUILTIN_CONST_FALSE: constval = &PL_sv_no; break;
        case BUILTIN_CONST_TRUE:  constval = &PL_sv_yes; break;
        case BUILTIN_CONST_INF:   constval = newSVnv(NV_INF); break;
        case BUILTIN_CONST_NAN:   constval = newSVnv(NV_NAN); break;
        default:
            Perl_die_nocontext(
                     "panic: unrecognised builtin_const value %" IVdf,
                      builtin->ckval);
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
        case OP_IS_BOOL:
            warn_experimental_builtin(&(S_get_builtins_arr()[BFDIDX_is_bool]));
            Perl_pp_is_bool(aTHX);
            break;

        case OP_IS_WEAK:
            Perl_pp_is_weak(aTHX);
            break;

        case OP_BLESSED:
            Perl_pp_blessed(aTHX);
            break;

        case OP_REFADDR:
            Perl_pp_refaddr(aTHX);
            break;

        case OP_REFTYPE:
            Perl_pp_reftype(aTHX);
            break;

        case OP_CEIL:
            Perl_pp_ceil(aTHX);
            break;

        case OP_FLOOR:
            Perl_pp_floor(aTHX);
            break;

        case OP_IS_TAINTED:
            Perl_pp_is_tainted(aTHX);
            break;

        case OP_STRINGIFY:
            {
                /* we could only call pp_stringify if we're sure there is a TARG
                   and if the XSUB is called from call_sv() or goto it may not
                   have one.
                */
                dXSTARG;
                sv_copypv(TARG, *PL_stack_sp);
                SvSETMAGIC(TARG);
                rpp_replace_1_1_NN(TARG);
            }
            break;

        default:
            Perl_die_nocontext("panic: unhandled opcode %" IVdf
                           " for xs_builtin_func1_%s()", (IV) ix, "scalar");
    }

    XSRETURN(1);
}

XS(XS_builtin_trim);
XS(XS_builtin_trim)
{
    dXSARGS;

    if (items != 1) {
        croak_xs_usage(cv, "arg");
    }

    dXSTARG;
    SV *source = TOPs;
    STRLEN len;
    const U8 *start;
    SV *dest;

    SvGETMAGIC(source);

    if (SvOK(source))
        start = (const U8*)SvPV_nomg_const(source, len);
    else {
        if (ckWARN(WARN_UNINITIALIZED))
            report_uninit(source);
        start = (const U8*)"";
        len = 0;
    }

    if (DO_UTF8(source)) {
        const U8 *end = start + len;

        /* Find the first non-space */
        while(len) {
            STRLEN thislen;
            if (!isSPACE_utf8_safe(start, end))
                break;
            start += (thislen = UTF8SKIP(start));
            len -= thislen;
        }

        /* Find the final non-space */
        STRLEN thislen;
        const U8 *cur_end = end;
        while ((thislen = is_SPACE_utf8_safe_backwards(cur_end, start))) {
            cur_end -= thislen;
        }
        len -= (end - cur_end);
    }
    else if (len) {
        while(len) {
            if (!isSPACE_L1(*start))
                break;
            start++;
            len--;
        }

        while(len) {
            if (!isSPACE_L1(start[len-1]))
                break;
            len--;
        }
    }

    dest = TARG;

    if (SvPOK(dest) && (dest == source)) {
        sv_chop(dest, (const char *)start);
        SvCUR_set(dest, len);
    }
    else {
        SvUPGRADE(dest, SVt_PV);
        SvGROW(dest, len + 1);

        Copy(start, SvPVX(dest), len, U8);
        SvPVX(dest)[len] = '\0';
        SvPOK_on(dest);
        SvCUR_set(dest, len);

        if (DO_UTF8(source))
            SvUTF8_on(dest);
        else
            SvUTF8_off(dest);

        if (SvTAINTED(source))
            SvTAINT(dest);
    }

    SvSETMAGIC(dest);

    SETs(dest);

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
            Perl_die_nocontext("panic: unhandled opcode %" IVdf
                           " for xs_builtin_func1_%s()", (IV) ix, "void");
    }

    XSRETURN(0);
}

XS(XS_builtin_created_as_string)
{
    dXSARGS;

    if(items != 1)
        croak_xs_usage(cv, "arg");

    SV *arg = ST(0);
    SvGETMAGIC(arg);

    /* SV was created as string if it has POK and isn't bool */
    ST(0) = boolSV(SvPOK(arg) && !SvIsBOOL(arg));
    XSRETURN(1);
}

XS(XS_builtin_created_as_number)
{
    dXSARGS;

    if(items != 1)
        croak_xs_usage(cv, "arg");

    SV *arg = ST(0);
    SvGETMAGIC(arg);

    /* SV was created as number if it has NOK or IOK but not POK and is not bool */
    ST(0) = boolSV(SvNIOK(arg) && !SvPOK(arg) && !SvIsBOOL(arg));
    XSRETURN(1);
}

static OP *ck_builtin_func1(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{

    const struct BuiltinFuncDescriptor *builtin = NUM2PTR(const struct BuiltinFuncDescriptor *, SvUVX(ckobj));

    if(UNPACK_IS_EXP(builtin->name_len_f))
        warn_experimental_builtin(builtin);

    assert(entersubop->op_type == OP_ENTERSUB);

    dMY_CXT;
    entersubop = ck_entersub_args_proto(entersubop, namegv, MY_CXT.dollar);

    OPCODE opcode = builtin->ckval;
    if(!opcode)
        return entersubop;

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

    if(opcode == OP_STRINGIFY)
        /* Even though pp_stringify only looks at TOPs and conceptually works
         * on a single argument, it happens to be a LISTOP. I've no idea why
         */
        return newLISTOPn(opcode, wantflags,
            argop,
            NULL);
    else {
        OP * const op = newUNOP(opcode, wantflags, argop);

        /* since these pp funcs can be called from XS, and XS may be called
           without a normal ENTERSUB, we need to indicate to them that a targ
           has been allocated.
        */
        if (op->op_targ)
            op->op_private |= OPpENTERSUB_HASTARG;

        return op;
    }
}

XS(XS_builtin_indexed)
{
    dXSARGS;

    switch(GIMME_V) {
        case G_VOID:
            Perl_ck_warner(aTHX_ packWARN(WARN_VOID),
                "Useless use of %s in void context", "builtin::indexed");
            XSRETURN(0);

        case G_SCALAR:
            Perl_ck_warner(aTHX_ packWARN(WARN_SCALAR),
                "Useless use of %s in scalar context", "builtin::indexed");
            ST(0) = sv_2mortal(newSViv(items * 2));
            XSRETURN(1);

        case G_LIST:
            break;
    }

    SSize_t retcount = items * 2;
    EXTEND(SP, retcount);

    /* Copy from [items-1] down to [0] so we don't have to make
     * temporary copies */
    for(SSize_t index = items - 1; index >= 0; index--) {
        /* Copy, not alias */
        ST(index * 2 + 1) = sv_mortalcopy(ST(index));
        ST(index * 2)     = sv_2mortal(newSViv(index));
    }

    XSRETURN(retcount);
}

XS(XS_builtin_load_module);
XS(XS_builtin_load_module)
{
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "arg");
    SV *module_name = newSVsv(ST(0));
    if (!SvPOK(module_name)) {
        SvREFCNT_dec(module_name);
        croak_xs_usage(cv, "defined string");
    }
    load_module(PERL_LOADMOD_NOIMPORT, module_name, NULL, NULL);
    /* The loaded module's name is left intentionally on the stack for the
     * caller's benefit, and becomes load_module's return value. */
    XSRETURN(1);
}

/* These pp_ funcs all need to use dXSTARG */

PP(pp_refaddr)
{
    dXSTARG;
    SV *arg = *PL_stack_sp;

    SvGETMAGIC(arg);

    if(SvROK(arg))
        sv_setuv_mg(TARG, PTR2UV(SvRV(arg)));
    else
        sv_setsv(TARG, &PL_sv_undef);

    rpp_replace_1_1_NN(TARG);
    return NORMAL;
}

PP(pp_reftype)
{
    dXSTARG;
    SV *arg = *PL_stack_sp;

    SvGETMAGIC(arg);

    if(SvROK(arg))
        sv_setpv_mg(TARG, sv_reftype(SvRV(arg), FALSE));
    else
        sv_setsv(TARG, &PL_sv_undef);

    rpp_replace_1_1_NN(TARG);
    return NORMAL;
}

PP(pp_ceil)
{
    dXSTARG;
    TARGn(Perl_ceil(SvNVx(*PL_stack_sp)), 1);
    rpp_replace_1_1_NN(TARG);
    return NORMAL;
}

PP(pp_floor)
{
    dXSTARG;
    TARGn(Perl_floor(SvNVx(*PL_stack_sp)), 1);
    rpp_replace_1_1_NN(TARG);
    return NORMAL;
}

static OP *ck_builtin_funcN(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{

    const struct BuiltinFuncDescriptor *builtin = NUM2PTR(const struct BuiltinFuncDescriptor *, SvUVX(ckobj));

    if(UNPACK_IS_EXP(builtin->name_len_f))
        warn_experimental_builtin(builtin);

    assert(entersubop->op_type == OP_ENTERSUB);
    dMY_CXT;
    entersubop = ck_entersub_args_proto(entersubop, namegv, MY_CXT.at);
    return entersubop;
}

static const char builtin_not_recognised[] = "'%" SVf "' is not recognised as a builtin function";

#define NO_BUNDLE U8_MAX

#if BFDIDX_is_bool == 3
#  undef BFDIDX_is_bool
#  define BFDIDX_is_bool 3
#else
#  error bad BFDIDX_is_bool
#endif
#define BFDIDX_export_lexically 21

static const struct BuiltinFuncDescriptor builtins[] = {
    /* constants */
    { "true", &XS_builtin_true, BUILTIN_CONST_TRUE, PACKVER(5,39), PACKLEN(false, CHKFN_CONST, STRLENs("true"))},
    { "false", &XS_builtin_false, BUILTIN_CONST_FALSE, PACKVER(5,39), PACKLEN(false, CHKFN_CONST, STRLENs("false"))},
    { "inf", &XS_builtin_inf, BUILTIN_CONST_INF, NO_BUNDLE, PACKLEN(true, CHKFN_CONST, STRLENs("inf"))},
    { "nan", &XS_builtin_nan, BUILTIN_CONST_NAN, NO_BUNDLE, PACKLEN(true, CHKFN_CONST, STRLENs("nan"))},

    /* unary functions */
    { "is_bool", &XS_builtin_func1_scalar, OP_IS_BOOL, NO_BUNDLE, PACKLEN(true, CHKFN_FUNC1, STRLENs("is_bool"))},
    { "weaken", &XS_builtin_func1_void, OP_WEAKEN, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("weaken"))},
    { "unweaken", &XS_builtin_func1_void, OP_UNWEAKEN, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("unweaken"))},
    { "is_weak", &XS_builtin_func1_scalar, OP_IS_WEAK, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("is_weak"))},
    { "blessed", &XS_builtin_func1_scalar, OP_BLESSED, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("blessed"))},
    { "refaddr", &XS_builtin_func1_scalar, OP_REFADDR, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("refaddr"))},
    { "reftype", &XS_builtin_func1_scalar, OP_REFTYPE, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("reftype"))},
    { "ceil", &XS_builtin_func1_scalar, OP_CEIL, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("ceil"))},
    { "floor", &XS_builtin_func1_scalar, OP_FLOOR, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("floor"))},
    { "is_tainted", &XS_builtin_func1_scalar, OP_IS_TAINTED, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("is_tainted"))},
    { "trim", &XS_builtin_trim, 0, PACKVER(5,39), PACKLEN(false, CHKFN_FUNC1, STRLENs("trim"))},
    { "stringify", &XS_builtin_func1_scalar, OP_STRINGIFY, NO_BUNDLE, PACKLEN(true, CHKFN_FUNC1, STRLENs("stringify"))},

    { "created_as_string", &XS_builtin_created_as_string, 0, NO_BUNDLE, PACKLEN(true, CHKFN_FUNC1, STRLENs("created_as_string"))},
    { "created_as_number", &XS_builtin_created_as_number, 0, NO_BUNDLE, PACKLEN(true, CHKFN_FUNC1, STRLENs("created_as_number"))},

    { "load_module", &XS_builtin_load_module, 0, NO_BUNDLE, PACKLEN(true, CHKFN_FUNC1, STRLENs("load_module"))},

    /* list functions */
    { "indexed", &XS_builtin_indexed, 0, PACKVER(5,39), PACKLEN(false, CHKFN_FUNCN, STRLENs("indexed"))},
    /* Must be last, or update "export_lexically" XSUB.
      "export_lexically" XSUB depends this being last */
    { "export_lexically", &XS_builtin_export_lexically, 0, NO_BUNDLE, PACKLEN(true, CHKFN_NULLFNPTR, STRLENs("export_lexically"))}
};

static const struct BuiltinFuncDescriptor * S_get_builtins_arr() {
    return &builtins[0];
}

static bool S_parse_version(const char *vstr, const char *vend, UV *vmajor, UV *vminor)
{
    /* Parse a string like "5.35" to yield 5 and 35. Ignores an optional
     * trailing third component e.g. "5.35.7". Returns false on parse errors.
     */

    const char *end = vend;
    if (!grok_atoUV(vstr, vmajor, &end))
        return FALSE;

    vstr = end;
    if (*vstr++ != '.')
        return FALSE;

    end = vend;
    if (!grok_atoUV(vstr, vminor, &end))
        return FALSE;

    if(*vminor > 255)
        return FALSE;

    vstr = end;

    if(vstr[0] == '.') {
        vstr++;

        UV _dummy;
        if(!grok_atoUV(vstr, &_dummy, &end))
            return FALSE;
        if(_dummy > 255)
            return FALSE;

        vstr = end;
    }

    if(vstr != vend)
        return FALSE;

    return TRUE;
}

#define import_sym(fqpv_rw, fqlen)  S_import_sym(aTHX_ fqpv_rw, fqlen)
static void S_import_sym(pTHX_ char * fqpv_rw, U32 fqlen)
{
    CV *cv = get_cvn_flags(fqpv_rw, fqlen, 0);
    /* Make a SVPV, reuse existing format string, branch almost unreachable. */
    if(!cv)
        Perl_croak_nocontext( builtin_not_recognised, newSVpvn_flags(
                                fqpv_rw+STRLENs("builtin::"),
                                fqlen-STRLENs("builtin::")
                              , SVs_TEMP));
    char * ampname = fqpv_rw + STRLENs("builtin::") - STRLENs("&");
    U32 amplen = fqlen-STRLENs("builtin::") + STRLENs("&");
    ampname[0] = '&';
    export_lexical(ampname, amplen, (SV *)cv);
    ampname[0] = ':';
}

#define cv_is_builtin(cv)  S_cv_is_builtin(aTHX_ cv)
static bool S_cv_is_builtin(pTHX_ CV *cv)
{
    char *file = CvFILE(cv);
    return file &&
        (file == __FILE__ || strnEQ(file, __FILE__, sizeof(__FILE__)));
}

void
Perl_import_builtin_bundle(pTHX_ U16 ver)
{
    /* Use Move(), not array initializer, null filling redundant. */
    char name [sizeof("builtin::") + U8_MAX]; /* way oversized */
    char * name_start = name;
    char * name_suffix = name_start + STRLENs("builtin::");
    Move("builtin::", name_start, STRLENs("builtin::"), char);
    U8 ver_u8 = (U8)ver;
    if ((ver >> 8) != 5 || ver_u8 < 39) {
        SV* badver = Perl_newSVpvf_nocontext("%u.%u",
            ((unsigned int)(ver >> 8)),
            ((unsigned int)ver_u8));
        badver = sv_2mortal(badver);
        Perl_croak_nocontext("Invalid version bundle %" SVf_QUOTEDPREFIX, badver);
    }
    ver_u8 -= 39;

    for(int i = 0; i < C_ARRAY_LENGTH(builtins); i++) {
        CV *cv;
        bool got;
        U32 name_len = UNPACK_LEN(builtins[i].name_len_f);
        char * ampname;
        PADOFFSET off;
        Move(builtins[i].name, name_suffix, name_len+1, char);
        ampname = &name_suffix[-1];
        ampname[0] = '&';
        off = pad_findmy_pvn(ampname, STRLENs("&") + name_len, 0);
        ampname[0] = ':';


        if(off != NOT_IN_PAD &&
                SvTYPE((cv = (CV *)PL_curpad[off])) == SVt_PVCV &&
                cv_is_builtin(cv))
            got = true;
        else
            got = false;

        if(!got) {
            bool want = builtins[i].since_ver <= ver_u8;
            if(want)
                import_sym(name_start, STRLENs("builtin::") + name_len);
        }
    }
}

XS(XS_builtin_import);
XS(XS_builtin_import)
{
    if(!PL_compcv)
        Perl_croak_nocontext(
                "builtin::import can only be called at compile time");

    prepare_export_lexical();

    STMT_START {
    /* Use Move(), not array initializer, null filling redundant. */
    char name [sizeof("builtin::") + U8_MAX]; /* way oversized */
    char * name_start = name;
    char * name_suffix = name_start + STRLENs("builtin::");
    Move("builtin::", name_start, STRLENs("builtin::"), char);
    dXSARGS;

    for(int i = 1; i < items; i++) {
        SV *sym = ST(i);
        STRLEN _symlen;
        U32 symlen;
        const char *sympv = SvPV(sym, _symlen);
        if(_symlen >= U8_MAX-1) /* -1 for paranoia, junk input regardless */
            Perl_croak_nocontext(builtin_not_recognised, sym);
        symlen = (U32)_symlen;
        if(memEQs(sympv, symlen, "import"))
            Perl_croak_nocontext(builtin_not_recognised, sym);

        if(sympv[0] == ':') {
            UV vmajor, vminor;
            if(!S_parse_version(sympv + 1, sympv + symlen, &vmajor, &vminor))
                Perl_croak_nocontext("Invalid version bundle %" SVf_QUOTEDPREFIX, sym);

            if(vmajor != 5 ||
               vminor < 39 ||
               vminor - 39 >= 0xFF)
                Perl_croak_nocontext("Builtin version bundle \"%s\" is not supported by Perl " PERL_VERSION_STRING,
                        sympv);
            U16 want_ver = SHORTVER((U8)vmajor, (U8)vminor);
                    /* round up devel version to next major release; e.g. 5.39 => 5.40 */
            if(want_ver > SHORTVER(PERL_REVISION, PERL_VERSION + (PERL_VERSION % 2)))
                Perl_croak_nocontext("Builtin version bundle \"%s\" is not supported by Perl " PERL_VERSION_STRING,
                        sympv);
            import_builtin_bundle(want_ver);

            continue;
        }

        Move(sympv, name_suffix, symlen+1, char);
        import_sym(name_start, STRLENs("builtin::") + symlen);
    }
    } STMT_END;

    finish_export_lexical();
}


XS(XS_builtin_export_lexically)
{
    /* Last element is "export_lexically" */
    warn_experimental_builtin(&builtins[C_ARRAY_LENGTH(builtins)-1]);

    if(!PL_compcv)
        Perl_croak_nocontext(
                "export_lexically can only be called at compile time");

    dXSARGS;
    /* cleaned_svarr is ~1408 bytes w/64b ptrs. 3 separate arrays to stop
       alignment padding, and not permanently stretch C stack too much.
       "Too much" is 4096 bytes/1 VM page. Limit pick as arbitrary and
       capricious, to have a limit. Not b/c previous bugs or perf issues.
       Total stackframe of this XSUB is (8*2*88)+(4*88)+88+1024=2872 bytes.
       All the arrays are very oversized and way beyond sane user input. */
    struct { char * sympv; SV * ref;}
        cleaned_svarr [(C_ARRAY_LENGTH(builtins)+1)*4];
    U32 cleaned_svarr_symlen [C_ARRAY_LENGTH(cleaned_svarr)];
    U8 cleaned_svarr_refmt_name_flag [C_ARRAY_LENGTH(cleaned_svarr)];

    if(items % 2)
        Perl_croak_nocontext("Odd number of elements in export_lexically");
    if((items/2) >= C_ARRAY_LENGTH(cleaned_svarr))
        Perl_croak_nocontext("Too many elements in export_lexically got " UVuf " > " UVuf " limit", items, C_ARRAY_LENGTH(cleaned_svarr) * 2);

    for(int i = 0; i < items; i += 2) {
        SV *name = ST(i);
        SV *ref  = ST(i+1);
        STRLEN name_len;
        char * name_pv;

        if(!SvROK(ref))
            /* diag_listed_as: Expected %s reference in export_lexically */
            Perl_croak_nocontext("Expected a reference in export_lexically");

        SV *rv = SvRV(ref);
        cleaned_svarr[i/2].ref = rv;
        if(!SvPOK(name))
          Perl_croak_nocontext(builtin_not_recognised, name);
        name_len = SvCUR(name);
        if(name_len >= U32_MAX)
            Perl_croak_nocontext(builtin_not_recognised, name);
        cleaned_svarr_symlen[i/2] = (U32)name_len;
        name_pv = SvPVX(name);
        cleaned_svarr[i/2].sympv = name_pv;

        cleaned_svarr_refmt_name_flag[i/2] = 0;
        char sigil = name_pv[0];
        const char *bad = NULL;
        U32 sv_type = SvTYPE(rv);
        switch(sigil) {
            default:
                cleaned_svarr_refmt_name_flag[i/2] = 1;
                /* FALLTHROUGH */
            case '&':
                if(sv_type != SVt_PVCV)
                    bad = "a CODE";
                break;

            case '$':
                /* Permit any of SVt_NULL to SVt_PVMG. Technically this also
                 * includes SVt_INVLIST but it isn't thought possible for pureperl
                 * code to ever manage to see one of those. */
                if(sv_type > SVt_PVMG)
                    bad = "a SCALAR";
                break;

            case '@':
                if(sv_type != SVt_PVAV)
                    bad = "an ARRAY";
                break;

            case '%':
                if(sv_type != SVt_PVHV)
                    bad = "a HASH";
                break;
        }

        if(bad)
            Perl_croak_nocontext("Expected %s reference in export_lexically", bad);
    }

    prepare_export_lexical();

    int pairs = items/2;
    for(int i = 0; i < pairs; i++) {
        char sigil_fix_buf [1024];
        U32 symlen = cleaned_svarr_symlen[i];
        char * sympv = cleaned_svarr[i].sympv;
        if(cleaned_svarr_refmt_name_flag[i]) {
            if(symlen+2 < sizeof(sigil_fix_buf)) {
                char * sigil_fix_p = sigil_fix_buf;
                char * old_src_p = sympv;
                U32 old_src_len = symlen;
                sympv = sigil_fix_p;
                symlen = symlen + 1;
                sigil_fix_p[0] = '&';
                Move(old_src_p, &sigil_fix_p[1], old_src_len+1, char);
            }
            else
                Perl_croak_no_mem_ext("export_lexically sym >= 1022", symlen);
        }
        export_lexical(sympv, symlen, cleaned_svarr[i].ref);
    }

    finish_export_lexical();
}


XS(XS_builtin_CLONE)
{
    dXSARGS;
    MY_CXT_CLONE;
    MY_CXT.empty = newSVpvs_share("");
    MY_CXT.dollar = newSVpvs_share("$");
    MY_CXT.at = newSVpvs_share("@");
}

void
Perl_boot_core_builtin(pTHX)
{
    assert( memEQs(builtins[BFDIDX_is_bool].name,
            UNPACK_LEN(builtins[BFDIDX_is_bool].name_len_f),
            "is_bool")
            && memEQs(builtins[BFDIDX_export_lexically].name,
            UNPACK_LEN(builtins[BFDIDX_export_lexically].name_len_f),
            "export_lexically"));

    MY_CXT_INIT;
    MY_CXT.empty = newSVpvs_share("");
    HEK * empty = SvSHARED_HEK_FROM_PV(SvPVX_const(MY_CXT.empty));
    MY_CXT.dollar = newSVpvs_share("$");
    HEK * dollar =  SvSHARED_HEK_FROM_PV(SvPVX_const(MY_CXT.dollar));
    MY_CXT.at = newSVpvs_share("@");
    HEK * at =  SvSHARED_HEK_FROM_PV(SvPVX_const(MY_CXT.at));
    char name [sizeof("builtin::") + U8_MAX]; /* way oversized */
    char * name_start = name;
    char * name_suffix = name_start + STRLENs("builtin::");
    Move("builtin::", name_start, STRLENs("builtin::"), char);
    I32 i;

    for(i = 0; i < C_ARRAY_LENGTH(builtins); i++) {
        const struct BuiltinFuncDescriptor *builtin = &builtins[i];
        U32 name_suf_len;
        name_suf_len = UNPACK_LEN(builtin->name_len_f);
        Move(builtin->name, name_suffix, name_suf_len+1, char);

        CV *cv = newXS_len_flags(name_start, name_suf_len + STRLENs("builtin::"),
                             builtin->xsub, __FILE__, NULL, NULL, 0);
        XSANY.any_i32 = builtin->ckval;

        if (   builtin->xsub == &XS_builtin_func1_void
            || builtin->xsub == &XS_builtin_func1_scalar)
        {
            /* these XS functions just call out to the relevant pp()
             * functions, so they must operate with a reference-counted
             * stack if the pp() do too.
             */
                CvXS_RCSTACK_on(cv);
        }

        U8 checker = UNPACK_CHKFN(builtin->name_len_f);
        if(checker == CHKFN_CONST)
            sv_sethek((SV*)cv, empty);
        else if(checker == CHKFN_FUNC1)
            sv_sethek((SV*)cv, dollar);
        else if(checker == CHKFN_FUNCN)
            sv_sethek((SV*)cv, at);

        if(checker != CHKFN_NULLFNPTR) {
            OP *(*checkerfn)(pTHX_ OP *, GV *, SV *) =
                checker == CHKFN_CONST ? &ck_builtin_const
                : checker == CHKFN_FUNC1 ? &ck_builtin_func1
                : &ck_builtin_funcN;
            SV * bisv = newSViv(PTR2IV(builtin));
            assert(SvREFCNT(bisv) == 1);
            SvREFCNT(bisv) = 0;
            cv_set_call_checker_flags(cv, checkerfn, bisv, 0);
        }
    }
    /* Skip single use string, "builtin::import"\0 is 16 bytes. Round to 8 chars
       so probably inline to 1 CPU op, "write(U64);". A CC probably will refuse
       to emit "write(U32); write(U16); write(U8);" and call libc instead. */
    Move("import\0", name_suffix, sizeof("import\0"), char);
    newXS_len_flags(name_start, STRLENs("builtin::import"), &XS_builtin_import,
                __FILE__, NULL, NULL, 0);
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
