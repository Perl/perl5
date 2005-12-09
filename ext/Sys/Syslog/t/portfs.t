#!/usr/bin/perl -T
use strict;
use Test::More;
eval "use Test::Portability::Files";
plan skip_all => "Test::Portability::Files required for testing filenames portability" if $@;

# run the selected tests
run_tests();
