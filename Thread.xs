#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct condpair {
    pthread_mutex_t	mutex;
    pthread_cond_t	cond;
    Thread		owner;
} condpair_t;

AV *condpair_table;
typedef SSize_t Thread__Cond;

static void *
threadstart(arg)
void *arg;
{
    Thread thr = (Thread) arg;
    LOGOP myop;
    dSP;
    I32 oldmark = TOPMARK;
    I32 oldscope = scopestack_ix;
    I32 retval;
    AV *returnav = newAV();
    int i;
    
    /*
     * Wait until our creator releases us. If we didn't do this, then
     * it would be potentially possible for out thread to carry on and
     * do stuff before our creator fills in our "self" field. For example,
     * if we went and created another thread which tried to pthread_join
     * with us, then we'd be in a mess.
     */
    MUTEX_LOCK(threadstart_mutexp);
    MUTEX_UNLOCK(threadstart_mutexp);
    MUTEX_DESTROY(threadstart_mutexp);	/* don't need it any more */
    Safefree(threadstart_mutexp);

    DEBUG_L(fprintf(stderr, "new thread 0x%lx starting at %s\n",
		    (unsigned long) thr, SvPEEK(TOPs)));
    /*
     * It's safe to wait until now to set the thread-specific pointer
     * from our pthread_t structure to our struct thread, since we're
     * the only thread who can get at it anyway.
     */
    if (pthread_setspecific(thr_key, (void *) thr))
	croak("panic: pthread_setspecific");

    switch (Sigsetjmp(top_env,1)) {
      case 3:
        fprintf(stderr, "panic: top_env\n");
	/* fall through */
      case 1:
#ifdef VMS
        statusvalue = 255;
#else
        statusvalue = 1;
#endif
	/* fall through */
      case 2:
	av_store(returnav, 0, newSViv(statusvalue));
	goto finishoff;
    }

    /* Now duplicate most of perl_call_sv but with a few twists */
    op = (OP*)&myop;
    Zero(op, 1, LOGOP);
    myop.op_flags = OPf_STACKED;
    myop.op_next = Nullop;
    myop.op_flags |= OPf_KNOW;
    myop.op_flags |= OPf_LIST;
    op = pp_entersub(ARGS);
    if (op)
	runops();
    retval = stack_sp - (stack_base + oldmark);
    sp -= retval;
    av_store(returnav, 0, newSVpv("", 0));
    for (i = 1; i <= retval; i++)
	sv_setsv(*av_fetch(returnav, i, TRUE), *sp++);

  finishoff:
    SvREFCNT_dec(stack);
    SvREFCNT_dec(cvcache);
    Safefree(markstack);
    Safefree(scopestack);
    Safefree(savestack);
    Safefree(retstack);
    Safefree(cxstack);
    Safefree(tmps_stack);

    return (void *) returnav;	/* Available for anyone to join with us */
}

Thread
newthread(startsv, initargs)
SV *startsv;
AV *initargs;
{
    dTHR;
    dSP;
    Thread savethread;
    int i;
    
    savethread = thr;
    New(53, thr, 1, struct thread);
    init_stacks(ARGS);
    SPAGAIN;
    defstash = savethread->Tdefstash;	/* XXX maybe these should */
    curstash = savethread->Tcurstash;	/* always be set to main? */
    mainstack = stack;
    /* top_env? */
    /* runlevel */
    cvcache = newHV();

    /* The following pushes the arg list and startsv onto the *new* stack */
    PUSHMARK(sp);
    /* Could easily speed up the following greatly */
    for (i = 0; i < AvFILL(initargs); i++)
	XPUSHs(SvREFCNT_inc(*av_fetch(initargs, i, FALSE)));
    XPUSHs(SvREFCNT_inc(startsv));
    PUTBACK;

    New(53, threadstart_mutexp, 1, pthread_mutex_t);
    /* On your marks... */
    MUTEX_INIT(threadstart_mutexp);
    MUTEX_LOCK(threadstart_mutexp);
    /* Get set...
     * Increment the global thread count. It is decremented
     * by the destructor for the thread specific key thr_key.
     */
    MUTEX_LOCK(&nthreads_mutex);
    nthreads++;
    MUTEX_UNLOCK(&nthreads_mutex);
    if (pthread_create(&self, NULL, threadstart, (void*) thr))
	return NULL;	/* XXX should clean up first */
    /* Go */
    MUTEX_UNLOCK(threadstart_mutexp);
    return thr;
}

void condpair_kick(SSize_t cond, SV *code, int broadcast_flag) {
    condpair_t *condp;
    HV *hvp;
    GV *gvp;
    CV *cv = sv_2cv(code, &hvp, &gvp, FALSE); 
    SV *sv = *av_fetch(condpair_table, cond, TRUE);
    dTHR;	

    if (!SvOK(sv))
	croak("bad Cond object argument");
    condp = (condpair_t *) SvPVX(sv);
    /* Get ownership of condpair object */
    MUTEX_LOCK(&condp->mutex);
    while (condp->owner && condp->owner != thr)
	COND_WAIT(&condp->cond, &condp->mutex);
    if (condp->owner == thr) {
	MUTEX_UNLOCK(&condp->mutex);
	croak("Recursing in Thread::Cond::waituntil");
    }
    condp->owner = thr;
    MUTEX_UNLOCK(&condp->mutex);
    /* We now own the condpair object */
    perl_call_sv(code, G_SCALAR|G_NOARGS|G_DISCARD|G_EVAL);
    /* Release condpair object */
    MUTEX_LOCK(&condp->mutex);
    condp->owner = 0;
    /* Signal or Broadcast condpair */
    if (broadcast_flag)
	COND_BROADCAST(&condp->cond);
    else
	COND_SIGNAL(&condp->cond);
    MUTEX_UNLOCK(&condp->mutex);
    /* Check we don't need to propagate a die */
    sv = GvSV(gv_fetchpv("@", TRUE, SVt_PV));
    if (SvTRUE(sv))
	croak(SvPV(sv, na));
}    

static SV *
fast(sv)
SV *sv;
{
    HV *hvp;
    GV *gvp;
    CV *cv = sv_2cv(sv, &hvp, &gvp, FALSE);

    if (!cv)
	croak("Not a CODE reference");
    if (CvCONDP(cv)) {
	COND_DESTROY(CvCONDP(cv));
	Safefree(CvCONDP(cv));
	CvCONDP(cv) = 0;
    }
    return sv;
}

MODULE = Thread		PACKAGE = Thread

Thread
new(class, startsv, ...)
	SV *		class
	SV *		startsv
	AV *		av = av_make(items - 1, &ST(2));
    CODE:
	RETVAL = newthread(startsv, av);
    OUTPUT:
	RETVAL

void
sync(sv)
	SV *	sv
	HV *	hvp = NO_INIT
	GV *	gvp = NO_INIT
    CODE:
	SvFLAGS(sv_2cv(sv, &hvp, &gvp, FALSE)) |= SVpcv_SYNC;
	ST(0) = sv_mortalcopy(sv);

void
fast(sv)
	SV *	sv
    CODE:
	ST(0) = sv_mortalcopy(fast(sv));

void
join(t)
	Thread	t
	AV *	av = NO_INIT
	int	i = NO_INIT
    PPCODE:
	if (pthread_join(t->Tself, (void **) &av))
	    croak("pthread_join failed");
	/* Could easily speed up the following if necessary */
	for (i = 0; i <= AvFILL(av); i++)
	    XPUSHs(sv_2mortal(*av_fetch(av, i, FALSE)));

void
yield(t)
	Thread	t
    CODE:
	pthread_yield();

MODULE = Thread		PACKAGE = Thread::Cond

Thread::Cond
new(class)
	char *		class
	SV *		sv = NO_INIT
	condpair_t *	condp = NO_INIT
    CODE:
	if (!condpair_table)
	    condpair_table = newAV();
	sv = newSVpv("", 0);
	sv_grow(sv, sizeof(condpair_t));
	condp = (condpair_t *) SvPVX(sv);
	MUTEX_INIT(&condp->mutex);
	COND_INIT(&condp->cond);
	condp->owner = 0;
	av_push(condpair_table, sv);
	RETVAL = AvFILL(condpair_table);
    OUTPUT:
	RETVAL

void
waituntil(cond, code)
	Thread::Cond	cond
	SV *		code
	SV *		sv = NO_INIT
	condpair_t *	condp = NO_INIT
	HV *		hvp = NO_INIT
	GV *		gvp = NO_INIT
	CV *		cv = sv_2cv(code, &hvp, &gvp, FALSE); 
	I32		count = NO_INIT
    CODE:
	sv = *av_fetch(condpair_table, cond, TRUE);
	if (!SvOK(sv))
	    croak("bad Cond object argument");
	condp = (condpair_t *) SvPVX(sv);
	do {
	    /* Get ownership of condpair object */
	    MUTEX_LOCK(&condp->mutex);
	    while (condp->owner && condp->owner != thr)
		COND_WAIT(&condp->cond, &condp->mutex);
	    if (condp->owner == thr) {
		MUTEX_UNLOCK(&condp->mutex);
		croak("Recursing in Thread::Cond::waituntil");
	    }
	    condp->owner = thr;
	    MUTEX_UNLOCK(&condp->mutex);
	    /* We now own the condpair object */
	    count = perl_call_sv(code, G_SCALAR|G_NOARGS|G_EVAL);
	    SPAGAIN;
	    /* Release condpair object */
	    MUTEX_LOCK(&condp->mutex);
	    condp->owner = 0;
	    MUTEX_UNLOCK(&condp->mutex);
	    /* See if we need to go round again */	
	    if (count == 0)
		croak(SvPV(GvSV(gv_fetchpv("@", TRUE, SVt_PV)), na));
	    else if (count > 1)
		croak("waituntil code returned more than one value");
	    sv = POPs;
	    PUTBACK;
	} while (!SvTRUE(sv));
	ST(0) = sv_mortalcopy(sv);

void
signal(cond, code)
	Thread::Cond	cond
	SV *		code
    CODE:
	condpair_kick(cond, code, 0);

void
broadcast(cond, code)
	Thread::Cond	cond
	SV *		code
    CODE:
	condpair_kick(cond, code, 1);

