#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

subtest my_subtest => sub {
    my $file = __FILE__;
    $file =~ s/\.t$/.load/;
    do $file;
    note "Got: $@";
    fail($@);
};

done_testing;
