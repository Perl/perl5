/*

	ipdir.c
	Interface for perl directory functions

*/

#include <ipdir.h>

class CPerlDir : public IPerlDir
{
public:
	CPerlDir() { pPerl = NULL; };
	virtual int MKdir(const char *dirname, int mode, int &err);
	virtual int Chdir(const char *dirname, int &err);
	virtual int Rmdir(const char *dirname, int &err);
	virtual int Close(DIR *dirp, int &err);
	virtual DIR *Open(char *filename, int &err);
	virtual struct direct *Read(DIR *dirp, int &err);
	virtual void Rewind(DIR *dirp, int &err);
	virtual void Seek(DIR *dirp, long loc, int &err);
	virtual long Tell(DIR *dirp, int &err);

	inline void SetPerlObj(CPerlObj *p) { pPerl = p; };
protected:
	CPerlObj *pPerl;
};

int CPerlDir::MKdir(const char *dirname, int mode, int &err)
{
    return mkdir(dirname); /* just ignore mode */
}

int CPerlDir::Chdir(const char *dirname, int &err)
{
    return chdir(dirname);
}

int CPerlDir::Rmdir(const char *dirname, int &err)
{
    return rmdir(dirname);
}

#define PATHLEN 1024
// The idea here is to read all the directory names into a string table
// (separated by nulls) and when one of the other dir functions is called
// return the pointer to the current file name. 
DIR *CPerlDir::Open(char *filename, int &err)
{
	DIR            *p;
	long            len;
	long            idx;
	char            scannamespc[PATHLEN];
	char       *scanname = scannamespc;
	struct stat     sbuf;
	WIN32_FIND_DATA FindData;
	HANDLE          fh;

	// Create the search pattern
	strcpy(scanname, filename);

	len = strlen(scanname);
	if(len > 1 && ((scanname[len-1] == '/') || (scanname[len-1] == '\\')))
	{
		// allow directory names of 'x:\' to pass
		if(!(len == 3 && scanname[1] == ':'))
			scanname[len-1] = '\0';
	}

	// check to see if filename is a directory
	if(stat(scanname, &sbuf) < 0 || sbuf.st_mode & _S_IFDIR == 0)
	{
		DWORD dTemp = GetFileAttributes(scanname);
		if(dTemp == 0xffffffff || !(dTemp & FILE_ATTRIBUTE_DIRECTORY))
		{
			return NULL;
		}
	}

	if((scanname[len-1] == '/') || (scanname[len-1] == '\\'))
		scanname[len-1] = '\0';

	strcat(scanname, "/*");

	// Get a DIR structure
	Newz(1501, p, 1, DIR);
	if(p == NULL)
		return NULL;

	// do the FindFirstFile call
	fh = FindFirstFile(scanname, &FindData);
	if(fh == INVALID_HANDLE_VALUE) 
	{
	    Safefree(p);
		return NULL;
	}

	// now allocate the first part of the string table for the filenames that we find.
	idx = strlen(FindData.cFileName)+1;
	New(1502, p->start, idx, char);
	if(p->start == NULL) 
	{
		FindClose(fh);
		croak("opendir: malloc failed!\n");
	}
	strcpy(p->start, FindData.cFileName);
	p->nfiles++;

	// loop finding all the files that match the wildcard
	// (which should be all of them in this directory!).
	// the variable idx should point one past the null terminator
	// of the previous string found.
	//
	while(FindNextFile(fh, &FindData)) 
	{
		len = strlen(FindData.cFileName);
		// bump the string table size by enough for the
		// new name and it's null terminator 
		Renew(p->start, idx+len+1, char);
		if(p->start == NULL) 
		{
			FindClose(fh);
	    	croak("opendir: malloc failed!\n");
		}
		strcpy(&p->start[idx], FindData.cFileName);
		p->nfiles++;
		idx += len+1;
	}
	FindClose(fh);
	p->size = idx;
	p->curr = p->start;
	return p;
}

int CPerlDir::Close(DIR *dirp, int &err)
{
	Safefree(dirp->start);
	Safefree(dirp);
	return 1;
}

// Readdir just returns the current string pointer and bumps the
// string pointer to the next entry.
struct direct *CPerlDir::Read(DIR *dirp, int &err)
{
	int         len;
	static int  dummy = 0;

	if(dirp->curr) 
	{	// first set up the structure to return
		len = strlen(dirp->curr);
		strcpy(dirp->dirstr.d_name, dirp->curr);
		dirp->dirstr.d_namlen = len;

		// Fake an inode
		dirp->dirstr.d_ino = dummy++;

		// Now set up for the next call to readdir
		dirp->curr += len + 1;
		if(dirp->curr >= (dirp->start + dirp->size)) 
		{
	    	dirp->curr = NULL;
		}

		return &(dirp->dirstr);
	} 
	else
		return NULL;
}

void CPerlDir::Rewind(DIR *dirp, int &err)
{
    dirp->curr = dirp->start;
}

void CPerlDir::Seek(DIR *dirp, long loc, int &err)
{
    dirp->curr = (char *)loc;
}

long CPerlDir::Tell(DIR *dirp, int &err)
{
    return (long) dirp->curr;
}


