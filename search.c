/* $Header: search.c,v 1.0 87/12/18 13:05:59 root Exp $
 *
 * $Log:	search.c,v $
 * Revision 1.0  87/12/18  13:05:59  root
 * Initial revision
 * 
 */

/* string search routines */
 
#include <stdio.h>
#include <ctype.h>

#include "EXTERN.h"
#include "handy.h"
#include "util.h"
#include "INTERN.h"
#include "search.h"

#define VERBOSE
#define FLUSH
#define MEM_SIZE int

#ifndef BITSPERBYTE
#define BITSPERBYTE 8
#endif

#define BMAPSIZ (127 / BITSPERBYTE + 1)

#define	CHAR	0		/*	a normal character */
#define	ANY	1		/* .	matches anything except newline */
#define	CCL	2		/* [..]	character class */
#define	NCCL	3		/* [^..]negated character class */
#define BEG	4		/* ^	beginning of a line */
#define	END	5		/* $	end of a line */
#define	LPAR	6		/* (	begin sub-match */
#define	RPAR	7		/* )	end sub-match */
#define	REF	8		/* \N	backreference to the Nth submatch */
#define WORD	9		/* \w	matches alphanumeric character */
#define NWORD	10		/* \W	matches non-alphanumeric character */
#define WBOUND	11		/* \b	matches word boundary */
#define NWBOUND	12		/* \B	matches non-boundary  */
#define	FINIS	13		/*	the end of the pattern */
 
#define CODEMASK 15

/* Quantifiers: */

#define MINZERO 16		/* minimum is 0, not 1 */
#define MAXINF	32		/* maximum is infinity, not 1 */
 
#define ASCSIZ 0200
typedef char	TRANSTABLE[ASCSIZ];

static	TRANSTABLE trans = {
0000,0001,0002,0003,0004,0005,0006,0007,
0010,0011,0012,0013,0014,0015,0016,0017,
0020,0021,0022,0023,0024,0025,0026,0027,
0030,0031,0032,0033,0034,0035,0036,0037,
0040,0041,0042,0043,0044,0045,0046,0047,
0050,0051,0052,0053,0054,0055,0056,0057,
0060,0061,0062,0063,0064,0065,0066,0067,
0070,0071,0072,0073,0074,0075,0076,0077,
0100,0101,0102,0103,0104,0105,0106,0107,
0110,0111,0112,0113,0114,0115,0116,0117,
0120,0121,0122,0123,0124,0125,0126,0127,
0130,0131,0132,0133,0134,0135,0136,0137,
0140,0141,0142,0143,0144,0145,0146,0147,
0150,0151,0152,0153,0154,0155,0156,0157,
0160,0161,0162,0163,0164,0165,0166,0167,
0170,0171,0172,0173,0174,0175,0176,0177,
};
static bool folding = FALSE;

static int err;
#define NOERR 0
#define BEGFAIL 1
#define FATAL 2

static char *FirstCharacter;
static char *matchend;
static char *matchtill;

void
search_init()
{
#ifdef UNDEF
    register int    i;
    
    for (i = 0; i < ASCSIZ; i++)
	trans[i] = i;
#else
    ;
#endif
}

void
init_compex(compex)
register COMPEX *compex;
{
    /* the following must start off zeroed */

    compex->precomp = Nullch;
    compex->complen = 0;
    compex->subbase = Nullch;
}

#ifdef NOTUSED
void
free_compex(compex)
register COMPEX *compex;
{
    if (compex->complen) {
	safefree(compex->compbuf);
	compex->complen = 0;
    }
    if (compex->subbase) {
	safefree(compex->subbase);
	compex->subbase = Nullch;
    }
}
#endif

static char *gbr_str = Nullch;
static int gbr_siz = 0;

char *
getparen(compex,n)
register COMPEX *compex;
int n;
{
    int length = compex->subend[n] - compex->subbeg[n];

    if (!n &&
	(!compex->numsubs || n > compex->numsubs || !compex->subend[n] || length<0))
	return "";
    growstr(&gbr_str, &gbr_siz, length+1);
    safecpy(gbr_str, compex->subbeg[n], length+1);
    return gbr_str;
}

void
case_fold(which)
int which;
{
    register int i;

    if (which != folding) {
	if (which) {
	    for (i = 'A'; i <= 'Z'; i++)
		trans[i] = tolower(i);
	}
	else {
	    for (i = 'A'; i <= 'Z'; i++)
		trans[i] = i;
	}
	folding = which;
    }
}

/* Compile the regular expression into internal form */

char *
compile(compex, sp, regex, fold)
register COMPEX *compex;
register char   *sp;
int regex;
int fold;
{
    register int c;
    register char  *cp;
    char   *lastcp;
    char    paren[MAXSUB],
	   *parenp;
    char **alt = compex->alternatives;
    char *retmes = "Badly formed search string";
 
    case_fold(compex->do_folding = fold);
    if (compex->precomp)
	safefree(compex->precomp);
    compex->precomp = savestr(sp);
    if (!compex->complen) {
	compex->compbuf = safemalloc(84);
	compex->complen = 80;
    }
    cp = compex->compbuf;		/* point at compiled buffer */
    *alt++ = cp;			/* first alternative starts here */
    parenp = paren;			/* first paren goes here */
    if (*sp == 0) {			/* nothing to compile? */
#ifdef NOTDEF
	if (*cp == 0)			/* nothing there yet? */
	    return "Null search string";
#endif
	if (*cp)
	    return Nullch;			/* just keep old expression */
    }
    compex->numsubs = 0;			/* no parens yet */
    lastcp = 0;
    for (;;) {
	if (cp - compex->compbuf >= compex->complen) {
	    char *ocompbuf = compex->compbuf;

	    grow_comp(compex);
	    if (ocompbuf != compex->compbuf) {	/* adjust pointers? */
		char **tmpalt;

		cp = compex->compbuf + (cp - ocompbuf);
		if (lastcp)
		    lastcp = compex->compbuf + (lastcp - ocompbuf);
		for (tmpalt = compex->alternatives; tmpalt < alt; tmpalt++)
		    if (*tmpalt)
			*tmpalt = compex->compbuf + (*tmpalt - ocompbuf);
	    }
	}
	c = *sp++;			/* get next char of pattern */
	if (c == 0) {			/* end of pattern? */
	    if (parenp != paren) {	/* balanced parentheses? */
#ifdef VERBOSE
		retmes = "Missing right parenthesis";
#endif
		goto badcomp;
	    }
	    *cp++ = FINIS;		/* append a stopper */
	    *alt++ = 0;			/* terminate alternative list */
	    /*
	    compex->complen = cp - compex->compbuf + 1;
	    compex->compbuf = saferealloc(compex->compbuf,compex->complen+4); */
	    return Nullch;		/* return success */
	}
	if (c != '*' && c != '?' && c != '+')
	    lastcp = cp;
	if (!regex) {			/* just a normal search string? */
	    *cp++ = CHAR;		/* everything is a normal char */
	    *cp++ = trans[c];
	}
	else				/* it is a regular expression */
	    switch (c) {
 
		default:
		  normal_char:
		    *cp++ = CHAR;
		    *cp++ = trans[c];
		    continue;

		case '.':
		    *cp++ = ANY;
		    continue;
 
		case '[': {		/* character class */
		    register int i;
		    
		    if (cp - compex->compbuf >= compex->complen - BMAPSIZ) {
			char *ocompbuf = compex->compbuf;

			grow_comp(compex);	/* reserve bitmap */
			if (ocompbuf != compex->compbuf) {/* adjust pointers? */
			    char **tmpalt;

			    cp = compex->compbuf + (cp - ocompbuf);
			    if (lastcp)
				lastcp = compex->compbuf + (lastcp - ocompbuf);
			    for (tmpalt = compex->alternatives; tmpalt < alt;
			      tmpalt++)
				if (*tmpalt)
				    *tmpalt =
					compex->compbuf + (*tmpalt - ocompbuf);
			}
		    }
		    for (i = BMAPSIZ; i; --i)
			cp[i] = 0;
		    
		    if ((c = *sp++) == '^') {
			c = *sp++;
			*cp++ = NCCL;	/* negated */
		    }
		    else
			*cp++ = CCL;	/* normal */
		    
		    i = 0;		/* remember oldchar */
		    do {
			if (c == '\0') {
#ifdef VERBOSE
			    retmes = "Missing ]";
#endif
			    goto badcomp;
			}
			if (c == '\\' && *sp) {
			    switch (*sp) {
			    default:
				c = *sp++;
				break;
			    case '0': case '1': case '2': case '3':
			    case '4': case '5': case '6': case '7':
				c = *sp++ - '0';
				if (index("01234567",*sp)) {
				    c <<= 3;
				    c += *sp++ - '0';
				}
				if (index("01234567",*sp)) {
				    c <<= 3;
				    c += *sp++ - '0';
				}
				break;
			    case 'b':
				c = '\b';
				sp++;
				break;
			    case 'n':
				c = '\n';
				sp++;
				break;
			    case 'r':
				c = '\r';
				sp++;
				break;
			    case 'f':
				c = '\f';
				sp++;
				break;
			    case 't':
				c = '\t';
				sp++;
				break;
			    }
			}
			if (*sp == '-' && *(++sp))
			    i = *sp++;
			else
			    i = c;
			while (c <= i) {
			    cp[c / BITSPERBYTE] |= 1 << (c % BITSPERBYTE);
			    if (fold && isalpha(c))
				cp[(c ^ 32) / BITSPERBYTE] |=
				    1 << ((c ^ 32) % BITSPERBYTE);
					/* set the other bit too */
			    c++;
			}
		    } while ((c = *sp++) != ']');
		    if (cp[-1] == NCCL)
			cp[0] |= 1;
		    cp += BMAPSIZ;
		    continue;
		}
 
		case '^':
		    if (cp != compex->compbuf && cp[-1] != FINIS)
			goto normal_char;
		    *cp++ = BEG;
		    continue;
 
		case '$':
		    if (isdigit(*sp)) {
			*cp++ = REF;
			*cp++ = *sp - '0';
			break;
		    }
		    if (*sp && *sp != '|')
			goto normal_char;
		    *cp++ = END;
		    continue;
 
		case '*': case '?': case '+':
		    if (lastcp == 0 ||
			(*lastcp & (MINZERO|MAXINF)) ||
			*lastcp == LPAR ||
			*lastcp == RPAR ||
			*lastcp == BEG ||
			*lastcp == END ||
			*lastcp == WBOUND ||
			*lastcp == NWBOUND )
			goto normal_char;
		    if (c != '+')
			*lastcp |= MINZERO;
		    if (c != '?')
			*lastcp |= MAXINF;
		    continue;
 
		case '(':
		    if (compex->numsubs >= MAXSUB) {
#ifdef VERBOSE
			retmes = "Too many parens";
#endif
			goto badcomp;
		    }
		    *parenp++ = ++compex->numsubs;
		    *cp++ = LPAR;
		    *cp++ = compex->numsubs;
		    break;
		case ')':
		    if (parenp <= paren) {
#ifdef VERBOSE
			retmes = "Unmatched right paren";
#endif
			goto badcomp;
		    }
		    *cp++ = RPAR;
		    *cp++ = *--parenp;
		    break;
		case '|':
		    if (parenp>paren) {
#ifdef VERBOSE
			retmes = "No | in subpattern";	/* Sigh! */
#endif
			goto badcomp;
		    }
		    *cp++ = FINIS;
		    if (alt - compex->alternatives >= MAXALT) {
#ifdef VERBOSE
			retmes = "Too many alternatives";
#endif
			goto badcomp;
		    }
		    *alt++ = cp;
		    break;
		case '\\':		/* backslashed thingie */
		    switch (c = *sp++) {
		    case '0': case '1': case '2': case '3': case '4':
		    case '5': case '6': case '7': case '8': case '9':
			*cp++ = REF;
			*cp++ = c - '0';
			break;
		    case 'w':
			*cp++ = WORD;
			break;
		    case 'W':
			*cp++ = NWORD;
			break;
		    case 'b':
			*cp++ = WBOUND;
			break;
		    case 'B':
			*cp++ = NWBOUND;
			break;
		    default:
			*cp++ = CHAR;
			if (c == '\0')
			    goto badcomp;
			switch (c) {
			case 'n':
			    c = '\n';
			    break;
			case 'r':
			    c = '\r';
			    break;
			case 'f':
			    c = '\f';
			    break;
			case 't':
			    c = '\t';
			    break;
			}
			*cp++ = c;
			break;
		    }
		    break;
	    }
    }
badcomp:
    compex->compbuf[0] = 0;
    compex->numsubs = 0;
    return retmes;
}

void
grow_comp(compex)
register COMPEX *compex;
{
    compex->complen += 80;
    compex->compbuf = saferealloc(compex->compbuf, (MEM_SIZE)compex->complen + 4);
}

char *
execute(compex, addr, beginning, minend)
register COMPEX *compex;
char *addr;
bool beginning;
int minend;
{
    register char *p1 = addr;
    register char *trt = trans;
    register int c;
    register int scr;
    register int c2;
 
    if (addr == Nullch)
	return Nullch;
    if (compex->numsubs) {			/* any submatches? */
	for (c = 0; c <= compex->numsubs; c++)
	    compex->subbeg[c] = compex->subend[c] = Nullch;
    }
    case_fold(compex->do_folding);	/* make sure table is correct */
    if (beginning)
	FirstCharacter = p1;		/* for ^ tests */
    else {
	if (multiline || compex->alternatives[1] || compex->compbuf[0] != BEG)
	    FirstCharacter = Nullch;
	else
	    return Nullch;		/* can't match */
    }
    matchend = Nullch;
    matchtill = addr + minend;
    err = 0;
    if (compex->compbuf[0] == CHAR && !compex->alternatives[1]) {
	if (compex->do_folding) {
	    c = compex->compbuf[1];	/* fast check for first character */
	    do {
		if (trt[*p1] == c && try(compex, p1, compex->compbuf))
		    goto got_it;
	    } while (*p1++ && !err);
	}
	else {
	    c = compex->compbuf[1];	/* faster check for first character */
	    if (compex->compbuf[2] == CHAR)
		c2 = compex->compbuf[3];
	    else
		c2 = 0;
	    do {
	      false_alarm:
		while (scr = *p1++, scr && scr != c) ;
		if (!scr)
		    break;
		if (c2 && *p1 != c2)	/* and maybe even second character */
		    goto false_alarm;
		if (try(compex, p1, compex->compbuf+2)) {
		    p1--;
		    goto got_it;
		}
	    } while (!err);
	}
	return Nullch;
    }
    else {			/* normal algorithm */
	do {
	    register char **alt = compex->alternatives;
	    while (*alt) {
		if (try(compex, p1, *alt++))
		    goto got_it;
	    }
	} while (*p1++ && err < FATAL);
	return Nullch;
    }

got_it:
    if (compex->numsubs) {			/* any parens? */
	trt = savestr(addr);		/* in case addr is not static */
	if (compex->subbase)
	    safefree(compex->subbase);	/* (may be freeing addr!) */
	compex->subbase = trt;
	scr = compex->subbase - addr;
	p1 += scr;
	matchend += scr;
	for (c = 0; c <= compex->numsubs; c++) {
	    if (compex->subend[c]) {
		compex->subbeg[c] += scr;
		compex->subend[c] += scr;
	    }
	}
    }
    compex->subend[0] = matchend;
    compex->subbeg[0] = p1;
    return p1;
}
 
bool
try(compex, sp, cp)
COMPEX *compex;
register char *cp;
register char *sp;
{
    register char *basesp;
    register char *trt = trans;
    register int i;
    register int backlen;
    register int code;
 
    while (*sp || (*cp & MAXINF) || *cp == BEG || *cp == RPAR ||
	*cp == WBOUND || *cp == NWBOUND) {
	switch ((code = *cp++) & CODEMASK) {
 
	    case CHAR:
		basesp = sp;
		i = *cp++;
		if (code & MAXINF)
		    while (*sp && trt[*sp] == i) sp++;
		else
		    if (*sp && trt[*sp] == i) sp++;
		backlen = 1;
		goto backoff;
 
	  backoff:
		while (sp > basesp) {
		    if (try(compex, sp, cp))
			goto right;
		    sp -= backlen;
		}
		if (code & MINZERO)
		    continue;
		goto wrong;
 
	    case ANY:
		basesp = sp;
		if (code & MAXINF)
		    while (*sp && *sp != '\n') sp++;
		else
		    if (*sp && *sp != '\n') sp++;
		backlen = 1;
		goto backoff;

	    case CCL:
		basesp = sp;
		if (code & MAXINF)
		    while (*sp && cclass(cp, *sp, 1)) sp++;
		else
		    if (*sp && cclass(cp, *sp, 1)) sp++;
		cp += BMAPSIZ;
		backlen = 1;
		goto backoff;
 
	    case NCCL:
		basesp = sp;
		if (code & MAXINF)
		    while (*sp && cclass(cp, *sp, 0)) sp++;
		else
		    if (*sp && cclass(cp, *sp, 0)) sp++;
		cp += BMAPSIZ;
		backlen = 1;
		goto backoff;
 
	    case END:
		if (!*sp || *sp == '\n') {
		    matchtill--;
		    continue;
		}
		goto wrong;
 
	    case BEG:
		if (sp == FirstCharacter || (
		    *sp && sp[-1] == '\n') ) {
		    matchtill--;
		    continue;
		}
		if (!multiline)		/* no point in advancing more */
		    err = BEGFAIL;
		goto wrong;
 
	    case WORD:
		basesp = sp;
		if (code & MAXINF)
		    while (*sp && isalnum(*sp)) sp++;
		else
		    if (*sp && isalnum(*sp)) sp++;
		backlen = 1;
		goto backoff;
 
	    case NWORD:
		basesp = sp;
		if (code & MAXINF)
		    while (*sp && !isalnum(*sp)) sp++;
		else
		    if (*sp && !isalnum(*sp)) sp++;
		backlen = 1;
		goto backoff;
 
	    case WBOUND:
		if ((sp == FirstCharacter || !isalnum(sp[-1])) !=
			(!*sp || !isalnum(*sp)) )
		    continue;
		goto wrong;
 
	    case NWBOUND:
		if ((sp == FirstCharacter || !isalnum(sp[-1])) ==
			(!*sp || !isalnum(*sp)))
		    continue;
		goto wrong;
 
	    case FINIS:
		goto right;
 
	    case LPAR:
		compex->subbeg[*cp++] = sp;
		continue;
 
	    case RPAR:
		i = *cp++;
		compex->subend[i] = sp;
		compex->lastparen = i;
		continue;
 
	    case REF:
		if (compex->subend[i = *cp++] == 0) {
		    fputs("Bad subpattern reference\n",stdout) FLUSH;
		    err = FATAL;
		    goto wrong;
		}
		basesp = sp;
		backlen = compex->subend[i] - compex->subbeg[i];
		if (code & MAXINF)
		    while (*sp && subpat(compex, i, sp)) sp += backlen;
		else
		    if (*sp && subpat(compex, i, sp)) sp += backlen;
		goto backoff;
 
	    default:
		fputs("Botched pattern compilation\n",stdout) FLUSH;
		err = FATAL;
		return -1;
	}
    }
    if (*cp == FINIS || *cp == END) {
right:
	if (matchend == Nullch || sp > matchend)
	    matchend = sp;
	return matchend >= matchtill;
    }
wrong:
    matchend = Nullch;
    return FALSE;
}
 
bool
subpat(compex, i, sp)
register COMPEX *compex;
register int i;
register char *sp;
{
    register char *bp;
 
    bp = compex->subbeg[i];
    while (*sp && *bp == *sp) {
	bp++;
	sp++;
	if (bp >= compex->subend[i])
	    return TRUE;
    }
    return FALSE;
}

bool
cclass(set, c, af)
register char  *set;
register int c;
{
    c &= 0177;
#if BITSPERBYTE == 8
    if (set[c >> 3] & 1 << (c & 7))
#else
    if (set[c / BITSPERBYTE] & 1 << (c % BITSPERBYTE))
#endif
	return af;
    return !af;
}
