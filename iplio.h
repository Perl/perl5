/*

    iplio.h
    Interface for perl Low IO functions

*/

#ifndef __Inc__IPerlLIO___
#define __Inc__IPerlLIO___

class IPerlLIO
{
public:
    virtual int Access(const char *path, int mode, int &err) = 0;
    virtual int Chmod(const char *filename, int pmode, int &err) = 0;
    virtual int Chown(const char *filename, uid_t owner, gid_t group, int &err) = 0;
    virtual int Chsize(int handle, long size, int &err) = 0;
    virtual int Close(int handle, int &err) = 0;
    virtual int Dup(int handle, int &err) = 0;
    virtual int Dup2(int handle1, int handle2, int &err) = 0;
    virtual int Flock(int fd, int oper, int &err) = 0;
    virtual int FileStat(int handle, struct stat *buffer, int &err) = 0;
    virtual int IOCtl(int i, unsigned int u, char *data, int &err) = 0;
    virtual int Isatty(int handle, int &err) = 0;
    virtual long Lseek(int handle, long offset, int origin, int &err) = 0;
    virtual int Lstat(const char *path, struct stat *buffer, int &err) = 0;
    virtual char *Mktemp(char *Template, int &err) = 0;
    virtual int Open(const char *filename, int oflag, int &err) = 0;	
    virtual int Open(const char *filename, int oflag, int pmode, int &err) = 0;	
    virtual int Read(int handle, void *buffer, unsigned int count, int &err) = 0;
    virtual int Rename(const char *oldname, const char *newname, int &err) = 0;
    virtual int Setmode(int handle, int mode, int &err) = 0;
    virtual int NameStat(const char *path, struct stat *buffer, int &err) = 0;
    virtual char *Tmpnam(char *string, int &err) = 0;
    virtual int Umask(int pmode, int &err) = 0;
    virtual int Unlink(const char *filename, int &err) = 0;
    virtual int Utime(char *filename, struct utimbuf *times, int &err) = 0;
    virtual int Write(int handle, const void *buffer, unsigned int count, int &err) = 0;
};

#endif	/* __Inc__IPerlLIO___ */
