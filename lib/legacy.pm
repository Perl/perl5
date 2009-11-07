package legacy;

our $VERSION = '1.00';

$unicode8bit::hint_bits = 0x00000800;

my %legacy_bundle = (
    "5.10" => [qw(unicode8bit)],
    "5.11" => [qw(unicode8bit)],
);

my %legacy = ( 'unicode8bit' => '0' );

=head1 NAME

legacy - Perl pragma to preserve legacy behaviors or enable new non-default
behaviors

=head1 SYNOPSIS

 use legacy ':5.10'; # Keeps semantics the same as in perl 5.10

 no legacy;

=cut

    #no legacy qw(unicode8bit);

=pod

=head1 DESCRIPTION

Some programs may rely on behaviors that for others are problematic or
even wrong.  A new version of Perl may change behaviors from past ones,
and when it is viewed that the old way of doing things may be required
to still be supported, that behavior will be added to the list recognized
by this pragma to allow that.

Additionally, a new behavior may be supported in a new version of Perl, but
for whatever reason the default remains the old one.  This pragma can enable
the new behavior.

Like other pragmas (C<use feature>, for example), C<use legacy qw(foo)> will
only make the legacy behavior for "foo" available from that point to the end of
the enclosing block.

B<This pragma is, for the moment, a skeleton and does not actually affect any
behaviors yet>

=head2 B<use legacy>

Preserve the old way of doing things when a new version of Perl is
released that changes things

=head2 B<no legacy>

Turn on a new behavior in a version of Perl that understands
it but has it turned off by default.  For example, C<no legacy 'foo'> turns on
behavior C<foo> in the lexical scope of the pragma.  Simply C<no legacy>
turns on all new behaviors known to the pragma.

=head1 LEGACY BUNDLES

It's possible to turn off all new behaviors past a given release by 
using a I<legacy bundle>, which is the name of the release prefixed with
a colon, to distinguish it from an individual legacy behavior.

Specifying sub-versions such as the C<0> in C<5.10.0> in legacy bundles has
no effect: legacy bundles are guaranteed to be the same for all sub-versions.

Legacy bundles are not allowed with C<no legacy>

=cut

sub import {
    my $class = shift;
    if (@_ == 0) {
        croak("No legacy behaviors specified");
    }
    while (@_) {
        my $name = shift(@_);
        if (substr($name, 0, 1) eq ":") {
            my $v = substr($name, 1);
            if (!exists $legacy_bundle{$v}) {
                $v =~ s/^([0-9]+)\.([0-9]+).[0-9]+$/$1.$2/;
                if (!exists $legacy_bundle{$v}) {
                    unknown_legacy_bundle(substr($name, 1));
                }
            }
            unshift @_, @{$legacy_bundle{$v}};
            next;
        }
        if (!exists $legacy{$name}) {
            unknown_legacy($name);
        }
        $^H &= ~$unicode8bit::hint_bits;    # The only thing it could be as of yet
    }
}


sub unimport {
    my $class = shift;

    # A bare C<no legacy> should disable *all* legacy behaviors
    if (!@_) {
        unshift @_, keys(%legacy);
    }

    while (@_) {
        my $name = shift;
        if (substr($name, 0, 1) eq ":") {
            croak(sprintf('Legacy bundles (%s) are not allowed in "no legacy"',
                $name));
        }
        if (!exists($legacy{$name})) {
            unknown_legacy($name);
        }
        else {
            $^H |= $unicode8bit::hint_bits; # The only thing it could be as of yet
        }
    }
}

sub unknown_legacy {
    my $legacy = shift;
    croak(sprintf('Legacy "%s" is not supported by Perl %vd', $legacy, $^V));
}

sub unknown_legacy_bundle {
    my $legacy = shift;
    croak(sprintf('Legacy bundle "%s" is not supported by Perl %vd',
        $legacy, $^V));
}

sub croak {
    require Carp;
    Carp::croak(@_);
}

1;
