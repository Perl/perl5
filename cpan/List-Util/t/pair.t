#!./perl

use strict;
use Test::More tests => 13;
use List::Util qw(pairgrep pairmap pairs pairkeys pairvalues);

is_deeply( [ pairgrep { $b % 2 } one => 1, two => 2, three => 3 ],
           [ one => 1, three => 3 ],
           'pairgrep list' );

is( scalar( pairgrep { $b & 2 } one => 1, two => 2, three => 3 ),
    2,
    'pairgrep scalar' );

is_deeply( [ pairgrep { $a } 0 => "zero", 1 => "one", 2 ],
           [ 1 => "one", 2 => undef ],
           'pairgrep pads with undef' );

{
  my @kvlist = ( one => 1, two => 2 );
  pairgrep { $b++ } @kvlist;
  is_deeply( \@kvlist, [ one => 2, two => 3 ], 'pairgrep aliases elements' );
}

is_deeply( [ pairmap { uc $a => $b } one => 1, two => 2, three => 3 ],
           [ ONE => 1, TWO => 2, THREE => 3 ],
           'pairmap list' );

is_deeply( [ pairmap { $a => @$b } one => [1,1,1], two => [2,2,2], three => [3,3,3] ],
           [ one => 1, 1, 1, two => 2, 2, 2, three => 3, 3, 3 ],
           'pairmap list returning >2 items' );

is_deeply( [ pairmap { $b } one => 1, two => 2, three => ],
           [ 1, 2, undef ],
           'pairmap pads with undef' );

{
  my @kvlist = ( one => 1, two => 2 );
  pairmap { $b++ } @kvlist;
  is_deeply( \@kvlist, [ one => 2, two => 3 ], 'pairmap aliases elements' );
}

# Calculating a 1000-element list should hopefully cause the stack to move
# underneath pairmap
is_deeply( [ pairmap { my @l = (1) x 1000; "$a=$b" } one => 1, two => 2, three => 3 ],
           [ "one=1", "two=2", "three=3" ],
           'pairmap copes with stack movement' );

is_deeply( [ pairs one => 1, two => 2, three => 3 ],
           [ [ one => 1 ], [ two => 2 ], [ three => 3 ] ],
           'pairs' );

is_deeply( [ pairs one => 1, two => ],
           [ [ one => 1 ], [ two => undef ] ],
           'pairs pads with undef' );

is_deeply( [ pairkeys one => 1, two => 2 ],
           [qw( one two )],
           'pairkeys' );

is_deeply( [ pairvalues one => 1, two => 2 ],
           [ 1, 2 ],
           'pairvalues' );
