/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPDrop.c			-	Droplets
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPDrop.c,v $
Revision 1.2  2001/01/23 05:31:47  neeri
Make Droplet and Font LDEF buildable with SC (Tasks 24870, 24872)

Revision 1.2  1998/04/07 01:46:35  neeri
MacPerl 5.2.0r4b1

Revision 1.1  1997/06/23 17:10:37  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:50:15  neeri
Debugger support.

Revision 1.1  1994/02/27  23:00:19  neeri
Initial revision

Revision 0.1  1993/10/02  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <Dialogs.h>
#include <QuickDraw.h>
#include <Windows.h>
#include <Menus.h>
#include <Fonts.h>
#include <AppleEvents.h>
#include <AERegistry.h>
#include <Processes.h>
#include <files.h>
#include <StandardFile.h>
#include <Aliases.h>
#include <Gestalt.h>
#include <Folders.h>
#include <Errors.h>
#include <Resources.h>
#include <SegLoad.h>

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

#define FAILOSERR(call) if (err = call) return err; else 0

Boolean		gQuitting;
FSSpec		gMySelf;
EventRecord	gLastEvent;

pascal Boolean CheckEnvironment()
{
	long	result;
	
	if (Gestalt(gestaltAppleEventsAttr, &result))
		return false;
		
	return (result & (1 << gestaltAppleEventsPresent)) != 0;
}  /* CheckEnvironment */

/* The following stuff is adapted from Jens Peter Alfke's SignatureToApp code */

OSErr MacPerlRunning(ProcessSerialNumber *psn)
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
		
		FAILOSERR(GetProcessInformation(psn, &info));
	} while(info.processSignature != 'McPL');

	*psn = info.processNumber;
	
	return noErr;
}

OSErr GetSysVolume(short *vRefNum)
{
	long dir;
	
	return FindFolder(kOnSystemDisk, kSystemFolderType, false, vRefNum, &dir);
}

OSErr GetIndVolume(short index, short *vRefNum)
{
	OSErr 			err;
	ParamBlockRec 	pb;
	
	pb.volumeParam.ioNamePtr 	= nil;
	pb.volumeParam.ioVolIndex 	= index;
	
	FAILOSERR(PBGetVInfoSync(&pb));
	
	*vRefNum = pb.volumeParam.ioVRefNum;
	
	return noErr;
}

OSErr VolHasDesktopDB(short vRefNum, Boolean * hasDesktop)
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

OSErr FindAppOnVolume(short vRefNum, FSSpec *file)
{
	OSErr 	err;
	DTPBRec 	pb;
	
	/* Get Acess path to Desktop database on this volume */
	
	pb.ioVRefNum 		= vRefNum;
	pb.ioNamePtr 		= nil;
	FAILOSERR(PBDTGetPath(&pb));
	
	pb.ioIndex 			= 0;
	pb.ioFileCreator 	= 'McPL';
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

OSErr LaunchIt(FSSpecPtr fileSpec, ProcessSerialNumber * psn )
{
	OSErr 					err;
	LaunchParamBlockRec 	pb;
	
	pb.launchBlockID 			= extendedBlock;
	pb.launchEPBLength 		= extendedBlockLen;
	pb.launchFileFlags 		= launchNoFileFlags;
	pb.launchControlFlags	= launchContinue + launchNoFileFlags;
	pb.launchAppSpec 			= fileSpec;
	pb.launchAppParameters	= nil;
	
	FAILOSERR(LaunchApplication(&pb));

	*psn = pb.launchProcessSN;
	
	return noErr;
}

/* Get the psn ofa copy of MacPerl. Launch one if necessary. Buy one. Steal one. */
static OSErr LaunchMacPerl(ProcessSerialNumber *psn)
{
	OSErr 	err;
	short 	vRefNum, sysVRefNum, index;
	FSSpec 	file;
	Boolean 	hasDesktopDB;
	
	/* See if ToolServer is already running:					*/
	err	= MacPerlRunning(psn);
	
	if	(err != procNotFound)
		return err;
	
	/* Not running, try to launch it */
	
	FAILOSERR(GetSysVolume(&sysVRefNum));
	
	vRefNum = sysVRefNum;
	
	for (index = 0; !err; err = GetIndVolume(++index,&vRefNum)) {
		if (!index || vRefNum != sysVRefNum) {
			if (err = VolHasDesktopDB(vRefNum,&hasDesktopDB))
				return err;
				
			if (hasDesktopDB)	
				switch (err = FindAppOnVolume(vRefNum, &file))	{
				case noErr:
					return LaunchIt(&file, psn);
				case afpItemNotFound:
					break;
				default:
					return err;
				}
		}
	}
	
	switch (err) {
	case nsvErr:
	case afpItemNotFound:
		return fnfErr;
	default:
		return err;
	}
}

void WhoAmI(FSSpec * me)
{
	FCBPBRec		fcb;
	
	fcb.ioNamePtr	=	me->name;
	fcb.ioRefNum	=	CurResFile();
	fcb.ioFCBIndx	=	0;
	
	PBGetFCBInfoSync(&fcb);
	
	me->vRefNum	=	fcb.ioFCBVRefNum;
	me->parID	=	fcb.ioFCBParID;
}

pascal OSErr Yo(const AppleEvent *message, AppleEvent *reply, long refcon)
{
	OSErr						err;
	AppleEvent				doscript;
	ProcessSerialNumber	perl;
	AEAddressDesc			perladdr;
	AEDescList				args;
	AEDescList				incoming;
	AliasHandle				alias;
	AEDesc					arg;
	AEKeyword				kw;
	Boolean					doDebug = true;
	
	gQuitting = true;

	WaitNextEvent(0, &gLastEvent, 0, nil);
	
	switch (err = LaunchMacPerl(&perl)) {
	case noErr:
		break;
	case fnfErr:
		ParamText(
			(StringPtr) "\pFailed to launch MacPerl. Either you don't have MacPerl "
			"or your desktop needs to be rebuilt.", (StringPtr) "\p", "\p", "\p");
		Alert(4096, nil);
		
		return err;
	default:
		ParamText(
			(StringPtr) "\pFailed to launch MacPerl (possibly because of "
			"a memory problem).", (StringPtr) "\p", "\p", "\p");
		Alert(4096, nil);
		
		return err;
	}
	
	FAILOSERR(SetFrontProcess(&perl));
	
	FAILOSERR(
		AECreateDesc(
			typeProcessSerialNumber,
			(Ptr)&perl,
			sizeof(ProcessSerialNumber),
			&perladdr));
	
	if (refcon && (gLastEvent.modifiers & optionKey))
		FAILOSERR(
			AECreateAppleEvent(
				'McPL', kAEOpenDocuments, &perladdr, 
				kAutoGenerateReturnID, kAnyTransactionID, 
				&doscript));
	else {
		FAILOSERR(
			AECreateAppleEvent(
				kAEMiscStandards, kAEDoScript, &perladdr, 
				kAutoGenerateReturnID, kAnyTransactionID, 
				&doscript));
		if (gLastEvent.modifiers & controlKey)
			FAILOSERR(AEPutParamPtr(&doscript, 'DEBG', typeBoolean, (Ptr) &doDebug, 1));
	}
	
	FAILOSERR(AECreateList(nil,0,false,&args));
	FAILOSERR(NewAlias(nil,&gMySelf,&alias));
	
	HLock((Handle) alias);
	FAILOSERR(AEPutPtr(&args, 0, typeAlias, (Ptr) *alias, GetHandleSize((Handle) alias)));
	DisposeHandle((Handle) alias);
	
	if (!AEGetParamDesc(message, keyDirectObject, typeAEList, &incoming)) {
		short	i = 1;
		
		while (!AEGetNthDesc(&incoming, i++, typeWildCard, &kw, &arg)) {
			FAILOSERR(AEPutDesc(&args, 0, &arg));
			AEDisposeDesc(&arg);
		}
		
		AEDisposeDesc(&incoming);
	}
	
	FAILOSERR(AEPutParamDesc(&doscript, keyDirectObject, &args));
	FAILOSERR(
		AESend(
			&doscript, reply,
			kAENoReply+kAEAlwaysInteract,
			kAENormalPriority, kAEDefaultTimeout,
			nil, nil));
	
	return noErr;
}

pascal void MainEvent(void)
{
	if (WaitNextEvent(everyEvent, &gLastEvent, 60, nil))
		switch (gLastEvent.what) {
		case kHighLevelEvent:
			AEProcessAppleEvent(&gLastEvent);
			break;
		}
}

#if defined(__SC__)
QDGlobals	qd;
#endif

void main()
{
	InitGraf(&qd.thePort);
	InitFonts();
	FlushEvents(everyEvent, 0);
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	InitCursor();

	gQuitting  		= false;

	/*check environment checks to see if we are running 7.0*/
	if (!CheckEnvironment()) {
		SetCursor(&qd.arrow);
		/*pose the only 7.0 alert*/
		ParamText(
			(StringPtr) "\pMacPerl droplets need at least System 7.0 to run "
			"(you may run me from the \"MacPerl Runtime\" "
			"application, however).", (StringPtr) "\p", "\p", "\p");
		Alert(4096, nil);
		
		ExitToShell();
	}

	/* We will not go native anytime soon */
	
	AEInstallEventHandler( kCoreEventClass, kAEOpenApplication, (AEEventHandlerUPP)Yo, 1, false) ;
	AEInstallEventHandler( kCoreEventClass, kAEOpenDocuments,   (AEEventHandlerUPP)Yo, 0, false) ;

	WhoAmI(&gMySelf);
	
	while (!gQuitting)
		MainEvent();
}

void RemoveConsole()
{
}
