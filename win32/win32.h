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
#define USE_SOCKETS_AS_HANDLES		/* we wanna pretend sockets are FDs */
/*#define USE_WIN32_RTL_ENV */		/* see note below */

/* For UNIX compatibility. */

#ifdef __BORLANDC__

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

typedef long		uid_t;
typedef long		gid_t;

#endif

START_EXTERN_C
extern  uid_t	getuid(void);
extern  gid_t	getgid(void);
extern  uid_t	geteuid(void);
extern  gid_t	getegid(void);
extern  int	setuid(uid_t uid);
extern  int	setgid(gid_t gid);
extern  int	kill(int pid, int sig);
END_EXTERN_C

extern  char	*staticlinkmodules[];

START_EXTERN_C

/* if USE_WIN32_RTL_ENV is not defined, Perl uses direct Win32 calls
 * to read the environment, bypassing the runtime's (usually broken)
 * facilities for accessing the same.  See note in util.c/my_setenv().
 */

#ifndef USE_WIN32_RTL_ENV
EXT char *win32_getenv(const char *name);
#undef getenv
#define getenv win32_getenv
#endif

EXT void Perl_win32_init(int *argcp, char ***argvp);

#ifndef USE_SOCKETS_AS_HANDLES
extern FILE *my_fdopen(int, char *);
#undef fdopen
#define fdopen my_fdopen
#endif	/* USE_SOCKETS_AS_HANDLES */

#undef fclose
#define fclose my_fclose

#undef	 pipe		/* win32_pipe() itself calls _pipe() */
#define  pipe(fd)	win32_pipe((fd), 512, O_BINARY)

#undef	 pause
#define  pause()	sleep((32767L << 16) + 32767)

#undef	 times
#define  times	my_times

#undef	 alarm
#define  alarm	my_alarm

struct tms {
	long	tms_utime;
	long	tms_stime;
	long	tms_cutime;
	long	tms_cstime;
};

extern unsigned int sleep(unsigned int);
extern char *win32PerlLibPath(void);
extern char *win32SiteLibPath(void);
extern int my_times(struct tms *timebuf);
extern unsigned int my_alarm(unsigned int sec);
extern int my_flock(int fd, int oper);
extern int do_aspawn(void* really, void ** mark, void ** arglast);
extern int do_spawn(char *cmd);
extern char do_exec(char *cmd);
extern void init_os_extras(void);
extern int my_fclose(FILE *);
extern int IsWin95(void);
extern int IsWinNT(void);

END_EXTERN_C

typedef  char *		caddr_t;	/* In malloc.c (core address). */

/*
 * Extension Library, only good for VC
 */

#define DllExport	__declspec(dllexport)
#define DllImport	__declspec(dllimport)

/*
 * handle socket stuff, assuming socket is always available
 */

#include <sys/socket.h>
#include <netdb.h>

#ifdef _MSC_VER
#pragma  warning(disable: 4018 4035 4101 4102 4244 4245 4761)
#endif

#ifndef VER_PLATFORM_WIN32_WINDOWS	/* VC-2.0 headers dont have this */
#define VER_PLATFORM_WIN32_WINDOWS	1
#endif

#endif /* _INC_WIN32_PERL5 */
