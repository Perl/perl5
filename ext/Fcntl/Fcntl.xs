#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef VMS
#  include <file.h>
#else
#if defined(__GNUC__) && defined(__cplusplus) && defined(WIN32)
#define _NO_OLDNAMES
#endif 
#  include <fcntl.h>
#if defined(__GNUC__) && defined(__cplusplus) && defined(WIN32)
#undef _NO_OLDNAMES
#endif 
#endif

#ifdef I_UNISTD
#include <unistd.h>
#endif

/* This comment is a kludge to get metaconfig to see the symbols
    VAL_O_NONBLOCK
    VAL_EAGAIN
    RD_NODATA
    EOF_NONBLOCK
   and include the appropriate metaconfig unit
   so that Configure will test how to turn on non-blocking I/O
   for a file descriptor.  See config.h for how to use these
   in your extension. 
   
   While I'm at it, I'll have metaconfig look for HAS_POLL too.
   --AD  October 16, 1995
*/

#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNV	4
#define PERL_constant_ISPV	5
#define PERL_constant_ISPVN	6
#define PERL_constant_ISUV	7

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif

static int
constant_5 (const char *name, IV *iv_return) {
  /* Names all of length 5.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FEXCL FSYNC O_RAW */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'R':
    if (memEQ(name, "O_RAW", 5)) {
    /*                 ^        */
#ifdef O_RAW
      *iv_return = O_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "FEXCL", 5)) {
    /*                 ^        */
#ifdef FEXCL
      *iv_return = FEXCL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "FSYNC", 5)) {
    /*                 ^        */
#ifdef FSYNC
      *iv_return = FSYNC;
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
constant_6 (const char *name, IV *iv_return) {
  /* Names all of length 6.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FASYNC FCREAT FDEFER FDSYNC FRSYNC FTRUNC O_EXCL O_RDWR O_RSRC O_SYNC
     O_TEXT */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'D':
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
    if (memEQ(name, "FCREAT", 6)) {
    /*                  ^        */
#ifdef FCREAT
      *iv_return = FCREAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_TEXT", 6)) {
    /*                  ^        */
#ifdef O_TEXT
      *iv_return = O_TEXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "FDEFER", 6)) {
    /*                  ^        */
#ifdef FDEFER
      *iv_return = FDEFER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "O_RSRC", 6)) {
    /*                  ^        */
#ifdef O_RSRC
      *iv_return = O_RSRC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "FTRUNC", 6)) {
    /*                  ^        */
#ifdef FTRUNC
      *iv_return = FTRUNC;
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
  case 'Y':
    if (memEQ(name, "FASYNC", 6)) {
    /*                  ^        */
#ifdef FASYNC
      *iv_return = FASYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FDSYNC", 6)) {
    /*                  ^        */
#ifdef FDSYNC
      *iv_return = FDSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FRSYNC", 6)) {
    /*                  ^        */
#ifdef FRSYNC
      *iv_return = FRSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_SYNC", 6)) {
    /*                  ^        */
#ifdef O_SYNC
      *iv_return = O_SYNC;
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
constant_7 (const char *name, IV *iv_return) {
  /* Names all of length 7.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FAPPEND FNDELAY F_DUPFD F_EXLCK F_FSYNC F_GETFD F_GETFL F_GETLK F_NODNY
     F_POSIX F_RDACC F_RDDNY F_RDLCK F_RWACC F_RWDNY F_SETFD F_SETFL F_SETLK
     F_SHARE F_SHLCK F_UNLCK F_WRACC F_WRDNY F_WRLCK LOCK_EX LOCK_NB LOCK_SH
     LOCK_UN O_ALIAS O_ASYNC O_CREAT O_DEFER O_DSYNC O_RSYNC O_TRUNC S_ENFMT
     S_IEXEC S_IFBLK S_IFCHR S_IFDIR S_IFIFO S_IFLNK S_IFREG S_IFWHT S_IREAD
     S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU S_ISGID S_ISTXT S_ISUID
     S_ISVTX S_IWGRP S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR _S_IFMT */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "F_RDACC", 7)) {
    /*                   ^        */
#ifdef F_RDACC
      *iv_return = F_RDACC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_RWACC", 7)) {
    /*                   ^        */
#ifdef F_RWACC
      *iv_return = F_RWACC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SHARE", 7)) {
    /*                   ^        */
#ifdef F_SHARE
      *iv_return = F_SHARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_WRACC", 7)) {
    /*                   ^        */
#ifdef F_WRACC
      *iv_return = F_WRACC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "S_IFBLK", 7)) {
    /*                   ^        */
#ifdef S_IFBLK
      *iv_return = S_IFBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "S_IFCHR", 7)) {
    /*                   ^        */
#ifdef S_IFCHR
      *iv_return = S_IFCHR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "F_NODNY", 7)) {
    /*                   ^        */
#ifdef F_NODNY
      *iv_return = F_NODNY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_RDDNY", 7)) {
    /*                   ^        */
#ifdef F_RDDNY
      *iv_return = F_RDDNY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_RWDNY", 7)) {
    /*                   ^        */
#ifdef F_RWDNY
      *iv_return = F_RWDNY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_WRDNY", 7)) {
    /*                   ^        */
#ifdef F_WRDNY
      *iv_return = F_WRDNY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IFDIR", 7)) {
    /*                   ^        */
#ifdef S_IFDIR
      *iv_return = S_IFDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "FAPPEND", 7)) {
    /*                   ^        */
#ifdef FAPPEND
      *iv_return = FAPPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_CREAT", 7)) {
    /*                   ^        */
#ifdef O_CREAT
      *iv_return = O_CREAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IREAD", 7)) {
    /*                   ^        */
#ifdef S_IREAD
      *iv_return = S_IREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "O_DEFER", 7)) {
    /*                   ^        */
#ifdef O_DEFER
      *iv_return = O_DEFER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_ENFMT", 7)) {
    /*                   ^        */
#ifdef S_ENFMT
      *iv_return = S_ENFMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "_S_IFMT", 7)) {
    /*                   ^        */
#ifdef S_IFMT
      *iv_return = S_IFMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "S_IRGRP", 7)) {
    /*                   ^        */
#ifdef S_IRGRP
      *iv_return = S_IRGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_ISGID", 7)) {
    /*                   ^        */
#ifdef S_ISGID
      *iv_return = S_ISGID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWGRP", 7)) {
    /*                   ^        */
#ifdef S_IWGRP
      *iv_return = S_IWGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXGRP", 7)) {
    /*                   ^        */
#ifdef S_IXGRP
      *iv_return = S_IXGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "O_ALIAS", 7)) {
    /*                   ^        */
#ifdef O_ALIAS
      *iv_return = O_ALIAS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IFIFO", 7)) {
    /*                   ^        */
#ifdef S_IFIFO
      *iv_return = S_IFIFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "FNDELAY", 7)) {
    /*                   ^        */
#ifdef FNDELAY
      *iv_return = FNDELAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_EXLCK", 7)) {
    /*                   ^        */
#ifdef F_EXLCK
      *iv_return = F_EXLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_RDLCK", 7)) {
    /*                   ^        */
#ifdef F_RDLCK
      *iv_return = F_RDLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SHLCK", 7)) {
    /*                   ^        */
#ifdef F_SHLCK
      *iv_return = F_SHLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_UNLCK", 7)) {
    /*                   ^        */
#ifdef F_UNLCK
      *iv_return = F_UNLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_WRLCK", 7)) {
    /*                   ^        */
#ifdef F_WRLCK
      *iv_return = F_WRLCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IFLNK", 7)) {
    /*                   ^        */
#ifdef S_IFLNK
      *iv_return = S_IFLNK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "S_IROTH", 7)) {
    /*                   ^        */
#ifdef S_IROTH
      *iv_return = S_IROTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWOTH", 7)) {
    /*                   ^        */
#ifdef S_IWOTH
      *iv_return = S_IWOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXOTH", 7)) {
    /*                   ^        */
#ifdef S_IXOTH
      *iv_return = S_IXOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "F_DUPFD", 7)) {
    /*                   ^        */
#ifdef F_DUPFD
      *iv_return = F_DUPFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "S_IFREG", 7)) {
    /*                   ^        */
#ifdef S_IFREG
      *iv_return = S_IFREG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "F_POSIX", 7)) {
    /*                   ^        */
#ifdef F_POSIX
      *iv_return = F_POSIX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "F_GETFD", 7)) {
    /*                   ^        */
#ifdef F_GETFD
      *iv_return = F_GETFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_GETFL", 7)) {
    /*                   ^        */
#ifdef F_GETFL
      *iv_return = F_GETFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_GETLK", 7)) {
    /*                   ^        */
#ifdef F_GETLK
      *iv_return = F_GETLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETFD", 7)) {
    /*                   ^        */
#ifdef F_SETFD
      *iv_return = F_SETFD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETFL", 7)) {
    /*                   ^        */
#ifdef F_SETFL
      *iv_return = F_SETFL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETLK", 7)) {
    /*                   ^        */
#ifdef F_SETLK
      *iv_return = F_SETLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_ISTXT", 7)) {
    /*                   ^        */
#ifdef S_ISTXT
      *iv_return = S_ISTXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "O_TRUNC", 7)) {
    /*                   ^        */
#ifdef O_TRUNC
      *iv_return = O_TRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRUSR", 7)) {
    /*                   ^        */
#ifdef S_IRUSR
      *iv_return = S_IRUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_ISUID", 7)) {
    /*                   ^        */
#ifdef S_ISUID
      *iv_return = S_ISUID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWUSR", 7)) {
    /*                   ^        */
#ifdef S_IWUSR
      *iv_return = S_IWUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXUSR", 7)) {
    /*                   ^        */
#ifdef S_IXUSR
      *iv_return = S_IXUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "S_ISVTX", 7)) {
    /*                   ^        */
#ifdef S_ISVTX
      *iv_return = S_ISVTX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "S_IFWHT", 7)) {
    /*                   ^        */
#ifdef S_IFWHT
      *iv_return = S_IFWHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXG", 7)) {
    /*                   ^        */
#ifdef S_IRWXG
      *iv_return = S_IRWXG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXO", 7)) {
    /*                   ^        */
#ifdef S_IRWXO
      *iv_return = S_IRWXO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXU", 7)) {
    /*                   ^        */
#ifdef S_IRWXU
      *iv_return = S_IRWXU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "S_IEXEC", 7)) {
    /*                   ^        */
#ifdef S_IEXEC
      *iv_return = S_IEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "F_FSYNC", 7)) {
    /*                   ^        */
#ifdef F_FSYNC
      *iv_return = F_FSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_ASYNC", 7)) {
    /*                   ^        */
#ifdef O_ASYNC
      *iv_return = O_ASYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_DSYNC", 7)) {
    /*                   ^        */
#ifdef O_DSYNC
      *iv_return = O_DSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_RSYNC", 7)) {
    /*                   ^        */
#ifdef O_RSYNC
      *iv_return = O_RSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "LOCK_EX", 7)) {
    /*                   ^        */
#ifdef LOCK_EX
      *iv_return = LOCK_EX;
      return PERL_constant_ISIV;
#else
      *iv_return = 2;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "LOCK_NB", 7)) {
    /*                   ^        */
#ifdef LOCK_NB
      *iv_return = LOCK_NB;
      return PERL_constant_ISIV;
#else
      *iv_return = 4;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "LOCK_SH", 7)) {
    /*                   ^        */
#ifdef LOCK_SH
      *iv_return = LOCK_SH;
      return PERL_constant_ISIV;
#else
      *iv_return = 1;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "LOCK_UN", 7)) {
    /*                   ^        */
#ifdef LOCK_UN
      *iv_return = LOCK_UN;
      return PERL_constant_ISIV;
#else
      *iv_return = 8;
      return PERL_constant_ISIV;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (const char *name, IV *iv_return) {
  /* Names all of length 8.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     F_COMPAT F_DUP2FD F_FREESP F_GETOWN F_SETLKW F_SETOWN O_APPEND O_BINARY
     O_DIRECT O_EXLOCK O_NDELAY O_NOCTTY O_RANDOM O_RDONLY O_SHLOCK O_WRONLY
     SEEK_CUR SEEK_END SEEK_SET S_IFSOCK S_IWRITE */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'A':
    if (memEQ(name, "O_RANDOM", 8)) {
    /*                  ^          */
#ifdef O_RANDOM
      *iv_return = O_RANDOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "O_NDELAY", 8)) {
    /*                  ^          */
#ifdef O_NDELAY
      *iv_return = O_NDELAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_RDONLY", 8)) {
    /*                  ^          */
#ifdef O_RDONLY
      *iv_return = O_RDONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "F_GETOWN", 8)) {
    /*                  ^          */
#ifdef F_GETOWN
      *iv_return = F_GETOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETLKW", 8)) {
    /*                  ^          */
#ifdef F_SETLKW
      *iv_return = F_SETLKW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "F_SETOWN", 8)) {
    /*                  ^          */
#ifdef F_SETOWN
      *iv_return = F_SETOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "S_IFSOCK", 8)) {
    /*                  ^          */
#ifdef S_IFSOCK
      *iv_return = S_IFSOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "O_SHLOCK", 8)) {
    /*                  ^          */
#ifdef O_SHLOCK
      *iv_return = O_SHLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "O_BINARY", 8)) {
    /*                  ^          */
#ifdef O_BINARY
      *iv_return = O_BINARY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_DIRECT", 8)) {
    /*                  ^          */
#ifdef O_DIRECT
      *iv_return = O_DIRECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "SEEK_CUR", 8)) {
    /*                  ^          */
#ifdef SEEK_CUR
      *iv_return = SEEK_CUR;
      return PERL_constant_ISIV;
#else
      *iv_return = 1;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "SEEK_END", 8)) {
    /*                  ^          */
#ifdef SEEK_END
      *iv_return = SEEK_END;
      return PERL_constant_ISIV;
#else
      *iv_return = 2;
      return PERL_constant_ISIV;
#endif
    }
    if (memEQ(name, "SEEK_SET", 8)) {
    /*                  ^          */
#ifdef SEEK_SET
      *iv_return = SEEK_SET;
      return PERL_constant_ISIV;
#else
      *iv_return = 0;
      return PERL_constant_ISIV;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "F_COMPAT", 8)) {
    /*                  ^          */
#ifdef F_COMPAT
      *iv_return = F_COMPAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_NOCTTY", 8)) {
    /*                  ^          */
#ifdef O_NOCTTY
      *iv_return = O_NOCTTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "O_APPEND", 8)) {
    /*                  ^          */
#ifdef O_APPEND
      *iv_return = O_APPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "F_FREESP", 8)) {
    /*                  ^          */
#ifdef F_FREESP
      *iv_return = F_FREESP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_WRONLY", 8)) {
    /*                  ^          */
#ifdef O_WRONLY
      *iv_return = O_WRONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "F_DUP2FD", 8)) {
    /*                  ^          */
#ifdef F_DUP2FD
      *iv_return = F_DUP2FD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "S_IWRITE", 8)) {
    /*                  ^          */
#ifdef S_IWRITE
      *iv_return = S_IWRITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "O_EXLOCK", 8)) {
    /*                  ^          */
#ifdef O_EXLOCK
      *iv_return = O_EXLOCK;
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
constant_9 (const char *name, IV *iv_return) {
  /* Names all of length 9.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FNONBLOCK F_ALLOCSP F_FSYNC64 F_GETLK64 F_SETLK64 F_UNSHARE O_ACCMODE */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'A':
    if (memEQ(name, "F_ALLOCSP", 9)) {
    /*                 ^            */
#ifdef F_ALLOCSP
      *iv_return = F_ALLOCSP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_ACCMODE", 9)) {
    /*                 ^            */
#ifdef O_ACCMODE
      *iv_return = O_ACCMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "F_FSYNC64", 9)) {
    /*                 ^            */
#ifdef F_FSYNC64
      *iv_return = F_FSYNC64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "F_GETLK64", 9)) {
    /*                 ^            */
#ifdef F_GETLK64
      *iv_return = F_GETLK64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "FNONBLOCK", 9)) {
    /*                 ^            */
#ifdef FNONBLOCK
      *iv_return = FNONBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "F_SETLK64", 9)) {
    /*                 ^            */
#ifdef F_SETLK64
      *iv_return = F_SETLK64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "F_UNSHARE", 9)) {
    /*                 ^            */
#ifdef F_UNSHARE
      *iv_return = F_UNSHARE;
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
constant_10 (const char *name, IV *iv_return) {
  /* Names all of length 10.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FD_CLOEXEC FLARGEFILE F_FREESP64 F_SETLKW64 O_NOFOLLOW O_NONBLOCK */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'E':
    if (memEQ(name, "F_FREESP64", 10)) {
    /*                   ^            */
#ifdef F_FREESP64
      *iv_return = F_FREESP64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "O_NOFOLLOW", 10)) {
    /*                   ^            */
#ifdef O_NOFOLLOW
      *iv_return = O_NOFOLLOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "FLARGEFILE", 10)) {
    /*                   ^            */
#ifdef FLARGEFILE
      *iv_return = FLARGEFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "FD_CLOEXEC", 10)) {
    /*                   ^            */
#ifdef FD_CLOEXEC
      *iv_return = FD_CLOEXEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "O_NONBLOCK", 10)) {
    /*                   ^            */
#ifdef O_NONBLOCK
      *iv_return = O_NONBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "F_SETLKW64", 10)) {
    /*                   ^            */
#ifdef F_SETLKW64
      *iv_return = F_SETLKW64;
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
constant_11 (const char *name, IV *iv_return) {
  /* Names all of length 11.  */
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     F_ALLOCSP64 O_DIRECTORY O_LARGEFILE O_NOINHERIT O_TEMPORARY */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'E':
    if (memEQ(name, "O_DIRECTORY", 11)) {
    /*                    ^            */
#ifdef O_DIRECTORY
      *iv_return = O_DIRECTORY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "O_LARGEFILE", 11)) {
    /*                    ^            */
#ifdef O_LARGEFILE
      *iv_return = O_LARGEFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "O_NOINHERIT", 11)) {
    /*                    ^            */
#ifdef O_NOINHERIT
      *iv_return = O_NOINHERIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "F_ALLOCSP64", 11)) {
    /*                    ^            */
#ifdef F_ALLOCSP64
      *iv_return = F_ALLOCSP64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "O_TEMPORARY", 11)) {
    /*                    ^            */
#ifdef O_TEMPORARY
      *iv_return = O_TEMPORARY;
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
constant (const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {IV => 1};
my @names = (qw(FAPPEND FASYNC FCREAT FDEFER FDSYNC FD_CLOEXEC FEXCL FLARGEFILE
	       FNDELAY FNONBLOCK FRSYNC FSYNC FTRUNC F_ALLOCSP F_ALLOCSP64
	       F_COMPAT F_DUP2FD F_DUPFD F_EXLCK F_FREESP F_FREESP64 F_FSYNC
	       F_FSYNC64 F_GETFD F_GETFL F_GETLK F_GETLK64 F_GETOWN F_NODNY
	       F_POSIX F_RDACC F_RDDNY F_RDLCK F_RWACC F_RWDNY F_SETFD F_SETFL
	       F_SETLK F_SETLK64 F_SETLKW F_SETLKW64 F_SETOWN F_SHARE F_SHLCK
	       F_UNLCK F_UNSHARE F_WRACC F_WRDNY F_WRLCK O_ACCMODE O_ALIAS
	       O_APPEND O_ASYNC O_BINARY O_CREAT O_DEFER O_DIRECT O_DIRECTORY
	       O_DSYNC O_EXCL O_EXLOCK O_LARGEFILE O_NDELAY O_NOCTTY O_NOFOLLOW
	       O_NOINHERIT O_NONBLOCK O_RANDOM O_RAW O_RDONLY O_RDWR O_RSRC
	       O_RSYNC O_SEQUENTIAL O_SHLOCK O_SYNC O_TEMPORARY O_TEXT O_TRUNC
	       O_WRONLY S_ENFMT S_IEXEC S_IFBLK S_IFCHR S_IFDIR S_IFIFO S_IFLNK
	       S_IFREG S_IFSOCK S_IFWHT S_IREAD S_IRGRP S_IROTH S_IRUSR S_IRWXG
	       S_IRWXO S_IRWXU S_ISGID S_ISTXT S_ISUID S_ISVTX S_IWGRP S_IWOTH
	       S_IWRITE S_IWUSR S_IXGRP S_IXOTH S_IXUSR),
            {name=>"LOCK_EX", type=>"IV", default=>["IV", "2"]},
            {name=>"LOCK_NB", type=>"IV", default=>["IV", "4"]},
            {name=>"LOCK_SH", type=>"IV", default=>["IV", "1"]},
            {name=>"LOCK_UN", type=>"IV", default=>["IV", "8"]},
            {name=>"SEEK_CUR", type=>"IV", default=>["IV", "1"]},
            {name=>"SEEK_END", type=>"IV", default=>["IV", "2"]},
            {name=>"SEEK_SET", type=>"IV", default=>["IV", "0"]},
            {name=>"_S_IFMT", type=>"IV", macro=>"S_IFMT", value=>"S_IFMT"});

print constant_types(); # macro defs
foreach (C_constant ("Fcntl", 'constant', 'IV', $types, undef, undef, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Fcntl", $types);
__END__
   */

  switch (len) {
  case 5:
    return constant_5 (name, iv_return);
    break;
  case 6:
    return constant_6 (name, iv_return);
    break;
  case 7:
    return constant_7 (name, iv_return);
    break;
  case 8:
    return constant_8 (name, iv_return);
    break;
  case 9:
    return constant_9 (name, iv_return);
    break;
  case 10:
    return constant_10 (name, iv_return);
    break;
  case 11:
    return constant_11 (name, iv_return);
    break;
  case 12:
    if (memEQ(name, "O_SEQUENTIAL", 12)) {
#ifdef O_SEQUENTIAL
      *iv_return = O_SEQUENTIAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

MODULE = Fcntl		PACKAGE = Fcntl

void
constant(sv)
    PREINIT:
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
    INPUT:
	SV *		sv;
        const char *	s = SvPV(sv, len);
    PPCODE:
        /* Change this to constant(s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid Fcntl macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined Fcntl macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Fcntl macro %s used",
               type, s));
          PUSHs(sv);
        }
