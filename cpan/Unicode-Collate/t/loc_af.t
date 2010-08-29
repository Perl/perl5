#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 8;

my $objAf = Unicode::Collate::Locale->
    new(locale => 'AF', normalization => undef);

ok(1);
ok($objAf->getlocale, 'af');

$objAf->change(level => 1);

ok($objAf->eq("n", "N"));
ok($objAf->eq("N", "\x{149}"));

$objAf->change(level => 2);

ok($objAf->eq("n", "N"));
ok($objAf->eq("N", "\x{149}"));

$objAf->change(level => 3);

ok($objAf->lt("n", "N"));
ok($objAf->lt("N", "\x{149}"));
