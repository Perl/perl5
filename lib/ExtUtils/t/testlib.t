#!./perl 

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 3;

my @blib_paths = grep { /blib/ } @INC;
is( @blib_paths, 0, 'No blib dirs yet in @INC' );

use_ok( 'ExtUtils::testlib' );

@blib_paths = grep { /blib/ } @INC;
is( @blib_paths, 2, 'ExtUtils::testlib added two @INC dirs!' );
