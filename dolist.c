/* $Header: dolist.c,v 3.0.1.1 89/10/26 23:11:51 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	dolist.c,v $
 * Revision 3.0.1.1  89/10/26  23:11:51  lwall
 * patch1: split in a subroutine wrongly freed referenced arguments
 * patch1: reverse didn't work
 * 
 * Revision 3.0  89/10/18  15:11:02  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"


int
do_match(str,arg,gimme,arglast)
STR *str;
register ARG *arg;
int gimme;
int *arglast;
{
    register STR **st = stack->ary_array;
    register SPAT *spat = arg[2].arg_ptr.arg_spat;
    register char *t;
    register int sp = arglast[0] + 1;
    STR *srchstr = st[sp];
    register char *s = str_get(st[sp]);
    char *strend = s + st[sp]->str_cur;
    STR *tmpstr;

    if (!spat) {
	if (gimme == G_ARRAY)
	    return --sp;
	str_set(str,Yes);
	STABSET(str);
	st[sp] = str;
	return sp;
    }
    if (!s)
	fatal("panic: do_match");
    if (spat->spat_flags & SPAT_USED) {
#ifdef DEBUGGING
	if (debug & 8)
	    deb("2.SPAT USED\n");
#endif
	if (gimme == G_ARRAY)
	    return --sp;
	str_set(str,No);
	STABSET(str);
	st[sp] = str;
	return sp;
    }
    --sp;
    if (spat->spat_runtime) {
	nointrp = "|)";
	sp = eval(spat->spat_runtime,G_SCALAR,sp);
	st = stack->ary_array;
	t = str_get(tmpstr = st[sp--]);
	nointrp = "";
#ifdef DEBUGGING
	if (debug & 8)
	    deb("2.SPAT /%s/\n",t);
#endif
	if (spat->spat_regexp)
	    regfree(spat->spat_regexp);
	spat->spat_regexp = regcomp(t,t+tmpstr->str_cur,
	    spat->spat_flags & SPAT_FOLD,1);
	if (!*spat->spat_regexp->precomp && lastspat)
	    spat = lastspat;
	if (spat->spat_flags & SPAT_KEEP) {
	    arg_free(spat->spat_runtime);	/* it won't change, so */
	    spat->spat_runtime = Nullarg;	/* no point compiling again */
	}
	if (!spat->spat_regexp->nparens)
	    gimme = G_SCALAR;			/* accidental array context? */
	if (regexec(spat->spat_regexp, s, strend, s, 0,
	  srchstr->str_pok & SP_STUDIED ? srchstr : Nullstr,
	  gimme == G_ARRAY)) {
	    if (spat->spat_regexp->subbase)
		curspat = spat;
	    lastspat = spat;
	    goto gotcha;
	}
	else {
	    if (gimme == G_ARRAY)
		return sp;
	    str_sset(str,&str_no);
	    STABSET(str);
	    st[++sp] = str;
	    return sp;
	}
    }
    else {
#ifdef DEBUGGING
	if (debug & 8) {
	    char ch;

	    if (spat->spat_flags & SPAT_ONCE)
		ch = '?';
	    else
		ch = '/';
	    deb("2.SPAT %c%s%c\n",ch,spat->spat_regexp->precomp,ch);
	}
#endif
	if (!*spat->spat_regexp->precomp && lastspat)
	    spat = lastspat;
	t = s;
	if (hint) {
	    if (hint < s || hint > strend)
		fatal("panic: hint in do_match");
	    s = hint;
	    hint = Nullch;
	    if (spat->spat_regexp->regback >= 0) {
		s -= spat->spat_regexp->regback;
		if (s < t)
		    s = t;
	    }
	    else
		s = t;
	}
	else if (spat->spat_short) {
	    if (spat->spat_flags & SPAT_SCANFIRST) {
		if (srchstr->str_pok & SP_STUDIED) {
		    if (screamfirst[spat->spat_short->str_rare] < 0)
			goto nope;
		    else if (!(s = screaminstr(srchstr,spat->spat_short)))
			goto nope;
		    else if (spat->spat_flags & SPAT_ALL)
			goto yup;
		}
#ifndef lint
		else if (!(s = fbminstr((unsigned char*)s,
		  (unsigned char*)strend, spat->spat_short)))
		    goto nope;
#endif
		else if (spat->spat_flags & SPAT_ALL)
		    goto yup;
		if (s && spat->spat_regexp->regback >= 0) {
		    ++spat->spat_short->str_u.str_useful;
		    s -= spat->spat_regexp->regback;
		    if (s < t)
			s = t;
		}
		else
		    s = t;
	    }
	    else if (!multiline && (*spat->spat_short->str_ptr != *s ||
	      bcmp(spat->spat_short->str_ptr, s, spat->spat_slen) ))
		goto nope;
	    if (--spat->spat_short->str_u.str_useful < 0) {
		str_free(spat->spat_short);
		spat->spat_short = Nullstr;	/* opt is being useless */
	    }
	}
	if (!spat->spat_regexp->nparens)
	    gimme = G_SCALAR;			/* accidental array context? */
	if (regexec(spat->spat_regexp, s, strend, t, 0,
	  srchstr->str_pok & SP_STUDIED ? srchstr : Nullstr,
	  gimme == G_ARRAY)) {
	    if (spat->spat_regexp->subbase)
		curspat = spat;
	    lastspat = spat;
	    if (spat->spat_flags & SPAT_ONCE)
		spat->spat_flags |= SPAT_USED;
	    goto gotcha;
	}
	else {
	    if (gimme == G_ARRAY)
		return sp;
	    str_sset(str,&str_no);
	    STABSET(str);
	    st[++sp] = str;
	    return sp;
	}
    }
    /*NOTREACHED*/

  gotcha:
    if (gimme == G_ARRAY) {
	int iters, i, len;

	iters = spat->spat_regexp->nparens;
	if (sp + iters >= stack->ary_max) {
	    astore(stack,sp + iters, Nullstr);
	    st = stack->ary_array;		/* possibly realloced */
	}

	for (i = 1; i <= iters; i++) {
	    st[++sp] = str_static(&str_no);
	    if (s = spat->spat_regexp->startp[i]) {
		len = spat->spat_regexp->endp[i] - s;
		if (len > 0)
		    str_nset(st[sp],s,len);
	    }
	}
	return sp;
    }
    else {
	str_sset(str,&str_yes);
	STABSET(str);
	st[++sp] = str;
	return sp;
    }

yup:
    ++spat->spat_short->str_u.str_useful;
    lastspat = spat;
    if (spat->spat_flags & SPAT_ONCE)
	spat->spat_flags |= SPAT_USED;
    if (sawampersand) {
	char *tmps;

	tmps = spat->spat_regexp->subbase = nsavestr(t,strend-t);
	tmps = spat->spat_regexp->startp[0] = tmps + (s - t);
	spat->spat_regexp->endp[0] = tmps + spat->spat_short->str_cur;
	curspat = spat;
    }
    str_sset(str,&str_yes);
    STABSET(str);
    st[++sp] = str;
    return sp;

nope:
    ++spat->spat_short->str_u.str_useful;
    if (gimme == G_ARRAY)
	return sp;
    str_sset(str,&str_no);
    STABSET(str);
    st[++sp] = str;
    return sp;
}

int
do_split(str,spat,limit,gimme,arglast)
STR *str;
register SPAT *spat;
register int limit;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    STR **st = ary->ary_array;
    register int sp = arglast[0] + 1;
    register char *s = str_get(st[sp]);
    char *strend = s + st[sp--]->str_cur;
    register STR *dstr;
    register char *m;
    int iters = 0;
    int i;
    char *orig;
    int origlimit = limit;
    int realarray = 0;

    if (!spat || !s)
	fatal("panic: do_split");
    else if (spat->spat_runtime) {
	nointrp = "|)";
	sp = eval(spat->spat_runtime,G_SCALAR,sp);
	st = stack->ary_array;
	m = str_get(dstr = st[sp--]);
	nointrp = "";
	if (!dstr->str_cur || (*m == ' ' && dstr->str_cur == 1)) {
	    str_set(dstr,"\\s+");
	    m = dstr->str_ptr;
	    spat->spat_flags |= SPAT_SKIPWHITE;
	}
	if (spat->spat_regexp)
	    regfree(spat->spat_regexp);
	spat->spat_regexp = regcomp(m,m+dstr->str_cur,
	    spat->spat_flags & SPAT_FOLD,1);
	if (spat->spat_flags & SPAT_KEEP ||
	    (spat->spat_runtime->arg_type == O_ITEM &&
	      (spat->spat_runtime[1].arg_type & A_MASK) == A_SINGLE) ) {
	    arg_free(spat->spat_runtime);	/* it won't change, so */
	    spat->spat_runtime = Nullarg;	/* no point compiling again */
	}
    }
#ifdef DEBUGGING
    if (debug & 8) {
	deb("2.SPAT /%s/\n",spat->spat_regexp->precomp);
    }
#endif
    ary = stab_xarray(spat->spat_repl[1].arg_ptr.arg_stab);
    if (ary && ((ary->ary_flags & ARF_REAL) || gimme != G_ARRAY)) {
	realarray = 1;
	if (!(ary->ary_flags & ARF_REAL)) {
	    ary->ary_flags |= ARF_REAL;
	    for (i = ary->ary_fill; i >= 0; i--)
		ary->ary_array[i] = Nullstr;	/* don't free mere refs */
	}
	ary->ary_fill = -1;
	sp = -1;	/* temporarily switch stacks */
    }
    else
	ary = stack;
    orig = s;
    if (spat->spat_flags & SPAT_SKIPWHITE) {
	while (isspace(*s))
	    s++;
    }
    if (!limit)
	limit = 10001;
    if (spat->spat_short) {
	i = spat->spat_short->str_cur;
	if (i == 1) {
	    i = *spat->spat_short->str_ptr;
	    while (--limit) {
		for (m = s; m < strend && *m != i; m++) ;
		if (m >= strend)
		    break;
		if (realarray)
		    dstr = Str_new(30,m-s);
		else
		    dstr = str_static(&str_undef);
		str_nset(dstr,s,m-s);
		(void)astore(ary, ++sp, dstr);
		s = m + 1;
	    }
	}
	else {
#ifndef lint
	    while (s < strend && --limit &&
	      (m=fbminstr((unsigned char*)s, (unsigned char*)strend,
		    spat->spat_short)) )
#endif
	    {
		if (realarray)
		    dstr = Str_new(31,m-s);
		else
		    dstr = str_static(&str_undef);
		str_nset(dstr,s,m-s);
		(void)astore(ary, ++sp, dstr);
		s = m + i;
	    }
	}
    }
    else {
	while (s < strend && --limit &&
	    regexec(spat->spat_regexp, s, strend, orig, 1, Nullstr, TRUE) ) {
	    if (spat->spat_regexp->subbase
	      && spat->spat_regexp->subbase != orig) {
		m = s;
		s = orig;
		orig = spat->spat_regexp->subbase;
		s = orig + (m - s);
		strend = s + (strend - m);
	    }
	    m = spat->spat_regexp->startp[0];
	    if (realarray)
		dstr = Str_new(32,m-s);
	    else
		dstr = str_static(&str_undef);
	    str_nset(dstr,s,m-s);
	    (void)astore(ary, ++sp, dstr);
	    if (spat->spat_regexp->nparens) {
		for (i = 1; i <= spat->spat_regexp->nparens; i++) {
		    s = spat->spat_regexp->startp[i];
		    m = spat->spat_regexp->endp[i];
		    if (realarray)
			dstr = Str_new(33,m-s);
		    else
			dstr = str_static(&str_undef);
		    str_nset(dstr,s,m-s);
		    (void)astore(ary, ++sp, dstr);
		}
	    }
	    s = spat->spat_regexp->endp[0];
	}
    }
    if (realarray)
	iters = sp + 1;
    else
	iters = sp - arglast[0];
    if (iters > 9999)
	fatal("Split loop");
    if (s < strend || origlimit) {	/* keep field after final delim? */
	if (realarray)
	    dstr = Str_new(34,strend-s);
	else
	    dstr = str_static(&str_undef);
	str_nset(dstr,s,strend-s);
	(void)astore(ary, ++sp, dstr);
	iters++;
    }
    else {
#ifndef I286
	while (iters > 0 && ary->ary_array[sp]->str_cur == 0)
	    iters--,sp--;
#else
	char *zaps;
	int   zapb;

	if (iters > 0) {
		zaps = str_get(afetch(ary,sp,FALSE));
		zapb = (int) *zaps;
	}
	
	while (iters > 0 && (!zapb)) {
	    iters--,sp--;
	    if (iters > 0) {
		zaps = str_get(afetch(ary,iters-1,FALSE));
		zapb = (int) *zaps;
	    }
	}
#endif
    }
    if (realarray) {
	ary->ary_fill = sp;
	if (gimme == G_ARRAY) {
	    sp++;
	    astore(stack, arglast[0] + 1 + sp, Nullstr);
	    Copy(ary->ary_array, stack->ary_array + arglast[0] + 1, sp, STR*);
	    return arglast[0] + sp;
	}
    }
    else {
	if (gimme == G_ARRAY)
	    return sp;
    }
    sp = arglast[0] + 1;
    str_numset(str,(double)iters);
    STABSET(str);
    st[sp] = str;
    return sp;
}

int
do_unpack(str,gimme,arglast)
STR *str;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    register int sp = arglast[0] + 1;
    register char *pat = str_get(st[sp++]);
    register char *s = str_get(st[sp]);
    char *strend = s + st[sp--]->str_cur;
    register char *patend = pat + st[sp]->str_cur;
    int datumtype;
    register int len;

    /* These must not be in registers: */
    char achar;
    short ashort;
    int aint;
    long along;
    unsigned char auchar;
    unsigned short aushort;
    unsigned int auint;
    unsigned long aulong;
    char *aptr;

    if (gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[sp] = str;
	return sp;
    }
    sp--;
    while (pat < patend) {
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
	    s += len;
	    break;
	case 'A':
	case 'a':
	    if (s + len > strend)
		len = strend - s;
	    str = Str_new(35,len);
	    str_nset(str,s,len);
	    s += len;
	    if (datumtype == 'A') {
		aptr = s;	/* borrow register */
		s = str->str_ptr + len - 1;
		while (s >= str->str_ptr && (!*s || isspace(*s)))
		    s--;
		*++s = '\0';
		str->str_cur = s - str->str_ptr;
		s = aptr;	/* unborrow register */
	    }
	    (void)astore(stack, ++sp, str_2static(str));
	    break;
	case 'c':
	    while (len-- > 0) {
		if (s + sizeof(char) > strend)
		    achar = 0;
		else {
		    bcopy(s,(char*)&achar,sizeof(char));
		    s += sizeof(char);
		}
		str = Str_new(36,0);
		aint = achar;
		if (aint >= 128)	/* fake up signed chars */
		    aint -= 256;
		str_numset(str,(double)aint);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'C':
	    while (len-- > 0) {
		if (s + sizeof(unsigned char) > strend)
		    auchar = 0;
		else {
		    bcopy(s,(char*)&auchar,sizeof(unsigned char));
		    s += sizeof(unsigned char);
		}
		str = Str_new(37,0);
		auint = auchar;		/* some can't cast uchar to double */
		str_numset(str,(double)auint);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 's':
	    while (len-- > 0) {
		if (s + sizeof(short) > strend)
		    ashort = 0;
		else {
		    bcopy(s,(char*)&ashort,sizeof(short));
		    s += sizeof(short);
		}
		str = Str_new(38,0);
		str_numset(str,(double)ashort);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'n':
	case 'S':
	    while (len-- > 0) {
		if (s + sizeof(unsigned short) > strend)
		    aushort = 0;
		else {
		    bcopy(s,(char*)&aushort,sizeof(unsigned short));
		    s += sizeof(unsigned short);
		}
		str = Str_new(39,0);
#ifdef NTOHS
		if (datumtype == 'n')
		    aushort = ntohs(aushort);
#endif
		str_numset(str,(double)aushort);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'i':
	    while (len-- > 0) {
		if (s + sizeof(int) > strend)
		    aint = 0;
		else {
		    bcopy(s,(char*)&aint,sizeof(int));
		    s += sizeof(int);
		}
		str = Str_new(40,0);
		str_numset(str,(double)aint);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'I':
	    while (len-- > 0) {
		if (s + sizeof(unsigned int) > strend)
		    auint = 0;
		else {
		    bcopy(s,(char*)&auint,sizeof(unsigned int));
		    s += sizeof(unsigned int);
		}
		str = Str_new(41,0);
		str_numset(str,(double)auint);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'l':
	    while (len-- > 0) {
		if (s + sizeof(long) > strend)
		    along = 0;
		else {
		    bcopy(s,(char*)&along,sizeof(long));
		    s += sizeof(long);
		}
		str = Str_new(42,0);
		str_numset(str,(double)along);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'N':
	case 'L':
	    while (len-- > 0) {
		if (s + sizeof(unsigned long) > strend)
		    aulong = 0;
		else {
		    bcopy(s,(char*)&aulong,sizeof(unsigned long));
		    s += sizeof(unsigned long);
		}
		str = Str_new(43,0);
#ifdef NTOHL
		if (datumtype == 'N')
		    aulong = ntohl(aulong);
#endif
		str_numset(str,(double)aulong);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	case 'p':
	    while (len-- > 0) {
		if (s + sizeof(char*) > strend)
		    aptr = 0;
		else {
		    bcopy(s,(char*)&aptr,sizeof(char*));
		    s += sizeof(char*);
		}
		str = Str_new(44,0);
		if (aptr)
		    str_set(str,aptr);
		(void)astore(stack, ++sp, str_2static(str));
	    }
	    break;
	}
    }
    return sp;
}

int
do_slice(stab,numarray,lval,gimme,arglast)
register STAB *stab;
int numarray;
int lval;
int gimme;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int max = arglast[2];
    register char *tmps;
    register int len;
    register int magic = 0;

    if (lval && !numarray) {
	if (stab == envstab)
	    magic = 'E';
	else if (stab == sigstab)
	    magic = 'S';
#ifdef SOME_DBM
	else if (stab_hash(stab)->tbl_dbm)
	    magic = 'D';
#endif /* SOME_DBM */
    }

    if (gimme == G_ARRAY) {
	if (numarray) {
	    while (sp < max) {
		if (st[++sp]) {
		    st[sp-1] = afetch(stab_array(stab),(int)str_gnum(st[sp]),
			lval);
		}
		else
		    st[sp-1] = Nullstr;
	    }
	}
	else {
	    while (sp < max) {
		if (st[++sp]) {
		    tmps = str_get(st[sp]);
		    len = st[sp]->str_cur;
		    st[sp-1] = hfetch(stab_hash(stab),tmps,len, lval);
		    if (magic)
			str_magic(st[sp-1],stab,magic,tmps,len);
		}
		else
		    st[sp-1] = Nullstr;
	    }
	}
	sp--;
    }
    else {
	if (numarray) {
	    if (st[max])
		st[sp] = afetch(stab_array(stab),(int)str_gnum(st[max]), lval);
	    else
		st[sp] = Nullstr;
	}
	else {
	    if (st[max]) {
		tmps = str_get(st[max]);
		len = st[max]->str_cur;
		st[sp] = hfetch(stab_hash(stab),tmps,len, lval);
		if (magic)
		    str_magic(st[sp],stab,magic,tmps,len);
	    }
	    else
		st[sp] = Nullstr;
	}
    }
    return sp;
}

int
do_grep(arg,str,gimme,arglast)
register ARG *arg;
STR *str;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    register STR **dst = &st[arglast[1]];
    register STR **src = dst + 1;
    register int sp = arglast[2];
    register int i = sp - arglast[1];
    int oldsave = savestack->ary_fill;

    savesptr(&stab_val(defstab));
    if ((arg[1].arg_type & A_MASK) != A_EXPR)
	dehoist(arg,1);
    arg = arg[1].arg_ptr.arg_arg;
    while (i-- > 0) {
	stab_val(defstab) = *src;
	(void)eval(arg,G_SCALAR,sp);
	if (str_true(st[sp+1]))
	    *dst++ = *src;
	src++;
    }
    restorelist(oldsave);
    if (gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[arglast[0]+1] = str;
	return arglast[0]+1;
    }
    return arglast[0] + (dst - &st[arglast[1]]);
}

int
do_reverse(str,gimme,arglast)
STR *str;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    register STR **up = &st[arglast[1]];
    register STR **down = &st[arglast[2]];
    register int i = arglast[2] - arglast[1];

    if (gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[arglast[0]+1] = str;
	return arglast[0]+1;
    }
    while (i-- > 0) {
	*up++ = *down;
	if (i-- > 0)
	    *down-- = *up;
    }
    i = arglast[2] - arglast[1];
    Copy(down+1,up,i/2,STR*);
    return arglast[2] - 1;
}

static CMD *sortcmd;
static STAB *firststab = Nullstab;
static STAB *secondstab = Nullstab;

int
do_sort(str,stab,gimme,arglast)
STR *str;
STAB *stab;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    int sp = arglast[1];
    register STR **up;
    register int max = arglast[2] - sp;
    register int i;
    int sortcmp();
    int sortsub();
    STR *oldfirst;
    STR *oldsecond;
    ARRAY *oldstack;
    static ARRAY *sortstack = Null(ARRAY*);

    if (gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[sp] = str;
	return sp;
    }
    up = &st[sp];
    for (i = 0; i < max; i++) {
	if ((*up = up[1]) && !(*up)->str_pok)
	    (void)str_2ptr(*up);
	up++;
    }
    sp--;
    if (max > 1) {
	if (stab_sub(stab) && (sortcmd = stab_sub(stab)->cmd)) {
	    int oldtmps_base = tmps_base;

	    if (!sortstack) {
		sortstack = anew(Nullstab);
		sortstack->ary_flags = 0;
	    }
	    oldstack = stack;
	    stack = sortstack;
	    tmps_base = tmps_max;
	    if (!firststab) {
		firststab = stabent("a",TRUE);
		secondstab = stabent("b",TRUE);
	    }
	    oldfirst = stab_val(firststab);
	    oldsecond = stab_val(secondstab);
#ifndef lint
	    qsort((char*)(st+sp+1),max,sizeof(STR*),sortsub);
#else
	    qsort(Nullch,max,sizeof(STR*),sortsub);
#endif
	    stab_val(firststab) = oldfirst;
	    stab_val(secondstab) = oldsecond;
	    tmps_base = oldtmps_base;
	    stack = oldstack;
	}
#ifndef lint
	else
	    qsort((char*)(st+sp+1),max,sizeof(STR*),sortcmp);
#endif
    }
    up = &st[arglast[1]];
    while (max > 0 && !*up)
	max--,up--;
    return sp+max;
}

int
sortsub(str1,str2)
STR **str1;
STR **str2;
{
    if (!*str1)
	return -1;
    if (!*str2)
	return 1;
    stab_val(firststab) = *str1;
    stab_val(secondstab) = *str2;
    cmd_exec(sortcmd,G_SCALAR,-1);
    return (int)str_gnum(*stack->ary_array);
}

sortcmp(strp1,strp2)
STR **strp1;
STR **strp2;
{
    register STR *str1 = *strp1;
    register STR *str2 = *strp2;
    int retval;

    if (!str1)
	return -1;
    if (!str2)
	return 1;

    if (str1->str_cur < str2->str_cur) {
	if (retval = memcmp(str1->str_ptr, str2->str_ptr, str1->str_cur))
	    return retval;
	else
	    return -1;
    }
    else if (retval = memcmp(str1->str_ptr, str2->str_ptr, str2->str_cur))
	return retval;
    else if (str1->str_cur == str2->str_cur)
	return 0;
    else
	return 1;
}

int
do_range(gimme,arglast)
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    register int sp = arglast[0];
    register int i = (int)str_gnum(st[sp+1]);
    register ARRAY *ary = stack;
    register STR *str;
    int max = (int)str_gnum(st[sp+2]);

    if (gimme != G_ARRAY)
	fatal("panic: do_range");

    while (i <= max) {
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str,(double)i++);
    }
    return sp;
}

int
do_tms(str,gimme,arglast)
STR *str;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    register int sp = arglast[0];

    if (gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[++sp] = str;
	return sp;
    }
    (void)times(&timesbuf);

#ifndef HZ
#define HZ 60
#endif

#ifndef lint
    (void)astore(stack,++sp,
      str_2static(str_nmake(((double)timesbuf.tms_utime)/HZ)));
    (void)astore(stack,++sp,
      str_2static(str_nmake(((double)timesbuf.tms_stime)/HZ)));
    (void)astore(stack,++sp,
      str_2static(str_nmake(((double)timesbuf.tms_cutime)/HZ)));
    (void)astore(stack,++sp,
      str_2static(str_nmake(((double)timesbuf.tms_cstime)/HZ)));
#else
    (void)astore(stack,++sp,
      str_2static(str_nmake(0.0)));
#endif
    return sp;
}

int
do_time(str,tmbuf,gimme,arglast)
STR *str;
struct tm *tmbuf;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    STR **st = ary->ary_array;
    register int sp = arglast[0];

    if (!tmbuf || gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[++sp] = str;
	return sp;
    }
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_sec)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_min)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_hour)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_mday)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_mon)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_year)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_wday)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_yday)));
    (void)astore(ary,++sp,str_2static(str_nmake((double)tmbuf->tm_isdst)));
    return sp;
}

int
do_kv(str,hash,kv,gimme,arglast)
STR *str;
HASH *hash;
int kv;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    STR **st = ary->ary_array;
    register int sp = arglast[0];
    int i;
    register HENT *entry;
    char *tmps;
    STR *tmpstr;
    int dokeys = (kv == O_KEYS || kv == O_HASH);
    int dovalues = (kv == O_VALUES || kv == O_HASH);

    if (gimme != G_ARRAY) {
	str_sset(str,&str_undef);
	STABSET(str);
	st[++sp] = str;
	return sp;
    }
    (void)hiterinit(hash);
    while (entry = hiternext(hash)) {
	if (dokeys) {
	    tmps = hiterkey(entry,&i);
	    (void)astore(ary,++sp,str_2static(str_make(tmps,i)));
	}
	if (dovalues) {
	    tmpstr = Str_new(45,0);
#ifdef DEBUGGING
	    if (debug & 8192) {
		sprintf(buf,"%d%%%d=%d\n",entry->hent_hash,
		    hash->tbl_max+1,entry->hent_hash & hash->tbl_max);
		str_set(tmpstr,buf);
	    }
	    else
#endif
	    str_sset(tmpstr,hiterval(hash,entry));
	    (void)astore(ary,++sp,str_2static(tmpstr));
	}
    }
    return sp;
}

int
do_each(str,hash,gimme,arglast)
STR *str;
HASH *hash;
int gimme;
int *arglast;
{
    STR **st = stack->ary_array;
    register int sp = arglast[0];
    static STR *mystrk = Nullstr;
    HENT *entry = hiternext(hash);
    int i;
    char *tmps;

    if (mystrk) {
	str_free(mystrk);
	mystrk = Nullstr;
    }

    if (entry) {
	if (gimme == G_ARRAY) {
	    tmps = hiterkey(entry, &i);
	    st[++sp] = mystrk = str_make(tmps,i);
	}
	st[++sp] = str;
	str_sset(str,hiterval(hash,entry));
	STABSET(str);
	return sp;
    }
    else
	return sp;
}
