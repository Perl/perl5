#ifndef _INC_SYS_ERRNO2
#define _INC_SYS_ERRNO2

#define _WINSOCKAPI_	/* Don't drag in everything */
#include <winsock.h>

/* Ensure all the Exxx constants required by get_last_socket_error() in
 * win32/win32sck.c are defined. Many are defined in <errno.h> already (more in
 * VC++ 2010 and above) so, for the sake of compatibility with third-party code
 * linked into XS modules, we must be careful not to redefine them; for the
 * remainder we define our own values, namely the corresponding WSAExxx values.
 * These definitions are also used as a supplement to the use of <errno.h> in
 * the Errno and POSIX modules, both of which may be used to test the value of
 * $!, which may have these values assigned to it (via win32/win32sck.c). It
 * also provides numerous otherwise missing values in the (hard-coded) list of
 * Exxx constants exported by POSIX.
 */
#ifndef EINTR
#  define EINTR			WSAEINTR
#endif
#ifndef EBADF
#  define EBADF			WSAEBADF
#endif
#ifndef EACCES
#  define EACCES		WSAEACCES
#endif
#ifndef EFAULT
#  define EFAULT		WSAEFAULT
#endif
#ifndef EINVAL
#  define EINVAL		WSAEINVAL
#endif
#ifndef EMFILE
#  define EMFILE		WSAEMFILE
#endif
#ifndef EWOULDBLOCK
#  define EWOULDBLOCK		WSAEWOULDBLOCK
#endif
#ifndef EINPROGRESS
#  define EINPROGRESS		WSAEINPROGRESS
#endif
#ifndef EALREADY
#  define EALREADY		WSAEALREADY
#endif
#ifndef ENOTSOCK
#  define ENOTSOCK		WSAENOTSOCK
#endif
#ifndef EDESTADDRREQ
#  define EDESTADDRREQ		WSAEDESTADDRREQ
#endif
#ifndef EMSGSIZE
#  define EMSGSIZE		WSAEMSGSIZE
#endif
#ifndef EPROTOTYPE
#  define EPROTOTYPE		WSAEPROTOTYPE
#endif
#ifndef ENOPROTOOPT
#  define ENOPROTOOPT		WSAENOPROTOOPT
#endif
#ifndef EPROTONOSUPPORT
#  define EPROTONOSUPPORT	WSAEPROTONOSUPPORT
#endif
#ifndef ESOCKTNOSUPPORT
#  define ESOCKTNOSUPPORT	WSAESOCKTNOSUPPORT
#endif
#ifndef EOPNOTSUPP
#  define EOPNOTSUPP		WSAEOPNOTSUPP
#endif
#ifndef EPFNOSUPPORT
#  define EPFNOSUPPORT		WSAEPFNOSUPPORT
#endif
#ifndef EAFNOSUPPORT
#  define EAFNOSUPPORT		WSAEAFNOSUPPORT
#endif
#ifndef EADDRINUSE
#  define EADDRINUSE		WSAEADDRINUSE
#endif
#ifndef EADDRNOTAVAIL
#  define EADDRNOTAVAIL		WSAEADDRNOTAVAIL
#endif
#ifndef ENETDOWN
#  define ENETDOWN		WSAENETDOWN
#endif
#ifndef ENETUNREACH
#  define ENETUNREACH		WSAENETUNREACH
#endif
#ifndef ENETRESET
#  define ENETRESET		WSAENETRESET
#endif
#ifndef ECONNABORTED
#  define ECONNABORTED		WSAECONNABORTED
#endif
#ifndef ECONNRESET
#  define ECONNRESET		WSAECONNRESET
#endif
#ifndef ENOBUFS
#  define ENOBUFS		WSAENOBUFS
#endif
#ifndef EISCONN
#  define EISCONN		WSAEISCONN
#endif
#ifndef ENOTCONN
#  define ENOTCONN		WSAENOTCONN
#endif
#ifndef ESHUTDOWN
#  define ESHUTDOWN		WSAESHUTDOWN
#endif
#ifndef ETOOMANYREFS
#  define ETOOMANYREFS		WSAETOOMANYREFS
#endif
#ifndef ETIMEDOUT
#  define ETIMEDOUT		WSAETIMEDOUT
#endif
#ifndef ECONNREFUSED
#  define ECONNREFUSED		WSAECONNREFUSED
#endif
#ifndef ELOOP
#  define ELOOP			WSAELOOP
#endif
#ifndef ENAMETOOLONG
#  define ENAMETOOLONG		WSAENAMETOOLONG
#endif
#ifndef EHOSTDOWN
#  define EHOSTDOWN		WSAEHOSTDOWN
#endif
#ifndef EHOSTUNREACH
#  define EHOSTUNREACH		WSAEHOSTUNREACH
#endif
#ifndef ENOTEMPTY
#  define ENOTEMPTY		WSAENOTEMPTY
#endif
#ifndef EPROCLIM
#  define EPROCLIM		WSAEPROCLIM
#endif
#ifndef EUSERS
#  define EUSERS		WSAEUSERS
#endif
#ifndef EDQUOT
#  define EDQUOT		WSAEDQUOT
#endif
#ifndef ESTALE
#  define ESTALE		WSAESTALE
#endif
#ifndef EREMOTE
#  define EREMOTE		WSAEREMOTE
#endif
#ifndef EDISCON
#  define EDISCON		WSAEDISCON
#endif
#ifndef ENOMORE
#  define ENOMORE		WSAENOMORE
#endif
#ifndef ECANCELLED
#  define ECANCELLED		WSAECANCELLED
#endif
#ifndef EINVALIDPROCTABLE
#  define EINVALIDPROCTABLE	WSAEINVALIDPROCTABLE
#endif
#ifndef EINVALIDPROVIDER
#  define EINVALIDPROVIDER	WSAEINVALIDPROVIDER
#endif
#ifndef EPROVIDERFAILEDINIT
#  define EPROVIDERFAILEDINIT	WSAEPROVIDERFAILEDINIT
#endif
#ifndef EREFUSED
#  define EREFUSED		WSAEREFUSED
#endif

#endif /* _INC_SYS_ERRNO2 */
