package Lingua::KO::Hangul::Util;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ();
our @EXPORT_OK = ();
our @EXPORT = qw(
  decomposeHangul
  composeHangul
  getHangulName
  parseHangulName
);
our $VERSION = '0.02';

our @JamoL = ( # Initial (HANGUL CHOSEONG)
    "G", "GG", "N", "D", "DD", "R", "M", "B", "BB",
    "S", "SS", "", "J", "JJ", "C", "K", "T", "P", "H",
  );

our @JamoV = ( # Medial  (HANGUL JUNGSEONG)
    "A", "AE", "YA", "YAE", "EO", "E", "YEO", "YE", "O",
    "WA", "WAE", "OE", "YO", "U", "WEO", "WE", "WI",
    "YU", "EU", "YI", "I",
  );

our @JamoT = ( # Final    (HANGUL JONGSEONG)
    "", "G", "GG", "GS", "N", "NJ", "NH", "D", "L", "LG", "LM",
    "LB", "LS", "LT", "LP", "LH", "M", "B", "BS",
    "S", "SS", "NG", "J", "C", "K", "T", "P", "H",
  );

our $BlockName = "HANGUL SYLLABLE ";

use constant SBase  => 0xAC00;
use constant LBase  => 0x1100;
use constant VBase  => 0x1161;
use constant TBase  => 0x11A7;
use constant LCount => 19;     # scalar @JamoL
use constant VCount => 21;     # scalar @JamoV
use constant TCount => 28;     # scalar @JamoT
use constant NCount => 588;    # VCount * TCount
use constant SCount => 11172;  # LCount * NCount
use constant SFinal => 0xD7A3; # SBase -1 + SCount

our(%CodeL, %CodeV, %CodeT);
@CodeL{@JamoL} = 0 .. LCount-1;
@CodeV{@JamoV} = 0 .. VCount-1;
@CodeT{@JamoT} = 0 .. TCount-1;

sub getHangulName {
    my $code = shift;
    return undef unless SBase <= $code && $code <= SFinal;
    my $SIndex = $code - SBase;
    my $LIndex = int( $SIndex / NCount);
    my $VIndex = int(($SIndex % NCount) / TCount);
    my $TIndex =      $SIndex % TCount;
    "$BlockName$JamoL[$LIndex]$JamoV[$VIndex]$JamoT[$TIndex]";
}

sub parseHangulName {
    my $arg = shift;
    return undef unless $arg =~ s/$BlockName//o;
    return undef unless $arg =~ /^([^AEIOUWY]*)([AEIOUWY]+)([^AEIOUWY]*)$/;
    return undef unless  exists $CodeL{$1}
		&& exists $CodeV{$2}
		&& exists $CodeT{$3};
    SBase + $CodeL{$1} * NCount + $CodeV{$2} * TCount + $CodeT{$3};
}

sub decomposeHangul {
    my $code = shift;
    return unless SBase <= $code && $code <= SFinal;
    my $SIndex = $code - SBase;
    my $LIndex = int( $SIndex / NCount);
    my $VIndex = int(($SIndex % NCount) / TCount);
    my $TIndex =      $SIndex % TCount;
    my @ret = (
       LBase + $LIndex,
       VBase + $VIndex,
      $TIndex ? (TBase + $TIndex) : (),
    );
    wantarray ? @ret : pack('U*', @ret);
}

#
# To Do:
#  s/(\p{JamoL}\p{JamoV})/toHangLV($1)/ge;
#  s/(\p{HangLV}\p{JamoT})/toHangLVT($1)/ge;
#
sub composeHangul {
    my $str = shift;
    return $str unless length $str;
    my(@ret);

    foreach my $ch (unpack('U*', $str)) # Makes list! The string be short!
    {
      push(@ret, $ch) and next unless @ret;

      # 1. check to see if $ret[-1] is L and $ch is V.
      my $LIndex = $ret[-1] - LBase;
      if(0 <= $LIndex && $LIndex < LCount)
      {
        my $VIndex = $ch - VBase;
        if(0 <= $VIndex && $VIndex < VCount)
        {
          $ret[-1] = SBase + ($LIndex * VCount + $VIndex) * TCount;
          next; # discard $ch
        }
      }

      # 2. check to see if $ret[-1] is LV and $ch is T.
      my $SIndex = $ret[-1] - SBase;
      if(0 <= $SIndex && $SIndex < SCount && $SIndex % TCount == 0)
      {
        my $TIndex = $ch - TBase;
        if(0 <= $TIndex && $TIndex < TCount)
        {
          $ret[-1] += $TIndex;
          next; # discard $ch
        }
      }

      # 3. just append $ch
      push(@ret, $ch);
    }
    wantarray ? @ret : pack('U*', @ret);
}

1;
__END__

=head1 NAME

Lingua::KO::Hangul::Util - utility functions for Hangul Syllables

=head1 SYNOPSIS

  use Lingua::KO::Hangul::Util;

  decomposeHangul(0xAC00);
    # (0x1100,0x1161) or "\x{1100}\x{1161}"

  composeHangul("\x{1100}\x{1161}");
    # "\x{AC00}"

  getHangulName(0xAC00);
    # "HANGUL SYLLABLE GA"

  parseHangulName("HANGUL SYLLABLE GA");
    # 0xAC00

=head1 DESCRIPTION

A Hangul syllable consists of Hangul Jamo.

Hangul Jamo are classified into three classes:

  CHOSEONG  (the initial sound) as a leading consonant (L),
  JUNGSEONG (the medial sound)  as a vowel (V),
  JONGSEONG (the final sound)   as a trailing consonant (T).

Any Hangul syllable is a composition of

   i) CHOSEONG + JUNGSEONG (L + V)

    or

  ii) CHOSEONG + JUNGSEONG + JONGSEONG (L + V + T).

Names of Hangul Syllables have a format of C<"HANGUL SYLLABLE %s">.

=head2 Composition and Decomposition

=over 4

=item C<$string_decomposed = decomposeHangul($codepoint)>

=item C<@codepoints = decomposeHangul($codepoint)>

Accepts unicode codepoint integer.

If the specified codepoint is of a Hangul syllable,
returns a list of codepoints (in a list context)
or a UTF-8 string (in a scalar context)
of its decomposition.

   decomposeHangul(0xAC00) # U+AC00 is HANGUL SYLLABLE GA.
      returns "\x{1100}\x{1161}" or (0x1100, 0x1161);

   decomposeHangul(0xAE00) # U+AE00 is HANGUL SYLLABLE GEUL.
      returns "\x{1100}\x{1173}\x{11AF}" or (0x1100, 0x1173, 0x11AF);

Otherwise, returns false (empty string or empty list).

   decomposeHangul(0x0041) # outside Hangul Syllables
      returns empty string or empty list.

=item C<$string_composed = composeHangul($src_string)>

=item C<@codepoints_composed = composeHangul($src_string)>

Any sequence of an initial Jamo C<L> and a medial Jamo C<V>
is composed into a syllable C<LV>;
then any sequence of a syllable C<LV> and a final Jamo C<T>
is composed into a syllable C<LVT>.

Any characters other than Hangul Jamo and Hangul Syllables
are unaffected.

   composeHangul("Hangul \x{1100}\x{1161}\x{1100}\x{1173}\x{11AF}.")
    returns "Hangul \x{AC00}\x{AE00}." or
     (0x48,0x61,0x6E,0x67,0x75,0x6C,0x20,0xAC00,0xAE00,0x2E);

=back

=head2 Hangul Syllable Name

=over 4

=item C<$name = getHangulName($codepoint)>

If the specified codepoint is of a Hangul syllable,
returns its name; otherwise returns undef.

   getHangulName(0xAC00) returns "HANGUL SYLLABLE GA";
   getHangulName(0x0041) returns undef.

=item C<$codepoint = parseHangulName($name)>

If the specified name is of a Hangul syllable,
returns its codepoint; otherwise returns undef. 

   parseHangulName("HANGUL SYLLABLE GEUL") returns 0xAE00;

   parseHangulName("LATIN SMALL LETTER A") returns undef;

   parseHangulName("HANGUL SYLLABLE PERL") returns undef;
    # Regrettably, HANGUL SYLLABLE PERL does not exist :-)

=back

=head2 EXPORT

By default,

  decomposeHangul
  composeHangul
  getHangulName
  parseHangulName

=head1 AUTHOR

SADAHIRO Tomoyuki 

  bqw10602@nifty.com
  http://homepage1.nifty.com/nomenclator/perl/

  Copyright(C) 2001, SADAHIRO Tomoyuki. Japan. All rights reserved.

  This program is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item http://www.unicode.org/unicode/reports/tr15

Annex 10: Hangul, in Unicode Normalization Forms (UAX #15).

=back

=cut
