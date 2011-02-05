#!./perl

BEGIN {
    require Config;
    if (($Config::Config{'extensions'} !~ /\bre\b/) ){
	print "1..0 # Skip -- Perl configured without re module\n";
	exit 0;
    }
}

use strict;

use Test::More tests => 10;
use Test::PerlRun 'perlrun';

my ($out, $err) = perlrun({file => "t/lexical_debug.pl"});

is($out, "Count=7\n", "Count is 7");

# Each pattern will produce an EXACT node with a specific string in 
# it, so we will look for that. We can't just look for the string
# alone as the string being matched against contains all of them.

like($err, qr/EXACT <foo>/,   "Expect 'foo'"    );
unlike($err, qr/EXACT <bar>/, "No 'bar'"        );
like($err, qr/EXACT <baz>/,   "Expect 'baz'"    );
unlike($err, qr/EXACT <bop>/, "No 'bop'"        );
like($err, qr/EXACT <fip>/,   "Expect 'fip'"    );
unlike($err, qr/EXACT <fop>/, "No 'baz'"        );
like($err, qr/<liz>/,         "Got 'liz'"       ); # in a TRIE so no EXACT
like($err, qr/<zoo>/,         "Got 'zoo'"       ); # in a TRIE so no EXACT
like($err, qr/<zap>/,         "Got 'zap'"       ); # in a TRIE so no EXACT
