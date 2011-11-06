
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
BEGIN { plan tests => 6 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objTe = Unicode::Collate::Locale->
    new(locale => 'TE', normalization => undef);

ok($objTe->getlocale, 'te');

$objTe->change(level => 1);

ok($objTe->lt("\x{C14}", "\x{C01}"));
ok($objTe->lt("\x{C01}", "\x{C02}"));
ok($objTe->lt("\x{C02}", "\x{C03}"));
ok($objTe->lt("\x{C03}", "\x{C15}"));

