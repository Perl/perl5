
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

my $objAf = Unicode::Collate::Locale->
    new(locale => 'AF', normalization => undef);

ok($objAf->getlocale, 'af');

$objAf->change(level => 1);

ok($objAf->eq("n", "N"));
ok($objAf->eq("N", "\x{149}"));

$objAf->change(level => 2);

ok($objAf->eq("n", "N"));
ok($objAf->eq("N", "\x{149}"));

$objAf->change(level => 3);

ok($objAf->lt("n", "N"));
ok($objAf->lt("N", "\x{149}"));
