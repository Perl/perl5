package RNG::Drand48;

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

sub srand {
    my ($self, @seed) = @_;
    return $self->_srand unless @seed && defined $seed[0];
    return $self->_srand($seed[0]);
}

1;

=head1 NAME

RNG::Drand48 - the Perl drand48 algorithm as a ${^RNG} provider

=head1 SYNOPSIS

    use RNG::Drand48;

    my $rng = RNG::Drand48->new(42);
    my $number = $rng->rand(10);

    {
        local ${^RNG} = $rng;
        print rand(10), "\n";
    }

=head1 DESCRIPTION

This module exposes the 48-bit linear-congruential generator used by Perl's
default random-number implementation as an object satisfying the C<RNG>
provider interface.  It is primarily useful for comparison and compatibility
testing.  It is not suitable for cryptography or security-sensitive uses.
Its byte interface emits the high 32 bits from each 48-bit state transition.
This avoids presenting the generator's weak low bits as independent random
bytes.

The XS implementation provides C<get_rand_U01_XS_func_addr> and
C<get_rand_U01_XS_state_addr>, so the core can call the provider directly
through the fast C<${^RNG}> callback path.  The provider uses the same state
transition and U01 result as the built-in C<drand48> implementation for the
shared 32-bit seed range.  Its byte interface uses the high-bit adapter
described above.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.  The module provides
C<new>, C<rand>, C<rand_U01>, C<rand_U01_callback>, C<rand_bytes>, C<srand>, and
C<get_rand_U01_XS_func_addr> and C<get_rand_U01_XS_state_addr>.

=head2 srand( [SEED] )

Reset the generator using SEED. Numeric seeds through 32 bits reproduce the
built-in C<drand48> initialization. The module also accepts numeric seeds
through 48 bits; larger numeric seeds warn. Non-numeric seeds are hashed in
the same way as built-in C<srand>, so they initialize both implementations
identically. An omitted or undefined seed obtains fresh seed material.

The compatibility forms accept leading and trailing whitespace, an optional
sign, decimal digits, and an optional fractional part.  The sign and
fractional part are ignored, as in the historical C<srand> numeric
conversion.  The built-in retains the low 32 bits and this module retains the
low 48 bits.  A value wider than the applicable width warns.  Other inputs
are ordinary string seeds.  After any input, C<srand> returns the resulting
Drand48 initializer, even when it hashes an ordinary string seed.  Passing
that return value back to C<srand> recreates the sequence.  It returns a
decimal string when the 48-bit initializer does not fit in the host UV.

A zero initializer returns the historical string C<"0 but true">.  This
module and the default RNG recognize that exact string as zero.  This is a
Drand48 compatibility quirk.  Other RNGs treat it as ordinary string seed
material and should not be expected to produce the same sequence as zero.

=head1 SEE ALSO

L<RNG> and L<perlfunc/rand EXPR>.

=cut
