#include "EXTERN.h"
#include "perl.h"

void
init_thread_intern(struct thread *thr)
{
#ifdef USE_THREADS
    static int key_allocated = 0;
    DuplicateHandle(GetCurrentProcess(),
		    GetCurrentThread(),
		    GetCurrentProcess(),
		    &thr->self,
		    0,
		    FALSE,
		    DUPLICATE_SAME_ACCESS);
    if (!key_allocated) {
	if ((thr_key = TlsAlloc()) == TLS_OUT_OF_INDEXES)
	    croak("panic: TlsAlloc");
	key_allocated = 1;
    }
    if (TlsSetValue(thr_key, (LPVOID) thr) != TRUE)
	croak("panic: TlsSetValue");
#endif
}

#ifdef USE_THREADS
int
Perl_thread_create(struct thread *thr, thread_func_t *fn)
{
    DWORD junk;

    MUTEX_LOCK(&thr->mutex);
    thr->self = CreateThread(NULL, 0, fn, (void*)thr, 0, &junk);
    MUTEX_UNLOCK(&thr->mutex);
    return thr->self ? 0 : -1;
}
#endif
