#!perl
#
# Perl translation of SAT Collision demo
#

use Mac::SAT;
use Mac::Events;
use Mac::QuickDraw;
use Mac::Resources;

BEGIN {
	$prev = CurResFile();
	UseResFile($rsrc = FSpOpenResFile("Collision.rsrc", 0));
	SATConfigure(1, kVPositionSort, kKindCollision, 32);
	SATInit(128, 129, 512, 322);
	HideCursor();
}

END {
	ShowCursor();
	SATSoundShutup(); # Always make sure the sound channel is de-allocated!.
	UseResFile($prev);
    CloseResFile($rsrc);
}

#################### Mr. Egghead ##########################

BEGIN {
	for my $i (128..131) {
		push @mrEggheadFaces, SATGetFace($i);
	}
}

sub HandleMrEgghead {
	my($my) = @_;
	
	$my->position(GetMouse());
	$my->mode($my->mode+1);
	$my->face($mrEggheadFaces[$my->mode % 4]);
}

sub SetupMrEgghead {
	my($my) = @_;
	
	$my->mode(0);
	$my->speed(new Point(1, 0));
	$my->kind(1); # Friend
	$my->hotRect(new Rect(0, 0, 32, 32));
	$my->task(\&HandleMrEgghead);
}

#################### Apple ##########################

BEGIN {
	$theSound = SATGetSound(128);
	$appleFace = SATGetFace(132);
}

sub HandleApple {
	my($my) = @_;
	
	if ($my->kind != -1) { # Something hit us!.
		SATSoundPlay($theSound, 1, 0);
		$my->task(undef); # Go away.
	}
	# Move.
	$my->position(AddPt($my->position, $my->speed));
	if  ($my->position->h > gSAT()->offSizeH - 16) {
		$my->speed(new Point(-1 - SATRand(3), 0));
	} elsif ($my->position->h < -16) {
		$my->speed(new Point(1 + SATRand(3), 0));
	}
}

sub SetupApple
{
	my($my) = @_;
	
	$my->speed(new Point(1 + SATRand(3), 0));
	$my->kind(-1); # Enemy
	$my->face($appleFace);
	$my->hotRect(new Rect(0, 0, 32, 32));
	$my->task(\&HandleApple);
}

############ The Game ##############################

$pt = GetMouse(); #We get the mouse position in order to put Mr Egghead under it immediately.
SATNewSprite(0, $pt->h, $pt->v, \&SetupMrEgghead);
SATNewSprite(0, 0, SATRand(gSAT()->offSizeV - 32), \&SetupApple);

do {
	$t = TickCount();
	SATRun(1); 						# Run a frame of animation.
	while ($t > TickCount() - 3) {	# Speed limit.
		;
	}
	# Start a new apple once in a while.
	if (SATRand(40) == 1) {
		SATNewSprite(0, 0, SATRand(gSAT()->offSizeV - 32), \&SetupApple);
	}
} while (!Button());
