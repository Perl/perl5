# Test to make sure object can be instantiated for stream protocol.

use Test;
use Net::Ping;
plan tests => 2;

# Everything loaded fine
ok 1;

my $p = new Net::Ping "stream";
ok !!$p;
