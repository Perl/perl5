#ifdef WIN32
#define _POSIX_
#endif

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#define PERLIO_NOT_STDIO 1
#include "perl.h"
#include "XSUB.h"
#if defined(PERL_OBJECT) || defined(PERL_CAPI) || defined(PERL_IMPLICIT_SYS)
#  undef signal
#  undef open
#  undef setmode
#  define open PerlLIO_open3
#endif
#include <ctype.h>
#ifdef I_DIRENT    /* XXX maybe better to just rely on perl.h? */
#include <dirent.h>
#endif
#include <errno.h>
#ifdef I_FLOAT
#include <float.h>
#endif
#ifdef I_LIMITS
#include <limits.h>
#endif
#include <locale.h>
#include <math.h>
#ifdef I_PWD
#include <pwd.h>
#endif
#include <setjmp.h>
#include <signal.h>
#include <stdarg.h>

#ifdef I_STDDEF
#include <stddef.h>
#endif

#ifdef I_UNISTD
#include <unistd.h>
#endif

/* XXX This comment is just to make I_TERMIO and I_SGTTY visible to 
   metaconfig for future extension writers.  We don't use them in POSIX.
   (This is really sneaky :-)  --AD
*/
#if defined(I_TERMIOS)
#include <termios.h>
#endif
#ifdef I_STDLIB
#include <stdlib.h>
#endif
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#ifdef I_UNISTD
#include <unistd.h>
#endif
#ifdef MACOS_TRADITIONAL
#undef fdopen
#endif
#include <fcntl.h>

#ifdef HAS_TZNAME
#  if !defined(WIN32) && !defined(__CYGWIN__)
extern char *tzname[];
#  endif
#else
#if !defined(WIN32) || (defined(__MINGW32__) && !defined(tzname))
char *tzname[] = { "" , "" };
#endif
#endif

#if defined(__VMS) && !defined(__POSIX_SOURCE)
#  include <libdef.h>       /* LIB$_INVARG constant */
#  include <lib$routines.h> /* prototype for lib$ediv() */
#  include <starlet.h>      /* prototype for sys$gettim() */
#  if DECC_VERSION < 50000000
#    define pid_t int       /* old versions of DECC miss this in types.h */
#  endif

#  undef mkfifo
#  define mkfifo(a,b) (not_here("mkfifo"),-1)
#  define tzset() not_here("tzset")

#if ((__VMS_VER >= 70000000) && (__DECC_VER >= 50200000)) || (__CRTL_VER >= 70000000)
#    define HAS_TZNAME  /* shows up in VMS 7.0 or Dec C 5.6 */
#    include <utsname.h>
#  endif /* __VMS_VER >= 70000000 or Dec C 5.6 */

   /* The POSIX notion of ttyname() is better served by getname() under VMS */
   static char ttnambuf[64];
#  define ttyname(fd) (isatty(fd) > 0 ? getname(fd,ttnambuf,0) : NULL)

   /* The non-POSIX CRTL times() has void return type, so we just get the
      current time directly */
   clock_t vms_times(struct tms *bufptr) {
	dTHX;
	clock_t retval;
	/* Get wall time and convert to 10 ms intervals to
	 * produce the return value that the POSIX standard expects */
#  if defined(__DECC) && defined (__ALPHA)
#    include <ints.h>
	uint64 vmstime;
	_ckvmssts(sys$gettim(&vmstime));
	vmstime /= 100000;
	retval = vmstime & 0x7fffffff;
#  else
	/* (Older hw or ccs don't have an atomic 64-bit type, so we
	 * juggle 32-bit ints (and a float) to produce a time_t result
	 * with minimal loss of information.) */
	long int vmstime[2],remainder,divisor = 100000;
	_ckvmssts(sys$gettim((unsigned long int *)vmstime));
	vmstime[1] &= 0x7fff;  /* prevent overflow in EDIV */
	_ckvmssts(lib$ediv(&divisor,vmstime,(long int *)&retval,&remainder));
#  endif
	/* Fill in the struct tms using the CRTL routine . . .*/
	times((tbuffer_t *)bufptr);
	return (clock_t) retval;
   }
#  define times(t) vms_times(t)
#else
#if defined (__CYGWIN__)
#    define tzname _tzname
#endif
#if defined (WIN32)
#  undef mkfifo
#  define mkfifo(a,b) not_here("mkfifo")
#  define ttyname(a) (char*)not_here("ttyname")
#  define sigset_t long
#  define pid_t long
#  ifdef __BORLANDC__
#    define tzname _tzname
#  endif
#  ifdef _MSC_VER
#    define mode_t short
#  endif
#  ifdef __MINGW32__
#    define mode_t short
#    ifndef tzset
#      define tzset()		not_here("tzset")
#    endif
#    ifndef _POSIX_OPEN_MAX
#      define _POSIX_OPEN_MAX	FOPEN_MAX	/* XXX bogus ? */
#    endif
#  endif
#  define sigaction(a,b,c)	not_here("sigaction")
#  define sigpending(a)		not_here("sigpending")
#  define sigprocmask(a,b,c)	not_here("sigprocmask")
#  define sigsuspend(a)		not_here("sigsuspend")
#  define sigemptyset(a)	not_here("sigemptyset")
#  define sigaddset(a,b)	not_here("sigaddset")
#  define sigdelset(a,b)	not_here("sigdelset")
#  define sigfillset(a)		not_here("sigfillset")
#  define sigismember(a,b)	not_here("sigismember")
#else

#  ifndef HAS_MKFIFO
#    if defined(OS2) || defined(MACOS_TRADITIONAL)
#      define mkfifo(a,b) not_here("mkfifo")
#    else	/* !( defined OS2 ) */ 
#      ifndef mkfifo
#        define mkfifo(path, mode) (mknod((path), (mode) | S_IFIFO, 0))
#      endif
#    endif
#  endif /* !HAS_MKFIFO */

#  ifdef MACOS_TRADITIONAL
#    define ttyname(a) (char*)not_here("ttyname")
#    define tzset() not_here("tzset")
#  else
#    include <grp.h>
#    include <sys/times.h>
#    ifdef HAS_UNAME
#      include <sys/utsname.h>
#    endif
#    include <sys/wait.h>
#  endif
#  ifdef I_UTIME
#    include <utime.h>
#  endif
#endif /* WIN32 */
#endif /* __VMS */

typedef int SysRet;
typedef long SysRetLong;
typedef sigset_t* POSIX__SigSet;
typedef HV* POSIX__SigAction;
#ifdef I_TERMIOS
typedef struct termios* POSIX__Termios;
#else /* Define termios types to int, and call not_here for the functions.*/
#define POSIX__Termios int
#define speed_t int
#define tcflag_t int
#define cc_t int
#define cfgetispeed(x) not_here("cfgetispeed")
#define cfgetospeed(x) not_here("cfgetospeed")
#define tcdrain(x) not_here("tcdrain")
#define tcflush(x,y) not_here("tcflush")
#define tcsendbreak(x,y) not_here("tcsendbreak")
#define cfsetispeed(x,y) not_here("cfsetispeed")
#define cfsetospeed(x,y) not_here("cfsetospeed")
#define ctermid(x) (char *) not_here("ctermid")
#define tcflow(x,y) not_here("tcflow")
#define tcgetattr(x,y) not_here("tcgetattr")
#define tcsetattr(x,y,z) not_here("tcsetattr")
#endif

/* Possibly needed prototypes */
char *cuserid (char *);
double strtod (const char *, char **);
long strtol (const char *, char **, int);
unsigned long strtoul (const char *, char **, int);

#ifndef HAS_CUSERID
#define cuserid(a) (char *) not_here("cuserid")
#endif
#ifndef HAS_DIFFTIME
#ifndef difftime
#define difftime(a,b) not_here("difftime")
#endif
#endif
#ifndef HAS_FPATHCONF
#define fpathconf(f,n) 	(SysRetLong) not_here("fpathconf")
#endif
#ifndef HAS_MKTIME
#define mktime(a) not_here("mktime")
#endif
#ifndef HAS_NICE
#define nice(a) not_here("nice")
#endif
#ifndef HAS_PATHCONF
#define pathconf(f,n) 	(SysRetLong) not_here("pathconf")
#endif
#ifndef HAS_SYSCONF
#define sysconf(n) 	(SysRetLong) not_here("sysconf")
#endif
#ifndef HAS_READLINK
#define readlink(a,b,c) not_here("readlink")
#endif
#ifndef HAS_SETPGID
#define setpgid(a,b) not_here("setpgid")
#endif
#ifndef HAS_SETSID
#define setsid() not_here("setsid")
#endif
#ifndef HAS_STRCOLL
#define strcoll(s1,s2) not_here("strcoll")
#endif
#ifndef HAS_STRTOD
#define strtod(s1,s2) not_here("strtod")
#endif
#ifndef HAS_STRTOL
#define strtol(s1,s2,b) not_here("strtol")
#endif
#ifndef HAS_STRTOUL
#define strtoul(s1,s2,b) not_here("strtoul")
#endif
#ifndef HAS_STRXFRM
#define strxfrm(s1,s2,n) not_here("strxfrm")
#endif
#ifndef HAS_TCGETPGRP
#define tcgetpgrp(a) not_here("tcgetpgrp")
#endif
#ifndef HAS_TCSETPGRP
#define tcsetpgrp(a,b) not_here("tcsetpgrp")
#endif
#ifndef HAS_TIMES
#define times(a) not_here("times")
#endif
#ifndef HAS_UNAME
#define uname(a) not_here("uname")
#endif
#ifndef HAS_WAITPID
#define waitpid(a,b,c) not_here("waitpid")
#endif

#ifndef HAS_MBLEN
#ifndef mblen
#define mblen(a,b) not_here("mblen")
#endif
#endif
#ifndef HAS_MBSTOWCS
#define mbstowcs(s, pwcs, n) not_here("mbstowcs")
#endif
#ifndef HAS_MBTOWC
#define mbtowc(pwc, s, n) not_here("mbtowc")
#endif
#ifndef HAS_WCSTOMBS
#define wcstombs(s, pwcs, n) not_here("wcstombs")
#endif
#ifndef HAS_WCTOMB
#define wctomb(s, wchar) not_here("wcstombs")
#endif
#if !defined(HAS_MBLEN) && !defined(HAS_MBSTOWCS) && !defined(HAS_MBTOWC) && !defined(HAS_WCSTOMBS) && !defined(HAS_WCTOMB)
/* If we don't have these functions, then we wouldn't have gotten a typedef
   for wchar_t, the wide character type.  Defining wchar_t allows the
   functions referencing it to compile.  Its actual type is then meaningless,
   since without the above functions, all sections using it end up calling
   not_here() and croak.  --Kaveh Ghazi (ghazi@noc.rutgers.edu) 9/18/94. */
#ifndef wchar_t
#define wchar_t char
#endif
#endif

#ifndef HAS_LOCALECONV
#define localeconv() not_here("localeconv")
#endif

#ifdef HAS_LONG_DOUBLE
#  if LONG_DOUBLESIZE > NVSIZE
#    undef HAS_LONG_DOUBLE  /* XXX until we figure out how to use them */
#  endif
#endif

#ifndef HAS_LONG_DOUBLE
#ifdef LDBL_MAX
#undef LDBL_MAX
#endif
#ifdef LDBL_MIN
#undef LDBL_MIN
#endif
#ifdef LDBL_EPSILON
#undef LDBL_EPSILON
#endif
#endif

static int
not_here(char *s)
{
    croak("POSIX::%s not implemented on this architecture", s);
    return -1;
}

#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISUNDEF	8
#define PERL_constant_ISUV	9
#define PERL_constant_ISYES	10

/* These were implemented in the old "constant" subroutine. They are actually
   macros that take an integer argument and return an integer result.  */
static int
int_macro_int (const char *name, STRLEN len, IV *arg_result) {
  /* Initially switch on the length of the name.  */
  /* This code has been edited from a "constant" function generated by:

use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(S_ISBLK S_ISCHR S_ISDIR S_ISFIFO S_ISREG WEXITSTATUS WIFEXITED
	       WIFSIGNALED WIFSTOPPED WSTOPSIG WTERMSIG));

print constant_types(); # macro defs
foreach (C_constant ("POSIX", 'int_macro_int', 'IV', $types, undef, 5, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("POSIX", $types);
__END__
   */

  switch (len) {
  case 7:
    /* Names all of length 7.  */
    /* S_ISBLK S_ISCHR S_ISDIR S_ISREG */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'E':
      if (memEQ(name, "S_ISREG", 7)) {
      /*                    ^       */
#ifdef S_ISREG
        *arg_result = S_ISREG(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'H':
      if (memEQ(name, "S_ISCHR", 7)) {
      /*                    ^       */
#ifdef S_ISCHR
        *arg_result = S_ISCHR(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "S_ISDIR", 7)) {
      /*                    ^       */
#ifdef S_ISDIR
        *arg_result = S_ISDIR(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'L':
      if (memEQ(name, "S_ISBLK", 7)) {
      /*                    ^       */
#ifdef S_ISBLK
        *arg_result = S_ISBLK(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    /* Names all of length 8.  */
    /* S_ISFIFO WSTOPSIG WTERMSIG */
    /* Offset 3 gives the best switch position.  */
    switch (name[3]) {
    case 'O':
      if (memEQ(name, "WSTOPSIG", 8)) {
      /*                  ^          */
#ifdef WSTOPSIG
        *arg_result = WSTOPSIG(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "WTERMSIG", 8)) {
      /*                  ^          */
#ifdef WTERMSIG
        *arg_result = WTERMSIG(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "S_ISFIFO", 8)) {
      /*                  ^          */
#ifdef S_ISFIFO
        *arg_result = S_ISFIFO(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 9:
    if (memEQ(name, "WIFEXITED", 9)) {
#ifdef WIFEXITED
      *arg_result = WIFEXITED(*arg_result);
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    if (memEQ(name, "WIFSTOPPED", 10)) {
#ifdef WIFSTOPPED
      *arg_result = WIFSTOPPED(*arg_result);
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* WEXITSTATUS WIFSIGNALED */
    /* Offset 1 gives the best switch position.  */
    switch (name[1]) {
    case 'E':
      if (memEQ(name, "WEXITSTATUS", 11)) {
      /*                ^                */
#ifdef WEXITSTATUS
        *arg_result = WEXITSTATUS(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "WIFSIGNALED", 11)) {
      /*                ^                */
#ifdef WIFSIGNALED
        *arg_result = WIFSIGNALED(*arg_result);
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_3 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     B50 B75 CS5 CS6 CS7 CS8 EIO EOF */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case '0':
    if (memEQ(name, "B50", 3)) {
    /*                 ^      */
#ifdef B50
      *iv_return = B50;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "B75", 3)) {
    /*                 ^      */
#ifdef B75
      *iv_return = B75;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CS5", 3)) {
    /*                 ^      */
#ifdef CS5
      *iv_return = CS5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "CS6", 3)) {
    /*                 ^      */
#ifdef CS6
      *iv_return = CS6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "CS7", 3)) {
    /*                 ^      */
#ifdef CS7
      *iv_return = CS7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "CS8", 3)) {
    /*                 ^      */
#ifdef CS8
      *iv_return = CS8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "EOF", 3)) {
    /*                 ^      */
#ifdef EOF
      *iv_return = EOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EIO", 3)) {
    /*                 ^      */
#ifdef EIO
      *iv_return = EIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_4 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     B110 B134 B150 B200 B300 B600 ECHO EDOM F_OK ISIG IXON NCCS NULL R_OK VEOF
     VEOL VMIN W_OK X_OK */
  /* Offset 1 gives the best switch position.  */
  switch (name[1]) {
  case '1':
    if (memEQ(name, "B110", 4)) {
    /*                ^        */
#ifdef B110
      *iv_return = B110;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "B134", 4)) {
    /*                ^        */
#ifdef B134
      *iv_return = B134;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "B150", 4)) {
    /*                ^        */
#ifdef B150
      *iv_return = B150;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "B200", 4)) {
    /*                ^        */
#ifdef B200
      *iv_return = B200;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "B300", 4)) {
    /*                ^        */
#ifdef B300
      *iv_return = B300;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "B600", 4)) {
    /*                ^        */
#ifdef B600
      *iv_return = B600;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "ECHO", 4)) {
    /*                ^        */
#ifdef ECHO
      *iv_return = ECHO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "NCCS", 4)) {
    /*                ^        */
#ifdef NCCS
      *iv_return = NCCS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "EDOM", 4)) {
    /*                ^        */
#ifdef EDOM
      *iv_return = EDOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "VEOF", 4)) {
    /*                ^        */
#ifdef VEOF
      *iv_return = VEOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "VEOL", 4)) {
    /*                ^        */
#ifdef VEOL
      *iv_return = VEOL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "VMIN", 4)) {
    /*                ^        */
#ifdef VMIN
      *iv_return = VMIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "ISIG", 4)) {
    /*                ^        */
#ifdef ISIG
      *iv_return = ISIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "NULL", 4)) {
    /*                ^        */
#ifdef NULL
      *iv_return = 0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "IXON", 4)) {
    /*                ^        */
#ifdef IXON
      *iv_return = IXON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "F_OK", 4)) {
    /*                ^        */
#ifdef F_OK
      *iv_return = F_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "R_OK", 4)) {
    /*                ^        */
#ifdef R_OK
      *iv_return = R_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "W_OK", 4)) {
    /*                ^        */
#ifdef W_OK
      *iv_return = W_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "X_OK", 4)) {
    /*                ^        */
#ifdef X_OK
      *iv_return = X_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_5 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     B1200 B1800 B2400 B4800 B9600 CREAD CSIZE E2BIG EBADF EBUSY ECHOE ECHOK
     EFBIG EINTR ELOOP ENXIO EPERM EPIPE EROFS ESRCH EXDEV HUPCL ICRNL IGNCR
     INLCR INPCK IXOFF OPOST TCION TCOON VINTR VKILL VQUIT VSTOP VSUSP VTIME */
  /* Offset 1 gives the best switch position.  */
  switch (name[1]) {
  case '1':
    if (memEQ(name, "B1200", 5)) {
    /*                ^         */
#ifdef B1200
      *iv_return = B1200;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "B1800", 5)) {
    /*                ^         */
#ifdef B1800
      *iv_return = B1800;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "B2400", 5)) {
    /*                ^         */
#ifdef B2400
      *iv_return = B2400;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "E2BIG", 5)) {
    /*                ^         */
#ifdef E2BIG
      *iv_return = E2BIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "B4800", 5)) {
    /*                ^         */
#ifdef B4800
      *iv_return = B4800;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "B9600", 5)) {
    /*                ^         */
#ifdef B9600
      *iv_return = B9600;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "EBADF", 5)) {
    /*                ^         */
#ifdef EBADF
      *iv_return = EBADF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EBUSY", 5)) {
    /*                ^         */
#ifdef EBUSY
      *iv_return = EBUSY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "ECHOE", 5)) {
    /*                ^         */
#ifdef ECHOE
      *iv_return = ECHOE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ECHOK", 5)) {
    /*                ^         */
#ifdef ECHOK
      *iv_return = ECHOK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ICRNL", 5)) {
    /*                ^         */
#ifdef ICRNL
      *iv_return = ICRNL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCION", 5)) {
    /*                ^         */
#ifdef TCION
      *iv_return = TCION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCOON", 5)) {
    /*                ^         */
#ifdef TCOON
      *iv_return = TCOON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "EFBIG", 5)) {
    /*                ^         */
#ifdef EFBIG
      *iv_return = EFBIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "IGNCR", 5)) {
    /*                ^         */
#ifdef IGNCR
      *iv_return = IGNCR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EINTR", 5)) {
    /*                ^         */
#ifdef EINTR
      *iv_return = EINTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "VINTR", 5)) {
    /*                ^         */
#ifdef VINTR
      *iv_return = VINTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "VKILL", 5)) {
    /*                ^         */
#ifdef VKILL
      *iv_return = VKILL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "ELOOP", 5)) {
    /*                ^         */
#ifdef ELOOP
      *iv_return = ELOOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "ENXIO", 5)) {
    /*                ^         */
#ifdef ENXIO
      *iv_return = ENXIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "INLCR", 5)) {
    /*                ^         */
#ifdef INLCR
      *iv_return = INLCR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "INPCK", 5)) {
    /*                ^         */
#ifdef INPCK
      *iv_return = INPCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EPERM", 5)) {
    /*                ^         */
#ifdef EPERM
      *iv_return = EPERM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EPIPE", 5)) {
    /*                ^         */
#ifdef EPIPE
      *iv_return = EPIPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "OPOST", 5)) {
    /*                ^         */
#ifdef OPOST
      *iv_return = OPOST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "VQUIT", 5)) {
    /*                ^         */
#ifdef VQUIT
      *iv_return = VQUIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CREAD", 5)) {
    /*                ^         */
#ifdef CREAD
      *iv_return = CREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EROFS", 5)) {
    /*                ^         */
#ifdef EROFS
      *iv_return = EROFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CSIZE", 5)) {
    /*                ^         */
#ifdef CSIZE
      *iv_return = CSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ESRCH", 5)) {
    /*                ^         */
#ifdef ESRCH
      *iv_return = ESRCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "VSTOP", 5)) {
    /*                ^         */
#ifdef VSTOP
      *iv_return = VSTOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "VSUSP", 5)) {
    /*                ^         */
#ifdef VSUSP
      *iv_return = VSUSP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "VTIME", 5)) {
    /*                ^         */
#ifdef VTIME
      *iv_return = VTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "HUPCL", 5)) {
    /*                ^         */
#ifdef HUPCL
      *iv_return = HUPCL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "EXDEV", 5)) {
    /*                ^         */
#ifdef EXDEV
      *iv_return = EXDEV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "IXOFF", 5)) {
    /*                ^         */
#ifdef IXOFF
      *iv_return = IXOFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_6 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     B19200 B38400 BRKINT BUFSIZ CLOCAL CSTOPB EACCES EAGAIN ECHILD ECHONL
     EDQUOT EEXIST EFAULT EINVAL EISDIR EMFILE EMLINK ENFILE ENODEV ENOENT
     ENOLCK ENOMEM ENOSPC ENOSYS ENOTTY ERANGE ESPIPE ESTALE EUSERS ICANON
     IEXTEN IGNBRK IGNPAR ISTRIP LC_ALL NOFLSH O_EXCL O_RDWR PARENB PARMRK
     PARODD SIGFPE SIGHUP SIGILL SIGINT TCIOFF TCOOFF TOSTOP VERASE VSTART */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case '2':
    if (memEQ(name, "B19200", 6)) {
    /*                  ^        */
#ifdef B19200
      *iv_return = B19200;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "B38400", 6)) {
    /*                  ^        */
#ifdef B38400
      *iv_return = B38400;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "EAGAIN", 6)) {
    /*                  ^        */
#ifdef EAGAIN
      *iv_return = EAGAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ESTALE", 6)) {
    /*                  ^        */
#ifdef ESTALE
      *iv_return = ESTALE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LC_ALL", 6)) {
    /*                  ^        */
#ifdef LC_ALL
      *iv_return = LC_ALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "VERASE", 6)) {
    /*                  ^        */
#ifdef VERASE
      *iv_return = VERASE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "VSTART", 6)) {
    /*                  ^        */
#ifdef VSTART
      *iv_return = VSTART;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "IGNBRK", 6)) {
    /*                  ^        */
#ifdef IGNBRK
      *iv_return = IGNBRK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CLOCAL", 6)) {
    /*                  ^        */
#ifdef CLOCAL
      *iv_return = CLOCAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EACCES", 6)) {
    /*                  ^        */
#ifdef EACCES
      *iv_return = EACCES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "EISDIR", 6)) {
    /*                  ^        */
#ifdef EISDIR
      *iv_return = EISDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENODEV", 6)) {
    /*                  ^        */
#ifdef ENODEV
      *iv_return = ENODEV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_RDWR", 6)) {
    /*                  ^        */
#ifdef O_RDWR
      *iv_return = O_RDWR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "ENOENT", 6)) {
    /*                  ^        */
#ifdef ENOENT
      *iv_return = ENOENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EUSERS", 6)) {
    /*                  ^        */
#ifdef EUSERS
      *iv_return = EUSERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PARENB", 6)) {
    /*                  ^        */
#ifdef PARENB
      *iv_return = PARENB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "SIGFPE", 6)) {
    /*                  ^        */
#ifdef SIGFPE
      *iv_return = SIGFPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "SIGHUP", 6)) {
    /*                  ^        */
#ifdef SIGHUP
      *iv_return = SIGHUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BRKINT", 6)) {
    /*                  ^        */
#ifdef BRKINT
      *iv_return = BRKINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ECHILD", 6)) {
    /*                  ^        */
#ifdef ECHILD
      *iv_return = ECHILD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EEXIST", 6)) {
    /*                  ^        */
#ifdef EEXIST
      *iv_return = EEXIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EMFILE", 6)) {
    /*                  ^        */
#ifdef EMFILE
      *iv_return = EMFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EMLINK", 6)) {
    /*                  ^        */
#ifdef EMLINK
      *iv_return = EMLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENFILE", 6)) {
    /*                  ^        */
#ifdef ENFILE
      *iv_return = ENFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ESPIPE", 6)) {
    /*                  ^        */
#ifdef ESPIPE
      *iv_return = ESPIPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGILL", 6)) {
    /*                  ^        */
#ifdef SIGILL
      *iv_return = SIGILL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGINT", 6)) {
    /*                  ^        */
#ifdef SIGINT
      *iv_return = SIGINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "ENOLCK", 6)) {
    /*                  ^        */
#ifdef ENOLCK
      *iv_return = ENOLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "NOFLSH", 6)) {
    /*                  ^        */
#ifdef NOFLSH
      *iv_return = NOFLSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "ENOMEM", 6)) {
    /*                  ^        */
#ifdef ENOMEM
      *iv_return = ENOMEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PARMRK", 6)) {
    /*                  ^        */
#ifdef PARMRK
      *iv_return = PARMRK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "ERANGE", 6)) {
    /*                  ^        */
#ifdef ERANGE
      *iv_return = ERANGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ICANON", 6)) {
    /*                  ^        */
#ifdef ICANON
      *iv_return = ICANON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CSTOPB", 6)) {
    /*                  ^        */
#ifdef CSTOPB
      *iv_return = CSTOPB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ECHONL", 6)) {
    /*                  ^        */
#ifdef ECHONL
      *iv_return = ECHONL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PARODD", 6)) {
    /*                  ^        */
#ifdef PARODD
      *iv_return = PARODD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCIOFF", 6)) {
    /*                  ^        */
#ifdef TCIOFF
      *iv_return = TCIOFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCOOFF", 6)) {
    /*                  ^        */
#ifdef TCOOFF
      *iv_return = TCOOFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "IGNPAR", 6)) {
    /*                  ^        */
#ifdef IGNPAR
      *iv_return = IGNPAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "ISTRIP", 6)) {
    /*                  ^        */
#ifdef ISTRIP
      *iv_return = ISTRIP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BUFSIZ", 6)) {
    /*                  ^        */
#ifdef BUFSIZ
      *iv_return = BUFSIZ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENOSPC", 6)) {
    /*                  ^        */
#ifdef ENOSPC
      *iv_return = ENOSPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENOSYS", 6)) {
    /*                  ^        */
#ifdef ENOSYS
      *iv_return = ENOSYS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "ENOTTY", 6)) {
    /*                  ^        */
#ifdef ENOTTY
      *iv_return = ENOTTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "IEXTEN", 6)) {
    /*                  ^        */
#ifdef IEXTEN
      *iv_return = IEXTEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TOSTOP", 6)) {
    /*                  ^        */
#ifdef TOSTOP
      *iv_return = TOSTOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EDQUOT", 6)) {
    /*                  ^        */
#ifdef EDQUOT
      *iv_return = EDQUOT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EFAULT", 6)) {
    /*                  ^        */
#ifdef EFAULT
      *iv_return = EFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "EINVAL", 6)) {
    /*                  ^        */
#ifdef EINVAL
      *iv_return = EINVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "O_EXCL", 6)) {
    /*                  ^        */
#ifdef O_EXCL
      *iv_return = O_EXCL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ARG_MAX CLK_TCK DBL_DIG DBL_MAX DBL_MIN EDEADLK EISCONN ENOBUFS ENOEXEC
     ENOTBLK ENOTDIR EREMOTE ETXTBSY FLT_DIG FLT_MAX FLT_MIN F_DUPFD F_GETFD
     F_GETFL F_GETLK F_RDLCK F_SETFD F_SETFL F_SETLK F_UNLCK F_WRLCK INT_MAX
     INT_MIN LC_TIME O_CREAT O_TRUNC SIGABRT SIGALRM SIGCHLD SIGCONT SIGKILL
     SIGPIPE SIGQUIT SIGSEGV SIGSTOP SIGTERM SIGTSTP SIGTTIN SIGTTOU SIGUSR1
     SIGUSR2 SIG_DFL SIG_ERR SIG_IGN S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO
     S_IRWXU S_ISGID S_ISUID S_IWGRP S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR
     TCSANOW TMP_MAX WNOHANG */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case '1':
    if (memEQ(name, "SIGUSR1", 7)) {
    /*                     ^      */
#ifdef SIGUSR1
      *iv_return = SIGUSR1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "SIGUSR2", 7)) {
    /*                     ^      */
#ifdef SIGUSR2
      *iv_return = SIGUSR2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "ENOEXEC", 7)) {
    /*                     ^      */
#ifdef ENOEXEC
      *iv_return = ENOEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_TRUNC", 7)) {
    /*                     ^      */
#ifdef O_TRUNC
      *iv_return = O_TRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "F_DUPFD", 7)) {
    /*                     ^      */
#ifdef F_DUPFD
      *iv_return = F_DUPFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_GETFD", 7)) {
    /*                     ^      */
#ifdef F_GETFD
      *iv_return = F_GETFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETFD", 7)) {
    /*                     ^      */
#ifdef F_SETFD
      *iv_return = F_SETFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGCHLD", 7)) {
    /*                     ^      */
#ifdef SIGCHLD
      *iv_return = SIGCHLD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_ISGID", 7)) {
    /*                     ^      */
#ifdef S_ISGID
      *iv_return = S_ISGID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_ISUID", 7)) {
    /*                     ^      */
#ifdef S_ISUID
      *iv_return = S_ISUID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EREMOTE", 7)) {
    /*                     ^      */
#ifdef EREMOTE
      *iv_return = EREMOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LC_TIME", 7)) {
    /*                     ^      */
#ifdef LC_TIME
      *iv_return = LC_TIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGPIPE", 7)) {
    /*                     ^      */
#ifdef SIGPIPE
      *iv_return = SIGPIPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DBL_DIG", 7)) {
    /*                     ^      */
#ifdef DBL_DIG
      *nv_return = DBL_DIG;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_DIG", 7)) {
    /*                     ^      */
#ifdef FLT_DIG
      *nv_return = FLT_DIG;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXG", 7)) {
    /*                     ^      */
#ifdef S_IRWXG
      *iv_return = S_IRWXG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WNOHANG", 7)) {
    /*                     ^      */
#ifdef WNOHANG
      *iv_return = WNOHANG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "S_IROTH", 7)) {
    /*                     ^      */
#ifdef S_IROTH
      *iv_return = S_IROTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWOTH", 7)) {
    /*                     ^      */
#ifdef S_IWOTH
      *iv_return = S_IWOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXOTH", 7)) {
    /*                     ^      */
#ifdef S_IXOTH
      *iv_return = S_IXOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CLK_TCK", 7)) {
    /*                     ^      */
#ifdef CLK_TCK
      *iv_return = CLK_TCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EDEADLK", 7)) {
    /*                     ^      */
#ifdef EDEADLK
      *iv_return = EDEADLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENOTBLK", 7)) {
    /*                     ^      */
#ifdef ENOTBLK
      *iv_return = ENOTBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_GETLK", 7)) {
    /*                     ^      */
#ifdef F_GETLK
      *iv_return = F_GETLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_RDLCK", 7)) {
    /*                     ^      */
#ifdef F_RDLCK
      *iv_return = F_RDLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETLK", 7)) {
    /*                     ^      */
#ifdef F_SETLK
      *iv_return = F_SETLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_UNLCK", 7)) {
    /*                     ^      */
#ifdef F_UNLCK
      *iv_return = F_UNLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_WRLCK", 7)) {
    /*                     ^      */
#ifdef F_WRLCK
      *iv_return = F_WRLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "F_GETFL", 7)) {
    /*                     ^      */
#ifdef F_GETFL
      *iv_return = F_GETFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETFL", 7)) {
    /*                     ^      */
#ifdef F_SETFL
      *iv_return = F_SETFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGKILL", 7)) {
    /*                     ^      */
#ifdef SIGKILL
      *iv_return = SIGKILL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIG_DFL", 7)) {
    /*                     ^      */
#ifdef SIG_DFL
      *iv_return = (IV)SIG_DFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SIGALRM", 7)) {
    /*                     ^      */
#ifdef SIGALRM
      *iv_return = SIGALRM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGTERM", 7)) {
    /*                     ^      */
#ifdef SIGTERM
      *iv_return = SIGTERM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DBL_MIN", 7)) {
    /*                     ^      */
#ifdef DBL_MIN
      *nv_return = DBL_MIN;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EISCONN", 7)) {
    /*                     ^      */
#ifdef EISCONN
      *iv_return = EISCONN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MIN", 7)) {
    /*                     ^      */
#ifdef FLT_MIN
      *nv_return = FLT_MIN;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "INT_MIN", 7)) {
    /*                     ^      */
#ifdef INT_MIN
      *iv_return = INT_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGTTIN", 7)) {
    /*                     ^      */
#ifdef SIGTTIN
      *iv_return = SIGTTIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIG_IGN", 7)) {
    /*                     ^      */
#ifdef SIG_IGN
      *iv_return = (IV)SIG_IGN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "S_IRWXO", 7)) {
    /*                     ^      */
#ifdef S_IRWXO
      *iv_return = S_IRWXO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "SIGSTOP", 7)) {
    /*                     ^      */
#ifdef SIGSTOP
      *iv_return = SIGSTOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGTSTP", 7)) {
    /*                     ^      */
#ifdef SIGTSTP
      *iv_return = SIGTSTP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRGRP", 7)) {
    /*                     ^      */
#ifdef S_IRGRP
      *iv_return = S_IRGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWGRP", 7)) {
    /*                     ^      */
#ifdef S_IWGRP
      *iv_return = S_IWGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXGRP", 7)) {
    /*                     ^      */
#ifdef S_IXGRP
      *iv_return = S_IXGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "ENOTDIR", 7)) {
    /*                     ^      */
#ifdef ENOTDIR
      *iv_return = ENOTDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIG_ERR", 7)) {
    /*                     ^      */
#ifdef SIG_ERR
      *iv_return = (IV)SIG_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRUSR", 7)) {
    /*                     ^      */
#ifdef S_IRUSR
      *iv_return = S_IRUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWUSR", 7)) {
    /*                     ^      */
#ifdef S_IWUSR
      *iv_return = S_IWUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXUSR", 7)) {
    /*                     ^      */
#ifdef S_IXUSR
      *iv_return = S_IXUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "ENOBUFS", 7)) {
    /*                     ^      */
#ifdef ENOBUFS
      *iv_return = ENOBUFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "O_CREAT", 7)) {
    /*                     ^      */
#ifdef O_CREAT
      *iv_return = O_CREAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGABRT", 7)) {
    /*                     ^      */
#ifdef SIGABRT
      *iv_return = SIGABRT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGCONT", 7)) {
    /*                     ^      */
#ifdef SIGCONT
      *iv_return = SIGCONT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIGQUIT", 7)) {
    /*                     ^      */
#ifdef SIGQUIT
      *iv_return = SIGQUIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "SIGTTOU", 7)) {
    /*                     ^      */
#ifdef SIGTTOU
      *iv_return = SIGTTOU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXU", 7)) {
    /*                     ^      */
#ifdef S_IRWXU
      *iv_return = S_IRWXU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "SIGSEGV", 7)) {
    /*                     ^      */
#ifdef SIGSEGV
      *iv_return = SIGSEGV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "TCSANOW", 7)) {
    /*                     ^      */
#ifdef TCSANOW
      *iv_return = TCSANOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "ARG_MAX", 7)) {
    /*                     ^      */
#ifdef ARG_MAX
      *iv_return = ARG_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DBL_MAX", 7)) {
    /*                     ^      */
#ifdef DBL_MAX
      *nv_return = DBL_MAX;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MAX", 7)) {
    /*                     ^      */
#ifdef FLT_MAX
      *nv_return = FLT_MAX;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "INT_MAX", 7)) {
    /*                     ^      */
#ifdef INT_MAX
      *iv_return = INT_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TMP_MAX", 7)) {
    /*                     ^      */
#ifdef TMP_MAX
      *iv_return = TMP_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "ETXTBSY", 7)) {
    /*                     ^      */
#ifdef ETXTBSY
      *iv_return = ETXTBSY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CHAR_BIT CHAR_MAX CHAR_MIN EALREADY EMSGSIZE ENETDOWN ENOTCONN ENOTSOCK
     EPROCLIM ERESTART F_SETLKW HUGE_VAL LC_CTYPE LDBL_DIG LDBL_MAX LDBL_MIN
     LINK_MAX LONG_MAX LONG_MIN L_tmpnam NAME_MAX OPEN_MAX O_APPEND O_NOCTTY
     O_RDONLY O_WRONLY PATH_MAX PIPE_BUF RAND_MAX SEEK_CUR SEEK_END SEEK_SET
     SHRT_MAX SHRT_MIN TCIFLUSH TCOFLUSH UINT_MAX */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'A':
    if (memEQ(name, "CHAR_BIT", 8)) {
    /*                 ^           */
#ifdef CHAR_BIT
      *iv_return = CHAR_BIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CHAR_MAX", 8)) {
    /*                 ^           */
#ifdef CHAR_MAX
      *iv_return = CHAR_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CHAR_MIN", 8)) {
    /*                 ^           */
#ifdef CHAR_MIN
      *iv_return = CHAR_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_APPEND", 8)) {
    /*                 ^           */
#ifdef O_APPEND
      *iv_return = O_APPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "LDBL_DIG", 8)) {
    /*                 ^           */
#ifdef LDBL_DIG
      *nv_return = LDBL_DIG;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LDBL_MAX", 8)) {
    /*                 ^           */
#ifdef LDBL_MAX
      *nv_return = LDBL_MAX;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LDBL_MIN", 8)) {
    /*                 ^           */
#ifdef LDBL_MIN
      *nv_return = LDBL_MIN;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "ENETDOWN", 8)) {
    /*                 ^           */
#ifdef ENETDOWN
      *iv_return = ENETDOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ERESTART", 8)) {
    /*                 ^           */
#ifdef ERESTART
      *iv_return = ERESTART;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "OPEN_MAX", 8)) {
    /*                 ^           */
#ifdef OPEN_MAX
      *iv_return = OPEN_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEEK_CUR", 8)) {
    /*                 ^           */
#ifdef SEEK_CUR
      *iv_return = SEEK_CUR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEEK_END", 8)) {
    /*                 ^           */
#ifdef SEEK_END
      *iv_return = SEEK_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEEK_SET", 8)) {
    /*                 ^           */
#ifdef SEEK_SET
      *iv_return = SEEK_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "HUGE_VAL", 8)) {
    /*                 ^           */
#if (defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)) || defined(HUGE_VAL)
	/* HUGE_VALL is admittedly non-POSIX but if we are using long doubles
	 * we might as well use long doubles. --jhi */
      *nv_return = 
#if defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)
                   HUGE_VALL
#else
                   HUGE_VAL
#endif
                           ;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "TCIFLUSH", 8)) {
    /*                 ^           */
#ifdef TCIFLUSH
      *iv_return = TCIFLUSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EALREADY", 8)) {
    /*                 ^           */
#ifdef EALREADY
      *iv_return = EALREADY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "NAME_MAX", 8)) {
    /*                 ^           */
#ifdef NAME_MAX
      *iv_return = NAME_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LINK_MAX", 8)) {
    /*                 ^           */
#ifdef LINK_MAX
      *iv_return = LINK_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LONG_MAX", 8)) {
    /*                 ^           */
#ifdef LONG_MAX
      *iv_return = LONG_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LONG_MIN", 8)) {
    /*                 ^           */
#ifdef LONG_MIN
      *iv_return = LONG_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_NOCTTY", 8)) {
    /*                 ^           */
#ifdef O_NOCTTY
      *iv_return = O_NOCTTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RAND_MAX", 8)) {
    /*                 ^           */
#ifdef RAND_MAX
      *iv_return = RAND_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "UINT_MAX", 8)) {
    /*                 ^           */
#ifdef UINT_MAX
      *iv_return = (IV) UINT_MAX;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "ENOTCONN", 8)) {
    /*                 ^           */
#ifdef ENOTCONN
      *iv_return = ENOTCONN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENOTSOCK", 8)) {
    /*                 ^           */
#ifdef ENOTSOCK
      *iv_return = ENOTSOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCOFLUSH", 8)) {
    /*                 ^           */
#ifdef TCOFLUSH
      *iv_return = TCOFLUSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "PIPE_BUF", 8)) {
    /*                 ^           */
#ifdef PIPE_BUF
      *iv_return = PIPE_BUF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EPROCLIM", 8)) {
    /*                 ^           */
#ifdef EPROCLIM
      *iv_return = EPROCLIM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_RDONLY", 8)) {
    /*                 ^           */
#ifdef O_RDONLY
      *iv_return = O_RDONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHRT_MAX", 8)) {
    /*                 ^           */
#ifdef SHRT_MAX
      *iv_return = SHRT_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHRT_MIN", 8)) {
    /*                 ^           */
#ifdef SHRT_MIN
      *iv_return = SHRT_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EMSGSIZE", 8)) {
    /*                 ^           */
#ifdef EMSGSIZE
      *iv_return = EMSGSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETLKW", 8)) {
    /*                 ^           */
#ifdef F_SETLKW
      *iv_return = F_SETLKW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "PATH_MAX", 8)) {
    /*                 ^           */
#ifdef PATH_MAX
      *iv_return = PATH_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "O_WRONLY", 8)) {
    /*                 ^           */
#ifdef O_WRONLY
      *iv_return = O_WRONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "LC_CTYPE", 8)) {
    /*                 ^           */
#ifdef LC_CTYPE
      *iv_return = LC_CTYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "L_tmpnam", 8)) {
    /*                 ^           */
#ifdef L_tmpnam
      *iv_return = L_tmpnam;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CHILD_MAX EHOSTDOWN ENETRESET ENOTEMPTY ESHUTDOWN ETIMEDOUT FLT_RADIX
     L_ctermid L_cuserid L_tmpname MAX_CANON MAX_INPUT O_ACCMODE SCHAR_MAX
     SCHAR_MIN SIG_BLOCK SSIZE_MAX TCIOFLUSH TCSADRAIN TCSAFLUSH UCHAR_MAX
     ULONG_MAX USHRT_MAX WUNTRACED */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'A':
    if (memEQ(name, "SCHAR_MAX", 9)) {
    /*                  ^           */
#ifdef SCHAR_MAX
      *iv_return = SCHAR_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCHAR_MIN", 9)) {
    /*                  ^           */
#ifdef SCHAR_MIN
      *iv_return = SCHAR_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCSADRAIN", 9)) {
    /*                  ^           */
#ifdef TCSADRAIN
      *iv_return = TCSADRAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "TCSAFLUSH", 9)) {
    /*                  ^           */
#ifdef TCSAFLUSH
      *iv_return = TCSAFLUSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "UCHAR_MAX", 9)) {
    /*                  ^           */
#ifdef UCHAR_MAX
      *iv_return = (IV) UCHAR_MAX;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "O_ACCMODE", 9)) {
    /*                  ^           */
#ifdef O_ACCMODE
      *iv_return = O_ACCMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CHILD_MAX", 9)) {
    /*                  ^           */
#ifdef CHILD_MAX
      *iv_return = CHILD_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "ETIMEDOUT", 9)) {
    /*                  ^           */
#ifdef ETIMEDOUT
      *iv_return = ETIMEDOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "ULONG_MAX", 9)) {
    /*                  ^           */
#ifdef ULONG_MAX
      *iv_return = (IV) ULONG_MAX;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "TCIOFLUSH", 9)) {
    /*                  ^           */
#ifdef TCIOFLUSH
      *iv_return = TCIOFLUSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "USHRT_MAX", 9)) {
    /*                  ^           */
#ifdef USHRT_MAX
      *iv_return = (IV) USHRT_MAX;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EHOSTDOWN", 9)) {
    /*                  ^           */
#ifdef EHOSTDOWN
      *iv_return = EHOSTDOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "ENETRESET", 9)) {
    /*                  ^           */
#ifdef ENETRESET
      *iv_return = ENETRESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENOTEMPTY", 9)) {
    /*                  ^           */
#ifdef ENOTEMPTY
      *iv_return = ENOTEMPTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WUNTRACED", 9)) {
    /*                  ^           */
#ifdef WUNTRACED
      *iv_return = WUNTRACED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "ESHUTDOWN", 9)) {
    /*                  ^           */
#ifdef ESHUTDOWN
      *iv_return = ESHUTDOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "SSIZE_MAX", 9)) {
    /*                  ^           */
#ifdef SSIZE_MAX
      *iv_return = SSIZE_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "FLT_RADIX", 9)) {
    /*                  ^           */
#ifdef FLT_RADIX
      *nv_return = FLT_RADIX;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MAX_CANON", 9)) {
    /*                  ^           */
#ifdef MAX_CANON
      *iv_return = MAX_CANON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MAX_INPUT", 9)) {
    /*                  ^           */
#ifdef MAX_INPUT
      *iv_return = MAX_INPUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIG_BLOCK", 9)) {
    /*                  ^           */
#ifdef SIG_BLOCK
      *iv_return = SIG_BLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "L_tmpname", 9)) {
    /*                  ^           */
#ifdef L_tmpname
      *iv_return = L_tmpnam;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "L_ctermid", 9)) {
    /*                  ^           */
#ifdef L_ctermid
      *iv_return = L_ctermid;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "L_cuserid", 9)) {
    /*                  ^           */
#ifdef L_cuserid
      *iv_return = L_cuserid;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EADDRINUSE ECONNRESET EOPNOTSUPP EPROTOTYPE FD_CLOEXEC FLT_ROUNDS
     LC_COLLATE LC_NUMERIC MB_CUR_MAX MB_LEN_MAX O_NONBLOCK SA_NODEFER
     SA_ONSTACK SA_RESTART SA_SIGINFO STREAM_MAX TZNAME_MAX */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'B':
    if (memEQ(name, "O_NONBLOCK", 10)) {
    /*                    ^           */
#ifdef O_NONBLOCK
      *iv_return = O_NONBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "SA_NODEFER", 10)) {
    /*                    ^           */
#ifdef SA_NODEFER
      *iv_return = (IV) SA_NODEFER;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "TZNAME_MAX", 10)) {
    /*                    ^           */
#ifdef TZNAME_MAX
      *iv_return = TZNAME_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SA_SIGINFO", 10)) {
    /*                    ^           */
#ifdef SA_SIGINFO
      *iv_return = (IV) SA_SIGINFO;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EADDRINUSE", 10)) {
    /*                    ^           */
#ifdef EADDRINUSE
      *iv_return = EADDRINUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LC_COLLATE", 10)) {
    /*                    ^           */
#ifdef LC_COLLATE
      *iv_return = LC_COLLATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LC_NUMERIC", 10)) {
    /*                    ^           */
#ifdef LC_NUMERIC
      *iv_return = LC_NUMERIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "STREAM_MAX", 10)) {
    /*                    ^           */
#ifdef STREAM_MAX
      *iv_return = STREAM_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MB_LEN_MAX", 10)) {
    /*                    ^           */
#ifdef MB_LEN_MAX
      *iv_return = MB_LEN_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EPROTOTYPE", 10)) {
    /*                    ^           */
#ifdef EPROTOTYPE
      *iv_return = EPROTOTYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FD_CLOEXEC", 10)) {
    /*                    ^           */
#ifdef FD_CLOEXEC
      *iv_return = FD_CLOEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_ROUNDS", 10)) {
    /*                    ^           */
#ifdef FLT_ROUNDS
      *nv_return = FLT_ROUNDS;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "ECONNRESET", 10)) {
    /*                    ^           */
#ifdef ECONNRESET
      *iv_return = ECONNRESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MB_CUR_MAX", 10)) {
    /*                    ^           */
#ifdef MB_CUR_MAX
      *iv_return = MB_CUR_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SA_ONSTACK", 10)) {
    /*                    ^           */
#ifdef SA_ONSTACK
      *iv_return = (IV) SA_ONSTACK;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SA_RESTART", 10)) {
    /*                    ^           */
#ifdef SA_RESTART
      *iv_return = (IV) SA_RESTART;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EOPNOTSUPP", 10)) {
    /*                    ^           */
#ifdef EOPNOTSUPP
      *iv_return = EOPNOTSUPP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DBL_EPSILON DBL_MAX_EXP DBL_MIN_EXP EINPROGRESS ENETUNREACH ENOPROTOOPT
     EWOULDBLOCK FLT_EPSILON FLT_MAX_EXP FLT_MIN_EXP LC_MESSAGES LC_MONETARY
     NGROUPS_MAX SIG_SETMASK SIG_UNBLOCK _SC_ARG_MAX _SC_CLK_TCK _SC_VERSION */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "DBL_MAX_EXP", 11)) {
    /*                    ^            */
#ifdef DBL_MAX_EXP
      *nv_return = DBL_MAX_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MAX_EXP", 11)) {
    /*                    ^            */
#ifdef FLT_MAX_EXP
      *nv_return = FLT_MAX_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "EWOULDBLOCK", 11)) {
    /*                    ^            */
#ifdef EWOULDBLOCK
      *iv_return = EWOULDBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SIG_SETMASK", 11)) {
    /*                    ^            */
#ifdef SIG_SETMASK
      *iv_return = SIG_SETMASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_SC_VERSION", 11)) {
    /*                    ^            */
#ifdef _SC_VERSION
      *iv_return = _SC_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DBL_MIN_EXP", 11)) {
    /*                    ^            */
#ifdef DBL_MIN_EXP
      *nv_return = DBL_MIN_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MIN_EXP", 11)) {
    /*                    ^            */
#ifdef FLT_MIN_EXP
      *nv_return = FLT_MIN_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "_SC_CLK_TCK", 11)) {
    /*                    ^            */
#ifdef _SC_CLK_TCK
      *iv_return = _SC_CLK_TCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "ENETUNREACH", 11)) {
    /*                    ^            */
#ifdef ENETUNREACH
      *iv_return = ENETUNREACH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LC_MONETARY", 11)) {
    /*                    ^            */
#ifdef LC_MONETARY
      *iv_return = LC_MONETARY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SIG_UNBLOCK", 11)) {
    /*                    ^            */
#ifdef SIG_UNBLOCK
      *iv_return = SIG_UNBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EINPROGRESS", 11)) {
    /*                    ^            */
#ifdef EINPROGRESS
      *iv_return = EINPROGRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENOPROTOOPT", 11)) {
    /*                    ^            */
#ifdef ENOPROTOOPT
      *iv_return = ENOPROTOOPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DBL_EPSILON", 11)) {
    /*                    ^            */
#ifdef DBL_EPSILON
      *nv_return = DBL_EPSILON;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_EPSILON", 11)) {
    /*                    ^            */
#ifdef FLT_EPSILON
      *nv_return = FLT_EPSILON;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "NGROUPS_MAX", 11)) {
    /*                    ^            */
#ifdef NGROUPS_MAX
      *iv_return = NGROUPS_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "_SC_ARG_MAX", 11)) {
    /*                    ^            */
#ifdef _SC_ARG_MAX
      *iv_return = _SC_ARG_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LC_MESSAGES", 11)) {
    /*                    ^            */
#ifdef LC_MESSAGES
      *iv_return = LC_MESSAGES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DBL_MANT_DIG EAFNOSUPPORT ECONNABORTED ECONNREFUSED EDESTADDRREQ
     EHOSTUNREACH ENAMETOOLONG EPFNOSUPPORT ETOOMANYREFS EXIT_FAILURE
     EXIT_SUCCESS FILENAME_MAX FLT_MANT_DIG LDBL_EPSILON LDBL_MAX_EXP
     LDBL_MIN_EXP SA_NOCLDSTOP SA_NOCLDWAIT SA_RESETHAND STDIN_FILENO
     _PC_LINK_MAX _PC_NAME_MAX _PC_NO_TRUNC _PC_PATH_MAX _PC_PIPE_BUF
     _PC_VDISABLE _SC_OPEN_MAX */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'C':
    if (memEQ(name, "EXIT_SUCCESS", 12)) {
    /*                      ^           */
#ifdef EXIT_SUCCESS
      *iv_return = EXIT_SUCCESS;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "EDESTADDRREQ", 12)) {
    /*                      ^           */
#ifdef EDESTADDRREQ
      *iv_return = EDESTADDRREQ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SA_NOCLDSTOP", 12)) {
    /*                      ^           */
#ifdef SA_NOCLDSTOP
      *iv_return = (IV) SA_NOCLDSTOP;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SA_NOCLDWAIT", 12)) {
    /*                      ^           */
#ifdef SA_NOCLDWAIT
      *iv_return = (IV) SA_NOCLDWAIT;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "FILENAME_MAX", 12)) {
    /*                      ^           */
#ifdef FILENAME_MAX
      *iv_return = FILENAME_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_PC_NAME_MAX", 12)) {
    /*                      ^           */
#ifdef _PC_NAME_MAX
      *iv_return = _PC_NAME_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_PC_PIPE_BUF", 12)) {
    /*                      ^           */
#ifdef _PC_PIPE_BUF
      *iv_return = _PC_PIPE_BUF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "ECONNREFUSED", 12)) {
    /*                      ^           */
#ifdef ECONNREFUSED
      *iv_return = ECONNREFUSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "_PC_PATH_MAX", 12)) {
    /*                      ^           */
#ifdef _PC_PATH_MAX
      *iv_return = _PC_PATH_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EXIT_FAILURE", 12)) {
    /*                      ^           */
#ifdef EXIT_FAILURE
      *iv_return = EXIT_FAILURE;
      return PERL_constant_ISIV;
#else
      *iv_return = 1;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "STDIN_FILENO", 12)) {
    /*                      ^           */
#ifdef STDIN_FILENO
      *iv_return = STDIN_FILENO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "_PC_LINK_MAX", 12)) {
    /*                      ^           */
#ifdef _PC_LINK_MAX
      *iv_return = _PC_LINK_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LDBL_MIN_EXP", 12)) {
    /*                      ^           */
#ifdef LDBL_MIN_EXP
      *nv_return = LDBL_MIN_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_SC_OPEN_MAX", 12)) {
    /*                      ^           */
#ifdef _SC_OPEN_MAX
      *iv_return = _SC_OPEN_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "ECONNABORTED", 12)) {
    /*                      ^           */
#ifdef ECONNABORTED
      *iv_return = ECONNABORTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ENAMETOOLONG", 12)) {
    /*                      ^           */
#ifdef ENAMETOOLONG
      *iv_return = ENAMETOOLONG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EAFNOSUPPORT", 12)) {
    /*                      ^           */
#ifdef EAFNOSUPPORT
      *iv_return = EAFNOSUPPORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EPFNOSUPPORT", 12)) {
    /*                      ^           */
#ifdef EPFNOSUPPORT
      *iv_return = EPFNOSUPPORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EHOSTUNREACH", 12)) {
    /*                      ^           */
#ifdef EHOSTUNREACH
      *iv_return = EHOSTUNREACH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LDBL_EPSILON", 12)) {
    /*                      ^           */
#ifdef LDBL_EPSILON
      *nv_return = LDBL_EPSILON;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_PC_VDISABLE", 12)) {
    /*                      ^           */
#ifdef _PC_VDISABLE
      *iv_return = _PC_VDISABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DBL_MANT_DIG", 12)) {
    /*                      ^           */
#ifdef DBL_MANT_DIG
      *nv_return = DBL_MANT_DIG;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MANT_DIG", 12)) {
    /*                      ^           */
#ifdef FLT_MANT_DIG
      *nv_return = FLT_MANT_DIG;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SA_RESETHAND", 12)) {
    /*                      ^           */
#ifdef SA_RESETHAND
      *iv_return = (IV) SA_RESETHAND;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_PC_NO_TRUNC", 12)) {
    /*                      ^           */
#ifdef _PC_NO_TRUNC
      *iv_return = _PC_NO_TRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "LDBL_MAX_EXP", 12)) {
    /*                      ^           */
#ifdef LDBL_MAX_EXP
      *nv_return = LDBL_MAX_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "ETOOMANYREFS", 12)) {
    /*                      ^           */
#ifdef ETOOMANYREFS
      *iv_return = ETOOMANYREFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EADDRNOTAVAIL LDBL_MANT_DIG STDERR_FILENO STDOUT_FILENO _PC_MAX_CANON
     _PC_MAX_INPUT _SC_CHILD_MAX _SC_SAVED_IDS */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "EADDRNOTAVAIL", 13)) {
    /*                         ^         */
#ifdef EADDRNOTAVAIL
      *iv_return = EADDRNOTAVAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "LDBL_MANT_DIG", 13)) {
    /*                         ^         */
#ifdef LDBL_MANT_DIG
      *nv_return = LDBL_MANT_DIG;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "STDERR_FILENO", 13)) {
    /*                         ^         */
#ifdef STDERR_FILENO
      *iv_return = STDERR_FILENO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "STDOUT_FILENO", 13)) {
    /*                         ^         */
#ifdef STDOUT_FILENO
      *iv_return = STDOUT_FILENO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "_SC_SAVED_IDS", 13)) {
    /*                         ^         */
#ifdef _SC_SAVED_IDS
      *iv_return = _SC_SAVED_IDS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "_SC_CHILD_MAX", 13)) {
    /*                         ^         */
#ifdef _SC_CHILD_MAX
      *iv_return = _SC_CHILD_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "_PC_MAX_CANON", 13)) {
    /*                         ^         */
#ifdef _PC_MAX_CANON
      *iv_return = _PC_MAX_CANON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "_PC_MAX_INPUT", 13)) {
    /*                         ^         */
#ifdef _PC_MAX_INPUT
      *iv_return = _PC_MAX_INPUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CLOCKS_PER_SEC DBL_MAX_10_EXP DBL_MIN_10_EXP FLT_MAX_10_EXP FLT_MIN_10_EXP
     _POSIX_ARG_MAX _POSIX_VERSION _SC_STREAM_MAX _SC_TZNAME_MAX */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "DBL_MAX_10_EXP", 14)) {
    /*                    ^               */
#ifdef DBL_MAX_10_EXP
      *nv_return = DBL_MAX_10_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MAX_10_EXP", 14)) {
    /*                    ^               */
#ifdef FLT_MAX_10_EXP
      *nv_return = FLT_MAX_10_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DBL_MIN_10_EXP", 14)) {
    /*                    ^               */
#ifdef DBL_MIN_10_EXP
      *nv_return = DBL_MIN_10_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FLT_MIN_10_EXP", 14)) {
    /*                    ^               */
#ifdef FLT_MIN_10_EXP
      *nv_return = FLT_MIN_10_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CLOCKS_PER_SEC", 14)) {
    /*                    ^               */
#ifdef CLOCKS_PER_SEC
      *iv_return = CLOCKS_PER_SEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "_SC_STREAM_MAX", 14)) {
    /*                    ^               */
#ifdef _SC_STREAM_MAX
      *iv_return = _SC_STREAM_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "_POSIX_ARG_MAX", 14)) {
    /*                    ^               */
#ifdef _POSIX_ARG_MAX
      *iv_return = _POSIX_ARG_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "_POSIX_VERSION", 14)) {
    /*                    ^               */
#ifdef _POSIX_VERSION
      *iv_return = _POSIX_VERSION;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "_SC_TZNAME_MAX", 14)) {
    /*                    ^               */
#ifdef _SC_TZNAME_MAX
      *iv_return = _SC_TZNAME_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EPROTONOSUPPORT ESOCKTNOSUPPORT LDBL_MAX_10_EXP LDBL_MIN_10_EXP
     _POSIX_LINK_MAX _POSIX_NAME_MAX _POSIX_NO_TRUNC _POSIX_OPEN_MAX
     _POSIX_PATH_MAX _POSIX_PIPE_BUF _POSIX_VDISABLE _SC_JOB_CONTROL
     _SC_NGROUPS_MAX */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case '1':
    if (memEQ(name, "LDBL_MAX_10_EXP", 15)) {
    /*                        ^            */
#ifdef LDBL_MAX_10_EXP
      *nv_return = LDBL_MAX_10_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LDBL_MIN_10_EXP", 15)) {
    /*                        ^            */
#ifdef LDBL_MIN_10_EXP
      *nv_return = LDBL_MIN_10_EXP;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "_POSIX_OPEN_MAX", 15)) {
    /*                        ^            */
#ifdef _POSIX_OPEN_MAX
      *iv_return = _POSIX_OPEN_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "_POSIX_VDISABLE", 15)) {
    /*                        ^            */
#ifdef _POSIX_VDISABLE
      *iv_return = _POSIX_VDISABLE;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "_POSIX_NAME_MAX", 15)) {
    /*                        ^            */
#ifdef _POSIX_NAME_MAX
      *iv_return = _POSIX_NAME_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "_POSIX_LINK_MAX", 15)) {
    /*                        ^            */
#ifdef _POSIX_LINK_MAX
      *iv_return = _POSIX_LINK_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "_SC_JOB_CONTROL", 15)) {
    /*                        ^            */
#ifdef _SC_JOB_CONTROL
      *iv_return = _SC_JOB_CONTROL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "_POSIX_PIPE_BUF", 15)) {
    /*                        ^            */
#ifdef _POSIX_PIPE_BUF
      *iv_return = _POSIX_PIPE_BUF;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "_SC_NGROUPS_MAX", 15)) {
    /*                        ^            */
#ifdef _SC_NGROUPS_MAX
      *iv_return = _SC_NGROUPS_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "_POSIX_PATH_MAX", 15)) {
    /*                        ^            */
#ifdef _POSIX_PATH_MAX
      *iv_return = _POSIX_PATH_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EPROTONOSUPPORT", 15)) {
    /*                        ^            */
#ifdef EPROTONOSUPPORT
      *iv_return = EPROTONOSUPPORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ESOCKTNOSUPPORT", 15)) {
    /*                        ^            */
#ifdef ESOCKTNOSUPPORT
      *iv_return = ESOCKTNOSUPPORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "_POSIX_NO_TRUNC", 15)) {
    /*                        ^            */
#ifdef _POSIX_NO_TRUNC
      *iv_return = _POSIX_NO_TRUNC;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (const char *name, IV *iv_return, NV *nv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     _POSIX_CHILD_MAX _POSIX_MAX_CANON _POSIX_MAX_INPUT _POSIX_SAVED_IDS
     _POSIX_SSIZE_MAX */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'C':
    if (memEQ(name, "_POSIX_MAX_CANON", 16)) {
    /*                          ^           */
#ifdef _POSIX_MAX_CANON
      *iv_return = _POSIX_MAX_CANON;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "_POSIX_CHILD_MAX", 16)) {
    /*                          ^           */
#ifdef _POSIX_CHILD_MAX
      *iv_return = _POSIX_CHILD_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "_POSIX_SAVED_IDS", 16)) {
    /*                          ^           */
#ifdef _POSIX_SAVED_IDS
      *iv_return = 1;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "_POSIX_SSIZE_MAX", 16)) {
    /*                          ^           */
#ifdef _POSIX_SSIZE_MAX
      *iv_return = _POSIX_SSIZE_MAX;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "_POSIX_MAX_INPUT", 16)) {
    /*                          ^           */
#ifdef _POSIX_MAX_INPUT
      *iv_return = _POSIX_MAX_INPUT;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (const char *name, STRLEN len, IV *iv_return, NV *nv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!../../perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV NV UV)};
my @names = (qw(ARG_MAX B0 B110 B1200 B134 B150 B1800 B19200 B200 B2400 B300
	       B38400 B4800 B50 B600 B75 B9600 BRKINT BUFSIZ CHAR_BIT CHAR_MAX
	       CHAR_MIN CHILD_MAX CLK_TCK CLOCAL CLOCKS_PER_SEC CREAD CS5 CS6
	       CS7 CS8 CSIZE CSTOPB E2BIG EACCES EADDRINUSE EADDRNOTAVAIL
	       EAFNOSUPPORT EAGAIN EALREADY EBADF EBUSY ECHILD ECHO ECHOE ECHOK
	       ECHONL ECONNABORTED ECONNREFUSED ECONNRESET EDEADLK EDESTADDRREQ
	       EDOM EDQUOT EEXIST EFAULT EFBIG EHOSTDOWN EHOSTUNREACH
	       EINPROGRESS EINTR EINVAL EIO EISCONN EISDIR ELOOP EMFILE EMLINK
	       EMSGSIZE ENAMETOOLONG ENETDOWN ENETRESET ENETUNREACH ENFILE
	       ENOBUFS ENODEV ENOENT ENOEXEC ENOLCK ENOMEM ENOPROTOOPT ENOSPC
	       ENOSYS ENOTBLK ENOTCONN ENOTDIR ENOTEMPTY ENOTSOCK ENOTTY ENXIO
	       EOF EOPNOTSUPP EPERM EPFNOSUPPORT EPIPE EPROCLIM EPROTONOSUPPORT
	       EPROTOTYPE ERANGE EREMOTE ERESTART EROFS ESHUTDOWN
	       ESOCKTNOSUPPORT ESPIPE ESRCH ESTALE ETIMEDOUT ETOOMANYREFS
	       ETXTBSY EUSERS EWOULDBLOCK EXDEV FD_CLOEXEC FILENAME_MAX F_DUPFD
	       F_GETFD F_GETFL F_GETLK F_OK F_RDLCK F_SETFD F_SETFL F_SETLK
	       F_SETLKW F_UNLCK F_WRLCK HUPCL ICANON ICRNL IEXTEN IGNBRK IGNCR
	       IGNPAR INLCR INPCK INT_MAX INT_MIN ISIG ISTRIP IXOFF IXON LC_ALL
	       LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME
	       LINK_MAX LONG_MAX LONG_MIN L_ctermid L_cuserid L_tmpnam
	       MAX_CANON MAX_INPUT MB_CUR_MAX MB_LEN_MAX NAME_MAX NCCS
	       NGROUPS_MAX NOFLSH OPEN_MAX OPOST O_ACCMODE O_APPEND O_CREAT
	       O_EXCL O_NOCTTY O_NONBLOCK O_RDONLY O_RDWR O_TRUNC O_WRONLY
	       PARENB PARMRK PARODD PATH_MAX PIPE_BUF RAND_MAX R_OK SCHAR_MAX
	       SCHAR_MIN SEEK_CUR SEEK_END SEEK_SET SHRT_MAX SHRT_MIN SIGABRT
	       SIGALRM SIGCHLD SIGCONT SIGFPE SIGHUP SIGILL SIGINT SIGKILL
	       SIGPIPE SIGQUIT SIGSEGV SIGSTOP SIGTERM SIGTSTP SIGTTIN SIGTTOU
	       SIGUSR1 SIGUSR2 SIG_BLOCK SIG_SETMASK SIG_UNBLOCK SSIZE_MAX
	       STDERR_FILENO STDIN_FILENO STDOUT_FILENO STREAM_MAX S_IRGRP
	       S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU S_ISGID S_ISUID S_IWGRP
	       S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR TCIFLUSH TCIOFF
	       TCIOFLUSH TCION TCOFLUSH TCOOFF TCOON TCSADRAIN TCSAFLUSH
	       TCSANOW TMP_MAX TOSTOP TZNAME_MAX VEOF VEOL VERASE VINTR VKILL
	       VMIN VQUIT VSTART VSTOP VSUSP VTIME WNOHANG WUNTRACED W_OK X_OK
	       _PC_CHOWN_RESTRICTED _PC_LINK_MAX _PC_MAX_CANON _PC_MAX_INPUT
	       _PC_NAME_MAX _PC_NO_TRUNC _PC_PATH_MAX _PC_PIPE_BUF _PC_VDISABLE
	       _SC_ARG_MAX _SC_CHILD_MAX _SC_CLK_TCK _SC_JOB_CONTROL
	       _SC_NGROUPS_MAX _SC_OPEN_MAX _SC_SAVED_IDS _SC_STREAM_MAX
	       _SC_TZNAME_MAX _SC_VERSION),
            {name=>"DBL_DIG", type=>"NV"},
            {name=>"DBL_EPSILON", type=>"NV"},
            {name=>"DBL_MANT_DIG", type=>"NV"},
            {name=>"DBL_MAX", type=>"NV"},
            {name=>"DBL_MAX_10_EXP", type=>"NV"},
            {name=>"DBL_MAX_EXP", type=>"NV"},
            {name=>"DBL_MIN", type=>"NV"},
            {name=>"DBL_MIN_10_EXP", type=>"NV"},
            {name=>"DBL_MIN_EXP", type=>"NV"},
            {name=>"EXIT_FAILURE", type=>"IV", default=>["IV", "1"]},
            {name=>"EXIT_SUCCESS", type=>"IV", default=>["IV", "0"]},
            {name=>"FLT_DIG", type=>"NV"},
            {name=>"FLT_EPSILON", type=>"NV"},
            {name=>"FLT_MANT_DIG", type=>"NV"},
            {name=>"FLT_MAX", type=>"NV"},
            {name=>"FLT_MAX_10_EXP", type=>"NV"},
            {name=>"FLT_MAX_EXP", type=>"NV"},
            {name=>"FLT_MIN", type=>"NV"},
            {name=>"FLT_MIN_10_EXP", type=>"NV"},
            {name=>"FLT_MIN_EXP", type=>"NV"},
            {name=>"FLT_RADIX", type=>"NV"},
            {name=>"FLT_ROUNDS", type=>"NV"},
            {name=>"HUGE_VAL", type=>"NV", macro=>["#if (defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)) || defined(HUGE_VAL)\n\t/" . "* HUGE_VALL is admittedly non-POSIX but if we are using long doubles\n\t * we might as well use long doubles. --jhi *" . "/\n", "#endif\n"], value=>"\n#if defined(USE_LONG_DOUBLE) && defined(HUGE_VALL)\n                   HUGE_VALL\n#else\n                   HUGE_VAL\n#endif\n                           "},
            {name=>"LDBL_DIG", type=>"NV"},
            {name=>"LDBL_EPSILON", type=>"NV"},
            {name=>"LDBL_MANT_DIG", type=>"NV"},
            {name=>"LDBL_MAX", type=>"NV"},
            {name=>"LDBL_MAX_10_EXP", type=>"NV"},
            {name=>"LDBL_MAX_EXP", type=>"NV"},
            {name=>"LDBL_MIN", type=>"NV"},
            {name=>"LDBL_MIN_10_EXP", type=>"NV"},
            {name=>"LDBL_MIN_EXP", type=>"NV"},
            {name=>"L_tmpname", type=>"IV", value=>"L_tmpnam"},
            {name=>"NULL", type=>"IV", value=>"0"},
            {name=>"SA_NOCLDSTOP", type=>"UV"},
            {name=>"SA_NOCLDWAIT", type=>"UV"},
            {name=>"SA_NODEFER", type=>"UV"},
            {name=>"SA_ONSTACK", type=>"UV"},
            {name=>"SA_RESETHAND", type=>"UV"},
            {name=>"SA_RESTART", type=>"UV"},
            {name=>"SA_SIGINFO", type=>"UV"},
            {name=>"SIG_DFL", type=>"IV", value=>"(IV)SIG_DFL"},
            {name=>"SIG_ERR", type=>"IV", value=>"(IV)SIG_ERR"},
            {name=>"SIG_IGN", type=>"IV", value=>"(IV)SIG_IGN"},
            {name=>"UCHAR_MAX", type=>"UV"},
            {name=>"UINT_MAX", type=>"UV"},
            {name=>"ULONG_MAX", type=>"UV"},
            {name=>"USHRT_MAX", type=>"UV"},
            {name=>"_POSIX_ARG_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_CHILD_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_CHOWN_RESTRICTED", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_JOB_CONTROL", type=>"IV", value=>"1", default=>["IV", "0"]},
            {name=>"_POSIX_LINK_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_MAX_CANON", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_MAX_INPUT", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_NAME_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_NGROUPS_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_NO_TRUNC", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_OPEN_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_PATH_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_PIPE_BUF", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_SAVED_IDS", type=>"IV", value=>"1", default=>["IV", "0"]},
            {name=>"_POSIX_SSIZE_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_STREAM_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_TZNAME_MAX", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_VDISABLE", type=>"IV", default=>["IV", "0"]},
            {name=>"_POSIX_VERSION", type=>"IV", default=>["IV", "0"]});

print constant_types(); # macro defs
foreach (C_constant ("POSIX", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("POSIX", $types);
__END__
   */

  switch (len) {
  case 2:
    if (memEQ(name, "B0", 2)) {
#ifdef B0
      *iv_return = B0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 3:
    return constant_3 (name, iv_return, nv_return);
    break;
  case 4:
    return constant_4 (name, iv_return, nv_return);
    break;
  case 5:
    return constant_5 (name, iv_return, nv_return);
    break;
  case 6:
    return constant_6 (name, iv_return, nv_return);
    break;
  case 7:
    return constant_7 (name, iv_return, nv_return);
    break;
  case 8:
    return constant_8 (name, iv_return, nv_return);
    break;
  case 9:
    return constant_9 (name, iv_return, nv_return);
    break;
  case 10:
    return constant_10 (name, iv_return, nv_return);
    break;
  case 11:
    return constant_11 (name, iv_return, nv_return);
    break;
  case 12:
    return constant_12 (name, iv_return, nv_return);
    break;
  case 13:
    return constant_13 (name, iv_return, nv_return);
    break;
  case 14:
    return constant_14 (name, iv_return, nv_return);
    break;
  case 15:
    return constant_15 (name, iv_return, nv_return);
    break;
  case 16:
    return constant_16 (name, iv_return, nv_return);
    break;
  case 17:
    /* Names all of length 17.  */
    /* _POSIX_STREAM_MAX _POSIX_TZNAME_MAX */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'S':
      if (memEQ(name, "_POSIX_STREAM_MAX", 17)) {
      /*                      ^                */
#ifdef _POSIX_STREAM_MAX
        *iv_return = _POSIX_STREAM_MAX;
        return PERL_constant_ISIV;
#else
        *iv_return = 0;
        return PERL_constant_ISIV;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "_POSIX_TZNAME_MAX", 17)) {
      /*                      ^                */
#ifdef _POSIX_TZNAME_MAX
        *iv_return = _POSIX_TZNAME_MAX;
        return PERL_constant_ISIV;
#else
        *iv_return = 0;
        return PERL_constant_ISIV;
#endif
      }
      break;
    }
    break;
  case 18:
    /* Names all of length 18.  */
    /* _POSIX_JOB_CONTROL _POSIX_NGROUPS_MAX */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'O':
      if (memEQ(name, "_POSIX_JOB_CONTROL", 18)) {
      /*                           ^            */
#ifdef _POSIX_JOB_CONTROL
        *iv_return = 1;
        return PERL_constant_ISIV;
#else
        *iv_return = 0;
        return PERL_constant_ISIV;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "_POSIX_NGROUPS_MAX", 18)) {
      /*                           ^            */
#ifdef _POSIX_NGROUPS_MAX
        *iv_return = _POSIX_NGROUPS_MAX;
        return PERL_constant_ISIV;
#else
        *iv_return = 0;
        return PERL_constant_ISIV;
#endif
      }
      break;
    }
    break;
  case 20:
    if (memEQ(name, "_PC_CHOWN_RESTRICTED", 20)) {
#ifdef _PC_CHOWN_RESTRICTED
      *iv_return = _PC_CHOWN_RESTRICTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 23:
    if (memEQ(name, "_POSIX_CHOWN_RESTRICTED", 23)) {
#ifdef _POSIX_CHOWN_RESTRICTED
      *iv_return = _POSIX_CHOWN_RESTRICTED;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static void
restore_sigmask(sigset_t *ossetp)
{
	    /* Fortunately, restoring the signal mask can't fail, because
	     * there's nothing we can do about it if it does -- we're not
	     * supposed to return -1 from sigaction unless the disposition
	     * was unaffected.
	     */
	    (void)sigprocmask(SIG_SETMASK, ossetp, (sigset_t *)0);
}

MODULE = SigSet		PACKAGE = POSIX::SigSet		PREFIX = sig

POSIX::SigSet
new(packname = "POSIX::SigSet", ...)
    char *		packname
    CODE:
	{
	    int i;
	    New(0, RETVAL, 1, sigset_t);
	    sigemptyset(RETVAL);
	    for (i = 1; i < items; i++)
		sigaddset(RETVAL, SvIV(ST(i)));
	}
    OUTPUT:
	RETVAL

void
DESTROY(sigset)
	POSIX::SigSet	sigset
    CODE:
	Safefree(sigset);

SysRet
sigaddset(sigset, sig)
	POSIX::SigSet	sigset
	int		sig

SysRet
sigdelset(sigset, sig)
	POSIX::SigSet	sigset
	int		sig

SysRet
sigemptyset(sigset)
	POSIX::SigSet	sigset

SysRet
sigfillset(sigset)
	POSIX::SigSet	sigset

int
sigismember(sigset, sig)
	POSIX::SigSet	sigset
	int		sig


MODULE = Termios	PACKAGE = POSIX::Termios	PREFIX = cf

POSIX::Termios
new(packname = "POSIX::Termios", ...)
    char *		packname
    CODE:
	{
#ifdef I_TERMIOS
	    New(0, RETVAL, 1, struct termios);
#else
	    not_here("termios");
        RETVAL = 0;
#endif
	}
    OUTPUT:
	RETVAL

void
DESTROY(termios_ref)
	POSIX::Termios	termios_ref
    CODE:
#ifdef I_TERMIOS
	Safefree(termios_ref);
#else
	    not_here("termios");
#endif

SysRet
getattr(termios_ref, fd = 0)
	POSIX::Termios	termios_ref
	int		fd
    CODE:
	RETVAL = tcgetattr(fd, termios_ref);
    OUTPUT:
	RETVAL

SysRet
setattr(termios_ref, fd = 0, optional_actions = 0)
	POSIX::Termios	termios_ref
	int		fd
	int		optional_actions
    CODE:
	RETVAL = tcsetattr(fd, optional_actions, termios_ref);
    OUTPUT:
	RETVAL

speed_t
cfgetispeed(termios_ref)
	POSIX::Termios	termios_ref

speed_t
cfgetospeed(termios_ref)
	POSIX::Termios	termios_ref

tcflag_t
getiflag(termios_ref)
	POSIX::Termios	termios_ref
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	RETVAL = termios_ref->c_iflag;
#else
     not_here("getiflag");
     RETVAL = 0;
#endif
    OUTPUT:
	RETVAL

tcflag_t
getoflag(termios_ref)
	POSIX::Termios	termios_ref
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	RETVAL = termios_ref->c_oflag;
#else
     not_here("getoflag");
     RETVAL = 0;
#endif
    OUTPUT:
	RETVAL

tcflag_t
getcflag(termios_ref)
	POSIX::Termios	termios_ref
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	RETVAL = termios_ref->c_cflag;
#else
     not_here("getcflag");
     RETVAL = 0;
#endif
    OUTPUT:
	RETVAL

tcflag_t
getlflag(termios_ref)
	POSIX::Termios	termios_ref
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	RETVAL = termios_ref->c_lflag;
#else
     not_here("getlflag");
     RETVAL = 0;
#endif
    OUTPUT:
	RETVAL

cc_t
getcc(termios_ref, ccix)
	POSIX::Termios	termios_ref
	int		ccix
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	if (ccix >= NCCS)
	    croak("Bad getcc subscript");
	RETVAL = termios_ref->c_cc[ccix];
#else
     not_here("getcc");
     RETVAL = 0;
#endif
    OUTPUT:
	RETVAL

SysRet
cfsetispeed(termios_ref, speed)
	POSIX::Termios	termios_ref
	speed_t		speed

SysRet
cfsetospeed(termios_ref, speed)
	POSIX::Termios	termios_ref
	speed_t		speed

void
setiflag(termios_ref, iflag)
	POSIX::Termios	termios_ref
	tcflag_t	iflag
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	termios_ref->c_iflag = iflag;
#else
	    not_here("setiflag");
#endif

void
setoflag(termios_ref, oflag)
	POSIX::Termios	termios_ref
	tcflag_t	oflag
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	termios_ref->c_oflag = oflag;
#else
	    not_here("setoflag");
#endif

void
setcflag(termios_ref, cflag)
	POSIX::Termios	termios_ref
	tcflag_t	cflag
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	termios_ref->c_cflag = cflag;
#else
	    not_here("setcflag");
#endif

void
setlflag(termios_ref, lflag)
	POSIX::Termios	termios_ref
	tcflag_t	lflag
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	termios_ref->c_lflag = lflag;
#else
	    not_here("setlflag");
#endif

void
setcc(termios_ref, ccix, cc)
	POSIX::Termios	termios_ref
	int		ccix
	cc_t		cc
    CODE:
#ifdef I_TERMIOS /* References a termios structure member so ifdef it out. */
	if (ccix >= NCCS)
	    croak("Bad setcc subscript");
	termios_ref->c_cc[ccix] = cc;
#else
	    not_here("setcc");
#endif


MODULE = POSIX		PACKAGE = POSIX

void
constant(sv)
    PREINIT:
	dXSTARG;
	STRLEN		len;
        int		type;
	IV		iv;
	NV		nv;
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
	type = constant(s, len, &iv, &nv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid POSIX macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined POSIX macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
	/* Uncomment this if you need to return NOs
        case PERL_constant_ISNO:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_no);
          break; */
        case PERL_constant_ISNV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHn(nv);
          break;
	/* Uncomment this if you need to return UNDEFs
        case PERL_constant_ISUNDEF:
          break; */
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break;
	/* Uncomment this if you need to return YESs
        case PERL_constant_ISYES:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_yes);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing POSIX macro %s, used",
               type, s));
          PUSHs(sv);
        }

void
int_macro_int(sv, iv)
    PREINIT:
	dXSTARG;
	STRLEN		len;
        int		type;
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
	IV		iv;
    PPCODE:
        /* Change this to int_macro_int(s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = int_macro_int(s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid POSIX macro", s));
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined POSIX macro %s, used", s));
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          PUSHi(iv);
          break;
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing POSIX macro %s, used",
               type, s));
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
        }

int
isalnum(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isalnum(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isalpha(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isalpha(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
iscntrl(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!iscntrl(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isdigit(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isdigit(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isgraph(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isgraph(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
islower(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!islower(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isprint(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isprint(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
ispunct(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!ispunct(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isspace(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isspace(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isupper(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isupper(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

int
isxdigit(charstring)
	unsigned char *	charstring
    CODE:
	unsigned char *s = charstring;
	unsigned char *e = s + PL_na;	/* "PL_na" set by typemap side effect */
	for (RETVAL = 1; RETVAL && s < e; s++)
	    if (!isxdigit(*s))
		RETVAL = 0;
    OUTPUT:
	RETVAL

SysRet
open(filename, flags = O_RDONLY, mode = 0666)
	char *		filename
	int		flags
	Mode_t		mode
    CODE:
	if (flags & (O_APPEND|O_CREAT|O_TRUNC|O_RDWR|O_WRONLY|O_EXCL))
	    TAINT_PROPER("open");
	RETVAL = open(filename, flags, mode);
    OUTPUT:
	RETVAL


HV *
localeconv()
    CODE:
#ifdef HAS_LOCALECONV
	struct lconv *lcbuf;
	RETVAL = newHV();
	if ((lcbuf = localeconv())) {
	    /* the strings */
	    if (lcbuf->decimal_point && *lcbuf->decimal_point)
		hv_store(RETVAL, "decimal_point", 13,
		    newSVpv(lcbuf->decimal_point, 0), 0);
	    if (lcbuf->thousands_sep && *lcbuf->thousands_sep)
		hv_store(RETVAL, "thousands_sep", 13,
		    newSVpv(lcbuf->thousands_sep, 0), 0);
#ifndef NO_LOCALECONV_GROUPING
	    if (lcbuf->grouping && *lcbuf->grouping)
		hv_store(RETVAL, "grouping", 8,
		    newSVpv(lcbuf->grouping, 0), 0);
#endif
	    if (lcbuf->int_curr_symbol && *lcbuf->int_curr_symbol)
		hv_store(RETVAL, "int_curr_symbol", 15,
		    newSVpv(lcbuf->int_curr_symbol, 0), 0);
	    if (lcbuf->currency_symbol && *lcbuf->currency_symbol)
		hv_store(RETVAL, "currency_symbol", 15,
		    newSVpv(lcbuf->currency_symbol, 0), 0);
	    if (lcbuf->mon_decimal_point && *lcbuf->mon_decimal_point)
		hv_store(RETVAL, "mon_decimal_point", 17,
		    newSVpv(lcbuf->mon_decimal_point, 0), 0);
#ifndef NO_LOCALECONV_MON_THOUSANDS_SEP
	    if (lcbuf->mon_thousands_sep && *lcbuf->mon_thousands_sep)
		hv_store(RETVAL, "mon_thousands_sep", 17,
		    newSVpv(lcbuf->mon_thousands_sep, 0), 0);
#endif                    
#ifndef NO_LOCALECONV_MON_GROUPING
	    if (lcbuf->mon_grouping && *lcbuf->mon_grouping)
		hv_store(RETVAL, "mon_grouping", 12,
		    newSVpv(lcbuf->mon_grouping, 0), 0);
#endif
	    if (lcbuf->positive_sign && *lcbuf->positive_sign)
		hv_store(RETVAL, "positive_sign", 13,
		    newSVpv(lcbuf->positive_sign, 0), 0);
	    if (lcbuf->negative_sign && *lcbuf->negative_sign)
		hv_store(RETVAL, "negative_sign", 13,
		    newSVpv(lcbuf->negative_sign, 0), 0);
	    /* the integers */
	    if (lcbuf->int_frac_digits != CHAR_MAX)
		hv_store(RETVAL, "int_frac_digits", 15,
		    newSViv(lcbuf->int_frac_digits), 0);
	    if (lcbuf->frac_digits != CHAR_MAX)
		hv_store(RETVAL, "frac_digits", 11,
		    newSViv(lcbuf->frac_digits), 0);
	    if (lcbuf->p_cs_precedes != CHAR_MAX)
		hv_store(RETVAL, "p_cs_precedes", 13,
		    newSViv(lcbuf->p_cs_precedes), 0);
	    if (lcbuf->p_sep_by_space != CHAR_MAX)
		hv_store(RETVAL, "p_sep_by_space", 14,
		    newSViv(lcbuf->p_sep_by_space), 0);
	    if (lcbuf->n_cs_precedes != CHAR_MAX)
		hv_store(RETVAL, "n_cs_precedes", 13,
		    newSViv(lcbuf->n_cs_precedes), 0);
	    if (lcbuf->n_sep_by_space != CHAR_MAX)
		hv_store(RETVAL, "n_sep_by_space", 14,
		    newSViv(lcbuf->n_sep_by_space), 0);
	    if (lcbuf->p_sign_posn != CHAR_MAX)
		hv_store(RETVAL, "p_sign_posn", 11,
		    newSViv(lcbuf->p_sign_posn), 0);
	    if (lcbuf->n_sign_posn != CHAR_MAX)
		hv_store(RETVAL, "n_sign_posn", 11,
		    newSViv(lcbuf->n_sign_posn), 0);
	}
#else
	localeconv(); /* A stub to call not_here(). */
#endif
    OUTPUT:
	RETVAL

char *
setlocale(category, locale = 0)
	int		category
	char *		locale
    CODE:
	RETVAL = setlocale(category, locale);
	if (RETVAL) {
#ifdef USE_LOCALE_CTYPE
	    if (category == LC_CTYPE
#ifdef LC_ALL
		|| category == LC_ALL
#endif
		)
	    {
		char *newctype;
#ifdef LC_ALL
		if (category == LC_ALL)
		    newctype = setlocale(LC_CTYPE, NULL);
		else
#endif
		    newctype = RETVAL;
		new_ctype(newctype);
	    }
#endif /* USE_LOCALE_CTYPE */
#ifdef USE_LOCALE_COLLATE
	    if (category == LC_COLLATE
#ifdef LC_ALL
		|| category == LC_ALL
#endif
		)
	    {
		char *newcoll;
#ifdef LC_ALL
		if (category == LC_ALL)
		    newcoll = setlocale(LC_COLLATE, NULL);
		else
#endif
		    newcoll = RETVAL;
		new_collate(newcoll);
	    }
#endif /* USE_LOCALE_COLLATE */
#ifdef USE_LOCALE_NUMERIC
	    if (category == LC_NUMERIC
#ifdef LC_ALL
		|| category == LC_ALL
#endif
		)
	    {
		char *newnum;
#ifdef LC_ALL
		if (category == LC_ALL)
		    newnum = setlocale(LC_NUMERIC, NULL);
		else
#endif
		    newnum = RETVAL;
		new_numeric(newnum);
	    }
#endif /* USE_LOCALE_NUMERIC */
	}
    OUTPUT:
	RETVAL


NV
acos(x)
	NV		x

NV
asin(x)
	NV		x

NV
atan(x)
	NV		x

NV
ceil(x)
	NV		x

NV
cosh(x)
	NV		x

NV
floor(x)
	NV		x

NV
fmod(x,y)
	NV		x
	NV		y

void
frexp(x)
	NV		x
    PPCODE:
	int expvar;
	/* (We already know stack is long enough.) */
	PUSHs(sv_2mortal(newSVnv(frexp(x,&expvar))));
	PUSHs(sv_2mortal(newSViv(expvar)));

NV
ldexp(x,exp)
	NV		x
	int		exp

NV
log10(x)
	NV		x

void
modf(x)
	NV		x
    PPCODE:
	NV intvar;
	/* (We already know stack is long enough.) */
	PUSHs(sv_2mortal(newSVnv(Perl_modf(x,&intvar))));
	PUSHs(sv_2mortal(newSVnv(intvar)));

NV
sinh(x)
	NV		x

NV
tan(x)
	NV		x

NV
tanh(x)
	NV		x

SysRet
sigaction(sig, optaction, oldaction = 0)
	int			sig
	SV *			optaction
	POSIX::SigAction	oldaction
    CODE:
#ifdef WIN32
	RETVAL = not_here("sigaction");
#else
# This code is really grody because we're trying to make the signal
# interface look beautiful, which is hard.

	{
	    POSIX__SigAction action;
	    GV *siggv = gv_fetchpv("SIG", TRUE, SVt_PVHV);
	    struct sigaction act;
	    struct sigaction oact;
	    sigset_t sset;
	    sigset_t osset;
	    POSIX__SigSet sigset;
	    SV** svp;
	    SV** sigsvp = hv_fetch(GvHVn(siggv),
				 PL_sig_name[sig],
				 strlen(PL_sig_name[sig]),
				 TRUE);

	    /* Check optaction and set action */
	    if(SvTRUE(optaction)) {
		if(sv_isa(optaction, "POSIX::SigAction"))
			action = (HV*)SvRV(optaction);
		else
			croak("action is not of type POSIX::SigAction");
	    }
	    else {
		action=0;
	    }

	    /* sigaction() is supposed to look atomic. In particular, any
	     * signal handler invoked during a sigaction() call should
	     * see either the old or the new disposition, and not something
	     * in between. We use sigprocmask() to make it so.
	     */
	    sigfillset(&sset);
	    RETVAL=sigprocmask(SIG_BLOCK, &sset, &osset);
	    if(RETVAL == -1)
		XSRETURN(1);
	    ENTER;
	    /* Restore signal mask no matter how we exit this block. */
	    SAVEDESTRUCTOR(restore_sigmask, &osset);

	    RETVAL=-1; /* In case both oldaction and action are 0. */

	    /* Remember old disposition if desired. */
	    if (oldaction) {
		svp = hv_fetch(oldaction, "HANDLER", 7, TRUE);
		if(!svp)
		    croak("Can't supply an oldaction without a HANDLER");
		if(SvTRUE(*sigsvp)) { /* TBD: what if "0"? */
			sv_setsv(*svp, *sigsvp);
		}
		else {
			sv_setpv(*svp, "DEFAULT");
		}
		RETVAL = sigaction(sig, (struct sigaction *)0, & oact);
		if(RETVAL == -1)
		    XSRETURN(1);
		/* Get back the mask. */
		svp = hv_fetch(oldaction, "MASK", 4, TRUE);
		if (sv_isa(*svp, "POSIX::SigSet")) {
		    IV tmp = SvIV((SV*)SvRV(*svp));
		    sigset = INT2PTR(sigset_t*, tmp);
		}
		else {
		    New(0, sigset, 1, sigset_t);
		    sv_setptrobj(*svp, sigset, "POSIX::SigSet");
		}
		*sigset = oact.sa_mask;

		/* Get back the flags. */
		svp = hv_fetch(oldaction, "FLAGS", 5, TRUE);
		sv_setiv(*svp, oact.sa_flags);
	    }

	    if (action) {
		/* Vector new handler through %SIG.  (We always use sighandler
		   for the C signal handler, which reads %SIG to dispatch.) */
		svp = hv_fetch(action, "HANDLER", 7, FALSE);
		if (!svp)
		    croak("Can't supply an action without a HANDLER");
		sv_setsv(*sigsvp, *svp);
		mg_set(*sigsvp);	/* handles DEFAULT and IGNORE */
		if(SvPOK(*svp)) {
			char *s=SvPVX(*svp);
			if(strEQ(s,"IGNORE")) {
				act.sa_handler = SIG_IGN;
			}
			else if(strEQ(s,"DEFAULT")) {
				act.sa_handler = SIG_DFL;
			}
			else {
				act.sa_handler = PL_sighandlerp;
			}
		}
		else {
			act.sa_handler = PL_sighandlerp;
		}

		/* Set up any desired mask. */
		svp = hv_fetch(action, "MASK", 4, FALSE);
		if (svp && sv_isa(*svp, "POSIX::SigSet")) {
		    IV tmp = SvIV((SV*)SvRV(*svp));
		    sigset = INT2PTR(sigset_t*, tmp);
		    act.sa_mask = *sigset;
		}
		else
		    sigemptyset(& act.sa_mask);

		/* Set up any desired flags. */
		svp = hv_fetch(action, "FLAGS", 5, FALSE);
		act.sa_flags = svp ? SvIV(*svp) : 0;

		/* Don't worry about cleaning up *sigsvp if this fails,
		 * because that means we tried to disposition a
		 * nonblockable signal, in which case *sigsvp is
		 * essentially meaningless anyway.
		 */
		RETVAL = sigaction(sig, & act, (struct sigaction *)0);
	    }

	    LEAVE;
	}
#endif
    OUTPUT:
	RETVAL

SysRet
sigpending(sigset)
	POSIX::SigSet		sigset

SysRet
sigprocmask(how, sigset, oldsigset = 0)
	int			how
	POSIX::SigSet		sigset
	POSIX::SigSet		oldsigset = NO_INIT
INIT:
	if ( items < 3 ) {
	    oldsigset = 0;
	}
	else if (sv_derived_from(ST(2), "POSIX::SigSet")) {
	    IV tmp = SvIV((SV*)SvRV(ST(2)));
	    oldsigset = INT2PTR(POSIX__SigSet,tmp);
	}
	else {
	    New(0, oldsigset, 1, sigset_t);
	    sigemptyset(oldsigset);
	    sv_setref_pv(ST(2), "POSIX::SigSet", (void*)oldsigset);
	}

SysRet
sigsuspend(signal_mask)
	POSIX::SigSet		signal_mask

void
_exit(status)
	int		status

SysRet
close(fd)
	int		fd

SysRet
dup(fd)
	int		fd

SysRet
dup2(fd1, fd2)
	int		fd1
	int		fd2

SysRetLong
lseek(fd, offset, whence)
	int		fd
	Off_t		offset
	int		whence

SysRet
nice(incr)
	int		incr

void
pipe()
    PPCODE:
	int fds[2];
	if (pipe(fds) != -1) {
	    EXTEND(SP,2);
	    PUSHs(sv_2mortal(newSViv(fds[0])));
	    PUSHs(sv_2mortal(newSViv(fds[1])));
	}

SysRet
read(fd, buffer, nbytes)
    PREINIT:
        SV *sv_buffer = SvROK(ST(1)) ? SvRV(ST(1)) : ST(1);
    INPUT:
        int             fd
        size_t          nbytes
        char *          buffer = sv_grow( sv_buffer, nbytes+1 );
    CLEANUP:
        if (RETVAL >= 0) {
            SvCUR(sv_buffer) = RETVAL;
            SvPOK_only(sv_buffer);
            *SvEND(sv_buffer) = '\0';
            SvTAINTED_on(sv_buffer);
        }

SysRet
setpgid(pid, pgid)
	pid_t		pid
	pid_t		pgid

pid_t
setsid()

pid_t
tcgetpgrp(fd)
	int		fd

SysRet
tcsetpgrp(fd, pgrp_id)
	int		fd
	pid_t		pgrp_id

void
uname()
    PPCODE:
#ifdef HAS_UNAME
	struct utsname buf;
	if (uname(&buf) >= 0) {
	    EXTEND(SP, 5);
	    PUSHs(sv_2mortal(newSVpv(buf.sysname, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.nodename, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.release, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.version, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.machine, 0)));
	}
#else
	uname((char *) 0); /* A stub to call not_here(). */
#endif

SysRet
write(fd, buffer, nbytes)
	int		fd
	char *		buffer
	size_t		nbytes

SV *
tmpnam()
    PREINIT:
	STRLEN i;
	int len;
    CODE:
	RETVAL = newSVpvn("", 0);
	SvGROW(RETVAL, L_tmpnam);
	len = strlen(tmpnam(SvPV(RETVAL, i)));
	SvCUR_set(RETVAL, len);
    OUTPUT:
	RETVAL

void
abort()

int
mblen(s, n)
	char *		s
	size_t		n

size_t
mbstowcs(s, pwcs, n)
	wchar_t *	s
	char *		pwcs
	size_t		n

int
mbtowc(pwc, s, n)
	wchar_t *	pwc
	char *		s
	size_t		n

int
wcstombs(s, pwcs, n)
	char *		s
	wchar_t *	pwcs
	size_t		n

int
wctomb(s, wchar)
	char *		s
	wchar_t		wchar

int
strcoll(s1, s2)
	char *		s1
	char *		s2

void
strtod(str)
	char *		str
    PREINIT:
	double num;
	char *unparsed;
    PPCODE:
	SET_NUMERIC_LOCAL();
	num = strtod(str, &unparsed);
	PUSHs(sv_2mortal(newSVnv(num)));
	if (GIMME == G_ARRAY) {
	    EXTEND(SP, 1);
	    if (unparsed)
		PUSHs(sv_2mortal(newSViv(strlen(unparsed))));
	    else
		PUSHs(&PL_sv_undef);
	}

void
strtol(str, base = 0)
	char *		str
	int		base
    PREINIT:
	long num;
	char *unparsed;
    PPCODE:
	num = strtol(str, &unparsed, base);
#if IVSIZE <= LONGSIZE
	if (num < IV_MIN || num > IV_MAX)
	    PUSHs(sv_2mortal(newSVnv((double)num)));
	else
#endif
	    PUSHs(sv_2mortal(newSViv((IV)num)));
	if (GIMME == G_ARRAY) {
	    EXTEND(SP, 1);
	    if (unparsed)
		PUSHs(sv_2mortal(newSViv(strlen(unparsed))));
	    else
		PUSHs(&PL_sv_undef);
	}

void
strtoul(str, base = 0)
	char *		str
	int		base
    PREINIT:
	unsigned long num;
	char *unparsed;
    PPCODE:
	num = strtoul(str, &unparsed, base);
	if (num <= IV_MAX)
	    PUSHs(sv_2mortal(newSViv((IV)num)));
	else
	    PUSHs(sv_2mortal(newSVnv((double)num)));
	if (GIMME == G_ARRAY) {
	    EXTEND(SP, 1);
	    if (unparsed)
		PUSHs(sv_2mortal(newSViv(strlen(unparsed))));
	    else
		PUSHs(&PL_sv_undef);
	}

void
strxfrm(src)
	SV *		src
    CODE:
	{
          STRLEN srclen;
          STRLEN dstlen;
          char *p = SvPV(src,srclen);
          srclen++;
          ST(0) = sv_2mortal(NEWSV(800,srclen));
          dstlen = strxfrm(SvPVX(ST(0)), p, (size_t)srclen);
          if (dstlen > srclen) {
              dstlen++;
              SvGROW(ST(0), dstlen);
              strxfrm(SvPVX(ST(0)), p, (size_t)dstlen);
              dstlen--;
          }
          SvCUR(ST(0)) = dstlen;
	    SvPOK_only(ST(0));
	}

SysRet
mkfifo(filename, mode)
	char *		filename
	Mode_t		mode
    CODE:
	TAINT_PROPER("mkfifo");
	RETVAL = mkfifo(filename, mode);
    OUTPUT:
	RETVAL

SysRet
tcdrain(fd)
	int		fd


SysRet
tcflow(fd, action)
	int		fd
	int		action


SysRet
tcflush(fd, queue_selector)
	int		fd
	int		queue_selector

SysRet
tcsendbreak(fd, duration)
	int		fd
	int		duration

char *
asctime(sec, min, hour, mday, mon, year, wday = 0, yday = 0, isdst = 0)
	int		sec
	int		min
	int		hour
	int		mday
	int		mon
	int		year
	int		wday
	int		yday
	int		isdst
    CODE:
	{
	    struct tm mytm;
	    init_tm(&mytm);	/* XXX workaround - see init_tm() above */
	    mytm.tm_sec = sec;
	    mytm.tm_min = min;
	    mytm.tm_hour = hour;
	    mytm.tm_mday = mday;
	    mytm.tm_mon = mon;
	    mytm.tm_year = year;
	    mytm.tm_wday = wday;
	    mytm.tm_yday = yday;
	    mytm.tm_isdst = isdst;
	    RETVAL = asctime(&mytm);
	}
    OUTPUT:
	RETVAL

long
clock()

char *
ctime(time)
	Time_t		&time

void
times()
	PPCODE:
	struct tms tms;
	clock_t realtime;
	realtime = times( &tms );
	EXTEND(SP,5);
	PUSHs( sv_2mortal( newSViv( (IV) realtime ) ) );
	PUSHs( sv_2mortal( newSViv( (IV) tms.tms_utime ) ) );
	PUSHs( sv_2mortal( newSViv( (IV) tms.tms_stime ) ) );
	PUSHs( sv_2mortal( newSViv( (IV) tms.tms_cutime ) ) );
	PUSHs( sv_2mortal( newSViv( (IV) tms.tms_cstime ) ) );

double
difftime(time1, time2)
	Time_t		time1
	Time_t		time2

SysRetLong
mktime(sec, min, hour, mday, mon, year, wday = 0, yday = 0, isdst = 0)
	int		sec
	int		min
	int		hour
	int		mday
	int		mon
	int		year
	int		wday
	int		yday
	int		isdst
    CODE:
	{
	    struct tm mytm;
	    init_tm(&mytm);	/* XXX workaround - see init_tm() above */
	    mytm.tm_sec = sec;
	    mytm.tm_min = min;
	    mytm.tm_hour = hour;
	    mytm.tm_mday = mday;
	    mytm.tm_mon = mon;
	    mytm.tm_year = year;
	    mytm.tm_wday = wday;
	    mytm.tm_yday = yday;
	    mytm.tm_isdst = isdst;
	    RETVAL = mktime(&mytm);
	}
    OUTPUT:
	RETVAL

#XXX: if $xsubpp::WantOptimize is always the default
#     sv_setpv(TARG, ...) could be used rather than
#     ST(0) = sv_2mortal(newSVpv(...))
void
strftime(fmt, sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)
	char *		fmt
	int		sec
	int		min
	int		hour
	int		mday
	int		mon
	int		year
	int		wday
	int		yday
	int		isdst
    CODE:
	{
	    char *buf = my_strftime(fmt, sec, min, hour, mday, mon, year, wday, yday, isdst);
	    if (buf) {
		ST(0) = sv_2mortal(newSVpv(buf, 0));
		Safefree(buf);
	    }
	}

void
tzset()

void
tzname()
    PPCODE:
	EXTEND(SP,2);
	PUSHs(sv_2mortal(newSVpvn(tzname[0],strlen(tzname[0]))));
	PUSHs(sv_2mortal(newSVpvn(tzname[1],strlen(tzname[1]))));

SysRet
access(filename, mode)
	char *		filename
	Mode_t		mode

char *
ctermid(s = 0)
	char *		s = 0;

char *
cuserid(s = 0)
	char *		s = 0;

SysRetLong
fpathconf(fd, name)
	int		fd
	int		name

SysRetLong
pathconf(filename, name)
	char *		filename
	int		name

SysRet
pause()

SysRet
setgid(gid)
	Gid_t		gid

SysRet
setuid(uid)
	Uid_t		uid

SysRetLong
sysconf(name)
	int		name

char *
ttyname(fd)
	int		fd

#XXX: use sv_getcwd()
void
getcwd()
	PPCODE:
#ifdef HAS_GETCWD
	char *		buf;
	int		buflen = 128;

	New(0, buf, buflen, char);
	/* Many getcwd()s know how to automatically allocate memory
	 * for the directory if the buffer argument is NULL but...
	 * (1) we cannot assume all getcwd()s do that
  	 * (2) this may interfere with Perl's malloc
         * So let's not.  --jhi */
	while ((getcwd(buf, buflen) == NULL) && errno == ERANGE) {
	    buflen += 128;
	    if (buflen > MAXPATHLEN) {
		Safefree(buf);
		buf = NULL;
		break;
	    }
	    Renew(buf, buflen, char);
	}
	if (buf) {
	    PUSHs(sv_2mortal(newSVpv(buf, 0)));
	    Safefree(buf);
	}
	else
	    PUSHs(&PL_sv_undef);
#else
	require_pv("Cwd.pm");
        /* Module require may have grown the stack */
	SPAGAIN;
	PUSHMARK(sp);
	PUTBACK;
	XSRETURN(call_pv("Cwd::cwd", GIMME_V));
#endif
