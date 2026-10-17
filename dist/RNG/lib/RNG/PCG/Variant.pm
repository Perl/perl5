package RNG::PCG::Variant;

use v5.24;
use strict;
use warnings;
use RNG ();
use RNG::Provider ();

our $VERSION = '0.02';
our @ISA = 'RNG::Provider';

RNG::_load_xs();

sub rand_U01_callback {
    my ($self) = @_;
    return sub { $self->rand_U01 };
}

sub srand { RNG::_provider_srand($_[0], '_srand', @_[1 .. $#_]) }

1;

=head1 NAME

RNG::PCG::Variant - common provider methods for PCG variants

=head1 DESCRIPTION

This module supplies the Perl-level provider methods shared by the specialized
PCG algorithm classes.  Each class has its own XS callbacks, so the core does
not select an algorithm for every generated value.

=cut
