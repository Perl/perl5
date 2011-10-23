
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

ok($objKn->lt("\x{C94}", "\x{C82}"));
ok($objKn->lt("\x{C82}", "\x{C83}"));
ok($objKn->lt("\x{C83}", "\x{CF1}"));
ok($objKn->lt("\x{CF1}", "\x{CF2}"));
ok($objKn->lt("\x{CF2}", "\x{C95}"));

