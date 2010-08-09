#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 22;

my $objEsTrad = Unicode::Collate::Locale->
    new(locale => 'ES-trad', normalization => undef);

ok(1);
ok($objEsTrad->getlocale, 'es__traditional');

$objEsTrad->change(level => 1);

ok($objEsTrad->lt("c", "ch"));
ok($objEsTrad->lt("cz","ch"));
ok($objEsTrad->gt("d", "ch"));
ok($objEsTrad->lt("l", "ll"));
ok($objEsTrad->lt("lz","ll"));
ok($objEsTrad->gt("m", "ll"));
ok($objEsTrad->lt("n", "n\x{303}"));
ok($objEsTrad->gt("o", "n\x{303}"));

# 10

$objEsTrad->change(level => 2);

ok($objEsTrad->eq("ch", "Ch"));
ok($objEsTrad->eq("Ch", "CH"));
ok($objEsTrad->eq("ll", "Ll"));
ok($objEsTrad->eq("Ll", "LL"));
ok($objEsTrad->eq("n\x{303}", "N\x{303}"));

# 15

$objEsTrad->change(level => 3);

ok($objEsTrad->lt("ch", "Ch"));
ok($objEsTrad->lt("Ch", "CH"));
ok($objEsTrad->lt("ll", "Ll"));
ok($objEsTrad->lt("Ll", "LL"));
ok($objEsTrad->lt("n\x{303}", "N\x{303}"));
ok($objEsTrad->eq("n\x{303}", pack('U', 0xF1)));
ok($objEsTrad->eq("N\x{303}", pack('U', 0xD1)));

# 22
