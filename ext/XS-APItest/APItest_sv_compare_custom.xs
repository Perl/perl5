TYPEMAP: <<HERE

nullable_SV	T_NULLABLE_SV

INPUT

T_NULLABLE_SV
    $var = $arg == &PL_sv_undef ? NULL : $arg;

HERE

bool
sv_numeq(nullable_SV sv1, nullable_SV sv2)
    CODE:
        RETVAL = sv_numeq(sv1, sv2);
    OUTPUT:
        RETVAL

bool
sv_numeq_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)
    CODE:
        RETVAL = sv_numeq_flags(sv1, sv2, flags);
    OUTPUT:
        RETVAL

# deliberately void context
void
void_sv_numeq(nullable_SV sv1, nullable_SV sv2, SV *out)
    CODE:
        sv_setbool(out, sv_numeq(sv1, sv2));
    OUTPUT:
        out

bool
sv_numne(nullable_SV sv1, nullable_SV sv2)

# deliberately void context
void
void_sv_numne(nullable_SV sv1, nullable_SV sv2, SV *out)
    CODE:
        sv_setbool(out, sv_numne(sv1, sv2));
    OUTPUT:
        out

bool
sv_numne_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)

I32
sv_numcmp(nullable_SV sv1, nullable_SV sv2)

I32
sv_numcmp_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)

bool
sv_numle(nullable_SV sv1, nullable_SV sv2)

bool
sv_numle_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)

bool
sv_numlt(nullable_SV sv1, nullable_SV sv2)

bool
sv_numlt_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)

bool
sv_numge(nullable_SV sv1, nullable_SV sv2)

bool
sv_numge_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)

bool
sv_numgt(nullable_SV sv1, nullable_SV sv2)

bool
sv_numgt_flags(nullable_SV sv1, nullable_SV sv2, U32 flags)

bool
sv_streq(SV *sv1, SV *sv2)
    CODE:
        RETVAL = sv_streq(sv1, sv2);
    OUTPUT:
        RETVAL

bool
sv_streq_flags(SV *sv1, SV *sv2, U32 flags)
    CODE:
        RETVAL = sv_streq_flags(sv1, sv2, flags);
    OUTPUT:
        RETVAL

void
set_custom_pp_func(sv)
    SV *sv;
    PPCODE:
        /* replace the pp func of the next op */
        OP* o = PL_op->op_next;
        if (o->op_type == OP_ADD)
            o->op_ppaddr = my_pp_add;
        else if (o->op_type == OP_ANONLIST)
            o->op_ppaddr = my_pp_anonlist;
        else
            croak("set_custom_pp_func: op_next is not an OP_ADD\n");

        /* the single SV arg is passed through */
        PERL_UNUSED_ARG(sv);
        XSRETURN(1);

void
set_xs_rc_stack(cv, sv)
    CV *cv;
    SV *sv;
    PPCODE:
        /* set or undet the CVf_XS_RCSTACK flag on the CV */
        assert(SvTYPE(cv) == SVt_PVCV);
        if (SvTRUE(sv))
            CvXS_RCSTACK_on(cv);
        else
            CvXS_RCSTACK_off(cv);
        XSRETURN(0);

void
rc_add(sv1, sv2)
    SV *sv1;
    SV *sv2;
    PPCODE:
        /* Do the XS equivalent of pp_add(), while expecting a
         * reference-counted stack */

        /* manipulate the stack directly */
        PERL_UNUSED_ARG(sv1);
        PERL_UNUSED_ARG(sv2);
        SV *r = newSViv(SvIV(PL_stack_sp[-1]) + SvIV(PL_stack_sp[0]));
        rpp_replace_2_1(r);
        return;

void
modify_pv(IV pi, IV sz)
    PPCODE:
        /* used by op/pack.t when testing pack "p" */
        memset(INT2PTR(char *, pi), 'y', sz);

STRLEN
sv_regex_global_pos_get(SV *sv, U32 flags = 0)
    CODE:
        if(!sv_regex_global_pos_get(sv, &RETVAL, flags))
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

void
sv_regex_global_pos_set(SV *sv, STRLEN pos, U32 flags = 0)

void
sv_regex_global_pos_clear(SV *sv)

SV *
newSVpvf_blank()
    CODE:
        GCC_DIAG_IGNORE_STMT(-Wformat-zero-length);
        RETVAL = newSVpvf("");
        GCC_DIAG_RESTORE_STMT;
    OUTPUT:
        RETVAL
