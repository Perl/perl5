use warnings;
use strict;

use Test::More tests => 2;
BEGIN {use_ok('Net::Ping')};

my $result = pingecho("127.0.0.1");
is($result, 1, "pingecho works");
