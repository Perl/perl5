/*    regcomp.c
 */

/*
 * "A fair jaw-cracker dwarf-language must be."  --Samwise Gamgee
 */

/* NOTE: this is derived from Henry Spencer's regexp code, and should not
 * confused with the original package (see point 3 below).  Thanks, Henry!
 */

/* Additional note: this code is very heavily munged from Henry's version
 * in places.  In some spots I've traded clarity for efficiency, so don't
 * blame Henry for some of the lack of readability.
 */

/* The names of the functions have been changed from regcomp and
 * regexec to  pregcomp and pregexec in order to avoid conflicts
 * with the POSIX routines of the same names.
*/

/*SUPPRESS 112*/
/*
 * pregcomp and pregexec -- regsub and regerror are not used in perl
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
 ****    Copyright (c) 1991-1997, Larry Wall
 ****
 ****    You may distribute under the terms of either the GNU General Public
 ****    License or the Artistic License, as specified in the README file.

 *
 * Beware that some of this code is subtly aware of the way operator
 * precedence is structured in regular expressions.  Serious changes in
 * regular-expression syntax might require a total rethink.
 */
#include "EXTERN.h"
#include "perl.h"
#include "INTERN.h"

#define REG_COMP_C
#include "regcomp.h"

#ifdef op
#undef op
#endif /* op */

static regnode regdummy;
static char *  regparse;       /* Input-scan pointer. */
static char *  regxend;        /* End of input for compile */
static regnode *       regcode;        /* Code-emit pointer; &regdummy = don't. */
static I32             regnaughty;     /* How bad is this pattern? */
static I32             regsawback;     /* Did we see \1, ...? */

/* This guys appear both in regcomp.c and regexec.c, but there is no
   other reason to have them global. */
static char *  regprecomp;     /* uncompiled string. */
static I32		regnpar;	/* () count. */
static I32		regsize;	/* Code size. */
static U16		regflags;	/* are we folding, multilining? */

#ifdef MSDOS
# if defined(BUGGY_MSC6)
 /* MSC 6.00A breaks on op/regexp.t test 85 unless we turn this off */
 # pragma optimize("a",off)
 /* But MSC 6.00A is happy with 'w', for aliases only across function calls*/
 # pragma optimize("w",on )
# endif /* BUGGY_MSC6 */
#endif /* MSDOS */

#ifndef STATIC
#define	STATIC	static
#endif

#define	ISMULT1(c)	((c) == '*' || (c) == '+' || (c) == '?')
#define	ISMULT2(s)	((*s) == '*' || (*s) == '+' || (*s) == '?' || \
	((*s) == '{' && regcurly(s)))
#ifdef atarist
#define	PERL_META	"^$.[()|?+*\\"
#else
#define	META	"^$.[()|?+*\\"
#endif

#ifdef SPSTART
#undef SPSTART		/* dratted cpp namespace... */
#endif
/*
 * Flags to be passed up and down.
 */
#define	WORST		0	/* Worst case. */
#define	HASWIDTH	0x1	/* Known never to match null string. */
#define	SIMPLE		0x2	/* Simple enough to be STAR/PLUS operand. */
#define	SPSTART		0x4	/* Starts with * or +. */
#define TRYAGAIN	0x8	/* Weeded out a declaration. */

/*
 * Forward declarations for pregcomp()'s friends.
 */

static regnode *reg _((I32, I32 *));
static regnode *reganode _((U8, U32));
static regnode *regatom _((I32 *));
static regnode *regbranch _((I32 *, I32));
static void regc _((U8, char *));
static regnode *regclass _((void));
STATIC I32 regcurly _((char *));
static regnode *reg_node _((U8));
static regnode *regpiece _((I32 *));
static void reginsert _((U8, regnode *));
static void regoptail _((regnode *, regnode *));
static void regset _((char *, I32));
static void regtail _((regnode *, regnode *));
static char* regwhite _((char *, char *));
static char* nextchar _((void));

static U32 regseen;
static I32 seen_zerolen;
static regexp *rx;
static I32 extralen;

#ifdef DEBUGGING
static int colorset;
char *colors[4];
#endif 

/* Length of a variant. */

typedef struct {
    I32 len_min;
    I32 len_delta;
    I32 pos_min;
    I32 pos_delta;
    SV *last_found;
    I32 last_end;			/* min value, <0 unless valid. */
    I32 last_start_min;
    I32 last_start_max;
    SV **longest;			/* Either &l_fixed, or &l_float. */
    SV *longest_fixed;
    I32 offset_fixed;
    SV *longest_float;
    I32 offset_float_min;
    I32 offset_float_max;
    I32 flags;
} scan_data_t;

static scan_data_t zero_scan_data = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

#define SF_BEFORE_EOL		(SF_BEFORE_SEOL|SF_BEFORE_MEOL)
#define SF_BEFORE_SEOL		0x1
#define SF_BEFORE_MEOL		0x2
#define SF_FIX_BEFORE_EOL	(SF_FIX_BEFORE_SEOL|SF_FIX_BEFORE_MEOL)
#define SF_FL_BEFORE_EOL	(SF_FL_BEFORE_SEOL|SF_FL_BEFORE_MEOL)

#define SF_FIX_SHIFT_EOL	(+2)
#define SF_FL_SHIFT_EOL		(+4)

#define SF_FIX_BEFORE_SEOL	(SF_BEFORE_SEOL << SF_FIX_SHIFT_EOL)
#define SF_FIX_BEFORE_MEOL	(SF_BEFORE_MEOL << SF_FIX_SHIFT_EOL)

#define SF_FL_BEFORE_SEOL	(SF_BEFORE_SEOL << SF_FL_SHIFT_EOL)
#define SF_FL_BEFORE_MEOL	(SF_BEFORE_MEOL << SF_FL_SHIFT_EOL) /* 0x20 */
#define SF_IS_INF		0x40
#define SF_HAS_PAR		0x80
#define SF_IN_PAR		0x100
#define SF_HAS_EVAL		0x200
#define SCF_DO_SUBSTR		0x400

static void
scan_commit(scan_data_t *data)
{
    STRLEN l = SvCUR(data->last_found);
    STRLEN old_l = SvCUR(*data->longest);
    
    if ((l >= old_l) && ((l > old_l) || (data->flags & SF_BEFORE_EOL))) {
	sv_setsv(*data->longest, data->last_found);
	if (*data->longest == data->longest_fixed) {
	    data->offset_fixed = l ? data->last_start_min : data->pos_min;
	    if (data->flags & SF_BEFORE_EOL)
		data->flags 
		    |= ((data->flags & SF_BEFORE_EOL) << SF_FIX_SHIFT_EOL);
	    else
		data->flags &= ~SF_FIX_BEFORE_EOL;
	} else {
	    data->offset_float_min = l ? data->last_start_min : data->pos_min;
	    data->offset_float_max = (l 
				      ? data->last_start_max 
				      : data->pos_min + data->pos_delta);
	    if (data->flags & SF_BEFORE_EOL)
		data->flags 
		    |= ((data->flags & SF_BEFORE_EOL) << SF_FL_SHIFT_EOL);
	    else
		data->flags &= ~SF_FL_BEFORE_EOL;
	}
    }
    SvCUR_set(data->last_found, 0);
    data->last_end = -1;
    data->flags &= ~SF_BEFORE_EOL;
}

/* Stops at toplevel WHILEM as well as at `last'. At end *scanp is set
   to the position after last scanned or to NULL. */

static I32
study_chunk(regnode **scanp, I32 *deltap, regnode *last, scan_data_t *data, U32 flags)
			/* scanp: Start here (read-write). */
			/* deltap: Write maxlen-minlen here. */
			/* last: Stop before this one. */
{
    I32 min = 0, pars = 0, code;
    regnode *scan = *scanp, *next;
    I32 delta = 0;
    int is_inf = (flags & SCF_DO_SUBSTR) && (data->flags & SF_IS_INF);
    I32 is_par = OP(scan) == OPEN ? ARG(scan) : 0;
    scan_data_t data_fake;
    
    while (scan && OP(scan) != END && scan < last) {
	/* Peephole optimizer: */

	if (regkind[(U8)OP(scan)] == EXACT) {
	    regnode *n = regnext(scan);
	    U32 stringok = 1;
#ifdef DEBUGGING
	    regnode *stop = scan;
#endif 

	    next = scan + (*OPERAND(scan) + 2 - 1)/sizeof(regnode) + 2;
	    /* Skip NOTHING, merge EXACT*. */
	    while (n &&
		   ( regkind[(U8)OP(n)] == NOTHING || 
		     (stringok && (OP(n) == OP(scan))))
		   && NEXT_OFF(n)
		   && NEXT_OFF(scan) + NEXT_OFF(n) < I16_MAX) {
		if (OP(n) == TAIL || n > next)
		    stringok = 0;
		if (regkind[(U8)OP(n)] == NOTHING) {
		    NEXT_OFF(scan) += NEXT_OFF(n);
		    next = n + NODE_STEP_REGNODE;
#ifdef DEBUGGING
		    if (stringok)
			stop = n;
#endif 
		    n = regnext(n);
		} else {
		    int oldl = *OPERAND(scan);
		    regnode *nnext = regnext(n);
		    
		    if (oldl + *OPERAND(n) > U8_MAX) 
			break;
		    NEXT_OFF(scan) += NEXT_OFF(n);
		    *OPERAND(scan) += *OPERAND(n);
		    next = n + (*OPERAND(n) + 2 - 1)/sizeof(regnode) + 2;
		    /* Now we can overwrite *n : */
		    Move(OPERAND(n) + 1, OPERAND(scan) + oldl + 1,
			 *OPERAND(n) + 1, char);
#ifdef DEBUGGING
		    if (stringok)
			stop = next - 1;
#endif 
		    n = nnext;
		}
	    }
#ifdef DEBUGGING
	    /* Allow dumping */
	    n = scan + (*OPERAND(scan) + 2 - 1)/sizeof(regnode) + 2;
	    while (n <= stop) {
		if (regkind[(U8)OP(n)] != NOTHING || OP(n) == NOTHING) {
		    OP(n) = OPTIMIZED;
		    NEXT_OFF(n) = 0;
		}
		n++;
	    }
#endif 

	}
	if (OP(scan) != CURLYX) {
	    int max = (reg_off_by_arg[OP(scan)] ? I32_MAX : U16_MAX);
	    int off = (reg_off_by_arg[OP(scan)] ? ARG(scan) : NEXT_OFF(scan));
	    int noff;
	    regnode *n = scan;
	    
	    /* Skip NOTHING and LONGJMP. */
	    while ((n = regnext(n))
		   && ((regkind[(U8)OP(n)] == NOTHING && (noff = NEXT_OFF(n)))
		       || ((OP(n) == LONGJMP) && (noff = ARG(n))))
		   && off + noff < max)
		off += noff;
	    if (reg_off_by_arg[OP(scan)])
		ARG(scan) = off;
	    else 
		NEXT_OFF(scan) = off;
	}
	if (OP(scan) == BRANCH || OP(scan) == BRANCHJ 
		   || OP(scan) == IFTHEN || OP(scan) == SUSPEND) {
	    next = regnext(scan);
	    code = OP(scan);
	    
	    if (OP(next) == code || code == IFTHEN || code == SUSPEND) { 
		I32 max1 = 0, min1 = I32_MAX, num = 0;
		
		if (flags & SCF_DO_SUBSTR)
		    scan_commit(data);
		while (OP(scan) == code) {
		    I32 deltanext, minnext;

		    num++;
		    data_fake.flags = 0;
		    next = regnext(scan);
		    scan = NEXTOPER(scan);
		    if (code != BRANCH)
			scan = NEXTOPER(scan);
		    /* We suppose the run is continuous, last=next...*/
		    minnext = study_chunk(&scan, &deltanext, next,
					  &data_fake, 0);
		    if (min1 > minnext) 
			min1 = minnext;
		    if (max1 < minnext + deltanext)
			max1 = minnext + deltanext;
		    if (deltanext == I32_MAX)
			is_inf = 1;
		    scan = next;
		    if (data_fake.flags & (SF_HAS_PAR|SF_IN_PAR))
			pars++;
		    if (data && (data_fake.flags & SF_HAS_EVAL))
			data->flags |= SF_HAS_EVAL;
		    if (code == SUSPEND) 
			break;
		}
		if (code == IFTHEN && num < 2) /* Empty ELSE branch */
		    min1 = 0;
		if (flags & SCF_DO_SUBSTR) {
		    data->pos_min += min1;
		    data->pos_delta += max1 - min1;
		    if (max1 != min1 || is_inf)
			data->longest = &(data->longest_float);
		}
		min += min1;
		delta += max1 - min1;
	    } else if (code == BRANCHJ)	/* single branch is optimized. */
		scan = NEXTOPER(NEXTOPER(scan));
	    else			/* single branch is optimized. */
		scan = NEXTOPER(scan);
	    continue;
	} else if (OP(scan) == EXACT) {
	    min += *OPERAND(scan);
	    if (flags & SCF_DO_SUBSTR) { /* Update longest substr. */
		I32 l = *OPERAND(scan);

		/* The code below prefers earlier match for fixed
		   offset, later match for variable offset.  */
		if (data->last_end == -1) { /* Update the start info. */
		    data->last_start_min = data->pos_min;
 		    data->last_start_max = is_inf
 			? I32_MAX : data->pos_min + data->pos_delta; 
		}
		sv_catpvn(data->last_found, (char *)(OPERAND(scan)+1), l);
		data->last_end = data->pos_min + l;
		data->pos_min += l; /* As in the first entry. */
		data->flags &= ~SF_BEFORE_EOL;
	    }
	} else if (regkind[(U8)OP(scan)] == EXACT) {
	    if (flags & SCF_DO_SUBSTR) 
		scan_commit(data);
	    min += *OPERAND(scan);
	    if (data && (flags & SCF_DO_SUBSTR))
		data->pos_min += *OPERAND(scan);
	} else if (strchr(varies,OP(scan))) {
	    I32 mincount, maxcount, minnext, deltanext, pos_before, fl;
	    regnode *oscan = scan;
	    
	    switch (regkind[(U8)OP(scan)]) {
	    case WHILEM:
		scan = NEXTOPER(scan);
		goto finish;
	    case PLUS:
		if (flags & SCF_DO_SUBSTR) {
		    next = NEXTOPER(scan);
		    if (OP(next) == EXACT) {
			mincount = 1; 
			maxcount = REG_INFTY; 
			next = regnext(scan);
			scan = NEXTOPER(scan);
			goto do_curly;
		    }
		}
		if (flags & SCF_DO_SUBSTR)
		    data->pos_min++;
		min++;
		/* Fall through. */
	    case STAR:
		is_inf = 1; 
		scan = regnext(scan);
		if (flags & SCF_DO_SUBSTR) {
		    scan_commit(data);
		    data->longest = &(data->longest_float);
		}
		goto optimize_curly_tail;
	    case CURLY:
		mincount = ARG1(scan); 
		maxcount = ARG2(scan);
		next = regnext(scan);
		scan = NEXTOPER(scan) + EXTRA_STEP_2ARGS;
	      do_curly:
		if (flags & SCF_DO_SUBSTR) {
		    if (mincount == 0) scan_commit(data);
		    pos_before = data->pos_min;
		}
		if (data) {
		    fl = data->flags;
		    data->flags &= ~(SF_HAS_PAR|SF_IN_PAR|SF_HAS_EVAL);
		    if (is_inf)
			data->flags |= SF_IS_INF;
		}
		/* This will finish on WHILEM, setting scan, or on NULL: */
		minnext = study_chunk(&scan, &deltanext, last, data, 
				      mincount == 0 
					? (flags & ~SCF_DO_SUBSTR) : flags);
		if (!scan) 		/* It was not CURLYX, but CURLY. */
		    scan = next;
		if (dowarn && (minnext + deltanext == 0) 
		    && !(data->flags & (SF_HAS_PAR|SF_IN_PAR))) 
		    warn("Strange *+?{} on zero-length expression");
		min += minnext * mincount;
		is_inf |= (maxcount == REG_INFTY && (minnext + deltanext) > 0
			   || deltanext == I32_MAX);
		delta += (minnext + deltanext) * maxcount - minnext * mincount;

		/* Try powerful optimization CURLYX => CURLYN. */
#ifdef REGALIGN_STRUCT
		if (  OP(oscan) == CURLYX && data 
		      && data->flags & SF_IN_PAR
		      && !(data->flags & SF_HAS_EVAL)
		      && !deltanext && minnext == 1 ) {
		    /* Try to optimize to CURLYN.  */
		    regnode *nxt = NEXTOPER(oscan) + EXTRA_STEP_2ARGS;
		    regnode *nxt1 = nxt, *nxt2;

		    /* Skip open. */
		    nxt = regnext(nxt);
		    if (!strchr(simple,OP(nxt))
			&& !(regkind[(U8)OP(nxt)] == EXACT
			     && *OPERAND(nxt) == 1)) 
			goto nogo;
		    nxt2 = nxt;
		    nxt = regnext(nxt);
		    if (OP(nxt) != CLOSE) 
			goto nogo;
		    /* Now we know that nxt2 is the only contents: */
		    oscan->flags = ARG(nxt);
		    OP(oscan) = CURLYN;
		    OP(nxt1) = NOTHING;	/* was OPEN. */
#ifdef DEBUGGING
		    OP(nxt1 + 1) = OPTIMIZED; /* was count. */
		    NEXT_OFF(nxt1+ 1) = 0; /* just for consistancy. */
		    NEXT_OFF(nxt2) = 0;	/* just for consistancy with CURLY. */
		    OP(nxt) = OPTIMIZED;	/* was CLOSE. */
		    OP(nxt + 1) = OPTIMIZED; /* was count. */
		    NEXT_OFF(nxt+ 1) = 0; /* just for consistancy. */
#endif 
		}
#endif 
	      nogo:

		/* Try optimization CURLYX => CURLYM. */
		if (  OP(oscan) == CURLYX && data 
#ifdef REGALIGN_STRUCT
		      && !(data->flags & SF_HAS_PAR)
#else
		      && !(data->flags & (SF_HAS_PAR|SF_IN_PAR))
#endif 
		      && !(data->flags & SF_HAS_EVAL)
		      && !deltanext  ) {
		    /* XXXX How to optimize if data == 0? */
		    /* Optimize to a simpler form.  */
		    regnode *nxt = NEXTOPER(oscan) + EXTRA_STEP_2ARGS; /* OPEN */
		    regnode *nxt2;

		    OP(oscan) = CURLYM;
		    while ( (nxt2 = regnext(nxt)) /* skip over embedded stuff*/
			    && (OP(nxt2) != WHILEM)) 
			nxt = nxt2;
		    OP(nxt2)  = SUCCEED; /* Whas WHILEM */
#ifdef REGALIGN_STRUCT
		    /* Need to optimize away parenths. */
		    if (data->flags & SF_IN_PAR) {
			/* Set the parenth number.  */
			regnode *nxt1 = NEXTOPER(oscan) + EXTRA_STEP_2ARGS; /* OPEN*/

			if (OP(nxt) != CLOSE) 
			    FAIL("panic opt close");
			oscan->flags = ARG(nxt);
			OP(nxt1) = OPTIMIZED;	/* was OPEN. */
			OP(nxt) = OPTIMIZED;	/* was CLOSE. */
#ifdef DEBUGGING
			OP(nxt1 + 1) = OPTIMIZED; /* was count. */
			OP(nxt + 1) = OPTIMIZED; /* was count. */
			NEXT_OFF(nxt1 + 1) = 0; /* just for consistancy. */
			NEXT_OFF(nxt + 1) = 0; /* just for consistancy. */
#endif 
#if 0
			while ( nxt1 && (OP(nxt1) != WHILEM)) {
			    regnode *nnxt = regnext(nxt1);
			    
			    if (nnxt == nxt) {
				if (reg_off_by_arg[OP(nxt1)])
				    ARG_SET(nxt1, nxt2 - nxt1);
				else if (nxt2 - nxt1 < U16_MAX)
				    NEXT_OFF(nxt1) = nxt2 - nxt1;
				else
				    OP(nxt) = NOTHING;	/* Cannot beautify */
			    }
			    nxt1 = nnxt;
			}
#endif
			/* Optimize again: */
			study_chunk(&nxt1, &deltanext, nxt, NULL, 0);
		    } else
			oscan->flags = 0;
#endif 
		}
		if (data && fl & (SF_HAS_PAR|SF_IN_PAR)) 
		    pars++;
		if (flags & SCF_DO_SUBSTR) {
		    SV *last_str = Nullsv;
		    int counted = mincount != 0;

		    if (data->last_end > 0 && mincount != 0) { /* Ends with a string. */
			I32 b = pos_before >= data->last_start_min 
			    ? pos_before : data->last_start_min;
			STRLEN l;
			char *s = SvPV(data->last_found, l);
			
			l -= b - data->last_start_min;
			/* Get the added string: */
			last_str = newSVpv(s  +  b - data->last_start_min, l);
			if (deltanext == 0 && pos_before == b) {
			    /* What was added is a constant string */
			    if (mincount > 1) {
				SvGROW(last_str, (mincount * l) + 1);
				repeatcpy(SvPVX(last_str) + l, 
					  SvPVX(last_str), l, mincount - 1);
				SvCUR(last_str) *= mincount;
				/* Add additional parts. */
				SvCUR_set(data->last_found, 
					  SvCUR(data->last_found) - l);
				sv_catsv(data->last_found, last_str);
				data->last_end += l * (mincount - 1);
			    }
			}
		    }
		    /* It is counted once already... */
		    data->pos_min += minnext * (mincount - counted);
		    data->pos_delta += - counted * deltanext +
			(minnext + deltanext) * maxcount - minnext * mincount;
		    if (mincount != maxcount) {
			scan_commit(data);
			if (mincount && last_str) {
			    sv_setsv(data->last_found, last_str);
			    data->last_end = data->pos_min;
			    data->last_start_min = 
				data->pos_min - SvCUR(last_str);
			    data->last_start_max = is_inf 
				? I32_MAX 
				: data->pos_min + data->pos_delta
				- SvCUR(last_str);
			}
			data->longest = &(data->longest_float);
		    }
		}
		if (data && (fl & SF_HAS_EVAL))
		    data->flags |= SF_HAS_EVAL;
	      optimize_curly_tail:
#ifdef REGALIGN
		if (OP(oscan) != CURLYX) {
		    while (regkind[(U8)OP(next = regnext(oscan))] == NOTHING
			   && NEXT_OFF(next))
			NEXT_OFF(oscan) += NEXT_OFF(next);
		}
#endif
		continue;
	    default:			/* REF only? */
		if (flags & SCF_DO_SUBSTR) {
		    scan_commit(data);
		    data->longest = &(data->longest_float);
		}
		is_inf = 1;
		break;
	    }
	} else if (strchr(simple,OP(scan))) {
	    if (flags & SCF_DO_SUBSTR) {
		scan_commit(data);
		data->pos_min++;
	    }
	    min++;
	} else if (regkind[(U8)OP(scan)] == EOL && flags & SCF_DO_SUBSTR) {
	    data->flags |= (OP(scan) == MEOL
			    ? SF_BEFORE_MEOL
			    : SF_BEFORE_SEOL);
	} else if (regkind[(U8)OP(scan)] == BRANCHJ
		   && (scan->flags || data)
		   && (OP(scan) == IFMATCH || OP(scan) == UNLESSM)) {
	    I32 deltanext, minnext;
	    regnode *nscan;

	    data_fake.flags = 0;
	    next = regnext(scan);
	    nscan = NEXTOPER(NEXTOPER(scan));
	    minnext = study_chunk(&nscan, &deltanext, last, &data_fake, 0);
	    if (scan->flags) {
		if (deltanext) {
		    FAIL("variable length lookbehind not implemented");
		} else if (minnext > U8_MAX) {
		    FAIL2("lookbehind longer than %d not implemented", U8_MAX);
		}
		scan->flags = minnext;
	    }
	    if (data && data_fake.flags & (SF_HAS_PAR|SF_IN_PAR))
		pars++;
	    if (data && (data_fake.flags & SF_HAS_EVAL))
		data->flags |= SF_HAS_EVAL;
	} else if (OP(scan) == OPEN) {
	    pars++;
	} else if (OP(scan) == CLOSE && ARG(scan) == is_par) {
#ifdef REGALIGN_STRUCT
	    next = regnext(scan);

	    if ( next && (OP(next) != WHILEM) && next < last)
#endif 
		is_par = 0;		/* Disable optimization */
	} else if (OP(scan) == EVAL) {
		if (data)
		    data->flags |= SF_HAS_EVAL;
	}
	/* Else: zero-length, ignore. */
	scan = regnext(scan);
    }

  finish:
    *scanp = scan;
    *deltap = is_inf ? I32_MAX : delta;
    if (flags & SCF_DO_SUBSTR && is_inf) 
	data->pos_delta = I32_MAX - data->pos_min;
    if (is_par > U8_MAX)
	is_par = 0;
    if (is_par && pars==1 && data) {
	data->flags |= SF_IN_PAR;
	data->flags &= ~SF_HAS_PAR;
    } else if (pars && data) {
	data->flags |= SF_HAS_PAR;
	data->flags &= ~SF_IN_PAR;
    }
    return min;
}

static I32
add_data(I32 n, char *s)
{
    if (rx->data) {
	Renewc(rx->data, 
	       sizeof(*rx->data) + sizeof(void*) * (rx->data->count + n - 1), 
	       char, struct reg_data);
	Renew(rx->data->what, rx->data->count + n, U8);
	rx->data->count += n;
    } else {
	Newc(1207, rx->data, sizeof(*rx->data) + sizeof(void*) * (n - 1),
	     char, struct reg_data);
	New(1208, rx->data->what, n, U8);
	rx->data->count = n;
    }
    Copy(s, rx->data->what + rx->data->count - n, n, U8);
    return rx->data->count - n;
}

/*
 - pregcomp - compile a regular expression into internal code
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
pregcomp(char *exp, char *xend, PMOP *pm)
{
    register regexp *r;
    regnode *scan;
    SV **longest;
    SV *longest_fixed;
    SV *longest_float;
    regnode *first;
    I32 flags;
    I32 minlen = 0;
    I32 sawplus = 0;
    I32 sawopen = 0;

    if (exp == NULL)
	FAIL("NULL regexp argument");

    regprecomp = savepvn(exp, xend - exp);
    DEBUG_r(PerlIO_printf(Perl_debug_log, "compiling RE `%*s'\n",
			  xend - exp, regprecomp));
    regflags = pm->op_pmflags;
    regsawback = 0;

    regseen = 0;
    seen_zerolen = *exp == '^' ? -1 : 0;
    extralen = 0;

    /* First pass: determine size, legality. */
    regparse = exp;
    regxend = xend;
    regnaughty = 0;
    regnpar = 1;
    regsize = 0L;
    regcode = &regdummy;
    regc((U8)MAGIC, (char*)regcode);
    if (reg(0, &flags) == NULL) {
	Safefree(regprecomp);
	regprecomp = Nullch;
	return(NULL);
    }
    DEBUG_r(PerlIO_printf(Perl_debug_log, "size %d ", regsize));

    DEBUG_r(
	if (!colorset) {
	    int i = 0;
	    char *s = PerlEnv_getenv("TERMCAP_COLORS");
	    
	    colorset = 1;
	    if (s) {
		colors[0] = s = savepv(s);
		while (++i < 4) {
		    s = strchr(s, '\t');
		    if (!s) 
			FAIL("Not enough TABs in TERMCAP_COLORS");
		    *s = '\0';
		    colors[i] = ++s;
		}
	    } else {
		while (i < 4) 
		    colors[i++] = "";
	    }
	    /* Reset colors: */
	    PerlIO_printf(Perl_debug_log, "%s%s%s%s", 
			  colors[0],colors[1],colors[2],colors[3]);
	}
	);

    /* Small enough for pointer-storage convention?
       If extralen==0, this means that we will not need long jumps. */
#ifndef REGALIGN_STRUCT
    if (regsize >= 0x10000L && extralen)
	FAIL("regexp too big");
#else
    if (regsize >= 0x10000L && extralen)
        regsize += extralen;
    else
	extralen = 0;
#endif 

    /* Allocate space and initialize. */
    Newc(1001, r, sizeof(regexp) + (unsigned)regsize * sizeof(regnode),
	 char, regexp);
    if (r == NULL)
	FAIL("regexp out of space");
    r->refcnt = 1;
    r->prelen = xend - exp;
    r->precomp = regprecomp;
    r->subbeg = r->subbase = NULL;
    rx = r;

    /* Second pass: emit code. */
    regparse = exp;
    regxend = xend;
    regnaughty = 0;
    regnpar = 1;
    regcode = r->program;
    regc((U8)MAGIC, (char*) regcode++);
    r->data = 0;
    if (reg(0, &flags) == NULL)
	return(NULL);

    /* Dig out information for optimizations. */
    pm->op_pmflags = regflags;
    r->reganch = 0;
    r->regstclass = NULL;
    r->naughty = regnaughty >= 10;	/* Probably an expensive pattern. */
    scan = r->program + 1;		/* First BRANCH. */
    if (OP(scan) != BRANCH) {	/* Only one top-level choice. */
	scan_data_t data;
	I32 fake;
	STRLEN longest_float_length, longest_fixed_length;

	StructCopy(&zero_scan_data, &data, scan_data_t);
	first = scan;
	/* Skip introductions and multiplicators >= 1. */
	while ((OP(first) == OPEN && (sawopen = 1)) ||
	    (OP(first) == BRANCH && OP(regnext(first)) != BRANCH) ||
	    (OP(first) == PLUS) ||
	    (OP(first) == MINMOD) ||
	    (regkind[(U8)OP(first)] == CURLY && ARG1(first) > 0) ) {
		if (OP(first) == PLUS)
		    sawplus = 1;
		else
		    first += regarglen[(U8)OP(first)];
		first = NEXTOPER(first);
	}

	/* Starting-point info. */
      again:
	if (OP(first) == EXACT);	/* Empty, get anchored substr later. */
	else if (strchr(simple+2,OP(first)))
	    r->regstclass = first;
	else if (regkind[(U8)OP(first)] == BOUND ||
		 regkind[(U8)OP(first)] == NBOUND)
	    r->regstclass = first;
	else if (regkind[(U8)OP(first)] == BOL) {
	    r->reganch |= (OP(first) == MBOL ? ROPT_ANCH_MBOL: ROPT_ANCH_BOL);
	    first = NEXTOPER(first);
	    goto again;
	}
	else if (OP(first) == GPOS) {
	    r->reganch |= ROPT_ANCH_GPOS;
	    first = NEXTOPER(first);
	    goto again;
	}
	else if ((OP(first) == STAR &&
	    regkind[(U8)OP(NEXTOPER(first))] == ANY) &&
	    !(r->reganch & ROPT_ANCH) )
	{
	    /* turn .* into ^.* with an implied $*=1 */
	    r->reganch |= ROPT_ANCH_BOL | ROPT_IMPLICIT;
	    first = NEXTOPER(first);
	    goto again;
	}
	if (sawplus && (!sawopen || !regsawback))
	    r->reganch |= ROPT_SKIP;	/* x+ must match 1st of run */

	/* Scan is after the zeroth branch, first is atomic matcher. */
	DEBUG_r(PerlIO_printf(Perl_debug_log, "first at %d\n", 
			      first - scan + 1));
	/*
	* If there's something expensive in the r.e., find the
	* longest literal string that must appear and make it the
	* regmust.  Resolve ties in favor of later strings, since
	* the regstart check works with the beginning of the r.e.
	* and avoiding duplication strengthens checking.  Not a
	* strong reason, but sufficient in the absence of others.
	* [Now we resolve ties in favor of the earlier string if
	* it happens that c_offset_min has been invalidated, since the
	* earlier string may buy us something the later one won't.]
	*/
	minlen = 0;

	data.longest_fixed = newSVpv("",0);
	data.longest_float = newSVpv("",0);
	data.last_found = newSVpv("",0);
	data.longest = &(data.longest_fixed);
	first = scan;
	
	minlen = study_chunk(&first, &fake, scan + regsize, /* Up to end */
			     &data, SCF_DO_SUBSTR);
	if ( regnpar == 1 && data.longest == &(data.longest_fixed)
	     && data.last_start_min == 0 && data.last_end > 0 
	     && !seen_zerolen
	     && (!(regseen & REG_SEEN_GPOS) || (r->reganch & ROPT_ANCH_GPOS)))
	    r->reganch |= ROPT_CHECK_ALL;
	scan_commit(&data);
	SvREFCNT_dec(data.last_found);

	longest_float_length = SvCUR(data.longest_float);
	if (longest_float_length
	    || (data.flags & SF_FL_BEFORE_EOL
		&& (!(data.flags & SF_FL_BEFORE_MEOL)
		    || (regflags & PMf_MULTILINE)))) {
	    if (SvCUR(data.longest_fixed) 
		&& data.offset_fixed == data.offset_float_min)
		goto remove;		/* Like in (a)+. */
	    
	    r->float_substr = data.longest_float;
	    r->float_min_offset = data.offset_float_min;
	    r->float_max_offset = data.offset_float_max;
	    fbm_compile(r->float_substr);
	    BmUSEFUL(r->float_substr) = 100;
	    if (data.flags & SF_FL_BEFORE_EOL /* Cannot have SEOL and MULTI */
		&& (!(data.flags & SF_FL_BEFORE_MEOL)
		    || (regflags & PMf_MULTILINE))) 
		SvTAIL_on(r->float_substr);
	} else {
	  remove:
	    r->float_substr = Nullsv;
	    SvREFCNT_dec(data.longest_float);
	    longest_float_length = 0;
	}

	longest_fixed_length = SvCUR(data.longest_fixed);
	if (longest_fixed_length
	    || (data.flags & SF_FIX_BEFORE_EOL /* Cannot have SEOL and MULTI */
		&& (!(data.flags & SF_FIX_BEFORE_MEOL)
		    || (regflags & PMf_MULTILINE)))) {
	    r->anchored_substr = data.longest_fixed;
	    r->anchored_offset = data.offset_fixed;
	    fbm_compile(r->anchored_substr);
	    BmUSEFUL(r->anchored_substr) = 100;
	    if (data.flags & SF_FIX_BEFORE_EOL /* Cannot have SEOL and MULTI */
		&& (!(data.flags & SF_FIX_BEFORE_MEOL)
		    || (regflags & PMf_MULTILINE)))
		SvTAIL_on(r->anchored_substr);
	} else {
	    r->anchored_substr = Nullsv;
	    SvREFCNT_dec(data.longest_fixed);
	    longest_fixed_length = 0;
	}

	/* A temporary algorithm prefers floated substr to fixed one to dig more info. */
	if (longest_fixed_length > longest_float_length) {
	    r->check_substr = r->anchored_substr;
	    r->check_offset_min = r->check_offset_max = r->anchored_offset;
	    if (r->reganch & ROPT_ANCH_SINGLE)
		r->reganch |= ROPT_NOSCAN;
	} else {
	    r->check_substr = r->float_substr;
	    r->check_offset_min = data.offset_float_min;
	    r->check_offset_max = data.offset_float_max;
	}
    } else {
	/* Several toplevels. Best we can is to set minlen. */
	I32 fake;
	
	DEBUG_r(PerlIO_printf(Perl_debug_log, "\n"));
	scan = r->program + 1;
	minlen = study_chunk(&scan, &fake, scan + regsize, NULL, 0);
	r->check_substr = r->anchored_substr = r->float_substr = Nullsv;
    }

    r->nparens = regnpar - 1;
    r->minlen = minlen;
    if (regseen & REG_SEEN_GPOS) 
	r->reganch |= ROPT_GPOS_SEEN;
    if (regseen & REG_SEEN_LOOKBEHIND)
	r->reganch |= ROPT_LOOKBEHIND_SEEN;
    Newz(1002, r->startp, regnpar, char*);
    Newz(1002, r->endp, regnpar, char*);
    DEBUG_r(regdump(r));
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
static regnode *
reg(I32 paren, I32 *flagp)
    /* paren: Parenthesized? 0=top, 1=(, inside: changed to letter. */
{
    register regnode *ret;		/* Will be the head of the group. */
    register regnode *br;
    register regnode *lastbr;
    register regnode *ender = 0;
    register I32 parno = 0;
    I32 flags, oregflags = regflags, have_branch = 0, open = 0;
    char c;

    *flagp = HASWIDTH;	/* Tentatively. */

    /* Make an OPEN node, if parenthesized. */
    if (paren) {
	if (*regparse == '?') {
	    regparse++;
	    paren = *regparse++;
	    ret = NULL;			/* For look-ahead/behind. */
	    switch (paren) {
	    case '<':
#ifndef REGALIGN_STRUCT
		FAIL("lookbehind non-implemented without REGALIGN_STRUCT");
#endif 
		regseen |= REG_SEEN_LOOKBEHIND;
		if (*regparse == '!') 
		    paren = ',';
		if (*regparse != '=' && *regparse != '!') 
		    goto unknown;
		regparse++;
	    case '=':
	    case '!':
		seen_zerolen++;
	    case ':':
	    case '>':
		break;
	    case '$':
	    case '@':
		FAIL2("Sequence (?%c...) not implemented", (int)paren);
		break;
	    case '#':
		while (*regparse && *regparse != ')')
		    regparse++;
		if (*regparse != ')')
		    FAIL("Sequence (?#... not terminated");
		nextchar();
		*flagp = TRYAGAIN;
		return NULL;
	    case '{':
	    {
		dTHR;
		I32 count = 1, n = 0;
		char c;
		char *s = regparse;
		SV *sv;
		OP_4tree *sop, *rop;

		seen_zerolen++;
		while (count && (c = *regparse)) {
		    if (c == '\\' && regparse[1])
			regparse++;
		    else if (c == '{') 
			count++;
		    else if (c == '}') 
			count--;
		    regparse++;
		}
		if (*regparse != ')')
		    FAIL("Sequence (?{...}) not terminated or not {}-balanced");
		if (!SIZE_ONLY) {
		    AV *av;
		    
		    if (regparse - 1 - s) 
			sv = newSVpv(s, regparse - 1 - s);
		    else
			sv = newSVpv("", 0);

		    rop = sv_compile_2op(sv, &sop, "re", &av);

		    n = add_data(3, "nso");
		    rx->data->data[n] = (void*)rop;
		    rx->data->data[n+1] = (void*)av;
		    rx->data->data[n+2] = (void*)sop;
		    SvREFCNT_dec(sv);
		} else {		/* First pass */
		    if (tainted)
			FAIL("Eval-group in insecure regular expression");
		}
		
		nextchar();
		return reganode(EVAL, n);
	    }
	    case '(':
	    {
		if (regparse[0] == '?') {
		    if (regparse[1] == '=' || regparse[1] == '!' 
			|| regparse[1] == '<' 
			|| regparse[1] == '{') { /* Lookahead or eval. */
			I32 flag;
			
			ret = reg_node(LOGICAL);
			regtail(ret, reg(1, &flag));
			goto insert_if;
		    } 
		} else if (regparse[0] >= '1' && regparse[0] <= '9' ) {
		    parno = atoi(regparse++);

		    while (isDIGIT(*regparse))
			regparse++;
		    ret = reganode(GROUPP, parno);
		    if ((c = *nextchar()) != ')')
			FAIL2("Switch (?(number%c not recognized", c);
		  insert_if:
		    regtail(ret, reganode(IFTHEN, 0));
		    br = regbranch(&flags, 1);
		    if (br == NULL)
			br = reganode(LONGJMP, 0);
		    else
			regtail(br, reganode(LONGJMP, 0));
		    c = *nextchar();
		    if (c == '|') {
			lastbr = reganode(IFTHEN, 0); /* Fake one for optimizer. */
			regbranch(&flags, 1);
			regtail(ret, lastbr);
			c = *nextchar();
		    } else
			lastbr = NULL;
		    if (c != ')')
			FAIL("Switch (?(condition)... contains too many branches");
		    ender = reg_node(TAIL);
		    regtail(br, ender);
		    if (lastbr) {
			regtail(lastbr, ender);
			regtail(NEXTOPER(NEXTOPER(lastbr)), ender);
		    } else
			regtail(ret, ender);
		    return ret;
		} else {
		    FAIL2("Unknown condition for (?(%.2s", regparse);
		}
	    }
            case 0:
                FAIL("Sequence (? incomplete");
                break;
	    default:
		--regparse;
		while (*regparse && strchr("iogcmsx", *regparse))
		    pmflag(&regflags, *regparse++);
	      unknown:
		if (*regparse != ')')
		    FAIL2("Sequence (?%c...) not recognized", *regparse);
		nextchar();
		*flagp = TRYAGAIN;
		return NULL;
	    }
	}
	else {
	    parno = regnpar;
	    regnpar++;
	    ret = reganode(OPEN, parno);
	    open = 1;
	}
    } else
	ret = NULL;

    /* Pick up the branches, linking them together. */
    br = regbranch(&flags, 1);
    if (br == NULL)
	return(NULL);
    if (*regparse == '|') {
	if (!SIZE_ONLY && extralen) {
	    reginsert(BRANCHJ, br);
	} else
	    reginsert(BRANCH, br);
	have_branch = 1;
	if (SIZE_ONLY)
	    extralen += 1;		/* For BRANCHJ-BRANCH. */
    } else if (paren == ':') {
	*flagp |= flags&SIMPLE;
    }
    if (open) {				/* Starts with OPEN. */
	regtail(ret, br);		/* OPEN -> first. */
    } else if (paren != '?')		/* Not Conditional */
	ret = br;
    if (!(flags&HASWIDTH))
	*flagp &= ~HASWIDTH;
    *flagp |= flags&SPSTART;
    lastbr = br;
    while (*regparse == '|') {
	if (!SIZE_ONLY && extralen) {
	    ender = reganode(LONGJMP,0);
	    regtail(NEXTOPER(NEXTOPER(lastbr)), ender); /* Append to the previous. */
	}
	if (SIZE_ONLY)
	    extralen += 2;		/* Account for LONGJMP. */
	nextchar();
	br = regbranch(&flags, 0);
	if (br == NULL)
	    return(NULL);
	regtail(lastbr, br);		/* BRANCH -> BRANCH. */
	lastbr = br;
	if (!(flags&HASWIDTH))
	    *flagp &= ~HASWIDTH;
	*flagp |= flags&SPSTART;
    }

    if (have_branch || paren != ':') {
	/* Make a closing node, and hook it on the end. */
	switch (paren) {
	case ':':
	    ender = reg_node(TAIL);
	    break;
	case 1:
	    ender = reganode(CLOSE, parno);
	    break;
	case '<':
	case '>':
	case ',':
	case '=':
	case '!':
	    ender = reg_node(SUCCEED);
	    *flagp &= ~HASWIDTH;
	    break;
	case 0:
	    ender = reg_node(END);
	    break;
	}
	regtail(lastbr, ender);

	if (have_branch) {
	    /* Hook the tails of the branches to the closing node. */
	    for (br = ret; br != NULL; br = regnext(br)) {
		regoptail(br, ender);
	    }
	}
    }

    {
	char *p;
	static char parens[] = "=!<,>";

	if (paren && (p = strchr(parens, paren))) {
	    int node = ((p - parens) % 2) ? UNLESSM : IFMATCH;
	    int flag = (p - parens) > 1;

	    if (paren == '>')
		node = SUSPEND, flag = 0;
	    reginsert(node,ret);
#ifdef REGALIGN_STRUCT
	    ret->flags = flag;
#endif 
	    regtail(ret, reg_node(TAIL));
	}
    }

    /* Check for proper termination. */
    if (paren && (regparse >= regxend || *nextchar() != ')')) {
	FAIL("unmatched () in regexp");
    } else if (!paren && regparse < regxend) {
	if (*regparse == ')') {
	    FAIL("unmatched () in regexp");
	} else
	    FAIL("junk on end of regexp");	/* "Can't happen". */
	/* NOTREACHED */
    }
    if (paren != 0) {
	regflags = oregflags;
    }

    return(ret);
}

/*
 - regbranch - one alternative of an | operator
 *
 * Implements the concatenation operator.
 */
static regnode *
regbranch(I32 *flagp, I32 first)
{
    register regnode *ret;
    register regnode *chain = NULL;
    register regnode *latest;
    I32 flags = 0, c = 0;

    if (first) 
	ret = NULL;
    else {
	if (!SIZE_ONLY && extralen) 
	    ret = reganode(BRANCHJ,0);
	else
	    ret = reg_node(BRANCH);
    }
	
    if (!first && SIZE_ONLY) 
	extralen += 1;			/* BRANCHJ */
    
    *flagp = WORST;			/* Tentatively. */

    regparse--;
    nextchar();
    while (regparse < regxend && *regparse != '|' && *regparse != ')') {
	flags &= ~TRYAGAIN;
	latest = regpiece(&flags);
	if (latest == NULL) {
	    if (flags & TRYAGAIN)
		continue;
	    return(NULL);
	} else if (ret == NULL)
	    ret = latest;
	*flagp |= flags&HASWIDTH;
	if (chain == NULL) 	/* First piece. */
	    *flagp |= flags&SPSTART;
	else {
	    regnaughty++;
	    regtail(chain, latest);
	}
	chain = latest;
	c++;
    }
    if (chain == NULL) {	/* Loop ran zero times. */
	chain = reg_node(NOTHING);
	if (ret == NULL)
	    ret = chain;
    }
    if (c == 1) {
	*flagp |= flags&SIMPLE;
    }

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
static regnode *
regpiece(I32 *flagp)
{
    register regnode *ret;
    register char op;
    register char *next;
    I32 flags;
    char *origparse = regparse;
    char *maxpos;
    I32 min;
    I32 max = REG_INFTY;

    ret = regatom(&flags);
    if (ret == NULL) {
	if (flags & TRYAGAIN)
	    *flagp |= TRYAGAIN;
	return(NULL);
    }

    op = *regparse;

    if (op == '{' && regcurly(regparse)) {
	next = regparse + 1;
	maxpos = Nullch;
	while (isDIGIT(*next) || *next == ',') {
	    if (*next == ',') {
		if (maxpos)
		    break;
		else
		    maxpos = next;
	    }
	    next++;
	}
	if (*next == '}') {		/* got one */
	    if (!maxpos)
		maxpos = next;
	    regparse++;
	    min = atoi(regparse);
	    if (*maxpos == ',')
		maxpos++;
	    else
		maxpos = regparse;
	    max = atoi(maxpos);
	    if (!max && *maxpos != '0')
		max = REG_INFTY;		/* meaning "infinity" */
	    else if (max >= REG_INFTY)
		FAIL2("Quantifier in {,} bigger than %d", REG_INFTY - 1);
	    regparse = next;
	    nextchar();

	do_curly:
	    if ((flags&SIMPLE)) {
		regnaughty += 2 + regnaughty / 2;
		reginsert(CURLY, ret);
	    }
	    else {
		regnaughty += 4 + regnaughty;	/* compound interest */
		regtail(ret, reg_node(WHILEM));
		if (!SIZE_ONLY && extralen) {
		    reginsert(LONGJMP,ret);
		    reginsert(NOTHING,ret);
		    NEXT_OFF(ret) = 3;	/* Go over LONGJMP. */
		}
		reginsert(CURLYX,ret);
		if (!SIZE_ONLY && extralen)
		    NEXT_OFF(ret) = 3;	/* Go over NOTHING to LONGJMP. */
		regtail(ret, reg_node(NOTHING));
		if (SIZE_ONLY)
		    extralen += 3;
	    }
#ifdef REGALIGN_STRUCT
	    ret->flags = 0;
#endif 

	    if (min > 0)
		*flagp = (WORST|HASWIDTH);
	    if (max && max < min)
		FAIL("Can't do {n,m} with n > m");
	    if (!SIZE_ONLY) {
		ARG1_SET(ret, min);
		ARG2_SET(ret, max);
	    }

	    goto nest_check;
	}
    }

    if (!ISMULT1(op)) {
	*flagp = flags;
	return(ret);
    }

#if 0				/* Now runtime fix should be reliable. */
    if (!(flags&HASWIDTH) && op != '?')
      FAIL("regexp *+ operand could be empty");
#endif 

    nextchar();

    *flagp = (op != '+') ? (WORST|SPSTART) : (WORST|HASWIDTH);

    if (op == '*' && (flags&SIMPLE)) {
	reginsert(STAR, ret);
#ifdef REGALIGN_STRUCT
	ret->flags = 0;
#endif 
	regnaughty += 4;
    }
    else if (op == '*') {
	min = 0;
	goto do_curly;
    } else if (op == '+' && (flags&SIMPLE)) {
	reginsert(PLUS, ret);
#ifdef REGALIGN_STRUCT
	ret->flags = 0;
#endif 
	regnaughty += 3;
    }
    else if (op == '+') {
	min = 1;
	goto do_curly;
    } else if (op == '?') {
	min = 0; max = 1;
	goto do_curly;
    }
  nest_check:
    if (dowarn && !SIZE_ONLY && !(flags&HASWIDTH) && max > 10000) {
	warn("%.*s matches null string many times",
	    regparse - origparse, origparse);
    }

    if (*regparse == '?') {
	nextchar();
	reginsert(MINMOD, ret);
#ifdef REGALIGN
	regtail(ret, ret + NODE_STEP_REGNODE);
#else
	regtail(ret, ret + 3);
#endif
    }
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
static regnode *
regatom(I32 *flagp)
{
    register regnode *ret = 0;
    I32 flags;

    *flagp = WORST;		/* Tentatively. */

tryagain:
    switch (*regparse) {
    case '^':
	seen_zerolen++;
	nextchar();
	if (regflags & PMf_MULTILINE)
	    ret = reg_node(MBOL);
	else if (regflags & PMf_SINGLELINE)
	    ret = reg_node(SBOL);
	else
	    ret = reg_node(BOL);
	break;
    case '$':
	if (regparse[1]) 
	    seen_zerolen++;
	nextchar();
	if (regflags & PMf_MULTILINE)
	    ret = reg_node(MEOL);
	else if (regflags & PMf_SINGLELINE)
	    ret = reg_node(SEOL);
	else
	    ret = reg_node(EOL);
	break;
    case '.':
	nextchar();
	if (regflags & PMf_SINGLELINE)
	    ret = reg_node(SANY);
	else
	    ret = reg_node(ANY);
	regnaughty++;
	*flagp |= HASWIDTH|SIMPLE;
	break;
    case '[':
	regparse++;
	ret = regclass();
	*flagp |= HASWIDTH|SIMPLE;
	break;
    case '(':
	nextchar();
	ret = reg(1, &flags);
	if (ret == NULL) {
		if (flags & TRYAGAIN)
		    goto tryagain;
		return(NULL);
	}
	*flagp |= flags&(HASWIDTH|SPSTART|SIMPLE);
	break;
    case '|':
    case ')':
	if (flags & TRYAGAIN) {
	    *flagp |= TRYAGAIN;
	    return NULL;
	}
	FAIL2("internal urp in regexp at /%s/", regparse);
				/* Supposed to be caught earlier. */
	break;
    case '{':
	if (!regcurly(regparse)) {
	    regparse++;
	    goto defchar;
	}
	/* FALL THROUGH */
    case '?':
    case '+':
    case '*':
	FAIL("?+*{} follows nothing in regexp");
	break;
    case '\\':
	switch (*++regparse) {
	case 'A':
	    seen_zerolen++;
	    ret = reg_node(SBOL);
	    *flagp |= SIMPLE;
	    nextchar();
	    break;
	case 'G':
	    ret = reg_node(GPOS);
	    regseen |= REG_SEEN_GPOS;
	    *flagp |= SIMPLE;
	    nextchar();
	    break;
	case 'Z':
	    ret = reg_node(SEOL);
	    *flagp |= SIMPLE;
	    nextchar();
	    break;
	case 'w':
	    ret = reg_node((regflags & PMf_LOCALE) ? ALNUML : ALNUM);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar();
	    break;
	case 'W':
	    ret = reg_node((regflags & PMf_LOCALE) ? NALNUML : NALNUM);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar();
	    break;
	case 'b':
	    seen_zerolen++;
	    ret = reg_node((regflags & PMf_LOCALE) ? BOUNDL : BOUND);
	    *flagp |= SIMPLE;
	    nextchar();
	    break;
	case 'B':
	    seen_zerolen++;
	    ret = reg_node((regflags & PMf_LOCALE) ? NBOUNDL : NBOUND);
	    *flagp |= SIMPLE;
	    nextchar();
	    break;
	case 's':
	    ret = reg_node((regflags & PMf_LOCALE) ? SPACEL : SPACE);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar();
	    break;
	case 'S':
	    ret = reg_node((regflags & PMf_LOCALE) ? NSPACEL : NSPACE);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar();
	    break;
	case 'd':
	    ret = reg_node(DIGIT);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar();
	    break;
	case 'D':
	    ret = reg_node(NDIGIT);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar();
	    break;
	case 'n':
	case 'r':
	case 't':
	case 'f':
	case 'e':
	case 'a':
	case 'x':
	case 'c':
	case '0':
	    goto defchar;
	case '1': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	    {
		I32 num = atoi(regparse);

		if (num > 9 && num >= regnpar)
		    goto defchar;
		else {
		    regsawback = 1;
		    ret = reganode((regflags & PMf_FOLD)
				   ? ((regflags & PMf_LOCALE) ? REFFL : REFF)
				   : REF, num);
		    *flagp |= HASWIDTH;
		    while (isDIGIT(*regparse))
			regparse++;
		    regparse--;
		    nextchar();
		}
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

    case '#':
	if (regflags & PMf_EXTENDED) {
	    while (regparse < regxend && *regparse != '\n') regparse++;
	    if (regparse < regxend)
		goto tryagain;
	}
	/* FALL THROUGH */

    default: {
	    register I32 len;
	    register U8 ender;
	    register char *p;
	    char *oldp, *s;
	    I32 numlen;

	    regparse++;

	defchar:
	    ret = reg_node((regflags & PMf_FOLD)
			  ? ((regflags & PMf_LOCALE) ? EXACTFL : EXACTF)
			  : EXACT);
	    s = (char *) OPERAND(ret);
	    regc(0, s++);		/* save spot for len */
	    for (len = 0, p = regparse - 1;
	      len < 127 && p < regxend;
	      len++)
	    {
		oldp = p;

		if (regflags & PMf_EXTENDED)
		    p = regwhite(p, regxend);
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
		    case 'A':
		    case 'G':
		    case 'Z':
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
		    case 'e':
			ender = '\033';
			p++;
			break;
		    case 'a':
			ender = '\007';
			p++;
			break;
		    case 'x':
			ender = scan_hex(++p, 2, &numlen);
			p += numlen;
			break;
		    case 'c':
			p++;
			ender = UCHARAT(p++);
			ender = toCTRL(ender);
			break;
		    case '0': case '1': case '2': case '3':case '4':
		    case '5': case '6': case '7': case '8':case '9':
			if (*p == '0' ||
			  (isDIGIT(p[1]) && atoi(p) >= regnpar) ) {
			    ender = scan_oct(p, 3, &numlen);
			    p += numlen;
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
		if (regflags & PMf_EXTENDED)
		    p = regwhite(p, regxend);
		if (ISMULT2(p)) { /* Back off on ?+*. */
		    if (len)
			p = oldp;
		    else {
			len++;
			regc(ender, s++);
		    }
		    break;
		}
		regc(ender, s++);
	    }
	loopdone:
	    regparse = p - 1;
	    nextchar();
	    if (len < 0)
		FAIL("internal disaster in regexp");
	    if (len > 0)
		*flagp |= HASWIDTH;
	    if (len == 1)
		*flagp |= SIMPLE;
	    if (!SIZE_ONLY)
		*OPERAND(ret) = len;
	    regc('\0', s++);
	    if (SIZE_ONLY) {
#ifdef REGALIGN_STRUCT
		regsize += (len + 2 + sizeof(regnode) - 1) / sizeof(regnode);
#endif 
	    } else {
		regcode += (len + 2 + sizeof(regnode) - 1) / sizeof(regnode);
	    }
	}
	break;
    }

    return(ret);
}

static char *
regwhite(char *p, char *e)
{
    while (p < e) {
	if (isSPACE(*p))
	    ++p;
	else if (*p == '#') {
	    do {
		p++;
	    } while (p < e && *p != '\n');
	}
	else
	    break;
    }
    return p;
}

static void
regset(char *opnd, register I32 c)
{
    if (SIZE_ONLY)
	return;
    c &= 0xFF;
    opnd[1 + (c >> 3)] |= (1 << (c & 7));
}

static regnode *
regclass(void)
{
    register char *opnd, *s;
    register I32 Class;
    register I32 lastclass = 1234;
    register I32 range = 0;
    register regnode *ret;
    register I32 def;
    I32 numlen;

    s = opnd = (char *) OPERAND(regcode);
    ret = reg_node(ANYOF);
    for (Class = 0; Class < 33; Class++)
	regc(0, s++);
    if (*regparse == '^') {	/* Complement of range. */
	regnaughty++;
	regparse++;
	if (!SIZE_ONLY)
	    *opnd |= ANYOF_INVERT;
    }
    if (!SIZE_ONLY) {
 	regcode += ANY_SKIP;
	if (regflags & PMf_FOLD)
	    *opnd |= ANYOF_FOLD;
	if (regflags & PMf_LOCALE)
	    *opnd |= ANYOF_LOCALE;
    } else {
	regsize += ANY_SKIP;
    }
    if (*regparse == ']' || *regparse == '-')
	goto skipcond;		/* allow 1st char to be ] or - */
    while (regparse < regxend && *regparse != ']') {
       skipcond:
	Class = UCHARAT(regparse++);
	if (Class == '[' && regparse + 1 < regxend &&
	    /* I smell either [: or [= or [. -- POSIX has been here, right? */
	    (*regparse == ':' || *regparse == '=' || *regparse == '.')) {
	    char  posixccc = *regparse;
	    char* posixccs = regparse++;
	    
	    while (regparse < regxend && *regparse != posixccc)
		regparse++;
	    if (regparse == regxend)
		/* Grandfather lone [:, [=, [. */
		regparse = posixccs;
	    else {
		regparse++; /* skip over the posixccc */
		if (*regparse == ']') {
		    /* Not Implemented Yet.
		     * (POSIX Extended Character Classes, that is)
		     * The text between e.g. [: and :] would start
		     * at posixccs + 1 and stop at regparse - 2. */
		    if (dowarn && !SIZE_ONLY)
			warn("Character class syntax [%c %c] is reserved for future extensions", posixccc, posixccc);
		    regparse++; /* skip over the ending ] */
		}
	    }
	}
	if (Class == '\\') {
	    Class = UCHARAT(regparse++);
	    switch (Class) {
	    case 'w':
		if (regflags & PMf_LOCALE) {
		    if (!SIZE_ONLY)
			*opnd |= ANYOF_ALNUML;
		}
		else {
		    for (Class = 0; Class < 256; Class++)
			if (isALNUM(Class))
			    regset(opnd, Class);
		}
		lastclass = 1234;
		continue;
	    case 'W':
		if (regflags & PMf_LOCALE) {
		    if (!SIZE_ONLY)
			*opnd |= ANYOF_NALNUML;
		}
		else {
		    for (Class = 0; Class < 256; Class++)
			if (!isALNUM(Class))
			    regset(opnd, Class);
		}
		lastclass = 1234;
		continue;
	    case 's':
		if (regflags & PMf_LOCALE) {
		    if (!SIZE_ONLY)
			*opnd |= ANYOF_SPACEL;
		}
		else {
		    for (Class = 0; Class < 256; Class++)
			if (isSPACE(Class))
			    regset(opnd, Class);
		}
		lastclass = 1234;
		continue;
	    case 'S':
		if (regflags & PMf_LOCALE) {
		    if (!SIZE_ONLY)
			*opnd |= ANYOF_NSPACEL;
		}
		else {
		    for (Class = 0; Class < 256; Class++)
			if (!isSPACE(Class))
			    regset(opnd, Class);
		}
		lastclass = 1234;
		continue;
	    case 'd':
		for (Class = '0'; Class <= '9'; Class++)
		    regset(opnd, Class);
		lastclass = 1234;
		continue;
	    case 'D':
		for (Class = 0; Class < '0'; Class++)
		    regset(opnd, Class);
		for (Class = '9' + 1; Class < 256; Class++)
		    regset(opnd, Class);
		lastclass = 1234;
		continue;
	    case 'n':
		Class = '\n';
		break;
	    case 'r':
		Class = '\r';
		break;
	    case 't':
		Class = '\t';
		break;
	    case 'f':
		Class = '\f';
		break;
	    case 'b':
		Class = '\b';
		break;
	    case 'e':
		Class = '\033';
		break;
	    case 'a':
		Class = '\007';
		break;
	    case 'x':
		Class = scan_hex(regparse, 2, &numlen);
		regparse += numlen;
		break;
	    case 'c':
		Class = UCHARAT(regparse++);
		Class = toCTRL(Class);
		break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
		Class = scan_oct(--regparse, 3, &numlen);
		regparse += numlen;
		break;
	    }
	}
	if (range) {
	    if (lastclass > Class)
		FAIL("invalid [] range in regexp");
	    range = 0;
	}
	else {
	    lastclass = Class;
	    if (*regparse == '-' && regparse+1 < regxend &&
	      regparse[1] != ']') {
		regparse++;
		range = 1;
		continue;	/* do it next time */
	    }
	}
	for ( ; lastclass <= Class; lastclass++)
	    regset(opnd, lastclass);
	lastclass = Class;
    }
    if (*regparse != ']')
	FAIL("unmatched [] in regexp");
    nextchar();
    return ret;
}

static char*
nextchar(void)
{
    char* retval = regparse++;

    for (;;) {
	if (*regparse == '(' && regparse[1] == '?' &&
		regparse[2] == '#') {
	    while (*regparse && *regparse != ')')
		regparse++;
	    regparse++;
	    continue;
	}
	if (regflags & PMf_EXTENDED) {
	    if (isSPACE(*regparse)) {
		regparse++;
		continue;
	    }
	    else if (*regparse == '#') {
		while (*regparse && *regparse != '\n')
		    regparse++;
		regparse++;
		continue;
	    }
	}
	return retval;
    }
}

/*
- reg_node - emit a node
*/
static regnode *			/* Location. */
reg_node(U8 op)
{
    register regnode *ret;
    register regnode *ptr;

    ret = regcode;
    if (SIZE_ONLY) {
	SIZE_ALIGN(regsize);
#ifdef REGALIGN_STRUCT
	regsize += 1;
#else
	regsize += 3;
#endif 
	return(ret);
    }

    NODE_ALIGN_FILL(ret);
    ptr = ret;
    FILL_ADVANCE_NODE(ptr, op);
    regcode = ptr;

    return(ret);
}

/*
- reganode - emit a node with an argument
*/
static regnode *			/* Location. */
reganode(U8 op, U32 arg)
{
    register regnode *ret;
    register regnode *ptr;

    ret = regcode;
    if (SIZE_ONLY) {
	SIZE_ALIGN(regsize);
#ifdef REGALIGN
	regsize += 2;
#else
	regsize += 5;
#endif 
	return(ret);
    }

    NODE_ALIGN_FILL(ret);
    ptr = ret;
    FILL_ADVANCE_NODE_ARG(ptr, op, arg);
    regcode = ptr;

    return(ret);
}

/*
- regc - emit (if appropriate) a byte of code
*/
static void
regc(U8 b, char* s)
{
    if (!SIZE_ONLY)
	*s = b;
}

/*
- reginsert - insert an operator in front of already-emitted operand
*
* Means relocating the operand.
*/
static void
reginsert(U8 op, regnode *opnd)
{
    register regnode *src;
    register regnode *dst;
    register regnode *place;
    register int offset = regarglen[(U8)op];
    
/* (regkind[(U8)op] == CURLY ? EXTRA_STEP_2ARGS : 0); */

    if (SIZE_ONLY) {
	regsize += NODE_STEP_REGNODE + offset;
	return;
    }

    src = regcode;
    regcode += NODE_STEP_REGNODE + offset;
    dst = regcode;
    while (src > opnd)
	StructCopy(--src, --dst, regnode);

    place = opnd;		/* Op node, where operand used to be. */
    src = NEXTOPER(place);
    FILL_ADVANCE_NODE(place, op);
    Zero(src, offset, regnode);
#if defined(REGALIGN) && !defined(REGALIGN_STRUCT)
    src[offset + 1] = '\177';
#endif
}

/*
- regtail - set the next-pointer at the end of a node chain of p to val.
*/
static void
regtail(regnode *p, regnode *val)
{
    register regnode *scan;
    register regnode *temp;
    register I32 offset;

    if (SIZE_ONLY)
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
#  ifdef REGALIGN_STRUCT
    if (reg_off_by_arg[OP(scan)]) {
	ARG_SET(scan, val - scan);
    } else {
	NEXT_OFF(scan) = val - scan;
    }
#  else
    offset = val - scan;
#    ifndef lint
    *(short*)(scan+1) = offset;
#    endif
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
regoptail(regnode *p, regnode *val)
{
    /* "Operandless" and "op != BRANCH" are synonymous in practice. */
    if (p == NULL || SIZE_ONLY)
	return;
    if (regkind[(U8)OP(p)] == BRANCH) {
	regtail(NEXTOPER(p), val);
    } else if ( regkind[(U8)OP(p)] == BRANCHJ) {
	regtail(NEXTOPER(NEXTOPER(p)), val);
    } else
	return;
}

/*
 - regcurly - a little FSA that accepts {\d+,?\d*}
 */
STATIC I32
regcurly(register char *s)
{
    if (*s++ != '{')
	return FALSE;
    if (!isDIGIT(*s))
	return FALSE;
    while (isDIGIT(*s))
	s++;
    if (*s == ',')
	s++;
    while (isDIGIT(*s))
	s++;
    if (*s != '}')
	return FALSE;
    return TRUE;
}

#ifdef DEBUGGING

static regnode *
dumpuntil(regnode *start, regnode *node, regnode *last, SV* sv, I32 l)
{
    register char op = EXACT;	/* Arbitrary non-END op. */
    register regnode *next, *onode;

    while (op != END && (!last || node < last)) {
	/* While that wasn't END last time... */

	NODE_ALIGN(node);
	op = OP(node);
	if (op == CLOSE)
	    l--;	
	next = regnext(node);
	/* Where, what. */
	if (OP(node) == OPTIMIZED)
	    goto after_print;
	regprop(sv, node);
	PerlIO_printf(Perl_debug_log, "%4d%*s%s", node - start, 
		      2*l + 1, "", SvPVX(sv));
	if (next == NULL)		/* Next ptr. */
	    PerlIO_printf(Perl_debug_log, "(0)");
	else 
	    PerlIO_printf(Perl_debug_log, "(%d)", next - start);
	(void)PerlIO_putc(Perl_debug_log, '\n');
      after_print:
	if (regkind[(U8)op] == BRANCHJ) {
	    register regnode *nnode = (OP(next) == LONGJMP 
				       ? regnext(next) 
				       : next);
	    if (last && nnode > last)
		nnode = last;
	    node = dumpuntil(start, NEXTOPER(NEXTOPER(node)), nnode, sv, l + 1);
	} else if (regkind[(U8)op] == BRANCH) {
	    node = dumpuntil(start, NEXTOPER(node), next, sv, l + 1);
	} else if ( op == CURLY) {   /* `next' might be very big: optimizer */
	    node = dumpuntil(start, NEXTOPER(node) + EXTRA_STEP_2ARGS,
			     NEXTOPER(node) + EXTRA_STEP_2ARGS + 1, sv, l + 1);
	} else if (regkind[(U8)op] == CURLY && op != CURLYX) {
	    node = dumpuntil(start, NEXTOPER(node) + EXTRA_STEP_2ARGS,
			     next, sv, l + 1);
	} else if ( op == PLUS || op == STAR) {
	    node = dumpuntil(start, NEXTOPER(node), NEXTOPER(node) + 1, sv, l + 1);
	} else if (op == ANYOF) {
	    node = NEXTOPER(node);
	    node += ANY_SKIP;
	} else if (regkind[(U8)op] == EXACT) {
            /* Literal string, where present. */
	    node += ((*OPERAND(node)) + 2 + sizeof(regnode) - 1) / sizeof(regnode);
	    node = NEXTOPER(node);
	} else {
	    node = NEXTOPER(node);
	    node += regarglen[(U8)op];
	}
	if (op == CURLYX || op == OPEN)
	    l++;
	else if (op == WHILEM)
	    l--;
    }
    return node;
}

/*
 - regdump - dump a regexp onto Perl_debug_log in vaguely comprehensible form
 */
void
regdump(regexp *r)
{
    SV *sv = sv_newmortal();

    (void)dumpuntil(r->program, r->program + 1, NULL, sv, 0);

    /* Header fields of interest. */
    if (r->anchored_substr)
	PerlIO_printf(Perl_debug_log, "anchored `%s%s%s'%s at %d ", 
		      colors[0],
		      SvPVX(r->anchored_substr), 
		      colors[1],
		      SvTAIL(r->anchored_substr) ? "$" : "",
		      r->anchored_offset);
    if (r->float_substr)
	PerlIO_printf(Perl_debug_log, "floating `%s%s%s'%s at %d..%u ", 
		      colors[0],
		      SvPVX(r->float_substr), 
		      colors[1],
		      SvTAIL(r->float_substr) ? "$" : "",
		      r->float_min_offset, r->float_max_offset);
    if (r->check_substr)
	PerlIO_printf(Perl_debug_log, 
		      r->check_substr == r->float_substr 
		      ? "(checking floating" : "(checking anchored");
    if (r->reganch & ROPT_NOSCAN)
	PerlIO_printf(Perl_debug_log, " noscan");
    if (r->reganch & ROPT_CHECK_ALL)
	PerlIO_printf(Perl_debug_log, " isall");
    if (r->check_substr)
	PerlIO_printf(Perl_debug_log, ") ");

    if (r->regstclass) {
	regprop(sv, r->regstclass);
	PerlIO_printf(Perl_debug_log, "stclass `%s' ", SvPVX(sv));
    }
    if (r->reganch & ROPT_ANCH) {
	PerlIO_printf(Perl_debug_log, "anchored");
	if (r->reganch & ROPT_ANCH_BOL)
	    PerlIO_printf(Perl_debug_log, "(BOL)");
	if (r->reganch & ROPT_ANCH_MBOL)
	    PerlIO_printf(Perl_debug_log, "(MBOL)");
	if (r->reganch & ROPT_ANCH_GPOS)
	    PerlIO_printf(Perl_debug_log, "(GPOS)");
	PerlIO_putc(Perl_debug_log, ' ');
    }
    if (r->reganch & ROPT_GPOS_SEEN)
	PerlIO_printf(Perl_debug_log, "GPOS ");
    if (r->reganch & ROPT_SKIP)
	PerlIO_printf(Perl_debug_log, "plus ");
    if (r->reganch & ROPT_IMPLICIT)
	PerlIO_printf(Perl_debug_log, "implicit ");
    PerlIO_printf(Perl_debug_log, "minlen %ld ", (long) r->minlen);
    PerlIO_printf(Perl_debug_log, "\n");
}

/*
- regprop - printable representation of opcode
*/
void
regprop(SV *sv, regnode *o)
{
    register char *p = 0;

    sv_setpv(sv, ":");
    switch (OP(o)) {
    case BOL:
	p = "BOL";
	break;
    case MBOL:
	p = "MBOL";
	break;
    case SBOL:
	p = "SBOL";
	break;
    case EOL:
	p = "EOL";
	break;
    case MEOL:
	p = "MEOL";
	break;
    case SEOL:
	p = "SEOL";
	break;
    case ANY:
	p = "ANY";
	break;
    case SANY:
	p = "SANY";
	break;
    case ANYOF:
	p = "ANYOF";
	break;
    case BRANCH:
	p = "BRANCH";
	break;
    case EXACT:
	sv_catpvf(sv, "EXACT <%s%s%s>", colors[0], OPERAND(o) + 1, colors[1]);
	break;
    case EXACTF:
	sv_catpvf(sv, "EXACTF <%s%s%s>", colors[0], OPERAND(o) + 1, colors[1]);
	break;
    case EXACTFL:
	sv_catpvf(sv, "EXACTFL <%s%s%s>", colors[0], OPERAND(o) + 1, colors[1]);
	break;
    case NOTHING:
	p = "NOTHING";
	break;
    case TAIL:
	p = "TAIL";
	break;
    case BACK:
	p = "BACK";
	break;
    case END:
	p = "END";
	break;
    case BOUND:
	p = "BOUND";
	break;
    case BOUNDL:
	p = "BOUNDL";
	break;
    case NBOUND:
	p = "NBOUND";
	break;
    case NBOUNDL:
	p = "NBOUNDL";
	break;
    case CURLY:
	sv_catpvf(sv, "CURLY {%d,%d}", ARG1(o), ARG2(o));
	break;
    case CURLYM:
#ifdef REGALIGN_STRUCT
	sv_catpvf(sv, "CURLYM[%d] {%d,%d}", o->flags, ARG1(o), ARG2(o));
#else
	sv_catpvf(sv, "CURLYM {%d,%d}", ARG1(o), ARG2(o));
#endif 
	break;
    case CURLYN:
#ifdef REGALIGN_STRUCT
	sv_catpvf(sv, "CURLYN[%d] {%d,%d}", o->flags, ARG1(o), ARG2(o));
#else
	sv_catpvf(sv, "CURLYN {%d,%d}", ARG1(o), ARG2(o));
#endif 
	break;
    case CURLYX:
	sv_catpvf(sv, "CURLYX {%d,%d}", ARG1(o), ARG2(o));
	break;
    case REF:
	sv_catpvf(sv, "REF%d", ARG(o));
	break;
    case REFF:
	sv_catpvf(sv, "REFF%d", ARG(o));
	break;
    case REFFL:
	sv_catpvf(sv, "REFFL%d", ARG(o));
	break;
    case OPEN:
	sv_catpvf(sv, "OPEN%d", ARG(o));
	break;
    case CLOSE:
	sv_catpvf(sv, "CLOSE%d", ARG(o));
	p = NULL;
	break;
    case STAR:
	p = "STAR";
	break;
    case PLUS:
	p = "PLUS";
	break;
    case MINMOD:
	p = "MINMOD";
	break;
    case GPOS:
	p = "GPOS";
	break;
    case UNLESSM:
#ifdef REGALIGN_STRUCT
	sv_catpvf(sv, "UNLESSM[-%d]", o->flags);
#else
	p = "UNLESSM";
#endif 
	break;
    case IFMATCH:
#ifdef REGALIGN_STRUCT
	sv_catpvf(sv, "IFMATCH[-%d]", o->flags);
#else
	p = "IFMATCH";
#endif 
	break;
    case SUCCEED:
	p = "SUCCEED";
	break;
    case WHILEM:
	p = "WHILEM";
	break;
    case DIGIT:
	p = "DIGIT";
	break;
    case NDIGIT:
	p = "NDIGIT";
	break;
    case ALNUM:
	p = "ALNUM";
	break;
    case NALNUM:
	p = "NALNUM";
	break;
    case SPACE:
	p = "SPACE";
	break;
    case NSPACE:
	p = "NSPACE";
	break;
    case ALNUML:
	p = "ALNUML";
	break;
    case NALNUML:
	p = "NALNUML";
	break;
    case SPACEL:
	p = "SPACEL";
	break;
    case NSPACEL:
	p = "NSPACEL";
	break;
    case EVAL:
	p = "EVAL";
	break;
    case LONGJMP:
	p = "LONGJMP";
	break;
    case BRANCHJ:
	p = "BRANCHJ";
	break;
    case IFTHEN:
	p = "IFTHEN";
	break;
    case GROUPP:
	sv_catpvf(sv, "GROUPP%d", ARG(o));
	break;
    case LOGICAL:
	p = "LOGICAL";
	break;
    case SUSPEND:
	p = "SUSPEND";
	break;
    case RENUM:
	p = "RENUM";
	break;
    case OPTIMIZED:
	p = "OPTIMIZED";
	break;
    default:
	FAIL("corrupted regexp opcode");
    }
    if (p)
	sv_catpv(sv, p);
}
#endif /* DEBUGGING */

void
pregfree(struct regexp *r)
{
    if (!r || (--r->refcnt > 0))
	return;
    if (r->precomp)
	Safefree(r->precomp);
    if (r->subbase)
	Safefree(r->subbase);
    if (r->anchored_substr)
	SvREFCNT_dec(r->anchored_substr);
    if (r->float_substr)
	SvREFCNT_dec(r->float_substr);
    if (r->data) {
	int n = r->data->count;
	while (--n >= 0) {
	    switch (r->data->what[n]) {
	    case 's':
		SvREFCNT_dec((SV*)r->data->data[n]);
		break;
	    case 'o':
		op_free((OP_4tree*)r->data->data[n]);
		break;
	    case 'n':
		break;
	    default:
		FAIL2("panic: regfree data code '%c'", r->data->what[n]);
	    }
	}
	Safefree(r->data->what);
	Safefree(r->data);
    }
    Safefree(r->startp);
    Safefree(r->endp);
    Safefree(r);
}

/*
 - regnext - dig the "next" pointer out of a node
 *
 * [Note, when REGALIGN is defined there are two places in regmatch()
 * that bypass this code for speed.]
 */
regnode *
regnext(register regnode *p)
{
    register I32 offset;

    if (p == &regdummy)
	return(NULL);

    offset = (reg_off_by_arg[OP(p)] ? ARG(p) : NEXT_OFF(p));
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

#ifdef I_STDARG
void	
re_croak2(const char* pat1,const char* pat2,...)
#else
/*VARARGS0*/
void	
re_croak2(const char* pat1,const char* pat2, va_alist)
    const char* pat1;
    const char* pat2;
    va_dcl
#endif 
{
    va_list args;
    STRLEN l1 = strlen(pat1);
    STRLEN l2 = strlen(pat2);
    char buf[512];
    char *message;

    if (l1 > 510)
	l1 = 510;
    if (l1 + l2 > 510)
	l2 = 510 - l1;
    Copy(pat1, buf, l1 , char);
    Copy(pat2, buf + l1, l2 , char);
    buf[l1 + l2 + 1] = '\n';
    buf[l1 + l2 + 2] = '\0';
#ifdef I_STDARG
    va_start(args, pat2);
#else
    va_start(args);
#endif
    message = mess(buf, &args);
    va_end(args);
    l1 = strlen(message);
    if (l1 > 512)
	l1 = 512;
    Copy(message, buf, l1 , char);
    buf[l1] = '\0';			/* Overwrite \n */
    croak("%s", buf);
}
