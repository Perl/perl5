Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# ICDump.t - Dump all IC settings
#

use Mac::InternetConfig;

print "Cooked:\n\n";
print map { "$_: $InternetConfig{$_}\n" } keys %InternetConfig;
