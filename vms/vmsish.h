/*  vmsish.h
 *
 * VMS-specific C header file for perl5.
 *
 * Last revised: 09-Oct-1994 by Charles Bailey  bailey@genetics.upenn.edu
 */

#ifndef __vmsish_h_included
#define __vmsish_h_included

#include <descrip.h> /* for dirent struct definitions */

/* Assorted things to look like Unix */
#ifdef __GNUC__
#ifndef _IOLBF /* gcc's stdio.h doesn't define this */
#define _IOLBF 1
#endif
#else
#include <processes.h> /* for vfork() */
#include <unixio.h>
#endif
#include <unixlib.h>
#include <file.h>  /* it's not <sys/file.h>, so don't use I_SYS_FILE */
#define unlink remove

#ifdef VMS_DO_SOCKETS
#include "sockadapt.h"
#endif

/*
 * The following symbols are defined (or undefined) according to the RTL
 * support VMS provides for the corresponding functions.  These don't
 * appear in config.h, so they're dealt with here.
 */
#define HAS_KILL
#define HAS_WAIT

/*  The VMS C RTL has vfork() but not fork().  Both actually work in a way
 *  that's somewhere between Unix vfork() and VMS lib$spawn(), so it's
 *  probably not a good idea to use them much.  That said, we'll try to
 *  use vfork() in either case.
 */
#define fork vfork

/*
 * fwrite1() should be a routine with the same calling sequence as fwrite(),
 * but which outputs all of the bytes requested as a single stream (unlike
 * fwrite() itself, which on some systems outputs several distinct records
 * if the number_of_items parameter is >1).
 */
#define fwrite1 my_fwrite

/* Use our own rmdir() */
#define rmdir(name) do_rmdir(name)

/* Assorted fiddling with sigs . . . */
# include <signal.h>
#define ABORT() abort()

/* This is what times() returns, but <times.h> calls it tbuffer_t on VMS */

struct tms {
  clock_t tms_utime;    /* user time */
  clock_t tms_stime;    /* system time - always 0 on VMS */
  clock_t tms_cutime;   /* user time, children */
  clock_t tms_cstime;   /* system time, children - always 0 on VMS */
};

/* VMS doesn't use a real sys_nerr, but we need this when scanning for error
 * messages in text strings . . .
 */

#define sys_nerr EVMSERR  /* EVMSERR is as high as we can go. */

/* Look up new %ENV values on the fly */
#define DYNAMIC_ENV_FETCH 1
#define ENV_HV_NAME "%EnV%VmS%"

/* Use our own stat() clones, which handle Unix-style directory names */
#define Stat(name,bufptr) flex_stat(name,bufptr)
#define Fstat(fd,bufptr) flex_fstat(fd,bufptr)

/* Setup for the dirent routines:
 * opendir(), closedir(), readdir(), seekdir(), telldir(), and
 * vmsreaddirversions(), and preprocessor stuff on which these depend:
 *    Written by Rich $alz, <rsalz@bbn.com> in August, 1990.
 *    This code has no copyright.
 */
    /* Data structure returned by READDIR(). */
struct dirent {
    char	d_name[256];		/* File name		*/
    int		d_namlen;			/* Length of d_name */
    int		vms_verscount;		/* Number of versions	*/
    int		vms_versions[20];	/* Version numbers	*/
};

    /* Handle returned by opendir(), used by the other routines.  You
     * are not supposed to care what's inside this structure. */
typedef struct _dirdesc {
    long			context;
    int				vms_wantversions;
    unsigned long int           count;
    char			*pattern;
    struct dirent		entry;
    struct dsc$descriptor_s	pat;
} DIR;

#define rewinddir(dirp)		seekdir((dirp), 0)


/* Prototypes for functions unique to vms.c.  Don't include replacements
 * for routines in the mainline source files excluded by #ifndef VMS;
 * their prototypes are already in proto.h.
 *
 * In order to keep Gen_ShrFls.Pl happy, functions which are to be made
 * available to images linked to PerlShr.Exe must be declared between the
 * __VMS_PROTOTYPES__ and __VMS_SEPYTOTORP__ lines, and must be in the form
 *    <data type><TAB>name<WHITESPACE>_((<prototype args>));
 */
typedef char  __VMS_PROTOTYPES__; /* prototype section start marker */
char *	my_getenv _((char *));
#ifndef HAS_WAITPID  /* Not a real waitpid - use only with popen from vms.c! */
unsigned long int	waitpid _((unsigned long int, int *, int));
#endif
char *	my_gconvert _((double, int, int, char *));
int	do_rmdir _((char *));
int	kill_file _((char *));
char *	fileify_dirspec _((char *, char *));
char *	fileify_dirspec_ts _((char *, char *));
char *	pathify_dirspec _((char *, char *));
char *	pathify_dirspec_ts _((char *, char *));
char *	tounixspec _((char *, char *));
char *	tounixspec_ts _((char *, char *));
char *	tovmsspec _((char *, char *));
char *	tovmsspec_ts _((char *, char *));
char *	tounixpath _((char *, char *));
char *	tounixpath_ts _((char *, char *));
char *	tovmspath _((char *, char *));
char *	tovmspath_ts _((char *, char *));
void	getredirection _(());
DIR *	opendir _((char *));
struct dirent *	readdir _((DIR *));
long	telldir _((DIR *));
void	seekdir _((DIR *, long));
void	closedir _((DIR *));
void	vmsreaddirversions _((DIR *, int));
void	getredirection _((int *, char ***));
int	flex_fstat _((int, stat_t *));
int	flex_stat _((char *, stat_t *));
int	trim_unixpath _((char *, char*));
struct sv; /* forward declaration for vms_do_aexec and do_aspawn */
           /* real declaration is in sv.h */
#define bool char  /* This must match handy.h */
bool	vms_do_aexec _((struct sv *, struct sv **, struct sv **));
bool	vms_do_exec _((char *));
unsigned long int	do_aspawn _((struct sv *, struct sv **, struct sv **));
unsigned long int	do_spawn _((char *));
int	my_fwrite _((void *, size_t, size_t, FILE *));
typedef char __VMS_SEPYTOTORP__; /* prototype section end marker */

#ifndef VMS_DO_SOCKETS
/***** The following four #defines are temporary, and should be removed,
 * along with the corresponding routines in vms.c, when TCP/IP support
 * is integrated into the VMS port of perl5. (The temporary hacks are
 * here for now so pack can handle type N elements.)
 * - C. Bailey  26-Aug-1994
 *****/
unsigned short int	tmp_shortflip _((unsigned short int));
unsigned long int	tmp_longflip _((unsigned long int));
#define htons(us) tmp_shortflip(us)
#define ntohs(us) tmp_shortflip(us)
#define htonl(ul) tmp_longflip(ul)
#define ntohl(ul) tmp_longflip(ul)
#endif

#endif  /* __vmsish_h_included */
