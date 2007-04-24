#!./perl -w
# tests state variables

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use feature "state";

plan tests => 37;

ok( ! defined state $uninit, q(state vars are undef by default) );

# basic functionality

sub stateful {
    state $x;
    state $y //= 1;
    my $z = 2;
    state ($t) //= 3;
    return ($x++, $y++, $z++, $t++);
}

my ($x, $y, $z, $t) = stateful();
is( $x, 0, 'uninitialized state var' );
is( $y, 1, 'initialized state var' );
is( $z, 2, 'lexical' );
is( $t, 3, 'initialized state var, list syntax' );

($x, $y, $z, $t) = stateful();
is( $x, 1, 'incremented state var' );
is( $y, 2, 'incremented state var' );
is( $z, 2, 'reinitialized lexical' );
is( $t, 4, 'incremented state var, list syntax' );

($x, $y, $z, $t) = stateful();
is( $x, 2, 'incremented state var' );
is( $y, 3, 'incremented state var' );
is( $z, 2, 'reinitialized lexical' );
is( $t, 5, 'incremented state var, list syntax' );

# in a nested block

sub nesting {
    state $foo //= 10;
    my $t;
    { state $bar //= 12; $t = ++$bar }
    ++$foo;
    return ($foo, $t);
}

($x, $y) = nesting();
is( $x, 11, 'outer state var' );
is( $y, 13, 'inner state var' );

($x, $y) = nesting();
is( $x, 12, 'outer state var' );
is( $y, 14, 'inner state var' );

# in a closure

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

# with ties
{
    package countfetches;
    our $fetchcount = 0;
    sub TIESCALAR {bless {}};
    sub FETCH { ++$fetchcount; 18 };
    tie my $y, "countfetches";
    sub foo { state $x //= $y; $x++ }
    ::is( foo(), 18, "initialisation with tied variable" );
    ::is( foo(), 19, "increments correctly" );
    ::is( foo(), 20, "increments correctly, twice" );
    ::is( $fetchcount, 1, "fetch only called once" );
}

# state variables are shared among closures

sub gen_cashier {
    my $amount = shift;
    state $cash_in_store;
    return {
	add => sub { $cash_in_store += $amount },
	del => sub { $cash_in_store -= $amount },
	bal => sub { $cash_in_store },
    };
}

gen_cashier(59)->{add}->();
gen_cashier(17)->{del}->();
is( gen_cashier()->{bal}->(), 42, '$42 in my drawer' );

# stateless assignment to a state variable

sub stateless {
    state $reinitme = 42;
    ++$reinitme;
}
is( stateless(), 43, 'stateless function, first time' );
is( stateless(), 43, 'stateless function, second time' );

# array state vars

sub stateful_array {
    state @x;
    push @x, 'x';
    return $#x;
}

my $xsize = stateful_array();
is( $xsize, 0, 'uninitialized state array' );

$xsize = stateful_array();
is( $xsize, 1, 'uninitialized state array after one iteration' );

# hash state vars

sub stateful_hash {
    state %hx;
    return $hx{foo}++;
}

my $xhval = stateful_hash();
is( $xhval, 0, 'uninitialized state hash' );

$xhval = stateful_hash();
is( $xhval, 1, 'uninitialized state hash after one iteration' );

# Recursion

sub noseworth {
    my $level = shift;
    state $recursed_state = 123;
    is($recursed_state, 123, "state kept through recursion ($level)");
    noseworth($level - 1) if $level;
}
noseworth(2);

# Assignment return value

sub pugnax { my $x = state $y = 42; $y++; $x; }

is( pugnax(), 42, 'scalar state assignment return value' );
