#define INCL_DOS
#define INCL_NOPM
#define INCL_DOSFILEMGR
#define INCL_DOSMEMMGR
#define INCL_DOSERRORS
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
#ifndef __EMX__
	RESULTCODES res;
	int rpid;
#endif

	if (pid < 0 || flag != 0)
		return pid;

#ifdef __EMX__
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
#else
	ihand = signal(SIGINT, SIG_IGN);
	r = DosWaitChild(DCWA_PROCESS, DCWW_WAIT, &res, &rpid, pid);
	signal(SIGINT, ihand);
	statusvalue = res.codeResult << 8 | res.codeTerminate;
	if (r)
		return -1;
	return statusvalue;
#endif
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

	if (mark < sp && SvNIOKp(*(mark+1)) && !SvPOKp(*(mark+1))) {
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

	if (*Argv[0] != '/' && *Argv[0] != '\\'
	    && !(*Argv[0] && *Argv[1] == ':' 
		 && (*Argv[2] == '/' || *Argv[2] != '\\'))
	    ) /* will swawnvp use PATH? */
	    TAINT_ENV();	/* testing IFS here is overkill, probably */
	/* We should check PERL_SH* and PERLLIB_* as well? */
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

#define EXECF_SPAWN 0
#define EXECF_EXEC 1
#define EXECF_TRUEEXEC 2

int
do_spawn2(cmd, execf)
char *cmd;
int execf;
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
	    if (execf == EXECF_TRUEEXEC)
                return execl(shell,shell,copt,cmd,(char*)0);
	    else if (execf == EXECF_EXEC)
                return spawnl(P_OVERLAY,shell,shell,copt,cmd,(char*)0);
	    /* In the ak code internal P_NOWAIT is P_WAIT ??? */
	    rc = result(P_WAIT,
			spawnl(P_NOWAIT,shell,shell,copt,cmd,(char*)0));
	    if (rc < 0 && dowarn)
		warn("Can't %s \"%s\": %s", 
		     (execf == EXECF_SPAWN ? "spawn" : "exec"),
		     shell, Strerror(errno));
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
	if (execf == EXECF_TRUEEXEC)
	    rc = execvp(Argv[0],Argv);
	else if (execf == EXECF_EXEC)
	    rc = spawnvp(P_OVERLAY,Argv[0],Argv);
        else
	    rc = result(P_WAIT, spawnvp(P_NOWAIT,Argv[0],Argv));
	if (rc < 0 && dowarn)
	    warn("Can't %s \"%s\": %s", 
		 (execf == EXECF_SPAWN ? "spawn" : "exec"),
		 Argv[0], Strerror(errno));
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
    return do_spawn2(cmd, EXECF_SPAWN);
}

bool
do_exec(cmd)
char *cmd;
{
    return do_spawn2(cmd, EXECF_EXEC);
}

bool
os2exec(cmd)
char *cmd;
{
    return do_spawn2(cmd, EXECF_TRUEEXEC);
}

#ifndef HAS_FORK
FILE *
my_popen(cmd,mode)
char	*cmd;
char	*mode;
{
#ifdef TRYSHELL
    return popen(cmd, mode);
#else
    char *shell = getenv("EMXSHELL");
    FILE *res;
    
    my_setenv("EMXSHELL", SH_PATH);
    res = popen(cmd, mode);
    my_setenv("EMXSHELL", shell);
    return res;
#endif 
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

/*****************************************************************************/
/* my socket forwarders - EMX lib only provides static forwarders */

static HMODULE htcp = 0;

static void *
tcp0(char *name)
{
    static BYTE buf[20];
    PFN fcn;
    if (!htcp)
	DosLoadModule(buf, sizeof buf, "tcp32dll", &htcp);
    if (htcp && DosQueryProcAddr(htcp, 0, name, &fcn) == 0)
	return (void *) ((void * (*)(void)) fcn) ();
    return 0;
}

static void
tcp1(char *name, int arg)
{
    static BYTE buf[20];
    PFN fcn;
    if (!htcp)
	DosLoadModule(buf, sizeof buf, "tcp32dll", &htcp);
    if (htcp && DosQueryProcAddr(htcp, 0, name, &fcn) == 0)
	((void (*)(int)) fcn) (arg);
}

void *	gethostent()	{ return tcp0("GETHOSTENT");  }
void *	getnetent()	{ return tcp0("GETNETENT");   }
void *	getprotoent()	{ return tcp0("GETPROTOENT"); }
void *	getservent()	{ return tcp0("GETSERVENT");  }
void	sethostent(x)	{ tcp1("SETHOSTENT",  x); }
void	setnetent(x)	{ tcp1("SETNETENT",   x); }
void	setprotoent(x)	{ tcp1("SETPROTOENT", x); }
void	setservent(x)	{ tcp1("SETSERVENT",  x); }
void	endhostent()	{ tcp0("ENDHOSTENT");  }
void	endnetent()	{ tcp0("ENDNETENT");   }
void	endprotoent()	{ tcp0("ENDPROTOENT"); }
void	endservent()	{ tcp0("ENDSERVENT");  }

/*****************************************************************************/
/* not implemented in C Set++ */

#ifndef __EMX__
int	setuid(x)	{ errno = EINVAL; return -1; }
int	setgid(x)	{ errno = EINVAL; return -1; }
#endif

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

#ifdef USE_PERL_SBRK

/* SBRK() emulation, mostly moved to malloc.c. */

void *
sys_alloc(int size) {
    void *got;
    APIRET rc = DosAllocMem(&got, size, PAG_COMMIT | PAG_WRITE);

    if (rc == ERROR_NOT_ENOUGH_MEMORY) {
	return (void *) -1;
    } else if ( rc ) die("Got an error from DosAllocMem: %li", (long)rc);
    return got;
}

#endif /* USE_PERL_SBRK */

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
    int pos = 6, len, avlen;
    unsigned int sum = 0;
    AV  *av;
    SV  *svp;
    char *s;

    if (!SvROK(sv)) croak("Not a reference given to mod2fname");
    sv = SvRV(sv);
    if (SvTYPE(sv) != SVt_PVAV) 
      croak("Not array reference given to mod2fname");

    avlen = av_len((AV*)sv);
    if (avlen < 0) 
      croak("Empty array reference given to mod2fname");

    s = SvPV(*av_fetch((AV*)sv, avlen, FALSE), na);
    strncpy(fname, s, 8);
    len = strlen(s);
    if (len < 6) pos = len;
    while (*s) {
	sum = 33 * sum + *(s++);	/* Checksumming first chars to
					 * get the capitalization into c.s. */
    }
    avlen --;
    while (avlen >= 0) {
	s = SvPV(*av_fetch((AV*)sv, avlen, FALSE), na);
	while (*s) {
	    sum = 33 * sum + *(s++);	/* 7 is primitive mod 13. */
	}
	avlen --;
    }
    fname[pos] = 'A' + (sum % 26);
    fname[pos + 1] = 'A' + (sum / 26 % 26);
    fname[pos + 2] = '\0';
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
	gv = gv_fetchpv("OS2::is_aout", TRUE, SVt_PV);
	GvMULTI_on(gv);
#ifdef PERL_IS_AOUT
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
    } else if ( (shell = getenv("PERL_SH_DIR")) ) {
	int l = strlen(shell);
	if (shell[l-1] == '/' || shell[l-1] == '\\') {
	    l--;
	}
	if (l > STATIC_FILE_LENGTH - 7) {
	    die("PERL_SH_DIR too long");
	}
	strncpy(sh_path, shell, l);
	strcpy(sh_path + l, "/sh.exe");
    }
}

char sh_path[STATIC_FILE_LENGTH+1] = SH_PATH_INI;

char *
perllib_mangle(char *s, unsigned int l)
{
    static char *newp, *oldp;
    static int newl, oldl, notfound;
    static char ret[STATIC_FILE_LENGTH+1];
    
    if (!newp && !notfound) {
	newp = getenv("PERLLIB_PREFIX");
	if (newp) {
	    oldp = newp;
	    while (*newp && !isSPACE(*newp) && *newp != ';') {
		newp++; oldl++;		/* Skip digits. */
	    }
	    while (*newp && (isSPACE(*newp) || *newp == ';')) {
		newp++;			/* Skip whitespace. */
	    }
	    newl = strlen(newp);
	    if (newl == 0 || oldl == 0) {
		die("Malformed PERLLIB_PREFIX");
	    }
	} else {
	    notfound = 1;
	}
    }
    if (!newp) {
	return s;
    }
    if (l == 0) {
	l = strlen(s);
    }
    if (l <= oldl || strnicmp(oldp, s, oldl) != 0) {
	return s;
    }
    if (l + newl - oldl > STATIC_FILE_LENGTH || newl > STATIC_FILE_LENGTH) {
	die("Malformed PERLLIB_PREFIX");
    }
    strncpy(ret, newp, newl);
    strcpy(ret + newl, s + oldl);
    return ret;
}

extern void dlopen();
void *fakedl = &dlopen;		/* Pull in dynaloading part. */
