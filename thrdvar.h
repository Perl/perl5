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

PERLVAR(TSv,	SV *)		
PERLVAR(TXpv,	XPV *)		
PERLVAR(Tstatbuf,	struct stat)		
#ifdef HAS_TIMES
PERLVAR(Ttimesbuf,	struct tms)		
#endif
    
/* XXX What about regexp stuff? */

/* Now the fields that used to be "per interpreter" (even when global) */

/* Fields used by magic variables such as $@, $/ and so on */
PERLVAR(Ttainted,	bool)		
PERLVAR(Tcurpm,		PMOP *)		
PERLVAR(Tnrs,		SV *)		
PERLVAR(Trs,		SV *)		
PERLVAR(Tlast_in_gv,	GV *)		
PERLVAR(Tofs,		char *)		
PERLVAR(Tofslen,	STRLEN)		
PERLVAR(Tdefoutgv,	GV *)		
PERLVAR(Tchopset,	char *)		
PERLVAR(Tformtarget,	SV *)		
PERLVAR(Tbodytarget,	SV *)		
PERLVAR(Ttoptarget,	SV *)		

    /* Stashes */
PERLVAR(Tdefstash,	HV *)		
PERLVAR(Tcurstash,	HV *)		

    /* Stacks */
PERLVAR(Ttmps_stack,	SV **)		
PERLVAR(Ttmps_ix,	I32)		
PERLVAR(Ttmps_floor,	I32)		
PERLVAR(Ttmps_max,	I32)		

PERLVAR(Tin_eval,	int)		
PERLVAR(Trestartop,	OP *)		
PERLVAR(Tdelaymagic,	int)		
PERLVAR(Tdirty,		bool)		
PERLVAR(Tlocalizing,	U8)		
PERLVAR(Tcurcop,	COP *)		

PERLVAR(Tcxstack,	PERL_CONTEXT *)		
PERLVAR(Tcxstack_ix,	I32)		
PERLVAR(Tcxstack_max,	I32)		

PERLVAR(Tcurstack,	AV *)		
PERLVAR(Tmainstack,	AV *)		
PERLVAR(Ttop_env,	JMPENV *)		
PERLVAR(Tstart_env,	JMPENV)			/* Top of top_env longjmp() chain */

/* XXX Sort stuff, firstgv secongv and so on? */

PERLVAR(oursv,		SV *)		
PERLVAR(cvcache,	HV *)		
PERLVAR(self,		perl_os_thread)		/* Underlying thread object */
PERLVAR(flags,		U32)		
PERLVAR(threadsv,	AV *)			/* Per-thread SVs ($_, $@ etc.) */
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

