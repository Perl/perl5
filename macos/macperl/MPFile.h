/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPFile.h			-
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPFile.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:57:59  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:45  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:03:17  neeri
Initial revision

Revision 0.3  1993/08/29  00:00:00  neeri
GetDocType

Revision 0.2  1993/08/13  00:00:00  neeri
ApplySettings

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#ifndef __MPFILE__
#define __MPFILE__

#include <Memory.h>
#include <QuickDraw.h>
#include <Traps.h>
#include <Files.h>
#include <Packages.h>
#include <AppleEvents.h>
#include <Printing.h>

#include "MPGlobals.h"
#include "MPUtils.h"
#include "MPWindow.h"
#include "MPEditions.h"

pascal void DoQuit(DescType saveOpt);

pascal OSErr DoClose(WindowPtr aWindow, Boolean canInteract, DescType dialogAnswer);

pascal OSErr GetFileNameToSaveAs(DPtr theDocument);

pascal OSErr GetFileContents(FSSpec theFSSpec, DPtr theDocument);

pascal void FileError(Str255 s, Str255 f);

pascal OSErr SaveAskingName(DPtr theDocument, Boolean canInteract);

pascal OSErr SaveUsingTemp(DPtr theDocument);

pascal OSErr SaveWithoutTemp(DPtr theDocument, FSSpec spec);

pascal OSErr DoCreate(FSSpec theSpec);

pascal OSErr OpenOld(FSSpec aFSSpec, DocType type);

pascal OSErr GetFile(FSSpec *theFSSpec);

pascal void ApplySettings(DPtr doc, HPtr settings);

pascal OSErr SaveConsole(DPtr doc);

pascal void RestoreConsole(DPtr doc);

pascal OSErr Handle2File(Handle text, FSSpec toFSSpec, DocType newtype);

pascal OSErr File2File(FSSpec aFSSpec, DocType type, FSSpec toFSSpec, DocType newtype);

pascal DocType GetDocType(FSSpec * spec);

pascal DocType GetDocTypeFromInfo(CInfoPBPtr info);

#endif