package Class::Fields;
use Carp;

sub import {
    my $class = shift;
    my ($package) = caller;
    my $fields = \%{"$package\::FIELDS"};
    my $i = $fields->{__MAX__};
    foreach my $f (@_) {
	if (defined($fields->{$f})) {
	    croak "Field name $f already used by a base class"
	}
	$fields->{$f} = ++$i;
    }
    $fields->{__MAX__} = $i;
    push(@{"$package\::ISA"}, "Class::Fields");
}

sub new {
    my $class = shift;
    bless [\%{"$class\::FIELDS"}, @_], $class;
}

sub ISA {
    my ($class, $package) = @_;
    my $from_fields = \%{"$class\::FIELDS"};
    my $to_fields = \%{"$package\::FIELDS"};
    return unless defined %$from_fields;
    croak "Ambiguous inheritance for %FIELDS" if defined %$to_fields;
    %$to_fields = %$from_fields;
}

1;
