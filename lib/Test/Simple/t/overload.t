#!/usr/bin/perl -w

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
use Test::More;

BEGIN {
    if( !eval "require overload" ) {
        plan skip_all => "needs overload.pm";
    }
    else {
        plan tests => 7;
    }
}


package Overloaded;

use overload
        q{""}    => sub { $_[0]->{string} },
        q{0}     => sub { $_[0]->{num} },
        fallback => 1;

sub new {
    my $class = shift;
    bless { string => shift, num => shift }, $class;
}


package main;

my $obj = Overloaded->new('foo', 42);
isa_ok $obj, 'Overloaded';

is $obj, 'foo',            'is() with string overloading';
cmp_ok $obj, 'eq', 'foo',  'cmp_ok() ...';
cmp_ok $obj, '==', 'foo',  'cmp_ok() with number overloading';

is_deeply [$obj], ['foo'],                 'is_deeply with string overloading';
ok eq_array([$obj], ['foo']),              'eq_array ...';
ok eq_hash({foo => $obj}, {foo => 'foo'}), 'eq_hash ...';
