/*********************************************************************
Project	:	MacPerl
File		:	PerlAEUtils.h		-	Stuff for Perl AppleEvent handling
Author	:	Matthias Neeracher
Language	:	Metrowerks C++

$Log: PerlAEUtils.h,v $
Revision 1.1  2000/08/14 01:48:18  neeri
Checked into Sourceforge

Revision 1.1  1997/04/07 20:49:10  neeri
Synchronized with MacPerl 5.1.4a1

*********************************************************************/

#include <AppleEvents.h>
#include <AEBuild.h>
#include <AEStream.h>
#include <AESubDescs.h>
#include <OSA.h>

#ifdef __cplusplus
extern "C" {
#endif

extern OSACreateAppleEventUPP	gPAECreate;
extern OSASendUPP					gPAESend;
extern AEEventHandlerUPP		gPAEResume;
extern OSAActiveUPP				gPAEActive;
extern long							gPAECreateRefCon;
extern long							gPAESendRefCon;
extern long							gPAEResumeRefCon;
extern long							gPAEActiveRefCon;
extern Boolean						gPAEInstall;

extern Ptr gPAEArgs;

void PAEClearArgs();
Boolean PAEDoNextParam(char ** formscan, SV * sv);
int PAENextParam(char ** formscan);
OSErr PAEInstallEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler);
OSErr PAEGetEventHandler(OSType aeClass, OSType aeID, SV * handler, SV * refCon, Boolean sysHandler);
OSErr PAERemoveEventHandler(OSType aeClass, OSType aeID, Boolean sysHandler);
OSErr	PAEDoAppleEvent(const AppleEvent * event, AppleEvent * reply);
Boolean PAEHasOpenHandler();
void PAENuke();

#ifdef __cplusplus
}
#endif
