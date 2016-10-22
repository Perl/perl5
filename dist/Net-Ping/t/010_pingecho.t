use warnings;
use strict;

BEGIN {
  unless (my $port = getservbyname('echo', 'tcp')) {
    print "1..0 \# Skip: no echo port\n";
    exit;
  }
}

use Test::More tests => 2;
BEGIN {use_ok('Net::Ping')};

my $result = pingecho("127.0.0.1");
is($result, 1, "pingecho works");
