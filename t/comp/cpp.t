#!./perl

# $RCSfile: cpp.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:18 $

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Config;
if ( ($Config{'cppstdin'} =~ /\bcppstdin\b/) &&
     ! -x $Config{'binexp'} . "/cppstdin" ) {
    print "1..0 # Skip: \$Config{cppstdin} unavailable\n";
    exit; 		# Cannot test till after install, alas.
}

system qq{$^X -"P" "comp/cpp.aux"};
