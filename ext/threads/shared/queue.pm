package threads::shared::queue;

use threads::shared;
use strict;

our $VERSION = '1.00';

=head1 NAME

threads::shared::queue - thread-safe queues

=head1 SYNOPSIS

    use threads::shared::queue;
    my $q = new threads::shared::queue;
    $q->enqueue("foo", "bar");
    my $foo = $q->dequeue;    # The "bar" is still in the queue.
    my $foo = $q->dequeue_nb; # returns "bar", or undef if the queue was
                              # empty
    my $left = $q->pending;   # returns the number of items still in the queue

=head1 DESCRIPTION

A queue, as implemented by C<threads::shared::queue> is a thread-safe 
data structure much like a list.  Any number of threads can safely 
add elements to the end of the list, or remove elements from the head 
of the list. (Queues don't permit adding or removing elements from 
the middle of the list).

=head1 FUNCTIONS AND METHODS

=over 8

=item new

The C<new> function creates a new empty queue.

=item enqueue LIST

The C<enqueue> method adds a list of scalars on to the end of the queue.
The queue will grow as needed to accommodate the list.

=item dequeue

The C<dequeue> method removes a scalar from the head of the queue and
returns it. If the queue is currently empty, C<dequeue> will block the
thread until another thread C<enqueue>s a scalar.

=item dequeue_nb

The C<dequeue_nb> method, like the C<dequeue> method, removes a scalar from
the head of the queue and returns it. Unlike C<dequeue>, though,
C<dequeue_nb> won't block if the queue is empty, instead returning
C<undef>.

=item pending

The C<pending> method returns the number of items still in the queue.

=back

=head1 SEE ALSO

L<threads>, L<threads::shared>

=cut

sub new {
    my $class = shift;
    my @q : shared = @_;
    my $q = \@q;
    return bless $q, $class;
}

sub dequeue  {
    my $q = shift;
    lock(@$q);
    until(@$q) {
	cond_wait(@$q);
    }
    return shift @$q;
}

sub dequeue_nb {
  my $q = shift;
  lock(@$q);
  if (@$q) {
    return shift @$q;
  } else {
    return undef;
  }
}

sub enqueue {
    my $q = shift;
    lock(@$q);
    push(@$q, @_) and cond_broadcast @$q;
}

sub pending  {
  my $q = shift;
  lock(@$q);
  return scalar(@$q);
}

1;


