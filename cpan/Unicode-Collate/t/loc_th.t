
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

use strict;
use warnings;
BEGIN { $| = 1; print "1..47\n"; }
my $count = 0;
sub ok ($;$) {
    my $p = my $r = shift;
    if (@_) {
	my $x = shift;
	$p = !defined $x ? !defined $r : !defined $r ? 0 : $r eq $x;
    }
    print $p ? "ok" : "not ok", ' ', ++$count, "\n";
}

use Unicode::Collate::Locale;

ok(1);

#########################

my $objTh = Unicode::Collate::Locale->
    new(locale => 'TH', normalization => undef);


ok($objTh->getlocale, 'th');

$objTh->change(level => 1);

# shifted

ok($objTh->eq("\x{E2F}", ""));
ok($objTh->eq("\x{E46}", ""));
ok($objTh->eq("\x{E4F}", ""));
ok($objTh->eq("\x{E5A}", ""));
ok($objTh->eq("\x{E5B}", ""));

# 7

ok($objTh->lt("\x{E2E}", "\x{E4D}"));
ok($objTh->lt("\x{E4D}", "\x{E30}"));

ok($objTh->lt("\x{E44}", "\x{E3A}"));

# 10

ok($objTh->eq("\x{E4E}", ""));
ok($objTh->eq("\x{E4C}", ""));
ok($objTh->eq("\x{E47}", ""));
ok($objTh->eq("\x{E48}", ""));
ok($objTh->eq("\x{E49}", ""));
ok($objTh->eq("\x{E4A}", ""));
ok($objTh->eq("\x{E4B}", ""));

# 17

$objTh->change(level => 2);

ok($objTh->lt("\x{E4E}", "\x{E4C}"));
ok($objTh->lt("\x{E4C}", "\x{E47}"));
ok($objTh->lt("\x{E47}", "\x{E48}"));
ok($objTh->lt("\x{E48}", "\x{E49}"));
ok($objTh->lt("\x{E49}", "\x{E4A}"));
ok($objTh->lt("\x{E4A}", "\x{E4B}"));

ok($objTh->eq("\x{E32}", "\x{E45}"));
ok($objTh->eq("\x{E32}\x{E4D}", "\x{E4D}\x{E32}"));
ok($objTh->eq("\x{E4D}\x{E32}", "\x{E33}"));
ok($objTh->eq("\x{E4D}\x{E45}", "\x{E45}\x{E4D}"));

# 27

$objTh->change(level => 3);

ok($objTh->lt("\x{E32}", "\x{E45}"));
ok($objTh->lt("\x{E32}\x{E4D}", "\x{E4D}\x{E32}"));
ok($objTh->lt("\x{E4D}\x{E32}", "\x{E33}"));
ok($objTh->lt("\x{E4D}\x{E45}", "\x{E45}\x{E4D}"));

ok($objTh->eq("\x{E4F}", "\x{E2F}"));
ok($objTh->eq("\x{E2F}", "\x{E5A}"));
ok($objTh->eq("\x{E5A}", "\x{E5B}"));
ok($objTh->eq("\x{E5B}", "\x{E46}"));

# 35

$objTh->change(level => 4);

ok($objTh->lt("\x{E4F}", "\x{E2F}"));
ok($objTh->lt("\x{E2F}", "\x{E5A}"));
ok($objTh->lt("\x{E5A}", "\x{E5B}"));
ok($objTh->lt("\x{E5B}", "\x{E46}"));

# 39

$objTh->change(level => 1);

ok($objTh->eq("\x{E4F}", "\x{E2F}"));
ok($objTh->eq("\x{E2F}", "\x{E5A}"));
ok($objTh->eq("\x{E5A}", "\x{E5B}"));
ok($objTh->eq("\x{E5B}", "\x{E46}"));

# 43

$objTh->change(variable => "non-ignorable");

ok($objTh->lt("\x{E4F}", "\x{E2F}"));
ok($objTh->lt("\x{E2F}", "\x{E5A}"));
ok($objTh->lt("\x{E5A}", "\x{E5B}"));
ok($objTh->lt("\x{E5B}", "\x{E46}"));

# 47
