/*    gv.h
 *
 *    Copyright (c) 1991-1994, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

struct gp {
    SV *	gp_sv;		/* scalar value */
    U32		gp_refcnt;	/* how many globs point to this? */
    struct io *	gp_io;		/* filehandle value */
    CV *	gp_form;	/* format value */
    AV *	gp_av;		/* array value */
    HV *	gp_hv;		/* associative array value */
    GV *	gp_egv;		/* effective gv, if *glob */
    CV *	gp_cv;		/* subroutine value */
    U32		gp_cvgen;	/* generational validity of cached gv_cv */
    I32		gp_lastexpr;	/* used by nothing_in_common() */
    line_t	gp_line;	/* line first declared at (for -w) */
    GV *	gp_filegv;	/* file first declared in (for -w) */
    char	gp_flags;
};

#if defined(CRIPPLED_CC) && (defined(iAPX286) || defined(M_I286) || defined(I80286))
#define MICROPORT
#endif

#define GvXPVGV(gv)	((XPVGV*)SvANY(gv))

#define GvSV(gv)	(GvGP(gv)->gp_sv)
#define GvREFCNT(gv)	(GvGP(gv)->gp_refcnt)
#define GvIO(gv)	((gv) && SvTYPE((SV*)gv) == SVt_PVGV ? GvIOp(gv) : 0)
#define GvIOp(gv)	(GvGP(gv)->gp_io)
#define GvIOn(gv)	(GvIO(gv) ? GvIOp(gv) : GvIOp(gv_IOadd(gv)))

#define GvFORM(gv)	(GvGP(gv)->gp_form)
#define GvAV(gv)	(GvGP(gv)->gp_av)

#ifdef	MICROPORT	/* Microport 2.4 hack */
AV *GvAVn();
#else
#define GvAVn(gv)	(GvGP(gv)->gp_av ? \
			 GvGP(gv)->gp_av : \
			 GvGP(gv_AVadd(gv))->gp_av)
#endif
#define GvHV(gv)	((GvGP(gv))->gp_hv)

#ifdef	MICROPORT	/* Microport 2.4 hack */
HV *GvHVn();
#else
#define GvHVn(gv)	(GvGP(gv)->gp_hv ? \
			 GvGP(gv)->gp_hv : \
			 GvGP(gv_HVadd(gv))->gp_hv)
#endif			/* Microport 2.4 hack */

#define GvCV(gv)	(GvGP(gv)->gp_cv)
#define GvCVGEN(gv)	(GvGP(gv)->gp_cvgen)

#define GvLASTEXPR(gv)	(GvGP(gv)->gp_lastexpr)

#define GvLINE(gv)	(GvGP(gv)->gp_line)
#define GvFILEGV(gv)	(GvGP(gv)->gp_filegv)

#define GvFLAGS(gv)	(GvGP(gv)->gp_flags)

#define GvEGV(gv)	(GvGP(gv)->gp_egv)

#define GvGP(gv)	(GvXPVGV(gv)->xgv_gp)
#define GvNAME(gv)	(GvXPVGV(gv)->xgv_name)
#define GvNAMELEN(gv)	(GvXPVGV(gv)->xgv_namelen)
#define GvENAME(gv)	GvNAME(GvEGV(gv) ? GvEGV(gv) : gv)

#define GvSTASH(gv)	(GvXPVGV(gv)->xgv_stash)
#define GvESTASH(gv)	GvSTASH(GvEGV(gv) ? GvEGV(gv) : gv)

#define Nullgv Null(GV*)

#define DM_UID   0x003
#define DM_RUID   0x001
#define DM_EUID   0x002
#define DM_GID   0x030
#define DM_RGID   0x010
#define DM_EGID   0x020
#define DM_DELAY 0x100

#define GVf_INTRO	0x01
#define GVf_IMPORTED	0x02

#define GV_ADD		0x01
#define GV_ADDMULTI	0x02
#define GV_ADDWARN	0x04
