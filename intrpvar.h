/***********************************************/
/* Global only to current interpreter instance */
/***********************************************/

/* pseudo environmental stuff */
PERLVAR(Iorigargc,	int)		
PERLVAR(Iorigargv,	char **)		
PERLVAR(Ienvgv,		GV *)		
PERLVAR(Isiggv,		GV *)		
PERLVAR(Iincgv,		GV *)		
PERLVAR(Iorigfilename,	char *)		
PERLVAR(Idiehook,	SV *)		
PERLVAR(Iwarnhook,	SV *)		
PERLVAR(Iparsehook,	SV *)		
PERLVAR(Icddir,		char *)		/* switches */
PERLVAR(Iminus_c,	bool)		
PERLVAR(Ipatchlevel[10],char)		
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
PERLVAR(Ie_tmpname,	char *)		
PERLVAR(Ie_fp,		PerlIO *)		
PERLVAR(Iperldb,	U32)		

/* This value may be raised by extensions for testing purposes */
/* 0=none, 1=full, 2=full with checks */
PERLVARI(Iperl_destruct_level,	int,	0)	

/* magical thingies */
PERLVAR(Ibasetime,	Time_t)		/* $^T */
PERLVAR(Iformfeed,	SV *)		/* $^L */


PERLVARI(Imaxsysfd,	I32,	MAXSYSFD)	/* top fd to pass to subprocesses */
PERLVAR(Imultiline,	int)		/* $*--do strings hold >1 line? */
PERLVAR(Istatusvalue,	I32)		/* $? */
#ifdef VMS
PERLVAR(Istatusvalue_vms,	U32)		
#endif

PERLVAR(Istatcache,	Stat_t)	/* _ */
PERLVAR(Istatgv,	GV *)		
PERLVARI(Istatname,	SV *,	Nullsv)	

/* shortcuts to various I/O objects */
PERLVAR(Istdingv,	GV *)		
PERLVAR(Idefgv,		GV *)		
PERLVAR(Iargvgv,	GV *)		
PERLVAR(Iargvoutgv,	GV *)		

/* shortcuts to regexp stuff */
PERLVAR(Ileftgv,	GV *)		
PERLVAR(Iampergv,	GV *)		
PERLVAR(Irightgv,	GV *)		
PERLVAR(Iscreamfirst,	I32 *)		
PERLVAR(Iscreamnext,	I32 *)		
PERLVARI(Imaxscream,	I32,	-1)	
PERLVAR(Ilastscream,	SV *)		

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
PERLVAR(Isortcop,	OP *)		/* user defined sort routine */
PERLVAR(Isortstash,	HV *)		/* which is in some package or other */
PERLVAR(Ifirstgv,	GV *)		/* $a */
PERLVAR(Isecondgv,	GV *)		/* $b */
PERLVAR(Imystrk,	SV *)		/* temp key string for do_each() */
PERLVAR(Idumplvl,	I32)		/* indentation level on syntax tree dump */
PERLVAR(Ioldlastpm,	PMOP *)		/* for saving regexp context during debugger */
PERLVAR(Igensym,	I32)		/* next symbol for getsym() to define */
PERLVAR(Ipreambled,	bool)		
PERLVAR(Ipreambleav,	AV *)		
PERLVARI(Ilaststatval,	int,	-1)	
PERLVARI(Ilaststype,	I32,	OP_STAT)	
PERLVAR(Imess_sv,	SV *)		

PERLVAR(Iors,		char *)		/* $\ */
PERLVAR(Iorslen,	STRLEN)		
PERLVAR(Iofmt,		char *)		/* $# */

#ifdef USE_THREADS
PERLVAR(Ithrsv,		SV *)		/* holds struct perl_thread for main thread */
PERLVARI(Ithreadnum,	U32,	0)	/* incremented each thread creation */
#endif /* USE_THREADS */
