#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

subtest my_subtest1 => sub {
    my $file = __FILE__;
    $file =~ s/\.t$/1.load/;
    do $file;
};

subtest my_subtest2 => sub {
    my $file = __FILE__;
    $file =~ s/\.t$/2.load/;
    do $file;
};

done_testing;
