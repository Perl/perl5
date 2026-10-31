/*
 * ex: set ts=8 sts=4 sw=4 et:
 */

#define PERL_IN_XS_APITEST

/* We want to be able to test things that aren't API yet. */
#define PERL_EXT

/* Do *not* define PERL_NO_GET_CONTEXT.  This is the one place where we get
   to test implicit Perl_get_context().  */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
 * MAINTAINER NOTE
 *
 * This file is intentionally limited to the shared scaffolding for
 * XS::APItest:
 *
 *   - global/shared C helpers used by multiple XS split files
 *   - MY_CXT definition and initialization
 *   - keyword-parser/plugin support that is tightly coupled to this file
 *   - top-level BOOT/CLONE setup that must remain centralized
 *   - other deeply shared or structurally central code that would become
 *     less clear if spread across multiple files
 *
 * Most test-facing XSUBs should not be added here directly.
 * Prefer adding new code in a domain-specific file such as:
 *
 *   ext/XS-APItest/APItest_*.xs
 *
 * Shared helper code that is reused by multiple split files should usually
 * live in a small, focused include file:
 *
 *   ext/XS-APItest/APItest_*.inc
 *
 * Guidelines:
 *
 *   - keep files domain-focused rather than growing a general dump file
 *   - prefer low-coupling splits; leave tightly coupled parser/setup code here
 *   - search for "Include Files Go Here" for the C and XS insertion points
 *   - if adding a new file, update MANIFEST and run make manisort
 *   - ensure changes work under root-level:
 *         make test
 *         make test_harness TEST_FILES='...'
 *   - when splitting code, preserve test coverage and test effectiveness
 *
 * The goal is to keep XS::APItest navigable, so it is easier to judge
 * completeness and easier to determine where new tests and helpers belong.
 */

/* PERL_VERSION_xx sanity checks */
#if !PERL_VERSION_EQ(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, PERL_VERSION_PATCH)
#  error PERL_VERSION_EQ(major, minor, patch) is false; expected true
#endif
#if !PERL_VERSION_EQ(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, '*')
#  error PERL_VERSION_EQ(major, minor, '*') is false; expected true
#endif
#if PERL_VERSION_NE(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, PERL_VERSION_PATCH)
#  error PERL_VERSION_NE(major, minor, patch) is true; expected false
#endif
#if PERL_VERSION_NE(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, '*')
#  error PERL_VERSION_NE(major, minor, '*') is true; expected false
#endif
#if PERL_VERSION_LT(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, PERL_VERSION_PATCH)
#  error PERL_VERSION_LT(major, minor, patch) is true; expected false
#endif
#if PERL_VERSION_LT(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, '*')
#  error PERL_VERSION_LT(major, minor, '*') is true; expected false
#endif
#if !PERL_VERSION_LE(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, PERL_VERSION_PATCH)
#  error PERL_VERSION_LE(major, minor, patch) is false; expected true
#endif
#if !PERL_VERSION_LE(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, '*')
#  error PERL_VERSION_LE(major, minor, '*') is false; expected true
#endif
#if PERL_VERSION_GT(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, PERL_VERSION_PATCH)
#  error PERL_VERSION_GT(major, minor, patch) is true; expected false
#endif
#if PERL_VERSION_GT(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, '*')
#  error PERL_VERSION_GT(major, minor, '*') is true; expected false
#endif
#if !PERL_VERSION_GE(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, PERL_VERSION_PATCH)
#  error PERL_VERSION_GE(major, minor, patch) is false; expected true
#endif
#if !PERL_VERSION_GE(PERL_VERSION_MAJOR, PERL_VERSION_MINOR, '*')
#  error PERL_VERSION_GE(major, minor, '*') is false; expected true
#endif

typedef FILE NativeFile;

#include "fakesdio.h"   /* Causes us to use PerlIO below */

typedef SV *SVREF;
typedef PTR_TBL_t *XS__APItest__PtrTable;
typedef PerlIO * InputStream;
typedef PerlIO * OutputStream;

#define croak_fail() croak("fail at " __FILE__ " line %d", __LINE__)
#define croak_fail_nep(h, w) croak("fail %p!=%p at " __FILE__ " line %d", (h), (w), __LINE__)
#define croak_fail_nei(h, w) croak("fail %d!=%d at " __FILE__ " line %d", (int)(h), (int)(w), __LINE__)

/* assumes that there is a 'failed' variable in scope */
#define TEST_EXPR(s) STMT_START {           \
    if (s) {                                \
        printf("# ok: %s\n", #s);           \
    } else {                                \
        printf("# not ok: %s\n", #s);       \
        failed++;                           \
    }                                       \
} STMT_END

#if IVSIZE == 8
#  define TEST_64BIT 1
#else
#  define TEST_64BIT 0
#endif

#ifdef EBCDIC

void
cat_utf8a2n(SV* sv, const char * const ascii_utf8, STRLEN len)
{
    /* Converts variant UTF-8 text pointed to by 'ascii_utf8' of length 'len',
     * to UTF-EBCDIC, appending that text to the text already in 'sv'.
     * Currently doesn't work on invariants, as that is unneeded here, and we
     * could get double translations if we did.
     *
     * It has the algorithm for strict UTF-8 hard-coded in to find the code
     * point it represents, then calls uvchr_to_utf8() to convert to
     * UTF-EBCDIC).
     *
     * Note that this uses code points, not characters.  Thus if the input is
     * the UTF-8 for the code point 0xFF, the output will be the UTF-EBCDIC for
     * 0xFF, even though that code point represents different characters on
     * ASCII vs EBCDIC platforms. */

    dTHX;
    char * p = (char *) ascii_utf8;
    const char * const e = p + len;

    while (p < e) {
        UV code_point;
        U8 native_utf8[UTF8_MAXBYTES + 1];
        U8 * char_end;
        U8 start = (U8) *p;

        /* Start bytes are the same in both UTF-8 and I8, therefore we can
         * treat this ASCII UTF-8 byte as an I8 byte.  But PL_utf8skip[] is
         * indexed by NATIVE_UTF8 bytes, so transform to that */
        STRLEN char_bytes_len = PL_utf8skip[I8_TO_NATIVE_UTF8(start)];

        if (start < 0xc2) {
            croak("fail: Expecting start byte, instead got 0x%X at %s line %d",
                                                  (U8) *p, __FILE__, __LINE__);
        }
        code_point = (start & (((char_bytes_len) >= 7)
                                ? 0x00
                                : (0x1F >> ((char_bytes_len)-2))));
        p++;
        while (p < e && ((( (U8) *p) & 0xC0) == 0x80)) {

            code_point = (code_point << 6) | (( (U8) *p) & 0x3F);
            p++;
        }

        char_end = uvchr_to_utf8(native_utf8, code_point);
        sv_catpvn(sv, (char *) native_utf8, char_end - native_utf8);
    }
}

#endif

/* for my_cxt tests */

#define MY_CXT_KEY "XS::APItest::_guts" XS_VERSION

typedef struct {
    int i;
    SV *sv;
    GV *cscgv;
    AV *cscav;
    AV *bhkav;
    bool bhk_record;
    peep_t orig_peep;
    peep_t orig_rpeep;
    int peep_recording;
    AV *peep_recorder;
    AV *rpeep_recorder;
    AV *xop_record;
} my_cxt_t;

START_MY_CXT

/* C Include Files Go Here - shared C support includes for split XS::APItest domains. */
#include "APItest_magic_hash_support.inc"

#include "APItest_magicv2.inc"

#include "APItest_lexical_attributes.inc"

/* indirect functions to test the [pa]MY_CXT macros */

int
my_cxt_getint_p(pMY_CXT)
{
    return MY_CXT.i;
}

void
my_cxt_setint_p(pMY_CXT_ int i)
{
    MY_CXT.i = i;
}

SV*
my_cxt_getsv_interp_context(void)
{
    dTHX;
    dMY_CXT_INTERP(my_perl);
    return MY_CXT.sv;
}

SV*
my_cxt_getsv_interp(void)
{
    dMY_CXT;
    return MY_CXT.sv;
}

void
my_cxt_setsv_p(SV* sv _pMY_CXT)
{
    MY_CXT.sv = sv;
}


/* from exception.c */
int apitest_exception(int);

/* from core_or_not.inc */
bool sv_setsv_cow_hashkey_core(void);
bool sv_setsv_cow_hashkey_notcore(void);

static void
blockhook_csc_start(pTHX_ int full)
{
    dMY_CXT;
    AV *const cur = GvAV(MY_CXT.cscgv);

    PERL_UNUSED_ARG(full);
    SAVEGENERICSV(GvAV(MY_CXT.cscgv));

    if (cur) {
        Size_t i;
        AV *const new_av = av_count(cur)
                        ? newAV_alloc_x(av_count(cur))
                        : newAV();

        for (i = 0; i < av_count(cur); i++) {
            av_store_simple(new_av, i, newSVsv(*av_fetch(cur, i, 0)));
        }

        GvAV(MY_CXT.cscgv) = new_av;
    }
}

static void
blockhook_csc_pre_end(pTHX_ OP **o)
{
    dMY_CXT;

    PERL_UNUSED_ARG(o);
    /* if we hit the end of a scope we missed the start of, we need to
     * unconditionally clear @CSC */
    if (GvAV(MY_CXT.cscgv) == MY_CXT.cscav && MY_CXT.cscav) {
        av_clear(MY_CXT.cscav);
    }

}

static void
blockhook_test_start(pTHX_ int full)
{
    dMY_CXT;
    AV *av;

    if (MY_CXT.bhk_record) {
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVpvs("start"));
        av_push_simple(av, newSViv(full));
        av_push_simple(MY_CXT.bhkav, newRV_noinc(MUTABLE_SV(av)));
    }
}

static void
blockhook_test_pre_end(pTHX_ OP **o)
{
    dMY_CXT;

    PERL_UNUSED_ARG(o);
    if (MY_CXT.bhk_record)
        av_push(MY_CXT.bhkav, newSVpvs("pre_end"));
}

static void
blockhook_test_post_end(pTHX_ OP **o)
{
    dMY_CXT;

    PERL_UNUSED_ARG(o);
    if (MY_CXT.bhk_record)
        av_push(MY_CXT.bhkav, newSVpvs("post_end"));
}

static void
blockhook_test_eval(pTHX_ OP *const o)
{
    dMY_CXT;
    AV *av;

    if (MY_CXT.bhk_record) {
        av = newAV_alloc_x(3);
        av_push_simple(av, newSVpvs("eval"));
        av_push_simple(av, newSVpv(OP_NAME(o), 0));
        av_push_simple(MY_CXT.bhkav, newRV_noinc(MUTABLE_SV(av)));
    }
}

static BHK bhk_csc, bhk_test;

static void
my_peep (pTHX_ OP *o)
{
    dMY_CXT;

    if (!o)
        return;

    MY_CXT.orig_peep(aTHX_ o);

    if (!MY_CXT.peep_recording)
        return;

    for (; o; o = o->op_next) {
        if (o->op_type == OP_CONST && cSVOPx_sv(o) && SvPOK(cSVOPx_sv(o))) {
            av_push(MY_CXT.peep_recorder, newSVsv(cSVOPx_sv(o)));
        }
    }
}

static void
my_rpeep (pTHX_ OP *first)
{
    dMY_CXT;
    OP *o, *t;

    if (!first)
        return;

    MY_CXT.orig_rpeep(aTHX_ first);

    if (!MY_CXT.peep_recording)
        return;

    for (o = first, t = first; o; o = o->op_next, t = t->op_next) {
        if (o->op_type == OP_CONST && cSVOPx_sv(o) && SvPOK(cSVOPx_sv(o))) {
            av_push(MY_CXT.rpeep_recorder, newSVsv(cSVOPx_sv(o)));
        }
        o = o->op_next;
        if (!o || o == t) break;
        if (o->op_type == OP_CONST && cSVOPx_sv(o) && SvPOK(cSVOPx_sv(o))) {
            av_push(MY_CXT.rpeep_recorder, newSVsv(cSVOPx_sv(o)));
        }
    }
}

#include "APItest_optree_support.inc"

/** RPN keyword parser **/

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)
#define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#define sv_is_string(sv) \
    (!sv_is_glob(sv) && !sv_is_regexp(sv) && \
     (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

static SV *hintkey_rpn_sv, *hintkey_calcrpn_sv, *hintkey_stufftest_sv;
static SV *hintkey_swaptwostmts_sv, *hintkey_looprest_sv;
static SV *hintkey_scopelessblock_sv;
static SV *hintkey_stmtasexpr_sv, *hintkey_stmtsasexpr_sv;
static SV *hintkey_loopblock_sv, *hintkey_blockasexpr_sv;
static SV *hintkey_swaplabel_sv, *hintkey_labelconst_sv;
static SV *hintkey_arrayfullexpr_sv, *hintkey_arraylistexpr_sv;
static SV *hintkey_arraytermexpr_sv, *hintkey_arrayarithexpr_sv;
static SV *hintkey_arrayexprflags_sv;
static SV *hintkey_subsignature_sv;
static SV *hintkey_DEFSV_sv;
static SV *hintkey_with_vars_sv;
static SV *hintkey_join_with_space_sv;
static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

/* low-level parser helpers */

#define PL_bufptr (PL_parser->bufptr)
#define PL_bufend (PL_parser->bufend)

/* RPN parser */

#define parse_var() THX_parse_var(aTHX)
static OP *THX_parse_var(pTHX)
{
    char *s = PL_bufptr;
    char *start = s;
    PADOFFSET varpos;
    OP *padop;
    if(*s != '$') croak("RPN syntax error");
    while(1) {
        char c = *++s;
        if(!isALNUM(c)) break;
    }
    if(s-start < 2) croak("RPN syntax error");
    lex_read_to(s);
    varpos = pad_findmy_pvn(start, s-start, 0);
    if(varpos == NOT_IN_PAD || PAD_COMPNAME_FLAGS_isOUR(varpos))
        croak("RPN only supports \"my\" variables");
    padop = newOP(OP_PADSV, 0);
    padop->op_targ = varpos;
    return padop;
}

#define push_rpn_item(o) \
    op_sibling_splice(parent, NULL, 0, o);
#define pop_rpn_item() ( \
    (tmpop = op_sibling_splice(parent, NULL, 1, NULL)) \
        ? tmpop : (croak("RPN stack underflow"), (OP*)NULL))

#define parse_rpn_expr() THX_parse_rpn_expr(aTHX)
static OP *THX_parse_rpn_expr(pTHX)
{
    OP *tmpop;
    /* fake parent for splice to mess with */
    OP *parent = mkBINOP(OP_NULL, NULL, NULL);

    while(1) {
        I32 c;
        lex_read_space(0);
        c = lex_peek_unichar(0);
        switch(c) {
            case /*(*/')': case /*{*/'}': {
                OP *result = pop_rpn_item();
                if(cLISTOPx(parent)->op_first)
                    croak("RPN expression must return a single value");
                op_free(parent);
                return result;
            } break;
            case '0': case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9': {
                UV val = 0;
                do {
                    lex_read_unichar(0);
                    val = 10*val + (c - '0');
                    c = lex_peek_unichar(0);
                } while(c >= '0' && c <= '9');
                push_rpn_item(newSVOP(OP_CONST, 0, newSVuv(val)));
            } break;
            case '$': {
                push_rpn_item(parse_var());
            } break;
            case '+': {
                OP *b = pop_rpn_item();
                OP *a = pop_rpn_item();
                lex_read_unichar(0);
                push_rpn_item(newBINOP(OP_I_ADD, 0, a, b));
            } break;
            case '-': {
                OP *b = pop_rpn_item();
                OP *a = pop_rpn_item();
                lex_read_unichar(0);
                push_rpn_item(newBINOP(OP_I_SUBTRACT, 0, a, b));
            } break;
            case '*': {
                OP *b = pop_rpn_item();
                OP *a = pop_rpn_item();
                lex_read_unichar(0);
                push_rpn_item(newBINOP(OP_I_MULTIPLY, 0, a, b));
            } break;
            case '/': {
                OP *b = pop_rpn_item();
                OP *a = pop_rpn_item();
                lex_read_unichar(0);
                push_rpn_item(newBINOP(OP_I_DIVIDE, 0, a, b));
            } break;
            case '%': {
                OP *b = pop_rpn_item();
                OP *a = pop_rpn_item();
                lex_read_unichar(0);
                push_rpn_item(newBINOP(OP_I_MODULO, 0, a, b));
            } break;
            default: {
                croak("RPN syntax error");
            } break;
        }
    }
}

#define parse_keyword_rpn() THX_parse_keyword_rpn(aTHX)
static OP *THX_parse_keyword_rpn(pTHX)
{
    OP *op;
    lex_read_space(0);
    if(lex_peek_unichar(0) != '('/*)*/)
        croak("RPN expression must be parenthesised");
    lex_read_unichar(0);
    op = parse_rpn_expr();
    if(lex_peek_unichar(0) != /*(*/')')
        croak("RPN expression must be parenthesised");
    lex_read_unichar(0);
    return op;
}

#define parse_keyword_calcrpn() THX_parse_keyword_calcrpn(aTHX)
static OP *THX_parse_keyword_calcrpn(pTHX)
{
    OP *varop, *exprop;
    lex_read_space(0);
    varop = parse_var();
    lex_read_space(0);
    if(lex_peek_unichar(0) != '{'/*}*/)
        croak("RPN expression must be braced");
    lex_read_unichar(0);
    exprop = parse_rpn_expr();
    if(lex_peek_unichar(0) != /*{*/'}')
        croak("RPN expression must be braced");
    lex_read_unichar(0);
    return newASSIGNOP(OPf_STACKED, varop, 0, exprop);
}

#define parse_keyword_stufftest() THX_parse_keyword_stufftest(aTHX)
static OP *THX_parse_keyword_stufftest(pTHX)
{
    I32 c;
    bool do_stuff;
    lex_read_space(0);
    do_stuff = lex_peek_unichar(0) == '+';
    if(do_stuff) {
        lex_read_unichar(0);
        lex_read_space(0);
    }
    c = lex_peek_unichar(0);
    if(c == ';') {
        lex_read_unichar(0);
    } else if(c != /*{*/'}') {
        croak("syntax error");
    }
    if(do_stuff) lex_stuff_pvs(" ", 0);
    return newOP(OP_NULL, 0);
}

#define parse_keyword_swaptwostmts() THX_parse_keyword_swaptwostmts(aTHX)
static OP *THX_parse_keyword_swaptwostmts(pTHX)
{
    OP *a, *b;
    a = parse_fullstmt(0);
    b = parse_fullstmt(0);
    if(a && b)
        PL_hints |= HINT_BLOCK_SCOPE;
    return op_append_list(OP_LINESEQ, b, a);
}

#define parse_keyword_looprest() THX_parse_keyword_looprest(aTHX)
static OP *THX_parse_keyword_looprest(pTHX)
{
    return newWHILEOP(0, 1, NULL, newSVOP(OP_CONST, 0, &PL_sv_yes),
                        parse_stmtseq(0), NULL, 1);
}

#define parse_keyword_scopelessblock() THX_parse_keyword_scopelessblock(aTHX)
static OP *THX_parse_keyword_scopelessblock(pTHX)
{
    I32 c;
    OP *body;
    lex_read_space(0);
    if(lex_peek_unichar(0) != '{'/*}*/) croak("syntax error");
    lex_read_unichar(0);
    body = parse_stmtseq(0);
    c = lex_peek_unichar(0);
    if(c != /*{*/'}' && c != /*[*/']' && c != /*(*/')') croak("syntax error");
    lex_read_unichar(0);
    return body;
}

#define parse_keyword_stmtasexpr() THX_parse_keyword_stmtasexpr(aTHX)
static OP *THX_parse_keyword_stmtasexpr(pTHX)
{
    OP *o = parse_barestmt(0);
    if (!o) o = newOP(OP_STUB, 0);
    if (PL_hints & HINT_BLOCK_SCOPE) o->op_flags |= OPf_PARENS;
    return op_scope(o);
}

#define parse_keyword_stmtsasexpr() THX_parse_keyword_stmtsasexpr(aTHX)
static OP *THX_parse_keyword_stmtsasexpr(pTHX)
{
    OP *o;
    lex_read_space(0);
    if(lex_peek_unichar(0) != '{'/*}*/) croak("syntax error");
    lex_read_unichar(0);
    o = parse_stmtseq(0);
    lex_read_space(0);
    if(lex_peek_unichar(0) != /*{*/'}') croak("syntax error");
    lex_read_unichar(0);
    if (!o) o = newOP(OP_STUB, 0);
    if (PL_hints & HINT_BLOCK_SCOPE) o->op_flags |= OPf_PARENS;
    return op_scope(o);
}

#define parse_keyword_loopblock() THX_parse_keyword_loopblock(aTHX)
static OP *THX_parse_keyword_loopblock(pTHX)
{
    return newWHILEOP(0, 1, NULL, newSVOP(OP_CONST, 0, &PL_sv_yes),
                        parse_block(0), NULL, 1);
}

#define parse_keyword_blockasexpr() THX_parse_keyword_blockasexpr(aTHX)
static OP *THX_parse_keyword_blockasexpr(pTHX)
{
    OP *o = parse_block(0);
    if (!o) o = newOP(OP_STUB, 0);
    if (PL_hints & HINT_BLOCK_SCOPE) o->op_flags |= OPf_PARENS;
    return op_scope(o);
}

#define parse_keyword_swaplabel() THX_parse_keyword_swaplabel(aTHX)
static OP *THX_parse_keyword_swaplabel(pTHX)
{
    OP *sop = parse_barestmt(0);
    SV *label = parse_label(PARSE_OPTIONAL);
    if (label) sv_2mortal(label);
    return newSTATEOP(label ? SvUTF8(label) : 0,
                      label ? savepv(SvPVX(label)) : NULL,
                      sop);
}

#define parse_keyword_labelconst() THX_parse_keyword_labelconst(aTHX)
static OP *THX_parse_keyword_labelconst(pTHX)
{
    return newSVOP(OP_CONST, 0, parse_label(0));
}

#define parse_keyword_arrayfullexpr() THX_parse_keyword_arrayfullexpr(aTHX)
static OP *THX_parse_keyword_arrayfullexpr(pTHX)
{
    return newANONLIST(parse_fullexpr(0));
}

#define parse_keyword_arraylistexpr() THX_parse_keyword_arraylistexpr(aTHX)
static OP *THX_parse_keyword_arraylistexpr(pTHX)
{
    return newANONLIST(parse_listexpr(0));
}

#define parse_keyword_arraytermexpr() THX_parse_keyword_arraytermexpr(aTHX)
static OP *THX_parse_keyword_arraytermexpr(pTHX)
{
    return newANONLIST(parse_termexpr(0));
}

#define parse_keyword_arrayarithexpr() THX_parse_keyword_arrayarithexpr(aTHX)
static OP *THX_parse_keyword_arrayarithexpr(pTHX)
{
    return newANONLIST(parse_arithexpr(0));
}

#define parse_keyword_arrayexprflags() THX_parse_keyword_arrayexprflags(aTHX)
static OP *THX_parse_keyword_arrayexprflags(pTHX)
{
    U32 flags = 0;
    I32 c;
    OP *o;
    lex_read_space(0);
    c = lex_peek_unichar(0);
    if (c != '!' && c != '?') croak("syntax error");
    lex_read_unichar(0);
    if (c == '?') flags |= PARSE_OPTIONAL;
    o = parse_listexpr(flags);
    return o ? newANONLIST(o) : newANONHASH(newOP(OP_STUB, 0));
}

#define parse_keyword_subsignature() THX_parse_keyword_subsignature(aTHX)
static OP *THX_parse_keyword_subsignature(pTHX)
{
    OP *retop = NULL, *listop, *sigop = parse_subsignature(0);
    OP *kid;
    int seen_nextstate = 0;

    /* We can't yield the optree as is to the caller because it won't be
     * executable outside of a called sub. We'll have to convert it into
     * something safe for them to invoke.
     * sigop should be an OP_NULL above a OP_LINESEQ containing
     * OP_NEXTSTATE-separated OP_ARGCHECK and OP_ARGELEMs
     */
    if(sigop->op_type != OP_NULL)
        croak("Expected parse_subsignature() to yield an OP_NULL");

    if(!(sigop->op_flags & OPf_KIDS))
        croak("Expected parse_subsignature() to yield an OP_NULL with kids");
    listop = cUNOPx(sigop)->op_first;

    if(listop->op_type != OP_LINESEQ)
        croak("Expected parse_subsignature() to yield an OP_LINESEQ");

    for(kid = cLISTOPx(listop)->op_first; kid; kid = OpSIBLING(kid)) {
        switch(kid->op_type) {
            case OP_NEXTSTATE:
                /* Only emit the first one otherwise they get boring */
                if(seen_nextstate)
                    break;
                seen_nextstate++;
                retop = op_append_list(OP_LIST, retop, newSVOP(OP_CONST, 0,
                    /* newSVpvf("nextstate:%s:%d", CopFILE(cCOPx(kid)), cCOPx(kid)->cop_line))); */
                    newSVpvf("nextstate:%" LINE_Tf, CopLINE(cCOPx(kid)))));
                break;
            case OP_ARGCHECK: {
                struct op_argcheck_aux *p =
                    (struct op_argcheck_aux*)(cUNOP_AUXx(kid)->op_aux);
                retop = op_append_list(OP_LIST, retop, newSVOP(OP_CONST, 0,
                    newSVpvf("argcheck:%" UVuf ":%" UVuf ":%c",
                            p->params, p->opt_params,
                            p->slurpy ? p->slurpy : '-')));
                break;
            }
            case OP_ARGELEM: {
                PADOFFSET padix = kid->op_targ;
                PADNAMELIST *names = PadlistNAMES(CvPADLIST(find_runcv(0)));
                char *namepv = PadnamePV(padnamelist_fetch(names, padix));
                retop = op_append_list(OP_LIST, retop, newSVOP(OP_CONST, 0,
                    newSVpvf(kid->op_flags & OPf_KIDS ? "argelem:%s:d" : "argelem:%s", namepv)));
                break;
            }
            case OP_MULTIPARAM: {
                struct op_multiparam_aux *p =
                    (struct op_multiparam_aux *)(cUNOP_AUXx(kid)->op_aux);
                PADNAMELIST *names = PadlistNAMES(CvPADLIST(find_runcv(0)));
                SV *retsv = newSVpvf("multiparam:%zu..%zu:%c",
                        p->min_args, p->n_positional, p->slurpy ? p->slurpy : '-');
                for (size_t paramidx = 0; paramidx < p->n_positional; paramidx++) {
                    char *namepv = PadnamePV(padnamelist_fetch(names, p->param_padix[paramidx]));
                    if(namepv)
                        sv_catpvf(retsv, ":%s=%zu", namepv, paramidx);
                    else
                        sv_catpvf(retsv, ":(anon)=%zu", paramidx);
                    if(paramidx >= p->min_args)
                        sv_catpvs(retsv, "?");
                }
                if (p->slurpy_padix)
                    sv_catpvf(retsv, ":%s=*",
                        PadnamePV(padnamelist_fetch(names, p->slurpy_padix)));
                retop = op_append_list(OP_LIST, retop, newSVOP(OP_CONST, 0, retsv));
                break;
            }
        }
    }

    op_free(sigop);
    return newANONLIST(retop);
}

#define parse_keyword_DEFSV() THX_parse_keyword_DEFSV(aTHX)
static OP *THX_parse_keyword_DEFSV(pTHX)
{
    return newDEFSVOP();
}

#define sv_cat_c(a,b) THX_sv_cat_c(aTHX_ a, b)
static void THX_sv_cat_c(pTHX_ SV *sv, U32 c) {
    char ds[UTF8_MAXBYTES + 1], *d;
    d = (char *)uvchr_to_utf8((U8 *)ds, c);
    if (d - ds > 1) {
        sv_utf8_upgrade(sv);
    }
    sv_catpvn(sv, ds, d - ds);
}

#define parse_keyword_with_vars() THX_parse_keyword_with_vars(aTHX)
static OP *THX_parse_keyword_with_vars(pTHX)
{
    I32 c;
    IV count;
    int save_ix;
    OP *vardeclseq, *body;

    save_ix = block_start(TRUE);
    vardeclseq = NULL;

    count = 0;

    lex_read_space(0);
    c = lex_peek_unichar(0);
    while (c != '{') {
        SV *varname;
        PADOFFSET padoff;

        if (c == -1) {
            croak("unexpected EOF; expecting '{'");
        }

        if (!isIDFIRST_uni(c)) {
            croak("unexpected '%c'; expecting an identifier", (int)c);
        }

        varname = newSVpvs("$");
        if (lex_bufutf8()) {
            SvUTF8_on(varname);
        }

        sv_cat_c(varname, c);
        lex_read_unichar(0);

        while (c = lex_peek_unichar(0), c != -1 && isIDCONT_uni(c)) {
            sv_cat_c(varname, c);
            lex_read_unichar(0);
        }

        padoff = pad_add_name_sv(varname, padadd_NO_DUP_CHECK, NULL, NULL);

        {
            OP *my_var = newOP(OP_PADSV, OPf_MOD | (OPpLVAL_INTRO << 8));
            my_var->op_targ = padoff;

            vardeclseq = op_append_list(
                OP_LINESEQ,
                vardeclseq,
                newSTATEOP(
                    0, NULL,
                    newASSIGNOP(
                        OPf_STACKED,
                        my_var, 0,
                        newSVOP(
                            OP_CONST, 0,
                            newSViv(++count)
                        )
                    )
                )
            );
        }

        lex_read_space(0);
        c = lex_peek_unichar(0);
    }

    intro_my();

    body = parse_block(0);

    return block_end(save_ix, op_append_list(OP_LINESEQ, vardeclseq, body));
}

#define parse_join_with_space() THX_parse_join_with_space(aTHX)
static OP *THX_parse_join_with_space(pTHX)
{
    OP *delim, *args;

    args = parse_listexpr(0);
    delim = newSVOP(OP_CONST, 0, newSVpvs(" "));
    return op_convert_list(OP_JOIN, 0, op_prepend_elem(OP_LIST, delim, args));
}

/* plugin glue */

#define keyword_active(hintkey_sv) THX_keyword_active(aTHX_ hintkey_sv)
static int THX_keyword_active(pTHX_ SV *hintkey_sv)
{
    HE *he;
    if(!GvHV(PL_hintgv)) return 0;
    he = hv_fetch_ent(GvHV(PL_hintgv), hintkey_sv, 0,
                SvSHARED_HASH(hintkey_sv));
    return he && SvTRUE(HeVAL(he));
}

static int my_keyword_plugin(pTHX_
    char *keyword_ptr, STRLEN keyword_len, OP **op_ptr)
{
    if (memEQs(keyword_ptr, keyword_len, "rpn") &&
                    keyword_active(hintkey_rpn_sv)) {
        *op_ptr = parse_keyword_rpn();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "calcrpn") &&
                    keyword_active(hintkey_calcrpn_sv)) {
        *op_ptr = parse_keyword_calcrpn();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "stufftest") &&
                    keyword_active(hintkey_stufftest_sv)) {
        *op_ptr = parse_keyword_stufftest();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "swaptwostmts") &&
                    keyword_active(hintkey_swaptwostmts_sv)) {
        *op_ptr = parse_keyword_swaptwostmts();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "looprest") &&
                    keyword_active(hintkey_looprest_sv)) {
        *op_ptr = parse_keyword_looprest();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "scopelessblock") &&
                    keyword_active(hintkey_scopelessblock_sv)) {
        *op_ptr = parse_keyword_scopelessblock();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "stmtasexpr") &&
                    keyword_active(hintkey_stmtasexpr_sv)) {
        *op_ptr = parse_keyword_stmtasexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "stmtsasexpr") &&
                    keyword_active(hintkey_stmtsasexpr_sv)) {
        *op_ptr = parse_keyword_stmtsasexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "loopblock") &&
                    keyword_active(hintkey_loopblock_sv)) {
        *op_ptr = parse_keyword_loopblock();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "blockasexpr") &&
                    keyword_active(hintkey_blockasexpr_sv)) {
        *op_ptr = parse_keyword_blockasexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "swaplabel") &&
                    keyword_active(hintkey_swaplabel_sv)) {
        *op_ptr = parse_keyword_swaplabel();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "labelconst") &&
                    keyword_active(hintkey_labelconst_sv)) {
        *op_ptr = parse_keyword_labelconst();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "arrayfullexpr") &&
                    keyword_active(hintkey_arrayfullexpr_sv)) {
        *op_ptr = parse_keyword_arrayfullexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "arraylistexpr") &&
                    keyword_active(hintkey_arraylistexpr_sv)) {
        *op_ptr = parse_keyword_arraylistexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "arraytermexpr") &&
                    keyword_active(hintkey_arraytermexpr_sv)) {
        *op_ptr = parse_keyword_arraytermexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "arrayarithexpr") &&
                    keyword_active(hintkey_arrayarithexpr_sv)) {
        *op_ptr = parse_keyword_arrayarithexpr();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "arrayexprflags") &&
                    keyword_active(hintkey_arrayexprflags_sv)) {
        *op_ptr = parse_keyword_arrayexprflags();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "DEFSV") &&
                    keyword_active(hintkey_DEFSV_sv)) {
        *op_ptr = parse_keyword_DEFSV();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "with_vars") &&
                    keyword_active(hintkey_with_vars_sv)) {
        *op_ptr = parse_keyword_with_vars();
        return KEYWORD_PLUGIN_STMT;
    } else if (memEQs(keyword_ptr, keyword_len, "join_with_space") &&
                    keyword_active(hintkey_join_with_space_sv)) {
        *op_ptr = parse_join_with_space();
        return KEYWORD_PLUGIN_EXPR;
    } else if (memEQs(keyword_ptr, keyword_len, "subsignature") &&
                    keyword_active(hintkey_subsignature_sv)) {
        *op_ptr = parse_keyword_subsignature();
        return KEYWORD_PLUGIN_EXPR;
    } else {
        assert(next_keyword_plugin != my_keyword_plugin);
        return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }
}

#include "APItest_runtime_support.inc"


#include "const-c.inc"

typedef SV *nullable_SV;

/* XS Include Files Go Here - domain-specific XS splits begin in the MODULE section below. */
MODULE = XS::APItest            PACKAGE = XS::APItest

INCLUDE: const-xs.inc

INCLUDE: numeric.xs

INCLUDE: APItest_misc_xsub_basics.xs

INCLUDE: APItest_utf8.xs

INCLUDE: APItest_overload.xs

INCLUDE: APItest_xsub_handshake.xs


INCLUDE: APItest_hash.xs

INCLUDE: APItest_temp_lv.xs

INCLUDE: APItest_ptr_table.xs

INCLUDE: APItest_autoload.xs

INCLUDE: APItest_xop_blockhooks.xs

INCLUDE: APItest_call_dispatch.xs

INCLUDE: APItest_runtime_hooks.xs

INCLUDE: APItest_optree_cophh.xs

INCLUDE: APItest_optree_multicall.xs

INCLUDE: APItest_runtime_helpers.xs

INCLUDE: APItest_runtime_utils.xs

INCLUDE: APItest_sv_compare_custom.xs

INCLUDE: APItest_autoloadtest.xs

INCLUDE: APItest_magic.xs

INCLUDE: APItest_unicode_charclass.xs

INCLUDE: APItest_unicode_utf8.xs

INCLUDE: APItest_unicode_case.xs

INCLUDE: APItest_misc_runtime.xs

INCLUDE: APItest_backrefs.xs

INCLUDE: APItest_rwmacro.xs

INCLUDE: APItest_hv_macro.xs

INCLUDE: APItest_bool_internals.xs

INCLUDE: APItest_cv_refcounted_anysv.xs

INCLUDE: APItest_global_locale.xs

INCLUDE: APItest_savestack.xs

INCLUDE: APItest_vstring.xs

INCLUDE: APItest_magicv2.xs

INCLUDE: APItest_lexical_attributes.xs
