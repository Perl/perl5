/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPEditor.c			-	Delegate to external editor
Author	:	Matthias Neeracher

Language	:	MPW C

$Log: MPEditor.c,v $
Revision 1.3  2001/09/26 21:51:15  pudge
Sync with perforce maint-5.6/macperl/macos/macperl

Revision 1.2  2001/09/10 07:39:03  neeri
External editor would sometimes corrupt files (MacPerl Bug #456329)

Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.4  1998/04/14 19:46:38  neeri
MacPerl 5.2.0r4b2

Revision 1.3  1998/04/07 01:46:36  neeri
MacPerl 5.2.0r4b1

Revision 1.2  1997/08/08 16:57:56  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:42  neeri
Checked into CVS

*********************************************************************/

#include "MPGlobals.h"
#include "MPEditor.h"
#include "SubLaunch.h"
#include "MPWindow.h"
#include "MPScript.h"
#include "MPSave.h"
#include "MPFile.h"
#include "MPUtils.h"

#include <AEBuild.h>
#include <AppleEvents.h>
#include <AERegistry.h>
#include <Files.h>
#include <Folders.h>
#include <StandardFile.h>
#include <string.h>
#include <Lists.h>

#define FAILOSERR(call) if (err = call) return err; else 0

static short		gExternalFileCount = 0;
static FSSpec **	gExternalFiles		 = nil;

static OSErr EditorRunning(OSType creator, ProcessSerialNumber *psn)
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
	} while(info.processSignature != creator);

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

static OSErr FindAppOnVolume(OSType signature, short vRefNum, FSSpec *file)
{
	OSErr 	err;
	DTPBRec 	pb;
	
	/* Get Acess path to Desktop database on this volume */
	
	pb.ioVRefNum 		= vRefNum;
	pb.ioNamePtr 		= nil;
	FAILOSERR(PBDTGetPath(&pb));
	
	pb.ioIndex 			= 0;
	pb.ioFileCreator 	= signature;
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

static OSErr LaunchIt(FSSpecPtr fileSpec, ProcessSerialNumber * psn )
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

static OSErr FindExternalEditor(OSType signature, FSSpec *spec)
{
	OSErr 	err;
	short 	vRefNum, sysVRefNum, index;
	Boolean 	hasDesktopDB;
	
	FAILOSERR(GetSysVolume(&sysVRefNum));
	
	vRefNum = sysVRefNum;
	
	for (index = 0; !err; err = GetIndVolume(++index,&vRefNum)) {
		if (!index || vRefNum != sysVRefNum) {
			if (err = VolHasDesktopDB(vRefNum,&hasDesktopDB))
				return err;
				
			if (hasDesktopDB)	
				switch (err = FindAppOnVolume(signature, vRefNum, spec))	{
				case noErr:
					return noErr;
				case afpItemNotFound:
					break;
				default:
					return err;
				}
		}
	}
	
	return fnfErr;
}

#define CLEANUPOSERR(e)	if (err = e) goto cleanup; else 0

static ICAppSpec sShuck = { '·uck', "\pShuck" };

OSErr FindHelper(StringPtr helperName, ICAppSpecHandle * helperHdl, Boolean launch)
{
	OSErr						err = fnfErr;
	ICAttr					attr;
	long						size = sizeof(ICFileSpec);
	FSSpec					spec;
	ICAppSpecHandle		helperPref;
	ProcessSerialNumber	psn;
	
	if (gICInstance) {
		helperPref = (ICAppSpecHandle) NewHandle(0);
		if (!ICFindPrefHandle(gICInstance, helperName, &attr, (Handle)helperPref)) {
foundHelper:
			if (!launch || (err = EditorRunning(helperPref[0]->fCreator, &psn))) {
				CLEANUPOSERR(FindExternalEditor(helperPref[0]->fCreator, &spec));
				HLock((Handle) helperPref);
				memcpy(helperPref[0]->name, spec.name, *spec.name+1);
				HUnlock((Handle) helperPref);
				if (launch)
					CLEANUPOSERR(LaunchIt(&spec, &psn));
			}
		} else if (helperName[0] == 10 && !memcmp(helperName+8, "pod", 3)) {
			/* Fix up Shuck */
			ICSetPref(gICInstance, helperName, ICattr_no_change, 
				(Ptr)&sShuck, sizeof(ICAppSpec));
			if (!ICFindPrefHandle(gICInstance, helperName, &attr, (Handle)helperPref))
				goto foundHelper;
		} 
	} else
		helperPref = nil;
		
cleanup:
	if (!err && helperHdl)
		*helperHdl = helperPref;
	else if (helperPref)
		DisposeHandle((Handle) helperPref);
	
	return err;
}

void InitExternalEditor()
{
	FindHelper("\pHelper¥editor", &gExternalEditor, false);
}

void CloseExternalEditor()
{
}

Boolean HasExternalEdits()
{
	return gExternalFileCount != 0;
}

void GetExternalEditorName(StringPtr name)
{
	char * trunc;
	
	if (gExternalEditor) {
		HLock((Handle) gExternalEditor);
		memcpy(name, gExternalEditor[0]->name, *gExternalEditor[0]->name+1);
		while (trunc = (char *) memchr((char *) name+1, ' ', *name))
			if (trunc == (char *) name + 1)
				memmove(name + 2, name + 1, --*name);
			else
				*name = trunc - (char *)name - 1;
		HUnlock((Handle) gExternalEditor);
	} else
		strcpy((char *) name, (char *) "\pEditor");
}

static OSErr FindExternalDocument(
	Boolean front, FSSpec * spec, short * index, short *fileIndex)
{
	OSErr						err;
	short						i;
	short						file;
	ProcessSerialNumber	psn;
	AppleEvent				getEvent;
	AppleEvent				getReply;
	DescType					type;
	Size						size;
	char *					title;
	char						name[260];
	
	if (!gExternalFileCount)	/* No external edits currently known */
		return fnfErr;

	FAILOSERR(EditorRunning(gExternalEditor[0]->fCreator, &psn));

	for (i=1;; ++i) {	
		FAILOSERR(
			AEBuildAppleEvent(
				kAECoreSuite, kAEGetData,
				typeProcessSerialNumber, &psn, sizeof(psn), 0, 0, 
				&getEvent,
				"'----':"
					"obj{"
						"want:type('prop'),"
						"from:obj{"
							"want:type('cwin'),"
							"from:(),"
							"form:'indx',"
							"seld:long(@)"
						"},"
						"form:'prop',"
						"seld:type('pnam')"
					"}",
				i));
		err = 
			AESend(
				&getEvent, &getReply, 
				kAEWaitReply+kAENeverInteract, kAENormalPriority, kAEDefaultTimeout,
				&uSubLaunchIdle, nil);
		AEDisposeDesc(&getEvent);
		if (err)
			return err;
		err = AEGetKeyPtr(&getReply, '----', 'TEXT', &type, name, 260, &size);
		AEDisposeDesc(&getReply);
		if (err)
			return err;
		name[size] = 0;
		if (title = strrchr(name, ':'))
			++title;
		else
			title = name;
		if (front) {
			HLock((Handle) gExternalFiles);
			for (file = 0; file<gExternalFileCount; ++file) {
				FSSpec * thisFile = gExternalFiles[0]+(file<<1)+1;
				if (!memcmp(thisFile->name+1, title, *thisFile->name))
					break;
			}
			HUnlock((Handle) gExternalFiles);
			if (file<gExternalFileCount) {
				if (spec)
					*spec = gExternalFiles[0][file<<1];
				if (index)
					*index= i;
				if (fileIndex)
					*fileIndex = file;
				
				return noErr;
			} else
				return fnfErr;
		} else {
			if (!memcmp(spec->name+1, title, *spec->name)) {
				if (index)
					*index= i;
				return noErr;
			}
		}
	}
}

Boolean GetExternalEditorDocumentName(StringPtr name)
{
	OSErr			err;
	short 		index;
	FSSpec		spec;
	
	if (err = FindExternalDocument(true, &spec, nil, &index))
		return false;
		
	memcpy(name, spec.name, *spec.name+1);
	
	return true;
}

static OSErr SendEditorEvent(OSType eventID, FSSpec * file)
{
	OSErr						err;
	ProcessSerialNumber 	psn;
	AppleEvent				editorEvent;
	AppleEvent				ignoreReply;

	MakeSelfPSN(&psn);
			
	FAILOSERR(
		AEBuildAppleEvent(MPAppSig, eventID,
					typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber),
					0, 0, &editorEvent,
					"'----':fss(@)",
					sizeof(FSSpec), file));
	err =	AESend(
				&editorEvent, &ignoreReply, 
				kAENoReply+kAENeverInteract, kAENormalPriority, kAEDefaultTimeout,
				nil, nil);
	AEDisposeDesc(&editorEvent);
	
	return err;
}

OSErr StartExternalEditor(Boolean front)
{
	OSErr	fileErr;
	
	if (front) {
		WindowPtr	win;
		DPtr			doc;
		
		for (win = FrontWindow(); win; win = GetNextWindow(win)) {
			if (!IsWindowVisible(win) || !Ours(win))
				continue;
			if ((doc = DPtrFromWindowPtr(win)) && doc->kind == kDocumentWindow)
				break;
		}
		
		if (!win)
			return fnfErr;

		if (doc->dirty || !doc->u.reg.everSaved) {
			if (!doc->u.reg.everSaved) {
				fileErr = GetFileNameToSaveAs(doc);
				if (!fileErr)
					fileErr = IssueSaveCommand(doc, &doc->theFSSpec);
				else if (fileErr != userCanceledErr)	
					FileError((StringPtr) "\perror saving ", doc->theFileName);
			} else
				fileErr = IssueSaveCommand(doc, nil);
			if (fileErr)
				return fileErr;
		}

		return SendEditorEvent('xEDT', &doc->theFSSpec);
	} else {
		StandardFileReply	reply;
		
		StandardGetFile(&uGetScriptFilter, MacPerlFileTypeCount, MacPerlFileTypes, &reply);
		if (reply.sfGood)
			return SendEditorEvent('xEDT', &reply.sfFile);
		else 
			return userCanceledErr;
	}
}

OSErr EditExternal(FSSpec * spec)
{
	return SendEditorEvent('xEDT', spec);
}

/* Defined in MacPerl.xs */
#if TARGET_RT_MAC_CFM
extern RoutineDescriptor	uMacListUpdate;
extern RoutineDescriptor	uMacListFilter;
#else
pascal void MacListUpdate();
pascal void MacListFilter();
#define uMacListUpdate MacListUpdate
#define uMacListFilter MacListFilter
#endif
extern ListHandle	gPickList;

static void UpdateList()
{
	short			itemHit;
	Boolean		done;
	DialogPtr	dlg;
	Cell			mycell;
	short			mytype;
	Handle		myhandle;
	Point			cellsize;
	Rect			listrect, dbounds;
		
	InitCursor();
	dlg = GetNewAppDialog(2020);
	
	SetText(dlg, 3, "\pSelect the files to update:");
	GetDialogItem(dlg, 4, &mytype, &myhandle, &listrect);
	SetDialogItem(dlg, 4, mytype, (Handle)&uMacListUpdate, &listrect);
	
	SetPort(dlg);
	InsetRect(&listrect, 1, 1);
	SetRect(&dbounds, 0, 0, 1, gExternalFileCount);
	cellsize.h = (listrect.right - listrect.left);
	cellsize.v = 17;

	listrect.right -= 15;

	gPickList = LNew(&listrect, &dbounds, cellsize, 0,
							dlg, true, false, false, true);

	LSetDrawingMode(false, gPickList);
	
	HLock((Handle) gExternalFiles);
	mycell.h = mycell.v = 0;
	for (; mycell.v<gExternalFileCount; ++mycell.v)	{
		StringPtr	name = gExternalFiles[0][mycell.v << 1].name;
		LSetCell(name+1, *name, mycell, gPickList);
	}
	HUnlock((Handle) gExternalFiles);

	LSetDrawingMode(true, gPickList);
	ShowWindow(dlg);
	
	for (done=false; !done; ) {
		SetPort(dlg);
		DrawDefaultOutline(dlg, ok);
		ModalDialog((ModalFilterUPP) &uMacListFilter, &itemHit);
		switch (itemHit) {
		case ok:
			mycell.h = mycell.v = 0;
			done = true;
			HLock((Handle) gExternalFiles);
			while (LGetSelect(true, &mycell, gPickList)) {
				SendEditorEvent('xUPD', gExternalFiles[0]+(mycell.v << 1));
				LDelRow(1, mycell.v, gPickList);
			}
			if (gExternalFiles)
				HUnlock((Handle) gExternalFiles);
			break;
		case cancel:
			done = true;
			break;
		}
	}	/* Modal Loop */

	SetPort(dlg);
	
	LDispose(gPickList);
	gPickList = nil;
	DisposeDialog(dlg);
}

OSErr UpdateExternalEditor(Boolean front)
{
	if (front) {
		OSErr			err;
		FSSpec		spec;
		
		FAILOSERR(FindExternalDocument(true, &spec, nil, nil));
		
		return SendEditorEvent('xUPD', &spec);
	} else {
		UpdateList();
		
		return noErr;
	}
}

static OSErr MakeScratch(FSSpec * file, FSSpec * scratch)
{
	OSErr			err;
	DocType		docType;
	CInfoPBRec	info;
	
	FAILOSERR(
		FindFolder(kOnSystemDisk, kTemporaryFolderType, true, 
			&scratch->vRefNum, &scratch->parID));
	memcpy(scratch->name, file->name, *file->name+1);
	if (*scratch->name > 24)
		return bdNamErr;
	memcpy(scratch->name+*scratch->name+1, " [Perl]", 7);
	*scratch->name += 7;
	if (!GUSIFSpGetCatInfo(scratch, &info)) {
		if (*scratch->name > 28)
			return bdNamErr;
		memcpy(scratch->name+*scratch->name+1, " #1", 3);
		*scratch->name += 3;
		do {
			++scratch->name[*scratch->name];
		} while (!GUSIFSpGetCatInfo(scratch, &info));
	}
	docType = GetDocType(file);
			
	if (docType == kUnknownDoc)
		return errAEWrongDataType;
	else
		return File2File(*file, docType, *scratch, 'TEXT');

	return noErr;
}

pascal OSErr DoExternalEditor(const AppleEvent * event, AppleEvent * reply, long refCon)
{
	OSErr						err;
	char						state;
	int						i;
	DescType					type;
	Size						size;
	WindowPtr				win;
	FSSpec					file;
	FSSpec					scratch;
	ProcessSerialNumber	psn;
	
	FAILOSERR(
		AEGetParamPtr(event, '----', 
			typeFSS, &type, (Ptr)&file, sizeof(FSSpec), &size));

	if (!gExternalFileCount)
		i = 0;
	else {
		state = HGetState((Handle) gExternalFiles);
		HLock((Handle) gExternalFiles);
		for (i = 0; i < (gExternalFileCount << 1); ++i)
			if (SameFSSpec(gExternalFiles[0]+i, &file))
				break;
		HSetState((Handle) gExternalFiles, state);
	}
	
	i >>= 1;
	
	if (!refCon)	{						/* Edit */
		AppleEvent	openEvent;
		AppleEvent	ignoreReply;
		
		if (EditorRunning(gExternalEditor[0]->fCreator, &psn)) {
			FSSpec	editor;
			
			FAILOSERR(FindExternalEditor(gExternalEditor[0]->fCreator, &editor));
			FAILOSERR(LaunchIt(&editor, &psn));
		}
		if (i < gExternalFileCount)
			scratch = gExternalFiles[0][(i<<1)+1];
		else {
			FAILOSERR(MakeScratch(&file, &scratch));
			if (!gExternalFileCount++)
				PtrToHand((Ptr) &file, (Handle *)&gExternalFiles, sizeof(FSSpec));
			else
				PtrAndHand((Ptr) &file, (Handle)gExternalFiles, sizeof(FSSpec));
			PtrAndHand((Ptr) &scratch, (Handle)gExternalFiles, sizeof(FSSpec));
		}
		FAILOSERR(
			AEBuildAppleEvent(kCoreEventClass, kAEOpenDocuments,
						typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber),
						0, 0, &openEvent,
						"'----':fss(@),~FSnd:type('McPL')",
						sizeof(FSSpec), &scratch));
		SetFrontProcess(&psn);
		err =	AESend(
					&openEvent, &ignoreReply, 
					kAENoReply+kAENeverInteract, kAENormalPriority, kAEDefaultTimeout,
					nil, nil);
		AEDisposeDesc(&openEvent);
		
		return err;
	} else {									/* Update */
		short		windowIndex;
		FSSpec *	files;
		
		if (i == gExternalFileCount)
			return fnfErr;
		files = gExternalFiles[0]+(i<<1);
		HLock((Handle) gExternalFiles);
		if (refCon != 2 && !FindExternalDocument(false, files, &windowIndex, nil)) {
			AppleEvent				closeEvent;
			AppleEvent				ignoreReply;
			ProcessSerialNumber	psn;
			
			EditorRunning(gExternalEditor[0]->fCreator, &psn);
			AEBuildAppleEvent(
				kAECoreSuite, kAEClose,
				typeProcessSerialNumber, &psn, sizeof(psn), 0, 0, 
				&closeEvent,
				"'----':"
					"obj{"
						"want:type('cwin'),"
						"from:(),"
						"form:'indx',"
						"seld:long(@)"
					"},"
				"savo:'yes '",
				windowIndex);
			AESend(
					&closeEvent, &ignoreReply, 
					kAEWaitReply+kAENeverInteract, kAENormalPriority, kAEDefaultTimeout,
					nil, nil);
			AEDisposeDesc(&closeEvent);
		}
		err = File2File(files[1], 'TEXT', files[0], GetDocType(files));
		if (refCon != 2)
			FSpDelete(files+1);
		if (win = AlreadyOpen(files, nil)) {
			CloseMyWindow(win);
			OpenOld(*files, GetDocType(files));
		}
		HSetState((Handle) gExternalFiles, state);
		if (refCon != 2) {
			Munger((Handle) gExternalFiles, (i<<1)*sizeof(FSSpec), nil, 2*sizeof(FSSpec), nil, 0);
			if (!--gExternalFileCount) {
				DisposeHandle((Handle) gExternalFiles);
				gExternalFiles = 0;
			}
		}
		return err;
	}
}
