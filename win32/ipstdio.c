/*

	ipstdio.c
	Interface for perl stdio functions

*/

#include "ipstdiowin.h"
#include <stdio.h>

class CPerlStdIO : public IPerlStdIOWin
{
public:
	CPerlStdIO()
	{
		pPerl = NULL;
		pSock = NULL;
		w32_platform = -1;
		ZeroMemory(bSocketTable, sizeof(bSocketTable));
	};
	virtual PerlIO* Stdin(void);
	virtual PerlIO* Stdout(void);
	virtual PerlIO* Stderr(void);
	virtual PerlIO* Open(const char *, const char *, int &err);
	virtual int Close(PerlIO*, int &err);
	virtual int Eof(PerlIO*, int &err);
	virtual int Error(PerlIO*, int &err);
	virtual void Clearerr(PerlIO*, int &err);
	virtual int Getc(PerlIO*, int &err);
	virtual char* GetBase(PerlIO *, int &err);
	virtual int GetBufsiz(PerlIO *, int &err);
	virtual int GetCnt(PerlIO *, int &err);
	virtual char* GetPtr(PerlIO *, int &err);
	virtual int Putc(PerlIO*, int, int &err);
	virtual int Puts(PerlIO*, const char *, int &err);
	virtual int Flush(PerlIO*, int &err);
	virtual int Ungetc(PerlIO*,int, int &err);
	virtual int Fileno(PerlIO*, int &err);
	virtual PerlIO* Fdopen(int, const char *, int &err);
	virtual PerlIO* Reopen(const char*, const char*, PerlIO*, int &err);
	virtual SSize_t Read(PerlIO*,void *,Size_t, int &err);
	virtual SSize_t Write(PerlIO*,const void *,Size_t, int &err);
	virtual void SetBuf(PerlIO *, char*, int &err);
	virtual int SetVBuf(PerlIO *, char*, int, Size_t, int &err);
	virtual void SetCnt(PerlIO *, int, int &err);
	virtual void SetPtrCnt(PerlIO *, char *, int, int& err);
	virtual void Setlinebuf(PerlIO*, int &err);
	virtual int Printf(PerlIO*, int &err, const char *,...);
	virtual int Vprintf(PerlIO*, int &err, const char *, va_list);
	virtual long Tell(PerlIO*, int &err);
	virtual int Seek(PerlIO*, off_t, int, int &err);
	virtual void Rewind(PerlIO*, int &err);
	virtual PerlIO*	Tmpfile(int &err);
	virtual int Getpos(PerlIO*, Fpos_t *, int &err);
	virtual int Setpos(PerlIO*, const Fpos_t *, int &err);
	virtual void Init(int &err);
	virtual void InitOSExtras(void* p);
	virtual int OpenOSfhandle(long osfhandle, int flags);
	virtual int GetOSfhandle(int filenum);

	void ShutDown(void);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
	inline void SetSockCtl(CPerlSock *p) { pSock = p; };
protected:
	inline int IsWin95(void)
	{
		return (os_id() == VER_PLATFORM_WIN32_WINDOWS);
	};
	inline int IsWinNT(void)
	{
		return (os_id() == VER_PLATFORM_WIN32_NT);
	};
	inline void AddToSocketTable(int fh)
	{
		if(fh < _NSTREAM_)
			bSocketTable[fh] = TRUE;
	};
	inline BOOL InSocketTable(int fh)
	{
		if(fh < _NSTREAM_)
			return bSocketTable[fh];
		return FALSE;
	};
	inline void RemoveFromSocketTable(int fh)
	{
		if(fh < _NSTREAM_)
			bSocketTable[fh] = FALSE;
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


	CPerlObj *pPerl;
	CPerlSock *pSock;
	DWORD w32_platform;
	BOOL bSocketTable[_NSTREAM_];
};

void CPerlStdIO::ShutDown(void)
{
	int i, err;
	for(i = 0; i < _NSTREAM_; ++i)
	{
		if(InSocketTable(i))
			pSock->CloseSocket(i, err);
	}
};

#ifdef _X86_
extern "C" int __cdecl _alloc_osfhnd(void);
extern "C" int __cdecl _set_osfhnd(int fh, long value);
extern "C" void __cdecl _unlock(int);

#if (_MSC_VER >= 1000)
typedef struct
{
	long osfhnd;    /* underlying OS file HANDLE */
	char osfile;    /* attributes of file (e.g., open in text mode?) */
	char pipech;    /* one char buffer for handles opened on pipes */
}	ioinfo;
extern "C" ioinfo * __pioinfo[];
#define IOINFO_L2E			5
#define IOINFO_ARRAY_ELTS	(1 << IOINFO_L2E)
#define _pioinfo(i)	(__pioinfo[i >> IOINFO_L2E] + (i & (IOINFO_ARRAY_ELTS - 1)))
#define _osfile(i)	(_pioinfo(i)->osfile)
#else
extern "C" extern char _osfile[];
#endif	// (_MSC_VER >= 1000)

#define FOPEN			0x01	// file handle open
#define FAPPEND			0x20	// file handle opened O_APPEND
#define FDEV			0x40	// file handle refers to device
#define FTEXT			0x80	// file handle is in text mode

#define _STREAM_LOCKS   26		// Table of stream locks
#define _LAST_STREAM_LOCK  (_STREAM_LOCKS+_NSTREAM_-1)	// Last stream lock
#define _FH_LOCKS          (_LAST_STREAM_LOCK+1)		// Table of fh locks
#endif	// _X86_

int CPerlStdIO::OpenOSfhandle(long osfhandle, int flags)
{
	int fh;

#ifdef _X86_
	if(IsWin95())
	{
		// all this is here to handle Win95's GetFileType bug.
		char fileflags;		// _osfile flags 

		// copy relevant flags from second parameter 
		fileflags = FDEV;

		if(flags & _O_APPEND)
			fileflags |= FAPPEND;

		if(flags & _O_TEXT)
			fileflags |= FTEXT;

		// attempt to allocate a C Runtime file handle
		if((fh = _alloc_osfhnd()) == -1)
		{
			errno = EMFILE;		// too many open files 
			_doserrno = 0L;		// not an OS error
			return -1;			// return error to caller
		}

		// the file is open. now, set the info in _osfhnd array
		_set_osfhnd(fh, osfhandle);

		fileflags |= FOPEN;			// mark as open

#if (_MSC_VER >= 1000)
		_osfile(fh) = fileflags;	// set osfile entry
#else
		_osfile[fh] = fileflags;	// set osfile entry
#endif
	}
	else
#endif	// _X86_
	fh = _open_osfhandle(osfhandle, flags);

	if(fh >= 0)
		AddToSocketTable(fh);

	return fh;					// return handle
}

int CPerlStdIO::GetOSfhandle(int filenum)
{
	return _get_osfhandle(filenum);
}

PerlIO* CPerlStdIO::Stdin(void)
{
    return (PerlIO*)(&_iob[0]);
}

PerlIO* CPerlStdIO::Stdout(void)
{
    return (PerlIO*)(&_iob[1]);
}

PerlIO* CPerlStdIO::Stderr(void)
{
    return (PerlIO*)(&_iob[2]);
}

PerlIO* CPerlStdIO::Open(const char *path, const char *mode, int &err)
{
	PerlIO* ret = NULL;
	if(*path != '\0')
	{
	    if(stricmp(path, "/dev/null") == 0)
			ret = (PerlIO*)fopen("NUL", mode);
		else
			ret = (PerlIO*)fopen(path, mode);

		if(errno)
			err = errno;
	}
	else
		err = EINVAL;		
	return ret;
}

extern "C" int _free_osfhnd(int fh);
int CPerlStdIO::Close(PerlIO* pf, int &err)
{
	int ret = 0, fileNo = fileno((FILE*)pf);
	if(InSocketTable(fileNo))
	{
		RemoveFromSocketTable(fileNo);
		pSock->CloseSocket(fileNo, err);
		_free_osfhnd(fileNo);
		fclose((FILE*)pf);
	}
	else
		ret = fclose((FILE*)pf);

	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Eof(PerlIO* pf, int &err)
{
	int ret = feof((FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Error(PerlIO* pf, int &err)
{
	int ret = ferror((FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

void CPerlStdIO::Clearerr(PerlIO* pf, int &err)
{
	clearerr((FILE*)pf);
	err = 0;
}

int CPerlStdIO::Getc(PerlIO* pf, int &err)
{
	int ret = fgetc((FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Putc(PerlIO* pf, int c, int &err)
{
	int ret = fputc(c, (FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Puts(PerlIO* pf, const char *s, int &err)
{
	int ret = fputs(s, (FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Flush(PerlIO* pf, int &err)
{
	int ret = fflush((FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Ungetc(PerlIO* pf,int c, int &err)
{
	int ret = ungetc(c, (FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Fileno(PerlIO* pf, int &err)
{
	int ret = fileno((FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

PerlIO* CPerlStdIO::Fdopen(int fh, const char *mode, int &err)
{
	PerlIO* ret = (PerlIO*)fdopen(fh, mode);
	if(errno)
		err = errno;
	return ret;
}

PerlIO* CPerlStdIO::Reopen(const char* filename, const char* mode, PerlIO* pf, int &err)
{
	PerlIO* ret = (PerlIO*)freopen(filename, mode, (FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

SSize_t CPerlStdIO::Read(PerlIO* pf, void * buffer, Size_t count, int &err)
{
	size_t ret = fread(buffer, 1, count, (FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

SSize_t CPerlStdIO::Write(PerlIO* pf, const void * buffer, Size_t count, int &err)
{
	size_t ret = fwrite(buffer, 1, count, (FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

void CPerlStdIO::Setlinebuf(PerlIO*pf, int &err)
{
    setvbuf((FILE*)pf, NULL, _IOLBF, 0);
}

int CPerlStdIO::Printf(PerlIO* pf, int &err, const char *format, ...)
{
	va_list(arglist);
	va_start(arglist, format);
	int ret = Vprintf(pf, err, format, arglist);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Vprintf(PerlIO* pf, int &err, const char * format, va_list arg)
{
	int ret = vfprintf((FILE*)pf, format, arg);
	if(errno)
		err = errno;
	return ret;
}

long CPerlStdIO::Tell(PerlIO* pf, int &err)
{
	long ret = ftell((FILE*)pf);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Seek(PerlIO* pf, off_t offset, int origin, int &err)
{
	int ret = fseek((FILE*)pf, offset, origin);
	if(errno)
		err = errno;
	return ret;
}

void CPerlStdIO::Rewind(PerlIO* pf, int &err)
{
	rewind((FILE*)pf);
}

PerlIO*	CPerlStdIO::Tmpfile(int &err)
{
	return (PerlIO*)tmpfile();
}

int CPerlStdIO::Getpos(PerlIO* pf, Fpos_t *p, int &err)
{
	int ret = fgetpos((FILE*)pf, (fpos_t*)p);
	if(errno)
		err = errno;
	return ret;
}

int CPerlStdIO::Setpos(PerlIO* pf, const Fpos_t *p, int &err)
{
	int ret = fsetpos((FILE*)pf, (fpos_t*)p);
	if(errno)
		err = errno;
	return ret;
}

char* CPerlStdIO::GetBase(PerlIO *pf, int &err)
{
	return ((FILE*)pf)->_base;
}

int CPerlStdIO::GetBufsiz(PerlIO *pf, int &err)
{
	return ((FILE*)pf)->_bufsiz;
}

int CPerlStdIO::GetCnt(PerlIO *pf, int &err)
{
	return ((FILE*)pf)->_cnt;
}

char* CPerlStdIO::GetPtr(PerlIO *pf, int &err)
{
	return ((FILE*)pf)->_ptr;
}

void CPerlStdIO::SetBuf(PerlIO *pf, char* buffer, int &err)
{
    setbuf((FILE*)pf, buffer);
}

int CPerlStdIO::SetVBuf(PerlIO *pf, char* buffer, int type, Size_t size, int &err)
{
    return setvbuf((FILE*)pf, buffer, type, size);
}

void CPerlStdIO::SetCnt(PerlIO *pf, int n, int &err)
{
	((FILE*)pf)->_cnt = n;
}

void CPerlStdIO::SetPtrCnt(PerlIO *pf, char *ptr, int n, int& err)
{
	((FILE*)pf)->_ptr = ptr;
	((FILE*)pf)->_cnt = n;
}

void CPerlStdIO::Init(int &err)
{
}

void CPerlStdIO::InitOSExtras(void* p)
{
}


