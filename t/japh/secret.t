#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use Config;

my ( $UV_MAX, $UV_MIN, $IV_MAX, $IV_MIN );
{
    use integer;
    $UV_MAX = 2**( 8 * $Config{uvsize} ) - 1;
    $UV_MIN = -2**( 8 * $Config{uvsize} );
    $IV_MAX = 2**( 8 * $Config{ivsize} - 1 ) - 1;
    $IV_MIN = -2**( 8 * $Config{ivsize} - 1 );
}
(my $uvuformat = "%" . $Config{uvuformat}) =~ tr/"//d;
(my $ivdformat = "%" . $Config{ivdformat}) =~ tr/"//d;

my ( $got, @got, %got );
my $true  = 1;
my $false = '';

# venus
is( 0+ '23a',       23,   '0+' );
is( 0+ '3.00',      3,    '0+' );
is( 0+ '1.2e3',     1200, '0+' );
is( 0+ '42 EUR',    42,   '0+' );
is( 0+ 'two cents', 0,    '0+' );
ok( ( 0+ [] ) =~ /^[1-9][0-9]*$/, '0+' );

# baby cart
{
    local $" = ',';
    %got = ( 'a' .. 'f' );
    is( "A @{[sort keys %got]} Z", "A a,c,e Z", '@{[ ]}' );
}

# bang bang
is( !!$true,      $true,  '!!' );
is( !!$false,     $false, '!!' );
is( !!'a string', $true,  '!!' );
is( !!undef,      $false, '!!' );

# eskimo greeting
# TODO }{

# inchworm
$got = time;
is( scalar localtime $got, ~~ localtime $got, '~~' );
@got = localtime;
is( ~~ @got, 9, '~~' );

is( ~~ 1.23, 1, '~~ exception' );    # floating point

$got = '1.23';                       # string
is( ~~ $got, 1, '~~ exception' ) if $got != 0;    # used in numeric context

$got = $UV_MAX + 1;
is( ~~ $got, sprintf($uvuformat, $UV_MAX), '~~ exception' );
$got = -1;
is( ~~ $got, sprintf($uvuformat, $UV_MAX), '~~ exception' );

$got = 2**( 8 * $Config{uvsize} - 1 );
{
    use integer;
    is( ~~ $got, sprintf($ivdformat, $IV_MIN), '~~ exception' );
}
$got = -2**( 8 * $Config{uvsize} - 1 ) - 1;
{
    use integer;
    is( ~~ $got, sprintf($ivdformat, $IV_MIN), '~~ exception' );
}

# TODO
# show overloading "" example

# backward inchworm on a stick
for my $val ( $IV_MAX, $IV_MIN + 1, 0, 1, -1 ) {
    $got = $val;
    if( $val <= 0 ) {
        use integer;
        is( ~- $got, $val - 1, '~-' );
    }
    else {
        is( ~- $got, $val - 1, '~-' );
    }
}

# forward inchworm on a stick
for my $val ( $IV_MAX -1 , $IV_MIN, 0, 1, -1 ) {
    $got = $val;
    if( $val >= 0 ) {
        use integer;
        is( -~ $got, $val + 1, '-~' );
    }
    else {
        is( -~ $got, $val + 1, '-~' );
    }
}


    # $y = ~-$x * 4;    # identical to $y = ($x-1)*4;

# Exceptions

# space station
is( -+- '23a',       23,   '-+-' );
is( -+- '3.00',      3,    '-+-' );
is( -+- '1.2e3',     1200, '-+-' );
is( -+- '42 EUR',    42,   '-+-' );
ok( ( -+- [] ) =~ /^[1-9][0-9]*$/, '-+-' );

is( -+- 'two cents', '+two cents',    '-+- exception' );
is( -+- '-2B' x 5, '-2B-2B-2B-2B-2B', '-+- exception' );

# goatse
my $n;
$_ = "word2 and word3";
$n =()= /word1|word2|word3/g;
is( $n, 2, '=()=' );
$n =()= "abababab" =~ /a/;
is( $n, 1, '=()=' );
$n =()= "abababab" =~ /a/g;
is( $n, 4, '=()=' );
$n =($got)= "abababab" =~ /a/g;
is( $n, 4, '=()=' );
is( $got, 'a', '=()=' );
$n =(@got)= "abababab" =~ /a/g;
is( $n, 4, '=()=' );
is( "@got", 'a a a a', '=()=' );

# goatse + split
$n =()= @{[ split /:/, "a:a:a:a" ]};
is( $n, 4, "=()= split" );
$n =()= split /:/, "a:a:a:a", -1;
is( $n, 4, "=()= split" );

# flaming xwing
@got =<DATA>=~ /(\d+) is (\w+)/;
is( "@got", '31337 eleet', '=<>=~' );

# kite
@got = ( ~~<DATA>, ~~<DATA> );
is( "@got", "camel\n llama\n", '~~<>' );

# 0rnate double bladed sword
$got = 1;

<<m=~m>>

# this is not code
# and should never be run
$got = 0;

m
;

ok( $got, '<<=~m>> m ;' );


# screwdrivers
for my $val ( -1, 0, 1, 1.5, -1.5, -0.5 ) {
   my $val_plus_1  = $val + 1;
   my $val_minus_1 = $val - 1;

   # flathead long handle
   ($got = $val ) -=!! $true;
   is( $got, $val_minus_1, '-=!!' );
   ($got = $val ) -=!! $false;
   is( $got, $val, '-=!!' );

   # flathead short handle
   ($got = $val ) -=! $true;
   is( $got, $val, '-=!' );
   ($got = $val ) -=! $false;
   is( $got, $val_minus_1, '-=!' );

   # phillips long handle
   ($got = $val ) +=!! $true;
   is( $got, $val_plus_1, '+=!!' );
   ($got = $val ) +=!! $false;
   is( $got, $val, '+=!!' );

   # phillips short handle
   ($got = $val ) +=! $true;
   is( $got, $val, '+=!' );
   ($got = $val ) +=! $false;
   is( $got, $val_plus_1, '+=!' );

   # torx long handle
   ($got = $val ) *=!! $true;
   is( $got, $val, "$val *=!! true" );

SKIP: {
    skip '*=!! and *=! broken with negative != -1 on perl <= 5.013005', 2
       if $val < 0 && $val != -1 && $] <= 5.013005;
    ( $got = $val ) *=!! $false;
    is( $got, 0, "$val *=!! false" );

   # torx short handle
   ($got = $val ) *=! $true;
   is( $got, 0, "$val *=! true" );
}
   ($got = $val ) *=! $false;
   is( $got, $val, "$val *=! false" );

   # pozidriv long handle
   ($got = $val ) x=!! $true;
   is( $got, $val . '' , 'x=!!' );
   ($got = $val ) x=!! $false;
   is( $got, '', 'x=!!' );

   # pozidriv short handle
   ($got = $val ) x=! $true;
   is( $got, '', 'x=!' );
   ($got = $val ) x=! $false;
   is( $got, $val . '', 'x=!' );
}


# Winking fat comma
sub APPLE  () { 1 }
sub CHERRY () { 2 }
sub BANANA () { 3 }
%got = (
  APPLE   ,=>  "green",
  CHERRY  ,=>  "red",
  BANANA  ,=>  "yellow",
);
is( "@{[ sort keys %got ]}", '1 2 3', ',=>' );

# Enterprise
%got = (
    apples   => 3,
    bananas  => 1,
    cherries => 41,
    gin      => 1,
);
@got = (
    'bread',
    'milk',
   ('apples'  )x!! ( $got{apples} < 2 ),
   ('bananas' )x!! ( $got{bananas} < 2 ),
   ('cherries')x!! ( $got{cherries} < 20 ),
   ('tonic'   )x!! $got{gin},
);
is( "@got", "bread milk bananas tonic", '()x!!' );

# space fleet
is( <=><=><=>, 0, '<=><=><=>' );

# amphisbaena
# TODO <~>

done_testing;

__DATA__
31337 is eleet
camel
llama
dromedary
