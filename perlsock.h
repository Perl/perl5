#ifndef H_PERLSOCK
#define H_PERLSOCK 1

#ifdef PERL_OBJECT
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
#define PerlSock_listen(s, b) listen(s, b)
#define PerlSock_recvfrom(s, b, l, f, from, fromlen) recvfrom(s, b, l, f, from, fromlen)
#define PerlSock_select(n, r, w, e, t) select(n, r, w, e, t)
#define PerlSock_send(s, b, l, f) send(s, b, l, f)
#define PerlSock_sendto(s, b, l, f, t, tlen) sendto(s, b, l, f, t, tlen)
#define PerlSock_setsockopt(s, l, n, v, len) setsockopt(s, l, n, v, len)
#define PerlSock_shutdown(s, h) shutdown(s, h)
#define PerlSock_socket(a, t, p) socket(a, t, p)
#define PerlSock_socketpair(a, t, p, f) socketpair(a, t, p, f)
#endif	/* PERL_OBJECT */

#endif /* Include guard */
