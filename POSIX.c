#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/utsname.h>

#define HAS_UNAME

#ifndef HAS_GETPGRP
#define getpgrp(a,b) not_here("getpgrp")
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
#ifndef HAS_SETPGRP
#define setpgrp(a,b) not_here("setpgrp")
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
XS_POSIX_chdir(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::chdir(path)");
    }
    {
	char *	path = SvPV(ST(1),na);
	int	RETVAL;

	RETVAL = chdir(path);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_chmod(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::chmod(path, mode)");
    }
    {
	char *	path = SvPV(ST(1),na);
	mode_t	mode = (int)SvIV(ST(2));
	int	RETVAL;

	RETVAL = chmod(path, mode);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	int	RETVAL;

	RETVAL = close(fd);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	int	RETVAL;

	RETVAL = dup(fd);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	int	RETVAL;

	RETVAL = dup2(fd1, fd2);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_fdopen(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::fdopen(fd, type)");
    }
    {
	int	fd = (int)SvIV(ST(1));
	char *	type = SvPV(ST(2),na);
	FILE *	RETVAL;

	RETVAL = fdopen(fd, type);
	ST(0) = sv_newmortal();
	sv_setnv(ST(0), (double)(unsigned long)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_fstat(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::fstat(fd, buf)");
    }
    {
	int	fd = (int)SvIV(ST(1));
	struct stat * buf = (struct stat*)sv_grow(ST(2),sizeof(struct stat));
	int	RETVAL;

	RETVAL = fstat(fd, buf);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
	SvCUR(ST(2)) = sizeof(struct stat);
    }
    return ax;
}

static int
XS_POSIX_getpgrp(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::getpgrp(pid)");
    }
    {
	int	pid = (int)SvIV(ST(1));
	int	RETVAL;

	RETVAL = getpgrp(pid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_link(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::link()");
    }
    {
	int	RETVAL;

	RETVAL = link();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	int	RETVAL;

	RETVAL = lseek();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_lstat(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::lstat()");
    }
    {
	int	RETVAL;

	RETVAL = lstat();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_mkdir(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::mkdir()");
    }
    {
	int	RETVAL;

	RETVAL = mkdir();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	int	RETVAL;

	RETVAL = nice(incr);
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
    if (items != 0) {
	croak("Usage: POSIX::open()");
    }
    {
	int	RETVAL;

	RETVAL = open();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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

	RETVAL = pipe();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	int	RETVAL;

	RETVAL = read();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_readlink(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 3) {
	croak("Usage: POSIX::readlink(path, buf, bufsiz)");
    }
    {
	char *	path = SvPV(ST(1),na);
	char * buf = sv_grow(ST(2), SvIV(ST(3)));
	int	bufsiz = (int)SvIV(ST(3));
	int	RETVAL;

	RETVAL = readlink(path, buf, bufsiz);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_rename(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::rename()");
    }
    {
	int	RETVAL;

	RETVAL = rename();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_rmdir(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::rmdir()");
    }
    {
	int	RETVAL;

	RETVAL = rmdir();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_setgid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::setgid()");
    }
    {
	int	RETVAL;

	RETVAL = setgid();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	pid_t	pid = (int)SvIV(ST(1));
	pid_t	pgid = (int)SvIV(ST(2));
	int	RETVAL;

	RETVAL = setpgid(pid, pgid);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_setpgrp(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 2) {
	croak("Usage: POSIX::setpgrp(pid, pgrp)");
    }
    {
	int	pid = (int)SvIV(ST(1));
	int	pgrp = (int)SvIV(ST(2));
	int	RETVAL;

	RETVAL = setpgrp(pid, pgrp);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_setuid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::setuid()");
    }
    {
	int	RETVAL;

	RETVAL = setuid();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_stat(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::stat()");
    }
    {
	int	RETVAL;

	RETVAL = stat();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_symlink(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::symlink()");
    }
    {
	int	RETVAL;

	RETVAL = symlink();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_system(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::system()");
    }
    {
	int	RETVAL;

	RETVAL = system();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	sv_setiv(ST(0), (I32)RETVAL);
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
	pid_t	pgrp_id = (int)SvIV(ST(2));
	int	RETVAL;

	RETVAL = tcsetpgrp(fd, pgrp_id);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_times(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 1) {
	croak("Usage: POSIX::times(tms)");
    }
    {
	struct tms * tms = (struct tms*)sv_grow(ST(1), sizeof(struct tms));
	int	RETVAL;

	RETVAL = times(tms);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
	SvCUR(ST(1)) = sizeof(struct tms);
    }
    return ax;
}

static int
XS_POSIX_umask(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::umask()");
    }
    {
	int	RETVAL;

	RETVAL = umask();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
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
	struct utsname utsname;
	sp--;
	if (uname(&utsname) >= 0) {
	    EXTEND(sp, 5);
	    PUSHs(sv_2mortal(newSVpv(utsname.sysname, 0)));
	    PUSHs(sv_2mortal(newSVpv(utsname.nodename, 0)));
	    PUSHs(sv_2mortal(newSVpv(utsname.release, 0)));
	    PUSHs(sv_2mortal(newSVpv(utsname.version, 0)));
	    PUSHs(sv_2mortal(newSVpv(utsname.machine, 0)));
	}
	return sp - stack_base;
    }
    return ax;
}

static int
XS_POSIX_unlink(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::unlink()");
    }
    {
	int	RETVAL;

	RETVAL = unlink();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_utime(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::utime()");
    }
    {
	int	RETVAL;

	RETVAL = utime();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_wait(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 0) {
	croak("Usage: POSIX::wait()");
    }
    {
	int	RETVAL;

	RETVAL = wait();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

static int
XS_POSIX_waitpid(ix, ax, items)
register int ix;
register int ax;
register int items;
{
    if (items != 3) {
	croak("Usage: POSIX::waitpid(pid, statusp, options)");
    }
    {
	int	pid = (int)SvIV(ST(1));
	int	statusp = (int)SvIV(ST(2));
	int	options = (int)SvIV(ST(3));
	int	RETVAL;

	RETVAL = waitpid(pid, &statusp, options);
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
	sv_setiv(ST(2), (I32)statusp);
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
	int	RETVAL;

	RETVAL = write();
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (I32)RETVAL);
    }
    return ax;
}

int boot_POSIX(ix,ax,items)
int ix;
int ax;
int items;
{
    char* file = __FILE__;

    newXSUB("POSIX::_exit", 0, XS_POSIX__exit, file);
    newXSUB("POSIX::chdir", 0, XS_POSIX_chdir, file);
    newXSUB("POSIX::chmod", 0, XS_POSIX_chmod, file);
    newXSUB("POSIX::close", 0, XS_POSIX_close, file);
    newXSUB("POSIX::dup", 0, XS_POSIX_dup, file);
    newXSUB("POSIX::dup2", 0, XS_POSIX_dup2, file);
    newXSUB("POSIX::fdopen", 0, XS_POSIX_fdopen, file);
    newXSUB("POSIX::fstat", 0, XS_POSIX_fstat, file);
    newXSUB("POSIX::getpgrp", 0, XS_POSIX_getpgrp, file);
    newXSUB("POSIX::link", 0, XS_POSIX_link, file);
    newXSUB("POSIX::lseek", 0, XS_POSIX_lseek, file);
    newXSUB("POSIX::lstat", 0, XS_POSIX_lstat, file);
    newXSUB("POSIX::mkdir", 0, XS_POSIX_mkdir, file);
    newXSUB("POSIX::nice", 0, XS_POSIX_nice, file);
    newXSUB("POSIX::open", 0, XS_POSIX_open, file);
    newXSUB("POSIX::pipe", 0, XS_POSIX_pipe, file);
    newXSUB("POSIX::read", 0, XS_POSIX_read, file);
    newXSUB("POSIX::readlink", 0, XS_POSIX_readlink, file);
    newXSUB("POSIX::rename", 0, XS_POSIX_rename, file);
    newXSUB("POSIX::rmdir", 0, XS_POSIX_rmdir, file);
    newXSUB("POSIX::setgid", 0, XS_POSIX_setgid, file);
    newXSUB("POSIX::setpgid", 0, XS_POSIX_setpgid, file);
    newXSUB("POSIX::setpgrp", 0, XS_POSIX_setpgrp, file);
    newXSUB("POSIX::setsid", 0, XS_POSIX_setsid, file);
    newXSUB("POSIX::setuid", 0, XS_POSIX_setuid, file);
    newXSUB("POSIX::stat", 0, XS_POSIX_stat, file);
    newXSUB("POSIX::symlink", 0, XS_POSIX_symlink, file);
    newXSUB("POSIX::system", 0, XS_POSIX_system, file);
    newXSUB("POSIX::tcgetpgrp", 0, XS_POSIX_tcgetpgrp, file);
    newXSUB("POSIX::tcsetpgrp", 0, XS_POSIX_tcsetpgrp, file);
    newXSUB("POSIX::times", 0, XS_POSIX_times, file);
    newXSUB("POSIX::umask", 0, XS_POSIX_umask, file);
    newXSUB("POSIX::uname", 0, XS_POSIX_uname, file);
    newXSUB("POSIX::unlink", 0, XS_POSIX_unlink, file);
    newXSUB("POSIX::utime", 0, XS_POSIX_utime, file);
    newXSUB("POSIX::wait", 0, XS_POSIX_wait, file);
    newXSUB("POSIX::waitpid", 0, XS_POSIX_waitpid, file);
    newXSUB("POSIX::write", 0, XS_POSIX_write, file);
}
