#!/usr/bin/perl -T
use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage" if $@;
all_pod_coverage_ok({also_private => [qw(^constant$ ^connect ^disconnect$ ^xlate$ ^LOG_)]});
