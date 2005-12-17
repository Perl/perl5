package feature;

our $VERSION = '1.00';
$feature::hint_bits = 0x04020000; # HINT_LOCALIZE_HH | HINT_HH_FOR_EVAL

# (feature name) => (internal name, used in %^H)
my %feature = (
    switch => 'switch',
    "~~"   => "~~",
    say    => "say",
);


# Here are some notes that probably shouldn't be in the public
# documentation, but which it's useful to have somewhere.
#
# One side-effect of the change is that C<prototype("CORE::continue")>
# no longer throws the error C<Can't find an opnumber for "continue">.
# One of the tests in t/op/cproto.t had to be changed to accommodate
# this, but it really shouldn't affect real-world code.
#
# TODO:
# - sort out the smartmatch semantics
# - think about versioned features (use switch => 2)
#
# -- Robin 2005-12

=head1 NAME

feature - Perl pragma to enable new syntactic features

=head1 SYNOPSIS

    use feature 'switch';
    given ($foo) {
	when (1)	  { print "\$foo == 1\n" }
	when ([2,3])	  { print "\$foo == 2 || \$foo == 3\n" }
	when (/^a[bc]d$/) { print "\$foo eq 'abd' || \$foo eq 'acd'\n" }
	when ($_ > 100)   { print "\$foo > 100\n" }
	default		  { print "None of the above\n" }
    }

=head1 DESCRIPTION

It is usually impossible to add new syntax to Perl without breaking
some existing programs. This pragma provides a way to minimize that
risk. New syntactic constructs can be enabled by C<use feature 'foo'>,
and will be parsed only when the appropriate feature pragma is in
scope.

=head2 The 'switch' feature

C<use feature 'switch'> tells the compiler to enable the Perl 6
given/when construct from here to the end of the enclosing BLOCK.

See L<perlsyn/"Switch statements"> for details.

=head2 The '~~' feature

C<use feature '~~'> tells the compiler to enable the Perl 6
smart match C<~~> operator from here to the end of the enclosing BLOCK.

See L<perlsyn/"Smart Matching in Detail"> for details.

=head2 The 'say' feature

C<use feature 'say'> tells the compiler to enable the Perl 6
C<say> function from here to the end of the enclosing BLOCK.

See L<perlfunc/say> for details.

=cut

sub import {
    $^H |= $feature::hint_bits;	# Need this or %^H won't work

    my $class = shift;
    if (@_ == 0) {
	require Carp;
	Carp->import("croak");
	croak("No features specified");
    }
    while (@_) {
	my $name = shift(@_);
	if (!exists $feature{$name}) {
	    require Carp;
	    Carp->import("croak");
	    croak(sprintf('Feature "%s" is not supported by Perl %vd',
		$name, $^V));
	}
	$^H{$feature{$name}} = 1;
    }
}

sub unimport {
    my $class = shift;

    # A bare C<no feature> should disable *all* features
    for my $name (@_) {
	if (!exists($feature{$name})) {
	    require Carp;
	    Carp->import("croak");
	    croak(sprintf('Feature "%s" is not supported by Perl %vd',
		$name, $^V));
	}
	else {
	    delete $^H{$feature{$name}};
	}
    }

    if(!@_) {
	delete @^H{ values(%feature) };
    }
}

1;
