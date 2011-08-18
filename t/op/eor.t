#!./perl

# test \\

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

package main;
require './test.pl';

plan( tests => 11 );

my %h = (
    foo => undef,
    bar => 0,
    baz => 69,
);

is( $h{foo} \\ 42, undef,  '\\\\ : left-hand hash operand undef' );
is( $h{bar} \\ 42, 0,      '\\\\ : left-hand hash operand false' );
is( $h{baz} \\ 42, 69,     '\\\\ : left-hand hash operand true' );
is( $h{not} \\ 42, 42,     '\\\\ : left-hand hash operand non-existant' );

my @a = ( undef, 0, 69 );

is( $a[0] \\ 42, undef,  '\\\\ : left-hand array operand undef' );
is( $a[1] \\ 42, 0,      '\\\\ : left-hand array operand false' );
is( $a[2] \\ 42, 69,     '\\\\ : left-hand array operand true' );
is( $a[3] \\ 42, 42,     '\\\\ : left-hand array operand non-existant' );

# Error cases
foreach my $code (
    '$foo \\\\ "wibble"',
    '&bar \\\\ "wibble"',
    '"wobble" \\\\ "wibble"',
) {
    eval $code;
    like( $@, qr/\Aexists or \(\\\\\) argument is not a HASH or ARRAY element at/, "syntax error: $code" );
}
