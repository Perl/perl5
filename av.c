/* $RCSfile: array.c,v $$Revision: 4.1 $$Date: 92/08/07 17:18:22 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	array.c,v $
 * Revision 4.1  92/08/07  17:18:22  lwall
 * Stage 6 Snapshot
 * 
 * Revision 4.0.1.3  92/06/08  11:45:05  lwall
 * patch20: Perl now distinguishes overlapped copies from non-overlapped
 * 
 * Revision 4.0.1.2  91/11/05  16:00:14  lwall
 * patch11: random cleanup
 * patch11: passing non-existend array elements to subrouting caused core dump
 * 
 * Revision 4.0.1.1  91/06/07  10:19:08  lwall
 * patch4: new copyright notice
 * 
 * Revision 4.0  91/03/20  01:03:32  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

SV**
av_fetch(ar,key,lval)
register AV *ar;
I32 key;
I32 lval;
{
    SV *sv;

    if (key < 0 || key > AvFILL(ar)) {
	if (lval && key >= 0) {
	    if (AvREAL(ar))
		sv = NEWSV(5,0);
	    else
		sv = sv_mortalcopy(&sv_undef);
	    return av_store(ar,key,sv);
	}
	else
	    return 0;
    }
    if (!AvARRAY(ar)[key]) {
	if (lval) {
	    sv = NEWSV(6,0);
	    return av_store(ar,key,sv);
	}
	return 0;
    }
    return &AvARRAY(ar)[key];
}

SV**
av_store(ar,key,val)
register AV *ar;
I32 key;
SV *val;
{
    I32 tmp;
    SV** ary;

    if (key < 0)
	return 0;
    if (key > AvMAX(ar)) {
	I32 newmax;

	if (AvALLOC(ar) != AvARRAY(ar)) {
	    tmp = AvARRAY(ar) - AvALLOC(ar);
	    Move(AvARRAY(ar), AvALLOC(ar), AvMAX(ar)+1, SV*);
	    Zero(AvALLOC(ar)+AvMAX(ar)+1, tmp, SV*);
	    AvMAX(ar) += tmp;
	    AvARRAY(ar) -= tmp;
	    if (key > AvMAX(ar) - 10) {
		newmax = key + AvMAX(ar);
		goto resize;
	    }
	}
	else {
	    if (AvALLOC(ar)) {
		newmax = key + AvMAX(ar) / 5;
	      resize:
		Renew(AvALLOC(ar),newmax+1, SV*);
		Zero(&AvALLOC(ar)[AvMAX(ar)+1], newmax - AvMAX(ar), SV*);
	    }
	    else {
		newmax = key < 4 ? 4 : key;
		Newz(2,AvALLOC(ar), newmax+1, SV*);
	    }
	    AvARRAY(ar) = AvALLOC(ar);
	    AvMAX(ar) = newmax;
	}
    }
    ary = AvARRAY(ar);
    if (AvREAL(ar)) {
	if (AvFILL(ar) < key) {
	    while (++AvFILL(ar) < key) {
		if (ary[AvFILL(ar)] != Nullsv) {
		    sv_free(ary[AvFILL(ar)]);
		    ary[AvFILL(ar)] = Nullsv;
		}
	    }
	}
	if (ary[key])
	    sv_free(ary[key]);
    }
    ary[key] = val;
    return &ary[key];
}

AV *
newAV()
{
    register AV *ar;

    Newz(1,ar,1,AV);
    SvREFCNT(ar) = 1;
    sv_upgrade(ar,SVt_PVAV);
    AvREAL_on(ar);
    AvALLOC(ar) = AvARRAY(ar) = 0;
    AvMAX(ar) = AvFILL(ar) = -1;
    return ar;
}

AV *
av_make(size,strp)
register I32 size;
register SV **strp;
{
    register AV *ar;
    register I32 i;
    register SV** ary;

    Newz(3,ar,1,AV);
    sv_upgrade(ar,SVt_PVAV);
    New(4,ary,size+1,SV*);
    AvALLOC(ar) = ary;
    Zero(ary,size,SV*);
    AvREAL_on(ar);
    AvARRAY(ar) = ary;
    AvFILL(ar) = size - 1;
    AvMAX(ar) = size - 1;
    for (i = 0; i < size; i++) {
	if (*strp) {
	    ary[i] = NEWSV(7,0);
	    sv_setsv(ary[i], *strp);
	}
	strp++;
    }
    return ar;
}

AV *
av_fake(size,strp)
register I32 size;
register SV **strp;
{
    register AV *ar;
    register SV** ary;

    Newz(3,ar,1,AV);
    SvREFCNT(ar) = 1;
    sv_upgrade(ar,SVt_PVAV);
    New(4,ary,size+1,SV*);
    AvALLOC(ar) = ary;
    Copy(strp,ary,size,SV*);
    AvREAL_off(ar);
    AvARRAY(ar) = ary;
    AvFILL(ar) = size - 1;
    AvMAX(ar) = size - 1;
    while (size--) {
	if (*strp)
	    SvTEMP_off(*strp);
	strp++;
    }
    return ar;
}

void
av_clear(ar)
register AV *ar;
{
    register I32 key;

    if (!ar || !AvREAL(ar) || AvMAX(ar) < 0)
	return;
    /*SUPPRESS 560*/
    if (key = AvARRAY(ar) - AvALLOC(ar)) {
	AvMAX(ar) += key;
	AvARRAY(ar) -= key;
    }
    for (key = 0; key <= AvMAX(ar); key++)
	sv_free(AvARRAY(ar)[key]);
    AvFILL(ar) = -1;
    Zero(AvARRAY(ar), AvMAX(ar)+1, SV*);
}

void
av_undef(ar)
register AV *ar;
{
    register I32 key;

    if (!ar)
	return;
    /*SUPPRESS 560*/
    if (key = AvARRAY(ar) - AvALLOC(ar)) {
	AvMAX(ar) += key;
	AvARRAY(ar) -= key;
    }
    if (AvREAL(ar)) {
	for (key = 0; key <= AvMAX(ar); key++)
	    sv_free(AvARRAY(ar)[key]);
    }
    Safefree(AvALLOC(ar));
    AvALLOC(ar) = AvARRAY(ar) = 0;
    AvMAX(ar) = AvFILL(ar) = -1;
}

void
av_free(ar)
AV *ar;
{
    av_undef(ar);
    Safefree(ar);
}

bool
av_push(ar,val)
register AV *ar;
SV *val;
{
    return av_store(ar,++(AvFILL(ar)),val) != 0;
}

SV *
av_pop(ar)
register AV *ar;
{
    SV *retval;

    if (AvFILL(ar) < 0)
	return Nullsv;
    retval = AvARRAY(ar)[AvFILL(ar)];
    AvARRAY(ar)[AvFILL(ar)--] = Nullsv;
    return retval;
}

void
av_popnulls(ar)
register AV *ar;
{
    register I32 fill = AvFILL(ar);

    while (fill >= 0 && !AvARRAY(ar)[fill])
	fill--;
    AvFILL(ar) = fill;
}

void
av_unshift(ar,num)
register AV *ar;
register I32 num;
{
    register I32 i;
    register SV **sstr,**dstr;

    if (num <= 0)
	return;
    if (AvARRAY(ar) - AvALLOC(ar) >= num) {
	AvMAX(ar) += num;
	AvFILL(ar) += num;
	while (num--)
	    *--AvARRAY(ar) = Nullsv;
    }
    else {
	(void)av_store(ar,AvFILL(ar)+num,(SV*)0);	/* maybe extend array */
	dstr = AvARRAY(ar) + AvFILL(ar);
	sstr = dstr - num;
#ifdef BUGGY_MSC5
 # pragma loop_opt(off)	/* don't loop-optimize the following code */
#endif /* BUGGY_MSC5 */
	for (i = AvFILL(ar) - num; i >= 0; i--) {
	    *dstr-- = *sstr--;
#ifdef BUGGY_MSC5
 # pragma loop_opt()	/* loop-optimization back to command-line setting */
#endif /* BUGGY_MSC5 */
	}
	Zero(AvARRAY(ar), num, SV*);
    }
}

SV *
av_shift(ar)
register AV *ar;
{
    SV *retval;

    if (AvFILL(ar) < 0)
	return Nullsv;
    retval = *AvARRAY(ar);
    *(AvARRAY(ar)++) = Nullsv;
    AvMAX(ar)--;
    AvFILL(ar)--;
    return retval;
}

I32
av_len(ar)
register AV *ar;
{
    return AvFILL(ar);
}

void
av_fill(ar, fill)
register AV *ar;
I32 fill;
{
    if (fill < 0)
	fill = -1;
    if (fill <= AvMAX(ar))
	AvFILL(ar) = fill;
    else {
	AvFILL(ar) = fill - 1;		/* don't clobber in-between values */
	(void)av_store(ar,fill,Nullsv);
    }
}
