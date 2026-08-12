use strict;
use Test::More;
use Win32;

unless (defined &Win32::BuildNumber) {
    plan skip_all => 'Only ActivePerl seems to set the perl.exe fileversion';
}

plan tests => 2;

my @version = Win32::GetFileVersion($^X);
my $version = $version[0] + $version[1] / 1000 + $version[2] / 1000000;

# numify $] because it is a version object in 5.10 which will stringify with trailing 0s
is($version, 0+$]);

is($version[3], int(Win32::BuildNumber()));
