/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/AppleEvents/AppleEvents.xs,v 1.2 2000/09/09 22:18:25 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: AppleEvents.xs,v $
 * Revision 1.2  2000/09/09 22:18:25  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 01:48:18  neeri
 * Checked into Sourceforge
 *
 * Revision 1.3  1999/06/03 19:22:05  pudge
 * Add AEPutKey, AEPutKeyDesc, AEGetKeyDesc functions.  Inline constant subroutines.
 *
 * Revision 1.2  1997/11/18 00:52:07  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:07  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdarg.h>
#include <Types.h>
#include <Memory.h>
#include <AppleEvents.h>
#include "PerlAEUtils.h"
#include "SubLaunch.h"

typedef int 	SysRet;
typedef long	SysRetLong;

#define AEFail(error)	if (gMacPerl_OSErr = (error)) { XSRETURN_UNDEF; } else 0

MODULE = Mac::AppleEvents	PACKAGE = AEDesc

AEDesc
_new(package, type='null', data=0)
	SV *		package
	OSType	type
	Handle	data
	CODE:
	{
		RETVAL.descriptorType	=	type;
		RETVAL.dataHandle			=	data;
	}
	OUTPUT:
	RETVAL

OSType
type(desc, newType=0)
	AEDesc	desc
	OSType	newType
	CODE:
	{
		if (items>1)
			desc.descriptorType	=	newType;
		RETVAL = desc.descriptorType;
	}
	OUTPUT:
	desc
	RETVAL

Handle
data(desc, newData=0)
	AEDesc	desc
	Handle	newData
	CODE:
	{
		if (items>1)
			desc.dataHandle	=	newData;
		RETVAL = desc.dataHandle;
	}
	OUTPUT:
	desc
	RETVAL

MODULE = Mac::AppleEvents	PACKAGE = AEKeyDesc

AEKeyDesc
_new(package, key=0, type='null', data=0)
	SV *		package
	OSType	key
	OSType	type
	Handle	data
	CODE:
	{
		RETVAL.descKey								=	key;
		RETVAL.descContent.descriptorType	=	type;
		RETVAL.descContent.dataHandle			=	data;
	}
	OUTPUT:
	RETVAL

OSType
key(desc, newKey=0)
	AEKeyDesc	desc
	OSType		newKey
	CODE:
	{
		if (items>1)
			desc.descKey	=	newKey;
		RETVAL = desc.descKey;
	}
	OUTPUT:
	desc
	RETVAL

OSType
type(desc, newType=0)
	AEKeyDesc	desc
	OSType		newType
	CODE:
	{
		if (items>1)
			desc.descContent.descriptorType	=	newType;
		RETVAL = desc.descContent.descriptorType;
	}
	OUTPUT:
	desc
	RETVAL

Handle
data(desc, newData=0)
	AEKeyDesc	desc
	Handle		newData
	CODE:
	{
		if (items>1)
			desc.descContent.dataHandle	=	newData;
		RETVAL = desc.descContent.dataHandle;
	}
	OUTPUT:
	desc
	RETVAL

MODULE = Mac::AppleEvents	PACKAGE = Mac::AppleEvents

=head2 Raw AppleEvent Interface

=over 4

=item AECreateDesc TYPE, DATA

The AECreateDesc function creates a new descriptor record that incorporates the
specified data.

=cut
AEDesc
AECreateDesc(typeCode, data)
	OSType	typeCode
	SV *		data
	CODE:
	{
		void *	dataPtr;
		STRLEN	dataSize;
		
		dataPtr = SvPV(data, dataSize);
		
		AEFail(AECreateDesc(typeCode, dataPtr, dataSize, &RETVAL));
	}
	OUTPUT:
	RETVAL

=item AECoerce TYPE, DATA, NEWTYPE

=item AECoerceDesc DESC, NEWTYPE

The AECoerceDesc function attempts to create a new descriptor record by coercing
the specified descriptor record. AECoerce attempts the same with a Perl data string.

=cut
AEDesc
AECoerce(typeCode, data, toType)
	OSType	typeCode
	SV *		data
	OSType	toType
	CODE:
	{
		void *	dataPtr;
		STRLEN	dataSize;
		
		dataPtr = SvPV(data, dataSize);
		AEFail(AECoercePtr(typeCode, dataPtr, dataSize, toType, &RETVAL));
	}
	OUTPUT:
	RETVAL

AEDesc
AECoerceDesc(theAEDesc, toType)
	AEDesc	&theAEDesc
	OSType	toType
	CODE:
	AEFail(AECoerceDesc(&theAEDesc, toType, &RETVAL));
	OUTPUT:
	RETVAL

=item AEDisposeDesc DESC

Deallocate the memory used by a descriptor record. 

	if ( !AEDisposeDesc($desc) ) {
		# error occurred
	}

=cut
MacOSRet
AEDisposeDesc(theAEDesc)
	AEDesc	&theAEDesc

=item AEDuplicateDesc DESC

Creates a new descriptor record by copying the
descriptor record from the parameter $DESC.

	$newDesc = AEDuplicateDesc($desc);
	if ( defined $newDesc ) {
		# do something productive
	}

=cut
AEDesc
AEDuplicateDesc(theAEDesc)
	AEDesc	&theAEDesc
	CODE:
	AEFail(AEDuplicateDesc(&theAEDesc, &RETVAL));
	OUTPUT:
	RETVAL

=item AECreateList FACTOR, BOOL

The AECreateList function creates an empty descriptor list (BOOL is 0),
or AE record (BOOL is nonzero). FACTOR contains the common prefix for each
descriptor or is empty.

	$list = AECreateList("", 0);
	if ( defined $list ) {
		# do something productive
	}

=cut
AEDesc
AECreateList(factoring, isRecord)
	SV *		factoring
	Boolean	isRecord
	CODE:
	{
		void *	factoringPtr;
		STRLEN	factoredSize;
		
		factoringPtr 	= 	SvPV(factoring, factoredSize);
		AEFail(AECreateList(factoringPtr, factoredSize, isRecord, &RETVAL));
	}
	OUTPUT:
	RETVAL

=item AECountItems DESCLIST

Count the number of descriptor records in any descriptor list. The result
is C<undef> if the list is invalid.

=cut
SysRetLong
AECountItems(theAEDescList)
	AEDesc	&theAEDescList
	CODE:
	AEFail(AECountItems(&theAEDescList, &RETVAL));
	OUTPUT:
	RETVAL

=item AEPut DESCLIST, INDEX, TYPE, HANDLE

=item AEPutDesc DESCLIST, INDEX, DESC

Add a descriptor record to any descriptor list. AEPut will manufacture the 
record to add it to the list.
Return zero if an error was detected.

=cut
MacOSRet
AEPut(theAEDescList, index, typeCode, data)
	AEDesc	&theAEDescList
	long		index
	OSType	typeCode
	SV *		data
	CODE:
	{
		void *	dataPtr;
		STRLEN	dataSize;
		
		dataPtr 	= 	SvPV(data, dataSize);
		RETVAL	=	AEPutPtr(&theAEDescList, index, typeCode, dataPtr, dataSize);
	}
	OUTPUT:
	RETVAL

MacOSRet
AEPutDesc(theAEDescList, index, theAEDesc)
	AEDesc	&theAEDescList
	long		index
	AEDesc	&theAEDesc


=item AEPutKey DESCLIST, KEY, TYPE, HANDLE

=item AEPutKeyDesc DESCLIST, KEY, DESC

Add a descriptor record and a keyword to an AE record. AEPutKey will manufacture the 
record to add it to the AE record.
Return zero if an error was detected.

=cut
MacOSRet
AEPutKey(theAERecord, theAEKeyword, typeCode, data)
	AEDesc	&theAERecord
	OSType	theAEKeyword
	OSType	typeCode
	SV *		data
	CODE:
	{
		void *	dataPtr;
		STRLEN	dataSize;
		
		dataPtr		=	SvPV(data, dataSize);
		RETVAL	=	AEPutKeyPtr(&theAERecord, theAEKeyword, typeCode, dataPtr, dataSize);
	}
	OUTPUT:
	RETVAL


MacOSRet
AEPutKeyDesc(theAERecord, theAEKeyword, theAEDesc)
	AEDesc	&theAERecord
	OSType	theAEKeyword
	AEDesc	&theAEDesc

=item AEGetNthDesc DESCLIST, INDEX [, TYPE]

The AEGetNthDesc function returns a specified descriptor record from a specified
descriptor list. The result is an AEDesc object and the keyword from a keyword
specified list.

	($Desc, $Key) = AEGetNthDesc($DescList, $i);
	if ( defined $Desc ) {
		# do something productive
	}

=cut
void
AEGetNthDesc(theAEDescList, index, desiredType=typeWildCard)
	AEDesc	&theAEDescList
	long		index
	OSType	desiredType
	PPCODE:
	{
		OSType 	kw;
		AEDesc	desc;
		
		AEFail(AEGetNthDesc(&theAEDescList, index, desiredType, &kw, &desc));
		XS_XPUSH(AEDesc, desc);
		if (GIMME == G_ARRAY && kw != typeWildCard) {
			XS_XPUSH(OSType, kw);
		}
	}

=item AEGetKeyDesc DESCLIST, KEY [, TYPE]

The AEGetKeyDesc function returns a keyword-specified descriptor record from
a specified descriptor record.	The result is an AEDesc object.

=cut
AEDesc
AEGetKeyDesc(theAEDescList, theAEKeyword, desiredType=typeWildCard)
	AEDesc	&theAEDescList
	OSType	theAEKeyword
	OSType	desiredType
	CODE:
	AEFail(AEGetKeyDesc(&theAEDescList, theAEKeyword, desiredType, &RETVAL));
	OUTPUT:
	RETVAL

=item AEDeleteItem DESCLIST, INDEX

Delete a descriptor record from a descriptor list. All subsequent descriptor
records will then move up one place.

=cut
MacOSRet
AEDeleteItem(theAEDescList, index)
	AEDesc	&theAEDescList
	long		index

=item AEPutParam EVENT, KEY, TYPE, HANDLE

=item AEPutParamDesc EVENT, KEY, DESC

Add a descriptor record and a keyword to an Apple event as an Apple event
parameter. AEPutParam creates the descriptor record.

=cut
MacOSRet
AEPutParam(theAppleEvent, theAEKeyword, typeCode, data)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword
	OSType	typeCode
	SV *		data
	CODE:
	{
		void *	dataPtr;
		STRLEN	dataSize;
		
		dataPtr 	= 	SvPV(data, dataSize);
		RETVAL	=	AEPutParamPtr(&theAppleEvent, theAEKeyword, typeCode, dataPtr, dataSize);
	}
	OUTPUT:
	RETVAL

MacOSRet
AEPutParamDesc(theAppleEvent, theAEKeyword, theAEDesc)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword
	AEDesc	&theAEDesc

=item AEGetParamDesc EVENT, KEY [, TYPE]

The AEGetParamDesc function returns the descriptor
record for a specified Apple event parameter, which it attempts to coerce to the
descriptor type specified by TYPE (default is no coercion). 

=cut
AEDesc
AEGetParamDesc(theAppleEvent, theAEKeyword, desiredType=typeWildCard)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword
	OSType	desiredType
	CODE:
	AEFail(AEGetParamDesc(&theAppleEvent, theAEKeyword, desiredType, &RETVAL));
	OUTPUT:
	RETVAL

=item AEDeleteParam EVENT, KEY

Delete an Apple event parameter.
Return zero if an error was detected.

=cut
MacOSRet
AEDeleteParam(theAppleEvent, theAEKeyword)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword

=item AEGetAttributeDesc EVENT, KEY, TYPE

The AEGetAttributeDesc function returns the descriptor
record for the Apple event attribute with the specified keyword.

=cut
AEDesc
AEGetAttributeDesc(theAppleEvent, theAEKeyword, desiredType=typeWildCard)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword
	OSType	desiredType
	CODE:
	AEFail(AEGetAttributeDesc(&theAppleEvent, theAEKeyword, desiredType, &RETVAL));
	OUTPUT:
	RETVAL

=item AEPutAttribute EVENT, KEY, TYPE, HANDLE

=item AEPutAttributeDesc EVENT, KEY, DESC

The AEPutAttributeDesc function takes a descriptor record and a keyword and adds
them to an Apple event as an attribute.
AEPutAttribute creates the record from TYPE and HANDLE. 
Return zero if an error was detected.

=cut
MacOSRet
AEPutAttribute(theAppleEvent, theAEKeyword, typeCode, data)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword
	OSType	typeCode
	SV *		data
	CODE:
	{
		void *	dataPtr;
		STRLEN	dataSize;
		
		dataPtr 	= 	SvPV(data, dataSize);
		RETVAL	=	AEPutAttributePtr(&theAppleEvent, theAEKeyword, typeCode, dataPtr, dataSize);
	}
	OUTPUT:
	RETVAL

MacOSRet
AEPutAttributeDesc(theAppleEvent, theAEKeyword, theAEDesc)
	AEDesc	&theAppleEvent
	OSType	theAEKeyword
	AEDesc	&theAEDesc

=item AECreateAppleEvent CLASS, EVENTID, DESC [, RETURNID [, TRANSACTIONID ] ]

The AECreateAppleEvent function creates an Apple event and returns it.
TRANSACTIONID defaults to zero.
RETURNID defaults to kAutoGenerateReturnID.

=cut
AEDesc
AECreateAppleEvent(theAEEventClass, theAEEventID, target, returnID=kAutoGenerateReturnID, transactionID=0)
	OSType	theAEEventClass
	OSType	theAEEventID
	AEDesc	&target
	short		returnID
	long		transactionID
	CODE:
	if (gPAECreate)
		AEFail(
			CallOSACreateAppleEventProc(gPAECreate,
				theAEEventClass, theAEEventID, 
				&target, returnID, transactionID, &RETVAL, 
				gPAECreateRefCon));
	else
		AEFail(
			AECreateAppleEvent(
				theAEEventClass, theAEEventID, 
				&target, returnID, transactionID, &RETVAL));
	OUTPUT:
	RETVAL

=item AESend EVENT, SENDMODE [, SENDPRIORITY [, TIMEOUT ] ]

Send the Apple Event EVENT. 
TIMEOUT defaults to kAEDefaultTimeout.
SENDPRIORITY defaults to kAENormalPriority.
Returns the reply if SENDMODE was kAEWaitReply.

=cut
AEDesc
AESend(theAppleEvent, sendMode, sendPriority=kAENormalPriority, timeout=kAEDefaultTimeout)
	AEDesc	&theAppleEvent
	long		sendMode
	short		sendPriority
	long		timeout
	CODE:
	if (gPAESend) 
		AEFail(
			CallOSASendProc(gPAESend,
				&theAppleEvent, &RETVAL, 
				sendMode, sendPriority, timeout, (AEIdleUPP) &uSubLaunchIdle, nil,
				gPAESendRefCon));
	else
		AEFail(
			AESend(
				&theAppleEvent, &RETVAL, 
				sendMode, sendPriority, timeout, (AEIdleUPP) &uSubLaunchIdle, nil));
	OUTPUT:
	RETVAL

=item AEResetTimer REPLY

The Apple Event Manager for the server
application uses the default reply to send a Reset Timer event to the client
application; the Apple Event Manager for the client application's computer
intercepts this Apple event and resets the client application's timer for the
Apple event.

=cut
MacOSRet
AEResetTimer(reply)
	AEDesc	&reply

=item AESuspendTheCurrentEvent EVENT

After a server application makes a successful call to the
AESuspendTheCurrentEvent function, it is no longer required to return a result or
a reply for the Apple event that was being handled. The result is zero if no error
was detected.

=cut
MacOSRet
AESuspendTheCurrentEvent(theAppleEvent)
	AEDesc	&theAppleEvent

=item AEResumeTheCurrentEvent EVENT [, FLAGS, REFCON]

The Apple Event
Manager resumes handling the specified Apple event using the handler specified in
the FLAGS parameter, if any. If FLAGS and REFCON are missing, 
AEResumeTheCurrentEvent simply informs the Apple Event Manager that
the specified event has been handled.

=cut
AEDesc
AEResumeTheCurrentEvent(theAppleEvent, flags=kAENoDispatch, handlerRefcon=0)
	AEDesc	&theAppleEvent
	long   	 flags
	long	 handlerRefcon
	CODE:
	AEFail(
		AEResumeTheCurrentEvent(
			&theAppleEvent, &RETVAL, (AEEventHandlerUPP) flags, handlerRefcon));
	OUTPUT:
	RETVAL

=item AEGetTheCurrentEvent

Get the Apple event that is currently being handled. 

=cut
AEDesc
AEGetTheCurrentEvent()
	CODE:
	AEFail(AEGetTheCurrentEvent(&RETVAL));
	OUTPUT:
	RETVAL

=item AESetTheCurrentEvent EVENT

There is usually no reason for your application to use the AESetTheCurrentEvent
function.

=cut
MacOSRet
AESetTheCurrentEvent(theAppleEvent)
	AEDesc	&theAppleEvent

=item AEGetInteractionAllowed

The AEGetInteractionAllowed function returns a value
that indicates the user interaction preferences for responding to an Apple event.
The result is C<undef> if an error was detected.

=cut
SysRet
AEGetInteractionAllowed()
	CODE:
	{
		char	level;
		
		AEFail(AEGetInteractionAllowed((AEInteractAllowed *)&level));
		RETVAL = level;
	}
	OUTPUT:
	RETVAL

=item AESetInteractionAllowed LEVEL

The AESetInteractionAllowed function sets the user interaction level for a server
application's response to an Apple event. The result is zero if no error was detected.

=cut
MacOSRet
AESetInteractionAllowed(level)
	char	level
	CODE:
	RETVAL = AESetInteractionAllowed((AEInteractAllowed)level);
	OUTPUT:
	RETVAL

=item AEInstallEventHandler CLASS, EVENTID, HANDLER, HANDLERREFCON [, SYSTEM]

The AEInstallEventHandler function creates an entry in the Apple event dispatch
table. You must supply parameters that specify the event class, the event ID, the
address of the handler that handles Apple events of the specified event class and
event ID, and whether the handler is to be added to the system Apple event
dispatch table or your application's Apple event dispatch table. You can also
specify a reference constant that the Apple Event Manager passes to your handler
whenever your handler processes an Apple event.

	if (!AEInstallEventHandler(kCoreEventClass, kAEOpenDocuments, 'OpenDocument', 0) ) {
		# an error occurred.
	}

A much more uniform (and Perl-ish) method is available using the hash arrays
%AppleEvent and %SysAppleEvent to bind handlers to event types.

	$AppleEvent{kCoreEventClass, kAEOpenDocuments} = 'OpenDocument';
	...
	delete $AppleEvent{kCoreEventClass, kAEOpenDocuments};

=cut
MacOSRet
AEInstallEventHandler(theAEEventClass, theAEEventID, handler, handlerRefcon, isSysHandler=0)
	OSType	theAEEventClass
	OSType	theAEEventID
	SV *		handler
	SV *		handlerRefcon
	Boolean	isSysHandler
	CODE:
	{
		RETVAL = PAEInstallEventHandler(theAEEventClass, theAEEventID, handler, handlerRefcon, isSysHandler);
	}
	OUTPUT:
	RETVAL

=item AERemoveEventHandler CLASS, EVENTID [, SYSTEM]

The AERemoveEventHandler function removes the Apple event dispatch table entry
you specify in the parameters CLASS, EVENTID, and SYSTEM. 

=cut
MacOSRet
AERemoveEventHandler(theAEEventClass, theAEEventID, isSysHandler=0)
	OSType	theAEEventClass
	OSType	theAEEventID
	Boolean	isSysHandler
	CODE:
	RETVAL = PAERemoveEventHandler(theAEEventClass, theAEEventID, isSysHandler);
	OUTPUT:
	RETVAL

=item AEGetEventHandler CLASS, EVENTID [, SYSTEM]

The AEGetEventHandler function returns the handler and handlerrefcon for
the specified class and event. 

	($proc, $refcon) = AEGetEventHandler("aevt", "oapp");

=cut
void
AEGetEventHandler(theAEEventClass, theAEEventID, isSysHandler=0)
	OSType	theAEEventClass
	OSType	theAEEventID
	Boolean	isSysHandler
	PPCODE:
	{
		SV * handler = sv_newmortal();
		SV * refCon  = sv_newmortal();
		
		AEFail(
			PAEGetEventHandler(
				theAEEventClass, theAEEventID, handler, refCon, isSysHandler));
		XPUSHs(handler);
		if (GIMME == G_ARRAY) {
			XPUSHs(refCon);
		}
	}

=item AEManagerInfo KEY

Obtain information about the version of the Apple Event Manager currently
available or the number of processes that are currently recording Apple events. 
The result is C<undef> if an error occurred.

=back

=cut
SysRetLong
AEManagerInfo(keyWord)
	OSType	keyWord
	CODE:
	AEFail(AEManagerInfo(keyWord, &RETVAL));
	OUTPUT:
	RETVAL


=head2 AEGizmos Build/Print

The Apple Event Gizmos were developed by Jens Peter Alfke at Apple as a vastly
speeded up AE library. Consult the AEGizmo documentation for details of usage
of the library. The Build/Print facility uses a formatting convention similar
to scanf/printf to put things together.

=item AEBuild FORMAT, PARM, ...

Build an AppleEvent descriptor using the format per the Gizmo documentation
and return it.

=cut
AEDesc
AEBuild(format, ...)
	char *	format
	CODE:
	{
		int	item = 1;
		char *formscan = format;
		
		PAEClearArgs();
		for (;item<items;++item) 
			if (!PAEDoNextParam(&formscan, ST(item)))
				croak("Too many arguments to AEBuild()");
			
		if (PAENextParam(&formscan))
			croak("Not enough arguments to AEBuild()");
		AEFail(vAEBuild(&RETVAL, format, gPAEArgs));
	}
	OUTPUT:
	RETVAL

=item AEBuildParameters EVENT, FORMAT, PARM, ...

Build parameters for an existing AppleEvent EVENT.

	if (!AEBuildParameters($reply, $format, $parm1, $parm2) ) {
		# an error occurred
	}

=cut
MacOSRet
AEBuildParameters(event, format, ...)
	AEDesc	&event
	char *	format
	CODE:
	{
		int	item = 2;
		char *formscan = format;
		
		PAEClearArgs();
		for (;item<items;++item) 
			if (!PAEDoNextParam(&formscan, ST(item)))
				croak("Too many arguments to AEBuildParameters()");
			
		if (PAENextParam(&formscan))
			croak("Not enough arguments to AEBuildParameters()");
		RETVAL = vAEBuildParameters(&event, format, gPAEArgs);
	}
	OUTPUT:
	RETVAL

=item AEBuildAppleEvent CLASS, ID, ADDRESSTYPE, ADDRESS, RETURNID, TRANSACTIONID, FORMAT, PARMS, ...

Construct an AppleEvent from the format and parameters and return it.

=cut
AEDesc
AEBuildAppleEvent(theClass, theID, addressType, address, returnID, transactionID, paramsFmt, ... )
	OSType	theClass
	OSType	theID
	OSType	addressType
	SV *		address
	short		returnID
	long		transactionID
	char *	paramsFmt
	CODE:
	{
		int		item = 7;
		char *	formscan = paramsFmt;
		char *	addressPtr;
		STRLEN	addressLen;
		AEDesc	targetDesc;
		
		PAEClearArgs();
		addressPtr = SvPV(address, addressLen);
		for (;item<items;++item) 
			if (!PAEDoNextParam(&formscan, ST(item)))
				croak("Too many arguments to AEBuildAppleEvent()");
			
		if (PAENextParam(&formscan))
			croak("Not enough arguments to AEBuildAppleEvent()");
		AEFail(AECreateDesc(addressType, addressPtr, addressLen, &targetDesc));
		if (gPAECreate)
			AEFail(
				CallOSACreateAppleEventProc(gPAECreate,
					theClass, theID, 
					&targetDesc, returnID, transactionID, &RETVAL, 
					gPAECreateRefCon));
		else
			AEFail(
				AECreateAppleEvent(
					theClass, theID, 
					&targetDesc, returnID, transactionID, &RETVAL));
		AEDisposeDesc(&targetDesc);
		AEFail(vAEBuildParameters(&RETVAL, paramsFmt, gPAEArgs));
	}
	OUTPUT:
	RETVAL

=item AEPrint DESC

Return a string version of the descriptor record. The result is C<undef>
if an error occurred.

=cut
SV *
AEPrint(desc)
	AEDesc	&desc
	CODE:
	{
		long	length;
		
		AEFail(AEPrintSize(&desc, &length));
		RETVAL = newSVpv("", length);
		AEPrint(&desc, SvPVX(RETVAL), length);
		SvCUR(RETVAL) = length-1;
	}
	OUTPUT:
	RETVAL

=head2 AEGizmos Subdescriptors

The Apple Event Gizmos subdescriptor approach uses a dictionary method for
extracting and constructing descriptors.  Parsing an Apple Event using the
dictionary is very time efficient, and translating to and from the dictionary
tables is quick and efficient.

=item AEDescToSubDesc DESC

Translate DESC to a subdescriptor (dictionary entry). 
Return the subdescriptor.

=cut
AESubDesc
AEDescToSubDesc(desc)
	AEDesc	&desc
	CODE:
	AEDescToSubDesc(&desc, &RETVAL);
	OUTPUT:
	RETVAL

=item AEGetSubDescType SUBDESC

Return the type of the subdescriptor.

=cut
OSType
AEGetSubDescType(subdesc)
	AESubDesc	&subdesc

=item AEGetSubDescBasicType SUBDESC

Return the basic type of the subdescriptor. Differs from AEGetSubDescType
in handling of coerced records.

=cut
OSType
AEGetSubDescBasicType(subdesc)
	AESubDesc	&subdesc

=item AESubDescIsListOrRecord SUBDESC

Return nonzero if the subdescriptor is a list or record.

=cut
Boolean
AESubDescIsListOrRecord(subdesc)
	AESubDesc	&subdesc

=item AEGetSubDescData SUBDESC

Returns the data of the subdescriptor. 

=cut
SV *
AEGetSubDescData(subdesc)
	AESubDesc	&subdesc
	CODE:
	{
		void *data;
		long	length;
		
		data		= AEGetSubDescData(&subdesc, &length);
		RETVAL	= newSVpv(data, length);
	}
	OUTPUT:
	RETVAL

=item AESubDescToDesc SUBDESC, DESIREDTYPE

Translate the subdescriptor back to a descriptor of the desired type.

=cut
AEDesc
AESubDescToDesc(subdesc, desiredType=typeWildCard)
	AESubDesc	&subdesc
	OSType		desiredType
	CODE:
	AEFail(AESubDescToDesc(&subdesc, desiredType, &RETVAL));
	OUTPUT:
	RETVAL

=item AECountSubDescItems SUBDESC

Counts the number of subdescriptor items.

=cut
long
AECountSubDescItems(subdesc)
	AESubDesc	&subdesc
	CODE:
	{
		RETVAL = AECountSubDescItems(&subdesc);
		if (RETVAL < 0)
			AEFail((OSErr) RETVAL);
	}
	OUTPUT:
	RETVAL	

=item AEGetNthSubDesc SUBDESC,INDEX

Returns the item INDEX of the subdescriptor and its type if the subdescriptor
represented a record and not a list.

=cut
void
AEGetNthSubDesc(subdesc,index)
	AESubDesc	&subdesc
	long			index
	PPCODE:
	{
		OSType		kw;
		AESubDesc	sub;
		
		AEFail(AEGetNthSubDesc(&subdesc, index, &kw, &sub));
		XS_XPUSH(AESubDesc, sub);
		if (GIMME == G_ARRAY && kw != typeWildCard) {
			XS_XPUSH(OSType, kw);
		}
	}

=item AEGetKeySubDesc SUBDESC,KW

Returns the keyword indexed item from the subdescriptor.

=back

=cut
AESubDesc
AEGetKeySubDesc(subdesc,kw)
	AESubDesc	&subdesc
	OSType		kw
	CODE:
	AEFail(AEGetKeySubDesc(&subdesc, kw, &RETVAL));
	OUTPUT:
	RETVAL

MODULE = Mac::AppleEvents	PACKAGE = AEStream 

=head2 AEStream

The Apple Event Gizmos streams approach uses a streaming model for building 
a sequence of descriptors.

=item new AEStream

=item AEStream::Open 

Return a new AEStream.

=cut
AEStream
Open()
	CODE:
	AEFail(AEStream_Open(&RETVAL));
	OUTPUT:
	RETVAL

=item new AEStream(CLASS, ID, ADDRESSTYPE, ADDRESS [, RETURNID [, TRANSACTIONID ] ])

=item AEStream::CreateEvent CLASS, ID, ADDRESSTYPE, ADDRESS, RETURNID, TRANSACTIONID

Create an AEStream attached to a new AppleEvent.

=cut
AEStream
CreateEvent(theClass, theID, addressType, address, returnID=kAutoGenerateReturnID, transactionID=0)
	OSType	theClass
	OSType	theID
	OSType	addressType
	SV *		address
	short		returnID
	long		transactionID
	CODE:
	{
		char *		addressPtr;
		STRLEN		addressLen;
		AEDesc		targetDesc;
		AppleEvent	event;
		
		addressPtr = SvPV(address, addressLen);
		AEFail(AECreateDesc(addressType, addressPtr, addressLen, &targetDesc));
		if (gPAECreate)
			AEFail(
				CallOSACreateAppleEventProc(gPAECreate,
					theClass, theID, 
					&targetDesc, returnID, transactionID, &event, 
					gPAECreateRefCon));
		else
			AEFail(
				AECreateAppleEvent(
					theClass, theID, 
					&targetDesc, returnID, transactionID, &event));
		AEDisposeDesc(&targetDesc);
		AEFail(AEStream_OpenEvent(&RETVAL, &event));
	}
	OUTPUT:
	RETVAL

=item new AEStream(EVENT)

=item AEStream::OpenEvent EVENT

Opens the stream on the $EVENT.
Return C<undef> if an error was detected.

=cut
AEStream
OpenEvent(theEvent)
	AEDesc	&theEvent
	CODE:
	AEFail(AEStream_OpenEvent(&RETVAL, &theEvent));
	OUTPUT:
	RETVAL

=item Close

Return the descriptor corresponding to the stream, and close it out.

	$stream->Close;

=cut
AEDesc
Close(stream)
	AEStream		&stream
	CODE:
	AEFail(AEStream_Close(&stream, &RETVAL));
	OUTPUT:
	stream
	RETVAL

=item Abort STREAM

Abort the streaming process, and close it out.

	$stream->Abort;

=cut
MacOSRet
Abort(stream)
	AEStream		&stream
	CODE:
	RETVAL = AEStream_Close(&stream, nil);
	OUTPUT:
	stream
	RETVAL

=item OpenDesc TYPE

Start building a descriptor of the given type.
Return zero if an error was detected.

	if ( $stream->OpenDesc($type) ) {
		# Long messy calculation that demonstrates the usefullness of this code
		if ( $stream->WriteData($calculatedData) 
		 &&  $stream->CloseDesc()
		){
			# then, my work here is done
		}
	}

=cut
MacOSRet
OpenDesc(stream, type)
	AEStream	&stream
	OSType	type
	CODE:
	RETVAL = AEStream_OpenDesc(&stream, type);
	OUTPUT:
	stream

=item WriteData DATA

Add data to the descriptor.

=cut
MacOSRet
WriteData(stream, data)
	AEStream	&stream
	SV *		data
	CODE:
	{
		void *	ptr;
		STRLEN	length;
		
		ptr = SvPV(data, length);
		RETVAL = AEStream_WriteData(&stream, ptr, length);
	}
	OUTPUT:
	stream
	RETVAL

=item CloseDesc

Finish up the descriptor.

=cut
MacOSRet
CloseDesc(stream)
	AEStream	&stream
	CODE:
	RETVAL = AEStream_CloseDesc(&stream);
	OUTPUT:
	stream

=item WriteDesc TYPE, DATA

Add the arbitrary data with the given type as a descriptor to the stream.

=cut
MacOSRet
WriteDesc(stream, type, data)
	AEStream	&stream
	OSType	type
	SV *		data
	CODE:
	{
		void *	ptr;
		STRLEN	length;
		
		ptr = SvPV(data, length);
		RETVAL = AEStream_WriteDesc(&stream, type, ptr, length);
	}
	OUTPUT:
	stream
	RETVAL

=item WriteAEDesc STREAM, AEDESC

Add an Apple Event descriptor to the stream.

=cut
MacOSRet
WriteAEDesc(stream, desc)
	AEStream	&stream
	AEDesc	&desc
	CODE:
	RETVAL = AEStream_WriteAEDesc(&stream, &desc);
	OUTPUT:
	stream

=item OpenList

Start building a list of AppleEvent descriptors in the stream.

=cut
MacOSRet
OpenList(stream)
	AEStream	&stream
	CODE:
	RETVAL = AEStream_OpenList(&stream);
	OUTPUT:
	stream

=item CloseList STREAM

Return zero if an error was detected.

	if ( $stream->OpenList() ) {
		for $desc (@descList) {
			croak unless $stream->WriteAEDesc($desc);
		}
		die unless $stream->CloseList();
	}

=cut
MacOSRet
CloseList(stream)
	AEStream	&stream
	CODE:
	RETVAL = AEStream_CloseList(&stream);
	OUTPUT:
	stream

=item OpenRecord [TYPE]

Start the process of building a record, to be coerced to the given type.
=cut
MacOSRet
OpenRecord(stream, type=typeAERecord)
	AEStream	&stream
	OSType	type
	CODE:
	RETVAL = AEStream_OpenRecord(&stream, type);
	OUTPUT:
	stream

=item SetRecordType TYPE

Change the record type.

=cut
MacOSRet
SetRecordType(stream, type)
	AEStream	&stream
	OSType	type
	CODE:
	RETVAL = AEStream_SetRecordType(&stream, type);
	OUTPUT:
	stream

=item CloseRecord STREAM

Close the record currently under construction.

	if ( $stream->OpenRecord(typeAErecord) ) {
		for $kdesc (@descList) {
			die unless $stream->WriteKey($kdesc->key) and 
					$stream->WriteAEDesc($kdesc->desc);
		}
		die unless $stream->CloseRecord();
	}

=cut
MacOSRet
CloseRecord(stream)
	AEStream	&stream
	CODE:
	RETVAL = AEStream_CloseRecord(&stream);
	OUTPUT:
	stream

=item WriteKeyDesc KEY, TYPE, DATA

Add the keyword descriptor to the stream.

=cut
MacOSRet
WriteKeyDesc(stream, key, type, data)
	AEStream	&stream
	OSType	key
	OSType	type
	SV *		data
	CODE:
	{
		void *	ptr;
		STRLEN	length;
		
		ptr = SvPV(data, length);
		RETVAL = AEStream_WriteKeyDesc(&stream, key, type, ptr, length);
	}
	OUTPUT:
	stream
	RETVAL

=item OpenKeyDesc KEY, TYPE

Open a descriptor with the given type and key.
Use CloseDesc() to close it.

=cut
MacOSRet
OpenKeyDesc(stream, key, type)
	AEStream	&stream
	OSType	key
	OSType	type
	CODE:
	RETVAL = AEStream_OpenKeyDesc(&stream, key, type);
	OUTPUT:
	stream

=item WriteKey  KEY

Add the keyword to the immediately following descriptor.
Return zero if an error was detected.

=cut
MacOSRet
WriteKey(stream, key)
	AEStream	&stream
	OSType	key
	CODE:
	RETVAL = AEStream_WriteKey(&stream, key);
	OUTPUT:
	stream

=item OptionalParam KEY

Adds the keyword to the list of optional attributes.

=back

=cut
MacOSRet
OptionalParam(stream, key)
	AEStream	&stream
	OSType	key
	CODE:
	RETVAL = AEStream_OptionalParam(&stream, key);
	OUTPUT:
	stream
