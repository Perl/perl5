/* Per-thread variables */
/* Important ones in the first cache line (if alignment is done right) */

PERLVAR(Tstack_sp,	SV **)		
#ifdef OP_IN_REGISTER
PERLVAR(Topsave,	OP *)		
#else
PERLVAR(Top,		OP *)		
#endif
PERLVAR(Tcurpad,	SV **)		

PERLVAR(Tstack_base,	SV **)		
PERLVAR(Tstack_max,	SV **)		

PERLVAR(Tscopestack,	I32 *)		
PERLVAR(Tscopestack_ix,	I32)		
PERLVAR(Tscopestack_max,I32)		

PERLVAR(Tsavestack,	ANY *)		
PERLVAR(Tsavestack_ix,	I32)		
PERLVAR(Tsavestack_max,	I32)		

PERLVAR(Tretstack,	OP **)		
PERLVAR(Tretstack_ix,	I32)		
PERLVAR(Tretstack_max,	I32)		

PERLVAR(Tmarkstack,	I32 *)		
PERLVAR(Tmarkstack_ptr,	I32 *)		
PERLVAR(Tmarkstack_max,	I32 *)		

PERLVAR(TSv,		SV *)		
PERLVAR(TXpv,		XPV *)		
PERLVAR(Tstatbuf,	Stat_t)		
#ifdef HAS_TIMES
PERLVAR(Ttimesbuf,	struct tms)		
#endif
    
/* Now the fields that used to be "per interpreter" (even when global) */

/* Fields used by magic variables such as $@, $/ and so on */
PERLVAR(Ttainted,	bool)		/* using variables controlled by $< */
PERLVAR(Tcurpm,		PMOP *)		/* what to do \ interps from */
PERLVAR(Tnrs,		SV *)		
PERLVAR(Trs,		SV *)		/* $/ */
PERLVAR(Tlast_in_gv,	GV *)		
PERLVAR(Tofs,		char *)		/* $, */
PERLVAR(Tofslen,	STRLEN)		
PERLVAR(Tdefoutgv,	GV *)		
PERLVARI(Tchopset,	char *,	" \n-")	/* $: */
PERLVAR(Tformtarget,	SV *)		
PERLVAR(Tbodytarget,	SV *)		
PERLVAR(Ttoptarget,	SV *)		

/* Stashes */
PERLVAR(Tdefstash,	HV *)		/* main symbol table */
PERLVAR(Tcurstash,	HV *)		/* symbol table for current package */

/* Stacks */
PERLVAR(Ttmps_stack,	SV **)		
PERLVARI(Ttmps_ix,	I32,	-1)	
PERLVARI(Ttmps_floor,	I32,	-1)	
PERLVAR(Ttmps_max,	I32)		

PERLVAR(Trestartop,	OP *)		/* Are we propagating an error from croak? */
PERLVARI(Tcurcop,	COP * VOL,	&compiling)	
PERLVAR(Tin_eval,	VOL int)	/* trap "fatal" errors? */
PERLVAR(Tdelaymagic,	int)		/* ($<,$>) = ... */
PERLVAR(Tdirty,		bool)		/* In the middle of tearing things down? */
PERLVAR(Tlocalizing,	int)		/* are we processing a local() list? */

PERLVAR(Tcurstack,	AV *)			/* THE STACK */
PERLVAR(Tcurstackinfo,	PERL_SI *)		/* current stack + context */
PERLVAR(Tmainstack,	AV *)			/* the stack when nothing funny is happening */
PERLVAR(Ttop_env,	JMPENV *)		/* ptr. to current sigjmp() environment */
PERLVAR(Tstart_env,	JMPENV)			/* empty startup sigjmp() environment */

/* statics "owned" by various functions */
PERLVAR(Tav_fetch_sv,	SV *)
PERLVAR(Thv_fetch_sv,	SV *)
PERLVAR(Thv_fetch_ent_mh, HE)

/* XXX Sort stuff, firstgv secongv and so on? */
/* XXX What about regexp stuff? */

#ifdef USE_THREADS

PERLVAR(oursv,		SV *)		
PERLVAR(cvcache,	HV *)		
PERLVAR(self,		perl_os_thread)		/* Underlying thread object */
PERLVAR(flags,		U32)		
PERLVAR(threadsv,	AV *)			/* Per-thread SVs ($_, $@ etc.) */
PERLVAR(threadsvp,	SV **)			/* AvARRAY(threadsv) */
PERLVAR(specific,	AV *)			/* Thread-specific user data */
PERLVAR(errsv,		SV *)			/* Backing SV for $@ */
PERLVAR(errhv,		HV *)			/* HV for what was %@ in pp_ctl.c */
PERLVAR(mutex,		perl_mutex)		/* For the fields others can change */
PERLVAR(tid,		U32)		
PERLVAR(prev,		struct perl_thread *)
PERLVAR(next,		struct perl_thread *)	/* Circular linked list of threads */

#ifdef HAVE_THREAD_INTERN
PERLVAR(i,		struct thread_intern)	/* Platform-dependent internals */
#endif

PERLVAR(trailing_nul,	char)			/* For the sake of thrsv and oursv */

#endif /* USE_THREADS */
