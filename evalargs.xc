/* This file is included by eval.c.  It's separate from eval.c to keep
 * kit sizes from getting too big.
 */

/* $Header: evalargs.xc,v 3.0.1.1 89/10/26 23:12:55 lwall Locked $
 *
 * $Log:	evalargs.xc,v $
 * Revision 3.0.1.1  89/10/26  23:12:55  lwall
 * patch1: glob didn't free a temporary string
 * 
 * Revision 3.0  89/10/18  15:17:16  lwall
 * 3.0 baseline
 * 
 */

    for (anum = 1; anum <= maxarg; anum++) {
	argflags = arg[anum].arg_flags;
	argtype = arg[anum].arg_type;
	argptr = arg[anum].arg_ptr;
      re_eval:
	switch (argtype) {
	default:
	    st[++sp] = &str_undef;
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
	    sp = eval(argptr.arg_arg,
		(argflags & AF_ARYOK) ? G_ARRAY : G_SCALAR, sp);
	    if (sp + (maxarg - anum) > stack->ary_max)
		astore(stack, sp + (maxarg - anum), Nullstr);
	    st = stack->ary_array;	/* possibly reallocated */
	    break;
	case A_CMD:
#ifdef DEBUGGING
	    if (debug & 8) {
		tmps = "CMD";
		deb("%d.CMD (%lx) =>\n",anum,argptr.arg_cmd);
	    }
#endif
	    sp = cmd_exec(argptr.arg_cmd, gimme, sp);
	    if (sp + (maxarg - anum) > stack->ary_max)
		astore(stack, sp + (maxarg - anum), Nullstr);
	    st = stack->ary_array;	/* possibly reallocated */
	    break;
	case A_LARYSTAB:
	    ++sp;
	    str = afetch(stab_array(argptr.arg_stab),
		arg[anum].arg_len - arybase, TRUE);
#ifdef DEBUGGING
	    if (debug & 8) {
		(void)sprintf(buf,"LARYSTAB $%s[%d]",stab_name(argptr.arg_stab),
		    arg[anum].arg_len);
		tmps = buf;
	    }
#endif
	    goto do_crement;
	case A_ARYSTAB:
	    st[++sp] = afetch(stab_array(argptr.arg_stab),
		arg[anum].arg_len - arybase, FALSE);
	    if (!st[sp])
		st[sp] = &str_undef;
#ifdef DEBUGGING
	    if (debug & 8) {
		(void)sprintf(buf,"ARYSTAB $%s[%d]",stab_name(argptr.arg_stab),
		    arg[anum].arg_len);
		tmps = buf;
	    }
#endif
	    break;
	case A_STAR:
	    st[++sp] = (STR*)argptr.arg_stab;
#ifdef DEBUGGING
	    if (debug & 8) {
		(void)sprintf(buf,"STAR *%s",stab_name(argptr.arg_stab));
		tmps = buf;
	    }
#endif
	    break;
	case A_LSTAR:
	    str = st[++sp] = (STR*)argptr.arg_stab;
#ifdef DEBUGGING
	    if (debug & 8) {
		(void)sprintf(buf,"LSTAR *%s",stab_name(argptr.arg_stab));
		tmps = buf;
	    }
#endif
	    break;
	case A_STAB:
	    st[++sp] = STAB_STR(argptr.arg_stab);
#ifdef DEBUGGING
	    if (debug & 8) {
		(void)sprintf(buf,"STAB $%s",stab_name(argptr.arg_stab));
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
	    if (argflags & AF_ARYOK) {
		sp = eval(argptr.arg_arg, G_ARRAY, sp);
		if (sp + (maxarg - anum) > stack->ary_max)
		    astore(stack, sp + (maxarg - anum), Nullstr);
		st = stack->ary_array;	/* possibly reallocated */
	    }
	    else {
		sp = eval(argptr.arg_arg, G_SCALAR, sp);
		st = stack->ary_array;	/* possibly reallocated */
		str = st[sp];
		goto do_crement;
	    }
	    break;
	case A_LVAL:
#ifdef DEBUGGING
	    if (debug & 8) {
		(void)sprintf(buf,"LVAL $%s",stab_name(argptr.arg_stab));
		tmps = buf;
	    }
#endif
	    ++sp;
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
		st[sp] = str;
		str = arg->arg_ptr.arg_str;
	    }
	    else if (argflags & AF_POST) {
		st[sp] = str_static(str);
		if (argflags & AF_UP)
		    str_inc(str);
		else
		    str_dec(str);
		STABSET(str);
		str = arg->arg_ptr.arg_str;
	    }
	    else
		st[sp] = str;
	    break;
	case A_LARYLEN:
	    ++sp;
	    stab = argptr.arg_stab;
	    str = stab_array(argptr.arg_stab)->ary_magic;
	    if (argflags & (AF_PRE|AF_POST))
		str_numset(str,(double)(stab_array(stab)->ary_fill+arybase));
#ifdef DEBUGGING
	    tmps = "LARYLEN";
#endif
	    if (!str)
		fatal("panic: A_LEXPR");
	    goto do_crement;
	case A_ARYLEN:
	    stab = argptr.arg_stab;
	    st[++sp] = stab_array(stab)->ary_magic;
	    str_numset(st[sp],(double)(stab_array(stab)->ary_fill+arybase));
#ifdef DEBUGGING
	    tmps = "ARYLEN";
#endif
	    break;
	case A_SINGLE:
	    st[++sp] = argptr.arg_str;
#ifdef DEBUGGING
	    tmps = "SINGLE";
#endif
	    break;
	case A_DOUBLE:
	    (void) interp(str,argptr.arg_str,sp);
	    st = stack->ary_array;
	    st[++sp] = str;
#ifdef DEBUGGING
	    tmps = "DOUBLE";
#endif
	    break;
	case A_BACKTICK:
	    tmps = str_get(interp(str,argptr.arg_str,sp));
	    st = stack->ary_array;
#ifdef TAINT
	    taintproper("Insecure dependency in ``");
#endif
	    fp = mypopen(tmps,"r");
	    str_set(str,"");
	    if (fp) {
		while (str_gets(str,fp,str->str_cur) != Nullch)
		    ;
		statusvalue = mypclose(fp);
	    }
	    else
		statusvalue = -1;

	    st[++sp] = str;
#ifdef DEBUGGING
	    tmps = "BACK";
#endif
	    break;
	case A_WANTARRAY:
	    {
		extern int wantarray;

		if (wantarray == G_ARRAY)
		    st[++sp] = &str_yes;
		else
		    st[++sp] = &str_no;
	    }
#ifdef DEBUGGING
	    tmps = "WANTARRAY";
#endif
	    break;
	case A_INDREAD:
	    last_in_stab = stabent(str_get(STAB_STR(argptr.arg_stab)),TRUE);
	    old_record_separator = record_separator;
	    goto do_read;
	case A_GLOB:
	    argflags |= AF_POST;	/* enable newline chopping */
	    last_in_stab = argptr.arg_stab;
	    old_record_separator = record_separator;
	    if (csh > 0)
		record_separator = 0;
	    else
		record_separator = '\n';
	    goto do_read;
	case A_READ:
	    last_in_stab = argptr.arg_stab;
	    old_record_separator = record_separator;
	  do_read:
	    if (anum > 1)		/* assign to scalar */
		gimme = G_SCALAR;	/* force context to scalar */
	    ++sp;
	    fp = Nullfp;
	    if (stab_io(last_in_stab)) {
		fp = stab_io(last_in_stab)->ifp;
		if (!fp) {
		    if (stab_io(last_in_stab)->flags & IOF_ARGV) {
			if (stab_io(last_in_stab)->flags & IOF_START) {
			    stab_io(last_in_stab)->flags &= ~IOF_START;
			    stab_io(last_in_stab)->lines = 0;
			    if (alen(stab_array(last_in_stab)) < 0) {
				tmpstr = str_make("-",1); /* assume stdin */
				(void)apush(stab_array(last_in_stab), tmpstr);
			    }
			}
			fp = nextargv(last_in_stab);
			if (!fp)  /* Note: fp != stab_io(last_in_stab)->ifp */
			    (void)do_close(last_in_stab,FALSE); /* now it does*/
		    }
		    else if (argtype == A_GLOB) {
			(void) interp(str,stab_val(last_in_stab),sp);
			st = stack->ary_array;
			tmpstr = Str_new(55,0);
			if (csh > 0) {
			    str_set(tmpstr,"/bin/csh -cf 'set nonomatch; glob ");
			    str_scat(tmpstr,str);
			    str_cat(tmpstr,"'|");
			}
			else {
			    str_set(tmpstr, "echo ");
			    str_scat(tmpstr,str);
			    str_cat(tmpstr,
			      "|tr -s ' \t\f\r' '\\012\\012\\012\\012'|");
			}
			(void)do_open(last_in_stab,tmpstr->str_ptr);
			fp = stab_io(last_in_stab)->ifp;
			str_free(tmpstr);
		    }
		}
	    }
	    if (!fp && dowarn)
		warn("Read on closed filehandle <%s>",stab_name(last_in_stab));
	  keepgoing:
	    if (!fp)
		st[sp] = &str_undef;
	    else if (!str_gets(str,fp, optype == O_RCAT ? str->str_cur : 0)) {
		clearerr(fp);
		if (stab_io(last_in_stab)->flags & IOF_ARGV) {
		    fp = nextargv(last_in_stab);
		    if (fp)
			goto keepgoing;
		    (void)do_close(last_in_stab,FALSE);
		    stab_io(last_in_stab)->flags |= IOF_START;
		}
		else if (argflags & AF_POST) {
		    (void)do_close(last_in_stab,FALSE);
		}
		st[sp] = &str_undef;
		record_separator = old_record_separator;
		if (gimme == G_ARRAY) {
		    --sp;
		    goto array_return;
		}
		break;
	    }
	    else {
		stab_io(last_in_stab)->lines++;
		st[sp] = str;
#ifdef TAINT
		str->str_tainted = 1; /* Anything from the outside world...*/
#endif
		if (argflags & AF_POST) {
		    if (str->str_cur > 0)
			str->str_cur--;
		    if (str->str_ptr[str->str_cur] == record_separator)
			str->str_ptr[str->str_cur] = '\0';
		    else
			str->str_cur++;
		    for (tmps = str->str_ptr; *tmps; tmps++)
			if (!isalpha(*tmps) && !isdigit(*tmps) &&
			    index("$&*(){}[]'\";\\|?<>~`",*tmps))
				break;
		    if (*tmps && stat(str->str_ptr,&statbuf) < 0)
			goto keepgoing;		/* unmatched wildcard? */
		}
		if (gimme == G_ARRAY) {
		    st[sp] = str_static(st[sp]);
		    if (++sp > stack->ary_max) {
			astore(stack, sp, Nullstr);
			st = stack->ary_array;
		    }
		    goto keepgoing;
		}
	    }
	    record_separator = old_record_separator;
#ifdef DEBUGGING
	    tmps = "READ";
#endif
	    break;
	}
#ifdef DEBUGGING
	if (debug & 8)
	    deb("%d.%s = '%s'\n",anum,tmps,str_peek(st[sp]));
#endif
	if (anum < 8)
	    arglast[anum] = sp;
    }
