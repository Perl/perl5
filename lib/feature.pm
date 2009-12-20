package feature;

our $VERSION = '1.14';

# (feature name) => (internal name, used in %^H)
my %feature = (
    switch          => 'feature_switch',
    say             => "feature_say",
    state           => "feature_state",
    unicode_strings => "feature_unicode",
);

# This gets set (for now) in $^H as well as in %^H,
# for runtime speed of the uc/lc/ucfirst/lcfirst functions.
our $hint_uni8bit = 0x00000800;

# NB. the latest bundle must be loaded by the -E switch (see toke.c)

my %feature_bundle = (
    "5.10" => [qw(switch say state)],
    "5.11" => [qw(switch say state unicode_strings)],
);

# special case
$feature_bundle{"5.9.5"} = $feature_bundle{"5.10"};

# TODO:
# - think about versioned features (use feature switch => 2)

=head1 NAME

feature - Perl pragma to enable new syntactic features

=head1 SYNOPSIS

    use feature qw(switch say);
    given ($foo) {
	when (1)	  { say "\$foo == 1" }
	when ([2,3])	  { say "\$foo == 2 || \$foo == 3" }
	when (/^a[bc]d$/) { say "\$foo eq 'abd' || \$foo eq 'acd'" }
	when ($_ > 100)   { say "\$foo > 100" }
	default		  { say "None of the above" }
    }

    use feature ':5.10'; # loads all features available in perl 5.10

=head1 DESCRIPTION

It is usually impossible to add new syntax to Perl without breaking
some existing programs. This pragma provides a way to minimize that
risk. New syntactic constructs, or new semantic meanings to older
constructs, can be enabled by C<use feature 'foo'>, and will be parsed
only when the appropriate feature pragma is in scope.

=head2 Lexical effect

Like other pragmas (C<use strict>, for example), features have a lexical
effect. C<use feature qw(foo)> will only make the feature "foo" available
from that point to the end of the enclosing block.

    {
        use feature 'say';
        say "say is available here";
    }
    print "But not here.\n";

=head2 C<no feature>

Features can also be turned off by using C<no feature "foo">. This too
has lexical effect.

    use feature 'say';
    say "say is available here";
    {
        no feature 'say';
        print "But not here.\n";
    }
    say "Yet it is here.";

C<no feature> with no features specified will turn off all features.

=head2 The 'switch' feature

C<use feature 'switch'> tells the compiler to enable the Perl 6
given/when construct.

See L<perlsyn/"Switch statements"> for details.

=head2 The 'say' feature

C<use feature 'say'> tells the compiler to enable the Perl 6
C<say> function.

See L<perlfunc/say> for details.

=head2 the 'state' feature

C<use feature 'state'> tells the compiler to enable C<state>
variables.

See L<perlsub/"Persistent Private Variables"> for details.

=head2 the 'unicode_strings' feature

C<use feature 'unicode_strings'> tells the compiler to treat
strings with codepoints larger than 128 as Unicode. It is available
starting with Perl 5.11.3.

In greater detail:

This feature modifies the semantics for the 128 characters on ASCII
systems that have the 8th bit set.  (See L</EBCDIC platforms> below for
EBCDIC systems.) By default, unless C<S<use locale>> is specified, or the
scalar containing such a character is known by Perl to be encoded in UTF8,
the semantics are essentially that the characters have an ordinal number,
and that's it.  They are caseless, and aren't anything: they're not
controls, not letters, not punctuation, ..., not anything.

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
C<use feature "unicode_strings">.

The other old (legacy) behaviors regarding these characters are currently
unaffected by this pragma.

=head4 EBCDIC platforms

On EBCDIC platforms, the situation is somewhat different.  The legacy
semantics are whatever the underlying semantics of the native C language
library are.  Each of the three EBCDIC encodings currently known by Perl is an
isomorph of the Latin-1 character set.  That means every character in Latin-1
has a corresponding EBCDIC equivalent, and vice-versa.  Specifying C<S<no
legacy>> currently makes sure that all EBCDIC characters have the same
B<casing only> semantics as their corresponding Latin-1 characters.

=head1 FEATURE BUNDLES

It's possible to load a whole slew of features in one go, using
a I<feature bundle>. The name of a feature bundle is prefixed with
a colon, to distinguish it from an actual feature. At present, the
only feature bundle is C<use feature ":5.10"> which is equivalent
to C<use feature qw(switch say state)>.

Specifying sub-versions such as the C<0> in C<5.10.0> in feature bundles has
no effect: feature bundles are guaranteed to be the same for all sub-versions.

=head1 IMPLICIT LOADING

There are two ways to load the C<feature> pragma implicitly :

=over 4

=item *

By using the C<-E> switch on the command-line instead of C<-e>. It enables
all available features in the main compilation unit (that is, the one-liner.)

=item *

By requiring explicitly a minimal Perl version number for your program, with
the C<use VERSION> construct, and when the version is higher than or equal to
5.10.0. That is,

    use 5.10.0;

will do an implicit

    use feature ':5.10';

and so on. Note how the trailing sub-version is automatically stripped from the
version.

But to avoid portability warnings (see L<perlfunc/use>), you may prefer:

    use 5.010;

with the same effect.

=back

=cut

sub import {
    my $class = shift;
    if (@_ == 0) {
	croak("No features specified");
    }
    while (@_) {
	my $name = shift(@_);
	if (substr($name, 0, 1) eq ":") {
	    my $v = substr($name, 1);
	    if (!exists $feature_bundle{$v}) {
		$v =~ s/^([0-9]+)\.([0-9]+).[0-9]+$/$1.$2/;
		if (!exists $feature_bundle{$v}) {
		    unknown_feature_bundle(substr($name, 1));
		}
	    }
	    unshift @_, @{$feature_bundle{$v}};
	    next;
	}
	if (!exists $feature{$name}) {
	    unknown_feature($name);
	}
	$^H{$feature{$name}} = 1;
        $^H |= $hint_uni8bit if $name eq 'unicode_strings';
    }
}

sub unimport {
    my $class = shift;

    # A bare C<no feature> should disable *all* features
    if (!@_) {
	delete @^H{ values(%feature) };
        $^H &= ~ $hint_uni8bit;
	return;
    }

    while (@_) {
	my $name = shift;
	if (substr($name, 0, 1) eq ":") {
	    my $v = substr($name, 1);
	    if (!exists $feature_bundle{$v}) {
		$v =~ s/^([0-9]+)\.([0-9]+).[0-9]+$/$1.$2/;
		if (!exists $feature_bundle{$v}) {
		    unknown_feature_bundle(substr($name, 1));
		}
	    }
	    unshift @_, @{$feature_bundle{$v}};
	    next;
	}
	if (!exists($feature{$name})) {
	    unknown_feature($name);
	}
	else {
	    delete $^H{$feature{$name}};
            $^H &= ~ $hint_uni8bit if $name eq 'unicode_strings';
	}
    }
}

sub unknown_feature {
    my $feature = shift;
    croak(sprintf('Feature "%s" is not supported by Perl %vd',
	    $feature, $^V));
}

sub unknown_feature_bundle {
    my $feature = shift;
    croak(sprintf('Feature bundle "%s" is not supported by Perl %vd',
	    $feature, $^V));
}

sub croak {
    require Carp;
    Carp::croak(@_);
}

1;
