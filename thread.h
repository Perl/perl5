#ifdef USE_THREADS

#ifdef WIN32
#  include <win32thread.h>
#else

/* POSIXish threads */
typedef pthread_t perl_os_thread;
#ifdef OLD_PTHREADS_API
#  define pthread_mutexattr_init(a) pthread_mutexattr_create(a)
#  define pthread_mutexattr_settype(a,t) pthread_mutexattr_setkind_np(a,t)
#  define pthread_key_create(k,d) pthread_keycreate(k,(pthread_destructor_t)(d))
#  define YIELD pthread_yield()
#  define DETACH(t)				\
    STMT_START {				\
	if (pthread_detach(&(t)->self)) {	\
	    MUTEX_UNLOCK(&(t)->mutex);		\
	    croak("panic: DETACH");		\
	}					\
    } STMT_END
#else
#  define pthread_mutexattr_default NULL
#  define pthread_condattr_default NULL
#  define pthread_attr_default NULL
#endif /* OLD_PTHREADS_API */
#endif

#ifndef YIELD
#  ifdef HAS_PTHREAD_YIELD
#    define YIELD pthread_yield()
#  else
#    define YIELD sched_yield()
#  endif
#endif

#ifndef MUTEX_INIT
#define MUTEX_INIT(m)						\
    STMT_START {						\
	if (pthread_mutex_init((m), pthread_mutexattr_default))	\
	    croak("panic: MUTEX_INIT");				\
    } STMT_END
#define MUTEX_LOCK(m)				\
    STMT_START {				\
	if (pthread_mutex_lock((m)))		\
	    croak("panic: MUTEX_LOCK");		\
    } STMT_END
#define MUTEX_UNLOCK(m)				\
    STMT_START {				\
	if (pthread_mutex_unlock((m)))		\
	    croak("panic: MUTEX_UNLOCK");	\
    } STMT_END
#define MUTEX_DESTROY(m)			\
    STMT_START {				\
	if (pthread_mutex_destroy((m)))		\
	    croak("panic: MUTEX_DESTROY");	\
    } STMT_END
#endif /* MUTEX_INIT */

#ifndef COND_INIT
#define COND_INIT(c)						\
    STMT_START {						\
	if (pthread_cond_init((c), pthread_condattr_default))	\
	    croak("panic: COND_INIT");				\
    } STMT_END
#define COND_SIGNAL(c)				\
    STMT_START {				\
	if (pthread_cond_signal((c)))		\
	    croak("panic: COND_SIGNAL");	\
    } STMT_END
#define COND_BROADCAST(c)			\
    STMT_START {				\
	if (pthread_cond_broadcast((c)))	\
	    croak("panic: COND_BROADCAST");	\
    } STMT_END
#define COND_WAIT(c, m)				\
    STMT_START {				\
	if (pthread_cond_wait((c), (m)))	\
	    croak("panic: COND_WAIT");		\
    } STMT_END
#define COND_DESTROY(c)				\
    STMT_START {				\
	if (pthread_cond_destroy((c)))		\
	    croak("panic: COND_DESTROY");	\
    } STMT_END
#endif /* COND_INIT */

/* DETACH(t) must only be called while holding t->mutex */
#ifndef DETACH
#define DETACH(t)				\
    STMT_START {				\
	if (pthread_detach((t)->self)) {	\
	    MUTEX_UNLOCK(&(t)->mutex);		\
	    croak("panic: DETACH");		\
	}					\
    } STMT_END
#endif /* DETACH */

#ifndef JOIN
#define JOIN(t, avp) 					\
    STMT_START {					\
	if (pthread_join((t)->self, (void**)(avp)))	\
	    croak("panic: pthread_join");		\
    } STMT_END
#endif /* JOIN */

#ifndef SET_THR
#define SET_THR(t)					\
    STMT_START {					\
	if (pthread_setspecific(thr_key, (void *) (t)))	\
	    croak("panic: pthread_setspecific");	\
    } STMT_END
#endif /* SET_THR */

#ifndef THR
#  ifdef OLD_PTHREADS_API
struct perl_thread *getTHR _((void));
#    define THR getTHR()
#  else
#    define THR ((struct perl_thread *) pthread_getspecific(thr_key))
#  endif /* OLD_PTHREADS_API */
#endif /* THR */

#ifndef dTHR
#  define dTHR struct perl_thread *thr = THR
#endif /* dTHR */

#ifndef INIT_THREADS
#  ifdef NEED_PTHREAD_INIT
#    define INIT_THREADS pthread_init()
#  else
#    define INIT_THREADS NOOP
#  endif
#endif


#ifndef THREAD_RET_TYPE
#  define THREAD_RET_TYPE	void *
#  define THREAD_RET_CAST(p)	((void *)(p))
#endif /* THREAD_RET */

struct perl_thread {
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

    /* Fields used by magic variables such as $@, $/ and so on */
    bool	Ttainted;
    PMOP *	Tcurpm;
    SV *	Tnrs;
    SV *	Trs;
    GV *	Tlast_in_gv;
    char *	Tofs;
    STRLEN	Tofslen;
    GV *	Tdefoutgv;
    char *	Tchopset;
    SV *	Tformtarget;
    SV *	Tbodytarget;
    SV *	Ttoptarget;

    /* Stashes */
    HV *	Tdefstash;
    HV *	Tcurstash;

    /* Stacks */
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

    PERL_CONTEXT *	Tcxstack;
    I32		Tcxstack_ix;
    I32		Tcxstack_max;

    AV *	Tcurstack;
    AV *	Tmainstack;
    JMPENV *	Ttop_env;

    /* XXX Sort stuff, firstgv, secongv and so on? */

    SV *	oursv;
    HV *	cvcache;
    perl_os_thread	self;		/* Underlying thread object */
    U32		flags;
    AV *	threadsv;		/* Per-thread SVs ($_, $@ etc.) */
    AV *	specific;		/* Thread-specific user data */
    SV *	errsv;			/* Backing SV for $@ */
    HV *	errhv;			/* HV for what was %@ in pp_ctl.c */
    perl_mutex	mutex;			/* For the fields others can change */
    U32		tid;
    struct perl_thread *next, *prev;		/* Circular linked list of threads */
    JMPENV	Tstart_env;	        /* Top of top_env longjmp() chain */ 
#ifdef HAVE_THREAD_INTERN
    struct thread_intern i;		/* Platform-dependent internals */
#endif
    char	trailing_nul;		/* For the sake of thrsv and oursv */
};

typedef struct perl_thread *Thread;

/* Values and macros for thr->flags */
#define THRf_STATE_MASK	7
#define THRf_R_JOINABLE	0
#define THRf_R_JOINED	1
#define THRf_R_DETACHED	2
#define THRf_ZOMBIE	3
#define THRf_DEAD	4

#define THRf_DID_DIE	8

/* ThrSTATE(t) and ThrSETSTATE(t) must only be called while holding t->mutex */
#define ThrSTATE(t) ((t)->flags & THRf_STATE_MASK)
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
#undef	tainted
#undef	curpm
#undef	nrs
#undef	rs
#undef	last_in_gv
#undef	ofs
#undef	ofslen
#undef	defoutgv
#undef	chopset
#undef	formtarget
#undef	bodytarget
#undef  start_env
#undef	toptarget
#undef	top_env
#undef	in_eval
#undef	restartop
#undef	delaymagic
#undef	dirty
#undef	localizing

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
#define	tainted		(thr->Ttainted)
#define	tainted		(thr->Ttainted)
#define	curpm		(thr->Tcurpm)
#define	nrs		(thr->Tnrs)
#define	rs		(thr->Trs)
#define	last_in_gv	(thr->Tlast_in_gv)
#define	ofs		(thr->Tofs)
#define	ofslen		(thr->Tofslen)
#define	defoutgv	(thr->Tdefoutgv)
#define	chopset		(thr->Tchopset)
#define	formtarget	(thr->Tformtarget)
#define	bodytarget	(thr->Tbodytarget)
#define	toptarget	(thr->Ttoptarget)
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
#define start_env       (thr->Tstart_env)

#else
/* USE_THREADS is not defined */
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
#endif /* USE_THREADS */
