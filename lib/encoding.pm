package encoding;

use Encode;

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

    # but pack/unpack C are not, in case you still
    # want back to your native encoding

    print "peta\n" if unpack("C", (pack("C", 0xdf))) == 0xdf;

=head1 DESCRIPTION

Normally when legacy 8-bit data is converted to Unicode the data is
expected to be Latin-1 (or EBCDIC in EBCDIC platforms).  With the
encoding pragma you can change this default.

The pragma is a per script, not a per block lexical.  Only the last
C<use encoding> matters, and it affects B<the whole script>.

If no encoding is specified, the environment variable L<PERL_ENCODING>
is consulted.  If that fails, "latin1" (ISO 8859-1) is assumed.
If no encoding can be found, C<Unknown encoding '...'> error will be thrown.

=head1 FUTURE POSSIBILITIES

The C<\x..> and C<\0...> in regular expressions are not affected by
this pragma.  They probably should.

The charnames "\N{...}" does not work with this pragma.

=head1 KNOWN PROBLEMS

Cannot be combined with C<use utf8>.  Note that this is a problem
B<only> if you would like to have Unicode identifiers in your scripts.
You should not need C<use utf8> for anything else these days
(since Perl 5.8.0).

=head1 SEE ALSO

L<perlunicode>, L<Encode>

=cut

1;
