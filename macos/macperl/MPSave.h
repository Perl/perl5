/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPSave.h			-	Handle all the runtime variations
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPSave.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:59  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:04:18  neeri
Initial revision

*********************************************************************/

#ifndef __MPSAVE__
#define __MPSAVE__

#include "MPGlobals.h"

extern OSType * 	MacPerlFileTypes;
extern short		MacPerlFileTypeCount;

pascal OSErr DoSave(DPtr theDocument, FSSpec theFSSpec, StringPtr name);

pascal Boolean CanSaveAs(DocType type);

pascal void AddExtensionsToMenu(MenuHandle menu);

pascal short Type2Menu(DocType type);

pascal DocType Menu2Type(short item);

pascal void BuildSEList();

#endif
