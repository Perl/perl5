
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>

#ifdef WIN32
#include <windows.h>
#include <win32thread.h>
#else
#include <pthread.h>
#include <thread.h>
#endif

typedef struct {
  PerlInterpreter *interp;    /* The threads interpreter */
  I32 tid;              /* Our thread */
  perl_mutex mutex; 		/* our mutex */
  I32 count;			/* how many threads have a reference to us */
  signed char detached;		/* are we detached ? */
  SV* init_function;
  SV* params;
#ifdef WIN32
  DWORD	thr;
  HANDLE handle;
#else
  pthread_t thr;
#endif
} ithread;



static perl_mutex create_mutex;  /* protects the creation of threads ??? */



I32 tid_counter = 1;
shared_sv* threads;






/* internal functions */
#ifdef WIN32
THREAD_RET_TYPE Perl_thread_run(LPVOID arg);
#else
void Perl_thread_run(ithread* thread);
#endif
void Perl_thread_destruct(ithread* thread);

/* Perl mapped functions to iThread:: */
SV* Perl_thread_create(char* class, SV* function_to_call, SV* params);
I32 Perl_thread_tid (SV* obj);
void Perl_thread_join(SV* obj);
void Perl_thread_detach(SV* obj);
SV* Perl_thread_self (char* class);









