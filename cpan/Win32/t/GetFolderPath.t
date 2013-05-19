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

# "windir" exists back to Win9X; "SystemRoot" only exists on WinNT and later.
ok(Win32::GetFolderPath(Win32::CSIDL_WINDOWS), $ENV{WINDIR});
