
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
BEGIN { plan tests => 34 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objHa = Unicode::Collate::Locale->
    new(locale => 'HA', normalization => undef);

ok($objHa->getlocale, 'ha');

$objHa->change(level => 1);

ok($objHa->lt("b", "\x{253}"));
ok($objHa->gt("c", "\x{253}"));
ok($objHa->lt("d", "\x{257}"));
ok($objHa->gt("e", "\x{257}"));
ok($objHa->lt("k", "\x{199}"));
ok($objHa->gt("l", "\x{199}"));
ok($objHa->lt("s", "sh"));
ok($objHa->gt("t", "sh"));
ok($objHa->lt("t", "ts"));
ok($objHa->gt("u", "ts"));
ok($objHa->lt("y", "\x{1B4}"));
ok($objHa->gt("z", "\x{1B4}"));

# 14

$objHa->change(level => 2);

ok($objHa->eq("\x{253}", "\x{181}"));
ok($objHa->eq("\x{257}", "\x{18A}"));
ok($objHa->eq("\x{199}", "\x{198}"));
ok($objHa->eq("sh", "Sh"));
ok($objHa->eq("Sh", "SH"));
ok($objHa->eq("ts", "Ts"));
ok($objHa->eq("Ts", "TS"));
ok($objHa->eq("'y", "'Y"));
ok($objHa->eq("\x{1B4}", "\x{1B3}"));

# 23

$objHa->change(level => 3);

ok($objHa->lt("\x{253}", "\x{181}"));
ok($objHa->lt("\x{257}", "\x{18A}"));
ok($objHa->lt("\x{199}", "\x{198}"));
ok($objHa->lt("sh", "Sh"));
ok($objHa->lt("Sh", "SH"));
ok($objHa->lt("ts", "Ts"));
ok($objHa->lt("Ts", "TS"));
ok($objHa->lt("'y", "'Y"));
ok($objHa->lt("\x{1B4}", "\x{1B3}"));
ok($objHa->eq("'y", "\x{1B4}"));
ok($objHa->eq("'Y", "\x{1B3}"));

# 34
