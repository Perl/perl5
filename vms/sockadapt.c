/*  sockadapt.c
 *
 *  Author: Charles Bailey  bailey@genetics.upenn.edu
 *  Last Revised: 05-Oct-1994
 *
 *  This file should contain stubs for any of the TCP/IP functions perl5
 *  requires which are not supported by your TCP/IP stack.  These stubs
 *  can attempt to emulate the routine in question, or can just return
 *  an error status or cause perl to die.
 *
 *  This version is set up for perl5 with socketshr 0.9A TCP/IP support.
 */

#include "sockadapt.h"

#ifdef __STDC__
#define STRINGIFY(a) #a	 /* config-skip */
#else
#define STRINGIFY(a) "a"	 /* config-skip */
#endif

#define FATALSTUB(func) \
  void func() {\
    croak("Function %s not implemented in this version of perl",\
    STRINGIFY(func));\
  }

FATALSTUB(endhostent);
FATALSTUB(endnetent);
FATALSTUB(endprotoent);
FATALSTUB(endservent);
FATALSTUB(gethostent);
FATALSTUB(getnetbyaddr);
FATALSTUB(getnetbyname);
FATALSTUB(getnetent);
FATALSTUB(getprotobyname);
FATALSTUB(getprotobynumber);
FATALSTUB(getprotoent);
FATALSTUB(getservent);
FATALSTUB(sethostent);
FATALSTUB(setnetent);
FATALSTUB(setprotoent);
FATALSTUB(setservent);
