/*********************************************************************
Project	:	SubLaunch		-	Call ToolServer
File		:	SubLaunch.h		-	Interface
Author	:	Matthias Neeracher

Copyright (c) 1991, 1992 Matthias Neeracher

	You may distribute under the terms of the Perl Artistic License,
	as specified in the README file.

$Log: SubLaunch.h,v $
Revision 1.1  2000/08/14 01:48:17  neeri
Checked into Sourceforge

Revision 1.1  2000/05/14 21:45:03  neeri
First build released to public


*********************************************************************/

#ifdef __cplusplus
extern "C" {
#endif

#include <Types.h>
#include <Files.h>

/* Create a temporary file in the temp folder. 
*/
OSErr	FSpMakeTempFile(FSSpec * desc);

/* Execute the command. Any of the files may be set to NULL */
OSErr SubLaunch(char * commandline, FSSpec * input, FSSpec * output, FSSpec * error, long * status);


#if TARGET_RT_MAC_CFM
extern RoutineDescriptor	uSubLaunchIdle;
#else
pascal Boolean SubLaunchIdle(EventRecord * ev, long * sleep, RgnHandle * rgn);
#define uSubLaunchIdle *(AEIdleUPP)&SubLaunchIdle
#endif

#ifdef __cplusplus
}
#endif
