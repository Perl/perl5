package encoding;

use Encode;

sub import {
    my ($class, $name) = @_;
    $name = $ENV{PERL_ENCODING} if @_ < 2;
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

    $a = "\xDF";
    $b = "\x{100}";

    $c = $a . $b;

    # $c will be "\x{3af}\x{100}", not "\x{df}\x{100}".
    # The \xDF of ISO 8859-7 is \x{3af} in Unicode.

=head1 DESCRIPTION

Normally when legacy 8-bit data is converted to Unicode the data is
expected to be Latin-1 (or EBCDIC in EBCDIC platforms).  With the
encoding pragma you can change this default.

The pragma is a per script, not a per block lexical.  Only the last
C<use encoding> matters, and it affects B<the whole script>.

=head1 FUTURE POSSIBILITIES

The C<\x..> and C<\0...> in regular expressions are not
affected by this pragma.  They probably should.

Also chr(), ord(), and C<\N{...}> might become affected.

=head1 SEE ALSO

L<perlunicode>

=cut

1;
