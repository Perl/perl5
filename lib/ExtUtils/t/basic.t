#!/usr/bin/perl -w

# This test puts MakeMaker through the paces of a basic perl module
# build, test and installation of the Big::Fat::Dummy module.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
$ENV{PERL_CORE} ? chdir '../lib/ExtUtils/t' : chdir 't';

use strict;
use Test::More tests => 15;
use MakeMaker::Test::Utils;
use File::Spec;
use TieOut;

my $perl = which_perl;
perl_lib;

$| = 1;

ok( chdir 'Big-Fat-Dummy', "chdir'd to Big-Fat-Dummy" ) ||
  diag("chdir failed: $!");

my @mpl_out = `$perl Makefile.PL PREFIX=dummy-install`;

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

my $makefile = makefile_name();
ok( grep(/^Writing $makefile for Big::Fat::Dummy/, 
         @mpl_out) == 1,
                                           'Makefile.PL output looks right');

ok( grep(/^Current package is: main$/,
         @mpl_out) == 1,
                                           'Makefile.PL run in package main');

ok( -e $makefile,       'Makefile exists' );

# -M is flakey on VMS.
my $mtime = (stat($makefile))[9];
ok( ($^T - $mtime) <= 0,  '  its been touched' );

END { unlink makefile_name(), makefile_backup() }

# Supress 'make manifest' noise
open(SAVERR, ">&STDERR") || die $!;
close(STDERR);
my $make = make_run();
my $manifest_out = `$make manifest`;
ok( -e 'MANIFEST',      'make manifest created a MANIFEST' );
ok( -s 'MANIFEST',      '  its not empty' );
open(STDERR, ">&SAVERR") || die $!;

END { unlink 'MANIFEST'; }

my $test_out = `$make test`;
like( $test_out, qr/All tests successful/, 'make test' );
is( $?, 0 );

# Test 'make test TEST_VERBOSE=1'
my $make_test_verbose = make_macro($make, 'test', TEST_VERBOSE => 1);
$test_out = `$make_test_verbose`;
like( $test_out, qr/ok \d+ - TEST_VERBOSE/, 'TEST_VERBOSE' );
like( $test_out, qr/All tests successful/, '  successful' );
is( $?, 0 );

my $dist_test_out = `$make disttest`;
is( $?, 0, 'disttest' ) || diag($dist_test_out);

my $realclean_out = `$make realclean`;
is( $?, 0, 'realclean' ) || diag($realclean_out);

close SAVERR;
