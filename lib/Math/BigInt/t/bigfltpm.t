#!/usr/bin/perl -w

BEGIN {
    $| = 1;
    my $location = $0;
    # to locate the testing files
    $location =~ s/bigfltpm.t//i;
    if ($ENV{PERL_CORE}) {
        # testing with the core distribution
	@INC = qw(../lib);
	if (-d 't') {
	    chdir 't';
	    require File::Spec;
	    unshift @INC, File::Spec->catdir(File::Spec->updir, $location);
	} else {
	    unshift @INC, $location;
	}
    } else {
        # for running manually with the CPAN distribution
	unshift @INC, '../lib';
	$location =~ s/bigfltpm.t//;
    }
    print "# INC = @INC\n";
}

use Test;
use strict;

BEGIN
  {
  plan tests => 1277;
  }

use Math::BigInt;
use Math::BigFloat;

use vars qw ($class $try $x $y $f @args $ans $ans1 $ans1_str $setup);
$class = "Math::BigFloat";
   
require 'bigfltpm.inc';	# all tests here for sharing
