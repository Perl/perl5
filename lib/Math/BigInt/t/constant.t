#!/usr/bin/perl -w

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 5;
  } 

use Math::BigInt ':constant';

ok (2 ** 255,'57896044618658097711785492504343953926634992332820282019728792003956564819968');

use Math::BigFloat ':constant';
ok (1.0 / 3.0, '0.3333333333333333333333333333333333333333');

# stress-test Math::BigFloat->import()

Math::BigFloat->import( qw/:constant/ );
ok (1,1);

Math::BigFloat->import( qw/:constant upgrade Math::BigRat/ );
ok (1,1);

Math::BigFloat->import( qw/upgrade Math::BigRat :constant/ );
ok (1,1);

# all tests done

