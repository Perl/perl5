/* dl_next.c
   Author:  tom@smart.bo.open.de (Thomas Neumann).
   Based on dl_sunos.c
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mach-o/rld.h>
#include <streams/streams.h>

static int
XS_DynamicLoader_bootstrap(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 1 || items > 1) {
	croak("Usage: DynamicLoader::bootstrap(package)");
    }
    {
	char*	package = SvPV(ST(1),na);
	int rld_success;
	NXStream *nxerr = NXOpenFile(fileno(stderr), NX_READONLY);
	int (*bootproc)();
	char tmpbuf[1024];
	char tmpbuf2[128];
	AV *av = GvAVn(incgv);
	I32 i;

	for (i = 0; i <= AvFILL(av); i++) {
	    char *p[2];
	    p[0] = tmpbuf;
	    p[1] = 0;
	    sprintf(tmpbuf, "%s/auto/%s/%s.so",
		    SvPVx(*av_fetch(av, i, TRUE), na), package, package);
	    if (rld_success = rld_load(nxerr, (struct mach_header **)0, p,
				       (const char *)0))
	    {
	        break;
	    }
	}
	if (!rld_success) {
	    NXClose(nxerr);
	    croak("Can't find loadable object for package %s in @INC", package);

	}
	sprintf(tmpbuf2, "_boot_%s", package);
	if (!rld_lookup(nxerr, tmpbuf2, (unsigned long *)&bootproc)) {
	    NXClose(nxerr);
	    croak("Shared object %s contains no %s function", tmpbuf, tmpbuf2);
	}
	NXClose(nxerr);
	(*bootproc)();
	ST(0) = sv_mortalcopy(&sv_yes);
    }
    return ax;
}

int
boot_DynamicLoader(ix,sp,items)
int ix;
int sp;
int items;
{
    char* file = __FILE__;

    newXSUB("DynamicLoader::bootstrap", 0, XS_DynamicLoader_bootstrap, file);
}
