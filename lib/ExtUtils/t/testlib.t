#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}
chdir 't';

use Test::More tests => 3;

BEGIN { 
    # non-core tests will have blib in their path.  We remove it
    # and just use the one in lib/.
    unless( $ENV{PERL_CORE} ) {
        @INC = grep !/blib/, @INC;
        unshift @INC, '../lib';
    }
}

my @blib_paths = grep /blib/, @INC;
is( @blib_paths, 0, 'No blib dirs yet in @INC' );

use_ok( 'ExtUtils::testlib' );

@blib_paths = grep { /blib/ } @INC;
is( @blib_paths, 2, 'ExtUtils::testlib added two @INC dirs!' );
