#!perl

use Mac::SpeechRecognition;
use Mac::AppleEvents;

#
# Initialize Recognition System
#
$system = SROpenRecognitionSystem or die $^E;
SRSetProperty $system, kSRFeedbackAndListeningModes, kSRHasFeedbackHasListenModes
	or die $^E;
#
# Create Recognizer
#
$recognizer = SRNewRecognizer $system;
#
# Build Language Model
#
$callModel = SRNewLanguageModel $system, "<call>"		or die $^E;
for (("call", "phone", "dial")) {
	$phrase = SRNewPhrase $system, $_					or die $^E;
	SRAddLanguageObject $callModel, $phrase				or die $^E;
	SRReleaseObject $phrase								or die $^E;
}
$personModel = SRNewLanguageModel $system, "<person>"	or die $^E;
for (("Arlo", "Matt", "Brent", "my wife")) {
	$phrase = SRNewPhrase $system, $_					or die $^E;
	SRAddLanguageObject $personModel, $phrase			or die $^E;
	SRReleaseObject $phrase								or die $^E;
}
$topModel = SRNewLanguageModel $system, "<TopLM>"		or die $^E;
$callPath = SRNewPath $system							or die $^E;
SRAddLanguageObject $callPath, $callModel				or die $^E;
SRAddLanguageObject $callPath, $personModel				or die $^E;
SRAddLanguageObject $topModel, $callPath				or die $^E;
SRReleaseObject $callPath;
SRReleaseObject $personModel;
SRReleaseObject $callModel;
SRSetLanguageModel $recognizer, $topModel				or die $^E;
#
# Set up AppleEvent handler and start listening
#
$AppleEvent{kAESpeechSuite, kAESpeechDone} = "WordUp";
SRStartListening $recognizer;
SRSetProperty $recognizer, kSRNotificationParam, kSRNotifyRecognitionDone
	or die $^E;
#
# Main event Loop
#
while (!$done) {
	sleep(5);
}
#
# Shut down
#
SRStopListening $recognizer;
SRReleaseObject $topModel;
SRReleaseObject $recognizer;
SRCloseRecognitionSystem $system;

sub AEGetSpeechObject {
	my($event, $key, $type) = @_;
	my($desc,$obj);
	$desc = AEGetParamDesc $event, $key, $type;
	$obj = SRMakeSpeechObject $desc->data->get;
	AEDisposeDesc $desc;
	$obj;
}

sub WordUp {
	my($event,$reply) = @_;
	
	$rec = AEGetSpeechObject $event, keySRRecognizer, typeSRRecognizer;
	$res = AEGetSpeechObject $event, keySRSpeechResult, typeSRSpeechResult;
	
	print "I think you said: ", SRGetProperty($res, kSRTEXTFormat), "\n";

	SRReleaseObject $res;
	# Not sure if we also need SRReleaseObject $rec;
	
	$done = 1;
}
