#define PERL_IN_XS_APITEST
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* for my_cxt tests */

#define MY_CXT_KEY "XS::APItest::_guts" XS_VERSION

typedef struct {
    int i;
    SV *sv;
} my_cxt_t;

START_MY_CXT

/* indirect functions to test the [pa]MY_CXT macros */

int
my_cxt_getint_p(pMY_CXT)
{
    return MY_CXT.i;
}

void
my_cxt_setint_p(pMY_CXT_ int i)
{
    MY_CXT.i = i;
}

SV*
my_cxt_getsv_interp(void)
{
#ifdef PERL_IMPLICIT_CONTEXT
    dTHX;
    dMY_CXT_INTERP(my_perl);
#else
    dMY_CXT;
#endif
    return MY_CXT.sv;
}

void
my_cxt_setsv_p(SV* sv _pMY_CXT)
{
    MY_CXT.sv = sv;
}


/* from exception.c */
int exception(int);

/* A routine to test hv_delayfree_ent
   (which itself is tested by testing on hv_free_ent  */

typedef void (freeent_function)(pTHX_ HV *, register HE *);

void
test_freeent(freeent_function *f) {
    dTHX;
    dSP;
    HV *test_hash = newHV();
    HE *victim;
    SV *test_scalar;
    U32 results[4];
    int i;

#ifdef PURIFY
    victim = (HE*)safemalloc(sizeof(HE));
#else
    /* Storing then deleting something should ensure that a hash entry is
       available.  */
    hv_store(test_hash, "", 0, &PL_sv_yes, 0);
    hv_delete(test_hash, "", 0, 0);

    /* We need to "inline" new_he here as it's static, and the functions we
       test expect to be able to call del_HE on the HE  */
    if (!PL_body_roots[HE_SVSLOT])
	croak("PL_he_root is 0");
    victim = (HE*) PL_body_roots[HE_SVSLOT];
    PL_body_roots[HE_SVSLOT] = HeNEXT(victim);
#endif

    victim->hent_hek = Perl_share_hek(aTHX_ "", 0, 0);

    test_scalar = newSV(0);
    SvREFCNT_inc(test_scalar);
    HeVAL(victim) = test_scalar;

    /* Need this little game else we free the temps on the return stack.  */
    results[0] = SvREFCNT(test_scalar);
    SAVETMPS;
    results[1] = SvREFCNT(test_scalar);
    f(aTHX_ test_hash, victim);
    results[2] = SvREFCNT(test_scalar);
    FREETMPS;
    results[3] = SvREFCNT(test_scalar);

    i = 0;
    do {
	mPUSHu(results[i]);
    } while (++i < sizeof(results)/sizeof(results[0]));

    /* Goodbye to our extra reference.  */
    SvREFCNT_dec(test_scalar);
}

MODULE = XS::APItest:Hash		PACKAGE = XS::APItest::Hash

#define UTF8KLEN(sv, len)   (SvUTF8(sv) ? -(I32)len : (I32)len)

bool
exists(hash, key_sv)
	PREINIT:
	STRLEN len;
	const char *key;
	INPUT:
	HV *hash
	SV *key_sv
	CODE:
	key = SvPV(key_sv, len);
	RETVAL = hv_exists(hash, key, UTF8KLEN(key_sv, len));
        OUTPUT:
        RETVAL

SV *
delete(hash, key_sv)
	PREINIT:
	STRLEN len;
	const char *key;
	INPUT:
	HV *hash
	SV *key_sv
	CODE:
	key = SvPV(key_sv, len);
	/* It's already mortal, so need to increase reference count.  */
	RETVAL = SvREFCNT_inc(hv_delete(hash, key, UTF8KLEN(key_sv, len), 0));
        OUTPUT:
        RETVAL

SV *
store_ent(hash, key, value)
	PREINIT:
	SV *copy;
	HE *result;
	INPUT:
	HV *hash
	SV *key
	SV *value
	CODE:
	copy = newSV(0);
	result = hv_store_ent(hash, key, copy, 0);
	SvSetMagicSV(copy, value);
	if (!result) {
	    SvREFCNT_dec(copy);
	    XSRETURN_EMPTY;
	}
	/* It's about to become mortal, so need to increase reference count.
	 */
	RETVAL = SvREFCNT_inc(HeVAL(result));
        OUTPUT:
        RETVAL


SV *
store(hash, key_sv, value)
	PREINIT:
	STRLEN len;
	const char *key;
	SV *copy;
	SV **result;
	INPUT:
	HV *hash
	SV *key_sv
	SV *value
	CODE:
	key = SvPV(key_sv, len);
	copy = newSV(0);
	result = hv_store(hash, key, UTF8KLEN(key_sv, len), copy, 0);
	SvSetMagicSV(copy, value);
	if (!result) {
	    SvREFCNT_dec(copy);
	    XSRETURN_EMPTY;
	}
	/* It's about to become mortal, so need to increase reference count.
	 */
	RETVAL = SvREFCNT_inc(*result);
        OUTPUT:
        RETVAL


SV *
fetch(hash, key_sv)
	PREINIT:
	STRLEN len;
	const char *key;
	SV **result;
	INPUT:
	HV *hash
	SV *key_sv
	CODE:
	key = SvPV(key_sv, len);
	result = hv_fetch(hash, key, UTF8KLEN(key_sv, len), 0);
	if (!result) {
	    XSRETURN_EMPTY;
	}
	/* Force mg_get  */
	RETVAL = newSVsv(*result);
        OUTPUT:
        RETVAL

void
test_hv_free_ent()
	PPCODE:
	test_freeent(&Perl_hv_free_ent);
	XSRETURN(4);

void
test_hv_delayfree_ent()
	PPCODE:
	test_freeent(&Perl_hv_delayfree_ent);
	XSRETURN(4);

SV *
test_share_unshare_pvn(input)
	PREINIT:
	STRLEN len;
	U32 hash;
	char *pvx;
	char *p;
	INPUT:
	SV *input
	CODE:
	pvx = SvPV(input, len);
	PERL_HASH(hash, pvx, len);
	p = sharepvn(pvx, len, hash);
	RETVAL = newSVpvn(p, len);
	unsharepvn(p, len, hash);
	OUTPUT:
	RETVAL

bool
refcounted_he_exists(key, level=0)
	SV *key
	IV level
	CODE:
	if (level) {
	    croak("level must be zero, not %"IVdf, level);
	}
	RETVAL = (Perl_refcounted_he_fetch(aTHX_ PL_curcop->cop_hints_hash,
					   key, NULL, 0, 0, 0)
		  != &PL_sv_placeholder);
	OUTPUT:
	RETVAL


SV *
refcounted_he_fetch(key, level=0)
	SV *key
	IV level
	CODE:
	if (level) {
	    croak("level must be zero, not %"IVdf, level);
	}
	RETVAL = Perl_refcounted_he_fetch(aTHX_ PL_curcop->cop_hints_hash, key,
					  NULL, 0, 0, 0);
	SvREFCNT_inc(RETVAL);
	OUTPUT:
	RETVAL
	
	
=pod

sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }

=cut

MODULE = XS::APItest		PACKAGE = XS::APItest

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.i  = 99;
    MY_CXT.sv = newSVpv("initial",0);
}                              

void
CLONE(...)
    CODE:
    MY_CXT_CLONE;
    MY_CXT.sv = newSVpv("initial_clone",0);

void
print_double(val)
        double val
        CODE:
        printf("%5.3f\n",val);

int
have_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
        RETVAL = 1;
#else
        RETVAL = 0;
#endif
        OUTPUT:
        RETVAL

void
print_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
#   if defined(PERL_PRIfldbl) && (LONG_DOUBLESIZE > DOUBLESIZE)
        long double val = 7.0;
        printf("%5.3" PERL_PRIfldbl "\n",val);
#   else
        double val = 7.0;
        printf("%5.3f\n",val);
#   endif
#endif

void
print_int(val)
        int val
        CODE:
        printf("%d\n",val);

void
print_long(val)
        long val
        CODE:
        printf("%ld\n",val);

void
print_float(val)
        float val
        CODE:
        printf("%5.3f\n",val);
	
void
print_flush()
    	CODE:
	fflush(stdout);

void
mpushp()
	PPCODE:
	EXTEND(SP, 3);
	mPUSHp("one", 3);
	mPUSHp("two", 3);
	mPUSHp("three", 5);
	XSRETURN(3);

void
mpushn()
	PPCODE:
	EXTEND(SP, 3);
	mPUSHn(0.5);
	mPUSHn(-0.25);
	mPUSHn(0.125);
	XSRETURN(3);

void
mpushi()
	PPCODE:
	EXTEND(SP, 3);
	mPUSHi(-1);
	mPUSHi(2);
	mPUSHi(-3);
	XSRETURN(3);

void
mpushu()
	PPCODE:
	EXTEND(SP, 3);
	mPUSHu(1);
	mPUSHu(2);
	mPUSHu(3);
	XSRETURN(3);

void
mxpushp()
	PPCODE:
	mXPUSHp("one", 3);
	mXPUSHp("two", 3);
	mXPUSHp("three", 5);
	XSRETURN(3);

void
mxpushn()
	PPCODE:
	mXPUSHn(0.5);
	mXPUSHn(-0.25);
	mXPUSHn(0.125);
	XSRETURN(3);

void
mxpushi()
	PPCODE:
	mXPUSHi(-1);
	mXPUSHi(2);
	mXPUSHi(-3);
	XSRETURN(3);

void
mxpushu()
	PPCODE:
	mXPUSHu(1);
	mXPUSHu(2);
	mXPUSHu(3);
	XSRETURN(3);


void
call_sv(sv, flags, ...)
    SV* sv
    I32 flags
    PREINIT:
	I32 i;
    PPCODE:
	for (i=0; i<items-2; i++)
	    ST(i) = ST(i+2); /* pop first two args */
	PUSHMARK(SP);
	SP += items - 2;
	PUTBACK;
	i = call_sv(sv, flags);
	SPAGAIN;
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSViv(i)));

void
call_pv(subname, flags, ...)
    char* subname
    I32 flags
    PREINIT:
	I32 i;
    PPCODE:
	for (i=0; i<items-2; i++)
	    ST(i) = ST(i+2); /* pop first two args */
	PUSHMARK(SP);
	SP += items - 2;
	PUTBACK;
	i = call_pv(subname, flags);
	SPAGAIN;
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSViv(i)));

void
call_method(methname, flags, ...)
    char* methname
    I32 flags
    PREINIT:
	I32 i;
    PPCODE:
	for (i=0; i<items-2; i++)
	    ST(i) = ST(i+2); /* pop first two args */
	PUSHMARK(SP);
	SP += items - 2;
	PUTBACK;
	i = call_method(methname, flags);
	SPAGAIN;
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSViv(i)));

void
eval_sv(sv, flags)
    SV* sv
    I32 flags
    PREINIT:
    	I32 i;
    PPCODE:
	PUTBACK;
	i = eval_sv(sv, flags);
	SPAGAIN;
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSViv(i)));

void
eval_pv(p, croak_on_error)
    const char* p
    I32 croak_on_error
    PPCODE:
	PUTBACK;
	EXTEND(SP, 1);
	PUSHs(eval_pv(p, croak_on_error));

void
require_pv(pv)
    const char* pv
    PPCODE:
	PUTBACK;
	require_pv(pv);

int
exception(throw_e)
    int throw_e
    OUTPUT:
        RETVAL

void
mycroak(sv)
    SV* sv
    CODE:
    if (SvOK(sv)) {
        Perl_croak(aTHX_ "%s", SvPV_nolen(sv));
    }
    else {
	Perl_croak(aTHX_ NULL);
    }

SV*
strtab()
   CODE:
   RETVAL = newRV_inc((SV*)PL_strtab);
   OUTPUT:
   RETVAL

int
my_cxt_getint()
    CODE:
	dMY_CXT;
	RETVAL = my_cxt_getint_p(aMY_CXT);
    OUTPUT:
        RETVAL

void
my_cxt_setint(i)
    int i;
    CODE:
	dMY_CXT;
	my_cxt_setint_p(aMY_CXT_ i);

void
my_cxt_getsv()
    PPCODE:
	EXTEND(SP, 1);
	ST(0) = my_cxt_getsv_interp();
	XSRETURN(1);

void
my_cxt_setsv(sv)
    SV *sv;
    CODE:
	dMY_CXT;
	SvREFCNT_dec(MY_CXT.sv);
	my_cxt_setsv_p(sv _aMY_CXT);
	SvREFCNT_inc(sv);

bool
sv_setsv_cow_hashkey_core()

bool
sv_setsv_cow_hashkey_notcore()
