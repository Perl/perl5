#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 2316;
  }

use Math::BigFloat lib => 'BareCalc';

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup $CL);
$class = "Math::BigFloat";
$CL = "Math::BigInt::BareCalc";

require 't/bigfltpm.inc';	# all tests here for sharing
