#!/usr/bin/perl -w

# see if using Math::BigInt and Math::BigFloat works together nicely.
# all use_lib*.t should be equivalent

use strict;
use Test;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 2;
  } 

use Math::BigInt lib => 'BareCalc';
use Math::BigFloat;

ok (Math::BigInt->config()->{lib},'Math::BigInt::BareCalc');

ok (Math::BigFloat->new(123)->badd(123),246);

