/* $Header: cmd.h,v 1.0.1.1 88/01/28 10:23:07 root Exp $
 *
 * $Log:	cmd.h,v $
 * Revision 1.0.1.1  88/01/28  10:23:07  root
 * patch8: added eval_root for eval operator.
 * 
 * Revision 1.0  87/12/18  13:04:59  root
 * Initial revision
 * 
 */

#define C_NULL 0
#define C_IF 1
#define C_WHILE 2
#define C_EXPR 3
#define C_BLOCK 4

#ifndef DOINIT
extern char *cmdname[];
#else
char *cmdname[] = {
    "NULL",
    "IF",
    "WHILE",
    "EXPR",
    "BLOCK",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16"
};
#endif

#define CF_OPTIMIZE 077	/* type of optimization */
#define CF_FIRSTNEG 0100/* conditional is ($register NE 'string') */
#define CF_NESURE 0200	/* if first doesn't match we're sure */
#define CF_EQSURE 0400	/* if first does match we're sure */
#define CF_COND	01000	/* test c_expr as conditional first, if not null. */
			/* Set for everything except do {} while currently */
#define CF_LOOP 02000	/* loop on the c_expr conditional (loop modifiers) */
#define CF_INVERT 04000	/* it's an "unless" or an "until" */
#define CF_ONCE 010000	/* we've already pushed the label on the stack */
#define CF_FLIP 020000	/* on a match do flipflop */

#define CFT_FALSE 0	/* c_expr is always false */
#define CFT_TRUE 1	/* c_expr is always true */
#define CFT_REG 2	/* c_expr is a simple register */
#define CFT_ANCHOR 3	/* c_expr is an anchored search /^.../ */
#define CFT_STROP 4	/* c_expr is a string comparison */
#define CFT_SCAN 5	/* c_expr is an unanchored search /.../ */
#define CFT_GETS 6	/* c_expr is $reg = <filehandle> */
#define CFT_EVAL 7	/* c_expr is not optimized, so call eval() */
#define CFT_UNFLIP 8	/* 2nd half of range not optimized */
#define CFT_CHOP 9	/* c_expr is a chop on a register */

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
    "10"
};
#endif

struct acmd {
    STAB	*ac_stab;	/* a symbol table entry */
    ARG		*ac_expr;	/* any associated expression */
};

struct ccmd {
    CMD		*cc_true;	/* normal code to do on if and while */
    CMD		*cc_alt;	/* else code or continue code */
};

struct cmd {
    CMD		*c_next;	/* the next command at this level */
    ARG		*c_expr;	/* conditional expression */
    CMD		*c_head;	/* head of this command list */
    STR		*c_first;	/* head of string to match as shortcut */
    STAB	*c_stab;	/* a symbol table entry, mostly for fp */
    SPAT	*c_spat;	/* pattern used by optimization */
    char	*c_label;	/* label for this construct */
    union ucmd {
	struct acmd acmd;	/* normal command */
	struct ccmd ccmd;	/* compound command */
    } ucmd;
    short	c_flen;		/* len of c_first, if not null */
    short	c_flags;	/* optimization flags--see above */
    char	c_type;		/* what this command does */
};

#define Nullcmd Null(CMD*)

EXT CMD *main_root INIT(Nullcmd);
EXT CMD *eval_root INIT(Nullcmd);

struct compcmd {
    CMD *comp_true;
    CMD *comp_alt;
};

#ifndef DOINIT
extern struct compcmd Nullccmd;
#else
struct compcmd Nullccmd = {Nullcmd, Nullcmd};
#endif
void opt_arg();
void evalstatic();
STR *cmd_exec();
