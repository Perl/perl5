/* $RCSfile: cv.h,v $$Revision: 4.1 $$Date: 92/08/07 18:26:42 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:        cv.h,v $
 */

struct xpvcv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xp_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    STRLEN	xof_off;	/* ptr is incremented by offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    HV *	xcv_stash;
    OP *	xcv_start;
    OP *	xcv_root;
    I32	      (*xcv_usersub)();
    I32		xcv_userindex;
    GV *	xcv_gv;
    GV *	xcv_filegv;
    long	xcv_depth;		/* >= 2 indicates recursive call */
    AV *	xcv_padlist;
    bool	xcv_deleted;
};
#define Nullcv Null(CV*)
#define CvSTASH(sv)	((XPVCV*)SvANY(sv))->xcv_stash
#define CvSTART(sv)	((XPVCV*)SvANY(sv))->xcv_start
#define CvROOT(sv)	((XPVCV*)SvANY(sv))->xcv_root
#define CvUSERSUB(sv)	((XPVCV*)SvANY(sv))->xcv_usersub
#define CvUSERINDEX(sv)	((XPVCV*)SvANY(sv))->xcv_userindex
#define CvGV(sv)	((XPVCV*)SvANY(sv))->xcv_gv
#define CvFILEGV(sv)	((XPVCV*)SvANY(sv))->xcv_filegv
#define CvDEPTH(sv)	((XPVCV*)SvANY(sv))->xcv_depth
#define CvPADLIST(sv)	((XPVCV*)SvANY(sv))->xcv_padlist
#define CvDELETED(sv)	((XPVCV*)SvANY(sv))->xcv_deleted

