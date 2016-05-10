use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::Event::Waiting;

my $waiting = Test2::Event::Waiting->new(
    trace => 'fake',
);

ok($waiting, "Created event");
ok($waiting->global, "waiting is global");

is($waiting->summary, "IPC is waiting for children to finish...", "Got summary");

done_testing;
