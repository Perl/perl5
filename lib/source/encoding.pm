package source::encoding;

use strict;
use warnings;

our $VERSION = '0.01';

our $ascii_hint_bits = 0x40000000;

sub import {
    my (undef, $arg) = @_;
    require utf8;
    if (lc $arg eq 'utf8') {
        utf8->import;
        return;
    }
    elsif (lc $arg eq 'ascii') {
        utf8->unimport;
        $^H |= $source::encoding::ascii_hint_bits;
        return;
    }

    die "Bad argument for source::encoding: $arg";
}

sub unimport {
    # If we don't guard against it, somebody will write:
    #
    #   use source::encoding 'utf8';
    #   no source::encoding 'ascii';
    #
    # ...and then complain.
    die q{No arguments permitted to "no source::encoding"} if @_ > 1;

    require utf8;
    utf8->unimport;
    $^H &= ~$source::encoding::ascii_hint_bits;
}

1;
__END__

=head1 NAME

source::encoding -- Declare Perl script's encoding

=head1 SYNOPSIS

 use source::encoding 'ascii';
 use source::encoding 'utf8';
 no source::encoding;

=head1 DESCRIPTION

These days, Perl scripts either generally contain only ASCII characters with
C<\x{}> and similar escapes to represent non-ASCII, or they use C<S<use utf8>>
to indicate that the script itself contains characters encoded as UTF-8.

That means that a character in the script not meeting these criteria is often
a typographical error.  This pragma is used to tell Perl to raise an error
when this happens.

S<C<use source::encoding 'utf8'>> is a synonym for S<C<use utf8>>.  They may
be used interchangeably.

S<C<use source::encoding 'ascii'>> turns off any UTF-8 expectations, and
raises a fatal error if any character within its scope in the input script is
not ASCII (or ASCII-equivalent on EBCDIC systems).

S<C<no source::encoding>> turns off any UTF-8/ASCII expectations for the
remainder of its scope, effectively also doing a S<C<no utf8>>.

Instances of this pragma should be the last thing on a source line.

=head1 SEE ALSO

L<utf8>

=cut
