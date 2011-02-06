#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests =>  7;
use lib qw( lib );
use ExtUtils::ParseXS::Utilities qw(
  map_type
);

my ($type, $varname, $hiertype);
my ($result, $expected);

$type = 'struct DATA *';
$varname = 'RETVAL';
$hiertype = 0;
$expected = "$type\t$varname";
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, <$varname>, <$hiertype>" );

$type = 'Crypt::Shark';
$varname = undef;
$hiertype = 0;
$expected = 'Crypt__Shark';
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, undef, <$hiertype>" );

$type = 'Crypt::Shark';
$varname = undef;
$hiertype = 1;
$expected = 'Crypt::Shark';
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, undef, <$hiertype>" );

$type = 'Crypt::TC18';
$varname = 'RETVAL';
$hiertype = 0;
$expected = "Crypt__TC18\t$varname";
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, <$varname>, <$hiertype>" );

$type = 'Crypt::TC18';
$varname = 'RETVAL';
$hiertype = 1;
$expected = "Crypt::TC18\t$varname";
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, <$varname>, <$hiertype>" );

$type = 'array(alpha,beta) gamma';
$varname = 'RETVAL';
$hiertype = 0;
$expected = "alpha *\t$varname";
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, <$varname>, <$hiertype>" );

$type = '(*)';
$varname = 'RETVAL';
$hiertype = 0;
$expected = "(* $varname )";
$result = map_type($type, $varname, $hiertype);
is( $result, $expected,
    "Got expected map_type for <$type>, <$varname>, <$hiertype>" );
