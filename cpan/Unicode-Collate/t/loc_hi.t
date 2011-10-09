
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
BEGIN { plan tests => 7 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objHi = Unicode::Collate::Locale->
    new(locale => 'HI', normalization => undef);

ok($objHi->getlocale, 'hi');

$objHi->change(level => 1);

ok($objHi->lt("\x{950}", "\x{902}"));
ok($objHi->lt("\x{902}", "\x{903}"));
ok($objHi->lt("\x{903}", "\x{972}"));

ok($objHi->eq("\x{902}", "\x{901}"));

$objHi->change(level => 2);

ok($objHi->lt("\x{902}", "\x{901}"));

