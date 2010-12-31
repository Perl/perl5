#!/usr/bin/perl

use strict;
use Test::More tests => 2;

BEGIN {
    $ENV{ PERL_JSON_BACKEND } = 0;
}

use JSON::PP;

my $obj = OverloadedObject->new( 'foo' );

ok( $obj eq 'foo' );

my $json = JSON::PP->new->convert_blessed;

is( $json->encode( [ $obj ] ), q{["foo"]} );



package OverloadedObject;

use overload 'eq' => sub { $_[0]->{v} eq $_[1] }, '""' => sub { $_[0]->{v} }, fallback => 1;


sub new {
    bless { v => $_[1] }, $_[0];
}


sub TO_JSON { "$_[0]"; }

