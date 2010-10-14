#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* These are tightly coupled to the RXapif_* flags defined in regexp.h  */
#define UNDEF_FATAL  0x80000
#define DISCARD      0x40000
#define EXPECT_SHIFT 24
#define ACTION_MASK  0x000FF

#define FETCH_ALIAS  (RXapif_FETCH  | (2 << EXPECT_SHIFT))
#define STORE_ALIAS  (RXapif_STORE  | (3 << EXPECT_SHIFT) | UNDEF_FATAL | DISCARD)
#define DELETE_ALIAS (RXapif_DELETE | (2 << EXPECT_SHIFT) | UNDEF_FATAL)
#define CLEAR_ALIAS  (RXapif_CLEAR  | (1 << EXPECT_SHIFT) | UNDEF_FATAL | DISCARD)
#define EXISTS_ALIAS (RXapif_EXISTS | (2 << EXPECT_SHIFT))
#define SCALAR_ALIAS (RXapif_SCALAR | (1 << EXPECT_SHIFT))

MODULE = Tie::Hash::NamedCapture	PACKAGE = Tie::Hash::NamedCapture
PROTOTYPES: DISABLE

void
FETCH(...)
    ALIAS:
	Tie::Hash::NamedCapture::FETCH  = FETCH_ALIAS
	Tie::Hash::NamedCapture::STORE  = STORE_ALIAS
	Tie::Hash::NamedCapture::DELETE = DELETE_ALIAS
	Tie::Hash::NamedCapture::CLEAR  = CLEAR_ALIAS
	Tie::Hash::NamedCapture::EXISTS = EXISTS_ALIAS
	Tie::Hash::NamedCapture::SCALAR = SCALAR_ALIAS
    PREINIT:
	REGEXP *const rx = PL_curpm ? PM_GETRE(PL_curpm) : NULL;
	U32 flags;
	SV *ret;
	const U32 action = ix & ACTION_MASK;
	const int expect = ix >> EXPECT_SHIFT;
    PPCODE:
	if (items != expect)
	    croak_xs_usage(cv, expect == 2 ? "$key"
				           : (expect == 3 ? "$key, $value"
							  : ""));

	if (!rx || !SvROK(ST(0))) {
	    if (ix & UNDEF_FATAL)
		Perl_croak_no_modify(aTHX);
	    else
		XSRETURN_UNDEF;
	}

	flags = (U32)SvUV(SvRV(MUTABLE_SV(ST(0))));

	PUTBACK;
	ret = RX_ENGINE(rx)->named_buff(aTHX_ (rx), expect >= 2 ? ST(1) : NULL,
				    expect >= 3 ? ST(2) : NULL, flags | action);
	SPAGAIN;

	if (ix & DISCARD) {
	    /* Called with G_DISCARD, so our return stack state is thrown away.
	       Hence if we were returned anything, free it immediately.  */
	    SvREFCNT_dec(ret);
	} else {
	    PUSHs(ret ? sv_2mortal(ret) : &PL_sv_undef);
	}

void
FIRSTKEY(...)
    ALIAS:
	Tie::Hash::NamedCapture::NEXTKEY = 1
    PREINIT:
	REGEXP *const rx = PL_curpm ? PM_GETRE(PL_curpm) : NULL;
	U32 flags;
	SV *ret;
	const int expect = ix ? 2 : 1;
	const U32 action = ix ? RXapif_NEXTKEY : RXapif_FIRSTKEY;
    PPCODE:
	if (items != expect)
	    croak_xs_usage(cv, expect == 2 ? "$lastkey" : "");

	if (!rx || !SvROK(ST(0)))
	    XSRETURN_UNDEF;

	flags = (U32)SvUV(SvRV(MUTABLE_SV(ST(0))));

	PUTBACK;
	ret = RX_ENGINE(rx)->named_buff_iter(aTHX_ (rx),
					     expect >= 2 ? ST(1) : NULL,
					     flags | action);
	SPAGAIN;

	PUSHs(ret ? sv_2mortal(ret) : &PL_sv_undef);

void
flags(...)
    PPCODE:
	EXTEND(SP, 2);
	mPUSHu(RXapif_ONE);
	mPUSHu(RXapif_ALL);

