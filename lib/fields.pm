package fields;

=head1 NAME

fields - compile-time class fields

=head1 SYNOPSIS

    {
        package Foo;
        use fields qw(foo bar baz);
    }
    ...
    my Foo $var = new Foo;
    $var->{foo} = 42;

    # This will generate a compile-time error.
    $var->{zap} = 42;

=head1 DESCRIPTION

The C<fields> pragma enables compile-time verified class fields.

=cut

sub import {
    my $class = shift;
    my ($package) = caller;
    my $fields = \%{"$package\::FIELDS"};
    my $i = $fields->{__MAX__};
    foreach my $f (@_) {
	if (defined($fields->{$f})) {
	    require Carp;
	    Carp::croak("Field name $f already in use");
	}
	$fields->{$f} = ++$i;
    }
    $fields->{__MAX__} = $i;
}

1;
