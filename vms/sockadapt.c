/*  sockadapt.c
 *
 *  Author: Charles Bailey  bailey@genetics.upenn.edu
 *  Last Revised: 17-Mar-1995
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

void endnetent() {
  croak("Function \"endnetent\" not implemented in this version of perl");
}
struct netent *getnetbyaddr( long net, int type) {
  croak("Function \"getnetbyaddr\" not implemented in this version of perl");
  return (struct netent *)NULL; /* Avoid MISSINGRETURN warning, not reached */
}
struct netent *getnetbyname( char *name) {
  croak("Function \"getnetbyname\" not implemented in this version of perl");
  return (struct netent *)NULL; /* Avoid MISSINGRETURN warning, not reached */
}
struct netent *getnetent() {
  croak("Function \"getnetent\" not implemented in this version of perl");
  return (struct netent *)NULL; /* Avoid MISSINGRETURN warning, not reached */
}
void setnetent() {
  croak("Function \"setnetent\" not implemented in this version of perl");
}
