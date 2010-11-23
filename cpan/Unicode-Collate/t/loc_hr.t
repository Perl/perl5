
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
BEGIN { plan tests => 88 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objHr = Unicode::Collate::Locale->
    new(locale => 'HR', normalization => undef);

ok($objHr->getlocale, 'hr');

$objHr->change(level => 1);

ok($objHr->lt("c", "c\x{30C}"));
ok($objHr->lt("c\x{30C}", "c\x{301}"));
ok($objHr->gt("d", "c\x{301}"));
ok($objHr->lt("d", "dz\x{30C}"));
ok($objHr->lt("dzz", "dz\x{30C}"));
ok($objHr->lt("dz\x{30C}", "d\x{335}"));
ok($objHr->gt("e", "d\x{335}"));
ok($objHr->lt("l", "lj"));
ok($objHr->lt("lz","lj"));
ok($objHr->gt("m", "lj"));
ok($objHr->lt("n", "nj"));
ok($objHr->lt("nz","nj"));
ok($objHr->gt("o", "nj"));
ok($objHr->lt("s", "s\x{30C}"));
ok($objHr->lt("sz","s\x{30C}"));
ok($objHr->gt("t", "s\x{30C}"));
ok($objHr->lt("z", "z\x{30C}"));
ok($objHr->lt("zz","z\x{30C}"));
ok($objHr->lt("z\x{30C}", "\x{292}")); # U+0292 EZH

# 21

$objHr->change(level => 2);

ok($objHr->eq("c\x{30C}", "C\x{30C}"));
ok($objHr->eq("c\x{301}", "C\x{301}"));
ok($objHr->eq("dz\x{30C}","dZ\x{30C}"));
ok($objHr->eq("dZ\x{30C}","Dz\x{30C}"));
ok($objHr->eq("Dz\x{30C}","DZ\x{30C}"));
ok($objHr->eq("d\x{335}", "D\x{335}"));
ok($objHr->eq("lj", "lJ"));
ok($objHr->eq("lJ", "Lj"));
ok($objHr->eq("Lj", "LJ"));
ok($objHr->eq("nj", "nJ"));
ok($objHr->eq("nJ", "Nj"));
ok($objHr->eq("Nj", "NJ"));
ok($objHr->eq("s\x{30C}", "S\x{30C}"));
ok($objHr->eq("z\x{30C}", "Z\x{30C}"));

# 35

$objHr->change(level => 3);

ok($objHr->lt("c\x{30C}", "C\x{30C}"));
ok($objHr->lt("c\x{301}", "C\x{301}"));
ok($objHr->lt("dz\x{30C}","dZ\x{30C}"));
ok($objHr->lt("dZ\x{30C}","Dz\x{30C}"));
ok($objHr->lt("Dz\x{30C}","DZ\x{30C}"));
ok($objHr->lt("d\x{335}", "D\x{335}"));
ok($objHr->lt("lj", "lJ"));
ok($objHr->lt("lJ", "Lj"));
ok($objHr->lt("Lj", "LJ"));
ok($objHr->lt("nj", "nJ"));
ok($objHr->lt("nJ", "Nj"));
ok($objHr->lt("Nj", "NJ"));
ok($objHr->lt("s\x{30C}", "S\x{30C}"));
ok($objHr->lt("z\x{30C}", "Z\x{30C}"));

# 49

ok($objHr->eq("c\x{30C}", "\x{10D}"));
ok($objHr->eq("C\x{30C}", "\x{10C}"));
ok($objHr->eq("c\x{301}", "\x{107}"));
ok($objHr->eq("c\x{341}", "\x{107}"));
ok($objHr->eq("C\x{301}", "\x{106}"));
ok($objHr->eq("C\x{341}", "\x{106}"));
ok($objHr->eq("dz\x{30C}", "\x{1C6}"));
ok($objHr->eq("Dz\x{30C}", "\x{1C5}"));
ok($objHr->eq("DZ\x{30C}", "\x{1C4}"));
ok($objHr->eq("dz\x{30C}", "d\x{17E}"));
ok($objHr->eq("dZ\x{30C}", "d\x{17D}"));
ok($objHr->eq("Dz\x{30C}", "D\x{17E}"));
ok($objHr->eq("DZ\x{30C}", "D\x{17D}"));
ok($objHr->eq("d\x{335}", "\x{111}"));
ok($objHr->eq("D\x{335}", "\x{110}"));
ok($objHr->eq("lj", "\x{1C9}"));
ok($objHr->eq("Lj", "\x{1C8}"));
ok($objHr->eq("LJ", "\x{1C7}"));
ok($objHr->eq("nj", "\x{1CC}"));
ok($objHr->eq("Nj", "\x{1CB}"));
ok($objHr->eq("NJ", "\x{1CA}"));
ok($objHr->eq("s\x{30C}", "\x{161}"));
ok($objHr->eq("S\x{30C}", "\x{160}"));
ok($objHr->eq("z\x{30C}", "\x{17E}"));
ok($objHr->eq("Z\x{30C}", "\x{17D}"));

# 74

$objHr->change(upper_before_lower => 1);

ok($objHr->gt("c\x{30C}", "C\x{30C}"));
ok($objHr->gt("c\x{301}", "C\x{301}"));
ok($objHr->gt("dz\x{30C}","dZ\x{30C}"));
ok($objHr->gt("dZ\x{30C}","Dz\x{30C}"));
ok($objHr->gt("Dz\x{30C}","DZ\x{30C}"));
ok($objHr->gt("d\x{335}", "D\x{335}"));
ok($objHr->gt("lj", "lJ"));
ok($objHr->gt("lJ", "Lj"));
ok($objHr->gt("Lj", "LJ"));
ok($objHr->gt("nj", "nJ"));
ok($objHr->gt("nJ", "Nj"));
ok($objHr->gt("Nj", "NJ"));
ok($objHr->gt("s\x{30C}", "S\x{30C}"));
ok($objHr->gt("z\x{30C}", "Z\x{30C}"));

# 88
