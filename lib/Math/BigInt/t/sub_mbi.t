#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib';	# for running manually
  my $location = $0; $location =~ s/sub_mbi.t//;
  unshift @INC, $location; # to locate the testing files
  chdir 't' if -d 't';
  plan tests => 1608 + 4;	# +4 own tests
  }

use Math::BigInt::Subclass;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup);
$class = "Math::BigInt::Subclass";

#my $version = '0.01';   # for $VERSION tests, match current release (by hand!)

require 'bigintpm.inc';	# perform same tests as bigfltpm

# Now do custom tests for Subclass itself
my $ms = $class->new(23);
print "# Missing custom attribute \$ms->{_custom}" if !ok (1, $ms->{_custom});

use Math::BigInt;

my $bi = Math::BigInt->new(23);		# same as other
$ms += $bi;
print "# Tried: \$ms += \$bi, got $ms" if !ok (46, $ms);
print "# Missing custom attribute \$ms->{_custom}" if !ok (1, $ms->{_custom});
print "# Wrong class: ref(\$ms) was ".ref($ms) if !ok ($class, ref($ms));
