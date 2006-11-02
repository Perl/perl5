/*    regexp.h
 *
 *    Copyright (C) 1993, 1994, 1996, 1997, 1999, 2000, 2001, 2003,
 *    by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * Definitions etc. for regexp(3) routines.
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 */
#ifndef PLUGGABLE_RE_EXTENSION
/* we don't want to include this stuff if we are inside Nicholas'
 * pluggable regex engine code */

struct regnode {
    U8	flags;
    U8  type;
    U16 next_off;
};

typedef struct regnode regnode;

struct reg_substr_data;

struct reg_data;

struct regexp_engine;

typedef struct regexp {
	I32 *startp;
	I32 *endp;
	regnode *regstclass;
        struct reg_substr_data *substrs;
	char *precomp;		/* pre-compilation regular expression */
        struct reg_data *data;	/* Additional data. */
	char *subbeg;		/* saved or original string 
				   so \digit works forever. */
#ifdef PERL_OLD_COPY_ON_WRITE
        SV *saved_copy;         /* If non-NULL, SV which is COW from original */
#endif
        U32 *offsets;           /* offset annotations 20001228 MJD */
	I32 sublen;		/* Length of string pointed by subbeg */
	I32 refcnt;
	I32 minlen;		/* mininum possible length of $& */
	I32 prelen;		/* length of precomp */
	U32 nparens;		/* number of parentheses */
	U32 lastparen;		/* last paren matched */
	U32 lastcloseparen;	/* last paren matched */
	U32 reganch;		/* Internal use only +
				   Tainted information used by regexec? */
	HV *paren_names;	/* Paren names */
	const struct regexp_engine* engine;
	regnode program[1];	/* Unwarranted chumminess with compiler. */
} regexp;


typedef struct re_scream_pos_data_s
{
    char **scream_olds;		/* match pos */
    I32 *scream_pos;		/* Internal iterator of scream. */
} re_scream_pos_data;

typedef struct regexp_engine {
    regexp* (*comp) (pTHX_ char* exp, char* xend, PMOP* pm);
    I32	    (*exec) (pTHX_ regexp* prog, char* stringarg, char* strend,
			    char* strbeg, I32 minend, SV* screamer,
			    void* data, U32 flags);
    char*   (*intuit) (pTHX_ regexp *prog, SV *sv, char *strpos,
			    char *strend, U32 flags,
			    struct re_scream_pos_data_s *data);
    SV*	    (*checkstr) (pTHX_ regexp *prog);
    void    (*free) (pTHX_ struct regexp* r);
#ifdef USE_ITHREADS
    regexp* (*dupe) (pTHX_ const regexp *r, CLONE_PARAMS *param);
#endif    
} regexp_engine;

#define ROPT_ANCH		(ROPT_ANCH_BOL|ROPT_ANCH_MBOL|ROPT_ANCH_GPOS|ROPT_ANCH_SBOL)
#define ROPT_ANCH_SINGLE	(ROPT_ANCH_SBOL|ROPT_ANCH_GPOS)
#define ROPT_ANCH_BOL	 	0x00000001
#define ROPT_ANCH_MBOL	 	0x00000002
#define ROPT_ANCH_SBOL	 	0x00000004
#define ROPT_ANCH_GPOS	 	0x00000008
#define ROPT_SKIP		0x00000010
#define ROPT_IMPLICIT		0x00000020	/* Converted .* to ^.* */
#define ROPT_NOSCAN		0x00000040	/* Check-string always at start. */
#define ROPT_GPOS_SEEN		0x00000080
#define ROPT_CHECK_ALL		0x00000100
#define ROPT_LOOKBEHIND_SEEN	0x00000200
#define ROPT_EVAL_SEEN		0x00000400
#define ROPT_CANY_SEEN		0x00000800
#define ROPT_SANY_SEEN		ROPT_CANY_SEEN /* src bckwrd cmpt */
#define ROPT_GPOS_CHECK         (ROPT_GPOS_SEEN|ROPT_ANCH_GPOS)
#define ROPT_RECURSE_SEEN       0x00001000

/* 0xf800 of reganch is used by PMf_COMPILETIME */

#define ROPT_UTF8		0x00010000
#define ROPT_NAUGHTY		0x00020000 /* how exponential is this pattern? */
#define ROPT_COPY_DONE		0x00040000	/* subbeg is a copy of the string */
#define ROPT_TAINTED_SEEN	0x00080000
#define ROPT_MATCH_UTF8		0x10000000 /* subbeg is utf-8 */

#define RE_USE_INTUIT_NOML	0x00100000 /* Best to intuit before matching */
#define RE_USE_INTUIT_ML	0x00200000
#define REINT_AUTORITATIVE_NOML	0x00400000 /* Can trust a positive answer */
#define REINT_AUTORITATIVE_ML	0x00800000
#define REINT_ONCE_NOML		0x01000000 /* Intuit can succed once only. */
#define REINT_ONCE_ML		0x02000000
#define RE_INTUIT_ONECHAR	0x04000000
#define RE_INTUIT_TAIL		0x08000000


#define RE_USE_INTUIT		(RE_USE_INTUIT_NOML|RE_USE_INTUIT_ML)
#define REINT_AUTORITATIVE	(REINT_AUTORITATIVE_NOML|REINT_AUTORITATIVE_ML)
#define REINT_ONCE		(REINT_ONCE_NOML|REINT_ONCE_ML)

#define RX_MATCH_TAINTED(prog)	((prog)->reganch & ROPT_TAINTED_SEEN)
#define RX_MATCH_TAINTED_on(prog) ((prog)->reganch |= ROPT_TAINTED_SEEN)
#define RX_MATCH_TAINTED_off(prog) ((prog)->reganch &= ~ROPT_TAINTED_SEEN)
#define RX_MATCH_TAINTED_set(prog, t) ((t) \
				       ? RX_MATCH_TAINTED_on(prog) \
				       : RX_MATCH_TAINTED_off(prog))

#define RX_MATCH_COPIED(prog)		((prog)->reganch & ROPT_COPY_DONE)
#define RX_MATCH_COPIED_on(prog)	((prog)->reganch |= ROPT_COPY_DONE)
#define RX_MATCH_COPIED_off(prog)	((prog)->reganch &= ~ROPT_COPY_DONE)
#define RX_MATCH_COPIED_set(prog,t)	((t) \
					 ? RX_MATCH_COPIED_on(prog) \
					 : RX_MATCH_COPIED_off(prog))

#endif /* PLUGGABLE_RE_EXTENSION */

/* Stuff that needs to be included in the plugable extension goes below here */

#define RE_DEBUG_BIT            0x20000000
#define RX_DEBUG(prog)	((prog)->reganch & RE_DEBUG_BIT)
#define RX_DEBUG_on(prog) ((prog)->reganch |= RE_DEBUG_BIT)

#ifdef PERL_OLD_COPY_ON_WRITE
#define RX_MATCH_COPY_FREE(rx) \
	STMT_START {if (rx->saved_copy) { \
	    SV_CHECK_THINKFIRST_COW_DROP(rx->saved_copy); \
	} \
	if (RX_MATCH_COPIED(rx)) { \
	    Safefree(rx->subbeg); \
	    RX_MATCH_COPIED_off(rx); \
	}} STMT_END
#else
#define RX_MATCH_COPY_FREE(rx) \
	STMT_START {if (RX_MATCH_COPIED(rx)) { \
	    Safefree(rx->subbeg); \
	    RX_MATCH_COPIED_off(rx); \
	}} STMT_END
#endif

#define RX_MATCH_UTF8(prog)		((prog)->reganch & ROPT_MATCH_UTF8)
#define RX_MATCH_UTF8_on(prog)		((prog)->reganch |= ROPT_MATCH_UTF8)
#define RX_MATCH_UTF8_off(prog)		((prog)->reganch &= ~ROPT_MATCH_UTF8)
#define RX_MATCH_UTF8_set(prog, t)	((t) \
			? (RX_MATCH_UTF8_on(prog), (PL_reg_match_utf8 = 1)) \
			: (RX_MATCH_UTF8_off(prog), (PL_reg_match_utf8 = 0)))
    
#define REXEC_COPY_STR	0x01		/* Need to copy the string. */
#define REXEC_CHECKED	0x02		/* check_substr already checked. */
#define REXEC_SCREAM	0x04		/* use scream table. */
#define REXEC_IGNOREPOS	0x08		/* \G matches at start. */
#define REXEC_NOT_FIRST	0x10		/* This is another iteration of //g. */

#define ReREFCNT_inc(re) ((void)(re && re->refcnt++), re)
#define ReREFCNT_dec(re) CALLREGFREE(re)

#define FBMcf_TAIL_DOLLAR	1
#define FBMcf_TAIL_DOLLARM	2
#define FBMcf_TAIL_Z		4
#define FBMcf_TAIL_z		8
#define FBMcf_TAIL		(FBMcf_TAIL_DOLLAR|FBMcf_TAIL_DOLLARM|FBMcf_TAIL_Z|FBMcf_TAIL_z)

#define FBMrf_MULTILINE	1

struct re_scream_pos_data_s;

/* an accepting state/position*/
struct _reg_trie_accepted {
    U8   *endpos;
    U16  wordnum;
};
typedef struct _reg_trie_accepted reg_trie_accepted;

/* some basic information about the current match that is created by
 * Perl_regexec_flags and then passed to regtry(), regmatch() etc */

typedef struct {
    regexp *prog;
    char *bol;
    char *till;
    SV *sv;
    char *ganch;
    char *cutpoint;
} regmatch_info;
 

/* structures for holding and saving the state maintained by regmatch() */

#define MAX_RECURSE_EVAL_NOCHANGE_DEPTH 50

typedef I32 CHECKPOINT;

typedef struct regmatch_state {
    int resume_state;		/* where to jump to on return */
    char *locinput;		/* where to backtrack in string on failure */

    union {

	/* this is a fake union member that matches the first element
	 * of each member that needs to store positive backtrack
	 * information */
	struct {
	    struct regmatch_state *prev_yes_state;
	} yes;

	struct {
	    reg_trie_accepted *accept_buff;
	    U32		accepted; /* how many accepting states we have seen */
	    U16         *jump;  /* positive offsets from me */
	    regnode	*B;	/* node following the trie */
	    regnode	*me;	/* Which node am I - needed for jump tries*/
	} trie;

	struct {
	    /* this first element must match u.yes */
	    struct regmatch_state *prev_yes_state;
	    struct regmatch_state *prev_eval;
	    struct regmatch_state *prev_curlyx;
	    regexp	*prev_rex;
	    U32		toggle_reg_flags; /* what bits in PL_reg_flags to
					    flip when transitioning between
					    inner and outer rexen */
	    CHECKPOINT	cp;	/* remember current savestack indexes */
	    CHECKPOINT	lastcp;
	    regnode	*B;	/* the node following us  */
	    U32        close_paren; /* which close bracket is our end */
	} eval;

	struct {
	    /* this first element must match u.yes */
	    struct regmatch_state *prev_yes_state;
	    struct regmatch_state *prev_curlyx; /* previous cur_curlyx */
	    CHECKPOINT	cp;	/* remember current savestack index */
	    bool	minmod;
	    int		parenfloor;/* how far back to strip paren data */
	    int		min;	/* the minimal number of A's to match */
	    int		max;	/* the maximal number of A's to match */
	    regnode	*A, *B;	/* the nodes corresponding to /A*B/  */

	    /* these two are modified by WHILEM */
	    int		count;	/* how many instances of A we've matched */
	    char	*lastloc;/* where previous A matched (0-len detect) */
	} curlyx;

	struct {
	    /* this first element must match u.yes */
	    struct regmatch_state *prev_yes_state;
	    struct regmatch_state *save_curlyx;
	    CHECKPOINT	cp;	/* remember current savestack indexes */
	    CHECKPOINT	lastcp;
	    char	*save_lastloc;	/* previous curlyx.lastloc */
	    I32		cache_offset;
	    I32		cache_mask;
	} whilem;

	struct {
	    I32 lastparen;
	    regnode *next_branch; /* next branch node */
	    CHECKPOINT cp;
	} branch;

	struct {
	    /* this first element must match u.yes */
	    struct regmatch_state *prev_yes_state;
	    I32 c1, c2;		/* case fold search */
	    CHECKPOINT cp;
	    I32 alen;		/* length of first-matched A string */
	    I32 count;
	    bool minmod;
	    regnode *A, *B;	/* the nodes corresponding to /A*B/  */
	    regnode *me;	/* the curlym node */
	} curlym;

	struct {
	    I32 paren;
	    CHECKPOINT cp;
	    I32 c1, c2;		/* case fold search */
	    char *maxpos;	/* highest possible point in string to match */
	    char *oldloc;	/* the previous locinput */
	    int count;
	    int min, max;	/* {m,n} */
	    regnode *A, *B;	/* the nodes corresponding to /A*B/  */
	} curly; /* and CURLYN/PLUS/STAR */

	struct {
	    /* this first element must match u.yes */
	    struct regmatch_state *prev_yes_state;
	    I32 wanted;
	    I32 logical;	/* saved copy of 'logical' var */
	    regnode  *me; /* the IFMATCH/SUSPEND/UNLESSM node  */
	} ifmatch; /* and SUSPEND/UNLESSM */
    } u;
} regmatch_state;

/* how many regmatch_state structs to allocate as a single slab.
 * We do it in 4K blocks for efficiency. The "3" is 2 for the next/prev
 * pointers, plus 1 for any mythical malloc overhead. */
 
#define PERL_REGMATCH_SLAB_SLOTS \
    ((4096 - 3 * sizeof (void*)) / sizeof(regmatch_state))

typedef struct regmatch_slab {
    regmatch_state states[PERL_REGMATCH_SLAB_SLOTS];
    struct regmatch_slab *prev, *next;
} regmatch_slab;

#define PL_reg_flags		PL_reg_state.re_state_reg_flags
#define PL_bostr		PL_reg_state.re_state_bostr
#define PL_reginput		PL_reg_state.re_state_reginput
#define PL_regeol		PL_reg_state.re_state_regeol
#define PL_regstartp		PL_reg_state.re_state_regstartp
#define PL_regendp		PL_reg_state.re_state_regendp
#define PL_reglastparen		PL_reg_state.re_state_reglastparen
#define PL_reglastcloseparen	PL_reg_state.re_state_reglastcloseparen
#define PL_reg_start_tmp	PL_reg_state.re_state_reg_start_tmp
#define PL_reg_start_tmpl	PL_reg_state.re_state_reg_start_tmpl
#define PL_reg_eval_set		PL_reg_state.re_state_reg_eval_set
#define PL_reg_match_utf8	PL_reg_state.re_state_reg_match_utf8
#define PL_reg_magic		PL_reg_state.re_state_reg_magic
#define PL_reg_oldpos		PL_reg_state.re_state_reg_oldpos
#define PL_reg_oldcurpm		PL_reg_state.re_state_reg_oldcurpm
#define PL_reg_curpm		PL_reg_state.re_state_reg_curpm
#define PL_reg_oldsaved		PL_reg_state.re_state_reg_oldsaved
#define PL_reg_oldsavedlen	PL_reg_state.re_state_reg_oldsavedlen
#define PL_reg_maxiter		PL_reg_state.re_state_reg_maxiter
#define PL_reg_leftiter		PL_reg_state.re_state_reg_leftiter
#define PL_reg_poscache		PL_reg_state.re_state_reg_poscache
#define PL_reg_poscache_size	PL_reg_state.re_state_reg_poscache_size
#define PL_regsize		PL_reg_state.re_state_regsize
#define PL_reg_starttry		PL_reg_state.re_state_reg_starttry
#define PL_nrs			PL_reg_state.re_state_nrs

struct re_save_state {
    U32 re_state_reg_flags;		/* from regexec.c */
    char *re_state_bostr;
    char *re_state_reginput;		/* String-input pointer. */
    char *re_state_regeol;		/* End of input, for $ check. */
    I32 *re_state_regstartp;		/* Pointer to startp array. */
    I32 *re_state_regendp;		/* Ditto for endp. */
    U32 *re_state_reglastparen;		/* Similarly for lastparen. */
    U32 *re_state_reglastcloseparen;	/* Similarly for lastcloseparen. */
    char **re_state_reg_start_tmp;	/* from regexec.c */
    U32 re_state_reg_start_tmpl;	/* from regexec.c */
    I32 re_state_reg_eval_set;		/* from regexec.c */
    bool re_state_reg_match_utf8;	/* from regexec.c */
    MAGIC *re_state_reg_magic;		/* from regexec.c */
    I32 re_state_reg_oldpos;		/* from regexec.c */
    PMOP *re_state_reg_oldcurpm;	/* from regexec.c */
    PMOP *re_state_reg_curpm;		/* from regexec.c */
    char *re_state_reg_oldsaved;	/* old saved substr during match */
    STRLEN re_state_reg_oldsavedlen;	/* old length of saved substr during match */
    I32 re_state_reg_maxiter;		/* max wait until caching pos */
    I32 re_state_reg_leftiter;		/* wait until caching pos */
    char *re_state_reg_poscache;	/* cache of pos of WHILEM */
    STRLEN re_state_reg_poscache_size;	/* size of pos cache of WHILEM */
    I32 re_state_regsize;		/* from regexec.c */
    char *re_state_reg_starttry;	/* from regexec.c */
#ifdef PERL_OLD_COPY_ON_WRITE
    SV *re_state_nrs;			/* was placeholder: unused since 5.8.0 (5.7.2 patch #12027 for bug ID 20010815.012). Used to save rx->saved_copy */
#endif
};

#define SAVESTACK_ALLOC_FOR_RE_SAVE_STATE \
	(1 + ((sizeof(struct re_save_state) - 1) / sizeof(*PL_savestack)))
/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
