#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  plan tests => 2112
   + 2;			# our own tests
  }

use Math::BigInt upgrade => 'Math::BigFloat';
use Math::BigFloat;

use vars qw ($scale $class $try $x $y $f @args $ans $ans1 $ans1_str $setup
             $ECL $CL);
$class = "Math::BigInt";
$CL = "Math::BigInt::Calc";
$ECL = "Math::BigFloat";

ok (Math::BigInt->upgrade(),'Math::BigFloat');
ok (Math::BigInt->downgrade()||'','');

require 't/upgrade.inc';	# all tests here for sharing
