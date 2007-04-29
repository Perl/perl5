/***********************************************/
/* Global only to current interpreter instance */
/***********************************************/

/* Don't forget to re-run embed.pl to propagate changes! */

/* New variables must be added to the very end for binary compatibility.
 * XSUB.h provides wrapper functions via perlapi.h that make this
 * irrelevant, but not all code may be expected to #include XSUB.h. */

/* Don't forget to add your variable also to perl_clone()! */

/* The 'I' prefix is only needed for vars that need appropriate #defines
 * generated when built with or without MULTIPLICITY.  It is also used
 * to generate the appropriate export list for win32.
 *
 * When building without MULTIPLICITY, these variables will be truly global. */


/* For historical reasons this file follows thrdvar.h into the interpeter
   struct, and that file currently ends with 7 bytes of variables, so putting
   one last byte here is good for alignment.  */

/* This value may be set when embedding for full cleanup  */
/* 0=none, 1=full, 2=full with checks */
PERLVARI(Iperl_destruct_level,	U8,	0)

PERLVAR(Iperldb,	U32)

/* pseudo environmental stuff */
PERLVAR(Iorigargc,	int)
PERLVAR(Iorigargv,	char **)
PERLVAR(Ienvgv,		GV *)
PERLVAR(Iincgv,		GV *)
PERLVAR(Ihintgv,	GV *)
PERLVAR(Iorigfilename,	char *)
PERLVAR(Idiehook,	SV *)
PERLVAR(Iwarnhook,	SV *)

/* switches */
PERLVAR(Ipatchlevel,	SV *)
PERLVAR(Ilocalpatches,	const char * const *)
PERLVARI(Isplitstr,	const char *, " ")

PERLVAR(Iminus_c,	bool)
PERLVAR(Ipreprocess,	bool)
PERLVAR(Iminus_n,	bool)
PERLVAR(Iminus_p,	bool)
PERLVAR(Iminus_l,	bool)
PERLVAR(Iminus_a,	bool)
PERLVAR(Iminus_F,	bool)
PERLVAR(Idoswitches,	bool)

PERLVAR(Iminus_E,	bool)

/*
=head1 Global Variables

=for apidoc mn|bool|PL_dowarn

The C variable which corresponds to Perl's $^W warning variable.

=cut
*/

PERLVAR(Idowarn,	U8)
PERLVAR(Idoextract,	bool)
PERLVAR(Isawampersand,	bool)		/* must save all match strings */
PERLVAR(Iunsafe,	bool)
PERLVAR(Iexit_flags,	U8)		/* was exit() unexpected, etc. */
PERLVAR(Isrand_called,	bool)
/* Part of internal state, but makes the 16th 1 byte variable in a row.  */
PERLVAR(Itainting,	bool)		/* doing taint checks */
PERLVAR(Iinplace,	char *)
PERLVAR(Ie_script,	SV *)

/* magical thingies */
PERLVAR(Ibasetime,	Time_t)		/* $^T */
PERLVAR(Iformfeed,	SV *)		/* $^L */


PERLVARI(Imaxsysfd,	I32,	MAXSYSFD)
					/* top fd to pass to subprocesses */
PERLVAR(Istatusvalue,	I32)		/* $? */
#ifdef VMS
PERLVAR(Istatusvalue_vms,U32)
#else
PERLVAR(Istatusvalue_posix,I32)
#endif

#ifdef CSH
PERLVARI(Icshlen,	I32,	0)
PERLVARI(Icshname,	const char *,	CSH)
#endif

/* shortcuts to various I/O objects */
PERLVAR(Istdingv,	GV *)
PERLVAR(Istderrgv,	GV *)
PERLVAR(Idefgv,		GV *)
PERLVAR(Iargvgv,	GV *)
PERLVAR(Iargvoutgv,	GV *)
PERLVAR(Iargvout_stack,	AV *)

/* shortcuts to regexp stuff */
/* this one needs to be moved to thrdvar.h and accessed via
 * find_threadsv() when USE_5005THREADS */
PERLVAR(Ireplgv,	GV *)

/* shortcuts to misc objects */
PERLVAR(Ierrgv,		GV *)

/* shortcuts to debugging objects */
PERLVAR(IDBgv,		GV *)
PERLVAR(IDBline,	GV *)

/*
=for apidoc mn|GV *|PL_DBsub
When Perl is run in debugging mode, with the B<-d> switch, this GV contains
the SV which holds the name of the sub being debugged.  This is the C
variable which corresponds to Perl's $DB::sub variable.  See
C<PL_DBsingle>.

=for apidoc mn|SV *|PL_DBsingle
When Perl is run in debugging mode, with the B<-d> switch, this SV is a
boolean which indicates whether subs are being single-stepped.
Single-stepping is automatically turned on after every step.  This is the C
variable which corresponds to Perl's $DB::single variable.  See
C<PL_DBsub>.

=for apidoc mn|SV *|PL_DBtrace
Trace variable used when Perl is run in debugging mode, with the B<-d>
switch.  This is the C variable which corresponds to Perl's $DB::trace
variable.  See C<PL_DBsingle>.

=cut
*/

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
PERLVAR(Iunitcheckav,	AV *)		/* names of UNITCHECK subroutines */
PERLVAR(Icheckav,	AV *)		/* names of CHECK subroutines */
PERLVAR(Iinitav,	AV *)		/* names of INIT subroutines */
PERLVAR(Istrtab,	HV *)		/* shared string table */
PERLVARI(Isub_generation,U32,1)		/* incr to invalidate method cache */

/* funky return mechanisms */
PERLVAR(Iforkprocess,	int)		/* so do_open |- can return proc# */

/* memory management */
PERLVAR(Isv_count,	I32)		/* how many SV* are currently allocated */
PERLVAR(Isv_objcount,	I32)		/* how many objects are currently allocated */
PERLVAR(Isv_root,	SV*)		/* storage for SVs belonging to interp */
PERLVAR(Isv_arenaroot,	SV*)		/* list of areas for garbage collection */

/* subprocess state */
PERLVAR(Ifdpid,		AV *)		/* keep fd-to-pid mappings for my_popen */

/* internal state */
PERLVARI(Iop_mask,	char *,	NULL)	/* masked operations for safe evals */

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
PERLVARI(Igensym,	I32,	0)	/* next symbol for getsym() to define */
PERLVAR(Ifilemode,	int)		/* so nextargv() can preserve mode */
PERLVAR(Ilastfd,	int)		/* what to preserve mode on */
PERLVAR(Ioldname,	char *)		/* what to preserve mode on */
PERLVAR(IArgv,		char **)	/* stuff to free from do_aexec, vfork safe */
PERLVAR(ICmd,		char *)		/* stuff to free from do_aexec, vfork safe */
PERLVAR(Ipreambleav,	AV *)
PERLVAR(Imess_sv,	SV *)
PERLVAR(Iors_sv,	SV *)		/* output record separator $\ */
     /* Space for one more U16 here without increasing the structure size */
PERLVAR(Ilast_lop_op,	OPCODE)		/* last list operator */
PERLVAR(Iin_my,		U16)		/* we're compiling a "my" (or "our") declaration */
PERLVARI(Ilaststype,	U16,	OP_STAT)
PERLVARI(Ilaststatval,	int,	-1)

/* interpreter atexit processing */
PERLVARI(Iexitlistlen,	I32, 0)		/* length of same */
PERLVARI(Iexitlist,	PerlExitListEntry *, NULL)
					/* list of exit functions */

/*
=for apidoc Amn|HV*|PL_modglobal

C<PL_modglobal> is a general purpose, interpreter global HV for use by
extensions that need to keep information on a per-interpreter basis.
In a pinch, it can also be used as a symbol table for extensions
to share data among each other.  It is a good idea to use keys
prefixed by the package name of the extension that owns the data.

=cut
*/

PERLVAR(Imodglobal,	HV *)		/* per-interp module data */

/* these used to be in global before 5.004_68 */
PERLVARI(Iprofiledata,	U32 *,	NULL)	/* table of ops, counts */
PERLVARI(Irsfp,	PerlIO * VOL,	NULL)	/* current source file pointer */
PERLVARI(Irsfp_filters,	AV *,	NULL)	/* keeps active source filters */

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
PERLVAR(IDBcv,		CV *)		/* from perl.c */
PERLVARI(Igeneration,	int,	100)	/* from op.c */

PERLVARI(Iin_clean_objs,bool,    FALSE)	/* from sv.c */
PERLVARI(Iin_clean_all,	bool,    FALSE)	/* from sv.c */
PERLVAR(Inomemok,	bool)		/* let malloc context handle nomem */
PERLVARI(Isavebegin,     bool,	FALSE)	/* save BEGINs for compiler	*/

PERLVAR(Ilinestart,	char *)		/* beg. of most recently read line */

PERLVAR(Iuid,		Uid_t)		/* current real user id */
PERLVAR(Ieuid,		Uid_t)		/* current effective user id */
PERLVAR(Igid,		Gid_t)		/* current real group id */
PERLVAR(Iegid,		Gid_t)		/* current effective group id */
PERLVARI(Ian,		U32,	0)	/* malloc sequence number */
PERLVARI(Icop_seqmax,	U32,	0)	/* statement sequence number */
PERLVARI(Ievalseq,	U32,	0)	/* eval sequence number */
PERLVAR(Iorigalen,	U32)
PERLVAR(Iorigenviron,	char **)
#ifdef PERL_USES_PL_PIDSTATUS
PERLVAR(Ipidstatus,	HV *)		/* pid-to-status mappings for waitpid */
#endif
PERLVAR(Iosname,	char *)		/* operating system */

PERLVAR(Isighandlerp,	Sighandler_t)

PERLVARA(Ibody_roots,	PERL_ARENA_ROOTS_SIZE, void*) /* array of body roots */

PERLVAR(Inice_chunk,	char *)		/* a nice chunk of memory to reuse */
PERLVAR(Inice_chunk_size,	U32)	/* how nice the chunk of memory is */

PERLVARI(Imaxo,	int,	MAXO)		/* maximum number of ops */

PERLVARI(Irunops,	runops_proc_t,	MEMBER_TO_FPTR(RUNOPS_DEFAULT))

PERLVARA(Itokenbuf,256,	char)

/*
=for apidoc Amn|SV|PL_sv_undef
This is the C<undef> SV.  Always refer to this as C<&PL_sv_undef>.

=for apidoc Amn|SV|PL_sv_no
This is the C<false> SV.  See C<PL_sv_yes>.  Always refer to this as
C<&PL_sv_no>.

=for apidoc Amn|SV|PL_sv_yes
This is the C<true> SV.  See C<PL_sv_no>.  Always refer to this as
C<&PL_sv_yes>.

=cut
*/

PERLVAR(Isv_undef,	SV)
PERLVAR(Isv_no,		SV)
PERLVAR(Isv_yes,	SV)

/* What we know when we're in LEX_KNOWNEXT state. */
#ifdef PERL_MAD
PERLVARA(Inexttoke,5,	NEXTTOKE)	/* value of next token, if any */
PERLVAR(Icurforce,	I32)
#else
PERLVARA(Inextval,5,	YYSTYPE)	/* value of next token, if any */
PERLVARA(Inexttype,5,	I32)		/* type of next token */
PERLVAR(Inexttoke,	I32)
#endif

PERLVAR(Ibufptr,	char *)
PERLVAR(Ioldbufptr,	char *)
PERLVAR(Ioldoldbufptr,	char *)
PERLVAR(Ibufend,	char *)

PERLVARI(Iexpect, U8,	XSTATE)		/* how to interpret ambiguous tokens */
PERLVAR(Ilex_state,	U8)		/* next token is determined */
PERLVAR(Ierror_count,	U8)		/* how many errors so far, max 10 */
PERLVARI(Icv_has_eval, bool, FALSE) /* PL_compcv includes an entereval or similar */
PERLVAR(Imulti_end,	I32)		/* last line of multi-line string */

PERLVAR(Isubname,	SV *)		/* name of current subroutine */

PERLVAR(Isubline,	I32)		/* line this subroutine began on */
PERLVAR(Imin_intro_pending,	I32)	/* start of vars to introduce */

PERLVAR(Imax_intro_pending,	I32)	/* end of vars to introduce */
PERLVAR(Ipadix,		I32)		/* max used index in current "register" pad */

PERLVAR(Ipadix_floor,	I32)		/* how low may inner block reset padix */
PERLVAR(Ipad_reset_pending,	I32)	/* reset pad on next attempted alloc */

PERLVAR(Ilast_uni,	char *)		/* position of last named-unary op */
PERLVAR(Ilast_lop,	char *)		/* position of last list operator */
PERLVAR(Iin_my_stash,	HV *)		/* declared class of this "my" declaration */

PERLVAR(Ihints,		U32)		/* pragma-tic compile-time flags */

PERLVAR(Idebug,		VOL U32)	/* flags given to -D switch */

PERLVARI(Iamagic_generation,	long,	0)

#ifdef USE_LOCALE_COLLATE
PERLVAR(Icollation_name,char *)		/* Name of current collation */
PERLVAR(Icollxfrm_base,	Size_t)		/* Basic overhead in *xfrm() */
PERLVARI(Icollxfrm_mult,Size_t,	2)	/* Expansion factor in *xfrm() */
PERLVARI(Icollation_ix,	U32,	0)	/* Collation generation index */
PERLVARI(Icollation_standard, bool,	TRUE)
					/* Assume simple collation */
#endif /* USE_LOCALE_COLLATE */


#ifdef PERL_UTF8_CACHE_ASSERT
PERLVARI(Iutf8cache, I8, -1)	/* Is the utf8 caching code enabled? */
#else
PERLVARI(Iutf8cache, I8, 1)	/* Is the utf8 caching code enabled? */
#endif

#ifdef USE_LOCALE_NUMERIC

PERLVARI(Inumeric_standard,	bool,	TRUE)
					/* Assume simple numerics */
PERLVARI(Inumeric_local,	bool,	TRUE)
					/* Assume local numerics */
PERLVAR(Inumeric_name,	char *)		/* Name of current numeric locale */
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
PERLVAR(Iutf8_tofold,	SV *)
PERLVAR(Ilast_swash_hv,	HV *)
PERLVAR(Ilast_swash_tmps,	U8 *)
PERLVAR(Ilast_swash_slen,	STRLEN)
PERLVARA(Ilast_swash_key,10,	U8)
PERLVAR(Ilast_swash_klen,	U8)	/* Only needs to store 0-10  */

#ifdef FCRYPT
PERLVARI(Icryptseen,	bool,	FALSE)	/* has fast crypt() been initialized? */
#endif

PERLVARI(Iglob_index,	int,	0)


PERLVAR(Iparser,	yy_parser *)	/* current parser state */

PERLVAR(Ibitcount,	char *)

PERLVAR(Ipsig_ptr, SV**)
PERLVAR(Ipsig_name, SV**)

#if defined(PERL_IMPLICIT_SYS)
PERLVAR(IMem,		struct IPerlMem*)
PERLVAR(IMemShared,	struct IPerlMem*)
PERLVAR(IMemParse,	struct IPerlMem*)
PERLVAR(IEnv,		struct IPerlEnv*)
PERLVAR(IStdIO,		struct IPerlStdIO*)
PERLVAR(ILIO,		struct IPerlLIO*)
PERLVAR(IDir,		struct IPerlDir*)
PERLVAR(ISock,		struct IPerlSock*)
PERLVAR(IProc,		struct IPerlProc*)
#endif

PERLVAR(Iptr_table,	PTR_TBL_t*)
PERLVARI(Ibeginav_save, AV*, NULL)	/* save BEGIN{}s when compiling */

PERLVAR(Ibody_arenas, void*) /* pointer to list of body-arenas */

PERLVAR(Ipsig_pend, int *)		/* per-signal "count" of pending */
PERLVARI(Isig_pending, int,0)           /* Number if highest signal pending */


PERLVAR(Itaint_warn,	bool)      /* taint warns instead of dying */
PERLVAR(Iutf8locale,	bool)		/* utf8 locale detected */
PERLVARI(Ihash_seed_set, bool, FALSE)		/* Hash initialized? */
PERLVARI(Irehash_seed_set, bool, FALSE)	/* 582 hash initialized? */

#ifdef USE_LOCALE_NUMERIC

PERLVAR(Inumeric_radix_sv,	SV *)	/* The radix separator if not '.' */

#endif

#if defined(USE_ITHREADS)
PERLVAR(Iregex_pad,     SV**)		/* All regex objects */
PERLVAR(Iregex_padav,   AV*)		/* All regex objects */

#endif

#ifdef USE_REENTRANT_API
PERLVAR(Ireentrant_buffer, REENTR*)	/* here we store the _r buffers */
#endif


#ifdef PERL_MAD
PERLVARI(Imadskills,	bool, FALSE)	/* preserve all syntactic info */
					/* (MAD = Misc Attribute Decoration) */
PERLVARI(Ixmlfp, PerlIO *,NULL)
#endif

PERLVAR(Icustom_op_names, HV*)  /* Names of user defined ops */
PERLVAR(Icustom_op_descs, HV*)  /* Descriptions of user defined ops */

#ifdef PERLIO_LAYERS
PERLVARI(Iperlio, PerlIO *,NULL)
PERLVARI(Iknown_layers, PerlIO_list_t *,NULL)
PERLVARI(Idef_layerlist, PerlIO_list_t *,NULL)
#endif

PERLVARI(Iencoding,	SV*, NULL)		/* character encoding */

PERLVAR(Idebug_pad,	struct perl_debug_pad)	/* always needed because of the re extension */

#ifdef PL_OP_SLAB_ALLOC
PERLVAR(IOpPtr,I32 **)
PERLVARI(IOpSpace,I32,0)
PERLVAR(IOpSlab,I32 *)
#endif

PERLVAR(Iutf8_idstart,	SV *)
PERLVAR(Iutf8_idcont,	SV *)

PERLVAR(Isort_RealCmp,  SVCOMPARE_t)

PERLVARI(Icheckav_save, AV*, NULL)	/* save CHECK{}s when compiling */
PERLVARI(Iunitcheckav_save, AV*, NULL)	/* save UNITCHECK{}s when compiling */

PERLVARI(Iclocktick, long, 0)	/* this many times() ticks in a second */

PERLVARI(Iin_load_module, int, 0)	/* to prevent recursions in PerlIO_find_layer */

PERLVAR(Iunicode, U32)	/* Unicode features: $ENV{PERL_UNICODE} or -C */

PERLVAR(Isignals, U32)	/* Using which pre-5.8 signals */

PERLVAR(Ireentrant_retint, int)	/* Integer return value from reentrant functions */

PERLVAR(Istashcache,	HV *)		/* Cache to speed up S_method_common */

/* Hooks to shared SVs and locks. */
PERLVARI(Isharehook,	share_proc_t,	MEMBER_TO_FPTR(Perl_sv_nosharing))
PERLVARI(Ilockhook,	share_proc_t,	MEMBER_TO_FPTR(Perl_sv_nosharing))
#ifdef NO_MATHOMS
#  define PERL_UNLOCK_HOOK Perl_sv_nosharing
#else
/* This reference ensures that the mathoms are linked with perl */
#  define PERL_UNLOCK_HOOK Perl_sv_nounlocking
#endif
PERLVARI(Iunlockhook,	share_proc_t,	MEMBER_TO_FPTR(PERL_UNLOCK_HOOK))

PERLVARI(Ithreadhook,	thrhook_proc_t,	MEMBER_TO_FPTR(Perl_nothreadhook))

/* Force inclusion of both runops options */
PERLVARI(Irunops_std,	runops_proc_t,	MEMBER_TO_FPTR(Perl_runops_standard))
PERLVARI(Irunops_dbg,	runops_proc_t,	MEMBER_TO_FPTR(Perl_runops_debug))

/* Stores the PPID */
#ifdef THREADS_HAVE_PIDS
PERLVARI(Ippid,		IV,		0)
#endif

PERLVARI(Ihash_seed, UV, 0)		/* Hash initializer */

PERLVAR(IDBassertion,   SV *)

PERLVARI(Irehash_seed, UV, 0)		/* 582 hash initializer */

#ifdef DEBUG_LEAKING_SCALARS_FORK_DUMP
/* File descriptor to talk to the child which dumps scalars.  */
PERLVARI(Idumper_fd, int, -1)
#endif

#ifdef PERL_IMPLICIT_CONTEXT
PERLVARI(Imy_cxt_size, int, 0)		/* size of PL_my_cxt_list */
PERLVARI(Imy_cxt_list, void **, NULL) /* per-module array of MY_CXT pointers */
#ifdef PERL_GLOBAL_STRUCT_PRIVATE
PERLVARI(Imy_cxt_keys, const char **, NULL) /* per-module array of pointers to MY_CXT_KEY constants */
#endif
#endif

#ifdef PERL_TRACK_MEMPOOL
/* For use with the memory debugging code in util.c  */
PERLVAR(Imemory_debug_header, struct perl_memory_debug_header)
#endif

#ifdef PERL_DEBUG_READONLY_OPS
PERLVARI(Islabs, I32**, NULL)	/* Array of slabs that have been allocated */
PERLVARI(Islab_count, U32, 0)	/* Size of the array */
#endif

PERLVARI(Iisarev, HV*, NULL) /* Reverse map of @ISA dependencies */

/* If you are adding a U16, see the comment above on where there are 2 bytes
   of gap which currently will be structure padding.  */

/* Within a stable branch, new variables must be added to the very end, before
 * this comment, for binary compatibility (the offsets of the old members must
 *  not change).
 * (Don't forget to add your variable also to perl_clone()!)
 * XSUB.h provides wrapper functions via perlapi.h that make this
 * irrelevant, but not all code may be expected to #include XSUB.h.
 */
