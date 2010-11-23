
BEGIN {
    unless ("A" eq pack('U', 0x41)) {
	print "1..0 # Unicode::Collate " .
	    "cannot stringify a Unicode code point\n";
	exit 0;
    }
    if ($ENV{PERL_CORE}) {
	chdir('t') if -d 't';
	@INC = $^O eq 'MacOS' ? qw(::lib) : qw(../lib);
    }
}

use Test;
BEGIN { plan tests => 302 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objZhP = Unicode::Collate::Locale->
    new(locale => 'ZH__pinyin', normalization => undef);

ok($objZhP->getlocale, 'zh__pinyin');

$objZhP->change(level => 1);

ok($objZhP->eq("a\x{304}", "a\x{301}"));
ok($objZhP->eq("a\x{301}", "a\x{30C}"));
ok($objZhP->eq("a\x{30C}", "a\x{300}"));
ok($objZhP->eq("a\x{300}", "a"));
ok($objZhP->eq("e\x{304}", "e\x{301}"));
ok($objZhP->eq("e\x{301}", "e\x{30C}"));
ok($objZhP->eq("e\x{30C}", "e\x{300}"));
ok($objZhP->eq("e\x{300}", "e"));
ok($objZhP->eq("e\x{302}\x{304}", "e\x{302}\x{301}"));
ok($objZhP->eq("e\x{302}\x{301}", "e\x{302}\x{30C}"));
ok($objZhP->eq("e\x{302}\x{30C}", "e\x{302}\x{300}"));
ok($objZhP->eq("e\x{302}\x{300}", "e\x{302}"));
ok($objZhP->eq("i\x{304}", "i\x{301}"));
ok($objZhP->eq("i\x{301}", "i\x{30C}"));
ok($objZhP->eq("i\x{30C}", "i\x{300}"));
ok($objZhP->eq("i\x{300}", "i"));
ok($objZhP->eq("m\x{304}", "m\x{301}"));
ok($objZhP->eq("m\x{301}", "m\x{30C}"));
ok($objZhP->eq("m\x{30C}", "m\x{300}"));
ok($objZhP->eq("m\x{300}", "m"));
ok($objZhP->eq("n\x{304}", "n\x{301}"));
ok($objZhP->eq("n\x{301}", "n\x{30C}"));
ok($objZhP->eq("n\x{30C}", "n\x{300}"));
ok($objZhP->eq("n\x{300}", "n"));
ok($objZhP->eq("o\x{304}", "o\x{301}"));
ok($objZhP->eq("o\x{301}", "o\x{30C}"));
ok($objZhP->eq("o\x{30C}", "o\x{300}"));
ok($objZhP->eq("o\x{300}", "o"));
ok($objZhP->eq("u\x{304}", "u\x{301}"));
ok($objZhP->eq("u\x{301}", "u\x{30C}"));
ok($objZhP->eq("u\x{30C}", "u\x{300}"));
ok($objZhP->eq("u\x{300}", "u"));
ok($objZhP->eq("u\x{308}\x{304}", "u\x{308}\x{301}"));
ok($objZhP->eq("u\x{308}\x{301}", "u\x{308}\x{30C}"));
ok($objZhP->eq("u\x{308}\x{30C}", "u\x{308}\x{300}"));
ok($objZhP->eq("u\x{308}\x{300}", "u\x{308}"));

# 38

$objZhP->change(level => 2);

ok($objZhP->lt("a\x{304}", "a\x{301}"));
ok($objZhP->lt("a\x{301}", "a\x{30C}"));
ok($objZhP->lt("a\x{30C}", "a\x{300}"));
ok($objZhP->lt("a\x{300}", "a"));
ok($objZhP->lt("e\x{304}", "e\x{301}"));
ok($objZhP->lt("e\x{301}", "e\x{30C}"));
ok($objZhP->lt("e\x{30C}", "e\x{300}"));
ok($objZhP->lt("e\x{300}", "e"));
ok($objZhP->lt("e\x{302}\x{304}", "e\x{302}\x{301}"));
ok($objZhP->lt("e\x{302}\x{301}", "e\x{302}\x{30C}"));
ok($objZhP->lt("e\x{302}\x{30C}", "e\x{302}\x{300}"));
ok($objZhP->lt("e\x{302}\x{300}", "e\x{302}"));
ok($objZhP->lt("i\x{304}", "i\x{301}"));
ok($objZhP->lt("i\x{301}", "i\x{30C}"));
ok($objZhP->lt("i\x{30C}", "i\x{300}"));
ok($objZhP->lt("i\x{300}", "i"));
ok($objZhP->lt("m\x{304}", "m\x{301}"));
ok($objZhP->lt("m\x{301}", "m\x{30C}"));
ok($objZhP->lt("m\x{30C}", "m\x{300}"));
ok($objZhP->lt("m\x{300}", "m"));
ok($objZhP->lt("n\x{304}", "n\x{301}"));
ok($objZhP->lt("n\x{301}", "n\x{30C}"));
ok($objZhP->lt("n\x{30C}", "n\x{300}"));
ok($objZhP->lt("n\x{300}", "n"));
ok($objZhP->lt("o\x{304}", "o\x{301}"));
ok($objZhP->lt("o\x{301}", "o\x{30C}"));
ok($objZhP->lt("o\x{30C}", "o\x{300}"));
ok($objZhP->lt("o\x{300}", "o"));
ok($objZhP->lt("u\x{304}", "u\x{301}"));
ok($objZhP->lt("u\x{301}", "u\x{30C}"));
ok($objZhP->lt("u\x{30C}", "u\x{300}"));
ok($objZhP->lt("u\x{300}", "u"));
ok($objZhP->lt("u\x{308}\x{304}", "u\x{308}\x{301}"));
ok($objZhP->lt("u\x{308}\x{301}", "u\x{308}\x{30C}"));
ok($objZhP->lt("u\x{308}\x{30C}", "u\x{308}\x{300}"));
ok($objZhP->lt("u\x{308}\x{300}", "u\x{308}"));

# 74

ok($objZhP->eq("a\x{304}", "A\x{304}"));
ok($objZhP->eq("a\x{301}", "A\x{301}"));
ok($objZhP->eq("a\x{30C}", "A\x{30C}"));
ok($objZhP->eq("a\x{300}", "A\x{300}"));
ok($objZhP->eq("e\x{304}", "E\x{304}"));
ok($objZhP->eq("e\x{301}", "E\x{301}"));
ok($objZhP->eq("e\x{30C}", "E\x{30C}"));
ok($objZhP->eq("e\x{300}", "E\x{300}"));
ok($objZhP->eq("e\x{302}\x{304}", "E\x{302}\x{304}"));
ok($objZhP->eq("e\x{302}\x{301}", "E\x{302}\x{301}"));
ok($objZhP->eq("e\x{302}\x{30C}", "E\x{302}\x{30C}"));
ok($objZhP->eq("e\x{302}\x{300}", "E\x{302}\x{300}"));
ok($objZhP->eq("e\x{302}", "E\x{302}"));
ok($objZhP->eq("i\x{304}", "I\x{304}"));
ok($objZhP->eq("i\x{301}", "I\x{301}"));
ok($objZhP->eq("i\x{30C}", "I\x{30C}"));
ok($objZhP->eq("i\x{300}", "I\x{300}"));
ok($objZhP->eq("m\x{304}", "M\x{304}"));
ok($objZhP->eq("m\x{301}", "M\x{301}"));
ok($objZhP->eq("m\x{30C}", "M\x{30C}"));
ok($objZhP->eq("m\x{300}", "M\x{300}"));
ok($objZhP->eq("n\x{304}", "N\x{304}"));
ok($objZhP->eq("n\x{301}", "N\x{301}"));
ok($objZhP->eq("n\x{30C}", "N\x{30C}"));
ok($objZhP->eq("n\x{300}", "N\x{300}"));
ok($objZhP->eq("o\x{304}", "O\x{304}"));
ok($objZhP->eq("o\x{301}", "O\x{301}"));
ok($objZhP->eq("o\x{30C}", "O\x{30C}"));
ok($objZhP->eq("o\x{300}", "O\x{300}"));
ok($objZhP->eq("u\x{304}", "U\x{304}"));
ok($objZhP->eq("u\x{301}", "U\x{301}"));
ok($objZhP->eq("u\x{30C}", "U\x{30C}"));
ok($objZhP->eq("u\x{300}", "U\x{300}"));
ok($objZhP->eq("u\x{308}\x{304}", "U\x{308}\x{304}"));
ok($objZhP->eq("u\x{308}\x{301}", "U\x{308}\x{301}"));
ok($objZhP->eq("u\x{308}\x{30C}", "U\x{308}\x{30C}"));
ok($objZhP->eq("u\x{308}\x{300}", "U\x{308}\x{300}"));
ok($objZhP->eq("u\x{308}", "U\x{308}"));

# 112

$objZhP->change(level => 3);

ok($objZhP->lt("a\x{304}", "A\x{304}"));
ok($objZhP->lt("a\x{301}", "A\x{301}"));
ok($objZhP->lt("a\x{30C}", "A\x{30C}"));
ok($objZhP->lt("a\x{300}", "A\x{300}"));
ok($objZhP->lt("e\x{304}", "E\x{304}"));
ok($objZhP->lt("e\x{301}", "E\x{301}"));
ok($objZhP->lt("e\x{30C}", "E\x{30C}"));
ok($objZhP->lt("e\x{300}", "E\x{300}"));
ok($objZhP->lt("e\x{302}\x{304}", "E\x{302}\x{304}"));
ok($objZhP->lt("e\x{302}\x{301}", "E\x{302}\x{301}"));
ok($objZhP->lt("e\x{302}\x{30C}", "E\x{302}\x{30C}"));
ok($objZhP->lt("e\x{302}\x{300}", "E\x{302}\x{300}"));
ok($objZhP->lt("e\x{302}", "E\x{302}"));
ok($objZhP->lt("i\x{304}", "I\x{304}"));
ok($objZhP->lt("i\x{301}", "I\x{301}"));
ok($objZhP->lt("i\x{30C}", "I\x{30C}"));
ok($objZhP->lt("i\x{300}", "I\x{300}"));
ok($objZhP->lt("m\x{304}", "M\x{304}"));
ok($objZhP->lt("m\x{301}", "M\x{301}"));
ok($objZhP->lt("m\x{30C}", "M\x{30C}"));
ok($objZhP->lt("m\x{300}", "M\x{300}"));
ok($objZhP->lt("n\x{304}", "N\x{304}"));
ok($objZhP->lt("n\x{301}", "N\x{301}"));
ok($objZhP->lt("n\x{30C}", "N\x{30C}"));
ok($objZhP->lt("n\x{300}", "N\x{300}"));
ok($objZhP->lt("o\x{304}", "O\x{304}"));
ok($objZhP->lt("o\x{301}", "O\x{301}"));
ok($objZhP->lt("o\x{30C}", "O\x{30C}"));
ok($objZhP->lt("o\x{300}", "O\x{300}"));
ok($objZhP->lt("u\x{304}", "U\x{304}"));
ok($objZhP->lt("u\x{301}", "U\x{301}"));
ok($objZhP->lt("u\x{30C}", "U\x{30C}"));
ok($objZhP->lt("u\x{300}", "U\x{300}"));
ok($objZhP->lt("u\x{308}\x{304}", "U\x{308}\x{304}"));
ok($objZhP->lt("u\x{308}\x{301}", "U\x{308}\x{301}"));
ok($objZhP->lt("u\x{308}\x{30C}", "U\x{308}\x{30C}"));
ok($objZhP->lt("u\x{308}\x{300}", "U\x{308}\x{300}"));
ok($objZhP->lt("u\x{308}", "U\x{308}"));

# 150

ok($objZhP->eq("a\x{304}", "\x{101}"));
ok($objZhP->eq("A\x{304}", "\x{100}"));
ok($objZhP->eq("a\x{301}", pack('U', 0xE1)));
ok($objZhP->eq("a\x{301}", "a\x{341}"));
ok($objZhP->eq("A\x{301}", pack('U', 0xC1)));
ok($objZhP->eq("A\x{301}", "A\x{341}"));
ok($objZhP->eq("a\x{30C}", "\x{1CE}"));
ok($objZhP->eq("A\x{30C}", "\x{1CD}"));
ok($objZhP->eq("a\x{300}", pack('U', 0xE0)));
ok($objZhP->eq("a\x{300}", "a\x{340}"));
ok($objZhP->eq("A\x{300}", pack('U', 0xC0)));
ok($objZhP->eq("A\x{300}", "A\x{340}"));
ok($objZhP->eq("e\x{304}", "\x{113}"));
ok($objZhP->eq("E\x{304}", "\x{112}"));
ok($objZhP->eq("e\x{301}", pack('U', 0xE9)));
ok($objZhP->eq("e\x{301}", "e\x{341}"));
ok($objZhP->eq("E\x{301}", pack('U', 0xC9)));
ok($objZhP->eq("E\x{301}", "E\x{341}"));
ok($objZhP->eq("e\x{30C}", "\x{11B}"));
ok($objZhP->eq("E\x{30C}", "\x{11A}"));
ok($objZhP->eq("e\x{300}", pack('U', 0xE8)));
ok($objZhP->eq("e\x{300}", "e\x{340}"));
ok($objZhP->eq("E\x{300}", pack('U', 0xC8)));
ok($objZhP->eq("E\x{300}", "E\x{340}"));
ok($objZhP->eq("e\x{302}\x{304}", pack('U*', 0xEA, 0x304)));
ok($objZhP->eq("E\x{302}\x{304}", pack('U*', 0xCA, 0x304)));
ok($objZhP->eq("e\x{302}\x{301}", "\x{1EBF}"));
ok($objZhP->eq("e\x{302}\x{301}", pack('U*', 0xEA, 0x301)));
ok($objZhP->eq("e\x{302}\x{301}", "e\x{302}\x{341}"));
ok($objZhP->eq("E\x{302}\x{301}", "\x{1EBE}"));
ok($objZhP->eq("E\x{302}\x{301}", pack('U*', 0xCA, 0x301)));
ok($objZhP->eq("E\x{302}\x{301}", "E\x{302}\x{341}"));
ok($objZhP->eq("e\x{302}\x{30C}", pack('U*', 0xEA, 0x30C)));
ok($objZhP->eq("E\x{302}\x{30C}", pack('U*', 0xCA, 0x30C)));
ok($objZhP->eq("e\x{302}\x{300}", "\x{1EC1}"));
ok($objZhP->eq("e\x{302}\x{300}", pack('U*', 0xEA, 0x300)));
ok($objZhP->eq("e\x{302}\x{300}", "e\x{302}\x{340}"));
ok($objZhP->eq("E\x{302}\x{300}", "\x{1EC0}"));
ok($objZhP->eq("E\x{302}\x{300}", pack('U*', 0xCA, 0x300)));
ok($objZhP->eq("E\x{302}\x{300}", "E\x{302}\x{340}"));
ok($objZhP->eq("e\x{302}", pack('U', 0xEA)));
ok($objZhP->eq("E\x{302}", pack('U', 0xCA)));
ok($objZhP->eq("i\x{304}", "\x{12B}"));
ok($objZhP->eq("I\x{304}", "\x{12A}"));
ok($objZhP->eq("i\x{301}", pack('U', 0xED)));
ok($objZhP->eq("i\x{301}", "i\x{341}"));
ok($objZhP->eq("I\x{301}", pack('U', 0xCD)));
ok($objZhP->eq("I\x{301}", "I\x{341}"));
ok($objZhP->eq("i\x{30C}", "\x{1D0}"));
ok($objZhP->eq("I\x{30C}", "\x{1CF}"));
ok($objZhP->eq("i\x{300}", pack('U', 0xEC)));
ok($objZhP->eq("i\x{300}", "i\x{340}"));
ok($objZhP->eq("I\x{300}", pack('U', 0xCC)));
ok($objZhP->eq("I\x{300}", "I\x{340}"));
ok($objZhP->eq("m\x{301}", "\x{1E3F}"));
ok($objZhP->eq("m\x{301}", "m\x{341}"));
ok($objZhP->eq("M\x{301}", "\x{1E3E}"));
ok($objZhP->eq("M\x{301}", "M\x{341}"));
ok($objZhP->eq("m\x{300}", "m\x{340}"));
ok($objZhP->eq("M\x{300}", "M\x{340}"));
ok($objZhP->eq("n\x{301}", "\x{144}"));
ok($objZhP->eq("n\x{301}", "n\x{341}"));
ok($objZhP->eq("N\x{301}", "\x{143}"));
ok($objZhP->eq("N\x{301}", "N\x{341}"));
ok($objZhP->eq("n\x{30C}", "\x{148}"));
ok($objZhP->eq("N\x{30C}", "\x{147}"));
ok($objZhP->eq("n\x{300}", "\x{1F9}"));
ok($objZhP->eq("n\x{300}", "n\x{340}"));
ok($objZhP->eq("N\x{300}", "\x{1F8}"));
ok($objZhP->eq("N\x{300}", "N\x{340}"));
ok($objZhP->eq("o\x{304}", "\x{14D}"));
ok($objZhP->eq("O\x{304}", "\x{14C}"));
ok($objZhP->eq("o\x{301}", pack('U', 0xF3)));
ok($objZhP->eq("o\x{301}", "o\x{341}"));
ok($objZhP->eq("O\x{301}", pack('U', 0xD3)));
ok($objZhP->eq("O\x{301}", "O\x{341}"));
ok($objZhP->eq("o\x{30C}", "\x{1D2}"));
ok($objZhP->eq("O\x{30C}", "\x{1D1}"));
ok($objZhP->eq("o\x{300}", pack('U', 0xF2)));
ok($objZhP->eq("o\x{300}", "o\x{340}"));
ok($objZhP->eq("O\x{300}", pack('U', 0xD2)));
ok($objZhP->eq("O\x{300}", "O\x{340}"));
ok($objZhP->eq("u\x{304}", "\x{16B}"));
ok($objZhP->eq("U\x{304}", "\x{16A}"));
ok($objZhP->eq("u\x{301}", pack('U', 0xFA)));
ok($objZhP->eq("u\x{301}", "u\x{341}"));
ok($objZhP->eq("U\x{301}", pack('U', 0xDA)));
ok($objZhP->eq("U\x{301}", "U\x{341}"));
ok($objZhP->eq("u\x{30C}", "\x{1D4}"));
ok($objZhP->eq("U\x{30C}", "\x{1D3}"));
ok($objZhP->eq("u\x{300}", pack('U', 0xF9)));
ok($objZhP->eq("u\x{300}", "u\x{340}"));
ok($objZhP->eq("U\x{300}", pack('U', 0xD9)));
ok($objZhP->eq("U\x{300}", "U\x{340}"));
ok($objZhP->eq("u\x{308}\x{304}", "\x{1D6}"));
ok($objZhP->eq("u\x{308}\x{304}", pack('U*', 0xFC, 0x304)));
ok($objZhP->eq("U\x{308}\x{304}", "\x{1D5}"));
ok($objZhP->eq("U\x{308}\x{304}", pack('U*', 0xDC, 0x304)));
ok($objZhP->eq("u\x{308}\x{301}", "\x{1D8}"));
ok($objZhP->eq("u\x{308}\x{301}", pack('U*', 0xFC, 0x301)));
ok($objZhP->eq("u\x{308}\x{301}", "u\x{308}\x{341}"));
ok($objZhP->eq("U\x{308}\x{301}", "\x{1D7}"));
ok($objZhP->eq("U\x{308}\x{301}", pack('U*', 0xDC, 0x301)));
ok($objZhP->eq("U\x{308}\x{301}", "U\x{308}\x{341}"));
ok($objZhP->eq("u\x{308}\x{30C}", "\x{1DA}"));
ok($objZhP->eq("u\x{308}\x{30C}", pack('U*', 0xFC, 0x30C)));
ok($objZhP->eq("U\x{308}\x{30C}", "\x{1D9}"));
ok($objZhP->eq("U\x{308}\x{30C}", pack('U*', 0xDC, 0x30C)));
ok($objZhP->eq("u\x{308}\x{300}", "\x{1DC}"));
ok($objZhP->eq("u\x{308}\x{300}", pack('U*', 0xFC, 0x300)));
ok($objZhP->eq("u\x{308}\x{300}", "u\x{308}\x{340}"));
ok($objZhP->eq("U\x{308}\x{300}", "\x{1DB}"));
ok($objZhP->eq("U\x{308}\x{300}", pack('U*', 0xDC, 0x300)));
ok($objZhP->eq("U\x{308}\x{300}", "U\x{308}\x{340}"));
ok($objZhP->eq("u\x{308}", pack('U', 0xFC)));
ok($objZhP->eq("U\x{308}", pack('U', 0xDC)));

# 266

ok($objZhP->eq("e\x{302}\x{303}", "\x{1EC5}"));
ok($objZhP->eq("E\x{302}\x{303}", "\x{1EC4}"));
ok($objZhP->eq("e\x{302}\x{309}", "\x{1EC3}"));
ok($objZhP->eq("E\x{302}\x{309}", "\x{1EC2}"));
ok($objZhP->eq("e\x{302}\x{323}", "\x{1EC7}"));
ok($objZhP->eq("E\x{302}\x{323}", "\x{1EC6}"));

# 272

$objZhP->change(level => 1);

ok($objZhP->lt("\x{A000}", "\x{3105}"));

ok($objZhP->lt("\x{3105}", "\x{3106}"));
ok($objZhP->lt("\x{3106}", "\x{3128}"));
ok($objZhP->lt("\x{3128}", "\x{3129}"));
ok($objZhP->lt("\x{3129}", "\x{5416}"));
ok($objZhP->lt("\x{5416}", "\x{963F}"));
ok($objZhP->lt("\x{963F}", "\x{554A}"));
ok($objZhP->lt("\x{554A}", "\x{9515}"));
ok($objZhP->lt("\x{9515}", "\x{9312}"));
ok($objZhP->lt("\x{9312}", "\x{55C4}"));
ok($objZhP->lt("\x{55C4}", "\x{5391}"));
ok($objZhP->lt("\x{5391}", "\x{54CE}"));
ok($objZhP->lt("\x{54CE}", "\x{54C0}"));
ok($objZhP->lt("\x{54C0}", "\x{5509}"));
ok($objZhP->lt("\x{5509}", "\x{57C3}"));

ok($objZhP->lt("\x{6FED}", "\x{FA1F}"));
ok($objZhP->lt("\x{FA1F}", "\x{85F9}"));

ok($objZhP->lt("\x{57C3}", "\x{4E00}"));
ok($objZhP->lt("\x{4E00}", "\x{8331}"));

ok($objZhP->lt("\x{8331}", "\x{682A}"));
ok($objZhP->lt("\x{682A}", "\x{3231}"));
ok($objZhP->lt("\x{3231}", "\x{73E0}"));
ok($objZhP->lt("\x{73E0}", "\x{8BF8}"));

ok($objZhP->lt("\x{5EA7}", "\x{888F}"));
ok($objZhP->lt("\x{888F}", "\x{505A}"));
ok($objZhP->lt("\x{505A}", "\x{8444}"));
ok($objZhP->lt("\x{8444}", "\x{84D9}"));
ok($objZhP->lt("\x{84D9}", "\x{98F5}"));
ok($objZhP->lt("\x{98F5}", "\x{7CF3}"));
ok($objZhP->lt("\x{7CF3}", "\x{5497}"));

# 302
