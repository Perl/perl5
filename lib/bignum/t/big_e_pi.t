#!/usr/bin/perl -w

###############################################################################
# test for e() and PI() exports

use Test::More;
use strict;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib';
  plan tests => 4;
  }

use bignum qw/e PI/;

is (e, "2.718281828459045235360287471352662497757", 'e');
is (PI, "3.141592653589793238462643383279502884197", 'PI');

is (e(10), "2.718281828", 'e');
is (PI(10), "3.141592654", 'PI');
