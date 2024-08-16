#!/usr/bin/perl
use strict;
use warnings;
$| = 1;
use Test::More qw(no_plan); # tests =>  7;
use ExtUtils::ParseXS::Utilities qw(
    analyze_preprocessor_statements
);

#      ( $self, $BootCode_ref ) =
#        analyze_preprocessor_statements(
#          $self, $statement, $BootCode_ref
#        );

pass("Passed all tests in $0");


