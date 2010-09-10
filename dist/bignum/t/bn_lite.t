#!/usr/bin/perl -w

###############################################################################

use Test;
use strict;

BEGIN
  {
  plan tests => 1;
  }

eval 'require Math::BigInt::Lite;';
if ($@ eq '')
  {
  # can use Lite, so let bignum try it
  require bignum; bignum->import();
  # can't get to work a ref(1+1) here, presumable because :constant phase
  # already done
  ok ($bignum::_lite,1);
  }
else
  {
  print "ok 1 # skipped, no Math::BigInt::Lite\n";
  }
  

