#include "EXTERN.h"
#include "perl.h"

__declspec(thread) struct thread *Perl_current_thread = NULL;

void
Perl_setTHR(struct thread *t)
{
 Perl_current_thread = t;
}

struct thread *
Perl_getTHR(void)
{
 return Perl_current_thread;
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
