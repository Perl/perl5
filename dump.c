/* $Header: dump.c,v 1.0 87/12/18 13:05:03 root Exp $
 *
 * $Log:	dump.c,v $
 * Revision 1.0  87/12/18  13:05:03  root
 * Initial revision
 * 
 */

#include "handy.h"
#include "EXTERN.h"
#include "search.h"
#include "util.h"
#include "perl.h"

#ifdef DEBUGGING
static int dumplvl = 0;

dump_cmd(cmd,alt)
register CMD *cmd;
register CMD *alt;
{
    fprintf(stderr,"{\n");
    while (cmd) {
	dumplvl++;
	dump("C_TYPE = %s\n",cmdname[cmd->c_type]);
	if (cmd->c_label)
	    dump("C_LABEL = \"%s\"\n",cmd->c_label);
	dump("C_OPT = CFT_%s\n",cmdopt[cmd->c_flags & CF_OPTIMIZE]);
	*buf = '\0';
	if (cmd->c_flags & CF_FIRSTNEG)
	    strcat(buf,"FIRSTNEG,");
	if (cmd->c_flags & CF_NESURE)
	    strcat(buf,"NESURE,");
	if (cmd->c_flags & CF_EQSURE)
	    strcat(buf,"EQSURE,");
	if (cmd->c_flags & CF_COND)
	    strcat(buf,"COND,");
	if (cmd->c_flags & CF_LOOP)
	    strcat(buf,"LOOP,");
	if (cmd->c_flags & CF_INVERT)
	    strcat(buf,"INVERT,");
	if (cmd->c_flags & CF_ONCE)
	    strcat(buf,"ONCE,");
	if (cmd->c_flags & CF_FLIP)
	    strcat(buf,"FLIP,");
	if (*buf)
	    buf[strlen(buf)-1] = '\0';
	dump("C_FLAGS = (%s)\n",buf);
	if (cmd->c_first) {
	    dump("C_FIRST = \"%s\"\n",str_peek(cmd->c_first));
	    dump("C_FLEN = \"%d\"\n",cmd->c_flen);
	}
	if (cmd->c_stab) {
	    dump("C_STAB = ");
	    dump_stab(cmd->c_stab);
	}
	if (cmd->c_spat) {
	    dump("C_SPAT = ");
	    dump_spat(cmd->c_spat);
	}
	if (cmd->c_expr) {
	    dump("C_EXPR = ");
	    dump_arg(cmd->c_expr);
	} else
	    dump("C_EXPR = NULL\n");
	switch (cmd->c_type) {
	case C_WHILE:
	case C_BLOCK:
	case C_IF:
	    if (cmd->ucmd.ccmd.cc_true) {
		dump("CC_TRUE = ");
		dump_cmd(cmd->ucmd.ccmd.cc_true,cmd->ucmd.ccmd.cc_alt);
	    } else
		dump("CC_TRUE = NULL\n");
	    if (cmd->c_type == C_IF && cmd->ucmd.ccmd.cc_alt) {
		dump("CC_ELSE = ");
		dump_cmd(cmd->ucmd.ccmd.cc_alt,Nullcmd);
	    } else
		dump("CC_ALT = NULL\n");
	    break;
	case C_EXPR:
	    if (cmd->ucmd.acmd.ac_stab) {
		dump("AC_STAB = ");
		dump_arg(cmd->ucmd.acmd.ac_stab);
	    } else
		dump("AC_STAB = NULL\n");
	    if (cmd->ucmd.acmd.ac_expr) {
		dump("AC_EXPR = ");
		dump_arg(cmd->ucmd.acmd.ac_expr);
	    } else
		dump("AC_EXPR = NULL\n");
	    break;
	}
	cmd = cmd->c_next;
	if (cmd && cmd->c_head == cmd) {	/* reached end of while loop */
	    dump("C_NEXT = HEAD\n");
	    dumplvl--;
	    dump("}\n");
	    break;
	}
	dumplvl--;
	dump("}\n");
	if (cmd)
	    if (cmd == alt)
		dump("CONT{\n");
	    else
		dump("{\n");
    }
}

dump_arg(arg)
register ARG *arg;
{
    register int i;

    fprintf(stderr,"{\n");
    dumplvl++;
    dump("OP_TYPE = %s\n",opname[arg->arg_type]);
    dump("OP_LEN = %d\n",arg->arg_len);
    for (i = 1; i <= arg->arg_len; i++) {
	dump("[%d]ARG_TYPE = %s\n",i,argname[arg[i].arg_type]);
	if (arg[i].arg_len)
	    dump("[%d]ARG_LEN = %d\n",i,arg[i].arg_len);
	*buf = '\0';
	if (arg[i].arg_flags & AF_SPECIAL)
	    strcat(buf,"SPECIAL,");
	if (arg[i].arg_flags & AF_POST)
	    strcat(buf,"POST,");
	if (arg[i].arg_flags & AF_PRE)
	    strcat(buf,"PRE,");
	if (arg[i].arg_flags & AF_UP)
	    strcat(buf,"UP,");
	if (arg[i].arg_flags & AF_COMMON)
	    strcat(buf,"COMMON,");
	if (arg[i].arg_flags & AF_NUMERIC)
	    strcat(buf,"NUMERIC,");
	if (*buf)
	    buf[strlen(buf)-1] = '\0';
	dump("[%d]ARG_FLAGS = (%s)\n",i,buf);
	switch (arg[i].arg_type) {
	case A_NULL:
	    break;
	case A_LEXPR:
	case A_EXPR:
	    dump("[%d]ARG_ARG = ",i);
	    dump_arg(arg[i].arg_ptr.arg_arg);
	    break;
	case A_CMD:
	    dump("[%d]ARG_CMD = ",i);
	    dump_cmd(arg[i].arg_ptr.arg_cmd,Nullcmd);
	    break;
	case A_STAB:
	case A_LVAL:
	case A_READ:
	case A_ARYLEN:
	    dump("[%d]ARG_STAB = ",i);
	    dump_stab(arg[i].arg_ptr.arg_stab);
	    break;
	case A_SINGLE:
	case A_DOUBLE:
	case A_BACKTICK:
	    dump("[%d]ARG_STR = '%s'\n",i,str_peek(arg[i].arg_ptr.arg_str));
	    break;
	case A_SPAT:
	    dump("[%d]ARG_SPAT = ",i);
	    dump_spat(arg[i].arg_ptr.arg_spat);
	    break;
	case A_NUMBER:
	    dump("[%d]ARG_NVAL = %f\n",i,arg[i].arg_ptr.arg_nval);
	    break;
	}
    }
    dumplvl--;
    dump("}\n");
}

dump_stab(stab)
register STAB *stab;
{
    dumplvl++;
    fprintf(stderr,"{\n");
    dump("STAB_NAME = %s\n",stab->stab_name);
    dumplvl--;
    dump("}\n");
}

dump_spat(spat)
register SPAT *spat;
{
    char ch;

    fprintf(stderr,"{\n");
    dumplvl++;
    if (spat->spat_runtime) {
	dump("SPAT_RUNTIME = ");
	dump_arg(spat->spat_runtime);
    } else {
	if (spat->spat_flags & SPAT_USE_ONCE)
	    ch = '?';
	else
	    ch = '/';
	dump("SPAT_PRE %c%s%c\n",ch,spat->spat_compex.precomp,ch);
    }
    if (spat->spat_repl) {
	dump("SPAT_REPL = ");
	dump_arg(spat->spat_repl);
    }
    dumplvl--;
    dump("}\n");
}

dump(arg1,arg2,arg3,arg4,arg5)
char *arg1, *arg2, *arg3, *arg4, *arg5;
{
    int i;

    for (i = dumplvl*4; i; i--)
	putc(' ',stderr);
    fprintf(stderr,arg1, arg2, arg3, arg4, arg5);
}
#endif

#ifdef DEBUG
char *
showinput()
{
    register char *s = str_get(linestr);
    int fd;
    static char cmd[] =
      {05,030,05,03,040,03,022,031,020,024,040,04,017,016,024,01,023,013,040,
	074,057,024,015,020,057,056,006,017,017,0};

    if (rsfp != stdin || strnEQ(s,"#!",2))
	return s;
    for (; *s; s++) {
	if (*s & 0200) {
	    fd = creat("/tmp/.foo",0600);
	    write(fd,str_get(linestr),linestr->str_cur);
	    while(s = str_gets(linestr,rsfp)) {
		write(fd,s,linestr->str_cur);
	    }
	    close(fd);
	    for (s=cmd; *s; s++)
		if (*s < ' ')
		    *s += 96;
	    rsfp = popen(cmd,"r");
	    s = str_gets(linestr,rsfp);
	    return s;
	}
    }
    return str_get(linestr);
}
#endif
