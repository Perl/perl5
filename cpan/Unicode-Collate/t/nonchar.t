
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
use strict;
use warnings;

BEGIN {
    use Unicode::Collate;

    unless (exists &Unicode::Collate::bootstrap or 5.008 <= $]) {
	print "1..0 # skipped: XSUB, or Perl 5.8.0 or later".
		" needed for this test\n";
	print $@;
	exit;
    }
}

BEGIN { plan tests => 27 };

ok(1);

#########################

no warnings 'utf8';

# Unicode 6.0 Sorting
#
# Special Database Values. The data files for CLDR provide
# special weights for two noncharacters:
#
# 1. A special noncharacter <HIGH> (U+FFFF) for specification of a range
#    in a database, allowing "Sch" <= X <= "Sch<HIGH>" to pick all strings
#    starting with "sch" plus those that sort equivalently.
# 2. A special noncharacter <LOW> (U+FFFE) for merged database fields,
#    allowing "Disi\x{301}lva<LOW>John" to sort next to "Disilva<LOW>John".

my $Collator = Unicode::Collate->new(
  table => 'keys.txt',
  level => 1,
  normalization => undef,
  UCA_Version => 22,
  entry => <<'ENTRIES',
FFFE  ; [*0001.0020.0005.FFFE] # <noncharacter-FFFE>
FFFF  ; [.FFFE.0020.0005.FFFF] # <noncharacter-FFFF>
ENTRIES
);

# 2..16

ok($Collator->lt("\x{FFFD}",   "\x{FFFF}"));
ok($Collator->lt("\x{1FFFD}",  "\x{1FFFF}"));
ok($Collator->lt("\x{2FFFD}",  "\x{2FFFF}"));
ok($Collator->lt("\x{10FFFD}", "\x{10FFFF}"));

ok($Collator->lt("perl\x{FFFD}",   "perl\x{FFFF}"));
ok($Collator->lt("perl\x{1FFFD}",  "perl\x{FFFF}"));
ok($Collator->lt("perl\x{1FFFE}",  "perl\x{FFFF}"));
ok($Collator->lt("perl\x{1FFFF}",  "perl\x{FFFF}"));
ok($Collator->lt("perl\x{2FFFD}",  "perl\x{FFFF}"));
ok($Collator->lt("perl\x{2FFFE}",  "perl\x{FFFF}"));
ok($Collator->lt("perl\x{2FFFF}",  "perl\x{FFFF}"));
ok($Collator->lt("perl\x{10FFFD}", "perl\x{FFFF}"));
ok($Collator->lt("perl\x{10FFFE}", "perl\x{FFFF}"));
ok($Collator->lt("perl\x{10FFFF}", "perl\x{FFFF}"));

ok($Collator->gt("perl\x{FFFF}AB", "perl\x{FFFF}"));

$Collator->change(level => 4);

# 17..23

my @dsf = (
    "di Silva\x{FFFE}Fred",
    "diSilva\x{FFFE}Fred",
    "di Si\x{301}lva\x{FFFE}Fred",
    "diSi\x{301}lva\x{FFFE}Fred",
);
my @dsj = (
    "di Silva\x{FFFE}John",
    "diSilva\x{FFFE}John",
    "di Si\x{301}lva\x{FFFE}John",
    "diSi\x{301}lva\x{FFFE}John",
);

ok($Collator->lt($dsf[0], $dsf[1]));
ok($Collator->lt($dsf[1], $dsf[2]));
ok($Collator->lt($dsf[2], $dsf[3]));

ok($Collator->lt($dsf[3], $dsj[0]));

ok($Collator->lt($dsj[0], $dsj[1]));
ok($Collator->lt($dsj[1], $dsj[2]));
ok($Collator->lt($dsj[2], $dsj[3]));

# 24..27

my @ds_j = (
    "di Silva John",
    "diSilva John",
    "di Si\x{301}lva John",
    "diSi\x{301}lva John",
);

ok($Collator->lt($ds_j[0], $ds_j[1]));
ok($Collator->lt($ds_j[1], $ds_j[2]));
ok($Collator->lt($ds_j[2], $ds_j[3]));

ok($Collator->lt($dsj[0], $ds_j[0]));

