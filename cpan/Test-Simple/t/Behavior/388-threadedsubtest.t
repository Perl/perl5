#!/usr/bin/perl
use strict;
use warnings;

use Test::CanThread qw/AUTHOR_TESTING/;
use Test::More;

subtest my_subtest => sub {
    my $file = __FILE__;
    $file =~ s/\.t$/.load/;
    do $file || die $@;
};

done_testing;
