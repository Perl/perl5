/* $RCSfile: array.h,v $$Revision: 4.1 $$Date: 92/08/07 17:18:24 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	array.h,v $
 * Revision 4.1  92/08/07  17:18:24  lwall
 * Stage 6 Snapshot
 * 
 * Revision 4.0.1.2  92/06/08  11:45:57  lwall
 * patch20: removed implicit int declarations on funcions
 * 
 * Revision 4.0.1.1  91/06/07  10:19:20  lwall
 * patch4: new copyright notice
 * 
 * Revision 4.0  91/03/20  01:03:44  lwall
 * 4.0 baseline.
 * 
 */

struct xpvav {
    char *	xav_array;	/* pointer to malloced string */
    int		xav_fill;
    int		xav_max;
    int		xof_off;	/* ptr is incremented by offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    SV**	xav_alloc;
    SV*		xav_arylen;
    U8		xav_flags;
};

#define AVf_REAL 1	/* free old entries */

#define Nullav Null(AV*)

#define AvARRAY(av)	((SV**)((XPVAV*)  SvANY(av))->xav_array)
#define AvALLOC(av)	((XPVAV*)  SvANY(av))->xav_alloc
#define AvMAX(av)	((XPVAV*)  SvANY(av))->xav_max
#define AvFILL(av)	((XPVAV*)  SvANY(av))->xav_fill
#define AvARYLEN(av)	((XPVAV*)  SvANY(av))->xav_arylen
#define AvFLAGS(av)	((XPVAV*)  SvANY(av))->xav_flags

#define AvREAL(av)	(((XPVAV*)  SvANY(av))->xav_flags & AVf_REAL)
#define AvREAL_on(av)	(((XPVAV*)  SvANY(av))->xav_flags |= AVf_REAL)
#define AvREAL_off(av)	(((XPVAV*)  SvANY(av))->xav_flags &= ~AVf_REAL)
