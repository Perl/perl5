package RNG;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

1;

=head1 NAME

RNG - interface documentation for Perl random number providers

=head1 SYNOPSIS

    {
        local ${^RNG} = My::RNG->new($seed);
        my $value = rand(100);
        srand(42);
    }

    {
        local ${^RNG} = sub { get_a_random_uv() };
        my $value = rand();
    }

=head1 DESCRIPTION

C<RNG> documents the interface used by objects and code references assigned
to Perl's C<${^RNG}> variable. It is not a required base class. A generator
may inherit from C<RNG> if that is useful, but Perl only requires the methods
described below.

The provider's state belongs to the provider. Localizing C<${^RNG}> selects a
different provider for the dynamically scoped region, but does not copy,
restore, or otherwise rewind the state of an object.

=head1 PROVIDER INTERFACE

=head2 Object providers

An object assigned to C<${^RNG}> must provide:

=over

=item rand_bytes LENGTH

Return exactly LENGTH random bytes. Perl calls this method with the number of
bytes it needs whenever it needs a random value for C<rand>. The method must
advance the provider's state as appropriate and return a binary string.

=item srand SEED

Reset the provider's state using C<SEED>. Perl calls this method for an
explicit C<srand> while the object is selected. C<srand()> and
C<srand(undef)> are equivalent, so the seed may be C<undef>.

=back

The provider may also offer C<rand>, C<rand01>, and
C<rand01_callback> methods as convenience interfaces. C<rand> accepts an
optional limit and returns a floating-point value in the corresponding range;
C<rand01> returns a value between zero and one; and C<rand01_callback> returns
a code reference which calls C<rand01> on the provider. These are ordinary
module methods; Perl's built-in C<rand> uses C<rand_bytes> directly.

=head2 Code-reference providers

An unblessed code reference assigned to C<${^RNG}> is called with the number
of bytes Perl needs whenever it requires a random value. It must return a
binary string of exactly that length. For an explicit C<srand>, Perl calls the
same code reference with the supplied seed, or with C<undef> when no seed was
supplied.
C<srand()> and C<srand(undef)> are equivalent.

The code reference owns and updates its state. It is responsible for
interpreting the seed and for making its returned bytes suitable for use as
random data.

=head2 Undefined providers

When C<${^RNG}> is undefined, Perl uses its normal process-local random
number generator.

=head1 SEE ALSO

L<perlvar/${^RNG}>, L<perlfunc/rand EXPR>, L<perlfunc/srand EXPR>,
L<RNG::PCG>, and L<RNG::SHA>.

=cut
