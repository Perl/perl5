/*
 *    Copyright (c) 1999 Olaf Flebbe o.flebbe@gmx.de
 *    
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/unistd.h>

char *environ = NULL;
void
Perl_epoc_init(int *argcp, char ***argvp) {
  int i;
  int truecount=0;
  char **lastcp = (*argvp);
  char *ptr;
  for (i=0; i< *argcp; i++) {
    if ((*argvp)[i]) {
      if (*((*argvp)[i]) == '<') {
	if (strlen((*argvp)[i]) > 1) {
	  ptr =((*argvp)[i])+1;
	} else {
	  i++;
	  ptr = ((*argvp)[i]);
	}
	freopen(  ptr, "r", stdin);
      } else if (*((*argvp)[i]) == '>') {
	if (strlen((*argvp)[i]) > 1) {
	  ptr =((*argvp)[i])+1;
	} else {
	  i++;
	  ptr = ((*argvp)[i]);
	}
	freopen(  ptr, "w", stdout);
      } else if ((*((*argvp)[i]) == '2') && (*(((*argvp)[i])+1) == '>')) {
	if (strcmp( (*argvp)[i], "2>&1") == 0) {
	  dup2( fileno( stdout), fileno( stderr));
	} else {
          if (strlen((*argvp)[i]) > 2) {
            ptr =((*argvp)[i])+2;
	  } else {
	    i++;
	    ptr = ((*argvp)[i]);
	  }
	  freopen(  ptr, "w", stderr);
	}
      } else {
	*lastcp++ = (*argvp)[i];
	truecount++;
      }
    } 
  }
  *argcp=truecount;
      

}

#ifdef __MARM__
/* Symbian forgot to include __fixunsdfi into the MARM euser.lib */
/* This is from libgcc2.c , gcc-2.7.2.3                          */

typedef unsigned int UQItype	__attribute__ ((mode (QI)));
typedef 	 int SItype	__attribute__ ((mode (SI)));
typedef unsigned int USItype	__attribute__ ((mode (SI)));
typedef		 int DItype	__attribute__ ((mode (DI)));
typedef unsigned int UDItype	__attribute__ ((mode (DI)));

typedef 	float SFtype	__attribute__ ((mode (SF)));
typedef		float DFtype	__attribute__ ((mode (DF)));



extern DItype __fixunssfdi (SFtype a);
extern DItype __fixunsdfdi (DFtype a);


USItype
__fixunsdfsi (a)
     DFtype a;
{
  if (a >= - (DFtype) (- 2147483647L  -1) )
    return (SItype) (a + (- 2147483647L  -1) ) - (- 2147483647L  -1) ;
  return (SItype) a;
}

#endif
