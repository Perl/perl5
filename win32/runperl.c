
#ifdef PERL_OBJECT
#define USE_SOCKETS_AS_HANDLES
#include "EXTERN.h"
#include "perl.h"

#define NO_XSLOCKS
#include "XSUB.H"
#undef errno
#if defined(_MT)
_CRTIMP int * __cdecl _errno(void);
#define errno (*_errno())
#else
_CRTIMP extern int errno;
#endif

#include <ipdir.h>
#include <ipenv.h>
#include <ipsock.h>
#include <iplio.h>
#include <ipmem.h>
#include <ipproc.h>

#include "ipstdiowin.h"
#include "ipdir.c"
#include "ipenv.c"
#include "ipsock.c"
#include "iplio.c"
#include "ipmem.c"
#include "ipproc.c"
#include "ipstdio.c"

static void xs_init _((CPERLarg));
#define stderr (&_iob[2])
#undef fprintf
#undef environ

class CPerlHost
{
public:
	CPerlHost() { pPerl = NULL; };
	inline BOOL PerlCreate(void)
	{
		try
		{
			pPerl = perl_alloc(&perlMem,
								&perlEnv,
								&perlStdIO,
								&perlLIO,
								&perlDir,
								&perlSock,
								&perlProc);
			if(pPerl != NULL)
			{
				perlDir.SetPerlObj(pPerl);
				perlEnv.SetPerlObj(pPerl);
				perlLIO.SetPerlObj(pPerl);
				perlLIO.SetSockCtl(&perlSock);
				perlLIO.SetStdObj(&perlStdIO);
				perlMem.SetPerlObj(pPerl);
				perlProc.SetPerlObj(pPerl);
				perlSock.SetPerlObj(pPerl);
				perlSock.SetStdObj(&perlStdIO);
				perlStdIO.SetPerlObj(pPerl);
				perlStdIO.SetSockCtl(&perlSock);
				try
				{
					pPerl->perl_construct();
				}
				catch(...)
				{
					fprintf(stderr, "%s\n", "Error: Unable to construct data structures");
					pPerl->perl_free();
					pPerl = NULL;
				}
			}
		}
		catch(...)
		{
			fprintf(stderr, "%s\n", "Error: Unable to allocate memory");
			pPerl = NULL;
		}
		return (pPerl != NULL);
	};
	inline int PerlParse(int argc, char** argv, char** env)
	{
		char* environ = NULL;
		int retVal;
		try
		{
			retVal = pPerl->perl_parse(xs_init, argc, argv, (env == NULL || *env == NULL ? &environ : env));
		}
		catch(int x)
		{
			// this is where exit() should arrive
			retVal = x;
		}
		catch(...)
		{
			fprintf(stderr, "Error: Parse exception\n");
			retVal = -1;
		}
		return retVal;
	};
	inline int PerlRun(void)
	{
		int retVal;
		try
		{
			retVal = pPerl->perl_run();
		}
		catch(int x)
		{
			// this is where exit() should arrive
			retVal = x;
		}
		catch(...)
		{
			fprintf(stderr, "Error: Runtime exception\n");
			retVal = -1;
		}
		return retVal;
	};
	inline void PerlDestroy(void)
	{
		try
		{
			pPerl->perl_destruct();
			pPerl->perl_free();
		}
		catch(...)
		{
		}
	};

protected:
	CPerlObj	*pPerl;
	CPerlDir	perlDir;
	CPerlEnv	perlEnv;
	CPerlLIO	perlLIO;
	CPerlMem	perlMem;
	CPerlProc	perlProc;
	CPerlSock	perlSock;
	CPerlStdIO	perlStdIO;
};

#undef PERL_SYS_INIT
#define PERL_SYS_INIT(a, c)

int
main(int argc, char **argv, char **env)
{
	CPerlHost host;
	int exitstatus = 1;

	if(!host.PerlCreate())
		exit(exitstatus);


	exitstatus = host.PerlParse(argc, argv, env);

	if (!exitstatus)
	{
		exitstatus = host.PerlRun();
    }

	host.PerlDestroy();

    return exitstatus;
}


static void xs_init(CPERLarg)
{
}

EXTERN_C void boot_DynaLoader _((CPERLarg_ CV* cv))
{
}

#else  /* PERL_OBJECT */

/* Say NO to CPP! Hallelujah! */
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
