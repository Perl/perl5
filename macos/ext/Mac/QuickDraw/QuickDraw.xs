/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/QuickDraw/QuickDraw.xs,v 1.2 2000/09/09 22:18:28 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: QuickDraw.xs,v $
 * Revision 1.2  2000/09/09 22:18:28  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:32  neeri
 * Checked into Sourceforge
 *
 * Revision 1.7  1998/11/22 21:21:14  neeri
 * All packed up and no place to go
 *
 * Revision 1.6  1998/04/07 01:03:09  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.5  1997/11/18 00:53:15  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.4  1997/09/02 23:06:42  neeri
 * Added Structs, other minor fixes
 *
 * Revision 1.3  1997/08/08 16:39:29  neeri
 * MacPerl 5.1.4b1 + time() fix
 *
 * Revision 1.2  1997/05/17 21:14:34  neeri
 * Last tweaks before 5.004 merge
 *
 * Revision 1.1  1997/04/07 20:50:36  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Icons.h>
#include <QuickDraw.h>
#include <QuickDrawText.h>

typedef short Fixed412;
typedef short Fixed016;

#ifndef __CFM68K__
#include <FixMath.h>
#else
#define fixed1				((Fixed) 0x00010000L)
#define fract1				((Fract) 0x40000000L)
#define positiveInfinity	((long)  0x7FFFFFFFL)
#define negativeInfinity	((long)  0x80000000L)

extern pascal long double Frac2X(Fract x) = 0xA845;
extern pascal long double Fix2X(Fixed x) = 0xA843;
extern pascal Fixed X2Fix(long double x) = 0xA844;
extern pascal Fract X2Frac(long double x) = 0xA846;
#endif

static Point 	sZeroPoint;
static Point	sUnityPoint = {1, 1};

#define COLORPORT(Port) 	((Port->portBits.rowBytes & 0xC000) == 0xC000)
#define GRAFVARS(PORT)	(*((GVarHandle)((CGrafPtr)STRUCT)->grafVars))

MODULE = Mac::QuickDraw	PACKAGE = Mac::QuickDraw

=item GrafPtr

A QuickDraw graphics port. Fields are:

	short							device;
	BitMap							portBits;
	PixMapHandle					portPixMap;					/*For color ports only*/
	RGBColor						rgbOpColor;					/*color for addPin  subPin and average*/
	RGBColor						rgbHiliteColor;				/*color for hiliting*/
	Fixed412						chExtra;
	Fixed016						pnLocHFrac;
	Rect							portRect;
	RgnHandle						visRgn;
	RgnHandle						clipRgn;
	Pattern							bkPat;
	Pattern							fillPat;
	RGBColor						rgbFgColor;
	RGBColor						rgbBkColor;
	Point							pnLoc;
	Point							pnSize;
	short							pnMode;
	Pattern							pnPat;
	short							pnVis;
	short							txFont;
	U8								txFace;				
	short							txMode;
	short							txSize;
	Fixed							spExtra;
	long							fgColor;
	long							bkColor;
	short							colrBit;

=cut
STRUCT * GrafPtr
	short							device;
	BitMap							portBits;
	PixMapHandle					portPixMap;
		READ_ONLY
		OUTPUT:
		if (COLORPORT(STRUCT)) {
			XS_OUTPUT(PixMapHandle, ((CGrafPtr)STRUCT)->portPixMap, $arg);
		} else {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		}
	RGBColor						rgbOpColor;					/*color for addPin  subPin and average*/
		READ_ONLY
		OUTPUT:
		if (COLORPORT(STRUCT)) {
			RGBColor	color = GRAFVARS(STRUCT)->rgbOpColor;
			XS_OUTPUT(RGBColor, color, $arg);
		} else {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		}
	RGBColor						rgbHiliteColor;				/*color for hiliting*/
		READ_ONLY
		OUTPUT:
		if (COLORPORT(STRUCT)) {
			RGBColor	color = GRAFVARS(STRUCT)->rgbHiliteColor;
			XS_OUTPUT(RGBColor, color, $arg);
		} else {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		}
	Fixed412						chExtra;
		INPUT:
		if (COLORPORT(STRUCT)) {
			XS_INPUT(Fixed412, ((CGrafPtr)STRUCT)->chExtra, $arg);
		}
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		} else {
			XS_OUTPUT(Fixed412, ((CGrafPtr)STRUCT)->chExtra, $arg);
		}
	Fixed016						pnLocHFrac;
		INPUT:
		if (COLORPORT(STRUCT)) {
			XS_INPUT(Fixed016, ((CGrafPtr)STRUCT)->pnLocHFrac, $arg);
		}
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		} else {
			XS_OUTPUT(Fixed016, ((CGrafPtr)STRUCT)->pnLocHFrac, $arg);
		}
	Rect							portRect;
		READ_ONLY
	RgnHandle						visRgn;
		READ_ONLY
	RgnHandle						clipRgn;
		READ_ONLY
	Pattern							bkPat;
		READ_ONLY
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(Pattern, STRUCT->bkPat, $arg);
		} else {
			XS_OUTPUT(PixPatHandle, ((CGrafPtr)STRUCT)->bkPixPat, $arg);
		}
	Pattern							fillPat;
		READ_ONLY
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(Pattern, STRUCT->fillPat, $arg);
		} else {
			XS_OUTPUT(PixPatHandle, ((CGrafPtr)STRUCT)->fillPixPat, $arg);
		}
	RGBColor						rgbFgColor;
		READ_ONLY
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		} else {
			XS_OUTPUT(RGBColor, ((CGrafPtr)STRUCT)->rgbFgColor, $arg);
		}
	RGBColor						rgbBkColor;
		READ_ONLY
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(SV *, &PL_sv_undef, $arg);
		} else {
			XS_OUTPUT(RGBColor, ((CGrafPtr)STRUCT)->rgbBkColor, $arg);
		}
	Point							pnLoc;
	Point							pnSize;
	short							pnMode;
	Pattern							pnPat;
		READ_ONLY
		OUTPUT:
		if (!COLORPORT(STRUCT)) {
			XS_OUTPUT(Pattern, STRUCT->pnPat, $arg);
		} else {
			XS_OUTPUT(PixPatHandle, ((CGrafPtr)STRUCT)->pnPixPat, $arg);
		}
	short							pnVis;
	short							txFont;
	U8								txFace;				
	short							txMode;
	short							txSize;
	Fixed							spExtra;
	long							fgColor;
	long							bkColor;
	short							colrBit;

=item BitMap

A bitmap. All accessible fields are read-only:

	short	rowBytes;
	Rect	bounds;

=cut
STRUCT BitMap
	short	rowBytes;
		READ_ONLY
	Rect	bounds;
		READ_ONLY

=item RgnHandle

A region. All accessible fields are read-only:

	short	rgnSize;					
	Rect	rgnBBox;

=over 4

=item new RgnHandle

Create a new region.

=back

=cut
STRUCT ** RgnHandle
	short	rgnSize;					
		READ_ONLY
	Rect	rgnBBox;
		READ_ONLY

=item PicHandle

A QuickDraw picture. All accessible fields are read-only:

	short	picSize
	Rect	picFrame

=over 4

=item new PicHandle DATA

=item new PicHandle DATAHDL

Create a C<PicHandle> from binary data (presumably read out of a file).

=back

=cut
STRUCT ** PicHandle
	short	picSize
		READ_ONLY
	Rect	picFrame
		READ_ONLY

=item PolyHandle

A polygon. All accessible fields are read-only:

	short	polySize;
	Rect	polyBBox;

=cut
STRUCT ** PolyHandle
	short	polySize;
		READ_ONLY
	Rect	polyBBox;
		READ_ONLY

=item RGBColor

A RGB color value. The color components are accessible

	U16		red;						
	U16		green;						
	U16		blue;					

=cut
STRUCT RGBColor
	U16		red;						
	U16		green;						
	U16		blue;					

=over 4

=item new RGBColor RED, GREEN, BLUE

Create a new RGBColor.

=back

=item PenState

A structure with the following members:

	Point		pnLoc;
	Point		pnSize;
	short		pnMode;
	Pattern		pnPat;

=cut
STRUCT PenState
	Point		pnLoc;
	Point		pnSize;
	short		pnMode;
	Pattern		pnPat;
	
MODULE = Mac::QuickDraw	PACKAGE = Point

=item Point

A point, featuring the following fields

	short	h;
	short	v;

=cut
STRUCT Point
	short	h;
	short	v;

=over 4

=item new Point [H [, V]]

Create a new point.

=back

=cut
Point
new(class, h=0, v=0)
	SV * 	class
	short	h
	short	v
	CODE:
	RETVAL.h = h;
	RETVAL.v = v;
	OUTPUT:
	RETVAL

MODULE = Mac::QuickDraw	PACKAGE = Rect

=item Rect

A rectangle, featuring the following fields

	short	top
	short	left
	short	bottom
	short	right
	Point	topLeft
	Point	botRight

=cut
STRUCT Rect
	short	top
	short	left
	short	bottom
	short	right
	Point	topLeft
		ALIAS *(Point *)&STRUCT.top
	Point	botRight
		ALIAS *(Point *)&STRUCT.bottom

=over 4

=item new Rect [LEFT [, TOP [, RIGHT [, BOTTOM]]]]

=item new Rect TOPLEFT [,BOTRIGHT]

Create a new rectangle from either coordinates or points.

=back

=cut
Rect
_new(left=0, top=0, right=0, bottom=0)
	short	left
	short	top
	short	right
	short 	bottom
	CODE:
	RETVAL.left 	= left;
	RETVAL.top  	= top;
	RETVAL.right	= right;
	RETVAL.bottom	= bottom;
	OUTPUT:
	RETVAL

=item PixMap

A pixel map, the color equivalent to a bitmap.

	short			rowBytes;		/*offset to next line*/
	Rect			bounds;			/*encloses bitmap*/
	short			pmVersion;		/*pixMap version number*/
	short			packType;		/*defines packing format*/
	long			packSize;		/*length of pixel data*/
	Fixed			hRes;			/*horiz. resolution (ppi)*/
	Fixed			vRes;			/*vert. resolution (ppi)*/
	short			pixelType;		/*defines pixel type*/
	short			pixelSize;		/*# bits in pixel*/
	short			cmpCount;		/*# components in pixel*/
	short			cmpSize;		/*# bits per component*/
	long			planeBytes;		/*offset to next plane*/
	CTabHandle		pmTable;		/*color map for this pixMap*/

=cut
STRUCT PixMap
	short			rowBytes;					/*offset to next line*/
	Rect			bounds;						/*encloses bitmap*/
	short			pmVersion;					/*pixMap version number*/
	short			packType;					/*defines packing format*/
	long			packSize;					/*length of pixel data*/
	Fixed			hRes;						/*horiz. resolution (ppi)*/
	Fixed			vRes;						/*vert. resolution (ppi)*/
	short			pixelType;					/*defines pixel type*/
	short			pixelSize;					/*# bits in pixel*/
	short			cmpCount;					/*# components in pixel*/
	short			cmpSize;					/*# bits per component*/
	long			planeBytes;					/*offset to next plane*/
	CTabHandle		pmTable;					/*color map for this pixMap*/

=item PixMapHandle

A pixel map, the color equivalent to a bitmap.

	short			rowBytes;		/*offset to next line*/
	Rect			bounds;			/*encloses bitmap*/
	short			pmVersion;		/*pixMap version number*/
	short			packType;		/*defines packing format*/
	long			packSize;		/*length of pixel data*/
	Fixed			hRes;			/*horiz. resolution (ppi)*/
	Fixed			vRes;			/*vert. resolution (ppi)*/
	short			pixelType;		/*defines pixel type*/
	short			pixelSize;		/*# bits in pixel*/
	short			cmpCount;		/*# components in pixel*/
	short			cmpSize;		/*# bits per component*/
	long			planeBytes;		/*offset to next plane*/
	CTabHandle		pmTable;		/*color map for this pixMap*/

=cut
STRUCT ** PixMapHandle
	short			rowBytes;					/*offset to next line*/
	Rect			bounds;						/*encloses bitmap*/
	short			pmVersion;					/*pixMap version number*/
	short			packType;					/*defines packing format*/
	long			packSize;					/*length of pixel data*/
	Fixed			hRes;						/*horiz. resolution (ppi)*/
	Fixed			vRes;						/*vert. resolution (ppi)*/
	short			pixelType;					/*defines pixel type*/
	short			pixelSize;					/*# bits in pixel*/
	short			cmpCount;					/*# components in pixel*/
	short			cmpSize;					/*# bits per component*/
	long			planeBytes;					/*offset to next plane*/
	CTabHandle		pmTable;					/*color map for this pixMap*/

=item PixPatHandle

A pixel pattern.

	short			patType;	/*type of pattern*/
	PixMapHandle	patMap;		/*the pattern's pixMap*/
	Handle			patData;	/*pixmap's data*/
	Handle			patXData;	/*expanded Pattern data*/
	short			patXValid;	/*flags whether expanded Pattern valid*/
	Handle			patXMap;	/*Handle to expanded Pattern data*/
	Pattern			pat1Data;	/*old-Style pattern/RGB color*/

=cut
STRUCT ** PixPatHandle
	short							patType;					/*type of pattern*/
	PixMapHandle					patMap;						/*the pattern's pixMap*/
	Handle							patData;					/*pixmap's data*/
	Handle							patXData;					/*expanded Pattern data*/
	short							patXValid;					/*flags whether expanded Pattern valid*/
	Handle							patXMap;					/*Handle to expanded Pattern data*/
	Pattern							pat1Data;					/*old-Style pattern/RGB color*/

=item CTabHandle

A color table. Currently, the colors are not yet accessible, but the following are:

	long	ctSeed;		/*unique identifier for table*/
	short	ctFlags;	/*high bit: 0 = PixMap; 1 = device*/
	short	ctSize;		/*number of entries in CTTable*/

=cut
STRUCT ** CTabHandle
	long	ctSeed;		/*unique identifier for table*/
	short	ctFlags;	/*high bit: 0 = PixMap; 1 = device*/
	short	ctSize;		/*number of entries in CTTable*/

=item CCrsrHandle

A color cursor.

	short			crsrType;					/*type of cursor*/
	PixMapHandle	crsrMap;					/*the cursor's pixmap*/
	Handle			crsrData;					/*cursor's data*/
	Handle			crsrXData;					/*expanded cursor data*/
	short			crsrXValid;					/*depth of expanded data (0 if none)*/
	Cursor			crsr1;						/*one-bit cursor and hotspot*/

=cut
STRUCT ** CCrsrHandle
	short			crsrType;					/*type of cursor*/
	PixMapHandle	crsrMap;					/*the cursor's pixmap*/
	Handle			crsrData;					/*cursor's data*/
	Handle			crsrXData;					/*expanded cursor data*/
	short			crsrXValid;					/*depth of expanded data (0 if none)*/
	Cursor			crsr1;						/*one-bit cursor and hotspot*/
		ALIAS *(Cursor *)&STRUCT[0]->crsr1Data

=item CIconHandle

A color icon

	PixMap			iconPMap;					/*the icon's pixMap*/
	BitMap			iconMask;					/*the icon's mask*/
	BitMap			iconBMap;					/*the icon's bitMap*/
	Handle			iconData;					/*the icon's data*/

=cut
STRUCT ** CIconHandle
	PixMap			iconPMap;					/*the icon's pixMap*/
	BitMap			iconMask;					/*the icon's mask*/
	BitMap			iconBMap;					/*the icon's bitMap*/
	Handle			iconData;					/*the icon's data*/

=item GDHandle

A graphics device

	short			gdRefNum;					/*driver's unit number*/
	short			gdID;						/*client ID for search procs*/
	short			gdType;						/*fixed/CLUT/direct*/
	short			gdResPref;					/*preferred resolution of GDITable*/
	short			gdFlags;					/*grafDevice flags word*/
	PixMapHandle	gdPMap;						/*describing pixMap*/
	long			gdRefCon;					/*reference value*/
	GDHandle		gdNextGD;					/*GDHandle Handle of next gDevice*/
	Rect			gdRect;						/* device's bounds in global coordinates*/
	long			gdMode;						/*device's current mode*/
	short			gdCCBytes;					/*depth of expanded cursor data*/
	short			gdCCDepth;					/*depth of expanded cursor data*/

=cut
STRUCT ** GDHandle
	short			gdRefNum;					/*driver's unit number*/
	short			gdID;						/*client ID for search procs*/
	short			gdType;						/*fixed/CLUT/direct*/
	short			gdResPref;					/*preferred resolution of GDITable*/
	short			gdFlags;					/*grafDevice flags word*/
	PixMapHandle	gdPMap;						/*describing pixMap*/
	long			gdRefCon;					/*reference value*/
	GDHandle		gdNextGD;					/*Handle of next gDevice*/
		INPUT:
		XS_INPUT(GDHandle, *(GDHandle *)&STRUCT[0]->gdNextGD, $arg);
	Rect			gdRect;						/* device's bounds in global coordinates*/
	long			gdMode;						/*device's current mode*/
	short			gdCCBytes;					/*depth of expanded cursor data*/
	short			gdCCDepth;					/*depth of expanded cursor data*/

=back

=cut

MODULE = Mac::QuickDraw	PACKAGE = Mac::QuickDraw

=head2 Functions

=over 4

=item SetPort PORT

Set the current port.

=cut
void
SetPort(port)
	GrafPtr 	port

=item GetPort()

Return the current port.

=cut
GrafPtr
GetPort()
	CODE:
	GetPort(&RETVAL);
	OUTPUT:
	RETVAL

=item SetOrigin H, V

Set the origin of the current port.

=cut
void
SetOrigin(h, v)
	short 	h
	short 	v

=item SetClip REGION

Set the clipping region of the current port to a copy of C<REGION>.

=cut
void
SetClip(rgn)
	RgnHandle 	rgn

=item REGION = GetClip [REGION]

Get the clipping region.

=cut
RgnHandle
GetClip(rgn=nil)
	RgnHandle 	rgn
	CODE:
	if (!(RETVAL = rgn))
		RETVAL = NewRgn();
	GetClip(RETVAL);
	OUTPUT:
	RETVAL

=item ClipRect RECT

Set the clipping region to a rectangular region.

=cut
void
ClipRect(r)
	Rect &r

=item BackPat PATTERN

Set background fill pattern.

=cut
void
BackPat(pat)
	Pattern &pat

=item InitCursor

Set the cursor to the arrow cursor.

=cut
void
InitCursor()

=item SetCursor [ CURSOR | ID ]

Set the cursor to a cursor specified as a shape or a resource ID.

=cut
void
_SetCursor(crsr=qd.arrow)
	Cursor &crsr
	CODE:
	SetCursor(&crsr);

=item HideCursor

Hide the cursor.

=cut
void
HideCursor()

=item ShowCursor

Show the cursor.

=cut
void
ShowCursor()

=item ObscureCursor

Hide the cursor until it is moved again.

=cut
void
ObscureCursor()

=item HidePen

Hide the "pen" drawing lines.

=cut
void
HidePen()

=item ShowPen

Show the "pen".

=cut
void
ShowPen()

=item GetPen()

Returns the pen position.

=cut
Point
GetPen()
	CODE:
	GetPen(&RETVAL);
	OUTPUT:
	RETVAL

=item GetPenState()

Returns the pen state.

=cut
PenState
GetPenState()
	CODE:
	GetPenState(&RETVAL);
	OUTPUT:
	RETVAL

=item SetPenState STATE

Restores a previously returned pen state.

=cut
void
SetPenState(pnState)
	PenState &pnState

=item PenSize WIDTH, HEIGHT

Set the pen size.

=cut
void
PenSize(width, height)
	short 	width
	short 	height

=item PenMode MODE

Set the pen mode.

=cut
void
PenMode(mode)
	short 	mode

=item PenPat PATTERN

Set the pen pattern.

=cut
void
PenPat(pat)
	Pattern &pat

=item PenNormal

Restore the pen to a sane state.

=cut
void
PenNormal()

=item MoveTo H, V

Move the pen without drawing.

=cut
void
MoveTo(H, V)
	short 	H
	short 	V

=item Move DH, DV

Move pen relatively.

=cut
void
Move(dh, dv)
	short 	dh
	short 	dv

=item LineTo H, V

Draw a line.

=cut
void
LineTo(H, V)
	short 	H
	short 	V

=item Line DH, DV

Draw relative line.

=cut
void
Line(dh, dv)
	short 	dh
	short 	dv

=item ForeColor COLOR

Set the foreground (Classic QuickDraw) color.

=cut
void
ForeColor(color)
	long 	color

=item BackColor COLOR

Set the background (Classic QuickDraw) color.

=cut
void
BackColor(color)
	long 	color

=item OffsetRect RECT, DH, DV

Return a rectangle offset relatively.

=cut
Rect
OffsetRect(r, dh, dv)
	Rect   &r
	short 	dh
	short 	dv
	CODE:
	RETVAL = r;
	OffsetRect(&RETVAL, dh, dv);
	OUTPUT:
	RETVAL

=item NEWRECT = InsetRect RECT, DH, DV

Return the rectangle with its boundaries moved inwards or outwards.

=cut
Rect
InsetRect(r, dh, dv)
	Rect    &r
	short 	dh
	short 	dv
	CODE:
	RETVAL = r;
	InsetRect(&RETVAL, dh, dv);
	OUTPUT:
	RETVAL

=item SectRect RECT1, RECT2

Return intersection of two rectangles or undef.

=cut
Rect
SectRect(src1, src2)
	Rect &src1
	Rect &src2
	CODE:
	if (!SectRect(&src1, &src2, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item UnionRect RECT1, RECT2

Return union of two rectangles.

=cut
Rect
UnionRect(src1, src2)
	Rect &src1
	Rect &src2
	CODE:
	UnionRect(&src1, &src2, &RETVAL);
	OUTPUT:
	RETVAL

=item EqualRect RECT1, RECT2

Compare two rectangles.

=cut
Boolean
EqualRect(rect1, rect2)
	Rect &rect1
	Rect &rect2

=item EmptyRect RECT

Is a rectangle empty?

=cut
Boolean
EmptyRect(r)
	Rect &r

=item FrameRect RECT

Draw a frame around the rectangle.

=cut
void
FrameRect(r)
	Rect &r

=item PaintRect RECT

Fill a rectangle with the pen pattern.

=cut
void
PaintRect(r)
	Rect &r

=item EraseRect RECT

Fill a rectangle with the background pattern.

=cut
void
EraseRect(r)
	Rect &r

=item InvertRect RECT

Invert a rectangle.

=cut
void
InvertRect(r)
	Rect &r

=item FillRect RECT, PATTERN

Fill a rectangle with the given pattern.

=cut
void
FillRect(r, pat)
	Rect 	&r
	Pattern &pat

=item FrameOval RECT

=item PaintOval RECT

=item EraseOval RECT

=item InvertOval RECT

=item FillOval RECT

Same as the C<...Rect> operations, but operating on an oval inscribed 
in the rectangle.

=cut
void
FrameOval(r)
	Rect &r

void
PaintOval(r)
	Rect &r

void
EraseOval(r)
	Rect &r

void
InvertOval(r)
	Rect &r

void
FillOval(r, pat)
	Rect 	&r
	Pattern &pat

=item FrameRoundRect RECT, CORNERWIDTH, CORNERHEIGHT

=item PaintRoundRect RECT, CORNERWIDTH, CORNERHEIGHT

=item EraseRoundRect RECT, CORNERWIDTH, CORNERHEIGHT

=item InvertRoundRect RECT, CORNERWIDTH, CORNERHEIGHT

=item FillRoundRect RECT, CORNERWIDTH, CORNERHEIGHT, PATTERN

Same as the C<...Rect> operations, but operating on an rectangle with
rounded corners.

=cut
void
FrameRoundRect(r, ovalWidth, ovalHeight)
	Rect &r
	short 	ovalWidth
	short 	ovalHeight

void
PaintRoundRect(r, ovalWidth, ovalHeight)
	Rect &r
	short 	ovalWidth
	short 	ovalHeight

void
EraseRoundRect(r, ovalWidth, ovalHeight)
	Rect &r
	short 	ovalWidth
	short 	ovalHeight

void
InvertRoundRect(r, ovalWidth, ovalHeight)
	Rect &r
	short 	ovalWidth
	short 	ovalHeight

void
FillRoundRect(r, ovalWidth, ovalHeight, pat)
	Rect &r
	short 	ovalWidth
	short 	ovalHeight
	Pattern &pat

=item FrameArc RECT, STARTANGLE, ARCANGLE

=item PaintArc RECT, STARTANGLE, ARCANGLE

=item EraseArc RECT, STARTANGLE, ARCANGLE

=item InvertArc RECT, STARTANGLE, ARCANGLE

=item FillArc RECT, STARTANGLE, ARCANGLE, PATTERN

Same as the C<...Oval> operations, but operating on a sector of the oval.

=cut
void
FrameArc(r, startAngle, arcAngle)
	Rect &r
	short 	startAngle
	short 	arcAngle

void
PaintArc(r, startAngle, arcAngle)
	Rect &r
	short 	startAngle
	short 	arcAngle

void
EraseArc(r, startAngle, arcAngle)
	Rect &r
	short 	startAngle
	short 	arcAngle

void
InvertArc(r, startAngle, arcAngle)
	Rect &r
	short 	startAngle
	short 	arcAngle

void
FillArc(r, startAngle, arcAngle, pat)
	Rect &r
	short 	startAngle
	short 	arcAngle
	Pattern &pat

=item REGION = NewRgn()

Create a region.

=cut
RgnHandle
NewRgn()	

=item OpenRgn

Start capturing commands to define a region.

=cut
void
OpenRgn()

=item REGION = CloseRgn [ REGION ]

End capturing and return the region.

=cut
RgnHandle
CloseRgn(dstRgn=NULL)
	RgnHandle 	dstRgn
	CODE:
	if (!(RETVAL = dstRgn))
		RETVAL = NewRgn();
	CloseRgn(RETVAL);
	OUTPUT:
	RETVAL

=item BitMapToRegion [REGION, ] BITMAP

Turn a bitmap into a region, creating the region if none is passed.

=cut
MacOSRet
_BitMapToRegion(region, bMap)
	RgnHandle 	region
	BitMap     &bMap
	CODE:
	RETVAL = BitMapToRegion(region, &bMap);
	OUTPUT:
	RETVAL

=item DisposeRgn REGION

Dispose a region.

=cut
void
DisposeRgn(rgn)
	RgnHandle 	rgn

=item CopyRgn SRCREGION [, DESTREGION]

Make a copy of a region.

=cut
RgnHandle
CopyRgn(srcRgn, dstRgn=NULL)
	RgnHandle 	srcRgn
	RgnHandle 	dstRgn
	CODE:
	if (!(RETVAL = dstRgn))
		RETVAL = NewRgn();
	CopyRgn(srcRgn, RETVAL);
	OUTPUT:
	RETVAL

=item SetEmptyRegion REGION

Set a region to the empty region.

=cut
void
SetEmptyRgn(rgn)
	RgnHandle 	rgn

=item SetRectRgn REGION, LEFT, TOP, RIGHT, BOTTOM

Set a region to a rectangle.

=cut
void
SetRectRgn(rgn, left, top, right, bottom)
	RgnHandle 	rgn
	short 	left
	short 	top
	short 	right
	short 	bottom

=item RectRgn [REGION, ] RECT

Create or copy a region from a rectangle.

=cut
void
_RectRgn(rgn, r)
	RgnHandle 	rgn
	Rect 		&r
	CODE:
	RectRgn(rgn, &r);

=item OffsetRgn REGION, DH, DV

Shift a region.

=cut
void
OffsetRgn(rgn, dh, dv)
	RgnHandle 	rgn
	short 	dh
	short 	dv

=item InsetRgn REGION, DH, DV

Inset a region.

=cut
void
InsetRgn(rgn, dh, dv)
	RgnHandle 	rgn
	short 	dh
	short 	dv

=item SectRgn REG1, REG2 [, SECT]

Return the intersection of two regions.

=cut
RgnHandle
SectRgn(srcRgnA, srcRgnB, dstRgn=NULL)
	RgnHandle 	srcRgnA
	RgnHandle 	srcRgnB
	RgnHandle 	dstRgn
	CODE:
	if (!(RETVAL = dstRgn))
		RETVAL = NewRgn();
	SectRgn(srcRgnA, srcRgnB, RETVAL);
	OUTPUT:
	RETVAL

=item UnionRgn REG1, REG2 [, SECT]

Return the union of two regions.

=cut
RgnHandle
UnionRgn(srcRgnA, srcRgnB, dstRgn=NULL)
	RgnHandle 	srcRgnA
	RgnHandle 	srcRgnB
	RgnHandle 	dstRgn
	CODE:
	if (!(RETVAL = dstRgn))
		RETVAL = NewRgn();
	UnionRgn(srcRgnA, srcRgnB, RETVAL);
	OUTPUT:
	RETVAL

=item DiffRgn REG1, REG2 [, SECT]

Return the difference between two regions.

=cut
RgnHandle
DiffRgn(srcRgnA, srcRgnB, dstRgn=NULL)
	RgnHandle 	srcRgnA
	RgnHandle 	srcRgnB
	RgnHandle 	dstRgn
	CODE:
	if (!(RETVAL = dstRgn))
		RETVAL = NewRgn();
	DiffRgn(srcRgnA, srcRgnB, RETVAL);
	OUTPUT:
	RETVAL

=item XorRgn REG1, REG2 [, SECT]

Return the symmetric difference between two regions.

=cut
RgnHandle
XorRgn(srcRgnA, srcRgnB, dstRgn=NULL)
	RgnHandle 	srcRgnA
	RgnHandle 	srcRgnB
	RgnHandle 	dstRgn
	CODE:
	if (!(RETVAL = dstRgn))
		RETVAL = NewRgn();
	XorRgn(srcRgnA, srcRgnB, RETVAL);
	OUTPUT:
	RETVAL

=item INSIDE = RectInRgn RECT, REGION

Test if a rectangle is contained in a region.

=cut
Boolean
RectInRgn(r, rgn)
	Rect 	   &r
	RgnHandle 	rgn

=item EQUAL = EqualRgn REG1, REG2

Compare two regions.

=cut
Boolean
EqualRgn(rgnA, rgnB)
	RgnHandle 	rgnA
	RgnHandle 	rgnB

=item EmptyRgn REGION

Test if a region is empty.

=cut
Boolean
EmptyRgn(rgn)
	RgnHandle 	rgn

=item FrameRgn REGION

=item PaintRgn REGION

=item EraseRgn REGION

=item InvertRgn REGION

=item FillRgn REGION, PATTERN

Analogous to the C<...Rect> operations.

=cut
void
FrameRgn(rgn)
	RgnHandle 	rgn

void
PaintRgn(rgn)
	RgnHandle 	rgn

void
EraseRgn(rgn)
	RgnHandle 	rgn

void
InvertRgn(rgn)
	RgnHandle 	rgn

void
FillRgn(rgn, pat)
	RgnHandle rgn
	Pattern  &pat

=item ScrollRect RECT, DH, DV [, UPDATERGN]

Scroll the contents of a rectangle and return a region to be updated.

=cut
RgnHandle
ScrollRect(r, dh, dv, updateRgn)
	Rect 	   &r
	short 		dh
	short 		dv
	RgnHandle 	updateRgn
	CODE:
	if (!(RETVAL = updateRgn))
		RETVAL = NewRgn();
	ScrollRect(&r, dh, dv, RETVAL);
	OUTPUT:
	RETVAL

=item CopyBits SRCBITS, DESTBITS, SRCRECT, DSTRECT, MODE [, MASKRGN]

Copy the contents of a rectangle from one bitmap into another.

=cut
void
CopyBits(srcBits, dstBits, srcRect, dstRect, mode, maskRgn=NULL)
	BitMap	 &srcBits
	BitMap	 &dstBits
	Rect     &srcRect
	Rect     &dstRect
	short 	  mode
	RgnHandle maskRgn

=item CopyMask SRCBITS, MASKBITS, DESTBITS, SRCRECT, MASKRECT, DSTRECT

Copy the masked contents of a rectangle from one bitmap into another.

=cut
void
CopyMask(srcBits, maskBits, dstBits, srcRect, maskRect, dstRect)
	BitMap &srcBits
	BitMap &maskBits
	BitMap &dstBits
	Rect   &srcRect
	Rect   &maskRect
	Rect   &dstRect

=item OpenPicture RECT

Start capturing commands to define a picture.

=cut
PicHandle
OpenPicture(picFrame)
	Rect &picFrame


=item PicComment KIND, DATASIZE, DATAHANDLE

Insert a comment into the picture being defined.

=cut
void
PicComment(kind, dataSize, dataHandle)
	short 	kind
	short 	dataSize
	Handle 	dataHandle

=item ClosePicture

Stop capturing and return the picture.

=cut
void
ClosePicture()

=item DrawPicture PICT, RECT

Draw a picture.

=cut
void
DrawPicture(myPicture, dstRect)
	PicHandle 	myPicture
	Rect	   &dstRect

=item KillPicture PICT

Destroy a picture.

=cut
void
KillPicture(myPicture)
	PicHandle 	myPicture

=item POLY = OpenPoly()

Start capturing commands to define a polygon.

=cut
PolyHandle
OpenPoly()

=item ClosePoly()

Stop capturing and return the polygon.

=cut
void
ClosePoly()

=item KillPoly POLY

Destroy a polygon.

=cut
void
KillPoly(poly)
	PolyHandle 	poly

=item OffsetPoly POLY, DH, DV

Move a polygon.

=cut
void
OffsetPoly(poly, dh, dv)
	PolyHandle 	poly
	short 	dh
	short 	dv

=item FramePoly POLY

=item PaintPoly POLY

=item ErasePoly POLY

=item InvertPoly POLY

=item FillPoly POLY, PATTERN

Analogous to their C<...Rgn> equivalents.

=cut
void
FramePoly(poly)
	PolyHandle 	poly

void
PaintPoly(poly)
	PolyHandle 	poly

void
ErasePoly(poly)
	PolyHandle 	poly

void
InvertPoly(poly)
	PolyHandle 	poly

void
FillPoly(poly, pat)
	PolyHandle 	poly
	Pattern     &pat

=item LocalToGlobal LPT

Translate from port coordinates to global coordinates.

=cut
Point
LocalToGlobal(pt)
	Point	pt
	CODE:
	{
		RETVAL = pt;
		LocalToGlobal(&RETVAL);
	}
	OUTPUT:
	RETVAL

=item GlobalToLocal GPT

Translate from global coordinates to port coordinates.

=cut
Point
GlobalToLocal(pt)
	Point	pt
	CODE:
	{
		RETVAL = pt;
		GlobalToLocal(&RETVAL);
	}
	OUTPUT:
	RETVAL

=item Random()

Return a random number.

=cut
short
Random()
		
=item GetPixel H, V

Return the value of a screen pixel.

=cut
Boolean
GetPixel(h, v)
	short 	h
	short 	v

=item ScalePt PT, SRCRECT, DSTRECT

Map a (height, width) from a source area to a destination area.

=cut
Point
ScalePt(pt, srcRect, dstRect)
	Point  pt
	Rect  &srcRect
	Rect  &dstRect
	CODE:
	{
		RETVAL = pt;
		ScalePt(&RETVAL, &srcRect, &dstRect);
	}
	OUTPUT:
	RETVAL

=item MapPt PT, SRCRECT, DSTRECT

Map a point from a source area to a destination area and return it.

=cut
Point
MapPt(pt, srcRect, dstRect)
	Point  pt
	Rect  &srcRect
	Rect  &dstRect
	CODE:
	{
		RETVAL = pt;
		MapPt(&RETVAL, &srcRect, &dstRect);
	}
	OUTPUT:
	RETVAL

=item MapRect RECT, SRCRECT, DSTRECT

Map a rectangle from a source area to a destination area and return it.

=cut
Rect
MapRect(r, srcRect, dstRect)
	Rect  &r
	Rect  &srcRect
	Rect  &dstRect
	CODE:
	{
		RETVAL = r;
		MapRect(&RETVAL, &srcRect, &dstRect);
	}
	OUTPUT:
	RETVAL

=item MapRgn REGION, SRCRECT, DSTRECT

Map a region from a source area to a destination area.

=cut
void
MapRgn(rgn, srcRect, dstRect)
	RgnHandle 	rgn
	Rect  &srcRect
	Rect  &dstRect

=item MapPoly POLY, SRCRECT, DSTRECT

Map a polygon from a source area to a destination area.

=cut
void
MapPoly(poly, srcRect, dstRect)
	PolyHandle 	poly
	Rect &srcRect
	Rect &dstRect

=item PtInRect PT, RECT

Test whether a point is in a rectangle.

=cut
Boolean
PtInRect(pt, r)
	Point pt
	Rect &r

=item AddPt P1, P2

Add two points.

=cut
Point
AddPt(src, dst)
	Point	src
	Point 	dst
	CODE:
	RETVAL = dst;
	AddPt(src, &RETVAL);
	OUTPUT:
	RETVAL

=item EqualPt P1, P2

Compare two points.

=cut
Boolean
EqualPt(pt1, pt2)
	Point	pt1
	Point	pt2

=item Pt2Rect TOPLEFT, BOTRIGHT

Create a rectangle from two corner points.

=cut
Rect
Pt2Rect(pt1, pt2)
	Point	pt1
	Point	pt2
	CODE:
	Pt2Rect(pt1, pt2, &RETVAL);
	OUTPUT:
	RETVAL

=item SubPt SUBTRAHEND, MINUEND

Subtract two points.

=cut
Point
SubPt(src, dst)
	Point	src
	Point 	&dst
	CODE:
	RETVAL = dst;
	SubPt(src, &RETVAL);
	OUTPUT:
	RETVAL

=item PtToAngle RECT, PT

Determine the angle of a point within an oval.

=cut
short
PtToAngle(r, pt)
	Rect  &r
	Point pt
	CODE:
	PtToAngle(&r, pt, &RETVAL);
	OUTPUT:
	RETVAL
		
=item PtInRgn PT, REGION

Test whether a point is in a region.

=cut
Boolean
PtInRgn(pt, rgn)
	Point		pt
	RgnHandle 	rgn

=item PIXMAP = NewPixMap()

Create a new pixel map.

=cut
PixMapHandle
NewPixMap()

=item DisposePixMap PIXMAP

Destroy a pixel map.

=cut
void
DisposePixMap(pm)
	PixMapHandle 	pm

=item CopyPixMap PIXMAP [, DSTPIXMAP]

Copy a pixmap.

=cut
PixMapHandle
CopyPixMap(srcPM, dstPM=NULL)
	PixMapHandle 	srcPM
	PixMapHandle 	dstPM
	CODE:
	if (!(RETVAL = dstPM))
		RETVAL = NewPixMap();
	CopyPixMap(srcPM, RETVAL);
	OUTPUT:
	RETVAL

=item PIXPAT = NewPixPat()

Create a pixel pattern.

=cut
PixPatHandle
NewPixPat()

=item DisposePixPat PIXPAT

Destroy a pixel pattern.

=cut
void
DisposePixPat(pp)
	PixPatHandle 	pp

=item CopyPixPat PIXPAT [, DSTPIXPAT]

Copy a pixpat.

=cut
PixPatHandle
CopyPixPat(srcPP, dstPP=NULL)
	PixPatHandle 	srcPP
	PixPatHandle 	dstPP
	CODE:
	if (!(RETVAL = dstPP))
		RETVAL = NewPixPat();
	CopyPixPat(srcPP, RETVAL);
	OUTPUT:
	RETVAL

=item PenPixPat PIXPAT

Set the pen pixel pattern.

=cut
void
PenPixPat(pp)
	PixPatHandle 	pp

=item BackPixPat PIXPAT

Set the fill pixel pattern.

=cut
void
BackPixPat(pp)
	PixPatHandle 	pp

=item GetPixPat ID

Get a pixel pattern from a resource.

=cut
PixPatHandle
GetPixPat(patID)
	short 	patID

=item MakeRGBPat [PATTERN, ] COLOR

Create a pixel pattern for a dithered color.

=cut
void
_MakeRGBPat(pp, myColor)
	PixPatHandle   pp
	RGBColor 	 & myColor
	CODE:
	MakeRGBPat(pp, &myColor);

=item FillCRect RECT, PIXPAT

=item FillCOval RECT, PIXPAT

=item FillCRoundRect RECT, CORNERWIDTH, CORNERHEIGHT, PIXPAT

=item FillCArc RECT, STARTANGLE, ARCANGLE, PIXPAT

=item FillCRgn REGION, PIXPAT

=item FillCPoly POLY, PIXPAT

Fill routines using pixel patterns instead of black and white patterns.

=cut
void
FillCRect(r, pp)
	Rect         &r
	PixPatHandle  pp

void
FillCOval(r, pp)
	Rect         &r
	PixPatHandle  pp

void
FillCRoundRect(r, ovalWidth, ovalHeight, pp)
	Rect   &r
	short 	ovalWidth
	short 	ovalHeight
	PixPatHandle 	pp

void
FillCArc(r, startAngle, arcAngle, pp)
	Rect   &r
	short 	startAngle
	short 	arcAngle
	PixPatHandle 	pp

void
FillCRgn(rgn, pp)
	RgnHandle 	rgn
	PixPatHandle 	pp

void
FillCPoly(poly, pp)
	PolyHandle 	poly
	PixPatHandle 	pp

=item RGBForeColor COLOR

Set an RGB color as the foreground color.

=cut
void
RGBForeColor(color)
	RGBColor &color

=item RGBBackColor COLOR

Set an RGB color as the background color.

=cut
void
RGBBackColor(color)
	RGBColor &color

=item SetCPixel H, V, COLOR

Set a pixel.

=cut
void
SetCPixel(h, v, color)
	short 	h
	short 	v
	RGBColor &color

=item SetPortPix PIXMAP

Set the pixmap for the current port.

=cut
void
SetPortPix(pm)
	PixMapHandle 	pm

=item GetCPixel H, V

Get the color of a pixel.

=cut
RGBColor
GetCPixel(h, v)
	short 	h
	short 	v
	CODE:
	GetCPixel(h, v, &RETVAL);
	OUTPUT:
	RETVAL

=item GetForeColor

Return the foreground color.

=cut
RGBColor
GetForeColor()
	CODE:
	GetForeColor(&RETVAL);
	OUTPUT:
	RETVAL

=item GetBackColor

Return the background color.

=cut
RGBColor
GetBackColor()
	CODE:
	GetBackColor(&RETVAL);
	OUTPUT:
	RETVAL

=item PICT = OpenCPicture RECT [, HRES, VRES]

Start capturing a color picture.

=cut
PicHandle
OpenCPicture(r, hRes=0x0048000, vRes=0x0048000)
	Rect	r
	Fixed	hRes
	Fixed 	vRes
	PREINIT:
	OpenCPicParams	params;
	CODE:
	{
		params.srcRect = r;
		params.hRes    = hRes;
		params.vRes    = vRes;
		params.version = -2;
		params.reserved1 = params.reserved2 = 0;
		RETVAL = OpenCPicture(&params);
	}
	OUTPUT:
	RETVAL

=item OpColor COLOR

Set color operand for pin and blend modes.

=cut
void
OpColor(color)
	RGBColor &color

=item HiliteColor COLOR

Set hilite color.

=cut
void
HiliteColor(color)
	RGBColor &color

=item DisposeCTable CTABLE

Dispose a color table.

=cut
void
DisposeCTable(cTable)
	CTabHandle 	cTable

=item CTABLE = GetCTable ID

Read a color table from a resource.

=cut
CTabHandle
GetCTable(ctID)
	short 	ctID

=item CURSOR = GetCCursor ID

Read a color cursor from a resource.

=cut
CCrsrHandle
GetCCursor(crsrID)
	short 	crsrID

=item SetCCursor CURSOR

Set a color cursor.

=cut
void
SetCCursor(cCrsr)
	CCrsrHandle 	cCrsr

=item DisposeCCursor CURSOR

Destroy a color cursor.

=cut
void
DisposeCCursor(cCrsr)
	CCrsrHandle 	cCrsr

=item GetCIcon ID

Read a color icon.

=cut
CIconHandle
GetCIcon(iconID)
	short 	iconID

=item PlotCIcon RECT, ICON

Plot a color icon.

=cut
void
PlotCIcon(theRect, theIcon)
	Rect 	   &theRect
	CIconHandle theIcon

=item DisposeCIcon ICON

Destroy a color icon.

=cut
void
DisposeCIcon(theIcon)
	CIconHandle 	theIcon

=item GetMaxDevice RECT

Get the device containing the largest portion of the rectangle.

=cut
GDHandle
GetMaxDevice(globalRect)
	Rect &globalRect

=item GetDeviceList()

Get the first device.

=cut
GDHandle
GetDeviceList()

=item GetMainDevice()

Get the main device.

=cut
GDHandle
GetMainDevice()

=item GetNextDevice PREVGDEVICE

Get the next device in the device list.

=cut
GDHandle
GetNextDevice(curDevice)
	GDHandle 	curDevice

=item TestDeviceAttribute GDEVICE, ATTR

Test a device for attributes.

=cut
Boolean
TestDeviceAttribute(gdh, attribute)
	GDHandle 	gdh
	short 	attribute

=item SetDeviceAttribute GDEVICE, ATTR, VAL

Set deive attributes.

=cut
void
SetDeviceAttribute(gdh, attribute, value)
	GDHandle 	gdh
	short 	attribute
	Boolean 	value

=item NewGDevice REFNUM, MODE

Create a new graphics device.

=cut
GDHandle
NewGDevice(refNum, mode)
	short 	refNum
	long 	mode

=item DisposeGDevice GDEVICE

Destroy a graphics device structure.

=cut
void
DisposeGDevice(gdh)
	GDHandle 	gdh

=item SetGDevice GDEVICE

Set the device of the current port.

=cut
void
SetGDevice(gd)
	GDHandle 	gd

=item GetGDevice 

Return the device of the current port.

=cut
GDHandle
GetGDevice()

=item Color2Index COLOR 

Translate a color into an index in the color table.

=cut
long
Color2Index(myColor)
	RGBColor &myColor

=item Index2Color INDEX 

Translate an index into its color.

=cut
RGBColor
Index2Color(index)
	long 	index
	CODE:
	Index2Color(index, &RETVAL);
	OUTPUT:
	RETVAL

=item InvertColor COLOR 

Return the inverse color.

=cut
RGBColor
InvertColor(myColor)
	RGBColor &myColor
	CODE:
	RETVAL = myColor;
	InvertColor(&RETVAL);
	OUTPUT:
	RETVAL

=item RealColor COLOR 

Test if the color is available.

=cut
Boolean
RealColor(color)
	RGBColor &color

=item ERROR = QDError()

=cut
MacOSRet
QDError()
		
=item CopyDeepMask SRCBITS, MASKBITS, DSTBITS, SRCRECT, MASKRECT, DSTRECT, MODE, MASKRGN

Combines the effects of C<CopyBits> and C<CopyMask>.

=cut
void
CopyDeepMask(srcBits, maskBits, dstBits, srcRect, maskRect, dstRect, mode, maskRgn=NULL)
	BitMap &srcBits
	BitMap &maskBits
	BitMap &dstBits
	Rect   &srcRect
	Rect   &maskRect
	Rect   &dstRect
	short 	mode
	RgnHandle 	maskRgn

=item GetPattern ID

Read a pattern from a resource.

=cut
Pattern
GetPattern(patternID)
	short 	patternID
	PREINIT:
	PatHandle	ph;
	CODE:
	if (!(ph = GetPattern(patternID)))
		XSRETURN_UNDEF;
	else
		RETVAL = **ph;
	OUTPUT:
	RETVAL

=item GetCursor ID

Read a cursor from a resource.

=cut
Cursor
GetCursor(cursorID)
	short 	cursorID
	PREINIT:
	CursHandle	ch;
	CODE:
	if (!(ch = GetCursor(cursorID)))
		XSRETURN_UNDEF;
	else
		RETVAL = **ch;
	OUTPUT:
	RETVAL

=item GetPicture ID

Read a picture from a resource.

=cut
PicHandle
GetPicture(pictureID)
	short 	pictureID

=item ShieldCursor RECT [, OFFSET]

Define a rectangle within which the cursor is hidden.

=cut
void
ShieldCursor(shieldRect, pt=sZeroPoint)
	Rect   &shieldRect
	Point	pt

=item ScreenRes();

Return the resolution of the screen.

   ($hres, $vres) = ScreenRes;

=cut
void
ScreenRes()
	PREINIT:
	short scrnHRes;
	short scrnVRes;
	PPCODE:
	{
		ScreenRes(&scrnHRes, &scrnVRes);
		XS_XPUSH(short, scrnHRes);
		if (GIMME == G_ARRAY) {
			XS_XPUSH(short, scrnVRes);
		}
	}

=item GetIndPattern ID, INDEX

Get a pattern from a pattern list resource.

=cut
Pattern
GetIndPattern(patternListID, index)
	short 	patternListID
	short 	index
	CODE:
	GetIndPattern(&RETVAL, patternListID, index);
	OUTPUT:
	RETVAL

=item (POS, LEADING, WIDTH) = PixelToChar TEXT, SLOP, WIDTH, STYLERUN [, NUMER, DENOM]

Map a pixel position into a character position.

	($characterPosition, $leadingEdge, $widthRemaining) =
		PixelToChar("Hello, World", 0, 35, smMiddleStyleRun);

=cut
void
PixelToChar(text, slop, pixelWidth, styleRunPosition, numer=sUnityPoint, denom=sUnityPoint)
	SV *	text
	Fixed 	slop
	Fixed 	pixelWidth
	JustStyleCode 	styleRunPosition
	Point	numer;
	Point	denom;
	PPCODE:
	{
		short	pos;
		Boolean	leadingEdge;
		Fixed	widthRemaining;
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		pos = 
			PixelToChar(
				textPtr, textSize, slop, pixelWidth, 
				&leadingEdge, &widthRemaining, styleRunPosition, numer, denom);
		EXTEND(sp,3);
		PUSHs(sv_2mortal(newSViv(pos)));
		PUSHs(sv_2mortal(newSViv(leadingEdge)));
		PUSHs(sv_2mortal(newSVnv(Fix2X(widthRemaining))));
	}

=item CharToPixel TEXT, SLOP, OFFSET, DIRECTION, STYLERUN [, NUMER, DENOM]

Translate a character position into a pixel offset.

=cut
short
CharToPixel(text, slop, offset, direction, styleRunPosition, numer=sUnityPoint, denom=sUnityPoint)
	SV *	text
	Fixed 	slop
	long 	offset
	short 	direction
	JustStyleCode 	styleRunPosition
	Point	numer;
	Point	denom;
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		RETVAL = 
			CharToPixel(
				textPtr, textSize, slop, offset, direction, 
				styleRunPosition, numer, denom);
	}
	OUTPUT:
	RETVAL

=item DrawJustified TEXT, SLOP, STYLERUN [, NUMER, DENOM]

Draw a string with the specified amount of adjustment.

=cut
void
DrawJustified(text, slop, styleRunPosition, numer=sUnityPoint, denom=sUnityPoint)
	SV *	text
	Fixed 	slop
	JustStyleCode 	styleRunPosition
	Point	numer;
	Point	denom;
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		DrawJustified(textPtr, textSize, slop, styleRunPosition, numer, denom);
	}

=item PortionLine TEXT, STYLERUN [, NUMER, DENOM]

Calculate a measure for the portion of space to be allocated to a style run.

=cut
Fixed
PortionLine(text, styleRunPosition, numer=sUnityPoint, denom=sUnityPoint)
	SV *	text
	JustStyleCode 	styleRunPosition
	Point	numer;
	Point	denom;
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		RETVAL = PortionLine(textPtr, textSize, styleRunPosition, numer, denom);
	}
	OUTPUT:
	RETVAL

=item VisibleLength TEXT

Calculate the length of the text as drawn.

=cut
long
VisibleLength(text)
	SV * text
	CODE:
	{
		void *	textPtr;
		STRLEN	textSize;
		
		textPtr = 	SvPV(text, textSize);
		RETVAL = VisibleLength(textPtr, textSize);
	}
	OUTPUT:
	RETVAL
	
=item TextFont FONTNUM

Set the font ID for text.

=cut
void
TextFont(font)
	short 	font

=item TextFace FACE

Set the text style.

=cut
void
TextFace(face)
	short 	face

=item TextMode MODE

Set the text mode.

=cut
void
TextMode(mode)
	short 	mode

=item TextSize SIZE

Set the text size.

=cut
void
TextSize(size)
	short 	size

=item SpaceExtra EXTRA

Set the extra space to be added to each space character.

=cut
void
SpaceExtra(extra)
	Fixed 	extra

=item DrawString STRING

Draw a string.

=cut
void
DrawString(s)
	Str255	s

=item StringWidth STRING

Return the width of a string.

=cut
short
StringWidth(s)
	Str255	s

=item GetFontInfo()

Get measurements for a font.

   ($ascent, $descend, $maxWidth, $leading) = GetFontInfo();

=cut
void
GetFontInfo()
	PPCODE:
	{
		FontInfo	info;
		
		GetFontInfo(&info);
		EXTEND(sp,4);
		PUSHs(sv_2mortal(newSViv(info.ascent)));
		PUSHs(sv_2mortal(newSViv(info.descent)));
		PUSHs(sv_2mortal(newSViv(info.widMax)));
		PUSHs(sv_2mortal(newSViv(info.leading)));
	}

=item CharExtra EXTRA

Specify the extra space to be added to each character.

=cut
void
CharExtra(extra)
	Fixed 	extra

