package Encode::Encoding;
# Base class for classes which implement encodings
use strict;
our $VERSION = do { my @r = (q$Revision: 0.96 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

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

F<Encode.xs> provides a class C<Encode::XS> which provides the
interface described above. It calls a generic octet-sequence to
octet-sequence "engine" that is driven by tables (defined in
F<encengine.c>). The same engine is used for both encode and
decode. C<Encode:XS>'s C<encode> forces Perl's characters to their
UTF-8 form and then treats them as just another multibyte
encoding. C<Encode:XS>'s C<decode> transforms the sequence and then
turns the UTF-8-ness flag as that is the form that the tables are
defined to produce. For details of the engine see the comments in
F<encengine.c>.

The tables are produced by the Perl script F<compile> (the name needs
to change so we can eventually install it somewhere). F<compile> can
currently read two formats:

=over 4

=item *.enc

This is a coined format used by Tcl. It is documented in
Encode/EncodeFormat.pod.

=item *.ucm

This is the semi-standard format used by IBM's ICU package.

=back

F<compile> can write the following forms:

=over 4

=item *.ucm

See above - the F<Encode/*.ucm> files provided with the distribution have
been created from the original Tcl .enc files using this approach.

=item *.c

Produces tables as C data structures - this is used to build in encodings
into F<Encode.so>/F<Encode.dll>.

=item *.xs

In theory this allows encodings to be stand-alone loadable Perl
extensions.  The process has not yet been tested. The plan is to use
this approach for large East Asian encodings.

=back

The set of encodings built-in to F<Encode.so>/F<Encode.dll> is
determined by F<Makefile.PL>.  The current set is as follows:

=over 4

=item ascii and iso-8859-*

That is all the common 8-bit "western" encodings.

=item IBM-1047 and two other variants of EBCDIC.

These are the same variants that are supported by EBCDIC Perl as
"native" encodings.  They are included to prove "reversibility" of
some constructs in EBCDIC Perl.

=item symbol and dingbats as used by Tk on X11.

(The reason Encode got started was to support Perl/Tk.)

=back

That set is rather ad hoc and has been driven by the needs of the
tests rather than the needs of typical applications. It is likely
to be rationalized.

=cut
