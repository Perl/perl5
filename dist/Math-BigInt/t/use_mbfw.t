#!/usr/bin/perl -w

# check that using BigFloat with "with" and "lib" at the same time works
# broken in versions up to v1.63

use strict;
use Test;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 2;
  } 


# the replacement lib can handle the lib statement, but it could also ignore
# it completely, for instance, when it is a 100% replacement for BigInt, but
# doesn't know the concept of alternative libs. But it still needs to cope
# with "lib => ". SubClass does record it, so we test here essential if
# BigFloat hands the lib properly down, any more is outside out testing reach.

use Math::BigFloat with => 'Math::BigInt::Subclass', lib => 'BareCalc';

ok (Math::BigFloat->config()->{with}, 'Math::BigInt::BareCalc' );

# ok ($Math::BigInt::Subclass::lib, 'BareCalc' );

# it never arrives here, but that is a design decision in SubClass
ok (Math::BigInt->config->{lib}, 'Math::BigInt::BareCalc' );

# all tests done

