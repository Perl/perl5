/* $Header: dolist.c,v 3.0.1.8 90/08/09 03:15:56 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	dolist.c,v $
 * Revision 3.0.1.8  90/08/09  03:15:56  lwall
 * patch19: certain kinds of matching cause "panic: hint"
 * patch19: $' broke on embedded nulls
 * patch19: split on /\s+/, /^/ and ' ' is now special cased for speed
 * patch19: split on /x/i didn't work
 * patch19: couldn't unpack an 'A' or 'a' field in a scalar context
 * patch19: unpack called bcopy on each character of a C/c field
 * patch19: pack/unpack know about uudecode lines
 * patch19: fixed sort on undefined strings and sped up slightly
 * patch19: each and keys returned garbage on null key in DBM file
 * 
 * Revision 3.0.1.7  90/03/27  15:48:42  lwall
 * patch16: MSDOS support
 * patch16: use of $`, $& or $' sometimes causes memory leakage
 * patch16: splice(@array,0,$n) case cause duplicate free
 * patch16: grep blows up on undefined array values
 * patch16: .. now works using magical string increment
 * 
 * Revision 3.0.1.6  90/03/12  16:33:02  lwall
 * patch13: added list slice operator (LIST)[LIST]
 * patch13: added splice operator: @oldelems = splice(@array,$offset,$len,LIST)
 * patch13: made split('') act like split(//) rather than split(' ')
 * 
 * Revision 3.0.1.5  90/02/28  17:09:44  lwall
 * patch9: split now can split into more than 10000 elements
 * patch9: @_ clobbered by ($foo,$bar) = split
 * patch9: sped up pack and unpack
 * patch9: unpack of single item now works in a scalar context
 * patch9: slices ignored value of $[
 * patch9: grep now returns number of items matched in scalar context
 * patch9: grep iterations no longer in the regexp context of previous iteration
 * 
 * Revision 3.0.1.4  89/12/21  19:58:46  lwall
 * patch7: grep(1,@array) didn't work
 * patch7: /$pat/; //; wrongly freed runtime pattern twice
 * 
 * Revision 3.0.1.3  89/11/17  15:14:45  lwall
 * patch5: grep() occasionally loses arguments or dumps core
 * 
 * Revision 3.0.1.2  89/11/11  04:28:17  lwall
 * patch2: non-existent slice values are now undefined rather than null
 * 
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


#ifdef BUGGY_MSC
 #pragma function(memcmp)
#endif /* BUGGY_MSC */

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
    char *myhint = hint;

    hint = Nullch;
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
	    spat->spat_flags & SPAT_FOLD);
	if (!*spat->spat_regexp->precomp && lastspat)
	    spat = lastspat;
	if (spat->spat_flags & SPAT_KEEP) {
	    if (spat->spat_runtime)
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
	if (myhint) {
	    if (myhint < s || myhint > strend)
		fatal("panic: hint in do_match");
	    s = myhint;
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

	if (spat->spat_regexp->subbase)
	    Safefree(spat->spat_regexp->subbase);
	tmps = spat->spat_regexp->subbase = nsavestr(t,strend-t);
	spat->spat_regexp->subend = tmps + (strend-t);
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

#ifdef BUGGY_MSC
 #pragma intrinsic(memcmp)
#endif /* BUGGY_MSC */

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
    int maxiters = (strend - s) + 10;
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
	if (*m == ' ' && dstr->str_cur == 1) {
	    str_set(dstr,"\\s+");
	    m = dstr->str_ptr;
	    spat->spat_flags |= SPAT_SKIPWHITE;
	}
	if (spat->spat_regexp)
	    regfree(spat->spat_regexp);
	spat->spat_regexp = regcomp(m,m+dstr->str_cur,
	    spat->spat_flags & SPAT_FOLD);
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
    if (ary && (gimme != G_ARRAY || (spat->spat_flags & SPAT_ONCE))) {
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
	limit = maxiters + 2;
    if (strEQ("\\s+",spat->spat_regexp->precomp)) {
	while (--limit) {
	    for (m = s; m < strend && !isspace(*m); m++) ;
	    if (m >= strend)
		break;
	    if (realarray)
		dstr = Str_new(30,m-s);
	    else
		dstr = str_static(&str_undef);
	    str_nset(dstr,s,m-s);
	    (void)astore(ary, ++sp, dstr);
	    for (s = m + 1; s < strend && isspace(*s); s++) ;
	}
    }
    else if (strEQ("^",spat->spat_regexp->precomp)) {
	while (--limit) {
	    for (m = s; m < strend && *m != '\n'; m++) ;
	    m++;
	    if (m >= strend)
		break;
	    if (realarray)
		dstr = Str_new(30,m-s);
	    else
		dstr = str_static(&str_undef);
	    str_nset(dstr,s,m-s);
	    (void)astore(ary, ++sp, dstr);
	    s = m;
	}
    }
    else if (spat->spat_short) {
	i = spat->spat_short->str_cur;
	if (i == 1) {
	    int fold = (spat->spat_flags & SPAT_FOLD);

	    i = *spat->spat_short->str_ptr;
	    if (fold && isupper(i))
		i = tolower(i);
	    while (--limit) {
		if (fold) {
		    for ( m = s;
			  m < strend && *m != i &&
			    (!isupper(*m) || tolower(*m) != i);
			  m++)
			;
		}
		else
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
	maxiters += (strend - s) * spat->spat_regexp->nparens;
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
    if (iters > maxiters)
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
#ifndef I286x
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
    char *strbeg = s;
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
    float afloat;
    double adouble;
    int checksum = 0;
    unsigned long culong;
    double cdouble;

    if (gimme != G_ARRAY) {		/* arrange to do first one only */
	for (patend = pat; !isalpha(*patend); patend++);
	if (*patend == 'a' || *patend == 'A' || *pat == '%') {
	    patend++;
	    while (isdigit(*patend) || *patend == '*')
		patend++;
	}
	else
	    patend++;
    }
    sp--;
    while (pat < patend) {
      reparse:
	datumtype = *pat++;
	if (pat >= patend)
	    len = 1;
	else if (*pat == '*')
	    len = strend - strbeg;	/* long enough */
	else if (isdigit(*pat)) {
	    len = *pat++ - '0';
	    while (isdigit(*pat))
		len = (len * 10) + (*pat++ - '0');
	}
	else
	    len = (datumtype != '@');
	switch(datumtype) {
	default:
	    break;
	case '%':
	    if (len == 1 && pat[-1] != '1')
		len = 16;
	    checksum = len;
	    culong = 0;
	    cdouble = 0;
	    if (pat < patend)
		goto reparse;
	    break;
	case '@':
	    if (len > strend - s)
		fatal("@ outside of string");
	    s = strbeg + len;
	    break;
	case 'X':
	    if (len > s - strbeg)
		fatal("X outside of string");
	    s -= len;
	    break;
	case 'x':
	    if (len > strend - s)
		fatal("x outside of string");
	    s += len;
	    break;
	case 'A':
	case 'a':
	    if (len > strend - s)
		len = strend - s;
	    if (checksum)
		goto uchar_checksum;
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
	    if (len > strend - s)
		len = strend - s;
	    if (checksum) {
		while (len-- > 0) {
		    aint = *s++;
		    if (aint >= 128)	/* fake up signed chars */
			aint -= 256;
		    culong += aint;
		}
	    }
	    else {
		while (len-- > 0) {
		    aint = *s++;
		    if (aint >= 128)	/* fake up signed chars */
			aint -= 256;
		    str = Str_new(36,0);
		    str_numset(str,(double)aint);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'C':
	    if (len > strend - s)
		len = strend - s;
	    if (checksum) {
	      uchar_checksum:
		while (len-- > 0) {
		    auint = *s++ & 255;
		    culong += auint;
		}
	    }
	    else {
		while (len-- > 0) {
		    auint = *s++ & 255;
		    str = Str_new(37,0);
		    str_numset(str,(double)auint);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 's':
	    along = (strend - s) / sizeof(short);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s,(char*)&ashort,sizeof(short));
		    s += sizeof(short);
		    culong += ashort;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s,(char*)&ashort,sizeof(short));
		    s += sizeof(short);
		    str = Str_new(38,0);
		    str_numset(str,(double)ashort);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'n':
	case 'S':
	    along = (strend - s) / sizeof(unsigned short);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s,(char*)&aushort,sizeof(unsigned short));
		    s += sizeof(unsigned short);
#ifdef NTOHS
		    if (datumtype == 'n')
			aushort = ntohs(aushort);
#endif
		    culong += aushort;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s,(char*)&aushort,sizeof(unsigned short));
		    s += sizeof(unsigned short);
		    str = Str_new(39,0);
#ifdef NTOHS
		    if (datumtype == 'n')
			aushort = ntohs(aushort);
#endif
		    str_numset(str,(double)aushort);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'i':
	    along = (strend - s) / sizeof(int);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s,(char*)&aint,sizeof(int));
		    s += sizeof(int);
		    if (checksum > 32)
			cdouble += (double)aint;
		    else
			culong += aint;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s,(char*)&aint,sizeof(int));
		    s += sizeof(int);
		    str = Str_new(40,0);
		    str_numset(str,(double)aint);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'I':
	    along = (strend - s) / sizeof(unsigned int);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s,(char*)&auint,sizeof(unsigned int));
		    s += sizeof(unsigned int);
		    if (checksum > 32)
			cdouble += (double)auint;
		    else
			culong += auint;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s,(char*)&auint,sizeof(unsigned int));
		    s += sizeof(unsigned int);
		    str = Str_new(41,0);
		    str_numset(str,(double)auint);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'l':
	    along = (strend - s) / sizeof(long);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s,(char*)&along,sizeof(long));
		    s += sizeof(long);
		    if (checksum > 32)
			cdouble += (double)along;
		    else
			culong += along;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s,(char*)&along,sizeof(long));
		    s += sizeof(long);
		    str = Str_new(42,0);
		    str_numset(str,(double)along);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'N':
	case 'L':
	    along = (strend - s) / sizeof(unsigned long);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s,(char*)&aulong,sizeof(unsigned long));
		    s += sizeof(unsigned long);
#ifdef NTOHL
		    if (datumtype == 'N')
			aulong = ntohl(aulong);
#endif
		    if (checksum > 32)
			cdouble += (double)aulong;
		    else
			culong += aulong;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s,(char*)&aulong,sizeof(unsigned long));
		    s += sizeof(unsigned long);
		    str = Str_new(43,0);
#ifdef NTOHL
		    if (datumtype == 'N')
			aulong = ntohl(aulong);
#endif
		    str_numset(str,(double)aulong);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'p':
	    along = (strend - s) / sizeof(char*);
	    if (len > along)
		len = along;
	    while (len-- > 0) {
		if (sizeof(char*) > strend - s)
		    break;
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
	/* float and double added gnb@melba.bby.oz.au 22/11/89 */
	case 'f':
	case 'F':
	    along = (strend - s) / sizeof(float);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s, (char *)&afloat, sizeof(float));
		    s += sizeof(float);
		    cdouble += afloat;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s, (char *)&afloat, sizeof(float));
		    s += sizeof(float);
		    str = Str_new(47, 0);
		    str_numset(str, (double)afloat);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'd':
	case 'D':
	    along = (strend - s) / sizeof(double);
	    if (len > along)
		len = along;
	    if (checksum) {
		while (len-- > 0) {
		    bcopy(s, (char *)&adouble, sizeof(double));
		    s += sizeof(double);
		    cdouble += adouble;
		}
	    }
	    else {
		while (len-- > 0) {
		    bcopy(s, (char *)&adouble, sizeof(double));
		    s += sizeof(double);
		    str = Str_new(48, 0);
		    str_numset(str, (double)adouble);
		    (void)astore(stack, ++sp, str_2static(str));
		}
	    }
	    break;
	case 'u':
	    along = (strend - s) * 3 / 4;
	    str = Str_new(42,along);
	    while (s < strend && *s > ' ' && *s < 'a') {
		int a,b,c,d;
		char hunk[4];

		hunk[3] = '\0';
		len = (*s++ - ' ') & 077;
		while (len > 0) {
		    if (s < strend && *s >= ' ')
			a = (*s++ - ' ') & 077;
		    else
			a = 0;
		    if (s < strend && *s >= ' ')
			b = (*s++ - ' ') & 077;
		    else
			b = 0;
		    if (s < strend && *s >= ' ')
			c = (*s++ - ' ') & 077;
		    else
			c = 0;
		    if (s < strend && *s >= ' ')
			d = (*s++ - ' ') & 077;
		    else
			d = 0;
		    hunk[0] = a << 2 | b >> 4;
		    hunk[1] = b << 4 | c >> 2;
		    hunk[2] = c << 6 | d;
		    str_ncat(str,hunk, len > 3 ? 3 : len);
		    len -= 3;
		}
		if (*s == '\n')
		    s++;
		else if (s[1] == '\n')		/* possible checksum byte */
		    s += 2;
	    }
	    (void)astore(stack, ++sp, str_2static(str));
	    break;
	}
	if (checksum) {
	    str = Str_new(42,0);
	    if (index("fFdD", datumtype) ||
	      (checksum > 32 && index("iIlLN", datumtype)) ) {
		double modf();
		double trouble;

		adouble = 1.0;
		while (checksum >= 16) {
		    checksum -= 16;
		    adouble *= 65536.0;
		}
		while (checksum >= 4) {
		    checksum -= 4;
		    adouble *= 16.0;
		}
		while (checksum--)
		    adouble *= 2.0;
		along = (1 << checksum) - 1;
		while (cdouble < 0.0)
		    cdouble += adouble;
		cdouble = modf(cdouble / adouble, &trouble) * adouble;
		str_numset(str,cdouble);
	    }
	    else {
		along = (1 << checksum) - 1;
		culong &= (unsigned long)along;
		str_numset(str,(double)culong);
	    }
	    (void)astore(stack, ++sp, str_2static(str));
	    checksum = 0;
	}
    }
    return sp;
}

int
do_slice(stab,str,numarray,lval,gimme,arglast)
STAB *stab;
STR *str;
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
    register ARRAY *ary;
    register HASH *hash;
    int oldarybase = arybase;

    if (numarray) {
	if (numarray == 2) {		/* a slice of a LIST */
	    ary = stack;
	    ary->ary_fill = arglast[3];
	    arybase -= max + 1;
	    st[sp] = str;		/* make stack size available */
	    str_numset(str,(double)(sp - 1));
	}
	else
	    ary = stab_array(stab);	/* a slice of an array */
    }
    else {
	if (lval) {
	    if (stab == envstab)
		magic = 'E';
	    else if (stab == sigstab)
		magic = 'S';
#ifdef SOME_DBM
	    else if (stab_hash(stab)->tbl_dbm)
		magic = 'D';
#endif /* SOME_DBM */
	}
	hash = stab_hash(stab);		/* a slice of an associative array */
    }

    if (gimme == G_ARRAY) {
	if (numarray) {
	    while (sp < max) {
		if (st[++sp]) {
		    st[sp-1] = afetch(ary,
		      ((int)str_gnum(st[sp])) - arybase, lval);
		}
		else
		    st[sp-1] = &str_undef;
	    }
	}
	else {
	    while (sp < max) {
		if (st[++sp]) {
		    tmps = str_get(st[sp]);
		    len = st[sp]->str_cur;
		    st[sp-1] = hfetch(hash,tmps,len, lval);
		    if (magic)
			str_magic(st[sp-1],stab,magic,tmps,len);
		}
		else
		    st[sp-1] = &str_undef;
	    }
	}
	sp--;
    }
    else {
	if (numarray) {
	    if (st[max])
		st[sp] = afetch(ary,
		  ((int)str_gnum(st[max])) - arybase, lval);
	    else
		st[sp] = &str_undef;
	}
	else {
	    if (st[max]) {
		tmps = str_get(st[max]);
		len = st[max]->str_cur;
		st[sp] = hfetch(hash,tmps,len, lval);
		if (magic)
		    str_magic(st[sp],stab,magic,tmps,len);
	    }
	    else
		st[sp] = &str_undef;
	}
    }
    arybase = oldarybase;
    return sp;
}

int
do_splice(ary,gimme,arglast)
register ARRAY *ary;
int gimme;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    int max = arglast[2] + 1;
    register STR **src;
    register STR **dst;
    register int i;
    register int offset;
    register int length;
    int newlen;
    int after;
    int diff;
    STR **tmparyval;

    if (++sp < max) {
	offset = ((int)str_gnum(st[sp])) - arybase;
	if (offset < 0)
	    offset += ary->ary_fill + 1;
	if (++sp < max) {
	    length = (int)str_gnum(st[sp++]);
	    if (length < 0)
		length = 0;
	}
	else
	    length = ary->ary_max;		/* close enough to infinity */
    }
    else {
	offset = 0;
	length = ary->ary_max;
    }
    if (offset < 0) {
	length += offset;
	offset = 0;
	if (length < 0)
	    length = 0;
    }
    if (offset > ary->ary_fill + 1)
	offset = ary->ary_fill + 1;
    after = ary->ary_fill + 1 - (offset + length);
    if (after < 0) {				/* not that much array */
	length += after;			/* offset+length now in array */
	after = 0;
    }

    /* At this point, sp .. max-1 is our new LIST */

    newlen = max - sp;
    diff = newlen - length;

    if (diff < 0) {				/* shrinking the area */
	if (newlen) {
	    New(451, tmparyval, newlen, STR*);	/* so remember insertion */
	    Copy(st+sp, tmparyval, newlen, STR*);
	}

	sp = arglast[0] + 1;
	if (gimme == G_ARRAY) {			/* copy return vals to stack */
	    if (sp + length >= stack->ary_max) {
		astore(stack,sp + length, Nullstr);
		st = stack->ary_array;
	    }
	    Copy(ary->ary_array+offset, st+sp, length, STR*);
	    if (ary->ary_flags & ARF_REAL) {
		for (i = length, dst = st+sp; i; i--)
		    str_2static(*dst++);	/* free them eventualy */
	    }
	    sp += length - 1;
	}
	else {
	    st[sp] = ary->ary_array[offset+length-1];
	    if (ary->ary_flags & ARF_REAL)
		str_2static(st[sp]);
	}
	ary->ary_fill += diff;

	/* pull up or down? */

	if (offset < after) {			/* easier to pull up */
	    if (offset) {			/* esp. if nothing to pull */
		src = &ary->ary_array[offset-1];
		dst = src - diff;		/* diff is negative */
		for (i = offset; i > 0; i--)	/* can't trust Copy */
		    *dst-- = *src--;
	    }
	    Zero(ary->ary_array, -diff, STR*);
	    ary->ary_array -= diff;		/* diff is negative */
	    ary->ary_max += diff;
	}
	else {
	    if (after) {			/* anything to pull down? */
		src = ary->ary_array + offset + length;
		dst = src + diff;		/* diff is negative */
		Copy(src, dst, after, STR*);
	    }
	    Zero(&ary->ary_array[ary->ary_fill+1], -diff, STR*);
						/* avoid later double free */
	}
	if (newlen) {
	    for (src = tmparyval, dst = ary->ary_array + offset;
	      newlen; newlen--) {
		*dst = Str_new(46,0);
		str_sset(*dst++,*src++);
	    }
	    Safefree(tmparyval);
	}
    }
    else {					/* no, expanding (or same) */
	if (length) {
	    New(452, tmparyval, length, STR*);	/* so remember deletion */
	    Copy(ary->ary_array+offset, tmparyval, length, STR*);
	}

	if (diff > 0) {				/* expanding */

	    /* push up or down? */

	    if (offset < after && diff <= ary->ary_array - ary->ary_alloc) {
		if (offset) {
		    src = ary->ary_array;
		    dst = src - diff;
		    Copy(src, dst, offset, STR*);
		}
		ary->ary_array -= diff;		/* diff is positive */
		ary->ary_max += diff;
		ary->ary_fill += diff;
	    }
	    else {
		if (ary->ary_fill + diff >= ary->ary_max)	/* oh, well */
		    astore(ary, ary->ary_fill + diff, Nullstr);
		else
		    ary->ary_fill += diff;
		if (after) {
		    dst = ary->ary_array + ary->ary_fill;
		    src = dst - diff;
		    for (i = after; i; i--) {
			if (*dst)		/* str was hanging around */
			    str_free(*dst);	/*  after $#foo */
			*dst-- = *src;
			*src-- = Nullstr;
		    }
		}
	    }
	}

	for (src = st+sp, dst = ary->ary_array + offset; newlen; newlen--) {
	    *dst = Str_new(46,0);
	    str_sset(*dst++,*src++);
	}
	sp = arglast[0] + 1;
	if (gimme == G_ARRAY) {			/* copy return vals to stack */
	    if (length) {
		Copy(tmparyval, st+sp, length, STR*);
		if (ary->ary_flags & ARF_REAL) {
		    for (i = length, dst = st+sp; i; i--)
			str_2static(*dst++);	/* free them eventualy */
		}
		Safefree(tmparyval);
	    }
	    sp += length - 1;
	}
	else if (length) {
	    st[sp] = tmparyval[length-1];
	    if (ary->ary_flags & ARF_REAL)
		str_2static(st[sp]);
	    Safefree(tmparyval);
	}
	else
	    st[sp] = &str_undef;
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
    register int dst = arglast[1];
    register int src = dst + 1;
    register int sp = arglast[2];
    register int i = sp - arglast[1];
    int oldsave = savestack->ary_fill;
    SPAT *oldspat = curspat;

    savesptr(&stab_val(defstab));
    if ((arg[1].arg_type & A_MASK) != A_EXPR) {
	arg[1].arg_type &= A_MASK;
	dehoist(arg,1);
	arg[1].arg_type |= A_DONT;
    }
    arg = arg[1].arg_ptr.arg_arg;
    while (i-- > 0) {
	if (st[src])
	    stab_val(defstab) = st[src];
	else
	    stab_val(defstab) = str_static(&str_undef);
	(void)eval(arg,G_SCALAR,sp);
	st = stack->ary_array;
	if (str_true(st[sp+1]))
	    st[dst++] = st[src];
	src++;
	curspat = oldspat;
    }
    restorelist(oldsave);
    if (gimme != G_ARRAY) {
	str_numset(str,(double)(dst - arglast[1]));
	STABSET(str);
	st[arglast[0]+1] = str;
	return arglast[0]+1;
    }
    return arglast[0] + (dst - arglast[1]);
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
    register STR **st = stack->ary_array;
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
    st += sp;		/* temporarily make st point to args */
    for (i = 1; i <= max; i++) {
	if (*up = st[i]) {
	    if (!(*up)->str_pok)
		(void)str_2ptr(*up);
	    up++;
	}
    }
    st -= sp;
    max = up - &st[sp];
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
    return sp+max;
}

int
sortsub(str1,str2)
STR **str1;
STR **str2;
{
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
    register int i;
    register ARRAY *ary = stack;
    register STR *str;
    int max;

    if (gimme != G_ARRAY)
	fatal("panic: do_range");

    if (st[sp+1]->str_nok ||
      (looks_like_number(st[sp+1]) && *st[sp+1]->str_ptr != '0') ) {
	i = (int)str_gnum(st[sp+1]);
	max = (int)str_gnum(st[sp+2]);
	while (i <= max) {
	    (void)astore(ary, ++sp, str = str_static(&str_no));
	    str_numset(str,(double)i++);
	}
    }
    else {
	STR *final = str_static(st[sp+2]);
	char *tmps = str_get(final);

	str = str_static(st[sp+1]);
	while (!str->str_nok && str->str_cur <= final->str_cur &&
	    strNE(str->str_ptr,tmps) ) {
	    (void)astore(ary, ++sp, str);
	    str = str_static(str);
	    str_inc(str);
	}
	if (strEQ(str->str_ptr,tmps))
	    (void)astore(ary, ++sp, str);
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
	    if (!i)
		tmps = "";
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
	    if (!i)
		tmps = "";
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
