# $Id: /mirror/googlecode/test-more/t/simple.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;

BEGIN { $| = 1; $^W = 1; }

use Test::Simple tests => 3;

ok(1, 'compile');

ok(1);
ok(1, 'foo');
