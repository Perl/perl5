package Encode;
use strict;

our $VERSION = '0.02';

require DynaLoader;
require Exporter;

our @ISA = qw(Exporter DynaLoader);

# Public, encouraged API is exported by default
our @EXPORT = qw (
  encode
  decode
  encode_utf8
  decode_utf8
  find_encoding
  encodings
);

our @EXPORT_OK =
    qw(
       define_encoding
       define_alias
       from_to
       is_utf8
       is_8bit
       is_16bit
       utf8_upgrade
       utf8_downgrade
       _utf8_on
       _utf8_off
      );

bootstrap Encode ();

# Documentation moved after __END__ for speed - NI-S

use Carp;

# Make a %encoding package variable to allow a certain amount of cheating
our %encoding;
my @alias;  # ordered matching list
my %alias;  # cached known aliases
                     # 0  1  2  3  4  5   6   7   8   9  10
our @latin2iso_num = ( 0, 1, 2, 3, 4, 9, 10, 13, 14, 15, 16 );


sub encodings
{
 my ($class) = @_;
 return keys %encoding;
}

sub findAlias
{
 my $class = shift;
 local $_ = shift;
 unless (exists $alias{$_})
  {
   for (my $i=0; $i < @alias; $i += 2)
    {
     my $alias = $alias[$i];
     my $val   = $alias[$i+1];
     my $new;
     if (ref($alias) eq 'Regexp' && $_ =~ $alias)
      {
       $new = eval $val;
      }
     elsif (ref($alias) eq 'CODE')
      {
       $new = &{$alias}($val)
      }
     elsif (lc($_) eq lc($alias))
      {
       $new = $val;
      }
     if (defined($new))
      {
       next if $new eq $_; # avoid (direct) recursion on bugs
       my $enc = (ref($new)) ? $new : find_encoding($new);
       if ($enc)
        {
         $alias{$_} = $enc;
         last;
        }
      }
    }
  }
 return $alias{$_};
}

sub define_alias
{
 while (@_)
  {
   my ($alias,$name) = splice(@_,0,2);
   push(@alias, $alias => $name);
  }
}

# Allow variants of iso-8859-1 etc.
define_alias( qr/^iso[-_]?(\d+)[-_](\d+)$/i => '"iso-$1-$2"' );

# At least HP-UX has these.
define_alias( qr/^iso8859(\d+)$/i => '"iso-8859-$1"' );

# This is a font issue, not an encoding issue.
# (The currency symbol of the Latin 1 upper half
#  has been redefined as the euro symbol.)
define_alias( qr/^(.+)\@euro$/i => '"$1"' );

# Allow latin-1 style names as well
define_alias( qr/^(?:iso[-_]?)?latin[-_]?(\d+)$/i => '"iso-8859-$latin2iso_num[$1]"' );

# Common names for non-latin prefered MIME names
define_alias( 'ascii'    => 'US-ascii',
              'cyrillic' => 'iso-8859-5',
              'arabic'   => 'iso-8859-6',
              'greek'    => 'iso-8859-7',
              'hebrew'   => 'iso-8859-8');

# At least AIX has IBM-NNN (surprisingly...) instead of cpNNN.
define_alias( qr/^ibm[-_]?(\d\d\d\d?)$/i => '"cp$1"');

# Standardize on the dashed versions.
define_alias( qr/^utf8$/i  => 'utf-8' );
define_alias( qr/^koi8r$/i => 'koi8-r' );

# TODO: the HP-UX '8' encodings:  arabic8 greek8 hebrew8 roman8 turkish8
# TODO: the Thai Encoding tis620
# TODO: the Chinese Encoding gb18030
# TODO: what is the Japanese 'ujis' encoding seen in some Linuxes?

# Map white space and _ to '-'
define_alias( qr/^(\S+)[\s_]+(.*)$/i => '"$1-$2"' );

sub define_encoding
{
 my $obj  = shift;
 my $name = shift;
 $encoding{$name} = $obj;
 my $lc = lc($name);
 define_alias($lc => $obj) unless $lc eq $name;
 while (@_)
  {
   my $alias = shift;
   define_alias($alias,$obj);
  }
 return $obj;
}

sub getEncoding
{
 my ($class,$name) = @_;
 my $enc;
 if (ref($name) && $name->can('new_sequence'))
  {
   return $name;
  }
 if (exists $encoding{$name})
  {
   return $encoding{$name};
  }
 else
  {
   return $class->findAlias($name);
  }
}

sub find_encoding
{
 my ($name) = @_;
 return __PACKAGE__->getEncoding($name);
}

sub encode
{
 my ($name,$string,$check) = @_;
 my $enc = find_encoding($name);
 croak("Unknown encoding '$name'") unless defined $enc;
 my $octets = $enc->encode($string,$check);
 return undef if ($check && length($string));
 return $octets;
}

sub decode
{
 my ($name,$octets,$check) = @_;
 my $enc = find_encoding($name);
 croak("Unknown encoding '$name'") unless defined $enc;
 my $string = $enc->decode($octets,$check);
 return undef if ($check && length($octets));
 return $string;
}

sub from_to
{
 my ($string,$from,$to,$check) = @_;
 my $f = find_encoding($from);
 croak("Unknown encoding '$from'") unless defined $f;
 my $t = find_encoding($to);
 croak("Unknown encoding '$to'") unless defined $t;
 my $uni = $f->decode($string,$check);
 return undef if ($check && length($string));
 $string = $t->encode($uni,$check);
 return undef if ($check && length($uni));
 return length($_[0] = $string);
}

sub encode_utf8
{
 my ($str) = @_;
 utf8::encode($str);
 return $str;
}

sub decode_utf8
{
 my ($str) = @_;
 return undef unless utf8::decode($str);
 return $str;
}

package Encode::Encoding;
# Base class for classes which implement encodings

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

package Encode::XS;
use base 'Encode::Encoding';

package Encode::Internal;
use base 'Encode::Encoding';

# Dummy package that provides the encode interface but leaves data
# as UTF-X encoded. It is here so that from_to() works.

__PACKAGE__->Define('Internal');

Encode::define_alias( 'Unicode' => 'Internal' ) if ord('A') == 65;

sub decode
{
 my ($obj,$str,$chk) = @_;
 utf8::upgrade($str);
 $_[1] = '' if $chk;
 return $str;
}

*encode = \&decode;

package Encoding::Unicode;
use base 'Encode::Encoding';

__PACKAGE__->Define('Unicode') unless ord('A') == 65;

sub decode
{
 my ($obj,$str,$chk) = @_;
 my $res = '';
 for (my $i = 0; $i < length($str); $i++)
  {
   $res .= chr(utf8::unicode_to_native(ord(substr($str,$i,1))));
  }
 $_[1] = '' if $chk;
 return $res;
}

sub encode
{
 my ($obj,$str,$chk) = @_;
 my $res = '';
 for (my $i = 0; $i < length($str); $i++)
  {
   $res .= chr(utf8::native_to_unicode(ord(substr($str,$i,1))));
  }
 $_[1] = '' if $chk;
 return $res;
}


package Encode::utf8;
use base 'Encode::Encoding';
# package to allow long-hand
#   $octets = encode( utf8 => $string );
#

__PACKAGE__->Define(qw(UTF-8 utf8));

sub decode
{
 my ($obj,$octets,$chk) = @_;
 my $str = Encode::decode_utf8($octets);
 if (defined $str)
  {
   $_[1] = '' if $chk;
   return $str;
  }
 return undef;
}

sub encode
{
 my ($obj,$string,$chk) = @_;
 my $octets = Encode::encode_utf8($string);
 $_[1] = '' if $chk;
 return $octets;
}

package Encode::iso10646_1;
use base 'Encode::Encoding';
# Encoding is 16-bit network order Unicode (no surogates)
# Used for X font encodings

__PACKAGE__->Define(qw(UCS-2 iso-10646-1));

sub decode
{
 my ($obj,$str,$chk) = @_;
 my $uni   = '';
 while (length($str))
  {
   my $code = unpack('n',substr($str,0,2,'')) & 0xffff;
   $uni .= chr($code);
  }
 $_[1] = $str if $chk;
 utf8::upgrade($uni);
 return $uni;
}

sub encode
{
 my ($obj,$uni,$chk) = @_;
 my $str   = '';
 while (length($uni))
  {
   my $ch = substr($uni,0,1,'');
   my $x  = ord($ch);
   unless ($x < 32768)
    {
     last if ($chk);
     $x = 0;
    }
   $str .= pack('n',$x);
  }
 $_[1] = $uni if $chk;
 return $str;
}

# switch back to Encode package in case we ever add AutoLoader
package Encode;

1;

__END__

=head1 NAME

Encode - character encodings

=head1 SYNOPSIS

    use Encode;

=head1 DESCRIPTION

The C<Encode> module provides the interfaces between Perl's strings
and the rest of the system.  Perl strings are sequences of B<characters>.

The repertoire of characters that Perl can represent is at least that
defined by the Unicode Consortium. On most platforms the ordinal
values of the characters (as returned by C<ord(ch)>) is the "Unicode
codepoint" for the character (the exceptions are those platforms where
the legacy encoding is some variant of EBCDIC rather than a super-set
of ASCII - see L<perlebcdic>).

Traditionaly computer data has been moved around in 8-bit chunks
often called "bytes". These chunks are also known as "octets" in
networking standards. Perl is widely used to manipulate data of
many types - not only strings of characters representing human or
computer languages but also "binary" data being the machines representation
of numbers, pixels in an image - or just about anything.

When Perl is processing "binary data" the programmer wants Perl to process
"sequences of bytes". This is not a problem for Perl - as a byte has 256
possible values it easily fits in Perl's much larger "logical character".

=head2 TERMINOLOGY

=over 4

=item *

I<character>: a character in the range 0..(2**32-1) (or more).
(What Perl's strings are made of.)

=item *

I<byte>: a character in the range 0..255
(A special case of a Perl character.)

=item *

I<octet>: 8 bits of data, with ordinal values 0..255
(Term for bytes passed to or from a non-Perl context, e.g. disk file.)

=back

The marker [INTERNAL] marks Internal Implementation Details, in
general meant only for those who think they know what they are doing,
and such details may change in future releases.

=head1 ENCODINGS

=head2 Characteristics of an Encoding

An encoding has a "repertoire" of characters that it can represent,
and for each representable character there is at least one sequence of
octets that represents it.

=head2 Types of Encodings

Encodings can be divided into the following types:

=over 4

=item * Fixed length 8-bit (or less) encodings.

Each character is a single octet so may have a repertoire of up to
256 characters. ASCII and iso-8859-* are typical examples.

=item * Fixed length 16-bit encodings

Each character is two octets so may have a repertoire of up to
65 536 characters.  Unicode's UCS-2 is an example.  Also used for
encodings for East Asian languages.

=item * Fixed length 32-bit encodings.

Not really very "encoded" encodings. The Unicode code points
are just represented as 4-octet integers. None the less because
different architectures use different representations of integers
(so called "endian") there at least two disctinct encodings.

=item * Multi-byte encodings

The number of octets needed to represent a character varies.
UTF-8 is a particularly complex but regular case of a multi-byte
encoding. Several East Asian countries use a multi-byte encoding
where 1-octet is used to cover western roman characters and Asian
characters get 2-octets.
(UTF-16 is strictly a multi-byte encoding taking either 2 or 4 octets
to represent a Unicode code point.)

=item * "Escape" encodings.

These encodings embed "escape sequences" into the octet sequence
which describe how the following octets are to be interpreted.
The iso-2022-* family is typical. Following the escape sequence
octets are encoded by an "embedded" encoding (which will be one
of the above types) until another escape sequence switches to
a different "embedded" encoding.

These schemes are very flexible and can handle mixed languages but are
very complex to process (and have state).  No escape encodings are
implemented for Perl yet.

=back

=head2 Specifying Encodings

Encodings can be specified to the API described below in two ways:

=over 4

=item 1. By name

Encoding names are strings with characters taken from a restricted
repertoire.  See L</"Encoding Names">.

=item 2. As an object

Encoding objects are returned by C<find_encoding($name)>.

=back

=head2 Encoding Names

Encoding names are case insensitive. White space in names is ignored.
In addition an encoding may have aliases. Each encoding has one
"canonical" name.  The "canonical" name is chosen from the names of
the encoding by picking the first in the following sequence:

=over 4

=item * The MIME name as defined in IETF RFC-XXXX.

=item * The name in the IANA registry.

=item * The name used by the the organization that defined it.

=back

Because of all the alias issues, and because in the general case
encodings have state C<Encode> uses the encoding object internally
once an operation is in progress.

=head1 PERL ENCODING API

=head2 Generic Encoding Interface

=over 4

=item *

        $bytes  = encode(ENCODING, $string[, CHECK])

Encodes string from Perl's internal form into I<ENCODING> and returns
a sequence of octets.  For CHECK see L</"Handling Malformed Data">.

=item *

        $string = decode(ENCODING, $bytes[, CHECK])

Decode sequence of octets assumed to be in I<ENCODING> into Perl's
internal form and returns the resulting string.  For CHECK see
L</"Handling Malformed Data">.

=item *

	from_to($string, FROM_ENCODING, TO_ENCODING[, CHECK])

Convert B<in-place> the data between two encodings.  How did the data
in $string originally get to be in FROM_ENCODING?  Either using
encode() or through PerlIO: See L</"Encoding and IO">.  For CHECK
see L</"Handling Malformed Data">.

For example to convert ISO 8859-1 data to UTF-8:

	from_to($data, "iso-8859-1", "utf-8");

and to convert it back:

	from_to($data, "utf-8", "iso-8859-1");

Note that because the conversion happens in place, the data to be
converted cannot be a string constant, it must be a scalar variable.

=back

=head2 Handling Malformed Data

If CHECK is not set, C<undef> is returned.  If the data is supposed to
be UTF-8, an optional lexical warning (category utf8) is given.  If
CHECK is true but not a code reference, dies.

It would desirable to have a way to indicate that transform should use
the encodings "replacement character" - no such mechanism is defined yet.

It is also planned to allow I<CHECK> to be a code reference.

This is not yet implemented as there are design issues with what its
arguments should be and how it returns its results.

=over 4

=item Scheme 1

Passed remaining fragment of string being processed.
Modifies it in place to remove bytes/characters it can understand
and returns a string used to represent them.
e.g.

 sub fixup {
   my $ch = substr($_[0],0,1,'');
   return sprintf("\x{%02X}",ord($ch);
 }

This scheme is close to how underlying C code for Encode works, but gives
the fixup routine very little context.

=item Scheme 2

Passed original string, and an index into it of the problem area, and
output string so far.  Appends what it will to output string and
returns new index into original string.  For example:

 sub fixup {
   # my ($s,$i,$d) = @_;
   my $ch = substr($_[0],$_[1],1);
   $_[2] .= sprintf("\x{%02X}",ord($ch);
   return $_[1]+1;
 }

This scheme gives maximal control to the fixup routine but is more
complicated to code, and may need internals of Encode to be tweaked to
keep original string intact.

=item Other Schemes

Hybrids of above.

Multiple return values rather than in-place modifications.

Index into the string could be pos($str) allowing s/\G...//.

=back

=head2 UTF-8 / utf8

The Unicode consortium defines the UTF-8 standard as a way of encoding
the entire Unicode repertiore as sequences of octets.  This encoding is
expected to become very widespread. Perl can use this form internaly
to represent strings, so conversions to and from this form are
particularly efficient (as octets in memory do not have to change,
just the meta-data that tells Perl how to treat them).

=over 4

=item *

        $bytes = encode_utf8($string);

The characters that comprise string are encoded in Perl's superset of UTF-8
and the resulting octets returned as a sequence of bytes. All possible
characters have a UTF-8 representation so this function cannot fail.

=item *

        $string = decode_utf8($bytes [,CHECK]);

The sequence of octets represented by $bytes is decoded from UTF-8
into a sequence of logical characters. Not all sequences of octets
form valid UTF-8 encodings, so it is possible for this call to fail.
For CHECK see L</"Handling Malformed Data">.

=back

=head2 Other Encodings of Unicode

UTF-16 is similar to UCS-2, 16 bit or 2-byte chunks.  UCS-2 can only
represent 0..0xFFFF, while UTF-16 has a "surrogate pair" scheme which
allows it to cover the whole Unicode range.

Encode implements big-endian UCS-2 aliased to "iso-10646-1" as that
happens to be the name used by that representation when used with X11
fonts.

UTF-32 or UCS-4 is 32-bit or 4-byte chunks.  Perl's logical characters
can be considered as being in this form without encoding. An encoding
to transfer strings in this form (e.g. to write them to a file) would
need to

     pack('L',map(chr($_),split(//,$string)));   # native
  or
     pack('V',map(chr($_),split(//,$string)));   # little-endian
  or
     pack('N',map(chr($_),split(//,$string)));   # big-endian

depending on the endian required.

No UTF-32 encodings are implemented yet.

Both UCS-2 and UCS-4 style encodings can have "byte order marks" by
representing the code point 0xFFFE as the very first thing in a file.

=head2 Listing available encodings

  use Encode qw(encodings);
  @list = encodings();

Returns a list of the canonical names of the available encodings.

=head2 Defining Aliases

  use Encode qw(define_alias);
  define_alias( newName => ENCODING);

Allows newName to be used as am alias for ENCODING. ENCODING may be
either the name of an encoding or and encoding object (as above).

Currently I<newName> can be specified in the following ways:

=over 4

=item As a simple string.

=item As a qr// compiled regular expression, e.g.:

  define_alias( qr/^iso8859-(\d+)$/i => '"iso-8859-$1"' );

In this case if I<ENCODING> is not a reference it is C<eval>-ed to
allow C<$1> etc. to be subsituted.  The example is one way to names as
used in X11 font names to alias the MIME names for the iso-8859-*
family.

=item As a code reference, e.g.:

  define_alias( sub { return /^iso8859-(\d+)$/i ? "iso-8859-$1" : undef } , '');

In this case C<$_> will be set to the name that is being looked up and
I<ENCODING> is passed to the sub as its first argument.  The example
is another way to names as used in X11 font names to alias the MIME
names for the iso-8859-* family.

=back

=head2 Defining Encodings

    use Encode qw(define_alias);
    define_encoding( $object, 'canonicalName' [,alias...]);

Causes I<canonicalName> to be associated with I<$object>.  The object
should provide the interface described in L</"IMPLEMENTATION CLASSES">
below.  If more than two arguments are provided then additional
arguments are taken as aliases for I<$object> as for C<define_alias>.

=head1 Encoding and IO

It is very common to want to do encoding transformations when
reading or writing files, network connections, pipes etc.
If Perl is configured to use the new 'perlio' IO system then
C<Encode> provides a "layer" (See L<perliol>) which can transform
data as it is read or written.

Here is how the blind poet would modernise the encoding:

    use Encode;
    open(my $iliad,'<:encoding(iso-8859-7)','iliad.greek');
    open(my $utf8,'>:utf8','iliad.utf8');
    my @epic = <$iliad>;
    print $utf8 @epic;
    close($utf8);
    close($illiad);

In addition the new IO system can also be configured to read/write
UTF-8 encoded characters (as noted above this is efficient):

    open(my $fh,'>:utf8','anything');
    print $fh "Any \x{0021} string \N{SMILEY FACE}\n";

Either of the above forms of "layer" specifications can be made the default
for a lexical scope with the C<use open ...> pragma. See L<open>.

Once a handle is open is layers can be altered using C<binmode>.

Without any such configuration, or if Perl itself is built using
system's own IO, then write operations assume that file handle accepts
only I<bytes> and will C<die> if a character larger than 255 is
written to the handle. When reading, each octet from the handle
becomes a byte-in-a-character. Note that this default is the same
behaviour as bytes-only languages (including Perl before v5.6) would
have, and is sufficient to handle native 8-bit encodings
e.g. iso-8859-1, EBCDIC etc. and any legacy mechanisms for handling
other encodings and binary data.

In other cases it is the programs responsibility to transform
characters into bytes using the API above before doing writes, and to
transform the bytes read from a handle into characters before doing
"character operations" (e.g. C<lc>, C</\W+/>, ...).

You can also use PerlIO to convert larger amounts of data you don't
want to bring into memory.  For example to convert between ISO 8859-1
(Latin 1) and UTF-8 (or UTF-EBCDIC in EBCDIC machines):

    open(F, "<:encoding(iso-8859-1)", "data.txt") or die $!;
    open(G, ">:utf8",                 "data.utf") or die $!;
    while (<F>) { print G }

    # Could also do "print G <F>" but that would pull
    # the whole file into memory just to write it out again.

More examples:

    open(my $f, "<:encoding(cp1252)")
    open(my $g, ">:encoding(iso-8859-2)")
    open(my $h, ">:encoding(latin9)")       # iso-8859-15

See L<PerlIO> for more information.

=head1 Encoding How to ...

To do:

=over 4

=item * IO with mixed content (faking iso-2020-*)

=item * MIME's Content-Length:

=item * UTF-8 strings in binary data.

=item * Perl/Encode wrappers on non-Unicode XS modules.

=back

=head1 Messing with Perl's Internals

The following API uses parts of Perl's internals in the current
implementation.  As such they are efficient, but may change.

=over 4

=item * is_utf8(STRING [, CHECK])

[INTERNAL] Test whether the UTF-8 flag is turned on in the STRING.
If CHECK is true, also checks the data in STRING for being well-formed
UTF-8.  Returns true if successful, false otherwise.

=item * valid_utf8(STRING)

[INTERNAL] Test whether STRING is in a consistent state.  Will return
true if string is held as bytes, or is well-formed UTF-8 and has the
UTF-8 flag on.  Main reason for this routine is to allow Perl's
testsuite to check that operations have left strings in a consistent
state.

=item *

        _utf8_on(STRING)

[INTERNAL] Turn on the UTF-8 flag in STRING.  The data in STRING is
B<not> checked for being well-formed UTF-8.  Do not use unless you
B<know> that the STRING is well-formed UTF-8.  Returns the previous
state of the UTF-8 flag (so please don't test the return value as
I<not> success or failure), or C<undef> if STRING is not a string.

=item *

        _utf8_off(STRING)

[INTERNAL] Turn off the UTF-8 flag in STRING.  Do not use frivolously.
Returns the previous state of the UTF-8 flag (so please don't test the
return value as I<not> success or failure), or C<undef> if STRING is
not a string.

=back

=head1 IMPLEMENTATION CLASSES

As mentioned above encodings are (in the current implementation at least)
defined by objects. The mapping of encoding name to object is via the
C<%encodings> hash.

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

=head1 SEE ALSO

L<perlunicode>, L<perlebcdic>, L<perlfunc/open>, L<PerlIO>

=cut

