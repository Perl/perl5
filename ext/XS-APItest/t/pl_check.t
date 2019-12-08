#!perl
use strict;
use Config;

# this doesn't work with Test::More
BEGIN {
    require '../../t/test.pl';
}

use threads;


$Config{usethreads}
  or plan skip_all => "test requires threads";

# do not use XS::APItest in this test

use constant thread_count => 20;

plan tests => thread_count;

local $::TODO = "PL_check isn't thread-safe";
push @INC, "t";
my @threads;
for (1..thread_count) {
    push @threads, threads->create(sub {
        require Hoisted;
        return 1;
    });
}
ok $_->join for @threads;
