package Thread::Queue;
use Thread qw(cond_wait cond_broadcast);

sub new {
    my $class = shift;
    return bless [@_], $class;
}

sub dequeue {
    use attrs qw(locked method);
    my $q = shift;
    cond_wait $q until @$q;
    return shift @$q;
}

sub enqueue {
    use attrs qw(locked method);
    my $q = shift;
    push(@$q, @_) and cond_broadcast $q;
}

1;
