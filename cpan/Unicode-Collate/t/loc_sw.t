#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 72;

my $objSw = Unicode::Collate::Locale->
    new(locale => 'SW', normalization => undef);

ok(1);
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
ok($objSw->eq("CH", "Ch"));
ok($objSw->eq("dh", "Dh"));
ok($objSw->eq("DH", "Dh"));
ok($objSw->eq("gh", "Gh"));
ok($objSw->eq("GH", "Gh"));
ok($objSw->eq("kh", "Kh"));
ok($objSw->eq("KH", "Kh"));
ok($objSw->eq("ng'","Ng'"));
ok($objSw->eq("NG'","Ng'"));
ok($objSw->eq("ny", "Ny"));
ok($objSw->eq("NY", "Ny"));
ok($objSw->eq("sh", "Sh"));
ok($objSw->eq("SH", "Sh"));
ok($objSw->eq("th", "Th"));
ok($objSw->eq("TH", "Th"));

# 40

$objSw->change(level => 3);

ok($objSw->lt("ch", "Ch"));
ok($objSw->gt("CH", "Ch"));
ok($objSw->lt("dh", "Dh"));
ok($objSw->gt("DH", "Dh"));
ok($objSw->lt("gh", "Gh"));
ok($objSw->gt("GH", "Gh"));
ok($objSw->lt("kh", "Kh"));
ok($objSw->gt("KH", "Kh"));
ok($objSw->lt("ng'","Ng'"));
ok($objSw->gt("NG'","Ng'"));
ok($objSw->lt("ny", "Ny"));
ok($objSw->gt("NY", "Ny"));
ok($objSw->lt("sh", "Sh"));
ok($objSw->gt("SH", "Sh"));
ok($objSw->lt("th", "Th"));
ok($objSw->gt("TH", "Th"));

# 56

$objSw->change(upper_before_lower => 1);

ok($objSw->gt("ch", "Ch"));
ok($objSw->lt("CH", "Ch"));
ok($objSw->gt("dh", "Dh"));
ok($objSw->lt("DH", "Dh"));
ok($objSw->gt("gh", "Gh"));
ok($objSw->lt("GH", "Gh"));
ok($objSw->gt("kh", "Kh"));
ok($objSw->lt("KH", "Kh"));
ok($objSw->gt("ng'","Ng'"));
ok($objSw->lt("NG'","Ng'"));
ok($objSw->gt("ny", "Ny"));
ok($objSw->lt("NY", "Ny"));
ok($objSw->gt("sh", "Sh"));
ok($objSw->lt("SH", "Sh"));
ok($objSw->gt("th", "Th"));
ok($objSw->lt("TH", "Th"));

# 72
