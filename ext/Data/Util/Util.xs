#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE=Data::Util   PACKAGE=Data::Util

int
sv_readonly_flag(...)
PROTOTYPE: \[$%@];$
CODE:
{
    SV *sv = SvRV(ST(0));
    IV old = SvREADONLY(sv);

    if (items == 2) {
        if (SvTRUE(ST(1))) {
            SvREADONLY_on(sv);
        }
        else {
            SvREADONLY_off(sv);
        }
    }
    if (old)
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

