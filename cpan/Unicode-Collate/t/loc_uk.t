#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 7;

my $objUk = Unicode::Collate::Locale->
    new(locale => 'UK', normalization => undef);

ok(1);
ok($objUk->getlocale, 'uk');

$objUk->change(level => 1);

ok($objUk->lt("\x{433}", "\x{491}"));
ok($objUk->gt("\x{434}", "\x{491}"));

# 4

$objUk->change(level => 2);

ok($objUk->eq("\x{491}", "\x{490}"));

$objUk->change(level => 3);

ok($objUk->lt("\x{491}", "\x{490}"));

$objUk->change(upper_before_lower => 1);

ok($objUk->gt("\x{491}", "\x{490}"));

# 7
