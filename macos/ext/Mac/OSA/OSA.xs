/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/OSA/OSA.xs,v 1.2 2000/09/09 22:18:28 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: OSA.xs,v $
 * Revision 1.2  2000/09/09 22:18:28  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:32  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:53:06  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:50:21  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <OSA.h>
#include <OSAGeneric.h>

MODULE = Mac::OSA	PACKAGE = Mac::OSA

=head2 Functions

=over 4

=item OSALoad SCRIPTINGCOMPONENT, SCRIPTDATA, MODEFLAGS

The OSALoad function loads script data and returns a script ID. The generic
scripting component uses the descriptor record in the SCRIPTDATA parameter to
determine which scripting component should load the script. If the descriptor
record is of type typeOSAGenericStorage, the generic scripting component uses the
trailer at the end of the SCRIPTDATA to identify the scripting component. If the
descriptor record's type is the subtype value for another scripting component,
the generic scripting component uses the descriptor type to identify the
scripting component.
Return C<undef> if an error was detected.

=cut
OSAID
OSALoad(scriptingComponent, scriptData, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				scriptData
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSALoad(scriptingComponent, &scriptData, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAStore SCRIPTINGCOMPONENT, SCRIPTID, DESIREDTYPE, MODEFLAGS

The OSAStore function returns script data in a descriptor record so that the data
can later be saved in a resource or written to the data fork of a document. You
can then reload the data for the descriptor record as a compiled script (although
possibly with a different script ID) by passing the descriptor record to OSALoad().
Return C<undef> if an error was detected.

=cut
AEDesc
OSAStore(scriptingComponent, scriptID, desiredType, modeFlags)
	ComponentInstance scriptingComponent
	OSAID 				scriptID
	OSType	 			desiredType 
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSAStore(scriptingComponent, scriptID, desiredType, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAExecute SCRIPTINGCOMPONENT, COMPILEDSCRIPTID, CONTEXTID, MODEFLAGS

The OSAExecute function executes the compiled script identified by the
COMPILEDSCRIPTID parameter, using the script context identified by the CONTEXTID
parameter to maintain state information, such as the binding of variables, for
the compiled script. After successfully executing a script, OSAExecute returns
the script ID for a resulting script value, or, if execution does not result in a
value, C<undef>.

=cut
OSAID
OSAExecute(scriptingComponent, compiledScriptID, contextID, modeFlags)
	ComponentInstance scriptingComponent
	OSAID 				compiledScriptID
	OSAID 				contextID
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSAExecute(scriptingComponent, compiledScriptID, contextID, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSADisplay SCRIPTINGCOMPONENT, SCRIPTVALUEID, DESIREDTYPE, MODEFLAGS

The OSADisplay function coerces the script value identified by SCRIPTVALUEID to a
descriptor record of the text type specified by the DESIREDTYPE parameter, if
possible. Valid types include all the standard text descriptor types defined in
the Apple Event Registry: Standard Suites, plus any special types supported by
the scripting component.
Return C<undef> if an error was detected.

=cut
AEDesc
OSADisplay(scriptingComponent, scriptValueID, desiredType, modeFlags)
	ComponentInstance scriptingComponent
	OSAID 				scriptValueID
	OSType 				desiredType
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSADisplay(scriptingComponent, scriptValueID, desiredType, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAScriptError SCRIPTINGCOMPONENT, SELECTOR, DESIREDTYPE

Whenever the OSAExecute() function returns the error errOSAScriptError, you can use
the OSAScriptError function to get more specific information about the error from
the scripting component that encountered it. (This information remains available
only until the next call to the same scripting component.) The information
returned by OSAScriptError depends on the value passed in the SELECTOR parameter,
which also determines the descriptor type you should specify in the DESIREDTYPE
parameter. 

Return C<undef> if an error was detected.

=cut
AEDesc
OSAScriptError(scriptingComponent, selector, desiredType)
	ComponentInstance scriptingComponent
	OSType 				selector
	OSType				desiredType
	CODE:
	if (gMacPerl_OSErr = (short) OSAScriptError(scriptingComponent, selector, desiredType, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSADispose SCRIPTINGCOMPONENT, SCRIPTID

The OSADispose function releases the memory assigned to the script data identified
by the SCRIPTID parameter. The SCRIPTID passed to the OSADispose function is no
longer valid if the function returns successfully. A scripting component can then
reuse that SCRIPTID for other script data. 
Return zero if no error was detected.

=cut
OSAError
OSADispose(scriptingComponent, scriptID)
	ComponentInstance scriptingComponent
	OSAID 				scriptID

=item OSASetScriptInfo SCRIPTINGCOMPONENT, SCRIPTID, SELECTOR, VALUE

The OSASetScriptInfo function sets script information according to the value you
pass in the selector parameter. If you use the kOSAScriptIsModified constant,
OSASetScriptInfo sets a value that indicates how many times the script data has
been modified since it was created or passed to OSALoad. Some scripting
components may provide additional constants.
Return zero if no error was detected.

=cut
OSAError
OSASetScriptInfo(scriptingComponent, scriptID, selector, value)
	ComponentInstance scriptingComponent
	OSAID 				scriptID
	OSType				selector
	long 					value

=item OSAGetScriptInfo SCRIPTINGCOMPONENT, SCRIPTID, SELECTOR

The OSAGetScriptInfo function returns various results according to the value you
pass in the SELECTOR parameter.
Returns an integer value which may need to be recast as the desired type.

=cut
long
OSAGetScriptInfo(scriptingComponent, scriptID, selector)
	ComponentInstance scriptingComponent
	OSAID 				scriptID
	OSType 				selector
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetScriptInfo(scriptingComponent, scriptID, selector, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAScriptingComponentName SCRIPTINGCOMPONENT

The OSAScriptingComponentName function returns a descriptor record that you can
coerce to a text descriptor type such as typeChar. This can be useful if you want
to display the name of the scripting language in which the user should write a
new script.
Return C<undef> if an error was detected.

=cut
AEDesc
OSAScriptingComponentName(scriptingComponent)
	ComponentInstance scriptingComponent
	CODE:
	if (gMacPerl_OSErr = (short) OSAScriptingComponentName(scriptingComponent, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSACompile SCRIPTINGCOMPONENT, SOURCEDATA, MODEFLAGS, [PREVIOUSSCRIPTID]

You can pass a descriptor record containing source data suitable for a specific
scripting component (usually text) to the OSACompile function to obtain a script
ID for the equivalent compiled script or script context. To compile the source
data as a script context for use with OSAExecuteEvent() or OSADoEvent(), you must set
the kOSACompileIntoContext flag, and the source data should include appropriate
handlers.
Return zero if no error was detected.

=cut
OSAID
OSACompile(scriptingComponent, sourceData, modeFlags, previousScriptID = 0)
	ComponentInstance scriptingComponent
	AEDesc				sourceData
	long 					modeFlags
	OSAID					previousScriptID
	CODE:
	RETVAL = previousScriptID;
	if (gMacPerl_OSErr = (short) OSACompile(scriptingComponent, &sourceData, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSACopyID SCRIPTINGCOMPONENT, FROMID, [TOID]

The OSACopyID function replaces the script data identified by the script ID in
the TOID parameter with the script data identified by the script ID in the FROMID
parameter.
Return C<undef> if an error was detected.

=cut
OSAID
OSACopyID(scriptingComponent, fromID, toID = 0)
	ComponentInstance scriptingComponent
	OSAID 				fromID
	OSAID					toID	
	CODE:
	RETVAL = toID;
	if (gMacPerl_OSErr = (short) OSACopyID(scriptingComponent, fromID, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAGetSource SCRIPTINGCOMPONENT, SCRIPTID, [DESIREDTYPE]

The OSAGetSource function decompiles the script data identified by the specified
script ID and returns a descriptor record containing the equivalent source data.
Return C<undef> if an error was detected.

=cut
AEDesc
OSAGetSource(scriptingComponent, scriptID, desiredType = 'TEXT')
	ComponentInstance scriptingComponent
	OSAID 				scriptID
	OSType				desiredType
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetSource(scriptingComponent, scriptID, desiredType, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSACoerceFromDesc SCRIPTINGCOMPONENT, SCRIPTDATA, MODEFLAGS

The OSACoerceFromDesc function coerces the descriptor record in the SCRIPTDATA
parameter to the equivalent script value and returns a script ID for that value. 
Return C<undef> if an error was detected.

=cut
OSAID
OSACoerceFromDesc(scriptingComponent, scriptData, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				scriptData
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSACoerceFromDesc(scriptingComponent, &scriptData, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSACoerceToDesc SCRIPTINGCOMPONENT, SCRIPTID, DESIREDTYPE, MODEFLAGS

The OSACoerceToDesc function coerces the script value identified by SCRIPTID
to a descriptor record of the type specified by the DESIREDTYPE parameter, if
possible.
Return C<undef> if an error was detected.

=cut
AEDesc
OSACoerceToDesc(scriptingComponent, scriptID, desiredType, modeFlags)
	ComponentInstance scriptingComponent
	OSAID 				scriptID
	OSType 				desiredType
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSACoerceToDesc(scriptingComponent, scriptID, desiredType, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSASetDefaultTarget SCRIPTINGCOMPONENT, TARGET

The OSASetDefaultTarget function establishes the default target application for
Apple event sending and the default application from which the scripting
component should obtain terminology information. For example, AppleScript
statements that refer to the default application do not need to be enclosed in
C<tell/end tell> statements. 
Return zero if no error was detected.

=cut
OSAError
OSASetDefaultTarget(scriptingComponent, target)
	ComponentInstance scriptingComponent
	AEDesc				&target

=item OSAStartRecording SCRIPTINGCOMPONENT, [COMPILEDSCRIPTTOMODIFYID]

The OSAStartRecording routine turns on Apple event recording. Subsequent Apple
events are recorded (that is, appended to any existing statements) in the
compiled script specified by the COMPILEDSCRIPTTOMODIFYID parameter.
Return C<undef> if an error was detected.

=cut
OSAID
OSAStartRecording(scriptingComponent, compiledScriptToModifyID = 0)
	ComponentInstance scriptingComponent
	OSAID					compiledScriptToModifyID
	CODE:
	RETVAL = compiledScriptToModifyID;
	if (gMacPerl_OSErr = (short) OSAStartRecording(scriptingComponent, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAStopRecording SCRIPTINGCOMPONENT, COMPILEDSCRIPTID

The OSAStopRecording function turns off recording. If the script is not currently
open in a script editor window, the COMPILEDSCRIPTTOMODIFYID parameter supplied
to OSAStartRecording() is then augmented to contain the newly recorded statements.
If the script is currently open in a script editor window, the script data that
corresponds to the compiledScriptToModifyID parameter supplied to
OSAStartRecording() is updated continuously until the client application calls
OSAStopRecording. 
Return zero if no error was detected.

=cut
OSAError
OSAStopRecording(scriptingComponent, compiledScriptID)
	ComponentInstance scriptingComponent
	OSAID					compiledScriptID

=item OSALoadExecute SCRIPTINGCOMPONENT, SCRIPTDATA, CONTEXTID, MODEFLAGS

The OSALoadExecute function loads script data and executes the resulting compiled
script, using the script context identified by the CONTEXTID parameter to
maintain state information such as the binding of variables. After successfully
executing the script, OSALoadExecute disposes of the compiled script and returns
either the script ID for the resulting script value or, if execution does not
result in a value, the constant kOSANullScript. 
Return C<undef> if an error was detected.

=cut
OSAID
OSALoadExecute(scriptingComponent, scriptData, contextID, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				scriptData
	OSAID 				contextID
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSALoadExecute(scriptingComponent, &scriptData, contextID, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSACompileExecute SCRIPTINGCOMPONENT, SOURCEDATA, CONTEXTID, MODEFLAGS

The OSACompileExecute function compiles source data and executes the resulting
compiled script, using the script context identified by the CONTEXTID parameter
to maintain state information such as the binding of variables. After
successfully executing the script, OSACompileExecute disposes of the compiled
script and returns either the script ID for the resulting script value or, if
execution does not result in a value, the constant kOSANullScript.
Return C<undef> if an error was detected.

=cut
OSAID
OSACompileExecute(scriptingComponent, sourceData, contextID, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				sourceData
	OSAID 				contextID
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSACompileExecute(scriptingComponent, &sourceData, contextID, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSADoScript SCRIPTINGCOMPONENT, SOURCEDATA, CONTEXTID, DESIREDTYPE, MODEFLAGS

Calling the OSADoScript function is equivalent to calling OSACompile() followed by
OSAExecute() and OSADisplay(). After compiling the source data, executing the
compiled script using the script context identified by the CONTEXTID parameter,
and returning the text equivalent of the resulting script value, OSADoScript
disposes of both the compiled script and the resulting script value.
Return C<undef> if an error was detected.

=cut
AEDesc
OSADoScript(scriptingComponent, sourceData, contextID, desiredType, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				sourceData
	OSAID 				contextID
	OSType   			desiredType
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSADoScript(scriptingComponent, &sourceData, contextID, desiredType, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSASetCurrentDialect SCRIPTINGCOMPONENT, DIALECTCODE

Set the current dialect for a scripting component.
Return zero if no error was detected.

=cut
OSAError
OSASetCurrentDialect(scriptingComponent, dialectCode)
	ComponentInstance scriptingComponent
	short 				dialectCode

=item OSAGetCurrentDialect SCRIPTINGCOMPONENT

Get the dialect code for the dialect currently being used by a scripting
component.
Returns the code for the current dialect of the specified scripting component.

=cut
short
OSAGetCurrentDialect(scriptingComponent)
	ComponentInstance scriptingComponent	
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetCurrentDialect(scriptingComponent, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAAvailableDialects SCRIPTINGCOMPONENT

Obtain a descriptor list containing information about each of the currently
available dialects for a scripting component. 
Return C<undef> if an error was detected.

=cut
AEDesc
OSAAvailableDialects(scriptingComponent)
	ComponentInstance scriptingComponent	
	CODE:
	if (gMacPerl_OSErr = (short) OSAAvailableDialects(scriptingComponent, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAGetDialectInfo SCRIPTINGCOMPONENT, DIALECTCODE, SELECTOR

After you obtain a list of dialect codes by calling OSAAvailableDialectCodeList(),
you can pass any of those codes to OSAGetDialectInfo to get information about the
corresponding dialect. The descriptor type of the descriptor record returned by
OSAGetDialectInfo depends on the constant specified in the SELECTOR parameter.
Return C<undef> if an error was detected.

=cut
AEDesc
OSAGetDialectInfo(scriptingComponent, dialectCode, selector)
	ComponentInstance scriptingComponent
	short 				dialectCode
	OSType 				selector
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetDialectInfo(scriptingComponent, dialectCode, selector, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAAvailableDialectCodeList SCRIPTINGCOMPONENT

Obtain a descriptor list containing dialect codes for each of a scripting
component's currently available dialects. 
Return C<undef> if an error was detected.

=cut
AEDesc
OSAAvailableDialectCodeList(scriptingComponent)
	ComponentInstance scriptingComponent	
	CODE:
	if (gMacPerl_OSErr = (short) OSAAvailableDialectCodeList(scriptingComponent, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAExecuteEvent SCRIPTINGCOMPONENT, THEAPPLEEVENT, CONTEXTID, MODEFLAGS

The OSAExecuteEvent function attempts to use the script context specified by the
contextID parameter to handle the Apple event specified by the THEAPPLEEVENT
parameter.
Return C<undef> if an error was detected.

=cut
OSAID
OSAExecuteEvent(scriptingComponent, theAppleEvent, contextID, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				theAppleEvent
	OSAID 				contextID
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSAExecuteEvent(scriptingComponent, &theAppleEvent, contextID, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSADoEvent SCRIPTINGCOMPONENT, THEAPPLEEVENT, CONTEXTID, MODEFLAGS

The OSADoEvent function resembles both OSADoScript() and OSAExecuteEvent().
However,
unlike OSADoScript(), the script OSADoEvent executes must be in the form of a
script context, and execution is initiated by an Apple event. Unlike
OSAExecuteEvent(), OSADoEvent returns a reply Apple event rather than the script ID
of the resulting script value.
Return C<undef> if an error was detected.

=cut
AEDesc
OSADoEvent(scriptingComponent, theAppleEvent, contextID, modeFlags)
	ComponentInstance scriptingComponent
	AEDesc				theAppleEvent
	OSAID 				contextID
	long 					modeFlags
	CODE:
	if (gMacPerl_OSErr = (short) OSADoEvent(scriptingComponent, &theAppleEvent, contextID, modeFlags, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAMakeContext SCRIPTINGCOMPONENT, CONTEXTNAME, [PARENTCONTEXT]

The OSAMakeContext function creates a new script context that you may pass to
OSAExecute() or OSAExecuteEvent(). The new script context inherits the bindings of
the script context specified in the PARENTCONTEXT parameter.
Return C<undef> if an error was detected.

=cut
OSAID
OSAMakeContext(scriptingComponent,contextName, parentContext = 0)
	ComponentInstance scriptingComponent
	AEDesc				contextName
	OSAID 				parentContext
	CODE:
	if (gMacPerl_OSErr = (short) OSAMakeContext(scriptingComponent, &contextName, parentContext, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAGetDefaultScriptingComponent GENERICSCRIPTINGCOMPONENT

The OSAGetDefaultScriptingComponent function returns the subtype code for the
default scripting component. This is the scripting component that will be used by
OSAStartRecording(), OSACompile(), or OSACompileExecute() if no existing script ID is
specified. From the user's point of view, the default scripting component
corresponds to the scripting language selected in the Script Editor application
when the user first creates a new script.
Return C<undef> if an error was detected.

=cut
OSType
OSAGetDefaultScriptingComponent(genericScriptingComponent)
	ComponentInstance	genericScriptingComponent
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetDefaultScriptingComponent(genericScriptingComponent, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSASetDefaultScriptingComponent GENERICSCRIPTINGCOMPONENT, SCRIPTINGSUBTYPE

The OSASetDefaultScriptingComponent function sets the default scripting component
for the specified instance of the generic scripting component to the scripting
component identified by the SCRIPTINGSUBTYPE parameter.
Return zero if no error was detected.

=cut
OSAError
OSASetDefaultScriptingComponent(genericScriptingComponent, scriptingSubType)
	ComponentInstance genericScriptingComponent
	OSType				scriptingSubType

=item OSAGetScriptingComponent GENERICSCRIPTINGCOMPONENT, SCRIPTINGSUBTYPE

The OSAGetScriptingComponent function returns an instance of the scripting
component identified by the
SCRIPTINGSUBTYPE parameter. Each instance of the generic scripting component
keeps track of a single instance of each component subtype, so
OSAGetScriptingComponent always returns the same instance of a specified
scripting component that the generic scripting component uses for standard
scripting component routines.
Return C<undef> if an error was detected.

=cut
ComponentInstance
OSAGetScriptingComponent(genericScriptingComponent, scriptingSubType)
	ComponentInstance genericScriptingComponent
	OSType 				scriptingSubType
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetScriptingComponent(genericScriptingComponent, scriptingSubType, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAGetScriptingComponentFromStored GENERICSCRIPTINGCOMPONENT, SCRIPTDATA

The OSAGetScriptingComponentFromStored function returns the subtype code for the
scripting component that created the script
data specified by the SCRIPTDATA parameter. 
Return C<undef> if an error was detected.

=cut
OSType
OSAGetScriptingComponentFromStored(genericScriptingComponent, scriptData)
	ComponentInstance genericScriptingComponent
	AEDesc				scriptData
	CODE:
	if (gMacPerl_OSErr = (short) OSAGetScriptingComponentFromStored(genericScriptingComponent, &scriptData, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item OSAGenericToRealID GENERICSCRIPTINGCOMPONENT, GENERICSCRIPTID

Given a GENERICSCRIPTID (that is, a script ID returned by a call to a standard
component routine via the generic scripting component), the OSAGenericToRealID
function returns the equivalent component-specific script ID and the component
instance that created that script ID as an array.

=cut
void
OSAGenericToRealID(genericScriptingComponent, genericScriptID)
	ComponentInstance genericScriptingComponent
	OSAID					genericScriptID
	PREINIT:
	ComponentInstance	exactScriptingComponent;
	PPCODE:
	if (gMacPerl_OSErr = (short) OSAGenericToRealID(genericScriptingComponent, &genericScriptID, &exactScriptingComponent)) {
		XSRETURN_EMPTY;
	}
	XS_XPUSH(OSAID, genericScriptID);
	XS_XPUSH(ComponentInstance, exactScriptingComponent);

	
=item OSARealToGenericID GENERICSCRIPTINGCOMPONENT, THESCRIPTID, THEEXACTCOMPONENT

The OSARealToGenericID function performs the reverse of the task performed by
OSAGenericToRealID(). Given a component-specific SCRIPTID and an exact scripting
component instance (that is, the component instance that created the
component-specific script ID), the OSARealToGenericID function returns the
corresponding generic script ID.
Return C<undef> if an error was detected.

=cut
OSAID
OSARealToGenericID(genericScriptingComponent, theScriptID, theExactComponent)
	ComponentInstance genericScriptingComponent
	OSAID					theScriptID
	ComponentInstance theExactComponent
	CODE:
	RETVAL = theScriptID;
	if (gMacPerl_OSErr = (short) OSARealToGenericID(genericScriptingComponent, &RETVAL, theExactComponent)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=back

=cut
