package integer;

our $VERSION = '1.00';

=head1 NAME

integer - Perl pragma to use integer arithmetic instead of floating point

=head1 SYNOPSIS

    use integer;
    $x = 10/3;
    # $x is now 3, not 3.33333333333333333

=head1 DESCRIPTION

This tells the compiler to use integer operations from here to the end
of the enclosing BLOCK.  On many machines, this doesn't matter a great
deal for most computations, but on those without floating point
hardware, it can make a big difference in performance.

Note that this only affects how certain operators handle their operands
and results, and not all numbers everywhere.  Specifically, C<use
integer;> has the effect that before computing the result of X + Y, X -
Y, X / Y, X * Y, X % Y, or -X (unary minus), the operands X and Y have
their fractional portions truncated, and the result will have its
fractional portion truncated as well.  For example, this code

    use integer;
    $x = 5.8;
    $y = 2.5;
    $, = ", ";
    print $x, -$x, $x + $y, $x - $y, $x / $y, $x * $y;

will print:  5.8, -5, 7, 3, 2, 10

Note that $x is still printed as having its true non-integer value of
5.8 since it wasn't operated on.  Also, arguments passed to functions
and the values returned by them are not affected by C<use integer;>.
E.g.,

    srand(1.5);
    $, = ", ";
    print sin(.5), cos(.5), atan2(1,2), sqrt(2), rand(10);

will give the same result with or without C<use integer;>  The power
operator C<**> is also not affected, so that 2 ** .5 is always the
square root of 2.

Finally, C<use integer;> also has an affect on the bitwise operators
"&", "|", "^", "~", "<<", and ">>".  Normally, the operands and results
are treated as unsigned integers, but with C<use integer;> the operands
and results are signed.  This means, among other things, that ~0 is -1,
and -2 & -5 is -6.

Internally, native integer arithmetic (as provided by your C compiler)
is used.  This means that Perl's own semantics for arithmetic
operations may not be preserved.  One common source of trouble is the
modulus of negative numbers, which Perl does one way, but your hardware
may do another.

    % perl -le 'print (4 % -3)'
    -2
    % perl -Minteger -le 'print (4 % -3)'
    1

See L<perlmod/Pragmatic Modules>.

=cut

$integer::hint_bits = 0x1;

sub import {
    $^H |= $integer::hint_bits;
}

sub unimport {
    $^H &= ~$integer::hint_bits;
}

1;
