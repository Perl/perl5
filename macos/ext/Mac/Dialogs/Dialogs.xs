/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Dialogs/Dialogs.xs,v 1.2 2000/09/09 22:18:26 neeri Exp $
 *
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Dialogs.xs,v $
 * Revision 1.2  2000/09/09 22:18:26  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:29  neeri
 * Checked into Sourceforge
 *
 * Revision 1.4  1998/04/07 01:02:47  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.3  1997/11/18 00:52:14  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.2  1997/06/04 22:55:44  neeri
 * Compiles fine.
 *
 * Revision 1.1  1997/04/07 20:49:23  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Dialogs.h>

typedef EventRecord *	ToolboxEvent;

static SV * 	sModalFilter;

static pascal Boolean ModalFilter(DialogPtr theDialog, EventRecord *theEvent, short *itemHit)
{
	dSP ;

	ENTER ;
	SAVETMPS;

	PUSHMARK(sp) ;
	XPUSHs(sv_mortalcopy(sModalFilter));
	XPUSHs(sv_setref_pv(sv_newmortal(), "GrafPtr", (void*)theDialog));
	XPUSHs(sv_setref_pv(sv_newmortal(), "ToolboxEvent", (void*)theEvent));
	PUTBACK ;

	perl_call_pv("Mac::Dialogs::_ModalFilter", G_SCALAR);

	SPAGAIN ;

	*itemHit = (short)POPi;

	PUTBACK ;
	FREETMPS ;
	LEAVE ;
	
	return *itemHit != 0;
}

static pascal Boolean DefaultModalFilter(DialogPtr theDialog, EventRecord *theEvent, short *itemHit)
{
	dSP ;

	ENTER ;
	SAVETMPS;

	PUSHMARK(sp) ;
	XPUSHs(sv_2mortal(newSVpv("Mac::Dialogs::_DefaultModalFilter", 0)));
	XPUSHs(sv_setref_pv(sv_newmortal(), "GrafPtr", (void*)theDialog));
	XPUSHs(sv_setref_pv(sv_newmortal(), "ToolboxEvent", (void*)theEvent));
	PUTBACK ;

	perl_call_pv("Mac::Dialogs::_ModalFilter", G_SCALAR);

	SPAGAIN ;

	*itemHit = (short)POPi;

	PUTBACK ;
	FREETMPS ;
	LEAVE ;
	
	return *itemHit != 0;
}

static pascal void ItemProc(DialogPtr theDialog, short item)
{
	dSP ;

	PUSHMARK(sp) ;
	XPUSHs(sv_setref_pv(sv_newmortal(), "GrafPtr", (void*)theDialog));
	XPUSHs(sv_2mortal(newSViv(item)));
	PUTBACK ;

	perl_call_pv("Mac::Dialogs::_UserItem", G_DISCARD);
}

#if TARGET_RT_MAC_CFM
static RoutineDescriptor	uModalFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, ModalFilter);
static RoutineDescriptor	uDefaultModalFilter = 
		BUILD_ROUTINE_DESCRIPTOR(uppModalFilterProcInfo, DefaultModalFilter);
static RoutineDescriptor	uItemProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppUserItemProcInfo, ItemProc);
#else
#define uModalFilter *(ModalFilterUPP)&ModalFilter
#define uDefaultModalFilter *(ModalFilterUPP)&DefaultModalFilter
#define uItemProc *(UserItemUPP)&ItemProc
#endif

MODULE = Mac::Dialogs	PACKAGE = Mac::Dialogs

=head2 Structures

=over 4

=item GrafPtr

A dialog window has the following additional fields over an ordinary window, all
of them read only:

=over 4

=item items

The dialog item list.

=item textH

A C<TextEdit> record for the active edit field.

=item editField

The currently active edit field - 1.

=item aDefItem

Default item number.

=back

=back

=cut
STRUCT * GrafPtr
	DialogPeek		STRUCT;
		INPUT:
		XS_INPUT(GrafPtr, *(GrafPtr *)&STRUCT, ST(0));
		OUTPUT:
		XS_PUSH(GrafPtr, STRUCT);
	Handle			items;
	TEHandle		textH;
	short			editField;
	short			aDefItem;

=head2 Functions

=over 4

=item _NewDialog BOUNDS, TITLE, VISIBLE, PROC, GOAWAY, ITEMS [, REFCON [, BEHIND]]

Create a new dialog and return it.

=cut
GrafPtr
_NewDialog(boundsRect, title, visible, theProc, goAwayFlag, ditems, refCon=0, behind=(GrafPtr)-1)
	Rect   	   &boundsRect
	Str255 		title
	Boolean 	visible
	short 		theProc
	Boolean 	goAwayFlag
	Handle		ditems
	long 		refCon
	GrafPtr 	behind
	CODE:
	RETVAL = 
		NewDialog(
			nil, &boundsRect, title, visible, theProc, behind, goAwayFlag, refCon, ditems);
	OUTPUT:
	RETVAL

=item PORT = GetNewDialog ID [, BEHIND]

Create a new dialog from a resource.

=cut
GrafPtr
GetNewDialog(dialogID, behind=(GrafPtr)-1)
	short 	dialogID
	GrafPtr behind
	CODE:
	RETVAL = GetNewDialog(dialogID, nil, behind);
	OUTPUT:
	RETVAL

void
_DisposeDialog(theDialog)
	GrafPtr	theDialog
	CODE:
	DisposeDialog(theDialog);

=item ParamText PARAM0, PARAM1, PARAM2, PARAM3 

Set text values for ^0 ^1 ^2 ^3.

=cut
void
ParamText(param0, param1, param2, param3)
	Str255	param0
	Str255	param1
	Str255	param2
	Str255	param3

=item ITEM = ModalDialog [ FILTERPROC ]

Run a modal dialog until an item is hit.

=cut
short
ModalDialog(modalFilter=0)
	SV *	modalFilter
	CODE:
	{
		Boolean saveInModalDialog = gMacPerl_InModalDialog;
		gMacPerl_InModalDialog	= true;
		if (modalFilter) {
			SV * saveModalFilter = sModalFilter;
			sModalFilter = modalFilter;
			ModalDialog(&uModalFilter, &RETVAL);
			sModalFilter = saveModalFilter;
		} else
			ModalDialog(&uDefaultModalFilter, &RETVAL);
		gMacPerl_InModalDialog	= saveInModalDialog;
	}
	OUTPUT:
	RETVAL

=item IsDialogEvent EVENT

Check if an event belongs to a dialog.

=cut
Boolean
IsDialogEvent(theEvent)
	ToolboxEvent	theEvent

=item DialogSelect EVENT

Returns the dialog and item that were affected by an event, if any.

	($dlg, $item) = DialogSelect($event);

=cut
void
DialogSelect(theEvent)
	ToolboxEvent	theEvent
	PPCODE:
	{
		DialogPtr 	theDialog;
		short 		itemHit;
		
		if (DialogSelect(theEvent, &theDialog, &itemHit)) {
			EXTEND(sp, 2);
			PUSHs(sv_setref_pv(sv_newmortal(), "GrafPtr", (void*)theDialog));
			PUSHs(sv_2mortal(newSViv(itemHit)));
		} else {
			XSRETURN_EMPTY;
		}
	}

=item DrawDialog DIALOG

Draw a dialog.

=cut
void
DrawDialog(theDialog)
	GrafPtr	theDialog

=item UpdateDialog DIALOG [, UPDATERGN ]

Draw the update region in a dialog.

=cut
void
UpdateDialog(theDialog, updateRgn=theDialog->visRgn)
	GrafPtr	theDialog
	RgnHandle	updateRgn

=item ITEM = Alert ALERTID [, FILTER]

Run an alert.

=cut
short
Alert(alertID, modalFilter=nil)
	short	alertID
	SV *	modalFilter
	CODE:
	if (modalFilter) {
		SV * saveModalFilter = sModalFilter;
		sModalFilter = modalFilter;
		RETVAL = Alert(alertID, &uModalFilter);
		sModalFilter = saveModalFilter;
	} else
		RETVAL = Alert(alertID, &uDefaultModalFilter);
	OUTPUT:
	RETVAL

=item ITEM = StopAlert ALERTID [, FILTER]

Run a an alert with the stop icon.

=cut
short
StopAlert(alertID, modalFilter=nil)
	short	alertID
	SV *	modalFilter
	CODE:
	if (modalFilter) {
		SV * saveModalFilter = sModalFilter;
		sModalFilter = modalFilter;
		RETVAL = StopAlert(alertID, &uModalFilter);
		sModalFilter = saveModalFilter;
	} else
		RETVAL = StopAlert(alertID, &uDefaultModalFilter);
	OUTPUT:
	RETVAL

=item ITEM = NoteAlert ALERTID [, FILTER]

Run a an alert with the note icon.

=cut
short
NoteAlert(alertID, modalFilter=nil)
	short	alertID
	SV *	modalFilter
	CODE:
	if (modalFilter) {
		SV * saveModalFilter = sModalFilter;
		sModalFilter = modalFilter;
		RETVAL = NoteAlert(alertID, &uModalFilter);
		sModalFilter = saveModalFilter;
	} else
		RETVAL = NoteAlert(alertID, &uDefaultModalFilter);
	OUTPUT:
	RETVAL

=item ITEM = CautionAlert ALERTID [, FILTER]

Run a an alert with the caution icon.

=cut
short
CautionAlert(alertID, modalFilter=nil)
	short	alertID
	SV *	modalFilter
	CODE:
	if (modalFilter) {
		SV * saveModalFilter = sModalFilter;
		sModalFilter = modalFilter;
		RETVAL = CautionAlert(alertID, &uModalFilter);
		sModalFilter = saveModalFilter;
	} else
		RETVAL = CautionAlert(alertID, &uDefaultModalFilter);
	OUTPUT:
	RETVAL

=item GetDialogItem DIALOG, ITEM

Get a dialog item's type, contents, and area.

	($type, $handle, $box) = GetDialogItem($dlg, $item);

=cut
void
GetDialogItem(theDialog, itemNo)
	GrafPtr	theDialog
	short	itemNo
	PPCODE:
	{
		short	itemType;
		Handle	item;
		Rect 	box;
		
		GetDialogItem(theDialog, itemNo, &itemType, &item, &box);
		EXTEND(sp, 3);
		PUSHs(sv_2mortal(newSViv(itemType)));
		PUSHs(sv_setref_pv(sv_newmortal(), "Handle", (void*)item));
		PUSHs(sv_setref_pvn(sv_newmortal(), "Rect", (void*)&box, sizeof(Rect)));
	}

=item GetDialogItemControl DIALOG, ITEM

Get the control handle for a dialog item.

	$control = GetDialogItemControl($dlg, $item);

=cut
ControlHandle
GetDialogItemControl(theDialog, itemNo)
	GrafPtr	theDialog
	short	itemNo
	CODE:
	{
		short	itemType;
		Handle	item;
		Rect 	box;
		
		GetDialogItem(theDialog, itemNo, &itemType, &item, &box);
		if (!(itemType & kControlDialogItem)) {
			XSRETURN_UNDEF;
		}
		RETVAL = (ControlHandle)item;
	}
	OUTPUT:
	RETVAL

=item SetDialogItem DIALOG, ITEM, TYPE, ITEMHANDLE, BOX

Don't use this for setting an user item procedure. 

=cut
void
SetDialogItem(theDialog, itemNo, itemType, item, box)
	GrafPtr	theDialog
	short	itemNo
	short	itemType
	Handle	item
	Rect   &box


void
_SetDialogItemProc(theDialog, itemNo)
	GrafPtr	theDialog
	short	itemNo
	CODE:
	{
		short	itemType;
		Handle	item;
		Rect 	box;
		
		GetDialogItem(theDialog, itemNo, &itemType, &item, &box);
		SetDialogItem(theDialog, itemNo, kUserDialogItem, (Handle)&uItemProc, &box);
	}
	
=item HideDialogItem DIALOG, ITEM

=cut
void
HideDialogItem(theDialog, itemNo)
	GrafPtr	theDialog
	short	itemNo

=item ShowDialogItem DIALOG, ITEM

=cut
void
ShowDialogItem(theDialog, itemNo)
	GrafPtr	theDialog
	short	itemNo

=item SelectDialogItemText DIALOG, ITEM [, START, END]

Select text in one of the edit items of a dialog.

=cut
void
SelectDialogItemText(theDialog, itemNo, strtSel=0, endSel=32767)
	GrafPtr	theDialog
	short	itemNo
	short	strtSel
	short	endSel

Str255
_GetDialogItemText(item)
	Handle	item
	CODE:
	GetDialogItemText(item, RETVAL);
	OUTPUT:
	RETVAL

void
_SetDialogItemText(item, text)
	Handle	item
	Str255	text
	CODE:
	SetDialogItemText(item, text);

=item FindDialogItem DIALOG, POINT

Find the topmost dialog item containing the point.

=cut
short
FindDialogItem(theDialog, thePt)
	GrafPtr	theDialog
	Point	thePt

=item NewColorDialog BOUNDS, TITLE, VISIBLE, PROC, GOAWAY, ITEMS [, REFCON [, BEHIND]]

Create and return a color dialog.

=cut
GrafPtr
_NewColorDialog(boundsRect, title, visible, theProc, goAwayFlag, ditems, refCon=0, behind=(GrafPtr)-1)
	Rect   	   &boundsRect
	Str255 		title
	Boolean 	visible
	short 		theProc
	Boolean 	goAwayFlag
	Handle		ditems
	long 		refCon
	GrafPtr 	behind
	CODE:
	RETVAL = 
		NewColorDialog(
			nil, &boundsRect, title, visible, theProc, behind, goAwayFlag, refCon, ditems);
	OUTPUT:
	RETVAL

=item GetAlertStage 

Get the dialog alert stage. Lower stages will just beep, while higher stages
will put up a dialog.

=cut
short
GetAlertStage()

=item ResetAlertStage 

Set the alert stage back to 0.

=cut
void
ResetAlertStage()

=item DialogCut DIALOG

=item DialogCopy DIALOG

=item DialogPaste DIALOG

=item DialogDelete DIALOG

Perform edit menu functions on a dialog.

=cut
void
DialogCut(theDialog)
	GrafPtr	theDialog

void
DialogPaste(theDialog)
	GrafPtr	theDialog

void
DialogCopy(theDialog)
	GrafPtr	theDialog

void
DialogDelete(theDialog)
	GrafPtr	theDialog

=item SetDialogFont FONTNUM

Set the font to be used in a dialog's edit items.

=cut
void
SetDialogFont(value)
	short	value

=item AppendDITL DIALOG, DITLHANDLE, METHOD

Append further items to a dialog.

=cut
void
AppendDITL(theDialog, theHandle, method)
	GrafPtr	theDialog
	Handle	theHandle
	short	method

=item CountDITL DIALOG

Count the number of items in a dialog.

=cut
short
CountDITL(theDialog)
	GrafPtr	theDialog

=item ShortenDITL DIALOG, ITEMS

Removes the specified number of the items from the end of the item list.

=cut
void
ShortenDITL(theDialog, numberItems)
	GrafPtr	theDialog
	short	numberItems

=item ITEM = StdFilterProc DIALOG, EVENT

Call the standard filter procedure and return the item hit or 0.

=cut
short
StdFilterProc(theDialog, event)
	GrafPtr			theDialog
	ToolboxEvent	event
	CODE:
	if (!StdFilterProc(theDialog, event, &RETVAL))
		RETVAL = 0;
	OUTPUT:
	RETVAL

=item SetDialogDefaultItem DIALOG, ITEM

Set the item to be highlighted as the OK button.

=cut
MacOSRet
SetDialogDefaultItem(theDialog, newItem)
	GrafPtr	theDialog
	short	newItem

=item SetDialogCancelItem DIALOG, ITEM

Set the item to be highlighted as the Cancel button.

=cut
MacOSRet
SetDialogCancelItem(theDialog, newItem)
	GrafPtr	theDialog
	short	newItem

=item SetDialogTracksCursor DIALOG, TRACK

Tell the dialog to automatically change the cursor over edit items.

=cut
MacOSRet
SetDialogTracksCursor(theDialog, tracks)
	GrafPtr	theDialog
	Boolean	tracks

