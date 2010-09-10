#!/usr/bin/perl -w

# test BigFloat constants alone (w/o BigInt loading)

use strict;
use Test;

BEGIN
  {
  plan tests => 2;
  } 

use Math::BigFloat ':constant';

ok (1.0 / 3.0, '0.3333333333333333333333333333333333333333');

# BigInt was not loadede with ':constant', so only floats are handled
ok (ref(2 ** 2),'');

