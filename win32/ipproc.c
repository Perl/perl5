/*

	ipproc.c
	Interface for perl process functions

*/

#include <ipproc.h>
#include <stdlib.h>
#include <fcntl.h>

#define EXECF_EXEC 1
#define EXECF_SPAWN 2
#define EXECF_SPAWN_NOWAIT 3

class CPerlProc : public IPerlProc
{
public:
	CPerlProc() 
	{
		pPerl = NULL;
		w32_perlshell_tokens = NULL;
		w32_perlshell_items = -1;
		w32_platform = -1;
#ifndef __BORLANDC__
		w32_num_children = 0;
#endif
	};
	virtual void Abort(void);
	virtual void Exit(int status);
	virtual void _Exit(int status);
	virtual int Execl(const char *cmdname, const char *arg0, const char *arg1, const char *arg2, const char *arg3);
	virtual int Execv(const char *cmdname, const char *const *argv);
	virtual int Execvp(const char *cmdname, const char *const *argv);
	virtual uid_t Getuid(void);
	virtual uid_t Geteuid(void);
	virtual gid_t Getgid(void);
	virtual gid_t Getegid(void);
	virtual char *Getlogin(void);
	virtual int Kill(int pid, int sig);
	virtual int Killpg(int pid, int sig);
	virtual int PauseProc(void);
	virtual PerlIO* Popen(const char *command, const char *mode);
	virtual int Pclose(PerlIO *stream);
	virtual int Pipe(int *phandles);
	virtual int Setuid(uid_t u);
	virtual int Setgid(gid_t g);
	virtual int Sleep(unsigned int);
	virtual int Times(struct tms *timebuf);
	virtual int Wait(int *status);
	virtual Sighandler_t Signal(int sig, Sighandler_t subcode);
	virtual void GetSysMsg(char*& msg, DWORD& dwLen, DWORD dwErr);
	virtual void FreeBuf(char* msg);
	virtual BOOL DoCmd(char *cmd);
	virtual int Spawn(char*cmds);
	virtual int Spawnvp(int mode, const char *cmdname, const char *const *argv);
	virtual int ASpawn(void *vreally, void **vmark, void **vsp);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
protected:
	int Spawn(char *cmd, int exectype);
	void GetShell(void);
	long Tokenize(char *str, char **dest, char ***destv);

	inline int IsWin95(void)
	{
		return (os_id() == VER_PLATFORM_WIN32_WINDOWS);
	};
	inline int IsWinNT(void)
	{
		return (os_id() == VER_PLATFORM_WIN32_NT);
	};

	inline long filetime_to_clock(PFILETIME ft)
	{
		__int64 qw = ft->dwHighDateTime;
		qw <<= 32;
		qw |= ft->dwLowDateTime;
		qw /= 10000;  /* File time ticks at 0.1uS, clock at 1mS */
		return (long) qw;
	};

	DWORD os_id(void)
	{
		if((-1) == w32_platform)
		{
			OSVERSIONINFO osver;

			memset(&osver, 0, sizeof(OSVERSIONINFO));
			osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
			GetVersionEx(&osver);
			w32_platform = osver.dwPlatformId;
		}
		return (w32_platform);
	};

	DWORD w32_platform;
	char szLoginNameStr[128];
	char *w32_perlshell_tokens;
	long w32_perlshell_items;
	char **w32_perlshell_vec;
#ifndef __BORLANDC__
	long w32_num_children;
	HANDLE w32_child_pids[MAXIMUM_WAIT_OBJECTS];
#endif
	CPerlObj *pPerl;
};


static BOOL
has_redirection(char *ptr)
{
    int inquote = 0;
    char quote = '\0';

    /*
     * Scan string looking for redirection (< or >) or pipe
     * characters (|) that are not in a quoted string
     */
    while(*ptr) {
	switch(*ptr) {
	case '\'':
	case '\"':
	    if(inquote) {
		if(quote == *ptr) {
		    inquote = 0;
		    quote = '\0';
		}
	    }
	    else {
		quote = *ptr;
		inquote++;
	    }
	    break;
	case '>':
	case '<':
	case '|':
	    if(!inquote)
		return TRUE;
	default:
	    break;
	}
	++ptr;
    }
    return FALSE;
}

/* Tokenize a string.  Words are null-separated, and the list
 * ends with a doubled null.  Any character (except null and
 * including backslash) may be escaped by preceding it with a
 * backslash (the backslash will be stripped).
 * Returns number of words in result buffer.
 */
long
CPerlProc::Tokenize(char *str, char **dest, char ***destv)
{
    char *retstart = Nullch;
    char **retvstart = 0;
    int items = -1;
    if (str) {
	int slen = strlen(str);
	register char *ret;
	register char **retv;
	New(1307, ret, slen+2, char);
	New(1308, retv, (slen+3)/2, char*);

	retstart = ret;
	retvstart = retv;
	*retv = ret;
	items = 0;
	while (*str) {
	    *ret = *str++;
	    if (*ret == '\\' && *str)
		*ret = *str++;
	    else if (*ret == ' ') {
		while (*str == ' ')
		    str++;
		if (ret == retstart)
		    ret--;
		else {
		    *ret = '\0';
		    ++items;
		    if (*str)
			*++retv = ret+1;
		}
	    }
	    else if (!*str)
		++items;
	    ret++;
	}
	retvstart[items] = Nullch;
	*ret++ = '\0';
	*ret = '\0';
    }
    *dest = retstart;
    *destv = retvstart;
    return items;
}


void
CPerlProc::GetShell(void)
{
    if (!w32_perlshell_tokens) {
	/* we don't use COMSPEC here for two reasons:
	 *  1. the same reason perl on UNIX doesn't use SHELL--rampant and
	 *     uncontrolled unportability of the ensuing scripts.
	 *  2. PERL5SHELL could be set to a shell that may not be fit for
	 *     interactive use (which is what most programs look in COMSPEC
	 *     for).
	 */
	char* defaultshell = (IsWinNT() ? "cmd.exe /x/c" : "command.com /c");
	char* usershell = getenv("PERL5SHELL");
	w32_perlshell_items = Tokenize(usershell ? usershell : defaultshell,
				       &w32_perlshell_tokens,
				       &w32_perlshell_vec);
    }
}

int
CPerlProc::ASpawn(void *vreally, void **vmark, void **vsp)
{
    SV *really = (SV*)vreally;
    SV **mark = (SV**)vmark;
    SV **sp = (SV**)vsp;
    char **argv;
    char *str;
    int status;
    int flag = P_WAIT;
    int index = 0;

    if (sp <= mark)
	return -1;

    GetShell();
    New(1306, argv, (sp - mark) + w32_perlshell_items + 2, char*);

    if (SvNIOKp(*(mark+1)) && !SvPOKp(*(mark+1))) {
	++mark;
	flag = SvIVx(*mark);
    }

    while(++mark <= sp) {
	if (*mark && (str = SvPV(*mark, na)))
	    argv[index++] = str;
	else
	    argv[index++] = "";
    }
    argv[index++] = 0;
   
    status = Spawnvp(flag,
			   (really ? SvPV(really,na) : argv[0]),
			   (const char* const*)argv);

    if (status < 0 && errno == ENOEXEC) {
	/* possible shell-builtin, invoke with shell */
	int sh_items;
	sh_items = w32_perlshell_items;
	while (--index >= 0)
	    argv[index+sh_items] = argv[index];
	while (--sh_items >= 0)
	    argv[sh_items] = w32_perlshell_vec[sh_items];
   
	status = Spawnvp(flag,
			       (really ? SvPV(really,na) : argv[0]),
			       (const char* const*)argv);
    }

    if (status < 0) {
	if (pPerl->Perl_dowarn)
	    warn("Can't spawn \"%s\": %s", argv[0], strerror(errno));
	status = 255 * 256;
    }
    else if (flag != P_NOWAIT)
	status *= 256;
    Safefree(argv);
    return (pPerl->Perl_statusvalue = status);
}


int
CPerlProc::Spawn(char *cmd, int exectype)
{
    char **a;
    char *s;
    char **argv;
    int status = -1;
    BOOL needToTry = TRUE;
    char *cmd2;

    /* Save an extra exec if possible. See if there are shell
     * metacharacters in it */
    if(!has_redirection(cmd)) {
	New(1301,argv, strlen(cmd) / 2 + 2, char*);
	New(1302,cmd2, strlen(cmd) + 1, char);
	strcpy(cmd2, cmd);
	a = argv;
	for (s = cmd2; *s;) {
	    while (*s && isspace(*s))
		s++;
	    if (*s)
		*(a++) = s;
	    while(*s && !isspace(*s))
		s++;
	    if(*s)
		*s++ = '\0';
	}
	*a = Nullch;
	if (argv[0]) {
	    switch (exectype) {
	    case EXECF_SPAWN:
		status = Spawnvp(P_WAIT, argv[0],
				       (const char* const*)argv);
		break;
	    case EXECF_SPAWN_NOWAIT:
		status = Spawnvp(P_NOWAIT, argv[0],
				       (const char* const*)argv);
		break;
	    case EXECF_EXEC:
		status = Execvp(argv[0], (const char* const*)argv);
		break;
	    }
	    if (status != -1 || errno == 0)
		needToTry = FALSE;
	}
	Safefree(argv);
	Safefree(cmd2);
    }
    if (needToTry) {
	char **argv;
	int i = -1;
	GetShell();
	New(1306, argv, w32_perlshell_items + 2, char*);
	while (++i < w32_perlshell_items)
	    argv[i] = w32_perlshell_vec[i];
	argv[i++] = cmd;
	argv[i] = Nullch;
	switch (exectype) {
	case EXECF_SPAWN:
	    status = Spawnvp(P_WAIT, argv[0],
				   (const char* const*)argv);
	    break;
	case EXECF_SPAWN_NOWAIT:
	    status = Spawnvp(P_NOWAIT, argv[0],
				   (const char* const*)argv);
	    break;
	case EXECF_EXEC:
	    status = Execvp(argv[0], (const char* const*)argv);
	    break;
	}
	cmd = argv[0];
	Safefree(argv);
    }
    if (status < 0) {
	if (pPerl->Perl_dowarn)
	    warn("Can't %s \"%s\": %s",
		 (exectype == EXECF_EXEC ? "exec" : "spawn"),
		 cmd, strerror(errno));
	status = 255 * 256;
    }
    else if (exectype != EXECF_SPAWN_NOWAIT)
	status *= 256;
    return (pPerl->Perl_statusvalue = status);
}


void CPerlProc::Abort(void)
{
	abort();
}

void CPerlProc::Exit(int status)
{
	exit(status);
}

void CPerlProc::_Exit(int status)
{
	_exit(status);
}

int CPerlProc::Execl(const char *cmdname, const char *arg0, const char *arg1, const char *arg2, const char *arg3)
{
	return execl(cmdname, arg0, arg1, arg2, arg3);
}

int CPerlProc::Execv(const char *cmdname, const char *const *argv)
{
	return execv(cmdname, argv);
}

int CPerlProc::Execvp(const char *cmdname, const char *const *argv)
{
	return execvp(cmdname, argv);
}

#define ROOT_UID    ((uid_t)0)
#define ROOT_GID    ((gid_t)0)

uid_t CPerlProc::Getuid(void)
{
    return ROOT_UID;
}

uid_t CPerlProc::Geteuid(void)
{
    return ROOT_UID;
}

gid_t CPerlProc::Getgid(void)
{
    return ROOT_GID;
}

gid_t CPerlProc::Getegid(void)
{
    return ROOT_GID;
}


char *CPerlProc::Getlogin(void)
{
	char unknown[] = "<Unknown>";
	unsigned long len;

	len = sizeof(szLoginNameStr);
	if(!GetUserName(szLoginNameStr, &len)) 
	{
		strcpy(szLoginNameStr, unknown);
	}
	return szLoginNameStr;
}

int CPerlProc::Kill(int pid, int sig)
{
	HANDLE hProcess;

	hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, (DWORD)pid);
	if(hProcess == NULL)
		croak("kill process failed!\n");

	if(TerminateProcess(hProcess, 0) == FALSE)
		croak("kill process failed!\n");

	CloseHandle(hProcess);
	return 0;
}

int CPerlProc::Killpg(int pid, int sig)
{
	croak("killpg not implemented!\n");
	return 0;
}

int CPerlProc::PauseProc(void)
{
    Sleep((unsigned int)((32767L << 16) + 32767));
    return 0;
}

PerlIO* CPerlProc::Popen(const char *command, const char *mode)
{
	return (PerlIO*)_popen(command, mode);
}

int CPerlProc::Pclose(PerlIO *pf)
{
	return _pclose((FILE*)pf);
}

int CPerlProc::Pipe(int *phandles)
{
	return _pipe(phandles, 512, O_BINARY);
}

int CPerlProc::Sleep(unsigned int s)
{
    ::Sleep(s*1000);
    return 0;
}

int CPerlProc::Times(struct tms *timebuf)
{
    FILETIME user;
    FILETIME kernel;
    FILETIME dummy;
    if (GetProcessTimes(GetCurrentProcess(), &dummy, &dummy, 
                        &kernel,&user)) {
	timebuf->tms_utime = filetime_to_clock(&user);
	timebuf->tms_stime = filetime_to_clock(&kernel);
	timebuf->tms_cutime = 0;
	timebuf->tms_cstime = 0;
        
    } else { 
        /* That failed - e.g. Win95 fallback to clock() */
        clock_t t = clock();
	timebuf->tms_utime = t;
	timebuf->tms_stime = 0;
	timebuf->tms_cutime = 0;
	timebuf->tms_cstime = 0;
    }
    return 0;
}

int CPerlProc::Wait(int *status)
{
#ifdef __BORLANDC__
    return wait(status);
#else
    /* XXX this wait emulation only knows about processes
     * spawned via win32_spawnvp(P_NOWAIT, ...).
     */
    int i, retval;
    DWORD exitcode, waitcode;

    if (!w32_num_children) {
	errno = ECHILD;
	return -1;
    }

    /* if a child exists, wait for it to die */
    waitcode = WaitForMultipleObjects(w32_num_children,
				      w32_child_pids,
				      FALSE,
				      INFINITE);
    if (waitcode != WAIT_FAILED) {
	if (waitcode >= WAIT_ABANDONED_0
	    && waitcode < WAIT_ABANDONED_0 + w32_num_children)
	    i = waitcode - WAIT_ABANDONED_0;
	else
	    i = waitcode - WAIT_OBJECT_0;
	if (GetExitCodeProcess(w32_child_pids[i], &exitcode) ) {
	    CloseHandle(w32_child_pids[i]);
	    *status = (int)((exitcode & 0xff) << 8);
	    retval = (int)w32_child_pids[i];
	    Copy(&w32_child_pids[i+1], &w32_child_pids[i],
		 (w32_num_children-i-1), HANDLE);
	    w32_num_children--;
	    return retval;
	}
    }

FAILED:
    errno = GetLastError();
    return -1;

#endif
}

int CPerlProc::Setuid(uid_t u)
{
    return (u == ROOT_UID ? 0 : -1);
}

int CPerlProc::Setgid(gid_t g)
{
    return (g == ROOT_GID ? 0 : -1);
}

Sighandler_t CPerlProc::Signal(int sig, Sighandler_t subcode)
{
	return 0;
}

void CPerlProc::GetSysMsg(char*& sMsg, DWORD& dwLen, DWORD dwErr)
{
	dwLen = FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER
			  |FORMAT_MESSAGE_IGNORE_INSERTS
			  |FORMAT_MESSAGE_FROM_SYSTEM, NULL,
			   dwErr, 0, (char *)&sMsg, 1, NULL);
    if (0 < dwLen) {
	while (0 < dwLen  &&  isspace(sMsg[--dwLen]))
	    ;
	if ('.' != sMsg[dwLen])
	    dwLen++;
	sMsg[dwLen]= '\0';
    }
    if (0 == dwLen) {
	sMsg = (char*)LocalAlloc(0, 64/**sizeof(TCHAR)*/);
	dwLen = sprintf(sMsg,
			"Unknown error #0x%lX (lookup 0x%lX)",
			dwErr, GetLastError());
    }
}

void CPerlProc::FreeBuf(char* sMsg)
{
    LocalFree(sMsg);
}

BOOL CPerlProc::DoCmd(char *cmd)
{
    Spawn(cmd, EXECF_EXEC);
    return FALSE;
}

int CPerlProc::Spawn(char* cmd)
{
    return Spawn(cmd, EXECF_SPAWN);
}

int CPerlProc::Spawnvp(int mode, const char *cmdname, const char *const *argv)
{
    int status;

    status = spawnvp(mode, cmdname, (char * const *)argv);
#ifndef __BORLANDC__
    /* XXX For the P_NOWAIT case, Borland RTL returns pinfo.dwProcessId
     * while VC RTL returns pinfo.hProcess. For purposes of the custom
     * implementation of win32_wait(), we assume the latter.
     */
    if (mode == P_NOWAIT && status >= 0)
	w32_child_pids[w32_num_children++] = (HANDLE)status;
#endif
    return status;
}




