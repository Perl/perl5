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

MODULE = POSIX	PACKAGE = POSIX

void
_exit(status)
	int		status

int
chdir(path)
	char *		path

int
chmod(path, mode)
	char *		path
	mode_t		mode

int
close(fd)
	int		fd

int
dup(fd)
	int		fd

int
dup2(fd1, fd2)
	int		fd1
	int		fd2

FILE *
fdopen(fd, type)
	int		fd
	char *		type

int
fstat(fd, buf)
	int		fd
	struct stat *	buf = (struct stat*)sv_grow(ST(2),sizeof(struct stat));
	CLEANUP:
	SvCUR(ST(2)) = sizeof(struct stat);

int
getpgrp(pid)
	int		pid

int
link()

int
lseek()

int
lstat()

int
mkdir()

int
nice(incr)
	int		incr

int
open()

int
pipe()

int
read()

int
readlink(path, buf, bufsiz)
	char *		path
	char *		buf = sv_grow(ST(2), SvIV(ST(3)));
	int		bufsiz

int
rename()

int
rmdir()

int
setgid()

int
setpgid(pid, pgid)
	pid_t		pid
	pid_t		pgid

int
setpgrp(pid, pgrp)
	int		pid
	int		pgrp

pid_t
setsid()

int
setuid()

int
stat()

int
symlink()

int
system()

pid_t
tcgetpgrp(fd)
	int		fd

int
tcsetpgrp(fd, pgrp_id)
	int		fd
	pid_t		pgrp_id

int
times(tms)
	struct tms *	tms = (struct tms*)sv_grow(ST(1), sizeof(struct tms));
	CLEANUP:
	SvCUR(ST(1)) = sizeof(struct tms);

int
umask()

int
uname()
	CODE:
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

int
unlink()

int
utime()

int
wait()

int
waitpid(pid, statusp, options)
	int		pid
	int		&statusp
	int		options
	OUTPUT:
	statusp

int
write()

