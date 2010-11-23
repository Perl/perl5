
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
BEGIN { plan tests => 23 };

use strict;
use warnings;
use Unicode::Collate;

ok(1);

#########################

use Unicode::Collate::CJK::GB2312;

my $collator = Unicode::Collate->new(
    table => undef,
    normalization => undef,
    overrideCJK => \&Unicode::Collate::CJK::GB2312::weightGB2312
);

$collator->change(level => 1);

ok($collator->lt("\x{554A}", "\x{963F}"));
ok($collator->lt("\x{963F}", "\x{57C3}"));
ok($collator->lt("\x{57C3}", "\x{6328}"));
ok($collator->lt("\x{6328}", "\x{54CE}"));
ok($collator->lt("\x{54CE}", "\x{5509}"));
ok($collator->lt("\x{5509}", "\x{54C0}"));
ok($collator->lt("\x{54C0}", "\x{7691}"));
ok($collator->lt("\x{7691}", "\x{764C}"));
ok($collator->lt("\x{764C}", "\x{853C}"));
ok($collator->lt("\x{853C}", "\x{77EE}"));

ok($collator->lt("\x{77EE}", "\x{4E00}"));
ok($collator->lt("\x{4E00}", "\x{9F2F}"));

ok($collator->lt("\x{9F2F}", "\x{9F39}"));
ok($collator->lt("\x{9F39}", "\x{9F37}"));
ok($collator->lt("\x{9F37}", "\x{9F3D}"));
ok($collator->lt("\x{9F3D}", "\x{9F3E}"));
ok($collator->lt("\x{9F3E}", "\x{9F44}"));

# Ext.B
ok($collator->lt("\x{20000}", "\x{20001}"));
ok($collator->lt("\x{20001}", "\x{20002}"));
ok($collator->lt("\x{20002}", "\x{20003}"));
ok($collator->lt("\x{20003}", "\x{20004}"));
ok($collator->lt("\x{20004}", "\x{20005}"));

