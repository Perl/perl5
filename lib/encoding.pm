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
'use encoding' seen matters.

=head1 FUTURE POSSIBILITIES

The C<\x..> and C<\0...> in literals and regular expressions are not
affected by this pragma.  They probably should.  Ditto C<\N{...}>.

=head1 SEE ALSO

L<perlunicode>

=cut

1;
