#define INCL_DOS
#define INCL_NOPM
#ifndef NO_SYS_ALLOC 
#  define INCL_DOSMEMMGR
#  define INCL_DOSERRORS
#endif /* ! defined NO_SYS_ALLOC */
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
	do {
	    r = wait4pid(pid, &status, 0);
	} while (r == -1 && errno == EINTR);
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

	if (*Argv[0] != '/' && *Argv[0] != '\\') /* will swawnvp use PATH? */
	    TAINT_ENV();	/* testing IFS here is overkill, probably */
	if (really && *(tmps = SvPV(really, na)))
	    rc = result(trueflag, spawnvp(flag,tmps,Argv));
	else
	    rc = result(trueflag, spawnvp(flag,Argv[0],Argv));

	if (rc < 0 && dowarn)
	    warn("Can't spawn \"%s\": %s", Argv[0], Strerror(errno));
	if (rc < 0) rc = 255 << 8; /* Emulate the fork(). */
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

#ifdef TRYSHELL
    if ((shell = getenv("EMXSHELL")) != NULL)
    	copt = "-c";
    else if ((shell = getenv("SHELL")) != NULL)
    	copt = "-c";
    else if ((shell = getenv("COMSPEC")) != NULL)
    	copt = "/C";
    else
    	shell = "cmd.exe";
#else
    /* Consensus on perl5-porters is that it is _very_ important to
       have a shell which will not change between computers with the
       same architecture, to avoid "action on a distance". 
       And to have simple build, this shell should be sh. */
    shell = "sh.exe";
    copt = "-c";
#endif 

    while (*cmd && isSPACE(*cmd))
	cmd++;

    /* save an extra exec if possible */
    /* see if there are shell metacharacters in it */

    if (*cmd == '.' && isSPACE(cmd[1]))
	goto doshell;

    if (strnEQ(cmd,"exec",4) && isSPACE(cmd[4]))
	goto doshell;

    for (s = cmd; *s && isALPHA(*s); s++) ;	/* catch VAR=val gizmo */
    if (*s == '=')
	goto doshell;

    for (s = cmd; *s; s++) {
	if (*s != ' ' && !isALPHA(*s) && strchr("$&*(){}[]'\";\\|?<>~`\n",*s)) {
	    if (*s == '\n' && !s[1]) {
		*s = '\0';
		break;
	    }
	  doshell:
	    rc = result(P_WAIT,
			  spawnl(P_NOWAIT,shell,shell,copt,cmd,(char*)0));
	    if (rc < 0 && dowarn)
		warn("Can't spawn \"%s\": %s", shell, Strerror(errno));
	    if (rc < 0) rc = 255 << 8; /* Emulate the fork(). */
	    return rc;
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
	if (rc < 0) rc = 255 << 8; /* Emulate the fork(). */
    } else
    	rc = -1;
    do_execfree();
    return rc;
}

FILE *
my_popen(cmd,mode)
char	*cmd;
char	*mode;
{
    char *shell = getenv("EMXSHELL");
    FILE *res;
    
    my_setenv("EMXSHELL", "sh.exe");
    res = popen(cmd, mode);
    my_setenv("EMXSHELL", shell);
    return res;
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

#ifndef NO_SYS_ALLOC

static char *old2K;

#define ONE_K (1<<10)
#define TWO_K (1<<11)
#define FOUR_K (1<<12)
#define FOUR_K_FLAG (FOUR_K - 1)


void *
sbrk(int size)
{
    char *got;
    APIRET rc;
    int is2K = 0;

    if (!size) return 0;
    else if (size == TWO_K) {
	is2K = 1;
	if (old2K) {
	    char *ret = old2K;

	    old2K = 0;
	    return (void *)ret;
	}
	size = FOUR_K;
    } else if (size & FOUR_K_FLAG) {
	croak("Memory allocation in units %li not multiple to 4K", size);
    }
    rc = DosAllocMem((void **)&got, size, PAG_COMMIT | PAG_WRITE);
    if (rc == ERROR_NOT_ENOUGH_MEMORY) {
	return (void *) -1;
    } else if ( rc ) die("Got an error from DosAllocMem: %li", (long)rc);
    if (is2K) old2K = got + TWO_K;
    return (void *)got;
}
#endif /* ! defined NO_SYS_ALLOC */

/* tmp path */

char *tmppath = TMPPATH1;

void
settmppath()
{
    char *p = getenv("TMP"), *tpath;
    int len;

    if (!p) p = getenv("TEMP");
    if (!p) return;
    len = strlen(p);
    tpath = (char *)malloc(len + strlen(TMPPATH1) + 2);
    strcpy(tpath, p);
    tpath[len] = '/';
    strcpy(tpath + len + 1, TMPPATH1);
    tmppath = tpath;
}
