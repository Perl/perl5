use strict; use warnings;

use Memoize qw(memoize unmemoize);
use Test::More tests => 19;

# Memoizing a function multiple times separately is not very useful
# but it should not break unmemoize or make memoization lose its mind

my $ret;
my $dummy = sub { $ret };
ok memoize $dummy, INSTALL => 'memo1';
ok memoize $dummy, INSTALL => 'memo2';
ok defined &memo1, 'memoized once';
ok defined &memo2, 'memoized twice';
$@ = '';
ok eval { unmemoize 'memo1' }, 'unmemoized once';
is $@, '', '... and no exception';
$@ = '';
ok eval { unmemoize 'memo2' }, 'unmemoized twice';
is $@, '', '... and no exception';
is \&memo1, $dummy, 'unmemoized installed once';
is \&memo2, $dummy, 'unmemoized installed twice';

my @quux = qw(foo bar baz);
my %memo = map +($_ => memoize $dummy), @quux;
for (@quux) { $ret = $_;  is $memo{$_}->(), $_, "\$memo{$_}->() returns $_" }
for (@quux) { undef $ret; is $memo{$_}->(), $_, "\$memo{$_}->() returns $_" }

my $destroyed = 0;
sub Counted::DESTROY { ++$destroyed }
{
	my $memo = memoize $dummy, map +( "$_\_CACHE" => [ HASH => bless {}, 'Counted' ] ), qw(LIST SCALAR);
	ok $memo, 'memoize anon';
	ok eval { unmemoize $memo }, 'unmemoized anon';
}
is $destroyed, 2, 'no cyclic references';
