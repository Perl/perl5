# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use strict;
BEGIN { plan tests => 22 };
use Lingua::KO::Hangul::Util;
ok(1); # If we made it this far, we're ok.

#########################

sub unpk { 
  join ':', map sprintf("%04X", $_), 
     @_ == 1 ? unpack('U*', shift) : @_;
}

ok(getHangulName(0xAC00), "HANGUL SYLLABLE GA");
ok(getHangulName(0xAE00), "HANGUL SYLLABLE GEUL");
ok(getHangulName(0xC544), "HANGUL SYLLABLE A");
ok(getHangulName(0xD7A3), "HANGUL SYLLABLE HIH");
ok(getHangulName(0x11A3),  undef);
ok(getHangulName(0x0000),  undef);

ok(unpk(decomposeHangul(0xAC00)), "1100:1161");
ok(unpk(decomposeHangul(0xAE00)), "1100:1173:11AF");
ok(unpk(scalar decomposeHangul(0xAC00)), "1100:1161");
ok(unpk(scalar decomposeHangul(0xAE00)), "1100:1173:11AF");
ok(scalar decomposeHangul(0x0041), undef);
ok(scalar decomposeHangul(0x0000), undef);

ok(composeHangul("Hangul \x{1100}\x{1161}\x{1100}\x{1173}\x{11AF}."),
    "Hangul \x{AC00}\x{AE00}.");

ok(parseHangulName("HANGUL SYLLABLE GA"),   0xAC00);
ok(parseHangulName("HANGUL SYLLABLE GEUL"), 0xAE00);
ok(parseHangulName("HANGUL SYLLABLE A"),    0xC544);
ok(parseHangulName("HANGUL SYLLABLE HIH"),  0xD7A3);
ok(parseHangulName("HANGUL SYLLABLE PERL"), undef);
ok(parseHangulName("LATIN LETTER SMALL A"), undef);

my $ng;

$ng = 0;
foreach my $i (0xAC00..0xD7A3){
  $ng ++ if $i != parseHangulName(getHangulName($i));
}
ok($ng, 0);

$ng = 0;
foreach my $i (0xAC00..0xD7A3){
  $ng ++ if $i != (composeHangul scalar decomposeHangul($i))[0];
}
ok($ng, 0);
