#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bsd_glob.h"

/* XXX: need some thread awareness */
static int GLOB_ERROR = 0;

#include "constants.c"

#ifdef WIN32
#define errfunc		NULL
#else
int
errfunc(const char *foo, int bar) {
  return !(bar == ENOENT || bar == ENOTDIR);
}
#endif

MODULE = File::Glob		PACKAGE = File::Glob

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
	/* allow for optional flags argument */
	if (items > 1) {
	    flags = (int) SvIV(ST(1));
	}

	/* call glob */
	retval = bsd_glob(pattern, flags, errfunc, &pglob);
	GLOB_ERROR = retval;

	/* return any matches found */
	EXTEND(sp, pglob.gl_pathc);
	for (i = 0; i < pglob.gl_pathc; i++) {
	    /* printf("# bsd_glob: %s\n", pglob.gl_pathv[i]); */
	    tmp = sv_2mortal(newSVpvn(pglob.gl_pathv[i],
				      strlen(pglob.gl_pathv[i])));
	    TAINT;
	    SvTAINT(tmp);
	    PUSHs(tmp);
	}

	bsd_globfree(&pglob);
    }

INCLUDE: constants.xs
