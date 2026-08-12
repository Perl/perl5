use strict;
use Test::More tests => 1;
use Win32;

my $scalar = Win32::GetOSVersion();
my @array  = Win32::GetOSVersion();

is $scalar, $array[4];
