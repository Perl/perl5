/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPWindow.c		-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPWindow.c,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.4  1998/04/07 01:46:48  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:59  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:10  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:11:06  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:52:40  neeri
Inline Input.

Revision 1.1  1994/02/27  23:02:22  neeri
Initial revision

Revision 0.4  1993/08/17  00:00:00  neeri
A little more defensiveness

Revision 0.3  1993/08/06  00:00:00  neeri
Draw pretty icons

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#include <Resources.h>
#include <Scrap.h>
#include <Packages.h>
#include <PLStringFuncs.h>
#include <Script.h>
#include <Icons.h>
#include <ControlDefinitions.h>

#include "MPWindow.h"
#include "MPConsole.h"
#include "MPEditions.h"

#define	kControlInvisible    0
#define	kControlVisible      0xFF
#define	kScrollbarWidth 	   16
#define	kScrollbarAdjust 	   (kScrollbarWidth - 1)
#define	kScrollTweek   		2
#define	kTextOffset				5
#define	kButtonScroll  		10

#define	kMaxPages       	   1000 /* Assumes pages > 32 pixels high */

#define	kHOffset 					   20   /* Stagger window offsets */
#define	kVOffset 					   20

#define	kTBarHeight 			   20
#define	kMBarHeight 			   20

typedef short PageEndsArray[kMaxPages];

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal DPtr DPtrFromWindowPtr(WindowPtr w)
{
	if (w && (GetWindowKind(w) == PerlWindowKind))
		return((DPtr)GetWRefCon(w));
	else
		return(nil);
} /* DPtrFromWindowPtr */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

/*
  Scroll the TERec around to match up to the potentially updated scrollbar
  values. This is really useful when the window resizes such that the
  scrollbars become inactive and the TERec had been previously scrolled.
*/
pascal void AdjustTE(DPtr theDoc)
{
	short    h;
	short    v;
	TEHandle myText;

	myText = theDoc->theText;
	h =
		(myText[0]->viewRect.left - myText[0]->destRect.left) -
		GetControlValue(theDoc->hScrollBar) + kTextOffset;

	v =
		(myText[0]->viewRect.top - myText[0]->destRect.top) -
		GetControlValue(theDoc->vScrollBar) + kTextOffset;

	if (h || v) {
		TEScroll(h, v, theDoc->theText);
		DrawPageExtras(theDoc);
	}
}  /* AdjustTE */


/*Calculate the new control maximum value and current value, whether it is the horizontal or
vertical scrollbar. The vertical max is calculated by comparing the number of lines to the
vertical size of the viewRect. The horizontal max is calculated by comparing the maximum document
width to the width of the viewRect. The current values are set by comparing the offset between
the view and destination rects. If necessary and we canRedraw, have the control be re-drawn by
calling ShowControl.*/

/*TEStyleSample-vertical max originally used line by line calculations-lineheight was a
constant value so it was easy to figure out what the range should be and pin the value
within range. Now we need to use max and min values in pixels rather than in nlines*/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal void AdjustHV(
	Boolean        isVert,
	ControlHandle  control,
	DPtr           theDoc,
	Boolean        canRedraw)
{
	TEHandle    docTE;
	short       value;
	short   		max;
	short   		oldValue;
	short   		oldMax;
	Rect   		sizeRect;
	Boolean		inflate;

	sizeRect = theDoc->pageSize;
	docTE    = theDoc->theText;

	oldValue = GetControlValue(control);
	oldMax   = GetControlMaximum(control);
	inflate  = 
		   (docTE[0]->selStart == docTE[0]->teLength) 
		&& (docTE[0]->hText[0][docTE[0]->teLength-1] == '\n');
	if (isVert)
		max = 
			(docTE[0]->nLines+inflate)*docTE[0]->lineHeight
		 - (docTE[0]->viewRect.bottom - docTE[0]->viewRect.top);
	else
		max = 20000 - (docTE[0]->viewRect.right - docTE[0]->viewRect.left);

	max += kTextOffset + kTextOffset; /* Allow over scroll by kTextOffset */

	if (max < 0)
		max = 0; /* check for negative values */

	SetControlMaximum(control, max);

	if (isVert)
		value = docTE[0]->viewRect.top - docTE[0]->destRect.top;
	else
		value = docTE[0]->viewRect.left - docTE[0]->destRect.left;

	value += kTextOffset;

	if (value < 0) {
		TEScroll(isVert ? 0 : value, isVert ? value : 0, docTE);
		DrawPageExtras(theDoc);

		value = 0;
	} else if (value > max) {
		TEScroll(isVert ? 0 : value-max, isVert ? value-max : 0, docTE);
		DrawPageExtras(theDoc);
		
		value = max; /* pin the value to within range */
	}
	SetControlValue(control, value);
	if (canRedraw && ((max != oldMax) || (value != oldValue)))
		ShowControl(control); /* check to see if the control can be re-drawn */
} /* AdjustHV */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

pascal void AdjustScrollValues(DPtr theDoc, Boolean canRedraw)
{
	AdjustHV(true,  theDoc->vScrollBar, theDoc, canRedraw);
	AdjustHV(false, theDoc->hScrollBar, theDoc, canRedraw);
}        /* AdjustScrollValues */

pascal void GetTERect(WindowPtr window, Rect  *teRect)
{
	 *teRect = window->portRect;
	 (*teRect).bottom -= kScrollbarAdjust; /* and for the scrollbars */
	 (*teRect).right  -= kScrollbarAdjust;
}         /* GetTERect */

/* Re-calculate the position and size of the viewRect and the scrollbars.
  kScrollTweek compensates for off-by-one requirements of the scrollbars
  to have borders coincide with the growbox. */

pascal void AdjustScrollSizes(DPtr theDoc)
{
	Rect    teRect;
	Rect    myPortRect;

	GetTERect(theDoc->theWindow, &teRect); /*start with teRect*/
	myPortRect = theDoc->theWindow->portRect;

	(*(theDoc->theText))->viewRect = teRect;

	MoveControl(theDoc->vScrollBar, myPortRect.right - kScrollbarAdjust, -1);
	SizeControl(
		theDoc->vScrollBar,
		kScrollbarWidth,
		(myPortRect.bottom - myPortRect.top) - (kScrollbarAdjust - kScrollTweek));

	MoveControl(theDoc->hScrollBar, 31, myPortRect.bottom - kScrollbarAdjust);
	SizeControl(
		theDoc->hScrollBar,
		(myPortRect.right - myPortRect.left) - (kScrollbarAdjust - kScrollTweek + 32),
		kScrollbarWidth);
}        /* AdjustScrollSizes */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

/* Turn off the controls by jamming a zero into their contrlVis fields
  (HideControl erases them and we don't want that). If the controls are to
  be resized as well, call the procedure to do that, then call the procedure
  to adjust the maximum and current values. Finally reset the controls
  to be visible if not in background. */

pascal void AdjustScrollbars(DPtr theDoc, Boolean  needsResize)
{
	Boolean	background = gInBackground || theDoc->theWindow != gActiveWindow;
	
	(*(theDoc->vScrollBar))->contrlVis = kControlInvisible; /* turn them off */
	(*(theDoc->hScrollBar))->contrlVis = kControlInvisible;

	if (needsResize) /* move and size if needed */
		AdjustScrollSizes(theDoc);

	AdjustScrollValues(theDoc, !needsResize && !background); /* fool with max and current value */

 	/* Now, restore visibility in case we never had to ShowControl during adjustment */

	if (!background) {
		(*(theDoc->vScrollBar))->contrlVis = kControlVisible; /* turn them on */
		(*(theDoc->hScrollBar))->contrlVis = kControlVisible;
	} else { /* make sure they stay invisible */
		if ((*(theDoc->vScrollBar))->contrlVis)
			HideControl(theDoc->vScrollBar);
		if ((*(theDoc->vScrollBar))->contrlVis)
			HideControl(theDoc->hScrollBar);
	}
}        /* AdjustScrollbars */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void GetWinContentRect(WindowPtr theWindow, Rect *r)
{
	*r         = theWindow->portRect;
	r->right  -= kScrollbarAdjust;
	r->bottom -= kScrollbarAdjust;
}  /* GetWinContentRect */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void InvalidateDocument(DPtr theDoc)
{
	GrafPtr oldPort;

	GetPort(&oldPort);
	SetPort(theDoc->theWindow);
	InvalRect(&theDoc->theWindow->portRect);
	SetPort(oldPort);
}

/* Called when the window has been resized to fix up the controls and content */

pascal void ResizeMyWindow(DPtr theDoc)
{
	AdjustScrollbars(theDoc, true);
	AdjustTE(theDoc);
	InvalidateDocument(theDoc);
}         /* ResizeWindow */

/* Called when the window has been resized to fix up the controls and content */

pascal void ResizePageSetupForDocument(DPtr theDoc)
{
	theDoc->pageSize = (*(theDoc->thePrintSetup))->prInfo.rPage;

	OffsetRect(&(theDoc->pageSize), -theDoc->pageSize.left, -theDoc->pageSize.top);

	(*(theDoc->theText))->destRect.right = (*(theDoc->theText))->destRect.left +
														theDoc->pageSize.right;

	TECalText(theDoc->theText);

	ResizeMyWindow(theDoc);
}         /* ResizePageSetupForDocument */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

/* Common algorithm for setting the new value of a control. It returns the actual amount
the value of the control changed. Note the pinning is done for the sake of returning
the amount the control value changed. */

pascal void CommonAction(ControlHandle control, short *amount)
{
	short   value;
	short   max;

	value   = GetControlValue(control); /* get current value */
	max     = GetControlMaximum(control); /* and max value */
	*amount = value - *amount;
	if (*amount < 0)
	  	*amount = 0;
	else if (*amount > max)
		*amount = max;

	SetControlValue(control, *amount);
	*amount = value - *amount; /* calculate true change */
}         /* CommonAction */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

/* Determines how much to change the value of the vertical scrollbar by and how
  much to scroll the TE record. */

pascal void VActionProc(ControlHandle control, short part)
{
	short           amount;
	WindowPtr       window;
	DPtr            theDoc;

 	if (part) {
	  	window = control[0]->contrlOwner;
		theDoc = DPtrFromWindowPtr(window);
		switch (part) {
		case kControlUpButtonPart:
		case kControlDownButtonPart:
			amount = 24;
			break;

		case kControlPageUpPart:
		case kControlPageDownPart:
			amount = (*(theDoc->theText))->viewRect.bottom -
						(*(theDoc->theText))->viewRect.top;
			break;
		}   /* case */

		if (part == kControlDownButtonPart || part == kControlPageDownPart)
		 	amount = -amount; /* reverse direction */

		CommonAction(control, &amount);

		if (amount) {
			TEScroll(0, amount, theDoc->theText);
			DrawPageExtras(theDoc);
		}
	}     /* if */
}  /* VActionProc */

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uVActionProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppControlActionProcInfo, VActionProc);
#else
#define uVActionProc *(ControlActionUPP)&VActionProc
#endif

#if !defined(powerc) && !defined(__powerc)
#pragma segment Main
#endif

/* Determines how much to change the value of the horizontal scrollbar by and how
  much to scroll the TE record. */

pascal void HActionProc(ControlHandle control, short part)
{
	short      amount;
	WindowPtr  window;
	DPtr       theDoc;

	if (part) {
		window = control[0]->contrlOwner;
		theDoc = DPtrFromWindowPtr(window);
		switch (part) {
		case  kControlUpButtonPart:
		case  kControlDownButtonPart:
			amount = kButtonScroll; /* a few pixels */
			break;
		case  kControlPageUpPart:
		case  kControlPageDownPart:
			amount = (*(theDoc->theText))->viewRect.right -
						(*(theDoc->theText))->viewRect.left; /* a page */
			break;
		}   /* switch */
		if (part == kControlDownButtonPart || part == kControlPageDownPart)
			amount = - amount; /* reverse direction */

		CommonAction(control, &amount);
		if (amount) {
			TEScroll(amount, 0, theDoc->theText);
			DrawPageExtras(theDoc);
		}
	}     /* if */
}         /* HActionProc */

#if TARGET_RT_MAC_CFM
RoutineDescriptor	uHActionProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppControlActionProcInfo, HActionProc);
#else
#define uHActionProc *(ControlActionUPP)&HActionProc
#endif

/**-----------------------------------------------------------------------
		Name: 		ShowSelect
		Purpose:		Scrolls the text selection into view.
	-----------------------------------------------------------------------**/

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void ShowSelect(DPtr theDoc)
{
	if (!theDoc)
		return;
		
 	AdjustScrollbars(theDoc, false);

	/*
		Let TextEdit do the hard work of keeping the selection visibleÉ
	*/

	TEAutoView(true, theDoc->theText);
	TESelView(theDoc->theText);
	TEAutoView(false, theDoc->theText);

	/*
		Now rematch the text and the scrollbarsÉ
	*/

	SetControlValue(
		theDoc->hScrollBar,
		(*(theDoc->theText))->viewRect.left -
		(*(theDoc->theText))->destRect.left + kTextOffset);

	SetControlValue(
		theDoc->vScrollBar,
		(*(theDoc->theText))->viewRect.top -
		(*(theDoc->theText))->destRect.top  + kTextOffset);
}  /* ShowSelect */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void OffsetWindow(WindowPtr aWindow)
{
	short theWidth;
	short theHeight;
	short theHScreen;
	short theVScreen;
	short xWidth;
	short xHeight;
	short hMax;
	short vMax;
	short wLeft;
	short wTop;

	theWidth  = aWindow->portRect.right - aWindow->portRect.left;
	theHeight = aWindow->portRect.bottom - aWindow->portRect.top + kTBarHeight;

	theHScreen = qd.screenBits.bounds.right  - qd.screenBits.bounds.left;
	theVScreen = qd.screenBits.bounds.bottom - qd.screenBits.bounds.top;

	xWidth  = theHScreen - theWidth;
	xHeight = theVScreen - (theHeight + kMBarHeight);

	hMax = (xWidth / kVOffset) + 1;
	vMax = (xHeight / kVOffset) + 1;

	gWCount++;

	wLeft = (gWCount % hMax) * kVOffset;
	wTop  = ((gWCount % vMax) * kVOffset) + kTBarHeight + kMBarHeight;

	MoveWindow(aWindow, wLeft, wTop, false);
}


/* Returns the update region in local coordinates */

pascal void GetLocalUpdateRgn(WindowPtr window, RgnHandle localRgn)
{
	GetWindowUpdateRgn(window, localRgn); /* save old update region */
	OffsetRgn(localRgn, window->portBits.bounds.left, window->portBits.bounds.top); /* convert to local coords */
}          /* GetLocalUpdateRgn */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void IssueZoomCommand(WindowPtr whichWindow, short whichPart);
pascal void IssueSizeWindow(WindowPtr whichWindow,short newHSize, short newVSize);

pascal void MyGrowWindow(WindowPtr w, Point p)
{
	GrafPtr savePort;
	long    theResult;
	Rect    r;

	GetPort(&savePort);
	SetPort(w);
	SetRect(&r, 80, 80, qd.screenBits.bounds.right, qd.screenBits.bounds.bottom);
	theResult = GrowWindow(w, p, &r);
	if (theResult)
		IssueSizeWindow(w, LoWord(theResult), HiWord(theResult));

	SetPort(savePort);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void DoZoom(WindowPtr w, short c, Point     p)
{
	GrafPtr savePort;

 	GetPort(&savePort);
	SetPort(w);
 	if (TrackBox(w, p, c)) {
		EraseRect(&w->portRect);
		IssueZoomCommand(w, c);
	}
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void DoThumb(DPtr theDoc, ControlHandle cntl, short oldValue)
{
	short value = oldValue - GetControlValue(cntl);
	if (value) {
		if (cntl == theDoc->vScrollBar)
			TEScroll(0, value, theDoc->theText);
		else
			TEScroll(value, 0, theDoc->theText);
		DrawPageExtras(theDoc);
	}
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void DoContent(WindowPtr theWindow, EventRecord * theEvent)
{
	short         cntlCode;
	short         part;
	ControlHandle theControl;
	GrafPtr       savePort;
	Boolean       extend;
	DPtr          theDoc;
	short         value;

	GetPort(&savePort);
	SetPort(theWindow);
	theDoc = DPtrFromWindowPtr(theWindow);

	GlobalToLocal(&theEvent->where);
	cntlCode = FindControl(theEvent->where, theWindow, &theControl);

	/*only extend the selection if the shiftkey is down*/
	if (cntlCode == 0) {
	  	extend = (theEvent->modifiers & shiftKey) != 0;

		if (PtInRect(theEvent->where, &(*(theDoc->theText))->viewRect)) {
			TEClick(theEvent->where, extend, theDoc->theText);
			if (theEvent->modifiers & cmdKey)
				Explain(theDoc);
		}
	} else if (cntlCode == kControlIndicatorPart) {
		value = GetControlValue(theControl);
		if (TrackControl(theControl, theEvent->where, nil))
			DoThumb(theDoc, theControl, value);
	} else
		if (theControl == theDoc->vScrollBar)
			part = TrackControl(theControl, theEvent->where, &uVActionProc);
		else
			part = TrackControl(theControl, theEvent->where, &uHActionProc);

	SetPort(savePort);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void AdjustScript(DPtr doc)
{
	ScriptCode	fontScript;
	ScriptCode	keyScript;

	fontScript = FontToScript(doc->theText[0]->txFont);
	keyScript  = GetScriptManagerVariable(smKeyScript);
	
	/* White man's burden: A roman keyboard script fits everywhere. */
	if (keyScript != fontScript && keyScript != smRoman) 
		KeyScript(fontScript);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal OSErr DoActivate(WindowPtr theWindow, Boolean   activate)
{
	OSErr err;
	Rect  r;
	DPtr  theDoc;

	err = noErr;

	if (theWindow && (theDoc = DPtrFromWindowPtr(theWindow))) {
		SetPort(theWindow);
		DrawGrowIcon(theWindow);
		GetWinContentRect(theWindow, &r);
		InvalRect(&r);
		if (activate) {
			gActiveWindow = theWindow;
			
			TEActivate(theDoc->theText);
			ShowControl(theDoc->vScrollBar);
			ShowControl(theDoc->hScrollBar);
			DisableItem(myMenus[editM], undoCommand);
			AdjustScript(theDoc);
			if (theDoc->tsmDoc)
				ActivateTSMDocument(theDoc->tsmDoc);
		} else {
			if (theDoc->tsmDoc)
				DeactivateTSMDocument(theDoc->tsmDoc);

			gActiveWindow = nil;
			
			TEDeactivate(theDoc->theText);
			HideControl(theDoc->vScrollBar);
			HideControl(theDoc->hScrollBar);
		}
	}

  	return err;
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void GetPageEnds(
	short          pageHeight,
	TEHandle       theText,
	PageEndsArray  pageBounds,
	short          *nPages)
{
	short  pageBase;      /* total pixel offset of pages so far */
	short  thisLine;
	short  lastLine;
	short  pageSoFar;
	short  thisPage;      /* Current page being calced */
	short  thisLineH;     /* Height of text line */
	short  pageFirstLine; /* Line # of top of page */

	pageBase   = 0;
	thisLine   = 1;
	lastLine   = theText[0]->nLines;

	thisPage   = 0;
	pageSoFar  = 0;
	while ((thisLine <= lastLine) || (pageSoFar!=0)) {
		pageFirstLine = thisLine;
		thisLineH     = TEGetHeight(thisLine, thisLine, theText);

		while ((thisLineH+pageSoFar<pageHeight) && (thisLine <= lastLine)) {
			pageSoFar += thisLineH;
			thisLine++;
			thisLineH = TEGetHeight(thisLine, thisLine, theText);
		}

		if (pageSoFar) {
			pageBounds[thisPage] = pageSoFar+pageBase;
			pageBase  = pageBounds[thisPage];
			thisPage++;
			pageSoFar = 0;
		}

		/*
			Special case text line taller than page
		*/

		if ((thisLine  == pageFirstLine) && (thisLineH > pageHeight)) {
			do {
				pageBounds[thisPage] = pageBase+pageHeight;
				pageBase   = pageBounds[thisPage];
				thisPage  += 1;
				thisLineH -= pageHeight;
			} while (thisLineH >= pageHeight);
			pageSoFar = thisLineH; /* Carry bottom of large line to next page */
			thisLine += 1; /* carry xs on as pageSoFar and start measuring next line */
		}
	}

	*nPages = thisPage;
}  /* GetPageEnds */

pascal void DrawPageBreaks(DPtr theDoc)
{
	PageEndsArray	pageEnds;
	short   	    nPages;
	short   	    ctr;
	short   	    lineBase;
	short   	    pageHeight;
	Rect    	    viewRect;

	pageHeight = theDoc->pageSize.bottom - theDoc->pageSize.top;

	GetPageEnds(pageHeight, theDoc->theText, pageEnds, &nPages);

	lineBase = (*(theDoc->theText))->destRect.top;
	viewRect = (*(theDoc->theText))->viewRect;

	PenPat(&qd.gray);
	for (ctr = 0; ctr<nPages-1; ctr++) {
		MoveTo(viewRect.left, lineBase+pageEnds[ctr]);
		LineTo(viewRect.right,lineBase+pageEnds[ctr]);
	}
	PenNormal();
} /*	DrawPageBreaks */

pascal void DrawPageExtras(DPtr theDoc)
{
	GrafPtr   	oldPort;
	RgnHandle	oldClip;
	Rect		  	rectToClip;

	GetPort(&oldPort);
	SetPort(theDoc->theWindow);

	oldClip = NewRgn();
	GetClip(oldClip);

	GetWinContentRect(theDoc->theWindow,&rectToClip);
	ClipRect(&rectToClip);

	/* and then the page breaks */
	/* DrawPageBreaks(theDoc);  Take the page breaks and shove 'em MN */

	SetClip(oldClip);

	DisposeRgn(oldClip);

	SetPort(oldPort);
}  /* DrawPageExtras */

#define PlotResMiniIcon(id, r)	PlotIconID(r, atNone, ttNone, id)

pascal void DoUpdate(DPtr theDoc, WindowPtr theWindow)
{
	GrafPtr   	savePort;
	Rect		 	rectClip;
	Rect		 	r;
	short			icmVBase;

	GetPort(&savePort);
	SetPort(theWindow);
	BeginUpdate(theWindow);

	ClipRect(&theWindow->portRect);
	EraseRect(&theWindow->portRect);
	
	if (theDoc) {
		short	resFile = CurResFile();
		UseResFile(gAppFile);
		
		icmVBase = theWindow->portRect.bottom - 13;
		
		SetRect(&r, 2, icmVBase, 18, icmVBase+12);
		switch (theDoc->lastState & 0x000F) {
		case stateConsole:
			PlotResMiniIcon(ConsoleSICNID, &r);
			break;
		case stateDocument:
			PlotResMiniIcon(DocumentSICNID, &r);
			break;
		}
		SetRect(&r, 18, icmVBase, 34, icmVBase+12);
		switch (theDoc->lastState & 0x00F0) {
		case stateRdWr:
			PlotResMiniIcon(EnabledSICNID, &r);
			break;
		case stateRdOnly:
			PlotResMiniIcon(ReadOnlySICNID, &r);
			break;
		case stateBlocked:
			PlotResMiniIcon(BlockedSICNID, &r);
			break;
		}
		UseResFile(resFile);
		
		DrawControls(theWindow);
		DrawGrowIcon(theWindow);
	
		GetWinContentRect(theWindow, &rectClip);
		ClipRect(&rectClip);
	
		TEUpdate(&theWindow->portRect, theDoc->theText);
	
		DrawPageExtras(theDoc);
	}
	
	EndUpdate(theWindow);
	ClipRect(&theWindow->portRect);

	SetPort(savePort);
} /* DoUpdate */

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal DPtr NewDocument(Boolean isForOldDoc, WindowKind kind)
{
	short				resFile;
	Rect           destRect;
	Rect           viewRect;
	Rect           vScrollRect;
	Rect           hScrollRect;
	DPtr           myDoc;
	WindowPtr      myWindow;
	ControlHandle  vScroll;
	ControlHandle  hScroll;
	Str255         theName;
	Str255         newNumber;
	OSType			supportedInterfaces[1];

	myDoc = nil;
	myWindow = GetNewAppWindow(WindowTemplates+kind);

	if (!myWindow)
		return nil;

	if (!isForOldDoc && kind == kDocumentWindow) {
		GetWTitle(myWindow, theName);
		NumToString(++gNewDocCount, newNumber);
		if (gNewDocCount>1) {
			PLstrcat(theName, (StringPtr) "\p #");
			PLstrcat(theName, newNumber);
			SetWTitle(myWindow, theName);
		}
	}

	OffsetWindow(myWindow);
	SetPort(myWindow);

	myDoc = (DPtr)NewPtr(sizeof(DocRec));

	SetWRefCon(myWindow, (long)myDoc);
	SetWindowKind(myWindow, PerlWindowKind);

	myDoc->theWindow = myWindow;

	vScrollRect = myWindow->portRect;

	vScrollRect.left  = vScrollRect.right - kScrollbarAdjust;
	vScrollRect.right = vScrollRect.left  + kScrollbarWidth;

	vScrollRect.bottom = vScrollRect.bottom - 14;
	vScrollRect.top    = vScrollRect.top - 1;

	vScroll = NewControl(myWindow, &vScrollRect, (StringPtr) "\p", true, 0, 0, 0, scrollBarProc, 0);

	hScrollRect = myWindow->portRect;
	hScrollRect.top = hScrollRect.bottom - kScrollbarAdjust;
	hScrollRect.bottom = hScrollRect.top + kScrollbarWidth;

	hScrollRect.right = hScrollRect.right - 14;
	hScrollRect.left  = hScrollRect.left + 31;
	hScroll = NewControl(myWindow, &hScrollRect, (StringPtr) "\p", true, 0, 0, 0, scrollBarProc, 0);

	myDoc->vScrollBar = vScroll;
	myDoc->hScrollBar = hScroll;
	myDoc->type			= kPlainTextDoc;
	myDoc->kind 		= kind;
	myDoc->dirty 		= false;

	if (kind == kDocumentWindow) {
		myDoc->u.reg.everSaved     = false;
		myDoc->u.reg.everLoaded    = false;
		myDoc->u.reg.showBorders 	= false;
		
		myDoc->lastState				= stateDocument + stateRdWr;
	} else {
		myDoc->u.cons.next			= gConsoleList;
		myDoc->u.cons.cookie			= nil;
		myDoc->u.cons.fence			= 0;
		myDoc->u.cons.memory			= 20000;
		myDoc->u.cons.selected		= false;

		gConsoleList = myDoc;

		myDoc->lastState				= stateConsole + stateBlocked;
	}

	GetTERect(myWindow, &viewRect);
	destRect = viewRect;

	myDoc->thePrintSetup = (THPrint)NewHandle(sizeof(TPrint));

	resFile = CurResFile();
	
	PrOpen();
	PrintDefault(myDoc->thePrintSetup);
	PrClose();
	
	UseResFile(resFile);

	myDoc->pageSize = (*(myDoc->thePrintSetup))->prInfo.rPage;
	OffsetRect(&myDoc->pageSize, -myDoc->pageSize.left, -myDoc->pageSize.top);

	destRect.right = destRect.left + myDoc->pageSize.right;

	OffsetRect(&destRect, kTextOffset, kTextOffset);

	TextFont(gFormat.font);
	TextSize(gFormat.size);
	TextFace(0);

	myDoc->theText = TENew(&destRect, &viewRect);
	
	myDoc->theText[0]->crOnly = -1;
	myDoc->theFileName[0] = 0;
	myDoc->theWindow      = myWindow;

	myDoc->tsmDoc				=	nil;
	myDoc->tsmTERecHandle	=	nil;
	
	if (gTSMTEImplemented) {
		supportedInterfaces[0] = kTSMTEInterfaceType;
		if (NewTSMDocument(1, supportedInterfaces, &myDoc->tsmDoc,
					(long) &myDoc->tsmTERecHandle) == noErr)
		{
			TSMTERecPtr tsmteRecPtr = *(myDoc->tsmTERecHandle);
			
			tsmteRecPtr->textH = myDoc->theText;
			tsmteRecPtr->preUpdateProc = nil;
			tsmteRecPtr->postUpdateProc = nil;
			tsmteRecPtr->updateFlag = 0;
			tsmteRecPtr->refCon = (long) myDoc->theWindow;
			
			UseInputWindow(myDoc->tsmDoc, !gPerlPrefs.inlineInput);
		} else {
			myDoc->tsmDoc				=	nil;
			myDoc->tsmTERecHandle	=	nil;
		}
	}
		
	ResizeMyWindow(myDoc);
	
	RegisterDocument(myDoc);
	
	return(myDoc);
}

#if !defined(powerc) && !defined(__powerc)
#pragma segment Window
#endif

pascal void CloseMyWindow(WindowPtr aWindow)
{
	DPtr     aDocument;
	TEHandle theText;

	DoHideWindow(aWindow);
	aDocument = DPtrFromWindowPtr(aWindow);

	UnregisterDocument(aDocument);

	if (aDocument->tsmDoc) {
		FixTSMDocument(aDocument->tsmDoc);
		// DeleteTSMDocument might cause crash if we don't deactivate first, so...
		DeactivateTSMDocument(aDocument->tsmDoc);
		DeleteTSMDocument(aDocument->tsmDoc);
	}

	if (aDocument->kind != kDocumentWindow) {
		CloseConsole(aDocument->u.cons.cookie);
		
		if (gConsoleList == aDocument)
			gConsoleList = aDocument->u.cons.next;
		else {
			DPtr doc = gConsoleList;
			while (doc->u.cons.next != aDocument)
				doc = doc->u.cons.next;
			doc->u.cons.next = aDocument->u.cons.next;
		}
	}
	
	theText   = aDocument->theText;
	TEDispose(theText);

	if (aDocument->thePrintSetup)
		DisposeHandle((Handle)aDocument->thePrintSetup);

	DisposePtr((Ptr)aDocument);
	DisposeWindow(aWindow);

	gWCount--;
}

/*
	Name     : PrintWindow
	Function : Prints the document supplied in theDoc. askUser controls interaction
				  with the user.

						 Uses extra memory equal to the size of the textedit use in the
						 printed document.
*/

pascal void PrintWindow(DPtr theDoc, Boolean askUser)
{
	GrafPtr      	oldPort;
	TEHandle     	printerTE;
	TPPrPort 		printerPort;
	Rect 				printView;
	PageEndsArray	pageBounds;
	short  			nPages;
	short   			pageCtr;
	Boolean 			abort;
	short				resFile;
	Rect 				rectToClip;
	TPrStatus 		thePrinterStatus;
	DialogPtr 		progressDialog;

	abort = false;

	/*
		Preserve the current port
	*/
	GetPort(&oldPort);
	resFile = CurResFile();
	PrOpen();

	if (askUser)
		if (abort = !PrJobDialog(theDoc->thePrintSetup)) {
			PrClose();
			
			goto done;
		}

	progressDialog = GetNewAppDialog(1005);

	DrawDialog(progressDialog);

	printerPort = PrOpenDoc(theDoc->thePrintSetup, nil, nil);
	SetPort((GrafPtr)printerPort);

	/*
		Put the window text into the printer port
	*/
	TextFont(theDoc->theText[0]->txFont);
	TextSize(theDoc->theText[0]->txSize);

	printView = (*(theDoc->thePrintSetup))->prInfo.rPage;
	printerTE = TENew(&printView, &printView);

	HLock((Handle)((*(theDoc->theText))->hText));

	TESetText(*((*(theDoc->theText))->hText), (*(theDoc->theText))->teLength, printerTE);

	HUnlock((Handle)((*(theDoc->theText))->hText));

	/*
		Work out the offsets
	*/
	printerTE[0]->destRect = printView; /* GetPageEnds calls TECalText */

	GetPageEnds(printView.bottom-printView.top, printerTE, pageBounds, &nPages);

	TEDeactivate(printerTE);

	for (pageCtr = 0; pageCtr <= nPages-1; pageCtr++)
		if (!abort) {
			PrOpenPage(printerPort, nil);

			rectToClip = printView;

			if (pageCtr > 0)
				rectToClip.bottom = rectToClip.top + (pageBounds[pageCtr]-pageBounds[pageCtr-1]);
			else
				rectToClip.bottom = rectToClip.top + pageBounds[pageCtr];

			ClipRect(&rectToClip);

			if (PrError() == iPrAbort)
				abort = true;

			if (! abort)
				TEUpdate(&printView, printerTE);

			if (PrError() == iPrAbort)
				abort = true;

			PrClosePage(printerPort);

			TEScroll(0,rectToClip.top-rectToClip.bottom, printerTE);
		}

	TEDispose(printerTE);
	PrCloseDoc(printerPort);

	if (( (*(theDoc->thePrintSetup))->prJob.bJDocLoop == bSpoolLoop ) &&
			( PrError() == noErr )  &&
			(! abort))
		PrPicFile( theDoc->thePrintSetup, nil, nil, nil, &thePrinterStatus);

	PrClose();

	DisposeDialog(progressDialog);

done:
	SetPort(oldPort);
	UseResFile(resFile);
	InvalRect(&oldPort->portRect);
}

void ForceStatusRedraw(WindowPtr win)
{
	GrafPtr	oldPort;
	Rect		r;
	
	GetPort(&oldPort);
	SetPort(win);

	r = win->portRect;
	
	r.right = 30;
	r.top   = r.bottom - 13;
	
	InvalRect(&r);
	
	SetPort(oldPort);
}

pascal void ShowWindowStatus()
{
 	DPtr   		aDocument;
	WindowPtr	win;
	short			curState;

	for (win = FrontWindow(); win; win = GetNextWindow(win)) {
		if (Ours(win)) {
			aDocument = DPtrFromWindowPtr(win);

			if (aDocument->kind == kDocumentWindow) 
				curState = stateDocument + stateRdWr;
			else {
				curState = stateConsole;
				if (aDocument->u.cons.fence == 32767)
					curState	+= stateRdOnly;
				else if (!gRunningPerl || !aDocument->u.cons.selected)
					curState += stateBlocked;
				else
					curState += stateRdWr;
			}
			
			if (curState != aDocument->lastState) {
				aDocument->lastState = curState;
				ForceStatusRedraw(win);
			}
		}
	}
}

pascal void UseInlineInput(Boolean doInline)
{
 	DPtr   		aDocument;
	WindowPtr	win;

	for (win = FrontWindow(); win; win = GetNextWindow(win)) {
		if (Ours(win)) {
			aDocument = DPtrFromWindowPtr(win);
			if (aDocument->tsmDoc)
				UseInputWindow(aDocument->tsmDoc, !doInline);
		}
	}
}

pascal void DoShowWindow(WindowPtr win)
{
	ShowWindow(win);

	for (win = FrontWindow(); win; win = GetNextWindow(win))
		if (IsWindowVisible(win) && Ours(win)) {
			SetLongMenus();
			
			return;
		}
}

pascal void DoHideWindow(WindowPtr win)
{
	HideWindow(win);

	for (win = FrontWindow(); win; win = GetNextWindow(win))
		if (IsWindowVisible(win) && Ours(win))
			return;
	
	SetShortMenus();
}

pascal WindowPtr AlreadyOpen(FSSpec * spec, StringPtr name)
{
 	DPtr   		aDocument;
	WindowPtr	win;
	Str255		title;

	for (win = FrontWindow(); win; win = GetNextWindow(win))
		if (Ours(win)) {
			aDocument = DPtrFromWindowPtr(win);
			if (aDocument->kind == kDocumentWindow && aDocument->u.reg.everSaved) {
				if (SameFSSpec(spec, &aDocument->theFSSpec))
					return win;
			} else if (name) {
				GetWTitle(win, title);
				if (EqualString(title, name, false, true))
					return win;
			}
		}
	
	return nil;
}

static Str255		sFindText;

pascal void DoFind(TEHandle te, Boolean again)
{
	short		found;
	short		start;

	if (!again) {
		short			item;
		DialogPtr	dlg;	
		
		dlg = GetNewAppDialog(FindDialog);
			
		SetText(dlg, fi_Subject, sFindText);
		SelectDialogItemText(dlg, fi_Subject, 0, 32767);
		ShowWindow(dlg);
		SetPort(dlg);
		DrawDefaultOutline(dlg, fi_OK);
		
		ModalDialog((ModalFilterUPP)0, &item);
		if (item == fi_OK)
			RetrieveText(dlg, fi_Subject, sFindText);
		DisposeDialog(dlg);
		
		if (item != fi_OK)
			return;
	}

	start = te[0]->selEnd;
	if (!*sFindText)
		found = -1;
	else {
		found = Munger(TEGetText(te), start, sFindText+1, *sFindText, nil, 0);
		if (found < 0)
			found = Munger(TEGetText(te), 0, sFindText+1, *sFindText, nil, 0);
	}
	if (found < 0) {
		SysBeep(1);
		
		return;
	}
	TESetSelect(found, found+*sFindText, te);
}
