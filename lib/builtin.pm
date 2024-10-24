package builtin 0.016;

use v5.40;

# All code, including &import, is implemented by always-present
# functions in the perl interpreter itself.
# See also `builtin.c` in perl source

__END__

=head1 NAME

builtin - Perl pragma to import built-in utility functions

=head1 SYNOPSIS

    use builtin qw(
        true false is_bool
        inf nan
        weaken unweaken is_weak
        blessed refaddr reftype
        created_as_string created_as_number
        stringify
        ceil floor
        indexed
        trim
        is_tainted
        export_lexically
        load_module
    );

    use builtin ':5.40';  # most of the above

=head1 DESCRIPTION

Perl provides several utility functions in the C<builtin> package. These are
plain functions, and look and behave just like regular user-defined functions
do. They do not provide new syntax or require special parsing. These functions
are always present in the interpreter and can be called at any time by their
fully-qualified names. By default they are not available as short names, but
can be requested for convenience.

Individual named functions can be imported by listing them as import
parameters on the C<use> statement for this pragma.

B<Warning>:  At present, many of the functions in the C<builtin> namespace are
experimental.  Calling them will trigger warnings of the
C<experimental::builtin> category.

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

Once imported, a lexical function is much like any other lexical symbol
(such as a variable) in that it cannot be removed again.  If you wish to
limit the visiblity of an imported C<builtin> function, put it inside its
own scope:

    {
      use builtin 'refaddr';
      ...
    }

=head2 Version Bundles

The entire set of builtin functions that were considered non-experimental by a
version of perl can be imported all at once, by requesting a version bundle.
This is done by giving the perl release version (without its subversion
suffix) after a colon character:

    use builtin ':5.40';

The following bundles currently exist:

    Version    Includes
    -------    --------

    :5.40      true false weaken unweaken is_weak blessed refaddr reftype
               ceil floor is_tainted trim indexed

=head2 Read-only Functions

Various optimisations that apply to many functions in the L<builtin> package
would be broken if the functions are ever replaced or changed, such as by
assignment into glob references.  Because of this, the globs that contain
them are set read-only since Perl version 5.41.5, preventing such replacement.

    $ perl -e '*builtin::reftype = sub { "BOO" }'
    Modification of a read-only value attempted at -e line 1.

=head1 FUNCTIONS

=head2 true

    $val = true;

Returns the boolean truth value. While any scalar value can be tested for
truth and most defined, non-empty and non-zero values are considered "true"
by perl, this one is special in that L</is_bool> considers it to be a
distinguished boolean value.

This gives an equivalent value to expressions like C<!!1> or C<!0>.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 false

    $val = false;

Returns the boolean fiction value. While any non-true scalar value is
considered "false" by perl, this one is special in that L</is_bool> considers
it to be a distinguished boolean value.

This gives an equivalent value to expressions like C<!!0> or C<!1>.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 is_bool

    $bool = is_bool($val);

This function is currently B<experimental>.

Returns true when given a distinguished boolean value, or false if not. A
distinguished boolean value is the result of any boolean-returning builtin
function (such as C<true> or C<is_bool> itself), boolean-returning operator
(such as the C<eq> or C<==> comparison tests or the C<!> negation operator),
or any variable containing one of these results.

This function used to be named C<isbool>. A compatibility alias is provided
currently but will be removed in a later version.

Available starting with Perl 5.36.

=head2 inf

    $num = inf;

This function is currently B<experimental>.

Returns the floating-point infinity value.

Available starting with Perl 5.40.

=head2 nan

    $num = nan;

This function is currently B<experimental>.

Returns the floating-point "Not-a-Number" value.

Available starting with Perl 5.40.

=head2 weaken

    weaken($ref);

Weakens a reference. A weakened reference does not contribute to the reference
count of its referent. If only weakened references to a referent remain, it
will be disposed of, and all remaining weak references to it will have their
value set to C<undef>.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 unweaken

    unweaken($ref);

Strengthens a reference, undoing the effects of a previous call to L</weaken>.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 is_weak

    $bool = is_weak($ref);

Returns true when given a weakened reference, or false if not a reference or
not weak.

This function used to be named C<isweak>. A compatibility alias is provided
currently but will be removed in a later version.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 blessed

    $str = blessed($ref);

Returns the package name for an object reference, or C<undef> for a
non-reference or reference that is not an object.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 refaddr

    $num = refaddr($ref);

Returns the memory address for a reference, or C<undef> for a non-reference.
This value is not likely to be very useful for pure Perl code, but is handy as
a means to test for referential identity or uniqueness.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 reftype

    $str = reftype($ref);

Returns the basic container type of the referent of a reference, or C<undef>
for a non-reference. This is returned as a string in all-capitals, such as
C<ARRAY> for array references, or C<HASH> for hash references.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 created_as_string

    $bool = created_as_string($val);

This function is currently B<experimental>.

Returns a boolean representing if the argument value was originally created as
a string. It will return true for any scalar expression whose most recent
assignment or modification was of a string-like nature - such as assignment
from a string literal, or the result of a string operation such as
concatenation or regexp. It will return false for references (including any
object), numbers, booleans and undef.

It is unlikely that you will want to use this for regular data validation
within Perl, as it will not return true for regular numbers that are still
perfectly usable as strings, nor for any object reference - especially objects
that overload the stringification operator in an attempt to behave more like
strings. For example

    my $val = URI->new( "https://metacpan.org/" );

    if( created_as_string $val ) { ... }    # this will not execute

Available starting with Perl 5.36.

=head2 created_as_number

    $bool = created_as_number($val);

This function is currently B<experimental>.

Returns a boolean representing if the argument value was originally created as
a number. It will return true for any scalar expression whose most recent
assignment or modification was of a numerical nature - such as assignment from
a number literal, or the result of a numerical operation such as addition. It
will return false for references (including any object), strings, booleans and
undef.

It is unlikely that you will want to use this for regular data validation
within Perl, as it will not return true for regular strings of decimal digits
that are still perfectly usable as numbers, nor for any object reference -
especially objects that overload the numification operator in an attempt to
behave more like numbers. For example

    my $val = Math::BigInt->new( 123 );

    if( created_as_number $val ) { ... }    # this will not execute

While most Perl code should operate on scalar values without needing to know
their creation history, these two functions are intended to be used by data
serialisation modules such as JSON encoders or similar situations, where
language interoperability concerns require making a distinction between values
that are fundamentally stringlike versus numberlike in nature.

Available starting with Perl 5.36.

=head2 stringify

    $str = stringify($val);

This function is currently B<experimental>.

Returns a new plain perl string that represents the given argument.

When given a value that is already a string, a copy of this value is returned
unchanged. False booleans are treated like the empty string.

Numbers are turned into a decimal representation. True booleans are treated
like the number 1.

References to objects in classes that have L<overload> and define the C<"">
overload entry will use the delegated method to provide a value here.

Non-object references, or references to objects in classes without a C<"">
overload will return a string that names the underlying container type of
the reference, its memory address, and possibly its class name if it is an
object.

Available starting with Perl 5.40.

=head2 ceil

    $num = ceil($num);

Returns the smallest integer value greater than or equal to the given
numerical argument.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 floor

    $num = floor($num);

Returns the largest integer value less than or equal to the given numerical
argument.

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

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

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

=head2 trim

    $stripped = trim($string);

Returns the input string with whitespace stripped from the beginning
and end. trim() will remove these characters:

" ", an ordinary space.

"\t", a tab.

"\n", a new line (line feed).

"\r", a carriage return.

and all other Unicode characters that are flagged as whitespace.
A complete list is in L<perlrecharclass/Whitespace>.

    $var = "  Hello world   ";            # "Hello world"
    $var = "\t\t\tHello world";           # "Hello world"
    $var = "Hello world\n";               # "Hello world"
    $var = "\x{2028}Hello world\x{3000}"; # "Hello world"

C<trim> is equivalent to:

    $str =~ s/\A\s+|\s+\z//urg;

Available starting with Perl 5.36. Since Perl 5.40, it is no longer
experimental and it is included in the 5.40 and higher builtin version
bundles.

For Perl versions where this function is not available look at the
L<String::Util> module for a comparable implementation.

=head2 is_tainted

    $bool = is_tainted($var);

Returns true when given a tainted variable.

Available starting with Perl 5.38.

=head2 export_lexically

    export_lexically($name1, $ref1, $name2, $ref2, ...)

This function is currently B<experimental>.

Exports new lexical names into the scope currently being compiled. Names given
by the first of each pair of values will refer to the corresponding item whose
reference is given by the second. Types of item that are permitted are
subroutines, and scalar, array, and hash variables. If the item is a
subroutine, the name may optionally be prefixed with the C<&> sigil, but for
convenience it doesn't have to. For items that are variables the sigil is
required, and must match the type of the variable.

    export_lexically func    => \&func,
                     '&func' => \&func;  # same as above

    export_lexically '$scalar' => \my $var;

Z<>

    # The following are not permitted
    export_lexically '$var' => \@arr;   # sigil does not match
    export_lexically name => \$scalar;  # implied '&' sigil does not match

    export_lexically '*name' => \*globref;  # globrefs are not supported

This must be called at compile time; which typically means during a C<BEGIN>
block. Usually this would be used as part of an C<import> method of a module,
when invoked as part of a C<use ...> statement.

Available starting with Perl 5.38.

=head2 load_module

    load_module($module_name);

This function is currently B<experimental>.

Loads a named module from the inclusion paths (C<@INC>).  C<$module_name> must
be a string that provides a module name.  It cannot be omitted, and providing
an invalid module name will result in an exception.  Not providing any argument
results in a compilation error.  Returns the loaded module's name on success.

The effect of C<load_module>-ing a module is mostly the same as C<require>-ing,
down to the same error conditions when the module does not exist, does not
compile, or does not evaluate to a true value.  See also
L<the C<module_true> feature|feature/"The 'module_true' feature">.

C<load_module> can't be used to require a particular version of Perl, nor can
it be given a bareword module name as an argument.

Available starting with Perl 5.40.

=head1 SEE ALSO

L<perlop>, L<perlfunc>, L<Scalar::Util>
