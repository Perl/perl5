/* $Header: consarg.c,v 3.0 89/10/18 15:10:30 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	consarg.c,v $
 * Revision 3.0  89/10/18  15:10:30  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"
static int nothing_in_common();
static int arg_common();
static int spat_common();

ARG *
make_split(stab,arg,limarg)
register STAB *stab;
register ARG *arg;
ARG *limarg;
{
    register SPAT *spat;

    if (arg->arg_type != O_MATCH) {
	Newz(201,spat,1,SPAT);
	spat->spat_next = curstash->tbl_spatroot; /* link into spat list */
	curstash->tbl_spatroot = spat;

	spat->spat_runtime = arg;
	arg = make_match(O_MATCH,stab2arg(A_STAB,defstab),spat);
    }
    Renew(arg,4,ARG);
    arg->arg_len = 3;
    if (limarg) {
	if (limarg->arg_type == O_ITEM) {
	    Copy(limarg+1,arg+3,1,ARG);
	    limarg[1].arg_type = A_NULL;
	    arg_free(limarg);
	}
	else {
	    arg[3].arg_type = A_EXPR;
	    arg[3].arg_ptr.arg_arg = limarg;
	}
    }
    else
	arg[3].arg_type = A_NULL;
    arg->arg_type = O_SPLIT;
    spat = arg[2].arg_ptr.arg_spat;
    spat->spat_repl = stab2arg(A_STAB,aadd(stab));
    if (spat->spat_short) {	/* exact match can bypass regexec() */
	if (!((spat->spat_flags & SPAT_SCANFIRST) &&
	    (spat->spat_flags & SPAT_ALL) )) {
	    str_free(spat->spat_short);
	    spat->spat_short = Nullstr;
	}
    }
    return arg;
}

ARG *
mod_match(type,left,pat)
register ARG *left;
register ARG *pat;
{

    register SPAT *spat;
    register ARG *newarg;

    if ((pat->arg_type == O_MATCH ||
	 pat->arg_type == O_SUBST ||
	 pat->arg_type == O_TRANS ||
	 pat->arg_type == O_SPLIT
	) &&
	pat[1].arg_ptr.arg_stab == defstab ) {
	switch (pat->arg_type) {
	case O_MATCH:
	    newarg = make_op(type == O_MATCH ? O_MATCH : O_NMATCH,
		pat->arg_len,
		left,Nullarg,Nullarg);
	    break;
	case O_SUBST:
	    newarg = l(make_op(type == O_MATCH ? O_SUBST : O_NSUBST,
		pat->arg_len,
		left,Nullarg,Nullarg));
	    break;
	case O_TRANS:
	    newarg = l(make_op(type == O_MATCH ? O_TRANS : O_NTRANS,
		pat->arg_len,
		left,Nullarg,Nullarg));
	    break;
	case O_SPLIT:
	    newarg = make_op(type == O_MATCH ? O_SPLIT : O_SPLIT,
		pat->arg_len,
		left,Nullarg,Nullarg);
	    break;
	}
	if (pat->arg_len >= 2) {
	    newarg[2].arg_type = pat[2].arg_type;
	    newarg[2].arg_ptr = pat[2].arg_ptr;
	    newarg[2].arg_flags = pat[2].arg_flags;
	    if (pat->arg_len >= 3) {
		newarg[3].arg_type = pat[3].arg_type;
		newarg[3].arg_ptr = pat[3].arg_ptr;
		newarg[3].arg_flags = pat[3].arg_flags;
	    }
	}
	Safefree(pat);
    }
    else {
	Newz(202,spat,1,SPAT);
	spat->spat_next = curstash->tbl_spatroot; /* link into spat list */
	curstash->tbl_spatroot = spat;

	spat->spat_runtime = pat;
	newarg = make_op(type,2,left,Nullarg,Nullarg);
	newarg[2].arg_type = A_SPAT | A_DONT;
	newarg[2].arg_ptr.arg_spat = spat;
    }

    return newarg;
}

ARG *
make_op(type,newlen,arg1,arg2,arg3)
int type;
int newlen;
ARG *arg1;
ARG *arg2;
ARG *arg3;
{
    register ARG *arg;
    register ARG *chld;
    register int doarg;
    extern ARG *arg4;	/* should be normal arguments, really */
    extern ARG *arg5;

    arg = op_new(newlen);
    arg->arg_type = type;
    doarg = opargs[type];
    if (chld = arg1) {
	if (chld->arg_type == O_ITEM &&
	    (hoistable[chld[1].arg_type] || chld[1].arg_type == A_LVAL ||
	     (chld[1].arg_type == A_LEXPR &&
	      (chld[1].arg_ptr.arg_arg->arg_type == O_LIST ||
	       chld[1].arg_ptr.arg_arg->arg_type == O_ARRAY ||
	       chld[1].arg_ptr.arg_arg->arg_type == O_HASH ))))
	{
	    arg[1].arg_type = chld[1].arg_type;
	    arg[1].arg_ptr = chld[1].arg_ptr;
	    arg[1].arg_flags |= chld[1].arg_flags;
	    arg[1].arg_len = chld[1].arg_len;
	    free_arg(chld);
	}
	else {
	    arg[1].arg_type = A_EXPR;
	    arg[1].arg_ptr.arg_arg = chld;
	}
	if (!(doarg & 1))
	    arg[1].arg_type |= A_DONT;
	if (doarg & 2)
	    arg[1].arg_flags |= AF_ARYOK;
    }
    doarg >>= 2;
    if (chld = arg2) {
	if (chld->arg_type == O_ITEM && 
	    (hoistable[chld[1].arg_type] || 
	     (type == O_ASSIGN && 
	      ((chld[1].arg_type == A_READ && !(arg[1].arg_type & A_DONT))
		||
	       (chld[1].arg_type == A_INDREAD && !(arg[1].arg_type & A_DONT))
		||
	       (chld[1].arg_type == A_GLOB && !(arg[1].arg_type & A_DONT))
	      ) ) ) ) {
	    arg[2].arg_type = chld[1].arg_type;
	    arg[2].arg_ptr = chld[1].arg_ptr;
	    arg[2].arg_len = chld[1].arg_len;
	    free_arg(chld);
	}
	else {
	    arg[2].arg_type = A_EXPR;
	    arg[2].arg_ptr.arg_arg = chld;
	}
	if (!(doarg & 1))
	    arg[2].arg_type |= A_DONT;
	if (doarg & 2)
	    arg[2].arg_flags |= AF_ARYOK;
    }
    doarg >>= 2;
    if (chld = arg3) {
	if (chld->arg_type == O_ITEM && hoistable[chld[1].arg_type]) {
	    arg[3].arg_type = chld[1].arg_type;
	    arg[3].arg_ptr = chld[1].arg_ptr;
	    arg[3].arg_len = chld[1].arg_len;
	    free_arg(chld);
	}
	else {
	    arg[3].arg_type = A_EXPR;
	    arg[3].arg_ptr.arg_arg = chld;
	}
	if (!(doarg & 1))
	    arg[3].arg_type |= A_DONT;
	if (doarg & 2)
	    arg[3].arg_flags |= AF_ARYOK;
    }
    if (newlen >= 4 && (chld = arg4)) {
	if (chld->arg_type == O_ITEM && hoistable[chld[1].arg_type]) {
	    arg[4].arg_type = chld[1].arg_type;
	    arg[4].arg_ptr = chld[1].arg_ptr;
	    arg[4].arg_len = chld[1].arg_len;
	    free_arg(chld);
	}
	else {
	    arg[4].arg_type = A_EXPR;
	    arg[4].arg_ptr.arg_arg = chld;
	}
    }
    if (newlen >= 5 && (chld = arg5)) {
	if (chld->arg_type == O_ITEM && hoistable[chld[1].arg_type]) {
	    arg[5].arg_type = chld[1].arg_type;
	    arg[5].arg_ptr = chld[1].arg_ptr;
	    arg[5].arg_len = chld[1].arg_len;
	    free_arg(chld);
	}
	else {
	    arg[5].arg_type = A_EXPR;
	    arg[5].arg_ptr.arg_arg = chld;
	}
    }
#ifdef DEBUGGING
    if (debug & 16) {
	fprintf(stderr,"%lx <= make_op(%s",arg,opname[arg->arg_type]);
	if (arg1)
	    fprintf(stderr,",%s=%lx",
		argname[arg[1].arg_type&A_MASK],arg[1].arg_ptr.arg_arg);
	if (arg2)
	    fprintf(stderr,",%s=%lx",
		argname[arg[2].arg_type&A_MASK],arg[2].arg_ptr.arg_arg);
	if (arg3)
	    fprintf(stderr,",%s=%lx",
		argname[arg[3].arg_type&A_MASK],arg[3].arg_ptr.arg_arg);
	if (newlen >= 4)
	    fprintf(stderr,",%s=%lx",
		argname[arg[4].arg_type&A_MASK],arg[4].arg_ptr.arg_arg);
	if (newlen >= 5)
	    fprintf(stderr,",%s=%lx",
		argname[arg[5].arg_type&A_MASK],arg[5].arg_ptr.arg_arg);
	fprintf(stderr,")\n");
    }
#endif
    evalstatic(arg);		/* see if we can consolidate anything */
    return arg;
}

void
evalstatic(arg)
register ARG *arg;
{
    register STR *str;
    register STR *s1;
    register STR *s2;
    double value;		/* must not be register */
    register char *tmps;
    int i;
    unsigned long tmplong;
    long tmp2;
    double exp(), log(), sqrt(), modf();
    char *crypt();
    double sin(), cos(), atan2(), pow();

    if (!arg || !arg->arg_len)
	return;

    if ((arg[1].arg_type == A_SINGLE || arg->arg_type == O_AELEM) &&
        (arg->arg_len == 1 || arg[2].arg_type == A_SINGLE) ) {
	str = Str_new(20,0);
	s1 = arg[1].arg_ptr.arg_str;
	if (arg->arg_len > 1)
	    s2 = arg[2].arg_ptr.arg_str;
	else
	    s2 = Nullstr;
	switch (arg->arg_type) {
	case O_AELEM:
	    i = (int)str_gnum(s2);
	    if (i < 32767 && i >= 0) {
		arg->arg_type = O_ITEM;
		arg->arg_len = 1;
		arg[1].arg_type = A_ARYSTAB;	/* $abc[123] is hoistable now */
		arg[1].arg_len = i;
		arg[1].arg_ptr = arg[1].arg_ptr;	/* get stab pointer */
		str_free(s2);
	    }
	    /* FALL THROUGH */
	default:
	    str_free(str);
	    str = Nullstr;		/* can't be evaluated yet */
	    break;
	case O_CONCAT:
	    str_sset(str,s1);
	    str_scat(str,s2);
	    break;
	case O_REPEAT:
	    i = (int)str_gnum(s2);
	    while (i-- > 0)
		str_scat(str,s1);
	    break;
	case O_MULTIPLY:
	    value = str_gnum(s1);
	    str_numset(str,value * str_gnum(s2));
	    break;
	case O_DIVIDE:
	    value = str_gnum(s2);
	    if (value == 0.0)
		yyerror("Illegal division by constant zero");
	    else
		str_numset(str,str_gnum(s1) / value);
	    break;
	case O_MODULO:
	    tmplong = (long)str_gnum(s2);
	    if (tmplong == 0L) {
		yyerror("Illegal modulus of constant zero");
		break;
	    }
	    tmp2 = (long)str_gnum(s1);
#ifndef lint
	    if (tmp2 >= 0)
		str_numset(str,(double)(tmp2 % tmplong));
	    else
		str_numset(str,(double)(tmplong - (-tmp2 % tmplong)));
#else
	    tmp2 = tmp2;
#endif
	    break;
	case O_ADD:
	    value = str_gnum(s1);
	    str_numset(str,value + str_gnum(s2));
	    break;
	case O_SUBTRACT:
	    value = str_gnum(s1);
	    str_numset(str,value - str_gnum(s2));
	    break;
	case O_LEFT_SHIFT:
	    value = str_gnum(s1);
	    i = (int)str_gnum(s2);
#ifndef lint
	    str_numset(str,(double)(((long)value) << i));
#endif
	    break;
	case O_RIGHT_SHIFT:
	    value = str_gnum(s1);
	    i = (int)str_gnum(s2);
#ifndef lint
	    str_numset(str,(double)(((long)value) >> i));
#endif
	    break;
	case O_LT:
	    value = str_gnum(s1);
	    str_numset(str,(value < str_gnum(s2)) ? 1.0 : 0.0);
	    break;
	case O_GT:
	    value = str_gnum(s1);
	    str_numset(str,(value > str_gnum(s2)) ? 1.0 : 0.0);
	    break;
	case O_LE:
	    value = str_gnum(s1);
	    str_numset(str,(value <= str_gnum(s2)) ? 1.0 : 0.0);
	    break;
	case O_GE:
	    value = str_gnum(s1);
	    str_numset(str,(value >= str_gnum(s2)) ? 1.0 : 0.0);
	    break;
	case O_EQ:
	    if (dowarn) {
		if ((!s1->str_nok && !looks_like_number(s1)) ||
		    (!s2->str_nok && !looks_like_number(s2)) )
		    warn("Possible use of == on string value");
	    }
	    value = str_gnum(s1);
	    str_numset(str,(value == str_gnum(s2)) ? 1.0 : 0.0);
	    break;
	case O_NE:
	    value = str_gnum(s1);
	    str_numset(str,(value != str_gnum(s2)) ? 1.0 : 0.0);
	    break;
	case O_BIT_AND:
	    value = str_gnum(s1);
#ifndef lint
	    str_numset(str,(double)(((long)value) & ((long)str_gnum(s2))));
#endif
	    break;
	case O_XOR:
	    value = str_gnum(s1);
#ifndef lint
	    str_numset(str,(double)(((long)value) ^ ((long)str_gnum(s2))));
#endif
	    break;
	case O_BIT_OR:
	    value = str_gnum(s1);
#ifndef lint
	    str_numset(str,(double)(((long)value) | ((long)str_gnum(s2))));
#endif
	    break;
	case O_AND:
	    if (str_true(s1))
		str_sset(str,s2);
	    else
		str_sset(str,s1);
	    break;
	case O_OR:
	    if (str_true(s1))
		str_sset(str,s1);
	    else
		str_sset(str,s2);
	    break;
	case O_COND_EXPR:
	    if ((arg[3].arg_type & A_MASK) != A_SINGLE) {
		str_free(str);
		str = Nullstr;
	    }
	    else {
		if (str_true(s1))
		    str_sset(str,s2);
		else
		    str_sset(str,arg[3].arg_ptr.arg_str);
		str_free(arg[3].arg_ptr.arg_str);
	    }
	    break;
	case O_NEGATE:
	    str_numset(str,(double)(-str_gnum(s1)));
	    break;
	case O_NOT:
	    str_numset(str,(double)(!str_true(s1)));
	    break;
	case O_COMPLEMENT:
#ifndef lint
	    str_numset(str,(double)(~(long)str_gnum(s1)));
#endif
	    break;
	case O_SIN:
	    str_numset(str,sin(str_gnum(s1)));
	    break;
	case O_COS:
	    str_numset(str,cos(str_gnum(s1)));
	    break;
	case O_ATAN2:
	    value = str_gnum(s1);
	    str_numset(str,atan2(value, str_gnum(s2)));
	    break;
	case O_POW:
	    value = str_gnum(s1);
	    str_numset(str,pow(value, str_gnum(s2)));
	    break;
	case O_LENGTH:
	    str_numset(str, (double)str_len(s1));
	    break;
	case O_SLT:
	    str_numset(str,(double)(str_cmp(s1,s2) < 0));
	    break;
	case O_SGT:
	    str_numset(str,(double)(str_cmp(s1,s2) > 0));
	    break;
	case O_SLE:
	    str_numset(str,(double)(str_cmp(s1,s2) <= 0));
	    break;
	case O_SGE:
	    str_numset(str,(double)(str_cmp(s1,s2) >= 0));
	    break;
	case O_SEQ:
	    str_numset(str,(double)(str_eq(s1,s2)));
	    break;
	case O_SNE:
	    str_numset(str,(double)(!str_eq(s1,s2)));
	    break;
	case O_CRYPT:
#ifdef CRYPT
	    tmps = str_get(s1);
	    str_set(str,crypt(tmps,str_get(s2)));
#else
	    yyerror(
	    "The crypt() function is unimplemented due to excessive paranoia.");
#endif
	    break;
	case O_EXP:
	    str_numset(str,exp(str_gnum(s1)));
	    break;
	case O_LOG:
	    str_numset(str,log(str_gnum(s1)));
	    break;
	case O_SQRT:
	    str_numset(str,sqrt(str_gnum(s1)));
	    break;
	case O_INT:
	    value = str_gnum(s1);
	    if (value >= 0.0)
		(void)modf(value,&value);
	    else {
		(void)modf(-value,&value);
		value = -value;
	    }
	    str_numset(str,value);
	    break;
	case O_ORD:
#ifndef I286
	    str_numset(str,(double)(*str_get(s1)));
#else
	    {
		int  zapc;
		char *zaps;

		zaps = str_get(s1);
		zapc = (int) *zaps;
		str_numset(str,(double)(zapc));
	    }
#endif
	    break;
	}
	if (str) {
	    arg->arg_type = O_ITEM;	/* note arg1 type is already SINGLE */
	    str_free(s1);
	    str_free(s2);
	    arg[1].arg_ptr.arg_str = str;
	}
    }
}

ARG *
l(arg)
register ARG *arg;
{
    register int i;
    register ARG *arg1;
    register ARG *arg2;
    SPAT *spat;
    int arghog = 0;

    i = arg[1].arg_type & A_MASK;

    arg->arg_flags |= AF_COMMON;	/* assume something in common */
					/* which forces us to copy things */

    if (i == A_ARYLEN) {
	arg[1].arg_type = A_LARYLEN;
	return arg;
    }
    if (i == A_ARYSTAB) {
	arg[1].arg_type = A_LARYSTAB;
	return arg;
    }

    /* see if it's an array reference */

    if (i == A_EXPR || i == A_LEXPR) {
	arg1 = arg[1].arg_ptr.arg_arg;

	if (arg1->arg_type == O_LIST || arg1->arg_type == O_ITEM) {
						/* assign to list */
	    if (arg->arg_len > 1) {
		dehoist(arg,2);
		arg2 = arg[2].arg_ptr.arg_arg;
		if (nothing_in_common(arg1,arg2))
		    arg->arg_flags &= ~AF_COMMON;
		if (arg->arg_type == O_ASSIGN) {
		    if (arg1->arg_flags & AF_LOCAL)
			arg->arg_flags |= AF_LOCAL;
		    arg[1].arg_flags |= AF_ARYOK;
		    arg[2].arg_flags |= AF_ARYOK;
		}
	    }
	    else if (arg->arg_type != O_CHOP)
		arg->arg_type = O_ASSIGN;	/* possible local(); */
	    for (i = arg1->arg_len; i >= 1; i--) {
		switch (arg1[i].arg_type) {
		case A_STAR: case A_LSTAR:
		    arg1[i].arg_type = A_LSTAR;
		    break;
		case A_STAB: case A_LVAL:
		    arg1[i].arg_type = A_LVAL;
		    break;
		case A_ARYLEN: case A_LARYLEN:
		    arg1[i].arg_type = A_LARYLEN;
		    break;
		case A_ARYSTAB: case A_LARYSTAB:
		    arg1[i].arg_type = A_LARYSTAB;
		    break;
		case A_EXPR: case A_LEXPR:
		    arg1[i].arg_type = A_LEXPR;
		    switch(arg1[i].arg_ptr.arg_arg->arg_type) {
		    case O_ARRAY: case O_LARRAY:
			arg1[i].arg_ptr.arg_arg->arg_type = O_LARRAY;
			arghog = 1;
			break;
		    case O_AELEM: case O_LAELEM:
			arg1[i].arg_ptr.arg_arg->arg_type = O_LAELEM;
			break;
		    case O_HASH: case O_LHASH:
			arg1[i].arg_ptr.arg_arg->arg_type = O_LHASH;
			arghog = 1;
			break;
		    case O_HELEM: case O_LHELEM:
			arg1[i].arg_ptr.arg_arg->arg_type = O_LHELEM;
			break;
		    case O_ASLICE: case O_LASLICE:
			arg1[i].arg_ptr.arg_arg->arg_type = O_LASLICE;
			break;
		    case O_HSLICE: case O_LHSLICE:
			arg1[i].arg_ptr.arg_arg->arg_type = O_LHSLICE;
			break;
		    default:
			goto ill_item;
		    }
		    break;
		default:
		  ill_item:
		    (void)sprintf(tokenbuf, "Illegal item (%s) as lvalue",
		      argname[arg1[i].arg_type&A_MASK]);
		    yyerror(tokenbuf);
		}
	    }
	    if (arg->arg_len > 1) {
		if (arg2->arg_type == O_SPLIT && !arg2[3].arg_type && !arghog) {
		    arg2[3].arg_type = A_SINGLE;
		    arg2[3].arg_ptr.arg_str =
		      str_nmake((double)arg1->arg_len + 1); /* limit split len*/
		}
	    }
	}
	else if (arg1->arg_type == O_AELEM || arg1->arg_type == O_LAELEM)
	    arg1->arg_type = O_LAELEM;
	else if (arg1->arg_type == O_ARRAY || arg1->arg_type == O_LARRAY) {
	    arg1->arg_type = O_LARRAY;
	    if (arg->arg_len > 1) {
		dehoist(arg,2);
		arg2 = arg[2].arg_ptr.arg_arg;
		if (arg2->arg_type == O_SPLIT) { /* use split's builtin =?*/
		    spat = arg2[2].arg_ptr.arg_spat;
		    if (spat->spat_repl[1].arg_ptr.arg_stab == defstab &&
		      nothing_in_common(arg1,spat->spat_repl)) {
			spat->spat_repl[1].arg_ptr.arg_stab =
			    arg1[1].arg_ptr.arg_stab;
			arg_free(arg1);	/* recursive */
			free_arg(arg);	/* non-recursive */
			return arg2;	/* split has builtin assign */
		    }
		}
		else if (nothing_in_common(arg1,arg2))
		    arg->arg_flags &= ~AF_COMMON;
		if (arg->arg_type == O_ASSIGN) {
		    arg[1].arg_flags |= AF_ARYOK;
		    arg[2].arg_flags |= AF_ARYOK;
		}
	    }
	}
	else if (arg1->arg_type == O_HELEM || arg1->arg_type == O_LHELEM)
	    arg1->arg_type = O_LHELEM;
	else if (arg1->arg_type == O_HASH || arg1->arg_type == O_LHASH) {
	    arg1->arg_type = O_LHASH;
	    if (arg->arg_len > 1) {
		dehoist(arg,2);
		arg2 = arg[2].arg_ptr.arg_arg;
		if (nothing_in_common(arg1,arg2))
		    arg->arg_flags &= ~AF_COMMON;
		if (arg->arg_type == O_ASSIGN) {
		    arg[1].arg_flags |= AF_ARYOK;
		    arg[2].arg_flags |= AF_ARYOK;
		}
	    }
	}
	else if (arg1->arg_type == O_ASLICE) {
	    arg1->arg_type = O_LASLICE;
	    if (arg->arg_type == O_ASSIGN) {
		arg[1].arg_flags |= AF_ARYOK;
		arg[2].arg_flags |= AF_ARYOK;
	    }
	}
	else if (arg1->arg_type == O_HSLICE) {
	    arg1->arg_type = O_LHSLICE;
	    if (arg->arg_type == O_ASSIGN) {
		arg[1].arg_flags |= AF_ARYOK;
		arg[2].arg_flags |= AF_ARYOK;
	    }
	}
	else if ((arg->arg_type == O_DEFINED || arg->arg_type == O_UNDEF) &&
	  (arg1->arg_type == (perldb ? O_DBSUBR : O_SUBR)) ) {
	    arg[1].arg_type |= A_DONT;
	}
	else if (arg1->arg_type == O_SUBSTR || arg1->arg_type == O_VEC) {
	    (void)l(arg1);
	    Renewc(arg1->arg_ptr.arg_str, 1, struct lstring, STR);
			/* grow string struct to hold an lstring struct */
	}
	else if (arg1->arg_type == O_ASSIGN) {
	    if (arg->arg_type == O_CHOP)
		arg[1].arg_flags &= ~AF_ARYOK;	/* grandfather chop idiom */
	}
	else {
	    (void)sprintf(tokenbuf,
	      "Illegal expression (%s) as lvalue",opname[arg1->arg_type]);
	    yyerror(tokenbuf);
	}
	arg[1].arg_type = A_LEXPR | (arg[1].arg_type & A_DONT);
	if (arg->arg_type == O_ASSIGN && (arg1[1].arg_flags & AF_ARYOK)) {
	    arg[1].arg_flags |= AF_ARYOK;
	    if (arg->arg_len > 1)
		arg[2].arg_flags |= AF_ARYOK;
	}
#ifdef DEBUGGING
	if (debug & 16)
	    fprintf(stderr,"lval LEXPR\n");
#endif
	return arg;
    }
    if (i == A_STAR || i == A_LSTAR) {
	arg[1].arg_type = A_LSTAR | (arg[1].arg_type & A_DONT);
	return arg;
    }

    /* not an array reference, should be a register name */

    if (i != A_STAB && i != A_LVAL) {
	(void)sprintf(tokenbuf,
	  "Illegal item (%s) as lvalue",argname[arg[1].arg_type&A_MASK]);
	yyerror(tokenbuf);
    }
    arg[1].arg_type = A_LVAL | (arg[1].arg_type & A_DONT);
#ifdef DEBUGGING
    if (debug & 16)
	fprintf(stderr,"lval LVAL\n");
#endif
    return arg;
}

ARG *
fixl(type,arg)
int type;
ARG *arg;
{
    if (type == O_DEFINED || type == O_UNDEF) {
	if (arg->arg_type != O_ITEM)
	    arg = hide_ary(arg);
	if (arg->arg_type == O_ITEM) {
	    type = arg[1].arg_type & A_MASK;
	    if (type == A_EXPR || type == A_LEXPR)
		arg[1].arg_type = A_LEXPR|A_DONT;
	}
    }
    return arg;
}

dehoist(arg,i)
ARG *arg;
{
    ARG *tmparg;

    if (arg[i].arg_type != A_EXPR) {	/* dehoist */
	tmparg = make_op(O_ITEM,1,Nullarg,Nullarg,Nullarg);
	tmparg[1] = arg[i];
	arg[i].arg_ptr.arg_arg = tmparg;
	arg[i].arg_type = A_EXPR;
    }
}

ARG *
addflags(i,flags,arg)
register ARG *arg;
{
    arg[i].arg_flags |= flags;
    return arg;
}

ARG *
hide_ary(arg)
ARG *arg;
{
    if (arg->arg_type == O_ARRAY || arg->arg_type == O_HASH)
	return make_op(O_ITEM,1,arg,Nullarg,Nullarg);
    return arg;
}

/* maybe do a join on multiple array dimensions */

ARG *
jmaybe(arg)
register ARG *arg;
{
    if (arg && arg->arg_type == O_COMMA) {
	arg = listish(arg);
	arg = make_op(O_JOIN, 2,
	    stab2arg(A_STAB,stabent(";",TRUE)),
	    make_list(arg),
	    Nullarg);
    }
    return arg;
}

ARG *
make_list(arg)
register ARG *arg;
{
    register int i;
    register ARG *node;
    register ARG *nxtnode;
    register int j;
    STR *tmpstr;

    if (!arg) {
	arg = op_new(0);
	arg->arg_type = O_LIST;
    }
    if (arg->arg_type != O_COMMA) {
	if (arg->arg_type != O_ARRAY)
	    arg->arg_flags |= AF_LISTISH;	/* see listish() below */
	return arg;
    }
    for (i = 2, node = arg; ; i++) {
	if (node->arg_len < 2)
	    break;
        if (node[1].arg_type != A_EXPR)
	    break;
	node = node[1].arg_ptr.arg_arg;
	if (node->arg_type != O_COMMA)
	    break;
    }
    if (i > 2) {
	node = arg;
	arg = op_new(i);
	tmpstr = arg->arg_ptr.arg_str;
#ifdef STRUCTCOPY
	*arg = *node;		/* copy everything except the STR */
#else
	(void)bcopy((char *)node, (char *)arg, sizeof(ARG));
#endif
	arg->arg_ptr.arg_str = tmpstr;
	for (j = i; ; ) {
#ifdef STRUCTCOPY
	    arg[j] = node[2];
#else
	    (void)bcopy((char *)(node+2), (char *)(arg+j), sizeof(ARG));
#endif
	    arg[j].arg_flags |= AF_ARYOK;
	    --j;		/* Bug in Xenix compiler */
	    if (j < 2) {
#ifdef STRUCTCOPY
		arg[1] = node[1];
#else
		(void)bcopy((char *)(node+1), (char *)(arg+1), sizeof(ARG));
#endif
		free_arg(node);
		break;
	    }
	    nxtnode = node[1].arg_ptr.arg_arg;
	    free_arg(node);
	    node = nxtnode;
	}
    }
    arg[1].arg_flags |= AF_ARYOK;
    arg[2].arg_flags |= AF_ARYOK;
    arg->arg_type = O_LIST;
    arg->arg_len = i;
    return arg;
}

/* turn a single item into a list */

ARG *
listish(arg)
ARG *arg;
{
    if (arg->arg_flags & AF_LISTISH)
	arg = make_op(O_LIST,1,arg,Nullarg,Nullarg);
    return arg;
}

ARG *
maybelistish(optype, arg)
int optype;
ARG *arg;
{
    if (optype == O_PRTF ||
      (arg->arg_type == O_ASLICE || arg->arg_type == O_HSLICE ||
       arg->arg_type == O_F_OR_R) )
	arg = listish(arg);
    return arg;
}

/* mark list of local variables */

ARG *
localize(arg)
ARG *arg;
{
    arg->arg_flags |= AF_LOCAL;
    return arg;
}

ARG *
fixeval(arg)
ARG *arg;
{
    Renew(arg, 3, ARG);
    arg->arg_len = 2;
    arg[2].arg_ptr.arg_hash = curstash;
    arg[2].arg_type = A_NULL;
    return arg;
}

ARG *
rcatmaybe(arg)
ARG *arg;
{
    if (arg->arg_type == O_CONCAT && arg[2].arg_type == A_READ) {
	arg->arg_type = O_RCAT;	
	arg[2].arg_type = arg[2].arg_ptr.arg_arg[1].arg_type;
	arg[2].arg_ptr = arg[2].arg_ptr.arg_arg[1].arg_ptr;
	free_arg(arg[2].arg_ptr.arg_arg);
    }
    return arg;
}

ARG *
stab2arg(atype,stab)
int atype;
register STAB *stab;
{
    register ARG *arg;

    arg = op_new(1);
    arg->arg_type = O_ITEM;
    arg[1].arg_type = atype;
    arg[1].arg_ptr.arg_stab = stab;
    return arg;
}

ARG *
cval_to_arg(cval)
register char *cval;
{
    register ARG *arg;

    arg = op_new(1);
    arg->arg_type = O_ITEM;
    arg[1].arg_type = A_SINGLE;
    arg[1].arg_ptr.arg_str = str_make(cval,0);
    Safefree(cval);
    return arg;
}

ARG *
op_new(numargs)
int numargs;
{
    register ARG *arg;

    Newz(203,arg, numargs + 1, ARG);
    arg->arg_ptr.arg_str = Str_new(21,0);
    arg->arg_len = numargs;
    return arg;
}

void
free_arg(arg)
ARG *arg;
{
    str_free(arg->arg_ptr.arg_str);
    Safefree(arg);
}

ARG *
make_match(type,expr,spat)
int type;
ARG *expr;
SPAT *spat;
{
    register ARG *arg;

    arg = make_op(type,2,expr,Nullarg,Nullarg);

    arg[2].arg_type = A_SPAT|A_DONT;
    arg[2].arg_ptr.arg_spat = spat;
#ifdef DEBUGGING
    if (debug & 16)
	fprintf(stderr,"make_match SPAT=%lx\n",(long)spat);
#endif

    if (type == O_SUBST || type == O_NSUBST) {
	if (arg[1].arg_type != A_STAB) {
	    yyerror("Illegal lvalue");
	}
	arg[1].arg_type = A_LVAL;
    }
    return arg;
}

ARG *
cmd_to_arg(cmd)
CMD *cmd;
{
    register ARG *arg;

    arg = op_new(1);
    arg->arg_type = O_ITEM;
    arg[1].arg_type = A_CMD;
    arg[1].arg_ptr.arg_cmd = cmd;
    return arg;
}

/* Check two expressions to see if there is any identifier in common */

static int
nothing_in_common(arg1,arg2)
ARG *arg1;
ARG *arg2;
{
    static int thisexpr = 0;	/* I don't care if this wraps */

    thisexpr++;
    if (arg_common(arg1,thisexpr,1))
	return 0;	/* hit eval or do {} */
    if (arg_common(arg2,thisexpr,0))
	return 0;	/* hit identifier again */
    return 1;
}

/* Recursively descend an expression and mark any identifier or check
 * it to see if it was marked already.
 */

static int
arg_common(arg,exprnum,marking)
register ARG *arg;
int exprnum;
int marking;
{
    register int i;

    if (!arg)
	return 0;
    for (i = arg->arg_len; i >= 1; i--) {
	switch (arg[i].arg_type & A_MASK) {
	case A_NULL:
	    break;
	case A_LEXPR:
	case A_EXPR:
	    if (arg_common(arg[i].arg_ptr.arg_arg,exprnum,marking))
		return 1;
	    break;
	case A_CMD:
	    return 1;		/* assume hanky panky */
	case A_STAR:
	case A_LSTAR:
	case A_STAB:
	case A_LVAL:
	case A_ARYLEN:
	case A_LARYLEN:
	    if (marking)
		stab_lastexpr(arg[i].arg_ptr.arg_stab) = exprnum;
	    else if (stab_lastexpr(arg[i].arg_ptr.arg_stab) == exprnum)
		return 1;
	    break;
	case A_DOUBLE:
	case A_BACKTICK:
	    {
		register char *s = arg[i].arg_ptr.arg_str->str_ptr;
		register char *send = s + arg[i].arg_ptr.arg_str->str_cur;
		register STAB *stab;

		while (*s) {
		    if (*s == '$' && s[1]) {
			s = scanreg(s,send,tokenbuf);
			stab = stabent(tokenbuf,TRUE);
			if (marking)
			    stab_lastexpr(stab) = exprnum;
			else if (stab_lastexpr(stab) == exprnum)
			    return 1;
			continue;
		    }
		    else if (*s == '\\' && s[1])
			s++;
		    s++;
		}
	    }
	    break;
	case A_SPAT:
	    if (spat_common(arg[i].arg_ptr.arg_spat,exprnum,marking))
		return 1;
	    break;
	case A_READ:
	case A_INDREAD:
	case A_GLOB:
	case A_WORD:
	case A_SINGLE:
	    break;
	}
    }
    switch (arg->arg_type) {
    case O_ARRAY:
    case O_LARRAY:
	if ((arg[1].arg_type & A_MASK) == A_STAB)
	    (void)aadd(arg[1].arg_ptr.arg_stab);
	break;
    case O_HASH:
    case O_LHASH:
	if ((arg[1].arg_type & A_MASK) == A_STAB)
	    (void)hadd(arg[1].arg_ptr.arg_stab);
	break;
    case O_EVAL:
    case O_SUBR:
    case O_DBSUBR:
	return 1;
    }
    return 0;
}

static int
spat_common(spat,exprnum,marking)
register SPAT *spat;
int exprnum;
int marking;
{
    if (spat->spat_runtime)
	if (arg_common(spat->spat_runtime,exprnum,marking))
	    return 1;
    if (spat->spat_repl) {
	if (arg_common(spat->spat_repl,exprnum,marking))
	    return 1;
    }
    return 0;
}
