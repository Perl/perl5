#!perl

use strict;
use warnings;
use Test::More tests => 5;

use XS::APItest;

{
   my $sv = newSVpviv("one-two-three", 456);
   ok($sv eq "one-two-three", '$sv stringily from newSVpviv');
   ok($sv == 456,             '$sv numerically from newSVpviv');
}

{
   my $sv = newSVpvniv("seven\0eight", 11, 90);
   ok($sv eq "seven\0eight", '$sv stringily from newSVpvniv');
   ok($sv == 90,             '$sv numerically from newSVpvniv');
}

ok(newSVpviv("string", -25) == -25, 'newSVpviv* can make negative numbers');
