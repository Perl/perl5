
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
BEGIN { plan tests => 31 };

use strict;
use warnings;
use Unicode::Collate;

ok(1);

#########################

use Unicode::Collate::CJK::JISX0208;

my $collator = Unicode::Collate->new(
    table => undef,
    normalization => undef,
    overrideCJK => \&Unicode::Collate::CJK::JISX0208::weightJISX0208
);

$collator->change(level => 1);

# first ten kanji
ok($collator->lt("\x{4E9C}", "\x{5516}"));
ok($collator->lt("\x{5516}", "\x{5A03}"));
ok($collator->lt("\x{5A03}", "\x{963F}"));
ok($collator->lt("\x{963F}", "\x{54C0}"));
ok($collator->lt("\x{54C0}", "\x{611B}"));
ok($collator->lt("\x{611B}", "\x{6328}"));
ok($collator->lt("\x{6328}", "\x{59F6}"));
ok($collator->lt("\x{59F6}", "\x{9022}"));
ok($collator->lt("\x{9022}", "\x{8475}"));

# last five kanji and undef
ok($collator->lt("\x{69C7}", "\x{9059}"));
ok($collator->lt("\x{9059}", "\x{7464}"));
ok($collator->lt("\x{7464}", "\x{51DC}"));
ok($collator->lt("\x{51DC}", "\x{7199}"));
ok($collator->lt("\x{7199}", "\x{4E02}")); # 4E02: UIdeo undef in JIS X 0208
ok($collator->lt("\x{4E02}", "\x{3400}")); # 3400: Ext.A undef in JIS X 0208

# Ext.B
ok($collator->lt("\x{20000}", "\x{20001}"));
ok($collator->lt("\x{20001}", "\x{20002}"));
ok($collator->lt("\x{20002}", "\x{20003}"));
ok($collator->lt("\x{20003}", "\x{20004}"));
ok($collator->lt("\x{20004}", "\x{20005}"));

$collator->change(overrideCJK => undef);

ok($collator->lt("\x{4E00}", "\x{4E01}"));
ok($collator->lt("\x{4E01}", "\x{4E02}"));
ok($collator->lt("\x{4E02}", "\x{4E03}"));
ok($collator->lt("\x{4E03}", "\x{4E04}"));
ok($collator->lt("\x{4E04}", "\x{4E05}"));

ok($collator->lt("\x{9F9B}", "\x{9F9C}"));
ok($collator->lt("\x{9F9C}", "\x{9F9D}"));
ok($collator->lt("\x{9F9D}", "\x{9F9E}"));
ok($collator->lt("\x{9F9E}", "\x{9F9F}"));
ok($collator->lt("\x{9F9F}", "\x{9FA0}"));

