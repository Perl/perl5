/*

	iplio.c
	Interface for perl Low IO functions

*/

#include <iplio.h>
#include <sys/utime.h>


class CPerlLIO : public IPerlLIO
{
public:
	CPerlLIO() { w32_platform = (-1); pPerl = NULL; pSock = NULL; pStdIO = NULL; };

	virtual int Access(const char *path, int mode, int &err);
	virtual int Chmod(const char *filename, int pmode, int &err);
	virtual int Chsize(int handle, long size, int &err);
	virtual int Close(int handle, int &err);
	virtual int Dup(int handle, int &err);
	virtual int Dup2(int handle1, int handle2, int &err);
	virtual int Flock(int fd, int oper, int &err);
	virtual int FStat(int handle, struct stat *buffer, int &err);
	virtual int IOCtl(int i, unsigned int u, char *data, int &err);
	virtual int Isatty(int handle, int &err);
	virtual long Lseek(int handle, long offset, int origin, int &err);
	virtual int Lstat(const char *path, struct stat *buffer, int &err);
	virtual char *Mktemp(char *Template, int &err);
	virtual int Open(const char *filename, int oflag, int &err);	
	virtual int Open(const char *filename, int oflag, int pmode, int &err);	
	virtual int Read(int handle, void *buffer, unsigned int count, int &err);
	virtual int Rename(const char *oldname, const char *newname, int &err);
	virtual int Setmode(int handle, int mode, int &err);
	virtual int STat(const char *path, struct stat *buffer, int &err);
	virtual char *Tmpnam(char *string, int &err);
	virtual int Umask(int pmode, int &err);
	virtual int Unlink(const char *filename, int &err);
	virtual int Utime(char *filename, struct utimbuf *times, int &err);
	virtual int Write(int handle, const void *buffer, unsigned int count, int &err);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
	inline void SetSockCtl(CPerlSock *p) { pSock = p; };
	inline void SetStdObj(IPerlStdIOWin *p) { pStdIO = p; };
protected:
	inline int IsWin95(void)
	{
		return (os_id() == VER_PLATFORM_WIN32_WINDOWS);
	};
	inline int IsWinNT(void)
	{
		return (os_id() == VER_PLATFORM_WIN32_NT);
	};
	int GetOSfhandle(int filenum)
	{
		return pStdIO->GetOSfhandle(filenum);
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
	}

	DWORD w32_platform;
	CPerlObj *pPerl;
	CPerlSock *pSock;
	IPerlStdIOWin *pStdIO;
};

#define CALLFUNCRET(x)\
	int ret = x;\
	if(ret)\
		err = errno;\
	return ret;

#define CALLFUNCERR(x)\
	int ret = x;\
	if(errno)\
		err = errno;\
	return ret;

#define LCALLFUNCERR(x)\
	long ret = x;\
	if(errno)\
		err = errno;\
	return ret;

int CPerlLIO::Access(const char *path, int mode, int &err)
{
	CALLFUNCRET(access(path, mode))
}

int CPerlLIO::Chmod(const char *filename, int pmode, int &err)
{
	CALLFUNCRET(chmod(filename, pmode))
}

int CPerlLIO::Chsize(int handle, long size, int &err)
{
	CALLFUNCRET(chsize(handle, size))
}

int CPerlLIO::Close(int fd, int &err)
{
	CALLFUNCRET(close(fd))
}

int CPerlLIO::Dup(int fd, int &err)
{
	CALLFUNCERR(dup(fd))
}

int CPerlLIO::Dup2(int handle1, int handle2, int &err)
{
	CALLFUNCERR(dup2(handle1, handle2))
}


#define LK_ERR(f,i)	((f) ? (i = 0) : (err = GetLastError()))
#define LK_LEN		0xffff0000
#define LOCK_SH 1
#define LOCK_EX 2
#define LOCK_NB 4
#define LOCK_UN 8

int CPerlLIO::Flock(int fd, int oper, int &err)
{
    OVERLAPPED o;
    int i = -1;
    HANDLE fh;

    if (!IsWinNT()) {
	croak("flock() unimplemented on this platform");
	return -1;
    }
    fh = (HANDLE)GetOSfhandle(fd);
    memset(&o, 0, sizeof(o));

    switch(oper) {
    case LOCK_SH:		/* shared lock */
	LK_ERR(LockFileEx(fh, 0, 0, LK_LEN, 0, &o),i);
	break;
    case LOCK_EX:		/* exclusive lock */
	LK_ERR(LockFileEx(fh, LOCKFILE_EXCLUSIVE_LOCK, 0, LK_LEN, 0, &o),i);
	break;
    case LOCK_SH|LOCK_NB:	/* non-blocking shared lock */
	LK_ERR(LockFileEx(fh, LOCKFILE_FAIL_IMMEDIATELY, 0, LK_LEN, 0, &o),i);
	break;
    case LOCK_EX|LOCK_NB:	/* non-blocking exclusive lock */
	LK_ERR(LockFileEx(fh,
		       LOCKFILE_EXCLUSIVE_LOCK|LOCKFILE_FAIL_IMMEDIATELY,
		       0, LK_LEN, 0, &o),i);
	break;
    case LOCK_UN:		/* unlock lock */
	LK_ERR(UnlockFileEx(fh, 0, LK_LEN, 0, &o),i);
	break;
    default:			/* unknown */
	err = EINVAL;
	break;
    }
    return i;
}

int CPerlLIO::FStat(int fd, struct stat *sbufptr, int &err)
{
	CALLFUNCERR(fstat(fd, sbufptr))
}

int CPerlLIO::IOCtl(int i, unsigned int u, char *data, int &err)
{
	return pSock->IoctlSocket((SOCKET)i, (long)u, (u_long*)data, err);
}

int CPerlLIO::Isatty(int fd, int &err)
{
	return isatty(fd);
}

long CPerlLIO::Lseek(int fd, long offset, int origin, int &err)
{
	LCALLFUNCERR(lseek(fd, offset, origin))
}

int CPerlLIO::Lstat(const char *path, struct stat *sbufptr, int &err)
{
	return STat(path, sbufptr, err);
}

char *CPerlLIO::Mktemp(char *Template, int &err)
{
	return mktemp(Template);
}

int CPerlLIO::Open(const char *filename, int oflag, int &err)
{
	int ret;
    if(stricmp(filename, "/dev/null") == 0)
		ret = open("NUL", oflag);
	else
		ret = open(filename, oflag);

	if(errno)
		err = errno;
	return ret;
}

int CPerlLIO::Open(const char *filename, int oflag, int pmode, int &err)
{
	int ret;
    if(stricmp(filename, "/dev/null") == 0)
		ret = open("NUL", oflag, pmode);
	else
		ret = open(filename, oflag, pmode);

	if(errno)
		err = errno;
	return ret;
}

int CPerlLIO::Read(int fd, void *buffer, unsigned int cnt, int &err)
{
	CALLFUNCERR(read(fd, buffer, cnt))
}

int CPerlLIO::Rename(const char *OldFileName, const char *newname, int &err)
{
	char szNewWorkName[MAX_PATH+1];
	WIN32_FIND_DATA fdOldFile, fdNewFile;
	HANDLE handle;
	char *ptr;

	if((strchr(OldFileName, '\\') || strchr(OldFileName, '/'))
		&& strchr(newname, '\\') == NULL
			&& strchr(newname, '/') == NULL)
	{
		strcpy(szNewWorkName, OldFileName);
		if((ptr = strrchr(szNewWorkName, '\\')) == NULL)
			ptr = strrchr(szNewWorkName, '/');
		strcpy(++ptr, newname);
	}
	else
		strcpy(szNewWorkName, newname);

	if(stricmp(OldFileName, szNewWorkName) != 0)
	{   // check that we're not being fooled by relative paths
		// and only delete the new file
		//  1) if it exists
		//  2) it is not the same file as the old file
		//  3) old file exist
		// GetFullPathName does not return the long file name on some systems
		handle = FindFirstFile(OldFileName, &fdOldFile);
		if(handle != INVALID_HANDLE_VALUE)
		{
			FindClose(handle);
        
			handle = FindFirstFile(szNewWorkName, &fdNewFile);
        
			if(handle != INVALID_HANDLE_VALUE)
				FindClose(handle);
			else
				fdNewFile.cFileName[0] = '\0';

			if(strcmp(fdOldFile.cAlternateFileName, fdNewFile.cAlternateFileName) != 0
				&& strcmp(fdOldFile.cFileName, fdNewFile.cFileName) != 0)
			{   // file exists and not same file
				DeleteFile(szNewWorkName);
			}
		}
	}
	int ret = rename(OldFileName, szNewWorkName);
	if(ret)
		err = errno;

	return ret;
}

int CPerlLIO::Setmode(int fd, int mode, int &err)
{
	CALLFUNCRET(setmode(fd, mode))
}

int CPerlLIO::STat(const char *path, struct stat *sbufptr, int &err)
{
    char		t[MAX_PATH]; 
    const char	*p = path;
    int		l = strlen(path);
    int		res;

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
	res = stat(path, sbufptr);
#ifdef __BORLANDC__
    if (res == 0) {
	if (S_ISDIR(buffer->st_mode))
	    buffer->st_mode |= S_IWRITE | S_IEXEC;
	else if (S_ISREG(buffer->st_mode)) {
	    if (l >= 4 && path[l-4] == '.') {
		const char *e = path + l - 3;
		if (strnicmp(e,"exe",3)
		    && strnicmp(e,"bat",3)
		    && strnicmp(e,"com",3)
		    && (IsWin95() || strnicmp(e,"cmd",3)))
		    buffer->st_mode &= ~S_IEXEC;
		else
		    buffer->st_mode |= S_IEXEC;
	    }
	    else
		buffer->st_mode &= ~S_IEXEC;
	}
    }
#endif
    return res;
}

char *CPerlLIO::Tmpnam(char *string, int &err)
{
	return tmpnam(string);
}

int CPerlLIO::Umask(int pmode, int &err)
{
	return umask(pmode);
}

int CPerlLIO::Unlink(const char *filename, int &err)
{
	chmod(filename, _S_IREAD | _S_IWRITE);
	CALLFUNCRET(unlink(filename))
}

int CPerlLIO::Utime(char *filename, struct utimbuf *times, int &err)
{
	CALLFUNCRET(utime(filename, times))
}

int CPerlLIO::Write(int fd, const void *buffer, unsigned int cnt, int &err)
{
	CALLFUNCERR(write(fd, buffer, cnt))
}

