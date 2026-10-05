package RNG::Seed;

use v5.24;
use strict;
use warnings;
use RNG::SeedBase ();

our $VERSION = '0.02';
our @ISA = 'RNG::SeedBase';

sub new {
    my ($class, $value) = @_;

    die "RNG::Seed requires defined seed material\n" unless defined $value;
    return RNG::Seed::Redacted->_new($value)
        if $value =~ /\Aperl-rng-seed-redacted:.*:v1\z/;
    return bless \$value, $class;
}

sub from_bytes {
    my ($class, $bytes) = @_;

    die "RNG::Seed requires defined seed material\n" unless defined $bytes;
    return bless \$bytes, $class;
}

sub redacted {
    my ($class, $provider) = @_;

    die "RNG::Seed requires a provider name\n" unless defined $provider;
    return $class->new("perl-rng-seed-redacted:$provider:v1");
}

sub is_redacted {
    return 0;
}

sub bytes {
    my ($self) = @_;

    return $$self;
}

sub provider {
    my ($self) = @_;

    return;
}

package RNG::Seed::Redacted;

our @ISA = 'RNG::Seed';

sub _new {
    my ($class, $value) = @_;

    return bless \$value, $class;
}

sub is_redacted { 1 }

sub bytes { die "Cannot reveal a redacted RNG seed\n" }

sub provider {
    my ($self) = @_;

    return $1 if $$self =~ /\Aperl-rng-seed-redacted:(.*):v1\z/;
}

package RNG::Seed;

1;

=head1 NAME

RNG::Seed - explicit raw seed material for an RNG

=head1 SYNOPSIS

    use RNG::Seed;

    srand(RNG::Seed->from_bytes($seed_bytes));

=head1 DESCRIPTION

C<RNG::Seed> implements L<RNG::SeedBase> and distinguishes raw seed material
from ordinary C<srand> string arguments.  Objects which merely implement
similarly named methods are ordinary seed values; other C<RNG::SeedBase>
implementations can provide raw seed material.  A seed can also be redacted.
Redacted seeds record the provider which was initialized but do not reveal
material which could reproduce its state.

=head1 METHODS

=head2 new( VALUE )

Create a seed object from VALUE.  A VALUE in the serialized redaction form
C<perl-rng-seed-redacted:PROVIDER:v1> creates a redacted seed.

=head2 from_bytes( BYTES )

Create a seed object from raw octets.  Unlike C<new>, this always creates raw
seed material, even if the octets happen to equal a serialized redaction.

=head2 redacted( PROVIDER )

Create a redacted seed which records PROVIDER.

=head2 is_redacted

Return true for a redacted seed.

=head2 bytes

Return the raw seed octets.  This throws for a redacted seed.

=head2 provider

Return the recorded provider name for a redacted seed.

=head1 RAW SEED WIDTHS

C<srand> accepts raw C<RNG::Seed> material only at the provider's native
width: 4 octets for the built-in generator, 6 for C<RNG::Drand48>, 16 for
C<RNG::PCG>, 8 for C<RNG::PCG::RXS_M_XS_64_64>, 16 for
C<RNG::PCG::XSL_RR_128_64_MCG>, 32 for
C<RNG::PCG::XSL_RR_128_64_LCG> (16 state octets followed by 16 increment
octets), 8 for C<RNG::Wyrand>, and 32 for C<RNG::Xoshiro>.
C<RNG::HMAC_DRBG> uses a 64-octet C<Key || V> state seed. Raw material is
never padded or truncated. An all-zero
C<RNG::Xoshiro> raw state is adjusted to its documented valid state.

=cut
