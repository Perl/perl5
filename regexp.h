/*
 * Definitions etc. for regexp(3) routines.
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 */

/* $Header: regexp.h,v 2.0 88/06/05 00:10:53 root Exp $
 *
 * $Log:	regexp.h,v $
 * Revision 2.0  88/06/05  00:10:53  root
 * Baseline version 2.0.
 * 
 */

#define ALIGN

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

extern regexp *regcomp();
extern int regexec();
extern void regsub();
extern void regerror();
