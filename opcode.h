#define Perl_pp_i_preinc Perl_pp_preinc
#define Perl_pp_i_predec Perl_pp_predec
#define Perl_pp_i_postinc Perl_pp_postinc
#define Perl_pp_i_postdec Perl_pp_postdec

typedef enum {
	OP_NULL,	/* 0 */
	OP_STUB,	/* 1 */
	OP_SCALAR,	/* 2 */
	OP_PUSHMARK,	/* 3 */
	OP_WANTARRAY,	/* 4 */
	OP_CONST,	/* 5 */
	OP_GVSV,	/* 6 */
	OP_GV,		/* 7 */
	OP_GELEM,	/* 8 */
	OP_PADSV,	/* 9 */
	OP_PADAV,	/* 10 */
	OP_PADHV,	/* 11 */
	OP_PADANY,	/* 12 */
	OP_PUSHRE,	/* 13 */
	OP_RV2GV,	/* 14 */
	OP_RV2SV,	/* 15 */
	OP_AV2ARYLEN,	/* 16 */
	OP_RV2CV,	/* 17 */
	OP_ANONCODE,	/* 18 */
	OP_PROTOTYPE,	/* 19 */
	OP_REFGEN,	/* 20 */
	OP_SREFGEN,	/* 21 */
	OP_REF,		/* 22 */
	OP_BLESS,	/* 23 */
	OP_BACKTICK,	/* 24 */
	OP_GLOB,	/* 25 */
	OP_READLINE,	/* 26 */
	OP_RCATLINE,	/* 27 */
	OP_REGCMAYBE,	/* 28 */
	OP_REGCRESET,	/* 29 */
	OP_REGCOMP,	/* 30 */
	OP_MATCH,	/* 31 */
	OP_QR,		/* 32 */
	OP_SUBST,	/* 33 */
	OP_SUBSTCONT,	/* 34 */
	OP_TRANS,	/* 35 */
	OP_SASSIGN,	/* 36 */
	OP_AASSIGN,	/* 37 */
	OP_CHOP,	/* 38 */
	OP_SCHOP,	/* 39 */
	OP_CHOMP,	/* 40 */
	OP_SCHOMP,	/* 41 */
	OP_DEFINED,	/* 42 */
	OP_UNDEF,	/* 43 */
	OP_STUDY,	/* 44 */
	OP_POS,		/* 45 */
	OP_PREINC,	/* 46 */
	OP_I_PREINC,	/* 47 */
	OP_PREDEC,	/* 48 */
	OP_I_PREDEC,	/* 49 */
	OP_POSTINC,	/* 50 */
	OP_I_POSTINC,	/* 51 */
	OP_POSTDEC,	/* 52 */
	OP_I_POSTDEC,	/* 53 */
	OP_POW,		/* 54 */
	OP_MULTIPLY,	/* 55 */
	OP_I_MULTIPLY,	/* 56 */
	OP_DIVIDE,	/* 57 */
	OP_I_DIVIDE,	/* 58 */
	OP_MODULO,	/* 59 */
	OP_I_MODULO,	/* 60 */
	OP_REPEAT,	/* 61 */
	OP_ADD,		/* 62 */
	OP_I_ADD,	/* 63 */
	OP_SUBTRACT,	/* 64 */
	OP_I_SUBTRACT,	/* 65 */
	OP_CONCAT,	/* 66 */
	OP_STRINGIFY,	/* 67 */
	OP_LEFT_SHIFT,	/* 68 */
	OP_RIGHT_SHIFT,	/* 69 */
	OP_LT,		/* 70 */
	OP_I_LT,	/* 71 */
	OP_GT,		/* 72 */
	OP_I_GT,	/* 73 */
	OP_LE,		/* 74 */
	OP_I_LE,	/* 75 */
	OP_GE,		/* 76 */
	OP_I_GE,	/* 77 */
	OP_EQ,		/* 78 */
	OP_I_EQ,	/* 79 */
	OP_NE,		/* 80 */
	OP_I_NE,	/* 81 */
	OP_NCMP,	/* 82 */
	OP_I_NCMP,	/* 83 */
	OP_SLT,		/* 84 */
	OP_SGT,		/* 85 */
	OP_SLE,		/* 86 */
	OP_SGE,		/* 87 */
	OP_SEQ,		/* 88 */
	OP_SNE,		/* 89 */
	OP_SCMP,	/* 90 */
	OP_BIT_AND,	/* 91 */
	OP_BIT_XOR,	/* 92 */
	OP_BIT_OR,	/* 93 */
	OP_NEGATE,	/* 94 */
	OP_I_NEGATE,	/* 95 */
	OP_NOT,		/* 96 */
	OP_COMPLEMENT,	/* 97 */
	OP_ATAN2,	/* 98 */
	OP_SIN,		/* 99 */
	OP_COS,		/* 100 */
	OP_RAND,	/* 101 */
	OP_SRAND,	/* 102 */
	OP_EXP,		/* 103 */
	OP_LOG,		/* 104 */
	OP_SQRT,	/* 105 */
	OP_INT,		/* 106 */
	OP_HEX,		/* 107 */
	OP_OCT,		/* 108 */
	OP_ABS,		/* 109 */
	OP_LENGTH,	/* 110 */
	OP_SUBSTR,	/* 111 */
	OP_VEC,		/* 112 */
	OP_INDEX,	/* 113 */
	OP_RINDEX,	/* 114 */
	OP_SPRINTF,	/* 115 */
	OP_FORMLINE,	/* 116 */
	OP_ORD,		/* 117 */
	OP_CHR,		/* 118 */
	OP_CRYPT,	/* 119 */
	OP_UCFIRST,	/* 120 */
	OP_LCFIRST,	/* 121 */
	OP_UC,		/* 122 */
	OP_LC,		/* 123 */
	OP_QUOTEMETA,	/* 124 */
	OP_RV2AV,	/* 125 */
	OP_AELEMFAST,	/* 126 */
	OP_AELEM,	/* 127 */
	OP_ASLICE,	/* 128 */
	OP_EACH,	/* 129 */
	OP_VALUES,	/* 130 */
	OP_KEYS,	/* 131 */
	OP_DELETE,	/* 132 */
	OP_EXISTS,	/* 133 */
	OP_RV2HV,	/* 134 */
	OP_HELEM,	/* 135 */
	OP_HSLICE,	/* 136 */
	OP_UNPACK,	/* 137 */
	OP_PACK,	/* 138 */
	OP_SPLIT,	/* 139 */
	OP_JOIN,	/* 140 */
	OP_LIST,	/* 141 */
	OP_LSLICE,	/* 142 */
	OP_ANONLIST,	/* 143 */
	OP_ANONHASH,	/* 144 */
	OP_SPLICE,	/* 145 */
	OP_PUSH,	/* 146 */
	OP_POP,		/* 147 */
	OP_SHIFT,	/* 148 */
	OP_UNSHIFT,	/* 149 */
	OP_SORT,	/* 150 */
	OP_REVERSE,	/* 151 */
	OP_GREPSTART,	/* 152 */
	OP_GREPWHILE,	/* 153 */
	OP_MAPSTART,	/* 154 */
	OP_MAPWHILE,	/* 155 */
	OP_RANGE,	/* 156 */
	OP_FLIP,	/* 157 */
	OP_FLOP,	/* 158 */
	OP_AND,		/* 159 */
	OP_OR,		/* 160 */
	OP_XOR,		/* 161 */
	OP_COND_EXPR,	/* 162 */
	OP_ANDASSIGN,	/* 163 */
	OP_ORASSIGN,	/* 164 */
	OP_METHOD,	/* 165 */
	OP_ENTERSUB,	/* 166 */
	OP_LEAVESUB,	/* 167 */
	OP_CALLER,	/* 168 */
	OP_WARN,	/* 169 */
	OP_DIE,		/* 170 */
	OP_RESET,	/* 171 */
	OP_LINESEQ,	/* 172 */
	OP_NEXTSTATE,	/* 173 */
	OP_DBSTATE,	/* 174 */
	OP_UNSTACK,	/* 175 */
	OP_ENTER,	/* 176 */
	OP_LEAVE,	/* 177 */
	OP_SCOPE,	/* 178 */
	OP_ENTERITER,	/* 179 */
	OP_ITER,	/* 180 */
	OP_ENTERLOOP,	/* 181 */
	OP_LEAVELOOP,	/* 182 */
	OP_RETURN,	/* 183 */
	OP_LAST,	/* 184 */
	OP_NEXT,	/* 185 */
	OP_REDO,	/* 186 */
	OP_DUMP,	/* 187 */
	OP_GOTO,	/* 188 */
	OP_EXIT,	/* 189 */
	OP_OPEN,	/* 190 */
	OP_CLOSE,	/* 191 */
	OP_PIPE_OP,	/* 192 */
	OP_FILENO,	/* 193 */
	OP_UMASK,	/* 194 */
	OP_BINMODE,	/* 195 */
	OP_TIE,		/* 196 */
	OP_UNTIE,	/* 197 */
	OP_TIED,	/* 198 */
	OP_DBMOPEN,	/* 199 */
	OP_DBMCLOSE,	/* 200 */
	OP_SSELECT,	/* 201 */
	OP_SELECT,	/* 202 */
	OP_GETC,	/* 203 */
	OP_READ,	/* 204 */
	OP_ENTERWRITE,	/* 205 */
	OP_LEAVEWRITE,	/* 206 */
	OP_PRTF,	/* 207 */
	OP_PRINT,	/* 208 */
	OP_SYSOPEN,	/* 209 */
	OP_SYSSEEK,	/* 210 */
	OP_SYSREAD,	/* 211 */
	OP_SYSWRITE,	/* 212 */
	OP_SEND,	/* 213 */
	OP_RECV,	/* 214 */
	OP_EOF,		/* 215 */
	OP_TELL,	/* 216 */
	OP_SEEK,	/* 217 */
	OP_TRUNCATE,	/* 218 */
	OP_FCNTL,	/* 219 */
	OP_IOCTL,	/* 220 */
	OP_FLOCK,	/* 221 */
	OP_SOCKET,	/* 222 */
	OP_SOCKPAIR,	/* 223 */
	OP_BIND,	/* 224 */
	OP_CONNECT,	/* 225 */
	OP_LISTEN,	/* 226 */
	OP_ACCEPT,	/* 227 */
	OP_SHUTDOWN,	/* 228 */
	OP_GSOCKOPT,	/* 229 */
	OP_SSOCKOPT,	/* 230 */
	OP_GETSOCKNAME,	/* 231 */
	OP_GETPEERNAME,	/* 232 */
	OP_LSTAT,	/* 233 */
	OP_STAT,	/* 234 */
	OP_FTRREAD,	/* 235 */
	OP_FTRWRITE,	/* 236 */
	OP_FTREXEC,	/* 237 */
	OP_FTEREAD,	/* 238 */
	OP_FTEWRITE,	/* 239 */
	OP_FTEEXEC,	/* 240 */
	OP_FTIS,	/* 241 */
	OP_FTEOWNED,	/* 242 */
	OP_FTROWNED,	/* 243 */
	OP_FTZERO,	/* 244 */
	OP_FTSIZE,	/* 245 */
	OP_FTMTIME,	/* 246 */
	OP_FTATIME,	/* 247 */
	OP_FTCTIME,	/* 248 */
	OP_FTSOCK,	/* 249 */
	OP_FTCHR,	/* 250 */
	OP_FTBLK,	/* 251 */
	OP_FTFILE,	/* 252 */
	OP_FTDIR,	/* 253 */
	OP_FTPIPE,	/* 254 */
	OP_FTLINK,	/* 255 */
	OP_FTSUID,	/* 256 */
	OP_FTSGID,	/* 257 */
	OP_FTSVTX,	/* 258 */
	OP_FTTTY,	/* 259 */
	OP_FTTEXT,	/* 260 */
	OP_FTBINARY,	/* 261 */
	OP_CHDIR,	/* 262 */
	OP_CHOWN,	/* 263 */
	OP_CHROOT,	/* 264 */
	OP_UNLINK,	/* 265 */
	OP_CHMOD,	/* 266 */
	OP_UTIME,	/* 267 */
	OP_RENAME,	/* 268 */
	OP_LINK,	/* 269 */
	OP_SYMLINK,	/* 270 */
	OP_READLINK,	/* 271 */
	OP_MKDIR,	/* 272 */
	OP_RMDIR,	/* 273 */
	OP_OPEN_DIR,	/* 274 */
	OP_READDIR,	/* 275 */
	OP_TELLDIR,	/* 276 */
	OP_SEEKDIR,	/* 277 */
	OP_REWINDDIR,	/* 278 */
	OP_CLOSEDIR,	/* 279 */
	OP_FORK,	/* 280 */
	OP_WAIT,	/* 281 */
	OP_WAITPID,	/* 282 */
	OP_SYSTEM,	/* 283 */
	OP_EXEC,	/* 284 */
	OP_KILL,	/* 285 */
	OP_GETPPID,	/* 286 */
	OP_GETPGRP,	/* 287 */
	OP_SETPGRP,	/* 288 */
	OP_GETPRIORITY,	/* 289 */
	OP_SETPRIORITY,	/* 290 */
	OP_TIME,	/* 291 */
	OP_TMS,		/* 292 */
	OP_LOCALTIME,	/* 293 */
	OP_GMTIME,	/* 294 */
	OP_ALARM,	/* 295 */
	OP_SLEEP,	/* 296 */
	OP_SHMGET,	/* 297 */
	OP_SHMCTL,	/* 298 */
	OP_SHMREAD,	/* 299 */
	OP_SHMWRITE,	/* 300 */
	OP_MSGGET,	/* 301 */
	OP_MSGCTL,	/* 302 */
	OP_MSGSND,	/* 303 */
	OP_MSGRCV,	/* 304 */
	OP_SEMGET,	/* 305 */
	OP_SEMCTL,	/* 306 */
	OP_SEMOP,	/* 307 */
	OP_REQUIRE,	/* 308 */
	OP_DOFILE,	/* 309 */
	OP_ENTEREVAL,	/* 310 */
	OP_LEAVEEVAL,	/* 311 */
	OP_ENTERTRY,	/* 312 */
	OP_LEAVETRY,	/* 313 */
	OP_GHBYNAME,	/* 314 */
	OP_GHBYADDR,	/* 315 */
	OP_GHOSTENT,	/* 316 */
	OP_GNBYNAME,	/* 317 */
	OP_GNBYADDR,	/* 318 */
	OP_GNETENT,	/* 319 */
	OP_GPBYNAME,	/* 320 */
	OP_GPBYNUMBER,	/* 321 */
	OP_GPROTOENT,	/* 322 */
	OP_GSBYNAME,	/* 323 */
	OP_GSBYPORT,	/* 324 */
	OP_GSERVENT,	/* 325 */
	OP_SHOSTENT,	/* 326 */
	OP_SNETENT,	/* 327 */
	OP_SPROTOENT,	/* 328 */
	OP_SSERVENT,	/* 329 */
	OP_EHOSTENT,	/* 330 */
	OP_ENETENT,	/* 331 */
	OP_EPROTOENT,	/* 332 */
	OP_ESERVENT,	/* 333 */
	OP_GPWNAM,	/* 334 */
	OP_GPWUID,	/* 335 */
	OP_GPWENT,	/* 336 */
	OP_SPWENT,	/* 337 */
	OP_EPWENT,	/* 338 */
	OP_GGRNAM,	/* 339 */
	OP_GGRGID,	/* 340 */
	OP_GGRENT,	/* 341 */
	OP_SGRENT,	/* 342 */
	OP_EGRENT,	/* 343 */
	OP_GETLOGIN,	/* 344 */
	OP_SYSCALL,	/* 345 */
	OP_LOCK,	/* 346 */
	OP_THREADSV,	/* 347 */
	OP_max		
} opcode;

#define MAXO 348


START_EXTERN_C

#ifndef DOINIT
EXT char *PL_op_name[];
#else
EXT char *PL_op_name[] = {
	"null",
	"stub",
	"scalar",
	"pushmark",
	"wantarray",
	"const",
	"gvsv",
	"gv",
	"gelem",
	"padsv",
	"padav",
	"padhv",
	"padany",
	"pushre",
	"rv2gv",
	"rv2sv",
	"av2arylen",
	"rv2cv",
	"anoncode",
	"prototype",
	"refgen",
	"srefgen",
	"ref",
	"bless",
	"backtick",
	"glob",
	"readline",
	"rcatline",
	"regcmaybe",
	"regcreset",
	"regcomp",
	"match",
	"qr",
	"subst",
	"substcont",
	"trans",
	"sassign",
	"aassign",
	"chop",
	"schop",
	"chomp",
	"schomp",
	"defined",
	"undef",
	"study",
	"pos",
	"preinc",
	"i_preinc",
	"predec",
	"i_predec",
	"postinc",
	"i_postinc",
	"postdec",
	"i_postdec",
	"pow",
	"multiply",
	"i_multiply",
	"divide",
	"i_divide",
	"modulo",
	"i_modulo",
	"repeat",
	"add",
	"i_add",
	"subtract",
	"i_subtract",
	"concat",
	"stringify",
	"left_shift",
	"right_shift",
	"lt",
	"i_lt",
	"gt",
	"i_gt",
	"le",
	"i_le",
	"ge",
	"i_ge",
	"eq",
	"i_eq",
	"ne",
	"i_ne",
	"ncmp",
	"i_ncmp",
	"slt",
	"sgt",
	"sle",
	"sge",
	"seq",
	"sne",
	"scmp",
	"bit_and",
	"bit_xor",
	"bit_or",
	"negate",
	"i_negate",
	"not",
	"complement",
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
	"ucfirst",
	"lcfirst",
	"uc",
	"lc",
	"quotemeta",
	"rv2av",
	"aelemfast",
	"aelem",
	"aslice",
	"each",
	"values",
	"keys",
	"delete",
	"exists",
	"rv2hv",
	"helem",
	"hslice",
	"unpack",
	"pack",
	"split",
	"join",
	"list",
	"lslice",
	"anonlist",
	"anonhash",
	"splice",
	"push",
	"pop",
	"shift",
	"unshift",
	"sort",
	"reverse",
	"grepstart",
	"grepwhile",
	"mapstart",
	"mapwhile",
	"range",
	"flip",
	"flop",
	"and",
	"or",
	"xor",
	"cond_expr",
	"andassign",
	"orassign",
	"method",
	"entersub",
	"leavesub",
	"caller",
	"warn",
	"die",
	"reset",
	"lineseq",
	"nextstate",
	"dbstate",
	"unstack",
	"enter",
	"leave",
	"scope",
	"enteriter",
	"iter",
	"enterloop",
	"leaveloop",
	"return",
	"last",
	"next",
	"redo",
	"dump",
	"goto",
	"exit",
	"open",
	"close",
	"pipe_op",
	"fileno",
	"umask",
	"binmode",
	"tie",
	"untie",
	"tied",
	"dbmopen",
	"dbmclose",
	"sselect",
	"select",
	"getc",
	"read",
	"enterwrite",
	"leavewrite",
	"prtf",
	"print",
	"sysopen",
	"sysseek",
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
	"sockpair",
	"bind",
	"connect",
	"listen",
	"accept",
	"shutdown",
	"gsockopt",
	"ssockopt",
	"getsockname",
	"getpeername",
	"lstat",
	"stat",
	"ftrread",
	"ftrwrite",
	"ftrexec",
	"fteread",
	"ftewrite",
	"fteexec",
	"ftis",
	"fteowned",
	"ftrowned",
	"ftzero",
	"ftsize",
	"ftmtime",
	"ftatime",
	"ftctime",
	"ftsock",
	"ftchr",
	"ftblk",
	"ftfile",
	"ftdir",
	"ftpipe",
	"ftlink",
	"ftsuid",
	"ftsgid",
	"ftsvtx",
	"fttty",
	"fttext",
	"ftbinary",
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
	"open_dir",
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
	"tms",
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
	"dofile",
	"entereval",
	"leaveeval",
	"entertry",
	"leavetry",
	"ghbyname",
	"ghbyaddr",
	"ghostent",
	"gnbyname",
	"gnbyaddr",
	"gnetent",
	"gpbyname",
	"gpbynumber",
	"gprotoent",
	"gsbyname",
	"gsbyport",
	"gservent",
	"shostent",
	"snetent",
	"sprotoent",
	"sservent",
	"ehostent",
	"enetent",
	"eprotoent",
	"eservent",
	"gpwnam",
	"gpwuid",
	"gpwent",
	"spwent",
	"epwent",
	"ggrnam",
	"ggrgid",
	"ggrent",
	"sgrent",
	"egrent",
	"getlogin",
	"syscall",
	"lock",
	"threadsv",
};
#endif

#ifndef DOINIT
EXT char *PL_op_desc[];
#else
EXT char *PL_op_desc[] = {
	"null operation",
	"stub",
	"scalar",
	"pushmark",
	"wantarray",
	"constant item",
	"scalar variable",
	"glob value",
	"glob elem",
	"private variable",
	"private array",
	"private hash",
	"private something",
	"push regexp",
	"ref-to-glob cast",
	"scalar deref",
	"array length",
	"subroutine deref",
	"anonymous subroutine",
	"subroutine prototype",
	"reference constructor",
	"single ref constructor",
	"reference-type operator",
	"bless",
	"backticks",
	"glob",
	"<HANDLE>",
	"append I/O operator",
	"regexp comp once",
	"regexp reset interpolation flag",
	"regexp compilation",
	"pattern match",
	"pattern quote",
	"substitution",
	"substitution cont",
	"character translation",
	"scalar assignment",
	"list assignment",
	"chop",
	"scalar chop",
	"safe chop",
	"scalar safe chop",
	"defined operator",
	"undef operator",
	"study",
	"match position",
	"preincrement",
	"integer preincrement",
	"predecrement",
	"integer predecrement",
	"postincrement",
	"integer postincrement",
	"postdecrement",
	"integer postdecrement",
	"exponentiation",
	"multiplication",
	"integer multiplication",
	"division",
	"integer division",
	"modulus",
	"integer modulus",
	"repeat",
	"addition",
	"integer addition",
	"subtraction",
	"integer subtraction",
	"concatenation",
	"string",
	"left bitshift",
	"right bitshift",
	"numeric lt",
	"integer lt",
	"numeric gt",
	"integer gt",
	"numeric le",
	"integer le",
	"numeric ge",
	"integer ge",
	"numeric eq",
	"integer eq",
	"numeric ne",
	"integer ne",
	"spaceship operator",
	"integer spaceship",
	"string lt",
	"string gt",
	"string le",
	"string ge",
	"string eq",
	"string ne",
	"string comparison",
	"bitwise and",
	"bitwise xor",
	"bitwise or",
	"negate",
	"integer negate",
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
	"quote metachars",
	"array deref",
	"known array element",
	"array element",
	"array slice",
	"each",
	"values",
	"keys",
	"delete",
	"exists operator",
	"hash deref",
	"hash elem",
	"hash slice",
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
	"map",
	"map iterator",
	"flipflop",
	"range (or flip)",
	"range (or flop)",
	"logical and",
	"logical or",
	"logical xor",
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
	"iteration finalizer",
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
	"open",
	"close",
	"pipe",
	"fileno",
	"umask",
	"binmode",
	"tie",
	"untie",
	"tied",
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
	"sysopen",
	"sysseek",
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
	"lock",
	"per-thread variable",
};
#endif

END_EXTERN_C


START_EXTERN_C

#ifndef DOINIT
EXT OP * (CPERLscope(*PL_ppaddr)[])(pTHX);
#else
EXT OP * (CPERLscope(*PL_ppaddr)[])(pTHX) = {
	Perl_pp_null,
	Perl_pp_stub,
	Perl_pp_scalar,
	Perl_pp_pushmark,
	Perl_pp_wantarray,
	Perl_pp_const,
	Perl_pp_gvsv,
	Perl_pp_gv,
	Perl_pp_gelem,
	Perl_pp_padsv,
	Perl_pp_padav,
	Perl_pp_padhv,
	Perl_pp_padany,
	Perl_pp_pushre,
	Perl_pp_rv2gv,
	Perl_pp_rv2sv,
	Perl_pp_av2arylen,
	Perl_pp_rv2cv,
	Perl_pp_anoncode,
	Perl_pp_prototype,
	Perl_pp_refgen,
	Perl_pp_srefgen,
	Perl_pp_ref,
	Perl_pp_bless,
	Perl_pp_backtick,
	Perl_pp_glob,
	Perl_pp_readline,
	Perl_pp_rcatline,
	Perl_pp_regcmaybe,
	Perl_pp_regcreset,
	Perl_pp_regcomp,
	Perl_pp_match,
	Perl_pp_qr,
	Perl_pp_subst,
	Perl_pp_substcont,
	Perl_pp_trans,
	Perl_pp_sassign,
	Perl_pp_aassign,
	Perl_pp_chop,
	Perl_pp_schop,
	Perl_pp_chomp,
	Perl_pp_schomp,
	Perl_pp_defined,
	Perl_pp_undef,
	Perl_pp_study,
	Perl_pp_pos,
	Perl_pp_preinc,
	Perl_pp_i_preinc,
	Perl_pp_predec,
	Perl_pp_i_predec,
	Perl_pp_postinc,
	Perl_pp_i_postinc,
	Perl_pp_postdec,
	Perl_pp_i_postdec,
	Perl_pp_pow,
	Perl_pp_multiply,
	Perl_pp_i_multiply,
	Perl_pp_divide,
	Perl_pp_i_divide,
	Perl_pp_modulo,
	Perl_pp_i_modulo,
	Perl_pp_repeat,
	Perl_pp_add,
	Perl_pp_i_add,
	Perl_pp_subtract,
	Perl_pp_i_subtract,
	Perl_pp_concat,
	Perl_pp_stringify,
	Perl_pp_left_shift,
	Perl_pp_right_shift,
	Perl_pp_lt,
	Perl_pp_i_lt,
	Perl_pp_gt,
	Perl_pp_i_gt,
	Perl_pp_le,
	Perl_pp_i_le,
	Perl_pp_ge,
	Perl_pp_i_ge,
	Perl_pp_eq,
	Perl_pp_i_eq,
	Perl_pp_ne,
	Perl_pp_i_ne,
	Perl_pp_ncmp,
	Perl_pp_i_ncmp,
	Perl_pp_slt,
	Perl_pp_sgt,
	Perl_pp_sle,
	Perl_pp_sge,
	Perl_pp_seq,
	Perl_pp_sne,
	Perl_pp_scmp,
	Perl_pp_bit_and,
	Perl_pp_bit_xor,
	Perl_pp_bit_or,
	Perl_pp_negate,
	Perl_pp_i_negate,
	Perl_pp_not,
	Perl_pp_complement,
	Perl_pp_atan2,
	Perl_pp_sin,
	Perl_pp_cos,
	Perl_pp_rand,
	Perl_pp_srand,
	Perl_pp_exp,
	Perl_pp_log,
	Perl_pp_sqrt,
	Perl_pp_int,
	Perl_pp_hex,
	Perl_pp_oct,
	Perl_pp_abs,
	Perl_pp_length,
	Perl_pp_substr,
	Perl_pp_vec,
	Perl_pp_index,
	Perl_pp_rindex,
	Perl_pp_sprintf,
	Perl_pp_formline,
	Perl_pp_ord,
	Perl_pp_chr,
	Perl_pp_crypt,
	Perl_pp_ucfirst,
	Perl_pp_lcfirst,
	Perl_pp_uc,
	Perl_pp_lc,
	Perl_pp_quotemeta,
	Perl_pp_rv2av,
	Perl_pp_aelemfast,
	Perl_pp_aelem,
	Perl_pp_aslice,
	Perl_pp_each,
	Perl_pp_values,
	Perl_pp_keys,
	Perl_pp_delete,
	Perl_pp_exists,
	Perl_pp_rv2hv,
	Perl_pp_helem,
	Perl_pp_hslice,
	Perl_pp_unpack,
	Perl_pp_pack,
	Perl_pp_split,
	Perl_pp_join,
	Perl_pp_list,
	Perl_pp_lslice,
	Perl_pp_anonlist,
	Perl_pp_anonhash,
	Perl_pp_splice,
	Perl_pp_push,
	Perl_pp_pop,
	Perl_pp_shift,
	Perl_pp_unshift,
	Perl_pp_sort,
	Perl_pp_reverse,
	Perl_pp_grepstart,
	Perl_pp_grepwhile,
	Perl_pp_mapstart,
	Perl_pp_mapwhile,
	Perl_pp_range,
	Perl_pp_flip,
	Perl_pp_flop,
	Perl_pp_and,
	Perl_pp_or,
	Perl_pp_xor,
	Perl_pp_cond_expr,
	Perl_pp_andassign,
	Perl_pp_orassign,
	Perl_pp_method,
	Perl_pp_entersub,
	Perl_pp_leavesub,
	Perl_pp_caller,
	Perl_pp_warn,
	Perl_pp_die,
	Perl_pp_reset,
	Perl_pp_lineseq,
	Perl_pp_nextstate,
	Perl_pp_dbstate,
	Perl_pp_unstack,
	Perl_pp_enter,
	Perl_pp_leave,
	Perl_pp_scope,
	Perl_pp_enteriter,
	Perl_pp_iter,
	Perl_pp_enterloop,
	Perl_pp_leaveloop,
	Perl_pp_return,
	Perl_pp_last,
	Perl_pp_next,
	Perl_pp_redo,
	Perl_pp_dump,
	Perl_pp_goto,
	Perl_pp_exit,
	Perl_pp_open,
	Perl_pp_close,
	Perl_pp_pipe_op,
	Perl_pp_fileno,
	Perl_pp_umask,
	Perl_pp_binmode,
	Perl_pp_tie,
	Perl_pp_untie,
	Perl_pp_tied,
	Perl_pp_dbmopen,
	Perl_pp_dbmclose,
	Perl_pp_sselect,
	Perl_pp_select,
	Perl_pp_getc,
	Perl_pp_read,
	Perl_pp_enterwrite,
	Perl_pp_leavewrite,
	Perl_pp_prtf,
	Perl_pp_print,
	Perl_pp_sysopen,
	Perl_pp_sysseek,
	Perl_pp_sysread,
	Perl_pp_syswrite,
	Perl_pp_send,
	Perl_pp_recv,
	Perl_pp_eof,
	Perl_pp_tell,
	Perl_pp_seek,
	Perl_pp_truncate,
	Perl_pp_fcntl,
	Perl_pp_ioctl,
	Perl_pp_flock,
	Perl_pp_socket,
	Perl_pp_sockpair,
	Perl_pp_bind,
	Perl_pp_connect,
	Perl_pp_listen,
	Perl_pp_accept,
	Perl_pp_shutdown,
	Perl_pp_gsockopt,
	Perl_pp_ssockopt,
	Perl_pp_getsockname,
	Perl_pp_getpeername,
	Perl_pp_lstat,
	Perl_pp_stat,
	Perl_pp_ftrread,
	Perl_pp_ftrwrite,
	Perl_pp_ftrexec,
	Perl_pp_fteread,
	Perl_pp_ftewrite,
	Perl_pp_fteexec,
	Perl_pp_ftis,
	Perl_pp_fteowned,
	Perl_pp_ftrowned,
	Perl_pp_ftzero,
	Perl_pp_ftsize,
	Perl_pp_ftmtime,
	Perl_pp_ftatime,
	Perl_pp_ftctime,
	Perl_pp_ftsock,
	Perl_pp_ftchr,
	Perl_pp_ftblk,
	Perl_pp_ftfile,
	Perl_pp_ftdir,
	Perl_pp_ftpipe,
	Perl_pp_ftlink,
	Perl_pp_ftsuid,
	Perl_pp_ftsgid,
	Perl_pp_ftsvtx,
	Perl_pp_fttty,
	Perl_pp_fttext,
	Perl_pp_ftbinary,
	Perl_pp_chdir,
	Perl_pp_chown,
	Perl_pp_chroot,
	Perl_pp_unlink,
	Perl_pp_chmod,
	Perl_pp_utime,
	Perl_pp_rename,
	Perl_pp_link,
	Perl_pp_symlink,
	Perl_pp_readlink,
	Perl_pp_mkdir,
	Perl_pp_rmdir,
	Perl_pp_open_dir,
	Perl_pp_readdir,
	Perl_pp_telldir,
	Perl_pp_seekdir,
	Perl_pp_rewinddir,
	Perl_pp_closedir,
	Perl_pp_fork,
	Perl_pp_wait,
	Perl_pp_waitpid,
	Perl_pp_system,
	Perl_pp_exec,
	Perl_pp_kill,
	Perl_pp_getppid,
	Perl_pp_getpgrp,
	Perl_pp_setpgrp,
	Perl_pp_getpriority,
	Perl_pp_setpriority,
	Perl_pp_time,
	Perl_pp_tms,
	Perl_pp_localtime,
	Perl_pp_gmtime,
	Perl_pp_alarm,
	Perl_pp_sleep,
	Perl_pp_shmget,
	Perl_pp_shmctl,
	Perl_pp_shmread,
	Perl_pp_shmwrite,
	Perl_pp_msgget,
	Perl_pp_msgctl,
	Perl_pp_msgsnd,
	Perl_pp_msgrcv,
	Perl_pp_semget,
	Perl_pp_semctl,
	Perl_pp_semop,
	Perl_pp_require,
	Perl_pp_dofile,
	Perl_pp_entereval,
	Perl_pp_leaveeval,
	Perl_pp_entertry,
	Perl_pp_leavetry,
	Perl_pp_ghbyname,
	Perl_pp_ghbyaddr,
	Perl_pp_ghostent,
	Perl_pp_gnbyname,
	Perl_pp_gnbyaddr,
	Perl_pp_gnetent,
	Perl_pp_gpbyname,
	Perl_pp_gpbynumber,
	Perl_pp_gprotoent,
	Perl_pp_gsbyname,
	Perl_pp_gsbyport,
	Perl_pp_gservent,
	Perl_pp_shostent,
	Perl_pp_snetent,
	Perl_pp_sprotoent,
	Perl_pp_sservent,
	Perl_pp_ehostent,
	Perl_pp_enetent,
	Perl_pp_eprotoent,
	Perl_pp_eservent,
	Perl_pp_gpwnam,
	Perl_pp_gpwuid,
	Perl_pp_gpwent,
	Perl_pp_spwent,
	Perl_pp_epwent,
	Perl_pp_ggrnam,
	Perl_pp_ggrgid,
	Perl_pp_ggrent,
	Perl_pp_sgrent,
	Perl_pp_egrent,
	Perl_pp_getlogin,
	Perl_pp_syscall,
	Perl_pp_lock,
	Perl_pp_threadsv,
};
#endif

#ifndef DOINIT
EXT OP * (CPERLscope(*PL_check)[]) (pTHX_ OP *op);
#else
EXT OP * (CPERLscope(*PL_check)[]) (pTHX_ OP *op) = {
	Perl_ck_null,	/* null */
	Perl_ck_null,	/* stub */
	Perl_ck_fun,	/* scalar */
	Perl_ck_null,	/* pushmark */
	Perl_ck_null,	/* wantarray */
	Perl_ck_svconst,/* const */
	Perl_ck_null,	/* gvsv */
	Perl_ck_null,	/* gv */
	Perl_ck_null,	/* gelem */
	Perl_ck_null,	/* padsv */
	Perl_ck_null,	/* padav */
	Perl_ck_null,	/* padhv */
	Perl_ck_null,	/* padany */
	Perl_ck_null,	/* pushre */
	Perl_ck_rvconst,/* rv2gv */
	Perl_ck_rvconst,/* rv2sv */
	Perl_ck_null,	/* av2arylen */
	Perl_ck_rvconst,/* rv2cv */
	Perl_ck_anoncode,/* anoncode */
	Perl_ck_null,	/* prototype */
	Perl_ck_spair,	/* refgen */
	Perl_ck_null,	/* srefgen */
	Perl_ck_fun,	/* ref */
	Perl_ck_fun,	/* bless */
	Perl_ck_null,	/* backtick */
	Perl_ck_glob,	/* glob */
	Perl_ck_null,	/* readline */
	Perl_ck_null,	/* rcatline */
	Perl_ck_fun,	/* regcmaybe */
	Perl_ck_fun,	/* regcreset */
	Perl_ck_null,	/* regcomp */
	Perl_ck_match,	/* match */
	Perl_ck_match,	/* qr */
	Perl_ck_null,	/* subst */
	Perl_ck_null,	/* substcont */
	Perl_ck_null,	/* trans */
	Perl_ck_null,	/* sassign */
	Perl_ck_null,	/* aassign */
	Perl_ck_spair,	/* chop */
	Perl_ck_null,	/* schop */
	Perl_ck_spair,	/* chomp */
	Perl_ck_null,	/* schomp */
	Perl_ck_defined,/* defined */
	Perl_ck_lfun,	/* undef */
	Perl_ck_fun,	/* study */
	Perl_ck_lfun,	/* pos */
	Perl_ck_lfun,	/* preinc */
	Perl_ck_lfun,	/* i_preinc */
	Perl_ck_lfun,	/* predec */
	Perl_ck_lfun,	/* i_predec */
	Perl_ck_lfun,	/* postinc */
	Perl_ck_lfun,	/* i_postinc */
	Perl_ck_lfun,	/* postdec */
	Perl_ck_lfun,	/* i_postdec */
	Perl_ck_null,	/* pow */
	Perl_ck_null,	/* multiply */
	Perl_ck_null,	/* i_multiply */
	Perl_ck_null,	/* divide */
	Perl_ck_null,	/* i_divide */
	Perl_ck_null,	/* modulo */
	Perl_ck_null,	/* i_modulo */
	Perl_ck_repeat,	/* repeat */
	Perl_ck_null,	/* add */
	Perl_ck_null,	/* i_add */
	Perl_ck_null,	/* subtract */
	Perl_ck_null,	/* i_subtract */
	Perl_ck_concat,	/* concat */
	Perl_ck_fun,	/* stringify */
	Perl_ck_bitop,	/* left_shift */
	Perl_ck_bitop,	/* right_shift */
	Perl_ck_null,	/* lt */
	Perl_ck_null,	/* i_lt */
	Perl_ck_null,	/* gt */
	Perl_ck_null,	/* i_gt */
	Perl_ck_null,	/* le */
	Perl_ck_null,	/* i_le */
	Perl_ck_null,	/* ge */
	Perl_ck_null,	/* i_ge */
	Perl_ck_null,	/* eq */
	Perl_ck_null,	/* i_eq */
	Perl_ck_null,	/* ne */
	Perl_ck_null,	/* i_ne */
	Perl_ck_null,	/* ncmp */
	Perl_ck_null,	/* i_ncmp */
	Perl_ck_scmp,	/* slt */
	Perl_ck_scmp,	/* sgt */
	Perl_ck_scmp,	/* sle */
	Perl_ck_scmp,	/* sge */
	Perl_ck_null,	/* seq */
	Perl_ck_null,	/* sne */
	Perl_ck_scmp,	/* scmp */
	Perl_ck_bitop,	/* bit_and */
	Perl_ck_bitop,	/* bit_xor */
	Perl_ck_bitop,	/* bit_or */
	Perl_ck_null,	/* negate */
	Perl_ck_null,	/* i_negate */
	Perl_ck_null,	/* not */
	Perl_ck_bitop,	/* complement */
	Perl_ck_fun,	/* atan2 */
	Perl_ck_fun,	/* sin */
	Perl_ck_fun,	/* cos */
	Perl_ck_fun,	/* rand */
	Perl_ck_fun,	/* srand */
	Perl_ck_fun,	/* exp */
	Perl_ck_fun,	/* log */
	Perl_ck_fun,	/* sqrt */
	Perl_ck_fun,	/* int */
	Perl_ck_fun,	/* hex */
	Perl_ck_fun,	/* oct */
	Perl_ck_fun,	/* abs */
	Perl_ck_lengthconst,/* length */
	Perl_ck_fun,	/* substr */
	Perl_ck_fun,	/* vec */
	Perl_ck_index,	/* index */
	Perl_ck_index,	/* rindex */
	Perl_ck_fun_locale,/* sprintf */
	Perl_ck_fun,	/* formline */
	Perl_ck_fun,	/* ord */
	Perl_ck_fun,	/* chr */
	Perl_ck_fun,	/* crypt */
	Perl_ck_fun_locale,/* ucfirst */
	Perl_ck_fun_locale,/* lcfirst */
	Perl_ck_fun_locale,/* uc */
	Perl_ck_fun_locale,/* lc */
	Perl_ck_fun,	/* quotemeta */
	Perl_ck_rvconst,/* rv2av */
	Perl_ck_null,	/* aelemfast */
	Perl_ck_null,	/* aelem */
	Perl_ck_null,	/* aslice */
	Perl_ck_fun,	/* each */
	Perl_ck_fun,	/* values */
	Perl_ck_fun,	/* keys */
	Perl_ck_delete,	/* delete */
	Perl_ck_exists,	/* exists */
	Perl_ck_rvconst,/* rv2hv */
	Perl_ck_null,	/* helem */
	Perl_ck_null,	/* hslice */
	Perl_ck_fun,	/* unpack */
	Perl_ck_fun,	/* pack */
	Perl_ck_split,	/* split */
	Perl_ck_fun,	/* join */
	Perl_ck_null,	/* list */
	Perl_ck_null,	/* lslice */
	Perl_ck_fun,	/* anonlist */
	Perl_ck_fun,	/* anonhash */
	Perl_ck_fun,	/* splice */
	Perl_ck_fun,	/* push */
	Perl_ck_shift,	/* pop */
	Perl_ck_shift,	/* shift */
	Perl_ck_fun,	/* unshift */
	Perl_ck_sort,	/* sort */
	Perl_ck_fun,	/* reverse */
	Perl_ck_grep,	/* grepstart */
	Perl_ck_null,	/* grepwhile */
	Perl_ck_grep,	/* mapstart */
	Perl_ck_null,	/* mapwhile */
	Perl_ck_null,	/* range */
	Perl_ck_null,	/* flip */
	Perl_ck_null,	/* flop */
	Perl_ck_null,	/* and */
	Perl_ck_null,	/* or */
	Perl_ck_null,	/* xor */
	Perl_ck_null,	/* cond_expr */
	Perl_ck_null,	/* andassign */
	Perl_ck_null,	/* orassign */
	Perl_ck_null,	/* method */
	Perl_ck_subr,	/* entersub */
	Perl_ck_null,	/* leavesub */
	Perl_ck_fun,	/* caller */
	Perl_ck_fun,	/* warn */
	Perl_ck_fun,	/* die */
	Perl_ck_fun,	/* reset */
	Perl_ck_null,	/* lineseq */
	Perl_ck_null,	/* nextstate */
	Perl_ck_null,	/* dbstate */
	Perl_ck_null,	/* unstack */
	Perl_ck_null,	/* enter */
	Perl_ck_null,	/* leave */
	Perl_ck_null,	/* scope */
	Perl_ck_null,	/* enteriter */
	Perl_ck_null,	/* iter */
	Perl_ck_null,	/* enterloop */
	Perl_ck_null,	/* leaveloop */
	Perl_ck_null,	/* return */
	Perl_ck_null,	/* last */
	Perl_ck_null,	/* next */
	Perl_ck_null,	/* redo */
	Perl_ck_null,	/* dump */
	Perl_ck_null,	/* goto */
	Perl_ck_fun,	/* exit */
	Perl_ck_fun,	/* open */
	Perl_ck_fun,	/* close */
	Perl_ck_fun,	/* pipe_op */
	Perl_ck_fun,	/* fileno */
	Perl_ck_fun,	/* umask */
	Perl_ck_fun,	/* binmode */
	Perl_ck_fun,	/* tie */
	Perl_ck_fun,	/* untie */
	Perl_ck_fun,	/* tied */
	Perl_ck_fun,	/* dbmopen */
	Perl_ck_fun,	/* dbmclose */
	Perl_ck_select,	/* sselect */
	Perl_ck_select,	/* select */
	Perl_ck_eof,	/* getc */
	Perl_ck_fun,	/* read */
	Perl_ck_fun,	/* enterwrite */
	Perl_ck_null,	/* leavewrite */
	Perl_ck_listiob,/* prtf */
	Perl_ck_listiob,/* print */
	Perl_ck_fun,	/* sysopen */
	Perl_ck_fun,	/* sysseek */
	Perl_ck_fun,	/* sysread */
	Perl_ck_fun,	/* syswrite */
	Perl_ck_fun,	/* send */
	Perl_ck_fun,	/* recv */
	Perl_ck_eof,	/* eof */
	Perl_ck_fun,	/* tell */
	Perl_ck_fun,	/* seek */
	Perl_ck_trunc,	/* truncate */
	Perl_ck_fun,	/* fcntl */
	Perl_ck_fun,	/* ioctl */
	Perl_ck_fun,	/* flock */
	Perl_ck_fun,	/* socket */
	Perl_ck_fun,	/* sockpair */
	Perl_ck_fun,	/* bind */
	Perl_ck_fun,	/* connect */
	Perl_ck_fun,	/* listen */
	Perl_ck_fun,	/* accept */
	Perl_ck_fun,	/* shutdown */
	Perl_ck_fun,	/* gsockopt */
	Perl_ck_fun,	/* ssockopt */
	Perl_ck_fun,	/* getsockname */
	Perl_ck_fun,	/* getpeername */
	Perl_ck_ftst,	/* lstat */
	Perl_ck_ftst,	/* stat */
	Perl_ck_ftst,	/* ftrread */
	Perl_ck_ftst,	/* ftrwrite */
	Perl_ck_ftst,	/* ftrexec */
	Perl_ck_ftst,	/* fteread */
	Perl_ck_ftst,	/* ftewrite */
	Perl_ck_ftst,	/* fteexec */
	Perl_ck_ftst,	/* ftis */
	Perl_ck_ftst,	/* fteowned */
	Perl_ck_ftst,	/* ftrowned */
	Perl_ck_ftst,	/* ftzero */
	Perl_ck_ftst,	/* ftsize */
	Perl_ck_ftst,	/* ftmtime */
	Perl_ck_ftst,	/* ftatime */
	Perl_ck_ftst,	/* ftctime */
	Perl_ck_ftst,	/* ftsock */
	Perl_ck_ftst,	/* ftchr */
	Perl_ck_ftst,	/* ftblk */
	Perl_ck_ftst,	/* ftfile */
	Perl_ck_ftst,	/* ftdir */
	Perl_ck_ftst,	/* ftpipe */
	Perl_ck_ftst,	/* ftlink */
	Perl_ck_ftst,	/* ftsuid */
	Perl_ck_ftst,	/* ftsgid */
	Perl_ck_ftst,	/* ftsvtx */
	Perl_ck_ftst,	/* fttty */
	Perl_ck_ftst,	/* fttext */
	Perl_ck_ftst,	/* ftbinary */
	Perl_ck_fun,	/* chdir */
	Perl_ck_fun,	/* chown */
	Perl_ck_fun,	/* chroot */
	Perl_ck_fun,	/* unlink */
	Perl_ck_fun,	/* chmod */
	Perl_ck_fun,	/* utime */
	Perl_ck_fun,	/* rename */
	Perl_ck_fun,	/* link */
	Perl_ck_fun,	/* symlink */
	Perl_ck_fun,	/* readlink */
	Perl_ck_fun,	/* mkdir */
	Perl_ck_fun,	/* rmdir */
	Perl_ck_fun,	/* open_dir */
	Perl_ck_fun,	/* readdir */
	Perl_ck_fun,	/* telldir */
	Perl_ck_fun,	/* seekdir */
	Perl_ck_fun,	/* rewinddir */
	Perl_ck_fun,	/* closedir */
	Perl_ck_null,	/* fork */
	Perl_ck_null,	/* wait */
	Perl_ck_fun,	/* waitpid */
	Perl_ck_exec,	/* system */
	Perl_ck_exec,	/* exec */
	Perl_ck_fun,	/* kill */
	Perl_ck_null,	/* getppid */
	Perl_ck_fun,	/* getpgrp */
	Perl_ck_fun,	/* setpgrp */
	Perl_ck_fun,	/* getpriority */
	Perl_ck_fun,	/* setpriority */
	Perl_ck_null,	/* time */
	Perl_ck_null,	/* tms */
	Perl_ck_fun,	/* localtime */
	Perl_ck_fun,	/* gmtime */
	Perl_ck_fun,	/* alarm */
	Perl_ck_fun,	/* sleep */
	Perl_ck_fun,	/* shmget */
	Perl_ck_fun,	/* shmctl */
	Perl_ck_fun,	/* shmread */
	Perl_ck_fun,	/* shmwrite */
	Perl_ck_fun,	/* msgget */
	Perl_ck_fun,	/* msgctl */
	Perl_ck_fun,	/* msgsnd */
	Perl_ck_fun,	/* msgrcv */
	Perl_ck_fun,	/* semget */
	Perl_ck_fun,	/* semctl */
	Perl_ck_fun,	/* semop */
	Perl_ck_require,/* require */
	Perl_ck_fun,	/* dofile */
	Perl_ck_eval,	/* entereval */
	Perl_ck_null,	/* leaveeval */
	Perl_ck_null,	/* entertry */
	Perl_ck_null,	/* leavetry */
	Perl_ck_fun,	/* ghbyname */
	Perl_ck_fun,	/* ghbyaddr */
	Perl_ck_null,	/* ghostent */
	Perl_ck_fun,	/* gnbyname */
	Perl_ck_fun,	/* gnbyaddr */
	Perl_ck_null,	/* gnetent */
	Perl_ck_fun,	/* gpbyname */
	Perl_ck_fun,	/* gpbynumber */
	Perl_ck_null,	/* gprotoent */
	Perl_ck_fun,	/* gsbyname */
	Perl_ck_fun,	/* gsbyport */
	Perl_ck_null,	/* gservent */
	Perl_ck_fun,	/* shostent */
	Perl_ck_fun,	/* snetent */
	Perl_ck_fun,	/* sprotoent */
	Perl_ck_fun,	/* sservent */
	Perl_ck_null,	/* ehostent */
	Perl_ck_null,	/* enetent */
	Perl_ck_null,	/* eprotoent */
	Perl_ck_null,	/* eservent */
	Perl_ck_fun,	/* gpwnam */
	Perl_ck_fun,	/* gpwuid */
	Perl_ck_null,	/* gpwent */
	Perl_ck_null,	/* spwent */
	Perl_ck_null,	/* epwent */
	Perl_ck_fun,	/* ggrnam */
	Perl_ck_fun,	/* ggrgid */
	Perl_ck_null,	/* ggrent */
	Perl_ck_null,	/* sgrent */
	Perl_ck_null,	/* egrent */
	Perl_ck_null,	/* getlogin */
	Perl_ck_fun,	/* syscall */
	Perl_ck_rfun,	/* lock */
	Perl_ck_null,	/* threadsv */
};
#endif

#ifndef DOINIT
EXT U32 PL_opargs[];
#else
EXT U32 PL_opargs[] = {
	0x00000000,	/* null */
	0x00000000,	/* stub */
	0x00001c04,	/* scalar */
	0x00000004,	/* pushmark */
	0x00000014,	/* wantarray */
	0x00000704,	/* const */
	0x00000844,	/* gvsv */
	0x00000844,	/* gv */
	0x00011240,	/* gelem */
	0x00000044,	/* padsv */
	0x00000040,	/* padav */
	0x00000040,	/* padhv */
	0x00000040,	/* padany */
	0x00000640,	/* pushre */
	0x00000144,	/* rv2gv */
	0x00000144,	/* rv2sv */
	0x00000114,	/* av2arylen */
	0x00000140,	/* rv2cv */
	0x00000700,	/* anoncode */
	0x00001c04,	/* prototype */
	0x00002101,	/* refgen */
	0x00001106,	/* srefgen */
	0x00009c8c,	/* ref */
	0x00091504,	/* bless */
	0x00000c08,	/* backtick */
	0x00099508,	/* glob */
	0x00000c08,	/* readline */
	0x00000c08,	/* rcatline */
	0x00001104,	/* regcmaybe */
	0x00001104,	/* regcreset */
	0x00001304,	/* regcomp */
	0x00000640,	/* match */
	0x00000604,	/* qr */
	0x00001654,	/* subst */
	0x00000354,	/* substcont */
	0x00001914,	/* trans */
	0x00000004,	/* sassign */
	0x00022208,	/* aassign */
	0x00002c0d,	/* chop */
	0x00009c8c,	/* schop */
	0x00002c0d,	/* chomp */
	0x00009c8c,	/* schomp */
	0x00009c94,	/* defined */
	0x00009c04,	/* undef */
	0x00009c84,	/* study */
	0x00009c8c,	/* pos */
	0x00001164,	/* preinc */
	0x00001154,	/* i_preinc */
	0x00001164,	/* predec */
	0x00001154,	/* i_predec */
	0x0000116c,	/* postinc */
	0x0000115c,	/* i_postinc */
	0x0000116c,	/* postdec */
	0x0000115c,	/* i_postdec */
	0x0001120e,	/* pow */
	0x0001122e,	/* multiply */
	0x0001121e,	/* i_multiply */
	0x0001122e,	/* divide */
	0x0001121e,	/* i_divide */
	0x0001123e,	/* modulo */
	0x0001121e,	/* i_modulo */
	0x00012209,	/* repeat */
	0x0001122e,	/* add */
	0x0001121e,	/* i_add */
	0x0001122e,	/* subtract */
	0x0001121e,	/* i_subtract */
	0x0001120e,	/* concat */
	0x0000150e,	/* stringify */
	0x0001120e,	/* left_shift */
	0x0001120e,	/* right_shift */
	0x00011236,	/* lt */
	0x00011216,	/* i_lt */
	0x00011236,	/* gt */
	0x00011216,	/* i_gt */
	0x00011236,	/* le */
	0x00011216,	/* i_le */
	0x00011236,	/* ge */
	0x00011216,	/* i_ge */
	0x00011236,	/* eq */
	0x00011216,	/* i_eq */
	0x00011236,	/* ne */
	0x00011216,	/* i_ne */
	0x0001123e,	/* ncmp */
	0x0001121e,	/* i_ncmp */
	0x00011216,	/* slt */
	0x00011216,	/* sgt */
	0x00011216,	/* sle */
	0x00011216,	/* sge */
	0x00011216,	/* seq */
	0x00011216,	/* sne */
	0x0001121e,	/* scmp */
	0x0001120e,	/* bit_and */
	0x0001120e,	/* bit_xor */
	0x0001120e,	/* bit_or */
	0x0000112e,	/* negate */
	0x0000111e,	/* i_negate */
	0x00001116,	/* not */
	0x0000110e,	/* complement */
	0x0001150e,	/* atan2 */
	0x00009c8e,	/* sin */
	0x00009c8e,	/* cos */
	0x00009c0c,	/* rand */
	0x00009c04,	/* srand */
	0x00009c8e,	/* exp */
	0x00009c8e,	/* log */
	0x00009c8e,	/* sqrt */
	0x00009c8e,	/* int */
	0x00009c8e,	/* hex */
	0x00009c8e,	/* oct */
	0x00009c8e,	/* abs */
	0x00009c9c,	/* length */
	0x0991150c,	/* substr */
	0x0011151c,	/* vec */
	0x0091151c,	/* index */
	0x0091151c,	/* rindex */
	0x0002150f,	/* sprintf */
	0x00021505,	/* formline */
	0x00009c9e,	/* ord */
	0x00009c8e,	/* chr */
	0x0001150e,	/* crypt */
	0x00009c8e,	/* ucfirst */
	0x00009c8e,	/* lcfirst */
	0x00009c8e,	/* uc */
	0x00009c8e,	/* lc */
	0x00009c8e,	/* quotemeta */
	0x00000148,	/* rv2av */
	0x00013804,	/* aelemfast */
	0x00013204,	/* aelem */
	0x00023501,	/* aslice */
	0x00004c08,	/* each */
	0x00004c08,	/* values */
	0x00004c08,	/* keys */
	0x00001c00,	/* delete */
	0x00001c14,	/* exists */
	0x00000148,	/* rv2hv */
	0x00014204,	/* helem */
	0x00024501,	/* hslice */
	0x00011500,	/* unpack */
	0x0002150d,	/* pack */
	0x00111508,	/* split */
	0x0002150d,	/* join */
	0x00002501,	/* list */
	0x00224200,	/* lslice */
	0x00002505,	/* anonlist */
	0x00002505,	/* anonhash */
	0x02993501,	/* splice */
	0x0002351d,	/* push */
	0x00003c04,	/* pop */
	0x00003c04,	/* shift */
	0x0002351d,	/* unshift */
	0x0002d501,	/* sort */
	0x00002509,	/* reverse */
	0x00025541,	/* grepstart */
	0x00000348,	/* grepwhile */
	0x00025541,	/* mapstart */
	0x00000348,	/* mapwhile */
	0x00011400,	/* range */
	0x00011100,	/* flip */
	0x00000100,	/* flop */
	0x00000300,	/* and */
	0x00000300,	/* or */
	0x00011306,	/* xor */
	0x00000440,	/* cond_expr */
	0x00000304,	/* andassign */
	0x00000304,	/* orassign */
	0x00000140,	/* method */
	0x00002149,	/* entersub */
	0x00000100,	/* leavesub */
	0x00009c08,	/* caller */
	0x0000251d,	/* warn */
	0x0000255d,	/* die */
	0x00009c14,	/* reset */
	0x00000500,	/* lineseq */
	0x00000b04,	/* nextstate */
	0x00000b04,	/* dbstate */
	0x00000004,	/* unstack */
	0x00000000,	/* enter */
	0x00000500,	/* leave */
	0x00000500,	/* scope */
	0x00000a40,	/* enteriter */
	0x00000000,	/* iter */
	0x00000a40,	/* enterloop */
	0x00000200,	/* leaveloop */
	0x00002541,	/* return */
	0x00000e44,	/* last */
	0x00000e44,	/* next */
	0x00000e44,	/* redo */
	0x00000e44,	/* dump */
	0x00000e44,	/* goto */
	0x00009c44,	/* exit */
	0x0009651c,	/* open */
	0x0000ec14,	/* close */
	0x00066514,	/* pipe_op */
	0x00006c1c,	/* fileno */
	0x00009c1c,	/* umask */
	0x00006c04,	/* binmode */
	0x00217555,	/* tie */
	0x00007c14,	/* untie */
	0x00007c04,	/* tied */
	0x00114514,	/* dbmopen */
	0x00004c14,	/* dbmclose */
	0x01111508,	/* sselect */
	0x0000e50c,	/* select */
	0x0000ec0c,	/* getc */
	0x0917651d,	/* read */
	0x0000ec54,	/* enterwrite */
	0x00000100,	/* leavewrite */
	0x0002e515,	/* prtf */
	0x0002e515,	/* print */
	0x09116504,	/* sysopen */
	0x00116504,	/* sysseek */
	0x0917651d,	/* sysread */
	0x0991651d,	/* syswrite */
	0x0911651d,	/* send */
	0x0117651d,	/* recv */
	0x0000ec14,	/* eof */
	0x0000ec0c,	/* tell */
	0x00116504,	/* seek */
	0x00011514,	/* truncate */
	0x0011650c,	/* fcntl */
	0x0011650c,	/* ioctl */
	0x0001651c,	/* flock */
	0x01116514,	/* socket */
	0x11166514,	/* sockpair */
	0x00016514,	/* bind */
	0x00016514,	/* connect */
	0x00016514,	/* listen */
	0x0006651c,	/* accept */
	0x0001651c,	/* shutdown */
	0x00116514,	/* gsockopt */
	0x01116514,	/* ssockopt */
	0x00006c14,	/* getsockname */
	0x00006c14,	/* getpeername */
	0x00006d80,	/* lstat */
	0x00006d80,	/* stat */
	0x00006d94,	/* ftrread */
	0x00006d94,	/* ftrwrite */
	0x00006d94,	/* ftrexec */
	0x00006d94,	/* fteread */
	0x00006d94,	/* ftewrite */
	0x00006d94,	/* fteexec */
	0x00006d94,	/* ftis */
	0x00006d94,	/* fteowned */
	0x00006d94,	/* ftrowned */
	0x00006d94,	/* ftzero */
	0x00006d9c,	/* ftsize */
	0x00006d8c,	/* ftmtime */
	0x00006d8c,	/* ftatime */
	0x00006d8c,	/* ftctime */
	0x00006d94,	/* ftsock */
	0x00006d94,	/* ftchr */
	0x00006d94,	/* ftblk */
	0x00006d94,	/* ftfile */
	0x00006d94,	/* ftdir */
	0x00006d94,	/* ftpipe */
	0x00006d94,	/* ftlink */
	0x00006d94,	/* ftsuid */
	0x00006d94,	/* ftsgid */
	0x00006d94,	/* ftsvtx */
	0x00006d14,	/* fttty */
	0x00006d94,	/* fttext */
	0x00006d94,	/* ftbinary */
	0x00009c1c,	/* chdir */
	0x0000251d,	/* chown */
	0x00009c9c,	/* chroot */
	0x0000259d,	/* unlink */
	0x0000251d,	/* chmod */
	0x0000251d,	/* utime */
	0x0001151c,	/* rename */
	0x0001151c,	/* link */
	0x0001151c,	/* symlink */
	0x00009c8c,	/* readlink */
	0x0001151c,	/* mkdir */
	0x00009c9c,	/* rmdir */
	0x00016514,	/* open_dir */
	0x00006c00,	/* readdir */
	0x00006c0c,	/* telldir */
	0x00016504,	/* seekdir */
	0x00006c04,	/* rewinddir */
	0x00006c14,	/* closedir */
	0x0000001c,	/* fork */
	0x0000001c,	/* wait */
	0x0001151c,	/* waitpid */
	0x0002951d,	/* system */
	0x0002955d,	/* exec */
	0x0000255d,	/* kill */
	0x0000001c,	/* getppid */
	0x00009c1c,	/* getpgrp */
	0x0009951c,	/* setpgrp */
	0x0001151c,	/* getpriority */
	0x0011151c,	/* setpriority */
	0x0000001c,	/* time */
	0x00000000,	/* tms */
	0x00009c08,	/* localtime */
	0x00009c08,	/* gmtime */
	0x00009c9c,	/* alarm */
	0x00009c1c,	/* sleep */
	0x0011151d,	/* shmget */
	0x0011151d,	/* shmctl */
	0x0111151d,	/* shmread */
	0x0111151d,	/* shmwrite */
	0x0001151d,	/* msgget */
	0x0011151d,	/* msgctl */
	0x0011151d,	/* msgsnd */
	0x1111151d,	/* msgrcv */
	0x0011151d,	/* semget */
	0x0111151d,	/* semctl */
	0x0001151d,	/* semop */
	0x00009cc0,	/* require */
	0x00001140,	/* dofile */
	0x00001c40,	/* entereval */
	0x00001100,	/* leaveeval */
	0x00000300,	/* entertry */
	0x00000500,	/* leavetry */
	0x00001c00,	/* ghbyname */
	0x00011500,	/* ghbyaddr */
	0x00000000,	/* ghostent */
	0x00001c00,	/* gnbyname */
	0x00011500,	/* gnbyaddr */
	0x00000000,	/* gnetent */
	0x00001c00,	/* gpbyname */
	0x00001500,	/* gpbynumber */
	0x00000000,	/* gprotoent */
	0x00011500,	/* gsbyname */
	0x00011500,	/* gsbyport */
	0x00000000,	/* gservent */
	0x00001c14,	/* shostent */
	0x00001c14,	/* snetent */
	0x00001c14,	/* sprotoent */
	0x00001c14,	/* sservent */
	0x00000014,	/* ehostent */
	0x00000014,	/* enetent */
	0x00000014,	/* eprotoent */
	0x00000014,	/* eservent */
	0x00001c00,	/* gpwnam */
	0x00001c00,	/* gpwuid */
	0x00000000,	/* gpwent */
	0x00000014,	/* spwent */
	0x00000014,	/* epwent */
	0x00001c00,	/* ggrnam */
	0x00001c00,	/* ggrgid */
	0x00000000,	/* ggrent */
	0x00000014,	/* sgrent */
	0x00000014,	/* egrent */
	0x0000000c,	/* getlogin */
	0x0002151d,	/* syscall */
	0x00001c04,	/* lock */
	0x00000044,	/* threadsv */
};
#endif

END_EXTERN_C
