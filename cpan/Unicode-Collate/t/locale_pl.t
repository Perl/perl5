#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 70;

my $objPl = Unicode::Collate::Locale->
    new(locale => 'PL', normalization => undef);

ok(1);
ok($objPl->getlocale, 'pl');

$objPl->change(level => 1);

ok($objPl->lt("A", "A\x{328}"));
ok($objPl->lt("A", "a\x{328}"));
ok($objPl->gt("B", "A\x{328}"));
ok($objPl->gt("B", "a\x{328}"));

ok($objPl->lt("C", "C\x{301}"));
ok($objPl->lt("C", "c\x{301}"));
ok($objPl->gt("D", "C\x{301}"));
ok($objPl->gt("D", "c\x{301}"));

ok($objPl->lt("E", "E\x{328}"));
ok($objPl->lt("E", "e\x{328}"));
ok($objPl->gt("F", "E\x{328}"));
ok($objPl->gt("F", "e\x{328}"));

ok($objPl->lt("L", "\x{142}"));
ok($objPl->lt("L", "\x{141}"));
ok($objPl->gt("M", "\x{142}"));
ok($objPl->gt("M", "\x{141}"));

ok($objPl->lt("N", "N\x{301}"));
ok($objPl->lt("N", "n\x{301}"));
ok($objPl->gt("O", "N\x{301}"));
ok($objPl->gt("O", "n\x{301}"));

ok($objPl->lt("O", "O\x{301}"));
ok($objPl->lt("O", "o\x{301}"));
ok($objPl->gt("P", "O\x{301}"));
ok($objPl->gt("P", "o\x{301}"));

ok($objPl->lt("S", "S\x{301}"));
ok($objPl->lt("S", "s\x{301}"));
ok($objPl->gt("T", "S\x{301}"));
ok($objPl->gt("T", "s\x{301}"));

ok($objPl->lt("Z", "Z\x{301}"));
ok($objPl->lt("Z", "z\x{301}"));
ok($objPl->lt("Z", "Z\x{307}"));
ok($objPl->lt("Z", "z\x{307}"));

ok($objPl->lt("Z\x{301}", "Z\x{307}"));
ok($objPl->lt("Z\x{301}", "z\x{307}"));
ok($objPl->lt("Z\x{307}", "\x{292}")); # U+0292 EZH
ok($objPl->lt("Z\x{307}", "\x{292}"));

$objPl->change(level => 3);

ok($objPl->lt("a\x{328}", "\x{104}"));
ok($objPl->eq("a\x{328}", "\x{105}"));
ok($objPl->eq("A\x{328}", "\x{104}"));
ok($objPl->gt("A\x{328}", "\x{105}"));

ok($objPl->lt("c\x{301}", "\x{106}"));
ok($objPl->eq("c\x{301}", "\x{107}"));
ok($objPl->eq("C\x{301}", "\x{106}"));
ok($objPl->gt("C\x{301}", "\x{107}"));

ok($objPl->lt("e\x{328}", "\x{118}"));
ok($objPl->eq("e\x{328}", "\x{119}"));
ok($objPl->eq("E\x{328}", "\x{118}"));
ok($objPl->gt("E\x{328}", "\x{119}"));

ok($objPl->lt("n\x{301}", "\x{143}"));
ok($objPl->eq("n\x{301}", "\x{144}"));
ok($objPl->eq("N\x{301}", "\x{143}"));
ok($objPl->gt("N\x{301}", "\x{144}"));

ok($objPl->lt("o\x{301}", pack('U',0xD3)));
ok($objPl->eq("o\x{301}", pack('U',0xF3)));
ok($objPl->eq("O\x{301}", pack('U',0xD3)));
ok($objPl->gt("O\x{301}", pack('U',0xF3)));

ok($objPl->lt("s\x{301}", "\x{15A}"));
ok($objPl->eq("s\x{301}", "\x{15B}"));
ok($objPl->eq("S\x{301}", "\x{15A}"));
ok($objPl->gt("S\x{301}", "\x{15B}"));

ok($objPl->lt("z\x{301}", "\x{179}"));
ok($objPl->eq("z\x{301}", "\x{17A}"));
ok($objPl->eq("Z\x{301}", "\x{179}"));
ok($objPl->gt("Z\x{301}", "\x{17A}"));

ok($objPl->lt("z\x{307}", "\x{17B}"));
ok($objPl->eq("z\x{307}", "\x{17C}"));
ok($objPl->eq("Z\x{307}", "\x{17B}"));
ok($objPl->gt("Z\x{307}", "\x{17C}"));

