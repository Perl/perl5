
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>

#ifdef WIN32
#include <windows.h>
#include <win32thread.h>
#define PERL_THREAD_DETACH(t) 
#define PERL_THREAD_SET_SPECIFIC(k,v) TlsSetValue(k,v)
#define PERL_THREAD_GET_SPECIFIC(k)   TlsGetValue(k)
#define PERL_THREAD_ALLOC_SPECIFIC(k) \
STMT_START {\
  if((k = TlsAlloc()) == TLS_OUT_OF_INDEXES) {\
    PerlIO_printf(PerlIO_stderr(),"panic threads.h: TlsAlloc");\
    exit(1);\
  }\
} STMT_END
#else
#include <pthread.h>
#include <thread.h>

#define PERL_THREAD_SET_SPECIFIC(k,v) pthread_setspecific(k,v)
#define PERL_THREAD_GET_SPECIFIC(k)   pthread_getspecific(k)
#define PERL_THREAD_ALLOC_SPECIFIC(k) STMT_START {\
  if(pthread_key_create(&(k),0)) {\
    PerlIO_printf(PerlIO_stderr(), "panic threads.h: pthread_key_create");\
    exit(1);\
  }\
} STMT_END
#ifdef OLD_PTHREADS_API
#define PERL_THREAD_DETACH(t) pthread_detach(&(t))
#else
#define PERL_THREAD_DETACH(t) pthread_detach((t))
#endif
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

perl_key self_key;




/* internal functions */
#ifdef WIN32
THREAD_RET_TYPE Perl_thread_run(LPVOID arg);
#else
void* Perl_thread_run(void * arg);
#endif
void Perl_thread_destruct(ithread* thread);

/* Perl mapped functions to iThread:: */
SV* Perl_thread_create(char* class, SV* function_to_call, SV* params);
I32 Perl_thread_tid (SV* obj);
void Perl_thread_join(SV* obj);
void Perl_thread_detach(SV* obj);
SV* Perl_thread_self (char* class);









