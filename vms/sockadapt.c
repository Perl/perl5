/*  sockadapt.c
 *
 *  Author: Charles Bailey  bailey@genetics.upenn.edu
 *  Last Revised: 29-Jan-1996
 *
 *  This file should contain stubs for any of the TCP/IP functions perl5
 *  requires which are not supported by your TCP/IP stack.  These stubs
 *  can attempt to emulate the routine in question, or can just return
 *  an error status or cause perl to die.
 *
 *  This version is set up for perl5 with socketshr 0.9D TCP/IP support.
 */

#include "EXTERN.h"
#include "perl.h"
#if defined(__DECC) && defined(__DECC_VER) && (__DECC_VER >= 50200000)
#  define __sockadapt_my_netent_t __struct_netent_ptr32
#  define __sockadapt_my_addr_t   __in_addr_t
#  define __sockadapt_my_name_t   const char *
#else
#  define __sockadapt_my_netent_t struct netent *
#  define __sockadapt_my_addr_t   long
#  define __sockadapt_my_name_t   char *
#endif

__sockadapt_my_netent_t getnetbyaddr( __sockadapt_my_addr_t net, int type) {
  croak("Function \"getnetbyaddr\" not implemented in this version of perl");
  return (struct netent *)NULL; /* Avoid MISSINGRETURN warning, not reached */
}
__sockadapt_my_netent_t getnetbyname( __sockadapt_my_name_t name) {
  croak("Function \"getnetbyname\" not implemented in this version of perl");
  return (struct netent *)NULL; /* Avoid MISSINGRETURN warning, not reached */
}
__sockadapt_my_netent_t getnetent() {
  croak("Function \"getnetent\" not implemented in this version of perl");
  return (struct netent *)NULL; /* Avoid MISSINGRETURN warning, not reached */
}
void setnetent() {
  croak("Function \"setnetent\" not implemented in this version of perl");
}
void endnetent() {
  croak("Function \"endnetent\" not implemented in this version of perl");
}

/* Some TCP/IP implementations seem to return success, when getpeername()
 * is called on a UDP socket, but the port and in_addr are all zeroes.
 */

int my_getpeername(int sock, struct sockaddr *addr, int *addrlen) {
  static char nowhere[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
  int rslt;

  rslt = si_getpeername(sock, addr, addrlen);

  /* Just pass an error back up the line */
  if (rslt) return rslt;

  /* If the call succeeded, make sure we don't have a zeroed port/addr */
  if (addr->sa_family == AF_INET &&
      !memcmp((char *)addr + sizeof(u_short), nowhere,
              sizeof(u_short) + sizeof(struct in_addr))) {
    rslt = -1;
    SETERRNO(ENOTCONN,SS$_CLEARED);
  }
  return rslt;
}
