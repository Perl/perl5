typedef enum {
	OP_NULL,	/* 0 */
	OP_STUB,	/* 1 */
	OP_SCALAR,	/* 2 */
	OP_PUSHMARK,	/* 3 */
	OP_WANTARRAY,	/* 4 */
	OP_CONST,	/* 5 */
	OP_INTERP,	/* 6 */
	OP_GVSV,	/* 7 */
	OP_GV,		/* 8 */
	OP_PADSV,	/* 9 */
	OP_PADAV,	/* 10 */
	OP_PADHV,	/* 11 */
	OP_PUSHRE,	/* 12 */
	OP_RV2GV,	/* 13 */
	OP_SV2LEN,	/* 14 */
	OP_RV2SV,	/* 15 */
	OP_AV2ARYLEN,	/* 16 */
	OP_RV2CV,	/* 17 */
	OP_REFGEN,	/* 18 */
	OP_REF,		/* 19 */
	OP_BLESS,	/* 20 */
	OP_BACKTICK,	/* 21 */
	OP_GLOB,	/* 22 */
	OP_READLINE,	/* 23 */
	OP_RCATLINE,	/* 24 */
	OP_REGCMAYBE,	/* 25 */
	OP_REGCOMP,	/* 26 */
	OP_MATCH,	/* 27 */
	OP_SUBST,	/* 28 */
	OP_SUBSTCONT,	/* 29 */
	OP_TRANS,	/* 30 */
	OP_SASSIGN,	/* 31 */
	OP_AASSIGN,	/* 32 */
	OP_SCHOP,	/* 33 */
	OP_CHOP,	/* 34 */
	OP_DEFINED,	/* 35 */
	OP_UNDEF,	/* 36 */
	OP_STUDY,	/* 37 */
	OP_PREINC,	/* 38 */
	OP_PREDEC,	/* 39 */
	OP_POSTINC,	/* 40 */
	OP_POSTDEC,	/* 41 */
	OP_POW,		/* 42 */
	OP_MULTIPLY,	/* 43 */
	OP_DIVIDE,	/* 44 */
	OP_MODULO,	/* 45 */
	OP_REPEAT,	/* 46 */
	OP_ADD,		/* 47 */
	OP_INTADD,	/* 48 */
	OP_SUBTRACT,	/* 49 */
	OP_CONCAT,	/* 50 */
	OP_LEFT_SHIFT,	/* 51 */
	OP_RIGHT_SHIFT,	/* 52 */
	OP_LT,		/* 53 */
	OP_GT,		/* 54 */
	OP_LE,		/* 55 */
	OP_GE,		/* 56 */
	OP_EQ,		/* 57 */
	OP_NE,		/* 58 */
	OP_NCMP,	/* 59 */
	OP_SLT,		/* 60 */
	OP_SGT,		/* 61 */
	OP_SLE,		/* 62 */
	OP_SGE,		/* 63 */
	OP_SEQ,		/* 64 */
	OP_SNE,		/* 65 */
	OP_SCMP,	/* 66 */
	OP_BIT_AND,	/* 67 */
	OP_XOR,		/* 68 */
	OP_BIT_OR,	/* 69 */
	OP_NEGATE,	/* 70 */
	OP_NOT,		/* 71 */
	OP_COMPLEMENT,	/* 72 */
	OP_ATAN2,	/* 73 */
	OP_SIN,		/* 74 */
	OP_COS,		/* 75 */
	OP_RAND,	/* 76 */
	OP_SRAND,	/* 77 */
	OP_EXP,		/* 78 */
	OP_LOG,		/* 79 */
	OP_SQRT,	/* 80 */
	OP_INT,		/* 81 */
	OP_HEX,		/* 82 */
	OP_OCT,		/* 83 */
	OP_ABS,		/* 84 */
	OP_LENGTH,	/* 85 */
	OP_SUBSTR,	/* 86 */
	OP_VEC,		/* 87 */
	OP_INDEX,	/* 88 */
	OP_RINDEX,	/* 89 */
	OP_SPRINTF,	/* 90 */
	OP_FORMLINE,	/* 91 */
	OP_ORD,		/* 92 */
	OP_CHR,		/* 93 */
	OP_CRYPT,	/* 94 */
	OP_UCFIRST,	/* 95 */
	OP_LCFIRST,	/* 96 */
	OP_UC,		/* 97 */
	OP_LC,		/* 98 */
	OP_RV2AV,	/* 99 */
	OP_AELEMFAST,	/* 100 */
	OP_AELEM,	/* 101 */
	OP_ASLICE,	/* 102 */
	OP_EACH,	/* 103 */
	OP_VALUES,	/* 104 */
	OP_KEYS,	/* 105 */
	OP_DELETE,	/* 106 */
	OP_RV2HV,	/* 107 */
	OP_HELEM,	/* 108 */
	OP_HSLICE,	/* 109 */
	OP_UNPACK,	/* 110 */
	OP_PACK,	/* 111 */
	OP_SPLIT,	/* 112 */
	OP_JOIN,	/* 113 */
	OP_LIST,	/* 114 */
	OP_LSLICE,	/* 115 */
	OP_ANONLIST,	/* 116 */
	OP_ANONHASH,	/* 117 */
	OP_SPLICE,	/* 118 */
	OP_PUSH,	/* 119 */
	OP_POP,		/* 120 */
	OP_SHIFT,	/* 121 */
	OP_UNSHIFT,	/* 122 */
	OP_SORT,	/* 123 */
	OP_REVERSE,	/* 124 */
	OP_GREPSTART,	/* 125 */
	OP_GREPWHILE,	/* 126 */
	OP_RANGE,	/* 127 */
	OP_FLIP,	/* 128 */
	OP_FLOP,	/* 129 */
	OP_AND,		/* 130 */
	OP_OR,		/* 131 */
	OP_COND_EXPR,	/* 132 */
	OP_ANDASSIGN,	/* 133 */
	OP_ORASSIGN,	/* 134 */
	OP_METHOD,	/* 135 */
	OP_ENTERSUBR,	/* 136 */
	OP_LEAVESUBR,	/* 137 */
	OP_CALLER,	/* 138 */
	OP_WARN,	/* 139 */
	OP_DIE,		/* 140 */
	OP_RESET,	/* 141 */
	OP_LINESEQ,	/* 142 */
	OP_NEXTSTATE,	/* 143 */
	OP_DBSTATE,	/* 144 */
	OP_UNSTACK,	/* 145 */
	OP_ENTER,	/* 146 */
	OP_LEAVE,	/* 147 */
	OP_SCOPE,	/* 148 */
	OP_ENTERITER,	/* 149 */
	OP_ITER,	/* 150 */
	OP_ENTERLOOP,	/* 151 */
	OP_LEAVELOOP,	/* 152 */
	OP_RETURN,	/* 153 */
	OP_LAST,	/* 154 */
	OP_NEXT,	/* 155 */
	OP_REDO,	/* 156 */
	OP_DUMP,	/* 157 */
	OP_GOTO,	/* 158 */
	OP_EXIT,	/* 159 */
	OP_NSWITCH,	/* 160 */
	OP_CSWITCH,	/* 161 */
	OP_OPEN,	/* 162 */
	OP_CLOSE,	/* 163 */
	OP_PIPE_OP,	/* 164 */
	OP_FILENO,	/* 165 */
	OP_UMASK,	/* 166 */
	OP_BINMODE,	/* 167 */
	OP_TIE,		/* 168 */
	OP_UNTIE,	/* 169 */
	OP_DBMOPEN,	/* 170 */
	OP_DBMCLOSE,	/* 171 */
	OP_SSELECT,	/* 172 */
	OP_SELECT,	/* 173 */
	OP_GETC,	/* 174 */
	OP_READ,	/* 175 */
	OP_ENTERWRITE,	/* 176 */
	OP_LEAVEWRITE,	/* 177 */
	OP_PRTF,	/* 178 */
	OP_PRINT,	/* 179 */
	OP_SYSREAD,	/* 180 */
	OP_SYSWRITE,	/* 181 */
	OP_SEND,	/* 182 */
	OP_RECV,	/* 183 */
	OP_EOF,		/* 184 */
	OP_TELL,	/* 185 */
	OP_SEEK,	/* 186 */
	OP_TRUNCATE,	/* 187 */
	OP_FCNTL,	/* 188 */
	OP_IOCTL,	/* 189 */
	OP_FLOCK,	/* 190 */
	OP_SOCKET,	/* 191 */
	OP_SOCKPAIR,	/* 192 */
	OP_BIND,	/* 193 */
	OP_CONNECT,	/* 194 */
	OP_LISTEN,	/* 195 */
	OP_ACCEPT,	/* 196 */
	OP_SHUTDOWN,	/* 197 */
	OP_GSOCKOPT,	/* 198 */
	OP_SSOCKOPT,	/* 199 */
	OP_GETSOCKNAME,	/* 200 */
	OP_GETPEERNAME,	/* 201 */
	OP_LSTAT,	/* 202 */
	OP_STAT,	/* 203 */
	OP_FTRREAD,	/* 204 */
	OP_FTRWRITE,	/* 205 */
	OP_FTREXEC,	/* 206 */
	OP_FTEREAD,	/* 207 */
	OP_FTEWRITE,	/* 208 */
	OP_FTEEXEC,	/* 209 */
	OP_FTIS,	/* 210 */
	OP_FTEOWNED,	/* 211 */
	OP_FTROWNED,	/* 212 */
	OP_FTZERO,	/* 213 */
	OP_FTSIZE,	/* 214 */
	OP_FTMTIME,	/* 215 */
	OP_FTATIME,	/* 216 */
	OP_FTCTIME,	/* 217 */
	OP_FTSOCK,	/* 218 */
	OP_FTCHR,	/* 219 */
	OP_FTBLK,	/* 220 */
	OP_FTFILE,	/* 221 */
	OP_FTDIR,	/* 222 */
	OP_FTPIPE,	/* 223 */
	OP_FTLINK,	/* 224 */
	OP_FTSUID,	/* 225 */
	OP_FTSGID,	/* 226 */
	OP_FTSVTX,	/* 227 */
	OP_FTTTY,	/* 228 */
	OP_FTTEXT,	/* 229 */
	OP_FTBINARY,	/* 230 */
	OP_CHDIR,	/* 231 */
	OP_CHOWN,	/* 232 */
	OP_CHROOT,	/* 233 */
	OP_UNLINK,	/* 234 */
	OP_CHMOD,	/* 235 */
	OP_UTIME,	/* 236 */
	OP_RENAME,	/* 237 */
	OP_LINK,	/* 238 */
	OP_SYMLINK,	/* 239 */
	OP_READLINK,	/* 240 */
	OP_MKDIR,	/* 241 */
	OP_RMDIR,	/* 242 */
	OP_OPEN_DIR,	/* 243 */
	OP_READDIR,	/* 244 */
	OP_TELLDIR,	/* 245 */
	OP_SEEKDIR,	/* 246 */
	OP_REWINDDIR,	/* 247 */
	OP_CLOSEDIR,	/* 248 */
	OP_FORK,	/* 249 */
	OP_WAIT,	/* 250 */
	OP_WAITPID,	/* 251 */
	OP_SYSTEM,	/* 252 */
	OP_EXEC,	/* 253 */
	OP_KILL,	/* 254 */
	OP_GETPPID,	/* 255 */
	OP_GETPGRP,	/* 256 */
	OP_SETPGRP,	/* 257 */
	OP_GETPRIORITY,	/* 258 */
	OP_SETPRIORITY,	/* 259 */
	OP_TIME,	/* 260 */
	OP_TMS,		/* 261 */
	OP_LOCALTIME,	/* 262 */
	OP_GMTIME,	/* 263 */
	OP_ALARM,	/* 264 */
	OP_SLEEP,	/* 265 */
	OP_SHMGET,	/* 266 */
	OP_SHMCTL,	/* 267 */
	OP_SHMREAD,	/* 268 */
	OP_SHMWRITE,	/* 269 */
	OP_MSGGET,	/* 270 */
	OP_MSGCTL,	/* 271 */
	OP_MSGSND,	/* 272 */
	OP_MSGRCV,	/* 273 */
	OP_SEMGET,	/* 274 */
	OP_SEMCTL,	/* 275 */
	OP_SEMOP,	/* 276 */
	OP_REQUIRE,	/* 277 */
	OP_DOFILE,	/* 278 */
	OP_ENTEREVAL,	/* 279 */
	OP_LEAVEEVAL,	/* 280 */
	OP_EVALONCE,	/* 281 */
	OP_ENTERTRY,	/* 282 */
	OP_LEAVETRY,	/* 283 */
	OP_GHBYNAME,	/* 284 */
	OP_GHBYADDR,	/* 285 */
	OP_GHOSTENT,	/* 286 */
	OP_GNBYNAME,	/* 287 */
	OP_GNBYADDR,	/* 288 */
	OP_GNETENT,	/* 289 */
	OP_GPBYNAME,	/* 290 */
	OP_GPBYNUMBER,	/* 291 */
	OP_GPROTOENT,	/* 292 */
	OP_GSBYNAME,	/* 293 */
	OP_GSBYPORT,	/* 294 */
	OP_GSERVENT,	/* 295 */
	OP_SHOSTENT,	/* 296 */
	OP_SNETENT,	/* 297 */
	OP_SPROTOENT,	/* 298 */
	OP_SSERVENT,	/* 299 */
	OP_EHOSTENT,	/* 300 */
	OP_ENETENT,	/* 301 */
	OP_EPROTOENT,	/* 302 */
	OP_ESERVENT,	/* 303 */
	OP_GPWNAM,	/* 304 */
	OP_GPWUID,	/* 305 */
	OP_GPWENT,	/* 306 */
	OP_SPWENT,	/* 307 */
	OP_EPWENT,	/* 308 */
	OP_GGRNAM,	/* 309 */
	OP_GGRGID,	/* 310 */
	OP_GGRENT,	/* 311 */
	OP_SGRENT,	/* 312 */
	OP_EGRENT,	/* 313 */
	OP_GETLOGIN,	/* 314 */
	OP_SYSCALL,	/* 315 */
} opcode;

#define MAXO 316

#ifndef DOINIT
extern char *op_name[];
#else
char *op_name[] = {
	"null operation",
	"stub",
	"scalar",
	"pushmark",
	"wantarray",
	"constant item",
	"interpreted string",
	"scalar variable",
	"glob value",
	"private variable",
	"private array",
	"private hash",
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
	"regexp comp once",
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
	"abs",
	"length",
	"substr",
	"vec",
	"index",
	"rindex",
	"sprintf",
	"formline",
	"ord",
	"chr",
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
	"debug next statement",
	"unstack",
	"block entry",
	"block exit",
	"block",
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
	"tie",
	"untie",
	"dbmopen",
	"dbmclose",
	"select system call",
	"select",
	"getc",
	"read",
	"write",
	"write exit",
	"printf",
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

OP *	pp_null		P((void));
OP *	pp_stub		P((void));
OP *	pp_scalar	P((void));
OP *	pp_pushmark	P((void));
OP *	pp_wantarray	P((void));
OP *	pp_const	P((void));
OP *	pp_interp	P((void));
OP *	pp_gvsv		P((void));
OP *	pp_gv		P((void));
OP *	pp_padsv	P((void));
OP *	pp_padav	P((void));
OP *	pp_padhv	P((void));
OP *	pp_pushre	P((void));
OP *	pp_rv2gv	P((void));
OP *	pp_sv2len	P((void));
OP *	pp_rv2sv	P((void));
OP *	pp_av2arylen	P((void));
OP *	pp_rv2cv	P((void));
OP *	pp_refgen	P((void));
OP *	pp_ref		P((void));
OP *	pp_bless	P((void));
OP *	pp_backtick	P((void));
OP *	pp_glob		P((void));
OP *	pp_readline	P((void));
OP *	pp_rcatline	P((void));
OP *	pp_regcmaybe	P((void));
OP *	pp_regcomp	P((void));
OP *	pp_match	P((void));
OP *	pp_subst	P((void));
OP *	pp_substcont	P((void));
OP *	pp_trans	P((void));
OP *	pp_sassign	P((void));
OP *	pp_aassign	P((void));
OP *	pp_schop	P((void));
OP *	pp_chop		P((void));
OP *	pp_defined	P((void));
OP *	pp_undef	P((void));
OP *	pp_study	P((void));
OP *	pp_preinc	P((void));
OP *	pp_predec	P((void));
OP *	pp_postinc	P((void));
OP *	pp_postdec	P((void));
OP *	pp_pow		P((void));
OP *	pp_multiply	P((void));
OP *	pp_divide	P((void));
OP *	pp_modulo	P((void));
OP *	pp_repeat	P((void));
OP *	pp_add		P((void));
OP *	pp_intadd	P((void));
OP *	pp_subtract	P((void));
OP *	pp_concat	P((void));
OP *	pp_left_shift	P((void));
OP *	pp_right_shift	P((void));
OP *	pp_lt		P((void));
OP *	pp_gt		P((void));
OP *	pp_le		P((void));
OP *	pp_ge		P((void));
OP *	pp_eq		P((void));
OP *	pp_ne		P((void));
OP *	pp_ncmp		P((void));
OP *	pp_slt		P((void));
OP *	pp_sgt		P((void));
OP *	pp_sle		P((void));
OP *	pp_sge		P((void));
OP *	pp_seq		P((void));
OP *	pp_sne		P((void));
OP *	pp_scmp		P((void));
OP *	pp_bit_and	P((void));
OP *	pp_xor		P((void));
OP *	pp_bit_or	P((void));
OP *	pp_negate	P((void));
OP *	pp_not		P((void));
OP *	pp_complement	P((void));
OP *	pp_atan2	P((void));
OP *	pp_sin		P((void));
OP *	pp_cos		P((void));
OP *	pp_rand		P((void));
OP *	pp_srand	P((void));
OP *	pp_exp		P((void));
OP *	pp_log		P((void));
OP *	pp_sqrt		P((void));
OP *	pp_int		P((void));
OP *	pp_hex		P((void));
OP *	pp_oct		P((void));
OP *	pp_abs		P((void));
OP *	pp_length	P((void));
OP *	pp_substr	P((void));
OP *	pp_vec		P((void));
OP *	pp_index	P((void));
OP *	pp_rindex	P((void));
OP *	pp_sprintf	P((void));
OP *	pp_formline	P((void));
OP *	pp_ord		P((void));
OP *	pp_chr		P((void));
OP *	pp_crypt	P((void));
OP *	pp_ucfirst	P((void));
OP *	pp_lcfirst	P((void));
OP *	pp_uc		P((void));
OP *	pp_lc		P((void));
OP *	pp_rv2av	P((void));
OP *	pp_aelemfast	P((void));
OP *	pp_aelem	P((void));
OP *	pp_aslice	P((void));
OP *	pp_each		P((void));
OP *	pp_values	P((void));
OP *	pp_keys		P((void));
OP *	pp_delete	P((void));
OP *	pp_rv2hv	P((void));
OP *	pp_helem	P((void));
OP *	pp_hslice	P((void));
OP *	pp_unpack	P((void));
OP *	pp_pack		P((void));
OP *	pp_split	P((void));
OP *	pp_join		P((void));
OP *	pp_list		P((void));
OP *	pp_lslice	P((void));
OP *	pp_anonlist	P((void));
OP *	pp_anonhash	P((void));
OP *	pp_splice	P((void));
OP *	pp_push		P((void));
OP *	pp_pop		P((void));
OP *	pp_shift	P((void));
OP *	pp_unshift	P((void));
OP *	pp_sort		P((void));
OP *	pp_reverse	P((void));
OP *	pp_grepstart	P((void));
OP *	pp_grepwhile	P((void));
OP *	pp_range	P((void));
OP *	pp_flip		P((void));
OP *	pp_flop		P((void));
OP *	pp_and		P((void));
OP *	pp_or		P((void));
OP *	pp_cond_expr	P((void));
OP *	pp_andassign	P((void));
OP *	pp_orassign	P((void));
OP *	pp_method	P((void));
OP *	pp_entersubr	P((void));
OP *	pp_leavesubr	P((void));
OP *	pp_caller	P((void));
OP *	pp_warn		P((void));
OP *	pp_die		P((void));
OP *	pp_reset	P((void));
OP *	pp_lineseq	P((void));
OP *	pp_nextstate	P((void));
OP *	pp_dbstate	P((void));
OP *	pp_unstack	P((void));
OP *	pp_enter	P((void));
OP *	pp_leave	P((void));
OP *	pp_scope	P((void));
OP *	pp_enteriter	P((void));
OP *	pp_iter		P((void));
OP *	pp_enterloop	P((void));
OP *	pp_leaveloop	P((void));
OP *	pp_return	P((void));
OP *	pp_last		P((void));
OP *	pp_next		P((void));
OP *	pp_redo		P((void));
OP *	pp_dump		P((void));
OP *	pp_goto		P((void));
OP *	pp_exit		P((void));
OP *	pp_nswitch	P((void));
OP *	pp_cswitch	P((void));
OP *	pp_open		P((void));
OP *	pp_close	P((void));
OP *	pp_pipe_op	P((void));
OP *	pp_fileno	P((void));
OP *	pp_umask	P((void));
OP *	pp_binmode	P((void));
OP *	pp_tie		P((void));
OP *	pp_untie	P((void));
OP *	pp_dbmopen	P((void));
OP *	pp_dbmclose	P((void));
OP *	pp_sselect	P((void));
OP *	pp_select	P((void));
OP *	pp_getc		P((void));
OP *	pp_read		P((void));
OP *	pp_enterwrite	P((void));
OP *	pp_leavewrite	P((void));
OP *	pp_prtf		P((void));
OP *	pp_print	P((void));
OP *	pp_sysread	P((void));
OP *	pp_syswrite	P((void));
OP *	pp_send		P((void));
OP *	pp_recv		P((void));
OP *	pp_eof		P((void));
OP *	pp_tell		P((void));
OP *	pp_seek		P((void));
OP *	pp_truncate	P((void));
OP *	pp_fcntl	P((void));
OP *	pp_ioctl	P((void));
OP *	pp_flock	P((void));
OP *	pp_socket	P((void));
OP *	pp_sockpair	P((void));
OP *	pp_bind		P((void));
OP *	pp_connect	P((void));
OP *	pp_listen	P((void));
OP *	pp_accept	P((void));
OP *	pp_shutdown	P((void));
OP *	pp_gsockopt	P((void));
OP *	pp_ssockopt	P((void));
OP *	pp_getsockname	P((void));
OP *	pp_getpeername	P((void));
OP *	pp_lstat	P((void));
OP *	pp_stat		P((void));
OP *	pp_ftrread	P((void));
OP *	pp_ftrwrite	P((void));
OP *	pp_ftrexec	P((void));
OP *	pp_fteread	P((void));
OP *	pp_ftewrite	P((void));
OP *	pp_fteexec	P((void));
OP *	pp_ftis		P((void));
OP *	pp_fteowned	P((void));
OP *	pp_ftrowned	P((void));
OP *	pp_ftzero	P((void));
OP *	pp_ftsize	P((void));
OP *	pp_ftmtime	P((void));
OP *	pp_ftatime	P((void));
OP *	pp_ftctime	P((void));
OP *	pp_ftsock	P((void));
OP *	pp_ftchr	P((void));
OP *	pp_ftblk	P((void));
OP *	pp_ftfile	P((void));
OP *	pp_ftdir	P((void));
OP *	pp_ftpipe	P((void));
OP *	pp_ftlink	P((void));
OP *	pp_ftsuid	P((void));
OP *	pp_ftsgid	P((void));
OP *	pp_ftsvtx	P((void));
OP *	pp_fttty	P((void));
OP *	pp_fttext	P((void));
OP *	pp_ftbinary	P((void));
OP *	pp_chdir	P((void));
OP *	pp_chown	P((void));
OP *	pp_chroot	P((void));
OP *	pp_unlink	P((void));
OP *	pp_chmod	P((void));
OP *	pp_utime	P((void));
OP *	pp_rename	P((void));
OP *	pp_link		P((void));
OP *	pp_symlink	P((void));
OP *	pp_readlink	P((void));
OP *	pp_mkdir	P((void));
OP *	pp_rmdir	P((void));
OP *	pp_open_dir	P((void));
OP *	pp_readdir	P((void));
OP *	pp_telldir	P((void));
OP *	pp_seekdir	P((void));
OP *	pp_rewinddir	P((void));
OP *	pp_closedir	P((void));
OP *	pp_fork		P((void));
OP *	pp_wait		P((void));
OP *	pp_waitpid	P((void));
OP *	pp_system	P((void));
OP *	pp_exec		P((void));
OP *	pp_kill		P((void));
OP *	pp_getppid	P((void));
OP *	pp_getpgrp	P((void));
OP *	pp_setpgrp	P((void));
OP *	pp_getpriority	P((void));
OP *	pp_setpriority	P((void));
OP *	pp_time		P((void));
OP *	pp_tms		P((void));
OP *	pp_localtime	P((void));
OP *	pp_gmtime	P((void));
OP *	pp_alarm	P((void));
OP *	pp_sleep	P((void));
OP *	pp_shmget	P((void));
OP *	pp_shmctl	P((void));
OP *	pp_shmread	P((void));
OP *	pp_shmwrite	P((void));
OP *	pp_msgget	P((void));
OP *	pp_msgctl	P((void));
OP *	pp_msgsnd	P((void));
OP *	pp_msgrcv	P((void));
OP *	pp_semget	P((void));
OP *	pp_semctl	P((void));
OP *	pp_semop	P((void));
OP *	pp_require	P((void));
OP *	pp_dofile	P((void));
OP *	pp_entereval	P((void));
OP *	pp_leaveeval	P((void));
OP *	pp_evalonce	P((void));
OP *	pp_entertry	P((void));
OP *	pp_leavetry	P((void));
OP *	pp_ghbyname	P((void));
OP *	pp_ghbyaddr	P((void));
OP *	pp_ghostent	P((void));
OP *	pp_gnbyname	P((void));
OP *	pp_gnbyaddr	P((void));
OP *	pp_gnetent	P((void));
OP *	pp_gpbyname	P((void));
OP *	pp_gpbynumber	P((void));
OP *	pp_gprotoent	P((void));
OP *	pp_gsbyname	P((void));
OP *	pp_gsbyport	P((void));
OP *	pp_gservent	P((void));
OP *	pp_shostent	P((void));
OP *	pp_snetent	P((void));
OP *	pp_sprotoent	P((void));
OP *	pp_sservent	P((void));
OP *	pp_ehostent	P((void));
OP *	pp_enetent	P((void));
OP *	pp_eprotoent	P((void));
OP *	pp_eservent	P((void));
OP *	pp_gpwnam	P((void));
OP *	pp_gpwuid	P((void));
OP *	pp_gpwent	P((void));
OP *	pp_spwent	P((void));
OP *	pp_epwent	P((void));
OP *	pp_ggrnam	P((void));
OP *	pp_ggrgid	P((void));
OP *	pp_ggrent	P((void));
OP *	pp_sgrent	P((void));
OP *	pp_egrent	P((void));
OP *	pp_getlogin	P((void));
OP *	pp_syscall	P((void));

#ifndef DOINIT
extern OP * (*ppaddr[])();
#else
OP * (*ppaddr[])() = {
	pp_null,
	pp_stub,
	pp_scalar,
	pp_pushmark,
	pp_wantarray,
	pp_const,
	pp_interp,
	pp_gvsv,
	pp_gv,
	pp_padsv,
	pp_padav,
	pp_padhv,
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
	pp_regcmaybe,
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
	pp_abs,
	pp_length,
	pp_substr,
	pp_vec,
	pp_index,
	pp_rindex,
	pp_sprintf,
	pp_formline,
	pp_ord,
	pp_chr,
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
	pp_nextstate,
	pp_dbstate,
	pp_unstack,
	pp_enter,
	pp_leave,
	pp_scope,
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
	pp_tie,
	pp_untie,
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
	ck_null,	/* stub */
	ck_fun,		/* scalar */
	ck_null,	/* pushmark */
	ck_null,	/* wantarray */
	ck_null,	/* const */
	ck_null,	/* interp */
	ck_null,	/* gvsv */
	ck_null,	/* gv */
	ck_null,	/* padsv */
	ck_null,	/* padav */
	ck_null,	/* padhv */
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
	ck_fun,		/* regcmaybe */
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
	ck_fun,		/* abs */
	ck_lengthconst,	/* length */
	ck_fun,		/* substr */
	ck_fun,		/* vec */
	ck_index,	/* index */
	ck_index,	/* rindex */
	ck_fun,		/* sprintf */
	ck_formline,	/* formline */
	ck_fun,		/* ord */
	ck_fun,		/* chr */
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
	ck_null,	/* nextstate */
	ck_null,	/* dbstate */
	ck_null,	/* unstack */
	ck_null,	/* enter */
	ck_null,	/* leave */
	ck_null,	/* scope */
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
	ck_fun,		/* tie */
	ck_fun,		/* untie */
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
	0x00000000,	/* stub */
	0x00000104,	/* scalar */
	0x00000004,	/* pushmark */
	0x00000014,	/* wantarray */
	0x00000004,	/* const */
	0x00000000,	/* interp */
	0x00000044,	/* gvsv */
	0x00000044,	/* gv */
	0x00000000,	/* padsv */
	0x00000000,	/* padav */
	0x00000000,	/* padhv */
	0x00000000,	/* pushre */
	0x00000044,	/* rv2gv */
	0x0000001c,	/* sv2len */
	0x00000044,	/* rv2sv */
	0x00000014,	/* av2arylen */
	0x00000040,	/* rv2cv */
	0x0000020e,	/* refgen */
	0x0000090c,	/* ref */
	0x00009104,	/* bless */
	0x00000008,	/* backtick */
	0x00000008,	/* glob */
	0x00000008,	/* readline */
	0x00000008,	/* rcatline */
	0x00000104,	/* regcmaybe */
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
	0x0000090e,	/* abs */
	0x0000011c,	/* length */
	0x0009110c,	/* substr */
	0x0001111c,	/* vec */
	0x0009111c,	/* index */
	0x0009111c,	/* rindex */
	0x0000210d,	/* sprintf */
	0x00002105,	/* formline */
	0x0000091e,	/* ord */
	0x0000090e,	/* chr */
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
	0x00000040,	/* method */
	0x00000241,	/* entersubr */
	0x00000000,	/* leavesubr */
	0x00000908,	/* caller */
	0x0000021d,	/* warn */
	0x0000025d,	/* die */
	0x00000914,	/* reset */
	0x00000000,	/* lineseq */
	0x00000004,	/* nextstate */
	0x00000004,	/* dbstate */
	0x00000004,	/* unstack */
	0x00000000,	/* enter */
	0x00000000,	/* leave */
	0x00000000,	/* scope */
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
	0x00021755,	/* tie */
	0x00000714,	/* untie */
	0x00011414,	/* dbmopen */
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
	0x00000114,	/* shostent */
	0x00000114,	/* snetent */
	0x00000114,	/* sprotoent */
	0x00000114,	/* sservent */
	0x00000014,	/* ehostent */
	0x00000014,	/* enetent */
	0x00000014,	/* eprotoent */
	0x00000014,	/* eservent */
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
