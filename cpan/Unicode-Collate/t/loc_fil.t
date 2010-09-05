#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 14;

my $objFil = Unicode::Collate::Locale->
    new(locale => 'FIL', normalization => undef);

ok(1);
ok($objFil->getlocale, 'fil');

$objFil->change(level => 1);

ok($objFil->lt("n", "n\x{303}"));
ok($objFil->lt("nz","n\x{303}"));
ok($objFil->lt("n\x{303}", "ng"));
ok($objFil->gt("o", "ng"));

# 6

$objFil->change(level => 2);

ok($objFil->eq("ng", "Ng"));
ok($objFil->eq("Ng", "NG"));
ok($objFil->eq("n\x{303}", "N\x{303}"));

# 9

$objFil->change(level => 3);

ok($objFil->lt("ng", "Ng"));
ok($objFil->lt("Ng", "NG"));
ok($objFil->lt("n\x{303}", "N\x{303}"));
ok($objFil->eq("n\x{303}", pack('U', 0xF1)));
ok($objFil->eq("N\x{303}", pack('U', 0xD1)));

# 14
