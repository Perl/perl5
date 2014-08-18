use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Event';

can_ok('Test::Builder::Event', qw/trace pid depth in_todo source constructed/);

my $one = Test::Builder::Event->new(
    trace => {},
    depth => 1,
    in_todo => 0,
    source => 'foo.t',
);

isa_ok($one, 'Test::Builder::Event');
is($one->depth, 1, "Got depth");
is($one->pid, $$, "Auto-populated pid");
ok($one->constructed, "auto-populated constructed" );

is($one->type, 'event', "Got type");

is($one->indent, '    ', "Indent 4 spaces per depth");

no warnings 'once';
@Test::Builder::Event::Fake::ISA = ('Test::Builder::Event');
bless $one, 'Test::Builder::Event::Fake';
is($one->type, 'fake', "Got type (subclass)");

done_testing;

