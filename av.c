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
av_fetch(av,key,lval)
register AV *av;
I32 key;
I32 lval;
{
    SV *sv;

    if (SvMAGICAL(av)) {
	if (mg_find((SV*)av,'P')) {
	    if (key < 0)
		return 0;
	    sv = sv_2mortal(NEWSV(61,0));
	    mg_copy((SV*)av, sv, 0, key);
	    if (!lval) {
		mg_get((SV*)sv);
		sv_unmagic(sv,'p');
	    }
	    Sv = sv;
	    return &Sv;
	}
    }

    if (key < 0 || key > AvFILL(av)) {
	if (key < 0) {
	    key += AvFILL(av) + 1;
	    if (key < 0)
		return 0;
	}
	else {
	    if (!lval)
		return 0;
	    if (AvREAL(av))
		sv = NEWSV(5,0);
	    else
		sv = sv_mortalcopy(&sv_undef);
	    return av_store(av,key,sv);
	}
    }
    if (!AvARRAY(av)[key]) {
	if (lval) {
	    sv = NEWSV(6,0);
	    return av_store(av,key,sv);
	}
	return 0;
    }
    return &AvARRAY(av)[key];
}

SV**
av_store(av,key,val)
register AV *av;
I32 key;
SV *val;
{
    I32 tmp;
    SV** ary;

    if (key < 0) {
	key += AvFILL(av) + 1;
	if (key < 0)
	    return 0;
    }

    if (SvMAGICAL(av)) {
	if (mg_find((SV*)av,'P')) {
	    mg_copy((SV*)av, val, 0, key);
	    return 0;
	}
    }

    if (key > AvMAX(av)) {
	I32 newmax;

	if (AvALLOC(av) != AvARRAY(av)) {
	    tmp = AvARRAY(av) - AvALLOC(av);
	    Move(AvARRAY(av), AvALLOC(av), AvMAX(av)+1, SV*);
	    Zero(AvALLOC(av)+AvMAX(av)+1, tmp, SV*);
	    AvMAX(av) += tmp;
	    SvPVX(av) = (char*)(AvARRAY(av) - tmp);
	    if (key > AvMAX(av) - 10) {
		newmax = key + AvMAX(av);
		goto resize;
	    }
	}
	else {
	    if (AvALLOC(av)) {
		newmax = key + AvMAX(av) / 5;
	      resize:
		Renew(AvALLOC(av),newmax+1, SV*);
		Zero(&AvALLOC(av)[AvMAX(av)+1], newmax - AvMAX(av), SV*);
	    }
	    else {
		newmax = key < 4 ? 4 : key;
		Newz(2,AvALLOC(av), newmax+1, SV*);
	    }
	    SvPVX(av) = (char*)AvALLOC(av);
	    AvMAX(av) = newmax;
	}
    }
    ary = AvARRAY(av);
    if (AvREAL(av)) {
	if (AvFILL(av) < key) {
	    while (++AvFILL(av) < key) {
		if (ary[AvFILL(av)] != Nullsv) {
		    sv_free(ary[AvFILL(av)]);
		    ary[AvFILL(av)] = Nullsv;
		}
	    }
	}
	if (ary[key])
	    sv_free(ary[key]);
    }
    ary[key] = val;
    if (SvMAGICAL(av)) {
	MAGIC* mg = SvMAGIC(av);
	sv_magic(val, (SV*)av, tolower(mg->mg_type), 0, key);
	mg_set((SV*)av);
    }
    return &ary[key];
}

AV *
newAV()
{
    register AV *av;

    Newz(1,av,1,AV);
    SvREFCNT(av) = 1;
    sv_upgrade(av,SVt_PVAV);
    AvREAL_on(av);
    AvALLOC(av) = 0;
    SvPVX(av) = 0;
    AvMAX(av) = AvFILL(av) = -1;
    return av;
}

AV *
av_make(size,strp)
register I32 size;
register SV **strp;
{
    register AV *av;
    register I32 i;
    register SV** ary;

    Newz(3,av,1,AV);
    sv_upgrade(av,SVt_PVAV);
    New(4,ary,size+1,SV*);
    AvALLOC(av) = ary;
    Zero(ary,size,SV*);
    AvREAL_on(av);
    SvPVX(av) = (char*)ary;
    AvFILL(av) = size - 1;
    AvMAX(av) = size - 1;
    for (i = 0; i < size; i++) {
	if (*strp) {
	    ary[i] = NEWSV(7,0);
	    sv_setsv(ary[i], *strp);
	}
	strp++;
    }
    SvOK_on(av);
    return av;
}

AV *
av_fake(size,strp)
register I32 size;
register SV **strp;
{
    register AV *av;
    register SV** ary;

    Newz(3,av,1,AV);
    SvREFCNT(av) = 1;
    sv_upgrade(av,SVt_PVAV);
    New(4,ary,size+1,SV*);
    AvALLOC(av) = ary;
    Copy(strp,ary,size,SV*);
    AvREAL_off(av);
    SvPVX(av) = (char*)ary;
    AvFILL(av) = size - 1;
    AvMAX(av) = size - 1;
    while (size--) {
	if (*strp)
	    SvTEMP_off(*strp);
	strp++;
    }
    SvOK_on(av);
    return av;
}

void
av_clear(av)
register AV *av;
{
    register I32 key;

    if (!av || !AvREAL(av) || AvMAX(av) < 0)
	return;
    /*SUPPRESS 560*/
    if (key = AvARRAY(av) - AvALLOC(av)) {
	AvMAX(av) += key;
	SvPVX(av) = (char*)(AvARRAY(av) - key);
    }
    for (key = 0; key <= AvMAX(av); key++)
	sv_free(AvARRAY(av)[key]);
    AvFILL(av) = -1;
    Zero(AvARRAY(av), AvMAX(av)+1, SV*);
}

void
av_undef(av)
register AV *av;
{
    register I32 key;

    if (!av)
	return;
    /*SUPPRESS 560*/
    if (key = AvARRAY(av) - AvALLOC(av)) {
	AvMAX(av) += key;
	SvPVX(av) = (char*)(AvARRAY(av) - key);
    }
    if (AvREAL(av)) {
	for (key = 0; key <= AvMAX(av); key++)
	    sv_free(AvARRAY(av)[key]);
    }
    Safefree(AvALLOC(av));
    AvALLOC(av) = 0;
    SvPVX(av) = 0;
    AvMAX(av) = AvFILL(av) = -1;
}

void
av_free(av)
AV *av;
{
    av_undef(av);
    Safefree(av);
}

bool
av_push(av,val)
register AV *av;
SV *val;
{
    return av_store(av,++(AvFILL(av)),val) != 0;
}

SV *
av_pop(av)
register AV *av;
{
    SV *retval;

    if (AvFILL(av) < 0)
	return Nullsv;
    retval = AvARRAY(av)[AvFILL(av)];
    AvARRAY(av)[AvFILL(av)--] = Nullsv;
    if (SvMAGICAL(av))
	mg_set((SV*)av);
    return retval;
}

void
av_popnulls(av)
register AV *av;
{
    register I32 fill = AvFILL(av);

    while (fill >= 0 && !AvARRAY(av)[fill])
	fill--;
    AvFILL(av) = fill;
}

void
av_unshift(av,num)
register AV *av;
register I32 num;
{
    register I32 i;
    register SV **sstr,**dstr;

    if (num <= 0)
	return;
    if (AvARRAY(av) - AvALLOC(av) >= num) {
	AvMAX(av) += num;
	AvFILL(av) += num;
	while (num--) {
	    SvPVX(av) = (char*)(AvARRAY(av) - 1);
	    *AvARRAY(av) = Nullsv;
	}
    }
    else {
	(void)av_store(av,AvFILL(av)+num,(SV*)0);	/* maybe extend array */
	dstr = AvARRAY(av) + AvFILL(av);
	sstr = dstr - num;
#ifdef BUGGY_MSC5
 # pragma loop_opt(off)	/* don't loop-optimize the following code */
#endif /* BUGGY_MSC5 */
	for (i = AvFILL(av) - num; i >= 0; i--) {
	    *dstr-- = *sstr--;
#ifdef BUGGY_MSC5
 # pragma loop_opt()	/* loop-optimization back to command-line setting */
#endif /* BUGGY_MSC5 */
	}
	Zero(AvARRAY(av), num, SV*);
    }
}

SV *
av_shift(av)
register AV *av;
{
    SV *retval;

    if (AvFILL(av) < 0)
	return Nullsv;
    retval = *AvARRAY(av);
    *AvARRAY(av) = Nullsv;
    SvPVX(av) = (char*)(AvARRAY(av) + 1);
    AvMAX(av)--;
    AvFILL(av)--;
    if (SvMAGICAL(av))
	mg_set((SV*)av);
    return retval;
}

I32
av_len(av)
register AV *av;
{
    return AvFILL(av);
}

void
av_fill(av, fill)
register AV *av;
I32 fill;
{
    if (fill < 0)
	fill = -1;
    if (fill <= AvMAX(av)) {
	AvFILL(av) = fill;
	if (SvMAGICAL(av))
	    mg_set((SV*)av);
    }
    else {
	AvFILL(av) = fill - 1;		/* don't clobber in-between values */
	(void)av_store(av,fill,Nullsv);
    }
}
