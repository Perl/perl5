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

/* For UNIX compatibility. */

typedef long		uid_t;
typedef long		gid_t;

extern  char	*staticlinkmodules[];

extern  uid_t	getuid(void);
extern  gid_t	getgid(void);
extern  uid_t	geteuid(void);
extern  gid_t	getegid(void);

extern  int	setuid(uid_t uid);
extern  int	setgid(gid_t gid);
extern  int	kill(int pid, int sig);

#define USE_SOCKETS_AS_HANDLES
#ifndef USE_SOCKETS_AS_HANDLES
extern FILE *myfdopen(int, char *);

#undef fdopen
#define fdopen myfdopen
#endif	/* USE_SOCKETS_AS_HANDLES */

#define  STANDARD_C	1		/* Perl5 likes standard C. */
#define  DOSISH		1		/* Take advantage of DOSish code in Perl5. */

#define  OP_BINARY	_O_BINARY	/* Mistake in in pp_sys.c. */

#undef	 pipe
#define  pipe(fd)	win32_pipe((fd), 512, _O_BINARY) /* the pipe call is a bit different */

#undef	 pause
#define  pause()	sleep((32767L << 16) + 32767)


#undef	 times
#define  times	mytimes

#undef	 alarm
#define  alarm	myalarm

struct tms {
	long	tms_utime;
	long	tms_stime;
	long	tms_cutime;
	long	tms_cstime;
};

unsigned int sleep(unsigned int);
char *win32PerlLibPath();
int mytimes(struct tms *timebuf);
unsigned int myalarm(unsigned int sec);
int do_aspawn(void* really, void** mark, void** arglast);
int do_spawn(char *cmd);

typedef  char *		caddr_t;	/* In malloc.c (core address). */

/*
 * Extension Library, only good for VC
 */

#define DllExport	__declspec(dllexport)

/*
 * handle socket stuff, assuming socket is always available
 */

#include <sys/socket.h>
#include <netdb.h>

#pragma  warning(disable: 4018 4035 4101 4102 4244 4245 4761)

int IsWin95(void);
int IsWinNT(void);

#ifndef VER_PLATFORM_WIN32_WINDOWS	/* VC-2.0 headers dont have this */
#define VER_PLATFORM_WIN32_WINDOWS	1
#endif

#endif /* _INC_WIN32_PERL5 */
