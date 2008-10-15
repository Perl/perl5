#!perl -w
# $Id: /mirror/googlecode/test-more/t/filehandles.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
}

use lib 't/lib';
use Test::More tests => 1;
use Dev::Null;

tie *STDOUT, "Dev::Null" or die $!;

print "not ok 1\n";     # this should not print.
pass 'STDOUT can be mucked with';

