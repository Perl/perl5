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

typedef struct regexp {
	I32 refcnt;
	char **startp;
	char **endp;
	regnode *regstclass;
	I32 minlen;		/* mininum possible length of $& */
	I32 prelen;		/* length of precomp */
	U32 nparens;		/* number of parentheses */
	U32 lastparen;		/* last paren matched */
	char *precomp;		/* pre-compilation regular expression */
	char *subbase;		/* saved string so \digit works forever */
	char *subbeg;		/* same, but not responsible for allocation */
	char *subend;		/* end of subbase */
	U16 naughty;		/* how exponential is this pattern? */
	U16 reganch;		/* Internal use only +
				   Tainted information used by regexec? */
        SV *anchored_substr;	/* Substring at fixed position wrt start. */
	I32 anchored_offset;	/* Position of it. */
        SV *float_substr;	/* Substring at variable position wrt start. */
	I32 float_min_offset;	/* Minimal position of it. */
	I32 float_max_offset;	/* Maximal position of it. */
        SV *check_substr;	/* Substring to check before matching. */
        I32 check_offset_min;	/* Offset of the above. */
        I32 check_offset_max;	/* Offset of the above. */
        struct reg_data *data;	/* Additional data. */
	regnode program[1];	/* Unwarranted chumminess with compiler. */
} regexp;

#define ROPT_ANCH		(ROPT_ANCH_BOL|ROPT_ANCH_MBOL|ROPT_ANCH_GPOS)
#define ROPT_ANCH_SINGLE	(ROPT_ANCH_BOL|ROPT_ANCH_GPOS)
#define ROPT_ANCH_BOL	 	1
#define ROPT_ANCH_MBOL	 	2
#define ROPT_ANCH_GPOS	 	4
#define ROPT_SKIP		8
#define ROPT_IMPLICIT		0x10	/* Converted .* to ^.* */
#define ROPT_NOSCAN		0x20	/* Check-string always at start. */
#define ROPT_GPOS_SEEN		0x40
#define ROPT_CHECK_ALL		0x80
#define ROPT_LOOKBEHIND_SEEN	0x100

#define ROPT_TAINTED_SEEN	0x8000

#define RX_MATCH_TAINTED(prog)	((prog)->reganch & ROPT_TAINTED_SEEN)
#define RX_MATCH_TAINTED_SET(prog, t) ((t) \
				       ? ((prog)->reganch |= ROPT_TAINTED_SEEN) \
				       : ((prog)->reganch &= ~ROPT_TAINTED_SEEN))

#define REXEC_COPY_STR	1		/* Need to copy the string. */
#define REXEC_CHECKED	2		/* check_substr already checked. */

#define ReREFCNT_inc(re) ((re && re->refcnt++), re)
#define ReREFCNT_dec(re) pregfree(re)
