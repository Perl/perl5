package Unicode::Normalize;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.12';
our $PACKAGE = __PACKAGE__;

require Exporter;
require DynaLoader;
require AutoLoader;

our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw( NFC NFD NFKC NFKD );
our @EXPORT_OK = qw(
    normalize decompose reorder compose
    getCanon getCompat getComposite getCombinClass isExclusion
);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

bootstrap Unicode::Normalize $VERSION;

use constant CANON  => 0;
use constant COMPAT => 1;

sub NFD  ($) { reorder(decompose($_[0], CANON )) }
sub NFKD ($) { reorder(decompose($_[0], COMPAT)) }

sub NFC  ($) { compose(reorder(decompose($_[0], CANON ))) }
sub NFKC ($) { compose(reorder(decompose($_[0], COMPAT))) }

sub normalize($$)
{
  my $form = shift;
  $form =~ s/NF//;
  $form eq 'D'  ? NFD ($_[0]) :
  $form eq 'C'  ? NFC ($_[0]) :
  $form eq 'KD' ? NFKD($_[0]) :
  $form eq 'KC' ? NFKC($_[0]) :
    croak $PACKAGE."::normalize: invalid form name: $form";
}

1;
__END__

=head1 NAME

Unicode::Normalize - normalized forms of Unicode text

=head1 SYNOPSIS

  use Unicode::Normalize;

  $string_NFD  = NFD($raw_string);  # Normalization Form D
  $string_NFC  = NFC($raw_string);  # Normalization Form C
  $string_NFKD = NFKD($raw_string); # Normalization Form KD
  $string_NFKC = NFKC($raw_string); # Normalization Form KC

   or

  use Unicode::Normalize 'normalize';

  $string_NFD  = normalize('D',  $raw_string);  # Normalization Form D
  $string_NFC  = normalize('C',  $raw_string);  # Normalization Form C
  $string_NFKD = normalize('KD', $raw_string);  # Normalization Form KD
  $string_NFKC = normalize('KC', $raw_string);  # Normalization Form KC

=head1 DESCRIPTION

=head2 Normalization

=over 4

=item C<$string_NFD = NFD($raw_string)>

returns the Normalization Form D (formed by canonical decomposition).


=item C<$string_NFC = NFC($raw_string)>

returns the Normalization Form C (formed by canonical decomposition
followed by canonical composition).

=item C<$string_NFKD = NFKD($raw_string)>

returns the Normalization Form KD (formed by compatibility decomposition).

=item C<$string_NFKC = NFKC($raw_string)>

returns the Normalization Form KC (formed by compatibility decomposition
followed by B<canonical> composition).

=item C<$normalized_string = normalize($form_name, $raw_string)>

As C<$form_name>, one of the following names must be given.

  'C'  or 'NFC'  for Normalization Form C
  'D'  or 'NFD'  for Normalization Form D
  'KC' or 'NFKC' for Normalization Form KC
  'KD' or 'NFKD' for Normalization Form KD

=back

=head2 Character Data

These functions are interface of character data used internally.
If you want only to get unicode normalization forms, 
you need not to call them by yourself.

=over 4

=item C<$canonical_decomposed = getCanon($codepoint)>

=item C<$compatibility_decomposed = getCompat($codepoint)>

If the character of the specified codepoint is canonically or 
compatibility decomposable (including Hangul Syllables),
returns the B<completely decomposed> string equivalent to it.

If it is not decomposable, returns undef.

=item C<$uv_composite = getComposite($uv_here, $uv_next)>

If the couple of two characters here and next (as codepoints) is composable
(including Hangul Jamo/Syllables and Exclusions),
returns the codepoint of the composite.

If they are not composable, returns undef.

=item C<$combining_class = getCombinClass($codepoint)>

Returns the combining class as integer of the character.

=item C<$is_exclusion = isExclusion($codepoint)>

Returns a boolean whether the character of the specified codepoint is
a composition exclusion.

=back

=head2 EXPORT

C<NFC>, C<NFD>, C<NFKC>, C<NFKD>: by default.

C<normalize> and other some functions: on request.

=head1 AUTHOR

SADAHIRO Tomoyuki, E<lt>SADAHIRO@cpan.orgE<gt>

  http://homepage1.nifty.com/nomenclator/perl/

  Copyright(C) 2001, SADAHIRO Tomoyuki. Japan. All rights reserved.

  This program is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item http://www.unicode.org/unicode/reports/tr15/

Unicode Normalization Forms - UAX #15

=back

=cut

