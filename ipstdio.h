/*

    ipstdio.h
    Interface for perl stdio functions

*/

#ifndef __Inc__IPerlStdIO___
#define __Inc__IPerlStdIO___

#ifndef PerlIO
typedef struct _PerlIO PerlIO;
#endif

class IPerlStdIO
{
public:
    virtual PerlIO* Stdin(void) = 0;
    virtual PerlIO* Stdout(void) = 0;
    virtual PerlIO* Stderr(void) = 0;
    virtual PerlIO* Open(const char *, const char *, int &err) = 0;
    virtual int Close(PerlIO*, int &err) = 0;
    virtual int Eof(PerlIO*, int &err) = 0;
    virtual int Error(PerlIO*, int &err) = 0;
    virtual void Clearerr(PerlIO*, int &err) = 0;
    virtual int Getc(PerlIO*, int &err) = 0;
    virtual char* GetBase(PerlIO *, int &err) = 0;
    virtual int GetBufsiz(PerlIO *, int &err) = 0;
    virtual int GetCnt(PerlIO *, int &err) = 0;
    virtual char* GetPtr(PerlIO *, int &err) = 0;
    virtual char* Gets(PerlIO*, char*, int, int& err) = 0;
    virtual int Putc(PerlIO*, int, int &err) = 0;
    virtual int Puts(PerlIO*, const char *, int &err) = 0;
    virtual int Flush(PerlIO*, int &err) = 0;
    virtual int Ungetc(PerlIO*,int, int &err) = 0;
    virtual int Fileno(PerlIO*, int &err) = 0;
    virtual PerlIO* Fdopen(int, const char *, int &err) = 0;
    virtual PerlIO* Reopen(const char*, const char*, PerlIO*, int &err) = 0;
    virtual SSize_t Read(PerlIO*,void *,Size_t, int &err) = 0;
    virtual SSize_t Write(PerlIO*,const void *,Size_t, int &err) = 0;
    virtual void SetBuf(PerlIO *, char*, int &err) = 0;
    virtual int SetVBuf(PerlIO *, char*, int, Size_t, int &err) = 0;
    virtual void SetCnt(PerlIO *, int, int &err) = 0;
    virtual void SetPtrCnt(PerlIO *, char *, int, int& err) = 0;
    virtual void Setlinebuf(PerlIO*, int &err) = 0;
    virtual int Printf(PerlIO*, int &err, const char *,...) = 0;
    virtual int Vprintf(PerlIO*, int &err, const char *, va_list) = 0;
    virtual long Tell(PerlIO*, int &err) = 0;
    virtual int Seek(PerlIO*, off_t, int, int &err) = 0;
    virtual void Rewind(PerlIO*, int &err) = 0;
    virtual PerlIO* Tmpfile(int &err) = 0;
    virtual int Getpos(PerlIO*, Fpos_t *, int &err) = 0;
    virtual int Setpos(PerlIO*, const Fpos_t *, int &err) = 0;
    virtual void Init(int &err) = 0;
    virtual void InitOSExtras(void* p) = 0;
#ifdef WIN32
    virtual int OpenOSfhandle(long osfhandle, int flags) = 0;
    virtual int GetOSfhandle(int filenum) = 0;
#endif
};

#endif	/* __Inc__IPerlStdIO___ */

