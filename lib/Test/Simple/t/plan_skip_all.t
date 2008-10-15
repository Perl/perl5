# $Id: /mirror/googlecode/test-more/t/plan_skip_all.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More;

plan skip_all => 'Just testing plan & skip_all';

fail('We should never get here');
