#ifndef USE_THREADS
#define MUTEX_LOCK(m)
#define MUTEX_UNLOCK(m)
#define MUTEX_INIT(m)
#define MUTEX_DESTROY(m)
#define COND_INIT(c)
#define COND_SIGNAL(c)
#define COND_BROADCAST(c)
#define COND_WAIT(c, m)
#define COND_DESTROY(c)

#define THR
/* Rats: if dTHR is just blank then the subsequent ";" throws an error */
#define dTHR extern int errno
#else

#ifdef FAKE_THREADS
typedef struct thread *perl_thread;
/* With fake threads, thr is global(ish) so we don't need dTHR */
#define dTHR extern int errno

/*
 * Note that SCHEDULE() is only callable from pp code (which
 * must be expecting to be restarted). We'll have to do
 * something a bit different for XS code.
 */
#define SCHEDULE() return schedule(), op

#define MUTEX_LOCK(m)
#define MUTEX_UNLOCK(m)
#define MUTEX_INIT(m)
#define MUTEX_DESTROY(m)
#define COND_INIT(c) perl_cond_init(c)
#define COND_SIGNAL(c) perl_cond_signal(c)
#define COND_BROADCAST(c) perl_cond_broadcast(c)
#define COND_WAIT(c, m) STMT_START {	\
	perl_cond_wait(c);		\
	SCHEDULE();			\
    } STMT_END
#define COND_DESTROY(c)

#else
/* POSIXish threads */
typedef pthread_t perl_thread;
#ifdef OLD_PTHREADS_API
#define pthread_mutexattr_init(a) pthread_mutexattr_create(a)
#define pthread_mutexattr_settype(a,t) pthread_mutexattr_setkind_np(a,t)
#define pthread_key_create(k,d) pthread_keycreate(k,(pthread_destructor_t)(d))
#else
#define pthread_mutexattr_default NULL
#endif /* OLD_PTHREADS_API */

#define MUTEX_INIT(m) \
    if (pthread_mutex_init((m), pthread_mutexattr_default)) \
	croak("panic: MUTEX_INIT"); \
    else 1
#define MUTEX_LOCK(m) \
    if (pthread_mutex_lock((m))) croak("panic: MUTEX_LOCK"); else 1
#define MUTEX_UNLOCK(m) \
    if (pthread_mutex_unlock((m))) croak("panic: MUTEX_UNLOCK"); else 1
#define MUTEX_DESTROY(m) \
    if (pthread_mutex_destroy((m))) croak("panic: MUTEX_DESTROY"); else 1
#define COND_INIT(c) \
    if (pthread_cond_init((c), NULL)) croak("panic: COND_INIT"); else 1
#define COND_SIGNAL(c) \
    if (pthread_cond_signal((c))) croak("panic: COND_SIGNAL"); else 1
#define COND_BROADCAST(c) \
    if (pthread_cond_broadcast((c))) croak("panic: COND_BROADCAST"); else 1
#define COND_WAIT(c, m) \
    if (pthread_cond_wait((c), (m))) croak("panic: COND_WAIT"); else 1
#define COND_DESTROY(c) \
    if (pthread_cond_destroy((c))) croak("panic: COND_DESTROY"); else 1
/* XXX Add "old" (?) POSIX draft interface too */
#ifdef OLD_PTHREADS_API
struct thread *getTHR _((void));
#define THR getTHR()
#else
#define THR ((struct thread *) pthread_getspecific(thr_key))
#endif /* OLD_PTHREADS_API */
#define dTHR struct thread *thr = THR
#endif /* FAKE_THREADS */

struct thread {
    perl_thread	Tself;
    SV *	Toursv;

    /* The fields that used to be global */
    SV **	Tstack_base;
    SV **	Tstack_sp;
    SV **	Tstack_max;

#ifdef OP_IN_REGISTER
    OP *	Topsave;
#else
    OP *	Top;
#endif

    I32 *	Tscopestack;
    I32		Tscopestack_ix;
    I32		Tscopestack_max;

    ANY *	Tsavestack;
    I32		Tsavestack_ix;
    I32		Tsavestack_max;

    OP **	Tretstack;
    I32		Tretstack_ix;
    I32		Tretstack_max;

    I32 *	Tmarkstack;
    I32 *	Tmarkstack_ptr;
    I32 *	Tmarkstack_max;

    SV **	Tcurpad;

    SV *	TSv;
    XPV *	TXpv;
    char	Tbuf[2048];	/* should be a global locked by a mutex */
    char	Ttokenbuf[256];	/* should be a global locked by a mutex */
    struct stat	Tstatbuf;
    struct tms	Ttimesbuf;
    
    /* XXX What about regexp stuff? */

    /* Now the fields that used to be "per interpreter" (even when global) */

    /* XXX What about magic variables such as $/, $? and so on? */
    HV *	Tdefstash;
    HV *	Tcurstash;

    SV **	Ttmps_stack;
    I32		Ttmps_ix;
    I32		Ttmps_floor;
    I32		Ttmps_max;

    int		Tin_eval;
    OP *	Trestartop;
    int		Tdelaymagic;
    bool	Tdirty;
    U8		Tlocalizing;
    COP *	Tcurcop;

    CONTEXT *	Tcxstack;
    I32		Tcxstack_ix;
    I32		Tcxstack_max;

    AV *	Tcurstack;
    AV *	Tmainstack;
    JMPENV *	Ttop_env;
    I32		Trunlevel;

    /* XXX Sort stuff, firstgv, secongv and so on? */

    perl_mutex *Tthreadstart_mutexp;
    HV *	Tcvcache;
    U32		Tthrflags;

#ifdef FAKE_THREADS
    perl_thread next, prev;		/* Linked list of all threads */
    perl_thread next_run, prev_run;	/* Linked list of runnable threads */
    perl_cond	wait_queue;		/* Wait queue that we are waiting on */
    IV		private;		/* Holds data across time slices */
    I32		savemark;		/* Holds MARK for thread join values */
#endif /* FAKE_THREADS */
};

typedef struct thread *Thread;

/* Values and macros for thrflags */
#define THRf_STATE_MASK	3
#define THRf_NORMAL	0
#define THRf_DETACHED	1
#define THRf_JOINED	2
#define THRf_DEAD	3

#define THRf_DIE_FATAL	4

#define ThrSTATE(t)	(t->Tthrflags & THRf_STATE_MASK)
#define ThrSETSTATE(t, s) STMT_START {		\
	(t)->Tthrflags &= ~THRf_STATE_MASK;	\
	(t)->Tthrflags |= (s);			\
	DEBUG_L(fprintf(stderr, "thread 0x%lx set to state %d\n", \
			(unsigned long)(t), (s))); \
    } STMT_END

typedef struct condpair {
    perl_mutex	mutex;
    perl_cond	owner_cond;
    perl_cond	cond;
    Thread	owner;
} condpair_t;

#define MgMUTEXP(mg) (&((condpair_t *)(mg->mg_ptr))->mutex)
#define MgOWNERCONDP(mg) (&((condpair_t *)(mg->mg_ptr))->owner_cond)
#define MgCONDP(mg) (&((condpair_t *)(mg->mg_ptr))->cond)
#define MgOWNER(mg) ((condpair_t *)(mg->mg_ptr))->owner

#undef	stack_base
#undef	stack_sp
#undef	stack_max
#undef	curstack
#undef	mainstack
#undef	markstack
#undef	markstack_ptr
#undef	markstack_max
#undef	scopestack
#undef	scopestack_ix
#undef	scopestack_max
#undef	savestack
#undef	savestack_ix
#undef	savestack_max
#undef	retstack
#undef	retstack_ix
#undef	retstack_max
#undef	curcop
#undef	cxstack
#undef	cxstack_ix
#undef	cxstack_max
#undef	defstash
#undef	curstash
#undef	tmps_stack
#undef	tmps_floor
#undef	tmps_ix
#undef	tmps_max
#undef	curpad
#undef	Sv
#undef	Xpv
#undef	top_env
#undef	runlevel
#undef	in_eval
#undef	restartop
#undef	delaymagic
#undef	dirty
#undef	localizing

#define self		(thr->Tself)
#define oursv		(thr->Toursv)
#define stack_base	(thr->Tstack_base)
#define stack_sp	(thr->Tstack_sp)
#define stack_max	(thr->Tstack_max)
#ifdef OP_IN_REGISTER
#define opsave		(thr->Topsave)
#else
#undef	op
#define op		(thr->Top)
#endif
#define	curcop		(thr->Tcurcop)
#define	stack		(thr->Tstack)
#define curstack	(thr->Tcurstack)
#define	mainstack	(thr->Tmainstack)
#define	markstack	(thr->Tmarkstack)
#define	markstack_ptr	(thr->Tmarkstack_ptr)
#define	markstack_max	(thr->Tmarkstack_max)
#define	scopestack	(thr->Tscopestack)
#define	scopestack_ix	(thr->Tscopestack_ix)
#define	scopestack_max	(thr->Tscopestack_max)

#define	savestack	(thr->Tsavestack)
#define	savestack_ix	(thr->Tsavestack_ix)
#define	savestack_max	(thr->Tsavestack_max)

#define	retstack	(thr->Tretstack)
#define	retstack_ix	(thr->Tretstack_ix)
#define	retstack_max	(thr->Tretstack_max)

#define	cxstack		(thr->Tcxstack)
#define	cxstack_ix	(thr->Tcxstack_ix)
#define	cxstack_max	(thr->Tcxstack_max)

#define curpad		(thr->Tcurpad)
#define Sv		(thr->TSv)
#define Xpv		(thr->TXpv)
#define defstash	(thr->Tdefstash)
#define curstash	(thr->Tcurstash)

#define tmps_stack	(thr->Ttmps_stack)
#define tmps_ix		(thr->Ttmps_ix)
#define tmps_floor	(thr->Ttmps_floor)
#define tmps_max	(thr->Ttmps_max)

#define in_eval		(thr->Tin_eval)
#define restartop	(thr->Trestartop)
#define delaymagic	(thr->Tdelaymagic)
#define dirty		(thr->Tdirty)
#define localizing	(thr->Tlocalizing)

#define	top_env		(thr->Ttop_env)
#define	runlevel	(thr->Trunlevel)

#define	threadstart_mutexp	(thr->Tthreadstart_mutexp)
#define	cvcache		(thr->Tcvcache)
#define	thrflags	(thr->Tthrflags)
#endif /* USE_THREADS */
