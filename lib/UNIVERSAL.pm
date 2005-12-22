package UNIVERSAL;

our $VERSION = '1.03';

# UNIVERSAL should not contain any extra subs/methods beyond those
# that it exists to define. The use of Exporter below is a historical
# accident that can't be fixed without breaking code.  Note that we
# *don't* set @ISA here, as we don't want all classes/objects inheriting from
# Exporter.  It's bad enough that all classes have a import() method
# whenever UNIVERSAL.pm is loaded.
require Exporter;
@EXPORT_OK = qw(isa can VERSION);

# Make sure that even though the import method is called, it doesn't do
# anything unless called on UNIVERSAL.
sub import {
    return unless $_[0] eq __PACKAGE__;
    goto &Exporter::import;
}

1;
__END__

=head1 NAME

UNIVERSAL - base class for ALL classes (blessed references)

=head1 SYNOPSIS

    $is_io = $fd->isa("IO::Handle");
    $is_io = Class->isa("IO::Handle");

    $sub   = $obj->can("print");
    $sub   = Class->can("print");

    $sub   = eval { $ref->can("fandango") };
    $ver   = $obj->VERSION;

    # but never do this!
    $is_io = UNIVERSAL::isa($fd, "IO::Handle");
    $sub   = UNIVERSAL::can($obj, "print");

=head1 DESCRIPTION

C<UNIVERSAL> is the base class from which all blessed references inherit.
See L<perlobj>.

C<UNIVERSAL> provides the following methods:

=over 4

=item C<< $obj->isa( TYPE ) >>

=item C<< CLASS->isa( TYPE ) >>

=item C<< eval { VAL->isa( TYPE ) } >>

Where

=over 4

=item C<TYPE>

is a package name

=item C<$obj>

is a blessed reference or a string containing a package name

=item C<CLASS>

is a package name

=item C<VAL>

is any of the above or an unblessed reference

=back

When used as an instance or class method (C<< $obj->isa( TYPE ) >>),
C<isa> returns I<true> if $obj is blessed into package C<TYPE> or
inherits from package C<TYPE>.

When used as a class method (C<< CLASS->isa( TYPE ) >>, sometimes
referred to as a static method), C<isa> returns I<true> if C<CLASS>
inherits from (or is itself) the name of the package C<TYPE> or
inherits from package C<TYPE>.

If you're not sure what you have (the C<VAL> case), wrap the method call in an
C<eval> block to catch the exception if C<VAL> is undefined.

If you want to be sure that you're calling C<isa> as a method, not a class,
check the invocant with C<blessed> from L<Scalar::Util> first:

  use Scalar::Util 'blessed';

  if ( blessed( $obj ) && $obj->isa("Some::Class") {
      ...
  }

=item C<< $obj->can( METHOD ) >>

=item C<< CLASS->can( METHOD ) >>

=item C<< eval { VAL->can( METHOD ) } >>

C<can> checks if the object or class has a method called C<METHOD>. If it does,
then it returns a reference to the sub.  If it does not, then it returns
I<undef>.  This includes methods inherited or imported by C<$obj>, C<CLASS>, or
C<VAL>.

C<can> cannot know whether an object will be able to provide a method through
AUTOLOAD (unless the object's class has overriden C<can> appropriately), so a
return value of I<undef> does not necessarily mean the object will not be able
to handle the method call. To get around this some module authors use a forward
declaration (see L<perlsub>) for methods they will handle via AUTOLOAD. For
such 'dummy' subs, C<can> will still return a code reference, which, when
called, will fall through to the AUTOLOAD. If no suitable AUTOLOAD is provided,
calling the coderef will cause an error.

You may call C<can> as a class (static) method or an object method.

Again, the same rule about having a valid invocant applies -- use an C<eval>
block or C<blessed> if you need to be extra paranoid.

=item C<VERSION ( [ REQUIRE ] )>

C<VERSION> will return the value of the variable C<$VERSION> in the
package the object is blessed into. If C<REQUIRE> is given then
it will do a comparison and die if the package version is not
greater than or equal to C<REQUIRE>.

C<VERSION> can be called as either a class (static) method or an object
method.

=back

=head1 EXPORTS

None by default.

You may request the import of all three functions (C<isa>, C<can>, and
C<VERSION>), however it is usually harmful to do so.  Please don't do this in
new code.

For example, previous versions of this documentation suggested using C<isa> as
a function to determine the type of a reference:

  use UNIVERSAL 'isa';

  $yes = isa $h, "HASH";
  $yes = isa "Foo", "Bar";

The problem is that this code will I<never> call an overridden C<isa> method in
any class.  Instead, use C<reftype> from L<Scalar::Util> for the first case:

  use Scalar::Util 'reftype';

  $yes = reftype( $h ) eq "HASH";

and the method form of C<isa> for the second:

  $yes = Foo->isa("Bar");

=cut
