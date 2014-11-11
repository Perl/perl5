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
use Test::More tests => 4;

# Symbol and Class::Struct are both non-XS core modules back to 5.004.
# So they'll always be there.
require_ok("Symbol");
ok( $INC{'Symbol.pm'},          "require_ok MODULE" );

require_ok("Class/Struct.pm");
ok( $INC{'Class/Struct.pm'},    "require_ok FILE" );
