
/*
 * The following symbols are defined if your operating system supports
 * functions by that name.  All Unixes I know of support them, thus they
 * are not checked by the configuration script, but are directly defined
 * here.
 */

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

#define HAS_KILL
#define HAS_LINK
#define HAS_WAIT
/*
 * The following symbols are defined if your operating system supports
 * password and group functions in general.  All Unix systems do.
 */
#ifdef I_GRP
#define HAS_GROUP
#endif
#ifdef I_PWD
#define HAS_PASSWD
#endif


#if !defined(NSIG) || defined(M_UNIX) || defined(M_XENIX)
# include <signal.h>
#endif

#ifndef SIGABRT
#    define SIGABRT SIGILL
#endif
#ifndef SIGILL
#    define SIGILL 6         /* blech */
#endif
#define ABORT() kill(getpid(),SIGABRT);

/*
 * fwrite1() should be a routine with the same calling sequence as fwrite(),
 * but which outputs all of the bytes requested as a single stream (unlike
 * fwrite() itself, which on some systems outputs several distinct records
 * if the number_of_items parameter is >1).
 */
#define fwrite1 fwrite

#define Stat(fname,bufptr) stat((fname),(bufptr))
#define Fstat(fd,bufptr)   fstat((fd),(bufptr))

#define my_getenv(var) getenv(var)
