package fields;

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
