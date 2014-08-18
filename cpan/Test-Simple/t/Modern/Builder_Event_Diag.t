use strict;
use warnings;

use Test::More 'modern';
use Scalar::Util qw/isweak/;

require_ok 'Test::Builder::Event::Diag';

can_ok('Test::Builder::Event::Diag', qw/message/);

my $one = Test::Builder::Event::Diag->new(message => "\nFooo\nBar\nBaz\n");

isa_ok($one, 'Test::Builder::Event::Diag');
isa_ok($one, 'Test::Builder::Event');

is($one->to_tap, "\n# Fooo\n# Bar\n# Baz\n", "Got tap output");

$one->message( "foo bar\n" );
is($one->to_tap, "# foo bar\n", "simple tap");

is($one->linked, undef, "Not linked");

require Test::Builder::Event::Ok;
my $ok = Test::Builder::Event::Ok->new(
    bool      => 0,
    real_bool => 0,
    trace     => Test::Builder::Trace->new
);

$one->linked($ok);
is($one->linked, $ok, "Now linked");
ok(isweak($one->{linked}), "Link reference is weak");

my $two = Test::Builder::Event::Diag->new(message => 'foo', linked => $ok);
ok(isweak($two->{linked}), "Link reference is weak even on construction");

done_testing;
