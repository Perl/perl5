#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Magic signature for Thread's mg_private is "Th" */ 
#define Thread_MAGIC_SIGNATURE 0x5468

static U32 threadnum = 0;
static int sig_pipe[2];

static void
remove_thread(t)
Thread t;
{
    DEBUG_L(WITH_THR(PerlIO_printf(PerlIO_stderr(),
				   "%p: remove_thread %p\n", thr, t)));
    MUTEX_LOCK(&threads_mutex);
    MUTEX_DESTROY(&t->mutex);
    nthreads--;
    t->prev->next = t->next;
    t->next->prev = t->prev;
    COND_BROADCAST(&nthreads_cond);
    MUTEX_UNLOCK(&threads_mutex);
}

static void *
threadstart(arg)
void *arg;
{
#ifdef FAKE_THREADS
    Thread savethread = thr;
    LOGOP myop;
    dSP;
    I32 oldscope = scopestack_ix;
    I32 retval;
    AV *returnav;
    int i;

    DEBUG_L(PerlIO_printf(PerlIO_stderr(), "new thread %p starting at %s\n",
			  thr, SvPEEK(TOPs)));
    thr = (Thread) arg;
    savemark = TOPMARK;
    thr->prev = thr->prev_run = savethread;
    thr->next = savethread->next;
    thr->next_run = savethread->next_run;
    savethread->next = savethread->next_run = thr;
    thr->wait_queue = 0;
    thr->private = 0;

    /* Now duplicate most of perl_call_sv but with a few twists */
    op = (OP*)&myop;
    Zero(op, 1, LOGOP);
    myop.op_flags = OPf_STACKED;
    myop.op_next = Nullop;
    myop.op_flags |= OPf_KNOW;
    myop.op_flags |= OPf_WANT_LIST;
    op = pp_entersub(ARGS);
    DEBUG_L(if (!op)
	    PerlIO_printf(PerlIO_stderr(), "thread starts at Nullop\n"));
    /*
     * When this thread is next scheduled, we start in the right
     * place. When the thread runs off the end of the sub, perl.c
     * handles things, using savemark to figure out how much of the
     * stack is the return value for any join.
     */
    thr = savethread;		/* back to the old thread */
    return 0;
#else
    Thread thr = (Thread) arg;
    LOGOP myop;
    dSP;
    I32 oldmark = TOPMARK;
    I32 oldscope = scopestack_ix;
    I32 retval;
    AV *returnav;
    int i, ret;
    dJMPENV;

    /* Don't call *anything* requiring dTHR until after pthread_setspecific */
    /*
     * Wait until our creator releases us. If we didn't do this, then
     * it would be potentially possible for out thread to carry on and
     * do stuff before our creator fills in our "self" field. For example,
     * if we went and created another thread which tried to pthread_join
     * with us, then we'd be in a mess.
     */
    MUTEX_LOCK(&thr->mutex);
    MUTEX_UNLOCK(&thr->mutex);

    /*
     * It's safe to wait until now to set the thread-specific pointer
     * from our pthread_t structure to our struct thread, since we're
     * the only thread who can get at it anyway.
     */
    if (pthread_setspecific(thr_key, (void *) thr))
	croak("panic: pthread_setspecific");

    /* Only now can we use SvPEEK (which calls sv_newmortal which does dTHR) */
    DEBUG_L(PerlIO_printf(PerlIO_stderr(), "new thread %p starting at %s\n",
			  thr, SvPEEK(TOPs)));

    JMPENV_PUSH(ret);
    switch (ret) {
    case 3:
        PerlIO_printf(PerlIO_stderr(), "panic: threadstart\n");
	/* fall through */
    case 1:
	STATUS_ALL_FAILURE;
	/* fall through */
    case 2:
	/* my_exit() was called */
	while (scopestack_ix > oldscope)
	    LEAVE;
	JMPENV_POP;
	av_store(returnav, 0, newSViv(statusvalue));
	goto finishoff;
    }

    /* Now duplicate most of perl_call_sv but with a few twists */
    op = (OP*)&myop;
    Zero(op, 1, LOGOP);
    myop.op_flags = OPf_STACKED;
    myop.op_next = Nullop;
    myop.op_flags |= OPf_KNOW;
    myop.op_flags |= OPf_WANT_LIST;
    op = pp_entersub(ARGS);
    if (op)
	runops();
    SPAGAIN;
    retval = sp - (stack_base + oldmark);
    sp = stack_base + oldmark + 1;
    DEBUG_L(for (i = 1; i <= retval; i++)
		PerlIO_printf(PerlIO_stderr(),
			      "%p returnav[%d] = %s\n",
			      thr, i, SvPEEK(sp[i - 1]));)
    returnav = newAV();
    av_store(returnav, 0, newSVpv("", 0));
    for (i = 1; i <= retval; i++, sp++)
	sv_setsv(*av_fetch(returnav, i, TRUE), SvREFCNT_inc(*sp));
    
  finishoff:
#if 0    
    /* removed for debug */
    SvREFCNT_dec(curstack);
#endif
    SvREFCNT_dec(cvcache);
    Safefree(markstack);
    Safefree(scopestack);
    Safefree(savestack);
    Safefree(retstack);
    Safefree(cxstack);
    Safefree(tmps_stack);

    MUTEX_LOCK(&thr->mutex);
    DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			  "%p: threadstart finishing: state is %u\n",
			  thr, ThrSTATE(thr)));
    switch (ThrSTATE(thr)) {
    case THRf_R_JOINABLE:
	ThrSETSTATE(thr, THRf_ZOMBIE);
	MUTEX_UNLOCK(&thr->mutex);
	DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			      "%p: R_JOINABLE thread finished\n", thr));
	break;
    case THRf_R_JOINED:
	ThrSETSTATE(thr, THRf_DEAD);
	MUTEX_UNLOCK(&thr->mutex);
	remove_thread(thr);
	DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			      "%p: R_JOINED thread finished\n", thr));
	break;
    case THRf_R_DETACHED:
	ThrSETSTATE(thr, THRf_DEAD);
	MUTEX_UNLOCK(&thr->mutex);
	SvREFCNT_dec(returnav);
	DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			      "%p: DETACHED thread finished\n", thr));
	remove_thread(thr);	/* This might trigger main thread to finish */
	break;
    default:
	MUTEX_UNLOCK(&thr->mutex);
	croak("panic: illegal state %u at end of threadstart", ThrSTATE(thr));
	/* NOTREACHED */
    }
    return (void *) returnav;	/* Available for anyone to join with us */
				/* unless we are detached in which case */
				/* noone will see the value anyway. */
#endif    
}

static SV *
newthread(startsv, initargs, class)
SV *startsv;
AV *initargs;
char *class;
{
    dTHR;
    dSP;
    Thread savethread;
    int i;
    SV *sv;
    sigset_t fullmask, oldmask;
    
    savethread = thr;
    sv = newSVpv("", 0);
    SvGROW(sv, sizeof(struct thread) + 1);
    SvCUR_set(sv, sizeof(struct thread));
    thr = (Thread) SvPVX(sv);
    DEBUG_L(PerlIO_printf(PerlIO_stderr(), "%p: newthread(%s) = %p)\n",
			  savethread, SvPEEK(startsv), thr));
    oursv = sv; 
    /* If we don't zero these foostack pointers, init_stacks won't init them */
    markstack = 0;
    scopestack = 0;
    savestack = 0;
    retstack = 0;
    init_stacks(ARGS);
    curcop = savethread->Tcurcop;	/* XXX As good a guess as any? */
    SPAGAIN;
    defstash = savethread->Tdefstash;	/* XXX maybe these should */
    curstash = savethread->Tcurstash;	/* always be set to main? */
    /* top_env? */
    /* runlevel */
    cvcache = newHV();
    thr->flags = THRf_R_JOINABLE;
    MUTEX_INIT(&thr->mutex);
    thr->tid = ++threadnum;
    /* Insert new thread into the circular linked list and bump nthreads */
    MUTEX_LOCK(&threads_mutex);
    thr->next = savethread->next;
    thr->prev = savethread;
    savethread->next = thr;
    thr->next->prev = thr;
    nthreads++;
    MUTEX_UNLOCK(&threads_mutex);

    DEBUG_L(PerlIO_printf(PerlIO_stderr(),
			  "%p: newthread, tid is %u, preparing stack\n",
			  savethread, thr->tid));
    /* The following pushes the arg list and startsv onto the *new* stack */
    PUSHMARK(sp);
    /* Could easily speed up the following greatly */
    for (i = 0; i <= AvFILL(initargs); i++)
	XPUSHs(SvREFCNT_inc(*av_fetch(initargs, i, FALSE)));
    XPUSHs(SvREFCNT_inc(startsv));
    PUTBACK;

#ifdef FAKE_THREADS
    threadstart(thr);
#else    
    /* On your marks... */
    MUTEX_LOCK(&thr->mutex);
    /* Get set...
     * Increment the global thread count.
     */
    sigfillset(&fullmask);
    if (sigprocmask(SIG_SETMASK, &fullmask, &oldmask) == -1)
	croak("panic: sigprocmask");
    if (pthread_create(&self, NULL, threadstart, (void*) thr))
	return NULL;	/* XXX should clean up first */
    /* Go */
    MUTEX_UNLOCK(&thr->mutex);
    if (sigprocmask(SIG_SETMASK, &oldmask, 0))
	croak("panic: sigprocmask");
#endif
    sv = newSViv(thr->tid);
    sv_magic(sv, oursv, '~', 0, 0);
    SvMAGIC(sv)->mg_private = Thread_MAGIC_SIGNATURE;
    return sv_bless(newRV_noinc(sv), gv_stashpv(class, TRUE));
}

static Signal_t
handle_thread_signal(sig)
int sig;
{
    char c = (char) sig;
    write(sig_pipe[0], &c, 1);
}

MODULE = Thread		PACKAGE = Thread

void
new(class, startsv, ...)
	char *		class
	SV *		startsv
	AV *		av = av_make(items - 2, &ST(2));
    PPCODE:
	XPUSHs(sv_2mortal(newthread(startsv, av, class)));

void
join(t)
	Thread	t
	AV *	av = NO_INIT
	int	i = NO_INIT
    PPCODE:
	DEBUG_L(PerlIO_printf(PerlIO_stderr(), "%p: joining %p (state %u)\n",
			      thr, t, ThrSTATE(t)););
    	MUTEX_LOCK(&t->mutex);
	switch (ThrSTATE(t)) {
	case THRf_R_JOINABLE:
	case THRf_R_JOINED:
	    ThrSETSTATE(t, THRf_R_JOINED);
	    MUTEX_UNLOCK(&t->mutex);
	    break;
	case THRf_ZOMBIE:
	    ThrSETSTATE(t, THRf_DEAD);
	    MUTEX_UNLOCK(&t->mutex);
	    remove_thread(t);
	    break;
	default:
	    MUTEX_UNLOCK(&t->mutex);
	    croak("can't join with thread");
	    /* NOTREACHED */
	}
	if (pthread_join(t->Tself, (void **) &av))
	    croak("pthread_join failed");

	/* Could easily speed up the following if necessary */
	for (i = 0; i <= AvFILL(av); i++)
	    XPUSHs(sv_2mortal(*av_fetch(av, i, FALSE)));

void
detach(t)
	Thread	t
    CODE:
	DEBUG_L(PerlIO_printf(PerlIO_stderr(), "%p: detaching %p (state %u)\n",
			      thr, t, ThrSTATE(t)););
    	MUTEX_LOCK(&t->mutex);
	switch (ThrSTATE(t)) {
	case THRf_R_JOINABLE:
	    ThrSETSTATE(t, THRf_R_DETACHED);
	    /* fall through */
	case THRf_R_DETACHED:
	    DETACH(t);
	    MUTEX_UNLOCK(&t->mutex);
	    break;
	case THRf_ZOMBIE:
	    ThrSETSTATE(t, THRf_DEAD);
	    DETACH(t);
	    MUTEX_UNLOCK(&t->mutex);
	    remove_thread(t);
	    break;
	default:
	    MUTEX_UNLOCK(&t->mutex);
	    croak("can't detach thread");
	    /* NOTREACHED */
	}

void
equal(t1, t2)
	Thread	t1
	Thread	t2
    PPCODE:
	PUSHs((t1 == t2) ? &sv_yes : &sv_no);

void
flags(t)
	Thread	t
    PPCODE:
	PUSHs(sv_2mortal(newSViv(t->flags)));

void
self(class)
	char *	class
    PREINIT:
	SV *sv;
    PPCODE:
	sv = newSViv(thr->tid);
	sv_magic(sv, oursv, '~', 0, 0);
	SvMAGIC(sv)->mg_private = Thread_MAGIC_SIGNATURE;
	PUSHs(sv_2mortal(sv_bless(newRV_noinc(sv), gv_stashpv(class, TRUE))));

U32
tid(t)
	Thread	t
    CODE:
    	MUTEX_LOCK(&t->mutex);
	RETVAL = t->tid;
    	MUTEX_UNLOCK(&t->mutex);
    OUTPUT:
	RETVAL

void
DESTROY(t)
	SV *	t
    PPCODE:
	PUSHs(&sv_yes);

void
yield()
    CODE:
#ifdef OLD_PTHREADS_API
	pthread_yield();
#else
#ifndef NO_SCHED_YIELD
	sched_yield();
#endif /* NO_SCHED_YIELD */
#endif /* OLD_PTHREADS_API */

void
cond_wait(sv)
	SV *	sv
	MAGIC *	mg = NO_INIT
CODE:
	if (SvROK(sv))
	    sv = SvRV(sv);

	mg = condpair_magic(sv);
	DEBUG_L(PerlIO_printf(PerlIO_stderr(), "%p: cond_wait %p\n", thr, sv));
	MUTEX_LOCK(MgMUTEXP(mg));
	if (MgOWNER(mg) != thr) {
	    MUTEX_UNLOCK(MgMUTEXP(mg));
	    croak("cond_wait for lock that we don't own\n");
	}
	MgOWNER(mg) = 0;
	COND_WAIT(MgCONDP(mg), MgMUTEXP(mg));
	while (MgOWNER(mg))
	    COND_WAIT(MgOWNERCONDP(mg), MgMUTEXP(mg));
	MgOWNER(mg) = thr;
	MUTEX_UNLOCK(MgMUTEXP(mg));
	
void
cond_signal(sv)
	SV *	sv
	MAGIC *	mg = NO_INIT
CODE:
	if (SvROK(sv))
	    sv = SvRV(sv);

	mg = condpair_magic(sv);
	DEBUG_L(PerlIO_printf(PerlIO_stderr(), "%p: cond_signal %p\n",thr,sv));
	MUTEX_LOCK(MgMUTEXP(mg));
	if (MgOWNER(mg) != thr) {
	    MUTEX_UNLOCK(MgMUTEXP(mg));
	    croak("cond_signal for lock that we don't own\n");
	}
	COND_SIGNAL(MgCONDP(mg));
	MUTEX_UNLOCK(MgMUTEXP(mg));

void
cond_broadcast(sv)
	SV *	sv
	MAGIC *	mg = NO_INIT
CODE:
	if (SvROK(sv))
	    sv = SvRV(sv);

	mg = condpair_magic(sv);
	DEBUG_L(PerlIO_printf(PerlIO_stderr(), "%p: cond_broadcast %p\n",
			      thr, sv));
	MUTEX_LOCK(MgMUTEXP(mg));
	if (MgOWNER(mg) != thr) {
	    MUTEX_UNLOCK(MgMUTEXP(mg));
	    croak("cond_broadcast for lock that we don't own\n");
	}
	COND_BROADCAST(MgCONDP(mg));
	MUTEX_UNLOCK(MgMUTEXP(mg));

void
list(class)
	char *	class
    PREINIT:
	Thread	t;
	AV *	av;
	SV **	svp;
	int	n = 0;
    PPCODE:
	av = newAV();
	/*
	 * Iterate until we have enough dynamic storage for all threads.
	 * We mustn't do any allocation while holding threads_mutex though.
	 */
	MUTEX_LOCK(&threads_mutex);
	do {
	    n = nthreads;
	    MUTEX_UNLOCK(&threads_mutex);
	    if (AvFILL(av) < n - 1) {
		int i = AvFILL(av);
		for (i = AvFILL(av); i < n - 1; i++) {
		    SV *sv = newSViv(0);	/* fill in tid later */
		    sv_magic(sv, 0, '~', 0, 0);	/* fill in other magic later */
		    av_push(av, sv_bless(newRV_noinc(sv),
					 gv_stashpv(class, TRUE)));
	
		}
	    }
	    MUTEX_LOCK(&threads_mutex);
	} while (n < nthreads);
	n = nthreads;	/* Get the final correct value */

	/*
	 * At this point, there's enough room to fill in av.
	 * Note that we are holding threads_mutex so the list
	 * won't change out from under us but all the remaining
	 * processing is "fast" (no blocking, malloc etc.)
	 */
	t = thr;
	svp = AvARRAY(av);
	do {
	    SV *sv = (SV*)SvRV(*svp);
	    sv_setiv(sv, t->tid);
	    SvMAGIC(sv)->mg_obj = SvREFCNT_inc(t->Toursv);
	    SvMAGIC(sv)->mg_flags |= MGf_REFCOUNTED;
	    SvMAGIC(sv)->mg_private = Thread_MAGIC_SIGNATURE;
	    t = t->next;
	    svp++;
	} while (t != thr);
	/*  */
	MUTEX_UNLOCK(&threads_mutex);
	/* Truncate any unneeded slots in av */
	av_fill(av, n - 1);
	/* Finally, push all the new objects onto the stack and drop av */
	EXTEND(sp, n);
	for (svp = AvARRAY(av); n > 0; n--, svp++)
	    PUSHs(*svp);
	(void)sv_2mortal((SV*)av);


MODULE = Thread		PACKAGE = Thread::Signal

void
kill_sighandler_thread()
    PPCODE:
	write(sig_pipe[0], "\0", 1);
	PUSHs(&sv_yes);

void
init_thread_signals()
    PPCODE:
	sighandlerp = handle_thread_signal;
	if (pipe(sig_pipe) == -1)
	    XSRETURN_UNDEF;
	PUSHs(&sv_yes);

SV *
await_signal()
    PREINIT:
	char c;
	ssize_t ret;
    CODE:
	do {
	    ret = read(sig_pipe[1], &c, 1);
	} while (ret == -1 && errno == EINTR);
	if (ret == -1)
	    croak("panic: await_signal");
	if (ret == 0)
	    XSRETURN_UNDEF;
	RETVAL = c ? psig_ptr[c] : &sv_no;
    OUTPUT:
	RETVAL
