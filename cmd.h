/* $Header: cmd.h,v 3.0.1.1 89/10/26 23:05:43 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	cmd.h,v $
 * Revision 3.0.1.1  89/10/26  23:05:43  lwall
 * patch1: unless was broken when run under the debugger
 * 
 * Revision 3.0  89/10/18  15:09:15  lwall
 * 3.0 baseline
 * 
 */

#define C_NULL 0
#define C_IF 1
#define C_ELSE 2
#define C_WHILE 3
#define C_BLOCK 4
#define C_EXPR 5
#define C_NEXT 6
#define C_ELSIF 7	/* temporary--turns into an IF + ELSE */
#define C_CSWITCH 8	/* created by switch optimization in block_head() */
#define C_NSWITCH 9	/* likewise */

#ifdef DEBUGGING
#ifndef DOINIT
extern char *cmdname[];
#else
char *cmdname[] = {
    "NULL",
    "IF",
    "ELSE",
    "WHILE",
    "BLOCK",
    "EXPR",
    "NEXT",
    "ELSIF",
    "CSWITCH",
    "NSWITCH",
    "10"
};
#endif
#endif /* DEBUGGING */

#define CF_OPTIMIZE 077	/* type of optimization */
#define CF_FIRSTNEG 0100/* conditional is ($register NE 'string') */
#define CF_NESURE 0200	/* if short doesn't match we're sure */
#define CF_EQSURE 0400	/* if short does match we're sure */
#define CF_COND	01000	/* test c_expr as conditional first, if not null. */
			/* Set for everything except do {} while currently */
#define CF_LOOP 02000	/* loop on the c_expr conditional (loop modifiers) */
#define CF_INVERT 04000	/* it's an "unless" or an "until" */
#define CF_ONCE 010000	/* we've already pushed the label on the stack */
#define CF_FLIP 020000	/* on a match do flipflop */
#define CF_TERM 040000	/* value of this cmd might be returned */
#define CF_DBSUB 0100000 /* this is an inserted cmd for debugging */

#define CFT_FALSE 0	/* c_expr is always false */
#define CFT_TRUE 1	/* c_expr is always true */
#define CFT_REG 2	/* c_expr is a simple register */
#define CFT_ANCHOR 3	/* c_expr is an anchored search /^.../ */
#define CFT_STROP 4	/* c_expr is a string comparison */
#define CFT_SCAN 5	/* c_expr is an unanchored search /.../ */
#define CFT_GETS 6	/* c_expr is <filehandle> */
#define CFT_EVAL 7	/* c_expr is not optimized, so call eval() */
#define CFT_UNFLIP 8	/* 2nd half of range not optimized */
#define CFT_CHOP 9	/* c_expr is a chop on a register */
#define CFT_ARRAY 10	/* this is a foreach loop */
#define CFT_INDGETS 11	/* c_expr is <$variable> */
#define CFT_NUMOP 12	/* c_expr is a numeric comparison */
#define CFT_CCLASS 13	/* c_expr must start with one of these characters */

#ifdef DEBUGGING
#ifndef DOINIT
extern char *cmdopt[];
#else
char *cmdopt[] = {
    "FALSE",
    "TRUE",
    "REG",
    "ANCHOR",
    "STROP",
    "SCAN",
    "GETS",
    "EVAL",
    "UNFLIP",
    "CHOP",
    "ARRAY",
    "INDGETS",
    "NUMOP",
    "CCLASS",
    "14"
};
#endif
#endif /* DEBUGGING */

struct acmd {
    STAB	*ac_stab;	/* a symbol table entry */
    ARG		*ac_expr;	/* any associated expression */
};

struct ccmd {
    CMD		*cc_true;	/* normal code to do on if and while */
    CMD		*cc_alt;	/* else cmd ptr or continue code */
};

struct scmd {
    CMD		**sc_next;	/* array of pointers to commands */
    short	sc_offset;	/* first value - 1 */
    short	sc_max;		/* last value + 1 */
};

struct cmd {
    CMD		*c_next;	/* the next command at this level */
    ARG		*c_expr;	/* conditional expression */
    CMD		*c_head;	/* head of this command list */
    STR		*c_short;	/* string to match as shortcut */
    STAB	*c_stab;	/* a symbol table entry, mostly for fp */
    SPAT	*c_spat;	/* pattern used by optimization */
    char	*c_label;	/* label for this construct */
    union ucmd {
	struct acmd acmd;	/* normal command */
	struct ccmd ccmd;	/* compound command */
	struct scmd scmd;	/* switch command */
    } ucmd;
    short	c_slen;		/* len of c_short, if not null */
    short	c_flags;	/* optimization flags--see above */
    char	*c_file;	/* file the following line # is from */
    line_t      c_line;         /* line # of this command */
    char	c_type;		/* what this command does */
};

#define Nullcmd Null(CMD*)

EXT CMD *main_root INIT(Nullcmd);
EXT CMD *eval_root INIT(Nullcmd);

struct compcmd {
    CMD *comp_true;
    CMD *comp_alt;
};

void opt_arg();
void evalstatic();
int cmd_exec();
