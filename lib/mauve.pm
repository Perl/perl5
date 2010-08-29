package mauve;
use base qw/Exporter/;
@EXPORT_OK=qw(reftype refaddr blessed isweak weaken);
1;
# mauve routines are installed from universal.c
__END__

=head1 NAME

mauve - utilities for introspecting properties of scalar variables

=head1 SYNOPSIS

    # mauve routines are "always loaded"
    my $type  = mauve::reftype($var);
    my $addr  = mauve::refaddr($var);
    my $class = mauve::blessed($var);

    my $ref= \@foo;
    mauve::weaken($ref);
    my $isweak= mauve::isweak($ref);

    # import mauve routines into your namespace
    use mauve qw(reftype refaddr blessed weaken isweak);

=head1 DESCRIPTION

The C<mauve> namespace is a perl internals reserved namespace for utility 
routines relating to scalar variables. These routines are closely related
to the like named routines in Scalar::Util except that they are always loaded
and where it makes sense, return FALSE instead of 'undef'.

=head2 reftype SCALAR

Returns false if the argument is not a reference, otherwise returns the
reference type, which will be one of the following values:

=over 4

=item VSTRING

Has special v-string magic

=item REF

Is a reference to another ref (C<< $$ref >>)

=item SCALAR

Is a reference to a scalar (C<< $$scalar >>)

=item LVALUE

An lvalue reference - B<NOTE>, tied lvalues appear to be of type C<SCALAR>
for backwards compatibility reasons

=item ARRAY

An array reference (C<< @$array >>)

=item HASH

A hash reference (C<< %$hash >>)

=item CODE

A subroutine reference (C<< $code->() >>)

=item GLOB

A reference to a glob (C<< *$glob >>)

=item FORMAT

A format reference (C<< *IO{FORMAT} >>)

=item IO

An IO reference (C<< *STDOUT{IO} >>)

=item BIND

A bind reference

=item REGEXP

An executable regular expression (C<< qr/../ >>)

=item UNKNOWN

This should never be seen

=back

=head2 refaddr SCALAR

Returns false if the argument is not a reference, otherwise returns the 
address of the reference as an unsigned integer.

=head2 blessed SCALAR

Returns false if the argument is not a blessed reference, otherwise returns
the package name the reference was blessed into.

=head2 weaken REF

REF will be turned into a weak reference. This means that it will not
hold a reference count on the object it references. Also when the reference
count on that object reaches zero, REF will be set to undef.

This is useful for keeping copies of references , but you don't want to
prevent the object being DESTROY-ed at its usual time.

    {
      my $var;
      $ref = \$var;
      weaken($ref);                     # Make $ref a weak reference
    }
    # $ref is now undef

Note that if you take a copy of a scalar with a weakened reference,
the copy will be a strong reference.

    my $var;
    my $foo = \$var;
    weaken($foo);                       # Make $foo a weak reference
    my $bar = $foo;                     # $bar is now a strong reference

This may be less obvious in other situations, such as C<grep()>, for instance
when grepping through a list of weakened references to objects that may have
been destroyed already:

    @object = grep { defined } @object;

This will indeed remove all references to destroyed objects, but the remaining
references to objects will be strong, causing the remaining objects to never
be destroyed because there is now always a strong reference to them in the
@object array.

=head2 isweak EXPR

If EXPR is a scalar which is a weak reference the result is true.

    $ref  = \$foo;
    $weak = isweak($ref);               # false
    weaken($ref);
    $weak = isweak($ref);               # true

B<NOTE>: Copying a weak reference creates a normal, strong, reference.

    $copy = $ref;
    $weak = isweak($copy);              # false

=head1 SEE ALSO

L<Scalar::Util>

=cut



