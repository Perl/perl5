/* $Header: doarg.c,v 3.0 89/10/18 15:10:41 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	doarg.c,v $
 * Revision 3.0  89/10/18  15:10:41  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#include <signal.h>

extern unsigned char fold[];

int wantarray;

int
do_subst(str,arg,sp)
STR *str;
ARG *arg;
int sp;
{
    register SPAT *spat;
    SPAT *rspat;
    register STR *dstr;
    register char *s = str_get(str);
    char *strend = s + str->str_cur;
    register char *m;
    char *c;
    register char *d;
    int clen;
    int iters = 0;
    register int i;
    bool once;
    char *orig;
    int safebase;

    rspat = spat = arg[2].arg_ptr.arg_spat;
    if (!spat || !s)
	fatal("panic: do_subst");
    else if (spat->spat_runtime) {
	nointrp = "|)";
	(void)eval(spat->spat_runtime,G_SCALAR,sp);
	m = str_get(dstr = stack->ary_array[sp+1]);
	nointrp = "";
	if (spat->spat_regexp)
	    regfree(spat->spat_regexp);
	spat->spat_regexp = regcomp(m,m+dstr->str_cur,
	    spat->spat_flags & SPAT_FOLD,1);
	if (spat->spat_flags & SPAT_KEEP) {
	    arg_free(spat->spat_runtime);	/* it won't change, so */
	    spat->spat_runtime = Nullarg;	/* no point compiling again */
	}
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.SPAT /%s/\n",spat->spat_regexp->precomp);
    }
#endif
    safebase = ((!spat->spat_regexp || !spat->spat_regexp->nparens) &&
      !sawampersand);
    if (!*spat->spat_regexp->precomp && lastspat)
	spat = lastspat;
    orig = m = s;
    if (hint) {
	if (hint < s || hint > strend)
	    fatal("panic: hint in do_match");
	s = hint;
	hint = Nullch;
	if (spat->spat_regexp->regback >= 0) {
	    s -= spat->spat_regexp->regback;
	    if (s < m)
		s = m;
	}
	else
	    s = m;
    }
    else if (spat->spat_short) {
	if (spat->spat_flags & SPAT_SCANFIRST) {
	    if (str->str_pok & SP_STUDIED) {
		if (screamfirst[spat->spat_short->str_rare] < 0)
		    goto nope;
		else if (!(s = screaminstr(str,spat->spat_short)))
		    goto nope;
	    }
#ifndef lint
	    else if (!(s = fbminstr((unsigned char*)s, (unsigned char*)strend,
	      spat->spat_short)))
		goto nope;
#endif
	    if (s && spat->spat_regexp->regback >= 0) {
		++spat->spat_short->str_u.str_useful;
		s -= spat->spat_regexp->regback;
		if (s < m)
		    s = m;
	    }
	    else
		s = m;
	}
	else if (!multiline && (*spat->spat_short->str_ptr != *s ||
	  bcmp(spat->spat_short->str_ptr, s, spat->spat_slen) ))
	    goto nope;
	if (--spat->spat_short->str_u.str_useful < 0) {
	    str_free(spat->spat_short);
	    spat->spat_short = Nullstr;	/* opt is being useless */
	}
    }
    once = ((rspat->spat_flags & SPAT_ONCE) != 0);
    if (rspat->spat_flags & SPAT_CONST) {	/* known replacement string? */
	if ((rspat->spat_repl[1].arg_type & A_MASK) == A_SINGLE)
	    dstr = rspat->spat_repl[1].arg_ptr.arg_str;
	else {					/* constant over loop, anyway */
	    (void)eval(rspat->spat_repl,G_SCALAR,sp);
	    dstr = stack->ary_array[sp+1];
	}
	c = str_get(dstr);
	clen = dstr->str_cur;
	if (clen <= spat->spat_slen + spat->spat_regexp->regback) {
					/* can do inplace substitution */
	    if (regexec(spat->spat_regexp, s, strend, orig, 1,
	      str->str_pok & SP_STUDIED ? str : Nullstr, safebase)) {
		if (spat->spat_regexp->subbase) /* oops, no we can't */
		    goto long_way;
		d = s;
		lastspat = spat;
		str->str_pok = SP_VALID;	/* disable possible screamer */
		if (once) {
		    m = spat->spat_regexp->startp[0];
		    d = spat->spat_regexp->endp[0];
		    s = orig;
		    if (m - s > strend - d) {	/* faster to shorten from end */
			if (clen) {
			    (void)bcopy(c, m, clen);
			    m += clen;
			}
			i = strend - d;
			if (i > 0) {
			    (void)bcopy(d, m, i);
			    m += i;
			}
			*m = '\0';
			str->str_cur = m - s;
			STABSET(str);
			str_numset(arg->arg_ptr.arg_str, 1.0);
			stack->ary_array[++sp] = arg->arg_ptr.arg_str;
			return sp;
		    }
		    else if (i = m - s) {	/* faster from front */
			d -= clen;
			m = d;
			str_chop(str,d-i);
			s += i;
			while (i--)
			    *--d = *--s;
			if (clen)
			    (void)bcopy(c, m, clen);
			STABSET(str);
			str_numset(arg->arg_ptr.arg_str, 1.0);
			stack->ary_array[++sp] = arg->arg_ptr.arg_str;
			return sp;
		    }
		    else if (clen) {
			d -= clen;
			str_chop(str,d);
			(void)bcopy(c,d,clen);
			STABSET(str);
			str_numset(arg->arg_ptr.arg_str, 1.0);
			stack->ary_array[++sp] = arg->arg_ptr.arg_str;
			return sp;
		    }
		    else {
			str_chop(str,d);
			STABSET(str);
			str_numset(arg->arg_ptr.arg_str, 1.0);
			stack->ary_array[++sp] = arg->arg_ptr.arg_str;
			return sp;
		    }
		    /* NOTREACHED */
		}
		do {
		    if (iters++ > 10000)
			fatal("Substitution loop");
		    m = spat->spat_regexp->startp[0];
		    if (i = m - s) {
			if (s != d)
			    (void)bcopy(s,d,i);
			d += i;
		    }
		    if (clen) {
			(void)bcopy(c,d,clen);
			d += clen;
		    }
		    s = spat->spat_regexp->endp[0];
		} while (regexec(spat->spat_regexp, s, strend, orig, 1, Nullstr,
		    TRUE));
		if (s != d) {
		    i = strend - s;
		    str->str_cur = d - str->str_ptr + i;
		    (void)bcopy(s,d,i+1);		/* include the Null */
		}
		STABSET(str);
		str_numset(arg->arg_ptr.arg_str, (double)iters);
		stack->ary_array[++sp] = arg->arg_ptr.arg_str;
		return sp;
	    }
	    str_numset(arg->arg_ptr.arg_str, 0.0);
	    stack->ary_array[++sp] = arg->arg_ptr.arg_str;
	    return sp;
	}
    }
    else
	c = Nullch;
    if (regexec(spat->spat_regexp, s, strend, orig, 1,
      str->str_pok & SP_STUDIED ? str : Nullstr, safebase)) {
    long_way:
	dstr = Str_new(25,str_len(str));
	str_nset(dstr,m,s-m);
	if (spat->spat_regexp->subbase)
	    curspat = spat;
	lastspat = spat;
	do {
	    if (iters++ > 10000)
		fatal("Substitution loop");
	    if (spat->spat_regexp->subbase
	      && spat->spat_regexp->subbase != orig) {
		m = s;
		s = orig;
		orig = spat->spat_regexp->subbase;
		s = orig + (m - s);
		strend = s + (strend - m);
	    }
	    m = spat->spat_regexp->startp[0];
	    str_ncat(dstr,s,m-s);
	    s = spat->spat_regexp->endp[0];
	    if (c) {
		if (clen)
		    str_ncat(dstr,c,clen);
	    }
	    else {
		(void)eval(rspat->spat_repl,G_SCALAR,sp);
		str_scat(dstr,stack->ary_array[sp+1]);
	    }
	    if (once)
		break;
	} while (regexec(spat->spat_regexp, s, strend, orig, 1, Nullstr,
	    safebase));
	str_ncat(dstr,s,strend - s);
	str_replace(str,dstr);
	STABSET(str);
	str_numset(arg->arg_ptr.arg_str, (double)iters);
	stack->ary_array[++sp] = arg->arg_ptr.arg_str;
	return sp;
    }
    str_numset(arg->arg_ptr.arg_str, 0.0);
    stack->ary_array[++sp] = arg->arg_ptr.arg_str;
    return sp;

nope:
    ++spat->spat_short->str_u.str_useful;
    str_numset(arg->arg_ptr.arg_str, 0.0);
    stack->ary_array[++sp] = arg->arg_ptr.arg_str;
    return sp;
}

int
do_trans(str,arg)
STR *str;
register ARG *arg;
{
    register char *tbl;
    register char *s;
    register int matches = 0;
    register int ch;
    register char *send;

    tbl = arg[2].arg_ptr.arg_cval;
    s = str_get(str);
    send = s + str->str_cur;
    if (!tbl || !s)
	fatal("panic: do_trans");
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.TBL\n");
    }
#endif
    while (s < send) {
	if (ch = tbl[*s & 0377]) {
	    matches++;
	    *s = ch;
	}
	s++;
    }
    STABSET(str);
    return matches;
}

void
do_join(str,arglast)
register STR *str;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register char *delim = str_get(st[sp]);
    int delimlen = st[sp]->str_cur;

    st += ++sp;
    if (items-- > 0)
	str_sset(str,*st++);
    else
	str_set(str,"");
    for (; items > 0; items--,st++) {
	str_ncat(str,delim,delimlen);
	str_scat(str,*st);
    }
    STABSET(str);
}

void
do_pack(str,arglast)
register STR *str;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items;
    register char *pat = str_get(st[sp]);
    register char *patend = pat + st[sp]->str_cur;
    register int len;
    int datumtype;
    STR *fromstr;
    static char *null10 = "\0\0\0\0\0\0\0\0\0\0";
    static char *space10 = "          ";

    /* These must not be in registers: */
    char achar;
    short ashort;
    int aint;
    long along;
    char *aptr;

    items = arglast[2] - sp;
    st += ++sp;
    str_nset(str,"",0);
    while (pat < patend) {
#define NEXTFROM (items-- > 0 ? *st++ : &str_no)
	datumtype = *pat++;
	if (isdigit(*pat)) {
	    len = atoi(pat);
	    while (isdigit(*pat))
		pat++;
	}
	else
	    len = 1;
	switch(datumtype) {
	default:
	    break;
	case 'x':
	    while (len >= 10) {
		str_ncat(str,null10,10);
		len -= 10;
	    }
	    str_ncat(str,null10,len);
	    break;
	case 'A':
	case 'a':
	    fromstr = NEXTFROM;
	    aptr = str_get(fromstr);
	    if (fromstr->str_cur > len)
		str_ncat(str,aptr,len);
	    else
		str_ncat(str,aptr,fromstr->str_cur);
	    len -= fromstr->str_cur;
	    if (datumtype == 'A') {
		while (len >= 10) {
		    str_ncat(str,space10,10);
		    len -= 10;
		}
		str_ncat(str,space10,len);
	    }
	    else {
		while (len >= 10) {
		    str_ncat(str,null10,10);
		    len -= 10;
		}
		str_ncat(str,null10,len);
	    }
	    break;
	case 'C':
	case 'c':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aint = (int)str_gnum(fromstr);
		achar = aint;
		str_ncat(str,&achar,sizeof(char));
	    }
	    break;
	case 'n':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		ashort = (short)str_gnum(fromstr);
#ifdef HTONS
		ashort = htons(ashort);
#endif
		str_ncat(str,(char*)&ashort,sizeof(short));
	    }
	    break;
	case 'S':
	case 's':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		ashort = (short)str_gnum(fromstr);
		str_ncat(str,(char*)&ashort,sizeof(short));
	    }
	    break;
	case 'I':
	case 'i':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aint = (int)str_gnum(fromstr);
		str_ncat(str,(char*)&aint,sizeof(int));
	    }
	    break;
	case 'N':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		along = (long)str_gnum(fromstr);
#ifdef HTONL
		along = htonl(along);
#endif
		str_ncat(str,(char*)&along,sizeof(long));
	    }
	    break;
	case 'L':
	case 'l':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		along = (long)str_gnum(fromstr);
		str_ncat(str,(char*)&along,sizeof(long));
	    }
	    break;
	case 'p':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aptr = str_get(fromstr);
		str_ncat(str,(char*)&aptr,sizeof(char*));
	    }
	    break;
	}
    }
    STABSET(str);
}
#undef NEXTFROM

void
do_sprintf(str,len,sarg)
register STR *str;
register int len;
register STR **sarg;
{
    register char *s;
    register char *t;
    bool dolong;
    char ch;
    static STR *sargnull = &str_no;
    register char *send;
    char *xs;
    int xlen;

    str_set(str,"");
    len--;			/* don't count pattern string */
    s = str_get(*sarg);
    send = s + (*sarg)->str_cur;
    sarg++;
    for ( ; s < send; len--) {
	if (len <= 0 || !*sarg) {
	    sarg = &sargnull;
	    len = 0;
	}
	dolong = FALSE;
	for (t = s; t < send && *t != '%'; t++) ;
	if (t >= send)
	    break;		/* not enough % patterns, oh well */
	for (t++; *sarg && t < send && t != s; t++) {
	    switch (*t) {
	    default:
		ch = *(++t);
		*t = '\0';
		(void)sprintf(buf,s);
		s = t;
		*(t--) = ch;
		len++;
		break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9': 
	    case '.': case '#': case '-': case '+':
		break;
	    case 'l':
		dolong = TRUE;
		break;
	    case 'D': case 'X': case 'O':
		dolong = TRUE;
		/* FALL THROUGH */
	    case 'c':
		*buf = (int)str_gnum(*(sarg++));
		str_ncat(str,buf,1);	/* force even if null */
		*buf = '\0';
		s = t+1;
		break;
	    case 'd': case 'x': case 'o': case 'u':
		ch = *(++t);
		*t = '\0';
		if (dolong)
		    (void)sprintf(buf,s,(long)str_gnum(*(sarg++)));
		else
		    (void)sprintf(buf,s,(int)str_gnum(*(sarg++)));
		s = t;
		*(t--) = ch;
		break;
	    case 'E': case 'e': case 'f': case 'G': case 'g':
		ch = *(++t);
		*t = '\0';
		(void)sprintf(buf,s,str_gnum(*(sarg++)));
		s = t;
		*(t--) = ch;
		break;
	    case 's':
		ch = *(++t);
		*t = '\0';
		xs = str_get(*sarg);
		xlen = (*sarg)->str_cur;
		if (*xs == 'S' && xs[1] == 't' && xs[2] == 'a' && xs[3] == 'b'
		  && xlen == sizeof(STBP) && strlen(xs) < xlen) {
		    xs = stab_name(((STAB*)(*sarg))); /* a stab value! */
		    sprintf(tokenbuf,"*%s",xs);	/* reformat to non-binary */
		    xs = tokenbuf;
		    xlen = strlen(tokenbuf);
		}
		if (strEQ(t-2,"%s")) {	/* some printfs fail on >128 chars */
		    *buf = '\0';
		    str_ncat(str,s,t - s - 2);
		    str_ncat(str,xs,xlen);  /* so handle simple case */
		}
		else
		    (void)sprintf(buf,s,xs);
		sarg++;
		s = t;
		*(t--) = ch;
		break;
	    }
	}
	if (s < t && t >= send) {
	    str_cat(str,s);
	    s = t;
	    break;
	}
	str_cat(str,buf);
    }
    if (*s) {
	(void)sprintf(buf,s,0,0,0,0);
	str_cat(str,buf);
    }
    STABSET(str);
}

STR *
do_push(ary,arglast)
register ARRAY *ary;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register STR *str = &str_undef;

    for (st += ++sp; items > 0; items--,st++) {
	str = Str_new(26,0);
	if (*st)
	    str_sset(str,*st);
	(void)apush(ary,str);
    }
    return str;
}

int
do_unshift(ary,arglast)
register ARRAY *ary;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register STR *str;
    register int i;

    aunshift(ary,items);
    i = 0;
    for (st += ++sp; i < items; i++,st++) {
	str = Str_new(27,0);
	str_sset(str,*st);
	(void)astore(ary,i,str);
    }
}

int
do_subr(arg,gimme,arglast)
register ARG *arg;
int gimme;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register SUBR *sub;
    ARRAY *savearray;
    STAB *stab;
    char *oldfile = filename;
    int oldsave = savestack->ary_fill;
    int oldtmps_base = tmps_base;

    if ((arg[1].arg_type & A_MASK) == A_WORD)
	stab = arg[1].arg_ptr.arg_stab;
    else {
	STR *tmpstr = stab_val(arg[1].arg_ptr.arg_stab);

	if (tmpstr)
	    stab = stabent(str_get(tmpstr),TRUE);
	else
	    stab = Nullstab;
    }
    if (!stab)
	fatal("Undefined subroutine called");
    sub = stab_sub(stab);
    if (!sub)
	fatal("Undefined subroutine \"%s\" called", stab_name(stab));
    if ((arg[2].arg_type & A_MASK) != A_NULL) {
	savearray = stab_xarray(defstab);
	stab_xarray(defstab) = afake(defstab, items, &st[sp+1]);
    }
    savelong(&sub->depth);
    sub->depth++;
    saveint(&wantarray);
    wantarray = gimme;
    if (sub->depth >= 2) {	/* save temporaries on recursion? */
	if (sub->depth == 100 && dowarn)
	    warn("Deep recursion on subroutine \"%s\"",stab_name(stab));
	savelist(sub->tosave->ary_array,sub->tosave->ary_fill);
    }
    filename = sub->filename;
    tmps_base = tmps_max;
    sp = cmd_exec(sub->cmd,gimme,--sp);		/* so do it already */
    st = stack->ary_array;

    if ((arg[2].arg_type & A_MASK) != A_NULL) {
	afree(stab_xarray(defstab));  /* put back old $_[] */
	stab_xarray(defstab) = savearray;
    }
    filename = oldfile;
    tmps_base = oldtmps_base;
    if (savestack->ary_fill > oldsave) {
	for (items = arglast[0] + 1; items <= sp; items++)
	    st[items] = str_static(st[items]);
		/* in case restore wipes old str */
	restorelist(oldsave);
    }
    return sp;
}

int
do_dbsubr(arg,gimme,arglast)
register ARG *arg;
int gimme;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register SUBR *sub;
    ARRAY *savearray;
    STR *str;
    STAB *stab;
    char *oldfile = filename;
    int oldsave = savestack->ary_fill;
    int oldtmps_base = tmps_base;

    if ((arg[1].arg_type & A_MASK) == A_WORD)
	stab = arg[1].arg_ptr.arg_stab;
    else {
	STR *tmpstr = stab_val(arg[1].arg_ptr.arg_stab);

	if (tmpstr)
	    stab = stabent(str_get(tmpstr),TRUE);
	else
	    stab = Nullstab;
    }
    if (!stab)
	fatal("Undefined subroutine called");
    sub = stab_sub(stab);
    if (!sub)
	fatal("Undefined subroutine \"%s\" called", stab_name(stab));
/* begin differences */
    str = stab_val(DBsub);
    saveitem(str);
    str_set(str,stab_name(stab));
    sub = stab_sub(DBsub);
    if (!sub)
	fatal("No DBsub routine");
/* end differences */
    if ((arg[2].arg_type & A_MASK) != A_NULL) {
	savearray = stab_xarray(defstab);
	stab_xarray(defstab) = afake(defstab, items, &st[sp+1]);
    }
    savelong(&sub->depth);
    sub->depth++;
    saveint(&wantarray);
    wantarray = gimme;
    if (sub->depth >= 2) {	/* save temporaries on recursion? */
	if (sub->depth == 100 && dowarn)
	    warn("Deep recursion on subroutine \"%s\"",stab_name(stab));
	savelist(sub->tosave->ary_array,sub->tosave->ary_fill);
    }
    filename = sub->filename;
    tmps_base = tmps_max;
    sp = cmd_exec(sub->cmd,gimme, --sp);	/* so do it already */
    st = stack->ary_array;

    if ((arg[2].arg_type & A_MASK) != A_NULL) {
	afree(stab_xarray(defstab));  /* put back old $_[] */
	stab_xarray(defstab) = savearray;
    }
    filename = oldfile;
    tmps_base = oldtmps_base;
    if (savestack->ary_fill > oldsave) {
	for (items = arglast[0] + 1; items <= sp; items++)
	    st[items] = str_static(st[items]);
		/* in case restore wipes old str */
	restorelist(oldsave);
    }
    return sp;
}

int
do_assign(arg,gimme,arglast)
register ARG *arg;
int gimme;
int *arglast;
{

    register STR **st = stack->ary_array;
    STR **firstrelem = st + arglast[1] + 1;
    STR **firstlelem = st + arglast[0] + 1;
    STR **lastrelem = st + arglast[2];
    STR **lastlelem = st + arglast[1];
    register STR **relem;
    register STR **lelem;

    register STR *str;
    register ARRAY *ary;
    register int makelocal;
    HASH *hash;
    int i;

    makelocal = (arg->arg_flags & AF_LOCAL);
    delaymagic = DM_DELAY;		/* catch simultaneous items */

    /* If there's a common identifier on both sides we have to take
     * special care that assigning the identifier on the left doesn't
     * clobber a value on the right that's used later in the list.
     */
    if (arg->arg_flags & AF_COMMON) {
	for (relem = firstrelem; relem <= lastrelem; relem++) {
	    if (str = *relem)
		*relem = str_static(str);
	}
    }
    relem = firstrelem;
    lelem = firstlelem;
    ary = Null(ARRAY*);
    hash = Null(HASH*);
    while (lelem <= lastlelem) {
	str = *lelem++;
	if (str->str_state >= SS_HASH) {
	    if (str->str_state == SS_ARY) {
		if (makelocal)
		    ary = saveary(str->str_u.str_stab);
		else {
		    ary = stab_array(str->str_u.str_stab);
		    ary->ary_fill = -1;
		}
		i = 0;
		while (relem <= lastrelem) {	/* gobble up all the rest */
		    str = Str_new(28,0);
		    if (*relem)
			str_sset(str,*(relem++));
		    else
			relem++;
		    (void)astore(ary,i++,str);
		}
	    }
	    else if (str->str_state == SS_HASH) {
		char *tmps;
		STR *tmpstr;

		if (makelocal)
		    hash = savehash(str->str_u.str_stab);
		else {
		    hash = stab_hash(str->str_u.str_stab);
		    hclear(hash);
		}
		while (relem < lastrelem) {	/* gobble up all the rest */
		    if (*relem)
			str = *(relem++);
		    else
			str = &str_no, relem++;
		    tmps = str_get(str);
		    tmpstr = Str_new(29,0);
		    if (*relem)
			str_sset(tmpstr,*(relem++));	/* value */
		    else
			relem++;
		    (void)hstore(hash,tmps,str->str_cur,tmpstr,0);
		}
	    }
	    else
		fatal("panic: do_assign");
	}
	else {
	    if (makelocal)
		saveitem(str);
	    if (relem <= lastrelem)
		str_sset(str, *(relem++));
	    else
		str_nset(str, "", 0);
	    STABSET(str);
	}
    }
    if (delaymagic > 1) {
#ifdef SETREUID
	if (delaymagic & DM_REUID)
	    setreuid(uid,euid);
#endif
#ifdef SETREGID
	if (delaymagic & DM_REGID)
	    setregid(gid,egid);
#endif
    }
    delaymagic = 0;
    if (gimme == G_ARRAY) {
	i = lastrelem - firstrelem + 1;
	if (ary || hash)
	    Copy(firstrelem, firstlelem, i, STR*);
	return arglast[0] + i;
    }
    else {
	str_numset(arg->arg_ptr.arg_str,(double)(arglast[2] - arglast[1]));
	*firstlelem = arg->arg_ptr.arg_str;
	return arglast[0] + 1;
    }
}

int
do_study(str,arg,gimme,arglast)
STR *str;
ARG *arg;
int gimme;
int *arglast;
{
    register unsigned char *s;
    register int pos = str->str_cur;
    register int ch;
    register int *sfirst;
    register int *snext;
    static int maxscream = -1;
    static STR *lastscream = Nullstr;
    int retval;
    int retarg = arglast[0] + 1;

#ifndef lint
    s = (unsigned char*)(str_get(str));
#else
    s = Null(unsigned char*);
#endif
    if (lastscream)
	lastscream->str_pok &= ~SP_STUDIED;
    lastscream = str;
    if (pos <= 0) {
	retval = 0;
	goto ret;
    }
    if (pos > maxscream) {
	if (maxscream < 0) {
	    maxscream = pos + 80;
	    New(301,screamfirst, 256, int);
	    New(302,screamnext, maxscream, int);
	}
	else {
	    maxscream = pos + pos / 4;
	    Renew(screamnext, maxscream, int);
	}
    }

    sfirst = screamfirst;
    snext = screamnext;

    if (!sfirst || !snext)
	fatal("do_study: out of memory");

    for (ch = 256; ch; --ch)
	*sfirst++ = -1;
    sfirst -= 256;

    while (--pos >= 0) {
	ch = s[pos];
	if (sfirst[ch] >= 0)
	    snext[pos] = sfirst[ch] - pos;
	else
	    snext[pos] = -pos;
	sfirst[ch] = pos;

	/* If there were any case insensitive searches, we must assume they
	 * all are.  This speeds up insensitive searches much more than
	 * it slows down sensitive ones.
	 */
	if (sawi)
	    sfirst[fold[ch]] = pos;
    }

    str->str_pok |= SP_STUDIED;
    retval = 1;
  ret:
    str_numset(arg->arg_ptr.arg_str,(double)retval);
    stack->ary_array[retarg] = arg->arg_ptr.arg_str;
    return retarg;
}

int
do_defined(str,arg,gimme,arglast)
STR *str;
register ARG *arg;
int gimme;
int *arglast;
{
    register int type;
    register int retarg = arglast[0] + 1;
    int retval;

    if ((arg[1].arg_type & A_MASK) != A_LEXPR)
	fatal("Illegal argument to defined()");
    arg = arg[1].arg_ptr.arg_arg;
    type = arg->arg_type;

    if (type == O_ARRAY || type == O_LARRAY)
	retval = stab_xarray(arg[1].arg_ptr.arg_stab) != 0;
    else if (type == O_HASH || type == O_LHASH)
	retval = stab_xhash(arg[1].arg_ptr.arg_stab) != 0;
    else if (type == O_SUBR || type == O_DBSUBR)
	retval = stab_sub(arg[1].arg_ptr.arg_stab) != 0;
    else if (type == O_ASLICE || type == O_LASLICE)
	retval = stab_xarray(arg[1].arg_ptr.arg_stab) != 0;
    else if (type == O_HSLICE || type == O_LHSLICE)
	retval = stab_xhash(arg[1].arg_ptr.arg_stab) != 0;
    else
	retval = FALSE;
    str_numset(str,(double)retval);
    stack->ary_array[retarg] = str;
    return retarg;
}

int
do_undef(str,arg,gimme,arglast)
STR *str;
register ARG *arg;
int gimme;
int *arglast;
{
    register int type;
    register STAB *stab;
    int retarg = arglast[0] + 1;

    if ((arg[1].arg_type & A_MASK) != A_LEXPR)
	fatal("Illegal argument to undef()");
    arg = arg[1].arg_ptr.arg_arg;
    type = arg->arg_type;

    if (type == O_ARRAY || type == O_LARRAY) {
	stab = arg[1].arg_ptr.arg_stab;
	afree(stab_xarray(stab));
	stab_xarray(stab) = Null(ARRAY*);
    }
    else if (type == O_HASH || type == O_LHASH) {
	stab = arg[1].arg_ptr.arg_stab;
	(void)hfree(stab_xhash(stab));
	stab_xhash(stab) = Null(HASH*);
    }
    else if (type == O_SUBR || type == O_DBSUBR) {
	stab = arg[1].arg_ptr.arg_stab;
	cmd_free(stab_sub(stab)->cmd);
	afree(stab_sub(stab)->tosave);
	Safefree(stab_sub(stab));
	stab_sub(stab) = Null(SUBR*);
    }
    else
	fatal("Can't undefine that kind of object");
    str_numset(str,0.0);
    stack->ary_array[retarg] = str;
    return retarg;
}

int
do_vec(lvalue,astr,arglast)
int lvalue;
STR *astr;
int *arglast;
{
    STR **st = stack->ary_array;
    int sp = arglast[0];
    register STR *str = st[++sp];
    register int offset = (int)str_gnum(st[++sp]);
    register int size = (int)str_gnum(st[++sp]);
    unsigned char *s = (unsigned char*)str_get(str);
    unsigned long retnum;
    int len;

    sp = arglast[1];
    offset *= size;		/* turn into bit offset */
    len = (offset + size + 7) / 8;
    if (offset < 0 || size < 1)
	retnum = 0;
    else if (!lvalue && len > str->str_cur)
	retnum = 0;
    else {
	if (len > str->str_cur) {
	    STR_GROW(str,len);
	    (void)bzero(str->str_ptr + str->str_cur, len - str->str_cur);
	    str->str_cur = len;
	}
	s = (unsigned char*)str_get(str);
	if (size < 8)
	    retnum = (s[offset >> 3] >> (offset & 7)) & ((1 << size) - 1);
	else {
	    offset >>= 3;
	    if (size == 8)
		retnum = s[offset];
	    else if (size == 16)
		retnum = (s[offset] << 8) + s[offset+1];
	    else if (size == 32)
		retnum = (s[offset] << 24) + (s[offset + 1] << 16) +
			(s[offset + 2] << 8) + s[offset+3];
	}

	if (lvalue) {                      /* it's an lvalue! */
	    struct lstring *lstr = (struct lstring*)astr;

	    astr->str_magic = str;
	    st[sp]->str_rare = 'v';
	    lstr->lstr_offset = offset;
	    lstr->lstr_len = size;
	}
    }

    str_numset(astr,(double)retnum);
    st[sp] = astr;
    return sp;
}

void
do_vecset(mstr,str)
STR *mstr;
STR *str;
{
    struct lstring *lstr = (struct lstring*)str;
    register int offset;
    register int size;
    register unsigned char *s = (unsigned char*)mstr->str_ptr;
    register unsigned long lval = (unsigned long)str_gnum(str);
    int mask;

    mstr->str_rare = 0;
    str->str_magic = Nullstr;
    offset = lstr->lstr_offset;
    size = lstr->lstr_len;
    if (size < 8) {
	mask = (1 << size) - 1;
	size = offset & 7;
	lval &= mask;
	offset >>= 3;
	s[offset] &= ~(mask << size);
	s[offset] |= lval << size;
    }
    else {
	if (size == 8)
	    s[offset] = lval & 255;
	else if (size == 16) {
	    s[offset] = (lval >> 8) & 255;
	    s[offset+1] = lval & 255;
	}
	else if (size == 32) {
	    s[offset] = (lval >> 24) & 255;
	    s[offset+1] = (lval >> 16) & 255;
	    s[offset+2] = (lval >> 8) & 255;
	    s[offset+3] = lval & 255;
	}
    }
}

do_chop(astr,str)
register STR *astr;
register STR *str;
{
    register char *tmps;
    register int i;
    ARRAY *ary;
    HASH *hash;
    HENT *entry;

    if (!str)
	return;
    if (str->str_state == SS_ARY) {
	ary = stab_array(str->str_u.str_stab);
	for (i = 0; i <= ary->ary_fill; i++)
	    do_chop(astr,ary->ary_array[i]);
	return;
    }
    if (str->str_state == SS_HASH) {
	hash = stab_hash(str->str_u.str_stab);
	(void)hiterinit(hash);
	while (entry = hiternext(hash))
	    do_chop(astr,hiterval(hash,entry));
	return;
    }
    tmps = str_get(str);
    if (!tmps)
	return;
    tmps += str->str_cur - (str->str_cur != 0);
    str_nset(astr,tmps,1);	/* remember last char */
    *tmps = '\0';				/* wipe it out */
    str->str_cur = tmps - str->str_ptr;
    str->str_nok = 0;
}

do_vop(optype,str,left,right)
STR *str;
STR *left;
STR *right;
{
    register char *s = str_get(str);
    register char *l = str_get(left);
    register char *r = str_get(right);
    register int len;

    len = left->str_cur;
    if (len > right->str_cur)
	len = right->str_cur;
    if (str->str_cur > len)
	str->str_cur = len;
    else if (str->str_cur < len) {
	STR_GROW(str,len);
	(void)bzero(str->str_ptr + str->str_cur, len - str->str_cur);
	str->str_cur = len;
	s = str_get(str);
    }
    switch (optype) {
    case O_BIT_AND:
	while (len--)
	    *s++ = *l++ & *r++;
	break;
    case O_XOR:
	while (len--)
	    *s++ = *l++ ^ *r++;
	goto mop_up;
    case O_BIT_OR:
	while (len--)
	    *s++ = *l++ | *r++;
      mop_up:
	len = str->str_cur;
	if (right->str_cur > len)
	    str_ncat(str,right->str_ptr+len,right->str_cur - len);
	else if (left->str_cur > len)
	    str_ncat(str,left->str_ptr+len,left->str_cur - len);
	break;
    }
}

int
do_syscall(arglast)
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    long arg[8];
    register int i = 0;
    int retval = -1;

#ifdef SYSCALL
#ifdef TAINT
    for (st += ++sp; items--; st++)
	tainted |= (*st)->str_tainted;
    st = stack->ary_array;
    sp = arglast[1];
    items = arglast[2] - sp;
#endif
#ifdef TAINT
    taintproper("Insecure dependency in syscall");
#endif
    /* This probably won't work on machines where sizeof(long) != sizeof(int)
     * or where sizeof(long) != sizeof(char*).  But such machines will
     * not likely have syscall implemented either, so who cares?
     */
    while (items--) {
	if (st[++sp]->str_nok || !i)
	    arg[i++] = (long)str_gnum(st[sp]);
#ifndef lint
	else
	    arg[i++] = (long)st[sp]->str_ptr;
#endif /* lint */
    }
    sp = arglast[1];
    items = arglast[2] - sp;
    switch (items) {
    case 0:
	fatal("Too few args to syscall");
    case 1:
	retval = syscall(arg[0]);
	break;
    case 2:
	retval = syscall(arg[0],arg[1]);
	break;
    case 3:
	retval = syscall(arg[0],arg[1],arg[2]);
	break;
    case 4:
	retval = syscall(arg[0],arg[1],arg[2],arg[3]);
	break;
    case 5:
	retval = syscall(arg[0],arg[1],arg[2],arg[3],arg[4]);
	break;
    case 6:
	retval = syscall(arg[0],arg[1],arg[2],arg[3],arg[4],arg[5]);
	break;
    case 7:
	retval = syscall(arg[0],arg[1],arg[2],arg[3],arg[4],arg[5],arg[6]);
	break;
    case 8:
	retval = syscall(arg[0],arg[1],arg[2],arg[3],arg[4],arg[5],arg[6],
	  arg[7]);
	break;
    }
    st[sp] = str_static(&str_undef);
    str_numset(st[sp], (double)retval);
    return sp;
#else
    fatal("syscall() unimplemented");
#endif
}


