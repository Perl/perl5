/*
 * "The Road goes ever on and on, down from the door where it began."
 */


#include "EXTERN.h"
#include "perl.h"

#ifdef PERL_OBJECT
#define NO_XSLOCKS
#endif

#include "XSUB.h"

#ifdef PERL_IMPLICIT_SYS
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

#ifdef PERL_IMPLICIT_SYS
/* IPerlMem */
void*
PerlMemMalloc(struct IPerlMem *I, size_t size)
{
    return win32_malloc(size);
}
void*
PerlMemRealloc(struct IPerlMem *I, void* ptr, size_t size)
{
    return win32_realloc(ptr, size);
}
void
PerlMemFree(struct IPerlMem *I, void* ptr)
{
    win32_free(ptr);
}

struct IPerlMem perlMem =
{
    PerlMemMalloc,
    PerlMemRealloc,
    PerlMemFree,
};


/* IPerlEnv */
extern char *		g_win32_get_privlib(char *pl);
extern char *		g_win32_get_sitelib(char *pl);


char*
PerlEnvGetenv(struct IPerlEnv *I, const char *varname)
{
    return win32_getenv(varname);
};
int
PerlEnvPutenv(struct IPerlEnv *I, const char *envstring)
{
    return win32_putenv(envstring);
};

char*
PerlEnvGetenv_len(struct IPerlEnv *I, const char* varname, unsigned long* len)
{
    char *e = win32_getenv(varname);
    if (e)
	*len = strlen(e);
    return e;
}

int
PerlEnvUname(struct IPerlEnv *I, struct utsname *name)
{
    return win32_uname(name);
}

void
PerlEnvClearenv(struct IPerlEnv *I)
{
    dTHXo;
    char *envv = GetEnvironmentStrings();
    char *cur = envv;
    STRLEN len;
    while (*cur) {
	char *end = strchr(cur,'=');
	if (end && end != cur) {
	    *end = '\0';
	    my_setenv(cur,Nullch);
	    *end = '=';
	    cur = end + strlen(end+1)+2;
	}
	else if ((len = strlen(cur)))
	    cur += len+1;
    }
    FreeEnvironmentStrings(envv);
}

void*
PerlEnvGetChildEnv(struct IPerlEnv *I)
{
    return NULL;
}

void
PerlEnvFreeChildEnv(struct IPerlEnv *I, void* env)
{
}

char*
PerlEnvGetChildDir(struct IPerlEnv *I)
{
    return NULL;
}

void
PerlEnvFreeChildDir(struct IPerlEnv *I, char* dir)
{
}

unsigned long
PerlEnvOsId(struct IPerlEnv *I)
{
    return win32_os_id();
}

char*
PerlEnvLibPath(struct IPerlEnv *I, char *pl)
{
    return g_win32_get_privlib(pl);
}

char*
PerlEnvSiteLibPath(struct IPerlEnv *I, char *pl)
{
    return g_win32_get_sitelib(pl);
}

struct IPerlEnv perlEnv = 
{
    PerlEnvGetenv,
    PerlEnvPutenv,
    PerlEnvGetenv_len,
    PerlEnvUname,
    PerlEnvClearenv,
    PerlEnvGetChildEnv,
    PerlEnvFreeChildEnv,
    PerlEnvGetChildDir,
    PerlEnvFreeChildDir,
    PerlEnvOsId,
    PerlEnvLibPath,
    PerlEnvSiteLibPath,
};


/* PerlStdIO */
PerlIO*
PerlStdIOStdin(struct IPerlStdIO *I)
{
    return (PerlIO*)win32_stdin();
}

PerlIO*
PerlStdIOStdout(struct IPerlStdIO *I)
{
    return (PerlIO*)win32_stdout();
}

PerlIO*
PerlStdIOStderr(struct IPerlStdIO *I)
{
    return (PerlIO*)win32_stderr();
}

PerlIO*
PerlStdIOOpen(struct IPerlStdIO *I, const char *path, const char *mode)
{
    return (PerlIO*)win32_fopen(path, mode);
}

int
PerlStdIOClose(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_fclose(((FILE*)pf));
}

int
PerlStdIOEof(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_feof((FILE*)pf);
}

int
PerlStdIOError(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_ferror((FILE*)pf);
}

void
PerlStdIOClearerr(struct IPerlStdIO *I, PerlIO* pf)
{
    win32_clearerr((FILE*)pf);
}

int
PerlStdIOGetc(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_getc((FILE*)pf);
}

char*
PerlStdIOGetBase(struct IPerlStdIO *I, PerlIO* pf)
{
#ifdef FILE_base
    FILE *f = (FILE*)pf;
    return FILE_base(f);
#else
    return Nullch;
#endif
}

int
PerlStdIOGetBufsiz(struct IPerlStdIO *I, PerlIO* pf)
{
#ifdef FILE_bufsiz
    FILE *f = (FILE*)pf;
    return FILE_bufsiz(f);
#else
    return (-1);
#endif
}

int
PerlStdIOGetCnt(struct IPerlStdIO *I, PerlIO* pf)
{
#ifdef USE_STDIO_PTR
    FILE *f = (FILE*)pf;
    return FILE_cnt(f);
#else
    return (-1);
#endif
}

char*
PerlStdIOGetPtr(struct IPerlStdIO *I, PerlIO* pf)
{
#ifdef USE_STDIO_PTR
    FILE *f = (FILE*)pf;
    return FILE_ptr(f);
#else
    return Nullch;
#endif
}

char*
PerlStdIOGets(struct IPerlStdIO *I, PerlIO* pf, char* s, int n)
{
    return win32_fgets(s, n, (FILE*)pf);
}

int
PerlStdIOPutc(struct IPerlStdIO *I, PerlIO* pf, int c)
{
    return win32_fputc(c, (FILE*)pf);
}

int
PerlStdIOPuts(struct IPerlStdIO *I, PerlIO* pf, const char *s)
{
    return win32_fputs(s, (FILE*)pf);
}

int
PerlStdIOFlush(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_fflush((FILE*)pf);
}

int
PerlStdIOUngetc(struct IPerlStdIO *I, PerlIO* pf,int c)
{
    return win32_ungetc(c, (FILE*)pf);
}

int
PerlStdIOFileno(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_fileno((FILE*)pf);
}

PerlIO*
PerlStdIOFdopen(struct IPerlStdIO *I, int fd, const char *mode)
{
    return (PerlIO*)win32_fdopen(fd, mode);
}

PerlIO*
PerlStdIOReopen(struct IPerlStdIO *I, const char*path, const char*mode, PerlIO* pf)
{
    return (PerlIO*)win32_freopen(path, mode, (FILE*)pf);
}

SSize_t
PerlStdIORead(struct IPerlStdIO *I, PerlIO* pf, void *buffer, Size_t size)
{
    return win32_fread(buffer, 1, size, (FILE*)pf);
}

SSize_t
PerlStdIOWrite(struct IPerlStdIO *I, PerlIO* pf, const void *buffer, Size_t size)
{
    return win32_fwrite(buffer, 1, size, (FILE*)pf);
}

void
PerlStdIOSetBuf(struct IPerlStdIO *I, PerlIO* pf, char* buffer)
{
    win32_setbuf((FILE*)pf, buffer);
}

int
PerlStdIOSetVBuf(struct IPerlStdIO *I, PerlIO* pf, char* buffer, int type, Size_t size)
{
    return win32_setvbuf((FILE*)pf, buffer, type, size);
}

void
PerlStdIOSetCnt(struct IPerlStdIO *I, PerlIO* pf, int n)
{
#ifdef STDIO_CNT_LVALUE
    FILE *f = (FILE*)pf;
    FILE_cnt(f) = n;
#endif
}

void
PerlStdIOSetPtrCnt(struct IPerlStdIO *I, PerlIO* pf, char * ptr, int n)
{
#ifdef STDIO_PTR_LVALUE
    FILE *f = (FILE*)pf;
    FILE_ptr(f) = ptr;
    FILE_cnt(f) = n;
#endif
}

void
PerlStdIOSetlinebuf(struct IPerlStdIO *I, PerlIO* pf)
{
    win32_setvbuf((FILE*)pf, NULL, _IOLBF, 0);
}

int
PerlStdIOPrintf(struct IPerlStdIO *I, PerlIO* pf, const char *format,...)
{
    va_list(arglist);
    va_start(arglist, format);
    return win32_vfprintf((FILE*)pf, format, arglist);
}

int
PerlStdIOVprintf(struct IPerlStdIO *I, PerlIO* pf, const char *format, va_list arglist)
{
    return win32_vfprintf((FILE*)pf, format, arglist);
}

long
PerlStdIOTell(struct IPerlStdIO *I, PerlIO* pf)
{
    return win32_ftell((FILE*)pf);
}

int
PerlStdIOSeek(struct IPerlStdIO *I, PerlIO* pf, off_t offset, int origin)
{
    return win32_fseek((FILE*)pf, offset, origin);
}

void
PerlStdIORewind(struct IPerlStdIO *I, PerlIO* pf)
{
    win32_rewind((FILE*)pf);
}

PerlIO*
PerlStdIOTmpfile(struct IPerlStdIO *I)
{
    return (PerlIO*)win32_tmpfile();
}

int
PerlStdIOGetpos(struct IPerlStdIO *I, PerlIO* pf, Fpos_t *p)
{
    return win32_fgetpos((FILE*)pf, p);
}

int
PerlStdIOSetpos(struct IPerlStdIO *I, PerlIO* pf, const Fpos_t *p)
{
    return win32_fsetpos((FILE*)pf, p);
}
void
PerlStdIOInit(struct IPerlStdIO *I)
{
}

void
PerlStdIOInitOSExtras(struct IPerlStdIO *I)
{
    Perl_init_os_extras();
}

int
PerlStdIOOpenOSfhandle(struct IPerlStdIO *I, long osfhandle, int flags)
{
    return win32_open_osfhandle(osfhandle, flags);
}

int
PerlStdIOGetOSfhandle(struct IPerlStdIO *I, int filenum)
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


/* IPerlLIO */
int
PerlLIOAccess(struct IPerlLIO *I, const char *path, int mode)
{
    return access(path, mode);
}

int
PerlLIOChmod(struct IPerlLIO *I, const char *filename, int pmode)
{
    return chmod(filename, pmode);
}

int
PerlLIOChown(struct IPerlLIO *I, const char *filename, uid_t owner, gid_t group)
{
    return chown(filename, owner, group);
}

int
PerlLIOChsize(struct IPerlLIO *I, int handle, long size)
{
    return chsize(handle, size);
}

int
PerlLIOClose(struct IPerlLIO *I, int handle)
{
    return win32_close(handle);
}

int
PerlLIODup(struct IPerlLIO *I, int handle)
{
    return win32_dup(handle);
}

int
PerlLIODup2(struct IPerlLIO *I, int handle1, int handle2)
{
    return win32_dup2(handle1, handle2);
}

int
PerlLIOFlock(struct IPerlLIO *I, int fd, int oper)
{
    return win32_flock(fd, oper);
}

int
PerlLIOFileStat(struct IPerlLIO *I, int handle, struct stat *buffer)
{
    return fstat(handle, buffer);
}

int
PerlLIOIOCtl(struct IPerlLIO *I, int i, unsigned int u, char *data)
{
    return win32_ioctlsocket((SOCKET)i, (long)u, (u_long*)data);
}

int
PerlLIOIsatty(struct IPerlLIO *I, int fd)
{
    return isatty(fd);
}

long
PerlLIOLseek(struct IPerlLIO *I, int handle, long offset, int origin)
{
    return win32_lseek(handle, offset, origin);
}

int
PerlLIOLstat(struct IPerlLIO* p, const char *path, struct stat *buffer)
{
    return win32_stat(path, buffer);
}

char*
PerlLIOMktemp(struct IPerlLIO *I, char *Template)
{
    return mktemp(Template);
}

int
PerlLIOOpen(struct IPerlLIO *I, const char *filename, int oflag)
{
    return win32_open(filename, oflag);
}

int
PerlLIOOpen3(struct IPerlLIO *I, const char *filename, int oflag, int pmode)
{
    int ret;
    if(stricmp(filename, "/dev/null") == 0)
	ret = open("NUL", oflag, pmode);
    else
	ret = open(filename, oflag, pmode);

    return ret;
}

int
PerlLIORead(struct IPerlLIO *I, int handle, void *buffer, unsigned int count)
{
    return win32_read(handle, buffer, count);
}

int
PerlLIORename(struct IPerlLIO *I, const char *OldFileName, const char *newname)
{
    return win32_rename(OldFileName, newname);
}

int
PerlLIOSetmode(struct IPerlLIO *I, int handle, int mode)
{
    return win32_setmode(handle, mode);
}

int
PerlLIONameStat(struct IPerlLIO *I, const char *path, struct stat *buffer)
{
    return win32_stat(path, buffer);
}

char*
PerlLIOTmpnam(struct IPerlLIO *I, char *string)
{
    return tmpnam(string);
}

int
PerlLIOUmask(struct IPerlLIO *I, int pmode)
{
    return umask(pmode);
}

int
PerlLIOUnlink(struct IPerlLIO *I, const char *filename)
{
    chmod(filename, S_IREAD | S_IWRITE);
    return unlink(filename);
}

int
PerlLIOUtime(struct IPerlLIO *I, char *filename, struct utimbuf *times)
{
    return win32_utime(filename, times);
}

int
PerlLIOWrite(struct IPerlLIO *I, int handle, const void *buffer, unsigned int count)
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

/* IPerlDIR */
int
PerlDirMakedir(struct IPerlDir *I, const char *dirname, int mode)
{
    return win32_mkdir(dirname, mode);
}

int
PerlDirChdir(struct IPerlDir *I, const char *dirname)
{
    return win32_chdir(dirname);
}

int
PerlDirRmdir(struct IPerlDir *I, const char *dirname)
{
    return win32_rmdir(dirname);
}

int
PerlDirClose(struct IPerlDir *I, DIR *dirp)
{
    return win32_closedir(dirp);
}

DIR*
PerlDirOpen(struct IPerlDir *I, char *filename)
{
    return win32_opendir(filename);
}

struct direct *
PerlDirRead(struct IPerlDir *I, DIR *dirp)
{
    return win32_readdir(dirp);
}

void
PerlDirRewind(struct IPerlDir *I, DIR *dirp)
{
    win32_rewinddir(dirp);
}

void
PerlDirSeek(struct IPerlDir *I, DIR *dirp, long loc)
{
    win32_seekdir(dirp, loc);
}

long
PerlDirTell(struct IPerlDir *I, DIR *dirp)
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


/* IPerlSock */
u_long
PerlSockHtonl(struct IPerlSock *I, u_long hostlong)
{
    return win32_htonl(hostlong);
}

u_short
PerlSockHtons(struct IPerlSock *I, u_short hostshort)
{
    return win32_htons(hostshort);
}

u_long
PerlSockNtohl(struct IPerlSock *I, u_long netlong)
{
    return win32_ntohl(netlong);
}

u_short
PerlSockNtohs(struct IPerlSock *I, u_short netshort)
{
    return win32_ntohs(netshort);
}

SOCKET PerlSockAccept(struct IPerlSock *I, SOCKET s, struct sockaddr* addr, int* addrlen)
{
    return win32_accept(s, addr, addrlen);
}

int
PerlSockBind(struct IPerlSock *I, SOCKET s, const struct sockaddr* name, int namelen)
{
    return win32_bind(s, name, namelen);
}

int
PerlSockConnect(struct IPerlSock *I, SOCKET s, const struct sockaddr* name, int namelen)
{
    return win32_connect(s, name, namelen);
}

void
PerlSockEndhostent(struct IPerlSock *I)
{
    win32_endhostent();
}

void
PerlSockEndnetent(struct IPerlSock *I)
{
    win32_endnetent();
}

void
PerlSockEndprotoent(struct IPerlSock *I)
{
    win32_endprotoent();
}

void
PerlSockEndservent(struct IPerlSock *I)
{
    win32_endservent();
}

struct hostent*
PerlSockGethostbyaddr(struct IPerlSock *I, const char* addr, int len, int type)
{
    return win32_gethostbyaddr(addr, len, type);
}

struct hostent*
PerlSockGethostbyname(struct IPerlSock *I, const char* name)
{
    return win32_gethostbyname(name);
}

struct hostent*
PerlSockGethostent(struct IPerlSock *I)
{
    dTHXo;
    Perl_croak(aTHX_ "gethostent not implemented!\n");
    return NULL;
}

int
PerlSockGethostname(struct IPerlSock *I, char* name, int namelen)
{
    return win32_gethostname(name, namelen);
}

struct netent *
PerlSockGetnetbyaddr(struct IPerlSock *I, long net, int type)
{
    return win32_getnetbyaddr(net, type);
}

struct netent *
PerlSockGetnetbyname(struct IPerlSock *I, const char *name)
{
    return win32_getnetbyname((char*)name);
}

struct netent *
PerlSockGetnetent(struct IPerlSock *I)
{
    return win32_getnetent();
}

int PerlSockGetpeername(struct IPerlSock *I, SOCKET s, struct sockaddr* name, int* namelen)
{
    return win32_getpeername(s, name, namelen);
}

struct protoent*
PerlSockGetprotobyname(struct IPerlSock *I, const char* name)
{
    return win32_getprotobyname(name);
}

struct protoent*
PerlSockGetprotobynumber(struct IPerlSock *I, int number)
{
    return win32_getprotobynumber(number);
}

struct protoent*
PerlSockGetprotoent(struct IPerlSock *I)
{
    return win32_getprotoent();
}

struct servent*
PerlSockGetservbyname(struct IPerlSock *I, const char* name, const char* proto)
{
    return win32_getservbyname(name, proto);
}

struct servent*
PerlSockGetservbyport(struct IPerlSock *I, int port, const char* proto)
{
    return win32_getservbyport(port, proto);
}

struct servent*
PerlSockGetservent(struct IPerlSock *I)
{
    return win32_getservent();
}

int
PerlSockGetsockname(struct IPerlSock *I, SOCKET s, struct sockaddr* name, int* namelen)
{
    return win32_getsockname(s, name, namelen);
}

int
PerlSockGetsockopt(struct IPerlSock *I, SOCKET s, int level, int optname, char* optval, int* optlen)
{
    return win32_getsockopt(s, level, optname, optval, optlen);
}

unsigned long
PerlSockInetAddr(struct IPerlSock *I, const char* cp)
{
    return win32_inet_addr(cp);
}

char*
PerlSockInetNtoa(struct IPerlSock *I, struct in_addr in)
{
    return win32_inet_ntoa(in);
}

int
PerlSockListen(struct IPerlSock *I, SOCKET s, int backlog)
{
    return win32_listen(s, backlog);
}

int
PerlSockRecv(struct IPerlSock *I, SOCKET s, char* buffer, int len, int flags)
{
    return win32_recv(s, buffer, len, flags);
}

int
PerlSockRecvfrom(struct IPerlSock *I, SOCKET s, char* buffer, int len, int flags, struct sockaddr* from, int* fromlen)
{
    return win32_recvfrom(s, buffer, len, flags, from, fromlen);
}

int
PerlSockSelect(struct IPerlSock *I, int nfds, char* readfds, char* writefds, char* exceptfds, const struct timeval* timeout)
{
    return win32_select(nfds, (Perl_fd_set*)readfds, (Perl_fd_set*)writefds, (Perl_fd_set*)exceptfds, timeout);
}

int
PerlSockSend(struct IPerlSock *I, SOCKET s, const char* buffer, int len, int flags)
{
    return win32_send(s, buffer, len, flags);
}

int
PerlSockSendto(struct IPerlSock *I, SOCKET s, const char* buffer, int len, int flags, const struct sockaddr* to, int tolen)
{
    return win32_sendto(s, buffer, len, flags, to, tolen);
}

void
PerlSockSethostent(struct IPerlSock *I, int stayopen)
{
    win32_sethostent(stayopen);
}

void
PerlSockSetnetent(struct IPerlSock *I, int stayopen)
{
    win32_setnetent(stayopen);
}

void
PerlSockSetprotoent(struct IPerlSock *I, int stayopen)
{
    win32_setprotoent(stayopen);
}

void
PerlSockSetservent(struct IPerlSock *I, int stayopen)
{
    win32_setservent(stayopen);
}

int
PerlSockSetsockopt(struct IPerlSock *I, SOCKET s, int level, int optname, const char* optval, int optlen)
{
    return win32_setsockopt(s, level, optname, optval, optlen);
}

int
PerlSockShutdown(struct IPerlSock *I, SOCKET s, int how)
{
    return win32_shutdown(s, how);
}

SOCKET
PerlSockSocket(struct IPerlSock *I, int af, int type, int protocol)
{
    return win32_socket(af, type, protocol);
}

int
PerlSockSocketpair(struct IPerlSock *I, int domain, int type, int protocol, int* fds)
{
    dTHXo;
    Perl_croak(aTHX_ "socketpair not implemented!\n");
    return 0;
}

int
PerlSockClosesocket(struct IPerlSock *I, SOCKET s)
{
    return win32_closesocket(s);
}

int
PerlSockIoctlsocket(struct IPerlSock *I, SOCKET s, long cmd, u_long *argp)
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


/* IPerlProc */

#define EXECF_EXEC 1
#define EXECF_SPAWN 2

extern char *		g_getlogin(void);
extern int		do_spawn2(char *cmd, int exectype);
#ifdef PERL_OBJECT
extern int		g_do_aspawn(void *vreally, void **vmark, void **vsp);
#define do_aspawn g_do_aspawn
#endif
EXTERN_C PerlInterpreter* perl_alloc_using(struct IPerlMem* pMem,
			struct IPerlEnv* pEnv, struct IPerlStdIO* pStdIO,
			struct IPerlLIO* pLIO, struct IPerlDir* pDir,
			struct IPerlSock* pSock, struct IPerlProc* pProc);

void
PerlProcAbort(struct IPerlProc *I)
{
    win32_abort();
}

char *
PerlProcCrypt(struct IPerlProc *I, const char* clear, const char* salt)
{
    return win32_crypt(clear, salt);
}

void
PerlProcExit(struct IPerlProc *I, int status)
{
    exit(status);
}

void
PerlProc_Exit(struct IPerlProc *I, int status)
{
    _exit(status);
}

int
PerlProcExecl(struct IPerlProc *I, const char *cmdname, const char *arg0, const char *arg1, const char *arg2, const char *arg3)
{
    return execl(cmdname, arg0, arg1, arg2, arg3);
}

int
PerlProcExecv(struct IPerlProc *I, const char *cmdname, const char *const *argv)
{
    return win32_execvp(cmdname, argv);
}

int
PerlProcExecvp(struct IPerlProc *I, const char *cmdname, const char *const *argv)
{
    return win32_execvp(cmdname, argv);
}

uid_t
PerlProcGetuid(struct IPerlProc *I)
{
    return getuid();
}

uid_t
PerlProcGeteuid(struct IPerlProc *I)
{
    return geteuid();
}

gid_t
PerlProcGetgid(struct IPerlProc *I)
{
    return getgid();
}

gid_t
PerlProcGetegid(struct IPerlProc *I)
{
    return getegid();
}

char *
PerlProcGetlogin(struct IPerlProc *I)
{
    return g_getlogin();
}

int
PerlProcKill(struct IPerlProc *I, int pid, int sig)
{
    return win32_kill(pid, sig);
}

int
PerlProcKillpg(struct IPerlProc *I, int pid, int sig)
{
    dTHXo;
    Perl_croak(aTHX_ "killpg not implemented!\n");
    return 0;
}

int
PerlProcPauseProc(struct IPerlProc *I)
{
    return win32_sleep((32767L << 16) + 32767);
}

PerlIO*
PerlProcPopen(struct IPerlProc *I, const char *command, const char *mode)
{
    PERL_FLUSHALL_FOR_CHILD;
    return (PerlIO*)win32_popen(command, mode);
}

int
PerlProcPclose(struct IPerlProc *I, PerlIO *stream)
{
    return win32_pclose((FILE*)stream);
}

int
PerlProcPipe(struct IPerlProc *I, int *phandles)
{
    return win32_pipe(phandles, 512, O_BINARY);
}

int
PerlProcSetuid(struct IPerlProc *I, uid_t u)
{
    return setuid(u);
}

int
PerlProcSetgid(struct IPerlProc *I, gid_t g)
{
    return setgid(g);
}

int
PerlProcSleep(struct IPerlProc *I, unsigned int s)
{
    return win32_sleep(s);
}

int
PerlProcTimes(struct IPerlProc *I, struct tms *timebuf)
{
    return win32_times(timebuf);
}

int
PerlProcWait(struct IPerlProc *I, int *status)
{
    return win32_wait(status);
}

int
PerlProcWaitpid(struct IPerlProc *I, int pid, int *status, int flags)
{
    return win32_waitpid(pid, status, flags);
}

Sighandler_t
PerlProcSignal(struct IPerlProc *I, int sig, Sighandler_t subcode)
{
    return 0;
}

void*
PerlProcDynaLoader(struct IPerlProc *I, const char* filename)
{
    return win32_dynaload(filename);
}

void
PerlProcGetOSError(struct IPerlProc *I, SV* sv, DWORD dwErr)
{
    win32_str_os_error(sv, dwErr);
}

BOOL
PerlProcDoCmd(struct IPerlProc *I, char *cmd)
{
    do_spawn2(cmd, EXECF_EXEC);
    return FALSE;
}

int
PerlProcSpawn(struct IPerlProc *I, char* cmds)
{
    return do_spawn2(cmds, EXECF_SPAWN);
}

int
PerlProcSpawnvp(struct IPerlProc *I, int mode, const char *cmdname, const char *const *argv)
{
    return win32_spawnvp(mode, cmdname, argv);
}

int
PerlProcASpawn(struct IPerlProc *I, void *vreally, void **vmark, void **vsp)
{
    return do_aspawn(vreally, vmark, vsp);
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

/*#include "perlhost.h" */


EXTERN_C void
perl_get_host_info(struct IPerlMemInfo* perlMemInfo,
		   struct IPerlEnvInfo* perlEnvInfo,
		   struct IPerlStdIOInfo* perlStdIOInfo,
		   struct IPerlLIOInfo* perlLIOInfo,
		   struct IPerlDirInfo* perlDirInfo,
		   struct IPerlSockInfo* perlSockInfo,
		   struct IPerlProcInfo* perlProcInfo)
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

#ifdef PERL_OBJECT

EXTERN_C PerlInterpreter* perl_alloc_using(struct IPerlMem* pMem,
			struct IPerlEnv* pEnv, struct IPerlStdIO* pStdIO,
			struct IPerlLIO* pLIO, struct IPerlDir* pDir,
			struct IPerlSock* pSock, struct IPerlProc* pProc)
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
	retVal = pPerl->perl_parse(xsinit, argc, argv, env);
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

#else /* !PERL_OBJECT */

EXTERN_C PerlInterpreter*
perl_alloc(void)
{
    return perl_alloc_using(&perlMem, &perlEnv, &perlStdIO, &perlLIO,
			   &perlDir, &perlSock, &perlProc);
}

#endif /* PERL_OBJECT */

#endif /* PERL_IMPLICIT_SYS */

extern HANDLE w32_perldll_handle;
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
	w32_perldll_handle = hModule;
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

