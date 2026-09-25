package RNG::Wyrand;

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
provides C<get_rand_u64_XS_func_addr> and C<get_rand_u64_XS_state_addr>,
allowing Perl's core C<rand> to call the
generator directly without Perl method dispatch or a temporary byte buffer.
The ordinary C<rand_bytes> method remains available as the portable provider
interface.

This generator is not suitable for cryptography, security tokens, passwords,
or any other security-sensitive use.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.

=head2 new( SEED )

Create a generator initialized from SEED.  Numeric and string seeds are
accepted.  If SEED is omitted, zero is used.

=head2 rand( [LIMIT] )

Return a pseudorandom floating-point value between zero and one, or between
zero and LIMIT when LIMIT is supplied.  A LIMIT of zero is treated as one.

=head2 rand01

Advance the generator and return a pseudorandom floating-point value between
zero and one.

=head2 rand01_callback

Return a callback which calls C<rand01> on this generator.

=head2 get_rand_u64_XS_func_addr and get_rand_u64_XS_state_addr

This optional XS integration method returns the address of the native 64-bit
callback used by the core's fast C<rand> path.  Applications should not
normally call it directly.

=head2 rand_bytes( LENGTH )

Advance the generator and return exactly LENGTH random bytes.  Bytes are
assembled in big-endian order.  LENGTH may be zero.

=head2 srand( [SEED] )

Reset the generator using SEED and return the numeric seed value.  An omitted
or undefined seed is treated as zero.

=head1 SEE ALSO

L<RNG>, L<perlfunc/rand EXPR>, and L<perlvar/${^RNG}>.

=cut
