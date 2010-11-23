
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
BEGIN { plan tests => 52 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objSk = Unicode::Collate::Locale->
    new(locale => 'SK', normalization => undef);

ok($objSk->getlocale, 'sk');

$objSk->change(level => 1);

ok($objSk->lt("a", "a\x{308}"));
ok($objSk->gt("b", "a\x{308}"));
ok($objSk->lt("c", "c\x{30C}"));
ok($objSk->gt("d", "c\x{30C}"));
ok($objSk->lt("h", "ch"));
ok($objSk->gt("i", "ch"));
ok($objSk->lt("o", "o\x{302}"));
ok($objSk->gt("p", "o\x{302}"));
ok($objSk->lt("s", "s\x{30C}"));
ok($objSk->gt("t", "s\x{30C}"));
ok($objSk->lt("z", "z\x{30C}"));
ok($objSk->lt("z\x{30C}", "\x{292}")); # U+0292 EZH

# 14

$objSk->change(level => 2);

ok($objSk->eq("a\x{308}", "A\x{308}"));
ok($objSk->eq("c\x{30C}", "C\x{30C}"));
ok($objSk->eq("o\x{302}", "O\x{302}"));
ok($objSk->eq("s\x{30C}", "S\x{30C}"));
ok($objSk->eq("z\x{30C}", "Z\x{30C}"));
ok($objSk->eq("ch", "cH"));
ok($objSk->eq("cH", "Ch"));
ok($objSk->eq("Ch", "CH"));

# 22

$objSk->change(level => 3);

ok($objSk->lt("a\x{308}", "A\x{308}"));
ok($objSk->lt("c\x{30C}", "C\x{30C}"));
ok($objSk->lt("o\x{302}", "O\x{302}"));
ok($objSk->lt("s\x{30C}", "S\x{30C}"));
ok($objSk->lt("z\x{30C}", "Z\x{30C}"));
ok($objSk->lt("ch", "cH"));
ok($objSk->lt("cH", "Ch"));
ok($objSk->lt("Ch", "CH"));

# 30

ok($objSk->eq("a\x{308}", pack('U', 0xE4)));
ok($objSk->eq("A\x{308}", pack('U', 0xC4)));
ok($objSk->eq("a\x{308}\x{304}", "\x{1DF}"));
ok($objSk->eq("A\x{308}\x{304}", "\x{1DE}"));
ok($objSk->eq("c\x{30C}", "\x{10D}"));
ok($objSk->eq("C\x{30C}", "\x{10C}"));
ok($objSk->eq("o\x{302}", pack('U', 0xF4)));
ok($objSk->eq("O\x{302}", pack('U', 0xD4)));
ok($objSk->eq("s\x{30C}", "\x{161}"));
ok($objSk->eq("S\x{30C}", "\x{160}"));
ok($objSk->eq("z\x{30C}", "\x{17E}"));
ok($objSk->eq("Z\x{30C}", "\x{17D}"));

# 42

ok($objSk->eq("o\x{302}\x{300}", "\x{1ED3}"));
ok($objSk->eq("O\x{302}\x{300}", "\x{1ED2}"));
ok($objSk->eq("o\x{302}\x{301}", "\x{1ED1}"));
ok($objSk->eq("O\x{302}\x{301}", "\x{1ED0}"));
ok($objSk->eq("o\x{302}\x{303}", "\x{1ED7}"));
ok($objSk->eq("O\x{302}\x{303}", "\x{1ED6}"));
ok($objSk->eq("o\x{302}\x{309}", "\x{1ED5}"));
ok($objSk->eq("O\x{302}\x{309}", "\x{1ED4}"));
ok($objSk->eq("o\x{302}\x{323}", "\x{1ED9}"));
ok($objSk->eq("O\x{302}\x{323}", "\x{1ED8}"));

# 52
