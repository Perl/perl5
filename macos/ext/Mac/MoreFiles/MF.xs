/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/MoreFiles/MF.xs,v 1.3 2001/01/16 21:18:53 pudge Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MF.xs,v $
 * Revision 1.3  2001/01/16 21:18:53  pudge
 * Update for FSpDirectoryCopy in MoreFiles 1.5.  Probably should actually
 * add that parameter as an option in the perl glue.
 *
 * Revision 1.2  2000/09/09 22:18:27  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:31  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:52:46  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:50:06  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Files.h>
#include <GUSIFileSpec.h>
#include "MoreFiles.h"
#include "FileCopy.h"
#include "IterateDirectory.h"
#include "DirectoryCopy.h"
#include "MoreDesktopMgr.h"

static SV * newMortalFSSpec(short vRefNum, long dirID, ConstStr255Param name)
{
	FSSpec	spec;
	
	spec.vRefNum 	= vRefNum;
	spec.parID		= dirID;
	memcpy(spec.name, name, *name+1);
	
	return sv_2mortal(newSVpv(GUSIFSp2FullPath(&spec), 0));
}

static SV * gMFProc;

static pascal Boolean MFErrHdlr(	
		OSErr error,
		short failedOperation,
		short srcVRefNum,
		long srcDirID,
		ConstStr255Param srcName,
		short dstVRefNum,
		long dstDirID,
		ConstStr255Param dstName)
{
	if (gMFProc) {
		Boolean 	res;
		dSP;
		ENTER;
		SAVETMPS;
		
		PUSHMARK(sp);
		XPUSHs(sv_2mortal(newSViv(error)));
		XPUSHs(sv_2mortal(newSViv(failedOperation)));
		XPUSHs(newMortalFSSpec(srcVRefNum, srcDirID, srcName));
		XPUSHs(newMortalFSSpec(dstVRefNum, dstDirID, dstName));
		PUTBACK;
		
		perl_call_sv(gMFProc, G_SCALAR);
		
		SPAGAIN;
		
		res = (Boolean) POPi;
		
		PUTBACK;
		FREETMPS;
		LEAVE;
		
		return res;
	} else
		return true;
}

static pascal void MFIterateFilter(const CInfoPBRec * const cpbPtr,
											  Boolean *quitFlag,
											  SV *yourDataPtr)
{
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XPUSHs(newMortalFSSpec(
				cpbPtr->hFileInfo.ioVRefNum, 
				cpbPtr->hFileInfo.ioFlParID, 
				cpbPtr->hFileInfo.ioNamePtr));
	XPUSHs(yourDataPtr); 
	PUTBACK;
	
	perl_call_sv(gMFProc, G_SCALAR);
	
	SPAGAIN;
	
	*quitFlag = (Boolean) POPi;
	
	PUTBACK;
	FREETMPS;
	LEAVE;
}

MODULE = Mac::MoreFiles	PACKAGE = Mac::MoreFiles

=head2 Functions

=over 4

=item FSpCreateMinimum SPEC

Create a new file with no creator or file type.
	The FSpCreateMinimum function creates a new file without attempting to set 
	the the creator and file type of the new file.  This function is needed to
	create a file in an AppleShare "dropbox" where the user can make
	changes, but cannot see folder or files. The FSSpec in SPEC is used to create
	the file.

=cut
MacOSRet
FSpCreateMinimum(spec)
	FSSpec	&spec

=item FSpShare SPEC

Establish a local volume or directory as a share point.
	The FSpShare function establishes a local volume or directory as a
	share point. SPEC is an FSSpec record specifying the share point.

=cut
MacOSRet
FSpShare(spec)
	FSSpec	&spec

=item FSpUnshare SPEC

The FSpUnshare function removes a share point in SPEC.

=cut
MacOSRet
FSpUnshare(spec)
	FSSpec	&spec

=item FSpFileCopy SRCSPEC, DSTSPEC, COPYNAME, PREFLIGHT

The FSpFileCopy function duplicates a file and optionally renames it.
	Since the PBHCopyFile() routine is only available on some
	AFP server volumes under specific conditions, this routine
	either uses PBHCopyFile(), or does all of the work PBHCopyFile()
	does.  The SRCSPEC is used to
	determine the location of the file to copy.  The DSTSPEC is
	used to determine the location of the
	destination directory.  If COPYNAME <> NIL, then it points
	to the name of the new file.  

=cut
MacOSRet
FSpFileCopy(srcSpec, dstSpec, copyName, preflight)
	FSSpec &srcSpec
	FSSpec &dstSpec
	Str255 copyName
	Boolean preflight
	CODE:
	RETVAL = FSpFileCopy(&srcSpec, &dstSpec, copyName, nil, 0, preflight);
	OUTPUT:
	RETVAL

=item FSpDirectoryCopy SRCSPEC, DSTSPEC, PREFLIGHT, [COPYERRHANDLER]

Make a copy of a directory structure in a new location.
The FSpDirectoryCopy function makes a copy of a directory structure in a
new location. COPYERRHANDLER is the Perl routine name to handle an
error, should one arise. It will be called as:

	$bailout = &$COPYERRHANDLER(ERRORCODE,OPERATION,SRCSPEC,DSTSPEC);

=cut
MacOSRet
FSpDirectoryCopy(srcSpec, dstSpec, preflight, copyErrHandler = NULL)
	FSSpec	&srcSpec
	FSSpec	&dstSpec
	Boolean	preflight
	SV *		copyErrHandler
	CODE:
	gMFProc = copyErrHandler;
	RETVAL = FSpDirectoryCopy(&srcSpec, &dstSpec, nil, nil, 0, preflight, MFErrHdlr);
	OUTPUT:
	RETVAL

=item FSpIterateDirectory SPEC, MAXLEVELS, ITERATEFILTER, YOURDATAPTR

Iterate (scan) through a directory's content.
The FSpIterateDirectory function performs a recursive iteration (scan)
of the specified directory and calls your ITERATEFILTER function once
for each file and directory found.

The MAXLEVELS parameter lets you control how deep the recursion goes.
If MAXLEVELS is 1, FSpIterateDirectory only scans the specified directory;
if MAXLEVELS is 2, FSpIterateDirectory scans the specified directory and
one subdirectory below the specified directory; etc. Set MAXLEVELS to
zero to scan all levels.

The YOURDATAPTR parameter can point to whatever data structure you might
want to access from within the ITERATEFILTER. Your filter function will be
called as:

	$quit = &$filterFunction(YOURDATAPTR, SPEC);

=cut
MacOSRet
FSpIterateDirectory(spec, maxLevels, iterateFilter, yourDataPtr)
	FSSpec			&spec
	unsigned short	maxLevels
	SV *				iterateFilter
	SV *				yourDataPtr
	CODE:
	gMFProc = iterateFilter;
	RETVAL = FSpIterateDirectory(&spec, maxLevels, (IterateFilterProcPtr)MFIterateFilter, yourDataPtr);
	OUTPUT:
	RETVAL

=item FSpDTGetAPPL VOLUME, CREATOR

The FSpDTGetAPPL function finds an application (file type 'APPL') with
the specified CREATOR on the specified VOLUME. It first tries to get
the application mapping from the desktop database. If that fails, then
it tries to find an application with the specified creator using
the File Manager's CatSearch() routine. If that fails, then it tries to
find an application in the Desktop file.
Returns FSSpec or C<undef> on failure.

=cut
FSSpec	
FSpDTGetAPPL(volume, creator)
	SV *			volume
	OSType		creator
	PREINIT:
	StringPtr	vName = nil;
	Str63			volName;
	short			vRefNum;
	STRLEN		len;
	char *		vol;
	CODE:
	vol = SvPV(volume, len);
	if (len && vol[len-1] == ':')
		MacPerl_CopyC2P(vol, (vName = volName));
	else
		vRefNum = SvIV(volume);
	if (gMacPerl_OSErr = FSpDTGetAPPL(vName, vRefNum, creator, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item FSpDTSetComment SPEC, COMMENT

The FSpDTSetComment function sets a file or directory's Finder comment
field. The volume must support the Desktop Manager because you only
have read access to the Desktop file.

=cut
MacOSRet
FSpDTSetComment(spec, comment)
	FSSpec 	&spec
	Str255	comment

=item FSpDTGetComment SPEC

The FSpDTGetComment function gets a file or directory's Finder comment
field (if any) from the Desktop Manager or if the Desktop Manager is
not available, from the Finder's Desktop file.
Returns Str255, or C<undef> on failure.

=cut
Str255
FSpDTGetComment(spec)
	FSSpec	&spec
	CODE:
	if (gMacPerl_OSErr = FSpDTGetComment(&spec, RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item FSpDTCopyComment SRCSPEC, DSTSPEC

The FSpDTCopyComment function copies the desktop database comment from
the source to the destination object.  Both the source and the
destination volumes must support the Desktop Manager.

=cut
MacOSRet
FSpDTCopyComment(srcSpec, dstSpec)
	FSSpec	&srcSpec
	FSSpec	&dstSpec

=back

=cut
