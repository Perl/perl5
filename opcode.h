typedef enum {
	OP_NULL,	/* 0 */
	OP_SCALAR,	/* 1 */
	OP_PUSHMARK,	/* 2 */
	OP_WANTARRAY,	/* 3 */
	OP_WORD,	/* 4 */
	OP_CONST,	/* 5 */
	OP_INTERP,	/* 6 */
	OP_GVSV,	/* 7 */
	OP_GV,		/* 8 */
	OP_PUSHRE,	/* 9 */
	OP_RV2GV,	/* 10 */
	OP_SV2LEN,	/* 11 */
	OP_RV2SV,	/* 12 */
	OP_AV2ARYLEN,	/* 13 */
	OP_RV2CV,	/* 14 */
	OP_REFGEN,	/* 15 */
	OP_REF,		/* 16 */
	OP_BLESS,	/* 17 */
	OP_BACKTICK,	/* 18 */
	OP_GLOB,	/* 19 */
	OP_READLINE,	/* 20 */
	OP_RCATLINE,	/* 21 */
	OP_REGCOMP,	/* 22 */
	OP_MATCH,	/* 23 */
	OP_SUBST,	/* 24 */
	OP_SUBSTCONT,	/* 25 */
	OP_TRANS,	/* 26 */
	OP_SASSIGN,	/* 27 */
	OP_AASSIGN,	/* 28 */
	OP_SCHOP,	/* 29 */
	OP_CHOP,	/* 30 */
	OP_DEFINED,	/* 31 */
	OP_UNDEF,	/* 32 */
	OP_STUDY,	/* 33 */
	OP_PREINC,	/* 34 */
	OP_PREDEC,	/* 35 */
	OP_POSTINC,	/* 36 */
	OP_POSTDEC,	/* 37 */
	OP_POW,		/* 38 */
	OP_MULTIPLY,	/* 39 */
	OP_DIVIDE,	/* 40 */
	OP_MODULO,	/* 41 */
	OP_REPEAT,	/* 42 */
	OP_ADD,		/* 43 */
	OP_INTADD,	/* 44 */
	OP_SUBTRACT,	/* 45 */
	OP_CONCAT,	/* 46 */
	OP_LEFT_SHIFT,	/* 47 */
	OP_RIGHT_SHIFT,	/* 48 */
	OP_LT,		/* 49 */
	OP_GT,		/* 50 */
	OP_LE,		/* 51 */
	OP_GE,		/* 52 */
	OP_EQ,		/* 53 */
	OP_NE,		/* 54 */
	OP_NCMP,	/* 55 */
	OP_SLT,		/* 56 */
	OP_SGT,		/* 57 */
	OP_SLE,		/* 58 */
	OP_SGE,		/* 59 */
	OP_SEQ,		/* 60 */
	OP_SNE,		/* 61 */
	OP_SCMP,	/* 62 */
	OP_BIT_AND,	/* 63 */
	OP_XOR,		/* 64 */
	OP_BIT_OR,	/* 65 */
	OP_NEGATE,	/* 66 */
	OP_NOT,		/* 67 */
	OP_COMPLEMENT,	/* 68 */
	OP_ATAN2,	/* 69 */
	OP_SIN,		/* 70 */
	OP_COS,		/* 71 */
	OP_RAND,	/* 72 */
	OP_SRAND,	/* 73 */
	OP_EXP,		/* 74 */
	OP_LOG,		/* 75 */
	OP_SQRT,	/* 76 */
	OP_INT,		/* 77 */
	OP_HEX,		/* 78 */
	OP_OCT,		/* 79 */
	OP_LENGTH,	/* 80 */
	OP_SUBSTR,	/* 81 */
	OP_VEC,		/* 82 */
	OP_INDEX,	/* 83 */
	OP_RINDEX,	/* 84 */
	OP_SPRINTF,	/* 85 */
	OP_FORMLINE,	/* 86 */
	OP_ORD,		/* 87 */
	OP_CRYPT,	/* 88 */
	OP_UCFIRST,	/* 89 */
	OP_LCFIRST,	/* 90 */
	OP_UC,		/* 91 */
	OP_LC,		/* 92 */
	OP_RV2AV,	/* 93 */
	OP_AELEMFAST,	/* 94 */
	OP_AELEM,	/* 95 */
	OP_ASLICE,	/* 96 */
	OP_EACH,	/* 97 */
	OP_VALUES,	/* 98 */
	OP_KEYS,	/* 99 */
	OP_DELETE,	/* 100 */
	OP_RV2HV,	/* 101 */
	OP_HELEM,	/* 102 */
	OP_HSLICE,	/* 103 */
	OP_UNPACK,	/* 104 */
	OP_PACK,	/* 105 */
	OP_SPLIT,	/* 106 */
	OP_JOIN,	/* 107 */
	OP_LIST,	/* 108 */
	OP_LSLICE,	/* 109 */
	OP_ANONLIST,	/* 110 */
	OP_ANONHASH,	/* 111 */
	OP_SPLICE,	/* 112 */
	OP_PUSH,	/* 113 */
	OP_POP,		/* 114 */
	OP_SHIFT,	/* 115 */
	OP_UNSHIFT,	/* 116 */
	OP_SORT,	/* 117 */
	OP_REVERSE,	/* 118 */
	OP_GREPSTART,	/* 119 */
	OP_GREPWHILE,	/* 120 */
	OP_RANGE,	/* 121 */
	OP_FLIP,	/* 122 */
	OP_FLOP,	/* 123 */
	OP_AND,		/* 124 */
	OP_OR,		/* 125 */
	OP_COND_EXPR,	/* 126 */
	OP_ANDASSIGN,	/* 127 */
	OP_ORASSIGN,	/* 128 */
	OP_METHOD,	/* 129 */
	OP_ENTERSUBR,	/* 130 */
	OP_LEAVESUBR,	/* 131 */
	OP_CALLER,	/* 132 */
	OP_WARN,	/* 133 */
	OP_DIE,		/* 134 */
	OP_RESET,	/* 135 */
	OP_LINESEQ,	/* 136 */
	OP_CURCOP,	/* 137 */
	OP_UNSTACK,	/* 138 */
	OP_ENTER,	/* 139 */
	OP_LEAVE,	/* 140 */
	OP_ENTERITER,	/* 141 */
	OP_ITER,	/* 142 */
	OP_ENTERLOOP,	/* 143 */
	OP_LEAVELOOP,	/* 144 */
	OP_RETURN,	/* 145 */
	OP_LAST,	/* 146 */
	OP_NEXT,	/* 147 */
	OP_REDO,	/* 148 */
	OP_DUMP,	/* 149 */
	OP_GOTO,	/* 150 */
	OP_EXIT,	/* 151 */
	OP_NSWITCH,	/* 152 */
	OP_CSWITCH,	/* 153 */
	OP_OPEN,	/* 154 */
	OP_CLOSE,	/* 155 */
	OP_PIPE_OP,	/* 156 */
	OP_FILENO,	/* 157 */
	OP_UMASK,	/* 158 */
	OP_BINMODE,	/* 159 */
	OP_DBMOPEN,	/* 160 */
	OP_DBMCLOSE,	/* 161 */
	OP_SSELECT,	/* 162 */
	OP_SELECT,	/* 163 */
	OP_GETC,	/* 164 */
	OP_READ,	/* 165 */
	OP_ENTERWRITE,	/* 166 */
	OP_LEAVEWRITE,	/* 167 */
	OP_PRTF,	/* 168 */
	OP_PRINT,	/* 169 */
	OP_SYSREAD,	/* 170 */
	OP_SYSWRITE,	/* 171 */
	OP_SEND,	/* 172 */
	OP_RECV,	/* 173 */
	OP_EOF,		/* 174 */
	OP_TELL,	/* 175 */
	OP_SEEK,	/* 176 */
	OP_TRUNCATE,	/* 177 */
	OP_FCNTL,	/* 178 */
	OP_IOCTL,	/* 179 */
	OP_FLOCK,	/* 180 */
	OP_SOCKET,	/* 181 */
	OP_SOCKPAIR,	/* 182 */
	OP_BIND,	/* 183 */
	OP_CONNECT,	/* 184 */
	OP_LISTEN,	/* 185 */
	OP_ACCEPT,	/* 186 */
	OP_SHUTDOWN,	/* 187 */
	OP_GSOCKOPT,	/* 188 */
	OP_SSOCKOPT,	/* 189 */
	OP_GETSOCKNAME,	/* 190 */
	OP_GETPEERNAME,	/* 191 */
	OP_LSTAT,	/* 192 */
	OP_STAT,	/* 193 */
	OP_FTRREAD,	/* 194 */
	OP_FTRWRITE,	/* 195 */
	OP_FTREXEC,	/* 196 */
	OP_FTEREAD,	/* 197 */
	OP_FTEWRITE,	/* 198 */
	OP_FTEEXEC,	/* 199 */
	OP_FTIS,	/* 200 */
	OP_FTEOWNED,	/* 201 */
	OP_FTROWNED,	/* 202 */
	OP_FTZERO,	/* 203 */
	OP_FTSIZE,	/* 204 */
	OP_FTMTIME,	/* 205 */
	OP_FTATIME,	/* 206 */
	OP_FTCTIME,	/* 207 */
	OP_FTSOCK,	/* 208 */
	OP_FTCHR,	/* 209 */
	OP_FTBLK,	/* 210 */
	OP_FTFILE,	/* 211 */
	OP_FTDIR,	/* 212 */
	OP_FTPIPE,	/* 213 */
	OP_FTLINK,	/* 214 */
	OP_FTSUID,	/* 215 */
	OP_FTSGID,	/* 216 */
	OP_FTSVTX,	/* 217 */
	OP_FTTTY,	/* 218 */
	OP_FTTEXT,	/* 219 */
	OP_FTBINARY,	/* 220 */
	OP_CHDIR,	/* 221 */
	OP_CHOWN,	/* 222 */
	OP_CHROOT,	/* 223 */
	OP_UNLINK,	/* 224 */
	OP_CHMOD,	/* 225 */
	OP_UTIME,	/* 226 */
	OP_RENAME,	/* 227 */
	OP_LINK,	/* 228 */
	OP_SYMLINK,	/* 229 */
	OP_READLINK,	/* 230 */
	OP_MKDIR,	/* 231 */
	OP_RMDIR,	/* 232 */
	OP_OPEN_DIR,	/* 233 */
	OP_READDIR,	/* 234 */
	OP_TELLDIR,	/* 235 */
	OP_SEEKDIR,	/* 236 */
	OP_REWINDDIR,	/* 237 */
	OP_CLOSEDIR,	/* 238 */
	OP_FORK,	/* 239 */
	OP_WAIT,	/* 240 */
	OP_WAITPID,	/* 241 */
	OP_SYSTEM,	/* 242 */
	OP_EXEC,	/* 243 */
	OP_KILL,	/* 244 */
	OP_GETPPID,	/* 245 */
	OP_GETPGRP,	/* 246 */
	OP_SETPGRP,	/* 247 */
	OP_GETPRIORITY,	/* 248 */
	OP_SETPRIORITY,	/* 249 */
	OP_TIME,	/* 250 */
	OP_TMS,		/* 251 */
	OP_LOCALTIME,	/* 252 */
	OP_GMTIME,	/* 253 */
	OP_ALARM,	/* 254 */
	OP_SLEEP,	/* 255 */
	OP_SHMGET,	/* 256 */
	OP_SHMCTL,	/* 257 */
	OP_SHMREAD,	/* 258 */
	OP_SHMWRITE,	/* 259 */
	OP_MSGGET,	/* 260 */
	OP_MSGCTL,	/* 261 */
	OP_MSGSND,	/* 262 */
	OP_MSGRCV,	/* 263 */
	OP_SEMGET,	/* 264 */
	OP_SEMCTL,	/* 265 */
	OP_SEMOP,	/* 266 */
	OP_REQUIRE,	/* 267 */
	OP_DOFILE,	/* 268 */
	OP_ENTEREVAL,	/* 269 */
	OP_LEAVEEVAL,	/* 270 */
	OP_EVALONCE,	/* 271 */
	OP_ENTERTRY,	/* 272 */
	OP_LEAVETRY,	/* 273 */
	OP_GHBYNAME,	/* 274 */
	OP_GHBYADDR,	/* 275 */
	OP_GHOSTENT,	/* 276 */
	OP_GNBYNAME,	/* 277 */
	OP_GNBYADDR,	/* 278 */
	OP_GNETENT,	/* 279 */
	OP_GPBYNAME,	/* 280 */
	OP_GPBYNUMBER,	/* 281 */
	OP_GPROTOENT,	/* 282 */
	OP_GSBYNAME,	/* 283 */
	OP_GSBYPORT,	/* 284 */
	OP_GSERVENT,	/* 285 */
	OP_SHOSTENT,	/* 286 */
	OP_SNETENT,	/* 287 */
	OP_SPROTOENT,	/* 288 */
	OP_SSERVENT,	/* 289 */
	OP_EHOSTENT,	/* 290 */
	OP_ENETENT,	/* 291 */
	OP_EPROTOENT,	/* 292 */
	OP_ESERVENT,	/* 293 */
	OP_GPWNAM,	/* 294 */
	OP_GPWUID,	/* 295 */
	OP_GPWENT,	/* 296 */
	OP_SPWENT,	/* 297 */
	OP_EPWENT,	/* 298 */
	OP_GGRNAM,	/* 299 */
	OP_GGRGID,	/* 300 */
	OP_GGRENT,	/* 301 */
	OP_SGRENT,	/* 302 */
	OP_EGRENT,	/* 303 */
	OP_GETLOGIN,	/* 304 */
	OP_SYSCALL,	/* 305 */
} opcode;

#define MAXO 306

#ifndef DOINIT
extern char *op_name[];
#else
char *op_name[] = {
	"null operation",
	"null operation",
	"pushmark",
	"wantarray",
	"bare word",
	"constant item",
	"interpreted string",
	"scalar variable",
	"glob value",
	"push regexp",
	"ref-to-glob cast",
	"scalar value length",
	"ref-to-scalar cast",
	"array length",
	"subroutine reference",
	"backslash reference",
	"reference-type operator",
	"bless",
	"backticks",
	"glob",
	"<HANDLE>",
	"append I/O operator",
	"regexp compilation",
	"pattern match",
	"substitution",
	"substitution cont",
	"character translation",
	"scalar assignment",
	"list assignment",
	"scalar chop",
	"chop",
	"defined operator",
	"undef operator",
	"study",
	"preincrement",
	"predecrement",
	"postincrement",
	"postdecrement",
	"exponentiation",
	"multiplication",
	"division",
	"modulus",
	"repeat",
	"addition",
	"integer addition",
	"subtraction",
	"concatenation",
	"left bitshift",
	"right bitshift",
	"numeric lt",
	"numeric gt",
	"numeric le",
	"numeric ge",
	"numeric eq",
	"numeric ne",
	"spaceship",
	"string lt",
	"string gt",
	"string le",
	"string ge",
	"string eq",
	"string ne",
	"string comparison",
	"bit and",
	"xor",
	"bit or",
	"negate",
	"not",
	"1's complement",
	"atan2",
	"sin",
	"cos",
	"rand",
	"srand",
	"exp",
	"log",
	"sqrt",
	"int",
	"hex",
	"oct",
	"length",
	"substr",
	"vec",
	"index",
	"rindex",
	"sprintf",
	"formline",
	"ord",
	"crypt",
	"upper case first",
	"lower case first",
	"upper case",
	"lower case",
	"array deref",
	"known array element",
	"array element",
	"array slice",
	"each",
	"values",
	"keys",
	"delete",
	"associative array deref",
	"associative array elem",
	"associative array slice",
	"unpack",
	"pack",
	"split",
	"join",
	"list",
	"list slice",
	"anonymous list",
	"anonymous hash",
	"splice",
	"push",
	"pop",
	"shift",
	"unshift",
	"sort",
	"reverse",
	"grep",
	"grep iterator",
	"flipflop",
	"range (or flip)",
	"range (or flop)",
	"logical and",
	"logical or",
	"conditional expression",
	"logical and assignment",
	"logical or assignment",
	"method lookup",
	"subroutine entry",
	"subroutine exit",
	"caller",
	"warn",
	"die",
	"reset",
	"line sequence",
	"next statement",
	"unstack",
	"block entry",
	"block exit",
	"foreach loop entry",
	"foreach loop iterator",
	"loop entry",
	"loop exit",
	"return",
	"last",
	"next",
	"redo",
	"dump",
	"goto",
	"exit",
	"numeric switch",
	"character switch",
	"open",
	"close",
	"pipe",
	"fileno",
	"umask",
	"binmode",
	"dbmopen",
	"dbmclose",
	"select system call",
	"select",
	"getc",
	"read",
	"write",
	"write exit",
	"prtf",
	"print",
	"sysread",
	"syswrite",
	"send",
	"recv",
	"eof",
	"tell",
	"seek",
	"truncate",
	"fcntl",
	"ioctl",
	"flock",
	"socket",
	"socketpair",
	"bind",
	"connect",
	"listen",
	"accept",
	"shutdown",
	"getsockopt",
	"setsockopt",
	"getsockname",
	"getpeername",
	"lstat",
	"stat",
	"-R",
	"-W",
	"-X",
	"-r",
	"-w",
	"-x",
	"-e",
	"-O",
	"-o",
	"-z",
	"-s",
	"-M",
	"-A",
	"-C",
	"-S",
	"-c",
	"-b",
	"-f",
	"-d",
	"-p",
	"-l",
	"-u",
	"-g",
	"-k",
	"-t",
	"-T",
	"-B",
	"chdir",
	"chown",
	"chroot",
	"unlink",
	"chmod",
	"utime",
	"rename",
	"link",
	"symlink",
	"readlink",
	"mkdir",
	"rmdir",
	"opendir",
	"readdir",
	"telldir",
	"seekdir",
	"rewinddir",
	"closedir",
	"fork",
	"wait",
	"waitpid",
	"system",
	"exec",
	"kill",
	"getppid",
	"getpgrp",
	"setpgrp",
	"getpriority",
	"setpriority",
	"time",
	"times",
	"localtime",
	"gmtime",
	"alarm",
	"sleep",
	"shmget",
	"shmctl",
	"shmread",
	"shmwrite",
	"msgget",
	"msgctl",
	"msgsnd",
	"msgrcv",
	"semget",
	"semctl",
	"semop",
	"require",
	"do 'file'",
	"eval string",
	"eval exit",
	"eval constant string",
	"eval block",
	"eval block exit",
	"gethostbyname",
	"gethostbyaddr",
	"gethostent",
	"getnetbyname",
	"getnetbyaddr",
	"getnetent",
	"getprotobyname",
	"getprotobynumber",
	"getprotoent",
	"getservbyname",
	"getservbyport",
	"getservent",
	"sethostent",
	"setnetent",
	"setprotoent",
	"setservent",
	"endhostent",
	"endnetent",
	"endprotoent",
	"endservent",
	"getpwnam",
	"getpwuid",
	"getpwent",
	"setpwent",
	"endpwent",
	"getgrnam",
	"getgrgid",
	"getgrent",
	"setgrent",
	"endgrent",
	"getlogin",
	"syscall",
};
#endif

OP *	ck_aelem	P((OP* op));
OP *	ck_chop		P((OP* op));
OP *	ck_concat	P((OP* op));
OP *	ck_eof		P((OP* op));
OP *	ck_eval		P((OP* op));
OP *	ck_exec		P((OP* op));
OP *	ck_formline	P((OP* op));
OP *	ck_ftst		P((OP* op));
OP *	ck_fun		P((OP* op));
OP *	ck_glob		P((OP* op));
OP *	ck_grep		P((OP* op));
OP *	ck_index	P((OP* op));
OP *	ck_lengthconst	P((OP* op));
OP *	ck_lfun		P((OP* op));
OP *	ck_listiob	P((OP* op));
OP *	ck_match	P((OP* op));
OP *	ck_null		P((OP* op));
OP *	ck_repeat	P((OP* op));
OP *	ck_rvconst	P((OP* op));
OP *	ck_select	P((OP* op));
OP *	ck_shift	P((OP* op));
OP *	ck_sort		P((OP* op));
OP *	ck_split	P((OP* op));
OP *	ck_subr		P((OP* op));
OP *	ck_trunc	P((OP* op));

OP *	pp_null		P((ARGSproto));
OP *	pp_scalar	P((ARGSproto));
OP *	pp_pushmark	P((ARGSproto));
OP *	pp_wantarray	P((ARGSproto));
OP *	pp_word		P((ARGSproto));
OP *	pp_const	P((ARGSproto));
OP *	pp_interp	P((ARGSproto));
OP *	pp_gvsv		P((ARGSproto));
OP *	pp_gv		P((ARGSproto));
OP *	pp_pushre	P((ARGSproto));
OP *	pp_rv2gv	P((ARGSproto));
OP *	pp_sv2len	P((ARGSproto));
OP *	pp_rv2sv	P((ARGSproto));
OP *	pp_av2arylen	P((ARGSproto));
OP *	pp_rv2cv	P((ARGSproto));
OP *	pp_refgen	P((ARGSproto));
OP *	pp_ref		P((ARGSproto));
OP *	pp_bless	P((ARGSproto));
OP *	pp_backtick	P((ARGSproto));
OP *	pp_glob		P((ARGSproto));
OP *	pp_readline	P((ARGSproto));
OP *	pp_rcatline	P((ARGSproto));
OP *	pp_regcomp	P((ARGSproto));
OP *	pp_match	P((ARGSproto));
OP *	pp_subst	P((ARGSproto));
OP *	pp_substcont	P((ARGSproto));
OP *	pp_trans	P((ARGSproto));
OP *	pp_sassign	P((ARGSproto));
OP *	pp_aassign	P((ARGSproto));
OP *	pp_schop	P((ARGSproto));
OP *	pp_chop		P((ARGSproto));
OP *	pp_defined	P((ARGSproto));
OP *	pp_undef	P((ARGSproto));
OP *	pp_study	P((ARGSproto));
OP *	pp_preinc	P((ARGSproto));
OP *	pp_predec	P((ARGSproto));
OP *	pp_postinc	P((ARGSproto));
OP *	pp_postdec	P((ARGSproto));
OP *	pp_pow		P((ARGSproto));
OP *	pp_multiply	P((ARGSproto));
OP *	pp_divide	P((ARGSproto));
OP *	pp_modulo	P((ARGSproto));
OP *	pp_repeat	P((ARGSproto));
OP *	pp_add		P((ARGSproto));
OP *	pp_intadd	P((ARGSproto));
OP *	pp_subtract	P((ARGSproto));
OP *	pp_concat	P((ARGSproto));
OP *	pp_left_shift	P((ARGSproto));
OP *	pp_right_shift	P((ARGSproto));
OP *	pp_lt		P((ARGSproto));
OP *	pp_gt		P((ARGSproto));
OP *	pp_le		P((ARGSproto));
OP *	pp_ge		P((ARGSproto));
OP *	pp_eq		P((ARGSproto));
OP *	pp_ne		P((ARGSproto));
OP *	pp_ncmp		P((ARGSproto));
OP *	pp_slt		P((ARGSproto));
OP *	pp_sgt		P((ARGSproto));
OP *	pp_sle		P((ARGSproto));
OP *	pp_sge		P((ARGSproto));
OP *	pp_seq		P((ARGSproto));
OP *	pp_sne		P((ARGSproto));
OP *	pp_scmp		P((ARGSproto));
OP *	pp_bit_and	P((ARGSproto));
OP *	pp_xor		P((ARGSproto));
OP *	pp_bit_or	P((ARGSproto));
OP *	pp_negate	P((ARGSproto));
OP *	pp_not		P((ARGSproto));
OP *	pp_complement	P((ARGSproto));
OP *	pp_atan2	P((ARGSproto));
OP *	pp_sin		P((ARGSproto));
OP *	pp_cos		P((ARGSproto));
OP *	pp_rand		P((ARGSproto));
OP *	pp_srand	P((ARGSproto));
OP *	pp_exp		P((ARGSproto));
OP *	pp_log		P((ARGSproto));
OP *	pp_sqrt		P((ARGSproto));
OP *	pp_int		P((ARGSproto));
OP *	pp_hex		P((ARGSproto));
OP *	pp_oct		P((ARGSproto));
OP *	pp_length	P((ARGSproto));
OP *	pp_substr	P((ARGSproto));
OP *	pp_vec		P((ARGSproto));
OP *	pp_index	P((ARGSproto));
OP *	pp_rindex	P((ARGSproto));
OP *	pp_sprintf	P((ARGSproto));
OP *	pp_formline	P((ARGSproto));
OP *	pp_ord		P((ARGSproto));
OP *	pp_crypt	P((ARGSproto));
OP *	pp_ucfirst	P((ARGSproto));
OP *	pp_lcfirst	P((ARGSproto));
OP *	pp_uc		P((ARGSproto));
OP *	pp_lc		P((ARGSproto));
OP *	pp_rv2av	P((ARGSproto));
OP *	pp_aelemfast	P((ARGSproto));
OP *	pp_aelem	P((ARGSproto));
OP *	pp_aslice	P((ARGSproto));
OP *	pp_each		P((ARGSproto));
OP *	pp_values	P((ARGSproto));
OP *	pp_keys		P((ARGSproto));
OP *	pp_delete	P((ARGSproto));
OP *	pp_rv2hv	P((ARGSproto));
OP *	pp_helem	P((ARGSproto));
OP *	pp_hslice	P((ARGSproto));
OP *	pp_unpack	P((ARGSproto));
OP *	pp_pack		P((ARGSproto));
OP *	pp_split	P((ARGSproto));
OP *	pp_join		P((ARGSproto));
OP *	pp_list		P((ARGSproto));
OP *	pp_lslice	P((ARGSproto));
OP *	pp_anonlist	P((ARGSproto));
OP *	pp_anonhash	P((ARGSproto));
OP *	pp_splice	P((ARGSproto));
OP *	pp_push		P((ARGSproto));
OP *	pp_pop		P((ARGSproto));
OP *	pp_shift	P((ARGSproto));
OP *	pp_unshift	P((ARGSproto));
OP *	pp_sort		P((ARGSproto));
OP *	pp_reverse	P((ARGSproto));
OP *	pp_grepstart	P((ARGSproto));
OP *	pp_grepwhile	P((ARGSproto));
OP *	pp_range	P((ARGSproto));
OP *	pp_flip		P((ARGSproto));
OP *	pp_flop		P((ARGSproto));
OP *	pp_and		P((ARGSproto));
OP *	pp_or		P((ARGSproto));
OP *	pp_cond_expr	P((ARGSproto));
OP *	pp_andassign	P((ARGSproto));
OP *	pp_orassign	P((ARGSproto));
OP *	pp_method	P((ARGSproto));
OP *	pp_entersubr	P((ARGSproto));
OP *	pp_leavesubr	P((ARGSproto));
OP *	pp_caller	P((ARGSproto));
OP *	pp_warn		P((ARGSproto));
OP *	pp_die		P((ARGSproto));
OP *	pp_reset	P((ARGSproto));
OP *	pp_lineseq	P((ARGSproto));
OP *	pp_curcop	P((ARGSproto));
OP *	pp_unstack	P((ARGSproto));
OP *	pp_enter	P((ARGSproto));
OP *	pp_leave	P((ARGSproto));
OP *	pp_enteriter	P((ARGSproto));
OP *	pp_iter		P((ARGSproto));
OP *	pp_enterloop	P((ARGSproto));
OP *	pp_leaveloop	P((ARGSproto));
OP *	pp_return	P((ARGSproto));
OP *	pp_last		P((ARGSproto));
OP *	pp_next		P((ARGSproto));
OP *	pp_redo		P((ARGSproto));
OP *	pp_dump		P((ARGSproto));
OP *	pp_goto		P((ARGSproto));
OP *	pp_exit		P((ARGSproto));
OP *	pp_nswitch	P((ARGSproto));
OP *	pp_cswitch	P((ARGSproto));
OP *	pp_open		P((ARGSproto));
OP *	pp_close	P((ARGSproto));
OP *	pp_pipe_op	P((ARGSproto));
OP *	pp_fileno	P((ARGSproto));
OP *	pp_umask	P((ARGSproto));
OP *	pp_binmode	P((ARGSproto));
OP *	pp_dbmopen	P((ARGSproto));
OP *	pp_dbmclose	P((ARGSproto));
OP *	pp_sselect	P((ARGSproto));
OP *	pp_select	P((ARGSproto));
OP *	pp_getc		P((ARGSproto));
OP *	pp_read		P((ARGSproto));
OP *	pp_enterwrite	P((ARGSproto));
OP *	pp_leavewrite	P((ARGSproto));
OP *	pp_prtf		P((ARGSproto));
OP *	pp_print	P((ARGSproto));
OP *	pp_sysread	P((ARGSproto));
OP *	pp_syswrite	P((ARGSproto));
OP *	pp_send		P((ARGSproto));
OP *	pp_recv		P((ARGSproto));
OP *	pp_eof		P((ARGSproto));
OP *	pp_tell		P((ARGSproto));
OP *	pp_seek		P((ARGSproto));
OP *	pp_truncate	P((ARGSproto));
OP *	pp_fcntl	P((ARGSproto));
OP *	pp_ioctl	P((ARGSproto));
OP *	pp_flock	P((ARGSproto));
OP *	pp_socket	P((ARGSproto));
OP *	pp_sockpair	P((ARGSproto));
OP *	pp_bind		P((ARGSproto));
OP *	pp_connect	P((ARGSproto));
OP *	pp_listen	P((ARGSproto));
OP *	pp_accept	P((ARGSproto));
OP *	pp_shutdown	P((ARGSproto));
OP *	pp_gsockopt	P((ARGSproto));
OP *	pp_ssockopt	P((ARGSproto));
OP *	pp_getsockname	P((ARGSproto));
OP *	pp_getpeername	P((ARGSproto));
OP *	pp_lstat	P((ARGSproto));
OP *	pp_stat		P((ARGSproto));
OP *	pp_ftrread	P((ARGSproto));
OP *	pp_ftrwrite	P((ARGSproto));
OP *	pp_ftrexec	P((ARGSproto));
OP *	pp_fteread	P((ARGSproto));
OP *	pp_ftewrite	P((ARGSproto));
OP *	pp_fteexec	P((ARGSproto));
OP *	pp_ftis		P((ARGSproto));
OP *	pp_fteowned	P((ARGSproto));
OP *	pp_ftrowned	P((ARGSproto));
OP *	pp_ftzero	P((ARGSproto));
OP *	pp_ftsize	P((ARGSproto));
OP *	pp_ftmtime	P((ARGSproto));
OP *	pp_ftatime	P((ARGSproto));
OP *	pp_ftctime	P((ARGSproto));
OP *	pp_ftsock	P((ARGSproto));
OP *	pp_ftchr	P((ARGSproto));
OP *	pp_ftblk	P((ARGSproto));
OP *	pp_ftfile	P((ARGSproto));
OP *	pp_ftdir	P((ARGSproto));
OP *	pp_ftpipe	P((ARGSproto));
OP *	pp_ftlink	P((ARGSproto));
OP *	pp_ftsuid	P((ARGSproto));
OP *	pp_ftsgid	P((ARGSproto));
OP *	pp_ftsvtx	P((ARGSproto));
OP *	pp_fttty	P((ARGSproto));
OP *	pp_fttext	P((ARGSproto));
OP *	pp_ftbinary	P((ARGSproto));
OP *	pp_chdir	P((ARGSproto));
OP *	pp_chown	P((ARGSproto));
OP *	pp_chroot	P((ARGSproto));
OP *	pp_unlink	P((ARGSproto));
OP *	pp_chmod	P((ARGSproto));
OP *	pp_utime	P((ARGSproto));
OP *	pp_rename	P((ARGSproto));
OP *	pp_link		P((ARGSproto));
OP *	pp_symlink	P((ARGSproto));
OP *	pp_readlink	P((ARGSproto));
OP *	pp_mkdir	P((ARGSproto));
OP *	pp_rmdir	P((ARGSproto));
OP *	pp_open_dir	P((ARGSproto));
OP *	pp_readdir	P((ARGSproto));
OP *	pp_telldir	P((ARGSproto));
OP *	pp_seekdir	P((ARGSproto));
OP *	pp_rewinddir	P((ARGSproto));
OP *	pp_closedir	P((ARGSproto));
OP *	pp_fork		P((ARGSproto));
OP *	pp_wait		P((ARGSproto));
OP *	pp_waitpid	P((ARGSproto));
OP *	pp_system	P((ARGSproto));
OP *	pp_exec		P((ARGSproto));
OP *	pp_kill		P((ARGSproto));
OP *	pp_getppid	P((ARGSproto));
OP *	pp_getpgrp	P((ARGSproto));
OP *	pp_setpgrp	P((ARGSproto));
OP *	pp_getpriority	P((ARGSproto));
OP *	pp_setpriority	P((ARGSproto));
OP *	pp_time		P((ARGSproto));
OP *	pp_tms		P((ARGSproto));
OP *	pp_localtime	P((ARGSproto));
OP *	pp_gmtime	P((ARGSproto));
OP *	pp_alarm	P((ARGSproto));
OP *	pp_sleep	P((ARGSproto));
OP *	pp_shmget	P((ARGSproto));
OP *	pp_shmctl	P((ARGSproto));
OP *	pp_shmread	P((ARGSproto));
OP *	pp_shmwrite	P((ARGSproto));
OP *	pp_msgget	P((ARGSproto));
OP *	pp_msgctl	P((ARGSproto));
OP *	pp_msgsnd	P((ARGSproto));
OP *	pp_msgrcv	P((ARGSproto));
OP *	pp_semget	P((ARGSproto));
OP *	pp_semctl	P((ARGSproto));
OP *	pp_semop	P((ARGSproto));
OP *	pp_require	P((ARGSproto));
OP *	pp_dofile	P((ARGSproto));
OP *	pp_entereval	P((ARGSproto));
OP *	pp_leaveeval	P((ARGSproto));
OP *	pp_evalonce	P((ARGSproto));
OP *	pp_entertry	P((ARGSproto));
OP *	pp_leavetry	P((ARGSproto));
OP *	pp_ghbyname	P((ARGSproto));
OP *	pp_ghbyaddr	P((ARGSproto));
OP *	pp_ghostent	P((ARGSproto));
OP *	pp_gnbyname	P((ARGSproto));
OP *	pp_gnbyaddr	P((ARGSproto));
OP *	pp_gnetent	P((ARGSproto));
OP *	pp_gpbyname	P((ARGSproto));
OP *	pp_gpbynumber	P((ARGSproto));
OP *	pp_gprotoent	P((ARGSproto));
OP *	pp_gsbyname	P((ARGSproto));
OP *	pp_gsbyport	P((ARGSproto));
OP *	pp_gservent	P((ARGSproto));
OP *	pp_shostent	P((ARGSproto));
OP *	pp_snetent	P((ARGSproto));
OP *	pp_sprotoent	P((ARGSproto));
OP *	pp_sservent	P((ARGSproto));
OP *	pp_ehostent	P((ARGSproto));
OP *	pp_enetent	P((ARGSproto));
OP *	pp_eprotoent	P((ARGSproto));
OP *	pp_eservent	P((ARGSproto));
OP *	pp_gpwnam	P((ARGSproto));
OP *	pp_gpwuid	P((ARGSproto));
OP *	pp_gpwent	P((ARGSproto));
OP *	pp_spwent	P((ARGSproto));
OP *	pp_epwent	P((ARGSproto));
OP *	pp_ggrnam	P((ARGSproto));
OP *	pp_ggrgid	P((ARGSproto));
OP *	pp_ggrent	P((ARGSproto));
OP *	pp_sgrent	P((ARGSproto));
OP *	pp_egrent	P((ARGSproto));
OP *	pp_getlogin	P((ARGSproto));
OP *	pp_syscall	P((ARGSproto));

#ifndef DOINIT
extern OP * (*ppaddr[])();
#else
OP * (*ppaddr[])() = {
	pp_null,
	pp_scalar,
	pp_pushmark,
	pp_wantarray,
	pp_word,
	pp_const,
	pp_interp,
	pp_gvsv,
	pp_gv,
	pp_pushre,
	pp_rv2gv,
	pp_sv2len,
	pp_rv2sv,
	pp_av2arylen,
	pp_rv2cv,
	pp_refgen,
	pp_ref,
	pp_bless,
	pp_backtick,
	pp_glob,
	pp_readline,
	pp_rcatline,
	pp_regcomp,
	pp_match,
	pp_subst,
	pp_substcont,
	pp_trans,
	pp_sassign,
	pp_aassign,
	pp_schop,
	pp_chop,
	pp_defined,
	pp_undef,
	pp_study,
	pp_preinc,
	pp_predec,
	pp_postinc,
	pp_postdec,
	pp_pow,
	pp_multiply,
	pp_divide,
	pp_modulo,
	pp_repeat,
	pp_add,
	pp_intadd,
	pp_subtract,
	pp_concat,
	pp_left_shift,
	pp_right_shift,
	pp_lt,
	pp_gt,
	pp_le,
	pp_ge,
	pp_eq,
	pp_ne,
	pp_ncmp,
	pp_slt,
	pp_sgt,
	pp_sle,
	pp_sge,
	pp_seq,
	pp_sne,
	pp_scmp,
	pp_bit_and,
	pp_xor,
	pp_bit_or,
	pp_negate,
	pp_not,
	pp_complement,
	pp_atan2,
	pp_sin,
	pp_cos,
	pp_rand,
	pp_srand,
	pp_exp,
	pp_log,
	pp_sqrt,
	pp_int,
	pp_hex,
	pp_oct,
	pp_length,
	pp_substr,
	pp_vec,
	pp_index,
	pp_rindex,
	pp_sprintf,
	pp_formline,
	pp_ord,
	pp_crypt,
	pp_ucfirst,
	pp_lcfirst,
	pp_uc,
	pp_lc,
	pp_rv2av,
	pp_aelemfast,
	pp_aelem,
	pp_aslice,
	pp_each,
	pp_values,
	pp_keys,
	pp_delete,
	pp_rv2hv,
	pp_helem,
	pp_hslice,
	pp_unpack,
	pp_pack,
	pp_split,
	pp_join,
	pp_list,
	pp_lslice,
	pp_anonlist,
	pp_anonhash,
	pp_splice,
	pp_push,
	pp_pop,
	pp_shift,
	pp_unshift,
	pp_sort,
	pp_reverse,
	pp_grepstart,
	pp_grepwhile,
	pp_range,
	pp_flip,
	pp_flop,
	pp_and,
	pp_or,
	pp_cond_expr,
	pp_andassign,
	pp_orassign,
	pp_method,
	pp_entersubr,
	pp_leavesubr,
	pp_caller,
	pp_warn,
	pp_die,
	pp_reset,
	pp_lineseq,
	pp_curcop,
	pp_unstack,
	pp_enter,
	pp_leave,
	pp_enteriter,
	pp_iter,
	pp_enterloop,
	pp_leaveloop,
	pp_return,
	pp_last,
	pp_next,
	pp_redo,
	pp_dump,
	pp_goto,
	pp_exit,
	pp_nswitch,
	pp_cswitch,
	pp_open,
	pp_close,
	pp_pipe_op,
	pp_fileno,
	pp_umask,
	pp_binmode,
	pp_dbmopen,
	pp_dbmclose,
	pp_sselect,
	pp_select,
	pp_getc,
	pp_read,
	pp_enterwrite,
	pp_leavewrite,
	pp_prtf,
	pp_print,
	pp_sysread,
	pp_syswrite,
	pp_send,
	pp_recv,
	pp_eof,
	pp_tell,
	pp_seek,
	pp_truncate,
	pp_fcntl,
	pp_ioctl,
	pp_flock,
	pp_socket,
	pp_sockpair,
	pp_bind,
	pp_connect,
	pp_listen,
	pp_accept,
	pp_shutdown,
	pp_gsockopt,
	pp_ssockopt,
	pp_getsockname,
	pp_getpeername,
	pp_lstat,
	pp_stat,
	pp_ftrread,
	pp_ftrwrite,
	pp_ftrexec,
	pp_fteread,
	pp_ftewrite,
	pp_fteexec,
	pp_ftis,
	pp_fteowned,
	pp_ftrowned,
	pp_ftzero,
	pp_ftsize,
	pp_ftmtime,
	pp_ftatime,
	pp_ftctime,
	pp_ftsock,
	pp_ftchr,
	pp_ftblk,
	pp_ftfile,
	pp_ftdir,
	pp_ftpipe,
	pp_ftlink,
	pp_ftsuid,
	pp_ftsgid,
	pp_ftsvtx,
	pp_fttty,
	pp_fttext,
	pp_ftbinary,
	pp_chdir,
	pp_chown,
	pp_chroot,
	pp_unlink,
	pp_chmod,
	pp_utime,
	pp_rename,
	pp_link,
	pp_symlink,
	pp_readlink,
	pp_mkdir,
	pp_rmdir,
	pp_open_dir,
	pp_readdir,
	pp_telldir,
	pp_seekdir,
	pp_rewinddir,
	pp_closedir,
	pp_fork,
	pp_wait,
	pp_waitpid,
	pp_system,
	pp_exec,
	pp_kill,
	pp_getppid,
	pp_getpgrp,
	pp_setpgrp,
	pp_getpriority,
	pp_setpriority,
	pp_time,
	pp_tms,
	pp_localtime,
	pp_gmtime,
	pp_alarm,
	pp_sleep,
	pp_shmget,
	pp_shmctl,
	pp_shmread,
	pp_shmwrite,
	pp_msgget,
	pp_msgctl,
	pp_msgsnd,
	pp_msgrcv,
	pp_semget,
	pp_semctl,
	pp_semop,
	pp_require,
	pp_dofile,
	pp_entereval,
	pp_leaveeval,
	pp_evalonce,
	pp_entertry,
	pp_leavetry,
	pp_ghbyname,
	pp_ghbyaddr,
	pp_ghostent,
	pp_gnbyname,
	pp_gnbyaddr,
	pp_gnetent,
	pp_gpbyname,
	pp_gpbynumber,
	pp_gprotoent,
	pp_gsbyname,
	pp_gsbyport,
	pp_gservent,
	pp_shostent,
	pp_snetent,
	pp_sprotoent,
	pp_sservent,
	pp_ehostent,
	pp_enetent,
	pp_eprotoent,
	pp_eservent,
	pp_gpwnam,
	pp_gpwuid,
	pp_gpwent,
	pp_spwent,
	pp_epwent,
	pp_ggrnam,
	pp_ggrgid,
	pp_ggrent,
	pp_sgrent,
	pp_egrent,
	pp_getlogin,
	pp_syscall,
};
#endif

#ifndef DOINIT
extern OP * (*check[])();
#else
OP * (*check[])() = {
	ck_null,	/* null */
	ck_null,	/* scalar */
	ck_null,	/* pushmark */
	ck_null,	/* wantarray */
	ck_null,	/* word */
	ck_null,	/* const */
	ck_null,	/* interp */
	ck_null,	/* gvsv */
	ck_null,	/* gv */
	ck_null,	/* pushre */
	ck_rvconst,	/* rv2gv */
	ck_null,	/* sv2len */
	ck_rvconst,	/* rv2sv */
	ck_null,	/* av2arylen */
	ck_rvconst,	/* rv2cv */
	ck_null,	/* refgen */
	ck_fun,		/* ref */
	ck_fun,		/* bless */
	ck_null,	/* backtick */
	ck_glob,	/* glob */
	ck_null,	/* readline */
	ck_null,	/* rcatline */
	ck_null,	/* regcomp */
	ck_match,	/* match */
	ck_null,	/* subst */
	ck_null,	/* substcont */
	ck_null,	/* trans */
	ck_null,	/* sassign */
	ck_null,	/* aassign */
	ck_null,	/* schop */
	ck_chop,	/* chop */
	ck_lfun,	/* defined */
	ck_lfun,	/* undef */
	ck_fun,		/* study */
	ck_lfun,	/* preinc */
	ck_lfun,	/* predec */
	ck_lfun,	/* postinc */
	ck_lfun,	/* postdec */
	ck_null,	/* pow */
	ck_null,	/* multiply */
	ck_null,	/* divide */
	ck_null,	/* modulo */
	ck_repeat,	/* repeat */
	ck_null,	/* add */
	ck_null,	/* intadd */
	ck_null,	/* subtract */
	ck_concat,	/* concat */
	ck_null,	/* left_shift */
	ck_null,	/* right_shift */
	ck_null,	/* lt */
	ck_null,	/* gt */
	ck_null,	/* le */
	ck_null,	/* ge */
	ck_null,	/* eq */
	ck_null,	/* ne */
	ck_null,	/* ncmp */
	ck_null,	/* slt */
	ck_null,	/* sgt */
	ck_null,	/* sle */
	ck_null,	/* sge */
	ck_null,	/* seq */
	ck_null,	/* sne */
	ck_null,	/* scmp */
	ck_null,	/* bit_and */
	ck_null,	/* xor */
	ck_null,	/* bit_or */
	ck_null,	/* negate */
	ck_null,	/* not */
	ck_null,	/* complement */
	ck_fun,		/* atan2 */
	ck_fun,		/* sin */
	ck_fun,		/* cos */
	ck_fun,		/* rand */
	ck_fun,		/* srand */
	ck_fun,		/* exp */
	ck_fun,		/* log */
	ck_fun,		/* sqrt */
	ck_fun,		/* int */
	ck_fun,		/* hex */
	ck_fun,		/* oct */
	ck_lengthconst,	/* length */
	ck_fun,		/* substr */
	ck_fun,		/* vec */
	ck_index,	/* index */
	ck_index,	/* rindex */
	ck_fun,		/* sprintf */
	ck_formline,	/* formline */
	ck_fun,		/* ord */
	ck_fun,		/* crypt */
	ck_fun,		/* ucfirst */
	ck_fun,		/* lcfirst */
	ck_fun,		/* uc */
	ck_fun,		/* lc */
	ck_rvconst,	/* rv2av */
	ck_null,	/* aelemfast */
	ck_aelem,	/* aelem */
	ck_null,	/* aslice */
	ck_fun,		/* each */
	ck_fun,		/* values */
	ck_fun,		/* keys */
	ck_null,	/* delete */
	ck_rvconst,	/* rv2hv */
	ck_null,	/* helem */
	ck_null,	/* hslice */
	ck_fun,		/* unpack */
	ck_fun,		/* pack */
	ck_split,	/* split */
	ck_fun,		/* join */
	ck_null,	/* list */
	ck_null,	/* lslice */
	ck_null,	/* anonlist */
	ck_null,	/* anonhash */
	ck_fun,		/* splice */
	ck_fun,		/* push */
	ck_shift,	/* pop */
	ck_shift,	/* shift */
	ck_fun,		/* unshift */
	ck_sort,	/* sort */
	ck_fun,		/* reverse */
	ck_grep,	/* grepstart */
	ck_null,	/* grepwhile */
	ck_null,	/* range */
	ck_null,	/* flip */
	ck_null,	/* flop */
	ck_null,	/* and */
	ck_null,	/* or */
	ck_null,	/* cond_expr */
	ck_null,	/* andassign */
	ck_null,	/* orassign */
	ck_null,	/* method */
	ck_subr,	/* entersubr */
	ck_null,	/* leavesubr */
	ck_fun,		/* caller */
	ck_fun,		/* warn */
	ck_fun,		/* die */
	ck_fun,		/* reset */
	ck_null,	/* lineseq */
	ck_null,	/* curcop */
	ck_null,	/* unstack */
	ck_null,	/* enter */
	ck_null,	/* leave */
	ck_null,	/* enteriter */
	ck_null,	/* iter */
	ck_null,	/* enterloop */
	ck_null,	/* leaveloop */
	ck_fun,		/* return */
	ck_null,	/* last */
	ck_null,	/* next */
	ck_null,	/* redo */
	ck_null,	/* dump */
	ck_null,	/* goto */
	ck_fun,		/* exit */
	ck_null,	/* nswitch */
	ck_null,	/* cswitch */
	ck_fun,		/* open */
	ck_fun,		/* close */
	ck_fun,		/* pipe_op */
	ck_fun,		/* fileno */
	ck_fun,		/* umask */
	ck_fun,		/* binmode */
	ck_fun,		/* dbmopen */
	ck_fun,		/* dbmclose */
	ck_select,	/* sselect */
	ck_select,	/* select */
	ck_eof,		/* getc */
	ck_fun,		/* read */
	ck_fun,		/* enterwrite */
	ck_null,	/* leavewrite */
	ck_listiob,	/* prtf */
	ck_listiob,	/* print */
	ck_fun,		/* sysread */
	ck_fun,		/* syswrite */
	ck_fun,		/* send */
	ck_fun,		/* recv */
	ck_eof,		/* eof */
	ck_fun,		/* tell */
	ck_fun,		/* seek */
	ck_trunc,	/* truncate */
	ck_fun,		/* fcntl */
	ck_fun,		/* ioctl */
	ck_fun,		/* flock */
	ck_fun,		/* socket */
	ck_fun,		/* sockpair */
	ck_fun,		/* bind */
	ck_fun,		/* connect */
	ck_fun,		/* listen */
	ck_fun,		/* accept */
	ck_fun,		/* shutdown */
	ck_fun,		/* gsockopt */
	ck_fun,		/* ssockopt */
	ck_fun,		/* getsockname */
	ck_fun,		/* getpeername */
	ck_ftst,	/* lstat */
	ck_ftst,	/* stat */
	ck_ftst,	/* ftrread */
	ck_ftst,	/* ftrwrite */
	ck_ftst,	/* ftrexec */
	ck_ftst,	/* fteread */
	ck_ftst,	/* ftewrite */
	ck_ftst,	/* fteexec */
	ck_ftst,	/* ftis */
	ck_ftst,	/* fteowned */
	ck_ftst,	/* ftrowned */
	ck_ftst,	/* ftzero */
	ck_ftst,	/* ftsize */
	ck_ftst,	/* ftmtime */
	ck_ftst,	/* ftatime */
	ck_ftst,	/* ftctime */
	ck_ftst,	/* ftsock */
	ck_ftst,	/* ftchr */
	ck_ftst,	/* ftblk */
	ck_ftst,	/* ftfile */
	ck_ftst,	/* ftdir */
	ck_ftst,	/* ftpipe */
	ck_ftst,	/* ftlink */
	ck_ftst,	/* ftsuid */
	ck_ftst,	/* ftsgid */
	ck_ftst,	/* ftsvtx */
	ck_ftst,	/* fttty */
	ck_ftst,	/* fttext */
	ck_ftst,	/* ftbinary */
	ck_fun,		/* chdir */
	ck_fun,		/* chown */
	ck_fun,		/* chroot */
	ck_fun,		/* unlink */
	ck_fun,		/* chmod */
	ck_fun,		/* utime */
	ck_fun,		/* rename */
	ck_fun,		/* link */
	ck_fun,		/* symlink */
	ck_fun,		/* readlink */
	ck_fun,		/* mkdir */
	ck_fun,		/* rmdir */
	ck_fun,		/* open_dir */
	ck_fun,		/* readdir */
	ck_fun,		/* telldir */
	ck_fun,		/* seekdir */
	ck_fun,		/* rewinddir */
	ck_fun,		/* closedir */
	ck_null,	/* fork */
	ck_null,	/* wait */
	ck_fun,		/* waitpid */
	ck_exec,	/* system */
	ck_exec,	/* exec */
	ck_fun,		/* kill */
	ck_null,	/* getppid */
	ck_fun,		/* getpgrp */
	ck_fun,		/* setpgrp */
	ck_fun,		/* getpriority */
	ck_fun,		/* setpriority */
	ck_null,	/* time */
	ck_null,	/* tms */
	ck_fun,		/* localtime */
	ck_fun,		/* gmtime */
	ck_fun,		/* alarm */
	ck_fun,		/* sleep */
	ck_fun,		/* shmget */
	ck_fun,		/* shmctl */
	ck_fun,		/* shmread */
	ck_fun,		/* shmwrite */
	ck_fun,		/* msgget */
	ck_fun,		/* msgctl */
	ck_fun,		/* msgsnd */
	ck_fun,		/* msgrcv */
	ck_fun,		/* semget */
	ck_fun,		/* semctl */
	ck_fun,		/* semop */
	ck_fun,		/* require */
	ck_fun,		/* dofile */
	ck_eval,	/* entereval */
	ck_null,	/* leaveeval */
	ck_null,	/* evalonce */
	ck_null,	/* entertry */
	ck_null,	/* leavetry */
	ck_fun,		/* ghbyname */
	ck_fun,		/* ghbyaddr */
	ck_null,	/* ghostent */
	ck_fun,		/* gnbyname */
	ck_fun,		/* gnbyaddr */
	ck_null,	/* gnetent */
	ck_fun,		/* gpbyname */
	ck_fun,		/* gpbynumber */
	ck_null,	/* gprotoent */
	ck_fun,		/* gsbyname */
	ck_fun,		/* gsbyport */
	ck_null,	/* gservent */
	ck_fun,		/* shostent */
	ck_fun,		/* snetent */
	ck_fun,		/* sprotoent */
	ck_fun,		/* sservent */
	ck_null,	/* ehostent */
	ck_null,	/* enetent */
	ck_null,	/* eprotoent */
	ck_null,	/* eservent */
	ck_fun,		/* gpwnam */
	ck_fun,		/* gpwuid */
	ck_null,	/* gpwent */
	ck_null,	/* spwent */
	ck_null,	/* epwent */
	ck_fun,		/* ggrnam */
	ck_fun,		/* ggrgid */
	ck_null,	/* ggrent */
	ck_null,	/* sgrent */
	ck_null,	/* egrent */
	ck_null,	/* getlogin */
	ck_fun,		/* syscall */
};
#endif

#ifndef DOINIT
EXT U32 opargs[];
#else
U32 opargs[] = {
	0x00000000,	/* null */
	0x00000004,	/* scalar */
	0x00000004,	/* pushmark */
	0x00000014,	/* wantarray */
	0x00000004,	/* word */
	0x00000004,	/* const */
	0x00000000,	/* interp */
	0x00000044,	/* gvsv */
	0x00000044,	/* gv */
	0x00000000,	/* pushre */
	0x00000044,	/* rv2gv */
	0x0000001c,	/* sv2len */
	0x00000044,	/* rv2sv */
	0x00000014,	/* av2arylen */
	0x00000040,	/* rv2cv */
	0x0000020e,	/* refgen */
	0x0000010c,	/* ref */
	0x00000104,	/* bless */
	0x00000008,	/* backtick */
	0x00000008,	/* glob */
	0x00000008,	/* readline */
	0x00000008,	/* rcatline */
	0x00000104,	/* regcomp */
	0x00000040,	/* match */
	0x00000154,	/* subst */
	0x00000054,	/* substcont */
	0x00000114,	/* trans */
	0x00000004,	/* sassign */
	0x00002208,	/* aassign */
	0x00000008,	/* schop */
	0x00000209,	/* chop */
	0x00000914,	/* defined */
	0x00000904,	/* undef */
	0x0000090c,	/* study */
	0x00000104,	/* preinc */
	0x00000104,	/* predec */
	0x0000010c,	/* postinc */
	0x0000010c,	/* postdec */
	0x0000110e,	/* pow */
	0x0000110e,	/* multiply */
	0x0000110e,	/* divide */
	0x0000111e,	/* modulo */
	0x00001209,	/* repeat */
	0x0000112e,	/* add */
	0x0000111e,	/* intadd */
	0x0000110e,	/* subtract */
	0x0000110e,	/* concat */
	0x0000111e,	/* left_shift */
	0x0000111e,	/* right_shift */
	0x00001116,	/* lt */
	0x00001116,	/* gt */
	0x00001116,	/* le */
	0x00001116,	/* ge */
	0x00001116,	/* eq */
	0x00001116,	/* ne */
	0x0000111e,	/* ncmp */
	0x00001116,	/* slt */
	0x00001116,	/* sgt */
	0x00001116,	/* sle */
	0x00001116,	/* sge */
	0x00001116,	/* seq */
	0x00001116,	/* sne */
	0x0000111e,	/* scmp */
	0x0000110e,	/* bit_and */
	0x0000110e,	/* xor */
	0x0000110e,	/* bit_or */
	0x0000010e,	/* negate */
	0x00000116,	/* not */
	0x0000010e,	/* complement */
	0x0000110e,	/* atan2 */
	0x0000090e,	/* sin */
	0x0000090e,	/* cos */
	0x0000090c,	/* rand */
	0x00000904,	/* srand */
	0x0000090e,	/* exp */
	0x0000090e,	/* log */
	0x0000090e,	/* sqrt */
	0x0000090e,	/* int */
	0x0000091c,	/* hex */
	0x0000091c,	/* oct */
	0x0000011c,	/* length */
	0x0009110c,	/* substr */
	0x0001111c,	/* vec */
	0x0009111c,	/* index */
	0x0009111c,	/* rindex */
	0x0000210d,	/* sprintf */
	0x00002105,	/* formline */
	0x0000091e,	/* ord */
	0x0000110e,	/* crypt */
	0x0000010a,	/* ucfirst */
	0x0000010a,	/* lcfirst */
	0x0000010a,	/* uc */
	0x0000010a,	/* lc */
	0x00000048,	/* rv2av */
	0x00001304,	/* aelemfast */
	0x00001304,	/* aelem */
	0x00002301,	/* aslice */
	0x00000408,	/* each */
	0x00000408,	/* values */
	0x00000408,	/* keys */
	0x00001404,	/* delete */
	0x00000048,	/* rv2hv */
	0x00001404,	/* helem */
	0x00002401,	/* hslice */
	0x00001100,	/* unpack */
	0x0000210d,	/* pack */
	0x00011108,	/* split */
	0x0000210d,	/* join */
	0x00000201,	/* list */
	0x00022400,	/* lslice */
	0x00000201,	/* anonlist */
	0x00000201,	/* anonhash */
	0x00291301,	/* splice */
	0x0000231d,	/* push */
	0x00000304,	/* pop */
	0x00000304,	/* shift */
	0x0000231d,	/* unshift */
	0x00002d01,	/* sort */
	0x00000209,	/* reverse */
	0x00002541,	/* grepstart */
	0x00000048,	/* grepwhile */
	0x00001100,	/* range */
	0x00001100,	/* flip */
	0x00000000,	/* flop */
	0x00000000,	/* and */
	0x00000000,	/* or */
	0x00000000,	/* cond_expr */
	0x00000004,	/* andassign */
	0x00000004,	/* orassign */
	0x00000048,	/* method */
	0x00000241,	/* entersubr */
	0x00000000,	/* leavesubr */
	0x00000908,	/* caller */
	0x0000021d,	/* warn */
	0x0000025d,	/* die */
	0x00000914,	/* reset */
	0x00000000,	/* lineseq */
	0x00000004,	/* curcop */
	0x00000004,	/* unstack */
	0x00000000,	/* enter */
	0x00000000,	/* leave */
	0x00000040,	/* enteriter */
	0x00000000,	/* iter */
	0x00000040,	/* enterloop */
	0x00000004,	/* leaveloop */
	0x00000241,	/* return */
	0x00000044,	/* last */
	0x00000044,	/* next */
	0x00000044,	/* redo */
	0x00000044,	/* dump */
	0x00000044,	/* goto */
	0x00000944,	/* exit */
	0x00000040,	/* nswitch */
	0x00000040,	/* cswitch */
	0x0000961c,	/* open */
	0x00000e14,	/* close */
	0x00006614,	/* pipe_op */
	0x0000061c,	/* fileno */
	0x0000091c,	/* umask */
	0x00000604,	/* binmode */
	0x0001141c,	/* dbmopen */
	0x00000414,	/* dbmclose */
	0x00111108,	/* sselect */
	0x00000e0c,	/* select */
	0x00000e0c,	/* getc */
	0x0091761d,	/* read */
	0x00000e54,	/* enterwrite */
	0x00000000,	/* leavewrite */
	0x00002e15,	/* prtf */
	0x00002e15,	/* print */
	0x0091761d,	/* sysread */
	0x0091161d,	/* syswrite */
	0x0091161d,	/* send */
	0x0011761d,	/* recv */
	0x00000e14,	/* eof */
	0x00000e0c,	/* tell */
	0x00011604,	/* seek */
	0x00001114,	/* truncate */
	0x0001160c,	/* fcntl */
	0x0001160c,	/* ioctl */
	0x0000161c,	/* flock */
	0x00111614,	/* socket */
	0x01116614,	/* sockpair */
	0x00001614,	/* bind */
	0x00001614,	/* connect */
	0x00001614,	/* listen */
	0x0000661c,	/* accept */
	0x0000161c,	/* shutdown */
	0x00011614,	/* gsockopt */
	0x00111614,	/* ssockopt */
	0x00000614,	/* getsockname */
	0x00000614,	/* getpeername */
	0x00000600,	/* lstat */
	0x00000600,	/* stat */
	0x00000614,	/* ftrread */
	0x00000614,	/* ftrwrite */
	0x00000614,	/* ftrexec */
	0x00000614,	/* fteread */
	0x00000614,	/* ftewrite */
	0x00000614,	/* fteexec */
	0x00000614,	/* ftis */
	0x00000614,	/* fteowned */
	0x00000614,	/* ftrowned */
	0x00000614,	/* ftzero */
	0x0000061c,	/* ftsize */
	0x0000060c,	/* ftmtime */
	0x0000060c,	/* ftatime */
	0x0000060c,	/* ftctime */
	0x00000614,	/* ftsock */
	0x00000614,	/* ftchr */
	0x00000614,	/* ftblk */
	0x00000614,	/* ftfile */
	0x00000614,	/* ftdir */
	0x00000614,	/* ftpipe */
	0x00000614,	/* ftlink */
	0x00000614,	/* ftsuid */
	0x00000614,	/* ftsgid */
	0x00000614,	/* ftsvtx */
	0x00000614,	/* fttty */
	0x00000614,	/* fttext */
	0x00000614,	/* ftbinary */
	0x0000091c,	/* chdir */
	0x0000021d,	/* chown */
	0x0000091c,	/* chroot */
	0x0000021d,	/* unlink */
	0x0000021d,	/* chmod */
	0x0000021d,	/* utime */
	0x0000111c,	/* rename */
	0x0000111c,	/* link */
	0x0000111c,	/* symlink */
	0x0000090c,	/* readlink */
	0x0000111c,	/* mkdir */
	0x0000091c,	/* rmdir */
	0x00001614,	/* open_dir */
	0x00000600,	/* readdir */
	0x0000060c,	/* telldir */
	0x00001604,	/* seekdir */
	0x00000604,	/* rewinddir */
	0x00000614,	/* closedir */
	0x0000001c,	/* fork */
	0x0000001c,	/* wait */
	0x0000111c,	/* waitpid */
	0x0000291d,	/* system */
	0x0000295d,	/* exec */
	0x0000025d,	/* kill */
	0x0000001c,	/* getppid */
	0x0000091c,	/* getpgrp */
	0x0000111c,	/* setpgrp */
	0x0000111c,	/* getpriority */
	0x0001111c,	/* setpriority */
	0x0000001c,	/* time */
	0x00000000,	/* tms */
	0x00000908,	/* localtime */
	0x00000908,	/* gmtime */
	0x0000091c,	/* alarm */
	0x0000091c,	/* sleep */
	0x0001111d,	/* shmget */
	0x0001111d,	/* shmctl */
	0x0011111d,	/* shmread */
	0x0011111c,	/* shmwrite */
	0x0000111d,	/* msgget */
	0x0001111d,	/* msgctl */
	0x0001111d,	/* msgsnd */
	0x0111111d,	/* msgrcv */
	0x0001111d,	/* semget */
	0x0011111d,	/* semctl */
	0x0001111d,	/* semop */
	0x00000140,	/* require */
	0x00000140,	/* dofile */
	0x00000140,	/* entereval */
	0x00000100,	/* leaveeval */
	0x00000140,	/* evalonce */
	0x00000000,	/* entertry */
	0x00000000,	/* leavetry */
	0x00000100,	/* ghbyname */
	0x00001100,	/* ghbyaddr */
	0x00000000,	/* ghostent */
	0x00000100,	/* gnbyname */
	0x00001100,	/* gnbyaddr */
	0x00000000,	/* gnetent */
	0x00000100,	/* gpbyname */
	0x00000100,	/* gpbynumber */
	0x00000000,	/* gprotoent */
	0x00001100,	/* gsbyname */
	0x00001100,	/* gsbyport */
	0x00000000,	/* gservent */
	0x0000011c,	/* shostent */
	0x0000011c,	/* snetent */
	0x0000011c,	/* sprotoent */
	0x0000011c,	/* sservent */
	0x0000001c,	/* ehostent */
	0x0000001c,	/* enetent */
	0x0000001c,	/* eprotoent */
	0x0000001c,	/* eservent */
	0x00000100,	/* gpwnam */
	0x00000100,	/* gpwuid */
	0x00000000,	/* gpwent */
	0x0000001c,	/* spwent */
	0x0000001c,	/* epwent */
	0x00000100,	/* ggrnam */
	0x00000100,	/* ggrgid */
	0x00000000,	/* ggrent */
	0x0000001c,	/* sgrent */
	0x0000001c,	/* egrent */
	0x0000000c,	/* getlogin */
	0x0000211c,	/* syscall */
};
#endif
