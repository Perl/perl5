#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib/');
    }
    else {
        unshift @INC, 't/lib/';
    }
}
chdir 't';

use Test::More tests => 1;
use ExtUtils::MakeMaker;

# For backwards compat with some Tk modules, dir_target() has to be there.
can_ok('MM', 'dir_target');