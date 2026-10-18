package RNG::PCG::XSL_RR_128_64_MCG;

use v5.24;
use strict;
use warnings;
use parent 'RNG::PCG::Variant';

our $VERSION = '0.02';

1;

=head1 NAME

RNG::PCG::XSL_RR_128_64_MCG - PCG XSL-RR 128/64 with an MCG state

=head1 DESCRIPTION

This class implements PCG XSL-RR 128/64 with a multiplicative congruential
state transition.  Its 128-bit state is forced odd when initialized, as
required for the MCG's full-length cycle.

Use C<RNG::PCG-E<gt>new(SEED, variant =E<gt> 'xsl-rr-128/64-mcg')> to
construct this provider, or load this module and call C<new> directly.
Defined ordinary seeds are stringified as UTF-8 and expanded to the native
state width.  An C<RNG::Seed> raw seed must contain exactly 16 octets.  Its
low bit is set to keep the MCG state valid.

This generator is not suitable for cryptography or security-sensitive use.

=cut
