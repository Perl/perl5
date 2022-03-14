package builtin 0.004;

use strict;
use warnings;

# All code, including &import, is implemented by always-present functions in
# the perl interpreter itself.
# See also `builtin.c` in perl source

1;
__END__

=head1 NAME

builtin - Perl pragma to import built-in utility functions

=head1 SYNOPSIS

    use builtin qw(
        true false is_bool
        weaken unweaken is_weak
        blessed refaddr reftype
        ceil floor
    );

=head1 DESCRIPTION

Perl provides several utility functions in the C<builtin> package. These are
plain functions, and look and behave just like regular user-defined functions
do. They do not provide new syntax or require special parsing. These functions
are always present in the interpreter and can be called at any time by their
fully-qualified names. By default they are not available as short names, but
can be requested for convenience.

Individual named functions can be imported by listing them as import
parameters on the C<use> statement for this pragma.

The overall C<builtin> mechanism, as well as every individual function it
provides, are currently B<experimental>.

=head2 Lexical Import

This pragma module creates I<lexical> aliases in the currently-compiling scope
to these builtin functions. This is similar to the lexical effect of other
pragmas such as L<strict> and L<feature>.

    sub classify
    {
        my $val = shift;

        use builtin 'is_bool';
        return is_bool($val) ? "boolean" : "not a boolean";
    }

    # the is_bool() function is no longer visible here
    # but may still be called by builtin::is_bool()

Because these functions are imported lexically, rather than by package
symbols, the user does not need to take any special measures to ensure they
don't accidentally appear as object methods from a class.

    package An::Object::Class {
        use builtin 'true', 'false';
        ...
    }

    # does not appear as a method
    An::Object::Class->true;

    # Can't locate object method "true" via package "An::Object::Class"
    #   at ...

=head1 FUNCTIONS

=head2 true

    $val = true;

Returns the boolean truth value. While any scalar value can be tested for
truth and most defined, non-empty and non-zero values are considered "true"
by perl, this one is special in that L</is_bool> considers it to be a
distinguished boolean value.

This gives an equivalent value to expressions like C<!!1> or C<!0>.

=head2 false

    $val = false;

Returns the boolean fiction value. While any non-true scalar value is
considered "false" by perl, this one is special in that L</is_bool> considers
it to be a distinguished boolean value.

This gives an equivalent value to expressions like C<!!0> or C<!1>.

=head2 is_bool

    $bool = is_bool($val);

Returns true when given a distinguished boolean value, or false if not. A
distinguished boolean value is the result of any boolean-returning builtin
function (such as C<true> or C<is_bool> itself), boolean-returning operator
(such as the C<eq> or C<==> comparison tests or the C<!> negation operator),
or any variable containing one of these results.

This function used to be named C<isbool>. A compatibility alias is provided
currently but will be removed in a later version.

=head2 weaken

    weaken($ref);

Weakens a reference. A weakened reference does not contribute to the reference
count of its referent. If only weakened references to a referent remain, it
will be disposed of, and all remaining weak references to it will have their
value set to C<undef>.

=head2 unweaken

    unweaken($ref);

Strengthens a reference, undoing the effects of a previous call to L</weaken>.

=head2 is_weak

    $bool = is_weak($ref);

Returns true when given a weakened reference, or false if not a reference or
not weak.

This function used to be named C<isweak>. A compatibility alias is provided
currently but will be removed in a later version.

=head2 blessed

    $str = blessed($ref);

Returns the package name for an object reference, or C<undef> for a
non-reference or reference that is not an object.

=head2 refaddr

    $num = refaddr($ref);

Returns the memory address for a reference, or C<undef> for a non-reference.
This value is not likely to be very useful for pure Perl code, but is handy as
a means to test for referential identity or uniqueness.

=head2 reftype

    $str = reftype($ref);

Returns the basic container type of the referent of a reference, or C<undef>
for a non-reference. This is returned as a string in all-capitals, such as
C<ARRAY> for array references, or C<HASH> for hash references.

=head2 ceil

    $num = ceil($num);

Returns the smallest integer value greater than or equal to the given
numerical argument.

=head2 floor

    $num = floor($num);

Returns the largest integer value less than or equal to the given numerical
argument.

=head2 indexed

    @ivpairs = indexed(@items)

Returns an even-sized list of number/value pairs, where each pair is formed
of a number giving an index in the original list followed by the value at that
position in it.  I.e. returns a list twice the size of the original, being
equal to

    (0, $items[0], 1, $items[1], 2, $items[2], ...)

Note that unlike the core C<values> function, this function returns copies of
its original arguments, not aliases to them. Any modifications of these copies
are I<not> reflected in modifications to the original.

    my @x = ...;
    $_++ for indexed @x;  # The @x array remains unaffected

This function is primarily intended to be useful combined with multi-variable
C<foreach> loop syntax; as

    foreach my ($index, $value) (indexed LIST) {
        ...
    }

In scalar context this function returns the size of the list that it would
otherwise have returned, and provokes a warning in the C<scalar> category.

=head1 SEE ALSO

L<perlop>, L<perlfunc>, L<Scalar::Util>

=cut
