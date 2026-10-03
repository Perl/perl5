package RNG::Provider;

use v5.24;
use strict;
use warnings;

our $VERSION = '0.02';

sub rand_bytes { die "RNG::Provider must implement rand_bytes\n" }
sub srand { die "RNG::Provider must implement srand\n" }
sub get_rand_U01_XS_func_addr { return }
sub get_rand_U01_XS_state_addr { return }

1;

=head1 NAME

RNG::Provider - abstract base class for C<${^RNG}> providers

=head1 DESCRIPTION

Subclasses of C<RNG::Provider> can be assigned to C<${^RNG}>.  They must
implement C<rand_bytes> and C<srand>.  Those base methods throw exceptions to
make an incomplete implementation fail at the call site.

The two C<get_rand_U01_XS_*> methods are optional integration hooks.  The
base methods return undef.  An XS provider can override both methods to let
the core cache a native U01 callback.  U01 means a uniform value in the
half-open interval [0,1).  Ordinary providers do not need to implement them.

=cut
