/*********************************************************************
Project	:	Perl5				-	
File		:	macish.h			-	Mac specific things
Author	:	Matthias Neeracher

*********************************************************************/

#include <Types.h>
#include <ConditionalMacros.h>

#define sys_nerr	80

extern char * sys_errlist[];

/* For now we get compiler this way, until we can
   find a better way */
#if TARGET_CPU_PPC
#  define	ARCHNAME	"MacPPC"
#  if defined(__MRC__)
#    define	CC		"MrC"
#  else
#    define	CC		"MWCPPC"
#  endif
#else
#  if TARGET_RT_MAC_CFM
#    define	ARCHNAME	"MacCFM68K"
#  else
#    define	ARCHNAME	"Mac68K"
#  endif
#  if defined(__SC__)
#    define	CC		"SC"
#  else
#    define	CC		"MWC68K"
#  endif
#endif

#ifndef MP_EXT
#define MP_EXT extern
#define MP_INIT(x)
#endif

MP_EXT char	gMacPerl_AlwaysExtract		MP_INIT(false);
MP_EXT char	gMacPerl_SyntaxError;
MP_EXT char	gMacPerl_MustPrime;
MP_EXT char *	gMacPerl_Perl5DB;
MP_EXT char	gMacPerl_InModalDialog		MP_INIT(false);
MP_EXT short	gMacPerl_OSErr;
MP_EXT char 	gMacPerl_PseudoFileName[256];
MP_EXT int	gMacPerl_Quit;
MP_EXT clock_t	gMacPerl_StartClock;
MP_EXT int	gMacPerl_ErrorFormat		MP_INIT(1);

#ifdef MAC_CONTEXT
#undef Move
#include <Events.h>
#include <Dialogs.h>
#include <Files.h>

MP_EXT Handle		gMacPerl_Reply;
MP_EXT void  		(*gMacPerl_HandleEvent)(EventRecord * ev)	MP_INIT(nil);
MP_EXT void		(*gMacPerl_FilterEvent)(EventRecord * ev)	MP_INIT(nil);
MP_EXT Boolean		(*gMacPerl_FilterMenu)(long menuSelection)	MP_INIT(nil);
void MacPerl_WaitEvent(Boolean busy, long sleep, RgnHandle rgn);
MP_EXT void		(*gMacPerl_WaitEvent)(Boolean busy, long sleep, RgnHandle rgn)	MP_INIT(MacPerl_WaitEvent);

typedef OSErr	MacOSRet;
typedef Handle	HandleRet;
typedef Ptr	RawPtr;
typedef Ptr	PtrRet;
#endif

typedef int (*MacPerl_EmulationProc)(void *, char *);
void MacPerl_AddWriteEmulationProc(const char * command, MacPerl_EmulationProc proc);
char * MacPerl_MPWFileName(char * file);
char * GetSysErrText(short, char *);
unsigned char * MacPerl_CopyC2P(const char * c, unsigned char * p);
const char * MacPerl_CanonDir(const char * dir, char * buf);
void MacPerl_WriteMsg(void * io, const char * msg, size_t len);

/* These defined following should be defined in 5.8 in config.h */
#define HAS_USLEEP
#define HAS_UALARM


/* HAS_IOCTL:
 *	This symbol, if defined, indicates that the ioctl() routine is
 *	available to set I/O characteristics
 */
#define	HAS_IOCTL		/**/
 
/* HAS_UTIME:
 *	This symbol, if defined, indicates that the routine utime() is
 *	available to update the access and modification times of files.
 */
#define HAS_UTIME		/**/

/* HAS_GROUP
 *	This symbol, if defined, indicates that the getgrnam() and
 *	getgrgid() routines are available to get group entries.
 *	The getgrent() has a separate definition, HAS_GETGRENT.
 */
#undef HAS_GROUP		/**/

/* HAS_PASSWD
 *	This symbol, if defined, indicates that the getpwnam() and
 *	getpwuid() routines are available to get password entries.
 *	The getpwent() has a separate definition, HAS_GETPWENT.
 */
#undef HAS_PASSWD		/**/

#define HAS_KILL
#undef HAS_WAIT
  
/* USEMYBINMODE
 *	This symbol, if defined, indicates that the program should
 *	use the routine my_binmode(FILE *fp, char iotype) to insure
 *	that a file is in "binary" mode -- that is, that no translation
 *	of bytes occurs on read or write operations.
 */
#undef USEMYBINMODE

/* Stat_t:
 *	This symbol holds the type used to declare buffers for information
 *	returned by stat().  It's usually just struct stat.  It may be necessary
 *	to include <sys/stat.h> and <sys/types.h> to get any typedef'ed
 *	information.
 */
#define Stat_t struct stat

/* USE_STAT_RDEV:
 *	This symbol is defined if this system has a stat structure declaring
 *	st_rdev
 */
#undef USE_STAT_RDEV 	/**/

/* ACME_MESS:
 *	This symbol, if defined, indicates that error messages should be 
 *	should be generated in a format that allows the use of the Acme
 *	GUI/editor's autofind feature.
 */
#undef ACME_MESS	/**/

/* UNLINK_ALL_VERSIONS:
 *	This symbol, if defined, indicates that the program should arrange
 *	to remove all versions of a file if unlink() is called.  This is
 *	probably only relevant for VMS.
 */
/* #define UNLINK_ALL_VERSIONS		/ **/

/* VMS:
 *	This symbol, if defined, indicates that the program is running under
 *	VMS.  It is currently automatically set by cpps running under VMS,
 *	and is included here for completeness only.
 */
/* #define VMS		/ **/

/* ALTERNATE_SHEBANG:
 *	This symbol, if defined, contains a "magic" string which may be used
 *	as the first line of a Perl program designed to be executed directly
 *	by name, instead of the standard Unix #!.  If ALTERNATE_SHEBANG
 *	begins with a character other then #, then Perl will only treat
 *	it as a command line if if finds the string "perl" in the first
 *	word; otherwise it's treated as the first line of code in the script.
 *	(IOW, Perl won't hand off to another interpreter via an alternate
 *	shebang sequence that might be legal Perl code.)
 */
/* #define ALTERNATE_SHEBANG "#!" / **/

/* Since we have CROSSCOMPILE and MULTIARCH defined, we need to make
 * sure everyone knows we are big-endian.
 */
#define __BIG_ENDIAN__

#if !defined(NSIG) || defined(M_UNIX) || defined(M_XENIX) || defined(__NetBSD__)
# include <signal.h>
#endif

#ifndef SIGABRT
#    define SIGABRT SIGILL
#endif
#ifndef SIGILL
#    define SIGILL 6         /* blech */
#endif
#define ABORT() abort();

/*
 * fwrite1() should be a routine with the same calling sequence as fwrite(),
 * but which outputs all of the bytes requested as a single stream (unlike
 * fwrite() itself, which on some systems outputs several distinct records
 * if the number_of_items parameter is >1).
 */
#define fwrite1 fwrite

#define Stat(fname,bufptr) stat((fname),(bufptr))
#define Fstat(fd,bufptr)   fstat((fd),(bufptr))
#define Fflush(fp)         fflush(fp)
#define Mkdir(path,mode)   mkdir((path),(mode))

#ifndef PERL_SYS_INIT3
#	define PERL_SYS_INIT3(c,v,e) \
		MacPerl_init(); init_env(*e); \
		PL_opargs[OP_TIME] &= ~OA_RETINTEGER; MALLOC_INIT
#endif

#ifndef PERL_SYS_TERM
#define PERL_SYS_TERM()		MALLOC_TERM
#endif

#define PERL_WRITE_MSG_TO_CONSOLE(io, msg, len) MacPerl_WriteMsg(io, msg, len)

#define BIT_BUCKET "Dev:Null"

#define dXSUB_SYS

#define DYNAMIC_ENV_FETCH 1
#define ENV_HV_NAME "%EnV%MacOS%"

struct tms {
	clock_t tms_utime;	/* User CPU time */
	clock_t tms_stime;	/* System CPU time */
	clock_t tms_cutime;	/* User CPU time of terminated child procs */
	clock_t tms_cstime;	/* System CPU time of terminated child procs */
};

clock_t	MacPerl_times(struct tms *);
#define times(x) MacPerl_times(x)

/* MacOS 68K defines atan2 et al. as macros */

#define atan2d_amg  atan2_amg
#define cosd_amg    cos_amg
#define expd_amg    exp_amg
#define logd_amg    log_amg
#define powd_amg    pow_amg
#define sind_amg    sin_amg
#define sqrtd_amg   sqrt_amg

#ifdef __SC__
#undef Perl_modf
double Perl_modf(double x, double * iptr);
#endif

#if defined(__SC__) || defined(__MRC__)
#include <fp.h>
#undef Perl_atof
double Perl_atof(const char *s);
#endif

#ifdef __SC__
#pragma segment perl
#endif
