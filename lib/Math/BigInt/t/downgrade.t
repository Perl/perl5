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
  plan tests => 10;
  }

use Math::BigInt;
use Math::BigFloat downgrade => 'Math::BigInt', upgrade => 'Math::BigInt';

use vars qw ($scale $class $try $x $y $f @args $ans $ans1 $ans1_str $setup
             $ECL $CL);
$class = "Math::BigInt";
$CL = "Math::BigInt::Calc";
$ECL = "Math::BigFloat";

# simplistic test for now 
ok (Math::BigFloat->downgrade(),'Math::BigInt');
ok (Math::BigFloat->upgrade(),'Math::BigInt');

# these downgrade
ok (ref(Math::BigFloat->new('inf')),'Math::BigInt');
ok (ref(Math::BigFloat->new('-inf')),'Math::BigInt');
ok (ref(Math::BigFloat->new('NaN')),'Math::BigInt');
ok (ref(Math::BigFloat->new('0')),'Math::BigInt');
ok (ref(Math::BigFloat->new('1')),'Math::BigInt');
ok (ref(Math::BigFloat->new('10')),'Math::BigInt');
ok (ref(Math::BigFloat->new('-10')),'Math::BigInt');
ok (ref(Math::BigFloat->new('-10.0E1')),'Math::BigInt');

#require 'upgrade.inc';	# all tests here for sharing
