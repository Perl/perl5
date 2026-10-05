package RNG::PCG;

use v5.24;
use strict;
use warnings;
use RNG ();
use RNG::Provider ();
use RNG::Seed;

our $VERSION = '0.02';
our @ISA = 'RNG::Provider';

RNG::_load_xs();

my %variant_class = (
    'xsh-rr-64/32-ext' => __PACKAGE__,
    'rxs-m-xs-64/64' => 'RNG::PCG::RXS_M_XS_64_64',
    'xsl-rr-128/64-mcg' => 'RNG::PCG::XSL_RR_128_64_MCG',
    'xsl-rr-128/64-lcg' => 'RNG::PCG::XSL_RR_128_64_LCG',
);

sub new {
    my ($class, $seed, @options) = @_;

    $seed = 0 unless @_ > 1;
    return $class->_new($seed) unless @options;
    CORE::die "RNG::PCG constructor options must be key/value pairs\n"
        if @options % 2;

    my %options = @options;
    my $variant = delete $options{variant};
    CORE::die "Unknown RNG::PCG constructor option: " . (keys %options)[0] . "\n"
        if %options;
    $variant = 'xsh-rr-64/32-ext' unless defined $variant;

    my $variant_class = $variant_class{$variant};
    CORE::die "Unknown RNG::PCG variant '$variant'\n"
        unless defined $variant_class;
    return $class->_new($seed) if $variant_class eq __PACKAGE__;

    (my $file = $variant_class) =~ s!::!/!g;
    require "$file.pm";
    return $variant_class->new($seed);
}

sub rand_U01_callback {
    my ($self) = @_;
    return sub { $self->rand_U01 };
}

sub srand { RNG::_provider_srand($_[0], '_srand', @_[1 .. $#_]) }

1;

=head1 NAME

RNG::PCG - PCG pseudorandom number generators

=head1 SYNOPSIS

    use RNG::PCG;

    my $rng = RNG::PCG->new(42);
    my $number = $rng->rand(10);

    my $pcg64 = RNG::PCG->new(42, variant => 'xsl-rr-128/64-mcg');

    {
        local ${^RNG} = $rng;
        print rand(10), "\n";
    }

=head1 DESCRIPTION

This module provides several PCG variants. The default is the existing
two-dimensional PCG-XSH-RR generator. It uses a 64-bit base state and a
two-element 32-bit extension array, avoiding a dependency on native 128-bit
arithmetic. Other choices are PCG RXS-M-XS 64/64 and PCG XSL-RR 128/64 with
either an MCG or LCG state transition.

Each object stores its state in a blessed scalar reference. Its
C<rand_bytes> method combines successive outputs into a canonical big-endian
byte string, so the provider interface is independent of Perl's native
integer width. Each object can be used directly as a provider for Perl's
C<${^RNG}> variable. Its XS implementation provides
C<get_rand_U01_XS_func_addr> and C<get_rand_U01_XS_state_addr> methods, so Perl
can discover a direct callback and its native state when the
object is selected. After that setup,
C<rand> can obtain U01 values without calling the Perl C<rand_bytes> method or
constructing a temporary byte buffer for every request.

The XSL-RR variants use native 128-bit arithmetic when the compiler target
provides it. Other targets use a pair of 64-bit words. Each variant has a
separate class and XS callback. The selected variant is fixed when the object
is constructed.

These generators are not suitable for cryptography, security tokens,
passwords, or any other security-sensitive use.

=head1 METHODS

See L<RNG> for the provider interface used by C<${^RNG}>.

=head2 new( SEED, variant =E<gt> NAME )

Create a generator initialized from SEED. Defined ordinary seeds are
stringified as UTF-8 and hashed. If SEED is omitted, it defaults to zero.
NAME may be C<xsh-rr-64/32-ext> (the default), C<rxs-m-xs-64/64>,
C<xsl-rr-128/64-mcg>, or C<xsl-rr-128/64-lcg>. The selected object is an
instance of that variant's class. Each class can be loaded and constructed
directly.

=head2 rand( [LIMIT] )

Return a pseudorandom floating-point value in the same form as Perl's
built-in C<rand>: between zero and one when LIMIT is omitted, or between zero
and LIMIT when it is supplied. A LIMIT of zero is treated as one.

=head2 rand_U01

Advance the generator and return a pseudorandom U01 value.  U01 means a
uniform floating-point value in the half-open interval [0,1).

=head2 rand_U01_callback

Return a callback which calls C<rand_U01> on this generator. The callback can
be assigned to C<$List::Util::RAND> to reproduce the same sequence as using
the generator through C<${^RNG}>.

=head2 get_rand_U01_XS_func_addr and get_rand_U01_XS_state_addr

These optional XS integration methods are used by the core for the fastest
C<rand> path. The first returns the address of the native U01 callback; the
second returns the address of its state. Applications should not normally call
them directly.

=head2 rand_bytes( LENGTH )

Advance the generator and return exactly LENGTH random bytes. Bytes are
assembled from successive 64-bit outputs in big-endian order. LENGTH may be
zero.

=head2 srand( [SEED] )

Reset the generator using SEED. Defined seeds are stringified as UTF-8 and
hashed. An omitted or undefined seed obtains fresh seed material and returns
a replayable C<RNG::Seed>; an explicit seed is returned unchanged.

=head1 SEE ALSO

L<RNG>, L<perlfunc/rand EXPR>, and
L<https://www.pcg-random.org/>.

=cut
