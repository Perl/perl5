#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 20;

my $objSl = Unicode::Collate::Locale->
    new(locale => 'SL', normalization => undef);

ok(1);
ok($objSl->getlocale, 'sl');

$objSl->change(level => 1);

ok($objSl->lt("c", "c\x{30C}"));
ok($objSl->gt("d", "c\x{30C}"));
ok($objSl->lt("s", "s\x{30C}"));
ok($objSl->gt("t", "s\x{30C}"));
ok($objSl->lt("z", "z\x{30C}"));
ok($objSl->lt("z\x{30C}", "\x{292}")); # U+0292 EZH

# 8

$objSl->change(level => 2);

ok($objSl->eq("c\x{30C}", "C\x{30C}"));
ok($objSl->eq("s\x{30C}", "S\x{30C}"));
ok($objSl->eq("z\x{30C}", "Z\x{30C}"));

# 11

$objSl->change(level => 3);

ok($objSl->lt("c\x{30C}", "C\x{30C}"));
ok($objSl->lt("s\x{30C}", "S\x{30C}"));
ok($objSl->lt("z\x{30C}", "Z\x{30C}"));

# 14

ok($objSl->eq("c\x{30C}", "\x{10D}"));
ok($objSl->eq("C\x{30C}", "\x{10C}"));
ok($objSl->eq("s\x{30C}", "\x{161}"));
ok($objSl->eq("S\x{30C}", "\x{160}"));
ok($objSl->eq("z\x{30C}", "\x{17E}"));
ok($objSl->eq("Z\x{30C}", "\x{17D}"));

# 20
