/* $Header: perl.h,v 1.0.1.4 88/01/30 08:54:00 root Exp $
 *
 * $Log:	perl.h,v $
 * Revision 1.0.1.4  88/01/30  08:54:00  root
 * patch9: changed #define YYDEBUG; to #define YYDEBUG 1
 * 
 * Revision 1.0.1.3  88/01/28  10:24:17  root
 * patch8: added eval operator.
 * 
 * Revision 1.0.1.2  88/01/24  03:53:47  root
 * patch 2: hid str_peek() in #ifdef DEBUGGING.
 * 
 * Revision 1.0.1.1  88/01/21  21:29:23  root
 * No longer defines STDSTDIO--gets it from config.h now.
 * 
 * Revision 1.0  87/12/18  13:05:38  root
 * Initial revision
 * 
 */

#define DEBUGGING

#define VOIDUSED 1
#include "config.h"

#ifndef BCOPY
#   define bcopy(s1,s2,l) memcpy(s2,s1,l);
#   define bzero(s,l) memset(s,0,l);
#endif

#include <stdio.h>
#include <ctype.h>
#include <setjmp.h>
#include <sys/types.h>
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
typedef struct string STR;
typedef struct atbl ARRAY;
typedef struct htbl HASH;

#include "str.h"
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
#define str_peek(str) (Str = (str), (Str->str_pok ? Str->str_ptr : (Str->str_nok ? (sprintf(buf,"num(%g)",Str->str_nval),buf) : "" )))
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

SPAT *stab_to_spat();

STAB *stabent();

ARG *stab_to_arg();
ARG *op_new();
ARG *make_op();
ARG *make_lval();
ARG *make_match();
ARG *make_split();
ARG *flipflip();

STR *arg_to_str();
STR *str_new();
STR *stab_str();
STR *eval();		/* this evaluates expressions */
STR *do_eval();		/* this evaluates eval operator */

FCMD *load_format();

char *scanpat();
char *scansubst();
char *scantrans();
char *scanstr();
char *scanreg();
char *reg_get();
char *str_append_till();
char *str_gets();

bool do_match();
bool do_open();
bool do_close();
bool do_print();

int do_subst();

void str_free();
void freearg();

EXT int line INIT(0);
EXT int arybase INIT(0);

struct outrec {
    int o_lines;
    char *o_str;
    int o_len;
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

EXT STR *freestrroot INIT(Nullstr);

EXT FILE *rsfp;
EXT char buf[1024];
EXT char *bufptr INIT(buf);

EXT STR *linestr INIT(Nullstr);

EXT char record_separator INIT('\n');
EXT char *ofs INIT(Nullch);
EXT char *ors INIT(Nullch);
EXT char *ofmt INIT(Nullch);
EXT char *inplace INIT(Nullch);

EXT char tokenbuf[256];
EXT int expectterm INIT(TRUE);
EXT int lex_newlines INIT(FALSE);
EXT int in_eval INIT(FALSE);

FILE *popen();
/* char *str_get(); */
STR *interp();
void free_arg();
STIO *stio_new();

EXT struct stat statbuf;
EXT struct tms timesbuf;

#ifdef DEBUGGING
EXT int debug INIT(0);
EXT int dlevel INIT(0);
EXT char debname[40];
EXT char debdelim[40];
#define YYDEBUG 1
extern int yydebug;
#endif

EXT STR str_no;
EXT STR str_yes;

/* runtime control stuff */

EXT struct loop {
    char *loop_label;
    jmp_buf loop_env;
} loop_stack[32];

EXT int loop_ptr INIT(-1);

EXT jmp_buf top_env;
EXT jmp_buf eval_env;

EXT char *goto_targ INIT(Nullch);	/* cmd_exec gets strange when set */

double atof();

#ifdef EUNICE
#define UNLINK(f) while (unlink(f) >= 0)
#else
#define UNLINK unlink
#endif
