#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  # to locate the testing files
  my $location = $0; $location =~ s/bigfltpm.t//i;
  if ($ENV{PERL_CORE})
    {
    # testing with the core distribution
    @INC = qw(../lib);
    }
  unshift @INC, '../lib';
  if (-d 't')
    {
    chdir 't';
    require File::Spec;
    unshift @INC, File::Spec->catdir(File::Spec->updir, $location);
    }
  else
    {
    unshift @INC, $location;
    }
  print "# INC = @INC\n";

  plan tests => 2064
	+ 3;		# own tests
  }

use Math::BigInt lib => 'Calc';
use Math::BigFloat;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup $CL);
$class = "Math::BigFloat";
$CL = "Math::BigInt::Calc";

ok ($class->config()->{class},$class);
ok ($class->config()->{with}, $CL);

# bug #17447: Can't call method Math::BigFloat->bsub, not a valid method
my $c = new Math::BigFloat( '123.3' );
ok ($c->fsub(123) eq '0.3', 1); # calling fsub on a BigFloat works
 
require 'bigfltpm.inc';	# all tests here for sharing
