/* $Header: arg.h,v 1.0 87/12/18 13:04:39 root Exp $
 *
 * $Log:	arg.h,v $
 * Revision 1.0  87/12/18  13:04:39  root
 * Initial revision
 * 
 */

#define O_NULL 0
#define O_ITEM 1
#define O_ITEM2 2
#define O_ITEM3 3
#define O_CONCAT 4
#define O_MATCH 5
#define O_NMATCH 6
#define O_SUBST 7
#define O_NSUBST 8
#define O_ASSIGN 9
#define O_MULTIPLY 10
#define O_DIVIDE 11
#define O_MODULO 12
#define O_ADD 13
#define O_SUBTRACT 14
#define O_LEFT_SHIFT 15
#define O_RIGHT_SHIFT 16
#define O_LT 17
#define O_GT 18
#define O_LE 19
#define O_GE 20
#define O_EQ 21
#define O_NE 22
#define O_BIT_AND 23
#define O_XOR 24
#define O_BIT_OR 25
#define O_AND 26
#define O_OR 27
#define O_COND_EXPR 28
#define O_COMMA 29
#define O_NEGATE 30
#define O_NOT 31
#define O_COMPLEMENT 32
#define O_WRITE 33
#define O_OPEN 34
#define O_TRANS 35
#define O_NTRANS 36
#define O_CLOSE 37
#define O_ARRAY 38
#define O_HASH 39
#define O_LARRAY 40
#define O_LHASH 41
#define O_PUSH 42
#define O_POP 43
#define O_SHIFT 44
#define O_SPLIT 45
#define O_LENGTH 46
#define O_SPRINTF 47
#define O_SUBSTR 48
#define O_JOIN 49
#define O_SLT 50
#define O_SGT 51
#define O_SLE 52
#define O_SGE 53
#define O_SEQ 54
#define O_SNE 55
#define O_SUBR 56
#define O_PRINT 57
#define O_CHDIR 58
#define O_DIE 59
#define O_EXIT 60
#define O_RESET 61
#define O_LIST 62
#define O_SELECT 63
#define O_EOF 64
#define O_TELL 65
#define O_SEEK 66
#define O_LAST 67
#define O_NEXT 68
#define O_REDO 69
#define O_GOTO 70
#define O_INDEX 71
#define O_TIME 72
#define O_TMS 73
#define O_LOCALTIME 74
#define O_GMTIME 75
#define O_STAT 76
#define O_CRYPT 77
#define O_EXP 78
#define O_LOG 79
#define O_SQRT 80
#define O_INT 81
#define O_PRTF 82
#define O_ORD 83
#define O_SLEEP 84
#define O_FLIP 85
#define O_FLOP 86
#define O_KEYS 87
#define O_VALUES 88
#define O_EACH 89
#define O_CHOP 90
#define O_FORK 91
#define O_EXEC 92
#define O_SYSTEM 93
#define O_OCT 94
#define O_HEX 95
#define O_CHMOD 96
#define O_CHOWN 97
#define O_KILL 98
#define O_RENAME 99
#define O_UNLINK 100
#define O_UMASK 101
#define O_UNSHIFT 102
#define O_LINK 103
#define O_REPEAT 104
#define MAXO 105

#ifndef DOINIT
extern char *opname[];
#else
char *opname[] = {
    "NULL",
    "ITEM",
    "ITEM2",
    "ITEM3",
    "CONCAT",
    "MATCH",
    "NMATCH",
    "SUBST",
    "NSUBST",
    "ASSIGN",
    "MULTIPLY",
    "DIVIDE",
    "MODULO",
    "ADD",
    "SUBTRACT",
    "LEFT_SHIFT",
    "RIGHT_SHIFT",
    "LT",
    "GT",
    "LE",
    "GE",
    "EQ",
    "NE",
    "BIT_AND",
    "XOR",
    "BIT_OR",
    "AND",
    "OR",
    "COND_EXPR",
    "COMMA",
    "NEGATE",
    "NOT",
    "COMPLEMENT",
    "WRITE",
    "OPEN",
    "TRANS",
    "NTRANS",
    "CLOSE",
    "ARRAY",
    "HASH",
    "LARRAY",
    "LHASH",
    "PUSH",
    "POP",
    "SHIFT",
    "SPLIT",
    "LENGTH",
    "SPRINTF",
    "SUBSTR",
    "JOIN",
    "SLT",
    "SGT",
    "SLE",
    "SGE",
    "SEQ",
    "SNE",
    "SUBR",
    "PRINT",
    "CHDIR",
    "DIE",
    "EXIT",
    "RESET",
    "LIST",
    "SELECT",
    "EOF",
    "TELL",
    "SEEK",
    "LAST",
    "NEXT",
    "REDO",
    "GOTO",/* shudder */
    "INDEX",
    "TIME",
    "TIMES",
    "LOCALTIME",
    "GMTIME",
    "STAT",
    "CRYPT",
    "EXP",
    "LOG",
    "SQRT",
    "INT",
    "PRINTF",
    "ORD",
    "SLEEP",
    "FLIP",
    "FLOP",
    "KEYS",
    "VALUES",
    "EACH",
    "CHOP",
    "FORK",
    "EXEC",
    "SYSTEM",
    "OCT",
    "HEX",
    "CHMOD",
    "CHOWN",
    "KILL",
    "RENAME",
    "UNLINK",
    "UMASK",
    "UNSHIFT",
    "LINK",
    "REPEAT",
    "105"
};
#endif

#define A_NULL 0
#define A_EXPR 1
#define A_CMD 2
#define A_STAB 3
#define A_LVAL 4
#define A_SINGLE 5
#define A_DOUBLE 6
#define A_BACKTICK 7
#define A_READ 8
#define A_SPAT 9
#define A_LEXPR 10
#define A_ARYLEN 11
#define A_NUMBER 12

#ifndef DOINIT
extern char *argname[];
#else
char *argname[] = {
    "A_NULL",
    "EXPR",
    "CMD",
    "STAB",
    "LVAL",
    "SINGLE",
    "DOUBLE",
    "BACKTICK",
    "READ",
    "SPAT",
    "LEXPR",
    "ARYLEN",
    "NUMBER",
    "13"
};
#endif

#ifndef DOINIT
extern bool hoistable[];
#else
bool hoistable[] = {0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0};
#endif

struct arg {
    union argptr {
	ARG	*arg_arg;
	char	*arg_cval;
	STAB	*arg_stab;
	SPAT	*arg_spat;
	CMD	*arg_cmd;
	STR	*arg_str;
	double	arg_nval;
    } arg_ptr;
    short	arg_len;
    char	arg_type;
    char	arg_flags;
};

#define AF_SPECIAL 1		/* op wants to evaluate this arg itself */
#define AF_POST 2		/* post *crement this item */
#define AF_PRE 4		/* pre *crement this item */
#define AF_UP 8			/* increment rather than decrement */
#define AF_COMMON 16		/* left and right have symbols in common */
#define AF_NUMERIC 32		/* return as numeric rather than string */
#define AF_LISTISH 64		/* turn into list if important */

/*
 * Most of the ARG pointers are used as pointers to arrays of ARG.  When
 * so used, the 0th element is special, and represents the operator to
 * use on the list of arguments following.  The arg_len in the 0th element
 * gives the maximum argument number, and the arg_str is used to store
 * the return value in a more-or-less static location.  Sorry it's not
 * re-entrant, but it sure makes it efficient.  The arg_type of the
 * 0th element is an operator (O_*) rather than an argument type (A_*).
 */

#define Nullarg Null(ARG*)

EXT char opargs[MAXO];

int do_trans();
int do_split();
bool do_eof();
long do_tell();
bool do_seek();
int do_tms();
int do_time();
int do_stat();
