/* $Header: array.h,v 2.0 88/06/05 00:08:21 root Exp $
 *
 * $Log:	array.h,v $
 * Revision 2.0  88/06/05  00:08:21  root
 * Baseline version 2.0.
 * 
 */

struct atbl {
    STR	**ary_array;
    STR *ary_magic;
    int ary_max;
    int ary_fill;
    int ary_index;
};

STR *afetch();
bool astore();
bool adelete();
STR *apop();
STR *ashift();
void afree();
void aclear();
bool apush();
int alen();
ARRAY *anew();
