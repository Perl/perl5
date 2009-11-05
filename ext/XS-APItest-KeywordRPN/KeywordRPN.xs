#define PERL_CORE 1   /* for pad_findmy() */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)
#define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

static SV *hintkey_rpn_sv, *hintkey_calcrpn_sv;
static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

/* low-level parser helpers */

#define PL_bufptr (PL_parser->bufptr)
#define PL_bufend (PL_parser->bufend)

static char THX_peek_char(pTHX)
{
	if(PL_bufptr == PL_bufend)
		Perl_croak(aTHX_
			"unexpected EOF "
			"(or you were unlucky about buffer position, FIXME)");
	return *PL_bufptr;
}
#define peek_char() THX_peek_char(aTHX)

static char THX_read_char(pTHX)
{
	char c = peek_char();
	PL_bufptr++;
	if(c == '\n') CopLINE_inc(PL_curcop);
	return c;
}
#define read_char() THX_read_char(aTHX)

static void THX_skip_opt_ws(pTHX)
{
	while(1) {
		switch(peek_char()) {
			case '\t': case '\n': case '\v': case '\f': case ' ':
				read_char();
				break;
			default:
				return;
		}
	}
}
#define skip_opt_ws() THX_skip_opt_ws(aTHX)

/* RPN parser */

static OP *THX_parse_var(pTHX)
{
	SV *varname = sv_2mortal(newSVpvs("$"));
	PADOFFSET varpos;
	OP *padop;
	if(peek_char() != '$') Perl_croak(aTHX_ "RPN syntax error");
	read_char();
	while(1) {
		char c = peek_char();
		if(!isALNUM(c)) break;
		read_char();
		sv_catpvn_nomg(varname, &c, 1);
	}
	if(SvCUR(varname) < 2) Perl_croak(aTHX_ "RPN syntax error");
	varpos = pad_findmy(SvPVX(varname));
	if(varpos == NOT_IN_PAD || PAD_COMPNAME_FLAGS_isOUR(varpos))
		Perl_croak(aTHX_ "RPN only supports \"my\" variables");
	padop = newOP(OP_PADSV, 0);
	padop->op_targ = varpos;
	return padop;
}
#define parse_var() THX_parse_var(aTHX)

#define push_rpn_item(o) \
	(tmpop = (o), tmpop->op_sibling = stack, stack = tmpop)
#define pop_rpn_item() \
	(!stack ? (Perl_croak(aTHX_ "RPN stack underflow"), (OP*)NULL) : \
	 (tmpop = stack, stack = stack->op_sibling, \
	  tmpop->op_sibling = NULL, tmpop))

static OP *THX_parse_rpn_expr(pTHX)
{
	OP *stack = NULL, *tmpop;
	while(1) {
		char c;
		skip_opt_ws();
		c = peek_char();
		switch(c) {
			case /*(*/')': case /*{*/'}': {
				OP *result = pop_rpn_item();
				if(stack)
					Perl_croak(aTHX_
						"RPN expression must return "
						"a single value");
				return result;
			} break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9': {
				UV val = 0;
				do {
					read_char();
					val = 10*val + (c - '0');
					c = peek_char();
				} while(c >= '0' && c <= '9');
				push_rpn_item(newSVOP(OP_CONST, 0,
					newSVuv(val)));
			} break;
			case '$': {
				push_rpn_item(parse_var());
			} break;
			case '+': {
				OP *b = pop_rpn_item();
				OP *a = pop_rpn_item();
				read_char();
				push_rpn_item(newBINOP(OP_I_ADD, 0, a, b));
			} break;
			case '-': {
				OP *b = pop_rpn_item();
				OP *a = pop_rpn_item();
				read_char();
				push_rpn_item(newBINOP(OP_I_SUBTRACT, 0, a, b));
			} break;
			case '*': {
				OP *b = pop_rpn_item();
				OP *a = pop_rpn_item();
				read_char();
				push_rpn_item(newBINOP(OP_I_MULTIPLY, 0, a, b));
			} break;
			case '/': {
				OP *b = pop_rpn_item();
				OP *a = pop_rpn_item();
				read_char();
				push_rpn_item(newBINOP(OP_I_DIVIDE, 0, a, b));
			} break;
			case '%': {
				OP *b = pop_rpn_item();
				OP *a = pop_rpn_item();
				read_char();
				push_rpn_item(newBINOP(OP_I_MODULO, 0, a, b));
			} break;
			default: {
				Perl_croak(aTHX_ "RPN syntax error");
			} break;
		}
	}
}
#define parse_rpn_expr() THX_parse_rpn_expr(aTHX)

static OP *THX_parse_keyword_rpn(pTHX)
{
	OP *op;
	skip_opt_ws();
	if(peek_char() != '('/*)*/)
		Perl_croak(aTHX_ "RPN expression must be parenthesised");
	read_char();
	op = parse_rpn_expr();
	if(peek_char() != /*(*/')')
		Perl_croak(aTHX_ "RPN expression must be parenthesised");
	read_char();
	return op;
}
#define parse_keyword_rpn() THX_parse_keyword_rpn(aTHX)

static OP *THX_parse_keyword_calcrpn(pTHX)
{
	OP *varop, *exprop;
	skip_opt_ws();
	varop = parse_var();
	skip_opt_ws();
	if(peek_char() != '{'/*}*/)
		Perl_croak(aTHX_ "RPN expression must be braced");
	read_char();
	exprop = parse_rpn_expr();
	if(peek_char() != /*{*/'}')
		Perl_croak(aTHX_ "RPN expression must be braced");
	read_char();
	return newASSIGNOP(OPf_STACKED, varop, 0, exprop);
}
#define parse_keyword_calcrpn() THX_parse_keyword_calcrpn(aTHX)

/* plugin glue */

static int THX_keyword_active(pTHX_ SV *hintkey_sv)
{
	HE *he;
	if(!GvHV(PL_hintgv)) return 0;
	he = hv_fetch_ent(GvHV(PL_hintgv), hintkey_sv, 0,
				SvSHARED_HASH(hintkey_sv));
	return he && SvTRUE(HeVAL(he));
}
#define keyword_active(hintkey_sv) THX_keyword_active(aTHX_ hintkey_sv)

static void THX_keyword_enable(pTHX_ SV *hintkey_sv)
{
	SV *val_sv = newSViv(1);
	HE *he;
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	he = hv_store_ent(GvHV(PL_hintgv),
		hintkey_sv, val_sv, SvSHARED_HASH(hintkey_sv));
	if(he) {
		SV *val = HeVAL(he);
		SvSETMAGIC(val);
	} else {
		SvREFCNT_dec(val_sv);
	}
}
#define keyword_enable(hintkey_sv) THX_keyword_enable(aTHX_ hintkey_sv)

static void THX_keyword_disable(pTHX_ SV *hintkey_sv)
{
	if(GvHV(PL_hintgv)) {
		PL_hints |= HINT_LOCALIZE_HH;
		hv_delete_ent(GvHV(PL_hintgv),
			hintkey_sv, G_DISCARD, SvSHARED_HASH(hintkey_sv));
	}
}
#define keyword_disable(hintkey_sv) THX_keyword_disable(aTHX_ hintkey_sv)

static int my_keyword_plugin(pTHX_
	char *keyword_ptr, STRLEN keyword_len, OP **op_ptr)
{
	if(keyword_len == 3 && strnEQ(keyword_ptr, "rpn", 3) &&
			keyword_active(hintkey_rpn_sv)) {
		*op_ptr = parse_keyword_rpn();
		return KEYWORD_PLUGIN_EXPR;
	} else if(keyword_len == 7 && strnEQ(keyword_ptr, "calcrpn", 7) &&
			keyword_active(hintkey_calcrpn_sv)) {
		*op_ptr = parse_keyword_calcrpn();
		return KEYWORD_PLUGIN_STMT;
	} else {
		return next_keyword_plugin(aTHX_
				keyword_ptr, keyword_len, op_ptr);
	}
}

MODULE = XS::APItest::KeywordRPN PACKAGE = XS::APItest::KeywordRPN

BOOT:
	hintkey_rpn_sv = newSVpvs_share("XS::APItest::KeywordRPN/rpn");
	hintkey_calcrpn_sv = newSVpvs_share("XS::APItest::KeywordRPN/calcrpn");
	next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = my_keyword_plugin;

void
import(SV *class, ...)
PREINIT:
	int i;
PPCODE:
	for(i = 1; i != items; i++) {
		SV *item = ST(i);
		if(sv_is_string(item) && strEQ(SvPVX(item), "rpn")) {
			keyword_enable(hintkey_rpn_sv);
		} else if(sv_is_string(item) && strEQ(SvPVX(item), "calcrpn")) {
			keyword_enable(hintkey_calcrpn_sv);
		} else {
			Perl_croak(aTHX_
				"\"%s\" is not exported by the %s module",
				SvPV_nolen(item), SvPV_nolen(ST(0)));
		}
	}

void
unimport(SV *class, ...)
PREINIT:
	int i;
PPCODE:
	for(i = 1; i != items; i++) {
		SV *item = ST(i);
		if(sv_is_string(item) && strEQ(SvPVX(item), "rpn")) {
			keyword_disable(hintkey_rpn_sv);
		} else if(sv_is_string(item) && strEQ(SvPVX(item), "calcrpn")) {
			keyword_disable(hintkey_calcrpn_sv);
		} else {
			Perl_croak(aTHX_
				"\"%s\" is not exported by the %s module",
				SvPV_nolen(item), SvPV_nolen(ST(0)));
		}
	}
