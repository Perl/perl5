
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
BEGIN { plan tests => 25 };

use strict;
use warnings;
use Unicode::Collate;

ok(1);

#########################

use Unicode::Collate::CJK::Pinyin;

my $collator = Unicode::Collate->new(
    table => undef,
    normalization => undef,
    overrideCJK => \&Unicode::Collate::CJK::Pinyin::weightPinyin
);

$collator->change(level => 1);

ok($collator->lt("\x{5416}", "\x{963F}"));
ok($collator->lt("\x{963F}", "\x{554A}"));
ok($collator->lt("\x{554A}", "\x{9515}"));
ok($collator->lt("\x{9515}", "\x{9312}"));
ok($collator->lt("\x{9312}", "\x{55C4}"));
ok($collator->lt("\x{55C4}", "\x{5391}"));
ok($collator->lt("\x{5391}", "\x{54CE}"));
ok($collator->lt("\x{54CE}", "\x{54C0}"));
ok($collator->lt("\x{54C0}", "\x{5509}"));
ok($collator->lt("\x{5509}", "\x{57C3}"));

ok($collator->lt("\x{57C3}", "\x{4E00}"));
ok($collator->lt("\x{4E00}", "\x{8331}"));

ok($collator->lt("\x{5EA7}", "\x{888F}"));
ok($collator->lt("\x{888F}", "\x{505A}"));
ok($collator->lt("\x{505A}", "\x{8444}"));
ok($collator->lt("\x{8444}", "\x{84D9}"));
ok($collator->lt("\x{84D9}", "\x{98F5}"));
ok($collator->lt("\x{98F5}", "\x{7CF3}"));
ok($collator->lt("\x{7CF3}", "\x{5497}"));

# Ext.B
ok($collator->lt("\x{20000}", "\x{20001}"));
ok($collator->lt("\x{20001}", "\x{20002}"));
ok($collator->lt("\x{20002}", "\x{20003}"));
ok($collator->lt("\x{20003}", "\x{20004}"));
ok($collator->lt("\x{20004}", "\x{20005}"));

