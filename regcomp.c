/* NOTE: this is derived from Henry Spencer's regexp code, and should not
 * confused with the original package (see point 3 below).  Thanks, Henry!
 */

/* Additional note: this code is very heavily munged from Henry's version
 * in places.  In some spots I've traded clarity for efficiency, so don't
 * blame Henry for some of the lack of readability.
 */

/* $Header: regcomp.c,v 3.0 89/10/18 15:22:29 lwall Locked $
 *
 * $Log:	regcomp.c,v $
 * Revision 3.0  89/10/18  15:22:29  lwall
 * 3.0 baseline
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
 *
 ****    Alterations to Henry's code are...
 ****
 ****    Copyright (c) 1989, Larry Wall
 ****
 ****    You may distribute under the terms of the GNU General Public License
 ****    as specified in the README file that comes with the perl 3.0 kit.
 *
 * Beware that some of this code is subtly aware of the way operator
 * precedence is structured in regular expressions.  Serious changes in
 * regular-expression syntax might require a total rethink.
 */
#include "EXTERN.h"
#include "perl.h"
#include "INTERN.h"
#include "regcomp.h"

#ifndef STATIC
#define	STATIC	static
#endif

#define	ISMULT1(c)	((c) == '*' || (c) == '+' || (c) == '?')
#define	ISMULT2(s)	((*s) == '*' || (*s) == '+' || (*s) == '?' || \
	((*s) == '{' && regcurly(s)))
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
static char *regxend;		/* End of input for compile */
static int regnpar;		/* () count. */
static char *regcode;		/* Code-emit pointer; &regdummy = don't. */
static long regsize;		/* Code size. */
static int regfold;
static int regsawbracket;	/* Did we do {d,d} trick? */

/*
 * Forward declarations for regcomp()'s friends.
 */
STATIC int regcurly();
STATIC char *reg();
STATIC char *regbranch();
STATIC char *regpiece();
STATIC char *regatom();
STATIC char *regclass();
STATIC char *regnode();
STATIC void regc();
STATIC void reginsert();
STATIC void regtail();
STATIC void regoptail();

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
regcomp(exp,xend,fold,rare)
char *exp;
char *xend;
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
	regxend = xend;
	regprecomp = nsavestr(exp,xend-exp);
	regsawbracket = 0;
	regnpar = 1;
	regsize = 0L;
	regcode = &regdummy;
	regc(MAGIC);
	if (reg(0, &flags) == NULL) {
		Safefree(regprecomp);
		return(NULL);
	}

	/* Small enough for pointer-storage convention? */
	if (regsize >= 32767L)		/* Probably could be 65535L. */
		FAIL("regexp too big");

	/* Allocate space. */
	Newc(1001, r, sizeof(regexp) + (unsigned)regsize, char, regexp);
	if (r == NULL)
		FAIL("regexp out of space");

	/* Second pass: emit code. */
	if (regsawbracket)
	    bcopy(regprecomp,exp,xend-exp);
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
	if (OP(regnext(scan)) == END) {/* Only one top-level choice. */
		scan = NEXTOPER(scan);

		first = scan;
		while ((OP(first) > OPEN && OP(first) < CLOSE) ||
		    (OP(first) == BRANCH && OP(regnext(first)) != BRANCH) ||
		    (OP(first) == PLUS) )
			first = NEXTOPER(first);

		/* Starting-point info. */
		if (OP(first) == EXACTLY) {
			r->regstart =
			    str_make(OPERAND(first)+1,*OPERAND(first));
			if (r->regstart->str_cur > !(sawstudy|fold))
				fbmcompile(r->regstart,fold);
		}
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
		longest = str_make("",0);
		len = 0;
		curback = 0;
		back = 0;
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
			    first = scan;
			    while (OP(regnext(scan)) >= CLOSE)
				scan = regnext(scan);
			    if (curback - back == len) {
				str_ncat(longest, OPERAND(first)+1,
				    *OPERAND(first));
				len += *OPERAND(first);
				curback += *OPERAND(first);
				first = regnext(scan);
			    }
			    else if (*OPERAND(first) >= len + (curback >= 0)) {
				len = *OPERAND(first);
				str_nset(longest, OPERAND(first)+1,len);
				back = curback;
				curback += len;
				first = regnext(scan);
			    }
			    else
				curback += *OPERAND(first);
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
			if (len > !(sawstudy||fold||OP(first)==EOL))
				fbmcompile(r->regmust,fold);
			r->regmust->str_u.str_useful = 100;
			if (OP(first) == EOL) /* is match anchored to EOL? */
			    r->regmust->str_pok |= SP_TAIL;
		}
		else
			str_free(longest);
	}

	r->do_folding = fold;
	r->nparens = regnpar - 1;
#ifdef DEBUGGING
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
	} else if (!paren && regparse < regxend) {
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
	while (regparse < regxend && *regparse != '|' && *regparse != ')') {
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
	char *origparse = regparse;
	int orignpar = regnpar;
	char *max;
	int iter;
	char ch;

	ret = regatom(&flags);
	if (ret == NULL)
		return(NULL);

	op = *regparse;

	/* Here's a total kludge: if after the atom there's a {\d+,?\d*}
	 * then we decrement the first number by one and reset our
	 * parsing back to the beginning of the same atom.  If the first number
	 * is down to 0, decrement the second number instead and fake up
	 * a ? after it.  Given the way this compiler doesn't keep track
	 * of offsets on the first pass, this is the only way to replicate
	 * a piece of code.  Sigh.
	 */
	if (op == '{' && regcurly(regparse)) {
	    next = regparse + 1;
	    max = Nullch;
	    while (isdigit(*next) || *next == ',') {
		if (*next == ',') {
		    if (max)
			break;
		    else
			max = next;
		}
		next++;
	    }
	    if (*next == '}') {		/* got one */
		regsawbracket++;	/* remember we clobbered exp */
		if (!max)
		    max = next;
		regparse++;
		iter = atoi(regparse);
		if (iter > 0) {
		    ch = *max;
		    sprintf(regparse,"%.*d", max-regparse, iter - 1);
		    *max = ch;
		    if (*max == ',' && atoi(max+1) > 0) {
			ch = *next;
			sprintf(max+1,"%.*d", next-(max+1), atoi(max+1) - 1);
			*next = ch;
		    }
		    if (iter != 1 || (*max == ',' || atoi(max+1))) {
			regparse = origparse;	/* back up input pointer */
			regnpar = orignpar;	/* don't make more parens */
		    }
		    else {
			regparse = next;
			goto nest_check;
		    }
		    *flagp = flags;
		    return ret;
		}
		if (*max == ',') {
		    max++;
		    iter = atoi(max);
		    if (max == next) {		/* any number more? */
			regparse = next;
			op = '*';		/* fake up one with a star */
		    }
		    else if (iter > 0) {
			op = '?';		/* fake up optional atom */
			ch = *next;
			sprintf(max,"%.*d", next-max, iter - 1);
			*next = ch;
			if (iter == 1)
			    regparse = next;
			else {
			    regparse = origparse - 1; /* offset ++ below */
			    regnpar = orignpar;
			}
		    }
		    else
			fatal("Can't do {n,0}");
		}
		else
		    fatal("Can't do {0}");
	    }
	}

	if (!ISMULT1(op)) {
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
      nest_check:
	regparse++;
	if (ISMULT2(regparse))
		FAIL("nested *?+ in regexp");

	return(ret);
}

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
		case '\0':
			if (regparse >= regxend)
			    FAIL("trailing \\ in regexp");
			/* FALL THROUGH */
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
			for (len=0, p=regparse-1;
			  len < 127 && p < regxend;
			  len++)
			{
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
				case '\0':
				    if (p >= regxend)
					FAIL("trailing \\ in regexp");
				    /* FALL THROUGH */
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
			    if (ISMULT2(p)) { /* Back off on ?+*. */
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
			if (regcode != &regdummy)
			    *OPERAND(ret) = len;
			regc('\0');
		}
		break;
	}

	return(ret);
}

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
	while (regparse < regxend && *regparse != ']') {
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
		if (!range && class == '-' && regparse < regxend &&
		    *regparse != ']') {
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
#ifdef REGALIGN
		if (!(regsize & 1))
			regsize++;
#endif
		regsize += 3;
		return(ret);
	}

#ifdef REGALIGN
#ifndef lint
	if (!((long)ret & 1))
	    *ret++ = 127;
#endif
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
#ifdef REGALIGN
		regsize += 4;
#else
		regsize += 3;
#endif
		return;
	}

	src = regcode;
#ifdef REGALIGN
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

#ifdef REGALIGN
	offset = val - scan;
#ifndef lint
	*(short*)(scan+1) = offset;
#else
	offset = offset;
#endif
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
 - regcurly - a little FSA that accepts {\d+,?\d*}
 */
STATIC int
regcurly(s)
register char *s;
{
    if (*s++ != '{')
	return FALSE;
    if (!isdigit(*s))
	return FALSE;
    while (isdigit(*s))
	s++;
    if (*s == ',')
	s++;
    while (isdigit(*s))
	s++;
    if (*s != '}')
	return FALSE;
    return TRUE;
}

#ifdef DEBUGGING

/*
 - regdump - dump a regexp onto stderr in vaguely comprehensible form
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
#ifdef REGALIGN
		if (!((long)s & 1))
			s++;
#endif
		op = OP(s);
		fprintf(stderr,"%2d%s", s-r->program, regprop(s));	/* Where, what. */
		next = regnext(s);
		if (next == NULL)		/* Next ptr. */
			fprintf(stderr,"(0)");
		else 
			fprintf(stderr,"(%d)", (s-r->program)+(next-s));
		s += 3;
		if (op == ANYOF || op == ANYBUT) {
			s += 32;
		}
		if (op == EXACTLY) {
			/* Literal string, where present. */
			s++;
			while (*s != '\0') {
				(void)putchar(*s);
				s++;
			}
			s++;
		}
		(void)putchar('\n');
	}

	/* Header fields of interest. */
	if (r->regstart)
		fprintf(stderr,"start `%s' ", r->regstart->str_ptr);
	if (r->regstclass)
		fprintf(stderr,"stclass `%s' ", regprop(r->regstclass));
	if (r->reganch)
		fprintf(stderr,"anchored ");
	if (r->regmust != NULL)
		fprintf(stderr,"must have \"%s\" back %d ", r->regmust->str_ptr,
		  r->regback);
	fprintf(stderr,"\n");
}

/*
 - regprop - printable representation of opcode
 */
char *
regprop(op)
char *op;
{
	register char *p;

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
		(void)sprintf(buf+strlen(buf), "REF%d", OP(op)-REF);
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
		(void)sprintf(buf+strlen(buf), "OPEN%d", OP(op)-OPEN);
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
		(void)sprintf(buf+strlen(buf), "CLOSE%d", OP(op)-CLOSE);
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
#endif /* DEBUGGING */

regfree(r)
struct regexp *r;
{
	if (r->precomp)
		Safefree(r->precomp);
	if (r->subbase)
		Safefree(r->subbase);
	if (r->regmust)
		str_free(r->regmust);
	if (r->regstart)
		str_free(r->regstart);
	Safefree(r);
}
