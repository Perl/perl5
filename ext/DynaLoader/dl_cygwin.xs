/* dl_cygwin.xs
 * 
 * Platform:	Win32 (Windows NT/Windows 95)
 * Author:	Wei-Yuen Tan (wyt@hip.com)
 * Created:	A warm day in June, 1995
 *
 * Modified:
 *    August 23rd 1995 - rewritten after losing everything when I
 *                       wiped off my NT partition (eek!)
 */
/* Modified from the original dl_win32.xs to work with cygwin
   -John Cerney 3/26/97
*/
/* Porting notes:

I merely took Paul's dl_dlopen.xs, took out extraneous stuff and
replaced the appropriate SunOS calls with the corresponding Win32
calls.

*/

#define WIN32_LEAN_AND_MEAN
// Defines from windows needed for this function only. Can't include full
//  Cygwin windows headers because of problems with CONTEXT redefinition
//  Removed logic to tell not dynamically load static modules. It is assumed that all
//   modules are dynamically built. This should be similar to the behavoir on sunOS.
//   Leaving in the logic would have required changes to the standard perlmain.c code
//
#include <stdio.h>

//#include <windows.h>
#define LOAD_WITH_ALTERED_SEARCH_PATH	(8)
typedef void *HANDLE;
typedef HANDLE HINSTANCE;
#define STDCALL     __attribute__ ((stdcall))
typedef int STDCALL (*FARPROC)();
#define MAX_PATH	260

HINSTANCE
STDCALL
LoadLibraryExA(
	       char* lpLibFileName,
	       HANDLE hFile,
	       unsigned int dwFlags
	       );
unsigned int
STDCALL
GetLastError(
	     void
	     );
FARPROC
STDCALL
GetProcAddress(
	       HINSTANCE hModule,
	       char* lpProcName
	       );

#include <string.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dlutils.c"	/* SaveError() etc	*/

static void
dl_private_init(pTHX)
{
    (void)dl_generic_private_init(aTHX);
}


MODULE = DynaLoader	PACKAGE = DynaLoader

BOOT:
    (void)dl_private_init(aTHX);

void *
dl_load_file(filename,flags=0)
    char *		filename
    int			flags
    PREINIT:
    CODE:
    {
    char	win32_path[MAX_PATH];
    cygwin_conv_to_full_win32_path(filename, win32_path);
    filename = win32_path;

    DLDEBUG(1,PerlIO_printf(Perl_debug_log,"dl_load_file(%s):\n", filename));

    RETVAL = (void*) LoadLibraryExA(filename, NULL, LOAD_WITH_ALTERED_SEARCH_PATH ) ;

    DLDEBUG(2,PerlIO_printf(Perl_debug_log," libref=%x\n", RETVAL));
    ST(0) = sv_newmortal() ;
    if (RETVAL == NULL){
	SaveError(aTHX_ "%d",GetLastError()) ;
    } else {
	sv_setiv( ST(0), PTR2IV(RETVAL) );
    }
   }
	


void *
dl_find_symbol(libhandle, symbolname)
    void *	libhandle
    char *	symbolname
    CODE:
    DLDEBUG(2,PerlIO_printf(Perl_debug_log,"dl_find_symbol(handle=%x, symbol=%s)\n",
	libhandle, symbolname));
    RETVAL = (void*) GetProcAddress((HINSTANCE) libhandle, symbolname);
    DLDEBUG(2,PerlIO_printf(Perl_debug_log,"  symbolref = %x\n", RETVAL));
    ST(0) = sv_newmortal() ;
    if (RETVAL == NULL)
	SaveError(aTHX_ "%d",GetLastError()) ;
    else
	sv_setiv( ST(0), PTR2IV(RETVAL));


void
dl_undef_symbols()
    PPCODE:



# These functions should not need changing on any platform:

void
dl_install_xsub(perl_name, symref, filename="$Package")
    char *		perl_name
    void *		symref 
    char *		filename
    CODE:
    DLDEBUG(2,PerlIO_printf(Perl_debug_log,"dl_install_xsub(name=%s, symref=%x)\n",
		perl_name, symref));
    ST(0) = sv_2mortal(newRV((SV*)newXS(perl_name,
					(void(*)(pTHX_ CV *))symref,
					filename)));


char *
dl_error()
    CODE:
    RETVAL = LastError ;
    OUTPUT:
    RETVAL

# end.
