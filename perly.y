/* $RCSfile: perly.y,v $$Revision: 4.1 $$Date: 92/08/07 18:26:16 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	perly.y,v $
 * Revision 4.1  92/08/07  18:26:16  lwall
 * 
 * Revision 4.0.1.5  92/06/11  21:12:50  lwall
 * patch34: expectterm incorrectly set to indicate start of program or block
 * 
 * Revision 4.0.1.4  92/06/08  17:33:25  lwall
 * patch20: one of the backdoors to expectterm was on the wrong reduction
 * 
 * Revision 4.0.1.3  92/06/08  15:18:16  lwall
 * patch20: an expression may now start with a bareword
 * patch20: relaxed requirement for semicolon at the end of a block
 * patch20: added ... as variant on ..
 * patch20: fixed double debug break in foreach with implicit array assignment
 * patch20: if {block} {block} didn't work any more
 * patch20: deleted some minor memory leaks
 * 
 * Revision 4.0.1.2  91/11/05  18:17:38  lwall
 * patch11: extra comma at end of list is now allowed in more places (Hi, Felix!)
 * patch11: once-thru blocks didn't display right in the debugger
 * patch11: debugger got confused over nested subroutine definitions
 * 
 * Revision 4.0.1.1  91/06/07  11:42:34  lwall
 * patch4: new copyright notice
 * 
 * Revision 4.0  91/03/20  01:38:40  lwall
 * 4.0 baseline.
 * 
 */

%{
#include "EXTERN.h"
#include "perl.h"

/*SUPPRESS 530*/
/*SUPPRESS 593*/
/*SUPPRESS 595*/

%}

%start prog

%union {
    I32	ival;
    char *pval;
    OP *opval;
    GV *gvval;
}

%token <ival> '{' ')'

%token <opval> WORD METHOD THING PMFUNC PRIVATEREF
%token <pval> LABEL
%token <ival> FORMAT SUB PACKAGE HINT
%token <ival> WHILE UNTIL IF UNLESS ELSE ELSIF CONTINUE FOR
%token <ival> LOOPEX DOTDOT
%token <ival> FUNC0 FUNC1 FUNC
%token <ival> RELOP EQOP MULOP ADDOP
%token <ival> DOLSHARP DO LOCAL DELETE HASHBRACK NOAMP

%type <ival> prog decl format remember crp crb crhb
%type <opval> block lineseq line loop cond nexpr else
%type <opval> expr sexpr term scalar ary hsh arylen star amper sideff
%type <opval> listexpr indirob
%type <opval> texpr listop
%type <pval> label
%type <opval> cont

%left OROP
%left ANDOP
%nonassoc <ival> LSTOP
%left ','
%right '='
%right '?' ':'
%nonassoc DOTDOT
%left OROR
%left ANDAND
%left <ival> BITOROP
%left <ival> BITANDOP
%nonassoc EQOP
%nonassoc RELOP
%nonassoc <ival> UNIOP
%left <ival> SHIFTOP
%left ADDOP
%left MULOP
%left <ival> MATCHOP
%right '!' '~' UMINUS REFGEN
%right <ival> POWOP
%nonassoc PREINC PREDEC POSTINC POSTDEC
%left ARROW
%left '('

%% /* RULES */

prog	:	/* NULL */
		{
#if defined(YYDEBUG) && defined(DEBUGGING)
		    yydebug = (debug & 1);
#endif
		    expect = XSTATE;
		}
	/*CONTINUED*/	lineseq
			{   if (in_eval) {
				eval_root = newUNOP(OP_LEAVEEVAL, 0, $2);
				eval_start = linklist(eval_root);
				eval_root->op_next = 0;
				peep(eval_start);
			    }
			    else
				main_root = block_head($2, &main_start);
			}
	;

block	:	'{' remember lineseq '}'
			{   int needblockscope = hints & HINT_BLOCK_SCOPE;
			    $$ = scalarseq($3);
			    if (copline > (line_t)$1)
				copline = $1;
			    LEAVE_SCOPE($2);
			    if (needblockscope)
				hints |= HINT_BLOCK_SCOPE; /* propagate out */
			    pad_leavemy(comppad_name_fill); }
	;

remember:	/* NULL */	/* in case they push a package name */
			{ $$ = savestack_ix;
			    comppad_name_fill = AvFILL(comppad_name);
			    SAVEINT(min_intro_pending);
			    SAVEINT(max_intro_pending);
			    min_intro_pending = 0;
			    SAVEINT(comppad_name_fill);
			    SAVEINT(hints);
			    hints &= ~HINT_BLOCK_SCOPE; }
	;

lineseq	:	/* NULL */
			{ $$ = Nullop; }
	|	lineseq decl
			{ $$ = $1; }
	|	lineseq line
			{   $$ = append_list(OP_LINESEQ,
				(LISTOP*)$1, (LISTOP*)$2); pad_reset();
			    if ($1 && $2) hints |= HINT_BLOCK_SCOPE; }
	;

line	:	label cond
			{ $$ = newSTATEOP(0, $1, $2); }
	|	loop	/* loops add their own labels */
	|	label ';'
			{ if ($1 != Nullch) {
			      $$ = newSTATEOP(0, $1, newOP(OP_NULL, 0));
			    }
			    else {
			      $$ = Nullop;
			      copline = NOLINE;
			    }
			    expect = XSTATE; }
	|	label sideff ';'
			{ $$ = newSTATEOP(0, $1, $2);
			  expect = XSTATE; }
	;

sideff	:	error
			{ $$ = Nullop; }
	|	expr
			{ $$ = $1; }
	|	expr IF expr
			{ $$ = newLOGOP(OP_AND, 0, $3, $1); }
	|	expr UNLESS expr
			{ $$ = newLOGOP(OP_OR, 0, $3, $1); }
	|	expr WHILE expr
			{ $$ = newLOOPOP(OPf_PARENS, 1, scalar($3), $1); }
	|	expr UNTIL expr
			{ $$ = newLOOPOP(OPf_PARENS, 1, invert(scalar($3)), $1);}
	;

else	:	/* NULL */
			{ $$ = Nullop; }
	|	ELSE block
			{ $$ = scope($2); }
	|	ELSIF '(' expr ')' block else
			{ copline = $1;
			    $$ = newSTATEOP(0, 0,
				newCONDOP(0, $3, scope($5), $6)); }
	;

cond	:	IF '(' expr ')' block else
			{ copline = $1;
			    $$ = newCONDOP(0, $3, scope($5), $6); }
	|	UNLESS '(' expr ')' block else
			{ copline = $1;
			    $$ = newCONDOP(0,
				invert(scalar($3)), scope($5), $6); }
	|	IF block block else
			{ copline = $1;
			    $$ = newCONDOP(0, scope($2), scope($3), $4); }
	|	UNLESS block block else
			{ copline = $1;
			    $$ = newCONDOP(0, invert(scalar(scope($2))),
						scope($3), $4); }
	;

cont	:	/* NULL */
			{ $$ = Nullop; }
	|	CONTINUE block
			{ $$ = scope($2); }
	;

loop	:	label WHILE '(' texpr ')' block cont
			{ copline = $2;
			    $$ = newSTATEOP(0, $1,
				    newWHILEOP(0, 1, (LOOP*)Nullop,
					$4, $6, $7) ); }
	|	label UNTIL '(' expr ')' block cont
			{ copline = $2;
			    $$ = newSTATEOP(0, $1,
				    newWHILEOP(0, 1, (LOOP*)Nullop,
					invert(scalar($4)), $6, $7) ); }
	|	label WHILE block block cont
			{ copline = $2;
			    $$ = newSTATEOP(0, $1,
				    newWHILEOP(0, 1, (LOOP*)Nullop,
					scope($3), $4, $5) ); }
	|	label UNTIL block block cont
			{ copline = $2;
			    $$ = newSTATEOP(0, $1,
				    newWHILEOP(0, 1, (LOOP*)Nullop,
					invert(scalar(scope($3))), $4, $5)); }
	|	label FOR scalar '(' expr crp block cont
			{ $$ = newFOROP(0, $1, $2, mod($3, OP_ENTERLOOP),
				$5, $7, $8); }
	|	label FOR '(' expr crp block cont
			{ $$ = newFOROP(0, $1, $2, Nullop, $4, $6, $7); }
	|	label FOR '(' nexpr ';' texpr ';' nexpr ')' block
			/* basically fake up an initialize-while lineseq */
			{  copline = $2;
			    $$ = append_elem(OP_LINESEQ,
				    newSTATEOP(0, $1, scalar($4)),
				    newSTATEOP(0, $1,
					newWHILEOP(0, 1, (LOOP*)Nullop,
					    scalar($6), $10, scalar($8)) )); }
	|	label block cont  /* a block is a loop that happens once */
			{ $$ = newSTATEOP(0,
				$1, newWHILEOP(0, 1, (LOOP*)Nullop,
					Nullop, $2, $3)); }
	;

nexpr	:	/* NULL */
			{ $$ = Nullop; }
	|	sideff
	;

texpr	:	/* NULL means true */
			{ (void)scan_num("1"); $$ = yylval.opval; }
	|	expr
	;

label	:	/* empty */
			{ $$ = Nullch; }
	|	LABEL
	;

decl	:	format
			{ $$ = 0; }
	|	subrout
			{ $$ = 0; }
	|	package
			{ $$ = 0; }
	|	hint
			{ $$ = 0; }
	;

format	:	FORMAT WORD block
			{ newFORM($1, $2, $3); }
	|	FORMAT block
			{ newFORM($1, Nullop, $2); }
	;

subrout	:	SUB WORD block
			{ newSUB($1, $2, $3); }
	|	SUB WORD ';'
			{ newSUB($1, $2, Nullop); expect = XSTATE; }
	;

package :	PACKAGE WORD ';'
			{ package($2); }
	|	PACKAGE ';'
			{ package(Nullop); }
	;

hint	:	HINT WORD ';'
			{ hint($1, $2, Nullop); }
	|	HINT WORD expr ';'
			{ hint($1, $2, list(force_list($3))); }
	;

expr	:	expr ',' sexpr
			{ $$ = append_elem(OP_LIST, $1, $3); }
	|	sexpr
	;

listop	:	LSTOP indirob listexpr
			{ $$ = convert($1, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF($2), $3) ); }
	|	FUNC '(' indirob listexpr ')'
			{ $$ = convert($1, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF($3), $4) ); }
	|	indirob ARROW LSTOP listexpr
			{ $$ = convert($3, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF($1), $4) ); }
	|	indirob ARROW FUNC '(' listexpr ')'
			{ $$ = convert($3, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF($1), $5) ); }
	|	term ARROW METHOD '(' listexpr ')'
			{ $$ = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST,
				    newMETHOD($1,$3), list($5))); }
	|	METHOD indirob listexpr
			{ $$ = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST,
				    newMETHOD($2,$1), list($3))); }
	|	LSTOP listexpr
			{ $$ = convert($1, 0, $2); }
	|	FUNC '(' listexpr ')'
			{ $$ = convert($1, 0, $3); }
	;

sexpr	:	sexpr '=' sexpr
			{ $$ = newASSIGNOP(OPf_STACKED, $1, $3); }
	|	sexpr POWOP '=' sexpr
			{ $$ = newBINOP($2, OPf_STACKED,
				mod(scalar($1), $2), scalar($4)); }
	|	sexpr MULOP '=' sexpr
			{ $$ = newBINOP($2, OPf_STACKED,
				mod(scalar($1), $2), scalar($4)); }
	|	sexpr ADDOP '=' sexpr
			{ $$ = newBINOP($2, OPf_STACKED,
				mod(scalar($1), $2), scalar($4));}
	|	sexpr SHIFTOP '=' sexpr
			{ $$ = newBINOP($2, OPf_STACKED,
				mod(scalar($1), $2), scalar($4)); }
	|	sexpr BITANDOP '=' sexpr
			{ $$ = newBINOP($2, OPf_STACKED,
				mod(scalar($1), $2), scalar($4)); }
	|	sexpr BITOROP '=' sexpr
			{ $$ = newBINOP($2, OPf_STACKED,
				mod(scalar($1), $2), scalar($4)); }
	|	sexpr ANDAND '=' sexpr
			{ $$ = newLOGOP(OP_ANDASSIGN, 0,
				mod(scalar($1), OP_ANDASSIGN),
				newUNOP(OP_SASSIGN, 0, scalar($4))); }
	|	sexpr OROR '=' sexpr
			{ $$ = newLOGOP(OP_ORASSIGN, 0,
				mod(scalar($1), OP_ORASSIGN),
				newUNOP(OP_SASSIGN, 0, scalar($4))); }


	|	sexpr POWOP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr MULOP sexpr
			{   if ($2 != OP_REPEAT)
				scalar($1);
			    $$ = newBINOP($2, 0, $1, scalar($3)); }
	|	sexpr ADDOP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr SHIFTOP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr RELOP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr EQOP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr BITANDOP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr BITOROP sexpr
			{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); }
	|	sexpr DOTDOT sexpr
			{ $$ = newRANGE($2, scalar($1), scalar($3));}
	|	sexpr ANDAND sexpr
			{ $$ = newLOGOP(OP_AND, 0, $1, $3); }
	|	sexpr OROR sexpr
			{ $$ = newLOGOP(OP_OR, 0, $1, $3); }
	|	sexpr ANDOP sexpr
			{ $$ = newLOGOP(OP_AND, 0, $1, $3); }
	|	sexpr OROP sexpr
			{ $$ = newLOGOP(OP_OR, 0, $1, $3); }
	|	sexpr '?' sexpr ':' sexpr
			{ $$ = newCONDOP(0, $1, $3, $5); }
	|	sexpr MATCHOP sexpr
			{ $$ = bind_match($2, $1, $3); }
	|	term
			{ $$ = $1; }
	;

term	:	'-' term %prec UMINUS
			{ $$ = newUNOP(OP_NEGATE, 0, scalar($2)); }
	|	'+' term %prec UMINUS
			{ $$ = $2; }
	|	'!' term
			{ $$ = newUNOP(OP_NOT, 0, scalar($2)); }
	|	'~' term
			{ $$ = newUNOP(OP_COMPLEMENT, 0, scalar($2));}
	|	REFGEN term
			{ $$ = newUNOP(OP_REFGEN, 0, ref($2,OP_REFGEN)); }
	|	term POSTINC
			{ $$ = newUNOP(OP_POSTINC, 0,
					mod(scalar($1), OP_POSTINC)); }
	|	term POSTDEC
			{ $$ = newUNOP(OP_POSTDEC, 0,
					mod(scalar($1), OP_POSTDEC)); }
	|	PREINC term
			{ $$ = newUNOP(OP_PREINC, 0,
					mod(scalar($2), OP_PREINC)); }
	|	PREDEC term
			{ $$ = newUNOP(OP_PREDEC, 0,
					mod(scalar($2), OP_PREDEC)); }
	|	LOCAL sexpr	%prec UNIOP
			{ $$ = localize($2,$1); }
	|	'(' expr crp
			{ $$ = sawparens($2); }
	|	'(' ')'
			{ $$ = sawparens(newNULLLIST()); }
	|	'[' expr crb				%prec '('
			{ $$ = newANONLIST($2); }
	|	'[' ']'					%prec '('
			{ $$ = newANONLIST(Nullop); }
	|	HASHBRACK expr crhb			%prec '('
			{ $$ = newANONHASH($2); }
	|	HASHBRACK ';' '}'				%prec '('
			{ $$ = newANONHASH(Nullop); }
	|	scalar	%prec '('
			{ $$ = $1; }
	|	star	%prec '('
			{ $$ = $1; }
	|	scalar '[' expr ']'	%prec '('
			{ $$ = newBINOP(OP_AELEM, 0, oopsAV($1), scalar($3)); }
	|	term ARROW '[' expr ']'	%prec '('
			{ $$ = newBINOP(OP_AELEM, 0,
					ref(newAVREF($1),OP_RV2AV),
					scalar($4));}
	|	term '[' expr ']'	%prec '('
			{ $$ = newBINOP(OP_AELEM, 0,
					ref(newAVREF($1),OP_RV2AV),
					scalar($3));}
	|	hsh 	%prec '('
			{ $$ = $1; }
	|	ary 	%prec '('
			{ $$ = $1; }
	|	arylen 	%prec '('
			{ $$ = newUNOP(OP_AV2ARYLEN, 0, ref($1, OP_AV2ARYLEN));}
	|	scalar '{' expr ';' '}'	%prec '('
			{ $$ = newBINOP(OP_HELEM, 0, oopsHV($1), jmaybe($3));
			    expect = XOPERATOR; }
	|	term ARROW '{' expr ';' '}'	%prec '('
			{ $$ = newBINOP(OP_HELEM, 0,
					ref(newHVREF($1),OP_RV2HV),
					jmaybe($4));
			    expect = XOPERATOR; }
	|	term '{' expr ';' '}'	%prec '('
			{ $$ = newBINOP(OP_HELEM, 0,
					ref(newHVREF($1),OP_RV2HV),
					jmaybe($3));
			    expect = XOPERATOR; }
	|	'(' expr crp '[' expr ']'	%prec '('
			{ $$ = newSLICEOP(0, $5, $2); }
	|	'(' ')' '[' expr ']'	%prec '('
			{ $$ = newSLICEOP(0, $4, Nullop); }
	|	ary '[' expr ']'	%prec '('
			{ $$ = prepend_elem(OP_ASLICE,
				newOP(OP_PUSHMARK, 0),
				list(
				    newLISTOP(OP_ASLICE, 0,
					list($3),
					ref($1, OP_ASLICE)))); }
	|	ary '{' expr ';' '}'	%prec '('
			{ $$ = prepend_elem(OP_HSLICE,
				newOP(OP_PUSHMARK, 0),
				list(
				    newLISTOP(OP_HSLICE, 0,
					list($3),
					ref(oopsHV($1), OP_HSLICE))));
			    expect = XOPERATOR; }
	|	DELETE scalar '{' expr ';' '}'	%prec '('
			{ $$ = newBINOP(OP_DELETE, 0, oopsHV($2), jmaybe($4));
			    expect = XOPERATOR; }
	|	DELETE '(' scalar '{' expr ';' '}' ')'	%prec '('
			{ $$ = newBINOP(OP_DELETE, 0, oopsHV($3), jmaybe($5));
			    expect = XOPERATOR; }
	|	THING	%prec '('
			{ $$ = $1; }
	|	amper
			{ $$ = newUNOP(OP_ENTERSUBR, 0,
				scalar($1)); }
	|	amper '(' ')'
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_STACKED, scalar($1)); }
	|	amper '(' expr crp
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_STACKED,
			    list(prepend_elem(OP_LIST, scalar($1), $3))); }
	|	NOAMP WORD listexpr
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				newCVREF(scalar($2)), $3))); }
	|	NOAMP WORD indirob listexpr
			{ $$ = convert(OP_ENTERSUBR, OPf_STACKED|OPf_SPECIAL,
				prepend_elem(OP_LIST,
				    newMETHOD($3,$2), list($4))); }
	|	DO sexpr	%prec UNIOP
			{ $$ = newUNOP(OP_DOFILE, 0, scalar($2)); }
	|	DO block	%prec '('
			{ $$ = newUNOP(OP_NULL, OPf_SPECIAL, scope($2)); }
	|	DO WORD '(' ')'
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar($2))), Nullop))); }
	|	DO WORD '(' expr crp
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar($2))),
				$4))); }
	|	DO scalar '(' ')'
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar($2))), Nullop)));}
	|	DO scalar '(' expr crp
			{ $$ = newUNOP(OP_ENTERSUBR, OPf_SPECIAL|OPf_STACKED,
			    list(prepend_elem(OP_LIST,
				scalar(newCVREF(scalar($2))),
				$4))); }
	|	LOOPEX
			{ $$ = newOP($1, OPf_SPECIAL);
			    hints |= HINT_BLOCK_SCOPE; }
	|	LOOPEX sexpr
			{ $$ = newLOOPEX($1,$2); }
	|	UNIOP
			{ $$ = newOP($1, 0); }
	|	UNIOP block
			{ $$ = newUNOP($1, 0, $2); }
	|	UNIOP sexpr
			{ $$ = newUNOP($1, 0, $2); }
	|	FUNC0
			{ $$ = newOP($1, 0); }
	|	FUNC0 '(' ')'
			{ $$ = newOP($1, 0); }
	|	FUNC1 '(' ')'
			{ $$ = newOP($1, OPf_SPECIAL); }
	|	FUNC1 '(' expr ')'
			{ $$ = newUNOP($1, 0, $3); }
	|	PMFUNC '(' sexpr ')'
			{ $$ = pmruntime($1, $3, Nullop); }
	|	PMFUNC '(' sexpr ',' sexpr ')'
			{ $$ = pmruntime($1, $3, $5); }
	|	WORD
	|	listop
	;

listexpr:	/* NULL */
			{ $$ = Nullop; }
	|	expr
			{ $$ = $1; }
	;

amper	:	'&' indirob
			{ $$ = newCVREF($2); }
	;

scalar	:	'$' indirob
			{ $$ = newSVREF($2); }
	;

ary	:	'@' indirob
			{ $$ = newAVREF($2); }
	;

hsh	:	'%' indirob
			{ $$ = newHVREF($2); }
	;

arylen	:	DOLSHARP indirob
			{ $$ = newAVREF($2); }
	;

star	:	'*' indirob
			{ $$ = newGVREF($2); }
	;

indirob	:	WORD
			{ $$ = scalar($1); }
	|	scalar
			{ $$ = scalar($1);  }
	|	block
			{ $$ = scalar(scope($1)); }

	|	PRIVATEREF
			{ $$ = $1; }
	;

crp	:	',' ')'
			{ $$ = 1; }
	|	')'
			{ $$ = 0; }
	;

crb	:	',' ']'
			{ $$ = 1; }
	|	']'
			{ $$ = 0; }
	;

crhb	:	',' ';' '}'
			{ $$ = 1; }
	|	';' '}'
			{ $$ = 0; }
	;

%% /* PROGRAM */
