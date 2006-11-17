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

use Test::More; # test count at bottom of file
use re qw(is_regexp regexp_pattern regmust);
my $qr=qr/foo/i;

ok(is_regexp($qr),'is_regexp($qr)');
ok(!is_regexp(''),'is_regexp("")');
is((regexp_pattern($qr))[0],'foo','regexp_pattern[0]');
is((regexp_pattern($qr))[1],'i','regexp_pattern[1]');
is(regexp_pattern($qr),'(?i-xsm:foo)','scalar regexp_pattern');
ok(!regexp_pattern(''),'!regexp_pattern("")');
{
    my $qr=qr/here .* there/x;
    my ($anchored,$floating)=regmust($qr);
    is($anchored,'here',"Regmust anchored - qr//");
    is($floating,'there',"Regmust floating - qr//");
    my $foo='blah';
    ($anchored,$floating)=regmust($foo);
    is($anchored,undef,"Regmust anchored - non ref");
    is($floating,undef,"Regmust anchored - non ref");
    my $bar=['blah'];
    ($anchored,$floating)=regmust($foo);
    is($anchored,undef,"Regmust anchored - ref");
    is($floating,undef,"Regmust anchored - ref");
}

# New tests above this line, don't forget to update the test count below!
use Test::More tests => 12;
# No tests here!
