/*

    ipdir.h
    Interface for perl directory functions

*/


/*
	PerlXXX_YYY explained - DickH and DougL @ ActiveState.com

XXX := functional group
YYY := stdlib/OS function name

Continuing with the theme of PerlIO, all OS functionality was
encapsulated into one of several interfaces.

PerlIO - stdio
PerlLIO - low level I/O
PerlMem - malloc, realloc, free
PerlDir - directory related
PerlEnv - process environment handling
PerlProc - process control
PerlSock - socket functions


The features of this are:
1. All OS dependant code is in the Perl Host and not the Perl Core.
   (At least this is the holy grail goal of this work)
2. The Perl Host (see perl.h for description) can provide a new and
   improved interface to OS functionality if required.
3. Developers can easily hook into the OS calls for instrumentation
   or diagnostic purposes.

What was changed to do this:
1. All calls to OS functions were replaced with PerlXXX_YYY

*/



#ifndef __Inc__IPerlDir___
#define __Inc__IPerlDir___

class IPerlDir
{
public:
    virtual int Makedir(const char *dirname, int mode, int &err) = 0;
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

