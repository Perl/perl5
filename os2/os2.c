#define INCL_DOS
#define INCL_NOPM
#include <os2.h>

/*
 * Various Unix compatibility functions for OS/2
 */

#include <stdio.h>
#include <errno.h>
#include <limits.h>
#include <process.h>

#include "EXTERN.h"
#include "perl.h"

/*****************************************************************************/
/* priorities */

int setpriority(int which, int pid, int val)
{
  return DosSetPriority((pid < 0) ? PRTYS_PROCESSTREE : PRTYS_PROCESS,
			val >> 8, val & 0xFF, abs(pid));
}

int getpriority(int which /* ignored */, int pid)
{
  TIB *tib;
  PIB *pib;
  DosGetInfoBlocks(&tib, &pib);
  return tib->tib_ptib2->tib2_ulpri;
}

/*****************************************************************************/
/* spawn */

static int
result(int flag, int pid)
{
	int r, status;
	Signal_t (*ihand)();     /* place to save signal during system() */
	Signal_t (*qhand)();     /* place to save signal during system() */

	if (pid < 0 || flag != 0)
		return pid;

	ihand = signal(SIGINT, SIG_IGN);
	qhand = signal(SIGQUIT, SIG_IGN);
	r = waitpid(pid, &status, 0);
	signal(SIGINT, ihand);
	signal(SIGQUIT, qhand);

	statusvalue = (U16)status;
	if (r < 0)
		return -1;
	return status & 0xFFFF;
}

int
do_aspawn(really,mark,sp)
SV *really;
register SV **mark;
register SV **sp;
{
    register char **a;
    char *tmps;
    int rc;
    int flag = P_WAIT, trueflag;

    if (sp > mark) {
	New(401,Argv, sp - mark + 1, char*);
	a = Argv;

	if (mark < sp && SvIOKp(*(mark+1))) {
		++mark;
		flag = SvIVx(*mark);
	}

	while (++mark <= sp) {
	    if (*mark)
		*a++ = SvPVx(*mark, na);
	    else
		*a++ = "";
	}
	*a = Nullch;

	trueflag = flag;
	if (flag == P_WAIT)
		flag = P_NOWAIT;

	if (really && *(tmps = SvPV(really, na)))
	    rc = result(trueflag, spawnvp(flag,tmps,Argv));
	else
	    rc = result(trueflag, spawnvp(flag,Argv[0],Argv));

	if (rc < 0 && dowarn)
	    warn("Can't spawn \"%s\": %s", Argv[0], Strerror(errno));
    } else
    	rc = -1;
    do_execfree();
    return rc;
}

int
do_spawn(cmd)
char *cmd;
{
    register char **a;
    register char *s;
    char flags[10];
    char *shell, *copt;
    int rc;

    if ((shell = getenv("SHELL")) != NULL)
    	copt = "-c";
    else if ((shell = getenv("COMSPEC")) != NULL)
    	copt = "/C";
    else
    	shell = "cmd.exe";

    /* save an extra exec if possible */
    /* see if there are shell metacharacters in it */

    /*SUPPRESS 530*/
    if (*cmd == '@') {
    	++cmd;
    	goto shell_cmd;
    }
    for (s = cmd; *s; s++) {
	if (*s != ' ' && !isALPHA(*s) && strchr("%&|<>\n",*s)) {
	    if (*s == '\n' && !s[1]) {
		*s = '\0';
		break;
	    }
shell_cmd:  return result(P_WAIT, spawnl(P_NOWAIT,shell,shell,copt,cmd,(char*)0));
	}
    }
    New(402,Argv, (s - cmd) / 2 + 2, char*);
    Cmd = savepvn(cmd, s-cmd);
    a = Argv;
    for (s = Cmd; *s;) {
	while (*s && isSPACE(*s)) s++;
	if (*s)
	    *(a++) = s;
	while (*s && !isSPACE(*s)) s++;
	if (*s)
	    *s++ = '\0';
    }
    *a = Nullch;
    if (Argv[0]) {
	rc = result(P_WAIT, spawnvp(P_NOWAIT,Argv[0],Argv));
	if (rc < 0 && dowarn)
	    warn("Can't spawn \"%s\": %s", Argv[0], Strerror(errno));
    } else
    	rc = -1;
    do_execfree();
    return rc;
}

/*****************************************************************************/

#ifndef HAS_FORK
int
fork(void)
{
    die(no_func, "Unsupported function fork");
    errno = EINVAL;
    return -1;
}
#endif

/*****************************************************************************/
/* not implemented in EMX 0.9a */

void *	ctermid(x)	{ return 0; }

#ifdef MYTTYNAME /* was not in emx0.9a */
void *	ttyname(x)	{ return 0; }
#endif

void *	gethostent()	{ return 0; }
void *	getnetent()	{ return 0; }
void *	getprotoent()	{ return 0; }
void *	getservent()	{ return 0; }
void	sethostent(x)	{}
void	setnetent(x)	{}
void	setprotoent(x)	{}
void	setservent(x)	{}
void	endhostent(x)	{}
void	endnetent(x)	{}
void	endprotoent(x)	{}
void	endservent(x)	{}

/*****************************************************************************/
/* stat() hack for char/block device */

#if OS2_STAT_HACK

    /* First attempt used DosQueryFSAttach which crashed the system when
       used with 5.001. Now just look for /dev/. */

int
os2_stat(char *name, struct stat *st)
{
    static int ino = SHRT_MAX;

    if (stricmp(name, "/dev/con") != 0
     && stricmp(name, "/dev/tty") != 0)
	return stat(name, st);

    memset(st, 0, sizeof *st);
    st->st_mode = S_IFCHR|0666;
    st->st_ino = (ino-- & 0x7FFF);
    st->st_nlink = 1;
    return 0;
}

#endif
