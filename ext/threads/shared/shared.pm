package threads::shared;

use strict;
use warnings;
use Config;
use Scalar::Util qw(weaken);
use attributes qw(reftype);

BEGIN {
    if ($Config{'useithreads'} && $threads::threads) {
	*share = \&share_enabled;
	*cond_wait = \&cond_wait_enabled;
	*cond_signal = \&cond_signal_enabled;
	*cond_broadcast = \&cond_broadcast_enabled;
	*unlock = \&unlock_enabled;
    } else {
	*share = \&share_disabled;
	*cond_wait = \&cond_wait_disabled;
	*cond_signal = \&cond_signal_disabled;
	*cond_broadcast = \&cond_broadcast_disabled;
	*unlock = \&unlock_disabled;
    }
}

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw(share cond_wait cond_broadcast cond_signal unlock);
our $VERSION = '0.90';

our %shared;

sub cond_wait_disabled { return @_ };
sub cond_signal_disabled { return @_};
sub cond_broadcast_disabled { return @_};
sub unlock_disabled { 1 };
sub lock_disabled { 1 }
sub share_disabled { return @_}

sub share_enabled (\[$@%]) { # \]
    my $value = $_[0];
    my $ref = reftype($value);
    if($ref eq 'SCALAR') {
	my $obj = \threads::shared::sv->new($$value);
	bless $obj, 'threads::shared::sv';
	$shared{$$obj} = $value;
	weaken($shared{$$obj});
    } elsif($ref eq "ARRAY") {
	tie @$value, 'threads::shared::av', $value;
    } elsif($ref eq "HASH") {
	tie %$value, "threads::shared::hv", $value;
    } else {
	die "You cannot share ref of type $_[0]\n";
    }
}


package threads::shared::sv;
use base 'threads::shared';

sub DESTROY {}

package threads::shared::av;
use base 'threads::shared';
use Scalar::Util qw(weaken);
sub TIEARRAY {
	my $class = shift;
        my $value = shift;
	my $self = bless \threads::shared::av->new($value),'threads::shared::av';
	$shared{$self->ptr} = $value;
	weaken($shared{$self->ptr});
	return $self;
}

package threads::shared::hv;
use base 'threads::shared';
use Scalar::Util qw(weaken);
sub TIEHASH {
    my $class = shift;
    my $value = shift;
    my $self = bless \threads::shared::hv->new($value),'threads::shared::hv';
    $shared{$self->ptr} = $value;
    weaken($shared{$self->ptr});
    return $self;
}

package threads::shared;

$threads::shared::threads_shared = 1;

bootstrap threads::shared $VERSION;

__END__

=head1 NAME

threads::shared - Perl extension for sharing data structures between threads

=head1 SYNOPSIS

  use threads::shared;

  my($foo, @foo, %foo);
  share($foo);
  share(@foo);
  share(%hash);
  my $bar = share([]);
  $hash{bar} = share({});

  lock(%hash);
  unlock(%hash);
  cond_wait($scalar);
  cond_broadcast(@array);
  cond_signal(%hash);

=head1 DESCRIPTION

This modules allows you to share() variables. These variables will
then be shared across different threads (and pseudoforks on
win32). They are used together with the threads module.

=head1 EXPORT

C<share>, C<lock>, C<unlock>, C<cond_wait>, C<cond_signal>, C<cond_broadcast>

=head1 FUNCTIONS

=over 4

=item share VARIABLE

C<share> takes a value and marks it as shared, you can share a scalar, array, hash
scalar ref, array ref and hash ref, C<share> will return the shared value.

C<share> will traverse up references exactly I<one> level.
C<share(\$a)> is equivalent to C<share($a)>, while C<share(\\$a)> is not.

=item lock VARIABLE

C<lock> places a lock on a variable until the lock goes out of scope.  If
the variable is locked by another thread, the C<lock> call will block until
it's available. C<lock> is recursive, so multiple calls to C<lock> are
safe--the variable will remain locked until the outermost lock on the
variable goes out of scope or C<unlock> is called enough times to match
the number of calls to <lock>.

If a container object, such as a hash or array, is locked, all the elements
of that container are not locked. For example, if a thread does a C<lock
@a>, any other thread doing a C<lock($a[12])> won't block.

C<lock> will traverse up references exactly I<one> level.
C<lock(\$a)> is equivalent to C<lock($a)>, while C<lock(\\$a)> is not.


=item unlock VARIABLE

C<unlock> takes a locked shared value and decrements the lock count.
If the lock count is zero the variable is unlocked. It is not necessary
to call C<unlock> but it can be usefull to reduce lock contention.

C<unlock> will traverse up references exactly I<one> level.
C<unlock(\$a)> is equivalent to C<unlock($a)>, while C<unlock(\\$a)> is not.

=item cond_wait VARIABLE

The C<cond_wait> function takes a B<locked> variable as a parameter,
unlocks the variable, and blocks until another thread does a C<cond_signal>
or C<cond_broadcast> for that same locked variable. The variable that
C<cond_wait> blocked on is relocked after the C<cond_wait> is satisfied.
If there are multiple threads C<cond_wait>ing on the same variable, all but
one will reblock waiting to reaquire the lock on the variable. (So if
you're only using C<cond_wait> for synchronization, give up the lock as
soon as possible)

It is important to note that the variable can be notified even if no
thread C<cond_signal> or C<cond_broadcast> on the variable. It is therefore
important to check the value of the variable and go back to waiting if the
requirment is not fullfilled.

=item cond_signal VARIABLE

The C<cond_signal> function takes a B<locked> variable as a parameter and
unblocks one thread that's C<cond_wait>ing on that variable. If more than
one thread is blocked in a C<cond_wait> on that variable, only one (and
which one is indeterminate) will be unblocked.

If there are no threads blocked in a C<cond_wait> on the variable, the
signal is discarded.

=item cond_broadcast VARIABLE

The C<cond_broadcast> function works similarly to C<cond_signal>.
C<cond_broadcast>, though, will unblock B<all> the threads that are blocked
in a C<cond_wait> on the locked variable, rather than only one.


=head1 NOTES

threads::shared is designed to disable itself silently if threads are
not available. If you want access to threads, you must C<use threads>
before you C<use threads::shared>.  threads will emit a warning if you
use it after threads::shared.

=head1 BUGS

C<bless> is not supported on shared references, in the current version
C<bless> will only bless the thread local reference and the blessing
will not propagate to the other threads, this is expected to be implmented
in the future.

Does not support splice on arrays!

=head1 AUTHOR

Arthur Bergman E<lt>arthur at contiller.seE<gt>

threads::shared is released under the same license as Perl

Documentation borrowed from Thread.pm

=head1 SEE ALSO

L<perl> L<threads>

=cut





