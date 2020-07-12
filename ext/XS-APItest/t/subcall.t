#!perl

# Test handling of XSUBs in pp_entersub

use Test::More tests => 1;
use XS::APItest;

no warnings 'uninitialized';
my $ref = XS::APItest::newRV($_+1);
is \$$ref, $ref, 'XSUBs do not get to see PADTMPs';
