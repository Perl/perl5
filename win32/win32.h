/* WIN32.H
 *
 * (c) 1995 Microsoft Corporation. All rights reserved. 
 * 		Developed by hip communications inc., http://info.hip.com/info/
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */
#ifndef  _INC_WIN32_PERL5
#define  _INC_WIN32_PERL5

#define  WIN32_LEAN_AND_MEAN
#include <windows.h>

#ifdef   WIN32_LEAN_AND_MEAN		/* C file is NOT a Perl5 original. */
#define  CONTEXT	PERL_CONTEXT	/* Avoid conflict of CONTEXT defs. */
#define  index		strchr		/* Why 'index'? */
#endif /*WIN32_LEAN_AND_MEAN */

#include <dirent.h>
#include <io.h>
#include <process.h>
#include <stdio.h>
#include <direct.h>
#include <stdlib.h>
#ifndef EXT
#include "EXTERN.h"
#endif

#ifndef START_EXTERN_C
#ifdef __cplusplus
#  define START_EXTERN_C extern "C" {
#  define END_EXTERN_C }
#  define EXTERN_C extern "C"
#else
#  define START_EXTERN_C 
#  define END_EXTERN_C 
#  define EXTERN_C
#endif
#endif

#define  STANDARD_C	1
#define  DOSISH		1		/* no escaping our roots */
#define  OP_BINARY	O_BINARY	/* mistake in in pp_sys.c? */
#define DllExport	__declspec(dllexport)
#define DllImport	__declspec(dllimport)

/* Define USE_SOCKETS_AS_HANDLES to enable emulation of windows sockets as
 * real filehandles. XXX Should always be defined (the other version is untested) */
#define USE_SOCKETS_AS_HANDLES

/* if USE_WIN32_RTL_ENV is not defined, Perl uses direct Win32 calls
 * to read the environment, bypassing the runtime's (usually broken)
 * facilities for accessing the same.  See note in util.c/my_setenv(). */
/*#define USE_WIN32_RTL_ENV */

/* Define USE_FIXED_OSFHANDLE to fix VC's _open_osfhandle() on W95.
 * Can only enable it if not using the DLL CRT (it doesn't expose internals) */
#if defined(_MSC_VER) && !defined(_DLL) && defined(_M_IX86)
#define USE_FIXED_OSFHANDLE
#endif

#ifndef VER_PLATFORM_WIN32_WINDOWS	/* VC-2.0 headers dont have this */
#define VER_PLATFORM_WIN32_WINDOWS	1
#endif

/* Compiler-specific stuff. */

#ifdef __BORLANDC__		/* Microsoft Visual C++ */

#define _access access
#define _chdir chdir
#include <sys/types.h>

#ifndef DllMain
#define DllMain DllEntryPoint
#endif

#pragma warn -ccc
#pragma warn -rch
#pragma warn -sig
#pragma warn -pia
#pragma warn -par
#pragma warn -aus
#pragma warn -use
#pragma warn -csu
#pragma warn -pro

#else

#ifdef _MSC_VER			/* Microsoft Visual C++ */

typedef long		uid_t;
typedef long		gid_t;
#pragma  warning(disable: 4018 4035 4101 4102 4244 4245 4761)

#endif /* _MSC_VER */

/* compatibility stuff for other compilers goes here */

#endif

START_EXTERN_C

/* For UNIX compatibility. */

extern  uid_t	getuid(void);
extern  gid_t	getgid(void);
extern  uid_t	geteuid(void);
extern  gid_t	getegid(void);
extern  int	setuid(uid_t uid);
extern  int	setgid(gid_t gid);
extern  int	kill(int pid, int sig);
extern  void	*sbrk(int need);

#undef	 Stat
#define  Stat		win32_stat

#undef   init_os_extras
#define  init_os_extras Perl_init_os_extras

EXT void		Perl_win32_init(int *argcp, char ***argvp);
EXT void		Perl_init_os_extras(void);

#ifndef USE_SOCKETS_AS_HANDLES
extern FILE *		my_fdopen(int, char *);
#endif
extern int		my_fclose(FILE *);
extern int		do_aspawn(void* really, void ** mark, void ** arglast);
extern int		do_spawn(char *cmd);
extern char		do_exec(char *cmd);
extern char *		win32PerlLibPath(char *sfx,...);
extern int		IsWin95(void);
extern int		IsWinNT(void);

extern char *		staticlinkmodules[];

END_EXTERN_C

typedef  char *		caddr_t;	/* In malloc.c (core address). */

/*
 * handle socket stuff, assuming socket is always available
 */
#include <sys/socket.h>
#include <netdb.h>

#ifdef MYMALLOC
#define EMBEDMYMALLOC	/**/
/* #define USE_PERL_SBRK	/**/
/* #define PERL_SBRK_VIA_MALLOC	/**/
#endif

#ifdef PERLDLL
#define PERL_CORE
#endif

#ifdef USE_BINMODE_SCRIPTS
#define PERL_SCRIPT_MODE "rb"
EXT void win32_strip_return(struct sv *sv);
#else
#define PERL_SCRIPT_MODE "r"
#define win32_strip_return(sv) NOOP
#endif

#endif /* _INC_WIN32_PERL5 */
