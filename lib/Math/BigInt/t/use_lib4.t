#!/usr/bin/perl -w

# see if using Math::BigInt and Math::BigFloat works together nicely.
# all use_lib*.t should be equivalent, except this, since the later overrides
# the former lib statement

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  unshift @INC, 'lib';
  plan tests => 2;
  } 

use Math::BigInt lib => 'BareCalc';
use Math::BigFloat lib => 'Calc';

ok (Math::BigInt->config()->{lib},'Math::BigInt::Calc');

ok (Math::BigFloat->new(123)->badd(123),246);

