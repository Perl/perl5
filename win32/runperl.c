
#ifdef PERL_OBJECT
#define USE_SOCKETS_AS_HANDLES
#include "EXTERN.h"
#include "perl.h"

#define NO_XSLOCKS
#include "XSUB.H"
#include "win32iop.h"

#include <fcntl.h>
#include "perlhost.h"


char *staticlinkmodules[] = {
    "DynaLoader",
    NULL,
};

EXTERN_C void boot_DynaLoader _((CV* cv _CPERLarg));

static void
xs_init(CPERLarg)
{
    char *file = __FILE__;
    dXSUB_SYS;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

CPerlObj *pPerl;

#undef PERL_SYS_INIT
#define PERL_SYS_INIT(a, c)

int
main(int argc, char **argv, char **env)
{
    CPerlHost host;
    int exitstatus = 1;

    if(!host.PerlCreate())
	exit(exitstatus);

    exitstatus = host.PerlParse(xs_init, argc, argv, NULL);

    if (!exitstatus)
	exitstatus = host.PerlRun();

    host.PerlDestroy();

    return exitstatus;
}

#else  /* PERL_OBJECT */

#ifdef __GNUC__
/*
 * GNU C does not do __declspec()
 */
#define __declspec(foo) 

/* Mingw32 defaults to globing command line 
 * This is inconsistent with other Win32 ports and 
 * seems to cause trouble with passing -DXSVERSION=\"1.6\" 
 * So we turn it off like this:
 */
int _CRT_glob = 0;

#endif


__declspec(dllimport) int RunPerl(int argc, char **argv, char **env, void *ios);

int
main(int argc, char **argv, char **env)
{
    return RunPerl(argc, argv, env, (void*)0);
}

#endif  /* PERL_OBJECT */
