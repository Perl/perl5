/*********************************************************************
Project	:	SubLaunch		-	Call ToolServer
File		:	SubLaunch.c		-	The code
Author	:	Matthias Neeracher

Copyright (c) 1991-1995 Matthias Neeracher

	You may distribute under the terms of the Perl Artistic License,
	as specified in the README file.

$Log: SubLaunch.c,v $
Revision 1.1  2000/08/14 01:48:17  neeri
Checked into Sourceforge

Revision 1.1  2000/05/14 21:45:03  neeri
First build released to public


*********************************************************************/

/* We need glue for Gestalt, but not for the rest of the stuff */

#include <Gestalt.h>
#include <GUSIFileSpec.h>

#include <Types.h>
#include <Processes.h>
#include <Events.h>
#include <AppleEvents.h>
#include <CursorCtl.h>
#include <Resources.h>
#include <QuickDraw.h>
#include <Folders.h>
#include <Errors.h>
#include <Script.h>
#include <TextUtils.h>

#include <string.h>

#define MAC_CONTEXT

#include "SubLaunch.h"
#include "EXTERN.h"
#include "perl.h"

#define FAILOSERR(call)	if (err = call)	return err
#define ToolServer	'MPSX'

/* The following stuff is adapted from Jens Peter Alfke's SignatureToApp code */

static OSErr ToolServerRunning(ProcessSerialNumber *psn)
{
	OSErr err;
	ProcessInfoRec info;
	
	psn->highLongOfPSN = 0;
	psn->lowLongOfPSN  = kNoProcess;
	do	{
		FAILOSERR(GetNextProcess(psn));
		info.processInfoLength 	= sizeof(info);
		info.processName 			= nil;
		info.processAppSpec 		= nil;
		FAILOSERR(GetProcessInformation(psn,&info));
	} while(info.processSignature != ToolServer);

	*psn = info.processNumber;
	
	return noErr;
}

static OSErr GetSysVolume(short *vRefNum)
{
	long dir;
	
	return FindFolder(kOnSystemDisk, kSystemFolderType, false, vRefNum, &dir);
}


static OSErr GetIndVolume(short index, short *vRefNum)
{
	OSErr 			err;
	ParamBlockRec 	pb;
	
	pb.volumeParam.ioNamePtr 	= nil;
	pb.volumeParam.ioVolIndex 	= index;
	
	FAILOSERR(PBGetVInfoSync(&pb));
	
	*vRefNum = pb.volumeParam.ioVRefNum;
	
	return noErr;
}

static OSErr VolHasDesktopDB(short vRefNum, Boolean * hasDesktop)
{
	OSErr 						err;
	HParamBlockRec 			pb;
	GetVolParmsInfoBuffer 	info;
	
	pb.ioParam.ioNamePtr 	= nil;
	pb.ioParam.ioVRefNum 	= vRefNum;
	pb.ioParam.ioBuffer 		= (Ptr)&info;
	pb.ioParam.ioReqCount 	= sizeof(GetVolParmsInfoBuffer);
	
	FAILOSERR(PBHGetVolParmsSync(&pb));

	*hasDesktop = (info.vMAttrib & (1 << bHasDesktopMgr))!=0;
	
	return noErr;
}

static OSErr FindAppOnVolume(short vRefNum, FSSpec *file)
{
	OSErr 	err;
	DTPBRec 	pb;
	
	/* Get Acess path to Desktop database on this volume */
	
	pb.ioVRefNum 		= vRefNum;
	pb.ioNamePtr 		= nil;
	FAILOSERR(PBDTGetPath(&pb));
	
	pb.ioIndex 			= 0;
	pb.ioFileCreator 	= ToolServer;
	pb.ioNamePtr 		= file->name;
	switch (err = PBDTGetAPPLSync(&pb))	{
	case noErr:
		file->vRefNum 	= vRefNum;
		file->parID 	= pb.ioAPPLParID;
	
		return noErr;
	case fnfErr:
		return afpItemNotFound;						/* Bug in PBDTGetAPPL			*/
	default:
		return err;
	}
}

/* LaunchApplication in 32 bit everything environment	*/

#if !defined(powerc) && !defined(__powerc)
pascal OSErr WrappedLaunchApplication(const LaunchParamBlockRec *LaunchParams);
#else
#define WrappedLaunchApplication LaunchApplication
#endif

static OSErr LaunchIt(const FSSpecPtr fileSpec, ProcessSerialNumber *psn )
{
	OSErr 					err;
	LaunchParamBlockRec 	pb;
	
	pb.launchBlockID 			= extendedBlock;
	pb.launchEPBLength 		= extendedBlockLen;
	pb.launchFileFlags 		= launchNoFileFlags;
	pb.launchControlFlags	= launchContinue | launchNoFileFlags | launchDontSwitch;
	pb.launchAppSpec 			= fileSpec;
	pb.launchAppParameters	= nil;
	
	FAILOSERR(LaunchApplication(&pb));

	*psn = pb.launchProcessSN;
	
	return noErr;
}

/* Get the psn of the ToolServer. Launch one if necessary. Buy one. Steal one. */
static OSErr LaunchToolServer(ProcessSerialNumber *psn)
{
	OSErr 	err;
	short 	sysVRefNum, vRefNum, index;
	FSSpec 	file;
	Boolean 	hasDesktopDB;
	
	/* See if ToolServer is already running:					*/
	err	= ToolServerRunning(psn);
	
	if	(err != procNotFound)
		return err;
	
	/* Not running, try to launch it */
	
	FAILOSERR(GetSysVolume(&sysVRefNum));
	vRefNum 	= sysVRefNum;
	for (index = 0; !err; err = GetIndVolume(++index,&vRefNum)) {
		if (!index || vRefNum != sysVRefNum) {
			FAILOSERR(VolHasDesktopDB(vRefNum,&hasDesktopDB));
			if (hasDesktopDB)	
				switch (err = FindAppOnVolume(vRefNum, &file))	{
				case noErr:
					return LaunchIt(&file,psn);
				case afpItemNotFound:
					break;
				default:
					return err;
				}
		}
	}
	switch (err)	{
	case nsvErr:
	case afpItemNotFound:
		return fnfErr;
	default:
		return err;
	}
}

typedef enum {
	dontKnow,
	canRun,
	cantRun
} featureCheck;

static featureCheck	requiredFeatures	=	dontKnow;

#define HASBIT(bit) (answer&(1<<bit))
#define GESTALT(sel) !Gestalt(sel, &answer)

OSErr ValidateFeatures()
{
	long answer;
	
	switch (requiredFeatures)	{
	case canRun:
		return noErr;
	case cantRun:
		return gestaltUnknownErr;
	case dontKnow:
		if (	GESTALT(gestaltAppleEventsAttr)							&& 
					HASBIT(gestaltAppleEventsPresent) 					&&
			 	GESTALT(gestaltFindFolderAttr)							&&
					HASBIT(gestaltFindFolderPresent) 					&&
				GESTALT(gestaltOSAttr)										&&
					HASBIT(gestaltLaunchCanReturn)						&&
					HASBIT(gestaltLaunchFullFileSpec)					&&
					HASBIT(gestaltLaunchControl)							&&
				GESTALT(gestaltFSAttr)										&&
					HASBIT(gestaltHasFSSpecCalls)
		)
			requiredFeatures	=	canRun;
		else
			requiredFeatures 	= 	cantRun;
		
		return ValidateFeatures();
	}
}

#define FAILOSERR(call)	if (err = call)	return err

/* Create a temporary file in the temp folder. 
*/
OSErr	FSpMakeTempFile(FSSpec * desc)
{
	static int	id	=	0;

	OSErr			err;
	
	FAILOSERR(FindFolder(kOnSystemDisk, 'temp', true, &desc->vRefNum, &desc->parID));
	
	*((long *) desc->name)		=	'\007tmp';
	
	do {
		desc->name[4]	=	id / 1000 	% 10 + '0';
		desc->name[5]	=	id / 100		% 10 + '0';
		desc->name[6]	=	id / 10		% 10 + '0';
		desc->name[7]	=	id 			% 10 + '0';
		
		++id;
		
		err = HCreate(desc->vRefNum, desc->parID, desc->name, 'TEMP', 'TEXT');
	} while (err == dupFNErr);
	
	return err;
}
			
pascal Boolean SubLaunchIdle(EventRecord * ev, long * sleep, RgnHandle * rgn)
{
	if (gMacPerl_HandleEvent)
		(*gMacPerl_HandleEvent)(ev);
	else if (ev->what == kHighLevelEvent)
		if (AEProcessAppleEvent(ev)) 
			return true;

	SpinCursor(1);
		
	*sleep	=	10;
	
	return false;
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uSubLaunchIdle = 
		BUILD_ROUTINE_DESCRIPTOR(uppAEIdleProcInfo, SubLaunchIdle);
#endif

static char * Fragments[] = {
	"Directory \'",
	"\'; Begin; ",
	"; End<\'",
	"\' >\'",
	"\' ³\'",
	"\' ·\'",
	"\'\n",
	"Dev:Null"
};

#define BEGIN_TEXT		Fragments[0]
#define DIRSET_TEXT		Fragments[1]
#define END_TEXT			Fragments[2]
#define STDOUT_TEXT		Fragments[3]
#define STDERR_TEXT		Fragments[4]
#define OUTERR_TEXT		Fragments[5]
#define TERM_TEXT			Fragments[6]
#define DEVNULL_TEXT		Fragments[7]
#define DEVSTRING(dev)	(dev) ? GUSIFSp2FullPath(dev) : DEVNULL_TEXT

/* Execute the command. Any of the files may be set to NULL */
OSErr SubLaunch(char * commandline, FSSpec * input, FSSpec * output, FSSpec * error, long * status)
{
	OSErr						err;
	Boolean					same;
	ProcessSerialNumber	psn;
	ProcessSerialNumber	me;
	AppleEvent				cmd;
	AppleEvent				reply;
	AEAddressDesc			addr;
	acurHandle				acur;
	Handle					text;
	const char *			segment;
	FSSpec					vol;
	OSType					type;
	Size						size;
	
	/* Check if the system is sexy enough */
	FAILOSERR(ValidateFeatures());
	
	/* Get the psn of the ToolServer. Launch one if necessary. Buy one. Steal one. */
	FAILOSERR(LaunchToolServer(&psn));
	
	/* It would be disastrous to send the event to ourselves (I know: I tried) */
	FAILOSERR(GetCurrentProcess(&me));
	FAILOSERR(SameProcess(&psn, &me, &same));
	if (same)
		return appMemFullErr;			/* This is a lie. So what ? */
	
	/* Build shell wrapper for command string */
	FAILOSERR(PtrToHand(BEGIN_TEXT, &text, strlen(BEGIN_TEXT)));
	FAILOSERR(GUSIPath2FSp(":", &vol));
	segment	=	GUSIFSp2FullPath(&vol);
	FAILOSERR(PtrAndHand(segment, text, strlen(segment)));
	FAILOSERR(PtrAndHand(DIRSET_TEXT, text, strlen(DIRSET_TEXT)));
	FAILOSERR(PtrAndHand(commandline, text, strlen(commandline)));
	FAILOSERR(PtrAndHand(END_TEXT, text, strlen(END_TEXT)));
	segment = DEVSTRING(input);
	FAILOSERR(PtrAndHand(segment, text, strlen(segment)));
	segment = DEVSTRING(output);
	if (	output && error 
		&& output->vRefNum == error->vRefNum
		&& output->parID   == error->parID
		&& EqualString(output->name, error->name, false, true)
	) {
		FAILOSERR(PtrAndHand(OUTERR_TEXT, text, strlen(OUTERR_TEXT)));
		FAILOSERR(PtrAndHand(segment, text, strlen(segment)));
	} else {
		FAILOSERR(PtrAndHand(STDOUT_TEXT, text, strlen(STDOUT_TEXT)));
		FAILOSERR(PtrAndHand(segment, text, strlen(segment)));
		FAILOSERR(PtrAndHand(STDERR_TEXT, text, strlen(STDERR_TEXT)));
		DEVSTRING(error);
		FAILOSERR(PtrAndHand(segment, text, strlen(segment)));
	}
	FAILOSERR(PtrAndHand(TERM_TEXT, text, strlen(TERM_TEXT)));
	
	/* Build the AppleEvent */
	FAILOSERR(
		AECreateDesc(typeProcessSerialNumber, (Ptr) &psn, sizeof(psn), &addr));
	FAILOSERR(
		AECreateAppleEvent('misc', 'dosc', &addr, 
			kAutoGenerateReturnID, kAnyTransactionID, 
			&cmd));
	HLock(text);
	FAILOSERR(
		AEPutParamPtr(&cmd, '----', typeChar, *text, GetHandleSize(text)));
	DisposeHandle(text);
	
	/* Send it */
	acur	=	(acurHandle) GetResource('acur', 128);
	DetachResource((Handle) acur);
	InitCursorCtl(acur);
	err	=	
		AESend(
			&cmd, &reply, kAEWaitReply+kAENeverInteract, 
			kAENormalPriority, kNoTimeOut, 
			(AEIdleUPP) &uSubLaunchIdle, nil);
		
	if (AEGetParamPtr(&reply, 'stat', typeLongInteger, &type, (Ptr) status, 4, &size))
		*status = 0;
		
	AEDisposeDesc(&cmd);
	AEDisposeDesc(&addr);
	AEDisposeDesc(&reply);
	
	DisposeHandle((Handle) acur);
	
	InitCursorCtl(NULL);
	
	return err;
}
