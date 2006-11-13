/*    perly.y
 *
 *    Copyright (c) 1991-2002, 2003, 2004 Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * 'I see,' laughed Strider.  'I look foul and feel fair.  Is that it?
 * All that is gold does not glitter, not all those who wander are lost.'
 */

/*  Make the parser re-entrant. */

/* FIXME for MAD - is the new mintro on while and until important?  */
%pure_parser

%start prog

%union {
    I32	ival;
    char *pval;
    TOKEN* tkval;
    OP *opval;
    GV *gvval;
}

%token <tkval> '{' '}' '[' ']' '-' '+' '$' '@' '%' '*'

%token <opval> WORD METHOD FUNCMETH THING PMFUNC PRIVATEREF
%token <opval> FUNC0SUB UNIOPSUB LSTOPSUB
%token <tkval> LABEL
%token <tkval> FORMAT SUB ANONSUB PACKAGE USE
%token <tkval> WHILE UNTIL IF UNLESS ELSE ELSIF CONTINUE FOR
%token <tkval> GIVEN WHEN DEFAULT
%token <tkval> LOOPEX DOTDOT
%token <tkval> FUNC0 FUNC1 FUNC UNIOP LSTOP
%token <tkval> RELOP EQOP MULOP ADDOP
%token <tkval> DOLSHARP DO HASHBRACK NOAMP
%token <tkval> LOCAL MY MYSUB REQUIRE
%token <tkval> COLONATTR

%type <ival> prog progstart remember mremember savescope
%type <ival>  startsub startanonsub startformsub
/* FIXME for MAD - are these two ival? */
%type <ival> mydefsv mintro

%type <tkval> '&' ';'

%type <opval> decl format subrout mysubrout package use peg

%type <opval> block mblock lineseq line loop cond else
%type <opval> expr term subscripted scalar ary hsh arylen star amper sideff
%type <opval> argexpr nexpr texpr iexpr mexpr mnexpr miexpr
%type <opval> listexpr listexprcom indirob listop method
%type <opval> formname subname proto subbody cont my_scalar
%type <opval> subattrlist myattrlist myattrterm myterm
%type <opval> termbinop termunop anonymous termdo
%type <opval> switch case
%type <tkval> label

%nonassoc <tkval> PREC_LOW
%nonassoc LOOPEX

%left <tkval> OROP DOROP
%left <tkval> ANDOP
%right <tkval> NOTOP
%nonassoc LSTOP LSTOPSUB
%left <tkval> ','
%right <tkval> ASSIGNOP
%right <tkval> '?' ':'
%nonassoc DOTDOT
%left <tkval> OROR DORDOR
%left <tkval> ANDAND
%left <tkval> BITOROP
%left <tkval> BITANDOP
%nonassoc EQOP
%nonassoc RELOP
%nonassoc UNIOP UNIOPSUB
%nonassoc REQUIRE
%left <tkval> SHIFTOP
%left ADDOP
%left MULOP
%left <tkval> MATCHOP
%right <tkval> '!' '~' UMINUS REFGEN
%right <tkval> POWOP
%nonassoc <tkval> PREINC PREDEC POSTINC POSTDEC
%left <tkval> ARROW
%nonassoc <tkval> ')'
%left <tkval> '('
%left '[' '{'

%token <tkval> PEG

%% /* RULES */

/* The whole program */
prog	:	progstart
	/*CONTINUED*/	lineseq
			{ $$ = $1; newPROG(block_end($1,$2)); }
	;

/* An ordinary block */
block	:	'{' remember lineseq '}'
			{ if (PL_copline > (line_t)($1)->tk_lval.ival)
			      PL_copline = (line_t)($1)->tk_lval.ival;
			  $$ = block_end($2, $3);
			  token_getmad($1,$$,'{');
			  token_getmad($4,$$,'}');
			}
	;

remember:	/* NULL */	/* start a full lexical scope */
			{ $$ = block_start(TRUE); }
	;

mydefsv:	/* NULL */	/* lexicalize $_ */
			{ $$ = (I32) allocmy("$_"); }
	;

progstart:
		{
		    PL_expect = XSTATE; $$ = block_start(TRUE);
		}
	;


mblock	:	'{' mremember lineseq '}'
			{ if (PL_copline > (line_t)($1)->tk_lval.ival)
			      PL_copline = (line_t)($1)->tk_lval.ival;
			  $$ = block_end($2, $3);
			  token_getmad($1,$$,'{');
			  token_getmad($4,$$,'}');
			}
	;

mremember:	/* NULL */	/* start a partial lexical scope */
			{ $$ = block_start(FALSE); }
	;

savescope:	/* NULL */	/* remember stack pos in case of error */
		{ $$ = PL_savestack_ix; }

/* A collection of "lines" in the program */
lineseq	:	/* NULL */
			{ $$ = Nullop; }
	|	lineseq decl
/*			{ $$ = $1 } */
			{ $$ = append_list(OP_LINESEQ,
				(LISTOP*)$1, (LISTOP*)$2); }
	|	lineseq savescope line
			{   LEAVE_SCOPE($2);
			    $$ = append_list(OP_LINESEQ,
				(LISTOP*)$1, (LISTOP*)$3);
			    PL_pad_reset_pending = TRUE;
			    if ($1 && $3) PL_hints |= HINT_BLOCK_SCOPE; }
	;

/* A "line" in the program */
line	:	label cond
			{ $$ = newSTATEOP(0, ($1)->tk_lval.pval, $2);
			  token_getmad($1,((LISTOP*)$$)->op_first,'L'); }
	|	loop	/* loops add their own labels */
	|	switch  /* ... and so do switches */
			{ $$ = $1; }
	|	label case
			{ $$ = newSTATEOP(0, ($1)->tk_lval.pval, $2); }
	|	label ';'
			{
			  if (($1)->tk_lval.pval) {
			      $$ = newSTATEOP(0, ($1)->tk_lval.pval, newOP(OP_NULL, 0));
			      token_getmad($1,$$,'L');
			      token_getmad($2,((LISTOP*)$$)->op_first,';');
			  }
			  else {
			      $$ = newOP(OP_NULL, 0);
                              PL_copline = NOLINE;
			      token_free($1);
			      token_getmad($2,$$,';');
			  }
			  PL_expect = XSTATE;
			}
	|	label sideff ';'
			{ OP* op;
			  $$ = newSTATEOP(0, ($1)->tk_lval.pval, $2);
			  PL_expect = XSTATE;
			  /* sideff might already have a nexstate */
			  op = ((LISTOP*)$$)->op_first;
			  if (op) {
			      while (op->op_sibling &&
				 op->op_sibling->op_type == OP_NEXTSTATE)
				    op = op->op_sibling;
			      token_getmad($1,op,'L');
			      token_getmad($3,op,';');
			  }
			}
	;

/* An expression which may have a side-effect */
sideff	:	error
			{ $$ = Nullop; }
	|	expr
			{ $$ = $1; }
	|	expr IF expr
			{ $$ = newLOGOP(OP_AND, 0, $3, $1);
			  token_getmad($2,$$,'i');
			}
	|	expr UNLESS expr
			{ $$ = newLOGOP(OP_OR, 0, $3, $1);
			  token_getmad($2,$$,'i');
			}
	|	expr WHILE expr
			{ $$ = newLOOPOP(OPf_PARENS, 1, scalar($3), $1);
			  token_getmad($2,$$,'w');
			}
	|	expr UNTIL iexpr
			{ $$ = newLOOPOP(OPf_PARENS, 1, $3, $1);
			  token_getmad($2,$$,'w');
			}
	|	expr FOR expr
			{ $$ = newFOROP(0, Nullch, (line_t)($2)->tk_lval.ival,
					Nullop, $3, $1, Nullop);
			  token_getmad($2,((LISTOP*)$$)->op_first->op_sibling,'w');
			}
	;

/* else and elsif blocks */
else	:	/* NULL */
			{ $$ = Nullop; }
	|	ELSE mblock
			{ ($2)->op_flags |= OPf_PARENS; $$ = scope($2);
			  token_getmad($1,$$,'o');
			}
	|	ELSIF '(' mexpr ')' mblock else
			{ PL_copline = (line_t)($1)->tk_lval.ival;
			    $$ = newCONDOP(0, $3, scope($5), $6);
			    PL_hints |= HINT_BLOCK_SCOPE;
			  token_getmad($1,$$,'I');
			  token_getmad($2,$$,'(');
			  token_getmad($4,$$,')');
			}
	;

/* Real conditional expressions */
cond	:	IF '(' remember mexpr ')' mblock else
			{ PL_copline = (line_t)($1)->tk_lval.ival;
			    $$ = block_end($3,
				   newCONDOP(0, $4, scope($6), $7));
			  token_getmad($1,$$,'I');
			  token_getmad($2,$$,'(');
			  token_getmad($5,$$,')');
			}
	|	UNLESS '(' remember miexpr ')' mblock else
			{ PL_copline = (line_t)($1)->tk_lval.ival;
			    $$ = block_end($3,
				   newCONDOP(0, $4, scope($6), $7));
			  token_getmad($1,$$,'I');
			  token_getmad($2,$$,'(');
			  token_getmad($5,$$,')');
			}
	;

/* Cases for a switch statement */
case	:	WHEN '(' remember mexpr ')' mblock
	{ $$ = block_end($3,
		newWHENOP($4, scope($6))); }
	|	DEFAULT block
	{ $$ = newWHENOP(0, scope($2)); }
	;

/* Continue blocks */
cont	:	/* NULL */
			{ $$ = Nullop; }
	|	CONTINUE block
			{ $$ = scope($2);
			  token_getmad($1,$$,'o');
			}
	;

/* Loops: while, until, for, and a bare block */
loop	:	label WHILE '(' remember texpr ')' mintro mblock cont
			{ OP *innerop;
			  PL_copline = (line_t)$2;
			    $$ = block_end($4,
				   newSTATEOP(0, ($1)->tk_lval.pval,
				     innerop = newWHILEOP(0, 1, (LOOP*)Nullop,
						($2)->tk_lval.ival, $5, $8, $9, $7)));
			  token_getmad($1,innerop,'L');
			  token_getmad($2,innerop,'W');
			  token_getmad($3,innerop,'(');
			  token_getmad($6,innerop,')');
			}

	|	label UNTIL '(' remember iexpr ')' mintro mblock cont
			{ OP *innerop;
			  PL_copline = (line_t)$2;
			    $$ = block_end($4,
				   newSTATEOP(0, ($1)->tk_lval.pval,
				     newWHILEOP(0, 1, (LOOP*)Nullop,
						($2)->tk_lval.ival, $5, $8, $9, $7)));
			  token_getmad($1,innerop,'L');
			  token_getmad($2,innerop,'W');
			  token_getmad($3,innerop,'(');
			  token_getmad($6,innerop,')');
			}
	|	label FOR MY remember my_scalar '(' mexpr ')' mblock cont
			{ OP *innerop;
			  $$ = block_end($4,
			     innerop = newFOROP(0, ($1)->tk_lval.pval, (line_t)($2)->tk_lval.ival, $5, $7, $9, $10));
			  token_getmad($1,((LISTOP*)innerop)->op_first,'L');
			  token_getmad($2,((LISTOP*)innerop)->op_first->op_sibling,'W');
			  token_getmad($3,((LISTOP*)innerop)->op_first->op_sibling,'d');
			  token_getmad($6,((LISTOP*)innerop)->op_first->op_sibling,'(');
			  token_getmad($8,((LISTOP*)innerop)->op_first->op_sibling,')');
			}
	|	label FOR scalar '(' remember mexpr ')' mblock cont
			{ OP *innerop;
			  $$ = block_end($5,
			     innerop = newFOROP(0, ($1)->tk_lval.pval, (line_t)($2)->tk_lval.ival, mod($3, OP_ENTERLOOP),
					  $6, $8, $9));
			  token_getmad($1,((LISTOP*)innerop)->op_first,'L');
			  token_getmad($2,((LISTOP*)innerop)->op_first->op_sibling,'W');
			  token_getmad($4,((LISTOP*)innerop)->op_first->op_sibling,'(');
			  token_getmad($7,((LISTOP*)innerop)->op_first->op_sibling,')');
			}
	|	label FOR '(' remember mexpr ')' mblock cont
			{ OP *innerop;
			  $$ = block_end($4,
			     innerop = newFOROP(0, ($1)->tk_lval.pval, (line_t)($2)->tk_lval.ival, Nullop, $5, $7, $8));
			  token_getmad($1,((LISTOP*)innerop)->op_first,'L');
			  token_getmad($2,((LISTOP*)innerop)->op_first->op_sibling,'W');
			  token_getmad($3,((LISTOP*)innerop)->op_first->op_sibling,'(');
			  token_getmad($6,((LISTOP*)innerop)->op_first->op_sibling,')');
			}
	|	label FOR '(' remember mnexpr ';' texpr ';' mintro mnexpr ')'
	    	    mblock
			/* basically fake up an initialize-while lineseq */
			{ OP *forop;
			  PL_copline = (line_t)($2)->tk_lval.ival;
			  forop = newSTATEOP(0, ($1)->tk_lval.pval,
					    newWHILEOP(0, 1, (LOOP*)Nullop,
						($2)->tk_lval.ival, scalar($7),
						$12, $10, $9));
			  if (!$5)
				$5 = newOP(OP_NULL, 0);
			  forop = newUNOP(OP_NULL, 0, append_elem(OP_LINESEQ,
				newSTATEOP(0,
					   (($1)->tk_lval.pval
					   ?savepv(($1)->tk_lval.pval):Nullch),
					   $5),
				forop));

			  token_getmad($2,forop,'3');
			  token_getmad($3,forop,'(');
			  token_getmad($6,forop,'1');
			  token_getmad($8,forop,'2');
			  token_getmad($11,forop,')');
			  token_getmad($1,forop,'L');
			  $$ = block_end($4, forop); }
	|	label block cont  /* a block is a loop that happens once */
			{ $$ = newSTATEOP(0, ($1)->tk_lval.pval,
				 newWHILEOP(0, 1, (LOOP*)Nullop,
					    NOLINE, Nullop, $2, $3, 0));
			  token_getmad($1,((LISTOP*)$$)->op_first,'L'); }
	;

/* Switch blocks */
switch	:	label GIVEN '(' remember mydefsv mexpr ')' mblock
			{ PL_copline = (line_t) $2;
			    $$ = block_end($4,
				newSTATEOP(0, ($1)->tk_lval.pval,
				    newGIVENOP($6, scope($8),
					(PADOFFSET) $5) )); }
	;

/* determine whether there are any new my declarations */
mintro	:	/* NULL */
			{ $$ = (PL_min_intro_pending &&
			    PL_max_intro_pending >=  PL_min_intro_pending);
			  intro_my(); }

/* Normal expression */
nexpr	:	/* NULL */
			{ $$ = Nullop; }
	|	sideff
	;

/* Boolean expression */
texpr	:	/* NULL means true */
			{ YYSTYPE tmplval;
			  (void)scan_num("1", &tmplval);
			  $$ = tmplval.opval; }
	|	expr
	;

/* Inverted boolean expression */
iexpr	:	expr
			{ $$ = invert(scalar($1)); }
	;

/* Expression with its own lexical scope */
mexpr	:	expr
			{ $$ = $1; intro_my(); }
	;

mnexpr	:	nexpr
			{ $$ = $1; intro_my(); }
	;

miexpr	:	iexpr
			{ $$ = $1; intro_my(); }
	;

/* Optional "MAIN:"-style loop labels */
label	:	/* empty */
			{ YYSTYPE tmplval;
			  tmplval.pval = Nullch;
			  $$ = newTOKEN(OP_NULL, tmplval, 0); }
	|	LABEL
	;

/* Some kind of declaration - just hang on peg in the parse tree */
decl	:	format
			{ $$ = $1; }
	|	subrout
			{ $$ = $1; }
	|	mysubrout
			{ $$ = $1; }
	|	package
			{ $$ = $1; }
	|	use
			{ $$ = $1; }
	|	peg
			{ $$ = $1; }
	;

peg	:	PEG
			{ $$ = newOP(OP_NULL,0);
			  token_getmad($1,$$,'p');
			}
	;

format	:	FORMAT startformsub formname block
			{ SvREFCNT_inc(PL_compcv);
			  $$ = newFORM($2, $3, $4);
			  prepend_madprops($1->tk_mad, $$, 'F');
			  $1->tk_mad = 0;
			  token_free($1);
			}
	;

formname:	WORD		{ $$ = $1; }
	|	/* NULL */	{ $$ = Nullop; }
	;

/* Unimplemented "my sub foo { }" */
mysubrout:	MYSUB startsub subname proto subattrlist subbody
			{ SvREFCNT_inc(PL_compcv);
			  $$ = newMYSUB($2, $3, $4, $5, $6);
			  token_getmad($1,$$,'d');
			}
	;

/* Subroutine definition */
subrout	:	SUB startsub subname proto subattrlist subbody
			{ SvREFCNT_inc(PL_compcv);
			  OP* o = newSVOP(OP_ANONCODE, 0,
			    (SV*)newATTRSUB($2, $3, $4, $5, $6));
			  $$ = newOP(OP_NULL,0);
			  op_getmad(o,$$,'&');
			  op_getmad($3,$$,'n');
			  op_getmad($4,$$,'s');
			  op_getmad($5,$$,'a');
			  token_getmad($1,$$,'d');
			  append_madprops($6->op_madprop, $$, 0);
			  $6->op_madprop = 0;
			}
	;

startsub:	/* NULL */	/* start a regular subroutine scope */
			{ $$ = start_subparse(FALSE, 0);
			    SAVEFREESV(PL_compcv); }

	;

startanonsub:	/* NULL */	/* start an anonymous subroutine scope */
			{ $$ = start_subparse(FALSE, CVf_ANON);
			    SAVEFREESV(PL_compcv); }
	;

startformsub:	/* NULL */	/* start a format subroutine scope */
			{ $$ = start_subparse(TRUE, 0);
			    SAVEFREESV(PL_compcv); }
	;

/* Name of a subroutine - must be a bareword, could be special */
subname	:	WORD	{ const char *const name = SvPV_nolen_const(((SVOP*)$1)->op_sv);
			  if (strEQ(name, "BEGIN") || strEQ(name, "END")
			      || strEQ(name, "INIT") || strEQ(name, "CHECK")
			      || strEQ(name, "UNITCHECK"))
			      CvSPECIAL_on(PL_compcv);
			  $$ = $1; }
	;

/* Subroutine prototype */
proto	:	/* NULL */
			{ $$ = Nullop; }
	|	THING
	;

/* Optional list of subroutine attributes */
subattrlist:	/* NULL */
			{ $$ = Nullop; }
	|	COLONATTR THING
			{ $$ = $2;
			  token_getmad($1,$$,':');
			}
	|	COLONATTR
			{ $$ = newOP(OP_NULL, 0);
			  token_getmad($1,$$,':');
			}
	;

/* List of attributes for a "my" variable declaration */
myattrlist:	COLONATTR THING
			{ $$ = $2;
			  token_getmad($1,$$,':');
			}
	|	COLONATTR
			{ $$ = newOP(OP_NULL, 0);
			  token_getmad($1,$$,':');
			}
	;

/* Subroutine body - either null or a block */
subbody	:	block	{ $$ = $1; }
	|	';'	{ $$ = newOP(OP_NULL,0); PL_expect = XSTATE;
			  token_getmad($1,$$,';');
			}
	;

package :	PACKAGE WORD ';'
			{ $$ = package($2);
			  token_getmad($1,$$,'o');
			  token_getmad($3,$$,';');
			}
	;

use	:	USE startsub
			{ CvSPECIAL_on(PL_compcv); /* It's a BEGIN {} */ }
		    WORD WORD listexpr ';'
			{ SvREFCNT_inc(PL_compcv);
			  $$ = utilize(($1)->tk_lval.ival, $2, $4, $5, $6);
			  token_getmad($1,$$,'o');
			  token_getmad($7,$$,';');
			  if (PL_rsfp_filters && AvFILLp(PL_rsfp_filters) >= 0)
			      append_madprops(newMADPROP('!', MAD_PV, "", 0), $$, 0);
			}
	;

/* Ordinary expressions; logical combinations */
expr	:	expr ANDOP expr
			{ $$ = newLOGOP(OP_AND, 0, $1, $3);
			  token_getmad($2,$$,'o');
			}
	|	expr OROP expr
			{ $$ = newLOGOP(($2)->tk_lval.ival, 0, $1, $3);
			  token_getmad($2,$$,'o');
			}
	|	expr DOROP expr
			{ $$ = newLOGOP(OP_DOR, 0, $1, $3);
			  token_getmad($2,$$,'o');
			}
	|	argexpr %prec PREC_LOW
	;

/* Expressions are a list of terms joined by commas */
argexpr	:	argexpr ','
			{ OP* op = newNULLLIST();
			  token_getmad($2,op,',');
			  $$ = append_elem(OP_LIST, $1, op);
			}
	|	argexpr ',' term
			{ 
			  $3 = newUNOP(OP_NULL, 0, $3);
			  token_getmad($2,$3,',');
			  $$ = append_elem(OP_LIST, $1, $3);
			}
	|	term %prec PREC_LOW
	;

/* List operators */
listop	:	LSTOP indirob argexpr          /* print $fh @args */
			{ $$ = convert(($1)->tk_lval.ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(($1)->tk_lval.ival,$2), $3) );
			  token_getmad($1,$$,'o');
			}
	|	FUNC '(' indirob expr ')'      /* print ($fh @args */
			{ $$ = convert(($1)->tk_lval.ival, OPf_STACKED,
				prepend_elem(OP_LIST, newGVREF(($1)->tk_lval.ival,$3), $4) );
			  token_getmad($1,$$,'o');
			  token_getmad($2,$$,'(');
			  token_getmad($5,$$,')');
			}
	|	term ARROW method '(' listexprcom ')' /* $foo->bar(list) */
			{ $$ = convert(OP_ENTERSUB, OPf_STACKED,
				append_elem(OP_LIST,
				    prepend_elem(OP_LIST, scalar($1), $5),
				    newUNOP(OP_METHOD, 0, $3)));
			  token_getmad($2,$$,'A');
			  token_getmad($4,$$,'(');
			  token_getmad($6,$$,')');
			}
	|	term ARROW method                     /* $foo->bar */
			{ $$ = convert(OP_ENTERSUB, OPf_STACKED,
				append_elem(OP_LIST, scalar($1),
				    newUNOP(OP_METHOD, 0, $3)));
			  token_getmad($2,$$,'A');
			}
	|	METHOD indirob listexpr              /* new Class @args */
			{ $$ = convert(OP_ENTERSUB, OPf_STACKED,
				append_elem(OP_LIST,
				    prepend_elem(OP_LIST, $2, $3),
				    newUNOP(OP_METHOD, 0, $1)));
			}
	|	FUNCMETH indirob '(' listexprcom ')' /* method $object (@args) */
			{ $$ = convert(OP_ENTERSUB, OPf_STACKED,
				append_elem(OP_LIST,
				    prepend_elem(OP_LIST, $2, $4),
				    newUNOP(OP_METHOD, 0, $1)));
			  token_getmad($3,$$,'(');
			  token_getmad($5,$$,')');
			}
	|	LSTOP listexpr                       /* print @args */
			{ $$ = convert(($1)->tk_lval.ival, 0, $2);
			  token_getmad($1,$$,'o');
			}
	|	FUNC '(' listexprcom ')'             /* print (@args) */
			{ $$ = convert(($1)->tk_lval.ival, 0, $3);
			  token_getmad($1,$$,'o');
			  token_getmad($2,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	LSTOPSUB startanonsub block          /* map { foo } ... */
			{ SvREFCNT_inc(PL_compcv);
			  $3 = newANONATTRSUB($2, 0, Nullop, $3); }
		    listexpr		%prec LSTOP  /* ... @bar */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				 append_elem(OP_LIST,
				   prepend_elem(OP_LIST, $3, $5), $1));
			}
	;

/* Names of methods. May use $object->$methodname */
method	:	METHOD
	|	scalar
	;

/* Some kind of subscripted expression */
subscripted:    star '{' expr ';' '}'        /* *main::{something} */
                        /* In this and all the hash accessors, ';' is
                         * provided by the tokeniser */
			{ $$ = newBINOP(OP_GELEM, 0, $1, scalar($3));
			    PL_expect = XOPERATOR;
			  token_getmad($2,$$,'{');
			  token_getmad($4,$$,';');
			  token_getmad($5,$$,'}');
			}
	|	scalar '[' expr ']'          /* $array[$element] */
			{ $$ = newBINOP(OP_AELEM, 0, oopsAV($1), scalar($3));
			  token_getmad($2,$$,'[');
			  token_getmad($4,$$,']');
			}
	|	term ARROW '[' expr ']'      /* somearef->[$element] */
			{ $$ = newBINOP(OP_AELEM, 0,
					ref(newAVREF($1),OP_RV2AV),
					scalar($4));
			  token_getmad($2,$$,'a');
			  token_getmad($3,$$,'[');
			  token_getmad($5,$$,']');
			}
	|	subscripted '[' expr ']'    /* $foo->[$bar]->[$baz] */
			{ $$ = newBINOP(OP_AELEM, 0,
					ref(newAVREF($1),OP_RV2AV),
					scalar($3));
			  token_getmad($2,$$,'[');
			  token_getmad($4,$$,']');
			}
	|	scalar '{' expr ';' '}'    /* $foo->{bar();} */
			{ $$ = newBINOP(OP_HELEM, 0, oopsHV($1), jmaybe($3));
			    PL_expect = XOPERATOR;
			  token_getmad($2,$$,'{');
			  token_getmad($4,$$,';');
			  token_getmad($5,$$,'}');
			}
	|	term ARROW '{' expr ';' '}' /* somehref->{bar();} */
			{ $$ = newBINOP(OP_HELEM, 0,
					ref(newHVREF($1),OP_RV2HV),
					jmaybe($4));
			    PL_expect = XOPERATOR;
			  token_getmad($2,$$,'a');
			  token_getmad($3,$$,'{');
			  token_getmad($5,$$,';');
			  token_getmad($6,$$,'}');
			}
	|	subscripted '{' expr ';' '}' /* $foo->[bar]->{baz;} */
			{ $$ = newBINOP(OP_HELEM, 0,
					ref(newHVREF($1),OP_RV2HV),
					jmaybe($3));
			    PL_expect = XOPERATOR;
			  token_getmad($2,$$,'{');
			  token_getmad($4,$$,';');
			  token_getmad($5,$$,'}');
			}
	|	term ARROW '(' ')'          /* $subref->() */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				   newCVREF(0, scalar($1)));
			  token_getmad($2,$$,'a');
			  token_getmad($3,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	term ARROW '(' expr ')'     /* $subref->(@args) */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				   append_elem(OP_LIST, $4,
				       newCVREF(0, scalar($1))));
			  token_getmad($2,$$,'a');
			  token_getmad($3,$$,'(');
			  token_getmad($5,$$,')');
			}

	|	subscripted '(' expr ')'   /* $foo->{bar}->(@args) */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				   append_elem(OP_LIST, $3,
					       newCVREF(0, scalar($1))));
			  token_getmad($2,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	subscripted '(' ')'        /* $foo->{bar}->() */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				   newCVREF(0, scalar($1)));
			  token_getmad($2,$$,'(');
			  token_getmad($3,$$,')');
			}
	|	'(' expr ')' '[' expr ']'            /* list slice */
			{ $$ = newSLICEOP(0, $5, $2);
			  token_getmad($1,$$,'(');
			  token_getmad($3,$$,')');
			  token_getmad($4,$$,'[');
			  token_getmad($6,$$,']');
			}
	|	'(' ')' '[' expr ']'                 /* empty list slice! */
			{ $$ = newSLICEOP(0, $4, Nullop);
			  token_getmad($1,$$,'(');
			  token_getmad($2,$$,')');
			  token_getmad($3,$$,'[');
			  token_getmad($5,$$,']');
			}
    ;

/* Binary operators between terms */
termbinop:	term ASSIGNOP term             /* $x = $y */
			{ $$ = newASSIGNOP(OPf_STACKED, $1, ($2)->tk_lval.ival, $3);
			  token_getmad($2,$$,'o');
			}
	|	term POWOP term                        /* $x ** $y */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term MULOP term                        /* $x * $y, $x x $y */
			{   if (($2)->tk_lval.ival != OP_REPEAT)
				scalar($1);
			    $$ = newBINOP(($2)->tk_lval.ival, 0, $1, scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term ADDOP term                        /* $x + $y */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term SHIFTOP term                      /* $x >> $y, $x << $y */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term RELOP term                        /* $x > $y, etc. */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term EQOP term                         /* $x == $y, $x eq $y */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term BITANDOP term                     /* $x & $y */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term BITOROP term                      /* $x | $y */
			{ $$ = newBINOP(($2)->tk_lval.ival, 0, scalar($1), scalar($3));
			  token_getmad($2,$$,'o');
			}
	|	term DOTDOT term                       /* $x..$y, $x...$y */
			{ UNOP *op;
			  $$ = newRANGE(($2)->tk_lval.ival, scalar($1), scalar($3));
			  op = (UNOP*)$$;
			  op = (UNOP*)op->op_first;	/* get to flop */
			  op = (UNOP*)op->op_first;	/* get to flip */
			  op = (UNOP*)op->op_first;	/* get to range */
			  token_getmad($2,(OP*)op,'o');
			}
	|	term ANDAND term                       /* $x && $y */
			{ $$ = newLOGOP(OP_AND, 0, $1, $3);
			  token_getmad($2,$$,'o');
			}
	|	term OROR term                         /* $x || $y */
			{ $$ = newLOGOP(OP_OR, 0, $1, $3);
			  token_getmad($2,$$,'o');
			}
	|	term DORDOR term                       /* $x // $y */
			{ $$ = newLOGOP(OP_DOR, 0, $1, $3);
			  token_getmad($2,$$,'o');
			}
	|	term MATCHOP term                      /* $x =~ /$y/ */
			{ $$ = bind_match(($2)->tk_lval.ival, $1, $3);
			  if ($$->op_type == OP_NOT)
			      token_getmad($2,((UNOP*)$$)->op_first,'~');
			    else
			      token_getmad($2,$$,'~');
			}
    ;

/* Unary operators and terms */
termunop : '-' term %prec UMINUS                       /* -$x */
			{ $$ = newUNOP(OP_NEGATE, 0, scalar($2));
			  token_getmad($1,$$,'o');
			}
	|	'+' term %prec UMINUS                  /* +$x */
			{ $$ = newUNOP(OP_NULL, 0, $2);
			  token_getmad($1,$$,'+');
			}
	|	'!' term                               /* !$x */
			{ $$ = newUNOP(OP_NOT, 0, scalar($2));
			  token_getmad($1,$$,'o');
			}
	|	'~' term                               /* ~$x */
			{ $$ = newUNOP(OP_COMPLEMENT, 0, scalar($2));
			  token_getmad($1,$$,'o');
			}
	|	term POSTINC                           /* $x++ */
			{ $$ = newUNOP(OP_POSTINC, 0,
					mod(scalar($1), OP_POSTINC));
			  token_getmad($2,$$,'o');
			}
	|	term POSTDEC                           /* $x-- */
			{ $$ = newUNOP(OP_POSTDEC, 0,
					mod(scalar($1), OP_POSTDEC));
			  token_getmad($2,$$,'o');
			}
	|	PREINC term                            /* ++$x */
			{ $$ = newUNOP(OP_PREINC, 0,
					mod(scalar($2), OP_PREINC));
			  token_getmad($1,$$,'o');
			}
	|	PREDEC term                            /* --$x */
			{ $$ = newUNOP(OP_PREDEC, 0,
					mod(scalar($2), OP_PREDEC));
			  token_getmad($1,$$,'o');
			}

    ;

/* Constructors for anonymous data */
anonymous:	'[' expr ']'
			{ $$ = newANONLIST($2);
			  token_getmad($1,$$,'[');
			  token_getmad($3,$$,']');
			}
	|	'[' ']'
			{ $$ = newANONLIST(Nullop);
			  token_getmad($1,$$,'[');
			  token_getmad($2,$$,']');
			}
	|	HASHBRACK expr ';' '}'	%prec '(' /* { foo => "Bar" } */
			{ $$ = newANONHASH($2);
			  token_getmad($1,$$,'{');
			  token_getmad($3,$$,';');
			  token_getmad($4,$$,'}');
			}
	|	HASHBRACK ';' '}'	%prec '(' /* { } (';' by tokener) */
			{ $$ = newANONHASH(Nullop);
			  token_getmad($1,$$,'{');
			  token_getmad($2,$$,';');
			  token_getmad($3,$$,'}');
			}
	|	ANONSUB startanonsub proto subattrlist block	%prec '('
			{ SvREFCNT_inc(PL_compcv);
			  $$ = newANONATTRSUB($2, $3, $4, $5);
			  token_getmad($1,$$,'o');
			  op_getmad($3,$$,'s');
			  op_getmad($4,$$,'a');
			}

    ;

/* Things called with "do" */
termdo	:       DO term	%prec UNIOP                     /* do $filename */
			{ $$ = dofile($2, $1);
			  token_getmad($1,$$,'o');
			}
	|	DO block	%prec '('               /* do { code */
			{ $$ = newUNOP(OP_NULL, OPf_SPECIAL, scope($2));
			  token_getmad($1,$$,'D');
			}
	|	DO WORD '(' ')'                         /* do somesub() */
			{ $$ = newUNOP(OP_ENTERSUB,
			    OPf_SPECIAL|OPf_STACKED,
			    prepend_elem(OP_LIST,
				scalar(newCVREF(
				    (OPpENTERSUB_AMPER<<8),
				    scalar($2)
				)),Nullop)); dep();
			  token_getmad($1,$$,'o');
			  token_getmad($3,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	DO WORD '(' expr ')'                    /* do somesub(@args) */
			{ $$ = newUNOP(OP_ENTERSUB,
			    OPf_SPECIAL|OPf_STACKED,
			    append_elem(OP_LIST,
				$4,
				scalar(newCVREF(
				    (OPpENTERSUB_AMPER<<8),
				    scalar($2)
				)))); dep();
			  token_getmad($1,$$,'o');
			  token_getmad($3,$$,'(');
			  token_getmad($5,$$,')');
			}
	|	DO scalar '(' ')'                      /* do $subref () */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_SPECIAL|OPf_STACKED,
			    prepend_elem(OP_LIST,
				scalar(newCVREF(0,scalar($2))), Nullop)); dep();
			  token_getmad($1,$$,'o');
			  token_getmad($3,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	DO scalar '(' expr ')'                 /* do $subref (@args) */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_SPECIAL|OPf_STACKED,
			    prepend_elem(OP_LIST,
				$4,
				scalar(newCVREF(0,scalar($2))))); dep();
			  token_getmad($1,$$,'o');
			  token_getmad($3,$$,'(');
			  token_getmad($5,$$,')');
			}

        ;

term	:	termbinop
	|	termunop
	|	anonymous
	|	termdo
	|	term '?' term ':' term
			{ $$ = newCONDOP(0, $1, $3, $5);
			  token_getmad($2,$$,'?');
			  token_getmad($4,$$,':');
			}
	|	REFGEN term                          /* \$x, \@y, \%z */
			{ $$ = newUNOP(OP_REFGEN, 0, mod($2,OP_REFGEN));
			  token_getmad($1,$$,'o');
			}
	|	myattrterm	%prec UNIOP
			{ $$ = $1; }
	|	LOCAL term	%prec UNIOP
			{ $$ = localize($2,($1)->tk_lval.ival);
			  token_getmad($1,$$,'d');
			}
	|	'(' expr ')'
			{ $$ = sawparens(newUNOP(OP_NULL,0,$2));
			  token_getmad($1,$$,'(');
			  token_getmad($3,$$,')');
			}
	|	'(' ')'
			{ $$ = sawparens(newNULLLIST());
			  token_getmad($1,$$,'(');
			  token_getmad($2,$$,')');
			}
	|	scalar	%prec '('
			{ $$ = $1; }
	|	star	%prec '('
			{ $$ = $1; }
	|	hsh 	%prec '('
			{ $$ = $1; }
	|	ary 	%prec '('
			{ $$ = $1; }
	|	arylen 	%prec '('                    /* $#x, $#{ something } */
			{ $$ = newUNOP(OP_AV2ARYLEN, 0, ref($1, OP_AV2ARYLEN));}
	|       subscripted
			{ $$ = $1; }
	|	ary '[' expr ']'                     /* array slice */
			{ $$ = prepend_elem(OP_ASLICE,
				newOP(OP_PUSHMARK, 0),
				    newLISTOP(OP_ASLICE, 0,
					list($3),
					ref($1, OP_ASLICE)));
			  token_getmad($2,$$,'[');
			  token_getmad($4,$$,']');
			}
	|	ary '{' expr ';' '}'                 /* @hash{@keys} */
			{ $$ = prepend_elem(OP_HSLICE,
				newOP(OP_PUSHMARK, 0),
				    newLISTOP(OP_HSLICE, 0,
					list($3),
					ref(oopsHV($1), OP_HSLICE)));
			    PL_expect = XOPERATOR;
			  token_getmad($2,$$,'{');
			  token_getmad($4,$$,';');
			  token_getmad($5,$$,'}');
			}
	|	THING	%prec '('
			{ $$ = $1; }
	|	amper                                /* &foo; */
			{ $$ = newUNOP(OP_ENTERSUB, 0, scalar($1)); }
	|	amper '(' ')'                        /* &foo() */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1));
			  token_getmad($2,$$,'(');
			  token_getmad($3,$$,')');
			}
	|	amper '(' expr ')'                   /* &foo(@args) */
			{ OP* op;
			  $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				append_elem(OP_LIST, $3, scalar($1)));
			  op = $$;
			  if (op->op_type == OP_CONST) { /* defeat const fold */
			    op = (OP*)op->op_madprop->mad_val;
			  }
			  token_getmad($2,op,'(');
			  token_getmad($4,op,')');
			}
	|	NOAMP WORD listexpr                  /* foo(@args) */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
			    append_elem(OP_LIST, $3, scalar($2)));
			  token_getmad($1,$$,'o');
			}
	|	LOOPEX  /* loop exiting command (goto, last, dump, etc) */
			{ $$ = newOP(($1)->tk_lval.ival, OPf_SPECIAL);
			    PL_hints |= HINT_BLOCK_SCOPE;
			  token_getmad($1,$$,'o');
			}
	|	LOOPEX term
			{ $$ = newLOOPEX(($1)->tk_lval.ival,$2);
			  token_getmad($1,$$,'o');
			}
	|	NOTOP argexpr                        /* not $foo */
			{ $$ = newUNOP(OP_NOT, 0, scalar($2));
			  token_getmad($1,$$,'o');
			}
	|	UNIOP                                /* Unary op, $_ implied */
			{ $$ = newOP(($1)->tk_lval.ival, 0);
			  token_getmad($1,$$,'o');
			}
	|	UNIOP block                          /* eval { foo }, I *think* */
			{ $$ = newUNOP(($1)->tk_lval.ival, 0, $2);
			  token_getmad($1,$$,'o');
			}
	|	UNIOP term                           /* Unary op */
			{ $$ = newUNOP(($1)->tk_lval.ival, 0, $2);
			  token_getmad($1,$$,'o');
			}
	|	REQUIRE                              /* require, $_ implied *//* FIMXE for MAD needed? */
			{ $$ = newOP(OP_REQUIRE, $1 ? OPf_SPECIAL : 0); }
	|	REQUIRE term                         /* require Foo *//* FIMXE for MAD needed? */
			{ $$ = newUNOP(OP_REQUIRE, $1 ? OPf_SPECIAL : 0, $2); }
	|	UNIOPSUB
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)); }
	|	UNIOPSUB term                        /* Sub treated as unop */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
			    append_elem(OP_LIST, $2, scalar($1))); }
	|	FUNC0                                /* Nullary operator */
			{ $$ = newOP(($1)->tk_lval.ival, 0);
			  token_getmad($1,$$,'o');
			}
	|	FUNC0 '(' ')'
			{ $$ = newOP(($1)->tk_lval.ival, 0);
			  token_getmad($1,$$,'o');
			  token_getmad($2,$$,'(');
			  token_getmad($3,$$,')');
			}
	|	FUNC0SUB                             /* Sub treated as nullop */
			{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED,
				scalar($1)); }
	|	FUNC1 '(' ')'                        /* not () */
			{ $$ = newOP(($1)->tk_lval.ival, OPf_SPECIAL);
			  token_getmad($1,$$,'o');
			  token_getmad($2,$$,'(');
			  token_getmad($3,$$,')');
			}
	|	FUNC1 '(' expr ')'                   /* not($foo) */
			{ $$ = newUNOP(($1)->tk_lval.ival, 0, $3);
			  token_getmad($1,$$,'o');
			  token_getmad($2,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	PMFUNC '(' argexpr ')'		/* m//, s///, tr/// */
			{ $$ = pmruntime($1, $3, 1);
			  token_getmad($2,$$,'(');
			  token_getmad($4,$$,')');
			}
	|	WORD
	|	listop
	;

/* "my" declarations, with optional attributes */
myattrterm:	MY myterm myattrlist
			{ $$ = my_attrs($2,$3);
			  token_getmad($1,$$,'d');
			  append_madprops($3->op_madprop, $$, 'a');
			  $3->op_madprop = 0;
			}
	|	MY myterm
			{ $$ = localize($2,($1)->tk_lval.ival);
			  token_getmad($1,$$,'d');
			}
	;

/* Things that can be "my"'d */
myterm	:	'(' expr ')'
			{ $$ = sawparens($2);
			  token_getmad($1,$$,'(');
			  token_getmad($3,$$,')');
			}
	|	'(' ')'
			{ $$ = sawparens(newNULLLIST());
			  token_getmad($1,$$,'(');
			  token_getmad($2,$$,')');
			}
	|	scalar	%prec '('
			{ $$ = $1; }
	|	hsh 	%prec '('
			{ $$ = $1; }
	|	ary 	%prec '('
			{ $$ = $1; }
	;

/* Basic list expressions */
listexpr:	/* NULL */ %prec PREC_LOW
			{ $$ = Nullop; }
	|	argexpr    %prec PREC_LOW
			{ $$ = $1; }
	;

listexprcom:	/* NULL */
			{ $$ = Nullop; }
	|	expr
			{ $$ = $1; }
	|	expr ','
			{ OP* op = newNULLLIST();
			  token_getmad($2,op,',');
			  $$ = append_elem(OP_LIST, $1, op);
			}
	;

/* A little bit of trickery to make "for my $foo (@bar)" actually be
   lexical */
my_scalar:	scalar
			{ PL_in_my = 0; $$ = my($1); }
	;

amper	:	'&' indirob
			{ $$ = newCVREF(($1)->tk_lval.ival,$2);
			  token_getmad($1,$$,'&');
			}
	;

scalar	:	'$' indirob
			{ $$ = newSVREF($2);
			  token_getmad($1,$$,'$');
			}
	;

ary	:	'@' indirob
			{ $$ = newAVREF($2);
			  token_getmad($1,$$,'@');
			}
	;

hsh	:	'%' indirob
			{ $$ = newHVREF($2);
			  token_getmad($1,$$,'%');
			}
	;

arylen	:	DOLSHARP indirob
			{ $$ = newAVREF($2);
			  token_getmad($1,$$,'l');
			}
	;

star	:	'*' indirob
			{ $$ = newGVREF(0,$2);
			  token_getmad($1,$$,'*');
			}
	;

/* Indirect objects */
indirob	:	WORD
			{ $$ = scalar($1); }
	|	scalar %prec PREC_LOW
			{ $$ = scalar($1); }
	|	block
			{ $$ = scope($1); }

	|	PRIVATEREF
			{ $$ = $1; }
	;
