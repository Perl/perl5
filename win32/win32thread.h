#ifndef _WIN32THREAD_H
#define _WIN32THREAD_H
typedef struct win32_cond { LONG waiters; HANDLE sem; } perl_cond;
typedef DWORD perl_key;
typedef HANDLE perl_thread;

/* XXX Critical Sections used instead of mutexes: lightweight,
 * but can't be communicated to child processes, and can't get
 * HANDLE to it for use elsewhere
 */

#ifndef DONT_USE_CRITICAL_SECTION
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
    STMT_START {                                                \
        (c)->waiters = 0;                                       \
        (c)->sem = CreateSemaphore(NULL,0,LONG_MAX,NULL);       \
        if ((c)->sem == NULL)                                   \
            croak("panic: COND_INIT (%ld)",GetLastError());     \
    } STMT_END

#define COND_SIGNAL(c) \
    STMT_START {                                                \
        if (ReleaseSemaphore((c)->sem,1,NULL) == 0)             \
            croak("panic: COND_SIGNAL (%ld)",GetLastError());   \
    } STMT_END

#define COND_BROADCAST(c) \
    STMT_START {                                                \
        if ((c)->waiters > 0 &&                                 \
            ReleaseSemaphore((c)->sem,(c)->waiters,NULL) == 0)  \
            croak("panic: COND_BROADCAST (%ld)",GetLastError());\
    } STMT_END

#define COND_WAIT(c, m) \
    STMT_START {                                                \
        (c)->waiters++;                                         \
        MUTEX_UNLOCK(m);                                        \
        /* Note that there's no race here, since a              \
         * COND_BROADCAST() on another thread will have seen the\
         * right number of waiters (i.e. including this one) */ \
        if (WaitForSingleObject((c)->sem,INFINITE)==WAIT_FAILED)\
            croak("panic: COND_WAIT (%ld)",GetLastError());     \
        MUTEX_LOCK(m);                                          \
        (c)->waiters--;                                         \
    } STMT_END

#define COND_DESTROY(c) \
    STMT_START {                                                \
        (c)->waiters = 0;                                       \
        if (CloseHandle((c)->sem) == 0)                         \
            croak("panic: COND_DESTROY (%ld)",GetLastError());  \
    } STMT_END

#define DETACH(t) \
    STMT_START {						\
	if (CloseHandle((t)->self) == 0) {			\
	    MUTEX_UNLOCK(&(t)->mutex);				\
	    croak("panic: DETACH");				\
	}							\
    } STMT_END

#define THR ((struct thread *) TlsGetValue(thr_key))
#define THREAD_CREATE(t, f)	Perl_thread_create(t, f)
#define THREAD_POST_CREATE(t)	NOOP
#define THREAD_RET_TYPE		DWORD WINAPI
#define THREAD_RET_CAST(p)	((DWORD)(p))

typedef THREAD_RET_TYPE thread_func_t(void *);

START_EXTERN_C
void Perl_alloc_thread_key _((void));
int Perl_thread_create _((struct thread *thr, thread_func_t *fn));
void Perl_init_thread_intern _((struct thread *thr));
END_EXTERN_C

#define INIT_THREADS NOOP
#define ALLOC_THREAD_KEY Perl_alloc_thread_key()
#define INIT_THREAD_INTERN(thr) Perl_init_thread_intern(thr)

#define JOIN(t, avp)							\
    STMT_START {							\
	if ((WaitForSingleObject((t)->self,INFINITE) == WAIT_FAILED)	\
             || (GetExitCodeThread((t)->self,(LPDWORD)(avp)) == 0))	\
	    croak("panic: JOIN");					\
    } STMT_END

#define SET_THR(t)					\
    STMT_START {					\
	if (TlsSetValue(thr_key, (void *) (t)) == 0)	\
	    croak("panic: TlsSetValue");		\
    } STMT_END

#define YIELD			Sleep(0)

#endif /* _WIN32THREAD_H */
