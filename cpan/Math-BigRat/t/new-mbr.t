#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Math::BigRat;

use Scalar::Util qw< refaddr >;

# CPAN RT #132712.

my $q1 = Math::BigRat -> new("-1/2");
my ($n, $d) = $q1 -> parts();

my $n_orig = $n -> copy();
my $d_orig = $d -> copy();
my $q2 = Math::BigRat -> new($n, $d);

cmp_ok($n, "==", $n_orig,
       "The value of the numerator hasn't changed");
cmp_ok($d, "==", $d_orig,
       "The value of the denominator hasn't changed");

isnt(refaddr($n), refaddr($n_orig),
     "The addresses of the numerators have changed");
isnt(refaddr($d), refaddr($d_orig),
     "The addresses of the denominators have changed");
