#include "EXTERN.h"
#include "perl.h"
#include "win32/win32thread.h"

void
init_thread_intern(struct thread *thr)
{
    DuplicateHandle(GetCurrentProcess(),
		    GetCurrentThread(),
		    GetCurrentProcess(),
		    &self,
		    0,
		    FALSE,
		    DUPLICATE_SAME_ACCESS);
    if ((thr_key = TlsAlloc()) == TLS_OUT_OF_INDEXES)
	croak("panic: TlsAlloc");
    if (TlsSetValue(thr_key, (LPVOID) thr) != TRUE)
	croak("panic: TlsSetValue");
}

int
thread_create(struct thread *thr, THREAD_RET_TYPE (*fn)(void *))
{
    DWORD junk;

    MUTEX_LOCK(&thr->mutex);
    self = CreateThread(NULL, 0, fn, (void*)thr, 0, &junk);
    MUTEX_UNLOCK(&thr->mutex);
    return self ? 0 : -1;
}
