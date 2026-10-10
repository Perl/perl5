package RNG::PCG::RXS_M_XS_64_64;

use v5.24;
use strict;
use warnings;
use parent 'RNG::PCG::Variant';

our $VERSION = '0.02';

1;

=head1 NAME

RNG::PCG::RXS_M_XS_64_64 - PCG RXS-M-XS with 64-bit state and output

=head1 DESCRIPTION

This class implements the PCG RXS-M-XS 64/64 generator.  It uses a 64-bit
linear congruential state transition and a 64-bit output permutation.

Use C<RNG::PCG-E<gt>new(SEED, variant =E<gt> 'rxs-m-xs-64/64')> to construct
this provider, or load this module and call C<new> directly.  Defined ordinary
seeds are stringified as UTF-8 and expanded to the native state width.  An
C<RNG::Seed> raw seed must contain exactly 8 octets.

This generator is not suitable for cryptography or security-sensitive use.

=cut
