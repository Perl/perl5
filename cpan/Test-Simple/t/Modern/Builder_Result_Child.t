use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Result::Child';

my $one = Test::Builder::Result::Child->new();

isa_ok($one, 'Test::Builder::Result::Child');
isa_ok($one, 'Test::Builder::Result');

can_ok($one, qw/name is_subtest action/);

ok(  eval { $one->action('push'); 1 }, "push is valid" );
ok(  eval { $one->action('pop');  1 }, "pop is valid" );
ok( !eval { $one->action('foo');  1 }, "nothing else is valid" );
like($@, qr/action must be one of 'push' or 'pop'/, "useful message");

ok(!$one->to_tap, "no real tap");

done_testing;
