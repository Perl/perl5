package re;

=head1 NAME

re - Perl pragma to alter regular expression behaviour

=head1 SYNOPSIS

    ($x) = ($^X =~ /^(.*)$/s);     # $x is not tainted here

    use re "taint";
    ($x) = ($^X =~ /^(.*)$/s);     # $x _is_ tainted here

=head1 DESCRIPTION

When C<use re 'taint'> is in effect, and a tainted string is the target
of a regex, the regex memories (or values returned by the m// operator
in list context) are tainted.

This feature is useful when regex operations on tainted data aren't
meant to extract safe substrings, but to perform other transformations.

See L<perlmodlib/Pragmatic Modules>.

=cut

my %bitmask = (
taint => 0x00100000
);

sub bits {
    my $bits = 0;
    unless(@_) {
	require Carp;
	Carp::carp("Useless use of \"re\" pragma");
    }
    foreach my $s (@_){ $bits |= $bitmask{$s} || 0; };
    $bits;
}

sub import {
    shift;
    $^H |= bits(@_);
}

sub unimport {
    shift;
    $^H &= ~ bits(@_);
}

1;
