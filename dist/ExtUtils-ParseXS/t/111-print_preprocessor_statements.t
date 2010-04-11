#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use Test::More qw(no_plan); # tests =>  7;
use lib qw( lib );
use ExtUtils::ParseXS::Utilities qw(
    print_preprocessor_statements
);

pass("Passed all tests in $0");
