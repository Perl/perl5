/*    regcomp.h
 */

typedef OP OP_4tree;			/* Will be redefined later. */

/*
 * The "internal use only" fields in regexp.h are present to pass info from
 * compile to execute that permits the execute phase to run lots faster on
 * simple cases.  They are:
 *
 * regstart	sv that must begin a match; Nullch if none obvious
 * reganch	is the match anchored (at beginning-of-line only)?
 * regmust	string (pointer into program) that match must include, or NULL
 *  [regmust changed to SV* for bminstr()--law]
 * regmlen	length of regmust string
 *  [regmlen not used currently]
 *
 * Regstart and reganch permit very fast decisions on suitable starting points
 * for a match, cutting down the work a lot.  Regmust permits fast rejection
 * of lines that cannot possibly match.  The regmust tests are costly enough
 * that pregcomp() supplies a regmust only if the r.e. contains something
 * potentially expensive (at present, the only such thing detected is * or +
 * at the start of the r.e., which can involve a lot of backup).  Regmlen is
 * supplied because the test in pregexec() needs it and pregcomp() is computing
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

/* #ifndef gould */
/* #ifndef cray */
/* #ifndef eta10 */
#define REGALIGN
/* #endif */
/* #endif */
/* #endif */

#ifdef REGALIGN
#  define REGALIGN_STRUCT
#endif 

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
#define	END	 0	/* no	End of program. */
#define	BOL	 1	/* no	Match "" at beginning of line. */
#define MBOL	 2	/* no	Same, assuming multiline. */
#define SBOL	 3	/* no	Same, assuming singleline. */
#define	EOL	 4	/* no	Match "" at end of line. */
#define MEOL	 5	/* no	Same, assuming multiline. */
#define SEOL	 6	/* no	Same, assuming singleline. */
#define	ANY	 7	/* no	Match any one character (except newline). */
#define	SANY	 8	/* no	Match any one character. */
#define	ANYOF	 9	/* sv	Match character in (or not in) this class. */
#define	CURLY	10	/* sv	Match this simple thing {n,m} times. */
#define	CURLYX	11	/* sv	Match this complex thing {n,m} times. */
#define	BRANCH	12	/* node	Match this alternative, or the next... */
#define	BACK	13	/* no	Match "", "next" ptr points backward. */
#define	EXACT	14	/* sv	Match this string (preceded by length). */
#define	EXACTF	15	/* sv	Match this string, folded (prec. by length). */
#define	EXACTFL	16	/* sv	Match this string, folded in locale (w/len). */
#define	NOTHING	17	/* no	Match empty string. */
#define	STAR	18	/* node	Match this (simple) thing 0 or more times. */
#define	PLUS	19	/* node	Match this (simple) thing 1 or more times. */
#define BOUND	20	/* no	Match "" at any word boundary */
#define BOUNDL	21	/* no	Match "" at any word boundary */
#define NBOUND	22	/* no	Match "" at any word non-boundary */
#define NBOUNDL	23	/* no	Match "" at any word non-boundary */
#define REF	24	/* num	Match some already matched string */
#define	OPEN	25	/* num	Mark this point in input as start of #n. */
#define	CLOSE	26	/* num	Analogous to OPEN. */
#define MINMOD	27	/* no	Next operator is not greedy. */
#define GPOS	28	/* no	Matches where last m//g left off. */
#define IFMATCH	29	/* off	Succeeds if the following matches. */
#define UNLESSM	30	/* off	Fails if the following matches. */
#define SUCCEED	31	/* no	Return from a subroutine, basically. */
#define WHILEM	32	/* no	Do curly processing and see if rest matches. */
#define ALNUM	33	/* no	Match any alphanumeric character */
#define ALNUML	34 	/* no	Match any alphanumeric char in locale */
#define NALNUM	35	/* no	Match any non-alphanumeric character */
#define NALNUML	36	/* no	Match any non-alphanumeric char in locale */
#define SPACE	37	/* no	Match any whitespace character */
#define SPACEL	38	/* no	Match any whitespace char in locale */
#define NSPACE	39	/* no	Match any non-whitespace character */
#define NSPACEL	40	/* no	Match any non-whitespace char in locale */
#define DIGIT	41	/* no	Match any numeric character */
#define NDIGIT	42	/* no	Match any non-numeric character */
#define CURLYM	43	/* no	Match this medium-complex thing {n,m} times. */
#define CURLYN	44	/* no	Match next-after-this simple thing
			   {n,m} times, set parenths. */
#define	TAIL	45	/* no	Match empty string. Can jump here from outside. */
#define REFF	46      /* num  Match already matched string, folded */
#define REFFL	47      /* num  Match already matched string, folded in loc. */
#define EVAL	48      /* evl  Execute some Perl code. */
#define LONGJMP	49      /* off  Jump far away, requires REGALIGN_STRUCT. */
#define BRANCHJ	50      /* off  BRANCH with long offset, requires REGALIGN_STRUCT. */
#define IFTHEN	51      /* off  Switch, should be preceeded by switcher . */
#define GROUPP	52      /* num  Whether the group matched. */
#define LOGICAL	53	/* no	Next opcode should set the flag only. */
#define SUSPEND	54	/* off	"Independent" sub-RE. */
#define RENUM	55	/* off	Group with independently numbered parens. */
#define OPTIMIZED	56	/* off	Placeholder for dump. */

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
 * OPEN,CLOSE,GROUPP	...are numbered at compile time.
 */

#ifndef DOINIT
EXTCONST U8 regkind[];
#else
EXTCONST U8 regkind[] = {
	END,
	BOL,
	BOL,
	BOL,
	EOL,
	EOL,
	EOL,
	ANY,
	ANY,
	ANYOF,
	CURLY,
	CURLY,
	BRANCH,
	BACK,
	EXACT,
	EXACT,
	EXACT,
	NOTHING,
	STAR,
	PLUS,
	BOUND,
	BOUND,
	NBOUND,
	NBOUND,
	REF,
	OPEN,
	CLOSE,
	MINMOD,
	GPOS,
	BRANCHJ,
	BRANCHJ,
	END,
	WHILEM,
	ALNUM,
	ALNUM,
	NALNUM,
	NALNUM,
	SPACE,
	SPACE,
	NSPACE,
	NSPACE,
	DIGIT,
	NDIGIT,
	CURLY,
	CURLY,
	NOTHING,
	REF,
	REF,
	EVAL,
	LONGJMP,
	BRANCHJ,
	BRANCHJ,
	GROUPP,
	LOGICAL,
	BRANCHJ,
	BRANCHJ,
	NOTHING,
};
#endif

/* The following have no fixed length. char* since we do strchr on it. */
#ifndef DOINIT
EXT const char varies[];
#else
EXT const char varies[] = {
    BRANCH, BACK, STAR, PLUS, CURLY, CURLYX, REF, REFF, REFFL, 
    WHILEM, CURLYM, CURLYN, BRANCHJ, IFTHEN, SUSPEND, 0
};
#endif

/* The following always have a length of 1. char* since we do strchr on it. */
#ifndef DOINIT
EXT const char simple[];
#else
EXT const char simple[] = {
    ANY, SANY, ANYOF,
    ALNUM, ALNUML, NALNUM, NALNUML,
    SPACE, SPACEL, NSPACE, NSPACEL,
    DIGIT, NDIGIT, 0
};
#endif

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
 * [If REGALIGN is defined, the "next" pointer is always aligned on an even
 * boundary, and reads the offset directly as a short.  Also, there is no
 * special test to reverse the sign of BACK pointers since the offset is
 * stored negative.]
 */

#ifdef REGALIGN_STRUCT

struct regnode_string {
    U8	flags;
    U8  type;
    U16 next_off;
    U8 string[1];
};

struct regnode_1 {
    U8	flags;
    U8  type;
    U16 next_off;
    U32 arg1;
};

struct regnode_2 {
    U8	flags;
    U8  type;
    U16 next_off;
    U16 arg1;
    U16 arg2;
};

#endif 

#define REG_INFTY I16_MAX

#ifdef REGALIGN
#  define ARG_VALUE(arg) (arg)
#  define ARG__SET(arg,val) ((arg) = (val))
#else
#  define ARG_VALUE(arg) (((*((char*)&arg)&0377)<<8) + (*(((char*)&arg)+1)&0377))
#  define ARG__SET(arg,val) (((char*)&arg)[0] = (val) >> 8; ((char*)&arg)[1] = (val) & 0377;)
#endif

#define ARG(p) ARG_VALUE(ARG_LOC(p))
#define ARG1(p) ARG_VALUE(ARG1_LOC(p))
#define ARG2(p) ARG_VALUE(ARG2_LOC(p))
#define ARG_SET(p, val) ARG__SET(ARG_LOC(p), (val))
#define ARG1_SET(p, val) ARG__SET(ARG1_LOC(p), (val))
#define ARG2_SET(p, val) ARG__SET(ARG2_LOC(p), (val))

#ifndef lint
#  ifdef REGALIGN
#    ifdef REGALIGN_STRUCT
#      define NEXT_OFF(p) ((p)->next_off)
#      define	NODE_ALIGN(node)
#      define	NODE_ALIGN_FILL(node) ((node)->flags = 0xde) /* deadbeef */
#    else
#      define NEXT_OFF(p) (*(short*)(p+1))
#      define	NODE_ALIGN(node)	((!((long)node & 1)) ? node++ : 0)
#      define	NODE_ALIGN_FILL(node)	((!((long)node & 1)) ? *node++ = 127 : 0)
#    endif 
#  else
#    define	NEXT_OFF(p)	(((*((p)+1)&0377)<<8) + (*((p)+2)&0377))
#    define	NODE_ALIGN(node)
#    define	NODE_ALIGN_FILL(node)
#  endif
#else /* lint */
#  define NEXT_OFF(p) 0
#  define	NODE_ALIGN(node)
#  define	NODE_ALIGN_FILL(node)
#endif /* lint */

#define SIZE_ALIGN NODE_ALIGN

#ifdef REGALIGN_STRUCT
#  define	OP(p)	((p)->type)
#  define	OPERAND(p)	(((struct regnode_string *)p)->string)
#  define	NODE_ALIGN(node)
#  define	ARG_LOC(p) (((struct regnode_1 *)p)->arg1)
#  define	ARG1_LOC(p) (((struct regnode_2 *)p)->arg1)
#  define	ARG2_LOC(p) (((struct regnode_2 *)p)->arg2)
#  define NODE_STEP_REGNODE	1	/* sizeof(regnode)/sizeof(regnode) */
#  define EXTRA_STEP_2ARGS	EXTRA_SIZE(struct regnode_2)
#else
#  define	OP(p)	(*(p))
#  define	OPERAND(p)	((p) + 3)
#  define	ARG_LOC(p) (*(unsigned short*)(p+3))
#  define	ARG1_LOC(p) (*(unsigned short*)(p+3))
#  define	ARG2_LOC(p) (*(unsigned short*)(p+5))
typedef char* regnode;
#  define NODE_STEP_REGNODE	NODE_STEP_B
#  define EXTRA_STEP_2ARGS	4
#endif 

#ifdef REGALIGN
#  define NODE_STEP_B	4
#else
#  define NODE_STEP_B	3
#endif

#define	NEXTOPER(p)	((p) + NODE_STEP_REGNODE)
#define	PREVOPER(p)	((p) - NODE_STEP_REGNODE)

#ifdef REGALIGN_STRUCT
#  define FILL_ADVANCE_NODE(ptr, op) STMT_START { \
    (ptr)->type = op;    (ptr)->next_off = 0;   (ptr)++; } STMT_END
#  define FILL_ADVANCE_NODE_ARG(ptr, op, arg) STMT_START { \
    ARG_SET(ptr, arg);  FILL_ADVANCE_NODE(ptr, op); (ptr) += 1; } STMT_END
#else
#  define FILL_ADVANCE_NODE(ptr, op) STMT_START { \
    *(ptr)++ = op;    *(ptr)++ = '\0';    *(ptr)++ = '\0'; } STMT_END
#  define FILL_ADVANCE_NODE_ARG(ptr, op, arg) STMT_START { \
    ARG_SET(ptr, arg);  FILL_ADVANCE_NODE(ptr, op); (ptr) += 2; } STMT_END
#endif

#define MAGIC 0234

#define SIZE_ONLY (regcode == &regdummy)

/* Flags for first parameter byte of ANYOF */
#define ANYOF_INVERT	0x40
#define ANYOF_FOLD	0x20
#define ANYOF_LOCALE	0x10
#define ANYOF_ISA	0x0F
#define ANYOF_ALNUML	 0x08
#define ANYOF_NALNUML	 0x04
#define ANYOF_SPACEL	 0x02
#define ANYOF_NSPACEL	 0x01

#ifdef REGALIGN_STRUCT
#define ANY_SKIP ((33 - 1)/sizeof(regnode) + 1)
#else
#define ANY_SKIP 32			/* overwrite the first byte of
					 * the next guy.  */
#endif 

/*
 * Utility definitions.
 */
#ifndef lint
#ifndef CHARMASK
#define	UCHARAT(p)	((int)*(unsigned char *)(p))
#else
#define	UCHARAT(p)	((int)*(p)&CHARMASK)
#endif
#else /* lint */
#define UCHARAT(p)	regdummy
#endif /* lint */

#define	FAIL(m)		croak    ("/%.127s/: %s",  regprecomp,m)
#define	FAIL2(pat,m)	re_croak2("/%.127s/: ",pat,regprecomp,m)

#define EXTRA_SIZE(guy) ((sizeof(guy)-1)/sizeof(struct regnode))

#ifdef REG_COMP_C
const static U8 regarglen[] = {
#  ifdef REGALIGN_STRUCT
    0,0,0,0,0,0,0,0,0,0,
    /*CURLY*/ EXTRA_SIZE(struct regnode_2), 
    /*CURLYX*/ EXTRA_SIZE(struct regnode_2),
    0,0,0,0,0,0,0,0,0,0,0,0,
    /*REF*/ EXTRA_SIZE(struct regnode_1), 
    /*OPEN*/ EXTRA_SIZE(struct regnode_1),
    /*CLOSE*/ EXTRA_SIZE(struct regnode_1),
    0,0,
    /*IFMATCH*/ EXTRA_SIZE(struct regnode_1),
    /*UNLESSM*/ EXTRA_SIZE(struct regnode_1),
    0,0,0,0,0,0,0,0,0,0,0,0,
    /*CURLYM*/ EXTRA_SIZE(struct regnode_2),
    /*CURLYN*/ EXTRA_SIZE(struct regnode_2),
    0,
    /*REFF*/ EXTRA_SIZE(struct regnode_1),
    /*REFFL*/ EXTRA_SIZE(struct regnode_1),
    /*EVAL*/ EXTRA_SIZE(struct regnode_1),
    /*LONGJMP*/ EXTRA_SIZE(struct regnode_1),
    /*BRANCHJ*/ EXTRA_SIZE(struct regnode_1),
    /*IFTHEN*/ EXTRA_SIZE(struct regnode_1),
    /*GROUPP*/ EXTRA_SIZE(struct regnode_1),
    /*LOGICAL*/ 0,
    /*SUSPEND*/ EXTRA_SIZE(struct regnode_1),
    /*RENUM*/ EXTRA_SIZE(struct regnode_1), 0,
#  else
    0,0,0,0,0,0,0,0,0,0,
    /*CURLY*/ 4, /*CURLYX*/ 4,
    0,0,0,0,0,0,0,0,0,0,0,0,
    /*REF*/ 2, /*OPEN*/ 2, /*CLOSE*/ 2,
    0,0, /*IFMATCH*/ 2, /*UNLESSM*/ 2,
    0,0,0,0,0,0,0,0,0,0,0,0,/*CURLYM*/ 4,/*CURLYN*/ 4,
    0, /*REFF*/ 2, /*REFFL*/ 2, /*EVAL*/ 2, /*LONGJMP*/ 2, /*BRANCHJ*/ 2,
    /*IFTHEN*/ 2, /*GROUPP*/ 2, /*LOGICAL*/ 0, /*RENUM*/ 2, /*RENUM*/ 2, 0,
#  endif 
};

const static char reg_off_by_arg[] = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* 0 .. 15 */
    0,0,0,0,0,0,0,0,0,0,0,0,0, /*IFMATCH*/ 2, /*UNLESSM*/ 2, 0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* 32 .. 47 */
    0, /*LONGJMP*/ 1, /*BRANCHJ*/ 1, /*IFTHEN*/ 1, 0, 0,
    /*RENUM*/ 1, /*RENUM*/ 1,0,
};
#endif

struct reg_data {
    U32 count;
    U8 *what;
    void* data[1];
};

#define REG_SEEN_ZERO_LEN	1
#define REG_SEEN_LOOKBEHIND	2
#define REG_SEEN_GPOS		4

#ifdef DEBUGGING
extern char *colors[4];
#endif 

void	re_croak2 _((const char* pat1,const char* pat2,...)) __attribute__((noreturn));
