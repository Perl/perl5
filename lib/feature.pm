package feature;

our $VERSION = '1.01';

# (feature name) => (internal name, used in %^H)
my %feature = (
    switch => 'feature_switch',
    "~~"   => "feature_~~",
    say    => "feature_say",
    err    => "feature_err",
    dor    => "feature_err",
    state  => "feature_state",
);

my %feature_bundle = (
    "5.10" => [qw(switch ~~ say err state)],
);


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

=head1 DESCRIPTION

It is usually impossible to add new syntax to Perl without breaking
some existing programs. This pragma provides a way to minimize that
risk. New syntactic constructs can be enabled by C<use feature 'foo'>,
and will be parsed only when the appropriate feature pragma is in
scope.

=head2 Lexical effect

Like other pragmas (C<use strict>, for example), features have a lexical
effect.  C<use feature qw(foo)> will only make the feature "foo" available
from that point to the end of the enclosing block.

    {
        use feature 'say';
        say "say is available here";
    }
    print "But not here.\n";

=head2 The 'switch' feature

C<use feature 'switch'> tells the compiler to enable the Perl 6
given/when construct.

See L<perlsyn/"Switch statements"> for details.

=head2 The '~~' feature

C<use feature '~~'> tells the compiler to enable the Perl 6
smart match C<~~> operator.

See L<perlsyn/"Smart Matching in Detail"> for details.

=head2 The 'say' feature

C<use feature 'say'> tells the compiler to enable the Perl 6
C<say> function.

See L<perlfunc/say> for details.

=head2 the 'err' feature

C<use feature 'err'> tells the compiler to enable the C<err>
operator.

C<err> is a low-precedence variant of the C<//> operator:
see C<perlop> for details.

=head2 the 'dor' feature

The 'dor' feature is an alias for the 'err' feature.

=head2 the 'state' feature

C<use feature 'state'> tells the compiler to enable C<state>
variables.

See L<perlsub/"Persistent Private Variables"> for details.

=head1 FEATURE BUNDLES

It's possible to load a whole slew of features in one go, using
a I<feature bundle>. The name of a feature bundle is prefixed with
a colon, to distinguish it from an actual feature. At present, the
only feature bundle is C<use feature ":5.10">, which is equivalent
to C<use feature qw(switch ~~ say err state)>.

=cut

sub import {
    my $class = shift;
    if (@_ == 0) {
	croak("No features specified");
    }
    while (@_) {
	my $name = shift(@_);
	if ($name =~ /^:(.*)/) {
	    if (!exists $feature_bundle{$1}) {
		unknown_feature_bundle($1);
	    }
	    unshift @_, @{$feature_bundle{$1}};
	    next;
	}
	if (!exists $feature{$name}) {
	    unknown_feature($name);
	}
	$^H{$feature{$name}} = 1;
    }
}

sub unimport {
    my $class = shift;

    # A bare C<no feature> should disable *all* features
    if (!@_) {
	delete @^H{ values(%feature) };
	return;
    }

    while (@_) {
	my $name = shift;
	if ($name =~ /^:(.*)/) {
	    if (!exists $feature_bundle{$1}) {
		unknown_feature_bundle($1);
	    }
	    unshift @_, @{$feature_bundle{$1}};
	    next;
	}
	if (!exists($feature{$name})) {
	    unknown_feature($name);
	}
	else {
	    delete $^H{$feature{$name}};
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
