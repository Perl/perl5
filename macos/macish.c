/*********************************************************************
Project	:	Perl5				-	
File	:	macish.c			-	Mac specific things
Author	:	Matthias Neeracher

*********************************************************************/

#define MAC_CONTEXT
#define MP_EXT
#define MP_INIT(x) = x

#include "EXTERN.h"
#include "perl.h"

#include <Resources.h>
#include <Folders.h>
#include <GUSIFileSpec.h>
#undef modff
#include <fp.h>
#include <LowMem.h>
#include <Timer.h>

char **environ;
static  char ** gEnviron;
static	char *	gEnvpool;

/* Borrowed from msdos.c
 * Just pretend that everyone is a superuser
 */
/* DISPATCH_START */
#define ROOT_UID	0
#define ROOT_GID	0

Uid_t
(getuid)(void)
{
	return ROOT_UID;
}

Uid_t
(geteuid)(void)
{
	return ROOT_UID;
}

Gid_t
(getgid)(void)
{
	return ROOT_GID;
}

Gid_t
(getegid)(void)
{
	return ROOT_GID;
}

int
(setuid)(Uid_t uid)
{ 
	return (uid==ROOT_UID?0:-1);
}

int
(setgid)(Gid_t gid)
{ 
	return (gid==ROOT_GID?0:-1); 
}

Pid_t (getpid)()
{
	return 1;
}

#undef execv
int (execv)(const char * file, char * const * argv)
{
	dTHX;
	Perl_croak(aTHX_ "execv() not implemented on the Macintosh");
	
	errno = EINVAL;
	return -1;
}

#undef execvp
int (execvp)(const char * path, char * const * argv)
{
	dTHX;
	Perl_croak(aTHX_ "execvp() not implemented on the Macintosh");
	
	errno = EINVAL;
	return -1;
}

/* for now, kill will just return 0, maybe do more later once we
   get fork emulation */
int kill(Pid_t pid, int sig)
{
	if (sig != 0) {
		dTHX;
		Perl_croak(aTHX_ PL_no_func, "Unsupported function kill");
	}

	errno = EINVAL;
	return -1;
}


static char *
setup_argstr(SV *really, SV **mark, SV **sp)
{
  dTHX;
  char *junk, *tmps = Nullch;
  register size_t cmdlen = 0;
  size_t rlen;
  register SV **idx;

  idx = mark;
  if (really) {
    tmps = SvPV(really,rlen);
    if (*tmps) {
      cmdlen += rlen + 1;
      idx++;
    }
  }
  
  for (idx++; idx <= sp; idx++) {
    if (*idx) {
      junk = SvPVx(*idx,rlen);
      cmdlen += rlen ? rlen + 1 : 0;
    }
  }
  New(401,PL_Cmd,cmdlen,char);

  if (tmps && *tmps) {
    strcpy(PL_Cmd,tmps);
    mark++;
  }
  else *PL_Cmd = '\0';
  while (++mark <= sp) {
    if (*mark) {
      strcat(PL_Cmd," ");
      strcat(PL_Cmd,SvPVx(*mark,PL_na));
    }
  }
  return PL_Cmd;
}  /* end of setup_argstr() */

int do_spawn(char * command)
{
   dTHX;
   Sfio_t * temp = my_popen(command, "r");
    char *   data;
    
    while (data = sfreserve(temp, -1, 0))
	write(1, data, sfslen());
	
    my_pclose(temp);
	
	return 0;
}

int do_aspawn(SV *really,SV **mark,SV **sp)
{
  if (sp > mark) {
    return do_spawn(setup_argstr(really,mark,sp));
  }

  return -1;
}  /* end of do_aspawn() */

bool
Perl_do_exec(pTHX_ char *cmd)
{
    Perl_croak(aTHX_ "exec? I'm not *that* kind of operating system");
	
	return false;
}

char * sys_errlist[] = {
	"No error",
	"Operation not permitted",
	"No such file or directory",
	"No such process",
	"Interrupted system call",
	"Input/output error",
	"Device not configured",
	"Argument list too long",
	"Exec format error",
	"Bad file descriptor",
	"No child processes",
	"Operation would block",
	"Cannot allocate memory",
	"Permission denied",
	"Bad address",
	"Block device required",
	"Device busy",
	"File exists",
	"Cross-device link",
	"Operation not supported by device",
	"Not a directory",
	"Is a directory",
	"Invalid argument",
	"Too many open files in system",
	"Too many open files",
	"Inappropriate ioctl for device",
	"Text file busy",
	"File too large",
	"No space left on device",
	"Illegal seek",
	"Read-only file system",
	"Too many links",
	"Broken pipe",
	"Numerical argument out of domain",
	"Result too large",
	"(unknown)",
	"Operation now in progress",
	"Operation already in progress",
	"Socket operation on non-socket",
	"Destination address required",
	"Message too long",
	"Protocol wrong type for socket",
	"Protocol not available",
	"Protocol not supported",
	"Socket type not supported",
	"Operation not supported on socket",
	"Protocol family not supported",
	"Address family not supported by protocol family",
	"Address already in use",
	"Can't assign requested address",
	"Network is down",
	"Network is unreachable",
	"Network dropped connection on reset",
	"Software caused connection abort",
	"Connection reset by peer",
	"No buffer space available",
	"Socket is already connected",
	"Socket is not connected",
	"Can't send after socket shutdown",
	"Too many references: can't splice",
	"Connection timed out",
	"Connection refused",
	"Too many levels of symbolic links",
	"File name too long",
	"Host is down",
	"No route to host",
	"Directory not empty",
	"Too many processes",
	"Too many users",
	"Disc quota exceeded",
	"Stale NFS file handle",
	"Too many levels of remote in path",
	"RPC struct is bad",
	"RPC version wrong",
	"RPC prog. not avail",
	"Program version wrong",
	"Bad procedure for program",
	"No locks available",
	"Function not implemented",
	"Inappropriate file type or format",
	0
};

void
prime_env_iter(void)
/* Fill the %ENV associative array with all logical names we can
 * find, in preparation for iterating over it.
 */
{
  dTHX;
	
  HV *envhv;
  char **env;
  STRLEN len;

  if (!gMacPerl_MustPrime || !PL_envgv) return;
  envhv = GvHVn(PL_envgv);
  gMacPerl_MustPrime = false;
  /* Perform a dummy fetch as an lval to insure that the hash table is
   * set up.  Otherwise, the hv_store() will turn into a nullop */
  (void) hv_fetch(envhv,"DEFAULT",7,TRUE);
  (void) hv_delete(envhv,"DEFAULT",7,G_DISCARD);
  for (env = environ; *env; ++env) {
    SV *sv;
    len = strchr(*env, '=') - *env;
    sv = newSVpv(*env+len+1, 0);
    SvTAINTED_on(sv);
    hv_store(envhv,*env,len,sv,0);
  }
}  /* end of prime_env_iter */

int OverrideExtract(char * origname)
{
    char	     file[256];
	
    strcpy(file+1, MacPerl_MPWFileName(origname));
    file[0] = strlen(file+1);
    ParamText((StringPtr) file, "\p", "\p", "\p");
	
    return Alert(270, (ModalFilterUPP) nil) == 1;
}

char * MacPerl_MPWFileName(char * file)
{
    if (!strcmp(file, "Dev:Pseudo"))
    	return gMacPerl_PseudoFileName;
    else if (!strncmp(file, "Dev:Pseudo:", 11))
    	return file + 11;
    else
    	return file;
}


Boolean EqualEnv(const char * search, const char * env)
{
	while (*search) {
		if (toupper(*search) != toupper(*env))
			return false;
		++search;
		++env;
	}
	
	return !*env || *env == '=';
}

char ** init_env(char ** env)
{
	int		envcnt		=	0;
	int		envsize		=	0;
	int		varlen;
	char *	envpool;
	Boolean seenUser	=	false;
	Boolean seenTmpDir	=	false;
	Handle	userString;
	FSSpec	tmpspec;
	
	gMacPerl_MustPrime = true;
	
	for (envcnt = 0; env[envcnt]; envcnt++)	{
		varlen	= strlen(env[envcnt]);
		envsize	+=	varlen+strlen(env[envcnt]+varlen+1)+2;
		if (!seenUser)
			seenUser = EqualEnv(env[envcnt], "USER");
		if (!seenTmpDir)
			seenTmpDir = EqualEnv(env[envcnt], "TMPDIR");
	}
	if (!seenUser) {
		userString = GetResource('STR ', -16096);
		++envcnt;
		envsize += GetHandleSize(userString)+5;
	}
	if (!seenTmpDir) {
		FindFolder(
			kOnSystemDisk, kTemporaryFolderType, true, 
			&tmpspec.vRefNum, &tmpspec.parID);
		GUSIFSpUp(&tmpspec);
		++envcnt;
		envsize += strlen(GUSIFSp2FullPath(&tmpspec))+9;
	}
	
	if (gEnvpool) {
		Safefree(gEnviron);
		Safefree(gEnvpool);
	}
	
	New(50, gEnviron, envcnt+1, char *);
	New(50, gEnvpool, envsize, char);
	
	environ = gEnviron;
	envpool = gEnvpool;
	for (envcnt = 0; env[envcnt]; envcnt++)	{
		environ[envcnt] 	= envpool;
		varlen				= strlen(env[envcnt]);
		strcpy(envpool, env[envcnt]);
		envpool			  += varlen+1;
		envpool[-1]			= '=';
		strcpy(envpool, env[envcnt]+varlen+1);
		envpool			  += strlen(env[envcnt]+varlen+1)+1;
	}
	if (!seenUser) {
		char state = HGetState(userString);
		HLock(userString);
		environ[envcnt++] 	= envpool;
		strcpy(envpool, "USER=");
		envpool += 5;
		BlockMoveData(*userString+1, envpool, **userString);
		HSetState(userString, state);
		envpool	+= **userString;
		*envpool++ = 0;
	}
	if (!seenTmpDir) {
		environ[envcnt++] 	= envpool;
		strcpy(envpool, "TMPDIR=");
		envpool += 7;
		strcpy(envpool, GUSIFSp2FullPath(&tmpspec));
	}

	environ[envcnt] = 0;
	
	return environ;
}	

void install_env(Handle env)
{
	int		envcnt	=	0;
	int		envsize	=	0;
	int		varlen;
	char *	envpool;
	char * 	max;
	char 		state;
	
	if (gEnvpool) {
		Safefree(environ);
		Safefree(gEnvpool);
	}

	New(50, gEnvpool, GetHandleSize(env), char);
	
	state = HGetState(env);
	HLock(env);
	BlockMove(*env, (Ptr)gEnvpool, GetHandleSize(env));
	HSetState(env, state);
	
	envpool = gEnvpool;
	max = envpool + GetHandleSize(env);
	while (envpool < max) {
		++envcnt;
		envpool += strlen(envpool)+1;
	}
	
	New(50, environ, envcnt+1, char *);
	
	envpool = gEnvpool;
	envcnt  = 0;
	while (envpool < max) {
		environ[envcnt++] 	= envpool;
		envpool					+= strlen(envpool)+1;
	}

	environ[envcnt] = 0;
}

#ifndef __CFM68K__
char * (getenv)(const char * env)
{
	int 	l = strlen(env);
	char ** 	e;

	if (strEQ(env, "PERL5DB") && gMacPerl_Perl5DB)
		return gMacPerl_Perl5DB;

	for (e = environ; *e; ++e)
		if (EqualEnv(env, *e))
			return *e+l+1;

	return nil;
}
#endif

Handle retrieve_env()
{
	char ** envp = environ;
	Handle  env  = NewHandle(0);
	
	while (*envp) {
		PtrAndHand(*envp, env, strlen(*envp)+1);
		++envp;
	}
	
	return env;
}

typedef struct PD {
	struct PD *	next;
	FILE *		tempFile;
	FSSpec		pipeFile;
	char *		execute;
	long		status;
} PipeDescr, *PipeDescrPtr;

static PipeDescrPtr	pipes		=	nil;
static Boolean		sweeper	=	false;

void sweep(pTHX_ void * p)
{		
	while (pipes)
		my_pclose(pipes->tempFile);
	sweeper = false;
}

typedef struct WEPDesc {
	struct WEPDesc *		next;
	const char *			command;
	MacPerl_EmulationProc 	proc;
} WEPDesc, * WEPDescPtr;

static WEPDescPtr	 	gEmulators[128];
static Boolean			gHasEmulators = false;

void AddWriteEmulationProc(const char * command, MacPerl_EmulationProc proc)
{
	WEPDescPtr	wepdesc 	= (WEPDescPtr) malloc(sizeof(WEPDesc));
	
	wepdesc->next 			= 	gEmulators[*command];
	wepdesc->command		=	command;
	wepdesc->proc			=	proc;
	gEmulators[*command]	=	wepdesc;
}

MacPerl_EmulationProc FindWriteEmulationProc(char * command, char ** rest)
{
	char * 		end;
	WEPDescPtr	queue;
	
	for (end = command; isalnum(*end); ++end);
	
	if (end == command || (*command & 0x80))
		return nil;
	
	for (queue = gEmulators[*command]; queue; queue = queue->next)
		if (!strncmp(command, queue->command, end-command))
			if (!queue->command[end-command]) {
				while (isspace(*end))
					++end;
				*rest = end;
				
				return queue->proc;
			}
	
	return nil;
}

static int EmulatePwd(PerlIO * tempFile, char * command)
{
	char curdir[256];
	
	if (!getcwd(curdir, 256)) 
		return -1;
	
	PerlIO_printf(tempFile, "%s\n", curdir);
	
	return 0;
}

static int EmulateHostname(PerlIO * tempFile, char * command)
{
	char curhostname[256];
	
	if (gethostname(curhostname, 256)) 
		return -1;
	
	PerlIO_printf(tempFile, "%s\n", curhostname);
	
	return 0;
}

PerlIO * Perl_my_popen(pTHX_ char * command, char * mode)
{
	PipeDescrPtr	pipe;
	
	if (!gHasEmulators) {
		gHasEmulators = true;
		AddWriteEmulationProc("pwd", (MacPerl_EmulationProc)EmulatePwd);
		AddWriteEmulationProc("directory", (MacPerl_EmulationProc)EmulatePwd);
		AddWriteEmulationProc("Directory", (MacPerl_EmulationProc)EmulatePwd);
		AddWriteEmulationProc("hostname", (MacPerl_EmulationProc)EmulateHostname);
	}
	
	if (!strcmp(command, "-"))
		Perl_croak(aTHX_ "Implicit fork() on a Mac? No forking chance");
	
	New(666, pipe, 1, PipeDescr);
	
	if (!pipe)
		return NULL;
		
	if (FSpMakeTempFile(&pipe->pipeFile))
		goto failed;
	pipe->execute	=	nil;
	
	switch(*mode)	{
	case 'r':
		{
			/* Ugh ! A hardcoded command  ! */
			MacPerl_EmulationProc proc = FindWriteEmulationProc(command, &command);
			
			if (proc) {
				if (!(pipe->tempFile	= PerlIO_open(GUSIFSp2FullPath(&pipe->pipeFile), "w")))
					goto delete;
				if (proc(pipe->tempFile, command))
					goto delete;
				PerlIO_close(pipe->tempFile);
			} else if (SubLaunch(command, nil, &pipe->pipeFile, &pipe->pipeFile, &pipe->status))
				goto delete;
			
			if (!(pipe->tempFile	= PerlIO_open(GUSIFSp2FullPath(&pipe->pipeFile), "r")))
				goto delete;
			break;
		}
	case 'w':
		New(667, pipe->execute, strlen(command)+1, char);
		if (!pipe->execute || !(pipe->tempFile	= PerlIO_open(GUSIFSp2FullPath(&pipe->pipeFile), "w")))
			goto delete;
		strcpy(pipe->execute, command);
		break;
	}
	
	pipe->next	=	pipes;
	pipes			=	pipe;
	
	if (!sweeper)	{
		Perl_call_atexit(aTHX_ sweep, NULL);
		sweeper	=	true;
	}

	return pipe->tempFile;
delete:
	if (pipe->execute)
		Safefree(pipe->execute);
	HDelete(pipe->pipeFile.vRefNum, pipe->pipeFile.parID, pipe->pipeFile.name);
failed:
	Safefree(pipe);
	
	return NULL;
}

I32 Perl_my_pclose(pTHX_ FILE * f)
{
	OSErr				err;
	PipeDescrPtr *	prev;
	PipeDescrPtr	pipe;
	
	for (prev = (PipeDescrPtr *) &pipes; pipe = *prev; prev = &pipe->next)
		if (pipe->tempFile == f)
			break;
	
	if (!pipe)
		return -1;
	
	*prev = pipe->next;
	
	PerlIO_close(f);
	
	if (pipe->execute)
		err = SubLaunch(pipe->execute, &pipe->pipeFile, nil, nil, &pipe->status);
	else
		err = noErr;
		
	HDelete(pipe->pipeFile.vRefNum, pipe->pipeFile.parID, pipe->pipeFile.name);
	if (pipe->execute)
		Safefree(pipe->execute);
	Safefree(pipe);
	
	return err? -1 : (int) pipe->status;	
}

StringPtr MacPerl_CopyC2P(const char * c, StringPtr p)
{
	memcpy(p+1, c, *p = strlen(c));
	
	return p;
}

#ifdef __SC__
double Perl_modf(double x, double * iptr)
{
	long double i;
	long double res;
	
	res 	= modf(x, &i);
	*iptr	= i;
	
	return res;
}
#endif

#if defined(__SC__) || defined(__MRC__)
double Perl_atof(const char *s)
{
	double f = atof(s);
	
	return isnan(f) ? 0.0 : f;
}
#endif

const char * MacPerl_CanonDir(const char * dir, char * buf)
{
	char * out = buf;
	char * slash;
	struct stat s;
	
	if (!strchr(dir, ':'))
		*out++ = ':';
	
	if (!stat(dir, &s))
		goto done;

	while (dir[0] == '.') {
		switch (dir[1]) {
		case NULL:
			if (out == buf)
				*out++ = ':';
			dir += 1;
			break;
		case '/':
			if (out == buf)
				*out++	= ':';
			dir += 2;
			continue;
		case '.':
			if (dir[2] == '/') {
				if (out == buf)
					*out++	= ':';
				*out++ = ':';
			} 
			dir += 3;
			continue;
		}
		break;
	}
	
	while (slash = strchr(dir, '/')) {
		memcpy(out, dir, slash-dir);
		out += slash-dir;
		*out++ = ':';
		for (;;) {
			while (*++slash == '/')
				;
			if (slash[0] == '.') {
				switch (slash[1]) {
				case '/':
					slash = slash+2;
					break;
				case '.':
					if (slash[2] == '/') {
						*out++ = ':';
						slash = slash+3;
						break;
					}
				default:
					goto nomoreslashes;
				}
			}
		}
nomoreslashes:
		dir = slash;
	}
done:
	strcpy(out, dir);
	out += strlen(out);
	if (out[-1] != ':')
		*out++ = ':';
	*out = 0;

	return buf;
}

void MacPerl_WaitEvent(Boolean busy, long sleep, RgnHandle rgn) 
{
	EventRecord ev;
	
	if (WaitNextEvent(highLevelEventMask, &ev, (sleep==-1 ? 0 : sleep), rgn)) {
		if (ev.what == kHighLevelEvent) {
			AEProcessAppleEvent(&ev);	/* Ignore errors */
		}
	}
}

clock_t MacPerl_times(struct tms * t)
{
	t->tms_utime = clock() - gMacPerl_StartClock;
	t->tms_stime = 0;
	t->tms_cutime = 0;
	t->tms_cstime = 0;
	
	return t->tms_utime;
}

/********************* Asynchronous Event management ************
 * MacPerl maintains an os queue of tasks to be executed at a 
 * reasonably "sane" time (in runops, to be more exact).
 */

static QHdr sMacPerlAsyncQueue;

Boolean MacPerl_QueueAsyncTask(MacPerl_AsyncTask * task)
{
	if (task->fPending) /* Already queued. Race condition resolved below */
		return false;
	task->fPending = true;
	if (!Dequeue((QElemPtr) task, &sMacPerlAsyncQueue)) /* Just in case somebody beat us in the race */
		return false;
	Enqueue((QElemPtr) task, &sMacPerlAsyncQueue);
	
	gMacPerl_HasAsyncTasks = true;	/* Flag for main loop to call async event processing */
	
	return true;
}

void MacPerl_DoAsyncTasks()
{
	QElemPtr			elem;
	MacPerl_AsyncTask * task;
	
	gMacPerl_HasAsyncTasks = false; /* Though this might be set again while we process */
	while (elem = sMacPerlAsyncQueue.qHead) {
		Dequeue(elem, &sMacPerlAsyncQueue);
		task = (MacPerl_AsyncTask *) elem;	/* Remove from queue */
		task->fProc(task);						/* Call procedure */
		task->fPending = false;					/* Allow it to be queued again */
	}
}

void MacPerl_ClearAsyncTasks()
{
	QElemPtr			elem;
	MacPerl_AsyncTask * task;
	
	gMacPerl_HasAsyncTasks = false;
	while (elem = sMacPerlAsyncQueue.qHead) {
		Dequeue(elem, &sMacPerlAsyncQueue);
	}
}

/*
 * Asynchronous tasks come in handy to exit gracefully from the middle of a script
 */
static MacPerl_AsyncTask	sAsyncExit;
static int					sExitStatus;

static void AsyncExit(MacPerl_AsyncTask * task) 
{
	dTHX;
	
	my_exit(sExitStatus);
}

void _exit(int status)
{
	if (MacPerl_QueueAsyncTask(&sAsyncExit))
		sExitStatus = status;
}

/********************* Cursor Spin management *******************
 * The other built in asynchronous task is cursor spinning.
 */

static struct SpinControlRec {
	TMTask				fTimer;
	MacPerl_AsyncTask	fTask;
} sSpinControl;

#define SPIN_FREQUENCY	200

static void SpinTimer(struct SpinControlRec * spin)
{
	MacPerl_QueueAsyncTask(&spin->fTask);	/* Queue task for a safe time */
	PrimeTime((QElem *) &spin->fTimer, SPIN_FREQUENCY);
}

#if GENERATINGCFM
static RoutineDescriptor	uSpinTimer =
		BUILD_ROUTINE_DESCRIPTOR(uppTimerProcInfo, SpinTimer);
#elif defined(__MWERKS__)
static pascal void uSpinTimer(struct SpinControlRec * param : __A1) { SpinTimer(param); }
#else
void * GetA1()  ONEWORDINLINE(0x2009);
static pascal void uSpinTimer() 		\
		{ SpinTimer((struct SpinControlRec *)GetA1()); }
#endif

static void SpinMacCursor(MacPerl_AsyncTask * task) 
{
	sleep(0);
}

static void StopSpinControl()
{	
	RmvTime((QElem *) &sSpinControl.fTimer);
}

/*
 * It seeems that calling Perl_call_atexit at init time is suicidal, so
 * we don't kick off the whole thing until we are well within the interpreter
 */

static void StartSpinControl(MacPerl_AsyncTask * task)
{
  	dTHX;
	
	sSpinControl.fTimer.tmAddr		=	(TimerUPP)&uSpinTimer;
	sSpinControl.fTimer.tmCount		=	0;
	sSpinControl.fTimer.tmWakeUp	=	0;
	sSpinControl.fTimer.tmReserved	=	0;
	sSpinControl.fTask.fProc		= 	SpinMacCursor;
		
	InsTime((QElem *) &sSpinControl.fTimer);
	PrimeTime((QElem *) &sSpinControl.fTimer, SPIN_FREQUENCY);

	Perl_call_atexit(aTHX_ StopSpinControl, NULL);
}

void MacPerl_init()
{
	gMacPerl_StartClock = LMGetTicks();

	MacPerl_ClearAsyncTasks();

	sSpinControl.fTask.fPending		=  	false;
	sSpinControl.fTask.fProc		= 	StartSpinControl;

	sAsyncExit.fPending				=  	false;
	sAsyncExit.fProc				= 	AsyncExit;

	MacPerl_QueueAsyncTask(&sSpinControl.fTask);
}

void
Perl_my_setenv(pTHX_ char *env, char *val)
{
	/* A hack just to get this darn thing working */
	if (strEQ(env, "PERL5DB"))
		gMacPerl_Perl5DB = val;
}

static const char * strnstr(const char * msg, const char * str, int len)
{
	char s1 = *str++;
	
	while (len-- > 0)
		if (*msg++ == s1) {
			const char * s = str;
			const char * m = msg;
			
			while (*s && *s == *m)
				++s, ++m;
			
			if (!*s)
				return msg-1;
		}
	return NULL;
}

static void WriteMsgLn(PerlIO * io, const char * msg, size_t len, Boolean start)
{
	if (start)
		PerlIO_write(io, "# ", 2);
	PerlIO_write(io, msg, len);
}

static void WriteMsg(PerlIO * io, const char * msg, size_t len, Boolean start)
{
	const char * nl;
	
	while (nl = (const char *)memchr(msg, '\n', len)) {
		WriteMsgLn(io, msg, nl-msg+1, start);
		start 	= true;
		len		= msg+len-nl-1;
		msg 	= nl+1;
	}
	if (len)
		WriteMsgLn(io, msg, len, start);
}

void MacPerl_WriteMsg(void * io, const char * msg, size_t len)
{
	const char * line= msg;
	const char * at;

	if (!gMacPerl_ErrorFormat) {
		PerlIO_write(io, msg, len);
		return;
	}

	/* Look for " line \d" */
	while (line = strnstr(line+1, " line ", msg+len-line-1)) {
		/* Invariants:
		 * To process: [msg, msg+len[
		 * msg < line < msg+len
		 */
		if (line[6] >= '0' && line[6] <= '9') {
			/* Got line, now look for end of line number */
			const char * endline = line+7;
			const char * newline;
			
			while (*endline >= '0' && *endline <= '9' && endline < msg+len)
				++endline;
			if (*endline == ' ' && endline < msg+len)
				++endline;
			for (newline = endline; *newline != '\n' && newline < msg+len; ++newline)
				;
			if (*newline == '\n' && newline < msg+len)
				++newline;
				
			/* Got it, now look for preceding " at ." length reduced by 4 because file name
			 * must be at least 1 character long.
			 */
			at	= strnstr(msg, " at ", line-msg-4);
	
			if (at) {
				/* msg <= at < line */
				const char * anotherat;
				
				/* Look for intervening "at". This part gives misleading results if the filename
				 * itself contains an at.
				 */
				while (anotherat = strnstr(at+4, " at ", line-at-5))
					at = anotherat;
					
				/* OK, we got them both, write the original message prefixed with # */
				WriteMsg(io, msg, at-msg, true);
				if (newline > endline) {
					switch (*endline) {
					case ',':
					case '.':
					case ';':
					case '\t':
					case '\n':
						break;
					default:
						PerlIO_write(io, " ", 1);
						break;
					}
					PerlIO_write(io, endline, newline-endline);
				}
				PerlIO_write(io, "File \'", 6);
				PerlIO_write(io, at+4, line-at-4);
				PerlIO_write(io, "\'; Line ", 8);
				PerlIO_write(io, line+6, endline-line-6);
				PerlIO_write(io, "\n", 1);
				
				len    -= newline-msg;
				msg 	= newline;
				line	= msg;
				
				if (!len)	/* We're done */
					return;
			}
		}
	}
	/* No file/line found */
	WriteMsg(io, msg, len, true);
}

void MacPerl_Exit(int status) 
{
	dTHX;
	
	my_exit(status);
}
