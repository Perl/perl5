/* $Header: array.c,v 1.0 87/12/18 13:04:42 root Exp $
 *
 * $Log:	array.c,v $
 * Revision 1.0  87/12/18  13:04:42  root
 * Initial revision
 * 
 */

#include <stdio.h>
#include "EXTERN.h"
#include "handy.h"
#include "util.h"
#include "search.h"
#include "perl.h"

STR *
afetch(ar,key)
register ARRAY *ar;
int key;
{
    if (key < 0 || key > ar->ary_max)
	return Nullstr;
    return ar->ary_array[key];
}

bool
astore(ar,key,val)
register ARRAY *ar;
int key;
STR *val;
{
    bool retval;

    if (key < 0)
	return FALSE;
    if (key > ar->ary_max) {
	int newmax = key + ar->ary_max;

	ar->ary_array = (STR**)saferealloc((char*)ar->ary_array,
	    (newmax+1) * sizeof(STR*));
	bzero((char*)&ar->ary_array[ar->ary_max+1],
	    (newmax - ar->ary_max) * sizeof(STR*));
	ar->ary_max = newmax;
    }
    if (key > ar->ary_fill)
	ar->ary_fill = key;
    retval = (ar->ary_array[key] != Nullstr);
    if (retval)
	str_free(ar->ary_array[key]);
    ar->ary_array[key] = val;
    return retval;
}

bool
adelete(ar,key)
register ARRAY *ar;
int key;
{
    if (key < 0 || key > ar->ary_max)
	return FALSE;
    if (ar->ary_array[key]) {
	str_free(ar->ary_array[key]);
	ar->ary_array[key] = Nullstr;
	return TRUE;
    }
    return FALSE;
}

ARRAY *
anew()
{
    register ARRAY *ar = (ARRAY*)safemalloc(sizeof(ARRAY));

    ar->ary_array = (STR**) safemalloc(5 * sizeof(STR*));
    ar->ary_fill = -1;
    ar->ary_max = 4;
    bzero((char*)ar->ary_array, 5 * sizeof(STR*));
    return ar;
}

void
afree(ar)
register ARRAY *ar;
{
    register int key;

    if (!ar)
	return;
    for (key = 0; key <= ar->ary_fill; key++)
	str_free(ar->ary_array[key]);
    safefree((char*)ar->ary_array);
    safefree((char*)ar);
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
    astore(ar,ar->ary_fill+num,(STR*)0);	/* maybe extend array */
    sstr = ar->ary_array + ar->ary_fill;
    dstr = sstr + num;
    for (i = ar->ary_fill; i >= 0; i--) {
	*dstr-- = *sstr--;
    }
    bzero((char*)(ar->ary_array), num * sizeof(STR*));
}

STR *
ashift(ar)
register ARRAY *ar;
{
    STR *retval;

    if (ar->ary_fill < 0)
	return Nullstr;
    retval = ar->ary_array[0];
    bcopy((char*)(ar->ary_array+1),(char*)ar->ary_array,
      ar->ary_fill * sizeof(STR*));
    ar->ary_array[ar->ary_fill--] = Nullstr;
    return retval;
}

long
alen(ar)
register ARRAY *ar;
{
    return (long)ar->ary_fill;
}

void
ajoin(ar,delim,str)
register ARRAY *ar;
char *delim;
register STR *str;
{
    register int i;
    register int len;
    register int dlen;

    if (ar->ary_fill < 0) {
	str_set(str,"");
	STABSET(str);
	return;
    }
    dlen = strlen(delim);
    len = ar->ary_fill * dlen;		/* account for delimiters */
    for (i = ar->ary_fill; i >= 0; i--)
	len += str_len(ar->ary_array[i]);
    str_grow(str,len);			/* preallocate for efficiency */
    str_sset(str,ar->ary_array[0]);
    for (i = 1; i <= ar->ary_fill; i++) {
	str_ncat(str,delim,dlen);
	str_scat(str,ar->ary_array[i]);
    }
    STABSET(str);
}
