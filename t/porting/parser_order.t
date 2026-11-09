#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;
use Config;

#
# C does not define the evaluation order for the arguments to a function,
# instead it relies on the developer to structure their code appropriately
# if they need a well defined evaluation order.
#
# This is fine for functions which have no visible side-effects, but for
# functions which can generate warnings, or increment line numbers or alter
# parse state, the order may matter and may even be visible to the end user.
#
# This test checks parser .c files for such cases, and fails tests if there
# are any such cases. It is by no means complete, this is just what I could
# work out so far. Feel free to extend the list to handle more cases or
# functions.
#

my @files_to_check = qw( perly.y op.c toke.c );

my $sensitive = qr/\b(?:Perl_|S_)?(?:
    scalar | list | scalarvoid | voidnonfinal | op_contextualize
    | op_lvalue(?:_flags)? | ref | doref | jmaybe | oopsAV | oopsHV
    | newAVREF | newHVREF | newSTATEOP
)\s*\(/x;

my $parens = qr/(?<parens> \( (?: [^()]++ | (?&parens) )* \) )/x;

sub unordered_calls {
    my ($source) = @_;

    # Hide comments and literals while preserving diagnostic line numbers.
    $source =~ s{
        /\* .*? \*/ | // [^\n]*
        | " (?: \\. | [^"\\] )* "
        | ' (?: \\. | [^'\\] )* '
    }{' ' . ("\n" x ($& =~ tr/\n//)) . ' '}gsex;

    my @found;

    # Look ahead so nested calls are checked as well as their parents.
    while ( $source =~ /(?=\b([A-Za-z_]\w*)\s*($parens))/g ) {
        my ( $name, $args ) = ( $1, $2 );
        my $offset = pos($source);
        next if $name =~ /\A(?:if|while|switch|for|sizeof|return)\z/;
        $args = substr( $args, 1, -1 );

        # Parenthesized expressions consume their own commas. Only commas
        # at this level separate the enclosing call's arguments.
        my $affected = 0;
        while ( $args =~ /\G((?:[^(),]++|$parens)*)(?:,|\z)/g ) {
            my $arg = $1;
            ++$affected if $arg =~ $sensitive;
            last        if pos($args) == length($args);
        }
        if ( $affected > 1 ) {
            my $line = 1 + ( substr( $source, 0, $offset ) =~ tr/\n// );
            push @found, "$name at line $line";
        }
    }
    return @found;
}

# The original failure patterns this test was set up to find
my @bad = (
    'newBINOP(op, 0, scalar(left), scalar(right));',
    'newBINOP(op, 0, op_lvalue(scalar(left), op), scalar(right));',
    'newBINOP(op, 0, ref(newAVREF(array), OP_RV2AV), scalar(index));',
    'newRANGE(op, scalar(left), scalar(right));',
    'op_append_elem(OP_LINESEQ, op_append_elem(OP_LINESEQ,
        newSTATEOP(0, NULL, require_op), newSTATEOP(0, NULL, version_op)),
        newSTATEOP(0, NULL, import_op));',
    'newBINOP(op, 0, Perl_scalar(aTHX_ left), scalar(right));',
    'newBINOP(OP_AELEM, 0, oopsAV(array), scalar(selector));',
    'newBINOP(OP_HELEM, 0, oopsHV(hash), jmaybe(selector));',
    'newBINOP(OP_HELEM, 0,
        ref(newHVREF(hash_reference), OP_RV2HV), jmaybe(selector));',
    'op_prepend_elem(OP_ASLICE, newOP(OP_PUSHMARK, 0),
        newLISTOP(OP_ASLICE, 0, list(selector), ref(sliceme, OP_ASLICE)));',
    'op_prepend_elem(OP_KVASLICE, newOP(OP_PUSHMARK, 0),
        newLISTOP(OP_KVASLICE, 0,
            list(selector), ref(oopsAV(kvslice), OP_KVASLICE)));',
    'op_prepend_elem(OP_HSLICE, newOP(OP_PUSHMARK, 0),
        newLISTOP(OP_HSLICE, 0,
            list(selector), ref(oopsHV(sliceme), OP_HSLICE)));',
    'op_prepend_elem(OP_KVHSLICE, newOP(OP_PUSHMARK, 0),
        newLISTOP(OP_KVHSLICE, 0, list(selector), ref(kvslice, OP_KVHSLICE)));',
    'return newBINOP(OP_LSLICE, flags,
        list(op_force_list(subscript)), list(op_force_list(listval)));',
    'loop = (LOOP*)op_convert_list(OP_ENTERITER, enteriterflags,
        op_append_elem(OP_LIST, list(expr), scalar(sv)));',
);

# We shouldn't trigger on any of this.
my @good = (
    'left = scalar(left); right = scalar(right); newBINOP(op, 0, left, right);',
    'newBINOP(op, 0, op_lvalue(scalar(left), op), right);',
    'f((scalar(left), scalar(right)), other);',
    'return (scalar(left), scalar(right));',
    'f("scalar(left)", scalar(right));',
    'f("\"scalar(left)\"", scalar(right));',
    "f('(', scalar(right));",
    'f(/* scalar(left), */ scalar(right));',
    "f(// scalar(left),\n scalar(right));",
    'f(newOP(op, 0), newOP(op, 0));',
);

# First we test the test code on prior cases.
for my $source (@bad) {
    my @found = unordered_calls($source);
    ( my $label = $source ) =~ s/\s+/ /g;
    cmp_ok( scalar @found, '>', 0, "detect unordered calls in $label" );
}

# Make sure we don't match any good cases.
for my $source (@good) {
    my @found = unordered_calls($source);
    ( my $label = $source ) =~ s/\s+/ /g;
    is( scalar @found, 0, "allow $label" );
}

# Make sure comments don't mess stuff up.
my @located =
  unordered_calls("/* comment\n */\nf(scalar(left), scalar(right));");
is( $located[0], 'f at line 3', 'comments preserve diagnostic line numbers' );

# and finally the real test!
SKIP: {
    skip( 'Source files are unavailable when cross-compiling', 3 )
      if $Config{usecrosscompile};

    # Check the grammar input rather than its generated copies. This is a
    # guard for known helpers, not a general C side-effect analysis. Macros
    # and helpers outside the list above need separate review.
    for my $file (@files_to_check) {
        open my $fh, '<', "../$file" or die "Cannot open $file: $!";
        my $source = do { local $/; <$fh> };
        close $fh or die "Cannot close $file: $!";
        my @found = unordered_calls($source);
        is( 0 + @found, 0, "$file sequences order-sensitive parser calls" )
          or diag( join "\n", @found );
    }
}

done_testing();
