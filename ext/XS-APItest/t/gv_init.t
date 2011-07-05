#!perl

use strict;
use warnings;
use Test::More tests => 10;

use XS::APItest;

is my $glob = XS::APItest::gv_init_type("sanity_check", 0, 0, 0), "*main::sanity_check";
ok $::{sanity_check};

for my $type (0..3) {
    is my $glob = XS::APItest::gv_init_type("test$type", 0, 0, $type), "*main::test$type";
    ok $::{"test$type"};
}
