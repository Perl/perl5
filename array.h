/* $Header: array.h,v 3.0 89/10/18 15:08:41 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	array.h,v $
 * Revision 3.0  89/10/18  15:08:41  lwall
 * 3.0 baseline
 * 
 */

struct atbl {
    STR	**ary_array;
    STR **ary_alloc;
    STR *ary_magic;
    int ary_max;
    int ary_fill;
    int ary_index;
    char ary_flags;
};

#define ARF_REAL 1	/* free old entries */

STR *afetch();
bool astore();
STR *apop();
STR *ashift();
void afree();
void aclear();
bool apush();
int alen();
ARRAY *anew();
ARRAY *afake();
