/* $RCSfile: sv.h,v $$Revision: 4.1 $$Date: 92/08/07 18:26:57 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	sv.h,v $
 * Revision 4.1  92/08/07  18:26:57  lwall
 * 
 * Revision 4.0.1.4  92/06/08  15:41:45  lwall
 * patch20: fixed confusion between a *var's real name and its effective name
 * patch20: removed implicit int declarations on functions
 * 
 * Revision 4.0.1.3  91/11/05  18:41:47  lwall
 * patch11: random cleanup
 * patch11: solitary subroutine references no longer trigger typo warnings
 * 
 * Revision 4.0.1.2  91/06/07  11:58:33  lwall
 * patch4: new copyright notice
 * 
 * Revision 4.0.1.1  91/04/12  09:16:12  lwall
 * patch1: you may now use "die" and "caller" in a signal handler
 * 
 * Revision 4.0  91/03/20  01:40:04  lwall
 * 4.0 baseline.
 * 
 */

typedef enum {
	SVt_NULL,
	SVt_IV,
	SVt_NV,
	SVt_RV,
	SVt_PV,
	SVt_PVIV,
	SVt_PVNV,
	SVt_PVMG,
	SVt_PVBM,
	SVt_PVLV,
	SVt_PVAV,
	SVt_PVHV,
	SVt_PVCV,
	SVt_PVGV,
	SVt_PVFM,
	SVt_PVIO
} svtype;

/* Using C's structural equivalence to help emulate C++ inheritance here... */

struct sv {
    void*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    U32		sv_flags;	/* what we are */
};

struct gv {
    XPVGV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    U32		sv_flags;	/* what we are */
};

struct cv {
    XPVGV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    U32		sv_flags;	/* what we are */
};

struct av {
    XPVAV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    U32		sv_flags;	/* what we are */
};

struct hv {
    XPVHV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    U32		sv_flags;	/* what we are */
};

struct io {
    XPVIO*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    U32		sv_flags;	/* what we are */
};

#define SvANY(sv)	(sv)->sv_any
#define SvFLAGS(sv)	(sv)->sv_flags

#define SvREFCNT(sv)	(sv)->sv_refcnt
#ifdef CRIPPLED_CC
#define SvREFCNT_inc(sv)	sv_newref((SV*)sv)
#define SvREFCNT_dec(sv)	sv_free((SV*)sv)
#else
#define SvREFCNT_inc(sv)	((Sv = (SV*)(sv)), \
				    (Sv && ++SvREFCNT(Sv)), (SV*)Sv)
#define SvREFCNT_dec(sv)	sv_free((SV*)sv)
#endif

#define SVTYPEMASK	0xff
#define SvTYPE(sv)	((sv)->sv_flags & SVTYPEMASK)

#define SvUPGRADE(sv, mt) (SvTYPE(sv) >= mt || sv_upgrade(sv, mt))

#define SVs_PADBUSY	0x00000100	/* reserved for tmp or my already */
#define SVs_PADTMP	0x00000200	/* in use as tmp */
#define SVs_PADMY	0x00000400	/* in use a "my" variable */
#define SVs_TEMP	0x00000800	/* string is stealable? */
#define SVs_OBJECT	0x00001000	/* is "blessed" */
#define SVs_GMG		0x00002000	/* has magical get method */
#define SVs_SMG		0x00004000	/* has magical set method */
#define SVs_RMG		0x00008000	/* has random magical methods */

#define SVf_IOK		0x00010000	/* has valid public integer value */
#define SVf_NOK		0x00020000	/* has valid public numeric value */
#define SVf_POK		0x00040000	/* has valid public pointer value */
#define SVf_ROK		0x00080000	/* has a valid reference pointer */
#define SVf_OK		0x00100000	/* has defined value */
#define SVf_OOK		0x00200000	/* has valid offset value */
#define SVf_BREAK	0x00400000	/* refcnt is artificially low */
#define SVf_READONLY	0x00800000	/* may not be modified */

#define SVp_IOK		0x01000000	/* has valid non-public integer value */
#define SVp_NOK		0x02000000	/* has valid non-public numeric value */
#define SVp_POK		0x04000000	/* has valid non-public pointer value */
#define SVp_SCREAM	0x08000000	/* has been studied? */

#define PRIVSHIFT 8

/* Some private flags. */

#define SVpfm_COMPILED	0x80000000

#define SVpbm_VALID	0x80000000
#define SVpbm_CASEFOLD	0x40000000
#define SVpbm_TAIL	0x20000000

#define SVpgv_MULTI	0x80000000

struct xrv {
    SV *	xrv_rv;		/* pointer to another SV */
};

struct xpv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
};

struct xpviv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
};

struct xpvnv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
};

struct xpvmg {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */
};

struct xpvlv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */

    STRLEN	xlv_targoff;
    STRLEN	xlv_targlen;
    SV*		xlv_targ;
    char	xlv_type;
};

struct xpvgv {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */

    GP*		xgv_gp;
    char*	xgv_name;
    STRLEN	xgv_namelen;
    HV*		xgv_stash;
};

struct xpvbm {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */

    I32		xbm_useful;	/* is this constant pattern being useful? */
    U16		xbm_previous;	/* how many characters in string before rare? */
    U8		xbm_rare;	/* rarest character in string */
};

struct xpvfm {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */

    HV *	xcv_stash;
    OP *	xcv_start;
    OP *	xcv_root;
    I32	      (*xcv_usersub)();
    I32		xcv_userindex;
    GV *	xcv_filegv;
    long	xcv_depth;		/* >= 2 indicates recursive call */
    AV *	xcv_padlist;
    bool	xcv_deleted;
    I32		xfm_lines;
};

struct xpvio {
    char *	xpv_pv;		/* pointer to malloced string */
    STRLEN	xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN	xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */

    FILE *	xio_ifp;	/* ifp and ofp are normally the same */
    FILE *	xio_ofp;	/* but sockets need separate streams */
    DIR *	xio_dirp;	/* for opendir, readdir, etc */
    long	xio_lines;	/* $. */
    long	xio_page;	/* $% */
    long	xio_page_len;	/* $= */
    long	xio_lines_left;	/* $- */
    char *	xio_top_name;	/* $^ */
    GV *	xio_top_gv;	/* $^ */
    char *	xio_fmt_name;	/* $~ */
    GV *	xio_fmt_gv;	/* $~ */
    char *	xio_bottom_name;/* $^B */
    GV *	xio_bottom_gv;	/* $^B */
    short	xio_subprocess;	/* -| or |- */
    char	xio_type;
    char	xio_flags;
};

#define IOf_ARGV 1	/* this fp iterates over ARGV */
#define IOf_START 2	/* check for null ARGV and substitute '-' */
#define IOf_FLUSH 4	/* this fp wants a flush after write op */

/* The following macros define implementation-independent predicates on SVs. */

#define SvNIOK(sv)		(SvFLAGS(sv) & (SVf_IOK|SVf_NOK))

#define SvOK(sv)		(SvFLAGS(sv) & SVf_OK)
#define SvOK_on(sv)		(SvFLAGS(sv) |= SVf_OK)
#define SvOK_off(sv)		(SvFLAGS(sv) &=				   \
					~(SVf_IOK|SVf_NOK|SVf_POK|SVf_OK|  \
					  SVp_IOK|SVp_NOK|SVp_POK|SVf_ROK),\
					SvOOK_off(sv))

#define SvOKp(sv)		(SvFLAGS(sv) & (SVp_IOK|SVp_NOK|SVp_POK))
#define SvIOKp(sv)		(SvFLAGS(sv) & SVp_IOK)
#define SvIOKp_on(sv)		(SvOOK_off(sv), SvFLAGS(sv) |= SVp_IOK)
#define SvNOKp(sv)		(SvFLAGS(sv) & SVp_NOK)
#define SvNOKp_on(sv)		(SvFLAGS(sv) |= SVp_NOK)
#define SvPOKp(sv)		(SvFLAGS(sv) & SVp_POK)
#define SvPOKp_on(sv)		(SvFLAGS(sv) |= SVp_POK)

#define SvIOK(sv)		(SvFLAGS(sv) & SVf_IOK)
#define SvIOK_on(sv)		(SvOOK_off(sv), \
				    SvFLAGS(sv) |= (SVf_IOK|SVp_IOK|SVf_OK))
#define SvIOK_off(sv)		(SvFLAGS(sv) &= ~(SVf_IOK|SVp_IOK))
#define SvIOK_only(sv)		(SvOK_off(sv), \
				    SvFLAGS(sv) |= (SVf_IOK|SVp_IOK|SVf_OK))

#define SvNOK(sv)		(SvFLAGS(sv) & SVf_NOK)
#define SvNOK_on(sv)		(SvFLAGS(sv) |= (SVf_NOK|SVp_NOK|SVf_OK))
#define SvNOK_off(sv)		(SvFLAGS(sv) &= ~(SVf_NOK|SVp_NOK))
#define SvNOK_only(sv)		(SvOK_off(sv), \
				    SvFLAGS(sv) |= (SVf_NOK|SVp_NOK|SVf_OK))

#define SvPOK(sv)		(SvFLAGS(sv) & SVf_POK)
#define SvPOK_on(sv)		(SvFLAGS(sv) |= (SVf_POK|SVp_POK|SVf_OK))
#define SvPOK_off(sv)		(SvFLAGS(sv) &= ~(SVf_POK|SVp_POK))
#define SvPOK_only(sv)		(SvOK_off(sv), \
				    SvFLAGS(sv) |= (SVf_POK|SVp_POK|SVf_OK))

#define SvOOK(sv)		(SvFLAGS(sv) & SVf_OOK)
#define SvOOK_on(sv)		(SvIOK_off(sv), SvFLAGS(sv) |= SVf_OOK)
#define SvOOK_off(sv)		(SvOOK(sv) && sv_backoff(sv))

#define SvROK(sv)		(SvFLAGS(sv) & SVf_ROK)
#define SvROK_on(sv)		(SvFLAGS(sv) |= SVf_ROK|SVf_OK)
#define SvROK_off(sv)		(SvFLAGS(sv) &= ~SVf_ROK)

#define SvMAGICAL(sv)		(SvFLAGS(sv) & (SVs_GMG|SVs_SMG|SVs_RMG))
#define SvMAGICAL_on(sv)	(SvFLAGS(sv) |= (SVs_GMG|SVs_SMG|SVs_RMG))
#define SvMAGICAL_off(sv)	(SvFLAGS(sv) &= ~(SVs_GMG|SVs_SMG|SVs_RMG))

#define SvGMAGICAL(sv)		(SvFLAGS(sv) & SVs_GMG)
#define SvGMAGICAL_on(sv)	(SvFLAGS(sv) |= SVs_GMG)
#define SvGMAGICAL_off(sv)	(SvFLAGS(sv) &= ~SVs_GMG)

#define SvSMAGICAL(sv)		(SvFLAGS(sv) & SVs_SMG)
#define SvSMAGICAL_on(sv)	(SvFLAGS(sv) |= SVs_SMG)
#define SvSMAGICAL_off(sv)	(SvFLAGS(sv) &= ~SVs_SMG)

#define SvRMAGICAL(sv)		(SvFLAGS(sv) & SVs_RMG)
#define SvRMAGICAL_on(sv)	(SvFLAGS(sv) |= SVs_RMG)
#define SvRMAGICAL_off(sv)	(SvFLAGS(sv) &= ~SVs_RMG)

#define SvTHINKFIRST(sv)	(SvFLAGS(sv) & (SVf_ROK|SVf_READONLY))

#define SvPADBUSY(sv)		(SvFLAGS(sv) & SVs_PADBUSY)

#define SvPADTMP(sv)		(SvFLAGS(sv) & SVs_PADTMP)
#define SvPADTMP_on(sv)		(SvFLAGS(sv) |= SVs_PADTMP|SVs_PADBUSY)
#define SvPADTMP_off(sv)	(SvFLAGS(sv) &= ~SVs_PADTMP)

#define SvPADMY(sv)		(SvFLAGS(sv) & SVs_PADMY)
#define SvPADMY_on(sv)		(SvFLAGS(sv) |= SVs_PADMY|SVs_PADBUSY)

#define SvTEMP(sv)		(SvFLAGS(sv) & SVs_TEMP)
#define SvTEMP_on(sv)		(SvFLAGS(sv) |= SVs_TEMP)
#define SvTEMP_off(sv)		(SvFLAGS(sv) &= ~SVs_TEMP)

#define SvOBJECT(sv)		(SvFLAGS(sv) & SVs_OBJECT)
#define SvOBJECT_on(sv)		(SvFLAGS(sv) |= SVs_OBJECT)
#define SvOBJECT_off(sv)	(SvFLAGS(sv) &= ~SVs_OBJECT)

#define SvREADONLY(sv)		(SvFLAGS(sv) & SVf_READONLY)
#define SvREADONLY_on(sv)	(SvFLAGS(sv) |= SVf_READONLY)
#define SvREADONLY_off(sv)	(SvFLAGS(sv) &= ~SVf_READONLY)

#define SvSCREAM(sv)		(SvFLAGS(sv) & SVp_SCREAM)
#define SvSCREAM_on(sv)		(SvFLAGS(sv) |= SVp_SCREAM)
#define SvSCREAM_off(sv)	(SvFLAGS(sv) &= ~SVp_SCREAM)

#define SvCOMPILED(sv)		(SvFLAGS(sv) & SVpfm_COMPILED)
#define SvCOMPILED_on(sv)	(SvFLAGS(sv) |= SVpfm_COMPILED)
#define SvCOMPILED_off(sv)	(SvFLAGS(sv) &= ~SVpfm_COMPILED)

#define SvTAIL(sv)		(SvFLAGS(sv) & SVpbm_TAIL)
#define SvTAIL_on(sv)		(SvFLAGS(sv) |= SVpbm_TAIL)
#define SvTAIL_off(sv)		(SvFLAGS(sv) &= ~SVpbm_TAIL)

#define SvCASEFOLD(sv)		(SvFLAGS(sv) & SVpbm_CASEFOLD)
#define SvCASEFOLD_on(sv)	(SvFLAGS(sv) |= SVpbm_CASEFOLD)
#define SvCASEFOLD_off(sv)	(SvFLAGS(sv) &= ~SVpbm_CASEFOLD)

#define SvVALID(sv)		(SvFLAGS(sv) & SVpbm_VALID)
#define SvVALID_on(sv)		(SvFLAGS(sv) |= SVpbm_VALID)
#define SvVALID_off(sv)		(SvFLAGS(sv) &= ~SVpbm_VALID)

#define SvMULTI(sv)		(SvFLAGS(sv) & SVpgv_MULTI)
#define SvMULTI_on(sv)		(SvFLAGS(sv) |= SVpgv_MULTI)
#define SvMULTI_off(sv)		(SvFLAGS(sv) &= ~SVpgv_MULTI)

#define SvRV(sv) ((XRV*)  SvANY(sv))->xrv_rv
#define SvRVx(sv) SvRV(sv)

#define SvIVX(sv) ((XPVIV*)  SvANY(sv))->xiv_iv
#define SvIVXx(sv) SvIVX(sv)
#define SvNVX(sv)  ((XPVNV*)SvANY(sv))->xnv_nv
#define SvNVXx(sv) SvNVX(sv)
#define SvPVX(sv)  ((XPV*)  SvANY(sv))->xpv_pv
#define SvPVXx(sv) SvPVX(sv)
#define SvCUR(sv) ((XPV*)  SvANY(sv))->xpv_cur
#define SvLEN(sv) ((XPV*)  SvANY(sv))->xpv_len
#define SvLENx(sv) SvLEN(sv)
#define SvEND(sv)(((XPV*)  SvANY(sv))->xpv_pv + ((XPV*)SvANY(sv))->xpv_cur)
#define SvENDx(sv) ((Sv = (sv)), SvEND(Sv))
#define SvMAGIC(sv)	((XPVMG*)  SvANY(sv))->xmg_magic
#define SvSTASH(sv)	((XPVMG*)  SvANY(sv))->xmg_stash

#define SvIV_set(sv, val) \
	do { assert(SvTYPE(sv) == SVt_IV || SvTYPE(sv) >= SVt_PVIV); \
		(((XPVIV*)  SvANY(sv))->xiv_iv = val); } while (0)
#define SvNV_set(sv, val) \
	do { assert(SvTYPE(sv) == SVt_NV || SvTYPE(sv) >= SVt_PVNV); \
		(((XPVNV*)  SvANY(sv))->xnv_nv = val); } while (0)
#define SvPV_set(sv, val) \
	do { assert(SvTYPE(sv) >= SVt_PV); \
		(((XPV*)  SvANY(sv))->xpv_pv = val); } while (0)
#define SvCUR_set(sv, val) \
	do { assert(SvTYPE(sv) >= SVt_PV); \
		(((XPV*)  SvANY(sv))->xpv_cur = val); } while (0)
#define SvLEN_set(sv, val) \
	do { assert(SvTYPE(sv) >= SVt_PV); \
		(((XPV*)  SvANY(sv))->xpv_len = val); } while (0)
#define SvEND_set(sv, val) \
	do { assert(SvTYPE(sv) >= SVt_PV); \
		(((XPV*)  SvANY(sv))->xpv_cur = val - SvPVX(sv)); } while (0)

#define BmRARE(sv)	((XPVBM*)  SvANY(sv))->xbm_rare
#define BmUSEFUL(sv)	((XPVBM*)  SvANY(sv))->xbm_useful
#define BmPREVIOUS(sv)	((XPVBM*)  SvANY(sv))->xbm_previous

#define FmLINES(sv)	((XPVFM*)  SvANY(sv))->xfm_lines

#define LvTYPE(sv)	((XPVLV*)  SvANY(sv))->xlv_type
#define LvTARG(sv)	((XPVLV*)  SvANY(sv))->xlv_targ
#define LvTARGOFF(sv)	((XPVLV*)  SvANY(sv))->xlv_targoff
#define LvTARGLEN(sv)	((XPVLV*)  SvANY(sv))->xlv_targlen

#define IoIFP(sv)	((XPVIO*)  SvANY(sv))->xio_ifp
#define IoOFP(sv)	((XPVIO*)  SvANY(sv))->xio_ofp
#define IoDIRP(sv)	((XPVIO*)  SvANY(sv))->xio_dirp
#define IoLINES(sv)	((XPVIO*)  SvANY(sv))->xio_lines
#define IoPAGE(sv)	((XPVIO*)  SvANY(sv))->xio_page
#define IoPAGE_LEN(sv)	((XPVIO*)  SvANY(sv))->xio_page_len
#define IoLINES_LEFT(sv)((XPVIO*)  SvANY(sv))->xio_lines_left
#define IoTOP_NAME(sv)	((XPVIO*)  SvANY(sv))->xio_top_name
#define IoTOP_GV(sv)	((XPVIO*)  SvANY(sv))->xio_top_gv
#define IoFMT_NAME(sv)	((XPVIO*)  SvANY(sv))->xio_fmt_name
#define IoFMT_GV(sv)	((XPVIO*)  SvANY(sv))->xio_fmt_gv
#define IoBOTTOM_NAME(sv)((XPVIO*) SvANY(sv))->xio_bottom_name
#define IoBOTTOM_GV(sv)	((XPVIO*)  SvANY(sv))->xio_bottom_gv
#define IoSUBPROCESS(sv)((XPVIO*)  SvANY(sv))->xio_subprocess
#define IoTYPE(sv)	((XPVIO*)  SvANY(sv))->xio_type
#define IoFLAGS(sv)	((XPVIO*)  SvANY(sv))->xio_flags

#define SvTAINT(sv) if (tainting && tainted) sv_magic(sv, 0, 't', 0, 0)

#ifdef CRIPPLED_CC

I32 SvIV();
double SvNV();
#define SvPV(sv, lp) sv_pvn(sv, &lp)
char *sv_pvn();
I32 SvTRUE();

#define SvIVx(sv) SvIV(sv)
#define SvNVx(sv) SvNV(sv)
#define SvPVx(sv, lp) sv_pvn(sv, &lp)
#define SvTRUEx(sv) SvTRUE(sv)

#else /* !CRIPPLED_CC */

#define SvIV(sv) (SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv))

#define SvNV(sv) (SvNOK(sv) ? SvNVX(sv) : sv_2nv(sv))

#define SvPV(sv, lp) (SvPOK(sv) ? ((lp = SvCUR(sv)), SvPVX(sv)) : sv_2pv(sv, &lp))

#define SvTRUE(sv) (						\
    !sv								\
    ? 0								\
    :    SvPOK(sv)						\
	?   ((Xpv = (XPV*)SvANY(sv)) &&				\
	     (*Xpv->xpv_pv > '0' ||				\
	      Xpv->xpv_cur > 1 ||				\
	      (Xpv->xpv_cur && *Xpv->xpv_pv != '0'))		\
	     ? 1						\
	     : 0)						\
	:							\
	    SvIOK(sv)						\
	    ? SvIVX(sv) != 0					\
	    :   SvNOK(sv)					\
		? SvNVX(sv) != 0.0				\
		: sv_2bool(sv) )

#define SvIVx(sv) ((Sv = (sv)), SvIV(Sv))
#define SvNVx(sv) ((Sv = (sv)), SvNV(Sv))
#define SvPVx(sv, lp) ((Sv = (sv)), SvPV(Sv, lp))
#define SvTRUEx(sv) ((Sv = (sv)), SvTRUE(Sv))

#endif /* CRIPPLED_CC */

/* the following macro updates any magic values this sv is associated with */

#define SvSETMAGIC(x) if (SvSMAGICAL(x)) mg_set(x)

#define SvSetSV(dst,src) if (dst != src) sv_setsv(dst,src)

#define SvPEEK(sv) sv_peek(sv)

#define isGV(sv) (SvTYPE(sv) == SVt_PVGV)

#ifndef DOSISH
#  define SvGROW(sv,len) if (SvLEN(sv) < (len)) sv_grow(sv,len)
#  define Sv_Grow sv_grow
#else
    /* extra parentheses intentionally NOT placed around "len"! */
#  define SvGROW(sv,len) if (SvLEN(sv) < (unsigned long)len) \
		sv_grow(sv,(unsigned long)len)
#  define Sv_Grow(sv,len) sv_grow(sv,(unsigned long)(len))
#endif /* DOSISH */
