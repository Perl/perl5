package Encode;
use strict;
our $VERSION = do { my @r = (q$Revision: 1.57 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG = 0;
use XSLoader ();
XSLoader::load 'Encode';

require Exporter;
our @ISA = qw(Exporter);

# Public, encouraged API is exported by default

our @EXPORT = qw(
  decode  decode_utf8  encode  encode_utf8
  encodings  find_encoding
);

our @FB_FLAGS  = qw(DIE_ON_ERR WARN_ON_ERR RETURN_ON_ERR LEAVE_SRC PERLQQ);
our @FB_CONSTS = qw(FB_DEFAULT FB_QUIET FB_WARN FB_PERLQQ FB_CROAK);

our @EXPORT_OK =
    (
     qw(
       _utf8_off _utf8_on define_encoding from_to is_16bit is_8bit
       is_utf8 perlio_ok resolve_alias utf8_downgrade utf8_upgrade
      ),
     @FB_FLAGS, @FB_CONSTS,
    );

our %EXPORT_TAGS =
    (
     all          =>  [ @EXPORT, @EXPORT_OK ],
     fallbacks    =>  [ @FB_CONSTS ],
     fallback_all =>  [ @FB_CONSTS, @FB_FLAGS ],
    );

# Documentation moved after __END__ for speed - NI-S

use Carp;

our $ON_EBCDIC = (ord("A") == 193);

use Encode::Alias;

# Make a %Encoding package variable to allow a certain amount of cheating
our %Encoding;
our %ExtModule;
require Encode::Config;
eval { require Encode::ConfigLocal };

sub encodings
{
    my $class = shift;
    my @modules = (@_ and $_[0] eq ":all") ? values %ExtModule : @_;
    for my $mod (@modules){
	$mod =~ s,::,/,g or $mod = "Encode/$mod";
	$mod .= '.pm';
	$DEBUG and warn "about to require $mod;";
	eval { require $mod; };
    }
    my %modules = map {$_ => 1} @modules;
    return
	sort { lc $a cmp lc $b }
             grep {!/^(?:Internal|Unicode)$/o} keys %Encoding;
}

sub perlio_ok{
    my $obj = ref($_[0]) ? $_[0] : find_encoding($_[0]);
    $obj->can("perlio_ok") and return $obj->perlio_ok();
    return 0; # safety net
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

    unless ($skip_external)
    {
	if (my $mod = $ExtModule{$name} || $ExtModule{$lc}){
	    $mod =~ s,::,/,g ; $mod .= '.pm';
	    eval{ require $mod; };
	    return $Encoding{$name} if exists $Encoding{$name};
	}
    }
    return;
}

sub find_encoding
{
    my ($name,$skip_external) = @_;
    return __PACKAGE__->getEncoding($name,$skip_external);
}

sub resolve_alias {
    my $obj = find_encoding(shift);
    defined $obj and return $obj->name;
    return;
}

sub encode($$;$)
{
    my ($name,$string,$check) = @_;
    $check ||=0;
    my $enc = find_encoding($name);
    croak("Unknown encoding '$name'") unless defined $enc;
    my $octets = $enc->encode($string,$check);
    return undef if ($check && length($string));
    return $octets;
}

sub decode($$;$)
{
    my ($name,$octets,$check) = @_;
    $check ||=0;
    my $enc = find_encoding($name);
    croak("Unknown encoding '$name'") unless defined $enc;
    my $string = $enc->decode($octets,$check);
    $_[1] = $octets if $check;
    return $string;
}

sub from_to($$$;$)
{
    my ($string,$from,$to,$check) = @_;
    $check ||=0;
    my $f = find_encoding($from);
    croak("Unknown encoding '$from'") unless defined $f;
    my $t = find_encoding($to);
    croak("Unknown encoding '$to'") unless defined $t;
    my $uni = $f->decode($string,$check);
    return undef if ($check && length($string));
    $string =  $t->encode($uni,$check);
    return undef if ($check && length($uni));
    return defined($_[0] = $string) ? length($string) : undef ;
}

sub encode_utf8($)
{
    my ($str) = @_;
    utf8::encode($str);
    return $str;
}

sub decode_utf8($)
{
    my ($str) = @_;
    return undef unless utf8::decode($str);
    return $str;
}

predefine_encodings();

#
# This is to restore %Encoding if really needed;
#
sub predefine_encodings{
    if ($ON_EBCDIC) {
	# was in Encode::UTF_EBCDIC
	package Encode::UTF_EBCDIC;
	*name         = sub{ shift->{'Name'} };
	*new_sequence = sub{ return $_[0] };
	*decode = sub{
	    my ($obj,$str,$chk) = @_;
	    my $res = '';
	    for (my $i = 0; $i < length($str); $i++) {
		$res .=
		    chr(utf8::unicode_to_native(ord(substr($str,$i,1))));
	    }
	    $_[1] = '' if $chk;
	    return $res;
	};
	*encode = sub{
	    my ($obj,$str,$chk) = @_;
	    my $res = '';
	    for (my $i = 0; $i < length($str); $i++) {
		$res .=
		    chr(utf8::native_to_unicode(ord(substr($str,$i,1))));
	    }
	    $_[1] = '' if $chk;
	    return $res;
	};
	$Encode::Encoding{Unicode} =
	    bless {Name => "UTF_EBCDIC"} => "Encode::UTF_EBCDIC";
    } else {
	# was in Encode::UTF_EBCDIC
	package Encode::Internal;
	*name         = sub{ shift->{'Name'} };
	*new_sequence = sub{ return $_[0] };
	*decode = sub{
	    my ($obj,$str,$chk) = @_;
	    utf8::upgrade($str);
	    $_[1] = '' if $chk;
	    return $str;
	};
	*encode = \&decode;
	$Encode::Encoding{Unicode} =
	    bless {Name => "Internal"} => "Encode::Internal";
    }

    {
	# was in Encode::utf8
	package Encode::utf8;
	*name         = sub{ shift->{'Name'} };
	*new_sequence = sub{ return $_[0] };
	*decode = sub{
	    my ($obj,$octets,$chk) = @_;
	    my $str = Encode::decode_utf8($octets);
	    if (defined $str) {
		$_[1] = '' if $chk;
		return $str;
	    }
	    return undef;
	};
	*encode = sub {
	    my ($obj,$string,$chk) = @_;
	    my $octets = Encode::encode_utf8($string);
	    $_[1] = '' if $chk;
	    return $octets;
	};
	$Encode::Encoding{utf8} = 
	    bless {Name => "utf8"} => "Encode::utf8";
    }
}

1;

__END__

=head1 NAME

Encode - character encodings

=head1 SYNOPSIS

    use Encode;

=head2 Table of Contents

Encode consists of a collection of modules whose details are too big
to fit in one document.  This POD itself explains the top-level APIs
and general topics at a glance.  For other topics and more details,
see the PODs below:

  Name			        Description
  --------------------------------------------------------
  Encode::Alias         Alias definitions to encodings
  Encode::Encoding      Encode Implementation Base Class
  Encode::Supported     List of Supported Encodings
  Encode::CN            Simplified Chinese Encodings
  Encode::JP            Japanese Encodings
  Encode::KR            Korean Encodings
  Encode::TW            Traditional Chinese Encodings
  --------------------------------------------------------

=head1 DESCRIPTION

The C<Encode> module provides the interfaces between Perl's strings
and the rest of the system.  Perl strings are sequences of
B<characters>.

The repertoire of characters that Perl can represent is at least that
defined by the Unicode Consortium. On most platforms the ordinal
values of the characters (as returned by C<ord(ch)>) is the "Unicode
codepoint" for the character (the exceptions are those platforms where
the legacy encoding is some variant of EBCDIC rather than a super-set
of ASCII - see L<perlebcdic>).

Traditionally, computer data has been moved around in 8-bit chunks
often called "bytes". These chunks are also known as "octets" in
networking standards. Perl is widely used to manipulate data of many
types - not only strings of characters representing human or computer
languages but also "binary" data being the machine's representation of
numbers, pixels in an image - or just about anything.

When Perl is processing "binary data", the programmer wants Perl to
process "sequences of bytes". This is not a problem for Perl - as a
byte has 256 possible values, it easily fits in Perl's much larger
"logical character".

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
(Term for bytes passed to or from a non-Perl context, e.g. a disk file.)

=back

The marker [INTERNAL] marks Internal Implementation Details, in
general meant only for those who think they know what they are doing,
and such details may change in future releases.

=head1 PERL ENCODING API

=over 4

=item $octets  = encode(ENCODING, $string[, CHECK])

Encodes a string from Perl's internal form into I<ENCODING> and returns
a sequence of octets.  ENCODING can be either a canonical name or
an alias.  For encoding names and aliases, see L</"Defining Aliases">.
For CHECK, see L</"Handling Malformed Data">.

For example, to convert (internally UTF-8 encoded) Unicode string to
iso-8859-1 (also known as Latin1),

  $octets = encode("iso-8859-1", $unicode);

=item $string = decode(ENCODING, $octets[, CHECK])

Decodes a sequence of octets assumed to be in I<ENCODING> into Perl's
internal form and returns the resulting string.  As in encode(),
ENCODING can be either a canonical name or an alias. For encoding names
and aliases, see L</"Defining Aliases">.  For CHECK, see
L</"Handling Malformed Data">.

For example, to convert ISO-8859-1 data to UTF-8:

  $utf8 = decode("iso-8859-1", $latin1);

=item [$length =] from_to($string, FROM_ENCODING, TO_ENCODING [,CHECK])

Converts B<in-place> data between two encodings.
For example, to convert ISO-8859-1 data to UTF-8:

	from_to($data, "iso-8859-1", "utf-8");

and to convert it back:

	from_to($data, "utf-8", "iso-8859-1");

Note that because the conversion happens in place, the data to be
converted cannot be a string constant; it must be a scalar variable.

from_to() returns the length of the converted string on success, undef
otherwise.

=back

=head2 UTF-8 / utf8

The Unicode Consortium defines the UTF-8 transformation format as a
way of encoding the entire Unicode repertoire as sequences of octets.
This encoding is expected to become very widespread. Perl can use this
form internally to represent strings, so conversions to and from this
form are particularly efficient (as octets in memory do not have to
change, just the meta-data that tells Perl how to treat them).

=over 4

=item $octets = encode_utf8($string);

The characters that comprise $string are encoded in Perl's superset of
UTF-8 and the resulting octets are returned as a sequence of bytes. All
possible characters have a UTF-8 representation so this function cannot
fail.

=item $string = decode_utf8($octets [, CHECK]);

The sequence of octets represented by $octets is decoded from UTF-8
into a sequence of logical characters. Not all sequences of octets
form valid UTF-8 encodings, so it is possible for this call to fail.
For CHECK, see L</"Handling Malformed Data">.

=back

=head2 Listing available encodings

  use Encode;
  @list = Encode->encodings();

Returns a list of the canonical names of the available encodings that
are loaded.  To get a list of all available encodings including the
ones that are not loaded yet, say

  @all_encodings = Encode->encodings(":all");

Or you can give the name of a specific module.

  @with_jp = Encode->encodings("Encode::JP");

When "::" is not in the name, "Encode::" is assumed.

  @ebcdic = Encode->encodings("EBCDIC");

To find out in detail which encodings are supported by this package,
see L<Encode::Supported>.

=head2 Defining Aliases

To add a new alias to a given encoding, use:

  use Encode;
  use Encode::Alias;
  define_alias(newName => ENCODING);

After that, newName can be used as an alias for ENCODING.
ENCODING may be either the name of an encoding or an
I<encoding object>

But before you do so, make sure the alias is nonexistent with
C<resolve_alias()>, which returns the canonical name thereof.
i.e.

  Encode::resolve_alias("latin1") eq "iso-8859-1" # true
  Encode::resolve_alias("iso-8859-12")   # false; nonexistent
  Encode::resolve_alias($name) eq $name  # true if $name is canonical

resolve_alias() does not need C<use Encode::Alias>; it can be
exported via C<use Encode qw(resolve_alias)>.

See L<Encode::Alias> for details.

=head1 Encoding via PerlIO

If your perl supports I<PerlIO>, you can use a PerlIO layer to decode
and encode directly via a filehandle.  The following two examples
are totally identical in their functionality.

  # via PerlIO
  open my $in,  "<:encoding(shiftjis)", $infile  or die;
  open my $out, ">:encoding(euc-jp)",   $outfile or die;
  while(<>){ print; }

  # via from_to
  open my $in,  "<", $infile  or die;
  open my $out, ">", $outfile or die;
  while(<>){
    from_to($_, "shiftjis", "euc-jp", 1);
  }

Unfortunately, there may be encodings are PerlIO-savvy.  You can check
if your encoding is supported by PerlIO by calling the C<perlio_ok>
method.

  Encode::perlio_ok("hz");             # False
  find_encoding("euc-cn")->perlio_ok;  # True where PerlIO is available

  use Encode qw(perlio_ok);            # exported upon request
  perlio_ok("euc-jp")

Fortunately, all encodings that come with Encode core are PerlIO-savvy
except for hz and ISO-2022-kr.  See L<Encode::Encoding> for details.

For gory details, see L<Encode::PerlIO>.

=head1 Handling Malformed Data

=over 4

The I<CHECK> argument is used as follows.  When you omit it,
the behaviour is the same as if you had passed a value of 0 for
I<CHECK>.

=item I<CHECK> = Encode::FB_DEFAULT ( == 0)

If I<CHECK> is 0, (en|de)code will put a I<substitution character>
in place of a malformed character.  For UCM-based encodings,
E<lt>subcharE<gt> will be used.  For Unicode, "\x{FFFD}" is used.
If the data is supposed to be UTF-8, an optional lexical warning
(category utf8) is given.

=item I<CHECK> = Encode::DIE_ON_ERROR (== 1)

If I<CHECK> is 1, methods will die immediately with an error
message.  Therefore, when I<CHECK> is set to 1,  you should trap the
fatal error with eval{} unless you really want to let it die on error.

=item I<CHECK> = Encode::FB_QUIET

If I<CHECK> is set to Encode::FB_QUIET, (en|de)code will immediately
return the portion of the data that has been processed so far when
an error occurs. The data argument will be overwritten with
everything after that point (that is, the unprocessed part of data).
This is handy when you have to call decode repeatedly in the case
where your source data may contain partial multi-byte character
sequences, for example because you are reading with a fixed-width
buffer. Here is some sample code that does exactly this:

  my $data = '';
  while(defined(read $fh, $buffer, 256)){
    # buffer may end in a partial character so we append
    $data .= $buffer;
    $utf8 .= decode($encoding, $data, ENCODE::FB_QUIET);
    # $data now contains the unprocessed partial character
  }

=item I<CHECK> = Encode::FB_WARN

This is the same as above, except that it warns on error.  Handy when
you are debugging the mode above.

=item perlqq mode (I<CHECK> = Encode::FB_PERLQQ)

For encodings that are implemented by Encode::XS, CHECK ==
Encode::FB_PERLQQ turns (en|de)code into C<perlqq> fallback mode.

When you decode, '\xI<XX>' will be inserted for a malformed character,
where I<XX> is the hex representation of the octet  that could not be
decoded to utf8.  And when you encode, '\x{I<xxxx>}' will be inserted,
where I<xxxx> is the Unicode ID of the character that cannot be found
in the character repertoire of the encoding.

=item The bitmask

These modes are actually set via a bitmask.  Here is how the FB_XX
constants are laid out.  You can import the FB_XX constants via
C<use Encode qw(:fallbacks)>; you can import the generic bitmask
constants via C<use Encode qw(:fallback_all)>.

                     FB_DEFAULT FB_CROAK FB_QUIET FB_WARN  FB_PERLQQ
 DIE_ON_ERR    0x0001             X
 WARN_ON_ER    0x0002                               X
 RETURN_ON_ERR 0x0004                      X        X
 LEAVE_SRC     0x0008
 PERLQQ        0x0100                                        X

=head2 Unimplemented fallback schemes

In the future, you will be able to use a code reference to a callback
function for the value of I<CHECK> but its API is still undecided.

=head1 Defining Encodings

To define a new encoding, use:

    use Encode qw(define_alias);
    define_encoding($object, 'canonicalName' [, alias...]);

I<canonicalName> will be associated with I<$object>.  The object
should provide the interface described in L<Encode::Encoding>.
If more than two arguments are provided then additional
arguments are taken as aliases for I<$object>, as for C<define_alias>.

See L<Encode::Encoding> for more details.

=head1 Messing with Perl's Internals

The following API uses parts of Perl's internals in the current
implementation.  As such, they are efficient but may change.

=over 4

=item is_utf8(STRING [, CHECK])

[INTERNAL] Tests whether the UTF-8 flag is turned on in the STRING.
If CHECK is true, also checks the data in STRING for being well-formed
UTF-8.  Returns true if successful, false otherwise.

=item _utf8_on(STRING)

[INTERNAL] Turns on the UTF-8 flag in STRING.  The data in STRING is
B<not> checked for being well-formed UTF-8.  Do not use unless you
B<know> that the STRING is well-formed UTF-8.  Returns the previous
state of the UTF-8 flag (so please don't treat the return value as
indicating success or failure), or C<undef> if STRING is not a string.

=item _utf8_off(STRING)

[INTERNAL] Turns off the UTF-8 flag in STRING.  Do not use frivolously.
Returns the previous state of the UTF-8 flag (so please don't treat the
return value as indicating success or failure), or C<undef> if STRING is
not a string.

=back

=head1 SEE ALSO

L<Encode::Encoding>,
L<Encode::Supported>,
L<Encode::PerlIO>,
L<encoding>,
L<perlebcdic>,
L<perlfunc/open>,
L<perlunicode>,
L<utf8>,
the Perl Unicode Mailing List E<lt>perl-unicode@perl.orgE<gt>

=head1 MAINTAINER

This project was originated by Nick Ing-Simmons and later maintained
by Dan Kogai E<lt>dankogai@dan.co.jpE<gt>.  See AUTHORS for a full list
of people involved.  For any questions, use
E<lt>perl-unicode@perl.orgE<gt> so others can share.

=cut
