/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.1 1997/04/07 20:49:35 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Lists.h>
#include <OSUtils.h>

static pascal void
CallLDEF(
		short message, Boolean selected, const Rect * r, Point cell,
		short dataoffset, short datalen, ListHandle lHandle)
{
	SV * 	ldef;
	Handle 	cells;
	
	dSP;
	
	ldef = (SV *) lHandle[0]->userHandle;
	
	PUSHMARK(sp);
	XS_XPUSH(short, message);
	XS_XPUSH(Boolean, selected);
	XS_XPUSH(Rect, *r);
	XS_XPUSH(Point, cell);
	HLock(cells = lHandle[0]->cells);
	XPUSHs(sv_2mortal(newSVpv(datalen ? *cells+dataoffset : "", datalen)));
	HUnlock(cells);
	XS_XPUSH(ListHandle, lHandle);
	PUTBACK;
	
	perl_call_sv(ldef, G_DISCARD);
}

#if GENERATINGCFM
RoutineDescriptor sCallLDEF = 
	BUILD_ROUTINE_DESCRIPTOR(uppListDefProcInfo, CallLDEF);
#else
struct {
	short	jmp;
	void *	addr;
} sCallLDEF = {0x4EF9, CallLDEF};
#endif
static Handle	sLDEF;
static int		sLDEFRefCount;

MODULE = Mac::Lists	PACKAGE = Mac::Lists

=head2 Functions

=over 4

=cut

STRUCT ** ListHandle
	Rect			rView;
	Rect			bounds;
		READ_ONLY;
		OUTPUT:
		{
			Rect bounds = STRUCT[0]->rView;
			if (STRUCT[0]->vScroll)
				bounds.right += 15;
			if (STRUCT[0]->hScroll)
				bounds.bottom += 15;
			XS_OUTPUT(Rect, bounds, $arg);
		}
	GrafPtr			port;
	Point			indent;
	Point			cellSize;
	Rect			visible;
	ControlHandle	vScroll;
	ControlHandle	hScroll;
	I8				selFlags;
	Boolean			lActive;
	I8				lReserved;
	I8				listFlags;
	long			clikTime;
	Point			clikLoc;
	Point			mouseLoc;
	Point			lastClick;
	long			refCon;
	SV *			listDefProc;
		INPUT:
		if (STRUCT[0]->listDefProc == sLDEF) 
			SvREFCNT_dec((SV *)STRUCT[0]->userHandle);
		else
			STRUCT[0]->listDefProc = sLDEF;
		STRUCT[0]->userHandle = (Handle)newSVsv($arg);
		OUTPUT:
		if (STRUCT[0]->listDefProc == sLDEF) 
			XS_OUTPUT(SV *, (SV *)STRUCT[0]->userHandle, $arg);
		else
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
	Rect			dataBounds;
	Handle			cells;
	short			maxIndex;

=item LIST = LNew rView, dataBounds, cSize, theProc, theWindow [, drawIt [, hasGrow [, scrollHoriz [, scrollVert]]]]

Creates a list.

=cut

ListHandle
LNew(rView, dataBounds, cSize, theProc, theWindow, drawIt=true, hasGrow=false, scrollHoriz=false, scrollVert=true)
	Rect	&rView
	Rect	&dataBounds
	Point	cSize
	SV *	theProc
	GrafPtr	theWindow
	Boolean	drawIt
	Boolean	hasGrow
	Boolean	scrollHoriz
	Boolean	scrollVert
	CODE:
	{
		short	proc = 0;
		if (!SvROK(theProc) && looks_like_number(theProc))
			proc = SvIV(theProc);
		RETVAL = LNew(
			&rView, &dataBounds, cSize, proc, theWindow, drawIt, 
			hasGrow, scrollHoriz, scrollVert);
		if (!proc && SvTRUE(theProc)) {
			if (!sLDEFRefCount++) {
				PtrToHand((Ptr)&sCallLDEF, &sLDEF, sizeof(sCallLDEF));
#if !GENERATINGCFM
				FlushInstructionCache();
				FlushDataCache();
#endif
			}
			RETVAL[0]->listDefProc  = sLDEF;
			RETVAL[0]->userHandle  	= (Handle) newSVsv(theProc);
			CallLDEF(lInitMsg, false, &rView, cSize, 0, 0, RETVAL);
		}
	}
	OUTPUT:
	RETVAL

=item LDispose LIST

Deletes a list.

=cut

void
LDispose(lHandle)
	ListHandle	lHandle
	CODE:
	if (lHandle[0]->listDefProc == sLDEF) {
		SV * proc = (SV *)lHandle[0]->userHandle;
		LDispose(lHandle);
		if (!--sLDEFRefCount)
			DisposeHandle(sLDEF);
		SvREFCNT_dec(proc);
	} else {
		LDispose(lHandle);
	}

=item LAddColumn count, colNum, list

Adds a number of columns to the list.

=cut

short
LAddColumn(count, colNum, lHandle)
	short	count
	short	colNum
	ListHandle	lHandle

=item LAddRow count, rowNum, list

Adds a number of rows to the list.

=cut

short
LAddRow(count, rowNum, lHandle)
	short	count
	short	rowNum
	ListHandle	lHandle

=item LDelColumn count, colNum, list

Delete a number of columns from the list.

=cut

void
LDelColumn(count, colNum, lHandle)
	short	count
	short	colNum
	ListHandle	lHandle

=item LDelRow count, colNum, list

Delete a number of rows from the list.

=cut

void
LDelRow(count, rowNum, lHandle)
	short	count
	short	rowNum
	ListHandle	lHandle


=item CELL = LGetSelect NEXT, STARTCELL, LIST

If C<NEXT> is false, returns STARTCELL if it is selected, else undef. If
C<NEXT> is true, returns next selected cell if one exists, else undef.

=cut
Point
LGetSelect(next, theCell, lHandle)
	Boolean	next
	Point &theCell
	ListHandle	lHandle
	CODE:
	if (!LGetSelect(next, &theCell, lHandle)) {
		XSRETURN_UNDEF;
	}
	RETVAL = theCell;
	OUTPUT:
	RETVAL

=item CELL = LLastClick LIST

Returns last cell clicked.

=cut

Point
LLastClick(lHandle)
	ListHandle	lHandle

=item CELL = LNextCell HNEXT, VNEXT, CELL, LIST

Returns next cell in indiacted direction or false.

=cut

Point
LNextCell(hNext, vNext, theCell, lHandle)
	Boolean	hNext
	Boolean	vNext
	Point &theCell
	ListHandle	lHandle
	CODE:
	if (!LNextCell(hNext, vNext, &theCell, lHandle)) {
		XSRETURN_UNDEF;
	}
	RETVAL = theCell;
	OUTPUT:
	RETVAL

=begin ignore

Boolean
LSearch(dataPtr, dataLen, searchProc, theCell, lHandle)
	const void *	dataPtr
	short	dataLen
	ListSearchUPP	searchProc
	Point *	theCell
	ListHandle	lHandle

=end ignore

=cut

=item LSize WIDTH, HEIGHT, LIST

Set the size of the list's visible rectangle.

=cut

void
LSize(listWidth, listHeight, lHandle)
	short	listWidth
	short	listHeight
	ListHandle	lHandle

=item LSetDrawingMode DRAWIT, LIST

Set flag to draw or not draw changes to the list.

=cut

void
LSetDrawingMode(drawIt, lHandle)
	Boolean	drawIt
	ListHandle	lHandle

=item LScroll COLS, ROWS, LIST

Scroll the list.

=cut

void
LScroll(dCols, dRows, lHandle)
	short	dCols
	short	dRows
	ListHandle	lHandle

=item LAutoScroll LIST

Scroll selection into view.

=cut

void
LAutoScroll(lHandle)
	ListHandle	lHandle

=item LUpdate REGION, LIST

Update list.

=cut

void
LUpdate(theRgn, lHandle)
	RgnHandle	theRgn
	ListHandle	lHandle

=item LActivate ACTIVE, LIST

Activate list.

=cut

void
LActivate(act, lHandle)
	Boolean	act
	ListHandle	lHandle

=item LCellSize SIZE, LIST

Set the list cell size.

=cut
void
LCellSize(cSize, lHandle)
	Point	cSize
	ListHandle	lHandle

=item DOUBLE = LClick PT, MODIFIERS, LIST

Handle a click in the list.

=cut

Boolean
LClick(pt, modifiers, lHandle)
	Point	pt
	short	modifiers
	ListHandle	lHandle

=item LAddToCell DATA, CELL, LIST

Add data to a cell.

=cut

void
LAddToCell(data, theCell, lHandle)
	SV *		data
	Point		theCell
	ListHandle	lHandle
	CODE:
	{
		STRLEN	len;
		char *	ptr = SvPV(data, len);
		
		LAddToCell(ptr, (short) len, theCell, lHandle);
	}

=item LClrCell CELL, LIST

Delete data for a cell.

=cut

void
LClrCell(theCell, lHandle)
	Point	theCell
	ListHandle	lHandle

=item DATA = LGetCell CELL, LIST

Get the data for a cell.

=cut

SV *
LGetCell(theCell, lHandle)
	Point		theCell
	ListHandle	lHandle
	CODE:
	{
		short 	offset;
		short 	len;
		Handle	cells;
		
		LGetCellDataLocation(&offset, &len, theCell, lHandle);
		HLock(cells = lHandle[0]->cells);
		RETVAL = len ? newSVpv(*cells+offset, len) : newSVpv("", 0);
		HUnlock(cells);
	}
	OUTPUT:
	RETVAL

=item RECT = LRect CELL, LIST

Get the rectangle of a cell.

=cut
Rect
LRect(theCell, lHandle)
	Point	theCell
	ListHandle	lHandle
	CODE:
	LRect(&RETVAL, theCell, lHandle);
	OUTPUT:
	RETVAL

=item LSetCell DATA, CELL, LIST

Set data for a cell.

=cut
void
LSetCell(data, theCell, lHandle)
	SV *		data
	Point		theCell
	ListHandle	lHandle
	CODE:
	{
		STRLEN	len;
		char *	ptr = SvPV(data, len);
		
		LSetCell(ptr, (short) len, theCell, lHandle);
	}

=item LSetSelect SETIT, CELL, LIST

Set selection status of a cell.

=cut

void
LSetSelect(setIt, theCell, lHandle)
	Boolean	setIt
	Point	theCell
	ListHandle	lHandle

=item LDraw CELL, LIST

Draw a cell.

=cut
void
LDraw(theCell, lHandle)
	Point	theCell
	ListHandle	lHandle

=back

=cut
