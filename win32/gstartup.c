/*
 * gstartup.c
 *
 * Startup file for GCC/Mingw32 builds
 * (replaces gcc's default c:\egcs\...\{crt1.o,dllcrt1.o})
 *
 * This file is taken from the Mingw32 package.
 *  Created by Colin Peters for Mingw32
 *  Modified by Mumit Khan
 *
 * History with Perl:
 *  Added (in modified form) to Perl standard distribution to fix
 *    problems linking against PerlCRT or MSVCRT
 *    -- Benjamin Stuhl <sho_pi@hotmail.com> 10-17-1999
*/

#include <stdlib.h>
#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <process.h>
#include <float.h>
#include <windows.h>
#include <signal.h>

/*
 * Access to a standard 'main'-like argument count and list. Also included
 * is a table of environment variables.
 */
int _argc;
char **_argv;

extern int _CRT_glob;

#ifdef __MSVCRT__
typedef struct {
  int newmode;
} _startupinfo;
extern void __getmainargs (int *, char ***, char ***, int, _startupinfo *);
#else
extern void __GetMainArgs (int *, char ***, char ***, int);
#endif

/*
 * Initialize the _argc, _argv and environ variables.
 */
static void
_mingw32_init_mainargs ()
{
  /* The environ variable is provided directly in stdlib.h through
   * a dll function call. */
  char **dummy_environ;
#ifdef __MSVCRT__
  _startupinfo start_info;
  start_info.newmode = 0;
#endif

  /*
   * Microsoft's runtime provides a function for doing just that.
   */
#ifdef __MSVCRT__
  (void) __getmainargs (&_argc, &_argv, &dummy_environ, _CRT_glob, 
                        &start_info);
#else
  /* CRTDLL version */
  (void) __GetMainArgs (&_argc, &_argv, &dummy_environ, _CRT_glob);
#endif
}

#if defined(EXESTARTUP) /* gcrt0.o - startup for an executable */

extern int main (int, char **, char **);

/*
 * Must have the correct app type for MSVCRT. 
 */

#ifdef __MSVCRT__
#define __UNKNOWN_APP    0
#define __CONSOLE_APP    1
#define __GUI_APP        2
__MINGW_IMPORT void __set_app_type(int);
#endif /* __MSVCRT__ */

/*
 * Setup the default file handles to have the _CRT_fmode mode, as well as
 * any new files created by the user.
 */
extern unsigned int _CRT_fmode;

static void
_mingw32_init_fmode ()
{
  /* Don't set the file mode if the user hasn't set any value for it. */
  if (_CRT_fmode)
    {
      _fmode = _CRT_fmode;

      /*
       * This overrides the default file mode settings for stdin,
       * stdout and stderr. At first I thought you would have to
       * test with isatty, but it seems that the DOS console at
       * least is smart enough to handle _O_BINARY stdout and
       * still display correctly.
       */
      if (stdin)
	{
	  _setmode (_fileno (stdin), _CRT_fmode);
	}
      if (stdout)
	{
	  _setmode (_fileno (stdout), _CRT_fmode);
	}
      if (stderr)
	{
	  _setmode (_fileno (stderr), _CRT_fmode);
	}
    }
}

/* This function will be called when a trap occurs. Thanks to Jacob
   Navia for his contribution. */
static CALLBACK long
_gnu_exception_handler (EXCEPTION_POINTERS * exception_data)
{
  void (*old_handler) (int);
  long action = EXCEPTION_CONTINUE_SEARCH;
  int reset_fpu = 0;

  switch (exception_data->ExceptionRecord->ExceptionCode)
    {
    case EXCEPTION_ACCESS_VIOLATION:
      /* test if the user has set SIGSEGV */
      old_handler = signal (SIGSEGV, SIG_DFL);
      if (old_handler == SIG_IGN)
	{
	  /* this is undefined if the signal was raised by anything other
	     than raise ().  */
	  signal (SIGSEGV, SIG_IGN);
	  action = EXCEPTION_CONTINUE_EXECUTION;
	}
      else if (old_handler != SIG_DFL)
	{
	  /* This means 'old' is a user defined function. Call it */
	  (*old_handler) (SIGSEGV);
	  action = EXCEPTION_CONTINUE_EXECUTION;
	}
      break;

    case EXCEPTION_FLT_INVALID_OPERATION:
    case EXCEPTION_FLT_DIVIDE_BY_ZERO:
    case EXCEPTION_FLT_DENORMAL_OPERAND:
    case EXCEPTION_FLT_OVERFLOW:
    case EXCEPTION_FLT_UNDERFLOW:
    case EXCEPTION_FLT_INEXACT_RESULT:
      reset_fpu = 1;
      /* fall through. */

    case EXCEPTION_INT_DIVIDE_BY_ZERO:
      /* test if the user has set SIGFPE */
      old_handler = signal (SIGFPE, SIG_DFL);
      if (old_handler == SIG_IGN)
	{
	  signal (SIGFPE, SIG_IGN);
	  if (reset_fpu)
	    _fpreset ();
	  action = EXCEPTION_CONTINUE_EXECUTION;
	}
      else if (old_handler != SIG_DFL)
	{
	  /* This means 'old' is a user defined function. Call it */
	  (*old_handler) (SIGFPE);
	  action = EXCEPTION_CONTINUE_EXECUTION;
	}
      break;

    default:
      break;
    }
  return action;
}

/*
 * The function mainCRTStartup is the entry point for all console programs.
 */
static int
__mingw_CRTStartup ()
{
  int nRet;

  /*
   * Set up the top-level exception handler so that signal handling
   * works as expected. The mapping between ANSI/POSIX signals and
   * Win32 SE is not 1-to-1, so caveat emptore.
   * 
   */
  SetUnhandledExceptionFilter (_gnu_exception_handler);

  /*
   * Initialize floating point unit.
   */
  _fpreset ();			/* Supplied by the runtime library. */

  /*
   * Set up __argc, __argv and _environ.
   */
  _mingw32_init_mainargs ();

  /*
   * Sets the default file mode for stdin, stdout and stderr, as well
   * as files later opened by the user, to _CRT_fmode.
   * NOTE: DLLs don't do this because that would be rude!
   */
  _mingw32_init_fmode ();

  /*
   * Call the main function. If the user does not supply one
   * the one in the 'libmingw32.a' library will be linked in, and
   * that one calls WinMain. See main.c in the 'lib' dir
   * for more details.
   */
  nRet = main (_argc, _argv, environ);

  /*
   * Perform exit processing for the C library. This means
   * flushing output and calling 'atexit' registered functions.
   */
  _cexit ();

  ExitProcess (nRet);

  return 0;
}

/*
 * The function mainCRTStartup is the entry point for all console programs.
 */
int
mainCRTStartup ()
{
#ifdef __MSVCRT__
  __set_app_type (__CONSOLE_APP);
#endif
  __mingw_CRTStartup ();
  return 0;
}

/*
 * For now the GUI startup function is the same as the console one.
 * This simply gets rid of the annoying warning about not being able
 * to find WinMainCRTStartup when linking GUI applications.
 */
int
WinMainCRTStartup ()
{
#ifdef __MSVCRT__
  __set_app_type (__GUI_APP);
#endif
  __mingw_CRTStartup ();
}

#elif defined(DLLSTARTUP) /* dllcrt0.o - startup for a DLL */

/* Unlike normal crt1, I don't initialize the FPU, because the process
 * should have done that already. I also don't set the file handle modes,
 * because that would be rude. */

#ifdef	__GNUC__
extern void __main ();
extern void __do_global_dtors ();
#endif

extern BOOL WINAPI DllMain (HANDLE, DWORD, LPVOID);

BOOL WINAPI
DllMainCRTStartup (HANDLE hDll, DWORD dwReason, LPVOID lpReserved)
{
  BOOL bRet;

  if (dwReason == DLL_PROCESS_ATTACH)
    {
      _mingw32_init_mainargs ();

#ifdef	__GNUC__
      /* From libgcc.a, calls global class constructors. */
      __main ();
#endif
    }

  /*
   * Call the user-supplied DllMain subroutine
   * NOTE: DllMain is optional, so libmingw32.a includes a stub
   *       which will be used if the user does not supply one.
   */
  bRet = DllMain (hDll, dwReason, lpReserved);

#ifdef	__GNUC__
  if (dwReason == DLL_PROCESS_DETACH)
    {
      /* From libgcc.a, calls global class destructors. */
      __do_global_dtors ();
    }
#endif

  return bRet;
}

/*
 * For the moment a dummy atexit. Atexit causes problems in DLLs, especially
 * if they are dynamically loaded. For now atexit inside a DLL does nothing.
 * NOTE: We need this even if the DLL author never calls atexit because
 *       the global constructor function __do_global_ctors called from __main
 *       will attempt to register __do_global_dtors using atexit.
 *       Thanks to Andrey A. Smirnov for pointing this one out.
 */
int
atexit (void (*pfn) ())
{
  return 0;
}

#else
#error No startup target!
#endif /* EXESTARTUP */
