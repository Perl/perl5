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
	SVt_REF,
	SVt_IV,
	SVt_NV,
	SVt_PV,
	SVt_PVIV,
	SVt_PVNV,
	SVt_PVMG,
	SVt_PVLV,
	SVt_PVAV,
	SVt_PVHV,
	SVt_PVCV,
	SVt_PVGV,
	SVt_PVBM,
	SVt_PVFM,
} svtype;

/* Compensate for ANSI C misdesign... */
#ifdef DEBUGGING
#define SVTYPE svtype
#else
#define SVTYPE U8
#endif

/* Using C's structural equivalence to help emulate C++ inheritance here... */

struct sv {
    void*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct gv {
    XPVGV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct cv {
    XPVGV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct av {
    XPVAV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct hv {
    XPVHV*	sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

#define SvANY(sv)	(sv)->sv_any
#define SvTYPE(sv)	(sv)->sv_type
#define SvREFCNT(sv)	(sv)->sv_refcnt
#define SvFLAGS(sv)	(sv)->sv_flags
#define SvSTORAGE(sv)	(sv)->sv_storage
#define SvPRIVATE(sv)	(sv)->sv_private

#define SvUPGRADE(sv, mt) (SvTYPE(sv) >= mt || sv_upgrade(sv, mt))

#define SVf_IOK		1		/* has valid integer value */
#define SVf_NOK		2		/* has valid numeric value */
#define SVf_POK		4		/* has valid pointer value */
#define SVf_OOK		8		/* has valid offset value */
#define SVf_MAGICAL	16		/* has special methods */
#define SVf_OK		32		/* has defined value */
#define SVf_TEMP	64		/* eventually in sv_private? */
#define SVf_READONLY	128		/* may not be modified */

#define SVp_IOK		1		/* has valid non-public integer value */
#define SVp_NOK		2		/* has valid non-public numeric value */
#define SVp_POK		4		/* has valid non-public pointer value */
#define SVp_SCREAM	8		/* has been studied? */
#define SVp_TAINTEDDIR	16		/* PATH component is a security risk */

#define SVpfm_COMPILED	128

#define SVpbm_VALID	128
#define SVpbm_CASEFOLD	64
#define SVpbm_TAIL	32

#define SVpgv_MULTI	128

struct xpv {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
};

struct xpviv {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
};

struct xpvnv {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double      xnv_nv;		/* numeric value, if any */
};

struct xpvmg {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double      xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */
};

struct xpvlv {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double      xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */
    STRLEN	xlv_targoff;
    STRLEN	xlv_targlen;
    SV*		xlv_targ;
    char	xlv_type;
};

struct xpvgv {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double      xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */
    GP*		xgv_gp;
    char*	xgv_name;
    STRLEN	xgv_namelen;
    HV*		xgv_stash;
};

struct xpvbm {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double      xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* linked list of magicalness */
    HV*		xmg_stash;	/* class package */
    I32		xbm_useful;	/* is this constant pattern being useful? */
    U16		xbm_previous;	/* how many characters in string before rare? */
    U8		xbm_rare;	/* rarest character in string */
};

struct xpvfm {
    char *      xpv_pv;		/* pointer to malloced string */
    STRLEN      xpv_cur;	/* length of xpv_pv as a C string */
    STRLEN      xpv_len;	/* allocated size */
    I32		xiv_iv;		/* integer value or pv offset */
    double      xnv_nv;		/* numeric value, if any */
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

#define SvNIOK(sv)		(SvFLAGS(sv) & (SVf_IOK|SVf_NOK))

#define SvOK(sv)		(SvFLAGS(sv) & SVf_OK)
#define SvOK_on(sv)		(SvFLAGS(sv) |= SVf_OK)
#define SvOK_off(sv)		(SvFLAGS(sv) &=				   \
					~(SVf_IOK|SVf_NOK|SVf_POK|SVf_OK), \
					SvOOK_off(sv))

#define SvOKp(sv)		(SvPRIVATE(sv) & (SVp_IOK|SVp_NOK|SVp_POK))
#define SvIOKp(sv)		(SvPRIVATE(sv) & SVp_IOK)
#define SvIOKp_on(sv)		(SvOOK_off(sv), SvPRIVATE(sv) |= SVp_IOK)
#define SvNOKp(sv)		(SvPRIVATE(sv) & SVp_NOK)
#define SvNOKp_on(sv)		(SvPRIVATE(sv) |= SVp_NOK)
#define SvPOKp(sv)		(SvPRIVATE(sv) & SVp_POK)
#define SvPOKp_on(sv)		(SvPRIVATE(sv) |= SVp_POK)

#define SvIOK(sv)		(SvFLAGS(sv) & SVf_IOK)
#define SvIOK_on(sv)		(SvOOK_off(sv), SvFLAGS(sv) |= (SVf_IOK|SVf_OK))
#define SvIOK_off(sv)		(SvFLAGS(sv) &= ~SVf_IOK)
#define SvIOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= (SVf_IOK|SVf_OK))

#define SvNOK(sv)		(SvFLAGS(sv) & SVf_NOK)
#define SvNOK_on(sv)		(SvFLAGS(sv) |= (SVf_NOK|SVf_OK))
#define SvNOK_off(sv)		(SvFLAGS(sv) &= ~SVf_NOK)
#define SvNOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= (SVf_NOK|SVf_OK))

#define SvPOK(sv)		(SvFLAGS(sv) & SVf_POK)
#define SvPOK_on(sv)		(SvFLAGS(sv) |= (SVf_POK|SVf_OK))
#define SvPOK_off(sv)		(SvFLAGS(sv) &= ~SVf_POK)
#define SvPOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= (SVf_POK|SVf_OK))

#define SvOOK(sv)		(SvFLAGS(sv) & SVf_OOK)
#define SvOOK_on(sv)		(SvIOK_off(sv), SvFLAGS(sv) |= SVf_OOK)
#define SvOOK_off(sv)		(SvOOK(sv) && sv_backoff(sv))

#define SvREADONLY(sv)		(SvFLAGS(sv) & SVf_READONLY)
#define SvREADONLY_on(sv)	(SvFLAGS(sv) |= SVf_READONLY)
#define SvREADONLY_off(sv)	(SvFLAGS(sv) &= ~SVf_READONLY)

#define SvMAGICAL(sv)		(SvFLAGS(sv) & SVf_MAGICAL)
#define SvMAGICAL_on(sv)	(SvFLAGS(sv) |= SVf_MAGICAL)
#define SvMAGICAL_off(sv)	(SvFLAGS(sv) &= ~SVf_MAGICAL)

#define SvSCREAM(sv)		(SvPRIVATE(sv) & SVp_SCREAM)
#define SvSCREAM_on(sv)		(SvPRIVATE(sv) |= SVp_SCREAM)
#define SvSCREAM_off(sv)	(SvPRIVATE(sv) &= ~SVp_SCREAM)

#define SvTEMP(sv)		(SvFLAGS(sv) & SVf_TEMP)
#define SvTEMP_on(sv)		(SvFLAGS(sv) |= SVf_TEMP)
#define SvTEMP_off(sv)		(SvFLAGS(sv) &= ~SVf_TEMP)

#define SvCOMPILED(sv)		(SvPRIVATE(sv) & SVpfm_COMPILED)
#define SvCOMPILED_on(sv)	(SvPRIVATE(sv) |= SVpfm_COMPILED)
#define SvCOMPILED_off(sv)	(SvPRIVATE(sv) &= ~SVpfm_COMPILED)

#define SvTAIL(sv)		(SvPRIVATE(sv) & SVpbm_TAIL)
#define SvTAIL_on(sv)		(SvPRIVATE(sv) |= SVpbm_TAIL)
#define SvTAIL_off(sv)		(SvPRIVATE(sv) &= ~SVpbm_TAIL)

#define SvCASEFOLD(sv)		(SvPRIVATE(sv) & SVpbm_CASEFOLD)
#define SvCASEFOLD_on(sv)	(SvPRIVATE(sv) |= SVpbm_CASEFOLD)
#define SvCASEFOLD_off(sv)	(SvPRIVATE(sv) &= ~SVpbm_CASEFOLD)

#define SvVALID(sv)		(SvPRIVATE(sv) & SVpbm_VALID)
#define SvVALID_on(sv)		(SvPRIVATE(sv) |= SVpbm_VALID)
#define SvVALID_off(sv)		(SvPRIVATE(sv) &= ~SVpbm_VALID)

#define SvMULTI(sv)		(SvPRIVATE(sv) & SVpgv_MULTI)
#define SvMULTI_on(sv)		(SvPRIVATE(sv) |= SVpgv_MULTI)
#define SvMULTI_off(sv)		(SvPRIVATE(sv) &= ~SVpgv_MULTI)

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
#define SvENDx(sv) ((Sv = sv), SvEND(Sv))
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

#define SvCUROK(sv) (SvPOK(sv) ? SvCUR(sv) : 0)

#define BmRARE(sv)	((XPVBM*)  SvANY(sv))->xbm_rare
#define BmUSEFUL(sv)	((XPVBM*)  SvANY(sv))->xbm_useful
#define BmPREVIOUS(sv)	((XPVBM*)  SvANY(sv))->xbm_previous

#define FmLINES(sv)	((XPVFM*)  SvANY(sv))->xfm_lines

#define LvTYPE(sv)	((XPVLV*)  SvANY(sv))->xlv_type
#define LvTARG(sv)	((XPVLV*)  SvANY(sv))->xlv_targ
#define LvTARGOFF(sv)	((XPVLV*)  SvANY(sv))->xlv_targoff
#define LvTARGLEN(sv)	((XPVLV*)  SvANY(sv))->xlv_targlen

#define SvTAINT(sv) if (tainting && tainted) sv_magic(sv, 0, 't', 0, 0)

#ifdef CRIPPLED_CC

double SvIV();
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
	SvPOK(sv)						\
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

#define SvIVx(sv) ((Sv = sv), SvIV(Sv))
#define SvNVx(sv) ((Sv = sv), SvNV(Sv))
#define SvPVx(sv, lp) ((Sv = sv), SvPV(Sv, lp))
#define SvTRUEx(sv) ((Sv = sv), SvTRUE(Sv))

#endif /* CRIPPLED_CC */

/* the following macro updates any magic values this sv is associated with */

#define SvSETMAGIC(x) if (SvMAGICAL(x)) mg_set(x)

#define SvSetSV(dst,src) if (dst != src) sv_setsv(dst,src)

#define SvPEEK(sv) sv_peek(sv)

#define isGV(sv) (SvTYPE(sv) == SVt_PVGV)

#define GROWSTR(pp,lp,len) if (*(lp) < (len)) pv_grow(pp, lp, (len) * 3 / 2)

#ifndef DOSISH
#  define SvGROW(sv,len) if (SvLEN(sv) < (len)) sv_grow(sv,len)
#  define Sv_Grow sv_grow
#else
    /* extra parentheses intentionally NOT placed around "len"! */
#  define SvGROW(sv,len) if (SvLEN(sv) < (unsigned long)len) \
		sv_grow(sv,(unsigned long)len)
#  define Sv_Grow(sv,len) sv_grow(sv,(unsigned long)(len))
#endif /* DOSISH */
