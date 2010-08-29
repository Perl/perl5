#!perl
use strict;
use warnings;
use Unicode::Collate::Locale;

use Test;
plan tests => 74;

my $objCy = Unicode::Collate::Locale->
    new(locale => 'CY', normalization => undef);

ok(1);
ok($objCy->getlocale, 'cy');

$objCy->change(level => 1);

ok($objCy->lt("c", "ch"));
ok($objCy->lt("cz","ch"));
ok($objCy->gt("d", "ch"));
ok($objCy->lt("d", "dd"));
ok($objCy->lt("dz","dd"));
ok($objCy->gt("e", "dd"));
ok($objCy->lt("f", "ff"));
ok($objCy->lt("fz","ff"));
ok($objCy->gt("g", "ff"));
ok($objCy->lt("g", "ng"));
ok($objCy->lt("gz","ng"));
ok($objCy->gt("h", "ng"));
ok($objCy->lt("l", "ll"));
ok($objCy->lt("lz","ll"));
ok($objCy->gt("m", "ll"));
ok($objCy->lt("p", "ph"));
ok($objCy->lt("pz","ph"));
ok($objCy->gt("q", "ph"));
ok($objCy->lt("r", "rh"));
ok($objCy->lt("rz","rh"));
ok($objCy->gt("s", "rh"));
ok($objCy->lt("t", "th"));
ok($objCy->lt("tz","th"));
ok($objCy->gt("u", "th"));

# 26

$objCy->change(level => 2);

ok($objCy->eq("ch", "Ch"));
ok($objCy->eq("CH", "Ch"));
ok($objCy->eq("dd", "Dd"));
ok($objCy->eq("DD", "Dd"));
ok($objCy->eq("ff", "Ff"));
ok($objCy->eq("FF", "Ff"));
ok($objCy->eq("ng", "Ng"));
ok($objCy->eq("NG", "Ng"));
ok($objCy->eq("ll", "Ll"));
ok($objCy->eq("LL", "Ll"));
ok($objCy->eq("ph", "Ph"));
ok($objCy->eq("PH", "Ph"));
ok($objCy->eq("rh", "Rh"));
ok($objCy->eq("RH", "Rh"));
ok($objCy->eq("th", "Th"));
ok($objCy->eq("TH", "Th"));

# 42

$objCy->change(level => 3);

ok($objCy->lt("ch", "Ch"));
ok($objCy->gt("CH", "Ch"));
ok($objCy->lt("dd", "Dd"));
ok($objCy->gt("DD", "Dd"));
ok($objCy->lt("ff", "Ff"));
ok($objCy->gt("FF", "Ff"));
ok($objCy->lt("ng", "Ng"));
ok($objCy->gt("NG", "Ng"));
ok($objCy->lt("ll", "Ll"));
ok($objCy->gt("LL", "Ll"));
ok($objCy->lt("ph", "Ph"));
ok($objCy->gt("PH", "Ph"));
ok($objCy->lt("rh", "Rh"));
ok($objCy->gt("RH", "Rh"));
ok($objCy->lt("th", "Th"));
ok($objCy->gt("TH", "Th"));

# 58

$objCy->change(upper_before_lower => 1);

ok($objCy->gt("ch", "Ch"));
ok($objCy->lt("CH", "Ch"));
ok($objCy->gt("dd", "Dd"));
ok($objCy->lt("DD", "Dd"));
ok($objCy->gt("ff", "Ff"));
ok($objCy->lt("FF", "Ff"));
ok($objCy->gt("ng", "Ng"));
ok($objCy->lt("NG", "Ng"));
ok($objCy->gt("ll", "Ll"));
ok($objCy->lt("LL", "Ll"));
ok($objCy->gt("ph", "Ph"));
ok($objCy->lt("PH", "Ph"));
ok($objCy->gt("rh", "Rh"));
ok($objCy->lt("RH", "Rh"));
ok($objCy->gt("th", "Th"));
ok($objCy->lt("TH", "Th"));

# 74
