/* win32sck.c
 *
 * (c) 1995 Microsoft Corporation. All rights reserved. 
 * 		Developed by hip communications inc., http://info.hip.com/info/
 * Portions (c) 1993 Intergraph Corporation. All rights reserved.
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#define WIN32IO_IS_STDIO
#define WIN32SCK_IS_STDSCK
#define WIN32_LEAN_AND_MEAN
#ifdef __GNUC__
#define Win32_Winsock
#endif
#include <windows.h>
#include "EXTERN.h"
#include "perl.h"

#if defined(PERL_OBJECT)
#define NO_XSLOCKS
#include "XSUB.h"
#endif

#include "Win32iop.h"
#include <sys/socket.h>
#include <fcntl.h>
#include <sys/stat.h>
#ifndef __MINGW32__
#include <assert.h>
#endif
#include <io.h>

/* thanks to Beverly Brown	(beverly@datacube.com) */
#ifdef USE_SOCKETS_AS_HANDLES
#	define OPEN_SOCKET(x)	win32_open_osfhandle(x,O_RDWR|O_BINARY)
#	define TO_SOCKET(x)	_get_osfhandle(x)
#else
#	define OPEN_SOCKET(x)	(x)
#	define TO_SOCKET(x)	(x)
#endif	/* USE_SOCKETS_AS_HANDLES */

#if defined(USE_THREADS) || defined(USE_ITHREADS)
#define StartSockets() \
    STMT_START {					\
	if (!wsock_started)				\
	    start_sockets();				\
       set_socktype();                         \
    } STMT_END
#else
#define StartSockets() \
    STMT_START {					\
	if (!wsock_started) {				\
	    start_sockets();				\
	    set_socktype();				\
	}						\
    } STMT_END
#endif

#define SOCKET_TEST(x, y) \
    STMT_START {					\
	StartSockets();					\
	if((x) == (y))					\
	    errno = CALL(WSAGetLastError)();			\
    } STMT_END

#define SOCKET_TEST_ERROR(x) SOCKET_TEST(x, SOCKET_ERROR)

static struct servent* win32_savecopyservent(struct servent*d,
                                             struct servent*s,
                                             const char *proto);

static int wsock_started = 0;

#ifdef PERL_WIN32_SOCK_DLOAD /* we load the socket libraries when needed -- BKS 5-29-2000 */
#define CALL(x) (*p ## x)
typedef SOCKET (PASCAL *Paccept)(SOCKET,struct sockaddr*,int*);
typedef int (PASCAL *Pbind)(SOCKET,const struct sockaddr*,int);
typedef int (PASCAL *Pclosesocket)(SOCKET);
typedef int (PASCAL *Pconnect)(SOCKET,const struct sockaddr*,int);
typedef int (PASCAL *Pioctlsocket)(SOCKET,long,u_long *);
typedef int (PASCAL *Pgetpeername)(SOCKET,struct sockaddr*,int*);
typedef int (PASCAL *Pgetsockname)(SOCKET,struct sockaddr*,int*);
typedef int (PASCAL *Pgetsockopt)(SOCKET,int,int,char*,int*);
typedef unsigned long (PASCAL *Pinet_addr)(const char*);
typedef char * (PASCAL *Pinet_ntoa)(struct in_addr);
typedef int (PASCAL *Plisten)(SOCKET,int);
typedef int (PASCAL *Precv)(SOCKET,char*,int,int);
typedef int (PASCAL *Precvfrom)(SOCKET,char*,int,int,struct sockaddr*,int*);
typedef int (PASCAL *Psend)(SOCKET,const char*,int,int);
typedef int (PASCAL *Psendto)(SOCKET,const char*,int,int,const struct sockaddr*,int);
typedef int (PASCAL *Psetsockopt)(SOCKET,int,int,const char*,int);
typedef int (PASCAL *Pshutdown)(SOCKET,int);
typedef SOCKET (PASCAL *Psocket)(int,int,int);
typedef struct hostent* (PASCAL *Pgethostbyaddr)(const char*,int,int);
typedef struct hostent* (PASCAL *Pgethostbyname)(const char*);
typedef struct servent* (PASCAL *Pgetservbyport)(int,const char*);
typedef struct servent* (PASCAL *Pgetservbyname)(const char*,const char*);
typedef struct protoent* (PASCAL *Pgetprotobynumber)(int);
typedef struct protoent* (PASCAL *Pgetprotobyname)(const char*);
typedef int (PASCAL *PWSACleanup)(void);
typedef int (PASCAL *PWSAStartup)(unsigned short, WSADATA*);
typedef void (PASCAL *PWSASetLastError)(int);
typedef int (PASCAL *PWSAGetLastError)(void);
typedef int (PASCAL *P__WSAFDIsSet)(SOCKET,fd_set*);
typedef int (PASCAL *Pselect)(int nfds,fd_set*,fd_set*,fd_set*,const struct timeval*);
typedef int (PASCAL *Pgethostname)(char*,int);
typedef u_long (PASCAL *Phtonl)(u_long), (PASCAL *Pntohl)(u_long);
typedef u_short (PASCAL *Phtons)(u_short), (PASCAL *Pntohs)(u_short);
static Paccept 		paccept;
static Pbind 		pbind;
static Pclosesocket 	pclosesocket;
static Pconnect 	pconnect;
static Pioctlsocket	pioctlsocket;
static Pgetpeername	pgetpeername;
static Pgetsockname	pgetsockname;
static Pgetsockopt	pgetsockopt;
static Pinet_addr	pinet_addr;
static Pinet_ntoa	pinet_ntoa;
static Plisten		plisten;
static Precv		precv;
static Precvfrom	precvfrom;
static Psend		psend;
static Psendto		psendto;
static Psetsockopt	psetsockopt;
static Pshutdown	pshutdown;
static Psocket		psocket;
static Pgethostbyaddr	pgethostbyaddr;
static Pgethostbyname	pgethostbyname;
static Pgetservbyport	pgetservbyport;
static Pgetservbyname	pgetservbyname;
static Pgetprotobynumber pgetprotobynumber;
static Pgetprotobyname	pgetprotobyname;
static PWSAStartup	pWSAStartup;
static PWSACleanup	pWSACleanup;
static PWSASetLastError	pWSASetLastError;
static PWSAGetLastError	pWSAGetLastError;
static P__WSAFDIsSet	p__WSAFDIsSet;
static Pselect		pselect;
static Pgethostname	pgethostname;
#if BYTEORDER != 0x1234
static Phtons		phtons;
static Pntohs		pntohs;
static Phtonl		phtonl;
static Pntohl		pntohl;
#endif
void end_sockets(pTHXo_ void *ptr)
{
    CALL(WSACleanup)();
    wsock_started = 0;
    FreeLibrary(ptr);
}
#else
#define CALL(x) x
#endif /* PERL_WIN32_SOCK_DLOAD */
void
start_sockets(void) 
{
    dTHXo;
    unsigned short version;
    WSADATA retdata;
    int ret;
#ifdef PERL_WIN32_SOCK_DLOAD
    HANDLE hDll = LoadLibraryA("wsock32.dll");

    /*
     * initalize the winsock interface and insure that it is
     * cleaned up at exit.
     * Also, only load the DLL when needed -- BKS, 4-2-2000
     */
    if (!(hDll &&
	(paccept = (Paccept)GetProcAddress(hDll, "accept")) &&
	(pbind = (Pbind)GetProcAddress(hDll, "bind")) &&
	(pclosesocket = (Pclosesocket)GetProcAddress(hDll, "closesocket")) &&
	(pconnect = (Pconnect)GetProcAddress(hDll, "connect")) &&
	(pioctlsocket = (Pioctlsocket)GetProcAddress(hDll, "ioctlsocket")) &&
	(pgetpeername = (Pgetpeername)GetProcAddress(hDll, "getpeername")) &&
	(pgetsockname = (Pgetsockname)GetProcAddress(hDll, "getsockname")) &&
	(pgetsockopt = (Pgetsockopt)GetProcAddress(hDll, "getsockopt")) &&
	(pinet_addr = (Pinet_addr)GetProcAddress(hDll, "inet_addr")) &&
	(pinet_ntoa = (Pinet_ntoa)GetProcAddress(hDll, "inet_ntoa")) &&
	(plisten = (Plisten)GetProcAddress(hDll, "listen")) &&
	(precv = (Precv)GetProcAddress(hDll, "recv")) &&
	(precvfrom = (Precvfrom)GetProcAddress(hDll, "recvfrom")) &&
	(psend = (Psend)GetProcAddress(hDll, "send")) &&
	(psendto = (Psendto)GetProcAddress(hDll, "sendto")) &&
	(psetsockopt = (Psetsockopt)GetProcAddress(hDll, "setsockopt")) &&
	(pshutdown = (Pshutdown)GetProcAddress(hDll, "shutdown")) &&
	(psocket = (Psocket)GetProcAddress(hDll, "socket")) &&
	(pgethostbyaddr = (Pgethostbyaddr)GetProcAddress(hDll, "gethostbyaddr")) &&
	(pgethostbyname = (Pgethostbyname)GetProcAddress(hDll, "gethostbyname")) &&
	(pgetservbyport = (Pgetservbyport)GetProcAddress(hDll, "getservbyport")) &&
	(pgetservbyname = (Pgetservbyname)GetProcAddress(hDll, "getservbyname")) &&
	(pgetprotobynumber = (Pgetprotobynumber)GetProcAddress(hDll, "getprotobynumber")) &&
	(pgetprotobyname = (Pgetprotobyname)GetProcAddress(hDll, "getprotobyname")) &&
	(pWSAStartup = (PWSAStartup)GetProcAddress(hDll, "WSAStartup")) &&
	(pWSACleanup = (PWSACleanup)GetProcAddress(hDll, "WSACleanup")) &&
	(pWSASetLastError = (PWSASetLastError)GetProcAddress(hDll, "WSASetLastError")) &&
	(pWSAGetLastError = (PWSAGetLastError)GetProcAddress(hDll, "WSAGetLastError")) &&
	(p__WSAFDIsSet = (P__WSAFDIsSet)GetProcAddress(hDll, "__WSAFDIsSet")) &&
	(pselect = (Pselect)GetProcAddress(hDll, "select")) &&
	(pgethostname = (Pgethostname)GetProcAddress(hDll, "gethostname")) &&
#if BYTEORDER != 0x1234
	(phtonl = (Phtonl)GetProcAddress(hDll, "htonl")) &&
	(pntohl = (Pntohl)GetProcAddress(hDll, "ntohl")) &&
	(phtons = (Pntohs)GetProcAddress(hDll, "htons")) &&
	(pntohs = (Pntohs)GetProcAddress(hDll, "ntohs")
#else
	1
#endif
    )) {
	Perl_croak(aTHX_ "Unable to load winsock library!\n");
    }
#endif /* PERL_WIN32_SOCK_DLOAD */
    version = 0x101;
    if(ret = CALL(WSAStartup)(version, &retdata))
	Perl_croak(aTHX_ "Unable to initialize winsock library!\n");
    if(retdata.wVersion != version)
	Perl_croak(aTHX_ "Could not find version 1.1 of winsock dll\n");

#ifdef PERL_WIN32_SOCK_DLOAD
    call_atexit(end_sockets, hDll);
#endif
    wsock_started = 1;
}

void
set_socktype(void)
{
#ifdef USE_SOCKETS_AS_HANDLES
#ifdef USE_THREADS
    dTHX;
    if (!w32_init_socktype) {
#endif
	int iSockOpt = SO_SYNCHRONOUS_NONALERT;
	/*
	 * Enable the use of sockets as filehandles
	 */
	CALL(setsockopt)(INVALID_SOCKET, SOL_SOCKET, SO_OPENTYPE,
		    (char *)&iSockOpt, sizeof(iSockOpt));
#ifdef USE_THREADS
	w32_init_socktype = 1;
    }
#endif
#endif	/* USE_SOCKETS_AS_HANDLES */
}


#ifndef USE_SOCKETS_AS_HANDLES
#undef fdopen
FILE *
my_fdopen(int fd, char *mode)
{
    FILE *fp;
    char sockbuf[256];
    int optlen = sizeof(sockbuf);
    int retval;

    if (!wsock_started)
	return(fdopen(fd, mode));

    retval = CALL(getsockopt)((SOCKET)fd, SOL_SOCKET, SO_TYPE, sockbuf, &optlen);
    if(retval == SOCKET_ERROR && CALL(WSAGetLastError)() == WSAENOTSOCK) {
	return(fdopen(fd, mode));
    }

    /*
     * If we get here, then fd is actually a socket.
     */
    Newz(1310, fp, 1, FILE);
    if(fp == NULL) {
	errno = ENOMEM;
	return NULL;
    }

    fp->_file = fd;
    if(*mode == 'r')
	fp->_flag = _IOREAD;
    else
	fp->_flag = _IOWRT;
   
    return fp;
}
#endif	/* USE_SOCKETS_AS_HANDLES */

/* ntoh* and hton* are implemented here so that ByteLoader doesn't need to load WinSock;
   these functions are simply copied from util.c */

u_long
win32_htonl(u_long l)
{
#if BYTEORDER == 0x1234
    union { u_long r; char c[4]; } u;
    u.c[0] = (l >> 24) & 255;
    u.c[1] = (l >> 16) & 255;
    u.c[2] = (l >> 8) & 255;
    u.c[3] = l & 255;
    return u.r;
#else
    StartSockets();
    return CALL(htonl)(l);
#endif
}

u_short
win32_htons(u_short s)
{
#if BYTEORDER == 0x1234
    return (((s >> 8) & 255) | ((s & 255) << 8));
#else
    StartSockets();
    return CALL(htons)(s);
#endif
}

u_long
win32_ntohl(u_long l)
{
#if BYTEORDER == 0x1234
    union { u_long r; char c[4]; } u;
    u.c[0] = (l >> 24) & 255;
    u.c[1] = (l >> 16) & 255;
    u.c[2] = (l >> 8) & 255;
    u.c[3] = l & 255;
    return u.r;
#else
    StartSockets();
    return CALL(ntohl)(l);
#endif
}

u_short
win32_ntohs(u_short s)
{
#if BYTEORDER == 0x1234
    return (((s >> 8) & 255) | ((s & 255) << 8));
#else
    StartSockets();
    return CALL(ntohs)(s);
#endif
}



SOCKET
win32_accept(SOCKET s, struct sockaddr *addr, int *addrlen)
{
    SOCKET r;

    SOCKET_TEST((r = CALL(accept)(TO_SOCKET(s), addr, addrlen)), INVALID_SOCKET);
    return OPEN_SOCKET(r);
}

int
win32_bind(SOCKET s, const struct sockaddr *addr, int addrlen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(bind)(TO_SOCKET(s), addr, addrlen));
    return r;
}

int
win32_connect(SOCKET s, const struct sockaddr *addr, int addrlen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(connect)(TO_SOCKET(s), addr, addrlen));
    return r;
}


int
win32_getpeername(SOCKET s, struct sockaddr *addr, int *addrlen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(getpeername)(TO_SOCKET(s), addr, addrlen));
    return r;
}

int
win32_getsockname(SOCKET s, struct sockaddr *addr, int *addrlen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(getsockname)(TO_SOCKET(s), addr, addrlen));
    return r;
}

int
win32_getsockopt(SOCKET s, int level, int optname, char *optval, int *optlen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(getsockopt)(TO_SOCKET(s), level, optname, optval, optlen));
    return r;
}

int
win32_ioctlsocket(SOCKET s, long cmd, u_long *argp)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(ioctlsocket)(TO_SOCKET(s), cmd, argp));
    return r;
}

int
win32_listen(SOCKET s, int backlog)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(listen)(TO_SOCKET(s), backlog));
    return r;
}

int
win32_recv(SOCKET s, char *buf, int len, int flags)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(recv)(TO_SOCKET(s), buf, len, flags));
    return r;
}

int
win32_recvfrom(SOCKET s, char *buf, int len, int flags, struct sockaddr *from, int *fromlen)
{
    int r;
    int frombufsize = *fromlen;

    SOCKET_TEST_ERROR(r = CALL(recvfrom)(TO_SOCKET(s), buf, len, flags, from, fromlen));
    /* Winsock's recvfrom() only returns a valid 'from' when the socket
     * is connectionless.  Perl expects a valid 'from' for all types
     * of sockets, so go the extra mile.
     */
    if (r != SOCKET_ERROR && frombufsize == *fromlen)
	(void)win32_getpeername(s, from, fromlen);
    return r;
}

/* select contributed by Vincent R. Slyngstad (vrs@ibeam.intel.com) */
int
win32_select(int nfds, Perl_fd_set* rd, Perl_fd_set* wr, Perl_fd_set* ex, const struct timeval* timeout)
{
    int r;
#ifdef USE_SOCKETS_AS_HANDLES
    Perl_fd_set dummy;
    int i, fd, bit, offset;
    FD_SET nrd, nwr, nex, *prd, *pwr, *pex;

    /* winsock seems incapable of dealing with all three null fd_sets,
     * so do the (millisecond) sleep as a special case
     */
    if (!(rd || wr || ex)) {
	if (timeout)
	    Sleep(timeout->tv_sec  * 1000 +
		  timeout->tv_usec / 1000);	/* do the best we can */
	else
	    Sleep(UINT_MAX);
	return 0;
    }
    StartSockets();
    PERL_FD_ZERO(&dummy);
    if (!rd)
	rd = &dummy, prd = NULL;
    else
	prd = &nrd;
    if (!wr)
	wr = &dummy, pwr = NULL;
    else
	pwr = &nwr;
    if (!ex)
	ex = &dummy, pex = NULL;
    else
	pex = &nex;

    FD_ZERO(&nrd);
    FD_ZERO(&nwr);
    FD_ZERO(&nex);
    for (i = 0; i < nfds; i++) {
	fd = TO_SOCKET(i);
	if (PERL_FD_ISSET(i,rd))
	    FD_SET(fd, &nrd);
	if (PERL_FD_ISSET(i,wr))
	    FD_SET(fd, &nwr);
	if (PERL_FD_ISSET(i,ex))
	    FD_SET(fd, &nex);
    }

    SOCKET_TEST_ERROR(r = CALL(select)(nfds, prd, pwr, pex, timeout));

    for (i = 0; i < nfds; i++) {
	fd = TO_SOCKET(i);
	if (PERL_FD_ISSET(i,rd) && !CALL(__WSAFDIsSet)(fd, &nrd))
	    PERL_FD_CLR(i,rd);
	if (PERL_FD_ISSET(i,wr) && !CALL(__WSAFDIsSet)(fd, &nwr))
	    PERL_FD_CLR(i,wr);
	if (PERL_FD_ISSET(i,ex) && !CALL(__WSAFDIsSet)(fd, &nex))
	    PERL_FD_CLR(i,ex);
    }
#else
    SOCKET_TEST_ERROR(r = CALL(select)(nfds, rd, wr, ex, timeout));
#endif
    return r;
}

int
win32_send(SOCKET s, const char *buf, int len, int flags)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(send)(TO_SOCKET(s), buf, len, flags));
    return r;
}

int
win32_sendto(SOCKET s, const char *buf, int len, int flags,
	     const struct sockaddr *to, int tolen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(sendto)(TO_SOCKET(s), buf, len, flags, to, tolen));
    return r;
}

int
win32_setsockopt(SOCKET s, int level, int optname, const char *optval, int optlen)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(setsockopt)(TO_SOCKET(s), level, optname, optval, optlen));
    return r;
}
    
int
win32_shutdown(SOCKET s, int how)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(shutdown)(TO_SOCKET(s), how));
    return r;
}

int
win32_closesocket(SOCKET s)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(closesocket)(TO_SOCKET(s)));
    return r;
}

SOCKET
win32_socket(int af, int type, int protocol)
{
    SOCKET s;

#ifndef USE_SOCKETS_AS_HANDLES
    SOCKET_TEST(s = CALL(socket)(af, type, protocol), INVALID_SOCKET);
#else
    StartSockets();
    if((s = CALL(socket)(af, type, protocol)) == INVALID_SOCKET)
	errno = CALL(WSAGetLastError)();
    else
	s = OPEN_SOCKET(s);
#endif	/* USE_SOCKETS_AS_HANDLES */

    return s;
}

#undef fclose
int
my_fclose (FILE *pf)
{
    int osf, retval;
    if (!wsock_started)		/* No WinSock? */
	return(fclose(pf));	/* Then not a socket. */
    osf = TO_SOCKET(fileno(pf));/* Get it now before it's gone! */
    retval = fclose(pf);	/* Must fclose() before closesocket() */
    if (osf != -1
	&& CALL(closesocket)(osf) == SOCKET_ERROR
	&& CALL(WSAGetLastError)() != WSAENOTSOCK)
    {
	return EOF;
    }
    return retval;
}

struct hostent *
win32_gethostbyaddr(const char *addr, int len, int type)
{
    struct hostent *r;

    SOCKET_TEST(r = CALL(gethostbyaddr)(addr, len, type), NULL);
    return r;
}

struct hostent *
win32_gethostbyname(const char *name)
{
    struct hostent *r;

    SOCKET_TEST(r = CALL(gethostbyname)(name), NULL);
    return r;
}

int
win32_gethostname(char *name, int len)
{
    int r;

    SOCKET_TEST_ERROR(r = CALL(gethostname)(name, len));
    return r;
}

struct protoent *
win32_getprotobyname(const char *name)
{
    struct protoent *r;

    SOCKET_TEST(r = CALL(getprotobyname)(name), NULL);
    return r;
}

struct protoent *
win32_getprotobynumber(int num)
{
    struct protoent *r;

    SOCKET_TEST(r = CALL(getprotobynumber)(num), NULL);
    return r;
}

struct servent *
win32_getservbyname(const char *name, const char *proto)
{
    dTHXo;    
    struct servent *r;

    SOCKET_TEST(r = CALL(getservbyname)(name, proto), NULL);
    if (r) {
	r = win32_savecopyservent(&w32_servent, r, proto);
    }
    return r;
}

struct servent *
win32_getservbyport(int port, const char *proto)
{
    dTHXo; 
    struct servent *r;

    SOCKET_TEST(r = CALL(getservbyport)(port, proto), NULL);
    if (r) {
	r = win32_savecopyservent(&w32_servent, r, proto);
    }
    return r;
}

int
win32_ioctl(int i, unsigned int u, char *data)
{
    dTHXo;
    u_long argp = (u_long)data;
    int retval;

    if (!wsock_started) {
	Perl_croak_nocontext("ioctl implemented only on sockets");
	/* NOTREACHED */
    }

    retval = CALL(ioctlsocket)(TO_SOCKET(i), (long)u, &argp);
    if (retval == SOCKET_ERROR) {
	if (CALL(WSAGetLastError)() == WSAENOTSOCK) {
	    Perl_croak_nocontext("ioctl implemented only on sockets");
	    /* NOTREACHED */
	}
	errno = CALL(WSAGetLastError)();
    }
    return retval;
}

char FAR *
win32_inet_ntoa(struct in_addr in)
{
    StartSockets();
    return CALL(inet_ntoa)(in);
}

unsigned long
win32_inet_addr(const char FAR *cp)
{
    StartSockets();
    return CALL(inet_addr)(cp);
}

/*
 * Networking stubs
 */

void
win32_endhostent() 
{
    dTHXo;
    Perl_croak_nocontext("endhostent not implemented!\n");
}

void
win32_endnetent()
{
    dTHXo;
    Perl_croak_nocontext("endnetent not implemented!\n");
}

void
win32_endprotoent()
{
    dTHXo;
    Perl_croak_nocontext("endprotoent not implemented!\n");
}

void
win32_endservent()
{
    dTHXo;
    Perl_croak_nocontext("endservent not implemented!\n");
}


struct netent *
win32_getnetent(void) 
{
    dTHXo;
    Perl_croak_nocontext("getnetent not implemented!\n");
    return (struct netent *) NULL;
}

struct netent *
win32_getnetbyname(char *name) 
{
    dTHXo;
    Perl_croak_nocontext("getnetbyname not implemented!\n");
    return (struct netent *)NULL;
}

struct netent *
win32_getnetbyaddr(long net, int type) 
{
    dTHXo;
    Perl_croak_nocontext("getnetbyaddr not implemented!\n");
    return (struct netent *)NULL;
}

struct protoent *
win32_getprotoent(void) 
{
    dTHXo;
    Perl_croak_nocontext("getprotoent not implemented!\n");
    return (struct protoent *) NULL;
}

struct servent *
win32_getservent(void) 
{
    dTHXo;
    Perl_croak_nocontext("getservent not implemented!\n");
    return (struct servent *) NULL;
}

void
win32_sethostent(int stayopen)
{
    dTHXo;
    Perl_croak_nocontext("sethostent not implemented!\n");
}


void
win32_setnetent(int stayopen)
{
    dTHXo;
    Perl_croak_nocontext("setnetent not implemented!\n");
}


void
win32_setprotoent(int stayopen)
{
    dTHXo;
    Perl_croak_nocontext("setprotoent not implemented!\n");
}


void
win32_setservent(int stayopen)
{
    dTHXo;
    Perl_croak_nocontext("setservent not implemented!\n");
}

static struct servent*
win32_savecopyservent(struct servent*d, struct servent*s, const char *proto)
{
    d->s_name = s->s_name;
    d->s_aliases = s->s_aliases;
    d->s_port = s->s_port;
#ifndef __BORLANDC__	/* Buggy on Win95 and WinNT-with-Borland-WSOCK */
    if (!IsWin95() && s->s_proto && strlen(s->s_proto))
	d->s_proto = s->s_proto;
    else
#endif
    if (proto && strlen(proto))
	d->s_proto = (char *)proto;
    else
	d->s_proto = "tcp";
   
    return d;
}


