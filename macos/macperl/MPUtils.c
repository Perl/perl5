/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPUtils.c	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPUtils.c,v $
Revision 1.2  2001/10/03 19:23:16  pudge
Sync with perforce maint-5.6/macperl

Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.3  1998/04/07 01:46:46  neeri
MacPerl 5.2.0r4b1

Revision 1.2  1997/08/08 16:58:08  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:11:03  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:52:40  neeri
Inline Input.

Revision 1.1  1994/02/27  23:02:08  neeri
Initial revision

Revision 0.5  1993/08/17  00:00:00  neeri
DoPrefDialog()

Revision 0.4  1993/08/15  00:00:00  neeri
DoAbout

Revision 0.3  1993/08/14  00:00:00  neeri
Preference file

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include "MPUtils.h"
#include "MPWindow.h"
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
#include <NumberFormatting.h>
#include <TextUtils.h>
#include <Folders.h>
#include <Resources.h>
#include <Script.h>
#include <Sound.h>
#include <OSUtils.h>
#include <Files.h>
#include <Lists.h>
#include <Icons.h>
#include <TSMTE.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

/**-----------------------------------------------------------------------
		Name: 		ShowError
		Purpose:		Reports an error to the user as both string and number.
	-----------------------------------------------------------------------**/
#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void ShowError(Str255 theError, long theErrorCode)
{
	short     alertResult;
	Str255    theString;

	if (gAppleEventsImplemented)
		if (AEInteractWithUser(kAEDefaultTimeout, nil,nil))
			return;
		
	 SetCursor(&qd.arrow);
	 NumToString(theErrorCode, theString);
	 ParamText(theError, theString, (StringPtr) "\p", (StringPtr) "\p");
	 alertResult = AppAlert(300);
} /* ShowError */

/**-----------------------------------------------------------------------
		Name: 		Ours
		Purpose:		Checks the frontmost window belongs to the app.
	-----------------------------------------------------------------------**/
#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal Boolean Ours(WindowPtr aWindow)
{
	return aWindow && (GetWindowKind(aWindow) == PerlWindowKind);
} /* Ours */

/**-----------------------------------------------------------------------
		Name: 		SetShortMenus
		Purpose:		Cuts the menus down to a minimum - Apple File Edit.
						Greys out the unavailable options - used when no docs open
	-----------------------------------------------------------------------**/
#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void SetShortMenus()
{
	DeleteMenu(windowID);

	DrawMenuBar();
}  /* SetShortMenus */

/**-----------------------------------------------------------------------
		Name: 		SetLongMenus
		Purpose:		Reinstates the full menu bar - called when first document
		            opened.
	-----------------------------------------------------------------------**/
#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void SetLongMenus()
{
	InsertMenu(myMenus[windowM], perlID);

	DrawMenuBar();
}  /* SetLongMenus */

/**-----------------------------------------------------------------------
    Name:       SetEditMenu
    Purpose:    Set the text of the edit menu according to the state of
					 current document.
  -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void SetEditMenu(DPtr theDoc)
{
}  /* SetEditMenu */

/**-----------------------------------------------------------------------
    Name:       GetTempFSSpec
    Purpose:    Fills newstring create temporary file specification.
  -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void GetTempFSSpec(DPtr aDoc, FSSpec * temp)
{
	GUSIMakeTempFSp(aDoc->theFSSpec.vRefNum, 0, temp);
}

/**-----------------------------------------------------------------------
    Name:       SetText
    Purpose:    Sets the text of the supplied itemNo in aDialog to
					theString and select it.
  -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void SetText(DialogPtr aDialog, short itemNo, Str255 theString)
{
	Handle      itemHandle;
	Rect        box;
	short       kind;
	TEHandle    theTEHandle;

	GetDialogItem(aDialog, itemNo, &kind, &itemHandle, &box);
	SetDialogItemText(itemHandle, theString);

	theTEHandle = ((DialogPeek)aDialog)->textH;

	/*set all the text to be selected*/
	if (theTEHandle)
		TESetSelect(0, 32767, theTEHandle);
}

/**-----------------------------------------------------------------------
    Name:       RetrieveText
    Purpose:    Returns the text of anItem in aDialog in aString.
  -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void RetrieveText(DialogPtr aDialog, short anItem, Str255 aString)
{
	short      kind;
	Rect       box;
	Handle     itemHandle;

	GetDialogItem(aDialog, anItem, &kind, &itemHandle, &box);
	GetDialogItemText(itemHandle, aString);
}

/**-----------------------------------------------------------------------
    Name:      DrawDefaultOutline
    Purpose:   Draws an outline around theItem.
					Called as a useritem Proc by the dialog manager.
					To use place a useritem over the default item in the
					dialog and install the address of this proc as the item
					handle.
  -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void DrawDefaultOutline(DialogPtr theDialog, short theItem)
{
	short       kind;
	Handle      itemHandle;
	Rect        box;

	GetDialogItem(theDialog, theItem, &kind, &itemHandle, &box);
	PenSize(3, 3);
	InsetRect(&box, -4, -4);
	FrameRoundRect(&box, 16, 16);
	PenNormal();
}  /* DrawDefaultOutline */

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawDefaultOutline = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawDefaultOutline);
#endif

/**-----------------------------------------------------------------------
    Name:       AdornDefaultButton
    Purpose:    Installs DrawDefaultOutline as the useritem proc
					 for the given item.
-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal void AdornDefaultButton(DialogPtr theDialog,short theItem)
{
	short		kind;
	Handle	itemHandle;
 	Rect		box;

	GetDialogItem(theDialog, theItem, &kind, &itemHandle, &box);
	SetDialogItem(theDialog, theItem, kind, (Handle)&uDrawDefaultOutline, &box);
}

pascal void GetRectOfDialogItem(DialogPtr theDialog, short theItem, Rect *theRect)
{
	short       kind;
	Handle      itemHandle;

	GetDialogItem(theDialog, theItem, &kind, &itemHandle, theRect);
}

/**------  FeatureIsImplemented    ------------**/
/*	This is called to use Gestalt to determine if a feature is implemented.
 	This applies to only those referenced by OSType	*/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal Boolean FeatureIsImplemented(OSType theFeature, short theTestBit)
{
 	long      result;

	return !Gestalt(theFeature, &result) && (result & (1 << theTestBit));
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Utils
#endif

pascal Boolean CheckEnvironment()
{
	long result;
	
	/*check for the AppleEvents manager - we certainly can't work without it*/

	gAppleEventsImplemented   = FeatureIsImplemented(gestaltAppleEventsAttr, gestaltAppleEventsPresent);

	/*and for good measure- the Alias manager*/

	gAliasManagerImplemented  = FeatureIsImplemented(gestaltAliasMgrAttr, gestaltAliasMgrPresent);

	/*check if recording is implemented*/

	gRecordingImplemented   = FeatureIsImplemented(gestaltAppleEventsAttr,1);

	/*check for the Outline fonts*/

	gOutlineFontsImplemented  = FeatureIsImplemented(gestaltFontMgrAttr, gestaltOutlineFonts);

	/* check for Text Services and TSMTE */
	gTextServicesImplemented = !Gestalt(gestaltTSMgrVersion, &result) && (result > 0);
	gTSMTEImplemented	= FeatureIsImplemented(gestaltTSMTEAttr, gestaltTSMTEPresent);

	return 	gAliasManagerImplemented   &&
				gAppleEventsImplemented    &&
				gOutlineFontsImplemented;
}  /* CheckEnvironment */

/*
	DoPageSetup returns true if the page setup of the document is altered
*/

pascal Boolean DoPageSetup(DPtr theDoc)
{
	if (theDoc) {
		Boolean result;

		PrOpen();
		result =  PrStlDialog(theDoc->thePrintSetup);
		PrClose();

		return(result);
	}
	
	return false;
}  /* DoPageSetup */

/*
	Name:    CtrlKeyPressed
	Purpose: Returns true if control key pressed during event
*/
pascal Boolean CtrlKeyPressed(const EventRecord *theEvent)
{
	return theEvent->modifiers & controlKey;
}

/*
	Name:    OptionKeyPressed
	Purpose: Returns true if option key pressed during event
*/
pascal Boolean OptionKeyPressed(const EventRecord *theEvent)
{
	return theEvent->modifiers & optionKey;
}

#if TARGET_CPU_PPC
#define ARCHITECTURE "PowerPC"
#else
#if TARGET_RT_MAC_CFM
#define ARCHITECTURE "CFM-68K"
#else
#define ARCHITECTURE "68K"
#endif
#endif

pascal void DrawVersion(DialogPtr dlg, short item)
{
	VersRecHndl	vers;
	short		base;
	short 		width;
	Handle		h;
	Rect		r;
	FontInfo	info;
	char		label[50];

	GetDialogItem(dlg, item, &base, &h, &r);
	SetPort(dlg);
	TextFont(1);
	TextSize(9);
	GetFontInfo(&info);

	base = r.top+2+info.ascent;
	width= r.right-r.left;
	MoveTo(r.left+2, base);
	DrawString((StringPtr) "\pVersion");

	MoveTo(r.left + width/2, base);
	vers = (VersRecHndl) GetAppResource('vers', 1);
	HLock((Handle) vers);
	DrawText(label, 0, sprintf(label, "%#s", (*vers)->shortVersion));
	ReleaseResource((Handle) vers);

	base += info.ascent+info.descent+info.leading;
	MoveTo(r.left+2, base);
	DrawString((StringPtr) "\pArchitecture");
	
	MoveTo(r.left + width/2, base);
	DrawText(label, 0, sprintf(label, ARCHITECTURE));

	base += info.ascent+info.descent+info.leading;
	MoveTo(r.left+2, base);
	DrawString((StringPtr) "\pPatchlevel");
	
	MoveTo(r.left + width/2, base);
#if SUBVERSION
	DrawText(label, 0, sprintf(label, "5.%03d_%02d", PATCHLEVEL, SUBVERSION));
#else
	DrawText(label, 0, sprintf(label, "5.%03d", PATCHLEVEL));
#endif
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawVersion = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawVersion);
#else
#define uDrawVersion *(UserItemUPP)&DrawVersion
#endif

static ListHandle	CreditList;

pascal void DrawCredits(DialogPtr dlg, short item)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused(item)
#endif
	Rect	r;
	
	TextFont(1);
	TextSize(9);
	r = (*CreditList)->rView;
	MoveTo(r.left + 4, r.top - 8);
	TextFace(bold);
	DrawString("\pThanks to:");
	TextFace(normal);
	LUpdate(dlg->visRgn, CreditList);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uDrawCredits = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, DrawCredits);
#else
#define uDrawCredits *(UserItemUPP)&DrawCredits
#endif

pascal void DoAbout(Boolean easter)
{
	DialogPtr		dlg;
	WindowPtr		win;
	short				kind;
	short				count;
	Handle			hdl;
	Handle			sound;
	SndChannelPtr 	channel = nil;
	long				nextAction;
	Point 			cell;
	Rect				bounds;
	Rect				dbounds;
	Str255			string;
	EventRecord 	ev;
	
	SetCursor(&qd.arrow);
	
	dlg 	= GetNewAppDialog(AboutDialog+easter);
	sound 	= GetAppResource('snd ', AlertSoundID+easter);
	hdl 	= GetAppResource('STR#', CreditID);
	count	= **(short **) hdl;

	GetDialogItem(dlg, ad_PatchLevel, &kind, &hdl, &bounds);
	SetDialogItem(dlg, ad_PatchLevel, kind, (Handle) &uDrawVersion, &bounds);
	GetDialogItem(dlg, ad_Credits, &kind, &hdl, &bounds);
	SetDialogItem(dlg, ad_Credits, kind, (Handle) &uDrawCredits, &bounds);

	bounds.top   += 20;

	SetPort(dlg);
	TextFont(1);
	TextSize(9);
	SetPt(&cell, bounds.right - bounds.left, 12);
	SetRect(&dbounds, 0, 0, 1, count);
	CreditList = LNew(&bounds, &dbounds, cell, 0, dlg, false, false, false, false);
	
	SetPt(&cell, 0, 0);
	for (; cell.v < count; ++cell.v) {
		GetIndString(string, CreditID, cell.v+1);
		LSetCell((Ptr)(string+1), *string, cell, CreditList);
	}
	LSetDrawingMode(true, CreditList);
	
	HideDialogItem(dlg, ad_Version);
	ShowWindow(dlg);
	DrawDialog(dlg);
	
	nextAction = TickCount()+30;
	SetPt(&cell, 0, count-1);
	
	while (dlg) {
		if (TickCount() > nextAction) {
			if (sound) {
				RgnHandle versRgn = NewRgn();

				HLock(sound);
				if (!SndNewChannel(&channel, sampledSynth, initMono, nil))
					SndPlay(channel, (SndListHandle) sound, true);
					
				ShowDialogItem(dlg, ad_Version);
				GetDialogItem(dlg, ad_Version, &kind, &hdl, &bounds);
				RectRgn(versRgn, &bounds);
				UpdateDialog(dlg, versRgn);
				DisposeRgn(versRgn);
				
				if (channel)
					SndDisposeChannel(channel, false);
					
				ReleaseResource(sound);
				sound = nil;
			} else {
				LSetSelect(false, cell, CreditList);
				cell.v = (cell.v+1) % count;
				LSetSelect(true, cell, CreditList);
				LAutoScroll(CreditList);
			}
			nextAction += 30;
		}
		
		if (WaitNextEvent(mDownMask+keyDownMask+activMask+updateMask+osMask, &ev, 1, nil))
			switch (ev.what) {
			case activateEvt:
				if ((WindowPtr) ev.message != dlg)
					DoActivate((WindowPtr)ev.message, (ev.modifiers & activeFlag) != 0);
				else 
					LActivate(ev.modifiers & activeFlag, CreditList);
	
				break;
	
			case updateEvt:
				win = (WindowPtr) ev.message;
				if (win == dlg) {
					BeginUpdate(dlg);
					UpdateDialog(dlg, dlg->visRgn);
					EndUpdate(dlg);
				} else
					DoUpdate(DPtrFromWindowPtr(win), win);
				break;
	
			case kOSEvent:
				switch (ev.message & osEvtMessageMask) { /*high byte of message*/
				case 0x01000000:
						gInBackground = ((ev.message & resumeFlag) == 0);
				}
				if (!gInBackground)
					break;
			default:
				DisposeDialog(dlg);
				
				dlg = nil;
				break;
			}
	}
}

static void CenterWindow(DialogPtr dlg)
{
	Rect	*		screen;
	short			hPos;
	short			vPos;
	
	screen	=	&qd.screenBits.bounds;
	hPos	=	screen->right+screen->left-dlg->portRect.right >> 1;
	vPos	=	(screen->bottom-screen->top-dlg->portRect.bottom)/3;
	vPos	+=	screen->top;
	MoveWindow(dlg, hPos, vPos, true);
}	

pascal void Separator(DialogPtr dlg, short item)
{
	short		kind;
	Handle	h;
	Rect		r;
	
	PenPat(&qd.gray);
	GetDialogItem(dlg, item, &kind, &h, &r);
	FrameRect(&r);
	PenPat(&qd.black);
}

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uSeparator = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, Separator);
#endif

static DPtr		Documents[50];
static short	DocCount = 0;

pascal void RegisterDocument(DPtr doc)
{
	Documents[DocCount++] = doc;
}

pascal void UnregisterDocument(DPtr doc)
{
	short	i,j;
	
	for (i = 0, j = 0; i < DocCount; ++i)
		if (Documents[i] != doc)
			Documents[j++] = Documents[i];
	
	DocCount = j;
}

pascal void SetupWindowMenu()
{
	short			i;
	short			item = 0;
	WindowPtr	front;
	WindowPtr	win;
	MenuHandle	menu;
	Str255		name;
	int	 		needsSeparator = 0;
	
	DisposeMenu(myMenus[windowM]);
	menu = myMenus[windowM]	= GetMenu(windowID);
	
	front = FrontWindow();
	
	for (i = 0; i < DocCount; ++i)
		if (Documents[i]->kind != kDocumentWindow) {
			AppendMenu(menu, (StringPtr) "\px");
			GetWTitle(Documents[i]->theWindow, name);
			SetMenuItemText(menu, ++item, name);
			
			if (!IsWindowVisible(Documents[i]->theWindow))
				SetItemStyle(menu, item, italic);
			else if (Documents[i]->theWindow == front)
				SetItemMark(menu, item, checkMark);
			
			EnableItem(menu, item);
			needsSeparator = 1;
		}
	
	for (i = 0; i < DocCount; ++i)
		if (Documents[i]->kind == kDocumentWindow) {
			if (needsSeparator && needsSeparator < 2) {
				AppendMenu(menu, (StringPtr) "\p-(");
				++item;
			}
			
			AppendMenu(menu, (StringPtr) "\px");
			GetWTitle(Documents[i]->theWindow, name);
			SetMenuItemText(menu, ++item, name);
			
			if (!IsWindowVisible(Documents[i]->theWindow))
				SetItemStyle(menu, item, Documents[i]->dirty ? underline + italic : italic);
			else {
				if (Documents[i]->dirty)
					SetItemStyle(menu, item, underline);
				if (Documents[i]->theWindow == front)
					SetItemMark(menu, item, checkMark);
			}
			
			EnableItem(menu, item);
			needsSeparator = 2;
		}
	
	for (win = front; win; win = GetNextWindow(win)) {
		if (IsWindowVisible(win) && !Ours(win)) {
			if (needsSeparator && needsSeparator < 3) {
				AppendMenu(menu, (StringPtr) "\p-(");
				++item;
			}
			
			AppendMenu(menu, (StringPtr) "\px");
			GetWTitle(win, name);
			SetMenuItemText(menu, ++item, name);
			
			if (win == front)
				SetItemMark(menu, item, checkMark);
			
			EnableItem(menu, item);
			needsSeparator = 3;
		}
	}
}

static void AnointWindow(WindowPtr win)
{
	if (!IsWindowVisible(win))
		ShowWindow(win);
	SelectWindow(win);
}

pascal void DoSelectWindow(short item)
{
	short			i;
 	WindowPtr	win;
	MenuHandle	menu;
	int	 		needsSeparator = 0;
	
	menu = myMenus[windowM];
	
	for (i = 0; i < DocCount; ++i)
		if (Documents[i]->kind != kDocumentWindow) {
			if (!--item) {
				AnointWindow(Documents[i]->theWindow);
				
				return;
			}
			needsSeparator = 1;
		}
	
	for (i = 0; i < DocCount; ++i)
		if (Documents[i]->kind == kDocumentWindow) {
			if (needsSeparator && needsSeparator < 2) {
				--item;
			}
			
			if (!--item) {
				AnointWindow(Documents[i]->theWindow);
				
				return;
			}
			
			needsSeparator = 2;
		}
	
	for (win = FrontWindow(); win; win = GetNextWindow(win)) {
		if (IsWindowVisible(win) && !Ours(win)) {
			if (needsSeparator && needsSeparator < 3) {
				--item;
			}
			
			if (!--item) {
				AnointWindow(win);
				
				return;
			}
			
			needsSeparator = 3;
		}
	}
}

/* Borrowed from tech note 263 */

#define kKosherModifiers	0x0E00		// We keep only option & shift
#define kMaskVirtualKey 	0x0000FF00 	// get virtual key from event message
                                   		// for KeyTrans
#define kUpKeyMask      	0x0080
#define kShiftWord      	8          	// we shift the virtual key to mask it
                                   		// into the keyCode for KeyTrans
#define kMaskASCII1     	0x00FF0000 	// get the key out of the ASCII1 byte
#define kMaskASCII2     	0x000000FF 	// get the key out of the ASCII2 byte

pascal Boolean WeirdChar(const EventRecord * ev, short modifiers, char ch)
{
  	short    		keyCode;
  	long     		virtualKey, keyInfo, lowChar, highChar, keyCId;
	unsigned long	state;
  	Handle   		hKCHR;
	Ptr 				KCHRPtr;

	if ((ev->what == keyDown) || (ev->what == autoKey)) {

		// see if the command key is down.  If it is, find out the ASCII
		// equivalent for the accompanying key.

		if ((ev->modifiers & 0xFF00) == modifiers) {

			virtualKey 	= (ev->message & kMaskVirtualKey) >> kShiftWord;
			keyCode	  	= (ev->modifiers & kKosherModifiers & ~modifiers) | virtualKey;
			state 	  	= 0;

			hKCHR			= nil;  /* set this to nil before starting */
		 	KCHRPtr 		= (Ptr)GetScriptManagerVariable(smKCHRCache);

			if ( !KCHRPtr ) {
				keyCId 	=	GetScriptVariable((short) GetScriptManagerVariable(smKeyScript), smScriptKeys);
				hKCHR		=	GetResource('KCHR', (short) keyCId);
				KCHRPtr	= *hKCHR;
			}

			if (KCHRPtr) {
				keyInfo = KeyTranslate(KCHRPtr, keyCode, &state);
				if (hKCHR)
					ReleaseResource(hKCHR);
			} else
				keyInfo = ev->message;

			lowChar =  keyInfo &  kMaskASCII2;
			highChar = (keyInfo & kMaskASCII1) >> 16;
			if (lowChar == ch || highChar == ch)
				return true;

		}  // end the command key is down
	}  // end key down event

	return false;
}


pascal Boolean SameFSSpec(FSSpec * one, FSSpec * other)
{
	return 	one->vRefNum	==		other->vRefNum 
		&&		one->parID		==		other->parID
		&& 	EqualString(one->name, other->name, false, true);
}

pascal DialogPtr GetNewAppDialog(short ID)
{
	short		resFile;
	DialogPtr	result;
	
	resFile = CurResFile();
	UseResFile(gAppFile);
	result 	= GetNewDialog(ID, nil, (WindowPtr) -1);
	UseResFile(resFile);
	
	return result;
}

pascal DialogPtr GetNewAppWindow(short ID)
{
	short		resFile;
	DialogPtr	result;
	
	resFile = CurResFile();
	UseResFile(gAppFile);
	result 	= GetNewWindow(ID, nil, (WindowPtr) -1);
	UseResFile(resFile);
	
	return result;
}

pascal short AppAlert(short ID)
{

	short	resFile;
	short	result;
	
	resFile = CurResFile();
	UseResFile(gAppFile);
	result 	= Alert(ID, nil);
	UseResFile(resFile);
	
	return result;
}

pascal Handle GetAppResource(OSType resType, short ID)
{
	short	resFile;
	Handle	result;
	
	resFile = CurResFile();
	UseResFile(gAppFile);
	result 	= Get1Resource(resType, ID);
	UseResFile(resFile);
	
	return result;
}


void RemoveConsole()
{
}

int faccess()
{
	return -1;
}

#ifndef powerc
#pragma far_data off
#endif

int StandAlone = 1;

#ifndef powerc
#pragma far_data reset
#endif

void __ttyname()
{
}
