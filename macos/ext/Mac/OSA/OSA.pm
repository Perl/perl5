=head1 NAME

Mac::OSA - Provide interface to Open Scripting Architecture

=head1 SYNOPSIS


    use Mac::OSA;

    use Mac::OSA qw(OSALoad OSAStore OSAExecute);

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::OSA;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	use Mac::AppleEvents;
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		OSALoad
		OSAStore
		OSAExecute
		OSADisplay
		OSAScriptError
		OSADispose
		OSASetScriptInfo
		OSAGetScriptInfo
		OSAScriptingComponentName
		OSACompile
		OSACopyID
		OSAGetSource
		OSACoerceFromDesc
		OSACoerceToDesc
		OSASetDefaultTarget
		OSAStartRecording
		OSAStopRecording
		OSALoadExecute
		OSACompileExecute
		OSADoScript
		OSASetCurrentDialect
		OSAGetCurrentDialect
		OSAAvailableDialects
		OSAGetDialectInfo
		OSAAvailableDialectCodeList
		OSAExecuteEvent
		OSADoEvent
		OSAMakeContext
		OSAGetDefaultScriptingComponent
		OSASetDefaultScriptingComponent
		OSAGetScriptingComponent
		OSAGetScriptingComponentFromStored
		OSAGenericToRealID
		OSARealToGenericID
		
		kOSAComponentType
		kOSAGenericScriptingComponentSubtype
		kOSAFileType
		kOSASuite
		kOSARecordedText
		kOSAScriptIsModified
		kOSAScriptIsTypeCompiledScript
		kOSAScriptIsTypeScriptValue
		kOSAScriptIsTypeScriptContext
		kOSAScriptBestType
		kOSACanGetSource
		typeOSADialectInfo
		keyOSADialectName
		keyOSADialectCode
		keyOSADialectLangCode
		keyOSADialectScriptCode
		kOSANullScript
		kOSANullMode
		kOSAModeNull
		kOSASupportsCompiling
		kOSASupportsGetSource
		kOSASupportsAECoercion
		kOSASupportsAESending
		kOSASupportsRecording
		kOSASupportsConvenience
		kOSASupportsDialects
		kOSASupportsEventHandling
		kOSAModePreventGetSource
		kOSAModeNeverInteract
		kOSAModeCanInteract
		kOSAModeAlwaysInteract
		kOSAModeDontReconnect
		kOSAModeCantSwitchLayer
		kOSAModeDoRecord
		kOSAModeCompileIntoContext
		kOSAModeAugmentContext
		kOSAModeDisplayForHumans
		kOSAModeDontStoreParent
		kOSAModeDispatchToDirectObject
		kOSAModeDontGetDataForArguments
		kOSAScriptResourceType
		typeOSAGenericStorage
		kOSAErrorNumber
		kOSAErrorMessage
		kOSAErrorBriefMessage
		kOSAErrorApp
		kOSAErrorPartialResult
		kOSAErrorOffendingObject
		kOSAErrorExpectedType
		kOSAErrorRange
		typeOSAErrorRange
		keyOSASourceStart
		keyOSASourceEnd
		kOSAUseStandardDispatch
		kOSANoDispatch
		kOSADontUsePhac
		kGenericComponentVersion
	);
}

bootstrap Mac::OSA;

=head2 Constants

=over 4

=item kOSAComponentType

=item kOSAGenericScriptingComponentSubtype

=item kOSAFileType

=item kOSASuite

=item kOSARecordedText

=item kOSAScriptIsModified

=item kOSAScriptIsTypeCompiledScript

=item kOSAScriptIsTypeScriptValue

=item kOSAScriptIsTypeScriptContext

=item kOSAScriptBestType

=item kOSACanGetSource

=item typeOSADialectInfo

=item keyOSADialectName

=item keyOSADialectCode

=item keyOSADialectLangCode

=item keyOSADialectScriptCode

=item kOSAScriptResourceType

=item typeOSAGenericStorage

Types and keywords.

=cut
sub kOSAComponentType ()           {     'osa '; }
sub kOSAGenericScriptingComponentSubtype () {     'scpt'; }
sub kOSAFileType ()                {     'osas'; }
sub kOSASuite ()                   {     'ascr'; }
sub kOSARecordedText ()            {     'recd'; }
sub kOSAScriptIsModified ()        {     'modi'; }
sub kOSAScriptIsTypeCompiledScript () {     'cscr'; }
sub kOSAScriptIsTypeScriptValue () {     'valu'; }
sub kOSAScriptIsTypeScriptContext () {     'cntx'; }
sub kOSAScriptBestType ()          {     'best'; }
sub kOSACanGetSource ()            {     'gsrc'; }
sub typeOSADialectInfo ()          {     'difo'; }
sub keyOSADialectName ()           {     'dnam'; }
sub keyOSADialectCode ()           {     'dcod'; }
sub keyOSADialectLangCode ()       {     'dlcd'; }
sub keyOSADialectScriptCode ()     {     'dscd'; }
sub kOSAScriptResourceType ()      { kOSAGenericScriptingComponentSubtype; }
sub typeOSAGenericStorage ()       { kOSAScriptResourceType; }


=item kOSANullScript

=item kOSANullMode

=item kOSAModeNull

Default values.

=cut
sub kOSANullScript ()              {          0; }
sub kOSANullMode ()                {          0; }
sub kOSAModeNull ()                {          0; }


=item kOSASupportsCompiling

=item kOSASupportsGetSource

=item kOSASupportsAECoercion

=item kOSASupportsAESending

=item kOSASupportsRecording

=item kOSASupportsConvenience

=item kOSASupportsDialects

=item kOSASupportsEventHandling

Feature flags.

=cut
sub kOSASupportsCompiling ()       {     0x0002; }
sub kOSASupportsGetSource ()       {     0x0004; }
sub kOSASupportsAECoercion ()      {     0x0008; }
sub kOSASupportsAESending ()       {     0x0010; }
sub kOSASupportsRecording ()       {     0x0020; }
sub kOSASupportsConvenience ()     {     0x0040; }
sub kOSASupportsDialects ()        {     0x0080; }
sub kOSASupportsEventHandling ()   {     0x0100; }


=item kOSAModePreventGetSource

=item kOSAModeNeverInteract

=item kOSAModeCanInteract

=item kOSAModeAlwaysInteract

=item kOSAModeDontReconnect

=item kOSAModeCantSwitchLayer

=item kOSAModeDoRecord

=item kOSAModeCompileIntoContext

=item kOSAModeAugmentContext

=item kOSAModeDisplayForHumans

=item kOSAModeDontStoreParent

=item kOSAModeDispatchToDirectObject

=item kOSAModeDontGetDataForArguments

Mode flags.

=cut
sub kOSAModePreventGetSource ()    { 0x00000001; }
sub kOSAModeNeverInteract ()       { kAENeverInteract; }
sub kOSAModeCanInteract ()         { kAECanInteract; }
sub kOSAModeAlwaysInteract ()      { kAEAlwaysInteract; }
sub kOSAModeDontReconnect ()       { kAEDontReconnect; }
sub kOSAModeCantSwitchLayer ()     { 0x00000040; }
sub kOSAModeDoRecord ()            { 0x00001000; }
sub kOSAModeCompileIntoContext ()  { 0x00000002; }
sub kOSAModeAugmentContext ()      { 0x00000004; }
sub kOSAModeDisplayForHumans ()    { 0x00000008; }
sub kOSAModeDontStoreParent ()     { 0x00010000; }
sub kOSAModeDispatchToDirectObject () { 0x00020000; }
sub kOSAModeDontGetDataForArguments () { 0x00040000; }


=item kOSAErrorNumber

=item kOSAErrorMessage

=item kOSAErrorBriefMessage

=item kOSAErrorApp

=item kOSAErrorPartialResult

=item kOSAErrorOffendingObject

=item kOSAErrorExpectedType

=item kOSAErrorRange

=item typeOSAErrorRange

=item keyOSASourceStart

=item keyOSASourceEnd

Error handling.

=cut
sub kOSAErrorNumber ()             { keyErrorNumber; }
sub kOSAErrorMessage ()            { keyErrorString; }
sub kOSAErrorBriefMessage ()       {     'errb'; }
sub kOSAErrorApp ()                {     'erap'; }
sub kOSAErrorPartialResult ()      {     'ptlr'; }
sub kOSAErrorOffendingObject ()    {     'erob'; }
sub kOSAErrorExpectedType ()       {     'errt'; }
sub kOSAErrorRange ()              {     'erng'; }
sub typeOSAErrorRange ()           {     'erng'; }
sub keyOSASourceStart ()           {     'srcs'; }
sub keyOSASourceEnd ()             {     'srce'; }


=item kOSAUseStandardDispatch

=item kOSANoDispatch

=item kOSADontUsePhac

=item kGenericComponentVersion

Dispatching flags

=cut
sub kOSAUseStandardDispatch ()     { kAEUseStandardDispatch; }
sub kOSANoDispatch ()              { kAENoDispatch; }
sub kOSADontUsePhac ()             {     0x0001; }
sub kGenericComponentVersion ()    {     0x0100; }

=back

=include OSA.xs

=head1 BUGS/LIMITATIONS

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> Author

Bob Dalgleish <bob.dalgleish@sasknet.sk.ca> Documenter

=cut

1;

__END__
