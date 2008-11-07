#!perl -w
# $Id: /mirror/googlecode/test-more/t/Builder/try.t 60332 2008-09-09T12:24:03.060291Z schwern  $

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

use Test::More 'no_plan';

require Test::Builder;
my $tb = Test::Builder->new;


# Test that _try() has no effect on $@ and $! and is not effected by
# __DIE__
{
    local $SIG{__DIE__} = sub { fail("DIE handler called: @_") };
    local $@ = 42;
    local $! = 23;

    is $tb->_try(sub { 2 }), 2;
    is $tb->_try(sub { return '' }), '';

    is $tb->_try(sub { die; }), undef;

    is_deeply [$tb->_try(sub { die "Foo\n" })], [undef, "Foo\n"];

    is $@, 42;
    cmp_ok $!, '==', 23;
}

ok !eval {
    $tb->_try(sub { die "Died\n" }, die_on_fail => 1);
};
is $@, "Died\n";
