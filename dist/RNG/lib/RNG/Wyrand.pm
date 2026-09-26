package RNG::Wyrand;

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

RNG::Wyrand - a small fast 64-bit pseudorandom number generator

=head1 SYNOPSIS

    use RNG::Wyrand;

    my $rng = RNG::Wyrand->new(42);
    my $number = $rng->rand(10);

    {
        local ${^RNG} = $rng;
        print rand(10), "\n";
    }

=head1 DESCRIPTION

This module implements the wyrand 64-bit pseudorandom number generator.  It
has a small state and is intended for fast simulation, testing, and other
non-cryptographic uses where a compact generator is useful.

The state is stored in a blessed scalar reference.  The XS implementation
provides C<get_rand_U01_XS_func_addr> and C<get_rand_U01_XS_state_addr>,
allowing Perl's core C<rand> to call the
generator directly without Perl method dispatch or a temporary byte buffer.
The ordinary C<rand_bytes> method remains available as the portable provider
interface.

This generator is not suitable for cryptography, security tokens, passwords,
or any other security-sensitive use.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.

=head2 new( SEED )

Create a generator initialized from SEED. Defined seeds are stringified as
UTF-8. If SEED is omitted, it defaults to zero.

=head2 rand( [LIMIT] )

Return a pseudorandom floating-point value between zero and one, or between
zero and LIMIT when LIMIT is supplied.  A LIMIT of zero is treated as one.

=head2 rand_U01

Advance the generator and return a pseudorandom U01 value.  U01 means a
uniform floating-point value in the half-open interval [0,1).

=head2 rand_U01_callback

Return a callback which calls C<rand_U01> on this generator.

=head2 get_rand_U01_XS_func_addr and get_rand_U01_XS_state_addr

These optional XS integration methods return the address of the native U01
callback and the address of its state for the core's fast C<rand> path.  U01
means a uniform value in the half-open interval [0,1).  Applications should
not normally call them directly.

=head2 rand_bytes( LENGTH )

Advance the generator and return exactly LENGTH random bytes.  Bytes are
assembled in big-endian order.  LENGTH may be zero.

=head2 srand( [SEED] )

Reset the generator using SEED. An omitted or undefined seed obtains fresh
seed material and returns a replayable C<RNG::Seed>; an explicit seed is
returned unchanged.

=head1 SEE ALSO

L<RNG> and L<perlfunc/rand EXPR>.

=cut
