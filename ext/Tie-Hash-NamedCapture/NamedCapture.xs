#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Tie::Hash::NamedCapture	PACKAGE = Tie::Hash::NamedCapture
PROTOTYPES: DISABLE

void
flags(...)
    PPCODE:
	EXTEND(SP, 2);
	mPUSHu(RXapif_ONE);
	mPUSHu(RXapif_ALL);

