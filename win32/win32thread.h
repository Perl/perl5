/*typedef CRITICAL_SECTION perl_mutex;*/
typedef HANDLE perl_mutex;
typedef HANDLE perl_cond;
typedef DWORD perl_key;
typedef HANDLE perl_thread;

/* XXX Critical Sections used instead of mutexes: lightweight,
 * but can't be communicated to child processes, and can't get
 * HANDLE to it for use elsewhere
 */
/*
#define MUTEX_INIT(m) InitializeCriticalSection(m)
#define MUTEX_LOCK(m) EnterCriticalSection(m)
#define MUTEX_UNLOCK(m) LeaveCriticalSection(m)
#define MUTEX_DESTROY(m) DeleteCriticalSection(m)
*/

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

#define COND_INIT(c) \
    STMT_START {						\
	if ((*(c) = CreateEvent(NULL,TRUE,FALSE,NULL)) == NULL)	\
	    croak("panic: COND_INIT");				\
    } STMT_END
#define COND_SIGNAL(c) \
    STMT_START {						\
	if (PulseEvent(*(c)) == 0)				\
	    croak("panic: COND_SIGNAL (%ld)",GetLastError());	\
    } STMT_END
#define COND_BROADCAST(c) \
    STMT_START {						\
	if (PulseEvent(*(c)) == 0)				\
	    croak("panic: COND_BROADCAST");			\
    } STMT_END
/* #define COND_WAIT(c, m) \
    STMT_START {						\
	if (WaitForSingleObject(*(c),INFINITE) == WAIT_FAILED)	\
	    croak("panic: COND_WAIT");				\
    } STMT_END
*/
#define COND_WAIT(c, m) \
    STMT_START {						\
	if (SignalObjectAndWait(*(m),*(c),INFINITE,FALSE) == WAIT_FAILED)\
	    croak("panic: COND_WAIT");				\
	else							\
	    MUTEX_LOCK(m);					\
    } STMT_END
#define COND_DESTROY(c) \
    STMT_START {						\
	if (CloseHandle(*(c)) == 0)				\
	    croak("panic: COND_DESTROY");			\
    } STMT_END

#define DETACH(t) \
    STMT_START {						\
	if (CloseHandle((t)->self) == 0) {			\
	    MUTEX_UNLOCK(&(t)->mutex);				\
	    croak("panic: DETACH");				\
	}							\
    } STMT_END

#define THR ((struct thread *) TlsGetValue(thr_key))

#define HAVE_THREAD_INTERN

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

#define THREAD_CREATE(t, f)	thread_create(t, f)
#define THREAD_POST_CREATE(t)	NOOP
#define THREAD_RET_TYPE		DWORD WINAPI
#define THREAD_RET_CAST(p)	((DWORD)(p))
#define YIELD			Sleep(0)
