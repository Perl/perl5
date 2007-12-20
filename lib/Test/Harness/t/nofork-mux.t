#!/usr/bin/perl -w

BEGIN {
    if ( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ( '../lib', 'lib' );
    }
    else {
        use lib 't/lib';
    }
}

use strict;

use NoFork;
require(
    ( $ENV{PERL_CORE} ? '../lib/Test/Harness/' : '' ) . 't/multiplexer.t' );
