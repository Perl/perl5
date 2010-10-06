#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 8;

my $objAr = Unicode::Collate::Locale->
    new(locale => 'AR', normalization => undef);

ok(1);
ok($objAr->getlocale, 'ar');

$objAr->change(level => 1);

ok($objAr->eq("\x{62A}", "\x{629}"));
ok($objAr->eq("\x{62A}", "\x{FE93}"));
ok($objAr->eq("\x{62A}", "\x{FE94}"));

$objAr->change(level => 3);

ok($objAr->eq("\x{62A}", "\x{629}"));
ok($objAr->eq("\x{62A}", "\x{FE93}"));
ok($objAr->eq("\x{62A}", "\x{FE94}"));

# 8
