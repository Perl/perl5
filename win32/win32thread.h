#ifndef _WIN32THREAD_H
#define _WIN32THREAD_H
typedef struct win32_cond { LONG waiters; HANDLE sem; } perl_cond;
typedef DWORD perl_key;
typedef HANDLE perl_os_thread;

#ifndef DONT_USE_CRITICAL_SECTION

/* Critical Sections used instead of mutexes: lightweight,
 * but can't be communicated to child processes, and can't get
 * HANDLE to it for use elsewhere.
 */
typedef CRITICAL_SECTION perl_mutex;
#define MUTEX_INIT(m) InitializeCriticalSection(m)
#define MUTEX_LOCK(m) EnterCriticalSection(m)
#define MUTEX_UNLOCK(m) LeaveCriticalSection(m)
#define MUTEX_DESTROY(m) DeleteCriticalSection(m)

#else

typedef HANDLE perl_mutex;
#define MUTEX_INIT(m) \
    STMT_START {						\
	if ((*(m) = CreateMutex(NULL,FALSE,NULL)) == NULL)	\
	    croak("panic: MUTEX_INIT");				\
    } STMT_END
#define MUTEX_LOCK(m) \
    STMT_START {						\
	if (WaitForSingleObject(*(m),INFINITE) == WAIT_FAILED)	\
	    croak("panic: MUTEX_LOCK");				\
    } STMT_END
#define MUTEX_UNLOCK(m) \
    STMT_START {						\
	if (ReleaseMutex(*(m)) == 0)				\
	    croak("panic: MUTEX_UNLOCK");			\
    } STMT_END
#define MUTEX_DESTROY(m) \
    STMT_START {						\
	if (CloseHandle(*(m)) == 0)				\
	    croak("panic: MUTEX_DESTROY");			\
    } STMT_END

#endif

/* These macros assume that the mutex associated with the condition
 * will always be held before COND_{SIGNAL,BROADCAST,WAIT,DESTROY},
 * so there's no separate mutex protecting access to (c)->waiters
 */
#define COND_INIT(c) \
    STMT_START {						\
	(c)->waiters = 0;					\
	(c)->sem = CreateSemaphore(NULL,0,LONG_MAX,NULL);	\
	if ((c)->sem == NULL)					\
	    croak("panic: COND_INIT (%ld)",GetLastError());	\
    } STMT_END

#define COND_SIGNAL(c) \
    STMT_START {						\
	if ((c)->waiters > 0 &&					\
	    ReleaseSemaphore((c)->sem,1,NULL) == 0)		\
	    croak("panic: COND_SIGNAL (%ld)",GetLastError());	\
    } STMT_END

#define COND_BROADCAST(c) \
    STMT_START {						\
	if ((c)->waiters > 0 &&					\
	    ReleaseSemaphore((c)->sem,(c)->waiters,NULL) == 0)	\
	    croak("panic: COND_BROADCAST (%ld)",GetLastError());\
    } STMT_END

#define COND_WAIT(c, m) \
    STMT_START {						\
	(c)->waiters++;						\
	MUTEX_UNLOCK(m);					\
	/* Note that there's no race here, since a		\
	 * COND_BROADCAST() on another thread will have seen the\
	 * right number of waiters (i.e. including this one) */	\
	if (WaitForSingleObject((c)->sem,INFINITE)==WAIT_FAILED)\
	    croak("panic: COND_WAIT (%ld)",GetLastError());	\
	/* XXX there may be an inconsequential race here */	\
	MUTEX_LOCK(m);						\
	(c)->waiters--;						\
    } STMT_END

#define COND_DESTROY(c) \
    STMT_START {						\
	(c)->waiters = 0;					\
	if (CloseHandle((c)->sem) == 0)				\
	    croak("panic: COND_DESTROY (%ld)",GetLastError());	\
    } STMT_END

#define DETACH(t) \
    STMT_START {						\
	if (CloseHandle((t)->self) == 0) {			\
	    MUTEX_UNLOCK(&(t)->mutex);				\
	    croak("panic: DETACH");				\
	}							\
    } STMT_END

#define THR ((struct perl_thread *) TlsGetValue(thr_key))
#define THREAD_CREATE(t, f)	Perl_thread_create(t, f)
#define THREAD_POST_CREATE(t)	NOOP
#define THREAD_RET_TYPE		DWORD WINAPI
#define THREAD_RET_CAST(p)	((DWORD)(p))

typedef THREAD_RET_TYPE thread_func_t(void *);


START_EXTERN_C

#if defined(PERLDLL) && (!defined(__BORLANDC__) || defined(_DLL))
extern __declspec(thread) struct thread *Perl_current_thread;
#define SET_THR(t)   		(Perl_current_thread = t)
#define THR			Perl_current_thread
#else
#define THR			Perl_getTHR()
#define SET_THR(t)		Perl_setTHR(t)
#endif

void Perl_alloc_thread_key _((void));
int Perl_thread_create _((struct perl_thread *thr, thread_func_t *fn));
void Perl_set_thread_self _((struct perl_thread *thr));
struct perl_thread *Perl_getTHR _((void));
void Perl_setTHR _((struct perl_thread *t));
END_EXTERN_C

#define INIT_THREADS NOOP
#define ALLOC_THREAD_KEY NOOP
#define SET_THREAD_SELF(thr) Perl_set_thread_self(thr)

#define JOIN(t, avp)							\
    STMT_START {							\
	if ((WaitForSingleObject((t)->self,INFINITE) == WAIT_FAILED)	\
	     || (GetExitCodeThread((t)->self,(LPDWORD)(avp)) == 0))	\
	    croak("panic: JOIN");					\
    } STMT_END

#define YIELD			Sleep(0)

#endif /* _WIN32THREAD_H */

