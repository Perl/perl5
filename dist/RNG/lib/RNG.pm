package RNG;

use 5.008;
use strict;
use warnings;
no warnings 'experimental::builtin';

use Scalar::Util qw(blessed looks_like_number);
use POSIX qw(isfinite);

our $VERSION = '0.02';

sub _bytes {
    return builtin::rand_bytes($_[1]);
}

sub _unit {
    my $bytes = builtin::rand_bytes(6);
    my $value = ord(substr($bytes, 0, 1));
    my $i;

    for $i (1 .. 5) {
        $value = $value * 256 + ord(substr($bytes, $i, 1));
    }
    return $value / 281474976710656;
}

sub uniform_int {
    my ($class, $bound) = @_;
    CORE::die "RNG::uniform_int() requires a positive integer bound"
        unless defined $bound && looks_like_number($bound)
            && $bound >= 1 && $bound == int($bound);

    return 0 if $bound == 1;

    my $bits = 0;
    my $range = 1;
    while ($range < $bound) {
        $range *= 2;
        ++$bits;
    }

    my $bytes = int(($bits + 7) / 8);
    my $excess = $bytes * 8 - $bits;
    my $mask = $excess ? 255 >> $excess : 255;

    while (1) {
        my $raw = builtin::rand_bytes($bytes);
        my $value = ord(substr($raw, 0, 1)) & $mask;
        my $i;

        if ($bytes > 1) {
            for $i (1 .. $bytes - 1) {
                $value = $value * 256 + ord(substr($raw, $i, 1));
            }
        }
        return $value if $value < $bound;
    }
}

sub die {
    my ($class, $sides) = @_;
    CORE::die "RNG->die() requires a positive integer side count"
        unless defined $sides && looks_like_number($sides)
            && $sides >= 1 && $sides == int($sides);
    return bless { sides => $sides }, 'RNG::Die';
}

sub weighted_die {
    my ($class, $weights) = @_;
    my $alias = RNG::AliasTable->new($weights);
    return bless { alias => $alias }, 'RNG::Die';
}

sub dice {
    my ($class, $count, $source) = @_;
    CORE::die "RNG->dice() requires a positive integer count"
        unless defined $count && looks_like_number($count)
            && $count >= 1 && $count == int($count);

    my $die = blessed($source) && $source->isa('RNG::Die')
        ? $source
        : $class->die($source);
    return bless { count => $count, die => $die }, 'RNG::Dice';
}

sub chooser {
    my ($class, $values) = @_;
    CORE::die "RNG->chooser() requires an array reference"
        unless ref($values) eq 'ARRAY' && @$values;

    my %seen;
    for my $value (@$values) {
        CORE::die "RNG->chooser() values must be defined, non-reference scalars"
            if !defined($value) || ref($value);
        CORE::die "RNG->chooser() values must be unique"
            if $seen{"$value"}++;
    }
    return bless { values => [@$values] }, 'RNG::Chooser';
}

sub weighted_chooser {
    my ($class, $weights) = @_;
    return bless { alias => RNG::AliasTable->new($weights) }, 'RNG::Chooser';
}

package RNG::AliasTable;

sub new {
    my ($class, $weights) = @_;
    CORE::die "weighted RNG input must be a hash reference"
        unless ref($weights) eq 'HASH' && %$weights;

    # Build the numerically stable form of Vose's alias method.  The method
    # is described in Michael D. Vose's paper and explained by Keith Schwarz:
    # https://doi.org/10.1109/32.92917
    # https://www.keithschwarz.com/darts-dice-coins/
    my @values = sort keys %$weights;
    my @scaled;
    my $max = 0;
    my $positive = 0;

    for my $value (@values) {
        my $weight = $weights->{$value};
        CORE::die "weighted RNG values must have finite, non-negative weights"
            unless defined $weight && Scalar::Util::looks_like_number($weight)
                && POSIX::isfinite($weight) && $weight >= 0;
        $max = $weight if $weight > $max;
        ++$positive if $weight > 0;
    }
    CORE::die "weighted RNG input must contain a positive weight"
        unless $positive;

    my $sum = 0;
    for my $value (@values) {
        my $scaled = $weights->{$value} / $max;
        push @scaled, $scaled;
        $sum += $scaled;
    }

    my $count = scalar @values;
    my @prob;
    my @alias;
    my (@small, @large);
    for my $i (0 .. $#values) {
        my $scaled = $scaled[$i] * $count / $sum;
        $prob[$i] = $scaled;
        if ($scaled < 1) {
            push @small, $i;
        }
        else {
            push @large, $i;
        }
    }

    while (@small && @large) {
        my $small = pop @small;
        my $large = pop @large;
        $alias[$small] = $large;
        $prob[$large] = $prob[$large] + $prob[$small] - 1;
        if ($prob[$large] < 1) {
            push @small, $large;
        }
        else {
            push @large, $large;
        }
    }
    $prob[$_] = 1 for (@small, @large);

    return bless {
        values => \@values,
        prob   => \@prob,
        alias  => \@alias,
    }, $class;
}

sub pick {
    my ($self) = @_;
    my $column = RNG->uniform_int(scalar @{$self->{values}});
    return $self->{values}[$column]
        if RNG::_unit() < $self->{prob}[$column];
    return $self->{values}[$self->{alias}[$column]];
}

sub roll {
    return $_[0]->pick;
}

package RNG::Die;

sub roll {
    my ($self) = @_;
    return RNG->uniform_int($self->{sides}) + 1
        if exists $self->{sides};
    return $self->{alias}->pick;
}

sub pick {
    return $_[0]->roll;
}

package RNG::Dice;

sub rolls {
    my ($self) = @_;
    my @rolls = map { $self->{die}->roll } 1 .. $self->{count};
    return \@rolls;
}

sub roll {
    my ($self) = @_;
    my $total = 0;
    $total += $_ for @{$self->rolls};
    return $total;
}

sub pick {
    return $_[0]->roll;
}

package RNG::Chooser;

sub pick {
    my ($self) = @_;
    return $self->{values}[RNG->uniform_int(scalar @{$self->{values}})]
        if exists $self->{values};
    return $self->{alias}->pick;
}

sub roll {
    return $_[0]->pick;
}

1;

=head1 NAME

RNG - random-number providers and reusable random distributions

=head1 SYNOPSIS

    use RNG;

    my $d20 = RNG->die(20);
    my $roll = $d20->roll;

    my $dice = RNG->dice(3, $d20);
    my $total = $dice->roll;       # The sum of three rolls
    my $rolls = $dice->rolls;      # The individual rolls

    my $loaded = RNG->weighted_die({
        1 => 1,
        2 => 1,
        3 => 4,
    });
    my $face = $loaded->roll;

    my $colour = RNG->weighted_chooser({
        red  => 3,
        blue => 1,
    });
    my $picked = $colour->pick;

=head1 DESCRIPTION

C<RNG> provides reusable random distributions and documents the provider
interface used by Perl's C<${^RNG}> variable.  The distributions use the
currently selected provider when they are rolled or picked.  Localizing
C<${^RNG}> is
therefore enough to make a group of calls use a different generator.

The low-level common operation is L<builtin/rand_bytes>.  C<RNG> uses that
operation to implement unbiased bounded integers and the distributions
described here.  The provider's word size is not part of the interface.

=head2 Provider interface

An object assigned to C<${^RNG}> must provide both C<rand_bytes> and C<srand>.
C<rand_bytes> returns exactly the requested number of bytes.  C<srand> resets
the provider for an explicit Perl C<srand> call.  An undefined C<${^RNG}> uses
Perl's built-in generator.

The object owns its state.  Localizing C<${^RNG}> selects a different object,
but does not copy, rewind, or restore the state of either object.

=head2 Weighted distributions

C<weighted_die> and C<weighted_chooser> use a reusable C<RNG::AliasTable>.
The table is built once, and each selection is constant time.  The
implementation uses the numerically stable form of Michael D. Vose's alias
method.  Hash keys are sorted while building the table so a seeded run does
not depend on Perl's hash iteration order.

Weights must be finite, non-negative numbers, and at least one weight must be
positive.  Weighted outcomes are hash keys and are therefore strings.

The alias table can also be constructed directly when that lower-level API is
useful:

    my $table = RNG::AliasTable->new({ red => 1, blue => 2 });
    my $value = $table->pick;  # or $table->roll

The method is described in Vose's paper
L<https://doi.org/10.1109/32.92917> and explained in Keith Schwarz's
L<Darts, Dice, and Coins|https://www.keithschwarz.com/darts-dice-coins/>.

=head2 Security

The distributions are only as strong as the selected provider.  The default
generator is intended for ordinary pseudorandom use, not cryptography.  Use a
provider designed for the required security properties when those properties
matter.

=head1 SEE ALSO

L<builtin/rand_bytes>, L<perlvar/${^RNG}>, L<perlfunc/rand EXPR>,
L<perlfunc/srand EXPR>, L<perlrng>, C<RNG::AliasTable>, L<RNG::Drand48>,
L<RNG::HMAC_DRBG>,
L<RNG::PCG>, L<RNG::Wyrand>, and L<RNG::Xoshiro>.

=cut
