/* Epoc helper Routines */

#include <stdlib.h>

int getgid() {return 0;}
int getegid() {return 0;}
int geteuid() {return 0;}
int getuid() {return 0;}
int setgid() {return -1;}
int setuid() {return -1;}


char *environ;

int Perl_my_popen( int a, int b) {
	 return 0;
}
int Perl_my_pclose( int a) {
	 return 0;
}

kill() {}
signal() {}

void execv() {}
void execvp() {}


void do_spawn() {}
void do_aspawn() {}
void Perl_do_exec() {}

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
