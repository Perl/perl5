use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'Test::Stream::PackageUtil';

can_ok(__PACKAGE__, qw/package_sym package_purge_sym/);

my $ok = package_sym(__PACKAGE__, CODE => 'ok');
is($ok, \&ok, "package sym gave us the code symbol");

my $todo = package_sym(__PACKAGE__, SCALAR => 'TODO');
is($todo, \$TODO, "got the TODO scalar");

our $foo = 'foo';
our @foo = ('f', 'o', 'o');
our %foo = (f => 'oo');
sub foo { 'foo' };

is(foo(), 'foo', "foo() is defined");
is($foo, 'foo', '$foo is defined');
is_deeply(\@foo, [ 'f', 'o', 'o' ], '@foo is defined');
is_deeply(\%foo, { f => 'oo' }, '%foo is defined');

package_purge_sym(__PACKAGE__, CODE => 'foo');

is($foo, 'foo', '$foo is still defined');
is_deeply(\@foo, [ 'f', 'o', 'o' ], '@foo is still defined');
is_deeply(\%foo, { f => 'oo' }, '%foo is still defined');
my $r = eval { foo() };
my $e = $@;
ok(!$r, "Failed to call foo()");
like($e, qr/Undefined subroutine &main::foo called/, "foo() is not defined anymore");
ok(!__PACKAGE__->can('foo'), "can() no longer thinks we can do foo()");

done_testing;
