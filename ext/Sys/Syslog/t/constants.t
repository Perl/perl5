#!/usr/bin/perl -T
use strict;
use Test::More;
my @names;
BEGIN {
    if(open(MACROS, 'macros.all')) {
        @names = map {chomp;$_} <MACROS>;
        close(MACROS);
        plan tests => @names + 3;
    } else {
        plan skip_all => "can't read 'macros.all': $!"
    }
}
use Sys::Syslog;

eval "use Test::Exception"; my $has_test_exception = !$@;

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 1 unless $has_test_exception;

    # constant() errors
    throws_ok(sub {
        Sys::Syslog::constant()
    }, '/^Usage: Sys::Syslog::constant\(sv\)/',
       "calling constant() with no argument");
}

# Testing constant()
like( Sys::Syslog::constant('This'), 
    '/^This is not a valid Sys::Syslog macro/', 
    "calling constant() with a non existing name" );

like( Sys::Syslog::constant('NOSUCHNAME'), 
    '/^NOSUCHNAME is not a valid Sys::Syslog macro/', 
    "calling constant() with a non existing name" );

# Testing all macros
if(@names) {
    for my $name (@names) {
        like( Sys::Syslog::constant($name), 
              '/^(?:\d+|Your vendor has not defined Sys::Syslog macro '.$name.', used)$/', 
              "checking that $name is a number (".Sys::Syslog::constant($name).")" );
    }
}

