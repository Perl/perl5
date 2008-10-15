#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/Builder/ok_obj.t 60332 2008-09-09T12:24:03.060291Z schwern  $

# Testing to make sure Test::Builder doesn't accidentally store objects
# passed in as test arguments.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More tests => 4;

package Foo;
my $destroyed = 0;
sub new { bless {}, shift }

sub DESTROY {
    $destroyed++;
}

package main;

for (1..3) {
    ok(my $foo = Foo->new, 'created Foo object');
}
is $destroyed, 3, "DESTROY called 3 times";

