# $Id: /mirror/googlecode/test-more/t/Builder/no_header.t 60332 2008-09-09T12:24:03.060291Z schwern  $
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::Builder;

# STDOUT must be unbuffered else our prints might come out after
# Test::More's.
$| = 1;

BEGIN {
    Test::Builder->new->no_header(1);
}

use Test::More tests => 1;

print "1..1\n";
pass;
