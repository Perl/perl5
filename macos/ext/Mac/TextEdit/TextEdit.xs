/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 * MacPerl 5.1.5
 * 
 * Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <TextEdit.h>

MODULE = Mac::TextEdit	PACKAGE = Mac::TextEdit

=head2 Types

=over 4

=item TEHandle

A TextEdit record. Fields are:

	Rect 		destRect;
	Rect 		viewRect;
	Rect 		selRect;		READ_ONLY
	short 		lineHeight;
	short 		fontAscent;
	Point 		selPoint;		READ_ONLY
	short 		selStart;
	short 		selEnd;
	short 		active;			READ_ONLY
	long 		clickTime;		READ_ONLY
	short 		clickLoc;		READ_ONLY
	long 		caretTime;		READ_ONLY
	short 		caretState;		READ_ONLY
	short 		just;
	short 		teLength;		READ_ONLY
	Handle 		hText;			READ_ONLY
	short 		clikStuff;
	short 		crOnly;
	short 		txFont;
	short	 	txFace;						/*txFace is unpacked byte*/
	short 		txMode;
	short 		txSize;
	GrafPtr 	inPort;			READ_ONLY
	short 		nLines;			READ_ONLY

=cut

STRUCT ** TEHandle
	Rect 		destRect;
	Rect 		viewRect;
	Rect 		selRect;
		READ_ONLY
	short 		lineHeight;
	short 		fontAscent;
	Point 		selPoint;
		READ_ONLY
	short 		selStart;
	short 		selEnd;
	short 		active;
		READ_ONLY
	long 		clickTime;
		READ_ONLY
	short 		clickLoc;
		READ_ONLY
	long 		caretTime;
		READ_ONLY
	short 		caretState;
		READ_ONLY
	short 		just;
	short 		teLength;
		READ_ONLY
	Handle 		hText;
		READ_ONLY
	short 		clikStuff;
	short 		crOnly;
	short 		txFont;
	short	 	txFace;						/*txFace is unpacked byte*/
	short 		txMode;
	short 		txSize;
	GrafPtr 	inPort;
		READ_ONLY
	short 		nLines;
		READ_ONLY

=item TextStyle

A record describing a run of text. Fields are.

	short 			tsFont;						/*font (family) number*/
	StyleField 		tsFace;						/*character Style*/
	short 			tsSize;						/*size in point*/
	RGBColor 		tsColor;					/*absolute (RGB) color*/

=cut

STRUCT TextStyle
	short 			tsFont;						/*font (family) number*/
	short	 		tsFace;						/*character Style*/
	short 			tsSize;						/*size in point*/
	RGBColor 		tsColor;					/*absolute (RGB) color*/

=head2 Functions

=over 4

=item TEScrapHandle 

=cut
Handle
TEScrapHandle()


=item TEGetScrapLength 

=cut
long
TEGetScrapLength()


=item TENew DESTRECT, VIEWRECT 

=cut
TEHandle
TENew(destRect, viewRect)
	Rect &destRect
	Rect &viewRect


=item TEDispose HTE 

=cut
void
TEDispose(hTE)
	TEHandle	hTE


=item TESetText TEXT, HTE 

=cut
void
TESetText(text, hTE)
	SV *		text
	TEHandle	hTE
	CODE:
	{
		STRLEN	length;
		char *	t = SvPV(text, length);
		TESetText(t, length, hTE);
	}


=item TEGetText HTE 

=cut
Handle
TEGetText(hTE)
	TEHandle	hTE


=item TEIdle HTE 

=cut
void
TEIdle(hTE)
	TEHandle	hTE


=item TESetSelect SELSTART, SELEND, HTE 

=cut
void
TESetSelect(selStart, selEnd, hTE)
	long	selStart
	long	selEnd
	TEHandle	hTE


=item TEActivate HTE 

=cut
void
TEActivate(hTE)
	TEHandle	hTE


=item TEDeactivate HTE 

=cut
void
TEDeactivate(hTE)
	TEHandle	hTE


=item TEKey KEY, HTE 

=cut
void
TEKey(key, hTE)
	char		key
	TEHandle	hTE


=item TECut HTE 

=cut
void
TECut(hTE)
	TEHandle	hTE


=item TECopy HTE 

=cut
void
TECopy(hTE)
	TEHandle	hTE


=item TEPaste HTE 

=cut
void
TEPaste(hTE)
	TEHandle	hTE


=item TEDelete HTE 

=cut
void
TEDelete(hTE)
	TEHandle	hTE


=item TEInsert TEXT, HTE 

=cut
void
TEInsert(text, hTE)
	SV *		text
	TEHandle	hTE
	CODE:
	{
		STRLEN	length;
		char *	t = SvPV(text, length);
		TEInsert(t, length, hTE);
	}


=item TESetAlignment JUST, HTE 

=cut
void
TESetAlignment(just, hTE)
	short		just
	TEHandle	hTE


=item TEUpdate RUPDATE, HTE 

=cut
void
TEUpdate(rUpdate, hTE)
	Rect       &rUpdate
	TEHandle	hTE


=item TETextBox TEXT, BOX, JUST 

=cut
void
TETextBox(text, box, just)
	SV *	text
	Rect   &box
	short	just
	CODE:
	{
		STRLEN	length;
		char *	t = SvPV(text, length);
		TETextBox(t, length, &box, just);
	}


=item TEScroll DH, DV, HTE 

=cut
void
TEScroll(dh, dv, hTE)
	short	dh
	short	dv
	TEHandle	hTE


=item TESelView HTE 

=cut
void
TESelView(hTE)
	TEHandle	hTE


=item TEPinScroll DH, DV, HTE 

=cut
void
TEPinScroll(dh, dv, hTE)
	short	dh
	short	dv
	TEHandle	hTE


=item TEAutoView FAUTO, HTE 

=cut
void
TEAutoView(fAuto, hTE)
	Boolean	fAuto
	TEHandle	hTE


=item TECalText HTE 

=cut
void
TECalText(hTE)
	TEHandle	hTE


=item TEGetOffset PT, HTE 

=cut
short
TEGetOffset(pt, hTE)
	Point	pt
	TEHandle	hTE


=item TEGetPoint OFFSET, HTE 

=cut
Point
TEGetPoint(offset, hTE)
	short	offset
	TEHandle	hTE


=item TEClick PT, FEXTEND, H 

=cut
void
TEClick(pt, fExtend, h)
	Point	pt
	Boolean	fExtend
	TEHandle	h


=item TEStyleNew DESTRECT, VIEWRECT 

=cut
TEHandle
TEStyleNew(destRect, viewRect)
	Rect &destRect
	Rect &viewRect


=item TESetStyleHandle THEHANDLE, HTE 

=cut
void
TESetStyleHandle(theHandle, hTE)
	TEStyleHandle	theHandle
	TEHandle	hTE


=item TEGetStyleHandle HTE 

=cut
TEStyleHandle
TEGetStyleHandle(hTE)
	TEHandle	hTE


=item (STYLE, HEIGHT, ASCENT) = TEGetStyle OFFSET, HTE 

=cut
void
TEGetStyle(offset, hTE)
	short		offset
	TEHandle	hTE
	PPCODE:
	{
		TextStyle 	theStyle;
		short		lineHeight;
		short		fontAscent;
		
		TEGetStyle(offset, &theStyle, &lineHeight, &fontAscent, hTE);
		
		XS_XPUSH(TextStyle, theStyle);
		if (GIMME == G_ARRAY) {
			XS_XPUSH(short, lineHeight);
			XS_XPUSH(short, fontAscent);
		}
	}


=item TEStylePaste HTE 

=cut
void
TEStylePaste(hTE)
	TEHandle	hTE


=item TESetStyle MODE, NEWSTYLE, FREDRAW, HTE 

=cut
void
TESetStyle(mode, newStyle, fRedraw, hTE)
	short		mode
	TextStyle  &newStyle
	Boolean		fRedraw
	TEHandle	hTE


=item TEReplaceStyle MODE, OLDSTYLE, NEWSTYLE, FREDRAW, HTE 

=cut
void
TEReplaceStyle(mode, oldStyle, newStyle, fRedraw, hTE)
	short	   mode
	TextStyle &oldStyle
	TextStyle &newStyle
	Boolean	   fRedraw
	TEHandle   hTE


=item TEGetStyleScrapHandle HTE 

=cut
StScrpHandle
TEGetStyleScrapHandle(hTE)
	TEHandle	hTE


=item TEStyleInsert TEXT, HST, HTE 

=cut
void
TEStyleInsert(text, hST, hTE)
	SV *			text
	StScrpHandle	hST
	TEHandle		hTE
	CODE:
	{
		STRLEN	length;
		char *	t = SvPV(text, length);
		TEStyleInsert(t, length, hST, hTE);
	}


=item TEGetHeight ENDLINE, STARTLINE, HTE 

=cut
long
TEGetHeight(endLine, startLine, hTE)
	long	endLine
	long	startLine
	TEHandle	hTE


=item (MODE, STYLE) = TEContinuousStyle MODE, HTE 

=cut
void
TEContinuousStyle(mode, hTE)
	short 		mode
	TEHandle	hTE
	PPCODE:
	{
		TextStyle	aStyle;
		
		TEContinuousStyle(&mode, &aStyle, hTE);
		XS_PUSH(short, mode);
		if (GIMME == G_ARRAY) {
			XS_XPUSH(TextStyle, aStyle);
		}
	}
		


=item TEUseStyleScrap RANGESTART, RANGEEND, NEWSTYLES, FREDRAW, HTE 

=cut
void
TEUseStyleScrap(rangeStart, rangeEnd, newStyles, fRedraw, hTE)
	long	rangeStart
	long	rangeEnd
	StScrpHandle	newStyles
	Boolean	fRedraw
	TEHandle	hTE


=item TENumStyles RANGESTART, RANGEEND, HTE 

=cut
long
TENumStyles(rangeStart, rangeEnd, hTE)
	long	rangeStart
	long	rangeEnd
	TEHandle	hTE


=item TEFeatureFlag FEATURE, ACTION, HTE 

=cut
short
TEFeatureFlag(feature, action, hTE)
	short	feature
	short	action
	TEHandle	hTE


=item TESetScrapLength LENGTH 

=cut
void
TESetScrapLength(length)
	long	length


=item TEFromScrap 

=cut
MacOSRet
TEFromScrap()


=item TEToScrap 

=cut
MacOSRet
TEToScrap()

=begin ignore

void
TECustomHook(which, addr, hTE)
	TEIntHook	which
	UniversalProcPtr *	addr
	TEHandle	hTE

void
TESetClickLoop(clikProc, hTE)
	TEClickLoopUPP	clikProc
	TEHandle	hTE

void
TESetWordBreak(wBrkProc, hTE)
	WordBreakUPP	wBrkProc
	TEHandle	hTE

=end ignore

=back

=cut
