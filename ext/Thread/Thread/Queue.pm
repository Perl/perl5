package Thread::Queue;
use Thread qw(cond_wait cond_broadcast);

=head1 NAME

Thread::Queue - thread-safe queues

=head1 SYNOPSIS

    use Thread::Queue;
    my $q = new Thread::Queue;
    $q->enqueue("foo", "bar");
    my $foo = $q->dequeue;	# The "bar" is still in the queue.

=cut

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
