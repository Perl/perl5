#!
#
# Scream.t - Play a sound resource
#

use Mac::Resources;
use Mac::Sound;

$snd = GetResource('snd ', 129)
	or die $^E;
$chan = SndNewChannel(0,0)
	or die $^E;
SndPlay($chan, $snd, 0)
	or die $^E;
SndDisposeChannel($chan, 0)
	or die $^E;
