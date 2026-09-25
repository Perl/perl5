package RNG::Drand48;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('RNG', $VERSION);

sub rand01_callback {
    my ($self) = @_;
    return sub { $self->rand01 };
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

The XS implementation provides C<get_rand_u64_XS_func_addr> and
C<get_rand_u64_XS_state_addr>, so the core can call the provider directly
through the fast C<${^RNG}> callback path.  The provider uses the same state
transition as the built-in C<drand48>
implementation, but its byte and floating-point interfaces use the high-bit
adapter described above.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.  The module provides
C<new>, C<rand>, C<rand01>, C<rand01_callback>, C<rand_bytes>, C<srand>, and
C<get_rand_u64_XS_func_addr> and C<get_rand_u64_XS_state_addr>.

=head1 SEE ALSO

L<RNG>, L<perlfunc/rand EXPR>, L<perlvar/${^RNG}>, and L<perlrng>.

=cut
