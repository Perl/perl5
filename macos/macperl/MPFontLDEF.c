/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPPreferences.c	-	Handle Preference Settings
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPFontLDEF.c,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:46  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:52:40  neeri
Inline Input.

Revision 1.1  1994/02/27  23:01:32  neeri
Initial revision

Revision 0.1  1993/12/08  00:00:00  neeri
Separated from MPUtils

*********************************************************************/

#include <QuickDraw.h>
#include <Gestalt.h>
#include <Script.h>
#include <Fonts.h>
#include <Resources.h>
#include <Lists.h>
#include <LowMem.h>

pascal void main(
	short 		message, 
	Boolean 		selected, 
	Rect * 		cellRect,
	Point			cell,
	short			dataOffset,
	short			dataLen,
	ListHandle	list)
{
#if !defined(powerc) && !defined(__powerc)
#pragma unused(dataOffset)
#endif
	short		oldFont;
	short		oldSize;
	short		fontNum;
	short		scriptNum;
	long		result;
	long		sysFont;
	FontInfo	fontInfo;
	Str255	contents;
	
	switch (message) {
	case lInitMsg:
		if (Gestalt(gestaltQuickdrawVersion, &result) || !result) /* B & W QD */
			(*list)->refCon = 0;
		else
			(*list)->refCon = 1;
	case lDrawMsg:
		SetPort((*list)->port);
		oldFont 		= (*list)->port->txFont;
		oldSize 		= (*list)->port->txSize;
		LGetCell(contents, &dataLen, cell, list);
		GetFNum(contents, &fontNum);
		scriptNum = FontToScript(fontNum);
			
		if (scriptNum == smUninterp)
			scriptNum = smRoman;
		sysFont = GetScriptVariable(scriptNum, smScriptSysFondSize);
		TextFont(sysFont >> 16);
		TextSize(sysFont & 0xFFFF);
		GetFontInfo(&fontInfo);
		MoveTo(cellRect->left+5, cellRect->top + fontInfo.ascent);
		DrawString(contents);
		
		TextFont(oldFont);
		TextSize(oldSize);
		
		if (!selected)
			break;
		
		/* Else fall through to select */
	case lHiliteMsg:
		if ((*list)->refCon)
			LMSetHiliteMode(LMGetHiliteMode() & 0x7F);
		InvertRect(cellRect);
		break;
	default:
		break;
	}
}
