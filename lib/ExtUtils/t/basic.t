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

use strict;
use Test::More tests => 17;
use MakeMaker::Test::Utils;
use File::Spec;
use TieOut;

my $perl = which_perl();

chdir 't';

perl_lib;

my $Touch_Time = calibrate_mtime();

$| = 1;

ok( chdir 'Big-Dummy', "chdir'd to Big-Dummy" ) ||
  diag("chdir failed: $!");


# The perl core test suite will run any .t file in the MANIFEST.
# So we have to generate this on the fly.
mkdir 't' || die "Can't create test dir: $!";
open(TEST, ">t/compile.t") or die "Can't open t/compile.t: $!";
print TEST <<'COMPILE_T';
print "1..2\n";

print eval "use Big::Dummy; 1;" ? "ok 1\n" : "not ok 1\n";
print "ok 2 - TEST_VERBOSE\n";
COMPILE_T
close TEST;

mkdir 'Liar/t' || die "Can't create test dir: $!";
open(TEST, ">Liar/t/sanity.t") or die "Can't open Liar/t/sanity.t: $!";
print TEST <<'SANITY_T';
print "1..3\n";

print eval "use Big::Dummy; 1;" ? "ok 1\n" : "not ok 1\n";
print eval "use Big::Liar; 1;" ? "ok 2\n" : "not ok 2\n";
print "ok 3 - TEST_VERBOSE\n";
SANITY_T
close TEST;

END { unlink 't/compile.t', 'Liar/t/sanity.t' }

my @mpl_out = `$perl Makefile.PL PREFIX=dummy-install`;

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

my $makefile = makefile_name();
ok( grep(/^Writing $makefile for Big::Dummy/, 
         @mpl_out) == 1,
                                           'Makefile.PL output looks right');

ok( grep(/^Current package is: main$/,
         @mpl_out) == 1,
                                           'Makefile.PL run in package main');

ok( -e $makefile,       'Makefile exists' );

# -M is flakey on VMS
my $mtime = (stat($makefile))[9];
cmp_ok( $Touch_Time, '<=', $mtime,  '  its been touched' );

END { unlink makefile_name(), makefile_backup() }

my $make = make_run();

{
    # Supress 'make manifest' noise
    local $ENV{PERL_MM_MANIFEST_VERBOSE} = 0;
    my $manifest_out = `$make manifest`;
    ok( -e 'MANIFEST',      'make manifest created a MANIFEST' );
    ok( -s 'MANIFEST',      '  its not empty' );
}

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


# Make sure init_dirscan doesn't go into the distdir
@mpl_out = `$perl Makefile.PL "PREFIX=dummy-install"`;

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

ok( grep(/^Writing $makefile for Big::Dummy/, 
         @mpl_out) == 1,
                                'init_dirscan skipped distdir') || 
  diag(@mpl_out);

# I know we'll get ignored errors from make here, that's ok.
# Send STDERR off to oblivion.
open(SAVERR, ">&STDERR") or die $!;
open(STDERR, ">".File::Spec->devnull) or die $!;

my $realclean_out = `$make realclean`;
is( $?, 0, 'realclean' ) || diag($realclean_out);

open(STDERR, ">&SAVERR") or die $!;
close SAVERR;
