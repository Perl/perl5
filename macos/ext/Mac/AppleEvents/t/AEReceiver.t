Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# AEReceiver.t - Demonstrate different techniques how to wait on an 
#                AppleEvent.

use Mac::AppleEvents;

AEInstallEventHandler("aevt", "pdoc", "PrintDocument", 0, 0) or die "$^E";
$AppleEvent{"aevt", "odoc"} = "OpenDocument";
$AppleEvent{"****", "****"} = "TattleTale";

print $AppleEvent{"aevt", "odoc"}, "\n";

while (!$ok) {
	sleep(1);
}

sub OpenDocument {
	my($event) = @_;
	
	print "OpenDocument called\n", AEPrint($event), "\n";
	$ok = 1;

	0;
}

sub PrintDocument {
	my($event) = @_;
	
	print "PrintDocument called\n", AEPrint($event), "\n";
	$ok = 1;

	0;
}

sub TattleTale {
	my($event,$reply) = @_;
	
	print "Some other event sent:\n", AEPrint($event), "\n";
	AEPutParam($reply, "----", "TEXT", "Hi there");
	$ok = 1;

	0;
}
