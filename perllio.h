#ifndef H_PERLLIO
#define H_PERLLIO 1

#ifdef PERL_OBJECT
#else
#define PerlLIO_access(file, mode) access((file), (mode))
#define PerlLIO_chmod(file, mode) chmod((file), (mode))
#define PerlLIO_chsize(fd, size) chsize((fd), (size))
#define PerlLIO_close(fd) close((fd))
#define PerlLIO_dup(fd) dup((fd))
#define PerlLIO_dup2(fd1, fd2) dup2((fd1), (fd2))
#define PerlLIO_fstat(fd, buf) Fstat((fd), (buf))
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

