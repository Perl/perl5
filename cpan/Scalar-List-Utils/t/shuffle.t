#!./perl

use strict;
use warnings;

use Test::More tests => 7;

use List::Util qw(shuffle);

my @r;

@r = shuffle();
ok( !@r,	'no args');

@r = shuffle(9);
is( 0+@r,	1,	'1 in 1 out');
is( $r[0],	9,	'one arg');

my @in = 1..100;
@r = shuffle(@in);
is( 0+@r,	0+@in,	'arg count');

isnt( "@r",	"@in",	'result different to args');

my @s = sort { $a <=> $b } @r;
is( "@in",	"@s",	'values');

{
  local $List::Util::RAND = sub { 4/10 }; # chosen by a fair die

  @r = shuffle(1..10);
  # This random function happens to always generate the same result
  is_deeply( \@r, [ 10, 1, 8, 2, 6, 7, 3, 9, 4, 5 ],
    'rigged rand() yields predictable output'
  );
}
