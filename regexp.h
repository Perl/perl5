/*
 * Definitions etc. for regexp(3) routines.
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 */

/* $Header: regexp.h,v 4.0 91/03/20 01:39:23 lwall Locked $
 *
 * $Log:	regexp.h,v $
 * Revision 4.0  91/03/20  01:39:23  lwall
 * 4.0 baseline.
 * 
 */

typedef struct regexp {
	char **startp;
	char **endp;
	STR *regstart;		/* Internal use only. */
	char *regstclass;
	STR *regmust;		/* Internal use only. */
	int regback;		/* Can regmust locate first try? */
	char *precomp;		/* pre-compilation regular expression */
	char *subbase;		/* saved string so \digit works forever */
	char *subend;		/* end of subbase */
	char reganch;		/* Internal use only. */
	char do_folding;	/* do case-insensitive match? */
	char lastparen;		/* last paren matched */
	char nparens;		/* number of parentheses */
	char program[1];	/* Unwarranted chumminess with compiler. */
} regexp;

regexp *regcomp();
int regexec();
