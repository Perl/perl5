#!./perl -w

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    if (ord("A") == 193) {
        print "1..0 # Skip: EBCDIC\n";
        exit 0;
    }
    unless (PerlIO::Layer->find('perlio')){
        print "1..0 # Skip: PerlIO required\n";
        exit 0;
    }
    eval 'use Encode';
    if ($@ =~ /dynamic loading not available/) {
        print "1..0 # Skip: no dynamic loading, no Encode\n";
        exit 0;
    }
}

use strict;
use Test::More tests => (4 * 4 * 4) * (3); # (@char ** 3) * (keys %mbchars)

# %mbchars = (encoding => { bytes => utf8, ... }, ...);
# * pack('C*') is expected to return bytes even if ${^ENCODING} is true.
our %mbchars = (
    'big-5' => {
	pack('C*', 0x40)       => pack('U*', 0x40), # COMMERCIAL AT
	pack('C*', 0xA4, 0x40) => "\x{4E00}",       # CJK-4E00
    },
    'euc-jp' => {
	pack('C*', 0xB0, 0xA1)       => "\x{4E9C}", # CJK-4E9C
	pack('C*', 0x8F, 0xB0, 0xA1) => "\x{4E02}", # CJK-4E02
    },
    'shift-jis' => {
	pack('C*', 0xA9)       => "\x{FF69}", # halfwidth katakana small U
	pack('C*', 0x82, 0xA9) => "\x{304B}", # hiragana KA
    },
);

for my $enc (sort keys %mbchars) {
    local ${^ENCODING} = find_encoding($enc);
    my @char = (sort(keys   %{ $mbchars{$enc} }),
		sort(values %{ $mbchars{$enc} }));

    for my $rs (@char) {
	local $/ = $rs;
	for my $start (@char) {
	    for my $end (@char) {
		my $string = $start.$end;
		my $expect = $end eq $rs ? $start : $string;
		chomp $string;
		is($string, $expect);
	    }
	}
    }
}
