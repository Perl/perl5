Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# AESender.t - Demonstrate how to build and send a very simple AppleEvent.
#              To use it, first start AEReceiver.t under MPW and then this
#              script.
#

use Mac::AppleEvents;

$evt = AEBuildAppleEvent("Hllo", "Wrld", typeApplSignature, "MPS ", 0, 0, "") or die $^E;
$rep = AESend($evt, kAEWaitReply) or die $^E;

print "Reply was: ", AEPrint($rep), "\n";

AEDisposeDesc $evt;
AEDisposeDesc $rep;

