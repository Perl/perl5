/* $Header: doio.c,v 3.0.1.12 90/10/20 02:04:18 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	doio.c,v $
 * Revision 3.0.1.12  90/10/20  02:04:18  lwall
 * patch37: split out separate Sys V IPC features
 * 
 * Revision 3.0.1.11  90/10/15  16:16:11  lwall
 * patch29: added SysV IPC
 * patch29: file - didn't auto-close cleanly
 * patch29: close; core dumped
 * patch29: more MSDOS and OS/2 updates, from Kai Uwe Rommel
 * patch29: various portability fixes
 * patch29: *foo now prints as *package'foo
 * 
 * Revision 3.0.1.10  90/08/13  22:14:29  lwall
 * patch28: close-on-exec problems on dup'ed file descriptors
 * patch28: F_FREESP wasn't implemented the way I thought
 * 
 * Revision 3.0.1.9  90/08/09  02:56:19  lwall
 * patch19: various MSDOS and OS/2 patches folded in
 * patch19: prints now check error status better
 * patch19: printing a list with null elements only printed front of list
 * patch19: on machines with vfork child would allocate memory in parent
 * patch19: getsockname and getpeername gave bogus warning on error
 * patch19: MACH doesn't have seekdir or telldir
 * 
 * Revision 3.0.1.8  90/03/27  15:44:02  lwall
 * patch16: MSDOS support
 * patch16: support for machines that can't cast negative floats to unsigned ints
 * patch16: system() can lose arguments passed to shell scripts on SysV machines
 * 
 * Revision 3.0.1.7  90/03/14  12:26:24  lwall
 * patch15: commands involving execs could cause malloc arena corruption
 * 
 * Revision 3.0.1.6  90/03/12  16:30:07  lwall
 * patch13: system 'FOO=bar command' didn't invoke sh as it should
 * 
 * Revision 3.0.1.5  90/02/28  17:01:36  lwall
 * patch9: open(FOO,"$filename\0") will now protect trailing spaces in filename
 * patch9: removed obsolete checks to avoid opening block devices
 * patch9: removed references to acusec and modusec that some utime.h's have
 * patch9: added pipe function
 * 
 * Revision 3.0.1.4  89/12/21  19:55:10  lwall
 * patch7: select now works on big-endian machines
 * patch7: errno may now be a macro with an lvalue
 * patch7: ANSI strerror() is now supported
 * patch7: Configure now detects DG/UX thingies like [sg]etpgrp2 and utime.h
 * 
 * Revision 3.0.1.3  89/11/17  15:13:06  lwall
 * patch5: some systems have symlink() but not lstat()
 * patch5: some systems have dirent.h but not readdir()
 * 
 * Revision 3.0.1.2  89/11/11  04:25:51  lwall
 * patch2: orthogonalized the file modes some so we can have <& +<& etc.
 * patch2: do_open() now detects sockets passed to process from parent
 * patch2: fd's above 2 are now closed on exec
 * patch2: csh code can now use csh from other than /bin
 * patch2: getsockopt, get{sock,peer}name didn't define result properly
 * patch2: warn("shutdown") was replicated
 * patch2: gethostbyname was misdeclared
 * patch2: telldir() is sometimes a macro
 * 
 * Revision 3.0.1.1  89/10/26  23:10:05  lwall
 * patch1: Configure now checks for BSD shadow passwords
 * 
 * Revision 3.0  89/10/18  15:10:54  lwall
 * 3.0 baseline
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#ifdef SOCKET
#include <sys/socket.h>
#include <netdb.h>
#endif

#if defined(SELECT) && (defined(M_UNIX) || defined(M_XENIX))
#include <sys/select.h>
#endif

#ifdef SYSVIPC
#include <sys/ipc.h>
#ifdef IPCMSG
#include <sys/msg.h>
#endif
#ifdef IPCSEM
#include <sys/sem.h>
#endif
#ifdef IPCSHM
#include <sys/shm.h>
#endif
#endif

#ifdef I_PWD
#include <pwd.h>
#endif
#ifdef I_GRP
#include <grp.h>
#endif
#ifdef I_UTIME
#include <utime.h>
#endif
#ifdef I_FCNTL
#include <fcntl.h>
#endif

bool
do_open(stab,name,len)
STAB *stab;
register char *name;
int len;
{
    FILE *fp;
    register STIO *stio = stab_io(stab);
    char *myname = savestr(name);
    int result;
    int fd;
    int writing = 0;
    char mode[3];		/* stdio file mode ("r\0" or "r+\0") */

    name = myname;
    forkprocess = 1;		/* assume true if no fork */
    while (len && isspace(name[len-1]))
	name[--len] = '\0';
    if (!stio)
	stio = stab_io(stab) = stio_new();
    else if (stio->ifp) {
	fd = fileno(stio->ifp);
	if (stio->type == '|')
	    result = mypclose(stio->ifp);
	else if (stio->type == '-')
	    result = 0;
	else if (stio->ifp != stio->ofp) {
	    if (stio->ofp) {
		result = fclose(stio->ofp);
		fclose(stio->ifp);	/* clear stdio, fd already closed */
	    }
	    else
		result = fclose(stio->ifp);
	}
	else
	    result = fclose(stio->ifp);
	if (result == EOF && fd > 2)
	    fprintf(stderr,"Warning: unable to close filehandle %s properly.\n",
	      stab_name(stab));
	stio->ofp = stio->ifp = Nullfp;
    }
    if (*name == '+' && len > 1 && name[len-1] != '|') {	/* scary */
	mode[1] = *name++;
	mode[2] = '\0';
	--len;
	writing = 1;
    }
    else  {
	mode[1] = '\0';
    }
    stio->type = *name;
    if (*name == '|') {
	for (name++; isspace(*name); name++) ;
#ifdef TAINT
	taintenv();
	taintproper("Insecure dependency in piped open");
#endif
	fp = mypopen(name,"w");
	writing = 1;
    }
    else if (*name == '>') {
#ifdef TAINT
	taintproper("Insecure dependency in open");
#endif
	name++;
	if (*name == '>') {
	    mode[0] = stio->type = 'a';
	    name++;
	}
	else
	    mode[0] = 'w';
	writing = 1;
	if (*name == '&') {
	  duplicity:
	    name++;
	    while (isspace(*name))
		name++;
	    if (isdigit(*name))
		fd = atoi(name);
	    else {
		stab = stabent(name,FALSE);
		if (!stab || !stab_io(stab))
		    return FALSE;
		if (stab_io(stab) && stab_io(stab)->ifp) {
		    fd = fileno(stab_io(stab)->ifp);
		    if (stab_io(stab)->type == 's')
			stio->type = 's';
		}
		else
		    fd = -1;
	    }
	    fp = fdopen(dup(fd),mode);
	}
	else {
	    while (isspace(*name))
		name++;
	    if (strEQ(name,"-")) {
		fp = stdout;
		stio->type = '-';
	    }
	    else  {
		fp = fopen(name,mode);
	    }
	}
    }
    else {
	if (*name == '<') {
	    mode[0] = 'r';
	    name++;
	    while (isspace(*name))
		name++;
	    if (*name == '&')
		goto duplicity;
	    if (strEQ(name,"-")) {
		fp = stdin;
		stio->type = '-';
	    }
	    else
		fp = fopen(name,mode);
	}
	else if (name[len-1] == '|') {
#ifdef TAINT
	    taintenv();
	    taintproper("Insecure dependency in piped open");
#endif
	    name[--len] = '\0';
	    while (len && isspace(name[len-1]))
		name[--len] = '\0';
	    for (; isspace(*name); name++) ;
	    fp = mypopen(name,"r");
	    stio->type = '|';
	}
	else {
	    stio->type = '<';
	    for (; isspace(*name); name++) ;
	    if (strEQ(name,"-")) {
		fp = stdin;
		stio->type = '-';
	    }
	    else
		fp = fopen(name,"r");
	}
    }
    Safefree(myname);
    if (!fp)
	return FALSE;
    if (stio->type &&
      stio->type != '|' && stio->type != '-') {
	if (fstat(fileno(fp),&statbuf) < 0) {
	    (void)fclose(fp);
	    return FALSE;
	}
	result = (statbuf.st_mode & S_IFMT);
#ifdef S_IFSOCK
	if (result == S_IFSOCK || result == 0)
	    stio->type = 's';	/* in case a socket was passed in to us */
#endif
    }
#if defined(FCNTL) && defined(F_SETFD)
    fd = fileno(fp);
    fcntl(fd,F_SETFD,fd >= 3);
#endif
    stio->ifp = fp;
    if (writing) {
	if (stio->type != 's')
	    stio->ofp = fp;
	else
	    stio->ofp = fdopen(fileno(fp),"w");
    }
    return TRUE;
}

FILE *
nextargv(stab)
register STAB *stab;
{
    register STR *str;
    char *oldname;
    int filemode,fileuid,filegid;

    while (alen(stab_xarray(stab)) >= 0) {
	str = ashift(stab_xarray(stab));
	str_sset(stab_val(stab),str);
	STABSET(stab_val(stab));
	oldname = str_get(stab_val(stab));
	if (do_open(stab,oldname,stab_val(stab)->str_cur)) {
	    if (inplace) {
#ifdef TAINT
		taintproper("Insecure dependency in inplace open");
#endif
		filemode = statbuf.st_mode;
		fileuid = statbuf.st_uid;
		filegid = statbuf.st_gid;
		if (*inplace) {
#ifdef SUFFIX
		    add_suffix(str,inplace);
#else
		    str_cat(str,inplace);
#endif
#ifdef RENAME
#ifndef MSDOS
		    (void)rename(oldname,str->str_ptr);
#else
		    do_close(stab,FALSE);
		    (void)unlink(str->str_ptr);
		    (void)rename(oldname,str->str_ptr);
		    do_open(stab,str->str_ptr,stab_val(stab)->str_cur);
#endif /* MSDOS */
#else
		    (void)UNLINK(str->str_ptr);
		    (void)link(oldname,str->str_ptr);
		    (void)UNLINK(oldname);
#endif
		}
		else {
#ifndef MSDOS
		    (void)UNLINK(oldname);
#else
		    fatal("Can't do inplace edit without backup");
#endif
		}

		str_nset(str,">",1);
		str_cat(str,oldname);
		errno = 0;		/* in case sprintf set errno */
		if (!do_open(argvoutstab,str->str_ptr,str->str_cur))
		    fatal("Can't do inplace edit");
		defoutstab = argvoutstab;
#ifdef FCHMOD
		(void)fchmod(fileno(stab_io(argvoutstab)->ifp),filemode);
#else
		(void)chmod(oldname,filemode);
#endif
#ifdef FCHOWN
		(void)fchown(fileno(stab_io(argvoutstab)->ifp),fileuid,filegid);
#else
#ifdef CHOWN
		(void)chown(oldname,fileuid,filegid);
#endif
#endif
	    }
	    str_free(str);
	    return stab_io(stab)->ifp;
	}
	else
	    fprintf(stderr,"Can't open %s\n",str_get(str));
	str_free(str);
    }
    if (inplace) {
	(void)do_close(argvoutstab,FALSE);
	defoutstab = stabent("STDOUT",TRUE);
    }
    return Nullfp;
}

#ifdef PIPE
void
do_pipe(str, rstab, wstab)
STR *str;
STAB *rstab;
STAB *wstab;
{
    register STIO *rstio;
    register STIO *wstio;
    int fd[2];

    if (!rstab)
	goto badexit;
    if (!wstab)
	goto badexit;

    rstio = stab_io(rstab);
    wstio = stab_io(wstab);

    if (!rstio)
	rstio = stab_io(rstab) = stio_new();
    else if (rstio->ifp)
	do_close(rstab,FALSE);
    if (!wstio)
	wstio = stab_io(wstab) = stio_new();
    else if (wstio->ifp)
	do_close(wstab,FALSE);

    if (pipe(fd) < 0)
	goto badexit;
    rstio->ifp = fdopen(fd[0], "r");
    wstio->ofp = fdopen(fd[1], "w");
    wstio->ifp = wstio->ofp;
    rstio->type = '<';
    wstio->type = '>';

    str_sset(str,&str_yes);
    return;

badexit:
    str_sset(str,&str_undef);
    return;
}
#endif

bool
do_close(stab,explicit)
STAB *stab;
bool explicit;
{
    bool retval = FALSE;
    register STIO *stio;
    int status;

    if (!stab)
	stab = argvstab;
    if (!stab)
	return FALSE;
    stio = stab_io(stab);
    if (!stio) {		/* never opened */
	if (dowarn && explicit)
	    warn("Close on unopened file <%s>",stab_name(stab));
	return FALSE;
    }
    if (stio->ifp) {
	if (stio->type == '|') {
	    status = mypclose(stio->ifp);
	    retval = (status >= 0);
	    statusvalue = (unsigned short)status & 0xffff;
	}
	else if (stio->type == '-')
	    retval = TRUE;
	else {
	    if (stio->ofp && stio->ofp != stio->ifp) {		/* a socket */
		retval = (fclose(stio->ofp) != EOF);
		fclose(stio->ifp);	/* clear stdio, fd already closed */
	    }
	    else
		retval = (fclose(stio->ifp) != EOF);
	}
	stio->ofp = stio->ifp = Nullfp;
    }
    if (explicit)
	stio->lines = 0;
    stio->type = ' ';
    return retval;
}

bool
do_eof(stab)
STAB *stab;
{
    register STIO *stio;
    int ch;

    if (!stab) {			/* eof() */
	if (argvstab)
	    stio = stab_io(argvstab);
	else
	    return TRUE;
    }
    else
	stio = stab_io(stab);

    if (!stio)
	return TRUE;

    while (stio->ifp) {

#ifdef STDSTDIO			/* (the code works without this) */
	if (stio->ifp->_cnt > 0)	/* cheat a little, since */
	    return FALSE;		/* this is the most usual case */
#endif

	ch = getc(stio->ifp);
	if (ch != EOF) {
	    (void)ungetc(ch, stio->ifp);
	    return FALSE;
	}
	if (!stab) {			/* not necessarily a real EOF yet? */
	    if (!nextargv(argvstab))	/* get another fp handy */
		return TRUE;
	}
	else
	    return TRUE;		/* normal fp, definitely end of file */
    }
    return TRUE;
}

long
do_tell(stab)
STAB *stab;
{
    register STIO *stio;

    if (!stab)
	goto phooey;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto phooey;

    if (feof(stio->ifp))
	(void)fseek (stio->ifp, 0L, 2);		/* ultrix 1.2 workaround */

    return ftell(stio->ifp);

phooey:
    if (dowarn)
	warn("tell() on unopened file");
    return -1L;
}

bool
do_seek(stab, pos, whence)
STAB *stab;
long pos;
int whence;
{
    register STIO *stio;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    if (feof(stio->ifp))
	(void)fseek (stio->ifp, 0L, 2);		/* ultrix 1.2 workaround */

    return fseek(stio->ifp, pos, whence) >= 0;

nuts:
    if (dowarn)
	warn("seek() on unopened file");
    return FALSE;
}

int
do_ctl(optype,stab,func,argstr)
int optype;
STAB *stab;
int func;
STR *argstr;
{
    register STIO *stio;
    register char *s;
    int retval;

    if (!stab || !argstr)
	return -1;
    stio = stab_io(stab);
    if (!stio)
	return -1;

    if (argstr->str_pok || !argstr->str_nok) {
	if (!argstr->str_pok)
	    s = str_get(argstr);

#ifdef IOCPARM_MASK
#ifndef IOCPARM_LEN
#define IOCPARM_LEN(x)  (((x) >> 16) & IOCPARM_MASK)
#endif
#endif
#ifdef IOCPARM_LEN
	retval = IOCPARM_LEN(func);	/* on BSDish systes we're safe */
#else
	retval = 256;			/* otherwise guess at what's safe */
#endif
	if (argstr->str_cur < retval) {
	    Str_Grow(argstr,retval+1);
	    argstr->str_cur = retval;
	}

	s = argstr->str_ptr;
	s[argstr->str_cur] = 17;	/* a little sanity check here */
    }
    else {
	retval = (int)str_gnum(argstr);
#ifdef MSDOS
	s = (char*)(long)retval;		/* ouch */
#else
	s = (char*)retval;		/* ouch */
#endif
    }

#ifndef lint
    if (optype == O_IOCTL)
	retval = ioctl(fileno(stio->ifp), func, s);
    else
#ifdef I_FCNTL
	retval = fcntl(fileno(stio->ifp), func, s);
#else
	fatal("fcntl is not implemented");
#endif
#else /* lint */
    retval = 0;
#endif /* lint */

    if (argstr->str_pok) {
	if (s[argstr->str_cur] != 17)
	    fatal("Return value overflowed string");
	s[argstr->str_cur] = 0;		/* put our null back */
    }
    return retval;
}

int
do_stat(str,arg,gimme,arglast)
STR *str;
register ARG *arg;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    register int sp = arglast[0] + 1;
    int max = 13;
    register int i;

    if ((arg[1].arg_type & A_MASK) == A_WORD) {
	tmpstab = arg[1].arg_ptr.arg_stab;
	if (tmpstab != defstab) {
	    statstab = tmpstab;
	    str_set(statname,"");
	    if (!stab_io(tmpstab) || !stab_io(tmpstab)->ifp ||
	      fstat(fileno(stab_io(tmpstab)->ifp),&statcache) < 0) {
		max = 0;
	    }
	}
    }
    else {
	str_sset(statname,ary->ary_array[sp]);
	statstab = Nullstab;
#ifdef LSTAT
	if (arg->arg_type == O_LSTAT)
	    i = lstat(str_get(statname),&statcache);
	else
#endif
	    i = stat(str_get(statname),&statcache);
	if (i < 0)
	    max = 0;
    }

    if (gimme != G_ARRAY) {
	if (max)
	    str_sset(str,&str_yes);
	else
	    str_sset(str,&str_undef);
	STABSET(str);
	ary->ary_array[sp] = str;
	return sp;
    }
    sp--;
    if (max) {
#ifndef lint
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_dev)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_ino)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_mode)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_nlink)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_uid)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_gid)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_rdev)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_size)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_atime)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_mtime)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_ctime)));
#ifdef STATBLOCKS
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_blksize)));
	(void)astore(ary,++sp,
	  str_2static(str_nmake((double)statcache.st_blocks)));
#else
	(void)astore(ary,++sp,
	  str_2static(str_make("",0)));
	(void)astore(ary,++sp,
	  str_2static(str_make("",0)));
#endif
#else /* lint */
	(void)astore(ary,++sp,str_nmake(0.0));
#endif /* lint */
    }
    return sp;
}

#if !defined(TRUNCATE) && !defined(CHSIZE) && defined(F_FREESP)
	/* code courtesy of William Kucharski */
#define CHSIZE

int chsize(fd, length)
int fd;			/* file descriptor */
off_t length;		/* length to set file to */
{
    extern long lseek();
    struct flock fl;
    struct stat filebuf;

    if (fstat(fd, &filebuf) < 0)
	return -1;

    if (filebuf.st_size < length) {

	/* extend file length */

	if ((lseek(fd, (length - 1), 0)) < 0)
	    return -1;

	/* write a "0" byte */

	if ((write(fd, "", 1)) != 1)
	    return -1;
    }
    else {
	/* truncate length */

	fl.l_whence = 0;
	fl.l_len = 0;
	fl.l_start = length;
	fl.l_type = F_WRLCK;    /* write lock on file space */

	/*
	* This relies on the UNDOCUMENTED F_FREESP argument to
	* fcntl(2), which truncates the file so that it ends at the
	* position indicated by fl.l_start.
	*
	* Will minor miracles never cease?
	*/

	if (fcntl(fd, F_FREESP, &fl) < 0)
	    return -1;

    }

    return 0;
}
#endif /* F_FREESP */

int
do_truncate(str,arg,gimme,arglast)
STR *str;
register ARG *arg;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    register int sp = arglast[0] + 1;
    off_t len = (off_t)str_gnum(ary->ary_array[sp+1]);
    int result = 1;
    STAB *tmpstab;

#if defined(TRUNCATE) || defined(CHSIZE)
#ifdef TRUNCATE
    if ((arg[1].arg_type & A_MASK) == A_WORD) {
	tmpstab = arg[1].arg_ptr.arg_stab;
	if (!stab_io(tmpstab) ||
	  ftruncate(fileno(stab_io(tmpstab)->ifp), len) < 0)
	    result = 0;
    }
    else if (truncate(str_get(ary->ary_array[sp]), len) < 0)
	result = 0;
#else
    if ((arg[1].arg_type & A_MASK) == A_WORD) {
	tmpstab = arg[1].arg_ptr.arg_stab;
	if (!stab_io(tmpstab) ||
	  chsize(fileno(stab_io(tmpstab)->ifp), len) < 0)
	    result = 0;
    }
    else {
	int tmpfd;

	if ((tmpfd = open(str_get(ary->ary_array[sp]), 0)) < 0)
	    result = 0;
	else {
	    if (chsize(tmpfd, len) < 0)
		result = 0;
	    close(tmpfd);
	}
    }
#endif

    if (result)
	str_sset(str,&str_yes);
    else
	str_sset(str,&str_undef);
    STABSET(str);
    ary->ary_array[sp] = str;
    return sp;
#else
    fatal("truncate not implemented");
#endif
}

int
looks_like_number(str)
STR *str;
{
    register char *s;
    register char *send;

    if (!str->str_pok)
	return TRUE;
    s = str->str_ptr; 
    send = s + str->str_cur;
    while (isspace(*s))
	s++;
    if (s >= send)
	return FALSE;
    if (*s == '+' || *s == '-')
	s++;
    while (isdigit(*s))
	s++;
    if (s == send)
	return TRUE;
    if (*s == '.') 
	s++;
    else if (s == str->str_ptr)
	return FALSE;
    while (isdigit(*s))
	s++;
    if (s == send)
	return TRUE;
    if (*s == 'e' || *s == 'E') {
	s++;
	if (*s == '+' || *s == '-')
	    s++;
	while (isdigit(*s))
	    s++;
    }
    while (isspace(*s))
	s++;
    if (s >= send)
	return TRUE;
    return FALSE;
}

bool
do_print(str,fp)
register STR *str;
FILE *fp;
{
    register char *tmps;

    if (!fp) {
	if (dowarn)
	    warn("print to unopened file");
	return FALSE;
    }
    if (!str)
	return TRUE;
    if (ofmt &&
      ((str->str_nok && str->str_u.str_nval != 0.0)
       || (looks_like_number(str) && str_gnum(str) != 0.0) ) ) {
	fprintf(fp, ofmt, str->str_u.str_nval);
	return !ferror(fp);
    }
    else {
	tmps = str_get(str);
	if (*tmps == 'S' && tmps[1] == 't' && tmps[2] == 'B' && tmps[3] == '\0'
	  && str->str_cur == sizeof(STBP) && strlen(tmps) < str->str_cur) {
	    STR *tmpstr = str_static(&str_undef);
	    stab_fullname(tmpstr,((STAB*)str));/* a stab value, be nice */
	    str = tmpstr;
	    tmps = str->str_ptr;
	    putc('*',fp);
	}
	if (str->str_cur && (fwrite(tmps,1,str->str_cur,fp) == 0 || ferror(fp)))
	    return FALSE;
    }
    return TRUE;
}

bool
do_aprint(arg,fp,arglast)
register ARG *arg;
register FILE *fp;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int retval;
    register int items = arglast[2] - sp;

    if (!fp) {
	if (dowarn)
	    warn("print to unopened file");
	return FALSE;
    }
    st += ++sp;
    if (arg->arg_type == O_PRTF) {
	do_sprintf(arg->arg_ptr.arg_str,items,st);
	retval = do_print(arg->arg_ptr.arg_str,fp);
    }
    else {
	retval = (items <= 0);
	for (; items > 0; items--,st++) {
	    if (retval && ofslen) {
		if (fwrite(ofs, 1, ofslen, fp) == 0 || ferror(fp)) {
		    retval = FALSE;
		    break;
		}
	    }
	    if (!(retval = do_print(*st, fp)))
		break;
	}
	if (retval && orslen)
	    if (fwrite(ors, 1, orslen, fp) == 0 || ferror(fp))
		retval = FALSE;
    }
    return retval;
}

int
mystat(arg,str)
ARG *arg;
STR *str;
{
    STIO *stio;

    if (arg[1].arg_type & A_DONT) {
	stio = stab_io(arg[1].arg_ptr.arg_stab);
	if (stio && stio->ifp) {
	    statstab = arg[1].arg_ptr.arg_stab;
	    str_set(statname,"");
	    return fstat(fileno(stio->ifp), &statcache);
	}
	else {
	    if (arg[1].arg_ptr.arg_stab == defstab)
		return 0;
	    if (dowarn)
		warn("Stat on unopened file <%s>",
		  stab_name(arg[1].arg_ptr.arg_stab));
	    statstab = Nullstab;
	    str_set(statname,"");
	    return -1;
	}
    }
    else {
	statstab = Nullstab;
	str_sset(statname,str);
	return stat(str_get(str),&statcache);
    }
}

STR *
do_fttext(arg,str)
register ARG *arg;
STR *str;
{
    int i;
    int len;
    int odd = 0;
    STDCHAR tbuf[512];
    register STDCHAR *s;
    register STIO *stio;

    if (arg[1].arg_type & A_DONT) {
	if (arg[1].arg_ptr.arg_stab == defstab) {
	    if (statstab)
		stio = stab_io(statstab);
	    else {
		str = statname;
		goto really_filename;
	    }
	}
	else {
	    statstab = arg[1].arg_ptr.arg_stab;
	    str_set(statname,"");
	    stio = stab_io(statstab);
	}
	if (stio && stio->ifp) {
#ifdef STDSTDIO
	    fstat(fileno(stio->ifp),&statcache);
	    if (stio->ifp->_cnt <= 0) {
		i = getc(stio->ifp);
		if (i != EOF)
		    (void)ungetc(i,stio->ifp);
	    }
	    if (stio->ifp->_cnt <= 0)	/* null file is anything */
		return &str_yes;
	    len = stio->ifp->_cnt + (stio->ifp->_ptr - stio->ifp->_base);
	    s = stio->ifp->_base;
#else
	    fatal("-T and -B not implemented on filehandles\n");
#endif
	}
	else {
	    if (dowarn)
		warn("Test on unopened file <%s>",
		  stab_name(arg[1].arg_ptr.arg_stab));
	    return &str_undef;
	}
    }
    else {
	statstab = Nullstab;
	str_sset(statname,str);
      really_filename:
	i = open(str_get(str),0);
	if (i < 0)
	    return &str_undef;
	fstat(i,&statcache);
	len = read(i,tbuf,512);
	if (len <= 0)		/* null file is anything */
	    return &str_yes;
	(void)close(i);
	s = tbuf;
    }

    /* now scan s to look for textiness */

    for (i = 0; i < len; i++,s++) {
	if (!*s) {			/* null never allowed in text */
	    odd += len;
	    break;
	}
	else if (*s & 128)
	    odd++;
	else if (*s < 32 &&
	  *s != '\n' && *s != '\r' && *s != '\b' &&
	  *s != '\t' && *s != '\f' && *s != 27)
	    odd++;
    }

    if ((odd * 10 > len) == (arg->arg_type == O_FTTEXT)) /* allow 10% odd */
	return &str_no;
    else
	return &str_yes;
}

bool
do_aexec(really,arglast)
STR *really;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register char **a;
    char **argv;
    char *tmps;

    if (items) {
	New(401,argv, items+1, char*);
	a = argv;
	for (st += ++sp; items > 0; items--,st++) {
	    if (*st)
		*a++ = str_get(*st);
	    else
		*a++ = "";
	}
	*a = Nullch;
#ifdef TAINT
	if (*argv[0] != '/')	/* will execvp use PATH? */
	    taintenv();		/* testing IFS here is overkill, probably */
#endif
	if (really && *(tmps = str_get(really)))
	    execvp(tmps,argv);
	else
	    execvp(argv[0],argv);
	Safefree(argv);
    }
    return FALSE;
}

static char **Argv = Null(char **);
static char *Cmd = Nullch;

int
do_execfree()
{
    if (Argv) {
	Safefree(Argv);
	Argv = Null(char **);
    }
    if (Cmd) {
	Safefree(Cmd);
	Cmd = Nullch;
    }
}

bool
do_exec(cmd)
char *cmd;
{
    register char **a;
    register char *s;
    char flags[10];

#ifdef TAINT
    taintenv();
    taintproper("Insecure dependency in exec");
#endif

    /* save an extra exec if possible */

#ifdef CSH
    if (strnEQ(cmd,cshname,cshlen) && strnEQ(cmd+cshlen," -c",3)) {
	strcpy(flags,"-c");
	s = cmd+cshlen+3;
	if (*s == 'f') {
	    s++;
	    strcat(flags,"f");
	}
	if (*s == ' ')
	    s++;
	if (*s++ == '\'') {
	    char *ncmd = s;

	    while (*s)
		s++;
	    if (s[-1] == '\n')
		*--s = '\0';
	    if (s[-1] == '\'') {
		*--s = '\0';
		execl(cshname,"csh", flags,ncmd,(char*)0);
		*s = '\'';
		return FALSE;
	    }
	}
    }
#endif /* CSH */

    /* see if there are shell metacharacters in it */

    for (s = cmd; *s && isalpha(*s); s++) ;	/* catch VAR=val gizmo */
    if (*s == '=')
	goto doshell;
    for (s = cmd; *s; s++) {
	if (*s != ' ' && !isalpha(*s) && index("$&*(){}[]'\";\\|?<>~`\n",*s)) {
	    if (*s == '\n' && !s[1]) {
		*s = '\0';
		break;
	    }
	  doshell:
	    execl("/bin/sh","sh","-c",cmd,(char*)0);
	    return FALSE;
	}
    }
    New(402,Argv, (s - cmd) / 2 + 2, char*);
    Cmd = nsavestr(cmd, s-cmd);
    a = Argv;
    for (s = Cmd; *s;) {
	while (*s && isspace(*s)) s++;
	if (*s)
	    *(a++) = s;
	while (*s && !isspace(*s)) s++;
	if (*s)
	    *s++ = '\0';
    }
    *a = Nullch;
    if (Argv[0]) {
	execvp(Argv[0],Argv);
	if (errno == ENOEXEC) {		/* for system V NIH syndrome */
	    do_execfree();
	    goto doshell;
	}
    }
    do_execfree();
    return FALSE;
}

#ifdef SOCKET
int
do_socket(stab, arglast)
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    int domain, type, protocol, fd;

    if (!stab)
	return FALSE;

    stio = stab_io(stab);
    if (!stio)
	stio = stab_io(stab) = stio_new();
    else if (stio->ifp)
	do_close(stab,FALSE);

    domain = (int)str_gnum(st[++sp]);
    type = (int)str_gnum(st[++sp]);
    protocol = (int)str_gnum(st[++sp]);
#ifdef TAINT
    taintproper("Insecure dependency in socket");
#endif
    fd = socket(domain,type,protocol);
    if (fd < 0)
	return FALSE;
    stio->ifp = fdopen(fd, "r");	/* stdio gets confused about sockets */
    stio->ofp = fdopen(fd, "w");
    stio->type = 's';

    return TRUE;
}

int
do_bind(stab, arglast)
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    char *addr;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    addr = str_get(st[++sp]);
#ifdef TAINT
    taintproper("Insecure dependency in bind");
#endif
    return bind(fileno(stio->ifp), addr, st[sp]->str_cur) >= 0;

nuts:
    if (dowarn)
	warn("bind() on closed fd");
    return FALSE;

}

int
do_connect(stab, arglast)
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    char *addr;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    addr = str_get(st[++sp]);
#ifdef TAINT
    taintproper("Insecure dependency in connect");
#endif
    return connect(fileno(stio->ifp), addr, st[sp]->str_cur) >= 0;

nuts:
    if (dowarn)
	warn("connect() on closed fd");
    return FALSE;

}

int
do_listen(stab, arglast)
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    int backlog;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    backlog = (int)str_gnum(st[++sp]);
    return listen(fileno(stio->ifp), backlog) >= 0;

nuts:
    if (dowarn)
	warn("listen() on closed fd");
    return FALSE;
}

void
do_accept(str, nstab, gstab)
STR *str;
STAB *nstab;
STAB *gstab;
{
    register STIO *nstio;
    register STIO *gstio;
    int len = sizeof buf;
    int fd;

    if (!nstab)
	goto badexit;
    if (!gstab)
	goto nuts;

    gstio = stab_io(gstab);
    nstio = stab_io(nstab);

    if (!gstio || !gstio->ifp)
	goto nuts;
    if (!nstio)
	nstio = stab_io(nstab) = stio_new();
    else if (nstio->ifp)
	do_close(nstab,FALSE);

    fd = accept(fileno(gstio->ifp),buf,&len);
    if (fd < 0)
	goto badexit;
    nstio->ifp = fdopen(fd, "r");
    nstio->ofp = fdopen(fd, "w");
    nstio->type = 's';

    str_nset(str, buf, len);
    return;

nuts:
    if (dowarn)
	warn("accept() on closed fd");
badexit:
    str_sset(str,&str_undef);
    return;
}

int
do_shutdown(stab, arglast)
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    int how;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    how = (int)str_gnum(st[++sp]);
    return shutdown(fileno(stio->ifp), how) >= 0;

nuts:
    if (dowarn)
	warn("shutdown() on closed fd");
    return FALSE;

}

int
do_sopt(optype, stab, arglast)
int optype;
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    int fd;
    int lvl;
    int optname;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    fd = fileno(stio->ifp);
    lvl = (int)str_gnum(st[sp+1]);
    optname = (int)str_gnum(st[sp+2]);
    switch (optype) {
    case O_GSOCKOPT:
	st[sp] = str_2static(str_new(257));
	st[sp]->str_cur = 256;
	st[sp]->str_pok = 1;
	if (getsockopt(fd, lvl, optname, st[sp]->str_ptr, &st[sp]->str_cur) < 0)
	    goto nuts;
	break;
    case O_SSOCKOPT:
	st[sp] = st[sp+3];
	if (setsockopt(fd, lvl, optname, st[sp]->str_ptr, st[sp]->str_cur) < 0)
	    goto nuts;
	st[sp] = &str_yes;
	break;
    }
    
    return sp;

nuts:
    if (dowarn)
	warn("[gs]etsockopt() on closed fd");
    st[sp] = &str_undef;
    return sp;

}

int
do_getsockname(optype, stab, arglast)
int optype;
STAB *stab;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    int fd;

    if (!stab)
	goto nuts;

    stio = stab_io(stab);
    if (!stio || !stio->ifp)
	goto nuts;

    st[sp] = str_2static(str_new(257));
    st[sp]->str_cur = 256;
    st[sp]->str_pok = 1;
    fd = fileno(stio->ifp);
    switch (optype) {
    case O_GETSOCKNAME:
	if (getsockname(fd, st[sp]->str_ptr, &st[sp]->str_cur) < 0)
	    goto nuts2;
	break;
    case O_GETPEERNAME:
	if (getpeername(fd, st[sp]->str_ptr, &st[sp]->str_cur) < 0)
	    goto nuts2;
	break;
    }
    
    return sp;

nuts:
    if (dowarn)
	warn("get{sock,peer}name() on closed fd");
nuts2:
    st[sp] = &str_undef;
    return sp;

}

int
do_ghent(which,gimme,arglast)
int which;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    register int sp = arglast[0];
    register char **elem;
    register STR *str;
    struct hostent *gethostbyname();
    struct hostent *gethostbyaddr();
#ifdef GETHOSTENT
    struct hostent *gethostent();
#endif
    struct hostent *hent;
    unsigned long len;

    if (gimme != G_ARRAY) {
	astore(ary, ++sp, str_static(&str_undef));
	return sp;
    }

    if (which == O_GHBYNAME) {
	char *name = str_get(ary->ary_array[sp+1]);

	hent = gethostbyname(name);
    }
    else if (which == O_GHBYADDR) {
	STR *addrstr = ary->ary_array[sp+1];
	int addrtype = (int)str_gnum(ary->ary_array[sp+2]);
	char *addr = str_get(addrstr);

	hent = gethostbyaddr(addr,addrstr->str_cur,addrtype);
    }
    else
#ifdef GETHOSTENT
	hent = gethostent();
#else
	fatal("gethostent not implemented");
#endif
    if (hent) {
#ifndef lint
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, hent->h_name);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	for (elem = hent->h_aliases; *elem; elem++) {
	    str_cat(str, *elem);
	    if (elem[1])
		str_ncat(str," ",1);
	}
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)hent->h_addrtype);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	len = hent->h_length;
	str_numset(str, (double)len);
#ifdef h_addr
	for (elem = hent->h_addr_list; *elem; elem++) {
	    (void)astore(ary, ++sp, str = str_static(&str_no));
	    str_nset(str, *elem, len);
	}
#else
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_nset(str, hent->h_addr, len);
#endif /* h_addr */
#else /* lint */
	elem = Nullch;
	elem = elem;
	(void)astore(ary, ++sp, str_static(&str_no));
#endif /* lint */
    }

    return sp;
}

int
do_gnent(which,gimme,arglast)
int which;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    register int sp = arglast[0];
    register char **elem;
    register STR *str;
    struct netent *getnetbyname();
    struct netent *getnetbyaddr();
    struct netent *getnetent();
    struct netent *nent;

    if (gimme != G_ARRAY) {
	astore(ary, ++sp, str_static(&str_undef));
	return sp;
    }

    if (which == O_GNBYNAME) {
	char *name = str_get(ary->ary_array[sp+1]);

	nent = getnetbyname(name);
    }
    else if (which == O_GNBYADDR) {
	STR *addrstr = ary->ary_array[sp+1];
	int addrtype = (int)str_gnum(ary->ary_array[sp+2]);
	char *addr = str_get(addrstr);

	nent = getnetbyaddr(addr,addrtype);
    }
    else
	nent = getnetent();

    if (nent) {
#ifndef lint
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, nent->n_name);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	for (elem = nent->n_aliases; *elem; elem++) {
	    str_cat(str, *elem);
	    if (elem[1])
		str_ncat(str," ",1);
	}
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)nent->n_addrtype);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)nent->n_net);
#else /* lint */
	elem = Nullch;
	elem = elem;
	(void)astore(ary, ++sp, str_static(&str_no));
#endif /* lint */
    }

    return sp;
}

int
do_gpent(which,gimme,arglast)
int which;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    register int sp = arglast[0];
    register char **elem;
    register STR *str;
    struct protoent *getprotobyname();
    struct protoent *getprotobynumber();
    struct protoent *getprotoent();
    struct protoent *pent;

    if (gimme != G_ARRAY) {
	astore(ary, ++sp, str_static(&str_undef));
	return sp;
    }

    if (which == O_GPBYNAME) {
	char *name = str_get(ary->ary_array[sp+1]);

	pent = getprotobyname(name);
    }
    else if (which == O_GPBYNUMBER) {
	int proto = (int)str_gnum(ary->ary_array[sp+1]);

	pent = getprotobynumber(proto);
    }
    else
	pent = getprotoent();

    if (pent) {
#ifndef lint
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, pent->p_name);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	for (elem = pent->p_aliases; *elem; elem++) {
	    str_cat(str, *elem);
	    if (elem[1])
		str_ncat(str," ",1);
	}
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)pent->p_proto);
#else /* lint */
	elem = Nullch;
	elem = elem;
	(void)astore(ary, ++sp, str_static(&str_no));
#endif /* lint */
    }

    return sp;
}

int
do_gsent(which,gimme,arglast)
int which;
int gimme;
int *arglast;
{
    register ARRAY *ary = stack;
    register int sp = arglast[0];
    register char **elem;
    register STR *str;
    struct servent *getservbyname();
    struct servent *getservbynumber();
    struct servent *getservent();
    struct servent *sent;

    if (gimme != G_ARRAY) {
	astore(ary, ++sp, str_static(&str_undef));
	return sp;
    }

    if (which == O_GSBYNAME) {
	char *name = str_get(ary->ary_array[sp+1]);
	char *proto = str_get(ary->ary_array[sp+2]);

	if (proto && !*proto)
	    proto = Nullch;

	sent = getservbyname(name,proto);
    }
    else if (which == O_GSBYPORT) {
	int port = (int)str_gnum(ary->ary_array[sp+1]);
	char *proto = str_get(ary->ary_array[sp+2]);

	sent = getservbyport(port,proto);
    }
    else
	sent = getservent();
    if (sent) {
#ifndef lint
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, sent->s_name);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	for (elem = sent->s_aliases; *elem; elem++) {
	    str_cat(str, *elem);
	    if (elem[1])
		str_ncat(str," ",1);
	}
	(void)astore(ary, ++sp, str = str_static(&str_no));
#ifdef NTOHS
	str_numset(str, (double)ntohs(sent->s_port));
#else
	str_numset(str, (double)(sent->s_port));
#endif
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, sent->s_proto);
#else /* lint */
	elem = Nullch;
	elem = elem;
	(void)astore(ary, ++sp, str_static(&str_no));
#endif /* lint */
    }

    return sp;
}

#endif /* SOCKET */

#ifdef SELECT
int
do_select(gimme,arglast)
int gimme;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    register int i;
    register int j;
    register char *s;
    register STR *str;
    double value;
    int maxlen = 0;
    int nfound;
    struct timeval timebuf;
    struct timeval *tbuf = &timebuf;
    int growsize;
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
    int masksize;
    int offset;
    char *fd_sets[4];
    int k;

#if BYTEORDER & 0xf0000
#define ORDERBYTE (0x88888888 - BYTEORDER)
#else
#define ORDERBYTE (0x4444 - BYTEORDER)
#endif

#endif

    for (i = 1; i <= 3; i++) {
	j = st[sp+i]->str_cur;
	if (maxlen < j)
	    maxlen = j;
    }

#if BYTEORDER == 0x1234 || BYTEORDER == 0x12345678
    growsize = maxlen;		/* little endians can use vecs directly */
#else
#ifdef NFDBITS

#ifndef NBBY
#define NBBY 8
#endif

    masksize = NFDBITS / NBBY;
#else
    masksize = sizeof(long);	/* documented int, everyone seems to use long */
#endif
    growsize = maxlen + (masksize - (maxlen % masksize));
    Zero(&fd_sets[0], 4, char*);
#endif

    for (i = 1; i <= 3; i++) {
	str = st[sp+i];
	j = str->str_len;
	if (j < growsize) {
	    if (str->str_pok) {
		Str_Grow(str,growsize);
		s = str_get(str) + j;
		while (++j <= growsize) {
		    *s++ = '\0';
		}
	    }
	    else if (str->str_ptr) {
		Safefree(str->str_ptr);
		str->str_ptr = Nullch;
	    }
	}
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
	s = str->str_ptr;
	if (s) {
	    New(403, fd_sets[i], growsize, char);
	    for (offset = 0; offset < growsize; offset += masksize) {
		for (j = 0, k=ORDERBYTE; j < masksize; j++, (k >>= 4))
		    fd_sets[i][j+offset] = s[(k % masksize) + offset];
	    }
	}
#endif
    }
    str = st[sp+4];
    if (str->str_nok || str->str_pok) {
	value = str_gnum(str);
	if (value < 0.0)
	    value = 0.0;
	timebuf.tv_sec = (long)value;
	value -= (double)timebuf.tv_sec;
	timebuf.tv_usec = (long)(value * 1000000.0);
    }
    else
	tbuf = Null(struct timeval*);

#if BYTEORDER == 0x1234 || BYTEORDER == 0x12345678
    nfound = select(
	maxlen * 8,
	st[sp+1]->str_ptr,
	st[sp+2]->str_ptr,
	st[sp+3]->str_ptr,
	tbuf);
#else
    nfound = select(
	maxlen * 8,
	fd_sets[1],
	fd_sets[2],
	fd_sets[3],
	tbuf);
    for (i = 1; i <= 3; i++) {
	if (fd_sets[i]) {
	    str = st[sp+i];
	    s = str->str_ptr;
	    for (offset = 0; offset < growsize; offset += masksize) {
		for (j = 0, k=ORDERBYTE; j < masksize; j++, (k >>= 4))
		    s[(k % masksize) + offset] = fd_sets[i][j+offset];
	    }
	}
    }
#endif

    st[++sp] = str_static(&str_no);
    str_numset(st[sp], (double)nfound);
    if (gimme == G_ARRAY && tbuf) {
	value = (double)(timebuf.tv_sec) +
		(double)(timebuf.tv_usec) / 1000000.0;
	st[++sp] = str_static(&str_no);
	str_numset(st[sp], value);
    }
    return sp;
}
#endif /* SELECT */

#ifdef SOCKET
int
do_spair(stab1, stab2, arglast)
STAB *stab1;
STAB *stab2;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[2];
    register STIO *stio1;
    register STIO *stio2;
    int domain, type, protocol, fd[2];

    if (!stab1 || !stab2)
	return FALSE;

    stio1 = stab_io(stab1);
    stio2 = stab_io(stab2);
    if (!stio1)
	stio1 = stab_io(stab1) = stio_new();
    else if (stio1->ifp)
	do_close(stab1,FALSE);
    if (!stio2)
	stio2 = stab_io(stab2) = stio_new();
    else if (stio2->ifp)
	do_close(stab2,FALSE);

    domain = (int)str_gnum(st[++sp]);
    type = (int)str_gnum(st[++sp]);
    protocol = (int)str_gnum(st[++sp]);
#ifdef TAINT
    taintproper("Insecure dependency in socketpair");
#endif
#ifdef SOCKETPAIR
    if (socketpair(domain,type,protocol,fd) < 0)
	return FALSE;
#else
    fatal("Socketpair unimplemented");
#endif
    stio1->ifp = fdopen(fd[0], "r");
    stio1->ofp = fdopen(fd[0], "w");
    stio1->type = 's';
    stio2->ifp = fdopen(fd[1], "r");
    stio2->ofp = fdopen(fd[1], "w");
    stio2->type = 's';

    return TRUE;
}

#endif /* SOCKET */

int
do_gpwent(which,gimme,arglast)
int which;
int gimme;
int *arglast;
{
#ifdef I_PWD
    register ARRAY *ary = stack;
    register int sp = arglast[0];
    register STR *str;
    struct passwd *getpwnam();
    struct passwd *getpwuid();
    struct passwd *getpwent();
    struct passwd *pwent;

    if (gimme != G_ARRAY) {
	astore(ary, ++sp, str_static(&str_undef));
	return sp;
    }

    if (which == O_GPWNAM) {
	char *name = str_get(ary->ary_array[sp+1]);

	pwent = getpwnam(name);
    }
    else if (which == O_GPWUID) {
	int uid = (int)str_gnum(ary->ary_array[sp+1]);

	pwent = getpwuid(uid);
    }
    else
	pwent = getpwent();

    if (pwent) {
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, pwent->pw_name);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, pwent->pw_passwd);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)pwent->pw_uid);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)pwent->pw_gid);
	(void)astore(ary, ++sp, str = str_static(&str_no));
#ifdef PWCHANGE
	str_numset(str, (double)pwent->pw_change);
#else
#ifdef PWQUOTA
	str_numset(str, (double)pwent->pw_quota);
#else
#ifdef PWAGE
	str_set(str, pwent->pw_age);
#endif
#endif
#endif
	(void)astore(ary, ++sp, str = str_static(&str_no));
#ifdef PWCLASS
	str_set(str,pwent->pw_class);
#else
#ifdef PWCOMMENT
	str_set(str, pwent->pw_comment);
#endif
#endif
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, pwent->pw_gecos);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, pwent->pw_dir);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, pwent->pw_shell);
#ifdef PWEXPIRE
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)pwent->pw_expire);
#endif
    }

    return sp;
#else
    fatal("password routines not implemented");
#endif
}

int
do_ggrent(which,gimme,arglast)
int which;
int gimme;
int *arglast;
{
#ifdef I_GRP
    register ARRAY *ary = stack;
    register int sp = arglast[0];
    register char **elem;
    register STR *str;
    struct group *getgrnam();
    struct group *getgrgid();
    struct group *getgrent();
    struct group *grent;

    if (gimme != G_ARRAY) {
	astore(ary, ++sp, str_static(&str_undef));
	return sp;
    }

    if (which == O_GGRNAM) {
	char *name = str_get(ary->ary_array[sp+1]);

	grent = getgrnam(name);
    }
    else if (which == O_GGRGID) {
	int gid = (int)str_gnum(ary->ary_array[sp+1]);

	grent = getgrgid(gid);
    }
    else
	grent = getgrent();

    if (grent) {
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, grent->gr_name);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_set(str, grent->gr_passwd);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	str_numset(str, (double)grent->gr_gid);
	(void)astore(ary, ++sp, str = str_static(&str_no));
	for (elem = grent->gr_mem; *elem; elem++) {
	    str_cat(str, *elem);
	    if (elem[1])
		str_ncat(str," ",1);
	}
    }

    return sp;
#else
    fatal("group routines not implemented");
#endif
}

int
do_dirop(optype,stab,gimme,arglast)
int optype;
STAB *stab;
int gimme;
int *arglast;
{
#if defined(DIRENT) && defined(READDIR)
    register ARRAY *ary = stack;
    register STR **st = ary->ary_array;
    register int sp = arglast[1];
    register STIO *stio;
    long along;
#ifndef telldir
    long telldir();
#endif
    struct DIRENT *readdir();
    register struct DIRENT *dp;

    if (!stab)
	goto nope;
    if (!(stio = stab_io(stab)))
	stio = stab_io(stab) = stio_new();
    if (!stio->dirp && optype != O_OPENDIR)
	goto nope;
    st[sp] = &str_yes;
    switch (optype) {
    case O_OPENDIR:
	if (stio->dirp)
	    closedir(stio->dirp);
	if (!(stio->dirp = opendir(str_get(st[sp+1]))))
	    goto nope;
	break;
    case O_READDIR:
	if (gimme == G_ARRAY) {
	    --sp;
	    while (dp = readdir(stio->dirp)) {
#ifdef DIRNAMLEN
		(void)astore(ary,++sp,
		  str_2static(str_make(dp->d_name,dp->d_namlen)));
#else
		(void)astore(ary,++sp,
		  str_2static(str_make(dp->d_name,0)));
#endif
	    }
	}
	else {
	    if (!(dp = readdir(stio->dirp)))
		goto nope;
	    st[sp] = str_static(&str_undef);
#ifdef DIRNAMLEN
	    str_nset(st[sp], dp->d_name, dp->d_namlen);
#else
	    str_set(st[sp], dp->d_name);
#endif
	}
	break;
#if MACH
    case O_TELLDIR:
    case O_SEEKDIR:
        goto nope;
#else
    case O_TELLDIR:
	st[sp] = str_static(&str_undef);
	str_numset(st[sp], (double)telldir(stio->dirp));
	break;
    case O_SEEKDIR:
	st[sp] = str_static(&str_undef);
	along = (long)str_gnum(st[sp+1]);
	(void)seekdir(stio->dirp,along);
	break;
#endif
    case O_REWINDDIR:
	st[sp] = str_static(&str_undef);
	(void)rewinddir(stio->dirp);
	break;
    case O_CLOSEDIR:
	st[sp] = str_static(&str_undef);
	(void)closedir(stio->dirp);
	stio->dirp = 0;
	break;
    }
    return sp;

nope:
    st[sp] = &str_undef;
    return sp;

#else
    fatal("Unimplemented directory operation");
#endif
}

apply(type,arglast)
int type;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[1];
    register int items = arglast[2] - sp;
    register int val;
    register int val2;
    register int tot = 0;
    char *s;

#ifdef TAINT
    for (st += ++sp; items--; st++)
	tainted |= (*st)->str_tainted;
    st = stack->ary_array;
    sp = arglast[1];
    items = arglast[2] - sp;
#endif
    switch (type) {
    case O_CHMOD:
#ifdef TAINT
	taintproper("Insecure dependency in chmod");
#endif
	if (--items > 0) {
	    tot = items;
	    val = (int)str_gnum(st[++sp]);
	    while (items--) {
		if (chmod(str_get(st[++sp]),val))
		    tot--;
	    }
	}
	break;
#ifdef CHOWN
    case O_CHOWN:
#ifdef TAINT
	taintproper("Insecure dependency in chown");
#endif
	if (items > 2) {
	    items -= 2;
	    tot = items;
	    val = (int)str_gnum(st[++sp]);
	    val2 = (int)str_gnum(st[++sp]);
	    while (items--) {
		if (chown(str_get(st[++sp]),val,val2))
		    tot--;
	    }
	}
	break;
#endif
#ifdef KILL
    case O_KILL:
#ifdef TAINT
	taintproper("Insecure dependency in kill");
#endif
	if (--items > 0) {
	    tot = items;
	    s = str_get(st[++sp]);
	    if (isupper(*s)) {
		if (*s == 'S' && s[1] == 'I' && s[2] == 'G')
		    s += 3;
		if (!(val = whichsig(s)))
		    fatal("Unrecognized signal name \"%s\"",s);
	    }
	    else
		val = (int)str_gnum(st[sp]);
	    if (val < 0) {
		val = -val;
		while (items--) {
		    int proc = (int)str_gnum(st[++sp]);
#ifdef KILLPG
		    if (killpg(proc,val))	/* BSD */
#else
		    if (kill(-proc,val))	/* SYSV */
#endif
			tot--;
		}
	    }
	    else {
		while (items--) {
		    if (kill((int)(str_gnum(st[++sp])),val))
			tot--;
		}
	    }
	}
	break;
#endif
    case O_UNLINK:
#ifdef TAINT
	taintproper("Insecure dependency in unlink");
#endif
	tot = items;
	while (items--) {
	    s = str_get(st[++sp]);
	    if (euid || unsafe) {
		if (UNLINK(s))
		    tot--;
	    }
	    else {	/* don't let root wipe out directories without -U */
#ifdef LSTAT
		if (lstat(s,&statbuf) < 0 ||
#else
		if (stat(s,&statbuf) < 0 ||
#endif
		  (statbuf.st_mode & S_IFMT) == S_IFDIR )
		    tot--;
		else {
		    if (UNLINK(s))
			tot--;
		}
	    }
	}
	break;
    case O_UTIME:
#ifdef TAINT
	taintproper("Insecure dependency in utime");
#endif
	if (items > 2) {
#ifdef I_UTIME
	    struct utimbuf utbuf;
#else
	    struct {
		long    actime;
		long	modtime;
	    } utbuf;
#endif

	    Zero(&utbuf, sizeof utbuf, char);
	    utbuf.actime = (long)str_gnum(st[++sp]);    /* time accessed */
	    utbuf.modtime = (long)str_gnum(st[++sp]);    /* time modified */
	    items -= 2;
#ifndef lint
	    tot = items;
	    while (items--) {
		if (utime(str_get(st[++sp]),&utbuf))
		    tot--;
	    }
#endif
	}
	else
	    items = 0;
	break;
    }
    return tot;
}

/* Do the permissions allow some operation?  Assumes statcache already set. */

int
cando(bit, effective, statbufp)
int bit;
int effective;
register struct stat *statbufp;
{
    if ((effective ? euid : uid) == 0) {	/* root is special */
	if (bit == S_IEXEC) {
	    if (statbufp->st_mode & 0111 ||
	      (statbufp->st_mode & S_IFMT) == S_IFDIR )
		return TRUE;
	}
	else
	    return TRUE;		/* root reads and writes anything */
	return FALSE;
    }
    if (statbufp->st_uid == (effective ? euid : uid) ) {
	if (statbufp->st_mode & bit)
	    return TRUE;	/* ok as "user" */
    }
    else if (ingroup((int)statbufp->st_gid,effective)) {
	if (statbufp->st_mode & bit >> 3)
	    return TRUE;	/* ok as "group" */
    }
    else if (statbufp->st_mode & bit >> 6)
	return TRUE;	/* ok as "other" */
    return FALSE;
}

int
ingroup(testgid,effective)
int testgid;
int effective;
{
    if (testgid == (effective ? egid : gid))
	return TRUE;
#ifdef GETGROUPS
#ifndef NGROUPS
#define NGROUPS 32
#endif
    {
	GIDTYPE gary[NGROUPS];
	int anum;

	anum = getgroups(NGROUPS,gary);
	while (--anum >= 0)
	    if (gary[anum] == testgid)
		return TRUE;
    }
#endif
    return FALSE;
}

#ifdef SYSVIPC

int
do_ipcget(optype, arglast)
int optype;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    key_t key;
    int n, flags;

    key = (key_t)str_gnum(st[++sp]);
    n = (optype == O_MSGGET) ? 0 : (int)str_gnum(st[++sp]);
    flags = (int)str_gnum(st[++sp]);
    errno = 0;
    switch (optype)
    {
#ifdef IPCMSG
    case O_MSGGET:
	return msgget(key, flags);
#endif
#ifdef IPCSEM
    case O_SEMGET:
	return semget(key, n, flags);
#endif
#ifdef IPCSHM
    case O_SHMGET:
	return shmget(key, n, flags);
#endif
#if !defined(IPCMSG) || !defined(IPCSEM) || !defined(IPCSHM)
    default:
	fatal("%s not implemented", opname[optype]);
#endif
    }
    return -1;			/* should never happen */
}

int
do_ipcctl(optype, arglast)
int optype;
int *arglast;
{
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    STR *astr;
    char *a;
    int id, n, cmd, infosize, getinfo, ret;

    id = (int)str_gnum(st[++sp]);
    n = (optype == O_SEMCTL) ? (int)str_gnum(st[++sp]) : 0;
    cmd = (int)str_gnum(st[++sp]);
    astr = st[++sp];

    infosize = 0;
    getinfo = (cmd == IPC_STAT);

    switch (optype)
    {
#ifdef IPCMSG
    case O_MSGCTL:
	if (cmd == IPC_STAT || cmd == IPC_SET)
	    infosize = sizeof(struct msqid_ds);
	break;
#endif
#ifdef IPCSHM
    case O_SHMCTL:
	if (cmd == IPC_STAT || cmd == IPC_SET)
	    infosize = sizeof(struct shmid_ds);
	break;
#endif
#ifdef IPCSEM
    case O_SEMCTL:
	if (cmd == IPC_STAT || cmd == IPC_SET)
	    infosize = sizeof(struct semid_ds);
	else if (cmd == GETALL || cmd == SETALL)
	{
	    struct semid_ds semds;
	    if (semctl(id, 0, IPC_STAT, &semds) == -1)
		return -1;
	    getinfo = (cmd == GETALL);
	    infosize = semds.sem_nsems * sizeof(ushort);
	}
	break;
#endif
#if !defined(IPCMSG) || !defined(IPCSEM) || !defined(IPCSHM)
    default:
	fatal("%s not implemented", opname[optype]);
#endif
    }

    if (infosize)
    {
	if (getinfo)
	{
	    STR_GROW(astr, infosize+1);
	    a = str_get(astr);
	}
	else
	{
	    a = str_get(astr);
	    if (astr->str_cur != infosize)
	    {
		errno = EINVAL;
		return -1;
	    }
	}
    }
    else
    {
	int i = (int)str_gnum(astr);
	a = (char *)i;		/* ouch */
    }
    errno = 0;
    switch (optype)
    {
#ifdef IPCMSG
    case O_MSGCTL:
	ret = msgctl(id, cmd, a);
	break;
#endif
#ifdef IPCSEM
    case O_SEMCTL:
	ret = semctl(id, n, cmd, a);
	break;
#endif
#ifdef IPCSHM
    case O_SHMCTL:
	ret = shmctl(id, cmd, a);
	break;
#endif
    }
    if (getinfo && ret >= 0) {
	astr->str_cur = infosize;
	astr->str_ptr[infosize] = '\0';
    }
    return ret;
}

int
do_msgsnd(arglast)
int *arglast;
{
#ifdef IPCMSG
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    STR *mstr;
    char *mbuf;
    int id, msize, flags;

    id = (int)str_gnum(st[++sp]);
    mstr = st[++sp];
    flags = (int)str_gnum(st[++sp]);
    mbuf = str_get(mstr);
    if ((msize = mstr->str_cur - sizeof(long)) < 0) {
	errno = EINVAL;
	return -1;
    }
    errno = 0;
    return msgsnd(id, mbuf, msize, flags);
#else
    fatal("msgsnd not implemented");
#endif
}

int
do_msgrcv(arglast)
int *arglast;
{
#ifdef IPCMSG
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    STR *mstr;
    char *mbuf;
    long mtype;
    int id, msize, flags, ret;

    id = (int)str_gnum(st[++sp]);
    mstr = st[++sp];
    msize = (int)str_gnum(st[++sp]);
    mtype = (long)str_gnum(st[++sp]);
    flags = (int)str_gnum(st[++sp]);
    mbuf = str_get(mstr);
    if (mstr->str_cur < sizeof(long)+msize+1) {
	STR_GROW(mstr, sizeof(long)+msize+1);
	mbuf = str_get(mstr);
    }
    errno = 0;
    ret = msgrcv(id, mbuf, msize, mtype, flags);
    if (ret >= 0) {
	mstr->str_cur = sizeof(long)+ret;
	mstr->str_ptr[sizeof(long)+ret] = '\0';
    }
    return ret;
#else
    fatal("msgrcv not implemented");
#endif
}

int
do_semop(arglast)
int *arglast;
{
#ifdef IPCSEM
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    STR *opstr;
    char *opbuf;
    int id, opsize;

    id = (int)str_gnum(st[++sp]);
    opstr = st[++sp];
    opbuf = str_get(opstr);
    opsize = opstr->str_cur;
    if (opsize < sizeof(struct sembuf)
	|| (opsize % sizeof(struct sembuf)) != 0) {
	errno = EINVAL;
	return -1;
    }
    errno = 0;
    return semop(id, opbuf, opsize/sizeof(struct sembuf));
#else
    fatal("semop not implemented");
#endif
}

int
do_shmio(optype, arglast)
int optype;
int *arglast;
{
#ifdef IPCSHM
    register STR **st = stack->ary_array;
    register int sp = arglast[0];
    STR *mstr;
    char *mbuf, *shm;
    int id, mpos, msize;
    struct shmid_ds shmds;
    extern char *shmat();

    id = (int)str_gnum(st[++sp]);
    mstr = st[++sp];
    mpos = (int)str_gnum(st[++sp]);
    msize = (int)str_gnum(st[++sp]);
    errno = 0;
    if (shmctl(id, IPC_STAT, &shmds) == -1)
	return -1;
    if (mpos < 0 || msize < 0 || mpos + msize > shmds.shm_segsz) {
	errno = EFAULT;		/* can't do as caller requested */
	return -1;
    }
    shm = shmat(id, (char *)NULL, (optype == O_SHMREAD) ? SHM_RDONLY : 0);
    if (shm == (char *)-1)	/* I hate System V IPC, I really do */
	return -1;
    mbuf = str_get(mstr);
    if (optype == O_SHMREAD) {
	if (mstr->str_cur < msize) {
	    STR_GROW(mstr, msize+1);
	    mbuf = str_get(mstr);
	}
	bcopy(shm + mpos, mbuf, msize);
	mstr->str_cur = msize;
	mstr->str_ptr[msize] = '\0';
    }
    else {
	int n;

	if ((n = mstr->str_cur) > msize)
	    n = msize;
	bcopy(mbuf, shm + mpos, n);
	if (n < msize)
	    bzero(shm + mpos + n, msize - n);
    }
    return shmdt(shm);
#else
    fatal("shm I/O not implemented");
#endif
}

#endif /* SYSVIPC */
