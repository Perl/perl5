/* $RCSfile: arg.h,v $$Revision: 4.1 $$Date: 92/08/07 17:18:16 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	arg.h,v $
 */

/*
 * The fields of BASEOP are:
 *	op_next		Pointer to next ppcode to execute after this one.
 *			(Top level pre-grafted op points to first op,
 *			but this is replaced when op is grafted in, when
 *			this op will point to the real next op, and the new
 *			parent takes over role of remembering starting op.)
 *	op_ppaddr	Pointer to current ppcode's function.
 *	op_type		The type of the operation.
 *	op_flags	Flags common to all operations.  See OPf_* below.
 *	op_private	Flags peculiar to a particular operation (BUT,
 *			by default, set to the number of children until
 *			the operation is privatized by a check routine,
 *			which may or may not check number of children).
 */

typedef U16 PADOFFSET;

#ifdef DEBUGGING
#define OPCODE opcode
#else
#define OPCODE U16
#endif

#define BASEOP				\
    OP*		op_next;		\
    OP*		op_sibling;		\
    OP*		(*op_ppaddr)();		\
    PADOFFSET	op_targ;		\
    OPCODE	op_type;		\
    U16		op_seq;			\
    char	op_flags;		\
    char	op_private;

#define GIMME (op->op_flags & OPf_KNOW ? op->op_flags & OPf_LIST : getgimme(op))

/* Public flags */
#define OPf_LIST	1	/* Do operator in list context. */
#define OPf_KNOW	2	/* Context is known. */
#define OPf_KIDS	4	/* There is a firstborn child. */
#define OPf_PARENS	8	/* This operator was parenthesized. */
				/*  (Or block needs explicit scope entry.) */
#define OPf_STACKED	16	/* Some arg is arriving on the stack. */
#define OPf_LVAL	32	/* Certified reference (lvalue). */
#define OPf_INTRO	64	/* Lvalue must be localized */
#define OPf_SPECIAL	128	/* Do something weird for this op: */
				/*  On local LVAL, don't init local value. */
				/*  On OP_SORT, subroutine is inlined. */
				/*  On OP_NOT, inversion was implicit. */
				/*  On file tests, we fstat filehandle */
				/*  On truncate, we truncate filehandle */
				/*  On control verbs, we saw no label */
				/*  On flipflop, we saw ... instead of .. */
				/*  On UNOPs, saw bare parens, e.g. eof(). */
				/*  On OP_ENTERSUBR || OP_NULL, saw a "do". */

/* Private for OP_ASSIGN */
#define OPpASSIGN_COMMON	1	/* Left & right have syms in common. */

/* Private for OP_TRANS */
#define OPpTRANS_SQUASH		1
#define OPpTRANS_DELETE		2
#define OPpTRANS_COMPLEMENT	4

/* Private for OP_REPEAT */
#define OPpREPEAT_DOLIST	1	/* List replication. */

/* Private for OP_SUBR */
#define OPpSUBR_DB		1	/* Debug subroutine. */

/* Private for OP_CONST */
#define OPpCONST_BARE		1	/* Was a bare word (filehandle?). */

/* Private for OP_FLIP/FLOP */
#define OPpFLIP_LINENUM		1	/* Range arg potentially a line num. */

/* Private for OP_LIST */
#define OPpLIST_GUESSED		1	/* Guessed that pushmark was needed. */

struct op {
    BASEOP
};

struct unop {
    BASEOP
    OP *	op_first;
};

struct binop {
    BASEOP
    OP *	op_first;
    OP *	op_last;
};

struct logop {
    BASEOP
    OP *	op_first;
    OP *	op_other;
};

struct condop {
    BASEOP
    OP *	op_first;
    OP *	op_true;
    OP *	op_false;
};

struct listop {
    BASEOP
    OP *	op_first;
    OP *	op_last;
    U32		op_children;
};

struct pmop {
    BASEOP
    OP *	op_first;
    OP *	op_last;
    U32		op_children;
    OP *	op_pmreplroot;
    OP *	op_pmreplstart;
    PMOP *	op_pmnext;		/* list of all scanpats */
    REGEXP *	op_pmregexp;		/* compiled expression */
    SV *	op_pmshort;		/* for a fast bypass of execute() */
    short	op_pmflags;
    char	op_pmslen;
};
#define PMf_USED 1			/* pm has been used once already */
#define PMf_ONCE 2			/* use pattern only once per reset */
#define PMf_SCANFIRST 4			/* initial constant not anchored */
#define PMf_ALL 8			/* initial constant is whole pat */
#define PMf_SKIPWHITE 16		/* skip leading whitespace for split */
#define PMf_FOLD 32			/* case insensitivity */
#define PMf_CONST 64			/* subst replacement is constant */
#define PMf_KEEP 128			/* keep 1st runtime pattern forever */
#define PMf_GLOBAL 256			/* pattern had a g modifier */
#define PMf_RUNTIME 512			/* pattern coming in on the stack */
#define PMf_EVAL 1024			/* evaluating replacement as expr */

struct svop {
    BASEOP
    SV *	op_sv;
};

struct gvop {
    BASEOP
    GV *	op_gv;
};

struct pvop {
    BASEOP
    char *	op_pv;
};

struct cvop {
    BASEOP
    CV *	op_cv;
    OP *	op_cont;
};

struct loop {
    BASEOP
    OP *	op_first;
    OP *	op_last;
    U32		op_children;
    OP *	op_redoop;
    OP *	op_nextop;
    OP *	op_lastop;
};

#define cUNOP ((UNOP*)op)
#define cBINOP ((BINOP*)op)
#define cLISTOP ((LISTOP*)op)
#define cLOGOP ((LOGOP*)op)
#define cCONDOP ((CONDOP*)op)
#define cPMOP ((PMOP*)op)
#define cSVOP ((SVOP*)op)
#define cGVOP ((GVOP*)op)
#define cPVOP ((PVOP*)op)
#define cCVOP ((CVOP*)op)
#define cCOP ((COP*)op)
#define cLOOP ((LOOP*)op)

#define kUNOP ((UNOP*)kid)
#define kBINOP ((BINOP*)kid)
#define kLISTOP ((LISTOP*)kid)
#define kLOGOP ((LOGOP*)kid)
#define kCONDOP ((CONDOP*)kid)
#define kPMOP ((PMOP*)kid)
#define kSVOP ((SVOP*)kid)
#define kGVOP ((GVOP*)kid)
#define kPVOP ((PVOP*)kid)
#define kCVOP ((CVOP*)kid)
#define kCOP ((COP*)kid)
#define kLOOP ((LOOP*)kid)

#define Nullop Null(OP*)

