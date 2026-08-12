use strict;
use Test::More tests => 1;
use Win32;

is(Win32::ExpandEnvironmentStrings("%WINDIR%"), $ENV{WINDIR});
