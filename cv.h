/*    cv.h
 *
 *    Copyright (c) 1991-1994, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

struct xpvcv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xp_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    IV		xof_off;	/* integer value */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    HV *	xcv_stash;
    OP *	xcv_start;
    OP *	xcv_root;
    void      (*xcv_xsub) _((CV*));
    ANY		xcv_xsubany;
    GV *	xcv_gv;
    GV *	xcv_filegv;
    long	xcv_depth;		/* >= 2 indicates recursive call */
    AV *	xcv_padlist;
    CV *	xcv_outside;
    bool	xcv_oldstyle;
};

#define Nullcv Null(CV*)
#define CvSTASH(sv)	((XPVCV*)SvANY(sv))->xcv_stash
#define CvSTART(sv)	((XPVCV*)SvANY(sv))->xcv_start
#define CvROOT(sv)	((XPVCV*)SvANY(sv))->xcv_root
#define CvXSUB(sv)	((XPVCV*)SvANY(sv))->xcv_xsub
#define CvXSUBANY(sv)	((XPVCV*)SvANY(sv))->xcv_xsubany
#define CvGV(sv)	((XPVCV*)SvANY(sv))->xcv_gv
#define CvFILEGV(sv)	((XPVCV*)SvANY(sv))->xcv_filegv
#define CvDEPTH(sv)	((XPVCV*)SvANY(sv))->xcv_depth
#define CvPADLIST(sv)	((XPVCV*)SvANY(sv))->xcv_padlist
#define CvOUTSIDE(sv)	((XPVCV*)SvANY(sv))->xcv_outside
#define CvOLDSTYLE(sv)	((XPVCV*)SvANY(sv))->xcv_oldstyle

