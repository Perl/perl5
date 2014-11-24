#!/usr/bin/perl -w

use strict;
use warnings;

use Test::CanThread;

use Test::More;

subtest 'simple test with threads on' => sub {
    is( 1+1, 2,   "simple test" );
    is( "a", "a", "another simple test" );
};

pass("Parent retains sharedness");

done_testing(2);
