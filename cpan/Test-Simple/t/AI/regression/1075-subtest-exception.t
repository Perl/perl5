use strict;
use warnings;

use Test::More;
use Test2::API qw/intercept/;

# An exception inside a subtest must fail the subtest, report the error, and
# still propagate to the caller.

my ($err, $events);

$events = intercept(sub {
    eval {
        subtest died_after_a_passing_assertion => sub {
            ok(1, "ran before the exception");
            die "boom\n";
            ok(1, "never runs");
        };
        1;
    } or $err = $@;
});

is($err, "boom\n", "the exception still propagates to the caller");

my ($subtest) = grep { $_->isa('Test2::Event::Subtest') } @$events;
ok($subtest, "got a subtest event");
ok(!$subtest->pass, "the subtest failed");

my @errors = map { @{$_->facet_data->{errors} || []} } @{$subtest->subevents};
is(scalar(@errors), 1, "one error recorded inside the subtest");
like($errors[0]->{details}, qr/^boom/, "the error says what went wrong");

my @asserts = grep { $_->facet_data->{assert} } @{$subtest->subevents};
is(scalar(@asserts), 1, "the assertion that did run is still reported");
ok($asserts[0]->facet_data->{assert}{pass}, "and it still passes");

my @plans = grep { $_->facet_data->{plan} } @{$subtest->subevents};
is(scalar(@plans), 1, "the subtest was still finalized with a plan");

# A subtest that dies before running anything was already a failure, but it
# should now say why.

undef $err;
$events = intercept(sub {
    eval {
        subtest died_before_any_assertion => sub { die "early boom\n" };
        1;
    } or $err = $@;
});

is($err, "early boom\n", "the early exception propagates too");

my ($fail) = grep { $_->facet_data->{assert} && !$_->facet_data->{assert}{pass} } @$events;
ok($fail, "the subtest is reported as a failure");

# Nothing changes for a subtest that completes.

$events = intercept(sub {
    subtest all_good => sub { ok(1, "fine") };
});

my ($passing) = grep { $_->isa('Test2::Event::Subtest') } @$events;
ok($passing->pass, "a subtest that does not die still passes");
is(
    scalar(map { @{$_->facet_data->{errors} || []} } @{$passing->subevents}),
    0,
    "and records no errors"
);

# skip_all inside a subtest is not an exception.

$events = intercept(sub {
    subtest skipper => sub {
        plan skip_all => 'nothing to do here';
        ok(0, "never runs");
    };
});

my ($skipped) = grep { $_->facet_data->{assert} } @$events;
ok($skipped->facet_data->{assert}{pass}, "a subtest that skips all still passes");
is(
    scalar(map { @{$_->facet_data->{errors} || []} } @$events),
    0,
    "and records no errors"
);

done_testing;
