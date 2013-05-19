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

ok(Win32::ExpandEnvironmentStrings("%WINDIR%"), $ENV{WINDIR});
