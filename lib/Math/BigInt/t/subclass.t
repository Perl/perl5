#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib';	# for running manually
  my $location = $0; $location =~ s/subclass.t//;
  unshift @INC, $location; # to locate the testing files
  #chdir 't' if -d 't';
  plan tests => 1277;
  }

use Math::BigInt;
use Math::Subclass;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup);
$class = "Math::Subclass";

require 'bigfltpm.inc';	# perform same tests as bigfltpm

# Now do custom tests for Subclass itself
my $ms = new Math::Subclass 23;
print "# Missing custom attribute \$ms->{_custom}" if !ok (1, $ms->{_custom});

use Math::BigFloat;

my $bf = new Math::BigFloat 23;	# same as other
$ms += $bf;
print "# Tried: \$ms += \$bf, got $ms" if !ok (46, $ms);
print "# Missing custom attribute \$ms->{_custom}" if !ok (1, $ms->{_custom});
print "# Wrong class: ref(\$ms) was ".ref($ms) if !ok ($class, ref($ms));
