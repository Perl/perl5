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
use Test::More tests => 6;
use TieOut;

ok( !Test::Builder::_is_fh("foo"), 'string is not a filehandle' );

ok( open(FILE, '>foo') );
END { unlink 'foo' }

ok( Test::Builder::_is_fh(*FILE) );
ok( Test::Builder::_is_fh(\*FILE) );
ok( Test::Builder::_is_fh(*FILE{IO}) );

tie *OUT, 'TieOut';
ok( Test::Builder::_is_fh(*OUT) );