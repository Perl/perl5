static OP *
THX_ck_entersub_args_lists(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);
    return ck_entersub_args_list(entersubop);
}

static OP *
THX_ck_entersub_args_scalars(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *aop = cUNOPx(entersubop)->op_first;
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);
    if (!OpHAS_SIBLING(aop))
        aop = cUNOPx(aop)->op_first;
    for (aop = OpSIBLING(aop); OpHAS_SIBLING(aop); aop = OpSIBLING(aop)) {
        op_contextualize(aop, G_SCALAR);
    }
    return entersubop;
}

static OP *
THX_ck_entersub_multi_sum(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *sumop = NULL;
    OP *parent = entersubop;
    OP *pushop = cUNOPx(entersubop)->op_first;
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);
    if (!OpHAS_SIBLING(pushop)) {
        parent = pushop;
        pushop = cUNOPx(pushop)->op_first;
    }
    while (1) {
        OP *aop = OpSIBLING(pushop);
        if (!OpHAS_SIBLING(aop))
            break;
        op_sibling_splice(parent, pushop, 1, NULL);
        op_contextualize(aop, G_SCALAR);
        if (sumop) {
            sumop = newBINOP(OP_ADD, 0, sumop, aop);
        } else {
            sumop = aop;
        }
    }
    if (!sumop)
        sumop = newSVOP(OP_CONST, 0, newSViv(0));
    op_free(entersubop);
    return sumop;
}

static void test_op_list_describe_part(SV *res, OP *o);
static void
test_op_list_describe_part(SV *res, OP *o)
{
    sv_catpv(res, PL_op_name[o->op_type]);
    switch (o->op_type) {
        case OP_CONST: {
            sv_catpvf(res, "(%d)", (int)SvIV(cSVOPx(o)->op_sv));
        } break;
    }
    if (o->op_flags & OPf_KIDS) {
        OP *k;
        sv_catpvs(res, "[");
        for (k = cUNOPx(o)->op_first; k; k = OpSIBLING(k))
            test_op_list_describe_part(res, k);
        sv_catpvs(res, "]");
    } else {
        sv_catpvs(res, ".");
    }
}

static char *
test_op_list_describe(OP *o)
{
    SV *res = sv_2mortal(newSVpvs(""));
    if (o)
        test_op_list_describe_part(res, o);
    return SvPVX(res);
}

/* the real new*OP functions have a tendency to call fold_constants, and
 * other such unhelpful things, so we need our own versions for testing */

#define mkUNOP(t, f) THX_mkUNOP(aTHX_ (t), (f))
static OP *
THX_mkUNOP(pTHX_ U32 type, OP *first)
{
    UNOP *unop;
    NewOp(1103, unop, 1, UNOP);
    unop->op_type   = (OPCODE)type;
    op_sibling_splice((OP*)unop, NULL, 0, first);
    return (OP *)unop;
}

#define mkBINOP(t, f, l) THX_mkBINOP(aTHX_ (t), (f), (l))
static OP *
THX_mkBINOP(pTHX_ U32 type, OP *first, OP *last)
{
    BINOP *binop;
    NewOp(1103, binop, 1, BINOP);
    binop->op_type      = (OPCODE)type;
    op_sibling_splice((OP*)binop, NULL, 0, last);
    op_sibling_splice((OP*)binop, NULL, 0, first);
    return (OP *)binop;
}

#define mkLISTOP(t, f, s, l) THX_mkLISTOP(aTHX_ (t), (f), (s), (l))
static OP *
THX_mkLISTOP(pTHX_ U32 type, OP *first, OP *sib, OP *last)
{
    LISTOP *listop;
    NewOp(1103, listop, 1, LISTOP);
    listop->op_type     = (OPCODE)type;
    op_sibling_splice((OP*)listop, NULL, 0, last);
    op_sibling_splice((OP*)listop, NULL, 0, sib);
    op_sibling_splice((OP*)listop, NULL, 0, first);
    return (OP *)listop;
}

static char *
test_op_linklist_describe(OP *start)
{
    SV *rv = sv_2mortal(newSVpvs(""));
    OP *o;
    o = start = LINKLIST(start);
    do {
        sv_catpvs(rv, ".");
        sv_catpv(rv, OP_NAME(o));
        if (o->op_type == OP_CONST)
            sv_catsv(rv, cSVOPo->op_sv);
        o = o->op_next;
    } while (o && o != start);
    return SvPVX(rv);
}

static void
THX_run_cleanup(pTHX_ void *cleanup_code_ref)
{
    dSP;
    PUSHSTACK;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    call_sv((SV*)cleanup_code_ref, G_VOID|G_DISCARD);
    FREETMPS;
    LEAVE;
    POPSTACK;
}

static OP *
THX_pp_establish_cleanup(pTHX)
{
    SV *cleanup_code_ref;
    cleanup_code_ref = newSVsv(*PL_stack_sp);
    rpp_popfree_1();
    SAVEFREESV(cleanup_code_ref);
    SAVEDESTRUCTOR_X(THX_run_cleanup, cleanup_code_ref);
    if(GIMME_V != G_VOID)
        rpp_push_1(&PL_sv_undef);
    return NORMAL;
    ;
}

static OP *
THX_ck_entersub_establish_cleanup(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *parent, *pushop, *argop, *estop;
    ck_entersub_args_proto(entersubop, namegv, ckobj);
    parent = entersubop;
    pushop = cUNOPx(entersubop)->op_first;
    if(!OpHAS_SIBLING(pushop)) {
        parent = pushop;
        pushop = cUNOPx(pushop)->op_first;
    }
    argop = OpSIBLING(pushop);
    op_sibling_splice(parent, pushop, 1, NULL);
    op_free(entersubop);

    estop = mkUNOP(OP_RAND, argop);
    estop->op_ppaddr = THX_pp_establish_cleanup;
    PL_hints |= HINT_BLOCK_SCOPE;
    return estop;
}

static OP *
THX_ck_entersub_postinc(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *parent, *pushop, *argop;
    ck_entersub_args_proto(entersubop, namegv, ckobj);
    parent = entersubop;
    pushop = cUNOPx(entersubop)->op_first;
    if(!OpHAS_SIBLING(pushop)) {
        parent = pushop;
        pushop = cUNOPx(pushop)->op_first;
    }
    argop = OpSIBLING(pushop);
    op_sibling_splice(parent, pushop, 1, NULL);
    op_free(entersubop);
    return newUNOP(OP_POSTINC, 0,
        op_lvalue(op_contextualize(argop, G_SCALAR), OP_POSTINC));
}

static OP *
THX_ck_entersub_pad_scalar(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *pushop, *argop;
    PADOFFSET padoff = NOT_IN_PAD;
    SV *a0, *a1;
    ck_entersub_args_proto(entersubop, namegv, ckobj);
    pushop = cUNOPx(entersubop)->op_first;
    if(!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    if(argop->op_type != OP_CONST || OpSIBLING(argop)->op_type != OP_CONST)
        croak("bad argument expression type for pad_scalar()");
    a0 = cSVOPx_sv(argop);
    a1 = cSVOPx_sv(OpSIBLING(argop));
    switch(SvIV(a0)) {
        case 1: {
            SV *namesv = sv_2mortal(newSVpvs("$"));
            sv_catsv(namesv, a1);
            padoff = pad_findmy_sv(namesv, 0);
        } break;
        case 2: {
            char *namepv;
            STRLEN namelen;
            SV *namesv = sv_2mortal(newSVpvs("$"));
            sv_catsv(namesv, a1);
            namepv = SvPV(namesv, namelen);
            padoff = pad_findmy_pvn(namepv, namelen, SvUTF8(namesv));
        } break;
        case 3: {
            char *namepv;
            SV *namesv = sv_2mortal(newSVpvs("$"));
            sv_catsv(namesv, a1);
            namepv = SvPV_nolen(namesv);
            padoff = pad_findmy_pv(namepv, SvUTF8(namesv));
        } break;
        case 4: {
            padoff = pad_findmy_pvs("$foo", 0);
        } break;
        default: croak("bad type value for pad_scalar()");
    }
    op_free(entersubop);
    if(padoff == NOT_IN_PAD) {
        return newSVOP(OP_CONST, 0, newSVpvs("NOT_IN_PAD"));
    } else if(PAD_COMPNAME_FLAGS_isOUR(padoff)) {
        return newSVOP(OP_CONST, 0, newSVpvs("NOT_MY"));
    } else {
        OP *padop = newOP(OP_PADSV, 0);
        padop->op_targ = padoff;
        return padop;
    }
}
