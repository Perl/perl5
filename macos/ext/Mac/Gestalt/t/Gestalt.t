Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Gestalt.t - Demostrate the Gestalt call.
#

use Mac::Gestalt;

print Gestalt(gestaltStandardFileAttr), "\n";

if ($Gestalt{gestaltCloseViewAttr()} & (1 << gestaltCloseViewEnabled)) {
	print "Hello, fellow four-eye!\n";
}