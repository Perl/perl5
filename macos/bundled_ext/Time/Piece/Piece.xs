#ifdef __cplusplus
#extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <time.h>
#ifdef __cplusplus
}
#endif

MODULE = Time::Piece         PACKAGE = Time::Piece

PROTOTYPES: ENABLE

char *
__strftime(fmt, sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)
	char *		fmt
	int		sec
	int		min
	int		hour
	int		mday
	int		mon
	int		year
	int		wday
	int		yday
	int		isdst

    PREINIT:
    char *buf = NULL;

    CODE:
    #XXX: an sv_strftime() that can make use of the TARG would faster
    buf = my_strftime(fmt, sec, min, hour, mday, mon, year, wday, yday, isdst);
    RETVAL = buf;

    OUTPUT:
    RETVAL

    CLEANUP:
    if (buf) {
        Safefree(buf);
    }
