/* $Header: cmd.c,v 1.0.1.1 88/01/21 21:24:16 root Exp $
 *
 * $Log:	cmd.c,v $
 * Revision 1.0.1.1  88/01/21  21:24:16  root
 * The redo cmd got a segmentation fault because trace context stack overflowed.
 * 
 * Revision 1.0  87/12/18  13:04:51  root
 * Initial revision
 * 
 */

#include "handy.h"
#include "EXTERN.h"
#include "search.h"
#include "util.h"
#include "perl.h"

static STR str_chop;

/* This is the main command loop.  We try to spend as much time in this loop
 * as possible, so lots of optimizations do their activities in here.  This
 * means things get a little sloppy.
 */

STR *
cmd_exec(cmd)
register CMD *cmd;
{
    SPAT *oldspat;
#ifdef DEBUGGING
    int olddlevel;
    int entdlevel;
#endif
    register STR *retstr;
    register char *tmps;
    register int cmdflags;
    register bool match;
    register char *go_to = goto_targ;
    ARG *arg;
    FILE *fp;

    retstr = &str_no;
#ifdef DEBUGGING
    entdlevel = dlevel;
#endif
tail_recursion_entry:
#ifdef DEBUGGING
    dlevel = entdlevel;
#endif
    if (cmd == Nullcmd)
	return retstr;
    cmdflags = cmd->c_flags;	/* hopefully load register */
    if (go_to) {
	if (cmd->c_label && strEQ(go_to,cmd->c_label))
	    goto_targ = go_to = Nullch;		/* here at last */
	else {
	    switch (cmd->c_type) {
	    case C_IF:
		oldspat = curspat;
#ifdef DEBUGGING
		olddlevel = dlevel;
#endif
		retstr = &str_yes;
		if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
		    debname[dlevel] = 't';
		    debdelim[dlevel++] = '_';
#endif
		    retstr = cmd_exec(cmd->ucmd.ccmd.cc_true);
		}
		if (!goto_targ) {
		    go_to = Nullch;
		} else {
		    retstr = &str_no;
		    if (cmd->ucmd.ccmd.cc_alt) {
#ifdef DEBUGGING
			debname[dlevel] = 'e';
			debdelim[dlevel++] = '_';
#endif
			retstr = cmd_exec(cmd->ucmd.ccmd.cc_alt);
		    }
		}
		if (!goto_targ)
		    go_to = Nullch;
		curspat = oldspat;
#ifdef DEBUGGING
		dlevel = olddlevel;
#endif
		break;
	    case C_BLOCK:
	    case C_WHILE:
		if (!(cmdflags & CF_ONCE)) {
		    cmdflags |= CF_ONCE;
		    loop_ptr++;
		    loop_stack[loop_ptr].loop_label = cmd->c_label;
#ifdef DEBUGGING
		    if (debug & 4) {
			deb("(Pushing label #%d %s)\n",
			  loop_ptr,cmd->c_label);
		    }
#endif
		}
		switch (setjmp(loop_stack[loop_ptr].loop_env)) {
		case O_LAST:	/* not done unless go_to found */
		    go_to = Nullch;
		    retstr = &str_no;
#ifdef DEBUGGING
		    olddlevel = dlevel;
#endif
		    curspat = oldspat;
#ifdef DEBUGGING
		    if (debug & 4) {
			deb("(Popping label #%d %s)\n",loop_ptr,
			    loop_stack[loop_ptr].loop_label);
		    }
#endif
		    loop_ptr--;
		    cmd = cmd->c_next;
		    goto tail_recursion_entry;
		case O_NEXT:	/* not done unless go_to found */
		    go_to = Nullch;
		    goto next_iter;
		case O_REDO:	/* not done unless go_to found */
		    go_to = Nullch;
		    goto doit;
		}
		oldspat = curspat;
#ifdef DEBUGGING
		olddlevel = dlevel;
#endif
		if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
		    debname[dlevel] = 't';
		    debdelim[dlevel++] = '_';
#endif
		    cmd_exec(cmd->ucmd.ccmd.cc_true);
		}
		if (!goto_targ) {
		    go_to = Nullch;
		    goto next_iter;
		}
#ifdef DEBUGGING
		dlevel = olddlevel;
#endif
		if (cmd->ucmd.ccmd.cc_alt) {
#ifdef DEBUGGING
		    debname[dlevel] = 'a';
		    debdelim[dlevel++] = '_';
#endif
		    cmd_exec(cmd->ucmd.ccmd.cc_alt);
		}
		if (goto_targ)
		    break;
		go_to = Nullch;
		goto finish_while;
	    }
	    cmd = cmd->c_next;
	    if (cmd && cmd->c_head == cmd)	/* reached end of while loop */
		return retstr;		/* targ isn't in this block */
	    goto tail_recursion_entry;
	}
    }

until_loop:

#ifdef DEBUGGING
    if (debug & 2) {
	deb("%s	(%lx)	r%lx	t%lx	a%lx	n%lx	cs%lx\n",
	    cmdname[cmd->c_type],cmd,cmd->c_expr,
	    cmd->ucmd.ccmd.cc_true,cmd->ucmd.ccmd.cc_alt,cmd->c_next,curspat);
    }
    debname[dlevel] = cmdname[cmd->c_type][0];
    debdelim[dlevel++] = '!';
#endif
    while (tmps_max >= 0)		/* clean up after last eval */
	str_free(tmps_list[tmps_max--]);

    /* Here is some common optimization */

    if (cmdflags & CF_COND) {
	switch (cmdflags & CF_OPTIMIZE) {

	case CFT_FALSE:
	    retstr = cmd->c_first;
	    match = FALSE;
	    if (cmdflags & CF_NESURE)
		goto maybe;
	    break;
	case CFT_TRUE:
	    retstr = cmd->c_first;
	    match = TRUE;
	    if (cmdflags & CF_EQSURE)
		goto flipmaybe;
	    break;

	case CFT_REG:
	    retstr = STAB_STR(cmd->c_stab);
	    match = str_true(retstr);	/* => retstr = retstr, c2 should fix */
	    if (cmdflags & (match ? CF_EQSURE : CF_NESURE))
		goto flipmaybe;
	    break;

	case CFT_ANCHOR:	/* /^pat/ optimization */
	    if (multiline) {
		if (*cmd->c_first->str_ptr && !(cmdflags & CF_EQSURE))
		    goto scanner;	/* just unanchor it */
		else
		    break;		/* must evaluate */
	    }
	    /* FALL THROUGH */
	case CFT_STROP:		/* string op optimization */
	    retstr = STAB_STR(cmd->c_stab);
	    if (*cmd->c_first->str_ptr == *str_get(retstr) &&
		    strnEQ(cmd->c_first->str_ptr, str_get(retstr),
		      cmd->c_flen) ) {
		if (cmdflags & CF_EQSURE) {
		    match = !(cmdflags & CF_FIRSTNEG);
		    retstr = &str_yes;
		    goto flipmaybe;
		}
	    }
	    else if (cmdflags & CF_NESURE) {
		match = cmdflags & CF_FIRSTNEG;
		retstr = &str_no;
		goto flipmaybe;
	    }
	    break;			/* must evaluate */

	case CFT_SCAN:			/* non-anchored search */
	  scanner:
	    retstr = STAB_STR(cmd->c_stab);
	    if (instr(str_get(retstr),cmd->c_first->str_ptr)) {
		if (cmdflags & CF_EQSURE) {
		    match = !(cmdflags & CF_FIRSTNEG);
		    retstr = &str_yes;
		    goto flipmaybe;
		}
	    }
	    else if (cmdflags & CF_NESURE) {
		match = cmdflags & CF_FIRSTNEG;
		retstr = &str_no;
		goto flipmaybe;
	    }
	    break;			/* must evaluate */

	case CFT_GETS:			/* really a while (<file>) */
	    last_in_stab = cmd->c_stab;
	    fp = last_in_stab->stab_io->fp;
	    retstr = defstab->stab_val;
	    if (fp && str_gets(retstr, fp)) {
		last_in_stab->stab_io->lines++;
		match = TRUE;
	    }
	    else if (last_in_stab->stab_io->flags & IOF_ARGV)
		goto doeval;	/* doesn't necessarily count as EOF yet */
	    else {
		retstr = &str_no;
		match = FALSE;
	    }
	    goto flipmaybe;
	case CFT_EVAL:
	    break;
	case CFT_UNFLIP:
	    retstr = eval(cmd->c_expr,Null(char***));
	    match = str_true(retstr);
	    if (cmd->c_expr->arg_type == O_FLIP)	/* undid itself? */
		cmdflags = copyopt(cmd,cmd->c_expr[3].arg_ptr.arg_cmd);
	    goto maybe;
	case CFT_CHOP:
	    retstr = cmd->c_stab->stab_val;
	    match = (retstr->str_cur != 0);
	    tmps = str_get(retstr);
	    tmps += retstr->str_cur - match;
	    str_set(&str_chop,tmps);
	    *tmps = '\0';
	    retstr->str_nok = 0;
	    retstr->str_cur = tmps - retstr->str_ptr;
	    retstr = &str_chop;
	    goto flipmaybe;
	}

    /* we have tried to make this normal case as abnormal as possible */

    doeval:
	retstr = eval(cmd->c_expr,Null(char***));
	match = str_true(retstr);
	goto maybe;

    /* if flipflop was true, flop it */

    flipmaybe:
	if (match && cmdflags & CF_FLIP) {
	    if (cmd->c_expr->arg_type == O_FLOP) {	/* currently toggled? */
		retstr = eval(cmd->c_expr,Null(char***)); /* let eval undo it */
		cmdflags = copyopt(cmd,cmd->c_expr[3].arg_ptr.arg_cmd);
	    }
	    else {
		retstr = eval(cmd->c_expr,Null(char***)); /* let eval do it */
		if (cmd->c_expr->arg_type == O_FLOP)	/* still toggled? */
		    cmdflags = copyopt(cmd,cmd->c_expr[4].arg_ptr.arg_cmd);
	    }
	}
	else if (cmdflags & CF_FLIP) {
	    if (cmd->c_expr->arg_type == O_FLOP) {	/* currently toggled? */
		match = TRUE;				/* force on */
	    }
	}

    /* at this point, match says whether our expression was true */

    maybe:
	if (cmdflags & CF_INVERT)
	    match = !match;
	if (!match && cmd->c_type != C_IF) {
	    cmd = cmd->c_next;
	    goto tail_recursion_entry;
	}
    }

    /* now to do the actual command, if any */

    switch (cmd->c_type) {
    case C_NULL:
	fatal("panic: cmd_exec\n");
    case C_EXPR:			/* evaluated for side effects */
	if (cmd->ucmd.acmd.ac_expr) {	/* more to do? */
	    retstr = eval(cmd->ucmd.acmd.ac_expr,Null(char***));
	}
	break;
    case C_IF:
	oldspat = curspat;
#ifdef DEBUGGING
	olddlevel = dlevel;
#endif
	if (match) {
	    retstr = &str_yes;
	    if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
		debname[dlevel] = 't';
		debdelim[dlevel++] = '_';
#endif
		retstr = cmd_exec(cmd->ucmd.ccmd.cc_true);
	    }
	}
	else {
	    retstr = &str_no;
	    if (cmd->ucmd.ccmd.cc_alt) {
#ifdef DEBUGGING
		debname[dlevel] = 'e';
		debdelim[dlevel++] = '_';
#endif
		retstr = cmd_exec(cmd->ucmd.ccmd.cc_alt);
	    }
	}
	curspat = oldspat;
#ifdef DEBUGGING
	dlevel = olddlevel;
#endif
	break;
    case C_BLOCK:
    case C_WHILE:
	if (!(cmdflags & CF_ONCE)) {	/* first time through here? */
	    cmdflags |= CF_ONCE;
	    loop_ptr++;
	    loop_stack[loop_ptr].loop_label = cmd->c_label;
#ifdef DEBUGGING
	    if (debug & 4) {
		deb("(Pushing label #%d %s)\n",
		  loop_ptr,cmd->c_label);
	    }
#endif
	}
	switch (setjmp(loop_stack[loop_ptr].loop_env)) {
	case O_LAST:
	    retstr = &str_no;
	    curspat = oldspat;
#ifdef DEBUGGING
	    if (debug & 4) {
		deb("(Popping label #%d %s)\n",loop_ptr,
		    loop_stack[loop_ptr].loop_label);
	    }
#endif
	    loop_ptr--;
	    cmd = cmd->c_next;
	    goto tail_recursion_entry;
	case O_NEXT:
	    goto next_iter;
	case O_REDO:
#ifdef DEBUGGING
	    dlevel = olddlevel;
#endif
	    goto doit;
	}
	oldspat = curspat;
#ifdef DEBUGGING
	olddlevel = dlevel;
#endif
    doit:
	if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
	    debname[dlevel] = 't';
	    debdelim[dlevel++] = '_';
#endif
	    cmd_exec(cmd->ucmd.ccmd.cc_true);
	}
	/* actually, this spot is never reached anymore since the above
	 * cmd_exec() returns through longjmp().  Hooray for structure.
	 */
      next_iter:
#ifdef DEBUGGING
	dlevel = olddlevel;
#endif
	if (cmd->ucmd.ccmd.cc_alt) {
#ifdef DEBUGGING
	    debname[dlevel] = 'a';
	    debdelim[dlevel++] = '_';
#endif
	    cmd_exec(cmd->ucmd.ccmd.cc_alt);
	}
      finish_while:
	curspat = oldspat;
#ifdef DEBUGGING
	dlevel = olddlevel - 1;
#endif
	if (cmd->c_type != C_BLOCK)
	    goto until_loop;	/* go back and evaluate conditional again */
    }
    if (cmdflags & CF_LOOP) {
	cmdflags |= CF_COND;		/* now test the condition */
	goto until_loop;
    }
    cmd = cmd->c_next;
    goto tail_recursion_entry;
}

#ifdef DEBUGGING
/*VARARGS1*/
deb(pat,a1,a2,a3,a4,a5,a6,a7,a8)
char *pat;
{
    register int i;

    for (i=0; i<dlevel; i++)
	fprintf(stderr,"%c%c ",debname[i],debdelim[i]);
    fprintf(stderr,pat,a1,a2,a3,a4,a5,a6,a7,a8);
}
#endif

copyopt(cmd,which)
register CMD *cmd;
register CMD *which;
{
    cmd->c_flags &= CF_ONCE|CF_COND|CF_LOOP;
    cmd->c_flags |= which->c_flags;
    cmd->c_first = which->c_first;
    cmd->c_flen = which->c_flen;
    cmd->c_stab = which->c_stab;
    return cmd->c_flags;
}
