/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Controls/Controls.xs,v 1.1 2000/08/14 03:39:29 neeri Exp $
 *
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Controls.xs,v $
 * Revision 1.1  2000/08/14 03:39:29  neeri
 * Checked into Sourceforge
 *
 * Revision 1.4  1998/11/22 21:21:04  neeri
 * All packed up and no place to go
 *
 * Revision 1.3  1998/04/07 01:02:45  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.2  1997/11/18 00:52:12  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:19  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Controls.h>
#include <CodeFragments.h>

static SV *	sActionProc;

static pascal void ActionProc(ControlHandle cntl, short part)
{
	dSP ;

	PUSHMARK(sp) ;
    XPUSHs(sv_setref_pv(sv_newmortal(), "ControlHandle", (void*)cntl));
	XPUSHs(sv_2mortal(newSViv(part)));
	PUTBACK ;

	perl_call_sv(sActionProc, G_DISCARD);
}

static pascal void IndicatorActionProc()
{
	dSP ;

	PUSHMARK(sp) ;

	perl_call_sv(sActionProc, G_DISCARD|G_NOARGS);
}

#if TARGET_RT_MAC_CFM
static RoutineDescriptor	uActionProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppControlActionProcInfo, ActionProc);
static RoutineDescriptor	uIndicatorActionProc = 
		BUILD_ROUTINE_DESCRIPTOR(kPascalStackBased, IndicatorActionProc);
#else
#define uActionProc *(ControlActionUPP)&ActionProc
#define uIndicatorActionProc *(ControlActionUPP)&IndicatorActionProc
#endif

MODULE = Mac::Controls	PACKAGE = Mac::Controls

=head2 Structures

=over 4

=item ControlHandle

A Control structure. Fields are:

	ControlHandle		nextControl;
	GrafPtr				contrlOwner;
	Rect				contrlRect;
	UInt8				contrlVis;
	UInt8				contrlHilite;
	SInt16				contrlValue;
	SInt16				contrlMin;
	SInt16				contrlMax;
	SInt32				contrlRfCon;
	Str255				contrlTitle;

=back

=cut

STRUCT ** ControlHandle
	ControlHandle		nextControl;
		READ_ONLY
	GrafPtr				contrlOwner;
		READ_ONLY
	Rect				contrlRect;
		READ_ONLY
	U8					contrlVis;
		READ_ONLY
	U8					contrlHilite;
		READ_ONLY
	short				contrlValue;
		READ_ONLY
	short				contrlMin;
		READ_ONLY
	short				contrlMax;
		READ_ONLY
	long				contrlRfCon;
	Str255				contrlTitle;
		READ_ONLY

=head2 Functions

=over 4

=item NewControl THEWINDOW, BOUNDSRECT, TITLE, VISIBLE, VALUE, MIN, MAX, PROC [, REFCON ]

Create a new control and return it..

=cut
ControlHandle
NewControl(theWindow, boundsRect, title, visible, value, min, max, proc, refCon=0)
	GrafPtr	theWindow
	Rect 	&boundsRect
	Str255	title
	Boolean	visible
	short	value
	short	min
	short	max
	short	proc
	long	refCon

=item GetNewControl CONTROLID, OWNER 

Create a new control from resource description.

=cut
ControlHandle
GetNewControl(controlID, owner)
	short	controlID
	GrafPtr	owner

=item DisposeControl CONTROL

Destroy a control.

=cut
void
DisposeControl(theControl)
	ControlHandle	theControl

=item KillControls WINDOW

Destroy all controls in a window.

=cut
void
KillControls(theWindow)
	GrafPtr	theWindow

=item ShowControl CONTROL

Make a control visible.

=cut
void
ShowControl(theControl)
	ControlHandle	theControl

=item HideControl CONTROL

Make a control invisible.

=cut
void
HideControl(theControl)
	ControlHandle	theControl

=item DrawControls WINDOW

Draw all controls in the window.

=cut
void
DrawControls(theWindow)
	GrafPtr	theWindow

=item Draw1Control CONTROL

Draw a single control.

=cut
void
Draw1Control(theControl)
	ControlHandle	theControl

=item UpdateControls WINDOW [, UPDATEREGION]

Update the controls intersecting with the given region.

=cut
void
UpdateControls(theWindow, updateRegion=theWindow->visRgn)
	GrafPtr	theWindow
	RgnHandle	updateRegion

=item HiliteControl CONTROL, HILITE

Hilite a control.

=cut
void
HiliteControl(theControl, hiliteState)
	ControlHandle	theControl
	short			hiliteState

=item TrackControl CONTROL, PT [, ACTIONPROC]

Track a mouse click on a control.

=cut
short
TrackControl(theControl, pt, actionProc=nil)
	ControlHandle	theControl
	Point			pt
	SV *			actionProc
	CODE:
	{
		ControlActionUPP	upp;
		short				part;
		
		if (!actionProc) {
			upp = nil;
		} else if (!SvROK(actionProc) && looks_like_number(actionProc)) {
			upp = (ControlActionUPP) SvIV(actionProc);
			if (upp && upp != (ControlActionUPP)-1)
				croak("Mac::Controls::TrackControl: Last argument must be procedure, 0, or -1");
		} else {
			sActionProc	= actionProc;
			/* Heuristic here */
			part = TestControl(theControl, pt);
			if (part > 127 && part < 250)
				upp = &uIndicatorActionProc;
			else
				upp = &uActionProc;
		}
		RETVAL = TrackControl(theControl, pt, upp); 
	}
	OUTPUT:
	RETVAL

=item DragControl CONTROL, PT, LIMITRECT, SLOPRECT, AXIS

Drag a control to a new position.

=cut
void
DragControl(theControl, pt, limitRect, slopRect, axis)
	ControlHandle	theControl
	Point			pt
	Rect 		   &limitRect
	Rect		   &slopRect
	short			axis

=item PART = TestControl CONTROL, PT

Test which part of a control, if any, has been hit.

=cut
short
TestControl(theControl, pt)
	ControlHandle	theControl
	Point			pt

=item FindControl PT, WINDOW

Find which control in a window, if any, has been hit and where.

	($part,$ctrl) = FindWindow($pt, $win);

=cut
void
FindControl(pt, theWindow)
	Point	pt
	GrafPtr	theWindow
	PPCODE:
	{
		ControlHandle	cntl;
		short			part;
		
		if (part = FindControl(pt, theWindow, &cntl)) {
			EXTEND(sp, 2);
			PUSHs(sv_2mortal(newSViv(part)));
			PUSHs(sv_setref_pv(sv_newmortal(), "ControlHandle", (void*)cntl));
		} else {
			XSRETURN_EMPTY;
		}
	}

=item MoveControl CONTROL, H, V

Move a control to a new position.

=cut
void
MoveControl(theControl, h, v)
	ControlHandle	theControl
	short	h
	short	v

=item SizeControl CONTROL, W, H

Resize a control.

=cut
void
SizeControl(theControl, w, h)
	ControlHandle	theControl
	short	w
	short	h

=item SetControlTitle CONTROL, TITLE

Change the title of a control.

=cut
void
SetControlTitle(theControl, title)
	ControlHandle	theControl
	Str255	title

=item GetControlTitle THECONTROL 

Returns the title of a control.

=cut
Str255
GetControlTitle(theControl)
	ControlHandle	theControl
	CODE:
	GetControlTitle(theControl, RETVAL);
	OUTPUT:
	RETVAL

=item GetControlValue CONTROL

Returns the value of a control.

=cut
short
GetControlValue(theControl)
	ControlHandle	theControl

=item SetControlValue CONTROL, VAL

Set the value of a control.

=cut
void
SetControlValue(theControl, newValue)
	ControlHandle	theControl
	short	newValue

=item GetControlMinimum CONTROL 

Get the minimum value of a control.

=cut
short
GetControlMinimum(theControl)
	ControlHandle	theControl

=item SetControlMinimum CONTROL, MIN

Set the minimum value of a control.

=cut
void
SetControlMinimum(theControl, newMinimum)
	ControlHandle	theControl
	short	newMinimum

=item GetControlMaximum CONTROL

Get the maximum value of a control.

=cut
short
GetControlMaximum(theControl)
	ControlHandle	theControl

=item SetControlMaximum CONTROL, MAX

Set the maximum value of a control.

=cut
void
SetControlMaximum(theControl, newMaximum)
	ControlHandle	theControl
	short	newMaximum

=item GetControlVariant CONTROL

Get the control variant of a control.

=cut
short
GetControlVariant(theControl)
	ControlHandle	theControl

=item SetControlReference CONTROL, REF

Set the reference value of a control.

=cut
void
SetControlReference(theControl, data)
	ControlHandle	theControl
	long	data

=item GetControlReference CONTROL

Get the reference value of a control.

=cut
long
GetControlReference(theControl)
	ControlHandle	theControl

