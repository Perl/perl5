use strict;
use warnings;
BEGIN { require "t/tools.pl" };
use Test2::Event::Bail;

my $bail = Test2::Event::Bail->new(
    trace => 'fake',
    reason => 'evil',
);

ok($bail->causes_fail, "bailout always causes fail.");

is($bail->terminate, 255, "Bail will cause the test to exit.");
is($bail->global, 1, "Bail is global, everything should bail");

my $hub = Test2::Hub->new;
ok($hub->is_passing, "passing");
ok(!$hub->failed, "no failures");

$bail->callback($hub);
is($hub->bailed_out, $bail, "set bailed out");

is($bail->summary, "Bail out!  evil", "Summary includes reason");
$bail->set_reason("");
is($bail->summary, "Bail out!", "Summary has no reason");

ok($bail->diagnostics, "Bail events are counted as diagnostics");

done_testing;
