/* $Header: a2p.h,v 1.0.1.2 88/02/01 17:33:40 root Exp $
 *
 * $Log:	a2p.h,v $
 * Revision 1.0.1.2  88/02/01  17:33:40  root
 * patch12: forgot to fix #define YYDEBUG; bug in a2p.
 * 
 * Revision 1.0.1.1  88/01/26  09:52:30  root
 * patch 5: a2p didn't use config.h.
 * 
 * Revision 1.0  87/12/18  13:06:58  root
 * Initial revision
 * 
 */

#define VOIDUSED 1
#include "../config.h"

#ifndef BCOPY
#   define bcopy(s1,s2,l) memcpy(s2,s1,l);
#   define bzero(s,l) memset(s,0,l);
#endif

#include "handy.h"
#define Nullop 0

#define OPROG		1
#define OJUNK		2
#define OHUNKS		3
#define ORANGE		4
#define OPAT		5
#define OHUNK		6
#define OPPAREN		7
#define OPANDAND	8
#define OPOROR		9
#define OPNOT		10
#define OCPAREN		11
#define OCANDAND	12
#define OCOROR		13
#define OCNOT		14
#define ORELOP		15
#define ORPAREN		16
#define OMATCHOP	17
#define OMPAREN		18
#define OCONCAT		19
#define OASSIGN		20
#define OADD		21
#define OSUB		22
#define OMULT		23
#define ODIV		24
#define OMOD		25
#define OPOSTINCR	26
#define OPOSTDECR	27
#define OPREINCR	28
#define OPREDECR	29
#define OUMINUS		30
#define OUPLUS		31
#define OPAREN		32
#define OGETLINE	33
#define OSPRINTF	34
#define OSUBSTR		35
#define OSTRING		36
#define OSPLIT		37
#define OSNEWLINE	38
#define OINDEX		39
#define ONUM		40
#define OSTR		41
#define OVAR		42
#define OFLD		43
#define ONEWLINE	44
#define OCOMMENT	45
#define OCOMMA		46
#define OSEMICOLON	47
#define OSCOMMENT	48
#define OSTATES		49
#define OSTATE		50
#define OPRINT		51
#define OPRINTF		52
#define OBREAK		53
#define ONEXT		54
#define OEXIT		55
#define OCONTINUE	56
#define OREDIR		57
#define OIF		58
#define OWHILE		59
#define OFOR		60
#define OFORIN		61
#define OVFLD		62
#define OBLOCK		63
#define OREGEX		64
#define OLENGTH		65
#define OLOG		66
#define OEXP		67
#define OSQRT		68
#define OINT		69

#ifdef DOINIT
char *opname[] = {
    "0",
    "PROG",
    "JUNK",
    "HUNKS",
    "RANGE",
    "PAT",
    "HUNK",
    "PPAREN",
    "PANDAND",
    "POROR",
    "PNOT",
    "CPAREN",
    "CANDAND",
    "COROR",
    "CNOT",
    "RELOP",
    "RPAREN",
    "MATCHOP",
    "MPAREN",
    "CONCAT",
    "ASSIGN",
    "ADD",
    "SUB",
    "MULT",
    "DIV",
    "MOD",
    "POSTINCR",
    "POSTDECR",
    "PREINCR",
    "PREDECR",
    "UMINUS",
    "UPLUS",
    "PAREN",
    "GETLINE",
    "SPRINTF",
    "SUBSTR",
    "STRING",
    "SPLIT",
    "SNEWLINE",
    "INDEX",
    "NUM",
    "STR",
    "VAR",
    "FLD",
    "NEWLINE",
    "COMMENT",
    "COMMA",
    "SEMICOLON",
    "SCOMMENT",
    "STATES",
    "STATE",
    "PRINT",
    "PRINTF",
    "BREAK",
    "NEXT",
    "EXIT",
    "CONTINUE",
    "REDIR",
    "IF",
    "WHILE",
    "FOR",
    "FORIN",
    "VFLD",
    "BLOCK",
    "REGEX",
    "LENGTH",
    "LOG",
    "EXP",
    "SQRT",
    "INT",
    "70"
};
#else
extern char *opname[];
#endif

union {
    int ival;
    char *cval;
} ops[50000];		/* hope they have 200k to spare */

EXT int mop INIT(1);

#define DEBUGGING

#include <stdio.h>
#include <ctype.h>
#include <setjmp.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <sys/times.h>

typedef struct string STR;
typedef struct htbl HASH;

#include "str.h"
#include "hash.h"

/* A string is TRUE if not "" or "0". */
#define True(val) (tmps = (val), (*tmps && !(*tmps == '0' && !tmps[1])))
EXT char *Yes INIT("1");
EXT char *No INIT("");

#define str_true(str) (Str = (str), (Str->str_pok ? True(Str->str_ptr) : (Str->str_nok ? (Str->str_nval != 0.0) : 0 )))

#define str_peek(str) (Str = (str), (Str->str_pok ? Str->str_ptr : (Str->str_nok ? (sprintf(buf,"num(%g)",Str->str_nval),buf) : "" )))
#define str_get(str) (Str = (str), (Str->str_pok ? Str->str_ptr : str_2ptr(Str)))
#define str_gnum(str) (Str = (str), (Str->str_nok ? Str->str_nval : str_2num(Str)))
EXT STR *Str;

#define GROWSTR(pp,lp,len) if (*(lp) < (len)) growstr(pp,lp,len)

STR *str_new();

char *scanpat();
char *scannum();

void str_free();

EXT int line INIT(0);

EXT FILE *rsfp;
EXT char buf[1024];
EXT char *bufptr INIT(buf);

EXT STR *linestr INIT(Nullstr);

EXT char tokenbuf[256];
EXT int expectterm INIT(TRUE);

#ifdef DEBUGGING
EXT int debug INIT(0);
EXT int dlevel INIT(0);
#define YYDEBUG 1
extern int yydebug;
#endif

EXT STR *freestrroot INIT(Nullstr);

EXT STR str_no;
EXT STR str_yes;

EXT bool do_split INIT(FALSE);
EXT bool split_to_array INIT(FALSE);
EXT bool set_array_base INIT(FALSE);
EXT bool saw_RS INIT(FALSE);
EXT bool saw_OFS INIT(FALSE);
EXT bool saw_ORS INIT(FALSE);
EXT bool saw_line_op INIT(FALSE);
EXT bool in_begin INIT(TRUE);
EXT bool do_opens INIT(FALSE);
EXT bool do_fancy_opens INIT(FALSE);
EXT bool lval_field INIT(FALSE);
EXT bool do_chop INIT(FALSE);
EXT bool need_entire INIT(FALSE);
EXT bool absmaxfld INIT(FALSE);

EXT char const_FS INIT(0);
EXT char *namelist INIT(Nullch);
EXT char fswitch INIT(0);

EXT int saw_FS INIT(0);
EXT int maxfld INIT(0);
EXT int arymax INIT(0);
char *nameary[100];

EXT STR *opens;

EXT HASH *symtab;
