use strict;
use warnings;
use FindBin;

require "$FindBin::Bin/public_suffix_lib.pl";
run_with_lib( 'Net::LibIDN' );
