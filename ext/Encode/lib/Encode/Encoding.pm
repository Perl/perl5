package Encode::Encoding;
# Base class for classes which implement encodings
use strict;
our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub Define
{
    my $obj = shift;
    my $canonical = shift;
    $obj = bless { Name => $canonical },$obj unless ref $obj;
    # warn "$canonical => $obj\n";
  Encode::define_encoding($obj, $canonical, @_);
}

sub name { shift->{'Name'} }

# Temporary legacy methods
sub toUnicode    { shift->decode(@_) }
sub fromUnicode  { shift->encode(@_) }

sub new_sequence { return $_[0] }

sub DESTROY {}

1;
__END__

=head1 NAME

Encode::Encoding - Encode Implementation Base Class

=head1 SYNOPSIS

  package Encode::MyEncoding;
  use base qw(Encode::Encoding);

  __PACKAGE__->Define(qw(myCanonical myAlias));

=head1 DESCRIPTION

As mentioned in L<Encode>, encodings are (in the current
implementation at least) defined by objects. The mapping of encoding
name to object is via the C<%encodings> hash.

The values of the hash can currently be either strings or objects.
The string form may go away in the future. The string form occurs
when C<encodings()> has scanned C<@INC> for loadable encodings but has
not actually loaded the encoding in question. This is because the
current "loading" process is all Perl and a bit slow.

Once an encoding is loaded then value of the hash is object which
implements the encoding. The object should provide the following
interface:

=over 4

=item -E<gt>name

Should return the string representing the canonical name of the encoding.

=item -E<gt>new_sequence

This is a placeholder for encodings with state. It should return an
object which implements this interface, all current implementations
return the original object.

=item -E<gt>encode($string,$check)

Should return the octet sequence representing I<$string>. If I<$check>
is true it should modify I<$string> in place to remove the converted
part (i.e.  the whole string unless there is an error).  If an error
occurs it should return the octet sequence for the fragment of string
that has been converted, and modify $string in-place to remove the
converted part leaving it starting with the problem fragment.

If check is is false then C<encode> should make a "best effort" to
convert the string - for example by using a replacement character.

=item -E<gt>decode($octets,$check)

Should return the string that I<$octets> represents. If I<$check> is
true it should modify I<$octets> in place to remove the converted part
(i.e.  the whole sequence unless there is an error).  If an error
occurs it should return the fragment of string that has been
converted, and modify $octets in-place to remove the converted part
leaving it starting with the problem fragment.

If check is is false then C<decode> should make a "best effort" to
convert the string - for example by using Unicode's "\x{FFFD}" as a
replacement character.

=back

It should be noted that the check behaviour is different from the
outer public API. The logic is that the "unchecked" case is useful
when encoding is part of a stream which may be reporting errors
(e.g. STDERR).  In such cases it is desirable to get everything
through somehow without causing additional errors which obscure the
original one. Also the encoding is best placed to know what the
correct replacement character is, so if that is the desired behaviour
then letting low level code do it is the most efficient.

In contrast if check is true, the scheme above allows the encoding to
do as much as it can and tell layer above how much that was. What is
lacking at present is a mechanism to report what went wrong. The most
likely interface will be an additional method call to the object, or
perhaps (to avoid forcing per-stream objects on otherwise stateless
encodings) and additional parameter.

It is also highly desirable that encoding classes inherit from
C<Encode::Encoding> as a base class. This allows that class to define
additional behaviour for all encoding objects. For example built in
Unicode, UCS-2 and UTF-8 classes use :

  package Encode::MyEncoding;
  use base qw(Encode::Encoding);

  __PACKAGE__->Define(qw(myCanonical myAlias));

To create an object with bless {Name => ...},$class, and call
define_encoding.  They inherit their C<name> method from
C<Encode::Encoding>.

=head2 Compiled Encodings

For the sake of speed and efficiency, Most of the encodings are now
supported via I<Compiled Form> that are XS modules generated from UCM
files.   Encode provides enc2xs tool to achieve that.  Please see
L<enc2xs> for more details.

=head1 SEE ALSO

L<perlmod>, L<enc2xs>

=cut
