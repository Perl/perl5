#define INCL_DOS
#define INCL_NOPM
#define INCL_DOSFILEMGR
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
static signed char priors[] = {0, 1, 3, 2}; /* Last two interchanged,
					       self inverse. */
#define QSS_INI_BUFFER 1024

PQTOPLEVEL
get_sysinfo(ULONG pid, ULONG flags)
{
    char *pbuffer;
    ULONG rc, buf_len = QSS_INI_BUFFER;

    New(1022, pbuffer, buf_len, char);
    /* QSS_PROCESS | QSS_MODULE | QSS_SEMAPHORES | QSS_SHARED */
    rc = QuerySysState(flags, pid, pbuffer, buf_len);
    while (rc == ERROR_BUFFER_OVERFLOW) {
	Renew(pbuffer, buf_len *= 2, char);
	rc = QuerySysState(QSS_PROCESS, pid, pbuffer, buf_len);
    }
    if (rc) {
	FillOSError(rc);
	Safefree(pbuffer);
	return 0;
    }
    return (PQTOPLEVEL)pbuffer;
}

#define PRIO_ERR 0x1111

static ULONG
sys_prio(pid)
{
  ULONG prio;
  PQTOPLEVEL psi;

  psi = get_sysinfo(pid, QSS_PROCESS);
  if (!psi) {
      return PRIO_ERR;
  }
  if (pid != psi->procdata->pid) {
      Safefree(psi);
      croak("panic: wrong pid in sysinfo");
  }
  prio = psi->procdata->threads->priority;
  Safefree(psi);
  return prio;
}

int 
setpriority(int which, int pid, int val)
{
  ULONG rc, prio;
  PQTOPLEVEL psi;

  prio = sys_prio(pid);

  if (priors[(32 - val) >> 5] + 1 == (prio >> 8)) {
      /* Do not change class. */
      return CheckOSError(DosSetPriority((pid < 0) 
					 ? PRTYS_PROCESSTREE : PRTYS_PROCESS,
					 0, 
					 (32 - val) % 32 - (prio & 0xFF), 
					 abs(pid)))
      ? -1 : 0;
  } else /* if ((32 - val) % 32 == (prio & 0xFF)) */ {
      /* Documentation claims one can change both class and basevalue,
       * but I find it wrong. */
      /* Change class, but since delta == 0 denotes absolute 0, correct. */
      if (CheckOSError(DosSetPriority((pid < 0) 
				      ? PRTYS_PROCESSTREE : PRTYS_PROCESS,
				      priors[(32 - val) >> 5] + 1, 
				      0, 
				      abs(pid)))) 
	  return -1;
      if ( ((32 - val) % 32) == 0 ) return 0;
      return CheckOSError(DosSetPriority((pid < 0) 
					 ? PRTYS_PROCESSTREE : PRTYS_PROCESS,
					 0, 
					 (32 - val) % 32, 
					 abs(pid)))
	  ? -1 : 0;
  } 
/*   else return CheckOSError(DosSetPriority((pid < 0)  */
/* 					  ? PRTYS_PROCESSTREE : PRTYS_PROCESS, */
/* 					  priors[(32 - val) >> 5] + 1,  */
/* 					  (32 - val) % 32 - (prio & 0xFF),  */
/* 					  abs(pid))) */
/*       ? -1 : 0; */
}

int 
getpriority(int which /* ignored */, int pid)
{
  TIB *tib;
  PIB *pib;
  ULONG rc, ret;

  /* DosGetInfoBlocks has old priority! */
/*   if (CheckOSError(DosGetInfoBlocks(&tib, &pib))) return -1; */
/*   if (pid != pib->pib_ulpid) { */
  ret = sys_prio(pid);
  if (ret == PRIO_ERR) {
      return -1;
  }
/*   } else */
/*       ret = tib->tib_ptib2->tib2_ulpri; */
  return (1 - priors[((ret >> 8) - 1)])*32 - (ret & 0xFF);
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
    shell = SH_PATH;
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

#ifndef HAS_FORK
FILE *
my_popen(cmd,mode)
char	*cmd;
char	*mode;
{
    char *shell = getenv("EMXSHELL");
    FILE *res;
    
    my_setenv("EMXSHELL", SH_PATH);
    res = popen(cmd, mode);
    my_setenv("EMXSHELL", shell);
    return res;
}
#endif

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

static char *oldchunk;
static long oldsize;

#define _32_K (1<<15)
#define _64_K (1<<16)

/* The real problem is that DosAllocMem will grant memory on 64K-chunks
 * boundaries only. Note that addressable space for application memory
 * is around 240M, thus we will run out of addressable space if we
 * allocate around 14M worth of 4K segments.
 * Thus we allocate memory in 64K chunks, and abandon the rest of the old
 * chunk if the new is bigger than that rest. Also, we just allocate
 * whatever is requested if the size is bigger that 32K. With this strategy
 * we cannot lose more than 1/2 of addressable space. */

void *
sbrk(int size)
{
    char *got;
    APIRET rc;
    int small, reqsize;

    if (!size) return 0;
    else if (size <= oldsize) {
	got = oldchunk;
	oldchunk += size;
	oldsize -= size;
	return (void *)got;
    } else if (size >= _32_K) {
	small = 0;
    } else {
	reqsize = size;
	size = _64_K;
	small = 1;
    }
    rc = DosAllocMem((void **)&got, size, PAG_COMMIT | PAG_WRITE);
    if (rc == ERROR_NOT_ENOUGH_MEMORY) {
	return (void *) -1;
    } else if ( rc ) die("Got an error from DosAllocMem: %li", (long)rc);
    if (small) {
	/* Chunk is small, register the rest for future allocs. */
	oldchunk = got + reqsize;
	oldsize = size - reqsize;
    }
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

#include "XSUB.h"

XS(XS_File__Copy_syscopy)
{
    dXSARGS;
    if (items < 2 || items > 3)
	croak("Usage: File::Copy::syscopy(src,dst,flag=0)");
    {
	char *	src = (char *)SvPV(ST(0),na);
	char *	dst = (char *)SvPV(ST(1),na);
	U32	flag;
	int	RETVAL, rc;

	if (items < 3)
	    flag = 0;
	else {
	    flag = (unsigned long)SvIV(ST(2));
	}

	RETVAL = !CheckOSError(DosCopy(src, dst, flag));
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)RETVAL);
    }
    XSRETURN(1);
}

char *
mod2fname(sv)
     SV   *sv;
{
    static char fname[9];
    int pos = 7;
    int len;
    AV  *av;
    SV  *svp;
    char *s;

    if (!SvROK(sv)) croak("Not a reference given to mod2fname");
    sv = SvRV(sv);
    if (SvTYPE(sv) != SVt_PVAV) 
      croak("Not array reference given to mod2fname");
    if (av_len((AV*)sv) < 0) 
      croak("Empty array reference given to mod2fname");
    s = SvPV(*av_fetch((AV*)sv, av_len((AV*)sv), FALSE), na);
    strncpy(fname, s, 8);
    if ((len=strlen(s)) < 7) pos = len;
    fname[pos] = '_';
    fname[pos + 1] = '\0';
    return (char *)fname;
}

XS(XS_DynaLoader_mod2fname)
{
    dXSARGS;
    if (items != 1)
	croak("Usage: DynaLoader::mod2fname(sv)");
    {
	SV *	sv = ST(0);
	char *	RETVAL;

	RETVAL = mod2fname(sv);
	ST(0) = sv_newmortal();
	sv_setpv((SV*)ST(0), RETVAL);
    }
    XSRETURN(1);
}

char *
os2error(int rc)
{
	static char buf[300];
	ULONG len;

	if (rc == 0)
		return NULL;
	if (DosGetMessage(NULL, 0, buf, sizeof buf - 1, rc, "OSO001.MSG", &len))
		sprintf(buf, "OS/2 system error code %d=0x%x", rc, rc);
	else
		buf[len] = '\0';
	return buf;
}

OS2_Perl_data_t OS2_Perl_data;

int
Xs_OS2_init()
{
    char *file = __FILE__;
    {
	GV *gv;
	
        newXS("File::Copy::syscopy", XS_File__Copy_syscopy, file);
        newXS("DynaLoader::mod2fname", XS_DynaLoader_mod2fname, file);
#ifdef PERL_IS_AOUT
	gv = gv_fetchpv("OS2::is_aout", TRUE, SVt_PV);
	GvMULTI_on(gv);
	sv_setiv(GvSV(gv), 1);
#endif 
    }
}

void
Perl_OS2_init()
{
    char *shell;

    settmppath();
    OS2_Perl_data.xs_init = &Xs_OS2_init;
    if ( (shell = getenv("PERL_SH_DRIVE")) ) {
	sh_path[0] = shell[0];
    }
}

char sh_path[33] = BIN_SH;

extern void dlopen();
void *fakedl = &dlopen;		/* Pull in dynaloading part. */
