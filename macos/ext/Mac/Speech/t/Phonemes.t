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
  $phon = TextToPhonemes($channel, "Stop all the clocks disconnect the phone");
  print $phon;
		DisposeSpeechChannel $channel;
	}
}
