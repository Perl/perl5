# -*- mode: perl; -*-

# Note that this does not test Math::BigFloat upgrading.

use strict;
use warnings;

use Test::More tests => 164;

use Math::BigInt   upgrade   => 'Math::BigFloat';
use Math::BigFloat downgrade => 'Math::BigInt';

# simplistic test for now
is(Math::BigFloat->downgrade(), 'Math::BigInt', 'Math::BigFloat->downgrade()');
is(Math::BigInt->upgrade(), 'Math::BigFloat', 'Math::BigInt->upgrade()');

# bug until v1.67:
is(Math::BigFloat->new("0.2E0"), "0.2", qq|Math::BigFloat->new("0.2E0")|);
is(Math::BigFloat->new("0.2E1"), "2",   qq|Math::BigFloat->new("0.2E1")|);
# until v1.67 resulted in 200:
is(Math::BigFloat->new("0.2E2"), "20",  qq|Math::BigFloat->new("0.2E2")|);

# disable, otherwise it screws calculations
Math::BigFloat->upgrade(undef);
is(Math::BigFloat->upgrade() || "", "", qq/Math::BigFloat->upgrade() || ""/);

Math::BigFloat->div_scale(20);  # make it a bit faster
my $x = Math::BigFloat->new(2);    # downgrades
# the following test upgrade for bsqrt() and also makes new() NOT downgrade
# for the bpow() side
is(Math::BigFloat->bpow("2", "0.5"), $x->bsqrt(),
   qq|Math::BigFloat->bpow("2", "0.5")|);

################################################################################
# Verify that constructors downgrade when they should.

note("Enable downgrading, and see if constructors downgrade");

Math::BigFloat -> downgrade("Math::BigInt");

# new()

$x = Math::BigFloat -> new("0.5");
cmp_ok($x, "==", 0.5);
is(ref $x, "Math::BigFloat", "Creating a 0.5 does not downgrade");

$x = Math::BigFloat -> new("4");
cmp_ok($x, "==", 4, 'new("4")');
is(ref $x, "Math::BigInt", "Creating a 4 downgrades to Math::BigInt");

$x = Math::BigFloat -> new("0");
cmp_ok($x, "==", 0, 'new("0")');
is(ref $x, "Math::BigInt", "Creating a 0 downgrades to Math::BigInt");

$x = Math::BigFloat -> new("1");
cmp_ok($x, "==", 1, 'new("1")');
is(ref $x, "Math::BigInt", "Creating a 1 downgrades to Math::BigInt");

$x = Math::BigFloat -> new("Inf");
cmp_ok($x, "==", "Inf", 'new("inf")');
is(ref $x, "Math::BigInt", "Creating an Inf downgrades to Math::BigInt");

$x = Math::BigFloat -> new("NaN");
is($x, "NaN", 'new("NaN")');
is(ref $x, "Math::BigInt", "Creating a NaN downgrades to Math::BigInt");

# bzero()

$x = Math::BigFloat -> bzero();
cmp_ok($x, "==", 0, "bzero()");
is(ref $x, "Math::BigInt", "Creating a 0 downgrades to Math::BigInt");

# bone()

$x = Math::BigFloat -> bone();
cmp_ok($x, "==", 1, "bone()");
is(ref $x, "Math::BigInt", "Creating a 1 downgrades to Math::BigInt");

# binf()

$x = Math::BigFloat -> binf();
cmp_ok($x, "==", "Inf", "binf()");
is(ref $x, "Math::BigInt", "Creating an Inf downgrades to Math::BigInt");

# bnan()

$x = Math::BigFloat -> bnan();
is($x, "NaN", "bnan()");
is(ref $x, "Math::BigInt", "Creating a NaN downgrades to Math::BigInt");

# from_dec()

$x = Math::BigFloat -> from_dec("3.14e2");
cmp_ok($x, "==", 314, 'from_dec("3.14e2")');
is(ref $x, "Math::BigInt", 'from_dec("3.14e2") downgrades to Math::BigInt');

# from_hex()

$x = Math::BigFloat -> from_hex("0x1.3ap+8");
cmp_ok($x, "==", 314, 'from_hex("3.14e2")');
is(ref $x, "Math::BigInt", 'from_hex("3.14e2") downgrades to Math::BigInt');

# from_oct()

$x = Math::BigFloat -> from_oct("0o1.164p+8");
cmp_ok($x, "==", 314, 'from_oct("0o1.164p+8")');
is(ref $x, "Math::BigInt", 'from_oct("0o1.164p+8") downgrades to Math::BigInt');

# from_bin()

$x = Math::BigFloat -> from_bin("0b1.0011101p+8");
cmp_ok($x, "==", 314, 'from_bin("0b1.0011101p+8")');
is(ref $x, "Math::BigInt",
   'from_bin("0b1.0011101p+8") downgrades to Math::BigInt');

# from_ieee754()

$x = Math::BigFloat -> from_ieee754("\x43\x9d\x00\x00", "binary32");
cmp_ok($x, "==", 314, 'from_ieee754("\x43\x9d\x00\x00", "binary32")');
is(ref $x, "Math::BigInt",
   'from_ieee754("\x43\x9d\x00\x00", "binary32") downgrades to Math::BigInt');

note("Disable downgrading, and see if constructors downgrade");

Math::BigFloat -> downgrade(undef);

my $half = Math::BigFloat -> new("0.5");
my $four = Math::BigFloat -> new("4");
my $zero = Math::BigFloat -> bzero();
my $inf  = Math::BigFloat -> binf();
my $nan  = Math::BigFloat -> bnan();

is(ref $half, "Math::BigFloat", "Creating a 0.5 does not downgrade");
is(ref $four, "Math::BigFloat", "Creating a 4 does not downgrade");
is(ref $zero, "Math::BigFloat", "Creating a 0 does not downgrade");
is(ref $inf,  "Math::BigFloat", "Creating an Inf does not downgrade");
is(ref $nan,  "Math::BigFloat", "Creating a NaN does not downgrade");

################################################################################
# Verify that other methods downgrade when they should.

Math::BigFloat -> downgrade("Math::BigInt");

# This shouldn't be necessary, but it is. Fixme!

Math::BigInt -> upgrade(undef);

# bneg()

$x = $zero -> copy() -> bneg();
cmp_ok($x, "==", 0, "-(0) = 0");
is(ref($x), "Math::BigInt", "-(0) => Math::BigInt");

$x = $four -> copy() -> bneg();
cmp_ok($x, "==", -4, "-(4) = -4");
is(ref($x), "Math::BigInt", "-(4) => Math::BigInt");

$x = $inf -> copy() -> bneg();
cmp_ok($x, "==", "-inf", "-(Inf) = -Inf");
is(ref($x), "Math::BigInt", "-(Inf) => Math::BigInt");

$x = $nan -> copy() -> bneg();
is($x, "NaN", "-(NaN) = NaN");
is(ref($x), "Math::BigInt", "-(NaN) => Math::BigInt");

# bnorm()

$x = $zero -> copy() -> bnorm();
cmp_ok($x, "==", 0, "bnorm(0)");
is(ref($x), "Math::BigInt", "bnorm(0) => Math::BigInt");

$x = $four -> copy() -> bnorm();
cmp_ok($x, "==", 4, "bnorm(4)");
is(ref($x), "Math::BigInt", "bnorm(4) => Math::BigInt");

$x = $inf -> copy() -> bnorm();
cmp_ok($x, "==", "inf", "bnorm(Inf)");
is(ref($x), "Math::BigInt", "bnorm(Inf) => Math::BigInt");

$x = $nan -> copy() -> bnorm();
is($x, "NaN", "bnorm(NaN)");
is(ref($x), "Math::BigInt", "bnorm(NaN) => Math::BigInt");

# binc()

$x = $zero -> copy() -> binc();
cmp_ok($x, "==", 1, "binc(0)");
is(ref($x), "Math::BigInt", "binc(0) => Math::BigInt");

$x = $four -> copy() -> binc();
cmp_ok($x, "==", 5, "binc(4)");
is(ref($x), "Math::BigInt", "binc(4) => Math::BigInt");

$x = $inf -> copy() -> binc();
cmp_ok($x, "==", "inf", "binc(Inf)");
is(ref($x), "Math::BigInt", "binc(Inf) => Math::BigInt");

$x = $nan -> copy() -> binc();
is($x, "NaN", "binc(NaN)");
is(ref($x), "Math::BigInt", "binc(NaN) => Math::BigInt");

# bdec()

$x = $zero -> copy() -> bdec();
cmp_ok($x, "==", -1, "bdec(0)");
is(ref($x), "Math::BigInt", "bdec(0) => Math::BigInt");

$x = $four -> copy() -> bdec();
cmp_ok($x, "==", 3, "bdec(4)");
is(ref($x), "Math::BigInt", "bdec(4) => Math::BigInt");

$x = $inf -> copy() -> bdec();
cmp_ok($x, "==", "inf", "bdec(Inf)");
is(ref($x), "Math::BigInt", "bdec(Inf) => Math::BigInt");

$x = $nan -> copy() -> bdec();
is($x, "NaN", "bdec(NaN)");
is(ref($x), "Math::BigInt", "bdec(NaN) => Math::BigInt");

# badd()

$x = $half -> copy() -> badd($nan);
is($x, "NaN", "0.5 + NaN = NaN");
is(ref($x), "Math::BigInt", "0.5 + NaN => Math::BigInt");

$x = $half -> copy() -> badd($inf);
cmp_ok($x, "==", "+Inf", "0.5 + Inf = Inf");
is(ref($x), "Math::BigInt", "2.5 + Inf => Math::BigInt");

$x = $half -> copy() -> badd($half);
cmp_ok($x, "==", 1, "0.5 + 0.5 = 1");
is(ref($x), "Math::BigInt", "0.5 + 0.5 => Math::BigInt");

$x = $half -> copy() -> badd($half -> copy() -> bneg());
cmp_ok($x, "==", 0, "0.5 + -0.5 = 0");
is(ref($x), "Math::BigInt", "0.5 + -0.5 => Math::BigInt");

$x = $four -> copy() -> badd($zero);
cmp_ok($x, "==", 4, "4 + 0 = 4");
is(ref($x), "Math::BigInt", "4 + 0 => Math::BigInt");

$x = $zero -> copy() -> badd($four);
cmp_ok($x, "==", 4, "0 + 4 = 4");
is(ref($x), "Math::BigInt", "0 + 4 => Math::BigInt");

$x = $inf -> copy() -> badd($four);
cmp_ok($x, "==", "+Inf", "Inf + 4 = Inf");
is(ref($x), "Math::BigInt", "Inf + 4 => Math::BigInt");

$x = $nan -> copy() -> badd($four);
is($x, "NaN", "NaN + 4 = NaN");
is(ref($x), "Math::BigInt", "NaN + 4 => Math::BigInt");

# bsub()

$x = $half -> copy() -> bsub($nan);
is($x, "NaN", "0.5 - NaN = NaN");
is(ref($x), "Math::BigInt", "0.5 - NaN => Math::BigInt");

$x = $half -> copy() -> bsub($inf);
cmp_ok($x, "==", "-Inf", "2.5 - Inf = -Inf");
is(ref($x), "Math::BigInt", "2.5 - Inf => Math::BigInt");

$x = $half -> copy() -> bsub($half);
cmp_ok($x, "==", 0, "0.5 + 0.5 = 0");
is(ref($x), "Math::BigInt", "0.5 - 0.5 => Math::BigInt");

$x = $half -> copy() -> bsub($half -> copy() -> bneg());
cmp_ok($x, "==", 1, "0.5 - -0.5 = 1");
is(ref($x), "Math::BigInt", "0.5 - -0.5 => Math::BigInt");

$x = $four -> copy() -> bsub($zero);
cmp_ok($x, "==", 4, "4 - 0 = 4");
is(ref($x), "Math::BigInt", "4 - 0 => Math::BigInt");

$x = $zero -> copy() -> bsub($four);
cmp_ok($x, "==", -4, "0 - 4 = -4");
is(ref($x), "Math::BigInt", "0 - 4 => Math::BigInt");

$x = $inf -> copy() -> bsub($four);
cmp_ok($x, "==", "Inf", "Inf - 4 = Inf");
is(ref($x), "Math::BigInt", "Inf - 4 => Math::BigInt");

$x = $nan -> copy() -> bsub($four);
is($x, "NaN", "NaN - 4 = NaN");
is(ref($x), "Math::BigInt", "NaN - 4 => Math::BigInt");

# bmul()

$x = $zero -> copy() -> bmul($four);
cmp_ok($x, "==", 0, "bmul(0, 4) = 0");
is(ref($x), "Math::BigInt", "bmul(0, 4) => Math::BigInt");

$x = $four -> copy() -> bmul($four);
cmp_ok($x, "==", 16, "bmul(4, 4) = 16");
is(ref($x), "Math::BigInt", "bmul(4, 4) => Math::BigInt");

$x = $inf -> copy() -> bmul($four);
cmp_ok($x, "==", "inf", "bmul(Inf, 4) = Inf");
is(ref($x), "Math::BigInt", "bmul(Inf, 4) => Math::BigInt");

$x = $nan -> copy() -> bmul($four);
is($x, "NaN", "bmul(NaN, 4) = NaN");
is(ref($x), "Math::BigInt", "bmul(NaN, 4) => Math::BigInt");

$x = $four -> copy() -> bmul("0.5");
cmp_ok($x, "==", 2, "bmul(4, 0.5) = 2");
is(ref($x), "Math::BigInt", "bmul(4, 0.5) => Math::BigInt");

# bmuladd()

$x = $zero -> copy() -> bmuladd($four, $four);
cmp_ok($x, "==", 4, "bmuladd(0, 4, 4) = 4");
is(ref($x), "Math::BigInt", "bmuladd(0, 4, 4) => Math::BigInt");

$x = $four -> copy() -> bmuladd($four, $four);
cmp_ok($x, "==", 20, "bmuladd(4, 4, 4) = 20");
is(ref($x), "Math::BigInt", "bmuladd(4, 4, 4) => Math::BigInt");

$x = $four -> copy() -> bmuladd($four, $inf);
cmp_ok($x, "==", "inf", "bmuladd(4, 4, Inf) = Inf");
is(ref($x), "Math::BigInt", "bmuladd(4, 4, Inf) => Math::BigInt");

$x = $inf -> copy() -> bmuladd($four, $four);
cmp_ok($x, "==", "inf", "bmuladd(Inf, 4, 4) = Inf");
is(ref($x), "Math::BigInt", "bmuladd(Inf, 4, 4) => Math::BigInt");

$x = $inf -> copy() -> bmuladd($four, $four);
cmp_ok($x, "==", "inf", "bmuladd(Inf, 4, 4) = Inf");
is(ref($x), "Math::BigInt", "bmuladd(Inf, 4, 4) => Math::BigInt");

$x = $nan -> copy() -> bmuladd($four, $four);
is($x, "NaN", "bmuladd(NaN, 4, 4) = NaN");
is(ref($x), "Math::BigInt", "bmuladd(NaN, 4, 4) => Math::BigInt");

$x = $four -> copy() -> bmuladd("0.5", $four);
cmp_ok($x, "==", 6, "bmuladd(4, 0.5, 4) = 6");
is(ref($x), "Math::BigInt", "bmuladd(4, 0.5, 4) => Math::BigInt");

# bdiv()

# bmod()

# bmodpow()

# bpow()

# blog()

# bexp()

# bnok()

# bsin()

# bcos()

# batan()

# batan()

# bsqrt()

# broot()

# bfac()

# bdfac()

# btfac()

# bmfac()

# blsft()

# brsft()

# band()

# bior()

# bxor()

# bnot()

# bround()

# Add tests for rounding a non-integer to an integer. Fixme!

$x = $zero -> copy() -> bround();
cmp_ok($x, "==", 0, "bround(0)");
is(ref($x), "Math::BigInt", "bround(0) => Math::BigInt");

$x = $four -> copy() -> bround();
cmp_ok($x, "==", 4, "bround(4)");
is(ref($x), "Math::BigInt", "bround(4) => Math::BigInt");

$x = $inf -> copy() -> bround();
cmp_ok($x, "==", "inf", "bround(Inf)");
is(ref($x), "Math::BigInt", "bround(Inf) => Math::BigInt");

$x = $nan -> copy() -> bround();
is($x, "NaN", "bround(NaN)");
is(ref($x), "Math::BigInt", "bround(NaN) => Math::BigInt");

# bfround()

# Add tests for rounding a non-integer to an integer. Fixme!

$x = $zero -> copy() -> bfround();
cmp_ok($x, "==", 0, "bfround(0)");
is(ref($x), "Math::BigInt", "bfround(0) => Math::BigInt");

$x = $four -> copy() -> bfround();
cmp_ok($x, "==", 4, "bfround(4)");
is(ref($x), "Math::BigInt", "bfround(4) => Math::BigInt");

$x = $inf -> copy() -> bfround();
cmp_ok($x, "==", "inf", "bfround(Inf)");
is(ref($x), "Math::BigInt", "bfround(Inf) => Math::BigInt");

$x = $nan -> copy() -> bfround();
is($x, "NaN", "bfround(NaN)");
is(ref($x), "Math::BigInt", "bfround(NaN) => Math::BigInt");

# bfloor()

$x = $half -> copy() -> bfloor();
cmp_ok($x, "==", 0, "bfloor(0)");
is(ref($x), "Math::BigInt", "bfloor(0) => Math::BigInt");

$x = $inf -> copy() -> bfloor();
cmp_ok($x, "==", "Inf", "bfloor(Inf)");
is(ref($x), "Math::BigInt", "bfloor(Inf) => Math::BigInt");

$x = $nan -> copy() -> bfloor();
is($x, "NaN", "bfloor(NaN)");
is(ref($x), "Math::BigInt", "bfloor(NaN) => Math::BigInt");

# bceil()

$x = $half -> copy() -> bceil();
cmp_ok($x, "==", 1, "bceil(0)");
is(ref($x), "Math::BigInt", "bceil(0) => Math::BigInt");

$x = $inf -> copy() -> bceil();
cmp_ok($x, "==", "Inf", "bceil(Inf)");
is(ref($x), "Math::BigInt", "bceil(Inf) => Math::BigInt");

$x = $nan -> copy() -> bceil();
is($x, "NaN", "bceil(NaN)");
is(ref($x), "Math::BigInt", "bceil(NaN) => Math::BigInt");

# bint()

$x = $half -> copy() -> bint();
cmp_ok($x, "==", 0, "bint(0)");
is(ref($x), "Math::BigInt", "bint(0) => Math::BigInt");

$x = $inf -> copy() -> bint();
cmp_ok($x, "==", "Inf", "bint(Inf)");
is(ref($x), "Math::BigInt", "bint(Inf) => Math::BigInt");

$x = $nan -> copy() -> bint();
is($x, "NaN", "bint(NaN)");
is(ref($x), "Math::BigInt", "bint(NaN) => Math::BigInt");

# bgcd()

# blcm()

# mantissa() ?

# exponent() ?

# parts() ?

# sparts()

# nparts()

# eparts()

# dparts()

# fparts()

# numerator()

# denominator()

#require 'upgrade.inc'; # all tests here for sharing
