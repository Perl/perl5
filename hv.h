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

#define FILLPCT 80		/* don't make greater than 99 */
#define DBM_CACHE_MAX 63	/* cache 64 entries for dbm file */
				/* (resident array acts as a write-thru cache)*/

#define COEFFSIZE (16 * 8)	/* size of coeff array */

typedef struct he HE;

struct he {
    HE		*hent_next;
    char	*hent_key;
    SV		*hent_val;
    I32		hent_hash;
    I32		hent_klen;
};

struct xpvhv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xp_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    STRLEN	xof_off;	/* ptr is incremented by offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    MAGIC*      xhv_magic;	/* magic for elements */

    HE		**xhv_array;
    I32		xhv_max;	/* subscript of last element of xhv_array */
    I32		xhv_dosplit;	/* how full to get before splitting */
    I32		xhv_fill;	/* how full xhv_array currently is */
    I32		xhv_riter;	/* current root of iterator */
    HE		*xhv_eiter;	/* current entry of iterator */
    PMOP	*xhv_pmroot;	/* list of pm's for this package */
    char	*xhv_name;	/* name, if a symbol table */
#ifdef SOME_DBM
#ifdef HAS_GDBM
    GDBM_FILE	xhv_dbm;
#else
#ifdef HAS_NDBM
    DBM		*xhv_dbm;
#else
    I32		xhv_dbm;
#endif
#endif
#endif
    unsigned char xhv_coeffsize; /* is 0 for symbol tables */
};

#define Nullhv Null(HV*)
#define HvMAGIC(hv)	((XPVHV*)  SvANY(hv))->xhv_magic
#define HvARRAY(hv)	((XPVHV*)  SvANY(hv))->xhv_array
#define HvMAX(hv)	((XPVHV*)  SvANY(hv))->xhv_max
#define HvDOSPLIT(hv)	((XPVHV*)  SvANY(hv))->xhv_dosplit
#define HvFILL(hv)	((XPVHV*)  SvANY(hv))->xhv_fill
#define HvRITER(hv)	((XPVHV*)  SvANY(hv))->xhv_riter
#define HvEITER(hv)	((XPVHV*)  SvANY(hv))->xhv_eiter
#define HvPMROOT(hv)	((XPVHV*)  SvANY(hv))->xhv_pmroot
#define HvNAME(hv)	((XPVHV*)  SvANY(hv))->xhv_name
#define HvDBM(hv)	((XPVHV*)  SvANY(hv))->xhv_dbm
#define HvCOEFFSIZE(hv)	((XPVHV*)  SvANY(hv))->xhv_coeffsize
