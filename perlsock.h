#ifndef H_PERLSOCK
#define H_PERLSOCK 1

#ifdef PERL_OBJECT

#include "ipsock.h"

#define PerlSock_htonl(x) piSock->Htonl(x)
#define PerlSock_htons(x) piSock->Htons(x)
#define PerlSock_ntohl(x) piSock->Ntohl(x)
#define PerlSock_ntohs(x) piSock->Ntohs(x)
#define PerlSock_accept(s, a, l) piSock->Accept(s, a, l, ErrorNo())
#define PerlSock_bind(s, n, l) piSock->Bind(s, n, l, ErrorNo())
#define PerlSock_connect(s, n, l) piSock->Connect(s, n, l, ErrorNo())
#define PerlSock_endhostent() piSock->Endhostent(ErrorNo())
#define PerlSock_endnetent() piSock->Endnetent(ErrorNo())
#define PerlSock_endprotoent() piSock->Endprotoent(ErrorNo())
#define PerlSock_endservent() piSock->Endservent(ErrorNo())
#define PerlSock_gethostbyaddr(a, l, t) piSock->Gethostbyaddr(a, l, t, ErrorNo())
#define PerlSock_gethostbyname(n) piSock->Gethostbyname(n, ErrorNo())
#define PerlSock_gethostent() piSock->Gethostent(ErrorNo())
#define PerlSock_gethostname(n, l) piSock->Gethostname(n, l, ErrorNo())
#define PerlSock_getnetbyaddr(n, t) piSock->Getnetbyaddr(n, t, ErrorNo())
#define PerlSock_getnetbyname(c) piSock->Getnetbyname(c, ErrorNo())
#define PerlSock_getnetent() piSock->Getnetent(ErrorNo())
#define PerlSock_getpeername(s, n, l) piSock->Getpeername(s, n, l, ErrorNo())
#define PerlSock_getprotobyname(n) piSock->Getprotobyname(n, ErrorNo())
#define PerlSock_getprotobynumber(n) piSock->Getprotobynumber(n, ErrorNo())
#define PerlSock_getprotoent() piSock->Getprotoent(ErrorNo())
#define PerlSock_getservbyname(n, p) piSock->Getservbyname(n, p, ErrorNo())
#define PerlSock_getservbyport(port, p) piSock->Getservbyport(port, p, ErrorNo())
#define PerlSock_getservent() piSock->Getservent(ErrorNo())
#define PerlSock_getsockname(s, n, l) piSock->Getsockname(s, n, l, ErrorNo())
#define PerlSock_getsockopt(s, l, n, v, i) piSock->Getsockopt(s, l, n, v, i, ErrorNo())
#define PerlSock_inet_addr(c) piSock->InetAddr(c, ErrorNo())
#define PerlSock_inet_ntoa(i) piSock->InetNtoa(i, ErrorNo())
#define PerlSock_listen(s, b) piSock->Listen(s, b, ErrorNo())
#define PerlSock_recv(s, b, l, f) piSock->Recv(s, b, l, f, ErrorNo())
#define PerlSock_recvfrom(s, b, l, f, from, fromlen) piSock->Recvfrom(s, b, l, f, from, fromlen, ErrorNo())
#define PerlSock_select(n, r, w, e, t) piSock->Select(n, (char*)r, (char*)w, (char*)e, t, ErrorNo())
#define PerlSock_send(s, b, l, f) piSock->Send(s, b, l, f, ErrorNo())
#define PerlSock_sendto(s, b, l, f, t, tlen) piSock->Sendto(s, b, l, f, t, tlen, ErrorNo())
#define PerlSock_sethostent(f) piSock->Sethostent(f, ErrorNo())
#define PerlSock_setnetent(f) piSock->Setnetent(f, ErrorNo())
#define PerlSock_setprotoent(f) piSock->Setprotoent(f, ErrorNo())
#define PerlSock_setservent(f) piSock->Setservent(f, ErrorNo())
#define PerlSock_setsockopt(s, l, n, v, len) piSock->Setsockopt(s, l, n, v, len, ErrorNo())
#define PerlSock_shutdown(s, h) piSock->Shutdown(s, h, ErrorNo())
#define PerlSock_socket(a, t, p) piSock->Socket(a, t, p, ErrorNo())
#define PerlSock_socketpair(a, t, p, f) piSock->Socketpair(a, t, p, f, ErrorNo())
#else
#define PerlSock_htonl(x) htonl(x)
#define PerlSock_htons(x) htons(x)
#define PerlSock_ntohl(x) ntohl(x)
#define PerlSock_ntohs(x) ntohs(x)
#define PerlSock_accept(s, a, l) accept(s, a, l)
#define PerlSock_bind(s, n, l) bind(s, n, l)
#define PerlSock_connect(s, n, l) connect(s, n, l)

#define PerlSock_gethostbyaddr(a, l, t) gethostbyaddr(a, l, t)
#define PerlSock_gethostbyname(n) gethostbyname(n)
#define PerlSock_gethostent gethostent
#define PerlSock_endhostent endhostent
#define PerlSock_gethostname(n, l) gethostname(n, l)

#define PerlSock_getnetbyaddr(n, t) getnetbyaddr(n, t)
#define PerlSock_getnetbyname(n) getnetbyname(n)
#define PerlSock_getnetent getnetent
#define PerlSock_endnetent endnetent
#define PerlSock_getpeername(s, n, l) getpeername(s, n, l)

#define PerlSock_getprotobyname(n) getprotobyname(n)
#define PerlSock_getprotobynumber(n) getprotobynumber(n)
#define PerlSock_getprotoent getprotoent
#define PerlSock_endprotoent endprotoent

#define PerlSock_getservbyname(n, p) getservbyname(n, p)
#define PerlSock_getservbyport(port, p) getservbyport(port, p)
#define PerlSock_getservent getservent
#define PerlSock_endservent endservent

#define PerlSock_getsockname(s, n, l) getsockname(s, n, l)
#define PerlSock_getsockopt(s, l, n, v, i) getsockopt(s, l, n, v, i)
#define PerlSock_inet_addr(c) inet_addr(c)
#define PerlSock_inet_ntoa(i) inet_ntoa(i)
#define PerlSock_listen(s, b) listen(s, b)
#define PerlSock_recvfrom(s, b, l, f, from, fromlen) recvfrom(s, b, l, f, from, fromlen)
#define PerlSock_select(n, r, w, e, t) select(n, r, w, e, t)
#define PerlSock_send(s, b, l, f) send(s, b, l, f)
#define PerlSock_sendto(s, b, l, f, t, tlen) sendto(s, b, l, f, t, tlen)
#define PerlSock_sethostent(f) sethostent(f)
#define PerlSock_setnetent(f) setnetent(f)
#define PerlSock_setprotoent(f) setprotoent(f)
#define PerlSock_setservent(f) setservent(f)
#define PerlSock_setsockopt(s, l, n, v, len) setsockopt(s, l, n, v, len)
#define PerlSock_shutdown(s, h) shutdown(s, h)
#define PerlSock_socket(a, t, p) socket(a, t, p)
#define PerlSock_socketpair(a, t, p, f) socketpair(a, t, p, f)
#endif	/* PERL_OBJECT */

#endif /* Include guard */

