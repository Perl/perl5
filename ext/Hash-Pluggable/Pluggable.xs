#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* For chaining the keyword plugin */
int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);
/* Our anonhash-alike custom OP */
XOP pluggable_anonhash_op;


/* This is a custom OP that's VERY similar to pp_anonhash/OP_ANONHASH.
 * In a nutshell, we just change it to use its first argument on the
 * stack for determining the hash implementation type / vtable to use.
 */
OP *
pp_pluggable_anonhash(pTHX)
{
    dSP; dMARK; dORIGMARK;
    SV *hash_type_sv;
    HE *he;
    HV *vtable_registry;
    HV *hv;
    SV *retval;
    HV_VTBL *vtbl = NULL;

    /* TODO This logic should only be executed in the cases that the vtable
     *      couldn't be resolved statically. But that's not implemented yet. */
    MARK++;
    hash_type_sv = *MARK;
    vtable_registry = get_hv("Hash::Pluggable::VtableRegistry", GV_ADD);
    he = hv_fetch_ent(vtable_registry, hash_type_sv, 0, 0);
    if (he) {
        vtbl = INT2PTR(HV_VTBL *, SvIV(HeVAL(he)));
    }

    hv = newHV_type(vtbl);
    retval = sv_2mortal( newRV_noinc(MUTABLE_SV(hv)) );

    while (MARK < SP) {
	SV * const key =
	    (MARK++, SvGMAGICAL(*MARK) ? sv_mortalcopy(*MARK) : *MARK);
	SV *val;
	if (MARK < SP)
	{
	    MARK++;
	    SvGETMAGIC(*MARK);
	    val = newSV(0);
	    sv_setsv_nomg(val, *MARK);
	}
	else
	{
	    Perl_ck_warner(aTHX_ packWARN(WARN_MISC), "Odd number of elements in anonymous hash");
	    val = newSV(0);
	}
	(void)hv_store_ent(hv,key,val,0);
    }
    SP = ORIGMARK;
    XPUSHs(retval);
    RETURN;
}


/* We intend to parse constructs of the following sorts:
 *   make_hash(LITERAL_STRING, LIST)
 *   make_hash(EXPR, LIST)
 *
 * The former can be evaluated at compile time and stuffed
 * into the OP structure, but for now, we'll just implement
 * it the same way as the (much) less efficient (EXPR, LIST)
 * version. TODO
 */
STATIC void
parse_make_hash_keyword(pTHX_ OP **op_ptr)
{
    I32 c;
    OP *anonhash_op;
    OP *arguments_ops;

    lex_read_space(0);

    c = lex_read_unichar(0);
    if (c != '(')
        croak("Not enough parameters for make_hash");

    lex_read_space(0);

    c = lex_peek_unichar(0);
    if (c == ')')
        croak("Not enough arguments for make_hash");

    arguments_ops = parse_listexpr(0);

    lex_read_space(0);
    c = lex_peek_unichar(0);
    if (c != ')') {
        op_free(arguments_ops);
        croak("Syntax error: Expected ')'");
    }

    /* Ditch ')' */
    c = lex_read_unichar(0);

    /* Check if arguments_ops is a LIST_OP. That means there
     * was more than one argument (more than just the type).
     */
    if (OP_TYPE_IS_NN(arguments_ops, OP_LIST)) {
        /* We make it an OP_ANONHASH temporarily because op_convert_list
         * seems to explicitly check for specific OPs that use a pushmark.
         * OP_CUSTOM isn't one of them, which is why we change the OP type
         * afterwards by hand. */
        anonhash_op = op_convert_list(OP_ANONHASH, 0, arguments_ops);
        anonhash_op->op_type = OP_CUSTOM;
    }
    else {
        /* Just the one argument, it must be the type. */
        anonhash_op = newLISTOP(OP_CUSTOM, 0, NULL, NULL);
        op_append_elem(OP_CUSTOM, anonhash_op, arguments_ops);
        /* Need to manufacture our own PUSHMARK to satisfy the pluggable
         * anonhash OP implementation. */
        op_prepend_elem(OP_CUSTOM, newOP(OP_PUSHMARK, 0), anonhash_op);
    }

    anonhash_op->op_ppaddr = pp_pluggable_anonhash;


    printf("----------------------------\n");
    op_dump(anonhash_op);

    *op_ptr = anonhash_op;
}

STATIC int
make_hash_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len,
                         OP **op_ptr)
{
    int ret;
    HV *hints;

    /* Enforce lexical scope of this keyword plugin */
    if (!(hints = GvHV(PL_hintgv)))
        return FALSE;
    if (!(hv_fetchs(hints, "Hash::Pluggable/is_enabled", 0)))
        return FALSE;

    if (keyword_len == 9 && memcmp(keyword_ptr, "make_hash", 9) == 0)
    {
        SAVETMPS;
        parse_make_hash_keyword(aTHX_ op_ptr);
        ret = KEYWORD_PLUGIN_EXPR;
        FREETMPS;
    }
    else {
        ret = (*next_keyword_plugin)(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }

    return ret;
}


MODULE = Hash::Pluggable		PACKAGE = Hash::Pluggable

BOOT:
    /* Add the keyword plugin to the chain */
    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = make_hash_keyword_plugin;

    /* Setup our custom op that implements pluggable anonhash*/
    XopENTRY_set(&pluggable_anonhash_op, xop_name, "pluggable_anonhash");
    XopENTRY_set(&pluggable_anonhash_op, xop_desc, "A pluggable version of the regular anonhash OP");
    XopENTRY_set(&pluggable_anonhash_op, xop_class, OA_LISTOP);
    Perl_custom_op_register(aTHX_ pp_pluggable_anonhash, &pluggable_anonhash_op);

