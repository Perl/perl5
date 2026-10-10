package RNG::PCG::XSL_RR_128_64_LCG;

use v5.24;
use strict;
use warnings;
use parent 'RNG::PCG::Variant';

our $VERSION = '0.02';

1;

=head1 NAME

RNG::PCG::XSL_RR_128_64_LCG - PCG XSL-RR 128/64 with an LCG state

=head1 DESCRIPTION

This class implements PCG XSL-RR 128/64 with a 128-bit linear congruential
state transition and an odd increment derived from the seed.

Use C<RNG::PCG-E<gt>new(SEED, variant =E<gt> 'xsl-rr-128/64-lcg')> to
construct this provider, or load this module and call C<new> directly.
Defined ordinary seeds are stringified as UTF-8 and expanded to 32 octets.
The first 16 octets initialize the state and the second 16 initialize the
increment, whose low bit is set to make it odd.  An C<RNG::Seed> raw seed must
contain exactly 32 octets in the same layout.

This generator is not suitable for cryptography or security-sensitive use.

=cut
