/*
 * Pipe support for OS/2.
 *
 * WARNING:  I am guilty of chumminess with the runtime library because
 *           I had no choice.  Details to follow.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#define INCL_DOSPROCESS
#define INCL_DOSQUEUES
#define INCL_DOSMISC
#define INCL_DOSMEMMGR
#include <os2.h>

extern char **environ;

/* This mysterious array _osfile is used internally by the runtime
 * library to remember assorted things about open file handles.
 * The problem is that we are creating file handles via DosMakePipe,
 * rather than via the runtime library.  This means that we have
 * to fake the runtime library into thinking that the handles we've
 * created are honest file handles.  So just before doing the fdopen,
 * we poke in a magic value that fools the library functions into
 * thinking that the handle is already open in text mode.
 *
 * This might not work for your compiler, so beware.
 */
extern char _osfile[];

/* The maximum number of simultaneously open pipes.  We create an
 * array of this size to record information about each open pipe.
 */
#define MAXPIPES 5

/* Information to remember about each open pipe.
 * The (FILE *) that popen returns is stored because that's the only
 * way we can keep track of the pipes.
 */
typedef struct pipeinfo {
	FILE *pfId;		/* Which FILE we're talking about */
	HFILE hfMe;		/* handle I should close at pclose */
	PID pidChild;		/* Child's PID */
	CHAR fReading;		/* A read or write pipe? */
} PIPEINFO, *PPIPEINFO;		/* pi and ppi */

static PIPEINFO PipeInfo[MAXPIPES];

FILE *mypopen(const char *command, const char *t)
{
	typedef char *PSZZ;
	PSZZ pszzPipeArgs = 0;
	PSZZ pszzEnviron = 0;
	PSZ *ppsz;
	PSZ psz;
	FILE *f;
	HFILE hfMe, hfYou;
	HFILE hf, hfSave;
	RESULTCODES rc;
	USHORT us;
	PPIPEINFO ppi;
	UINT i;

	/* Validate pipe type */
	if (*t != 'w' && *t != 'r') fatal("Unknown pipe type");

	/* Room for another pipe? */
	for (ppi = &PipeInfo[0]; ppi < &PipeInfo[MAXPIPES]; ppi++)
		if (ppi->pfId == 0) goto foundone;
	return NULL;

foundone:

	/* Make the pipe */
	if (DosMakePipe(&hfMe, &hfYou, 0)) return NULL;

	/* Build the environment.  First compute its length, then copy
	 * the environment strings into it.
	 */
	i = 0;
	for (ppsz = environ; *ppsz; ppsz++) i += 1 + strlen(*ppsz);
	New(1204, pszzEnviron, 1+i, CHAR);

	psz = pszzEnviron;
	for (ppsz = environ; *ppsz; ppsz++) {
		strcpy(psz, *ppsz);
		psz += 1 + strlen(*ppsz);
	}
	*psz = 0;

	/* Build the command string to execute.
	 * 6 = length(0 "/c " 0 0)
	 */
	if (DosScanEnv("COMSPEC", &psz)) psz = "C:\\OS2\\cmd.exe";
#if 0
	New(1203, pszzPipeArgs, strlen(psz) + strlen(command) + 6, CHAR);
#else
#define pszzPipeArgs buf
#endif
	sprintf(pszzPipeArgs, "%s%c/c %s%c", psz, 0, command, 0);

	/* Now some stuff that depends on what kind of pipe we're doing.
	 * We pull a sneaky trick; namely, that stdin = 0 = false,
	 * and stdout = 1 = true.  The end result is that if the
	 * pipe is a read pipe, then hf = 1; if it's a write pipe, then
	 * hf = 0 and Me and You are reversed.
	 */
	if (!(hf = (*t == 'r'))) {
		/* The meaning of Me and You is reversed for write pipes. */
		hfSave = hfYou; hfYou = hfMe; hfMe = hfSave;
	}

	ppi->fReading = hf;

	/* Trick number 1:  Fooling the runtime library into thinking
 	 * that the file handle is legit.
	 *
	 * Trick number 2:  Don't let my handle go over to the child!
	 * Since the child never closes it (why should it?), I'd better
	 * make sure he never sees it in the first place.  Otherwise,
	 * we are in deadlock city.
	 */
	_osfile[hfMe] = 0x81;		/* Danger, Will Robinson! */
	if (!(ppi->pfId = fdopen(hfMe, t))) goto no_fdopen;
	DosSetFHandState(hfMe, OPEN_FLAGS_NOINHERIT);

	/* Save the original handle because we're going to diddle it */
	hfSave = 0xFFFF;
	if (DosDupHandle(hf, &hfSave)) goto no_dup_init;

	/* Force the child's handle onto the stdio handle */
	if (DosDupHandle(hfYou, &hf)) goto no_force_dup;
	DosClose(hfYou);

	/* Now run the guy servicing the pipe */
	us = DosExecPgm(NULL, 0, EXEC_ASYNCRESULT, pszzPipeArgs, pszzEnviron,
			&rc, pszzPipeArgs);

	/* Restore stdio handle, even if exec failed. */
	DosDupHandle(hfSave, &hf); close(hfSave);

	/* See if the exec succeeded. */
	if (us) goto no_exec_pgm;

	/* Remember the child's PID */
	ppi->pidChild = rc.codeTerminate;

	Safefree(pszzEnviron);

	/* Phew. */
	return ppi->pfId;

	/* Here is where we clean up after an error. */
no_exec_pgm: ;
no_force_dup: close(hfSave);
no_dup_init: fclose(f);
no_fdopen:
	DosClose(hfMe); DosClose(hfYou);
	ppi->pfId = 0;
	Safefree(pszzEnviron);
	return NULL;
}


/* mypclose:  Closes the pipe associated with the file handle.
 * After waiting for the child process to terminate, its return
 * code is returned.  If the stream was not associated with a pipe,
 * we return -1.
 */
int
mypclose(FILE *f)
{
	PPIPEINFO ppi;
	RESULTCODES rc;
	USHORT us;

	/* Find the pipe this (FILE *) refers to */
	for (ppi = &PipeInfo[0]; ppi < &PipeInfo[MAXPIPES]; ppi++)
		if (ppi->pfId == f) goto foundit;
	return -1;
foundit:
	if (ppi->fReading && !DosRead(fileno(f), &rc, 1, &us) && us > 0) {
		DosKillProcess(DKP_PROCESSTREE, ppi->pidChild);
	}
	fclose(f);
	DosCwait(DCWA_PROCESS, DCWW_WAIT, &rc, &ppi->pidChild, ppi->pidChild);
	ppi->pfId = 0;
	return rc.codeResult;
}

/* pipe:  The only tricky thing is letting the runtime library know about
 * our two new file descriptors.
 */
int pipe(int filedes[2])
{
	HFILE hfRead, hfWrite;
	USHORT usResult;

	usResult = DosMakePipe(&hfRead, &hfWrite, 0);
	if (usResult) {
		/* Error 4 == ERROR_TOO_MANY_OPEN_FILES */
		errno = (usResult == 4) ? ENFILE : ENOMEM;
		return -1;
	}
	_osfile[hfRead] = _osfile[hfWrite] = 0x81;/* Danger, Will Robinson! */
	filedes[0] = hfRead;
	filedes[1] = hfWrite;
	return 0;
}
