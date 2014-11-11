use strict;
use warnings;

use Test::More;
use Test::Stream::Tester;

my $events = intercept {
    local $TODO = "";
    ok(0, "Should not be in todo 1");

    local $TODO = 0;
    ok(0, "Should not be in todo 2");

    local $TODO = undef;
    ok(0, "Should not be in todo 3");

    local $TODO = "foo";
    ok(0, "Should be in todo");
};

events_are(
    $events,
    check {
        event ok => { in_todo => 0 };
        event ok => { in_todo => 0 };
        event ok => { in_todo => 0 };
        event ok => { in_todo => 1 };
        directive 'end';
    },
    "Verify TODO state"
);

my $i = 0;
for my $e (@$events) {
    next if $e->context->in_todo;

    my @tap = $e->to_tap(++$i);
    my $ok_line = $tap[0];
    chomp(my $text = $ok_line->[1]);
    is($text, "not ok $i - Should not be in todo $i", "No TODO directive $i");
}

done_testing;
