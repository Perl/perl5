/* WIN32.C
 *
 * (c) 1995 Microsoft Corporation. All rights reserved. 
 * 		Developed by hip communications inc., http://info.hip.com/info/
 * Portions (c) 1993 Intergraph Corporation. All rights reserved.
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#define WIN32_LEAN_AND_MEAN
#define WIN32IO_IS_STDIO
#include <tchar.h>
#include <windows.h>

/* #include "config.h" */

#define PERLIO_NOT_STDIO 0 
#if !defined(PERLIO_IS_STDIO) && !defined(USE_SFIO)
#define PerlIO FILE
#endif

#include "EXTERN.h"
#include "perl.h"
#include <fcntl.h>
#include <sys/stat.h>
#include <assert.h>
#include <string.h>
#include <stdarg.h>

#define CROAK croak
#define WARN warn

extern WIN32_IOSUBSYSTEM	win32stdio;
__declspec(thread) PWIN32_IOSUBSYSTEM	pIOSubSystem = &win32stdio;
/*__declspec(thread) PWIN32_IOSUBSYSTEM	pIOSubSystem = NULL;*/

BOOL  ProbeEnv = FALSE;
DWORD Win32System;
char  szShellPath[MAX_PATH+1];
char  szPerlLibRoot[MAX_PATH+1];
HANDLE PerlDllHandle = INVALID_HANDLE_VALUE;

#define IsWin95()	(Win32System == VER_PLATFORM_WIN32_WINDOWS)
#define IsWinNT()	(Win32System == VER_PLATFORM_WIN32_NT)

void *
SetIOSubSystem(void *p)
{
    if (p) {
	PWIN32_IOSUBSYSTEM pio = (PWIN32_IOSUBSYSTEM)p;

	if (pio->signature_begin == 12345678L
	    && pio->signature_end == 87654321L) {
	    PWIN32_IOSUBSYSTEM pold = pIOSubSystem;
	    pIOSubSystem = pio;
	    return pold;
	}
    }
    else {
	/* re-assign our stuff */
/*	pIOSubSystem = &win32stdio; */
	pIOSubSystem = NULL;
    }
    return pIOSubSystem;
}

char *
win32PerlLibPath(void)
{
    char *end;
    GetModuleFileName((PerlDllHandle == INVALID_HANDLE_VALUE) 
		      ? GetModuleHandle(NULL)
		      : PerlDllHandle,
		      szPerlLibRoot, 
		      sizeof(szPerlLibRoot));

    *(end = strrchr(szPerlLibRoot, '\\')) = '\0';
    if (stricmp(end-4,"\\bin") == 0)
     end -= 4;
    strcpy(end,"\\lib");
    return (szPerlLibRoot);
}

BOOL
HasRedirection(char *ptr)
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

/* since the current process environment is being updated in util.c
 * the library functions will get the correct environment
 */
PerlIO *
my_popen(char *cmd, char *mode)
{
#ifdef FIXCMD
#define fixcmd(x)	{					\
			    char *pspace = strchr((x),' ');	\
			    if (pspace) {			\
				char *p = (x);			\
				while (p < pspace) {		\
				    if (*p == '/')		\
					*p = '\\';		\
				    p++;			\
				}				\
			    }					\
			}
#else
#define fixcmd(x)
#endif

#if 1
/* was #ifndef PERLDLL, but the #else stuff doesn't work on NT
 * GSAR 97/03/13
 */
    fixcmd(cmd);
    return win32_popen(cmd, mode);
#else
/*
 * There seems to be some problems for the _popen call in a DLL
 * this trick at the moment seems to work but it is never test
 * on NT yet
 *
 */ 
#	ifdef __cplusplus
#define EXT_C_FUNC	extern "C"
#	else
#define EXT_C_FUNC	extern
#	endif

    EXT_C_FUNC int __cdecl _set_osfhnd(int fh, long value);
    EXT_C_FUNC void __cdecl _lock_fhandle(int);
    EXT_C_FUNC void __cdecl _unlock_fhandle(int);

    BOOL	fSuccess;
    PerlIO	*pf;		/* to store the _popen return value */
    int		tm = 0;		/* flag indicating tDllExport or binary mode */
    int		fhNeeded, fhInherited, fhDup;
    int		ineeded, iinherited;
    DWORD	dwDup;
    int		phdls[2];	/* I/O handles for pipe */
    HANDLE	hPIn, hPOut, hPErr,
		hSaveStdin, hSaveStdout, hSaveStderr,
		hPNeeded, hPInherited, hPDuped;
     
    /* first check for errors in the arguments */
    if ( (cmd == NULL) || (mode == NULL)
	 || ((*mode != 'w') && (*mode != _T('r'))) )
	goto error1;

    if ( *(mode + 1) == _T('t') )
	tm = _O_TEXT;
    else if ( *(mode + 1) == _T('b') )
	tm = _O_BINARY;
    else
	tm = (*mode == 'w' ? _O_BINARY : _O_TEXT);


    fixcmd(cmd);
    if (&win32stdio != pIOSubSystem)
	return win32_popen(cmd, mode);

#ifdef EFG
    if ( _pipe( phdls, 1024, tm ) == -1 )
#else
    if ( win32_pipe( phdls, 1024, tm ) == -1 )
#endif
	goto error1;

    /* save the current situation */
    hSaveStdin = GetStdHandle(STD_INPUT_HANDLE); 
    hSaveStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    hSaveStderr = GetStdHandle(STD_ERROR_HANDLE); 

    if (*mode == _T('w')) {
	ineeded = 1;
	dwDup	= STD_INPUT_HANDLE;
	iinherited = 0;
    }
    else {
	ineeded = 0;
	dwDup	= STD_OUTPUT_HANDLE;
	iinherited = 1;
    }

    fhNeeded = phdls[ineeded];
    fhInherited = phdls[iinherited];

    fSuccess = DuplicateHandle(GetCurrentProcess(), 
			       (HANDLE) stolen_get_osfhandle(fhNeeded), 
			       GetCurrentProcess(), 
			       &hPNeeded, 
			       0, 
			       FALSE,       /* not inherited */ 
			       DUPLICATE_SAME_ACCESS); 

    if (!fSuccess)
	goto error2;

    fhDup = stolen_open_osfhandle((long) hPNeeded, tm);
    win32_dup2(fhDup, fhNeeded);
    win32_close(fhDup);

#ifdef AAA
    /* Close the Out pipe, child won't need it */
    hPDuped = (HANDLE) stolen_get_osfhandle(fhNeeded);

    _lock_fhandle(fhNeeded);
    _set_osfhnd(fhNeeded, (long)hPNeeded); /* put in ours duplicated one */
    _unlock_fhandle(fhNeeded);

    CloseHandle(hPDuped);	/* close the handle first */
#endif

    if (!SetStdHandle(dwDup, (HANDLE) stolen_get_osfhandle(fhInherited)))
	goto error2;

    /*
     * make sure the child see the same stderr as the calling program
     */
    if (!SetStdHandle(STD_ERROR_HANDLE,
		      (HANDLE)stolen_get_osfhandle(win32_fileno(win32_stderr()))))
	goto error2;

    pf = win32_popen(cmd, mode);	/* ask _popen to do the job */

    /* restore to where we were */
    SetStdHandle(STD_INPUT_HANDLE, hSaveStdin);
    SetStdHandle(STD_OUTPUT_HANDLE, hSaveStdout);
    SetStdHandle(STD_ERROR_HANDLE, hSaveStderr);

    /* we don't need it any more, that's for the child */
    win32_close(fhInherited);

    if (NULL == pf) {
	/* something wrong */
	win32_close(fhNeeded);
	goto error1;
    }
    else {
	/*
	 * here we steal the file handle in pf and stuff ours in
	 */
	win32_dup2(fhNeeded, win32_fileno(pf));
	win32_close(fhNeeded);
    }
    return (pf);

error2:
    win32_close(fhNeeded);
    win32_close(fhInherited);

error1:
    return (NULL);

#endif
}

long
my_pclose(PerlIO *fp)
{
    return win32_pclose(fp);
}

static void
IdOS(void)
{
    OSVERSIONINFO osver;

    memset(&osver, 0, sizeof(OSVERSIONINFO));
    osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
    GetVersionEx(&osver);
    Win32System = osver.dwPlatformId;
    return;
}

static char *
GetShell(void)
{
    static char* szWin95ShellEntry = "Win95Shell";
    static char* szWin95DefaultShell = "Cmd32.exe";
    static char* szWinNTDefaultShell = "cmd.exe";
   
    if (!ProbeEnv) {
	IdOS(), ProbeEnv = TRUE;
	if (IsWin95()) {
	    strcpy(szShellPath, szWin95DefaultShell);
	}
	else {
	    strcpy(szShellPath, szWinNTDefaultShell);
	}
    }
    return szShellPath;
}

int
do_aspawn(void* really, void** mark, void** arglast)
{
    char **argv;
    char *strPtr;
    char *cmd;
    int status;
    unsigned int length;
    int index = 0;
    SV *sv = (SV*)really;
    SV** pSv = (SV**)mark;

    New(1110, argv, (arglast - mark) + 3, char*);

    if(sv != Nullsv) {
	cmd = SvPV(sv, length);
    }
    else {
	cmd = GetShell();
	argv[index++] = "/c";
    }

    while(pSv <= (SV**)arglast) {
	sv = *pSv++;
	strPtr = SvPV(sv, length);
	if(strPtr != NULL && *strPtr != '\0')
	    argv[index++] = strPtr;
    }
    argv[index++] = 0;
   
    status = win32_spawnvpe(P_WAIT, cmd, (const char* const*)argv,
			    (const char* const*)environ);

    Safefree(argv);

    /* set statusvalue the perl variable $? */
    return (statusvalue = status*256);
}

int
do_spawn(char *cmd)
{
    char **a;
    char *s;
    char **argv;
    int status = -1;
    BOOL needToTry = TRUE;
    char *shell, *cmd2;

    /* save an extra exec if possible */
    shell = GetShell();

    /* see if there are shell metacharacters in it */
    if(!HasRedirection(cmd)) {
	New(1102,argv, strlen(cmd) / 2 + 2, char*);
	New(1103,cmd2, strlen(cmd) + 1, char);
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
	if(argv[0]) {
	    status = win32_spawnvpe(P_WAIT,
				    argv[0],
				    (const char* const*)argv,
				    (const char* const*)environ);
	    if(status != -1 || errno == 0)
		needToTry = FALSE;
	}
	Safefree(argv);
	Safefree(cmd2);
    }
    if(needToTry) {
	status = win32_spawnle(P_WAIT,
			       shell,
			       shell,
			       "/c", cmd, (char*)0, environ);
    }

    /* set statusvalue the perl variable $? */
    return (statusvalue = status*256);
}


#define PATHLEN 1024

/* The idea here is to read all the directory names into a string table
 * (separated by nulls) and when one of the other dir functions is called
 * return the pointer to the current file name.
 */
DIR *
opendir(char *filename)
{
    DIR            *p;
    long            len;
    long            idx;
    char            scannamespc[PATHLEN];
    char       *scanname = scannamespc;
    struct stat     sbuf;
    WIN32_FIND_DATA FindData;
    HANDLE          fh;
/*  char            root[_MAX_PATH];*/
/*  char            volname[_MAX_PATH];*/
/*  DWORD           serial, maxname, flags;*/
/*  BOOL            downcase;*/
/*  char           *dummy;*/

    /* check to see if filename is a directory */
    if(stat(filename, &sbuf) < 0 || sbuf.st_mode & _S_IFDIR == 0) {
	return NULL;
    }

    /* get the file system characteristics */
/*  if(GetFullPathName(filename, MAX_PATH, root, &dummy)) {
 *	if(dummy = strchr(root, '\\'))
 *	    *++dummy = '\0';
 *	if(GetVolumeInformation(root, volname, MAX_PATH, &serial,
 *				&maxname, &flags, 0, 0)) {
 *	    downcase = !(flags & FS_CASE_IS_PRESERVED);
 *	}
 *  }
 *  else {
 *	downcase = TRUE;
 *  }
 */
    /* Get us a DIR structure */
    Newz(1501, p, 1, DIR);
    if(p == NULL)
	return NULL;

    /* Create the search pattern */
    strcpy(scanname, filename);

    if(index("/\\", *(scanname + strlen(scanname) - 1)) == NULL)
	strcat(scanname, "/*");
    else
	strcat(scanname, "*");

    /* do the FindFirstFile call */
    fh = FindFirstFile(scanname, &FindData);
    if(fh == INVALID_HANDLE_VALUE) {
	return NULL;
    }

    /* now allocate the first part of the string table for
     * the filenames that we find.
     */
    idx = strlen(FindData.cFileName)+1;
    New(1502, p->start, idx, char);
    if(p->start == NULL) {
	CROAK("opendir: malloc failed!\n");
    }
    strcpy(p->start, FindData.cFileName);
/*  if(downcase)
 *	strlwr(p->start);
 */
    p->nfiles++;

    /* loop finding all the files that match the wildcard
     * (which should be all of them in this directory!).
     * the variable idx should point one past the null terminator
     * of the previous string found.
     */
    while (FindNextFile(fh, &FindData)) {
	len = strlen(FindData.cFileName);
	/* bump the string table size by enough for the
	 * new name and it's null terminator
	 */
	Renew(p->start, idx+len+1, char);
	if(p->start == NULL) {
	    CROAK("opendir: malloc failed!\n");
	}
	strcpy(&p->start[idx], FindData.cFileName);
/*	if (downcase) 
 *	    strlwr(&p->start[idx]);
 */
		p->nfiles++;
		idx += len+1;
	}
	FindClose(fh);
	p->size = idx;
	p->curr = p->start;
	return p;
}


/* Readdir just returns the current string pointer and bumps the
 * string pointer to the nDllExport entry.
 */
struct direct *
readdir(DIR *dirp)
{
    int         len;
    static int  dummy = 0;

    if (dirp->curr) {
	/* first set up the structure to return */
	len = strlen(dirp->curr);
	strcpy(dirp->dirstr.d_name, dirp->curr);
	dirp->dirstr.d_namlen = len;

	/* Fake an inode */
	dirp->dirstr.d_ino = dummy++;

	/* Now set up for the nDllExport call to readdir */
	dirp->curr += len + 1;
	if (dirp->curr >= (dirp->start + dirp->size)) {
	    dirp->curr = NULL;
	}

	return &(dirp->dirstr);
    } 
    else
	return NULL;
}

/* Telldir returns the current string pointer position */
long
telldir(DIR *dirp)
{
    return (long) dirp->curr;
}


/* Seekdir moves the string pointer to a previously saved position
 *(Saved by telldir).
 */
void
seekdir(DIR *dirp, long loc)
{
    dirp->curr = (char *)loc;
}

/* Rewinddir resets the string pointer to the start */
void
rewinddir(DIR *dirp)
{
    dirp->curr = dirp->start;
}

/* free the memory allocated by opendir */
int
closedir(DIR *dirp)
{
    Safefree(dirp->start);
    Safefree(dirp);
    return 1;
}


/*
 * various stubs
 */


/* Ownership
 *
 * Just pretend that everyone is a superuser. NT will let us know if
 * we don\'t really have permission to do something.
 */

#define ROOT_UID    ((uid_t)0)
#define ROOT_GID    ((gid_t)0)

uid_t
getuid(void)
{
    return ROOT_UID;
}

uid_t
geteuid(void)
{
    return ROOT_UID;
}

gid_t
getgid(void)
{
    return ROOT_GID;
}

gid_t
getegid(void)
{
    return ROOT_GID;
}

int
setuid(uid_t uid)
{ 
    return (uid == ROOT_UID ? 0 : -1);
}

int
setgid(gid_t gid)
{
    return (gid == ROOT_GID ? 0 : -1);
}

/*
 * pretended kill
 */
int
kill(int pid, int sig)
{
    HANDLE hProcess= OpenProcess(PROCESS_ALL_ACCESS, TRUE, pid);

    if (hProcess == NULL) {
	CROAK("kill process failed!\n");
    }
    else {
	if (!TerminateProcess(hProcess, sig))
	    CROAK("kill process failed!\n");
	CloseHandle(hProcess);
    }
    return 0;
}
      
/*
 * File system stuff
 */

int
ioctl(int i, unsigned int u, char *data)
{
    CROAK("ioctl not implemented!\n");
    return -1;
}

unsigned int
sleep(unsigned int t)
{
    Sleep(t*1000);
    return 0;
}


#undef rename

int
myrename(char *OldFileName, char *newname)
{
    if(_access(newname, 0) != -1) {	/* file exists */
	_unlink(newname);
    }
    return rename(OldFileName, newname);
}


DllExport int
win32_stat(const char *path, struct stat *buffer)
{
    char		t[MAX_PATH]; 
    const char	*p = path;
    int		l = strlen(path);

    if (l > 1) {
	switch(path[l - 1]) {
	case '\\':
	case '/':
	    if (path[l - 2] != ':') {
		strncpy(t, path, l - 1);
		t[l - 1] = 0;
		p = t;
	    };
	}
    }
    return stat(p, buffer);
}

#undef times
int
mytimes(struct tms *timebuf)
{
    clock_t	t = clock();
    timebuf->tms_utime = t;
    timebuf->tms_stime = 0;
    timebuf->tms_cutime = 0;
    timebuf->tms_cstime = 0;

    return 0;
}

#undef alarm
unsigned int
myalarm(unsigned int sec)
{
    /* we warn the usuage of alarm function */
    if (sec != 0)
	WARN("dummy function alarm called, program might not function as expected\n");
    return 0;
}

/*
 *  redirected io subsystem for all XS modules
 *
 */

DllExport int *
win32_errno(void)
{
    return (pIOSubSystem->pfnerrno());
}

/* the rest are the remapped stdio routines */
DllExport FILE *
win32_stderr(void)
{
    return (pIOSubSystem->pfnstderr());
}

DllExport FILE *
win32_stdin(void)
{
    return (pIOSubSystem->pfnstdin());
}

DllExport FILE *
win32_stdout()
{
    return (pIOSubSystem->pfnstdout());
}

DllExport int
win32_ferror(FILE *fp)
{
    return (pIOSubSystem->pfnferror(fp));
}


DllExport int
win32_feof(FILE *fp)
{
    return (pIOSubSystem->pfnfeof(fp));
}

/*
 * Since the errors returned by the socket error function 
 * WSAGetLastError() are not known by the library routine strerror
 * we have to roll our own.
 */

__declspec(thread) char	strerror_buffer[512];

DllExport char *
win32_strerror(int e) 
{
    extern int sys_nerr;
    DWORD source = 0;

    if(e < 0 || e > sys_nerr) {
	if(e < 0)
	    e = GetLastError();

	if(FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, &source, e, 0,
			 strerror_buffer, sizeof(strerror_buffer), NULL) == 0) 
	    strcpy(strerror_buffer, "Unknown Error");

	return strerror_buffer;
    }
    return pIOSubSystem->pfnstrerror(e);
}

DllExport int
win32_fprintf(FILE *fp, const char *format, ...)
{
    va_list marker;
    va_start(marker, format);     /* Initialize variable arguments. */

    return (pIOSubSystem->pfnvfprintf(fp, format, marker));
}

DllExport int
win32_printf(const char *format, ...)
{
    va_list marker;
    va_start(marker, format);     /* Initialize variable arguments. */

    return (pIOSubSystem->pfnvprintf(format, marker));
}

DllExport int
win32_vfprintf(FILE *fp, const char *format, va_list args)
{
    return (pIOSubSystem->pfnvfprintf(fp, format, args));
}

DllExport size_t
win32_fread(void *buf, size_t size, size_t count, FILE *fp)
{
    return pIOSubSystem->pfnfread(buf, size, count, fp);
}

DllExport size_t
win32_fwrite(const void *buf, size_t size, size_t count, FILE *fp)
{
    return pIOSubSystem->pfnfwrite(buf, size, count, fp);
}

DllExport FILE *
win32_fopen(const char *filename, const char *mode)
{
    if (stricmp(filename, "/dev/null")==0)
	return pIOSubSystem->pfnfopen("NUL", mode);
    return pIOSubSystem->pfnfopen(filename, mode);
}

DllExport FILE *
win32_fdopen( int handle, const char *mode)
{
    return pIOSubSystem->pfnfdopen(handle, mode);
}

DllExport FILE *
win32_freopen( const char *path, const char *mode, FILE *stream)
{
    if (stricmp(path, "/dev/null")==0)
	return pIOSubSystem->pfnfreopen("NUL", mode, stream);
    return pIOSubSystem->pfnfreopen(path, mode, stream);
}

DllExport int
win32_fclose(FILE *pf)
{
    return pIOSubSystem->pfnfclose(pf);
}

DllExport int
win32_fputs(const char *s,FILE *pf)
{
    return pIOSubSystem->pfnfputs(s, pf);
}

DllExport int
win32_fputc(int c,FILE *pf)
{
    return pIOSubSystem->pfnfputc(c,pf);
}

DllExport int
win32_ungetc(int c,FILE *pf)
{
    return pIOSubSystem->pfnungetc(c,pf);
}

DllExport int
win32_getc(FILE *pf)
{
    return pIOSubSystem->pfngetc(pf);
}

DllExport int
win32_fileno(FILE *pf)
{
    return pIOSubSystem->pfnfileno(pf);
}

DllExport void
win32_clearerr(FILE *pf)
{
    pIOSubSystem->pfnclearerr(pf);
    return;
}

DllExport int
win32_fflush(FILE *pf)
{
    return pIOSubSystem->pfnfflush(pf);
}

DllExport long
win32_ftell(FILE *pf)
{
    return pIOSubSystem->pfnftell(pf);
}

DllExport int
win32_fseek(FILE *pf,long offset,int origin)
{
    return pIOSubSystem->pfnfseek(pf, offset, origin);
}

DllExport int
win32_fgetpos(FILE *pf,fpos_t *p)
{
    return pIOSubSystem->pfnfgetpos(pf, p);
}

DllExport int
win32_fsetpos(FILE *pf,const fpos_t *p)
{
    return pIOSubSystem->pfnfsetpos(pf, p);
}

DllExport void
win32_rewind(FILE *pf)
{
    pIOSubSystem->pfnrewind(pf);
    return;
}

DllExport FILE*
win32_tmpfile(void)
{
    return pIOSubSystem->pfntmpfile();
}

DllExport void
win32_abort(void)
{
    pIOSubSystem->pfnabort();
    return;
}

DllExport int
win32_fstat(int fd,struct stat *bufptr)
{
    return pIOSubSystem->pfnfstat(fd,bufptr);
}

DllExport int
win32_pipe(int *pfd, unsigned int size, int mode)
{
    return pIOSubSystem->pfnpipe(pfd, size, mode);
}

DllExport FILE*
win32_popen(const char *command, const char *mode)
{
    return pIOSubSystem->pfnpopen(command, mode);
}

DllExport int
win32_pclose(FILE *pf)
{
    return pIOSubSystem->pfnpclose(pf);
}

DllExport int
win32_setmode(int fd, int mode)
{
    return pIOSubSystem->pfnsetmode(fd, mode);
}

DllExport int
win32_open(const char *path, int flag, ...)
{
    va_list ap;
    int pmode;

    va_start(ap, flag);
    pmode = va_arg(ap, int);
    va_end(ap);

    if (stricmp(path, "/dev/null")==0)
	return pIOSubSystem->pfnopen("NUL", flag, pmode);
    return pIOSubSystem->pfnopen(path,flag,pmode);
}

DllExport int
win32_close(int fd)
{
    return pIOSubSystem->pfnclose(fd);
}

DllExport int
win32_dup(int fd)
{
    return pIOSubSystem->pfndup(fd);
}

DllExport int
win32_dup2(int fd1,int fd2)
{
    return pIOSubSystem->pfndup2(fd1,fd2);
}

DllExport int
win32_read(int fd, char *buf, unsigned int cnt)
{
    return pIOSubSystem->pfnread(fd, buf, cnt);
}

DllExport int
win32_write(int fd, const char *buf, unsigned int cnt)
{
    return pIOSubSystem->pfnwrite(fd, buf, cnt);
}

DllExport int
win32_spawnvpe(int mode, const char *cmdname,
	       const char *const *argv, const char *const *envp)
{
    return pIOSubSystem->pfnspawnvpe(mode, cmdname, argv, envp);
}

DllExport int
win32_spawnle(int mode, const char *cmdname, const char *arglist,...)
{
    const char*	const*	envp;
    const char*	const*	argp;

    argp = &arglist;
    while (*argp++) ;

    return pIOSubSystem->pfnspawnvpe(mode, cmdname, &arglist, argp);
}

int
stolen_open_osfhandle(long handle, int flags)
{
    return pIOSubSystem->pfn_open_osfhandle(handle, flags);
}

long
stolen_get_osfhandle(int fd)
{
    return pIOSubSystem->pfn_get_osfhandle(fd);
}
