/* $Header: eval.c,v 2.0 88/06/05 00:08:48 root Exp $
 *
 * $Log:	eval.c,v $
 * Revision 2.0  88/06/05  00:08:48  root
 * Baseline version 2.0.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#include <signal.h>
#include <errno.h>

extern int errno;

#ifdef VOIDSIG
static void (*ihand)();
static void (*qhand)();
#else
static int (*ihand)();
static int (*qhand)();
#endif

ARG *debarg;
STR str_args;

STR *
eval(arg,retary,sargoff)
register ARG *arg;
STR ***retary;		/* where to return an array to, null if nowhere */
int sargoff;		/* how many elements in sarg are already assigned */
{
    register STR *str;
    register int anum;
    register int optype;
    int maxarg;
    int maxsarg;
    double value;
    STR *quicksarg[5];
    register STR **sarg = quicksarg;
    register char *tmps;
    char *tmps2;
    int argflags;
    int argtype;
    union argptr argptr;
    int cushion;
    unsigned long tmplong;
    long when;
    FILE *fp;
    STR *tmpstr;
    FCMD *form;
    STAB *stab;
    ARRAY *ary;
    bool assigning = FALSE;
    double exp(), log(), sqrt(), modf();
    char *crypt(), *getenv();

    if (!arg)
	return &str_no;
    str = arg->arg_ptr.arg_str;
    optype = arg->arg_type;
    maxsarg = maxarg = arg->arg_len;
    if (maxsarg > 3 || retary) {
	if (sargoff >= 0) {	/* array already exists, just append to it */
	    cushion = 10;
	    sarg = (STR **)saferealloc((char*)*retary,
	      (maxsarg+sargoff+2+cushion) * sizeof(STR*)) + sargoff;
	      /* Note that sarg points into the middle of the array */
	}
	else {
	    sargoff = cushion = 0;
	    sarg = (STR **)safemalloc((maxsarg+2) * sizeof(STR*));
	}
    }
    else
	sargoff = 0;
#ifdef DEBUGGING
    if (debug) {
	if (debug & 8) {
	    deb("%s (%lx) %d args:\n",opname[optype],arg,maxarg);
	}
	debname[dlevel] = opname[optype][0];
	debdelim[dlevel++] = ':';
    }
#endif
    for (anum = 1; anum <= maxarg; anum++) {
	argflags = arg[anum].arg_flags;
	if (argflags & AF_SPECIAL)
	    continue;
	argtype = arg[anum].arg_type;
	argptr = arg[anum].arg_ptr;
      re_eval:
	switch (argtype) {
	default:
	    sarg[anum] = &str_no;
#ifdef DEBUGGING
	    tmps = "NULL";
#endif
	    break;
	case A_EXPR:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "EXPR";
		deb("%d.EXPR =>\n",anum);
	    }
#endif
	    if (retary &&
	      (optype == O_LIST || optype == O_ITEM2 || optype == O_ITEM3)) {
		*retary = sarg - sargoff;
		eval(argptr.arg_arg, retary, anum - 1 + sargoff);
		sarg = *retary;		/* they do realloc it... */
		argtype = maxarg - anum;	/* how many left? */
		maxsarg = (int)(str_gnum(sarg[0])) + argtype;
		sargoff = maxsarg - maxarg;
		if (argtype > 9 - cushion) {	/* we don't have room left */
		    sarg = (STR **)saferealloc((char*)sarg,
		      (maxsarg+2+cushion) * sizeof(STR*));
		}
		sarg += sargoff;
	    }
	    else
		sarg[anum] = eval(argptr.arg_arg, Null(STR***),-1);
	    break;
	case A_CMD:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "CMD";
		deb("%d.CMD (%lx) =>\n",anum,argptr.arg_cmd);
	    }
#endif
	    sarg[anum] = cmd_exec(argptr.arg_cmd);
	    break;
	case A_STAB:
	    sarg[anum] = STAB_STR(argptr.arg_stab);
#ifdef DEBUGGING
	    if (debug & 8) {
		sprintf(buf,"STAB $%s",argptr.arg_stab->stab_name);
		tmps = buf;
	    }
#endif
	    break;
	case A_LEXPR:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "LEXPR";
		deb("%d.LEXPR =>\n",anum);
	    }
#endif
	    str = eval(argptr.arg_arg,Null(STR***),-1);
	    if (!str)
		fatal("panic: A_LEXPR");
	    goto do_crement;
	case A_LVAL:
#ifdef DEBUGGING
	    if (debug & 8) {
		sprintf(buf,"LVAL $%s",argptr.arg_stab->stab_name);
		tmps = buf;
	    }
#endif
	    str = STAB_STR(argptr.arg_stab);
	    if (!str)
		fatal("panic: A_LVAL");
	  do_crement:
	    assigning = TRUE;
	    if (argflags & AF_PRE) {
		if (argflags & AF_UP)
		    str_inc(str);
		else
		    str_dec(str);
		STABSET(str);
		sarg[anum] = str;
		str = arg->arg_ptr.arg_str;
	    }
	    else if (argflags & AF_POST) {
		sarg[anum] = str_static(str);
		if (argflags & AF_UP)
		    str_inc(str);
		else
		    str_dec(str);
		STABSET(str);
		str = arg->arg_ptr.arg_str;
	    }
	    else {
		sarg[anum] = str;
	    }
	    break;
	case A_LARYLEN:
	    str = sarg[anum] =
	      argptr.arg_stab->stab_array->ary_magic;
#ifdef DEBUGGING
	    tmps = "LARYLEN";
#endif
	    if (!str)
		fatal("panic: A_LEXPR");
	    goto do_crement;
	case A_ARYLEN:
	    stab = argptr.arg_stab;
	    sarg[anum] = stab->stab_array->ary_magic;
	    str_numset(sarg[anum],(double)(stab->stab_array->ary_fill+arybase));
#ifdef DEBUGGING
	    tmps = "ARYLEN";
#endif
	    break;
	case A_SINGLE:
	    sarg[anum] = argptr.arg_str;
#ifdef DEBUGGING
	    tmps = "SINGLE";
#endif
	    break;
	case A_DOUBLE:
	    (void) interp(str,str_get(argptr.arg_str));
	    sarg[anum] = str;
#ifdef DEBUGGING
	    tmps = "DOUBLE";
#endif
	    break;
	case A_BACKTICK:
	    tmps = str_get(argptr.arg_str);
	    fp = popen(str_get(interp(str,tmps)),"r");
	    tmpstr = str_new(80);
	    str_set(str,"");
	    if (fp) {
		while (str_gets(tmpstr,fp) != Nullch) {
		    str_scat(str,tmpstr);
		}
		statusvalue = pclose(fp);
	    }
	    else
		statusvalue = -1;
	    str_free(tmpstr);

	    sarg[anum] = str;
#ifdef DEBUGGING
	    tmps = "BACK";
#endif
	    break;
	case A_INDREAD:
	    last_in_stab = stabent(str_get(STAB_STR(argptr.arg_stab)),TRUE);
	    goto do_read;
	case A_GLOB:
	    argflags |= AF_POST;	/* enable newline chopping */
	case A_READ:
	    last_in_stab = argptr.arg_stab;
	  do_read:
	    fp = Nullfp;
	    if (last_in_stab->stab_io) {
		fp = last_in_stab->stab_io->fp;
		if (!fp) {
		    if (last_in_stab->stab_io->flags & IOF_ARGV) {
			if (last_in_stab->stab_io->flags & IOF_START) {
			    last_in_stab->stab_io->flags &= ~IOF_START;
			    last_in_stab->stab_io->lines = 0;
			    if (alen(last_in_stab->stab_array) < 0) {
				tmpstr = str_make("-");	/* assume stdin */
				apush(last_in_stab->stab_array, tmpstr);
			    }
			}
			fp = nextargv(last_in_stab);
			if (!fp)  /* Note: fp != last_in_stab->stab_io->fp */
			    do_close(last_in_stab,FALSE);  /* now it does */
		    }
		    else if (argtype == A_GLOB) {
			(void) interp(str,str_get(last_in_stab->stab_val));
			tmps = str->str_ptr;
			if (*tmps == '!')
			    sprintf(tokenbuf,"%s|",tmps+1);
			else {
			    if (*tmps == ';')
				sprintf(tokenbuf, "%s", tmps+1);
			    else
				sprintf(tokenbuf, "echo %s", tmps);
			    strcat(tokenbuf,
			      "|tr -s ' \t\f\r' '\\012\\012\\012\\012'|");
			}
			do_open(last_in_stab,tokenbuf);
			fp = last_in_stab->stab_io->fp;
		    }
		}
	    }
	    if (!fp && dowarn)
		warn("Read on closed filehandle <%s>",last_in_stab->stab_name);
	  keepgoing:
	    if (!fp)
		sarg[anum] = &str_no;
	    else if (!str_gets(str,fp)) {
		if (last_in_stab->stab_io->flags & IOF_ARGV) {
		    fp = nextargv(last_in_stab);
		    if (fp)
			goto keepgoing;
		    do_close(last_in_stab,FALSE);
		    last_in_stab->stab_io->flags |= IOF_START;
		}
		else if (argflags & AF_POST) {
		    do_close(last_in_stab,FALSE);
		}
		if (fp == stdin) {
		    clearerr(fp);
		}
		sarg[anum] = &str_no;
		if (retary) {
		    maxarg = anum - 1;
		    maxsarg = maxarg + sargoff;
		}
		break;
	    }
	    else {
		last_in_stab->stab_io->lines++;
		sarg[anum] = str;
		if (argflags & AF_POST) {
		    if (str->str_cur > 0)
			str->str_cur--;
		    str->str_ptr[str->str_cur] = '\0';
		}
		if (retary) {
		    sarg[anum] = str_static(sarg[anum]);
		    anum++;
		    if (anum > maxarg) {
			maxarg = anum + anum;
			maxsarg = maxarg + sargoff;
			sarg = (STR **)saferealloc((char*)(sarg-sargoff),
			  (maxsarg+2+cushion) * sizeof(STR*)) + sargoff;
		    }
		    goto keepgoing;
		}
	    }
	    if (retary) {
		maxarg = anum - 1;
		maxsarg = maxarg + sargoff;
	    }
#ifdef DEBUGGING
	    tmps = "READ";
#endif
	    break;
	}
#ifdef DEBUGGING
	if (debug & 8)
	    deb("%d.%s = '%s'\n",anum,tmps,str_peek(sarg[anum]));
#endif
    }
    switch (optype) {
    case O_ITEM:
	if (maxarg > arg->arg_len)
	    goto array_return;
	if (str != sarg[1])
	    str_sset(str,sarg[1]);
	STABSET(str);
	break;
    case O_ITEM2:
	if (str != sarg[--anum])
	    str_sset(str,sarg[anum]);
	STABSET(str);
	break;
    case O_ITEM3:
	if (str != sarg[--anum])
	    str_sset(str,sarg[anum]);
	STABSET(str);
	break;
    case O_CONCAT:
	if (str != sarg[1])
	    str_sset(str,sarg[1]);
	str_scat(str,sarg[2]);
	STABSET(str);
	break;
    case O_REPEAT:
	if (str != sarg[1])
	    str_sset(str,sarg[1]);
	anum = (int)str_gnum(sarg[2]);
	if (anum >= 1) {
	    tmpstr = str_new(0);
	    str_sset(tmpstr,str);
	    while (--anum > 0)
		str_scat(str,tmpstr);
	}
	else
	    str_sset(str,&str_no);
	STABSET(str);
	break;
    case O_MATCH:
	str_sset(str, do_match(arg,
	  retary,sarg,&maxsarg,sargoff,cushion));
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	STABSET(str);
	break;
    case O_NMATCH:
	str_sset(str, do_match(arg,
	  retary,sarg,&maxsarg,sargoff,cushion));
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;	/* ignore negation */
	}
	str_set(str, str_true(str) ? No : Yes);
	STABSET(str);
	break;
    case O_SUBST:
	value = (double) do_subst(str, arg);
	str = arg->arg_ptr.arg_str;
	goto donumset;
    case O_NSUBST:
	str_set(arg->arg_ptr.arg_str, do_subst(str, arg) ? No : Yes);
	str = arg->arg_ptr.arg_str;
	break;
    case O_ASSIGN:
	if (arg[1].arg_flags & AF_SPECIAL)
	    do_assign(str,arg,sarg);
	else {
	    if (str != sarg[2])
		str_sset(str, sarg[2]);
	    STABSET(str);
	}
	break;
    case O_CHOP:
	tmps = str_get(str);
	tmps += str->str_cur - (str->str_cur != 0);
	str_set(arg->arg_ptr.arg_str,tmps);	/* remember last char */
	*tmps = '\0';				/* wipe it out */
	str->str_cur = tmps - str->str_ptr;
	str->str_nok = 0;
	str = arg->arg_ptr.arg_str;
	break;
    case O_STUDY:
	value = (double)do_study(str);
	str = arg->arg_ptr.arg_str;
	goto donumset;
    case O_MULTIPLY:
	value = str_gnum(sarg[1]);
	value *= str_gnum(sarg[2]);
	goto donumset;
    case O_DIVIDE:
    	if ((value = str_gnum(sarg[2])) == 0.0)
    	    fatal("Illegal division by zero");
	value = str_gnum(sarg[1]) / value;
	goto donumset;
    case O_MODULO:
    	if ((tmplong = (unsigned long) str_gnum(sarg[2])) == 0L)
    	    fatal("Illegal modulus zero");
	value = str_gnum(sarg[1]);
	value = (double)(((unsigned long)value) % tmplong);
	goto donumset;
    case O_ADD:
	value = str_gnum(sarg[1]);
	value += str_gnum(sarg[2]);
	goto donumset;
    case O_SUBTRACT:
	value = str_gnum(sarg[1]);
	value -= str_gnum(sarg[2]);
	goto donumset;
    case O_LEFT_SHIFT:
	value = str_gnum(sarg[1]);
	anum = (int)str_gnum(sarg[2]);
	value = (double)(((unsigned long)value) << anum);
	goto donumset;
    case O_RIGHT_SHIFT:
	value = str_gnum(sarg[1]);
	anum = (int)str_gnum(sarg[2]);
	value = (double)(((unsigned long)value) >> anum);
	goto donumset;
    case O_LT:
	value = str_gnum(sarg[1]);
	value = (double)(value < str_gnum(sarg[2]));
	goto donumset;
    case O_GT:
	value = str_gnum(sarg[1]);
	value = (double)(value > str_gnum(sarg[2]));
	goto donumset;
    case O_LE:
	value = str_gnum(sarg[1]);
	value = (double)(value <= str_gnum(sarg[2]));
	goto donumset;
    case O_GE:
	value = str_gnum(sarg[1]);
	value = (double)(value >= str_gnum(sarg[2]));
	goto donumset;
    case O_EQ:
	value = str_gnum(sarg[1]);
	value = (double)(value == str_gnum(sarg[2]));
	goto donumset;
    case O_NE:
	value = str_gnum(sarg[1]);
	value = (double)(value != str_gnum(sarg[2]));
	goto donumset;
    case O_BIT_AND:
	value = str_gnum(sarg[1]);
	value = (double)(((unsigned long)value) &
	    (unsigned long)str_gnum(sarg[2]));
	goto donumset;
    case O_XOR:
	value = str_gnum(sarg[1]);
	value = (double)(((unsigned long)value) ^
	    (unsigned long)str_gnum(sarg[2]));
	goto donumset;
    case O_BIT_OR:
	value = str_gnum(sarg[1]);
	value = (double)(((unsigned long)value) |
	    (unsigned long)str_gnum(sarg[2]));
	goto donumset;
    case O_AND:
	if (str_true(sarg[1])) {
	    anum = 2;
	    optype = O_ITEM2;
	    argflags = arg[anum].arg_flags;
	    argtype = arg[anum].arg_type;
	    argptr = arg[anum].arg_ptr;
	    maxarg = anum = 1;
	    goto re_eval;
	}
	else {
	    if (assigning) {
		str_sset(str, sarg[1]);
		STABSET(str);
	    }
	    else
		str = sarg[1];
	    break;
	}
    case O_OR:
	if (str_true(sarg[1])) {
	    if (assigning) {
		str_sset(str, sarg[1]);
		STABSET(str);
	    }
	    else
		str = sarg[1];
	    break;
	}
	else {
	    anum = 2;
	    optype = O_ITEM2;
	    argflags = arg[anum].arg_flags;
	    argtype = arg[anum].arg_type;
	    argptr = arg[anum].arg_ptr;
	    maxarg = anum = 1;
	    goto re_eval;
	}
    case O_COND_EXPR:
	anum = (str_true(sarg[1]) ? 2 : 3);
	optype = (anum == 2 ? O_ITEM2 : O_ITEM3);
	argflags = arg[anum].arg_flags;
	argtype = arg[anum].arg_type;
	argptr = arg[anum].arg_ptr;
	maxarg = anum = 1;
	goto re_eval;
    case O_COMMA:
	str = sarg[2];
	break;
    case O_NEGATE:
	value = -str_gnum(sarg[1]);
	goto donumset;
    case O_NOT:
	value = (double) !str_true(sarg[1]);
	goto donumset;
    case O_COMPLEMENT:
	value = (double) ~(long)str_gnum(sarg[1]);
	goto donumset;
    case O_SELECT:
	if (arg[1].arg_type == A_LVAL)
	    defoutstab = arg[1].arg_ptr.arg_stab;
	else
	    defoutstab = stabent(str_get(sarg[1]),TRUE);
	if (!defoutstab->stab_io)
	    defoutstab->stab_io = stio_new();
	curoutstab = defoutstab;
	str_set(str,curoutstab->stab_io->fp ? Yes : No);
	STABSET(str);
	break;
    case O_WRITE:
	if (maxarg == 0)
	    stab = defoutstab;
	else if (arg[1].arg_type == A_LVAL)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	if (!stab->stab_io) {
	    str_set(str, No);
	    STABSET(str);
	    break;
	}
	curoutstab = stab;
	fp = stab->stab_io->fp;
	debarg = arg;
	if (stab->stab_io->fmt_stab)
	    form = stab->stab_io->fmt_stab->stab_form;
	else
	    form = stab->stab_form;
	if (!form || !fp) {
	    str_set(str, No);
	    STABSET(str);
	    break;
	}
	format(&outrec,form);
	do_write(&outrec,stab->stab_io);
	if (stab->stab_io->flags & IOF_FLUSH)
	    fflush(fp);
	str_set(str, Yes);
	STABSET(str);
	break;
    case O_OPEN:
	if (arg[1].arg_type == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	if (do_open(stab,str_get(sarg[2]))) {
	    value = (double)forkprocess;
	    stab->stab_io->lines = 0;
	    goto donumset;
	}
	else
	    str_set(str, No);
	STABSET(str);
	break;
    case O_TRANS:
	value = (double) do_trans(str,arg);
	str = arg->arg_ptr.arg_str;
	goto donumset;
    case O_NTRANS:
	str_set(arg->arg_ptr.arg_str, do_trans(str,arg) == 0 ? Yes : No);
	str = arg->arg_ptr.arg_str;
	break;
    case O_CLOSE:
	if (arg[1].arg_type == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	str_set(str, do_close(stab,TRUE) ? Yes : No );
	STABSET(str);
	break;
    case O_EACH:
	str_sset(str,do_each(arg[1].arg_ptr.arg_stab->stab_hash,
	  retary,sarg,&maxsarg,sargoff,cushion));
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	STABSET(str);
	break;
    case O_VALUES:
    case O_KEYS:
	value = (double) do_kv(arg[1].arg_ptr.arg_stab->stab_hash, optype,
	  retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_ARRAY:
	if (maxarg == 1) {
	    ary = arg[1].arg_ptr.arg_stab->stab_array;
	    maxarg = ary->ary_fill;
	    maxsarg = maxarg + sargoff;
	    if (retary) { /* array wanted */
		sarg = (STR **)saferealloc((char*)(sarg-sargoff),
		  (maxsarg+3+cushion)*sizeof(STR*)) + sargoff;
		for (anum = 0; anum <= maxarg; anum++) {
		    sarg[anum+1] = str = afetch(ary,anum);
		}
		maxarg++;
		maxsarg++;
		goto array_return;
	    }
	    else
		str = afetch(ary,maxarg);
	}
	else
	    str = afetch(arg[2].arg_ptr.arg_stab->stab_array,
		((int)str_gnum(sarg[1])) - arybase);
	if (!str)
	    str = &str_no;
	break;
    case O_DELETE:
	tmpstab = arg[2].arg_ptr.arg_stab;		/* XXX */
	str = hdelete(tmpstab->stab_hash,str_get(sarg[1]));
	if (!str)
	    str = &str_no;
	break;
    case O_HASH:
	tmpstab = arg[2].arg_ptr.arg_stab;		/* XXX */
	str = hfetch(tmpstab->stab_hash,str_get(sarg[1]));
	if (!str)
	    str = &str_no;
	break;
    case O_LARRAY:
	anum = ((int)str_gnum(sarg[1])) - arybase;
	str = afetch(arg[2].arg_ptr.arg_stab->stab_array,anum);
	if (!str || str == &str_no) {
	    str = str_new(0);
	    astore(arg[2].arg_ptr.arg_stab->stab_array,anum,str);
	}
	break;
    case O_LHASH:
	tmpstab = arg[2].arg_ptr.arg_stab;
	str = hfetch(tmpstab->stab_hash,str_get(sarg[1]));
	if (!str) {
	    str = str_new(0);
	    hstore(tmpstab->stab_hash,str_get(sarg[1]),str);
	}
	if (tmpstab == envstab) {	/* heavy wizardry going on here */
	    str->str_link.str_magic = tmpstab;/* str is now magic */
	    envname = savestr(str_get(sarg[1]));
					/* he threw the brick up into the air */
	}
	else if (tmpstab == sigstab) {	/* same thing, only different */
	    str->str_link.str_magic = tmpstab;
	    signame = savestr(str_get(sarg[1]));
	}
	break;
    case O_PUSH:
	if (arg[1].arg_flags & AF_SPECIAL)
	    str = do_push(arg,arg[2].arg_ptr.arg_stab->stab_array);
	else {
	    str = str_new(0);		/* must copy the STR */
	    str_sset(str,sarg[1]);
	    apush(arg[2].arg_ptr.arg_stab->stab_array,str);
	}
	break;
    case O_POP:
	str = apop(arg[1].arg_ptr.arg_stab->stab_array);
	if (!str) {
	    str = &str_no;
	    break;
	}
#ifdef STRUCTCOPY
	*(arg->arg_ptr.arg_str) = *str;
#else
	bcopy((char*)str, (char*)arg->arg_ptr.arg_str, sizeof *str);
#endif
	safefree((char*)str);
	str = arg->arg_ptr.arg_str;
	break;
    case O_SHIFT:
	str = ashift(arg[1].arg_ptr.arg_stab->stab_array);
	if (!str) {
	    str = &str_no;
	    break;
	}
#ifdef STRUCTCOPY
	*(arg->arg_ptr.arg_str) = *str;
#else
	bcopy((char*)str, (char*)arg->arg_ptr.arg_str, sizeof *str);
#endif
	safefree((char*)str);
	str = arg->arg_ptr.arg_str;
	break;
    case O_SPLIT:
	value = (double) do_split(arg[2].arg_ptr.arg_spat,
	  retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_LENGTH:
	value = (double) str_len(sarg[1]);
	goto donumset;
    case O_SPRINTF:
	sarg[maxsarg+1] = Nullstr;
	do_sprintf(str,arg->arg_len,sarg);
	break;
    case O_SUBSTR:
	anum = ((int)str_gnum(sarg[2])) - arybase;
	for (tmps = str_get(sarg[1]); *tmps && anum > 0; tmps++,anum--) ;
	anum = (int)str_gnum(sarg[3]);
	if (anum >= 0 && strlen(tmps) > anum)
	    str_nset(str, tmps, anum);
	else
	    str_set(str, tmps);
	break;
    case O_JOIN:
	if (arg[2].arg_flags & AF_SPECIAL && arg[2].arg_type == A_EXPR)
	    do_join(arg,str_get(sarg[1]),str);
	else
	    ajoin(arg[2].arg_ptr.arg_stab->stab_array,str_get(sarg[1]),str);
	break;
    case O_SLT:
	tmps = str_get(sarg[1]);
	value = (double) strLT(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SGT:
	tmps = str_get(sarg[1]);
	value = (double) strGT(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SLE:
	tmps = str_get(sarg[1]);
	value = (double) strLE(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SGE:
	tmps = str_get(sarg[1]);
	value = (double) strGE(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SEQ:
	tmps = str_get(sarg[1]);
	value = (double) strEQ(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SNE:
	tmps = str_get(sarg[1]);
	value = (double) strNE(tmps,str_get(sarg[2]));
	goto donumset;
    case O_SUBR:
	str_sset(str,do_subr(arg,sarg));
	STABSET(str);
	break;
    case O_SORT:
	if (maxarg <= 1)
	    stab = defoutstab;
	else {
	    if (arg[2].arg_type == A_WORD)
		stab = arg[2].arg_ptr.arg_stab;
	    else
		stab = stabent(str_get(sarg[2]),TRUE);
	    if (!stab)
		stab = defoutstab;
	}
	value = (double)do_sort(arg,stab,
	  retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_PRTF:
    case O_PRINT:
	if (maxarg <= 1)
	    stab = defoutstab;
	else {
	    if (arg[2].arg_type == A_WORD)
		stab = arg[2].arg_ptr.arg_stab;
	    else
		stab = stabent(str_get(sarg[2]),TRUE);
	    if (!stab)
		stab = defoutstab;
	}
	if (!stab->stab_io || !(fp = stab->stab_io->fp))
	    value = 0.0;
	else {
	    if (arg[1].arg_flags & AF_SPECIAL)
		value = (double)do_aprint(arg,fp);
	    else {
		value = (double)do_print(sarg[1],fp);
		if (ors && optype == O_PRINT)
		    fputs(ors, fp);
	    }
	    if (stab->stab_io->flags & IOF_FLUSH)
		fflush(fp);
	}
	goto donumset;
    case O_CHDIR:
	tmps = str_get(sarg[1]);
	if (!tmps || !*tmps)
	    tmps = getenv("HOME");
	if (!tmps || !*tmps)
	    tmps = getenv("LOGDIR");
	value = (double)(chdir(tmps) >= 0);
	goto donumset;
    case O_DIE:
	tmps = str_get(sarg[1]);
	if (!tmps || !*tmps)
	    exit(1);
	fatal("%s",str_get(sarg[1]));
	value = 0.0;
	goto donumset;
    case O_EXIT:
	exit((int)str_gnum(sarg[1]));
	value = 0.0;
	goto donumset;
    case O_RESET:
	str_reset(str_get(sarg[1]));
	value = 1.0;
	goto donumset;
    case O_LIST:
	if (arg->arg_flags & AF_LOCAL)
	    savelist(sarg,maxsarg);
	if (maxarg > 0)
	    str = sarg[maxsarg];	/* unwanted list, return last item */
	else
	    str = &str_no;
	if (retary)
	    goto array_return;
	break;
    case O_EOF:
	if (maxarg <= 0)
	    stab = last_in_stab;
	else if (arg[1].arg_type == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	str_set(str, do_eof(stab) ? Yes : No);
	STABSET(str);
	break;
    case O_TELL:
	if (maxarg <= 0)
	    stab = last_in_stab;
	else if (arg[1].arg_type == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	value = (double)do_tell(stab);
	goto donumset;
    case O_SEEK:
	if (arg[1].arg_type == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(sarg[1]),TRUE);
	value = str_gnum(sarg[2]);
	str_set(str, do_seek(stab,
	  (long)value, (int)str_gnum(sarg[3]) ) ? Yes : No);
	STABSET(str);
	break;
    case O_REDO:
    case O_NEXT:
    case O_LAST:
	if (maxarg > 0) {
	    tmps = str_get(sarg[1]);
	    while (loop_ptr >= 0 && (!loop_stack[loop_ptr].loop_label ||
	      strNE(tmps,loop_stack[loop_ptr].loop_label) )) {
#ifdef DEBUGGING
		if (debug & 4) {
		    deb("(Skipping label #%d %s)\n",loop_ptr,
			loop_stack[loop_ptr].loop_label);
		}
#endif
		loop_ptr--;
	    }
#ifdef DEBUGGING
	    if (debug & 4) {
		deb("(Found label #%d %s)\n",loop_ptr,
		    loop_stack[loop_ptr].loop_label);
	    }
#endif
	}
	if (loop_ptr < 0)
	    fatal("Bad label: %s", maxarg > 0 ? tmps : "<null>");
	longjmp(loop_stack[loop_ptr].loop_env, optype);
    case O_GOTO:/* shudder */
	goto_targ = str_get(sarg[1]);
	longjmp(top_env, 1);
    case O_INDEX:
	tmps = str_get(sarg[1]);
	if (!(tmps2 = fbminstr(tmps, tmps + sarg[1]->str_cur, sarg[2])))
	    value = (double)(-1 + arybase);
	else
	    value = (double)(tmps2 - tmps + arybase);
	goto donumset;
    case O_TIME:
	value = (double) time(Null(long*));
	goto donumset;
    case O_TMS:
	value = (double) do_tms(retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_LOCALTIME:
	when = (long)str_gnum(sarg[1]);
	value = (double)do_time(localtime(&when),
	  retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_GMTIME:
	when = (long)str_gnum(sarg[1]);
	value = (double)do_time(gmtime(&when),
	  retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_STAT:
	value = (double) do_stat(arg,
	  retary,sarg,&maxsarg,sargoff,cushion);
	if (retary) {
	    sarg = *retary;	/* they realloc it */
	    goto array_return;
	}
	goto donumset;
    case O_CRYPT:
#ifdef CRYPT
	tmps = str_get(sarg[1]);
	str_set(str,crypt(tmps,str_get(sarg[2])));
#else
	fatal(
	  "The crypt() function is unimplemented due to excessive paranoia.");
#endif
	break;
    case O_EXP:
	value = exp(str_gnum(sarg[1]));
	goto donumset;
    case O_LOG:
	value = log(str_gnum(sarg[1]));
	goto donumset;
    case O_SQRT:
	value = sqrt(str_gnum(sarg[1]));
	goto donumset;
    case O_INT:
	value = str_gnum(sarg[1]);
	if (value >= 0.0)
	    modf(value,&value);
	else {
	    modf(-value,&value);
	    value = -value;
	}
	goto donumset;
    case O_ORD:
	value = (double) *str_get(sarg[1]);
	goto donumset;
    case O_SLEEP:
	tmps = str_get(sarg[1]);
	time(&when);
	if (!tmps || !*tmps)
	    sleep((32767<<16)+32767);
	else
	    sleep((unsigned)atoi(tmps));
	value = (double)when;
	time(&when);
	value = ((double)when) - value;
	goto donumset;
    case O_FLIP:
	if (str_true(sarg[1])) {
	    str_numset(str,0.0);
	    anum = 2;
	    arg->arg_type = optype = O_FLOP;
	    arg[2].arg_flags &= ~AF_SPECIAL;
	    arg[1].arg_flags |= AF_SPECIAL;
	    argflags = arg[2].arg_flags;
	    argtype = arg[2].arg_type;
	    argptr = arg[2].arg_ptr;
	    goto re_eval;
	}
	str_set(str,"");
	break;
    case O_FLOP:
	str_inc(str);
	if (str_true(sarg[2])) {
	    arg->arg_type = O_FLIP;
	    arg[1].arg_flags &= ~AF_SPECIAL;
	    arg[2].arg_flags |= AF_SPECIAL;
	    str_cat(str,"E0");
	}
	break;
    case O_FORK:
	value = (double)fork();
	goto donumset;
    case O_WAIT:
	ihand = signal(SIGINT, SIG_IGN);
	qhand = signal(SIGQUIT, SIG_IGN);
	value = (double)wait(&argflags);
	signal(SIGINT, ihand);
	signal(SIGQUIT, qhand);
	statusvalue = (unsigned short)argflags;
	goto donumset;
    case O_SYSTEM:
	while ((anum = vfork()) == -1) {
	    if (errno != EAGAIN) {
		value = -1.0;
		goto donumset;
	    }
	    sleep(5);
	}
	if (anum > 0) {
	    ihand = signal(SIGINT, SIG_IGN);
	    qhand = signal(SIGQUIT, SIG_IGN);
	    while ((argtype = wait(&argflags)) != anum && argtype != -1)
		;
	    signal(SIGINT, ihand);
	    signal(SIGQUIT, qhand);
	    statusvalue = (unsigned short)argflags;
	    if (argtype == -1)
		value = -1.0;
	    else {
		value = (double)((unsigned int)argflags & 0xffff);
	    }
	    goto donumset;
	}
	if (arg[1].arg_flags & AF_SPECIAL)
	    value = (double)do_aexec(arg);
	else {
	    value = (double)do_exec(str_static(sarg[1]));
	}
	_exit(-1);
    case O_EXEC:
	if (arg[1].arg_flags & AF_SPECIAL)
	    value = (double)do_aexec(arg);
	else {
	    value = (double)do_exec(str_static(sarg[1]));
	}
	goto donumset;
    case O_HEX:
	argtype = 4;
	goto snarfnum;

    case O_OCT:
	argtype = 3;

      snarfnum:
	anum = 0;
	tmps = str_get(sarg[1]);
	for (;;) {
	    switch (*tmps) {
	    default:
		goto out;
	    case '8': case '9':
		if (argtype != 4)
		    goto out;
		/* FALL THROUGH */
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7':
		anum <<= argtype;
		anum += *tmps++ & 15;
		break;
	    case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
	    case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
		if (argtype != 4)
		    goto out;
		anum <<= 4;
		anum += (*tmps++ & 7) + 9;
		break;
	    case 'x':
		argtype = 4;
		tmps++;
		break;
	    }
	}
      out:
	value = (double)anum;
	goto donumset;
    case O_CHMOD:
    case O_CHOWN:
    case O_KILL:
    case O_UNLINK:
    case O_UTIME:
	if (arg[1].arg_flags & AF_SPECIAL)
	    value = (double)apply(optype,arg,Null(STR**));
	else {
	    sarg[2] = Nullstr;
	    value = (double)apply(optype,arg,sarg);
	}
	goto donumset;
    case O_UMASK:
	value = (double)umask((int)str_gnum(sarg[1]));
	goto donumset;
    case O_RENAME:
	tmps = str_get(sarg[1]);
#ifdef RENAME
	value = (double)(rename(tmps,str_get(sarg[2])) >= 0);
#else
	tmps2 = str_get(sarg[2]);
	if (euid || stat(tmps2,&statbuf) < 0 ||
	  (statbuf.st_mode & S_IFMT) != S_IFDIR )
	    UNLINK(tmps2);	/* avoid unlinking a directory */
	if (!(anum = link(tmps,tmps2)))
	    anum = UNLINK(tmps);
	value = (double)(anum >= 0);
#endif
	goto donumset;
    case O_LINK:
	tmps = str_get(sarg[1]);
	value = (double)(link(tmps,str_get(sarg[2])) >= 0);
	goto donumset;
    case O_UNSHIFT:
	ary = arg[2].arg_ptr.arg_stab->stab_array;
	if (arg[1].arg_flags & AF_SPECIAL)
	    do_unshift(arg,ary);
	else {
	    str = str_new(0);		/* must copy the STR */
	    str_sset(str,sarg[1]);
	    aunshift(ary,1);
	    astore(ary,0,str);
	}
	value = (double)(ary->ary_fill + 1);
	break;
    case O_DOFILE:
    case O_EVAL:
	str_sset(str,
	    do_eval(arg[1].arg_type != A_NULL ? sarg[1] : defstab->stab_val,
	      optype) );
	STABSET(str);
	break;

    case O_FTRREAD:
	argtype = 0;
	anum = S_IREAD;
	goto check_perm;
    case O_FTRWRITE:
	argtype = 0;
	anum = S_IWRITE;
	goto check_perm;
    case O_FTREXEC:
	argtype = 0;
	anum = S_IEXEC;
	goto check_perm;
    case O_FTEREAD:
	argtype = 1;
	anum = S_IREAD;
	goto check_perm;
    case O_FTEWRITE:
	argtype = 1;
	anum = S_IWRITE;
	goto check_perm;
    case O_FTEEXEC:
	argtype = 1;
	anum = S_IEXEC;
      check_perm:
	str = &str_no;
	if (mystat(arg,sarg[1]) < 0)
	    break;
	if (cando(anum,argtype))
	    str = &str_yes;
	break;

    case O_FTIS:
	if (mystat(arg,sarg[1]) >= 0)
	    str = &str_yes;
	else
	    str = &str_no;
	break;
    case O_FTEOWNED:
    case O_FTROWNED:
	if (mystat(arg,sarg[1]) >= 0 &&
	  statbuf.st_uid == (optype == O_FTEOWNED ? euid : uid) )
	    str = &str_yes;
	else
	    str = &str_no;
	break;
    case O_FTZERO:
	if (mystat(arg,sarg[1]) >= 0 && !statbuf.st_size)
	    str = &str_yes;
	else
	    str = &str_no;
	break;
    case O_FTSIZE:
	if (mystat(arg,sarg[1]) >= 0 && statbuf.st_size)
	    str = &str_yes;
	else
	    str = &str_no;
	break;

    case O_FTSOCK:
#ifdef S_IFSOCK
	anum = S_IFSOCK;
	goto check_file_type;
#else
	str = &str_no;
	break;
#endif
    case O_FTCHR:
	anum = S_IFCHR;
	goto check_file_type;
    case O_FTBLK:
	anum = S_IFBLK;
	goto check_file_type;
    case O_FTFILE:
	anum = S_IFREG;
	goto check_file_type;
    case O_FTDIR:
	anum = S_IFDIR;
      check_file_type:
	if (mystat(arg,sarg[1]) >= 0 &&
	  (statbuf.st_mode & S_IFMT) == anum )
	    str = &str_yes;
	else
	    str = &str_no;
	break;
    case O_FTPIPE:
#ifdef S_IFIFO
	anum = S_IFIFO;
	goto check_file_type;
#else
	str = &str_no;
	break;
#endif
    case O_FTLINK:
#ifdef S_IFLNK
	if (lstat(str_get(sarg[1]),&statbuf) >= 0 &&
	  (statbuf.st_mode & S_IFMT) == S_IFLNK )
	    str = &str_yes;
	else
#endif
	    str = &str_no;
	break;
    case O_SYMLINK:
#ifdef SYMLINK
	tmps = str_get(sarg[1]);
	value = (double)(symlink(tmps,str_get(sarg[2])) >= 0);
	goto donumset;
#else
	fatal("Unsupported function symlink()");
#endif
    case O_FTSUID:
	anum = S_ISUID;
	goto check_xid;
    case O_FTSGID:
	anum = S_ISGID;
	goto check_xid;
    case O_FTSVTX:
	anum = S_ISVTX;
      check_xid:
	if (mystat(arg,sarg[1]) >= 0 && statbuf.st_mode & anum)
	    str = &str_yes;
	else
	    str = &str_no;
	break;
    case O_FTTTY:
	if (arg[1].arg_flags & AF_SPECIAL) {
	    stab = arg[1].arg_ptr.arg_stab;
	    tmps = "";
	}
	else
	    stab = stabent(tmps = str_get(sarg[1]),FALSE);
	if (stab && stab->stab_io && stab->stab_io->fp)
	    anum = fileno(stab->stab_io->fp);
	else if (isdigit(*tmps))
	    anum = atoi(tmps);
	else
	    anum = -1;
	if (isatty(anum))
	    str = &str_yes;
	else
	    str = &str_no;
	break;
    case O_FTTEXT:
    case O_FTBINARY:
	str = do_fttext(arg,sarg[1]);
	break;
    }
    if (retary) {
	sarg[1] = str;
	maxsarg = sargoff + 1;
    }
#ifdef DEBUGGING
    if (debug) {
	dlevel--;
	if (debug & 8)
	    deb("%s RETURNS \"%s\"\n",opname[optype],str_get(str));
    }
#endif
    goto freeargs;

array_return:
#ifdef DEBUGGING
    if (debug) {
	dlevel--;
	if (debug & 8)
	    deb("%s RETURNS ARRAY OF %d ARGS\n",opname[optype],maxsarg-sargoff);
    }
#endif
    goto freeargs;

donumset:
    str_numset(str,value);
    STABSET(str);
    if (retary) {
	sarg[1] = str;
	maxsarg = sargoff + 1;
    }
#ifdef DEBUGGING
    if (debug) {
	dlevel--;
	if (debug & 8)
	    deb("%s RETURNS \"%f\"\n",opname[optype],value);
    }
#endif

freeargs:
    sarg -= sargoff;
    if (sarg != quicksarg) {
	if (retary) {
	    sarg[0] = &str_args;
	    str_numset(sarg[0], (double)(maxsarg));
	    sarg[maxsarg+1] = Nullstr;
	    *retary = sarg;	/* up to them to free it */
	}
	else
	    safefree((char*)sarg);
    }
    return str;
}

int
ingroup(gid,effective)
int gid;
int effective;
{
    if (gid == (effective ? getegid() : getgid()))
	return TRUE;
#ifdef GETGROUPS
#ifndef NGROUPS
#define NGROUPS 32
#endif
    {
	GIDTYPE gary[NGROUPS];
	int anum;

	anum = getgroups(NGROUPS,gary);
	while (--anum >= 0)
	    if (gary[anum] == gid)
		return TRUE;
    }
#endif
    return FALSE;
}

/* Do the permissions allow some operation?  Assumes statbuf already set. */

int
cando(bit, effective)
int bit;
int effective;
{
    if ((effective ? euid : uid) == 0) {	/* root is special */
	if (bit == S_IEXEC) {
	    if (statbuf.st_mode & 0111 ||
	      (statbuf.st_mode & S_IFMT) == S_IFDIR )
		return TRUE;
	}
	else
	    return TRUE;		/* root reads and writes anything */
	return FALSE;
    }
    if (statbuf.st_uid == (effective ? euid : uid) ) {
	if (statbuf.st_mode & bit)
	    return TRUE;	/* ok as "user" */
    }
    else if (ingroup((int)statbuf.st_gid,effective)) {
	if (statbuf.st_mode & bit >> 3)
	    return TRUE;	/* ok as "group" */
    }
    else if (statbuf.st_mode & bit >> 6)
	return TRUE;	/* ok as "other" */
    return FALSE;
}
