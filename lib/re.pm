package re;

=head1 NAME

re - Perl pragma to alter regular expression behaviour

=head1 SYNOPSIS

    use re 'taint';
    ($x) = ($^X =~ /^(.*)$/s);     # $x is tainted here

    use re 'eval';
    /foo(?{ $foo = 1 })bar/;	   # won't fail (when not under -T switch)

    {
	no re 'taint';		   # the default
	($x) = ($^X =~ /^(.*)$/s); # $x is not tainted here

	no re 'eval';		   # the default
	/foo(?{ $foo = 1 })bar/;   # disallowed (with or without -T switch)
    }

=head1 DESCRIPTION

When C<use re 'taint'> is in effect, and a tainted string is the target
of a regex, the regex memories (or values returned by the m// operator
in list context) are tainted.  This feature is useful when regex operations
on tainted data aren't meant to extract safe substrings, but to perform
other transformations.

When C<use re 'eval'> is in effect, a regex is allowed to contain
C<(?{ ... })> zero-width assertions (which may not be interpolated in
the regex).  That is normally disallowed, since it is a potential security
risk.  Note that this pragma is ignored when perl detects tainted data,
i.e.  evaluation is always disallowed with tainted data.  See
L<perlre/(?{ code })>.

See L<perlmodlib/Pragmatic Modules>.

=cut

my %bitmask = (
taint	=> 0x00100000,
eval	=> 0x00200000,
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
