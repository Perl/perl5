Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# ListComponents.t - Demonstrate how to list all components. To restrict the listing
#                    to one type, pass it on the command line as in 
#   ListComponents.t "osa "
#

use Mac::Components;

for ($comp = 0; $comp = FindNextComponent($comp, $ARGV[0]); ) {
	printf "%08X: %4s %4s %4s %08X %08X %-25s %s\n", $comp, GetComponentInfo($comp);
}
