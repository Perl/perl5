Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# AppleScript.t - Run an AppleScript.
#

use Mac::Components;
use Mac::OSA;
use Mac::AppleEvents;

$applescript = OpenDefaultComponent(kOSAComponentType, "ascr") or die "AppleScript not installed";
$script = AECreateDesc "TEXT", $ARGV[0] || <<'END_SCRIPT';
2+2
END_SCRIPT

$result = OSADoScript($applescript, $script, 0, "TEXT", 0) or die $^E;

print AEPrint($result), "\n";

AEDisposeDesc $result;
AEDisposeDesc $script;

CloseComponent $applescript;
