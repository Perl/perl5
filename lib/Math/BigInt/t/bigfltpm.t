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

#  unshift @INC, '../lib'; # for running manually
#  my $location = $0; $location =~ s/bigfltpm.t//;
#  unshift @INC, $location; # to locate the testing files
#  # chdir 't' if -d 't';

  plan tests => 1367;
  }

use Math::BigInt;
use Math::BigFloat;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup);
$class = "Math::BigFloat";
   
require 'bigfltpm.inc';	# all tests here for sharing
