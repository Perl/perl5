#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Cwd		PACKAGE = Cwd

PROTOTYPES: ENABLE

void
fastcwd()
PPCODE:
{
    dXSTARG;
    sv_getcwd(TARG);
    XSprePUSH; PUSHTARG;
}

void
abs_path(svpath=Nullsv)
    SV *svpath
PPCODE:
{
    dXSTARG;
    char *path;
    STRLEN len;

    if (svpath) {
        path = SvPV(svpath, len);
    }
    else {
        path = ".";
        len = 1;
    }

    sv_realpath(TARG, path, len);
    XSprePUSH; PUSHTARG;
}
