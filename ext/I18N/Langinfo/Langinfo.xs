#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_LANGINFO
#   include <langinfo.h>
#endif

#include "constants.c"

MODULE = I18N::Langinfo	PACKAGE = I18N::Langinfo

PROTOTYPES: ENABLE

INCLUDE: constants.xs

SV*
langinfo(code)
	int	code
  CODE:
#ifdef HAS_NL_LANGINFO
	char *s;
	if (code > 0) { /* bold assumption: all valid langinfo codes > 0 */
#ifdef _MAXSTRMSG
	    if (code >= _MAXSTRMSG
	        RETVAL = &PL_sv_undef;
	    else
#else
#   ifdef _NL_NUM_ITEMS
	    if (code >= _NL_NUM_ITEMS)
	        RETVAL = &PL_sv_undef;
	    else
#   else
#       ifdef _NL_NUM
	    if (code >= _NL_NUM)
	        RETVAL = &PL_sv_undef;
	    else
#       endif
#   endif
#endif
	    {
	        s = nl_langinfo(code);
		RETVAL = newSVpvn(s, strlen(s));
	    }
	} else {
	    RETVAL = &PL_sv_undef;
	}
#else
	croak("nl_langinfo() not implemented on this architecture");
#endif
  OUTPUT:
	RETVAL
