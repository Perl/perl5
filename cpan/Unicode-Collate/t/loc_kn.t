
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

my $objKn = Unicode::Collate::Locale->
    new(locale => 'KN', normalization => undef);

ok($objKn->getlocale, 'kn');

$objKn->change(level => 1);

ok($objKn->lt("\x{0C94}", "\x{0C82}"));
ok($objKn->lt("\x{0C82}", "\x{0C83}"));
ok($objKn->lt("\x{0C83}", "\x{0CF1}"));
ok($objKn->lt("\x{0CF1}", "\x{0CF2}"));
ok($objKn->lt("\x{0CF2}", "\x{0C95}"));

