/* $Header: cmd.c,v 3.0.1.1 89/10/26 23:04:21 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	cmd.c,v $
 * Revision 3.0.1.1  89/10/26  23:04:21  lwall
 * patch1: heuristically disabled optimization could cause core dump
 * 
 * Revision 3.0  89/10/18  15:09:02  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#ifdef I_VARARGS
#  include <varargs.h>
#endif

static STR str_chop;

void grow_dlevel();

/* This is the main command loop.  We try to spend as much time in this loop
 * as possible, so lots of optimizations do their activities in here.  This
 * means things get a little sloppy.
 */

int
cmd_exec(cmd,gimme,sp)
#ifdef cray	/* nobody else has complained yet */
CMD *cmd;
#else
register CMD *cmd;
#endif
int gimme;
int sp;
{
    SPAT *oldspat;
    int oldsave;
    int aryoptsave;
#ifdef DEBUGGING
    int olddlevel;
    int entdlevel;
#endif
    register STR *retstr = &str_undef;
    register char *tmps;
    register int cmdflags;
    register int match;
    register char *go_to = goto_targ;
    register int newsp = -2;
    register STR **st = stack->ary_array;
    FILE *fp;
    ARRAY *ar;

    lastsize = 0;
#ifdef DEBUGGING
    entdlevel = dlevel;
#endif
tail_recursion_entry:
#ifdef DEBUGGING
    dlevel = entdlevel;
#endif
#ifdef TAINT
    tainted = 0;	/* Each statement is presumed innocent */
#endif
    if (cmd == Nullcmd) {
	if (gimme == G_ARRAY && newsp > -2)
	    return newsp;
	else {
	    st[++sp] = retstr;
	    return sp;
	}
    }
    cmdflags = cmd->c_flags;	/* hopefully load register */
    if (go_to) {
	if (cmd->c_label && strEQ(go_to,cmd->c_label))
	    goto_targ = go_to = Nullch;		/* here at last */
	else {
	    switch (cmd->c_type) {
	    case C_IF:
		oldspat = curspat;
		oldsave = savestack->ary_fill;
#ifdef DEBUGGING
		olddlevel = dlevel;
#endif
		retstr = &str_yes;
		newsp = -2;
		if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
		    if (debug) {
			debname[dlevel] = 't';
			debdelim[dlevel] = '_';
			if (++dlevel >= dlmax)
			    grow_dlevel();
		    }
#endif
		    newsp = cmd_exec(cmd->ucmd.ccmd.cc_true,gimme,sp);
		    st = stack->ary_array;	/* possibly reallocated */
		    retstr = st[newsp];
		}
		if (!goto_targ)
		    go_to = Nullch;
		curspat = oldspat;
		if (savestack->ary_fill > oldsave)
		    restorelist(oldsave);
#ifdef DEBUGGING
		dlevel = olddlevel;
#endif
		cmd = cmd->ucmd.ccmd.cc_alt;
		goto tail_recursion_entry;
	    case C_ELSE:
		oldspat = curspat;
		oldsave = savestack->ary_fill;
#ifdef DEBUGGING
		olddlevel = dlevel;
#endif
		retstr = &str_undef;
		newsp = -2;
		if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
		    if (debug) {
			debname[dlevel] = 'e';
			debdelim[dlevel] = '_';
			if (++dlevel >= dlmax)
			    grow_dlevel();
		    }
#endif
		    newsp = cmd_exec(cmd->ucmd.ccmd.cc_true,gimme,sp);
		    st = stack->ary_array;	/* possibly reallocated */
		    retstr = st[newsp];
		}
		if (!goto_targ)
		    go_to = Nullch;
		curspat = oldspat;
		if (savestack->ary_fill > oldsave)
		    restorelist(oldsave);
#ifdef DEBUGGING
		dlevel = olddlevel;
#endif
		break;
	    case C_BLOCK:
	    case C_WHILE:
		if (!(cmdflags & CF_ONCE)) {
		    cmdflags |= CF_ONCE;
		    if (++loop_ptr >= loop_max) {
			loop_max += 128;
			Renew(loop_stack, loop_max, struct loop);
		    }
		    loop_stack[loop_ptr].loop_label = cmd->c_label;
		    loop_stack[loop_ptr].loop_sp = sp;
#ifdef DEBUGGING
		    if (debug & 4) {
			deb("(Pushing label #%d %s)\n",
			  loop_ptr, cmd->c_label ? cmd->c_label : "");
		    }
#endif
		}
		switch (setjmp(loop_stack[loop_ptr].loop_env)) {
		case O_LAST:	/* not done unless go_to found */
		    go_to = Nullch;
		    st = stack->ary_array;	/* possibly reallocated */
		    if (lastretstr) {
			retstr = lastretstr;
			newsp = -2;
		    }
		    else {
			newsp = sp + lastsize;
			retstr = st[newsp];
		    }
#ifdef DEBUGGING
		    olddlevel = dlevel;
#endif
		    curspat = oldspat;
		    if (savestack->ary_fill > oldsave)
			restorelist(oldsave);
		    goto next_cmd;
		case O_NEXT:	/* not done unless go_to found */
		    go_to = Nullch;
		    goto next_iter;
		case O_REDO:	/* not done unless go_to found */
		    go_to = Nullch;
		    goto doit;
		}
		oldspat = curspat;
		oldsave = savestack->ary_fill;
#ifdef DEBUGGING
		olddlevel = dlevel;
#endif
		if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
		    if (debug) {
			debname[dlevel] = 't';
			debdelim[dlevel] = '_';
			if (++dlevel >= dlmax)
			    grow_dlevel();
		    }
#endif
		    newsp = cmd_exec(cmd->ucmd.ccmd.cc_true,gimme,sp);
		    st = stack->ary_array;	/* possibly reallocated */
		    retstr = st[newsp];
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
		    if (debug) {
			debname[dlevel] = 'a';
			debdelim[dlevel] = '_';
			if (++dlevel >= dlmax)
			    grow_dlevel();
		    }
#endif
		    newsp = cmd_exec(cmd->ucmd.ccmd.cc_alt,gimme,sp);
		    st = stack->ary_array;	/* possibly reallocated */
		    retstr = st[newsp];
		}
		if (goto_targ)
		    break;
		go_to = Nullch;
		goto finish_while;
	    }
	    cmd = cmd->c_next;
	    if (cmd && cmd->c_head == cmd)
					/* reached end of while loop */
		return sp;		/* targ isn't in this block */
	    if (cmdflags & CF_ONCE) {
#ifdef DEBUGGING
		if (debug & 4) {
		    tmps = loop_stack[loop_ptr].loop_label;
		    deb("(Popping label #%d %s)\n",loop_ptr,
			tmps ? tmps : "" );
		}
#endif
		loop_ptr--;
	    }
	    goto tail_recursion_entry;
	}
    }

until_loop:

    /* Set line number so run-time errors can be located */

    line = cmd->c_line;

#ifdef DEBUGGING
    if (debug) {
	if (debug & 2) {
	    deb("%s	(%lx)	r%lx	t%lx	a%lx	n%lx	cs%lx\n",
		cmdname[cmd->c_type],cmd,cmd->c_expr,
		cmd->ucmd.ccmd.cc_true,cmd->ucmd.ccmd.cc_alt,cmd->c_next,
		curspat);
	}
	debname[dlevel] = cmdname[cmd->c_type][0];
	debdelim[dlevel] = '!';
	if (++dlevel >= dlmax)
	    grow_dlevel();
    }
#endif

    /* Here is some common optimization */

    if (cmdflags & CF_COND) {
	switch (cmdflags & CF_OPTIMIZE) {

	case CFT_FALSE:
	    retstr = cmd->c_short;
	    newsp = -2;
	    match = FALSE;
	    if (cmdflags & CF_NESURE)
		goto maybe;
	    break;
	case CFT_TRUE:
	    retstr = cmd->c_short;
	    newsp = -2;
	    match = TRUE;
	    if (cmdflags & CF_EQSURE)
		goto flipmaybe;
	    break;

	case CFT_REG:
	    retstr = STAB_STR(cmd->c_stab);
	    newsp = -2;
	    match = str_true(retstr);	/* => retstr = retstr, c2 should fix */
	    if (cmdflags & (match ? CF_EQSURE : CF_NESURE))
		goto flipmaybe;
	    break;

	case CFT_ANCHOR:	/* /^pat/ optimization */
	    if (multiline) {
		if (*cmd->c_short->str_ptr && !(cmdflags & CF_EQSURE))
		    goto scanner;	/* just unanchor it */
		else
		    break;		/* must evaluate */
	    }
	    /* FALL THROUGH */
	case CFT_STROP:		/* string op optimization */
	    retstr = STAB_STR(cmd->c_stab);
	    newsp = -2;
#ifndef I286
	    if (*cmd->c_short->str_ptr == *str_get(retstr) &&
		    bcmp(cmd->c_short->str_ptr, str_get(retstr),
		      cmd->c_slen) == 0 ) {
		if (cmdflags & CF_EQSURE) {
		    if (sawampersand && (cmdflags & CF_OPTIMIZE) != CFT_STROP) {
			curspat = Nullspat;
			if (leftstab)
			    str_nset(stab_val(leftstab),"",0);
			if (amperstab)
			    str_sset(stab_val(amperstab),cmd->c_short);
			if (rightstab)
			    str_nset(stab_val(rightstab),
			      retstr->str_ptr + cmd->c_slen,
			      retstr->str_cur - cmd->c_slen);
		    }
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
#else
	    {
		char *zap1, *zap2, zap1c, zap2c;
		int  zaplen;

		zap1 = cmd->c_short->str_ptr;
		zap2 = str_get(retstr);
		zap1c = *zap1;
		zap2c = *zap2;
		zaplen = cmd->c_slen;
		if ((zap1c == zap2c) && (bcmp(zap1, zap2, zaplen) == 0)) {
		    if (cmdflags & CF_EQSURE) {
			if (sawampersand &&
			  (cmdflags & CF_OPTIMIZE) != CFT_STROP) {
			    curspat = Nullspat;
			    if (leftstab)
				str_nset(stab_val(leftstab),"",0);
			    if (amperstab)
				str_sset(stab_val(amperstab),cmd->c_short);
			    if (rightstab)
				str_nset(stab_val(rightstab),
					 retstr->str_ptr + cmd->c_slen,
					 retstr->str_cur - cmd->c_slen);
			}
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
	    }
#endif
	    break;			/* must evaluate */

	case CFT_SCAN:			/* non-anchored search */
	  scanner:
	    retstr = STAB_STR(cmd->c_stab);
	    newsp = -2;
	    if (retstr->str_pok & SP_STUDIED)
		if (screamfirst[cmd->c_short->str_rare] >= 0)
		    tmps = screaminstr(retstr, cmd->c_short);
		else
		    tmps = Nullch;
	    else {
		tmps = str_get(retstr);		/* make sure it's pok */
#ifndef lint
		tmps = fbminstr((unsigned char*)tmps,
		    (unsigned char*)tmps + retstr->str_cur, cmd->c_short);
#endif
	    }
	    if (tmps) {
		if (cmdflags & CF_EQSURE) {
		    ++cmd->c_short->str_u.str_useful;
		    if (sawampersand) {
			curspat = Nullspat;
			if (leftstab)
			    str_nset(stab_val(leftstab),retstr->str_ptr,
			      tmps - retstr->str_ptr);
			if (amperstab)
			    str_sset(stab_val(amperstab),cmd->c_short);
			if (rightstab)
			    str_nset(stab_val(rightstab),
			      tmps + cmd->c_short->str_cur,
			      retstr->str_cur - (tmps - retstr->str_ptr) -
				cmd->c_short->str_cur);
		    }
		    match = !(cmdflags & CF_FIRSTNEG);
		    retstr = &str_yes;
		    goto flipmaybe;
		}
		else
		    hint = tmps;
	    }
	    else {
		if (cmdflags & CF_NESURE) {
		    ++cmd->c_short->str_u.str_useful;
		    match = cmdflags & CF_FIRSTNEG;
		    retstr = &str_no;
		    goto flipmaybe;
		}
	    }
	    if (--cmd->c_short->str_u.str_useful < 0) {
		cmdflags &= ~CF_OPTIMIZE;
		cmdflags |= CFT_EVAL;	/* never try this optimization again */
		cmd->c_flags = cmdflags;
	    }
	    break;			/* must evaluate */

	case CFT_NUMOP:		/* numeric op optimization */
	    retstr = STAB_STR(cmd->c_stab);
	    newsp = -2;
	    switch (cmd->c_slen) {
	    case O_EQ:
		if (dowarn) {
		    if ((!retstr->str_nok && !looks_like_number(retstr)))
			warn("Possible use of == on string value");
		}
		match = (str_gnum(retstr) == cmd->c_short->str_u.str_nval);
		break;
	    case O_NE:
		match = (str_gnum(retstr) != cmd->c_short->str_u.str_nval);
		break;
	    case O_LT:
		match = (str_gnum(retstr) <  cmd->c_short->str_u.str_nval);
		break;
	    case O_LE:
		match = (str_gnum(retstr) <= cmd->c_short->str_u.str_nval);
		break;
	    case O_GT:
		match = (str_gnum(retstr) >  cmd->c_short->str_u.str_nval);
		break;
	    case O_GE:
		match = (str_gnum(retstr) >= cmd->c_short->str_u.str_nval);
		break;
	    }
	    if (match) {
		if (cmdflags & CF_EQSURE) {
		    retstr = &str_yes;
		    goto flipmaybe;
		}
	    }
	    else if (cmdflags & CF_NESURE) {
		retstr = &str_no;
		goto flipmaybe;
	    }
	    break;			/* must evaluate */

	case CFT_INDGETS:		/* while (<$foo>) */
	    last_in_stab = stabent(str_get(STAB_STR(cmd->c_stab)),TRUE);
	    if (!stab_io(last_in_stab))
		stab_io(last_in_stab) = stio_new();
	    goto dogets;
	case CFT_GETS:			/* really a while (<file>) */
	    last_in_stab = cmd->c_stab;
	  dogets:
	    fp = stab_io(last_in_stab)->ifp;
	    retstr = stab_val(defstab);
	    newsp = -2;
	    if (fp && str_gets(retstr, fp, 0)) {
		if (*retstr->str_ptr == '0' && retstr->str_cur == 1)
		    match = FALSE;
		else
		    match = TRUE;
		stab_io(last_in_stab)->lines++;
	    }
	    else if (stab_io(last_in_stab)->flags & IOF_ARGV)
		goto doeval;	/* doesn't necessarily count as EOF yet */
	    else {
		retstr = &str_undef;
		match = FALSE;
	    }
	    goto flipmaybe;
	case CFT_EVAL:
	    break;
	case CFT_UNFLIP:
	    while (tmps_max > tmps_base)	/* clean up after last eval */
		str_free(tmps_list[tmps_max--]);
	    newsp = eval(cmd->c_expr,gimme && (cmdflags & CF_TERM),sp);
	    st = stack->ary_array;	/* possibly reallocated */
	    retstr = st[newsp];
	    match = str_true(retstr);
	    if (cmd->c_expr->arg_type == O_FLIP)	/* undid itself? */
		cmdflags = copyopt(cmd,cmd->c_expr[3].arg_ptr.arg_cmd);
	    goto maybe;
	case CFT_CHOP:
	    retstr = stab_val(cmd->c_stab);
	    newsp = -2;
	    match = (retstr->str_cur != 0);
	    tmps = str_get(retstr);
	    tmps += retstr->str_cur - match;
	    str_nset(&str_chop,tmps,match);
	    *tmps = '\0';
	    retstr->str_nok = 0;
	    retstr->str_cur = tmps - retstr->str_ptr;
	    retstr = &str_chop;
	    goto flipmaybe;
	case CFT_ARRAY:
	    ar = stab_array(cmd->c_expr[1].arg_ptr.arg_stab);
	    match = ar->ary_index;	/* just to get register */

	    if (match < 0) {		/* first time through here? */
		aryoptsave = savestack->ary_fill;
		savesptr(&stab_val(cmd->c_stab));
		saveint(&ar->ary_index);
	    }

	    if (match >= ar->ary_fill) {	/* we're in LAST, probably */
		retstr = &str_undef;
		ar->ary_index = -1;	/* this is actually redundant */
		match = FALSE;
	    }
	    else {
		match++;
		retstr = stab_val(cmd->c_stab) = ar->ary_array[match];
		ar->ary_index = match;
		match = TRUE;
	    }
	    newsp = -2;
	    goto maybe;
	}

    /* we have tried to make this normal case as abnormal as possible */

    doeval:
	if (gimme == G_ARRAY) {
	    lastretstr = Nullstr;
	    lastspbase = sp;
	    lastsize = newsp - sp;
	}
	else
	    lastretstr = retstr;
	while (tmps_max > tmps_base)	/* clean up after last eval */
	    str_free(tmps_list[tmps_max--]);
	newsp = eval(cmd->c_expr,gimme && (cmdflags & CF_TERM),sp);
	st = stack->ary_array;	/* possibly reallocated */
	retstr = st[newsp];
	if (newsp > sp)
	    match = str_true(retstr);
	else
	    match = FALSE;
	goto maybe;

    /* if flipflop was true, flop it */

    flipmaybe:
	if (match && cmdflags & CF_FLIP) {
	    while (tmps_max > tmps_base)	/* clean up after last eval */
		str_free(tmps_list[tmps_max--]);
	    if (cmd->c_expr->arg_type == O_FLOP) {	/* currently toggled? */
		newsp = eval(cmd->c_expr,G_SCALAR,sp);/*let eval undo it*/
		cmdflags = copyopt(cmd,cmd->c_expr[3].arg_ptr.arg_cmd);
	    }
	    else {
		newsp = eval(cmd->c_expr,G_SCALAR,sp);/* let eval do it */
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
	if (!match)
	    goto next_cmd;
    }
#ifdef TAINT
    tainted = 0;	/* modifier doesn't affect regular expression */
#endif

    /* now to do the actual command, if any */

    switch (cmd->c_type) {
    case C_NULL:
	fatal("panic: cmd_exec");
    case C_EXPR:			/* evaluated for side effects */
	if (cmd->ucmd.acmd.ac_expr) {	/* more to do? */
	    if (gimme == G_ARRAY) {
		lastretstr = Nullstr;
		lastspbase = sp;
		lastsize = newsp - sp;
	    }
	    else
		lastretstr = retstr;
	    while (tmps_max > tmps_base)	/* clean up after last eval */
		str_free(tmps_list[tmps_max--]);
	    newsp = eval(cmd->ucmd.acmd.ac_expr,gimme && (cmdflags&CF_TERM),sp);
	    st = stack->ary_array;	/* possibly reallocated */
	    retstr = st[newsp];
	}
	break;
    case C_NSWITCH:
	match = (int)str_gnum(STAB_STR(cmd->c_stab));
	goto doswitch;
    case C_CSWITCH:
	match = *(str_get(STAB_STR(cmd->c_stab))) & 255;
      doswitch:
	match -= cmd->ucmd.scmd.sc_offset;
	if (match < 0)
	    match = 0;
	else if (match > cmd->ucmd.scmd.sc_max)
	    match = cmd->c_slen;
	cmd = cmd->ucmd.scmd.sc_next[match];
	goto tail_recursion_entry;
    case C_NEXT:
	cmd = cmd->ucmd.ccmd.cc_alt;
	goto tail_recursion_entry;
    case C_ELSIF:
	fatal("panic: ELSIF");
    case C_IF:
	oldspat = curspat;
	oldsave = savestack->ary_fill;
#ifdef DEBUGGING
	olddlevel = dlevel;
#endif
	retstr = &str_yes;
	newsp = -2;
	if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
	    if (debug) {
		debname[dlevel] = 't';
		debdelim[dlevel] = '_';
		if (++dlevel >= dlmax)
		    grow_dlevel();
	    }
#endif
	    newsp = cmd_exec(cmd->ucmd.ccmd.cc_true,gimme,sp);
	    st = stack->ary_array;	/* possibly reallocated */
	    retstr = st[newsp];
	}
	curspat = oldspat;
	if (savestack->ary_fill > oldsave)
	    restorelist(oldsave);
#ifdef DEBUGGING
	dlevel = olddlevel;
#endif
	cmd = cmd->ucmd.ccmd.cc_alt;
	goto tail_recursion_entry;
    case C_ELSE:
	oldspat = curspat;
	oldsave = savestack->ary_fill;
#ifdef DEBUGGING
	olddlevel = dlevel;
#endif
	retstr = &str_undef;
	newsp = -2;
	if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
	    if (debug) {
		debname[dlevel] = 'e';
		debdelim[dlevel] = '_';
		if (++dlevel >= dlmax)
		    grow_dlevel();
	    }
#endif
	    newsp = cmd_exec(cmd->ucmd.ccmd.cc_true,gimme,sp);
	    st = stack->ary_array;	/* possibly reallocated */
	    retstr = st[newsp];
	}
	curspat = oldspat;
	if (savestack->ary_fill > oldsave)
	    restorelist(oldsave);
#ifdef DEBUGGING
	dlevel = olddlevel;
#endif
	break;
    case C_BLOCK:
    case C_WHILE:
	if (!(cmdflags & CF_ONCE)) {	/* first time through here? */
	    cmdflags |= CF_ONCE;
	    if (++loop_ptr >= loop_max) {
		loop_max += 128;
		Renew(loop_stack, loop_max, struct loop);
	    }
	    loop_stack[loop_ptr].loop_label = cmd->c_label;
	    loop_stack[loop_ptr].loop_sp = sp;
#ifdef DEBUGGING
	    if (debug & 4) {
		deb("(Pushing label #%d %s)\n",
		  loop_ptr, cmd->c_label ? cmd->c_label : "");
	    }
#endif
	}
	switch (setjmp(loop_stack[loop_ptr].loop_env)) {
	case O_LAST:
	    /* retstr = lastretstr; */
	    st = stack->ary_array;	/* possibly reallocated */
	    if (lastretstr) {
		retstr = lastretstr;
		newsp = -2;
	    }
	    else {
		newsp = sp + lastsize;
		retstr = st[newsp];
	    }
	    curspat = oldspat;
	    if (savestack->ary_fill > oldsave)
		restorelist(oldsave);
	    goto next_cmd;
	case O_NEXT:
	    goto next_iter;
	case O_REDO:
#ifdef DEBUGGING
	    dlevel = olddlevel;
#endif
	    goto doit;
	}
	oldspat = curspat;
	oldsave = savestack->ary_fill;
#ifdef DEBUGGING
	olddlevel = dlevel;
#endif
    doit:
	if (cmd->ucmd.ccmd.cc_true) {
#ifdef DEBUGGING
	    if (debug) {
		debname[dlevel] = 't';
		debdelim[dlevel] = '_';
		if (++dlevel >= dlmax)
		    grow_dlevel();
	    }
#endif
	    newsp = cmd_exec(cmd->ucmd.ccmd.cc_true,gimme,sp);
	    st = stack->ary_array;	/* possibly reallocated */
	    retstr = st[newsp];
	}
	/* actually, this spot is rarely reached anymore since the above
	 * cmd_exec() returns through longjmp().  Hooray for structure.
	 */
      next_iter:
#ifdef DEBUGGING
	dlevel = olddlevel;
#endif
	if (cmd->ucmd.ccmd.cc_alt) {
#ifdef DEBUGGING
	    if (debug) {
		debname[dlevel] = 'a';
		debdelim[dlevel] = '_';
		if (++dlevel >= dlmax)
		    grow_dlevel();
	    }
#endif
	    newsp = cmd_exec(cmd->ucmd.ccmd.cc_alt,gimme,sp);
	    st = stack->ary_array;	/* possibly reallocated */
	    retstr = st[newsp];
	}
      finish_while:
	curspat = oldspat;
	if (savestack->ary_fill > oldsave)
	    restorelist(oldsave);
#ifdef DEBUGGING
	dlevel = olddlevel - 1;
#endif
	if (cmd->c_type != C_BLOCK)
	    goto until_loop;	/* go back and evaluate conditional again */
    }
    if (cmdflags & CF_LOOP) {
	cmdflags |= CF_COND;		/* now test the condition */
#ifdef DEBUGGING
	dlevel = entdlevel;
#endif
	goto until_loop;
    }
  next_cmd:
    if (cmdflags & CF_ONCE) {
#ifdef DEBUGGING
	if (debug & 4) {
	    tmps = loop_stack[loop_ptr].loop_label;
	    deb("(Popping label #%d %s)\n",loop_ptr, tmps ? tmps : "");
	}
#endif
	loop_ptr--;
	if ((cmdflags & CF_OPTIMIZE) == CFT_ARRAY)
	    restorelist(aryoptsave);
    }
    cmd = cmd->c_next;
    goto tail_recursion_entry;
}

#ifdef DEBUGGING
#  ifndef VARARGS
/*VARARGS1*/
deb(pat,a1,a2,a3,a4,a5,a6,a7,a8)
char *pat;
{
    register int i;

    fprintf(stderr,"%-4ld",(long)line);
    for (i=0; i<dlevel; i++)
	fprintf(stderr,"%c%c ",debname[i],debdelim[i]);
    fprintf(stderr,pat,a1,a2,a3,a4,a5,a6,a7,a8);
}
#  else
/*VARARGS1*/
deb(va_alist)
va_dcl
{
    va_list args;
    char *pat;
    register int i;

    va_start(args);
    fprintf(stderr,"%-4ld",(long)line);
    for (i=0; i<dlevel; i++)
	fprintf(stderr,"%c%c ",debname[i],debdelim[i]);

    pat = va_arg(args, char *);
    (void) vfprintf(stderr,pat,args);
    va_end( args );
}
#  endif
#endif

copyopt(cmd,which)
register CMD *cmd;
register CMD *which;
{
    cmd->c_flags &= CF_ONCE|CF_COND|CF_LOOP;
    cmd->c_flags |= which->c_flags;
    cmd->c_short = which->c_short;
    cmd->c_slen = which->c_slen;
    cmd->c_stab = which->c_stab;
    return cmd->c_flags;
}

ARRAY *
saveary(stab)
STAB *stab;
{
    register STR *str;

    str = Str_new(10,0);
    str->str_state = SS_SARY;
    str->str_u.str_stab = stab;
    if (str->str_ptr) {
	Safefree(str->str_ptr);
	str->str_len = 0;
    }
    str->str_ptr = (char*)stab_array(stab);
    (void)apush(savestack,str); /* save array ptr */
    stab_xarray(stab) = Null(ARRAY*);
    return stab_xarray(aadd(stab));
}

HASH *
savehash(stab)
STAB *stab;
{
    register STR *str;

    str = Str_new(11,0);
    str->str_state = SS_SHASH;
    str->str_u.str_stab = stab;
    if (str->str_ptr) {
	Safefree(str->str_ptr);
	str->str_len = 0;
    }
    str->str_ptr = (char*)stab_hash(stab);
    (void)apush(savestack,str); /* save hash ptr */
    stab_xhash(stab) = Null(HASH*);
    return stab_xhash(hadd(stab));
}

void
saveitem(item)
register STR *item;
{
    register STR *str;

    (void)apush(savestack,item);		/* remember the pointer */
    str = Str_new(12,0);
    str_sset(str,item);
    (void)apush(savestack,str);			/* remember the value */
}

void
saveint(intp)
int *intp;
{
    register STR *str;

    str = Str_new(13,0);
    str->str_state = SS_SINT;
    str->str_u.str_useful = (long)*intp;	/* remember value */
    if (str->str_ptr) {
	Safefree(str->str_ptr);
	str->str_len = 0;
    }
    str->str_ptr = (char*)intp;		/* remember pointer */
    (void)apush(savestack,str);
}

void
savelong(longp)
long *longp;
{
    register STR *str;

    str = Str_new(14,0);
    str->str_state = SS_SLONG;
    str->str_u.str_useful = *longp;		/* remember value */
    if (str->str_ptr) {
	Safefree(str->str_ptr);
	str->str_len = 0;
    }
    str->str_ptr = (char*)longp;		/* remember pointer */
    (void)apush(savestack,str);
}

void
savesptr(sptr)
STR **sptr;
{
    register STR *str;

    str = Str_new(15,0);
    str->str_state = SS_SSTRP;
    str->str_magic = *sptr;		/* remember value */
    if (str->str_ptr) {
	Safefree(str->str_ptr);
	str->str_len = 0;
    }
    str->str_ptr = (char*)sptr;		/* remember pointer */
    (void)apush(savestack,str);
}

void
savenostab(stab)
STAB *stab;
{
    register STR *str;

    str = Str_new(16,0);
    str->str_state = SS_SNSTAB;
    str->str_magic = (STR*)stab;	/* remember which stab to free */
    (void)apush(savestack,str);
}

void
savehptr(hptr)
HASH **hptr;
{
    register STR *str;

    str = Str_new(17,0);
    str->str_state = SS_SHPTR;
    str->str_u.str_hash = *hptr;	/* remember value */
    if (str->str_ptr) {
	Safefree(str->str_ptr);
	str->str_len = 0;
    }
    str->str_ptr = (char*)hptr;		/* remember pointer */
    (void)apush(savestack,str);
}

void
savelist(sarg,maxsarg)
register STR **sarg;
int maxsarg;
{
    register STR *str;
    register int i;

    for (i = 1; i <= maxsarg; i++) {
	(void)apush(savestack,sarg[i]);		/* remember the pointer */
	str = Str_new(18,0);
	str_sset(str,sarg[i]);
	(void)apush(savestack,str);			/* remember the value */
    }
}

void
restorelist(base)
int base;
{
    register STR *str;
    register STR *value;
    register STAB *stab;

    if (base < -1)
	fatal("panic: corrupt saved stack index");
    while (savestack->ary_fill > base) {
	value = apop(savestack);
	switch (value->str_state) {
	case SS_NORM:				/* normal string */
	case SS_INCR:
	    str = apop(savestack);
	    str_replace(str,value);
	    STABSET(str);
	    break;
	case SS_SARY:				/* array reference */
	    stab = value->str_u.str_stab;
	    afree(stab_xarray(stab));
	    stab_xarray(stab) = (ARRAY*)value->str_ptr;
	    value->str_ptr = Nullch;
	    str_free(value);
	    break;
	case SS_SHASH:				/* hash reference */
	    stab = value->str_u.str_stab;
	    (void)hfree(stab_xhash(stab));
	    stab_xhash(stab) = (HASH*)value->str_ptr;
	    value->str_ptr = Nullch;
	    str_free(value);
	    break;
	case SS_SINT:				/* int reference */
	    *((int*)value->str_ptr) = (int)value->str_u.str_useful;
	    value->str_ptr = Nullch;
	    str_free(value);
	    break;
	case SS_SLONG:				/* long reference */
	    *((long*)value->str_ptr) = value->str_u.str_useful;
	    value->str_ptr = Nullch;
	    str_free(value);
	    break;
	case SS_SSTRP:				/* STR* reference */
	    *((STR**)value->str_ptr) = value->str_magic;
	    value->str_magic = Nullstr;
	    value->str_ptr = Nullch;
	    str_free(value);
	    break;
	case SS_SHPTR:				/* HASH* reference */
	    *((HASH**)value->str_ptr) = value->str_u.str_hash;
	    value->str_ptr = Nullch;
	    str_free(value);
	    break;
	case SS_SNSTAB:
	    stab = (STAB*)value->str_magic;
	    value->str_magic = Nullstr;
	    (void)stab_clear(stab);
	    str_free(value);
	    break;
	default:
	    fatal("panic: restorelist inconsistency");
	}
    }
}

void
grow_dlevel()
{
    dlmax += 128;
    Renew(debname, dlmax, char);
    Renew(debdelim, dlmax, char);
}
