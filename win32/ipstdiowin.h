/*

	ipstdiowin.h
	Interface for perl stdio functions

*/

#ifndef __Inc__IPerlStdIOWin___
#define __Inc__IPerlStdIOWin___

#include <ipstdio.h>


class IPerlStdIOWin : public IPerlStdIO
{
public:
	virtual int OpenOSfhandle(long osfhandle, int flags) = 0;
	virtual int GetOSfhandle(int filenum) = 0;
};

#endif	/* __Inc__IPerlStdIOWin___ */

