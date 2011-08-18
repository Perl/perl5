#!./perl

# test \\

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

package main;
require './test.pl';

plan( tests => 34 );

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

# assignment

my %copy = %h;
foreach my $key (keys %copy) {
    is( $copy{$key} \\= 'wibble', $h{$key}, '\\\\= : hash non-assignment returns old value' );
    is( $copy{$key}, $h{$key}, '\\\\= : does not assign to hash' );
}

is( $copy{not} \\= 'wibble', 'wibble', '\\\\= : hash assignment returns new value' );
is( $copy{not}, 'wibble',  '\\\\= : assigns to hash' );

my @copy = @a;
foreach my $idx (keys @copy) {
    is( $copy[$idx] \\= 'wibble', $a[$idx], '\\\\= : array non-assignment returns old value' );
    is( $copy[$idx], $a[$idx], '\\\\= : does not assign to array' );
}

is( $copy[4] \\= 'wibble', 'wibble', '\\\\= : array assignment returns new value' );
is( $copy[4], 'wibble', '\\\\= : assigns to array' );

eval { $copy{neither} \\= die "wobble" };
like( $@, qr/\Awobble at\b/, "die on RHS of hash assignment dies" );
ok( !exists($copy{neither}), "die on RHS of hash assignment doesn't create the element" );

eval { $copy[42] \\= die "wobble" };
like( $@, qr/\Awobble at\b/, "die on RHS of array assignment dies" );
ok( !exists($copy[42]), "die on RHS of array assignment doesn't create the element" );


# Error cases
foreach my $code (
    '$foo \\\\ "wibble"',
    '&bar \\\\ "wibble"',
    '"wobble" \\\\ "wibble"',
) {
    eval $code;
    like( $@, qr/\Aexists or \(\\\\\) argument is not a HASH or ARRAY element at/, "syntax error: $code" );
    (my $assign = $code) =~ s/\\\\/\\\\=/;
    eval $assign;
    like( $@, qr/\Aexists or assignment \(\\\\=\) argument is not a HASH or ARRAY element at/, "syntax error: $assign" );
}
