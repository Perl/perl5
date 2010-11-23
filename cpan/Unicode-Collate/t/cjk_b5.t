
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
use Unicode::Collate;

ok(1);

#########################

use Unicode::Collate::CJK::Big5;

my $collator = Unicode::Collate->new(
    table => undef,
    normalization => undef,
    overrideCJK => \&Unicode::Collate::CJK::Big5::weightBig5
);

$collator->change(level => 1);

ok($collator->lt("\x{5159}", "\x{515B}"));
ok($collator->lt("\x{515B}", "\x{515E}"));
ok($collator->lt("\x{515E}", "\x{515D}"));
ok($collator->lt("\x{515D}", "\x{5161}"));
ok($collator->lt("\x{5161}", "\x{5163}"));
ok($collator->lt("\x{5163}", "\x{55E7}"));
ok($collator->lt("\x{55E7}", "\x{74E9}"));
ok($collator->lt("\x{74E9}", "\x{7CCE}"));
ok($collator->lt("\x{7CCE}", "\x{4E00}"));
ok($collator->lt("\x{4E00}", "\x{4E59}"));
ok($collator->lt("\x{4E59}", "\x{4E01}"));
ok($collator->lt("\x{4E01}", "\x{4E03}"));
ok($collator->lt("\x{4E03}", "\x{4E43}"));
ok($collator->lt("\x{4E43}", "\x{4E5D}"));
ok($collator->lt("\x{4E5D}", "\x{4E86}"));

ok($collator->lt("\x{7069}", "\x{706A}"));
ok($collator->lt("\x{706A}", "\x{9EA4}"));
ok($collator->lt("\x{9EA4}", "\x{9F7E}"));
ok($collator->lt("\x{9F7E}", "\x{9F49}"));
ok($collator->lt("\x{9F49}", "\x{9F98}"));

# Ext.B
ok($collator->lt("\x{20000}", "\x{20001}"));
ok($collator->lt("\x{20001}", "\x{20002}"));
ok($collator->lt("\x{20002}", "\x{20003}"));
ok($collator->lt("\x{20003}", "\x{20004}"));
ok($collator->lt("\x{20004}", "\x{20005}"));

