#ifndef H_PERLLIO
#define H_PERLLIO 1

#ifdef PERL_OBJECT

#include "iplio.h"

#define PerlLIO_access(file, mode) piLIO->Access((file), (mode), ErrorNo())
#define PerlLIO_chmod(file, mode) piLIO->Chmod((file), (mode), ErrorNo())
#define PerlLIO_chown(file, owner, group) piLIO->Chown((file), (owner), (group), ErrorNo())
#define PerlLIO_chsize(fd, size) piLIO->Chsize((fd), (size), ErrorNo())
#define PerlLIO_close(fd) piLIO->Close((fd), ErrorNo())
#define PerlLIO_dup(fd) piLIO->Dup((fd), ErrorNo())
#define PerlLIO_dup2(fd1, fd2) piLIO->Dup2((fd1), (fd2), ErrorNo())
#define PerlLIO_flock(fd, op) piLIO->Flock((fd), (op), ErrorNo())
#define PerlLIO_fstat(fd, buf) piLIO->FileStat((fd), (buf), ErrorNo())
#define PerlLIO_ioctl(fd, u, buf) piLIO->IOCtl((fd), (u), (buf), ErrorNo())
#define PerlLIO_isatty(fd) piLIO->Isatty((fd), ErrorNo())
#define PerlLIO_lseek(fd, offset, mode) piLIO->Lseek((fd), (offset), (mode), ErrorNo())
#define PerlLIO_lstat(name, buf) piLIO->Lstat((name), (buf), ErrorNo())
#define PerlLIO_mktemp(file) piLIO->Mktemp((file), ErrorNo())
#define PerlLIO_open(file, flag) piLIO->Open((file), (flag), ErrorNo())
#define PerlLIO_open3(file, flag, perm) piLIO->Open((file), (flag), (perm), ErrorNo())
#define PerlLIO_read(fd, buf, count) piLIO->Read((fd), (buf), (count), ErrorNo())
#define PerlLIO_rename(oldname, newname) piLIO->Rename((oldname), (newname), ErrorNo())
#define PerlLIO_setmode(fd, mode) piLIO->Setmode((fd), (mode), ErrorNo())
#define PerlLIO_stat(name, buf) piLIO->NameStat((name), (buf), ErrorNo())
#define PerlLIO_tmpnam(str) piLIO->Tmpnam((str), ErrorNo())
#define PerlLIO_umask(mode) piLIO->Umask((mode), ErrorNo())
#define PerlLIO_unlink(file) piLIO->Unlink((file), ErrorNo())
#define PerlLIO_utime(file, time) piLIO->Utime((file), (time), ErrorNo())
#define PerlLIO_write(fd, buf, count) piLIO->Write((fd), (buf), (count), ErrorNo())
#else
#define PerlLIO_access(file, mode) access((file), (mode))
#define PerlLIO_chmod(file, mode) chmod((file), (mode))
#define PerlLIO_chown(file, owner, group) chown((file), (owner), (group))
#define PerlLIO_chsize(fd, size) chsize((fd), (size))
#define PerlLIO_close(fd) close((fd))
#define PerlLIO_dup(fd) dup((fd))
#define PerlLIO_dup2(fd1, fd2) dup2((fd1), (fd2))
#define PerlLIO_flock(fd, op) FLOCK((fd), (op))
#define PerlLIO_fstat(fd, buf) Fstat((fd), (buf))
#define PerlLIO_ioctl(fd, u, buf) ioctl((fd), (u), (buf))
#define PerlLIO_isatty(fd) isatty((fd))
#define PerlLIO_lseek(fd, offset, mode) lseek((fd), (offset), (mode))
#define PerlLIO_lstat(name, buf) lstat((name), (buf))
#define PerlLIO_mktemp(file) mktemp((file))
#define PerlLIO_mkstemp(file) mkstemp((file))
#define PerlLIO_open(file, flag) open((file), (flag))
#define PerlLIO_open3(file, flag, perm) open((file), (flag), (perm))
#define PerlLIO_read(fd, buf, count) read((fd), (buf), (count))
#define PerlLIO_rename(oldname, newname) rename((oldname), (newname))
#define PerlLIO_setmode(fd, mode) setmode((fd), (mode))
#define PerlLIO_stat(name, buf) Stat((name), (buf))
#define PerlLIO_tmpnam(str) tmpnam((str))
#define PerlLIO_umask(mode) umask((mode))
#define PerlLIO_unlink(file) unlink((file))
#define PerlLIO_utime(file, time) utime((file), (time))
#define PerlLIO_write(fd, buf, count) write((fd), (buf), (count))
#endif	/* PERL_OBJECT */

#endif /* Include guard */

