
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
BEGIN { plan tests => 14 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objSa = Unicode::Collate::Locale->
    new(locale => 'SA', normalization => undef);

ok($objSa->getlocale, 'sa');

$objSa->change(level => 1);

ok($objSa->lt("\x{950}", "\x{902}"));
ok($objSa->lt("\x{902}", "\x{903}"));
ok($objSa->lt("\x{903}", "\x{972}"));

ok($objSa->eq("\x{902}", "\x{901}"));

ok($objSa->lt("\x{939}", "\x{933}"));
ok($objSa->lt("\x{933}", "\x{915}\x{94D}\x{937}"));
ok($objSa->lt("\x{915}\x{94D}\x{937}", "\x{91C}\x{94D}\x{91E}"));
ok($objSa->lt("\x{91C}\x{94D}\x{91E}", "\x{93D}"));

ok($objSa->eq("\x{933}", "\x{934}"));

# 11

$objSa->change(level => 2);

ok($objSa->lt("\x{902}", "\x{901}"));
ok($objSa->lt("\x{933}", "\x{934}"));

$objSa->change(level => 3);

ok($objSa->eq("\x{933}\x{93C}", "\x{934}"));

# 14
