/* $Header: array.c,v 3.0 89/10/18 15:08:33 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	array.c,v $
 * Revision 3.0  89/10/18  15:08:33  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

STR *
afetch(ar,key,lval)
register ARRAY *ar;
int key;
int lval;
{
    STR *str;

    if (key < 0 || key > ar->ary_fill) {
	if (lval && key >= 0) {
	    if (ar->ary_flags & ARF_REAL)
		str = Str_new(5,0);
	    else
		str = str_static(&str_undef);
	    (void)astore(ar,key,str);
	    return str;
	}
	else
	    return Nullstr;
    }
    if (lval && !ar->ary_array[key]) {
	str = Str_new(6,0);
	(void)astore(ar,key,str);
	return str;
    }
    return ar->ary_array[key];
}

bool
astore(ar,key,val)
register ARRAY *ar;
int key;
STR *val;
{
    int retval;

    if (key < 0)
	return FALSE;
    if (key > ar->ary_max) {
	int newmax;

	if (ar->ary_alloc != ar->ary_array) {
	    retval = ar->ary_array - ar->ary_alloc;
	    Copy(ar->ary_array, ar->ary_alloc, ar->ary_max+1, STR*);
	    Zero(ar->ary_alloc+ar->ary_max+1, retval, STR*);
	    ar->ary_max += retval;
	    ar->ary_array -= retval;
	    if (key > ar->ary_max - 10) {
		newmax = key + ar->ary_max;
		goto resize;
	    }
	}
	else {
	    newmax = key + ar->ary_max / 5;
	  resize:
	    Renew(ar->ary_alloc,newmax+1, STR*);
	    Zero(&ar->ary_alloc[ar->ary_max+1], newmax - ar->ary_max, STR*);
	    ar->ary_array = ar->ary_alloc;
	    ar->ary_max = newmax;
	}
    }
    if ((ar->ary_flags & ARF_REAL) && ar->ary_fill < key) {
	while (++ar->ary_fill < key) {
	    if (ar->ary_array[ar->ary_fill] != Nullstr) {
		str_free(ar->ary_array[ar->ary_fill]);
		ar->ary_array[ar->ary_fill] = Nullstr;
	    }
	}
    }
    retval = (ar->ary_array[key] != Nullstr);
    if (retval && (ar->ary_flags & ARF_REAL))
	str_free(ar->ary_array[key]);
    ar->ary_array[key] = val;
    return retval;
}

ARRAY *
anew(stab)
STAB *stab;
{
    register ARRAY *ar;

    New(1,ar,1,ARRAY);
    Newz(2,ar->ary_alloc,5,STR*);
    ar->ary_array = ar->ary_alloc;
    ar->ary_magic = Str_new(7,0);
    str_magic(ar->ary_magic, stab, '#', Nullch, 0);
    ar->ary_fill = -1;
    ar->ary_index = -1;
    ar->ary_max = 4;
    ar->ary_flags = ARF_REAL;
    return ar;
}

ARRAY *
afake(stab,size,strp)
STAB *stab;
int size;
STR **strp;
{
    register ARRAY *ar;

    New(3,ar,1,ARRAY);
    New(4,ar->ary_alloc,size+1,STR*);
    Copy(strp,ar->ary_alloc,size,STR*);
    ar->ary_array = ar->ary_alloc;
    ar->ary_magic = Str_new(8,0);
    str_magic(ar->ary_magic, stab, '#', Nullch, 0);
    ar->ary_fill = size - 1;
    ar->ary_index = -1;
    ar->ary_max = size - 1;
    ar->ary_flags = 0;
    return ar;
}

void
aclear(ar)
register ARRAY *ar;
{
    register int key;

    if (!ar || !(ar->ary_flags & ARF_REAL))
	return;
    if (key = ar->ary_array - ar->ary_alloc) {
	ar->ary_max += key;
	ar->ary_array -= key;
    }
    for (key = 0; key <= ar->ary_max; key++)
	str_free(ar->ary_array[key]);
    ar->ary_fill = -1;
    Zero(ar->ary_array, ar->ary_max+1, STR*);
}

void
afree(ar)
register ARRAY *ar;
{
    register int key;

    if (!ar)
	return;
    if (key = ar->ary_array - ar->ary_alloc) {
	ar->ary_max += key;
	ar->ary_array -= key;
    }
    if (ar->ary_flags & ARF_REAL) {
	for (key = 0; key <= ar->ary_max; key++)
	    str_free(ar->ary_array[key]);
    }
    str_free(ar->ary_magic);
    Safefree(ar->ary_alloc);
    Safefree(ar);
}

bool
apush(ar,val)
register ARRAY *ar;
STR *val;
{
    return astore(ar,++(ar->ary_fill),val);
}

STR *
apop(ar)
register ARRAY *ar;
{
    STR *retval;

    if (ar->ary_fill < 0)
	return Nullstr;
    retval = ar->ary_array[ar->ary_fill];
    ar->ary_array[ar->ary_fill--] = Nullstr;
    return retval;
}

aunshift(ar,num)
register ARRAY *ar;
register int num;
{
    register int i;
    register STR **sstr,**dstr;

    if (num <= 0)
	return;
    if (ar->ary_array - ar->ary_alloc >= num) {
	ar->ary_max += num;
	ar->ary_fill += num;
	while (num--)
	    *--ar->ary_array = Nullstr;
    }
    else {
	(void)astore(ar,ar->ary_fill+num,(STR*)0);	/* maybe extend array */
	dstr = ar->ary_array + ar->ary_fill;
	sstr = dstr - num;
	for (i = ar->ary_fill; i >= 0; i--) {
	    *dstr-- = *sstr--;
	}
	Zero(ar->ary_array, num, STR*);
    }
}

STR *
ashift(ar)
register ARRAY *ar;
{
    STR *retval;

    if (ar->ary_fill < 0)
	return Nullstr;
    retval = *ar->ary_array;
    *(ar->ary_array++) = Nullstr;
    ar->ary_max--;
    ar->ary_fill--;
    return retval;
}

int
alen(ar)
register ARRAY *ar;
{
    return ar->ary_fill;
}

afill(ar, fill)
register ARRAY *ar;
int fill;
{
    if (fill < 0)
	fill = -1;
    if (fill <= ar->ary_max)
	ar->ary_fill = fill;
    else
	(void)astore(ar,fill,Nullstr);
}
