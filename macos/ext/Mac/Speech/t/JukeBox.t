#!perl
#
# Demonstrate all avaliable voices
#

use Mac::Speech;

$count = CountVoices();

for ($i = 0; $i++ < $count; ) {
	$voice = GetIndVoice($i);
	$desc  = ${GetVoiceDescription($voice)};
	($synt, $id, $version,$nlen,$name,$clen,$comment,$gender,$age,$script,$language,$region)
		= unpack("x4 a4 l l C a63 C a255 s s s s s", $desc);
 $name = substr $name, 0, $nlen;
	$comment = substr $comment, 0, $clen;
	$channel = NewSpeechChannel($voice)               or die $^E;
	SpeakText $channel, $comment or die $^E;
	while (SpeechBusy()) {}
	DisposeSpeechChannel $channel;
}
