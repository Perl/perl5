use strict;
use warnings;

BEGIN { require "t/tools.pl" };

use Test2::API qw/run_subtest intercept/;

my $events = intercept {
    my $code = sub { plan 4; ok(1) };
    run_subtest('bad_plan', $code, 'buffered');
};

is(
    $events->[-1]->message,
    "Bad subtest plan, expected 4 but ran 1",
    "Helpful message if subtest has a bad plan",
);

done_testing;
