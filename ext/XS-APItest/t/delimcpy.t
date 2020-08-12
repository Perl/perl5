#!perl -w
use strict;

use Test::More;
use XS::APItest;


my @ret;
@ret = test_delimcpy('\x\\\x\\x', 'x', 100);
use Data::Dumper;
print STDERR Dumper \@ret;

done_testing();
