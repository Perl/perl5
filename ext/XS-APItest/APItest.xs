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

static int
S_myset_set(pTHX_ SV* sv, MAGIC* mg)
{
    SV *isv = (SV*)mg->mg_ptr;

    PERL_UNUSED_ARG(sv);
    SvIVX(isv)++;
    return 0;
}

static int
S_myset_set_dies(pTHX_ SV* sv, MAGIC* mg)
{
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(mg);
    croak("in S_myset_set_dies");
    return 0;
}


static MGVTBL vtbl_foo, vtbl_bar;
static MGVTBL vtbl_myset = { 0, S_myset_set, 0, 0, 0, 0, 0, 0 };
static MGVTBL vtbl_myset_dies = { 0, S_myset_set_dies, 0, 0, 0, 0, 0, 0 };

static int
S_mycopy_copy(pTHX_ SV *sv, MAGIC* mg, SV *nsv, const char *name, I32 namlen) {
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(nsv);
    PERL_UNUSED_ARG(name);
    PERL_UNUSED_ARG(namlen);

    /* Count that we were called to "copy".
       There's actually no point in copying *this* magic onto nsv, as it's a
       SCALAR, whereas mg_copy is only triggered for ARRAYs and HASHes.
       It's not *exactly* generic. :-( */
    ++mg->mg_private;
    return 0;
}

static MGVTBL vtbl_mycopy = { 0, 0, 0, 0, 0, S_mycopy_copy, 0, 0 };

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

/* A routine to test hv_delayfree_ent
   (which itself is tested by testing on hv_free_ent  */

typedef void (freeent_function)(pTHX_ HV *, HE *);

void
test_freeent(freeent_function *f) {
    dSP;
    HV *test_hash = newHV();
    HE *victim;
    SV *test_scalar;
    U32 results[4];
    int i;

#ifdef PURIFY
    victim = (HE*)safemalloc(sizeof(HE));
#else
    /* Storing then deleting something should ensure that a hash entry is
       available.  */
    (void) hv_stores(test_hash, "", &PL_sv_yes);
    (void) hv_deletes(test_hash, "", 0);

    /* We need to "inline" new_he here as it's static, and the functions we
       test expect to be able to call del_HE on the HE  */
    if (!PL_body_roots[HE_ARENA_ROOT_IX])
        croak("PL_he_root is 0");
    victim = (HE*) PL_body_roots[HE_ARENA_ROOT_IX];
    PL_body_roots[HE_ARENA_ROOT_IX] = HeNEXT(victim);
#endif

#ifdef NODEFAULT_SHAREKEYS
    HvSHAREKEYS_on(test_hash);
#endif

    victim->hent_hek = Perl_share_hek(aTHX_ "", 0, 0);

    test_scalar = newSV(0);
    SvREFCNT_inc(test_scalar);
    HeVAL(victim) = test_scalar;

    /* Need this little game else we free the temps on the return stack.  */
    results[0] = SvREFCNT(test_scalar);
    SAVETMPS;
    results[1] = SvREFCNT(test_scalar);
    f(aTHX_ test_hash, victim);
    results[2] = SvREFCNT(test_scalar);
    FREETMPS;
    results[3] = SvREFCNT(test_scalar);

    i = 0;
    do {
        mXPUSHu(results[i]);
    } while (++i < (int)(sizeof(results)/sizeof(results[0])));

    /* Goodbye to our extra reference.  */
    SvREFCNT_dec(test_scalar);
}

/* Not that it matters much, but it's handy for the flipped character to just
 * be the opposite case (at least for ASCII-range and most Latin1 as well). */
#define FLIP_BIT ('A' ^ 'a')

static I32
bitflip_key(pTHX_ IV action, SV *field) {
    MAGIC *mg = mg_find(field, PERL_MAGIC_uvar);
    SV *keysv;
    PERL_UNUSED_ARG(action);
    if (mg && (keysv = mg->mg_obj)) {
        STRLEN len;
        const char *p = SvPV(keysv, len);

        if (len) {
            /* Allow for the flipped val to be longer than the original.  This
             * is just for testing, so can afford to have some slop */
            const STRLEN newlen = len * 2;

            SV *newkey = newSV(newlen);
            const char * const new_p_orig = SvPVX(newkey);
            char *new_p = (char *) new_p_orig;

            if (SvUTF8(keysv)) {
                const char *const end = p + len;
                while (p < end) {
                    STRLEN curlen;
                    UV chr = utf8_to_uvchr_buf((U8 *)p, (U8 *) end, &curlen);

                    /* Make sure don't exceed bounds */
                    assert(new_p - new_p_orig + curlen < newlen);

                    new_p = (char *)uvchr_to_utf8((U8 *)new_p, chr ^ FLIP_BIT);
                    p += curlen;
                }
                SvUTF8_on(newkey);
            } else {
                while (len--)
                    *new_p++ = *p++ ^ FLIP_BIT;
            }
            *new_p = '\0';
            SvCUR_set(newkey, new_p - new_p_orig);
            SvPOK_on(newkey);

            mg->mg_obj = newkey;
        }
    }
    return 0;
}

static I32
rot13_key(pTHX_ IV action, SV *field) {
    MAGIC *mg = mg_find(field, PERL_MAGIC_uvar);
    SV *keysv;
    PERL_UNUSED_ARG(action);
    if (mg && (keysv = mg->mg_obj)) {
        STRLEN len;
        const char *p = SvPV(keysv, len);

        if (len) {
            SV *newkey = newSV(len);
            char *new_p = SvPVX(newkey);

            /* There's a deliberate fencepost error here to loop len + 1 times
               to copy the trailing \0  */
            do {
                char new_c = *p++;
                /* Try doing this cleanly and clearly in EBCDIC another way: */
                switch (new_c) {
                case 'A': new_c = 'N'; break;
                case 'B': new_c = 'O'; break;
                case 'C': new_c = 'P'; break;
                case 'D': new_c = 'Q'; break;
                case 'E': new_c = 'R'; break;
                case 'F': new_c = 'S'; break;
                case 'G': new_c = 'T'; break;
                case 'H': new_c = 'U'; break;
                case 'I': new_c = 'V'; break;
                case 'J': new_c = 'W'; break;
                case 'K': new_c = 'X'; break;
                case 'L': new_c = 'Y'; break;
                case 'M': new_c = 'Z'; break;
                case 'N': new_c = 'A'; break;
                case 'O': new_c = 'B'; break;
                case 'P': new_c = 'C'; break;
                case 'Q': new_c = 'D'; break;
                case 'R': new_c = 'E'; break;
                case 'S': new_c = 'F'; break;
                case 'T': new_c = 'G'; break;
                case 'U': new_c = 'H'; break;
                case 'V': new_c = 'I'; break;
                case 'W': new_c = 'J'; break;
                case 'X': new_c = 'K'; break;
                case 'Y': new_c = 'L'; break;
                case 'Z': new_c = 'M'; break;
                case 'a': new_c = 'n'; break;
                case 'b': new_c = 'o'; break;
                case 'c': new_c = 'p'; break;
                case 'd': new_c = 'q'; break;
                case 'e': new_c = 'r'; break;
                case 'f': new_c = 's'; break;
                case 'g': new_c = 't'; break;
                case 'h': new_c = 'u'; break;
                case 'i': new_c = 'v'; break;
                case 'j': new_c = 'w'; break;
                case 'k': new_c = 'x'; break;
                case 'l': new_c = 'y'; break;
                case 'm': new_c = 'z'; break;
                case 'n': new_c = 'a'; break;
                case 'o': new_c = 'b'; break;
                case 'p': new_c = 'c'; break;
                case 'q': new_c = 'd'; break;
                case 'r': new_c = 'e'; break;
                case 's': new_c = 'f'; break;
                case 't': new_c = 'g'; break;
                case 'u': new_c = 'h'; break;
                case 'v': new_c = 'i'; break;
                case 'w': new_c = 'j'; break;
                case 'x': new_c = 'k'; break;
                case 'y': new_c = 'l'; break;
                case 'z': new_c = 'm'; break;
                }
                *new_p++ = new_c;
            } while (len--);
            SvCUR_set(newkey, SvCUR(keysv));
            SvPOK_on(newkey);
            if (SvUTF8(keysv))
                SvUTF8_on(newkey);

            mg->mg_obj = newkey;
        }
    }
    return 0;
}

static I32
rmagical_a_dummy(pTHX_ IV idx, SV *sv) {
    PERL_UNUSED_ARG(idx);
    PERL_UNUSED_ARG(sv);
    return 0;
}

/* We could do "= { 0 };" but some versions of gcc do warn
 * (with -Wextra) about missing initializer, this is probably gcc
 * being a bit too paranoid.  But since this is file-static, we can
 * just have it without initializer, since it should get
 * zero-initialized. */
static MGVTBL rmagical_b;

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
        /* cut out first arg */
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

/** establish_cleanup operator, ripped off from Scope::Cleanup **/

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

/* Note that this is a pp function attached to an OP */

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
    /* extract out first arg, then delete the rest of the tree */
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

static XOP my_xop;

static OP *
pp_xop(pTHX)
{
    return PL_op->op_next;
}

static void
peep_xop(pTHX_ OP *o, OP *oldop)
{
    dMY_CXT;
    av_push(MY_CXT.xop_record, newSVpvf("peep:%" UVxf, PTR2UV(o)));
    av_push(MY_CXT.xop_record, newSVpvf("oldop:%" UVxf, PTR2UV(oldop)));
}

static I32
filter_call(pTHX_ int idx, SV *buf_sv, int maxlen)
{
    char *p;
    char *end;
    int n = FILTER_READ(idx + 1, buf_sv, maxlen);

    if (n<=0) return n;

    p = SvPV_force_nolen(buf_sv);
    end = p + SvCUR(buf_sv);
    while (p < end) {
        if (*p == 'o') *p = 'e';
        p++;
    }
    return SvCUR(buf_sv);
}

static AV *
myget_linear_isa(pTHX_ HV *stash, U32 level) {
    GV **gvp = (GV **)hv_fetchs(stash, "ISA", 0);
    PERL_UNUSED_ARG(level);
    return gvp && *gvp && GvAV(*gvp)
         ? GvAV(*gvp)
         : newAV_mortal();
}


XS_EXTERNAL(XS_XS__APItest__XSUB_XS_VERSION_undef);
XS_EXTERNAL(XS_XS__APItest__XSUB_XS_VERSION_empty);
XS_EXTERNAL(XS_XS__APItest__XSUB_XS_APIVERSION_invalid);

static struct mro_alg mymro;

static Perl_check_t addissub_nxck_add;

static OP *
addissub_myck_add(pTHX_ OP *op)
{
    SV **flag_svp = hv_fetchs(GvHV(PL_hintgv), "XS::APItest/addissub", 0);
    OP *aop, *bop;
    U8 flags;
    if (!(flag_svp && SvTRUE(*flag_svp) && (op->op_flags & OPf_KIDS) &&
            (aop = cBINOPx(op)->op_first) && (bop = OpSIBLING(aop)) &&
            !OpHAS_SIBLING(bop)))
        return addissub_nxck_add(aTHX_ op);
    flags = op->op_flags;
    op_sibling_splice(op, NULL, 1, NULL); /* excise aop */
    op_sibling_splice(op, NULL, 1, NULL); /* excise bop */
    op_free(op); /* free the empty husk */
    flags &= ~OPf_KIDS;
    return newBINOP(OP_SUBTRACT, flags, aop, bop);
}

static Perl_check_t old_ck_rv2cv;

static OP *
my_ck_rv2cv(pTHX_ OP *o)
{
    SV *ref;
    SV **flag_svp = hv_fetchs(GvHV(PL_hintgv), "XS::APItest/addunder", 0);
    OP *aop;

    if (flag_svp && SvTRUE(*flag_svp) && (o->op_flags & OPf_KIDS)
     && (aop = cUNOPx(o)->op_first) && aop->op_type == OP_CONST
     && aop->op_private & (OPpCONST_ENTERED|OPpCONST_BARE)
     && (ref = cSVOPx(aop)->op_sv) && SvPOK(ref) && SvCUR(ref)
     && *(SvEND(ref)-1) == 'o')
    {
        SvGROW(ref, SvCUR(ref)+2);
        *SvEND(ref) = '_';
        SvCUR(ref)++; /* Not _set, so we don't accidentally break non-PERL_CORE */
        *SvEND(ref) = '\0';
    }
    return old_ck_rv2cv(aTHX_ o);
}

#define test_bool_internals_macro(true_sv, false_sv) \
    test_bool_internals_func(true_sv, false_sv,\
        #true_sv " and " #false_sv)

U32
test_bool_internals_func(SV *true_sv, SV *false_sv, const char *msg) {
    U32 failed = 0;
    printf("# Testing '%s'\n", msg);
    TEST_EXPR(SvCUR(true_sv) == 1);
    TEST_EXPR(SvCUR(false_sv) == 0);
    TEST_EXPR(SvLEN(true_sv) == 0);
    TEST_EXPR(SvLEN(false_sv) == 0);
    TEST_EXPR(SvIV(true_sv) == 1);
    TEST_EXPR(SvIV(false_sv) == 0);
    TEST_EXPR(SvIsCOW(true_sv));
    TEST_EXPR(SvIsCOW(false_sv));
    TEST_EXPR(strEQ(SvPV_nolen(true_sv),"1"));
    TEST_EXPR(strEQ(SvPV_nolen(false_sv),""));
    TEST_EXPR(SvIOK(true_sv));
    TEST_EXPR(SvIOK(false_sv));
    TEST_EXPR(SvPOK(true_sv));
    TEST_EXPR(SvPOK(false_sv));
    TEST_EXPR(SvBoolFlagsOK(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv));
    TEST_EXPR(SvTYPE(true_sv) >= SVt_PVNV);
    TEST_EXPR(SvTYPE(false_sv) >= SVt_PVNV);
    TEST_EXPR(SvBoolFlagsOK(true_sv) && BOOL_INTERNALS_sv_isbool(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv) && BOOL_INTERNALS_sv_isbool(false_sv));
    TEST_EXPR(SvBoolFlagsOK(true_sv) && BOOL_INTERNALS_sv_isbool_true(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv) && BOOL_INTERNALS_sv_isbool_false(false_sv));
    TEST_EXPR(SvBoolFlagsOK(true_sv) && !BOOL_INTERNALS_sv_isbool_false(true_sv));
    TEST_EXPR(SvBoolFlagsOK(false_sv) && !BOOL_INTERNALS_sv_isbool_true(false_sv));
    TEST_EXPR(SvTRUE(true_sv));
    TEST_EXPR(!SvTRUE(false_sv));
    if (failed) {
        PerlIO_printf(Perl_debug_log, "# '%s' the tested true_sv:\n", msg);
        sv_dump(true_sv);
        PerlIO_printf(Perl_debug_log, "# PL_sv_yes:\n");
        sv_dump(&PL_sv_yes);
        PerlIO_printf(Perl_debug_log, "# '%s' tested false_sv:\n",msg);
        sv_dump(false_sv);
        PerlIO_printf(Perl_debug_log, "# PL_sv_no:\n");
        sv_dump(&PL_sv_no);
    }
    fflush(stdout);
    SvREFCNT_dec(true_sv);
    SvREFCNT_dec(false_sv);
    return failed;
}


/* A simplified/fake replacement for pp_add, which tests the pp
 * function wrapping API, XSPP_wrapped() for a fixed number of args*/

XSPP_wrapped(my_pp_add, 2, 0)
{
    SV *ret;
    dSP;
    SV *r = POPs;
    SV *l = TOPs;
    if (SvROK(l))
        l = SvRV(l);
    if (SvROK(r))
        r = SvRV(r);
    ret = newSViv( SvIV(l) + SvIV(r));
    sv_2mortal(ret);
    SETs(ret);
    RETURN;
}


/* A copy of pp_anonlist, which tests the pp
 * function wrapping API, XSPP_wrapped()  for a list*/

XSPP_wrapped(my_pp_anonlist, 0, 1)
{
    dSP; dMARK;
    const I32 items = SP - MARK;
    SV * const av = MUTABLE_SV(av_make(items, MARK+1));
    SP = MARK;
    mXPUSHs((PL_op->op_flags & OPf_SPECIAL)
            ? newRV_noinc(av) : av);
    RETURN;
}


#include "const-c.inc"

void
destruct_test(pTHX_ SV *p) {
    warn("In destruct_test: %" SVf "\n", p);
}

#if defined(USE_ITHREADS) && !defined(WIN32)

static void *
signal_thread_start(void *arg) {
  PERL_UNUSED_ARG(arg);
  raise(SIGUSR1);
  return NULL;
}

#endif

#ifdef PERL_USE_HWM
#  define hwm_checks_enabled() true
#else
#  define hwm_checks_enabled() false
#endif

typedef SV *nullable_SV;

MODULE = XS::APItest            PACKAGE = XS::APItest

INCLUDE: const-xs.inc

INCLUDE: numeric.xs

INCLUDE: APItest_utf8.xs

void
assertx(int x)
    CODE:
        /* this only needs to compile and checks that assert() can be
           used this way syntactically */
        (void)(assert(x), 1);
        (void)(x);

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

MODULE = XS::APItest            PACKAGE = XS::APItest::XSUB

BOOT:
    newXS("XS::APItest::XSUB::XS_VERSION_undef", XS_XS__APItest__XSUB_XS_VERSION_undef, __FILE__);
    newXS("XS::APItest::XSUB::XS_VERSION_empty", XS_XS__APItest__XSUB_XS_VERSION_empty, __FILE__);
    newXS("XS::APItest::XSUB::XS_APIVERSION_invalid", XS_XS__APItest__XSUB_XS_APIVERSION_invalid, __FILE__);

void
XS_VERSION_defined(...)
    PPCODE:
        XS_VERSION_BOOTCHECK;
        XSRETURN_EMPTY;

void
XS_APIVERSION_valid(...)
    PPCODE:
        XS_APIVERSION_BOOTCHECK;
        XSRETURN_EMPTY;

void
xsreturn( int len )
    PPCODE:
        int i = 0;
        EXTEND( SP, len );
        for ( ; i < len; i++ ) {
            ST(i) = sv_2mortal( newSViv(i) );
        }
        XSRETURN( len );

void
xsreturn_iv()
    PPCODE:
        XSRETURN_IV(I32_MIN + 1);

void
xsreturn_uv()
    PPCODE:
        XSRETURN_UV( (U32)((1U<<31) + 1) );

void
xsreturn_nv()
    PPCODE:
        XSRETURN_NV(0.25);

void
xsreturn_pv()
    PPCODE:
        XSRETURN_PV("returned");

void
xsreturn_pvn()
    PPCODE:
        XSRETURN_PVN("returned too much",8);

void
xsreturn_no()
    PPCODE:
        XSRETURN_NO;

void
xsreturn_yes()
    PPCODE:
        XSRETURN_YES;

void
xsreturn_undef()
    PPCODE:
        XSRETURN_UNDEF;

void
xsreturn_empty()
    PPCODE:
        XSRETURN_EMPTY;

void
test_mismatch_xs_handshake_api_ver(...)
    ALIAS:
        test_mismatch_xs_handshake_bad_struct = 1
        test_mismatch_xs_handshake_bad_struct_and_ver = 2
    PPCODE:
    if(ix == 0) {
#ifdef MULTIPLICITY
        Perl_xs_handshake(HS_KEYp(sizeof(PerlInterpreter),
                                  TRUE, NULL, FALSE,
                                  sizeof("v1.1337.0")-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v1.1337.0");
#else
        Perl_xs_handshake(HS_KEYp(sizeof(struct PerlHandShakeInterpreter),
                                  FALSE, NULL, FALSE,
                                  sizeof("v1.1337.0")-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v1.1337.0");
#endif
    }
    else if(ix == 1) {
#ifdef MULTIPLICITY
        Perl_xs_handshake(HS_KEYp(sizeof(PerlInterpreter)+1,
                                  TRUE, NULL, FALSE,
                                  sizeof("v" PERL_API_VERSION_STRING)-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v" PERL_API_VERSION_STRING);
#else
        Perl_xs_handshake(HS_KEYp(sizeof(struct PerlHandShakeInterpreter)+1,
                                  FALSE, NULL, FALSE,
                                  sizeof("v" PERL_API_VERSION_STRING)-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v" PERL_API_VERSION_STRING);
#endif
    }
    else {
#ifdef MULTIPLICITY
        Perl_xs_handshake(HS_KEYp(sizeof(PerlInterpreter)+1,
                                  TRUE, NULL, FALSE,
                                  sizeof("v1.1337.0")-1,
                                  sizeof("")-1),
                                  HS_CXT, __FILE__, items, ax,
                                  "v1.1337.0");
#else
        Perl_xs_handshake(HS_KEYp(sizeof(struct PerlHandShakeInterpreter)+1,
                                    FALSE, NULL, FALSE,
                                    sizeof("v1.1337.0")-1,
                                    sizeof("")-1),
                                    HS_CXT, __FILE__, items, ax,
                                    "v1.1337.0");
#endif
    }


INCLUDE: APItest_hash.xs

INCLUDE: APItest_temp_lv.xs

INCLUDE: APItest_ptr_table.xs

INCLUDE: APItest_autoload.xs

MODULE = XS::APItest            PACKAGE = XS::APItest

PROTOTYPES: DISABLE

BOOT:
    mymro.resolve = myget_linear_isa;
    mymro.name    = "justisa";
    mymro.length  = 7;
    mymro.kflags  = 0;
    mymro.hash    = 0;
    Perl_mro_register(aTHX_ &mymro);

HV *
xop_custom_ops ()
    CODE:
        RETVAL = PL_custom_ops;
    OUTPUT:
        RETVAL

HV *
xop_custom_op_names ()
    CODE:
        PL_custom_op_names = newHV();
        RETVAL = PL_custom_op_names;
    OUTPUT:
        RETVAL

HV *
xop_custom_op_descs ()
    CODE:
        PL_custom_op_descs = newHV();
        RETVAL = PL_custom_op_descs;
    OUTPUT:
        RETVAL

void
xop_register ()
    CODE:
        XopENTRY_set(&my_xop, xop_name, "my_xop");
        XopENTRY_set(&my_xop, xop_desc, "XOP for testing");
        XopENTRY_set(&my_xop, xop_class, OA_UNOP);
        XopENTRY_set(&my_xop, xop_peep, peep_xop);
        Perl_custom_op_register(aTHX_ pp_xop, &my_xop);

void
xop_clear ()
    CODE:
        XopDISABLE(&my_xop, xop_name);
        XopDISABLE(&my_xop, xop_desc);
        XopDISABLE(&my_xop, xop_class);
        XopDISABLE(&my_xop, xop_peep);

IV
xop_my_xop ()
    CODE:
        RETVAL = PTR2IV(&my_xop);
    OUTPUT:
        RETVAL

IV
xop_ppaddr ()
    CODE:
        RETVAL = PTR2IV(pp_xop);
    OUTPUT:
        RETVAL

IV
xop_OA_UNOP ()
    CODE:
        RETVAL = OA_UNOP;
    OUTPUT:
        RETVAL

AV *
xop_build_optree ()
    CODE:
        dMY_CXT;
        UNOP *unop;
        OP *kid;

        MY_CXT.xop_record = newAV_alloc_x(5);

        kid = newSVOP(OP_CONST, 0, newSViv(42));

        unop = (UNOP*)mkUNOP(OP_CUSTOM, kid);
        unop->op_ppaddr     = pp_xop;
        unop->op_private    = 0;
        unop->op_next       = NULL;
        kid->op_next        = (OP*)unop;

        av_push_simple(MY_CXT.xop_record, newSVpvf("unop:%" UVxf, PTR2UV(unop)));
        av_push_simple(MY_CXT.xop_record, newSVpvf("kid:%" UVxf, PTR2UV(kid)));

        av_push_simple(MY_CXT.xop_record, newSVpvf("NAME:%s", OP_NAME((OP*)unop)));
        av_push_simple(MY_CXT.xop_record, newSVpvf("DESC:%s", OP_DESC((OP*)unop)));
        av_push_simple(MY_CXT.xop_record, newSVpvf("CLASS:%d", (int)OP_CLASS((OP*)unop)));

        PL_rpeepp(aTHX_ kid);

        FreeOp(kid);
        FreeOp(unop);

        RETVAL = MY_CXT.xop_record;
        MY_CXT.xop_record = NULL;
    OUTPUT:
        RETVAL

IV
xop_from_custom_op ()
    CODE:
/* author note: this test doesn't imply Perl_custom_op_xop is or isn't public
   API or that Perl_custom_op_xop is known to be used outside the core */
        UNOP *unop;
        XOP *xop;

        unop = (UNOP*)mkUNOP(OP_CUSTOM, NULL);
        unop->op_ppaddr     = pp_xop;
        unop->op_private    = 0;
        unop->op_next       = NULL;

        xop = Perl_custom_op_xop(aTHX_ (OP *)unop);
        FreeOp(unop);
        RETVAL = PTR2IV(xop);
    OUTPUT:
        RETVAL

BOOT:
{
    MY_CXT_INIT;

    MY_CXT.i  = 99;
    MY_CXT.sv = newSVpv("initial",0);

    MY_CXT.bhkav = get_av("XS::APItest::bhkav", GV_ADDMULTI);
    MY_CXT.bhk_record = 0;

    BhkENTRY_set(&bhk_test, bhk_start, blockhook_test_start);
    BhkENTRY_set(&bhk_test, bhk_pre_end, blockhook_test_pre_end);
    BhkENTRY_set(&bhk_test, bhk_post_end, blockhook_test_post_end);
    BhkENTRY_set(&bhk_test, bhk_eval, blockhook_test_eval);
    Perl_blockhook_register(aTHX_ &bhk_test);

    MY_CXT.cscgv = gv_fetchpvs("XS::APItest::COMPILE_SCOPE_CONTAINER",
        GV_ADDMULTI, SVt_PVAV);
    MY_CXT.cscav = GvAV(MY_CXT.cscgv);

    BhkENTRY_set(&bhk_csc, bhk_start, blockhook_csc_start);
    BhkENTRY_set(&bhk_csc, bhk_pre_end, blockhook_csc_pre_end);
    Perl_blockhook_register(aTHX_ &bhk_csc);

    MY_CXT.peep_recorder = newAV();
    MY_CXT.rpeep_recorder = newAV();

    MY_CXT.orig_peep = PL_peepp;
    MY_CXT.orig_rpeep = PL_rpeepp;
    PL_peepp = my_peep;
    PL_rpeepp = my_rpeep;
}

void
CLONE(...)
    CODE:
    MY_CXT_CLONE;
    PERL_UNUSED_VAR(items);
    MY_CXT.sv = newSVpv("initial_clone",0);
    MY_CXT.cscgv = gv_fetchpvs("XS::APItest::COMPILE_SCOPE_CONTAINER",
        GV_ADDMULTI, SVt_PVAV);
    MY_CXT.cscav = NULL;
    MY_CXT.bhkav = get_av("XS::APItest::bhkav", GV_ADDMULTI);
    MY_CXT.bhk_record = 0;
    MY_CXT.peep_recorder = newAV();
    MY_CXT.rpeep_recorder = newAV();

void
print_double(val)
        double val
        CODE:
        printf("%5.3f\n",val);

int
have_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
        RETVAL = 1;
#else
        RETVAL = 0;
#endif
        OUTPUT:
        RETVAL

void
print_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
#   if defined(PERL_PRIfldbl) && (LONG_DOUBLESIZE > DOUBLESIZE)
        long double val = 7.0;
        printf("%5.3" PERL_PRIfldbl "\n",val);
#   else
        double val = 7.0;
        printf("%5.3f\n",val);
#   endif
#endif

void
print_long_doubleL()
        CODE:
#ifdef HAS_LONG_DOUBLE
        /* used to test we allow the length modifier required by the standard */
        long double val = 7.0;
        printf("%5.3Lf\n",val);
#else
        double val = 7.0;
        printf("%5.3f\n",val);
#endif

void
print_int(val)
        int val
        CODE:
        printf("%d\n",val);

void
print_long(val)
        long val
        CODE:
        printf("%ld\n",val);

void
print_float(val)
        float val
        CODE:
        printf("%5.3f\n",val);

void
print_flush()
        CODE:
        fflush(stdout);

void
mpushp()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHp("one", 3);
        mPUSHp("two", 3);
        mPUSHpvs("three");
        XSRETURN(3);

void
mpushn()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHn(0.5);
        mPUSHn(-0.25);
        mPUSHn(0.125);
        XSRETURN(3);

void
mpushi()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHi(-1);
        mPUSHi(2);
        mPUSHi(-3);
        XSRETURN(3);

void
mpushu()
        PPCODE:
        EXTEND(SP, 3);
        mPUSHu(1);
        mPUSHu(2);
        mPUSHu(3);
        XSRETURN(3);

void
mxpushp()
        PPCODE:
        mXPUSHp("one", 3);
        mXPUSHp("two", 3);
        mXPUSHpvs("three");
        XSRETURN(3);

void
mxpushn()
        PPCODE:
        mXPUSHn(0.5);
        mXPUSHn(-0.25);
        mXPUSHn(0.125);
        XSRETURN(3);

void
mxpushi()
        PPCODE:
        mXPUSHi(-1);
        mXPUSHi(2);
        mXPUSHi(-3);
        XSRETURN(3);

void
mxpushu()
        PPCODE:
        mXPUSHu(1);
        mXPUSHu(2);
        mXPUSHu(3);
        XSRETURN(3);


 # test_EXTEND(): excerise the EXTEND() macro.
 # After calling EXTEND(), it also does *(p+n) = NULL and
 # *PL_stack_max = NULL to allow valgrind etc to spot if the stack hasn't
 # actually been extended properly.
 #
 # max_offset specifies the SP to use.  It is treated as a signed offset
 #              from PL_stack_max.
 # nsv        is the SV holding the value of n indicating how many slots
 #              to extend the stack by.
 # use_ss     is a boolean indicating that n should be cast to a SSize_t

void
test_EXTEND(max_offset, nsv, use_ss)
    IV   max_offset;
    SV  *nsv;
    bool use_ss;
PREINIT:
    SV **new_sp = PL_stack_max + max_offset;
    SSize_t new_offset = new_sp - PL_stack_base;
PPCODE:
    if (use_ss) {
        SSize_t n = (SSize_t)SvIV(nsv);
        EXTEND(new_sp, n);
        new_sp = PL_stack_base + new_offset;
        assert(new_sp + n <= PL_stack_max);
        if ((new_sp + n) > PL_stack_sp)
            *(new_sp + n) = NULL;
    }
    else {
        IV n = SvIV(nsv);
        EXTEND(new_sp, n);
        new_sp = PL_stack_base + new_offset;
        assert(new_sp + n <= PL_stack_max);
        if ((new_sp + n) > PL_stack_sp)
            *(new_sp + n) = NULL;
    }
    if (PL_stack_max > PL_stack_sp)
        *PL_stack_max = NULL;


void
bad_EXTEND()
    PPCODE:
        /* testing failure to extend the stack, do not extend the stack */
        PUSHs(&PL_sv_yes);
        PUSHs(&PL_sv_no);
        XSRETURN(2);

bool
hwm_checks_enabled()

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
