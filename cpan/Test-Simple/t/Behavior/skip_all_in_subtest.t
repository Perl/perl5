#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

subtest my_subtest1 => sub {
    my $file = __FILE__;
    $file =~ s/\.t$/1.load/;
    do $file;
};

is(scalar(@warnings), 1, "one warning");
like(
    $warnings[0],
    qr/^SKIP_ALL in subtest via 'BEGIN' or 'use'/,
    "the warning"
);


subtest my_subtest2 => sub {
    my $file = __FILE__;
    $file =~ s/\.t$/2.load/;
    do $file;
};

done_testing;
