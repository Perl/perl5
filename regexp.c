/* NOTE: this is derived from Henry Spencer's regexp code, and should not
 * confused with the original package (see point 3 below).  Thanks, Henry!
 */

/* Additional note: this code is very heavily munged from Henry's version
 * in places.  In some spots I've traded clarity for efficiency, so don't
 * blame Henry for some of the lack of readability.
 */

/* $Header: regexp.c,v 2.0 88/06/05 00:10:45 root Exp $
 *
 * $Log:	regexp.c,v $
 * Revision 2.0  88/06/05  00:10:45  root
 * Baseline version 2.0.
 * 
 */

/*
 * regcomp and regexec -- regsub and regerror are not used in perl
 *
 *	Copyright (c) 1986 by University of Toronto.
 *	Written by Henry Spencer.  Not derived from licensed software.
 *
 *	Permission is granted to anyone to use this software for any
 *	purpose on any computer system, and to redistribute it freely,
 *	subject to the following restrictions:
 *
 *	1. The author is not responsible for the consequences of use of
 *		this software, no matter how awful, even if they arise
 *		from defects in it.
 *
 *	2. The origin of this software must not be misrepresented, either
 *		by explicit claim or by omission.
 *
 *	3. Altered versions must be plainly marked as such, and must not
 *		be misrepresented as being the original software.
 *
 * Beware that some of this code is subtly aware of the way operator
 * precedence is structured in regular expressions.  Serious changes in
 * regular-expression syntax might require a total rethink.
 */
#include "EXTERN.h"
#include "perl.h"

/*
 * The "internal use only" fields in regexp.h are present to pass info from
 * compile to execute that permits the execute phase to run lots faster on
 * simple cases.  They are:
 *
 * regstart	str that must begin a match; Nullch if none obvious
 * reganch	is the match anchored (at beginning-of-line only)?
 * regmust	string (pointer into program) that match must include, or NULL
 *  [regmust changed to STR* for bminstr()--law]
 * regmlen	length of regmust string
 *  [regmlen not used currently]
 *
 * Regstart and reganch permit very fast decisions on suitable starting points
 * for a match, cutting down the work a lot.  Regmust permits fast rejection
 * of lines that cannot possibly match.  The regmust tests are costly enough
 * that regcomp() supplies a regmust only if the r.e. contains something
 * potentially expensive (at present, the only such thing detected is * or +
 * at the start of the r.e., which can involve a lot of backup).  Regmlen is
 * supplied because the test in regexec() needs it and regcomp() is computing
 * it anyway.
 * [regmust is now supplied always.  The tests that use regmust have a
 * heuristic that disables the test if it usually matches.]
 *
 * [In fact, we now use regmust in many cases to locate where the search
 * starts in the string, so if regback is >= 0, the regmust search is never
 * wasted effort.  The regback variable says how many characters back from
 * where regmust matched is the earliest possible start of the match.
 * For instance, /[a-z].foo/ has a regmust of 'foo' and a regback of 2.]
 */

/*
 * Structure for regexp "program".  This is essentially a linear encoding
 * of a nondeterministic finite-state machine (aka syntax charts or
 * "railroad normal form" in parsing technology).  Each node is an opcode
 * plus a "next" pointer, possibly plus an operand.  "Next" pointers of
 * all nodes except BRANCH implement concatenation; a "next" pointer with
 * a BRANCH on both ends of it is connecting two alternatives.  (Here we
 * have one of the subtle syntax dependencies:  an individual BRANCH (as
 * opposed to a collection of them) is never concatenated with anything
 * because of operator precedence.)  The operand of some types of node is
 * a literal string; for others, it is a node leading into a sub-FSM.  In
 * particular, the operand of a BRANCH node is the first node of the branch.
 * (NB this is *not* a tree structure:  the tail of the branch connects
 * to the thing following the set of BRANCHes.)  The opcodes are:
 */

/* definition	number	opnd?	meaning */
#define	END	0	/* no	End of program. */
#define	BOL	1	/* no	Match "" at beginning of line. */
#define	EOL	2	/* no	Match "" at end of line. */
#define	ANY	3	/* no	Match any one character. */
#define	ANYOF	4	/* str	Match any character in this string. */
#define	ANYBUT	5	/* str	Match any character not in this string. */
#define	BRANCH	6	/* node	Match this alternative, or the next... */
#define	BACK	7	/* no	Match "", "next" ptr points backward. */
#define	EXACTLY	8	/* str	Match this string (preceded by length). */
#define	NOTHING	9	/* no	Match empty string. */
#define	STAR	10	/* node	Match this (simple) thing 0 or more times. */
#define	PLUS	11	/* node	Match this (simple) thing 1 or more times. */
#define ALNUM	12	/* no	Match any alphanumeric character */
#define NALNUM	13	/* no	Match any non-alphanumeric character */
#define BOUND	14	/* no	Match "" at any word boundary */
#define NBOUND	15	/* no	Match "" at any word non-boundary */
#define SPACE	16	/* no	Match any whitespace character */
#define NSPACE	17	/* no	Match any non-whitespace character */
#define DIGIT	18	/* no	Match any numeric character */
#define NDIGIT	19	/* no	Match any non-numeric character */
#define REF	20	/* no	Match some already matched string */
#define	OPEN	30	/* no	Mark this point in input as start of #n. */
			/*	OPEN+1 is number 1, etc. */
#define	CLOSE	40	/* no	Analogous to OPEN. */

/*
 * Opcode notes:
 *
 * BRANCH	The set of branches constituting a single choice are hooked
 *		together with their "next" pointers, since precedence prevents
 *		anything being concatenated to any individual branch.  The
 *		"next" pointer of the last BRANCH in a choice points to the
 *		thing following the whole choice.  This is also where the
 *		final "next" pointer of each individual branch points; each
 *		branch starts with the operand node of a BRANCH node.
 *
 * BACK		Normal "next" pointers all implicitly point forward; BACK
 *		exists to make loop structures possible.
 *
 * STAR,PLUS	'?', and complex '*' and '+', are implemented as circular
 *		BRANCH structures using BACK.  Simple cases (one character
 *		per match) are implemented with STAR and PLUS for speed
 *		and to minimize recursive plunges.
 *
 * OPEN,CLOSE	...are numbered at compile time.
 */

/* The following have no fixed length. */
char varies[] = {BRANCH,BACK,STAR,PLUS,REF,0};

/* The following always have a length of 1. */
char simple[] = {ANY,ANYOF,ANYBUT,ALNUM,NALNUM,SPACE,NSPACE,DIGIT,NDIGIT,0};

/*
 * A node is one char of opcode followed by two chars of "next" pointer.
 * "Next" pointers are stored as two 8-bit pieces, high order first.  The
 * value is a positive offset from the opcode of the node containing it.
 * An operand, if any, simply follows the node.  (Note that much of the
 * code generation knows about this implicit relationship.)
 *
 * Using two bytes for the "next" pointer is vast overkill for most things,
 * but allows patterns to get big without disasters.
 *
 * [If ALIGN is defined, the "next" pointer is always aligned on an even
 * boundary, and reads the offset directly as a short.  Also, there is no
 * special test to reverse the sign of BACK pointers since the offset is
 * stored negative.]
 */

#ifndef STATIC
#define	STATIC	static
#endif

#define ALIGN
#define FASTANY
#ifdef DEBUG
#undef DEBUG
#endif
#ifdef DEBUGGING
#define DEBUG
#endif

#ifdef DEBUG
int regnarrate = 0;
void regdump();
STATIC char *regprop();
#endif


#define	OP(p)	(*(p))

#ifdef ALIGN
#define NEXT(p) (*(short*)(p+1))
#else
#define	NEXT(p)	(((*((p)+1)&0377)<<8) + (*((p)+2)&0377))
#endif

#define	OPERAND(p)	((p) + 3)

#ifdef ALIGN
#define	NEXTOPER(p)	((p) + 4)
#else
#define	NEXTOPER(p)	((p) + 3)
#endif

#define MAGIC 0234

/*
 * Utility definitions.
 */
#ifndef CHARBITS
#define	UCHARAT(p)	((int)*(unsigned char *)(p))
#else
#define	UCHARAT(p)	((int)*(p)&CHARBITS)
#endif

#define	FAIL(m)	fatal("/%s/: %s",regprecomp,m)
#define	ISMULT(c)	((c) == '*' || (c) == '+' || (c) == '?')
#define	META	"^$.[()|?+*\\"

/*
 * Flags to be passed up and down.
 */
#define	HASWIDTH	01	/* Known never to match null string. */
#define	SIMPLE		02	/* Simple enough to be STAR/PLUS operand. */
#define	SPSTART		04	/* Starts with * or +. */
#define	WORST		0	/* Worst case. */

/*
 * Global work variables for regcomp().
 */
static char *regprecomp;		/* uncompiled string. */
static char *regparse;		/* Input-scan pointer. */
static int regnpar;		/* () count. */
static char regdummy;
static char *regcode;		/* Code-emit pointer; &regdummy = don't. */
static long regsize;		/* Code size. */
static int regfold;

/*
 * Forward declarations for regcomp()'s friends.
 */
STATIC char *reg();
STATIC char *regbranch();
STATIC char *regpiece();
STATIC char *regatom();
STATIC char *regclass();
STATIC char *regchar();
STATIC char *regnode();
STATIC char *regnext();
STATIC void regc();
STATIC void reginsert();
STATIC void regtail();
STATIC void regoptail();
#ifndef STRCSPN
STATIC int strcspn();
#endif

/*
 - regcomp - compile a regular expression into internal code
 *
 * We can't allocate space until we know how big the compiled form will be,
 * but we can't compile it (and thus know how big it is) until we've got a
 * place to put the code.  So we cheat:  we compile it twice, once with code
 * generation turned off and size counting turned on, and once "for real".
 * This also means that we don't allocate space until we are sure that the
 * thing really will compile successfully, and we never have to move the
 * code and thus invalidate pointers into it.  (Note that it has to be in
 * one piece because free() must be able to free it all.) [NB: not true in perl]
 *
 * Beware that the optimization-preparation code in here knows about some
 * of the structure of the compiled regexp.  [I'll say.]
 */
regexp *
regcomp(exp,fold,rare)
char *exp;
int fold;
int rare;
{
	register regexp *r;
	register char *scan;
	register STR *longest;
	register int len;
	register char *first;
	int flags;
	int back;
	int curback;
	extern char *safemalloc();
	extern char *savestr();

	if (exp == NULL)
		fatal("NULL regexp argument");

	/* First pass: determine size, legality. */
	regfold = fold;
	regparse = exp;
	regprecomp = savestr(exp);
	regnpar = 1;
	regsize = 0L;
	regcode = &regdummy;
	regc(MAGIC);
	if (reg(0, &flags) == NULL) {
		safefree(regprecomp);
		return(NULL);
	}

	/* Small enough for pointer-storage convention? */
	if (regsize >= 32767L)		/* Probably could be 65535L. */
		FAIL("regexp too big");

	/* Allocate space. */
	r = (regexp *)safemalloc(sizeof(regexp) + (unsigned)regsize);
	if (r == NULL)
		FAIL("regexp out of space");

	/* Second pass: emit code. */
	r->precomp = regprecomp;
	r->subbase = NULL;
	regparse = exp;
	regnpar = 1;
	regcode = r->program;
	regc(MAGIC);
	if (reg(0, &flags) == NULL)
		return(NULL);

	/* Dig out information for optimizations. */
	r->regstart = Nullstr;	/* Worst-case defaults. */
	r->reganch = 0;
	r->regmust = Nullstr;
	r->regback = -1;
	r->regstclass = Nullch;
	scan = r->program+1;			/* First BRANCH. */
	if (!fold && OP(regnext(scan)) == END) {/* Only one top-level choice. */
		scan = NEXTOPER(scan);

		first = scan;
		while ((OP(first) > OPEN && OP(first) < CLOSE) ||
		    (OP(first) == BRANCH && OP(regnext(first)) != BRANCH) ||
		    (OP(first) == PLUS) )
			first = NEXTOPER(first);

		/* Starting-point info. */
		if (OP(first) == EXACTLY)
			r->regstart = str_make(OPERAND(first)+1);
		else if ((exp = index(simple,OP(first))) && exp > simple)
			r->regstclass = first;
		else if (OP(first) == BOUND || OP(first) == NBOUND)
			r->regstclass = first;
		else if (OP(first) == BOL)
			r->reganch++;

#ifdef DEBUGGING
		if (debug & 512)
		    fprintf(stderr,"first %d next %d offset %d\n",
		      OP(first), OP(NEXTOPER(first)), first - scan);
#endif
		/*
		 * If there's something expensive in the r.e., find the
		 * longest literal string that must appear and make it the
		 * regmust.  Resolve ties in favor of later strings, since
		 * the regstart check works with the beginning of the r.e.
		 * and avoiding duplication strengthens checking.  Not a
		 * strong reason, but sufficient in the absence of others.
		 * [Now we resolve ties in favor of the earlier string if
		 * it happens that curback has been invalidated, since the
		 * earlier string may buy us something the later one won't.]
		 */
		longest = str_new(10);
		len = 0;
		curback = 0;
		while (scan != NULL) {
			if (OP(scan) == BRANCH) {
			    if (OP(regnext(scan)) == BRANCH) {
				curback = -30000;
				while (OP(scan) == BRANCH)
				    scan = regnext(scan);
			    }
			    else	/* single branch is ok */
				scan = NEXTOPER(scan);
			}
			if (OP(scan) == EXACTLY) {
			    if (curback - back == len) {
				str_cat(longest, OPERAND(scan)+1);
				len += *OPERAND(scan);
				curback += *OPERAND(scan);
			    }
			    else if (*OPERAND(scan) >= len + (curback >= 0)) {
				str_set(longest, OPERAND(scan)+1);
				len = *OPERAND(scan);
				back = curback;
				curback += len;
			    }
			    else
				curback += *OPERAND(scan);
			}
			else if (index(varies,OP(scan)))
				curback = -30000;
			else if (index(simple,OP(scan)))
				curback++;
			scan = regnext(scan);
		}
		if (len) {
			r->regmust = longest;
			if (back < 0)
				back = -1;
			r->regback = back;
			if (len > !(sawstudy))
				fbmcompile(r->regmust);
			*(long*)&r->regmust->str_nval = 100;
#ifdef DEBUGGING
			if (debug & 512)
			    fprintf(stderr,"must = '%s' back=%d\n",
				longest,back);
#endif
		}
		else
			str_free(longest);
	}

	r->do_folding = fold;
	r->nparens = regnpar - 1;
#ifdef DEBUG
	if (debug & 512)
		regdump(r);
#endif
	return(r);
}

/*
 - reg - regular expression, i.e. main body or parenthesized thing
 *
 * Caller must absorb opening parenthesis.
 *
 * Combining parenthesis handling with the base level of regular expression
 * is a trifle forced, but the need to tie the tails of the branches to what
 * follows makes it hard to avoid.
 */
static char *
reg(paren, flagp)
int paren;			/* Parenthesized? */
int *flagp;
{
	register char *ret;
	register char *br;
	register char *ender;
	register int parno;
	int flags;

	*flagp = HASWIDTH;	/* Tentatively. */

	/* Make an OPEN node, if parenthesized. */
	if (paren) {
		if (regnpar >= NSUBEXP)
			FAIL("too many () in regexp");
		parno = regnpar;
		regnpar++;
		ret = regnode(OPEN+parno);
	} else
		ret = NULL;

	/* Pick up the branches, linking them together. */
	br = regbranch(&flags);
	if (br == NULL)
		return(NULL);
	if (ret != NULL)
		regtail(ret, br);	/* OPEN -> first. */
	else
		ret = br;
	if (!(flags&HASWIDTH))
		*flagp &= ~HASWIDTH;
	*flagp |= flags&SPSTART;
	while (*regparse == '|') {
		regparse++;
		br = regbranch(&flags);
		if (br == NULL)
			return(NULL);
		regtail(ret, br);	/* BRANCH -> BRANCH. */
		if (!(flags&HASWIDTH))
			*flagp &= ~HASWIDTH;
		*flagp |= flags&SPSTART;
	}

	/* Make a closing node, and hook it on the end. */
	ender = regnode((paren) ? CLOSE+parno : END);	
	regtail(ret, ender);

	/* Hook the tails of the branches to the closing node. */
	for (br = ret; br != NULL; br = regnext(br))
		regoptail(br, ender);

	/* Check for proper termination. */
	if (paren && *regparse++ != ')') {
		FAIL("unmatched () in regexp");
	} else if (!paren && *regparse != '\0') {
		if (*regparse == ')') {
			FAIL("unmatched () in regexp");
		} else
			FAIL("junk on end of regexp");	/* "Can't happen". */
		/* NOTREACHED */
	}

	return(ret);
}

/*
 - regbranch - one alternative of an | operator
 *
 * Implements the concatenation operator.
 */
static char *
regbranch(flagp)
int *flagp;
{
	register char *ret;
	register char *chain;
	register char *latest;
	int flags;

	*flagp = WORST;		/* Tentatively. */

	ret = regnode(BRANCH);
	chain = NULL;
	while (*regparse != '\0' && *regparse != '|' && *regparse != ')') {
		latest = regpiece(&flags);
		if (latest == NULL)
			return(NULL);
		*flagp |= flags&HASWIDTH;
		if (chain == NULL)	/* First piece. */
			*flagp |= flags&SPSTART;
		else
			regtail(chain, latest);
		chain = latest;
	}
	if (chain == NULL)	/* Loop ran zero times. */
		(void) regnode(NOTHING);

	return(ret);
}

/*
 - regpiece - something followed by possible [*+?]
 *
 * Note that the branching code sequences used for ? and the general cases
 * of * and + are somewhat optimized:  they use the same NOTHING node as
 * both the endmarker for their branch list and the body of the last branch.
 * It might seem that this node could be dispensed with entirely, but the
 * endmarker role is not redundant.
 */
static char *
regpiece(flagp)
int *flagp;
{
	register char *ret;
	register char op;
	register char *next;
	int flags;

	ret = regatom(&flags);
	if (ret == NULL)
		return(NULL);

	op = *regparse;
	if (!ISMULT(op)) {
		*flagp = flags;
		return(ret);
	}

	if (!(flags&HASWIDTH) && op != '?')
		FAIL("regexp *+ operand could be empty");
	*flagp = (op != '+') ? (WORST|SPSTART) : (WORST|HASWIDTH);

	if (op == '*' && (flags&SIMPLE))
		reginsert(STAR, ret);
	else if (op == '*') {
		/* Emit x* as (x&|), where & means "self". */
		reginsert(BRANCH, ret);			/* Either x */
		regoptail(ret, regnode(BACK));		/* and loop */
		regoptail(ret, ret);			/* back */
		regtail(ret, regnode(BRANCH));		/* or */
		regtail(ret, regnode(NOTHING));		/* null. */
	} else if (op == '+' && (flags&SIMPLE))
		reginsert(PLUS, ret);
	else if (op == '+') {
		/* Emit x+ as x(&|), where & means "self". */
		next = regnode(BRANCH);			/* Either */
		regtail(ret, next);
		regtail(regnode(BACK), ret);		/* loop back */
		regtail(next, regnode(BRANCH));		/* or */
		regtail(ret, regnode(NOTHING));		/* null. */
	} else if (op == '?') {
		/* Emit x? as (x|) */
		reginsert(BRANCH, ret);			/* Either x */
		regtail(ret, regnode(BRANCH));		/* or */
		next = regnode(NOTHING);		/* null. */
		regtail(ret, next);
		regoptail(ret, next);
	}
	regparse++;
	if (ISMULT(*regparse))
		FAIL("nested *?+ in regexp");

	return(ret);
}

static int foo;

/*
 - regatom - the lowest level
 *
 * Optimization:  gobbles an entire sequence of ordinary characters so that
 * it can turn them into a single node, which is smaller to store and
 * faster to run.  Backslashed characters are exceptions, each becoming a
 * separate node; the code is simpler that way and it's not worth fixing.
 *
 * [Yes, it is worth fixing, some scripts can run twice the speed.]
 */
static char *
regatom(flagp)
int *flagp;
{
	register char *ret;
	int flags;

	*flagp = WORST;		/* Tentatively. */

	switch (*regparse++) {
	case '^':
		ret = regnode(BOL);
		break;
	case '$':
		ret = regnode(EOL);
		break;
	case '.':
		ret = regnode(ANY);
		*flagp |= HASWIDTH|SIMPLE;
		break;
	case '[':
		ret = regclass();
		*flagp |= HASWIDTH|SIMPLE;
		break;
	case '(':
		ret = reg(1, &flags);
		if (ret == NULL)
			return(NULL);
		*flagp |= flags&(HASWIDTH|SPSTART);
		break;
	case '\0':
	case '|':
	case ')':
		FAIL("internal urp in regexp");	/* Supposed to be caught earlier. */
		break;
	case '?':
	case '+':
	case '*':
		FAIL("?+* follows nothing in regexp");
		break;
	case '\\':
		switch (*regparse) {
		case '\0':
			FAIL("trailing \\ in regexp");
		case 'w':
			ret = regnode(ALNUM);
			*flagp |= HASWIDTH|SIMPLE;
			regparse++;
			break;
		case 'W':
			ret = regnode(NALNUM);
			*flagp |= HASWIDTH|SIMPLE;
			regparse++;
			break;
		case 'b':
			ret = regnode(BOUND);
			*flagp |= SIMPLE;
			regparse++;
			break;
		case 'B':
			ret = regnode(NBOUND);
			*flagp |= SIMPLE;
			regparse++;
			break;
		case 's':
			ret = regnode(SPACE);
			*flagp |= HASWIDTH|SIMPLE;
			regparse++;
			break;
		case 'S':
			ret = regnode(NSPACE);
			*flagp |= HASWIDTH|SIMPLE;
			regparse++;
			break;
		case 'd':
			ret = regnode(DIGIT);
			*flagp |= HASWIDTH|SIMPLE;
			regparse++;
			break;
		case 'D':
			ret = regnode(NDIGIT);
			*flagp |= HASWIDTH|SIMPLE;
			regparse++;
			break;
		case 'n':
		case 'r':
		case 't':
		case 'f':
			goto defchar;
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			if (isdigit(regparse[1]))
				goto defchar;
			else {
				ret = regnode(REF + *regparse++ - '0');
				*flagp |= SIMPLE;
			}
			break;
		default:
			goto defchar;
		}
		break;
	default: {
			register int len;
			register char ender;
			register char *p;
			char *oldp;
			int foo;

		    defchar:
			ret = regnode(EXACTLY);
			regc(0);		/* save spot for len */
			for (len=0, p=regparse-1; len < 127 && *p; len++) {
			    oldp = p;
			    switch (*p) {
			    case '^':
			    case '$':
			    case '.':
			    case '[':
			    case '(':
			    case ')':
			    case '|':
				goto loopdone;
			    case '\\':
				switch (*++p) {
				case '\0':
					FAIL("trailing \\ in regexp");
				case 'w':
				case 'W':
				case 'b':
				case 'B':
				case 's':
				case 'S':
				case 'd':
				case 'D':
				    --p;
				    goto loopdone;
				case 'n':
					ender = '\n';
					p++;
					break;
				case 'r':
					ender = '\r';
					p++;
					break;
				case 't':
					ender = '\t';
					p++;
					break;
				case 'f':
					ender = '\f';
					p++;
					break;
				case '0': case '1': case '2': case '3':case '4':
				case '5': case '6': case '7': case '8':case '9':
				    if (isdigit(p[1])) {
					foo = *p++ - '0';
					foo <<= 3;
					foo += *p - '0';
					if (isdigit(p[1]))
					    foo = (foo<<3) + *++p - '0';
					ender = foo;
					p++;
				    }
				    else {
					--p;
					goto loopdone;
				    }
				    break;
				default:
				    ender = *p++;
				    break;
				}
				break;
			    default:
				ender = *p++;
				break;
			    }
			    if (regfold && isupper(ender))
				    ender = tolower(ender);
			    if (ISMULT(*p)) { /* Back off on ?+*. */
				if (len)
				    p = oldp;
				else {
				    len++;
				    regc(ender);
				}
				break;
			    }
			    regc(ender);
			}
		    loopdone:
			regparse = p;
			if (len <= 0)
				FAIL("internal disaster in regexp");
			*flagp |= HASWIDTH;
			if (len == 1)
				*flagp |= SIMPLE;
			*OPERAND(ret) = len;
			regc('\0');
		}
		break;
	}

	return(ret);
}

#ifdef FASTANY
static void
regset(bits,def,c)
char *bits;
int def;
register int c;
{
	if (regcode == &regdummy)
	    return;
	if (def)
		bits[c >> 3] &= ~(1 << (c & 7));
	else
		bits[c >> 3] |=  (1 << (c & 7));
}

static char *
regclass()
{
	register char *bits;
	register int class;
	register int lastclass;
	register int range = 0;
	register char *ret;
	register int def;

	if (*regparse == '^') {	/* Complement of range. */
		ret = regnode(ANYBUT);
		regparse++;
		def = 0;
	} else {
		ret = regnode(ANYOF);
		def = 255;
	}
	bits = regcode;
	for (class = 0; class < 32; class++)
	    regc(def);
	if (*regparse == ']' || *regparse == '-')
		regset(bits,def,lastclass = *regparse++);
	while (*regparse != '\0' && *regparse != ']') {
		class = UCHARAT(regparse++);
		if (class == '\\') {
			class = UCHARAT(regparse++);
			switch (class) {
			case 'w':
				for (class = 'a'; class <= 'z'; class++)
					regset(bits,def,class);
				for (class = 'A'; class <= 'Z'; class++)
					regset(bits,def,class);
				for (class = '0'; class <= '9'; class++)
					regset(bits,def,class);
				regset(bits,def,'_');
				lastclass = 1234;
				continue;
			case 's':
				regset(bits,def,' ');
				regset(bits,def,'\t');
				regset(bits,def,'\r');
				regset(bits,def,'\f');
				regset(bits,def,'\n');
				lastclass = 1234;
				continue;
			case 'd':
				for (class = '0'; class <= '9'; class++)
					regset(bits,def,class);
				lastclass = 1234;
				continue;
			case 'n':
				class = '\n';
				break;
			case 'r':
				class = '\r';
				break;
			case 't':
				class = '\t';
				break;
			case 'f':
				class = '\f';
				break;
			case 'b':
				class = '\b';
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				class -= '0';
				if (isdigit(*regparse)) {
					class <<= 3;
					class += *regparse++ - '0';
				}
				if (isdigit(*regparse)) {
					class <<= 3;
					class += *regparse++ - '0';
				}
				break;
			}
		}
		if (!range && class == '-' && *regparse && *regparse != ']') {
			range = 1;
			continue;
		}
		if (range) {
			if (lastclass > class)
				FAIL("invalid [] range in regexp");
		}
		else
			lastclass = class - 1;
		range = 0;
		for (lastclass++; lastclass <= class; lastclass++) {
			regset(bits,def,lastclass);
			if (regfold && isupper(lastclass))
				regset(bits,def,tolower(lastclass));
		}
		lastclass = class;
	}
	if (*regparse != ']')
		FAIL("unmatched [] in regexp");
	regset(bits,0,0);		/* always bomb out on null */
	regparse++;
	return ret;
}

#else /* !FASTANY */
static char *
regclass()
{
	register int class;
	register int lastclass;
	register int range = 0;
	register char *ret;

	if (*regparse == '^') {	/* Complement of range. */
		ret = regnode(ANYBUT);
		regparse++;
	} else
		ret = regnode(ANYOF);
	if (*regparse == ']' || *regparse == '-')
		regc(lastclass = *regparse++);
	while (*regparse != '\0' && *regparse != ']') {
		class = UCHARAT(regparse++);
		if (class == '\\') {
			class = UCHARAT(regparse++);
			switch (class) {
			case 'w':
				for (class = 'a'; class <= 'z'; class++)
					regc(class);
				for (class = 'A'; class <= 'Z'; class++)
					regc(class);
				for (class = '0'; class <= '9'; class++)
					regc(class);
				regc('_');
				lastclass = 1234;
				continue;
			case 's':
				regc(' ');
				regc('\t');
				regc('\r');
				regc('\f');
				regc('\n');
				lastclass = 1234;
				continue;
			case 'd':
				for (class = '0'; class <= '9'; class++)
					regc(class);
				lastclass = 1234;
				continue;
			case 'n':
				class = '\n';
				break;
			case 'r':
				class = '\r';
				break;
			case 't':
				class = '\t';
				break;
			case 'f':
				class = '\f';
				break;
			case 'b':
				class = '\b';
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				class -= '0';
				if (isdigit(*regparse)) {
					class <<= 3;
					class += *regparse++ - '0';
				}
				if (isdigit(*regparse)) {
					class <<= 3;
					class += *regparse++ - '0';
				}
				break;
			}
		}
		if (!range && class == '-' && *regparse && *regparse != ']') {
			range = 1;
			continue;
		}
		if (range) {
			if (lastclass > class)
				FAIL("invalid [] range in regexp");
		}
		else
			lastclass = class - 1;
		range = 0;
		for (lastclass++; lastclass <= class; lastclass++) {
			regc(lastclass);
			if (regfold && isupper(lastclass))
				regc(tolower(lastclass));
		}
		lastclass = class;
	}
	regc('\0');
	if (*regparse != ']')
		FAIL("unmatched [] in regexp");
	regparse++;
	return ret;
}
#endif /* NOTDEF */

static char *
regchar(ch,flagp)
int ch;
int *flagp;
{
	char *ret;

	ret = regnode(EXACTLY);
	regc(1);
	regc(ch);
	regc('\0');
	regparse++;
	*flagp |= HASWIDTH|SIMPLE;
	return ret;
}

/*
 - regnode - emit a node
 */
static char *			/* Location. */
regnode(op)
char op;
{
	register char *ret;
	register char *ptr;

	ret = regcode;
	if (ret == &regdummy) {
#ifdef ALIGN
		if (!(regsize & 1))
			regsize++;
#endif
		regsize += 3;
		return(ret);
	}

#ifdef ALIGN
	if (!((long)ret & 1))
	    *ret++ = 127;
#endif
	ptr = ret;
	*ptr++ = op;
	*ptr++ = '\0';		/* Null "next" pointer. */
	*ptr++ = '\0';
	regcode = ptr;

	return(ret);
}

/*
 - regc - emit (if appropriate) a byte of code
 */
static void
regc(b)
char b;
{
	if (regcode != &regdummy)
		*regcode++ = b;
	else
		regsize++;
}

/*
 - reginsert - insert an operator in front of already-emitted operand
 *
 * Means relocating the operand.
 */
static void
reginsert(op, opnd)
char op;
char *opnd;
{
	register char *src;
	register char *dst;
	register char *place;

	if (regcode == &regdummy) {
#ifdef ALIGN
		regsize += 4;
#else
		regsize += 3;
#endif
		return;
	}

	src = regcode;
#ifdef ALIGN
	regcode += 4;
#else
	regcode += 3;
#endif
	dst = regcode;
	while (src > opnd)
		*--dst = *--src;

	place = opnd;		/* Op node, where operand used to be. */
	*place++ = op;
	*place++ = '\0';
	*place++ = '\0';
}

/*
 - regtail - set the next-pointer at the end of a node chain
 */
static void
regtail(p, val)
char *p;
char *val;
{
	register char *scan;
	register char *temp;
	register int offset;

	if (p == &regdummy)
		return;

	/* Find last node. */
	scan = p;
	for (;;) {
		temp = regnext(scan);
		if (temp == NULL)
			break;
		scan = temp;
	}

#ifdef ALIGN
	offset = val - scan;
	*(short*)(scan+1) = offset;
#else
	if (OP(scan) == BACK)
		offset = scan - val;
	else
		offset = val - scan;
	*(scan+1) = (offset>>8)&0377;
	*(scan+2) = offset&0377;
#endif
}

/*
 - regoptail - regtail on operand of first argument; nop if operandless
 */
static void
regoptail(p, val)
char *p;
char *val;
{
	/* "Operandless" and "op != BRANCH" are synonymous in practice. */
	if (p == NULL || p == &regdummy || OP(p) != BRANCH)
		return;
	regtail(NEXTOPER(p), val);
}

/*
 * regexec and friends
 */

/*
 * Global work variables for regexec().
 */
static char *reginput;		/* String-input pointer. */
static char *regbol;		/* Beginning of input, for ^ check. */
static char **regstartp;	/* Pointer to startp array. */
static char **regendp;		/* Ditto for endp. */
static char *reglastparen;	/* Similarly for lastparen. */
static char *regtill;

static char *regmystartp[10];	/* For remembering backreferences. */
static char *regmyendp[10];

/*
 * Forwards.
 */
STATIC int regtry();
STATIC int regmatch();
STATIC int regrepeat();

extern char sawampersand;
extern int multiline;

/*
 - regexec - match a regexp against a string
 */
int
regexec(prog, stringarg, strend, beginning, minend, screamer)
register regexp *prog;
char *stringarg;
char *strend;	/* pointer to null at end of string */
int beginning;	/* is ^ valid at the beginning of stringarg? */
int minend;	/* end of match must be at least minend after stringarg */
STR *screamer;
{
	register char *s;
	extern char *index();
	register int tmp, i;
	register char *string = stringarg;
	register char *c;
	extern char *savestr();

	/* Be paranoid... */
	if (prog == NULL || string == NULL) {
		fatal("NULL regexp parameter");
		return(0);
	}

	regprecomp = prog->precomp;
	/* Check validity of program. */
	if (UCHARAT(prog->program) != MAGIC) {
		FAIL("corrupted regexp program");
	}

	if (prog->do_folding) {
		i = strend - string;
		string = savestr(string);
		strend = string + i;
		for (s = string; *s; s++)
			if (isupper(*s))
				*s = tolower(*s);
	}

	/* If there is a "must appear" string, look for it. */
	s = string;
	if (prog->regmust != Nullstr) {
		if (beginning && screamer) {
			if (screamfirst[prog->regmust->str_rare] >= 0)
				s = screaminstr(screamer,prog->regmust);
			else
				s = Nullch;
		}
		else
			s = fbminstr(s,strend,prog->regmust);
		if (!s) {
			++*(long*)&prog->regmust->str_nval;	/* hooray */
			goto phooey;	/* not present */
		}
		else if (prog->regback >= 0) {
			s -= prog->regback;
			if (s < string)
			    s = string;
		}
		else if (--*(long*)&prog->regmust->str_nval < 0) { /* boo */
			str_free(prog->regmust);
			prog->regmust = Nullstr;	/* disable regmust */
			s = string;
		}
		else
			s = string;
	}

	/* Mark beginning of line for ^ . */
	if (beginning)
		regbol = string;
	else
		regbol = NULL;

	/* see how far we have to get to not match where we matched before */
	regtill = string+minend;

	/* Simplest case:  anchored match need be tried only once. */
	/*  [unless multiline is set] */
	if (prog->reganch) {
		if (regtry(prog, string))
			goto got_it;
		else if (multiline) {
			/* for multiline we only have to try after newlines */
			if (s > string)
			    s--;
			while ((s = index(s, '\n')) != NULL) {
				if (*++s && regtry(prog, s))
					goto got_it;
			}
		}
		goto phooey;
	}

	/* Messy cases:  unanchored match. */
	if (prog->regstart) {
		/* We know what string it must start with. */
		if (prog->regstart->str_pok == 3) {
		    while ((s = fbminstr(s, strend, prog->regstart)) != NULL) {
			    if (regtry(prog, s))
				    goto got_it;
			    s++;
		    }
		}
		else {
		    c = prog->regstart->str_ptr;
		    while ((s = instr(s, c)) != NULL) {
			    if (regtry(prog, s))
				    goto got_it;
			    s++;
		    }
		}
	}
	else if (c = prog->regstclass) {
		/* We know what class it must start with. */
		switch (OP(c)) {
		case ANYOF: case ANYBUT:
		    c = OPERAND(c);
		    while (i = *s) {
			    if (!(c[i >> 3] & (1 << (i&7))))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case BOUND:
		    tmp = 0;
		    while (i = *s) {
			    if (tmp != (isalpha(i) || isdigit(i) || i == '_')) {
				    tmp = !tmp;
				    if (regtry(prog, s))
					    goto got_it;
			    }
			    s++;
		    }
		    if (tmp && regtry(prog,s))
			    goto got_it;
		    break;
		case NBOUND:
		    tmp = 0;
		    while (i = *s) {
			    if (tmp != (isalpha(i) || isdigit(i) || i == '_'))
				    tmp = !tmp;
			    else if (regtry(prog, s))
				    goto got_it;
			    s++;
		    }
		    if (!tmp && regtry(prog,s))
			    goto got_it;
		    break;
		case ALNUM:
		    while (i = *s) {
			    if (isalpha(i) || isdigit(i) || i == '_')
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case NALNUM:
		    while (i = *s) {
			    if (!isalpha(i) && !isdigit(i) && i != '_')
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case SPACE:
		    while (i = *s) {
			    if (isspace(i))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case NSPACE:
		    while (i = *s) {
			    if (!isspace(i))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case DIGIT:
		    while (i = *s) {
			    if (isdigit(i))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case NDIGIT:
		    while (i = *s) {
			    if (!isdigit(i))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		}
	}
	else
		/* We don't know much -- general case. */
		do {
			if (regtry(prog, s))
				goto got_it;
		} while (*s++ != '\0');

	/* Failure. */
	goto phooey;

    got_it:
	if (prog->nparens || sawampersand || prog->do_folding) {
		s = savestr(stringarg);	/* so $digit will always work */
		if (prog->subbase)
			safefree(prog->subbase);
		prog->subbase = s;
		tmp = prog->subbase - string;
		for (i = 0; i <= prog->nparens; i++) {
			if (prog->endp[i]) {
				prog->startp[i] += tmp;
				prog->endp[i] += tmp;
			}
		}
		if (prog->do_folding) {
			safefree(string);
		}
	}
	return(1);

    phooey:
	if (prog->do_folding) {
		safefree(string);
	}
	return(0);
}

/*
 - regtry - try match at specific point
 */
static int			/* 0 failure, 1 success */
regtry(prog, string)
regexp *prog;
char *string;
{
	register int i;
	register char **sp;
	register char **ep;

	reginput = string;
	regstartp = prog->startp;
	regendp = prog->endp;
	reglastparen = &prog->lastparen;

	sp = prog->startp;
	ep = prog->endp;
	if (prog->nparens) {
		for (i = NSUBEXP; i > 0; i--) {
			*sp++ = NULL;
			*ep++ = NULL;
		}
	}
	if (regmatch(prog->program + 1) && reginput >= regtill) {
		prog->startp[0] = string;
		prog->endp[0] = reginput;
		return(1);
	} else
		return(0);
}

/*
 - regmatch - main matching routine
 *
 * Conceptually the strategy is simple:  check to see whether the current
 * node matches, call self recursively to see whether the rest matches,
 * and then act accordingly.  In practice we make some effort to avoid
 * recursion, in particular by going through "ordinary" nodes (that don't
 * need to know whether the rest of the match failed) by a loop instead of
 * by recursion.
 */
/* [lwall] I've hoisted the register declarations to the outer block in order to
 * maybe save a little bit of pushing and popping on the stack.  It also takes
 * advantage of machines that use a register save mask on subroutine entry.
 */
static int			/* 0 failure, 1 success */
regmatch(prog)
char *prog;
{
	register char *scan;	/* Current node. */
	char *next;		/* Next node. */
	extern char *index();
	register int nextchar;
	register int n;		/* no or next */
	register int ln;        /* len or last */
	register char *s;	/* operand or save */
	register char *locinput = reginput;

	nextchar = *reginput;
	scan = prog;
#ifdef DEBUG
	if (scan != NULL && regnarrate)
		fprintf(stderr, "%s(\n", regprop(scan));
#endif
	while (scan != NULL) {
#ifdef DEBUG
		if (regnarrate)
			fprintf(stderr, "%s...\n", regprop(scan));
#endif

#ifdef ALIGN
		next = scan + NEXT(scan);
		if (next == scan)
		    next = NULL;
#else
		next = regnext(scan);
#endif

		switch (OP(scan)) {
		case BOL:
			if (locinput == regbol ||
			    (nextchar && locinput[-1] == '\n') ) {
				regtill--;
				break;
			}
			return(0);
		case EOL:
			if (nextchar != '\0' && nextchar != '\n')
				return(0);
			regtill--;
			break;
		case ANY:
			if (nextchar == '\0' || nextchar == '\n')
				return(0);
			nextchar = *++locinput;
			break;
		case EXACTLY:
			s = OPERAND(scan);
			ln = *s++;
			/* Inline the first character, for speed. */
			if (*s != nextchar)
				return(0);
			if (ln > 1 && strncmp(s, locinput, ln) != 0)
				return(0);
			locinput += ln;
			nextchar = *locinput;
			break;
		case ANYOF:
		case ANYBUT:
			s = OPERAND(scan);
			if (nextchar < 0)
				nextchar = UCHARAT(locinput);
			if (s[nextchar >> 3] & (1 << (nextchar&7)))
				return(0);
			nextchar = *++locinput;
			break;
#ifdef NOTDEF
		case ANYOF:
 			if (nextchar == '\0' || index(OPERAND(scan), nextchar) == NULL)
				return(0);
			nextchar = *++locinput;
			break;
		case ANYBUT:
 			if (nextchar == '\0' || index(OPERAND(scan), nextchar) != NULL)
				return(0);
			nextchar = *++locinput;
			break;
#endif
		case ALNUM:
			if (!nextchar)
				return(0);
			if (!isalpha(nextchar) && !isdigit(nextchar) &&
			  nextchar != '_')
				return(0);
			nextchar = *++locinput;
			break;
		case NALNUM:
			if (!nextchar)
				return(0);
			if (isalpha(nextchar) || isdigit(nextchar) ||
			  nextchar == '_')
				return(0);
			nextchar = *++locinput;
			break;
		case NBOUND:
		case BOUND:
			if (locinput == regbol)	/* was last char in word? */
				ln = 0;
			else 
				ln = (isalpha(locinput[-1]) ||
				     isdigit(locinput[-1]) ||
				     locinput[-1] == '_' );
			n = (isalpha(nextchar) || isdigit(nextchar) ||
			    nextchar == '_' );	/* is next char in word? */
			if ((ln == n) == (OP(scan) == BOUND))
				return(0);
			break;
		case SPACE:
			if (!nextchar)
				return(0);
			if (!isspace(nextchar))
				return(0);
			nextchar = *++locinput;
			break;
		case NSPACE:
			if (!nextchar)
				return(0);
			if (isspace(nextchar))
				return(0);
			nextchar = *++locinput;
			break;
		case DIGIT:
			if (!isdigit(nextchar))
				return(0);
			nextchar = *++locinput;
			break;
		case NDIGIT:
			if (!nextchar)
				return(0);
			if (isdigit(nextchar))
				return(0);
			nextchar = *++locinput;
			break;
		case REF:
		case REF+1:
		case REF+2:
		case REF+3:
		case REF+4:
		case REF+5:
		case REF+6:
		case REF+7:
		case REF+8:
		case REF+9:
			n = OP(scan) - REF;
			s = regmystartp[n];
			if (!s)
			    return(0);
			if (!regmyendp[n])
			    return(0);
			if (s == regmyendp[n])
			    break;
			/* Inline the first character, for speed. */
			if (*s != nextchar)
				return(0);
			ln = regmyendp[n] - s;
			if (ln > 1 && strncmp(s, locinput, ln) != 0)
				return(0);
			locinput += ln;
			nextchar = *locinput;
			break;

		case NOTHING:
			break;
		case BACK:
			break;
		case OPEN+1:
		case OPEN+2:
		case OPEN+3:
		case OPEN+4:
		case OPEN+5:
		case OPEN+6:
		case OPEN+7:
		case OPEN+8:
		case OPEN+9:
			n = OP(scan) - OPEN;
			reginput = locinput;

			regmystartp[n] = locinput;	/* for REF */
			if (regmatch(next)) {
				/*
				 * Don't set startp if some later
				 * invocation of the same parentheses
				 * already has.
				 */
				if (regstartp[n] == NULL)
					regstartp[n] = locinput;
				return(1);
			} else
				return(0);
			/* NOTREACHED */
		case CLOSE+1:
		case CLOSE+2:
		case CLOSE+3:
		case CLOSE+4:
		case CLOSE+5:
		case CLOSE+6:
		case CLOSE+7:
		case CLOSE+8:
		case CLOSE+9: {
				n = OP(scan) - CLOSE;
				reginput = locinput;

				regmyendp[n] = locinput;	/* for REF */
				if (regmatch(next)) {
					/*
					 * Don't set endp if some later
					 * invocation of the same parentheses
					 * already has.
					 */
					if (regendp[n] == NULL) {
						regendp[n] = locinput;
						*reglastparen = n;
					}
					return(1);
				} else
					return(0);
			}
			break;
		case BRANCH: {
				if (OP(next) != BRANCH)		/* No choice. */
					next = NEXTOPER(scan);	/* Avoid recursion. */
				else {
					do {
						reginput = locinput;
						if (regmatch(NEXTOPER(scan)))
							return(1);
#ifdef ALIGN
						if (n = NEXT(scan))
						    scan += n;
						else
						    scan = NULL;
#else
						scan = regnext(scan);
#endif
					} while (scan != NULL && OP(scan) == BRANCH);
					return(0);
					/* NOTREACHED */
				}
			}
			break;
		case STAR:
		case PLUS:
			/*
			 * Lookahead to avoid useless match attempts
			 * when we know what character comes next.
			 */
			if (OP(next) == EXACTLY)
				nextchar = *(OPERAND(next)+1);
			else
				nextchar = '\0';
			ln = (OP(scan) == STAR) ? 0 : 1;
			reginput = locinput;
			n = regrepeat(NEXTOPER(scan));
			while (n >= ln) {
				/* If it could work, try it. */
				if (nextchar == '\0' || *reginput == nextchar)
					if (regmatch(next))
						return(1);
				/* Couldn't or didn't -- back up. */
				n--;
				reginput = locinput + n;
			}
			return(0);
		case END:
			reginput = locinput; /* put where regtry can find it */
			return(1);	/* Success! */
		default:
			printf("%x %d\n",scan,scan[1]);
			FAIL("regexp memory corruption");
		}

		scan = next;
	}

	/*
	 * We get here only if there's trouble -- normally "case END" is
	 * the terminating point.
	 */
	FAIL("corrupted regexp pointers");
	/*NOTREACHED*/
}

/*
 - regrepeat - repeatedly match something simple, report how many
 */
/*
 * [This routine now assumes that it will only match on things of length 1.
 * That was true before, but now we assume scan - reginput is the count,
 * rather than incrementing count on every character.]
 */
static int
regrepeat(p)
char *p;
{
	register char *scan;
	register char *opnd;
	register int c;

	scan = reginput;
	opnd = OPERAND(p);
	switch (OP(p)) {
	case ANY:
		while (*scan && *scan != '\n')
			scan++;
		break;
	case EXACTLY:		/* length of string is 1 */
		opnd++;
		while (*opnd == *scan)
			scan++;
		break;
#ifdef FASTANY
	case ANYOF:
	case ANYBUT:
		c = UCHARAT(scan);
		while (!(opnd[c >> 3] & (1 << (c & 7)))) {
			scan++;
			c = UCHARAT(scan);
		}
		break;
#else
	case ANYOF:
		while (*scan != '\0' && index(opnd, *scan) != NULL)
			scan++;
		break;
	case ANYBUT:
		while (*scan != '\0' && index(opnd, *scan) == NULL)
			scan++;
		break;
#endif /* FASTANY */
	case ALNUM:
		while (*scan && (isalpha(*scan) || isdigit(*scan) ||
		  *scan == '_'))
			scan++;
		break;
	case NALNUM:
		while (*scan && (!isalpha(*scan) && !isdigit(*scan) &&
		  *scan != '_'))
			scan++;
		break;
	case SPACE:
		while (*scan && isspace(*scan))
			scan++;
		break;
	case NSPACE:
		while (*scan && !isspace(*scan))
			scan++;
		break;
	case DIGIT:
		while (*scan && isdigit(*scan))
			scan++;
		break;
	case NDIGIT:
		while (*scan && !isdigit(*scan))
			scan++;
		break;
	default:		/* Oh dear.  Called inappropriately. */
		FAIL("internal regexp foulup");
		/* NOTREACHED */
	}

	c = scan - reginput;
	reginput = scan;

	return(c);
}

/*
 - regnext - dig the "next" pointer out of a node
 *
 * [Note, when ALIGN is defined there are two places in regmatch() that bypass
 * this code for speed.]
 */
static char *
regnext(p)
register char *p;
{
	register int offset;

	if (p == &regdummy)
		return(NULL);

	offset = NEXT(p);
	if (offset == 0)
		return(NULL);

#ifdef ALIGN
	return(p+offset);
#else
	if (OP(p) == BACK)
		return(p-offset);
	else
		return(p+offset);
#endif
}

#ifdef DEBUG

STATIC char *regprop();

/*
 - regdump - dump a regexp onto stdout in vaguely comprehensible form
 */
void
regdump(r)
regexp *r;
{
	register char *s;
	register char op = EXACTLY;	/* Arbitrary non-END op. */
	register char *next;
	extern char *index();


	s = r->program + 1;
	while (op != END) {	/* While that wasn't END last time... */
#ifdef ALIGN
		if (!((long)s & 1))
			s++;
#endif
		op = OP(s);
		printf("%2d%s", s-r->program, regprop(s));	/* Where, what. */
		next = regnext(s);
		if (next == NULL)		/* Next ptr. */
			printf("(0)");
		else 
			printf("(%d)", (s-r->program)+(next-s));
		s += 3;
		if (op == ANYOF || op == ANYBUT) {
			s += 32;
		}
		if (op == EXACTLY) {
			/* Literal string, where present. */
			s++;
			while (*s != '\0') {
				putchar(*s);
				s++;
			}
			s++;
		}
		putchar('\n');
	}

	/* Header fields of interest. */
	if (r->regstart)
		printf("start `%s' ", r->regstart->str_ptr);
	if (r->regstclass)
		printf("stclass `%s' ", regprop(OP(r->regstclass)));
	if (r->reganch)
		printf("anchored ");
	if (r->regmust != NULL)
		printf("must have \"%s\" back %d ", r->regmust->str_ptr,
		  r->regback);
	printf("\n");
}

/*
 - regprop - printable representation of opcode
 */
static char *
regprop(op)
char *op;
{
	register char *p;
	static char buf[50];

	(void) strcpy(buf, ":");

	switch (OP(op)) {
	case BOL:
		p = "BOL";
		break;
	case EOL:
		p = "EOL";
		break;
	case ANY:
		p = "ANY";
		break;
	case ANYOF:
		p = "ANYOF";
		break;
	case ANYBUT:
		p = "ANYBUT";
		break;
	case BRANCH:
		p = "BRANCH";
		break;
	case EXACTLY:
		p = "EXACTLY";
		break;
	case NOTHING:
		p = "NOTHING";
		break;
	case BACK:
		p = "BACK";
		break;
	case END:
		p = "END";
		break;
	case ALNUM:
		p = "ALNUM";
		break;
	case NALNUM:
		p = "NALNUM";
		break;
	case BOUND:
		p = "BOUND";
		break;
	case NBOUND:
		p = "NBOUND";
		break;
	case SPACE:
		p = "SPACE";
		break;
	case NSPACE:
		p = "NSPACE";
		break;
	case DIGIT:
		p = "DIGIT";
		break;
	case NDIGIT:
		p = "NDIGIT";
		break;
	case REF:
	case REF+1:
	case REF+2:
	case REF+3:
	case REF+4:
	case REF+5:
	case REF+6:
	case REF+7:
	case REF+8:
	case REF+9:
		sprintf(buf+strlen(buf), "REF%d", OP(op)-REF);
		p = NULL;
		break;
	case OPEN+1:
	case OPEN+2:
	case OPEN+3:
	case OPEN+4:
	case OPEN+5:
	case OPEN+6:
	case OPEN+7:
	case OPEN+8:
	case OPEN+9:
		sprintf(buf+strlen(buf), "OPEN%d", OP(op)-OPEN);
		p = NULL;
		break;
	case CLOSE+1:
	case CLOSE+2:
	case CLOSE+3:
	case CLOSE+4:
	case CLOSE+5:
	case CLOSE+6:
	case CLOSE+7:
	case CLOSE+8:
	case CLOSE+9:
		sprintf(buf+strlen(buf), "CLOSE%d", OP(op)-CLOSE);
		p = NULL;
		break;
	case STAR:
		p = "STAR";
		break;
	case PLUS:
		p = "PLUS";
		break;
	default:
		FAIL("corrupted regexp opcode");
	}
	if (p != NULL)
		(void) strcat(buf, p);
	return(buf);
}
#endif

#ifdef NOTDEF
/*
 * The following is provided for those people who do not have strcspn() in
 * their C libraries.  They should get off their butts and do something
 * about it; at least one public-domain implementation of those (highly
 * useful) string routines has been published on Usenet.
 */
#ifndef STRCSPN
/*
 * strcspn - find length of initial segment of s1 consisting entirely
 * of characters not from s2
 */

static int
strcspn(s1, s2)
char *s1;
char *s2;
{
	register char *scan1;
	register char *scan2;
	register int count;

	count = 0;
	for (scan1 = s1; *scan1 != '\0'; scan1++) {
		for (scan2 = s2; *scan2 != '\0';)	/* ++ moved down. */
			if (*scan1 == *scan2++)
				return(count);
		count++;
	}
	return(count);
}
#endif
#endif /* NOTDEF */

regfree(r)
struct regexp *r;
{
	if (r->precomp)
		safefree(r->precomp);
	if (r->subbase)
		safefree(r->subbase);
	if (r->regmust)
		str_free(r->regmust);
	if (r->regstart)
		str_free(r->regstart);
	safefree((char*)r);
}
