/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPScript.h		-	Handle scripts
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPScript.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1998/04/07 01:46:45  neeri
MacPerl 5.2.0r4b1

Revision 1.1  1997/06/23 17:11:02  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:04:28  neeri
Initial revision

Revision 0.1  1993/09/16  00:00:00  neeri
Runtime is not particularly fond of AppleEvents

*********************************************************************/

#ifndef __MPSCRIPT__
#define __MPSCRIPT__

#include <MacTypes.h>
#include <Files.h>
#include <MixedMode.h>
#include <StandardFile.h>

pascal void InitPerlEnviron();

pascal void DoScriptMenu(short theItem);

pascal OSErr DoScript(const AppleEvent *theAppleEvent, AppleEvent *reply, long refCon);

pascal Boolean DoRuntime();

pascal Boolean GetScriptFilter(CInfoPBPtr pb);

#if TARGET_RT_MAC_CFM
extern RoutineDescriptor	uGetScriptFilter;
#else
#define uGetScriptFilter *(FileFilterUPP)&GetScriptFilter
#endif

pascal void AddStandardScripts();

#endif