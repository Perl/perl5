/* $Header: perl.y,v 2.0 88/06/05 00:09:36 root Exp $
 *
 * $Log:	perl.y,v $
 * Revision 2.0  88/06/05  00:09:36  root
 * Baseline version 2.0.
 * 
 */

%{
#include "INTERN.h"
#include "perl.h"

char *tokename[] = {
"256",
"word",
"append","open","write","select","close","loopctl",
"using","format","do","shift","push","pop","chop/study",
"while","until","if","unless","else","elsif","continue","split","sprintf",
"for", "eof", "tell", "seek", "stat",
"function(no args)","function(1 arg)","function(2 args)","function(3 args)","array function",
"join", "sub", "file test", "local", "delete",
"format lines",
"register","array_length", "array",
"s","pattern",
"string","tr",
"list operator",
"..",
"||",
"&&",
"==","!=", "EQ", "NE",
"<=",">=", "LT", "GT", "LE", "GE",
"unary operation",
"file test",
"<<",">>",
"=~","!~",
"unary -",
"++", "--",
"???"
};

STAB *scrstab;

%}

%start prog

%union {
    int	ival;
    char *cval;
    ARG *arg;
    CMD *cmdval;
    struct compcmd compval;
    STAB *stabval;
    FCMD *formval;
}

%token <cval> WORD
%token <ival> APPEND OPEN WRITE SELECT CLOSE LOOPEX
%token <ival> USING FORMAT DO SHIFT PUSH POP LVALFUN
%token <ival> WHILE UNTIL IF UNLESS ELSE ELSIF CONTINUE SPLIT SPRINTF
%token <ival> FOR FEOF TELL SEEK STAT 
%token <ival> FUNC0 FUNC1 FUNC2 FUNC3 STABFUN
%token <ival> JOIN SUB FILETEST LOCAL DELETE
%token <formval> FORMLIST
%token <stabval> REG ARYLEN ARY
%token <arg> SUBST PATTERN
%token <arg> RSTRING TRANS

%type <ival> prog decl format
%type <stabval>
%type <cmdval> block lineseq line loop cond sideff nexpr else
%type <arg> expr sexpr term
%type <arg> condmod loopmod
%type <arg> texpr listop
%type <cval> label
%type <compval> compblock

%nonassoc <ival> LISTOP
%left ','
%right '='
%right '?' ':'
%nonassoc DOTDOT
%left OROR
%left ANDAND
%left '|' '^'
%left '&'
%nonassoc EQ NE SEQ SNE
%nonassoc '<' '>' LE GE SLT SGT SLE SGE
%nonassoc <ival> UNIOP
%nonassoc FILETEST
%left LS RS
%left '+' '-' '.'
%left '*' '/' '%' 'x'
%left MATCH NMATCH 
%right '!' '~' UMINUS
%nonassoc INC DEC
%left '('

%% /* RULES */

prog	:	lineseq
			{ if (in_eval)
				eval_root = block_head($1);
			    else
				main_root = block_head($1); }
	;

compblock:	block CONTINUE block
			{ $$.comp_true = $1; $$.comp_alt = $3; }
	|	block else
			{ $$.comp_true = $1; $$.comp_alt = $2; }
	;

else	:	/* NULL */
			{ $$ = Nullcmd; }
	|	ELSE block
			{ $$ = $2; }
	|	ELSIF '(' expr ')' compblock
			{ cmdline = $1;
			    $$ = make_ccmd(C_IF,$3,$5); }
	;

block	:	'{' lineseq '}'
			{ $$ = block_head($2); }
	;

lineseq	:	/* NULL */
			{ $$ = Nullcmd; }
	|	lineseq line
			{ $$ = append_line($1,$2); }
	;

line	:	decl
			{ $$ = Nullcmd; }
	|	label cond
			{ $$ = add_label($1,$2); }
	|	loop	/* loops add their own labels */
	|	label ';'
			{ if ($1 != Nullch) {
			      $$ = add_label($1, make_acmd(C_EXPR, Nullstab,
				  Nullarg, Nullarg) );
			    } else
			      $$ = Nullcmd; }
	|	label sideff ';'
			{ $$ = add_label($1,$2); }
	;

sideff	:	expr
			{ $$ = make_acmd(C_EXPR, Nullstab, $1, Nullarg); }
	|	expr condmod
			{ $$ = addcond(
			       make_acmd(C_EXPR, Nullstab, Nullarg, $1), $2); }
	|	expr loopmod
			{ $$ = addloop(
			       make_acmd(C_EXPR, Nullstab, Nullarg, $1), $2); }
	;

cond	:	IF '(' expr ')' compblock
			{ cmdline = $1;
			    $$ = make_ccmd(C_IF,$3,$5); }
	|	UNLESS '(' expr ')' compblock
			{ cmdline = $1;
			    $$ = invert(make_ccmd(C_IF,$3,$5)); }
	|	IF block compblock
			{ cmdline = $1;
			    $$ = make_ccmd(C_IF,cmd_to_arg($2),$3); }
	|	UNLESS block compblock
			{ cmdline = $1;
			    $$ = invert(make_ccmd(C_IF,cmd_to_arg($2),$3)); }
	;

loop	:	label WHILE '(' texpr ')' compblock
			{ cmdline = $2;
			    $$ = wopt(add_label($1,
			    make_ccmd(C_WHILE,$4,$6) )); }
	|	label UNTIL '(' expr ')' compblock
			{ cmdline = $2;
			    $$ = wopt(add_label($1,
			    invert(make_ccmd(C_WHILE,$4,$6)) )); }
	|	label WHILE block compblock
			{ cmdline = $2;
			    $$ = wopt(add_label($1,
			    make_ccmd(C_WHILE, cmd_to_arg($3),$4) )); }
	|	label UNTIL block compblock
			{ cmdline = $2;
			    $$ = wopt(add_label($1,
			    invert(make_ccmd(C_WHILE, cmd_to_arg($3),$4)) )); }
	|	label FOR REG '(' expr ')' compblock
			{ cmdline = $2;
			    /*
			     * The following gobbledygook catches EXPRs that
			     * aren't explicit array refs and translates
			     *		foreach VAR (EXPR) {
			     * into
			     *		@ary = EXPR;
			     *		foreach VAR (@ary) {
			     * where @ary is a hidden array made by genstab().
			     */
			    if ($5->arg_type != O_ARRAY) {
				scrstab = aadd(genstab());
				$$ = append_line(
				    make_acmd(C_EXPR, Nullstab,
				      l(make_op(O_ASSIGN,2,
					listish(make_op(O_ARRAY, 1,
					  stab2arg(A_STAB,scrstab),
					  Nullarg,Nullarg, 1)),
					listish($5),
					Nullarg,1)),
				      Nullarg),
				    wopt(over($3,add_label($1,
				      make_ccmd(C_WHILE,
					make_op(O_ARRAY, 1,
					  stab2arg(A_STAB,scrstab),
					  Nullarg,Nullarg, 1 ),
					$7)))));
			    }
			    else {
				$$ = wopt(over($3,add_label($1,
				make_ccmd(C_WHILE,$5,$7) )));
			    }
			}
	|	label FOR '(' expr ')' compblock
			{ cmdline = $2;
			    if ($4->arg_type != O_ARRAY) {
				scrstab = aadd(genstab());
				$$ = append_line(
				    make_acmd(C_EXPR, Nullstab,
				      l(make_op(O_ASSIGN,2,
					listish(make_op(O_ARRAY, 1,
					  stab2arg(A_STAB,scrstab),
					  Nullarg,Nullarg, 1 )),
					listish($4),
					Nullarg,1)),
				      Nullarg),
				    wopt(over(defstab,add_label($1,
				      make_ccmd(C_WHILE,
					make_op(O_ARRAY, 1,
					  stab2arg(A_STAB,scrstab),
					  Nullarg,Nullarg, 1 ),
					$6)))));
			    }
			    else {	/* lisp, anyone? */
				$$ = wopt(over(defstab,add_label($1,
				make_ccmd(C_WHILE,$4,$6) )));
			    }
			}
	|	label FOR '(' nexpr ';' texpr ';' nexpr ')' block
			/* basically fake up an initialize-while lineseq */
			{   yyval.compval.comp_true = $10;
			    yyval.compval.comp_alt = $8;
			    cmdline = $2;
			    $$ = append_line($4,wopt(add_label($1,
				make_ccmd(C_WHILE,$6,yyval.compval) ))); }
	|	label compblock	/* a block is a loop that happens once */
			{ $$ = add_label($1,make_ccmd(C_BLOCK,Nullarg,$2)); }
	;

nexpr	:	/* NULL */
			{ $$ = Nullcmd; }
	|	sideff
	;

texpr	:	/* NULL means true */
			{   scanstr("1"); $$ = yylval.arg; }
	|	expr
	;

label	:	/* empty */
			{ $$ = Nullch; }
	|	WORD ':'
	;

loopmod :	WHILE expr
			{ $$ = $2; }
	|	UNTIL expr
			{ $$ = make_op(O_NOT,1,$2,Nullarg,Nullarg,0); }
	;

condmod :	IF expr
			{ $$ = $2; }
	|	UNLESS expr
			{ $$ = make_op(O_NOT,1,$2,Nullarg,Nullarg,0); }
	;

decl	:	format
			{ $$ = 0; }
	|	subrout
			{ $$ = 0; }
	;

format	:	FORMAT WORD '=' FORMLIST '.' 
			{ stabent($2,TRUE)->stab_form = $4; safefree($2); }
	|	FORMAT '=' FORMLIST '.'
			{ stabent("stdout",TRUE)->stab_form = $3; }
	;

subrout	:	SUB WORD block
			{ make_sub($2,$3); }
	;

expr	:	sexpr ',' expr
			{ $$ = make_op(O_COMMA, 2, $1, $3, Nullarg,0); }
	|	sexpr
	;

sexpr	:	sexpr '=' sexpr
			{   $1 = listish($1);
			    if ($1->arg_type == O_LIST)
				$3 = listish($3);
			    $$ = l(make_op(O_ASSIGN, 2, $1, $3, Nullarg,1)); }
	|	sexpr '*' '=' sexpr
			{ $$ = l(make_op(O_MULTIPLY, 2, $1, $4, Nullarg,0)); }
	|	sexpr '/' '=' sexpr
			{ $$ = l(make_op(O_DIVIDE, 2, $1, $4, Nullarg,0)); }
	|	sexpr '%' '=' sexpr
			{ $$ = l(make_op(O_MODULO, 2, $1, $4, Nullarg,0)); }
	|	sexpr 'x' '=' sexpr
			{ $$ = l(make_op(O_REPEAT, 2, $1, $4, Nullarg,0)); }
	|	sexpr '+' '=' sexpr
			{ $$ = l(make_op(O_ADD, 2, $1, $4, Nullarg,0)); }
	|	sexpr '-' '=' sexpr
			{ $$ = l(make_op(O_SUBTRACT, 2, $1, $4, Nullarg,0)); }
	|	sexpr LS '=' sexpr
			{ $$ = l(make_op(O_LEFT_SHIFT, 2, $1, $4, Nullarg,0)); }
	|	sexpr RS '=' sexpr
			{ $$ = l(make_op(O_RIGHT_SHIFT, 2, $1, $4, Nullarg,0)); }
	|	sexpr '&' '=' sexpr
			{ $$ = l(make_op(O_BIT_AND, 2, $1, $4, Nullarg,0)); }
	|	sexpr '^' '=' sexpr
			{ $$ = l(make_op(O_XOR, 2, $1, $4, Nullarg,0)); }
	|	sexpr '|' '=' sexpr
			{ $$ = l(make_op(O_BIT_OR, 2, $1, $4, Nullarg,0)); }
	|	sexpr '.' '=' sexpr
			{ $$ = l(make_op(O_CONCAT, 2, $1, $4, Nullarg,0)); }


	|	sexpr '*' sexpr
			{ $$ = make_op(O_MULTIPLY, 2, $1, $3, Nullarg,0); }
	|	sexpr '/' sexpr
			{ $$ = make_op(O_DIVIDE, 2, $1, $3, Nullarg,0); }
	|	sexpr '%' sexpr
			{ $$ = make_op(O_MODULO, 2, $1, $3, Nullarg,0); }
	|	sexpr 'x' sexpr
			{ $$ = make_op(O_REPEAT, 2, $1, $3, Nullarg,0); }
	|	sexpr '+' sexpr
			{ $$ = make_op(O_ADD, 2, $1, $3, Nullarg,0); }
	|	sexpr '-' sexpr
			{ $$ = make_op(O_SUBTRACT, 2, $1, $3, Nullarg,0); }
	|	sexpr LS sexpr
			{ $$ = make_op(O_LEFT_SHIFT, 2, $1, $3, Nullarg,0); }
	|	sexpr RS sexpr
			{ $$ = make_op(O_RIGHT_SHIFT, 2, $1, $3, Nullarg,0); }
	|	sexpr '<' sexpr
			{ $$ = make_op(O_LT, 2, $1, $3, Nullarg,0); }
	|	sexpr '>' sexpr
			{ $$ = make_op(O_GT, 2, $1, $3, Nullarg,0); }
	|	sexpr LE sexpr
			{ $$ = make_op(O_LE, 2, $1, $3, Nullarg,0); }
	|	sexpr GE sexpr
			{ $$ = make_op(O_GE, 2, $1, $3, Nullarg,0); }
	|	sexpr EQ sexpr
			{ $$ = make_op(O_EQ, 2, $1, $3, Nullarg,0); }
	|	sexpr NE sexpr
			{ $$ = make_op(O_NE, 2, $1, $3, Nullarg,0); }
	|	sexpr SLT sexpr
			{ $$ = make_op(O_SLT, 2, $1, $3, Nullarg,0); }
	|	sexpr SGT sexpr
			{ $$ = make_op(O_SGT, 2, $1, $3, Nullarg,0); }
	|	sexpr SLE sexpr
			{ $$ = make_op(O_SLE, 2, $1, $3, Nullarg,0); }
	|	sexpr SGE sexpr
			{ $$ = make_op(O_SGE, 2, $1, $3, Nullarg,0); }
	|	sexpr SEQ sexpr
			{ $$ = make_op(O_SEQ, 2, $1, $3, Nullarg,0); }
	|	sexpr SNE sexpr
			{ $$ = make_op(O_SNE, 2, $1, $3, Nullarg,0); }
	|	sexpr '&' sexpr
			{ $$ = make_op(O_BIT_AND, 2, $1, $3, Nullarg,0); }
	|	sexpr '^' sexpr
			{ $$ = make_op(O_XOR, 2, $1, $3, Nullarg,0); }
	|	sexpr '|' sexpr
			{ $$ = make_op(O_BIT_OR, 2, $1, $3, Nullarg,0); }
	|	sexpr DOTDOT sexpr
			{ $$ = make_op(O_FLIP, 4,
			    flipflip($1),
			    flipflip($3),
			    Nullarg,0);}
	|	sexpr ANDAND sexpr
			{ $$ = make_op(O_AND, 2, $1, $3, Nullarg,0); }
	|	sexpr OROR sexpr
			{ $$ = make_op(O_OR, 2, $1, $3, Nullarg,0); }
	|	sexpr '?' sexpr ':' sexpr
			{ $$ = make_op(O_COND_EXPR, 3, $1, $3, $5,0); }
	|	sexpr '.' sexpr
			{ $$ = make_op(O_CONCAT, 2, $1, $3, Nullarg,0); }
	|	sexpr MATCH sexpr
			{ $$ = mod_match(O_MATCH, $1, $3); }
	|	sexpr NMATCH sexpr
			{ $$ = mod_match(O_NMATCH, $1, $3); }
	|	term INC
			{ $$ = addflags(1, AF_POST|AF_UP,
			    l(make_op(O_ITEM,1,$1,Nullarg,Nullarg,0))); }
	|	term DEC
			{ $$ = addflags(1, AF_POST,
			    l(make_op(O_ITEM,1,$1,Nullarg,Nullarg,0))); }
	|	INC term
			{ $$ = addflags(1, AF_PRE|AF_UP,
			    l(make_op(O_ITEM,1,$2,Nullarg,Nullarg,0))); }
	|	DEC term
			{ $$ = addflags(1, AF_PRE,
			    l(make_op(O_ITEM,1,$2,Nullarg,Nullarg,0))); }
	|	term
			{ $$ = $1; }
	;

term	:	'-' term %prec UMINUS
			{ $$ = make_op(O_NEGATE, 1, $2, Nullarg, Nullarg,0); }
	|	'!' term
			{ $$ = make_op(O_NOT, 1, $2, Nullarg, Nullarg,0); }
	|	'~' term
			{ $$ = make_op(O_COMPLEMENT, 1, $2, Nullarg, Nullarg,0);}
	|	FILETEST WORD
			{ opargs[$1] = 0;	/* force it special */
			    $$ = make_op($1, 1,
				stab2arg(A_STAB,stabent($2,TRUE)),
				Nullarg, Nullarg,0);
			}
	|	FILETEST sexpr
			{ opargs[$1] = 1;
			    $$ = make_op($1, 1, $2, Nullarg, Nullarg,0); }
	|	FILETEST
			{ opargs[$1] = ($1 != O_FTTTY);
			    $$ = make_op($1, 1,
				stab2arg(A_STAB,
				  $1 == O_FTTTY?stabent("stdin",TRUE):defstab),
				Nullarg, Nullarg,0); }
	|	LOCAL '(' expr ')'
			{ $$ = localize(listish(make_list(hide_ary($3)))); }
	|	'(' expr ')'
			{ $$ = make_list(hide_ary($2)); }
	|	'(' ')'
			{ $$ = make_list(Nullarg); }
	|	DO sexpr	%prec FILETEST
			{ $$ = make_op(O_DOFILE,1,$2,Nullarg,Nullarg,0);
			    allstabs = TRUE;}
	|	DO block	%prec '('
			{ $$ = cmd_to_arg($2); }
	|	REG	%prec '('
			{ $$ = stab2arg(A_STAB,$1); }
	|	REG '[' expr ']'	%prec '('
			{ $$ = make_op(O_ARRAY, 2,
				$3, stab2arg(A_STAB,aadd($1)), Nullarg,0); }
	|	ARY 	%prec '('
			{ $$ = make_op(O_ARRAY, 1,
				stab2arg(A_STAB,$1),
				Nullarg, Nullarg, 1); }
	|	REG '{' expr '}'	%prec '('
			{ $$ = make_op(O_HASH, 2,
				$3, stab2arg(A_STAB,hadd($1)), Nullarg,0); }
	|	DELETE REG '{' expr '}'	%prec '('
			{ $$ = make_op(O_DELETE, 2,
				$4, stab2arg(A_STAB,hadd($2)), Nullarg,0); }
	|	ARYLEN	%prec '('
			{ $$ = stab2arg(A_ARYLEN,$1); }
	|	RSTRING	%prec '('
			{ $$ = $1; }
	|	PATTERN	%prec '('
			{ $$ = $1; }
	|	SUBST	%prec '('
			{ $$ = $1; }
	|	TRANS	%prec '('
			{ $$ = $1; }
	|	DO WORD '(' expr ')'
			{ $$ = make_op(O_SUBR, 2,
				make_list($4),
				stab2arg(A_WORD,stabent($2,TRUE)),
				Nullarg,1); }
	|	DO WORD '(' ')'
			{ $$ = make_op(O_SUBR, 2,
				make_list(Nullarg),
				stab2arg(A_WORD,stabent($2,TRUE)),
				Nullarg,1); }
	|	DO REG '(' expr ')'
			{ $$ = make_op(O_SUBR, 2,
				make_list($4),
				stab2arg(A_STAB,$2),
				Nullarg,1); }
	|	DO REG '(' ')'
			{ $$ = make_op(O_SUBR, 2,
				make_list(Nullarg),
				stab2arg(A_STAB,$2),
				Nullarg,1); }
	|	LOOPEX
			{ $$ = make_op($1,0,Nullarg,Nullarg,Nullarg,0); }
	|	LOOPEX WORD
			{ $$ = make_op($1,1,cval_to_arg($2),
			    Nullarg,Nullarg,0); }
	|	UNIOP
			{ $$ = make_op($1,1,Nullarg,Nullarg,Nullarg,0); }
	|	UNIOP sexpr
			{ $$ = make_op($1,1,$2,Nullarg,Nullarg,0); }
	|	WRITE
			{ $$ = make_op(O_WRITE, 0,
			    Nullarg, Nullarg, Nullarg,0); }
	|	WRITE '(' ')'
			{ $$ = make_op(O_WRITE, 0,
			    Nullarg, Nullarg, Nullarg,0); }
	|	WRITE '(' WORD ')'
			{ $$ = l(make_op(O_WRITE, 1,
			    stab2arg(A_STAB,stabent($3,TRUE)),
			    Nullarg, Nullarg,0)); safefree($3); }
	|	WRITE '(' expr ')'
			{ $$ = make_op(O_WRITE, 1, $3, Nullarg, Nullarg,0); }
	|	SELECT '(' WORD ')'
			{ $$ = l(make_op(O_SELECT, 1,
			    stab2arg(A_STAB,stabent($3,TRUE)),
			    Nullarg, Nullarg,0)); safefree($3); }
	|	SELECT '(' expr ')'
			{ $$ = make_op(O_SELECT, 1, $3, Nullarg, Nullarg,0); }
	|	OPEN WORD	%prec '('
			{ $$ = make_op(O_OPEN, 2,
			    stab2arg(A_WORD,stabent($2,TRUE)),
			    stab2arg(A_STAB,stabent($2,TRUE)),
			    Nullarg,0); }
	|	OPEN '(' WORD ')'
			{ $$ = make_op(O_OPEN, 2,
			    stab2arg(A_WORD,stabent($3,TRUE)),
			    stab2arg(A_STAB,stabent($3,TRUE)),
			    Nullarg,0); }
	|	OPEN '(' WORD ',' expr ')'
			{ $$ = make_op(O_OPEN, 2,
			    stab2arg(A_WORD,stabent($3,TRUE)),
			    $5, Nullarg,0); }
	|	OPEN '(' sexpr ',' expr ')'
			{ $$ = make_op(O_OPEN, 2,
			    $3,
			    $5, Nullarg,0); }
	|	CLOSE '(' WORD ')'
			{ $$ = make_op(O_CLOSE, 1,
			    stab2arg(A_WORD,stabent($3,TRUE)),
			    Nullarg, Nullarg,0); }
	|	CLOSE '(' expr ')'
			{ $$ = make_op(O_CLOSE, 1,
			    $3,
			    Nullarg, Nullarg,0); }
	|	CLOSE WORD	%prec '('
			{ $$ = make_op(O_CLOSE, 1,
			    stab2arg(A_WORD,stabent($2,TRUE)),
			    Nullarg, Nullarg,0); }
	|	FEOF '(' WORD ')'
			{ $$ = make_op(O_EOF, 1,
			    stab2arg(A_WORD,stabent($3,TRUE)),
			    Nullarg, Nullarg,0); }
	|	FEOF '(' expr ')'
			{ $$ = make_op(O_EOF, 1,
			    $3,
			    Nullarg, Nullarg,0); }
	|	FEOF '(' ')'
			{ $$ = make_op(O_EOF, 1,
			    stab2arg(A_WORD,Nullstab),
			    Nullarg, Nullarg,0); }
	|	FEOF
			{ $$ = make_op(O_EOF, 0,
			    Nullarg, Nullarg, Nullarg,0); }
	|	TELL '(' WORD ')'
			{ $$ = make_op(O_TELL, 1,
			    stab2arg(A_WORD,stabent($3,TRUE)),
			    Nullarg, Nullarg,0); }
	|	TELL '(' expr ')'
			{ $$ = make_op(O_TELL, 1,
			    $3,
			    Nullarg, Nullarg,0); }
	|	TELL
			{ $$ = make_op(O_TELL, 0,
			    Nullarg, Nullarg, Nullarg,0); }
	|	SEEK '(' WORD ',' sexpr ',' expr ')'
			{ $$ = make_op(O_SEEK, 3,
			    stab2arg(A_WORD,stabent($3,TRUE)),
			    $5, $7,1); }
	|	SEEK '(' sexpr ',' sexpr ',' expr ')'
			{ $$ = make_op(O_SEEK, 3,
			    $3,
			    $5, $7,1); }
	|	PUSH '(' WORD ',' expr ')'
			{ $$ = make_op($1, 2,
			    make_list($5),
			    stab2arg(A_STAB,aadd(stabent($3,TRUE))),
			    Nullarg,1); }
	|	PUSH '(' ARY ',' expr ')'
			{ $$ = make_op($1, 2,
			    make_list($5),
			    stab2arg(A_STAB,$3),
			    Nullarg,1); }
	|	POP WORD	%prec '('
			{ $$ = make_op(O_POP, 1,
			    stab2arg(A_STAB,aadd(stabent($2,TRUE))),
			    Nullarg, Nullarg,0); }
	|	POP '(' WORD ')'
			{ $$ = make_op(O_POP, 1,
			    stab2arg(A_STAB,aadd(stabent($3,TRUE))),
			    Nullarg, Nullarg,0); }
	|	POP ARY	%prec '('
			{ $$ = make_op(O_POP, 1,
			    stab2arg(A_STAB,$2),
			    Nullarg,
			    Nullarg,
			    0); }
	|	POP '(' ARY ')'
			{ $$ = make_op(O_POP, 1,
			    stab2arg(A_STAB,$3),
			    Nullarg,
			    Nullarg,
			    0); }
	|	SHIFT WORD	%prec '('
			{ $$ = make_op(O_SHIFT, 1,
			    stab2arg(A_STAB,aadd(stabent($2,TRUE))),
			    Nullarg, Nullarg,0); }
	|	SHIFT '(' WORD ')'
			{ $$ = make_op(O_SHIFT, 1,
			    stab2arg(A_STAB,aadd(stabent($3,TRUE))),
			    Nullarg, Nullarg,0); }
	|	SHIFT ARY	%prec '('
			{ $$ = make_op(O_SHIFT, 1,
			    stab2arg(A_STAB,$2), Nullarg, Nullarg,0); }
	|	SHIFT '(' ARY ')'
			{ $$ = make_op(O_SHIFT, 1,
			    stab2arg(A_STAB,$3), Nullarg, Nullarg,0); }
	|	SHIFT	%prec '('
			{ $$ = make_op(O_SHIFT, 1,
			    stab2arg(A_STAB,aadd(stabent("ARGV",TRUE))),
			    Nullarg, Nullarg,0); }
	|	SPLIT	%prec '('
			{ scanpat("/\\s+/");
			    $$ = make_split(defstab,yylval.arg); }
	|	SPLIT '(' WORD ')'
			{ scanpat("/\\s+/");
			    $$ = make_split(stabent($3,TRUE),yylval.arg); }
	|	SPLIT '(' WORD ',' PATTERN ')'
			{ $$ = make_split(stabent($3,TRUE),$5); }
	|	SPLIT '(' WORD ',' PATTERN ',' sexpr ')'
			{ $$ = mod_match(O_MATCH,
			    $7,
			    make_split(stabent($3,TRUE),$5) ); }
	|	SPLIT '(' sexpr ',' sexpr ')'
			{ $$ = mod_match(O_MATCH, $5, make_split(defstab,$3) ); }
	|	SPLIT '(' sexpr ')'
			{ $$ = mod_match(O_MATCH,
			    stab2arg(A_STAB,defstab),
			    make_split(defstab,$3) ); }
	|	JOIN '(' WORD ',' expr ')'
			{ $$ = make_op(O_JOIN, 2,
			    $5,
			    stab2arg(A_STAB,aadd(stabent($3,TRUE))),
			    Nullarg,0); }
	|	JOIN '(' sexpr ',' expr ')'
			{ $$ = make_op(O_JOIN, 2,
			    $3,
			    make_list($5),
			    Nullarg,2); }
	|	SPRINTF '(' expr ')'
			{ $$ = make_op(O_SPRINTF, 1,
			    make_list($3),
			    Nullarg,
			    Nullarg,1); }
	|	STAT '(' WORD ')'
			{ $$ = l(make_op(O_STAT, 1,
			    stab2arg(A_STAB,stabent($3,TRUE)),
			    Nullarg, Nullarg,0)); }
	|	STAT '(' expr ')'
			{ $$ = make_op(O_STAT, 1, $3, Nullarg, Nullarg,0); }
	|	LVALFUN
			{ $$ = l(make_op($1, 1,
			    stab2arg(A_STAB,defstab),
			    Nullarg, Nullarg,0)); }
	|	LVALFUN '(' expr ')'
			{ $$ = l(make_op($1, 1, $3, Nullarg, Nullarg,0)); }
	|	FUNC0
			{ $$ = make_op($1, 0, Nullarg, Nullarg, Nullarg,0); }
	|	FUNC1 '(' expr ')'
			{ $$ = make_op($1, 1, $3, Nullarg, Nullarg,0); }
	|	FUNC2 '(' sexpr ',' expr ')'
			{ $$ = make_op($1, 2, $3, $5, Nullarg, 0);
			    if ($1 == O_INDEX && $$[2].arg_type == A_SINGLE)
				fbmcompile($$[2].arg_ptr.arg_str); }
	|	FUNC3 '(' sexpr ',' sexpr ',' expr ')'
			{ $$ = make_op($1, 3, $3, $5, $7, 0); }
	|	STABFUN '(' WORD ')'
			{ $$ = make_op($1, 1,
				stab2arg(A_STAB,hadd(stabent($3,TRUE))),
				Nullarg,
				Nullarg, 0); }
	|	listop
	;

listop	:	LISTOP
			{ $$ = make_op($1,2,
				stab2arg(A_STAB,defstab),
				stab2arg(A_WORD,Nullstab),
				Nullarg,0); }
	|	LISTOP expr
			{ $$ = make_op($1,2,make_list($2),
				stab2arg(A_WORD,Nullstab),
				Nullarg,1); }
	|	LISTOP WORD
			{ $$ = make_op($1,2,
				stab2arg(A_STAB,defstab),
				stab2arg(A_WORD,stabent($2,TRUE)),
				Nullarg,1); }
	|	LISTOP WORD expr
			{ $$ = make_op($1,2,make_list($3),
				stab2arg(A_WORD,stabent($2,TRUE)),
				Nullarg,1); }
	|	LISTOP REG expr
			{ $$ = make_op($1,2,make_list($3),
				stab2arg(A_STAB,$2),
				Nullarg,1); }
	;

%% /* PROGRAM */
