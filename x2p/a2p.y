%{
/* $Header: a2p.y,v 1.0 87/12/18 13:07:05 root Exp $
 *
 * $Log:	a2p.y,v $
 * Revision 1.0  87/12/18  13:07:05  root
 * Initial revision
 * 
 */

#include "INTERN.h"
#include "a2p.h"

int root;

%}
%token BEGIN END
%token REGEX
%token SEMINEW NEWLINE COMMENT
%token FUN1 GRGR
%token PRINT PRINTF SPRINTF SPLIT
%token IF ELSE WHILE FOR IN
%token EXIT NEXT BREAK CONTINUE

%right ASGNOP
%left OROR
%left ANDAND
%left NOT
%left NUMBER VAR SUBSTR INDEX
%left GETLINE
%nonassoc RELOP MATCHOP
%left OR
%left STRING
%left '+' '-'
%left '*' '/' '%'
%right UMINUS
%left INCR DECR
%left FIELD VFIELD

%%

program	: junk begin hunks end
		{ root = oper4(OPROG,$1,$2,$3,$4); }
	;

begin	: BEGIN '{' states '}' junk
		{ $$ = oper2(OJUNK,$3,$5); in_begin = FALSE; }
	| /* NULL */
		{ $$ = Nullop; }
	;

end	: END '{' states '}'
		{ $$ = $3; }
	| end NEWLINE
		{ $$ = $1; }
	| /* NULL */
		{ $$ = Nullop; }
	;

hunks	: hunks hunk junk
		{ $$ = oper3(OHUNKS,$1,$2,$3); }
	| /* NULL */
		{ $$ = Nullop; }
	;

hunk	: patpat
		{ $$ = oper1(OHUNK,$1); need_entire = TRUE; }
	| patpat '{' states '}'
		{ $$ = oper2(OHUNK,$1,$3); }
	| '{' states '}'
		{ $$ = oper2(OHUNK,Nullop,$2); }
	;

patpat	: pat
		{ $$ = oper1(OPAT,$1); }
	| pat ',' pat
		{ $$ = oper2(ORANGE,$1,$3); }
	;

pat	: REGEX
		{ $$ = oper1(OREGEX,$1); }
	| match
	| rel
	| compound_pat
	;

compound_pat
	: '(' compound_pat ')'
		{ $$ = oper1(OPPAREN,$2); }
	| pat ANDAND pat
		{ $$ = oper2(OPANDAND,$1,$3); }
	| pat OROR pat
		{ $$ = oper2(OPOROR,$1,$3); }
	| NOT pat
		{ $$ = oper1(OPNOT,$2); }
	;

cond	: expr
	| match
	| rel
	| compound_cond
	;

compound_cond
	: '(' compound_cond ')'
		{ $$ = oper1(OCPAREN,$2); }
	| cond ANDAND cond
		{ $$ = oper2(OCANDAND,$1,$3); }
	| cond OROR cond
		{ $$ = oper2(OCOROR,$1,$3); }
	| NOT cond
		{ $$ = oper1(OCNOT,$2); }
	;

rel	: expr RELOP expr
		{ $$ = oper3(ORELOP,$2,$1,$3); }
	| '(' rel ')'
		{ $$ = oper1(ORPAREN,$2); }
	;

match	: expr MATCHOP REGEX
		{ $$ = oper3(OMATCHOP,$2,$1,$3); }
	| '(' match ')'
		{ $$ = oper1(OMPAREN,$2); }
	;

expr	: term
		{ $$ = $1; }
	| expr term
		{ $$ = oper2(OCONCAT,$1,$2); }
	| variable ASGNOP expr
		{ $$ = oper3(OASSIGN,$2,$1,$3);
			if ((ops[$1].ival & 255) == OFLD)
			    lval_field = TRUE;
			if ((ops[$1].ival & 255) == OVFLD)
			    lval_field = TRUE;
		}
	;

term	: variable
		{ $$ = $1; }
	| term '+' term
		{ $$ = oper2(OADD,$1,$3); }
	| term '-' term
		{ $$ = oper2(OSUB,$1,$3); }
	| term '*' term
		{ $$ = oper2(OMULT,$1,$3); }
	| term '/' term
		{ $$ = oper2(ODIV,$1,$3); }
	| term '%' term
		{ $$ = oper2(OMOD,$1,$3); }
	| variable INCR
		{ $$ = oper1(OPOSTINCR,$1); }
	| variable DECR
		{ $$ = oper1(OPOSTDECR,$1); }
	| INCR variable
		{ $$ = oper1(OPREINCR,$2); }
	| DECR variable
		{ $$ = oper1(OPREDECR,$2); }
	| '-' term %prec UMINUS
		{ $$ = oper1(OUMINUS,$2); }
	| '+' term %prec UMINUS
		{ $$ = oper1(OUPLUS,$2); }
	| '(' expr ')'
		{ $$ = oper1(OPAREN,$2); }
	| GETLINE
		{ $$ = oper0(OGETLINE); }
	| FUN1
		{ $$ = oper0($1); need_entire = do_chop = TRUE; }
	| FUN1 '(' ')'
		{ $$ = oper1($1,Nullop); need_entire = do_chop = TRUE; }
	| FUN1 '(' expr ')'
		{ $$ = oper1($1,$3); }
	| SPRINTF print_list
		{ $$ = oper1(OSPRINTF,$2); }
	| SUBSTR '(' expr ',' expr ',' expr ')'
		{ $$ = oper3(OSUBSTR,$3,$5,$7); }
	| SUBSTR '(' expr ',' expr ')'
		{ $$ = oper2(OSUBSTR,$3,$5); }
	| SPLIT '(' expr ',' VAR ',' expr ')'
		{ $$ = oper3(OSPLIT,$3,numary($5),$7); }
	| SPLIT '(' expr ',' VAR ')'
		{ $$ = oper2(OSPLIT,$3,numary($5)); }
	| INDEX '(' expr ',' expr ')'
		{ $$ = oper2(OINDEX,$3,$5); }
	;

variable: NUMBER
		{ $$ = oper1(ONUM,$1); }
	| STRING
		{ $$ = oper1(OSTR,$1); }
	| VAR
		{ $$ = oper1(OVAR,$1); }
	| VAR '[' expr ']'
		{ $$ = oper2(OVAR,$1,$3); }
	| FIELD
		{ $$ = oper1(OFLD,$1); }
	| VFIELD term
		{ $$ = oper1(OVFLD,$2); }
	;

maybe	: NEWLINE
		{ $$ = oper0(ONEWLINE); }
	| /* NULL */
		{ $$ = Nullop; }
	| COMMENT
		{ $$ = oper1(OCOMMENT,$1); }
	;

print_list
	: expr
	| clist
	| /* NULL */
		{ $$ = Nullop; }
	;

clist	: expr ',' expr
		{ $$ = oper2(OCOMMA,$1,$3); }
	| clist ',' expr
		{ $$ = oper2(OCOMMA,$1,$3); }
	| '(' clist ')'		/* these parens are invisible */
		{ $$ = $2; }
	;

junk	: junk hunksep
		{ $$ = oper2(OJUNK,$1,$2); }
	| /* NULL */
		{ $$ = Nullop; }
	;

hunksep : ';'
		{ $$ = oper0(OSEMICOLON); }
	| SEMINEW
		{ $$ = oper0(OSEMICOLON); }
	| NEWLINE
		{ $$ = oper0(ONEWLINE); }
	| COMMENT
		{ $$ = oper1(OCOMMENT,$1); }
	;

separator
	: ';'
		{ $$ = oper0(OSEMICOLON); }
	| SEMINEW
		{ $$ = oper0(OSNEWLINE); }
	| NEWLINE
		{ $$ = oper0(OSNEWLINE); }
	| COMMENT
		{ $$ = oper1(OSCOMMENT,$1); }
	;

states	: states statement
		{ $$ = oper2(OSTATES,$1,$2); }
	| /* NULL */
		{ $$ = Nullop; }
	;

statement
	: simple separator
		{ $$ = oper2(OSTATE,$1,$2); }
	| compound
	;

simple
	: expr
	| PRINT print_list redir expr
		{ $$ = oper3(OPRINT,$2,$3,$4);
		    do_opens = TRUE;
		    saw_ORS = saw_OFS = TRUE;
		    if (!$2) need_entire = TRUE;
		    if (ops[$4].ival != OSTR + (1<<8)) do_fancy_opens = TRUE; }
	| PRINT print_list
		{ $$ = oper1(OPRINT,$2);
		    if (!$2) need_entire = TRUE;
		    saw_ORS = saw_OFS = TRUE;
		}
	| PRINTF print_list redir expr
		{ $$ = oper3(OPRINTF,$2,$3,$4);
		    do_opens = TRUE;
		    if (!$2) need_entire = TRUE;
		    if (ops[$4].ival != OSTR + (1<<8)) do_fancy_opens = TRUE; }
	| PRINTF print_list
		{ $$ = oper1(OPRINTF,$2);
		    if (!$2) need_entire = TRUE;
		}
	| BREAK
		{ $$ = oper0(OBREAK); }
	| NEXT
		{ $$ = oper0(ONEXT); }
	| EXIT
		{ $$ = oper0(OEXIT); }
	| EXIT expr
		{ $$ = oper1(OEXIT,$2); }
	| CONTINUE
		{ $$ = oper0(OCONTINUE); }
	| /* NULL */
		{ $$ = Nullop; }
	;

redir	: RELOP
		{ $$ = oper1(OREDIR,string(">",1)); }
	| GRGR
		{ $$ = oper1(OREDIR,string(">>",2)); }
	| '|'
		{ $$ = oper1(OREDIR,string("|",1)); }
	;

compound
	: IF '(' cond ')' maybe statement
		{ $$ = oper2(OIF,$3,bl($6,$5)); }
	| IF '(' cond ')' maybe statement ELSE maybe statement
		{ $$ = oper3(OIF,$3,bl($6,$5),bl($9,$8)); }
	| WHILE '(' cond ')' maybe statement
		{ $$ = oper2(OWHILE,$3,bl($6,$5)); }
	| FOR '(' simple ';' cond ';' simple ')' maybe statement
		{ $$ = oper4(OFOR,$3,$5,$7,bl($10,$9)); }
	| FOR '(' simple ';'  ';' simple ')' maybe statement
		{ $$ = oper4(OFOR,$3,string("",0),$6,bl($9,$8)); }
	| FOR '(' VAR IN VAR ')' maybe statement
		{ $$ = oper3(OFORIN,$3,$5,bl($8,$7)); }
	| '{' states '}'
		{ $$ = oper1(OBLOCK,$2); }
	;

%%
#include "a2py.c"
