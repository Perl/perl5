Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Application.t - Demonstrate %Application
#

use Mac::MoreFiles;

print "MacPerl apparently is in $Application{McPL}\n";

die "Oops! You have Microsoft Word on your machine" if $Application{"MSWD"};

