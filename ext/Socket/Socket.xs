#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef VMS
# ifdef I_SYS_TYPES
#  include <sys/types.h>
# endif
# include <sys/socket.h>
# if defined(USE_SOCKS) && defined(I_SOCKS)
#   include <socks.h>
# endif 
# ifdef MPE
#  define PF_INET AF_INET
#  define PF_UNIX AF_UNIX
#  define SOCK_RAW 3
# endif
# ifdef I_SYS_UN
#  include <sys/un.h>
# endif
/* XXX Configure test for <netinet/in_systm.h needed XXX */
# if defined(NeXT) || defined(__NeXT__)
#  include <netinet/in_systm.h>
# endif
# ifdef I_NETINET_IN
#  include <netinet/in.h>
# endif
# ifdef I_NETDB
#  include <netdb.h>
# endif
# ifdef I_ARPA_INET
#  include <arpa/inet.h>
# endif
# ifdef I_NETINET_TCP
#  include <netinet/tcp.h>
# endif
#else
# include "sockadapt.h"
#endif

#ifdef I_SYSUIO
# include <sys/uio.h>
#endif

#ifndef AF_NBS
# undef PF_NBS
#endif

#ifndef AF_X25
# undef PF_X25
#endif

#ifndef INADDR_NONE
# define INADDR_NONE	0xffffffff
#endif /* INADDR_NONE */
#ifndef INADDR_BROADCAST
# define INADDR_BROADCAST	0xffffffff
#endif /* INADDR_BROADCAST */
#ifndef INADDR_LOOPBACK
# define INADDR_LOOPBACK         0x7F000001
#endif /* INADDR_LOOPBACK */

#ifndef HAS_INET_ATON

/* 
 * Check whether "cp" is a valid ascii representation
 * of an Internet address and convert to a binary address.
 * Returns 1 if the address is valid, 0 if not.
 * This replaces inet_addr, the return value from which
 * cannot distinguish between failure and a local broadcast address.
 */
static int
my_inet_aton(register const char *cp, struct in_addr *addr)
{
	dTHX;
	register U32 val;
	register int base;
	register char c;
	int nparts;
	const char *s;
	unsigned int parts[4];
	register unsigned int *pp = parts;

	if (!cp)
		return 0;
	for (;;) {
		/*
		 * Collect number up to ``.''.
		 * Values are specified as for C:
		 * 0x=hex, 0=octal, other=decimal.
		 */
		val = 0; base = 10;
		if (*cp == '0') {
			if (*++cp == 'x' || *cp == 'X')
				base = 16, cp++;
			else
				base = 8;
		}
		while ((c = *cp) != '\0') {
			if (isDIGIT(c)) {
				val = (val * base) + (c - '0');
				cp++;
				continue;
			}
			if (base == 16 && (s=strchr(PL_hexdigit,c))) {
				val = (val << 4) + 
					((s - PL_hexdigit) & 15);
				cp++;
				continue;
			}
			break;
		}
		if (*cp == '.') {
			/*
			 * Internet format:
			 *	a.b.c.d
			 *	a.b.c	(with c treated as 16-bits)
			 *	a.b	(with b treated as 24 bits)
			 */
			if (pp >= parts + 3 || val > 0xff)
				return 0;
			*pp++ = val, cp++;
		} else
			break;
	}
	/*
	 * Check for trailing characters.
	 */
	if (*cp && !isSPACE(*cp))
		return 0;
	/*
	 * Concoct the address according to
	 * the number of parts specified.
	 */
	nparts = pp - parts + 1;	/* force to an int for switch() */
	switch (nparts) {

	case 1:				/* a -- 32 bits */
		break;

	case 2:				/* a.b -- 8.24 bits */
		if (val > 0xffffff)
			return 0;
		val |= parts[0] << 24;
		break;

	case 3:				/* a.b.c -- 8.8.16 bits */
		if (val > 0xffff)
			return 0;
		val |= (parts[0] << 24) | (parts[1] << 16);
		break;

	case 4:				/* a.b.c.d -- 8.8.8.8 bits */
		if (val > 0xff)
			return 0;
		val |= (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8);
		break;
	}
	addr->s_addr = htonl(val);
	return 1;
}

#undef inet_aton
#define inet_aton my_inet_aton

#endif /* ! HAS_INET_ATON */


static int
not_here(char *s)
{
    croak("Socket::%s not implemented on this architecture", s);
    return -1;
}

#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

static int
constant_6 (pTHX_ const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AF_802 AF_DLI AF_LAT AF_MAX AF_NBS AF_NIT AF_OSI AF_PUP AF_SNA AF_X25
     PF_802 PF_DLI PF_LAT PF_MAX PF_NBS PF_NIT PF_OSI PF_PUP PF_SNA PF_X25 */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case '8':
    if (memEQ(name, "AF_802", 6)) {
    /*                  ^        */
#ifdef AF_802
      *iv_return = AF_802;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_802", 6)) {
    /*                  ^        */
#ifdef PF_802
      *iv_return = PF_802;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "AF_DLI", 6)) {
    /*                  ^        */
#ifdef AF_DLI
      *iv_return = AF_DLI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_DLI", 6)) {
    /*                  ^        */
#ifdef PF_DLI
      *iv_return = PF_DLI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "AF_LAT", 6)) {
    /*                  ^        */
#ifdef AF_LAT
      *iv_return = AF_LAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_LAT", 6)) {
    /*                  ^        */
#ifdef PF_LAT
      *iv_return = PF_LAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "AF_MAX", 6)) {
    /*                  ^        */
#ifdef AF_MAX
      *iv_return = AF_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_MAX", 6)) {
    /*                  ^        */
#ifdef PF_MAX
      *iv_return = PF_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "AF_NBS", 6)) {
    /*                  ^        */
#ifdef AF_NBS
      *iv_return = AF_NBS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "AF_NIT", 6)) {
    /*                  ^        */
#ifdef AF_NIT
      *iv_return = AF_NIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_NBS", 6)) {
    /*                  ^        */
#ifdef PF_NBS
      *iv_return = PF_NBS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_NIT", 6)) {
    /*                  ^        */
#ifdef PF_NIT
      *iv_return = PF_NIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "AF_OSI", 6)) {
    /*                  ^        */
#ifdef AF_OSI
      *iv_return = AF_OSI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_OSI", 6)) {
    /*                  ^        */
#ifdef PF_OSI
      *iv_return = PF_OSI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "AF_PUP", 6)) {
    /*                  ^        */
#ifdef AF_PUP
      *iv_return = AF_PUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_PUP", 6)) {
    /*                  ^        */
#ifdef PF_PUP
      *iv_return = PF_PUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "AF_SNA", 6)) {
    /*                  ^        */
#ifdef AF_SNA
      *iv_return = AF_SNA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_SNA", 6)) {
    /*                  ^        */
#ifdef PF_SNA
      *iv_return = PF_SNA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "AF_X25", 6)) {
    /*                  ^        */
#ifdef AF_X25
      *iv_return = AF_X25;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_X25", 6)) {
    /*                  ^        */
#ifdef PF_X25
      *iv_return = PF_X25;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AF_ECMA AF_INET AF_UNIX IOV_MAX MSG_EOF MSG_EOR MSG_FIN MSG_OOB MSG_RST
     MSG_SYN MSG_URG PF_ECMA PF_INET PF_UNIX SHUT_RD SHUT_WR SO_TYPE */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'C':
    if (memEQ(name, "AF_ECMA", 7)) {
    /*                   ^        */
#ifdef AF_ECMA
      *iv_return = AF_ECMA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_ECMA", 7)) {
    /*                   ^        */
#ifdef PF_ECMA
      *iv_return = PF_ECMA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "MSG_EOF", 7)) {
    /*                   ^        */
#ifdef MSG_EOF
      *iv_return = MSG_EOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_EOR", 7)) {
    /*                   ^        */
#ifdef MSG_EOR
      *iv_return = MSG_EOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "MSG_FIN", 7)) {
    /*                   ^        */
#ifdef MSG_FIN
      *iv_return = MSG_FIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "IOV_MAX", 7)) {
    /*                   ^        */
#ifdef IOV_MAX
      *iv_return = IOV_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "AF_INET", 7)) {
    /*                   ^        */
#ifdef AF_INET
      *iv_return = AF_INET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "AF_UNIX", 7)) {
    /*                   ^        */
#ifdef AF_UNIX
      *iv_return = AF_UNIX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_INET", 7)) {
    /*                   ^        */
#ifdef PF_INET
      *iv_return = PF_INET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_UNIX", 7)) {
    /*                   ^        */
#ifdef PF_UNIX
      *iv_return = PF_UNIX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "MSG_OOB", 7)) {
    /*                   ^        */
#if defined(MSG_OOB) || defined(HAS_MSG_OOB) /* might be an enum */
      *iv_return = MSG_OOB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MSG_RST", 7)) {
    /*                   ^        */
#ifdef MSG_RST
      *iv_return = MSG_RST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MSG_SYN", 7)) {
    /*                   ^        */
#ifdef MSG_SYN
      *iv_return = MSG_SYN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MSG_URG", 7)) {
    /*                   ^        */
#ifdef MSG_URG
      *iv_return = MSG_URG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "SO_TYPE", 7)) {
    /*                   ^        */
#ifdef SO_TYPE
      *iv_return = SO_TYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "SHUT_RD", 7)) {
    /*                   ^        */
#ifdef SHUT_RD
      *iv_return = SHUT_RD;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "SHUT_WR", 7)) {
    /*                   ^        */
#ifdef SHUT_WR
      *iv_return = SHUT_WR;
      return PERL_constant_ISIV;
#else
      *iv_return = 1;
      return PERL_constant_ISIV;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AF_CCITT AF_CHAOS AF_GOSIP MSG_PEEK PF_CCITT PF_CHAOS PF_GOSIP SOCK_RAW
     SOCK_RDM SO_DEBUG SO_ERROR */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'G':
    if (memEQ(name, "SO_DEBUG", 8)) {
    /*                      ^      */
#ifdef SO_DEBUG
      *iv_return = SO_DEBUG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "MSG_PEEK", 8)) {
    /*                      ^      */
#if defined(MSG_PEEK) || defined(HAS_MSG_PEEK) /* might be an enum */
      *iv_return = MSG_PEEK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SOCK_RDM", 8)) {
    /*                      ^      */
#ifdef SOCK_RDM
      *iv_return = SOCK_RDM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "AF_GOSIP", 8)) {
    /*                      ^      */
#ifdef AF_GOSIP
      *iv_return = AF_GOSIP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_GOSIP", 8)) {
    /*                      ^      */
#ifdef PF_GOSIP
      *iv_return = PF_GOSIP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SO_ERROR", 8)) {
    /*                      ^      */
#ifdef SO_ERROR
      *iv_return = SO_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "AF_CHAOS", 8)) {
    /*                      ^      */
#ifdef AF_CHAOS
      *iv_return = AF_CHAOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_CHAOS", 8)) {
    /*                      ^      */
#ifdef PF_CHAOS
      *iv_return = PF_CHAOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "AF_CCITT", 8)) {
    /*                      ^      */
#ifdef AF_CCITT
      *iv_return = AF_CCITT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_CCITT", 8)) {
    /*                      ^      */
#ifdef PF_CCITT
      *iv_return = PF_CCITT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "SOCK_RAW", 8)) {
    /*                      ^      */
#ifdef SOCK_RAW
      *iv_return = SOCK_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AF_DECnet AF_HYLINK AF_OSINET AF_UNSPEC MSG_BCAST MSG_MCAST MSG_PROXY
     MSG_TRUNC PF_DECnet PF_HYLINK PF_OSINET PF_UNSPEC SCM_CREDS SHUT_RDWR
     SOMAXCONN SO_LINGER SO_RCVBUF SO_SNDBUF TCP_MAXRT */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "MSG_BCAST", 9)) {
    /*                     ^        */
#ifdef MSG_BCAST
      *iv_return = MSG_BCAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_MCAST", 9)) {
    /*                     ^        */
#ifdef MSG_MCAST
      *iv_return = MSG_MCAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "SO_RCVBUF", 9)) {
    /*                     ^        */
#ifdef SO_RCVBUF
      *iv_return = SO_RCVBUF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SO_SNDBUF", 9)) {
    /*                     ^        */
#ifdef SO_SNDBUF
      *iv_return = SO_SNDBUF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "SHUT_RDWR", 9)) {
    /*                     ^        */
#ifdef SHUT_RDWR
      *iv_return = SHUT_RDWR;
      return PERL_constant_ISIV;
#else
      *iv_return = 2;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SCM_CREDS", 9)) {
    /*                     ^        */
#ifdef SCM_CREDS
      *iv_return = SCM_CREDS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SO_LINGER", 9)) {
    /*                     ^        */
#ifdef SO_LINGER
      *iv_return = SO_LINGER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "AF_HYLINK", 9)) {
    /*                     ^        */
#ifdef AF_HYLINK
      *iv_return = AF_HYLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_HYLINK", 9)) {
    /*                     ^        */
#ifdef PF_HYLINK
      *iv_return = PF_HYLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "AF_OSINET", 9)) {
    /*                     ^        */
#ifdef AF_OSINET
      *iv_return = AF_OSINET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_OSINET", 9)) {
    /*                     ^        */
#ifdef PF_OSINET
      *iv_return = PF_OSINET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "MSG_PROXY", 9)) {
    /*                     ^        */
#if defined(MSG_PROXY) || defined(HAS_MSG_PROXY) /* might be an enum */
      *iv_return = MSG_PROXY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SOMAXCONN", 9)) {
    /*                     ^        */
#ifdef SOMAXCONN
      *iv_return = SOMAXCONN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "AF_UNSPEC", 9)) {
    /*                     ^        */
#ifdef AF_UNSPEC
      *iv_return = AF_UNSPEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_UNSPEC", 9)) {
    /*                     ^        */
#ifdef PF_UNSPEC
      *iv_return = PF_UNSPEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MSG_TRUNC", 9)) {
    /*                     ^        */
#ifdef MSG_TRUNC
      *iv_return = MSG_TRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "TCP_MAXRT", 9)) {
    /*                     ^        */
#ifdef TCP_MAXRT
      *iv_return = TCP_MAXRT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "AF_DECnet", 9)) {
    /*                     ^        */
#ifdef AF_DECnet
      *iv_return = AF_DECnet;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_DECnet", 9)) {
    /*                     ^        */
#ifdef PF_DECnet
      *iv_return = PF_DECnet;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AF_DATAKIT AF_IMPLINK INADDR_ANY MSG_CTRUNC PF_DATAKIT PF_IMPLINK
     SCM_RIGHTS SOCK_DGRAM SOL_SOCKET TCP_MAXSEG TCP_STDURG UIO_MAXIOV */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "AF_DATAKIT", 10)) {
    /*                     ^          */
#ifdef AF_DATAKIT
      *iv_return = AF_DATAKIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_DATAKIT", 10)) {
    /*                     ^          */
#ifdef PF_DATAKIT
      *iv_return = PF_DATAKIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SOL_SOCKET", 10)) {
    /*                     ^          */
#ifdef SOL_SOCKET
      *iv_return = SOL_SOCKET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "TCP_STDURG", 10)) {
    /*                     ^          */
#ifdef TCP_STDURG
      *iv_return = TCP_STDURG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SCM_RIGHTS", 10)) {
    /*                     ^          */
#if defined(SCM_RIGHTS) || defined(HAS_SCM_RIGHTS) /* might be an enum */
      *iv_return = SCM_RIGHTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SOCK_DGRAM", 10)) {
    /*                     ^          */
#ifdef SOCK_DGRAM
      *iv_return = SOCK_DGRAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "AF_IMPLINK", 10)) {
    /*                     ^          */
#ifdef AF_IMPLINK
      *iv_return = AF_IMPLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_IMPLINK", 10)) {
    /*                     ^          */
#ifdef PF_IMPLINK
      *iv_return = PF_IMPLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MSG_CTRUNC", 10)) {
    /*                     ^          */
#if defined(MSG_CTRUNC) || defined(HAS_MSG_CTRUNC) /* might be an enum */
      *iv_return = MSG_CTRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "TCP_MAXSEG", 10)) {
    /*                     ^          */
#ifdef TCP_MAXSEG
      *iv_return = TCP_MAXSEG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "UIO_MAXIOV", 10)) {
    /*                     ^          */
#ifdef UIO_MAXIOV
      *iv_return = UIO_MAXIOV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "INADDR_ANY", 10)) {
    /*                     ^          */
#ifdef INADDR_ANY
      {
struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_ANY);
        *sv_return =  sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ));
        return PERL_constant_ISSV;
      }
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     INADDR_NONE IPPROTO_TCP MSG_WAITALL SCM_CONNECT SOCK_STREAM SO_RCVLOWAT
     SO_RCVTIMEO SO_SNDLOWAT SO_SNDTIMEO TCP_NODELAY */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "MSG_WAITALL", 11)) {
    /*                    ^            */
#ifdef MSG_WAITALL
      *iv_return = MSG_WAITALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "SO_SNDLOWAT", 11)) {
    /*                    ^            */
#ifdef SO_SNDLOWAT
      *iv_return = SO_SNDLOWAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SO_SNDTIMEO", 11)) {
    /*                    ^            */
#ifdef SO_SNDTIMEO
      *iv_return = SO_SNDTIMEO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SCM_CONNECT", 11)) {
    /*                    ^            */
#ifdef SCM_CONNECT
      *iv_return = SCM_CONNECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCP_NODELAY", 11)) {
    /*                    ^            */
#ifdef TCP_NODELAY
      *iv_return = TCP_NODELAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "INADDR_NONE", 11)) {
    /*                    ^            */
#ifdef INADDR_NONE
      {
struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_NONE);
        *sv_return =  sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ));
        return PERL_constant_ISSV;
      }
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SOCK_STREAM", 11)) {
    /*                    ^            */
#ifdef SOCK_STREAM
      *iv_return = SOCK_STREAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "IPPROTO_TCP", 11)) {
    /*                    ^            */
#ifdef IPPROTO_TCP
      *iv_return = IPPROTO_TCP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "SO_RCVLOWAT", 11)) {
    /*                    ^            */
#ifdef SO_RCVLOWAT
      *iv_return = SO_RCVLOWAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SO_RCVTIMEO", 11)) {
    /*                    ^            */
#ifdef SO_RCVTIMEO
      *iv_return = SO_RCVTIMEO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AF_APPLETALK MSG_CTLFLAGS MSG_DONTWAIT MSG_ERRQUEUE MSG_NOSIGNAL
     PF_APPLETALK SO_BROADCAST SO_DONTROUTE SO_KEEPALIVE SO_OOBINLINE
     SO_REUSEADDR SO_REUSEPORT */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "MSG_NOSIGNAL", 12)) {
    /*                         ^        */
#ifdef MSG_NOSIGNAL
      *iv_return = MSG_NOSIGNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "SO_REUSEADDR", 12)) {
    /*                         ^        */
#ifdef SO_REUSEADDR
      *iv_return = SO_REUSEADDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "MSG_CTLFLAGS", 12)) {
    /*                         ^        */
#ifdef MSG_CTLFLAGS
      *iv_return = MSG_CTLFLAGS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "MSG_DONTWAIT", 12)) {
    /*                         ^        */
#ifdef MSG_DONTWAIT
      *iv_return = MSG_DONTWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "AF_APPLETALK", 12)) {
    /*                         ^        */
#ifdef AF_APPLETALK
      *iv_return = AF_APPLETALK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PF_APPLETALK", 12)) {
    /*                         ^        */
#ifdef PF_APPLETALK
      *iv_return = PF_APPLETALK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SO_OOBINLINE", 12)) {
    /*                         ^        */
#ifdef SO_OOBINLINE
      *iv_return = SO_OOBINLINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SO_REUSEPORT", 12)) {
    /*                         ^        */
#ifdef SO_REUSEPORT
      *iv_return = SO_REUSEPORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SO_BROADCAST", 12)) {
    /*                         ^        */
#ifdef SO_BROADCAST
      *iv_return = SO_BROADCAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SO_DONTROUTE", 12)) {
    /*                         ^        */
#ifdef SO_DONTROUTE
      *iv_return = SO_DONTROUTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MSG_ERRQUEUE", 12)) {
    /*                         ^        */
#ifdef MSG_ERRQUEUE
      *iv_return = MSG_ERRQUEUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "SO_KEEPALIVE", 12)) {
    /*                         ^        */
#ifdef SO_KEEPALIVE
      *iv_return = SO_KEEPALIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (const char *name, IV *iv_return, SV **sv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MSG_CTLIGNORE MSG_DONTROUTE MSG_MAXIOVLEN SCM_TIMESTAMP SO_ACCEPTCONN
     SO_DONTLINGER TCP_KEEPALIVE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "MSG_MAXIOVLEN", 13)) {
    /*                    ^              */
#ifdef MSG_MAXIOVLEN
      *iv_return = MSG_MAXIOVLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SO_ACCEPTCONN", 13)) {
    /*                    ^              */
#ifdef SO_ACCEPTCONN
      *iv_return = SO_ACCEPTCONN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "TCP_KEEPALIVE", 13)) {
    /*                    ^              */
#ifdef TCP_KEEPALIVE
      *iv_return = TCP_KEEPALIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SCM_TIMESTAMP", 13)) {
    /*                    ^              */
#ifdef SCM_TIMESTAMP
      *iv_return = SCM_TIMESTAMP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SO_DONTLINGER", 13)) {
    /*                    ^              */
#ifdef SO_DONTLINGER
      *iv_return = SO_DONTLINGER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "MSG_DONTROUTE", 13)) {
    /*                    ^              */
#if defined(MSG_DONTROUTE) || defined(HAS_MSG_DONTROUTE) /* might be an enum */
      *iv_return = MSG_DONTROUTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "MSG_CTLIGNORE", 13)) {
    /*                    ^              */
#ifdef MSG_CTLIGNORE
      *iv_return = MSG_CTLIGNORE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return, SV **sv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!../../perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV SV)};
my @names = (qw(AF_802 AF_APPLETALK AF_CCITT AF_CHAOS AF_DATAKIT AF_DECnet
	       AF_DLI AF_ECMA AF_GOSIP AF_HYLINK AF_IMPLINK AF_INET AF_LAT
	       AF_MAX AF_NBS AF_NIT AF_NS AF_OSI AF_OSINET AF_PUP AF_SNA
	       AF_UNIX AF_UNSPEC AF_X25 IOV_MAX IPPROTO_TCP MSG_BCAST
	       MSG_CTLFLAGS MSG_CTLIGNORE MSG_DONTWAIT MSG_EOF MSG_EOR
	       MSG_ERRQUEUE MSG_FIN MSG_MAXIOVLEN MSG_MCAST MSG_NOSIGNAL
	       MSG_RST MSG_SYN MSG_TRUNC MSG_URG MSG_WAITALL PF_802
	       PF_APPLETALK PF_CCITT PF_CHAOS PF_DATAKIT PF_DECnet PF_DLI
	       PF_ECMA PF_GOSIP PF_HYLINK PF_IMPLINK PF_INET PF_LAT PF_MAX
	       PF_NBS PF_NIT PF_NS PF_OSI PF_OSINET PF_PUP PF_SNA PF_UNIX
	       PF_UNSPEC PF_X25 SCM_CONNECT SCM_CREDENTIALS SCM_CREDS
	       SCM_TIMESTAMP SOCK_DGRAM SOCK_RAW SOCK_RDM SOCK_SEQPACKET
	       SOCK_STREAM SOL_SOCKET SOMAXCONN SO_ACCEPTCONN SO_BROADCAST
	       SO_DEBUG SO_DONTLINGER SO_DONTROUTE SO_ERROR SO_KEEPALIVE
	       SO_LINGER SO_OOBINLINE SO_RCVBUF SO_RCVLOWAT SO_RCVTIMEO
	       SO_REUSEADDR SO_REUSEPORT SO_SNDBUF SO_SNDLOWAT SO_SNDTIMEO
	       SO_TYPE SO_USELOOPBACK TCP_KEEPALIVE TCP_MAXRT TCP_MAXSEG
	       TCP_NODELAY TCP_STDURG UIO_MAXIOV),
            {name=>"INADDR_ANY", type=>"SV", value=>"sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ))", pre=>"struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_ANY);"},
            {name=>"INADDR_BROADCAST", type=>"SV", value=>"sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ))", pre=>"struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_BROADCAST);"},
            {name=>"INADDR_LOOPBACK", type=>"SV", value=>"sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ))", pre=>"struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_LOOPBACK);"},
            {name=>"INADDR_NONE", type=>"SV", value=>"sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ))", pre=>"struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_NONE);"},
            {name=>"MSG_CTRUNC", type=>"IV", macro=>["#if defined(MSG_CTRUNC) || defined(HAS_MSG_CTRUNC) /" . "* might be an enum *" . "/\n", "#endif\n"]},
            {name=>"MSG_DONTROUTE", type=>"IV", macro=>["#if defined(MSG_DONTROUTE) || defined(HAS_MSG_DONTROUTE) /" . "* might be an enum *" . "/\n", "#endif\n"]},
            {name=>"MSG_OOB", type=>"IV", macro=>["#if defined(MSG_OOB) || defined(HAS_MSG_OOB) /" . "* might be an enum *" . "/\n", "#endif\n"]},
            {name=>"MSG_PEEK", type=>"IV", macro=>["#if defined(MSG_PEEK) || defined(HAS_MSG_PEEK) /" . "* might be an enum *" . "/\n", "#endif\n"]},
            {name=>"MSG_PROXY", type=>"IV", macro=>["#if defined(MSG_PROXY) || defined(HAS_MSG_PROXY) /" . "* might be an enum *" . "/\n", "#endif\n"]},
            {name=>"SCM_RIGHTS", type=>"IV", macro=>["#if defined(SCM_RIGHTS) || defined(HAS_SCM_RIGHTS) /" . "* might be an enum *" . "/\n", "#endif\n"]},
            {name=>"SHUT_RD", type=>"IV", default=>["IV", "0"]},
            {name=>"SHUT_RDWR", type=>"IV", default=>["IV", "2"]},
            {name=>"SHUT_WR", type=>"IV", default=>["IV", "1"]});

print constant_types(); # macro defs
foreach (C_constant ("Socket", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Socket", $types);
__END__
   */

  switch (len) {
  case 5:
    /* Names all of length 5.  */
    /* AF_NS PF_NS */
    /* Offset 0 gives the best switch position.  */
    switch (name[0]) {
    case 'A':
      if (memEQ(name, "AF_NS", 5)) {
      /*               ^          */
#ifdef AF_NS
        *iv_return = AF_NS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "PF_NS", 5)) {
      /*               ^          */
#ifdef PF_NS
        *iv_return = PF_NS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return, sv_return);
    break;
  case 7:
    return constant_7 (name, iv_return, sv_return);
    break;
  case 8:
    return constant_8 (name, iv_return, sv_return);
    break;
  case 9:
    return constant_9 (name, iv_return, sv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return, sv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return, sv_return);
    break;
  case 12:
    return constant_12 (name, iv_return, sv_return);
    break;
  case 13:
    return constant_13 (name, iv_return, sv_return);
    break;
  case 14:
    /* Names all of length 14.  */
    /* SOCK_SEQPACKET SO_USELOOPBACK */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'O':
      if (memEQ(name, "SO_USELOOPBACK", 14)) {
      /*                       ^            */
#ifdef SO_USELOOPBACK
        *iv_return = SO_USELOOPBACK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "SOCK_SEQPACKET", 14)) {
      /*                       ^            */
#ifdef SOCK_SEQPACKET
        *iv_return = SOCK_SEQPACKET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* INADDR_LOOPBACK SCM_CREDENTIALS */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'C':
      if (memEQ(name, "SCM_CREDENTIALS", 15)) {
      /*                   ^                 */
#ifdef SCM_CREDENTIALS
        *iv_return = SCM_CREDENTIALS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'D':
      if (memEQ(name, "INADDR_LOOPBACK", 15)) {
      /*                   ^                 */
#ifdef INADDR_LOOPBACK
        {
struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_LOOPBACK);
          *sv_return =  sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ));
          return PERL_constant_ISSV;
        }
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 16:
    if (memEQ(name, "INADDR_BROADCAST", 16)) {
#ifdef INADDR_BROADCAST
      {
struct in_addr ip_address; ip_address.s_addr = htonl(INADDR_BROADCAST);
        *sv_return =  sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address ));
        return PERL_constant_ISSV;
      }
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}


MODULE = Socket		PACKAGE = Socket

void
constant(sv)
    PREINIT:
	dXSTARG;
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
        /* Change this to constant(s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(aTHX_ s, len, &iv, &sv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid Socket macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined Socket macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
        case PERL_constant_ISSV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break;
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Socket macro %s, used",
               type, s));
          PUSHs(sv);
        }

void
inet_aton(host)
	char *	host
	CODE:
	{
	struct in_addr ip_address;
	struct hostent * phe;
	int ok = inet_aton(host, &ip_address);

	if (!ok && (phe = gethostbyname(host))) {
		Copy( phe->h_addr, &ip_address, phe->h_length, char );
		ok = 1;
	}

	ST(0) = sv_newmortal();
	if (ok) {
		sv_setpvn( ST(0), (char *)&ip_address, sizeof ip_address );
	}
	}

void
inet_ntoa(ip_address_sv)
	SV *	ip_address_sv
	CODE:
	{
	STRLEN addrlen;
	struct in_addr addr;
	char * addr_str;
	char * ip_address = SvPV(ip_address_sv,addrlen);
	if (addrlen != sizeof(addr)) {
	    croak("Bad arg length for %s, length is %d, should be %d",
			"Socket::inet_ntoa",
			addrlen, sizeof(addr));
	}

	Copy( ip_address, &addr, sizeof addr, char );
	addr_str = inet_ntoa(addr);

	ST(0) = sv_2mortal(newSVpvn(addr_str, strlen(addr_str)));
	}

void
pack_sockaddr_un(pathname)
	char *	pathname
	CODE:
	{
#ifdef I_SYS_UN
	struct sockaddr_un sun_ad; /* fear using sun */
	STRLEN len;

	Zero( &sun_ad, sizeof sun_ad, char );
	sun_ad.sun_family = AF_UNIX;
	len = strlen(pathname);
	if (len > sizeof(sun_ad.sun_path))
	    len = sizeof(sun_ad.sun_path);
#  ifdef OS2	/* Name should start with \socket\ and contain backslashes! */
	{
	    int off;
	    char *s, *e;

	    if (pathname[0] != '/' && pathname[0] != '\\')
		croak("Relative UNIX domain socket name '%s' unsupported", pathname);
	    else if (len < 8 
		     || pathname[7] != '/' && pathname[7] != '\\'
		     || !strnicmp(pathname + 1, "socket", 6))
		off = 7;
	    else
		off = 0;		/* Preserve names starting with \socket\ */
	    Copy( "\\socket", sun_ad.sun_path, off, char);
	    Copy( pathname, sun_ad.sun_path + off, len, char );

	    s = sun_ad.sun_path + off - 1;
	    e = s + len + 1;
	    while (++s < e)
		if (*s = '/')
		    *s = '\\';
	}
#  else	/* !( defined OS2 ) */ 
	Copy( pathname, sun_ad.sun_path, len, char );
#  endif
	ST(0) = sv_2mortal(newSVpvn((char *)&sun_ad, sizeof sun_ad));
#else
	ST(0) = (SV *) not_here("pack_sockaddr_un");
#endif
	
	}

void
unpack_sockaddr_un(sun_sv)
	SV *	sun_sv
	CODE:
	{
#ifdef I_SYS_UN
	struct sockaddr_un addr;
	STRLEN sockaddrlen;
	char * sun_ad = SvPV(sun_sv,sockaddrlen);
	char * e;
#   ifndef __linux__
	/* On Linux sockaddrlen on sockets returned by accept, recvfrom,
	   getpeername and getsockname is not equal to sizeof(addr). */
	if (sockaddrlen != sizeof(addr)) {
	    croak("Bad arg length for %s, length is %d, should be %d",
			"Socket::unpack_sockaddr_un",
			sockaddrlen, sizeof(addr));
	}
#   endif

	Copy( sun_ad, &addr, sizeof addr, char );

	if ( addr.sun_family != AF_UNIX ) {
	    croak("Bad address family for %s, got %d, should be %d",
			"Socket::unpack_sockaddr_un",
			addr.sun_family,
			AF_UNIX);
	}
	e = addr.sun_path;
	while (*e && e < addr.sun_path + sizeof addr.sun_path)
	    ++e;
	ST(0) = sv_2mortal(newSVpvn(addr.sun_path, e - addr.sun_path));
#else
	ST(0) = (SV *) not_here("unpack_sockaddr_un");
#endif
	}

void
pack_sockaddr_in(port,ip_address)
	unsigned short	port
	char *	ip_address
	CODE:
	{
	struct sockaddr_in sin;

	Zero( &sin, sizeof sin, char );
	sin.sin_family = AF_INET;
	sin.sin_port = htons(port);
	Copy( ip_address, &sin.sin_addr, sizeof sin.sin_addr, char );

	ST(0) = sv_2mortal(newSVpvn((char *)&sin, sizeof sin));
	}

void
unpack_sockaddr_in(sin_sv)
	SV *	sin_sv
	PPCODE:
	{
	STRLEN sockaddrlen;
	struct sockaddr_in addr;
	unsigned short	port;
	struct in_addr	ip_address;
	char *	sin = SvPV(sin_sv,sockaddrlen);
	if (sockaddrlen != sizeof(addr)) {
	    croak("Bad arg length for %s, length is %d, should be %d",
			"Socket::unpack_sockaddr_in",
			sockaddrlen, sizeof(addr));
	}
	Copy( sin, &addr,sizeof addr, char );
	if ( addr.sin_family != AF_INET ) {
	    croak("Bad address family for %s, got %d, should be %d",
			"Socket::unpack_sockaddr_in",
			addr.sin_family,
			AF_INET);
	} 
	port = ntohs(addr.sin_port);
	ip_address = addr.sin_addr;

	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSViv((IV) port)));
	PUSHs(sv_2mortal(newSVpvn((char *)&ip_address,sizeof ip_address)));
	}
