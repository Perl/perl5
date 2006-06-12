#!/usr/bin/perl -w

BEGIN {
    if ( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More tests => 6;

BEGIN {
    use_ok( 'Test::Harness' );
}

my $died;
sub prepare_for_death { $died = 0; }
sub signal_death { $died = 1; }

PASSING: {
    local $SIG{__DIE__} = \&signal_death;
    prepare_for_death();
    eval { runtests( "t/sample-tests/simple" ) };
    ok( !$@, "simple lives" );
    is( $died, 0, "Death never happened" );
}

FAILING: {
    local $SIG{__DIE__} = \&signal_death;
    prepare_for_death();
    eval { runtests( "t/sample-tests/too_many" ) };
    ok( $@, "$@" );
    ok( $@ =~ m[Failed 1/1], "too_many dies" );
    is( $died, 1, "Death happened" );
}
