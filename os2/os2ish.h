#include <signal.h>

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
#define HAS_WAIT

#ifndef SIGABRT
#    define SIGABRT SIGILL
#endif
#ifndef SIGILL
#    define SIGILL 6         /* blech */
#endif
#define ABORT() kill(getpid(),SIGABRT);

#define BIT_BUCKET "/dev/null"  /* Will this work? */

#define PERL_SYS_INIT(argcp, argvp) do {	\
    _response(argcp, argvp);			\
    _wildcard(argcp, argvp); } while (0)


/*
 * fwrite1() should be a routine with the same calling sequence as fwrite(),
 * but which outputs all of the bytes requested as a single stream (unlike
 * fwrite() itself, which on some systems outputs several distinct records
 * if the number_of_items parameter is >1).
 */
#define fwrite1 fwrite

#define my_getenv(var) getenv(var)

/*****************************************************************************/

#include <stdlib.h>	/* before the following definitions */
#include <unistd.h>	/* before the following definitions */

#define chdir	_chdir2
#define getcwd	_getcwd2

/* This guy is needed for quick stdstd  */

#if defined(USE_STDIO_PTR) && defined(STDIO_PTR_LVALUE) && defined(STDIO_CNT_LVALUE)
#  define _filbuf _fill
	/* Perl uses ungetc only with successful return */
#  define ungetc(c,fp) \
	(FILE_ptr(fp) > FILE_base(fp) && c == (int)*(FILE_ptr(fp) - 1) \
	 ? (--FILE_ptr(fp), ++FILE_cnt(fp), (int)c) : ungetc(c,fp))
#endif

#define OP_BINARY O_BINARY

#define OS2_STAT_HACK 1
#if OS2_STAT_HACK

#define Stat(fname,bufptr) os2_stat((fname),(bufptr))
#define Fstat(fd,bufptr)   fstat((fd),(bufptr))

#undef S_IFBLK
#undef S_ISBLK
#define S_IFBLK		0120000
#define S_ISBLK(mode)	(((mode) & S_IFMT) == S_IFBLK)

#else

#define Stat(fname,bufptr) stat((fname),(bufptr))
#define Fstat(fd,bufptr)   fstat((fd),(bufptr))

#endif
