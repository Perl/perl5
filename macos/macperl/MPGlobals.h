/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPGlobals.h	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPGlobals.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.4  1998/04/07 01:46:38  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:52  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:00  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:48  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:51:46  neeri
Inline Input.

Revision 1.1  1994/02/27  23:03:27  neeri
Initial revision

Revision 0.5  1993/12/12  00:00:00  neeri
PerlPrefs, SacrificalGoat

Revision 0.4  1993/08/17  00:00:00  neeri
LibraryPaths

Revision 0.3  1993/08/05  00:00:00  neeri
Small icons

Revision 0.2  1993/05/29  00:00:00  neeri
Support console windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#ifndef __MPGLOBALS__
#define __MPGLOBALS__

#include <Types.h>
#include <QuickDraw.h>
#include <Menus.h>
#include <Printing.h>
#include <AppleEvents.h>
#include <TextServices.h>
#include <TextUtils.h>
#include <NumberFormatting.h>
#include <Sound.h>
#include <TSMTE.h>
#include <InternetConfig.h>
#include <stdio.h>
#include <setjmp.h>

#define X2P
#define MAC_CONTEXT
#include "macish.h"

#include "MPRsrc.h"

#ifndef EXTERN
#define EXTERN extern 
#define INIT(x)
#endif

#if !ACCESSOR_CALLS_ARE_FUNCTIONS
#define AEGetDescData(spec, buf, sz) (memcpy((buf), *(spec)->dataHandle, (sz)), 0)
#endif

#define  PerlWindowKind		5146

#define	LibraryPaths		128
#define 	EnvironmentVars	129	

/*
	Items in Apple Menu
*/

#define  aboutItem  1

/*
	Items in File Menu
*/

#define  fmNew					1
#define  fmOpen				2
#define  fmClose				4
#define  fmSave				5
#define  fmSaveAs				6
#define  fmRevert				7
#define  fmPageSetUp			9
#define  fmPrint				10
#define 	fmStopScript		12
#define  fmQuit				14

/*
	Items in Edit Menu
*/
#define  undoCommand			1
#define  cutCommand 			3
#define  copyCommand 		4
#define  pasteCommand 		5
#define  clearCommand 		6
#define  selectAllCommand 	7

#define	emFind				9
#define 	emFindAgain			10
#define	emJumpTo				11
#define	emFormat				13

#define	emPreferences		15

/* 
	Items in Editor Menu 
*/
#define	xmEdit			1
#define	xmEditFront		2
#define 	xmUpdate			4
#define 	xmUpdateFront	5

/*
	Items in Perl Menu
*/
#define	pmRun				1
#define	pmRunFront		2
#define	pmCheckSyntax	3
#define	pmCheckFront	4
#define	pmWarnings		6
#define	pmDebug			7
#define	pmTaint			8
#define	pmStandard		10

/*
	Item in Help Menu
*/
#define	hmExplain		5

/*
	Entry of Menu in myMenus
*/
#define  appleM 			0
#define  fileM 		 	1
#define  editM 		 	2
#define	windowM			3
#define	editorM			4
#define	perlM				5
#define	helpM				6
#define  kLastMenu		6

/*
	Save Changes Dialog Items
*/

#define  aaSave 		 	1
#define  aaDiscard 	 	2
#define  aaCancel 		3

#define  kOSEvent			   		app4Evt	/*event used by MultiFinder*/
#define  kSuspendResumeMessage		1		/*high byte of suspend/resume event message*/
#define  kResumeMask				 		1		/*bit of message field for resume vs. suspend*/
#define  kMouseMovedMessage		  	0xFA	/*high byte of mouse-moved event message*/
#define  kNoEvents					 	0		/*no events mask*/

/* How much memory to set aside for emergencies */

#define SACRIFICE		65536

/* File too bulky for TextEdit */

#define elvisErr		666

typedef enum {
	kDocumentWindow,
	kWorksheetWindow,
	kConsoleWindow
} WindowKind;

#if defined(powerc) || defined (__powerc)
#pragma options align=mac68k
#endif

typedef struct RegularDoc {
	Boolean      	showBorders;
	Boolean        everSaved;
	Boolean			everLoaded;
	FSSpec 			origFSSpec;
} RegularDoc;

struct DocRec;

typedef struct ConsoleDoc {
	struct DocRec *next;
	Ptr				cookie;
	short				memory;
	short				fence;
	Boolean			selected;
} ConsoleDoc;

enum {
	stateConsole = 0x0001,
	stateDocument= 0x0002,
	stateRdWr    = 0x0010,
	stateRdOnly  = 0x0020,
	stateBlocked = 0x0030
};

enum {
	kPreferenceDoc = 'pref',
	kPlainTextDoc	= 'TEXT',
	kScriptDoc		= 'SCPT',
	kRuntime7Doc	= 'MrP7',
	kOldRuntime6Doc= 'OlP6',
	kUnknownDoc		= '\?\?\?\?'
};

typedef OSType	DocType;

struct DocRec {
	TEHandle       theText;
	ControlHandle  vScrollBar;
	ControlHandle  hScrollBar;
	WindowPtr      theWindow;
	short          refNum;
	short				lastState;
	Str255         theFileName;
	FSSpec		   theFSSpec;
	THPrint        thePrintSetup;
	Rect           pageSize;    /*From thePrintSetUp^^.prInfo.rPage but 0 offset*/
	Boolean        dirty;
	Boolean			inDataFork;
	WindowKind		kind;
	DocType			type;
	TSMTERecHandle	tsmTERecHandle;
	TSMDocumentID	tsmDoc;
	union {
		RegularDoc	reg;
		ConsoleDoc	cons;
	} u;
};

typedef struct DocRec DocRec;
typedef DocRec *DPtr;

struct HeaderRec {
	Rect		theRect;
	Str255   theFont;
	short		theSize;
	short    theLength;
	short    numSections;
	short    lastID;
};

typedef struct HeaderRec HeaderRec;

typedef HeaderRec *HPtr, **HHandle;

struct DocFormat {
	short		font;
	short		size;
};

typedef struct DocFormat DocFormat;

struct PerlPrefs	{
	short		version;
#define PerlPrefVersion411	0
#define PerlPrefVersion413	1
#define PerlPrefVersion500 2
	Boolean	runFinderOpens;
	Boolean	checkType;
	Boolean	inlineInput;
};

typedef struct PerlPrefs PerlPrefs;

#if defined(powerc) || defined (__powerc)
#pragma options align=reset
#endif

EXTERN short      		gWCount;
EXTERN short      		gNewDocCount;
EXTERN MenuHandle 		myMenus[kLastMenu+1];
EXTERN short      		gFontMItem;
EXTERN Boolean    		gQuitting;
EXTERN Boolean    		gAborting;
EXTERN Boolean				gWarnings;
EXTERN Boolean				gDebug;
EXTERN Boolean				gTaint;
EXTERN Boolean    		gInBackground;
EXTERN Boolean				gRunningPerl;
EXTERN Boolean				gRemoteControl;
EXTERN Boolean				gExplicitWNE;
EXTERN Cursor     		editCursor;
EXTERN Cursor     		waitCursor;
EXTERN DPtr					gConsoleList;
MP_EXT short				gPrefsFile;
EXTERN short				gScriptFile;
EXTERN WindowPtr			gActiveWindow;
MP_EXT short				gAppFile;
MP_EXT short				gAppVol;
MP_EXT long					gAppDir;
EXTERN DocFormat			gFormat;
EXTERN Handle				gRuntimeScript;
EXTERN Handle				gPseudoFile;
EXTERN AppleEvent **		gWaitingScripts;
EXTERN DPtr					gGotEof;
EXTERN PerlPrefs			gPerlPrefs;
MP_EXT Handle				gSacrificialGoat;
EXTERN jmp_buf				gExitPerl;
EXTERN AppleEvent			gDelayedScript;
EXTERN short				gCompletedScripts;
EXTERN long 				gSavedFontForce;
EXTERN ICAppSpecHandle	gExternalEditor;
EXTERN Handle				gCachedLibraries;

  /*now for the environment variables set up by Gestalt*/

EXTERN Boolean    gAppleEventsImplemented;

EXTERN Boolean    gAliasManagerImplemented;
EXTERN Boolean    gOutlineFontsImplemented;
EXTERN Boolean    gRecordingImplemented;
EXTERN Boolean		gTextServicesImplemented;
EXTERN Boolean		gTSMTEImplemented;
EXTERN ICInstance	gICInstance;

#endif