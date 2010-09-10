#!/usr/bin/perl -w

# Test use Math::BigFloat with => 'Math::BigInt::SomeSubclass';

use Test;
use strict;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 2316
	+ 1;
  }

use Math::BigFloat with => 'Math::BigInt::Subclass', lib => 'Calc';

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup $CL);
$class = "Math::BigFloat";
$CL = "Math::BigInt::Calc";

# the with argument is ignored
ok (Math::BigFloat->config()->{with}, 'Math::BigInt::Calc');

require 't/bigfltpm.inc';	# all tests here for sharing
