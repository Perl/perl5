#include "EXTERN.h"
#include "perl.h"

#ifdef USE_DECLSPEC_THREAD
__declspec(thread) struct perl_thread *Perl_current_thread = NULL;
#endif

void
Perl_setTHR(struct perl_thread *t)
{
#ifdef USE_THREADS
#ifdef USE_DECLSPEC_THREAD
 Perl_current_thread = t;
#else
 TlsSetValue(thr_key,t);
#endif
#endif
}

struct perl_thread *
Perl_getTHR(void)
{
#ifdef USE_THREADS
#ifdef USE_DECLSPEC_THREAD
 return Perl_current_thread;
#else
 return (struct perl_thread *) TlsGetValue(thr_key);
#endif
#else
 return NULL;
#endif
}

void
Perl_alloc_thread_key(void)
{
#ifdef USE_THREADS
    static int key_allocated = 0;
    if (!key_allocated) {
	if ((thr_key = TlsAlloc()) == TLS_OUT_OF_INDEXES)
	    croak("panic: TlsAlloc");
	key_allocated = 1;
    }
#endif
}

void
Perl_init_thread_intern(struct perl_thread *athr)
{
#ifdef USE_THREADS
#ifndef USE_DECLSPEC_THREAD

 /* 
  * Initialize port-specific per-thread data in thr->i
  * as only things we have there are just static areas for
  * return values we don't _need_ to do anything but 
  * this is good practice:
  */
 memset(&athr->i,0,sizeof(athr->i));

#endif
#endif
}

void
Perl_set_thread_self(struct perl_thread *thr)
{
#ifdef USE_THREADS
    /* Set thr->self.  GetCurrentThread() retrurns a pseudo handle, need
       this to convert it into a handle another thread can use.
     */
    DuplicateHandle(GetCurrentProcess(),
		    GetCurrentThread(),
		    GetCurrentProcess(),
		    &thr->self,
		    0,
		    FALSE,
		    DUPLICATE_SAME_ACCESS);
#endif
}

#ifdef USE_THREADS
int
Perl_thread_create(struct perl_thread *thr, thread_func_t *fn)
{
    DWORD junk;

    MUTEX_LOCK(&thr->mutex);
    DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			  "%p: create OS thread\n", thr));
    thr->self = CreateThread(NULL, 0, fn, (void*)thr, 0, &junk);
    DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			  "%p: OS thread = %p, id=%ld\n", thr, thr->self, junk));
    MUTEX_UNLOCK(&thr->mutex);
    return thr->self ? 0 : -1;
}
#endif

