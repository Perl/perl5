/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Windows/Windows.xs,v 1.3 2000/12/22 08:31:47 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Windows.xs,v $
 * Revision 1.3  2000/12/22 08:31:47  neeri
 * Some build tweaks
 *
 * Revision 1.2  2000/09/09 22:18:29  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:34  neeri
 * Checked into Sourceforge
 *
 * Revision 1.4  1998/04/07 01:03:21  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.3  1997/11/18 00:53:28  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.2  1997/09/02 23:06:44  neeri
 * Added Structs, other minor fixes
 *
 * Revision 1.1  1997/04/07 20:51:00  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Windows.h>
#include <QuickDraw.h>

Rect	gGrowBounds;

typedef struct {
	Rect	userState;
	Rect	stdState;
	SV *	wdef;
} PerlWDEFData, **PerlWDEFDataHdl;

static pascal long 
CallWDEF(short varCode, WindowPeek win, short message, long param)
{
	SV * 	wdef;
	
	dXSARGS;
	
	wdef = ((PerlWDEFDataHdl)win->dataHandle)[0]->wdef;
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(short, varCode);
	XS_XPUSH(GrafPtr, win);
	XS_XPUSH(short, message);
	switch (message) {
	case wDraw:
		XS_XPUSH(short, (short)param);
		break;
	case wHit:
		XS_XPUSH(Point, *(Point *)&param);
		break;
	case wGrow:
		XS_XPUSH(Rect, *(Rect *)param);
		break;
	case wNew:
	case wCalcRgns:
	case wDispose:
	case wDrawGIcon:
		break;			/* No parameters */
	default:
		XS_XPUSH(long, param);
		break;
	}
	PUTBACK;
	
	perl_call_sv(wdef, G_SCALAR);
	
	SPAGAIN;
	
	XS_POP(long, param);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return param;
}


#if GENERATINGCFM
RoutineDescriptor sCallWDEF = 
	BUILD_ROUTINE_DESCRIPTOR(uppWindowDefProcInfo, CallWDEF);
#else
struct {
	short	jmp;
	void *	addr;
} sCallWDEF = {0x4EF9, CallWDEF};
#endif
static Handle	sWDEF;
static int		sWDEFRefCount;

static Rect GlobalBounds(WindowPtr win)
{
	Rect r	  =	win->portRect;
	r.top    -= win->portBits.bounds.top;
	r.bottom -= win->portBits.bounds.top;
	r.left   -= win->portBits.bounds.left;
	r.right  -= win->portBits.bounds.left;
	
	return r;
}

MODULE = Mac::Windows	PACKAGE = Mac::Windows

=head2 Types

=over 4

=item GrafPtr

Those C<GrafPtrs> which represent windows have the following fields defined:

	short			windowKind;
	Boolean			visible;
	Boolean			hilited;
	Boolean			goAwayFlag;
	Boolean			spareFlag;
	RgnHandle		strucRgn;
	RgnHandle		contRgn;
	RgnHandle		updateRgn;
	SV *			windowDefProc;
	Handle			titleHandle;
	short			titleWidth;
	ControlHandle	controlList;
	GrafPtr			nextWindow;
	PicHandle		windowPic;
	long			refCon;
	Rect 			userState;
	Rect 			stdState;
	
You should consider most of them read only.

=back

=cut
STRUCT * GrafPtr
	WindowPeek		STRUCT;
		INPUT:
		XS_INPUT(GrafPtr, *(GrafPtr *)&STRUCT, ST(0));
		OUTPUT:
		XS_PUSH(GrafPtr, STRUCT);
	short			windowKind;
	Boolean			visible;
	Boolean			hilited;
	Boolean			goAwayFlag;
	Boolean			spareFlag;
	RgnHandle		strucRgn;
		READ_ONLY
	RgnHandle		contRgn;
		READ_ONLY
	RgnHandle		updateRgn;
		READ_ONLY
	SV *			windowDefProc;
		INPUT:
		if (STRUCT->windowDefProc == sWDEF) {
			HLock(STRUCT->dataHandle);
			SvREFCNT_dec(((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->wdef);
		} else {
			STRUCT->windowDefProc = sWDEF;
			if (STRUCT->dataHandle) {
				SetHandleSize(STRUCT->dataHandle, sizeof(PerlWDEFData));
				HLock(STRUCT->dataHandle);
			} else {
				STRUCT->dataHandle = NewHandle(sizeof(PerlWDEFData));
				HLock(STRUCT->dataHandle);
				((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->userState =
				((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->stdState =
					GlobalBounds((WindowPtr)STRUCT);
			}
		}
		((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->wdef = newSVsv($arg);
		HUnlock(STRUCT->dataHandle);
		OUTPUT:
		if (STRUCT->windowDefProc == sWDEF) {
			HLock(STRUCT->dataHandle);
			sv_setsv($arg, ((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->wdef);
			HUnlock(STRUCT->dataHandle);
		} else
			$arg = &PL_sv_undef;
	Handle			titleHandle;
		READ_ONLY
	short			titleWidth;
		READ_ONLY
	ControlHandle	controlList;
		READ_ONLY
	GrafPtr			nextWindow;
		READ_ONLY
	PicHandle		windowPic;
	long			refCon;
	Rect 			userState;
		INPUT:
		if (STRUCT->dataHandle) {
			HLock(STRUCT->dataHandle);
			XS_INPUT(Rect, ((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->userState, $arg);
			HUnlock(STRUCT->dataHandle);
		}
		OUTPUT:
		if (STRUCT->dataHandle) {
			HLock(STRUCT->dataHandle);
			XS_OUTPUT(Rect, ((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->userState, $arg);
			HUnlock(STRUCT->dataHandle);
		} else {
			Rect	r = GlobalBounds((WindowPtr)STRUCT);
			XS_OUTPUT(Rect, r, $arg);
		}
	Rect 			stdState;
		INPUT:
		if (STRUCT->dataHandle) {
			HLock(STRUCT->dataHandle);
			XS_INPUT(Rect, ((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->stdState, $arg);
			HUnlock(STRUCT->dataHandle);
		}
		OUTPUT:
		if (STRUCT->dataHandle) {
			HLock(STRUCT->dataHandle);
			XS_OUTPUT(Rect, ((PerlWDEFDataHdl)STRUCT->dataHandle)[0]->stdState, $arg);
			HUnlock(STRUCT->dataHandle);
		} else {
			Rect	r = GlobalBounds((WindowPtr)STRUCT);
			XS_OUTPUT(Rect, r, $arg);
		}

=head2 Functions

=over 4

=item GetGrayRgn()

Returns a handle to the desktop region.

=cut
BOOT:
gGrowBounds = qd.screenBits.bounds;
InsetRect(&gGrowBounds, 10, 10);
gGrowBounds.left = gGrowBounds.top = 80;

RgnHandle
GetGrayRgn()

=item GetWMgrPort()

Return the window manager port.

=cut
GrafPtr
GetWMgrPort()
	CODE:
	GetWMgrPort(&RETVAL);
	OUTPUT:
	RETVAL

=item NewWindow BOUNDS, TITLE, VISIBLE, PROC, GOAWAY [, REFCON [, BEHIND]]

Create a new window.

=cut
GrafPtr
NewWindow(boundsRect, title, visible, theProc, goAwayFlag, refCon=0, behind=(GrafPtr)-1)
	Rect   	   &boundsRect
	Str255 		title
	Boolean 	visible
	SV * 		theProc
	Boolean 	goAwayFlag
	long 		refCon
	GrafPtr 	behind
	CODE:
	{
		short	proc 	 = zoomDocProc;
		Boolean	vis  	 = visible;
		Boolean userProc = SvROK(theProc) || !looks_like_number(theProc);
		if (!userProc)
			proc = SvIV(theProc);
		else
			vis = false;
		RETVAL = 
			NewWindow(
				nil, &boundsRect, title, vis, proc, behind, goAwayFlag, refCon);
		if (userProc) {
			WindowPeek peek = (WindowPeek)RETVAL;
			if (!sWDEFRefCount++) {
				PtrToHand((Ptr)&sCallWDEF, &sWDEF, sizeof(sCallWDEF));
#if !GENERATINGCFM
				FlushInstructionCache();
				FlushDataCache();
#endif
			}
			peek->windowDefProc	= sWDEF;
			SetHandleSize(peek->dataHandle, sizeof(PerlWDEFData));
			((PerlWDEFDataHdl)peek->dataHandle)[0]->wdef = newSVsv(theProc);
			CallWDEF(GetWVariant(RETVAL), peek, wNew, 0);
			if (visible)
				ShowWindow(RETVAL);
		}
	}
	OUTPUT:
	RETVAL

=item GetNewWindow ID [, BEHIND]

Create a new window from a resource.

=cut
GrafPtr
GetNewWindow(windowID, behind=(GrafPtr)-1)
	short 	windowID
	GrafPtr behind
	CODE:
	RETVAL = GetNewWindow(windowID, nil, behind);
	OUTPUT:
	RETVAL

=item DisposeWindow WINDOW

Destroy a window.

=cut
void
DisposeWindow(theWindow)
	GrafPtr 	theWindow
	CODE:
	if (((WindowPeek)theWindow)->windowDefProc == sWDEF) {
		PerlWDEFDataHdl h = (PerlWDEFDataHdl)((WindowPeek)theWindow)->dataHandle;
		DisposeWindow(theWindow);
		if (!--sWDEFRefCount)
			DisposeHandle(sWDEF);
		HLock((Handle)h);
		SvREFCNT_dec(h[0]->wdef);
		DisposeHandle((Handle)h);
	} else {
		DisposeWindow(theWindow);
	}

=item GetWTitle WINDOW

Return the title of the window.

=cut
Str255
GetWTitle(theWindow)
	GrafPtr 	theWindow
	CODE:
	GetWTitle(theWindow, RETVAL);
	OUTPUT:
	RETVAL

=item SelectWindow WINDOW

Put the window in front.

=cut
void
SelectWindow(theWindow)
	GrafPtr 	theWindow

=item HideWindow WINDOW

Make the window invisible.

=cut
void
HideWindow(theWindow)
	GrafPtr 	theWindow

=item ShowWindow WINDOW

Make the window visible.

=cut
void
ShowWindow(theWindow)
	GrafPtr 	theWindow

=item ShowHide WINDOW, SHOWIT

Set the visibility status of a window.

=cut
void
ShowHide(theWindow, showFlag)
	GrafPtr 	theWindow
	Boolean 	showFlag

=item HiliteWindow WINDOW, HILITE

Set the hilite status of a window.

=cut
void
HiliteWindow(theWindow, fHilite)
	GrafPtr 	theWindow
	Boolean 	fHilite

=item BringToFront WINDOW

Put a window in front without changing hiliting.

=cut
void
BringToFront(theWindow)
	GrafPtr 	theWindow

=item SendBehind WINDOW [, BEHIND]

Put a window behind another one. If BEHIND is omitted, send the window behind all
other windows.

=cut
void
SendBehind(theWindow, behindWindow=NULL)
	GrafPtr 	theWindow
	GrafPtr 	behindWindow

=item FrontWindow()

Return the front window.

=cut
GrafPtr
FrontWindow()

=item DrawGrowIcon WINDOW

Draw the grow icon for a window.

=cut
void
DrawGrowIcon(theWindow)
	GrafPtr 	theWindow

=item MoveWindow WINDOW, H, V, FRONT

Move a window.

=cut
void
MoveWindow(theWindow, hGlobal, vGlobal, front)
	GrafPtr theWindow
	short 	hGlobal
	short 	vGlobal
	Boolean front

=item SizeWindow WINDOW, W, H

Set the size of a window.

=cut
void
SizeWindow(theWindow, w, h, fUpdate=true)
	GrafPtr theWindow
	short 	w
	short 	h
	Boolean fUpdate

=item ZoomWindow WINDOW, PARTCODE, FRONT

Zoom a window.

=cut
void
ZoomWindow(theWindow, partCode, front)
	GrafPtr theWindow
	short 	partCode
	Boolean front

=item InvalRect RECT

Invalidate a rectangular area of a window.

=cut
void
InvalRect(badRect)
	Rect &badRect

=item InvalRgn REGION

Invalidate a region in a window.

=cut
void
InvalRgn(badRgn)
	RgnHandle 	badRgn

=item ValidRect RECT

Validate a rectangular area.

=cut
void
ValidRect(goodRect)
	Rect &goodRect

=item ValidRgn REGION

Validate a region.

=cut
void
ValidRgn(goodRgn)
	RgnHandle 	goodRgn

=item BeginUpdate WINDOW

Begin updating the window.

=cut
void
BeginUpdate(theWindow)
	GrafPtr 	theWindow

=item EndUpdate WINDOW

End updating the window.

=cut
void
EndUpdate(theWindow)
	GrafPtr 	theWindow

=item SetWRefCon WINDOW, REFCON

Set a user defined value associated with the window.

=cut
void
SetWRefCon(theWindow, data)
	GrafPtr theWindow
	long 	data

=item GetWRefCon WINDOW

Return the user defined value.

=cut
long
GetWRefCon(theWindow)
	GrafPtr 	theWindow

=item SetWindowPic WINDOW, PICTURE

Set a picture to be displayed as the window's contents.

=cut
void
SetWindowPic(theWindow, pic)
	GrafPtr 	theWindow
	PicHandle 	pic

=item GetWindowPic WINDOW

Return the picture of the window.

=cut
PicHandle
GetWindowPic(theWindow)
	GrafPtr 	theWindow
	CODE:
	if (!(RETVAL = GetWindowPic(theWindow))) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item GrowWindow WINDOW, PT [, BBOX]

Drag the size of a window and return the new suggested width and height.

	($w, $h) = GrowWindow $win, $pt;

=cut
void
GrowWindow(theWindow, pt, bBox=gGrowBounds)
	GrafPtr theWindow
	Point	pt
	Rect   &bBox
	PPCODE:
	{
		long res  = GrowWindow(theWindow, pt, &bBox);
		if (!res) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(short, res & 0x0FFFF);
		XS_XPUSH(short, (res >> 16) & 0x0FFFF);
	}

=item FindWindow PT

Identify the window and part hit by a point.

	($code, $win) = FindWindow $pt;

=cut
void
FindWindow(pt)
	Point	pt
	PREINIT:
	GrafPtr	window;
	short	code;
	PPCODE:
	{
		code = FindWindow(pt, &window);
		if (GIMME != G_ARRAY) {
			if (code < inSysWindow) {
				XSRETURN_UNDEF;
			} else
				XS_XPUSH(GrafPtr, window);
		} else {
			XS_XPUSH(short, code);
			if (code >= inSysWindow)
				XS_XPUSH(GrafPtr, window);
		}
	}

=item PinRect RECT, PT

Pin a point inside a rectangle.

=cut
Point
PinRect(theRect, pt)
	Rect   &theRect
	Point	pt
	PREINIT:
	long	res;
	CODE:
	{
		res = PinRect(&theRect, pt);
		RETVAL.h = res & 0x0FFFF;
		RETVAL.v = (res >> 16) & 0x0FFFF;
	}
	OUTPUT:
	RETVAL

=item DragGrayRgn REGION, PT, LIMITRECT, SLOPRECT, AXIS

Drag a region around and return the movement difference as a point.

=cut
Point
DragGrayRgn(theRgn, pt, limitRect, slopRect, axis)
	RgnHandle 	theRgn
	Point		pt
	Rect       &limitRect
	Rect       &slopRect
	short  		axis
	PREINIT:
	long	res;
	CODE:
	{
		res = DragGrayRgn(theRgn, pt, &limitRect, &slopRect, axis, nil);
		RETVAL.h = res & 0x0FFFF;
		RETVAL.v = (res >> 16) & 0x0FFFF;
	}
	OUTPUT:
	RETVAL

=item TrackBox WINDOW, PT, PART

Track a click in the zoom box of a window and return whether the mouse was still 
inside when the pointer was released.

=cut
Boolean
TrackBox(theWindow, pt, partCode)
	GrafPtr theWindow
	Point	pt
	short 	partCode

=item GetCWMgrPort()

Return the color window manager port.

=cut
GrafPtr
GetCWMgrPort()
	CODE:
	GetCWMgrPort(&(CGrafPort *)RETVAL);
	OUTPUT:
	RETVAL

=item SetDeskCPat PIXPAT

Change the current desktop pattern.

=cut
void
SetDeskCPat(deskPixPat)
	PixPatHandle 	deskPixPat

=item NewCWindow BOUNDS, TITLE, VISIBLE, PROC, GOAWAY [, REFCON [, BEHIND]]

Create a color window.

=cut
GrafPtr
NewCWindow(boundsRect, title, visible, theProc, goAwayFlag, refCon=0, behind=(GrafPtr)-1)
	Rect   	   &boundsRect
	Str255 		title
	Boolean 	visible
	SV * 		theProc
	Boolean 	goAwayFlag
	long 		refCon
	GrafPtr 	behind
	CODE:
	{
		short	proc = zoomDocProc;
		Boolean	vis  = visible;
		Boolean userProc = SvROK(theProc) || !looks_like_number(theProc);
		if (!userProc)
			proc = SvIV(theProc);
		else
			vis = false;
		RETVAL = 
			NewCWindow(
				nil, &boundsRect, title, vis, proc, behind, goAwayFlag, refCon);
		if (userProc) {
			WindowPeek peek = (WindowPeek)RETVAL;
			if (!sWDEFRefCount++) {
				PtrToHand((Ptr)&sCallWDEF, &sWDEF, sizeof(sCallWDEF));
#if !GENERATINGCFM
				FlushInstructionCache();
				FlushDataCache();
#endif
			}
			peek->windowDefProc	= sWDEF;
			SetHandleSize(peek->dataHandle, sizeof(PerlWDEFData));
			((PerlWDEFDataHdl)peek->dataHandle)[0]->wdef = newSVsv(theProc);
			CallWDEF(GetWVariant(RETVAL), peek, wNew, 0);
			if (visible)
				ShowWindow(RETVAL);
		}
	}
	OUTPUT:
	RETVAL

=item GetNewCWindow ID [, BEHIND]

Create a color window from a resource.

=cut
GrafPtr
GetNewCWindow(windowID, behind=(GrafPtr)-1)
	short 	windowID
	GrafPtr behind
	CODE:
	RETVAL = GetNewCWindow(windowID, nil, behind);
	OUTPUT:
	RETVAL

=item GetWVariant WINDOW

Return the variant code of a window.

=cut
short
GetWVariant(theWindow)
	GrafPtr 	theWindow

=item SetWTitle WINDOW, TITLE

Change the title of a window.

=cut
void
SetWTitle(theWindow, title)
	GrafPtr 	theWindow
	Str255	 	title

=item TrackGoAway WINDOW, PT

Track a click in the goaway box of a window and return if the mouse remained inside.

=cut
Boolean
TrackGoAway(theWindow, pt)
	GrafPtr theWindow
	Point	pt

=item DragWindow WINDOW, PT [, BBOX]

Drag a window around.

=cut
void
DragWindow(theWindow, pt, boundsRect=GetGrayRgn()[0]->rgnBBox)
	GrafPtr  theWindow
	Point	 pt
	Rect    &boundsRect

=back

=cut
