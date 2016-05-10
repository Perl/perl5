use strict;
use warnings;

BEGIN { require "t/tools.pl" };

ok(1, "");

tests foo => sub {
    ok(1, "name");
    ok(1, "");
};

done_testing;
