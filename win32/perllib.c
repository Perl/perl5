/*
 * "The Road goes ever on and on, down from the door where it began."
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

/* Register any extra external extensions */

char *staticlinkmodules[] = {
    "DynaLoader",
    NULL,
};

EXTERN_C void boot_DynaLoader _((CV* cv));

static
XS(w32_GetCurrentDirectory)
{
    dXSARGS;
    SV *sv = sv_newmortal();
    /* Make one call with zero size - return value is required size */
    DWORD len = GetCurrentDirectory((DWORD)0,NULL);
    SvUPGRADE(sv,SVt_PV);
    SvGROW(sv,len);
    SvCUR(sv) = GetCurrentDirectory((DWORD) SvLEN(sv), SvPVX(sv));
    /* 
     * If result != 0 
     *   then it worked, set PV valid, 
     *   else leave it 'undef' 
     */
    if (SvCUR(sv))
	SvPOK_on(sv);
    EXTEND(sp,1);
    ST(0) = sv;
    XSRETURN(1);
}

static
XS(w32_GetLastError)
{
	dXSARGS;
	XSRETURN_IV(GetLastError());
}

XS(w32_IsWinNT)
{
	dXSARGS;
	XSRETURN_IV(IsWinNT());
}

XS(w32_IsWin95)
{
	dXSARGS;
	XSRETURN_IV(IsWin95());
}

static void
xs_init()
{
    char *file = __FILE__;
    dXSUB_SYS;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
    newXS("Win32::GetCurrentDirectory", w32_GetCurrentDirectory, file);
    newXS("Win32::GetLastError", w32_GetLastError, file);
    newXS("Win32::IsWinNT", w32_IsWinNT, file);
    newXS("Win32::IsWin95", w32_IsWin95, file);
}

