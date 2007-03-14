#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;
use Test::More tests => 8;
use TieOut;

ok( !Test::Builder->is_fh("foo"), 'string is not a filehandle' );
ok( !Test::Builder->is_fh(''),    'empty string' );
ok( !Test::Builder->is_fh(undef), 'undef' );

ok( open(FILE, '>foo') );
END { close FILE; unlink 'foo' }

ok( Test::Builder->is_fh(*FILE) );
ok( Test::Builder->is_fh(\*FILE) );
ok( Test::Builder->is_fh(*FILE{IO}) );

tie *OUT, 'TieOut';
ok( Test::Builder->is_fh(*OUT) );
