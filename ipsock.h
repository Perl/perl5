/*

    ipsock.h
    Interface for perl socket functions

*/

#ifndef __Inc__IPerlSock___
#define __Inc__IPerlSock___

class IPerlSock
{
public:
    virtual u_long Htonl(u_long hostlong) = 0;
    virtual u_short Htons(u_short hostshort) = 0;
    virtual u_long Ntohl(u_long netlong) = 0;
    virtual u_short Ntohs(u_short netshort) = 0;
    virtual SOCKET Accept(SOCKET s, struct sockaddr* addr, int* addrlen, int &err) = 0;
    virtual int Bind(SOCKET s, const struct sockaddr* name, int namelen, int &err) = 0;
    virtual int Connect(SOCKET s, const struct sockaddr* name, int namelen, int &err) = 0;
    virtual void Endhostent(int &err) = 0;
    virtual void Endnetent(int &err) = 0;
    virtual void Endprotoent(int &err) = 0;
    virtual void Endservent(int &err) = 0;
    virtual struct hostent* Gethostbyaddr(const char* addr, int len, int type, int &err) = 0;
    virtual struct hostent* Gethostbyname(const char* name, int &err) = 0;
    virtual struct hostent* Gethostent(int &err) = 0;
    virtual int Gethostname(char* name, int namelen, int &err) = 0;
    virtual struct netent *Getnetbyaddr(long net, int type, int &err) = 0;
    virtual struct netent *Getnetbyname(const char *, int &err) = 0;
    virtual struct netent *Getnetent(int &err) = 0;
    virtual int Getpeername(SOCKET s, struct sockaddr* name, int* namelen, int &err) = 0;
    virtual struct protoent* Getprotobyname(const char* name, int &err) = 0;
    virtual struct protoent* Getprotobynumber(int number, int &err) = 0;
    virtual struct protoent* Getprotoent(int &err) = 0;
    virtual struct servent* Getservbyname(const char* name, const char* proto, int &err) = 0;
    virtual struct servent* Getservbyport(int port, const char* proto, int &err) = 0;
    virtual struct servent* Getservent(int &err) = 0;
    virtual int Getsockname(SOCKET s, struct sockaddr* name, int* namelen, int &err) = 0;
    virtual int Getsockopt(SOCKET s, int level, int optname, char* optval, int* optlen, int &err) = 0;
    virtual unsigned long InetAddr(const char* cp, int &err) = 0;
    virtual char* InetNtoa(struct in_addr in, int &err) = 0;
    virtual int Listen(SOCKET s, int backlog, int &err) = 0;
    virtual int Recv(SOCKET s, char* buf, int len, int flags, int &err) = 0;
    virtual int Recvfrom(SOCKET s, char* buf, int len, int flags, struct sockaddr* from, int* fromlen, int &err) = 0;
    virtual int Select(int nfds, char* readfds, char* writefds, char* exceptfds, const struct timeval* timeout, int &err) = 0;
    virtual int Send(SOCKET s, const char* buf, int len, int flags, int &err) = 0; 
    virtual int Sendto(SOCKET s, const char* buf, int len, int flags, const struct sockaddr* to, int tolen, int &err) = 0;
    virtual void Sethostent(int stayopen, int &err) = 0;
    virtual void Setnetent(int stayopen, int &err) = 0;
    virtual void Setprotoent(int stayopen, int &err) = 0;
    virtual void Setservent(int stayopen, int &err) = 0;
    virtual int Setsockopt(SOCKET s, int level, int optname, const char* optval, int optlen, int &err) = 0;
    virtual int Shutdown(SOCKET s, int how, int &err) = 0;
    virtual SOCKET Socket(int af, int type, int protocol, int &err) = 0;
    virtual int Socketpair(int domain, int type, int protocol, int* fds, int &err) = 0;
#ifdef WIN32
    virtual int Closesocket(SOCKET s, int& err) = 0;
    virtual int Ioctlsocket(SOCKET s, long cmd, u_long *argp, int& err) = 0;
#endif
};

#endif	/* __Inc__IPerlSock___ */

