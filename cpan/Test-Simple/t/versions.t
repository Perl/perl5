#!/usr/bin/perl -w

# Make sure all the modules have the same version
#
# TBT has its own version system.

use strict;
use Test::More;

require Test::Builder;
require Test::Builder::Module;
require Test::Simple;
require Test::Builder::Tester;
require Test::Tester2;
require Test::Tester;

my $dist_version = Test::More->VERSION;

like( $dist_version, qr/^ \d+ \. \d+ $/x );

my @modules = qw(
    Test::Simple
    Test::Builder
    Test::Builder::Module
    Test::Builder::Tester
    Test::Tester2
    Test::Tester
);

for my $module (@modules) {
    my $file = $module;
    $file =~ s{(::|')}{/}g;
    $file .= ".pm";
    is( $module->VERSION, $module->VERSION, sprintf("%-22s %s", $module, $INC{$file}) );
}

done_testing();
