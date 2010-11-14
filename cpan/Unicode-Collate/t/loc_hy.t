#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 13;

my $objHy = Unicode::Collate::Locale->
    new(locale => 'HY', normalization => undef);

ok(1);
ok($objHy->getlocale, 'hy');

$objHy->change(level => 1);

ok($objHy->lt("\x{584}", "\x{587}"));
ok($objHy->gt("\x{585}", "\x{587}"));

ok($objHy->lt("\x{584}\x{4E00}",  "\x{587}"));
ok($objHy->lt("\x{584}\x{20000}", "\x{587}"));
ok($objHy->lt("\x{584}\x{10FFFD}","\x{587}"));

# 7

$objHy->change(level => 2);

ok($objHy->eq("\x{587}", "\x{535}\x{582}"));

$objHy->change(level => 3);

ok($objHy->lt("\x{587}", "\x{535}\x{582}"));

$objHy->change(upper_before_lower => 1);

ok($objHy->gt("\x{587}", "\x{535}\x{582}"));

# 10

$objHy->change(UCA_Version => 8);

ok($objHy->lt("\x{584}\x{4E00}",  "\x{587}"));
ok($objHy->lt("\x{584}\x{20000}", "\x{587}"));
ok($objHy->lt("\x{584}\x{10FFFD}","\x{587}"));

# 13
