/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPFile.c			-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPFile.c,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.3  1998/04/07 01:46:37  neeri
MacPerl 5.2.0r4b1

Revision 1.2  1997/08/08 16:57:58  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:44  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:00:47  neeri
Initial revision

Revision 0.6  1993/09/17  00:00:00  neeri
Runtime version

Revision 0.5  1993/08/28  00:00:00  neeri
Handle multiple preference files

Revision 0.4  1993/08/17  00:00:00  neeri
Enable Save

Revision 0.3  1993/08/13  00:00:00  neeri
Write bounds rectangles

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <Errors.h>
#include <Resources.h>
#include <PLStringFuncs.h>
#include <AppleEvents.h>
#include <AERegistry.h>
#include <StandardFile.h>
#include <GUSIFileSpec.h>
#include <Script.h>
#include <Balloons.h>
#include <Devices.h>
#include <ControlDefinitions.h>

#include "MPFile.h"
#include "MPScript.h"
#include "MPSave.h"
#include "MPEditor.h"
#include "MPPreferences.h"

/**-----------------------------------------------------------------------
		Name: 			FileError
		Purpose:		Puts up an error alert.
	-----------------------------------------------------------------------**/


#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal void FileError(Str255 s, Str255 f)
{
	SetCursor(&qd.arrow);
	ParamText(s, f, (StringPtr) "\p", (StringPtr) "\p");
 	AppAlert(ErrorAlert);
}

/**-----------------------------------------------------------------------
		Name: 			DoClose
		Purpose:		Closes a window.
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal OSErr DoClose(WindowPtr aWindow, Boolean canInteract, DescType dialogAnswer)
{
 	DPtr    aDocument;
 	short   alertResult;
 	Str255  theName;
	OSErr   myErr;

	myErr = noErr;

 	if (gWCount > 0) {
		aDocument = DPtrFromWindowPtr(aWindow);

		if (aDocument->kind == kDocumentWindow) {
			if (aDocument->dirty)
				if (canInteract && (dialogAnswer==kAEAsk)) {
					if (aDocument->u.reg.everSaved == false)
						GetWTitle(aWindow, theName); /* Pick it up as a script may have changed it */
					else
						PLstrcpy(theName, aDocument->theFileName);
	
					ParamText(theName, (StringPtr) "\p", (StringPtr) "\p", (StringPtr) "\p");
					SetCursor(&qd.arrow);
					alertResult = AppAlert(SaveAlert);
					switch (alertResult) {
					case aaSave:
						myErr = SaveAskingName(aDocument, canInteract);
						break;
	
					case aaCancel:
						return userCanceledErr;
	
					case aaDiscard:
						aDocument->dirty = false;
						break;
					}
				} else {
					if (dialogAnswer==kAEYes)
						myErr = SaveAskingName(aDocument, canInteract);
					else
						myErr = noErr; /* Don't save */
				}
				
			if (!myErr) {
				CloseMyWindow(aWindow);
			}
		} else if (aDocument->u.cons.selected) {
			if (!gQuitting) {
				SysBeep(0);
	
				return userCanceledErr;
			}
		} else 
			SaveConsole(aDocument);
	} else
		myErr = errAEIllegalIndex;

	return myErr;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

//  DoQuit
//  saveOpt - one of kAEAsk,kAEYes,kAENo
//  if kAEYes or kAEAsk then AEInteactWithUser should have been called
//  before DoQuit. Assumes that it can interact if it needs to.

pascal void DoQuit(DescType saveOpt)
{
	WindowPtr	aWindow;
	WindowPtr	nextWindow;
	short			theKind;

	if (gRunningPerl && (AppAlert(AbortAlert) == 2))
		return;
		
	gQuitting = true;

	for (aWindow = FrontWindow(); aWindow; aWindow = nextWindow) {
		nextWindow = GetNextWindow(aWindow);
		if (Ours((WindowPtr) aWindow)) {
			if (DoClose((WindowPtr) aWindow, true, saveOpt)) {
				gQuitting = false;
				
				return;
			}
		} else {
			theKind = GetWindowKind(aWindow);
			if (theKind < 0)
				CloseDeskAcc(theKind);
		}
	}
}

pascal Boolean GetFileFilter(CInfoPBPtr pb)
{
	switch (GetDocTypeFromInfo(pb)) {
	case kPreferenceDoc:
		/* We don't want preference files here. Maybe we should */
	case kUnknownDoc:
		return true;
	default:
		return false;
	}
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uGetFileFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppFileFilterProcInfo, GetFileFilter);
#else
#define uGetFileFilter *(FileFilterUPP)&GetFileFilter
#endif

pascal OSErr GetFile(FSSpec *theFSSpec)
{
	StandardFileReply  reply;

	BuildSEList();
	
	StandardGetFile(&uGetFileFilter, MacPerlFileTypeCount, MacPerlFileTypes, &reply);

	if (reply.sfGood) {
		*theFSSpec = reply.sfFile;
		return noErr;
	} else
		return userCanceledErr;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal OSErr DoCreate(FSSpec theSpec)
{
	OSErr err;

	err = FSpCreate(&theSpec, MPAppSig, 'TEXT', smSystemScript);

	if (!err)
		HCreateResFile(theSpec.vRefNum, theSpec.parID, theSpec.name);
	else
		ShowError((StringPtr) "\pCreating", err);

	return err;
}

pascal OSErr SaveConsole(DPtr doc)
{
	OSErr			err;
	short       resFile;
	HHandle     theHHandle;
	Str255		title;
	Boolean		existing;
	
	resFile	=	CurResFile();
	
	OpenPreferences();
	if (gPrefsFile) {
		UseResFile(gPrefsFile);
		GetWTitle(doc->theWindow, title);
		
		if (theHHandle = (HHandle) Get1NamedResource('TFSS', title)) {
			existing = true;
		} else {
			existing = false;
			theHHandle = (HHandle)NewHandle(sizeof(HeaderRec));
		}
		
		HLock((Handle)theHHandle);
	
		(*theHHandle)->theRect     = doc->theWindow->portRect;
		OffsetRect(
			&(*theHHandle)->theRect,
			-doc->theWindow->portBits.bounds.left,
			-doc->theWindow->portBits.bounds.top);
			
		GetFontName((*(doc->theText))->txFont, (StringPtr) &(*theHHandle)->theFont);
		
		(*theHHandle)->theSize     = (*(doc->theText))->txSize;
		(*theHHandle)->lastID      = 0;
		(*theHHandle)->numSections = 0;
	
		HUnlock((Handle)theHHandle);
	
		if (existing) {
			ChangedResource((Handle) theHHandle);
			WriteResource((Handle) theHHandle);
			UpdateResFile(gPrefsFile);
		} else {
			AddResource((Handle)theHHandle, 'TFSS', Unique1ID('TFSS'), title);
		}
		
		err = ResError();
		
		CloseResFile(gPrefsFile);
		UseResFile(resFile);
	}
	
	if (doc->u.cons.cookie) {
		/* We might need this window again. */
		DoHideWindow(doc->theWindow);
		TESetSelect(0, 32767, doc->theText);
		TEDelete(doc->theText);
	
		if (doc->u.cons.fence < 32767)
			doc->u.cons.fence	= 0;
	} else /* Done with this window */
		CloseMyWindow(doc->theWindow);
	
	return err;
} 

pascal void ApplySettings(DPtr doc, HPtr settings)
{
	short		fNum;
	FontInfo	info;
	Rect		bounds;
	
	GetFNum(settings->theFont, &fNum);
	SetPort(doc->theWindow);
	TextFont(fNum);
	TextSize(settings->theSize);
	GetFontInfo(&info);
	
	(*doc->theText)->txFont 		= fNum;
	(*doc->theText)->txSize 		= settings->theSize;
	(*doc->theText)->lineHeight	= info.ascent+info.descent+info.leading;
	(*doc->theText)->fontAscent	= info.ascent;
	
	bounds.top							= settings->theRect.top - 13;
	bounds.left							= settings->theRect.left + 5;
	bounds.bottom						= settings->theRect.top  - 5;
	bounds.right						= settings->theRect.right - 5;
	
	if (settings->theRect.right > settings->theRect.left + 50 &&
		settings->theRect.bottom > settings->theRect.top  + 50 &&
		RectInRgn(&bounds, GetGrayRgn())
	) {
		MoveWindow(doc->theWindow, settings->theRect.left, settings->theRect.top, false);
		SizeWindow(
			doc->theWindow,
			settings->theRect.right - settings->theRect.left,
			settings->theRect.bottom - settings->theRect.top,
			false);
	}
		
	ResizeMyWindow(doc);
}

pascal void RestoreConsole(DPtr doc)
{
	short       resFile;
	HHandle     theHHandle;
	Str255		title;
	
	resFile	=	CurResFile();
	OpenPreferences();
	if (!gPrefsFile)
		return;
		
	UseResFile(gPrefsFile);
	GetWTitle(doc->theWindow, title);
	
	if (theHHandle = (HHandle) Get1NamedResource('TFSS', title)) {
 		HLock((Handle)theHHandle);
		
		ApplySettings(doc, *theHHandle);
		
		HUnlock((Handle)theHHandle);
	}
	
	CloseResFile(gPrefsFile);
	UseResFile(resFile);
}


/** -----------------------------------------------------------------------
		Name: 		GetFileContents
		Purpose:		Opens the document specified by theFSSpec and puts
						the contents into theDocument.
	 -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal OSErr GetFileContents(FSSpec spec, DPtr theDocument)
{
	long			theSize;
	short			oldRes;
	short			resFile;
	short			refNum;
	OSErr			err;
	HHandle		aHandle;
	Handle		gHandle;

	oldRes	=	CurResFile();
	resFile 	=	HOpenResFile(spec.vRefNum, spec.parID, spec.name, fsRdPerm);
	
	theDocument->u.reg.everLoaded = true;
	theDocument->u.reg.origFSSpec = spec;
	
	if (theDocument->inDataFork) {
		if (err = HOpenDF(spec.vRefNum, spec.parID, spec.name, fsRdPerm, &refNum)) {
			ShowError((StringPtr) "\pread file - HOpenDF", err);
			refNum = 0;
			
			goto giveUp;
		}
	
		if (err = GetEOF(refNum, &theSize))
			goto giveUp;

  		gHandle = NewHandle(theSize);

		HLock(gHandle);
		if (err = FSRead(refNum, &theSize, *gHandle))
			return err;
		HUnlock(gHandle);
		FSClose(refNum);
	} else {
		gHandle	=	Get1NamedResource('TEXT', (StringPtr) "\p!");
		
		if (gHandle) 
			DetachResource(gHandle);
		else {
			err = ResError();
			
			goto giveUp;
		}
	}

	if (resFile != -1) {
		aHandle = nil;

		if (Count1Resources('TFSS'))
			aHandle = (HHandle)Get1Resource('TFSS', 255);

		if (aHandle) {
			HLock((Handle) aHandle);
			ApplySettings(theDocument, *aHandle);
		}

		/*
			If there is a print record saved, ditch the old one
			created by new document and fill this one in
		*/
		if (Count1Resources('TFSP')) {
			if (theDocument->thePrintSetup)
				DisposeHandle((Handle)theDocument->thePrintSetup);

			theDocument->thePrintSetup = (THPrint)Get1Resource('TFSP', 255);
		  	HandToHand((Handle *)&theDocument->thePrintSetup);

			PrOpen();
			PrValidate(theDocument->thePrintSetup);
			PrClose();
		}

		CloseResFile(resFile);

		if (err = ResError()) {
			ShowError((StringPtr) "\pread file- CloseResFile", err);
			return err;
		}
	}

	HLock(gHandle);
	if (GetHandleSize(gHandle) > 32000) {
		PtrToXHand(
			*gHandle, 
			(*theDocument->theText)->hText, 
			GetHandleSize(gHandle));
		
		err = elvisErr;
	} else
		TESetText(*gHandle, GetHandleSize(gHandle), theDocument->theText);
	DisposeHandle(gHandle);

	if (err == fnfErr)
		return noErr;
	else
  		return err;

giveUp:	
	if (refNum)
		FSClose(refNum);
		
	if (resFile > -1)
		CloseResFile(resFile);
	
	UseResFile(oldRes);
	
	return err;
} /* GetFileContents */


#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal OSErr SaveAskingName(DPtr aDocument, Boolean canInteract)
{
	OSErr	myErr;

	if (aDocument->kind != kDocumentWindow || !aDocument->u.reg.everSaved) {

		if (canInteract) {
			if (myErr = GetFileNameToSaveAs(aDocument))
				return myErr;

			if (myErr = SaveWithoutTemp(aDocument, aDocument->theFSSpec))
				return myErr;			
			return noErr;
		} else
			return errAENoUserInteraction;

	} else
		return SaveUsingTemp(aDocument);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

void NukeFileProcess(FSSpec * spec)
{
	/* Search for process running with this file and quit it if necessary */
	ProcessInfoRec 		info;
	FSSpec					procSpec;
	CInfoPBRec				specInfo;
	AEDesc					processDesc;
	AppleEvent				quitEvent;
	AppleEvent				ignoreReply;
	ProcessSerialNumber	psn;
	
	if (GUSIFSpGetCatInfo(spec, &specInfo))
		return;
		
	psn.highLongOfPSN = 0;
	psn.lowLongOfPSN  = kNoProcess;
	while (!GetNextProcess(&psn))	{
		info.processInfoLength 	= sizeof(info);
		info.processName 			= nil;
		info.processAppSpec 		= &procSpec;
		
		if (GetProcessInformation(&psn, &info))
			continue;
		if (info.processSignature != specInfo.hFileInfo.ioFlFndrInfo.fdCreator)
			continue;
		if (!SameFSSpec(&procSpec, spec))
			continue;
		if (AECreateDesc(
			typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), &processDesc)
		)
			return;
		if(AECreateAppleEvent(kCoreEventClass, kAEQuitApplication, &processDesc,
						0, 0, &quitEvent)
		) 
			goto disposeProcDesc;
		AESend(&quitEvent, &ignoreReply, 
				 kAEWaitReply+kAENeverInteract, kAENormalPriority, kAEDefaultTimeout,
				 nil, nil);
		AEDisposeDesc(&quitEvent);
		AEDisposeDesc(&ignoreReply);
disposeProcDesc:
		AEDisposeDesc(&processDesc);
	}
}

pascal OSErr SaveUsingTemp(DPtr theDocument)
{
	OSErr		err;
	FSSpec	tempFSSpec;

	/*save the file to disk using a temporary file*/
	/*this is the recommended way of doing things*/
	/*first write out the file to disk using a temporary filename*/
	/*if it is sucessfully written, exchange the temporary file with the last one saved*/
	/*then delete the temporary file- so if anything goes wrong, the original version is still there*/
	/*first generate the temporary filename*/

	GetTempFSSpec(theDocument, &tempFSSpec);

	if (err = DoCreate(tempFSSpec))
		return err;

	if (err = DoSave(theDocument, tempFSSpec, theDocument->theFSSpec.name))
		return err;
	
	NukeFileProcess(&theDocument->theFSSpec);
	
	if (err = FSpExchangeFiles(&tempFSSpec, &theDocument->theFSSpec))
		return err;
	GUSIFSpTouchFolder(&theDocument->theFSSpec);
	
	/*we've exchanged the files, now delete the temporary one*/

	FSpDelete(&tempFSSpec);
	
	if (!err && theDocument->kind == kDocumentWindow) {
		theDocument->dirty 				= false;
		theDocument->u.reg.everSaved 	= true;
		theDocument->u.reg.origFSSpec = theDocument->theFSSpec;
	}

	
	return err;
}

pascal OSErr SaveWithoutTemp(DPtr theDocument, FSSpec spec)
{
	OSErr		err;
	
	if (err = DoSave(theDocument, spec, spec.name))
		return err;
	GUSIFSpTouchFolder(&spec);

	if (theDocument->kind == kDocumentWindow) {
		theDocument->dirty 				= false;
		theDocument->u.reg.everSaved 	= true;
		theDocument->u.reg.origFSSpec = theDocument->theFSSpec = spec;
				
		SetWTitle(theDocument->theWindow, theDocument->theFSSpec.name);
	}
	/* Rebuild list of standard scripts */
	AddStandardScripts();
	
	return noErr;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal short SaveScriptHook(short item, DialogPtr dlg, void * params)
{
	short				kind;
	ControlHandle	type;
	MenuHandle		typeMenu;
	Rect				r;
	DPtr				doc = (DPtr) params;
	
	if (GetWRefCon(dlg) != 'stdf')
		return item;
		
	switch (item) {
	case sfHookFirstCall:
		GetDialogItem(dlg, ssd_Type, &kind, (Handle *) &type, &r);
		typeMenu = (*(PopupPrivateDataHandle)(*type)->contrlData)->mHandle;
		
		AddExtensionsToMenu(typeMenu);
		SetControlMaximum(type, CountMItems(typeMenu));
		SetControlValue(type, Type2Menu(doc->type));
		
		return sfHookFirstCall;
	case ssd_Type:
		GetDialogItem(dlg, item, &kind, (Handle *) &type, &r);
		
		doc->type = (DocType) Menu2Type(GetControlValue(type));
		
		return sfHookNullEvent;
	default:
		return item;
	}
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uSaveScriptHook = 
		BUILD_ROUTINE_DESCRIPTOR(uppDlgHookYDProcInfo, SaveScriptHook);
#else
#define uSaveScriptHook *(DlgHookYDUPP)&SaveScriptHook
#endif

/*
	Fills in the document record with the user chosen destination
*/

pascal OSErr GetFileNameToSaveAs(DPtr theDocument)
{
	OSErr					err;
	StandardFileReply	reply;
	Str255            suggestName;
	Point					where;
	
	where.h = where.v = -1;

	GetWTitle(theDocument->theWindow, suggestName);

	HMSetDialogResID(SaveScriptDialog);
	CustomPutFile(
		(StringPtr) "\pSave Document As:", suggestName, &reply,
		SaveScriptDialog,
		where,
		&uSaveScriptHook,
		(ModalFilterYDUPP) nil,
		nil,
		(ActivateYDUPP) nil,
		theDocument);
	HMSetDialogResID(-1);

	if (reply.sfGood)
		switch (err = FSpDelete(&reply.sfFile)) {
		case noErr:
		case fnfErr:
			theDocument->theFSSpec = reply.sfFile;
			PLstrcpy(theDocument->theFileName, reply.sfFile.name);

			return noErr;
		default:
			return err;
		}
	else
		return userCanceledErr;
} /* GetFileNameToSaveAs */

#if !defined(powerc) && !defined(__powerc)
#pragma segment File
#endif

pascal DPtr MakeOldDoc(FSSpec aFSSpec, DocType type)
{
	DPtr  		theDocument;
	
	theDocument = NewDocument(true, kDocumentWindow);

	SetWTitle(theDocument->theWindow, aFSSpec.name);

	SetPort(theDocument->theWindow);

	theDocument->theFSSpec   = aFSSpec;

	PLstrcpy(theDocument->theFileName, aFSSpec.name);

	theDocument->dirty       		= false;
	theDocument->inDataFork			= type == kPlainTextDoc;
	
	/* We *can* open documents created by unknown save extensions, but we can't
	   save them again 
	*/
	if (CanSaveAs(type)) {
		CInfoPBRec	info;

		theDocument->type 				= type;
		if (!GUSIFSpGetCatInfo(&aFSSpec, &info) && info.hFileInfo.ioFlAttrib & 1)
			theDocument->u.reg.everSaved	= false;		/* Locked file, don't overwrite */
		else
			theDocument->u.reg.everSaved	= true;
	} else {
		theDocument->type					= kPlainTextDoc;
		theDocument->u.reg.everSaved	= false;
	}

	return theDocument;
}

pascal OSErr OpenOld(FSSpec aFSSpec, DocType type)
{
	DPtr  		theDocument;
	OSErr 		fileErr;
	WindowPtr	win;

	if (win = AlreadyOpen(&aFSSpec, nil)) {
		SelectWindow(win);
		
		return noErr;
	}
	
	theDocument	=	MakeOldDoc(aFSSpec, type);
	
	fileErr = GetFileContents(aFSSpec, theDocument);

	if (!fileErr) {
		ResizeMyWindow(theDocument);
		DoShowWindow(theDocument->theWindow);
	} else {
		if (fileErr == elvisErr) {
			theDocument->u.reg.everSaved	= false;
#ifdef RUNTIME
			if (AEInteractWithUser(kAEDefaultTimeout, nil, nil))
#endif
				switch (AppAlert(gExternalEditor ? ElvisEditAlert : ElvisAlert)) {
				case 1:
					SaveAskingName(theDocument, true);
					break;
				case 2:
					/* Abandon */
					break;
				case 3:
					/* Edit */
					EditExternal(&aFSSpec);
					break;
				}
		} else
			FileError((StringPtr) "\pError Opening ", aFSSpec.name);
		
		CloseMyWindow(theDocument->theWindow);
	}

	return fileErr;
} /* OpenOld */

pascal OSErr File2File(FSSpec aFSSpec, DocType type, FSSpec toFSSpec, DocType newtype)
{
	DPtr  		theDocument;
	OSErr 		fileErr;

	theDocument	=	MakeOldDoc(aFSSpec, type);
	
	switch (fileErr = GetFileContents(aFSSpec, theDocument)) {
	case elvisErr:
		fileErr = noErr;
		/* Fall through */
	case noErr:
		theDocument->type = newtype;
		theDocument->u.reg.everSaved	= false;
		if (SameFSSpec(&aFSSpec, &toFSSpec))
			fileErr = SaveUsingTemp(theDocument);
		else
			fileErr = SaveWithoutTemp(theDocument, toFSSpec);
		
		/* Fall through */
	default:
		CloseMyWindow(theDocument->theWindow);
	}

	return fileErr;
} /* File2File */

pascal OSErr Handle2File(Handle text, FSSpec toFSSpec, DocType newtype)
{
	DPtr  		theDocument;
	OSErr 		fileErr;

	theDocument = NewDocument(true, kDocumentWindow);
	
	HLock(text);
	PtrToXHand(*text, (*theDocument->theText)->hText, GetHandleSize(text));
	HUnlock(text);
	
	theDocument->u.reg.everSaved	= false;
	theDocument->type 				= newtype;

	fileErr = SaveWithoutTemp(theDocument, toFSSpec);
	
	CloseMyWindow(theDocument->theWindow);

	return fileErr;
} /* Handle2File */

pascal DocType GetDocTypeFromFile(short vRefNum, long dirID, StringPtr name)
{
	short			resFile;
	short			nuFile;
	OSType	**	rtType;
	DocType		type	=	kUnknownDoc;
	
	resFile	= CurResFile();
	nuFile	= HOpenResFile(vRefNum, dirID, name, fsRdPerm);
	
	if (nuFile != -1) {
		if (rtType = (OSType **) Get1Resource('MrPL', 128))
			type = **(DocType **) rtType;
			
		CloseResFile(nuFile);
	}
	UseResFile(resFile);
	
	return type;
}

pascal DocType GetDocTypeFromInfo(CInfoPBPtr info)
{
	DocType		type	=	kUnknownDoc;
	
	switch (info->hFileInfo.ioFlFndrInfo.fdType) {
	case 'APPL':
		if (info->hFileInfo.ioFlFndrInfo.fdCreator == MPAppSig) 
			/* A heuristic to separate old runtimes from PowerPC executables */
			if (info->hFileInfo.ioFlLgLen && info->hFileInfo.ioFlLgLen < 100000)
				return kOldRuntime6Doc; 
		
		break;
	case 'TEXT':
		return kPlainTextDoc;
	case 'pref':
		switch (info->hFileInfo.ioFlFndrInfo.fdCreator) {
		case MPAppSig:
		case MPRtSig:
			return kPreferenceDoc;
		}
		break;
	default:
		break;
	}
	
	/* Ultimately, with save extensions, every file could be ours */
	return GetDocTypeFromFile(
		info->hFileInfo.ioVRefNum, 
		info->hFileInfo.ioFlParID, 
		info->hFileInfo.ioNamePtr);
}

pascal DocType GetDocType(FSSpec * spec)
{
	CInfoPBRec	info;

	if (GUSIFSpGetCatInfo(spec, &info))
		return kUnknownDoc;
	else
		return GetDocTypeFromInfo(&info);
}