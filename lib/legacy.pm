package legacy;

our $VERSION = '1.00';

$unicode8bit::hint_not_uni8bit = 0x00000800;

my %legacy_bundle = (
    "5.10" => [qw(unicode8bit)],
    "5.11" => [qw(unicode8bit)],
);

my %legacy = ( 'unicode8bit' => '0' );

=head1 NAME

legacy - Perl pragma to preserve legacy behaviors or enable new non-default behaviors

=head1 SYNOPSIS

 use legacy ':5.10'; # Keeps semantics the same as in perl 5.10

 use legacy qw(unicode8bit);

 no legacy;

 no legacy qw(unicode8bit);

=head1 DESCRIPTION

Some programs may rely on behaviors that for others are problematic or
even wrong.  A new version of Perl may change behaviors from past ones,
and when it is viewed that the old way of doing things may be required
to still be supported, the new behavior will be able to be turned off by using
this pragma.

Additionally, a new behavior may be supported in a new version of Perl, but
for whatever reason the default remains the old one.  This pragma can enable
the new behavior.

Like other pragmas (C<use feature>, for example), C<use legacy qw(foo)> will
only make the legacy behavior for "foo" available from that point to the end of
the enclosing block.

=head2 B<use legacy>

Preserve the old way of doing things when a new version of Perl is
released that would otherwise change the behavior.

The one current possibility is:

=head3 unicode8bit

Use legacy semantics for the 128 characters on ASCII systems that have the 8th
bit set.  (See L</EBCDIC platforms> below for EBCDIC systems.)  Unless
C<S<use locale>> is specified, or the scalar containing such a character is
known by Perl to be encoded in UTF8, the semantics are essentially that the
characters have an ordinal number, and that's it.  They are caseless, and
aren't anything: they're not controls, not letters, not punctuation, ..., not
anything.

This behavior stems from when Perl did not support Unicode, and ASCII was the
only known character set outside of C<S<use locale>>.  In order to not
possibly break pre-Unicode programs, these characters have retained their old
non-meanings, except when it is clear to Perl that Unicode is what is meant,
for example by calling utf8::upgrade() on a scalar, or if the scalar also
contains characters that are only available in Unicode.  Then these 128
characters take on their Unicode meanings.

The problem with this behavior is that a scalar that encodes these characters
has a different meaning depending on if it is stored as utf8 or not.
In general, the internal storage method should not affect the
external behavior.

The behavior is known to have effects on these areas:

=over 4

=item *

Changing the case of a scalar, that is, using C<uc()>, C<ucfirst()>, C<lc()>,
and C<lcfirst()>, or C<\L>, C<\U>, C<\u> and C<\l> in regular expression
substitutions.

=item *

Using caseless (C</i>) regular expression matching

=item *

Matching a number of properties in regular expressions, such as C<\w>

=item *

User-defined case change mappings.  You can create a C<ToUpper()> function, for
example, which overrides Perl's built-in case mappings.  The scalar must be
encoded in utf8 for your function to actually be invoked.

=back

B<This lack of semantics for these characters is currently the default,>
outside of C<use locale>.  See below for EBCDIC.
To turn on B<case changing semantics only> for these characters, use
C<S<no legacy>>.
The other legacy behaviors regarding these characters are currently
unaffected by this pragma.

=head4 EBCDIC platforms

On EBCDIC platforms, the situation is somewhat different.  The legacy
semantics are whatever the underlying semantics of the native C language
library are.  Each of the three EBCDIC encodings currently known by Perl is an
isomorph of the Latin-1 character set.  That means every character in Latin-1
has a corresponding EBCDIC equivalent, and vice-versa.  Specifying C<S<no
legacy>> currently makes sure that all EBCDIC characters have the same
B<casing only> semantics as their corresponding Latin-1 characters.

=head2 B<no legacy>

Turn on a new behavior in a version of Perl that understands
it but has it turned off by default.  For example, C<no legacy 'foo'> turns on
behavior C<foo> in the lexical scope of the pragma.  C<no legacy>
without any modifier turns on all new behaviors known to the pragma.

=head1 LEGACY BUNDLES

It's possible to turn off all new behaviors past a given release by
using a I<legacy bundle>, which is the name of the release prefixed with
a colon, to distinguish it from an individual legacy behavior.

Specifying sub-versions such as the C<0> in C<5.10.0> in legacy bundles has
no effect: legacy bundles are guaranteed to be the same for all sub-versions.

Legacy bundles are not allowed with C<no legacy>.

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
        $^H |= $unicode8bit::hint_not_uni8bit;   # The only valid thing as of yet
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
            $^H &= ~ $unicode8bit::hint_not_uni8bit; # The only valid thing now
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
