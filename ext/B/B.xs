/*	B.xs
 *
 *	Copyright (c) 1996 Malcolm Beattie
 *
 *	You may distribute under the terms of either the GNU General Public
 *	License or the Artistic License, as specified in the README file.
 *
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef PerlIO
typedef PerlIO * InputStream;
#else
typedef FILE * InputStream;
#endif


static const char* const svclassnames[] = {
    "B::NULL",
#if PERL_VERSION >= 9
    "B::BIND",
#endif
    "B::IV",
    "B::NV",
#if PERL_VERSION <= 10
    "B::RV",
#endif
    "B::PV",
    "B::PVIV",
    "B::PVNV",
    "B::PVMG",
#if PERL_VERSION <= 8
    "B::BM",
#endif
#if PERL_VERSION >= 11
    "B::REGEXP",
#endif
#if PERL_VERSION >= 9
    "B::GV",
#endif
    "B::PVLV",
    "B::AV",
    "B::HV",
    "B::CV",
#if PERL_VERSION <= 8
    "B::GV",
#endif
    "B::FM",
    "B::IO",
};

typedef enum {
    OPc_NULL,	/* 0 */
    OPc_BASEOP,	/* 1 */
    OPc_UNOP,	/* 2 */
    OPc_BINOP,	/* 3 */
    OPc_LOGOP,	/* 4 */
    OPc_LISTOP,	/* 5 */
    OPc_PMOP,	/* 6 */
    OPc_SVOP,	/* 7 */
    OPc_PADOP,	/* 8 */
    OPc_PVOP,	/* 9 */
    OPc_LOOP,	/* 10 */
    OPc_COP	/* 11 */
} opclass;

static const char* const opclassnames[] = {
    "B::NULL",
    "B::OP",
    "B::UNOP",
    "B::BINOP",
    "B::LOGOP",
    "B::LISTOP",
    "B::PMOP",
    "B::SVOP",
    "B::PADOP",
    "B::PVOP",
    "B::LOOP",
    "B::COP"	
};

static const size_t opsizes[] = {
    0,	
    sizeof(OP),
    sizeof(UNOP),
    sizeof(BINOP),
    sizeof(LOGOP),
    sizeof(LISTOP),
    sizeof(PMOP),
    sizeof(SVOP),
    sizeof(PADOP),
    sizeof(PVOP),
    sizeof(LOOP),
    sizeof(COP)	
};

#define MY_CXT_KEY "B::_guts" XS_VERSION

typedef struct {
    int		x_walkoptree_debug;	/* Flag for walkoptree debug hook */
    SV *	x_specialsv_list[7];
} my_cxt_t;

START_MY_CXT

#define walkoptree_debug	(MY_CXT.x_walkoptree_debug)
#define specialsv_list		(MY_CXT.x_specialsv_list)

static opclass
cc_opclass(pTHX_ const OP *o)
{
    if (!o)
	return OPc_NULL;

    if (o->op_type == 0)
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    if (o->op_type == OP_SASSIGN)
	return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);

    if (o->op_type == OP_AELEMFAST) {
	if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
#ifdef USE_ITHREADS
	    return OPc_PADOP;
#else
	    return OPc_SVOP;
#endif
    }
    
#ifdef USE_ITHREADS
    if (o->op_type == OP_GV || o->op_type == OP_GVSV ||
	o->op_type == OP_RCATLINE)
	return OPc_PADOP;
#endif

    switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
    case OA_BASEOP:
	return OPc_BASEOP;

    case OA_UNOP:
	return OPc_UNOP;

    case OA_BINOP:
	return OPc_BINOP;

    case OA_LOGOP:
	return OPc_LOGOP;

    case OA_LISTOP:
	return OPc_LISTOP;

    case OA_PMOP:
	return OPc_PMOP;

    case OA_SVOP:
	return OPc_SVOP;

    case OA_PADOP:
	return OPc_PADOP;

    case OA_PVOP_OR_SVOP:
        /*
         * Character translations (tr///) are usually a PVOP, keeping a 
         * pointer to a table of shorts used to look up translations.
         * Under utf8, however, a simple table isn't practical; instead,
         * the OP is an SVOP, and the SV is a reference to a swash
         * (i.e., an RV pointing to an HV).
         */
	return (o->op_private & (OPpTRANS_TO_UTF|OPpTRANS_FROM_UTF))
		? OPc_SVOP : OPc_PVOP;

    case OA_LOOP:
	return OPc_LOOP;

    case OA_COP:
	return OPc_COP;

    case OA_BASEOP_OR_UNOP:
	/*
	 * UNI(OP_foo) in toke.c returns token UNI or FUNC1 depending on
	 * whether parens were seen. perly.y uses OPf_SPECIAL to
	 * signal whether a BASEOP had empty parens or none.
	 * Some other UNOPs are created later, though, so the best
	 * test is OPf_KIDS, which is set in newUNOP.
	 */
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    case OA_FILESTATOP:
	/*
	 * The file stat OPs are created via UNI(OP_foo) in toke.c but use
	 * the OPf_REF flag to distinguish between OP types instead of the
	 * usual OPf_SPECIAL flag. As usual, if OPf_KIDS is set, then we
	 * return OPc_UNOP so that walkoptree can find our children. If
	 * OPf_KIDS is not set then we check OPf_REF. Without OPf_REF set
	 * (no argument to the operator) it's an OP; with OPf_REF set it's
	 * an SVOP (and op_sv is the GV for the filehandle argument).
	 */
	return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
#ifdef USE_ITHREADS
		(o->op_flags & OPf_REF) ? OPc_PADOP : OPc_BASEOP);
#else
		(o->op_flags & OPf_REF) ? OPc_SVOP : OPc_BASEOP);
#endif
    case OA_LOOPEXOP:
	/*
	 * next, last, redo, dump and goto use OPf_SPECIAL to indicate that a
	 * label was omitted (in which case it's a BASEOP) or else a term was
	 * seen. In this last case, all except goto are definitely PVOP but
	 * goto is either a PVOP (with an ordinary constant label), an UNOP
	 * with OPf_STACKED (with a non-constant non-sub) or an UNOP for
	 * OP_REFGEN (with goto &sub) in which case OPf_STACKED also seems to
	 * get set.
	 */
	if (o->op_flags & OPf_STACKED)
	    return OPc_UNOP;
	else if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
	    return OPc_PVOP;
    }
    warn("can't determine class of operator %s, assuming BASEOP\n",
	 PL_op_name[o->op_type]);
    return OPc_BASEOP;
}

static char *
cc_opclassname(pTHX_ const OP *o)
{
    return (char *)opclassnames[cc_opclass(aTHX_ o)];
}

/* FIXME - figure out how to get the typemap to assign this to ST(0), rather
   than creating a new mortal for ST(0) then passing it in as the first
   argument.  */
static SV *
make_sv_object(pTHX_ SV *arg, SV *sv)
{
    const char *type = 0;
    IV iv;
    dMY_CXT;

    if (!arg)
	arg = sv_newmortal();

    for (iv = 0; iv < sizeof(specialsv_list)/sizeof(SV*); iv++) {
	if (sv == specialsv_list[iv]) {
	    type = "B::SPECIAL";
	    break;
	}
    }
    if (!type) {
	type = svclassnames[SvTYPE(sv)];
	iv = PTR2IV(sv);
    }
    sv_setiv(newSVrv(arg, type), iv);
    return arg;
}

#if PERL_VERSION >= 9
static SV *
make_temp_object(pTHX_ SV *temp)
{
    SV *target;
    SV *arg = sv_newmortal();
    const char *const type = svclassnames[SvTYPE(temp)];
    const IV iv = PTR2IV(temp);

    target = newSVrv(arg, type);
    sv_setiv(target, iv);

    /* Need to keep our "temp" around as long as the target exists.
       Simplest way seems to be to hang it from magic, and let that clear
       it up.  No vtable, so won't actually get in the way of anything.  */
    sv_magicext(target, temp, PERL_MAGIC_sv, NULL, NULL, 0);
    /* magic object has had its reference count increased, so we must drop
       our reference.  */
    SvREFCNT_dec(temp);
    return arg;
}

static SV *
make_warnings_object(pTHX_ STRLEN *warnings)
{
    const char *type = 0;
    dMY_CXT;
    IV iv = sizeof(specialsv_list)/sizeof(SV*);

    /* Counting down is deliberate. Before the split between make_sv_object
       and make_warnings_obj there appeared to be a bug - Nullsv and pWARN_STD
       were both 0, so you could never get a B::SPECIAL for pWARN_STD  */

    while (iv--) {
	if ((SV*)warnings == specialsv_list[iv]) {
	    type = "B::SPECIAL";
	    break;
	}
    }
    if (type) {
	SV *arg = sv_newmortal();
	sv_setiv(newSVrv(arg, type), iv);
	return arg;
    } else {
	/* B assumes that warnings are a regular SV. Seems easier to keep it
	   happy by making them into a regular SV.  */
	return make_temp_object(aTHX_ newSVpvn((char *)(warnings + 1), *warnings));
    }
}

static SV *
make_cop_io_object(pTHX_ COP *cop)
{
    SV *const value = newSV(0);

    Perl_emulate_cop_io(aTHX_ cop, value);

    if(SvOK(value)) {
	return make_sv_object(aTHX_ NULL, value);
    } else {
	SvREFCNT_dec(value);
	return make_sv_object(aTHX_ NULL, NULL);
    }
}
#endif

static SV *
make_mg_object(pTHX_ MAGIC *mg)
{
    SV *arg = sv_newmortal();
    sv_setiv(newSVrv(arg, "B::MAGIC"), PTR2IV(mg));
    return arg;
}

static SV *
cstring(pTHX_ SV *sv, bool perlstyle)
{
    SV *sstr;

    if (!SvOK(sv))
	return newSVpvs_flags("0", SVs_TEMP);

    sstr = newSVpvs_flags("\"", SVs_TEMP);

    if (perlstyle && SvUTF8(sv)) {
	SV *tmpsv = sv_newmortal(); /* Temporary SV to feed sv_uni_display */
	const STRLEN len = SvCUR(sv);
	const char *s = sv_uni_display(tmpsv, sv, 8*len, UNI_DISPLAY_QQ);
	while (*s)
	{
	    if (*s == '"')
		sv_catpvs(sstr, "\\\"");
	    else if (*s == '$')
		sv_catpvs(sstr, "\\$");
	    else if (*s == '@')
		sv_catpvs(sstr, "\\@");
	    else if (*s == '\\')
	    {
		if (strchr("nrftax\\",*(s+1)))
		    sv_catpvn(sstr, s++, 2);
		else
		    sv_catpvs(sstr, "\\\\");
	    }
	    else /* should always be printable */
		sv_catpvn(sstr, s, 1);
	    ++s;
	}
    }
    else
    {
	/* XXX Optimise? */
	STRLEN len;
	const char *s = SvPV(sv, len);
	for (; len; len--, s++)
	{
	    /* At least try a little for readability */
	    if (*s == '"')
		sv_catpvs(sstr, "\\\"");
	    else if (*s == '\\')
		sv_catpvs(sstr, "\\\\");
            /* trigraphs - bleagh */
            else if (!perlstyle && *s == '?' && len>=3 && s[1] == '?') {
                Perl_sv_catpvf(aTHX_ sstr, "\\%03o", '?');
            }
	    else if (perlstyle && *s == '$')
		sv_catpvs(sstr, "\\$");
	    else if (perlstyle && *s == '@')
		sv_catpvs(sstr, "\\@");
#ifdef EBCDIC
	    else if (isPRINT(*s))
#else
	    else if (*s >= ' ' && *s < 127)
#endif /* EBCDIC */
		sv_catpvn(sstr, s, 1);
	    else if (*s == '\n')
		sv_catpvs(sstr, "\\n");
	    else if (*s == '\r')
		sv_catpvs(sstr, "\\r");
	    else if (*s == '\t')
		sv_catpvs(sstr, "\\t");
	    else if (*s == '\a')
		sv_catpvs(sstr, "\\a");
	    else if (*s == '\b')
		sv_catpvs(sstr, "\\b");
	    else if (*s == '\f')
		sv_catpvs(sstr, "\\f");
	    else if (!perlstyle && *s == '\v')
		sv_catpvs(sstr, "\\v");
	    else
	    {
		/* Don't want promotion of a signed -1 char in sprintf args */
		const unsigned char c = (unsigned char) *s;
		Perl_sv_catpvf(aTHX_ sstr, "\\%03o", c);
	    }
	    /* XXX Add line breaks if string is long */
	}
    }
    sv_catpvs(sstr, "\"");
    return sstr;
}

static SV *
cchar(pTHX_ SV *sv)
{
    SV *sstr = newSVpvs_flags("'", SVs_TEMP);
    const char *s = SvPV_nolen(sv);
    /* Don't want promotion of a signed -1 char in sprintf args */
    const unsigned char c = (unsigned char) *s;

    if (c == '\'')
	sv_catpvs(sstr, "\\'");
    else if (c == '\\')
	sv_catpvs(sstr, "\\\\");
#ifdef EBCDIC
    else if (isPRINT(c))
#else
    else if (c >= ' ' && c < 127)
#endif /* EBCDIC */
	sv_catpvn(sstr, s, 1);
    else if (c == '\n')
	sv_catpvs(sstr, "\\n");
    else if (c == '\r')
	sv_catpvs(sstr, "\\r");
    else if (c == '\t')
	sv_catpvs(sstr, "\\t");
    else if (c == '\a')
	sv_catpvs(sstr, "\\a");
    else if (c == '\b')
	sv_catpvs(sstr, "\\b");
    else if (c == '\f')
	sv_catpvs(sstr, "\\f");
    else if (c == '\v')
	sv_catpvs(sstr, "\\v");
    else
	Perl_sv_catpvf(aTHX_ sstr, "\\%03o", c);
    sv_catpvs(sstr, "'");
    return sstr;
}

#if PERL_VERSION >= 9
#  define PMOP_pmreplstart(o)	o->op_pmstashstartu.op_pmreplstart
#  define PMOP_pmreplroot(o)	o->op_pmreplrootu.op_pmreplroot
#else
#  define PMOP_pmreplstart(o)	o->op_pmreplstart
#  define PMOP_pmreplroot(o)	o->op_pmreplroot
#  define PMOP_pmpermflags(o)	o->op_pmpermflags
#  define PMOP_pmdynflags(o)      o->op_pmdynflags
#endif

static void
walkoptree(pTHX_ SV *opsv, const char *method)
{
    dSP;
    OP *o, *kid;
    dMY_CXT;

    if (!SvROK(opsv))
	croak("opsv is not a reference");
    opsv = sv_mortalcopy(opsv);
    o = INT2PTR(OP*,SvIV((SV*)SvRV(opsv)));
    if (walkoptree_debug) {
	PUSHMARK(sp);
	XPUSHs(opsv);
	PUTBACK;
	perl_call_method("walkoptree_debug", G_DISCARD);
    }
    PUSHMARK(sp);
    XPUSHs(opsv);
    PUTBACK;
    perl_call_method(method, G_DISCARD);
    if (o && (o->op_flags & OPf_KIDS)) {
	for (kid = ((UNOP*)o)->op_first; kid; kid = kid->op_sibling) {
	    /* Use the same opsv. Rely on methods not to mess it up. */
	    sv_setiv(newSVrv(opsv, cc_opclassname(aTHX_ kid)), PTR2IV(kid));
	    walkoptree(aTHX_ opsv, method);
	}
    }
    if (o && (cc_opclass(aTHX_ o) == OPc_PMOP) && o->op_type != OP_PUSHRE
           && (kid = PMOP_pmreplroot(cPMOPo)))
    {
	sv_setiv(newSVrv(opsv, cc_opclassname(aTHX_ kid)), PTR2IV(kid));
	walkoptree(aTHX_ opsv, method);
    }
}

static SV **
oplist(pTHX_ OP *o, SV **SP)
{
    for(; o; o = o->op_next) {
	SV *opsv;
#if PERL_VERSION >= 9
	if (o->op_opt == 0)
	    break;
	o->op_opt = 0;
#else
	if (o->op_seq == 0)
	    break;
	o->op_seq = 0;
#endif
	opsv = sv_newmortal();
	sv_setiv(newSVrv(opsv, cc_opclassname(aTHX_ (OP*)o)), PTR2IV(o));
	XPUSHs(opsv);
        switch (o->op_type) {
	case OP_SUBST:
            SP = oplist(aTHX_ PMOP_pmreplstart(cPMOPo), SP);
            continue;
	case OP_SORT:
	    if (o->op_flags & OPf_STACKED && o->op_flags & OPf_SPECIAL) {
		OP *kid = cLISTOPo->op_first->op_sibling;   /* pass pushmark */
		kid = kUNOP->op_first;                      /* pass rv2gv */
		kid = kUNOP->op_first;                      /* pass leave */
		SP = oplist(aTHX_ kid->op_next, SP);
	    }
	    continue;
        }
	switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
	case OA_LOGOP:
	    SP = oplist(aTHX_ cLOGOPo->op_other, SP);
	    break;
	case OA_LOOP:
	    SP = oplist(aTHX_ cLOOPo->op_lastop, SP);
	    SP = oplist(aTHX_ cLOOPo->op_nextop, SP);
	    SP = oplist(aTHX_ cLOOPo->op_redoop, SP);
	    break;
	}
    }
    return SP;
}

typedef OP	*B__OP;
typedef UNOP	*B__UNOP;
typedef BINOP	*B__BINOP;
typedef LOGOP	*B__LOGOP;
typedef LISTOP	*B__LISTOP;
typedef PMOP	*B__PMOP;
typedef SVOP	*B__SVOP;
typedef PADOP	*B__PADOP;
typedef PVOP	*B__PVOP;
typedef LOOP	*B__LOOP;
typedef COP	*B__COP;

typedef SV	*B__SV;
typedef SV	*B__IV;
typedef SV	*B__PV;
typedef SV	*B__NV;
typedef SV	*B__PVMG;
#if PERL_VERSION >= 11
typedef SV	*B__REGEXP;
#endif
typedef SV	*B__PVLV;
typedef SV	*B__BM;
typedef SV	*B__RV;
typedef SV	*B__FM;
typedef AV	*B__AV;
typedef HV	*B__HV;
typedef CV	*B__CV;
typedef GV	*B__GV;
typedef IO	*B__IO;

typedef MAGIC	*B__MAGIC;
typedef HE      *B__HE;
#if PERL_VERSION >= 9
typedef struct refcounted_he	*B__RHE;
#endif

#include "const-c.inc"

MODULE = B	PACKAGE = B	PREFIX = B_

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

BOOT:
{
    HV *stash = gv_stashpvs("B", GV_ADD);
    AV *export_ok = perl_get_av("B::EXPORT_OK", GV_ADD);
    MY_CXT_INIT;
    specialsv_list[0] = Nullsv;
    specialsv_list[1] = &PL_sv_undef;
    specialsv_list[2] = &PL_sv_yes;
    specialsv_list[3] = &PL_sv_no;
    specialsv_list[4] = (SV *) pWARN_ALL;
    specialsv_list[5] = (SV *) pWARN_NONE;
    specialsv_list[6] = (SV *) pWARN_STD;
#if PERL_VERSION <= 8
#  define OPpPAD_STATE 0
#endif
}

#define B_main_cv()	PL_main_cv
#define B_init_av()	PL_initav
#define B_inc_gv()	PL_incgv
#define B_check_av()	PL_checkav_save
#if PERL_VERSION > 8
#  define B_unitcheck_av()	PL_unitcheckav_save
#else
#  define B_unitcheck_av()	NULL
#endif
#define B_begin_av()	PL_beginav_save
#define B_end_av()	PL_endav
#define B_main_root()	PL_main_root
#define B_main_start()	PL_main_start
#define B_amagic_generation()	PL_amagic_generation
#define B_sub_generation()	PL_sub_generation
#define B_defstash()	PL_defstash
#define B_curstash()	PL_curstash
#define B_dowarn()	PL_dowarn
#define B_comppadlist()	(PL_main_cv ? CvPADLIST(PL_main_cv) : CvPADLIST(PL_compcv))
#define B_sv_undef()	&PL_sv_undef
#define B_sv_yes()	&PL_sv_yes
#define B_sv_no()	&PL_sv_no
#define B_formfeed()	PL_formfeed
#ifdef USE_ITHREADS
#define B_regex_padav()	PL_regex_padav
#endif

B::AV
B_init_av()

B::AV
B_check_av()

#if PERL_VERSION >= 9

B::AV
B_unitcheck_av()

#endif

B::AV
B_begin_av()

B::AV
B_end_av()

B::GV
B_inc_gv()

#ifdef USE_ITHREADS

B::AV
B_regex_padav()

#endif

B::CV
B_main_cv()

B::OP
B_main_root()

B::OP
B_main_start()

long 
B_amagic_generation()

long
B_sub_generation()

B::AV
B_comppadlist()

B::SV
B_sv_undef()

B::SV
B_sv_yes()

B::SV
B_sv_no()

B::HV
B_curstash()

B::HV
B_defstash()

U8
B_dowarn()

B::SV
B_formfeed()

void
B_warnhook()
    CODE:
	ST(0) = make_sv_object(aTHX_ NULL, PL_warnhook);

void
B_diehook()
    CODE:
	ST(0) = make_sv_object(aTHX_ NULL, PL_diehook);

MODULE = B	PACKAGE = B

void
walkoptree(opsv, method)
	SV *	opsv
	const char *	method
    CODE:
	walkoptree(aTHX_ opsv, method);

int
walkoptree_debug(...)
    CODE:
	dMY_CXT;
	RETVAL = walkoptree_debug;
	if (items > 0 && SvTRUE(ST(1)))
	    walkoptree_debug = 1;
    OUTPUT:
	RETVAL

#define address(sv) PTR2IV(sv)

IV
address(sv)
	SV *	sv

B::SV
svref_2object(sv)
	SV *	sv
    CODE:
	if (!SvROK(sv))
	    croak("argument is not a reference");
	RETVAL = (SV*)SvRV(sv);
    OUTPUT:
	RETVAL              

void
opnumber(name)
const char *	name
CODE:
{
 int i; 
 IV  result = -1;
 ST(0) = sv_newmortal();
 if (strncmp(name,"pp_",3) == 0)
   name += 3;
 for (i = 0; i < PL_maxo; i++)
  {
   if (strcmp(name, PL_op_name[i]) == 0)
    {
     result = i;
     break;
    }
  }
 sv_setiv(ST(0),result);
}

void
ppname(opnum)
	int	opnum
    CODE:
	ST(0) = sv_newmortal();
	if (opnum >= 0 && opnum < PL_maxo) {
	    sv_setpvs(ST(0), "pp_");
	    sv_catpv(ST(0), PL_op_name[opnum]);
	}

void
hash(sv)
	SV *	sv
    CODE:
	STRLEN len;
	U32 hash = 0;
	const char *s = SvPVbyte(sv, len);
	PERL_HASH(hash, s, len);
	ST(0) = sv_2mortal(Perl_newSVpvf(aTHX_ "0x%"UVxf, (UV)hash));

#define cast_I32(foo) (I32)foo
IV
cast_I32(i)
	IV	i

void
minus_c()
    CODE:
	PL_minus_c = TRUE;

void
save_BEGINs()
    CODE:
	PL_savebegin = TRUE;

SV *
cstring(sv)
	SV *	sv
    ALIAS:
	perlstring = 1
	cchar = 2
    PPCODE:
	PUSHs(ix == 2 ? cchar(aTHX_ sv) : cstring(aTHX_ sv, ix));

void
threadsv_names()
    PPCODE:
#if PERL_VERSION <= 8
# ifdef USE_5005THREADS
	int i;
	const STRLEN len = strlen(PL_threadsv_names);

	EXTEND(sp, len);
	for (i = 0; i < len; i++)
	    PUSHs(newSVpvn_flags(&PL_threadsv_names[i], 1, SVs_TEMP));
# endif
#endif

#define OPp		0x00000
#define PADOFFSETp	0x10000
#define U8p		0x20000
#define U32p		0x30000
#define SVp		0x40000
#define IVp		0x50000

#define OP_next_ix		OPp | offsetof(struct op, op_next)
#define OP_sibling_ix		OPp | offsetof(struct op, op_sibling)
#define UNOP_first_ix		OPp | offsetof(struct unop, op_first)
#define BINOP_last_ix		OPp | offsetof(struct binop, op_last)
#define LOGOP_other_ix		OPp | offsetof(struct logop, op_other)
#if PERL_VERSION >= 9
#  define PMOP_pmreplstart_ix \
		OPp | offsetof(struct pmop, op_pmstashstartu.op_pmreplstart)
#else
#  define PMOP_pmreplstart_ix	OPp | offsetof(struct pmop, op_pmreplstart)
#endif
#define LOOP_redoop_ix		OPp | offsetof(struct loop, op_redoop)
#define LOOP_nextop_ix		OPp | offsetof(struct loop, op_nextop)
#define LOOP_lastop_ix		OPp | offsetof(struct loop, op_lastop)

#define OP_targ_ix		PADOFFSETp | offsetof(struct op, op_targ)
#define OP_flags_ix		U8p | offsetof(struct op, op_flags)
#define OP_private_ix		U8p | offsetof(struct op, op_private)

#define PMOP_pmflags_ix		U32p | offsetof(struct pmop, op_pmflags)

#ifdef USE_ITHREADS
#define PMOP_pmoffset_ix	IVp | offsetof(struct pmop, op_pmoffset)
#endif

#  Yes, B::SV::sv and B::SV::gv really do end up generating identical code.
#define SVOP_sv_ix		SVp | offsetof(struct svop, op_sv)
#define SVOP_gv_ix		SVp | offsetof(struct svop, op_sv)

#define PADOP_padix_ix		PADOFFSETp | offsetof(struct padop, op_padix)

MODULE = B	PACKAGE = B::OP		PREFIX = OP_

size_t
OP_size(o)
	B::OP		o
    CODE:
	RETVAL = opsizes[cc_opclass(aTHX_ o)];
    OUTPUT:
	RETVAL

# The type checking code in B has always been identical for all OP types,
# irrespective of whether the action is actually defined on that OP.
# We should fix this
void
next(o)
	B::OP		o
    ALIAS:
	B::OP::next = OP_next_ix
	B::OP::sibling = OP_sibling_ix
	B::OP::targ = OP_targ_ix
	B::OP::flags = OP_flags_ix
	B::OP::private = OP_private_ix
	B::UNOP::first = UNOP_first_ix
	B::BINOP::last = BINOP_last_ix
	B::LOGOP::other = LOGOP_other_ix
	B::PMOP::pmreplstart = PMOP_pmreplstart_ix
	B::LOOP::redoop = LOOP_redoop_ix
	B::LOOP::nextop = LOOP_nextop_ix
	B::LOOP::lastop = LOOP_lastop_ix
	B::PMOP::pmflags = PMOP_pmflags_ix
	B::SVOP::sv = SVOP_sv_ix
	B::SVOP::gv = SVOP_gv_ix
	B::PADOP::padix = PADOP_padix_ix
    PREINIT:
	char *ptr;
	SV *ret;
    PPCODE:
	ptr = (ix & 0xFFFF) + (char *)o;
	switch ((U8)(ix >> 16)) {
	case (U8)(OPp >> 16):
	    {
		OP *const o2 = *((OP **)ptr);
		ret = sv_newmortal();
		sv_setiv(newSVrv(ret, cc_opclassname(aTHX_ o2)), PTR2IV(o2));
		break;
	    }
	case (U8)(PADOFFSETp >> 16):
	    ret = sv_2mortal(newSVuv(*((PADOFFSET*)ptr)));
	    break;
	case (U8)(U8p >> 16):
	    ret = sv_2mortal(newSVuv(*((U8*)ptr)));
	    break;
	case (U8)(U32p >> 16):
	    ret = sv_2mortal(newSVuv(*((U32*)ptr)));
	    break;
	case (U8)(SVp >> 16):
	    ret = make_sv_object(aTHX_ NULL, *((SV **)ptr));
	    break;
#ifdef USE_ITHREADS
	case (U8)(IVp >> 16):
	    ret = sv_2mortal(newSViv(*((IV*)ptr)));
	    break;
#endif
	}
	ST(0) = ret;
	XSRETURN(1);

char *
OP_name(o)
	B::OP		o
    ALIAS:
	desc = 1
    CODE:
	RETVAL = (char *)(ix ? PL_op_desc : PL_op_name)[o->op_type];
    OUTPUT:
	RETVAL

void
OP_ppaddr(o)
	B::OP		o
    PREINIT:
	int i;
	SV *sv = newSVpvs_flags("PL_ppaddr[OP_", SVs_TEMP);
    CODE:
	sv_catpv(sv, PL_op_name[o->op_type]);
	for (i=13; (STRLEN)i < SvCUR(sv); ++i)
	    SvPVX(sv)[i] = toUPPER(SvPVX(sv)[i]);
	sv_catpvs(sv, "]");
	ST(0) = sv;

#if PERL_VERSION >= 9
#  These 3 are all bitfields, so we can't take their addresses.
UV
OP_type(o)
	B::OP		o
    ALIAS:
	opt = 1
	spare = 2
    CODE:
	switch(ix) {
	  case 1:
	    RETVAL = o->op_opt;
	    break;
	  case 2:
	    RETVAL = o->op_spare;
	    break;
	  default:
	    RETVAL = o->op_type;
	}
    OUTPUT:
	RETVAL

#else

UV
OP_type(o)
	B::OP		o
    ALIAS:
	seq = 1
    CODE:
	switch(ix) {
	  case 1:
	    RETVAL = o->op_seq;
	    break;
	  default:
	    RETVAL = o->op_type;
	}
    OUTPUT:
	RETVAL

#endif

void
OP_oplist(o)
	B::OP		o
    PPCODE:
	SP = oplist(aTHX_ o, SP);

MODULE = B	PACKAGE = B::LISTOP		PREFIX = LISTOP_

U32
LISTOP_children(o)
	B::LISTOP	o
	OP *		kid = NO_INIT
	int		i = NO_INIT
    CODE:
	i = 0;
	for (kid = o->op_first; kid; kid = kid->op_sibling)
	    i++;
	RETVAL = i;
    OUTPUT:
	RETVAL

MODULE = B	PACKAGE = B::PMOP		PREFIX = PMOP_

#if PERL_VERSION <= 8

void
PMOP_pmreplroot(o)
	B::PMOP		o
	OP *		root = NO_INIT
    CODE:
	ST(0) = sv_newmortal();
	root = o->op_pmreplroot;
	/* OP_PUSHRE stores an SV* instead of an OP* in op_pmreplroot */
	if (o->op_type == OP_PUSHRE) {
#  ifdef USE_ITHREADS
            sv_setiv(ST(0), INT2PTR(PADOFFSET,root) );
#  else
	    sv_setiv(newSVrv(ST(0), root ?
			     svclassnames[SvTYPE((SV*)root)] : "B::SV"),
		     PTR2IV(root));
#  endif
	}
	else {
	    sv_setiv(newSVrv(ST(0), cc_opclassname(aTHX_ root)), PTR2IV(root));
	}

#else

void
PMOP_pmreplroot(o)
	B::PMOP		o
    CODE:
	ST(0) = sv_newmortal();
	if (o->op_type == OP_PUSHRE) {
#  ifdef USE_ITHREADS
            sv_setiv(ST(0), o->op_pmreplrootu.op_pmtargetoff);
#  else
	    GV *const target = o->op_pmreplrootu.op_pmtargetgv;
	    sv_setiv(newSVrv(ST(0), target ?
			     svclassnames[SvTYPE((SV*)target)] : "B::SV"),
		     PTR2IV(target));
#  endif
	}
	else {
	    OP *const root = o->op_pmreplrootu.op_pmreplroot; 
	    sv_setiv(newSVrv(ST(0), cc_opclassname(aTHX_ root)),
		     PTR2IV(root));
	}

#endif

#ifdef USE_ITHREADS
#define PMOP_pmstashpv(o)	PmopSTASHPV(o);

char*
PMOP_pmstashpv(o)
	B::PMOP		o

#else
#define PMOP_pmstash(o)		PmopSTASH(o);

B::HV
PMOP_pmstash(o)
	B::PMOP		o

#endif

#if PERL_VERSION < 9
#define PMOP_pmnext(o)		o->op_pmnext

B::PMOP
PMOP_pmnext(o)
	B::PMOP		o

U32
PMOP_pmpermflags(o)
	B::PMOP		o

U8
PMOP_pmdynflags(o)
        B::PMOP         o

#endif

void
PMOP_precomp(o)
	B::PMOP		o
    PREINIT:
	dXSI32;
	REGEXP *rx;
    CODE:
	rx = PM_GETRE(o);
	ST(0) = sv_newmortal();
	if (rx) {
#if PERL_VERSION >= 9
	    if (ix) {
		sv_setuv(ST(0), RX_EXTFLAGS(rx));
	    } else
#endif
	    {
		sv_setpvn(ST(0), RX_PRECOMP(rx), RX_PRELEN(rx));
	    }
	}

BOOT:
{
	CV *cv;
#ifdef USE_ITHREADS
        cv = newXS("B::PMOP::pmoffset", XS_B__OP_next, __FILE__);
        XSANY.any_i32 = PMOP_pmoffset_ix;
#endif
#if PERL_VERSION >= 9
        cv = newXS("B::PMOP::reflags", XS_B__PMOP_precomp, __FILE__);
        XSANY.any_i32 = 1;
#endif
}

#define PADOP_sv(o)	(o->op_padix ? PAD_SVl(o->op_padix) : Nullsv)
#define PADOP_gv(o)	((o->op_padix \
			  && SvTYPE(PAD_SVl(o->op_padix)) == SVt_PVGV) \
			 ? (GV*)PAD_SVl(o->op_padix) : (GV *)NULL)

MODULE = B	PACKAGE = B::PADOP		PREFIX = PADOP_

B::SV
PADOP_sv(o)
	B::PADOP o

B::GV
PADOP_gv(o)
	B::PADOP o

MODULE = B	PACKAGE = B::PVOP		PREFIX = PVOP_

void
PVOP_pv(o)
	B::PVOP	o
    CODE:
	/*
	 * OP_TRANS uses op_pv to point to a table of 256 or >=258 shorts
	 * whereas other PVOPs point to a null terminated string.
	 */
	if (o->op_type == OP_TRANS &&
		(o->op_private & OPpTRANS_COMPLEMENT) &&
		!(o->op_private & OPpTRANS_DELETE))
	{
	    const short* const tbl = (short*)o->op_pv;
	    const short entries = 257 + tbl[256];
	    ST(0) = newSVpvn_flags(o->op_pv, entries * sizeof(short), SVs_TEMP);
	}
	else if (o->op_type == OP_TRANS) {
	    ST(0) = newSVpvn_flags(o->op_pv, 256 * sizeof(short), SVs_TEMP);
	}
	else
	    ST(0) = newSVpvn_flags(o->op_pv, strlen(o->op_pv), SVs_TEMP);

#define COP_label(o)	CopLABEL(o)
#define COP_stashpv(o)	CopSTASHPV(o)
#define COP_stash(o)	CopSTASH(o)
#define COP_file(o)	CopFILE(o)
#define COP_filegv(o)	CopFILEGV(o)
#define COP_cop_seq(o)	o->cop_seq
#define COP_arybase(o)	CopARYBASE_get(o)
#define COP_line(o)	CopLINE(o)
#define COP_hints(o)	CopHINTS_get(o)

MODULE = B	PACKAGE = B::COP		PREFIX = COP_

const char *
COP_label(o)
	B::COP	o

char *
COP_stashpv(o)
	B::COP	o

B::HV
COP_stash(o)
	B::COP	o

char *
COP_file(o)
	B::COP	o

B::GV
COP_filegv(o)
       B::COP  o


U32
COP_cop_seq(o)
	B::COP	o

I32
COP_arybase(o)
	B::COP	o

U32
COP_line(o)
	B::COP	o

void
COP_warnings(o)
	B::COP	o
	PPCODE:
#if PERL_VERSION >= 9
	ST(0) = make_warnings_object(aTHX_ o->cop_warnings);
#else
	ST(0) = make_sv_object(aTHX_ NULL, o->cop_warnings);
#endif
	XSRETURN(1);

void
COP_io(o)
	B::COP	o
	PPCODE:
#if PERL_VERSION >= 9
	ST(0) = make_cop_io_object(aTHX_ o);
#else
	ST(0) = make_sv_object(aTHX_ NULL, o->cop_io);
#endif
	XSRETURN(1);

#if PERL_VERSION >= 9

B::RHE
COP_hints_hash(o)
	B::COP o
    CODE:
	RETVAL = CopHINTHASH_get(o);
    OUTPUT:
	RETVAL

#endif

U32
COP_hints(o)
	B::COP	o

MODULE = B	PACKAGE = B::SV

#define MAGICAL_FLAG_BITS (SVs_GMG|SVs_SMG|SVs_RMG)

U32
REFCNT(sv)
	B::SV	sv
    ALIAS:
	FLAGS = 0xFFFFFFFF
	SvTYPE = SVTYPEMASK
	POK = SVf_POK
	ROK = SVf_ROK
	MAGICAL = MAGICAL_FLAG_BITS
    CODE:
	RETVAL = ix ? (SvFLAGS(sv) & (U32)ix) : SvREFCNT(sv);
    OUTPUT:
	RETVAL

void
object_2svref(sv)
	B::SV	sv
    PPCODE:
	ST(0) = sv_2mortal(newRV(sv));
	XSRETURN(1);
	
MODULE = B	PACKAGE = B::IV		PREFIX = Sv

IV
SvIV(sv)
	B::IV	sv

IV
SvIVX(sv)
	B::IV	sv

UV 
SvUVX(sv) 
	B::IV   sv
                      

MODULE = B	PACKAGE = B::IV

#define needs64bits(sv) ((I32)SvIVX(sv) != SvIVX(sv))

int
needs64bits(sv)
	B::IV	sv

void
packiv(sv)
	B::IV	sv
    CODE:
	if (sizeof(IV) == 8) {
	    U32 wp[2];
	    const IV iv = SvIVX(sv);
	    /*
	     * The following way of spelling 32 is to stop compilers on
	     * 32-bit architectures from moaning about the shift count
	     * being >= the width of the type. Such architectures don't
	     * reach this code anyway (unless sizeof(IV) > 8 but then
	     * everything else breaks too so I'm not fussed at the moment).
	     */
#ifdef UV_IS_QUAD
	    wp[0] = htonl(((UV)iv) >> (sizeof(UV)*4));
#else
	    wp[0] = htonl(((U32)iv) >> (sizeof(UV)*4));
#endif
	    wp[1] = htonl(iv & 0xffffffff);
	    ST(0) = newSVpvn_flags((char *)wp, 8, SVs_TEMP);
	} else {
	    U32 w = htonl((U32)SvIVX(sv));
	    ST(0) = newSVpvn_flags((char *)&w, 4, SVs_TEMP);
	}

#if PERL_VERSION >= 11
#  The input typemap checking makes no distinction between different SV types,
#  so the XS body will generate the same C code, despite the different XS
#  "types". So there is no change in behaviour from doing newXS like this,
#  compared with the old approach of having a (near) duplicate XS body.
#  We should fix the typemap checking.

BOOT:
        newXS("B::IV::RV", XS_B__PV_RV, __FILE__);

#endif

MODULE = B	PACKAGE = B::NV		PREFIX = Sv

NV
SvNV(sv)
	B::NV	sv

NV
SvNVX(sv)
	B::NV	sv

U32
COP_SEQ_RANGE_LOW(sv)
	B::NV	sv

U32
COP_SEQ_RANGE_HIGH(sv)
	B::NV	sv

U32
PARENT_PAD_INDEX(sv)
	B::NV	sv

U32
PARENT_FAKELEX_FLAGS(sv)
	B::NV	sv

#if PERL_VERSION < 11

MODULE = B	PACKAGE = B::RV		PREFIX = Sv

B::SV
SvRV(sv)
	B::RV	sv

#endif

MODULE = B	PACKAGE = B::PV		PREFIX = Sv

char*
SvPVX(sv)
	B::PV	sv

B::SV
SvRV(sv)
        B::PV   sv
    CODE:
        if( SvROK(sv) ) {
            RETVAL = SvRV(sv);
        }
        else {
            croak( "argument is not SvROK" );
        }
    OUTPUT:
        RETVAL

void
SvPV(sv)
	B::PV	sv
    CODE:
        if( SvPOK(sv) ) {
	    STRLEN len = SvCUR(sv);
	    const char *p = SvPVX_const(sv);
#if PERL_VERSION < 10
	    /* Before 5.10 (well 931b58fb28fa5ca7), PAD_COMPNAME_GEN was stored
	       in SvCUR(), which meant we had to attempt this special casing
	       to avoid tripping up over variable names in the pads.  */
	    if((SvLEN(sv) && len >= SvLEN(sv))) {
		/* It claims to be longer than the space allocated for it -
		   presuambly it's a variable name in the pad  */
		len = strlen(p);
	    }
#endif
	    ST(0) = newSVpvn_flags(p, len, SVs_TEMP | SvUTF8(sv));
        }
        else {
            /* XXX for backward compatibility, but should fail */
            /* croak( "argument is not SvPOK" ); */
            ST(0) = sv_newmortal();
        }

# This used to read 257. I think that that was buggy - should have been 258.
# (The "\0", the flags byte, and 256 for the table.  Not that anything
# anywhere calls this method.  NWC.
void
SvPVBM(sv)
	B::PV	sv
    CODE:
        ST(0) = newSVpvn_flags(SvPVX_const(sv),
	    SvCUR(sv) + (SvVALID(sv) ? 256 + PERL_FBM_TABLE_OFFSET : 0),
	    SVs_TEMP);


STRLEN
SvLEN(sv)
	B::PV	sv

STRLEN
SvCUR(sv)
	B::PV	sv

MODULE = B	PACKAGE = B::PVMG	PREFIX = Sv

void
SvMAGIC(sv)
	B::PVMG	sv
	MAGIC *	mg = NO_INIT
    PPCODE:
	for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
	    XPUSHs(make_mg_object(aTHX_ mg));

MODULE = B	PACKAGE = B::PVMG

B::HV
SvSTASH(sv)
	B::PVMG	sv

MODULE = B	PACKAGE = B::REGEXP

#if PERL_VERSION >= 11

IV
REGEX(sv)
	B::REGEXP	sv
    CODE:
	/* FIXME - can we code this method more efficiently?  */
	RETVAL = PTR2IV(sv);
    OUTPUT:
        RETVAL

SV*
precomp(sv)
	B::REGEXP	sv
    CODE:
	RETVAL = newSVpvn( RX_PRECOMP(sv), RX_PRELEN(sv) );
    OUTPUT:
        RETVAL

#endif

#define MgMOREMAGIC(mg) mg->mg_moremagic
#define MgPRIVATE(mg) mg->mg_private
#define MgTYPE(mg) mg->mg_type
#define MgFLAGS(mg) mg->mg_flags
#define MgOBJ(mg) mg->mg_obj
#define MgLENGTH(mg) mg->mg_len
#define MgREGEX(mg) PTR2IV(mg->mg_obj)

MODULE = B	PACKAGE = B::MAGIC	PREFIX = Mg	

B::MAGIC
MgMOREMAGIC(mg)
	B::MAGIC	mg
     CODE:
	if( MgMOREMAGIC(mg) ) {
	    RETVAL = MgMOREMAGIC(mg);
	}
	else {
	    XSRETURN_UNDEF;
	}
     OUTPUT:
	RETVAL

U16
MgPRIVATE(mg)
	B::MAGIC	mg

char
MgTYPE(mg)
	B::MAGIC	mg

U8
MgFLAGS(mg)
	B::MAGIC	mg

B::SV
MgOBJ(mg)
	B::MAGIC	mg

IV
MgREGEX(mg)
	B::MAGIC	mg
    CODE:
        if(mg->mg_type == PERL_MAGIC_qr) {
            RETVAL = MgREGEX(mg);
        }
        else {
            croak( "REGEX is only meaningful on r-magic" );
        }
    OUTPUT:
        RETVAL

SV*
precomp(mg)
        B::MAGIC        mg
    CODE:
        if (mg->mg_type == PERL_MAGIC_qr) {
            REGEXP* rx = (REGEXP*)mg->mg_obj;
            RETVAL = Nullsv;
            if( rx )
                RETVAL = newSVpvn( RX_PRECOMP(rx), RX_PRELEN(rx) );
        }
        else {
            croak( "precomp is only meaningful on r-magic" );
        }
    OUTPUT:
        RETVAL

I32 
MgLENGTH(mg)
	B::MAGIC	mg
 
void
MgPTR(mg)
	B::MAGIC	mg
    CODE:
 	if (mg->mg_ptr){
		if (mg->mg_len >= 0){
	    		ST(0) = newSVpvn_flags(mg->mg_ptr, mg->mg_len, SVs_TEMP);
		} else if (mg->mg_len == HEf_SVKEY) {
			ST(0) = make_sv_object(aTHX_ NULL, (SV*)mg->mg_ptr);
		} else
		    ST(0) = sv_newmortal();
	} else
	    ST(0) = sv_newmortal();

MODULE = B	PACKAGE = B::PVLV	PREFIX = Lv

U32
LvTARGOFF(sv)
	B::PVLV	sv

U32
LvTARGLEN(sv)
	B::PVLV	sv

char
LvTYPE(sv)
	B::PVLV	sv

B::SV
LvTARG(sv)
	B::PVLV sv

MODULE = B	PACKAGE = B::BM		PREFIX = Bm

I32
BmUSEFUL(sv)
	B::BM	sv

U32
BmPREVIOUS(sv)
	B::BM	sv

U8
BmRARE(sv)
	B::BM	sv

void
BmTABLE(sv)
	B::BM	sv
	STRLEN	len = NO_INIT
	char *	str = NO_INIT
    CODE:
	str = SvPV(sv, len);
	/* Boyer-Moore table is just after string and its safety-margin \0 */
	ST(0) = newSVpvn_flags(str + len + PERL_FBM_TABLE_OFFSET, 256, SVs_TEMP);

MODULE = B	PACKAGE = B::GV		PREFIX = Gv

void
GvNAME(gv)
	B::GV	gv
    CODE:
#if PERL_VERSION >= 10
	ST(0) = sv_2mortal(newSVhek(GvNAME_HEK(gv)));
#else
	ST(0) = newSVpvn_flags(GvNAME(gv), GvNAMELEN(gv), SVs_TEMP);
#endif

bool
is_empty(gv)
        B::GV   gv
    ALIAS:
	isGV_with_GP = 1
    CODE:
	if (ix) {
#if PERL_VERSION >= 9
	    RETVAL = isGV_with_GP(gv) ? TRUE : FALSE;
#else
	    RETVAL = TRUE; /* In 5.8 and earlier they all are.  */
#endif
	} else {
            RETVAL = GvGP(gv) == Null(GP*);
	}
    OUTPUT:
        RETVAL

void*
GvGP(gv)
	B::GV	gv

B::HV
GvSTASH(gv)
	B::GV	gv

B::SV
GvSV(gv)
	B::GV	gv

B::IO
GvIO(gv)
	B::GV	gv

B::FM
GvFORM(gv)
	B::GV	gv
    CODE:
	RETVAL = (SV*)GvFORM(gv);
    OUTPUT:
	RETVAL

B::AV
GvAV(gv)
	B::GV	gv

B::HV
GvHV(gv)
	B::GV	gv

B::GV
GvEGV(gv)
	B::GV	gv

B::CV
GvCV(gv)
	B::GV	gv

U32
GvCVGEN(gv)
	B::GV	gv

U32
GvLINE(gv)
	B::GV	gv

char *
GvFILE(gv)
	B::GV	gv

B::GV
GvFILEGV(gv)
	B::GV	gv

MODULE = B	PACKAGE = B::GV

U32
GvREFCNT(gv)
	B::GV	gv

U8
GvFLAGS(gv)
	B::GV	gv

MODULE = B	PACKAGE = B::IO		PREFIX = Io

long
IoLINES(io)
	B::IO	io

long
IoPAGE(io)
	B::IO	io

long
IoPAGE_LEN(io)
	B::IO	io

long
IoLINES_LEFT(io)
	B::IO	io

char *
IoTOP_NAME(io)
	B::IO	io

B::GV
IoTOP_GV(io)
	B::IO	io

char *
IoFMT_NAME(io)
	B::IO	io

B::GV
IoFMT_GV(io)
	B::IO	io

char *
IoBOTTOM_NAME(io)
	B::IO	io

B::GV
IoBOTTOM_GV(io)
	B::IO	io

#if PERL_VERSION <= 8

short
IoSUBPROCESS(io)
	B::IO	io

#endif

bool
IsSTD(io,name)
	B::IO	io
	const char*	name
    PREINIT:
	PerlIO* handle = 0;
    CODE:
	if( strEQ( name, "stdin" ) ) {
	    handle = PerlIO_stdin();
	}
	else if( strEQ( name, "stdout" ) ) {
	    handle = PerlIO_stdout();
	}
	else if( strEQ( name, "stderr" ) ) {
	    handle = PerlIO_stderr();
	}
	else {
	    croak( "Invalid value '%s'", name );
	}
	RETVAL = handle == IoIFP(io);
    OUTPUT:
	RETVAL

MODULE = B	PACKAGE = B::IO

char
IoTYPE(io)
	B::IO	io

U8
IoFLAGS(io)
	B::IO	io

MODULE = B	PACKAGE = B::AV		PREFIX = Av

SSize_t
AvFILL(av)
	B::AV	av

SSize_t
AvMAX(av)
	B::AV	av

void
AvARRAY(av)
	B::AV	av
    PPCODE:
	if (AvFILL(av) >= 0) {
	    SV **svp = AvARRAY(av);
	    I32 i;
	    for (i = 0; i <= AvFILL(av); i++)
		XPUSHs(make_sv_object(aTHX_ NULL, svp[i]));
	}

void
AvARRAYelt(av, idx)
	B::AV	av
	int	idx
    PPCODE:
    	if (idx >= 0 && AvFILL(av) >= 0 && idx <= AvFILL(av))
	    XPUSHs(make_sv_object(aTHX_ NULL, (AvARRAY(av)[idx])));
	else
	    XPUSHs(make_sv_object(aTHX_ NULL, NULL));

#if PERL_VERSION < 9
				   
#define AvOFF(av) ((XPVAV*)SvANY(av))->xof_off

IV
AvOFF(av)
	B::AV	av

MODULE = B	PACKAGE = B::AV

U8
AvFLAGS(av)
	B::AV	av

#endif

MODULE = B	PACKAGE = B::FM		PREFIX = Fm

IV
FmLINES(form)
	B::FM	form

MODULE = B	PACKAGE = B::CV		PREFIX = Cv

U32
CvCONST(cv)
	B::CV	cv

B::HV
CvSTASH(cv)
	B::CV	cv

B::OP
CvSTART(cv)
	B::CV	cv
    ALIAS:
	ROOT = 1
    CODE:
	RETVAL = CvISXSUB(cv) ? NULL : ix ? CvROOT(cv) : CvSTART(cv);
    OUTPUT:
	RETVAL

B::GV
CvGV(cv)
	B::CV	cv

char *
CvFILE(cv)
	B::CV	cv

long
CvDEPTH(cv)
	B::CV	cv

B::AV
CvPADLIST(cv)
	B::CV	cv

B::CV
CvOUTSIDE(cv)
	B::CV	cv

U32
CvOUTSIDE_SEQ(cv)
	B::CV	cv

void
CvXSUB(cv)
	B::CV	cv
    CODE:
	ST(0) = sv_2mortal(newSViv(CvISXSUB(cv) ? PTR2IV(CvXSUB(cv)) : 0));


void
CvXSUBANY(cv)
	B::CV	cv
    CODE:
	ST(0) = CvCONST(cv)
	    ? make_sv_object(aTHX_ NULL, (SV *)CvXSUBANY(cv).any_ptr)
	    : sv_2mortal(newSViv(CvISXSUB(cv) ? CvXSUBANY(cv).any_iv : 0));

MODULE = B    PACKAGE = B::CV

U16
CvFLAGS(cv)
      B::CV   cv

MODULE = B	PACKAGE = B::CV		PREFIX = cv_

B::SV
cv_const_sv(cv)
	B::CV	cv


MODULE = B	PACKAGE = B::HV		PREFIX = Hv

STRLEN
HvFILL(hv)
	B::HV	hv

STRLEN
HvMAX(hv)
	B::HV	hv

I32
HvKEYS(hv)
	B::HV	hv

I32
HvRITER(hv)
	B::HV	hv

char *
HvNAME(hv)
	B::HV	hv

#if PERL_VERSION < 9

B::PMOP
HvPMROOT(hv)
	B::HV	hv

#endif

void
HvARRAY(hv)
	B::HV	hv
    PPCODE:
	if (HvKEYS(hv) > 0) {
	    SV *sv;
	    char *key;
	    I32 len;
	    (void)hv_iterinit(hv);
	    EXTEND(sp, HvKEYS(hv) * 2);
	    while ((sv = hv_iternextsv(hv, &key, &len))) {
		mPUSHp(key, len);
		PUSHs(make_sv_object(aTHX_ NULL, sv));
	    }
	}

MODULE = B	PACKAGE = B::HE		PREFIX = He

B::SV
HeVAL(he)
	B::HE he

U32
HeHASH(he)
	B::HE he

B::SV
HeSVKEY_force(he)
	B::HE he

MODULE = B	PACKAGE = B::RHE	PREFIX = RHE_

#if PERL_VERSION >= 9

SV*
RHE_HASH(h)
	B::RHE h
    CODE:
	RETVAL = newRV( (SV*)cophh_2hv(h, 0) );
    OUTPUT:
	RETVAL

#endif
