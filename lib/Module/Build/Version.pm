package Module::Build::Version;
use base qw/version/;

use overload (
    '""' => \&stringify,
);

sub new {
    my ($class, $value) = @_;
    my $self = $class->SUPER::new($value);
    $self->original($value);
    return $self;
}

sub original {
    my $self = shift;
    $self->{original} = shift if @_;
    return $self->{original};
}

sub stringify {
    my $self = shift;
    return $self->original;
}

1;
