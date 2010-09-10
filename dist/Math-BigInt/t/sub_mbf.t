#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  unshift @INC, 't';
  plan tests => 2316
    + 6;	# + our own tests
  }

use Math::BigFloat::Subclass;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup $CL);
$class = "Math::BigFloat::Subclass";
$CL = Math::BigFloat->config()->{lib}; # "Math::BigInt::Calc"; or FastCalc

require 't/bigfltpm.inc';	# perform same tests as bigfltpm

###############################################################################
# Now do custom tests for Subclass itself
my $ms = $class->new(23);
print "# Missing custom attribute \$ms->{_custom}" if !ok (1, $ms->{_custom});

# Check that subclass is a Math::BigFloat, but not a Math::Bigint
ok ($ms->isa('Math::BigFloat'),1);
ok ($ms->isa('Math::BigInt') || 0,0);

use Math::BigFloat;

my $bf = Math::BigFloat->new(23);		# same as other
$ms += $bf;
print "# Tried: \$ms += \$bf, got $ms" if !ok (46, $ms);
print "# Missing custom attribute \$ms->{_custom}" if !ok (1, $ms->{_custom});
print "# Wrong class: ref(\$ms) was ".ref($ms) if !ok ($class, ref($ms));
