/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Files/Files.xs,v 1.3 2000/09/12 20:18:57 pudge Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Files.xs,v $
 * Revision 1.3  2000/09/12 20:18:57  pudge
 * Added all the new constants for FindFolder
 * Make FSMakeFSSpec return FSSpec even if file does not exist
 *
 * Revision 1.2  2000/09/09 22:18:26  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:30  neeri
 * Checked into Sourceforge
 *
 * Revision 1.5  1998/04/07 01:02:53  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.4  1997/11/18 00:52:22  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.3  1997/09/02 23:06:38  neeri
 * Added Structs, other minor fixes
 *
 * Revision 1.2  1997/06/04 22:55:46  neeri
 * Compiles fine.
 *
 * Revision 1.1  1997/04/07 20:49:37  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Folders.h>
#include <Files.h>
#include <GUSIFileSpec.h>
#include <Script.h>
#include <Errors.h>
#include <Aliases.h>

typedef FSSpec			RealFSSpec;
typedef CInfoPBPtr 	CatInfo;

static CatInfo NewCatInfo()
{
	CatInfo	ci;
	ci = (CatInfo) malloc(sizeof(CInfoPBRec)+sizeof(Str63));
	ci->hFileInfo.ioNamePtr = (StringPtr) ((char *)ci+sizeof(CInfoPBRec));
	
	return ci;
}

MODULE = Mac::Files	PACKAGE = Mac::Files

=head2 Types

=over 4

=item FInfo

Information for a file, including:

	OSType			fdType			the type of the file
	OSType			fdCreator		file's creator
	U16				fdFlags			flags ex. hasbundle,invisible,locked, etc.
	Point			fdLocation		file's location in folder

=cut
STRUCT FInfo
	OSType			fdType;						/*the type of the file*/
	OSType			fdCreator;					/*file's creator*/
	U16				fdFlags;					/*flags ex. hasbundle,invisible,locked, etc.*/
	Point			fdLocation;					/*file's location in folder*/

=item FXInfo

Further information for a file, including:

	short			fdIconID		Icon ID
	I8				fdScript		Script flag and number
	I8				fdXFlags		More flag bits
	short			fdComment		Comment ID
	long			fdPutAway		Home Dir ID

=cut
STRUCT FXInfo
	short			fdIconID;					/*Icon ID*/
	I8				fdScript;					/*Script flag and number*/
	I8				fdXFlags;					/*More flag bits*/
	short			fdComment;					/*Comment ID*/
	long			fdPutAway;					/*Home Dir ID*/

=item DInfo

Information for a directory, including:

	Rect			frRect			folder rect
	U16				frFlags			Flags
	Point			frLocation		folder location
	short			frView			folder view

=cut
STRUCT DInfo
	Rect			frRect;						/*folder rect*/
	U16				frFlags;					/*Flags*/
	Point			frLocation;					/*folder location*/
	short			frView;						/*folder view*/

=item DXInfo

Further information for a directory, including:

	Point			frScroll		scroll position
	long			frOpenChain		DirID chain of open folders
	I8				frScript		Script flag and number
	I8				frXFlags;		More flag bits
	short			frComment		comment
	long			frPutAway;		DirID

=cut
STRUCT DXInfo
	Point			frScroll;					/*scroll position*/
	long			frOpenChain;				/*DirID chain of open folders*/
	I8				frScript;					/*Script flag and number*/
	I8				frXFlags;					/*More flag bits*/
	short			frComment;					/*comment*/
	long			frPutAway;					/*DirID*/

=back

=cut

MODULE = Mac::Files	PACKAGE = CatInfo

STRUCT * CatInfo
	HFileInfo *		STRUCT;
		INPUT:
		XS_INPUT(CatInfo, *(CatInfo *)&STRUCT, $arg);
		OUTPUT:
		XS_PUSH(CatInfo, STRUCT);
	Str255			ioNamePtr;
	short			ioVRefNum;
	short			ioFRefNum;
	I8				ioFVersNum;
	short			ioFDirIndex;
	I8				ioFlAttrib;
	I8				ioACUser;
	FInfo			ioFlFndrInfo;
	long			ioDirID;
	U16				ioFlStBlk;
	long			ioFlLgLen;
	long			ioFlPyLen;
	U16				ioFlRStBlk;
	long			ioFlRLgLen;
	long			ioFlRPyLen;
	time_t			ioFlCrDat;
	time_t			ioFlMdDat;
	time_t			ioFlBkDat;
	FXInfo			ioFlXFndrInfo;
	long			ioFlParID;
	long			ioFlClpSiz;
	DInfo			ioDrUsrWds;
		INPUT:
		XS_INPUT(DInfo, ((DirInfo *)STRUCT)->ioDrUsrWds, $arg);
		OUTPUT:
		XS_OUTPUT(DInfo, ((DirInfo *)STRUCT)->ioDrUsrWds, $arg);
	long			ioDrDirID;
		INPUT:
		XS_INPUT(long, ((DirInfo *)STRUCT)->ioDrDirID, $arg);
		OUTPUT:
		XS_OUTPUT(long, ((DirInfo *)STRUCT)->ioDrDirID, $arg);
	U16				ioDrNmFls;
		INPUT:
		XS_INPUT(U16, ((DirInfo *)STRUCT)->ioDrNmFls, $arg);
		OUTPUT:
		XS_OUTPUT(U16, ((DirInfo *)STRUCT)->ioDrNmFls, $arg);
	time_t			ioDrCrDat;
		INPUT:
		XS_INPUT(time_t, ((DirInfo *)STRUCT)->ioDrCrDat, $arg);
		OUTPUT:
		XS_OUTPUT(time_t, ((DirInfo *)STRUCT)->ioDrCrDat, $arg);
	time_t			ioDrMdDat;
		INPUT:
		XS_INPUT(time_t, ((DirInfo *)STRUCT)->ioDrMdDat, $arg);
		OUTPUT:
		XS_OUTPUT(time_t, ((DirInfo *)STRUCT)->ioDrMdDat, $arg);
	time_t			ioDrBkDat;
		INPUT:
		XS_INPUT(time_t, ((DirInfo *)STRUCT)->ioDrBkDat, $arg);
		OUTPUT:
		XS_OUTPUT(time_t, ((DirInfo *)STRUCT)->ioDrBkDat, $arg);
	DXInfo			ioDrFndrInfo;
		INPUT:
		XS_INPUT(DXInfo, ((DirInfo *)STRUCT)->ioDrFndrInfo, $arg);
		OUTPUT:
		XS_OUTPUT(DXInfo, ((DirInfo *)STRUCT)->ioDrFndrInfo, $arg);
	long			ioDrParID;
		INPUT:
		XS_INPUT(long, ((DirInfo *)STRUCT)->ioDrParID, $arg);
		OUTPUT:
		XS_OUTPUT(long, ((DirInfo *)STRUCT)->ioDrParID, $arg);

void
DESTROY(cat)
	CatInfo	cat
	CODE:
	free(cat);


MODULE = Mac::Files	PACKAGE = Mac::Files

=head2 Functions

=over 4

=item FSpGetCatInfo FILE [, INDEX ]

If INDEX is omitted or 0, returns information about the specified 
file or folder. If INDEX is nonzero, returns information obout the 
nth item in the specified folder.

=cut
CatInfo
FSpGetCatInfo(file, index=0)
	FSSpec	file
	short		index
	CODE:
	if ((index && GUSIFSpUp(&file)) || !(RETVAL = NewCatInfo())) {
		XSRETURN_UNDEF;
	}
	RETVAL->hFileInfo.ioVRefNum 	= file.vRefNum;
	RETVAL->hFileInfo.ioDirID 	= file.parID;
	RETVAL->hFileInfo.ioFDirIndex = index;
	if (!index)
		memcpy(RETVAL->hFileInfo.ioNamePtr, file.name, *file.name+1);
	if (gMacPerl_OSErr = PBGetCatInfoSync(RETVAL)) {
		free(RETVAL);
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item FSpSetCatInfo FILE, INFO

Change information about the specified file.

=cut
MacOSRet
FSpSetCatInfo(file, info)
	FSSpec	file
	CatInfo	info;
	CODE:
	info->hFileInfo.ioVRefNum 	= file.vRefNum;
	info->hFileInfo.ioDirID 	= file.parID;
	memcpy(info->hFileInfo.ioNamePtr, file.name, *file.name+1);
	RETVAL = PBSetCatInfoSync(info);
	OUTPUT:
	RETVAL

=item FSMakeFSSpec VREF, DIRID, NAME

Creates a file system specification record from a volume number, 
directory ID, and name. This call never returns a path name.

=cut
RealFSSpec
FSMakeFSSpec(vRefNum, dirID, fileName)
	short		vRefNum
	long		dirID
	Str255	fileName
	CODE:
	gMacPerl_OSErr = FSMakeFSSpec(vRefNum, dirID, fileName, &RETVAL);
	if ((gMacPerl_OSErr != noErr) && (gMacPerl_OSErr != fnfErr)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item FSpCreate FILE, CREATOR, TYPE [, SCRIPTTAG]

Creates a file with the specified file creator and type. You don't
want to know what a script tag is.

=cut
MacOSRet
FSpCreate(spec, creator, type, scriptTag=smSystemScript)
	FSSpec	&spec
	OSType	creator
	OSType 	type
	char		scriptTag
	
=item FSpDirCreate FILE [, SCRIPTTAG]

Creates a directory and returns its ID.

=cut
long
FSpDirCreate(spec, scriptTag=smSystemScript)
	FSSpec	&spec
	char		scriptTag
	CODE:
	if (gMacPerl_OSErr = FSpDirCreate(&spec, scriptTag, &RETVAL))
		RETVAL = 0;
	OUTPUT:
	RETVAL

=item FSpDelete FILE

End the sad existence of a file or (empty) folder.

=cut
MacOSRet
FSpDelete(spec)
	FSSpec	&spec

=item FSpGetFInfo FILE

Returns finder info about a specified file.

=cut
FInfo
FSpGetFInfo(spec)
	FSSpec	&spec
	CODE:
	if (gMacPerl_OSErr = FSpGetFInfo(&spec, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item FSpSetFInfo FILE, INFO

Changes the finder info about a specified file.

=cut
MacOSRet
FSpSetFInfo(spec, info)
	FSSpec	&spec
	FInfo	&info;

=item FSpSetFLock FILE

Software lock a file.

=cut
MacOSRet
FSpSetFLock(spec)
	FSSpec	&spec

=item FSpRstFLock FILE

Unlock a file.

=cut
MacOSRet
FSpRstFLock(spec)
	FSSpec	&spec

=item FSpRename FILE, NAME

Rename a file (only the name component).

=cut
MacOSRet
FSpRename(spec, newName)
	FSSpec	&spec
	Str255	newName

=item FSpCatMove FILE, FOLDER

Move a file into a different folder.

=cut
MacOSRet
FSpCatMove(source, dest)
	FSSpec	&source
	FSSpec	&dest

=item FSpExchangeFiles FILE1, FILE2

Swap the contents of two files, e.g. if you saved to a temp file
and finally swap it with the original.

=cut
MacOSRet
FSpExchangeFiles(source, dest)
	FSSpec	&source
	FSSpec	&dest

=item NewAlias FILE

Returns an AliasHandle for the file.

=cut
Handle
NewAlias(target)
	FSSpec	&target
	CODE:
	gMacPerl_OSErr = NewAlias(nil, &target, (AliasHandle *)&RETVAL);
	OUTPUT:
	RETVAL

=item NewAliasRelative FROM, FILE

Returns a AliasHandle relative to FROM for the file.

=cut
Handle
NewAliasRelative(from, target)
	FSSpec	&from
	FSSpec	&target
	CODE:
	gMacPerl_OSErr = NewAlias(&from, &target, (AliasHandle *)&RETVAL);
	OUTPUT:
	RETVAL

=item NewAliasMinimal FILE

Returns an AliasHandle containing minimal information for the file.
This type of alias is best suited for short lived aliases, e.g. in
AppleEvents.

=cut
Handle
NewAliasMinimal(target)
	FSSpec	&target
	CODE:
	gMacPerl_OSErr = NewAliasMinimal(&target, (AliasHandle *)&RETVAL);
	OUTPUT:
	RETVAL

=item NewAliasMinimalFromFullPath NAME [, ZONE [, SERVER]]

Create a new alias containing only the path name.

=cut
Handle
NewAliasMinimalFromFullPath(name, zone=NO_INIT, server=NO_INIT)
	char *	name
	Str255	zone
	Str255	server
	CODE:
	if (items < 3)
		server[0] = 0;
	if (items < 2)
		zone[0] = 0;
	gMacPerl_OSErr = 
		NewAliasMinimalFromFullPath(strlen(name), name, zone, server, (AliasHandle *)&RETVAL);
	OUTPUT:
	RETVAL

=item UpdateAlias TARGET, ALIAS

Updates an alias to point to the target file. Returns whether the alias was changed..

=cut
Boolean
UpdateAlias(target, alias)
	FSSpec	target
	Handle	alias
	CODE:
	if (gMacPerl_OSErr = UpdateAlias(nil, &target, (AliasHandle) alias, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item UpdateAliasRelative FROM, TARGET, ALIAS

Updates an alias to point to the target file relative to FROM. Returns whether 
the alias was changed..

=cut
Boolean
UpdateAliasRelative(from, target, alias)
	FSSpec  &from
	FSSpec	&target
	Handle	alias
	CODE:
	if (gMacPerl_OSErr = UpdateAlias(&from, &target, (AliasHandle) alias, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ResolveAlias ALIAS

Resolves an alias. In scalar context, returns the path to the resolved file.
In list context, also returns whether the alias was changed when resolving.

=cut
void
ResolveAlias(alias)
	Handle	alias
	PPCODE:
	{
		FSSpec	target;
		Boolean	changed;
		
		gMacPerl_OSErr = ResolveAlias(nil, (AliasHandle) alias, &target, &changed);
		
		if (gMacPerl_OSErr)  {
			XSRETURN_EMPTY;
		} 
		XS_XPUSH(FSSpec, target);
		if (GIMME == G_ARRAY) {
			XS_XPUSH(Boolean, changed);
		}
	}

=item ResolveAliasRelative FROM, ALIAS

Resolves an alias relative to a file. In scalar context, returns the path to the 
resolved file. In list context, also returns whether the alias was changed when 
resolving.

=cut
void
ResolveAliasRelative(from, alias)
	FSSpec	&from
	Handle	alias
	PPCODE:
	{
		FSSpec	target;
		Boolean	changed;
		
		gMacPerl_OSErr = ResolveAlias(&from, (AliasHandle) alias, &target, &changed);
		
		if (gMacPerl_OSErr)  {
			XSRETURN_EMPTY;
		} 
		XS_XPUSH(FSSpec, target);
		if (GIMME == G_ARRAY) {
			XS_XPUSH(Boolean, changed);
		}
	}

=item GetAliasInfo ALIAS, INDEX

Return a component of the alias information.

=cut
Str255
GetAliasInfo(alias, index)
	Handle	alias
	short 	index
	CODE:
	if (gMacPerl_OSErr = GetAliasInfo((AliasHandle) alias, index, RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item UnmountVol (VOLUMENAME | VOLUMENR)

Unmounts a volume.

=cut
MacOSRet
_UnmountVol(volName, vRefNum)
	Str255	volName
	short	vRefNum
	CODE:
	RETVAL = UnmountVol(volName, vRefNum);
	OUTPUT:
	RETVAL

=item Eject (VOLUMENAME | VOLUMENR)

Ejects a volume, placing it offline.

=cut
MacOSRet
_Eject(volName, vRefNum)
	Str255	volName
	short	vRefNum
	CODE:
	RETVAL = Eject(volName, vRefNum);
	OUTPUT:
	RETVAL

=item FlushVol (VOLUMENAME | VOLUMENR)

Flush pending write operations on a volume.

=cut
MacOSRet
_FlushVol(volName, vRefNum)
	Str255	volName
	short	vRefNum
	CODE:
	RETVAL = FlushVol(volName, vRefNum);
	OUTPUT:
	RETVAL

=item FindFolder VREF, FOLDERTYPE [, CREATE]

Returns a path to a special folder on the given volume (specify 
C<kOnSystemDisk> for the boot volume). For FOLDERTYPE, you can specify
any of the C<kXXXFolderType> constants listed above.

=cut
FSSpec
FindFolder(vRefNum, folderType, createFolder=0)
	short 	vRefNum
	OSType 	folderType
	Boolean 	createFolder
	CODE:
	if (gMacPerl_OSErr = FindFolder(vRefNum, folderType, createFolder, &RETVAL.vRefNum, &RETVAL.parID)) {
		XSRETURN_UNDEF;
	}
	GUSIFSpUp(&RETVAL);
	OUTPUT:
	RETVAL
 
=back
 
=cut
