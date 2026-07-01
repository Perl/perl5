void
test_op_list()
    PREINIT:
        OP *a;
    CODE:
#define iv_op(iv) newSVOP(OP_CONST, 0, newSViv(iv))
#define check_op(o, expect) \
    do { \
        if (strNE(test_op_list_describe(o), (expect))) \
            croak("fail %s %s", test_op_list_describe(o), (expect)); \
    } while(0)
        a = op_append_elem(OP_LIST, NULL, NULL);
        check_op(a, "");
        a = op_append_elem(OP_LIST, iv_op(1), a);
        check_op(a, "const(1).");
        a = op_append_elem(OP_LIST, NULL, a);
        check_op(a, "const(1).");
        a = op_append_elem(OP_LIST, a, iv_op(2));
        check_op(a, "list[pushmark.const(1).const(2).]");
        a = op_append_elem(OP_LIST, a, iv_op(3));
        check_op(a, "list[pushmark.const(1).const(2).const(3).]");
        a = op_append_elem(OP_LIST, a, NULL);
        check_op(a, "list[pushmark.const(1).const(2).const(3).]");
        a = op_append_elem(OP_LIST, NULL, a);
        check_op(a, "list[pushmark.const(1).const(2).const(3).]");
        a = op_append_elem(OP_LIST, iv_op(4), a);
        check_op(a, "list[pushmark.const(4)."
                "list[pushmark.const(1).const(2).const(3).]]");
        a = op_append_elem(OP_LIST, a, iv_op(5));
        check_op(a, "list[pushmark.const(4)."
                "list[pushmark.const(1).const(2).const(3).]const(5).]");
        a = op_append_elem(OP_LIST, a,
                op_append_elem(OP_LIST, iv_op(7), iv_op(6)));
        check_op(a, "list[pushmark.const(4)."
                "list[pushmark.const(1).const(2).const(3).]const(5)."
                "list[pushmark.const(7).const(6).]]");
        op_free(a);
        a = op_append_elem(OP_LINESEQ, iv_op(1), iv_op(2));
        check_op(a, "lineseq[const(1).const(2).]");
        a = op_append_elem(OP_LINESEQ, a, iv_op(3));
        check_op(a, "lineseq[const(1).const(2).const(3).]");
        op_free(a);
        a = op_append_elem(OP_LINESEQ,
                op_append_elem(OP_LIST, iv_op(1), iv_op(2)),
                iv_op(3));
        check_op(a, "lineseq[list[pushmark.const(1).const(2).]const(3).]");
        op_free(a);
        a = op_prepend_elem(OP_LIST, NULL, NULL);
        check_op(a, "");
        a = op_prepend_elem(OP_LIST, a, iv_op(1));
        check_op(a, "const(1).");
        a = op_prepend_elem(OP_LIST, a, NULL);
        check_op(a, "const(1).");
        a = op_prepend_elem(OP_LIST, iv_op(2), a);
        check_op(a, "list[pushmark.const(2).const(1).]");
        a = op_prepend_elem(OP_LIST, iv_op(3), a);
        check_op(a, "list[pushmark.const(3).const(2).const(1).]");
        a = op_prepend_elem(OP_LIST, NULL, a);
        check_op(a, "list[pushmark.const(3).const(2).const(1).]");
        a = op_prepend_elem(OP_LIST, a, NULL);
        check_op(a, "list[pushmark.const(3).const(2).const(1).]");
        a = op_prepend_elem(OP_LIST, a, iv_op(4));
        check_op(a, "list[pushmark."
                "list[pushmark.const(3).const(2).const(1).]const(4).]");
        a = op_prepend_elem(OP_LIST, iv_op(5), a);
        check_op(a, "list[pushmark.const(5)."
                "list[pushmark.const(3).const(2).const(1).]const(4).]");
        a = op_prepend_elem(OP_LIST,
                op_prepend_elem(OP_LIST, iv_op(6), iv_op(7)), a);
        check_op(a, "list[pushmark.list[pushmark.const(6).const(7).]const(5)."
                "list[pushmark.const(3).const(2).const(1).]const(4).]");
        op_free(a);
        a = op_prepend_elem(OP_LINESEQ, iv_op(2), iv_op(1));
        check_op(a, "lineseq[const(2).const(1).]");
        a = op_prepend_elem(OP_LINESEQ, iv_op(3), a);
        check_op(a, "lineseq[const(3).const(2).const(1).]");
        op_free(a);
        a = op_prepend_elem(OP_LINESEQ, iv_op(3),
                op_prepend_elem(OP_LIST, iv_op(2), iv_op(1)));
        check_op(a, "lineseq[const(3).list[pushmark.const(2).const(1).]]");
        op_free(a);
        a = op_append_list(OP_LINESEQ, NULL, NULL);
        check_op(a, "");
        a = op_append_list(OP_LINESEQ, iv_op(1), a);
        check_op(a, "const(1).");
        a = op_append_list(OP_LINESEQ, NULL, a);
        check_op(a, "const(1).");
        a = op_append_list(OP_LINESEQ, a, iv_op(2));
        check_op(a, "lineseq[const(1).const(2).]");
        a = op_append_list(OP_LINESEQ, a, iv_op(3));
        check_op(a, "lineseq[const(1).const(2).const(3).]");
        a = op_append_list(OP_LINESEQ, iv_op(4), a);
        check_op(a, "lineseq[const(4).const(1).const(2).const(3).]");
        a = op_append_list(OP_LINESEQ, a, NULL);
        check_op(a, "lineseq[const(4).const(1).const(2).const(3).]");
        a = op_append_list(OP_LINESEQ, NULL, a);
        check_op(a, "lineseq[const(4).const(1).const(2).const(3).]");
        a = op_append_list(OP_LINESEQ, a,
                op_append_list(OP_LINESEQ, iv_op(5), iv_op(6)));
        check_op(a, "lineseq[const(4).const(1).const(2).const(3)."
                "const(5).const(6).]");
        op_free(a);
        a = op_append_list(OP_LINESEQ,
                op_append_list(OP_LINESEQ, iv_op(1), iv_op(2)),
                op_append_list(OP_LIST, iv_op(3), iv_op(4)));
        check_op(a, "lineseq[const(1).const(2)."
                "list[pushmark.const(3).const(4).]]");
        op_free(a);
        a = op_append_list(OP_LINESEQ,
                op_append_list(OP_LIST, iv_op(1), iv_op(2)),
                op_append_list(OP_LINESEQ, iv_op(3), iv_op(4)));
        check_op(a, "lineseq[list[pushmark.const(1).const(2).]"
                "const(3).const(4).]");
        op_free(a);
#undef check_op

void
test_op_linklist ()
    PREINIT:
        OP *o;
    CODE:
#define check_ll(o, expect) \
    STMT_START { \
        if (strNE(test_op_linklist_describe(o), (expect))) \
            croak("fail %s %s", test_op_linklist_describe(o), (expect)); \
    } STMT_END
        o = iv_op(1);
        check_ll(o, ".const1");
        op_free(o);

        o = mkUNOP(OP_NOT, iv_op(1));
        check_ll(o, ".const1.not");
        op_free(o);

        o = mkUNOP(OP_NOT, mkUNOP(OP_NEGATE, iv_op(1)));
        check_ll(o, ".const1.negate.not");
        op_free(o);

        o = mkBINOP(OP_ADD, iv_op(1), iv_op(2));
        check_ll(o, ".const1.const2.add");
        op_free(o);

        o = mkBINOP(OP_ADD, mkUNOP(OP_NOT, iv_op(1)), iv_op(2));
        check_ll(o, ".const1.not.const2.add");
        op_free(o);

        o = mkUNOP(OP_NOT, mkBINOP(OP_ADD, iv_op(1), iv_op(2)));
        check_ll(o, ".const1.const2.add.not");
        op_free(o);

        o = mkLISTOP(OP_LINESEQ, iv_op(1), iv_op(2), iv_op(3));
        check_ll(o, ".const1.const2.const3.lineseq");
        op_free(o);

        o = mkLISTOP(OP_LINESEQ,
                mkBINOP(OP_ADD, iv_op(1), iv_op(2)),
                mkUNOP(OP_NOT, iv_op(3)),
                mkLISTOP(OP_SUBSTR, iv_op(4), iv_op(5), iv_op(6)));
        check_ll(o, ".const1.const2.add.const3.not"
                    ".const4.const5.const6.substr.lineseq");
        op_free(o);

        o = mkBINOP(OP_ADD, iv_op(1), iv_op(2));
        LINKLIST(o);
        o = mkBINOP(OP_SUBTRACT, o, iv_op(3));
        check_ll(o, ".const1.const2.add.const3.subtract");
        op_free(o);
#undef check_ll
#undef iv_op

void
peep_enable ()
    PREINIT:
        dMY_CXT;
    CODE:
        av_clear(MY_CXT.peep_recorder);
        av_clear(MY_CXT.rpeep_recorder);
        MY_CXT.peep_recording = 1;

void
peep_disable ()
    PREINIT:
        dMY_CXT;
    CODE:
        MY_CXT.peep_recording = 0;

SV *
peep_record ()
    PREINIT:
        dMY_CXT;
    CODE:
        RETVAL = newRV_inc((SV *)MY_CXT.peep_recorder);
    OUTPUT:
        RETVAL

SV *
rpeep_record ()
    PREINIT:
        dMY_CXT;
    CODE:
        RETVAL = newRV_inc((SV *)MY_CXT.rpeep_recorder);
    OUTPUT:
        RETVAL

=pod

multicall_each: call a sub for each item in the list. Used to test MULTICALL

=cut

void
multicall_each(block,...)
    SV * block
PROTOTYPE: &@
CODE:
{
    dMULTICALL;
    int index;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    CV *cv;

    if(items <= 1) {
        XSRETURN_UNDEF;
    }
    cv = sv_2cv(block, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("multicall_each: not a subroutine reference");
    }
    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    for(index = 1 ; index < items ; index++) {
        GvSV(PL_defgv) = args[index];
        MULTICALL;
    }
    POP_MULTICALL;
    XSRETURN_UNDEF;
}

=pod

multicall_return(): call the passed sub once in the specificed context
and return whatever it returns

=cut

void
multicall_return(block, context)
    SV *block
    I32 context
PROTOTYPE: &$
PPCODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = context;
    CV *cv;
    AV *av = NULL;
    SV **p;
    SSize_t i, size;

    cv = sv_2cv(block, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("multicall_return not a subroutine reference");
    }
    PUSH_MULTICALL(cv);

    MULTICALL;

    /* copy returned values into an array so they're not freed during
     * POP_MULTICALL */

    SPAGAIN;

    switch (context) {
    case G_VOID:
        av = newAV();
        break;

    case G_SCALAR:
        av = newAV_alloc_x(1);
        av_push_simple(av, SvREFCNT_inc(TOPs));
        break;

    case G_LIST:
        av = (SP - PL_stack_base)
                ? newAV_alloc_xz(SP - PL_stack_base)
                : newAV();
        for (p = PL_stack_base + 1; p <= SP; p++)
            av_push_simple(av, SvREFCNT_inc(*p));
        break;

    default:
        croak("multicall_return: invalid context %" I32df, context);
    }

    POP_MULTICALL;

    size = AvFILLp(av) + 1;
    EXTEND(SP, size);
    for (i = 0; i < size; i++)
        PUSHs(*av_fetch_simple(av, i, FALSE));
    sv_2mortal((SV*)av);
}
