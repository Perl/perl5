/* $Header: perl.h,v 3.0.1.8 90/08/09 04:10:53 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	perl.h,v $
 * Revision 3.0.1.8  90/08/09  04:10:53  lwall
 * patch19: various MSDOS and OS/2 patches folded in
 * patch19: did preliminary work toward debugging packages and evals
 * patch19: added -x switch to extract script from input trash
 * 
 * Revision 3.0.1.7  90/03/27  16:12:52  lwall
 * patch16: MSDOS support
 * patch16: support for machines that can't cast negative floats to unsigned ints
 * 
 * Revision 3.0.1.6  90/03/12  16:40:43  lwall
 * patch13: did some ndir straightening up for Xenix
 * 
 * Revision 3.0.1.5  90/02/28  17:52:28  lwall
 * patch9: Configure now determines whether volatile is supported
 * patch9: volatilized some more variables for super-optimizing compilers
 * patch9: unused VREG symbol deleted
 * patch9: perl can now start up other interpreters scripts  
 * patch9: you may now undef $/ to have no input record separator
 * patch9: nested evals clobbered their longjmp environment
 * 
 * Revision 3.0.1.4  89/12/21  20:07:35  lwall
 * patch7: arranged for certain registers to be restored after longjmp()
 * patch7: Configure now compiles a test program to figure out time.h fiasco
 * patch7: Configure now detects DG/UX thingies like [sg]etpgrp2 and utime.h
 * patch7: memcpy() and memset() return void in __STDC__
 * patch7: errno may now be a macro with an lvalue
 * patch7: ANSI strerror() is now supported
 * patch7: Xenix support for sys/ndir.h, cross compilation
 * 
 * Revision 3.0.1.3  89/11/17  15:28:57  lwall
 * patch5: byteorder now is a hex value
 * patch5: Configure now looks for <time.h> including <sys/time.h>
 * 
 * Revision 3.0.1.2  89/11/11  04:39:38  lwall
 * patch2: Configure may now set -DDEBUGGING
 * patch2: netinet/in.h needed sys/types.h some places
 * patch2: more <sys/time.h> and <time.h> wrangling
 * patch2: yydebug moved to where type doesn't matter  
 * 
 * Revision 3.0.1.1  89/10/26  23:17:08  lwall
 * patch1: vfork now conditionally defined based on VFORK
 * patch1: DEC risc machines have a buggy memcmp
 * patch1: perl.h now includes <netinet/in.h> if it exists
 * 
 * Revision 3.0  89/10/18  15:21:21  lwall
 * 3.0 baseline
 * 
 */

#define VOIDUSED 1
#include "config.h"

#ifdef MSDOS
/*
 * BUGGY_MSC:
 *	This symbol is defined if you are the unfortunate owner of a buggy
 *	Microsoft C compiler and want to use intrinsic functions.  Versions
 *	up to 5.1 are known conform to this definition.  This is not needed
 *	under Unix.
 */
#define BUGGY_MSC			/**/
/*
 * BINARY:
 *	This symbol is defined if you run under an operating system that
 *	distinguishes between binary and text files.  If so the function
 *	setmode will be used to set the file into binary mode.  Unix
 *	doesn't distinguish.
 */
#define BINARY				/**/

#else /* !MSDOS */

/*
 * The following symbols are defined if your operating system supports
 * functions by that name.  All Unixes I know of support them, thus they
 * are not checked by the configuration script, but are directly defined
 * here.
 */
#define CHOWN
#define CHROOT
#define FORK
#define GETLOGIN
#define GETPPID
#define KILL
#define LINK
#define PIPE
#define WAIT
#define UMASK
/*
 * The following symbols are defined if your operating system supports
 * password and group functions in general.  All Unix systems do.
 */
#define GROUP
#define PASSWD

#endif /* !MSDOS */

#if defined(HASVOLATILE) || defined(__STDC__)
#define VOLATILE volatile
#else
#define VOLATILE
#endif

#ifdef IAMSUID
#   ifndef TAINT
#	define TAINT
#   endif
#endif

#ifndef VFORK
#   define vfork fork
#endif

#ifdef GETPGRP2
#   ifndef GETPGRP
#	define GETPGRP
#   endif
#   define getpgrp getpgrp2
#endif

#ifdef SETPGRP2
#   ifndef SETPGRP
#	define SETPGRP
#   endif
#   define setpgrp setpgrp2
#endif

#if defined(MEMCMP) && defined(mips) && BYTEORDER == 0x1234
#undef MEMCMP
#endif

#ifdef MEMCPY
#ifndef memcpy
#if defined(__STDC__ ) || defined(MSDOS)
extern void *memcpy(), *memset();
#else
extern char *memcpy(), *memset();
#endif
extern int memcmp();
#endif
#define bcopy(s1,s2,l) memcpy(s2,s1,l)
#define bzero(s,l) memset(s,0,l)
#endif
#ifndef BCMP		/* prefer bcmp slightly 'cuz it doesn't order */
#define bcmp(s1,s2,l) memcmp(s1,s2,l)
#endif

#include <stdio.h>
#include <ctype.h>
#include <setjmp.h>
#include <sys/param.h>	/* if this needs types.h we're still wrong */

#ifndef _TYPES_		/* If types.h defines this it's easy. */
#ifndef major		/* Does everyone's types.h define this? */
#include <sys/types.h>
#endif
#endif

#ifdef I_NETINET_IN
#include <netinet/in.h>
#endif

#include <sys/stat.h>

#ifdef I_TIME
#   include <time.h>
#endif

#ifdef I_SYSTIME
#   ifdef SYSTIMEKERNEL
#	define KERNEL
#   endif
#   include <sys/time.h>
#   ifdef SYSTIMEKERNEL
#	undef KERNEL
#   endif
#endif

#include <sys/times.h>

#if defined(STRERROR) && (!defined(MKDIR) || !defined(RMDIR))
#undef STRERROR
#endif

#include <errno.h>
#ifndef errno
extern int errno;     /* ANSI allows errno to be an lvalue expr */
#endif

#ifdef STRERROR
char *strerror();
#else
extern int sys_nerr;
extern char *sys_errlist[];
#define strerror(e) ((e) < 0 || (e) >= sys_nerr ? "(unknown)" : sys_errlist[e])
#endif

#ifdef I_SYSIOCTL
#ifndef _IOCTL_
#include <sys/ioctl.h>
#endif
#endif

#if defined(mc300) || defined(mc500) || defined(mc700)	/* MASSCOMP */
#ifdef SOCKETPAIR
#undef SOCKETPAIR
#endif
#ifdef NDBM
#undef NDBM
#endif
#endif

#ifdef NDBM
#include <ndbm.h>
#define SOME_DBM
#ifdef ODBM
#undef ODBM
#endif
#else
#ifdef ODBM
#ifdef NULL
#undef NULL		/* suppress redefinition message */
#endif
#include <dbm.h>
#ifdef NULL
#undef NULL
#endif
#define NULL 0		/* silly thing is, we don't even use this */
#define SOME_DBM
#define dbm_fetch(db,dkey) fetch(dkey)
#define dbm_delete(db,dkey) delete(dkey)
#define dbm_store(db,dkey,dcontent,flags) store(dkey,dcontent)
#define dbm_close(db) dbmclose()
#define dbm_firstkey(db) firstkey()
#endif /* ODBM */
#endif /* NDBM */
#ifdef SOME_DBM
EXT char *dbmkey;
EXT int dbmlen;
#endif

#if INTSIZE == 2
#define htoni htons
#define ntohi ntohs
#else
#define htoni htonl
#define ntohi ntohl
#endif

#if defined(I_DIRENT) && !defined(M_XENIX)
#   include <dirent.h>
#   define DIRENT dirent
#else
#   ifdef I_SYSNDIR
#	include <sys/ndir.h>
#	define DIRENT direct
#   else
#	ifdef I_SYSDIR
#	    ifdef hp9000s500
#		include <ndir.h>	/* may be wrong in the future */
#	    else
#		include <sys/dir.h>
#	    endif
#	    define DIRENT direct
#	endif
#   endif
#endif

typedef unsigned int STRLEN;

typedef struct arg ARG;
typedef struct cmd CMD;
typedef struct formcmd FCMD;
typedef struct scanpat SPAT;
typedef struct stio STIO;
typedef struct sub SUBR;
typedef struct string STR;
typedef struct atbl ARRAY;
typedef struct htbl HASH;
typedef struct regexp REGEXP;
typedef struct stabptrs STBP;
typedef struct stab STAB;

#include "handy.h"
#include "regexp.h"
#include "str.h"
#include "util.h"
#include "form.h"
#include "stab.h"
#include "spat.h"
#include "arg.h"
#include "cmd.h"
#include "array.h"
#include "hash.h"

#if defined(iAPX286) || defined(M_I286) || defined(I80286)
#   define I286
#endif

#ifndef	__STDC__
#ifdef CHARSPRINTF
    char *sprintf();
#else
    int sprintf();
#endif
#endif

EXT char *Yes INIT("1");
EXT char *No INIT("");

/* "gimme" values */

/* Note: cmd.c assumes that it can use && to produce one of these values! */
#define G_SCALAR 0
#define G_ARRAY 1

#ifdef CRIPPLED_CC
int str_true();
#else /* !CRIPPLED_CC */
#define str_true(str) (Str = (str), \
	(Str->str_pok ? \
	    ((*Str->str_ptr > '0' || \
	      Str->str_cur > 1 || \
	      (Str->str_cur && *Str->str_ptr != '0')) ? 1 : 0) \
	: \
	    (Str->str_nok ? (Str->str_u.str_nval != 0.0) : 0 ) ))
#endif /* CRIPPLED_CC */

#ifdef DEBUGGING
#define str_peek(str) (Str = (str), \
	(Str->str_pok ? \
	    Str->str_ptr : \
	    (Str->str_nok ? \
		(sprintf(tokenbuf,"num(%g)",Str->str_u.str_nval), \
		    (char*)tokenbuf) : \
		"" )))
#endif

#ifdef CRIPPLED_CC
char *str_get();
#else
#ifdef TAINT
#define str_get(str) (Str = (str), tainted |= Str->str_tainted, \
	(Str->str_pok ? Str->str_ptr : str_2ptr(Str)))
#else
#define str_get(str) (Str = (str), (Str->str_pok ? Str->str_ptr : str_2ptr(Str)))
#endif /* TAINT */
#endif /* CRIPPLED_CC */

#ifdef CRIPPLED_CC
double str_gnum();
#else /* !CRIPPLED_CC */
#ifdef TAINT
#define str_gnum(str) (Str = (str), tainted |= Str->str_tainted, \
	(Str->str_nok ? Str->str_u.str_nval : str_2num(Str)))
#else /* !TAINT */
#define str_gnum(str) (Str = (str), (Str->str_nok ? Str->str_u.str_nval : str_2num(Str)))
#endif /* TAINT*/
#endif /* CRIPPLED_CC */
EXT STR *Str;

#define GROWSTR(pp,lp,len) if (*(lp) < (len)) growstr(pp,lp,len)

#ifndef MSDOS
#define STR_GROW(str,len) if ((str)->str_len < (len)) str_grow(str,len)
#define Str_Grow str_grow
#else
/* extra parentheses intentionally NOT placed around "len"! */
#define STR_GROW(str,len) if ((str)->str_len < (unsigned long)len) \
		str_grow(str,(unsigned long)len)
#define Str_Grow(str,len) str_grow(str,(unsigned long)(len))
#endif /* MSDOS */

#ifndef BYTEORDER
#define BYTEORDER 0x1234
#endif

#if defined(htonl) && !defined(HTONL)
#define HTONL
#endif
#if defined(htons) && !defined(HTONS)
#define HTONS
#endif
#if defined(ntohl) && !defined(NTOHL)
#define NTOHL
#endif
#if defined(ntohs) && !defined(NTOHS)
#define NTOHS
#endif
#ifndef HTONL
#if (BYTEORDER != 0x4321) && (BYTEORDER != 0x87654321)
#define HTONS
#define HTONL
#define NTOHS
#define NTOHL
#define MYSWAP
#define htons my_swap
#define htonl my_htonl
#define ntohs my_swap
#define ntohl my_ntohl
#endif
#else
#if (BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)
#undef HTONS
#undef HTONL
#undef NTOHS
#undef NTOHL
#endif
#endif

#ifdef CASTNEGFLOAT
#define U_S(what) ((unsigned short)(what))
#define U_I(what) ((unsigned int)(what))
#define U_L(what) ((unsigned long)(what))
#else
unsigned long castulong();
#define U_S(what) ((unsigned int)castulong(what))
#define U_I(what) ((unsigned int)castulong(what))
#define U_L(what) (castulong(what))
#endif

CMD *add_label();
CMD *block_head();
CMD *append_line();
CMD *make_acmd();
CMD *make_ccmd();
CMD *make_icmd();
CMD *invert();
CMD *addcond();
CMD *addloop();
CMD *wopt();
CMD *over();

STAB *stabent();
STAB *genstab();

ARG *stab2arg();
ARG *op_new();
ARG *make_op();
ARG *make_match();
ARG *make_split();
ARG *rcatmaybe();
ARG *listish();
ARG *maybelistish();
ARG *localize();
ARG *fixeval();
ARG *jmaybe();
ARG *l();
ARG *fixl();
ARG *mod_match();
ARG *make_list();
ARG *cmd_to_arg();
ARG *addflags();
ARG *hide_ary();
ARG *cval_to_arg();

STR *str_new();
STR *stab_str();

int do_each();
int do_subr();
int do_match();
int do_unpack();
int eval();		/* this evaluates expressions */
int do_eval();		/* this evaluates eval operator */
int do_assign();

SUBR *make_sub();

FCMD *load_format();

char *scanpat();
char *scansubst();
char *scantrans();
char *scanstr();
char *scanreg();
char *str_append_till();
char *str_gets();
char *str_grow();

bool do_open();
bool do_close();
bool do_print();
bool do_aprint();
bool do_exec();
bool do_aexec();

int do_subst();
int cando();
int ingroup();

void str_replace();
void str_inc();
void str_dec();
void str_free();
void stab_clear();
void do_join();
void do_sprintf();
void do_accept();
void do_pipe();
void do_vecset();
void savelist();
void saveitem();
void saveint();
void savelong();
void savesptr();
void savehptr();
void restorelist();
void repeatcpy();
HASH *savehash();
ARRAY *saveary();

EXT char **origargv;
EXT int origargc;
EXT line_t subline INIT(0);
EXT STR *subname INIT(Nullstr);
EXT int arybase INIT(0);

struct outrec {
    line_t  o_lines;
    char    *o_str;
    int     o_len;
};

EXT struct outrec outrec;
EXT struct outrec toprec;

EXT STAB *stdinstab INIT(Nullstab);
EXT STAB *last_in_stab INIT(Nullstab);
EXT STAB *defstab INIT(Nullstab);
EXT STAB *argvstab INIT(Nullstab);
EXT STAB *envstab INIT(Nullstab);
EXT STAB *sigstab INIT(Nullstab);
EXT STAB *defoutstab INIT(Nullstab);
EXT STAB *curoutstab INIT(Nullstab);
EXT STAB *argvoutstab INIT(Nullstab);
EXT STAB *incstab INIT(Nullstab);
EXT STAB *leftstab INIT(Nullstab);
EXT STAB *amperstab INIT(Nullstab);
EXT STAB *rightstab INIT(Nullstab);
EXT STAB *DBstab INIT(Nullstab);
EXT STAB *DBsub INIT(Nullstab);

EXT HASH *defstash;		/* main symbol table */
EXT HASH *curstash;		/* symbol table for current package */
EXT HASH *debstash;		/* symbol table for perldb package */

EXT STR *curstname;		/* name of current package */

EXT STR *freestrroot INIT(Nullstr);
EXT STR *lastretstr INIT(Nullstr);
EXT STR *DBsingle INIT(Nullstr);

EXT int lastspbase;
EXT int lastsize;

EXT char *curpack;
EXT char *filename;
EXT char *origfilename;
EXT FILE * VOLATILE rsfp;
EXT char buf[1024];
EXT char *bufptr;
EXT char *oldbufptr;
EXT char *oldoldbufptr;
EXT char *bufend;

EXT STR *linestr INIT(Nullstr);

EXT int record_separator INIT('\n');
EXT int rslen INIT(1);
EXT char *ofs INIT(Nullch);
EXT int ofslen INIT(0);
EXT char *ors INIT(Nullch);
EXT int orslen INIT(0);
EXT char *ofmt INIT(Nullch);
EXT char *inplace INIT(Nullch);
EXT char *nointrp INIT("");

EXT bool preprocess INIT(FALSE);
EXT bool minus_n INIT(FALSE);
EXT bool minus_p INIT(FALSE);
EXT bool minus_a INIT(FALSE);
EXT bool doswitches INIT(FALSE);
EXT bool dowarn INIT(FALSE);
EXT bool doextract INIT(FALSE);
EXT bool allstabs INIT(FALSE);	/* init all customary symbols in symbol table?*/
EXT bool sawampersand INIT(FALSE);	/* must save all match strings */
EXT bool sawstudy INIT(FALSE);		/* do fbminstr on all strings */
EXT bool sawi INIT(FALSE);		/* study must assume case insensitive */
EXT bool sawvec INIT(FALSE);
EXT bool localizing INIT(FALSE);	/* are we processing a local() list? */

#ifdef CSH
char *cshname INIT(CSH);
int cshlen INIT(0);
#endif /* CSH */

#ifdef TAINT
EXT bool tainted INIT(FALSE);		/* using variables controlled by $< */
#endif

#ifndef MSDOS
#define TMPPATH "/tmp/perl-eXXXXXX"
#else
#define TMPPATH "/tmp/plXXXXXX"
#endif /* MSDOS */
EXT char *e_tmpname;
EXT FILE *e_fp INIT(Nullfp);

EXT char tokenbuf[256];
EXT int expectterm INIT(TRUE);		/* how to interpret ambiguous tokens */
EXT VOLATILE int in_eval INIT(FALSE);	/* trap fatal errors? */
EXT int multiline INIT(0);		/* $*--do strings hold >1 line? */
EXT int forkprocess;			/* so do_open |- can return proc# */
EXT int do_undump INIT(0);		/* -u or dump seen? */
EXT int error_count INIT(0);		/* how many errors so far, max 10 */
EXT int multi_start INIT(0);		/* 1st line of multi-line string */
EXT int multi_end INIT(0);		/* last line of multi-line string */
EXT int multi_open INIT(0);		/* delimiter of said string */
EXT int multi_close INIT(0);		/* delimiter of said string */

FILE *popen();
/* char *str_get(); */
STR *interp();
void free_arg();
STIO *stio_new();

EXT struct stat statbuf;
EXT struct stat statcache;
STAB *statstab INIT(Nullstab);
STR *statname;
EXT struct tms timesbuf;
EXT int uid;
EXT int euid;
EXT int gid;
EXT int egid;
UIDTYPE getuid();
UIDTYPE geteuid();
GIDTYPE getgid();
GIDTYPE getegid();
EXT int unsafe;

#ifdef DEBUGGING
EXT VOLATILE int debug INIT(0);
EXT int dlevel INIT(0);
EXT int dlmax INIT(128);
EXT char *debname;
EXT char *debdelim;
#define YYDEBUG 1
#endif
EXT int perldb INIT(0);

EXT line_t cmdline INIT(NOLINE);

EXT STR str_undef;
EXT STR str_no;
EXT STR str_yes;

/* runtime control stuff */

EXT struct loop {
    char *loop_label;		/* what the loop was called, if anything */
    int loop_sp;		/* stack pointer to copy stuff down to */
    jmp_buf loop_env;
} *loop_stack;

EXT int loop_ptr INIT(-1);
EXT int loop_max INIT(128);

EXT jmp_buf top_env;

EXT char * VOLATILE goto_targ INIT(Nullch); /* cmd_exec gets strange when set */

struct ufuncs {
    int (*uf_val)();
    int (*uf_set)();
    int uf_index;
};

EXT ARRAY *stack;		/* THE STACK */

EXT ARRAY * VOLATILE savestack;		/* to save non-local values on */

EXT ARRAY *tosave;		/* strings to save on recursive subroutine */

EXT ARRAY *lineary;		/* lines of script for debugger */

EXT ARRAY *pidstatary;		/* keep pids and statuses by fd for mypopen */

EXT int *di;			/* for tmp use in debuggers */
EXT char *dc;
EXT short *ds;

double atof();
long time();
struct tm *gmtime(), *localtime();
char *mktemp();
char *index(), *rindex();
char *strcpy(), *strcat();

#ifdef EUNICE
#define UNLINK unlnk
int unlnk();
#else
#define UNLINK unlink
#endif

#ifndef SETREUID
#ifdef SETRESUID
#define setreuid(r,e) setresuid(r,e,-1)
#define SETREUID
#endif
#endif
#ifndef SETREGID
#ifdef SETRESGID
#define setregid(r,e) setresgid(r,e,-1)
#define SETREGID
#endif
#endif
