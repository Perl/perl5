BEGIN { require "t/tools.pl" };
use strict;
use warnings;

use Test2::Event::Skip;
use Test2::Util::Trace;

my $skip = Test2::Event::Skip->new(
    trace  => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    name   => 'skip me',
    reason => 'foo',
);

is($skip->name, 'skip me', "set name");
is($skip->reason, 'foo', "got skip reason");
ok(!$skip->pass, "no default for pass");
ok($skip->effective_pass, "TODO always effectively passes");

is($skip->summary, "skip me (SKIP: foo)", "summary with reason");

$skip->set_reason('');
is($skip->summary, "skip me (SKIP)", "summary without reason");

done_testing;
