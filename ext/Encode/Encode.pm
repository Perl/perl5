package Encode;
use strict;
our $VERSION = do { my @r = (q$Revision: 0.97 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG = 0;

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

use Encode::Alias;

# Make a %Encoding package variable to allow a certain amount of cheating
our %Encoding;

our %ExtModule =
    (
     viscii             => 'Encode/Byte.pm',
     'koi8-r'           => 'Encode/Byte.pm',
     cp1047             => 'Encode/EBCDIC.pm',
     cp37               => 'Encode/EBCDIC.pm',
     'posix-bc'         => 'Encode/EBCDIC.pm',
     symbol             => 'Encode/Symbol.pm',
     dingbats           => 'Encode/Symbol.pm',
     'euc-cn'           => 'Encode/CN.pm',
     gb2312		=> 'Encode/CN.pm',
     gb12345		=> 'Encode/CN.pm',
     gbk		=> 'Encode/CN.pm',
     cp936		=> 'Encode/CN.pm',
     'iso-ir-165'	=> 'Encode/CN.pm',
     'euc-jp'	        => 'Encode/JP.pm',
     'iso-2022-jp'	=> 'Encode/JP.pm',
     '7bit-jis'         => 'Encode/JP.pm',
     shiftjis	        => 'Encode/JP.pm',
     macjapan	        => 'Encode/JP.pm',
     cp932		=> 'Encode/JP.pm',
     'euc-kr'       	=> 'Encode/KR.pm',
     ksc5601		=> 'Encode/KR.pm',
     cp949		=> 'Encode/KR.pm',
     big5		=> 'Encode/TW.pm',
     'big5-hkscs'	=> 'Encode/TW.pm',
     cp950		=> 'Encode/TW.pm',
     gb18030		=> 'Encode/HanExtra.pm',
     big5plus     	=> 'Encode/HanExtra.pm',
     'euc-tw'   	=> 'Encode/HanExtra.pm',
    );

for my $k (2..11,13..16){
    $ExtModule{"iso-8859-$k"} = 'Encode/Byte.pm';
}

for my $k (1250..1258){
    $ExtModule{"cp$k"} = 'Encode/Byte.pm';
}

for my $k (qw(centeuro croatian cyrillic dingbats greek
	      iceland roman rumanian sami 
	      thai turkish  ukraine))
{
    $ExtModule{"mac$k"} = 'Encode/Byte.pm';
}


sub encodings
{
    my $class = shift;
    my @modules = (@_ and $_[0] eq ":all") ? values %ExtModule : @_;
    for my $m (@modules)
    {
	$DEBUG and warn "about to require $m;";
	eval { require $m; };
    }
    return
	map({$_->[0]} 
	    sort({$a->[1] cmp $b->[1]}
		 map({[$_, lc $_]} 
		     grep({ $_ ne 'Internal' }  keys %Encoding))));
}

sub define_encoding
{
    my $obj  = shift;
    my $name = shift;
    $Encoding{$name} = $obj;
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
    my ($class,$name,$skip_external) = @_;
    my $enc;
    if (ref($name) && $name->can('new_sequence'))
    {
	return $name;
    }
    my $lc = lc $name;
    if (exists $Encoding{$name})
    {
	return $Encoding{$name};
    }
    if (exists $Encoding{$lc})
    {
	return $Encoding{$lc};
    }

    my $oc = $class->find_alias($name);
    return $oc if defined $oc;

    $oc = $class->find_alias($lc) if $lc ne $name;
    return $oc if defined $oc;

    if (!$skip_external and exists $ExtModule{$lc})
    {
	eval{ require $ExtModule{$lc}; };
	return $Encoding{$name} if exists $Encoding{$name};
    }

    return;
}

sub find_encoding
{
    my ($name,$skip_external) = @_;
    return __PACKAGE__->getEncoding($name,$skip_external);
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
    $_[1] = $octets if $check;
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

require Encode::Encoding;
require Encode::XS;
require Encode::Internal;
require Encode::Unicode;
require Encode::utf8;
require Encode::iso10646_1;
require Encode::ucs2_le;

1;

__END__

=head1 NAME

Encode - character encodings

=head1 SYNOPSIS

    use Encode;

=head1 DESCRIPTION

The C<Encode> module provides the interfaces between Perl's strings
and the rest of the system.  Perl strings are sequences of B<characters>.

To find more about character encodings, please consult
L<Encode::Details> . This document focuses on programming references.

=head1 PERL ENCODING API

=head2 Generic Encoding Interface

=over 4

=item *

        $bytes  = encode(ENCODING, $string[, CHECK])

Encodes string from Perl's internal form into I<ENCODING> and returns
a sequence of octets.  For CHECK see L</"Handling Malformed Data">.

For example to convert (internally UTF-8 encoded) Unicode data
to octets:

	$octets = encode("utf8", $unicode);

=item *

        $string = decode(ENCODING, $bytes[, CHECK])

Decode sequence of octets assumed to be in I<ENCODING> into Perl's
internal form and returns the resulting string.  For CHECK see
L</"Handling Malformed Data">.

For example to convert ISO-8859-1 data to UTF-8:

	$utf8 = decode("latin1", $latin1);

=item *

	from_to($string, FROM_ENCODING, TO_ENCODING[, CHECK])

Convert B<in-place> the data between two encodings.  How did the data
in $string originally get to be in FROM_ENCODING?  Either using
encode() or through PerlIO: See L</"Encoding and IO">.  For CHECK
see L</"Handling Malformed Data">.

For example to convert ISO-8859-1 data to UTF-8:

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

=head2 Listing available encodings

  use Encode;
  @list = Encode->encodings();

Returns a list of the canonical names of the available encodings that
are loaded.  To get a list of all available encodings including the
ones that are not loaded yet, say

  @all_encodings = Encode->encodings(":all");

Or you can give the name of specific module.

  @with_jp = Encode->encodings("Encode/JP.pm");

Note in this case you have to say "Encode/JP.pm instead of Encode::JP.

To find which encodings are suppoted by this package in details, 
see L<Encode::Supported>.

=head2 Defining Aliases

  use Encode;
  use Encode::Alias;
  define_alias( newName => ENCODING);

Allows newName to be used as am alias for ENCODING. ENCODING may be
either the name of an encoding or and encoding object (as above).

See L<Encode::Alias> on details.

=head1 Defining Encodings

    use Encode qw(define_alias);
    define_encoding( $object, 'canonicalName' [,alias...]);

Causes I<canonicalName> to be associated with I<$object>.  The object
should provide the interface described in L<Encode::Encoding>
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
want to bring into memory.  For example to convert between ISO-8859-1
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

See also L<encoding> for how to change the default encoding of the
data in your script.

=head1 Messing with Perl's Internals

The following API uses parts of Perl's internals in the current
implementation.  As such they are efficient, but may change.

=over 4

=item * is_utf8(STRING [, CHECK])

[INTERNAL] Test whether the UTF-8 flag is turned on in the STRING.
If CHECK is true, also checks the data in STRING for being well-formed
UTF-8.  Returns true if successful, false otherwise.

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

=head1 SEE ALSO

L<Encode::Details>, 
L<Encode::Encoding>,
L<Encode::Supported>,
L<PerlIO>, 
L<encoding>,
L<perlebcdic>, 
L<perlfunc/open>, 
L<perlunicode>, 
L<utf8>, 
the Perl Unicode Mailing List E<lt>perl-unicode@perl.orgE<gt>

=cut
