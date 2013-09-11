#include "ppport.h"

/* The MUTABLE_*() macros cast pointers to the types shown, in such a way
 * (compiler permitting) that casting away const-ness will give a warning;
 * e.g.:
 *
 * const SV *sv = ...;
 * AV *av1 = (AV*)sv;        <== BAD:  the const has been silently cast away
 * AV *av2 = MUTABLE_AV(sv); <== GOOD: it may warn
 */

#ifndef MUTABLE_PTR
#  if defined(__GNUC__) && !defined(PERL_GCC_BRACE_GROUPS_FORBIDDEN)
#    define MUTABLE_PTR(p) ({ void *_p = (p); _p; })
#  else
#    define MUTABLE_PTR(p) ((void *) (p))
#  endif

#  define MUTABLE_AV(p)	((AV *)MUTABLE_PTR(p))
#  define MUTABLE_CV(p)	((CV *)MUTABLE_PTR(p))
#  define MUTABLE_GV(p)	((GV *)MUTABLE_PTR(p))
#  define MUTABLE_HV(p)	((HV *)MUTABLE_PTR(p))
#  define MUTABLE_IO(p)	((IO *)MUTABLE_PTR(p))
#  define MUTABLE_SV(p)	((SV *)MUTABLE_PTR(p))
#endif

#ifndef SvPVx_nolen_const
#  if defined(__GNUC__) && !defined(PERL_GCC_BRACE_GROUPS_FORBIDDEN)
#    define SvPVx_nolen_const(sv) ({SV *_sv = (sv); SvPV_nolen_const(_sv); })
#  else
#    define SvPVx_nolen_const(sv) (SvPV_nolen_const(sv))
#  endif
#endif

#ifndef PERL_ARGS_ASSERT_CK_WARNER
static void Perl_ck_warner(pTHX_ U32 err, const char* pat, ...);

#  ifdef vwarner
static
void
Perl_ck_warner(pTHX_ U32 err, const char* pat, ...)
{
  va_list args;

  PERL_UNUSED_ARG(err);
  if (ckWARN(err)) {
    va_list args;
    va_start(args, pat);
    vwarner(err, pat, &args);
    va_end(args);
  }
}
#  else
/* yes this replicates my_warner */
static
void
Perl_ck_warner(pTHX_ U32 err, const char* pat, ...)
{
  SV *sv;
  va_list args;

  PERL_UNUSED_ARG(err);

  va_start(args, pat);
  sv = vnewSVpvf(pat, &args);
  va_end(args);
  sv_2mortal(sv);
  warn("%s", SvPV_nolen(sv));
}
#  endif
#endif

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_LT(r,v,s) \
	(PERL_DECIMAL_VERSION < PERL_VERSION_DECIMAL(r,v,s))
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#define ISA_CLASS_OBJ(v,c) (sv_isobject(v) && sv_derived_from(v,c))

#if PERL_VERSION_GE(5,9,0)

#  define VUTIL_REPLACE_CORE 1

const char * Perl_scan_version2(pTHX_ const char *s, SV *rv, bool qv);
SV * Perl_new_version2(pTHX_ SV *ver);
SV * Perl_upg_version2(pTHX_ SV *sv, bool qv);
SV * Perl_vstringify2(pTHX_ SV *vs);
SV * Perl_vverify2(pTHX_ SV *vs);
SV * Perl_vnumify2(pTHX_ SV *vs);
SV * Perl_vnormal2(pTHX_ SV *vs);
SV * Perl_vstringify2(pTHX_ SV *vs);
int Perl_vcmp2(pTHX_ SV *lsv, SV *rsv);
const char * Perl_prescan_version2(pTHX_ const char *s, bool strict, const char** errstr, bool *sqv, int *ssaw_decimal, int *swidth, bool *salpha);

#  define SCAN_VERSION(a,b,c)	Perl_scan_version2(aTHX_ a,b,c)
#  define NEW_VERSION(a)	Perl_new_version2(aTHX_ a)
#  define UPG_VERSION(a,b)	Perl_upg_version2(aTHX_ a, b)
#  define VSTRINGIFY(a)		Perl_vstringify2(aTHX_ a)
#  define VVERIFY(a)		Perl_vverify2(aTHX_ a)
#  define VNUMIFY(a)		Perl_vnumify2(aTHX_ a)
#  define VNORMAL(a)		Perl_vnormal2(aTHX_ a)
#  define VCMP(a,b)		Perl_vcmp2(aTHX_ a,b)
#  define PRESCAN_VERSION(a,b,c,d,e,f,g)	Perl_prescan_version2(aTHX_ a,b,c,d,e,f,g)
#  define is_LAX_VERSION(a,b) \
	(a != Perl_prescan_version2(aTHX_ a, FALSE, b, NULL, NULL, NULL, NULL))
#  define is_STRICT_VERSION(a,b) \
	(a != Perl_prescan_version2(aTHX_ a, TRUE, b, NULL, NULL, NULL, NULL))

#else

const char * Perl_scan_version(pTHX_ const char *s, SV *rv, bool qv);
SV * Perl_new_version(pTHX_ SV *ver);
SV * Perl_upg_version(pTHX_ SV *sv, bool qv);
SV * Perl_vverify(pTHX_ SV *vs);
SV * Perl_vnumify(pTHX_ SV *vs);
SV * Perl_vnormal(pTHX_ SV *vs);
SV * Perl_vstringify(pTHX_ SV *vs);
int Perl_vcmp(pTHX_ SV *lsv, SV *rsv);
const char * Perl_prescan_version(pTHX_ const char *s, bool strict, const char** errstr, bool *sqv, int *ssaw_decimal, int *swidth, bool *salpha);

#  define SCAN_VERSION(a,b,c)	Perl_scan_version(aTHX_ a,b,c)
#  define NEW_VERSION(a)	Perl_new_version(aTHX_ a)
#  define UPG_VERSION(a,b)	Perl_upg_version(aTHX_ a, b)
#  define VSTRINGIFY(a)		Perl_vstringify(aTHX_ a)
#  define VVERIFY(a)		Perl_vverify(aTHX_ a)
#  define VNUMIFY(a)		Perl_vnumify(aTHX_ a)
#  define VNORMAL(a)		Perl_vnormal(aTHX_ a)
#  define VCMP(a,b)		Perl_vcmp(aTHX_ a,b)

#  define PRESCAN_VERSION(a,b,c,d,e,f,g)	Perl_prescan_version(aTHX_ a,b,c,d,e,f,g)
#  define is_LAX_VERSION(a,b) \
	(a != Perl_prescan_version(aTHX_ a, FALSE, b, NULL, NULL, NULL, NULL))
#  define is_STRICT_VERSION(a,b) \
	(a != Perl_prescan_version(aTHX_ a, TRUE, b, NULL, NULL, NULL, NULL))

#endif

#if PERL_VERSION_LT(5,11,4)
#  define BADVERSION(a,b,c) \
	if (b) { \
	    *b = c; \
	} \
	return a;

#  define PERL_ARGS_ASSERT_PRESCAN_VERSION	\
	assert(s); assert(sqv); assert(ssaw_decimal);\
	assert(swidth); assert(salpha);

#  define PERL_ARGS_ASSERT_SCAN_VERSION	\
	assert(s); assert(rv)
#  define PERL_ARGS_ASSERT_NEW_VERSION	\
	assert(ver)
#  define PERL_ARGS_ASSERT_UPG_VERSION	\
	assert(ver)
#  define PERL_ARGS_ASSERT_VVERIFY	\
	assert(vs)
#  define PERL_ARGS_ASSERT_VNUMIFY	\
	assert(vs)
#  define PERL_ARGS_ASSERT_VNORMAL	\
	assert(vs)
#  define PERL_ARGS_ASSERT_VSTRINGIFY	\
	assert(vs)
#  define PERL_ARGS_ASSERT_VCMP	\
	assert(lhv); assert(rhv)
#  define PERL_ARGS_ASSERT_CK_WARNER      \
	assert(pat)
#endif
