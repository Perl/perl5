/*
 * "The Road goes ever on and on, down from the door where it began."
 */


#include "EXTERN.h"
#include "perl.h"

#ifdef PERL_OBJECT
#define NO_XSLOCKS
#endif

#include "XSUB.h"

#ifdef PERL_OBJECT
#include "win32iop.h"
#include <fcntl.h>
#endif


/* Register any extra external extensions */
char *staticlinkmodules[] = {
    "DynaLoader",
    NULL,
};

EXTERN_C void boot_DynaLoader (pTHXo_ CV* cv);

static void
xs_init(pTHXo)
{
    char *file = __FILE__;
    dXSUB_SYS;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

#ifdef PERL_OBJECT
// IPerlMem
void*
PerlMemMalloc(struct IPerlMem*, size_t size)
{
    return win32_malloc(size);
}
void*
PerlMemRealloc(struct IPerlMem*, void* ptr, size_t size)
{
    return win32_realloc(ptr, size);
}
void
PerlMemFree(struct IPerlMem*, void* ptr)
{
    win32_free(ptr);
}

struct IPerlMem perlMem =
{
    PerlMemMalloc,
    PerlMemRealloc,
    PerlMemFree,
};


// IPerlEnv
extern char *		g_win32_get_privlib(char *pl);
extern char *		g_win32_get_sitelib(char *pl);


char*
PerlEnvGetenv(struct IPerlEnv*, const char *varname)
{
    return win32_getenv(varname);
};
int
PerlEnvPutenv(struct IPerlEnv*, const char *envstring)
{
    return win32_putenv(envstring);
};

char*
PerlEnvGetenv_len(struct IPerlEnv*, const char* varname, unsigned long* len)
{
    char *e = win32_getenv(varname);
    if (e)
	*len = strlen(e);
    return e;
}

int
PerlEnvUname(struct IPerlEnv*, struct utsname *name)
{
    return win32_uname(name);
}

unsigned long
PerlEnvOsId(struct IPerlEnv*)
{
    return win32_os_id();
}

char*
PerlEnvLibPath(struct IPerlEnv*, char *pl)
{
    return g_win32_get_privlib(pl);
}

char*
PerlEnvSiteLibPath(struct IPerlEnv*, char *pl)
{
    return g_win32_get_sitelib(pl);
}

struct IPerlEnv perlEnv = 
{
    PerlEnvGetenv,
    PerlEnvPutenv,
    PerlEnvGetenv_len,
    PerlEnvUname,
    NULL,
    PerlEnvOsId,
    PerlEnvLibPath,
    PerlEnvSiteLibPath,
};


// PerlStdIO
PerlIO*
PerlStdIOStdin(struct IPerlStdIO*)
{
    return (PerlIO*)win32_stdin();
}

PerlIO*
PerlStdIOStdout(struct IPerlStdIO*)
{
    return (PerlIO*)win32_stdout();
}

PerlIO*
PerlStdIOStderr(struct IPerlStdIO*)
{
    return (PerlIO*)win32_stderr();
}

PerlIO*
PerlStdIOOpen(struct IPerlStdIO*, const char *path, const char *mode)
{
    return (PerlIO*)win32_fopen(path, mode);
}

int
PerlStdIOClose(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_fclose(((FILE*)pf));
}

int
PerlStdIOEof(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_feof((FILE*)pf);
}

int
PerlStdIOError(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_ferror((FILE*)pf);
}

void
PerlStdIOClearerr(struct IPerlStdIO*, PerlIO* pf)
{
    win32_clearerr((FILE*)pf);
}

int
PerlStdIOGetc(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_getc((FILE*)pf);
}

char*
PerlStdIOGetBase(struct IPerlStdIO*, PerlIO* pf)
{
#ifdef FILE_base
    FILE *f = (FILE*)pf;
    return FILE_base(f);
#else
    return Nullch;
#endif
}

int
PerlStdIOGetBufsiz(struct IPerlStdIO*, PerlIO* pf)
{
#ifdef FILE_bufsiz
    FILE *f = (FILE*)pf;
    return FILE_bufsiz(f);
#else
    return (-1);
#endif
}

int
PerlStdIOGetCnt(struct IPerlStdIO*, PerlIO* pf)
{
#ifdef USE_STDIO_PTR
    FILE *f = (FILE*)pf;
    return FILE_cnt(f);
#else
    return (-1);
#endif
}

char*
PerlStdIOGetPtr(struct IPerlStdIO*, PerlIO* pf)
{
#ifdef USE_STDIO_PTR
    FILE *f = (FILE*)pf;
    return FILE_ptr(f);
#else
    return Nullch;
#endif
}

char*
PerlStdIOGets(struct IPerlStdIO*, PerlIO* pf, char* s, int n)
{
    return win32_fgets(s, n, (FILE*)pf);
}

int
PerlStdIOPutc(struct IPerlStdIO*, PerlIO* pf, int c)
{
    return win32_fputc(c, (FILE*)pf);
}

int
PerlStdIOPuts(struct IPerlStdIO*, PerlIO* pf, const char *s)
{
    return win32_fputs(s, (FILE*)pf);
}

int
PerlStdIOFlush(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_fflush((FILE*)pf);
}

int
PerlStdIOUngetc(struct IPerlStdIO*, PerlIO* pf,int c)
{
    return win32_ungetc(c, (FILE*)pf);
}

int
PerlStdIOFileno(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_fileno((FILE*)pf);
}

PerlIO*
PerlStdIOFdopen(struct IPerlStdIO*, int fd, const char *mode)
{
    return (PerlIO*)win32_fdopen(fd, mode);
}

PerlIO*
PerlStdIOReopen(struct IPerlStdIO*, const char*path, const char*mode, PerlIO* pf)
{
    return (PerlIO*)win32_freopen(path, mode, (FILE*)pf);
}

SSize_t
PerlStdIORead(struct IPerlStdIO*, PerlIO* pf, void *buffer, Size_t size)
{
    return win32_fread(buffer, 1, size, (FILE*)pf);
}

SSize_t
PerlStdIOWrite(struct IPerlStdIO*, PerlIO* pf, const void *buffer, Size_t size)
{
    return win32_fwrite(buffer, 1, size, (FILE*)pf);
}

void
PerlStdIOSetBuf(struct IPerlStdIO*, PerlIO* pf, char* buffer)
{
    win32_setbuf((FILE*)pf, buffer);
}

int
PerlStdIOSetVBuf(struct IPerlStdIO*, PerlIO* pf, char* buffer, int type, Size_t size)
{
    return win32_setvbuf((FILE*)pf, buffer, type, size);
}

void
PerlStdIOSetCnt(struct IPerlStdIO*, PerlIO* pf, int n)
{
#ifdef STDIO_CNT_LVALUE
    FILE *f = (FILE*)pf;
    FILE_cnt(f) = n;
#endif
}

void
PerlStdIOSetPtrCnt(struct IPerlStdIO*, PerlIO* pf, char * ptr, int n)
{
#ifdef STDIO_PTR_LVALUE
    FILE *f = (FILE*)pf;
    FILE_ptr(f) = ptr;
    FILE_cnt(f) = n;
#endif
}

void
PerlStdIOSetlinebuf(struct IPerlStdIO*, PerlIO* pf)
{
    win32_setvbuf((FILE*)pf, NULL, _IOLBF, 0);
}

int
PerlStdIOPrintf(struct IPerlStdIO*, PerlIO* pf, const char *format,...)
{
    va_list(arglist);
    va_start(arglist, format);
    return win32_vfprintf((FILE*)pf, format, arglist);
}

int
PerlStdIOVprintf(struct IPerlStdIO*, PerlIO* pf, const char *format, va_list arglist)
{
    return win32_vfprintf((FILE*)pf, format, arglist);
}

long
PerlStdIOTell(struct IPerlStdIO*, PerlIO* pf)
{
    return win32_ftell((FILE*)pf);
}

int
PerlStdIOSeek(struct IPerlStdIO*, PerlIO* pf, off_t offset, int origin)
{
    return win32_fseek((FILE*)pf, offset, origin);
}

void
PerlStdIORewind(struct IPerlStdIO*, PerlIO* pf)
{
    win32_rewind((FILE*)pf);
}

PerlIO*
PerlStdIOTmpfile(struct IPerlStdIO*)
{
    return (PerlIO*)win32_tmpfile();
}

int
PerlStdIOGetpos(struct IPerlStdIO*, PerlIO* pf, Fpos_t *p)
{
    return win32_fgetpos((FILE*)pf, p);
}

int
PerlStdIOSetpos(struct IPerlStdIO*, PerlIO* pf, const Fpos_t *p)
{
    return win32_fsetpos((FILE*)pf, p);
}
void
PerlStdIOInit(struct IPerlStdIO*)
{
}

void
PerlStdIOInitOSExtras(struct IPerlStdIO*)
{
    Perl_init_os_extras();
}

int
PerlStdIOOpenOSfhandle(struct IPerlStdIO*, long osfhandle, int flags)
{
    return win32_open_osfhandle(osfhandle, flags);
}

int
PerlStdIOGetOSfhandle(struct IPerlStdIO*, int filenum)
{
    return win32_get_osfhandle(filenum);
}


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
    PerlStdIOSetPtrCnt,
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
};


// IPerlLIO
int
PerlLIOAccess(struct IPerlLIO*, const char *path, int mode)
{
    return access(path, mode);
}

int
PerlLIOChmod(struct IPerlLIO*, const char *filename, int pmode)
{
    return chmod(filename, pmode);
}

int
PerlLIOChown(struct IPerlLIO*, const char *filename, uid_t owner, gid_t group)
{
    return chown(filename, owner, group);
}

int
PerlLIOChsize(struct IPerlLIO*, int handle, long size)
{
    return chsize(handle, size);
}

int
PerlLIOClose(struct IPerlLIO*, int handle)
{
    return win32_close(handle);
}

int
PerlLIODup(struct IPerlLIO*, int handle)
{
    return win32_dup(handle);
}

int
PerlLIODup2(struct IPerlLIO*, int handle1, int handle2)
{
    return win32_dup2(handle1, handle2);
}

int
PerlLIOFlock(struct IPerlLIO*, int fd, int oper)
{
    return win32_flock(fd, oper);
}

int
PerlLIOFileStat(struct IPerlLIO*, int handle, struct stat *buffer)
{
    return fstat(handle, buffer);
}

int
PerlLIOIOCtl(struct IPerlLIO*, int i, unsigned int u, char *data)
{
    return win32_ioctlsocket((SOCKET)i, (long)u, (u_long*)data);
}

int
PerlLIOIsatty(struct IPerlLIO*, int fd)
{
    return isatty(fd);
}

long
PerlLIOLseek(struct IPerlLIO*, int handle, long offset, int origin)
{
    return win32_lseek(handle, offset, origin);
}

int
PerlLIOLstat(struct IPerlLIO* p, const char *path, struct stat *buffer)
{
    return win32_stat(path, buffer);
}

char*
PerlLIOMktemp(struct IPerlLIO*, char *Template)
{
    return mktemp(Template);
}

int
PerlLIOOpen(struct IPerlLIO*, const char *filename, int oflag)
{
    return win32_open(filename, oflag);
}

int
PerlLIOOpen3(struct IPerlLIO*, const char *filename, int oflag, int pmode)
{
    int ret;
    if(stricmp(filename, "/dev/null") == 0)
	ret = open("NUL", oflag, pmode);
    else
	ret = open(filename, oflag, pmode);

    return ret;
}

int
PerlLIORead(struct IPerlLIO*, int handle, void *buffer, unsigned int count)
{
    return win32_read(handle, buffer, count);
}

int
PerlLIORename(struct IPerlLIO*, const char *OldFileName, const char *newname)
{
    return win32_rename(OldFileName, newname);
}

int
PerlLIOSetmode(struct IPerlLIO*, int handle, int mode)
{
    return win32_setmode(handle, mode);
}

int
PerlLIONameStat(struct IPerlLIO*, const char *path, struct stat *buffer)
{
    return win32_stat(path, buffer);
}

char*
PerlLIOTmpnam(struct IPerlLIO*, char *string)
{
    return tmpnam(string);
}

int
PerlLIOUmask(struct IPerlLIO*, int pmode)
{
    return umask(pmode);
}

int
PerlLIOUnlink(struct IPerlLIO*, const char *filename)
{
    chmod(filename, S_IREAD | S_IWRITE);
    return unlink(filename);
}

int
PerlLIOUtime(struct IPerlLIO*, char *filename, struct utimbuf *times)
{
    return win32_utime(filename, times);
}

int
PerlLIOWrite(struct IPerlLIO*, int handle, const void *buffer, unsigned int count)
{
    return win32_write(handle, buffer, count);
}

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

// IPerlDIR
int
PerlDirMakedir(struct IPerlDir*, const char *dirname, int mode)
{
    return win32_mkdir(dirname, mode);
}

int
PerlDirChdir(struct IPerlDir*, const char *dirname)
{
    return win32_chdir(dirname);
}

int
PerlDirRmdir(struct IPerlDir*, const char *dirname)
{
    return win32_rmdir(dirname);
}

int
PerlDirClose(struct IPerlDir*, DIR *dirp)
{
    return win32_closedir(dirp);
}

DIR*
PerlDirOpen(struct IPerlDir*, char *filename)
{
    return win32_opendir(filename);
}

struct direct *
PerlDirRead(struct IPerlDir*, DIR *dirp)
{
    return win32_readdir(dirp);
}

void
PerlDirRewind(struct IPerlDir*, DIR *dirp)
{
    win32_rewinddir(dirp);
}

void
PerlDirSeek(struct IPerlDir*, DIR *dirp, long loc)
{
    win32_seekdir(dirp, loc);
}

long
PerlDirTell(struct IPerlDir*, DIR *dirp)
{
    return win32_telldir(dirp);
}

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


// IPerlSock
u_long
PerlSockHtonl(struct IPerlSock*, u_long hostlong)
{
    return win32_htonl(hostlong);
}

u_short
PerlSockHtons(struct IPerlSock*, u_short hostshort)
{
    return win32_htons(hostshort);
}

u_long
PerlSockNtohl(struct IPerlSock*, u_long netlong)
{
    return win32_ntohl(netlong);
}

u_short
PerlSockNtohs(struct IPerlSock*, u_short netshort)
{
    return win32_ntohs(netshort);
}

SOCKET PerlSockAccept(struct IPerlSock*, SOCKET s, struct sockaddr* addr, int* addrlen)
{
    return win32_accept(s, addr, addrlen);
}

int
PerlSockBind(struct IPerlSock*, SOCKET s, const struct sockaddr* name, int namelen)
{
    return win32_bind(s, name, namelen);
}

int
PerlSockConnect(struct IPerlSock*, SOCKET s, const struct sockaddr* name, int namelen)
{
    return win32_connect(s, name, namelen);
}

void
PerlSockEndhostent(struct IPerlSock*)
{
    win32_endhostent();
}

void
PerlSockEndnetent(struct IPerlSock*)
{
    win32_endnetent();
}

void
PerlSockEndprotoent(struct IPerlSock*)
{
    win32_endprotoent();
}

void
PerlSockEndservent(struct IPerlSock*)
{
    win32_endservent();
}

struct hostent*
PerlSockGethostbyaddr(struct IPerlSock*, const char* addr, int len, int type)
{
    return win32_gethostbyaddr(addr, len, type);
}

struct hostent*
PerlSockGethostbyname(struct IPerlSock*, const char* name)
{
    return win32_gethostbyname(name);
}

struct hostent*
PerlSockGethostent(struct IPerlSock*)
{
    dTHXo;
    croak("gethostent not implemented!\n");
    return NULL;
}

int
PerlSockGethostname(struct IPerlSock*, char* name, int namelen)
{
    return win32_gethostname(name, namelen);
}

struct netent *
PerlSockGetnetbyaddr(struct IPerlSock*, long net, int type)
{
    return win32_getnetbyaddr(net, type);
}

struct netent *
PerlSockGetnetbyname(struct IPerlSock*, const char *name)
{
    return win32_getnetbyname((char*)name);
}

struct netent *
PerlSockGetnetent(struct IPerlSock*)
{
    return win32_getnetent();
}

int PerlSockGetpeername(struct IPerlSock*, SOCKET s, struct sockaddr* name, int* namelen)
{
    return win32_getpeername(s, name, namelen);
}

struct protoent*
PerlSockGetprotobyname(struct IPerlSock*, const char* name)
{
    return win32_getprotobyname(name);
}

struct protoent*
PerlSockGetprotobynumber(struct IPerlSock*, int number)
{
    return win32_getprotobynumber(number);
}

struct protoent*
PerlSockGetprotoent(struct IPerlSock*)
{
    return win32_getprotoent();
}

struct servent*
PerlSockGetservbyname(struct IPerlSock*, const char* name, const char* proto)
{
    return win32_getservbyname(name, proto);
}

struct servent*
PerlSockGetservbyport(struct IPerlSock*, int port, const char* proto)
{
    return win32_getservbyport(port, proto);
}

struct servent*
PerlSockGetservent(struct IPerlSock*)
{
    return win32_getservent();
}

int
PerlSockGetsockname(struct IPerlSock*, SOCKET s, struct sockaddr* name, int* namelen)
{
    return win32_getsockname(s, name, namelen);
}

int
PerlSockGetsockopt(struct IPerlSock*, SOCKET s, int level, int optname, char* optval, int* optlen)
{
    return win32_getsockopt(s, level, optname, optval, optlen);
}

unsigned long
PerlSockInetAddr(struct IPerlSock*, const char* cp)
{
    return win32_inet_addr(cp);
}

char*
PerlSockInetNtoa(struct IPerlSock*, struct in_addr in)
{
    return win32_inet_ntoa(in);
}

int
PerlSockListen(struct IPerlSock*, SOCKET s, int backlog)
{
    return win32_listen(s, backlog);
}

int
PerlSockRecv(struct IPerlSock*, SOCKET s, char* buffer, int len, int flags)
{
    return win32_recv(s, buffer, len, flags);
}

int
PerlSockRecvfrom(struct IPerlSock*, SOCKET s, char* buffer, int len, int flags, struct sockaddr* from, int* fromlen)
{
    return win32_recvfrom(s, buffer, len, flags, from, fromlen);
}

int
PerlSockSelect(struct IPerlSock*, int nfds, char* readfds, char* writefds, char* exceptfds, const struct timeval* timeout)
{
    return win32_select(nfds, (Perl_fd_set*)readfds, (Perl_fd_set*)writefds, (Perl_fd_set*)exceptfds, timeout);
}

int
PerlSockSend(struct IPerlSock*, SOCKET s, const char* buffer, int len, int flags)
{
    return win32_send(s, buffer, len, flags);
}

int
PerlSockSendto(struct IPerlSock*, SOCKET s, const char* buffer, int len, int flags, const struct sockaddr* to, int tolen)
{
    return win32_sendto(s, buffer, len, flags, to, tolen);
}

void
PerlSockSethostent(struct IPerlSock*, int stayopen)
{
    win32_sethostent(stayopen);
}

void
PerlSockSetnetent(struct IPerlSock*, int stayopen)
{
    win32_setnetent(stayopen);
}

void
PerlSockSetprotoent(struct IPerlSock*, int stayopen)
{
    win32_setprotoent(stayopen);
}

void
PerlSockSetservent(struct IPerlSock*, int stayopen)
{
    win32_setservent(stayopen);
}

int
PerlSockSetsockopt(struct IPerlSock*, SOCKET s, int level, int optname, const char* optval, int optlen)
{
    return win32_setsockopt(s, level, optname, optval, optlen);
}

int
PerlSockShutdown(struct IPerlSock*, SOCKET s, int how)
{
    return win32_shutdown(s, how);
}

SOCKET
PerlSockSocket(struct IPerlSock*, int af, int type, int protocol)
{
    return win32_socket(af, type, protocol);
}

int
PerlSockSocketpair(struct IPerlSock*, int domain, int type, int protocol, int* fds)
{
    dTHXo;
    croak("socketpair not implemented!\n");
    return 0;
}

int
PerlSockClosesocket(struct IPerlSock*, SOCKET s)
{
    return win32_closesocket(s);
}

int
PerlSockIoctlsocket(struct IPerlSock*, SOCKET s, long cmd, u_long *argp)
{
    return win32_ioctlsocket(s, cmd, argp);
}

struct IPerlSock perlSock =
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
    PerlSockClosesocket,
};


// IPerlProc

#define EXECF_EXEC 1
#define EXECF_SPAWN 2

extern char *		g_getlogin(void);
extern int		do_spawn2(char *cmd, int exectype);
extern int		g_do_aspawn(void *vreally, void **vmark, void **vsp);

void
PerlProcAbort(struct IPerlProc*)
{
    win32_abort();
}

char *
PerlProcCrypt(struct IPerlProc*, const char* clear, const char* salt)
{
    return win32_crypt(clear, salt);
}

void
PerlProcExit(struct IPerlProc*, int status)
{
    exit(status);
}

void
PerlProc_Exit(struct IPerlProc*, int status)
{
    _exit(status);
}

int
PerlProcExecl(struct IPerlProc*, const char *cmdname, const char *arg0, const char *arg1, const char *arg2, const char *arg3)
{
    return execl(cmdname, arg0, arg1, arg2, arg3);
}

int
PerlProcExecv(struct IPerlProc*, const char *cmdname, const char *const *argv)
{
    return win32_execvp(cmdname, argv);
}

int
PerlProcExecvp(struct IPerlProc*, const char *cmdname, const char *const *argv)
{
    return win32_execvp(cmdname, argv);
}

uid_t
PerlProcGetuid(struct IPerlProc*)
{
    return getuid();
}

uid_t
PerlProcGeteuid(struct IPerlProc*)
{
    return geteuid();
}

gid_t
PerlProcGetgid(struct IPerlProc*)
{
    return getgid();
}

gid_t
PerlProcGetegid(struct IPerlProc*)
{
    return getegid();
}

char *
PerlProcGetlogin(struct IPerlProc*)
{
    return g_getlogin();
}

int
PerlProcKill(struct IPerlProc*, int pid, int sig)
{
    return win32_kill(pid, sig);
}

int
PerlProcKillpg(struct IPerlProc*, int pid, int sig)
{
    dTHXo;
    croak("killpg not implemented!\n");
    return 0;
}

int
PerlProcPauseProc(struct IPerlProc*)
{
    return win32_sleep((32767L << 16) + 32767);
}

PerlIO*
PerlProcPopen(struct IPerlProc*, const char *command, const char *mode)
{
    win32_fflush(stdout);
    win32_fflush(stderr);
    return (PerlIO*)win32_popen(command, mode);
}

int
PerlProcPclose(struct IPerlProc*, PerlIO *stream)
{
    return win32_pclose((FILE*)stream);
}

int
PerlProcPipe(struct IPerlProc*, int *phandles)
{
    return win32_pipe(phandles, 512, O_BINARY);
}

int
PerlProcSetuid(struct IPerlProc*, uid_t u)
{
    return setuid(u);
}

int
PerlProcSetgid(struct IPerlProc*, gid_t g)
{
    return setgid(g);
}

int
PerlProcSleep(struct IPerlProc*, unsigned int s)
{
    return win32_sleep(s);
}

int
PerlProcTimes(struct IPerlProc*, struct tms *timebuf)
{
    return win32_times(timebuf);
}

int
PerlProcWait(struct IPerlProc*, int *status)
{
    return win32_wait(status);
}

int
PerlProcWaitpid(struct IPerlProc*, int pid, int *status, int flags)
{
    return win32_waitpid(pid, status, flags);
}

Sighandler_t
PerlProcSignal(struct IPerlProc*, int sig, Sighandler_t subcode)
{
    return 0;
}

void*
PerlProcDynaLoader(struct IPerlProc*, const char* filename)
{
    return win32_dynaload(filename);
}

void
PerlProcGetOSError(struct IPerlProc*, SV* sv, DWORD dwErr)
{
    win32_str_os_error(aTHX_ sv, dwErr);
}

BOOL
PerlProcDoCmd(struct IPerlProc*, char *cmd)
{
    do_spawn2(cmd, EXECF_EXEC);
    return FALSE;
}

int
PerlProcSpawn(struct IPerlProc*, char* cmds)
{
    return do_spawn2(cmds, EXECF_SPAWN);
}

int
PerlProcSpawnvp(struct IPerlProc*, int mode, const char *cmdname, const char *const *argv)
{
    return win32_spawnvp(mode, cmdname, argv);
}

int
PerlProcASpawn(struct IPerlProc*, void *vreally, void **vmark, void **vsp)
{
    return g_do_aspawn(vreally, vmark, vsp);
}

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
    PerlProcDynaLoader,
    PerlProcGetOSError,
    PerlProcDoCmd,
    PerlProcSpawn,
    PerlProcSpawnvp,
    PerlProcASpawn,
};

//#include "perlhost.h"


EXTERN_C void perl_get_host_info(IPerlMemInfo* perlMemInfo,
			IPerlEnvInfo* perlEnvInfo, IPerlStdIOInfo* perlStdIOInfo,
			IPerlLIOInfo* perlLIOInfo, IPerlDirInfo* perlDirInfo,
			IPerlSockInfo* perlSockInfo, IPerlProcInfo* perlProcInfo)
{
    if(perlMemInfo) {
	Copy(&perlMem, &perlMemInfo->perlMemList, perlMemInfo->nCount, void*);
	perlMemInfo->nCount = (sizeof(struct IPerlMem)/sizeof(void*));
    }
    if(perlEnvInfo) {
	Copy(&perlEnv, &perlEnvInfo->perlEnvList, perlEnvInfo->nCount, void*);
	perlEnvInfo->nCount = (sizeof(struct IPerlEnv)/sizeof(void*));
    }
    if(perlStdIOInfo) {
	Copy(&perlStdIO, &perlStdIOInfo->perlStdIOList, perlStdIOInfo->nCount, void*);
	perlStdIOInfo->nCount = (sizeof(struct IPerlStdIO)/sizeof(void*));
    }
    if(perlLIOInfo) {
	Copy(&perlLIO, &perlLIOInfo->perlLIOList, perlLIOInfo->nCount, void*);
	perlLIOInfo->nCount = (sizeof(struct IPerlLIO)/sizeof(void*));
    }
    if(perlDirInfo) {
	Copy(&perlDir, &perlDirInfo->perlDirList, perlDirInfo->nCount, void*);
	perlDirInfo->nCount = (sizeof(struct IPerlDir)/sizeof(void*));
    }
    if(perlSockInfo) {
	Copy(&perlSock, &perlSockInfo->perlSockList, perlSockInfo->nCount, void*);
	perlSockInfo->nCount = (sizeof(struct IPerlSock)/sizeof(void*));
    }
    if(perlProcInfo) {
	Copy(&perlProc, &perlProcInfo->perlProcList, perlProcInfo->nCount, void*);
	perlProcInfo->nCount = (sizeof(struct IPerlProc)/sizeof(void*));
    }
}

EXTERN_C PerlInterpreter* perl_alloc_using(IPerlMem* pMem,
			IPerlEnv* pEnv, IPerlStdIO* pStdIO,
			IPerlLIO* pLIO, IPerlDir* pDir,
			IPerlSock* pSock, IPerlProc* pProc)
{
    CPerlObj* pPerl = NULL;
    try
    {
	pPerl = Perl_alloc(pMem, pEnv, pStdIO, pLIO, pDir, pSock, pProc);
    }
    catch(...)
    {
	win32_fprintf(stderr, "%s\n", "Error: Unable to allocate memory");
	pPerl = NULL;
    }
    if(pPerl)
    {
	SetPerlInterpreter(pPerl);
	return (PerlInterpreter*)pPerl;
    }
    SetPerlInterpreter(NULL);
    return NULL;
}

#undef perl_alloc
#undef perl_construct
#undef perl_destruct
#undef perl_free
#undef perl_run
#undef perl_parse
EXTERN_C PerlInterpreter* perl_alloc(void)
{
    CPerlObj* pPerl = NULL;
    try
    {
	pPerl = Perl_alloc(&perlMem, &perlEnv, &perlStdIO, &perlLIO,
			   &perlDir, &perlSock, &perlProc);
    }
    catch(...)
    {
	win32_fprintf(stderr, "%s\n", "Error: Unable to allocate memory");
	pPerl = NULL;
    }
    if(pPerl)
    {
	SetPerlInterpreter(pPerl);
	return (PerlInterpreter*)pPerl;
    }
    SetPerlInterpreter(NULL);
    return NULL;
}

EXTERN_C void perl_construct(PerlInterpreter* sv_interp)
{
    CPerlObj* pPerl = (CPerlObj*)sv_interp;
    try
    {
	pPerl->perl_construct();
    }
    catch(...)
    {
	win32_fprintf(stderr, "%s\n",
		      "Error: Unable to construct data structures");
	pPerl->perl_free();
	SetPerlInterpreter(NULL);
    }
}

EXTERN_C void perl_destruct(PerlInterpreter* sv_interp)
{
    CPerlObj* pPerl = (CPerlObj*)sv_interp;
    try
    {
	pPerl->perl_destruct();
    }
    catch(...)
    {
    }
}

EXTERN_C void perl_free(PerlInterpreter* sv_interp)
{
    CPerlObj* pPerl = (CPerlObj*)sv_interp;
    try
    {
	pPerl->perl_free();
    }
    catch(...)
    {
    }
    SetPerlInterpreter(NULL);
}

EXTERN_C int perl_run(PerlInterpreter* sv_interp)
{
    CPerlObj* pPerl = (CPerlObj*)sv_interp;
    int retVal;
    try
    {
	retVal = pPerl->perl_run();
    }
/*
    catch(int x)
    {
	// this is where exit() should arrive
	retVal = x;
    }
*/
    catch(...)
    {
	win32_fprintf(stderr, "Error: Runtime exception\n");
	retVal = -1;
    }
    return retVal;
}

EXTERN_C int perl_parse(PerlInterpreter* sv_interp, void (*xsinit)(CPerlObj*), int argc, char** argv, char** env)
{
    int retVal;
    CPerlObj* pPerl = (CPerlObj*)sv_interp;
    try
    {
	retVal = pPerl->perl_parse(xs_init, argc, argv, env);
    }
/*
    catch(int x)
    {
	// this is where exit() should arrive
	retVal = x;
    }
*/
    catch(...)
    {
	win32_fprintf(stderr, "Error: Parse exception\n");
	retVal = -1;
    }
    *win32_errno() = 0;
    return retVal;
}

#undef PL_perl_destruct_level
#define PL_perl_destruct_level int dummy
#undef w32_perldll_handle
#define w32_perldll_handle g_w32_perldll_handle
HANDLE g_w32_perldll_handle;
#else
extern HANDLE w32_perldll_handle;
#endif /* PERL_OBJECT */

static DWORD g_TlsAllocIndex;

EXTERN_C DllExport bool
SetPerlInterpreter(void *interp)
{
    return TlsSetValue(g_TlsAllocIndex, interp);
}

EXTERN_C DllExport void*
GetPerlInterpreter(void)
{
    return TlsGetValue(g_TlsAllocIndex);
}

EXTERN_C DllExport int
RunPerl(int argc, char **argv, char **env)
{
    int exitstatus;
    PerlInterpreter *my_perl;
    struct perl_thread *thr;

#ifndef __BORLANDC__
    /* XXX this _may_ be a problem on some compilers (e.g. Borland) that
     * want to free() argv after main() returns.  As luck would have it,
     * Borland's CRT does the right thing to argv[0] already. */
    char szModuleName[MAX_PATH];
    char *ptr;

    GetModuleFileName(NULL, szModuleName, sizeof(szModuleName));
    (void)win32_longpath(szModuleName);
    argv[0] = szModuleName;
#endif

#ifdef PERL_GLOBAL_STRUCT
#define PERLVAR(var,type) /**/
#define PERLVARA(var,type) /**/
#define PERLVARI(var,type,init) PL_Vars.var = init;
#define PERLVARIC(var,type,init) PL_Vars.var = init;
#include "perlvars.h"
#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#endif

    PERL_SYS_INIT(&argc,&argv);

    if (!(my_perl = perl_alloc()))
	return (1);
    perl_construct( my_perl );
    PL_perl_destruct_level = 0;

    exitstatus = perl_parse(my_perl, xs_init, argc, argv, env);
    if (!exitstatus) {
	exitstatus = perl_run( my_perl );
    }

    perl_destruct( my_perl );
    perl_free( my_perl );

    PERL_SYS_TERM();

    return (exitstatus);
}

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
	setmode( fileno( stdin  ), O_BINARY );
	setmode( fileno( stdout ), O_BINARY );
	setmode( fileno( stderr ), O_BINARY );
	_fmode = O_BINARY;
#endif
	g_TlsAllocIndex = TlsAlloc();
	DisableThreadLibraryCalls(hModule);
#ifndef PERL_OBJECT
	w32_perldll_handle = hModule;
#endif
	break;

	/* The DLL is detaching from a process due to
	 * process termination or call to FreeLibrary.
	 */
    case DLL_PROCESS_DETACH:
	TlsFree(g_TlsAllocIndex);
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

