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
    ANY		sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct gv {
    ANY		sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct cv {
    ANY		sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct av {
    ANY		sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

struct hv {
    ANY		sv_any;		/* pointer to something */
    U32		sv_refcnt;	/* how many references to us */
    SVTYPE	sv_type;	/* what sort of thing pointer points to */
    U8		sv_flags;	/* extra flags, some depending on type */
    U8		sv_storage;	/* storage class */
    U8		sv_private;	/* extra value, depending on type */
};

#define SvANY(sv)	(sv)->sv_any.any_ptr
#define SvANYI32(sv)	(sv)->sv_any.any_i32
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
#define SVf_SCREAM	32		/* eventually in sv_private? */
#define SVf_TEMP	64		/* eventually in sv_private? */
#define SVf_READONLY	128		/* may not be modified */

#define SVp_TAINTED	128		/* is a security risk */

#define SVpfm_COMPILED	1

#define SVpbm_TAIL	1
#define SVpbm_CASEFOLD	2
#define SVpbm_VALID	4

#define SVpgv_MULTI	1

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

/* XXX need to write custom routines for some of these */
#define new_SV() (void*)malloc(sizeof(SV))
#define del_SV(p) free((char*)p)

#define new_XIV() (void*)malloc(sizeof(XPVIV))
#define del_XIV(p) free((char*)p)

#define new_XNV() (void*)malloc(sizeof(XPVNV))
#define del_XNV(p) free((char*)p)

#define new_XPV() (void*)malloc(sizeof(XPV))
#define del_XPV(p) free((char*)p)

#define new_XPVIV() (void*)malloc(sizeof(XPVIV))
#define del_XPVIV(p) free((char*)p)

#define new_XPVNV() (void*)malloc(sizeof(XPVNV))
#define del_XPVNV(p) free((char*)p)

#define new_XPVMG() (void*)malloc(sizeof(XPVMG))
#define del_XPVMG(p) free((char*)p)

#define new_XPVLV() (void*)malloc(sizeof(XPVLV))
#define del_XPVLV(p) free((char*)p)

#define new_XPVAV() (void*)malloc(sizeof(XPVAV))
#define del_XPVAV(p) free((char*)p)

#define new_XPVHV() (void*)malloc(sizeof(XPVHV))
#define del_XPVHV(p) free((char*)p)

#define new_XPVCV() (void*)malloc(sizeof(XPVCV))
#define del_XPVCV(p) free((char*)p)

#define new_XPVGV() (void*)malloc(sizeof(XPVGV))
#define del_XPVGV(p) free((char*)p)

#define new_XPVBM() (void*)malloc(sizeof(XPVBM))
#define del_XPVBM(p) free((char*)p)

#define new_XPVFM() (void*)malloc(sizeof(XPVFM))
#define del_XPVFM(p) free((char*)p)

#define SvNIOK(sv)		(SvFLAGS(sv) & (SVf_IOK|SVf_NOK))

#define SvOK(sv)		(SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK))
#define SvOK_off(sv)		(SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK), \
					SvOOK_off(sv))

#define SvIOK(sv)		(SvFLAGS(sv) & SVf_IOK)
#define SvIOK_on(sv)		(SvOOK_off(sv), SvFLAGS(sv) |= SVf_IOK)
#define SvIOK_off(sv)		(SvFLAGS(sv) &= ~SVf_IOK)
#define SvIOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= SVf_IOK)

#define SvNOK(sv)		(SvFLAGS(sv) & SVf_NOK)
#define SvNOK_on(sv)		(SvFLAGS(sv) |= SVf_NOK)
#define SvNOK_off(sv)		(SvFLAGS(sv) &= ~SVf_NOK)
#define SvNOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= SVf_NOK)

#define SvPOK(sv)		(SvFLAGS(sv) & SVf_POK)
#define SvPOK_on(sv)		(SvFLAGS(sv) |= SVf_POK)
#define SvPOK_off(sv)		(SvFLAGS(sv) &= ~SVf_POK)
#define SvPOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= SVf_POK)

#define SvOOK(sv)		(SvFLAGS(sv) & SVf_OOK)
#define SvOOK_on(sv)		(SvIOK_off(sv), SvFLAGS(sv) |= SVf_OOK)
#define SvOOK_off(sv)		(SvOOK(sv) && sv_backoff(sv))
#define SvOOK_only(sv)		(SvOK_off(sv), SvFLAGS(sv) |= SVf_OOK)

#define SvREADONLY(sv)		(SvFLAGS(sv) & SVf_READONLY)
#define SvREADONLY_on(sv)	(SvFLAGS(sv) |= SVf_READONLY)
#define SvREADONLY_off(sv)	(SvFLAGS(sv) &= ~SVf_READONLY)

#define SvMAGICAL(sv)		(SvFLAGS(sv) & SVf_MAGICAL)
#define SvMAGICAL_on(sv)	(SvFLAGS(sv) |= SVf_MAGICAL)
#define SvMAGICAL_off(sv)	(SvFLAGS(sv) &= ~SVf_MAGICAL)

#define SvSCREAM(sv)		(SvFLAGS(sv) & SVf_SCREAM)
#define SvSCREAM_on(sv)		(SvFLAGS(sv) |= SVf_SCREAM)
#define SvSCREAM_off(sv)	(SvFLAGS(sv) &= ~SVf_SCREAM)

#define SvTEMP(sv)		(SvFLAGS(sv) & SVf_TEMP)
#define SvTEMP_on(sv)		(SvFLAGS(sv) |= SVf_TEMP)
#define SvTEMP_off(sv)		(SvFLAGS(sv) &= ~SVf_TEMP)

#define SvTAINTED(sv)		(SvPRIVATE(sv) & SVp_TAINTED)
#define SvTAINTED_on(sv)	(SvPRIVATE(sv) |= SVp_TAINTED)
#define SvTAINTED_off(sv)	(SvPRIVATE(sv) &= ~SVp_TAINTED)

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

#define SvIV(sv) ((XPVIV*)  SvANY(sv))->xiv_iv
#define SvIVx(sv) SvIV(sv)
#define SvNV(sv)  ((XPVNV*)SvANY(sv))->xnv_nv
#define SvNVx(sv) SvNV(sv)
#define SvPV(sv)  ((XPV*)  SvANY(sv))->xpv_pv
#define SvPVx(sv) SvPV(sv)
#define SvCUR(sv) ((XPV*)  SvANY(sv))->xpv_cur
#define SvCURx(sv) SvCUR(sv)
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
		(((XPV*)  SvANY(sv))->xpv_cur = val - SvPV(sv)); } while (0)

#define BmRARE(sv)	((XPVBM*)  SvANY(sv))->xbm_rare
#define BmUSEFUL(sv)	((XPVBM*)  SvANY(sv))->xbm_useful
#define BmPREVIOUS(sv)	((XPVBM*)  SvANY(sv))->xbm_previous

#define FmLINES(sv)	((XPVFM*)  SvANY(sv))->xfm_lines

#define LvTYPE(sv)	((XPVLV*)  SvANY(sv))->xlv_type
#define LvTARG(sv)	((XPVLV*)  SvANY(sv))->xlv_targ
#define LvTARGOFF(sv)	((XPVLV*)  SvANY(sv))->xlv_targoff
#define LvTARGLEN(sv)	((XPVLV*)  SvANY(sv))->xlv_targlen

#ifdef TAINT
#define SvTUP(sv)  (tainted |= (SvPRIVATE(sv) & SVp_TAINTED))
#define SvTUPc(sv) (tainted |= (SvPRIVATE(sv) & SVp_TAINTED)),
#define SvTDOWN(sv)  (SvPRIVATE(sv) |= tainted ? SVp_TAINTED : 0)
#define SvTDOWNc(sv) (SvPRIVATE(sv) |= tainted ? SVp_TAINTED : 0),
#else
#define SvTUP(sv)
#define SvTUPc(sv) 
#define SvTDOWN(sv)
#define SvTDOWNc(sv)
#endif

#ifdef CRIPPLED_CC

double SvIVn();
double SvNVn();
char *SvPVn();
I32 SvTRUE();

#define SvIVnx(sv) SvIVn(sv)
#define SvNVnx(sv) SvNVn(sv)
#define SvPVnx(sv) SvPVn(sv)
#define SvTRUEx(sv) SvTRUE(sv)

#else /* !CRIPPLED_CC */

#define SvIVn(sv) (SvTUPc(sv) (SvMAGICAL(sv) && mg_get(sv)),	\
			    SvIOK(sv) ? SvIV(sv) : sv_2iv(sv))

#define SvNVn(sv) (SvTUPc(sv) (SvMAGICAL(sv) && mg_get(sv)),	\
			    SvNOK(sv) ? SvNV(sv) : sv_2nv(sv))

#define SvPVn(sv) (SvTUPc(sv) (SvMAGICAL(sv) && mg_get(sv)),	\
			    SvPOK(sv) ? SvPV(sv) : sv_2pv(sv))

#define SvTRUE(sv) ((SvMAGICAL(sv) && mg_get(sv)),		\
	SvPOK(sv)						\
	?   ((Xpv = (XPV*)SvANY(sv)) &&				\
	     (*Xpv->xpv_pv > '0' ||				\
	      Xpv->xpv_cur > 1 ||				\
	      (Xpv->xpv_cur && *Xpv->xpv_pv != '0'))		\
	     ? 1						\
	     : 0)						\
	:							\
	    SvIOK(sv)						\
	    ? SvIV(sv) != 0					\
	    :   SvNOK(sv)					\
		? SvNV(sv) != 0.0				\
		: 0 )

#define SvIVnx(sv) ((Sv = sv), SvIVn(Sv))
#define SvNVnx(sv) ((Sv = sv), SvNVn(Sv))
#define SvPVnx(sv) ((Sv = sv), SvPVn(Sv))
#define SvTRUEx(sv) ((Sv = sv), SvTRUE(Sv))

#endif /* CRIPPLED_CC */

/* the following macro updates any magic values this sv is associated with */

#define SvGETMAGIC(x)						\
    SvTUP(x);							\
    if (SvMAGICAL(x)) mg_get(x)

#define SvSETMAGIC(x)						\
    SvTDOWN(x);							\
    if (SvMAGICAL(x))						\
	mg_set(x)

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

