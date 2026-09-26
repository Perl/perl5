package RNG::SeedBase;

use v5.24;
use strict;
use warnings;

our $VERSION = '0.02';

sub is_redacted { die "RNG::SeedBase is an abstract base class\n" }
sub bytes { die "RNG::SeedBase is an abstract base class\n" }
sub provider { die "RNG::SeedBase is an abstract base class\n" }

1;

=head1 NAME

RNG::SeedBase - abstract base class for raw RNG seed material

=head1 DESCRIPTION

Subclasses of C<RNG::SeedBase> carry raw seed material for C<srand>.  They
must implement C<is_redacted>, C<bytes>, and C<provider>.
C<srand> recognizes the inheritance relationship and obtains raw octets
through C<bytes>; it does not inspect a subclass's representation.  The base
methods throw exceptions to make an incomplete implementation fail at the call
site.

=cut
