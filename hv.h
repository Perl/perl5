/*    hv.h
 *
 *    Copyright (c) 1991-1994, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
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
    I32		xhv_keys;	/* how many elements in the array */
    double	xnv_nv;		/* numeric value, if any */
    MAGIC*	xmg_magic;	/* magic for scalar array */
    HV*		xmg_stash;	/* class package */

    I32		xhv_riter;	/* current root of iterator */
    HE		*xhv_eiter;	/* current entry of iterator */
    PMOP	*xhv_pmroot;	/* list of pm's for this package */
    char	*xhv_name;	/* name, if a symbol table */
};

#define PERL_HASH(hash,str,len) \
     STMT_START	{ \
	register char *s_PeRlHaSh = str; \
	register I32 i_PeRlHaSh = len; \
	register U32 hash_PeRlHaSh = 0; \
	while (i_PeRlHaSh--) \
	    hash_PeRlHaSh = hash_PeRlHaSh * 33 + *s_PeRlHaSh++; \
	(hash) = hash_PeRlHaSh; \
    } STMT_END


/* these hash entry flags ride on hent_klen */

#define HEf_LAZYDEL	-1	/* entry must be deleted during next iter step */
#define HEf_SVKEY	-2	/* hent_key is a SV* (only for magic/tied HVs) */


#define Nullhv Null(HV*)
#define HvARRAY(hv)	((HE**)((XPVHV*)  SvANY(hv))->xhv_array)
#define HvFILL(hv)	((XPVHV*)  SvANY(hv))->xhv_fill
#define HvMAX(hv)	((XPVHV*)  SvANY(hv))->xhv_max
#define HvKEYS(hv)	((XPVHV*)  SvANY(hv))->xhv_keys
#define HvRITER(hv)	((XPVHV*)  SvANY(hv))->xhv_riter
#define HvEITER(hv)	((XPVHV*)  SvANY(hv))->xhv_eiter
#define HvPMROOT(hv)	((XPVHV*)  SvANY(hv))->xhv_pmroot
#define HvNAME(hv)	((XPVHV*)  SvANY(hv))->xhv_name

#define HvSHAREKEYS(hv)		(SvFLAGS(hv) & SVphv_SHAREKEYS)
#define HvSHAREKEYS_on(hv)	(SvFLAGS(hv) |= SVphv_SHAREKEYS)
#define HvSHAREKEYS_off(hv)	(SvFLAGS(hv) &= ~SVphv_SHAREKEYS)

#ifdef OVERLOAD

/* Maybe amagical: */
/* #define HV_AMAGICmb(hv)      (SvFLAGS(hv) & (SVpgv_badAM | SVpgv_AM)) */

#define HV_AMAGIC(hv)        (SvFLAGS(hv) &   SVpgv_AM)
#define HV_AMAGIC_on(hv)     (SvFLAGS(hv) |=  SVpgv_AM)
#define HV_AMAGIC_off(hv)    (SvFLAGS(hv) &= ~SVpgv_AM)

/*
#define HV_AMAGICbad(hv)     (SvFLAGS(hv) & SVpgv_badAM)
#define HV_badAMAGIC_on(hv)  (SvFLAGS(hv) |= SVpgv_badAM)
#define HV_badAMAGIC_off(hv) (SvFLAGS(hv) &= ~SVpgv_badAM)
*/

#endif /* OVERLOAD */

#define Nullhe Null(HE*)
#define HeNEXT(he)		(he)->hent_next
#define HeKEY(he)		(he)->hent_key
#define HeKLEN(he)		(he)->hent_klen
#define HeVAL(he)		(he)->hent_val
#define HeHASH(he)		(he)->hent_hash
#define HePV(he)		((he)->hent_klen == HEf_SVKEY) ?		\
				SvPV((SV*)((he)->hent_key),na) :		\
				(he)->hent_key))
#define HeSVKEY(he)		(((he)->hent_key && 				\
				  (he)->hent_klen == HEf_SVKEY) ?		\
				 (SV*)((he)->hent_key) : Nullsv)

#define HeSVKEY_force(he)	((he)->hent_key ?				\
				 (((he)->hent_klen == HEf_SVKEY) ?		\
				  (SV*)((he)->hent_key) :			\
				  sv_2mortal(newSVpv((he)->hent_key,		\
						     (he)->hent_klen))) :	\
				 &sv_undef)
