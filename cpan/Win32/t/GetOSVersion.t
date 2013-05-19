use strict;
use Test;
BEGIN {
    if ( $^O ne 'MSWin32' ) {
        print "1..0 # Skip: Not running on Windows\n";
        exit 0;
    }
}
use Win32;

plan tests => 1;

my $scalar = Win32::GetOSVersion();
my @array  = Win32::GetOSVersion();

print "not " unless $scalar == $array[4];
print "ok 1\n";
