use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::Event::Plan;
use Test2::Util::Trace;

my $plan = Test2::Event::Plan->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    max => 100,
);

is($plan->summary, "Plan is 100 assertions", "simple summary");
is_deeply( [$plan->sets_plan], [100, '', undef], "Got plan details");

ok(!$plan->global, "regular plan is not a global event");
my $state = Test2::Hub->new;
$plan->callback($state);
is($state->plan, 100, "set plan in state");
is($plan->terminate, undef, "No terminate for normal plan");

$plan->set_max(0);
$plan->set_directive('SKIP');
$plan->set_reason('foo');
$state = Test2::Hub->new;
$plan->callback($state);
is($state->plan, 'SKIP', "set plan in state");
is($plan->terminate, 0, "Terminate 0 on skip_all");

is($plan->summary, "Plan is 'SKIP', foo", "skip summary");
is_deeply( [$plan->sets_plan], [0, 'SKIP', 'foo'], "Got skip details");

$plan->set_max(0);
$plan->set_directive('NO PLAN');
$plan->set_reason(undef);
is($plan->summary, "Plan is 'NO PLAN'", "NO PLAN summary");
is_deeply( [$plan->sets_plan], [0, 'NO PLAN', undef], "Got 'NO PLAN' details");
$state = Test2::Hub->new;
$plan->callback($state);
is($state->plan, 'NO PLAN', "set plan in state");
is($plan->terminate, undef, "No terminate for no_plan");
$plan->set_max(100);
$plan->set_directive(undef);
$plan->callback($state);
is($state->plan, '100', "Update plan in state if it is 'NO PLAN'");

$plan = Test2::Event::Plan->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    max => 0,
    directive => 'skip_all',
);
is($plan->directive, 'SKIP', "Change skip_all to SKIP");

$plan = Test2::Event::Plan->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    max => 0,
    directive => 'no_plan',
);
is($plan->directive, 'NO PLAN', "Change no_plan to 'NO PLAN'");
ok(!$plan->global, "NO PLAN is not global");

like(
    exception {
        $plan = Test2::Event::Plan->new(
            trace     => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
            max       => 0,
            directive => 'foo',
        );
    },
    qr/'foo' is not a valid plan directive/,
    "Invalid Directive"
);

like(
    exception {
        $plan = Test2::Event::Plan->new(
            trace  => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
            max    => 0,
            reason => 'foo',
        );
    },
    qr/Cannot have a reason without a directive!/,
    "Reason without directive"
);

like(
    exception {
        $plan = Test2::Event::Plan->new(
            trace  => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
        );
    },
    qr/No number of tests specified/,
    "Nothing to do"
);

like(
    exception {
        $plan = Test2::Event::Plan->new(
            trace  => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
            max => 'skip',
        );
    },
    qr/Plan test count 'skip' does not appear to be a valid positive integer/,
    "Max must be an integer"
);

done_testing;
