/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPMain.c			-	The main event loop
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPMain.c,v $
Revision 1.4  2001/10/11 05:19:31  neeri
Fix exit code (MacPerl bug #422129)

Revision 1.3  2001/04/28 23:28:01  neeri
Need to register MPAEVTStreamDevice (MacPerl Bug #418932)

Revision 1.2  2000/12/22 08:35:45  neeri
PPC, MrC, and SC builds work

Revision 1.5  1998/04/14 19:46:41  neeri
MacPerl 5.2.0r4b2

Revision 1.4  1998/04/07 01:46:40  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:54  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:02  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:51  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:52:40  neeri
Inline Input.

Revision 1.1  1994/02/27  23:01:21  neeri
Initial revision

Revision 0.9  1993/12/30  00:00:00  neeri
DeferredKeys

Revision 0.8  1993/12/20  00:00:00  neeri
Trying to be more subtle about cursors

Revision 0.7  1993/12/12  00:00:00  neeri
SacrificialGoat

Revision 0.6  1993/10/17  00:00:00  neeri
Mercutio Support

Revision 0.5  1993/08/17  00:00:00  neeri
Preferences

Revision 0.4  1993/08/16  00:00:00  neeri
Moved scripting to separate file

Revision 0.3  1993/07/15  00:00:00  neeri
Beginning to see the light

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#define MP_EXT 
#define MP_INIT(x) = x

#include "MPGlobals.h"
#include "MPUtils.h"
#include "MPEditions.h"
#include "MPAppleEvents.h"
#include "MPWindow.h"
#include "MPFile.h"
#include "MPHelp.h"
#include "MPScript.h"
#include "MPUtils.h"
#include "MPPreferences.h"
#include "MercutioAPI.h"
#include "MPConsole.h"
#include "MPPseudoFile.h"
#include "MPEditor.h"

#include <Memory.h>
#include <QuickDraw.h>
#include <Types.h>
#include <Menus.h>
#include <Windows.h>
#include <Controls.h>
#include <ControlDefinitions.h>
#include <Dialogs.h>
#include <Traps.h>
#include <Packages.h>
#include <DiskInit.h>
#include <PPCToolbox.h>
#include <Resources.h>
#include <Printing.h>
#include <ToolUtils.h>
#include <Scrap.h>
#include <AppleEvents.h>
#include <AEObjects.h>
#include <Errors.h>
#include <StandardFile.h>
#include <Balloons.h>
#include <String.h>
#include <CType.h>
#include <PLStringFuncs.h>
#include <TextUtils.h>
#include <StdLib.h>
#include <CursorCtl.h>
#include <Script.h>
#include <SegLoad.h>
#include <LowMem.h>
#include <Devices.h>

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

pascal void MaintainCursor()
{
	Point     	pt;
	WindowPtr 	wPtr;
	GrafPtr   	savePort;
	DPtr      	theDoc;
	Boolean		inText = false;
	
	wPtr = FrontWindow();
	if (Ours(wPtr)) {
		theDoc = DPtrFromWindowPtr(wPtr);
		GetPort(&savePort);
		SetPort(wPtr);
		GetMouse(&pt);
		if (gTextServicesImplemented && SetTSMCursor(pt))
			goto restorePort;
		if (theDoc->theText)
			if (inText = PtInRect(pt, &(**(theDoc->theText)).viewRect))
				SetCursor(&editCursor);
			else
				SetCursor(&qd.arrow);
		else
			SetCursor(&qd.arrow);

		if (theDoc->theText)
			TEIdle(theDoc->theText);

restorePort:
		SetPort(savePort);
	} else if (!wPtr)
		SetCursor(&qd.arrow);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

FSSpec		jumpFile;
WindowPtr	jumpWindow;
short			jumpLine;

Boolean  SeriousFSSpec(char * name)
{
	CInfoPBRec	info;
	
	if (GUSIPath2FSp(name, &jumpFile))
		return false;
	if (GUSIFSpGetCatInfo(&jumpFile, &info) 
	 || info.dirInfo.ioFlAttrib & 0x10 
	) {
		if (strchr(name, ':') || !(jumpWindow = AlreadyOpen(&jumpFile, jumpFile.name)))
			return false;
	} else {
		switch (GetDocTypeFromInfo(&info)) {
		case kUnknownDoc:
		case kPreferenceDoc:
			return false;
		}
		jumpWindow = nil;
	}
	
	return true;
}

Boolean	ParseJump(DPtr	theDoc)
{
	char    	endCh;
	Boolean	result = false;
	TEHandle	te 	= theDoc->theText;
	short		len	= (*te)->selEnd - (*te)->selStart;
	char *	text;
	char *   end;
	char *   endFile;
	Str255	jumpText;
	
	if (len <= 0)
		goto fixupMenuItem;
	
	HLock((*te)->hText);
	text = *(*te)->hText + (*te)->selStart;
	end  = text + len;
	endCh= *end;
	*end = 0;

rescan:	
	while (isspace(*text))
		++text;
	
	switch (*text) {
	case 'F':
	case 'f':
		if (toupper(text[1]) == 'I' 
		 && toupper(text[2]) == 'L' 
		 && toupper(text[3]) == 'E'
		 && isspace(text[4])
		) {
			/* Strip off "File" prefix */
			text += 5;
			
			goto rescan;
		} else
			goto slurp;
	case '\'':
	case '\"':
		if (endFile = strchr(text+1, *text)) {
			*endFile = 0;
			
			if (endFile - text < 1 || !SeriousFSSpec(text+1)) {
				*endFile = *text;
				
				goto repair;
			}
			
			*endFile = *text;
			text = endFile + 1;
			
			break;
		} 
		
		/* Unbalanced quote, skip & fall through */
		++text;
	default:
slurp:
		/* Break at end of line */
		if (endFile = strchr(text, '\n')) {
			/* Strip trailing whitespace */
			while (endFile > text && isspace(endFile[-1]))
				--endFile;
				
			*endFile = 0;
			
			if (endFile - text < 1 || !SeriousFSSpec(text)) {
				*endFile = '\n';
				
				goto repair;
			}
			
			*endFile = '\n';
			text = endFile + 1;
			
			break;
		} 
		
		if (end - text < 1 || !SeriousFSSpec(text))
			goto repair;
		
		text = end;
		break;
	}
	
	/* Try to parse line # */
	
	jumpLine = 0;
	
	while (*text)
		if (isdigit(*text)) {
			while (isdigit(*text))
				jumpLine = jumpLine * 10 + *text++ - '0';
			
			break;
		} else
			++text;
	
	result = true;
		
repair:	
	*end = endCh;
	HUnlock((*te)->hText);

fixupMenuItem:
	if (result) {
		jumpFile.name[jumpFile.name[0]+1] = 0;
		jumpText[0] = sprintf((char *) jumpText+1, "Jump to \"%s\"", jumpFile.name+1);
		if (jumpLine)
			jumpText[0] += 
				sprintf((char *) jumpText+jumpText[0]+1, ", Line %d", jumpLine);
		SetMenuItemText(myMenus[editM], emJumpTo, jumpText);
	} else 
		SetMenuItemText(myMenus[editM], emJumpTo, (StringPtr) "\pJump ToÉ");

	return result;	
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

static Boolean	mRunningPerl;

pascal void MaintainMenuBar()
{
	if (gRunningPerl != mRunningPerl) {
		if (gRunningPerl) {
			DeleteMenu(perlID);
			EnableItem(myMenus[fileM], fmStopScript);
		} else {
			InsertMenu(myMenus[perlM], 0);
			DisableItem(myMenus[fileM], fmStopScript);
		}
		
		mRunningPerl = gRunningPerl;
		
		DrawMenuBar();
	}
}

void MaintainScriptMenu(WindowPtr win)
{
	DPtr		doc;
	short		origLen;
	Str255	title;
	
	if (mRunningPerl) 
		return;
	
	for (; win; win = GetNextWindow(win)) {
		if (!IsWindowVisible(win) || !Ours(win))
			continue;
		if (!(doc = DPtrFromWindowPtr(win)) || doc->kind != kDocumentWindow)
			continue;

		PLstrcpy(title, (StringPtr) "\pRun ");
		origLen 				= title[0];
		GetWTitle(win, title+origLen+1);
		title[0] 			= title[origLen+1] + origLen + 2;
		title[origLen+1]	= '"';
		title[title[0]]	= '"';
		SetMenuItemText(myMenus[perlM], pmRunFront, title);
		EnableItem(myMenus[perlM], pmRunFront);
		
		PLstrcpy(title, (StringPtr) "\pSyntax Check ");
		origLen 				= title[0];
		GetWTitle(win, title+origLen+1);
		title[0] 			= title[origLen+1] + origLen + 2;
		title[origLen+1]	= '"';
		title[title[0]]	= '"';
		SetMenuItemText(myMenus[perlM], pmCheckFront, title);
		EnableItem(myMenus[perlM], pmCheckFront);
		
		return;
	}
	
	SetMenuItemText(myMenus[perlM], pmRunFront, (StringPtr) "\pRun Front Window");
	DisableItem(myMenus[perlM], pmRunFront);
	SetMenuItemText(myMenus[perlM], pmCheckFront, (StringPtr) "\pCheck Front Window");
	DisableItem(myMenus[perlM], pmCheckFront);
}

void MaintainEditorMenu(WindowPtr win)
{
	DPtr		doc;
	int		origLen;
	Str255	title;
	
	if (HasExternalEdits())
		EnableItem(myMenus[editorM], xmUpdate);
	else 
		DisableItem(myMenus[editorM], xmUpdate);

	PLstrcpy(title, (StringPtr) "\pUpdate ");
	origLen 				= title[0];
	if (GetExternalEditorDocumentName(title+origLen+1)) {
		title[0] 			= title[origLen+1] + origLen + 2;
		title[origLen+1]	= '"';
		title[title[0]]	= '"';
		SetMenuItemText(myMenus[editorM], xmUpdateFront, title);
		EnableItem(myMenus[editorM], xmUpdateFront);
	} else {
		SetMenuItemText(myMenus[editorM], xmUpdateFront, (StringPtr) "\pUpdate");
		DisableItem(myMenus[editorM], xmUpdateFront);
	}

	for (; win; win = GetNextWindow(win)) {
		if (!IsWindowVisible(win) || !Ours(win))
			continue;
		if (!(doc = DPtrFromWindowPtr(win)) || doc->kind != kDocumentWindow)
			continue;

		PLstrcpy(title, (StringPtr) "\pEdit ");
		origLen 				= title[0];
		GetWTitle(win, title+origLen+1);
		title[0] 			= title[origLen+1] + origLen + 2;
		title[origLen+1]	= '"';
		title[title[0]]	= '"';
		SetMenuItemText(myMenus[editorM], xmEditFront, title);
		EnableItem(myMenus[editorM], xmEditFront);
		
		return;
	}
	
	SetMenuItemText(myMenus[editorM], xmEditFront, "\pEdit Front Window");
	DisableItem(myMenus[editorM], xmEditFront);
}

pascal void MaintainMenus()
{
	DPtr       		theDoc;
	WindowPtr  		firstWindow;

	MaintainMenuBar();
	
	firstWindow = FrontWindow();
	
	MaintainScriptMenu(firstWindow);
	MaintainEditorMenu(firstWindow);
	
	if (!Ours(firstWindow)) {
		EnableItem(myMenus[fileM], fmNew);
		EnableItem(myMenus[fileM], fmOpen);
		DisableItem(myMenus[fileM], fmClose);
		DisableItem(myMenus[fileM], fmSave);
		DisableItem(myMenus[fileM], fmSaveAs);
		DisableItem(myMenus[fileM], fmRevert);
		DisableItem(myMenus[fileM], fmPrint);
		DisableItem(myMenus[fileM], fmPageSetUp);
		EnableItem(myMenus[fileM], fmQuit);

		if (firstWindow) {
			EnableItem(myMenus[editM], undoCommand);
			EnableItem(myMenus[editM], cutCommand);
			EnableItem(myMenus[editM], copyCommand);
			EnableItem(myMenus[editM], pasteCommand);
			EnableItem(myMenus[editM], clearCommand);
		} else {
			DisableItem(myMenus[editM], undoCommand);
			DisableItem(myMenus[editM], cutCommand);
			DisableItem(myMenus[editM], copyCommand);
			DisableItem(myMenus[editM], pasteCommand);
			DisableItem(myMenus[editM], clearCommand);
		}
		EnableItem(myMenus[editM],  emPreferences);
		DisableItem(myMenus[editM], selectAllCommand);

		DisableItem(myMenus[editM],  emFind);
		DisableItem(myMenus[editM],  emFindAgain);
		DisableItem(myMenus[editM],  emJumpTo);
		
		EnableItem(myMenus[helpM], hmExplain);
	} else {
		theDoc = DPtrFromWindowPtr(firstWindow);
		
		if (theDoc->kind == kDocumentWindow) {
			EnableItem(myMenus[editM], pasteCommand);
		} else {
			if ((*theDoc->theText)->selStart < theDoc->u.cons.fence)
				DisableItem(myMenus[editM], pasteCommand);
			else
				EnableItem(myMenus[editM], pasteCommand);
		}
		
		EnableItem(myMenus[fileM], fmClose);
		EnableItem(myMenus[fileM], fmSave);
		EnableItem(myMenus[fileM], fmSaveAs);
		EnableItem(myMenus[fileM], fmPrint);
		EnableItem(myMenus[fileM], fmPageSetUp);
		EnableItem(myMenus[fileM], fmQuit);

		if (theDoc->kind == kDocumentWindow && theDoc->u.reg.everSaved && theDoc->dirty)
			EnableItem(myMenus[fileM], fmRevert);
		else
			DisableItem(myMenus[fileM], fmRevert);

		DisableItem(myMenus[editM], undoCommand);

		if (((**(theDoc->theText)).selEnd - (**(theDoc->theText)).selStart) > 0) {
			EnableItem(myMenus[editM], cutCommand);
			EnableItem(myMenus[editM], copyCommand);
			EnableItem(myMenus[editM], clearCommand);
		} else {
			DisableItem(myMenus[editM], cutCommand);
			DisableItem(myMenus[editM], copyCommand);
			DisableItem(myMenus[editM], clearCommand);
		}
		
		EnableItem(myMenus[editM],  selectAllCommand);
		EnableItem(myMenus[editM],  emPreferences);

		EnableItem(myMenus[editM],  emFind);
		EnableItem(myMenus[editM],  emFindAgain);
		
		if (ParseJump(theDoc))
			EnableItem(myMenus[editM],  emJumpTo);
		else
			DisableItem(myMenus[editM],  emJumpTo);

		EnableItem(myMenus[helpM], hmExplain);
	}
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

pascal void SetUpCursors(void)
{
	CursHandle  hCurs;

	hCurs = GetCursor(1);
	editCursor = **hCurs;
	hCurs = GetCursor(watchCursor);
	waitCursor = **hCurs;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

static short gExplainItem;

pascal void SetUpMenus(void)
{
	short 			i;
	StringHandle	str;

	myMenus[appleM] = GetMenu(appleID);
	AppendResMenu(myMenus[appleM], 'DRVR');
	myMenus[fileM] = GetMenu(fileID);
	myMenus[editM] = GetMenu(editID);
	myMenus[windowM]	= GetMenu(windowID);
	myMenus[perlM]	= GetMenu(perlID);
	myMenus[editorM]	= GetMenu(editorID);
	
	if (gExternalEditor) {
		Str63 name;
		GetExternalEditorName(name);
		Munger(
			(Handle) myMenus[editorM], 14, 
			nil, *myMenus[editorM][0]->menuData+1, 
			(Ptr) name, *name+1);
	}

	for (i = appleM; i < kLastMenu; i++)
		if (i != editorM || gExternalEditor)
			InsertMenu(myMenus[i], 0);

	HMGetHelpMenuHandle(&myMenus[helpM]);
	str = GetString(helpID);
	
	HLock((Handle) str);
	AppendMenu(myMenus[helpM], *str);
	ReleaseResource((Handle) str);
	
	gExplainItem = CountMItems(myMenus[helpM]);

	AddStandardScripts();
	
	SetShortMenus(); /* Does a DrawMenuBar() */
}

pascal void DoFile(short theItem)
{
	short   alertResult;
	DPtr    theDoc;
	FSSpec  theFSSpec;
	OSErr   fileErr;
	TPrint  thePSetup;

	switch (theItem){
	case fmNew:
		IssueAENewWindow();
		break;

	case fmOpen:
		if (GetFile(&theFSSpec)==noErr)
			fileErr = IssueAEOpenDoc(theFSSpec);
		break;

	case fmClose:
		IssueCloseCommand(FrontWindow());
		break;

	case fmSave:
	case fmSaveAs:
		theDoc = DPtrFromWindowPtr(FrontWindow());

		if (theItem==fmSaveAs || theDoc->kind != kDocumentWindow || !theDoc->u.reg.everSaved) {
			fileErr = GetFileNameToSaveAs(theDoc);
			if (!fileErr)
				fileErr = IssueSaveCommand(theDoc, &theDoc->theFSSpec);
			else if (fileErr != userCanceledErr)	
				FileError((StringPtr) "\perror saving ", theDoc->theFileName);
		} else
			fileErr = IssueSaveCommand(theDoc, nil);
		break;

	case fmRevert:
		SetCursor(&qd.arrow);
		theDoc = DPtrFromWindowPtr(FrontWindow());

		ParamText(theDoc->theFileName, (StringPtr) "", (StringPtr) "", (StringPtr) "");
		alertResult = AppAlert(RevertAlert);
		switch (alertResult){
			case aaSave:
				if (IssueRevertCommand(theDoc->theWindow))
					FileError((StringPtr) "\perror reverting ", theDoc->theFileName);
		}
		break;

	case fmPageSetUp:
		theDoc = DPtrFromWindowPtr(FrontWindow());
		if (DoPageSetup(theDoc)) {
			 thePSetup = **(theDoc->thePrintSetup);
			 IssuePageSetupWindow(theDoc->theWindow, thePSetup);
		 }
		break;

	case fmPrint:
		IssuePrintWindow(FrontWindow());
		 break;

	case fmStopScript:
		if (gRunningPerl)
			gAborting = true;
		break;

	case fmQuit:
		IssueQuitCommand();
		break;
	} /*of switch*/
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

pascal void DoCommand(long mResult, Boolean option, Boolean mousing)
{
	short	  	theMenu;
	short   	theItem;
	short   	err;
	Str255  	name;
	DPtr    	theDocument;

	if (gMacPerl_FilterMenu) {
		gExplicitWNE = true;
		if (gMacPerl_FilterMenu(mResult))
			return;
	}

	if (!mResult) {
		/*
		 * Hierarchical submenus of the Help menu are broken. We therefore
		 * special case for them but prevent this route from being taken for
		 * any other menu
		 */
		
		if (mousing)
			mResult = MenuChoice();
		
		if (!mResult)
			return;
		else
			mResult |= 0x80000000;
	}
	
	theDocument = DPtrFromWindowPtr(FrontWindow());
		
	if (gTextServicesImplemented && TSMMenuSelect(mResult))
		goto done;
	if (theDocument && theDocument->tsmDoc)
		FixTSMDocument(theDocument->tsmDoc);

	theItem = LoWord(mResult);

	switch (theMenu = HiWord(mResult)) {
	case appleID:
		if (theItem == aboutItem) {
			DoAbout(option);
		} else {
			GetMenuItemText(myMenus[appleM], theItem, name);
			err = OpenDeskAcc(name);
			SetPort(FrontWindow());
		}
  		break;

	case fileID:
		DoFile(theItem);
		break;

	case editID:
		SystemEdit(theItem - 1);

		switch (theItem) {
		case cutCommand:
			IssueCutCommand(theDocument);
			break;

		case copyCommand:
			IssueCopyCommand(theDocument);
			break;

		case pasteCommand :
			IssuePasteCommand(theDocument);
			break;

		case clearCommand :
			IssueClearCommand(theDocument);
			break;

		case selectAllCommand:
			if (theDocument)
				TESetSelect(0, (**(theDocument->theText)).teLength, theDocument->theText);
			break;

		case emFind:
		case emFindAgain:
			if (theDocument)
				DoFind(theDocument->theText, theItem==emFindAgain);
			break;
			
		case emJumpTo:
			IssueJumpCommand(&jumpFile, jumpWindow, jumpLine);
			break;
			
		case emFormat:
			IssueFormatCommand(theDocument);
			break;
			
		case emPreferences:
			DoPrefDialog();
			break;
		}	 /*of switch*/

		ShowSelect(theDocument);
	 	break;
	
	case windowID:
		DoSelectWindow(theItem);
		break;

	case editorID:
		switch (theItem) {
		case xmEdit:
			StartExternalEditor(false);
			break;
		case xmEditFront:
			StartExternalEditor(true);
			break;
		case xmUpdate:
			UpdateExternalEditor(false);
			break;
		case xmUpdateFront:
			UpdateExternalEditor(true);
			break;
		}
		break;
		
	case perlID:
		DoScriptMenu(theItem);
		break;

	case kHMHelpMenuID:
		if (theItem < gExplainItem)
			break;
		else if (theItem == gExplainItem)
			Explain(theDocument);
		else
			DoHelp(0, theItem);
		break;
	
	default:
		theMenu &= 0x7FFF;
		
		if (theMenu > kHierHelpMenu && theMenu < kHierHelpMenu+20)
			DoHelp(theMenu - kHierHelpMenu, theItem);
		break;
	}				 /*of switch*/

done:
	HiliteMenu(0);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

pascal void DoMouseDown(EventRecord *myEvent)
{
	WindowPtr whichWindow;
	Point     p;
	Rect      dragRect;

	p = myEvent->where;
	switch (FindWindow(p, &whichWindow)) {
	case inDesk:
		SysBeep(10);
		break;

	case inGoAway:
		if (Ours(whichWindow))
			if (TrackGoAway(whichWindow, p))
				IssueCloseCommand(whichWindow);
		break;

	case inMenuBar:
		SetCursor(&qd.arrow);
		SetupWindowMenu();
		MaintainMenus(); 
		if (gMacPerl_FilterMenu) {
			gExplicitWNE = true;
			gMacPerl_FilterMenu(-1);
		}
		DoCommand(MenuSelect(p), (myEvent->modifiers & optionKey) == optionKey, true);
		HiliteMenu(0);
		break;

	case inSysWindow:
		SystemClick(myEvent, whichWindow);
		break;

	case inDrag:
		dragRect = qd.screenBits.bounds;

		if (Ours(whichWindow)) {
			DragWindow(whichWindow, p, &dragRect);
			/*
				As rgnBBox may be passed by address
			*/
			dragRect = (**((WindowPeek)whichWindow)->strucRgn).rgnBBox;
			/*
				The windows already there, but still tell
				the our AppleEvents core about the move in case
				they want to do anything
			*/
			IssueMoveWindow(whichWindow, dragRect);
		}
	  	break;

	case inGrow:
		SetCursor(&qd.arrow);
		if (Ours(whichWindow))
			MyGrowWindow(whichWindow, p);
		break;

	case inZoomIn:
		DoZoom(whichWindow, inZoomIn, p);
		break;

	case inZoomOut:
		DoZoom(whichWindow, inZoomOut, p);
		break;

	case inContent:
		if (whichWindow != FrontWindow())
			SelectWindow(whichWindow);
		else
			if (Ours(whichWindow))
				DoContent(whichWindow, myEvent);
		break;
	}				 /*of switch*/
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

pascal long GetSleep(void)
{
	long      sleep;
	WindowPtr theWindow;
	DPtr      theDoc;

	sleep = 30;
	if (!gInBackground)
		{
			theWindow = FrontWindow();
			if (theWindow)
				{
					theDoc = DPtrFromWindowPtr(theWindow);
					if (theDoc && (**(theDoc->theText)).selStart == (**(theDoc->theText)).selEnd)
						sleep = GetCaretTime();
				}
		}
	return(sleep);
}					 /*GetSleep*/

long FindMenuKey(EventRecord * ev)
{
	/* Work around Help manager bug */
	short	key;
	
	GetItemCmd(myMenus[helpM], gExplainItem, &key);
	
	if (toupper((char) key) == toupper(ev->message & charCodeMask))
		return (kHMHelpMenuID << 16) | gExplainItem;
	else {
		MaintainMenus();

		return MDEF_MenuKey(ev->message, ev->modifiers, myMenus[fileM]);
	}
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

typedef enum {keyOK, keyRetry, keyAbort} KeyStatus;

#define kHome		1
#define kEnd		4
#define kHelp		5
#define kPageUp	11
#define kPageDown	12

KeyStatus TryKey(DPtr theDoc, char theChar)
{
	short value;
	
	if (theDoc->kind != kDocumentWindow && DoRawConsole(theDoc->u.cons.cookie, theChar))
		return keyOK;

	switch (theChar) {
	case 0:
	case 2:
	case 6:
	case 7:
	case 10:
	case 14:
	case 15:
	case 16:
	case 17:
	case 18:
	case 19:
	case 20:
	case 21:
	case 22:
	case 23:
	case 24:
	case 25:
	case 26:
	case 27:
	case 0x7F:
		return keyAbort;
	case kHome:
		value = GetControlValue(theDoc->vScrollBar);
		SetControlValue(theDoc->vScrollBar, GetControlMinimum(theDoc->vScrollBar));
		DoThumb(theDoc, theDoc->vScrollBar, value);
		
		return keyOK;
	case kEnd:
		value = GetControlValue(theDoc->vScrollBar);
		SetControlValue(theDoc->vScrollBar, GetControlMaximum(theDoc->vScrollBar));
		DoThumb(theDoc, theDoc->vScrollBar, value);
		
		return keyOK;
	case kPageUp:
		VActionProc(theDoc->vScrollBar, kControlPageUpPart);
		return keyOK;
	case kPageDown:
		VActionProc(theDoc->vScrollBar, kControlPageDownPart);
		return keyOK;
	case kHelp:
		Explain(theDoc);
		return keyOK;
	case ETX:
		theChar = CR;
		
		break;
	default:
		break;
	}

	if (theDoc->kind != kDocumentWindow)
		if (theChar == BS) {
			if (AllSelected(theDoc->theText)) {
				if (theDoc->u.cons.fence < 32767)
					theDoc->u.cons.fence = 0;
			} else if ((*theDoc->theText)->selStart == (*theDoc->theText)->selEnd)
				if ((*theDoc->theText)->selStart-1 < theDoc->u.cons.fence)
					return keyAbort;
				else if ((*theDoc->theText)->selStart < theDoc->u.cons.fence)
					return keyAbort;
		} else if (
			(*theDoc->theText)->selStart < theDoc->u.cons.fence &&
			!KeyOKinSubscriber(theChar)
		) 
			return keyAbort;
		else if (!theDoc->u.cons.selected)
			return gRunningPerl ? keyRetry : keyAbort;

	AddKeyToTypingBuffer(theDoc, theChar);
	TEKey(theChar, theDoc->theText);
	EnforceMemory(theDoc, theDoc->theText);
	AdjustScrollbars(theDoc, false);
	ShowSelect(theDoc);

	theDoc->dirty = true;
	
	return keyOK;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

static Boolean IntlTSMEvent(EventRecord *event)
{
	short oldFont;
	ScriptCode keyboardScript;
	
	if (qd.thePort != nil)
	{
		oldFont = qd.thePort->txFont;
		keyboardScript = GetScriptManagerVariable(smKeyScript);
		if (FontToScript(oldFont) != keyboardScript)
			TextFont(GetScriptVariable(keyboardScript, smScriptAppFond));
	};
	return TSMEvent(event);
}

/* Our cursor/WaitNextEvent strategy */

#define FRONT_BUSY_WAIT	120
#define BACK_BUSY_WAIT	30
#define FRONT_FREQUENCY	30
#define BACK_FREQUENCY  10

static long			lastNonBusy 	= 0;
static long 		lastWNE     	= 0;
static long			lastBusySpin	= 0;
static char			deferredKeys[256];
static short		deferredRd		= 0;
static short		deferredWr		= 0;
static WindowPtr	deferredWindow	= 0;
static RgnHandle	mouseRgn;

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

void HandleEvent(EventRecord * myEvent)
{
	char        theChar;
	Boolean     activate;
	Point			mouse;
	WindowPtr   theWindow;
	DPtr        theDoc;

	if (gMacPerl_FilterEvent) {
		gExplicitWNE = true;
		gMacPerl_FilterEvent(myEvent);
	}
		
	theDoc = DPtrFromWindowPtr(FrontWindow());
	
	switch (myEvent->what) {
	case mouseDown:
		FlushAndRecordTypingBuffer();
		DoMouseDown(myEvent);
		lastNonBusy = TickCount();
		break;

	case keyDown:
	case autoKey:
		if (WeirdChar(myEvent, cmdKey, ETX) 
		 || WeirdChar(myEvent, controlKey, 'd')
		)	{
			if (theDoc && theDoc->kind != kDocumentWindow && !DoRawConsole(theDoc->u.cons.cookie, '\004')) {
				gGotEof			=	theDoc;
				theDoc->dirty 	= 	true;
			} 
			
			break;
		} 
		
		theChar = myEvent->message & charCodeMask;

		if ((myEvent->modifiers & cmdKey) == cmdKey) {
			FlushAndRecordTypingBuffer();
			if (gMacPerl_FilterMenu) {
				gExplicitWNE = true;
				gMacPerl_FilterMenu(-1);
			}
			DoCommand(FindMenuKey(myEvent), (myEvent->modifiers & optionKey) == optionKey, false);
			HiliteMenu(0);
		} else if (theDoc && theDoc->theText)
			switch (TryKey(theDoc, theChar)) {
			case keyOK:
			case keyAbort:
				break;
			case keyRetry:
				if (FrontWindow() != deferredWindow) {
					deferredRd = deferredWr;
					deferredWindow = FrontWindow();
				}
				deferredKeys[deferredWr] = theChar;
				deferredWr = (deferredWr + 1) & 255;
				break;
			}
		break;

	case activateEvt:
		activate = ((myEvent->modifiers & activeFlag) != 0);
		theWindow = (WindowPtr)myEvent->message;
		DoActivate(theWindow, activate);
		break;

	case updateEvt:
		theWindow = (WindowPtr)myEvent->message;
		DoUpdate(DPtrFromWindowPtr(theWindow), theWindow);
		break;

	case kHighLevelEvent:
		FlushAndRecordTypingBuffer();
		DoAppleEvent(*myEvent);
		
		if (gDelayedScript.dataHandle) {
			AppleEvent	awakenedScript = gDelayedScript;
			
			gDelayedScript.dataHandle = nil;
			
			DoScript(&awakenedScript, nil, 0);
			AEDisposeDesc(&awakenedScript);
		}
		break;

	case kOSEvent:
		switch (myEvent->message & osEvtMessageMask) { /*high byte of message*/
		case 0x01000000:
				FlushAndRecordTypingBuffer();
				gInBackground = ((myEvent->message & resumeFlag) == 0);
				if (!gInBackground)
					InitCursor();
				DoActivate(FrontWindow(), !gInBackground);
		}
		break;
	case diskEvt:
		if (myEvent->message & 0xFFFF0000) {
			DILoad();
			SetPt(&mouse, 120, 120);
			DIBadMount(mouse, myEvent->message);
			DIUnload();
		}
	}
}

static EventRecord sDeferredEvent;
static Boolean     sHasDeferredEvent;

void MainEvent(Boolean busy, long sleep, RgnHandle rgn)
{
	short		events = everyEvent;
	DPtr        theDoc;
	Boolean		gotEvent;
	Boolean		spinning;
	WindowPtr   theWindow;
	long		now;
	EventRecord myEvent;
	Point		mouse;

	if (!gSacrificialGoat)		/* Memory trouble */
		if (gRunningPerl)			/* This script has gone too far */
			Perl_die("Out of memory ! Aborting script for your own good...\n");
		else							/* We aborted it, now buy a new goat */
			if (!(gSacrificialGoat = NewHandle(SACRIFICE)))
				ExitToShell();		/* Save our sorry ass. Shouldn't happen */
	
	now = LMGetTicks();
	if (spinning = busy) {
		if (now - lastNonBusy < (gInBackground ? BACK_BUSY_WAIT : FRONT_BUSY_WAIT))
			spinning = false;
	} else
		lastNonBusy = now;

	if (gMacPerl_InModalDialog) {
		events = activMask | updateMask | highLevelEventMask | osMask;
		spinning = false;
	}
	
	MaintainMenuBar();
	
	if (spinning) {
		if (now-lastBusySpin < 3) 
			return;
		
		lastBusySpin = now;
		RotateCursor(32);
		
		if (now - lastWNE < (gInBackground ? BACK_FREQUENCY : FRONT_FREQUENCY))
			return;
	} else
		MaintainCursor();

	lastWNE = now;	
	gGotEof = nil;
	
	if (!gRunningPerl && GetHandleSize((Handle) gWaitingScripts)) {
		AppleEvent ev	=	(*gWaitingScripts)[0];
		AppleEvent repl	=	(*gWaitingScripts)[1];
		
		Munger((Handle) gWaitingScripts, 0, nil, 16, (Ptr) -1, 0);
		
		AESetTheCurrentEvent(&ev);
		DoScript(&ev, &repl, 0);
		AEResumeTheCurrentEvent(
			&ev, &repl, (AEEventHandlerUPP) kAENoDispatch, -1);
	}
	
	if ((theDoc = DPtrFromWindowPtr(FrontWindow())) && theDoc->theText) 
		while (deferredKeys[deferredRd]) {
			switch (deferredWindow != FrontWindow() ? keyAbort : TryKey(theDoc, deferredKeys[deferredRd])) {
			case keyOK:
			case keyAbort:
				deferredKeys[deferredRd] = 0;
				deferredRd = (deferredRd + 1) & 255;
				continue;
			}
			break;
		}

	if (!(theWindow = FrontWindow()))
		GetWMgrPort(&theWindow);
		
	SetPort(theWindow);

	SetScriptManagerVariable(smFontForce, gSavedFontForce);

	if (!busy) {
		if (sHasDeferredEvent) {
			/* Deliver a suspend/resume event we got earlier when it was not opportune */
			
			myEvent = sDeferredEvent;
			sHasDeferredEvent = false;
			gotEvent          = true;
		} else {
			if (!mouseRgn) 
				mouseRgn	=	NewRgn();
			
			GetMouse(&mouse);
			LocalToGlobal(&mouse);
			SetRectRgn(mouseRgn, mouse.h, mouse.v, mouse.h+1, mouse.v+1);
			gotEvent = 
				WaitNextEvent(
					events, &myEvent, 
					(sleep == -1 ? GetSleep() : sleep), 
					(rgn ? rgn : mouseRgn));
		}
	} else {
		gotEvent = WaitNextEvent(gExplicitWNE ? osMask : events, &myEvent, 0, nil);
		if (gotEvent && gExplicitWNE) {
			/* Suspend/Resume Event, handle later */
			sDeferredEvent    = myEvent;
			sHasDeferredEvent = true;
			gotEvent          = false;
		}
	}

	/* clear fontForce again so it doesn't upset our operations */
	gSavedFontForce = GetScriptManagerVariable(smFontForce);
	(void) SetScriptManagerVariable(smFontForce, 0);
		
	if (gotEvent && gTextServicesImplemented && IntlTSMEvent(&myEvent))
		;		/* TSMTE handled it without our help */
	else if (busy && gExplicitWNE)
		;       /* Events are not opportune right now */
	else
		HandleEvent(&myEvent);
		
	if (gQuitting && gRunningPerl)
		MacPerl_Exit(-128);
}

pascal long VoodooChile(Size cbNeeded)
{
#if !defined(powerc) && !defined(__powerc)
	long	oldA5 = SetCurrentA5();
#endif
	long	res;
	
	if (gSacrificialGoat && (GZSaveHnd() != gSacrificialGoat)) {
		/* Oh Memory Manager, our dark Lord. Take the blood of this animal to
		   unwield thy power to crush our enemies.
			
			(Chant 7 times)
		*/
		DisposeHandle(gSacrificialGoat);
		
		gSacrificialGoat 	= 	0;
		res					=	SACRIFICE;
	} else
		res 					=	0;
		
#if !defined(powerc) && !defined(__powerc)
	SetA5(oldA5);
#endif
	
	return res;
}


#if TARGET_RT_MAC_CFM
RoutineDescriptor	uVoodooChile = 
		BUILD_ROUTINE_DESCRIPTOR(uppGrowZoneProcInfo, VoodooChile);
#else
#define uVoodooChile *(GrowZoneUPP)&VoodooChile
#endif

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPMain
#endif

double * cs;
double * ps;

void main()
{
	OSErr  err;
	short  result;

	/* 
	 * Instead of blindly bumping stack space, we make the stack a fraction of
	 * the partition size, which will fill expectations of folks who increase
	 * partitions in response to memory problems
	 */
	unsigned long stackBase = (unsigned long)LMGetCurStackBase();
	unsigned long applZone  = (unsigned long)LMGetApplZone();
	
	if (applZone > stackBase-0x100000) {
		/* Either we're run by a lunatic, or the memory layout of 
		 * applications has changed. Revert to moderate stack
		 */
		SetApplLimit(GetApplLimit() - 65536L);
	} else {
		int megs = (int)((stackBase-applZone) >> 20);
		
		/* Add 16K for each M of heap space */
		SetApplLimit(GetApplLimit() - 32768L - (megs<<14));
	}
	MaxApplZone();

	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	FlushEvents(everyEvent, 0);
	InitCursor();
	SetGrowZone(&uVoodooChile);
	SetUpCursors();

	/* There appears to be a bug in current versions of Macintosh Easy Open that causes
		spurious System Error 28 crashes. The only remedy at the moment is to disable the
		stack sniffer 
	*/
#define StackLowPoint (*(Ptr *)0x110)
	StackLowPoint = nil;
	
	/*check environment checks to see if we are running 7.0*/
	if (!CheckEnvironment()) {
		SetCursor(&qd.arrow);
		/*pose the only 7.0 alert*/
		result = Alert(302, nil);
		return;
	}

	gAppFile				= CurResFile();

	ICStart(&gICInstance, MPAppSig);
	if (gICInstance)
		ICFindConfigFile(gICInstance, 0, nil);
	
	gPerlPrefs.version 			= 	PerlPrefVersion500;
	gPerlPrefs.runFinderOpens	=	false;
	gPerlPrefs.checkType			=	false;
	gPerlPrefs.inlineInput		= 	true;
	
	OpenPreferences();
	if (gPrefsFile)
		CloseResFile(gPrefsFile);
	UseResFile(gAppFile);

	InitExternalEditor();
	
	SetUpMenus();

	gWCount    			= 0;
	gNewDocCount 		= 0;
	gQuitting  			= false;
	gWarnings  			= false;
	gDebug	  			= false;
	gFontMItem 			= 0;
	gConsoleList		= nil;
	gActiveWindow		= nil;
	gScriptFile			= gAppFile;
	gWaitingScripts	= (AppleEvent **) NewHandle(0);
	gGotEof				= nil;
	gSacrificialGoat	= NewHandle(SACRIFICE);
	/* gPerlPool			= new_malloc_pool('PERL', SUGGESTED_BLK_SIZE); */
	gMacPerl_WaitEvent	= MainEvent;

	if (err = AEObjectInit()) {
		ShowError((StringPtr) "\pAEObjectInit", err);
		gQuitting = true;
	}

	InitAppleEvents();

	if (err = PPCInit()) {
		ShowError((StringPtr) "\pPPCInit", err);
		gQuitting = true;
	}

	if (!(gTSMTEImplemented && !InitTSMAwareApplication())) {
		gTextServicesImplemented = false;
		gTSMTEImplemented = false;
	}
	
	InitConsole();
	InitAevtStream();
	InitPseudo();
	InitHelp();
	InitHelpIndex();
	EndHelp();

	setvbuf(stderr, NULL, _IOLBF, BUFSIZ);

	gSavedFontForce = GetScriptManagerVariable(smFontForce);
	(void) SetScriptManagerVariable(smFontForce, 0);
	
	if (gQuitting)
		ExitToShell();
		
	InitPerlEnviron();
	
	/* GUSISetSpin(MPConsoleSpin); */
	
	for (gQuitting = DoRuntime(); !gQuitting; )
		MainEvent(false, -1, nil);

	if (gICInstance)
		ICStop(gICInstance);
		
	if (gTextServicesImplemented)
		CloseTSMAwareApplication();
	SetScriptManagerVariable(smFontForce, gSavedFontForce);
	
	ExitToShell();
}
