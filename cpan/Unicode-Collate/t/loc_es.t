
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
BEGIN { plan tests => 26 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objEs = Unicode::Collate::Locale->
    new(locale => 'ES', normalization => undef);

ok($objEs->getlocale, 'es');

$objEs->change(level => 1);

ok($objEs->lt("cg", "ch"));
ok($objEs->gt("ci", "ch"));
ok($objEs->gt("d", "ch"));
ok($objEs->lt("lk", "ll"));
ok($objEs->gt("lm", "ll"));
ok($objEs->gt("m", "ll"));
ok($objEs->lt("n", "n\x{303}"));
ok($objEs->gt("o", "n\x{303}"));

# 10

ok($objEs->eq("a\x{300}a", "aa\x{300}"));

$objEs->change(level => 2);

ok($objEs->gt("a\x{300}a", "aa\x{300}"));
ok($objEs->lt("Ca\x{300}ca\x{302}", "ca\x{302}ca\x{300}"));
ok($objEs->lt("ca\x{300}ca\x{302}", "Ca\x{302}ca\x{300}"));

# 14

ok($objEs->eq("ch", "Ch"));
ok($objEs->eq("Ch", "CH"));
ok($objEs->eq("ll", "Ll"));
ok($objEs->eq("Ll", "LL"));
ok($objEs->eq("n\x{303}", "N\x{303}"));

# 19

$objEs->change(level => 3);

ok($objEs->lt("ch", "Ch"));
ok($objEs->lt("Ch", "CH"));
ok($objEs->lt("ll", "Ll"));
ok($objEs->lt("Ll", "LL"));
ok($objEs->lt("n\x{303}", "N\x{303}"));
ok($objEs->eq("n\x{303}", pack('U', 0xF1)));
ok($objEs->eq("N\x{303}", pack('U', 0xD1)));

# 26
