/*

	ipsock.c
	Interface for perl socket functions

*/

#include <ipsock.h>
#include <fcntl.h>

#define USE_SOCKETS_AS_HANDLES

class CPerlSock : public IPerlSock
{
public:
	CPerlSock();
	~CPerlSock();
	virtual u_long Htonl(u_long hostlong);
	virtual u_short Htons(u_short hostshort);
	virtual u_long Ntohl(u_long netlong);
	virtual u_short Ntohs(u_short netshort);
	virtual SOCKET Accept(SOCKET s, struct sockaddr* addr, int* addrlen, int &err);
	virtual int Bind(SOCKET s, const struct sockaddr* name, int namelen, int &err);
	virtual int Connect(SOCKET s, const struct sockaddr* name, int namelen, int &err);
	virtual void Endhostent(int &err);
	virtual void Endnetent(int &err);
	virtual void Endprotoent(int &err);
	virtual void Endservent(int &err);
	virtual struct hostent* Gethostbyaddr(const char* addr, int len, int type, int &err);
	virtual struct hostent* Gethostbyname(const char* name, int &err);
	virtual struct hostent* Gethostent(int &err);
	virtual int Gethostname(char* name, int namelen, int &err);
	virtual struct netent *Getnetbyaddr(long net, int type, int &err);
	virtual struct netent *Getnetbyname(const char *, int &err);
	virtual struct netent *Getnetent(int &err);
 	virtual int Getpeername(SOCKET s, struct sockaddr* name, int* namelen, int &err);
	virtual struct protoent* Getprotobyname(const char* name, int &err);
	virtual struct protoent* Getprotobynumber(int number, int &err);
	virtual struct protoent* Getprotoent(int &err);
	virtual struct servent* Getservbyname(const char* name, const char* proto, int &err);
	virtual struct servent* Getservbyport(int port, const char* proto, int &err);
	virtual struct servent* Getservent(int &err);
	virtual int Getsockname(SOCKET s, struct sockaddr* name, int* namelen, int &err);
	virtual int Getsockopt(SOCKET s, int level, int optname, char* optval, int* optlen, int &err);
	virtual unsigned long InetAddr(const char* cp, int &err);
	virtual char* InetNtoa(struct in_addr in, int &err);
	virtual int IoctlSocket(SOCKET s, long cmd, u_long *argp, int& err);
	virtual int Listen(SOCKET s, int backlog, int &err);
	virtual int Recvfrom(SOCKET s, char* buffer, int len, int flags, struct sockaddr* from, int* fromlen, int &err);
	virtual int Select(int nfds, char* readfds, char* writefds, char* exceptfds, const struct timeval* timeout, int &err);
	virtual int Send(SOCKET s, const char* buffer, int len, int flags, int &err); 
	virtual int Sendto(SOCKET s, const char* buffer, int len, int flags, const struct sockaddr* to, int tolen, int &err);
	virtual void Sethostent(int stayopen, int &err);
	virtual void Setnetent(int stayopen, int &err);
	virtual void Setprotoent(int stayopen, int &err);
	virtual void Setservent(int stayopen, int &err);
	virtual int Setsockopt(SOCKET s, int level, int optname, const char* optval, int optlen, int &err);
	virtual int Shutdown(SOCKET s, int how, int &err);
	virtual SOCKET Socket(int af, int type, int protocol, int &err);
	virtual int Socketpair(int domain, int type, int protocol, int* fds, int &err);

	void CloseSocket(int fh, int& err);
	void* GetAddress(HINSTANCE hInstance, char *lpFunctionName);
	void LoadWinSock(void);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
	inline void SetStdObj(IPerlStdIOWin *p) { pStdIO = p; };
protected:
	void Start(void);

	inline int OpenOSfhandle(long osfhandle)
	{
		return pStdIO->OpenOSfhandle(osfhandle, O_RDWR|O_BINARY);
	};
	int GetOSfhandle(int filenum)
	{
		return pStdIO->GetOSfhandle(filenum);
	};

	inline void StartSockets(void)
	{
		if(!bStarted)
			Start();
	};

	BOOL bStarted;
	CPerlObj *pPerl;
	IPerlStdIOWin *pStdIO;
};


#define SOCKETAPI PASCAL 

typedef SOCKET (SOCKETAPI *LPSOCKACCEPT)(SOCKET, struct sockaddr *, int *);
typedef int (SOCKETAPI *LPSOCKBIND)(SOCKET, const struct sockaddr *, int);
typedef int (SOCKETAPI *LPSOCKCLOSESOCKET)(SOCKET);
typedef int (SOCKETAPI *LPSOCKCONNECT)(SOCKET, const struct sockaddr *, int);
typedef unsigned long (SOCKETAPI *LPINETADDR)(const char *);
typedef char* (SOCKETAPI *LPINETNTOA)(struct in_addr);
typedef int (SOCKETAPI *LPSOCKIOCTLSOCKET)(SOCKET, long, u_long *);
typedef int (SOCKETAPI *LPSOCKGETPEERNAME)(SOCKET, struct sockaddr *, int *);
typedef int (SOCKETAPI *LPSOCKGETSOCKNAME)(SOCKET, struct sockaddr *, int *);
typedef int (SOCKETAPI *LPSOCKGETSOCKOPT)(SOCKET, int, int, char *, int *);
typedef u_long (SOCKETAPI *LPSOCKHTONL)(u_long);
typedef u_short (SOCKETAPI *LPSOCKHTONS)(u_short);
typedef int (SOCKETAPI *LPSOCKLISTEN)(SOCKET, int);
typedef u_long (SOCKETAPI *LPSOCKNTOHL)(u_long);
typedef u_short (SOCKETAPI *LPSOCKNTOHS)(u_short);
typedef int (SOCKETAPI *LPSOCKRECV)(SOCKET, char *, int, int);
typedef int (SOCKETAPI *LPSOCKRECVFROM)(SOCKET, char *, int, int, struct sockaddr *, int *);
typedef int (SOCKETAPI *LPSOCKSELECT)(int, fd_set *, fd_set *, fd_set *, const struct timeval *);
typedef int (SOCKETAPI *LPSOCKSEND)(SOCKET, const char *, int, int);
typedef int (SOCKETAPI *LPSOCKSENDTO)(SOCKET, const char *, int, int, const struct sockaddr *, int);
typedef int (SOCKETAPI *LPSOCKSETSOCKOPT)(SOCKET, int, int, const char *, int);
typedef int (SOCKETAPI *LPSOCKSHUTDOWN)(SOCKET, int);
typedef SOCKET (SOCKETAPI *LPSOCKSOCKET)(int, int, int);

/* Database function prototypes */
typedef struct hostent *(SOCKETAPI *LPSOCKGETHOSTBYADDR)(const char *, int, int);
typedef struct hostent *(SOCKETAPI *LPSOCKGETHOSTBYNAME)(const char *);
typedef int (SOCKETAPI *LPSOCKGETHOSTNAME)(char *, int);
typedef struct servent *(SOCKETAPI *LPSOCKGETSERVBYPORT)(int, const char *);
typedef struct servent *(SOCKETAPI *LPSOCKGETSERVBYNAME)(const char *, const char *);
typedef struct protoent *(SOCKETAPI *LPSOCKGETPROTOBYNUMBER)(int);
typedef struct protoent *(SOCKETAPI *LPSOCKGETPROTOBYNAME)(const char *);

/* Microsoft Windows Extension function prototypes */
typedef int (SOCKETAPI *LPSOCKWSASTARTUP)(unsigned short, LPWSADATA);
typedef int (SOCKETAPI *LPSOCKWSACLEANUP)(void);
typedef int (SOCKETAPI *LPSOCKWSAGETLASTERROR)(void);
typedef int (SOCKETAPI *LPWSAFDIsSet)(SOCKET, fd_set *);

static HINSTANCE hWinSockDll = 0;

static LPSOCKACCEPT paccept = 0;
static LPSOCKBIND pbind = 0;
static LPSOCKCLOSESOCKET pclosesocket = 0;
static LPSOCKCONNECT pconnect = 0;
static LPINETADDR pinet_addr = 0;
static LPINETNTOA pinet_ntoa = 0;
static LPSOCKIOCTLSOCKET pioctlsocket = 0;
static LPSOCKGETPEERNAME pgetpeername = 0;
static LPSOCKGETSOCKNAME pgetsockname = 0;
static LPSOCKGETSOCKOPT pgetsockopt = 0;
static LPSOCKHTONL phtonl = 0;
static LPSOCKHTONS phtons = 0;
static LPSOCKLISTEN plisten = 0;
static LPSOCKNTOHL pntohl = 0;
static LPSOCKNTOHS pntohs = 0;
static LPSOCKRECV precv = 0;
static LPSOCKRECVFROM precvfrom = 0;
static LPSOCKSELECT pselect = 0;
static LPSOCKSEND psend = 0;
static LPSOCKSENDTO psendto = 0;
static LPSOCKSETSOCKOPT psetsockopt = 0;
static LPSOCKSHUTDOWN pshutdown = 0;
static LPSOCKSOCKET psocket = 0;
static LPSOCKGETHOSTBYADDR pgethostbyaddr = 0;
static LPSOCKGETHOSTBYNAME pgethostbyname = 0;
static LPSOCKGETHOSTNAME pgethostname = 0;
static LPSOCKGETSERVBYPORT pgetservbyport = 0;
static LPSOCKGETSERVBYNAME pgetservbyname = 0;
static LPSOCKGETPROTOBYNUMBER pgetprotobynumber = 0;
static LPSOCKGETPROTOBYNAME pgetprotobyname = 0;
static LPSOCKWSASTARTUP pWSAStartup = 0;
static LPSOCKWSACLEANUP pWSACleanup = 0;
static LPSOCKWSAGETLASTERROR pWSAGetLastError = 0;
static LPWSAFDIsSet pWSAFDIsSet = 0;

void* CPerlSock::GetAddress(HINSTANCE hInstance, char *lpFunctionName)
{
	char buffer[512];
	FARPROC proc = GetProcAddress(hInstance, lpFunctionName);
	if(proc == 0)
	{
		sprintf(buffer, "Unable to get address of %s in WSock32.dll", lpFunctionName);
		croak(buffer);
	}
	return proc;
}

void CPerlSock::LoadWinSock(void)
{
	if(hWinSockDll == NULL)
	{
		HINSTANCE hLib = LoadLibrary("WSock32.DLL");
		if(hLib == NULL)
			croak("Could not load WSock32.dll\n");

		paccept = (LPSOCKACCEPT)GetAddress(hLib, "accept");
		pbind = (LPSOCKBIND)GetAddress(hLib, "bind");
		pclosesocket = (LPSOCKCLOSESOCKET)GetAddress(hLib, "closesocket");
		pconnect = (LPSOCKCONNECT)GetAddress(hLib, "connect");
		pinet_addr = (LPINETADDR)GetAddress(hLib, "inet_addr");
		pinet_ntoa = (LPINETNTOA)GetAddress(hLib, "inet_ntoa");
		pioctlsocket = (LPSOCKIOCTLSOCKET)GetAddress(hLib, "ioctlsocket");
		pgetpeername = (LPSOCKGETPEERNAME)GetAddress(hLib, "getpeername");
		pgetsockname = (LPSOCKGETSOCKNAME)GetAddress(hLib, "getsockname");
		pgetsockopt = (LPSOCKGETSOCKOPT)GetAddress(hLib, "getsockopt");
		phtonl = (LPSOCKHTONL)GetAddress(hLib, "htonl");
		phtons = (LPSOCKHTONS)GetAddress(hLib, "htons");
		plisten = (LPSOCKLISTEN)GetAddress(hLib, "listen");
		pntohl = (LPSOCKNTOHL)GetAddress(hLib, "ntohl");
		pntohs = (LPSOCKNTOHS)GetAddress(hLib, "ntohs");
		precv = (LPSOCKRECV)GetAddress(hLib, "recv");
		precvfrom = (LPSOCKRECVFROM)GetAddress(hLib, "recvfrom");
		pselect = (LPSOCKSELECT)GetAddress(hLib, "select");
		psend = (LPSOCKSEND)GetAddress(hLib, "send");
		psendto = (LPSOCKSENDTO)GetAddress(hLib, "sendto");
		psetsockopt = (LPSOCKSETSOCKOPT)GetAddress(hLib, "setsockopt");
		pshutdown = (LPSOCKSHUTDOWN)GetAddress(hLib, "shutdown");
		psocket = (LPSOCKSOCKET)GetAddress(hLib, "socket");
		pgethostbyaddr = (LPSOCKGETHOSTBYADDR)GetAddress(hLib, "gethostbyaddr");
		pgethostbyname = (LPSOCKGETHOSTBYNAME)GetAddress(hLib, "gethostbyname");
		pgethostname = (LPSOCKGETHOSTNAME)GetAddress(hLib, "gethostname");
		pgetservbyport = (LPSOCKGETSERVBYPORT)GetAddress(hLib, "getservbyport");
		pgetservbyname = (LPSOCKGETSERVBYNAME)GetAddress(hLib, "getservbyname");
		pgetprotobynumber = (LPSOCKGETPROTOBYNUMBER)GetAddress(hLib, "getprotobynumber");
		pgetprotobyname = (LPSOCKGETPROTOBYNAME)GetAddress(hLib, "getprotobyname");
		pWSAStartup = (LPSOCKWSASTARTUP)GetAddress(hLib, "WSAStartup");
		pWSACleanup = (LPSOCKWSACLEANUP)GetAddress(hLib, "WSACleanup");
		pWSAGetLastError = (LPSOCKWSAGETLASTERROR)GetAddress(hLib, "WSAGetLastError");
		pWSAFDIsSet = (LPWSAFDIsSet)GetAddress(hLib, "__WSAFDIsSet");
		hWinSockDll = hLib;
	}
}


CPerlSock::CPerlSock()
{
	bStarted = FALSE;
	pPerl = NULL;
	pStdIO = NULL;
}

CPerlSock::~CPerlSock()
{
	if(bStarted)
		pWSACleanup();
}

void
CPerlSock::Start(void) 
{
    unsigned short version;
    WSADATA retdata;
    int ret;
    int iSockOpt = SO_SYNCHRONOUS_NONALERT;

	LoadWinSock();
    /*
     * initalize the winsock interface and insure that it is
     * cleaned up at exit.
     */
    version = 0x101;
    if(ret = pWSAStartup(version, &retdata))
	croak("Unable to locate winsock library!\n");
    if(retdata.wVersion != version)
	croak("Could not find version 1.1 of winsock dll\n");

    /* atexit((void (*)(void)) EndSockets); */

#ifdef USE_SOCKETS_AS_HANDLES
    /*
     * Enable the use of sockets as filehandles
     */
    psetsockopt(INVALID_SOCKET, SOL_SOCKET, SO_OPENTYPE,
		(char *)&iSockOpt, sizeof(iSockOpt));
#endif	/* USE_SOCKETS_AS_HANDLES */
    bStarted = TRUE;
}


u_long 
CPerlSock::Htonl(u_long hostlong)
{
	StartSockets();
	return phtonl(hostlong);
}

u_short 
CPerlSock::Htons(u_short hostshort)
{
	StartSockets();
	return phtons(hostshort);
}

u_long 
CPerlSock::Ntohl(u_long netlong)
{
	StartSockets();
	return pntohl(netlong);
}

u_short 
CPerlSock::Ntohs(u_short netshort)
{
	StartSockets();
	return pntohs(netshort);
}


/* thanks to Beverly Brown	(beverly@datacube.com) */
#ifdef USE_SOCKETS_AS_HANDLES
#	define OPEN_SOCKET(x)	OpenOSfhandle(x)
#	define TO_SOCKET(x)	GetOSfhandle(x)
#else
#	define OPEN_SOCKET(x)	(x)
#	define TO_SOCKET(x)	(x)
#endif	/* USE_SOCKETS_AS_HANDLES */

#define SOCKET_TEST(x, y) \
	STMT_START {					\
	StartSockets();					\
	if((x) == (y))					\
		err = pWSAGetLastError();	\
	} STMT_END

#define SOCKET_TEST_ERROR(x) SOCKET_TEST(x, SOCKET_ERROR)

SOCKET 
CPerlSock::Accept(SOCKET s, struct sockaddr* addr, int* addrlen, int &err)
{
	SOCKET r;

	SOCKET_TEST((r = paccept(TO_SOCKET(s), addr, addrlen)), INVALID_SOCKET);
	return OPEN_SOCKET(r);
}

int
CPerlSock::Bind(SOCKET s, const struct sockaddr* addr, int addrlen, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = pbind(TO_SOCKET(s), addr, addrlen));
	return r;
}

void
CPerlSock::CloseSocket(int fh, int& err)
{
	SOCKET_TEST_ERROR(pclosesocket(TO_SOCKET(fh)));
}

int 
CPerlSock::Connect(SOCKET s, const struct sockaddr* addr, int addrlen, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = pconnect(TO_SOCKET(s), addr, addrlen));
	return r;
}

void CPerlSock::Endhostent(int &err)
{
	croak("endhostent not implemented!\n");
}

void CPerlSock::Endnetent(int &err)
{
	croak("endnetent not implemented!\n");
}

void CPerlSock::Endprotoent(int &err)
{
	croak("endprotoent not implemented!\n");
}

void CPerlSock::Endservent(int &err)
{
	croak("endservent not implemented!\n");
}

struct hostent* 
CPerlSock::Gethostbyaddr(const char* addr, int len, int type, int &err)
{
    struct hostent *r;

    SOCKET_TEST(r = pgethostbyaddr(addr, len, type), NULL);
    return r;
}

struct hostent* 
CPerlSock::Gethostbyname(const char* name, int &err)
{
    struct hostent *r;

    SOCKET_TEST(r = pgethostbyname(name), NULL);
    return r;
}

struct hostent* CPerlSock::Gethostent(int &err)
{
	croak("gethostent not implemented!\n");
	return NULL;
}

int 
CPerlSock::Gethostname(char* name, int len, int &err)
{
    int r;

    SOCKET_TEST_ERROR(r = pgethostname(name, len));
    return r;
}

struct netent *CPerlSock::Getnetbyaddr(long net, int type, int &err)
{
	croak("getnetbyaddr not implemented!\n");
	return NULL;
}

struct netent *CPerlSock::Getnetbyname(const char *, int &err)
{
	croak("getnetbyname not implemented!\n");
	return NULL;
}

struct netent *CPerlSock::Getnetent(int &err)
{
	croak("getnetent not implemented!\n");
	return NULL;
}

int 
CPerlSock::Getpeername(SOCKET s, struct sockaddr* addr, int* addrlen, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = pgetpeername(TO_SOCKET(s), addr, addrlen));
	return r;
}

struct protoent* 
CPerlSock::Getprotobyname(const char* name, int &err)
{
    struct protoent *r;

    SOCKET_TEST(r = pgetprotobyname(name), NULL);
    return r;
}

struct protoent* 
CPerlSock::Getprotobynumber(int number, int &err)
{
    struct protoent *r;

    SOCKET_TEST(r = pgetprotobynumber(number), NULL);
    return r;
}

struct protoent* CPerlSock::Getprotoent(int &err)
{
	croak("getprotoent not implemented!\n");
	return NULL;
}

struct servent* 
CPerlSock::Getservbyname(const char* name, const char* proto, int &err)
{
    struct servent *r;
    dTHR;    

    SOCKET_TEST(r = pgetservbyname(name, proto), NULL);
//    if (r) {
//	r = win32_savecopyservent(&myservent, r, proto);
//    }
    return r;
}

struct servent* 
CPerlSock::Getservbyport(int port, const char* proto, int &err)
{
    struct servent *r;
    dTHR; 

    SOCKET_TEST(r = pgetservbyport(port, proto), NULL);
//    if (r) {
//	r = win32_savecopyservent(&myservent, r, proto);
//    }
    return r;
}

struct servent* CPerlSock::Getservent(int &err)
{
	croak("getservent not implemented!\n");
	return NULL;
}

int 
CPerlSock::Getsockname(SOCKET s, struct sockaddr* addr, int* addrlen, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = pgetsockname(TO_SOCKET(s), addr, addrlen));
	return r;
}

int 
CPerlSock::Getsockopt(SOCKET s, int level, int optname, char* optval, int* optlen, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = pgetsockopt(TO_SOCKET(s), level, optname, optval, optlen));
	return r;
}

unsigned long
CPerlSock::InetAddr(const char* cp, int &err)
{
	unsigned long r;

	SOCKET_TEST(r = pinet_addr(cp), INADDR_NONE);
	return r;
}

char*
CPerlSock::InetNtoa(struct in_addr in, int &err)
{
	char* r;

	SOCKET_TEST(r = pinet_ntoa(in), NULL);
	return r;
}

int
CPerlSock::IoctlSocket(SOCKET s, long cmd, u_long *argp, int& err)
{
    int r;

    SOCKET_TEST_ERROR(r = pioctlsocket(TO_SOCKET(s), cmd, argp));
    return r;
}

int 
CPerlSock::Listen(SOCKET s, int backlog, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = plisten(TO_SOCKET(s), backlog));
	return r;
}

int 
CPerlSock::Recvfrom(SOCKET s, char* buffer, int len, int flags, struct sockaddr* from, int* fromlen, int &err)
{
	int r;

	SOCKET_TEST_ERROR(r = precvfrom(TO_SOCKET(s), buffer, len, flags, from, fromlen));
	return r;
}

int 
CPerlSock::Select(int nfds, char* rd, char* wr, char* ex, const struct timeval* timeout, int &err)
{
	long r;
	int i, fd, bit, offset;
	FD_SET nrd, nwr, nex;

	FD_ZERO(&nrd);
	FD_ZERO(&nwr);
	FD_ZERO(&nex);
	for (i = 0; i < nfds; i++)
	{
		fd = TO_SOCKET(i);
		bit = 1L<<(i % (sizeof(char)*8));
		offset = i / (sizeof(char)*8);
		if(rd != NULL && (rd[offset] & bit))
			FD_SET(fd, &nrd);
		if(wr != NULL && (wr[offset] & bit))
			FD_SET(fd, &nwr);
		if(ex != NULL && (ex[offset] & bit))
			FD_SET(fd, &nex);
	}
	SOCKET_TEST_ERROR(r = pselect(nfds, &nrd, &nwr, &nex, timeout));

	for(i = 0; i < nfds; i++)
	{
		fd = TO_SOCKET(i);
		bit = 1L<<(i % (sizeof(char)*8));
		offset = i / (sizeof(char)*8);
		if(rd != NULL && (rd[offset] & bit))
		{
			if(!pWSAFDIsSet(fd, &nrd))
				rd[offset] &= ~bit;
		}
		if(wr != NULL && (wr[offset] & bit))
		{
			if(!pWSAFDIsSet(fd, &nwr))
				wr[offset] &= ~bit;
		}
		if(ex != NULL && (ex[offset] & bit))
		{
			if(!pWSAFDIsSet(fd, &nex))
				ex[offset] &= ~bit;
		}
	}
	return r;
}

int 
CPerlSock::Send(SOCKET s, const char* buffer, int len, int flags, int &err)
{
    int r;

    SOCKET_TEST_ERROR(r = psend(TO_SOCKET(s), buffer, len, flags));
    return r;
}

int 
CPerlSock::Sendto(SOCKET s, const char* buffer, int len, int flags, const struct sockaddr* to, int tolen, int &err)
{
    int r;

    SOCKET_TEST_ERROR(r = psendto(TO_SOCKET(s), buffer, len, flags, to, tolen));
    return r;
}

void CPerlSock::Sethostent(int stayopen, int &err)
{
	croak("sethostent not implemented!\n");
}

void CPerlSock::Setnetent(int stayopen, int &err)
{
	croak("setnetent not implemented!\n");
}

void CPerlSock::Setprotoent(int stayopen, int &err)
{
	croak("setprotoent not implemented!\n");
}

void CPerlSock::Setservent(int stayopen, int &err)
{
	croak("setservent not implemented!\n");
}

int 
CPerlSock::Setsockopt(SOCKET s, int level, int optname, const char* optval, int optlen, int &err)
{
    int r;

    SOCKET_TEST_ERROR(r = psetsockopt(TO_SOCKET(s), level, optname, optval, optlen));
    return r;
}

int 
CPerlSock::Shutdown(SOCKET s, int how, int &err)
{
    int r;

    SOCKET_TEST_ERROR(r = pshutdown(TO_SOCKET(s), how));
    return r;
}

SOCKET 
CPerlSock::Socket(int af, int type, int protocol, int &err)
{
    SOCKET s;

#ifdef USE_SOCKETS_AS_HANDLES
    StartSockets();
    if((s = psocket(af, type, protocol)) == INVALID_SOCKET)
	err = pWSAGetLastError();
    else
	s = OPEN_SOCKET(s);
#else
    SOCKET_TEST(s = psocket(af, type, protocol), INVALID_SOCKET);
#endif	/* USE_SOCKETS_AS_HANDLES */

    return s;
}

int CPerlSock::Socketpair(int domain, int type, int protocol, int* fds, int &err)
{
	croak("socketpair not implemented!\n");
	return 0;
}


