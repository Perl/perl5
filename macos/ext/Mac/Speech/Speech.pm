=head1 NAME

Mac::Speech - Provide interface to PlainTalk (Speech Manager)

=head1 SYNOPSIS

	use Mac::Speech;

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Speech;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT %Voice);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		SpeechManagerVersion
		CountVoices
		GetIndVoice
		GetVoiceDescription
		NewSpeechChannel
		DisposeSpeechChannel
		SpeakString
		SpeakText
		SpeakBuffer
		StopSpeech
		StopSpeechAt
		PauseSpeechAt
		ContinueSpeech
		SpeechBusy
		SpeechBusySystemWide
		SetSpeechRate
		GetSpeechRate
		GetSpeechPitch
	 	SetSpeechPitch
		TextToPhonemes
		
		kTextToSpeechSynthType
		kTextToSpeechVoiceType
		kTextToSpeechVoiceFileType
		kTextToSpeechVoiceBundleType
		kNoEndingProsody
		kNoSpeechInterrupt
		kPreflightThenPause
		kImmediate
		kEndOfWord
		kEndOfSentence
		kNeuter
		kMale
		kFemale

      %Voice
	);
}

package Mac::Speech::_VoiceHash;

BEGIN {
    use Tie::Hash ();
    use vars qw(@ISA %VoiceDesc);
    @ISA = qw(Tie::StdHash);
}

sub FETCH {
    my($self,$voice) = @_;
    if (!%VoiceDesc) {
      foreach my $i (@{[1..Mac::Speech::CountVoices()]}) {
          my $voicet = Mac::Speech::GetIndVoice($i);
          my $voiced = ${Mac::Speech::GetVoiceDescription($voicet)};
          $VoiceDesc{$voiced} = $voicet;
      }
    }
  if (!$self->{$voice}) {
      foreach my $i (keys %VoiceDesc) {
          if ($i =~ /\Q$voice\E/) {
              $self->{$voice} = $VoiceDesc{$i};
              last;
          }
      }
  }
  $self->{$voice};
}

package Mac::Speech;

=head2 Variables

=over 4

=item %Voice

The C<%Voice> hash will return the index to the first voice matching
the given text.

=back

=cut

tie %Voice, q(Mac::Speech::_VoiceHash);

bootstrap Mac::Speech;

=head2 Constants

=over 4

=item kTextToSpeechSynthType

=item kTextToSpeechVoiceType

=item kTextToSpeechVoiceFileType

=item kTextToSpeechVoiceBundleType

Speech Types.

=cut
sub kTextToSpeechSynthType ()      {     'ttsc'; }
sub kTextToSpeechVoiceType ()      {     'ttvd'; }
sub kTextToSpeechVoiceFileType ()  {     'ttvf'; }
sub kTextToSpeechVoiceBundleType () {     'ttvb'; }


=item kNoEndingProsody

=item kNoSpeechInterrupt

=item kPreflightThenPause

Synthesizer flags.

=cut
sub kNoEndingProsody ()            {          1; }
sub kNoSpeechInterrupt ()          {          2; }
sub kPreflightThenPause ()         {          4; }


=item kImmediate

=item kEndOfWord

=item kEndOfSentence

Where to stop.

=cut
sub kImmediate ()                  {          0; }
sub kEndOfWord ()                  {          1; }
sub kEndOfSentence ()              {          2; }


=item kNeuter

=item kMale

=item kFemale

Genders.

=cut
sub kNeuter ()                     {          0; }
sub kMale ()                       {          1; }
sub kFemale ()                     {          2; }

=back

=include Speech.xs

=head1 BUGS/LIMITATIONS

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> Author

=cut

1;

__END__
