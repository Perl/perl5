#include "EXTERN.h"
#include "perl.h"

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
init_thread_intern(struct thread *thr)
{
#ifdef USE_THREADS
    /* GetCurrentThread() retrurns a pseudo handle, need
       this to convert it into a handle another thread can use
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
Perl_thread_create(struct thread *thr, thread_func_t *fn)
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
