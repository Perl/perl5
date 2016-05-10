use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::Event::Subtest;
my $st = 'Test2::Event::Subtest';

my $trace = Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__, 'xxx']);
my $one = $st->new(
    trace     => $trace,
    pass      => 1,
    buffered  => 1,
    name      => 'foo',
    subtest_id => "1-1-1",
);

ok($one->isa('Test2::Event::Ok'), "Inherit from Ok");
is_deeply($one->subevents, [], "subevents is an arrayref");

is($one->summary, "foo", "simple summary");
$one->set_todo('');
is($one->summary, "foo (TODO)", "simple summary + TODO");
$one->set_todo('foo');
is($one->summary, "foo (TODO: foo)", "simple summary + TODO + Reason");

$one->set_todo(undef);
$one->set_name('');
is($one->summary, "Nameless Subtest", "unnamed summary");

done_testing;
