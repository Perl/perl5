# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use strict;
use warnings;
BEGIN { plan tests => 18 };
use Unicode::Normalize qw(normalize);
ok(1); # If we made it this far, we're ok.

#########################

ok(normalize('C', ""), "");
ok(normalize('D', ""), "");

sub hexNFC {
  join " ", map sprintf("%04X", $_),
  unpack 'U*', normalize 'C', pack 'U*', map hex(), split ' ', shift;
}
sub hexNFD {
  join " ", map sprintf("%04X", $_),
  unpack 'U*', normalize 'NFD', pack 'U*', map hex(), split ' ', shift;
}

my $ordA   = ord("A");
my $ASCII  = $ordA == 0x41;
my $EBCDIC = $ordA == 0xc1;

if ($ASCII) {
  ok(hexNFC("0061 0315 0300 05AE 05C4 0062"), "00E0 05AE 05C4 0315 0062");
  ok(hexNFC("00E0 05AE 05C4 0315 0062"),      "00E0 05AE 05C4 0315 0062");
  ok(hexNFC("0061 05AE 0300 05C4 0315 0062"), "00E0 05AE 05C4 0315 0062");
} elsif ($EBCDIC) {
  # A WITH GRAVE  is 0044 in EBCDIC, not 00E0
  # SMALL LATIN B is 0082 in EBCDIC, not 0062
  ok(hexNFC("0061 0315 0300 05AE 05C4 0062"), "0044 05AE 05C4 0315 0082");
  ok(hexNFC("00E0 05AE 05C4 0315 0062"),      "0044 05AE 05C4 0315 0082");
  ok(hexNFC("0061 05AE 0300 05C4 0315 0062"), "0044 05AE 05C4 0315 0082");
} else {
  skip("Neither ASCII nor EBCDIC based") for 1..3;
}

ok(hexNFC("0045 0304 0300 AC00 11A8"), "1E14 AC01");
ok(hexNFC("1100 1161 1100 1173 11AF"), "AC00 AE00");
ok(hexNFC("1100 0300 1161 1173 11AF"), "1100 0300 1161 1173 11AF");

ok(hexNFD("0061 0315 0300 05AE 05C4 0062"), "0061 05AE 0300 05C4 0315 0062");
ok(hexNFD("00E0 05AE 05C4 0315 0062"),      "0061 05AE 0300 05C4 0315 0062");
ok(hexNFD("0061 05AE 0300 05C4 0315 0062"), "0061 05AE 0300 05C4 0315 0062");

if ($ASCII) {
  ok(hexNFC("0061 05C4 0315 0300 05AE 0062"), "0061 05AE 05C4 0300 0315 0062");
  ok(hexNFC("0061 05AE 05C4 0300 0315 0062"), "0061 05AE 05C4 0300 0315 0062");
} elsif ($EBCDIC) {
  # SMALL LATIN A is 0081 in EBCDIC, not 0061
  # SMALL LATIN B is 0082 in EBCDIC, not 0062
  ok(hexNFC("0061 05C4 0315 0300 05AE 0062"), "0081 05AE 05C4 0300 0315 0082");
  ok(hexNFC("0061 05AE 05C4 0300 0315 0062"), "0081 05AE 05C4 0300 0315 0082");
} else {
  skip("Neither ASCII nor EBCDIC based") for 1..2;
}

ok(hexNFD("0061 05C4 0315 0300 05AE 0062"), "0061 05AE 05C4 0300 0315 0062");
ok(hexNFD("0061 05AE 05C4 0300 0315 0062"), "0061 05AE 05C4 0300 0315 0062");

if ($ASCII) {
  ok(hexNFC("0000 0041 0000 0000"), "0000 0041 0000 0000");
} elsif ($EBCDIC) {
  # CAPITAL LATIN A is 00C1 in EBCDIC, not 0041
  ok(hexNFC("0000 0041 0000 0000"), "0000 00C1 0000 0000");
} else {
  skip("Neither ASCII nor EBCDIC based");
}

ok(hexNFD("0000 0041 0000 0000"), "0000 0041 0000 0000");

