#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 104;

my $objNn = Unicode::Collate::Locale->
    new(locale => 'NN', normalization => undef);

my $ae   = pack 'U', 0xE6;
my $AE   = pack 'U', 0xC6;
my $auml = pack 'U', 0xE4;
my $Auml = pack 'U', 0xC4;
my $ostk = pack 'U', 0xF8;
my $Ostk = pack 'U', 0xD8;
my $ouml = pack 'U', 0xF6;
my $Ouml = pack 'U', 0xD6;
my $arng = pack 'U', 0xE5;
my $Arng = pack 'U', 0xC5;

my $eth  = pack 'U', 0xF0;
my $ETH  = pack 'U', 0xD0;
my $thrn = pack 'U', 0xFE;
my $THRN = pack 'U', 0xDE;
my $uuml = pack 'U', 0xFC;
my $Uuml = pack 'U', 0xDC;

ok(1);
ok($objNn->getlocale, 'nn');

$objNn->change(level => 1);

ok($objNn->lt("Z", $ae));
ok($objNn->lt("Z", $AE));
ok($objNn->lt($ae, $ostk));
ok($objNn->lt($AE, $Ostk));
ok($objNn->lt($ostk, $arng));
ok($objNn->lt($Ostk, $Arng));
ok($objNn->lt($arng, "\x{0292}"));
ok($objNn->lt($Arng, "\x{0292}"));

# 10

ok($objNn->eq('d', "\x{0111}"));
ok($objNn->eq('d', "\x{0110}"));
ok($objNn->eq('d', $eth));
ok($objNn->eq('d', $ETH));
ok($objNn->eq('th', $thrn));
ok($objNn->eq('th', $THRN));
ok($objNn->eq('y', "\x{0171}"));
ok($objNn->eq('y', "\x{0170}"));
ok($objNn->eq('y', "u\x{0308}"));
ok($objNn->eq('y', "U\x{0308}"));
ok($objNn->eq('y', $uuml));
ok($objNn->eq('y', $Uuml));
ok($objNn->eq('y', "u\x{030B}"));
ok($objNn->eq('y', "U\x{030B}"));

# 24

ok($objNn->eq($ae, $AE));
ok($objNn->eq($ae, "\x{1D2D}"));
ok($objNn->eq($ae, $auml));
ok($objNn->eq($ae, $Auml));
ok($objNn->eq($ae, "A\x{0308}"));
ok($objNn->eq($ae, "a\x{0308}"));
ok($objNn->eq($ostk, $Ostk));
ok($objNn->eq($ostk, $ouml));
ok($objNn->eq($ostk, $Ouml));
ok($objNn->eq($ostk, "o\x{0308}"));
ok($objNn->eq($ostk, "O\x{0308}"));
ok($objNn->eq($ostk, "\x{0151}"));
ok($objNn->eq($ostk, "\x{0150}"));
ok($objNn->eq($ostk, "o\x{030B}"));
ok($objNn->eq($ostk, "O\x{030B}"));
ok($objNn->eq($arng, $Arng));
ok($objNn->eq($arng, "a\x{030A}"));
ok($objNn->eq($arng, "A\x{030A}"));
ok($objNn->eq($arng, "\x{212B}"));

# 43

$objNn->change(level => 2);

ok($objNn->lt('d', "\x{0111}"));
ok($objNn->lt('d', "\x{0110}"));
ok($objNn->lt('d', $eth));
ok($objNn->lt('d', $ETH));
ok($objNn->eq('th', $thrn));
ok($objNn->eq('TH', $THRN));
ok($objNn->lt('y', "\x{0171}"));
ok($objNn->lt('y', "\x{0170}"));
ok($objNn->lt('y', "u\x{0308}"));
ok($objNn->lt('y', "U\x{0308}"));
ok($objNn->lt('y', $uuml));
ok($objNn->lt('y', $Uuml));
ok($objNn->lt('y', "u\x{030B}"));
ok($objNn->lt('y', "U\x{030B}"));

ok($objNn->eq("\x{0111}", "\x{0110}"));
ok($objNn->eq("\x{0171}", "\x{0170}"));
ok($objNn->eq($eth,  $ETH));
ok($objNn->eq($thrn, $THRN));
ok($objNn->eq($uuml, $Uuml));

# 62

ok($objNn->eq($ae, $AE));
ok($objNn->eq($ae, "\x{1D2D}"));
ok($objNn->eq($auml, $Auml));
ok($objNn->eq($ostk, $Ostk));
ok($objNn->eq($ouml, $Ouml));
ok($objNn->eq("\x{0151}", "\x{0150}"));
ok($objNn->eq($ouml, "o\x{0308}"));
ok($objNn->eq($Ouml, "O\x{0308}"));
ok($objNn->lt($ostk, "o\x{030B}"));
ok($objNn->lt($Ostk, "O\x{030B}"));
ok($objNn->lt($ostk, "\x{0151}"));
ok($objNn->lt($Ostk, "\x{0150}"));
ok($objNn->eq($arng, $Arng));
ok($objNn->eq($arng, "a\x{030A}"));
ok($objNn->eq($arng, "A\x{030A}"));
ok($objNn->eq($arng, "\x{212B}"));

# 78

$objNn->change(level => 3);

ok($objNn->lt("\x{0111}", "\x{0110}"));
ok($objNn->lt("\x{0171}", "\x{0170}"));
ok($objNn->lt($eth,  $ETH));
ok($objNn->lt('th', $thrn));
ok($objNn->lt($thrn, 'TH'));
ok($objNn->lt('TH', $THRN));
ok($objNn->lt($uuml, $Uuml));

ok($objNn->lt($ae, $AE));
ok($objNn->lt($ae, "\x{1D2D}"));
ok($objNn->lt($auml, $Auml));
ok($objNn->lt($ostk, $Ostk));
ok($objNn->lt($ouml, $Ouml));
ok($objNn->lt($arng, $Arng));
ok($objNn->lt("\x{01FD}", "\x{01FC}"));
ok($objNn->lt("\x{01E3}", "\x{01E2}"));
ok($objNn->lt("\x{01FF}", "\x{01FE}"));
ok($objNn->lt("\x{0151}", "\x{0150}"));
ok($objNn->lt("\x{01FB}", "\x{01FA}"));

# 96

ok($objNn->eq("\x{01FD}",   $ae."\x{0301}"));
ok($objNn->eq("\x{01FC}",   $AE."\x{0301}"));
ok($objNn->eq("\x{01E3}",   $ae."\x{0304}"));
ok($objNn->eq("\x{01E2}",   $AE."\x{0304}"));
ok($objNn->eq("\x{01FF}", $ostk."\x{0301}"));
ok($objNn->eq("\x{01FE}", $Ostk."\x{0301}"));
ok($objNn->eq("\x{01FB}", $arng."\x{0301}"));
ok($objNn->eq("\x{01FA}", $Arng."\x{0301}"));

# 104
