/*  sockadapt.h
 *
 *  Authors: Charles Bailey  bailey@genetics.upenn.edu
 *           David Denholm  denholm@conmat.phys.soton.ac.uk
 *  Last Revised: 05-Oct-1994
 *
 *  This file should include any other header files and procide any
 *  declarations, typedefs, and prototypes needed by perl for TCP/IP
 *  operations.
 *
 *  This version is set up for perl5 with socketshr 0.9A TCP/IP support.
 */

#include <socketshr.h>

/* we may not have socket.h etc, so lets just do these here  - div */
/* built up from a variety of sources */
/* no harm doing this for all .c files - needed only by pp_sys.c */

struct hostent {
	char *h_name;
	char *h_aliases;
	int h_addrtype;
	int h_length;
	char **h_addr_list;
};
#define h_addr h_addr_list[0]

struct sockaddr_in {
	short sin_family;
	unsigned short sin_port;
	unsigned long sin_addr;
	char sin_zero[8];
};

struct netent {
	char *n_name;
	char **n_aliases;
	int n_addrtype;
	long n_net;
};

struct  servent {
        char    *s_name;        /* official service name */
        char    **s_aliases;    /* alias list */
        int     s_port;         /* port # */
        char    *s_proto;       /* protocol to use */
};

struct  protoent {
        char    *p_name;        /* official protocol name */
        char    **p_aliases;    /* alias list */
        int     p_proto;        /* protocol # */
};
