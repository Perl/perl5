/* NOTE: this is derived from Henry Spencer's regexp code, and should not
 * confused with the original package (see point 3 below).  Thanks, Henry!
 */

/* Additional note: this code is very heavily munged from Henry's version
 * in places.  In some spots I've traded clarity for efficiency, so don't
 * blame Henry for some of the lack of readability.
 */

/* $Header: regexec.c,v 3.0 89/10/18 15:22:53 lwall Locked $
 *
 * $Log:	regexec.c,v $
 * Revision 3.0  89/10/18  15:22:53  lwall
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
#include "regcomp.h"

#ifndef STATIC
#define	STATIC	static
#endif

#ifdef DEBUGGING
int regnarrate = 0;
#endif

/*
 * regexec and friends
 */

/*
 * Global work variables for regexec().
 */
static char *regprecomp;
static char *reginput;		/* String-input pointer. */
static char *regbol;		/* Beginning of input, for ^ check. */
static char *regeol;		/* End of input, for $ check. */
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

extern int multiline;

/*
 - regexec - match a regexp against a string
 */
int
regexec(prog, stringarg, strend, strbeg, minend, screamer, safebase)
register regexp *prog;
char *stringarg;
register char *strend;	/* pointer to null at end of string */
char *strbeg;	/* real beginning of string */
int minend;	/* end of match must be at least minend after stringarg */
STR *screamer;
int safebase;	/* no need to remember string in subbase */
{
	register char *s;
	register int i;
	register char *c;
	register char *string = stringarg;
	register int tmp;
	int minlen = 0;		/* must match at least this many chars */
	int dontbother = 0;	/* how many characters not to try at end */
	int beginning = (string == strbeg);	/* is ^ valid at stringarg? */

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
		safebase = FALSE;
		i = strend - string;
		New(1101,c,i+1,char);
		(void)bcopy(string, c, i+1);
		string = c;
		strend = string + i;
		for (s = string; s < strend; s++)
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
#ifndef lint
		else
			s = fbminstr((unsigned char*)s, (unsigned char*)strend,
			    prog->regmust);
#endif
		if (!s) {
			++prog->regmust->str_u.str_useful;	/* hooray */
			goto phooey;	/* not present */
		}
		else if (prog->regback >= 0) {
			s -= prog->regback;
			if (s < string)
			    s = string;
			minlen = prog->regback + prog->regmust->str_cur;
		}
		else if (--prog->regmust->str_u.str_useful < 0) { /* boo */
			str_free(prog->regmust);
			prog->regmust = Nullstr;	/* disable regmust */
			s = string;
		}
		else {
			s = string;
			minlen = prog->regmust->str_cur;
		}
	}

	/* Mark beginning of line for ^ . */
	if (beginning)
		regbol = string;
	else
		regbol = NULL;

	/* Mark end of line for $ (and such) */
	regeol = strend;

	/* see how far we have to get to not match where we matched before */
	regtill = string+minend;

	/* Simplest case:  anchored match need be tried only once. */
	/*  [unless multiline is set] */
	if (prog->reganch) {
		if (regtry(prog, string))
			goto got_it;
		else if (multiline) {
			if (minlen)
			    dontbother = minlen - 1;
			strend -= dontbother;
			/* for multiline we only have to try after newlines */
			if (s > string)
			    s--;
			for (; s < strend; s++) {
			    if (*s == '\n') {
				if (++s < strend && regtry(prog, s))
				    goto got_it;
			    }
			}
		}
		goto phooey;
	}

	/* Messy cases:  unanchored match. */
	if (prog->regstart) {
		/* We know what string it must start with. */
		if (prog->regstart->str_pok == 3) {
#ifndef lint
		    while ((s = fbminstr((unsigned char*)s,
		      (unsigned char*)strend, prog->regstart)) != NULL)
#else
		    while (s = Nullch)
#endif
		    {
			    if (regtry(prog, s))
				    goto got_it;
			    s++;
		    }
		}
		else {
		    c = prog->regstart->str_ptr;
		    while ((s = ninstr(s, strend,
		      c, c + prog->regstart->str_cur )) != NULL) {
			    if (regtry(prog, s))
				    goto got_it;
			    s++;
		    }
		}
		goto phooey;
	}
	if (c = prog->regstclass) {
		if (minlen)
		    dontbother = minlen - 1;
		strend -= dontbother;	/* don't bother with what can't match */
		/* We know what class it must start with. */
		switch (OP(c)) {
		case ANYOF: case ANYBUT:
		    c = OPERAND(c);
		    while (s < strend) {
			    i = *s;
			    if (!(c[i >> 3] & (1 << (i&7))))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case BOUND:
		    if (minlen)
			dontbother++,strend--;
		    if (s != string) {
			i = s[-1];
			tmp = (isalpha(i) || isdigit(i) || i == '_');
		    }
		    else
			tmp = 0;	/* assume not alphanumeric */
		    while (s < strend) {
			    i = *s;
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
		    if (minlen)
			dontbother++,strend--;
		    if (s != string) {
			i = s[-1];
			tmp = (isalpha(i) || isdigit(i) || i == '_');
		    }
		    else
			tmp = 0;	/* assume not alphanumeric */
		    while (s < strend) {
			    i = *s;
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
		    while (s < strend) {
			    i = *s;
			    if (isalpha(i) || isdigit(i) || i == '_')
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case NALNUM:
		    while (s < strend) {
			    i = *s;
			    if (!isalpha(i) && !isdigit(i) && i != '_')
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case SPACE:
		    while (s < strend) {
			    if (isspace(*s))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case NSPACE:
		    while (s < strend) {
			    if (!isspace(*s))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case DIGIT:
		    while (s < strend) {
			    if (isdigit(*s))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		case NDIGIT:
		    while (s < strend) {
			    if (!isdigit(*s))
				    if (regtry(prog, s))
					    goto got_it;
			    s++;
		    }
		    break;
		}
	}
	else {
		dontbother = minend;
		strend -= dontbother;
		/* We don't know much -- general case. */
		do {
			if (regtry(prog, s))
				goto got_it;
		} while (s++ < strend);
	}

	/* Failure. */
	goto phooey;

    got_it:
	if ((!safebase && (prog->nparens || sawampersand)) || prog->do_folding){
		strend += dontbother;	/* uncheat */
		if (safebase)			/* no need for $digit later */
		    s = strbeg;
		else if (strbeg != prog->subbase) {
		    i = strend - string + (stringarg - strbeg);
		    s = nsavestr(strbeg,i);	/* so $digit will work later */
		    if (prog->subbase)
			    Safefree(prog->subbase);
		    prog->subbase = s;
		}
		else
		    s = prog->subbase;
		s += (stringarg - strbeg);
		for (i = 0; i <= prog->nparens; i++) {
			if (prog->endp[i]) {
			    prog->startp[i] = s + (prog->startp[i] - string);
			    prog->endp[i] = s + (prog->endp[i] - string);
			}
		}
		if (prog->do_folding)
			Safefree(string);
	}
	return(1);

    phooey:
	if (prog->do_folding)
		Safefree(string);
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
	prog->lastparen = 0;

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
	register int nextchar;
	register int n;		/* no or next */
	register int ln;        /* len or last */
	register char *s;	/* operand or save */
	register char *locinput = reginput;

	nextchar = *locinput;
	scan = prog;
#ifdef DEBUGGING
	if (scan != NULL && regnarrate)
		fprintf(stderr, "%s(\n", regprop(scan));
#endif
	while (scan != NULL) {
#ifdef DEBUGGING
		if (regnarrate)
			fprintf(stderr, "%s...\n", regprop(scan));
#endif

#ifdef REGALIGN
		next = scan + NEXT(scan);
		if (next == scan)
		    next = NULL;
#else
		next = regnext(scan);
#endif

		switch (OP(scan)) {
		case BOL:
			if (locinput == regbol ||
			    ((nextchar || locinput < regeol) &&
			      locinput[-1] == '\n') )
			{
				regtill--;
				break;
			}
			return(0);
		case EOL:
			if ((nextchar || locinput < regeol) && nextchar != '\n')
				return(0);
			regtill--;
			break;
		case ANY:
			if ((nextchar == '\0' && locinput >= regeol) ||
			  nextchar == '\n')
				return(0);
			nextchar = *++locinput;
			break;
		case EXACTLY:
			s = OPERAND(scan);
			ln = *s++;
			/* Inline the first character, for speed. */
			if (*s != nextchar)
				return(0);
			if (locinput + ln > regeol)
				return 0;
			if (ln > 1 && bcmp(s, locinput, ln) != 0)
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
			if (!nextchar && locinput > regeol)
				return 0;
			break;
		case ALNUM:
			if (!nextchar)
				return(0);
			if (!isalpha(nextchar) && !isdigit(nextchar) &&
			  nextchar != '_')
				return(0);
			nextchar = *++locinput;
			break;
		case NALNUM:
			if (!nextchar && locinput >= regeol)
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
			if (!nextchar && locinput >= regeol)
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
			if (!nextchar && locinput >= regeol)
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
			if (locinput + ln > regeol)
				return 0;
			if (ln > 1 && bcmp(s, locinput, ln) != 0)
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
						if (n > *reglastparen)
						    *reglastparen = n;
					}
					return(1);
				} else
					return(0);
			}
			/*NOTREACHED*/
		case BRANCH: {
				if (OP(next) != BRANCH)		/* No choice. */
					next = NEXTOPER(scan);	/* Avoid recursion. */
				else {
					do {
						reginput = locinput;
						if (regmatch(NEXTOPER(scan)))
							return(1);
#ifdef REGALIGN
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
				nextchar = -1000;
			ln = (OP(scan) == STAR) ? 0 : 1;
			reginput = locinput;
			n = regrepeat(NEXTOPER(scan));
			while (n >= ln) {
				/* If it could work, try it. */
				if (nextchar == -1000 || *reginput == nextchar)
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
#ifdef lint
	return 0;
#endif
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
	register char *loceol = regeol;

	scan = reginput;
	opnd = OPERAND(p);
	switch (OP(p)) {
	case ANY:
		while (scan < loceol && *scan != '\n')
			scan++;
		break;
	case EXACTLY:		/* length of string is 1 */
		opnd++;
		while (scan < loceol && *opnd == *scan)
			scan++;
		break;
	case ANYOF:
	case ANYBUT:
		c = UCHARAT(scan);
		while (scan < loceol && !(opnd[c >> 3] & (1 << (c & 7)))) {
			scan++;
			c = UCHARAT(scan);
		}
		break;
	case ALNUM:
		while (isalpha(*scan) || isdigit(*scan) || *scan == '_')
			scan++;
		break;
	case NALNUM:
		while (scan < loceol && (!isalpha(*scan) && !isdigit(*scan) &&
		  *scan != '_'))
			scan++;
		break;
	case SPACE:
		while (scan < loceol && isspace(*scan))
			scan++;
		break;
	case NSPACE:
		while (scan < loceol && !isspace(*scan))
			scan++;
		break;
	case DIGIT:
		while (isdigit(*scan))
			scan++;
		break;
	case NDIGIT:
		while (scan < loceol && !isdigit(*scan))
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
 * [Note, when REGALIGN is defined there are two places in regmatch()
 * that bypass this code for speed.]
 */
char *
regnext(p)
register char *p;
{
	register int offset;

	if (p == &regdummy)
		return(NULL);

	offset = NEXT(p);
	if (offset == 0)
		return(NULL);

#ifdef REGALIGN
	return(p+offset);
#else
	if (OP(p) == BACK)
		return(p-offset);
	else
		return(p+offset);
#endif
}
