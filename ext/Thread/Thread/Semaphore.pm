package Thread::Semaphore;
use Thread qw(cond_wait cond_broadcast);

=head1 NAME

Thread::Semaphore - thread-safe semaphores

=head1 SYNOPSIS

    use Thread::Semaphore;
    my $s = new Thread::Semaphore;
    $s->up;	# Also known as the semaphore V -operation.
    # The guarded section is here
    $s->down;	# Also known as the semaphore P -operation.

    # The default semaphore value is 1.
    my $s = new Thread::Semaphore($initial_value);
    $s->up($up_value);
    $s->down($up_value);

=cut

sub new {
    my $class = shift;
    my $val = @_ ? shift : 1;
    bless \$val, $class;
}

sub down {
    use attrs qw(locked method);
    my $s = shift;
    my $inc = @_ ? shift : 1;
    cond_wait $s until $$s >= $inc;
    $$s -= $inc;
}

sub up {
    use attrs qw(locked method);
    my $s = shift;
    my $inc = @_ ? shift : 1;
    ($$s += $inc) > 0 and cond_broadcast $s;
}

1;
