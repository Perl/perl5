Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Record.t - Record an AppleScript.
#

use Mac::Components;
use Mac::OSA;
use Mac::AppleEvents;

$defaultScripting = OpenDefaultComponent(kOSAComponentType, kOSAGenericScriptingComponentSubtype);
$appleScript = OSAGetScriptingComponent($defaultScripting, "ascr");

$AppleEvent{kOSASuite, kOSARecordedText} = \&Recorder;
$script = OSAStartRecording($appleScript);
print STDERR "Recording started, enter a newline to stop\n";
$_ = <>;
OSAStopRecording($appleScript, $script);

$source = OSAGetSource($appleScript, $script, "TEXT");
print $source->get(), "\n";
AEDisposeDesc $source;

OSADispose($appleScript, $script);

CloseComponent $appleScript;
CloseComponent $defaultScripting;

sub Recorder {
	my($event) = @_;
	
	print AEPrint($event), "\n";
}