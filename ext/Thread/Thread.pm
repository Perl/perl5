package Thread;
require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = "1.0";

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(yield cond_signal cond_broadcast cond_wait async);

=head1 NAME

Thread - multithreading

=head1 SYNOPSIS

    use Thread;

    my $t = new Thread \&start_sub, @start_args;

    $t->join;

    my $tid = Thread->self->tid; 

    my $tlist = Thread->list;

    lock($scalar);

    use Thread 'async';

    use Thread 'eval';

=head1 DESCRIPTION

The C<Threads> module provides multithreading.

=head1 SEE ALSO

L<attrs>, L<Thread::Queue>, L<Thread::Semaphore>, L<Thread::Specific>.

=cut

#
# Methods
#

#
# Exported functions
#
sub async (&) {
    return new Thread $_[0];
}

sub eval {
    return eval { shift->join; };
}

bootstrap Thread;

1;
