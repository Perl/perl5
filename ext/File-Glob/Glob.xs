#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bsd_glob.h"

#define MY_CXT_KEY "File::Glob::_guts" XS_VERSION

typedef struct {
    int		x_GLOB_ERROR;
} my_cxt_t;

START_MY_CXT

#define GLOB_ERROR	(MY_CXT.x_GLOB_ERROR)

#include "const-c.inc"

#ifdef WIN32
#define errfunc		NULL
#else
static int
errfunc(const char *foo, int bar) {
  PERL_UNUSED_ARG(foo);
  return !(bar == EACCES || bar == ENOENT || bar == ENOTDIR);
}
#endif

MODULE = File::Glob		PACKAGE = File::Glob

int
GLOB_ERROR()
    PREINIT:
	dMY_CXT;
    CODE:
	RETVAL = GLOB_ERROR;
    OUTPUT:
	RETVAL

void
doglob(pattern,...)
    char *pattern
PROTOTYPE: $;$
PREINIT:
    glob_t pglob;
    int i;
    int retval;
    int flags = 0;
    SV *tmp;
PPCODE:
    {
	dMY_CXT;
	dXSI32;

	/* allow for optional flags argument */
	if (items > 1) {
	    flags = (int) SvIV(ST(1));
	    /* remove unsupported flags */
	    flags &= ~(GLOB_APPEND | GLOB_DOOFFS | GLOB_ALTDIRFUNC | GLOB_MAGCHAR);
	} else if (ix) {
	    flags = (int) SvIV(get_sv("File::Glob::DEFAULT_FLAGS", GV_ADD));
	}

	/* call glob */
	memset(&pglob, 0, sizeof(glob_t));
	retval = bsd_glob(pattern, flags, errfunc, &pglob);
	GLOB_ERROR = retval;

	/* return any matches found */
	EXTEND(sp, pglob.gl_pathc);
	for (i = 0; i < pglob.gl_pathc; i++) {
	    /* printf("# bsd_glob: %s\n", pglob.gl_pathv[i]); */
	    tmp = newSVpvn_flags(pglob.gl_pathv[i], strlen(pglob.gl_pathv[i]),
				 SVs_TEMP);
	    TAINT;
	    SvTAINT(tmp);
	    PUSHs(tmp);
	}

	bsd_globfree(&pglob);
    }

BOOT:
{
    CV *cv = newXS("File::Glob::bsd_glob", XS_File__Glob_doglob, __FILE__);
    XSANY.any_i32 = 1;
}

BOOT:
{
    MY_CXT_INIT;
}

INCLUDE: const-xs.inc
