
package threads::shared::queue;

use threads::shared;
use strict;

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

