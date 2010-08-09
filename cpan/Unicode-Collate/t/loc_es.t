#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 22;

my $objEs = Unicode::Collate::Locale->
    new(locale => 'ES', normalization => undef);

ok(1);
ok($objEs->getlocale, 'es');

$objEs->change(level => 1);

ok($objEs->lt("cg", "ch"));
ok($objEs->gt("ci", "ch"));
ok($objEs->gt("d", "ch"));
ok($objEs->lt("lk", "ll"));
ok($objEs->gt("lm", "ll"));
ok($objEs->gt("m", "ll"));
ok($objEs->lt("n", "n\x{303}"));
ok($objEs->gt("o", "n\x{303}"));

# 10

$objEs->change(level => 2);

ok($objEs->eq("ch", "Ch"));
ok($objEs->eq("Ch", "CH"));
ok($objEs->eq("ll", "Ll"));
ok($objEs->eq("Ll", "LL"));
ok($objEs->eq("n\x{303}", "N\x{303}"));

# 15

$objEs->change(level => 3);

ok($objEs->lt("ch", "Ch"));
ok($objEs->lt("Ch", "CH"));
ok($objEs->lt("ll", "Ll"));
ok($objEs->lt("Ll", "LL"));
ok($objEs->lt("n\x{303}", "N\x{303}"));
ok($objEs->eq("n\x{303}", pack('U', 0xF1)));
ok($objEs->eq("N\x{303}", pack('U', 0xD1)));

# 22
