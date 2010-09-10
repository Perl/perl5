#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 3279;
  }

use Math::BigInt lib => 'BareCalc';

print "# ",Math::BigInt->config()->{lib},"\n";

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup $CL);
$class = "Math::BigInt";
$CL = "Math::BigInt::BareCalc";

my $version = '1.84';	# for $VERSION tests, match current release (by hand!)

require 't/bigintpm.inc';	# perform same tests as bigintpm
