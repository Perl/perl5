#!/usr/bin/perl -w

# see if using Math::BigInt and Math::BigFloat works together nicely.
# all use_lib*.t should be equivalent

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  unshift @INC, 'lib';
  print "# INC = @INC\n";
  plan tests => 2;
  } 

use Math::BigFloat lib => 'BareCalc';

ok (Math::BigInt->config()->{lib},'Math::BigInt::BareCalc');

ok (Math::BigFloat->new(123)->badd(123),246);

