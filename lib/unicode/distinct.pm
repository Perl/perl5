package unicode::distinct;

our $VERSION = '0.01';

$unicode::distinct::hint_bits = 0x01000000;

sub import {
    $^H |= $unicode::distinct::hint_bits;
}

sub unimport {
    $^H &= ~$unicode::distinct::hint_bits;
}

1;
__END__

=head1 NAME

unicode::distinct - Perl pragma to strictly distinguish UTF8 data and non-UTF data.

=head1 SYNOPSIS

    use unicode::distinct;
    no unicode::distinct;

=head1 DESCRIPTION

 *NOT YET*

=head1 SEE ALSO

L<perlunicode>, L<utf8>

=cut
