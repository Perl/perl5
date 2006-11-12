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

use Test::More tests => 6;
use re qw(is_regexp regexp_pattern);
my $qr=qr/foo/i;

ok(is_regexp($qr),'is_regexp($qr)');
ok(!is_regexp(''),'is_regexp("")');
is((regexp_pattern($qr))[0],'foo','regexp_pattern[0]');
is((regexp_pattern($qr))[1],'i','regexp_pattern[1]');
is(regexp_pattern($qr),'(?i-xsm:foo)','scalar regexp_pattern');
ok(!regexp_pattern(''),'!regexp_pattern("")');
