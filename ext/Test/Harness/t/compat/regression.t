#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 1;
use Test::Harness;

{

    #28567
    unshift @INC, 'wibble';
    my @before = Test::Harness::_filtered_inc();
    unshift @INC, sub {die};
    my @after = Test::Harness::_filtered_inc();
    is_deeply \@after, \@before, 'subref removed from @INC';
}
