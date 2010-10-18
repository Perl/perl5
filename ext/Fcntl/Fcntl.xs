#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef VMS
#  include <file.h>
#else
#if defined(__GNUC__) && defined(__cplusplus) && defined(WIN32)
#define _NO_OLDNAMES
#endif 
#  include <fcntl.h>
#if defined(__GNUC__) && defined(__cplusplus) && defined(WIN32)
#undef _NO_OLDNAMES
#endif 
#endif

#ifdef I_UNISTD
#include <unistd.h>
#endif

/* This comment is a kludge to get metaconfig to see the symbols
    VAL_O_NONBLOCK
    VAL_EAGAIN
    RD_NODATA
    EOF_NONBLOCK
   and include the appropriate metaconfig unit
   so that Configure will test how to turn on non-blocking I/O
   for a file descriptor.  See config.h for how to use these
   in your extension. 
   
   While I'm at it, I'll have metaconfig look for HAS_POLL too.
   --AD  October 16, 1995
*/

#include "const-c.inc"

MODULE = Fcntl		PACKAGE = Fcntl

INCLUDE: const-xs.inc

void
S_ISREG(...)
    ALIAS:
	Fcntl::S_ISREG = S_IFREG
	Fcntl::S_ISDIR = S_IFDIR
    PREINIT:
	/* Preserve the semantics of the perl code, which was:
	   sub S_ISREG    { ( $_[0] & _S_IFMT() ) == S_IFREG()   }
	 */
	SV *mode;
    PPCODE:
	if (items > 0)
	    mode = ST(0);
	else {
	    mode = &PL_sv_undef;
	    EXTEND(SP, 1);
	}
	PUSHs(((SvUV(mode) & S_IFMT) == ix) ? &PL_sv_yes : &PL_sv_no);
