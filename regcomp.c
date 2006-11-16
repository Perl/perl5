/*    regcomp.c
 */

/*
 * "A fair jaw-cracker dwarf-language must be."  --Samwise Gamgee
 */

/* This file contains functions for compiling a regular expression.  See
 * also regexec.c which funnily enough, contains functions for executing
 * a regular expression.
 *
 * This file is also copied at build time to ext/re/re_comp.c, where
 * it's built with -DPERL_EXT_RE_BUILD -DPERL_EXT_RE_DEBUG -DPERL_EXT.
 * This causes the main functions to be compiled under new names and with
 * debugging support added, which makes "use re 'debug'" work.
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

#ifdef PERL_EXT_RE_BUILD
#include "re_top.h"
#endif

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
 ****    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
 ****    2000, 2001, 2002, 2003, 2004, 2005, 2006, by Larry Wall and others
 ****
 ****    You may distribute under the terms of either the GNU General Public
 ****    License or the Artistic License, as specified in the README file.

 *
 * Beware that some of this code is subtly aware of the way operator
 * precedence is structured in regular expressions.  Serious changes in
 * regular-expression syntax might require a total rethink.
 */
#include "EXTERN.h"
#define PERL_IN_REGCOMP_C
#include "perl.h"

#ifndef PERL_IN_XSUB_RE
#  include "INTERN.h"
#endif

#define REG_COMP_C
#ifdef PERL_IN_XSUB_RE
#  include "re_comp.h"
#else
#  include "regcomp.h"
#endif

#ifdef op
#undef op
#endif /* op */

#ifdef MSDOS
#  if defined(BUGGY_MSC6)
 /* MSC 6.00A breaks on op/regexp.t test 85 unless we turn this off */
#    pragma optimize("a",off)
 /* But MSC 6.00A is happy with 'w', for aliases only across function calls*/
#    pragma optimize("w",on )
#  endif /* BUGGY_MSC6 */
#endif /* MSDOS */

#ifndef STATIC
#define	STATIC	static
#endif

typedef struct RExC_state_t {
    U32		flags;			/* are we folding, multilining? */
    char	*precomp;		/* uncompiled string. */
    regexp	*rx;
    char	*start;			/* Start of input for compile */
    char	*end;			/* End of input for compile */
    char	*parse;			/* Input-scan pointer. */
    I32		whilem_seen;		/* number of WHILEM in this expr */
    regnode	*emit_start;		/* Start of emitted-code area */
    regnode	*emit;			/* Code-emit pointer; &regdummy = don't = compiling */
    I32		naughty;		/* How bad is this pattern? */
    I32		sawback;		/* Did we see \1, ...? */
    U32		seen;
    I32		size;			/* Code size. */
    I32		npar;			/* Capture buffer count, (OPEN). */
    I32		cpar;			/* Capture buffer count, (CLOSE). */
    I32		nestroot;		/* root parens we are in - used by accept */
    I32		extralen;
    I32		seen_zerolen;
    I32		seen_evals;
    regnode	**open_parens;		/* pointers to open parens */
    regnode	**close_parens;		/* pointers to close parens */
    regnode	*opend;			/* END node in program */
    I32		utf8;
    HV		*charnames;		/* cache of named sequences */
    HV		*paren_names;		/* Paren names */
    regnode	**recurse;		/* Recurse regops */
    I32		recurse_count;		/* Number of recurse regops */
#if ADD_TO_REGEXEC
    char 	*starttry;		/* -Dr: where regtry was called. */
#define RExC_starttry	(pRExC_state->starttry)
#endif
#ifdef DEBUGGING
    const char  *lastparse;
    I32         lastnum;
#define RExC_lastparse	(pRExC_state->lastparse)
#define RExC_lastnum	(pRExC_state->lastnum)
#endif
} RExC_state_t;

#define RExC_flags	(pRExC_state->flags)
#define RExC_precomp	(pRExC_state->precomp)
#define RExC_rx		(pRExC_state->rx)
#define RExC_start	(pRExC_state->start)
#define RExC_end	(pRExC_state->end)
#define RExC_parse	(pRExC_state->parse)
#define RExC_whilem_seen	(pRExC_state->whilem_seen)
#define RExC_offsets	(pRExC_state->rx->offsets) /* I am not like the others */
#define RExC_emit	(pRExC_state->emit)
#define RExC_emit_start	(pRExC_state->emit_start)
#define RExC_naughty	(pRExC_state->naughty)
#define RExC_sawback	(pRExC_state->sawback)
#define RExC_seen	(pRExC_state->seen)
#define RExC_size	(pRExC_state->size)
#define RExC_npar	(pRExC_state->npar)
#define RExC_cpar	(pRExC_state->cpar)
#define RExC_nestroot   (pRExC_state->nestroot)
#define RExC_extralen	(pRExC_state->extralen)
#define RExC_seen_zerolen	(pRExC_state->seen_zerolen)
#define RExC_seen_evals	(pRExC_state->seen_evals)
#define RExC_utf8	(pRExC_state->utf8)
#define RExC_charnames  (pRExC_state->charnames)
#define RExC_open_parens	(pRExC_state->open_parens)
#define RExC_close_parens	(pRExC_state->close_parens)
#define RExC_opend	(pRExC_state->opend)
#define RExC_paren_names	(pRExC_state->paren_names)
#define RExC_recurse	(pRExC_state->recurse)
#define RExC_recurse_count	(pRExC_state->recurse_count)

#define	ISMULT1(c)	((c) == '*' || (c) == '+' || (c) == '?')
#define	ISMULT2(s)	((*s) == '*' || (*s) == '+' || (*s) == '?' || \
	((*s) == '{' && regcurly(s)))

#ifdef SPSTART
#undef SPSTART		/* dratted cpp namespace... */
#endif
/*
 * Flags to be passed up and down.
 */
#define	WORST		0	/* Worst case. */
#define	HASWIDTH	0x1	/* Known to match non-null strings. */
#define	SIMPLE		0x2	/* Simple enough to be STAR/PLUS operand. */
#define	SPSTART		0x4	/* Starts with * or +. */
#define TRYAGAIN	0x8	/* Weeded out a declaration. */

#define REG_NODE_NUM(x) ((x) ? (int)((x)-RExC_emit_start) : -1)

/* whether trie related optimizations are enabled */
#if PERL_ENABLE_EXTENDED_TRIE_OPTIMISATION
#define TRIE_STUDY_OPT
#define FULL_TRIE_STUDY
#define TRIE_STCLASS
#endif



#define PBYTE(u8str,paren) ((U8*)(u8str))[(paren) >> 3]
#define PBITVAL(paren) (1 << ((paren) & 7))
#define PAREN_TEST(u8str,paren) ( PBYTE(u8str,paren) & PBITVAL(paren))
#define PAREN_SET(u8str,paren) PBYTE(u8str,paren) |= PBITVAL(paren)
#define PAREN_UNSET(u8str,paren) PBYTE(u8str,paren) &= (~PBITVAL(paren))


/* About scan_data_t.

  During optimisation we recurse through the regexp program performing
  various inplace (keyhole style) optimisations. In addition study_chunk
  and scan_commit populate this data structure with information about
  what strings MUST appear in the pattern. We look for the longest 
  string that must appear for at a fixed location, and we look for the
  longest string that may appear at a floating location. So for instance
  in the pattern:
  
    /FOO[xX]A.*B[xX]BAR/
    
  Both 'FOO' and 'A' are fixed strings. Both 'B' and 'BAR' are floating
  strings (because they follow a .* construct). study_chunk will identify
  both FOO and BAR as being the longest fixed and floating strings respectively.
  
  The strings can be composites, for instance
  
     /(f)(o)(o)/
     
  will result in a composite fixed substring 'foo'.
  
  For each string some basic information is maintained:
  
  - offset or min_offset
    This is the position the string must appear at, or not before.
    It also implicitly (when combined with minlenp) tells us how many
    character must match before the string we are searching.
    Likewise when combined with minlenp and the length of the string
    tells us how many characters must appear after the string we have 
    found.
  
  - max_offset
    Only used for floating strings. This is the rightmost point that
    the string can appear at. Ifset to I32 max it indicates that the
    string can occur infinitely far to the right.
  
  - minlenp
    A pointer to the minimum length of the pattern that the string 
    was found inside. This is important as in the case of positive 
    lookahead or positive lookbehind we can have multiple patterns 
    involved. Consider
    
    /(?=FOO).*F/
    
    The minimum length of the pattern overall is 3, the minimum length
    of the lookahead part is 3, but the minimum length of the part that
    will actually match is 1. So 'FOO's minimum length is 3, but the 
    minimum length for the F is 1. This is important as the minimum length
    is used to determine offsets in front of and behind the string being 
    looked for.  Since strings can be composites this is the length of the
    pattern at the time it was commited with a scan_commit. Note that
    the length is calculated by study_chunk, so that the minimum lengths
    are not known until the full pattern has been compiled, thus the 
    pointer to the value.
  
  - lookbehind
  
    In the case of lookbehind the string being searched for can be
    offset past the start point of the final matching string. 
    If this value was just blithely removed from the min_offset it would
    invalidate some of the calculations for how many chars must match
    before or after (as they are derived from min_offset and minlen and
    the length of the string being searched for). 
    When the final pattern is compiled and the data is moved from the
    scan_data_t structure into the regexp structure the information
    about lookbehind is factored in, with the information that would 
    have been lost precalculated in the end_shift field for the 
    associated string.

  The fields pos_min and pos_delta are used to store the minimum offset
  and the delta to the maximum offset at the current point in the pattern.    

*/

typedef struct scan_data_t {
    /*I32 len_min;      unused */
    /*I32 len_delta;    unused */
    I32 pos_min;
    I32 pos_delta;
    SV *last_found;
    I32 last_end;	    /* min value, <0 unless valid. */
    I32 last_start_min;
    I32 last_start_max;
    SV **longest;	    /* Either &l_fixed, or &l_float. */
    SV *longest_fixed;      /* longest fixed string found in pattern */
    I32 offset_fixed;       /* offset where it starts */
    I32 *minlen_fixed;      /* pointer to the minlen relevent to the string */
    I32 lookbehind_fixed;   /* is the position of the string modfied by LB */
    SV *longest_float;      /* longest floating string found in pattern */
    I32 offset_float_min;   /* earliest point in string it can appear */
    I32 offset_float_max;   /* latest point in string it can appear */
    I32 *minlen_float;      /* pointer to the minlen relevent to the string */
    I32 lookbehind_float;   /* is the position of the string modified by LB */
    I32 flags;
    I32 whilem_c;
    I32 *last_closep;
    struct regnode_charclass_class *start_class;
} scan_data_t;

/*
 * Forward declarations for pregcomp()'s friends.
 */

static const scan_data_t zero_scan_data =
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0};

#define SF_BEFORE_EOL		(SF_BEFORE_SEOL|SF_BEFORE_MEOL)
#define SF_BEFORE_SEOL		0x0001
#define SF_BEFORE_MEOL		0x0002
#define SF_FIX_BEFORE_EOL	(SF_FIX_BEFORE_SEOL|SF_FIX_BEFORE_MEOL)
#define SF_FL_BEFORE_EOL	(SF_FL_BEFORE_SEOL|SF_FL_BEFORE_MEOL)

#ifdef NO_UNARY_PLUS
#  define SF_FIX_SHIFT_EOL	(0+2)
#  define SF_FL_SHIFT_EOL		(0+4)
#else
#  define SF_FIX_SHIFT_EOL	(+2)
#  define SF_FL_SHIFT_EOL		(+4)
#endif

#define SF_FIX_BEFORE_SEOL	(SF_BEFORE_SEOL << SF_FIX_SHIFT_EOL)
#define SF_FIX_BEFORE_MEOL	(SF_BEFORE_MEOL << SF_FIX_SHIFT_EOL)

#define SF_FL_BEFORE_SEOL	(SF_BEFORE_SEOL << SF_FL_SHIFT_EOL)
#define SF_FL_BEFORE_MEOL	(SF_BEFORE_MEOL << SF_FL_SHIFT_EOL) /* 0x20 */
#define SF_IS_INF		0x0040
#define SF_HAS_PAR		0x0080
#define SF_IN_PAR		0x0100
#define SF_HAS_EVAL		0x0200
#define SCF_DO_SUBSTR		0x0400
#define SCF_DO_STCLASS_AND	0x0800
#define SCF_DO_STCLASS_OR	0x1000
#define SCF_DO_STCLASS		(SCF_DO_STCLASS_AND|SCF_DO_STCLASS_OR)
#define SCF_WHILEM_VISITED_POS	0x2000

#define SCF_TRIE_RESTUDY        0x4000 /* Do restudy? */
#define SCF_SEEN_ACCEPT         0x8000 

#define UTF (RExC_utf8 != 0)
#define LOC ((RExC_flags & PMf_LOCALE) != 0)
#define FOLD ((RExC_flags & PMf_FOLD) != 0)

#define OOB_UNICODE		12345678
#define OOB_NAMEDCLASS		-1

#define CHR_SVLEN(sv) (UTF ? sv_len_utf8(sv) : SvCUR(sv))
#define CHR_DIST(a,b) (UTF ? utf8_distance(a,b) : a - b)


/* length of regex to show in messages that don't mark a position within */
#define RegexLengthToShowInErrorMessages 127

/*
 * If MARKER[12] are adjusted, be sure to adjust the constants at the top
 * of t/op/regmesg.t, the tests in t/op/re_tests, and those in
 * op/pragma/warn/regcomp.
 */
#define MARKER1 "<-- HERE"    /* marker as it appears in the description */
#define MARKER2 " <-- HERE "  /* marker as it appears within the regex */

#define REPORT_LOCATION " in regex; marked by " MARKER1 " in m/%.*s" MARKER2 "%s/"

/*
 * Calls SAVEDESTRUCTOR_X if needed, then calls Perl_croak with the given
 * arg. Show regex, up to a maximum length. If it's too long, chop and add
 * "...".
 */
#define	FAIL(msg) STMT_START {						\
    const char *ellipses = "";						\
    IV len = RExC_end - RExC_precomp;					\
									\
    if (!SIZE_ONLY)							\
	SAVEDESTRUCTOR_X(clear_re,(void*)RExC_rx);			\
    if (len > RegexLengthToShowInErrorMessages) {			\
	/* chop 10 shorter than the max, to ensure meaning of "..." */	\
	len = RegexLengthToShowInErrorMessages - 10;			\
	ellipses = "...";						\
    }									\
    Perl_croak(aTHX_ "%s in regex m/%.*s%s/",				\
	    msg, (int)len, RExC_precomp, ellipses);			\
} STMT_END

/*
 * Simple_vFAIL -- like FAIL, but marks the current location in the scan
 */
#define	Simple_vFAIL(m) STMT_START {					\
    const IV offset = RExC_parse - RExC_precomp;			\
    Perl_croak(aTHX_ "%s" REPORT_LOCATION,				\
	    m, (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

/*
 * Calls SAVEDESTRUCTOR_X if needed, then Simple_vFAIL()
 */
#define	vFAIL(m) STMT_START {				\
    if (!SIZE_ONLY)					\
	SAVEDESTRUCTOR_X(clear_re,(void*)RExC_rx);	\
    Simple_vFAIL(m);					\
} STMT_END

/*
 * Like Simple_vFAIL(), but accepts two arguments.
 */
#define	Simple_vFAIL2(m,a1) STMT_START {			\
    const IV offset = RExC_parse - RExC_precomp;			\
    S_re_croak2(aTHX_ m, REPORT_LOCATION, a1,			\
	    (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

/*
 * Calls SAVEDESTRUCTOR_X if needed, then Simple_vFAIL2().
 */
#define	vFAIL2(m,a1) STMT_START {			\
    if (!SIZE_ONLY)					\
	SAVEDESTRUCTOR_X(clear_re,(void*)RExC_rx);	\
    Simple_vFAIL2(m, a1);				\
} STMT_END


/*
 * Like Simple_vFAIL(), but accepts three arguments.
 */
#define	Simple_vFAIL3(m, a1, a2) STMT_START {			\
    const IV offset = RExC_parse - RExC_precomp;		\
    S_re_croak2(aTHX_ m, REPORT_LOCATION, a1, a2,		\
	    (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

/*
 * Calls SAVEDESTRUCTOR_X if needed, then Simple_vFAIL3().
 */
#define	vFAIL3(m,a1,a2) STMT_START {			\
    if (!SIZE_ONLY)					\
	SAVEDESTRUCTOR_X(clear_re,(void*)RExC_rx);	\
    Simple_vFAIL3(m, a1, a2);				\
} STMT_END

/*
 * Like Simple_vFAIL(), but accepts four arguments.
 */
#define	Simple_vFAIL4(m, a1, a2, a3) STMT_START {		\
    const IV offset = RExC_parse - RExC_precomp;		\
    S_re_croak2(aTHX_ m, REPORT_LOCATION, a1, a2, a3,		\
	    (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

#define	vWARN(loc,m) STMT_START {					\
    const IV offset = loc - RExC_precomp;				\
    Perl_warner(aTHX_ packWARN(WARN_REGEXP), "%s" REPORT_LOCATION,	\
	    m, (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

#define	vWARNdep(loc,m) STMT_START {					\
    const IV offset = loc - RExC_precomp;				\
    Perl_warner(aTHX_ packWARN2(WARN_DEPRECATED, WARN_REGEXP),		\
	    "%s" REPORT_LOCATION,					\
	    m, (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END


#define	vWARN2(loc, m, a1) STMT_START {					\
    const IV offset = loc - RExC_precomp;				\
    Perl_warner(aTHX_ packWARN(WARN_REGEXP), m REPORT_LOCATION,		\
	    a1, (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

#define	vWARN3(loc, m, a1, a2) STMT_START {				\
    const IV offset = loc - RExC_precomp;				\
    Perl_warner(aTHX_ packWARN(WARN_REGEXP), m REPORT_LOCATION,		\
	    a1, a2, (int)offset, RExC_precomp, RExC_precomp + offset);	\
} STMT_END

#define	vWARN4(loc, m, a1, a2, a3) STMT_START {				\
    const IV offset = loc - RExC_precomp;				\
    Perl_warner(aTHX_ packWARN(WARN_REGEXP), m REPORT_LOCATION,		\
	    a1, a2, a3, (int)offset, RExC_precomp, RExC_precomp + offset); \
} STMT_END

#define	vWARN5(loc, m, a1, a2, a3, a4) STMT_START {			\
    const IV offset = loc - RExC_precomp;				\
    Perl_warner(aTHX_ packWARN(WARN_REGEXP), m REPORT_LOCATION,		\
	    a1, a2, a3, a4, (int)offset, RExC_precomp, RExC_precomp + offset); \
} STMT_END


/* Allow for side effects in s */
#define REGC(c,s) STMT_START {			\
    if (!SIZE_ONLY) *(s) = (c); else (void)(s);	\
} STMT_END

/* Macros for recording node offsets.   20001227 mjd@plover.com 
 * Nodes are numbered 1, 2, 3, 4.  Node #n's position is recorded in
 * element 2*n-1 of the array.  Element #2n holds the byte length node #n.
 * Element 0 holds the number n.
 * Position is 1 indexed.
 */

#define Set_Node_Offset_To_R(node,byte) STMT_START {			\
    if (! SIZE_ONLY) {							\
	MJD_OFFSET_DEBUG(("** (%d) offset of node %d is %d.\n",		\
		    __LINE__, (int)(node), (int)(byte)));		\
	if((node) < 0) {						\
	    Perl_croak(aTHX_ "value of node is %d in Offset macro", (int)(node)); \
	} else {							\
	    RExC_offsets[2*(node)-1] = (byte);				\
	}								\
    }									\
} STMT_END

#define Set_Node_Offset(node,byte) \
    Set_Node_Offset_To_R((node)-RExC_emit_start, (byte)-RExC_start)
#define Set_Cur_Node_Offset Set_Node_Offset(RExC_emit, RExC_parse)

#define Set_Node_Length_To_R(node,len) STMT_START {			\
    if (! SIZE_ONLY) {							\
	MJD_OFFSET_DEBUG(("** (%d) size of node %d is %d.\n",		\
		__LINE__, (int)(node), (int)(len)));			\
	if((node) < 0) {						\
	    Perl_croak(aTHX_ "value of node is %d in Length macro", (int)(node)); \
	} else {							\
	    RExC_offsets[2*(node)] = (len);				\
	}								\
    }									\
} STMT_END

#define Set_Node_Length(node,len) \
    Set_Node_Length_To_R((node)-RExC_emit_start, len)
#define Set_Cur_Node_Length(len) Set_Node_Length(RExC_emit, len)
#define Set_Node_Cur_Length(node) \
    Set_Node_Length(node, RExC_parse - parse_start)

/* Get offsets and lengths */
#define Node_Offset(n) (RExC_offsets[2*((n)-RExC_emit_start)-1])
#define Node_Length(n) (RExC_offsets[2*((n)-RExC_emit_start)])

#define Set_Node_Offset_Length(node,offset,len) STMT_START {	\
    Set_Node_Offset_To_R((node)-RExC_emit_start, (offset));	\
    Set_Node_Length_To_R((node)-RExC_emit_start, (len));	\
} STMT_END


#if PERL_ENABLE_EXPERIMENTAL_REGEX_OPTIMISATIONS
#define EXPERIMENTAL_INPLACESCAN
#endif

#define DEBUG_STUDYDATA(data,depth)                                  \
DEBUG_OPTIMISE_MORE_r(if(data){                                           \
    PerlIO_printf(Perl_debug_log,                                    \
        "%*s"/* Len:%"IVdf"/%"IVdf" */"Pos:%"IVdf"/%"IVdf           \
        " Flags: %"IVdf" Whilem_c: %"IVdf" Lcp: %"IVdf" ",           \
        (int)(depth)*2, "",                                          \
        (IV)((data)->pos_min),                                       \
        (IV)((data)->pos_delta),                                     \
        (IV)((data)->flags),                                         \
        (IV)((data)->whilem_c),                                      \
        (IV)((data)->last_closep ? *((data)->last_closep) : -1)      \
    );                                                               \
    if ((data)->last_found)                                          \
        PerlIO_printf(Perl_debug_log,                                \
            "Last:'%s' %"IVdf":%"IVdf"/%"IVdf" %sFixed:'%s' @ %"IVdf \
            " %sFloat: '%s' @ %"IVdf"/%"IVdf"",                      \
            SvPVX_const((data)->last_found),                         \
            (IV)((data)->last_end),                                  \
            (IV)((data)->last_start_min),                            \
            (IV)((data)->last_start_max),                            \
            ((data)->longest &&                                      \
             (data)->longest==&((data)->longest_fixed)) ? "*" : "",  \
            SvPVX_const((data)->longest_fixed),                      \
            (IV)((data)->offset_fixed),                              \
            ((data)->longest &&                                      \
             (data)->longest==&((data)->longest_float)) ? "*" : "",  \
            SvPVX_const((data)->longest_float),                      \
            (IV)((data)->offset_float_min),                          \
            (IV)((data)->offset_float_max)                           \
        );                                                           \
    PerlIO_printf(Perl_debug_log,"\n");                              \
});

static void clear_re(pTHX_ void *r);

/* Mark that we cannot extend a found fixed substring at this point.
   Update the longest found anchored substring and the longest found
   floating substrings if needed. */

STATIC void
S_scan_commit(pTHX_ const RExC_state_t *pRExC_state, scan_data_t *data, I32 *minlenp)
{
    const STRLEN l = CHR_SVLEN(data->last_found);
    const STRLEN old_l = CHR_SVLEN(*data->longest);
    GET_RE_DEBUG_FLAGS_DECL;

    if ((l >= old_l) && ((l > old_l) || (data->flags & SF_BEFORE_EOL))) {
	SvSetMagicSV(*data->longest, data->last_found);
	if (*data->longest == data->longest_fixed) {
	    data->offset_fixed = l ? data->last_start_min : data->pos_min;
	    if (data->flags & SF_BEFORE_EOL)
		data->flags
		    |= ((data->flags & SF_BEFORE_EOL) << SF_FIX_SHIFT_EOL);
	    else
		data->flags &= ~SF_FIX_BEFORE_EOL;
	    data->minlen_fixed=minlenp;	
	    data->lookbehind_fixed=0;
	}
	else {
	    data->offset_float_min = l ? data->last_start_min : data->pos_min;
	    data->offset_float_max = (l
				      ? data->last_start_max
				      : data->pos_min + data->pos_delta);
	    if ((U32)data->offset_float_max > (U32)I32_MAX)
		data->offset_float_max = I32_MAX;
	    if (data->flags & SF_BEFORE_EOL)
		data->flags
		    |= ((data->flags & SF_BEFORE_EOL) << SF_FL_SHIFT_EOL);
	    else
		data->flags &= ~SF_FL_BEFORE_EOL;
            data->minlen_float=minlenp;
            data->lookbehind_float=0;
	}
    }
    SvCUR_set(data->last_found, 0);
    {
	SV * const sv = data->last_found;
	if (SvUTF8(sv) && SvMAGICAL(sv)) {
	    MAGIC * const mg = mg_find(sv, PERL_MAGIC_utf8);
	    if (mg)
		mg->mg_len = 0;
	}
    }
    data->last_end = -1;
    data->flags &= ~SF_BEFORE_EOL;
    DEBUG_STUDYDATA(data,0);
}

/* Can match anything (initialization) */
STATIC void
S_cl_anything(const RExC_state_t *pRExC_state, struct regnode_charclass_class *cl)
{
    ANYOF_CLASS_ZERO(cl);
    ANYOF_BITMAP_SETALL(cl);
    cl->flags = ANYOF_EOS|ANYOF_UNICODE_ALL;
    if (LOC)
	cl->flags |= ANYOF_LOCALE;
}

/* Can match anything (initialization) */
STATIC int
S_cl_is_anything(const struct regnode_charclass_class *cl)
{
    int value;

    for (value = 0; value <= ANYOF_MAX; value += 2)
	if (ANYOF_CLASS_TEST(cl, value) && ANYOF_CLASS_TEST(cl, value + 1))
	    return 1;
    if (!(cl->flags & ANYOF_UNICODE_ALL))
	return 0;
    if (!ANYOF_BITMAP_TESTALLSET((const void*)cl))
	return 0;
    return 1;
}

/* Can match anything (initialization) */
STATIC void
S_cl_init(const RExC_state_t *pRExC_state, struct regnode_charclass_class *cl)
{
    Zero(cl, 1, struct regnode_charclass_class);
    cl->type = ANYOF;
    cl_anything(pRExC_state, cl);
}

STATIC void
S_cl_init_zero(const RExC_state_t *pRExC_state, struct regnode_charclass_class *cl)
{
    Zero(cl, 1, struct regnode_charclass_class);
    cl->type = ANYOF;
    cl_anything(pRExC_state, cl);
    if (LOC)
	cl->flags |= ANYOF_LOCALE;
}

/* 'And' a given class with another one.  Can create false positives */
/* We assume that cl is not inverted */
STATIC void
S_cl_and(struct regnode_charclass_class *cl,
	const struct regnode_charclass_class *and_with)
{

    assert(and_with->type == ANYOF);
    if (!(and_with->flags & ANYOF_CLASS)
	&& !(cl->flags & ANYOF_CLASS)
	&& (and_with->flags & ANYOF_LOCALE) == (cl->flags & ANYOF_LOCALE)
	&& !(and_with->flags & ANYOF_FOLD)
	&& !(cl->flags & ANYOF_FOLD)) {
	int i;

	if (and_with->flags & ANYOF_INVERT)
	    for (i = 0; i < ANYOF_BITMAP_SIZE; i++)
		cl->bitmap[i] &= ~and_with->bitmap[i];
	else
	    for (i = 0; i < ANYOF_BITMAP_SIZE; i++)
		cl->bitmap[i] &= and_with->bitmap[i];
    } /* XXXX: logic is complicated otherwise, leave it along for a moment. */
    if (!(and_with->flags & ANYOF_EOS))
	cl->flags &= ~ANYOF_EOS;

    if (cl->flags & ANYOF_UNICODE_ALL && and_with->flags & ANYOF_UNICODE &&
	!(and_with->flags & ANYOF_INVERT)) {
	cl->flags &= ~ANYOF_UNICODE_ALL;
	cl->flags |= ANYOF_UNICODE;
	ARG_SET(cl, ARG(and_with));
    }
    if (!(and_with->flags & ANYOF_UNICODE_ALL) &&
	!(and_with->flags & ANYOF_INVERT))
	cl->flags &= ~ANYOF_UNICODE_ALL;
    if (!(and_with->flags & (ANYOF_UNICODE|ANYOF_UNICODE_ALL)) &&
	!(and_with->flags & ANYOF_INVERT))
	cl->flags &= ~ANYOF_UNICODE;
}

/* 'OR' a given class with another one.  Can create false positives */
/* We assume that cl is not inverted */
STATIC void
S_cl_or(const RExC_state_t *pRExC_state, struct regnode_charclass_class *cl, const struct regnode_charclass_class *or_with)
{
    if (or_with->flags & ANYOF_INVERT) {
	/* We do not use
	 * (B1 | CL1) | (!B2 & !CL2) = (B1 | !B2 & !CL2) | (CL1 | (!B2 & !CL2))
	 *   <= (B1 | !B2) | (CL1 | !CL2)
	 * which is wasteful if CL2 is small, but we ignore CL2:
	 *   (B1 | CL1) | (!B2 & !CL2) <= (B1 | CL1) | !B2 = (B1 | !B2) | CL1
	 * XXXX Can we handle case-fold?  Unclear:
	 *   (OK1(i) | OK1(i')) | !(OK1(i) | OK1(i')) =
	 *   (OK1(i) | OK1(i')) | (!OK1(i) & !OK1(i'))
	 */
	if ( (or_with->flags & ANYOF_LOCALE) == (cl->flags & ANYOF_LOCALE)
	     && !(or_with->flags & ANYOF_FOLD)
	     && !(cl->flags & ANYOF_FOLD) ) {
	    int i;

	    for (i = 0; i < ANYOF_BITMAP_SIZE; i++)
		cl->bitmap[i] |= ~or_with->bitmap[i];
	} /* XXXX: logic is complicated otherwise */
	else {
	    cl_anything(pRExC_state, cl);
	}
    } else {
	/* (B1 | CL1) | (B2 | CL2) = (B1 | B2) | (CL1 | CL2)) */
	if ( (or_with->flags & ANYOF_LOCALE) == (cl->flags & ANYOF_LOCALE)
	     && (!(or_with->flags & ANYOF_FOLD)
		 || (cl->flags & ANYOF_FOLD)) ) {
	    int i;

	    /* OR char bitmap and class bitmap separately */
	    for (i = 0; i < ANYOF_BITMAP_SIZE; i++)
		cl->bitmap[i] |= or_with->bitmap[i];
	    if (or_with->flags & ANYOF_CLASS) {
		for (i = 0; i < ANYOF_CLASSBITMAP_SIZE; i++)
		    cl->classflags[i] |= or_with->classflags[i];
		cl->flags |= ANYOF_CLASS;
	    }
	}
	else { /* XXXX: logic is complicated, leave it along for a moment. */
	    cl_anything(pRExC_state, cl);
	}
    }
    if (or_with->flags & ANYOF_EOS)
	cl->flags |= ANYOF_EOS;

    if (cl->flags & ANYOF_UNICODE && or_with->flags & ANYOF_UNICODE &&
	ARG(cl) != ARG(or_with)) {
	cl->flags |= ANYOF_UNICODE_ALL;
	cl->flags &= ~ANYOF_UNICODE;
    }
    if (or_with->flags & ANYOF_UNICODE_ALL) {
	cl->flags |= ANYOF_UNICODE_ALL;
	cl->flags &= ~ANYOF_UNICODE;
    }
}

#define TRIE_LIST_ITEM(state,idx) (trie->states[state].trans.list)[ idx ]
#define TRIE_LIST_CUR(state)  ( TRIE_LIST_ITEM( state, 0 ).forid )
#define TRIE_LIST_LEN(state) ( TRIE_LIST_ITEM( state, 0 ).newstate )
#define TRIE_LIST_USED(idx)  ( trie->states[state].trans.list ? (TRIE_LIST_CUR( idx ) - 1) : 0 )


#ifdef DEBUGGING
/*
   dump_trie(trie)
   dump_trie_interim_list(trie,next_alloc)
   dump_trie_interim_table(trie,next_alloc)

   These routines dump out a trie in a somewhat readable format.
   The _interim_ variants are used for debugging the interim
   tables that are used to generate the final compressed
   representation which is what dump_trie expects.

   Part of the reason for their existance is to provide a form
   of documentation as to how the different representations function.

*/

/*
  dump_trie(trie)
  Dumps the final compressed table form of the trie to Perl_debug_log.
  Used for debugging make_trie().
*/
 
STATIC void
S_dump_trie(pTHX_ const struct _reg_trie_data *trie,U32 depth)
{
    U32 state;
    SV *sv=sv_newmortal();
    int colwidth= trie->widecharmap ? 6 : 4;
    GET_RE_DEBUG_FLAGS_DECL;


    PerlIO_printf( Perl_debug_log, "%*sChar : %-6s%-6s%-4s ",
        (int)depth * 2 + 2,"",
        "Match","Base","Ofs" );

    for( state = 0 ; state < trie->uniquecharcount ; state++ ) {
	SV ** const tmp = av_fetch( trie->revcharmap, state, 0);
        if ( tmp ) {
            PerlIO_printf( Perl_debug_log, "%*s", 
                colwidth,
                pv_pretty(sv, SvPV_nolen_const(*tmp), SvCUR(*tmp), colwidth, 
	                    PL_colors[0], PL_colors[1],
	                    (SvUTF8(*tmp) ? PERL_PV_ESCAPE_UNI : 0) |
	                    PERL_PV_ESCAPE_FIRSTCHAR 
                ) 
            );
        }
    }
    PerlIO_printf( Perl_debug_log, "\n%*sState|-----------------------",
        (int)depth * 2 + 2,"");

    for( state = 0 ; state < trie->uniquecharcount ; state++ )
        PerlIO_printf( Perl_debug_log, "%.*s", colwidth, "--------");
    PerlIO_printf( Perl_debug_log, "\n");

    for( state = 1 ; state < trie->statecount ; state++ ) {
	const U32 base = trie->states[ state ].trans.base;

        PerlIO_printf( Perl_debug_log, "%*s#%4"UVXf"|", (int)depth * 2 + 2,"", (UV)state);

        if ( trie->states[ state ].wordnum ) {
            PerlIO_printf( Perl_debug_log, " W%4X", trie->states[ state ].wordnum );
        } else {
            PerlIO_printf( Perl_debug_log, "%6s", "" );
        }

        PerlIO_printf( Perl_debug_log, " @%4"UVXf" ", (UV)base );

        if ( base ) {
            U32 ofs = 0;

            while( ( base + ofs  < trie->uniquecharcount ) ||
                   ( base + ofs - trie->uniquecharcount < trie->lasttrans
                     && trie->trans[ base + ofs - trie->uniquecharcount ].check != state))
                    ofs++;

            PerlIO_printf( Perl_debug_log, "+%2"UVXf"[ ", (UV)ofs);

            for ( ofs = 0 ; ofs < trie->uniquecharcount ; ofs++ ) {
                if ( ( base + ofs >= trie->uniquecharcount ) &&
                     ( base + ofs - trie->uniquecharcount < trie->lasttrans ) &&
                     trie->trans[ base + ofs - trie->uniquecharcount ].check == state )
                {
                   PerlIO_printf( Perl_debug_log, "%*"UVXf,
                    colwidth,
                    (UV)trie->trans[ base + ofs - trie->uniquecharcount ].next );
                } else {
                    PerlIO_printf( Perl_debug_log, "%*s",colwidth,"   ." );
                }
            }

            PerlIO_printf( Perl_debug_log, "]");

        }
        PerlIO_printf( Perl_debug_log, "\n" );
    }
}    
/*
  dump_trie_interim_list(trie,next_alloc)
  Dumps a fully constructed but uncompressed trie in list form.
  List tries normally only are used for construction when the number of 
  possible chars (trie->uniquecharcount) is very high.
  Used for debugging make_trie().
*/
STATIC void
S_dump_trie_interim_list(pTHX_ const struct _reg_trie_data *trie, U32 next_alloc,U32 depth)
{
    U32 state;
    SV *sv=sv_newmortal();
    int colwidth= trie->widecharmap ? 6 : 4;
    GET_RE_DEBUG_FLAGS_DECL;
    /* print out the table precompression.  */
    PerlIO_printf( Perl_debug_log, "%*sState :Word | Transition Data\n%*s%s",
        (int)depth * 2 + 2,"", (int)depth * 2 + 2,"",
        "------:-----+-----------------\n" );
    
    for( state=1 ; state < next_alloc ; state ++ ) {
        U16 charid;
    
        PerlIO_printf( Perl_debug_log, "%*s %4"UVXf" :",
            (int)depth * 2 + 2,"", (UV)state  );
        if ( ! trie->states[ state ].wordnum ) {
            PerlIO_printf( Perl_debug_log, "%5s| ","");
        } else {
            PerlIO_printf( Perl_debug_log, "W%4x| ",
                trie->states[ state ].wordnum
            );
        }
        for( charid = 1 ; charid <= TRIE_LIST_USED( state ) ; charid++ ) {
	    SV ** const tmp = av_fetch( trie->revcharmap, TRIE_LIST_ITEM(state,charid).forid, 0);
	    if ( tmp ) {
                PerlIO_printf( Perl_debug_log, "%*s:%3X=%4"UVXf" | ",
                    colwidth,
                    pv_pretty(sv, SvPV_nolen_const(*tmp), SvCUR(*tmp), colwidth, 
	                    PL_colors[0], PL_colors[1],
	                    (SvUTF8(*tmp) ? PERL_PV_ESCAPE_UNI : 0) |
	                    PERL_PV_ESCAPE_FIRSTCHAR 
                    ) ,
                    TRIE_LIST_ITEM(state,charid).forid,
                    (UV)TRIE_LIST_ITEM(state,charid).newstate
                );
                if (!(charid % 10)) 
                    PerlIO_printf(Perl_debug_log, "\n%*s| ",
                        (int)((depth * 2) + 14), "");
            }
        }
        PerlIO_printf( Perl_debug_log, "\n");
    }
}    

/*
  dump_trie_interim_table(trie,next_alloc)
  Dumps a fully constructed but uncompressed trie in table form.
  This is the normal DFA style state transition table, with a few 
  twists to facilitate compression later. 
  Used for debugging make_trie().
*/
STATIC void
S_dump_trie_interim_table(pTHX_ const struct _reg_trie_data *trie, U32 next_alloc, U32 depth)
{
    U32 state;
    U16 charid;
    SV *sv=sv_newmortal();
    int colwidth= trie->widecharmap ? 6 : 4;
    GET_RE_DEBUG_FLAGS_DECL;
    
    /*
       print out the table precompression so that we can do a visual check
       that they are identical.
     */
    
    PerlIO_printf( Perl_debug_log, "%*sChar : ",(int)depth * 2 + 2,"" );

    for( charid = 0 ; charid < trie->uniquecharcount ; charid++ ) {
	SV ** const tmp = av_fetch( trie->revcharmap, charid, 0);
        if ( tmp ) {
            PerlIO_printf( Perl_debug_log, "%*s", 
                colwidth,
                pv_pretty(sv, SvPV_nolen_const(*tmp), SvCUR(*tmp), colwidth, 
	                    PL_colors[0], PL_colors[1],
	                    (SvUTF8(*tmp) ? PERL_PV_ESCAPE_UNI : 0) |
	                    PERL_PV_ESCAPE_FIRSTCHAR 
                ) 
            );
        }
    }

    PerlIO_printf( Perl_debug_log, "\n%*sState+-",(int)depth * 2 + 2,"" );

    for( charid=0 ; charid < trie->uniquecharcount ; charid++ ) {
        PerlIO_printf( Perl_debug_log, "%.*s", colwidth,"--------");
    }

    PerlIO_printf( Perl_debug_log, "\n" );

    for( state=1 ; state < next_alloc ; state += trie->uniquecharcount ) {

        PerlIO_printf( Perl_debug_log, "%*s%4"UVXf" : ", 
            (int)depth * 2 + 2,"",
            (UV)TRIE_NODENUM( state ) );

        for( charid = 0 ; charid < trie->uniquecharcount ; charid++ ) {
            UV v=(UV)SAFE_TRIE_NODENUM( trie->trans[ state + charid ].next );
            if (v)
                PerlIO_printf( Perl_debug_log, "%*"UVXf, colwidth, v );
            else
                PerlIO_printf( Perl_debug_log, "%*s", colwidth, "." );
        }
        if ( ! trie->states[ TRIE_NODENUM( state ) ].wordnum ) {
            PerlIO_printf( Perl_debug_log, " (%4"UVXf")\n", (UV)trie->trans[ state ].check );
        } else {
            PerlIO_printf( Perl_debug_log, " (%4"UVXf") W%4X\n", (UV)trie->trans[ state ].check,
            trie->states[ TRIE_NODENUM( state ) ].wordnum );
        }
    }
}

#endif

/* make_trie(startbranch,first,last,tail,word_count,flags,depth)
  startbranch: the first branch in the whole branch sequence
  first      : start branch of sequence of branch-exact nodes.
	       May be the same as startbranch
  last       : Thing following the last branch.
	       May be the same as tail.
  tail       : item following the branch sequence
  count      : words in the sequence
  flags      : currently the OP() type we will be building one of /EXACT(|F|Fl)/
  depth      : indent depth

Inplace optimizes a sequence of 2 or more Branch-Exact nodes into a TRIE node.

A trie is an N'ary tree where the branches are determined by digital
decomposition of the key. IE, at the root node you look up the 1st character and
follow that branch repeat until you find the end of the branches. Nodes can be
marked as "accepting" meaning they represent a complete word. Eg:

  /he|she|his|hers/

would convert into the following structure. Numbers represent states, letters
following numbers represent valid transitions on the letter from that state, if
the number is in square brackets it represents an accepting state, otherwise it
will be in parenthesis.

      +-h->+-e->[3]-+-r->(8)-+-s->[9]
      |    |
      |   (2)
      |    |
     (1)   +-i->(6)-+-s->[7]
      |
      +-s->(3)-+-h->(4)-+-e->[5]

      Accept Word Mapping: 3=>1 (he),5=>2 (she), 7=>3 (his), 9=>4 (hers)

This shows that when matching against the string 'hers' we will begin at state 1
read 'h' and move to state 2, read 'e' and move to state 3 which is accepting,
then read 'r' and go to state 8 followed by 's' which takes us to state 9 which
is also accepting. Thus we know that we can match both 'he' and 'hers' with a
single traverse. We store a mapping from accepting to state to which word was
matched, and then when we have multiple possibilities we try to complete the
rest of the regex in the order in which they occured in the alternation.

The only prior NFA like behaviour that would be changed by the TRIE support is
the silent ignoring of duplicate alternations which are of the form:

 / (DUPE|DUPE) X? (?{ ... }) Y /x

Thus EVAL blocks follwing a trie may be called a different number of times with
and without the optimisation. With the optimisations dupes will be silently
ignored. This inconsistant behaviour of EVAL type nodes is well established as
the following demonstrates:

 'words'=~/(word|word|word)(?{ print $1 })[xyz]/

which prints out 'word' three times, but

 'words'=~/(word|word|word)(?{ print $1 })S/

which doesnt print it out at all. This is due to other optimisations kicking in.

Example of what happens on a structural level:

The regexp /(ac|ad|ab)+/ will produce the folowing debug output:

   1: CURLYM[1] {1,32767}(18)
   5:   BRANCH(8)
   6:     EXACT <ac>(16)
   8:   BRANCH(11)
   9:     EXACT <ad>(16)
  11:   BRANCH(14)
  12:     EXACT <ab>(16)
  16:   SUCCEED(0)
  17:   NOTHING(18)
  18: END(0)

This would be optimizable with startbranch=5, first=5, last=16, tail=16
and should turn into:

   1: CURLYM[1] {1,32767}(18)
   5:   TRIE(16)
	[Words:3 Chars Stored:6 Unique Chars:4 States:5 NCP:1]
	  <ac>
	  <ad>
	  <ab>
  16:   SUCCEED(0)
  17:   NOTHING(18)
  18: END(0)

Cases where tail != last would be like /(?foo|bar)baz/:

   1: BRANCH(4)
   2:   EXACT <foo>(8)
   4: BRANCH(7)
   5:   EXACT <bar>(8)
   7: TAIL(8)
   8: EXACT <baz>(10)
  10: END(0)

which would be optimizable with startbranch=1, first=1, last=7, tail=8
and would end up looking like:

    1: TRIE(8)
      [Words:2 Chars Stored:6 Unique Chars:5 States:7 NCP:1]
	<foo>
	<bar>
   7: TAIL(8)
   8: EXACT <baz>(10)
  10: END(0)

    d = uvuni_to_utf8_flags(d, uv, 0);

is the recommended Unicode-aware way of saying

    *(d++) = uv;
*/

#define TRIE_STORE_REVCHAR                                                 \
    STMT_START {                                                           \
	SV *tmp = newSVpvs("");                                            \
	if (UTF) SvUTF8_on(tmp);                                           \
	Perl_sv_catpvf( aTHX_ tmp, "%c", (int)uvc );                       \
	av_push( TRIE_REVCHARMAP(trie), tmp );                             \
    } STMT_END

#define TRIE_READ_CHAR STMT_START {                                           \
    wordlen++;                                                                \
    if ( UTF ) {                                                              \
	if ( folder ) {                                                       \
	    if ( foldlen > 0 ) {                                              \
	       uvc = utf8n_to_uvuni( scan, UTF8_MAXLEN, &len, uniflags );     \
	       foldlen -= len;                                                \
	       scan += len;                                                   \
	       len = 0;                                                       \
	    } else {                                                          \
		uvc = utf8n_to_uvuni( (const U8*)uc, UTF8_MAXLEN, &len, uniflags);\
		uvc = to_uni_fold( uvc, foldbuf, &foldlen );                  \
		foldlen -= UNISKIP( uvc );                                    \
		scan = foldbuf + UNISKIP( uvc );                              \
	    }                                                                 \
	} else {                                                              \
	    uvc = utf8n_to_uvuni( (const U8*)uc, UTF8_MAXLEN, &len, uniflags);\
	}                                                                     \
    } else {                                                                  \
	uvc = (U32)*uc;                                                       \
	len = 1;                                                              \
    }                                                                         \
} STMT_END



#define TRIE_LIST_PUSH(state,fid,ns) STMT_START {               \
    if ( TRIE_LIST_CUR( state ) >=TRIE_LIST_LEN( state ) ) {    \
	U32 ging = TRIE_LIST_LEN( state ) *= 2;                 \
	Renew( trie->states[ state ].trans.list, ging, reg_trie_trans_le ); \
    }                                                           \
    TRIE_LIST_ITEM( state, TRIE_LIST_CUR( state ) ).forid = fid;     \
    TRIE_LIST_ITEM( state, TRIE_LIST_CUR( state ) ).newstate = ns;   \
    TRIE_LIST_CUR( state )++;                                   \
} STMT_END

#define TRIE_LIST_NEW(state) STMT_START {                       \
    Newxz( trie->states[ state ].trans.list,               \
	4, reg_trie_trans_le );                                 \
     TRIE_LIST_CUR( state ) = 1;                                \
     TRIE_LIST_LEN( state ) = 4;                                \
} STMT_END

#define TRIE_HANDLE_WORD(state) STMT_START {                    \
    U16 dupe= trie->states[ state ].wordnum;                    \
    regnode * const noper_next = regnext( noper );              \
                                                                \
    if (trie->wordlen)                                          \
        trie->wordlen[ curword ] = wordlen;                     \
    DEBUG_r({                                                   \
        /* store the word for dumping */                        \
        SV* tmp;                                                \
        if (OP(noper) != NOTHING)                               \
            tmp = newSVpvn(STRING(noper), STR_LEN(noper));      \
        else                                                    \
            tmp = newSVpvn( "", 0 );                            \
        if ( UTF ) SvUTF8_on( tmp );                            \
        av_push( trie->words, tmp );                            \
    });                                                         \
                                                                \
    curword++;                                                  \
                                                                \
    if ( noper_next < tail ) {                                  \
        if (!trie->jump)                                        \
            Newxz( trie->jump, word_count + 1, U16);            \
        trie->jump[curword] = (U16)(noper_next - convert);      \
        if (!jumper)                                            \
            jumper = noper_next;                                \
        if (!nextbranch)                                        \
            nextbranch= regnext(cur);                           \
    }                                                           \
                                                                \
    if ( dupe ) {                                               \
        /* So it's a dupe. This means we need to maintain a   */\
        /* linked-list from the first to the next.            */\
        /* we only allocate the nextword buffer when there    */\
        /* a dupe, so first time we have to do the allocation */\
        if (!trie->nextword)                                    \
            Newxz( trie->nextword, word_count + 1, U16);        \
        while ( trie->nextword[dupe] )                          \
            dupe= trie->nextword[dupe];                         \
        trie->nextword[dupe]= curword;                          \
    } else {                                                    \
        /* we haven't inserted this word yet.                */ \
        trie->states[ state ].wordnum = curword;                \
    }                                                           \
} STMT_END


#define TRIE_TRANS_STATE(state,base,ucharcount,charid,special)		\
     ( ( base + charid >=  ucharcount					\
         && base + charid < ubound					\
         && state == trie->trans[ base - ucharcount + charid ].check	\
         && trie->trans[ base - ucharcount + charid ].next )		\
           ? trie->trans[ base - ucharcount + charid ].next		\
           : ( state==1 ? special : 0 )					\
      )

#define MADE_TRIE       1
#define MADE_JUMP_TRIE  2
#define MADE_EXACT_TRIE 4

STATIC I32
S_make_trie(pTHX_ RExC_state_t *pRExC_state, regnode *startbranch, regnode *first, regnode *last, regnode *tail, U32 word_count, U32 flags, U32 depth)
{
    dVAR;
    /* first pass, loop through and scan words */
    reg_trie_data *trie;
    regnode *cur;
    const U32 uniflags = UTF8_ALLOW_DEFAULT;
    STRLEN len = 0;
    UV uvc = 0;
    U16 curword = 0;
    U32 next_alloc = 0;
    regnode *jumper = NULL;
    regnode *nextbranch = NULL;
    regnode *convert = NULL;
    /* we just use folder as a flag in utf8 */
    const U8 * const folder = ( flags == EXACTF
                       ? PL_fold
                       : ( flags == EXACTFL
                           ? PL_fold_locale
                           : NULL
                         )
                     );

    const U32 data_slot = add_data( pRExC_state, 1, "t" );
    SV *re_trie_maxbuff;
#ifndef DEBUGGING
    /* these are only used during construction but are useful during
     * debugging so we store them in the struct when debugging.
     */
    STRLEN trie_charcount=0;
    AV *trie_revcharmap;
#endif
    GET_RE_DEBUG_FLAGS_DECL;
#ifndef DEBUGGING
    PERL_UNUSED_ARG(depth);
#endif

    Newxz( trie, 1, reg_trie_data );
    trie->refcount = 1;
    trie->startstate = 1;
    trie->wordcount = word_count;
    RExC_rx->data->data[ data_slot ] = (void*)trie;
    Newxz( trie->charmap, 256, U16 );
    if (!(UTF && folder))
        Newxz( trie->bitmap, ANYOF_BITMAP_SIZE, char );
    DEBUG_r({
        trie->words = newAV();
    });
    TRIE_REVCHARMAP(trie) = newAV();

    re_trie_maxbuff = get_sv(RE_TRIE_MAXBUF_NAME, 1);
    if (!SvIOK(re_trie_maxbuff)) {
        sv_setiv(re_trie_maxbuff, RE_TRIE_MAXBUF_INIT);
    }
    DEBUG_OPTIMISE_r({
                PerlIO_printf( Perl_debug_log,
                  "%*smake_trie start==%d, first==%d, last==%d, tail==%d depth=%d\n",
                  (int)depth * 2 + 2, "", 
                  REG_NODE_NUM(startbranch),REG_NODE_NUM(first), 
                  REG_NODE_NUM(last), REG_NODE_NUM(tail),
                  (int)depth);
    });
   
   /* Find the node we are going to overwrite */
    if ( first == startbranch && OP( last ) != BRANCH ) {
        /* whole branch chain */
        convert = first;
    } else {
        /* branch sub-chain */
        convert = NEXTOPER( first );
    }
        
    /*  -- First loop and Setup --

       We first traverse the branches and scan each word to determine if it
       contains widechars, and how many unique chars there are, this is
       important as we have to build a table with at least as many columns as we
       have unique chars.

       We use an array of integers to represent the character codes 0..255
       (trie->charmap) and we use a an HV* to store unicode characters. We use the
       native representation of the character value as the key and IV's for the
       coded index.

       *TODO* If we keep track of how many times each character is used we can
       remap the columns so that the table compression later on is more
       efficient in terms of memory by ensuring most common value is in the
       middle and the least common are on the outside.  IMO this would be better
       than a most to least common mapping as theres a decent chance the most
       common letter will share a node with the least common, meaning the node
       will not be compressable. With a middle is most common approach the worst
       case is when we have the least common nodes twice.

     */

    for ( cur = first ; cur < last ; cur = regnext( cur ) ) {
        regnode * const noper = NEXTOPER( cur );
        const U8 *uc = (U8*)STRING( noper );
        const U8 * const e  = uc + STR_LEN( noper );
        STRLEN foldlen = 0;
        U8 foldbuf[ UTF8_MAXBYTES_CASE + 1 ];
        const U8 *scan = (U8*)NULL;
        U32 wordlen      = 0;         /* required init */
        STRLEN chars=0;

        if (OP(noper) == NOTHING) {
            trie->minlen= 0;
            continue;
        }
        if (trie->bitmap) {
            TRIE_BITMAP_SET(trie,*uc);
            if ( folder ) TRIE_BITMAP_SET(trie,folder[ *uc ]);            
        }
        for ( ; uc < e ; uc += len ) {
            TRIE_CHARCOUNT(trie)++;
            TRIE_READ_CHAR;
            chars++;
            if ( uvc < 256 ) {
                if ( !trie->charmap[ uvc ] ) {
                    trie->charmap[ uvc ]=( ++trie->uniquecharcount );
                    if ( folder )
                        trie->charmap[ folder[ uvc ] ] = trie->charmap[ uvc ];
                    TRIE_STORE_REVCHAR;
                }
            } else {
                SV** svpp;
                if ( !trie->widecharmap )
                    trie->widecharmap = newHV();

                svpp = hv_fetch( trie->widecharmap, (char*)&uvc, sizeof( UV ), 1 );

                if ( !svpp )
                    Perl_croak( aTHX_ "error creating/fetching widecharmap entry for 0x%"UVXf, uvc );

                if ( !SvTRUE( *svpp ) ) {
                    sv_setiv( *svpp, ++trie->uniquecharcount );
                    TRIE_STORE_REVCHAR;
                }
            }
        }
        if( cur == first ) {
            trie->minlen=chars;
            trie->maxlen=chars;
        } else if (chars < trie->minlen) {
            trie->minlen=chars;
        } else if (chars > trie->maxlen) {
            trie->maxlen=chars;
        }

    } /* end first pass */
    DEBUG_TRIE_COMPILE_r(
        PerlIO_printf( Perl_debug_log, "%*sTRIE(%s): W:%d C:%d Uq:%d Min:%d Max:%d\n",
                (int)depth * 2 + 2,"",
                ( trie->widecharmap ? "UTF8" : "NATIVE" ), (int)word_count,
		(int)TRIE_CHARCOUNT(trie), trie->uniquecharcount,
		(int)trie->minlen, (int)trie->maxlen )
    );
    Newxz( trie->wordlen, word_count, U32 );

    /*
        We now know what we are dealing with in terms of unique chars and
        string sizes so we can calculate how much memory a naive
        representation using a flat table  will take. If it's over a reasonable
        limit (as specified by ${^RE_TRIE_MAXBUF}) we use a more memory
        conservative but potentially much slower representation using an array
        of lists.

        At the end we convert both representations into the same compressed
        form that will be used in regexec.c for matching with. The latter
        is a form that cannot be used to construct with but has memory
        properties similar to the list form and access properties similar
        to the table form making it both suitable for fast searches and
        small enough that its feasable to store for the duration of a program.

        See the comment in the code where the compressed table is produced
        inplace from the flat tabe representation for an explanation of how
        the compression works.

    */


    if ( (IV)( ( TRIE_CHARCOUNT(trie) + 1 ) * trie->uniquecharcount + 1) > SvIV(re_trie_maxbuff) ) {
        /*
            Second Pass -- Array Of Lists Representation

            Each state will be represented by a list of charid:state records
            (reg_trie_trans_le) the first such element holds the CUR and LEN
            points of the allocated array. (See defines above).

            We build the initial structure using the lists, and then convert
            it into the compressed table form which allows faster lookups
            (but cant be modified once converted).
        */

        STRLEN transcount = 1;

        DEBUG_TRIE_COMPILE_MORE_r( PerlIO_printf( Perl_debug_log, 
            "%*sCompiling trie using list compiler\n",
            (int)depth * 2 + 2, ""));

        Newxz( trie->states, TRIE_CHARCOUNT(trie) + 2, reg_trie_state );
        TRIE_LIST_NEW(1);
        next_alloc = 2;

        for ( cur = first ; cur < last ; cur = regnext( cur ) ) {

	    regnode * const noper = NEXTOPER( cur );
	    U8 *uc           = (U8*)STRING( noper );
	    const U8 * const e = uc + STR_LEN( noper );
	    U32 state        = 1;         /* required init */
	    U16 charid       = 0;         /* sanity init */
	    U8 *scan         = (U8*)NULL; /* sanity init */
	    STRLEN foldlen   = 0;         /* required init */
            U32 wordlen      = 0;         /* required init */
	    U8 foldbuf[ UTF8_MAXBYTES_CASE + 1 ];

            if (OP(noper) != NOTHING) {
                for ( ; uc < e ; uc += len ) {

                    TRIE_READ_CHAR;

                    if ( uvc < 256 ) {
                        charid = trie->charmap[ uvc ];
		    } else {
                        SV** const svpp = hv_fetch( trie->widecharmap, (char*)&uvc, sizeof( UV ), 0);
                        if ( !svpp ) {
                            charid = 0;
                        } else {
                            charid=(U16)SvIV( *svpp );
                        }
		    }
                    /* charid is now 0 if we dont know the char read, or nonzero if we do */
                    if ( charid ) {

                        U16 check;
                        U32 newstate = 0;

                        charid--;
                        if ( !trie->states[ state ].trans.list ) {
                            TRIE_LIST_NEW( state );
			}
                        for ( check = 1; check <= TRIE_LIST_USED( state ); check++ ) {
                            if ( TRIE_LIST_ITEM( state, check ).forid == charid ) {
                                newstate = TRIE_LIST_ITEM( state, check ).newstate;
                                break;
                            }
                        }
                        if ( ! newstate ) {
                            newstate = next_alloc++;
                            TRIE_LIST_PUSH( state, charid, newstate );
                            transcount++;
                        }
                        state = newstate;
                    } else {
                        Perl_croak( aTHX_ "panic! In trie construction, no char mapping for %"IVdf, uvc );
		    }
		}
	    }
            TRIE_HANDLE_WORD(state);

        } /* end second pass */

        /* next alloc is the NEXT state to be allocated */
        trie->statecount = next_alloc; 
        Renew( trie->states, next_alloc, reg_trie_state );

        /* and now dump it out before we compress it */
        DEBUG_TRIE_COMPILE_MORE_r(
            dump_trie_interim_list(trie,next_alloc,depth+1)
        );

        Newxz( trie->trans, transcount ,reg_trie_trans );
        {
            U32 state;
            U32 tp = 0;
            U32 zp = 0;


            for( state=1 ; state < next_alloc ; state ++ ) {
                U32 base=0;

                /*
                DEBUG_TRIE_COMPILE_MORE_r(
                    PerlIO_printf( Perl_debug_log, "tp: %d zp: %d ",tp,zp)
                );
                */

                if (trie->states[state].trans.list) {
                    U16 minid=TRIE_LIST_ITEM( state, 1).forid;
                    U16 maxid=minid;
		    U16 idx;

                    for( idx = 2 ; idx <= TRIE_LIST_USED( state ) ; idx++ ) {
			const U16 forid = TRIE_LIST_ITEM( state, idx).forid;
			if ( forid < minid ) {
			    minid=forid;
			} else if ( forid > maxid ) {
			    maxid=forid;
			}
                    }
                    if ( transcount < tp + maxid - minid + 1) {
                        transcount *= 2;
                        Renew( trie->trans, transcount, reg_trie_trans );
                        Zero( trie->trans + (transcount / 2), transcount / 2 , reg_trie_trans );
                    }
                    base = trie->uniquecharcount + tp - minid;
                    if ( maxid == minid ) {
                        U32 set = 0;
                        for ( ; zp < tp ; zp++ ) {
                            if ( ! trie->trans[ zp ].next ) {
                                base = trie->uniquecharcount + zp - minid;
                                trie->trans[ zp ].next = TRIE_LIST_ITEM( state, 1).newstate;
                                trie->trans[ zp ].check = state;
                                set = 1;
                                break;
                            }
                        }
                        if ( !set ) {
                            trie->trans[ tp ].next = TRIE_LIST_ITEM( state, 1).newstate;
                            trie->trans[ tp ].check = state;
                            tp++;
                            zp = tp;
                        }
                    } else {
                        for ( idx=1; idx <= TRIE_LIST_USED( state ) ; idx++ ) {
                            const U32 tid = base -  trie->uniquecharcount + TRIE_LIST_ITEM( state, idx ).forid;
                            trie->trans[ tid ].next = TRIE_LIST_ITEM( state, idx ).newstate;
                            trie->trans[ tid ].check = state;
                        }
                        tp += ( maxid - minid + 1 );
                    }
                    Safefree(trie->states[ state ].trans.list);
                }
                /*
                DEBUG_TRIE_COMPILE_MORE_r(
                    PerlIO_printf( Perl_debug_log, " base: %d\n",base);
                );
                */
                trie->states[ state ].trans.base=base;
            }
            trie->lasttrans = tp + 1;
        }
    } else {
        /*
           Second Pass -- Flat Table Representation.

           we dont use the 0 slot of either trans[] or states[] so we add 1 to each.
           We know that we will need Charcount+1 trans at most to store the data
           (one row per char at worst case) So we preallocate both structures
           assuming worst case.

           We then construct the trie using only the .next slots of the entry
           structs.

           We use the .check field of the first entry of the node  temporarily to
           make compression both faster and easier by keeping track of how many non
           zero fields are in the node.

           Since trans are numbered from 1 any 0 pointer in the table is a FAIL
           transition.

           There are two terms at use here: state as a TRIE_NODEIDX() which is a
           number representing the first entry of the node, and state as a
           TRIE_NODENUM() which is the trans number. state 1 is TRIE_NODEIDX(1) and
           TRIE_NODENUM(1), state 2 is TRIE_NODEIDX(2) and TRIE_NODENUM(3) if there
           are 2 entrys per node. eg:

             A B       A B
          1. 2 4    1. 3 7
          2. 0 3    3. 0 5
          3. 0 0    5. 0 0
          4. 0 0    7. 0 0

           The table is internally in the right hand, idx form. However as we also
           have to deal with the states array which is indexed by nodenum we have to
           use TRIE_NODENUM() to convert.

        */
        DEBUG_TRIE_COMPILE_MORE_r( PerlIO_printf( Perl_debug_log, 
            "%*sCompiling trie using table compiler\n",
            (int)depth * 2 + 2, ""));

        Newxz( trie->trans, ( TRIE_CHARCOUNT(trie) + 1 ) * trie->uniquecharcount + 1,
              reg_trie_trans );
        Newxz( trie->states, TRIE_CHARCOUNT(trie) + 2, reg_trie_state );
        next_alloc = trie->uniquecharcount + 1;


        for ( cur = first ; cur < last ; cur = regnext( cur ) ) {

	    regnode * const noper   = NEXTOPER( cur );
	    const U8 *uc     = (U8*)STRING( noper );
	    const U8 * const e = uc + STR_LEN( noper );

            U32 state        = 1;         /* required init */

            U16 charid       = 0;         /* sanity init */
            U32 accept_state = 0;         /* sanity init */
            U8 *scan         = (U8*)NULL; /* sanity init */

            STRLEN foldlen   = 0;         /* required init */
            U32 wordlen      = 0;         /* required init */
            U8 foldbuf[ UTF8_MAXBYTES_CASE + 1 ];

            if ( OP(noper) != NOTHING ) {
                for ( ; uc < e ; uc += len ) {

                    TRIE_READ_CHAR;

                    if ( uvc < 256 ) {
                        charid = trie->charmap[ uvc ];
                    } else {
                        SV* const * const svpp = hv_fetch( trie->widecharmap, (char*)&uvc, sizeof( UV ), 0);
                        charid = svpp ? (U16)SvIV(*svpp) : 0;
                    }
                    if ( charid ) {
                        charid--;
                        if ( !trie->trans[ state + charid ].next ) {
                            trie->trans[ state + charid ].next = next_alloc;
                            trie->trans[ state ].check++;
                            next_alloc += trie->uniquecharcount;
                        }
                        state = trie->trans[ state + charid ].next;
                    } else {
                        Perl_croak( aTHX_ "panic! In trie construction, no char mapping for %"IVdf, uvc );
                    }
                    /* charid is now 0 if we dont know the char read, or nonzero if we do */
                }
            }
            accept_state = TRIE_NODENUM( state );
            TRIE_HANDLE_WORD(accept_state);

        } /* end second pass */

        /* and now dump it out before we compress it */
        DEBUG_TRIE_COMPILE_MORE_r(
            dump_trie_interim_table(trie,next_alloc,depth+1)
        );

        {
        /*
           * Inplace compress the table.*

           For sparse data sets the table constructed by the trie algorithm will
           be mostly 0/FAIL transitions or to put it another way mostly empty.
           (Note that leaf nodes will not contain any transitions.)

           This algorithm compresses the tables by eliminating most such
           transitions, at the cost of a modest bit of extra work during lookup:

           - Each states[] entry contains a .base field which indicates the
           index in the state[] array wheres its transition data is stored.

           - If .base is 0 there are no  valid transitions from that node.

           - If .base is nonzero then charid is added to it to find an entry in
           the trans array.

           -If trans[states[state].base+charid].check!=state then the
           transition is taken to be a 0/Fail transition. Thus if there are fail
           transitions at the front of the node then the .base offset will point
           somewhere inside the previous nodes data (or maybe even into a node
           even earlier), but the .check field determines if the transition is
           valid.

           XXX - wrong maybe?
           The following process inplace converts the table to the compressed
           table: We first do not compress the root node 1,and mark its all its
           .check pointers as 1 and set its .base pointer as 1 as well. This
           allows to do a DFA construction from the compressed table later, and
           ensures that any .base pointers we calculate later are greater than
           0.

           - We set 'pos' to indicate the first entry of the second node.

           - We then iterate over the columns of the node, finding the first and
           last used entry at l and m. We then copy l..m into pos..(pos+m-l),
           and set the .check pointers accordingly, and advance pos
           appropriately and repreat for the next node. Note that when we copy
           the next pointers we have to convert them from the original
           NODEIDX form to NODENUM form as the former is not valid post
           compression.

           - If a node has no transitions used we mark its base as 0 and do not
           advance the pos pointer.

           - If a node only has one transition we use a second pointer into the
           structure to fill in allocated fail transitions from other states.
           This pointer is independent of the main pointer and scans forward
           looking for null transitions that are allocated to a state. When it
           finds one it writes the single transition into the "hole".  If the
           pointer doesnt find one the single transition is appended as normal.

           - Once compressed we can Renew/realloc the structures to release the
           excess space.

           See "Table-Compression Methods" in sec 3.9 of the Red Dragon,
           specifically Fig 3.47 and the associated pseudocode.

           demq
        */
        const U32 laststate = TRIE_NODENUM( next_alloc );
	U32 state, charid;
        U32 pos = 0, zp=0;
        trie->statecount = laststate;

        for ( state = 1 ; state < laststate ; state++ ) {
            U8 flag = 0;
	    const U32 stateidx = TRIE_NODEIDX( state );
	    const U32 o_used = trie->trans[ stateidx ].check;
	    U32 used = trie->trans[ stateidx ].check;
            trie->trans[ stateidx ].check = 0;

            for ( charid = 0 ; used && charid < trie->uniquecharcount ; charid++ ) {
                if ( flag || trie->trans[ stateidx + charid ].next ) {
                    if ( trie->trans[ stateidx + charid ].next ) {
                        if (o_used == 1) {
                            for ( ; zp < pos ; zp++ ) {
                                if ( ! trie->trans[ zp ].next ) {
                                    break;
                                }
                            }
                            trie->states[ state ].trans.base = zp + trie->uniquecharcount - charid ;
                            trie->trans[ zp ].next = SAFE_TRIE_NODENUM( trie->trans[ stateidx + charid ].next );
                            trie->trans[ zp ].check = state;
                            if ( ++zp > pos ) pos = zp;
                            break;
                        }
                        used--;
                    }
                    if ( !flag ) {
                        flag = 1;
                        trie->states[ state ].trans.base = pos + trie->uniquecharcount - charid ;
                    }
                    trie->trans[ pos ].next = SAFE_TRIE_NODENUM( trie->trans[ stateidx + charid ].next );
                    trie->trans[ pos ].check = state;
                    pos++;
                }
            }
        }
        trie->lasttrans = pos + 1;
        Renew( trie->states, laststate, reg_trie_state);
        DEBUG_TRIE_COMPILE_MORE_r(
                PerlIO_printf( Perl_debug_log,
		    "%*sAlloc: %d Orig: %"IVdf" elements, Final:%"IVdf". Savings of %%%5.2f\n",
		    (int)depth * 2 + 2,"",
                    (int)( ( TRIE_CHARCOUNT(trie) + 1 ) * trie->uniquecharcount + 1 ),
		    (IV)next_alloc,
		    (IV)pos,
                    ( ( next_alloc - pos ) * 100 ) / (double)next_alloc );
            );

        } /* end table compress */
    }
    DEBUG_TRIE_COMPILE_MORE_r(
            PerlIO_printf(Perl_debug_log, "%*sStatecount:%"UVxf" Lasttrans:%"UVxf"\n",
                (int)depth * 2 + 2, "",
                (UV)trie->statecount,
                (UV)trie->lasttrans)
    );
    /* resize the trans array to remove unused space */
    Renew( trie->trans, trie->lasttrans, reg_trie_trans);

    /* and now dump out the compressed format */
    DEBUG_TRIE_COMPILE_r(
        dump_trie(trie,depth+1)
    );

    {   /* Modify the program and insert the new TRIE node*/ 
        U8 nodetype =(U8)(flags & 0xFF);
        char *str=NULL;
        
#ifdef DEBUGGING
        regnode *optimize = NULL;
        U32 mjd_offset = 0;
        U32 mjd_nodelen = 0;
#endif
        /*
           This means we convert either the first branch or the first Exact,
           depending on whether the thing following (in 'last') is a branch
           or not and whther first is the startbranch (ie is it a sub part of
           the alternation or is it the whole thing.)
           Assuming its a sub part we conver the EXACT otherwise we convert
           the whole branch sequence, including the first.
         */
        /* Find the node we are going to overwrite */
        if ( first != startbranch || OP( last ) == BRANCH ) {
            /* branch sub-chain */
            NEXT_OFF( first ) = (U16)(last - first);
            DEBUG_r({
                mjd_offset= Node_Offset((convert));
                mjd_nodelen= Node_Length((convert));
            });
            /* whole branch chain */
        } else {
            DEBUG_r({
                const  regnode *nop = NEXTOPER( convert );
                mjd_offset= Node_Offset((nop));
                mjd_nodelen= Node_Length((nop));
            });
        }
        
        DEBUG_OPTIMISE_r(
            PerlIO_printf(Perl_debug_log, "%*sMJD offset:%"UVuf" MJD length:%"UVuf"\n",
                (int)depth * 2 + 2, "",
                (UV)mjd_offset, (UV)mjd_nodelen)
        );

        /* But first we check to see if there is a common prefix we can 
           split out as an EXACT and put in front of the TRIE node.  */
        trie->startstate= 1;
        if ( trie->bitmap && !trie->widecharmap && !trie->jump  ) {
            U32 state;
            for ( state = 1 ; state < trie->statecount-1 ; state++ ) {
                U32 ofs = 0;
                I32 idx = -1;
                U32 count = 0;
                const U32 base = trie->states[ state ].trans.base;

                if ( trie->states[state].wordnum )
                        count = 1;

                for ( ofs = 0 ; ofs < trie->uniquecharcount ; ofs++ ) {
                    if ( ( base + ofs >= trie->uniquecharcount ) &&
                         ( base + ofs - trie->uniquecharcount < trie->lasttrans ) &&
                         trie->trans[ base + ofs - trie->uniquecharcount ].check == state )
                    {
                        if ( ++count > 1 ) {
                            SV **tmp = av_fetch( TRIE_REVCHARMAP(trie), ofs, 0);
			    const U8 *ch = (U8*)SvPV_nolen_const( *tmp );
                            if ( state == 1 ) break;
                            if ( count == 2 ) {
                                Zero(trie->bitmap, ANYOF_BITMAP_SIZE, char);
                                DEBUG_OPTIMISE_r(
                                    PerlIO_printf(Perl_debug_log,
					"%*sNew Start State=%"UVuf" Class: [",
                                        (int)depth * 2 + 2, "",
                                        (UV)state));
				if (idx >= 0) {
				    SV ** const tmp = av_fetch( TRIE_REVCHARMAP(trie), idx, 0);
				    const U8 * const ch = (U8*)SvPV_nolen_const( *tmp );

                                    TRIE_BITMAP_SET(trie,*ch);
                                    if ( folder )
                                        TRIE_BITMAP_SET(trie, folder[ *ch ]);
                                    DEBUG_OPTIMISE_r(
                                        PerlIO_printf(Perl_debug_log, (char*)ch)
                                    );
				}
			    }
			    TRIE_BITMAP_SET(trie,*ch);
			    if ( folder )
				TRIE_BITMAP_SET(trie,folder[ *ch ]);
			    DEBUG_OPTIMISE_r(PerlIO_printf( Perl_debug_log,"%s", ch));
			}
                        idx = ofs;
		    }
                }
                if ( count == 1 ) {
                    SV **tmp = av_fetch( TRIE_REVCHARMAP(trie), idx, 0);
                    const char *ch = SvPV_nolen_const( *tmp );
                    DEBUG_OPTIMISE_r(
                        PerlIO_printf( Perl_debug_log,
			    "%*sPrefix State: %"UVuf" Idx:%"UVuf" Char='%s'\n",
                            (int)depth * 2 + 2, "",
                            (UV)state, (UV)idx, ch)
                    );
                    if ( state==1 ) {
                        OP( convert ) = nodetype;
                        str=STRING(convert);
                        STR_LEN(convert)=0;
                    }
                    *str++=*ch;
                    STR_LEN(convert)++;

		} else {
#ifdef DEBUGGING	    
		    if (state>1)
			DEBUG_OPTIMISE_r(PerlIO_printf( Perl_debug_log,"]\n"));
#endif
		    break;
		}
	    }
            if (str) {
                regnode *n = convert+NODE_SZ_STR(convert);
                NEXT_OFF(convert) = NODE_SZ_STR(convert);
                trie->startstate = state;
                trie->minlen -= (state - 1);
                trie->maxlen -= (state - 1);
                DEBUG_r({
                    regnode *fix = convert;
                    mjd_nodelen++;
                    Set_Node_Offset_Length(convert, mjd_offset, state - 1);
                    while( ++fix < n ) {
                        Set_Node_Offset_Length(fix, 0, 0);
                    }
                });
                if (trie->maxlen) {
                    convert = n;
		} else {
                    NEXT_OFF(convert) = (U16)(tail - convert);
                    DEBUG_r(optimize= n);
                }
            }
        }
        if (!jumper) 
            jumper = last; 
        if ( trie->maxlen ) {
	    NEXT_OFF( convert ) = (U16)(tail - convert);
	    ARG_SET( convert, data_slot );
	    /* Store the offset to the first unabsorbed branch in 
	       jump[0], which is otherwise unused by the jump logic. 
	       We use this when dumping a trie and during optimisation. */
	    if (trie->jump) 
	        trie->jump[0] = (U16)(nextbranch - convert);
            
            /* XXXX */
            if ( !trie->states[trie->startstate].wordnum && trie->bitmap && 
                 ( (char *)jumper - (char *)convert) >= (int)sizeof(struct regnode_charclass) )
            {
                OP( convert ) = TRIEC;
                Copy(trie->bitmap, ((struct regnode_charclass *)convert)->bitmap, ANYOF_BITMAP_SIZE, char);
                Safefree(trie->bitmap);
                trie->bitmap= NULL;
            } else 
                OP( convert ) = TRIE;

            /* store the type in the flags */
            convert->flags = nodetype;
            DEBUG_r({
            optimize = convert 
                      + NODE_STEP_REGNODE 
                      + regarglen[ OP( convert ) ];
            });
            /* XXX We really should free up the resource in trie now, 
                   as we won't use them - (which resources?) dmq */
        }
        /* needed for dumping*/
        DEBUG_r(if (optimize) {
            regnode *opt = convert;
            while ( ++opt < optimize) {
                Set_Node_Offset_Length(opt,0,0);
            }
            /* 
                Try to clean up some of the debris left after the 
                optimisation.
             */
            while( optimize < jumper ) {
                mjd_nodelen += Node_Length((optimize));
                OP( optimize ) = OPTIMIZED;
                Set_Node_Offset_Length(optimize,0,0);
                optimize++;
            }
            Set_Node_Offset_Length(convert,mjd_offset,mjd_nodelen);
        });
    } /* end node insert */
#ifndef DEBUGGING
    SvREFCNT_dec(TRIE_REVCHARMAP(trie));
#endif
    return trie->jump 
           ? MADE_JUMP_TRIE 
           : trie->startstate>1 
             ? MADE_EXACT_TRIE 
             : MADE_TRIE;
}

STATIC void
S_make_trie_failtable(pTHX_ RExC_state_t *pRExC_state, regnode *source,  regnode *stclass, U32 depth)
{
/* The Trie is constructed and compressed now so we can build a fail array now if its needed

   This is basically the Aho-Corasick algorithm. Its from exercise 3.31 and 3.32 in the
   "Red Dragon" -- Compilers, principles, techniques, and tools. Aho, Sethi, Ullman 1985/88
   ISBN 0-201-10088-6

   We find the fail state for each state in the trie, this state is the longest proper
   suffix of the current states 'word' that is also a proper prefix of another word in our
   trie. State 1 represents the word '' and is the thus the default fail state. This allows
   the DFA not to have to restart after its tried and failed a word at a given point, it
   simply continues as though it had been matching the other word in the first place.
   Consider
      'abcdgu'=~/abcdefg|cdgu/
   When we get to 'd' we are still matching the first word, we would encounter 'g' which would
   fail, which would bring use to the state representing 'd' in the second word where we would
   try 'g' and succeed, prodceding to match 'cdgu'.
 */
 /* add a fail transition */
    reg_trie_data *trie=(reg_trie_data *)RExC_rx->data->data[ARG(source)];
    U32 *q;
    const U32 ucharcount = trie->uniquecharcount;
    const U32 numstates = trie->statecount;
    const U32 ubound = trie->lasttrans + ucharcount;
    U32 q_read = 0;
    U32 q_write = 0;
    U32 charid;
    U32 base = trie->states[ 1 ].trans.base;
    U32 *fail;
    reg_ac_data *aho;
    const U32 data_slot = add_data( pRExC_state, 1, "T" );
    GET_RE_DEBUG_FLAGS_DECL;
#ifndef DEBUGGING
    PERL_UNUSED_ARG(depth);
#endif


    ARG_SET( stclass, data_slot );
    Newxz( aho, 1, reg_ac_data );
    RExC_rx->data->data[ data_slot ] = (void*)aho;
    aho->trie=trie;
    aho->states=(reg_trie_state *)savepvn((const char*)trie->states,
        numstates * sizeof(reg_trie_state));
    Newxz( q, numstates, U32);
    Newxz( aho->fail, numstates, U32 );
    aho->refcount = 1;
    fail = aho->fail;
    /* initialize fail[0..1] to be 1 so that we always have
       a valid final fail state */
    fail[ 0 ] = fail[ 1 ] = 1;

    for ( charid = 0; charid < ucharcount ; charid++ ) {
	const U32 newstate = TRIE_TRANS_STATE( 1, base, ucharcount, charid, 0 );
	if ( newstate ) {
            q[ q_write ] = newstate;
            /* set to point at the root */
            fail[ q[ q_write++ ] ]=1;
        }
    }
    while ( q_read < q_write) {
	const U32 cur = q[ q_read++ % numstates ];
        base = trie->states[ cur ].trans.base;

        for ( charid = 0 ; charid < ucharcount ; charid++ ) {
	    const U32 ch_state = TRIE_TRANS_STATE( cur, base, ucharcount, charid, 1 );
	    if (ch_state) {
                U32 fail_state = cur;
                U32 fail_base;
                do {
                    fail_state = fail[ fail_state ];
                    fail_base = aho->states[ fail_state ].trans.base;
                } while ( !TRIE_TRANS_STATE( fail_state, fail_base, ucharcount, charid, 1 ) );

                fail_state = TRIE_TRANS_STATE( fail_state, fail_base, ucharcount, charid, 1 );
                fail[ ch_state ] = fail_state;
                if ( !aho->states[ ch_state ].wordnum && aho->states[ fail_state ].wordnum )
                {
                        aho->states[ ch_state ].wordnum =  aho->states[ fail_state ].wordnum;
                }
                q[ q_write++ % numstates] = ch_state;
            }
        }
    }
    /* restore fail[0..1] to 0 so that we "fall out" of the AC loop
       when we fail in state 1, this allows us to use the
       charclass scan to find a valid start char. This is based on the principle
       that theres a good chance the string being searched contains lots of stuff
       that cant be a start char.
     */
    fail[ 0 ] = fail[ 1 ] = 0;
    DEBUG_TRIE_COMPILE_r({
        PerlIO_printf(Perl_debug_log,
		      "%*sStclass Failtable (%"UVuf" states): 0", 
		      (int)(depth * 2), "", (UV)numstates
        );
        for( q_read=1; q_read<numstates; q_read++ ) {
            PerlIO_printf(Perl_debug_log, ", %"UVuf, (UV)fail[q_read]);
        }
        PerlIO_printf(Perl_debug_log, "\n");
    });
    Safefree(q);
    /*RExC_seen |= REG_SEEN_TRIEDFA;*/
}


/*
 * There are strange code-generation bugs caused on sparc64 by gcc-2.95.2.
 * These need to be revisited when a newer toolchain becomes available.
 */
#if defined(__sparc64__) && defined(__GNUC__)
#   if __GNUC__ < 2 || (__GNUC__ == 2 && __GNUC_MINOR__ < 96)
#       undef  SPARC64_GCC_WORKAROUND
#       define SPARC64_GCC_WORKAROUND 1
#   endif
#endif

#define DEBUG_PEEP(str,scan,depth) \
    DEBUG_OPTIMISE_r({if (scan){ \
       SV * const mysv=sv_newmortal(); \
       regnode *Next = regnext(scan); \
       regprop(RExC_rx, mysv, scan); \
       PerlIO_printf(Perl_debug_log, "%*s" str ">%3d: %s (%d)\n", \
       (int)depth*2, "", REG_NODE_NUM(scan), SvPV_nolen_const(mysv),\
       Next ? (REG_NODE_NUM(Next)) : 0 ); \
   }});





#define JOIN_EXACT(scan,min,flags) \
    if (PL_regkind[OP(scan)] == EXACT) \
        join_exact(pRExC_state,(scan),(min),(flags),NULL,depth+1)

STATIC U32
S_join_exact(pTHX_ RExC_state_t *pRExC_state, regnode *scan, I32 *min, U32 flags,regnode *val, U32 depth) {
    /* Merge several consecutive EXACTish nodes into one. */
    regnode *n = regnext(scan);
    U32 stringok = 1;
    regnode *next = scan + NODE_SZ_STR(scan);
    U32 merged = 0;
    U32 stopnow = 0;
#ifdef DEBUGGING
    regnode *stop = scan;
    GET_RE_DEBUG_FLAGS_DECL;
#else
    PERL_UNUSED_ARG(depth);
#endif
#ifndef EXPERIMENTAL_INPLACESCAN
    PERL_UNUSED_ARG(flags);
    PERL_UNUSED_ARG(val);
#endif
    DEBUG_PEEP("join",scan,depth);
    
    /* Skip NOTHING, merge EXACT*. */
    while (n &&
           ( PL_regkind[OP(n)] == NOTHING ||
             (stringok && (OP(n) == OP(scan))))
           && NEXT_OFF(n)
           && NEXT_OFF(scan) + NEXT_OFF(n) < I16_MAX) {
        
        if (OP(n) == TAIL || n > next)
            stringok = 0;
        if (PL_regkind[OP(n)] == NOTHING) {
            DEBUG_PEEP("skip:",n,depth);
            NEXT_OFF(scan) += NEXT_OFF(n);
            next = n + NODE_STEP_REGNODE;
#ifdef DEBUGGING
            if (stringok)
                stop = n;
#endif
            n = regnext(n);
        }
        else if (stringok) {
            const unsigned int oldl = STR_LEN(scan);
            regnode * const nnext = regnext(n);
            
            DEBUG_PEEP("merg",n,depth);
            
            merged++;
            if (oldl + STR_LEN(n) > U8_MAX)
                break;
            NEXT_OFF(scan) += NEXT_OFF(n);
            STR_LEN(scan) += STR_LEN(n);
            next = n + NODE_SZ_STR(n);
            /* Now we can overwrite *n : */
            Move(STRING(n), STRING(scan) + oldl, STR_LEN(n), char);
#ifdef DEBUGGING
            stop = next - 1;
#endif
            n = nnext;
            if (stopnow) break;
        }

#ifdef EXPERIMENTAL_INPLACESCAN
	if (flags && !NEXT_OFF(n)) {
	    DEBUG_PEEP("atch", val, depth);
	    if (reg_off_by_arg[OP(n)]) {
		ARG_SET(n, val - n);
	    }
	    else {
		NEXT_OFF(n) = val - n;
	    }
	    stopnow = 1;
	}
#endif
    }
    
    if (UTF && ( OP(scan) == EXACTF ) && ( STR_LEN(scan) >= 6 ) ) {
    /*
    Two problematic code points in Unicode casefolding of EXACT nodes:
    
    U+0390 - GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
    U+03B0 - GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
    
    which casefold to
    
    Unicode                      UTF-8
    
    U+03B9 U+0308 U+0301         0xCE 0xB9 0xCC 0x88 0xCC 0x81
    U+03C5 U+0308 U+0301         0xCF 0x85 0xCC 0x88 0xCC 0x81
    
    This means that in case-insensitive matching (or "loose matching",
    as Unicode calls it), an EXACTF of length six (the UTF-8 encoded byte
    length of the above casefolded versions) can match a target string
    of length two (the byte length of UTF-8 encoded U+0390 or U+03B0).
    This would rather mess up the minimum length computation.
    
    What we'll do is to look for the tail four bytes, and then peek
    at the preceding two bytes to see whether we need to decrease
    the minimum length by four (six minus two).
    
    Thanks to the design of UTF-8, there cannot be false matches:
    A sequence of valid UTF-8 bytes cannot be a subsequence of
    another valid sequence of UTF-8 bytes.
    
    */
         char * const s0 = STRING(scan), *s, *t;
         char * const s1 = s0 + STR_LEN(scan) - 1;
         char * const s2 = s1 - 4;
#ifdef EBCDIC /* RD tunifold greek 0390 and 03B0 */
	 const char t0[] = "\xaf\x49\xaf\x42";
#else
         const char t0[] = "\xcc\x88\xcc\x81";
#endif
         const char * const t1 = t0 + 3;
    
         for (s = s0 + 2;
              s < s2 && (t = ninstr(s, s1, t0, t1));
              s = t + 4) {
#ifdef EBCDIC
	      if (((U8)t[-1] == 0x68 && (U8)t[-2] == 0xB4) ||
		  ((U8)t[-1] == 0x46 && (U8)t[-2] == 0xB5))
#else
              if (((U8)t[-1] == 0xB9 && (U8)t[-2] == 0xCE) ||
                  ((U8)t[-1] == 0x85 && (U8)t[-2] == 0xCF))
#endif
                   *min -= 4;
         }
    }
    
#ifdef DEBUGGING
    /* Allow dumping */
    n = scan + NODE_SZ_STR(scan);
    while (n <= stop) {
        if (PL_regkind[OP(n)] != NOTHING || OP(n) == NOTHING) {
            OP(n) = OPTIMIZED;
            NEXT_OFF(n) = 0;
        }
        n++;
    }
#endif
    DEBUG_OPTIMISE_r(if (merged){DEBUG_PEEP("finl",scan,depth)});
    return stopnow;
}

/* REx optimizer.  Converts nodes into quickier variants "in place".
   Finds fixed substrings.  */

/* Stops at toplevel WHILEM as well as at "last". At end *scanp is set
   to the position after last scanned or to NULL. */

#define INIT_AND_WITHP \
    assert(!and_withp); \
    Newx(and_withp,1,struct regnode_charclass_class); \
    SAVEFREEPV(and_withp)

/* this is a chain of data about sub patterns we are processing that
   need to be handled seperately/specially in study_chunk. Its so
   we can simulate recursion without losing state.  */
struct scan_frame;
typedef struct scan_frame {
    regnode *last;  /* last node to process in this frame */
    regnode *next;  /* next node to process when last is reached */
    struct scan_frame *prev; /*previous frame*/
    I32 stop; /* what stopparen do we use */
} scan_frame;

STATIC I32
S_study_chunk(pTHX_ RExC_state_t *pRExC_state, regnode **scanp,
                        I32 *minlenp, I32 *deltap,
			regnode *last,
			scan_data_t *data,
			I32 stopparen,
			U8* recursed,
			struct regnode_charclass_class *and_withp,
			U32 flags, U32 depth)
			/* scanp: Start here (read-write). */
			/* deltap: Write maxlen-minlen here. */
			/* last: Stop before this one. */
			/* data: string data about the pattern */
			/* stopparen: treat close N as END */
			/* recursed: which subroutines have we recursed into */
			/* and_withp: Valid if flags & SCF_DO_STCLASS_OR */
{
    dVAR;
    I32 min = 0, pars = 0, code;
    regnode *scan = *scanp, *next;
    I32 delta = 0;
    int is_inf = (flags & SCF_DO_SUBSTR) && (data->flags & SF_IS_INF);
    int is_inf_internal = 0;		/* The studied chunk is infinite */
    I32 is_par = OP(scan) == OPEN ? ARG(scan) : 0;
    scan_data_t data_fake;
    SV *re_trie_maxbuff = NULL;
    regnode *first_non_open = scan;
    I32 stopmin = I32_MAX;
    scan_frame last_frame= { last, NULL, NULL, stopparen };
    scan_frame *frame=&last_frame;
    
    GET_RE_DEBUG_FLAGS_DECL;
    
#ifdef DEBUGGING
    StructCopy(&zero_scan_data, &data_fake, scan_data_t);
#endif

    if ( depth == 0 ) {
        while (first_non_open && OP(first_non_open) == OPEN)
            first_non_open=regnext(first_non_open);
    }

    while (frame) {

	DEBUG_PEEP("FBEG",scan,depth);
	while ( scan && OP(scan) != END && scan < frame->last ) {
	    /* Peephole optimizer: */
	    DEBUG_STUDYDATA(data,depth);
	    DEBUG_PEEP("Peep",scan,depth);
	    JOIN_EXACT(scan,&min,0);

	    /* Follow the next-chain of the current node and optimize
	       away all the NOTHINGs from it.  */
	    if (OP(scan) != CURLYX) {
		const int max = (reg_off_by_arg[OP(scan)]
			? I32_MAX
			/* I32 may be smaller than U16 on CRAYs! */
			: (I32_MAX < U16_MAX ? I32_MAX : U16_MAX));
		int off = (reg_off_by_arg[OP(scan)] ? ARG(scan) : NEXT_OFF(scan));
		int noff;
		regnode *n = scan;

		/* Skip NOTHING and LONGJMP. */
		while ((n = regnext(n))
			&& ((PL_regkind[OP(n)] == NOTHING && (noff = NEXT_OFF(n)))
			    || ((OP(n) == LONGJMP) && (noff = ARG(n))))
			&& off + noff < max)
		    off += noff;
		if (reg_off_by_arg[OP(scan)])
		    ARG(scan) = off;
		else
		    NEXT_OFF(scan) = off;
	    }

	    /* The principal pseudo-switch.  Cannot be a switch, since we
	       look into several different things.  */
	    if (OP(scan) == BRANCH || OP(scan) == BRANCHJ
		    || OP(scan) == IFTHEN) {
		next = regnext(scan);
		code = OP(scan);
		/* demq: the op(next)==code check is to see if we have "branch-branch" AFAICT */

		if (OP(next) == code || code == IFTHEN) {
		    /* NOTE - There is similar code to this block below for handling
		       TRIE nodes on a re-study.  If you change stuff here check there
		       too. */
		    I32 max1 = 0, min1 = I32_MAX, num = 0;
		    struct regnode_charclass_class accum;
		    regnode * const startbranch=scan;

		    if (flags & SCF_DO_SUBSTR)
			scan_commit(pRExC_state, data, minlenp); /* Cannot merge strings after this. */
		    if (flags & SCF_DO_STCLASS)
			cl_init_zero(pRExC_state, &accum);

		    while (OP(scan) == code) {
			I32 deltanext, minnext, f = 0, fake;
			struct regnode_charclass_class this_class;

			num++;
			data_fake.flags = 0;
			if (data) {
			    data_fake.whilem_c = data->whilem_c;
			    data_fake.last_closep = data->last_closep;
			}
			else
			    data_fake.last_closep = &fake;
			next = regnext(scan);
			scan = NEXTOPER(scan);
			if (code != BRANCH)
			    scan = NEXTOPER(scan);
			if (flags & SCF_DO_STCLASS) {
			    cl_init(pRExC_state, &this_class);
			    data_fake.start_class = &this_class;
			    f = SCF_DO_STCLASS_AND;
			}
			if (flags & SCF_WHILEM_VISITED_POS)
			    f |= SCF_WHILEM_VISITED_POS;

			/* we suppose the run is continuous, last=next...*/
			minnext = study_chunk(pRExC_state, &scan, minlenp, &deltanext,
				next, &data_fake,
				stopparen, recursed, NULL, f,depth+1);
			if (min1 > minnext)
			    min1 = minnext;
			if (max1 < minnext + deltanext)
			    max1 = minnext + deltanext;
			if (deltanext == I32_MAX)
			    is_inf = is_inf_internal = 1;
			scan = next;
			if (data_fake.flags & (SF_HAS_PAR|SF_IN_PAR))
			    pars++;
			if (data_fake.flags & SCF_SEEN_ACCEPT) {
			    if ( stopmin > minnext)
				stopmin = min + min1;
			    flags &= ~SCF_DO_SUBSTR;
			    if (data)
				data->flags |= SCF_SEEN_ACCEPT;
			}
			if (data) {
			    if (data_fake.flags & SF_HAS_EVAL)
				data->flags |= SF_HAS_EVAL;
			    data->whilem_c = data_fake.whilem_c;
			}
			if (flags & SCF_DO_STCLASS)
			    cl_or(pRExC_state, &accum, &this_class);
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
		    if (flags & SCF_DO_STCLASS_OR) {
			cl_or(pRExC_state, data->start_class, &accum);
			if (min1) {
			    cl_and(data->start_class, and_withp);
			    flags &= ~SCF_DO_STCLASS;
			}
		    }
		    else if (flags & SCF_DO_STCLASS_AND) {
			if (min1) {
			    cl_and(data->start_class, &accum);
			    flags &= ~SCF_DO_STCLASS;
			}
			else {
			    /* Switch to OR mode: cache the old value of
			     * data->start_class */
			    INIT_AND_WITHP;
			    StructCopy(data->start_class, and_withp,
				    struct regnode_charclass_class);
			    flags &= ~SCF_DO_STCLASS_AND;
			    StructCopy(&accum, data->start_class,
				    struct regnode_charclass_class);
			    flags |= SCF_DO_STCLASS_OR;
			    data->start_class->flags |= ANYOF_EOS;
			}
		    }

		    if (PERL_ENABLE_TRIE_OPTIMISATION && OP( startbranch ) == BRANCH ) {
			/* demq.

			   Assuming this was/is a branch we are dealing with: 'scan' now
			   points at the item that follows the branch sequence, whatever
			   it is. We now start at the beginning of the sequence and look
			   for subsequences of

			   BRANCH->EXACT=>x1
			   BRANCH->EXACT=>x2
			   tail

			   which would be constructed from a pattern like /A|LIST|OF|WORDS/

			   If we can find such a subseqence we need to turn the first
			   element into a trie and then add the subsequent branch exact
			   strings to the trie.

			   We have two cases

			   1. patterns where the whole set of branch can be converted. 

			   2. patterns where only a subset can be converted.

			   In case 1 we can replace the whole set with a single regop
			   for the trie. In case 2 we need to keep the start and end
			   branchs so

			   'BRANCH EXACT; BRANCH EXACT; BRANCH X'
			   becomes BRANCH TRIE; BRANCH X;

			   There is an additional case, that being where there is a 
			   common prefix, which gets split out into an EXACT like node
			   preceding the TRIE node.

			   If x(1..n)==tail then we can do a simple trie, if not we make
			   a "jump" trie, such that when we match the appropriate word
			   we "jump" to the appopriate tail node. Essentailly we turn
			   a nested if into a case structure of sorts.

			*/

			int made=0;
			if (!re_trie_maxbuff) {
			    re_trie_maxbuff = get_sv(RE_TRIE_MAXBUF_NAME, 1);
			    if (!SvIOK(re_trie_maxbuff))
				sv_setiv(re_trie_maxbuff, RE_TRIE_MAXBUF_INIT);
			}
			if ( SvIV(re_trie_maxbuff)>=0  ) {
			    regnode *cur;
			    regnode *first = (regnode *)NULL;
			    regnode *last = (regnode *)NULL;
			    regnode *tail = scan;
			    U8 optype = 0;
			    U32 count=0;

#ifdef DEBUGGING
			    SV * const mysv = sv_newmortal();       /* for dumping */
#endif
			    /* var tail is used because there may be a TAIL
			       regop in the way. Ie, the exacts will point to the
			       thing following the TAIL, but the last branch will
			       point at the TAIL. So we advance tail. If we
			       have nested (?:) we may have to move through several
			       tails.
			       */

			    while ( OP( tail ) == TAIL ) {
				/* this is the TAIL generated by (?:) */
				tail = regnext( tail );
			    }


			    DEBUG_OPTIMISE_r({
				    regprop(RExC_rx, mysv, tail );
				    PerlIO_printf( Perl_debug_log, "%*s%s%s\n",
					(int)depth * 2 + 2, "", 
					"Looking for TRIE'able sequences. Tail node is: ", 
					SvPV_nolen_const( mysv )
					);
				    });

			    /*

			       step through the branches, cur represents each
			       branch, noper is the first thing to be matched
			       as part of that branch and noper_next is the
			       regnext() of that node. if noper is an EXACT
			       and noper_next is the same as scan (our current
			       position in the regex) then the EXACT branch is
			       a possible optimization target. Once we have
			       two or more consequetive such branches we can
			       create a trie of the EXACT's contents and stich
			       it in place. If the sequence represents all of
			       the branches we eliminate the whole thing and
			       replace it with a single TRIE. If it is a
			       subsequence then we need to stitch it in. This
			       means the first branch has to remain, and needs
			       to be repointed at the item on the branch chain
			       following the last branch optimized. This could
			       be either a BRANCH, in which case the
			       subsequence is internal, or it could be the
			       item following the branch sequence in which
			       case the subsequence is at the end.

*/

			    /* dont use tail as the end marker for this traverse */
			    for ( cur = startbranch ; cur != scan ; cur = regnext( cur ) ) {
				regnode * const noper = NEXTOPER( cur );
#if defined(DEBUGGING) || defined(NOJUMPTRIE)
				regnode * const noper_next = regnext( noper );
#endif

				DEBUG_OPTIMISE_r({
				    regprop(RExC_rx, mysv, cur);
				    PerlIO_printf( Perl_debug_log, "%*s- %s (%d)",
					(int)depth * 2 + 2,"", SvPV_nolen_const( mysv ), REG_NODE_NUM(cur) );

				    regprop(RExC_rx, mysv, noper);
				    PerlIO_printf( Perl_debug_log, " -> %s",
					SvPV_nolen_const(mysv));

				    if ( noper_next ) {
					regprop(RExC_rx, mysv, noper_next );
					PerlIO_printf( Perl_debug_log,"\t=> %s\t",
					    SvPV_nolen_const(mysv));
				    }
				    PerlIO_printf( Perl_debug_log, "(First==%d,Last==%d,Cur==%d)\n",
					REG_NODE_NUM(first), REG_NODE_NUM(last), REG_NODE_NUM(cur) );
				});
				if ( (((first && optype!=NOTHING) ? OP( noper ) == optype
						: PL_regkind[ OP( noper ) ] == EXACT )
					    || OP(noper) == NOTHING )
#ifdef NOJUMPTRIE
					&& noper_next == tail
#endif
					&& count < U16_MAX)
				{
				    count++;
				    if ( !first || optype == NOTHING ) {
					if (!first) first = cur;
					optype = OP( noper );
				    } else {
					last = cur;
				    }
				} else {
				    if ( last ) {
					make_trie( pRExC_state,
						startbranch, first, cur, tail, count,
						optype, depth+1 );
				    }
				    if ( PL_regkind[ OP( noper ) ] == EXACT
#ifdef NOJUMPTRIE
					    && noper_next == tail
#endif
					) {
					count = 1;
					first = cur;
					optype = OP( noper );
				    } else {
					count = 0;
					first = NULL;
					optype = 0;
				    }
				    last = NULL;
				}
			    }
			    DEBUG_OPTIMISE_r({
				    regprop(RExC_rx, mysv, cur);
				    PerlIO_printf( Perl_debug_log,
					"%*s- %s (%d) <SCAN FINISHED>\n", (int)depth * 2 + 2,
					"", SvPV_nolen_const( mysv ),REG_NODE_NUM(cur));

				    });
			    if ( last ) {
				made= make_trie( pRExC_state, startbranch, first, scan, tail, count, optype, depth+1 );
#ifdef TRIE_STUDY_OPT	
				if ( ((made == MADE_EXACT_TRIE &&
						startbranch == first)
					    || ( first_non_open == first )) &&
					depth==0 ) {
				    flags |= SCF_TRIE_RESTUDY;
				    if ( startbranch == first
					    && scan == tail )
				    {
					RExC_seen &=~REG_TOP_LEVEL_BRANCHES;
				    }
				}
#endif
			    }
			}

		    } /* do trie */

		}
		else if ( code == BRANCHJ ) {  /* single branch is optimized. */
		    scan = NEXTOPER(NEXTOPER(scan));
		} else			/* single branch is optimized. */
		    scan = NEXTOPER(scan);
		continue;
	    } else if (OP(scan) == SUSPEND || OP(scan) == GOSUB || OP(scan) == GOSTART) {
		scan_frame *newframe = NULL;
		I32 paren;
		regnode *start;
		regnode *end;

		if (OP(scan) != SUSPEND) {
		    /* set the pointer */
		    if (OP(scan) == GOSUB) {
			paren = ARG(scan);
			RExC_recurse[ARG2L(scan)] = scan;
			start = RExC_open_parens[paren-1];
			end   = RExC_close_parens[paren-1];
		    } else {
			paren = 0;
			start = RExC_rx->program + 1;
			end   = RExC_opend;
		    }
		    if (!recursed) {
			Newxz(recursed, (((RExC_npar)>>3) +1), U8);
			SAVEFREEPV(recursed);
		    }
		    if (!PAREN_TEST(recursed,paren+1)) {
			PAREN_SET(recursed,paren+1);
			Newx(newframe,1,scan_frame);
		    } else {
			if (flags & SCF_DO_SUBSTR) {
			    scan_commit(pRExC_state,data,minlenp);
			    data->longest = &(data->longest_float);
			}
			is_inf = is_inf_internal = 1;
			if (flags & SCF_DO_STCLASS_OR) /* Allow everything */
			    cl_anything(pRExC_state, data->start_class);
			flags &= ~SCF_DO_STCLASS;
		    }
		} else {             
		    Newx(newframe,1,scan_frame);
		    paren = stopparen;
		    start = scan+2;
		    end = regnext(scan);
		}
		if (newframe) {
		    assert(start);
		    assert(end);
		    SAVEFREEPV(newframe);
		    newframe->next = regnext(scan);
		    newframe->last = end;
		    newframe->stop = stopparen;
		    newframe->prev = frame;
		    frame = newframe;
		    scan =  start;
		    stopparen = paren;
		    continue;
		} 
	    }
	    else if (OP(scan) == EXACT) {
		I32 l = STR_LEN(scan);
		UV uc;
		if (UTF) {
		    const U8 * const s = (U8*)STRING(scan);
		    l = utf8_length(s, s + l);
		    uc = utf8_to_uvchr(s, NULL);
		} else {
		    uc = *((U8*)STRING(scan));
		}
		min += l;
		if (flags & SCF_DO_SUBSTR) { /* Update longest substr. */
		    /* The code below prefers earlier match for fixed
		       offset, later match for variable offset.  */
		    if (data->last_end == -1) { /* Update the start info. */
			data->last_start_min = data->pos_min;
			data->last_start_max = is_inf
			    ? I32_MAX : data->pos_min + data->pos_delta;
		    }
		    sv_catpvn(data->last_found, STRING(scan), STR_LEN(scan));
		    if (UTF)
			SvUTF8_on(data->last_found);
		    {
			SV * const sv = data->last_found;
			MAGIC * const mg = SvUTF8(sv) && SvMAGICAL(sv) ?
			    mg_find(sv, PERL_MAGIC_utf8) : NULL;
			if (mg && mg->mg_len >= 0)
			    mg->mg_len += utf8_length((U8*)STRING(scan),
				    (U8*)STRING(scan)+STR_LEN(scan));
		    }
		    data->last_end = data->pos_min + l;
		    data->pos_min += l; /* As in the first entry. */
		    data->flags &= ~SF_BEFORE_EOL;
		}
		if (flags & SCF_DO_STCLASS_AND) {
		    /* Check whether it is compatible with what we know already! */
		    int compat = 1;

		    if (uc >= 0x100 ||
			    (!(data->start_class->flags & (ANYOF_CLASS | ANYOF_LOCALE))
			     && !ANYOF_BITMAP_TEST(data->start_class, uc)
			     && (!(data->start_class->flags & ANYOF_FOLD)
				 || !ANYOF_BITMAP_TEST(data->start_class, PL_fold[uc])))
		       )
			compat = 0;
		    ANYOF_CLASS_ZERO(data->start_class);
		    ANYOF_BITMAP_ZERO(data->start_class);
		    if (compat)
			ANYOF_BITMAP_SET(data->start_class, uc);
		    data->start_class->flags &= ~ANYOF_EOS;
		    if (uc < 0x100)
			data->start_class->flags &= ~ANYOF_UNICODE_ALL;
		}
		else if (flags & SCF_DO_STCLASS_OR) {
		    /* false positive possible if the class is case-folded */
		    if (uc < 0x100)
			ANYOF_BITMAP_SET(data->start_class, uc);
		    else
			data->start_class->flags |= ANYOF_UNICODE_ALL;
		    data->start_class->flags &= ~ANYOF_EOS;
		    cl_and(data->start_class, and_withp);
		}
		flags &= ~SCF_DO_STCLASS;
	    }
	    else if (PL_regkind[OP(scan)] == EXACT) { /* But OP != EXACT! */
		I32 l = STR_LEN(scan);
		UV uc = *((U8*)STRING(scan));

		/* Search for fixed substrings supports EXACT only. */
		if (flags & SCF_DO_SUBSTR) {
		    assert(data);
		    scan_commit(pRExC_state, data, minlenp);
		}
		if (UTF) {
		    const U8 * const s = (U8 *)STRING(scan);
		    l = utf8_length(s, s + l);
		    uc = utf8_to_uvchr(s, NULL);
		}
		min += l;
		if (flags & SCF_DO_SUBSTR)
		    data->pos_min += l;
		if (flags & SCF_DO_STCLASS_AND) {
		    /* Check whether it is compatible with what we know already! */
		    int compat = 1;

		    if (uc >= 0x100 ||
			    (!(data->start_class->flags & (ANYOF_CLASS | ANYOF_LOCALE))
			     && !ANYOF_BITMAP_TEST(data->start_class, uc)
			     && !ANYOF_BITMAP_TEST(data->start_class, PL_fold[uc])))
			compat = 0;
		    ANYOF_CLASS_ZERO(data->start_class);
		    ANYOF_BITMAP_ZERO(data->start_class);
		    if (compat) {
			ANYOF_BITMAP_SET(data->start_class, uc);
			data->start_class->flags &= ~ANYOF_EOS;
			data->start_class->flags |= ANYOF_FOLD;
			if (OP(scan) == EXACTFL)
			    data->start_class->flags |= ANYOF_LOCALE;
		    }
		}
		else if (flags & SCF_DO_STCLASS_OR) {
		    if (data->start_class->flags & ANYOF_FOLD) {
			/* false positive possible if the class is case-folded.
			   Assume that the locale settings are the same... */
			if (uc < 0x100)
			    ANYOF_BITMAP_SET(data->start_class, uc);
			data->start_class->flags &= ~ANYOF_EOS;
		    }
		    cl_and(data->start_class, and_withp);
		}
		flags &= ~SCF_DO_STCLASS;
	    }
	    else if (strchr((const char*)PL_varies,OP(scan))) {
		I32 mincount, maxcount, minnext, deltanext, fl = 0;
		I32 f = flags, pos_before = 0;
		regnode * const oscan = scan;
		struct regnode_charclass_class this_class;
		struct regnode_charclass_class *oclass = NULL;
		I32 next_is_eval = 0;

		switch (PL_regkind[OP(scan)]) {
		    case WHILEM:		/* End of (?:...)* . */
			scan = NEXTOPER(scan);
			goto finish;
		    case PLUS:
			if (flags & (SCF_DO_SUBSTR | SCF_DO_STCLASS)) {
			    next = NEXTOPER(scan);
			    if (OP(next) == EXACT || (flags & SCF_DO_STCLASS)) {
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
			if (flags & SCF_DO_STCLASS) {
			    mincount = 0;
			    maxcount = REG_INFTY;
			    next = regnext(scan);
			    scan = NEXTOPER(scan);
			    goto do_curly;
			}
			is_inf = is_inf_internal = 1;
			scan = regnext(scan);
			if (flags & SCF_DO_SUBSTR) {
			    scan_commit(pRExC_state, data, minlenp); /* Cannot extend fixed substrings */
			    data->longest = &(data->longest_float);
			}
			goto optimize_curly_tail;
		    case CURLY:
			if (stopparen>0 && (OP(scan)==CURLYN || OP(scan)==CURLYM)
				&& (scan->flags == stopparen))
			{
			    mincount = 1;
			    maxcount = 1;
			} else {
			    mincount = ARG1(scan);
			    maxcount = ARG2(scan);
			}
			next = regnext(scan);
			if (OP(scan) == CURLYX) {
			    I32 lp = (data ? *(data->last_closep) : 0);
			    scan->flags = ((lp <= (I32)U8_MAX) ? (U8)lp : U8_MAX);
			}
			scan = NEXTOPER(scan) + EXTRA_STEP_2ARGS;
			next_is_eval = (OP(scan) == EVAL);
do_curly:
			if (flags & SCF_DO_SUBSTR) {
			    if (mincount == 0) scan_commit(pRExC_state,data,minlenp); /* Cannot extend fixed substrings */
			    pos_before = data->pos_min;
			}
			if (data) {
			    fl = data->flags;
			    data->flags &= ~(SF_HAS_PAR|SF_IN_PAR|SF_HAS_EVAL);
			    if (is_inf)
				data->flags |= SF_IS_INF;
			}
			if (flags & SCF_DO_STCLASS) {
			    cl_init(pRExC_state, &this_class);
			    oclass = data->start_class;
			    data->start_class = &this_class;
			    f |= SCF_DO_STCLASS_AND;
			    f &= ~SCF_DO_STCLASS_OR;
			}
			/* These are the cases when once a subexpression
			   fails at a particular position, it cannot succeed
			   even after backtracking at the enclosing scope.

			   XXXX what if minimal match and we are at the
			   initial run of {n,m}? */
			if ((mincount != maxcount - 1) && (maxcount != REG_INFTY))
			    f &= ~SCF_WHILEM_VISITED_POS;

			/* This will finish on WHILEM, setting scan, or on NULL: */
			minnext = study_chunk(pRExC_state, &scan, minlenp, &deltanext, 
				last, data, stopparen, recursed, NULL,
				(mincount == 0
				 ? (f & ~SCF_DO_SUBSTR) : f),depth+1);

			if (flags & SCF_DO_STCLASS)
			    data->start_class = oclass;
			if (mincount == 0 || minnext == 0) {
			    if (flags & SCF_DO_STCLASS_OR) {
				cl_or(pRExC_state, data->start_class, &this_class);
			    }
			    else if (flags & SCF_DO_STCLASS_AND) {
				/* Switch to OR mode: cache the old value of
				 * data->start_class */
				INIT_AND_WITHP;
				StructCopy(data->start_class, and_withp,
					struct regnode_charclass_class);
				flags &= ~SCF_DO_STCLASS_AND;
				StructCopy(&this_class, data->start_class,
					struct regnode_charclass_class);
				flags |= SCF_DO_STCLASS_OR;
				data->start_class->flags |= ANYOF_EOS;
			    }
			} else {		/* Non-zero len */
			    if (flags & SCF_DO_STCLASS_OR) {
				cl_or(pRExC_state, data->start_class, &this_class);
				cl_and(data->start_class, and_withp);
			    }
			    else if (flags & SCF_DO_STCLASS_AND)
				cl_and(data->start_class, &this_class);
			    flags &= ~SCF_DO_STCLASS;
			}
			if (!scan) 		/* It was not CURLYX, but CURLY. */
			    scan = next;
			if ( /* ? quantifier ok, except for (?{ ... }) */
				(next_is_eval || !(mincount == 0 && maxcount == 1))
				&& (minnext == 0) && (deltanext == 0)
				&& data && !(data->flags & (SF_HAS_PAR|SF_IN_PAR))
				&& maxcount <= REG_INFTY/3 /* Complement check for big count */
				&& ckWARN(WARN_REGEXP))
			{
			    vWARN(RExC_parse,
				    "Quantifier unexpected on zero-length expression");
			}

			min += minnext * mincount;
			is_inf_internal |= ((maxcount == REG_INFTY
				    && (minnext + deltanext) > 0)
				|| deltanext == I32_MAX);
			is_inf |= is_inf_internal;
			delta += (minnext + deltanext) * maxcount - minnext * mincount;

			/* Try powerful optimization CURLYX => CURLYN. */
			if (  OP(oscan) == CURLYX && data
				&& data->flags & SF_IN_PAR
				&& !(data->flags & SF_HAS_EVAL)
				&& !deltanext && minnext == 1 ) {
			    /* Try to optimize to CURLYN.  */
			    regnode *nxt = NEXTOPER(oscan) + EXTRA_STEP_2ARGS;
			    regnode * const nxt1 = nxt;
#ifdef DEBUGGING
			    regnode *nxt2;
#endif

			    /* Skip open. */
			    nxt = regnext(nxt);
			    if (!strchr((const char*)PL_simple,OP(nxt))
				    && !(PL_regkind[OP(nxt)] == EXACT
					&& STR_LEN(nxt) == 1))
				goto nogo;
#ifdef DEBUGGING
			    nxt2 = nxt;
#endif
			    nxt = regnext(nxt);
			    if (OP(nxt) != CLOSE)
				goto nogo;
			    if (RExC_open_parens) {
				RExC_open_parens[ARG(nxt1)-1]=oscan; /*open->CURLYM*/
				RExC_close_parens[ARG(nxt1)-1]=nxt+2; /*close->while*/
			    }
			    /* Now we know that nxt2 is the only contents: */
			    oscan->flags = (U8)ARG(nxt);
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
nogo:

			/* Try optimization CURLYX => CURLYM. */
			if (  OP(oscan) == CURLYX && data
				&& !(data->flags & SF_HAS_PAR)
				&& !(data->flags & SF_HAS_EVAL)
				&& !deltanext	/* atom is fixed width */
				&& minnext != 0	/* CURLYM can't handle zero width */
			   ) {
			    /* XXXX How to optimize if data == 0? */
			    /* Optimize to a simpler form.  */
			    regnode *nxt = NEXTOPER(oscan) + EXTRA_STEP_2ARGS; /* OPEN */
			    regnode *nxt2;

			    OP(oscan) = CURLYM;
			    while ( (nxt2 = regnext(nxt)) /* skip over embedded stuff*/
				    && (OP(nxt2) != WHILEM))
				nxt = nxt2;
			    OP(nxt2)  = SUCCEED; /* Whas WHILEM */
			    /* Need to optimize away parenths. */
			    if (data->flags & SF_IN_PAR) {
				/* Set the parenth number.  */
				regnode *nxt1 = NEXTOPER(oscan) + EXTRA_STEP_2ARGS; /* OPEN*/

				if (OP(nxt) != CLOSE)
				    FAIL("Panic opt close");
				oscan->flags = (U8)ARG(nxt);
				if (RExC_open_parens) {
				    RExC_open_parens[ARG(nxt1)-1]=oscan; /*open->CURLYM*/
				    RExC_close_parens[ARG(nxt1)-1]=nxt2+1; /*close->NOTHING*/
				}
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
				study_chunk(pRExC_state, &nxt1, minlenp, &deltanext, nxt,
					NULL, stopparen, recursed, NULL, 0,depth+1);
			    }
			    else
				oscan->flags = 0;
			}
			else if ((OP(oscan) == CURLYX)
				&& (flags & SCF_WHILEM_VISITED_POS)
				/* See the comment on a similar expression above.
				   However, this time it not a subexpression
				   we care about, but the expression itself. */
				&& (maxcount == REG_INFTY)
				&& data && ++data->whilem_c < 16) {
			    /* This stays as CURLYX, we can put the count/of pair. */
			    /* Find WHILEM (as in regexec.c) */
			    regnode *nxt = oscan + NEXT_OFF(oscan);

			    if (OP(PREVOPER(nxt)) == NOTHING) /* LONGJMP */
				nxt += ARG(nxt);
			    PREVOPER(nxt)->flags = (U8)(data->whilem_c
				    | (RExC_whilem_seen << 4)); /* On WHILEM */
			}
			if (data && fl & (SF_HAS_PAR|SF_IN_PAR))
			    pars++;
			if (flags & SCF_DO_SUBSTR) {
			    SV *last_str = NULL;
			    int counted = mincount != 0;

			    if (data->last_end > 0 && mincount != 0) { /* Ends with a string. */
#if defined(SPARC64_GCC_WORKAROUND)
				I32 b = 0;
				STRLEN l = 0;
				const char *s = NULL;
				I32 old = 0;

				if (pos_before >= data->last_start_min)
				    b = pos_before;
				else
				    b = data->last_start_min;

				l = 0;
				s = SvPV_const(data->last_found, l);
				old = b - data->last_start_min;

#else
				I32 b = pos_before >= data->last_start_min
				    ? pos_before : data->last_start_min;
				STRLEN l;
				const char * const s = SvPV_const(data->last_found, l);
				I32 old = b - data->last_start_min;
#endif

				if (UTF)
				    old = utf8_hop((U8*)s, old) - (U8*)s;

				l -= old;
				/* Get the added string: */
				last_str = newSVpvn(s  + old, l);
				if (UTF)
				    SvUTF8_on(last_str);
				if (deltanext == 0 && pos_before == b) {
				    /* What was added is a constant string */
				    if (mincount > 1) {
					SvGROW(last_str, (mincount * l) + 1);
					repeatcpy(SvPVX(last_str) + l,
						SvPVX_const(last_str), l, mincount - 1);
					SvCUR_set(last_str, SvCUR(last_str) * mincount);
					/* Add additional parts. */
					SvCUR_set(data->last_found,
						SvCUR(data->last_found) - l);
					sv_catsv(data->last_found, last_str);
					{
					    SV * sv = data->last_found;
					    MAGIC *mg =
						SvUTF8(sv) && SvMAGICAL(sv) ?
						mg_find(sv, PERL_MAGIC_utf8) : NULL;
					    if (mg && mg->mg_len >= 0)
						mg->mg_len += CHR_SVLEN(last_str);
					}
					data->last_end += l * (mincount - 1);
				    }
				} else {
				    /* start offset must point into the last copy */
				    data->last_start_min += minnext * (mincount - 1);
				    data->last_start_max += is_inf ? I32_MAX
					: (maxcount - 1) * (minnext + data->pos_delta);
				}
			    }
			    /* It is counted once already... */
			    data->pos_min += minnext * (mincount - counted);
			    data->pos_delta += - counted * deltanext +
				(minnext + deltanext) * maxcount - minnext * mincount;
			    if (mincount != maxcount) {
				/* Cannot extend fixed substrings found inside
				   the group.  */
				scan_commit(pRExC_state,data,minlenp);
				if (mincount && last_str) {
				    SV * const sv = data->last_found;
				    MAGIC * const mg = SvUTF8(sv) && SvMAGICAL(sv) ?
					mg_find(sv, PERL_MAGIC_utf8) : NULL;

				    if (mg)
					mg->mg_len = -1;
				    sv_setsv(sv, last_str);
				    data->last_end = data->pos_min;
				    data->last_start_min =
					data->pos_min - CHR_SVLEN(last_str);
				    data->last_start_max = is_inf
					? I32_MAX
					: data->pos_min + data->pos_delta
					- CHR_SVLEN(last_str);
				}
				data->longest = &(data->longest_float);
			    }
			    SvREFCNT_dec(last_str);
			}
			if (data && (fl & SF_HAS_EVAL))
			    data->flags |= SF_HAS_EVAL;
optimize_curly_tail:
			if (OP(oscan) != CURLYX) {
			    while (PL_regkind[OP(next = regnext(oscan))] == NOTHING
				    && NEXT_OFF(next))
				NEXT_OFF(oscan) += NEXT_OFF(next);
			}
			continue;
		    default:			/* REF and CLUMP only? */
			if (flags & SCF_DO_SUBSTR) {
			    scan_commit(pRExC_state,data,minlenp);	/* Cannot expect anything... */
			    data->longest = &(data->longest_float);
			}
			is_inf = is_inf_internal = 1;
			if (flags & SCF_DO_STCLASS_OR)
			    cl_anything(pRExC_state, data->start_class);
			flags &= ~SCF_DO_STCLASS;
			break;
		}
	    }
	    else if (strchr((const char*)PL_simple,OP(scan))) {
		int value = 0;

		if (flags & SCF_DO_SUBSTR) {
		    scan_commit(pRExC_state,data,minlenp);
		    data->pos_min++;
		}
		min++;
		if (flags & SCF_DO_STCLASS) {
		    data->start_class->flags &= ~ANYOF_EOS;	/* No match on empty */

		    /* Some of the logic below assumes that switching
		       locale on will only add false positives. */
		    switch (PL_regkind[OP(scan)]) {
			case SANY:
			default:
do_default:
			    /* Perl_croak(aTHX_ "panic: unexpected simple REx opcode %d", OP(scan)); */
			    if (flags & SCF_DO_STCLASS_OR) /* Allow everything */
				cl_anything(pRExC_state, data->start_class);
			    break;
			case REG_ANY:
			    if (OP(scan) == SANY)
				goto do_default;
			    if (flags & SCF_DO_STCLASS_OR) { /* Everything but \n */
				value = (ANYOF_BITMAP_TEST(data->start_class,'\n')
					|| (data->start_class->flags & ANYOF_CLASS));
				cl_anything(pRExC_state, data->start_class);
			    }
			    if (flags & SCF_DO_STCLASS_AND || !value)
				ANYOF_BITMAP_CLEAR(data->start_class,'\n');
			    break;
			case ANYOF:
			    if (flags & SCF_DO_STCLASS_AND)
				cl_and(data->start_class,
					(struct regnode_charclass_class*)scan);
			    else
				cl_or(pRExC_state, data->start_class,
					(struct regnode_charclass_class*)scan);
			    break;
			case ALNUM:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (!(data->start_class->flags & ANYOF_LOCALE)) {
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_NALNUM);
				    for (value = 0; value < 256; value++)
					if (!isALNUM(value))
					    ANYOF_BITMAP_CLEAR(data->start_class, value);
				}
			    }
			    else {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_SET(data->start_class,ANYOF_ALNUM);
				else {
				    for (value = 0; value < 256; value++)
					if (isALNUM(value))
					    ANYOF_BITMAP_SET(data->start_class, value);
				}
			    }
			    break;
			case ALNUML:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_NALNUM);
			    }
			    else {
				ANYOF_CLASS_SET(data->start_class,ANYOF_ALNUM);
				data->start_class->flags |= ANYOF_LOCALE;
			    }
			    break;
			case NALNUM:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (!(data->start_class->flags & ANYOF_LOCALE)) {
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_ALNUM);
				    for (value = 0; value < 256; value++)
					if (isALNUM(value))
					    ANYOF_BITMAP_CLEAR(data->start_class, value);
				}
			    }
			    else {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_SET(data->start_class,ANYOF_NALNUM);
				else {
				    for (value = 0; value < 256; value++)
					if (!isALNUM(value))
					    ANYOF_BITMAP_SET(data->start_class, value);
				}
			    }
			    break;
			case NALNUML:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_ALNUM);
			    }
			    else {
				data->start_class->flags |= ANYOF_LOCALE;
				ANYOF_CLASS_SET(data->start_class,ANYOF_NALNUM);
			    }
			    break;
			case SPACE:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (!(data->start_class->flags & ANYOF_LOCALE)) {
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_NSPACE);
				    for (value = 0; value < 256; value++)
					if (!isSPACE(value))
					    ANYOF_BITMAP_CLEAR(data->start_class, value);
				}
			    }
			    else {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_SET(data->start_class,ANYOF_SPACE);
				else {
				    for (value = 0; value < 256; value++)
					if (isSPACE(value))
					    ANYOF_BITMAP_SET(data->start_class, value);
				}
			    }
			    break;
			case SPACEL:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_NSPACE);
			    }
			    else {
				data->start_class->flags |= ANYOF_LOCALE;
				ANYOF_CLASS_SET(data->start_class,ANYOF_SPACE);
			    }
			    break;
			case NSPACE:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (!(data->start_class->flags & ANYOF_LOCALE)) {
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_SPACE);
				    for (value = 0; value < 256; value++)
					if (isSPACE(value))
					    ANYOF_BITMAP_CLEAR(data->start_class, value);
				}
			    }
			    else {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_SET(data->start_class,ANYOF_NSPACE);
				else {
				    for (value = 0; value < 256; value++)
					if (!isSPACE(value))
					    ANYOF_BITMAP_SET(data->start_class, value);
				}
			    }
			    break;
			case NSPACEL:
			    if (flags & SCF_DO_STCLASS_AND) {
				if (data->start_class->flags & ANYOF_LOCALE) {
				    ANYOF_CLASS_CLEAR(data->start_class,ANYOF_SPACE);
				    for (value = 0; value < 256; value++)
					if (!isSPACE(value))
					    ANYOF_BITMAP_CLEAR(data->start_class, value);
				}
			    }
			    else {
				data->start_class->flags |= ANYOF_LOCALE;
				ANYOF_CLASS_SET(data->start_class,ANYOF_NSPACE);
			    }
			    break;
			case DIGIT:
			    if (flags & SCF_DO_STCLASS_AND) {
				ANYOF_CLASS_CLEAR(data->start_class,ANYOF_NDIGIT);
				for (value = 0; value < 256; value++)
				    if (!isDIGIT(value))
					ANYOF_BITMAP_CLEAR(data->start_class, value);
			    }
			    else {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_SET(data->start_class,ANYOF_DIGIT);
				else {
				    for (value = 0; value < 256; value++)
					if (isDIGIT(value))
					    ANYOF_BITMAP_SET(data->start_class, value);			
				}
			    }
			    break;
			case NDIGIT:
			    if (flags & SCF_DO_STCLASS_AND) {
				ANYOF_CLASS_CLEAR(data->start_class,ANYOF_DIGIT);
				for (value = 0; value < 256; value++)
				    if (isDIGIT(value))
					ANYOF_BITMAP_CLEAR(data->start_class, value);
			    }
			    else {
				if (data->start_class->flags & ANYOF_LOCALE)
				    ANYOF_CLASS_SET(data->start_class,ANYOF_NDIGIT);
				else {
				    for (value = 0; value < 256; value++)
					if (!isDIGIT(value))
					    ANYOF_BITMAP_SET(data->start_class, value);			
				}
			    }
			    break;
		    }
		    if (flags & SCF_DO_STCLASS_OR)
			cl_and(data->start_class, and_withp);
		    flags &= ~SCF_DO_STCLASS;
		}
	    }
	    else if (PL_regkind[OP(scan)] == EOL && flags & SCF_DO_SUBSTR) {
		data->flags |= (OP(scan) == MEOL
			? SF_BEFORE_MEOL
			: SF_BEFORE_SEOL);
	    }
	    else if (  PL_regkind[OP(scan)] == BRANCHJ
		    /* Lookbehind, or need to calculate parens/evals/stclass: */
		    && (scan->flags || data || (flags & SCF_DO_STCLASS))
		    && (OP(scan) == IFMATCH || OP(scan) == UNLESSM)) {
		if ( !PERL_ENABLE_POSITIVE_ASSERTION_STUDY 
			|| OP(scan) == UNLESSM )
		{
		    /* Negative Lookahead/lookbehind
		       In this case we can't do fixed string optimisation.
		       */

		    I32 deltanext, minnext, fake = 0;
		    regnode *nscan;
		    struct regnode_charclass_class intrnl;
		    int f = 0;

		    data_fake.flags = 0;
		    if (data) {
			data_fake.whilem_c = data->whilem_c;
			data_fake.last_closep = data->last_closep;
		    }
		    else
			data_fake.last_closep = &fake;
		    if ( flags & SCF_DO_STCLASS && !scan->flags
			    && OP(scan) == IFMATCH ) { /* Lookahead */
			cl_init(pRExC_state, &intrnl);
			data_fake.start_class = &intrnl;
			f |= SCF_DO_STCLASS_AND;
		    }
		    if (flags & SCF_WHILEM_VISITED_POS)
			f |= SCF_WHILEM_VISITED_POS;
		    next = regnext(scan);
		    nscan = NEXTOPER(NEXTOPER(scan));
		    minnext = study_chunk(pRExC_state, &nscan, minlenp, &deltanext, 
			    last, &data_fake, stopparen, recursed, NULL, f, depth+1);
		    if (scan->flags) {
			if (deltanext) {
			    vFAIL("Variable length lookbehind not implemented");
			}
			else if (minnext > (I32)U8_MAX) {
			    vFAIL2("Lookbehind longer than %"UVuf" not implemented", (UV)U8_MAX);
			}
			scan->flags = (U8)minnext;
		    }
		    if (data) {
			if (data_fake.flags & (SF_HAS_PAR|SF_IN_PAR))
			    pars++;
			if (data_fake.flags & SF_HAS_EVAL)
			    data->flags |= SF_HAS_EVAL;
			data->whilem_c = data_fake.whilem_c;
		    }
		    if (f & SCF_DO_STCLASS_AND) {
			const int was = (data->start_class->flags & ANYOF_EOS);

			cl_and(data->start_class, &intrnl);
			if (was)
			    data->start_class->flags |= ANYOF_EOS;
		    }
		}
#if PERL_ENABLE_POSITIVE_ASSERTION_STUDY
		else {
		    /* Positive Lookahead/lookbehind
		       In this case we can do fixed string optimisation,
		       but we must be careful about it. Note in the case of
		       lookbehind the positions will be offset by the minimum
		       length of the pattern, something we won't know about
		       until after the recurse.
		       */
		    I32 deltanext, fake = 0;
		    regnode *nscan;
		    struct regnode_charclass_class intrnl;
		    int f = 0;
		    /* We use SAVEFREEPV so that when the full compile 
		       is finished perl will clean up the allocated 
		       minlens when its all done. This was we don't
		       have to worry about freeing them when we know
		       they wont be used, which would be a pain.
		       */
		    I32 *minnextp;
		    Newx( minnextp, 1, I32 );
		    SAVEFREEPV(minnextp);

		    if (data) {
			StructCopy(data, &data_fake, scan_data_t);
			if ((flags & SCF_DO_SUBSTR) && data->last_found) {
			    f |= SCF_DO_SUBSTR;
			    if (scan->flags) 
				scan_commit(pRExC_state, &data_fake,minlenp);
			    data_fake.last_found=newSVsv(data->last_found);
			}
		    }
		    else
			data_fake.last_closep = &fake;
		    data_fake.flags = 0;
		    if (is_inf)
			data_fake.flags |= SF_IS_INF;
		    if ( flags & SCF_DO_STCLASS && !scan->flags
			    && OP(scan) == IFMATCH ) { /* Lookahead */
			cl_init(pRExC_state, &intrnl);
			data_fake.start_class = &intrnl;
			f |= SCF_DO_STCLASS_AND;
		    }
		    if (flags & SCF_WHILEM_VISITED_POS)
			f |= SCF_WHILEM_VISITED_POS;
		    next = regnext(scan);
		    nscan = NEXTOPER(NEXTOPER(scan));

		    *minnextp = study_chunk(pRExC_state, &nscan, minnextp, &deltanext, 
			    last, &data_fake, stopparen, recursed, NULL, f,depth+1);
		    if (scan->flags) {
			if (deltanext) {
			    vFAIL("Variable length lookbehind not implemented");
			}
			else if (*minnextp > (I32)U8_MAX) {
			    vFAIL2("Lookbehind longer than %"UVuf" not implemented", (UV)U8_MAX);
			}
			scan->flags = (U8)*minnextp;
		    }

		    *minnextp += min;

		    if (f & SCF_DO_STCLASS_AND) {
			const int was = (data->start_class->flags & ANYOF_EOS);

			cl_and(data->start_class, &intrnl);
			if (was)
			    data->start_class->flags |= ANYOF_EOS;
		    }
		    if (data) {
			if (data_fake.flags & (SF_HAS_PAR|SF_IN_PAR))
			    pars++;
			if (data_fake.flags & SF_HAS_EVAL)
			    data->flags |= SF_HAS_EVAL;
			data->whilem_c = data_fake.whilem_c;
			if ((flags & SCF_DO_SUBSTR) && data_fake.last_found) {
			    if (RExC_rx->minlen<*minnextp)
				RExC_rx->minlen=*minnextp;
			    scan_commit(pRExC_state, &data_fake, minnextp);
			    SvREFCNT_dec(data_fake.last_found);

			    if ( data_fake.minlen_fixed != minlenp ) 
			    {
				data->offset_fixed= data_fake.offset_fixed;
				data->minlen_fixed= data_fake.minlen_fixed;
				data->lookbehind_fixed+= scan->flags;
			    }
			    if ( data_fake.minlen_float != minlenp )
			    {
				data->minlen_float= data_fake.minlen_float;
				data->offset_float_min=data_fake.offset_float_min;
				data->offset_float_max=data_fake.offset_float_max;
				data->lookbehind_float+= scan->flags;
			    }
			}
		    }


		}
#endif
	    }
	    else if (OP(scan) == OPEN) {
		if (stopparen != (I32)ARG(scan))
		    pars++;
	    }
	    else if (OP(scan) == CLOSE) {
		if (stopparen == (I32)ARG(scan)) {
		    break;
		}
		if ((I32)ARG(scan) == is_par) {
		    next = regnext(scan);

		    if ( next && (OP(next) != WHILEM) && next < last)
			is_par = 0;		/* Disable optimization */
		}
		if (data)
		    *(data->last_closep) = ARG(scan);
	    }
	    else if (OP(scan) == EVAL) {
		if (data)
		    data->flags |= SF_HAS_EVAL;
	    }
	    else if ( PL_regkind[OP(scan)] == ENDLIKE ) {
		if (flags & SCF_DO_SUBSTR) {
		    scan_commit(pRExC_state,data,minlenp);
		    flags &= ~SCF_DO_SUBSTR;
		}
		if (data && OP(scan)==ACCEPT) {
		    data->flags |= SCF_SEEN_ACCEPT;
		    if (stopmin > min)
			stopmin = min;
		}
	    }
	    else if (OP(scan) == LOGICAL && scan->flags == 2) /* Embedded follows */
	    {
		if (flags & SCF_DO_SUBSTR) {
		    scan_commit(pRExC_state,data,minlenp);
		    data->longest = &(data->longest_float);
		}
		is_inf = is_inf_internal = 1;
		if (flags & SCF_DO_STCLASS_OR) /* Allow everything */
		    cl_anything(pRExC_state, data->start_class);
		flags &= ~SCF_DO_STCLASS;
	    }
#ifdef TRIE_STUDY_OPT
#ifdef FULL_TRIE_STUDY
	    else if (PL_regkind[OP(scan)] == TRIE) {
		/* NOTE - There is similar code to this block above for handling
		   BRANCH nodes on the initial study.  If you change stuff here
		   check there too. */
		regnode *trie_node= scan;
		regnode *tail= regnext(scan);
		reg_trie_data *trie = (reg_trie_data*)RExC_rx->data->data[ ARG(scan) ];
		I32 max1 = 0, min1 = I32_MAX;
		struct regnode_charclass_class accum;

		if (flags & SCF_DO_SUBSTR) /* XXXX Add !SUSPEND? */
		    scan_commit(pRExC_state, data,minlenp); /* Cannot merge strings after this. */
		if (flags & SCF_DO_STCLASS)
		    cl_init_zero(pRExC_state, &accum);

		if (!trie->jump) {
		    min1= trie->minlen;
		    max1= trie->maxlen;
		} else {
		    const regnode *nextbranch= NULL;
		    U32 word;

		    for ( word=1 ; word <= trie->wordcount ; word++) 
		    {
			I32 deltanext=0, minnext=0, f = 0, fake;
			struct regnode_charclass_class this_class;

			data_fake.flags = 0;
			if (data) {
			    data_fake.whilem_c = data->whilem_c;
			    data_fake.last_closep = data->last_closep;
			}
			else
			    data_fake.last_closep = &fake;

			if (flags & SCF_DO_STCLASS) {
			    cl_init(pRExC_state, &this_class);
			    data_fake.start_class = &this_class;
			    f = SCF_DO_STCLASS_AND;
			}
			if (flags & SCF_WHILEM_VISITED_POS)
			    f |= SCF_WHILEM_VISITED_POS;

			if (trie->jump[word]) {
			    if (!nextbranch)
				nextbranch = trie_node + trie->jump[0];
			    scan= trie_node + trie->jump[word];
			    /* We go from the jump point to the branch that follows
			       it. Note this means we need the vestigal unused branches
			       even though they arent otherwise used.
			       */
			    minnext = study_chunk(pRExC_state, &scan, minlenp, 
				    &deltanext, (regnode *)nextbranch, &data_fake, 
				    stopparen, recursed, NULL, f,depth+1);
			}
			if (nextbranch && PL_regkind[OP(nextbranch)]==BRANCH)
			    nextbranch= regnext((regnode*)nextbranch);

			if (min1 > (I32)(minnext + trie->minlen))
			    min1 = minnext + trie->minlen;
			if (max1 < (I32)(minnext + deltanext + trie->maxlen))
			    max1 = minnext + deltanext + trie->maxlen;
			if (deltanext == I32_MAX)
			    is_inf = is_inf_internal = 1;

			if (data_fake.flags & (SF_HAS_PAR|SF_IN_PAR))
			    pars++;
			if (data_fake.flags & SCF_SEEN_ACCEPT) {
			    if ( stopmin > min + min1) 
				stopmin = min + min1;
			    flags &= ~SCF_DO_SUBSTR;
			    if (data)
				data->flags |= SCF_SEEN_ACCEPT;
			}
			if (data) {
			    if (data_fake.flags & SF_HAS_EVAL)
				data->flags |= SF_HAS_EVAL;
			    data->whilem_c = data_fake.whilem_c;
			}
			if (flags & SCF_DO_STCLASS)
			    cl_or(pRExC_state, &accum, &this_class);
		    }
		}
		if (flags & SCF_DO_SUBSTR) {
		    data->pos_min += min1;
		    data->pos_delta += max1 - min1;
		    if (max1 != min1 || is_inf)
			data->longest = &(data->longest_float);
		}
		min += min1;
		delta += max1 - min1;
		if (flags & SCF_DO_STCLASS_OR) {
		    cl_or(pRExC_state, data->start_class, &accum);
		    if (min1) {
			cl_and(data->start_class, and_withp);
			flags &= ~SCF_DO_STCLASS;
		    }
		}
		else if (flags & SCF_DO_STCLASS_AND) {
		    if (min1) {
			cl_and(data->start_class, &accum);
			flags &= ~SCF_DO_STCLASS;
		    }
		    else {
			/* Switch to OR mode: cache the old value of
			 * data->start_class */
			INIT_AND_WITHP;
			StructCopy(data->start_class, and_withp,
				struct regnode_charclass_class);
			flags &= ~SCF_DO_STCLASS_AND;
			StructCopy(&accum, data->start_class,
				struct regnode_charclass_class);
			flags |= SCF_DO_STCLASS_OR;
			data->start_class->flags |= ANYOF_EOS;
		    }
		}
		scan= tail;
		continue;
	    }
#else
	    else if (PL_regkind[OP(scan)] == TRIE) {
		reg_trie_data *trie = (reg_trie_data*)RExC_rx->data->data[ ARG(scan) ];
		U8*bang=NULL;

		min += trie->minlen;
		delta += (trie->maxlen - trie->minlen);
		flags &= ~SCF_DO_STCLASS; /* xxx */
		if (flags & SCF_DO_SUBSTR) {
		    scan_commit(pRExC_state,data,minlenp);	/* Cannot expect anything... */
		    data->pos_min += trie->minlen;
		    data->pos_delta += (trie->maxlen - trie->minlen);
		    if (trie->maxlen != trie->minlen)
			data->longest = &(data->longest_float);
		}
		if (trie->jump) /* no more substrings -- for now /grr*/
		    flags &= ~SCF_DO_SUBSTR;
	    }
#endif /* old or new */
#endif /* TRIE_STUDY_OPT */
	    /* Else: zero-length, ignore. */
	    scan = regnext(scan);
	}
	DEBUG_PEEP("FEND",scan,depth);
	scan = frame->next;
	stopparen = frame->stop;
	frame = frame->prev;

    }

  finish:
    *scanp = scan;
    *deltap = is_inf_internal ? I32_MAX : delta;
    if (flags & SCF_DO_SUBSTR && is_inf)
	data->pos_delta = I32_MAX - data->pos_min;
    if (is_par > (I32)U8_MAX)
	is_par = 0;
    if (is_par && pars==1 && data) {
	data->flags |= SF_IN_PAR;
	data->flags &= ~SF_HAS_PAR;
    }
    else if (pars && data) {
	data->flags |= SF_HAS_PAR;
	data->flags &= ~SF_IN_PAR;
    }
    if (flags & SCF_DO_STCLASS_OR)
	cl_and(data->start_class, and_withp);
    if (flags & SCF_TRIE_RESTUDY)
        data->flags |= 	SCF_TRIE_RESTUDY;
    
    DEBUG_STUDYDATA(data,depth);
    
    return min < stopmin ? min : stopmin;
}

STATIC I32
S_add_data(RExC_state_t *pRExC_state, I32 n, const char *s)
{
    if (RExC_rx->data) {
	const U32 count = RExC_rx->data->count;
	Renewc(RExC_rx->data,
	       sizeof(*RExC_rx->data) + sizeof(void*) * (count + n - 1),
	       char, struct reg_data);
	Renew(RExC_rx->data->what, count + n, U8);
	RExC_rx->data->count += n;
    }
    else {
	Newxc(RExC_rx->data, sizeof(*RExC_rx->data) + sizeof(void*) * (n - 1),
	     char, struct reg_data);
	Newx(RExC_rx->data->what, n, U8);
	RExC_rx->data->count = n;
    }
    Copy(s, RExC_rx->data->what + RExC_rx->data->count - n, n, U8);
    return RExC_rx->data->count - n;
}

#ifndef PERL_IN_XSUB_RE
void
Perl_reginitcolors(pTHX)
{
    dVAR;
    const char * const s = PerlEnv_getenv("PERL_RE_COLORS");
    if (s) {
	char *t = savepv(s);
	int i = 0;
	PL_colors[0] = t;
	while (++i < 6) {
	    t = strchr(t, '\t');
	    if (t) {
		*t = '\0';
		PL_colors[i] = ++t;
	    }
	    else
		PL_colors[i] = t = (char *)"";
	}
    } else {
	int i = 0;
	while (i < 6)
	    PL_colors[i++] = (char *)"";
    }
    PL_colorset = 1;
}
#endif


#ifdef TRIE_STUDY_OPT
#define CHECK_RESTUDY_GOTO                                  \
        if (                                                \
              (data.flags & SCF_TRIE_RESTUDY)               \
              && ! restudied++                              \
        )     goto reStudy
#else
#define CHECK_RESTUDY_GOTO
#endif        

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



#ifndef PERL_IN_XSUB_RE
#define RE_ENGINE_PTR &PL_core_reg_engine
#else
extern const struct regexp_engine my_reg_engine;
#define RE_ENGINE_PTR &my_reg_engine
#endif
/* these make a few things look better, to avoid indentation */
#define BEGIN_BLOCK {
#define END_BLOCK }
 
regexp *
Perl_pregcomp(pTHX_ char *exp, char *xend, PMOP *pm)
{
    dVAR;
    GET_RE_DEBUG_FLAGS_DECL;
    DEBUG_r(if (!PL_colorset) reginitcolors());
#ifndef PERL_IN_XSUB_RE
    BEGIN_BLOCK
    /* Dispatch a request to compile a regexp to correct 
       regexp engine. */
    HV * const table = GvHV(PL_hintgv);
    if (table) {
        SV **ptr= hv_fetchs(table, "regcomp", FALSE);
        if (ptr && SvIOK(*ptr) && SvIV(*ptr)) {
            const regexp_engine *eng=INT2PTR(regexp_engine*,SvIV(*ptr));
            DEBUG_COMPILE_r({
                PerlIO_printf(Perl_debug_log, "Using engine %"UVxf"\n",
                    SvIV(*ptr));
            });            
            return CALLREGCOMP_ENG(eng, exp, xend, pm);
        } 
    }
    END_BLOCK
#endif
    BEGIN_BLOCK    
    register regexp *r;
    regnode *scan;
    regnode *first;
    I32 flags;
    I32 minlen = 0;
    I32 sawplus = 0;
    I32 sawopen = 0;
    scan_data_t data;
    RExC_state_t RExC_state;
    RExC_state_t * const pRExC_state = &RExC_state;
#ifdef TRIE_STUDY_OPT    
    int restudied= 0;
    RExC_state_t copyRExC_state;
#endif    
    if (exp == NULL)
	FAIL("NULL regexp argument");

    RExC_utf8 = pm->op_pmdynflags & PMdf_CMP_UTF8;

    RExC_precomp = exp;
    DEBUG_COMPILE_r({
        SV *dsv= sv_newmortal();
        RE_PV_QUOTED_DECL(s, RExC_utf8,
            dsv, RExC_precomp, (xend - exp), 60);
        PerlIO_printf(Perl_debug_log, "%sCompiling REx%s %s\n",
		       PL_colors[4],PL_colors[5],s);
    });
    RExC_flags = pm->op_pmflags;
    RExC_sawback = 0;

    RExC_seen = 0;
    RExC_seen_zerolen = *exp == '^' ? -1 : 0;
    RExC_seen_evals = 0;
    RExC_extralen = 0;

    /* First pass: determine size, legality. */
    RExC_parse = exp;
    RExC_start = exp;
    RExC_end = xend;
    RExC_naughty = 0;
    RExC_npar = 1;
    RExC_cpar = 1;
    RExC_nestroot = 0;
    RExC_size = 0L;
    RExC_emit = &PL_regdummy;
    RExC_whilem_seen = 0;
    RExC_charnames = NULL;
    RExC_open_parens = NULL;
    RExC_close_parens = NULL;
    RExC_opend = NULL;
    RExC_paren_names = NULL;
    RExC_recurse = NULL;
    RExC_recurse_count = 0;

#if 0 /* REGC() is (currently) a NOP at the first pass.
       * Clever compilers notice this and complain. --jhi */
    REGC((U8)REG_MAGIC, (char*)RExC_emit);
#endif
    DEBUG_PARSE_r(PerlIO_printf(Perl_debug_log, "Starting first pass (sizing)\n"));
    if (reg(pRExC_state, 0, &flags,1) == NULL) {
	RExC_precomp = NULL;
	return(NULL);
    }
    DEBUG_PARSE_r({
        PerlIO_printf(Perl_debug_log, 
            "Required size %"IVdf" nodes\n"
            "Starting second pass (creation)\n", 
            (IV)RExC_size);
        RExC_lastnum=0; 
        RExC_lastparse=NULL; 
    });
    /* Small enough for pointer-storage convention?
       If extralen==0, this means that we will not need long jumps. */
    if (RExC_size >= 0x10000L && RExC_extralen)
        RExC_size += RExC_extralen;
    else
	RExC_extralen = 0;
    if (RExC_whilem_seen > 15)
	RExC_whilem_seen = 15;

#ifdef DEBUGGING
    /* Make room for a sentinel value at the end of the program */
    RExC_size++;
#endif

    /* Allocate space and zero-initialize. Note, the two step process 
       of zeroing when in debug mode, thus anything assigned has to 
       happen after that */
    Newxc(r, sizeof(regexp) + (unsigned)RExC_size * sizeof(regnode),
	 char, regexp);
    if (r == NULL)
	FAIL("Regexp out of space");
#ifdef DEBUGGING
    /* avoid reading uninitialized memory in DEBUGGING code in study_chunk() */
    Zero(r, sizeof(regexp) + (unsigned)RExC_size * sizeof(regnode), char);
#endif
    /* initialization begins here */
    r->engine= RE_ENGINE_PTR;
    r->refcnt = 1;
    r->prelen = xend - exp;
    r->precomp = savepvn(RExC_precomp, r->prelen);
    r->subbeg = NULL;
#ifdef PERL_OLD_COPY_ON_WRITE
    r->saved_copy = NULL;
#endif
    r->reganch = pm->op_pmflags & PMf_COMPILETIME;
    r->nparens = RExC_npar - 1;	/* set early to validate backrefs */
    r->lastparen = 0;			/* mg.c reads this.  */

    r->substrs = 0;			/* Useful during FAIL. */
    r->startp = 0;			/* Useful during FAIL. */
    r->endp = 0;			
    r->swap = NULL; 
    r->paren_names = 0;
    
    if (RExC_seen & REG_SEEN_RECURSE) {
        Newxz(RExC_open_parens, RExC_npar,regnode *);
        SAVEFREEPV(RExC_open_parens);
        Newxz(RExC_close_parens,RExC_npar,regnode *);
        SAVEFREEPV(RExC_close_parens);
    }

    /* Useful during FAIL. */
    Newxz(r->offsets, 2*RExC_size+1, U32); /* MJD 20001228 */
    if (r->offsets) {
	r->offsets[0] = RExC_size;
    }
    DEBUG_OFFSETS_r(PerlIO_printf(Perl_debug_log,
                          "%s %"UVuf" bytes for offset annotations.\n",
                          r->offsets ? "Got" : "Couldn't get",
                          (UV)((2*RExC_size+1) * sizeof(U32))));

    RExC_rx = r;

    /* Second pass: emit code. */
    RExC_flags = pm->op_pmflags;	/* don't let top level (?i) bleed */
    RExC_parse = exp;
    RExC_end = xend;
    RExC_naughty = 0;
    RExC_npar = 1;
    RExC_cpar = 1;
    RExC_emit_start = r->program;
    RExC_emit = r->program;
#ifdef DEBUGGING
    /* put a sentinal on the end of the program so we can check for
       overwrites */
    r->program[RExC_size].type = 255;
#endif
    /* Store the count of eval-groups for security checks: */
    RExC_emit->next_off = (RExC_seen_evals > (I32)U16_MAX) ? U16_MAX : (U16)RExC_seen_evals;
    REGC((U8)REG_MAGIC, (char*) RExC_emit++);
    r->data = 0;
    if (reg(pRExC_state, 0, &flags,1) == NULL)
	return(NULL);

    /* XXXX To minimize changes to RE engine we always allocate
       3-units-long substrs field. */
    Newx(r->substrs, 1, struct reg_substr_data);
    if (RExC_recurse_count) {
        Newxz(RExC_recurse,RExC_recurse_count,regnode *);
        SAVEFREEPV(RExC_recurse);
    }

reStudy:
    r->minlen = minlen = sawplus = sawopen = 0;
    Zero(r->substrs, 1, struct reg_substr_data);

#ifdef TRIE_STUDY_OPT
    if ( restudied ) {
        U32 seen=RExC_seen;
        DEBUG_OPTIMISE_r(PerlIO_printf(Perl_debug_log,"Restudying\n"));
        
        RExC_state = copyRExC_state;
        if (seen & REG_TOP_LEVEL_BRANCHES) 
            RExC_seen |= REG_TOP_LEVEL_BRANCHES;
        else
            RExC_seen &= ~REG_TOP_LEVEL_BRANCHES;
        if (data.last_found) {
            SvREFCNT_dec(data.longest_fixed);
	    SvREFCNT_dec(data.longest_float);
	    SvREFCNT_dec(data.last_found);
	}
	StructCopy(&zero_scan_data, &data, scan_data_t);
    } else {
        StructCopy(&zero_scan_data, &data, scan_data_t);
        copyRExC_state = RExC_state;
    }
#else
    StructCopy(&zero_scan_data, &data, scan_data_t);
#endif    

    /* Dig out information for optimizations. */
    r->reganch = pm->op_pmflags & PMf_COMPILETIME; /* Again? */
    pm->op_pmflags = RExC_flags;
    if (UTF)
        r->reganch |= ROPT_UTF8;	/* Unicode in it? */
    r->regstclass = NULL;
    if (RExC_naughty >= 10)	/* Probably an expensive pattern. */
	r->reganch |= ROPT_NAUGHTY;
    scan = r->program + 1;		/* First BRANCH. */

    /* testing for BRANCH here tells us whether there is "must appear"
       data in the pattern. If there is then we can use it for optimisations */
    if (!(RExC_seen & REG_TOP_LEVEL_BRANCHES)) { /*  Only one top-level choice. */
	I32 fake;
	STRLEN longest_float_length, longest_fixed_length;
	struct regnode_charclass_class ch_class; /* pointed to by data */
	int stclass_flag;
	I32 last_close = 0; /* pointed to by data */

	first = scan;
	/* Skip introductions and multiplicators >= 1. */
	while ((OP(first) == OPEN && (sawopen = 1)) ||
	       /* An OR of *one* alternative - should not happen now. */
	    (OP(first) == BRANCH && OP(regnext(first)) != BRANCH) ||
	    /* for now we can't handle lookbehind IFMATCH*/
	    (OP(first) == IFMATCH && !first->flags) || 
	    (OP(first) == PLUS) ||
	    (OP(first) == MINMOD) ||
	       /* An {n,m} with n>0 */
	    (PL_regkind[OP(first)] == CURLY && ARG1(first) > 0) ) 
	{
	        
		if (OP(first) == PLUS)
		    sawplus = 1;
		else
		    first += regarglen[OP(first)];
		if (OP(first) == IFMATCH) {
		    first = NEXTOPER(first);
		    first += EXTRA_STEP_2ARGS;
		} else  /* XXX possible optimisation for /(?=)/  */
		    first = NEXTOPER(first);
	}

	/* Starting-point info. */
      again:
        DEBUG_PEEP("first:",first,0);
        /* Ignore EXACT as we deal with it later. */
	if (PL_regkind[OP(first)] == EXACT) {
	    if (OP(first) == EXACT)
		NOOP;	/* Empty, get anchored substr later. */
	    else if ((OP(first) == EXACTF || OP(first) == EXACTFL))
		r->regstclass = first;
	}
#ifdef TRIE_STCLASS	
	else if (PL_regkind[OP(first)] == TRIE &&
	        ((reg_trie_data *)r->data->data[ ARG(first) ])->minlen>0) 
	{
	    regnode *trie_op;
	    /* this can happen only on restudy */
	    if ( OP(first) == TRIE ) {
                struct regnode_1 *trieop;
                Newxz(trieop,1,struct regnode_1);
                StructCopy(first,trieop,struct regnode_1);
                trie_op=(regnode *)trieop;
            } else {
                struct regnode_charclass *trieop;
                Newxz(trieop,1,struct regnode_charclass);
                StructCopy(first,trieop,struct regnode_charclass);
                trie_op=(regnode *)trieop;
            }
            OP(trie_op)+=2;
            make_trie_failtable(pRExC_state, (regnode *)first, trie_op, 0);
	    r->regstclass = trie_op;
	}
#endif	
	else if (strchr((const char*)PL_simple,OP(first)))
	    r->regstclass = first;
	else if (PL_regkind[OP(first)] == BOUND ||
		 PL_regkind[OP(first)] == NBOUND)
	    r->regstclass = first;
	else if (PL_regkind[OP(first)] == BOL) {
	    r->reganch |= (OP(first) == MBOL
			   ? ROPT_ANCH_MBOL
			   : (OP(first) == SBOL
			      ? ROPT_ANCH_SBOL
			      : ROPT_ANCH_BOL));
	    first = NEXTOPER(first);
	    goto again;
	}
	else if (OP(first) == GPOS) {
	    r->reganch |= ROPT_ANCH_GPOS;
	    first = NEXTOPER(first);
	    goto again;
	}
	else if (!sawopen && (OP(first) == STAR &&
	    PL_regkind[OP(NEXTOPER(first))] == REG_ANY) &&
	    !(r->reganch & ROPT_ANCH) )
	{
	    /* turn .* into ^.* with an implied $*=1 */
	    const int type =
		(OP(NEXTOPER(first)) == REG_ANY)
		    ? ROPT_ANCH_MBOL
		    : ROPT_ANCH_SBOL;
	    r->reganch |= type | ROPT_IMPLICIT;
	    first = NEXTOPER(first);
	    goto again;
	}
	if (sawplus && (!sawopen || !RExC_sawback)
	    && !(RExC_seen & REG_SEEN_EVAL)) /* May examine pos and $& */
	    /* x+ must match at the 1st pos of run of x's */
	    r->reganch |= ROPT_SKIP;

	/* Scan is after the zeroth branch, first is atomic matcher. */
#ifdef TRIE_STUDY_OPT
	DEBUG_PARSE_r(
	    if (!restudied)
	        PerlIO_printf(Perl_debug_log, "first at %"IVdf"\n",
			      (IV)(first - scan + 1))
        );
#else
	DEBUG_PARSE_r(
	    PerlIO_printf(Perl_debug_log, "first at %"IVdf"\n",
	        (IV)(first - scan + 1))
        );
#endif


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
	
	data.longest_fixed = newSVpvs("");
	data.longest_float = newSVpvs("");
	data.last_found = newSVpvs("");
	data.longest = &(data.longest_fixed);
	first = scan;
	if (!r->regstclass) {
	    cl_init(pRExC_state, &ch_class);
	    data.start_class = &ch_class;
	    stclass_flag = SCF_DO_STCLASS_AND;
	} else				/* XXXX Check for BOUND? */
	    stclass_flag = 0;
	data.last_closep = &last_close;
        
	minlen = study_chunk(pRExC_state, &first, &minlen, &fake, scan + RExC_size, /* Up to end */
            &data, -1, NULL, NULL,
            SCF_DO_SUBSTR | SCF_WHILEM_VISITED_POS | stclass_flag,0);

	
        CHECK_RESTUDY_GOTO;


	if ( RExC_npar == 1 && data.longest == &(data.longest_fixed)
	     && data.last_start_min == 0 && data.last_end > 0
	     && !RExC_seen_zerolen
	     && (!(RExC_seen & REG_SEEN_GPOS) || (r->reganch & ROPT_ANCH_GPOS)))
	    r->reganch |= ROPT_CHECK_ALL;
	scan_commit(pRExC_state, &data,&minlen);
	SvREFCNT_dec(data.last_found);

        /* Note that code very similar to this but for anchored string 
           follows immediately below, changes may need to be made to both. 
           Be careful. 
         */
	longest_float_length = CHR_SVLEN(data.longest_float);
	if (longest_float_length
	    || (data.flags & SF_FL_BEFORE_EOL
		&& (!(data.flags & SF_FL_BEFORE_MEOL)
		    || (RExC_flags & PMf_MULTILINE)))) 
        {
            I32 t,ml;

	    if (SvCUR(data.longest_fixed)  /* ok to leave SvCUR */
		&& data.offset_fixed == data.offset_float_min
		&& SvCUR(data.longest_fixed) == SvCUR(data.longest_float))
		    goto remove_float;		/* As in (a)+. */

            /* copy the information about the longest float from the reg_scan_data
               over to the program. */
	    if (SvUTF8(data.longest_float)) {
		r->float_utf8 = data.longest_float;
		r->float_substr = NULL;
	    } else {
		r->float_substr = data.longest_float;
		r->float_utf8 = NULL;
	    }
	    /* float_end_shift is how many chars that must be matched that 
	       follow this item. We calculate it ahead of time as once the
	       lookbehind offset is added in we lose the ability to correctly
	       calculate it.*/
	    ml = data.minlen_float ? *(data.minlen_float) 
	                           : (I32)longest_float_length;
	    r->float_end_shift = ml - data.offset_float_min
	        - longest_float_length + (SvTAIL(data.longest_float) != 0)
	        + data.lookbehind_float;
	    r->float_min_offset = data.offset_float_min - data.lookbehind_float;
	    r->float_max_offset = data.offset_float_max;
	    if (data.offset_float_max < I32_MAX) /* Don't offset infinity */
	        r->float_max_offset -= data.lookbehind_float;
	    
	    t = (data.flags & SF_FL_BEFORE_EOL /* Can't have SEOL and MULTI */
		       && (!(data.flags & SF_FL_BEFORE_MEOL)
			   || (RExC_flags & PMf_MULTILINE)));
	    fbm_compile(data.longest_float, t ? FBMcf_TAIL : 0);
	}
	else {
	  remove_float:
	    r->float_substr = r->float_utf8 = NULL;
	    SvREFCNT_dec(data.longest_float);
	    longest_float_length = 0;
	}

        /* Note that code very similar to this but for floating string 
           is immediately above, changes may need to be made to both. 
           Be careful. 
         */
	longest_fixed_length = CHR_SVLEN(data.longest_fixed);
	if (longest_fixed_length
	    || (data.flags & SF_FIX_BEFORE_EOL /* Cannot have SEOL and MULTI */
		&& (!(data.flags & SF_FIX_BEFORE_MEOL)
		    || (RExC_flags & PMf_MULTILINE)))) 
        {
            I32 t,ml;

            /* copy the information about the longest fixed 
               from the reg_scan_data over to the program. */
	    if (SvUTF8(data.longest_fixed)) {
		r->anchored_utf8 = data.longest_fixed;
		r->anchored_substr = NULL;
	    } else {
		r->anchored_substr = data.longest_fixed;
		r->anchored_utf8 = NULL;
	    }
	    /* fixed_end_shift is how many chars that must be matched that 
	       follow this item. We calculate it ahead of time as once the
	       lookbehind offset is added in we lose the ability to correctly
	       calculate it.*/
            ml = data.minlen_fixed ? *(data.minlen_fixed) 
                                   : (I32)longest_fixed_length;
            r->anchored_end_shift = ml - data.offset_fixed
	        - longest_fixed_length + (SvTAIL(data.longest_fixed) != 0)
	        + data.lookbehind_fixed;
	    r->anchored_offset = data.offset_fixed - data.lookbehind_fixed;

	    t = (data.flags & SF_FIX_BEFORE_EOL /* Can't have SEOL and MULTI */
		 && (!(data.flags & SF_FIX_BEFORE_MEOL)
		     || (RExC_flags & PMf_MULTILINE)));
	    fbm_compile(data.longest_fixed, t ? FBMcf_TAIL : 0);
	}
	else {
	    r->anchored_substr = r->anchored_utf8 = NULL;
	    SvREFCNT_dec(data.longest_fixed);
	    longest_fixed_length = 0;
	}
	if (r->regstclass
	    && (OP(r->regstclass) == REG_ANY || OP(r->regstclass) == SANY))
	    r->regstclass = NULL;
	if ((!(r->anchored_substr || r->anchored_utf8) || r->anchored_offset)
	    && stclass_flag
	    && !(data.start_class->flags & ANYOF_EOS)
	    && !cl_is_anything(data.start_class))
	{
	    const I32 n = add_data(pRExC_state, 1, "f");

	    Newx(RExC_rx->data->data[n], 1,
		struct regnode_charclass_class);
	    StructCopy(data.start_class,
		       (struct regnode_charclass_class*)RExC_rx->data->data[n],
		       struct regnode_charclass_class);
	    r->regstclass = (regnode*)RExC_rx->data->data[n];
	    r->reganch &= ~ROPT_SKIP;	/* Used in find_byclass(). */
	    DEBUG_COMPILE_r({ SV *sv = sv_newmortal();
	              regprop(r, sv, (regnode*)data.start_class);
		      PerlIO_printf(Perl_debug_log,
				    "synthetic stclass \"%s\".\n",
				    SvPVX_const(sv));});
	}

	/* A temporary algorithm prefers floated substr to fixed one to dig more info. */
	if (longest_fixed_length > longest_float_length) {
	    r->check_end_shift = r->anchored_end_shift;
	    r->check_substr = r->anchored_substr;
	    r->check_utf8 = r->anchored_utf8;
	    r->check_offset_min = r->check_offset_max = r->anchored_offset;
	    if (r->reganch & ROPT_ANCH_SINGLE)
		r->reganch |= ROPT_NOSCAN;
	}
	else {
	    r->check_end_shift = r->float_end_shift;
	    r->check_substr = r->float_substr;
	    r->check_utf8 = r->float_utf8;
	    r->check_offset_min = r->float_min_offset;
	    r->check_offset_max = r->float_max_offset;
	}
	/* XXXX Currently intuiting is not compatible with ANCH_GPOS.
	   This should be changed ASAP!  */
	if ((r->check_substr || r->check_utf8) && !(r->reganch & ROPT_ANCH_GPOS)) {
	    r->reganch |= RE_USE_INTUIT;
	    if (SvTAIL(r->check_substr ? r->check_substr : r->check_utf8))
		r->reganch |= RE_INTUIT_TAIL;
	}
	/* XXX Unneeded? dmq (shouldn't as this is handled elsewhere)
	if ( (STRLEN)minlen < longest_float_length )
            minlen= longest_float_length;
        if ( (STRLEN)minlen < longest_fixed_length )
            minlen= longest_fixed_length;     
        */
    }
    else {
	/* Several toplevels. Best we can is to set minlen. */
	I32 fake;
	struct regnode_charclass_class ch_class;
	I32 last_close = 0;
	
	DEBUG_PARSE_r(PerlIO_printf(Perl_debug_log, "\nMulti Top Level\n"));

	scan = r->program + 1;
	cl_init(pRExC_state, &ch_class);
	data.start_class = &ch_class;
	data.last_closep = &last_close;

        
	minlen = study_chunk(pRExC_state, &scan, &minlen, &fake, scan + RExC_size,
	    &data, -1, NULL, NULL, SCF_DO_STCLASS_AND|SCF_WHILEM_VISITED_POS,0);
        
        CHECK_RESTUDY_GOTO;

	r->check_substr = r->check_utf8 = r->anchored_substr = r->anchored_utf8
		= r->float_substr = r->float_utf8 = NULL;
	if (!(data.start_class->flags & ANYOF_EOS)
	    && !cl_is_anything(data.start_class))
	{
	    const I32 n = add_data(pRExC_state, 1, "f");

	    Newx(RExC_rx->data->data[n], 1,
		struct regnode_charclass_class);
	    StructCopy(data.start_class,
		       (struct regnode_charclass_class*)RExC_rx->data->data[n],
		       struct regnode_charclass_class);
	    r->regstclass = (regnode*)RExC_rx->data->data[n];
	    r->reganch &= ~ROPT_SKIP;	/* Used in find_byclass(). */
	    DEBUG_COMPILE_r({ SV* sv = sv_newmortal();
	              regprop(r, sv, (regnode*)data.start_class);
		      PerlIO_printf(Perl_debug_log,
				    "synthetic stclass \"%s\".\n",
				    SvPVX_const(sv));});
	}
    }

    /* Guard against an embedded (?=) or (?<=) with a longer minlen than
       the "real" pattern. */
    DEBUG_OPTIMISE_r({
	PerlIO_printf(Perl_debug_log,"minlen: %"IVdf" r->minlen:%"IVdf"\n",
	    minlen, r->minlen);
    });
    r->minlenret = minlen;
    if (r->minlen < minlen) 
        r->minlen = minlen;
    
    if (RExC_seen & REG_SEEN_GPOS)
	r->reganch |= ROPT_GPOS_SEEN;
    if (RExC_seen & REG_SEEN_LOOKBEHIND)
	r->reganch |= ROPT_LOOKBEHIND_SEEN;
    if (RExC_seen & REG_SEEN_EVAL)
	r->reganch |= ROPT_EVAL_SEEN;
    if (RExC_seen & REG_SEEN_CANY)
	r->reganch |= ROPT_CANY_SEEN;
    if (RExC_seen & REG_SEEN_VERBARG)
	r->reganch |= ROPT_VERBARG_SEEN;
    if (RExC_seen & REG_SEEN_CUTGROUP)
	r->reganch |= ROPT_CUTGROUP_SEEN;
    if (RExC_paren_names)
        r->paren_names = (HV*)SvREFCNT_inc(RExC_paren_names);
    else
        r->paren_names = NULL;
        	
    if (RExC_recurse_count) {
        for ( ; RExC_recurse_count ; RExC_recurse_count-- ) {
            const regnode *scan = RExC_recurse[RExC_recurse_count-1];
            ARG2L_SET( scan, RExC_open_parens[ARG(scan)-1] - scan );
        }
    }
    Newxz(r->startp, RExC_npar, I32);
    Newxz(r->endp, RExC_npar, I32);
    /* assume we don't need to swap parens around before we match */

    DEBUG_DUMP_r({
        PerlIO_printf(Perl_debug_log,"Final program:\n");
        regdump(r);
    });
    DEBUG_OFFSETS_r(if (r->offsets) {
        const U32 len = r->offsets[0];
        U32 i;
        GET_RE_DEBUG_FLAGS_DECL;
        PerlIO_printf(Perl_debug_log, "Offsets: [%"UVuf"]\n\t", (UV)r->offsets[0]);
        for (i = 1; i <= len; i++) {
            if (r->offsets[i*2-1] || r->offsets[i*2])
                PerlIO_printf(Perl_debug_log, "%"UVuf":%"UVuf"[%"UVuf"] ",
                (UV)i, (UV)r->offsets[i*2-1], (UV)r->offsets[i*2]);
            }
        PerlIO_printf(Perl_debug_log, "\n");
    });
    return(r);
    END_BLOCK    
}

#undef CORE_ONLY_BLOCK
#undef END_BLOCK
#undef RE_ENGINE_PTR

#ifndef PERL_IN_XSUB_RE
SV*
Perl_reg_named_buff_sv(pTHX_ SV* namesv)
{
    I32 parno = 0; /* no match */
    if (PL_curpm) {
        const REGEXP * const rx = PM_GETRE(PL_curpm);
        if (rx && rx->paren_names) {            
            HE *he_str = hv_fetch_ent( rx->paren_names, namesv, 0, 0 );
            if (he_str) {
                IV i;
                SV* sv_dat=HeVAL(he_str);
                I32 *nums=(I32*)SvPVX(sv_dat);
                for ( i=0; i<SvIVX(sv_dat); i++ ) {
                    if ((I32)(rx->lastparen) >= nums[i] &&
                        rx->endp[nums[i]] != -1) 
                    {
                        parno = nums[i];
                        break;
                    }
                }
            }
        }
    }
    if ( !parno ) {
        return 0;
    } else {
        GV *gv_paren;
        SV *sv= sv_newmortal();
        Perl_sv_setpvf(aTHX_ sv, "%"IVdf,(IV)parno);
        gv_paren= Perl_gv_fetchsv(aTHX_ sv, GV_ADD, SVt_PVGV);
        return GvSVn(gv_paren);
    }
}
#endif

/* Scans the name of a named buffer from the pattern.
 * If flags is REG_RSN_RETURN_NULL returns null.
 * If flags is REG_RSN_RETURN_NAME returns an SV* containing the name
 * If flags is REG_RSN_RETURN_DATA returns the data SV* corresponding
 * to the parsed name as looked up in the RExC_paren_names hash.
 * If there is an error throws a vFAIL().. type exception.
 */

#define REG_RSN_RETURN_NULL    0
#define REG_RSN_RETURN_NAME    1
#define REG_RSN_RETURN_DATA    2

STATIC SV*
S_reg_scan_name(pTHX_ RExC_state_t *pRExC_state, U32 flags) {
    char *name_start = RExC_parse;
    if ( UTF ) {
	STRLEN numlen;
        while( isIDFIRST_uni(utf8n_to_uvchr((U8*)RExC_parse,
            RExC_end - RExC_parse, &numlen, UTF8_ALLOW_DEFAULT)))
        {
                RExC_parse += numlen;
        }
    } else {
        while( isIDFIRST(*RExC_parse) )
	    RExC_parse++;
    }
    if ( flags ) {
        SV* sv_name = sv_2mortal(Perl_newSVpvn(aTHX_ name_start,
            (int)(RExC_parse - name_start)));
	if (UTF)
            SvUTF8_on(sv_name);
        if ( flags == REG_RSN_RETURN_NAME)
            return sv_name;
        else if (flags==REG_RSN_RETURN_DATA) {
            HE *he_str = NULL;
            SV *sv_dat = NULL;
            if ( ! sv_name )      /* should not happen*/
                Perl_croak(aTHX_ "panic: no svname in reg_scan_name");
            if (RExC_paren_names)
                he_str = hv_fetch_ent( RExC_paren_names, sv_name, 0, 0 );
            if ( he_str )
                sv_dat = HeVAL(he_str);
            if ( ! sv_dat )
                vFAIL("Reference to nonexistent named group");
            return sv_dat;
        }
        else {
            Perl_croak(aTHX_ "panic: bad flag in reg_scan_name");
        }
        /* NOT REACHED */
    }
    return NULL;
}

#define DEBUG_PARSE_MSG(funcname)     DEBUG_PARSE_r({           \
    int rem=(int)(RExC_end - RExC_parse);                       \
    int cut;                                                    \
    int num;                                                    \
    int iscut=0;                                                \
    if (rem>10) {                                               \
        rem=10;                                                 \
        iscut=1;                                                \
    }                                                           \
    cut=10-rem;                                                 \
    if (RExC_lastparse!=RExC_parse)                             \
        PerlIO_printf(Perl_debug_log," >%.*s%-*s",              \
            rem, RExC_parse,                                    \
            cut + 4,                                            \
            iscut ? "..." : "<"                                 \
        );                                                      \
    else                                                        \
        PerlIO_printf(Perl_debug_log,"%16s","");                \
                                                                \
    if (SIZE_ONLY)                                              \
       num=RExC_size;                                           \
    else                                                        \
       num=REG_NODE_NUM(RExC_emit);                             \
    if (RExC_lastnum!=num)                                      \
       PerlIO_printf(Perl_debug_log,"|%4d",num);                \
    else                                                        \
       PerlIO_printf(Perl_debug_log,"|%4s","");                 \
    PerlIO_printf(Perl_debug_log,"|%*s%-4s",                    \
        (int)((depth*2)), "",                                   \
        (funcname)                                              \
    );                                                          \
    RExC_lastnum=num;                                           \
    RExC_lastparse=RExC_parse;                                  \
})



#define DEBUG_PARSE(funcname)     DEBUG_PARSE_r({           \
    DEBUG_PARSE_MSG((funcname));                            \
    PerlIO_printf(Perl_debug_log,"%4s","\n");               \
})
#define DEBUG_PARSE_FMT(funcname,fmt,args)     DEBUG_PARSE_r({           \
    DEBUG_PARSE_MSG((funcname));                            \
    PerlIO_printf(Perl_debug_log,fmt "\n",args);               \
})
/*
 - reg - regular expression, i.e. main body or parenthesized thing
 *
 * Caller must absorb opening parenthesis.
 *
 * Combining parenthesis handling with the base level of regular expression
 * is a trifle forced, but the need to tie the tails of the branches to what
 * follows makes it hard to avoid.
 */
#define REGTAIL(x,y,z) regtail((x),(y),(z),depth+1)
#ifdef DEBUGGING
#define REGTAIL_STUDY(x,y,z) regtail_study((x),(y),(z),depth+1)
#else
#define REGTAIL_STUDY(x,y,z) regtail((x),(y),(z),depth+1)
#endif

/* this idea is borrowed from STR_WITH_LEN in handy.h */
#define CHECK_WORD(s,v,l)  \
    (((sizeof(s)-1)==(l)) && (strnEQ(start_verb, (s ""), (sizeof(s)-1))))

STATIC regnode *
S_reg(pTHX_ RExC_state_t *pRExC_state, I32 paren, I32 *flagp,U32 depth)
    /* paren: Parenthesized? 0=top, 1=(, inside: changed to letter. */
{
    dVAR;
    register regnode *ret;		/* Will be the head of the group. */
    register regnode *br;
    register regnode *lastbr;
    register regnode *ender = NULL;
    register I32 parno = 0;
    I32 flags;
    const I32 oregflags = RExC_flags;
    bool have_branch = 0;
    bool is_open = 0;

    /* for (?g), (?gc), and (?o) warnings; warning
       about (?c) will warn about (?g) -- japhy    */

#define WASTED_O  0x01
#define WASTED_G  0x02
#define WASTED_C  0x04
#define WASTED_GC (0x02|0x04)
    I32 wastedflags = 0x00;

    char * parse_start = RExC_parse; /* MJD */
    char * const oregcomp_parse = RExC_parse;

    GET_RE_DEBUG_FLAGS_DECL;
    DEBUG_PARSE("reg ");


    *flagp = 0;				/* Tentatively. */


    /* Make an OPEN node, if parenthesized. */
    if (paren) {
        if ( *RExC_parse == '*') { /* (*VERB:ARG) */
	    char *start_verb = RExC_parse;
	    STRLEN verb_len = 0;
	    char *start_arg = NULL;
	    unsigned char op = 0;
	    int argok = 1;
	    int internal_argval = 0; /* internal_argval is only useful if !argok */
	    while ( *RExC_parse && *RExC_parse != ')' ) {
	        if ( *RExC_parse == ':' ) {
	            start_arg = RExC_parse + 1;
	            break;
	        }
	        RExC_parse++;
	    }
	    ++start_verb;
	    verb_len = RExC_parse - start_verb;
	    if ( start_arg ) {
	        RExC_parse++;
	        while ( *RExC_parse && *RExC_parse != ')' ) 
	            RExC_parse++;
	        if ( *RExC_parse != ')' ) 
	            vFAIL("Unterminated verb pattern argument");
	        if ( RExC_parse == start_arg )
	            start_arg = NULL;
	    } else {
	        if ( *RExC_parse != ')' )
	            vFAIL("Unterminated verb pattern");
	    }
	    
	    switch ( *start_verb ) {
            case 'A':  /* (*ACCEPT) */
                if ( CHECK_WORD("ACCEPT",start_verb,verb_len) ) {
		    op = ACCEPT;
		    internal_argval = RExC_nestroot;
		}
		break;
            case 'C':  /* (*COMMIT) */
                if ( CHECK_WORD("COMMIT",start_verb,verb_len) )
                    op = COMMIT;
                break;
            case 'F':  /* (*FAIL) */
                if ( verb_len==1 || CHECK_WORD("FAIL",start_verb,verb_len) ) {
		    op = OPFAIL;
		    argok = 0;
		}
		break;
            case ':':  /* (*:NAME) */
	    case 'M':  /* (*MARK:NAME) */
	        if ( verb_len==0 || CHECK_WORD("MARK",start_verb,verb_len) ) {
                    op = MARKPOINT;
                    argok = -1;
                }
                break;
            case 'P':  /* (*PRUNE) */
                if ( CHECK_WORD("PRUNE",start_verb,verb_len) )
                    op = PRUNE;
                break;
            case 'S':   /* (*SKIP) */  
                if ( CHECK_WORD("SKIP",start_verb,verb_len) ) 
                    op = SKIP;
                break;
            case 'T':  /* (*THEN) */
                /* [19:06] <TimToady> :: is then */
                if ( CHECK_WORD("THEN",start_verb,verb_len) ) {
                    op = CUTGROUP;
                    RExC_seen |= REG_SEEN_CUTGROUP;
                }
                break;
	    }
	    if ( ! op ) {
	        RExC_parse++;
	        vFAIL3("Unknown verb pattern '%.*s'",
	            verb_len, start_verb);
	    }
	    if ( argok ) {
                if ( start_arg && internal_argval ) {
	            vFAIL3("Verb pattern '%.*s' may not have an argument",
	                verb_len, start_verb); 
	        } else if ( argok < 0 && !start_arg ) {
                    vFAIL3("Verb pattern '%.*s' has a mandatory argument",
	                verb_len, start_verb);    
	        } else {
	            ret = reganode(pRExC_state, op, internal_argval);
	            if ( ! internal_argval && ! SIZE_ONLY ) {
                        if (start_arg) {
                            SV *sv = newSVpvn( start_arg, RExC_parse - start_arg);
                            ARG(ret) = add_data( pRExC_state, 1, "S" );
                            RExC_rx->data->data[ARG(ret)]=(void*)sv;
                            ret->flags = 0;
                        } else {
                            ret->flags = 1; 
                        }
                    }	            
	        }
	        if (!internal_argval)
	            RExC_seen |= REG_SEEN_VERBARG;
	    } else if ( start_arg ) {
	        vFAIL3("Verb pattern '%.*s' may not have an argument",
	                verb_len, start_verb);    
	    } else {
	        ret = reg_node(pRExC_state, op);
	    }
	    nextchar(pRExC_state);
	    return ret;
        } else 
	if (*RExC_parse == '?') { /* (?...) */
	    U32 posflags = 0, negflags = 0;
	    U32 *flagsp = &posflags;
	    bool is_logical = 0;
	    const char * const seqstart = RExC_parse;

	    RExC_parse++;
	    paren = *RExC_parse++;
	    ret = NULL;			/* For look-ahead/behind. */
	    switch (paren) {

	    case '<':           /* (?<...) */
		if (*RExC_parse == '!')
		    paren = ',';
		else if (*RExC_parse != '=') 
		{               /* (?<...>) */
		    char *name_start;
		    SV *svname;
		    paren= '>';
            case '\'':          /* (?'...') */
    		    name_start= RExC_parse;
    		    svname = reg_scan_name(pRExC_state,
    		        SIZE_ONLY ?  /* reverse test from the others */
    		        REG_RSN_RETURN_NAME : 
    		        REG_RSN_RETURN_NULL);
		    if (RExC_parse == name_start)
		        goto unknown;
		    if (*RExC_parse != paren)
		        vFAIL2("Sequence (?%c... not terminated",
		            paren=='>' ? '<' : paren);
		    if (SIZE_ONLY) {
			HE *he_str;
			SV *sv_dat = NULL;
                        if (!svname) /* shouldnt happen */
                            Perl_croak(aTHX_
                                "panic: reg_scan_name returned NULL");
                        if (!RExC_paren_names) {
                            RExC_paren_names= newHV();
                            sv_2mortal((SV*)RExC_paren_names);
                        }
                        he_str = hv_fetch_ent( RExC_paren_names, svname, 1, 0 );
                        if ( he_str )
                            sv_dat = HeVAL(he_str);
                        if ( ! sv_dat ) {
                            /* croak baby croak */
                            Perl_croak(aTHX_
                                "panic: paren_name hash element allocation failed");
                        } else if ( SvPOK(sv_dat) ) {
                            IV count=SvIV(sv_dat);
                            I32 *pv=(I32*)SvGROW(sv_dat,SvCUR(sv_dat)+sizeof(I32)+1);
                            SvCUR_set(sv_dat,SvCUR(sv_dat)+sizeof(I32));
                            pv[count]=RExC_npar;
                            SvIVX(sv_dat)++;
                        } else {
                            (void)SvUPGRADE(sv_dat,SVt_PVNV);
                            sv_setpvn(sv_dat, (char *)&(RExC_npar), sizeof(I32));
                            SvIOK_on(sv_dat);
                            SvIVX(sv_dat)= 1;
                        }

                        /*sv_dump(sv_dat);*/
                    }
                    nextchar(pRExC_state);
		    paren = 1;
		    goto capturing_parens;
		}
                RExC_seen |= REG_SEEN_LOOKBEHIND;
		RExC_parse++;
	    case '=':           /* (?=...) */
	    case '!':           /* (?!...) */
		RExC_seen_zerolen++;
	        if (*RExC_parse == ')') {
	            ret=reg_node(pRExC_state, OPFAIL);
	            nextchar(pRExC_state);
	            return ret;
	        }
	    case ':':           /* (?:...) */
	    case '>':           /* (?>...) */
		break;
	    case '$':           /* (?$...) */
	    case '@':           /* (?@...) */
		vFAIL2("Sequence (?%c...) not implemented", (int)paren);
		break;
	    case '#':           /* (?#...) */
		while (*RExC_parse && *RExC_parse != ')')
		    RExC_parse++;
		if (*RExC_parse != ')')
		    FAIL("Sequence (?#... not terminated");
		nextchar(pRExC_state);
		*flagp = TRYAGAIN;
		return NULL;
	    case '0' :           /* (?0) */
	    case 'R' :           /* (?R) */
		if (*RExC_parse != ')')
		    FAIL("Sequence (?R) not terminated");
		ret = reg_node(pRExC_state, GOSTART);
		nextchar(pRExC_state);
		return ret;
		/*notreached*/
            { /* named and numeric backreferences */
                I32 num;
                char * parse_start;
            case '&':            /* (?&NAME) */
                parse_start = RExC_parse - 1;
                {
    		    SV *sv_dat = reg_scan_name(pRExC_state,
    		        SIZE_ONLY ? REG_RSN_RETURN_NULL : REG_RSN_RETURN_DATA);
    		     num = sv_dat ? *((I32 *)SvPVX(sv_dat)) : 0;
                }
                goto gen_recurse_regop;
                /* NOT REACHED */
            case '+':
                if (!(RExC_parse[0] >= '1' && RExC_parse[0] <= '9')) {
                    RExC_parse++;
                    vFAIL("Illegal pattern");
                }
                goto parse_recursion;
                /* NOT REACHED*/
            case '-': /* (?-1) */
                if (!(RExC_parse[0] >= '1' && RExC_parse[0] <= '9')) {
                    RExC_parse--; /* rewind to let it be handled later */
                    goto parse_flags;
                } 
                /*FALLTHROUGH */
            case '1': case '2': case '3': case '4': /* (?1) */
	    case '5': case '6': case '7': case '8': case '9':
	        RExC_parse--;
              parse_recursion:
		num = atoi(RExC_parse);
  	        parse_start = RExC_parse - 1; /* MJD */
	        if (*RExC_parse == '-')
	            RExC_parse++;
		while (isDIGIT(*RExC_parse))
			RExC_parse++;
	        if (*RExC_parse!=')') 
	            vFAIL("Expecting close bracket");
			
              gen_recurse_regop:
                if ( paren == '-' ) {
                    /*
                    Diagram of capture buffer numbering.
                    Top line is the normal capture buffer numbers
                    Botton line is the negative indexing as from
                    the X (the (?-2))

                    +   1 2    3 4 5 X          6 7
                       /(a(x)y)(a(b(c(?-2)d)e)f)(g(h))/
                    -   5 4    3 2 1 X          x x

                    */
                    num = RExC_npar + num;
                    if (num < 1)  {
                        RExC_parse++;
                        vFAIL("Reference to nonexistent group");
                    }
                } else if ( paren == '+' ) {
                    num = RExC_npar + num - 1;
                }

                ret = reganode(pRExC_state, GOSUB, num);
                if (!SIZE_ONLY) {
		    if (num > (I32)RExC_rx->nparens) {
			RExC_parse++;
			vFAIL("Reference to nonexistent group");
	            }
	            ARG2L_SET( ret, RExC_recurse_count++);
                    RExC_emit++;
		    DEBUG_OPTIMISE_MORE_r(PerlIO_printf(Perl_debug_log,
			"Recurse #%"UVuf" to %"IVdf"\n", (UV)ARG(ret), (IV)ARG2L(ret)));
		} else {
		    RExC_size++;
    		}
    		RExC_seen |= REG_SEEN_RECURSE;
                Set_Node_Length(ret, 1 + regarglen[OP(ret)]); /* MJD */
		Set_Node_Offset(ret, parse_start); /* MJD */

                nextchar(pRExC_state);
                return ret;
            } /* named and numeric backreferences */
            /* NOT REACHED */

	    case 'p':           /* (?p...) */
		if (SIZE_ONLY && ckWARN2(WARN_DEPRECATED, WARN_REGEXP))
		    vWARNdep(RExC_parse, "(?p{}) is deprecated - use (??{})");
		/* FALL THROUGH*/
	    case '?':           /* (??...) */
		is_logical = 1;
		if (*RExC_parse != '{')
		    goto unknown;
		paren = *RExC_parse++;
		/* FALL THROUGH */
	    case '{':           /* (?{...}) */
	    {
		I32 count = 1, n = 0;
		char c;
		char *s = RExC_parse;

		RExC_seen_zerolen++;
		RExC_seen |= REG_SEEN_EVAL;
		while (count && (c = *RExC_parse)) {
		    if (c == '\\') {
			if (RExC_parse[1])
			    RExC_parse++;
		    }
		    else if (c == '{')
			count++;
		    else if (c == '}')
			count--;
		    RExC_parse++;
		}
		if (*RExC_parse != ')') {
		    RExC_parse = s;		
		    vFAIL("Sequence (?{...}) not terminated or not {}-balanced");
		}
		if (!SIZE_ONLY) {
		    PAD *pad;
		    OP_4tree *sop, *rop;
		    SV * const sv = newSVpvn(s, RExC_parse - 1 - s);

		    ENTER;
		    Perl_save_re_context(aTHX);
		    rop = sv_compile_2op(sv, &sop, "re", &pad);
		    sop->op_private |= OPpREFCOUNTED;
		    /* re_dup will OpREFCNT_inc */
		    OpREFCNT_set(sop, 1);
		    LEAVE;

		    n = add_data(pRExC_state, 3, "nop");
		    RExC_rx->data->data[n] = (void*)rop;
		    RExC_rx->data->data[n+1] = (void*)sop;
		    RExC_rx->data->data[n+2] = (void*)pad;
		    SvREFCNT_dec(sv);
		}
		else {						/* First pass */
		    if (PL_reginterp_cnt < ++RExC_seen_evals
			&& IN_PERL_RUNTIME)
			/* No compiled RE interpolated, has runtime
			   components ===> unsafe.  */
			FAIL("Eval-group not allowed at runtime, use re 'eval'");
		    if (PL_tainting && PL_tainted)
			FAIL("Eval-group in insecure regular expression");
#if PERL_VERSION > 8
		    if (IN_PERL_COMPILETIME)
			PL_cv_has_eval = 1;
#endif
		}

		nextchar(pRExC_state);
		if (is_logical) {
		    ret = reg_node(pRExC_state, LOGICAL);
		    if (!SIZE_ONLY)
			ret->flags = 2;
                    REGTAIL(pRExC_state, ret, reganode(pRExC_state, EVAL, n));
                    /* deal with the length of this later - MJD */
		    return ret;
		}
		ret = reganode(pRExC_state, EVAL, n);
		Set_Node_Length(ret, RExC_parse - parse_start + 1);
		Set_Node_Offset(ret, parse_start);
		return ret;
	    }
	    case '(':           /* (?(?{...})...) and (?(?=...)...) */
	    {
	        int is_define= 0;
		if (RExC_parse[0] == '?') {        /* (?(?...)) */
		    if (RExC_parse[1] == '=' || RExC_parse[1] == '!'
			|| RExC_parse[1] == '<'
			|| RExC_parse[1] == '{') { /* Lookahead or eval. */
			I32 flag;
			
			ret = reg_node(pRExC_state, LOGICAL);
			if (!SIZE_ONLY)
			    ret->flags = 1;
                        REGTAIL(pRExC_state, ret, reg(pRExC_state, 1, &flag,depth+1));
			goto insert_if;
		    }
		}
		else if ( RExC_parse[0] == '<'     /* (?(<NAME>)...) */
		         || RExC_parse[0] == '\'' ) /* (?('NAME')...) */
	        {
	            char ch = RExC_parse[0] == '<' ? '>' : '\'';
	            char *name_start= RExC_parse++;
	            I32 num = 0;
	            SV *sv_dat=reg_scan_name(pRExC_state,
	                SIZE_ONLY ? REG_RSN_RETURN_NULL : REG_RSN_RETURN_DATA);
	            if (RExC_parse == name_start || *RExC_parse != ch)
                        vFAIL2("Sequence (?(%c... not terminated",
                            (ch == '>' ? '<' : ch));
                    RExC_parse++;
	            if (!SIZE_ONLY) {
                        num = add_data( pRExC_state, 1, "S" );
                        RExC_rx->data->data[num]=(void*)sv_dat;
                        SvREFCNT_inc(sv_dat);
                    }
                    ret = reganode(pRExC_state,NGROUPP,num);
                    goto insert_if_check_paren;
		}
		else if (RExC_parse[0] == 'D' &&
		         RExC_parse[1] == 'E' &&
		         RExC_parse[2] == 'F' &&
		         RExC_parse[3] == 'I' &&
		         RExC_parse[4] == 'N' &&
		         RExC_parse[5] == 'E')
		{
		    ret = reganode(pRExC_state,DEFINEP,0);
		    RExC_parse +=6 ;
		    is_define = 1;
		    goto insert_if_check_paren;
		}
		else if (RExC_parse[0] == 'R') {
		    RExC_parse++;
		    parno = 0;
		    if (RExC_parse[0] >= '1' && RExC_parse[0] <= '9' ) {
		        parno = atoi(RExC_parse++);
		        while (isDIGIT(*RExC_parse))
			    RExC_parse++;
		    } else if (RExC_parse[0] == '&') {
		        SV *sv_dat;
		        RExC_parse++;
		        sv_dat = reg_scan_name(pRExC_state,
    		            SIZE_ONLY ? REG_RSN_RETURN_NULL : REG_RSN_RETURN_DATA);
    		        parno = sv_dat ? *((I32 *)SvPVX(sv_dat)) : 0;
		    }
		    ret = reganode(pRExC_state,INSUBP,parno); 
		    goto insert_if_check_paren;
		}
		else if (RExC_parse[0] >= '1' && RExC_parse[0] <= '9' ) {
                    /* (?(1)...) */
		    char c;
		    parno = atoi(RExC_parse++);

		    while (isDIGIT(*RExC_parse))
			RExC_parse++;
                    ret = reganode(pRExC_state, GROUPP, parno);

                 insert_if_check_paren:
		    if ((c = *nextchar(pRExC_state)) != ')')
			vFAIL("Switch condition not recognized");
		  insert_if:
                    REGTAIL(pRExC_state, ret, reganode(pRExC_state, IFTHEN, 0));
                    br = regbranch(pRExC_state, &flags, 1,depth+1);
		    if (br == NULL)
			br = reganode(pRExC_state, LONGJMP, 0);
		    else
                        REGTAIL(pRExC_state, br, reganode(pRExC_state, LONGJMP, 0));
		    c = *nextchar(pRExC_state);
		    if (flags&HASWIDTH)
			*flagp |= HASWIDTH;
		    if (c == '|') {
		        if (is_define) 
		            vFAIL("(?(DEFINE)....) does not allow branches");
			lastbr = reganode(pRExC_state, IFTHEN, 0); /* Fake one for optimizer. */
                        regbranch(pRExC_state, &flags, 1,depth+1);
                        REGTAIL(pRExC_state, ret, lastbr);
		 	if (flags&HASWIDTH)
			    *flagp |= HASWIDTH;
			c = *nextchar(pRExC_state);
		    }
		    else
			lastbr = NULL;
		    if (c != ')')
			vFAIL("Switch (?(condition)... contains too many branches");
		    ender = reg_node(pRExC_state, TAIL);
                    REGTAIL(pRExC_state, br, ender);
		    if (lastbr) {
                        REGTAIL(pRExC_state, lastbr, ender);
                        REGTAIL(pRExC_state, NEXTOPER(NEXTOPER(lastbr)), ender);
		    }
		    else
                        REGTAIL(pRExC_state, ret, ender);
		    return ret;
		}
		else {
		    vFAIL2("Unknown switch condition (?(%.2s", RExC_parse);
		}
	    }
            case 0:
		RExC_parse--; /* for vFAIL to print correctly */
                vFAIL("Sequence (? incomplete");
                break;
	    default:
		--RExC_parse;
	      parse_flags:      /* (?i) */
		while (*RExC_parse && strchr("iogcmsx", *RExC_parse)) {
		    /* (?g), (?gc) and (?o) are useless here
		       and must be globally applied -- japhy */

		    if (*RExC_parse == 'o' || *RExC_parse == 'g') {
			if (SIZE_ONLY && ckWARN(WARN_REGEXP)) {
			    const I32 wflagbit = *RExC_parse == 'o' ? WASTED_O : WASTED_G;
			    if (! (wastedflags & wflagbit) ) {
				wastedflags |= wflagbit;
				vWARN5(
				    RExC_parse + 1,
				    "Useless (%s%c) - %suse /%c modifier",
				    flagsp == &negflags ? "?-" : "?",
				    *RExC_parse,
				    flagsp == &negflags ? "don't " : "",
				    *RExC_parse
				);
			    }
			}
		    }
		    else if (*RExC_parse == 'c') {
			if (SIZE_ONLY && ckWARN(WARN_REGEXP)) {
			    if (! (wastedflags & WASTED_C) ) {
				wastedflags |= WASTED_GC;
				vWARN3(
				    RExC_parse + 1,
				    "Useless (%sc) - %suse /gc modifier",
				    flagsp == &negflags ? "?-" : "?",
				    flagsp == &negflags ? "don't " : ""
				);
			    }
			}
		    }
		    else { pmflag(flagsp, *RExC_parse); }

		    ++RExC_parse;
		}
		if (*RExC_parse == '-') {
		    flagsp = &negflags;
		    wastedflags = 0;  /* reset so (?g-c) warns twice */
		    ++RExC_parse;
		    goto parse_flags;
		}
		RExC_flags |= posflags;
		RExC_flags &= ~negflags;
		if (*RExC_parse == ':') {
		    RExC_parse++;
		    paren = ':';
		    break;
		}		
	      unknown:
		if (*RExC_parse != ')') {
		    RExC_parse++;
		    vFAIL3("Sequence (%.*s...) not recognized", RExC_parse-seqstart, seqstart);
		}
		nextchar(pRExC_state);
		*flagp = TRYAGAIN;
		return NULL;
	    }
	}
	else {                  /* (...) */
	  capturing_parens:
	    parno = RExC_npar;
	    RExC_npar++;
	    
	    ret = reganode(pRExC_state, OPEN, parno);
	    if (!SIZE_ONLY ){
	        if (!RExC_nestroot) 
	            RExC_nestroot = parno;
	        if (RExC_seen & REG_SEEN_RECURSE) {
		    DEBUG_OPTIMISE_MORE_r(PerlIO_printf(Perl_debug_log,
			"Setting open paren #%"IVdf" to %d\n", 
			(IV)parno, REG_NODE_NUM(ret)));
	            RExC_open_parens[parno-1]= ret;
	        }
	    }
            Set_Node_Length(ret, 1); /* MJD */
            Set_Node_Offset(ret, RExC_parse); /* MJD */
	    is_open = 1;
	}
    }
    else                        /* ! paren */
	ret = NULL;

    /* Pick up the branches, linking them together. */
    parse_start = RExC_parse;   /* MJD */
    br = regbranch(pRExC_state, &flags, 1,depth+1);
    /*     branch_len = (paren != 0); */

    if (br == NULL)
	return(NULL);
    if (*RExC_parse == '|') {
	if (!SIZE_ONLY && RExC_extralen) {
	    reginsert(pRExC_state, BRANCHJ, br, depth+1);
	}
	else {                  /* MJD */
	    reginsert(pRExC_state, BRANCH, br, depth+1);
            Set_Node_Length(br, paren != 0);
            Set_Node_Offset_To_R(br-RExC_emit_start, parse_start-RExC_start);
        }
	have_branch = 1;
	if (SIZE_ONLY)
	    RExC_extralen += 1;		/* For BRANCHJ-BRANCH. */
    }
    else if (paren == ':') {
	*flagp |= flags&SIMPLE;
    }
    if (is_open) {				/* Starts with OPEN. */
        REGTAIL(pRExC_state, ret, br);          /* OPEN -> first. */
    }
    else if (paren != '?')		/* Not Conditional */
	ret = br;
    *flagp |= flags & (SPSTART | HASWIDTH);
    lastbr = br;
    while (*RExC_parse == '|') {
	if (!SIZE_ONLY && RExC_extralen) {
	    ender = reganode(pRExC_state, LONGJMP,0);
            REGTAIL(pRExC_state, NEXTOPER(NEXTOPER(lastbr)), ender); /* Append to the previous. */
	}
	if (SIZE_ONLY)
	    RExC_extralen += 2;		/* Account for LONGJMP. */
	nextchar(pRExC_state);
        br = regbranch(pRExC_state, &flags, 0, depth+1);

	if (br == NULL)
	    return(NULL);
        REGTAIL(pRExC_state, lastbr, br);               /* BRANCH -> BRANCH. */
	lastbr = br;
	if (flags&HASWIDTH)
	    *flagp |= HASWIDTH;
	*flagp |= flags&SPSTART;
    }

    if (have_branch || paren != ':') {
	/* Make a closing node, and hook it on the end. */
	switch (paren) {
	case ':':
	    ender = reg_node(pRExC_state, TAIL);
	    break;
	case 1:
	    RExC_cpar++;
	    ender = reganode(pRExC_state, CLOSE, parno);
	    if (!SIZE_ONLY && RExC_seen & REG_SEEN_RECURSE) {
		DEBUG_OPTIMISE_MORE_r(PerlIO_printf(Perl_debug_log,
			"Setting close paren #%"IVdf" to %d\n", 
			(IV)parno, REG_NODE_NUM(ender)));
	        RExC_close_parens[parno-1]= ender;
	        if (RExC_nestroot == parno) 
	            RExC_nestroot = 0;
	    }	    
            Set_Node_Offset(ender,RExC_parse+1); /* MJD */
            Set_Node_Length(ender,1); /* MJD */
	    break;
	case '<':
	case ',':
	case '=':
	case '!':
	    *flagp &= ~HASWIDTH;
	    /* FALL THROUGH */
	case '>':
	    ender = reg_node(pRExC_state, SUCCEED);
	    break;
	case 0:
	    ender = reg_node(pRExC_state, END);
	    if (!SIZE_ONLY) {
                assert(!RExC_opend); /* there can only be one! */
                RExC_opend = ender;
            }
	    break;
	}
        REGTAIL(pRExC_state, lastbr, ender);

	if (have_branch && !SIZE_ONLY) {
	    if (depth==1)
	        RExC_seen |= REG_TOP_LEVEL_BRANCHES;

	    /* Hook the tails of the branches to the closing node. */
	    for (br = ret; br; br = regnext(br)) {
		const U8 op = PL_regkind[OP(br)];
		if (op == BRANCH) {
                    REGTAIL_STUDY(pRExC_state, NEXTOPER(br), ender);
		}
		else if (op == BRANCHJ) {
                    REGTAIL_STUDY(pRExC_state, NEXTOPER(NEXTOPER(br)), ender);
		}
	    }
	}
    }

    {
        const char *p;
        static const char parens[] = "=!<,>";

	if (paren && (p = strchr(parens, paren))) {
	    U8 node = ((p - parens) % 2) ? UNLESSM : IFMATCH;
	    int flag = (p - parens) > 1;

	    if (paren == '>')
		node = SUSPEND, flag = 0;
	    reginsert(pRExC_state, node,ret, depth+1);
	    Set_Node_Cur_Length(ret);
	    Set_Node_Offset(ret, parse_start + 1);
	    ret->flags = flag;
            REGTAIL_STUDY(pRExC_state, ret, reg_node(pRExC_state, TAIL));
	}
    }

    /* Check for proper termination. */
    if (paren) {
	RExC_flags = oregflags;
	if (RExC_parse >= RExC_end || *nextchar(pRExC_state) != ')') {
	    RExC_parse = oregcomp_parse;
	    vFAIL("Unmatched (");
	}
    }
    else if (!paren && RExC_parse < RExC_end) {
	if (*RExC_parse == ')') {
	    RExC_parse++;
	    vFAIL("Unmatched )");
	}
	else
	    FAIL("Junk on end of regexp");	/* "Can't happen". */
	/* NOTREACHED */
    }

    return(ret);
}

/*
 - regbranch - one alternative of an | operator
 *
 * Implements the concatenation operator.
 */
STATIC regnode *
S_regbranch(pTHX_ RExC_state_t *pRExC_state, I32 *flagp, I32 first, U32 depth)
{
    dVAR;
    register regnode *ret;
    register regnode *chain = NULL;
    register regnode *latest;
    I32 flags = 0, c = 0;
    GET_RE_DEBUG_FLAGS_DECL;
    DEBUG_PARSE("brnc");
    if (first)
	ret = NULL;
    else {
	if (!SIZE_ONLY && RExC_extralen)
	    ret = reganode(pRExC_state, BRANCHJ,0);
	else {
	    ret = reg_node(pRExC_state, BRANCH);
            Set_Node_Length(ret, 1);
        }
    }
	
    if (!first && SIZE_ONLY)
	RExC_extralen += 1;			/* BRANCHJ */

    *flagp = WORST;			/* Tentatively. */

    RExC_parse--;
    nextchar(pRExC_state);
    while (RExC_parse < RExC_end && *RExC_parse != '|' && *RExC_parse != ')') {
	flags &= ~TRYAGAIN;
        latest = regpiece(pRExC_state, &flags,depth+1);
	if (latest == NULL) {
	    if (flags & TRYAGAIN)
		continue;
	    return(NULL);
	}
	else if (ret == NULL)
	    ret = latest;
	*flagp |= flags&HASWIDTH;
	if (chain == NULL) 	/* First piece. */
	    *flagp |= flags&SPSTART;
	else {
	    RExC_naughty++;
            REGTAIL(pRExC_state, chain, latest);
	}
	chain = latest;
	c++;
    }
    if (chain == NULL) {	/* Loop ran zero times. */
	chain = reg_node(pRExC_state, NOTHING);
	if (ret == NULL)
	    ret = chain;
    }
    if (c == 1) {
	*flagp |= flags&SIMPLE;
    }

    return ret;
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
STATIC regnode *
S_regpiece(pTHX_ RExC_state_t *pRExC_state, I32 *flagp, U32 depth)
{
    dVAR;
    register regnode *ret;
    register char op;
    register char *next;
    I32 flags;
    const char * const origparse = RExC_parse;
    I32 min;
    I32 max = REG_INFTY;
    char *parse_start;
    const char *maxpos = NULL;
    GET_RE_DEBUG_FLAGS_DECL;
    DEBUG_PARSE("piec");

    ret = regatom(pRExC_state, &flags,depth+1);
    if (ret == NULL) {
	if (flags & TRYAGAIN)
	    *flagp |= TRYAGAIN;
	return(NULL);
    }

    op = *RExC_parse;

    if (op == '{' && regcurly(RExC_parse)) {
	maxpos = NULL;
        parse_start = RExC_parse; /* MJD */
	next = RExC_parse + 1;
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
	    RExC_parse++;
	    min = atoi(RExC_parse);
	    if (*maxpos == ',')
		maxpos++;
	    else
		maxpos = RExC_parse;
	    max = atoi(maxpos);
	    if (!max && *maxpos != '0')
		max = REG_INFTY;		/* meaning "infinity" */
	    else if (max >= REG_INFTY)
		vFAIL2("Quantifier in {,} bigger than %d", REG_INFTY - 1);
	    RExC_parse = next;
	    nextchar(pRExC_state);

	do_curly:
	    if ((flags&SIMPLE)) {
		RExC_naughty += 2 + RExC_naughty / 2;
		reginsert(pRExC_state, CURLY, ret, depth+1);
                Set_Node_Offset(ret, parse_start+1); /* MJD */
                Set_Node_Cur_Length(ret);
	    }
	    else {
		regnode * const w = reg_node(pRExC_state, WHILEM);

		w->flags = 0;
                REGTAIL(pRExC_state, ret, w);
		if (!SIZE_ONLY && RExC_extralen) {
		    reginsert(pRExC_state, LONGJMP,ret, depth+1);
		    reginsert(pRExC_state, NOTHING,ret, depth+1);
		    NEXT_OFF(ret) = 3;	/* Go over LONGJMP. */
		}
		reginsert(pRExC_state, CURLYX,ret, depth+1);
                                /* MJD hk */
                Set_Node_Offset(ret, parse_start+1);
                Set_Node_Length(ret,
                                op == '{' ? (RExC_parse - parse_start) : 1);

		if (!SIZE_ONLY && RExC_extralen)
		    NEXT_OFF(ret) = 3;	/* Go over NOTHING to LONGJMP. */
                REGTAIL(pRExC_state, ret, reg_node(pRExC_state, NOTHING));
		if (SIZE_ONLY)
		    RExC_whilem_seen++, RExC_extralen += 3;
		RExC_naughty += 4 + RExC_naughty;	/* compound interest */
	    }
	    ret->flags = 0;

	    if (min > 0)
		*flagp = WORST;
	    if (max > 0)
		*flagp |= HASWIDTH;
	    if (max && max < min)
		vFAIL("Can't do {n,m} with n > m");
	    if (!SIZE_ONLY) {
		ARG1_SET(ret, (U16)min);
		ARG2_SET(ret, (U16)max);
	    }

	    goto nest_check;
	}
    }

    if (!ISMULT1(op)) {
	*flagp = flags;
	return(ret);
    }

#if 0				/* Now runtime fix should be reliable. */

    /* if this is reinstated, don't forget to put this back into perldiag:

	    =item Regexp *+ operand could be empty at {#} in regex m/%s/

	   (F) The part of the regexp subject to either the * or + quantifier
           could match an empty string. The {#} shows in the regular
           expression about where the problem was discovered.

    */

    if (!(flags&HASWIDTH) && op != '?')
      vFAIL("Regexp *+ operand could be empty");
#endif

    parse_start = RExC_parse;
    nextchar(pRExC_state);

    *flagp = (op != '+') ? (WORST|SPSTART|HASWIDTH) : (WORST|HASWIDTH);

    if (op == '*' && (flags&SIMPLE)) {
	reginsert(pRExC_state, STAR, ret, depth+1);
	ret->flags = 0;
	RExC_naughty += 4;
    }
    else if (op == '*') {
	min = 0;
	goto do_curly;
    }
    else if (op == '+' && (flags&SIMPLE)) {
	reginsert(pRExC_state, PLUS, ret, depth+1);
	ret->flags = 0;
	RExC_naughty += 3;
    }
    else if (op == '+') {
	min = 1;
	goto do_curly;
    }
    else if (op == '?') {
	min = 0; max = 1;
	goto do_curly;
    }
  nest_check:
    if (!SIZE_ONLY && !(flags&HASWIDTH) && max > REG_INFTY/3 && ckWARN(WARN_REGEXP)) {
	vWARN3(RExC_parse,
	       "%.*s matches null string many times",
	       (int)(RExC_parse >= origparse ? RExC_parse - origparse : 0),
	       origparse);
    }

    if (RExC_parse < RExC_end && *RExC_parse == '?') {
	nextchar(pRExC_state);
	reginsert(pRExC_state, MINMOD, ret, depth+1);
        REGTAIL(pRExC_state, ret, ret + NODE_STEP_REGNODE);
    }
#ifndef REG_ALLOW_MINMOD_SUSPEND
    else
#endif
    if (RExC_parse < RExC_end && *RExC_parse == '+') {
        regnode *ender;
        nextchar(pRExC_state);
        ender = reg_node(pRExC_state, SUCCEED);
        REGTAIL(pRExC_state, ret, ender);
        reginsert(pRExC_state, SUSPEND, ret, depth+1);
        ret->flags = 0;
        ender = reg_node(pRExC_state, TAIL);
        REGTAIL(pRExC_state, ret, ender);
        /*ret= ender;*/
    }

    if (RExC_parse < RExC_end && ISMULT2(RExC_parse)) {
	RExC_parse++;
	vFAIL("Nested quantifiers");
    }

    return(ret);
}


/* reg_namedseq(pRExC_state,UVp)
   
   This is expected to be called by a parser routine that has 
   recognized'\N' and needs to handle the rest. RExC_parse is 
   expected to point at the first char following the N at the time
   of the call.
   
   If valuep is non-null then it is assumed that we are parsing inside 
   of a charclass definition and the first codepoint in the resolved
   string is returned via *valuep and the routine will return NULL. 
   In this mode if a multichar string is returned from the charnames 
   handler a warning will be issued, and only the first char in the 
   sequence will be examined. If the string returned is zero length
   then the value of *valuep is undefined and NON-NULL will 
   be returned to indicate failure. (This will NOT be a valid pointer 
   to a regnode.)
   
   If value is null then it is assumed that we are parsing normal text
   and inserts a new EXACT node into the program containing the resolved
   string and returns a pointer to the new node. If the string is 
   zerolength a NOTHING node is emitted.
   
   On success RExC_parse is set to the char following the endbrace.
   Parsing failures will generate a fatal errorvia vFAIL(...)
   
   NOTE: We cache all results from the charnames handler locally in 
   the RExC_charnames hash (created on first use) to prevent a charnames 
   handler from playing silly-buggers and returning a short string and 
   then a long string for a given pattern. Since the regexp program 
   size is calculated during an initial parse this would result
   in a buffer overrun so we cache to prevent the charname result from
   changing during the course of the parse.
   
 */
STATIC regnode *
S_reg_namedseq(pTHX_ RExC_state_t *pRExC_state, UV *valuep) 
{
    char * name;        /* start of the content of the name */
    char * endbrace;    /* endbrace following the name */
    SV *sv_str = NULL;  
    SV *sv_name = NULL;
    STRLEN len; /* this has various purposes throughout the code */
    bool cached = 0; /* if this is true then we shouldn't refcount dev sv_str */
    regnode *ret = NULL;
    
    if (*RExC_parse != '{') {
        vFAIL("Missing braces on \\N{}");
    }
    name = RExC_parse+1;
    endbrace = strchr(RExC_parse, '}');
    if ( ! endbrace ) {
        RExC_parse++;
        vFAIL("Missing right brace on \\N{}");
    } 
    RExC_parse = endbrace + 1;  
    
    
    /* RExC_parse points at the beginning brace, 
       endbrace points at the last */
    if ( name[0]=='U' && name[1]=='+' ) {
        /* its a "unicode hex" notation {U+89AB} */
        I32 fl = PERL_SCAN_ALLOW_UNDERSCORES
            | PERL_SCAN_DISALLOW_PREFIX
            | (SIZE_ONLY ? PERL_SCAN_SILENT_ILLDIGIT : 0);
        UV cp;
        len = (STRLEN)(endbrace - name - 2);
        cp = grok_hex(name + 2, &len, &fl, NULL);
        if ( len != (STRLEN)(endbrace - name - 2) ) {
            cp = 0xFFFD;
        }    
        if (cp > 0xff)
            RExC_utf8 = 1;
        if ( valuep ) {
            *valuep = cp;
            return NULL;
        }
        sv_str= Perl_newSVpvf_nocontext("%c",(int)cp);
    } else {
        /* fetch the charnames handler for this scope */
        HV * const table = GvHV(PL_hintgv);
        SV **cvp= table ? 
            hv_fetchs(table, "charnames", FALSE) :
            NULL;
        SV *cv= cvp ? *cvp : NULL;
        HE *he_str;
        int count;
        /* create an SV with the name as argument */
        sv_name = newSVpvn(name, endbrace - name);
        
        if (!table || !(PL_hints & HINT_LOCALIZE_HH)) {
            vFAIL2("Constant(\\N{%s}) unknown: "
                  "(possibly a missing \"use charnames ...\")",
                  SvPVX(sv_name));
        }
        if (!cvp || !SvOK(*cvp)) { /* when $^H{charnames} = undef; */
            vFAIL2("Constant(\\N{%s}): "
                  "$^H{charnames} is not defined",SvPVX(sv_name));
        }
        
        
        
        if (!RExC_charnames) {
            /* make sure our cache is allocated */
            RExC_charnames = newHV();
            sv_2mortal((SV*)RExC_charnames);
        } 
            /* see if we have looked this one up before */
        he_str = hv_fetch_ent( RExC_charnames, sv_name, 0, 0 );
        if ( he_str ) {
            sv_str = HeVAL(he_str);
            cached = 1;
        } else {
            dSP ;

            ENTER ;
            SAVETMPS ;
            PUSHMARK(SP) ;
            
            XPUSHs(sv_name);
            
            PUTBACK ;
            
            count= call_sv(cv, G_SCALAR);
            
            if (count == 1) { /* XXXX is this right? dmq */
                sv_str = POPs;
                SvREFCNT_inc_simple_void(sv_str);
            } 
            
            SPAGAIN ;
            PUTBACK ;
            FREETMPS ;
            LEAVE ;
            
            if ( !sv_str || !SvOK(sv_str) ) {
                vFAIL2("Constant(\\N{%s}): Call to &{$^H{charnames}} "
                      "did not return a defined value",SvPVX(sv_name));
            }
            if (hv_store_ent( RExC_charnames, sv_name, sv_str, 0))
                cached = 1;
        }
    }
    if (valuep) {
        char *p = SvPV(sv_str, len);
        if (len) {
            STRLEN numlen = 1;
            if ( SvUTF8(sv_str) ) {
                *valuep = utf8_to_uvchr((U8*)p, &numlen);
                if (*valuep > 0x7F)
                    RExC_utf8 = 1; 
                /* XXXX
                  We have to turn on utf8 for high bit chars otherwise
                  we get failures with
                  
                   "ss" =~ /[\N{LATIN SMALL LETTER SHARP S}]/i
                   "SS" =~ /[\N{LATIN SMALL LETTER SHARP S}]/i
                
                  This is different from what \x{} would do with the same
                  codepoint, where the condition is > 0xFF.
                  - dmq
                */
                
                
            } else {
                *valuep = (UV)*p;
                /* warn if we havent used the whole string? */
            }
            if (numlen<len && SIZE_ONLY && ckWARN(WARN_REGEXP)) {
                vWARN2(RExC_parse,
                    "Ignoring excess chars from \\N{%s} in character class",
                    SvPVX(sv_name)
                );
            }        
        } else if (SIZE_ONLY && ckWARN(WARN_REGEXP)) {
            vWARN2(RExC_parse,
                    "Ignoring zero length \\N{%s} in character class",
                    SvPVX(sv_name)
                );
        }
        if (sv_name)    
            SvREFCNT_dec(sv_name);    
        if (!cached)
            SvREFCNT_dec(sv_str);    
        return len ? NULL : (regnode *)&len;
    } else if(SvCUR(sv_str)) {     
        
        char *s; 
        char *p, *pend;        
        STRLEN charlen = 1;
        char * parse_start = name-3; /* needed for the offsets */
        GET_RE_DEBUG_FLAGS_DECL;     /* needed for the offsets */
        
        ret = reg_node(pRExC_state,
            (U8)(FOLD ? (LOC ? EXACTFL : EXACTF) : EXACT));
        s= STRING(ret);
        
        if ( RExC_utf8 && !SvUTF8(sv_str) ) {
            sv_utf8_upgrade(sv_str);
        } else if ( !RExC_utf8 && SvUTF8(sv_str) ) {
            RExC_utf8= 1;
        }
        
        p = SvPV(sv_str, len);
        pend = p + len;
        /* len is the length written, charlen is the size the char read */
        for ( len = 0; p < pend; p += charlen ) {
            if (UTF) {
                UV uvc = utf8_to_uvchr((U8*)p, &charlen);
                if (FOLD) {
                    STRLEN foldlen,numlen;
                    U8 tmpbuf[UTF8_MAXBYTES_CASE+1], *foldbuf;
                    uvc = toFOLD_uni(uvc, tmpbuf, &foldlen);
                    /* Emit all the Unicode characters. */
                    
                    for (foldbuf = tmpbuf;
                        foldlen;
                        foldlen -= numlen) 
                    {
                        uvc = utf8_to_uvchr(foldbuf, &numlen);
                        if (numlen > 0) {
                            const STRLEN unilen = reguni(pRExC_state, uvc, s);
                            s       += unilen;
                            len     += unilen;
                            /* In EBCDIC the numlen
                            * and unilen can differ. */
                            foldbuf += numlen;
                            if (numlen >= foldlen)
                                break;
                        }
                        else
                            break; /* "Can't happen." */
                    }                          
                } else {
                    const STRLEN unilen = reguni(pRExC_state, uvc, s);
        	    if (unilen > 0) {
        	       s   += unilen;
        	       len += unilen;
        	    }
        	}
	    } else {
                len++;
                REGC(*p, s++);
            }
        }
        if (SIZE_ONLY) {
            RExC_size += STR_SZ(len);
        } else {
            STR_LEN(ret) = len;
            RExC_emit += STR_SZ(len);
        }
        Set_Node_Cur_Length(ret); /* MJD */
        RExC_parse--; 
        nextchar(pRExC_state);
    } else {
        ret = reg_node(pRExC_state,NOTHING);
    }
    if (!cached) {
        SvREFCNT_dec(sv_str);
    }
    if (sv_name) {
        SvREFCNT_dec(sv_name); 
    }
    return ret;

}


/*
 * reg_recode
 *
 * It returns the code point in utf8 for the value in *encp.
 *    value: a code value in the source encoding
 *    encp:  a pointer to an Encode object
 *
 * If the result from Encode is not a single character,
 * it returns U+FFFD (Replacement character) and sets *encp to NULL.
 */
STATIC UV
S_reg_recode(pTHX_ const char value, SV **encp)
{
    STRLEN numlen = 1;
    SV * const sv = sv_2mortal(newSVpvn(&value, numlen));
    const char * const s = encp && *encp ? sv_recode_to_utf8(sv, *encp)
					 : SvPVX(sv);
    const STRLEN newlen = SvCUR(sv);
    UV uv = UNICODE_REPLACEMENT;

    if (newlen)
	uv = SvUTF8(sv)
	     ? utf8n_to_uvchr((U8*)s, newlen, &numlen, UTF8_ALLOW_DEFAULT)
	     : *(U8*)s;

    if (!newlen || numlen != newlen) {
	uv = UNICODE_REPLACEMENT;
	if (encp)
	    *encp = NULL;
    }
    return uv;
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
 * [It looks like its ok, as in S_study_chunk we merge adjacent EXACT nodes]
 */
STATIC regnode *
S_regatom(pTHX_ RExC_state_t *pRExC_state, I32 *flagp, U32 depth)
{
    dVAR;
    register regnode *ret = NULL;
    I32 flags;
    char *parse_start = RExC_parse;
    GET_RE_DEBUG_FLAGS_DECL;
    DEBUG_PARSE("atom");
    *flagp = WORST;		/* Tentatively. */

tryagain:
    switch (*RExC_parse) {
    case '^':
	RExC_seen_zerolen++;
	nextchar(pRExC_state);
	if (RExC_flags & PMf_MULTILINE)
	    ret = reg_node(pRExC_state, MBOL);
	else if (RExC_flags & PMf_SINGLELINE)
	    ret = reg_node(pRExC_state, SBOL);
	else
	    ret = reg_node(pRExC_state, BOL);
        Set_Node_Length(ret, 1); /* MJD */
	break;
    case '$':
	nextchar(pRExC_state);
	if (*RExC_parse)
	    RExC_seen_zerolen++;
	if (RExC_flags & PMf_MULTILINE)
	    ret = reg_node(pRExC_state, MEOL);
	else if (RExC_flags & PMf_SINGLELINE)
	    ret = reg_node(pRExC_state, SEOL);
	else
	    ret = reg_node(pRExC_state, EOL);
        Set_Node_Length(ret, 1); /* MJD */
	break;
    case '.':
	nextchar(pRExC_state);
	if (RExC_flags & PMf_SINGLELINE)
	    ret = reg_node(pRExC_state, SANY);
	else
	    ret = reg_node(pRExC_state, REG_ANY);
	*flagp |= HASWIDTH|SIMPLE;
	RExC_naughty++;
        Set_Node_Length(ret, 1); /* MJD */
	break;
    case '[':
    {
	char * const oregcomp_parse = ++RExC_parse;
        ret = regclass(pRExC_state,depth+1);
	if (*RExC_parse != ']') {
	    RExC_parse = oregcomp_parse;
	    vFAIL("Unmatched [");
	}
	nextchar(pRExC_state);
	*flagp |= HASWIDTH|SIMPLE;
        Set_Node_Length(ret, RExC_parse - oregcomp_parse + 1); /* MJD */
	break;
    }
    case '(':
	nextchar(pRExC_state);
        ret = reg(pRExC_state, 1, &flags,depth+1);
	if (ret == NULL) {
		if (flags & TRYAGAIN) {
		    if (RExC_parse == RExC_end) {
			 /* Make parent create an empty node if needed. */
			*flagp |= TRYAGAIN;
			return(NULL);
		    }
		    goto tryagain;
		}
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
	vFAIL("Internal urp");
				/* Supposed to be caught earlier. */
	break;
    case '{':
	if (!regcurly(RExC_parse)) {
	    RExC_parse++;
	    goto defchar;
	}
	/* FALL THROUGH */
    case '?':
    case '+':
    case '*':
	RExC_parse++;
	vFAIL("Quantifier follows nothing");
	break;
    case '\\':
	switch (*++RExC_parse) {
	case 'A':
	    RExC_seen_zerolen++;
	    ret = reg_node(pRExC_state, SBOL);
	    *flagp |= SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'G':
	    ret = reg_node(pRExC_state, GPOS);
	    RExC_seen |= REG_SEEN_GPOS;
	    *flagp |= SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'Z':
	    ret = reg_node(pRExC_state, SEOL);
	    *flagp |= SIMPLE;
	    RExC_seen_zerolen++;		/* Do not optimize RE away */
	    nextchar(pRExC_state);
	    break;
	case 'z':
	    ret = reg_node(pRExC_state, EOS);
	    *flagp |= SIMPLE;
	    RExC_seen_zerolen++;		/* Do not optimize RE away */
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'C':
	    ret = reg_node(pRExC_state, CANY);
	    RExC_seen |= REG_SEEN_CANY;
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'X':
	    ret = reg_node(pRExC_state, CLUMP);
	    *flagp |= HASWIDTH;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'w':
	    ret = reg_node(pRExC_state, (U8)(LOC ? ALNUML     : ALNUM));
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'W':
	    ret = reg_node(pRExC_state, (U8)(LOC ? NALNUML    : NALNUM));
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'b':
	    RExC_seen_zerolen++;
	    RExC_seen |= REG_SEEN_LOOKBEHIND;
	    ret = reg_node(pRExC_state, (U8)(LOC ? BOUNDL     : BOUND));
	    *flagp |= SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'B':
	    RExC_seen_zerolen++;
	    RExC_seen |= REG_SEEN_LOOKBEHIND;
	    ret = reg_node(pRExC_state, (U8)(LOC ? NBOUNDL    : NBOUND));
	    *flagp |= SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 's':
	    ret = reg_node(pRExC_state, (U8)(LOC ? SPACEL     : SPACE));
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'S':
	    ret = reg_node(pRExC_state, (U8)(LOC ? NSPACEL    : NSPACE));
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'd':
	    ret = reg_node(pRExC_state, DIGIT);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'D':
	    ret = reg_node(pRExC_state, NDIGIT);
	    *flagp |= HASWIDTH|SIMPLE;
	    nextchar(pRExC_state);
            Set_Node_Length(ret, 2); /* MJD */
	    break;
	case 'p':
	case 'P':
	    {	
		char* const oldregxend = RExC_end;
		char* parse_start = RExC_parse - 2;

		if (RExC_parse[1] == '{') {
		  /* a lovely hack--pretend we saw [\pX] instead */
		    RExC_end = strchr(RExC_parse, '}');
		    if (!RExC_end) {
		        const U8 c = (U8)*RExC_parse;
			RExC_parse += 2;
			RExC_end = oldregxend;
			vFAIL2("Missing right brace on \\%c{}", c);
		    }
		    RExC_end++;
		}
		else {
		    RExC_end = RExC_parse + 2;
		    if (RExC_end > oldregxend)
			RExC_end = oldregxend;
		}
		RExC_parse--;

                ret = regclass(pRExC_state,depth+1);

		RExC_end = oldregxend;
		RExC_parse--;

		Set_Node_Offset(ret, parse_start + 2);
		Set_Node_Cur_Length(ret);
		nextchar(pRExC_state);
		*flagp |= HASWIDTH|SIMPLE;
	    }
	    break;
        case 'N': 
            /* Handle \N{NAME} here and not below because it can be 
            multicharacter. join_exact() will join them up later on. 
            Also this makes sure that things like /\N{BLAH}+/ and 
            \N{BLAH} being multi char Just Happen. dmq*/
            ++RExC_parse;
            ret= reg_namedseq(pRExC_state, NULL); 
            break;
	case 'k':    /* Handle \k<NAME> and \k'NAME' */
        {   
            char ch= RExC_parse[1];	    
	    if (ch != '<' && ch != '\'') {
	        if (SIZE_ONLY)
	            vWARN( RExC_parse + 1, 
	                "Possible broken named back reference treated as literal k");
	        parse_start--;
	        goto defchar;
	    } else {
		char* name_start = (RExC_parse += 2);
		I32 num = 0;
                SV *sv_dat = reg_scan_name(pRExC_state,
                    SIZE_ONLY ? REG_RSN_RETURN_NULL : REG_RSN_RETURN_DATA);
                ch= (ch == '<') ? '>' : '\'';
                    
                if (RExC_parse == name_start || *RExC_parse != ch)
                    vFAIL2("Sequence \\k%c... not terminated",
                        (ch == '>' ? '<' : ch));
                
                RExC_sawback = 1;
                ret = reganode(pRExC_state,
                	   (U8)(FOLD ? (LOC ? NREFFL : NREFF) : NREF),
                	   num);
                *flagp |= HASWIDTH;
                
    		
                if (!SIZE_ONLY) {
                    num = add_data( pRExC_state, 1, "S" );
                    ARG_SET(ret,num);
                    RExC_rx->data->data[num]=(void*)sv_dat;
                    SvREFCNT_inc(sv_dat);
                }    
                /* override incorrect value set in reganode MJD */
                Set_Node_Offset(ret, parse_start+1);
                Set_Node_Cur_Length(ret); /* MJD */
                nextchar(pRExC_state);
		               
            }
            break;
        }            
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
	case 'R': 
	case '1': case '2': case '3': case '4':
	case '5': case '6': case '7': case '8': case '9':
	    {
		I32 num;
		bool isrel=(*RExC_parse=='R');
		if (isrel)
		    RExC_parse++;
		num = atoi(RExC_parse);
                if (isrel) {
                    num = RExC_cpar - num;
                    if (num < 1)
                        vFAIL("Reference to nonexistent or unclosed group");
                }
		if (num > 9 && num >= RExC_npar)
		    goto defchar;
		else {
		    char * const parse_start = RExC_parse - 1; /* MJD */
		    while (isDIGIT(*RExC_parse))
			RExC_parse++;

		    if (!SIZE_ONLY) {
		        if (num > (I32)RExC_rx->nparens)
			    vFAIL("Reference to nonexistent group");
			/* People make this error all the time apparently.
			   So we cant fail on it, even though we should 
			
			else if (num >= RExC_cpar)
			    vFAIL("Reference to unclosed group will always match");
			*/
		    }
		    RExC_sawback = 1;
		    ret = reganode(pRExC_state,
				   (U8)(FOLD ? (LOC ? REFFL : REFF) : REF),
				   num);
		    *flagp |= HASWIDTH;

                    /* override incorrect value set in reganode MJD */
                    Set_Node_Offset(ret, parse_start+1);
                    Set_Node_Cur_Length(ret); /* MJD */
		    RExC_parse--;
		    nextchar(pRExC_state);
		}
	    }
	    break;
	case '\0':
	    if (RExC_parse >= RExC_end)
		FAIL("Trailing \\");
	    /* FALL THROUGH */
	default:
	    /* Do not generate "unrecognized" warnings here, we fall
	       back into the quick-grab loop below */
	    parse_start--;
	    goto defchar;
	}
	break;

    case '#':
	if (RExC_flags & PMf_EXTENDED) {
	    while (RExC_parse < RExC_end && *RExC_parse != '\n')
		RExC_parse++;
	    if (RExC_parse < RExC_end)
		goto tryagain;
	}
	/* FALL THROUGH */

    default: {
	    register STRLEN len;
	    register UV ender;
	    register char *p;
	    char *s;
	    STRLEN foldlen;
	    U8 tmpbuf[UTF8_MAXBYTES_CASE+1], *foldbuf;

            parse_start = RExC_parse - 1;

	    RExC_parse++;

	defchar:
	    ender = 0;
	    ret = reg_node(pRExC_state,
			   (U8)(FOLD ? (LOC ? EXACTFL : EXACTF) : EXACT));
	    s = STRING(ret);
	    for (len = 0, p = RExC_parse - 1;
	      len < 127 && p < RExC_end;
	      len++)
	    {
		char * const oldp = p;

		if (RExC_flags & PMf_EXTENDED)
		    p = regwhite(p, RExC_end);
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
		    case 'C':
		    case 'X':
		    case 'G':
		    case 'Z':
		    case 'z':
		    case 'w':
		    case 'W':
		    case 'b':
		    case 'B':
		    case 's':
		    case 'S':
		    case 'd':
		    case 'D':
		    case 'p':
		    case 'P':
                    case 'N':
                    case 'R':
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
			  ender = ASCII_TO_NATIVE('\033');
			p++;
			break;
		    case 'a':
			  ender = ASCII_TO_NATIVE('\007');
			p++;
			break;
		    case 'x':
			if (*++p == '{') {
			    char* const e = strchr(p, '}');
	
			    if (!e) {
				RExC_parse = p + 1;
				vFAIL("Missing right brace on \\x{}");
			    }
			    else {
                                I32 flags = PERL_SCAN_ALLOW_UNDERSCORES
                                    | PERL_SCAN_DISALLOW_PREFIX;
                                STRLEN numlen = e - p - 1;
				ender = grok_hex(p + 1, &numlen, &flags, NULL);
				if (ender > 0xff)
				    RExC_utf8 = 1;
				p = e + 1;
			    }
			}
			else {
                            I32 flags = PERL_SCAN_DISALLOW_PREFIX;
			    STRLEN numlen = 2;
			    ender = grok_hex(p, &numlen, &flags, NULL);
			    p += numlen;
			}
			if (PL_encoding && ender < 0x100)
			    goto recode_encoding;
			break;
		    case 'c':
			p++;
			ender = UCHARAT(p++);
			ender = toCTRL(ender);
			break;
		    case '0': case '1': case '2': case '3':case '4':
		    case '5': case '6': case '7': case '8':case '9':
			if (*p == '0' ||
			  (isDIGIT(p[1]) && atoi(p) >= RExC_npar) ) {
                            I32 flags = 0;
			    STRLEN numlen = 3;
			    ender = grok_oct(p, &numlen, &flags, NULL);
			    p += numlen;
			}
			else {
			    --p;
			    goto loopdone;
			}
			if (PL_encoding && ender < 0x100)
			    goto recode_encoding;
			break;
		    recode_encoding:
			{
			    SV* enc = PL_encoding;
			    ender = reg_recode((const char)(U8)ender, &enc);
			    if (!enc && SIZE_ONLY && ckWARN(WARN_REGEXP))
				vWARN(p, "Invalid escape in the specified encoding");
			    RExC_utf8 = 1;
			}
			break;
		    case '\0':
			if (p >= RExC_end)
			    FAIL("Trailing \\");
			/* FALL THROUGH */
		    default:
			if (!SIZE_ONLY&& isALPHA(*p) && ckWARN(WARN_REGEXP))
			    vWARN2(p + 1, "Unrecognized escape \\%c passed through", UCHARAT(p));
			goto normal_default;
		    }
		    break;
		default:
		  normal_default:
		    if (UTF8_IS_START(*p) && UTF) {
			STRLEN numlen;
			ender = utf8n_to_uvchr((U8*)p, RExC_end - p,
					       &numlen, UTF8_ALLOW_DEFAULT);
			p += numlen;
		    }
		    else
			ender = *p++;
		    break;
		}
		if (RExC_flags & PMf_EXTENDED)
		    p = regwhite(p, RExC_end);
		if (UTF && FOLD) {
		    /* Prime the casefolded buffer. */
		    ender = toFOLD_uni(ender, tmpbuf, &foldlen);
		}
		if (ISMULT2(p)) { /* Back off on ?+*. */
		    if (len)
			p = oldp;
		    else if (UTF) {
			 if (FOLD) {
			      /* Emit all the Unicode characters. */
			      STRLEN numlen;
			      for (foldbuf = tmpbuf;
				   foldlen;
				   foldlen -= numlen) {
				   ender = utf8_to_uvchr(foldbuf, &numlen);
				   if (numlen > 0) {
					const STRLEN unilen = reguni(pRExC_state, ender, s);
					s       += unilen;
					len     += unilen;
					/* In EBCDIC the numlen
					 * and unilen can differ. */
					foldbuf += numlen;
					if (numlen >= foldlen)
					     break;
				   }
				   else
					break; /* "Can't happen." */
			      }
			 }
			 else {
			      const STRLEN unilen = reguni(pRExC_state, ender, s);
			      if (unilen > 0) {
				   s   += unilen;
				   len += unilen;
			      }
			 }
		    }
		    else {
			len++;
			REGC((char)ender, s++);
		    }
		    break;
		}
		if (UTF) {
		     if (FOLD) {
		          /* Emit all the Unicode characters. */
			  STRLEN numlen;
			  for (foldbuf = tmpbuf;
			       foldlen;
			       foldlen -= numlen) {
			       ender = utf8_to_uvchr(foldbuf, &numlen);
			       if (numlen > 0) {
				    const STRLEN unilen = reguni(pRExC_state, ender, s);
				    len     += unilen;
				    s       += unilen;
				    /* In EBCDIC the numlen
				     * and unilen can differ. */
				    foldbuf += numlen;
				    if (numlen >= foldlen)
					 break;
			       }
			       else
				    break;
			  }
		     }
		     else {
			  const STRLEN unilen = reguni(pRExC_state, ender, s);
			  if (unilen > 0) {
			       s   += unilen;
			       len += unilen;
			  }
		     }
		     len--;
		}
		else
		    REGC((char)ender, s++);
	    }
	loopdone:
	    RExC_parse = p - 1;
            Set_Node_Cur_Length(ret); /* MJD */
	    nextchar(pRExC_state);
	    {
		/* len is STRLEN which is unsigned, need to copy to signed */
		IV iv = len;
		if (iv < 0)
		    vFAIL("Internal disaster");
	    }
	    if (len > 0)
		*flagp |= HASWIDTH;
	    if (len == 1 && UNI_IS_INVARIANT(ender))
		*flagp |= SIMPLE;
		
	    if (SIZE_ONLY)
		RExC_size += STR_SZ(len);
	    else {
		STR_LEN(ret) = len;
		RExC_emit += STR_SZ(len);
            }
	}
	break;
    }

    return(ret);
}

STATIC char *
S_regwhite(char *p, const char *e)
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

/* Parse POSIX character classes: [[:foo:]], [[=foo=]], [[.foo.]].
   Character classes ([:foo:]) can also be negated ([:^foo:]).
   Returns a named class id (ANYOF_XXX) if successful, -1 otherwise.
   Equivalence classes ([=foo=]) and composites ([.foo.]) are parsed,
   but trigger failures because they are currently unimplemented. */

#define POSIXCC_DONE(c)   ((c) == ':')
#define POSIXCC_NOTYET(c) ((c) == '=' || (c) == '.')
#define POSIXCC(c) (POSIXCC_DONE(c) || POSIXCC_NOTYET(c))

STATIC I32
S_regpposixcc(pTHX_ RExC_state_t *pRExC_state, I32 value)
{
    dVAR;
    I32 namedclass = OOB_NAMEDCLASS;

    if (value == '[' && RExC_parse + 1 < RExC_end &&
	/* I smell either [: or [= or [. -- POSIX has been here, right? */
	POSIXCC(UCHARAT(RExC_parse))) {
	const char c = UCHARAT(RExC_parse);
	char* const s = RExC_parse++;
	
	while (RExC_parse < RExC_end && UCHARAT(RExC_parse) != c)
	    RExC_parse++;
	if (RExC_parse == RExC_end)
	    /* Grandfather lone [:, [=, [. */
	    RExC_parse = s;
	else {
	    const char* const t = RExC_parse++; /* skip over the c */
	    assert(*t == c);

  	    if (UCHARAT(RExC_parse) == ']') {
		const char *posixcc = s + 1;
  		RExC_parse++; /* skip over the ending ] */

		if (*s == ':') {
		    const I32 complement = *posixcc == '^' ? *posixcc++ : 0;
		    const I32 skip = t - posixcc;

		    /* Initially switch on the length of the name.  */
		    switch (skip) {
		    case 4:
			if (memEQ(posixcc, "word", 4)) /* this is not POSIX, this is the Perl \w */
			    namedclass = complement ? ANYOF_NALNUM : ANYOF_ALNUM;
			break;
		    case 5:
			/* Names all of length 5.  */
			/* alnum alpha ascii blank cntrl digit graph lower
			   print punct space upper  */
			/* Offset 4 gives the best switch position.  */
			switch (posixcc[4]) {
			case 'a':
			    if (memEQ(posixcc, "alph", 4)) /* alpha */
				namedclass = complement ? ANYOF_NALPHA : ANYOF_ALPHA;
			    break;
			case 'e':
			    if (memEQ(posixcc, "spac", 4)) /* space */
				namedclass = complement ? ANYOF_NPSXSPC : ANYOF_PSXSPC;
			    break;
			case 'h':
			    if (memEQ(posixcc, "grap", 4)) /* graph */
				namedclass = complement ? ANYOF_NGRAPH : ANYOF_GRAPH;
			    break;
			case 'i':
			    if (memEQ(posixcc, "asci", 4)) /* ascii */
				namedclass = complement ? ANYOF_NASCII : ANYOF_ASCII;
			    break;
			case 'k':
			    if (memEQ(posixcc, "blan", 4)) /* blank */
				namedclass = complement ? ANYOF_NBLANK : ANYOF_BLANK;
			    break;
			case 'l':
			    if (memEQ(posixcc, "cntr", 4)) /* cntrl */
				namedclass = complement ? ANYOF_NCNTRL : ANYOF_CNTRL;
			    break;
			case 'm':
			    if (memEQ(posixcc, "alnu", 4)) /* alnum */
				namedclass = complement ? ANYOF_NALNUMC : ANYOF_ALNUMC;
			    break;
			case 'r':
			    if (memEQ(posixcc, "lowe", 4)) /* lower */
				namedclass = complement ? ANYOF_NLOWER : ANYOF_LOWER;
			    else if (memEQ(posixcc, "uppe", 4)) /* upper */
				namedclass = complement ? ANYOF_NUPPER : ANYOF_UPPER;
			    break;
			case 't':
			    if (memEQ(posixcc, "digi", 4)) /* digit */
				namedclass = complement ? ANYOF_NDIGIT : ANYOF_DIGIT;
			    else if (memEQ(posixcc, "prin", 4)) /* print */
				namedclass = complement ? ANYOF_NPRINT : ANYOF_PRINT;
			    else if (memEQ(posixcc, "punc", 4)) /* punct */
				namedclass = complement ? ANYOF_NPUNCT : ANYOF_PUNCT;
			    break;
			}
			break;
		    case 6:
			if (memEQ(posixcc, "xdigit", 6))
			    namedclass = complement ? ANYOF_NXDIGIT : ANYOF_XDIGIT;
			break;
		    }

		    if (namedclass == OOB_NAMEDCLASS)
			Simple_vFAIL3("POSIX class [:%.*s:] unknown",
				      t - s - 1, s + 1);
		    assert (posixcc[skip] == ':');
		    assert (posixcc[skip+1] == ']');
		} else if (!SIZE_ONLY) {
		    /* [[=foo=]] and [[.foo.]] are still future. */

		    /* adjust RExC_parse so the warning shows after
		       the class closes */
		    while (UCHARAT(RExC_parse) && UCHARAT(RExC_parse) != ']')
			RExC_parse++;
		    Simple_vFAIL3("POSIX syntax [%c %c] is reserved for future extensions", c, c);
		}
	    } else {
		/* Maternal grandfather:
		 * "[:" ending in ":" but not in ":]" */
		RExC_parse = s;
	    }
	}
    }

    return namedclass;
}

STATIC void
S_checkposixcc(pTHX_ RExC_state_t *pRExC_state)
{
    dVAR;
    if (POSIXCC(UCHARAT(RExC_parse))) {
	const char *s = RExC_parse;
	const char  c = *s++;

	while (isALNUM(*s))
	    s++;
	if (*s && c == *s && s[1] == ']') {
	    if (ckWARN(WARN_REGEXP))
		vWARN3(s+2,
			"POSIX syntax [%c %c] belongs inside character classes",
			c, c);

	    /* [[=foo=]] and [[.foo.]] are still future. */
	    if (POSIXCC_NOTYET(c)) {
		/* adjust RExC_parse so the error shows after
		   the class closes */
		while (UCHARAT(RExC_parse) && UCHARAT(RExC_parse++) != ']')
		    NOOP;
		Simple_vFAIL3("POSIX syntax [%c %c] is reserved for future extensions", c, c);
	    }
	}
    }
}


/*
   parse a class specification and produce either an ANYOF node that
   matches the pattern. If the pattern matches a single char only and
   that char is < 256 then we produce an EXACT node instead.
*/
STATIC regnode *
S_regclass(pTHX_ RExC_state_t *pRExC_state, U32 depth)
{
    dVAR;
    register UV value = 0;
    register UV nextvalue;
    register IV prevvalue = OOB_UNICODE;
    register IV range = 0;
    register regnode *ret;
    STRLEN numlen;
    IV namedclass;
    char *rangebegin = NULL;
    bool need_class = 0;
    SV *listsv = NULL;
    UV n;
    bool optimize_invert   = TRUE;
    AV* unicode_alternate  = NULL;
#ifdef EBCDIC
    UV literal_endpoint = 0;
#endif
    UV stored = 0;  /* number of chars stored in the class */

    regnode * const orig_emit = RExC_emit; /* Save the original RExC_emit in
        case we need to change the emitted regop to an EXACT. */
    const char * orig_parse = RExC_parse;
    GET_RE_DEBUG_FLAGS_DECL;
#ifndef DEBUGGING
    PERL_UNUSED_ARG(depth);
#endif

    DEBUG_PARSE("clas");

    /* Assume we are going to generate an ANYOF node. */
    ret = reganode(pRExC_state, ANYOF, 0);

    if (!SIZE_ONLY)
	ANYOF_FLAGS(ret) = 0;

    if (UCHARAT(RExC_parse) == '^') {	/* Complement of range. */
	RExC_naughty++;
	RExC_parse++;
	if (!SIZE_ONLY)
	    ANYOF_FLAGS(ret) |= ANYOF_INVERT;
    }

    if (SIZE_ONLY) {
	RExC_size += ANYOF_SKIP;
	listsv = &PL_sv_undef; /* For code scanners: listsv always non-NULL. */
    }
    else {
 	RExC_emit += ANYOF_SKIP;
	if (FOLD)
	    ANYOF_FLAGS(ret) |= ANYOF_FOLD;
	if (LOC)
	    ANYOF_FLAGS(ret) |= ANYOF_LOCALE;
	ANYOF_BITMAP_ZERO(ret);
	listsv = newSVpvs("# comment\n");
    }

    nextvalue = RExC_parse < RExC_end ? UCHARAT(RExC_parse) : 0;

    if (!SIZE_ONLY && POSIXCC(nextvalue))
	checkposixcc(pRExC_state);

    /* allow 1st char to be ] (allowing it to be - is dealt with later) */
    if (UCHARAT(RExC_parse) == ']')
	goto charclassloop;

parseit:
    while (RExC_parse < RExC_end && UCHARAT(RExC_parse) != ']') {

    charclassloop:

	namedclass = OOB_NAMEDCLASS; /* initialize as illegal */

	if (!range)
	    rangebegin = RExC_parse;
	if (UTF) {
	    value = utf8n_to_uvchr((U8*)RExC_parse,
				   RExC_end - RExC_parse,
				   &numlen, UTF8_ALLOW_DEFAULT);
	    RExC_parse += numlen;
	}
	else
	    value = UCHARAT(RExC_parse++);

	nextvalue = RExC_parse < RExC_end ? UCHARAT(RExC_parse) : 0;
	if (value == '[' && POSIXCC(nextvalue))
	    namedclass = regpposixcc(pRExC_state, value);
	else if (value == '\\') {
	    if (UTF) {
		value = utf8n_to_uvchr((U8*)RExC_parse,
				   RExC_end - RExC_parse,
				   &numlen, UTF8_ALLOW_DEFAULT);
		RExC_parse += numlen;
	    }
	    else
		value = UCHARAT(RExC_parse++);
	    /* Some compilers cannot handle switching on 64-bit integer
	     * values, therefore value cannot be an UV.  Yes, this will
	     * be a problem later if we want switch on Unicode.
	     * A similar issue a little bit later when switching on
	     * namedclass. --jhi */
	    switch ((I32)value) {
	    case 'w':	namedclass = ANYOF_ALNUM;	break;
	    case 'W':	namedclass = ANYOF_NALNUM;	break;
	    case 's':	namedclass = ANYOF_SPACE;	break;
	    case 'S':	namedclass = ANYOF_NSPACE;	break;
	    case 'd':	namedclass = ANYOF_DIGIT;	break;
	    case 'D':	namedclass = ANYOF_NDIGIT;	break;
            case 'N':  /* Handle \N{NAME} in class */
                {
                    /* We only pay attention to the first char of 
                    multichar strings being returned. I kinda wonder
                    if this makes sense as it does change the behaviour
                    from earlier versions, OTOH that behaviour was broken
                    as well. */
                    UV v; /* value is register so we cant & it /grrr */
                    if (reg_namedseq(pRExC_state, &v)) {
                        goto parseit;
                    }
                    value= v; 
                }
                break;
	    case 'p':
	    case 'P':
		{
		char *e;
		if (RExC_parse >= RExC_end)
		    vFAIL2("Empty \\%c{}", (U8)value);
		if (*RExC_parse == '{') {
		    const U8 c = (U8)value;
		    e = strchr(RExC_parse++, '}');
                    if (!e)
                        vFAIL2("Missing right brace on \\%c{}", c);
		    while (isSPACE(UCHARAT(RExC_parse)))
		        RExC_parse++;
                    if (e == RExC_parse)
                        vFAIL2("Empty \\%c{}", c);
		    n = e - RExC_parse;
		    while (isSPACE(UCHARAT(RExC_parse + n - 1)))
		        n--;
		}
		else {
		    e = RExC_parse;
		    n = 1;
		}
		if (!SIZE_ONLY) {
		    if (UCHARAT(RExC_parse) == '^') {
			 RExC_parse++;
			 n--;
			 value = value == 'p' ? 'P' : 'p'; /* toggle */
			 while (isSPACE(UCHARAT(RExC_parse))) {
			      RExC_parse++;
			      n--;
			 }
		    }
		    Perl_sv_catpvf(aTHX_ listsv, "%cutf8::%.*s\n",
			(value=='p' ? '+' : '!'), (int)n, RExC_parse);
		}
		RExC_parse = e + 1;
		ANYOF_FLAGS(ret) |= ANYOF_UNICODE;
		namedclass = ANYOF_MAX;  /* no official name, but it's named */
		}
		break;
	    case 'n':	value = '\n';			break;
	    case 'r':	value = '\r';			break;
	    case 't':	value = '\t';			break;
	    case 'f':	value = '\f';			break;
	    case 'b':	value = '\b';			break;
	    case 'e':	value = ASCII_TO_NATIVE('\033');break;
	    case 'a':	value = ASCII_TO_NATIVE('\007');break;
	    case 'x':
		if (*RExC_parse == '{') {
                    I32 flags = PERL_SCAN_ALLOW_UNDERSCORES
                        | PERL_SCAN_DISALLOW_PREFIX;
		    char * const e = strchr(RExC_parse++, '}');
                    if (!e)
                        vFAIL("Missing right brace on \\x{}");

		    numlen = e - RExC_parse;
		    value = grok_hex(RExC_parse, &numlen, &flags, NULL);
		    RExC_parse = e + 1;
		}
		else {
                    I32 flags = PERL_SCAN_DISALLOW_PREFIX;
		    numlen = 2;
		    value = grok_hex(RExC_parse, &numlen, &flags, NULL);
		    RExC_parse += numlen;
		}
		if (PL_encoding && value < 0x100)
		    goto recode_encoding;
		break;
	    case 'c':
		value = UCHARAT(RExC_parse++);
		value = toCTRL(value);
		break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
		{
		    I32 flags = 0;
		    numlen = 3;
		    value = grok_oct(--RExC_parse, &numlen, &flags, NULL);
		    RExC_parse += numlen;
		    if (PL_encoding && value < 0x100)
			goto recode_encoding;
		    break;
		}
	    recode_encoding:
		{
		    SV* enc = PL_encoding;
		    value = reg_recode((const char)(U8)value, &enc);
		    if (!enc && SIZE_ONLY && ckWARN(WARN_REGEXP))
			vWARN(RExC_parse,
			      "Invalid escape in the specified encoding");
		    break;
		}
	    default:
		if (!SIZE_ONLY && isALPHA(value) && ckWARN(WARN_REGEXP))
		    vWARN2(RExC_parse,
			   "Unrecognized escape \\%c in character class passed through",
			   (int)value);
		break;
	    }
	} /* end of \blah */
#ifdef EBCDIC
	else
	    literal_endpoint++;
#endif

	if (namedclass > OOB_NAMEDCLASS) { /* this is a named class \blah */

	    if (!SIZE_ONLY && !need_class)
		ANYOF_CLASS_ZERO(ret);

	    need_class = 1;

	    /* a bad range like a-\d, a-[:digit:] ? */
	    if (range) {
		if (!SIZE_ONLY) {
		    if (ckWARN(WARN_REGEXP)) {
			const int w =
			    RExC_parse >= rangebegin ?
			    RExC_parse - rangebegin : 0;
			vWARN4(RExC_parse,
			       "False [] range \"%*.*s\"",
			       w, w, rangebegin);
		    }
		    if (prevvalue < 256) {
			ANYOF_BITMAP_SET(ret, prevvalue);
			ANYOF_BITMAP_SET(ret, '-');
		    }
		    else {
			ANYOF_FLAGS(ret) |= ANYOF_UNICODE;
			Perl_sv_catpvf(aTHX_ listsv,
				       "%04"UVxf"\n%04"UVxf"\n", (UV)prevvalue, (UV) '-');
		    }
		}

		range = 0; /* this was not a true range */
	    }

	    if (!SIZE_ONLY) {
		const char *what = NULL;
		char yesno = 0;

	        if (namedclass > OOB_NAMEDCLASS)
		    optimize_invert = FALSE;
		/* Possible truncation here but in some 64-bit environments
		 * the compiler gets heartburn about switch on 64-bit values.
		 * A similar issue a little earlier when switching on value.
		 * --jhi */
		switch ((I32)namedclass) {
		case ANYOF_ALNUM:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_ALNUM);
		    else {
			for (value = 0; value < 256; value++)
			    if (isALNUM(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Word";	
		    break;
		case ANYOF_NALNUM:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NALNUM);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isALNUM(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Word";
		    break;
		case ANYOF_ALNUMC:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_ALNUMC);
		    else {
			for (value = 0; value < 256; value++)
			    if (isALNUMC(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Alnum";
		    break;
		case ANYOF_NALNUMC:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NALNUMC);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isALNUMC(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Alnum";
		    break;
		case ANYOF_ALPHA:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_ALPHA);
		    else {
			for (value = 0; value < 256; value++)
			    if (isALPHA(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Alpha";
		    break;
		case ANYOF_NALPHA:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NALPHA);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isALPHA(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Alpha";
		    break;
		case ANYOF_ASCII:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_ASCII);
		    else {
#ifndef EBCDIC
			for (value = 0; value < 128; value++)
			    ANYOF_BITMAP_SET(ret, value);
#else  /* EBCDIC */
			for (value = 0; value < 256; value++) {
			    if (isASCII(value))
			        ANYOF_BITMAP_SET(ret, value);
			}
#endif /* EBCDIC */
		    }
		    yesno = '+';
		    what = "ASCII";
		    break;
		case ANYOF_NASCII:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NASCII);
		    else {
#ifndef EBCDIC
			for (value = 128; value < 256; value++)
			    ANYOF_BITMAP_SET(ret, value);
#else  /* EBCDIC */
			for (value = 0; value < 256; value++) {
			    if (!isASCII(value))
			        ANYOF_BITMAP_SET(ret, value);
			}
#endif /* EBCDIC */
		    }
		    yesno = '!';
		    what = "ASCII";
		    break;
		case ANYOF_BLANK:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_BLANK);
		    else {
			for (value = 0; value < 256; value++)
			    if (isBLANK(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Blank";
		    break;
		case ANYOF_NBLANK:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NBLANK);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isBLANK(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Blank";
		    break;
		case ANYOF_CNTRL:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_CNTRL);
		    else {
			for (value = 0; value < 256; value++)
			    if (isCNTRL(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Cntrl";
		    break;
		case ANYOF_NCNTRL:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NCNTRL);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isCNTRL(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Cntrl";
		    break;
		case ANYOF_DIGIT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_DIGIT);
		    else {
			/* consecutive digits assumed */
			for (value = '0'; value <= '9'; value++)
			    ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Digit";
		    break;
		case ANYOF_NDIGIT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NDIGIT);
		    else {
			/* consecutive digits assumed */
			for (value = 0; value < '0'; value++)
			    ANYOF_BITMAP_SET(ret, value);
			for (value = '9' + 1; value < 256; value++)
			    ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Digit";
		    break;
		case ANYOF_GRAPH:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_GRAPH);
		    else {
			for (value = 0; value < 256; value++)
			    if (isGRAPH(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Graph";
		    break;
		case ANYOF_NGRAPH:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NGRAPH);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isGRAPH(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Graph";
		    break;
		case ANYOF_LOWER:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_LOWER);
		    else {
			for (value = 0; value < 256; value++)
			    if (isLOWER(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Lower";
		    break;
		case ANYOF_NLOWER:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NLOWER);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isLOWER(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Lower";
		    break;
		case ANYOF_PRINT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_PRINT);
		    else {
			for (value = 0; value < 256; value++)
			    if (isPRINT(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Print";
		    break;
		case ANYOF_NPRINT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NPRINT);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isPRINT(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Print";
		    break;
		case ANYOF_PSXSPC:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_PSXSPC);
		    else {
			for (value = 0; value < 256; value++)
			    if (isPSXSPC(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Space";
		    break;
		case ANYOF_NPSXSPC:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NPSXSPC);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isPSXSPC(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Space";
		    break;
		case ANYOF_PUNCT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_PUNCT);
		    else {
			for (value = 0; value < 256; value++)
			    if (isPUNCT(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Punct";
		    break;
		case ANYOF_NPUNCT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NPUNCT);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isPUNCT(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Punct";
		    break;
		case ANYOF_SPACE:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_SPACE);
		    else {
			for (value = 0; value < 256; value++)
			    if (isSPACE(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "SpacePerl";
		    break;
		case ANYOF_NSPACE:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NSPACE);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isSPACE(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "SpacePerl";
		    break;
		case ANYOF_UPPER:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_UPPER);
		    else {
			for (value = 0; value < 256; value++)
			    if (isUPPER(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "Upper";
		    break;
		case ANYOF_NUPPER:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NUPPER);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isUPPER(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "Upper";
		    break;
		case ANYOF_XDIGIT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_XDIGIT);
		    else {
			for (value = 0; value < 256; value++)
			    if (isXDIGIT(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '+';
		    what = "XDigit";
		    break;
		case ANYOF_NXDIGIT:
		    if (LOC)
			ANYOF_CLASS_SET(ret, ANYOF_NXDIGIT);
		    else {
			for (value = 0; value < 256; value++)
			    if (!isXDIGIT(value))
				ANYOF_BITMAP_SET(ret, value);
		    }
		    yesno = '!';
		    what = "XDigit";
		    break;
		case ANYOF_MAX:
		    /* this is to handle \p and \P */
		    break;
		default:
		    vFAIL("Invalid [::] class");
		    break;
		}
		if (what) {
		    /* Strings such as "+utf8::isWord\n" */
		    Perl_sv_catpvf(aTHX_ listsv, "%cutf8::Is%s\n", yesno, what);
		}
		if (LOC)
		    ANYOF_FLAGS(ret) |= ANYOF_CLASS;
		continue;
	    }
	} /* end of namedclass \blah */

	if (range) {
	    if (prevvalue > (IV)value) /* b-a */ {
		const int w = RExC_parse - rangebegin;
		Simple_vFAIL4("Invalid [] range \"%*.*s\"", w, w, rangebegin);
		range = 0; /* not a valid range */
	    }
	}
	else {
	    prevvalue = value; /* save the beginning of the range */
	    if (*RExC_parse == '-' && RExC_parse+1 < RExC_end &&
		RExC_parse[1] != ']') {
		RExC_parse++;

		/* a bad range like \w-, [:word:]- ? */
		if (namedclass > OOB_NAMEDCLASS) {
		    if (ckWARN(WARN_REGEXP)) {
			const int w =
			    RExC_parse >= rangebegin ?
			    RExC_parse - rangebegin : 0;
			vWARN4(RExC_parse,
			       "False [] range \"%*.*s\"",
			       w, w, rangebegin);
		    }
		    if (!SIZE_ONLY)
			ANYOF_BITMAP_SET(ret, '-');
		} else
		    range = 1;	/* yeah, it's a range! */
		continue;	/* but do it the next time */
	    }
	}

	/* now is the next time */
        /*stored += (value - prevvalue + 1);*/
	if (!SIZE_ONLY) {
	    if (prevvalue < 256) {
	        const IV ceilvalue = value < 256 ? value : 255;
		IV i;
#ifdef EBCDIC
		/* In EBCDIC [\x89-\x91] should include
		 * the \x8e but [i-j] should not. */
		if (literal_endpoint == 2 &&
		    ((isLOWER(prevvalue) && isLOWER(ceilvalue)) ||
		     (isUPPER(prevvalue) && isUPPER(ceilvalue))))
		{
		    if (isLOWER(prevvalue)) {
			for (i = prevvalue; i <= ceilvalue; i++)
			    if (isLOWER(i))
				ANYOF_BITMAP_SET(ret, i);
		    } else {
			for (i = prevvalue; i <= ceilvalue; i++)
			    if (isUPPER(i))
				ANYOF_BITMAP_SET(ret, i);
		    }
		}
		else
#endif
		      for (i = prevvalue; i <= ceilvalue; i++) {
		        if (!ANYOF_BITMAP_TEST(ret,i)) {
		            stored++;  
			    ANYOF_BITMAP_SET(ret, i);
		        }
	              }
	  }
	  if (value > 255 || UTF) {
	        const UV prevnatvalue  = NATIVE_TO_UNI(prevvalue);
		const UV natvalue      = NATIVE_TO_UNI(value);
                stored+=2; /* can't optimize this class */
		ANYOF_FLAGS(ret) |= ANYOF_UNICODE;
		if (prevnatvalue < natvalue) { /* what about > ? */
		    Perl_sv_catpvf(aTHX_ listsv, "%04"UVxf"\t%04"UVxf"\n",
				   prevnatvalue, natvalue);
		}
		else if (prevnatvalue == natvalue) {
		    Perl_sv_catpvf(aTHX_ listsv, "%04"UVxf"\n", natvalue);
		    if (FOLD) {
			 U8 foldbuf[UTF8_MAXBYTES_CASE+1];
			 STRLEN foldlen;
			 const UV f = to_uni_fold(natvalue, foldbuf, &foldlen);

#ifdef EBCDIC /* RD t/uni/fold ff and 6b */
			 if (RExC_precomp[0] == ':' &&
			     RExC_precomp[1] == '[' &&
			     (f == 0xDF || f == 0x92)) {
			     f = NATIVE_TO_UNI(f);
                        }
#endif
			 /* If folding and foldable and a single
			  * character, insert also the folded version
			  * to the charclass. */
			 if (f != value) {
#ifdef EBCDIC /* RD tunifold ligatures s,t fb05, fb06 */
			     if ((RExC_precomp[0] == ':' &&
				  RExC_precomp[1] == '[' &&
				  (f == 0xA2 &&
				   (value == 0xFB05 || value == 0xFB06))) ?
				 foldlen == ((STRLEN)UNISKIP(f) - 1) :
				 foldlen == (STRLEN)UNISKIP(f) )
#else
			      if (foldlen == (STRLEN)UNISKIP(f))
#endif
				  Perl_sv_catpvf(aTHX_ listsv,
						 "%04"UVxf"\n", f);
			      else {
				  /* Any multicharacter foldings
				   * require the following transform:
				   * [ABCDEF] -> (?:[ABCabcDEFd]|pq|rst)
				   * where E folds into "pq" and F folds
				   * into "rst", all other characters
				   * fold to single characters.  We save
				   * away these multicharacter foldings,
				   * to be later saved as part of the
				   * additional "s" data. */
				  SV *sv;

				  if (!unicode_alternate)
				      unicode_alternate = newAV();
				  sv = newSVpvn((char*)foldbuf, foldlen);
				  SvUTF8_on(sv);
				  av_push(unicode_alternate, sv);
			      }
			 }

			 /* If folding and the value is one of the Greek
			  * sigmas insert a few more sigmas to make the
			  * folding rules of the sigmas to work right.
			  * Note that not all the possible combinations
			  * are handled here: some of them are handled
			  * by the standard folding rules, and some of
			  * them (literal or EXACTF cases) are handled
			  * during runtime in regexec.c:S_find_byclass(). */
			 if (value == UNICODE_GREEK_SMALL_LETTER_FINAL_SIGMA) {
			      Perl_sv_catpvf(aTHX_ listsv, "%04"UVxf"\n",
					     (UV)UNICODE_GREEK_CAPITAL_LETTER_SIGMA);
			      Perl_sv_catpvf(aTHX_ listsv, "%04"UVxf"\n",
					     (UV)UNICODE_GREEK_SMALL_LETTER_SIGMA);
			 }
			 else if (value == UNICODE_GREEK_CAPITAL_LETTER_SIGMA)
			      Perl_sv_catpvf(aTHX_ listsv, "%04"UVxf"\n",
					     (UV)UNICODE_GREEK_SMALL_LETTER_SIGMA);
		    }
		}
	    }
#ifdef EBCDIC
	    literal_endpoint = 0;
#endif
        }

	range = 0; /* this range (if it was one) is done now */
    }

    if (need_class) {
	ANYOF_FLAGS(ret) |= ANYOF_LARGE;
	if (SIZE_ONLY)
	    RExC_size += ANYOF_CLASS_ADD_SKIP;
	else
	    RExC_emit += ANYOF_CLASS_ADD_SKIP;
    }


    if (SIZE_ONLY)
        return ret;
    /****** !SIZE_ONLY AFTER HERE *********/

    if( stored == 1 && value < 256
        && !( ANYOF_FLAGS(ret) & ( ANYOF_FLAGS_ALL ^ ANYOF_FOLD ) )
    ) {
        /* optimize single char class to an EXACT node
           but *only* when its not a UTF/high char  */
        const char * cur_parse= RExC_parse;
        RExC_emit = (regnode *)orig_emit;
        RExC_parse = (char *)orig_parse;
        ret = reg_node(pRExC_state,
                       (U8)((ANYOF_FLAGS(ret) & ANYOF_FOLD) ? EXACTF : EXACT));
        RExC_parse = (char *)cur_parse;
        *STRING(ret)= (char)value;
        STR_LEN(ret)= 1;
        RExC_emit += STR_SZ(1);
        return ret;
    }
    /* optimize case-insensitive simple patterns (e.g. /[a-z]/i) */
    if ( /* If the only flag is folding (plus possibly inversion). */
	((ANYOF_FLAGS(ret) & (ANYOF_FLAGS_ALL ^ ANYOF_INVERT)) == ANYOF_FOLD)
       ) {
	for (value = 0; value < 256; ++value) {
	    if (ANYOF_BITMAP_TEST(ret, value)) {
		UV fold = PL_fold[value];

		if (fold != value)
		    ANYOF_BITMAP_SET(ret, fold);
	    }
	}
	ANYOF_FLAGS(ret) &= ~ANYOF_FOLD;
    }

    /* optimize inverted simple patterns (e.g. [^a-z]) */
    if (optimize_invert &&
	/* If the only flag is inversion. */
	(ANYOF_FLAGS(ret) & ANYOF_FLAGS_ALL) ==	ANYOF_INVERT) {
	for (value = 0; value < ANYOF_BITMAP_SIZE; ++value)
	    ANYOF_BITMAP(ret)[value] ^= ANYOF_FLAGS_ALL;
	ANYOF_FLAGS(ret) = ANYOF_UNICODE_ALL;
    }
    {
	AV * const av = newAV();
	SV *rv;
	/* The 0th element stores the character class description
	 * in its textual form: used later (regexec.c:Perl_regclass_swash())
	 * to initialize the appropriate swash (which gets stored in
	 * the 1st element), and also useful for dumping the regnode.
	 * The 2nd element stores the multicharacter foldings,
	 * used later (regexec.c:S_reginclass()). */
	av_store(av, 0, listsv);
	av_store(av, 1, NULL);
	av_store(av, 2, (SV*)unicode_alternate);
	rv = newRV_noinc((SV*)av);
	n = add_data(pRExC_state, 1, "s");
	RExC_rx->data->data[n] = (void*)rv;
	ARG_SET(ret, n);
    }
    return ret;
}

STATIC char*
S_nextchar(pTHX_ RExC_state_t *pRExC_state)
{
    char* const retval = RExC_parse++;

    for (;;) {
	if (*RExC_parse == '(' && RExC_parse[1] == '?' &&
		RExC_parse[2] == '#') {
	    while (*RExC_parse != ')') {
		if (RExC_parse == RExC_end)
		    FAIL("Sequence (?#... not terminated");
		RExC_parse++;
	    }
	    RExC_parse++;
	    continue;
	}
	if (RExC_flags & PMf_EXTENDED) {
	    if (isSPACE(*RExC_parse)) {
		RExC_parse++;
		continue;
	    }
	    else if (*RExC_parse == '#') {
		while (RExC_parse < RExC_end)
		    if (*RExC_parse++ == '\n') break;
		continue;
	    }
	}
	return retval;
    }
}

/*
- reg_node - emit a node
*/
STATIC regnode *			/* Location. */
S_reg_node(pTHX_ RExC_state_t *pRExC_state, U8 op)
{
    dVAR;
    register regnode *ptr;
    regnode * const ret = RExC_emit;
    GET_RE_DEBUG_FLAGS_DECL;

    if (SIZE_ONLY) {
	SIZE_ALIGN(RExC_size);
	RExC_size += 1;
	return(ret);
    }
#ifdef DEBUGGING
    if (OP(RExC_emit) == 255)
        Perl_croak(aTHX_ "panic: reg_node overrun trying to emit %s: %d ",
            reg_name[op], OP(RExC_emit));
#endif  
    NODE_ALIGN_FILL(ret);
    ptr = ret;
    FILL_ADVANCE_NODE(ptr, op);
    if (RExC_offsets) {         /* MJD */
	MJD_OFFSET_DEBUG(("%s:%d: (op %s) %s %"UVuf" (len %"UVuf") (max %"UVuf").\n", 
              "reg_node", __LINE__, 
              reg_name[op],
              (UV)(RExC_emit - RExC_emit_start) > RExC_offsets[0] 
		? "Overwriting end of array!\n" : "OK",
              (UV)(RExC_emit - RExC_emit_start),
              (UV)(RExC_parse - RExC_start),
              (UV)RExC_offsets[0])); 
	Set_Node_Offset(RExC_emit, RExC_parse + (op == END));
    }

    RExC_emit = ptr;
    return(ret);
}

/*
- reganode - emit a node with an argument
*/
STATIC regnode *			/* Location. */
S_reganode(pTHX_ RExC_state_t *pRExC_state, U8 op, U32 arg)
{
    dVAR;
    register regnode *ptr;
    regnode * const ret = RExC_emit;
    GET_RE_DEBUG_FLAGS_DECL;

    if (SIZE_ONLY) {
	SIZE_ALIGN(RExC_size);
	RExC_size += 2;
	/* 
	   We can't do this:
	   
	   assert(2==regarglen[op]+1); 
	
	   Anything larger than this has to allocate the extra amount.
	   If we changed this to be:
	   
	   RExC_size += (1 + regarglen[op]);
	   
	   then it wouldn't matter. Its not clear what side effect
	   might come from that so its not done so far.
	   -- dmq
	*/
	return(ret);
    }
#ifdef DEBUGGING
    if (OP(RExC_emit) == 255)
        Perl_croak(aTHX_ "panic: reganode overwriting end of allocated program space");
#endif 
    NODE_ALIGN_FILL(ret);
    ptr = ret;
    FILL_ADVANCE_NODE_ARG(ptr, op, arg);
    if (RExC_offsets) {         /* MJD */
	MJD_OFFSET_DEBUG(("%s(%d): (op %s) %s %"UVuf" <- %"UVuf" (max %"UVuf").\n", 
              "reganode",
	      __LINE__,
	      reg_name[op],
              (UV)(RExC_emit - RExC_emit_start) > RExC_offsets[0] ? 
              "Overwriting end of array!\n" : "OK",
              (UV)(RExC_emit - RExC_emit_start),
              (UV)(RExC_parse - RExC_start),
              (UV)RExC_offsets[0])); 
	Set_Cur_Node_Offset;
    }
            
    RExC_emit = ptr;
    return(ret);
}

/*
- reguni - emit (if appropriate) a Unicode character
*/
STATIC STRLEN
S_reguni(pTHX_ const RExC_state_t *pRExC_state, UV uv, char* s)
{
    dVAR;
    return SIZE_ONLY ? UNISKIP(uv) : (uvchr_to_utf8((U8*)s, uv) - (U8*)s);
}

/*
- reginsert - insert an operator in front of already-emitted operand
*
* Means relocating the operand.
*/
STATIC void
S_reginsert(pTHX_ RExC_state_t *pRExC_state, U8 op, regnode *opnd, U32 depth)
{
    dVAR;
    register regnode *src;
    register regnode *dst;
    register regnode *place;
    const int offset = regarglen[(U8)op];
    const int size = NODE_STEP_REGNODE + offset;
    GET_RE_DEBUG_FLAGS_DECL;
/* (PL_regkind[(U8)op] == CURLY ? EXTRA_STEP_2ARGS : 0); */
    DEBUG_PARSE_FMT("inst"," - %s",reg_name[op]);
    if (SIZE_ONLY) {
	RExC_size += size;
	return;
    }

    src = RExC_emit;
    RExC_emit += size;
    dst = RExC_emit;
    if (RExC_open_parens) {
        int paren;
        DEBUG_PARSE_FMT("inst"," - %"IVdf, (IV)RExC_npar);
        for ( paren=0 ; paren < RExC_npar ; paren++ ) {
            if ( RExC_open_parens[paren] >= opnd ) {
                DEBUG_PARSE_FMT("open"," - %d",size);
                RExC_open_parens[paren] += size;
            } else {
                DEBUG_PARSE_FMT("open"," - %s","ok");
            }
            if ( RExC_close_parens[paren] >= opnd ) {
                DEBUG_PARSE_FMT("close"," - %d",size);
                RExC_close_parens[paren] += size;
            } else {
                DEBUG_PARSE_FMT("close"," - %s","ok");
            }
        }
    }

    while (src > opnd) {
	StructCopy(--src, --dst, regnode);
        if (RExC_offsets) {     /* MJD 20010112 */
	    MJD_OFFSET_DEBUG(("%s(%d): (op %s) %s copy %"UVuf" -> %"UVuf" (max %"UVuf").\n",
                  "reg_insert",
		  __LINE__,
		  reg_name[op],
                  (UV)(dst - RExC_emit_start) > RExC_offsets[0] 
		    ? "Overwriting end of array!\n" : "OK",
                  (UV)(src - RExC_emit_start),
                  (UV)(dst - RExC_emit_start),
                  (UV)RExC_offsets[0])); 
	    Set_Node_Offset_To_R(dst-RExC_emit_start, Node_Offset(src));
	    Set_Node_Length_To_R(dst-RExC_emit_start, Node_Length(src));
        }
    }
    

    place = opnd;		/* Op node, where operand used to be. */
    if (RExC_offsets) {         /* MJD */
	MJD_OFFSET_DEBUG(("%s(%d): (op %s) %s %"UVuf" <- %"UVuf" (max %"UVuf").\n", 
              "reginsert",
	      __LINE__,
	      reg_name[op],
              (UV)(place - RExC_emit_start) > RExC_offsets[0] 
              ? "Overwriting end of array!\n" : "OK",
              (UV)(place - RExC_emit_start),
              (UV)(RExC_parse - RExC_start),
              (UV)RExC_offsets[0]));
	Set_Node_Offset(place, RExC_parse);
	Set_Node_Length(place, 1);
    }
    src = NEXTOPER(place);
    FILL_ADVANCE_NODE(place, op);
    Zero(src, offset, regnode);
}

/*
- regtail - set the next-pointer at the end of a node chain of p to val.
- SEE ALSO: regtail_study
*/
/* TODO: All three parms should be const */
STATIC void
S_regtail(pTHX_ RExC_state_t *pRExC_state, regnode *p, const regnode *val,U32 depth)
{
    dVAR;
    register regnode *scan;
    GET_RE_DEBUG_FLAGS_DECL;
#ifndef DEBUGGING
    PERL_UNUSED_ARG(depth);
#endif

    if (SIZE_ONLY)
	return;

    /* Find last node. */
    scan = p;
    for (;;) {
	regnode * const temp = regnext(scan);
        DEBUG_PARSE_r({
            SV * const mysv=sv_newmortal();
            DEBUG_PARSE_MSG((scan==p ? "tail" : ""));
            regprop(RExC_rx, mysv, scan);
            PerlIO_printf(Perl_debug_log, "~ %s (%d) %s %s\n",
                SvPV_nolen_const(mysv), REG_NODE_NUM(scan),
                    (temp == NULL ? "->" : ""),
                    (temp == NULL ? reg_name[OP(val)] : "")
            );
        });
        if (temp == NULL)
            break;
        scan = temp;
    }

    if (reg_off_by_arg[OP(scan)]) {
        ARG_SET(scan, val - scan);
    }
    else {
        NEXT_OFF(scan) = val - scan;
    }
}

#ifdef DEBUGGING
/*
- regtail_study - set the next-pointer at the end of a node chain of p to val.
- Look for optimizable sequences at the same time.
- currently only looks for EXACT chains.

This is expermental code. The idea is to use this routine to perform 
in place optimizations on branches and groups as they are constructed,
with the long term intention of removing optimization from study_chunk so
that it is purely analytical.

Currently only used when in DEBUG mode. The macro REGTAIL_STUDY() is used
to control which is which.

*/
/* TODO: All four parms should be const */

STATIC U8
S_regtail_study(pTHX_ RExC_state_t *pRExC_state, regnode *p, const regnode *val,U32 depth)
{
    dVAR;
    register regnode *scan;
    U8 exact = PSEUDO;
#ifdef EXPERIMENTAL_INPLACESCAN
    I32 min = 0;
#endif

    GET_RE_DEBUG_FLAGS_DECL;


    if (SIZE_ONLY)
        return exact;

    /* Find last node. */

    scan = p;
    for (;;) {
        regnode * const temp = regnext(scan);
#ifdef EXPERIMENTAL_INPLACESCAN
        if (PL_regkind[OP(scan)] == EXACT)
            if (join_exact(pRExC_state,scan,&min,1,val,depth+1))
                return EXACT;
#endif
        if ( exact ) {
            switch (OP(scan)) {
                case EXACT:
                case EXACTF:
                case EXACTFL:
                        if( exact == PSEUDO )
                            exact= OP(scan);
                        else if ( exact != OP(scan) )
                            exact= 0;
                case NOTHING:
                    break;
                default:
                    exact= 0;
            }
        }
        DEBUG_PARSE_r({
            SV * const mysv=sv_newmortal();
            DEBUG_PARSE_MSG((scan==p ? "tsdy" : ""));
            regprop(RExC_rx, mysv, scan);
            PerlIO_printf(Perl_debug_log, "~ %s (%d) -> %s\n",
                SvPV_nolen_const(mysv),
                REG_NODE_NUM(scan),
                reg_name[exact]);
        });
	if (temp == NULL)
	    break;
	scan = temp;
    }
    DEBUG_PARSE_r({
        SV * const mysv_val=sv_newmortal();
        DEBUG_PARSE_MSG("");
        regprop(RExC_rx, mysv_val, val);
        PerlIO_printf(Perl_debug_log, "~ attach to %s (%d) offset to %d\n",
            SvPV_nolen_const(mysv_val),
            REG_NODE_NUM(val),
            val - scan
        );
    });
    if (reg_off_by_arg[OP(scan)]) {
	ARG_SET(scan, val - scan);
    }
    else {
	NEXT_OFF(scan) = val - scan;
    }

    return exact;
}
#endif

/*
 - regcurly - a little FSA that accepts {\d+,?\d*}
 */
STATIC I32
S_regcurly(register const char *s)
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


/*
 - regdump - dump a regexp onto Perl_debug_log in vaguely comprehensible form
 */
void
Perl_regdump(pTHX_ const regexp *r)
{
#ifdef DEBUGGING
    dVAR;
    SV * const sv = sv_newmortal();
    SV *dsv= sv_newmortal();

    (void)dumpuntil(r, r->program, r->program + 1, NULL, NULL, sv, 0, 0);

    /* Header fields of interest. */
    if (r->anchored_substr) {
	RE_PV_QUOTED_DECL(s, 0, dsv, SvPVX_const(r->anchored_substr), 
	    RE_SV_DUMPLEN(r->anchored_substr), 30);
	PerlIO_printf(Perl_debug_log,
		      "anchored %s%s at %"IVdf" ",
		      s, RE_SV_TAIL(r->anchored_substr),
		      (IV)r->anchored_offset);
    } else if (r->anchored_utf8) {
	RE_PV_QUOTED_DECL(s, 1, dsv, SvPVX_const(r->anchored_utf8), 
	    RE_SV_DUMPLEN(r->anchored_utf8), 30);
	PerlIO_printf(Perl_debug_log,
		      "anchored utf8 %s%s at %"IVdf" ",
		      s, RE_SV_TAIL(r->anchored_utf8),
		      (IV)r->anchored_offset);
    }		      
    if (r->float_substr) {
	RE_PV_QUOTED_DECL(s, 0, dsv, SvPVX_const(r->float_substr), 
	    RE_SV_DUMPLEN(r->float_substr), 30);
	PerlIO_printf(Perl_debug_log,
		      "floating %s%s at %"IVdf"..%"UVuf" ",
		      s, RE_SV_TAIL(r->float_substr),
		      (IV)r->float_min_offset, (UV)r->float_max_offset);
    } else if (r->float_utf8) {
	RE_PV_QUOTED_DECL(s, 1, dsv, SvPVX_const(r->float_utf8), 
	    RE_SV_DUMPLEN(r->float_utf8), 30);
	PerlIO_printf(Perl_debug_log,
		      "floating utf8 %s%s at %"IVdf"..%"UVuf" ",
		      s, RE_SV_TAIL(r->float_utf8),
		      (IV)r->float_min_offset, (UV)r->float_max_offset);
    }
    if (r->check_substr || r->check_utf8)
	PerlIO_printf(Perl_debug_log,
		      (const char *)
		      (r->check_substr == r->float_substr
		       && r->check_utf8 == r->float_utf8
		       ? "(checking floating" : "(checking anchored"));
    if (r->reganch & ROPT_NOSCAN)
	PerlIO_printf(Perl_debug_log, " noscan");
    if (r->reganch & ROPT_CHECK_ALL)
	PerlIO_printf(Perl_debug_log, " isall");
    if (r->check_substr || r->check_utf8)
	PerlIO_printf(Perl_debug_log, ") ");

    if (r->regstclass) {
	regprop(r, sv, r->regstclass);
	PerlIO_printf(Perl_debug_log, "stclass %s ", SvPVX_const(sv));
    }
    if (r->reganch & ROPT_ANCH) {
	PerlIO_printf(Perl_debug_log, "anchored");
	if (r->reganch & ROPT_ANCH_BOL)
	    PerlIO_printf(Perl_debug_log, "(BOL)");
	if (r->reganch & ROPT_ANCH_MBOL)
	    PerlIO_printf(Perl_debug_log, "(MBOL)");
	if (r->reganch & ROPT_ANCH_SBOL)
	    PerlIO_printf(Perl_debug_log, "(SBOL)");
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
    if (r->reganch & ROPT_EVAL_SEEN)
	PerlIO_printf(Perl_debug_log, "with eval ");
    PerlIO_printf(Perl_debug_log, "\n");
#else
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(r);
#endif	/* DEBUGGING */
}

/*
- regprop - printable representation of opcode
*/
void
Perl_regprop(pTHX_ const regexp *prog, SV *sv, const regnode *o)
{
#ifdef DEBUGGING
    dVAR;
    register int k;
    GET_RE_DEBUG_FLAGS_DECL;

    sv_setpvn(sv, "", 0);
    
    if (OP(o) > REGNODE_MAX)		/* regnode.type is unsigned */
	/* It would be nice to FAIL() here, but this may be called from
	   regexec.c, and it would be hard to supply pRExC_state. */
	Perl_croak(aTHX_ "Corrupted regexp opcode %d > %d", (int)OP(o), (int)REGNODE_MAX);
    sv_catpv(sv, reg_name[OP(o)]); /* Take off const! */

    k = PL_regkind[OP(o)];

    if (k == EXACT) {
	SV * const dsv = sv_2mortal(newSVpvs(""));
	/* Using is_utf8_string() (via PERL_PV_UNI_DETECT) 
	 * is a crude hack but it may be the best for now since 
	 * we have no flag "this EXACTish node was UTF-8" 
	 * --jhi */
	const char * const s = 
	    pv_pretty(dsv, STRING(o), STR_LEN(o), 60, 
	        PL_colors[0], PL_colors[1],
	        PERL_PV_ESCAPE_UNI_DETECT |
	        PERL_PV_PRETTY_ELIPSES    |
	        PERL_PV_PRETTY_LTGT    
            ); 
	Perl_sv_catpvf(aTHX_ sv, " %s", s );
    } else if (k == TRIE) {
	/* print the details of the trie in dumpuntil instead, as
	 * prog->data isn't available here */
        const char op = OP(o);
        const I32 n = ARG(o);
        const reg_ac_data * const ac = IS_TRIE_AC(op) ?
               (reg_ac_data *)prog->data->data[n] :
               NULL;
        const reg_trie_data * const trie = !IS_TRIE_AC(op) ?
            (reg_trie_data*)prog->data->data[n] :
            ac->trie;
        
        Perl_sv_catpvf(aTHX_ sv, "-%s",reg_name[o->flags]);
        DEBUG_TRIE_COMPILE_r(
            Perl_sv_catpvf(aTHX_ sv,
                "<S:%"UVuf"/%"IVdf" W:%"UVuf" L:%"UVuf"/%"UVuf" C:%"UVuf"/%"UVuf">",
                (UV)trie->startstate,
                (IV)trie->statecount-1, /* -1 because of the unused 0 element */
                (UV)trie->wordcount,
                (UV)trie->minlen,
                (UV)trie->maxlen,
                (UV)TRIE_CHARCOUNT(trie),
                (UV)trie->uniquecharcount
            )
        );
        if ( IS_ANYOF_TRIE(op) || trie->bitmap ) {
            int i;
            int rangestart = -1;
            U8* bitmap = IS_ANYOF_TRIE(op) ? (U8*)ANYOF_BITMAP(o) : (U8*)TRIE_BITMAP(trie);
            Perl_sv_catpvf(aTHX_ sv, "[");
            for (i = 0; i <= 256; i++) {
                if (i < 256 && BITMAP_TEST(bitmap,i)) {
                    if (rangestart == -1)
                        rangestart = i;
                } else if (rangestart != -1) {
                    if (i <= rangestart + 3)
                        for (; rangestart < i; rangestart++)
                            put_byte(sv, rangestart);
                    else {
                        put_byte(sv, rangestart);
                        sv_catpvs(sv, "-");
                        put_byte(sv, i - 1);
                    }
                    rangestart = -1;
                }
            }
            Perl_sv_catpvf(aTHX_ sv, "]");
        } 
	 
    } else if (k == CURLY) {
	if (OP(o) == CURLYM || OP(o) == CURLYN || OP(o) == CURLYX)
	    Perl_sv_catpvf(aTHX_ sv, "[%d]", o->flags); /* Parenth number */
	Perl_sv_catpvf(aTHX_ sv, " {%d,%d}", ARG1(o), ARG2(o));
    }
    else if (k == WHILEM && o->flags)			/* Ordinal/of */
	Perl_sv_catpvf(aTHX_ sv, "[%d/%d]", o->flags & 0xf, o->flags>>4);
    else if (k == REF || k == OPEN || k == CLOSE || k == GROUPP || OP(o)==ACCEPT) 
	Perl_sv_catpvf(aTHX_ sv, "%d", (int)ARG(o));	/* Parenth number */
    else if (k == GOSUB) 
	Perl_sv_catpvf(aTHX_ sv, "%d[%+d]", (int)ARG(o),(int)ARG2L(o));	/* Paren and offset */
    else if (k == VERB) {
        if (!o->flags) 
            Perl_sv_catpvf(aTHX_ sv, ":%"SVf, 
                (SV*)prog->data->data[ ARG( o ) ]);
    } else if (k == LOGICAL)
	Perl_sv_catpvf(aTHX_ sv, "[%d]", o->flags);	/* 2: embedded, otherwise 1 */
    else if (k == ANYOF) {
	int i, rangestart = -1;
	const U8 flags = ANYOF_FLAGS(o);

	/* Should be synchronized with * ANYOF_ #xdefines in regcomp.h */
	static const char * const anyofs[] = {
	    "\\w",
	    "\\W",
	    "\\s",
	    "\\S",
	    "\\d",
	    "\\D",
	    "[:alnum:]",
	    "[:^alnum:]",
	    "[:alpha:]",
	    "[:^alpha:]",
	    "[:ascii:]",
	    "[:^ascii:]",
	    "[:ctrl:]",
	    "[:^ctrl:]",
	    "[:graph:]",
	    "[:^graph:]",
	    "[:lower:]",
	    "[:^lower:]",
	    "[:print:]",
	    "[:^print:]",
	    "[:punct:]",
	    "[:^punct:]",
	    "[:upper:]",
	    "[:^upper:]",
	    "[:xdigit:]",
	    "[:^xdigit:]",
	    "[:space:]",
	    "[:^space:]",
	    "[:blank:]",
	    "[:^blank:]"
	};

	if (flags & ANYOF_LOCALE)
	    sv_catpvs(sv, "{loc}");
	if (flags & ANYOF_FOLD)
	    sv_catpvs(sv, "{i}");
	Perl_sv_catpvf(aTHX_ sv, "[%s", PL_colors[0]);
	if (flags & ANYOF_INVERT)
	    sv_catpvs(sv, "^");
	for (i = 0; i <= 256; i++) {
	    if (i < 256 && ANYOF_BITMAP_TEST(o,i)) {
		if (rangestart == -1)
		    rangestart = i;
	    } else if (rangestart != -1) {
		if (i <= rangestart + 3)
		    for (; rangestart < i; rangestart++)
			put_byte(sv, rangestart);
		else {
		    put_byte(sv, rangestart);
		    sv_catpvs(sv, "-");
		    put_byte(sv, i - 1);
		}
		rangestart = -1;
	    }
	}

	if (o->flags & ANYOF_CLASS)
	    for (i = 0; i < (int)(sizeof(anyofs)/sizeof(char*)); i++)
		if (ANYOF_CLASS_TEST(o,i))
		    sv_catpv(sv, anyofs[i]);

	if (flags & ANYOF_UNICODE)
	    sv_catpvs(sv, "{unicode}");
	else if (flags & ANYOF_UNICODE_ALL)
	    sv_catpvs(sv, "{unicode_all}");

	{
	    SV *lv;
	    SV * const sw = regclass_swash(prog, o, FALSE, &lv, 0);
	
	    if (lv) {
		if (sw) {
		    U8 s[UTF8_MAXBYTES_CASE+1];
		
		    for (i = 0; i <= 256; i++) { /* just the first 256 */
			uvchr_to_utf8(s, i);
			
			if (i < 256 && swash_fetch(sw, s, TRUE)) {
			    if (rangestart == -1)
				rangestart = i;
			} else if (rangestart != -1) {
			    if (i <= rangestart + 3)
				for (; rangestart < i; rangestart++) {
				    const U8 * const e = uvchr_to_utf8(s,rangestart);
				    U8 *p;
				    for(p = s; p < e; p++)
					put_byte(sv, *p);
				}
			    else {
				const U8 *e = uvchr_to_utf8(s,rangestart);
				U8 *p;
				for (p = s; p < e; p++)
				    put_byte(sv, *p);
				sv_catpvs(sv, "-");
				e = uvchr_to_utf8(s, i-1);
				for (p = s; p < e; p++)
				    put_byte(sv, *p);
				}
				rangestart = -1;
			    }
			}
			
		    sv_catpvs(sv, "..."); /* et cetera */
		}

		{
		    char *s = savesvpv(lv);
		    char * const origs = s;
		
		    while (*s && *s != '\n')
			s++;
		
		    if (*s == '\n') {
			const char * const t = ++s;
			
			while (*s) {
			    if (*s == '\n')
				*s = ' ';
			    s++;
			}
			if (s[-1] == ' ')
			    s[-1] = 0;
			
			sv_catpv(sv, t);
		    }
		
		    Safefree(origs);
		}
	    }
	}

	Perl_sv_catpvf(aTHX_ sv, "%s]", PL_colors[1]);
    }
    else if (k == BRANCHJ && (OP(o) == UNLESSM || OP(o) == IFMATCH))
	Perl_sv_catpvf(aTHX_ sv, "[%d]", -(o->flags));
#else
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(o);
    PERL_UNUSED_ARG(prog);
#endif	/* DEBUGGING */
}

SV *
Perl_re_intuit_string(pTHX_ regexp *prog)
{				/* Assume that RE_INTUIT is set */
    dVAR;
    GET_RE_DEBUG_FLAGS_DECL;
    PERL_UNUSED_CONTEXT;

    DEBUG_COMPILE_r(
	{
	    const char * const s = SvPV_nolen_const(prog->check_substr
		      ? prog->check_substr : prog->check_utf8);

	    if (!PL_colorset) reginitcolors();
	    PerlIO_printf(Perl_debug_log,
		      "%sUsing REx %ssubstr:%s \"%s%.60s%s%s\"\n",
		      PL_colors[4],
		      prog->check_substr ? "" : "utf8 ",
		      PL_colors[5],PL_colors[0],
		      s,
		      PL_colors[1],
		      (strlen(s) > 60 ? "..." : ""));
	} );

    return prog->check_substr ? prog->check_substr : prog->check_utf8;
}

/* 
   pregfree - free a regexp
   
   See regdupe below if you change anything here. 
*/

void
Perl_pregfree(pTHX_ struct regexp *r)
{
    dVAR;

    GET_RE_DEBUG_FLAGS_DECL;

    if (!r || (--r->refcnt > 0))
	return;
    DEBUG_COMPILE_r({
	if (!PL_colorset)
	    reginitcolors();
	{
	    SV *dsv= sv_newmortal();
            RE_PV_QUOTED_DECL(s, (r->reganch & ROPT_UTF8),
                dsv, r->precomp, r->prelen, 60);
            PerlIO_printf(Perl_debug_log,"%sFreeing REx:%s %s\n", 
                PL_colors[4],PL_colors[5],s);
        }
    });

    /* gcov results gave these as non-null 100% of the time, so there's no
       optimisation in checking them before calling Safefree  */
    Safefree(r->precomp);
    Safefree(r->offsets);             /* 20010421 MJD */
    RX_MATCH_COPY_FREE(r);
#ifdef PERL_OLD_COPY_ON_WRITE
    if (r->saved_copy)
	SvREFCNT_dec(r->saved_copy);
#endif
    if (r->substrs) {
	if (r->anchored_substr)
	    SvREFCNT_dec(r->anchored_substr);
	if (r->anchored_utf8)
	    SvREFCNT_dec(r->anchored_utf8);
	if (r->float_substr)
	    SvREFCNT_dec(r->float_substr);
	if (r->float_utf8)
	    SvREFCNT_dec(r->float_utf8);
	Safefree(r->substrs);
    }
    if (r->paren_names)
            SvREFCNT_dec(r->paren_names);
    if (r->data) {
	int n = r->data->count;
	PAD* new_comppad = NULL;
	PAD* old_comppad;
	PADOFFSET refcnt;

	while (--n >= 0) {
          /* If you add a ->what type here, update the comment in regcomp.h */
	    switch (r->data->what[n]) {
	    case 's':
	    case 'S':
		SvREFCNT_dec((SV*)r->data->data[n]);
		break;
	    case 'f':
		Safefree(r->data->data[n]);
		break;
	    case 'p':
		new_comppad = (AV*)r->data->data[n];
		break;
	    case 'o':
		if (new_comppad == NULL)
		    Perl_croak(aTHX_ "panic: pregfree comppad");
		PAD_SAVE_LOCAL(old_comppad,
		    /* Watch out for global destruction's random ordering. */
		    (SvTYPE(new_comppad) == SVt_PVAV) ? new_comppad : NULL
		);
		OP_REFCNT_LOCK;
		refcnt = OpREFCNT_dec((OP_4tree*)r->data->data[n]);
		OP_REFCNT_UNLOCK;
		if (!refcnt)
                    op_free((OP_4tree*)r->data->data[n]);

		PAD_RESTORE_LOCAL(old_comppad);
		SvREFCNT_dec((SV*)new_comppad);
		new_comppad = NULL;
		break;
	    case 'n':
	        break;
            case 'T':	        
                { /* Aho Corasick add-on structure for a trie node.
                     Used in stclass optimization only */
                    U32 refcount;
                    reg_ac_data *aho=(reg_ac_data*)r->data->data[n];
                    OP_REFCNT_LOCK;
                    refcount = --aho->refcount;
                    OP_REFCNT_UNLOCK;
                    if ( !refcount ) {
                        Safefree(aho->states);
                        Safefree(aho->fail);
                        aho->trie=NULL; /* not necessary to free this as it is 
                                           handled by the 't' case */
                        Safefree(r->data->data[n]); /* do this last!!!! */
                        Safefree(r->regstclass);
                    }
                }
                break;
	    case 't':
	        {
	            /* trie structure. */
	            U32 refcount;
	            reg_trie_data *trie=(reg_trie_data*)r->data->data[n];
                    OP_REFCNT_LOCK;
                    refcount = --trie->refcount;
                    OP_REFCNT_UNLOCK;
                    if ( !refcount ) {
                        Safefree(trie->charmap);
                        if (trie->widecharmap)
                            SvREFCNT_dec((SV*)trie->widecharmap);
                        Safefree(trie->states);
                        Safefree(trie->trans);
                        if (trie->bitmap)
                            Safefree(trie->bitmap);
                        if (trie->wordlen)
                            Safefree(trie->wordlen);
                        if (trie->jump)
                            Safefree(trie->jump);
                        if (trie->nextword)
                            Safefree(trie->nextword);
#ifdef DEBUGGING
                        if (trie->words)
                            SvREFCNT_dec((SV*)trie->words);
                        if (trie->revcharmap)
                            SvREFCNT_dec((SV*)trie->revcharmap);
#endif
                        Safefree(r->data->data[n]); /* do this last!!!! */
		    }
		}
		break;
	    default:
		Perl_croak(aTHX_ "panic: regfree data code '%c'", r->data->what[n]);
	    }
	}
	Safefree(r->data->what);
	Safefree(r->data);
    }
    Safefree(r->startp);
    Safefree(r->endp);
    if (r->swap) {
        Safefree(r->swap->startp);
        Safefree(r->swap->endp);
        Safefree(r->swap);
    }
    Safefree(r);
}

#define sv_dup_inc(s,t)	SvREFCNT_inc(sv_dup(s,t))
#define av_dup_inc(s,t)	(AV*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define hv_dup_inc(s,t)	(HV*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)

/* 
   regdupe - duplicate a regexp. 
   
   This routine is called by sv.c's re_dup and is expected to clone a 
   given regexp structure. It is a no-op when not under USE_ITHREADS. 
   (Originally this *was* re_dup() for change history see sv.c)
   
   See pregfree() above if you change anything here. 
*/
#if defined(USE_ITHREADS)
regexp *
Perl_regdupe(pTHX_ const regexp *r, CLONE_PARAMS *param)
{
    dVAR;
    REGEXP *ret;
    int i, len, npar;
    struct reg_substr_datum *s;

    if (!r)
	return (REGEXP *)NULL;

    if ((ret = (REGEXP *)ptr_table_fetch(PL_ptr_table, r)))
	return ret;

    len = r->offsets[0];
    npar = r->nparens+1;

    Newxc(ret, sizeof(regexp) + (len+1)*sizeof(regnode), char, regexp);
    Copy(r->program, ret->program, len+1, regnode);

    Newx(ret->startp, npar, I32);
    Copy(r->startp, ret->startp, npar, I32);
    Newx(ret->endp, npar, I32);
    Copy(r->startp, ret->startp, npar, I32);
    if(r->swap) {
        Newx(ret->swap, 1, regexp_paren_ofs);
        /* no need to copy these */
        Newx(ret->swap->startp, npar, I32);
        Newx(ret->swap->endp, npar, I32);
    } else {
        ret->swap = NULL;
    }

    Newx(ret->substrs, 1, struct reg_substr_data);
    for (s = ret->substrs->data, i = 0; i < 3; i++, s++) {
	s->min_offset = r->substrs->data[i].min_offset;
	s->max_offset = r->substrs->data[i].max_offset;
	s->end_shift  = r->substrs->data[i].end_shift;
	s->substr     = sv_dup_inc(r->substrs->data[i].substr, param);
	s->utf8_substr = sv_dup_inc(r->substrs->data[i].utf8_substr, param);
    }

    ret->regstclass = NULL;
    if (r->data) {
	struct reg_data *d;
        const int count = r->data->count;
	int i;

	Newxc(d, sizeof(struct reg_data) + count*sizeof(void *),
		char, struct reg_data);
	Newx(d->what, count, U8);

	d->count = count;
	for (i = 0; i < count; i++) {
	    d->what[i] = r->data->what[i];
	    switch (d->what[i]) {
	        /* legal options are one of: sSfpont
	           see also regcomp.h and pregfree() */
	    case 's':
	    case 'S':
		d->data[i] = sv_dup_inc((SV *)r->data->data[i], param);
		break;
	    case 'p':
		d->data[i] = av_dup_inc((AV *)r->data->data[i], param);
		break;
	    case 'f':
		/* This is cheating. */
		Newx(d->data[i], 1, struct regnode_charclass_class);
		StructCopy(r->data->data[i], d->data[i],
			    struct regnode_charclass_class);
		ret->regstclass = (regnode*)d->data[i];
		break;
	    case 'o':
		/* Compiled op trees are readonly, and can thus be
		   shared without duplication. */
		OP_REFCNT_LOCK;
		d->data[i] = (void*)OpREFCNT_inc((OP*)r->data->data[i]);
		OP_REFCNT_UNLOCK;
		break;
	    case 'n':
		d->data[i] = r->data->data[i];
		break;
	    case 't':
		d->data[i] = r->data->data[i];
		OP_REFCNT_LOCK;
		((reg_trie_data*)d->data[i])->refcount++;
		OP_REFCNT_UNLOCK;
		break;
	    case 'T':
		d->data[i] = r->data->data[i];
		OP_REFCNT_LOCK;
		((reg_ac_data*)d->data[i])->refcount++;
		OP_REFCNT_UNLOCK;
		/* Trie stclasses are readonly and can thus be shared
		 * without duplication. We free the stclass in pregfree
		 * when the corresponding reg_ac_data struct is freed.
		 */
		ret->regstclass= r->regstclass;
		break;
            default:
		Perl_croak(aTHX_ "panic: re_dup unknown data code '%c'", r->data->what[i]);
	    }
	}

	ret->data = d;
    }
    else
	ret->data = NULL;

    Newx(ret->offsets, 2*len+1, U32);
    Copy(r->offsets, ret->offsets, 2*len+1, U32);

    ret->precomp        = SAVEPVN(r->precomp, r->prelen);
    ret->refcnt         = r->refcnt;
    ret->minlen         = r->minlen;
    ret->minlenret      = r->minlenret;
    ret->prelen         = r->prelen;
    ret->nparens        = r->nparens;
    ret->lastparen      = r->lastparen;
    ret->lastcloseparen = r->lastcloseparen;
    ret->reganch        = r->reganch;

    ret->sublen         = r->sublen;

    ret->engine         = r->engine;
    
    ret->paren_names    = hv_dup_inc(r->paren_names, param);

    if (RX_MATCH_COPIED(ret))
	ret->subbeg  = SAVEPVN(r->subbeg, r->sublen);
    else
	ret->subbeg = NULL;
#ifdef PERL_OLD_COPY_ON_WRITE
    ret->saved_copy = NULL;
#endif

    ptr_table_store(PL_ptr_table, r, ret);
    return ret;
}
#endif    

/* 
   reg_stringify() 
   
   converts a regexp embedded in a MAGIC struct to its stringified form, 
   caching the converted form in the struct and returns the cached 
   string. 

   If lp is nonnull then it is used to return the length of the 
   resulting string
   
   If flags is nonnull and the returned string contains UTF8 then 
   (flags & 1) will be true.
   
   If haseval is nonnull then it is used to return whether the pattern 
   contains evals.
   
   Normally called via macro: 
   
        CALLREG_STRINGIFY(mg,0,0);
        
   And internally with
   
        CALLREG_AS_STR(mg,lp,flags,haseval)        
    
   See sv_2pv_flags() in sv.c for an example of internal usage.
    
 */

char *
Perl_reg_stringify(pTHX_ MAGIC *mg, STRLEN *lp, U32 *flags, I32 *haseval ) {
    dVAR;
    const regexp * const re = (regexp *)mg->mg_obj;

    if (!mg->mg_ptr) {
	const char *fptr = "msix";
	char reflags[6];
	char ch;
	int left = 0;
	int right = 4;
	bool need_newline = 0;
	U16 reganch = (U16)((re->reganch & PMf_COMPILETIME) >> 12);

	while((ch = *fptr++)) {
	    if(reganch & 1) {
		reflags[left++] = ch;
	    }
	    else {
		reflags[right--] = ch;
	    }
	    reganch >>= 1;
	}
	if(left != 4) {
	    reflags[left] = '-';
	    left = 5;
	}

	mg->mg_len = re->prelen + 4 + left;
	/*
	 * If /x was used, we have to worry about a regex ending with a
	 * comment later being embedded within another regex. If so, we don't
	 * want this regex's "commentization" to leak out to the right part of
	 * the enclosing regex, we must cap it with a newline.
	 *
	 * So, if /x was used, we scan backwards from the end of the regex. If
	 * we find a '#' before we find a newline, we need to add a newline
	 * ourself. If we find a '\n' first (or if we don't find '#' or '\n'),
	 * we don't need to add anything.  -jfriedl
	 */
	if (PMf_EXTENDED & re->reganch) {
	    const char *endptr = re->precomp + re->prelen;
	    while (endptr >= re->precomp) {
		const char c = *(endptr--);
		if (c == '\n')
		    break; /* don't need another */
		if (c == '#') {
		    /* we end while in a comment, so we need a newline */
		    mg->mg_len++; /* save space for it */
		    need_newline = 1; /* note to add it */
		    break;
		}
	    }
	}

	Newx(mg->mg_ptr, mg->mg_len + 1 + left, char);
	mg->mg_ptr[0] = '(';
	mg->mg_ptr[1] = '?';
	Copy(reflags, mg->mg_ptr+2, left, char);
	*(mg->mg_ptr+left+2) = ':';
	Copy(re->precomp, mg->mg_ptr+3+left, re->prelen, char);
	if (need_newline)
	    mg->mg_ptr[mg->mg_len - 2] = '\n';
	mg->mg_ptr[mg->mg_len - 1] = ')';
	mg->mg_ptr[mg->mg_len] = 0;
    }
    if (haseval) 
        *haseval = re->program[0].next_off;
    if (flags)    
	*flags = ((re->reganch & ROPT_UTF8) ? 1 : 0);
    
    if (lp)
	*lp = mg->mg_len;
    return mg->mg_ptr;
}


#ifndef PERL_IN_XSUB_RE
/*
 - regnext - dig the "next" pointer out of a node
 */
regnode *
Perl_regnext(pTHX_ register regnode *p)
{
    dVAR;
    register I32 offset;

    if (p == &PL_regdummy)
	return(NULL);

    offset = (reg_off_by_arg[OP(p)] ? ARG(p) : NEXT_OFF(p));
    if (offset == 0)
	return(NULL);

    return(p+offset);
}
#endif

STATIC void	
S_re_croak2(pTHX_ const char* pat1,const char* pat2,...)
{
    va_list args;
    STRLEN l1 = strlen(pat1);
    STRLEN l2 = strlen(pat2);
    char buf[512];
    SV *msv;
    const char *message;

    if (l1 > 510)
	l1 = 510;
    if (l1 + l2 > 510)
	l2 = 510 - l1;
    Copy(pat1, buf, l1 , char);
    Copy(pat2, buf + l1, l2 , char);
    buf[l1 + l2] = '\n';
    buf[l1 + l2 + 1] = '\0';
#ifdef I_STDARG
    /* ANSI variant takes additional second argument */
    va_start(args, pat2);
#else
    va_start(args);
#endif
    msv = vmess(buf, &args);
    va_end(args);
    message = SvPV_const(msv,l1);
    if (l1 > 512)
	l1 = 512;
    Copy(message, buf, l1 , char);
    buf[l1-1] = '\0';			/* Overwrite \n */
    Perl_croak(aTHX_ "%s", buf);
}

/* XXX Here's a total kludge.  But we need to re-enter for swash routines. */

#ifndef PERL_IN_XSUB_RE
void
Perl_save_re_context(pTHX)
{
    dVAR;

    struct re_save_state *state;

    SAVEVPTR(PL_curcop);
    SSGROW(SAVESTACK_ALLOC_FOR_RE_SAVE_STATE + 1);

    state = (struct re_save_state *)(PL_savestack + PL_savestack_ix);
    PL_savestack_ix += SAVESTACK_ALLOC_FOR_RE_SAVE_STATE;
    SSPUSHINT(SAVEt_RE_STATE);

    Copy(&PL_reg_state, state, 1, struct re_save_state);

    PL_reg_start_tmp = 0;
    PL_reg_start_tmpl = 0;
    PL_reg_oldsaved = NULL;
    PL_reg_oldsavedlen = 0;
    PL_reg_maxiter = 0;
    PL_reg_leftiter = 0;
    PL_reg_poscache = NULL;
    PL_reg_poscache_size = 0;
#ifdef PERL_OLD_COPY_ON_WRITE
    PL_nrs = NULL;
#endif

    /* Save $1..$n (#18107: UTF-8 s/(\w+)/uc($1)/e); AMS 20021106. */
    if (PL_curpm) {
	const REGEXP * const rx = PM_GETRE(PL_curpm);
	if (rx) {
	    U32 i;
	    for (i = 1; i <= rx->nparens; i++) {
		char digits[TYPE_CHARS(long)];
		const STRLEN len = my_snprintf(digits, sizeof(digits), "%lu", (long)i);
		GV *const *const gvp
		    = (GV**)hv_fetch(PL_defstash, digits, len, 0);

		if (gvp) {
		    GV * const gv = *gvp;
		    if (SvTYPE(gv) == SVt_PVGV && GvSV(gv))
			save_scalar(gv);
		}
	    }
	}
    }
}
#endif

static void
clear_re(pTHX_ void *r)
{
    dVAR;
    ReREFCNT_dec((regexp *)r);
}

#ifdef DEBUGGING

STATIC void
S_put_byte(pTHX_ SV *sv, int c)
{
    if (isCNTRL(c) || c == 255 || !isPRINT(c))
	Perl_sv_catpvf(aTHX_ sv, "\\%o", c);
    else if (c == '-' || c == ']' || c == '\\' || c == '^')
	Perl_sv_catpvf(aTHX_ sv, "\\%c", c);
    else
	Perl_sv_catpvf(aTHX_ sv, "%c", c);
}


#define CLEAR_OPTSTART \
    if (optstart) STMT_START { \
	    DEBUG_OPTIMISE_r(PerlIO_printf(Perl_debug_log, " (%d nodes)\n", node - optstart)); \
	    optstart=NULL; \
    } STMT_END

#define DUMPUNTIL(b,e) CLEAR_OPTSTART; node=dumpuntil(r,start,(b),(e),last,sv,indent+1,depth+1);

STATIC const regnode *
S_dumpuntil(pTHX_ const regexp *r, const regnode *start, const regnode *node,
	    const regnode *last, const regnode *plast, 
	    SV* sv, I32 indent, U32 depth)
{
    dVAR;
    register U8 op = PSEUDO;	/* Arbitrary non-END op. */
    register const regnode *next;
    const regnode *optstart= NULL;
    GET_RE_DEBUG_FLAGS_DECL;

#ifdef DEBUG_DUMPUNTIL
    PerlIO_printf(Perl_debug_log, "--- %d : %d - %d - %d\n",indent,node-start,
        last ? last-start : 0,plast ? plast-start : 0);
#endif
            
    if (plast && plast < last) 
        last= plast;

    while (PL_regkind[op] != END && (!last || node < last)) {
	/* While that wasn't END last time... */

	NODE_ALIGN(node);
	op = OP(node);
	if (op == CLOSE)
	    indent--;
	next = regnext((regnode *)node);
	
	/* Where, what. */
	if (OP(node) == OPTIMIZED) {
	    if (!optstart && RE_DEBUG_FLAG(RE_DEBUG_COMPILE_OPTIMISE))
	        optstart = node;
	    else
		goto after_print;
	} else
	    CLEAR_OPTSTART;
	    
	regprop(r, sv, node);
	PerlIO_printf(Perl_debug_log, "%4"IVdf":%*s%s", (IV)(node - start),
		      (int)(2*indent + 1), "", SvPVX_const(sv));

	if (OP(node) != OPTIMIZED) {
	    if (next == NULL)		/* Next ptr. */
		PerlIO_printf(Perl_debug_log, "(0)");
	    else if (PL_regkind[(U8)op] == BRANCH && PL_regkind[OP(next)] != BRANCH )
	        PerlIO_printf(Perl_debug_log, "(FAIL)");
	    else
		PerlIO_printf(Perl_debug_log, "(%"IVdf")", (IV)(next - start));
		
	    /*if (PL_regkind[(U8)op]  != TRIE)*/
	        (void)PerlIO_putc(Perl_debug_log, '\n');
	}

      after_print:
	if (PL_regkind[(U8)op] == BRANCHJ) {
	    assert(next);
	    {
                register const regnode *nnode = (OP(next) == LONGJMP
					     ? regnext((regnode *)next)
					     : next);
                if (last && nnode > last)
                    nnode = last;
                DUMPUNTIL(NEXTOPER(NEXTOPER(node)), nnode);
	    }
	}
	else if (PL_regkind[(U8)op] == BRANCH) {
	    assert(next);
	    DUMPUNTIL(NEXTOPER(node), next);
	}
	else if ( PL_regkind[(U8)op]  == TRIE ) {
	    const regnode *this_trie = node;
	    const char op = OP(node);
            const I32 n = ARG(node);
	    const reg_ac_data * const ac = op>=AHOCORASICK ?
               (reg_ac_data *)r->data->data[n] :
               NULL;
	    const reg_trie_data * const trie = op<AHOCORASICK ?
	        (reg_trie_data*)r->data->data[n] :
	        ac->trie;
	    const regnode *nextbranch= NULL;
	    I32 word_idx;
            sv_setpvn(sv, "", 0);
	    for (word_idx= 0; word_idx < (I32)trie->wordcount; word_idx++) {
		SV ** const elem_ptr = av_fetch(trie->words,word_idx,0);
		
                PerlIO_printf(Perl_debug_log, "%*s%s ",
                   (int)(2*(indent+3)), "",
                    elem_ptr ? pv_pretty(sv, SvPV_nolen_const(*elem_ptr), SvCUR(*elem_ptr), 60,
	                    PL_colors[0], PL_colors[1],
	                    (SvUTF8(*elem_ptr) ? PERL_PV_ESCAPE_UNI : 0) |
	                    PERL_PV_PRETTY_ELIPSES    |
	                    PERL_PV_PRETTY_LTGT
                            )
                            : "???"
                );
                if (trie->jump) {
                    U16 dist= trie->jump[word_idx+1];
		    PerlIO_printf(Perl_debug_log, "(%u)\n",
                        (dist ? this_trie + dist : next) - start);
                    if (dist) {
                        if (!nextbranch)
                            nextbranch= this_trie + trie->jump[0];    
			DUMPUNTIL(this_trie + dist, nextbranch);
                    }
                    if (nextbranch && PL_regkind[OP(nextbranch)]==BRANCH)
                        nextbranch= regnext((regnode *)nextbranch);
                } else {
                    PerlIO_printf(Perl_debug_log, "\n");
		}
	    }
	    if (last && next > last)
	        node= last;
	    else
	        node= next;
	}
	else if ( op == CURLY ) {   /* "next" might be very big: optimizer */
	    DUMPUNTIL(NEXTOPER(node) + EXTRA_STEP_2ARGS,
                    NEXTOPER(node) + EXTRA_STEP_2ARGS + 1);
	}
	else if (PL_regkind[(U8)op] == CURLY && op != CURLYX) {
	    assert(next);
	    DUMPUNTIL(NEXTOPER(node) + EXTRA_STEP_2ARGS, next);
	}
	else if ( op == PLUS || op == STAR) {
	    DUMPUNTIL(NEXTOPER(node), NEXTOPER(node) + 1);
	}
	else if (op == ANYOF) {
	    /* arglen 1 + class block */
	    node += 1 + ((ANYOF_FLAGS(node) & ANYOF_LARGE)
		    ? ANYOF_CLASS_SKIP : ANYOF_SKIP);
	    node = NEXTOPER(node);
	}
	else if (PL_regkind[(U8)op] == EXACT) {
            /* Literal string, where present. */
	    node += NODE_SZ_STR(node) - 1;
	    node = NEXTOPER(node);
	}
	else {
	    node = NEXTOPER(node);
	    node += regarglen[(U8)op];
	}
	if (op == CURLYX || op == OPEN)
	    indent++;
	else if (op == WHILEM)
	    indent--;
    }
    CLEAR_OPTSTART;
#ifdef DEBUG_DUMPUNTIL    
    PerlIO_printf(Perl_debug_log, "--- %d\n",indent);
#endif
    return node;
}

#endif	/* DEBUGGING */

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
