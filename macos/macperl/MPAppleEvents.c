/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPAppleEvents.c	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPAppleEvents.c,v $
Revision 1.3  2001/10/22 19:28:01  pudge
Sync with perforce

Revision 1.2  2001/04/03 06:51:37  neeri
Alias code was messing up double clicks from the finder (MacPerl bug #409948)

Revision 1.6  1999/01/24 05:07:00  neeri
Tweak alias handling

Revision 1.5  1998/04/14 19:46:35  neeri
MacPerl 5.2.0r4b2

Revision 1.4  1998/04/07 01:46:28  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:46  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:57:48  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:32  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:48:27  neeri
Inline input.
Fix deletions.

Revision 1.1  1994/02/27  22:59:44  neeri
Initial revision

Revision 0.4  1993/08/28  00:00:00  neeri
FormatCommand

Revision 0.3  1993/08/16  00:00:00  neeri
DoScript

Revision 0.2  1993/05/30  00:00:00  neeri
Support console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <AppleEvents.h>
#include <LowMem.h>
#include <Menus.h>
#include <PLStringFuncs.h>
#include <Scrap.h>
#include <TextEdit.h>
#include <AEObjects.h>
#include <AEPackObject.h>
#include <AERegistry.h>
#include <AEStream.h>
#include <AEBuild.h>
#include <Resources.h>
#include <String.h>
#include <GUSIFileSpec.h>

#include "MPGlobals.h"
#include "MPUtils.h"
#include "MPAEUtils.h"
#include "MPWindow.h"
#include "MPFile.h"
#include "MPAppleEvents.h"
#include "MPScript.h"
#include "MPSave.h"
#include "MPPreferences.h"
#include "MPAEVTStream.h"
#include "MPEditor.h"

/* these should come from the registry */

#define 		kAEStartedRecording  'rec1'
#define 		kAEStoppedRecording	'rec0'
#define 		kAEDontExecute 		0x00002000

#define 		pText 					'TEXT'
#define     cSpot             	'cspt'

/*
	Text Properties
*/

#define 		pStringWidth			'pwid'

/*
	Window Properties - See the Registry for Details
*/

#define     pPosition			   'ppos'
#define 		pPageSetup				'PSET' /* One of ours - Not in registry */
#define 		pShowBorders			'PBOR' /* Another of ours */

#define 		typeTPrint				'TPNT' /* A raw TPrint record - also one of ours */

/*
	Error Codes
*/

#define 		kAEGenericErr    -1799

static short   gBigBrother;
static char    *gTypingBuffer;
static short   gCharsInBuffer;
static AEDesc  gTypingTargetObject;

pascal Boolean AllSelected(TEHandle te)
{
	return ((*te)->selStart == 0 && (*te)->selEnd == (*te)->teLength);
}

/*-----------------------------------------------------------------------*/
/**----------						 APPLE EVENT HANDLING 		---------------**/
/*-----------------------------------------------------------------------*/

pascal OSErr GetTHPrintFromDescriptor(const AEDesc *sourceDesc, THPrint *result)
{
	OSErr   myErr;
	Size    ptSize;
	AEDesc  resultDesc;

	*result = nil;

	if (myErr = AECoerceDesc(sourceDesc,typeTPrint,&resultDesc))
		return myErr;

	*result = (THPrint)NewHandle(sizeof(TPrint));

	PrOpen();
	PrintDefault(*result);

	HLock((Handle)*result);

	GetRawDataFromDescriptor(&resultDesc, (Ptr)**result, sizeof(TPrint), &ptSize);

	HUnlock((Handle)*result);

	if ((ptSize<sizeof(TPrint)) || (PrValidate(*result))) {
		myErr = errAECoercionFail;
		DisposeHandle((Handle)*result);
		*result = nil;
	}

	PrClose();

	if (resultDesc.dataHandle)
		AEDisposeDesc(&resultDesc);

	return myErr;
} /*GetTHPrintFromDescriptor*/

/*******************************************************************************/
/*
	Object Accessors - Utility Routines
*/

#if !defined(powerc) && !defined(__powerc)
#pragma segment ObjectAccessors
#endif

/*
	Returns the WindowPtr of the window with title nameStr
	or nil if there is no matching window.
*/
pascal WindowPtr WindowNameToWindowPtr(StringPtr nameStr)
{
	WindowPtr theWindow;
	Str255    windTitle;

	theWindow = (WindowPtr)LMGetWindowList();
	/*
		iterate through windows - we use WindowList 'cos we could
		have made the window invisible and  we lose it - so we
		can't set it back to visible!!
	*/
	while (theWindow) {
		GetWTitle(theWindow, windTitle);
		if (DPtrFromWindowPtr(theWindow) && EqualString(windTitle,
							 nameStr,
										false,
										true)) 	/* ignore case, don't ignore diacriticals */
			return theWindow;
	  theWindow = GetNextWindow(theWindow);
	}

	return theWindow;
}	/* WindowNameToWindowPtr */

pascal WindowPtr GetWindowPtrOfNthWindow(short index)
/* returns a ptr to the window with the given index
  (front window is 1, behind that is 2, etc.).  if
  there's no window with that index (inc. no windows
  at all), returns nil.
*/
{
  WindowPtr theWindow;

	theWindow = (WindowPtr)LMGetWindowList();

	/* iterate through windows */

	while (theWindow) {
		if (DPtrFromWindowPtr(theWindow) && --index <= 0)
			return theWindow;

	  theWindow = GetNextWindow(theWindow);
	}

	return nil;
}	/* GetWindowPtrOfNthWindow */

pascal short CountWindows(void)
{
	WindowPtr theWindow;
	short     index;

	index = 0;
	theWindow = (WindowPtr)LMGetWindowList();

	/* iterate through windows */

	while (theWindow) {
		if (DPtrFromWindowPtr(theWindow)) 
			index++;
		theWindow = GetNextWindow(theWindow);
	}

	return index;
} /*CountWindows*/

/**-----------------------------------------------------------------------
		Name: 		DoStopScript
		Purpose:		Stop currently running script.
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal OSErr DoStopScript(const AppleEvent *message, AppleEvent *reply, long refcon)
{
	if (gRunningPerl)
		gAborting = true;

	return noErr;
}

/**-----------------------------------------------------------------------
		Name: 		DoOpenApp
		Purpose:		Called on startup, creates a new document.
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal OSErr DoOpenApp(const AppleEvent *message, AppleEvent *reply, long refcon)
{
	if (gRuntimeScript)
		return DoScript(message, reply, refcon);

	return noErr;
}

/**-----------------------------------------------------------------------
		Name: 		DoOpenDocument
		Purpose:		Open all the documents passed in the Open AppleEvent.
-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal OSErr DoOpenDocument(const AppleEvent *message, AppleEvent *reply, long refcon)
{
	long        index;
	long        itemsInList;
	AEKeyword   keywd;
	OSErr       err;
	OSErr       ignoreErr;
	AEDescList  docList;
	long        actSize;
	DescType    typeCode;
	FSSpec      theFSSpec;
	EventRecord	ev;
	DocType		type;

	if (gRuntimeScript)
		return DoScript(message, reply, refcon);
	
	/* open the specified documents */

	docList.dataHandle = nil;

	err = AEGetParamDesc(message, keyDirectObject, typeAEList, &docList);

	if (err==noErr)
		err = AECountItems( &docList, &itemsInList) ;
	else
	  itemsInList = 0;

	if (itemsInList) {
		err =
			AEGetNthPtr(&docList, 1, typeFSS, &keywd, &typeCode, (Ptr)&theFSSpec, sizeof(theFSSpec), &actSize);
		
		if (!err) {
			type = GetDocType(&theFSSpec);
			
			GetNextEvent(0, &ev);
		
			switch (type) {
			case kPlainTextDoc:
			case kOldRuntime6Doc:
			case kRuntime7Doc:
				if (!(ev.modifiers & optionKey) != gPerlPrefs.runFinderOpens)
					break;
				if (refcon != -1)
					break;
					
				err = DoScript(message, reply, 0);
					
				goto done;
			}
		}
	}

	for (index = 1; index <= itemsInList; index++)
		if (err==noErr) {
			err = AEGetNthPtr( &docList, index, typeFSS, &keywd, &typeCode,
												 (Ptr)&theFSSpec, sizeof(theFSSpec), &actSize ) ;
			if (err==noErr)
				switch (type = GetDocType(&theFSSpec)) {
				case kUnknownDoc:
					break;
				case kPreferenceDoc:
					OpenPreferenceFile(&theFSSpec);
					break;
				case kPlainTextDoc:
				case kOldRuntime6Doc:
				case kScriptDoc:
				case kRuntime7Doc:
				default:
			  		err = OpenOld(theFSSpec, type);
					break;
				}
		}

done:	
  if (docList.dataHandle)
		ignoreErr = AEDisposeDesc(&docList);

	return err;
}

/**-----------------------------------------------------------------------
		Name: 		MyQuit
		Purpose:		Quit event received- exit the program.
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal OSErr MyQuit(const AppleEvent *message, const AppleEvent *reply, long refcon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,refcon)
#endif

	DescType saveOpt;
	OSErr    myErr;
	DescType returnedType;
	long     actSize;

	saveOpt = kAEAsk; /* the default */
	myErr = AEGetParamPtr(message,
									keyAESaveOptions,
									typeEnumerated,
									&returnedType,
									(Ptr)&saveOpt,
									sizeof(saveOpt),
									&actSize);

	if (saveOpt != kAENo)
		myErr = AEInteractWithUser(kAEDefaultTimeout, nil, nil);

	if (myErr == noErr)
		DoQuit(saveOpt);

	return myErr;
}

/**-----------------------------------------------------------------------
		Name: 		DoAppleEvent
		Purpose:		Process and despatch the AppleEvent
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal void DoAppleEvent(EventRecord theEvent)
{
  OSErr err;

  /*should check for your own event message types here - if you have any*/

	err = AEProcessAppleEvent(&theEvent);
}

/**-----------------------------------------------------------------------
		Name: 		MakeSelfAddress
		Purpose:		Builds an AEAddressDesc for the current process
	-----------------------------------------------------------------------**/

pascal OSErr MakeSelfPSN(ProcessSerialNumber *selfPSN)
{
	selfPSN->highLongOfPSN = 0;
	selfPSN->lowLongOfPSN  = kCurrentProcess;
	
	return noErr;
}

pascal OSErr MakeSelfAddress(AEAddressDesc *selfAddress)
{
  	ProcessSerialNumber procSerNum;

	MakeSelfPSN(&procSerNum);

	return
		AECreateDesc(
			typeProcessSerialNumber,
			(Ptr)&procSerNum,
			sizeof(procSerNum),
			selfAddress);
} /* MakeSelfAddress */

/**--------------------------------------------------------------------
	Name : 		SendAESetObjProp
	Function : 	Creates a property object from an object,
					a property type and its data and sends it to
					the requested address, and cleans up zapping params too
	--------------------------------------------------------------------**/

pascal OSErr SendAESetObjProp(
	AEDesc        *theObj,
	DescType      theProp,
	AEDesc        *theData,
	AEAddressDesc *toWhom)
{
	AEDesc     propObjSpec;
	AppleEvent myAppleEvent;
	AppleEvent defReply;
	OSErr      myErr;
	OSErr      ignoreErr;
	AEDesc     theProperty;

	/* create an object spec that represents the property of the given object */

	myErr = AECreateDesc(typeType, (Ptr)&theProp, sizeof(theProp), &theProperty);
	if (myErr==noErr)
		myErr =
			CreateObjSpecifier(
				cProperty,
				theObj,
				formPropertyID,
				&theProperty,
				true,
				&propObjSpec);

	/* create event */

	if (myErr==noErr)
		myErr =
			AECreateAppleEvent(
				kAECoreSuite,
				kAESetData,
				toWhom,
				0,
				0,
				&myAppleEvent);

	/* add prop obj spec to the event */

	if (myErr==noErr)
		myErr = AEPutParamDesc(&myAppleEvent, keyDirectObject, &propObjSpec);

	/* add prop data to the event */

	if (myErr==noErr)
		myErr = AEPutParamDesc(&myAppleEvent, keyAEData, theData);

	/* send event */

	if (myErr==noErr)
		myErr =
			AESend(
				&myAppleEvent,
				&defReply,
				kAENoReply+kAEAlwaysInteract,
				kAENormalPriority,
				kAEDefaultTimeout,
				nil,
				nil);

	if (myAppleEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&myAppleEvent);

	if (&propObjSpec.dataHandle)
	  ignoreErr = AEDisposeDesc(&propObjSpec);

	if (theData->dataHandle)
		ignoreErr = AEDisposeDesc(theData);

	if (toWhom->dataHandle)
		ignoreErr = AEDisposeDesc(toWhom);

	return myErr;
}	/* SendAESetObjProp */

/*----------------------------------------------------------------------------------------------*/
/*
	Private AEObject definitions
*/
#if !defined(powerc) && !defined(__powerc)
#pragma segment AECommandHandlers
#endif

#define typeMyAppl       'BAPP'	/* sig of my private token type for the app     - appToken   */
#define typeMyWndw		 'BWIN'	/* sig of my private token type for windows     - windowToken   */
#define typeMyText  		 'BTXT'	/* sig of my private token type for text        - textToken     */
#define typeMyTextProp   'BPRP'	/* sig of my private token type for text properties    - textPropToken */
#define typeMyWindowProp 'WPRP'	/* sig of my private token type for window properties  - windowPropToken */
#define typeMyApplProp   'APRP'	/* sig of my private token type for appl properties    - applPropToken */
#define typeMyMenu       'MTKN'	/* sig of my private token type for menus       - menuToken  */
#define typeMyMenuItem   'ITKN'	/* sig of my private token type for menus       - menuItemToken  */
#define typeMyMenuProp   'MPRP'	/* sig of my private token type for menu properties - menuPropToken  */
#define typeMyItemProp   'IPRP'	/* sig of my private token type for menu item properties  - menuItemPropToken  */

/* These are entirely private to our app - used only when resolving the object specifier */

typedef	ProcessSerialNumber appToken;

struct applPropToken{
	appToken tokenApplToken;
	DescType tokenApplProperty;
};

typedef struct applPropToken applPropToken;

typedef	WindowPtr WindowToken;

struct windowPropToken{
		WindowToken tokenWindowToken;
		DescType    tokenProperty;
	};

typedef struct windowPropToken windowPropToken;

struct TextToken{
		WindowPtr tokenWindow;
		short     tokenOffset;
		short     tokenLength;
	};

typedef struct TextToken TextToken;

struct textPropToken{
		TextToken propertyTextToken;
		DescType  propertyProperty;
	};

typedef struct textPropToken textPropToken;

/* Tokens related to menus */

struct MenuToken {
	MenuHandle theTokenMenu;
	short      theTokenID;
};

typedef struct MenuToken MenuToken;

struct MenuItemToken {
	MenuToken  theMenuToken;
	short      theTokenItem;
};

typedef struct MenuItemToken MenuItemToken;

struct MenuPropToken {
	MenuToken  theMenuToken;
	DescType   theMenuProp;
};

typedef struct MenuPropToken MenuPropToken;

struct MenuItemPropToken {
	MenuItemToken  theItemToken;
	DescType       theItemProp;
};

typedef struct MenuItemPropToken MenuItemPropToken;

/*
	Name: GotRequiredParams
	Function: Checks all parameters defined as 'required' have been read
*/
pascal OSErr GotRequiredParams(const AppleEvent *theAppleEvent)
{
	OSErr    myErr;
	DescType returnedType;
	Size     actSize;

	/* look for the keyMissedKeywordAttr, just to see if it's there */

	myErr =
		AEGetAttributePtr(
			theAppleEvent,
			keyMissedKeywordAttr,
			typeWildCard,
			&returnedType,
			nil,
			0,
			&actSize);

	if (myErr == errAEDescNotFound)
		return noErr;			/* attribute not there means we got all req params */
	else
		if (myErr == noErr)
			return errAEParamMissed;		/* attribute there means missed at least one */
		else
			return myErr;		/* some unexpected arror in looking for the attribute */
}	/* GotReqiredParams */

/**--------------------------------------------------------------------
	Name : SetSelectionOfAppleEventDirectObject
	Function : Resolves the Direct Object into a text token and
						 sets the selection of the specified document to that
						 specified in the direct object.
						 Returns the doc and TEHandle chosen.
	--------------------------------------------------------------------**/

pascal OSErr SetSelectionOfAppleEventDirectObject(
	const AppleEvent *theAppleEvent,
	DPtr             *theDocument,
	TEHandle         *theHTE)
{
	OSErr     myErr;
	DescType  returnedType;
	long      actSize;
	TextToken myTextToken;
	OSErr     paramErr;
	WindowPtr fWin;

	paramErr =
		AEGetParamPtr(
			theAppleEvent,
			keyDirectObject,
			typeMyText,
			&returnedType,
			(Ptr)&myTextToken,
			sizeof(myTextToken),
			&actSize);

	myErr = GotRequiredParams(theAppleEvent);

	/* now let's work on the direct object, if any */

	if (paramErr == errAEDescNotFound) {
		/* no direct object; check we have a window */

		fWin = FrontWindow();

		if (fWin == nil)
			return -1700; /* Generic Err */

		*theDocument = DPtrFromWindowPtr(fWin);
		*theHTE      = (*theDocument)->theText;
	}

	if (paramErr == noErr)  {
		/* got a text token */

		*theDocument = DPtrFromWindowPtr(myTextToken.tokenWindow);
		*theHTE      = (*theDocument)->theText;

		TESetSelect(
			myTextToken.tokenOffset-1,
			myTextToken.tokenOffset+myTextToken.tokenLength-1,
			*theHTE);

	}

	if ((paramErr!=noErr) &&
		 (paramErr!=errAEDescNotFound)
	) {
		 *theDocument = DPtrFromWindowPtr(FrontWindow());
		 *theHTE      = (*theDocument)->theText;
	 }

	return myErr;

} /* SetSelectionOfAppleEventDirectObject */

/**--------------------------------------------------------------------
	Name 			: SetSelectionOfAppleEventObject
	Function 	: Resolves the whatObject type of the AppleEvent into a text
					  token and sets the selection to be that specified in the
					  text token.
					  Returns the doc and TEHandle chosen.
	--------------------------------------------------------------------**/

pascal OSErr SetSelectionOfAppleEventObject(
	OSType            whatObject,
	const AppleEvent *theAppleEvent,
	DPtr             *theDocument,
	TEHandle         *theHTE)
{
	DescType   returnedType;
	long       actSize;
	TextToken  myTextToken;
	OSErr      paramErr;

	paramErr  =
		AEGetParamPtr(
			theAppleEvent,
			whatObject,
			typeMyText,
			&returnedType,
			(Ptr)&myTextToken,
			sizeof(myTextToken),
			&actSize);

	if (paramErr == noErr) {
		/* got a text token */

		*theDocument = DPtrFromWindowPtr(myTextToken.tokenWindow);
		*theHTE      = (*theDocument)->theText;

		TESetSelect(
			myTextToken.tokenOffset-1,
			myTextToken.tokenOffset+myTextToken.tokenLength-1,
			*theHTE);
	}

	return paramErr;
} /* SetSelectionOfAppleEventObject */

pascal void EnforceMemory(DPtr theDocument, TEHandle theHTE)
{
	if (theDocument->kind != kDocumentWindow && (*theHTE)->teLength > theDocument->u.cons.memory) {
		short	obulus =	(*theHTE)->teLength - theDocument->u.cons.memory;
		short saveStart;
		short	saveEnd;
		Ptr	search = *(*theHTE)->hText;
		short rest   = theDocument->u.cons.memory;
		
		while (search[obulus-1] != '\n' && rest--)
			++obulus;
			
		saveStart	=	(*theHTE)->selStart - obulus;
		saveEnd		=	(*theHTE)->selEnd	  - obulus;
		
		TESetSelect(0, obulus, theHTE);
		TEDelete(theHTE);
		TESetSelect(saveStart < 0 ? 0 : saveStart, saveEnd < 0 ? 0 : saveEnd, theHTE);
		
		if (theDocument->u.cons.fence < 32767)
			theDocument->u.cons.fence	-=	obulus;
	}
}

/* -----------------------------------------------------------------------
		Name: 		DoCopyEdit
		Purpose:		Performs a copy text operation on the text selection specified
						by the appleEvent direct object (if any)
	 -----------------------------------------------------------------------**/

pascal OSErr DoCopyEdit(const AppleEvent *theAppleEvent,AppleEvent *reply, long refCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,refCon)
#endif

	OSErr    myErr;
	TEHandle theHTE;
	DPtr     theDocument;

	/*
			Here we extract the information about what to copy from the
			directObject - if any
	*/

	if (myErr = SetSelectionOfAppleEventDirectObject(theAppleEvent,&theDocument,&theHTE))
		return myErr;

	myErr = (OSErr) ZeroScrap();
	TECopy(theHTE);
	TEToScrap();

	if (myErr)
		return myErr;

	if (!SetSelectionOfAppleEventObject(
		keyAEContainer,
		theAppleEvent,
		&theDocument,
		&theHTE)
	) {
		if (theDocument->kind != kDocumentWindow)	
			if (!theDocument->u.cons.selected || (*theHTE)->selStart < theDocument->u.cons.fence) {
				SysBeep(1);
				
				return errAEEventNotHandled;
			}
			
		TEFromScrap();
		TEPaste(theHTE);
		EnforceMemory(theDocument, theHTE);
		AdjustScrollbars(theDocument, false);
		DrawPageExtras(theDocument);
			
		theDocument->dirty = true;
	}

	return noErr;
} /* DoCopyEdit */

/* -----------------------------------------------------------------------
		Name: 			DoCutEdit
		Purpose:		Performs a cut text operation on the current text selection
	 -----------------------------------------------------------------------**/

pascal OSErr DoCutEdit(const AppleEvent *theAppleEvent, AppleEvent *reply, long refCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,refCon)
#endif

	OSErr    myErr;
	TEHandle theHTE;
	DPtr     theDocument;

	if (myErr = SetSelectionOfAppleEventDirectObject(theAppleEvent,&theDocument,&theHTE))
		return myErr;

	if (theDocument->kind == kDocumentWindow) {
		theDocument->dirty = true;
	} else if (!theDocument->u.cons.selected || (*theHTE)->selStart < theDocument->u.cons.fence) {
		if (AllSelected(theHTE)) {
			if (theDocument->u.cons.fence < 32767)
				theDocument->u.cons.fence = 0;
		} else {
			SysBeep(1);
		
			return DoCopyEdit(theAppleEvent, reply, refCon);
		}
	}

	myErr = (OSErr) ZeroScrap();
	TECut(theHTE);
	TEToScrap();
	AdjustScrollbars(theDocument, false);
	DrawPageExtras(theDocument);

	return myErr;
} /* DoCutEdit */

/* -----------------------------------------------------------------------
		Name: 		DoPasteEdit
		Purpose:		Performs a paste text operation on the text selection specified
						by the appleEvent direct object (if any)
	 -----------------------------------------------------------------------**/

pascal OSErr DoPasteEdit(const AppleEvent *theAppleEvent, AppleEvent *reply, long refCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,refCon)
#endif

	OSErr    myErr;
	TEHandle theHTE;
	DPtr     theDocument;

	if (myErr = SetSelectionOfAppleEventDirectObject(theAppleEvent, &theDocument, &theHTE))
		return myErr;

	if (theDocument->kind != kDocumentWindow) 
		if (!theDocument->u.cons.selected || (*theHTE)->selStart < theDocument->u.cons.fence) {
			SysBeep(1);
			
			return errAEEventNotHandled;
		}
	
	TEFromScrap();
	TEPaste(theHTE);
	EnforceMemory(theDocument, theHTE);
	AdjustScrollbars(theDocument, false);
	DrawPageExtras(theDocument);
		
	theDocument->dirty = true;

	return noErr;
} /* DoPasteEdit */

/* -----------------------------------------------------------------------
		Name: 		DoDeleteEdit
		Purpose:		Performs a delete text operation on the selection specified
						by the appleEvent direct object (if any)
	 -----------------------------------------------------------------------**/

pascal OSErr DoDeleteEdit(const AppleEvent *theAppleEvent, AppleEvent *reply, long refcon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,refcon)
#endif

	OSErr     myErr;
	TEHandle theHTE;
	DPtr     theDocument;

	if (myErr = SetSelectionOfAppleEventDirectObject(theAppleEvent, &theDocument, &theHTE))
		return myErr;

	if (theDocument->kind != kDocumentWindow)
		if (!theDocument->u.cons.selected || (*theHTE)->selStart < theDocument->u.cons.fence) {
			if (AllSelected(theHTE)) {
				if (theDocument->u.cons.fence < 32767)
					theDocument->u.cons.fence = 0;
			} else {
				SysBeep(1);
					
				return errAEEventNotHandled;
			}
			theDocument->u.cons.fence = 0;
		}
	
	TEDelete(theHTE);
	AdjustScrollbars(theDocument, false);
	DrawPageExtras(theDocument);
	theDocument->dirty = true;

	return noErr;
} /*DoDeleteEdit*/

void RecalcFontInfo(TEHandle te)
{
	TEPtr		t;
	short		oldFont;
	short		oldSize;
	FontInfo	info;

	HLock((Handle) te);

	t 			= *te;
	oldFont	=	t->inPort->txFont;
	oldSize	=	t->inPort->txSize;

	SetPort(t->inPort);
	TextFont(t->txFont);
	TextSize(t->txSize);
	GetFontInfo(&info);
	TextFont(oldFont);
	TextSize(oldSize);

	t->lineHeight	=	info.ascent+info.descent+info.leading;
	t->fontAscent	=	info.ascent;
	InvalRect(&t->viewRect);
	HUnlock((Handle) te);

	TECalText(te);
}

/* -----------------------------------------------------------------------
		Name: 		SetWindowProperty
		Purpose:		Sets the window property specified in theWindowPropToken to
						be that supplied in dataDesc.
	 -----------------------------------------------------------------------**/

pascal OSErr SetMyWindowProperty(const AEDesc *theWPTokenDesc, const AEDesc *dataDesc)
{
  	Str255          name;
	DPtr            theDocument;
	short				 size;
	short				 font;
	OSErr           err;
	OSErr           ignoreErr;
	Rect            thePosnRect;
	Boolean         theBoolean;
	TEHandle        theHTE;
	GrafPtr         oldPort;
	Point           thePosn;
	THPrint         theTHPrint;
	windowPropToken theWindowPropToken;
	AEDesc          newDesc;
	AEDesc          tokenDesc;
	Size            tokenSize;
	TextToken       myTextToken;
	short           hOffset;
	short           vOffset;

	if (err = AECoerceDesc(theWPTokenDesc, typeMyWindowProp, &newDesc))
		return err;

	GetRawDataFromDescriptor(
		&newDesc,
		(Ptr)&theWindowPropToken,
		sizeof(theWindowPropToken),
		&tokenSize);

	err = AEDisposeDesc(&newDesc);

	GetPort(&oldPort);
	SetPort(theWindowPropToken.tokenWindowToken);

	theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);

	switch (theWindowPropToken.tokenProperty) {
	case pName:
		err = GetPStringFromDescriptor(dataDesc, (char *)name);
		if (err==noErr)
			if (theDocument->kind != kDocumentWindow)
				return errAEEventNotHandled;
			else if (name[0] == 0)
				err = errAEWrongDataType;
			else {
				SetWTitle(theWindowPropToken.tokenWindowToken, name);
				PLstrcpy(theDocument->theFileName, name); /* Should we do this??? */
				theDocument->dirty = true;
			}
		break;

	case pText:
	case pContents:
		theHTE = theDocument->theText;
		TESetSelect(0, 32000, theHTE);

		if (theDocument->kind != kDocumentWindow)
			if (!theDocument->u.cons.selected || (*theHTE)->selStart < theDocument->u.cons.fence) {
				SysBeep(1);
			
				return errAEEventNotHandled;
			}
		
		TEDelete(theHTE);
		GetTextFromDescIntoTEHandle(dataDesc, theHTE);
		EnforceMemory(theDocument, theHTE);
		
		theDocument->dirty = true;
		break;

	case pBounds:
		err = GetRectFromDescriptor(dataDesc, &thePosnRect);
		/* the rectangle is for the structure region, and is in global coordinates */
		/* MoveWindow and SizeWindow apply to the content region, so we have to massage a little */

		thePosnRect.top    += (**((WindowPeek)theWindowPropToken.tokenWindowToken)->contRgn).rgnBBox.top -
									 (**((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn).rgnBBox.top;

		thePosnRect.left   += (**((WindowPeek)theWindowPropToken.tokenWindowToken)->contRgn).rgnBBox.left -
									 (**((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn).rgnBBox.left;

		thePosnRect.bottom += (**((WindowPeek)theWindowPropToken.tokenWindowToken)->contRgn).rgnBBox.bottom -
									 (**((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn).rgnBBox.bottom;

		thePosnRect.right  += (**((WindowPeek)theWindowPropToken.tokenWindowToken)->contRgn).rgnBBox.right -
									 (**((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn).rgnBBox.right;

		if (EmptyRect(&thePosnRect))
			err = errAECorruptData;
		else {
			MoveWindow(
				theWindowPropToken.tokenWindowToken,
				thePosnRect.left,
				thePosnRect.top,
				false);
			SizeWindow(
				theWindowPropToken.tokenWindowToken,
				thePosnRect.right- thePosnRect.left,
				thePosnRect.bottom-thePosnRect.top,
				true);
			ResizeMyWindow(theDocument);
		}
		break;

	case pPosition:
		err = GetPointFromDescriptor(dataDesc, &thePosn);
		/* the point is for the structure region, and is in global coordinates */
		/* MoveWindow applies to the content region, so we have to massage a little */

		hOffset = (**((WindowPeek)theWindowPropToken.tokenWindowToken)->contRgn).rgnBBox.left -
					 (**((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn).rgnBBox.left;

		vOffset = (**((WindowPeek)theWindowPropToken.tokenWindowToken)->contRgn).rgnBBox.top -
					 (**((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn).rgnBBox.top;

		thePosn.v  += vOffset;
		thePosn.h  += hOffset;

		MoveWindow(
			theWindowPropToken.tokenWindowToken,
			thePosn.h,
			thePosn.v,
			false);

		ResizeMyWindow(theDocument);
		break;

	case pIsZoomed:
		err = GetBooleanFromDescriptor(dataDesc, &theBoolean);
		if (theBoolean)
			ZoomWindow(qd.thePort, inZoomOut, false);
		else
			ZoomWindow(qd.thePort, inZoomIn, false);

		ResizeMyWindow(theDocument);
		break;

	case pVisible:
		err = GetBooleanFromDescriptor(dataDesc, &theBoolean);
		if (theBoolean)
			DoShowWindow(theWindowPropToken.tokenWindowToken);
		else
			DoHideWindow(theWindowPropToken.tokenWindowToken);
		break;

	case pPageSetup:
		err = GetTHPrintFromDescriptor(dataDesc, &theTHPrint);

		if (theTHPrint) {
			if (theDocument->thePrintSetup)
				DisposeHandle((Handle)theDocument->thePrintSetup);

			theDocument->thePrintSetup = theTHPrint;

			ResizePageSetupForDocument(theDocument);
		}
		break;

	case pShowBorders:
		if (theDocument->kind != kDocumentWindow)
			return errAEEventNotHandled;
			
		err = GetBooleanFromDescriptor(dataDesc, &theBoolean);
		theDocument->u.reg.showBorders = theBoolean;
		if (theBoolean)
			DrawPageExtras(theDocument); /* Does the clipping as well as drawing borders/page breaks */
		else
			InvalidateDocument(theDocument);
		break;

	case pFont:
		err = GetPStringFromDescriptor(dataDesc, (char *)name);
		GetFNum(name, &font);
	
		(*theDocument->theText)->txFont = font;
		RecalcFontInfo(theDocument->theText);
		AdjustScrollbars(theDocument, false);
		DrawPageExtras(theDocument);
		
		if (theDocument->kind == kDocumentWindow)
			theDocument->dirty = true;
	
		if (theDocument->theWindow == FrontWindow() && !gInBackground)
			AdjustScript(theDocument);

		break;

	case pPointSize:
		err = GetIntegerFromDescriptor(dataDesc, &size);

		(*theDocument->theText)->txSize = size;
		RecalcFontInfo(theDocument->theText);
		AdjustScrollbars(theDocument, false);
		DrawPageExtras(theDocument);
		
		if (theDocument->kind == kDocumentWindow)
			theDocument->dirty = true;

		if (theDocument->theWindow == FrontWindow() && !gInBackground)
			AdjustScript(theDocument);

		break;

	case pSelection:
		err = AECoerceDesc(dataDesc, typeMyText, &tokenDesc);

		GetRawDataFromDescriptor(&tokenDesc,
														 (Ptr)&myTextToken,
														 sizeof(myTextToken),
														 &tokenSize);

		ignoreErr = AEDisposeDesc(&tokenDesc);

		if (err == noErr) {
			/* got a text token */

			theDocument = DPtrFromWindowPtr(myTextToken.tokenWindow);
			theHTE      = theDocument->theText;

			TESetSelect(
				myTextToken.tokenOffset-1,
				myTextToken.tokenOffset+myTextToken.tokenLength-1,
				theHTE);
		}
		break;

	case pIndex:
	case pIsModal:
	case pIsResizable:
	case pHasTitleBar:
	case pHasCloseBox:
	case pIsFloating:
	case pIsZoomable:
	case pIsModified:
		err = errAEEventNotHandled; /* We don't allow these to be set */
		break;
	}
	
	SetPort(oldPort);

	return err;
} /* SetWindowProperty */

/* -----------------------------------------------------------------------
		Name: 		SetTextProperty
		Purpose:		Sets the text property specfied by theTextPropToken to
						that in dataDesc.
	 -----------------------------------------------------------------------**/

pascal OSErr SetTextProperty(const AEDesc *tokenDesc, const AEDesc *dataDesc)
{
	TEHandle      theHTE;
	DPtr          theDoc;
	OSErr         myErr;
	textPropToken theTextPropToken;
	AEDesc        newDesc;
	Size          tokenSize;

	newDesc.dataHandle = nil;

	if (myErr = AECoerceDesc(tokenDesc, typeMyTextProp, &newDesc))
		return myErr;

	GetRawDataFromDescriptor(&newDesc, (Ptr)&theTextPropToken, sizeof(theTextPropToken), &tokenSize);
	myErr 			=	AEDisposeDesc(&newDesc);
	theDoc 			=	DPtrFromWindowPtr(theTextPropToken.propertyTextToken.tokenWindow);
	
	if (theDoc->kind == kDocumentWindow)
		theDoc->dirty 	=	true;

	switch (theTextPropToken.propertyProperty) {
	case pText:
	case pContents:
		theHTE = theDoc->theText;
		TESetSelect(
			theTextPropToken.propertyTextToken.tokenOffset-1,
			theTextPropToken.propertyTextToken.tokenOffset+theTextPropToken.propertyTextToken.tokenLength-1,
			theHTE);
		
		if (theDoc->kind != kDocumentWindow)
			if (!theDoc->u.cons.selected || (*theHTE)->selStart < theDoc->u.cons.fence) {
				SysBeep(1);
			
				return errAEEventNotHandled;
			}
		
		TEDelete(theHTE);
		myErr = GetTextFromDescIntoTEHandle(dataDesc, theHTE);
		EnforceMemory(theDoc, theHTE);
			
		theDoc->dirty = true;
		
		return myErr;
	}

	return errAEWrongDataType;
} /* SetTextProperty */

/* -----------------------------------------------------------------------
		Name: 		HandleSetData
		Purpose:		Resolves the object into a token (could be one of many) and
						the sets the data of that object to dataDesc.
	 -----------------------------------------------------------------------**/

pascal OSErr HandleSetData(const AEDesc *theObj, const AEDesc *dataDesc)
{
	OSErr           myErr;
	AEDesc          newDesc;
	DPtr            theDocument;
	TEHandle        theHTE;
	TextToken       theTextToken;
	Size            tokenSize;
	AEDesc          objTokenDesc;
	OSErr           ignoreErr;

	objTokenDesc.dataHandle = nil;
	newDesc.dataHandle      = nil;

	/*
		Coerce theObj into a token which we can use -
			 set the property or data for that token
	*/

	myErr = AEResolve(theObj ,kAEIDoMinimum, &objTokenDesc);

	/* We don't actually allow ANY app property setting, but
		just incase we'll decode looking for an typeMyApplProp and flag an error -
		 do same for menu related tokens
	*/

	if (
		(objTokenDesc.descriptorType == typeMyApplProp) ||
		(objTokenDesc.descriptorType == typeMyMenu    ) ||
		(objTokenDesc.descriptorType == typeMyMenuProp) ||
		(objTokenDesc.descriptorType == typeMyMenuItem) ||
		(objTokenDesc.descriptorType == typeMyItemProp)
	)
		myErr = errAEWrongDataType;
	else if (objTokenDesc.descriptorType == typeMyWindowProp)
		myErr = SetMyWindowProperty(&objTokenDesc, dataDesc);
	else if (objTokenDesc.descriptorType == typeMyTextProp)
		myErr = SetTextProperty(&objTokenDesc, dataDesc);
	else if (objTokenDesc.descriptorType == typeMyText)
		if (!AECoerceDesc(&objTokenDesc, typeMyText, &newDesc)) {
			GetRawDataFromDescriptor(&newDesc, (Ptr)&theTextToken, sizeof(theTextToken), &tokenSize);

			myErr 		= AEDisposeDesc(&newDesc);
			theDocument = DPtrFromWindowPtr(theTextToken.tokenWindow);
			theHTE		= theDocument->theText;

			TESetSelect(
				theTextToken.tokenOffset-1,
				theTextToken.tokenOffset+theTextToken.tokenLength-1,
				theHTE);
				
			if (theDocument->kind != kDocumentWindow)
				if (!theDocument->u.cons.selected || (*theHTE)->selStart < theDocument->u.cons.fence) {
					SysBeep(1);
				
					return errAEEventNotHandled;
				}
			
			TEDelete(theHTE);
			myErr = GetTextFromDescIntoTEHandle(dataDesc, theHTE);
			EnforceMemory(theDocument, theHTE);
				
			theDocument->dirty = true;
		}

	ignoreErr = AEDisposeDesc(&objTokenDesc);

	return myErr;
}	/* HandleSetData */

/*
	A few convenient FORWARDS...
*/

pascal OSErr MakeWindowObj(WindowPtr theWindow, AEDesc *dMyDoc);

/*
	Back to real code
*/
pascal OSErr MakeSelTextObj(WindowPtr theWindow, TEHandle theTextEditHandle, AEDesc *selTextObj)
{
	OSErr    myErr;
	OSErr    ignoreErr;
	AEDesc   dNull;
	AEDesc   dMyDoc;
	AEDesc   startOfs;
	AEDesc   endOfs;
	AEDesc   startObj;
	AEDesc   endObj;
	AEDesc   rangeDesc;
	long     startChar;
	long     endChar;
	Boolean  spotFlag;

	myErr = noErr;

	if (theWindow==nil)
		return noErr;

	selTextObj->dataHandle = nil;
	dMyDoc.dataHandle      = nil;
	startObj.dataHandle    = nil;
	endObj.dataHandle      = nil;

	/*
		make the window object
	*/

	if (myErr = MakeWindowObj(theWindow, &dMyDoc))
		return myErr;

	/* get the start and end of selection */

	startChar = (*theTextEditHandle)->selStart+1;	/* start counting obj's from 1, not 0 */
	endChar   = (*theTextEditHandle)->selEnd;
	spotFlag  = ((*theTextEditHandle)->selStart == (*theTextEditHandle)->selEnd);

	if (myErr = CreateOffsetDescriptor(startChar, &startOfs))
		return myErr;

	if (spotFlag)
		myErr = CreateObjSpecifier(cSpot, &dMyDoc, formAbsolutePosition, &startOfs, true, selTextObj);
	else {
		/* not a spot - must represent as range */
		/* make obj for start char */

		myErr = AECreateDesc(typeNull, nil , 0, &dNull);

		myErr = CreateObjSpecifier(cChar, &dMyDoc, formAbsolutePosition, &startOfs, false, &startObj);

		if (myErr==noErr)
			myErr = CreateOffsetDescriptor(endChar, &endOfs);

		if (myErr==noErr)
			myErr = CreateObjSpecifier(cChar, &dMyDoc, formAbsolutePosition, &endOfs, false, &endObj);

		if (myErr==noErr)
			myErr = CreateRangeDescriptor(&startObj, &endObj, false, &rangeDesc);

		if (myErr==noErr)
			myErr = CreateObjSpecifier(cText, &dMyDoc, formRange, &rangeDesc, true, selTextObj);

		if (startObj.dataHandle)
		  ignoreErr = AEDisposeDesc(&startObj);

		if (startOfs.dataHandle)
		  ignoreErr = AEDisposeDesc(&startOfs);

		if (endObj.dataHandle)
		  ignoreErr = AEDisposeDesc(&endObj);

		if (endOfs.dataHandle)
		  ignoreErr = AEDisposeDesc(&endOfs);
	}

	return myErr;
}	/* MakeSelTextObj */

/* -----------------------------------------------------------------------
		Name: 			DoSetData
		Purpose:		Handles the SetData Apple Event, extracting the direct
								object (which says what to set) and the data (what to set
								it to).
	 -----------------------------------------------------------------------**/

pascal OSErr DoSetData(const AppleEvent *theAppleEvent, AppleEvent *reply, long handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply, handlerRefCon)
#endif

	OSErr  myErr;
	OSErr  ignoreErr;
	AEDesc myDirObj;
	AEDesc myDataDesc;

	myDataDesc.dataHandle = nil;
	myDirObj.dataHandle   = nil;

	/* pick up the direct object, which is the object whose data is to be set */

	myErr = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObj);

	/* now the data to set it to - typeWildCard means get as is*/
	if (myErr == noErr)
		myErr = AEGetParamDesc(theAppleEvent, keyAEData, typeWildCard, &myDataDesc);

	/* missing any parameters? */
	if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

	/* set the data */
	if (myErr == noErr)
		myErr = HandleSetData(&myDirObj, &myDataDesc);

	if (myDataDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&myDataDesc);

	if (myDirObj.dataHandle)
		ignoreErr = AEDisposeDesc(&myDirObj);

	return myErr;
}	/* DoSetData */

pascal OSErr BuildStyledTextDesc(TEHandle theHTE, short start, short howLong, AEDesc *resultDesc)
{
	AEDesc       listDesc;
	OSErr        myErr;
	OSErr        ignoreErr;

	listDesc.dataHandle = nil;

	TESetSelect(start-1, start+howLong-2, theHTE);

	myErr = AECreateList(nil, 0, true,  &listDesc);

	HLock((Handle)(**theHTE).hText);

	if (myErr==noErr)
		myErr = AEPutKeyPtr(&listDesc,
								  keyAEText,
												typeChar,
												(Ptr)&(*(**theHTE).hText)[start-1],
												howLong);

	HUnlock((Handle)(**theHTE).hText);

	myErr = AEPutKeyPtr(&listDesc, keyAEStyles, typeScrapStyles, (Ptr)nil, 0);

	if (myErr==noErr)
		myErr = AECoerceDesc(&listDesc, typeStyledText, resultDesc); // should be typeIntlText

	if (listDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&listDesc);

	return myErr;
}

/* -----------------------------------------------------------------------
		Name: 			GetTextProperty
		Purpose:		Fills dataDesc with the requested text property.
	 -----------------------------------------------------------------------**/

pascal OSErr GetTextProperty(const AEDesc *theTokenDesc, AEDesc *dataDesc)
{
  	DPtr          theDocument;
	TEHandle      theHTE;
	short         theSize;
	GrafPtr       oldPort;
	textPropToken theTextPropToken;
	OSErr         myErr;
	Size          tokenSize;
	AEDesc        newDesc;

  	if (myErr = AECoerceDesc(theTokenDesc, typeMyTextProp, &newDesc))
		return myErr;

	GetRawDataFromDescriptor(&newDesc, (Ptr)&theTextPropToken, sizeof(theTextPropToken), &tokenSize);
	myErr= AEDisposeDesc(&newDesc);

	/*
		For each property we build a descriptor to be returned as the reply.
	*/

	theDocument = DPtrFromWindowPtr(theTextPropToken.propertyTextToken.tokenWindow);
	theHTE 		= theDocument->theText;

	switch (theTextPropToken.propertyProperty) {
	case pText:
	case pContents:
		return BuildStyledTextDesc(
						theHTE,
						theTextPropToken.propertyTextToken.tokenOffset,
						theTextPropToken.propertyTextToken.tokenLength,
						dataDesc);
	case pStringWidth:
		GetPort(&oldPort);
		SetPort(theTextPropToken.propertyTextToken.tokenWindow);

		HLock((Handle)(*theHTE)->hText);
		theSize =
			TextWidth(
				&(*theHTE)->hText,
				theTextPropToken.propertyTextToken.tokenOffset-1,
				theTextPropToken.propertyTextToken.tokenLength);
		HUnlock((Handle)(*theHTE)->hText);

		SetPort(oldPort);
		return CreateOffsetDescriptor(theSize, dataDesc);
	default:
		return errAEEventNotHandled;
	}
} /*GetTextProperty*/

/* -----------------------------------------------------------------------
		Name: 		GetMyWindowProperty
		Purpose:		Fills dataDesc with the requested window property.
	 -----------------------------------------------------------------------**/
typedef Rect **RectHandle;

pascal OSErr GetMyWindowProperty(const AEDesc *theWPTokenObj, AEDesc *dataDesc)
{
 	OSErr           theErr;
	Str255          theName;
	Boolean         theBoolean;
	Rect            theRect;
	Point           thePoint;
	Rect            winRect;
	Rect            userRect;
	short           theIndex;
	DPtr            theDocument;
	TEHandle        theHTE;
	windowPropToken theWindowPropToken;
	AEDesc          newDesc;
	Size            tokenSize;

  	if (theErr = AECoerceDesc(theWPTokenObj,typeMyWindowProp, &newDesc))
  		return theErr;

	GetRawDataFromDescriptor(
		&newDesc,
		(Ptr)&theWindowPropToken,
		sizeof(theWindowPropToken),
		&tokenSize);

	theErr = AEDisposeDesc(&newDesc);

	theErr = kAEGenericErr;

	switch (theWindowPropToken.tokenProperty) {
	case pName:
		GetWTitle(theWindowPropToken.tokenWindowToken, theName);

		theErr = AECreateDesc(typeChar, (Ptr)&theName[1], theName[0], dataDesc);
		break;
	case pText:
	case pContents:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theHTE      = theDocument->theText;
		theErr 		= BuildStyledTextDesc(theHTE, 1, (**theHTE).teLength, dataDesc);
		break;
	case pBounds:
		SetPort(theWindowPropToken.tokenWindowToken);

		theRect = (*((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn)->rgnBBox;
		theErr  = AECreateDesc(typeQDRectangle, (Ptr)&theRect, sizeof(theRect), dataDesc);
		break;
	case pPosition:
		thePoint.v 	= (*((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn)->rgnBBox.top;
		thePoint.h 	= (*((WindowPeek)theWindowPropToken.tokenWindowToken)->strucRgn)->rgnBBox.left;
		theErr   	= AECreateDesc(typeQDPoint, (Ptr)&thePoint, sizeof(thePoint), dataDesc);
		break;
	case pVisible:
		theBoolean 	= ((WindowPeek)theWindowPropToken.tokenWindowToken)->visible;
		theErr  		= AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
		break;
	case pIsModal:
		theBoolean 	= false;
		theErr  		= AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
		break;
	case pShowBorders:
		theDocument	= DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theBoolean	= (theDocument->kind == kDocumentWindow) ? theDocument->u.reg.showBorders : false;
		theErr  		= AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
		break;
	case pIsZoomed:
		if (((WindowPeek)theWindowPropToken.tokenWindowToken)->spareFlag) {
			SetPort(theWindowPropToken.tokenWindowToken);

			userRect = **((RectHandle)((WindowPeek)qd.thePort)->dataHandle);
			winRect  = qd.thePort->portRect;
			LocalToGlobal((Point *)&winRect.top);
			LocalToGlobal((Point *)&winRect.bottom);

			theBoolean = !EqualRect(&userRect, &winRect);
		} else
			theBoolean = false;

		theErr  = AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
		break;
	case pIsResizable:
	case pHasTitleBar:
	case pIsZoomable:
	case pHasCloseBox:
		theBoolean 	= true;
		theErr  		= AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
		break;
	case pIsFloating:
		theBoolean 	= false;
		theErr  		= AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
		break;
	case pIsModified:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theBoolean  = (theDocument->kind == kDocumentWindow) ? theDocument->dirty : true;
		theErr  		= AECreateDesc(typeBoolean, (Ptr)&theBoolean, sizeof(theBoolean), dataDesc);
	case pIndex:
		theIndex = 0;
		if (theWindowPropToken.tokenWindowToken)
			do
				theIndex++;
			while (theWindowPropToken.tokenWindowToken != GetWindowPtrOfNthWindow(theIndex));
		theErr  = AECreateDesc(typeShortInteger, (Ptr)theIndex, sizeof(theIndex), dataDesc);
		break;
	case pPageSetup:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);

		HLock((Handle)theDocument->thePrintSetup);
		theErr  = AECreateDesc(typeTPrint, (Ptr)*(theDocument->thePrintSetup), sizeof(TPrint), dataDesc);
		HUnlock((Handle)theDocument->thePrintSetup);
		
		break;
	case pSelection:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theErr  		= MakeSelTextObj(theWindowPropToken.tokenWindowToken, theDocument->theText, dataDesc);
		break;
	case pFont:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		
		GetFontName((*theDocument->theText)->txFont, theName);

		theErr = AECreateDesc(typeChar, (Ptr)&theName[1], theName[0], dataDesc);
		break; 
	case pPointSize:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theErr 		= CreateOffsetDescriptor((*theDocument->theText)->txSize, dataDesc);
		break;
	case pScriptTag:
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theErr 		= CreateOffsetDescriptor(FontToScript((*theDocument->theText)->txFont), dataDesc);
		break;
	}

	return theErr;
} /* GetMyWindowProperty */

/** -----------------------------------------------------------------------
		Name: 			GetApplicationProperty
		Purpose:		Fills dataDesc with the requested application property.
	 -----------------------------------------------------------------------**/

pascal OSErr GetApplicationProperty(const AEDesc *theObjToken, AEDesc *dataDesc)
{
  	OSErr         	theErr;
	Str255        	theName;
	Boolean       	isFront;
	applPropToken 	theApplPropToken;
	AEDesc        	newDesc;
	Size          	tokenSize;
	AEStream			aes;
	Handle			scrap;
	VersRecHndl		vers;

	if (theErr = AECoerceDesc(theObjToken, typeMyApplProp, &newDesc))
		return theErr;

	GetRawDataFromDescriptor(&newDesc, (Ptr)&theApplPropToken, sizeof(theApplPropToken), &tokenSize);

	theErr = AEDisposeDesc(&newDesc);
	theErr = kAEGenericErr;

	switch (theApplPropToken.tokenApplProperty) {
	case pName:
		PLstrcpy((StringPtr)theName, (StringPtr) "\pMacPerl");
		theErr  = AECreateDesc(typeChar, (Ptr)&theName[1], theName[0], dataDesc);
		break;
	case pVersion:
		vers = (VersRecHndl) GetAppResource('vers', 1);
		HLock((Handle) vers);
		PLstrcpy((StringPtr)theName, (*vers)->shortVersion);
		ReleaseResource((Handle) vers);
		theErr  = AECreateDesc(typeChar, (Ptr)&theName[1], theName[0], dataDesc);
		break;
	case pIsFrontProcess:
		isFront = !gInBackground;
		theErr  = AECreateDesc(typeBoolean, (Ptr)&isFront, sizeof(isFront), dataDesc);
		break;
	case pClipboard:
		if (theErr = AEStream_Open(&aes))
			break;
		if (theErr = AEStream_OpenList(&aes))
			goto abortClipboard;
		TEFromScrap();
		scrap = TEScrapHandle();
		HLock(scrap);
		theErr = AEStream_WriteDesc(&aes, typeChar, *scrap, GetHandleSize(scrap));
		HLock(scrap);
		if (theErr || (theErr = AEStream_CloseList(&aes)))
			goto abortClipboard;
		theErr = AEStream_Close(&aes, dataDesc);
		break;
abortClipboard:
		AEStream_Close(&aes, nil);
		break;
	}
	
	return theErr;
} /* GetApplicationProperty */

/** -----------------------------------------------------------------------
		Name: 			GetMenuProperty
		Purpose:		Fills dataDesc with the requested menu property.
	 -----------------------------------------------------------------------**/

pascal OSErr GetMenuProperty(const AEDesc *theObjToken, AEDesc *dataDesc)
{
  	OSErr         theErr;
	Str255        theName;
	MenuPropToken theMenuPropToken;
	AEDesc        newDesc;
	Size          tokenSize;

	if (theErr = AECoerceDesc(theObjToken, typeMyMenuProp, &newDesc))
		return theErr;

	GetRawDataFromDescriptor(&newDesc, (Ptr)&theMenuPropToken, sizeof(theMenuPropToken), &tokenSize);

	theErr = AEDisposeDesc(&newDesc);
	theErr = kAEGenericErr;

	if (theMenuPropToken.theMenuProp == pName)  {
	  	PLstrcpy(theName, (**theMenuPropToken.theMenuToken.theTokenMenu).menuData);
		theErr  = AECreateDesc(typeChar, (Ptr)&theName[1], theName[0], dataDesc);
	}

	if (theMenuPropToken.theMenuProp == pMenuID) {
		theErr  =
			AECreateDesc(
				typeShortInteger,
				(Ptr)&theMenuPropToken.theMenuToken.theTokenID,
				sizeof(theMenuPropToken.theMenuToken.theTokenID),
				dataDesc);
	}

	return theErr;
} /* GetMenuProperty */

/** -----------------------------------------------------------------------
		Name: 		GetMyMenuItemProperty
		Purpose:		Fills dataDesc with the requested menu property.
	 -----------------------------------------------------------------------**/

pascal OSErr GetMyMenuItemProperty(const AEDesc *theObjToken, AEDesc *dataDesc)
{
  	OSErr             theErr;
	Str255            theName;
	MenuItemPropToken theMenuItemPropToken;
	AEDesc            newDesc;
	Size              tokenSize;

	if (theErr = AECoerceDesc(theObjToken, typeMyItemProp, &newDesc))
		return theErr;

	GetRawDataFromDescriptor(&newDesc, (Ptr)&theMenuItemPropToken, sizeof(theMenuItemPropToken), &tokenSize);

	theErr = AEDisposeDesc(&newDesc);
	theErr = kAEGenericErr;

	if (theMenuItemPropToken.theItemProp == pName) {
	  	GetMenuItemText(
			theMenuItemPropToken.theItemToken.theMenuToken.theTokenMenu,
			theMenuItemPropToken.theItemToken.theTokenItem,
			theName);
		theErr  = AECreateDesc(typeChar, (Ptr)&theName[1], theName[0], dataDesc);
	}

	if (theMenuItemPropToken.theItemProp == pItemNumber) {
		theErr  =
			AECreateDesc(
				typeShortInteger,
				(Ptr)&theMenuItemPropToken.theItemToken.theTokenItem,
				sizeof(theMenuItemPropToken.theItemToken.theTokenItem),
				dataDesc);
	}

	return theErr;
} /* GetMyMenuItemProperty */

/** -----------------------------------------------------------------------
		Name: 		HandleGetData
		Purpose:		Coerces theObj into a token which we understand and
						extracts the data requested in the token and puts it
						into dataDesc.
	 -----------------------------------------------------------------------**/

typedef char chars[32001];
typedef chars **charsHandle;

pascal OSErr HandleGetData(AEDesc *theObj, DescType whatType, AEDesc *dataDesc)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (whatType)
#endif

  	OSErr           myErr;
	AEDesc          newDesc;
	TextToken       theTextToken;
	Size            tokenSize;
	DPtr            theDoc;
	AEDesc          objTokenDesc;

	myErr = errAEWrongDataType;

	/*
		Coerce theObj into a token which we can use -
			 set the property for that token
	*/


	if (myErr = AEResolve(theObj, kAEIDoMinimum, &objTokenDesc))
		return myErr;

	switch (objTokenDesc.descriptorType) {
	case typeMyApplProp:
		myErr = GetApplicationProperty(&objTokenDesc, dataDesc);
		break;
	case typeMyMenuProp:
		myErr = GetMenuProperty(&objTokenDesc, dataDesc);
		break;
	case typeMyItemProp:
		myErr = GetMyMenuItemProperty(&objTokenDesc, dataDesc);
		break;
	case typeMyTextProp:
		myErr = GetTextProperty(&objTokenDesc, dataDesc);
		break;
	case typeMyWindowProp:
		myErr = GetMyWindowProperty(&objTokenDesc, dataDesc);
		break;
	case typeMyText:
		if (!AECoerceDesc(&objTokenDesc, typeMyText, &newDesc)) {
			GetRawDataFromDescriptor(
				&newDesc,
				(Ptr)&theTextToken,
				sizeof(theTextToken),
				&tokenSize);

			myErr 	= AEDisposeDesc(&newDesc);

			theDoc	= DPtrFromWindowPtr(theTextToken.tokenWindow);

			myErr 	=
				BuildStyledTextDesc(
					theDoc->theText,
					theTextToken.tokenOffset,
					theTextToken.tokenLength,
					dataDesc);
		break;
		}
	}

	return myErr;
}	/* HandleGetData */

/** -----------------------------------------------------------------------
		Name: 		DoGetData
		Purpose:		Handles the GetData AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr DoGetData(
	const AppleEvent *theAppleEvent,
	AppleEvent *reply,
	long handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (handlerRefCon)
#endif

	OSErr    myErr;
	OSErr    tempErr;
	AEDesc   myDirObj;
	AEDesc   myDataDesc;
	Size     actualSize;
	DescType returnedType;
	DescType reqType;

	myDataDesc.dataHandle = nil;
	myDirObj.dataHandle   = nil;

	/*
		extract the direct object, which is the object whose data is to be returned
	*/

	myErr  = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObj);

	/*
		now the get the type of data wanted - optional
	*/

	tempErr =
		AEGetParamPtr(
			theAppleEvent,
			keyAERequestedType,
			typeType,
			&returnedType,
			(Ptr)&reqType,
			sizeof(reqType),
			&actualSize);

	if (tempErr!=noErr)
		reqType = typeChar;

	if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

	/* get the data */
	if (myErr == noErr)
		myErr = HandleGetData(&myDirObj, reqType, &myDataDesc);

	/* if they wanted a reply, attach it now */
	if (myErr==noErr)
		if (reply->descriptorType != typeNull)
			myErr = AEPutParamDesc(reply, keyDirectObject, &myDataDesc);

 	if (myDataDesc.dataHandle)
	  	tempErr = AEDisposeDesc(&myDataDesc);

 	if (myDirObj.dataHandle)
	  	tempErr = AEDisposeDesc(&myDirObj);

	return myErr;
}	/* DoGetData */


/** -----------------------------------------------------------------------
		Name: 		DoGetDataSize
		Purpose:		Handles the GetDataSize AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr DoGetDataSize(
	const AppleEvent *theAppleEvent,
	AppleEvent *reply,
	long       handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (handlerRefCon)
#endif

	OSErr     myErr;
	OSErr     tempErr;
	AEDesc    myDirObj;
	AEDesc    myDataDesc;
	Size      actualSize;
	DescType  returnedType;
	DescType  reqType;
	long      dataSize;

	myDataDesc.dataHandle = nil;
	myDirObj.dataHandle = nil;

	/* pick up the direct object, which is the object whose data is to be sized */

	myErr  = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObj);

	/* now the get the type wanted - optional*/

	tempErr =
		AEGetParamPtr(
			theAppleEvent,
			keyAERequestedType,
			typeType,
			&returnedType,
			(Ptr)&reqType,
			sizeof(reqType),
			&actualSize);

	if (tempErr!=noErr)
		reqType = typeChar;

	if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

	/* get the data */
	if (myErr == noErr)
		myErr = HandleGetData(&myDirObj, reqType, &myDataDesc);

	/* evaluate size of data and discard, create desc for size */
	if (myErr == noErr)
		if (myDataDesc.dataHandle) {
			dataSize = GetHandleSize((Handle)myDataDesc.dataHandle);
			DisposeHandle((Handle)myDataDesc.dataHandle);
			myErr  = AECreateDesc(typeLongInteger, (Ptr)&dataSize, sizeof(dataSize), &myDataDesc);
		}


	/* if they wanted a reply, attach it now */

	if (myErr==noErr)
		if (reply->descriptorType != typeNull)
			myErr = AEPutParamDesc(reply, keyDirectObject, &myDataDesc);

	/* discard our copy */

	if (myDataDesc.dataHandle)
		tempErr = AEDisposeDesc(&myDataDesc);

	if (myDirObj.dataHandle)
		tempErr = AEDisposeDesc(&myDirObj);

	return myErr;
}	/* DoGetDataSize */

/** -----------------------------------------------------------------------
		Name: 		DoNewElement
		Purpose:		Handles the NewElement AppleEvent. Only Creates windows for
		            now.
	 -----------------------------------------------------------------------**/

pascal OSErr DoNewElement(
	const AppleEvent *theAppleEvent,
	AppleEvent *reply,
	long       handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (handlerRefCon)
#endif

	OSErr       myErr;
	OSErr       ignoreErr;
	DescType  	returnedType;
	DescType  	newElemClass;
	Size        actSize;
	AEDesc    	wndwObjSpec;
	DPtr        theDoc;

	wndwObjSpec.dataHandle = nil;

	myErr =
		AEGetParamPtr(
			theAppleEvent,
			keyAEObjectClass,
			typeType,
			&returnedType,
			(Ptr)&newElemClass,
			sizeof(newElemClass),
			&actSize);

  /* check for missing required parameters */

  if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

  /* got all required params */

  /* let's make sure container is the null desc */
  /* and they want a window */

  if (newElemClass != cWindow && newElemClass != cDocument)
    myErr = errAEWrongDataType;

  /* let's create a new window */

	if (myErr == noErr)
		theDoc = NewDocument(false, kDocumentWindow);

	if (myErr==noErr)
		if (theDoc == nil)
			myErr = -1700;
		else {
			DoShowWindow(theDoc->theWindow);
			theDoc->dirty = false;
			myErr = AEBuild(
						&wndwObjSpec, 
						"obj{want:type(@),form:'indx',seld:1,from:()}",
						sizeof(newElemClass), &newElemClass);
		}

	if (myErr == noErr)
		if (reply->descriptorType != typeNull)
			 myErr = AEPutParamDesc(reply, keyDirectObject, &wndwObjSpec);

	if (wndwObjSpec.dataHandle)
		ignoreErr = AEDisposeDesc(&wndwObjSpec);

  	return myErr;
}	/* DoNewElement */

/** -----------------------------------------------------------------------
		Name: 		DoIsThereA
		Purpose:		Handles the IsThereA AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr DoIsThereA(
	const AppleEvent *theAppleEvent,
	AppleEvent       *reply,
	long             handlerRefCon)
/*
	Support check of Windows at first

	What we do :
		Get Direct Object
		Check have all required params
		Coerce into things we support
		if we get something back
			check to see it exists and set reply
		clean up
		return
*/
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (handlerRefCon)
#endif

	OSErr         myErr;
	OSErr         ignoreErr;
	AEDesc        myDirObject;
	AEDesc        windDesc;
	AEDesc        dataDesc;
	WindowToken   theWindowToken;
	Size          tokenSize;
	Boolean       exists;

	myDirObject.dataHandle = nil;
	windDesc.dataHandle    = nil;
	dataDesc.dataHandle    = nil;

	myErr = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObject);

	/* check for missing required parameters */

	if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

	/* got all required params */

	/* let's make sure they want to check for a window */

	exists = false;

	if (myErr == noErr)
		if (AECoerceDesc(&myDirObject, typeMyWndw, &windDesc)==noErr)
			if (windDesc.descriptorType!=typeNull) {
				GetRawDataFromDescriptor(
					&windDesc,
					(Ptr)&theWindowToken,
					sizeof(theWindowToken),
					&tokenSize);

				exists = (theWindowToken != nil);
			}

	if (myErr == noErr)
		myErr = AECreateDesc(typeBoolean, (Ptr)&exists, sizeof(exists), &dataDesc);

	/*
		if they wanted a reply, which they surely must,
		attach the result to itÉ
	*/

	if (myErr == noErr)
		if (reply->descriptorType != typeNull)
			 myErr = AEPutParamDesc(reply, keyDirectObject, &dataDesc);

	if (dataDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&dataDesc);

	if (myDirObject.dataHandle)
		ignoreErr = AEDisposeDesc(&myDirObject);

	if (windDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&windDesc);

	return myErr;
}	/* DoIsThereA */

/** -----------------------------------------------------------------------
		Name: 		DoCloseWindow
		Purpose:		Handles the Close AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr DoCloseWindow(
	const AppleEvent *theAppleEvent,
	AppleEvent       *reply,
	long             handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply, handlerRefCon)
#endif

	OSErr         myErr;
	OSErr         tempErr;
	AEDesc        myDirObj;
	AEDesc        newDesc;
	WindowToken   theWindowToken;
	Size          tokenSize;
	DescType      saveOpt;
	Size          actSize;
	DescType      returnedType;
	DPtr          myDPtr;

	myDirObj.dataHandle = nil;

	/* pick up the direct object, which is the object (window) to close */

	myErr = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObj);

	/* pick up optional save param, if any */

	saveOpt = kAEAsk; /* the default */

	tempErr =
		AEGetParamPtr(
			theAppleEvent,
			keyAESaveOptions,
			typeEnumerated,
			&returnedType,
			(Ptr)&saveOpt,
			sizeof(saveOpt),
			&actSize);

	if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

	/* get the window to close as a window ptr */
	if (myErr == noErr)
		if (!AECoerceDesc(&myDirObj, typeMyWndw, &newDesc))
			if (newDesc.descriptorType!=typeNull)  {
				GetRawDataFromDescriptor(
					&newDesc,
					(Ptr)&theWindowToken,
					sizeof(theWindowToken),
					&tokenSize);

				myErr = AEDisposeDesc(&newDesc);

				if (theWindowToken) {
					myErr=AESetInteractionAllowed(kAEInteractWithAll); /* Should do this in prefs */

					/*
						We do some of the close checks here to avoid
						calling AEInteractWithUser
					*/
					if (!(myDPtr = DPtrFromWindowPtr(theWindowToken)))
						myErr =  errAEIllegalIndex;
					else if (myDPtr->kind == kDocumentWindow && (myDPtr->dirty || !myDPtr->u.reg.everSaved))
						if (saveOpt != kAENo) /* Don't flip layers if force no ask */
							myErr = AEInteractWithUser(kAEDefaultTimeout, nil, nil);

					if (myErr==noErr)
						myErr = DoClose(theWindowToken, true, saveOpt);
				} else
					myErr =  errAEIllegalIndex;
			}

	if (myDirObj.dataHandle)
		tempErr = AEDisposeDesc(&myDirObj);

	return myErr;
}	/* DoCloseWindow */

/** -----------------------------------------------------------------------
		Name: 			DoSaveWindow
		Purpose:		Handles the Save AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr DoSaveWindow(
	const AppleEvent *theAppleEvent,
	AppleEvent       *reply,
	long             handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply, handlerRefCon)
#endif

	OSErr         	myErr;
	OSErr         	tempErr;
	AEDesc        	myDirObj;
	AEDesc        	newDesc;
	WindowToken   	theWindowToken;
	Size          	tokenSize;
	Size          	actSize;
	DescType      	returnedType;
	DPtr          	theDoc;
	OSType			type;
	FSSpec        	destFSSpec;

	myDirObj.dataHandle = nil;

	/* pick up the direct object, which is the window to save */

	myErr = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard,  &myDirObj);

	/* pick up optional destination param, if any */

	tempErr =
		AEGetParamPtr(
			theAppleEvent,
			keyAEDestination,
		  	typeFSS,
			&returnedType,
			(Ptr)&destFSSpec,
			sizeof(destFSSpec),
			&actSize);

	if (AEGetParamPtr(
			theAppleEvent,
			keyAEFileType,
		  	typeEnumerated,
			&returnedType,
			(Ptr)&type,
			sizeof(type),
			&actSize)
		|| !CanSaveAs(type)
	)
		type = 0;
	
	if (myErr == noErr)
		myErr = GotRequiredParams(theAppleEvent);

	/* get the data */

	if (myErr = AECoerceDesc(&myDirObj, typeMyWndw, &newDesc))	{
		/* No window, maybe a file? */
		if (AECoerceDesc(&myDirObj, typeFSS, &newDesc)) {
			/* Apparently not, maybe just some text ? */
			if (!AECoerceDesc(&myDirObj, typeChar, &newDesc))
				myErr = Handle2File(newDesc.dataHandle, destFSSpec, type ? type : 'TEXT');
		} else {
			FSSpec	fromFile;
			DocType	oldType;
			
			GetRawDataFromDescriptor(
				&newDesc,
				(Ptr)&fromFile,
				sizeof(fromFile),
				&tokenSize);
				
			oldType = GetDocType(&fromFile);
			
			if (oldType == kUnknownDoc)
				myErr = errAEWrongDataType;
			else
				myErr = File2File(fromFile, oldType, destFSSpec, type ? type : oldType);
		}
	} else if (newDesc.descriptorType!=typeNull) {
		GetRawDataFromDescriptor(
			&newDesc,
			(Ptr)&theWindowToken,
			sizeof(theWindowToken),
			&tokenSize);

		myErr = AEDisposeDesc(&newDesc);

		if (theWindowToken) {
			theDoc = DPtrFromWindowPtr(theWindowToken);

			if (theDoc->kind != kDocumentWindow || theDoc->u.reg.everSaved == false)
				if (tempErr != noErr)
					 /* We had no supplied destination and no default either */
					myErr = kAEGenericErr;

			if (type)
				theDoc->type = type;
				
			if (myErr==noErr)
				if (tempErr==noErr)  /* we were told where */
					myErr = SaveWithoutTemp(theDoc, destFSSpec);
				else
					myErr = SaveUsingTemp(theDoc);
		} else
			myErr =  errAEIllegalIndex;
	}

	if (myDirObj.dataHandle)
		tempErr = AEDisposeDesc(&myDirObj);

	return myErr;
}	/* DoSaveWindow */

/** -----------------------------------------------------------------------
		Name: 		DoRevertWindow
		Purpose:		Handles the Revert AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr DoRevertWindow(
	const AppleEvent *theAppleEvent,
	AppleEvent       *reply,
	long             handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply, handlerRefCon)
#endif

	OSErr          myErr;
	OSErr          ignoreErr;
	AEDesc         myDirObj;
	AEDesc         newDesc;
	WindowToken    theWindowToken;
	Size           tokenSize;
	DPtr           theDoc;

	myDirObj.dataHandle = nil;

  /* pick up the direct object, which is the window to revert */

  	if (myErr = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObj))
  		return myErr;

  	GotRequiredParams(theAppleEvent);

  /* get the window to revert from the direct object */

	myErr = AECoerceDesc(&myDirObj, typeMyWndw, &newDesc);

  	if (myErr == noErr)
		if (newDesc.descriptorType!=typeNull) {
			GetRawDataFromDescriptor(
				&newDesc,
				(Ptr)&theWindowToken,
				sizeof(theWindowToken),
				&tokenSize);

			myErr = AEDisposeDesc(&newDesc);

			if (theWindowToken) {
				theDoc = DPtrFromWindowPtr(theWindowToken);

				if (theDoc->kind != kDocumentWindow)
					myErr = errAEEventNotHandled;
				else {
					HidePen();
					TESetSelect(0, (*(theDoc->theText))->teLength, theDoc->theText);
					ShowPen();
					TEDelete(theDoc->theText);
	
					if (theDoc->u.reg.everSaved) {
						myErr = GetFileContents(theDoc->theFSSpec, theDoc);
						if (myErr == noErr) {
							ResizeMyWindow(theDoc);
							theDoc->dirty = false;
						}
					}
	
					DoShowWindow(theDoc->theWindow); /* <<< Visible already??? */
					DoUpdate(theDoc, theDoc->theWindow);
				}
			} else
				myErr =  errAEIllegalIndex;
		}

	if (myDirObj.dataHandle)
		ignoreErr = AEDisposeDesc(&myDirObj);

  return myErr;
}	/* DoRevertWindow */

/**-----------------------------------------------------------------------
		Name: 		DoPrintDocuments
		Purpose:		Print a list of documents (or windows).
-----------------------------------------------------------------------**/
pascal OSErr DoPrintDocuments(
	const AppleEvent *message,
   AppleEvent       *reply,
	long refcon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply, refcon)
#endif
	long          index;
	long          itemsInList;
	AEKeyword     keywd;
	OSErr         err;
	AEDescList    docList;
	Size          actSize;
	DescType      typeCode;
	FSSpec        theFSSpec;
	WindowToken   theWindowToken;
	OSErr         forgetErr;
	Boolean       talkToUser;

	err = AEGetParamDesc(message, keyDirectObject, typeAEList, &docList);
	err = AECountItems(&docList, &itemsInList);

	for (index = 1; index<=itemsInList; index++)
		if (err == noErr) {
			forgetErr =
				AEGetNthPtr(
					&docList,
					index,
					typeFSS,
					&keywd,
					&typeCode,
					(Ptr)&theFSSpec,
					sizeof(theFSSpec),
					&actSize);

			if (forgetErr == noErr) {
				if (err == noErr)
					err = IssueAEOpenDoc(theFSSpec);

				if (err == noErr)
					IssuePrintWindow(FrontWindow());

				if (err == noErr)
					IssueCloseCommand(FrontWindow());
			} else { /* wasn't a file - was it a window ? */
				err =
					AEGetNthPtr(
						&docList,
						index,
						typeMyWndw,
						&keywd,
						&typeCode,
						(Ptr)&theWindowToken,
						sizeof(WindowToken),
						&actSize);

				talkToUser = (AEInteractWithUser(kAEDefaultTimeout, nil, nil) == noErr);

				if (err == noErr)
					PrintWindow(DPtrFromWindowPtr(theWindowToken), talkToUser);
			}
		}

	if (docList.dataHandle)
		forgetErr = AEDisposeDesc(&docList);

	return err;
} /* DoPrintDocuments */

pascal OSErr MyCountProc(
	DescType desiredType,
	DescType containerClass,
	const AEDesc *container,
	long *result);

/** -----------------------------------------------------------------------
		Name:       HandleNumberOfElements
		Purpose:		Handles the Number Of Elements AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr HandleNumberOfElements(
	const AppleEvent *theAppleEvent,
	AppleEvent *reply,
	long       handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (handlerRefCon)
#endif

  	OSErr    myErr;
  	OSErr    forgetErr;
	AEDesc   myDirObj;
	DescType myClass;
	long     myCount;
	DescType returnedType;
	Size     actSize;

	myErr						= errAEEventNotHandled;
	myDirObj.dataHandle 	= nil;

	/* pick up direct object, which is the container in which things are to be counted */

	myErr = AEGetParamDesc(theAppleEvent, keyDirectObject, typeWildCard, &myDirObj);

	/* now the class of objects to be counted */

	myErr =
		AEGetParamPtr(
			theAppleEvent,
			keyAEObjectClass,
			typeType,
			&returnedType,
			(Ptr)&myClass,
			sizeof(myClass),
			&actSize);

	/* missing any parameters? */

	myErr = GotRequiredParams(theAppleEvent);

	/* now count */

	if (myErr == noErr)
		myErr = MyCountProc(myClass,myDirObj.descriptorType, &myDirObj,&myCount);

	/* add result to reply */

	if (myErr == noErr)
		if (reply->descriptorType != typeNull)
			 myErr  =
			 	AEPutParamPtr(
					reply,
					keyDirectObject,
					typeLongInteger,
					(Ptr)&myCount,
					sizeof(myCount));
	if (myErr == noErr)
		forgetErr  = AEDisposeDesc(&myDirObj);

	return myErr;
}	/* HandleNumberOfElements */

/** -----------------------------------------------------------------------
		Name: 			HandleShowSelection
		Purpose:		Handles the Make Selection Visible AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr HandleShowSelection(
	const AppleEvent *theAppleEvent,
	AppleEvent       *reply,
	long             handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,handlerRefCon)
#endif

	OSErr       myErr;
	OSErr       ignoreErr;
	AEDesc      myDirObj;
	AEDesc      newDesc;
	AEDesc      tokenDesc;
	Size        actSize;
	WindowToken theWindowToken;
	DPtr        theDocument;
	TEHandle    theHTE;

	myErr 	 = errAEEventNotHandled;
	myDirObj.dataHandle  = nil;
	tokenDesc.dataHandle = nil;

	/*
		pick up direct object, i.e. the window in which to show the selection
	*/

	myErr  =
		AEGetParamDesc(
			theAppleEvent,
			keyDirectObject,
			typeWildCard,
			&myDirObj);

	/*
		missing any parameters?
	*/

	myErr = GotRequiredParams(theAppleEvent);

	/*
		convert object to WindowToken which we understand
	*/
	myErr = AEResolve(&myDirObj, kAEIDoMinimum, &tokenDesc);

	if (myErr == noErr)
		if (tokenDesc.descriptorType==typeMyWndw) {
			if (AECoerceDesc(&myDirObj, typeMyWndw, &newDesc) == noErr) {
				GetRawDataFromDescriptor(
					&newDesc,
					(Ptr)&theWindowToken,
					sizeof(theWindowToken),
					&actSize);

				ignoreErr = AEDisposeDesc(&newDesc);

				if (myErr==noErr)
					if (theWindowToken)
						ShowSelect(DPtrFromWindowPtr(theWindowToken));
					else
						myErr = errAEIllegalIndex;
			}
		} else if (tokenDesc.descriptorType==typeMyText) {
			myErr =
				SetSelectionOfAppleEventObject(
					keyDirectObject,
					theAppleEvent,
					&theDocument,
					&theHTE);

			if (theDocument)
			  ShowSelect(theDocument);
			else
				myErr = errAEIllegalIndex;
		} else
			myErr = errAEEventNotHandled;

	if (myDirObj.dataHandle)
		ignoreErr = AEDisposeDesc(&myDirObj);

	if (tokenDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&tokenDesc);

	return myErr;
}	/* HandleShowSelection */

/** -----------------------------------------------------------------------
		Name: 		HandleSelect
		Purpose:		Handles the Select AppleEvent.
	 -----------------------------------------------------------------------**/

pascal OSErr HandleSelect(
	const AppleEvent *theAppleEvent,
	AppleEvent       *reply,
	long             handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,handlerRefCon)
#endif

	OSErr       myErr;
	OSErr       ignoreErr;
	AEDesc      myDirObj;
	AEDesc      tokenDesc;
	DPtr        theDocument;
	Size        actSize;
	TEHandle    theHTE;
	WindowToken theWindowToken;

	myErr 	 = errAEEventNotHandled;
	myDirObj.dataHandle  = nil;
	tokenDesc.dataHandle = nil;

	/*
		pick up direct object, i.e. the window in which to show the selection
	*/

	myErr  =
		AEGetParamDesc(
			theAppleEvent,
			keyDirectObject,
			typeWildCard,
			&myDirObj);

	/*
		missing any parameters?
	*/

	myErr = GotRequiredParams(theAppleEvent);

	/*
		convert object to WindowToken which we understand
	*/
	myErr = AEResolve(&myDirObj, kAEIDoMinimum, &tokenDesc);

	if (!myErr)
		switch (tokenDesc.descriptorType) {
		case typeMyWndw:
			GetRawDataFromDescriptor(
				&tokenDesc,
				(Ptr)&theWindowToken,
				sizeof(theWindowToken),
				&actSize);

			if (theWindowToken)
				SelectWindow(theWindowToken);
			else
				myErr = errAEIllegalIndex;
			
			break;
		case typeMyText:
			myErr =
				SetSelectionOfAppleEventObject(
					keyDirectObject,
					theAppleEvent,
					&theDocument,
					&theHTE);
			break;
		default:
			myErr = errAEEventNotHandled;
			break;
		}

	if (myDirObj.dataHandle)
		ignoreErr = AEDisposeDesc(&myDirObj);

	if (tokenDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&tokenDesc);

	return myErr;
}	/* HandleSelect */

pascal OSErr HandleStartRecording(
	const AppleEvent *theAppleEvent,
	AppleEvent *reply,
	long       handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (reply,handlerRefCon)
#endif

	OSErr myErr;

	gBigBrother++;

	myErr = GotRequiredParams(theAppleEvent);

	return myErr;

}	/* HandleStartRecording */

pascal OSErr HandleStopRecording(
	const AppleEvent *theAppleEvent,
	AppleEvent *reply,
	long handlerRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theAppleEvent,reply,handlerRefCon)
#endif

	gBigBrother--;
	return noErr;
}	/* HandleStopRecording */


#if !defined(powerc) && !defined(__powerc)
#pragma segment AECommandIssuers
#endif

/*******************************************************************************/
/*
		Start of section involved in building and sending AppleEvent Objects as/with
		commands
 */

/*
	Make an AEDesc that describes the selection in the window and text edit
	record supplied
*/

pascal OSErr MakeWindowObj(
	WindowPtr theWindow,
	AEDesc    *dMyDoc)
{
  	WindowPtr searchWindow;
	short		 index;
	
	searchWindow = (WindowPtr)LMGetWindowList();

	/* iterate through windows */

	for (index = 1; searchWindow; ++index)
		if (searchWindow == theWindow)
			break;
		else
			searchWindow = (WindowPtr)((WindowPeek)searchWindow)->nextWindow;

	if (searchWindow == theWindow) 
		return AEBuild(
					dMyDoc, 
					"obj{want: type('docu'), form: 'indx', seld: long(@), from: ()}",
/*					"obj{want:type('docu'),form:'indx',seld:long(@),from:()}", */ 
					(long) index);
	else {
		char   windowName[256];
		
		getwtitle(theWindow, windowName);
		
		return AEBuild(
					dMyDoc, 
/*					"obj{want: type('docu'), form: 'name', seld: TEXT(@), from: ()}", */
					"obj{want:type('docu'),form:'name',seld:TEXT(@),from:()}",
					windowName);
	}
} /*MakeWindowObj*/

pascal OSErr MakeTextObj(
	WindowPtr theWindow,
	short     selStart,
	short     selEnd,
	AEDesc    *selTextObj)
{
	OSErr    myErr;
	OSErr    ignoreErr;
	AEDesc   dMyDoc;
	AEDesc   startOfs;
	AEDesc   endOfs;
	AEDesc   startObj;
	AEDesc   endObj;
	AEDesc   rangeDesc;
	long     startChar;
	long     endChar;
	Boolean  spotFlag;

	myErr = noErr;

	if (theWindow==nil)
		return noErr;

	selTextObj->dataHandle = nil;
	dMyDoc.dataHandle      = nil;
	startObj.dataHandle    = nil;
	endObj.dataHandle      = nil;

	/*
		make the window object
	*/

	if (myErr = MakeWindowObj(theWindow, &dMyDoc))
		return myErr;

	/* get the start and end of selection */

	startChar = selStart+1;	/* start counting obj's from 1, not 0 */
	endChar   = selEnd;
	spotFlag  = (selStart == selEnd);

	if (myErr = CreateOffsetDescriptor(startChar, &startOfs))
		return noErr;

	if (spotFlag)
		myErr =
			CreateObjSpecifier(
				cSpot,
				&dMyDoc,
				formAbsolutePosition,
				&startOfs,
				true,
				selTextObj);
	else {
		/* not a spot - must represent as range */
		/* make obj for start char */

		myErr =
			CreateObjSpecifier(
				cChar,
				&dMyDoc,
				formAbsolutePosition,
				&startOfs,
				false,
				&startObj);

		if (myErr==noErr)
			myErr = CreateOffsetDescriptor(endChar, &endOfs);

		if (myErr==noErr)
			myErr =
				CreateObjSpecifier(
					cChar,
					&dMyDoc,
					formAbsolutePosition,
					&endOfs,
					false,
					&endObj);

		if (myErr==noErr)
			myErr = CreateRangeDescriptor(&startObj, &endObj, false, &rangeDesc);

		if (myErr==noErr)
			myErr = CreateObjSpecifier(cChar, &dMyDoc, formRange, &rangeDesc, true, selTextObj);

		if (startObj.dataHandle)
		  ignoreErr = AEDisposeDesc(&startObj);

		if (startOfs.dataHandle)
		  ignoreErr = AEDisposeDesc(&startOfs);

		if (endObj.dataHandle)
		  ignoreErr = AEDisposeDesc(&endObj);

		if (endOfs.dataHandle)
		  ignoreErr = AEDisposeDesc(&endOfs);
	}

	return myErr;
}

pascal OSErr MakeSelectedTextObj(
	WindowPtr theWindow,
	TEHandle  theTextEditHandle,
	AEDesc    *selTextObj)
{
	return
		MakeTextObj(
			theWindow,
			(**theTextEditHandle).selStart,
			(**theTextEditHandle).selEnd,
			selTextObj);

}	/* MakeSelectedTextObj */

enum editCommandType {
editCutCommand   = 1,
editCopyCommand  = 2,
editPasteCommand = 3,
editClearCommand = 4
};

typedef enum editCommandType editCommandType;

pascal void DoEditCommand(DPtr theDocument,editCommandType whatCommand)
{
  	OSErr         err;
  	OSErr         forgetErr;
	AEAddressDesc ourAddress;
	AppleEvent    editCommandEvent;
	AppleEvent    ignoreReply;
	AEDesc        ourTextSelObj;
	AEEventID     theEventID;
	AEEventClass  theEventClass;

	/*
			Initialise
	*/

	ourAddress.dataHandle 			= nil;
	ourTextSelObj.dataHandle 		= nil;
	editCommandEvent.dataHandle 	= nil;
	ignoreReply.dataHandle 			= nil;

	err = MakeSelfAddress(&ourAddress);

	if (err==noErr) {
		switch (whatCommand) {
		case  editCutCommand:
			theEventID    = kAECut;
			theEventClass = kAEMiscStandards;
			break;
		case  editCopyCommand:
			theEventID    = kAECopy;
			theEventClass = kAEMiscStandards;
			break;
		case  editPasteCommand:
			theEventID    = kAEPaste;
			theEventClass = kAEMiscStandards;
			break;
		case  editClearCommand:
			theEventID    = kAEDelete;
			theEventClass = kAECoreSuite;
			break;
		}

		err = AECreateAppleEvent( theEventClass, theEventID, &ourAddress, 0, 0, &editCommandEvent);

		if (!err && theDocument) {
			/* If it's one of our windows, build an object to represent the current 
			 * document's selection, although that seems to be in somewhat 
			 * questionable taste and not documented in the core suite.
			*/
			if (!MakeSelectedTextObj(theDocument->theWindow, theDocument->theText, &ourTextSelObj))
				AEPutParamDesc(&editCommandEvent, keyDirectObject, &ourTextSelObj);
		}

		/*and now Send the message*/
		if (err==noErr)
			err = AESend(&editCommandEvent,&ignoreReply,kAENoReply,kAEHighPriority,10000,nil, nil);
	}

	/*
		Clean up
	*/
	if (ourAddress.dataHandle)
		forgetErr = AEDisposeDesc(&ourAddress);

	if (editCommandEvent.dataHandle)
		forgetErr = AEDisposeDesc(&editCommandEvent);

	if (ignoreReply.dataHandle)
		forgetErr = AEDisposeDesc(&ignoreReply);

	if (ourTextSelObj.dataHandle)
		forgetErr = AEDisposeDesc(&ourTextSelObj);

} /*DoEditCommand*/

pascal void IssueCutCommand(DPtr theDocument)
{
	DoEditCommand(theDocument, editCutCommand);
}

pascal void IssueCopyCommand(DPtr theDocument)
{
	DoEditCommand(theDocument, editCopyCommand);
}

pascal void IssuePasteCommand(DPtr theDocument)
{
	DoEditCommand(theDocument, editPasteCommand);
}

pascal void IssueClearCommand(DPtr theDocument)
{
	DoEditCommand(theDocument, editClearCommand);
}

pascal OSErr IssueJumpCommand(FSSpec * file, WindowPtr win, short line)
{
	OSErr						err;
	AEDesc					window;
	AEDesc					target;
	AppleEvent				ignoreReply;
	ProcessSerialNumber 	psn;
	
	MakeSelfPSN(&psn);

	if (win) {
		if (err = MakeWindowObj(win, &window))
			return err;
			
		err = AEBuildAppleEvent(kAEMiscStandards, kAESelect,
					typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber),
					0, 0, &target,
					"'----':@",
					&window);
		
		AEDisposeDesc(&window);
		
		if (err)
			return err;
			
		err = AESend(&target,&ignoreReply,kAENoReply,kAEHighPriority,10000,nil,nil);
	
		AEDisposeDesc(&target);

		if (ignoreReply.dataHandle)
			AEDisposeDesc(&ignoreReply);	

		if (err)
			return err;
	} else if (file) {
		if (err = IssueAEOpenDoc(*file))
			return err;
	}

	if (!line)
		return noErr;
		
	if (err = AEBuildAppleEvent(kAEMiscStandards, kAEMakeObjectsVisible,
		typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber),
		0, 0, &target,
		"'----':obj{ "
					 "want:type(clin),"
					 "form:indx,"
					 "seld:long(@),"
					 "from:obj{"
								  "want:type(cwin),"
								  "form:indx,"
								  "seld:long(1),"
								  "from:()"
								 "}"
					"}",
		line
		)
	)
		return err;

	err = AESend(&target,&ignoreReply,kAENoReply,kAEHighPriority,10000,nil,nil);
	
	AEDisposeDesc(&target);

	if (ignoreReply.dataHandle)
		AEDisposeDesc(&ignoreReply);	

	return err;
}

/*
	Window property routines
*/

pascal void IssueZoomCommand(WindowPtr whichWindow, short whichPart)
{
  	Boolean       zoomBool;
	AEDesc        zoomDesc;
	AEAddressDesc selfAddr;
	AEDesc        frontWinObj;
	OSErr         err;

	err = MakeSelfAddress(&selfAddr);
	err = MakeWindowObj(whichWindow, &frontWinObj);

	zoomBool = (whichPart==inZoomOut);

	err = AECreateDesc(typeBoolean, (Ptr)&zoomBool, sizeof(zoomBool), &zoomDesc);
	err = SendAESetObjProp(&frontWinObj, pIsZoomed, &zoomDesc, &selfAddr);
} /* IssueZoomCommand */

pascal void IssueCloseCommand(WindowPtr whichWindow)
{
	AEAddressDesc  selfAddr;
	AEDesc         frontWinObj;
	OSErr          err;
	OSErr          ignoreErr;
	AppleEvent     closeCommandEvent;
	AppleEvent     ignoreReply;

	frontWinObj.dataHandle = nil;

	err = MakeSelfAddress(&selfAddr);
	err = MakeWindowObj(whichWindow, &frontWinObj);
	err = AECreateAppleEvent( kAECoreSuite, kAEClose, &selfAddr, 0, 0, &closeCommandEvent) ;

	/* add parameter - the window to close */
	if (err==noErr)
		err = AEPutParamDesc(&closeCommandEvent, keyDirectObject, &frontWinObj);

	if (err==noErr)
		err = AESend(&closeCommandEvent,&ignoreReply,kAENoReply+kAEAlwaysInteract,kAEHighPriority,10000,nil, nil);

	if (closeCommandEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&closeCommandEvent);

	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);

	if (frontWinObj.dataHandle)
		ignoreErr = AEDisposeDesc(&frontWinObj);
} /* IssueCloseCommand */

pascal void IssueSizeWindow(WindowPtr whichWindow, short newHSize, short newVSize)
{
  	Rect          sizeRect;
	Rect          contentRect;
	short         edgeSize;
	AEDesc        sizeDesc;
	AEAddressDesc selfAddr;
	AEDesc        frontWinObj;
	OSErr         err;

	sizeRect    = (**(((WindowPeek)whichWindow)->strucRgn)).rgnBBox;
	contentRect = (**(((WindowPeek)whichWindow)->contRgn)).rgnBBox;

	edgeSize = sizeRect.right-sizeRect.left-(contentRect.right-contentRect.left);
	sizeRect.right = sizeRect.left+newHSize+edgeSize;

	edgeSize = sizeRect.bottom-sizeRect.top-(contentRect.bottom-contentRect.top);
	sizeRect.bottom = sizeRect.top+newVSize+edgeSize;

	err = MakeSelfAddress(&selfAddr);

	err = MakeWindowObj(whichWindow, &frontWinObj);

	if (err==noErr)
		err =
			AECreateDesc(
				typeQDRectangle,
				(Ptr)&sizeRect,
				sizeof(sizeRect),
				&sizeDesc);

	if (err==noErr)
		err =
			SendAESetObjProp(
				&frontWinObj,
				pBounds,
				&sizeDesc,
				&selfAddr);
} /*IssueSizeWindow*/

pascal void IssueMoveWindow(WindowPtr whichWindow, Rect sizeRect)
{
	AEDesc        sizeDesc;
	AEAddressDesc selfAddr;
	AEDesc        frontWinObj;
	OSErr         err;

	err = MakeSelfAddress(&selfAddr);
	err = MakeWindowObj(whichWindow, &frontWinObj);

	if (err==noErr)
		err = AECreateDesc(typeQDRectangle, (Ptr)&sizeRect, sizeof(sizeRect), &sizeDesc);

	if (err==noErr)
		err = SendAESetObjProp(&frontWinObj, pBounds, &sizeDesc, &selfAddr);
} /*IssueMoveWindow*/

pascal void IssuePageSetupWindow(WindowPtr whichWindow, TPrint thePageSetup)
{
	AEDesc        sizeDesc;
	AEAddressDesc selfAddr;
	AEDesc        frontWinObj;
	OSErr         err;

	err = MakeSelfAddress(&selfAddr);

	err = MakeWindowObj(whichWindow, &frontWinObj);

	if (err==noErr)
		err = AECreateDesc(typeTPrint, (Ptr)&thePageSetup, sizeof(thePageSetup), &sizeDesc);

	if (err==noErr)
		err = SendAESetObjProp(&frontWinObj, pPageSetup, &sizeDesc, &selfAddr);
} /*IssuePageSetupWindow*/

pascal void IssueShowBorders(WindowPtr whichWindow, Boolean showBorders)
{
	AEDesc        sizeDesc;
	AEAddressDesc selfAddr;
	AEDesc        frontWinObj;
	OSErr         err;

	err = MakeSelfAddress(&selfAddr);

	err = MakeWindowObj(whichWindow, &frontWinObj);

	if (err==noErr)
		err = AECreateDesc(typeBoolean, (Ptr)&showBorders, sizeof(showBorders), &sizeDesc);

	if (err==noErr)
		err = SendAESetObjProp(&frontWinObj, pShowBorders, &sizeDesc, &selfAddr);
} /*IssueShowBorders*/

pascal void IssuePrintWindow(WindowPtr whichWindow)
{
	AEAddressDesc selfAddr;
	AEDesc        frontWinObj;
	OSErr         err;
	OSErr         ignoreErr;
	AppleEvent    printCommandEvent;
	AppleEvent    ignoreReply;

	err = MakeSelfAddress(&selfAddr);

	err = MakeWindowObj(whichWindow, &frontWinObj);

	err = AECreateAppleEvent(kCoreEventClass, kAEPrintDocuments, &selfAddr, 0, 0, &printCommandEvent) ;

	/*
		add parameter - the window to print
	*/

	if (err==noErr)
		err = AEPutParamDesc(&printCommandEvent, keyDirectObject, &frontWinObj);

	if (err==noErr)
		err = AESend(&printCommandEvent,&ignoreReply,kAENoReply+kAEAlwaysInteract,kAEHighPriority,10000,nil, nil);

  	if (printCommandEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&printCommandEvent);

	if (frontWinObj.dataHandle)
		err = AEDisposeDesc(&frontWinObj);

	if (selfAddr.dataHandle)
		err = AEDisposeDesc(&selfAddr);
} /*IssuePrintWindow*/

pascal OSErr IssueAEOpenDoc(FSSpec myFSSpec)
/* send OpenDocs AppleEvent to myself, with a one-element list
  containing the given file spec

  NOTES : the core AEOpenDocs event is defined as taking a list of
  		aliases (not file specs) as its direct parameter.  However,
			we can send the file spec instead and depend on AppleEvents'
			automatic coercion.  In fact, we don't really even have to put
			in a list; AppleEvents will coerce a descriptor into a 1-element
			list if called for.  In this routine, though, we'll make the
			list for demonstration purposes.
*/

{
	AppleEvent    myAppleEvent;
	AppleEvent    defReply;
	AEDescList    docList;
	AEAddressDesc selfAddr;
	OSErr         myErr;
	OSErr         ignoreErr;

	myAppleEvent.dataHandle = nil;
	docList.dataHandle  = nil;
	selfAddr.dataHandle = nil;
	defReply.dataHandle = nil;

	/*
		Create empty list and add one file spec
	*/
	myErr = AECreateList(nil,0,false, &docList);

	if (myErr==noErr)
		myErr = AEPutPtr(&docList,1,typeFSS,(Ptr)&myFSSpec,sizeof(myFSSpec));

	/*
		Create a self address to send it to
	*/
	if (myErr==noErr)
		myErr = MakeSelfAddress(&selfAddr);

	if (myErr==noErr)
		myErr =
			AECreateAppleEvent(
				MPAppSig,
				kAEOpenDocuments,
				&selfAddr,
				kAutoGenerateReturnID,
				kAnyTransactionID,
				&myAppleEvent);

	/*
		Put Params into our event and send it
	*/
	if (myErr == noErr)
		myErr =
			AEPutParamDesc(
				&myAppleEvent,
				keyDirectObject,
				&docList);

	myErr =
		AESend(
			&myAppleEvent,
			&defReply,
			kAENoReply+kAEAlwaysInteract,
			kAENormalPriority,
			kAEDefaultTimeout,
			nil,
			nil);

	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);

	if (myAppleEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&myAppleEvent);

	if (docList.dataHandle)
		ignoreErr = AEDisposeDesc(&docList);

	return myErr;
}	/* IssueAEOpenDoc */

pascal void IssueAENewWindow(void)
/*
	send the New Element event to myself with a null container
*/
{
	AppleEvent    myAppleEvent;
	AppleEvent    defReply;
	AEAddressDesc selfAddr;
	OSErr         myErr;
	OSErr         ignoreErr;
	DescType      elemClass;

	myAppleEvent.dataHandle = nil;

	/*
		Create the address of us
	*/

	myErr = MakeSelfAddress(&selfAddr);

	/*
		create event
	*/

	myErr =
		AECreateAppleEvent(
			kAECoreSuite,
			kAECreateElement,
			&selfAddr,
			kAutoGenerateReturnID,
			kAnyTransactionID,
			&myAppleEvent);

	/*
		attach desired class of new element
	*/

	elemClass = cDocument;

	if (myErr == noErr)
		myErr =
			AEPutParamPtr(
				&myAppleEvent,
				keyAEObjectClass,
				typeType,
				(Ptr)&elemClass,
				sizeof(elemClass));

	/*
		send the event
	*/

	if (myErr == noErr)
		myErr =
			AESend(
				&myAppleEvent,
				&defReply,
				kAENoReply+kAENeverInteract,
				kAENormalPriority,
				kAEDefaultTimeout,
				nil,
				nil);
	/*
		Clean up - reply never created so don't throw away
	*/
	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);

	if (myAppleEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&myAppleEvent);
}	/* IssueAENewWindow */

pascal OSErr IssueSaveCommand(
	DPtr 			theDocument,
	FSSpecPtr 	where)
/*
	send an AppleEvent Save Event to myself
*/
{
	AEDesc        windowObj;
	AppleEvent    myAppleEvent;
	AppleEvent    defReply;
	OSErr         myErr;
	OSErr         ignoreErr;
	AEAddressDesc selfAddr;

	windowObj.dataHandle = nil;
	myAppleEvent.dataHandle = nil;

	myErr = MakeWindowObj(theDocument->theWindow, &windowObj);

	if (myErr==noErr)
		myErr = MakeSelfAddress(&selfAddr);

  /*
		Build event
	*/
  if (myErr == noErr)
		myErr =
			AECreateAppleEvent(
				kAECoreSuite,
				kAESave,
				&selfAddr,
				kAutoGenerateReturnID,
				kAnyTransactionID,
				&myAppleEvent);

  /*
		say which window
	*/
  if (myErr==noErr)
		myErr = AEPutParamDesc(&myAppleEvent, keyDirectObject, &windowObj);

  /*
		add optional file param if we need to
	*/
  if (where)
		if (myErr==noErr)
			myErr =
				AEPutParamPtr(
					&myAppleEvent,
					keyAEDestination,
					typeFSS,
					(Ptr)where,
					sizeof(FSSpec));

	if (!myErr)
		myErr =
			AEPutParamPtr(
				&myAppleEvent,
				keyAEFileType,
				typeEnumerated,
				(Ptr)&theDocument->type,
				sizeof(OSType));
		
  /*
		send the event
	*/
  if (myErr==noErr)
		myErr  =
			AESend(
				&myAppleEvent,
				&defReply,
				kAENoReply+kAENeverInteract,
				kAENormalPriority,
				kAEDefaultTimeout,
				nil,
				nil);

	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);

	if (windowObj.dataHandle)
		ignoreErr = AEDisposeDesc(&windowObj);

	if (myAppleEvent.dataHandle)
		myErr = AEDisposeDesc(&myAppleEvent);

	return myErr;
}	/* IssueSaveCommand */

pascal OSErr IssueRevertCommand(WindowPtr theWindow)
/*
	send an AppleEvent Revert Event to myself
*/
{
	AEDesc        windowObj;
	AppleEvent    myAppleEvent;
	AppleEvent    defReply;
	OSErr         myErr;
	OSErr         ignoreErr;
	AEAddressDesc selfAddr;

	windowObj.dataHandle = nil;
	myAppleEvent.dataHandle = nil;

	myErr = MakeWindowObj(theWindow, &windowObj);

	if (myErr==noErr)
		myErr = MakeSelfAddress(&selfAddr);

	/*
		Build event
	*/

	if (myErr == noErr)
		myErr  =
			AECreateAppleEvent(
				kAEMiscStandards,
				kAERevert,
				&selfAddr,
				kAutoGenerateReturnID,
				kAnyTransactionID,
				&myAppleEvent);
	/*
		say which window
	*/

	if (myErr == noErr)
		myErr = AEPutParamDesc(&myAppleEvent, keyDirectObject, &windowObj);
	/*
		send the event
	*/
	if (myErr==noErr)
		myErr =
			AESend(
				&myAppleEvent,
				&defReply,
				kAENoReply+kAENeverInteract,
				kAENormalPriority,
				kAEDefaultTimeout,
				nil,
				nil);

	if (windowObj.dataHandle)
		ignoreErr = AEDisposeDesc(&windowObj);

	if (myAppleEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&myAppleEvent);

	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);

	return myErr;
}	/* IssueRevertCommand */

/*
	Name : IssueQuitCommand
	Purpose : Sends self a Quit AppleEvent
*/
pascal OSErr IssueQuitCommand(void)
{
	AppleEvent    myAppleEvent;
	AppleEvent    defReply;
	OSErr         myErr;
	OSErr         ignoreErr;
	AEAddressDesc selfAddr;
	DescType      mySaveOpt;

	myAppleEvent.dataHandle = nil;
	selfAddr.dataHandle     = nil;

	myErr = MakeSelfAddress(&selfAddr);

	/*
		Build event
	*/
	if (myErr == noErr)
		myErr  =
			AECreateAppleEvent(
				kCoreEventClass,
				kAEQuitApplication,
				&selfAddr,
				kAutoGenerateReturnID,
				kAnyTransactionID,
				&myAppleEvent);
	/*
		say which save option
	*/
	mySaveOpt = kAEAsk;

	if (myErr == noErr)
		myErr =
			AEPutParamPtr(
				&myAppleEvent,
				keyAESaveOptions,
				typeEnumerated,
				(Ptr)&mySaveOpt,
				sizeof(mySaveOpt));
	/*
		send the event
	*/
	if (myErr==noErr)
		myErr =
			AESend(
				&myAppleEvent,
				&defReply,
				kAENoReply+kAEAlwaysInteract,
				kAENormalPriority,
				kAEDefaultTimeout,
				nil,
				nil);

	if (myAppleEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&myAppleEvent);

	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);

	return myErr;
}	/* IssueQuitCommand */

/*
	 Name :IssueCreatePublisher
	 Purpose :Interact with user to get Publisher info
						and the IssueAECommand to Publish currect selection
*/
pascal void IssueCreatePublisher(DPtr whichDoc)
{
	AEAddressDesc selfAddr;
	AEDesc        selTextObj;
	OSErr         err;
	OSErr         ignoreErr;
	AppleEvent    publishCommandEvent;
	AppleEvent    ignoreReply;

  	publishCommandEvent.dataHandle = nil;
	selfAddr.dataHandle = nil;
	selTextObj.dataHandle = nil;

	err = MakeSelfAddress(&selfAddr);

	if (err==noErr)
		err = MakeSelectedTextObj(whichDoc->theWindow, whichDoc->theText, &selTextObj);

	err =
		AECreateAppleEvent(
			kAEMiscStandards,
			kAECreatePublisher,
			&selfAddr,
			0,
			0,
			&publishCommandEvent) ;

	/*
		add parameter - the text to publish
	*/
	if (err==noErr)
		err = AEPutParamDesc(&publishCommandEvent, keyDirectObject, &selTextObj);

	if (err==noErr)
		err =
			AESend(
				&publishCommandEvent,
				&ignoreReply,
				kAENoReply+kAEAlwaysInteract,
				kAEHighPriority,
				10000,
				nil,
				nil);

  	if (publishCommandEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&publishCommandEvent);

	if (selTextObj.dataHandle)
		ignoreErr = AEDisposeDesc(&selTextObj);

	if (selfAddr.dataHandle)
		ignoreErr = AEDisposeDesc(&selfAddr);
} /*IssueCreatePublisher*/

#define kOK 1
#define kCancel 2
#define kOtherSize 4
#define kOutlineItem 5

pascal Boolean PoseSizeDialog(long *whatSize)
{
	GrafPtr   savedPort;
	DialogPtr aDialog;
	Str255    aString;
	short     itemHit;

	GetPort(&savedPort);
	aDialog = GetNewAppDialog(1004);
	DoShowWindow(aDialog);
	SetPort(aDialog);

	AdornDefaultButton(aDialog, kOutlineItem);

	/*set the edittext button to contain the right size*/
	NumToString(*whatSize, aString);
	SetText(aDialog, kOtherSize, aString);

	do {
		ModalDialog(nil, &itemHit);
	} while ((itemHit!=kOK) && (itemHit!=kCancel));

	if (itemHit == kOK)
		RetrieveText(aDialog, kOtherSize, aString);

	DisposeDialog(aDialog);
	SetPort(savedPort);

	if (itemHit == kOK) {
		/*set the new size of the text*/
		StringToNum(aString, whatSize);
		if ((*whatSize<1) || (*whatSize>2000))
		 	*whatSize = 12;
	}
	return itemHit == kOK;
}

pascal void IssueFormatCommand(DPtr theDocument)
{
	Str255        	name;
	AEDesc        	desc;
	AEAddressDesc 	theAddress;
	AEDesc        	windowObj;
	OSErr         	err;
	DocFormat		fmt;
	Boolean			defaultFormat;
	
	if (theDocument) {
		fmt.font 		= 	(*theDocument->theText)->txFont;
		fmt.size 		= 	(*theDocument->theText)->txSize;
		defaultFormat	=	false;
	} else {
		fmt 				= 	gFormat;
		defaultFormat	=	true;
	}
	
	if (DoFormatDialog(&fmt, &defaultFormat)) {
		if (theDocument) {
			err = MakeSelfAddress(&theAddress);
			err = MakeWindowObj(theDocument->theWindow, &windowObj);

			if (err==noErr)
	  			err = CreateOffsetDescriptor(fmt.size, &desc);

			if (err==noErr)
				err = SendAESetObjProp(&windowObj, pPointSize, &desc, &theAddress);
				
			err = MakeSelfAddress(&theAddress);
			err = MakeWindowObj(theDocument->theWindow, &windowObj);
		
			GetFontName(fmt.font, name);
		
			if (err==noErr)
				err  = AECreateDesc(typeChar, (Ptr)&name[1], name[0], &desc);
		
			if (err==noErr)
				err  = SendAESetObjProp(&windowObj, pFont, &desc, &theAddress);
		}
		
		if (defaultFormat) {
			OpenPreferences(); /* trashes gFormat */

			gFormat = fmt;

			if (gPrefsFile) {
				short		resFile;
				short	**	defaultFont;
			
				resFile = CurResFile();
				UseResFile(gPrefsFile);
				
				defaultFont = (short **) Get1Resource('PFNT', 128);
				**defaultFont = gFormat.size;
				GetFontName(gFormat.font, name);
				SetResInfo((Handle) defaultFont, 128, name);
				ChangedResource((Handle) defaultFont);
				WriteResource((Handle) defaultFont);
				UpdateResFile(gPrefsFile);
				CloseResFile(gPrefsFile);
				
				UseResFile(resFile);
			}
		}
	}
} /*IssueFormatCommand*/

pascal OSErr IssueSetDataObjToBufferContents(const AEDesc * theObj)
{
  	OSErr         	myErr;
	OSErr				ignoreErr;
	AEAddressDesc 	theAddress;
	AppleEvent    	myAppleEvent;
	AppleEvent    	defReply;

	myErr = MakeSelfAddress(&theAddress);

	/* create event */

	if (myErr==noErr)
		myErr = AECreateAppleEvent(kAECoreSuite, kAESetData, &theAddress, 0, 0, &myAppleEvent);

	/* add prop obj spec to the event */

	if (myErr==noErr)
		myErr = AEPutParamDesc(&myAppleEvent, keyDirectObject, theObj);

	/* add prop data to the event */

	if (myErr==noErr)
		myErr =
			AEPutParamPtr(
				&myAppleEvent,
				keyAEData,
				typeChar,
				(Ptr)gTypingBuffer,
				gCharsInBuffer);

	/* send event */

	if (myErr==noErr)
	 if (gRecordingImplemented)
		 myErr =
		 	AESend(
				&myAppleEvent,
				&defReply,
				kAENoReply+kAEDontExecute,
				kAENormalPriority,
				kAEDefaultTimeout,
				nil,
				nil);

	if (theAddress.dataHandle)
		ignoreErr = AEDisposeDesc(&theAddress);

	if (myAppleEvent.dataHandle)
		ignoreErr = AEDisposeDesc(&myAppleEvent);

	return myErr;
}

pascal void AddKeyToTypingBuffer(DPtr theDocument, char theKey)
{
	OSErr myErr;
	OSErr ignoreErr;

	if (theKey==BS || theKey==FS || theKey==GS || theKey==RS || theKey==US) {
		FlushAndRecordTypingBuffer();
		if (theKey==BS) {
			if ((**theDocument->theText).selStart!=(**theDocument->theText).selEnd) {
				myErr =
					MakeTextObj(
						theDocument->theWindow,
						(**theDocument->theText).selStart,
						(**theDocument->theText).selEnd,
						&gTypingTargetObject);
			} else {
				myErr =
					MakeTextObj(
						theDocument->theWindow,
						(**theDocument->theText).selStart-1,
						(**theDocument->theText).selStart,
						&gTypingTargetObject);
			}

		 	myErr = IssueSetDataObjToBufferContents(&gTypingTargetObject);

			ignoreErr = AEDisposeDesc(&gTypingTargetObject);

			gTypingTargetObject.dataHandle = nil;
		}
	} else {
		if (gCharsInBuffer==0)
			myErr =
				MakeSelectedTextObj(
					theDocument->theWindow,
					theDocument->theText,
					&gTypingTargetObject);

		gTypingBuffer[gCharsInBuffer++] = theKey;
	}
}

pascal void FlushAndRecordTypingBuffer(void)
{
  	OSErr  myErr;
	OSErr  ignoreErr;

	if (gCharsInBuffer != 0) {
		myErr = IssueSetDataObjToBufferContents(&gTypingTargetObject);

		if (gTypingTargetObject.dataHandle)
			ignoreErr = AEDisposeDesc(&gTypingTargetObject);
	}

	gCharsInBuffer = 0;
	gTypingTargetObject.dataHandle = 0;
}

/*****************************************************************************/
/*
	Object Accessors
*/

pascal OSErr WindowFromNullAccessor(
	DescType      wantClass,
	const AEDesc  *container,
	DescType      containerClass,
	DescType      form,
	const AEDesc  *selectionData,
	AEDesc        *value,
	long          theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (container,theRefCon)
#endif

	OSErr       myErr;
	Str255      nameStr;
	WindowToken theWindow;
	short       index;
	AEDesc      resultDesc;

	myErr = errAEBadKeyForm;	/* or whatever */

	value->dataHandle     = nil;
	resultDesc.dataHandle = nil;

	/*
		should only be called with wantClass = cWindow and
		with containerClass = typeNull or typeMyAppl.
		Currently accept as either formName or formAbsolutePosition
	*/

	if (
		((wantClass != cWindow) && (wantClass != cDocument)) ||
		((containerClass != typeNull) && (containerClass != typeMyAppl)) ||
		!((form == formName) || (form == formAbsolutePosition))
	)
		return errAEWrongDataType;

	if (form == formName) {
		myErr     = GetPStringFromDescriptor(selectionData, (char *)nameStr);
		theWindow = WindowNameToWindowPtr(nameStr);
	}

	if (form == formAbsolutePosition) {
		myErr 		= GetIntegerFromDescriptor(selectionData, &index);

		if (index<0)
			index = CountWindows()+index+1;

		theWindow = GetWindowPtrOfNthWindow(index);
	}

	if (!theWindow)
		myErr = errAEIllegalIndex;								/* We only want document windows */
		
	if (myErr == noErr)
		myErr = AECreateDesc(typeMyWndw, (Ptr)&theWindow, sizeof(theWindow), value);

	return myErr;
}	/* WindowFromNullAccessor */

pascal OSErr ApplicationFromNullAccessor(
	DescType      wantClass,
	const AEDesc  *container,
	DescType      containerClass,
	DescType      form,
	const AEDesc  *selectionData,
	AEDesc        *value,
	long          theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (container,selectionData,theRefCon)
#endif

	OSErr    myErr;
	appToken theApp;
	AEDesc   resultDesc;

	value->dataHandle     = nil;
	resultDesc.dataHandle = nil;

	/*
		should only be called with wantClass = cApplication and
		with containerClass = typeNull.
		Currently accept as either formName or formAbsolutePosition
	*/

	if (
		(wantClass != cApplication) ||
		(containerClass != typeNull) ||
		!((form == formName) || (form == formAbsolutePosition))
	)
		return errAEWrongDataType;

	if ((form == formName) || (form == formAbsolutePosition)) {
		theApp.highLongOfPSN = 0;
		theApp.lowLongOfPSN  = kCurrentProcess;
	}

	myErr = AECreateDesc(typeMyAppl, (Ptr)&theApp, sizeof(theApp), value);

	return myErr;
}	/* ApplicationFromNullAccessor */

pascal void MoveToNonSpace(short *start, short limit, charsHandle myChars)
/*
	Treats space,comma, full stop, ; and : as space chars
*/
{
	while (*start<=limit)
	  	switch ((**myChars)[*start]) {
	  	case ' ':
		case ',':
		case '.':
		case ':':
		case 10:
		case 13:
			(*start) +=1;
			break;
		default:
			return;
		}
}

pascal void MoveToSpace(short *start, short limit, charsHandle myChars)
	/*
		Treats space,comma, full stop, ; and : as space chars
	*/
{
	while (*start<=limit)
	  	switch ((**myChars)[*start]) {
	  	case ' ':
		case ',':
		case '.':
		case ':':
		case 10:
		case 13:
			return;
		default:
			(*start) +=1;
			break;
		}
}

pascal short CountWords(TEHandle inTextHandle, short startAt, short forHowManyChars)
{
	charsHandle myChars;
	short       start;
	short       limit;
	short       myWords;

	myChars  = (charsHandle)(**inTextHandle).hText;
	limit    = startAt+forHowManyChars-1;
	start    = startAt;
	myWords  = 0;
	MoveToNonSpace(&start, limit, myChars);
	while (start<=limit) {
		myWords++;
		MoveToSpace(&start, limit, myChars);
		MoveToNonSpace(&start, limit, myChars);
	}
	return myWords;
} /* CountWords */

pascal void GetNthWordInfo(
	short    whichWord,
	TEHandle inTextHandle,
	short    *wordStartChar,
	short    *wordLength)
	/*
		On entry:	wordStartChar is start of char range to count in
							wordLength is number of chars to consider

		On Exit : wordStartChar is start of requested word
							wordLength is number of chars in word
	*/
{
	charsHandle myChars;
	short       start;
	short       limit;

	myChars  = (charsHandle)(**inTextHandle).hText;
	limit    = *wordStartChar + *wordLength-1;
	start    = *wordStartChar;
	MoveToNonSpace(&start, limit, myChars);
	while ((start<=limit) && (whichWord>0)) {

		whichWord       = whichWord-1;
		*wordStartChar  = start;
		MoveToSpace(&start, limit, myChars);
		*wordLength     = start- *wordStartChar;

		MoveToNonSpace(&start, limit, myChars);
	}
} /* GetNthWordInfo */

pascal void GetWordInfo(
	short    whichWord,
	TEHandle inTextHandle,
	short    *wordStartChar,
	short    *wordLength)
	/*
		On wordStartChar entry is start of char range to count in
							wordLength is number of chars to consider

		On Exit : wordStartChar is start of requested word
							wordLength is number of chars in word
	*/
{
	short noOfWords;

	noOfWords = CountWords(inTextHandle, *wordStartChar, *wordLength);

	if (whichWord<0)
		whichWord = noOfWords + whichWord + 1;

	if (whichWord>noOfWords) {
		*wordStartChar = *wordStartChar+*wordLength;
		*wordLength    = 0;
	} else
		GetNthWordInfo(whichWord, inTextHandle, wordStartChar, wordLength);
}

pascal short CountLines(TEHandle inTextHandle)
{
	/*
		CountLines makes use of info in TERec
	*/
	return (**inTextHandle).nLines;
}

pascal short LineOfOffset(TEHandle theHTE, short charOffset)
{
	short n;

	n = (**theHTE).nLines;

	while (((**theHTE).lineStarts[n-1]>charOffset) &&
				 (n>0))
		 n--;

	return n;
} /* LineOfOffset */

pascal void GetLineInfo(
	short    whichLine,
	TEHandle inTextHandle,
	short    *lineStartChar,
	short    *lineLength)
{
	short       noOfLines;
	charsHandle myChars;

	/* Addition of lines within text object */
	short       lineOfStart;
	short       lineOfEnd;

	lineOfStart = LineOfOffset(inTextHandle, *lineStartChar);
	lineOfEnd   = LineOfOffset(inTextHandle, *lineStartChar+*lineLength-1);

	myChars   = (charsHandle)(**inTextHandle).hText;
	noOfLines = lineOfEnd - lineOfStart + 1;

	if (whichLine<0)
		whichLine = noOfLines + whichLine + 1;

	noOfLines = CountLines(inTextHandle);
	whichLine = whichLine + lineOfStart - 1; /* convert offset relative to offset absolute */

	/* End of addition */

	if (whichLine<=lineOfEnd) {
		*lineStartChar = (**inTextHandle).lineStarts[whichLine-1];
		if (whichLine==noOfLines)
			*lineLength  = (**inTextHandle).teLength;
		else
			*lineLength  = (**inTextHandle).lineStarts[whichLine];
		*lineLength    = *lineLength-*lineStartChar;
		/*
			Don't return CR
		*/
		if ((**myChars)[ *lineStartChar+*lineLength-1] == 13)
			*lineLength = *lineLength-1;
	} else {
		if (whichLine<noOfLines)
		  *lineStartChar = (**inTextHandle).lineStarts[whichLine]; /* start of whichLine++ */
		else
			*lineStartChar = (**inTextHandle).teLength;
		*lineLength    = 0;
	}
} /* GetLineInfo */

pascal OSErr TextElemFromWndwAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon)
#endif

	OSErr       myErr;
	OSErr       ignoreErr;
	WindowToken theWindow;
	Size        actSize;
	long        index;
	TextToken   theTextToken;
	AERecord    selectionRecord;
	TextToken   startText;
	TextToken   stopText;
	DescType    returnedType;
	AEDesc      windDesc;
	TEHandle    theHTE;
	DPtr        theDocument;
	short       wordStartChar;
	short       wordLength;

	myErr = -1700;	/* or whatever */

	selectionRecord.dataHandle = nil;

	/* do some checking for robustness' sake */

	if (
		((containerClass != cWindow) && (containerClass != cDocument)) ||
		((wantClass != cText) && (wantClass != cChar) && (wantClass != cSpot) && (wantClass != cWord) && (wantClass != cLine)    ) ||
		((form!=formRange) && (form!=formAbsolutePosition))
	)
		return errAEWrongDataType;

	/* let's get the window which contains the text element */

	myErr = AECoerceDesc(container, typeMyWndw, &windDesc);
	GetRawDataFromDescriptor(&windDesc, (Ptr)&theWindow, sizeof(theWindow), &actSize);
	myErr = AEDisposeDesc(&windDesc);

	if (theWindow==nil)
		myErr = errAEIllegalIndex;
	else {
		theTextToken.tokenWindow = theWindow;

		theDocument = DPtrFromWindowPtr(theTextToken.tokenWindow);
		theHTE      = theDocument->theText;

		switch (form) {
		case formAbsolutePosition:
			myErr = GetLongIntFromDescriptor(selectionData, &index);

			switch (wantClass) {
			case cSpot:
				if (index<0)
					theTextToken.tokenOffset = (**theHTE).teLength+index+2; /* Past last char */
				else
					theTextToken.tokenOffset = index;

				theTextToken.tokenLength = 0;
				break;

			case cChar:
				if (index<0)
					theTextToken.tokenOffset = (**theHTE).teLength+index+1;
				else
				  theTextToken.tokenOffset = index;

				theTextToken.tokenLength = 1;
				break;

			case cWord:
				wordStartChar = 0;
				wordLength    = (**theHTE).teLength;
				GetWordInfo(index, theHTE, &wordStartChar, &wordLength); /* zero based */
				theTextToken.tokenOffset = wordStartChar+1;
				theTextToken.tokenLength = wordLength;
				break;

			case cLine:
				wordStartChar = 0;
				wordLength    = (**theHTE).teLength;
				GetLineInfo(index, theHTE, &wordStartChar, &wordLength); /* zero based */
				theTextToken.tokenOffset = wordStartChar+1;
				theTextToken.tokenLength = wordLength;
				break;
			
			case cText:
				theTextToken.tokenOffset = 1;
				theTextToken.tokenLength = (**theHTE).teLength;
				myErr							 = noErr;
				break;
			}
			break;

		case formRange:
			/* coerce the selection data into an AERecord */

			 myErr = AECoerceDesc(selectionData, typeAERecord, &selectionRecord);

			/* get the start object as a text token -
					this will reenter this proc but as formAbsolutePosition via the coercion handler*/

			myErr =
				AEGetKeyPtr(
					&selectionRecord,
					keyAERangeStart,
					typeMyText,
					&returnedType,
					(Ptr)&startText,
					sizeof(startText),
					&actSize);

			/* now do the same for the stop object */
			if (myErr==noErr)
				myErr =
					AEGetKeyPtr(
						&selectionRecord,
						keyAERangeStop,
						typeMyText,
						&returnedType,
						(Ptr)&stopText,
						sizeof(stopText),
						&actSize);

			if (myErr==noErr)
				if (
					(theTextToken.tokenWindow != stopText.tokenWindow) ||
					(theTextToken.tokenWindow != startText.tokenWindow)
				)
					myErr = errAECorruptData;	/* or whatever ????*/

			theTextToken.tokenOffset  = startText.tokenOffset;
			theTextToken.tokenLength  = stopText.tokenOffset + stopText.tokenLength - startText.tokenOffset;

			if (theTextToken.tokenLength<0)
				myErr = errAECorruptData;	/* or whatever */

			ignoreErr = AEDisposeDesc(&selectionRecord);

			break;
		}
	}

	/* return theTextToken in a descriptor */

	if (myErr==noErr)
		myErr = AECreateDesc(typeMyText, (Ptr)&theTextToken, sizeof(theTextToken), value);

	return myErr;
}	/* TextElemFromWndwAccessor */

pascal OSErr TextElemFromWndwPropAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr       		myErr;
	Size        		actSize;
	long        		index;
	AEDesc				windowPropDesc;
	windowPropToken 	theWindowPropToken;
	TextToken   		theTextToken;
	AERecord    		selectionRecord;
	TextToken   		startText;
	TextToken   		stopText;
	DescType    		returnedType;
	TEHandle    		theHTE;
	short       		wordStartChar;
	short       		wordLength;
	DPtr        		theDocument;

	myErr = -1700;	/* or whatever */
	windowPropDesc.dataHandle = nil;
	
	/* do some checking for robustness' sake */

	if (
		((wantClass != cText) && (wantClass != cChar) && (wantClass != cSpot) && (wantClass != cLine) && (wantClass != cWord)) ||
		((form != formAbsolutePosition) && (form != formRange))
	)
		return errAEWrongDataType;

	/* get the window property token*/
	myErr = AECoerceDesc(container, typeMyWindowProp, &windowPropDesc);
	GetRawDataFromDescriptor(&windowPropDesc, (Ptr)&theWindowPropToken, sizeof(theWindowPropToken), &actSize);
	if (windowPropDesc.dataHandle)
		AEDisposeDesc(&windowPropDesc);

	if (theWindowPropToken.tokenProperty != pSelection)
		return errAEEventNotHandled;
		
	/* let's get the src text */
	theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
	theHTE      = theDocument->theText;

	theTextToken.tokenWindow 	= theWindowPropToken.tokenWindowToken;
	theTextToken.tokenOffset	= (*theHTE)->selStart + 1;
	theTextToken.tokenLength	= (*theHTE)->selEnd - (*theHTE)->selStart;

	switch (form) {
	case formAbsolutePosition:
		myErr = GetLongIntFromDescriptor(selectionData, &index);

		switch (wantClass) {
		case cSpot:
			if (index<0)
				theTextToken.tokenOffset = theTextToken.tokenOffset+index+1+theTextToken.tokenLength;
			else
				theTextToken.tokenOffset = theTextToken.tokenOffset+index-1;
			theTextToken.tokenLength = 0;
			break;

		case cChar:
			if (index<0)
				theTextToken.tokenOffset = theTextToken.tokenOffset+index+1+theTextToken.tokenLength;
			else
				theTextToken.tokenOffset = theTextToken.tokenOffset+index-1;
			theTextToken.tokenLength = 1;
			break;

		case cWord:
			wordStartChar = theTextToken.tokenOffset-1;
			wordLength    = theTextToken.tokenLength;

			GetWordInfo(index, theHTE, &wordStartChar, &wordLength);/*zero based*/

			theTextToken.tokenOffset = wordStartChar+1;
			theTextToken.tokenLength = wordLength;
			break;

		case cLine:
			wordStartChar = theTextToken.tokenOffset-1;
			wordLength    = theTextToken.tokenLength;

			GetLineInfo(index, theHTE, &wordStartChar, &wordLength);

			theTextToken.tokenOffset = wordStartChar+1;
			theTextToken.tokenLength = wordLength;
			break;
		default: /* case cText */
			break;
		}
		break;

	case formRange:
		/* coerce the selection data into an AERecord */

		 myErr = AECoerceDesc(selectionData, typeAERecord, &selectionRecord);

		/* get the start object as a text token -
				this will reenter this proc but as formAbsolutePosition via the coercion handler*/

		myErr =
			AEGetKeyPtr(
				&selectionRecord,
				keyAERangeStart,
				typeMyText,
				&returnedType,
				(Ptr)&startText,
				sizeof(startText),
				&actSize);

		/* now do the same for the stop object */

		if (myErr==noErr)
			myErr =
				AEGetKeyPtr(
					&selectionRecord,
					keyAERangeStop,
					typeMyText,
					&returnedType,
					(Ptr)&stopText,
					sizeof(stopText),
					&actSize);

		if (myErr==noErr)
			if ((theTextToken.tokenWindow != stopText.tokenWindow) ||
				  (theTextToken.tokenWindow != startText.tokenWindow))
				myErr = errAECorruptData;	/* or whatever */

		theTextToken.tokenOffset  = startText.tokenOffset;
		theTextToken.tokenLength  = stopText.tokenOffset + stopText.tokenLength - startText.tokenOffset;

		myErr = AEDisposeDesc(&selectionRecord);
		break;
	}

	/* return theTextToken in a descriptor */

	myErr =
		AECreateDesc(
			typeMyText,
			(Ptr)&theTextToken,
			sizeof(theTextToken),
			value);

	return myErr;
}	/* TextElemFromWndwPropAccessor */

pascal OSErr TextElemFromTextAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr       myErr;
	Size        actSize;
	long        index;
	TextToken   theTextToken;
	AERecord    selectionRecord;
	TextToken   startText;
	TextToken   stopText;
	DescType    returnedType;
	AEDesc      textDesc;
	TEHandle    theHTE;
	short       wordStartChar;
	short       wordLength;
	DPtr        theDocument;

	myErr = -1700;	/* or whatever */

	/* do some checking for robustness' sake */

	if (
		((wantClass != cText) && (wantClass != cChar) && (wantClass != cSpot) && (wantClass != cLine) && (wantClass != cWord)) ||
		((form != formAbsolutePosition) && (form != formRange))
	)
		return errAEWrongDataType;

	/* let's get the src text */

	myErr = AECoerceDesc(container, typeMyText, &textDesc);
	GetRawDataFromDescriptor(&textDesc, (Ptr)&theTextToken, sizeof(theTextToken), &actSize);

	myErr = AEDisposeDesc(&textDesc);

	theDocument = DPtrFromWindowPtr(theTextToken.tokenWindow);
	theHTE      = theDocument->theText;

	switch (form) {
	case formAbsolutePosition:
		myErr = GetLongIntFromDescriptor(selectionData, &index);

		switch (wantClass) {
		case cSpot:
			if (index<0)
				theTextToken.tokenOffset = theTextToken.tokenOffset+index+1+theTextToken.tokenLength;
			else
				theTextToken.tokenOffset = theTextToken.tokenOffset+index-1;
			theTextToken.tokenLength = 0;
			break;

		case cChar:
			if (index<0)
				theTextToken.tokenOffset = theTextToken.tokenOffset+index+1+theTextToken.tokenLength;
			else
				theTextToken.tokenOffset = theTextToken.tokenOffset+index-1;
			theTextToken.tokenLength = 1;
			break;

		case cWord:
			wordStartChar = theTextToken.tokenOffset-1;
			wordLength    = theTextToken.tokenLength;

			GetWordInfo(index, theHTE, &wordStartChar, &wordLength);/*zero based*/

			theTextToken.tokenOffset = wordStartChar+1;
			theTextToken.tokenLength = wordLength;
			break;

		case cLine:
			wordStartChar = theTextToken.tokenOffset-1;
			wordLength    = theTextToken.tokenLength;

			GetLineInfo(index, theHTE, &wordStartChar, &wordLength);

			theTextToken.tokenOffset = wordStartChar+1;
			theTextToken.tokenLength = wordLength;
			break;
		}
		break;

	case formRange:
		/* coerce the selection data into an AERecord */

		 myErr = AECoerceDesc(selectionData, typeAERecord, &selectionRecord);

		/* get the start object as a text token -
				this will reenter this proc but as formAbsolutePosition via the coercion handler*/

		myErr =
			AEGetKeyPtr(
				&selectionRecord,
				keyAERangeStart,
				typeMyText,
				&returnedType,
				(Ptr)&startText,
				sizeof(startText),
				&actSize);

		/* now do the same for the stop object */

		if (myErr==noErr)
			myErr =
				AEGetKeyPtr(
					&selectionRecord,
					keyAERangeStop,
					typeMyText,
					&returnedType,
					(Ptr)&stopText,
					sizeof(stopText),
					&actSize);

		if (myErr==noErr)
			if ((theTextToken.tokenWindow != stopText.tokenWindow) ||
				  (theTextToken.tokenWindow != startText.tokenWindow))
				myErr = errAECorruptData;	/* or whatever */

		theTextToken.tokenOffset  = startText.tokenOffset;
		theTextToken.tokenLength  = stopText.tokenOffset + stopText.tokenLength - startText.tokenOffset;

		myErr = AEDisposeDesc(&selectionRecord);
		break;
	}

	/* return theTextToken in a descriptor */

	myErr =
		AECreateDesc(
			typeMyText,
			(Ptr)&theTextToken,
			sizeof(theTextToken),
			value);

	return myErr;
}	/* TextElemFromTextAccessor */

pascal OSErr PropertyFromTextAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr         myErr;
	OSErr         ignoreErr;
	TextToken     theTextToken;
	DescType      theProperty;
	AEDesc        textDesc;
	AEDesc        propDesc;
	Size          actualSize;
	textPropToken myTextProp;

	value->dataHandle   = nil;
	textDesc.dataHandle = nil;
	propDesc.dataHandle = nil;

	if ((wantClass != cProperty) || (form != formPropertyID)) {
		return errAEWrongDataType;
	}

	/* get the text token */
	myErr = AECoerceDesc(container, typeMyText, &textDesc);
	GetRawDataFromDescriptor(&textDesc, (Ptr)&theTextToken, sizeof(theTextToken), &actualSize);

	/* get the property */
	myErr = AECoerceDesc(selectionData, typeType, &propDesc);
	GetRawDataFromDescriptor(&propDesc, (Ptr)&theProperty, sizeof(theProperty), &actualSize);

	/*
		Combine the two into single token
	*/
	myTextProp.propertyTextToken = theTextToken;
	myTextProp.propertyProperty  = theProperty;

	myErr = AECreateDesc(typeMyTextProp, (Ptr)&myTextProp, sizeof(myTextProp), value);

	if (textDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&textDesc);

	if (propDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&propDesc);

	return myErr;
}	/* PropertyFromTextAccessor */

pascal OSErr PropertyFromWndwAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr           myErr;
	OSErr           ignoreErr;
	WindowToken     theWindowToken;
	DescType        theProperty;
	AEDesc          windowDesc;
	AEDesc          propDesc;
	Size            actualSize;
	windowPropToken myWindowProp;

	value->dataHandle     = nil;
	windowDesc.dataHandle = nil;
	propDesc.dataHandle   = nil;

	if ((wantClass != cProperty) || (form != formPropertyID)) {
		return errAEWrongDataType;
	}

	/* get the window token - it's the container */
	myErr = AECoerceDesc(container, typeMyWndw, &windowDesc);
	GetRawDataFromDescriptor(&windowDesc, (Ptr)&theWindowToken, sizeof(theWindowToken), &actualSize);

	/* Check the window exists */
	if (theWindowToken==nil)
		myErr = errAEIllegalIndex;
	else {

		/* get the property - it's in the selection data */

		myErr = AECoerceDesc(selectionData, typeType, &propDesc);
		GetRawDataFromDescriptor(&propDesc, (Ptr)&theProperty, sizeof(theProperty), &actualSize);

		myWindowProp.tokenWindowToken = theWindowToken;
		myWindowProp.tokenProperty    = theProperty;

		myErr = AECreateDesc(typeMyWindowProp, (Ptr)&myWindowProp, sizeof(myWindowProp), value);
	}

	if (windowDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&windowDesc);

	if (propDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&propDesc);

	return myErr;
}	/* PropertyFromWndwAccessor */

pascal OSErr PropertyFromWndwPropAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr           	myErr;
	OSErr           	ignoreErr;
	windowPropToken 	theWindowPropToken;
	textPropToken 		myTextProp;
	DescType        	theProperty;
	AEDesc          	windowPropDesc;
	AEDesc          	propDesc;
	Size            	actualSize;
	TEHandle    		theHTE;
	DPtr        		theDocument;

	value->dataHandle     		= nil;
	windowPropDesc.dataHandle 	= nil;
	propDesc.dataHandle   		= nil;

	if ((wantClass != cProperty) || (form != formPropertyID)) {
		return errAEWrongDataType;
	}

	/* get the window property token*/
	myErr = AECoerceDesc(container, typeMyWindowProp, &windowPropDesc);
	GetRawDataFromDescriptor(&windowPropDesc, (Ptr)&theWindowPropToken, sizeof(theWindowPropToken), &actualSize);

	/* get the property */
	myErr = AECoerceDesc(selectionData, typeType, &propDesc);
	GetRawDataFromDescriptor(&propDesc, (Ptr)&theProperty, sizeof(theProperty), &actualSize);

	if (theWindowPropToken.tokenProperty != pSelection)
		myErr = errAEEventNotHandled;
	else {
		theDocument = DPtrFromWindowPtr(theWindowPropToken.tokenWindowToken);
		theHTE      = theDocument->theText;
		
		myTextProp.propertyTextToken.tokenWindow 	= theWindowPropToken.tokenWindowToken;
		myTextProp.propertyTextToken.tokenOffset	= (*theHTE)->selStart + 1;
		myTextProp.propertyTextToken.tokenLength	= (*theHTE)->selEnd - (*theHTE)->selStart;
		myTextProp.propertyProperty					= theProperty;

		myErr = AECreateDesc(typeMyTextProp, (Ptr)&myTextProp, sizeof(myTextProp), value);
	}

	if (windowPropDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&windowPropDesc);

	if (propDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&propDesc);

	return myErr;
}	/* PropertyFromWndwPropAccessor */

pascal OSErr PropertyFromNullAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon)
#endif

	OSErr					myErr;
	OSErr					ignoreErr;
	appToken				theApplToken;
	DescType				theProperty;
	AEDesc				applDesc;
	AEDesc				propDesc;
	Size					actualSize;
	applPropToken		myApplProp;
	windowPropToken	myWindowProp;

	value->dataHandle     = nil;
	applDesc.dataHandle   = nil;
	propDesc.dataHandle   = nil;

	if ((wantClass != cProperty) || (form != formPropertyID)) {
		return errAEWrongDataType;
	}

	/* get the application token - it's the container */
	
	if (containerClass != typeNull) {
		myErr = AECoerceDesc(container, typeMyAppl, &applDesc);
		GetRawDataFromDescriptor(&applDesc, (Ptr)&theApplToken, sizeof(theApplToken), &actualSize);
	} else {
		theApplToken.highLongOfPSN = 0;
		theApplToken.lowLongOfPSN  = kCurrentProcess;
	}
	
	/* get the property - it's in the selection data */

	myErr = AECoerceDesc(selectionData, typeType, &propDesc);
	GetRawDataFromDescriptor(&propDesc, (Ptr)&theProperty, sizeof(theProperty), &actualSize);

	switch (theProperty) {
	case pUserSelection:
		theProperty = pSelection;
		/* Fall through */
	case pSelection:
		if (myWindowProp.tokenWindowToken = FrontWindow()) {
			myWindowProp.tokenProperty    = theProperty;

			myErr = AECreateDesc(typeMyWindowProp, (Ptr)&myWindowProp, sizeof(myWindowProp), value);
		} else
			myErr = errAEIllegalIndex;
			
		break;
	default:
		/*
			Combine the two into single token
		*/
		myApplProp.tokenApplToken    = theApplToken;
		myApplProp.tokenApplProperty = theProperty;
	
		myErr = AECreateDesc(typeMyApplProp, (Ptr)&myApplProp, sizeof(myApplProp), value);
		break;
	}
	
	if (applDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&applDesc);

	if (propDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&propDesc);

	return myErr;
}	/* PropertyFromApplAccessor */

pascal OSErr MenuNameToMenuToken(const Str255 theName, MenuToken *theToken)
{
	short   index;

	for (index=appleM; index<kLastMenu; index++) {
		if (IUEqualString(theName, (**(myMenus[index])).menuData)==0) {
			theToken->theTokenMenu = myMenus[index];
			theToken->theTokenID   = index+appleID;
			return noErr;
		}
	}
	return errAEIllegalIndex;
}

pascal OSErr MenuFromNullAccessor(
	DescType      wantClass,
	const AEDesc  *container,
	DescType      containerClass,
	DescType      form,
	const AEDesc  *selectionData,
	AEDesc        *value,
	long          theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (container,theRefCon)
#endif

	OSErr       myErr;
	Str255      nameStr;
	MenuToken   theMenu;
	short       index;
	AEDesc      resultDesc;

	myErr = errAEBadKeyForm;	/* or whatever */

	value->dataHandle     = nil;
	resultDesc.dataHandle = nil;

	/*
		should only be called with wantClass = cMenu and
		with containerClass = typeNull or typeMyAppl.
		Currently accept as either formName or formAbsolutePosition
	*/

	if (
		(wantClass != cMenu) ||
		((containerClass != typeNull) && (containerClass != typeMyAppl)) ||
		!((form == formName) || (form == formAbsolutePosition))
	)
		return errAEWrongDataType;

	if (form == formName) {
		myErr = GetPStringFromDescriptor(selectionData, (char *)nameStr);
		myErr = MenuNameToMenuToken(nameStr, &theMenu);
	}

	if (form == formAbsolutePosition) {
		myErr 	= GetIntegerFromDescriptor(selectionData, &index);
		if (index<0)
			index = kLastMenu + index + 1;

		if (index>0 && index<kLastMenu+1) {
			theMenu.theTokenMenu = myMenus[index-1];
			theMenu.theTokenID   = index-1+appleID;
		} else
			myErr = errAEIllegalIndex;	/* or whatever */
	}

	if (myErr == noErr)
		myErr = AECreateDesc(typeMyMenu, (Ptr)&theMenu, sizeof(theMenu), value);

	return myErr;
}	/* MenuFromNullAccessor */

pascal OSErr PropertyFromMenuAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr         myErr;
	OSErr         ignoreErr;
	MenuToken     theMenuToken;
	DescType      theProperty;
	AEDesc        menuDesc;
	AEDesc        propDesc;
	Size          actualSize;
	MenuPropToken myMenuProp;

	value->dataHandle     = nil;
	menuDesc.dataHandle   = nil;
	propDesc.dataHandle   = nil;

	if ((wantClass != cProperty) || (form != formPropertyID)) {
		return errAEWrongDataType;
	}

	/* get the menu token - it's the container */

	myErr = AECoerceDesc(container, typeMyMenu, &menuDesc);
	GetRawDataFromDescriptor(&menuDesc, (Ptr)&theMenuToken, sizeof(theMenuToken), &actualSize);

	/* get the property - it's in the selection data */

	myErr = AECoerceDesc(selectionData, typeType, &propDesc);
	GetRawDataFromDescriptor(&propDesc, (Ptr)&theProperty, sizeof(theProperty), &actualSize);

	/*
		Combine the two into single token
	*/
	myMenuProp.theMenuToken = theMenuToken;
	myMenuProp.theMenuProp  = theProperty;

	myErr = AECreateDesc(typeMyMenuProp, (Ptr)&myMenuProp, sizeof(myMenuProp), value);

	if (menuDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&menuDesc);

	if (propDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&propDesc);

	return myErr;
}	/* PropertyFromMenuAccessor */

pascal OSErr PropertyFromMenuItemAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon, containerClass)
#endif

	OSErr         myErr;
	OSErr         ignoreErr;
	MenuItemToken theMenuItemToken;
	DescType      theProperty;
	AEDesc        itemDesc;
	AEDesc        propDesc;
	Size          actualSize;
	MenuItemPropToken myItemProp;

	value->dataHandle     = nil;
	itemDesc.dataHandle   = nil;
	propDesc.dataHandle   = nil;

	if ((wantClass != cProperty) || (form != formPropertyID)) {
		return errAEWrongDataType;
	}

	/* get the menu token - it's the container */

	myErr = AECoerceDesc(container, typeMyMenuItem, &itemDesc);
	GetRawDataFromDescriptor(&itemDesc, (Ptr)&theMenuItemToken, sizeof(theMenuItemToken), &actualSize);

	/* get the property - it's in the selection data */

	myErr = AECoerceDesc(selectionData, typeType, &propDesc);
	GetRawDataFromDescriptor(&propDesc, (Ptr)&theProperty, sizeof(theProperty), &actualSize);
	/*
		Combine the two into single token
	*/
	myItemProp.theItemToken  = theMenuItemToken;
	myItemProp.theItemProp   = theProperty;

	myErr = AECreateDesc(typeMyItemProp, (Ptr)&myItemProp, sizeof(myItemProp), value);

	if (itemDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&itemDesc);

	if (propDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&propDesc);

	return myErr;
}	/* PropertyFromMenuItemAccessor */

pascal OSErr ItemNameToItemIndex(const Str255 theName, MenuHandle theMenu, short *theIndex)
{
	short   index;
	short   maxItems;
	Str255  menuName;

	maxItems = CountMItems(theMenu);

	for (index=1; index<=maxItems; index++) {
		GetMenuItemText(theMenu, index, menuName);
		if (IUEqualString(theName, menuName)==0) {
			*theIndex = index;
			return noErr;
		}
	}
	return errAEIllegalIndex;
}

pascal OSErr MenuItemFromMenuAccessor(
	DescType     wantClass,
	const AEDesc *container,
	DescType     containerClass,
	DescType     form,
	const AEDesc *selectionData,
	AEDesc       *value,
	long         theRefCon)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (theRefCon)
#endif

	OSErr         myErr;
	OSErr         ignoreErr;
	MenuItemToken theMenuItemToken;
	MenuToken     theMenuToken;
	AEDesc        menuDesc;
	Size          actualSize;
	Str255        nameStr;
	short         maxItems;
	short         index;

	value->dataHandle     = nil;
	menuDesc.dataHandle   = nil;

	if (
		(wantClass != cMenuItem) || (containerClass != cMenu) ||
		((form != formAbsolutePosition) && (form != formName))
	) {
		return errAEWrongDataType;
	}

	/* get the menu token - it's the container */

	myErr = AECoerceDesc(container, typeMyMenu, &menuDesc);
	GetRawDataFromDescriptor(&menuDesc, (Ptr)&theMenuToken, sizeof(theMenuToken), &actualSize);

	if (form==formAbsolutePosition) {
		myErr = GetIntegerFromDescriptor(selectionData, &index);
		maxItems = CountMItems(theMenuToken.theTokenMenu);

		if (index<0)
			index = maxItems + index + 1;

		if ((index<1) || (index>maxItems))
		  myErr = errAEIllegalIndex;
	}

	if (form == formName) {
		myErr  = GetPStringFromDescriptor(selectionData, (char *)nameStr);
		myErr  = ItemNameToItemIndex(nameStr, theMenuToken.theTokenMenu, &index);
	}

	/*
		Combine the two into single token
	*/

	theMenuItemToken.theMenuToken  = theMenuToken;
	theMenuItemToken.theTokenItem  = index;

	if (myErr==noErr)
		myErr = AECreateDesc(typeMyMenuItem, (Ptr)&theMenuItemToken, sizeof(theMenuItemToken), value);

	if (menuDesc.dataHandle)
		ignoreErr = AEDisposeDesc(&menuDesc);

	return myErr;
}	/* MenuItemFromMenuAccessor */

/*******************************************************************************/
/*
	Stuff for counting objects
*/

pascal OSErr MyCountProc(
	DescType     desiredType,
	DescType     containerClass,
	const AEDesc *container,
	long         *result)
/* so far all I count is:
  (1) the number of active windows in the app;
  (2) the number of words in a window
*/
{
	OSErr       myErr;
	WindowToken theWindowToken;
	DPtr        theDocument;
	TEHandle    theHTE;
	AEDesc      newDesc;
	short       wordStart;
	short       wordLength;
	Size        tokenSize;
	TextToken   theTextToken;

	*result = -1;	/* easily recognized illegal value */

	myErr = errAEWrongDataType;

	if (desiredType == cWindow || desiredType == cDocument) {
		if ((containerClass == typeNull) || (containerClass == cApplication)) {
			*result = CountWindows();
			myErr = noErr;
		}
	}

	if ((desiredType == cWord) || (desiredType == cLine) || (desiredType == cChar) || (desiredType == cText)) {
		myErr = AECoerceDesc(container, typeMyWndw, &newDesc);
		if (newDesc.descriptorType!=typeNull) {
			GetRawDataFromDescriptor(
				&newDesc,
				(Ptr)&theWindowToken,
				sizeof(theWindowToken),
				&tokenSize);

			myErr = AEDisposeDesc(&newDesc);

			if (theWindowToken==nil)
				myErr = errAEIllegalIndex;
			else {
				theDocument = DPtrFromWindowPtr(theWindowToken);
				theHTE      = theDocument->theText;

				switch (desiredType) {
				case cWord:
					wordStart   = 0;
					wordLength  = (**theHTE).teLength;
					*result     = CountWords(theHTE, wordStart, wordLength);
					break;
				case cChar:
					*result = (**theHTE).teLength;
					break;
				case cLine:
					*result = CountLines(theHTE);
					break;
				case cText:
					*result = 1;
					break;
				}
			}
		} 
		
		AECoerceDesc(container, typeMyText, &newDesc);
		if (newDesc.descriptorType!=typeNull) {
			GetRawDataFromDescriptor(
				&newDesc,
				(Ptr)&theTextToken,
				sizeof(theTextToken),
				&tokenSize);

			myErr = AEDisposeDesc(&newDesc);

			theDocument = DPtrFromWindowPtr(theTextToken.tokenWindow);
			theHTE      = theDocument->theText;

			switch (desiredType) {
			case cWord:
				wordStart   = theTextToken.tokenOffset-1;
				wordLength  = theTextToken.tokenLength;
				*result     = CountWords(theHTE, wordStart, wordLength);
				break;
			case cChar:
				*result = theTextToken.tokenLength;
				break;
			case cLine:
				*result	=
					LineOfOffset(theHTE,theTextToken.tokenOffset-1) -
					LineOfOffset(theHTE,theTextToken.tokenOffset+theTextToken.tokenLength-1)
					+1;
				break;
			case cText:
				*result = 1;
				break;
			}
		}
	}

	return myErr;
}	/* MyCountProc */

/*******************************************************************************/
/*
	Coercion Handlers - Allow AEResolve to do the hard work
*/
pascal OSErr CoerceObjToAnything(
	const AEDesc *theAEDesc,
	DescType     toType,
	long         handlerRefCon,
	AEDesc       *result)
/*
	CoerceObjToAnything functions by using AEResolve to do the hard
	work.
*/
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused (handlerRefCon)
#endif

	OSErr  myErr;
	AEDesc objDesc;

	myErr = errAECoercionFail;

	result->dataHandle = nil;
	objDesc.dataHandle = nil;


	if (theAEDesc->descriptorType != typeObjectSpecifier) {
		return errAEWrongDataType;
	}

	/* resolve the object specifier */
	myErr = AEResolve(theAEDesc, kAEIDoMinimum, &objDesc);

	/* hopefully it's the right type by now, but we'll give it a nudge */
	if (myErr==noErr) {
		myErr = AECoerceDesc(&objDesc, toType, result);
		myErr = AEDisposeDesc(&objDesc);
	}

	if (result->descriptorType!=toType) {
		/*DebugStr('COTA - Not of requested type');*/
	}

	return myErr;
}	/* CoerceObjToAnything */

/*******************************************************************************/

pascal OSErr Text2FSSpec(
	DescType type, Ptr path, Size size, 
	DescType to, long refCon, AEDesc * result)
{
	OSErr			err;
	char			file[256];
	FSSpec		spec;
	CInfoPBRec	info;
	
	if (size > 255)
		return errAECoercionFail;
		
	memcpy(file, path, size);
	file[size] = 0;
	
	if (err = GUSIPath2FSp(file, &spec))
		return err;
	if (err = GUSIFSpGetCatInfo(&spec, &info))
		return err;
	
	return AECreateDesc(typeFSS, (Ptr) &spec, sizeof(FSSpec), result);
}

/* -----------------------------------------------------------------------
		Name: 			InitAppleEvents
		Purpose:		Initialise the AppleEvent dispatch table
	 -----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

#define noRefCon -1

pascal void InitAppleEvents(void)
{
	AECoercionHandlerUPP	handler;
	long						refCon;
	Boolean					isDesc;

 	gBigBrother = 0;
	gCharsInBuffer = 0;
	gTypingBuffer  = (char *)NewPtr(32000);
	gTypingTargetObject.dataHandle = 0;

	/*set up the dispatch table for the four standard apple events*/

	AEInstallEventHandler( kCoreEventClass, kAEOpenApplication, NewAEEventHandlerProc(DoOpenApp), noRefCon, false) ;
	AEInstallEventHandler( kCoreEventClass, kAEOpenDocuments,   NewAEEventHandlerProc(DoOpenDocument), noRefCon, false) ;
	AEInstallEventHandler( kCoreEventClass, kAEPrintDocuments,  NewAEEventHandlerProc(DoPrintDocuments), noRefCon, false) ;
	AEInstallEventHandler( kCoreEventClass, kAEQuitApplication, NewAEEventHandlerProc(MyQuit), noRefCon, false) ;

	AEInstallEventHandler( MPAppSig,	'STOP',			NewAEEventHandlerProc(DoStopScript),	noRefCon,	false) ;
	AEInstallEventHandler( MPAppSig, 		  kAEOpenDocuments,   NewAEEventHandlerProc(DoOpenDocument), 	1, false) ;
	AEInstallEventHandler( MPAppSig, 		  'DATA',   			 NewAEEventHandlerProc(Relay), 			 	0, false) ;
	AEInstallEventHandler( MPAppSig, 		  'xEDT',   			 NewAEEventHandlerProc(DoExternalEditor), 0, false) ;
	AEInstallEventHandler( MPAppSig, 		  'xUPD',   			 NewAEEventHandlerProc(DoExternalEditor), 1, false) ;
	AEInstallEventHandler( typeWildCard, 	  'FMod',   			 NewAEEventHandlerProc(DoExternalEditor), 2, false) ;
	AEInstallEventHandler( typeWildCard, 	  'FCls',   			 NewAEEventHandlerProc(DoExternalEditor), 3, false) ;
	/* set up the dispatch table for the core AppleEvents for text */

	AEInstallEventHandler( kAECoreSuite,     kAEDelete, NewAEEventHandlerProc(DoDeleteEdit),noRefCon, false);

	AEInstallEventHandler( kAEMiscStandards, kAECut,    NewAEEventHandlerProc(DoCutEdit),   noRefCon, false);
	AEInstallEventHandler( kAEMiscStandards, kAECopy,   NewAEEventHandlerProc(DoCopyEdit),  noRefCon, false);
	AEInstallEventHandler( kAEMiscStandards, kAEPaste,  NewAEEventHandlerProc(DoPasteEdit), noRefCon, false);
	AEInstallEventHandler( kAECoreSuite,     kAESetData,NewAEEventHandlerProc(DoSetData),   noRefCon, false);
	AEInstallEventHandler( kAECoreSuite,     kAEGetData,NewAEEventHandlerProc(DoGetData),   noRefCon, false);
	AEInstallEventHandler( kAECoreSuite,     kAEGetDataSize,NewAEEventHandlerProc(DoGetDataSize),   noRefCon, false);

	AEInstallEventHandler( kAECoreSuite, kAECountElements,   NewAEEventHandlerProc(HandleNumberOfElements),   noRefCon, false);
	AEInstallEventHandler( kAECoreSuite, kAECreateElement,   NewAEEventHandlerProc(DoNewElement),   noRefCon, false);
	AEInstallEventHandler( kAECoreSuite, kAEDoObjectsExist,  NewAEEventHandlerProc(DoIsThereA),   noRefCon, false);

	AEInstallEventHandler( kAECoreSuite,     kAEClose,  NewAEEventHandlerProc(DoCloseWindow),noRefCon, false);
	AEInstallEventHandler( kAECoreSuite,     kAESave,   NewAEEventHandlerProc(DoSaveWindow),noRefCon, false);
	AEInstallEventHandler( kAEMiscStandards, kAERevert, NewAEEventHandlerProc(DoRevertWindow),noRefCon, false);

	AEInstallEventHandler( kAEMiscStandards, kAEMakeObjectsVisible, 	NewAEEventHandlerProc(HandleShowSelection),   noRefCon, false);
	AEInstallEventHandler( kAEMiscStandards, kAESelect, 					NewAEEventHandlerProc(HandleSelect),   noRefCon, false);
	AEInstallEventHandler( kAEMiscStandards, kAEDoScript,           	NewAEEventHandlerProc(DoScript), noRefCon, false);

	/* Now look for recording notifications */

	AEInstallEventHandler( kCoreEventClass, kAEStartedRecording, NewAEEventHandlerProc(HandleStartRecording), noRefCon, false);
	AEInstallEventHandler( kCoreEventClass, kAEStoppedRecording, NewAEEventHandlerProc(HandleStopRecording), noRefCon, false);

	/* Now Put in the required object accessors */

	AESetObjectCallbacks(nil,NewOSLCountProc(MyCountProc),nil,nil,nil,nil,nil);


	AEInstallObjectAccessor(cApplication, typeNull,   NewOSLAccessorProc(ApplicationFromNullAccessor),  0,false);
	AEInstallObjectAccessor(cProperty,    typeNull, 	NewOSLAccessorProc(PropertyFromNullAccessor),0,false);
	AEInstallObjectAccessor(cProperty,    typeMyAppl, NewOSLAccessorProc(PropertyFromNullAccessor),0,false);
	AEInstallObjectAccessor(cWindow,      typeNull,   NewOSLAccessorProc(WindowFromNullAccessor),  0,false);
	AEInstallObjectAccessor(cWindow,		typeMyAppl, NewOSLAccessorProc(WindowFromNullAccessor),  0,false);
	AEInstallObjectAccessor(cDocument,    typeNull,   NewOSLAccessorProc(WindowFromNullAccessor),  0,false);
	AEInstallObjectAccessor(cDocument,		typeMyAppl, NewOSLAccessorProc(WindowFromNullAccessor),  0,false);

	AEInstallObjectAccessor(cProperty,		typeMyWndw,NewOSLAccessorProc(PropertyFromWndwAccessor),0,false);
	AEInstallObjectAccessor(cChar,			typeMyWndw,NewOSLAccessorProc(TextElemFromWndwAccessor),0,false);
	AEInstallObjectAccessor(cSpot,			typeMyWndw,NewOSLAccessorProc(TextElemFromWndwAccessor),0,false);
	AEInstallObjectAccessor(cWord,			typeMyWndw,NewOSLAccessorProc(TextElemFromWndwAccessor),0,false);
	AEInstallObjectAccessor(cLine,			typeMyWndw,NewOSLAccessorProc(TextElemFromWndwAccessor),0,false);
	AEInstallObjectAccessor(cText,			typeMyWndw,NewOSLAccessorProc(TextElemFromWndwAccessor),0,false);

	AEInstallObjectAccessor(cProperty,		typeMyWindowProp,NewOSLAccessorProc(PropertyFromWndwPropAccessor),0,false);
	AEInstallObjectAccessor(cChar,			typeMyWindowProp,NewOSLAccessorProc(TextElemFromWndwPropAccessor),0,false);
	AEInstallObjectAccessor(cSpot,			typeMyWindowProp,NewOSLAccessorProc(TextElemFromWndwPropAccessor),0,false);
	AEInstallObjectAccessor(cWord,			typeMyWindowProp,NewOSLAccessorProc(TextElemFromWndwPropAccessor),0,false);
	AEInstallObjectAccessor(cLine,			typeMyWindowProp,NewOSLAccessorProc(TextElemFromWndwPropAccessor),0,false);
	AEInstallObjectAccessor(cText,			typeMyWindowProp,NewOSLAccessorProc(TextElemFromWndwPropAccessor),0,false);

	AEInstallObjectAccessor(cProperty,		typeMyText,NewOSLAccessorProc(PropertyFromTextAccessor),0,false);
	AEInstallObjectAccessor(cChar,			typeMyText,NewOSLAccessorProc(TextElemFromTextAccessor),0,false);
	AEInstallObjectAccessor(cWord,			typeMyText,NewOSLAccessorProc(TextElemFromTextAccessor),0,false);
	AEInstallObjectAccessor(cSpot,			typeMyText,NewOSLAccessorProc(TextElemFromTextAccessor),0,false);
	AEInstallObjectAccessor(cLine,			typeMyText,NewOSLAccessorProc(TextElemFromTextAccessor),0,false);
	AEInstallObjectAccessor(cText,			typeMyText,NewOSLAccessorProc(TextElemFromTextAccessor),0,false);

	AEInstallObjectAccessor(cMenu,			typeNull,       NewOSLAccessorProc(MenuFromNullAccessor),    0,false);
	AEInstallObjectAccessor(cProperty,		typeMyMenu,     NewOSLAccessorProc(PropertyFromMenuAccessor),0,false);
	AEInstallObjectAccessor(cProperty,		typeMyMenuItem, NewOSLAccessorProc(PropertyFromMenuItemAccessor),0,false);
	AEInstallObjectAccessor(cMenuItem,		typeMyMenu,     NewOSLAccessorProc(MenuItemFromMenuAccessor),0,false);

	/* Now the coercion handlers */

	AEInstallCoercionHandler(typeObjectSpecifier,typeMyAppl,      (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyWndw,      (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyText,      (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyTextProp,  (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyWindowProp,(AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyApplProp,  (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyMenu,      (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyMenuProp,  (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyMenuItem,  (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);
	AEInstallCoercionHandler(typeObjectSpecifier,typeMyItemProp,  (AECoercionHandlerUPP)NewAECoerceDescProc(CoerceObjToAnything),0,true,false);

	AEInstallCoercionHandler(typeChar,typeFSS,  (AECoercionHandlerUPP)NewAECoercePtrProc(Text2FSSpec),0,false,false);
} /* InitAppleEvents */
