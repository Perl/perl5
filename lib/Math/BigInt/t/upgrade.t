#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # for running manually
  my $location = $0; $location =~ s/bigintpm.t//;
  unshift @INC, $location; # to locate the testing files
  chdir 't' if -d 't';
  plan tests => 2056
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

require 'upgrade.inc';	# all tests here for sharing
