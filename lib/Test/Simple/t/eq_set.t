#!perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use strict;
use Test::More;

plan tests => 2;

# RT 3747
ok( eq_set([1, 2, [3]], [[3], 1, 2]) );
ok( eq_set([1,2,[3]], [1,[3],2]) );
