/***********************************************/
/* Global only to current interpreter instance */
/***********************************************/

/* Don't forget to re-run embed.pl to propagate changes! */

/* The 'I' prefix is only needed for vars that need appropriate #defines
 * generated when built with or without MULTIPLICITY.  It is also used
 * to generate the appropriate export list for win32.
 *
 * When building without MULTIPLICITY, these variables will be truly global.
 *
 * Avoid build-specific #ifdefs here, like DEBUGGING.  That way,
 * we can keep binary compatibility of the curinterp structure */

/* pseudo environmental stuff */
PERLVAR(Iorigargc,	int)
PERLVAR(Iorigargv,	char **)
PERLVAR(Ienvgv,		GV *)
PERLVAR(Isiggv,		GV *)
PERLVAR(Iincgv,		GV *)
PERLVAR(Ihintgv,	GV *)
PERLVAR(Iorigfilename,	char *)
PERLVAR(Idiehook,	SV *)
PERLVAR(Iwarnhook,	SV *)
PERLVAR(Iparsehook,	SV *)
PERLVAR(Icddir,		char *)		/* switches */
PERLVAR(Iminus_c,	bool)
PERLVARA(Ipatchlevel,10,char)
PERLVAR(Ilocalpatches,	char **)
PERLVARI(Isplitstr,	char *,	" ")
PERLVAR(Ipreprocess,	bool)
PERLVAR(Iminus_n,	bool)
PERLVAR(Iminus_p,	bool)
PERLVAR(Iminus_l,	bool)
PERLVAR(Iminus_a,	bool)
PERLVAR(Iminus_F,	bool)
PERLVAR(Idoswitches,	bool)
PERLVAR(Idowarn,	bool)
PERLVAR(Idoextract,	bool)
PERLVAR(Isawampersand,	bool)		/* must save all match strings */
PERLVAR(Isawstudy,	bool)		/* do fbm_instr on all strings */
PERLVAR(Isawvec,	bool)
PERLVAR(Iunsafe,	bool)
PERLVAR(Iinplace,	char *)
PERLVAR(Ie_script,	SV *)
PERLVAR(Iperldb,	U32)

/* This value may be raised by extensions for testing purposes */
/* 0=none, 1=full, 2=full with checks */
PERLVARI(Iperl_destruct_level,	int,	0)

/* magical thingies */
PERLVAR(Ibasetime,	Time_t)		/* $^T */
PERLVAR(Iformfeed,	SV *)		/* $^L */


PERLVARI(Imaxsysfd,	I32,	MAXSYSFD)
					/* top fd to pass to subprocesses */
PERLVAR(Imultiline,	int)		/* $*--do strings hold >1 line? */
PERLVAR(Istatusvalue,	I32)		/* $? */
#ifdef VMS
PERLVAR(Istatusvalue_vms,U32)
#endif

/* shortcuts to various I/O objects */
PERLVAR(Istdingv,	GV *)
PERLVAR(Idefgv,		GV *)
PERLVAR(Iargvgv,	GV *)
PERLVAR(Iargvoutgv,	GV *)

/* shortcuts to regexp stuff */
/* XXX these three aren't used anywhere */
PERLVAR(Ileftgv,	GV *)
PERLVAR(Iampergv,	GV *)
PERLVAR(Irightgv,	GV *)

/* this one needs to be moved to thrdvar.h and accessed via
 * find_threadsv() when USE_THREADS */
PERLVAR(Ireplgv,	GV *)

/* shortcuts to misc objects */
PERLVAR(Ierrgv,		GV *)

/* shortcuts to debugging objects */
PERLVAR(IDBgv,		GV *)
PERLVAR(IDBline,	GV *)
PERLVAR(IDBsub,		GV *)
PERLVAR(IDBsingle,	SV *)
PERLVAR(IDBtrace,	SV *)
PERLVAR(IDBsignal,	SV *)
PERLVAR(Ilineary,	AV *)		/* lines of script for debugger */
PERLVAR(Idbargs,	AV *)		/* args to call listed by caller function */

/* symbol tables */
PERLVAR(Idebstash,	HV *)		/* symbol table for perldb package */
PERLVAR(Iglobalstash,	HV *)		/* global keyword overrides imported here */
PERLVAR(Icurstname,	SV *)		/* name of current package */
PERLVAR(Ibeginav,	AV *)		/* names of BEGIN subroutines */
PERLVAR(Iendav,		AV *)		/* names of END subroutines */
PERLVAR(Iinitav,	AV *)		/* names of INIT subroutines */
PERLVAR(Istrtab,	HV *)		/* shared string table */
PERLVARI(Isub_generation,U32,1)		/* incr to invalidate method cache */

/* memory management */
PERLVAR(Isv_count,	I32)		/* how many SV* are currently allocated */
PERLVAR(Isv_objcount,	I32)		/* how many objects are currently allocated */
PERLVAR(Isv_root,	SV*)		/* storage for SVs belonging to interp */
PERLVAR(Isv_arenaroot,	SV*)		/* list of areas for garbage collection */

/* funky return mechanisms */
PERLVAR(Ilastspbase,	I32)
PERLVAR(Ilastsize,	I32)
PERLVAR(Iforkprocess,	int)		/* so do_open |- can return proc# */

/* subprocess state */
PERLVAR(Ifdpid,		AV *)		/* keep fd-to-pid mappings for my_popen */

/* internal state */
PERLVAR(Itainting,	bool)		/* doing taint checks */
PERLVARI(Iop_mask,	char *,	NULL)	/* masked operations for safe evals */

/* trace state */
PERLVAR(Idlevel,	I32)
PERLVARI(Idlmax,	I32,	128)
PERLVAR(Idebname,	char *)
PERLVAR(Idebdelim,	char *)

/* current interpreter roots */
PERLVAR(Imain_cv,	CV *)
PERLVAR(Imain_root,	OP *)
PERLVAR(Imain_start,	OP *)
PERLVAR(Ieval_root,	OP *)
PERLVAR(Ieval_start,	OP *)

/* runtime control stuff */
PERLVARI(Icurcopdb,	COP *,	NULL)
PERLVARI(Icopline,	line_t,	NOLINE)

/* statics moved here for shared library purposes */
PERLVAR(Istrchop,	SV)		/* return value from chop */
PERLVAR(Ifilemode,	int)		/* so nextargv() can preserve mode */
PERLVAR(Ilastfd,	int)		/* what to preserve mode on */
PERLVAR(Ioldname,	char *)		/* what to preserve mode on */
PERLVAR(IArgv,		char **)	/* stuff to free from do_aexec, vfork safe */
PERLVAR(ICmd,		char *)		/* stuff to free from do_aexec, vfork safe */
PERLVAR(Imystrk,	SV *)		/* temp key string for do_each() */
PERLVAR(Ioldlastpm,	PMOP *)		/* for saving regexp context in debugger */
PERLVAR(Igensym,	I32)		/* next symbol for getsym() to define */
PERLVAR(Ipreambled,	bool)
PERLVAR(Ipreambleav,	AV *)
PERLVARI(Ilaststatval,	int,	-1)
PERLVARI(Ilaststype,	I32,	OP_STAT)
PERLVAR(Imess_sv,	SV *)

/* XXX shouldn't these be per-thread? --GSAR */
PERLVAR(Iors,		char *)		/* output record separator $\ */
PERLVAR(Iorslen,	STRLEN)
PERLVAR(Iofmt,		char *)		/* output format for numbers $# */

/* interpreter atexit processing */
PERLVARI(Iexitlist,	PerlExitListEntry *, NULL)
					/* list of exit functions */
PERLVARI(Iexitlistlen,	I32, 0)		/* length of same */
PERLVAR(Imodglobal,	HV *)		/* per-interp module data */

/* these used to be in global before 5.004_68 */
PERLVARI(Iprofiledata,	U32 *,	NULL)	/* table of ops, counts */
PERLVARI(Irsfp,	PerlIO * VOL,	Nullfp) /* current source file pointer */
PERLVARI(Irsfp_filters,	AV *,	Nullav)	/* keeps active source filters */

PERLVAR(Icompiling,	COP)		/* compiling/done executing marker */

PERLVAR(Icompcv,	CV *)		/* currently compiling subroutine */
PERLVAR(Icomppad,	AV *)		/* storage for lexically scoped temporaries */
PERLVAR(Icomppad_name,	AV *)		/* variable names for "my" variables */
PERLVAR(Icomppad_name_fill,	I32)	/* last "introduced" variable offset */
PERLVAR(Icomppad_name_floor,	I32)	/* start of vars in innermost block */

#ifdef HAVE_INTERP_INTERN
PERLVAR(Isys_intern,	struct interp_intern)
					/* platform internals */
#endif

/* more statics moved here */
PERLVARI(Igeneration,	int,	100)	/* from op.c */
PERLVAR(IDBcv,		CV *)		/* from perl.c */
PERLVAR(Iarchpat_auto,	char*)		/* from perl.c */

PERLVARI(Iin_clean_objs,bool,    FALSE)	/* from sv.c */
PERLVARI(Iin_clean_all,	bool,    FALSE)	/* from sv.c */

PERLVAR(Ilinestart,	char *)		/* beg. of most recently read line */
PERLVAR(Ipending_ident,	char)		/* pending identifier lookup */
PERLVAR(Isublex_info,	SUBLEXINFO)	/* from toke.c */

#ifdef USE_THREADS
PERLVAR(Ithrsv,		SV *)		/* struct perl_thread for main thread */
PERLVARI(Ithreadnum,	U32,	0)	/* incremented each thread creation */
PERLVAR(Istrtab_mutex,	perl_mutex)	/* Mutex for string table access */
#endif /* USE_THREADS */

PERLVAR(Iuid,		Uid_t)		/* current real user id */
PERLVAR(Ieuid,		Uid_t)		/* current effective user id */
PERLVAR(Igid,		Gid_t)		/* current real group id */
PERLVAR(Iegid,		Gid_t)		/* current effective group id */
PERLVAR(Inomemok,	bool)		/* let malloc context handle nomem */
PERLVAR(Ian,		U32)		/* malloc sequence number */
PERLVAR(Icop_seqmax,	U32)		/* statement sequence number */
PERLVAR(Iop_seqmax,	U16)		/* op sequence number */
PERLVAR(Ievalseq,	U32)		/* eval sequence number */
PERLVAR(Iorigenviron,	char **)
PERLVAR(Iorigalen,	U32)
PERLVAR(Ipidstatus,	HV *)		/* pid-to-status mappings for waitpid */
PERLVARI(Imaxo,	int,	MAXO)		/* maximum number of ops */
PERLVAR(Iosname,	char *)		/* operating system */
PERLVARI(Ish_path,	char *,	SH_PATH)/* full path of shell */
PERLVAR(Isighandlerp,	Sighandler_t)

PERLVAR(Ixiv_arenaroot,	XPV*)		/* list of allocated xiv areas */
PERLVAR(Ixiv_root,	IV *)		/* free xiv list--shared by interpreters */
PERLVAR(Ixnv_root,	NV *)		/* free xnv list--shared by interpreters */
PERLVAR(Ixrv_root,	XRV *)		/* free xrv list--shared by interpreters */
PERLVAR(Ixpv_root,	XPV *)		/* free xpv list--shared by interpreters */
PERLVAR(Ihe_root,	HE *)		/* free he list--shared by interpreters */
PERLVAR(Inice_chunk,	char *)		/* a nice chunk of memory to reuse */
PERLVAR(Inice_chunk_size,	U32)	/* how nice the chunk of memory is */

PERLVARI(Irunops,	runops_proc_t,	MEMBER_TO_FPTR(RUNOPS_DEFAULT))

PERLVARA(Itokenbuf,256,	char)

PERLVAR(Isv_undef,	SV)
PERLVAR(Isv_no,		SV)
PERLVAR(Isv_yes,	SV)

#ifdef CSH
PERLVARI(Icshname,	char *,	CSH)
PERLVAR(Icshlen,	I32)
#endif

PERLVAR(Ilex_state,	U32)		/* next token is determined */
PERLVAR(Ilex_defer,	U32)		/* state after determined token */
PERLVAR(Ilex_expect,	expectation)	/* expect after determined token */
PERLVAR(Ilex_brackets,	I32)		/* bracket count */
PERLVAR(Ilex_formbrack,	I32)		/* bracket count at outer format level */
PERLVAR(Ilex_fakebrack,	I32)		/* outer bracket is mere delimiter */
PERLVAR(Ilex_casemods,	I32)		/* casemod count */
PERLVAR(Ilex_dojoin,	I32)		/* doing an array interpolation */
PERLVAR(Ilex_starts,	I32)		/* how many interps done on level */
PERLVAR(Ilex_stuff,	SV *)		/* runtime pattern from m// or s/// */
PERLVAR(Ilex_repl,	SV *)		/* runtime replacement from s/// */
PERLVAR(Ilex_op,	OP *)		/* extra info to pass back on op */
PERLVAR(Ilex_inpat,	OP *)		/* in pattern $) and $| are special */
PERLVAR(Ilex_inwhat,	I32)		/* what kind of quoting are we in */
PERLVAR(Ilex_brackstack,char *)		/* what kind of brackets to pop */
PERLVAR(Ilex_casestack,	char *)		/* what kind of case mods in effect */

/* What we know when we're in LEX_KNOWNEXT state. */
PERLVARA(Inextval,5,	YYSTYPE)	/* value of next token, if any */
PERLVARA(Inexttype,5,	I32)		/* type of next token */
PERLVAR(Inexttoke,	I32)

PERLVAR(Ilinestr,	SV *)
PERLVAR(Ibufptr,	char *)
PERLVAR(Ioldbufptr,	char *)
PERLVAR(Ioldoldbufptr,	char *)
PERLVAR(Ibufend,	char *)
PERLVARI(Iexpect,expectation,	XSTATE)	/* how to interpret ambiguous tokens */

PERLVAR(Imulti_start,	I32)		/* 1st line of multi-line string */
PERLVAR(Imulti_end,	I32)		/* last line of multi-line string */
PERLVAR(Imulti_open,	I32)		/* delimiter of said string */
PERLVAR(Imulti_close,	I32)		/* delimiter of said string */

PERLVAR(Ierror_count,	I32)		/* how many errors so far, max 10 */
PERLVAR(Isubline,	I32)		/* line this subroutine began on */
PERLVAR(Isubname,	SV *)		/* name of current subroutine */

PERLVAR(Imin_intro_pending,	I32)	/* start of vars to introduce */
PERLVAR(Imax_intro_pending,	I32)	/* end of vars to introduce */
PERLVAR(Ipadix,		I32)		/* max used index in current "register" pad */
PERLVAR(Ipadix_floor,	I32)		/* how low may inner block reset padix */
PERLVAR(Ipad_reset_pending,	I32)	/* reset pad on next attempted alloc */

PERLVAR(Ithisexpr,	I32)		/* name id for nothing_in_common() */
PERLVAR(Ilast_uni,	char *)		/* position of last named-unary op */
PERLVAR(Ilast_lop,	char *)		/* position of last list operator */
PERLVAR(Ilast_lop_op,	OPCODE)		/* last list operator */
PERLVAR(Iin_my,		bool)		/* we're compiling a "my" declaration */
PERLVAR(Iin_my_stash,	HV *)		/* declared class of this "my" declaration */
#ifdef FCRYPT
PERLVAR(Icryptseen,	I32)		/* has fast crypt() been initialized? */
#endif

PERLVAR(Ihints,	U32)			/* pragma-tic compile-time flags */

PERLVAR(Idebug,		VOL U32)	/* flags given to -D switch */

PERLVAR(Iamagic_generation,	long)

#ifdef USE_LOCALE_COLLATE
PERLVAR(Icollation_ix,	U32)		/* Collation generation index */
PERLVAR(Icollation_name,char *)		/* Name of current collation */
PERLVARI(Icollation_standard, bool,	TRUE)
					/* Assume simple collation */
PERLVAR(Icollxfrm_base,	Size_t)		/* Basic overhead in *xfrm() */
PERLVARI(Icollxfrm_mult,Size_t,	2)	/* Expansion factor in *xfrm() */
#endif /* USE_LOCALE_COLLATE */

#ifdef USE_LOCALE_NUMERIC

PERLVAR(Inumeric_name,	char *)		/* Name of current numeric locale */
PERLVARI(Inumeric_standard,	bool,	TRUE)
					/* Assume simple numerics */
PERLVARI(Inumeric_local,	bool,	TRUE)
					/* Assume local numerics */
PERLVAR(Inumeric_radix,		char)
					/* The radix character if not '.' */

#endif /* !USE_LOCALE_NUMERIC */

/* utf8 character classes */
PERLVAR(Iutf8_alnum,	SV *)
PERLVAR(Iutf8_alnumc,	SV *)
PERLVAR(Iutf8_ascii,	SV *)
PERLVAR(Iutf8_alpha,	SV *)
PERLVAR(Iutf8_space,	SV *)
PERLVAR(Iutf8_cntrl,	SV *)
PERLVAR(Iutf8_graph,	SV *)
PERLVAR(Iutf8_digit,	SV *)
PERLVAR(Iutf8_upper,	SV *)
PERLVAR(Iutf8_lower,	SV *)
PERLVAR(Iutf8_print,	SV *)
PERLVAR(Iutf8_punct,	SV *)
PERLVAR(Iutf8_xdigit,	SV *)
PERLVAR(Iutf8_mark,	SV *)
PERLVAR(Iutf8_toupper,	SV *)
PERLVAR(Iutf8_totitle,	SV *)
PERLVAR(Iutf8_tolower,	SV *)
PERLVAR(Ilast_swash_hv,	HV *)
PERLVAR(Ilast_swash_klen,	U32)
PERLVARA(Ilast_swash_key,10,	U8)
PERLVAR(Ilast_swash_tmps,	U8 *)
PERLVAR(Ilast_swash_slen,	STRLEN)

/* perly.c globals */
PERLVAR(Iyydebug,	int)
PERLVAR(Iyynerrs,	int)
PERLVAR(Iyyerrflag,	int)
PERLVAR(Iyychar,	int)
PERLVAR(Iyyval,		YYSTYPE)
PERLVAR(Iyylval,	YYSTYPE)

PERLVAR(Iglob_index,	int)
PERLVAR(Iefloatbuf,	char*)
PERLVAR(Iefloatsize,	STRLEN)
PERLVAR(Isrand_called,	bool)
PERLVARA(Iuudmap,256,	char)
PERLVAR(Ibitcount,	char *)
PERLVAR(Ifilter_debug,	int)

#ifdef USE_THREADS
PERLVAR(Ithr_key,	perl_key)	/* For per-thread struct perl_thread* */
PERLVAR(Isv_mutex,	perl_mutex)	/* Mutex for allocating SVs in sv.c */
PERLVAR(Imalloc_mutex,	perl_mutex)	/* Mutex for malloc */
PERLVAR(Ieval_mutex,	perl_mutex)	/* Mutex for doeval */
PERLVAR(Ieval_cond,	perl_cond)	/* Condition variable for doeval */
PERLVAR(Ieval_owner,	struct perl_thread *)
					/* Owner thread for doeval */
PERLVAR(Inthreads,	int)		/* Number of threads currently */
PERLVAR(Ithreads_mutex,	perl_mutex)	/* Mutex for nthreads and thread list */
PERLVAR(Inthreads_cond,	perl_cond)	/* Condition variable for nthreads */
PERLVAR(Isvref_mutex,	perl_mutex)	/* Mutex for SvREFCNT_{inc,dec} */
PERLVARI(Ithreadsv_names,char *,	THREADSV_NAMES)
#ifdef FAKE_THREADS
PERLVAR(Icurthr,	struct perl_thread *)
					/* Currently executing (fake) thread */
#endif

PERLVAR(Icred_mutex,	perl_mutex)	/* altered credentials in effect */

#endif /* USE_THREADS */

#if defined(PERL_IMPLICIT_SYS)
PERLVARI(IMem,		struct IPerlMem*,  NULL)
PERLVARI(IEnv,		struct IPerlEnv*,  NULL)
PERLVARI(IStdIO,	struct IPerlStdIO*, NULL)
PERLVARI(ILIO,		struct IPerlLIO*,  NULL)
PERLVARI(IDir,		struct IPerlDir*,  NULL)
PERLVARI(ISock,		struct IPerlSock*, NULL)
PERLVARI(IProc,		struct IPerlProc*, NULL)
#endif
