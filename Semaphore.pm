package Thread::Semaphore;
use Thread qw(cond_wait cond_broadcast);

sub new {
    my $class = shift;
    my $val = @_ ? shift : 1;
    bless \$val, $class;
}

sub down {
    use attrs qw(locked method);
    my $s = shift;
    cond_wait $s until $$s > 0;
    $$s--;
}

sub up {
    use attrs qw(locked method);
    my $s = shift;
    $$s++ > 0 and cond_broadcast $s;
}

1;
