/*
Date: Mon, 25 Apr 94 14:15:30 PDT
From: Jeff Okamoto <okamoto@hpcc101.corp.hp.com>
To: doughera@lafcol.lafayette.edu
Cc: okamoto@hpcc101.corp.hp.com, Jarkko.Hietaniemi@hut.fi, ram@acri.fr,
     john@WPI.EDU, k@franz.ww.TU-Berlin.DE, dmm0t@rincewind.mech.virginia.edu,
     lwall@netlabs.com
Subject: dl.c.hpux

This is what I hacked around and came up with for HP-UX.  (Or maybe it should
be called dl_hpux.c).  Notice the change in suffix from .so to .sl (the
default suffix for HP-UX shared libraries).

Jeff
*/
#include <dl.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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
	shl_t obj = NULL;
	int (*bootproc)();
	char tmpbuf[1024];
	char tmpbuf2[128];
	AV *av = GvAVn(incgv);
	I32 i;

	for (i = 0; i <= AvFILL(av); i++) {
	    (void)sprintf(tmpbuf, "%s/auto/%s/%s.sl",
		SvPVx(*av_fetch(av, i, TRUE), na), package, package);
	    if (obj = shl_load(tmpbuf,
		BIND_IMMEDIATE | BIND_NONFATAL | BIND_NOSTART,0L))
		break;
	}
	if (obj != (shl_t) NULL)
	    croak("Can't find loadable object for package %s in @INC", package);

	sprintf(tmpbuf2, "boot_%s", package);
	i = shl_findsym(&obj, tmpbuf2, TYPE_PROCEDURE, &bootproc);
	if (i == -1)
	    croak("Shared object %s contains no %s function", tmpbuf, tmpbuf2);
	bootproc();

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

