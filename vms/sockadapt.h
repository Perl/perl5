/*  sockadapt.h
 *
 *  Authors: Charles Bailey  bailey@genetics.upenn.edu
 *           David Denholm  denholm@conmat.phys.soton.ac.uk
 *  Last Revised: 24-Feb-1995
 *
 *  This file should include any other header files and procide any
 *  declarations, typedefs, and prototypes needed by perl for TCP/IP
 *  operations.
 *
 *  This version is set up for perl5 with socketshr 0.9D TCP/IP support.
 */

#include <socketshr.h>

/* we may not have netdb.h etc, so lets just do this here  - div */
/* no harm doing this for all .c files - needed only by pp_sys.c */

struct	hostent {
    char	*h_name;	/* official name of host */
    char	**h_aliases;	/* alias list */
    int	h_addrtype;	/* host address type */
    int	h_length;	/* length of address */
    char	**h_addr_list;	/* address */
};
#ifdef h_addr
#   undef h_addr
#endif
#define h_addr h_addr_list[0]

struct	protoent {
    char	*p_name;	/* official protocol name */
    char	**p_aliases;	/* alias list */
    int	p_proto;	/* protocol # */
};

struct	servent {
    char	*s_name;	/* official service name */
    char	**s_aliases;	/* alias list */
    int	s_port;		/* port # */
    char	*s_proto;	/* protocol to use */
};

struct	in_addr {
    unsigned long s_addr;
};

struct	sockaddr {
    unsigned short	sa_family;		/* address family */
    char	sa_data[14];		/* up to 14 bytes of direct address */
};

struct timeval {
    long tv_sec;
    long tv_usec;
};

struct netent {
	char *n_name;
	char **n_aliases;
	int n_addrtype;
	long n_net;
};
