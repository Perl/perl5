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
use Test::More tests => 15;
use MakeMaker::Test::Utils;
use File::Spec;
use TieOut;

my $perl = which_perl;

$ENV{PERL_CORE} ? chdir '../lib/ExtUtils/t' : chdir 't';

perl_lib;

$| = 1;

ok( chdir 'Big-Fat-Dummy', "chdir'd to Big-Fat-Dummy" ) ||
  diag("chdir failed: $!");


# The perl core test suite will run any .t file in the MANIFEST.
# So we have to generate this on the fly.
mkdir 't';
open(TEST, ">t/compile.t") or die "Can't open t/compile.t: $!";
print TEST <DATA>;
close TEST;

END { unlink 't/compile.t' }

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

# -M is flakey on VMS, flat out broken on Tru64 5.6.0
SKIP: {
    skip "stat a/mtime broken on Tru64 5.6.0", 1 if $^O eq 'dec_osf' and
                                                    $] >= 5.006;

    my $mtime = (stat($makefile))[9];
    cmp_ok( $^T, '<=', $mtime,  '  its been touched' );
}

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

my $realclean_out = `$make realclean`;
is( $?, 0, 'realclean' ) || diag($realclean_out);

__DATA__
print "1..2\n";

print eval "use Big::Fat::Dummy; 1;" ? "ok 1\n" : "not ok 1\n";
print "ok 2 - TEST_VERBOSE\n";
