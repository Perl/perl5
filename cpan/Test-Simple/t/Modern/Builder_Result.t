use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Result';

can_ok('Test::Builder::Result', qw/trace pid depth in_todo source constructed/);

my $one = Test::Builder::Result->new(
    trace => {},
    depth => 1,
    in_todo => 0,
    source => 'foo.t',
);

isa_ok($one, 'Test::Builder::Result');
is($one->depth, 1, "Got depth");
is($one->pid, $$, "Auto-populated pid");
ok($one->constructed, "auto-populated constructed" );

is($one->type, 'result', "Got type");

is($one->indent, '    ', "Indent 4 spaces per depth");

no warnings 'once';
@Test::Builder::Result::Fake::ISA = ('Test::Builder::Result');
bless $one, 'Test::Builder::Result::Fake';
is($one->type, 'fake', "Got type (subclass)");

done_testing;
