/* $RCSfile: perl.h,v $$Revision: 4.1 $$Date: 92/08/07 18:25:56 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	perl.h,v $
 * Revision 4.1  92/08/07  18:25:56  lwall
 * 
 * Revision 4.0.1.6  92/06/08  14:55:10  lwall
 * patch20: added Atari ST portability
 * patch20: bcopy() and memcpy() now tested for overlap safety
 * patch20: Perl now distinguishes overlapped copies from non-overlapped
 * patch20: removed implicit int declarations on functions
 * 
 * Revision 4.0.1.5  91/11/11  16:41:07  lwall
 * patch19: uts wrongly defines S_ISDIR() et al
 * patch19: too many preprocessors can't expand a macro right in #if
 * patch19: added little-endian pack/unpack options
 * 
 * Revision 4.0.1.4  91/11/05  18:06:10  lwall
 * patch11: various portability fixes
 * patch11: added support for dbz
 * patch11: added some support for 64-bit integers
 * patch11: hex() didn't understand leading 0x
 * 
 * Revision 4.0.1.3  91/06/10  01:25:10  lwall
 * patch10: certain pattern optimizations were botched
 * 
 * Revision 4.0.1.2  91/06/07  11:28:33  lwall
 * patch4: new copyright notice
 * patch4: made some allowances for "semi-standard" C
 * patch4: many, many itty-bitty portability fixes
 * 
 * Revision 4.0.1.1  91/04/11  17:49:51  lwall
 * patch1: hopefully straightened out some of the Xenix mess
 * 
 * Revision 4.0  91/03/20  01:37:56  lwall
 * 4.0 baseline.
 * 
 */

#include "embed.h"

#define VOIDWANT 1
#ifdef __cplusplus
#include "config_c++.h"
#else
#include "config.h"
#endif

#ifndef BYTEORDER
#   define BYTEORDER 0x1234
#endif

/* Overall memory policy? */
#ifndef CONSERVATIVE
#   define LIBERAL 1
#endif

/*
 * The following contortions are brought to you on behalf of all the
 * standards, semi-standards, de facto standards, not-so-de-facto standards
 * of the world, as well as all the other botches anyone ever thought of.
 * The basic theory is that if we work hard enough here, the rest of the
 * code can be a lot prettier.  Well, so much for theory.  Sorry, Henry...
 */

#ifdef MYMALLOC
#   ifdef HIDEMYMALLOC
#	define malloc Mymalloc
#	define realloc Myremalloc
#	define free Myfree
#   endif
#   define safemalloc malloc
#   define saferealloc realloc
#   define safefree free
#endif

/* work around some libPW problems */
#ifdef DOINIT
char Error[1];
#endif

/* define this once if either system, instead of cluttering up the src */
#if defined(MSDOS) || defined(atarist)
#define DOSISH 1
#endif

#if defined(__STDC__) || defined(_AIX) || defined(__stdc__) || defined(__cplusplus)
# define STANDARD_C 1
#endif

#if defined(STANDARD_C)
#   define P(args) args
#else
#   define P(args) ()
#endif

#if defined(HASVOLATILE) || defined(STANDARD_C)
#   ifdef __cplusplus
#	define VOL		// to temporarily suppress warnings
#   else
#	define VOL volatile
#   endif
#else
#   define VOL
#endif

#define TAINT_IF(c)	(tainted |= (c))
#define TAINT_NOT	(tainted = 0)
#define TAINT_PROPER(s)	if (tainting) taint_proper(no_security, s)
#define TAINT_ENV()	if (tainting) taint_env()

#ifndef HAS_VFORK
#   define vfork fork
#endif

#ifdef HAS_GETPGRP2
#   ifndef HAS_GETPGRP
#	define HAS_GETPGRP
#   endif
#   define getpgrp getpgrp2
#endif

#ifdef HAS_SETPGRP2
#   ifndef HAS_SETPGRP
#	define HAS_SETPGRP
#   endif
#   define setpgrp setpgrp2
#endif

#include <stdio.h>
#include <ctype.h>
#include <setjmp.h>

#ifndef MSDOS
#   ifdef PARAM_NEEDS_TYPES
#	include <sys/types.h>
#   endif
#   include <sys/param.h>
#endif


/* Use all the "standard" definitions? */
#ifdef STANDARD_C
#   include <stdlib.h>
#   include <string.h>
#   define MEM_SIZE size_t
#else
    typedef unsigned int MEM_SIZE;
#endif /* STANDARD_C */

#if defined(HAS_MEMCMP) && defined(mips) && defined(ultrix)
#   undef HAS_MEMCMP
#endif

#ifdef HAS_MEMCPY
#  ifndef STANDARD_C
#    ifndef memcpy
	extern char * memcpy P((char*, char*, int));
#    endif
#  endif
#else
#   ifndef memcpy
#	ifdef HAS_BCOPY
#	    define memcpy(d,s,l) bcopy(s,d,l)
#	else
#	    define memcpy(d,s,l) my_bcopy(s,d,l)
#	endif
#   endif
#endif /* HAS_MEMCPY */

#ifdef HAS_MEMSET
#  ifndef STANDARD_C
#    ifndef memset
	extern char *memset P((char*, int, int));
#    endif
#  endif
#  define memzero(d,l) memset(d,0,l)
#else
#   ifndef memzero
#	ifdef HAS_BZERO
#	    define memzero(d,l) bzero(d,l)
#	else
#	    define memzero(d,l) my_bzero(d,l)
#	endif
#   endif
#endif /* HAS_MEMSET */

#ifdef HAS_MEMCMP
#  ifndef STANDARD_C
#    ifndef memcmp
	extern int memcmp P((char*, char*, int));
#    endif
#  endif
#else
#   ifndef memcmp
#	define memcmp(s1,s2,l) my_memcmp(s1,s2,l)
#   endif
#endif /* HAS_MEMCMP */

/* we prefer bcmp slightly for comparisons that don't care about ordering */
#ifndef HAS_BCMP
#   ifndef bcmp
#	define bcmp(s1,s2,l) memcmp(s1,s2,l)
#   endif
#endif /* HAS_BCMP */

#ifndef HAS_MEMMOVE
#   if defined(HAS_BCOPY) && defined(SAFE_BCOPY)
#	define memmove(d,s,l) bcopy(s,d,l)
#   else
#	if defined(HAS_MEMCPY) && defined(SAFE_MEMCPY)
#	    define memmove(d,s,l) memcpy(d,s,l)
#	else
#	    define memmove(d,s,l) my_bcopy(s,d,l)
#	endif
#   endif
#endif

#ifndef _TYPES_		/* If types.h defines this it's easy. */
#   ifndef major		/* Does everyone's types.h define this? */
#	include <sys/types.h>
#   endif
#endif

#ifdef I_NETINET_IN
#   include <netinet/in.h>
#endif

#include <sys/stat.h>

#if defined(uts) || defined(UTekV)
#   undef S_ISDIR
#   undef S_ISCHR
#   undef S_ISBLK
#   undef S_ISREG
#   undef S_ISFIFO
#   undef S_ISLNK
#   define S_ISDIR(P) (((P)&S_IFMT)==S_IFDIR)
#   define S_ISCHR(P) (((P)&S_IFMT)==S_IFCHR)
#   define S_ISBLK(P) (((P)&S_IFMT)==S_IFBLK)
#   define S_ISREG(P) (((P)&S_IFMT)==S_IFREG)
#   define S_ISFIFO(P) (((P)&S_IFMT)==S_IFIFO)
#   ifdef S_IFLNK
#	define S_ISLNK(P) (((P)&S_IFMT)==S_IFLNK)
#   endif
#endif

#ifdef I_TIME
#   include <time.h>
#endif

#ifdef I_SYS_TIME
#   ifdef SYSTIMEKERNEL
#	define KERNEL
#   endif
#   include <sys/time.h>
#   ifdef SYSTIMEKERNEL
#	undef KERNEL
#   endif
#endif

#ifndef MSDOS
#include <sys/times.h>
#endif

#if defined(HAS_STRERROR) && (!defined(HAS_MKDIR) || !defined(HAS_RMDIR))
#   undef HAS_STRERROR
#endif

#include <errno.h>
#ifndef MSDOS
#   ifndef errno
	extern int errno;     /* ANSI allows errno to be an lvalue expr */
#   endif
#endif

#ifndef strerror
#   ifdef HAS_STRERROR
	char *strerror P((int));
#   else
	extern int sys_nerr;
	extern char *sys_errlist[];
#       define strerror(e) \
		((e) < 0 || (e) >= sys_nerr ? "(unknown)" : sys_errlist[e])
#   endif
#endif

#ifdef I_SYSIOCTL
#   ifndef _IOCTL_
#	include <sys/ioctl.h>
#   endif
#endif

#if defined(mc300) || defined(mc500) || defined(mc700) || defined(mc6000)
#   ifdef HAS_SOCKETPAIR
#	undef HAS_SOCKETPAIR
#   endif
#   ifdef HAS_NDBM
#	undef HAS_NDBM
#   endif
#endif

#if INTSIZE == 2
#   define htoni htons
#   define ntohi ntohs
#else
#   define htoni htonl
#   define ntohi ntohl
#endif

#if defined(I_DIRENT)
#   include <dirent.h>
#   define DIRENT dirent
#else
#   ifdef I_SYS_NDIR
#	include <sys/ndir.h>
#	define DIRENT direct
#   else
#	ifdef I_SYS_DIR
#	    ifdef hp9000s500
#		include <ndir.h>	/* may be wrong in the future */
#	    else
#		include <sys/dir.h>
#	    endif
#	    define DIRENT direct
#	endif
#   endif
#endif

#ifdef FPUTS_BOTCH
/* work around botch in SunOS 4.0.1 and 4.0.2 */
#   ifndef fputs
#	define fputs(sv,fp) fprintf(fp,"%s",sv)
#   endif
#endif

/*
 * The following gobbledygook brought to you on behalf of __STDC__.
 * (I could just use #ifndef __STDC__, but this is more bulletproof
 * in the face of half-implementations.)
 */

#ifndef S_IFMT
#   ifdef _S_IFMT
#	define S_IFMT _S_IFMT
#   else
#	define S_IFMT 0170000
#   endif
#endif

#ifndef S_ISDIR
#   define S_ISDIR(m) ((m & S_IFMT) == S_IFDIR)
#endif

#ifndef S_ISCHR
#   define S_ISCHR(m) ((m & S_IFMT) == S_IFCHR)
#endif

#ifndef S_ISBLK
#   ifdef S_IFBLK
#	define S_ISBLK(m) ((m & S_IFMT) == S_IFBLK)
#   else
#	define S_ISBLK(m) (0)
#   endif
#endif

#ifndef S_ISREG
#   define S_ISREG(m) ((m & S_IFMT) == S_IFREG)
#endif

#ifndef S_ISFIFO
#   ifdef S_IFIFO
#	define S_ISFIFO(m) ((m & S_IFMT) == S_IFIFO)
#   else
#	define S_ISFIFO(m) (0)
#   endif
#endif

#ifndef S_ISLNK
#   ifdef _S_ISLNK
#	define S_ISLNK(m) _S_ISLNK(m)
#   else
#	ifdef _S_IFLNK
#	    define S_ISLNK(m) ((m & S_IFMT) == _S_IFLNK)
#	else
#	    ifdef S_IFLNK
#		define S_ISLNK(m) ((m & S_IFMT) == S_IFLNK)
#	    else
#		define S_ISLNK(m) (0)
#	    endif
#	endif
#   endif
#endif

#ifndef S_ISSOCK
#   ifdef _S_ISSOCK
#	define S_ISSOCK(m) _S_ISSOCK(m)
#   else
#	ifdef _S_IFSOCK
#	    define S_ISSOCK(m) ((m & S_IFMT) == _S_IFSOCK)
#	else
#	    ifdef S_IFSOCK
#		define S_ISSOCK(m) ((m & S_IFMT) == S_IFSOCK)
#	    else
#		define S_ISSOCK(m) (0)
#	    endif
#	endif
#   endif
#endif

#ifndef S_IRUSR
#   ifdef S_IREAD
#	define S_IRUSR S_IREAD
#	define S_IWUSR S_IWRITE
#	define S_IXUSR S_IEXEC
#   else
#	define S_IRUSR 0400
#	define S_IWUSR 0200
#	define S_IXUSR 0100
#   endif
#   define S_IRGRP (S_IRUSR>>3)
#   define S_IWGRP (S_IWUSR>>3)
#   define S_IXGRP (S_IXUSR>>3)
#   define S_IROTH (S_IRUSR>>6)
#   define S_IWOTH (S_IWUSR>>6)
#   define S_IXOTH (S_IXUSR>>6)
#endif

#ifndef S_ISUID
#   define S_ISUID 04000
#endif

#ifndef S_ISGID
#   define S_ISGID 02000
#endif

#ifdef ff_next
#   undef ff_next
#endif

#if defined(cray) || defined(gould) || defined(i860)
#   define SLOPPYDIVIDE
#endif

#if defined(cray) || defined(convex) || defined (uts) || BYTEORDER > 0xffff
#   define QUAD
#endif

#ifdef QUAD
#   ifdef cray
#	define quad int
#   else
#	if defined(convex) || defined (uts)
#	    define quad long long
#	else
#	    define quad long
#	endif
#   endif
#endif

#ifdef VOIDSIG
#   define VOIDRET void
#else
#   define VOIDRET int
#endif

#ifdef DOSISH
#   include "dosish.h"
#else
#   include "unixish.h"
#endif

#ifndef HAS_PAUSE
#define pause() sleep((32767<<16)+32767)
#endif

#ifndef IOCPARM_LEN
#   ifdef IOCPARM_MASK
	/* on BSDish systes we're safe */
#	define IOCPARM_LEN(x)  (((x) >> 16) & IOCPARM_MASK)
#   else
	/* otherwise guess at what's safe */
#	define IOCPARM_LEN(x)	256
#   endif
#endif

typedef MEM_SIZE STRLEN;

typedef struct op OP;
typedef struct cop COP;
typedef struct unop UNOP;
typedef struct binop BINOP;
typedef struct listop LISTOP;
typedef struct logop LOGOP;
typedef struct condop CONDOP;
typedef struct pmop PMOP;
typedef struct svop SVOP;
typedef struct gvop GVOP;
typedef struct pvop PVOP;
typedef struct cvop CVOP;
typedef struct loop LOOP;

typedef struct Outrec Outrec;
typedef struct lstring Lstring;
typedef struct interpreter PerlInterpreter;
typedef struct ff FF;
typedef struct io IO;
typedef struct sv SV;
typedef struct av AV;
typedef struct hv HV;
typedef struct cv CV;
typedef struct regexp REGEXP;
typedef struct gp GP;
typedef struct sv GV;
typedef struct context CONTEXT;
typedef struct block BLOCK;

typedef struct magic MAGIC;
typedef struct xpv XPV;
typedef struct xpviv XPVIV;
typedef struct xpvnv XPVNV;
typedef struct xpvmg XPVMG;
typedef struct xpvlv XPVLV;
typedef struct xpvav XPVAV;
typedef struct xpvhv XPVHV;
typedef struct xpvgv XPVGV;
typedef struct xpvcv XPVCV;
typedef struct xpvbm XPVBM;
typedef struct xpvfm XPVFM;
typedef struct mgvtbl MGVTBL;
typedef union any ANY;

#include "handy.h"
union any {
    void*	any_ptr;
    I32		any_i32;
};

#include "regexp.h"
#include "sv.h"
#include "util.h"
#include "form.h"
#include "gv.h"
#include "cv.h"
#include "opcode.h"
#include "op.h"
#include "cop.h"
#include "av.h"
#include "hv.h"
#include "mg.h"
#include "scope.h"

#if defined(iAPX286) || defined(M_I286) || defined(I80286)
#   define I286
#endif

#ifndef	STANDARD_C
#   ifdef CHARSPRINTF
	char *sprintf P((char *, ...));
#   else
	int sprintf P((char *, ...));
#   endif
#endif

#if defined(htonl) && !defined(HAS_HTONL)
#define HAS_HTONL
#endif
#if defined(htons) && !defined(HAS_HTONS)
#define HAS_HTONS
#endif
#if defined(ntohl) && !defined(HAS_NTOHL)
#define HAS_NTOHL
#endif
#if defined(ntohs) && !defined(HAS_NTOHS)
#define HAS_NTOHS
#endif
#ifndef HAS_HTONL
#if (BYTEORDER & 0xffff) != 0x4321
#define HAS_HTONS
#define HAS_HTONL
#define HAS_NTOHS
#define HAS_NTOHL
#define MYSWAP
#define htons my_swap
#define htonl my_htonl
#define ntohs my_swap
#define ntohl my_ntohl
#endif
#else
#if (BYTEORDER & 0xffff) == 0x4321
#undef HAS_HTONS
#undef HAS_HTONL
#undef HAS_NTOHS
#undef HAS_NTOHL
#endif
#endif

/*
 * Little-endian byte order functions - 'v' for 'VAX', or 'reVerse'.
 * -DWS
 */
#if BYTEORDER != 0x1234
# define HAS_VTOHL
# define HAS_VTOHS
# define HAS_HTOVL
# define HAS_HTOVS
# if BYTEORDER == 0x4321
#  define vtohl(x)	((((x)&0xFF)<<24)	\
			+(((x)>>24)&0xFF)	\
			+(((x)&0x0000FF00)<<8)	\
			+(((x)&0x00FF0000)>>8)	)
#  define vtohs(x)	((((x)&0xFF)<<8) + (((x)>>8)&0xFF))
#  define htovl(x)	vtohl(x)
#  define htovs(x)	vtohs(x)
# endif
	/* otherwise default to functions in util.c */
#endif

#ifdef CASTNEGFLOAT
#define U_S(what) ((U16)(what))
#define U_I(what) ((unsigned int)(what))
#define U_L(what) ((U32)(what))
#else
U32 cast_ulong P((double));
#define U_S(what) ((U16)cast_ulong(what))
#define U_I(what) ((unsigned int)cast_ulong(what))
#define U_L(what) (cast_ulong(what))
#endif

struct Outrec {
    I32		o_lines;
    char	*o_str;
    U32		o_len;
};

#ifndef MAXSYSFD
#   define MAXSYSFD 2
#endif

#ifndef DOSISH
#define TMPPATH "/tmp/perl-eXXXXXX"
#else
#define TMPPATH "plXXXXXX"
#endif /* MSDOS */

#ifndef __cplusplus
UIDTYPE getuid P(());
UIDTYPE geteuid P(());
GIDTYPE getgid P(());
GIDTYPE getegid P(());
#endif

#ifdef DEBUGGING
#define YYDEBUG 1
#define DEB(a)     			a
#define DEBUG(a)   if (debug)		a
#define DEBUG_p(a) if (debug & 1)	a
#define DEBUG_s(a) if (debug & 2)	a
#define DEBUG_l(a) if (debug & 4)	a
#define DEBUG_t(a) if (debug & 8)	a
#define DEBUG_o(a) if (debug & 16)	a
#define DEBUG_c(a) if (debug & 32)	a
#define DEBUG_P(a) if (debug & 64)	a
#define DEBUG_m(a) if (debug & 128)	a
#define DEBUG_f(a) if (debug & 256)	a
#define DEBUG_r(a) if (debug & 512)	a
#define DEBUG_x(a) if (debug & 1024)	a
#define DEBUG_u(a) if (debug & 2048)	a
#define DEBUG_L(a) if (debug & 4096)	a
#define DEBUG_H(a) if (debug & 8192)	a
#define DEBUG_X(a) if (debug & 16384)	a
#else
#define DEB(a)
#define DEBUG(a)
#define DEBUG_p(a)
#define DEBUG_s(a)
#define DEBUG_l(a)
#define DEBUG_t(a)
#define DEBUG_o(a)
#define DEBUG_c(a)
#define DEBUG_P(a)
#define DEBUG_m(a)
#define DEBUG_f(a)
#define DEBUG_r(a)
#define DEBUG_x(a)
#define DEBUG_u(a)
#define DEBUG_L(a)
#define DEBUG_H(a)
#define DEBUG_X(a)
#endif
#define YYMAXDEPTH 300

#define assert(what)	DEB( {						\
	if (!(what)) {							\
	    croak("Assertion failed: file \"%s\", line %d",		\
		__FILE__, __LINE__);					\
	    exit(1);							\
	}})

struct ufuncs {
    I32 (*uf_val)P((I32, SV*));
    I32 (*uf_set)P((I32, SV*));
    I32 uf_index;
};

/* Fix these up for __STDC__ */
char *mktemp P((char*));
double atof P((const char*));

#ifndef STANDARD_C
/* All of these are in stdlib.h or time.h for ANSI C */
long time();
struct tm *gmtime(), *localtime();
char *strchr(), *strrchr();
char *strcpy(), *strcat();
#endif /* ! STANDARD_C */


#ifdef I_MATH
#    include <math.h>
#else
#   ifdef __cplusplus
	extern "C" {
#   endif
	    double exp P((double));
	    double log P((double));
	    double sqrt P((double));
	    double modf P((double,int*));
	    double sin P((double));
	    double cos P((double));
	    double atan2 P((double,double));
	    double pow P((double,double));
#   ifdef __cplusplus
	};
#   endif
#endif


char *crypt P((const char*, const char*));
char *getenv P((const char*));
long lseek P((int,int,int));
char *getlogin P((void));

#ifdef EUNICE
#define UNLINK unlnk
int unlnk P((char*));
#else
#define UNLINK unlink
#endif

#ifndef HAS_SETREUID
#ifdef HAS_SETRESUID
#define setreuid(r,e) setresuid(r,e,-1)
#define HAS_SETREUID
#endif
#endif
#ifndef HAS_SETREGID
#ifdef HAS_SETRESGID
#define setregid(r,e) setresgid(r,e,-1)
#define HAS_SETREGID
#endif
#endif

#define SCAN_DEF 0
#define SCAN_TR 1
#define SCAN_REPL 2

#ifdef DEBUGGING
#define PAD_SV(po) pad_sv(po)
#else
#define PAD_SV(po) curpad[po]
#endif

/****************/
/* Truly global */
/****************/

/* global state */
EXT PerlInterpreter *curinterp;	/* currently running interpreter */
extern char **	environ;	/* environment variables supplied via exec */
EXT int		uid;		/* current real user id */
EXT int		euid;		/* current effective user id */
EXT int		gid;		/* current real group id */
EXT int		egid;		/* current effective group id */
EXT bool	nomemok;	/* let malloc context handle nomem */
EXT U32		an;		/* malloc sequence number */
EXT U32		cop_seqmax;	/* statement sequence number */
EXT U32		op_seqmax;	/* op sequence number */
EXT U32		sub_generation;	/* inc to force methods to be looked up again */
EXT char **	origenviron;
EXT U32		origalen;

/* Stack for currently executing thread--context switch must handle this.     */
EXT SV **	stack_base;	/* stack->array_ary */
EXT SV **	stack_sp;	/* stack pointer now */
EXT SV **	stack_max;	/* stack->array_ary + stack->array_max */

/* likewise for these */

EXT OP *	op;		/* current op--oughta be in a global register */

EXT I32 *	scopestack;	/* blocks we've entered */
EXT I32		scopestack_ix;
EXT I32		scopestack_max;

EXT ANY*	savestack;	/* to save non-local values on */
EXT I32		savestack_ix;
EXT I32		savestack_max;

EXT OP **	retstack;	/* returns we've pushed */
EXT I32		retstack_ix;
EXT I32		retstack_max;

EXT I32 *	markstack;	/* stackmarks we're remembering */
EXT I32 *	markstack_ptr;	/* stackmarks we're remembering */
EXT I32 *	markstack_max;	/* stackmarks we're remembering */

EXT SV **	curpad;

/* temp space */
EXT SV *	Sv;
EXT XPV *	Xpv;
EXT char	buf[1024];
EXT char	tokenbuf[256];
EXT struct stat	statbuf;
#ifndef MSDOS
EXT struct tms	timesbuf;
#endif
EXT STRLEN na;		/* for use in SvPV when length is Not Applicable */

/* for tmp use in stupid debuggers */
EXT int *	di;
EXT short *	ds;
EXT char *	dc;

/* handy constants */
EXT char *	Yes INIT("1");
EXT char *	No INIT("");
EXT char *	hexdigit INIT("0123456789abcdef0123456789ABCDEFx");
EXT char *	patleave INIT("\\.^$@dDwWsSbB+*?|()-nrtfeaxc0123456789[{]}");
EXT char *	vert INIT("|");

EXT char	warn_nosemi[]
  INIT("Semicolon seems to be missing");
EXT char	warn_reserved[]
  INIT("Unquoted string \"%s\" may clash with future reserved word");
EXT char	warn_nl[]
  INIT("Unsuccessful %s on filename containing newline");
EXT char	no_usym[]
  INIT("Can't use an undefined value to create a symbol");
EXT char	no_aelem[]
  INIT("Modification of non-creatable array value attempted, subscript %d");
EXT char	no_helem[]
  INIT("Modification of non-creatable hash value attempted, subscript \"%s\"");
EXT char	no_modify[]
  INIT("Modification of a read-only value attempted");
EXT char	no_mem[]
  INIT("Out of memory!\n");
EXT char	no_security[]
  INIT("Insecure dependency in %s%s");
EXT char	no_sock_func[]
  INIT("Unsupported socket function \"%s\" called");
EXT char	no_dir_func[]
  INIT("Unsupported directory function \"%s\" called");
EXT char	no_func[]
  INIT("The %s function is unimplemented");

EXT SV		sv_undef;
EXT SV		sv_no;
EXT SV		sv_yes;
#ifdef CSH
    EXT char *	cshname INIT(CSH);
    EXT I32	cshlen;
#endif

#ifdef DOINIT
EXT char *sig_name[] = {
    SIG_NAME,0
};
#else
EXT char *sig_name[];
#endif

#ifdef DOINIT
EXT unsigned char fold[] = {	/* fast case folding table */
	0,	1,	2,	3,	4,	5,	6,	7,
	8,	9,	10,	11,	12,	13,	14,	15,
	16,	17,	18,	19,	20,	21,	22,	23,
	24,	25,	26,	27,	28,	29,	30,	31,
	32,	33,	34,	35,	36,	37,	38,	39,
	40,	41,	42,	43,	44,	45,	46,	47,
	48,	49,	50,	51,	52,	53,	54,	55,
	56,	57,	58,	59,	60,	61,	62,	63,
	64,	'a',	'b',	'c',	'd',	'e',	'f',	'g',
	'h',	'i',	'j',	'k',	'l',	'm',	'n',	'o',
	'p',	'q',	'r',	's',	't',	'u',	'v',	'w',
	'x',	'y',	'z',	91,	92,	93,	94,	95,
	96,	'A',	'B',	'C',	'D',	'E',	'F',	'G',
	'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O',
	'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W',
	'X',	'Y',	'Z',	123,	124,	125,	126,	127,
	128,	129,	130,	131,	132,	133,	134,	135,
	136,	137,	138,	139,	140,	141,	142,	143,
	144,	145,	146,	147,	148,	149,	150,	151,
	152,	153,	154,	155,	156,	157,	158,	159,
	160,	161,	162,	163,	164,	165,	166,	167,
	168,	169,	170,	171,	172,	173,	174,	175,
	176,	177,	178,	179,	180,	181,	182,	183,
	184,	185,	186,	187,	188,	189,	190,	191,
	192,	193,	194,	195,	196,	197,	198,	199,
	200,	201,	202,	203,	204,	205,	206,	207,
	208,	209,	210,	211,	212,	213,	214,	215,
	216,	217,	218,	219,	220,	221,	222,	223,	
	224,	225,	226,	227,	228,	229,	230,	231,
	232,	233,	234,	235,	236,	237,	238,	239,
	240,	241,	242,	243,	244,	245,	246,	247,
	248,	249,	250,	251,	252,	253,	254,	255
};
#else
EXT unsigned char fold[];
#endif

#ifdef DOINIT
EXT unsigned char freq[] = {	/* letter frequencies for mixed English/C */
	1,	2,	84,	151,	154,	155,	156,	157,
	165,	246,	250,	3,	158,	7,	18,	29,
	40,	51,	62,	73,	85,	96,	107,	118,
	129,	140,	147,	148,	149,	150,	152,	153,
	255,	182,	224,	205,	174,	176,	180,	217,
	233,	232,	236,	187,	235,	228,	234,	226,
	222,	219,	211,	195,	188,	193,	185,	184,
	191,	183,	201,	229,	181,	220,	194,	162,
	163,	208,	186,	202,	200,	218,	198,	179,
	178,	214,	166,	170,	207,	199,	209,	206,
	204,	160,	212,	216,	215,	192,	175,	173,
	243,	172,	161,	190,	203,	189,	164,	230,
	167,	248,	227,	244,	242,	255,	241,	231,
	240,	253,	169,	210,	245,	237,	249,	247,
	239,	168,	252,	251,	254,	238,	223,	221,
	213,	225,	177,	197,	171,	196,	159,	4,
	5,	6,	8,	9,	10,	11,	12,	13,
	14,	15,	16,	17,	19,	20,	21,	22,
	23,	24,	25,	26,	27,	28,	30,	31,
	32,	33,	34,	35,	36,	37,	38,	39,
	41,	42,	43,	44,	45,	46,	47,	48,
	49,	50,	52,	53,	54,	55,	56,	57,
	58,	59,	60,	61,	63,	64,	65,	66,
	67,	68,	69,	70,	71,	72,	74,	75,
	76,	77,	78,	79,	80,	81,	82,	83,
	86,	87,	88,	89,	90,	91,	92,	93,
	94,	95,	97,	98,	99,	100,	101,	102,
	103,	104,	105,	106,	108,	109,	110,	111,
	112,	113,	114,	115,	116,	117,	119,	120,
	121,	122,	123,	124,	125,	126,	127,	128,
	130,	131,	132,	133,	134,	135,	136,	137,
	138,	139,	141,	142,	143,	144,	145,	146
};
#else
EXT unsigned char freq[];
#endif

/*****************************************************************************/
/* This lexer/parser stuff is currently global since yacc is hard to reenter */
/*****************************************************************************/

typedef enum {
    XOPERATOR,
    XTERM,
    XBLOCK,
    XREF,
} expectation;

EXT FILE * VOL	rsfp INIT(Nullfp);
EXT SV *	linestr;
EXT char *	bufptr;
EXT char *	oldbufptr;
EXT char *	oldoldbufptr;
EXT char *	bufend;
EXT expectation expect INIT(XBLOCK);	/* how to interpret ambiguous tokens */

EXT I32		multi_start;	/* 1st line of multi-line string */
EXT I32		multi_end;	/* last line of multi-line string */
EXT I32		multi_open;	/* delimiter of said string */
EXT I32		multi_close;	/* delimiter of said string */

EXT GV *	scrgv;
EXT I32		error_count;	/* how many errors so far, max 10 */
EXT I32		subline;	/* line this subroutine began on */
EXT SV *	subname;	/* name of current subroutine */

EXT AV *	comppad;	/* storage for lexically scoped temporaries */
EXT AV *	comppadname;	/* variable names for "my" variables */
EXT I32		comppadnamefill;/* last "introduced" variable offset */
EXT I32		padix;		/* max used index in current "register" pad */
EXT COP		compiling;

EXT SV *	evstr;		/* op_fold_const() temp string cache */
EXT I32		thisexpr;	/* name id for nothing_in_common() */
EXT char *	last_uni;	/* position of last named-unary operator */
EXT char *	last_lop;	/* position of last list operator */
EXT bool	in_format;	/* we're compiling a run_format */
EXT bool	in_my;		/* we're compiling a "my" declaration */
EXT I32		needblockscope INIT(TRUE);	/* block overhead needed? */
#ifdef FCRYPT
EXT I32		cryptseen;	/* has fast crypt() been initialized? */
#endif

/**************************************************************************/
/* This regexp stuff is global since it always happens within 1 expr eval */
/**************************************************************************/

EXT char *	regprecomp;	/* uncompiled string. */
EXT char *	regparse;	/* Input-scan pointer. */
EXT char *	regxend;	/* End of input for compile */
EXT I32		regnpar;	/* () count. */
EXT char *	regcode;	/* Code-emit pointer; &regdummy = don't. */
EXT I32		regsize;	/* Code size. */
EXT I32		regfold;	/* are we folding? */
EXT I32		regsawbracket;	/* Did we do {d,d} trick? */
EXT I32		regsawback;	/* Did we see \1, ...? */

EXT char *	reginput;	/* String-input pointer. */
EXT char	regprev;	/* char before regbol, \n if none */
EXT char *	regbol;		/* Beginning of input, for ^ check. */
EXT char *	regeol;		/* End of input, for $ check. */
EXT char **	regstartp;	/* Pointer to startp array. */
EXT char **	regendp;	/* Ditto for endp. */
EXT char *	reglastparen;	/* Similarly for lastparen. */
EXT char *	regtill;	/* How far we are required to go. */
EXT I32		regmyp_size;
EXT char **	regmystartp;
EXT char **	regmyendp;

/***********************************************/
/* Global only to current interpreter instance */
/***********************************************/

#ifdef EMBEDDED
#define IEXT
#define IINIT(x)
struct interpreter {
#else
#define IEXT EXT
#define IINIT(x) INIT(x)
#endif

/* pseudo environmental stuff */
IEXT int	Iorigargc;
IEXT char **	Iorigargv;
IEXT GV *	Ienvgv;
IEXT GV *	Isiggv;
IEXT GV *	Iincgv;
IEXT char *	Iorigfilename;

/* switches */
IEXT char *	Icddir;
IEXT bool	Iminus_c;
IEXT char	Ipatchlevel[6];
IEXT char *	Inrs IINIT("\n");
IEXT U32	Inrschar IINIT('\n');   /* final char of rs, or 0777 if none */
IEXT I32	Inrslen IINIT(1);
IEXT bool	Ipreprocess;
IEXT bool	Iminus_n;
IEXT bool	Iminus_p;
IEXT bool	Iminus_l;
IEXT bool	Iminus_a;
IEXT bool	Idoswitches;
IEXT bool	Idowarn;
IEXT bool	Idoextract;
IEXT bool	Isawampersand;	/* must save all match strings */
IEXT bool	Isawstudy;	/* do fbm_instr on all strings */
IEXT bool	Isawi;		/* study must assume case insensitive */
IEXT bool	Isawvec;
IEXT bool	Iunsafe;
IEXT bool	Ido_undump;		/* -u or dump seen? */
IEXT char *	Iinplace;
IEXT char *	Ie_tmpname;
IEXT FILE *	Ie_fp;
IEXT VOL U32	Idebug;
IEXT U32	Iperldb;

/* magical thingies */
IEXT time_t	Ibasetime;		/* $^T */
IEXT I32	Iarybase;		/* $[ */
IEXT SV *	Iformfeed;		/* $^L */
IEXT char *	Ichopset IINIT(" \n-");	/* $: */
IEXT char *	Irs IINIT("\n");	/* $/ */
IEXT U32	Irschar IINIT('\n');	/* final char of rs, or 0777 if none */
IEXT I32	Irslen IINIT(1);
IEXT bool	Irspara;
IEXT char *	Iofs;			/* $, */
IEXT I32	Iofslen;
IEXT char *	Iors;			/* $\ */
IEXT I32	Iorslen;
IEXT char *	Iofmt;			/* $# */
IEXT I32	Imaxsysfd IINIT(MAXSYSFD); /* top fd to pass to subprocesses */
IEXT int	Imultiline;	  /* $*--do strings hold >1 line? */
IEXT U16	Istatusvalue;	/* $? */

IEXT struct stat Istatcache;		/* _ */
IEXT GV *	Istatgv;
IEXT SV *	Istatname IINIT(Nullsv);

/* shortcuts to various I/O objects */
IEXT GV *	Istdingv;
IEXT GV *	Ilast_in_gv;
IEXT GV *	Idefgv;
IEXT GV *	Iargvgv;
IEXT GV *	Idefoutgv;
IEXT GV *	Icuroutgv;
IEXT GV *	Iargvoutgv;

/* shortcuts to regexp stuff */
IEXT GV *	Ileftgv;
IEXT GV *	Iampergv;
IEXT GV *	Irightgv;
IEXT PMOP *	Icurpm;		/* what to do \ interps from */
IEXT I32 *	Iscreamfirst;
IEXT I32 *	Iscreamnext;
IEXT I32	Imaxscream IINIT(-1);
IEXT SV *	Ilastscream;

/* shortcuts to debugging objects */
IEXT GV *	IDBgv;
IEXT GV *	IDBline;
IEXT GV *	IDBsub;
IEXT SV *	IDBsingle;
IEXT SV *	IDBtrace;
IEXT SV *	IDBsignal;
IEXT AV *	Ilineary;	/* lines of script for debugger */
IEXT AV *	Idbargs;	/* args to call listed by caller function */

/* symbol tables */
IEXT HV *	Idefstash;	/* main symbol table */
IEXT HV *	Icurstash;	/* symbol table for current package */
IEXT HV *	Idebstash;	/* symbol table for perldb package */
IEXT SV *	Icurstname;	/* name of current package */
IEXT AV *	Ibeginav;	/* names of BEGIN subroutines */
IEXT AV *	Iendav;		/* names of END subroutines */
IEXT AV *	Ipad;		/* storage for lexically scoped temporaries */
IEXT AV *	Ipadname;	/* variable names for "my" variables */

/* memory management */
IEXT SV *	Ifreestrroot;
IEXT SV **	Itmps_stack;
IEXT I32	Itmps_ix IINIT(-1);
IEXT I32	Itmps_floor IINIT(-1);
IEXT I32	Itmps_max IINIT(-1);

/* funky return mechanisms */
IEXT I32	Ilastspbase;
IEXT I32	Ilastsize;
IEXT int	Iforkprocess;	/* so do_open |- can return proc# */

/* subprocess state */
IEXT AV *	Ifdpid;		/* keep fd-to-pid mappings for my_popen */
IEXT HV *	Ipidstatus;	/* keep pid-to-status mappings for waitpid */

/* internal state */
IEXT VOL int	Iin_eval;	/* trap "fatal" errors? */
IEXT OP *	Irestartop;	/* Are we propagating an error from croak? */
IEXT int	Idelaymagic;	/* ($<,$>) = ... */
IEXT bool	Idirty;		/* clean before rerunning */
IEXT bool	Ilocalizing;	/* are we processing a local() list? */
IEXT bool	Itainted;	/* using variables controlled by $< */
IEXT bool	Itainting;	/* doing taint checks */

/* trace state */
IEXT I32	Idlevel;
IEXT I32	Idlmax IINIT(128);
IEXT char *	Idebname;
IEXT char *	Idebdelim;

/* current interpreter roots */
IEXT OP *	Imain_root;
IEXT OP *	Imain_start;
IEXT OP *	Ieval_root;
IEXT OP *	Ieval_start;

/* runtime control stuff */
IEXT COP * VOL	Icurcop IINIT(&compiling);
IEXT line_t	Icopline IINIT(NOLINE);
IEXT CONTEXT *	Icxstack;
IEXT I32	Icxstack_ix IINIT(-1);
IEXT I32	Icxstack_max IINIT(128);
IEXT jmp_buf	Itop_env;

/* stack stuff */
IEXT AV *	Istack;		/* THE STACK */
IEXT AV *	Imainstack;	/* the stack when nothing funny is happening */
IEXT SV **	Imystack_base;	/* stack->array_ary */
IEXT SV **	Imystack_sp;	/* stack pointer now */
IEXT SV **	Imystack_max;	/* stack->array_ary + stack->array_max */

/* format accumulators */
IEXT SV *	Iformtarget;
IEXT SV *	Ibodytarget;
IEXT SV *	Itoptarget;

/* statics moved here for shared library purposes */
IEXT SV		Istrchop;	/* return value from chop */
IEXT int	Ifilemode;	/* so nextargv() can preserve mode */
IEXT int	Ilastfd;	/* what to preserve mode on */
IEXT char *	Ioldname;	/* what to preserve mode on */
IEXT char **	IArgv;		/* stuff to free from do_aexec, vfork safe */
IEXT char *	ICmd;		/* stuff to free from do_aexec, vfork safe */
IEXT OP *	Isortcop;	/* user defined sort routine */
IEXT HV *	Isortstash;	/* which is in some package or other */
IEXT GV *	Ifirstgv;	/* $a */
IEXT GV *	Isecondgv;	/* $b */
IEXT AV *	Isortstack;	/* temp stack during pp_sort() */
IEXT AV *	Isignalstack;	/* temp stack during sighandler() */
IEXT SV *	Imystrk;	/* temp key string for do_each() */
IEXT I32	Idumplvl;	/* indentation level on syntax tree dump */
IEXT PMOP *	Ioldlastpm;	/* for saving regexp context during debugger */
IEXT I32	Igensym;	/* next symbol for getsym() to define */
IEXT bool	Ipreambled;
IEXT int	Ilaststatval IINIT(-1);
IEXT I32	Ilaststype IINIT(OP_STAT);

#undef IEXT
#undef IINIT

#ifdef EMBEDDED
};
#else
struct interpreter {
    char broiled;
};
#endif

#include "pp.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "proto.h"

#ifdef __cplusplus
};
#endif

/* The following must follow proto.h */

#ifdef DOINIT
MGVTBL vtbl_sv =	{magic_get,
				magic_set,
					magic_len,
						0,	0};
MGVTBL vtbl_env =	{0,	0,	0,	0,	0};
MGVTBL vtbl_envelem =	{0,	magic_setenv,
					0,	0,	0};
MGVTBL vtbl_sig =	{0,	0,		 0, 0, 0};
MGVTBL vtbl_sigelem =	{0,	magic_setsig,
					0,	0,	0};
MGVTBL vtbl_pack =	{0,	0,
					0,	0,	0};
MGVTBL vtbl_packelem =	{magic_getpack,
				magic_setpack,
					0,	magic_clearpack,
							0};
MGVTBL vtbl_dbline =	{0,	magic_setdbline,
					0,	0,	0};
MGVTBL vtbl_isa =	{0,	magic_setisa,
					0,	0,	0};
MGVTBL vtbl_isaelem =	{0,	magic_setisa,
					0,	0,	0};
MGVTBL vtbl_arylen =	{magic_getarylen,
				magic_setarylen,
					0,	0,	0};
MGVTBL vtbl_glob =	{magic_getglob,
				magic_setglob,
					0,	0,	0};
MGVTBL vtbl_mglob =	{0,	magic_setmglob,
					0,	0,	0};
MGVTBL vtbl_taint =	{magic_gettaint,magic_settaint,
					0,	0,	0};
MGVTBL vtbl_substr =	{0,	magic_setsubstr,
					0,	0,	0};
MGVTBL vtbl_vec =	{0,	magic_setvec,
					0,	0,	0};
MGVTBL vtbl_bm =	{0,	magic_setbm,
					0,	0,	0};
MGVTBL vtbl_uvar =	{magic_getuvar,
				magic_setuvar,
					0,	0,	0};
#else
EXT MGVTBL vtbl_sv;
EXT MGVTBL vtbl_env;
EXT MGVTBL vtbl_envelem;
EXT MGVTBL vtbl_sig;
EXT MGVTBL vtbl_sigelem;
EXT MGVTBL vtbl_pack;
EXT MGVTBL vtbl_packelem;
EXT MGVTBL vtbl_dbline;
EXT MGVTBL vtbl_isa;
EXT MGVTBL vtbl_isaelem;
EXT MGVTBL vtbl_arylen;
EXT MGVTBL vtbl_glob;
EXT MGVTBL vtbl_mglob;
EXT MGVTBL vtbl_taint;
EXT MGVTBL vtbl_substr;
EXT MGVTBL vtbl_vec;
EXT MGVTBL vtbl_bm;
EXT MGVTBL vtbl_uvar;
#endif
