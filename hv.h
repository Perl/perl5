/* $RCSfile: hash.h,v $$Revision: 4.1 $$Date: 92/08/07 18:21:52 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	hash.h,v $
 * Revision 4.1  92/08/07  18:21:52  lwall
 * 
 * Revision 4.0.1.2  91/11/05  17:24:31  lwall
 * patch11: random cleanup
 * 
 * Revision 4.0.1.1  91/06/07  11:10:33  lwall
 * patch4: new copyright notice
 * 
 * Revision 4.0  91/03/20  01:22:38  lwall
 * 4.0 baseline.
 * 
 */

typedef struct he HE;

struct he {
    HE		*hent_next;
    char	*hent_key;
    SV		*hent_val;
    U32		hent_hash;
    I32		hent_klen;
};

struct xpvhv {
    char *	xhv_array;	/* pointer to malloced string */
    STRLEN	xhv_fill;	/* how full xhv_array currently is */
    STRLEN	xhv_max;	/* subscript of last element of xhv_array */
    STRLEN	xhv_keys;	/* how many elements in the array */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    I32		xhv_riter;	/* current root of iterator */
    HE		*xhv_eiter;	/* current entry of iterator */
    PMOP	*xhv_pmroot;	/* list of pm's for this package */
    char	*xhv_name;	/* name, if a symbol table */
};

#define Nullhv Null(HV*)
#define HvARRAY(hv)	((HE**)((XPVHV*)  SvANY(hv))->xhv_array)
#define HvFILL(hv)	((XPVHV*)  SvANY(hv))->xhv_fill
#define HvMAX(hv)	((XPVHV*)  SvANY(hv))->xhv_max
#define HvKEYS(hv)	((XPVHV*)  SvANY(hv))->xhv_keys
#define HvRITER(hv)	((XPVHV*)  SvANY(hv))->xhv_riter
#define HvEITER(hv)	((XPVHV*)  SvANY(hv))->xhv_eiter
#define HvPMROOT(hv)	((XPVHV*)  SvANY(hv))->xhv_pmroot
#define HvNAME(hv)	((XPVHV*)  SvANY(hv))->xhv_name
