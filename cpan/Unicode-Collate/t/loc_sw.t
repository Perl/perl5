
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
BEGIN { plan tests => 17 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objSw = Unicode::Collate::Locale->
    new(locale => 'SW', normalization => undef);

ok($objSw->getlocale, "default"); # no tailoring since 0.74

$objSw->change(level => 1);

ok($objSw->lt("c", "ch"));
ok($objSw->gt("cz","ch"));
ok($objSw->lt("d", "dh"));
ok($objSw->gt("dz","dh"));
ok($objSw->lt("g", "gh"));
ok($objSw->gt("gz","gh"));
ok($objSw->lt("k", "kh"));
ok($objSw->gt("kz","kh"));
ok($objSw->lt("n", "ng'"));
ok($objSw->gt("ny","ng'"));
ok($objSw->gt("nz","ny"));
ok($objSw->lt("s", "sh"));
ok($objSw->gt("sz","sh"));
ok($objSw->lt("t", "th"));
ok($objSw->gt("tz","th"));

# 17
