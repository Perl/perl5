/* $Header: perl.h,v 2.0 88/06/05 00:09:21 root Exp $
 *
 * $Log:	perl.h,v $
 * Revision 2.0  88/06/05  00:09:21  root
 * Baseline version 2.0.
 * 
 */

#ifndef lint
#define DEBUGGING
#endif

#define VOIDUSED 1
#include "config.h"

#ifdef MEMCPY
extern char *memcpy(), *memset();
#define bcopy(s1,s2,l) memcpy(s2,s1,l);
#define bzero(s,l) memset(s,0,l);
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
#include <time.h>
#endif

#include <sys/times.h>

typedef struct arg ARG;
typedef struct cmd CMD;
typedef struct formcmd FCMD;
typedef struct scanpat SPAT;
typedef struct stab STAB;
typedef struct stio STIO;
typedef struct sub SUBR;
typedef struct string STR;
typedef struct atbl ARRAY;
typedef struct htbl HASH;
typedef struct regexp REGEXP;

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

#ifdef CHARSPRINTF
    char *sprintf();
#else
    int sprintf();
#endif

/* A string is TRUE if not "" or "0". */
#define True(val) (tmps = (val), (*tmps && !(*tmps == '0' && !tmps[1])))
EXT char *Yes INIT("1");
EXT char *No INIT("");

#define str_true(str) (Str = (str), (Str->str_pok ? True(Str->str_ptr) : (Str->str_nok ? (Str->str_nval != 0.0) : 0 )))

#ifdef DEBUGGING
#define str_peek(str) (Str = (str), (Str->str_pok ? Str->str_ptr : (Str->str_nok ? (sprintf(buf,"num(%g)",Str->str_nval),(char*)buf) : "" )))
#endif

#define str_get(str) (Str = (str), (Str->str_pok ? Str->str_ptr : str_2ptr(Str)))
#define str_gnum(str) (Str = (str), (Str->str_nok ? Str->str_nval : str_2num(Str)))
EXT STR *Str;

#define GROWSTR(pp,lp,len) if (*(lp) < (len)) growstr(pp,lp,len)

CMD *add_label();
CMD *block_head();
CMD *append_line();
CMD *make_acmd();
CMD *make_ccmd();
CMD *invert();
CMD *addcond();
CMD *addloop();
CMD *wopt();
CMD *over();

SPAT *stab2spat();

STAB *stabent();
STAB *genstab();

ARG *stab2arg();
ARG *op_new();
ARG *make_op();
ARG *make_lval();
ARG *make_match();
ARG *make_split();
ARG *flipflip();
ARG *listish();
ARG *localize();
ARG *l();
ARG *mod_match();
ARG *make_list();
ARG *cmd_to_arg();
ARG *addflags();
ARG *hide_ary();
ARG *cval_to_arg();

STR *arg_to_str();
STR *str_new();
STR *stab_str();
STR *eval();		/* this evaluates expressions */
STR *do_eval();		/* this evaluates eval operator */
STR *do_each();
STR *do_subr();
STR *do_match();

SUBR *make_sub();

FCMD *load_format();

char *scanpat();
char *scansubst();
char *scantrans();
char *scanstr();
char *scanreg();
char *reg_get();
char *str_append_till();
char *str_gets();

bool do_open();
bool do_close();
bool do_print();
bool do_aprint();
bool do_exec();
bool do_aexec();

int do_subst();
int cando();
int ingroup();

void str_grow();
void str_replace();
void str_inc();
void str_dec();
void str_free();
void freearg();
void savelist();
void restorelist();
void ajoin();
void do_join();
void do_assign();
void do_sprintf();

EXT line_t line INIT(0);
EXT int arybase INIT(0);

struct outrec {
    line_t  o_lines;
    char    *o_str;
    int     o_len;
};

EXT struct outrec outrec;
EXT struct outrec toprec;

EXT STAB *last_in_stab INIT(Nullstab);
EXT STAB *defstab INIT(Nullstab);
EXT STAB *argvstab INIT(Nullstab);
EXT STAB *envstab INIT(Nullstab);
EXT STAB *sigstab INIT(Nullstab);
EXT STAB *defoutstab INIT(Nullstab);
EXT STAB *curoutstab INIT(Nullstab);
EXT STAB *argvoutstab INIT(Nullstab);
EXT STAB *incstab INIT(Nullstab);

EXT STR *freestrroot INIT(Nullstr);
EXT STR *lastretstr INIT(Nullstr);

EXT char *filename;
EXT char *origfilename;
EXT FILE *rsfp;
EXT char buf[1024];
EXT char *bufptr INIT(buf);

EXT STR *linestr INIT(Nullstr);

EXT char record_separator INIT('\n');
EXT char *ofs INIT(Nullch);
EXT char *ors INIT(Nullch);
EXT char *ofmt INIT(Nullch);
EXT char *inplace INIT(Nullch);

EXT bool preprocess INIT(FALSE);
EXT bool minus_n INIT(FALSE);
EXT bool minus_p INIT(FALSE);
EXT bool minus_a INIT(FALSE);
EXT bool doswitches INIT(FALSE);
EXT bool dowarn INIT(FALSE);
EXT bool allstabs INIT(FALSE);	/* init all customary symbols in symbol table?*/
EXT bool sawampersand INIT(FALSE);	/* must save all match strings */
EXT bool sawstudy INIT(FALSE);		/* do fbminstr on all strings */

#define TMPPATH "/tmp/perl-eXXXXXX"
EXT char *e_tmpname;
EXT FILE *e_fp INIT(Nullfp);

EXT char tokenbuf[256];
EXT int expectterm INIT(TRUE);
EXT int lex_newlines INIT(FALSE);
EXT int in_eval INIT(FALSE);
EXT int multiline INIT(0);
EXT int forkprocess;

FILE *popen();
/* char *str_get(); */
STR *interp();
void free_arg();
STIO *stio_new();

EXT struct stat statbuf;
EXT struct tms timesbuf;
EXT int uid;
EXT int euid;
UIDTYPE getuid();
UIDTYPE geteuid();
GIDTYPE getgid();
GIDTYPE getegid();
EXT int unsafe;

#ifdef DEBUGGING
EXT int debug INIT(0);
EXT int dlevel INIT(0);
EXT char debname[128];
EXT char debdelim[128];
#define YYDEBUG 1
extern int yydebug;
#endif

EXT line_t cmdline INIT(NOLINE);

EXT STR str_no;
EXT STR str_yes;

/* runtime control stuff */

EXT struct loop {
    char *loop_label;
    jmp_buf loop_env;
} loop_stack[64];

EXT int loop_ptr INIT(-1);

EXT jmp_buf top_env;
EXT jmp_buf eval_env;

EXT char *goto_targ INIT(Nullch);	/* cmd_exec gets strange when set */

EXT ARRAY *savestack;		/* to save non-local values on */

EXT ARRAY *tosave;		/* strings to save on recursive subroutine */

double atof();
unsigned sleep();
long time(), times();
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
