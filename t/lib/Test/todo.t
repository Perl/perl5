# -*-perl-*-
use strict;
use Test;
BEGIN { 
    my $tests = 5; 
    plan tests => $tests, todo => [1..$tests]; 
}

ok(0);
ok(1);
ok(0,1);
ok(0,1,"need more tuits");
ok(1,1);
