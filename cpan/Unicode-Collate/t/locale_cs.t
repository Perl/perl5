#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 50;

my $objCs = Unicode::Collate::Locale->
    new(locale => 'CS', normalization => undef);

ok(1);
ok($objCs->getlocale, 'cs');

$objCs->change(level => 1);

ok($objCs->lt("C", "C\x{30C}"));
ok($objCs->lt("C", "c\x{30C}"));
ok($objCs->gt("D", "C\x{30C}"));
ok($objCs->gt("D", "c\x{30C}"));

ok($objCs->lt("H", "ch"));
ok($objCs->lt("H", "cH"));
ok($objCs->lt("H", "Ch"));
ok($objCs->lt("H", "CH"));

ok($objCs->gt("I", "ch"));
ok($objCs->gt("I", "cH"));
ok($objCs->gt("I", "Ch"));
ok($objCs->gt("I", "CH"));

ok($objCs->lt("R", "R\x{30C}"));
ok($objCs->lt("R", "r\x{30C}"));
ok($objCs->gt("S", "R\x{30C}"));
ok($objCs->gt("S", "r\x{30C}"));

ok($objCs->lt("S", "S\x{30C}"));
ok($objCs->lt("S", "s\x{30C}"));
ok($objCs->gt("T", "S\x{30C}"));
ok($objCs->gt("T", "s\x{30C}"));

ok($objCs->lt("Z", "Z\x{30C}"));
ok($objCs->lt("Z", "z\x{30C}"));

ok($objCs->gt("\x{188}", "C\x{30C}"));	# c-hook > C-caron
ok($objCs->gt("\x{188}", "c\x{30C}"));	# c-hook > c-caron
ok($objCs->gt("\x{1B6}", "Z\x{30C}"));	# z-stroke > Z-caron
ok($objCs->gt("\x{1B6}", "z\x{30C}"));	# z-stroke > z-caron
ok($objCs->gt("\x{1B5}", "Z\x{30C}"));	# Z-stroke > Z-caron
ok($objCs->gt("\x{1B5}", "z\x{30C}"));	# Z-stroke > z-caron

$objCs->change(level => 3);

ok($objCs->lt("c\x{30C}", "\x{10C}"));
ok($objCs->eq("c\x{30C}", "\x{10D}"));
ok($objCs->eq("C\x{30C}", "\x{10C}"));
ok($objCs->gt("C\x{30C}", "\x{10D}"));

ok($objCs->lt("r\x{30C}", "\x{158}"));
ok($objCs->eq("r\x{30C}", "\x{159}"));
ok($objCs->eq("R\x{30C}", "\x{158}"));
ok($objCs->gt("R\x{30C}", "\x{159}"));

ok($objCs->lt("s\x{30C}", "\x{160}"));
ok($objCs->eq("s\x{30C}", "\x{161}"));
ok($objCs->eq("S\x{30C}", "\x{160}"));
ok($objCs->gt("S\x{30C}", "\x{161}"));

ok($objCs->lt("z\x{30C}", "\x{17D}"));
ok($objCs->eq("z\x{30C}", "\x{17E}"));
ok($objCs->eq("Z\x{30C}", "\x{17D}"));
ok($objCs->gt("Z\x{30C}", "\x{17E}"));

ok($objCs->lt("ch", "cH"));
ok($objCs->lt("cH", "Ch"));
ok($objCs->lt("Ch", "CH"));
ok($objCs->lt("ch", "CH"));

