use strict;
use warnings;

BEGIN { require "t/tools.pl" };

use Test2::API qw/run_subtest intercept/;

my $events = intercept {
    my $code = sub { ok(1) };
    run_subtest('blah', $code, 'buffered');
};

ok(!$events->[0]->in_subtest, "main event is not inside a subtest");
ok($events->[0]->subtest_id, "Got subtest id");
ok($events->[0]->subevents->[0]->in_subtest, "nested events are in the subtest");

done_testing;
