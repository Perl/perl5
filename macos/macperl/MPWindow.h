/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPWindow.h		-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPWindow.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:58:11  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:11:07  neeri
Checked into CVS

Revision 1.3  1994/05/04  03:18:45  neeri
C++ freaked out at use of name "inline".

Revision 1.2  1994/05/04  02:52:40  neeri
Inline Input.

Revision 1.1  1994/02/27  23:04:48  neeri
Initial revision

Revision 0.4  1993/08/24  00:00:00  neeri
DoContent needs EventRecord *

Revision 0.3  1993/08/05  00:00:00  neeri
Show window status

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#ifndef __MPWINDOW__
#define __MPWINDOW__

#include <Memory.h>
#include <Types.h>
#include <QuickDraw.h>
#include <Controls.h>
#include <Fonts.h>
#include <ToolUtils.h>
#include <Traps.h>
#include "MPGlobals.h"
#include "MPUtils.h"
#include "MPEditions.h"
#include "MPAppleEvents.h"

pascal DPtr DPtrFromWindowPtr(WindowPtr w);

pascal void MyGrowWindow(WindowPtr w,
                         Point     p);

pascal void DoZoom(WindowPtr w, short c, Point p);

pascal void DoContent(WindowPtr theWindow, EventRecord * theEvent);

pascal void AdjustScript(DPtr doc);

pascal OSErr DoActivate(WindowPtr theWindow, Boolean   activate);

pascal void DoUpdate(DPtr theDoc, WindowPtr theWindow);

pascal DPtr NewDocument(Boolean isForOldDoc, WindowKind kind);

pascal void CloseMyWindow(WindowPtr aWindow);

pascal void ShowSelect(DPtr theDoc);

pascal void AdjustScrollbars(DPtr theDoc, Boolean needsResize);

pascal void GetWinContentRect(WindowPtr theWindow, Rect *r);

pascal void ResizeMyWindow(DPtr theDoc);

pascal void ResizePageSetupForDocument(DPtr theDoc);

pascal void InvalidateDocument(DPtr theDoc);

pascal void DrawPageExtras(DPtr theDoc);

pascal void PrintWindow(DPtr theDoc, Boolean askUser);

pascal void ShowWindowStatus();

pascal void UseInlineInput(Boolean useInline);

pascal void DoShowWindow(WindowPtr win);

pascal void DoHideWindow(WindowPtr win);

pascal WindowPtr AlreadyOpen(FSSpec * spec, StringPtr name);

pascal void VActionProc(ControlHandle control, short part);

pascal void DoThumb(DPtr theDoc, ControlHandle cntl, short oldValue);

pascal void DoFind(TEHandle te, Boolean again);

#endif