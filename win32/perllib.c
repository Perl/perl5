/*
 * "The Road goes ever on and on, down from the door where it began."
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#ifdef __cplusplus
}
#  define EXTERN_C extern "C"
#else
#  define EXTERN_C extern
#endif

static void xs_init _((void));

__declspec(dllexport) int
RunPerl(int argc, char **argv, char **env, void *iosubsystem)
{
    int exitstatus;
    PerlInterpreter *my_perl;
    void *pOldIOSubsystem;

    pOldIOSubsystem = SetIOSubSystem(iosubsystem);

    PERL_SYS_INIT(&argc,&argv);

    perl_init_i18nl10n(1);

    if (!(my_perl = perl_alloc()))
	return (1);
    perl_construct( my_perl );
    perl_destruct_level = 0;

    exitstatus = perl_parse( my_perl, xs_init, argc, argv, env);
    if (!exitstatus) {
	exitstatus = perl_run( my_perl );
    }

    perl_destruct( my_perl );
    perl_free( my_perl );

    PERL_SYS_TERM();

    SetIOSubSystem(pOldIOSubsystem);

    return (exitstatus);
}

/* Register any extra external extensions */

char *staticlinkmodules[] = {
    "DynaLoader",
    NULL,
};

EXTERN_C void boot_DynaLoader _((CV* cv));

static void
xs_init()
{
    dXSUB_SYS;
    char *file = __FILE__;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

extern HANDLE PerlDllHandle;

BOOL APIENTRY
DllMain(HANDLE hModule,		/* DLL module handle */
	DWORD fdwReason,	/* reason called */
	LPVOID lpvReserved)	/* reserved */
{ 
    switch (fdwReason) {
	/* The DLL is attaching to a process due to process
	 * initialization or a call to LoadLibrary.
	 */
    case DLL_PROCESS_ATTACH:
/* #define DEFAULT_BINMODE */
#ifdef DEFAULT_BINMODE
	_setmode( _fileno( stdin  ), _O_BINARY );
	_setmode( _fileno( stdout ), _O_BINARY );
	_setmode( _fileno( stderr ), _O_BINARY );
	_fmode = _O_BINARY;
#endif
	PerlDllHandle = hModule;
	break;

	/* The DLL is detaching from a process due to
	 * process termination or call to FreeLibrary.
	 */
    case DLL_PROCESS_DETACH:
	break;

	/* The attached process creates a new thread. */
    case DLL_THREAD_ATTACH:
	break;

	/* The thread of the attached process terminates. */
    case DLL_THREAD_DETACH:
	break;

    default:
	break;
    }
    return TRUE;
}
