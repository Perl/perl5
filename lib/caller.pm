package caller;
use vars qw($VERSION);
$VERSION = "1.0";

=head1 NAME

caller - inherit pragmatic attributes from the context of the caller

=head1 SYNOPSIS

        use caller qw(encoding);

=head1 DESCRIPTION

This pragma allows a module to inherit some attributes from the
context which loaded it.

Inheriting attributes takes place at compile time; this means
only attributes that are visible in the calling context at compile
time will be propagated.

Currently, the only supported attribute is C<encoding>.

=over

=item encoding

Indicates that the character set encoding of the caller's context
must be inherited.  This can be used to inherit the C<use utf8>
setting in the calling context.

=back

=cut

my %bitmask = (
    # only HINT_UTF8 supported for now
    encoding => 0x8
);

sub bits {
    my $bits = 0;
    for my $s (@_) { $bits |= $bitmask{$s} || 0; };
    $bits;
}

sub import {
    shift;
    my @cxt = caller(3);
    if (@cxt and $cxt[7]) {	# was our parent require-d?
	$^H |= bits(@_) & $cxt[8];
    }
}

sub unimport {
    # noop currently
}

1;
