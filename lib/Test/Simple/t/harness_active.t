#!perl -w

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

use Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();


# Can't use Test.pm, that's a 5.005 thing.
package My::Test;

print "1..4\n";

my $test_num = 1;
# Utility testing functions.
sub ok ($;$) {
    my($test, $name) = @_;
    my $ok = '';
    $ok .= "not " unless $test;
    $ok .= "ok $test_num";
    $ok .= " - $name" if defined $name;
    $ok .= "\n";
    print $ok;
    $test_num++;

    return $test;
}


sub main::err_ok ($) {
    my($expect) = @_;
    my $got = $err->read;

    my $ok = ok( $got eq $expect );

    unless( $ok ) {
        print STDERR "got\n$got\n";
        print STDERR "expected\n$expect\n";
    }

    return $ok;
}


package main;

require Test::More;
Test::More->import(tests => 4);
Test::More->builder->no_ending(1);

{
    local $ENV{HARNESS_ACTIVE} = 0;

#line 62
    fail( "this fails" );
    err_ok( <<ERR );
#     Failed test ($0 at line 62)
ERR

#line 72
    is( 1, 0 );
    err_ok( <<ERR );
#     Failed test ($0 at line 72)
#          got: '1'
#     expected: '0'
ERR
}

{
    local $ENV{HARNESS_ACTIVE} = 1;
                   
#line 71
    fail( "this fails" );
    err_ok( <<ERR );

#     Failed test ($0 at line 71)
ERR


#line 84
    is( 1, 0 );
    err_ok( <<ERR );

#     Failed test ($0 at line 84)
#          got: '1'
#     expected: '0'
ERR

}
