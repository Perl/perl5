BEGIN {
    if ($ENV{PERL_CORE}) {
	unless ($ENV{PERL_TEST_Net_Ping}) {
	    print "1..0 # Skip: network dependent test\n";
	    exit;
	}
	chdir 't' if -d 't';
	@INC = qw(../lib);
    }
}

# Test to make sure object can be instantiated for icmp protocol.
# Root access is required to actually perform icmp testing.

use Test;
use Net::Ping;
plan tests => 2;

# Everything loaded fine
ok 1;

my $p = new Net::Ping "tcp";
ok !!$p;
