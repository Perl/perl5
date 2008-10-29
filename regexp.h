/*    regexp.h
 *
 *    Copyright (C) 1993, 1994, 1996, 1997, 1999, 2000, 2001, 2003,
 *    2005, 2006, 2007, 2008 by Larry Wall and others
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
/* we don't want to include this stuff if we are inside of
   an external regex engine based on the core one - like re 'debug'*/

struct regnode {
    U8	flags;
    U8  type;
    U16 next_off;
};

typedef struct regnode regnode;

struct reg_substr_data;

struct reg_data;

struct reg_substr_datum {
    I32 min_offset;
    I32 max_offset;
    SV *substr;		/* non-utf8 variant */
    SV *utf8_substr;	/* utf8 variant */
};
struct reg_substr_data {
    struct reg_substr_datum data[3];	/* Actual array */
};
typedef struct regexp {
	I32 *startp;
	I32 *endp;
	regnode *regstclass;
        struct reg_substr_data *substrs;
	char *precomp;		/* pre-compilation regular expression */
        struct reg_data *data;	/* Additional data. */
	char *subbeg;		/* saved or original string 
				   so \digit works forever. */
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
	regnode program[1];	/* Unwarranted chumminess with compiler. */
} regexp;

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
/* used for high speed searches */
/* 0xf800 of reganch is used by PMf_COMPILETIME */

/* regexp_engine structure. This is the dispatch table for regexes.
 * Any regex engine implementation must be able to build one of these.
 */
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
#define REXEC_ML	0x20		/* $* was set. */

#define ReREFCNT_inc(re) ((void)(re && re->refcnt++), re)
#define ReREFCNT_dec(re) CALLREGFREE(aTHX_ re)

#define FBMcf_TAIL_DOLLAR	1
#define FBMcf_TAIL_DOLLARM	2
#define FBMcf_TAIL_Z		4
#define FBMcf_TAIL_z		8
#define FBMcf_TAIL		(FBMcf_TAIL_DOLLAR|FBMcf_TAIL_DOLLARM|FBMcf_TAIL_Z|FBMcf_TAIL_z)

#define FBMrf_MULTILINE	1

struct re_scream_pos_data_s;

struct re_save_state {
    U32 re_state_reg_flags;		/* from regexec.c */
    char *re_state_bostr;
    char *re_state_reginput;		/* String-input pointer. */
    char *re_state_regbol;		/* Beginning of input, for ^ check. */
    char *re_state_regeol;		/* End of input, for $ check. */
    I32 *re_state_regstartp;		/* Pointer to startp array. */
    I32 *re_state_regendp;		/* Ditto for endp. */
    U32 *re_state_reglastparen;		/* Similarly for lastparen. */
    U32 *re_state_reglastcloseparen;	/* Similarly for lastcloseparen. */
    char *re_state_regtill;		/* How far we are required to go. */
    char **re_state_reg_start_tmp;	/* from regexec.c */
    U32 re_state_reg_start_tmpl;	/* from regexec.c */
    I32 re_state_reg_eval_set;		/* from regexec.c */
    I32 re_state_regnarrate;		/* from regexec.c */
    int re_state_regindent;		/* from regexec.c */
    struct re_cc_state *re_state_reg_call_cc;		/* from regexec.c */
    regexp *re_state_reg_re;		/* from regexec.c */
    char *re_state_reg_ganch;		/* from regexec.c */
    SV *re_state_reg_sv;		/* from regexec.c */
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

    struct reg_data *re_state_regdata;	/* from regexec.c renamed was data */ 
    regnode *re_state_regprogram;	/* from regexec.c */
    struct curcur *re_state_regcc;	/* from regexec.c */
    char *re_state_regprecomp;		/* uncompiled string. */
    I32 re_state_regnpar;		/* () count. */
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
