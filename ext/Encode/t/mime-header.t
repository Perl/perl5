BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    $| = 1;
}

use strict;
use Test::More qw(no_plan);
#use Test::More tests => 19;
use_ok("Encode::MIME::Header");


__END__;
