#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use strict;
use Test::More 'no_plan';

use File::Spec;
use MakeMaker::Test::Setup::PL_FILES;
use MakeMaker::Test::Utils;

my $perl = which_perl();
my $make = make_run();
perl_lib();

setup;

END { 
    ok( chdir File::Spec->updir );
    ok( teardown );
}

ok chdir('PL_FILES-Module');

run(qq{$perl Makefile.PL});
cmp_ok( $?, '==', 0 );

my $make_out = run("$make");
is( $?, 0 ) || diag $make_out;

foreach my $file (qw(single.out 1.out 2.out)) {
    ok( -e $file, "$file was created" );
}
