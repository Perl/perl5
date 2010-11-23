
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
BEGIN { plan tests => 8 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objAr = Unicode::Collate::Locale->
    new(locale => 'AR', normalization => undef);

ok($objAr->getlocale, 'ar');

$objAr->change(level => 1);

ok($objAr->eq("\x{62A}", "\x{629}"));
ok($objAr->eq("\x{62A}", "\x{FE93}"));
ok($objAr->eq("\x{62A}", "\x{FE94}"));

$objAr->change(level => 3);

ok($objAr->eq("\x{62A}", "\x{629}"));
ok($objAr->eq("\x{62A}", "\x{FE93}"));
ok($objAr->eq("\x{62A}", "\x{FE94}"));

# 8
