package Thread::Specific;

=head1 NAME

Thread::Specific - thread-specific keys

=head1 SYNOPSIS

    use Thread::Specific;
    my $k = key_create Thread::Specific;

=cut

sub import {
    use attrs qw(locked method);
    require fields;
    fields->import(@_);
}	

sub key_create {
    use attrs qw(locked method);
    return ++$FIELDS{__MAX__};
}

1;
