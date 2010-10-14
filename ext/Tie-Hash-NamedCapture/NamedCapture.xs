#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Tie::Hash::NamedCapture	PACKAGE = Tie::Hash::NamedCapture
PROTOTYPES: DISABLE

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

