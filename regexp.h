/*    regexp.h
 */

/*
 * Definitions etc. for regexp(3) routines.
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 */


struct regnode {
    U8	flags;
    U8  type;
    U16 next_off;
};

typedef struct regnode regnode;

struct reg_data {
    U32 count;
    U8 *what;
    void* data[1];
};

struct reg_substr_datum {
    I32 min_offset;
    I32 max_offset;
    SV *substr;
};

struct reg_substr_data {
    struct reg_substr_datum data[3];	/* Actual array */
};

typedef struct regexp {
	I32 *startp;
	I32 *endp;
	regnode *regstclass;
#if 0
        SV *anchored_substr;	/* Substring at fixed position wrt start. */
	I32 anchored_offset;	/* Position of it. */
        SV *float_substr;	/* Substring at variable position wrt start. */
	I32 float_min_offset;	/* Minimal position of it. */
	I32 float_max_offset;	/* Maximal position of it. */
        SV *check_substr;	/* Substring to check before matching. */
        I32 check_offset_min;	/* Offset of the above. */
        I32 check_offset_max;	/* Offset of the above. */
#else
        struct reg_substr_data *substrs;
#endif
	char *precomp;		/* pre-compilation regular expression */
        struct reg_data *data;	/* Additional data. */
	char *subbeg;		/* saved or original string 
				   so \digit works forever. */
	I32 sublen;		/* Length of string pointed by subbeg */
	I32 refcnt;
	I32 minlen;		/* mininum possible length of $& */
	I32 prelen;		/* length of precomp */
	U32 nparens;		/* number of parentheses */
	U32 lastparen;		/* last paren matched */
	U32 reganch;		/* Internal use only +
				   Tainted information used by regexec? */
	regnode program[1];	/* Unwarranted chumminess with compiler. */
} regexp;

#define anchored_substr substrs->data[0].substr
#define anchored_offset substrs->data[0].min_offset
#define float_substr substrs->data[1].substr
#define float_min_offset substrs->data[1].min_offset
#define float_max_offset substrs->data[1].max_offset
#define check_substr substrs->data[2].substr
#define check_offset_min substrs->data[2].min_offset
#define check_offset_max substrs->data[2].max_offset

#define ROPT_ANCH		(ROPT_ANCH_BOL|ROPT_ANCH_MBOL|ROPT_ANCH_GPOS)
#define ROPT_ANCH_SINGLE	(ROPT_ANCH_BOL|ROPT_ANCH_GPOS)
#define ROPT_ANCH_BOL	 	0x00001
#define ROPT_ANCH_MBOL	 	0x00002
#define ROPT_ANCH_GPOS	 	0x00004
#define ROPT_SKIP		0x00008
#define ROPT_IMPLICIT		0x00010	/* Converted .* to ^.* */
#define ROPT_NOSCAN		0x00020	/* Check-string always at start. */
#define ROPT_GPOS_SEEN		0x00040
#define ROPT_CHECK_ALL		0x00080
#define ROPT_LOOKBEHIND_SEEN	0x00100
#define ROPT_EVAL_SEEN		0x00200
#define ROPT_TAINTED_SEEN	0x00400
#define ROPT_ANCH_SBOL	 	0x00800

/* 0xf800 of reganch is used by PMf_COMPILETIME */

#define ROPT_UTF8		0x10000
#define ROPT_NAUGHTY		0x20000 /* how exponential is this pattern? */
#define ROPT_COPY_DONE		0x40000	/* subbeg is a copy of the string */

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

#define REXEC_COPY_STR	1		/* Need to copy the string. */
#define REXEC_CHECKED	2		/* check_substr already checked. */
#define REXEC_SCREAM	4		/* use scream table. */
#define REXEC_IGNOREPOS	8		/* \G matches at start. */
#define REXEC_NOT_FIRST	0x10		/* This is another iteration of //g. */

#define ReREFCNT_inc(re) ((re && re->refcnt++), re)
#define ReREFCNT_dec(re) pregfree(re)

#define FBMcf_TAIL_DOLLAR	1
#define FBMcf_TAIL_Z		2
#define FBMcf_TAIL_z		4
#define FBMcf_TAIL		(FBMcf_TAIL_DOLLAR|FBMcf_TAIL_Z|FBMcf_TAIL_z)

#define FBMrf_MULTILINE	1
