#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/socket.h>

#ifndef AF_NBS
#undef PF_NBS
#endif

#ifndef AF_X25
#undef PF_X25
#endif

static int
not_here(s)
char *s;
{
    croak("Socket::%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "AF_802"))
#ifdef AF_802
	    return AF_802;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_APPLETALK"))
#ifdef AF_APPLETALK
	    return AF_APPLETALK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_CCITT"))
#ifdef AF_CCITT
	    return AF_CCITT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_CHAOS"))
#ifdef AF_CHAOS
	    return AF_CHAOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_DATAKIT"))
#ifdef AF_DATAKIT
	    return AF_DATAKIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_DECnet"))
#ifdef AF_DECnet
	    return AF_DECnet;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_DLI"))
#ifdef AF_DLI
	    return AF_DLI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_ECMA"))
#ifdef AF_ECMA
	    return AF_ECMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_GOSIP"))
#ifdef AF_GOSIP
	    return AF_GOSIP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_HYLINK"))
#ifdef AF_HYLINK
	    return AF_HYLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_IMPLINK"))
#ifdef AF_IMPLINK
	    return AF_IMPLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_INET"))
#ifdef AF_INET
	    return AF_INET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_LAT"))
#ifdef AF_LAT
	    return AF_LAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_MAX"))
#ifdef AF_MAX
	    return AF_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_NBS"))
#ifdef AF_NBS
	    return AF_NBS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_NIT"))
#ifdef AF_NIT
	    return AF_NIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_NS"))
#ifdef AF_NS
	    return AF_NS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_OSI"))
#ifdef AF_OSI
	    return AF_OSI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_OSINET"))
#ifdef AF_OSINET
	    return AF_OSINET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_PUP"))
#ifdef AF_PUP
	    return AF_PUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_SNA"))
#ifdef AF_SNA
	    return AF_SNA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_UNIX"))
#ifdef AF_UNIX
	    return AF_UNIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_UNSPEC"))
#ifdef AF_UNSPEC
	    return AF_UNSPEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AF_X25"))
#ifdef AF_X25
	    return AF_X25;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MSG_DONTROUTE"))
#ifdef MSG_DONTROUTE
	    return MSG_DONTROUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_MAXIOVLEN"))
#ifdef MSG_MAXIOVLEN
	    return MSG_MAXIOVLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_OOB"))
#ifdef MSG_OOB
	    return MSG_OOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_PEEK"))
#ifdef MSG_PEEK
	    return MSG_PEEK;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	if (strEQ(name, "PF_802"))
#ifdef PF_802
	    return PF_802;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_APPLETALK"))
#ifdef PF_APPLETALK
	    return PF_APPLETALK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_CCITT"))
#ifdef PF_CCITT
	    return PF_CCITT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_CHAOS"))
#ifdef PF_CHAOS
	    return PF_CHAOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_DATAKIT"))
#ifdef PF_DATAKIT
	    return PF_DATAKIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_DECnet"))
#ifdef PF_DECnet
	    return PF_DECnet;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_DLI"))
#ifdef PF_DLI
	    return PF_DLI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_ECMA"))
#ifdef PF_ECMA
	    return PF_ECMA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_GOSIP"))
#ifdef PF_GOSIP
	    return PF_GOSIP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_HYLINK"))
#ifdef PF_HYLINK
	    return PF_HYLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_IMPLINK"))
#ifdef PF_IMPLINK
	    return PF_IMPLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_INET"))
#ifdef PF_INET
	    return PF_INET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_LAT"))
#ifdef PF_LAT
	    return PF_LAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_MAX"))
#ifdef PF_MAX
	    return PF_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_NBS"))
#ifdef PF_NBS
	    return PF_NBS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_NIT"))
#ifdef PF_NIT
	    return PF_NIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_NS"))
#ifdef PF_NS
	    return PF_NS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_OSI"))
#ifdef PF_OSI
	    return PF_OSI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_OSINET"))
#ifdef PF_OSINET
	    return PF_OSINET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_PUP"))
#ifdef PF_PUP
	    return PF_PUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_SNA"))
#ifdef PF_SNA
	    return PF_SNA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_UNIX"))
#ifdef PF_UNIX
	    return PF_UNIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_UNSPEC"))
#ifdef PF_UNSPEC
	    return PF_UNSPEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PF_X25"))
#ifdef PF_X25
	    return PF_X25;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	if (strEQ(name, "SOCK_DGRAM"))
#ifdef SOCK_DGRAM
	    return SOCK_DGRAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCK_RAW"))
#ifdef SOCK_RAW
	    return SOCK_RAW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCK_RDM"))
#ifdef SOCK_RDM
	    return SOCK_RDM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCK_SEQPACKET"))
#ifdef SOCK_SEQPACKET
	    return SOCK_SEQPACKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCK_STREAM"))
#ifdef SOCK_STREAM
	    return SOCK_STREAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOL_SOCKET"))
#ifdef SOL_SOCKET
	    return SOL_SOCKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOMAXCONN"))
#ifdef SOMAXCONN
	    return SOMAXCONN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_ACCEPTCONN"))
#ifdef SO_ACCEPTCONN
	    return SO_ACCEPTCONN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_BROADCAST"))
#ifdef SO_BROADCAST
	    return SO_BROADCAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_DEBUG"))
#ifdef SO_DEBUG
	    return SO_DEBUG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_DONTLINGER"))
#ifdef SO_DONTLINGER
	    return SO_DONTLINGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_DONTROUTE"))
#ifdef SO_DONTROUTE
	    return SO_DONTROUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_ERROR"))
#ifdef SO_ERROR
	    return SO_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_KEEPALIVE"))
#ifdef SO_KEEPALIVE
	    return SO_KEEPALIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_LINGER"))
#ifdef SO_LINGER
	    return SO_LINGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_OOBINLINE"))
#ifdef SO_OOBINLINE
	    return SO_OOBINLINE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_RCVBUF"))
#ifdef SO_RCVBUF
	    return SO_RCVBUF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_RCVLOWAT"))
#ifdef SO_RCVLOWAT
	    return SO_RCVLOWAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_RCVTIMEO"))
#ifdef SO_RCVTIMEO
	    return SO_RCVTIMEO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_REUSEADDR"))
#ifdef SO_REUSEADDR
	    return SO_REUSEADDR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_REUSEPORT"))
#ifdef SO_REUSEPORT
	    return SO_REUSEPORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_SNDBUF"))
#ifdef SO_SNDBUF
	    return SO_SNDBUF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_SNDLOWAT"))
#ifdef SO_SNDLOWAT
	    return SO_SNDLOWAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_SNDTIMEO"))
#ifdef SO_SNDTIMEO
	    return SO_SNDTIMEO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_TYPE"))
#ifdef SO_TYPE
	    return SO_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SO_USELOOPBACK"))
#ifdef SO_USELOOPBACK
	    return SO_USELOOPBACK;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Socket		PACKAGE = Socket

double
constant(name,arg)
	char *		name
	int		arg

