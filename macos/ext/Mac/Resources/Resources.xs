/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Resources/Resources.xs,v 1.2 2000/09/09 22:18:28 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Resources.xs,v $
 * Revision 1.2  2000/09/09 22:18:28  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:33  neeri
 * Checked into Sourceforge
 *
 * Revision 1.3  1998/04/07 01:03:11  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.2  1997/11/18 00:53:19  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:50:41  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Resources.h>

#define ResErrorReturn	\
	if (gMacPerl_OSErr = ResError()) {	\
		XSRETURN_UNDEF;						\
	} else {							\
		XSRETURN_YES;						\
	}

#define ResErrorCheck						\
	if (gMacPerl_OSErr = ResError()) {	\
		XSRETURN_UNDEF;						\
	} else 0 	

#define ResErrorCheckRetval				\
	if (RETVAL == -1) {						\
		gMacPerl_OSErr = ResError();		\
		XSRETURN_UNDEF;						\
	} else 0

#define ResErrorCheckRetvalNULL			\
	if (!RETVAL) {								\
		gMacPerl_OSErr = ResError();		\
		XSRETURN_UNDEF;						\
	} else 0

MODULE = Mac::Resources	PACKAGE = Mac::Resources

=head2 Functions

=over 4

=item CloseResFile RFD

Given a file reference number for a file whose resource fork is open, the
CloseResFile procedure performs four tasks. First, it updates the file by calling
the &UpdateResFile procedure. Second, it releases the memory occupied by each
resource in the resource fork by calling the &DisposeHandle procedure. Third, it
releases the memory occupied by the resource map. The fourth task is to close the
resource fork.

=cut
void
CloseResFile(refNum)
	short	refNum

=item CurResFile

The CurResFile function returns the file reference number associated with the
current resource file. You can call this function when your application starts up
(before opening the resource fork of any other file) to get the file reference
number of your application's resource fork.

	$RFD = CurResFile;

=cut
short
CurResFile()

=item HomeResFile RESOURCE

Given a handle to a resource, the HomeResFile function returns the file reference
number for the resource fork containing the specified resource. If the given
handle isn't a handle to a resource, HomeResFile returns –1, and the &ResError
function returns the result code resNotFound. If HomeResFile returns 0, the
resource is in the System file's resource fork. If HomeResFile returns 1, the
resource is ROM-resident.

	$RFD = HomeResFile($Resource);

=cut
short
HomeResFile(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorCheckRetval;

=item CreateResFile NAME

The CreateResFile procedure creates an empty resource file.

	if ( CreateResFile("Resource.rsrc")) {
		# error occurred
	} else {
		# proceed
	}

=cut
void
CreateResFile(fileName)
	Str255	fileName
	CLEANUP:
	ResErrorReturn;

=item OpenResFile NAME

The OpenResFile function opens an existing resource file. It also makes this file
the current resource file.

	if ( defined($RFD = OpenResFile("Resource.rsrc")) ) {
		# proceed
	} else {
		# error occurred
	}

=cut
short
OpenResFile(fileName)
	Str255	fileName
	CLEANUP:
	ResErrorCheckRetval;

=item UseResFile RFD

The UseResFile procedure searches the list of files whose resource forks have
been opened for the file specified by the RFD parameter. If the specified file
is found, the Resource Manager sets the current resource file to the specified
file. If there's no resource fork open for a file with that reference number,
UseResFile does nothing. To set the current resource file to the System file, use
0 for the refNum parameter.

	if (UseResFile($RFD)) {
		# error occurred
	} else {
		# proceed
	}

=cut
void
UseResFile(refNum)
	short	refNum
	CLEANUP:
	ResErrorReturn;


=item CountTypes

=item Count1Types

The CountTypes (Count1Types) function reads the resource maps in memory for all resource forks
(the current resource fork) open to your application. It returns an integer representing the 
total number of unique resource types.

	$types = Count1Types;

=cut
short
CountTypes()

short
Count1Types()

=item GetIndType INDEX

=item Get1IndType INDEX

Given an index number from 1 to the number of resource types in all resource
forks (the current resource fork)
open to your application (as returned by CountTypes), the GetIndType
procedure returns a resource type. You can call
GetIndType repeatedly over the entire range of the index to get all the resource
types available in all resource forks open to your application. If the given
index isn't in the range from 1 to the number of resource types as returned by
CountTypes, undef() is returned.

	# Load up @resourceTypes with the types from the current file.
	for (1 .. Count1Types) {
		$resourceTypes[$_-1] = Get1IndType($_);
	}

=cut
OSType
GetIndType(index)
	short	index
	CODE:
	GetIndType(&RETVAL, index);
	OUTPUT:
	RETVAL
	CLEANUP:
	ResErrorCheckRetvalNULL;

OSType
Get1IndType(index)
	short	index
	CODE:
	Get1IndType(&RETVAL, index);
	OUTPUT:
	RETVAL
	CLEANUP:
	ResErrorCheckRetvalNULL;

=item SetResLoad BOOL

Enable and disable automatic loading of resource data into memory for routines
that return handles to resources.

=cut
void
SetResLoad(load)
	Boolean	load

=item CountResources TYPE

=item Count1Resources TYPE

Get the total number of available resources of a given type. Count1Resources
looks only at the current resource fork.

	$totalDialogsAvailable = CountResources "DITL";

=cut
short
CountResources(theType)
	OSType	theType

short
Count1Resources(theType)
	OSType	theType

=item GetIndResource TYPE, INDEX

=item Get1IndResource TYPE, INDEX

Given an index ranging from 1 to the number of resources of a given type returned
by &CountResources (&Count1Resources) (that is, the number of resources of that type 
in all resource forks open to your application), the GetIndResource function returns a 
handle to a resource of the given type. If you call GetIndResource repeatedly over the
entire range of the index, it returns handles to all resources of the given type
in all resource forks open to your application.

	# Load up handles of this type of resource
	for (1 .. CountResources("DITL")) {
		$dialogs[$_] = GetIndResource("DITL", $_);
	}

=cut
Handle
GetIndResource(theType, index)
	OSType	theType
	short	index
	CLEANUP:
	ResErrorCheckRetvalNULL;

Handle
Get1IndResource(theType, index)
	OSType	theType
	short	index
	CLEANUP:
	ResErrorCheckRetvalNULL;

=item GetResource TYPE, ID

=item Get1Resource TYPE, ID

Get resource data for a resource specified by resource type and resource ID.

	$SFGdialog = GetResource("DITL", 6042);
	if ( defined $SFGdialog ) {
		# proceed
	}

=cut
Handle
GetResource(theType, theID)
	OSType	theType
	short	theID
	CLEANUP:
	ResErrorCheckRetvalNULL;

Handle
Get1Resource(theType, theID)
	OSType	theType
	short	theID
	CLEANUP:
	ResErrorCheckRetvalNULL;

=item GetNamedResource TYPE, NAME

=item Get1NamedResource TYPE, NAME

The GetNamedResource (Get1NamedResource) function searches the resource maps in memory for the
resource specified by the parameters $TYPE and $NAME.

	$SFGdialog = GetNamedResource("DITL", "Standard Get");
	if ( defined $SFGdialog ) {
		# proceed
	}

=cut
Handle
GetNamedResource(theType, name)
	OSType	theType
	Str255	name
	CLEANUP:
	ResErrorCheckRetvalNULL;

Handle
Get1NamedResource(theType, name)
	OSType	theType
	Str255	name
	CLEANUP:
	ResErrorCheckRetvalNULL;

=item LoadResource HANDLE

Given a handle to a resource, LoadResource reads the resource data into memory.
If the HANDLE parameter doesn't contain a handle to a resource, then LoadResource
returns undef.

	if (LoadResource($HANDLE) ) {
		# proceed
	} else {
		# error occurred
	}

=cut
void
LoadResource(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorReturn;

=item ReleaseResource HANDLE

Given a handle to a resource, ReleaseResource releases the memory occupied by the
resource data, if any, and sets the master pointer of the resource's handle in
the resource map in memory to NIL. If your application previously obtained a
handle to that resource, the handle is no longer valid. If your application
subsequently calls the Resource Manager to get the released resource, the
Resource Manager assigns a new handle. 

	if ( ReleaseResource($HANDLE) ) {
		# proceed
	} else {
		# error occurred
	}

=cut
void
ReleaseResource(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorReturn;

=item DetachResource HANDLE

Given a handle to a resource, ReleaseResource releases the memory occupied by the
resource data, if any, and sets the master pointer of the resource's handle in
the resource map in memory to NIL. If your application previously obtained a
handle to that resource, the handle is no longer valid. If your application
subsequently calls the Resource Manager to get the released resource, the
Resource Manager assigns a new handle. 

	if ( DetachResource($HANDLE) ) {
		# proceed
	} else {
		# error occurred
	}

=cut
void
DetachResource(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorReturn;

=item UniqueID TYPE

=item Unique1ID TYPE

The UniqueID function returns as its function result a resource ID greater than 0
that isn't currently assigned to any resource of the specified type in any open
resource fork. You should use this function before adding a new resource to
ensure that you don't duplicate a resource ID and override an existing resource.
Unique1ID ensures uniqueness within the current resource fork.

	$id = Unique1ID("DITL");

=cut
short
UniqueID(theType)
	OSType	theType

short
Unique1ID(theType)
	OSType	theType


=item GetResAttrs HANDLE

Given a handle to a resource, the GetResAttrs function returns the resource's
attributes as recorded in its entry in the resource map in memory. If the value
of the theResource parameter isn't a handle to a valid resource, undef is returned.

	$resAttrs = GetResAttrs($HANDLE);
	if ( defined $resAttrs ) {
		# proceed
	}

=cut
short
GetResAttrs(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorCheck;

=item GetResInfo HANDLE

Given a handle to a resource, the GetResInfo procedure returns the resource's
resource ID, resource type, and resource name. If the handle isn't a valid handle
to a resource, undef is returned.

	($id, $type, $name) = GetResInfo($HANDLE);
	if ( defined $id ) {
		# proceed
	}

=cut
void
GetResInfo(theResource)
	Handle	theResource
	PPCODE:
	{
		short		theID;
		OSType	theType;
		Str255	name;
		
		GetResInfo(theResource, &theID, &theType, name);
		ResErrorCheck;

		EXTEND(sp, 3);
		XS_PUSH(short, theID);
		XS_PUSH(OSType, theType);
		if (*name)
			XS_PUSH(Str255, name);
	}

=item SetResInfo HANDLE, ID, NAME

Given a handle to a resource, SetResInfo changes the resource ID and the resource
name of the specified resource to the values given in ID and NAME. If you pass
an empty string for the name parameter, the resource name is not changed.

=cut
void
SetResInfo(theResource, theID, name)
	Handle	theResource
	short	theID
	Str255	name
	CLEANUP:
	ResErrorReturn;

=item AddResource HANDLE, TYPE, ID, NAME

Given a handle to any type of data in memory (but not a handle to an existing
resource), AddResource adds the given handle, resource type, resource ID, and
resource name to the current resource file's resource map in memory. The
AddResource procedure sets the resChanged attribute to 1; it does not set any of
the resource's other attributes—that is, all other attributes are set to 0.

=cut
void
AddResource(theData, theType, theID, name)
	Handle	theData
	OSType	theType
	short	theID
	Str255	name
	CLEANUP:
	ResErrorReturn;

=item GetResourceSizeOnDisk HANDLE

Given a handle to a resource, the GetResourceSizeOnDisk function checks the
resource on disk (not in memory) and returns its exact size, in bytes. If the
handle isn't a handle to a valid resource, undef is returned.

	$size = GetResourceSizeOnDisk($HANDLE);
	if ( defined $size ) {
		# proceed
	}

=cut
long
GetResourceSizeOnDisk(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorCheckRetval;

=item GetMaxResourceSize HANDLE

Like &GetResourceSizeOnDisk, GetMaxResourceSize takes a handle and returns the
size of the corresponding resource. However, GetMaxResourceSize does not check
the resource on disk; instead, it either checks the resource size in memory or,
if the resource is not in memory, calculates its size, in bytes, on the basis of
information in the resource map in memory. This gives you an approximate size for
the resource that you can count on as the resource's maximum size. It's possible
that the resource is actually smaller than the offsets in the resource map
indicate because the file has not yet been compacted. If you want the exact size
of a resource on disk, either call &GetResourceSizeOnDisk or call &UpdateResFile
before calling GetMaxResourceSize.

	$size = GetMaxResourceSize($HANDLE);
	if ( defined $size ) {
		# proceed
	}

=cut
long
GetMaxResourceSize(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorCheckRetval;

=item RsrcMapEntry HANDLE

Given a handle to a resource, RsrcMapEntry returns the offset of the specified
resource's entry from the beginning of the resource map in memory. If it doesn't
find the resource entry, RsrcMapEntry returns 0, and the ResError function
returns the result code resNotFound. If you pass a handle whose value is NIL,
RsrcMapEntry returns arbitrary data. 

	$offset = RsrcMapEntry($HANDLE);
	if ( defined $offset ) {
		# proceed
	}

=cut
long
RsrcMapEntry(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorCheckRetvalNULL;

=item SetResAttrs HANDLE, ATTRS

Given a handle to a resource, SetResAttrs changes the resource attributes of the
resource to those specified in the attrs parameter. The SetResAttrs procedure
changes the information in the resource map in memory, not in the file on disk.
The resProtected attribute changes immediately. Other attribute changes take
effect the next time the specified resource is read into memory but are not made
permanent until the Resource Manager updates the resource fork.

	if ( SetResAttrs($HANDLE, $ATTRS) ) {
		# proceed
	} else {
		# error
	}

=cut
void
SetResAttrs(theResource, attrs)
	Handle	theResource
	short	attrs
	CLEANUP:
	ResErrorReturn;

=item ChangedResource HANDLE

Given a handle to a resource, the ChangedResource procedure sets the resChanged
attribute for that resource in the resource map in memory. If the resChanged
attribute for a resource has been set and your application calls &UpdateResFile or
quits, the Resource Manager writes the resource data for that resource (and for
all other resources whose resChanged attribute is set) and the entire resource
map to the resource fork of the corresponding file on disk. If the resChanged
attribute for a resource has been set and your application calls &WriteResource,
the Resource Manager writes only the resource data for that resource to disk.

	if ( ChangedResource($HANDLE) ) {
		# proceed
	} else {
		# error
	}

=cut
void
ChangedResource(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorReturn;

=item RemoveResource HANDLE

Given a handle to a resource in the current resource file, RemoveResource removes
the resource entry (resource type, resource ID, resource name, if any, and
resource attributes) from the current resource file's resource map in memory. 

	if ( RemoveResource($HANDLE) ) {
		# proceed
	} else {
		# error
	}

=cut
void
RemoveResource(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorReturn;

=item UpdateResFile RFD

Given the reference number of a file whose resource fork is open, UpdateResFile
performs three tasks. The first task is to change, add, or remove resource data
in the file's resource fork to match the resource map in memory. Changed resource
data for each resource is written only if that resource's resChanged bit has been
set by a successful call to &ChangedResource or &AddResource. The UpdateResFile
procedure calls the &WriteResource procedure to write changed or added resources
to the resource fork.

	if ( UpdateResFile($RFD) ) {
		# proceed
	} else {
		# error
	}

=cut
void
UpdateResFile(refNum)
	short	refNum
	CLEANUP:
	ResErrorReturn;

=item WriteResource HANDLE

Given a handle to a resource, WriteResource checks the resChanged attribute of
that resource. If the resChanged attribute is set to 1 (after a successful call
to the &ChangedResource or &AddResource procedure), WriteResource writes the
resource data in memory to the resource fork, then clears the resChanged
attribute in the resource's resource map in memory.

	if ( WriteResource($HANDLE) ) {
		# proceed
	} else {
		# error
	}

=cut
void
WriteResource(theResource)
	Handle	theResource
	CLEANUP:
	ResErrorReturn;

=item SetResPurge INSTALL

Specify TRUE in the install parameter to make the Memory Manager pass the handle
for a resource to the Resource Manager before purging the resource data to which
the handle points. The Resource Manager determines whether the handle points to a
resource in the application heap. It also checks if the resource's resChanged
attribute is set to 1. If these two conditions are met, the Resource Manager
calls the &WriteResource procedure to write the resource's resource data to the
resource fork before returning control to the Memory Manager.

Specify FALSE in the install parameter to restore the normal state, so that the
Memory Manager purges resource data when it needs to without calling the Resource
Manager.

	if ( SetResPurge(1) ) {
		# proceed
	} else {
		# error
	}

=cut
void
SetResPurge(install)
	Boolean	install
	CLEANUP:
	ResErrorReturn;

=item GetResFileAttrs RFD

Given a file reference number, the GetResFileAttrs function returns the
attributes of the file's resource fork. Specify 0 in $RFD to get
the attributes of the System file's resource fork. If there's no open resource
fork for the given file reference number, undef is returned.

	$rfa = GetResFileAttrs($RFD);
	if ( defined $rfa ) {
		# proceed
	}

=cut
short
GetResFileAttrs(refNum)
	short	refNum
	CLEANUP:
	ResErrorCheck;

=item SetResFileAttrs RFD, ATTRS

Given a file reference number, the SetResFileAttrs procedure sets the attributes
of the file's resource fork to those specified in the attrs parameter. If the
refNum parameter is 0, it represents the System file's resource fork. However,
you shouldn't change the attributes of the System file's resource fork. If
there's no resource fork with the given reference number, SetResFileAttrs does
nothing, and the ResError function returns the result code noErr.

	if ( SetResFileAttrs($RFD, $ATTRS) ) {
		# proceed
	} else {
		# error
	}

=cut
void
SetResFileAttrs(refNum, attrs)
	short	refNum
	short	attrs
	CLEANUP:
	ResErrorReturn;

=item RGetResource TYPE, ID

The RGetResource function searches the resource maps in memory for the resource
specified by the parameters $TYPE and $ID. The resource maps in memory, which
represent all open resource forks, are arranged as a linked list. The
RGetResource function first uses GetResource to search this list. The GetResource
function starts with the current resource file and progresses through the list in
order (that is, in reverse chronological order in which the resource forks were
opened) until it finds the resource's entry in one of the resource maps. If
GetResource doesn't find the specified resource in its search of the resource
maps of open resource forks (which includes the System file's resource fork),
RGetResource sets the global variable RomMapInsert to TRUE, then calls
GetResource again. In response, GetResource performs the same search, but this
time it looks in the resource map of the ROM-resident resources before searching
the resource map of the System file. 

	$handle = RGetResource("DITL", 6042);
	if ( defined $handle ) {
		# proceed
	}

=cut
Handle
RGetResource(theType, theID)
	OSType	theType
	short	theID
	CLEANUP:
	ResErrorCheckRetvalNULL;

=item FSpOpenResFile SPEC, PERMISSION

The FSpOpenResFile function opens the resource fork of the file identified by the
spec parameter. It also makes this file the current resource file.

	$sp = FSpOpenResFile($SPEC);
	if ( defined $sp ) {
		# proceed
	}

In addition to opening the resource fork for the file with the specified name,
FSpOpenResFile lets you specify in the permission parameter the read/write permission
of the resource fork the first time it is opened. 

=cut
short
FSpOpenResFile(spec, permission)
	FSSpec	&spec
	SInt8	permission
	CLEANUP:
	ResErrorCheckRetval;

=item FSpCreateResFile SPEC, CREATOR, FILETYPE, SCRIPTTAG

The FSpCreateResFile procedure creates an empty resource fork for a file with the
specified $FILETYPE, $CREATOR, and $SCRIPTTAG in the location and with the name
designated by the spec parameter. (An empty resource fork contains no resource
data but does include a resource map.) 

	if ( FSpCreateResFile($SPEC, $CREATOR, $FILETYPE, $SCRIPTTAG) ) {
		# proceed
	} else {
		# error
	}

=cut
void
FSpCreateResFile(spec, creator, fileType, scriptTag)
	FSSpec		&spec
	OSType		creator
	OSType		fileType
	SInt8			scriptTag
	CLEANUP:
	ResErrorReturn;

=item ReadPartialResource HANDLE, OFFSET, BYTECOUNT

The ReadPartialResource procedure reads the resource subsection identified by the
theResource, offset, and count parameters.

   $data = ReadPartialResource($rsrc, 2000, 256);

=cut
SV *
ReadPartialResource(theResource, offset, count)
	Handle	theResource
	long	offset
	long	count
	CODE:
	RETVAL = newSV(count);
	ReadPartialResource(theResource, offset, SvPV_nolen(RETVAL), count);
	ResErrorCheck;
	OUTPUT:
	RETVAL

=item WritePartialResource HANDLE, OFFSET, DATA

The WritePartialResource procedure writes the data specified by DATA 
to the resource subsection identified by the HANDLE and OFFSET parameters.

	if ( WritePartialResource($HANDLE, $OFFSET, $DATA) ) {
		# proceed
	} else {
		# error
	}

=cut
void
WritePartialResource(theResource, offset, data)
	Handle	theResource
	long	offset
	SV *	data
	CODE: 
	{
		STRLEN	count;
		void *	buffer = SvPV(data, count);
		WritePartialResource(theResource, offset, buffer, count);
		ResErrorReturn;
	}

=item SetResourceSize HANDLE, SIZE

Given a handle to a resource, SetResourceSize sets the size field of the
specified resource on disk without writing the resource data. You can change the
size of any resource, regardless of the amount of memory you have available.

	if ( SetResource($HANDLE, $SIZE) ) {
		# proceed
	} else {
		# error
	}

=cut
void
SetResourceSize(theResource, newSize)
	Handle	theResource
	long	newSize
	CLEANUP:
	ResErrorReturn;

=back

=cut
