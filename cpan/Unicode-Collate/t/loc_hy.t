#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 7;

my $objHy = Unicode::Collate::Locale->
    new(locale => 'HY', normalization => undef);

ok(1);
ok($objHy->getlocale, 'hy');

$objHy->change(level => 1);

ok($objHy->lt("\x{584}", "\x{587}"));
ok($objHy->gt("\x{585}", "\x{587}"));

$objHy->change(level => 2);

ok($objHy->eq("\x{587}", "\x{535}\x{582}"));

$objHy->change(level => 3);

ok($objHy->lt("\x{587}", "\x{535}\x{582}"));

$objHy->change(upper_before_lower => 1);

ok($objHy->gt("\x{587}", "\x{535}\x{582}"));

# 7
