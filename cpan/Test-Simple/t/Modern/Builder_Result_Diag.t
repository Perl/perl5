use strict;
use warnings;

use Test::More 'modern';
use Scalar::Util qw/isweak/;

require_ok 'Test::Builder::Result::Diag';

can_ok('Test::Builder::Result::Diag', qw/message/);

my $one = Test::Builder::Result::Diag->new(message => "\nFooo\nBar\nBaz\n");

isa_ok($one, 'Test::Builder::Result::Diag');
isa_ok($one, 'Test::Builder::Result');

is($one->to_tap, "\n# Fooo\n# Bar\n# Baz\n", "Got tap output");

$one->message( "foo bar\n" );
is($one->to_tap, "# foo bar\n", "simple tap");

is($one->linked, undef, "Not linked");

require Test::Builder::Result::Ok;
my $ok = Test::Builder::Result::Ok->new(
    bool      => 0,
    real_bool => 0,
    trace     => Test::Builder::Trace->new
);

$one->linked($ok);
is($one->linked, $ok, "Now linked");
ok(isweak($one->{linked}), "Link reference is weak");

my $two = Test::Builder::Result::Diag->new(message => 'foo', linked => $ok);
ok(isweak($two->{linked}), "Link reference is weak even on construction");

done_testing;
