Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Iterate.t - Demonstrate FSpIterateDirectory
#

use Mac::MoreFiles;

FSpIterateDirectory(":", 2, sub { print @_, "\n"; return 0; }, "");

