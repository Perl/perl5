#!/usr/bin/perl -w

# use Module(); doesn't call impor() - thanx for cpan test David. M. Town and
# Andreas Marcel Riechert for spotting it. It is fixed by the same code that
# fixes require Math::BigInt, but we make a test to be sure it really works.

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 1;
  } 

my ($try,$ans,$x);

use Math::BigInt(); $x = Math::BigInt->new(1); ++$x;

ok ($x||'undef',2);

# all tests done

1;

