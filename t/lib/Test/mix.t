# -*-perl-*-
use strict;
use Test;
BEGIN { plan tests => 4, todo => [2,3] }

ok(sub { 
       my $r = 0;
       for (my $x=0; $x < 10; $x++) {
	   $r += $x*($r+1);
       }
       $r
   }, 3628799);

ok(0);
ok(1);

skip(1,0);
