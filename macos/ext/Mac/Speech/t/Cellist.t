#!perl
#
# Say something in Cello
#

use Mac::Speech;

$count = CountVoices();

for ($i = 0; $i++ < $count; ) {
	$voice = GetIndVoice($i);
	$desc  = ${GetVoiceDescription($voice)};
	if ($desc =~ /Cello/) {
		$channel = NewSpeechChannel($voice)               or die $^E;
		SpeakText $channel, "Do you like my Cello Voice?" or die $^E;
		while (SpeechBusy()) {}
		SetSpeechPitch $channel, 1.2*GetSpeechPitch($channel);
		SpeakText $channel, "Wanna take you higher"       or die $^E;
		while (SpeechBusy()) {}
		DisposeSpeechChannel $channel;
	}
}
