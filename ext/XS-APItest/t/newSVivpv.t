#!perl

use strict;
use warnings;
use Test::More tests => 5;

use XS::APItest;

{
   my $sv = newSVivpv(123, "four-five-six");
   ok($sv == 123,             '$sv numerically from newSVivpv');
   ok($sv eq "four-five-six", '$sv stringily from newSVivpv');
}

{
   my $sv = newSVivpvn(78, "nine\0ten", 8);
   ok($sv == 78,          '$sv numerically from newSVivpvn');
   ok($sv eq "nine\0ten", '$sv stringily from newSVivpvn');
}

ok(newSVivpv(-25, "string") == -25, 'newSVivpv* can make negative numbers');
