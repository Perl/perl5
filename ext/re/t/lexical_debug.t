#!./perl

BEGIN {
    require Config;
    if (($Config::Config{'extensions'} !~ /\bre\b/) ){
	print "1..0 # Skip -- Perl configured without re module\n";
	exit 0;
    }
}

use strict;

# must use a BEGIN or the prototypes wont be respected meaning 
# tests could pass that shouldn't
BEGIN { require "../../t/test.pl"; }
my $out = runperl(progfile => "t/lexical_debug.pl", stderr => 1 );

print "1..19\n";

# Each pattern will produce an EXACT node with a specific string in 
# it, so we will look for that. We can't just look for the string
# alone as the string being matched against contains all of them.

ok( $out =~ /EXACT <foo>/, "Expect 'foo'"    );
ok( $out !~ /EXACT <bar>/, "No 'bar'"        );
ok( $out =~ /EXACT <baz>/, "Expect 'baz'"    );
ok( $out !~ /EXACT <bop>/, "No 'bop'"        );
ok( $out =~ /EXACT <boq>/, "Expect 'boq'"    );
ok( $out !~ /EXACT <bor>/, "No 'bor'"        );
ok( $out =~ /EXACT <fip>/, "Expect 'fip'"    );
ok( $out !~ /EXACT <fop>/, "No 'baz'"        );
ok( $out =~ /<liz>/,       "Got 'liz'"       ); # in a TRIE so no EXACT
ok( $out =~ /<zoo>/,       "Got 'zoo'"       ); # in a TRIE so no EXACT
ok( $out =~ /<zap>/,       "Got 'zap'"       ); # in a TRIE so no EXACT
ok( $out =~ /Count=9\n/,   "Count is 9")
    or diag($out);

my $native = runperl(prog => <<'PROG', stderr => 1);
use re Debug => qw(TRIEE);
my ($e, $f, $bad) = map { chr utf8::unicode_to_native($_) } (0xe9, 0xef, 0xea);
my $re = qr/\A.(?:${e}a|${f}b)\z/;
my @matched;
for my $target (q(X).$e.q(a), q(X).$bad.q(a), q(Xqa)) {
    push @matched, $target =~ $re ? 1 : 0;
}
print qq(matched: @matched\n);
PROG

is(scalar(() = $native =~ /native input, fused octet transitions/g), 3,
   'tracing executes the fused native loop for each target');
my $e = sprintf '%X', utf8::unicode_to_native(0xe9);
like($native, qr/TRIE: Char:0x$e\s+CP:0x$e\s+.* - good ->.* via St:0x[1-9A-F]/,
     'trace shows a successful two-octet character and its middle state');
my $bad = sprintf '%X', utf8::unicode_to_native(0xea);
like($native, qr/TRIE: Char:0x$bad\s+CP:0x$bad\s+.* - fail ->.* via St:0x[1-9A-F]/,
     'trace shows a failed continuation transition and its middle state');
my $q = sprintf '%X', ord 'q';
like($native, qr/TRIE: Char:0x$q\s+.* - fail ->/,
     'trace shows a failed first transition');
my $a = sprintf '%X', ord 'a';
like($native, qr/TRIE: Char:0x$a\s+.* - good ->/,
     'trace shows an invariant native character');
unlike($native, qr/TRIE: Octet:/,
       'native trace reports characters rather than individual UTF octets');
like($native, qr/matched: 1 0 0/, 'traced matches give the expected results');
