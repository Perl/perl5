/*
 * Definitions etc. for regexp(3) routines.
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 */

/* $Header: regexp.h,v 3.0 89/10/18 15:22:46 lwall Locked $
 *
 * $Log:	regexp.h,v $
 * Revision 3.0  89/10/18  15:22:46  lwall
 * 3.0 baseline
 * 
 */

#define NSUBEXP  10

typedef struct regexp {
	char *startp[NSUBEXP];
	char *endp[NSUBEXP];
	STR *regstart;		/* Internal use only. */
	char *regstclass;
	STR *regmust;		/* Internal use only. */
	int regback;		/* Can regmust locate first try? */
	char *precomp;		/* pre-compilation regular expression */
	char *subbase;		/* saved string so \digit works forever */
	char reganch;		/* Internal use only. */
	char do_folding;	/* do case-insensitive match? */
	char lastparen;		/* last paren matched */
	char nparens;		/* number of parentheses */
	char program[1];	/* Unwarranted chumminess with compiler. */
} regexp;

regexp *regcomp();
int regexec();
