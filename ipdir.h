/*

	ipdir.h
	Interface for perl directory functions

*/

#ifndef __Inc__IPerlDir___
#define __Inc__IPerlDir___

class IPerlDir
{
public:
	virtual int MKdir(const char *dirname, int mode, int &err) = 0;
	virtual int Chdir(const char *dirname, int &err) = 0;
	virtual int Rmdir(const char *dirname, int &err) = 0;
	virtual int Close(DIR *dirp, int &err) = 0;
	virtual DIR *Open(char *filename, int &err) = 0;
	virtual struct direct *Read(DIR *dirp, int &err) = 0;
	virtual void Rewind(DIR *dirp, int &err) = 0;
	virtual void Seek(DIR *dirp, long loc, int &err) = 0;
	virtual long Tell(DIR *dirp, int &err) = 0;
};

#endif	/* __Inc__IPerlDir___ */

