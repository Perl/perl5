#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config;
    if (($Config::Config{'extensions'} !~ /\bre\b/) ){
	print "1..0 # Skip -- Perl configured without re module\n";
	exit 0;
    }
}

use strict;
require "./test.pl";
my $out = runperl(progfile => "../ext/re/t/lexical_debug.pl", stderr => 1 );

print "1..7\n";

# Each pattern will produce an EXACT node with a specific string in 
# it, so we will look for that. We can't just look for the string
# alone as the string being matched against contains all of them.

ok( $out =~ /EXACT <foo>/, "Expect 'foo'");
ok( $out !~ /EXACT <bar>/, "No 'bar'");
ok( $out =~ /EXACT <baz>/, "Expect 'baz'");
ok( $out !~ /EXACT <bop>/, "No 'bop'");
ok( $out =~ /EXACT <fip>/, "Expect 'fip'");
ok( $out !~ /EXACT <fop>/, "No 'baz'");
ok( $out =~ /Count=6\n/,"Count is 6");

