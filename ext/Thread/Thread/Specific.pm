package Thread::Specific;

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
