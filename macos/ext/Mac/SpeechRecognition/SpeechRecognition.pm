=head1 NAME

Mac::SpeechRecognition - Provide interface to Speech Recognition Manager

=head1 SYNOPSIS

	use Mac::SpeechRecognition;

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut
use strict;

package Mac::SpeechRecognition;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		SROpenRecognitionSystem
		SRCloseRecognitionSystem
		SRSetProperty
		SRGetProperty
		SRReleaseObject
		SRGetReference
		SRNewRecognizer
		SRStartListening
		SRStopListening
		SRSetLanguageModel
		SRGetLanguageModel
		SRContinueRecognition
		SRCancelRecognition
		SRIdle
		SRNewLanguageModel
		SRNewPath
		SRNewPhrase
		SRNewWord
		SRPutLanguageObjectIntoHandle
		SRPutLanguageObjectIntoDataFile
		SRNewLanguageObjectFromHandle
		SRNewLanguageObjectFromDataFile
		SREmptyLanguageObject
		SRChangeLanguageObject
		SRAddLanguageObject
		SRAddText
		SRRemoveLanguageObject
		SRCountItems
		SRGetIndexedItem
		SRSetIndexedItem
		SRRemoveIndexedItem
		SRDrawText
		SRDrawRecognizedText
		SRSpeakText
		SRSpeakAndDrawText
		SRStopSpeech
		SRSpeechBusy
		SRProcessBegin
		SRProcessEnd
		SRMakeSpeechObject
		gestaltSpeechRecognitionVersion
		gestaltSpeechRecognitionAttr
		gestaltDesktopSpeechRecognition
		gestaltTelephoneSpeechRecognition
		kSRNotAvailable
		kSRInternalError
		kSRComponentNotFound
		kSROutOfMemory
		kSRNotASpeechObject
		kSRBadParameter
		kSRParamOutOfRange
		kSRBadSelector
		kSRBufferTooSmall
		kSRNotARecSystem
		kSRFeedbackNotAvail
		kSRCantSetProperty
		kSRCantGetProperty
		kSRCantSetDuringRecognition
		kSRAlreadyListening
		kSRNotListeningState
		kSRModelMismatch
		kSRNoClientLanguageModel
		kSRNoPendingUtterances
		kSRRecognitionCanceled
		kSRRecognitionDone
		kSROtherRecAlreadyModal
		kSRHasNoSubItems
		kSRSubItemNotFound
		kSRLanguageModelTooBig
		kSRAlreadyReleased
		kSRAlreadyFinished
		kSRWordNotFound
		kSRNotFinishedWithRejection
		kSRExpansionTooDeep
		kSRTooManyElements
		kSRCantAdd
		kSRSndInSourceDisconnected
		kSRCantReadLanguageObject
		kSRNotImplementedYet
		kSRDefaultRecognitionSystemID
		kSRFeedbackAndListeningModes
		kSRRejectedWord
		kSRCleanupOnClientExit
		kSRNoFeedbackNoListenModes
		kSRHasFeedbackHasListenModes
		kSRNoFeedbackHasListenModes
		kSRDefaultSpeechSource
		kSRLiveDesktopSpeechSource
		kSRCanned22kHzSpeechSource
		kSRNotifyRecognitionBeginning
		kSRNotifyRecognitionDone
		kAESpeechSuite
		kAESpeechDone
		kAESpeechDetected
		keySRRecognizer
		keySRSpeechResult
		keySRSpeechStatus
		typeSRRecognizer
		typeSRSpeechResult
		kSRNotificationParam
		kSRCallBackParam
		kSRSearchStatusParam
		kSRAutoFinishingParam
		kSRForegroundOnly
		kSRBlockBackground
		kSRBlockModally
		kSRWantsResultTextDrawn
		kSRWantsAutoFBGestures
		kSRSoundInVolume
		kSRReadAudioFSSpec
		kSRCancelOnSoundOut
		kSRSpeedVsAccuracyParam
		kSRUseToggleListen
		kSRUsePushToTalk
		kSRListenKeyMode
		kSRListenKeyCombo
		kSRListenKeyName
		kSRKeyWord
		kSRKeyExpected
		kSRIdleRecognizer
		kSRSearchInProgress
		kSRSearchWaitForAllClients
		kSRMustCancelSearch
		kSRPendingSearch
		kSRTEXTFormat
		kSRPhraseFormat
		kSRPathFormat
		kSRLanguageModelFormat
		kSRSpelling
		kSRLMObjType
		kSRRefCon
		kSROptional
		kSREnabled
		kSRRepeatable
		kSRRejectable
		kSRRejectionLevel
		kSRLanguageModelType
		kSRPathType
		kSRPhraseType
		kSRWordType
		kSRDefaultRejectionLevel
	);
}

bootstrap Mac::SpeechRecognition;

=head2 Constants

=over 4

=item gestaltSpeechRecognitionVersion

=item gestaltSpeechRecognitionAttr

=cut
sub gestaltSpeechRecognitionVersion () {     'srtb'; }
sub gestaltSpeechRecognitionAttr () {     'srta'; }


=item gestaltDesktopSpeechRecognition

=item gestaltTelephoneSpeechRecognition

=cut
sub gestaltDesktopSpeechRecognition () {    1 << 0; }
sub gestaltTelephoneSpeechRecognition () {    1 << 1; }


=item kSRNotAvailable

=item kSRInternalError

=item kSRComponentNotFound

=item kSROutOfMemory

=item kSRNotASpeechObject

=item kSRBadParameter

=item kSRParamOutOfRange

=item kSRBadSelector

=item kSRBufferTooSmall

=item kSRNotARecSystem

=item kSRFeedbackNotAvail

=item kSRCantSetProperty

=item kSRCantGetProperty

=item kSRCantSetDuringRecognition

=item kSRAlreadyListening

=item kSRNotListeningState

=item kSRModelMismatch

=item kSRNoClientLanguageModel

=item kSRNoPendingUtterances

=item kSRRecognitionCanceled

=item kSRRecognitionDone

=item kSROtherRecAlreadyModal

=item kSRHasNoSubItems

=item kSRSubItemNotFound

=item kSRLanguageModelTooBig

=item kSRAlreadyReleased

=item kSRAlreadyFinished

=item kSRWordNotFound

=item kSRNotFinishedWithRejection

=item kSRExpansionTooDeep

=item kSRTooManyElements

=item kSRCantAdd

=item kSRSndInSourceDisconnected

=item kSRCantReadLanguageObject

=item kSRNotImplementedYet

=cut
sub kSRNotAvailable ()             {      -5100; }
sub kSRInternalError ()            {      -5101; }
sub kSRComponentNotFound ()        {      -5102; }
sub kSROutOfMemory ()              {      -5103; }
sub kSRNotASpeechObject ()         {      -5104; }
sub kSRBadParameter ()             {      -5105; }
sub kSRParamOutOfRange ()          {      -5106; }
sub kSRBadSelector ()              {      -5107; }
sub kSRBufferTooSmall ()           {      -5108; }
sub kSRNotARecSystem ()            {      -5109; }
sub kSRFeedbackNotAvail ()         {      -5110; }
sub kSRCantSetProperty ()          {      -5111; }
sub kSRCantGetProperty ()          {      -5112; }
sub kSRCantSetDuringRecognition () {      -5113; }
sub kSRAlreadyListening ()         {      -5114; }
sub kSRNotListeningState ()        {      -5115; }
sub kSRModelMismatch ()            {      -5116; }
sub kSRNoClientLanguageModel ()    {      -5117; }
sub kSRNoPendingUtterances ()      {      -5118; }
sub kSRRecognitionCanceled ()      {      -5119; }
sub kSRRecognitionDone ()          {      -5120; }
sub kSROtherRecAlreadyModal ()     {      -5121; }
sub kSRHasNoSubItems ()            {      -5122; }
sub kSRSubItemNotFound ()          {      -5123; }
sub kSRLanguageModelTooBig ()      {      -5124; }
sub kSRAlreadyReleased ()          {      -5125; }
sub kSRAlreadyFinished ()          {      -5126; }
sub kSRWordNotFound ()             {      -5127; }
sub kSRNotFinishedWithRejection () {      -5128; }
sub kSRExpansionTooDeep ()         {      -5129; }
sub kSRTooManyElements ()          {      -5130; }
sub kSRCantAdd ()                  {      -5131; }
sub kSRSndInSourceDisconnected ()  {      -5132; }
sub kSRCantReadLanguageObject ()   {      -5133; }
sub kSRNotImplementedYet ()        {      -5199; }


=item kSRDefaultRecognitionSystemID

=cut
sub kSRDefaultRecognitionSystemID () {          0; }


=item kSRFeedbackAndListeningModes

=item kSRRejectedWord

=item kSRCleanupOnClientExit

=cut
sub kSRFeedbackAndListeningModes () {     'fbwn'; }
sub kSRRejectedWord ()             {     'rejq'; }
sub kSRCleanupOnClientExit ()      {     'clup'; }


=item kSRNoFeedbackNoListenModes

=item kSRHasFeedbackHasListenModes

=item kSRNoFeedbackHasListenModes

=cut
sub kSRNoFeedbackNoListenModes ()  {          0; }
sub kSRHasFeedbackHasListenModes () {          1; }
sub kSRNoFeedbackHasListenModes () {          2; }


=item kSRDefaultSpeechSource

=item kSRLiveDesktopSpeechSource

=item kSRCanned22kHzSpeechSource

=cut
sub kSRDefaultSpeechSource ()      {          0; }
sub kSRLiveDesktopSpeechSource ()  {     'dklv'; }
sub kSRCanned22kHzSpeechSource ()  {     'ca22'; }


=item kSRNotifyRecognitionBeginning

=item kSRNotifyRecognitionDone

=cut
sub kSRNotifyRecognitionBeginning () {    1 << 0; }
sub kSRNotifyRecognitionDone ()    {    1 << 1; }


=item kAESpeechSuite

=item kAESpeechDone

=item kAESpeechDetected

=item keySRRecognizer

=item keySRSpeechResult

=item keySRSpeechStatus

=item typeSRRecognizer

=item typeSRSpeechResult

=item kSRNotificationParam

=item kSRCallBackParam

=item kSRSearchStatusParam

=item kSRAutoFinishingParam

=item kSRForegroundOnly

=item kSRBlockBackground

=item kSRBlockModally

=item kSRWantsResultTextDrawn

=item kSRWantsAutoFBGestures

=item kSRSoundInVolume

=item kSRReadAudioFSSpec

=item kSRCancelOnSoundOut

=item kSRSpeedVsAccuracyParam

=cut
sub kAESpeechSuite ()              {     'sprc'; }
sub kAESpeechDone ()               {     'srsd'; }
sub kAESpeechDetected ()           {     'srbd'; }
sub keySRRecognizer ()             {     'krec'; }
sub keySRSpeechResult ()           {     'kspr'; }
sub keySRSpeechStatus ()           {     'ksst'; }
sub typeSRRecognizer ()            {     'trec'; }
sub typeSRSpeechResult ()          {     'tspr'; }
sub kSRNotificationParam ()        {     'noti'; }
sub kSRCallBackParam ()            {     'call'; }
sub kSRSearchStatusParam ()        {     'stat'; }
sub kSRAutoFinishingParam ()       {     'afin'; }
sub kSRForegroundOnly ()           {     'fgon'; }
sub kSRBlockBackground ()          {     'blbg'; }
sub kSRBlockModally ()             {     'blmd'; }
sub kSRWantsResultTextDrawn ()     {     'txfb'; }
sub kSRWantsAutoFBGestures ()      {     'dfbr'; }
sub kSRSoundInVolume ()            {     'volu'; }
sub kSRReadAudioFSSpec ()          {     'aurd'; }
sub kSRCancelOnSoundOut ()         {     'caso'; }
sub kSRSpeedVsAccuracyParam ()     {     'sped'; }


=item kSRUseToggleListen

=item kSRUsePushToTalk

=cut
sub kSRUseToggleListen ()          {          0; }
sub kSRUsePushToTalk ()            {          1; }


=item kSRListenKeyMode

=item kSRListenKeyCombo

=item kSRListenKeyName

=item kSRKeyWord

=item kSRKeyExpected

=cut
sub kSRListenKeyMode ()            {     'lkmd'; }
sub kSRListenKeyCombo ()           {     'lkey'; }
sub kSRListenKeyName ()            {     'lnam'; }
sub kSRKeyWord ()                  {     'kwrd'; }
sub kSRKeyExpected ()              {     'kexp'; }


=item kSRIdleRecognizer

=item kSRSearchInProgress

=item kSRSearchWaitForAllClients

=item kSRMustCancelSearch

=item kSRPendingSearch

=cut
sub kSRIdleRecognizer ()           {    1 << 0; }
sub kSRSearchInProgress ()         {    1 << 1; }
sub kSRSearchWaitForAllClients ()  {    1 << 2; }
sub kSRMustCancelSearch ()         {    1 << 3; }
sub kSRPendingSearch ()            {    1 << 4; }


=item kSRTEXTFormat

=item kSRPhraseFormat

=item kSRPathFormat

=item kSRLanguageModelFormat

=item kSRSpelling

=item kSRLMObjType

=item kSRRefCon

=item kSROptional

=item kSREnabled

=item kSRRepeatable

=item kSRRejectable

=item kSRRejectionLevel

=item kSRLanguageModelType

=item kSRPathType

=item kSRPhraseType

=item kSRWordType

=cut
sub kSRTEXTFormat ()               {     'TEXT'; }
sub kSRPhraseFormat ()             {     'lmph'; }
sub kSRPathFormat ()               {     'lmpt'; }
sub kSRLanguageModelFormat ()      {     'lmfm'; }
sub kSRSpelling ()                 {     'spel'; }
sub kSRLMObjType ()                {     'lmtp'; }
sub kSRRefCon ()                   {     'refc'; }
sub kSROptional ()                 {     'optl'; }
sub kSREnabled ()                  {     'enbl'; }
sub kSRRepeatable ()               {     'rptb'; }
sub kSRRejectable ()               {     'rjbl'; }
sub kSRRejectionLevel ()           {     'rjct'; }
sub kSRLanguageModelType ()        {     'lmob'; }
sub kSRPathType ()                 {     'path'; }
sub kSRPhraseType ()               {     'phra'; }
sub kSRWordType ()                 {     'word'; }


=item kSRDefaultRejectionLevel

=cut
sub kSRDefaultRejectionLevel ()    {         50; }

=back

=include SpeechRecognition.xs

=head1 BUGS/LIMITATIONS

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> Author

=cut

1;

__END__
