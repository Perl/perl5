#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use feature "state";

plan tests => 23;

ok( ! defined state $uninit, q(state vars are undef by default) );

sub stateful {
    state $x;
    state $y = 1;
    my $z = 2;
    return ($x++, $y++, $z++);
}

my ($x, $y, $z) = stateful();
is( $x, 0, 'uninitialized state var' );
is( $y, 1, 'initialized state var' );
is( $z, 2, 'lexical' );

($x, $y, $z) = stateful();
is( $x, 1, 'incremented state var' );
is( $y, 2, 'incremented state var' );
is( $z, 2, 'reinitialized lexical' );

($x, $y, $z) = stateful();
is( $x, 2, 'incremented state var' );
is( $y, 3, 'incremented state var' );
is( $z, 2, 'reinitialized lexical' );

sub nesting {
    state $foo = 10;
    my $t;
    { state $bar = 12; $t = ++$bar }
    ++$foo;
    return ($foo, $t);
}

($x, $y) = nesting();
is( $x, 11, 'outer state var' );
is( $y, 13, 'inner state var' );

($x, $y) = nesting();
is( $x, 12, 'outer state var' );
is( $y, 14, 'inner state var' );

sub generator {
    my $outer;
    # we use $outer to generate a closure
    sub { ++$outer; ++state $x }
}

my $f1 = generator();
is( $f1->(), 1, 'generator 1' );
is( $f1->(), 2, 'generator 1' );
my $f2 = generator();
is( $f2->(), 1, 'generator 2' );
is( $f1->(), 3, 'generator 1 again' );
is( $f2->(), 2, 'generator 2 once more' );

{
    package countfetches;
    our $fetchcount = 0;
    sub TIESCALAR {bless {}};
    sub FETCH { ++$fetchcount; 18 };
    tie my $y, "countfetches";
    sub foo { state $x = $y; $x++ }
    ::is( foo(), 18, "initialisation with tied variable" );
    ::is( foo(), 19, "increments correctly" );
    ::is( foo(), 20, "increments correctly, twice" );
    ::is( $fetchcount, 1, "fetch only called once" );
}
