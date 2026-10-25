use strict;
use Test::More tests => 1;
use Win32;

# An XSUB that writes its return value into the stack slot below its
# arguments overwrites the 1 in front of the call.
my @r = (1, Win32::SetChildShowWindow(0));
is_deeply(\@r, [1, undef], "Win32::SetChildShowWindow(0) in a list");
