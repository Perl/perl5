#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* In lieu of proper docs, let's outline what this is about:
 *
 * This module exposes the hash vtable mechanism to Perl insofar
 * that it allows Perl programs to create hashes with alternate
 * vtables/implementations.
 *
 * To do so, this module exports a new keyword "make_hash" (better
 * naming suggestions welcome) whose first parameter indicates
 * the type of hash implementation (which vtable) to use. The
 * remaining parameters are used the same way as you'd initialize
 * an anonymous hash with {}.
 *
 * The hash vtables is determined from the first parameter to
 * make_hash by looking it up in a global registry. Non-existent
 * vtable names cause an exception to be thrown.
 * Said global registry is simply the hash
 *   %Hash::Pluggable::VtableRegistry
 * which contains "name" => vtable pointer mappings.
 * It should generally only be accessed directly from XS extensions
 * which implement vtables rather than from Perl code directly.
 * For now, the API to add a new vtable implementation from an
 * XS module is assuming you have a 'HV_VTBL *my_vtable':
 *
 *   HV *vtable_reg = get_hv("Hash::Pluggable::VtableRegistry", GV_ADD);
 *   hv_stores(vtable_reg, "My::Module/set", my_vtable);
 *
 * in the BOOT section of your XS module.
 *
 * It seems like good practice to use vtable names of the form
 *   "My::Module/fancy_vtable"
 * to avoid potential collisions. But this might prove too clunky
 * in practice?
 *
 * The vtable pointer is looked up at compile time for cases of
 * constant strings used for vtable names in make_hash calls.
 */


/* For chaining the keyword plugin */
int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);
/* Our anonhash-alike custom OP */
XOP pluggable_anonhash_op;
/* Our free-hook for our custom anonhash ops. */
Perl_ophook_t next_opfreehook;



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

    if (PL_op->op_targ == 0) {
        /* Resolve vtbl at run time. */
        MARK++;
        hash_type_sv = *MARK;
        vtable_registry = get_hv("Hash::Pluggable::VtableRegistry", GV_ADD);
        he = hv_fetch_ent(vtable_registry, hash_type_sv, 0, 0);
        if (he) {
            vtbl = INT2PTR(HV_VTBL *, SvIV(HeVAL(he)));
        }
        else {
            /* Couldn't look up vtable: Barf! */
            Perl_croak(aTHX_ "No hash vtable for vtable name '%s'",
                       SvPV_nolen_const(hash_type_sv));
        }
    }
    else {
        vtbl = (HV_VTBL *)PL_op->op_targ;
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

STATIC void
custom_anonhash_opfreehook(pTHX_ OP *o)
{
    if (next_opfreehook != NULL)
        next_opfreehook(aTHX_ o);

    if (o->op_ppaddr == pp_pluggable_anonhash)
        o->op_targ = 0; /* important or Perl will use it to access the pad */
}


STATIC void
perform_compile_time_vtable_lookup(pTHX_ OP *anonhash_op)
{
    /* Try and see if we have a constant string for the type and if so,
     * do a compile time vtable lookup and associated OP munging. */

    OP *op;

    assert(OP_CLASS(anonhash_op) == OA_LISTOP);

    op = cLISTOPx(anonhash_op)->op_first;
    assert(OP_TYPE_IS(op, OP_PUSHMARK));

    op = OpSIBLING(op);
    assert(op != NULL);

    if (OP_TYPE_IS_NN(op, OP_CONST)) {
        HV_VTBL *vtbl = NULL;
        HV *vtable_registry;
        HE *he;
        SV *op_sv;

        assert(OP_CLASS(op) == OA_SVOP);
        op_sv = cSVOPx_sv(op);

        /* Okay, we DO have a constant hash vtable type identifier.
         * Let's do the vtable lookup right now and then munge the OP
         * tree to eschew this OP and modify the special custom
         * OP traits such that we get the vtable pointer from its
         * op_targ member. */
        vtable_registry = get_hv("Hash::Pluggable::VtableRegistry", GV_ADD);
        he = hv_fetch_ent(vtable_registry, op_sv, 0, 0);
        if (he) {
            vtbl = INT2PTR(HV_VTBL *, SvIV(HeVAL(he)));
        }
        else {
            /* Couldn't look up vtable: Barf! */
            /* Arguably, we could fall back to run-time evaluation? Does that
             * alleviate the language design concern at the cost of run-time
             * exceptions? FIXME consider. */
            Perl_croak(aTHX_ "No hash vtable for constant vtable name '%s'",
                       SvPV_nolen_const(op_sv));
        }

        /* First NULL out the const OP so it won't be executed. */
        op_null(op);

        /* Now set the op_targ to the vtbl pointer for the anonhash OP. */
        assert(vtbl != NULL);
        anonhash_op->op_targ = (PADOFFSET)vtbl;
    }
}

/* We intend to parse constructs of the following sorts:
 *   make_hash(LITERAL_STRING, LIST)
 *   make_hash(EXPR, LIST)
 *
 * The former version will be evaluated right now, at compile time.
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

    perform_compile_time_vtable_lookup(aTHX_ anonhash_op);

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

    /* Setup our callback for cleaning up OPs during global cleanup */
    next_opfreehook = PL_opfreehook;
    PL_opfreehook = custom_anonhash_opfreehook;

    /* Setup our custom op that implements pluggable anonhash*/
    XopENTRY_set(&pluggable_anonhash_op, xop_name, "pluggable_anonhash");
    XopENTRY_set(&pluggable_anonhash_op, xop_desc, "A pluggable version of the regular anonhash OP");
    XopENTRY_set(&pluggable_anonhash_op, xop_class, OA_LISTOP);
    Perl_custom_op_register(aTHX_ pp_pluggable_anonhash, &pluggable_anonhash_op);

    {
        HV *vr = get_hv("Hash::Pluggable::VtableRegistry", GV_ADD);
        hv_stores(vr, "Hash::Pluggable/mock", newSViv(PTR2IV(&PL_mock_std_vtable)));
    }
