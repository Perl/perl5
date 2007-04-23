#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
#ifdef I_UNISTD
#include <unistd.h>
#endif
#endif
#include <fcntl.h>
                        
static int sig_pipe[2];
            
#ifndef THREAD_RET_TYPE
#define THREAD_RET_TYPE void *
#define THREAD_RET_CAST(x) ((THREAD_RET_TYPE) x)
#endif

static void
remove_thread(pTHX_ Thread t)
{
}

static THREAD_RET_TYPE
threadstart(void *arg)
{
    return THREAD_RET_CAST(NULL);
}

static SV *
newthread (pTHX_ SV *startsv, AV *initargs, char *classname)
{
#ifdef USE_ITHREADS
    croak("This perl was built for \"ithreads\", which currently does not support Thread.pm.\n"
	  "Run \"perldoc Thread\" for more information");
#else
    croak("This perl was not built with support for 5.005-style threads.\n"
	  "Run \"perldoc Thread\" for more information");
#endif
  return &PL_sv_undef;
}

static Signal_t handle_thread_signal (int sig);

static Signal_t
handle_thread_signal(int sig)
{
    unsigned char c = (unsigned char) sig;
    dTHX;
    /*
     * We're not really allowed to call fprintf in a signal handler
     * so don't be surprised if this isn't robust while debugging
     * with -DL.
     */
    DEBUG_S(PerlIO_printf(Perl_debug_log,
	    "handle_thread_signal: got signal %d\n", sig));
    write(sig_pipe[1], &c, 1);
}

MODULE = Thread		PACKAGE = Thread
PROTOTYPES: DISABLE

void
new(classname, startsv, ...)
	char *		classname
	SV *		startsv
	AV *		av = av_make(items - 2, &ST(2));
    PPCODE:
	XPUSHs(sv_2mortal(newthread(aTHX_ startsv, av, classname)));

void
join(t)
	Thread	t
    PREINIT:
#ifdef USE_5005THREADS
	AV *	av;
	int	i;
#endif
    PPCODE:

void
detach(t)
	Thread	t
    CODE:

void
equal(t1, t2)
	Thread	t1
	Thread	t2
    PPCODE:
	PUSHs((t1 == t2) ? &PL_sv_yes : &PL_sv_no);

void
flags(t)
	Thread	t
    PPCODE:

void
done(t)
	Thread	t
    PPCODE:

void
self(classname)
	char *	classname
    PREINIT:
#ifdef USE_5005THREADS
	SV *sv;
#endif
    PPCODE:        

U32
tid(t)
	Thread	t
    CODE:
	RETVAL = 0;
    OUTPUT:
	RETVAL

void
DESTROY(t)
	SV *	t
    PPCODE:
	PUSHs(t ? &PL_sv_yes : &PL_sv_no);

void
yield()
    CODE:

void
cond_wait(sv)
	SV *	sv
CODE:                       

void
cond_signal(sv)
	SV *	sv
CODE:

void
cond_broadcast(sv)
	SV *	sv
CODE: 

void
list(classname)
	char *	classname
    PPCODE:


MODULE = Thread		PACKAGE = Thread::Signal

void
kill_sighandler_thread()
    PPCODE:
	write(sig_pipe[1], "\0", 1);
	PUSHs(&PL_sv_yes);

void
init_thread_signals()
    PPCODE:
	PL_sighandlerp = handle_thread_signal;
	if (pipe(sig_pipe) == -1)
	    XSRETURN_UNDEF;
	PUSHs(&PL_sv_yes);

void
await_signal()
    PREINIT:
	unsigned char c;
	SSize_t ret;
    CODE:
	do {
	    ret = read(sig_pipe[0], &c, 1);
	} while (ret == -1 && errno == EINTR);
	if (ret == -1)
	    croak("panic: await_signal");
	ST(0) = sv_newmortal();
	if (ret)
	    sv_setsv(ST(0), c ? PL_psig_ptr[c] : &PL_sv_no);
	DEBUG_S(PerlIO_printf(Perl_debug_log,
			      "await_signal returning %s\n", SvPEEK(ST(0))));

MODULE = Thread		PACKAGE = Thread::Specific

void
data(classname = "Thread::Specific")
	char *	classname
    PPCODE:
