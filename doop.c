/* $RCSfile: doarg.c,v $$Revision: 4.1 $$Date: 92/08/07 17:19:37 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	doarg.c,v $
 * Revision 4.1  92/08/07  17:19:37  lwall
 * Stage 6 Snapshot
 * 
 * Revision 4.0.1.7  92/06/11  21:07:11  lwall
 * patch34: join with null list attempted negative allocation
 * patch34: sprintf("%6.4s", "abcdefg") didn't print "abcd  "
 * 
 * Revision 4.0.1.6  92/06/08  12:34:30  lwall
 * patch20: removed implicit int declarations on funcions
 * patch20: pattern modifiers i and o didn't interact right
 * patch20: join() now pre-extends target string to avoid excessive copying
 * patch20: fixed confusion between a *var's real name and its effective name
 * patch20: subroutines didn't localize $`, $&, $', $1 et al correctly
 * patch20: usersub routines didn't reclaim temp values soon enough
 * patch20: ($<,$>) = ... didn't work on some architectures
 * patch20: added Atari ST portability
 * 
 * Revision 4.0.1.5  91/11/11  16:31:58  lwall
 * patch19: added little-endian pack/unpack options
 * 
 * Revision 4.0.1.4  91/11/05  16:35:06  lwall
 * patch11: /$foo/o optimizer could access deallocated data
 * patch11: minimum match length calculation in regexp is now cumulative
 * patch11: added some support for 64-bit integers
 * patch11: prepared for ctype implementations that don't define isascii()
 * patch11: sprintf() now supports any length of s field
 * patch11: indirect subroutine calls through magic vars (e.g. &$1) didn't work
 * patch11: defined(&$foo) and undef(&$foo) didn't work
 * 
 * Revision 4.0.1.3  91/06/10  01:18:41  lwall
 * patch10: pack(hh,1) dumped core
 * 
 * Revision 4.0.1.2  91/06/07  10:42:17  lwall
 * patch4: new copyright notice
 * patch4: // wouldn't use previous pattern if it started with a null character
 * patch4: //o and s///o now optimize themselves fully at runtime
 * patch4: added global modifier for pattern matches
 * patch4: undef @array disabled "@array" interpolation
 * patch4: chop("") was returning "\0" rather than ""
 * patch4: vector logical operations &, | and ^ sometimes returned null string
 * patch4: syscall couldn't pass numbers with most significant bit set on sparcs
 * 
 * Revision 4.0.1.1  91/04/11  17:40:14  lwall
 * patch1: fixed undefined environ problem
 * patch1: fixed debugger coredump on subroutines
 * 
 * Revision 4.0  91/03/20  01:06:42  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#if !defined(NSIG) || defined(M_UNIX) || defined(M_XENIX)
#include <signal.h>
#endif

#ifdef BUGGY_MSC
 #pragma function(memcmp)
#endif /* BUGGY_MSC */

static void doencodes();

#ifdef BUGGY_MSC
 #pragma intrinsic(memcmp)
#endif /* BUGGY_MSC */

I32
do_trans(sv,arg)
SV *sv;
OP *arg;
{
    register short *tbl;
    register char *s;
    register I32 matches = 0;
    register I32 ch;
    register char *send;
    register char *d;
    register I32 squash = op->op_private & OPpTRANS_SQUASH;

    tbl = (short*) cPVOP->op_pv;
    s = SvPVn(sv);
    send = s + SvCUROK(sv);
    if (!tbl || !s)
	fatal("panic: do_trans");
    DEBUG_t( deb("2.TBL\n"));
    if (!op->op_private) {
	while (s < send) {
	    if ((ch = tbl[*s & 0377]) >= 0) {
		matches++;
		*s = ch;
	    }
	    s++;
	}
    }
    else {
	d = s;
	while (s < send) {
	    if ((ch = tbl[*s & 0377]) >= 0) {
		*d = ch;
		if (matches++ && squash) {
		    if (d[-1] == *d)
			matches--;
		    else
			d++;
		}
		else
		    d++;
	    }
	    else if (ch == -1)		/* -1 is unmapped character */
		*d++ = *s;		/* -2 is delete character */
	    s++;
	}
	matches += send - d;	/* account for disappeared chars */
	*d = '\0';
	SvCUR_set(sv, d - SvPV(sv));
    }
    SvSETMAGIC(sv);
    return matches;
}

void
do_join(sv,del,mark,sp)
register SV *sv;
SV *del;
register SV **mark;
register SV **sp;
{
    SV **oldmark = mark;
    register I32 items = sp - mark;
    register char *delim = SvPVn(del);
    register STRLEN len;
    I32 delimlen = SvCUROK(del);

    mark++;
    len = (items > 0 ? (delimlen * (items - 1) ) : 0);
    if (SvTYPE(sv) < SVt_PV)
	sv_upgrade(sv, SVt_PV);
    if (SvLEN(sv) < len + items) {	/* current length is way too short */
	while (items-- > 0) {
	    if (*mark) {
		if (!SvPOK(*mark)) {
		    sv_2pv(*mark);
		    if (!SvPOK(*mark))
			*mark = &sv_no;
		}
		len += SvCUR((*mark));
	    }
	    mark++;
	}
	SvGROW(sv, len + 1);		/* so try to pre-extend */

	mark = oldmark;
	items = sp - mark;;
	++mark;
    }

    if (items-- > 0)
	sv_setsv(sv, *mark++);
    else
	sv_setpv(sv,"");
    len = delimlen;
    if (len) {
	for (; items > 0; items--,mark++) {
	    sv_catpvn(sv,delim,len);
	    sv_catsv(sv,*mark);
	}
    }
    else {
	for (; items > 0; items--,mark++)
	    sv_catsv(sv,*mark);
    }
    SvSETMAGIC(sv);
}

void
do_sprintf(sv,len,sarg)
register SV *sv;
register I32 len;
register SV **sarg;
{
    register char *s;
    register char *t;
    register char *f;
    bool dolong;
#ifdef QUAD
    bool doquad;
#endif /* QUAD */
    char ch;
    register char *send;
    register SV *arg;
    char *xs;
    I32 xlen;
    I32 pre;
    I32 post;
    double value;

    sv_setpv(sv,"");
    len--;			/* don't count pattern string */
    t = s = SvPVn(*sarg);
    send = s + SvCUROK(*sarg);
    sarg++;
    for ( ; ; len--) {

	/*SUPPRESS 560*/
	if (len <= 0 || !(arg = *sarg++))
	    arg = &sv_no;

	/*SUPPRESS 530*/
	for ( ; t < send && *t != '%'; t++) ;
	if (t >= send)
	    break;		/* end of run_format string, ignore extra args */
	f = t;
	*buf = '\0';
	xs = buf;
#ifdef QUAD
	doquad =
#endif /* QUAD */
	dolong = FALSE;
	pre = post = 0;
	for (t++; t < send; t++) {
	    switch (*t) {
	    default:
		ch = *(++t);
		*t = '\0';
		(void)sprintf(xs,f);
		len++, sarg--;
		xlen = strlen(xs);
		break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9': 
	    case '.': case '#': case '-': case '+': case ' ':
		continue;
	    case 'lXXX':
#ifdef QUAD
		if (dolong) {
		    dolong = FALSE;
		    doquad = TRUE;
		} else
#endif
		dolong = TRUE;
		continue;
	    case 'c':
		ch = *(++t);
		*t = '\0';
		xlen = SvIVn(arg);
		if (strEQ(f,"%c")) { /* some printfs fail on null chars */
		    *xs = xlen;
		    xs[1] = '\0';
		    xlen = 1;
		}
		else {
		    (void)sprintf(xs,f,xlen);
		    xlen = strlen(xs);
		}
		break;
	    case 'D':
		dolong = TRUE;
		/* FALL THROUGH */
	    case 'd':
		ch = *(++t);
		*t = '\0';
#ifdef QUAD
		if (doquad)
		    (void)sprintf(buf,s,(quad)SvNVn(arg));
		else
#endif
		if (dolong)
		    (void)sprintf(xs,f,(long)SvNVn(arg));
		else
		    (void)sprintf(xs,f,SvIVn(arg));
		xlen = strlen(xs);
		break;
	    case 'X': case 'O':
		dolong = TRUE;
		/* FALL THROUGH */
	    case 'x': case 'o': case 'u':
		ch = *(++t);
		*t = '\0';
		value = SvNVn(arg);
#ifdef QUAD
		if (doquad)
		    (void)sprintf(buf,s,(unsigned quad)value);
		else
#endif
		if (dolong)
		    (void)sprintf(xs,f,U_L(value));
		else
		    (void)sprintf(xs,f,U_I(value));
		xlen = strlen(xs);
		break;
	    case 'E': case 'e': case 'f': case 'G': case 'g':
		ch = *(++t);
		*t = '\0';
		(void)sprintf(xs,f,SvNVn(arg));
		xlen = strlen(xs);
		break;
	    case 's':
		ch = *(++t);
		*t = '\0';
		xs = SvPVn(arg);
		if (SvPOK(arg))
		    xlen = SvCUR(arg);
		else
		    xlen = strlen(xs);
		if (strEQ(f,"%s")) {	/* some printfs fail on >128 chars */
		    break;		/* so handle simple cases */
		}
		else if (f[1] == '-') {
		    char *mp = strchr(f, '.');
		    I32 min = atoi(f+2);

		    if (mp) {
			I32 max = atoi(mp+1);

			if (xlen > max)
			    xlen = max;
		    }
		    if (xlen < min)
			post = min - xlen;
		    break;
		}
		else if (isDIGIT(f[1])) {
		    char *mp = strchr(f, '.');
		    I32 min = atoi(f+1);

		    if (mp) {
			I32 max = atoi(mp+1);

			if (xlen > max)
			    xlen = max;
		    }
		    if (xlen < min)
			pre = min - xlen;
		    break;
		}
		strcpy(tokenbuf+64,f);	/* sprintf($s,...$s...) */
		*t = ch;
		(void)sprintf(buf,tokenbuf+64,xs);
		xs = buf;
		xlen = strlen(xs);
		break;
	    }
	    /* end of switch, copy results */
	    *t = ch;
	    SvGROW(sv, SvCUR(sv) + (f - s) + xlen + 1 + pre + post);
	    sv_catpvn(sv, s, f - s);
	    if (pre) {
		repeatcpy(SvPV(sv) + SvCUR(sv), " ", 1, pre);
		SvCUR(sv) += pre;
	    }
	    sv_catpvn(sv, xs, xlen);
	    if (post) {
		repeatcpy(SvPV(sv) + SvCUR(sv), " ", 1, post);
		SvCUR(sv) += post;
	    }
	    s = t;
	    break;		/* break from for loop */
	}
    }
    sv_catpvn(sv, s, t - s);
    SvSETMAGIC(sv);
}

void
do_vecset(sv)
SV *sv;
{
    SV *targ = LvTARG(sv);
    register I32 offset;
    register I32 size;
    register unsigned char *s = (unsigned char*)SvPV(targ);
    register unsigned long lval = U_L(SvNVn(sv));
    I32 mask;

    offset = LvTARGOFF(sv);
    size = LvTARGLEN(sv);
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

void
do_chop(astr,sv)
register SV *astr;
register SV *sv;
{
    register char *tmps;
    register I32 i;
    AV *ary;
    HV *hash;
    HE *entry;

    if (!sv)
	return;
    if (SvTYPE(sv) == SVt_PVAV) {
	I32 max;
	SV **array = AvARRAY(sv);
	max = AvFILL(sv);
	for (i = 0; i <= max; i++)
	    do_chop(astr,array[i]);
	return;
    }
    if (SvTYPE(sv) == SVt_PVHV) {
	hash = (HV*)sv;
	(void)hv_iterinit(hash);
	/*SUPPRESS 560*/
	while (entry = hv_iternext(hash))
	    do_chop(astr,hv_iterval(hash,entry));
	return;
    }
    tmps = SvPVn(sv);
    if (tmps && SvCUROK(sv)) {
	tmps += SvCUR(sv) - 1;
	sv_setpvn(astr,tmps,1);	/* remember last char */
	*tmps = '\0';				/* wipe it out */
	SvCUR_set(sv, tmps - SvPV(sv));
	SvNOK_off(sv);
	SvSETMAGIC(sv);
    }
    else
	sv_setpvn(astr,"",0);
}

void
do_vop(optype,sv,left,right)
I32 optype;
SV *sv;
SV *left;
SV *right;
{
#ifdef LIBERAL
    register long *dl;
    register long *ll;
    register long *rl;
#endif
    register char *dc;
    register char *lc = SvPVn(left);
    register char *rc = SvPVn(right);
    register I32 len;
    I32 leftlen = SvCUROK(left);
    I32 rightlen = SvCUROK(right);

    len = leftlen < rightlen ? leftlen : rightlen;
    if (SvTYPE(sv) < SVt_PV)
	sv_upgrade(sv, SVt_PV);
    if (SvCUR(sv) > len)
	SvCUR_set(sv, len);
    else if (SvCUR(sv) < len) {
	SvGROW(sv,len);
	(void)memzero(SvPV(sv) + SvCUR(sv), len - SvCUR(sv));
	SvCUR_set(sv, len);
    }
    SvPOK_only(sv);
    dc = SvPV(sv);
    if (!dc) {
	sv_setpvn(sv,"",0);
	dc = SvPV(sv);
    }
#ifdef LIBERAL
    if (len >= sizeof(long)*4 &&
	!((long)dc % sizeof(long)) &&
	!((long)lc % sizeof(long)) &&
	!((long)rc % sizeof(long)))	/* It's almost always aligned... */
    {
	I32 remainder = len % (sizeof(long)*4);
	len /= (sizeof(long)*4);

	dl = (long*)dc;
	ll = (long*)lc;
	rl = (long*)rc;

	switch (optype) {
	case OP_BIT_AND:
	    while (len--) {
		*dl++ = *ll++ & *rl++;
		*dl++ = *ll++ & *rl++;
		*dl++ = *ll++ & *rl++;
		*dl++ = *ll++ & *rl++;
	    }
	    break;
	case OP_XOR:
	    while (len--) {
		*dl++ = *ll++ ^ *rl++;
		*dl++ = *ll++ ^ *rl++;
		*dl++ = *ll++ ^ *rl++;
		*dl++ = *ll++ ^ *rl++;
	    }
	    break;
	case OP_BIT_OR:
	    while (len--) {
		*dl++ = *ll++ | *rl++;
		*dl++ = *ll++ | *rl++;
		*dl++ = *ll++ | *rl++;
		*dl++ = *ll++ | *rl++;
	    }
	}

	dc = (char*)dl;
	lc = (char*)ll;
	rc = (char*)rl;

	len = remainder;
    }
#endif
    switch (optype) {
    case OP_BIT_AND:
	while (len--)
	    *dc++ = *lc++ & *rc++;
	break;
    case OP_XOR:
	while (len--)
	    *dc++ = *lc++ ^ *rc++;
	goto mop_up;
    case OP_BIT_OR:
	while (len--)
	    *dc++ = *lc++ | *rc++;
      mop_up:
	len = SvCUR(sv);
	if (rightlen > len)
	    sv_catpvn(sv, SvPV(right) + len, rightlen - len);
	else if (leftlen > len)
	    sv_catpvn(sv, SvPV(left) + len, leftlen - len);
	break;
    }
}
