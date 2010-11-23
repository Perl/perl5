
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
BEGIN { plan tests => 41 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $dot  = pack 'U', 0xB7;

my $objCa = Unicode::Collate::Locale->
    new(locale => 'CA', normalization => undef);

ok($objCa->getlocale, 'ca');

$objCa->change(level => 1);

ok($objCa->lt("c",  "ch"));
ok($objCa->lt("cz", "ch"));
ok($objCa->gt("d", "ch"));
ok($objCa->lt("l",  "ll"));
ok($objCa->lt("lz", "ll"));
ok($objCa->gt("m", "ll"));

# 8

ok($objCa->eq("a\x{300}a", "aa\x{300}"));

$objCa->change(level => 2);

ok($objCa->lt("a\x{300}a", "aa\x{300}"));
ok($objCa->gt("Ca\x{300}ca\x{302}", "ca\x{302}ca\x{300}"));
ok($objCa->gt("ca\x{300}ca\x{302}", "Ca\x{302}ca\x{300}"));

# 12

ok($objCa->eq("ch", "cH"));
ok($objCa->eq("cH", "Ch"));
ok($objCa->eq("Ch", "CH"));

ok($objCa->eq("ll", "lL"));
ok($objCa->eq("lL", "Ll"));
ok($objCa->eq("Ll", "LL"));
ok($objCa->eq("l${dot}l", "lL"));
ok($objCa->eq("l${dot}L", "Ll"));
ok($objCa->eq("L${dot}l", "LL"));
ok($objCa->eq("ll","l${dot}l"));
ok($objCa->eq("lL","l${dot}L"));
ok($objCa->eq("Ll","L${dot}l"));
ok($objCa->eq("LL","L${dot}L"));

# 25

$objCa->change(level => 3);

ok($objCa->lt("ch", "cH"));
ok($objCa->lt("cH", "Ch"));
ok($objCa->lt("Ch", "CH"));

ok($objCa->lt("ll", "lL"));
ok($objCa->lt("lL", "Ll"));
ok($objCa->lt("Ll", "LL"));
ok($objCa->lt("l${dot}l", "lL"));
ok($objCa->lt("l${dot}L", "Ll"));
ok($objCa->lt("L${dot}l", "LL"));
ok($objCa->lt("ll","l${dot}l"));
ok($objCa->lt("lL","l${dot}L"));
ok($objCa->lt("Ll","L${dot}l"));
ok($objCa->lt("LL","L${dot}L"));

# 38

$objCa->change(backwards => undef, level => 2);

ok($objCa->gt("a\x{300}a", "aa\x{300}"));
ok($objCa->lt("Ca\x{300}ca\x{302}", "ca\x{302}ca\x{300}"));
ok($objCa->lt("ca\x{300}ca\x{302}", "Ca\x{302}ca\x{300}"));

# 41
