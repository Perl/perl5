/* $Header: arg.h,v 3.0.1.1 89/10/26 23:02:35 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	arg.h,v $
 * Revision 3.0.1.1  89/10/26  23:02:35  lwall
 * patch1: reverse didn't work
 * 
 * Revision 3.0  89/10/18  15:08:27  lwall
 * 3.0 baseline
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
#define O_EVAL 105
#define O_FTEREAD 106
#define O_FTEWRITE 107
#define O_FTEEXEC 108
#define O_FTEOWNED 109
#define O_FTRREAD 110
#define O_FTRWRITE 111
#define O_FTREXEC 112
#define O_FTROWNED 113
#define O_FTIS 114
#define O_FTZERO 115
#define O_FTSIZE 116
#define O_FTFILE 117
#define O_FTDIR 118
#define O_FTLINK 119
#define O_SYMLINK 120
#define O_FTPIPE 121
#define O_FTSOCK 122
#define O_FTBLK 123
#define O_FTCHR 124
#define O_FTSUID 125
#define O_FTSGID 126
#define O_FTSVTX 127
#define O_FTTTY 128
#define O_DOFILE 129
#define O_FTTEXT 130
#define O_FTBINARY 131
#define O_UTIME 132
#define O_WAIT 133
#define O_SORT 134
#define O_DELETE 135
#define O_STUDY 136
#define O_ATAN2 137
#define O_SIN 138
#define O_COS 139
#define O_RAND 140
#define O_SRAND 141
#define O_POW 142
#define O_RETURN 143
#define O_GETC 144
#define O_MKDIR 145
#define O_RMDIR 146
#define O_GETPPID 147
#define O_GETPGRP 148
#define O_SETPGRP 149
#define O_GETPRIORITY 150
#define O_SETPRIORITY 151
#define O_CHROOT 152
#define O_IOCTL 153
#define O_FCNTL 154
#define O_FLOCK 155
#define O_RINDEX 156
#define O_PACK 157
#define O_UNPACK 158
#define O_READ 159
#define O_WARN 160
#define O_DBMOPEN 161
#define O_DBMCLOSE 162
#define O_ASLICE 163
#define O_HSLICE 164
#define O_LASLICE 165
#define O_LHSLICE 166
#define O_F_OR_R 167
#define O_RANGE 168
#define O_RCAT 169
#define O_AASSIGN 170
#define O_SASSIGN 171
#define O_DUMP 172
#define O_REVERSE 173
#define O_ADDROF 174
#define O_SOCKET 175
#define O_BIND 176
#define O_CONNECT 177
#define O_LISTEN 178
#define O_ACCEPT 179
#define O_SEND 180
#define O_RECV 181
#define O_SSELECT 182
#define O_SOCKETPAIR 183
#define O_DBSUBR 184
#define O_DEFINED 185
#define O_UNDEF 186
#define O_READLINK 187
#define O_LSTAT 188
#define O_AELEM 189
#define O_HELEM 190
#define O_LAELEM 191
#define O_LHELEM 192
#define O_LOCAL 193
#define O_UNUSED 194
#define O_FILENO 195
#define O_GHBYNAME 196
#define O_GHBYADDR 197
#define O_GHOSTENT 198
#define O_SHOSTENT 199
#define O_EHOSTENT 200
#define O_GSBYNAME 201
#define O_GSBYPORT 202
#define O_GSERVENT 203
#define O_SSERVENT 204
#define O_ESERVENT 205
#define O_GPBYNAME 206
#define O_GPBYNUMBER 207
#define O_GPROTOENT 208
#define O_SPROTOENT 209
#define O_EPROTOENT 210
#define O_GNBYNAME 211
#define O_GNBYADDR 212
#define O_GNETENT 213
#define O_SNETENT 214
#define O_ENETENT 215
#define O_VEC 216
#define O_GREP 217
#define O_GPWNAM 218
#define O_GPWUID 219
#define O_GPWENT 220
#define O_SPWENT 221
#define O_EPWENT 222
#define O_GGRNAM 223
#define O_GGRGID 224
#define O_GGRENT 225
#define O_SGRENT 226
#define O_EGRENT 227
#define O_SHUTDOWN 228
#define O_OPENDIR 229
#define O_READDIR 230
#define O_TELLDIR 231
#define O_SEEKDIR 232
#define O_REWINDDIR 233
#define O_CLOSEDIR 234
#define O_GETLOGIN 235
#define O_SYSCALL 236
#define O_GSOCKOPT 237
#define O_SSOCKOPT 238
#define O_GETSOCKNAME 239
#define O_GETPEERNAME 240
#define MAXO 241

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
    "EVAL",
    "FTEREAD",
    "FTEWRITE",
    "FTEEXEC",
    "FTEOWNED",
    "FTRREAD",
    "FTRWRITE",
    "FTREXEC",
    "FTROWNED",
    "FTIS",
    "FTZERO",
    "FTSIZE",
    "FTFILE",
    "FTDIR",
    "FTLINK",
    "SYMLINK",
    "FTPIPE",
    "FTSOCK",
    "FTBLK",
    "FTCHR",
    "FTSUID",
    "FTSGID",
    "FTSVTX",
    "FTTTY",
    "DOFILE",
    "FTTEXT",
    "FTBINARY",
    "UTIME",
    "WAIT",
    "SORT",
    "DELETE",
    "STUDY",
    "ATAN2",
    "SIN",
    "COS",
    "RAND",
    "SRAND",
    "POW",
    "RETURN",
    "GETC",
    "MKDIR",
    "RMDIR",
    "GETPPID",
    "GETPGRP",
    "SETPGRP",
    "GETPRIORITY",
    "SETPRIORITY",
    "CHROOT",
    "IOCTL",
    "FCNTL",
    "FLOCK",
    "RINDEX",
    "PACK",
    "UNPACK",
    "READ",
    "WARN",
    "DBMOPEN",
    "DBMCLOSE",
    "ASLICE",
    "HSLICE",
    "LASLICE",
    "LHSLICE",
    "FLIP_OR_RANGE",
    "RANGE",
    "RCAT",
    "AASSIGN",
    "SASSIGN",
    "DUMP",
    "REVERSE",
    "ADDRESS_OF",
    "SOCKET",
    "BIND",
    "CONNECT",
    "LISTEN",
    "ACCEPT",
    "SEND",
    "RECV",
    "SSELECT",
    "SOCKETPAIR",
    "DBSUBR",
    "DEFINED",
    "UNDEF",
    "READLINK",
    "LSTAT",
    "AELEM",
    "HELEM",
    "LAELEM",
    "LHELEM",
    "LOCAL",
    "UNUSED",
    "FILENO",
    "GHBYNAME",
    "GHBYADDR",
    "GHOSTENT",
    "SHOSTENT",
    "EHOSTENT",
    "GSBYNAME",
    "GSBYPORT",
    "GSERVENT",
    "SSERVENT",
    "ESERVENT",
    "GPBYNAME",
    "GPBYNUMBER",
    "GPROTOENT",
    "SPROTOENT",
    "EPROTOENT",
    "GNBYNAME",
    "GNBYADDR",
    "GNETENT",
    "SNETENT",
    "ENETENT",
    "VEC",
    "GREP",
    "GPWNAM",
    "GPWUID",
    "GPWENT",
    "SPWENT",
    "EPWENT",
    "GGRNAM",
    "GGRGID",
    "GGRENT",
    "SGRENT",
    "EGRENT",
    "SHUTDOWN",
    "OPENDIR",
    "READDIR",
    "TELLDIR",
    "SEEKDIR",
    "REWINDDIR",
    "CLOSEDIR",
    "GETLOGIN",
    "SYSCALL",
    "GSOCKOPT",
    "SSOCKOPT",
    "GETSOCKNAME",
    "GETPEERNAME",
    "241"
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
#define A_ARYSTAB 12
#define A_LARYLEN 13
#define A_GLOB 14
#define A_WORD 15
#define A_INDREAD 16
#define A_LARYSTAB 17
#define A_STAR 18
#define A_LSTAR 19
#define A_WANTARRAY 20

#define A_MASK 31
#define A_DONT 32		/* or this into type to suppress evaluation */

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
    "ARYSTAB",
    "LARYLEN",
    "GLOB",
    "WORD",
    "INDREAD",
    "LARYSTAB",
    "STAR",
    "LSTAR",
    "WANTARRAY",
    "21"
};
#endif

#ifndef DOINIT
extern bool hoistable[];
#else
bool hoistable[] =
  {0,	/* A_NULL */
   0,	/* EXPR */
   1,	/* CMD */
   1,	/* STAB */
   0,	/* LVAL */
   1,	/* SINGLE */
   0,	/* DOUBLE */
   0,	/* BACKTICK */
   0,	/* READ */
   0,	/* SPAT */
   0,	/* LEXPR */
   1,	/* ARYLEN */
   1,	/* ARYSTAB */
   0,	/* LARYLEN */
   0,	/* GLOB */
   1,	/* WORD */
   0,	/* INDREAD */
   0,	/* LARYSTAB */
   1,	/* STAR */
   1,	/* LSTAR */
   1,	/* WANTARRAY */
   0,	/* 21 */
};
#endif

union argptr {
    ARG		*arg_arg;
    char	*arg_cval;
    STAB	*arg_stab;
    SPAT	*arg_spat;
    CMD		*arg_cmd;
    STR		*arg_str;
    HASH	*arg_hash;
};

struct arg {
    union argptr arg_ptr;
    short	arg_len;
#ifdef mips
    short	pad;
#endif
    unsigned char arg_type;
    unsigned char arg_flags;
};

#define AF_ARYOK 1		/* op can handle multiple values here */
#define AF_POST 2		/* post *crement this item */
#define AF_PRE 4		/* pre *crement this item */
#define AF_UP 8			/* increment rather than decrement */
#define AF_COMMON 16		/* left and right have symbols in common */
#define AF_UNUSED 32		/*  */
#define AF_LISTISH 64		/* turn into list if important */
#define AF_LOCAL 128		/* list of local variables */

/*
 * Most of the ARG pointers are used as pointers to arrays of ARG.  When
 * so used, the 0th element is special, and represents the operator to
 * use on the list of arguments following.  The arg_len in the 0th element
 * gives the maximum argument number, and the arg_str is used to store
 * the return value in a more-or-less static location.  Sorry it's not
 * re-entrant (yet), but it sure makes it efficient.  The arg_type of the
 * 0th element is an operator (O_*) rather than an argument type (A_*).
 */

#define Nullarg Null(ARG*)

#ifndef DOINIT
EXT char opargs[MAXO+1];
#else
#define A(e1,e2,e3) (e1+(e2<<2)+(e3<<4))
char opargs[MAXO+1] = {
	A(0,0,0),	/* NULL */
	A(1,0,0),	/* ITEM */
	A(0,0,0),	/* ITEM2 */
	A(0,0,0),	/* ITEM3 */
	A(1,1,0),	/* CONCAT */
	A(1,0,0),	/* MATCH */
	A(1,0,0),	/* NMATCH */
	A(1,0,0),	/* SUBST */
	A(1,0,0),	/* NSUBST */
	A(1,1,0),	/* ASSIGN */
	A(1,1,0),	/* MULTIPLY */
	A(1,1,0),	/* DIVIDE */
	A(1,1,0),	/* MODULO */
	A(1,1,0),	/* ADD */
	A(1,1,0),	/* SUBTRACT */
	A(1,1,0),	/* LEFT_SHIFT */
	A(1,1,0),	/* RIGHT_SHIFT */
	A(1,1,0),	/* LT */
	A(1,1,0),	/* GT */
	A(1,1,0),	/* LE */
	A(1,1,0),	/* GE */
	A(1,1,0),	/* EQ */
	A(1,1,0),	/* NE */
	A(1,1,0),	/* BIT_AND */
	A(1,1,0),	/* XOR */
	A(1,1,0),	/* BIT_OR */
	A(1,0,0),	/* AND */
	A(1,0,0),	/* OR */
	A(1,0,0),	/* COND_EXPR */
	A(1,1,0),	/* COMMA */
	A(1,0,0),	/* NEGATE */
	A(1,0,0),	/* NOT */
	A(1,0,0),	/* COMPLEMENT */
	A(1,0,0),	/* WRITE */
	A(1,1,0),	/* OPEN */
	A(1,0,0),	/* TRANS */
	A(1,0,0),	/* NTRANS */
	A(1,0,0),	/* CLOSE */
	A(0,0,0),	/* ARRAY */
	A(0,0,0),	/* HASH */
	A(0,0,0),	/* LARRAY */
	A(0,0,0),	/* LHASH */
	A(0,3,0),	/* PUSH */
	A(0,0,0),	/* POP */
	A(0,0,0),	/* SHIFT */
	A(1,0,1),	/* SPLIT */
	A(1,0,0),	/* LENGTH */
	A(3,0,0),	/* SPRINTF */
	A(1,1,1),	/* SUBSTR */
	A(1,3,0),	/* JOIN */
	A(1,1,0),	/* SLT */
	A(1,1,0),	/* SGT */
	A(1,1,0),	/* SLE */
	A(1,1,0),	/* SGE */
	A(1,1,0),	/* SEQ */
	A(1,1,0),	/* SNE */
	A(0,3,0),	/* SUBR */
	A(1,3,0),	/* PRINT */
	A(1,0,0),	/* CHDIR */
	A(0,3,0),	/* DIE */
	A(1,0,0),	/* EXIT */
	A(1,0,0),	/* RESET */
	A(3,0,0),	/* LIST */
	A(1,0,0),	/* SELECT */
	A(1,0,0),	/* EOF */
	A(1,0,0),	/* TELL */
	A(1,1,1),	/* SEEK */
	A(0,0,0),	/* LAST */
	A(0,0,0),	/* NEXT */
	A(0,0,0),	/* REDO */
	A(0,0,0),	/* GOTO */
	A(1,1,0),	/* INDEX */
	A(0,0,0),	/* TIME */
	A(0,0,0),	/* TIMES */
	A(1,0,0),	/* LOCALTIME */
	A(1,0,0),	/* GMTIME */
	A(1,0,0),	/* STAT */
	A(1,1,0),	/* CRYPT */
	A(1,0,0),	/* EXP */
	A(1,0,0),	/* LOG */
	A(1,0,0),	/* SQRT */
	A(1,0,0),	/* INT */
	A(1,3,0),	/* PRINTF */
	A(1,0,0),	/* ORD */
	A(1,0,0),	/* SLEEP */
	A(1,0,0),	/* FLIP */
	A(0,1,0),	/* FLOP */
	A(0,0,0),	/* KEYS */
	A(0,0,0),	/* VALUES */
	A(0,0,0),	/* EACH */
	A(3,0,0),	/* CHOP */
	A(0,0,0),	/* FORK */
	A(1,3,0),	/* EXEC */
	A(1,3,0),	/* SYSTEM */
	A(1,0,0),	/* OCT */
	A(1,0,0),	/* HEX */
	A(0,3,0),	/* CHMOD */
	A(0,3,0),	/* CHOWN */
	A(0,3,0),	/* KILL */
	A(1,1,0),	/* RENAME */
	A(0,3,0),	/* UNLINK */
	A(1,0,0),	/* UMASK */
	A(0,3,0),	/* UNSHIFT */
	A(1,1,0),	/* LINK */
	A(1,1,0),	/* REPEAT */
	A(1,0,0),	/* EVAL */
	A(1,0,0),	/* FTEREAD */
	A(1,0,0),	/* FTEWRITE */
	A(1,0,0),	/* FTEEXEC */
	A(1,0,0),	/* FTEOWNED */
	A(1,0,0),	/* FTRREAD */
	A(1,0,0),	/* FTRWRITE */
	A(1,0,0),	/* FTREXEC */
	A(1,0,0),	/* FTROWNED */
	A(1,0,0),	/* FTIS */
	A(1,0,0),	/* FTZERO */
	A(1,0,0),	/* FTSIZE */
	A(1,0,0),	/* FTFILE */
	A(1,0,0),	/* FTDIR */
	A(1,0,0),	/* FTLINK */
	A(1,1,0),	/* SYMLINK */
	A(1,0,0),	/* FTPIPE */
	A(1,0,0),	/* FTSOCK */
	A(1,0,0),	/* FTBLK */
	A(1,0,0),	/* FTCHR */
	A(1,0,0),	/* FTSUID */
	A(1,0,0),	/* FTSGID */
	A(1,0,0),	/* FTSVTX */
	A(1,0,0),	/* FTTTY */
	A(1,0,0),	/* DOFILE */
	A(1,0,0),	/* FTTEXT */
	A(1,0,0),	/* FTBINARY */
	A(0,3,0),	/* UTIME */
	A(0,0,0),	/* WAIT */
	A(1,3,0),	/* SORT */
	A(0,1,0),	/* DELETE */
	A(1,0,0),	/* STUDY */
	A(1,1,0),	/* ATAN2 */
	A(1,0,0),	/* SIN */
	A(1,0,0),	/* COS */
	A(1,0,0),	/* RAND */
	A(1,0,0),	/* SRAND */
	A(1,1,0),	/* POW */
	A(0,3,0),	/* RETURN */
	A(1,0,0),	/* GETC */
	A(1,1,0),	/* MKDIR */
	A(1,0,0),	/* RMDIR */
	A(0,0,0),	/* GETPPID */
	A(1,0,0),	/* GETPGRP */
	A(1,1,0),	/* SETPGRP */
	A(1,1,0),	/* GETPRIORITY */
	A(1,1,1),	/* SETPRIORITY */
	A(1,0,0),	/* CHROOT */
	A(1,1,1),	/* IOCTL */
	A(1,1,1),	/* FCNTL */
	A(1,1,0),	/* FLOCK */
	A(1,1,0),	/* RINDEX */
	A(1,3,0),	/* PACK */
	A(1,1,0),	/* UNPACK */
	A(1,1,1),	/* READ */
	A(0,3,0),	/* WARN */
	A(1,1,1),	/* DBMOPEN */
	A(1,0,0),	/* DBMCLOSE */
	A(0,3,0),	/* ASLICE */
	A(0,3,0),	/* HSLICE */
	A(0,3,0),	/* LASLICE */
	A(0,3,0),	/* LHSLICE */
	A(1,0,0),	/* F_OR_R */
	A(1,1,0),	/* RANGE */
	A(1,1,0),	/* RCAT */
	A(3,3,0),	/* AASSIGN */
	A(0,0,0),	/* SASSIGN */
	A(0,0,0),	/* DUMP */
	A(0,3,0),	/* REVERSE */
	A(1,0,0),	/* ADDROF */
	A(1,1,1),	/* SOCKET */
	A(1,1,0),	/* BIND */
	A(1,1,0),	/* CONNECT */
	A(1,1,0),	/* LISTEN */
	A(1,1,0),	/* ACCEPT */
	A(1,1,2),	/* SEND */
	A(1,1,1),	/* RECV */
	A(1,1,1),	/* SSELECT */
	A(1,1,1),	/* SOCKETPAIR */
	A(0,3,0),	/* DBSUBR */
	A(1,0,0),	/* DEFINED */
	A(1,0,0),	/* UNDEF */
	A(1,0,0),	/* READLINK */
	A(1,0,0),	/* LSTAT */
	A(0,1,0),	/* AELEM */
	A(0,1,0),	/* HELEM */
	A(0,1,0),	/* LAELEM */
	A(0,1,0),	/* LHELEM */
	A(1,0,0),	/* LOCAL */
	A(0,0,0),	/* UNUSED */
	A(1,0,0),	/* FILENO */
	A(1,0,0),	/* GHBYNAME */
	A(1,1,0),	/* GHBYADDR */
	A(0,0,0),	/* GHOSTENT */
	A(1,0,0),	/* SHOSTENT */
	A(0,0,0),	/* EHOSTENT */
	A(1,1,0),	/* GSBYNAME */
	A(1,1,0),	/* GSBYPORT */
	A(0,0,0),	/* GSERVENT */
	A(1,0,0),	/* SSERVENT */
	A(0,0,0),	/* ESERVENT */
	A(1,0,0),	/* GPBYNAME */
	A(1,0,0),	/* GPBYNUMBER */
	A(0,0,0),	/* GPROTOENT */
	A(1,0,0),	/* SPROTOENT */
	A(0,0,0),	/* EPROTOENT */
	A(1,0,0),	/* GNBYNAME */
	A(1,1,0),	/* GNBYADDR */
	A(0,0,0),	/* GNETENT */
	A(1,0,0),	/* SNETENT */
	A(0,0,0),	/* ENETENT */
	A(1,1,1),	/* VEC */
	A(0,3,0),	/* GREP */
	A(1,0,0),	/* GPWNAM */
	A(1,0,0),	/* GPWUID */
	A(0,0,0),	/* GPWENT */
	A(0,0,0),	/* SPWENT */
	A(0,0,0),	/* EPWENT */
	A(1,0,0),	/* GGRNAM */
	A(1,0,0),	/* GGRGID */
	A(0,0,0),	/* GGRENT */
	A(0,0,0),	/* SGRENT */
	A(0,0,0),	/* EGRENT */
	A(1,1,0),	/* SHUTDOWN */
	A(1,1,0),	/* OPENDIR */
	A(1,0,0),	/* READDIR */
	A(1,0,0),	/* TELLDIR */
	A(1,1,0),	/* SEEKDIR */
	A(1,0,0),	/* REWINDDIR */
	A(1,0,0),	/* CLOSEDIR */
	A(0,0,0),	/* GETLOGIN */
	A(1,3,0),	/* SYSCALL */
	A(1,1,1),	/* GSOCKOPT */
	A(1,1,1),	/* SSOCKOPT */
	A(1,0,0),	/* GETSOCKNAME */
	A(1,0,0),	/* GETPEERNAME */
	0
};
#undef A
#endif

int do_trans();
int do_split();
bool do_eof();
long do_tell();
bool do_seek();
int do_tms();
int do_time();
int do_stat();
STR *do_push();
FILE *nextargv();
STR *do_fttext();
int do_slice();
