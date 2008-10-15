# $Id: /mirror/googlecode/test-more/t/import.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}


use Test::More tests => 2, import => [qw(!fail)];

can_ok(__PACKAGE__, qw(ok pass like isa_ok));
ok( !__PACKAGE__->can('fail'),  'fail() not exported' );
