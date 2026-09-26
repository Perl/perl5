package RNG::PCG;

use v5.24;
use strict;
use warnings;
use RNG ();
use RNG::Provider ();
use RNG::Seed;

our $VERSION = '0.02';
our @ISA = 'RNG::Provider';

RNG::_load_xs();

sub rand_U01_callback {
    my ($self) = @_;
    return sub { $self->rand_U01 };
}

sub srand { RNG::_provider_srand($_[0], '_srand', @_[1 .. $#_]) }

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
Perl's C<${^RNG}> variable. Its XS implementation provides
C<get_rand_U01_XS_func_addr> and C<get_rand_U01_XS_state_addr> methods, so Perl
can discover a direct callback and its native state when the
object is selected. After that setup,
C<rand> can obtain U01 values without calling the Perl C<rand_bytes> method or
constructing a temporary byte buffer for every request.

This generator is not suitable for cryptography, security tokens, passwords,
or any other security-sensitive use.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.

=head2 new( SEED )

Create a generator initialized from SEED. Defined seeds are stringified as
UTF-8 and hashed. If SEED is omitted, it defaults to zero.

=head2 rand( [LIMIT] )

Return a pseudorandom floating-point value in the same form as Perl's
built-in C<rand>: between zero and one when LIMIT is omitted, or between zero
and LIMIT when it is supplied. A LIMIT of zero is treated as one.

=head2 rand_U01

Advance the generator and return a pseudorandom U01 value.  U01 means a
uniform floating-point value in the half-open interval [0,1).

=head2 rand_U01_callback

Return a callback which calls C<rand_U01> on this generator. The callback can
be assigned to C<$List::Util::RAND> to reproduce the same sequence as using
the generator through C<${^RNG}>.

=head2 get_rand_U01_XS_func_addr and get_rand_U01_XS_state_addr

These optional XS integration methods are used by the core for the fastest
C<rand> path. The first returns the address of the native U01 callback; the
second returns the address of its state. Applications should not normally call
them directly.

=head2 rand_bytes( LENGTH )

Advance the generator and return exactly LENGTH random bytes. Bytes are
assembled from successive 32-bit PCG outputs in big-endian order. LENGTH may
be zero.

=head2 srand( [SEED] )

Reset the generator using SEED. Defined seeds are stringified as UTF-8 and
hashed. An omitted or undefined seed obtains fresh seed material and returns
a replayable C<RNG::Seed>; an explicit seed is returned unchanged.

=head1 SEE ALSO

L<RNG>, L<perlfunc/rand EXPR>, and
L<https://www.pcg-random.org/>.

=cut
