Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Frontier.t - Run a Frontier script.
#

use Mac::Components;
use Mac::OSA;
use Mac::AppleEvents;

$frontier = OpenDefaultComponent(kOSAComponentType, "LAND") or die "Frontier not installed";
$script = AECreateDesc "TEXT", $ARGV[0] || <<'END_SCRIPT';
2+2
END_SCRIPT

$result = OSADoScript($frontier, $script, 0, "TEXT", 0) or die $^E;

print AEPrint($result), "\n";

AEDisposeDesc $result;
AEDisposeDesc $script;

CloseComponent $frontier;
