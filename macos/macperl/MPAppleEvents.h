/*********************************************************************
Project	:	MacPerl					-	Real Perl Application
File		:	MPAppleEvents.h	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPAppleEvents.h,v $
Revision 1.1  2000/11/30 08:37:28  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:57:52  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:34  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:02:47  neeri
Initial revision

Revision 0.3  1993/08/28  00:00:00  neeri
IssueFormatCommand

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#ifndef __MPAPPLEEVENTS__
#define __MPAPPLEEVENTS__

#include <Types.h>
#include <QuickDraw.h>
#include <Packages.h>
#include <Gestalt.h>
#include <Printing.h>
#include <AppleEvents.h>
#include <Processes.h>

#ifndef __MPGLOBALS__
#include <MPGlobals.h>
#endif

enum {

ETX = 0x03, /* Enter key on keyboard or keypad */
BS  = 0x08, /* Backspace key on keyboard       */
HT  = 0x09, /* Tab key on keyboard             */
CR  = 0x0D, /* Return key on keyboard          */
ESC = 0x1B, /* Clear key on keypad             */
FS  = 0x1C, /* Left arrow key on keypad        */
GS  = 0x1D, /* Right arrow key on keypad       */
RS  = 0x1E, /* Up arrow key on keypad          */
US  = 0x1F  /* Down arrow key on keypad        */
};

pascal Boolean AllSelected(TEHandle te);
pascal void InitAppleEvents(void);
pascal void DoAppleEvent(EventRecord theEvent);
pascal OSErr MakeSelfAddress(AEAddressDesc *selfAddress);
pascal OSErr MakeSelfPSN(ProcessSerialNumber *selfPSN);

/*
	Text Commands
*/
pascal void IssueCutCommand(DPtr theDocument);
pascal void IssueCopyCommand(DPtr theDocument);
pascal void IssuePasteCommand(DPtr theDocument);
pascal void IssueClearCommand(DPtr theDocument);
pascal void IssueFormatCommand(DPtr theDocument);

/*
	Window Commands
*/

pascal void IssueZoomCommand(WindowPtr whichWindow, short whichPart);
pascal void IssueCloseCommand(WindowPtr whichWindow);
pascal void IssueSizeWindow(WindowPtr whichWindow, short newHSize,short newVSize);
pascal void IssueMoveWindow(WindowPtr whichWindow, Rect sizeRect);
pascal void IssuePageSetupWindow(WindowPtr whichWindow, TPrint thePageSetup);
pascal void IssueShowBorders(WindowPtr whichWindow, Boolean showBorders);
pascal void IssuePrintWindow(WindowPtr whichWindow);

/*
	Document Commands
*/

pascal OSErr IssueJumpCommand(FSSpec * file, WindowPtr win, short line);
pascal OSErr IssueAEOpenDoc(FSSpec myFSSpec);
pascal void  IssueAENewWindow(void);
pascal OSErr IssueSaveCommand(DPtr theDocument, FSSpecPtr where);
pascal OSErr IssueRevertCommand(WindowPtr theWindow);
pascal OSErr IssueQuitCommand(void);
pascal void IssueCreatePublisher(DPtr whichDoc);

pascal void EnforceMemory(DPtr theDocument, TEHandle theHTE);

/*
	Recording of Keystrokes
*/

pascal void AddKeyToTypingBuffer(DPtr theDocument, char theKey);
pascal void FlushAndRecordTypingBuffer(void);

#endif