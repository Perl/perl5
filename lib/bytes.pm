package bytes;

sub import {
    $^H |= 0x00000008;
}

sub unimport {
    $^H &= ~0x00000008;
}

sub AUTOLOAD {
    require "bytes_heavy.pl";
    goto &$AUTOLOAD;
}

sub length ($);

1;
__END__

=head1 NAME

bytes - Perl pragma to force byte semantics rather than character semantics

=head1 SYNOPSIS

    use bytes;
    no bytes;

=head1 DESCRIPTION

WARNING: The implementation of Unicode support in Perl is incomplete.
Expect sudden and unannounced changes!

The C<use bytes> pragma disables character semantics for the rest of the
lexical scope in which it appears.  C<no bytes> can be used to reverse
the effect of C<use bytes> within the current lexical scope.

Perl normally assumes character semantics in the presence of
character data (i.e. data that has come from a source that has
been marked as being of a particular character encoding).

To understand the implications and differences between character
semantics and byte semantics, see L<perlunicode>.

=head1 SEE ALSO

L<perlunicode>, L<utf8>

=cut
