/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPUtils.h	-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPUtils.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.3  1998/04/07 01:46:47  neeri
MacPerl 5.2.0r4b1

Revision 1.2  1997/08/08 16:58:09  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:11:05  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:04:38  neeri
Initial revision

Revision 0.4  1993/09/28  00:00:00  neeri
PlotResMiniIcon

Revision 0.3  1993/08/17  00:00:00  neeri
DoPrefsDialog

Revision 0.2  1993/08/14  00:00:00  neeri
OpenPreferences

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#ifndef __MPUTILS__
#define __MPUTILS__

#include <Types.h>
#include <QuickDraw.h>
#include <Packages.h>
#include <Gestalt.h>
#include <Printing.h>

#ifndef __MPGLOBALS__
#include "MPGlobals.h"
#endif

pascal Boolean CheckEnvironment();

pascal void ShowError(Str255 theError,
                      long   theErrorCode);

pascal Boolean FeatureIsImplemented(OSType theFeature,
                                    short  theTestBit);

pascal void GetTempFSSpec(DPtr aDoc, FSSpec * temp);

pascal Boolean Ours(WindowPtr aWindow);

pascal void SetShortMenus();

pascal void SetLongMenus();

pascal void SetEditMenu(DPtr theDoc);

pascal void AdornDefaultButton(DialogPtr theDialog, short theItem);

#if TARGET_RT_MAC_CFM
extern RoutineDescriptor uDrawDefaultOutline;
extern RoutineDescriptor uSeparator;
#else
pascal void DrawDefaultOutline(DialogPtr theDialog, short theItem);
pascal void Separator(DialogPtr dlg, short item);

#define uDrawDefaultOutline *(UserItemUPP)&DrawDefaultOutline
#define uSeparator *(UserItemUPP)&Separator
#endif

pascal void RetrieveText(DialogPtr aDialog,
											   short     anItem,
											   Str255    aString);

pascal void SetText( DialogPtr aDialog,
										 short     itemNo,
										 Str255    theString);

pascal void GetRectOfDialogItem(DialogPtr theDialog, short theItem, Rect *theRect);

#define LesserOf(A,B)	((A<B) ? A : B)
#define GreaterOf(A,B)	((A>B) ? A : B)

pascal Boolean DoPageSetup(DPtr theDoc);

pascal Boolean CtrlKeyPressed(const EventRecord *theEvent);

pascal Boolean OptionKeyPressed(const EventRecord *theEvent);

pascal void DoAbout(Boolean easter);

pascal void RegisterDocument(DPtr doc);

pascal void UnregisterDocument(DPtr doc);

pascal void SetupWindowMenu();

pascal void DoSelectWindow(short item);

pascal Boolean WeirdChar(const EventRecord * ev, short modifiers, char ch);

pascal Boolean SameFSSpec(FSSpec * one, FSSpec * other);

pascal DialogPtr GetNewAppDialog(short ID);

pascal DialogPtr GetNewAppWindow(short ID);

pascal short AppAlert(short ID);

pascal Handle GetAppResource(OSType resType, short ID);

#endif
