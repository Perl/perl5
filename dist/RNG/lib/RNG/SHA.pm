package RNG::SHA;

use 5.008;
use strict;
use warnings;
use Digest::SHA qw(sha256);
use Encode qw(encode_utf8);

our $VERSION = '0.01';

sub new {
    my ($class, $seed) = @_;
    my $self = bless {}, $class;
    $self->srand($seed);
    return $self;
}

sub _bytes {
    my ($seed) = @_;
    return '' unless defined $seed;
    return encode_utf8($seed) if utf8::is_utf8($seed);
    return "$seed";
}

sub srand {
    my ($self, $seed) = @_;
    $self->{seed} = _bytes($seed);
    $self->{counter} = 0;
    $self->{buffer} = '';
    return defined($seed) && $seed =~ /\A[+-]?\d+\z/ ? 0 + $seed : 0;
}

sub _refill {
    my ($self) = @_;
    my $counter = pack('Q>', $self->{counter}++);
    $self->{buffer} .= sha256($self->{seed} . $counter);
}

sub rand_bytes {
    my ($self, $length) = @_;
    while (length($self->{buffer}) < $length) {
        $self->_refill;
    }
    return substr($self->{buffer}, 0, $length, '');
}

sub rand01 {
    my ($self) = @_;
    my ($high, $low) = unpack('N2', $self->rand_bytes(8));
    return ($high / (2 ** 32)) + ($low / (2 ** 64));
}

sub rand {
    my ($self, $limit) = @_;
    $limit = 1 unless defined($limit) && $limit != 0;
    return $limit * $self->rand01;
}

sub rand01_callback {
    my ($self) = @_;
    return sub { $self->rand01 };
}

1;

=head1 NAME

RNG::SHA - a SHA-256 based pseudorandom number generator

=head1 DESCRIPTION

This module implements a deterministic pseudorandom number generator using
the pure-Perl C<Digest::SHA> interface. Each block is the SHA-256 digest of
the seed concatenated with a counter. Each digest supplies four 64-bit values
before the next digest is computed.

The generator is suitable for repeatable simulations and tests, but is not
intended for cryptographic use.

See L<RNG> for the provider interface used by C<${^RNG}>.

=head1 METHODS

The C<new>, C<rand>, C<rand01>, C<rand01_callback>, C<rand_bytes>, and C<srand>
methods have the same roles as their counterparts in L<RNG::PCG>.

=cut
