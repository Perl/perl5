#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = File::DosGlob		PACKAGE = File::DosGlob

PROTOTYPES: DISABLE

SV *
_callsite(...)
    CODE:
	RETVAL = newSVpvn(
		   (char *)&cxstack[cxstack_ix].blk_sub.retop, sizeof(OP *)
		 );
    OUTPUT:
	RETVAL
