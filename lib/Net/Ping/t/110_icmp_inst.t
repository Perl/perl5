# Test to make sure object can be instantiated for icmp protocol.
# Root access is required to actually perform icmp testing.

use Test;
use Net::Ping;
plan tests => 2;

# Everything loaded fine
ok 1;

my $p = new Net::Ping "tcp";
ok !!$p;
