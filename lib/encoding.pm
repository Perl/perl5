package encoding;

our $VERSION = '1.00';

use Encode;

BEGIN {
    if (ord("A") == 193) {
	require Carp;
	Carp::croak "encoding pragma does not support EBCDIC platforms";
    }
}

sub import {
    my ($class, $name) = @_;
    $name = $ENV{PERL_ENCODING} if @_ < 2;
    $name = "latin1" unless defined $name;
    my $enc = find_encoding($name);
    unless (defined $enc) {
	require Carp;
	Carp::croak "Unknown encoding '$name'";
    }
    ${^ENCODING} = $enc;
}

=pod

=head1 NAME

encoding - pragma to control the conversion of legacy data into Unicode

=head1 SYNOPSIS

    use encoding "iso 8859-7";

    # The \xDF of ISO 8859-7 (Greek) is \x{3af} in Unicode.

    $a = "\xDF";
    $b = "\x{100}";

    printf "%#x\n", ord($a); # will print 0x3af, not 0xdf

    $c = $a . $b;

    # $c will be "\x{3af}\x{100}", not "\x{df}\x{100}".

    # chr() is affected, and ...

    print "mega\n"  if ord(chr(0xdf)) == 0x3af;

    # ... ord() is affected by the encoding pragma ...

    print "tera\n" if ord(pack("C", 0xdf)) == 0x3af;

    # ... as are eq and cmp ...

    print "peta\n" if "\x{3af}" eq  pack("C", 0xdf);
    print "exa\n"  if "\x{3af}" cmp pack("C", 0xdf) == 0;

    # ... but pack/unpack C are not affected, in case you still
    # want back to your native encoding

    print "zetta\n" if unpack("C", (pack("C", 0xdf))) == 0xdf;

=head1 DESCRIPTION

Normally when legacy 8-bit data is converted to Unicode the data is
expected to be Latin-1 (or EBCDIC in EBCDIC platforms).  With the
encoding pragma you can change this default.

The pragma is a per script, not a per block lexical.  Only the last
C<use encoding> matters, and it affects B<the whole script>.

Notice that only literals (string or regular expression) having only
legacy code points are affected: if you mix data like this

	\xDF\x{100}

the data is assumed to be in (Latin 1 and) Unicode, not in your native
encoding.  In other words, this will match in "greek":

	"\xDF" =~ /\x{3af}/

but this will not

	"\xDF\x{100}" =~ /\x{3af}\x{100}/

since the C<\xDF> on the left will B<not> be upgraded to C<\x{3af}>
because of the C<\x{100}> on the left.  You should not be mixing your
legacy data and Unicode in the same string.

This pragma also affects encoding of the 0x80..0xFF code point range:
normally characters in that range are left as eight-bit bytes (unless
they are combined with characters with code points 0x100 or larger,
in which case all characters need to become UTF-8 encoded), but if
the C<encoding> pragma is present, even the 0x80..0xFF range always
gets UTF-8 encoded.

If no encoding is specified, the environment variable L<PERL_ENCODING>
is consulted.  If that fails, "latin1" (ISO 8859-1) is assumed.  If no
encoding can be found, C<Unknown encoding '...'> error will be thrown.

=head1 KNOWN PROBLEMS

For native multibyte encodings (either fixed or variable length)
the current implementation of the regular expressions may introduce
recoding errors for longer regular expression literals than 127 bytes.

The encoding pragma is not supported on EBCDIC platforms.

=head1 SEE ALSO

L<perlunicode>, L<Encode>

=cut

1;
