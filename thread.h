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
#define pthread_condattr_default NULL
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
    if (pthread_cond_init((c), pthread_condattr_default)) \
	croak("panic: COND_INIT"); \
    else 1
#define COND_SIGNAL(c) \
    if (pthread_cond_signal((c))) croak("panic: COND_SIGNAL"); else 1
#define COND_BROADCAST(c) \
    if (pthread_cond_broadcast((c))) croak("panic: COND_BROADCAST"); else 1
#define COND_WAIT(c, m) \
    if (pthread_cond_wait((c), (m))) croak("panic: COND_WAIT"); else 1
#define COND_DESTROY(c) \
    if (pthread_cond_destroy((c))) croak("panic: COND_DESTROY"); else 1

/* DETACH(t) must only be called while holding t->mutex */
#define DETACH(t)			\
    if (pthread_detach((t)->Tself)) {	\
	MUTEX_UNLOCK(&(t)->mutex);	\
	croak("panic: DETACH");		\
    } else 1

/* XXX Add "old" (?) POSIX draft interface too */
#ifdef OLD_PTHREADS_API
struct thread *getTHR _((void));
#define THR getTHR()
#else
#define THR ((struct thread *) pthread_getspecific(thr_key))
#endif /* OLD_PTHREADS_API */
#define dTHR struct thread *thr = THR
#endif /* FAKE_THREADS */

#ifndef INIT_THREADS
#  ifdef NEED_PTHREAD_INIT
#    define INIT_THREADS pthread_init()
#  else
#    define INIT_THREADS NOOP
#  endif
#endif

struct thread {
    /* The fields that used to be global */
    /* Important ones in the first cache line (if alignment is done right) */
    SV **	Tstack_sp;
#ifdef OP_IN_REGISTER
    OP *	Topsave;
#else
    OP *	Top;
#endif
    SV **	Tcurpad;
    SV **	Tstack_base;

    SV **	Tstack_max;

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

    SV *	TSv;
    XPV *	TXpv;
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

    perl_thread	Tself;
    SV *	Toursv;
    HV *	Tcvcache;
    U32		flags;
    perl_mutex	mutex;			/* For the fields others can change */
    U32		tid;
    struct thread *next, *prev;		/* Circular linked list of threads */

#ifdef ADD_THREAD_INTERN
    struct thread_intern i;		/* Platform-dependent internals */
#endif
};

typedef struct thread *Thread;

/* Values and macros for thr->flags */
#define THRf_STATE_MASK	7
#define THRf_R_JOINABLE	0
#define THRf_R_JOINED	1
#define THRf_R_DETACHED	2
#define THRf_ZOMBIE	3
#define THRf_DEAD	4

#define THRf_DIE_FATAL	8

/* ThrSTATE(t) and ThrSETSTATE(t) must only be called while holding t->mutex */
#define ThrSTATE(t) ((t)->flags)
#define ThrSETSTATE(t, s) STMT_START {		\
	(t)->flags &= ~THRf_STATE_MASK;		\
	(t)->flags |= (s);			\
	DEBUG_L(PerlIO_printf(PerlIO_stderr(),	\
			      "thread %p set to state %d\n", (t), (s))); \
    } STMT_END

typedef struct condpair {
    perl_mutex	mutex;		/* Protects all other fields */
    perl_cond	owner_cond;	/* For when owner changes at all */
    perl_cond	cond;		/* For cond_signal and cond_broadcast */
    Thread	owner;		/* Currently owning thread */
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
#undef	statbuf
#undef	timesbuf
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
#define statbuf		(thr->Tstatbuf)
#define timesbuf	(thr->Ttimesbuf)
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

#define	cvcache		(thr->Tcvcache)
#endif /* USE_THREADS */
