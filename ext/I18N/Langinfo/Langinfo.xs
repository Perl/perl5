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
	char *s = nl_langinfo(code);
	RETVAL = newSVpvn(s, strlen(s));
#else
	croak("nl_langinfo() not implemented on this architecture");
#endif
  OUTPUT:
	RETVAL
