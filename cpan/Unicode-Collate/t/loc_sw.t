
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
BEGIN { plan tests => 72 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objSw = Unicode::Collate::Locale->
    new(locale => 'SW', normalization => undef);

ok($objSw->getlocale, 'sw');

$objSw->change(level => 1);

ok($objSw->lt("b", "ch"));
ok($objSw->lt("bz","ch"));
ok($objSw->gt("c", "ch"));
ok($objSw->lt("d", "dh"));
ok($objSw->lt("dz","dh"));
ok($objSw->gt("e", "dh"));
ok($objSw->lt("g", "gh"));
ok($objSw->lt("gz","gh"));
ok($objSw->gt("h", "gh"));
ok($objSw->lt("k", "kh"));
ok($objSw->lt("kz","kh"));
ok($objSw->gt("l", "kh"));
ok($objSw->lt("n", "ng'"));
ok($objSw->lt("nz","ng'"));
ok($objSw->lt("ng'","ny"));
ok($objSw->gt("o", "ny"));
ok($objSw->lt("s", "sh"));
ok($objSw->lt("sz","sh"));
ok($objSw->gt("t", "sh"));
ok($objSw->lt("t", "th"));
ok($objSw->lt("tz","th"));
ok($objSw->gt("u", "th"));

# 24

$objSw->change(level => 2);

ok($objSw->eq("ch", "Ch"));
ok($objSw->eq("Ch", "CH"));
ok($objSw->eq("dh", "Dh"));
ok($objSw->eq("Dh", "DH"));
ok($objSw->eq("gh", "Gh"));
ok($objSw->eq("Gh", "GH"));
ok($objSw->eq("kh", "Kh"));
ok($objSw->eq("Kh", "KH"));
ok($objSw->eq("ng'","Ng'"));
ok($objSw->eq("Ng'","NG'"));
ok($objSw->eq("ny", "Ny"));
ok($objSw->eq("Ny", "NY"));
ok($objSw->eq("sh", "Sh"));
ok($objSw->eq("Sh", "SH"));
ok($objSw->eq("th", "Th"));
ok($objSw->eq("Th", "TH"));

# 40

$objSw->change(level => 3);

ok($objSw->lt("ch", "Ch"));
ok($objSw->lt("Ch", "CH"));
ok($objSw->lt("dh", "Dh"));
ok($objSw->lt("Dh", "DH"));
ok($objSw->lt("gh", "Gh"));
ok($objSw->lt("Gh", "GH"));
ok($objSw->lt("kh", "Kh"));
ok($objSw->lt("Kh", "KH"));
ok($objSw->lt("ng'","Ng'"));
ok($objSw->lt("Ng'","NG'"));
ok($objSw->lt("ny", "Ny"));
ok($objSw->lt("Ny", "NY"));
ok($objSw->lt("sh", "Sh"));
ok($objSw->lt("Sh", "SH"));
ok($objSw->lt("th", "Th"));
ok($objSw->lt("Th", "TH"));

# 56

$objSw->change(upper_before_lower => 1);

ok($objSw->gt("ch", "Ch"));
ok($objSw->gt("Ch", "CH"));
ok($objSw->gt("dh", "Dh"));
ok($objSw->gt("Dh", "DH"));
ok($objSw->gt("gh", "Gh"));
ok($objSw->gt("Gh", "GH"));
ok($objSw->gt("kh", "Kh"));
ok($objSw->gt("Kh", "KH"));
ok($objSw->gt("ng'","Ng'"));
ok($objSw->gt("Ng'","NG'"));
ok($objSw->gt("ny", "Ny"));
ok($objSw->gt("Ny", "NY"));
ok($objSw->gt("sh", "Sh"));
ok($objSw->gt("Sh", "SH"));
ok($objSw->gt("th", "Th"));
ok($objSw->gt("Th", "TH"));

# 72
