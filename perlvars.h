/****************/
/* Truly global */
/****************/

/* Don't forget to re-run embed.pl to propagate changes! */

/* This file describes the "global" variables used by perl
 * This used to be in perl.h directly but we want to abstract out into
 * distinct files which are per-thread, per-interpreter or really global,
 * and how they're initialized.
 *
 * The 'G' prefix is only needed for vars that need appropriate #defines
 * generated in embed*.h.  Such symbols are also used to generate
 * the appropriate export list for win32.
 *
 * Avoid build-specific #ifdefs here, like DEBUGGING.  That way,
 * we can keep binary compatibility of the curinterp structure */


/* global state */
PERLVAR(Gcurinterp,	PerlInterpreter *)
					/* currently running interpreter */
#ifdef USE_THREADS
PERLVAR(Gthr_key,	perl_key)	/* For per-thread struct perl_thread* */
PERLVAR(Gsv_mutex,	perl_mutex)	/* Mutex for allocating SVs in sv.c */
PERLVAR(Gmalloc_mutex,	perl_mutex)	/* Mutex for malloc */
PERLVAR(Geval_mutex,	perl_mutex)	/* Mutex for doeval */
PERLVAR(Geval_cond,	perl_cond)	/* Condition variable for doeval */
PERLVAR(Geval_owner,	struct perl_thread *)
					/* Owner thread for doeval */
PERLVAR(Gnthreads,	int)		/* Number of threads currently */
PERLVAR(Gthreads_mutex,	perl_mutex)	/* Mutex for nthreads and thread list */
PERLVAR(Gnthreads_cond,	perl_cond)	/* Condition variable for nthreads */
PERLVAR(Gsvref_mutex,	perl_mutex)	/* Mutex for SvREFCNT_{inc,dec} */
PERLVARI(Gthreadsv_names,char *,	THREADSV_NAMES)
#ifdef FAKE_THREADS
PERLVAR(Gcurthr,	struct perl_thread *)
					/* Currently executing (fake) thread */
#endif

PERLVAR(Gcred_mutex,	perl_mutex)	/* altered credentials in effect */

#endif /* USE_THREADS */

PERLVAR(Gninterps,	int)		/* number of active interpreters */
PERLVARI(Gdo_undump,	bool,	FALSE)	/* -u or dump seen? */

/* constants (these are not literals to facilitate pointer comparisons) */
PERLVARIC(GYes,		char *, "1")
PERLVARIC(GNo,		char *, "")
PERLVARIC(Ghexdigit,	char *, "0123456789abcdef0123456789ABCDEF")
PERLVARIC(Gpatleave,	char *, "\\.^$@dDwWsSbB+*?|()-nrtfeaxc0123456789[{]}")
