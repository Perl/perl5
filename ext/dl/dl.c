#include <dlfcn.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
XS_DynamicLoader_bootstrap(ix, sp, items)
register int ix;
register int sp;
register int items;
{
    if (items < 1 || items > 1) {
	croak("Usage: DynamicLoader::bootstrap(package)");
    }
    {
	char*	package = SvPV(ST(1),na);
	void* obj = 0;
	int (*bootproc)();
	char tmpbuf[1024];
	char tmpbuf2[128];
	AV *av = GvAVn(incgv);
	I32 i;

	for (i = 0; i <= AvFILL(av); i++) {
	    (void)sprintf(tmpbuf, "%s/auto/%s/%s.so",
		SvPVx(*av_fetch(av, i, TRUE), na), package, package);
	    if (obj = dlopen(tmpbuf,1))
		break;
	}
	if (!obj)
	    croak("Can't find loadable object for package %s in @INC", package);

	sprintf(tmpbuf2, "boot_%s", package);
	bootproc = (int (*)())dlsym(obj, tmpbuf2);
	if (!bootproc)
	    croak("Shared object %s contains no %s function", tmpbuf, tmpbuf2);
	bootproc();

	ST(0) = sv_mortalcopy(&sv_yes);
    }
    return sp;
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
