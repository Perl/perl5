package RNG::PCG;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RNG', $VERSION);

sub rand01_callback {
    my ($self) = @_;
    return sub { $self->rand01 };
}

1;

=head1 NAME

RNG::PCG - a small two-dimensional PCG-XSH-RR pseudorandom number generator

=head1 SYNOPSIS

    use RNG::PCG;

    my $rng = RNG::PCG->new(42);
    my $number = $rng->rand(10);

    {
        local ${^RNG} = $rng;
        print rand(10), "\n";
    }

=head1 DESCRIPTION

This module implements Melissa O'Neill's two-dimensional PCG-XSH-RR
generator. It uses a 64-bit base state and a two-element 32-bit extension
array, avoiding any dependency on native 128-bit arithmetic. It is small,
deterministic, and suitable for simulation, testing, and other uses where a
non-cryptographic pseudorandom number generator is appropriate.

The object stores its 128-bit state in a blessed scalar reference. Its
C<rand_bytes> method combines successive 32-bit PCG outputs into a canonical
big-endian byte string, so the provider interface is independent of Perl's
native integer width. The object can be used directly as a provider for
Perl's C<${^RNG}> variable.

This generator is not suitable for cryptography, security tokens, passwords,
or any other security-sensitive use.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.

=head2 new( SEED )

Create a generator initialized from SEED. Numeric seeds are encoded as
fixed-width integers; byte strings are hashed as bytes and wide strings are
encoded as UTF-8 before hashing. If SEED is omitted, zero is used.

=head2 rand( [LIMIT] )

Return a pseudorandom floating-point value in the same form as Perl's
built-in C<rand>: between zero and one when LIMIT is omitted, or between zero
and LIMIT when it is supplied. A LIMIT of zero is treated as one.

=head2 rand01

Advance the generator and return a pseudorandom floating-point value between
zero and one.

=head2 rand01_callback

Return a callback which calls C<rand01> on this generator. The callback can
be assigned to C<$List::Util::RAND> to reproduce the same sequence as using
the generator through C<${^RNG}>.

=head2 rand_bytes( LENGTH )

Advance the generator and return exactly LENGTH random bytes. Bytes are
assembled from successive 32-bit PCG outputs in big-endian order. LENGTH may
be zero.

=head2 srand( [SEED] )

Reset the generator using SEED. Numeric seeds are encoded as fixed-width
integers, while byte strings are hashed as bytes and wide strings are encoded
as UTF-8 before hashing. An omitted or undefined seed is treated as zero. The
numeric value of the seed is returned.

=head1 SEE ALSO

L<RNG>, L<perlfunc/rand EXPR>, L<perlvar/${^RNG}>, and
L<https://www.pcg-random.org/>.

=cut
