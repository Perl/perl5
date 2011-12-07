package feature;

our $VERSION = '1.24';

# (feature name) => (internal name, used in %^H)
my %feature = (
    say             => 'feature_say',
    state           => 'feature_state',
    switch          => 'feature_switch',
    evalbytes       => 'feature_evalbytes',
    current_sub     => 'feature___SUB__',
    unicode_eval    => 'feature_unieval',
    unicode_strings => 'feature_unicode',
);

# This gets set (for now) in $^H as well as in %^H,
# for runtime speed of the uc/lc/ucfirst/lcfirst functions.
# See HINT_UNI_8_BIT in perl.h.
our $hint_uni8bit = 0x00000800;

# NB. the latest bundle must be loaded by the -E switch (see toke.c)

our %feature_bundle = (
    "default" => [],
    "5.10" => [qw(say state switch)],
    "5.11" => [qw(say state switch unicode_strings)],
    "5.15" => [qw(say state switch unicode_strings unicode_eval
                  evalbytes current_sub)],
);

# Each of these is the same as the previous bundle
for(12...14, 16) {
    $feature_bundle{"5.$_"} = $feature_bundle{"5.".($_-1)}
}

# special case
$feature_bundle{"5.9.5"} = $feature_bundle{"5.10"};

# TODO:
# - think about versioned features (use feature switch => 2)

=head1 NAME

feature - Perl pragma to enable new features

=head1 SYNOPSIS

    use feature qw(say switch);
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
only when the appropriate feature pragma is in scope. (Nevertheless, the
C<CORE::> prefix provides access to all Perl keywords, regardless of this
pragma.)

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

=head2 The 'say' feature

C<use feature 'say'> tells the compiler to enable the Perl 6
C<say> function.

See L<perlfunc/say> for details.

=head2 the 'state' feature

C<use feature 'state'> tells the compiler to enable C<state>
variables.

See L<perlsub/"Persistent Private Variables"> for details.

=head2 The 'switch' feature

C<use feature 'switch'> tells the compiler to enable the Perl 6
given/when construct.

See L<perlsyn/"Switch statements"> for details.

=head2 the 'unicode_strings' feature

C<use feature 'unicode_strings'> tells the compiler to use Unicode semantics
in all string operations executed within its scope (unless they are also
within the scope of either C<use locale> or C<use bytes>).  The same applies
to all regular expressions compiled within the scope, even if executed outside
it.

C<no feature 'unicode_strings'> tells the compiler to use the traditional
Perl semantics wherein the native character set semantics is used unless it is
clear to Perl that Unicode is desired.  This can lead to some surprises
when the behavior suddenly changes.  (See
L<perlunicode/The "Unicode Bug"> for details.)  For this reason, if you are
potentially using Unicode in your program, the
C<use feature 'unicode_strings'> subpragma is B<strongly> recommended.

This subpragma is available starting with Perl 5.11.3, but was not fully
implemented until 5.13.8.

=head2 the 'unicode_eval' and 'evalbytes' features

Under the C<unicode_eval> feature, Perl's C<eval> function, when passed a
string, will evaluate it as a string of characters, ignoring any
C<use utf8> declarations.  C<use utf8> exists to declare the encoding of
the script, which only makes sense for a stream of bytes, not a string of
characters.  Source filters are forbidden, as they also really only make
sense on strings of bytes.  Any attempt to activate a source filter will
result in an error.

The C<evalbytes> feature enables the C<evalbytes> keyword, which evaluates
the argument passed to it as a string of bytes.  It dies if the string
contains any characters outside the 8-bit range.  Source filters work
within C<evalbytes>: they apply to the contents of the string being
evaluated.

Together, these two features are intended to replace the historical C<eval>
function, which has (at least) two bugs in it, that cannot easily be fixed
without breaking existing programs:

=over

=item *

C<eval> behaves differently depending on the internal encoding of the
string, sometimes treating its argument as a string of bytes, and sometimes
as a string of characters.

=item *

Source filters activated within C<eval> leak out into whichever I<file>
scope is currently being compiled.  To give an example with the CPAN module
L<Semi::Semicolons>:

    BEGIN { eval "use Semi::Semicolons;  # not filtered here " }
    # filtered here!

C<evalbytes> fixes that to work the way one would expect:

    use feature "evalbytes";
    BEGIN { evalbytes "use Semi::Semicolons;  # filtered " }
    # not filtered

=back

These two features are available starting with Perl 5.16.

=head2 The 'current_sub' feature

This provides the C<__SUB__> token that returns a reference to the current
subroutine or C<undef> outside of a subroutine.

This feature is available starting with Perl 5.16.

=head1 FEATURE BUNDLES

It's possible to load a whole slew of features in one go, using
a I<feature bundle>. The name of a feature bundle is prefixed with
a colon, to distinguish it from an actual feature. At present, most
feature bundles correspond to Perl releases, e.g. C<use feature
":5.10"> which is equivalent to C<use feature qw(switch say state)>. The
only bundle that does not follow this convention is ":default", which is
currently empty.

By convention, the feature bundle for any given Perl release includes
the features of previous releases, down to and including 5.10, the
first official release to provide this facility. Since Perl 5.12
only provides one new feature, C<unicode_strings>, and Perl 5.14
provides none, C<use feature ":5.14"> is equivalent to C<use feature
qw(switch say state unicode_strings)>.

Specifying sub-versions such as the C<0> in C<5.14.0> in feature bundles has
no effect: feature bundles are guaranteed to be the same for all sub-versions.

Note that instead of using release-based feature bundles it is usually
better, and shorter, to use implicit loading as described below.

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

    no feature;
    use feature ':5.10';

and so on. Note how the trailing sub-version is automatically stripped from the
version.

But to avoid portability warnings (see L<perlfunc/use>), you may prefer:

    use 5.010;

with the same effect.

For versions below 5.010, the ":default" feature bundle is automatically
loaded, but it is currently empty and has no effect.

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
