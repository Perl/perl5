/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/InternetConfig/InternetConfig.xs,v 1.2 2000/09/09 22:18:27 neeri Exp $
 *
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: InternetConfig.xs,v $
 * Revision 1.2  2000/09/09 22:18:27  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:31  neeri
 * Checked into Sourceforge
 *
 * Revision 1.3  1998/04/07 01:02:55  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.2  1997/11/18 00:52:27  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:49  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef pad

#include <InternetConfig.h>
#include <GUSIFileSpec.h>
#include <Components.h>

static SV * MakeHndSV(Handle hdl)
{
	SV * res;
	char state;
	
	state = HGetState(hdl);
	HLock(hdl);
	res = GetHandleSize(hdl) ? newSVpv(*hdl, GetHandleSize(hdl)) : newSVpv("", 0);
	HSetState(hdl, state);
	
	return res;
}

#define PLstrcmp(s1, s2) memcmp((void *)s1, (void *)s2, s1[0]+1)
#define PLstrcpy(s1, s2) memcpy((void *)s1, (void *)s2, s1[0]+1)

static Boolean EqualMapEntries(ICMapEntry * e1, ICMapEntry *e2)
{
	return e1->file_type 	== e2->file_type
		&& e1->file_creator == e2->file_creator
		&& e1->post_creator == e2->post_creator
		&& !PLstrcmp(e1->extension, e2->extension)
		&& !PLstrcmp(e1->creator_app_name, e2->creator_app_name)
		&& !PLstrcmp(e1->post_app_name, e2->post_app_name)
		&& !PLstrcmp(e1->MIME_type, e2->MIME_type)
		&& !PLstrcmp(e1->entry_name, e2->entry_name);
}

MODULE = Mac::InternetConfig  PACKAGE = Mac::InternetConfig

=head2 Types

=over 4

=item ICMapEntry

An entry in the file map. Fields are:

	short 	version;
	OSType 	file_type;
	OSType 	file_creator;
	OSType 	post_creator;
	long 	flags;
	Str255 	extension;
	Str255 	creator_app_name;
	Str255 	post_app_name;
	Str255 	MIME_type;
	Str255 	entry_name;

=cut
STRUCT ICMapEntry
	short 	version;
	OSType 	file_type;
	OSType 	file_creator;
	OSType 	post_creator;
	long 	flags;
	Str255 	extension;
	Str255 	creator_app_name;
	Str255 	post_app_name;
	Str255 	MIME_type;
	Str255 	entry_name;

MODULE = ICMapEntry  PACKAGE = ICMapEntry

ICMapEntry
new(file_type, file_creator, post_creator, flags, extension, creator_app_name, post_app_name, MIME_type, entry_name)
	OSType 	file_type
	OSType 	file_creator
	OSType 	post_creator
	long 	flags
	Str255 	extension
	Str255 	creator_app_name
	Str255 	post_app_name
	Str255 	MIME_type
	Str255 	entry_name
	CODE:
	RETVAL.version 	 	= 0;
	RETVAL.file_type 	= file_type;
	RETVAL.file_creator = file_creator;
	RETVAL.post_creator = post_creator;
	RETVAL.flags		= flags;
	PLstrcpy(RETVAL.extension, extension);
	PLstrcpy(RETVAL.creator_app_name, creator_app_name);
	PLstrcpy(RETVAL.post_app_name, post_app_name);
	PLstrcpy(RETVAL.MIME_type, MIME_type);
	PLstrcpy(RETVAL.entry_name, entry_name);
	OUTPUT:
	RETVAL

=back

=head2 Functions

=over 4

=item ICStart 

=item ICStart CREATOR

Call this at application initialisation. Set creator to your application creator to 
allow for future expansion of the IC system (Default is MacPerl's creator). Returns 
a connection to the IC system.

=cut
MODULE = Mac::InternetConfig   PACKAGE = Mac::InternetConfig

ICInstance
ICStart(creator='McPL')
	OSType	creator;
	CODE:
	if (gMacPerl_OSErr = ICStart(&RETVAL, creator)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL
	
=item ICStop INST

It is illegal to call this routine inside a ICBegin/End pair.
Call this at application termination, after which INST
is no longer valid connection to IC.

=cut

MacOSRet
ICStop(inst)
	ICInstance	inst;

=item ICGeneralFindConfigFile INST, SEARCH_PREFS, CAN_CREATE, @FOLDERS

=item ICGeneralFindConfigFile INST, SEARCH_PREFS, CAN_CREATE

=item ICGeneralFindConfigFile INST

It is illegal to call this routine inside a ICBegin/End pair.
Call to configure this connection to IC.
This routine acts as a more general replacement for
ICFindConfigFile and ICFindUserConfigFile.
Set search_prefs to 1 (default) if you want it to search the preferences folder.
Set can_create to 1 if you want it to be able to create a new config.
Set count as the number of valid elements in folders.
Set folders to a pointer to the folders to search.
Setting count to 0 and folders to nil is OK.
Searches the specified folders and then optionally the Preferences folder
in a unspecified manner.

=cut

MacOSRet
ICGeneralFindConfigFile(inst, search_prefs=1, can_create=0, ...)
	ICInstance	inst;
	Boolean		search_prefs;
	Boolean		can_create;
	PREINIT:
	int			i;
	short		count;
	FSSpec		spec;
	ICDirSpec	spex[8];
	CODE:
	count = 0;
	for (i=3; i<items; ++i)
		if (!GUSIPath2FSp((char *) SvPV_nolen(ST(i)), &spec) && !GUSIFSpDown(&spec, "\p")) {
			spex[count].vRefNum = spec.vRefNum;
			spex[count].dirID	= spec.parID;
			++count;
		}
	RETVAL = ICGeneralFindConfigFile(inst, search_prefs, can_create, count, (ICDirSpecArrayPtr) spex);
	OUTPUT:
	RETVAL

=item ICChooseConfig INST

Requires IC 1.2.
It is illegal to call this routine inside a ICBegin/End pair.
Requests the user to choose a configuration, typically using some
sort of modal dialog. If the user cancels the dialog the configuration
state will be unaffected.

=cut

MacOSRet
ICChooseConfig(inst)
	ICInstance	inst;

=item ICChooseNewConfig INST

Requires IC 1.2.
It is illegal to call this routine inside a ICBegin/End pair.
Requests the user to choose a new configuration, typically using some
sort of modal dialog. If the user cancels the dialog the configuration
state will be unaffected.

=cut

MacOSRet
ICChooseNewConfig(inst)
	ICInstance	inst;

=item ICGetConfigName INST, LONGNAME
 
=item ICGetConfigName INST

Requires IC 1.2.
You must specify a configuration before calling this routine.
Returns a string that describes the current configuration at a user
level. Set longname to 1 if you want a long name, up to 255
characters, or 0 (default) if you want a short name, typically about 32
characters.
The returned string is for user display only. If you rely on the
exact format of it, you will conflict with any future IC
implementation that doesn't use explicit preference files.

=cut

Str255
ICGetConfigName(inst, longname=0)
	ICInstance	inst;
	Boolean		longname;
	CODE:
	if (gMacPerl_OSErr = ICGetConfigName(inst, longname, RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL
	
=item ICGetConfigReference INST

Requires IC 1.2.
You must specify a configuration before calling this routine.
Returns a self-contained reference to the instance's current
configuration.

=cut

Handle
ICGetConfigReference(inst)
	ICInstance	inst;
	CODE:
	if (!(RETVAL = NewHandle(0))) {
		XSRETURN_UNDEF;
	}
	if (gMacPerl_OSErr = ICGetConfigReference(inst, (ICConfigRefHandle) RETVAL)) {
		DisposeHandle(RETVAL);
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICSetConfigReference INST, REF, FLAGS

=item ICSetConfigReference INST, REF

Requires IC 1.2.
It is illegal to call this routine inside a ICBegin/End pair.
Reconfigures the instance using a configuration reference that was
got using ICGetConfigReference reference. Set the
icNoUserInteraction_bit in flags if you require that this routine
not present a modal dialog. Other flag bits are reserved and should
be set to zero.

=cut

MacOSRet
ICSetConfigReference(inst, ref, flags=0)
	ICInstance	inst; 
	Handle		ref;
	long		flags;
	CODE:
	RETVAL = ICSetConfigReference(inst, (ICConfigRefHandle) ref, flags);
	OUTPUT:
	RETVAL

=item ICGetSeed INST

You do not have to specify a configuration before calling this routine.
You do not have to be inside an ICBegin/End pair to call this routine.
Returns the current seed for the IC prefs database.
This seed changes each time a non-volatile preference is changed.
You can poll this to determine if any cached preferences change.

=cut

long
ICGetSeed(inst)
	ICInstance	inst;
	CODE:
	if (gMacPerl_OSErr = ICGetSeed(inst, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICGetComponentInstance INST

Requires IC 1.2.
You do not have to specify a configuration before calling this routine.
You do not have to be inside an ICBegin/End pair to call this routine.
Returns the connection to the IC component.

=cut

ComponentInstance
ICGetComponentInstance(inst)
	ICInstance	inst;
	CODE:
	if (gMacPerl_OSErr = ICGetComponentInstance(inst, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICBegin INST, PERM

You must specify a configuration before calling this routine. It is illegal to
call this routine inside a ICBegin/End pair. Starting reading or writing
multiple preferences. A call to this must be balanced by a call to ICEnd. Do
not call WaitNextEvent between these calls. The perm specifies whether you
intend to read or read/write. Only one writer is allowed per instance. Note
that this may open resource files that are not closed until you call ICEnd. 

=cut

MacOSRet
ICBegin(inst, perm)
	ICInstance	inst;
	ICPerm		perm;

=item ICGetPref INST, KEY

You must specify a configuration before calling this routine.
If you are getting or setting multiple preferences, you should place
these calls within an ICBegin/ICEnd pair.
If you call this routine outside of such a pair, it implicitly
calls ICBegin(inst, icReadOnlyPerm).
Reads the preference specified by key from the IC database to the
buffer pointed to by buf and size.
key must not be the empty string.
If called in a scalar context, return the preference. If called in a list
context, additionally returns the attributes.
Returns icPrefNotFound if there is no preference for the key.

=cut

void
ICGetPref(inst, key)
	ICInstance	inst;
	Str255		key;
	PREINIT:
	ICAttr	attr;
	Handle	pref;
	PPCODE:
	pref = NewHandle(0);
	gMacPerl_OSErr = ICFindPrefHandle(inst, key, &attr, pref);
	if (!gMacPerl_OSErr) 
		if (GIMME != G_ARRAY) {
			XPUSHs(sv_2mortal(MakeHndSV(pref)));
		} else {
			XPUSHs(sv_2mortal(MakeHndSV(pref)));
			XPUSHs(sv_2mortal(newSViv(attr)));
		}
	DisposeHandle(pref);

=item ICSetPref INST, KEY, VALUE
=item ICSetPref INST, KEY, VALUE, ATTR

You must specify a configuration before calling this routine.
If you are getting or setting multiple preferences, you should place
these calls within an ICBegin/ICEnd pair.
If you call this routine outside of such a pair, it implicitly
calls ICBegin(inst, icReadWritePerm).
Sets the preference specified by KEY from the IC database to the
VALUE. If attr is ICattr_no_change (the default) then the preference attributes 
are not set. Otherwise the preference attributes are set to attr.
Returns icPermErr if the previous ICBegin was passed icReadOnlyPerm.
Returns icPermErr if current attr is locked, new attr is locked.

=cut 

MacOSRet
ICSetPref(inst, key, value, attr=ICattr_no_change)
	ICInstance	inst;
	Str255		key;
	SV *		value;
	ICAttr		attr;
	PREINIT:
	STRLEN	len;
	Ptr		ptr;
	Handle	pref;
	CODE:
	ptr = SvPV(value, len);
	RETVAL = PtrToHand(ptr, &pref, len);
	if (!RETVAL) {
		RETVAL = ICSetPrefHandle(inst, key, attr, pref);
		DisposeHandle(pref);
	}
	OUTPUT:
	RETVAL

=item ICCountPref INST

You must specify a configuration before calling this routine.
You must be inside an ICBegin/End pair to call this routine.
Counts the total number of preferences.

=cut

long
ICCountPref(inst)
	ICInstance	inst;
	CODE:
	if (gMacPerl_OSErr = ICCountPref(inst, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL
	
=item ICGetIndPref	INST, N

You must specify a configuration before calling this routine.
You must be inside an ICBegin/End pair to call this routine.
Returns the key of the Nth preference.
n must be positive.
Returns icPrefNotFoundErr if n is greater than the total number of preferences.

=cut

Str255
ICGetIndPref(inst, n)
	ICInstance	inst;
	long		n;
	CODE:
	if (gMacPerl_OSErr = ICGetIndPref(inst, n, RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICDeletePref INST, KEY

You must specify a configuration before calling this routine.
You must be inside an ICBegin/End pair to call this routine.
Deletes the preference specified by KEY.
KEY must not be the empty string.
Returns icPrefNotFound if the preference specified by key is not present.

=cut

MacOSRet
ICDeletePref(inst, key)
	ICInstance	inst;
	Str255		key;

=item ICEnd INST

You must specify a configuration before calling this routine.
You must be inside an ICBegin/End pair to call this routine.
Terminates a preference session, as started by ICBegin.
You must have called ICBegin before calling this routine.

=cut

MacOSRet
ICEnd(inst)
	ICInstance	inst;

=item ICEditPreferences	INST, KEY

Requires IC 1.1.
You must specify a configuration before calling this routine.
You do not have to be inside an ICBegin/End pair to call this routine.
Instructs IC to display the user interface associated with editing
preferences and focusing on the preference specified by key.
If key is the empty string then no preference should be focused upon.
You must have specified a configuration before calling this routine.
You do not need to call ICBegin before calling this routine.
In the current implementation this launches the IC application
(or brings it to the front) and displays the window containing
the preference specified by key.
It may have a radically different implementation in future
IC systems.

=cut

MacOSRet
ICEditPreferences(ic, key)
	ICInstance	ic;
	Str255			key;

=item ICParseURL INST, HINT, DATA, START, END

=item ICParseURL INST, HINT, DATA

Requires IC 1.1.
You must specify a configuration before calling this routine.
You do not have to be inside an ICBegin/End pair to call this routine.
Parses a URL out of the specified text and returns it in a canonical form
in a handle.
HINT indicates the default scheme for URLs of the form "name@address".
If HINT is the empty string then URLs of that form are not allowed.
DATA contains the text.
START and END should be passed in as the current selection of
the text. This selection is given in the same manner as TextEdit,
ie if START == END then there is no selection only an insertion
point. Also START ² END and 0 ² START ² length(DATA) and 0 ² END ² length(DATA).
If START and END are omitted, the whole of DATA is assumed.
In a scalar context, returns URL. In an array context, returns URL, START, END.

=cut

void
ICParseURL(ic, hint, sv, start=-1, end=-1)
	ICInstance	ic;
	Str255			hint;
	SV *			sv;
	long			start;
	long			end;
	PREINIT:
	STRLEN	len;
	Ptr 	data;
	Handle	url;
	PPCODE:
	url = NewHandle(0);
	data = (Ptr) SvPV(sv, len);
	if (start == -1) {
		start = 0;
		end	  = len;
	} else if (end == -1) 
		end   = start;
	gMacPerl_OSErr = ICParseURL(ic, hint, data, len, &start, &end, url);
	if (!gMacPerl_OSErr) 
		if (GIMME != G_ARRAY) {
			XPUSHs(sv_2mortal(MakeHndSV(url)));
		} else {
			XPUSHs(sv_2mortal(MakeHndSV(url)));
			XPUSHs(sv_2mortal(newSViv(start)));
			XPUSHs(sv_2mortal(newSViv(end)));
		}
	DisposeHandle(url);

=item ICLaunchURL INST, HINT, DATA, START, END

=item ICLaunchURL INST, HINT, DATA

Requires IC 1.1.
You must specify a configuration before calling this routine.
You do not have to be inside an ICBegin/End pair to call this routine.
Parses a URL out of the specified text and feeds it off to the appropriate helper.
HINT indicates the default scheme for URLs of the form "name@address".
If HINT is the empty string then URLs of that form are not allowed.
DATA contains the text.
START and END should be passed in as the current selection of
the text. This selection is given in the same manner as TextEdit,
ie if START == END then there is no selection only an insertion
point. Also START ² END and 0 ² START ² length(DATA) and 0 ² END ² length(DATA).
If START and END are omitted, the whole of DATA is assumed.
In a scalar context, returns URL. In an array context, returns URL, START, END.

=cut

void
ICLaunchURL(ic, hint, sv, start=-1, end=-1)
	ICInstance		ic;
	Str255			hint;
	SV *			sv;
	long			start;
	long			end;
	PREINIT:
	STRLEN	len;
	Ptr 	data;
	PPCODE:
	data = (Ptr) SvPV(sv, len);
	if (start == -1) {
		start = 0;
		end	  = len;
	} else if (end == -1) 
		end   = start;
	gMacPerl_OSErr = ICLaunchURL(ic, hint, data, len, &start, &end);
	if (!gMacPerl_OSErr) 
		if (GIMME != G_ARRAY) {
			XPUSHs(sv_2mortal(newSViv(1)));
		} else {
			XPUSHs(sv_2mortal(newSViv(start)));
			XPUSHs(sv_2mortal(newSViv(end)));
		}

=item ICMapFileName INST, NAME

Returns the C<ICMapEntry> matching best the given name.

=cut
ICMapEntry
ICMapFilename(inst, filename)
	ICInstance		inst	
	Str255 			filename
	CODE:
	if (gMacPerl_OSErr = ICMapFilename(inst, filename, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICMapTypeCreator INST, TYPE, CREATOR [, NAME]

Takes the type and creator (and optionally the name) of an outgoing
file and returns the most appropriate C<ICMapEntry>.

=cut
ICMapEntry
ICMapTypeCreator(inst, fType, fCreator, filename=NO_INIT)
	ICInstance 	inst
	OSType 		fType
	OSType 		fCreator
	Str255		filename
	CODE:
	if (items < 4)
		filename[0] = 0;
	if (gMacPerl_OSErr = ICMapTypeCreator(inst, fType, fCreator, filename, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICMapEntriesFileName INST, ENTRIES, NAME

Returns the C<ICMapEntry> matching best the given name.

=cut
ICMapEntry
ICMapEntriesFilename(inst, entries, filename)
	ICInstance		inst	
	Handle			entries
	Str255 			filename
	CODE:
	if (gMacPerl_OSErr = ICMapEntriesFilename(inst, entries, filename, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICMapEntriesTypeCreator INST, ENTRIES, TYPE, CREATOR [, NAME]

Takes the type and creator (and optionally the name) of an outgoing
file and returns the most appropriate C<ICMapEntry>.

=cut
ICMapEntry
ICMapEntriesTypeCreator(inst, entries, fType, fCreator, filename=NO_INIT)
	ICInstance 	inst
	Handle		entries
	OSType 		fType
	OSType 		fCreator
	Str255		filename
	CODE:
	if (items < 5)
		filename[0] = 0;
	if (gMacPerl_OSErr = ICMapEntriesTypeCreator(inst, entries, fType, fCreator, filename, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICCountMapEntries	INST, ENTRIES

Counts the number of entries in the map.

=cut
long
ICCountMapEntries(inst, entries)
	ICInstance 	inst
	Handle 		entries
	CODE:
	if (gMacPerl_OSErr = ICCountMapEntries(inst, entries, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICGetIndMapEntry INST, ENTRIES, INDEX

Returns the position of a map entry and the entry itself.

	$map = ICGetIndMapEntry $inst, $entries, 5;
	($pos, $map) = ICGetIndMapEntry $inst, $entries, 5;

=cut
void
ICGetIndMapEntry(inst, entries, ndx)
	ICInstance 	inst
	Handle 		entries
	long 		ndx
	PPCODE:
	{
		long		pos;
		ICMapEntry	entry;
		
		if (gMacPerl_OSErr = ICGetIndMapEntry(inst, entries, ndx, &pos, &entry)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(long, pos);
		XS_XPUSH(ICMapEntry, entry);
	}

=item ICGetMapEntry INST, ENTRIES, POS

Returns the entry located at position pos in the mappings database.

=cut
ICMapEntry
ICGetMapEntry(inst, entries, pos)
	ICInstance 	inst
	Handle 		entries
	long 		pos
	CODE:
	if (gMacPerl_OSErr = ICGetMapEntry(inst, entries, pos, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item ICSetMapEntry INST, ENTRIES, POS, ENTRY

Replace the entry at position pos

=cut
MacOSRet
ICSetMapEntry(inst, entries, pos, entry)
	ICInstance 	inst
	Handle 		entries
	long 		pos
	ICMapEntry &entry

=item ICDeleteMapEntry INST, ENTRIES, POS

Delete the entry at position pos

=cut
MacOSRet
ICDeleteMapEntry(inst, entries, pos)
	ICInstance 	inst
	Handle 		entries
	long 		pos

=item ICAddMapEntry INST, ENTRIES, ENTRY

Add an entry to the database.

=cut
MacOSRet
ICAddMapEntry(inst, entries, entry)
	ICInstance 	inst
	Handle 		entries
	ICMapEntry &entry

long
_ICMapFind(inst, entries, entry)
	ICInstance 	inst
	Handle 		entries
	ICMapEntry 	entry
	CODE:
	{
		long		ndx;
		ICMapEntry	ent;
		
		for (ndx = 0; ICGetIndMapEntry(inst, entries, ndx++, &RETVAL, &ent); )
			if (EqualMapEntries(&entry, &ent))
				goto found;
		XSRETURN_UNDEF;
found:
		;
	}
	OUTPUT:
	RETVAL

=back

=cut
