/* $Header: eval.c,v 3.0.1.10 90/11/10 01:33:22 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	eval.c,v $
 * Revision 3.0.1.10  90/11/10  01:33:22  lwall
 * patch38: random cleanup
 * patch38: couldn't return from sort routine
 * patch38: added hooks for unexec()
 * patch38: added alarm function
 * 
 * Revision 3.0.1.9  90/10/15  16:46:13  lwall
 * patch29: added caller
 * patch29: added scalar
 * patch29: added cmp and <=>
 * patch29: added sysread and syswrite
 * patch29: added -M, -A and -C
 * patch29: index and substr now have optional 3rd args
 * patch29: you can now read into the middle string
 * patch29: ~ now works on vector string
 * patch29: non-existent array values no longer cause core dumps
 * patch29: eof; core dumped
 * patch29: oct and hex now produce unsigned result
 * patch29: unshift did not return the documented value
 * 
 * Revision 3.0.1.8  90/08/13  22:17:14  lwall
 * patch28: the NSIG hack didn't work right on Xenix
 * patch28: defined(@array) and defined(%array) didn't work right
 * patch28: rename was busted on systems without rename system call
 * 
 * Revision 3.0.1.7  90/08/09  03:33:44  lwall
 * patch19: made ~ do vector operation on strings like &, | and ^
 * patch19: dbmopen(%name...) didn't work right
 * patch19: dbmopen(name, 'filename', undef) now refrains from creating
 * patch19: empty %array now returns 0 in scalar context
 * patch19: die with no arguments no longer exits unconditionally
 * patch19: return outside a subroutine now returns a reasonable message
 * patch19: rename done with unlink()/link()/unlink() now checks for clobbering
 * patch19: -s now returns size of file
 * 
 * Revision 3.0.1.6  90/03/27  15:53:51  lwall
 * patch16: MSDOS support
 * patch16: support for machines that can't cast negative floats to unsigned ints
 * patch16: ioctl didn't return values correctly
 * 
 * Revision 3.0.1.5  90/03/12  16:37:40  lwall
 * patch13: undef $/ didn't work as advertised
 * patch13: added list slice operator (LIST)[LIST]
 * patch13: added splice operator: @oldelems = splice(@array,$offset,$len,LIST)
 * 
 * Revision 3.0.1.4  90/02/28  17:36:59  lwall
 * patch9: added pipe function
 * patch9: a return in scalar context wouldn't return array
 * patch9: !~ now always returns scalar even in array context
 * patch9: some machines can't cast float to long with high bit set
 * patch9: piped opens returned undef in child
 * patch9: @array in scalar context now returns length of array
 * patch9: chdir; coredumped
 * patch9: wait no longer ignores signals
 * patch9: mkdir now handles odd versions of /bin/mkdir
 * patch9: -l FILEHANDLE now disallowed
 * 
 * Revision 3.0.1.3  89/12/21  20:03:05  lwall
 * patch7: errno may now be a macro with an lvalue
 * patch7: ANSI strerror() is now supported
 * patch7: send() didn't allow a TO argument
 * patch7: ord() now always returns positive even on signed char machines
 * 
 * Revision 3.0.1.2  89/11/17  15:19:34  lwall
 * patch5: constant numeric subscripts get lost inside ?:
 * 
 * Revision 3.0.1.1  89/11/11  04:31:51  lwall
 * patch2: mkdir and rmdir needed to quote argument when passed to shell
 * patch2: mkdir and rmdir now return better error codes
 * patch2: fileno, seekdir, rewinddir and closedir now disallow defaults
 * 
 * Revision 3.0  89/10/18  15:17:04  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#if !defined(NSIG) || defined(M_UNIX) || defined(M_XENIX)
#include <signal.h>
#endif

#ifdef I_FCNTL
#include <fcntl.h>
#endif
#ifdef I_VFORK
#   include <vfork.h>
#endif

#ifdef VOIDSIG
static void (*ihand)();
static void (*qhand)();
#else
static int (*ihand)();
static int (*qhand)();
#endif

ARG *debarg;
STR str_args;
static STAB *stab2;
static STIO *stio;
static struct lstring *lstr;
static int old_record_separator;

double sin(), cos(), atan2(), pow();

char *getlogin();

int
eval(arg,gimme,sp)
register ARG *arg;
int gimme;
register int sp;
{
    register STR *str;
    register int anum;
    register int optype;
    register STR **st;
    int maxarg;
    double value;
    register char *tmps;
    char *tmps2;
    int argflags;
    int argtype;
    union argptr argptr;
    int arglast[8];	/* highest sp for arg--valid only for non-O_LIST args */
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
    extern void grow_dlevel();

    if (!arg)
	goto say_undef;
    optype = arg->arg_type;
    maxarg = arg->arg_len;
    arglast[0] = sp;
    str = arg->arg_ptr.arg_str;
    if (sp + maxarg > stack->ary_max)
	astore(stack, sp + maxarg, Nullstr);
    st = stack->ary_array;

#ifdef DEBUGGING
    if (debug) {
	if (debug & 8) {
	    deb("%s (%lx) %d args:\n",opname[optype],arg,maxarg);
	}
	debname[dlevel] = opname[optype][0];
	debdelim[dlevel] = ':';
	if (++dlevel >= dlmax)
	    grow_dlevel();
    }
#endif

#include "evalargs.xc"

    st += arglast[0];
    switch (optype) {
    case O_RCAT:
	STABSET(str);
	break;
    case O_ITEM:
	if (gimme == G_ARRAY)
	    goto array_return;
	/* FALL THROUGH */
    case O_SCALAR:
	STR_SSET(str,st[1]);
	STABSET(str);
	break;
    case O_ITEM2:
	if (gimme == G_ARRAY)
	    goto array_return;
	--anum;
	STR_SSET(str,st[arglast[anum]-arglast[0]]);
	STABSET(str);
	break;
    case O_ITEM3:
	if (gimme == G_ARRAY)
	goto array_return;
	--anum;
	STR_SSET(str,st[arglast[anum]-arglast[0]]);
	STABSET(str);
	break;
    case O_CONCAT:
	STR_SSET(str,st[1]);
	str_scat(str,st[2]);
	STABSET(str);
	break;
    case O_REPEAT:
	STR_SSET(str,st[1]);
	anum = (int)str_gnum(st[2]);
	if (anum >= 1) {
	    tmpstr = Str_new(50, 0);
	    str_sset(tmpstr,str);
	    tmps = str_get(tmpstr);	/* force to be string */
	    STR_GROW(str, (anum * str->str_cur) + 1);
	    repeatcpy(str->str_ptr, tmps, tmpstr->str_cur, anum);
	    str->str_cur *= anum;
	    str->str_ptr[str->str_cur] = '\0';
	}
	else
	    str_sset(str,&str_no);
	STABSET(str);
	break;
    case O_MATCH:
	sp = do_match(str,arg,
	  gimme,arglast);
	if (gimme == G_ARRAY)
	    goto array_return;
	STABSET(str);
	break;
    case O_NMATCH:
	sp = do_match(str,arg,
	  G_SCALAR,arglast);
	str_sset(str, str_true(str) ? &str_no : &str_yes);
	STABSET(str);
	break;
    case O_SUBST:
	sp = do_subst(str,arg,arglast[0]);
	goto array_return;
    case O_NSUBST:
	sp = do_subst(str,arg,arglast[0]);
	str = arg->arg_ptr.arg_str;
	str_set(str, str_true(str) ? No : Yes);
	goto array_return;
    case O_ASSIGN:
	if (arg[1].arg_flags & AF_ARYOK) {
	    if (arg->arg_len == 1) {
		arg->arg_type = O_LOCAL;
		goto local;
	    }
	    else {
		arg->arg_type = O_AASSIGN;
		goto aassign;
	    }
	}
	else {
	    arg->arg_type = O_SASSIGN;
	    goto sassign;
	}
    case O_LOCAL:
      local:
	arglast[2] = arglast[1];	/* push a null array */
	/* FALL THROUGH */
    case O_AASSIGN:
      aassign:
	sp = do_assign(arg,
	  gimme,arglast);
	goto array_return;
    case O_SASSIGN:
      sassign:
	STR_SSET(str, st[2]);
	STABSET(str);
	break;
    case O_CHOP:
	st -= arglast[0];
	str = arg->arg_ptr.arg_str;
	for (sp = arglast[0] + 1; sp <= arglast[1]; sp++)
	    do_chop(str,st[sp]);
	st += arglast[0];
	break;
    case O_DEFINED:
	if (arg[1].arg_type & A_DONT) {
	    sp = do_defined(str,arg,
		  gimme,arglast);
	    goto array_return;
	}
	else if (str->str_pok || str->str_nok)
	    goto say_yes;
	goto say_no;
    case O_UNDEF:
	if (arg[1].arg_type & A_DONT) {
	    sp = do_undef(str,arg,
	      gimme,arglast);
	    goto array_return;
	}
	else if (str != stab_val(defstab)) {
	    str->str_pok = str->str_nok = 0;
	    STABSET(str);
	}
	goto say_undef;
    case O_STUDY:
	sp = do_study(str,arg,
	  gimme,arglast);
	goto array_return;
    case O_POW:
	value = str_gnum(st[1]);
	value = pow(value,str_gnum(st[2]));
	goto donumset;
    case O_MULTIPLY:
	value = str_gnum(st[1]);
	value *= str_gnum(st[2]);
	goto donumset;
    case O_DIVIDE:
    	if ((value = str_gnum(st[2])) == 0.0)
    	    fatal("Illegal division by zero");
	value = str_gnum(st[1]) / value;
	goto donumset;
    case O_MODULO:
	tmplong = (long) str_gnum(st[2]);
    	if (tmplong == 0L)
    	    fatal("Illegal modulus zero");
	when = (long)str_gnum(st[1]);
#ifndef lint
	if (when >= 0)
	    value = (double)(when % tmplong);
	else
	    value = (double)(tmplong - ((-when - 1) % tmplong)) - 1;
#endif
	goto donumset;
    case O_ADD:
	value = str_gnum(st[1]);
	value += str_gnum(st[2]);
	goto donumset;
    case O_SUBTRACT:
	value = str_gnum(st[1]);
	value -= str_gnum(st[2]);
	goto donumset;
    case O_LEFT_SHIFT:
	value = str_gnum(st[1]);
	anum = (int)str_gnum(st[2]);
#ifndef lint
	value = (double)(U_L(value) << anum);
#endif
	goto donumset;
    case O_RIGHT_SHIFT:
	value = str_gnum(st[1]);
	anum = (int)str_gnum(st[2]);
#ifndef lint
	value = (double)(U_L(value) >> anum);
#endif
	goto donumset;
    case O_LT:
	value = str_gnum(st[1]);
	value = (value < str_gnum(st[2])) ? 1.0 : 0.0;
	goto donumset;
    case O_GT:
	value = str_gnum(st[1]);
	value = (value > str_gnum(st[2])) ? 1.0 : 0.0;
	goto donumset;
    case O_LE:
	value = str_gnum(st[1]);
	value = (value <= str_gnum(st[2])) ? 1.0 : 0.0;
	goto donumset;
    case O_GE:
	value = str_gnum(st[1]);
	value = (value >= str_gnum(st[2])) ? 1.0 : 0.0;
	goto donumset;
    case O_EQ:
	if (dowarn) {
	    if ((!st[1]->str_nok && !looks_like_number(st[1])) ||
		(!st[2]->str_nok && !looks_like_number(st[2])) )
		warn("Possible use of == on string value");
	}
	value = str_gnum(st[1]);
	value = (value == str_gnum(st[2])) ? 1.0 : 0.0;
	goto donumset;
    case O_NE:
	value = str_gnum(st[1]);
	value = (value != str_gnum(st[2])) ? 1.0 : 0.0;
	goto donumset;
    case O_NCMP:
	value = str_gnum(st[1]);
	value -= str_gnum(st[2]);
	if (value > 0.0)
	    value = 1.0;
	else if (value < 0.0)
	    value = -1.0;
	goto donumset;
    case O_BIT_AND:
	if (!sawvec || st[1]->str_nok || st[2]->str_nok) {
	    value = str_gnum(st[1]);
#ifndef lint
	    value = (double)(U_L(value) & U_L(str_gnum(st[2])));
#endif
	    goto donumset;
	}
	else
	    do_vop(optype,str,st[1],st[2]);
	break;
    case O_XOR:
	if (!sawvec || st[1]->str_nok || st[2]->str_nok) {
	    value = str_gnum(st[1]);
#ifndef lint
	    value = (double)(U_L(value) ^ U_L(str_gnum(st[2])));
#endif
	    goto donumset;
	}
	else
	    do_vop(optype,str,st[1],st[2]);
	break;
    case O_BIT_OR:
	if (!sawvec || st[1]->str_nok || st[2]->str_nok) {
	    value = str_gnum(st[1]);
#ifndef lint
	    value = (double)(U_L(value) | U_L(str_gnum(st[2])));
#endif
	    goto donumset;
	}
	else
	    do_vop(optype,str,st[1],st[2]);
	break;
/* use register in evaluating str_true() */
    case O_AND:
	if (str_true(st[1])) {
	    anum = 2;
	    optype = O_ITEM2;
	    argflags = arg[anum].arg_flags;
	    if (gimme == G_ARRAY)
		argflags |= AF_ARYOK;
	    argtype = arg[anum].arg_type & A_MASK;
	    argptr = arg[anum].arg_ptr;
	    maxarg = anum = 1;
	    sp = arglast[0];
	    st -= sp;
	    goto re_eval;
	}
	else {
	    if (assigning) {
		str_sset(str, st[1]);
		STABSET(str);
	    }
	    else
		str = st[1];
	    break;
	}
    case O_OR:
	if (str_true(st[1])) {
	    if (assigning) {
		str_sset(str, st[1]);
		STABSET(str);
	    }
	    else
		str = st[1];
	    break;
	}
	else {
	    anum = 2;
	    optype = O_ITEM2;
	    argflags = arg[anum].arg_flags;
	    if (gimme == G_ARRAY)
		argflags |= AF_ARYOK;
	    argtype = arg[anum].arg_type & A_MASK;
	    argptr = arg[anum].arg_ptr;
	    maxarg = anum = 1;
	    sp = arglast[0];
	    st -= sp;
	    goto re_eval;
	}
    case O_COND_EXPR:
	anum = (str_true(st[1]) ? 2 : 3);
	optype = (anum == 2 ? O_ITEM2 : O_ITEM3);
	argflags = arg[anum].arg_flags;
	if (gimme == G_ARRAY)
	    argflags |= AF_ARYOK;
	argtype = arg[anum].arg_type & A_MASK;
	argptr = arg[anum].arg_ptr;
	maxarg = anum = 1;
	sp = arglast[0];
	st -= sp;
	goto re_eval;
    case O_COMMA:
	if (gimme == G_ARRAY)
	    goto array_return;
	str = st[2];
	break;
    case O_NEGATE:
	value = -str_gnum(st[1]);
	goto donumset;
    case O_NOT:
	value = (double) !str_true(st[1]);
	goto donumset;
    case O_COMPLEMENT:
	if (!sawvec || st[1]->str_nok) {
#ifndef lint
	    value = (double) ~U_L(str_gnum(st[1]));
#endif
	    goto donumset;
	}
	else {
	    STR_SSET(str,st[1]);
	    tmps = str_get(str);
	    for (anum = str->str_cur; anum; anum--, tmps++)
		*tmps = ~*tmps;
	}
	break;
    case O_SELECT:
	stab_fullname(str,defoutstab);
	if (maxarg > 0) {
	    if ((arg[1].arg_type & A_MASK) == A_WORD)
		defoutstab = arg[1].arg_ptr.arg_stab;
	    else
		defoutstab = stabent(str_get(st[1]),TRUE);
	    if (!stab_io(defoutstab))
		stab_io(defoutstab) = stio_new();
	    curoutstab = defoutstab;
	}
	STABSET(str);
	break;
    case O_WRITE:
	if (maxarg == 0)
	    stab = defoutstab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD) {
	    if (!(stab = arg[1].arg_ptr.arg_stab))
		stab = defoutstab;
	}
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab_io(stab)) {
	    str_set(str, No);
	    STABSET(str);
	    break;
	}
	curoutstab = stab;
	fp = stab_io(stab)->ofp;
	debarg = arg;
	if (stab_io(stab)->fmt_stab)
	    form = stab_form(stab_io(stab)->fmt_stab);
	else
	    form = stab_form(stab);
	if (!form || !fp) {
	    if (dowarn) {
		if (form)
		    warn("No format for filehandle");
		else {
		    if (stab_io(stab)->ifp)
			warn("Filehandle only opened for input");
		    else
			warn("Write on closed filehandle");
		}
	    }
	    str_set(str, No);
	    STABSET(str);
	    break;
	}
	format(&outrec,form,sp);
	do_write(&outrec,stab_io(stab),sp);
	if (stab_io(stab)->flags & IOF_FLUSH)
	    (void)fflush(fp);
	str_set(str, Yes);
	STABSET(str);
	break;
    case O_DBMOPEN:
#ifdef SOME_DBM
	stab = arg[1].arg_ptr.arg_stab;
	if (st[3]->str_nok || st[3]->str_pok)
	    anum = (int)str_gnum(st[3]);
	else
	    anum = -1;
	value = (double)hdbmopen(stab_hash(stab),str_get(st[2]),anum);
	goto donumset;
#else
	fatal("No dbm or ndbm on this machine");
#endif
    case O_DBMCLOSE:
#ifdef SOME_DBM
	stab = arg[1].arg_ptr.arg_stab;
	hdbmclose(stab_hash(stab));
	goto say_yes;
#else
	fatal("No dbm or ndbm on this machine");
#endif
    case O_OPEN:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	tmps = str_get(st[2]);
	if (do_open(stab,tmps,st[2]->str_cur)) {
	    value = (double)forkprocess;
	    stab_io(stab)->lines = 0;
	    goto donumset;
	}
	else if (forkprocess == 0)		/* we are a new child */
	    goto say_zero;
	else
	    goto say_undef;
	/* break; */
    case O_TRANS:
	value = (double) do_trans(str,arg);
	str = arg->arg_ptr.arg_str;
	goto donumset;
    case O_NTRANS:
	str_set(arg->arg_ptr.arg_str, do_trans(str,arg) == 0 ? Yes : No);
	str = arg->arg_ptr.arg_str;
	break;
    case O_CLOSE:
	if (maxarg == 0)
	    stab = defoutstab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	str_set(str, do_close(stab,TRUE) ? Yes : No );
	STABSET(str);
	break;
    case O_EACH:
	sp = do_each(str,stab_hash(arg[1].arg_ptr.arg_stab),
	  gimme,arglast);
	goto array_return;
    case O_VALUES:
    case O_KEYS:
	sp = do_kv(str,stab_hash(arg[1].arg_ptr.arg_stab), optype,
	  gimme,arglast);
	goto array_return;
    case O_LARRAY:
	str->str_nok = str->str_pok = 0;
	str->str_u.str_stab = arg[1].arg_ptr.arg_stab;
	str->str_state = SS_ARY;
	break;
    case O_ARRAY:
	ary = stab_array(arg[1].arg_ptr.arg_stab);
	maxarg = ary->ary_fill + 1;
	if (gimme == G_ARRAY) { /* array wanted */
	    sp = arglast[0];
	    st -= sp;
	    if (maxarg > 0 && sp + maxarg > stack->ary_max) {
		astore(stack,sp + maxarg, Nullstr);
		st = stack->ary_array;
	    }
	    st += sp;
	    Copy(ary->ary_array, &st[1], maxarg, STR*);
	    sp += maxarg;
	    goto array_return;
	}
	else {
	    value = (double)maxarg;
	    goto donumset;
	}
    case O_AELEM:
	anum = ((int)str_gnum(st[2])) - arybase;
	str = afetch(stab_array(arg[1].arg_ptr.arg_stab),anum,FALSE);
	break;
    case O_DELETE:
	tmpstab = arg[1].arg_ptr.arg_stab;
	tmps = str_get(st[2]);
	str = hdelete(stab_hash(tmpstab),tmps,st[2]->str_cur);
	if (tmpstab == envstab)
	    setenv(tmps,Nullch);
	if (!str)
	    goto say_undef;
	break;
    case O_LHASH:
	str->str_nok = str->str_pok = 0;
	str->str_u.str_stab = arg[1].arg_ptr.arg_stab;
	str->str_state = SS_HASH;
	break;
    case O_HASH:
	if (gimme == G_ARRAY) { /* array wanted */
	    sp = do_kv(str,stab_hash(arg[1].arg_ptr.arg_stab), optype,
		gimme,arglast);
	    goto array_return;
	}
	else {
	    tmpstab = arg[1].arg_ptr.arg_stab;
	    if (!stab_hash(tmpstab)->tbl_fill)
		goto say_zero;
	    sprintf(buf,"%d/%d",stab_hash(tmpstab)->tbl_fill,
		stab_hash(tmpstab)->tbl_max+1);
	    str_set(str,buf);
	}
	break;
    case O_HELEM:
	tmpstab = arg[1].arg_ptr.arg_stab;
	tmps = str_get(st[2]);
	str = hfetch(stab_hash(tmpstab),tmps,st[2]->str_cur,FALSE);
	break;
    case O_LAELEM:
	anum = ((int)str_gnum(st[2])) - arybase;
	str = afetch(stab_array(arg[1].arg_ptr.arg_stab),anum,TRUE);
	if (!str || str == &str_undef)
	    fatal("Assignment to non-creatable value, subscript %d",anum);
	break;
    case O_LHELEM:
	tmpstab = arg[1].arg_ptr.arg_stab;
	tmps = str_get(st[2]);
	anum = st[2]->str_cur;
	str = hfetch(stab_hash(tmpstab),tmps,anum,TRUE);
	if (!str || str == &str_undef)
	    fatal("Assignment to non-creatable value, subscript \"%s\"",tmps);
	if (tmpstab == envstab)		/* heavy wizardry going on here */
	    str_magic(str, tmpstab, 'E', tmps, anum);	/* str is now magic */
					/* he threw the brick up into the air */
	else if (tmpstab == sigstab)
	    str_magic(str, tmpstab, 'S', tmps, anum);
#ifdef SOME_DBM
	else if (stab_hash(tmpstab)->tbl_dbm)
	    str_magic(str, tmpstab, 'D', tmps, anum);
#endif
	else if (perldb && tmpstab == DBline)
	    str_magic(str, tmpstab, 'L', tmps, anum);
	break;
    case O_LSLICE:
	anum = 2;
	argtype = FALSE;
	goto do_slice_already;
    case O_ASLICE:
	anum = 1;
	argtype = FALSE;
	goto do_slice_already;
    case O_HSLICE:
	anum = 0;
	argtype = FALSE;
	goto do_slice_already;
    case O_LASLICE:
	anum = 1;
	argtype = TRUE;
	goto do_slice_already;
    case O_LHSLICE:
	anum = 0;
	argtype = TRUE;
      do_slice_already:
	sp = do_slice(arg[1].arg_ptr.arg_stab,str,anum,argtype,
	    gimme,arglast);
	goto array_return;
    case O_SPLICE:
	sp = do_splice(stab_array(arg[1].arg_ptr.arg_stab),gimme,arglast);
	goto array_return;
    case O_PUSH:
	if (arglast[2] - arglast[1] != 1)
	    str = do_push(stab_array(arg[1].arg_ptr.arg_stab),arglast);
	else {
	    str = Str_new(51,0);		/* must copy the STR */
	    str_sset(str,st[2]);
	    (void)apush(stab_array(arg[1].arg_ptr.arg_stab),str);
	}
	break;
    case O_POP:
	str = apop(ary = stab_array(arg[1].arg_ptr.arg_stab));
	goto staticalization;
    case O_SHIFT:
	str = ashift(ary = stab_array(arg[1].arg_ptr.arg_stab));
      staticalization:
	if (!str)
	    goto say_undef;
	if (ary->ary_flags & ARF_REAL)
	    (void)str_2static(str);
	break;
    case O_UNPACK:
	sp = do_unpack(str,gimme,arglast);
	goto array_return;
    case O_SPLIT:
	value = str_gnum(st[3]);
	sp = do_split(str, arg[2].arg_ptr.arg_spat, (int)value,
	  gimme,arglast);
	goto array_return;
    case O_LENGTH:
	if (maxarg < 1)
	    value = (double)str_len(stab_val(defstab));
	else
	    value = (double)str_len(st[1]);
	goto donumset;
    case O_SPRINTF:
	do_sprintf(str, sp-arglast[0], st+1);
	break;
    case O_SUBSTR:
	anum = ((int)str_gnum(st[2])) - arybase;	/* anum=where to start*/
	tmps = str_get(st[1]);		/* force conversion to string */
	if (argtype = (str == st[1]))
	    str = arg->arg_ptr.arg_str;
	if (anum < 0)
	    anum += st[1]->str_cur + arybase;
	if (anum < 0 || anum > st[1]->str_cur)
	    str_nset(str,"",0);
	else {
	    optype = maxarg < 3 ? st[1]->str_cur : (int)str_gnum(st[3]);
	    if (optype < 0)
		optype = 0;
	    tmps += anum;
	    anum = st[1]->str_cur - anum;	/* anum=how many bytes left*/
	    if (anum > optype)
		anum = optype;
	    str_nset(str, tmps, anum);
	    if (argtype) {			/* it's an lvalue! */
		lstr = (struct lstring*)str;
		str->str_magic = st[1];
		st[1]->str_rare = 's';
		lstr->lstr_offset = tmps - str_get(st[1]); 
		lstr->lstr_len = anum; 
	    }
	}
	break;
    case O_PACK:
	(void)do_pack(str,arglast);
	break;
    case O_GREP:
	sp = do_grep(arg,str,gimme,arglast);
	goto array_return;
    case O_JOIN:
	do_join(str,arglast);
	break;
    case O_SLT:
	tmps = str_get(st[1]);
	value = (double) (str_cmp(st[1],st[2]) < 0);
	goto donumset;
    case O_SGT:
	tmps = str_get(st[1]);
	value = (double) (str_cmp(st[1],st[2]) > 0);
	goto donumset;
    case O_SLE:
	tmps = str_get(st[1]);
	value = (double) (str_cmp(st[1],st[2]) <= 0);
	goto donumset;
    case O_SGE:
	tmps = str_get(st[1]);
	value = (double) (str_cmp(st[1],st[2]) >= 0);
	goto donumset;
    case O_SEQ:
	tmps = str_get(st[1]);
	value = (double) str_eq(st[1],st[2]);
	goto donumset;
    case O_SNE:
	tmps = str_get(st[1]);
	value = (double) !str_eq(st[1],st[2]);
	goto donumset;
    case O_SCMP:
	tmps = str_get(st[1]);
	value = (double) str_cmp(st[1],st[2]);
	goto donumset;
    case O_SUBR:
	sp = do_subr(arg,gimme,arglast);
	st = stack->ary_array + arglast[0];		/* maybe realloced */
	goto array_return;
    case O_DBSUBR:
	sp = do_subr(arg,gimme,arglast);
	st = stack->ary_array + arglast[0];		/* maybe realloced */
	goto array_return;
    case O_CALLER:
	sp = do_caller(arg,maxarg,gimme,arglast);
	st = stack->ary_array + arglast[0];		/* maybe realloced */
	goto array_return;
    case O_SORT:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	sp = do_sort(str,stab,
	  gimme,arglast);
	goto array_return;
    case O_REVERSE:
	if (gimme == G_ARRAY)
	    sp = do_reverse(arglast);
	else
	    sp = do_sreverse(str, arglast);
	goto array_return;
    case O_WARN:
	if (arglast[2] - arglast[1] != 1) {
	    do_join(str,arglast);
	    tmps = str_get(st[1]);
	}
	else {
	    str = st[2];
	    tmps = str_get(st[2]);
	}
	if (!tmps || !*tmps)
	    tmps = "Warning: something's wrong";
	warn("%s",tmps);
	goto say_yes;
    case O_DIE:
	if (arglast[2] - arglast[1] != 1) {
	    do_join(str,arglast);
	    tmps = str_get(st[1]);
	}
	else {
	    str = st[2];
	    tmps = str_get(st[2]);
	}
	if (!tmps || !*tmps)
	    tmps = "Died";
	fatal("%s",tmps);
	goto say_zero;
    case O_PRTF:
    case O_PRINT:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab)
	    stab = defoutstab;
	if (!stab_io(stab)) {
	    if (dowarn)
		warn("Filehandle never opened");
	    goto say_zero;
	}
	if (!(fp = stab_io(stab)->ofp)) {
	    if (dowarn)  {
		if (stab_io(stab)->ifp)
		    warn("Filehandle opened only for input");
		else
		    warn("Print on closed filehandle");
	    }
	    goto say_zero;
	}
	else {
	    if (optype == O_PRTF || arglast[2] - arglast[1] != 1)
		value = (double)do_aprint(arg,fp,arglast);
	    else {
		value = (double)do_print(st[2],fp);
		if (orslen && optype == O_PRINT)
		    if (fwrite(ors, 1, orslen, fp) == 0)
			goto say_zero;
	    }
	    if (stab_io(stab)->flags & IOF_FLUSH)
		if (fflush(fp) == EOF)
		    goto say_zero;
	}
	goto donumset;
    case O_CHDIR:
	if (maxarg < 1)
	    tmps = Nullch;
	else
	    tmps = str_get(st[1]);
	if (!tmps || !*tmps) {
	    tmpstr = hfetch(stab_hash(envstab),"HOME",4,FALSE);
	    tmps = str_get(tmpstr);
	}
	if (!tmps || !*tmps) {
	    tmpstr = hfetch(stab_hash(envstab),"LOGDIR",6,FALSE);
	    tmps = str_get(tmpstr);
	}
#ifdef TAINT
	taintproper("Insecure dependency in chdir");
#endif
	value = (double)(chdir(tmps) >= 0);
	goto donumset;
    case O_EXIT:
	if (maxarg < 1)
	    anum = 0;
	else
	    anum = (int)str_gnum(st[1]);
	exit(anum);
	goto say_zero;
    case O_RESET:
	if (maxarg < 1)
	    tmps = "";
	else
	    tmps = str_get(st[1]);
	str_reset(tmps,curcmd->c_stash);
	value = 1.0;
	goto donumset;
    case O_LIST:
	if (gimme == G_ARRAY)
	    goto array_return;
	if (maxarg > 0)
	    str = st[sp - arglast[0]];	/* unwanted list, return last item */
	else
	    str = &str_undef;
	break;
    case O_EOF:
	if (maxarg <= 0)
	    stab = last_in_stab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	str_set(str, do_eof(stab) ? Yes : No);
	STABSET(str);
	break;
    case O_GETC:
	if (maxarg <= 0)
	    stab = stdinstab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab)
	    stab = argvstab;
	if (!stab || do_eof(stab)) /* make sure we have fp with something */
	    goto say_undef;
	else {
#ifdef TAINT
	    tainted = 1;
#endif
	    str_set(str," ");
	    *str->str_ptr = getc(stab_io(stab)->ifp); /* should never be EOF */
	}
	STABSET(str);
	break;
    case O_TELL:
	if (maxarg <= 0)
	    stab = last_in_stab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
#ifndef lint
	value = (double)do_tell(stab);
#else
	(void)do_tell(stab);
#endif
	goto donumset;
    case O_RECV:
    case O_READ:
    case O_SYSREAD:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	tmps = str_get(st[2]);
	anum = (int)str_gnum(st[3]);
	errno = 0;
	maxarg = sp - arglast[0];
	if (maxarg > 4)
	    warn("Too many args on read");
	if (maxarg == 4)
	    maxarg = (int)str_gnum(st[4]);
	else
	    maxarg = 0;
	if (!stab_io(stab) || !stab_io(stab)->ifp)
	    goto say_undef;
#ifdef SOCKET
	if (optype == O_RECV) {
	    argtype = sizeof buf;
	    anum = recvfrom(fileno(stab_io(stab)->ifp), tmps, anum, maxarg,
		buf, &argtype);
	    if (anum >= 0) {
		st[2]->str_cur = anum;
		st[2]->str_ptr[anum] = '\0';
		str_nset(str,buf,argtype);
	    }
	    else
		str_sset(str,&str_undef);
	    break;
	}
#else
	if (optype == O_RECV)
	    goto badsock;
#endif
	STR_GROW(st[2], anum+maxarg+1), (tmps = str_get(st[2]));  /* sneaky */
#ifdef SOCKET
	if (stab_io(stab)->type == 's') {
	    argtype = sizeof buf;
	    anum = recvfrom(fileno(stab_io(stab)->ifp), tmps+maxarg, anum, 0,
		buf, &argtype);
	}
	else
#endif
	if (optype == O_SYSREAD) {
	    anum = read(fileno(stab_io(stab)->ifp), tmps+maxarg, anum);
	}
	else
	    anum = fread(tmps+maxarg, 1, anum, stab_io(stab)->ifp);
	if (anum < 0)
	    goto say_undef;
	st[2]->str_cur = anum+maxarg;
	st[2]->str_ptr[anum+maxarg] = '\0';
	value = (double)anum;
	goto donumset;
    case O_SYSWRITE:
    case O_SEND:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	tmps = str_get(st[2]);
	anum = (int)str_gnum(st[3]);
	errno = 0;
	stio = stab_io(stab);
	maxarg = sp - arglast[0];
	if (!stio || !stio->ifp) {
	    anum = -1;
	    if (dowarn) {
		if (optype == O_SYSWRITE)
		    warn("Syswrite on closed filehandle");
		else
		    warn("Send on closed socket");
	    }
	}
	else if (optype == O_SYSWRITE) {
	    if (maxarg > 4)
		warn("Too many args on syswrite");
	    if (maxarg == 4)
		optype = (int)str_gnum(st[4]);
	    else
		optype = 0;
	    anum = write(fileno(stab_io(stab)->ifp), tmps+optype, anum);
	}
#ifdef SOCKET
	else if (maxarg >= 4) {
	    if (maxarg > 4)
		warn("Too many args on send");
	    tmps2 = str_get(st[4]);
	    anum = sendto(fileno(stab_io(stab)->ifp), tmps, st[2]->str_cur,
	      anum, tmps2, st[4]->str_cur);
	}
	else
	    anum = send(fileno(stab_io(stab)->ifp), tmps, st[2]->str_cur, anum);
#else
	else
	    goto badsock;
#endif
	if (anum < 0)
	    goto say_undef;
	value = (double)anum;
	goto donumset;
    case O_SEEK:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	value = str_gnum(st[2]);
	str_set(str, do_seek(stab,
	  (long)value, (int)str_gnum(st[3]) ) ? Yes : No);
	STABSET(str);
	break;
    case O_RETURN:
	tmps = "_SUB_";		/* just fake up a "last _SUB_" */
	optype = O_LAST;
	if (curcsv && curcsv->wantarray == G_ARRAY) {
	    lastretstr = Nullstr;
	    lastspbase = arglast[1];
	    lastsize = arglast[2] - arglast[1];
	}
	else
	    lastretstr = str_static(st[arglast[2] - arglast[0]]);
	goto dopop;
    case O_REDO:
    case O_NEXT:
    case O_LAST:
	if (maxarg > 0) {
	    tmps = str_get(arg[1].arg_ptr.arg_str);
	  dopop:
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
	if (loop_ptr < 0) {
	    if (tmps && strEQ(tmps, "_SUB_"))
		fatal("Can't return outside a subroutine");
	    fatal("Bad label: %s", maxarg > 0 ? tmps : "<null>");
	}
	if (!lastretstr && optype == O_LAST && lastsize) {
	    st -= arglast[0];
	    st += lastspbase + 1;
	    optype = loop_stack[loop_ptr].loop_sp - lastspbase; /* negative */
	    if (optype) {
		for (anum = lastsize; anum > 0; anum--,st++)
		    st[optype] = str_static(st[0]);
	    }
	    longjmp(loop_stack[loop_ptr].loop_env, O_LAST);
	}
	longjmp(loop_stack[loop_ptr].loop_env, optype);
    case O_DUMP:
    case O_GOTO:/* shudder */
	goto_targ = str_get(arg[1].arg_ptr.arg_str);
	if (!*goto_targ)
	    goto_targ = Nullch;		/* just restart from top */
	if (optype == O_DUMP) {
	    do_undump = 1;
	    my_unexec();
	}
	longjmp(top_env, 1);
    case O_INDEX:
	tmps = str_get(st[1]);
	if (maxarg < 3)
	    anum = 0;
	else {
	    anum = (int) str_gnum(st[3]) - arybase;
	    if (anum < 0)
		anum = 0;
	    else if (anum > st[1]->str_cur)
		anum = st[1]->str_cur;
	}
#ifndef lint
	if (!(tmps2 = fbminstr((unsigned char*)tmps + anum,
	  (unsigned char*)tmps + st[1]->str_cur, st[2])))
#else
	if (tmps2 = fbminstr(Null(unsigned char*),Null(unsigned char*),Nullstr))
#endif
	    value = (double)(-1 + arybase);
	else
	    value = (double)(tmps2 - tmps + arybase);
	goto donumset;
    case O_RINDEX:
	tmps = str_get(st[1]);
	tmps2 = str_get(st[2]);
	if (maxarg < 3)
	    anum = st[1]->str_cur;
	else {
	    anum = (int) str_gnum(st[3]) - arybase + st[2]->str_cur;
	    if (anum < 0)
		anum = 0;
	    else if (anum > st[1]->str_cur)
		anum = st[1]->str_cur;
	}
#ifndef lint
	if (!(tmps2 = rninstr(tmps,  tmps  + anum,
			      tmps2, tmps2 + st[2]->str_cur)))
#else
	if (tmps2 = rninstr(Nullch,Nullch,Nullch,Nullch))
#endif
	    value = (double)(-1 + arybase);
	else
	    value = (double)(tmps2 - tmps + arybase);
	goto donumset;
    case O_TIME:
#ifndef lint
	value = (double) time(Null(long*));
#endif
	goto donumset;
    case O_TMS:
	sp = do_tms(str,gimme,arglast);
	goto array_return;
    case O_LOCALTIME:
	if (maxarg < 1)
	    (void)time(&when);
	else
	    when = (long)str_gnum(st[1]);
	sp = do_time(str,localtime(&when),
	  gimme,arglast);
	goto array_return;
    case O_GMTIME:
	if (maxarg < 1)
	    (void)time(&when);
	else
	    when = (long)str_gnum(st[1]);
	sp = do_time(str,gmtime(&when),
	  gimme,arglast);
	goto array_return;
    case O_TRUNCATE:
	sp = do_truncate(str,arg,
	  gimme,arglast);
	goto array_return;
    case O_LSTAT:
    case O_STAT:
	sp = do_stat(str,arg,
	  gimme,arglast);
	goto array_return;
    case O_CRYPT:
#ifdef CRYPT
	tmps = str_get(st[1]);
#ifdef FCRYPT
	str_set(str,fcrypt(tmps,str_get(st[2])));
#else
	str_set(str,crypt(tmps,str_get(st[2])));
#endif
#else
	fatal(
	  "The crypt() function is unimplemented due to excessive paranoia.");
#endif
	break;
    case O_ATAN2:
	value = str_gnum(st[1]);
	value = atan2(value,str_gnum(st[2]));
	goto donumset;
    case O_SIN:
	if (maxarg < 1)
	    value = str_gnum(stab_val(defstab));
	else
	    value = str_gnum(st[1]);
	value = sin(value);
	goto donumset;
    case O_COS:
	if (maxarg < 1)
	    value = str_gnum(stab_val(defstab));
	else
	    value = str_gnum(st[1]);
	value = cos(value);
	goto donumset;
    case O_RAND:
	if (maxarg < 1)
	    value = 1.0;
	else
	    value = str_gnum(st[1]);
	if (value == 0.0)
	    value = 1.0;
#if RANDBITS == 31
	value = rand() * value / 2147483648.0;
#else
#if RANDBITS == 16
	value = rand() * value / 65536.0;
#else
#if RANDBITS == 15
	value = rand() * value / 32768.0;
#else
	value = rand() * value / (double)(((unsigned long)1) << RANDBITS);
#endif
#endif
#endif
	goto donumset;
    case O_SRAND:
	if (maxarg < 1) {
	    (void)time(&when);
	    anum = when;
	}
	else
	    anum = (int)str_gnum(st[1]);
	(void)srand(anum);
	goto say_yes;
    case O_EXP:
	if (maxarg < 1)
	    value = str_gnum(stab_val(defstab));
	else
	    value = str_gnum(st[1]);
	value = exp(value);
	goto donumset;
    case O_LOG:
	if (maxarg < 1)
	    value = str_gnum(stab_val(defstab));
	else
	    value = str_gnum(st[1]);
	value = log(value);
	goto donumset;
    case O_SQRT:
	if (maxarg < 1)
	    value = str_gnum(stab_val(defstab));
	else
	    value = str_gnum(st[1]);
	value = sqrt(value);
	goto donumset;
    case O_INT:
	if (maxarg < 1)
	    value = str_gnum(stab_val(defstab));
	else
	    value = str_gnum(st[1]);
	if (value >= 0.0)
	    (void)modf(value,&value);
	else {
	    (void)modf(-value,&value);
	    value = -value;
	}
	goto donumset;
    case O_ORD:
	if (maxarg < 1)
	    tmps = str_get(stab_val(defstab));
	else
	    tmps = str_get(st[1]);
#ifndef I286
	value = (double) (*tmps & 255);
#else
	anum = (int) *tmps;
	value = (double) (anum & 255);
#endif
	goto donumset;
    case O_ALARM:
	if (maxarg < 1)
	    tmps = str_get(stab_val(defstab));
	else
	    tmps = str_get(st[1]);
	if (!tmps)
	    tmps = "0";
	anum = alarm((unsigned int)atoi(tmps));
	if (anum < 0)
	    goto say_undef;
	value = (double)anum;
	goto donumset;
    case O_SLEEP:
	if (maxarg < 1)
	    tmps = Nullch;
	else
	    tmps = str_get(st[1]);
	(void)time(&when);
	if (!tmps || !*tmps)
	    sleep((32767<<16)+32767);
	else
	    sleep((unsigned int)atoi(tmps));
#ifndef lint
	value = (double)when;
	(void)time(&when);
	value = ((double)when) - value;
#endif
	goto donumset;
    case O_RANGE:
	sp = do_range(gimme,arglast);
	goto array_return;
    case O_F_OR_R:
	if (gimme == G_ARRAY) {		/* it's a range */
	    /* can we optimize to constant array? */
	    if ((arg[1].arg_type & A_MASK) == A_SINGLE &&
	      (arg[2].arg_type & A_MASK) == A_SINGLE) {
		st[2] = arg[2].arg_ptr.arg_str;
		sp = do_range(gimme,arglast);
		st = stack->ary_array;
		maxarg = sp - arglast[0];
		str_free(arg[1].arg_ptr.arg_str);
		str_free(arg[2].arg_ptr.arg_str);
		arg->arg_type = O_ARRAY;
		arg[1].arg_type = A_STAB|A_DONT;
		arg->arg_len = 1;
		stab = arg[1].arg_ptr.arg_stab = aadd(genstab());
		ary = stab_array(stab);
		afill(ary,maxarg - 1);
		st += arglast[0]+1;
		while (maxarg-- > 0)
		    ary->ary_array[maxarg] = str_smake(st[maxarg]);
		goto array_return;
	    }
	    arg->arg_type = optype = O_RANGE;
	    maxarg = arg->arg_len = 2;
	    anum = 2;
	    arg[anum].arg_flags &= ~AF_ARYOK;
	    argflags = arg[anum].arg_flags;
	    argtype = arg[anum].arg_type & A_MASK;
	    arg[anum].arg_type = argtype;
	    argptr = arg[anum].arg_ptr;
	    sp = arglast[0];
	    st -= sp;
	    sp++;
	    goto re_eval;
	}
	arg->arg_type = O_FLIP;
	/* FALL THROUGH */
    case O_FLIP:
	if ((arg[1].arg_type & A_MASK) == A_SINGLE ?
	  last_in_stab && (int)str_gnum(st[1]) == stab_io(last_in_stab)->lines
	  :
	  str_true(st[1]) ) {
	    str_numset(str,0.0);
	    anum = 2;
	    arg->arg_type = optype = O_FLOP;
	    arg[2].arg_type &= ~A_DONT;
	    arg[1].arg_type |= A_DONT;
	    argflags = arg[2].arg_flags;
	    argtype = arg[2].arg_type & A_MASK;
	    argptr = arg[2].arg_ptr;
	    sp = arglast[0];
	    st -= sp++;
	    goto re_eval;
	}
	str_set(str,"");
	break;
    case O_FLOP:
	str_inc(str);
	if ((arg[2].arg_type & A_MASK) == A_SINGLE ?
	  last_in_stab && (int)str_gnum(st[2]) == stab_io(last_in_stab)->lines
	  :
	  str_true(st[2]) ) {
	    arg->arg_type = O_FLIP;
	    arg[1].arg_type &= ~A_DONT;
	    arg[2].arg_type |= A_DONT;
	    str_cat(str,"E0");
	}
	break;
    case O_FORK:
#ifdef FORK
	anum = fork();
	if (!anum) {
	    if (tmpstab = stabent("$",allstabs))
		str_numset(STAB_STR(tmpstab),(double)getpid());
	    hclear(pidstatus);	/* no kids, so don't wait for 'em */
	}
	value = (double)anum;
	goto donumset;
#else
	fatal("Unsupported function fork");
	break;
#endif
    case O_WAIT:
#ifdef WAIT
#ifndef lint
	anum = wait(&argflags);
	if (anum > 0)
	    pidgone(anum,argflags);
	value = (double)anum;
#endif
	statusvalue = (unsigned short)argflags;
	goto donumset;
#else
	fatal("Unsupported function wait");
	break;
#endif
    case O_WAITPID:
#ifdef WAITPID
#ifndef lint
	anum = (int)str_gnum(st[1]);
	optype = (int)str_gnum(st[2]);
	anum = wait4pid(anum, &argflags,optype);
	value = (double)anum;
#endif
	statusvalue = (unsigned short)argflags;
	goto donumset;
#else
	fatal("Unsupported function wait");
	break;
#endif
    case O_SYSTEM:
#ifdef FORK
#ifdef TAINT
	if (arglast[2] - arglast[1] == 1) {
	    taintenv();
	    tainted |= st[2]->str_tainted;
	    taintproper("Insecure dependency in system");
	}
#endif
	while ((anum = vfork()) == -1) {
	    if (errno != EAGAIN) {
		value = -1.0;
		goto donumset;
	    }
	    sleep(5);
	}
	if (anum > 0) {
#ifndef lint
	    ihand = signal(SIGINT, SIG_IGN);
	    qhand = signal(SIGQUIT, SIG_IGN);
	    argtype = wait4pid(anum, &argflags, 0);
#else
	    ihand = qhand = 0;
#endif
	    (void)signal(SIGINT, ihand);
	    (void)signal(SIGQUIT, qhand);
	    statusvalue = (unsigned short)argflags;
	    if (argtype < 0)
		value = -1.0;
	    else {
		value = (double)((unsigned int)argflags & 0xffff);
	    }
	    do_execfree();	/* free any memory child malloced on vfork */
	    goto donumset;
	}
	if ((arg[1].arg_type & A_MASK) == A_STAB)
	    value = (double)do_aexec(st[1],arglast);
	else if (arglast[2] - arglast[1] != 1)
	    value = (double)do_aexec(Nullstr,arglast);
	else {
	    value = (double)do_exec(str_get(str_static(st[2])));
	}
	_exit(-1);
#else /* ! FORK */
	if ((arg[1].arg_type & A_MASK) == A_STAB)
	    value = (double)do_aspawn(st[1],arglast);
	else if (arglast[2] - arglast[1] != 1)
	    value = (double)do_aspawn(Nullstr,arglast);
	else {
	    value = (double)do_spawn(str_get(str_static(st[2])));
	}
	goto donumset;
#endif /* FORK */
    case O_EXEC_OP:
	if ((arg[1].arg_type & A_MASK) == A_STAB)
	    value = (double)do_aexec(st[1],arglast);
	else if (arglast[2] - arglast[1] != 1)
	    value = (double)do_aexec(Nullstr,arglast);
	else {
	    value = (double)do_exec(str_get(str_static(st[2])));
	}
	goto donumset;
    case O_HEX:
	argtype = 4;
	goto snarfnum;

    case O_OCT:
	argtype = 3;

      snarfnum:
	tmplong = 0;
	if (maxarg < 1)
	    tmps = str_get(stab_val(defstab));
	else
	    tmps = str_get(st[1]);
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
		tmplong <<= argtype;
		tmplong += *tmps++ & 15;
		break;
	    case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
	    case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
		if (argtype != 4)
		    goto out;
		tmplong <<= 4;
		tmplong += (*tmps++ & 7) + 9;
		break;
	    case 'x':
		argtype = 4;
		tmps++;
		break;
	    }
	}
      out:
	value = (double)tmplong;
	goto donumset;
    case O_CHOWN:
#ifdef CHOWN
	value = (double)apply(optype,arglast);
	goto donumset;
#else
	fatal("Unsupported function chown");
	break;
#endif
    case O_KILL:
#ifdef KILL
	value = (double)apply(optype,arglast);
	goto donumset;
#else
	fatal("Unsupported function kill");
	break;
#endif
    case O_UNLINK:
    case O_CHMOD:
    case O_UTIME:
	value = (double)apply(optype,arglast);
	goto donumset;
    case O_UMASK:
#ifdef UMASK
	if (maxarg < 1) {
	    anum = umask(0);
	    (void)umask(anum);
	}
	else
	    anum = umask((int)str_gnum(st[1]));
	value = (double)anum;
#ifdef TAINT
	taintproper("Insecure dependency in umask");
#endif
	goto donumset;
#else
	fatal("Unsupported function umask");
	break;
#endif
#ifdef SYSVIPC
    case O_MSGGET:
    case O_SHMGET:
    case O_SEMGET:
	if ((anum = do_ipcget(optype, arglast)) == -1)
	    goto say_undef;
	value = (double)anum;
	goto donumset;
    case O_MSGCTL:
    case O_SHMCTL:
    case O_SEMCTL:
	anum = do_ipcctl(optype, arglast);
	if (anum == -1)
	    goto say_undef;
	if (anum != 0) {
	    value = (double)anum;
	    goto donumset;
	}
	str_set(str,"0 but true");
	STABSET(str);
	break;
    case O_MSGSND:
	value = (double)(do_msgsnd(arglast) >= 0);
	goto donumset;
    case O_MSGRCV:
	value = (double)(do_msgrcv(arglast) >= 0);
	goto donumset;
    case O_SEMOP:
	value = (double)(do_semop(arglast) >= 0);
	goto donumset;
    case O_SHMREAD:
    case O_SHMWRITE:
	value = (double)(do_shmio(optype, arglast) >= 0);
	goto donumset;
#else /* not SYSVIPC */
    case O_MSGGET:
    case O_MSGCTL:
    case O_MSGSND:
    case O_MSGRCV:
    case O_SEMGET:
    case O_SEMCTL:
    case O_SEMOP:
    case O_SHMGET:
    case O_SHMCTL:
    case O_SHMREAD:
    case O_SHMWRITE:
	fatal("System V IPC is not implemented on this machine");
#endif /* not SYSVIPC */
    case O_RENAME:
	tmps = str_get(st[1]);
	tmps2 = str_get(st[2]);
#ifdef TAINT
	taintproper("Insecure dependency in rename");
#endif
#ifdef RENAME
	value = (double)(rename(tmps,tmps2) >= 0);
#else
	if (same_dirent(tmps2, tmps))	/* can always rename to same name */
	    anum = 1;
	else {
	    if (euid || stat(tmps2,&statbuf) < 0 ||
	      (statbuf.st_mode & S_IFMT) != S_IFDIR )
		(void)UNLINK(tmps2);
	    if (!(anum = link(tmps,tmps2)))
		anum = UNLINK(tmps);
	}
	value = (double)(anum >= 0);
#endif
	goto donumset;
    case O_LINK:
#ifdef LINK
	tmps = str_get(st[1]);
	tmps2 = str_get(st[2]);
#ifdef TAINT
	taintproper("Insecure dependency in link");
#endif
	value = (double)(link(tmps,tmps2) >= 0);
	goto donumset;
#else
	fatal("Unsupported function link");
	break;
#endif
    case O_MKDIR:
	tmps = str_get(st[1]);
	anum = (int)str_gnum(st[2]);
#ifdef TAINT
	taintproper("Insecure dependency in mkdir");
#endif
#ifdef MKDIR
	value = (double)(mkdir(tmps,anum) >= 0);
	goto donumset;
#else
	(void)strcpy(buf,"mkdir ");
#endif
#if !defined(MKDIR) || !defined(RMDIR)
      one_liner:
	for (tmps2 = buf+6; *tmps; ) {
	    *tmps2++ = '\\';
	    *tmps2++ = *tmps++;
	}
	(void)strcpy(tmps2," 2>&1");
	rsfp = mypopen(buf,"r");
	if (rsfp) {
	    *buf = '\0';
	    tmps2 = fgets(buf,sizeof buf,rsfp);
	    (void)mypclose(rsfp);
	    if (tmps2 != Nullch) {
		for (errno = 1; errno < sys_nerr; errno++) {
		    if (instr(buf,sys_errlist[errno]))	/* you don't see this */
			goto say_zero;
		}
		errno = 0;
#ifndef EACCES
#define EACCES EPERM
#endif
		if (instr(buf,"cannot make"))
		    errno = EEXIST;
		else if (instr(buf,"existing file"))
		    errno = EEXIST;
		else if (instr(buf,"ile exists"))
		    errno = EEXIST;
		else if (instr(buf,"non-exist"))
		    errno = ENOENT;
		else if (instr(buf,"does not exist"))
		    errno = ENOENT;
		else if (instr(buf,"not empty"))
		    errno = EBUSY;
		else if (instr(buf,"cannot access"))
		    errno = EACCES;
		else
		    errno = EPERM;
		goto say_zero;
	    }
	    else {	/* some mkdirs return no failure indication */
		tmps = str_get(st[1]);
		anum = (stat(tmps,&statbuf) >= 0);
		if (optype == O_RMDIR)
		    anum = !anum;
		if (anum)
		    errno = 0;
		else
		    errno = EACCES;	/* a guess */
		value = (double)anum;
	    }
	    goto donumset;
	}
	else
	    goto say_zero;
#endif
    case O_RMDIR:
	if (maxarg < 1)
	    tmps = str_get(stab_val(defstab));
	else
	    tmps = str_get(st[1]);
#ifdef TAINT
	taintproper("Insecure dependency in rmdir");
#endif
#ifdef RMDIR
	value = (double)(rmdir(tmps) >= 0);
	goto donumset;
#else
	(void)strcpy(buf,"rmdir ");
	goto one_liner;		/* see above in MKDIR */
#endif
    case O_GETPPID:
#ifdef GETPPID
	value = (double)getppid();
	goto donumset;
#else
	fatal("Unsupported function getppid");
	break;
#endif
    case O_GETPGRP:
#ifdef GETPGRP
	if (maxarg < 1)
	    anum = 0;
	else
	    anum = (int)str_gnum(st[1]);
	value = (double)getpgrp(anum);
	goto donumset;
#else
	fatal("The getpgrp() function is unimplemented on this machine");
	break;
#endif
    case O_SETPGRP:
#ifdef SETPGRP
	argtype = (int)str_gnum(st[1]);
	anum = (int)str_gnum(st[2]);
#ifdef TAINT
	taintproper("Insecure dependency in setpgrp");
#endif
	value = (double)(setpgrp(argtype,anum) >= 0);
	goto donumset;
#else
	fatal("The setpgrp() function is unimplemented on this machine");
	break;
#endif
    case O_GETPRIORITY:
#ifdef GETPRIORITY
	argtype = (int)str_gnum(st[1]);
	anum = (int)str_gnum(st[2]);
	value = (double)getpriority(argtype,anum);
	goto donumset;
#else
	fatal("The getpriority() function is unimplemented on this machine");
	break;
#endif
    case O_SETPRIORITY:
#ifdef SETPRIORITY
	argtype = (int)str_gnum(st[1]);
	anum = (int)str_gnum(st[2]);
	optype = (int)str_gnum(st[3]);
#ifdef TAINT
	taintproper("Insecure dependency in setpriority");
#endif
	value = (double)(setpriority(argtype,anum,optype) >= 0);
	goto donumset;
#else
	fatal("The setpriority() function is unimplemented on this machine");
	break;
#endif
    case O_CHROOT:
#ifdef CHROOT
	if (maxarg < 1)
	    tmps = str_get(stab_val(defstab));
	else
	    tmps = str_get(st[1]);
#ifdef TAINT
	taintproper("Insecure dependency in chroot");
#endif
	value = (double)(chroot(tmps) >= 0);
	goto donumset;
#else
	fatal("Unsupported function chroot");
	break;
#endif
    case O_FCNTL:
    case O_IOCTL:
	if (maxarg <= 0)
	    stab = last_in_stab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	argtype = U_I(str_gnum(st[2]));
#ifdef TAINT
	taintproper("Insecure dependency in ioctl");
#endif
	anum = do_ctl(optype,stab,argtype,st[3]);
	if (anum == -1)
	    goto say_undef;
	if (anum != 0) {
	    value = (double)anum;
	    goto donumset;
	}
	str_set(str,"0 but true");
	STABSET(str);
	break;
    case O_FLOCK:
#ifdef FLOCK
	if (maxarg <= 0)
	    stab = last_in_stab;
	else if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (stab && stab_io(stab))
	    fp = stab_io(stab)->ifp;
	else
	    fp = Nullfp;
	if (fp) {
	    argtype = (int)str_gnum(st[2]);
	    value = (double)(flock(fileno(fp),argtype) >= 0);
	}
	else
	    value = 0;
	goto donumset;
#else
	fatal("The flock() function is unimplemented on this machine");
	break;
#endif
    case O_UNSHIFT:
	ary = stab_array(arg[1].arg_ptr.arg_stab);
	if (arglast[2] - arglast[1] != 1)
	    do_unshift(ary,arglast);
	else {
	    STR *tmpstr = Str_new(52,0);	/* must copy the STR */
	    str_sset(tmpstr,st[2]);
	    aunshift(ary,1);
	    (void)astore(ary,0,tmpstr);
	}
	value = (double)(ary->ary_fill + 1);
	goto donumset;

    case O_REQUIRE:
    case O_DOFILE:
    case O_EVAL:
	if (maxarg < 1)
	    tmpstr = stab_val(defstab);
	else
	    tmpstr =
	      (arg[1].arg_type & A_MASK) != A_NULL ? st[1] : stab_val(defstab);
#ifdef TAINT
	tainted |= tmpstr->str_tainted;
	taintproper("Insecure dependency in eval");
#endif
	sp = do_eval(tmpstr, optype, curcmd->c_stash,
	    gimme,arglast);
	goto array_return;

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
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	if (cando(anum,argtype,&statcache))
	    goto say_yes;
	goto say_no;

    case O_FTIS:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	goto say_yes;
    case O_FTEOWNED:
    case O_FTROWNED:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	if (statcache.st_uid == (optype == O_FTEOWNED ? euid : uid) )
	    goto say_yes;
	goto say_no;
    case O_FTZERO:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	if (!statcache.st_size)
	    goto say_yes;
	goto say_no;
    case O_FTSIZE:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	value = (double)statcache.st_size;
	goto donumset;

    case O_FTMTIME:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	value = (double)(basetime - statcache.st_mtime) / 86400.0;
	goto donumset;
    case O_FTATIME:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	value = (double)(basetime - statcache.st_atime) / 86400.0;
	goto donumset;
    case O_FTCTIME:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	value = (double)(basetime - statcache.st_ctime) / 86400.0;
	goto donumset;

    case O_FTSOCK:
#ifdef S_IFSOCK
	anum = S_IFSOCK;
	goto check_file_type;
#else
	goto say_no;
#endif
    case O_FTCHR:
	anum = S_IFCHR;
	goto check_file_type;
    case O_FTBLK:
#ifdef S_IFBLK
	anum = S_IFBLK;
	goto check_file_type;
#else
	goto say_no;
#endif
    case O_FTFILE:
	anum = S_IFREG;
	goto check_file_type;
    case O_FTDIR:
	anum = S_IFDIR;
      check_file_type:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	if ((statcache.st_mode & S_IFMT) == anum )
	    goto say_yes;
	goto say_no;
    case O_FTPIPE:
#ifdef S_IFIFO
	anum = S_IFIFO;
	goto check_file_type;
#else
	goto say_no;
#endif
    case O_FTLINK:
	if (arg[1].arg_type & A_DONT)
	    fatal("You must supply explicit filename with -l");
#ifdef LSTAT
	if (lstat(str_get(st[1]),&statcache) < 0)
	    goto say_undef;
	if ((statcache.st_mode & S_IFMT) == S_IFLNK )
	    goto say_yes;
#endif
	goto say_no;
    case O_SYMLINK:
#ifdef SYMLINK
	tmps = str_get(st[1]);
	tmps2 = str_get(st[2]);
#ifdef TAINT
	taintproper("Insecure dependency in symlink");
#endif
	value = (double)(symlink(tmps,tmps2) >= 0);
	goto donumset;
#else
	fatal("Unsupported function symlink");
#endif
    case O_READLINK:
#ifdef SYMLINK
	if (maxarg < 1)
	    tmps = str_get(stab_val(defstab));
	else
	    tmps = str_get(st[1]);
	anum = readlink(tmps,buf,sizeof buf);
	if (anum < 0)
	    goto say_undef;
	str_nset(str,buf,anum);
	break;
#else
	fatal("Unsupported function readlink");
#endif
    case O_FTSUID:
#ifdef S_ISUID
	anum = S_ISUID;
	goto check_xid;
#else
	goto say_no;
#endif
    case O_FTSGID:
#ifdef S_ISGID
	anum = S_ISGID;
	goto check_xid;
#else
	goto say_no;
#endif
    case O_FTSVTX:
#ifdef S_ISVTX
	anum = S_ISVTX;
#else
	goto say_no;
#endif
      check_xid:
	if (mystat(arg,st[1]) < 0)
	    goto say_undef;
	if (statcache.st_mode & anum)
	    goto say_yes;
	goto say_no;
    case O_FTTTY:
	if (arg[1].arg_type & A_DONT) {
	    stab = arg[1].arg_ptr.arg_stab;
	    tmps = "";
	}
	else
	    stab = stabent(tmps = str_get(st[1]),FALSE);
	if (stab && stab_io(stab) && stab_io(stab)->ifp)
	    anum = fileno(stab_io(stab)->ifp);
	else if (isdigit(*tmps))
	    anum = atoi(tmps);
	else
	    goto say_undef;
	if (isatty(anum))
	    goto say_yes;
	goto say_no;
    case O_FTTEXT:
    case O_FTBINARY:
	str = do_fttext(arg,st[1]);
	break;
#ifdef SOCKET
    case O_SOCKET:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
#ifndef lint
	value = (double)do_socket(stab,arglast);
#else
	(void)do_socket(stab,arglast);
#endif
	goto donumset;
    case O_BIND:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
#ifndef lint
	value = (double)do_bind(stab,arglast);
#else
	(void)do_bind(stab,arglast);
#endif
	goto donumset;
    case O_CONNECT:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
#ifndef lint
	value = (double)do_connect(stab,arglast);
#else
	(void)do_connect(stab,arglast);
#endif
	goto donumset;
    case O_LISTEN:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
#ifndef lint
	value = (double)do_listen(stab,arglast);
#else
	(void)do_listen(stab,arglast);
#endif
	goto donumset;
    case O_ACCEPT:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if ((arg[2].arg_type & A_MASK) == A_WORD)
	    stab2 = arg[2].arg_ptr.arg_stab;
	else
	    stab2 = stabent(str_get(st[2]),TRUE);
	do_accept(str,stab,stab2);
	STABSET(str);
	break;
    case O_GHBYNAME:
	if (maxarg < 1)
	    goto say_undef;
    case O_GHBYADDR:
    case O_GHOSTENT:
	sp = do_ghent(optype,
	  gimme,arglast);
	goto array_return;
    case O_GNBYNAME:
	if (maxarg < 1)
	    goto say_undef;
    case O_GNBYADDR:
    case O_GNETENT:
	sp = do_gnent(optype,
	  gimme,arglast);
	goto array_return;
    case O_GPBYNAME:
	if (maxarg < 1)
	    goto say_undef;
    case O_GPBYNUMBER:
    case O_GPROTOENT:
	sp = do_gpent(optype,
	  gimme,arglast);
	goto array_return;
    case O_GSBYNAME:
	if (maxarg < 1)
	    goto say_undef;
    case O_GSBYPORT:
    case O_GSERVENT:
	sp = do_gsent(optype,
	  gimme,arglast);
	goto array_return;
    case O_SHOSTENT:
	value = (double) sethostent((int)str_gnum(st[1]));
	goto donumset;
    case O_SNETENT:
	value = (double) setnetent((int)str_gnum(st[1]));
	goto donumset;
    case O_SPROTOENT:
	value = (double) setprotoent((int)str_gnum(st[1]));
	goto donumset;
    case O_SSERVENT:
	value = (double) setservent((int)str_gnum(st[1]));
	goto donumset;
    case O_EHOSTENT:
	value = (double) endhostent();
	goto donumset;
    case O_ENETENT:
	value = (double) endnetent();
	goto donumset;
    case O_EPROTOENT:
	value = (double) endprotoent();
	goto donumset;
    case O_ESERVENT:
	value = (double) endservent();
	goto donumset;
    case O_SOCKPAIR:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if ((arg[2].arg_type & A_MASK) == A_WORD)
	    stab2 = arg[2].arg_ptr.arg_stab;
	else
	    stab2 = stabent(str_get(st[2]),TRUE);
#ifndef lint
	value = (double)do_spair(stab,stab2,arglast);
#else
	(void)do_spair(stab,stab2,arglast);
#endif
	goto donumset;
    case O_SHUTDOWN:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
#ifndef lint
	value = (double)do_shutdown(stab,arglast);
#else
	(void)do_shutdown(stab,arglast);
#endif
	goto donumset;
    case O_GSOCKOPT:
    case O_SSOCKOPT:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	sp = do_sopt(optype,stab,arglast);
	goto array_return;
    case O_GETSOCKNAME:
    case O_GETPEERNAME:
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab)
	    goto say_undef;
	sp = do_getsockname(optype,stab,arglast);
	goto array_return;

#else /* SOCKET not defined */
    case O_SOCKET:
    case O_BIND:
    case O_CONNECT:
    case O_LISTEN:
    case O_ACCEPT:
    case O_SOCKPAIR:
    case O_GHBYNAME:
    case O_GHBYADDR:
    case O_GHOSTENT:
    case O_GNBYNAME:
    case O_GNBYADDR:
    case O_GNETENT:
    case O_GPBYNAME:
    case O_GPBYNUMBER:
    case O_GPROTOENT:
    case O_GSBYNAME:
    case O_GSBYPORT:
    case O_GSERVENT:
    case O_SHOSTENT:
    case O_SNETENT:
    case O_SPROTOENT:
    case O_SSERVENT:
    case O_EHOSTENT:
    case O_ENETENT:
    case O_EPROTOENT:
    case O_ESERVENT:
    case O_SHUTDOWN:
    case O_GSOCKOPT:
    case O_SSOCKOPT:
    case O_GETSOCKNAME:
    case O_GETPEERNAME:
      badsock:
	fatal("Unsupported socket function");
#endif /* SOCKET */
    case O_SSELECT:
#ifdef SELECT
	sp = do_select(gimme,arglast);
	goto array_return;
#else
	fatal("select not implemented");
#endif
    case O_FILENO:
	if (maxarg < 1)
	    goto say_undef;
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab || !(stio = stab_io(stab)) || !(fp = stio->ifp))
	    goto say_undef;
	value = fileno(fp);
	goto donumset;
    case O_BINMODE:
	if (maxarg < 1)
	    goto say_undef;
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab || !(stio = stab_io(stab)) || !(fp = stio->ifp))
	    goto say_undef;
#ifdef MSDOS
	str_set(str, (setmode(fileno(fp), O_BINARY) != -1) ? Yes : No);
#else
	str_set(str, Yes);
#endif
	STABSET(str);
	break;
    case O_VEC:
	sp = do_vec(str == st[1], arg->arg_ptr.arg_str, arglast);
	goto array_return;
    case O_GPWNAM:
    case O_GPWUID:
    case O_GPWENT:
#ifdef PASSWD
	sp = do_gpwent(optype,
	  gimme,arglast);
	goto array_return;
    case O_SPWENT:
	value = (double) setpwent();
	goto donumset;
    case O_EPWENT:
	value = (double) endpwent();
	goto donumset;
#else
    case O_EPWENT:
    case O_SPWENT:
	fatal("Unsupported password function");
	break;
#endif
    case O_GGRNAM:
    case O_GGRGID:
    case O_GGRENT:
#ifdef GROUP
	sp = do_ggrent(optype,
	  gimme,arglast);
	goto array_return;
    case O_SGRENT:
	value = (double) setgrent();
	goto donumset;
    case O_EGRENT:
	value = (double) endgrent();
	goto donumset;
#else
    case O_EGRENT:
    case O_SGRENT:
	fatal("Unsupported group function");
	break;
#endif
    case O_GETLOGIN:
#ifdef GETLOGIN
	if (!(tmps = getlogin()))
	    goto say_undef;
	str_set(str,tmps);
#else
	fatal("Unsupported function getlogin");
#endif
	break;
    case O_OPENDIR:
    case O_READDIR:
    case O_TELLDIR:
    case O_SEEKDIR:
    case O_REWINDDIR:
    case O_CLOSEDIR:
	if (maxarg < 1)
	    goto say_undef;
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if (!stab)
	    goto say_undef;
	sp = do_dirop(optype,stab,gimme,arglast);
	goto array_return;
    case O_SYSCALL:
	value = (double)do_syscall(arglast);
	goto donumset;
    case O_PIPE:
#ifdef PIPE
	if ((arg[1].arg_type & A_MASK) == A_WORD)
	    stab = arg[1].arg_ptr.arg_stab;
	else
	    stab = stabent(str_get(st[1]),TRUE);
	if ((arg[2].arg_type & A_MASK) == A_WORD)
	    stab2 = arg[2].arg_ptr.arg_stab;
	else
	    stab2 = stabent(str_get(st[2]),TRUE);
	do_pipe(str,stab,stab2);
	STABSET(str);
#else
	fatal("Unsupported function pipe");
#endif
	break;
    }

  normal_return:
    st[1] = str;
#ifdef DEBUGGING
    if (debug) {
	dlevel--;
	if (debug & 8)
	    deb("%s RETURNS \"%s\"\n",opname[optype],str_get(str));
    }
#endif
    return arglast[0] + 1;

array_return:
#ifdef DEBUGGING
    if (debug) {
	dlevel--;
	if (debug & 8) {
	    anum = sp - arglast[0];
	    switch (anum) {
	    case 0:
		deb("%s RETURNS ()\n",opname[optype]);
		break;
	    case 1:
		deb("%s RETURNS (\"%s\")\n",opname[optype],str_get(st[1]));
		break;
	    default:
		tmps = str_get(st[1]);
		deb("%s RETURNS %d ARGS (\"%s\",%s\"%s\")\n",opname[optype],
		  anum,tmps,anum==2?"":"...,",str_get(st[anum]));
		break;
	    }
	}
    }
#endif
    return sp;

say_yes:
    str = &str_yes;
    goto normal_return;

say_no:
    str = &str_no;
    goto normal_return;

say_undef:
    str = &str_undef;
    goto normal_return;

say_zero:
    value = 0.0;
    /* FALL THROUGH */

donumset:
    str_numset(str,value);
    STABSET(str);
    st[1] = str;
#ifdef DEBUGGING
    if (debug) {
	dlevel--;
	if (debug & 8)
	    deb("%s RETURNS \"%f\"\n",opname[optype],value);
    }
#endif
    return arglast[0] + 1;
}
