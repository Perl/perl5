Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Types.t - Demostrate MacPack and MacUnpack.
#

use Mac::Types;

$p = MacPack("STR ", "Hello");

print $p, " ", length($p), "\n";

$u = MacUnpack("STR ", "$p dskjkjkdsjk");

print $u, " ", length($u), "\n";
