#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#include <windows.h>
#include <win32thread.h>
#define PERL_THREAD_SETSPECIFIC(k,v) TlsSetValue(k,v)
#define PERL_THREAD_GETSPECIFIC(k,v) v = TlsGetValue(k)
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

#define PERL_THREAD_SETSPECIFIC(k,v) pthread_setspecific(k,v)
#ifdef OLD_PTHREADS_API
#define PERL_THREAD_DETACH(t) pthread_detach(&(t))
#define PERL_THREAD_GETSPECIFIC(k,v) pthread_getspecific(k,&v)
#define PERL_THREAD_ALLOC_SPECIFIC(k) STMT_START {\
  if(pthread_keycreate(&(k),0)) {\
    PerlIO_printf(PerlIO_stderr(), "panic threads.h: pthread_key_create");\
    exit(1);\
  }\
} STMT_END
#else
#define PERL_THREAD_DETACH(t) pthread_detach((t))
#define PERL_THREAD_GETSPECIFIC(k,v) v = pthread_getspecific(k)
#define PERL_THREAD_ALLOC_SPECIFIC(k) STMT_START {\
  if(pthread_key_create(&(k),0)) {\
    PerlIO_printf(PerlIO_stderr(), "panic threads.h: pthread_key_create");\
    exit(1);\
  }\
} STMT_END
#endif
#endif

typedef struct ithread_s {
    struct ithread_s *next;	/* next thread in the list */
    struct ithread_s *prev;	/* prev thread in the list */
    PerlInterpreter *interp;	/* The threads interpreter */
    I32 tid;              	/* threads module's thread id */
    perl_mutex mutex; 		/* mutex for updating things in this struct */
    I32 count;			/* how many SVs have a reference to us */
    signed char detached;	/* are we detached ? */
    int gimme;			/* Context of create */
    SV* init_function;          /* Code to run */
    SV* params;                 /* args to pass function */
#ifdef WIN32
	DWORD	thr;            /* OS's idea if thread id */
	HANDLE handle;          /* OS's waitable handle */
#else
  	pthread_t thr;          /* OS's handle for the thread */
#endif
} ithread;

ithread *threads;

/* Macros to supply the aTHX_ in an embed.h like manner */
#define ithread_join(thread)		Perl_ithread_join(aTHX_ thread)
#define ithread_DESTROY(thread)		Perl_ithread_DESTROY(aTHX_ thread)
#define ithread_CLONE(thread)		Perl_ithread_CLONE(aTHX_ thread)
#define ithread_detach(thread)		Perl_ithread_detach(aTHX_ thread)
#define ithread_tid(thread)		((thread)->tid)

static perl_mutex create_mutex;  /* protects the creation of threads ??? */

I32 tid_counter = 0;

perl_key self_key;

/*
 *  Clear up after thread is done with
 */
void
Perl_ithread_destruct (pTHX_ ithread* thread)
{
	MUTEX_LOCK(&thread->mutex);
	if (thread->count != 0) {
		MUTEX_UNLOCK(&thread->mutex);
		return;
	}
	MUTEX_LOCK(&create_mutex);
	/* Remove from circular list of threads */
	if (thread->next == thread) {
	    /* last one should never get here ? */
	    threads = NULL;
        }
	else {
	    thread->next->prev = thread->prev->next;
	    thread->prev->next = thread->next->prev;
	    if (threads == thread) {
		threads = thread->next;
	    }
	}
	MUTEX_UNLOCK(&create_mutex);
	/* Thread is now disowned */
#if 0
        Perl_warn(aTHX_ "destruct %d @ %p by %p",
	          thread->tid,thread->interp,aTHX);
#endif
	if (thread->interp) {
	    dTHXa(thread->interp);
	    PERL_SET_CONTEXT(thread->interp);
	    perl_destruct(thread->interp);
	    perl_free(thread->interp);
	    thread->interp = NULL;
	}
	PERL_SET_CONTEXT(aTHX);
	MUTEX_UNLOCK(&thread->mutex);
}


/* MAGIC (in mg.h sense) hooks */

int
ithread_mg_get(pTHX_ SV *sv, MAGIC *mg)
{
    ithread *thread = (ithread *) mg->mg_ptr;
    SvIVX(sv) = PTR2IV(thread);
    SvIOK_on(sv);
    return 0;
}

int
ithread_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    ithread *thread = (ithread *) mg->mg_ptr;
    MUTEX_LOCK(&thread->mutex);
    thread->count--;
    MUTEX_UNLOCK(&thread->mutex);
    /* This is safe as it re-checks count */
    Perl_ithread_destruct(aTHX_ thread);
    return 0;
}

int
ithread_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    ithread *thread = (ithread *) mg->mg_ptr;
    MUTEX_LOCK(&thread->mutex);
    thread->count++;
    MUTEX_UNLOCK(&thread->mutex);
    return 0;
}

MGVTBL ithread_vtbl = {
 ithread_mg_get,	/* get */
 0,			/* set */
 0,			/* len */
 0,			/* clear */
 ithread_mg_free,	/* free */
 0,			/* copy */
 ithread_mg_dup		/* dup */
};


/*
 *	Starts executing the thread. Needs to clean up memory a tad better.
 *      Passed as the C level function to run in the new thread
 */

#ifdef WIN32
THREAD_RET_TYPE
Perl_ithread_run(LPVOID arg) {
#else
void*
Perl_ithread_run(void * arg) {
#endif
	ithread* thread = (ithread*) arg;
	dTHXa(thread->interp);
	PERL_SET_CONTEXT(thread->interp);
	PERL_THREAD_SETSPECIFIC(self_key,thread);

#if 0
	/* Far from clear messing with ->thr child-side is a good idea */
	MUTEX_LOCK(&thread->mutex);
#ifdef WIN32
	thread->thr = GetCurrentThreadId();
#else
	thread->thr = pthread_self();
#endif
 	MUTEX_UNLOCK(&thread->mutex);
#endif

	PL_perl_destruct_level = 2;

	{
		AV* params = (AV*) SvRV(thread->params);
		I32 len = av_len(params)+1;
		int i;
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		for(i = 0; i < len; i++) {
		    XPUSHs(av_shift(params));
		}
		PUTBACK;
		len = call_sv(thread->init_function, thread->gimme|G_EVAL);
		SPAGAIN;
		for (i=len-1; i >= 0; i--) {
		    SV *sv = POPs;
		    av_store(params, i, SvREFCNT_inc(sv));
		}
		PUTBACK;
		if (SvTRUE(ERRSV)) {
		    Perl_warn(aTHX_ "Died:%_",ERRSV);
		}
		FREETMPS;
		LEAVE;
		SvREFCNT_dec(thread->init_function);
	}

	PerlIO_flush((PerlIO*)NULL);
	MUTEX_LOCK(&thread->mutex);
	if (thread->detached & 1) {
		MUTEX_UNLOCK(&thread->mutex);
		SvREFCNT_dec(thread->params);
		thread->params = Nullsv;
		Perl_ithread_destruct(aTHX_ thread);
	} else {
		thread->detached |= 4;
	  	MUTEX_UNLOCK(&thread->mutex);
   	}
#ifdef WIN32
	return (DWORD)0;
#else
	return 0;
#endif
}

SV *
ithread_to_SV(pTHX_ SV *obj, ithread *thread, char *classname, bool inc)
{
    SV *sv;
    MAGIC *mg;
    if (inc) {
	MUTEX_LOCK(&thread->mutex);
	thread->count++;
	MUTEX_UNLOCK(&thread->mutex);
    }
    if (!obj)
     obj = newSV(0);
    sv = newSVrv(obj,classname);
    sv_setiv(sv,PTR2IV(thread));
    mg = sv_magicext(sv,Nullsv,PERL_MAGIC_shared_scalar,&ithread_vtbl,(char *)thread,0);
    mg->mg_flags |= MGf_DUP;
    SvREADONLY_on(sv);
    return obj;
}

ithread *
SV_to_ithread(pTHX_ SV *sv)
{
    ithread *thread;
    if (SvROK(sv))
     {
      thread = INT2PTR(ithread*, SvIV(SvRV(sv)));
     }
    else
     {
      PERL_THREAD_GETSPECIFIC(self_key,thread);
     }
    return thread;
}

/*
 * iThread->create(); ( aka iThread->new() )
 * Called in context of parent thread
 */

SV *
Perl_ithread_create(pTHX_ SV *obj, char* classname, SV* init_function, SV* params)
{
	ithread*	thread;
	CLONE_PARAMS	clone_param;

	MUTEX_LOCK(&create_mutex);
	thread = PerlMemShared_malloc(sizeof(ithread));
	Zero(thread,1,ithread);
	thread->next = threads;
	thread->prev = threads->prev;
	thread->prev->next = thread;
	/* Set count to 1 immediately in case thread exits before
	 * we return to caller !
	 */
	thread->count = 1;
	MUTEX_INIT(&thread->mutex);
	thread->tid = tid_counter++;
	thread->gimme = GIMME_V;
	thread->detached = (thread->gimme == G_VOID) ? 1 : 0;

	/* "Clone" our interpreter into the thread's interpreter
	 * This gives thread access to "static data" and code.
	 */

	PerlIO_flush((PerlIO*)NULL);

#ifdef WIN32
	thread->interp = perl_clone(aTHX, CLONEf_KEEP_PTR_TABLE | CLONEf_CLONE_HOST);
#else
	thread->interp = perl_clone(aTHX, CLONEf_KEEP_PTR_TABLE);
#endif
	/* perl_clone leaves us in new interpreter's context.
	   As it is tricky to spot implcit aTHX create a new scope
	   with aTHX matching the context for the duration of
	   our work for new interpreter.
	 */
	{
	    dTHXa(thread->interp);

            clone_param.flags = 0;
	    thread->init_function = sv_dup(init_function, &clone_param);
	    if (SvREFCNT(thread->init_function) == 0) {
		SvREFCNT_inc(thread->init_function);
	    }

	    thread->params = sv_dup(params, &clone_param);
	    SvREFCNT_inc(thread->params);
	    SvTEMP_off(thread->init_function);
	    ptr_table_free(PL_ptr_table);
	    PL_ptr_table = NULL;
	}

	PERL_SET_CONTEXT(aTHX);

	/* Start the thread */

#ifdef WIN32

	thread->handle = CreateThread(NULL, 0, Perl_ithread_run,
			(LPVOID)thread, 0, &thread->thr);

#else
	{
	  static pthread_attr_t attr;
	  static int attr_inited = 0;
	  sigset_t fullmask, oldmask;
	  static int attr_joinable = PTHREAD_CREATE_JOINABLE;
	  if (!attr_inited) {
	    attr_inited = 1;
	    pthread_attr_init(&attr);
	  }
#  ifdef PTHREAD_ATTR_SETDETACHSTATE
            PTHREAD_ATTR_SETDETACHSTATE(&attr, attr_joinable);
#  endif
#  ifdef THREAD_CREATE_NEEDS_STACK
	    if(pthread_attr_setstacksize(&attr, THREAD_CREATE_NEEDS_STACK))
	      croak("panic: pthread_attr_setstacksize failed");
#  endif

#ifdef OLD_PTHREADS_API
	  pthread_create( &thread->thr, attr, Perl_ithread_run, (void *)thread);
#else
	  pthread_create( &thread->thr, &attr, Perl_ithread_run, (void *)thread);
#endif
	}
#endif
	MUTEX_UNLOCK(&create_mutex);
	return ithread_to_SV(aTHX_ obj, thread, classname, FALSE);
}

SV*
Perl_ithread_self (pTHX_ SV *obj, char* Class)
{
    ithread *thread;
    PERL_THREAD_GETSPECIFIC(self_key,thread);
    return ithread_to_SV(aTHX_ obj, thread, Class, TRUE);
}

/*
 * joins the thread this code needs to take the returnvalue from the
 * call_sv and send it back
 */

void
Perl_ithread_CLONE(pTHX_ SV *obj)
{
 if (SvROK(obj))
  {
   ithread *thread = SV_to_ithread(aTHX_ obj);
  }
 else
  {
   Perl_warn(aTHX_ "CLONE %_",obj);
  }
}

void
Perl_ithread_join(pTHX_ SV *obj)
{
    ithread *thread = SV_to_ithread(aTHX_ obj);
    MUTEX_LOCK(&thread->mutex);
    if (thread->detached & 1) {
	MUTEX_UNLOCK(&thread->mutex);
	Perl_croak(aTHX_ "Cannot join a detached thread");
    }
    else if (thread->detached & 2) {
	MUTEX_UNLOCK(&thread->mutex);
	Perl_croak(aTHX_ "Thread already joined");
    }
    else {
#ifdef WIN32
	DWORD waitcode;
#else
	void *retval;
#endif
	MUTEX_UNLOCK(&thread->mutex);
#ifdef WIN32
	waitcode = WaitForSingleObject(thread->handle, INFINITE);
#else
	pthread_join(thread->thr,&retval);
#endif
	MUTEX_LOCK(&thread->mutex);
	/* sv_dup over the args */
	/* We have finished with it */
	thread->detached |= 2;
	MUTEX_UNLOCK(&thread->mutex);
	sv_unmagic(SvRV(obj),PERL_MAGIC_shared_scalar);
    }
}

void
Perl_ithread_detach(pTHX_ ithread *thread)
{
    MUTEX_LOCK(&thread->mutex);
    if (!thread->detached) {
	thread->detached = 1;
#ifdef WIN32
	CloseHandle(thread->handle);
	thread->handle = 0;
#else
	PERL_THREAD_DETACH(thread->thr);
#endif
    }
    MUTEX_UNLOCK(&thread->mutex);
}


void
Perl_ithread_DESTROY(pTHX_ SV *sv)
{
    ithread *thread = SV_to_ithread(aTHX_ sv);
    sv_unmagic(SvRV(sv),PERL_MAGIC_shared_scalar);
}

MODULE = threads		PACKAGE = threads	PREFIX = ithread_
PROTOTYPES: DISABLE

void
ithread_new (classname, function_to_call, ...)
char *	classname
SV *	function_to_call
CODE:
{
    AV* params = newAV();
    if (items > 2) {
	int i;
	for(i = 2; i < items ; i++) {
	    av_push(params, ST(i));
	}
    }
    ST(0) = sv_2mortal(Perl_ithread_create(aTHX_ Nullsv, classname, function_to_call, newRV_noinc((SV*) params)));
    XSRETURN(1);
}

void
ithread_self(char *classname)
CODE:
{
	ST(0) = sv_2mortal(Perl_ithread_self(aTHX_ Nullsv,classname));
	XSRETURN(1);
}

int
ithread_tid(ithread *thread)

void
ithread_join(SV *obj)

void
ithread_detach(ithread *thread)

void
ithread_DESTROY(SV *thread)

BOOT:
{
	ithread* thread;
	PERL_THREAD_ALLOC_SPECIFIC(self_key);
	MUTEX_INIT(&create_mutex);
	MUTEX_LOCK(&create_mutex);
	thread  = PerlMemShared_malloc(sizeof(ithread));
	Zero(thread,1,ithread);
	PL_perl_destruct_level = 2;
	MUTEX_INIT(&thread->mutex);
	threads = thread;
	thread->next = thread;
        thread->prev = thread;
	thread->interp = aTHX;
	thread->count  = 1;  /* imortal */
	thread->tid = tid_counter++;
	thread->detached = 1;
#ifdef WIN32
	thread->thr = GetCurrentThreadId();
#else
	thread->thr = pthread_self();
#endif
	PERL_THREAD_SETSPECIFIC(self_key,thread);
	MUTEX_UNLOCK(&create_mutex);
}

