#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#ifdef I_FLOAT
#include <float.h>
#endif
#include <grp.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#ifdef I_PWD
#include <pwd.h>
#endif
#include <setjmp.h>
#include <signal.h>
#ifdef I_STDARG
#include <stdarg.h>
#endif
#ifdef I_STDDEF
#include <stddef.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/times.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#if defined(I_TERMIOS) && !defined(CR3)
#include <termios.h>
#endif
#include <time.h>
#include <unistd.h>
#include <utime.h>

typedef int SysRet;
typedef sigset_t* POSIX__SigSet;
typedef HV* POSIX__SigAction;

#define HAS_UNAME

#ifndef HAS_GETPGRP
#define getpgrp() not_here("getpgrp")
#endif
#ifndef HAS_NICE
#define nice(a) not_here("nice")
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
#ifndef HAS_SYMLINK
#define symlink(a,b) not_here("symlink")
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

static int
not_here(s)
char *s;
{
    croak("POSIX::%s not implemented on this architecture", s);
    return -1;
}

int constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ARG_MAX"))
#ifdef ARG_MAX
	    return ARG_MAX;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BUFSIZ"))
#ifdef BUFSIZ
	    return BUFSIZ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BRKINT"))
#ifdef BRKINT
	    return BRKINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B9600"))
#ifdef B9600
	    return B9600;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B19200"))
#ifdef B19200
	    return B19200;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B38400"))
#ifdef B38400
	    return B38400;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B0"))
#ifdef B0
	    return B0;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B110"))
#ifdef B110
	    return B110;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B1200"))
#ifdef B1200
	    return B1200;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B134"))
#ifdef B134
	    return B134;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B150"))
#ifdef B150
	    return B150;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B1800"))
#ifdef B1800
	    return B1800;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B200"))
#ifdef B200
	    return B200;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B2400"))
#ifdef B2400
	    return B2400;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B300"))
#ifdef B300
	    return B300;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B4800"))
#ifdef B4800
	    return B4800;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B50"))
#ifdef B50
	    return B50;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B600"))
#ifdef B600
	    return B600;
#else
	    goto not_there;
#endif
	if (strEQ(name, "B75"))
#ifdef B75
	    return B75;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "CHAR_BIT"))
#ifdef CHAR_BIT
	    return CHAR_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CHAR_MAX"))
#ifdef CHAR_MAX
	    return CHAR_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CHAR_MIN"))
#ifdef CHAR_MIN
	    return CHAR_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CHILD_MAX"))
#ifdef CHILD_MAX
	    return CHILD_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLK_TCK"))
#ifdef CLK_TCK
	    return CLK_TCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLOCAL"))
#ifdef CLOCAL
	    return CLOCAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLOCKS_PER_SEC"))
#ifdef CLOCKS_PER_SEC
	    return CLOCKS_PER_SEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CREAD"))
#ifdef CREAD
	    return CREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CS5"))
#ifdef CS5
	    return CS5;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CS6"))
#ifdef CS6
	    return CS6;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CS7"))
#ifdef CS7
	    return CS7;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CS8"))
#ifdef CS8
	    return CS8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSIZE"))
#ifdef CSIZE
	    return CSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSTOPB"))
#ifdef CSTOPB
	    return CSTOPB;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DBL_MAX"))
#ifdef DBL_MAX
	    return DBL_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_MIN"))
#ifdef DBL_MIN
	    return DBL_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_DIG"))
#ifdef DBL_DIG
	    return DBL_DIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_EPSILON"))
#ifdef DBL_EPSILON
	    return DBL_EPSILON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_MANT_DIG"))
#ifdef DBL_MANT_DIG
	    return DBL_MANT_DIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_MAX_10_EXP"))
#ifdef DBL_MAX_10_EXP
	    return DBL_MAX_10_EXP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_MAX_EXP"))
#ifdef DBL_MAX_EXP
	    return DBL_MAX_EXP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_MIN_10_EXP"))
#ifdef DBL_MIN_10_EXP
	    return DBL_MIN_10_EXP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBL_MIN_EXP"))
#ifdef DBL_MIN_EXP
	    return DBL_MIN_EXP;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	switch (name[1]) {
	case 'A':
	    if (strEQ(name, "EACCES"))
#ifdef EACCES
		return EACCES;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EAGAIN"))
#ifdef EAGAIN
		return EAGAIN;
#else
		goto not_there;
#endif
	    break;
	case 'B':
	    if (strEQ(name, "EBADF"))
#ifdef EBADF
		return EBADF;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EBUSY"))
#ifdef EBUSY
		return EBUSY;
#else
		goto not_there;
#endif
	    break;
	case 'C':
	    if (strEQ(name, "ECHILD"))
#ifdef ECHILD
		return ECHILD;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ECHO"))
#ifdef ECHO
		return ECHO;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ECHOE"))
#ifdef ECHOE
		return ECHOE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ECHOK"))
#ifdef ECHOK
		return ECHOK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ECHONL"))
#ifdef ECHONL
		return ECHONL;
#else
		goto not_there;
#endif
	    break;
	case 'D':
	    if (strEQ(name, "EDEADLK"))
#ifdef EDEADLK
		return EDEADLK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EDOM"))
#ifdef EDOM
		return EDOM;
#else
		goto not_there;
#endif
	    break;
	case 'E':
	    if (strEQ(name, "EEXIST"))
#ifdef EEXIST
		return EEXIST;
#else
		goto not_there;
#endif
	    break;
	case 'F':
	    if (strEQ(name, "EFAULT"))
#ifdef EFAULT
		return EFAULT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EFBIG"))
#ifdef EFBIG
		return EFBIG;
#else
		goto not_there;
#endif
	    break;
	case 'I':
	    if (strEQ(name, "EINTR"))
#ifdef EINTR
		return EINTR;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EINVAL"))
#ifdef EINVAL
		return EINVAL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EIO"))
#ifdef EIO
		return EIO;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EISDIR"))
#ifdef EISDIR
		return EISDIR;
#else
		goto not_there;
#endif
	    break;
	case 'M':
	    if (strEQ(name, "EMFILE"))
#ifdef EMFILE
		return EMFILE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EMLINK"))
#ifdef EMLINK
		return EMLINK;
#else
		goto not_there;
#endif
	    break;
	case 'N':
	    if (strEQ(name, "ENOMEM"))
#ifdef ENOMEM
		return ENOMEM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOSPC"))
#ifdef ENOSPC
		return ENOSPC;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOEXEC"))
#ifdef ENOEXEC
		return ENOEXEC;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOTTY"))
#ifdef ENOTTY
		return ENOTTY;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOTDIR"))
#ifdef ENOTDIR
		return ENOTDIR;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOTEMPTY"))
#ifdef ENOTEMPTY
		return ENOTEMPTY;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENFILE"))
#ifdef ENFILE
		return ENFILE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENODEV"))
#ifdef ENODEV
		return ENODEV;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOENT"))
#ifdef ENOENT
		return ENOENT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOLCK"))
#ifdef ENOLCK
		return ENOLCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENOSYS"))
#ifdef ENOSYS
		return ENOSYS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENXIO"))
#ifdef ENXIO
		return ENXIO;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ENAMETOOLONG"))
#ifdef ENAMETOOLONG
		return ENAMETOOLONG;
#else
		goto not_there;
#endif
	    break;
	case 'O':
	    if (strEQ(name, "EOF"))
#ifdef EOF
		return EOF;
#else
		goto not_there;
#endif
	    break;
	case 'P':
	    if (strEQ(name, "EPERM"))
#ifdef EPERM
		return EPERM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EPIPE"))
#ifdef EPIPE
		return EPIPE;
#else
		goto not_there;
#endif
	    break;
	case 'R':
	    if (strEQ(name, "ERANGE"))
#ifdef ERANGE
		return ERANGE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "EROFS"))
#ifdef EROFS
		return EROFS;
#else
		goto not_there;
#endif
	    break;
	case 'S':
	    if (strEQ(name, "ESPIPE"))
#ifdef ESPIPE
		return ESPIPE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "ESRCH"))
#ifdef ESRCH
		return ESRCH;
#else
		goto not_there;
#endif
	    break;
	case 'X':
	    if (strEQ(name, "EXIT_FAILURE"))
#ifdef EXIT_FAILURE
		return EXIT_FAILURE;
#else
		return 1;
#endif
	    if (strEQ(name, "EXIT_SUCCESS"))
#ifdef EXIT_SUCCESS
		return EXIT_SUCCESS;
#else
		return 0;
#endif
	    if (strEQ(name, "EXDEV"))
#ifdef EXDEV
		return EXDEV;
#else
		goto not_there;
#endif
	    break;
	}
	if (strEQ(name, "E2BIG"))
#ifdef E2BIG
	    return E2BIG;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strnEQ(name, "FLT_", 4)) {
	    if (strEQ(name, "FLT_MAX"))
#ifdef FLT_MAX
		return FLT_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_MIN"))
#ifdef FLT_MIN
		return FLT_MIN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_ROUNDS"))
#ifdef FLT_ROUNDS
		return FLT_ROUNDS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_DIG"))
#ifdef FLT_DIG
		return FLT_DIG;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_EPSILON"))
#ifdef FLT_EPSILON
		return FLT_EPSILON;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_MANT_DIG"))
#ifdef FLT_MANT_DIG
		return FLT_MANT_DIG;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_MAX_10_EXP"))
#ifdef FLT_MAX_10_EXP
		return FLT_MAX_10_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_MAX_EXP"))
#ifdef FLT_MAX_EXP
		return FLT_MAX_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_MIN_10_EXP"))
#ifdef FLT_MIN_10_EXP
		return FLT_MIN_10_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_MIN_EXP"))
#ifdef FLT_MIN_EXP
		return FLT_MIN_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "FLT_RADIX"))
#ifdef FLT_RADIX
		return FLT_RADIX;
#else
		goto not_there;
#endif
	    break;
	}
	if (strnEQ(name, "F_", 2)) {
	    if (strEQ(name, "F_DUPFD"))
#ifdef F_DUPFD
		return F_DUPFD;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_GETFD"))
#ifdef F_GETFD
		return F_GETFD;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_GETFL"))
#ifdef F_GETFL
		return F_GETFL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_GETLK"))
#ifdef F_GETLK
		return F_GETLK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_OK"))
#ifdef F_OK
		return F_OK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_RDLCK"))
#ifdef F_RDLCK
		return F_RDLCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_SETFD"))
#ifdef F_SETFD
		return F_SETFD;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_SETFL"))
#ifdef F_SETFL
		return F_SETFL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_SETLK"))
#ifdef F_SETLK
		return F_SETLK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_SETLKW"))
#ifdef F_SETLKW
		return F_SETLKW;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_UNLCK"))
#ifdef F_UNLCK
		return F_UNLCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "F_WRLCK"))
#ifdef F_WRLCK
		return F_WRLCK;
#else
		goto not_there;
#endif
	    break;
	}
	if (strEQ(name, "FD_CLOEXEC")) return FD_CLOEXEC;
	if (strEQ(name, "FILENAME_MAX"))
#ifdef FILENAME_MAX
	    return FILENAME_MAX;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	if (strEQ(name, "HUGE_VAL"))
#ifdef HUGE_VAL
	    return HUGE_VAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "HUPCL"))
#ifdef HUPCL
	    return HUPCL;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	if (strEQ(name, "INT_MAX"))
#ifdef INT_MAX
	    return INT_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INT_MIN"))
#ifdef INT_MIN
	    return INT_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ICANON"))
#ifdef ICANON
	    return ICANON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ICRNL"))
#ifdef ICRNL
	    return ICRNL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IEXTEN"))
#ifdef IEXTEN
	    return IEXTEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IGNBRK"))
#ifdef IGNBRK
	    return IGNBRK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IGNCR"))
#ifdef IGNCR
	    return IGNCR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IGNPAR"))
#ifdef IGNPAR
	    return IGNPAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INLCR"))
#ifdef INLCR
	    return INLCR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPCK"))
#ifdef INPCK
	    return INPCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISIG"))
#ifdef ISIG
	    return ISIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISTRIP"))
#ifdef ISTRIP
	    return ISTRIP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IXOFF"))
#ifdef IXOFF
	    return IXOFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "IXON"))
#ifdef IXON
	    return IXON;
#else
	    goto not_there;
#endif
	break;
    case 'L':
	if (strnEQ(name, "LC_", 3)) {
	    if (strEQ(name, "LC_ALL"))
#ifdef LC_ALL
		return LC_ALL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LC_COLLATE"))
#ifdef LC_COLLATE
		return LC_COLLATE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LC_CTYPE"))
#ifdef LC_CTYPE
		return LC_CTYPE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LC_MONETARY"))
#ifdef LC_MONETARY
		return LC_MONETARY;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LC_NUMERIC"))
#ifdef LC_NUMERIC
		return LC_NUMERIC;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LC_TIME"))
#ifdef LC_TIME
		return LC_TIME;
#else
		goto not_there;
#endif
	    break;
	}
	if (strnEQ(name, "LDBL_", 5)) {
	    if (strEQ(name, "LDBL_MAX"))
#ifdef LDBL_MAX
		return LDBL_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_MIN"))
#ifdef LDBL_MIN
		return LDBL_MIN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_DIG"))
#ifdef LDBL_DIG
		return LDBL_DIG;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_EPSILON"))
#ifdef LDBL_EPSILON
		return LDBL_EPSILON;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_MANT_DIG"))
#ifdef LDBL_MANT_DIG
		return LDBL_MANT_DIG;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_MAX_10_EXP"))
#ifdef LDBL_MAX_10_EXP
		return LDBL_MAX_10_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_MAX_EXP"))
#ifdef LDBL_MAX_EXP
		return LDBL_MAX_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_MIN_10_EXP"))
#ifdef LDBL_MIN_10_EXP
		return LDBL_MIN_10_EXP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "LDBL_MIN_EXP"))
#ifdef LDBL_MIN_EXP
		return LDBL_MIN_EXP;
#else
		goto not_there;
#endif
	    break;
	}
	if (strnEQ(name, "L_", 2)) {
	    if (strEQ(name, "L_ctermid"))
#ifdef L_ctermid
		return L_ctermid;
#else
		goto not_there;
#endif
	    if (strEQ(name, "L_cuserid"))
#ifdef L_cuserid
		return L_cuserid;
#else
		goto not_there;
#endif
	    if (strEQ(name, "L_tmpname"))
#ifdef L_tmpname
		return L_tmpname;
#else
		goto not_there;
#endif
	    break;
	}
	if (strEQ(name, "LONG_MAX"))
#ifdef LONG_MAX
	    return LONG_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LONG_MIN"))
#ifdef LONG_MIN
	    return LONG_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LINK_MAX"))
#ifdef LINK_MAX
	    return LINK_MAX;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	if (strEQ(name, "MAX_CANON"))
#ifdef MAX_CANON
	    return MAX_CANON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_INPUT"))
#ifdef MAX_INPUT
	    return MAX_INPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MB_CUR_MAX"))
#ifdef MB_CUR_MAX
	    return MB_CUR_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MB_LEN_MAX"))
#ifdef MB_LEN_MAX
	    return MB_LEN_MAX;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NULL")) return NULL;
	if (strEQ(name, "NAME_MAX"))
#ifdef NAME_MAX
	    return NAME_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NCCS"))
#ifdef NCCS
	    return NCCS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NGROUPS_MAX"))
#ifdef NGROUPS_MAX
	    return NGROUPS_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOFLSH"))
#ifdef NOFLSH
	    return NOFLSH;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strnEQ(name, "O_", 2)) {
	    if (strEQ(name, "O_APPEND"))
#ifdef O_APPEND
		return O_APPEND;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_CREAT"))
#ifdef O_CREAT
		return O_CREAT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_TRUNC"))
#ifdef O_TRUNC
		return O_TRUNC;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_RDONLY"))
#ifdef O_RDONLY
		return O_RDONLY;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_RDWR"))
#ifdef O_RDWR
		return O_RDWR;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_WRONLY"))
#ifdef O_WRONLY
		return O_WRONLY;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_EXCL"))
#ifdef O_EXCL
		return O_EXCL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_NOCTTY"))
#ifdef O_NOCTTY
		return O_NOCTTY;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_NONBLOCK"))
#ifdef O_NONBLOCK
		return O_NONBLOCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "O_ACCMODE"))
#ifdef O_ACCMODE
		return O_ACCMODE;
#else
		goto not_there;
#endif
	    break;
	}
	if (strEQ(name, "OPEN_MAX"))
#ifdef OPEN_MAX
	    return OPEN_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OPOST"))
#ifdef OPOST
	    return OPOST;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "PATH_MAX"))
#ifdef PATH_MAX
	    return PATH_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARENB"))
#ifdef PARENB
	    return PARENB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARMRK"))
#ifdef PARMRK
	    return PARMRK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PARODD"))
#ifdef PARODD
	    return PARODD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PIPE_BUF"))
#ifdef PIPE_BUF
	    return PIPE_BUF;
#else
	    goto not_there;
#endif
	break;
    case 'R':
	if (strEQ(name, "RAND_MAX"))
#ifdef RAND_MAX
	    return RAND_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "R_OK"))
#ifdef R_OK
	    return R_OK;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strnEQ(name, "SIG", 3)) {
	    if (name[3] == '_') {
		if (strEQ(name, "SIG_BLOCK"))
#ifdef SIG_BLOCK
		    return SIG_BLOCK;
#else
		    goto not_there;
#endif
#ifdef SIG_DFL
		if (strEQ(name, "SIG_DFL")) return (int)SIG_DFL;
#endif
#ifdef SIG_ERR
		if (strEQ(name, "SIG_ERR")) return (int)SIG_ERR;
#endif
#ifdef SIG_IGN
		if (strEQ(name, "SIG_IGN")) return (int)SIG_IGN;
#endif
		if (strEQ(name, "SIG_SETMASK"))
#ifdef SIG_SETMASK
		    return SIG_SETMASK;
#else
		    goto not_there;
#endif
		if (strEQ(name, "SIG_UNBLOCK"))
#ifdef SIG_UNBLOCK
		    return SIG_UNBLOCK;
#else
		    goto not_there;
#endif
		break;
	    }
	    if (strEQ(name, "SIGABRT"))
#ifdef SIGABRT
		return SIGABRT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGALRM"))
#ifdef SIGALRM
		return SIGALRM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGCHLD"))
#ifdef SIGCHLD
		return SIGCHLD;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGCONT"))
#ifdef SIGCONT
		return SIGCONT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGFPE"))
#ifdef SIGFPE
		return SIGFPE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGHUP"))
#ifdef SIGHUP
		return SIGHUP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGILL"))
#ifdef SIGILL
		return SIGILL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGINT"))
#ifdef SIGINT
		return SIGINT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGKILL"))
#ifdef SIGKILL
		return SIGKILL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGPIPE"))
#ifdef SIGPIPE
		return SIGPIPE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGQUIT"))
#ifdef SIGQUIT
		return SIGQUIT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGSEGV"))
#ifdef SIGSEGV
		return SIGSEGV;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGSTOP"))
#ifdef SIGSTOP
		return SIGSTOP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGTERM"))
#ifdef SIGTERM
		return SIGTERM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGTSTP"))
#ifdef SIGTSTP
		return SIGTSTP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGTTIN"))
#ifdef SIGTTIN
		return SIGTTIN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGTTOU"))
#ifdef SIGTTOU
		return SIGTTOU;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGUSR1"))
#ifdef SIGUSR1
		return SIGUSR1;
#else
		goto not_there;
#endif
	    if (strEQ(name, "SIGUSR2"))
#ifdef SIGUSR2
		return SIGUSR2;
#else
		goto not_there;
#endif
	    break;
	}
	if (name[1] == '_') {
#ifdef S_ISBLK
	    if (strEQ(name, "S_ISBLK")) return S_ISBLK(arg);
#endif
#ifdef S_ISCHR
	    if (strEQ(name, "S_ISCHR")) return S_ISCHR(arg);
#endif
#ifdef S_ISDIR
	    if (strEQ(name, "S_ISDIR")) return S_ISDIR(arg);
#endif
#ifdef S_ISFIFO
	    if (strEQ(name, "S_ISFIFO")) return S_ISFIFO(arg);
#endif
#ifdef S_ISREG
	    if (strEQ(name, "S_ISREG")) return S_ISREG(arg);
#endif
	    if (strEQ(name, "S_ISGID"))
#ifdef S_ISGID
		return S_ISGID;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_ISUID"))
#ifdef S_ISUID
		return S_ISUID;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IRGRP"))
#ifdef S_IRGRP
		return S_IRGRP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IROTH"))
#ifdef S_IROTH
		return S_IROTH;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IRUSR"))
#ifdef S_IRUSR
		return S_IRUSR;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IRWXG"))
#ifdef S_IRWXG
		return S_IRWXG;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IRWXO"))
#ifdef S_IRWXO
		return S_IRWXO;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IRWXU"))
#ifdef S_IRWXU
		return S_IRWXU;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IWGRP"))
#ifdef S_IWGRP
		return S_IWGRP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IWOTH"))
#ifdef S_IWOTH
		return S_IWOTH;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IWUSR"))
#ifdef S_IWUSR
		return S_IWUSR;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IXGRP"))
#ifdef S_IXGRP
		return S_IXGRP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IXOTH"))
#ifdef S_IXOTH
		return S_IXOTH;
#else
		goto not_there;
#endif
	    if (strEQ(name, "S_IXUSR"))
#ifdef S_IXUSR
		return S_IXUSR;
#else
		goto not_there;
#endif
	    break;
	}
	if (strEQ(name, "SEEK_CUR"))
#ifdef SEEK_CUR
	    return SEEK_CUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SEEK_END"))
#ifdef SEEK_END
	    return SEEK_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SEEK_SET"))
#ifdef SEEK_SET
	    return SEEK_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STREAM_MAX"))
#ifdef STREAM_MAX
	    return STREAM_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SHRT_MAX"))
#ifdef SHRT_MAX
	    return SHRT_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SHRT_MIN"))
#ifdef SHRT_MIN
	    return SHRT_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SA_NOCLDSTOP"))
#ifdef SA_NOCLDSTOP
	    return SA_NOCLDSTOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SCHAR_MAX"))
#ifdef SCHAR_MAX
	    return SCHAR_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SCHAR_MIN"))
#ifdef SCHAR_MIN
	    return SCHAR_MIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SSIZE_MAX"))
#ifdef SSIZE_MAX
	    return SSIZE_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STDIN_FILENO"))
#ifdef STDIN_FILENO
	    return STDIN_FILENO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STDOUT_FILENO"))
#ifdef STDOUT_FILENO
	    return STDOUT_FILENO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STRERR_FILENO"))
#ifdef STRERR_FILENO
	    return STRERR_FILENO;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TCIFLUSH"))
#ifdef TCIFLUSH
	    return TCIFLUSH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCIOFF"))
#ifdef TCIOFF
	    return TCIOFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCIOFLUSH"))
#ifdef TCIOFLUSH
	    return TCIOFLUSH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCION"))
#ifdef TCION
	    return TCION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCOFLUSH"))
#ifdef TCOFLUSH
	    return TCOFLUSH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCOOFF"))
#ifdef TCOOFF
	    return TCOOFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCOON"))
#ifdef TCOON
	    return TCOON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCSADRAIN"))
#ifdef TCSADRAIN
	    return TCSADRAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCSAFLUSH"))
#ifdef TCSAFLUSH
	    return TCSAFLUSH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TCSANOW"))
#ifdef TCSANOW
	    return TCSANOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TMP_MAX"))
#ifdef TMP_MAX
	    return TMP_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TOSTOP"))
#ifdef TOSTOP
	    return TOSTOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TZNAME_MAX"))
#ifdef TZNAME_MAX
	    return TZNAME_MAX;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	if (strEQ(name, "UCHAR_MAX"))
#ifdef UCHAR_MAX
	    return UCHAR_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UINT_MAX"))
#ifdef UINT_MAX
	    return UINT_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ULONG_MAX"))
#ifdef ULONG_MAX
	    return ULONG_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "USHRT_MAX"))
#ifdef USHRT_MAX
	    return USHRT_MAX;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	if (strEQ(name, "VEOF"))
#ifdef VEOF
	    return VEOF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VEOL"))
#ifdef VEOL
	    return VEOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VERASE"))
#ifdef VERASE
	    return VERASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VINTR"))
#ifdef VINTR
	    return VINTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VKILL"))
#ifdef VKILL
	    return VKILL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VMIN"))
#ifdef VMIN
	    return VMIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VQUIT"))
#ifdef VQUIT
	    return VQUIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VSTART"))
#ifdef VSTART
	    return VSTART;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VSTOP"))
#ifdef VSTOP
	    return VSTOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VSUSP"))
#ifdef VSUSP
	    return VSUSP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VTIME"))
#ifdef VTIME
	    return VTIME;
#else
	    goto not_there;
#endif
	break;
    case 'W':
	if (strEQ(name, "W_OK"))
#ifdef W_OK
	    return W_OK;
#else
	    goto not_there;
#endif
#ifdef WEXITSTATUS
	if (strEQ(name, "WEXITSTATUS")) return WEXITSTATUS(arg);
#endif
#ifdef WIFEXITED
	if (strEQ(name, "WIFEXITED")) return WIFEXITED(arg);
#endif
#ifdef WIFSIGNALED
	if (strEQ(name, "WIFSIGNALED")) return WIFSIGNALED(arg);
#endif
#ifdef WIFSTOPPED
	if (strEQ(name, "WIFSTOPPED")) return WIFSTOPPED(arg);
#endif
	if (strEQ(name, "WNOHANG"))
#ifdef WNOHANG
	    return WNOHANG;
#else
	    goto not_there;
#endif
#ifdef WSTOPSIG
	if (strEQ(name, "WSTOPSIG")) return WSTOPSIG(arg);
#endif
#ifdef WTERMSIG
	if (strEQ(name, "WTERMSIG")) return WTERMSIG(arg);
#endif
	if (strEQ(name, "WUNTRACED"))
#ifdef WUNTRACED
	    return WUNTRACED;
#else
	    goto not_there;
#endif
	break;
    case 'X':
	if (strEQ(name, "X_OK"))
#ifdef X_OK
	    return X_OK;
#else
	    goto not_there;
#endif
	break;
    case '_':
	if (strnEQ(name, "_PC_", 4)) {
	    if (strEQ(name, "_PC_CHOWN_RESTRICTED"))
#ifdef _PC_CHOWN_RESTRICTED
		return _PC_CHOWN_RESTRICTED;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_LINK_MAX"))
#ifdef _PC_LINK_MAX
		return _PC_LINK_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_MAX_CANON"))
#ifdef _PC_MAX_CANON
		return _PC_MAX_CANON;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_MAX_INPUT"))
#ifdef _PC_MAX_INPUT
		return _PC_MAX_INPUT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_NAME_MAX"))
#ifdef _PC_NAME_MAX
		return _PC_NAME_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_NO_TRUNC"))
#ifdef _PC_NO_TRUNC
		return _PC_NO_TRUNC;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_PATH_MAX"))
#ifdef _PC_PATH_MAX
		return _PC_PATH_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_PIPE_BUF"))
#ifdef _PC_PIPE_BUF
		return _PC_PIPE_BUF;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_PC_VDISABLE"))
#ifdef _PC_VDISABLE
		return _PC_VDISABLE;
#else
		goto not_there;
#endif
	    break;
	}
	if (strnEQ(name, "_POSIX_", 7)) {
	    if (strEQ(name, "_POSIX_ARG_MAX"))
#ifdef _POSIX_ARG_MAX
		return _POSIX_ARG_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_CHILD_MAX"))
#ifdef _POSIX_CHILD_MAX
		return _POSIX_CHILD_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_CHOWN_RESTRICTED"))
#ifdef _POSIX_CHOWN_RESTRICTED
		return _POSIX_CHOWN_RESTRICTED;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_JOB_CONTROL"))
#ifdef _POSIX_JOB_CONTROL
		return _POSIX_JOB_CONTROL;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_LINK_MAX"))
#ifdef _POSIX_LINK_MAX
		return _POSIX_LINK_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_MAX_CANON"))
#ifdef _POSIX_MAX_CANON
		return _POSIX_MAX_CANON;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_MAX_INPUT"))
#ifdef _POSIX_MAX_INPUT
		return _POSIX_MAX_INPUT;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_NAME_MAX"))
#ifdef _POSIX_NAME_MAX
		return _POSIX_NAME_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_NGROUPS_MAX"))
#ifdef _POSIX_NGROUPS_MAX
		return _POSIX_NGROUPS_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_NO_TRUNC"))
#ifdef _POSIX_NO_TRUNC
		return _POSIX_NO_TRUNC;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_OPEN_MAX"))
#ifdef _POSIX_OPEN_MAX
		return _POSIX_OPEN_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_PATH_MAX"))
#ifdef _POSIX_PATH_MAX
		return _POSIX_PATH_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_PIPE_BUF"))
#ifdef _POSIX_PIPE_BUF
		return _POSIX_PIPE_BUF;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_SAVED_IDS"))
#ifdef _POSIX_SAVED_IDS
		return _POSIX_SAVED_IDS;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_SSIZE_MAX"))
#ifdef _POSIX_SSIZE_MAX
		return _POSIX_SSIZE_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_STREAM_MAX"))
#ifdef _POSIX_STREAM_MAX
		return _POSIX_STREAM_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_TZNAME_MAX"))
#ifdef _POSIX_TZNAME_MAX
		return _POSIX_TZNAME_MAX;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_VDISABLE"))
#ifdef _POSIX_VDISABLE
		return _POSIX_VDISABLE;
#else
		return 0;
#endif
	    if (strEQ(name, "_POSIX_VERSION"))
#ifdef _POSIX_VERSION
		return _POSIX_VERSION;
#else
		return 0;
#endif
	    break;
	}
	if (strnEQ(name, "_SC_", 4)) {
	    if (strEQ(name, "_SC_ARG_MAX"))
#ifdef _SC_ARG_MAX
		return _SC_ARG_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_CHILD_MAX"))
#ifdef _SC_CHILD_MAX
		return _SC_CHILD_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_CLK_TCK"))
#ifdef _SC_CLK_TCK
		return _SC_CLK_TCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_JOB_CONTROL"))
#ifdef _SC_JOB_CONTROL
		return _SC_JOB_CONTROL;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_NGROUPS_MAX"))
#ifdef _SC_NGROUPS_MAX
		return _SC_NGROUPS_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_OPEN_MAX"))
#ifdef _SC_OPEN_MAX
		return _SC_OPEN_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_SAVED_IDS"))
#ifdef _SC_SAVED_IDS
		return _SC_SAVED_IDS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_STREAM_MAX"))
#ifdef _SC_STREAM_MAX
		return _SC_STREAM_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_TZNAME_MAX"))
#ifdef _SC_TZNAME_MAX
		return _SC_TZNAME_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "_SC_VERSION"))
#ifdef _SC_VERSION
		return _SC_VERSION;
#else
		goto not_there;
#endif
	    break;
	}
	if (strEQ(name, "_IOFBF"))
#ifdef _IOFBF
	    return _IOFBF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "_IOLBF"))
#ifdef _IOLBF
	    return _IOLBF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "_IONBF"))
#ifdef _IONBF
	    return _IONBF;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static int
XS_POSIX__SigSet_new(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 0) {
	croak("Usage: POSIX::SigSet::new(packname = \"POSIX::SigSet\", ...)");
    }
    {
	char *	packname;
	POSIX__SigSet	RETVAL;

	if (items < 1)
	    packname = "POSIX::SigSet";
	else {
	    packname = SvPV(ST(1),na);
	}
	{
	    int i;
	    RETVAL = (sigset_t*)safemalloc(sizeof(sigset_t));
	    sigemptyset(RETVAL);
	    for (i = 2; i <= items; i++)
		sigaddset(RETVAL, SvIV(ST(i)));
	}
	ST(0) = sv_newmortal();
	sv_setptrobj(ST(0), RETVAL, "POSIX::SigSet");
    }
    return ax;
}

static int
XS_POSIX__SigSet_DESTROY(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::SigSet::DESTROY(sigset)");
    }
    {
	POSIX__SigSet	sigset;

	if (SvROK(ST(1))) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not a reference");
	safefree(sigset);
    }
    return ax;
}

static int
XS_POSIX__SigSet_sigaddset(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::SigSet::addset(sigset, sig)");
    }
    {
	POSIX__SigSet	sigset;
	int	sig = (int)SvIV(ST(2));
	SysRet	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	RETVAL = sigaddset(sigset, sig);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX__SigSet_sigdelset(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::SigSet::delset(sigset, sig)");
    }
    {
	POSIX__SigSet	sigset;
	int	sig = (int)SvIV(ST(2));
	SysRet	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	RETVAL = sigdelset(sigset, sig);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX__SigSet_sigemptyset(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::SigSet::emptyset(sigset)");
    }
    {
	POSIX__SigSet	sigset;
	SysRet	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	RETVAL = sigemptyset(sigset);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX__SigSet_sigfillset(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::SigSet::fillset(sigset)");
    }
    {
	POSIX__SigSet	sigset;
	SysRet	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	RETVAL = sigfillset(sigset);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX__SigSet_sigismember(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::SigSet::ismember(sigset, sig)");
    }
    {
	POSIX__SigSet	sigset;
	int	sig = (int)SvIV(ST(2));
	int	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	RETVAL = sigismember(sigset, sig);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_constant(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::constant(name,arg)");
    }
    {
	char *	name = SvPV(ST(1),na);
	int	arg = (int)SvIV(ST(2));
	int	RETVAL;

	RETVAL = constant(name, arg);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isalnum(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isalnum(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isalnum(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isalpha(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isalpha(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isalpha(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_iscntrl(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::iscntrl(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!iscntrl(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isdigit(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isdigit(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isdigit(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isgraph(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isgraph(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isgraph(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_islower(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::islower(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!islower(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isprint(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isprint(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isprint(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_ispunct(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::ispunct(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!ispunct(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isspace(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isspace(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isspace(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isupper(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isupper(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isupper(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_isxdigit(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::isxdigit(charstring)");
    }
    {
	char *	charstring = SvPV(ST(1),na);
	int	RETVAL;
	char *s;
	RETVAL = 1;
	for (s = charstring; *s && RETVAL; s++)
	    if (!isxdigit(*s))
		RETVAL = 0;
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_open(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 1 || items > 3) {
	croak("Usage: POSIX::open(filename, flags = O_RDONLY, mode = 0666)");
    }
    {
	char *	filename = SvPV(ST(1),na);
	int	flags;
	int	mode;
	SysRet	RETVAL;

	if (items < 2)
	    flags = O_RDONLY;
	else {
	    flags = (int)SvIV(ST(2));
	}

	if (items < 3)
	    mode = 0666;
	else {
	    mode = (int)SvIV(ST(3));
	}

	RETVAL = open(filename, flags, mode);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_localeconv(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::localeconv()");
    }
    {
	HV *	RETVAL;
	struct lconv *lcbuf;
	RETVAL = newHV();
	if (lcbuf = localeconv()) {
	    /* the strings */
	    if (lcbuf->decimal_point && *lcbuf->decimal_point)
		hv_store(RETVAL, "decimal_point", 13,
		    newSVpv(lcbuf->decimal_point, 0), 0);
	    if (lcbuf->thousands_sep && *lcbuf->thousands_sep)
		hv_store(RETVAL, "thousands_sep", 13,
		    newSVpv(lcbuf->thousands_sep, 0), 0);
	    if (lcbuf->grouping && *lcbuf->grouping)
		hv_store(RETVAL, "grouping", 8,
		    newSVpv(lcbuf->grouping, 0), 0);
	    if (lcbuf->int_curr_symbol && *lcbuf->int_curr_symbol)
		hv_store(RETVAL, "int_curr_symbol", 15,
		    newSVpv(lcbuf->int_curr_symbol, 0), 0);
	    if (lcbuf->currency_symbol && *lcbuf->currency_symbol)
		hv_store(RETVAL, "currency_symbol", 15,
		    newSVpv(lcbuf->currency_symbol, 0), 0);
	    if (lcbuf->mon_decimal_point && *lcbuf->mon_decimal_point)
		hv_store(RETVAL, "mon_decimal_point", 17,
		    newSVpv(lcbuf->mon_decimal_point, 0), 0);
	    if (lcbuf->mon_thousands_sep && *lcbuf->mon_thousands_sep)
		hv_store(RETVAL, "mon_thousands_sep", 17,
		    newSVpv(lcbuf->mon_thousands_sep, 0), 0);
	    if (lcbuf->mon_grouping && *lcbuf->mon_grouping)
		hv_store(RETVAL, "mon_grouping", 12,
		    newSVpv(lcbuf->mon_grouping, 0), 0);
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
	ST(0) = newRV((SV*)RETVAL);
	sv_2mortal(ST(0));
    }
    return ax;
}

static int
XS_POSIX_setlocale(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::setlocale(category, locale)");
    }
    {
	int	category = (int)SvIV(ST(1));
	char *	locale = SvPV(ST(2),na);
	char *	RETVAL;

	RETVAL = setlocale(category, locale);
	ST(0) = sv_newmortal();
	sv_setpv(ST(0), RETVAL);
    }
    return ax;
}

static int
XS_POSIX_acos(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::acos(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = acos(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_asin(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::asin(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = asin(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_atan(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::atan(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = atan(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_ceil(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::ceil(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = ceil(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_cosh(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::cosh(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = cosh(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_floor(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::floor(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = floor(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_fmod(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::fmod(x,y)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	y = (double)SvNV(ST(2));
	double	RETVAL;

	RETVAL = fmod(x, y);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_frexp(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::frexp(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	dSP;
	int expvar;
	sp--;
	/* (We already know stack is long enough.) */
	PUSHs(sv_2mortal(newSVnv(frexp(x,&expvar))));
	PUSHs(sv_2mortal(newSViv(expvar)));
	ax = sp - stack_base;
    }
    return ax;
}

static int
XS_POSIX_ldexp(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::ldexp(x,exp)");
    }
    {
	double	x = (double)SvNV(ST(1));
	int	exp = (int)SvIV(ST(2));
	double	RETVAL;

	RETVAL = ldexp(x, exp);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_log10(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::log10(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = log10(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_modf(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::modf(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	dSP;
	double intvar;
	sp--;
	/* (We already know stack is long enough.) */
	PUSHs(sv_2mortal(newSVnv(modf(x,&intvar))));
	PUSHs(sv_2mortal(newSVnv(intvar)));
	ax = sp - stack_base;
    }
    return ax;
}

static int
XS_POSIX_sinh(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::sinh(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = sinh(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_tanh(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::tanh(x)");
    }
    {
	double	x = (double)SvNV(ST(1));
	double	RETVAL;

	RETVAL = tanh(x);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_sigaction(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 2 || items > 3) {
	croak("Usage: POSIX::sigaction(sig, action, oldaction = 0)");
    }
    {
	int	sig = (int)SvIV(ST(1));
	POSIX__SigAction	action;
	POSIX__SigAction	oldaction;
	SysRet	RETVAL;

	if (sv_isa(ST(2), "POSIX::SigAction"))
	    action = (HV*)SvRV(ST(2));
	else
	    croak("action is not of type POSIX::SigAction");

	if (items < 3)
	    oldaction = 0;
	else {
	    if (sv_isa(ST(3), "POSIX::SigAction"))
		oldaction = (HV*)SvRV(ST(3));
	    else
		croak("oldaction is not of type POSIX::SigAction");
	}


	if (!siggv)
	    gv_fetchpv("SIG", TRUE, SVt_PVHV);

	{
	    struct sigaction act;
	    struct sigaction oact;
	    POSIX__SigSet sigset;
	    SV** svp;
	    SV** sigsvp = hv_fetch(GvHVn(siggv),
				 sig_name[sig],
				 strlen(sig_name[sig]),
				 TRUE);

	    /* Remember old handler name if desired. */
	    if (oldaction) {
		char *hand = SvPVx(*sigsvp, na);
		svp = hv_fetch(oldaction, "HANDLER", 7, TRUE);
		sv_setpv(*svp, *hand ? hand : "DEFAULT");
	    }

	    if (action) {
		/* Vector new handler through %SIG.  (We always use sighandler
		   for the C signal handler, which reads %SIG to dispatch.) */
		svp = hv_fetch(action, "HANDLER", 7, FALSE);
		if (!svp)
		    croak("Can't supply an action without a HANDLER");
		sv_setpv(*sigsvp, SvPV(*svp, na));
		mg_set(*sigsvp);	/* handles DEFAULT and IGNORE */
		act.sa_handler = sighandler;

		/* Set up any desired mask. */
		svp = hv_fetch(action, "MASK", 4, FALSE);
		if (svp && sv_isa(*svp, "POSIX::SigSet")) {
		    sigset = (sigset_t*)(unsigned long)SvNV((SV*)SvRV(*svp));
		    act.sa_mask = *sigset;
		}
		else
		    sigemptyset(& act.sa_mask);

		/* Set up any desired flags. */
		svp = hv_fetch(action, "FLAGS", 5, FALSE);
		act.sa_flags = svp ? SvIV(*svp) : 0;
	    }

	    /* Now work around sigaction oddities */
	    if (action && oldaction)
		RETVAL = sigaction(sig, & act, & oact);
	    else if (action)
		RETVAL = sigaction(sig, & act, (struct sigaction*)0);
	    else if (oldaction)
		RETVAL = sigaction(sig, (struct sigaction*)0, & oact);

	    if (oldaction) {
		/* Get back the mask. */
		svp = hv_fetch(oldaction, "MASK", 4, TRUE);
		if (sv_isa(*svp, "POSIX::SigSet"))
		    sigset = (sigset_t*)(unsigned long)SvNV((SV*)SvRV(*svp));
		else {
		    sigset = (sigset_t*)safemalloc(sizeof(sigset_t));
		    sv_setptrobj(*svp, sigset, "POSIX::SigSet");
		}
		*sigset = oact.sa_mask;

		/* Get back the flags. */
		svp = hv_fetch(oldaction, "FLAGS", 5, TRUE);
		sv_setiv(*svp, oact.sa_flags);
	    }
	}
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_sigpending(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::sigpending(sigset)");
    }
    {
	POSIX__SigSet	sigset;
	SysRet	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	RETVAL = sigpending(sigset);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_sigprocmask(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items < 2 || items > 3) {
	croak("Usage: POSIX::sigprocmask(how, sigset, oldsigset = 0)");
    }
    {
	int	how = (int)SvIV(ST(1));
	POSIX__SigSet	sigset;
	POSIX__SigSet	oldsigset;
	SysRet	RETVAL;

	if (sv_isa(ST(2), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(2)));
	    sigset = (POSIX__SigSet) tmp;
	}
	else
	    croak("sigset is not of type POSIX::SigSet");

	if (items < 3)
	    oldsigset = 0;
	else {
	    if (sv_isa(ST(3), "POSIX::SigSet")) {
		unsigned long tmp;
		tmp = (unsigned long)SvNV((SV*)SvRV(ST(3)));
		oldsigset = (POSIX__SigSet) tmp;
	    }
	    else
		croak("oldsigset is not of type POSIX::SigSet");
	}

	RETVAL = sigprocmask(how, sigset, oldsigset);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_sigsuspend(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::sigsuspend(signal_mask)");
    }
    {
	POSIX__SigSet	signal_mask;
	SysRet	RETVAL;

	if (sv_isa(ST(1), "POSIX::SigSet")) {
	    unsigned long tmp;
	    tmp = (unsigned long)SvNV((SV*)SvRV(ST(1)));
	    signal_mask = (POSIX__SigSet) tmp;
	}
	else
	    croak("signal_mask is not of type POSIX::SigSet");

	RETVAL = sigsuspend(signal_mask);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX__exit(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::_exit(status)");
    }
    {
	int	status = (int)SvIV(ST(1));

	_exit(status);
    }
    return ax;
}

static int
XS_POSIX_close(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::close(fd)");
    }
    {
	int	fd = (int)SvIV(ST(1));
	SysRet	RETVAL;

	RETVAL = close(fd);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_dup(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::dup(fd)");
    }
    {
	int	fd = (int)SvIV(ST(1));
	SysRet	RETVAL;

	RETVAL = dup(fd);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_dup2(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::dup2(fd1, fd2)");
    }
    {
	int	fd1 = (int)SvIV(ST(1));
	int	fd2 = (int)SvIV(ST(2));
	SysRet	RETVAL;

	RETVAL = dup2(fd1, fd2);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_lseek(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::lseek()");
    }
    {
	int;
	Off_t;
	int;
	SysRet	RETVAL;

	RETVAL = lseek();
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_nice(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::nice(incr)");
    }
    {
	int	incr = (int)SvIV(ST(1));
	SysRet	RETVAL;

	RETVAL = nice(incr);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_pipe(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::pipe()");
    }
    {
	int	RETVAL;
	dSP;
	int fds[2];
	sp--;
	if (pipe(fds) != -1) {
	    EXTEND(sp,2);
	    PUSHs(sv_2mortal(newSViv(fds[0])));
	    PUSHs(sv_2mortal(newSViv(fds[1])));
	}
	ax = sp - stack_base;
    }
    return ax;
}

static int
XS_POSIX_read(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::read()");
    }
    {
	SysRet	RETVAL;
	int fd;
	char * buffer;
	size_t nbytes;

	RETVAL = read(fd, buffer, nbytes);
	croak("POSIX::read() not implemented yet\n");
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_setgid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::setgid(gid)");
    }
    {
	Gid_t	gid = (Gid_t)SvNV(ST(1));
	SysRet	RETVAL;

	RETVAL = setgid(gid);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_setpgid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::setpgid(pid, pgid)");
    }
    {
	pid_t	pid = (pid_t)SvNV(ST(1));
	pid_t	pgid = (pid_t)SvNV(ST(2));
	SysRet	RETVAL;

	RETVAL = setpgid(pid, pgid);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_setsid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::setsid()");
    }
    {
	pid_t	RETVAL;

	RETVAL = setsid();
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_setuid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::setuid(uid)");
    }
    {
	Uid_t	uid = (Uid_t)SvNV(ST(1));
	SysRet	RETVAL;

	RETVAL = setuid(uid);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_tcgetpgrp(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::tcgetpgrp(fd)");
    }
    {
	int	fd = (int)SvIV(ST(1));
	pid_t	RETVAL;

	RETVAL = tcgetpgrp(fd);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_tcsetpgrp(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::tcsetpgrp(fd, pgrp_id)");
    }
    {
	int	fd = (int)SvIV(ST(1));
	pid_t	pgrp_id = (pid_t)SvNV(ST(2));
	SysRet	RETVAL;

	RETVAL = tcsetpgrp(fd, pgrp_id);
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

static int
XS_POSIX_uname(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::uname()");
    }
    {
	int	RETVAL;
	dSP;
	struct utsname buf;
	sp--;
	if (uname(&buf) >= 0) {
	    EXTEND(sp, 5);
	    PUSHs(sv_2mortal(newSVpv(buf.sysname, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.nodename, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.release, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.version, 0)));
	    PUSHs(sv_2mortal(newSVpv(buf.machine, 0)));
	}
	ax = sp - stack_base;
    }
    return ax;
}

static int
XS_POSIX_write(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::write()");
    }
    {
	SysRet	RETVAL;
	int fd;
	char * buffer;
	size_t nbytes;

	RETVAL = write(fd, buffer, nbytes);
	croak("POSIX::write() not implemented yet\n");
	ST(0) = sv_newmortal();
	if (RETVAL != -1) {
	    if (RETVAL == 0)
		sv_setpvn(ST(0), "0 but true", 10);
	    else
		sv_setiv(ST(0), (I32)RETVAL);
	}
    }
    return ax;
}

int boot_POSIX(ix,ax,items)
int ix;
int ax;
int items;
{
    char* file = __FILE__;

    newXSUB("POSIX::SigSet::new", 0, XS_POSIX__SigSet_new, file);
    newXSUB("POSIX::SigSet::DESTROY", 0, XS_POSIX__SigSet_DESTROY, file);
    newXSUB("POSIX::SigSet::addset", 0, XS_POSIX__SigSet_sigaddset, file);
    newXSUB("POSIX::SigSet::delset", 0, XS_POSIX__SigSet_sigdelset, file);
    newXSUB("POSIX::SigSet::emptyset", 0, XS_POSIX__SigSet_sigemptyset, file);
    newXSUB("POSIX::SigSet::fillset", 0, XS_POSIX__SigSet_sigfillset, file);
    newXSUB("POSIX::SigSet::ismember", 0, XS_POSIX__SigSet_sigismember, file);
    newXSUB("POSIX::constant", 0, XS_POSIX_constant, file);
    newXSUB("POSIX::isalnum", 0, XS_POSIX_isalnum, file);
    newXSUB("POSIX::isalpha", 0, XS_POSIX_isalpha, file);
    newXSUB("POSIX::iscntrl", 0, XS_POSIX_iscntrl, file);
    newXSUB("POSIX::isdigit", 0, XS_POSIX_isdigit, file);
    newXSUB("POSIX::isgraph", 0, XS_POSIX_isgraph, file);
    newXSUB("POSIX::islower", 0, XS_POSIX_islower, file);
    newXSUB("POSIX::isprint", 0, XS_POSIX_isprint, file);
    newXSUB("POSIX::ispunct", 0, XS_POSIX_ispunct, file);
    newXSUB("POSIX::isspace", 0, XS_POSIX_isspace, file);
    newXSUB("POSIX::isupper", 0, XS_POSIX_isupper, file);
    newXSUB("POSIX::isxdigit", 0, XS_POSIX_isxdigit, file);
    newXSUB("POSIX::open", 0, XS_POSIX_open, file);
    newXSUB("POSIX::localeconv", 0, XS_POSIX_localeconv, file);
    newXSUB("POSIX::setlocale", 0, XS_POSIX_setlocale, file);
    newXSUB("POSIX::acos", 0, XS_POSIX_acos, file);
    newXSUB("POSIX::asin", 0, XS_POSIX_asin, file);
    newXSUB("POSIX::atan", 0, XS_POSIX_atan, file);
    newXSUB("POSIX::ceil", 0, XS_POSIX_ceil, file);
    newXSUB("POSIX::cosh", 0, XS_POSIX_cosh, file);
    newXSUB("POSIX::floor", 0, XS_POSIX_floor, file);
    newXSUB("POSIX::fmod", 0, XS_POSIX_fmod, file);
    newXSUB("POSIX::frexp", 0, XS_POSIX_frexp, file);
    newXSUB("POSIX::ldexp", 0, XS_POSIX_ldexp, file);
    newXSUB("POSIX::log10", 0, XS_POSIX_log10, file);
    newXSUB("POSIX::modf", 0, XS_POSIX_modf, file);
    newXSUB("POSIX::sinh", 0, XS_POSIX_sinh, file);
    newXSUB("POSIX::tanh", 0, XS_POSIX_tanh, file);
    newXSUB("POSIX::sigaction", 0, XS_POSIX_sigaction, file);
    newXSUB("POSIX::sigpending", 0, XS_POSIX_sigpending, file);
    newXSUB("POSIX::sigprocmask", 0, XS_POSIX_sigprocmask, file);
    newXSUB("POSIX::sigsuspend", 0, XS_POSIX_sigsuspend, file);
    newXSUB("POSIX::_exit", 0, XS_POSIX__exit, file);
    newXSUB("POSIX::close", 0, XS_POSIX_close, file);
    newXSUB("POSIX::dup", 0, XS_POSIX_dup, file);
    newXSUB("POSIX::dup2", 0, XS_POSIX_dup2, file);
    newXSUB("POSIX::lseek", 0, XS_POSIX_lseek, file);
    newXSUB("POSIX::nice", 0, XS_POSIX_nice, file);
    newXSUB("POSIX::pipe", 0, XS_POSIX_pipe, file);
    newXSUB("POSIX::read", 0, XS_POSIX_read, file);
    newXSUB("POSIX::setgid", 0, XS_POSIX_setgid, file);
    newXSUB("POSIX::setpgid", 0, XS_POSIX_setpgid, file);
    newXSUB("POSIX::setsid", 0, XS_POSIX_setsid, file);
    newXSUB("POSIX::setuid", 0, XS_POSIX_setuid, file);
    newXSUB("POSIX::tcgetpgrp", 0, XS_POSIX_tcgetpgrp, file);
    newXSUB("POSIX::tcsetpgrp", 0, XS_POSIX_tcsetpgrp, file);
    newXSUB("POSIX::uname", 0, XS_POSIX_uname, file);
    newXSUB("POSIX::write", 0, XS_POSIX_write, file);
}
