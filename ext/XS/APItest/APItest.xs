#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = XS::APItest		PACKAGE = XS::APItest

PROTOTYPES: DISABLE

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

void
print_long_double()
        CODE:
#ifdef HAS_LONG_DOUBLE
#   if LONG_DOUBLESIZE > DOUBLESIZE
        long double val = 7.0;
        printf("%5.3" PERL_PRIfldbl "\n",val);
#   else
        double val = 7.0;
        printf("%5.3f\n",val);
#   endif
#endif

void
print_nv(val)
        NV val
        CODE:
        printf("%5.3Vf\n",val);

void
print_iv(val)
        IV val
        CODE:
        printf("%Vd\n",val);

void
print_uv(val)
        UV val
        CODE:
        printf("%Vu\n",val);

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
