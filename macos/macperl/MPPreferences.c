/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPPreferences.c	-	Handle Preference Settings
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPPreferences.c,v $
Revision 1.8  2001/04/24 05:11:32  pudge
Remove extra : at end of TMPDIR in prefs

Revision 1.7  2001/01/30 05:17:22  pudge
Temp. change to pref file name

Revision 1.6  2001/01/24 09:51:30  neeri
Fix library paths (Bug 129817)

Revision 1.4  2001/01/16 21:01:42  pudge
Minor changes

Revision 1.3  2001/01/11 08:05:04  neeri
Fixed preference editing

Revision 1.4  1998/04/14 19:46:42  neeri
MacPerl 5.2.0r4b2

Revision 1.3  1998/04/07 01:46:41  neeri
MacPerl 5.2.0r4b1

Revision 1.2  1997/11/18 00:53:55  neeri
MacPerl 5.1.5

Revision 1.1  1997/06/23 17:10:53  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:52:40  neeri
Inline Input.

Revision 1.1  1994/02/27  23:01:32  neeri
Initial revision

Revision 0.1  1993/12/08  00:00:00  neeri
Separated from MPUtils

*********************************************************************/

#include "MPPreferences.h"
#include "MPUtils.h"
#include "MPWindow.h"
#include "MPFile.h"
#include "patchlevel.h"

#include <PLStringFuncs.h>
#include <Events.h>
#include <Traps.h>
#include <Dialogs.h>
#include <Fonts.h>
#include <Packages.h>
#include <ToolUtils.h>
#include <AppleEvents.h>
#include <GUSIFileSpec.h>
#include <Folders.h>
#include <Resources.h>
#include <OSUtils.h>
#include <Files.h>
#include <Lists.h>
#include <Icons.h>
#include <Script.h>
#include <LowMem.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <Balloons.h>
#include <Navigation.h>

pascal void OpenPreferenceFile(FSSpec * spec)
{
	Str255		name;
	short			oldResFile;
	short			res;
	short	**		defaultfont;
	PerlPrefs **prefs;
	
	oldResFile	=	CurResFile();

	gPrefsFile = HOpenResFile(spec->vRefNum, spec->parID, spec->name, fsRdWrPerm);
	
	if (gPrefsFile == -1) {
		gPrefsFile = 0;
		 
		return;
	}
	
	if (!Get1Resource('STR#', LibraryPaths)) {
		Handle	lib;
		short		count = 0;
		
		PtrToHand((Ptr) &count, &lib, sizeof(short));
		
		AddResource(lib, 'STR#', LibraryPaths, (StringPtr) "\p");
	}
	
	if (!Get1Resource('STR#', EnvironmentVars)) {
		Handle	env;
		Handle	userString;
		short	count = 2;
		char	state;
		char *	tmp;
		int	tmplen;
		FSSpec	tmpspec;
		
		PtrToHand((Ptr) &count, &env, sizeof(short));
		userString = GetResource('STR ', -16096);
		state      = HGetState(userString);
		HLock(userString);
		PtrAndHand((Ptr) "\pUSER=", env, 6);
		PtrAndHand(*userString+1, env, **userString);
		(*env)[2]  += **userString;
		HSetState(env, state);
		FindFolder(
			kOnSystemDisk, kTemporaryFolderType, true, 
			&tmpspec.vRefNum, &tmpspec.parID);
		GUSIFSpUp(&tmpspec);
		tmp = GUSIFSp2FullPath(&tmpspec);
		tmplen = strlen(tmp);
		PtrAndHand((Ptr) "\pTMPDIR=", env, 8);
		PtrAndHand(tmp, env, tmplen);
		(*env)[3+(*env)[2]] += tmplen;
		
		AddResource(env, 'STR#', EnvironmentVars, (StringPtr) "\p");
	}
	
	if (!(defaultfont = (short **) Get1Resource('PFNT', 128))) {
		Handle	font;
		
		PtrToHand((Ptr) &gFormat.size, &font, sizeof(short));
		GetFontName(gFormat.font, name);
		AddResource(font, 'PFNT', 128, name);
	} else {
		OSType type;
		
		GetResInfo((Handle) defaultfont, &res, &type, name);
		GetFNum(name, &gFormat.font);
		
		if (gFormat.font)
			gFormat.size = **defaultfont;
		else {
			gFormat.font = GetAppFont();
			gFormat.size = GetDefFontSize();
		}
	}

	if (!(prefs = (PerlPrefs **) Get1Resource('PPRF', 128))) {
		PtrToHand((Ptr) &gPerlPrefs, (Handle *)&prefs, sizeof(PerlPrefs));
		AddResource((Handle) prefs, 'PPRF', 128, (StringPtr) "\p");
	} else {
		gPerlPrefs.runFinderOpens 	= (*prefs)->runFinderOpens;
		gPerlPrefs.checkType 	  	= (*prefs)->checkType;
		if ((*prefs)->version >= PerlPrefVersion413) {
			gPerlPrefs.inlineInput	= (*prefs)->inlineInput;
			if (gTSMTEImplemented)
				UseInlineInput(gPerlPrefs.inlineInput);
		}
	}
	
	UseResFile(oldResFile);
}

pascal void OpenPreferences()
{
	FSSpec		prefPath;
	CInfoPBRec	info;
	FCBPBRec		fcb;
	Str63			name;

	gPrefsFile = 0;
	
	GetFNum((StringPtr) "\pMonaco", &gFormat.font);
	gFormat.size = gFormat.font ? 9 : GetDefFontSize();
	gFormat.font = gFormat.font ? gFormat.font : GetAppFont();
	
	fcb.ioNamePtr	=	(StringPtr) &name;
	fcb.ioRefNum	=	gAppFile;
	fcb.ioFCBIndx	=	0;
	
	PBGetFCBInfoSync(&fcb);
	
	gAppVol	=	fcb.ioFCBVRefNum;
	gAppDir	=	fcb.ioFCBParID;
	
	prefPath.vRefNum 	= gAppVol;
	prefPath.parID		= gAppDir;
	/* Temporarily make path with "¶", for development */
	PLstrcpy(prefPath.name, (StringPtr) "\pMacPerl 5 Preferences ¶");
	
	if (GUSIFSpGetCatInfo(&prefPath, &info))
		if (FindFolder(
			kOnSystemDisk, 
			kPreferencesFolderType, 
			true, 
			&prefPath.vRefNum,
			&prefPath.parID)
		)
			return;
			
	if (GUSIFSpGetCatInfo(&prefPath, &info)) {
		if (HCreate(prefPath.vRefNum, prefPath.parID, prefPath.name, 'McPL', 'pref'))
			return;
			
		HCreateResFile(prefPath.vRefNum, prefPath.parID, prefPath.name);
	}
	
	OpenPreferenceFile(&prefPath);
}

static short		PrefSubDialog 	= 	1;
static short		PathCount;
static ListHandle	PathList;

pascal void DrawPrefIcon(DialogPtr dlg, short item)
{
	short		resFile;
	short		kind;
	Handle	h;
	Rect		r;
	Str31		title;
	FontInfo	info;
	
	resFile = CurResFile();
	UseResFile(gAppFile);
	GetDialogItem(dlg, item, &kind, &h, &r);
	PlotIconID(&r, atNone, (item == PrefSubDialog) ? ttSelected : ttNone, PrefDialog+item);
	UseResFile(resFile);
	
	GetIndString(title, PrefDialog, item);
	TextFont(1);
	TextSize(9);
	GetFontInfo(&info);

	MoveTo(r.left - (StringWidth(title) - 32 >> 1), r.bottom+2+info.ascent);
	DrawString(title);
	
	if (item == PrefSubDialog) {
		
		r.top 	= r.bottom + 2;
		r.bottom = r.top + info.ascent+info.descent+info.leading+2;
		r.left 	= r.left - (StringWidth(title) - 32 >> 1) - 1;
		r.right  = r.left + StringWidth(title) + 2;
		
		InvertRect(&r);
	}
	
	TextFont(0);
	TextSize(12);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawPrefIcon = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawPrefIcon);
#else
#define uDrawPrefIcon *(UserItemUPP)&DrawPrefIcon
#endif

pascal void DrawPathList(DialogPtr dlg, short item)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused(item)
#endif
	Rect	r;
	
	TextFont(0);
	TextSize(12);
	LUpdate(dlg->visRgn, PathList);
	r = (*PathList)->rView;
	InsetRect(&r, -1, -1);
	FrameRect(&r);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawPathList = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawPathList);
#else
#define uDrawPathList *(UserItemUPP)&DrawPathList
#endif

pascal void PrefCommonFilter(DialogPtr dlg, EventRecord * ev, short * item)
{
	Rect			r;
	WindowPtr	win;
	
	SetPort(dlg);
	switch (ev->what) {
	case mouseDown:
		switch (FindWindow(ev->where, &win)) {
		case inDrag:
			if (win != dlg)
				return;
				
			r = qd.screenBits.bounds;
			InsetRect(&r, 10, 10);
			DragWindow(win, ev->where, &r);
			
			ev->what = nullEvent;
			
			return;
		case inSysWindow:
			SystemClick(ev, win);
			
			ev->what = nullEvent;
			
			return;
		default:
			return;
		}
	case updateEvt:
		win = (WindowPtr) ev->message;
		if (win != dlg) {
			if (IsDialogEvent(ev))
				DialogSelect(ev, &dlg, item);
			else
				DoUpdate(DPtrFromWindowPtr(win), win);
			
			ev->what = nullEvent;
		}
		break;
	}
}

static Boolean ChooseFSObject(StringPtr msg, char * path, Boolean folder, Boolean hasDefault)
{
	NavReplyRecord		theReply;
	NavDialogOptions	dialogOptions;
	OSErr					theErr = noErr;
	FSSpec				spec;	
	AEDesc 				defSpec;
	
	theErr = NavGetDefaultDialogOptions(&dialogOptions);
	
	memcpy(dialogOptions.message, msg, msg[0]+1);
	
	dialogOptions.dialogOptionFlags	&= ~kNavAllowMultipleFiles;
	dialogOptions.preferenceKey 		= 'P5LB';
	
	if (hasDefault 
	 && (GUSIPath2FSp(path, &spec) || AECreateDesc(typeFSS, &spec, sizeof(FSSpec), &defSpec))
	) 
		hasDefault = false;
	
	if (folder)
		theErr = NavChooseFolder(hasDefault ? &defSpec : nil, &theReply, &dialogOptions, nil, nil, nil);
	else
		theErr = NavChooseObject(hasDefault ? &defSpec : nil, &theReply, &dialogOptions, nil, nil, nil);
		
	if (hasDefault)
		AEDisposeDesc(&defSpec);
	
	if ((theReply.validRecord)&&(theErr == noErr))
		{
		// grab the target FSSpec from the AEDesc:	
		AEDesc 	resultDesc;

		if ((theErr = AECoerceDesc(&(theReply.selection),typeFSS,&resultDesc)) == noErr)
			if ((theErr = AEGetDescData ( &resultDesc, &spec, sizeof ( FSSpec ))) == noErr)
				{
					strcpy(path, GUSIFSp2FullPath(&spec));
				}
		AEDisposeDesc(&resultDesc);
		
		theErr = NavDisposeReply(&theReply);
		}
		
	return !theErr;
}

pascal Boolean PrefLibFilter(DialogPtr dlg, EventRecord * ev, short * item)
{
	Point 		cell;
	short			kind;
	short			len;
	Handle		h;
	Rect			r;
	WindowPtr	win;
	Str63			msg;
	char			contents[256];
	
	PrefCommonFilter(dlg, ev, item);
	switch (ev->what) {
	case keyDown:
		switch (ev->message & charCodeMask) {
		case '\n':
		case 3:
			*item = pd_Done;
			
			return true;
		case 8:
			*item = pld_Remove;
			
			return true;
		default:
			break;
		}
	case mouseDown:
		switch (FindWindow(ev->where, &win)) {
		case inContent:
			break;
		default:
			return false;
		}
		TextFont(0);
		TextSize(12);
		cell = ev->where;
		GlobalToLocal(&cell);
		GetDialogItem(dlg, pld_List, &kind, &h, &r);
		if (PtInRect(cell, &r)) {
			if (LClick(cell, ev->modifiers, PathList))
				for (SetPt(&cell, 0, 0); LGetSelect(true, &cell, PathList); ++cell.v) {
					len = 256;
					LGetCell(contents, &len, cell, PathList);
					contents[len] = 0;
					GetIndString(msg, PrefDialog, pd_ChangePath);
					
					if (ChooseFSObject(msg, contents, true, true))
						LSetCell((Ptr) contents, strlen(contents), cell, PathList);
				} 
			ev->what = nullEvent;
		}
		break;			
	case activateEvt:
		LActivate(ev->modifiers & activeFlag, PathList);
		break;
	}
	
	return false;
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uPrefLibFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, PrefLibFilter);
#else
#define uPrefLibFilter *(ModalFilterUPP)&PrefLibFilter
#endif

static short PrefsLibDialog(DialogPtr prefs, short resFile)
{
	short			item;
	short			kind;
	short			len;
	int			length;
	Boolean		done;
	Handle		h;
	Handle		paths;
	Point			cell;
	Rect			bounds;
	Rect			dbounds;
	Str63			msg;
	Str255		contents;
	char			data[256];
	FSSpec		libspec;
	char *		libpath;

	UseResFile(gPrefsFile);
	
	paths 		= Get1Resource('STR#', LibraryPaths);
	PathCount	= **(short **)paths;

	UseResFile(resFile);
	
	h	= GetAppResource('DITL', PrefDialog+PrefSubDialog);
	AppendDITL(prefs, h, overlayDITL); 

	GetDialogItem(prefs, pld_List, &kind, &h, &bounds);
	SetDialogItem(prefs, pld_List, kind, (Handle) &uDrawPathList, &bounds);

	libspec.vRefNum	= 	gAppVol;
	libspec.parID		=	gAppDir;
	PLstrcpy(libspec.name, "\plib");
	
	libpath  = GUSIFSp2FullPath(&libspec);
	length   = strlen(libpath);
	if (length < 118) {
		if (libpath[length-1] == ':')
			--length;
		libpath[length -= 3] = 0;
		contents[0] =
			sprintf((char *)(contents+1), "%slib:\n%ssite_perl:\n:", libpath, libpath);
		SetText(prefs, pld_Defaults, contents);
	}

	SetPt(&cell, bounds.right - bounds.left, 16);
	SetRect(&dbounds, 0, 0, 1, PathCount);
	PathList = LNew(&bounds, &dbounds, cell, 0, prefs, false, false, false, true);
	
	UseResFile(gPrefsFile);
	SetPt(&cell, 0, 0);
	for (; cell.v < PathCount; ++cell.v) {
		GetIndString(contents, LibraryPaths, cell.v + 1);
		if (contents[1] == ':') {
			memcpy(libspec.name+1, contents+2, *libspec.name = *contents-1);
		
			libpath  = GUSIFSp2FullPath(&libspec);
			memcpy(contents+1, libpath, *contents = strlen(libpath));
		}
		LSetCell((Ptr)contents+1, contents[0], cell, PathList);
	}
	UseResFile(resFile);
	
	LSetDrawingMode(true, PathList);
	HMSetDialogResID(PrefDialog+PrefSubDialog);
	ShowWindow(prefs);
		
	for (done = false; !done; ) {
		ModalDialog(&uPrefLibFilter, &item);
		switch (item) {
		case pd_Done:
		case pd_EnvIcon:
		case pd_ScriptIcon:
		case pd_InputIcon:
		case pd_ConfigIcon:
			done = true;
			break;
		case pld_Remove:
			SetPt(&cell, 0, 0);
			
			if (LGetSelect(true, &cell, PathList) && AppAlert(PrefLibDelID) == 1)
				do {
					LDelRow(1, cell.v, PathList);
						
					--PathCount;
				} while (LGetSelect(true, &cell, PathList));
				
			break;
		case pld_Add:
			GetIndString(msg, PrefDialog, pd_AddPath);
			if (ChooseFSObject(msg, data, true, false)) {
					SetPt(&cell, 0, PathCount);
					LAddRow(1, PathCount++, PathList);
					LSetCell(data, strlen(data), cell, PathList);
			}	
			break;
		}
	}
	
	PtrToXHand(&PathCount, paths, sizeof(short));
	SetPt(&cell, 0, 0);
	
	{
		FSSpec	item;
		char *	shortpath;
		
		GUSIFSpUp(&libspec);
		
		for (; cell.v < PathCount; ++cell.v) {
			len = 255;
			LGetCell((Ptr) contents+1, &len, cell, PathList);
			contents[0] 	 = len;
			contents[len+1] = 0;
			if (!GUSIPath2FSp((char *)contents+1, &item)) {
#if GUSI_RELATIVE_PATHS_FIXED
				shortpath = GUSIFSp2DirRelPath(&item, &libspec);
#else
				shortpath = GUSIFSp2FullPath(&item);
#endif
				if (!strchr(shortpath, ':')) {
					memcpy(contents+2, shortpath, *contents = strlen(shortpath));
					++*contents;
					contents[1] = ':';
				} else
					memcpy(contents+1, shortpath, *contents = strlen(shortpath));
			}
		
			PtrAndHand(contents, paths, *contents+1);
		}
	}
	
	ChangedResource((Handle) paths);
	WriteResource((Handle) paths);
	
	LDispose(PathList);

	ShortenDITL(prefs, CountDITL(prefs) - pd_Outline);

	return item;
}

pascal Boolean PrefEnvEditFilter(DialogPtr dlg, EventRecord * ev, short * item)
{
	PrefCommonFilter(dlg, ev, item);
	return StdFilterProc(dlg, ev, item);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uPrefEnvEditFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, PrefEnvEditFilter);
#else
#define uPrefEnvEditFilter *(ModalFilterUPP)&PrefEnvEditFilter
#endif

static int PrefsEnvEdit(StringPtr env)
{
	Boolean		done;
	int			result;
	int			len;
	short			item;
	DialogPtr	envEdit;
	Ptr			equals;
	Str255		contents;
	Str63			msg;
	char 			data[256];
	
	envEdit = GetNewAppDialog(PrefEnvAddID);
	
	equals = PLstrchr(env, '=');
	*equals= *env - (equals - (Ptr) env);
	*env  -= *equals + 1;
	SetText(envEdit, pead_Name, env);
	SetText(envEdit, pead_Value, (StringPtr)equals);

	SetDialogDefaultItem(envEdit, 1);
	SetDialogCancelItem(envEdit, 2);
	SetDialogTracksCursor(envEdit, true);
	
	ShowWindow(envEdit);

	for (done = false; !done;) {	
		ModalDialog(&uPrefEnvEditFilter, &item);
		switch (item) {
		case pead_OK:
			RetrieveText(envEdit, pead_Name, contents);
			if (!contents[0])
				FileError("\pVariable name cannot be empty!", "\p");
			else if (!PLstrcmp(contents, env)) {	// name was not changed
				done 		= true;
				result  	= 0;
			} else { // Check for duplicates
				Point	 cell;
				short	 len;
				Str255 other;
				
				SetPt(&cell, 0, 0);
				for (; cell.v < PathCount; ++cell.v) {
					len = 255;
					LGetCell((Ptr) other+1, &len, cell, PathList);
					if (!memcmp(other+1, contents+1, contents[0]) && other[contents[0]+1] == '=') {
						FileError("\pA variable with that name already exists!", "\p");
						goto failed;
					}
				}
				done 		= true;
				result	= 1;
failed:
				;
			}
			break;
		case pead_Cancel:
			done   = true;
			result = -1;
			break;
		case pead_Folder:
		case pead_File:
			GetIndString(msg, PrefDialog, pd_ChangePath);
			if (ChooseFSObject(msg, data, item==pead_Folder, false)) {
				len = strlen(data);
				RetrieveText(envEdit, pead_Value, contents);
				if (item == pead_Folder && data[len-1]!= ':')
					data[len++] = ':';
				if (contents[0] + len + 1 < 256) {
					if (contents[0]) 
						PLstrcat(contents, "\p,");
					memcpy(contents+contents[0]+1, data, len);
					contents[0] += len;
					SetText(envEdit, pead_Value, contents);
				}
			}
			break;
		}
	}
	
	if (result>-1) {
		RetrieveText(envEdit, pead_Name, env);
		RetrieveText(envEdit, pead_Value, contents);
		PLstrcat(env, "\p=");
		PLstrcat(env, contents);
	}
		
	DisposeDialog(envEdit);
	
	return result;
}


pascal Boolean PrefEnvFilter(DialogPtr dlg, EventRecord * ev, short * item)
{
	Point 		cell;
	short			kind;
	short			len;
	Handle		h;
	Rect			r;
	WindowPtr	win;
	Str255		contents;
	
	PrefCommonFilter(dlg, ev, item);
	switch (ev->what) {
	case keyDown:
		switch (ev->message & charCodeMask) {
		case '\n':
		case 3:
			*item = pd_Done;
			
			return true;
		case 8:
			*item = ped_Remove;
			
			return true;
		default:
			break;
		}
	case mouseDown:
		switch (FindWindow(ev->where, &win)) {
		case inContent:
			break;
		default:
			return false;
		}
		TextFont(0);
		TextSize(12);
		cell = ev->where;
		GlobalToLocal(&cell);
		GetDialogItem(dlg, pld_List, &kind, &h, &r);
		if (PtInRect(cell, &r)) {
			if (LClick(cell, ev->modifiers, PathList))
				for (SetPt(&cell, 0, 0); LGetSelect(true, &cell, PathList); ++cell.v) {
					len = 255;
					LGetCell((Ptr)contents+1, &len, cell, PathList);
					*contents = len;
					switch (PrefsEnvEdit(contents)) {
					case 1:
						LSetSelect(false, cell, PathList);
						SetPt(&cell, 0, PathCount);
						LAddRow(1, PathCount++, PathList);
						LSetSelect(true, cell, PathList);
						/* Fall through */
					case 0:
						LSetCell((Ptr)contents+1, *contents, cell, PathList);
						break;
					}
				}
			ev->what = nullEvent;
		}
		break;			
	case activateEvt:
		LActivate(ev->modifiers & activeFlag, PathList);
		break;
	}
	
	return false;
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uPrefEnvFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, PrefEnvFilter);
#else
#define uPrefEnvFilter *(ModalFilterUPP)&PrefEnvFilter
#endif

static short PrefsEnvDialog(DialogPtr prefs, short resFile)
{
	short			item;
	short			kind;
	short			len;
	Boolean		done;
	Handle		h;
	Handle		paths;
	Point			cell;
	Rect			bounds;
	Rect			dbounds;
 	Str255		contents;

	UseResFile(gPrefsFile);
	
	paths	 		= Get1Resource('STR#', EnvironmentVars);
	PathCount	= **(short **)paths;

	UseResFile(resFile);
	
	h	= GetAppResource('DITL', PrefDialog+PrefSubDialog);
	AppendDITL(prefs, h, overlayDITL); 

	GetDialogItem(prefs, ped_List, &kind, &h, &bounds);
	SetDialogItem(prefs, ped_List, kind, (Handle) &uDrawPathList, &bounds);
		
	SetPt(&cell, bounds.right - bounds.left, 16);
	SetRect(&dbounds, 0, 0, 1, PathCount);
	PathList = LNew(&bounds, &dbounds, cell, 0, prefs, false, false, false, true);
	
	UseResFile(gPrefsFile);
	SetPt(&cell, 0, 0);
	for (; cell.v < PathCount; ++cell.v) {
		GetIndString(contents, EnvironmentVars, cell.v + 1);
		LSetCell((Ptr)contents+1, contents[0], cell, PathList);
	}
	UseResFile(resFile);
	
	LSetDrawingMode(true, PathList);
	HMSetDialogResID(PrefDialog+PrefSubDialog);
	ShowWindow(prefs);
		
	for (done = false; !done; ) {
		ModalDialog(&uPrefEnvFilter, &item);
		switch (item) {
		case pd_Done:
		case pd_LibIcon:
		case pd_ScriptIcon:
		case pd_InputIcon:
		case pd_ConfigIcon:
			done = true;
			break;
		case ped_Remove:
			SetPt(&cell, 0, 0);
			
			if (LGetSelect(true, &cell, PathList) && AppAlert(PrefEnvDelID) == 1)
				do {
					LDelRow(1, cell.v, PathList);
						
					--PathCount;
				} while (LGetSelect(true, &cell, PathList));
				
			break;
		case ped_Add:
			PLstrcpy(contents, "\p=");
			if (PrefsEnvEdit(contents) == 1) {
					SetPt(&cell, 0, PathCount);
					LAddRow(1, PathCount++, PathList);
					LSetCell((Ptr)contents+1, *contents, cell, PathList);
			}	
			break;
		}
	}
	
	PtrToXHand(&PathCount, paths, sizeof(short));
	SetPt(&cell, 0, 0);
	
	for (; cell.v < PathCount; ++cell.v) {
		len = 255;
		LGetCell((Ptr) contents+1, &len, cell, PathList);
		contents[0] 	 = len;		
		PtrAndHand(contents, paths, *contents+1);
	}
	
	ChangedResource((Handle) paths);
	WriteResource((Handle) paths);
	
	LDispose(PathList);

	ShortenDITL(prefs, CountDITL(prefs) - pd_Outline);

	return item;
}

pascal Boolean PrefSubFilter(DialogPtr dlg, EventRecord * ev, short * item)
{	
	PrefCommonFilter(dlg, ev, item);
	switch (ev->what) {
	case keyDown:
		switch (ev->message & charCodeMask) {
		case '\n':
		case 3:
			*item = pd_Done;
			
			return true;
		default:
			break;
		}
	}
	
	return false;
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uPrefSubFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, PrefSubFilter);
#else
#define uPrefSubFilter *(ModalFilterUPP)&PrefSubFilter
#endif

static short PrefsScriptDialog(DialogPtr prefs, short resFile)
{
	short			item;
	short			kind;
	Boolean		done;
	Handle		h;
	Handle		pref;
	Rect			bounds;
	
	h	= GetAppResource('DITL', PrefDialog+PrefSubDialog);
	AppendDITL(prefs, h, overlayDITL); 
	
	GetDialogItem(prefs, psd_Edit, &kind, &h, &bounds);
	SetControlValue((ControlHandle) h, !gPerlPrefs.runFinderOpens);
	GetDialogItem(prefs, psd_Run, &kind, &h, &bounds);
	SetControlValue((ControlHandle) h, gPerlPrefs.runFinderOpens);
	GetDialogItem(prefs, psd_Check, &kind, &h, &bounds);
	SetControlValue((ControlHandle) h, gPerlPrefs.checkType);
	HMSetDialogResID(PrefDialog+PrefSubDialog);
			
	for (done = false; !done; ) {
		ModalDialog(&uPrefSubFilter, &item);
		switch (item) {
		case pd_Done:
		case pd_LibIcon:
		case pd_EnvIcon:
		case pd_InputIcon:
		case pd_ConfigIcon:
			done = true;
			break;
		case psd_Edit:
		case psd_Run:
			gPerlPrefs.runFinderOpens = item == psd_Run;
			GetDialogItem(prefs, psd_Edit, &kind, &h, &bounds);
			SetControlValue((ControlHandle) h, !gPerlPrefs.runFinderOpens);
			GetDialogItem(prefs, psd_Run, &kind, &h, &bounds);
			SetControlValue((ControlHandle) h, gPerlPrefs.runFinderOpens);
			break;
		case psd_Check:
			gPerlPrefs.checkType = !gPerlPrefs.checkType;
			GetDialogItem(prefs, psd_Check, &kind, &h, &bounds);
			SetControlValue((ControlHandle) h, gPerlPrefs.checkType);
			break;
		}
	}

	UseResFile(gPrefsFile);
	if (pref = Get1Resource('PPRF', 128)) {
		PtrToXHand((Ptr) &gPerlPrefs, pref, sizeof(PerlPrefs));
		ChangedResource((Handle) pref);
		WriteResource((Handle) pref);
	}
	UseResFile(resFile);

	ShortenDITL(prefs, CountDITL(prefs) - pd_Outline);

	return item;
}

static short PrefsInputDialog(DialogPtr prefs, short resFile)
{
	short			item;
	short			kind;
	Boolean		done;
	Handle		h;
	Handle		pref;
	Rect			bounds;
	
	h	= GetAppResource('DITL', PrefDialog+PrefSubDialog);
	AppendDITL(prefs, h, overlayDITL); 
	
	GetDialogItem(prefs, pid_Inline, &kind, &h, &bounds);
	SetControlValue((ControlHandle) h, gPerlPrefs.inlineInput);
	HMSetDialogResID(PrefDialog+PrefSubDialog);
			
	for (done = false; !done; ) {
		ModalDialog(&uPrefSubFilter, &item);
		switch (item) {
		case pd_Done:
		case pd_LibIcon:
		case pd_EnvIcon:
		case pd_ScriptIcon:
		case pd_ConfigIcon:
			done = true;
			break;
		case pid_Inline:
			gPerlPrefs.inlineInput = !gPerlPrefs.inlineInput;
			GetDialogItem(prefs, pid_Inline, &kind, &h, &bounds);
			SetControlValue((ControlHandle) h, gPerlPrefs.inlineInput);
			break;
		}
	}

	UseResFile(gPrefsFile);
	if (pref = Get1Resource('PPRF', 128)) {
		PtrToXHand((Ptr) &gPerlPrefs, pref, sizeof(PerlPrefs));
		ChangedResource((Handle) pref);
		WriteResource((Handle) pref);
	}
	UseResFile(resFile);
	
	if (gTSMTEImplemented)
		UseInlineInput(gPerlPrefs.inlineInput);

	ShortenDITL(prefs, CountDITL(prefs) - pd_Outline);

	return item;
}

static short PrefsConfigDialog(DialogPtr prefs, short resFile)
{
	short			item;
	Boolean		done;
	Handle		h;
	
	h	= GetAppResource('DITL', PrefDialog+PrefSubDialog);
	AppendDITL(prefs, h, overlayDITL); 

	HMSetDialogResID(PrefDialog+PrefSubDialog);
			
	for (done = false; !done; ) {
		ModalDialog(&uPrefSubFilter, &item);
		switch (item) {
		case pd_Done:
		case pd_LibIcon:
		case pd_EnvIcon:
		case pd_ScriptIcon:
		case pd_InputIcon:
			done = true;
			break;
		case pcd_Launch:
			if (gICInstance) {
				ICEditPreferences(gICInstance, "\p");
				item = pd_Done;
				done = true;
			}
			break;
		}
	}

	ShortenDITL(prefs, CountDITL(prefs) - pd_Outline);

	return item;
}

pascal void DoPrefDialog()
{
	short			resFile;
	short			kind;
	Handle		h;
	DialogPtr	prefs;
	Rect			bounds;
	
	resFile		= CurResFile();
	
	OpenPreferences();

	prefs = GetNewAppDialog(PrefDialog);

	GetDialogItem(prefs, pd_LibIcon, &kind, &h, &bounds);
	SetDialogItem(prefs, pd_LibIcon, kind, (Handle) &uDrawPrefIcon, &bounds);

	GetDialogItem(prefs, pd_EnvIcon, &kind, &h, &bounds);
	SetDialogItem(prefs, pd_EnvIcon, kind, (Handle) &uDrawPrefIcon, &bounds);

	GetDialogItem(prefs, pd_ScriptIcon, &kind, &h, &bounds);
	SetDialogItem(prefs, pd_ScriptIcon, kind, (Handle) &uDrawPrefIcon, &bounds);

	GetDialogItem(prefs, pd_InputIcon, &kind, &h, &bounds);
	SetDialogItem(prefs, pd_InputIcon, kind, (Handle) &uDrawPrefIcon, &bounds);

	GetDialogItem(prefs, pd_ConfigIcon, &kind, &h, &bounds);
	SetDialogItem(prefs, pd_ConfigIcon, kind, (Handle) &uDrawPrefIcon, &bounds);

	GetDialogItem(prefs, pd_Boundary, &kind, &h, &bounds);
	SetDialogItem(prefs, pd_Boundary, kind, (Handle) &uSeparator, &bounds);

	AdornDefaultButton(prefs, pd_Outline);

	ShowWindow(prefs);

	PrefSubDialog = pd_LibIcon;
	PrefSubDialog = PrefsLibDialog(prefs, resFile);
	
	while (PrefSubDialog != pd_Done) {
		SetPort(prefs);
		InvalRect(&prefs->portRect);
		EraseRect(&prefs->portRect);
		switch (PrefSubDialog) {
		case pd_LibIcon:
			PrefSubDialog = PrefsLibDialog(prefs, resFile);
			break;
		case pd_EnvIcon:
			PrefSubDialog = PrefsEnvDialog(prefs, resFile);
			break;
		case pd_ScriptIcon:
			PrefSubDialog = PrefsScriptDialog(prefs, resFile);
			break;
		case pd_InputIcon:
			PrefSubDialog = PrefsInputDialog(prefs, resFile);
			break;
		case pd_ConfigIcon:
			PrefSubDialog = PrefsConfigDialog(prefs, resFile);
			break;
		}
	}
		
	UpdateResFile(gPrefsFile);
	CloseResFile(gPrefsFile);

	DisposeDialog(prefs);

	HMSetDialogResID(-1);
	UseResFile(resFile);
	
	if (gCachedLibraries) {
		DisposeHandle(gCachedLibraries);
		gCachedLibraries = nil;
	}
}

static ListHandle FontList;
static ListHandle	SizeList;

pascal void DrawFontList(DialogPtr dlg, short item)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused(item)
#endif
	Rect	r;
	
	TextFont(0);
	TextSize(12);
	LUpdate(dlg->visRgn, FontList);
	r = (*FontList)->rView;
	InsetRect(&r, -1, -1);
	FrameRect(&r);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawFontList = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawFontList);
#else
#define uDrawFontList *(UserItemUPP)&DrawFontList
#endif

pascal void DrawSizeList(DialogPtr dlg, short item)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused(item)
#endif
	Rect	r;
	
	TextFont(0);
	TextSize(12);
	LUpdate(dlg->visRgn, SizeList);
	r = (*SizeList)->rView;
	InsetRect(&r, -1, -1);
	FrameRect(&r);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawSizeList = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawSizeList);
#else
#define uDrawSizeList *(UserItemUPP)&DrawSizeList
#endif

static short SizeChoice[] = 
{
	9,
	10,
	12,
	14,
	18,
	24
};

const short	SizeChoiceCount = 6;

pascal Boolean FormatFilter(DialogPtr dlg, EventRecord * ev, short * item)
{	
	WindowPtr	win;
	Rect			r;
	
	SetPort(dlg);
	switch (ev->what) {
	case keyDown:
		switch (ev->message & charCodeMask) {
		case '\n':
		case 3:
			*item = fd_OK;
			
			return true;
		case '.':
			if (!(ev->modifiers & cmdKey))
				break;
		case 27:
			*item = fd_Cancel;
			
			return true;
		default:
			break;
		}
	case mouseDown:
		switch (FindWindow(ev->where, &win)) {
		case inDrag:
			if (win != dlg)
				return false;
				
			r = qd.screenBits.bounds;
			InsetRect(&r, 10, 10);
			DragWindow(win, ev->where, &r);
			
			ev->what = nullEvent;
			break;
		case inSysWindow:
			SystemClick(ev, win);
			
			ev->what = nullEvent;
			break;
		}
		return false;
	case activateEvt:
		LActivate(ev->modifiers & activeFlag, FontList);
		LActivate(ev->modifiers & activeFlag, SizeList);
		break;
	case updateEvt:
		win = (WindowPtr) ev->message;
		if (win != dlg) {
			DoUpdate(DPtrFromWindowPtr(win), win);
			
			ev->what = nullEvent;
		}
		break;
	}
	
	return false;
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uFormatFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, FormatFilter);
#else
#define uFormatFilter *(ModalFilterUPP)&FormatFilter
#endif

short FontCellHeight(MenuHandle fonts, GrafPtr dlg)
{
	short		oldFont;
	short		oldSize;
	short		index;
	short		fontNum;
	short		scriptNum;
	short		minHeight;
	long		scriptsDone;
	long		sysFont;
	FontInfo	fontInfo;
	Str255	contents;
	
	if (GetScriptManagerVariable(smEnabled) < 2)			/* Roman Script Only	*/
		return 16;					/* Ascent + Descent + Leading for Chicago 12 */
	
	SetPort(dlg);
	oldFont 		= dlg->txFont;
	oldSize 		= dlg->txSize;
	minHeight	= 16;
	scriptsDone	= 0;
	
	for (index=0; index++ < CountMItems(fonts); ) {
		GetMenuItemText(fonts, index, contents);
		GetFNum(contents, &fontNum);
		scriptNum = FontToScript(fontNum);
		
		if (scriptNum == smUninterp)
			scriptNum = smRoman;
		/* No point measuring a script more than once */
		if (scriptNum < 32 && (scriptsDone & (1 << scriptNum)))
			continue;
		scriptsDone |= 1 << scriptNum;
		sysFont = GetScriptVariable(scriptNum, smScriptSysFondSize);
		TextFont(sysFont >> 16);
		TextSize(sysFont & 0xFFFF);
		GetFontInfo(&fontInfo);
		if (fontInfo.ascent + fontInfo.descent + fontInfo.leading > minHeight)
			minHeight = fontInfo.ascent + fontInfo.descent + fontInfo.leading;
	}
	
	TextFont(oldFont);
	TextSize(oldSize);
	return minHeight;
}

short FontLDEFID()
{
	if (GetScriptManagerVariable(smEnabled) < 2)			/* Roman Script Only	*/
		return 0;
	else 
		return 128;
}

pascal Boolean DoFormatDialog(DocFormat * form, Boolean * defaultFormat)
{
	short			item;
	short			kind;
	short 		digit;
	Boolean		done;
	Handle		h;
	DialogPtr	format;
	Point			cell;
	Rect			bounds;
	Rect			dbounds;
	Str255		contents;
	MenuHandle	fonts;
	
	format = GetNewAppDialog(FormatDialog);

	GetDialogItem(format, fd_Separator, &kind, &h, &bounds);
	SetDialogItem(format, fd_Separator, kind, (Handle) &uSeparator, &bounds);

	GetDialogItem(format, fd_FontList, &kind, &h, &bounds);
	SetDialogItem(format, fd_FontList, kind, (Handle) &uDrawFontList, &bounds);
		
	fonts = NewMenu(FormatDialog, (StringPtr) "\pFonts");
	AppendResMenu(fonts, 'FONT');

	bounds.right -= 16;
	SetPt(&cell, bounds.right - bounds.left, FontCellHeight(fonts, format));
	SetRect(&dbounds, 0, 0, 1, CountMItems(fonts));
	FontList = LNew(&bounds, &dbounds, cell, item = FontLDEFID(), format, false, false, false, true);
	
	SetPt(&cell, 0, 0);
	for (; cell.v < CountMItems(fonts); ++cell.v) {
		GetMenuItemText(fonts, cell.v+1, contents);
		if (item)
			LSetCell((Ptr)contents, contents[0]+1, cell, FontList);
		else
			LSetCell((Ptr)contents+1, contents[0], cell, FontList);
		GetFNum(contents, &kind);
		LSetSelect(form->font == kind, cell, FontList);
	}
	LAutoScroll(FontList);
	
	GetDialogItem(format, fd_SizeList, &kind, &h, &bounds);
	SetDialogItem(format, fd_SizeList, kind, (Handle) &uDrawSizeList, &bounds);

	bounds.right -= 16;
	SetPt(&cell, bounds.right - bounds.left, 16);
	SetRect(&dbounds, 0, 0, 1, SizeChoiceCount);
	SizeList = LNew(&bounds, &dbounds, cell, 0, format, false, false, false, true);
	
	SetPt(&cell, 0, 0);
	for (; cell.v < SizeChoiceCount; ++cell.v) {
		sprintf((char *) contents, "%d", SizeChoice[cell.v]);
		LSetCell((Ptr)contents, strlen((Ptr) contents), cell, SizeList);
		LSetSelect(form->size == SizeChoice[cell.v], cell, SizeList);
	}
	
	AdornDefaultButton(format, fd_Outline);

	LSetDrawingMode(true, FontList);
	LSetDrawingMode(true, SizeList);
	
	sprintf((char *) contents+1, "%d", form->size);
	contents[0] = strlen((Ptr) contents+1);
	SetText(format, fd_SizeEdit, contents);
	SelectDialogItemText(format, fd_SizeEdit, 0, 32767);

	if (*defaultFormat) {
		GetDialogItem(format, fd_MakeDefault, &kind, &h, &bounds);
		SetControlValue((ControlHandle) h, 1);
		HiliteControl((ControlHandle) h, 254);
	}
	
	ShowWindow(format);
		
	for (done = false; !done; ) {
		ModalDialog(&uFormatFilter, &item);
		
		switch (item) {
		case fd_OK:
			RetrieveText(format, fd_SizeEdit, contents);
			if (contents[0]) {
				for (digit = 0, kind = 0; digit++ < contents[0]; )
					if (isdigit(contents[digit]))
						kind = kind * 10 + contents[digit] - '0';
					else {
						kind = 0;
						
						break;
					}
				
				if (kind) {
					form->size = kind;
					SetPt(&cell, 0, 0);
					LGetSelect(true, &cell, FontList);
					GetMenuItemText(fonts, cell.v+1, contents);
					GetFNum(contents, &kind);
					form->font = kind;
					
					done = true;
					break;
				}
			}
			
			SelectDialogItemText(format, fd_SizeEdit, 0, 32767);
			SysBeep(0);
			
			item = 0;
			break;
		case fd_Cancel:
			done = true;
			*defaultFormat = false;
			break;
		case fd_FontList:
			GetMouse(&cell);
			LClick(cell, 0, FontList);
			break;
		case fd_SizeList:
			GetMouse(&cell);
			LClick(cell, 0, SizeList);
			SetPt(&cell, 0, 0);
			if (LGetSelect(true, &cell, SizeList)) {
				sprintf((char *) contents+1, "%d", SizeChoice[cell.v]);
				contents[0] = strlen((Ptr) contents+1);
				SetText(format, fd_SizeEdit, contents);
				SelectDialogItemText(format, fd_SizeEdit, 0, 32767);
			}
			break;
		case fd_MakeDefault:
			GetDialogItem(format, fd_MakeDefault, &kind, &h, &bounds);
			SetControlValue((ControlHandle) h, *defaultFormat = !*defaultFormat);
			break;
		}
	}
	
	LDispose(FontList);
	LDispose(SizeList);
	DisposeDialog(format);
	DisposeMenu(fonts);
	
	return (item == fd_OK);
}
