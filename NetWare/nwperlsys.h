/*
 * Copyright © 2001 Novell, Inc. All Rights Reserved.
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the README file.
 *
 */

/*
 * FILENAME		:	nwperlsys.h
 * DESCRIPTION	:	Derives from iperlsys.h and define the platform specific function
 * Author		:	SGP
 * Date	Created	:	June 12th 2001.
 * Date Modified:
 */

#ifndef ___NWPerlSys_H___
#define ___NWPerlSys_H___


#include "iperlsys.h"

//Socket related calls
#include "nw5sck.h"

//Store the Watcom hash list
#include "nwtinfo.h"

//Watcom hash list
#include <wchash.h>

/* IPerlMem - Memory management - Begin ==================================================*/

void* PerlMemMalloc(struct IPerlMem* piPerl, size_t size);
void* PerlMemRealloc(struct IPerlMem* piPerl, void* ptr, size_t size);
void  PerlMemFree(struct IPerlMem* piPerl, void* ptr);
void* PerlMemCalloc(struct IPerlMem* piPerl, size_t num, size_t size);

struct IPerlMem perlMem =
{
    PerlMemMalloc,
    PerlMemRealloc,
    PerlMemFree,
    PerlMemCalloc,
};

/* IPerlMem - Memory management - End   ==================================================*/

/* IPerlDir	- Directory Manipulation - Begin =============================================*/

int PerlDirMakedir(struct IPerlDir* piPerl, const char *dirname, int mode);
int PerlDirChdir(struct IPerlDir* piPerl, const char *dirname);
int PerlDirRmdir(struct IPerlDir* piPerl, const char *dirname);
int PerlDirClose(struct IPerlDir* piPerl, DIR *dirp);
DIR* PerlDirOpen(struct IPerlDir* piPerl, char *filename);
struct direct * PerlDirRead(struct IPerlDir* piPerl, DIR *dirp);
void PerlDirRewind(struct IPerlDir* piPerl, DIR *dirp);
void PerlDirSeek(struct IPerlDir* piPerl, DIR *dirp, long loc);
long PerlDirTell(struct IPerlDir* piPerl, DIR *dirp);

struct IPerlDir perlDir =
{
	PerlDirMakedir,
    PerlDirChdir,
    PerlDirRmdir,
    PerlDirClose,
    PerlDirOpen,
    PerlDirRead,
    PerlDirRewind,
    PerlDirSeek,
    PerlDirTell,
};

/* IPerlDir	- Directory Manipulation - End   =============================================*/

/* IPerlEnv	- Environment related functions - Begin ======================================*/

char* PerlEnvGetenv(struct IPerlEnv* piPerl, const char *varname);
int PerlEnvPutenv(struct IPerlEnv* piPerl, const char *envstring);
char* PerlEnvGetenv_len(struct IPerlEnv* piPerl, const char* varname, unsigned long* len);
int PerlEnvUname(struct IPerlEnv* piPerl, struct utsname *name);
void PerlEnvClearenv(struct IPerlEnv* piPerl);

//Uncomment the following prototypes and the function names in the structure below
//whenever it is implemented.
//The function definition to be put in nwperlsys.c

/*void* PerlEnvGetChildenv(struct IPerlEnv* piPerl);
void PerlEnvFreeChildenv(struct IPerlEnv* piPerl, void* childEnv);
char* PerlEnvGetChilddir(struct IPerlEnv* piPerl);
void PerlEnvFreeChilddir(struct IPerlEnv* piPerl, char* childDir);*/

struct IPerlEnv perlEnv = 
{
	PerlEnvGetenv,
	PerlEnvPutenv,
    PerlEnvGetenv_len,
    PerlEnvUname,
    PerlEnvClearenv,
/*    PerlEnvGetChildenv,
    PerlEnvFreeChildenv,
    PerlEnvGetChilddir,
    PerlEnvFreeChilddir,*/
};

/* IPerlEnv	- Environment related functions - Begin ======================================*/

/* IPerlStdio	- Stdio functions - Begin ================================================*/

FILE* PerlStdIOStdin(struct IPerlStdIO* piPerl);
FILE* PerlStdIOStdout(struct IPerlStdIO* piPerl);
FILE* PerlStdIOStderr(struct IPerlStdIO* piPerl);
FILE* PerlStdIOOpen(struct IPerlStdIO* piPerl, const char *path, const char *mode);
int PerlStdIOClose(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOEof(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOError(struct IPerlStdIO* piPerl, FILE* pf);
void PerlStdIOClearerr(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOGetc(struct IPerlStdIO* piPerl, FILE* pf);
char* PerlStdIOGetBase(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOGetBufsiz(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOGetCnt(struct IPerlStdIO* piPerl, FILE* pf);
char* PerlStdIOGetPtr(struct IPerlStdIO* piPerl, FILE* pf);
char* PerlStdIOGets(struct IPerlStdIO* piPerl, FILE* pf, char* s, int n);
int PerlStdIOPutc(struct IPerlStdIO* piPerl, FILE* pf, int c);
int PerlStdIOPuts(struct IPerlStdIO* piPerl, FILE* pf, const char *s);
int PerlStdIOFlush(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOUngetc(struct IPerlStdIO* piPerl, int c, FILE* pf);
int PerlStdIOFileno(struct IPerlStdIO* piPerl, FILE* pf);
FILE* PerlStdIOFdopen(struct IPerlStdIO* piPerl, int fd, const char *mode);
FILE* PerlStdIOReopen(struct IPerlStdIO* piPerl, const char*path, const char*mode, FILE* pf);
SSize_t PerlStdIORead(struct IPerlStdIO* piPerl, void *buffer, Size_t size, Size_t count, FILE* pf);
SSize_t PerlStdIOWrite(struct IPerlStdIO* piPerl, const void *buffer, Size_t size, Size_t count, FILE* pf);
void PerlStdIOSetBuf(struct IPerlStdIO* piPerl, FILE* pf, char* buffer);
int PerlStdIOSetVBuf(struct IPerlStdIO* piPerl, FILE* pf, char* buffer, int type, Size_t size);
void PerlStdIOSetCnt(struct IPerlStdIO* piPerl, FILE* pf, int n);
void PerlStdIOSetPtr(struct IPerlStdIO* piPerl, FILE* pf, char * ptr);
void PerlStdIOSetlinebuf(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOPrintf(struct IPerlStdIO* piPerl, FILE* pf, const char *format,...);
int PerlStdIOVprintf(struct IPerlStdIO* piPerl, FILE* pf, const char *format, va_list arglist);
long PerlStdIOTell(struct IPerlStdIO* piPerl, FILE* pf);
int PerlStdIOSeek(struct IPerlStdIO* piPerl, FILE* pf, off_t offset, int origin);
void PerlStdIORewind(struct IPerlStdIO* piPerl, FILE* pf);
FILE* PerlStdIOTmpfile(struct IPerlStdIO* piPerl);
int PerlStdIOGetpos(struct IPerlStdIO* piPerl, FILE* pf, Fpos_t *p);
int PerlStdIOSetpos(struct IPerlStdIO* piPerl, FILE* pf, const Fpos_t *p);
void PerlStdIOInit(struct IPerlStdIO* piPerl);
void PerlStdIOInitOSExtras(struct IPerlStdIO* piPerl);
int PerlStdIOOpenOSfhandle(struct IPerlStdIO* piPerl, long osfhandle, int flags);
int PerlStdIOGetOSfhandle(struct IPerlStdIO* piPerl, int filenum);
FILE* PerlStdIOFdupopen(struct IPerlStdIO* piPerl, FILE* pf);

struct IPerlStdIO perlStdIO =
{
	PerlStdIOStdin,
    PerlStdIOStdout,
    PerlStdIOStderr,
    PerlStdIOOpen,
    PerlStdIOClose,
    PerlStdIOEof,
    PerlStdIOError,
    PerlStdIOClearerr,
    PerlStdIOGetc,
    PerlStdIOGetBase,
    PerlStdIOGetBufsiz,
    PerlStdIOGetCnt,
    PerlStdIOGetPtr,
    PerlStdIOGets,
    PerlStdIOPutc,
    PerlStdIOPuts,
    PerlStdIOFlush,
    PerlStdIOUngetc,
    PerlStdIOFileno,
    PerlStdIOFdopen,
    PerlStdIOReopen,
    PerlStdIORead,
    PerlStdIOWrite,
    PerlStdIOSetBuf,
    PerlStdIOSetVBuf,
    PerlStdIOSetCnt,
    PerlStdIOSetPtr,
    PerlStdIOSetlinebuf,
    PerlStdIOPrintf,
    PerlStdIOVprintf,
    PerlStdIOTell,
    PerlStdIOSeek,
    PerlStdIORewind,
    PerlStdIOTmpfile,
    PerlStdIOGetpos,
    PerlStdIOSetpos,
    PerlStdIOInit,
    PerlStdIOInitOSExtras,
    PerlStdIOFdupopen,
};

/* IPerlStdio	- Stdio functions - End   ================================================*/

/* IPerlLIO	- Low-level IO functions - Begin =============================================*/

int PerlLIOAccess(struct IPerlLIO* piPerl, const char *path, int mode);
int PerlLIOChmod(struct IPerlLIO* piPerl, const char *filename, int pmode);
int PerlLIOChown(struct IPerlLIO* piPerl, const char *filename, uid_t owner, gid_t group);
int PerlLIOChsize(struct IPerlLIO* piPerl, int handle, long size);
int PerlLIOClose(struct IPerlLIO* piPerl, int handle);
int PerlLIODup(struct IPerlLIO* piPerl, int handle);
int PerlLIODup2(struct IPerlLIO* piPerl, int handle1, int handle2);
int PerlLIOFlock(struct IPerlLIO* piPerl, int fd, int oper);
int PerlLIOFileStat(struct IPerlLIO* piPerl, int handle, struct stat *buffer);
int PerlLIOIOCtl(struct IPerlLIO* piPerl, int i, unsigned int u, char *data);
int PerlLIOIsatty(struct IPerlLIO* piPerl, int fd);
int PerlLIOLink(struct IPerlLIO* piPerl, const char*oldname, const char *newname);
long PerlLIOLseek(struct IPerlLIO* piPerl, int handle, long offset, int origin);
int PerlLIOLstat(struct IPerlLIO* piPerl, const char *path, struct stat *buffer);
char* PerlLIOMktemp(struct IPerlLIO* piPerl, char *Template);
int PerlLIOOpen(struct IPerlLIO* piPerl, const char *filename, int oflag);
int PerlLIOOpen3(struct IPerlLIO* piPerl, const char *filename, int oflag, int pmode);
int PerlLIORead(struct IPerlLIO* piPerl, int handle, void *buffer, unsigned int count);
int PerlLIORename(struct IPerlLIO* piPerl, const char *OldFileName, const char *newname);
int PerlLIOSetmode(struct IPerlLIO* piPerl, FILE *fp, int mode);
int PerlLIONameStat(struct IPerlLIO* piPerl, const char *path, struct stat *buffer);
char* PerlLIOTmpnam(struct IPerlLIO* piPerl, char *string);
int PerlLIOUmask(struct IPerlLIO* piPerl, int pmode);
int PerlLIOUnlink(struct IPerlLIO* piPerl, const char *filename);
int PerlLIOUtime(struct IPerlLIO* piPerl, char *filename, struct utimbuf *times);
int PerlLIOWrite(struct IPerlLIO* piPerl, int handle, const void *buffer, unsigned int count);

struct IPerlLIO perlLIO =
{
	PerlLIOAccess,
    PerlLIOChmod,
    PerlLIOChown,
    PerlLIOChsize,
    PerlLIOClose,
    PerlLIODup,
    PerlLIODup2,
    PerlLIOFlock,
    PerlLIOFileStat,
    PerlLIOIOCtl,
    PerlLIOIsatty,
    PerlLIOLink,
    PerlLIOLseek,
    PerlLIOLstat,
    PerlLIOMktemp,
    PerlLIOOpen,
    PerlLIOOpen3,
    PerlLIORead,
    PerlLIORename,
    PerlLIOSetmode,
    PerlLIONameStat,
    PerlLIOTmpnam,
    PerlLIOUmask,
    PerlLIOUnlink,
    PerlLIOUtime,
    PerlLIOWrite,    
};

/* IPerlLIO	- Low-level IO functions - End ==============================================*/

/* IPerlProc - Process control functions - Begin =========================================*/

void PerlProcAbort(struct IPerlProc* piPerl);
char * PerlProcCrypt(struct IPerlProc* piPerl, const char* clear, const char* salt);
void PerlProcExit(struct IPerlProc* piPerl, int status);
void PerlProc_Exit(struct IPerlProc* piPerl, int status);
int PerlProcExecl(struct IPerlProc* piPerl, const char *cmdname, const char *arg0, const char *arg1, const char *arg2, const char *arg3);
int PerlProcExecv(struct IPerlProc* piPerl, const char *cmdname, const char *const *argv);
int PerlProcExecvp(struct IPerlProc* piPerl, const char *cmdname, const char *const *argv);
uid_t PerlProcGetuid(struct IPerlProc* piPerl);
uid_t PerlProcGeteuid(struct IPerlProc* piPerl);
gid_t PerlProcGetgid(struct IPerlProc* piPerl);
gid_t PerlProcGetegid(struct IPerlProc* piPerl);
char * PerlProcGetlogin(struct IPerlProc* piPerl);
int PerlProcKill(struct IPerlProc* piPerl, int pid, int sig);
int PerlProcKillpg(struct IPerlProc* piPerl, int pid, int sig);
int PerlProcPauseProc(struct IPerlProc* piPerl);
PerlIO* PerlProcPopen(struct IPerlProc* piPerl, const char *command, const char *mode);
int PerlProcPclose(struct IPerlProc* piPerl, PerlIO *stream);
int PerlProcPipe(struct IPerlProc* piPerl, int *phandles);
int PerlProcSetuid(struct IPerlProc* piPerl, uid_t u);
int PerlProcSetgid(struct IPerlProc* piPerl, gid_t g);
int PerlProcSleep(struct IPerlProc* piPerl, unsigned int s);
int PerlProcTimes(struct IPerlProc* piPerl, struct tms *timebuf);
int PerlProcWait(struct IPerlProc* piPerl, int *status);
int PerlProcWaitpid(struct IPerlProc* piPerl, int pid, int *status, int flags);
Sighandler_t PerlProcSignal(struct IPerlProc* piPerl, int sig, Sighandler_t subcode);
int PerlProcFork(struct IPerlProc* piPerl);
int PerlProcGetpid(struct IPerlProc* piPerl);
int PerlProcSpawn(struct IPerlProc* piPerl, char* cmds);
int PerlProcSpawnvp(struct IPerlProc* piPerl, int mode, const char *cmdname, const char *const *argv);
int PerlProcASpawn(struct IPerlProc* piPerl, void *vreally, void **vmark, void **vsp);

struct IPerlProc perlProc =
{
    PerlProcAbort,
    PerlProcCrypt,
    PerlProcExit,
    PerlProc_Exit,
    PerlProcExecl,
    PerlProcExecv,
    PerlProcExecvp,
    PerlProcGetuid,
    PerlProcGeteuid,
    PerlProcGetgid,
    PerlProcGetegid,
    PerlProcGetlogin,
    PerlProcKill,
    PerlProcKillpg,
    PerlProcPauseProc,
    PerlProcPopen,
    PerlProcPclose,
    PerlProcPipe,
    PerlProcSetuid,
    PerlProcSetgid,
    PerlProcSleep,
    PerlProcTimes,
    PerlProcWait,
    PerlProcWaitpid,
    PerlProcSignal,
    PerlProcFork,
    PerlProcGetpid,
    //PerlProcLastHost;
    //PerlProcPopenList;
};

/* IPerlProc - Process control functions - End   =========================================*/

/* IPerlSock - Socket functions - Begin ==================================================*/

u_long PerlSockHtonl(struct IPerlSock* piPerl, u_long hostlong);
u_short PerlSockHtons(struct IPerlSock* piPerl, u_short hostshort);
u_long PerlSockNtohl(struct IPerlSock* piPerl, u_long netlong);
u_short PerlSockNtohs(struct IPerlSock* piPerl, u_short netshort);
SOCKET PerlSockAccept(struct IPerlSock* piPerl, SOCKET s, struct sockaddr* addr, int* addrlen);
int PerlSockBind(struct IPerlSock* piPerl, SOCKET s, const struct sockaddr* name, int namelen);
int PerlSockConnect(struct IPerlSock* piPerl, SOCKET s, const struct sockaddr* name, int namelen);
void PerlSockEndhostent(struct IPerlSock* piPerl);
void PerlSockEndnetent(struct IPerlSock* piPerl);
void PerlSockEndprotoent(struct IPerlSock* piPerl);
void PerlSockEndservent(struct IPerlSock* piPerl);
struct hostent* PerlSockGethostbyaddr(struct IPerlSock* piPerl, const char* addr, int len, int type);
struct hostent* PerlSockGethostbyname(struct IPerlSock* piPerl, const char* name);
struct hostent* PerlSockGethostent(struct IPerlSock* piPerl);
int PerlSockGethostname(struct IPerlSock* piPerl, char* name, int namelen);
struct netent * PerlSockGetnetbyaddr(struct IPerlSock* piPerl, long net, int type);
struct netent * PerlSockGetnetbyname(struct IPerlSock* piPerl, const char *name);
struct netent * PerlSockGetnetent(struct IPerlSock* piPerl);
int PerlSockGetpeername(struct IPerlSock* piPerl, SOCKET s, struct sockaddr* name, int* namelen);
struct protoent* PerlSockGetprotobyname(struct IPerlSock* piPerl, const char* name);
struct protoent* PerlSockGetprotobynumber(struct IPerlSock* piPerl, int number);
struct protoent* PerlSockGetprotoent(struct IPerlSock* piPerl);
struct servent* PerlSockGetservbyname(struct IPerlSock* piPerl, const char* name, const char* proto);
struct servent* PerlSockGetservbyport(struct IPerlSock* piPerl, int port, const char* proto);
struct servent* PerlSockGetservent(struct IPerlSock* piPerl);
int PerlSockGetsockname(struct IPerlSock* piPerl, SOCKET s, struct sockaddr* name, int* namelen);
int PerlSockGetsockopt(struct IPerlSock* piPerl, SOCKET s, int level, int optname, char* optval, int* optlen);
unsigned long PerlSockInetAddr(struct IPerlSock* piPerl, const char* cp);
char* PerlSockInetNtoa(struct IPerlSock* piPerl, struct in_addr in);
int PerlSockListen(struct IPerlSock* piPerl, SOCKET s, int backlog);
int PerlSockRecv(struct IPerlSock* piPerl, SOCKET s, char* buffer, int len, int flags);
int PerlSockRecvfrom(struct IPerlSock* piPerl, SOCKET s, char* buffer, int len, int flags, struct sockaddr* from, int* fromlen);
int PerlSockSelect(struct IPerlSock* piPerl, int nfds, char* readfds, char* writefds, char* exceptfds, const struct timeval* timeout);
int PerlSockSend(struct IPerlSock* piPerl, SOCKET s, const char* buffer, int len, int flags);
int PerlSockSendto(struct IPerlSock* piPerl, SOCKET s, const char* buffer, int len, int flags, const struct sockaddr* to, int tolen);
void PerlSockSethostent(struct IPerlSock* piPerl, int stayopen);
void PerlSockSetnetent(struct IPerlSock* piPerl, int stayopen);
void PerlSockSetprotoent(struct IPerlSock* piPerl, int stayopen);
void PerlSockSetservent(struct IPerlSock* piPerl, int stayopen);
int PerlSockSetsockopt(struct IPerlSock* piPerl, SOCKET s, int level, int optname, const char* optval, int optlen);
int PerlSockShutdown(struct IPerlSock* piPerl, SOCKET s, int how);
SOCKET PerlSockSocket(struct IPerlSock* piPerl, int af, int type, int protocol);
int PerlSockSocketpair(struct IPerlSock* piPerl, int domain, int type, int protocol, int* fds);
int PerlSockIoctlsocket(struct IPerlSock* piPerl, SOCKET s, long cmd, u_long *argp);

struct IPerlSock  perlSock =
{
	PerlSockHtonl,
    PerlSockHtons,
    PerlSockNtohl,
    PerlSockNtohs,
    PerlSockAccept,
    PerlSockBind,
    PerlSockConnect,
    PerlSockEndhostent,
    PerlSockEndnetent,
    PerlSockEndprotoent,
    PerlSockEndservent,
    PerlSockGethostname,
    PerlSockGetpeername,
    PerlSockGethostbyaddr,
    PerlSockGethostbyname,
    PerlSockGethostent,
    PerlSockGetnetbyaddr,
    PerlSockGetnetbyname,
    PerlSockGetnetent,
    PerlSockGetprotobyname,
    PerlSockGetprotobynumber,
    PerlSockGetprotoent,
    PerlSockGetservbyname,
    PerlSockGetservbyport,
    PerlSockGetservent,
    PerlSockGetsockname,
    PerlSockGetsockopt,
    PerlSockInetAddr,
	PerlSockInetNtoa,
	PerlSockListen,
    PerlSockRecv,
    PerlSockRecvfrom,
    PerlSockSelect,
    PerlSockSend,
    PerlSockSendto,
    PerlSockSethostent,
    PerlSockSetnetent,
    PerlSockSetprotoent,
    PerlSockSetservent,
    PerlSockSetsockopt,
    PerlSockShutdown,
	PerlSockSocket,
    PerlSockSocketpair,
};

/* IPerlSock - Socket functions - End ====================================================*/

#endif /* ___NWPerlSys_H___ */
