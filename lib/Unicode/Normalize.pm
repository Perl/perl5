package Unicode::Normalize;

use 5.006;
use strict;
use warnings;
use Carp;
use Lingua::KO::Hangul::Util;

our $VERSION = '0.04';
our $PACKAGE = __PACKAGE__;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( NFC NFD NFKC NFKD );
our @EXPORT_OK = qw( normalize );
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

our $Combin = do "unicore/CombiningClass.pl"
           || do "unicode/CombiningClass.pl"
           || croak "$PACKAGE: CombiningClass.pl not found";

our $Decomp = do "unicore/Decomposition.pl"
           || do "unicode/Decomposition.pl"
           || croak "$PACKAGE: Decomposition.pl not found";

our %Combin; # $codepoint => $number      : combination class
our %Canon;  # $codepoint => \@codepoints : canonical decomp.
our %Compat; # $codepoint => \@codepoints : compat. decomp.
our %Compos; # $string    => $codepoint   : composite
our %Exclus; # $codepoint => 1            : composition exclusions

{
  my($f, $fh);
  foreach my $d (@INC) {
    use File::Spec;
    $f = File::Spec->catfile($d, "unicore", "CompExcl.txt");
    last if open($fh, $f);
    $f = File::Spec->catfile($d, "unicode", "CompExcl.txt");
    last if open($fh, $f);
    $f = undef;
  }
  croak "$PACKAGE: CompExcl.txt not found in @INC" unless defined $f;
  while(<$fh>){
    next if /^#/ or /^$/;
    s/#.*//;
    $Exclus{ hex($1) } =1 if /([0-9A-Fa-f]+)/;
  }
  close $fh;
}

while($Combin =~ /(.+)/g)
{
  my @tab = split /\t/, $1;
  my $ini = hex $tab[0];
  if($tab[1] eq '')
  {
    $Combin{ $ini } = $tab[2];
  }
  else
  {
    $Combin{ $_ } = $tab[2] foreach $ini .. hex($tab[1]);
  }
}

while($Decomp =~ /(.+)/g)
{
  my @tab = split /\t/, $1;
  my $compat = $tab[2] =~ s/<[^>]+>//;
  my $dec = [ _getHexArray($tab[2]) ]; # decomposition
  my $com = pack('U*', @$dec); # composable sequence
  my $ini = hex($tab[0]);
  if($tab[1] eq '')
  {
    $Compat{ $ini } = $dec;
    if(! $compat){
      $Canon{  $ini } = $dec;
      $Compos{ $com } = $ini;
    }
  }
  else
  {
    foreach my $u ($ini .. hex($tab[1])){
      $Compat{ $u } = $dec;
      if(! $compat){
        $Canon{  $u }   = $dec;
        $Compos{ $com } = $ini;
      }
    }
  }
}

foreach my $key (keys %Canon)  # exhaustive decomposition
{
   $Canon{$key}  = [ getCanonList($key) ];
}

foreach my $key (keys %Compat) # exhaustive decomposition
{
   $Compat{$key} = [ getCompatList($key) ];
}

sub getCanonList
{
  my @src = @_;
  my @dec = map $Canon{$_} ? @{ $Canon{$_} } : $_, @src;
  join(" ",@src) eq join(" ",@dec) ? @dec : getCanonList(@dec);
  # condition @src == @dec is not ok.
}

sub getCompatList
{
  my @src = @_;
  my @dec = map $Compat{$_} ? @{ $Compat{$_} } : $_, @src;
  join(" ",@src) eq join(" ",@dec) ? @dec : getCompatList(@dec);
  # condition @src == @dec is not ok.
}

sub NFD($){ _decompose(shift, 0) }

sub NFKD($){ _decompose(shift, 1) }

sub NFC($){ _compose(NFD(shift)) }

sub NFKC($){ _compose(NFKD(shift)) }

sub normalize($$)
{
  my($form,$str) = @_;
  $form eq 'D'  || $form eq 'NFD'  ? NFD($str) :
  $form eq 'C'  || $form eq 'NFC'  ? NFC($str) :
  $form eq 'KD' || $form eq 'NFKD' ? NFKD($str) :
  $form eq 'KC' || $form eq 'NFKC' ? NFKC($str) :
    croak $PACKAGE."::normalize: invalid form name: $form";
}


##
## string _decompose(string, compat?)
##
sub _decompose
{
  my $str  = $_[0];
  my $hash = $_[1] ? \%Compat : \%Canon;
  my @ret;
  my $retstr="";
  foreach my $u (unpack 'U*', $str){
    push @ret,
      $hash->{ $u }  ? @{ $hash->{ $u } } :
      _isHangul($u) ? decomposeHangul($u) : $u;
  }
  for(my $i=0; $i<@ret;){
    $retstr .= pack('U', $ret[$i++]), next
       unless $Combin{ $ret[$i] } && $i+1 < @ret && $Combin{ $ret[$i+1] };
    my @tmp;
    push(@tmp, $ret[$i++]) while $i < @ret && $Combin{ $ret[$i] };
    $retstr .= pack 'U*', @tmp[
      sort {
        $Combin{ $tmp[$a] } <=> $Combin{ $tmp[$b] } || $a <=> $b
      } 0 .. @tmp - 1,
    ];
  }
  $retstr;
}

##
## string _compose(string)
##
## S : starter; NS : not starter;
##
## composable sequence begins at S.
## S + S or (S + S) + S may be composed.
## NS + NS must not be composed.
##
sub _compose
{
  my @src = unpack('U*', composeHangul shift); # get codepoints
  for(my $s = 0; $s+1 < @src; $s++){
    next unless defined $src[$s] && ! $Combin{ $src[$s] }; # S only
    my($c, $blocked);
    for(my $j = $s+1; $j < @src && !$blocked; $j++){
      $blocked = 1 if ! $Combin{ $src[$j] };

      next if $j != $s + 1 && defined $src[$j-1]
        && $Combin{ $src[$j-1] } && $Combin{ $src[$j] } 
        && $Combin{ $src[$j-1] } == $Combin{ $src[$j] };

      if(  # $c != 0, maybe.
        $c = $Compos{pack('U*', @src[$s,$j])} and ! $Exclus{$c}
      )
      {
        $src[$s] = $c; $src[$j] = undef; $blocked = 0;
      }
    }
  }
  pack 'U*', grep defined(), @src;
}

##
## "hhhh hhhh hhhh" to (dddd, dddd, dddd)
##
sub _getHexArray
{
  my $str = shift;
  map hex(), $str =~ /([0-9A-Fa-f]+)/g;
}

##
## Hangul Syllables
##
sub _isHangul
{
  my $code = shift;
  return 0xAC00 <= $code && $code <= 0xD7A3;
}

##
## for Debug
##
sub _getCombin { wantarray ? %Combin : \%Combin }
sub _getCanon  { wantarray ? %Canon  : \%Canon  }
sub _getCompat { wantarray ? %Compat : \%Compat }
sub _getCompos { wantarray ? %Compos : \%Compos }
sub _getExclus { wantarray ? %Exclus : \%Exclus }
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

=head2 EXPORT

C<NFC>, C<NFD>, C<NFKC>, C<NFKD>: by default.

C<normalize>: on request.

=head1 AUTHOR

SADAHIRO Tomoyuki, E<lt>SADAHIRO@cpan.orgE<gt>

  http://homepage1.nifty.com/nomenclator/perl/

  Copyright(C) 2001, SADAHIRO Tomoyuki. Japan. All rights reserved.

  This program is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<Lingua::KO::Hangul::Util>

utility functions for Hangul Syllables

=item http://www.unicode.org/unicode/reports/tr15/

Unicode Normalization Forms - UAX #15

=back

=cut
