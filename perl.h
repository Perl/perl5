/* $Header: perl.h,v 3.0 89/10/18 15:21:21 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	perl.h,v $
 * Revision 3.0  89/10/18  15:21:21  lwall
 * 3.0 baseline
 * 
 */

#ifndef lint
#define DEBUGGING
#endif

#define VOIDUSED 1
#include "config.h"

#ifdef IAMSUID
#   ifndef TAINT
#	define TAINT
#   endif
#endif

#ifdef MEMCPY
extern char *memcpy(), *memset();
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

#include <sys/stat.h>

#ifdef TMINSYS
#include <sys/time.h>
#else
#ifdef I_SYSTIME
#include <sys/time.h>
#else
#include <time.h>
#endif
#endif

#include <sys/times.h>

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

#ifdef I_DIRENT
#include <dirent.h>
#define DIRENT dirent
#else
#ifdef I_SYSDIR
#include <sys/dir.h>
#define DIRENT direct
#endif
#endif

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

#define STR_GROW(str,len) if ((str)->str_len < (len)) str_grow(str,len)

#ifndef BYTEORDER
#define BYTEORDER 01234
#endif

#ifndef HTONL
#if BYTEORDER != 04321
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
#if BYTEORDER == 04321
#undef HTONS
#undef HTONL
#undef NTOHS
#undef NTOHL
#endif
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
void do_vecset();
void savelist();
void saveitem();
void saveint();
void savelong();
void savesptr();
void savehptr();
void restorelist();
HASH *savehash();
ARRAY *saveary();

EXT line_t line INIT(0);
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

EXT char *filename;
EXT char *origfilename;
EXT FILE *rsfp;
EXT char buf[1024];
EXT char *bufptr;
EXT char *oldbufptr;
EXT char *oldoldbufptr;
EXT char *bufend;

EXT STR *linestr INIT(Nullstr);

EXT char record_separator INIT('\n');
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
EXT bool allstabs INIT(FALSE);	/* init all customary symbols in symbol table?*/
EXT bool sawampersand INIT(FALSE);	/* must save all match strings */
EXT bool sawstudy INIT(FALSE);		/* do fbminstr on all strings */
EXT bool sawi INIT(FALSE);		/* study must assume case insensitive */
EXT bool sawvec INIT(FALSE);

EXT int csh INIT(0);		/* 1 if /bin/csh is there, -1 if not */

#ifdef TAINT
EXT bool tainted INIT(FALSE);		/* using variables controlled by $< */
#endif

#define TMPPATH "/tmp/perl-eXXXXXX"
EXT char *e_tmpname;
EXT FILE *e_fp INIT(Nullfp);

EXT char tokenbuf[256];
EXT int expectterm INIT(TRUE);		/* how to interpret ambiguous tokens */
EXT int in_eval INIT(FALSE);		/* trap fatal errors? */
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
EXT int debug INIT(0);
EXT int dlevel INIT(0);
EXT int dlmax INIT(128);
EXT char *debname;
EXT char *debdelim;
#define YYDEBUG 1
extern int yydebug;
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
EXT jmp_buf eval_env;

EXT char *goto_targ INIT(Nullch);	/* cmd_exec gets strange when set */

EXT ARRAY *stack;		/* THE STACK */

EXT ARRAY *savestack;		/* to save non-local values on */

EXT ARRAY *tosave;		/* strings to save on recursive subroutine */

EXT ARRAY *lineary;		/* lines of script for debugger */

EXT ARRAY *pidstatary;		/* keep pids and statuses by fd for mypopen */

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
