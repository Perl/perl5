package threads::shared;

use 5.007_003;
use strict;
use warnings;
use Config;

BEGIN {
    unless ($Config{useithreads}) {
	my @caller = caller(2);
        die <<EOF;
$caller[1] line $caller[2]:

This Perl hasn't been configured and built properly for the threads
module to work.  (The 'useithreads' configuration option hasn't been used.)

Having threads support requires all of Perl and all of the modules in
the Perl installation to be rebuilt, it is not just a question of adding
the threads module.  (In other words, threaded and non-threaded Perls
are binary incompatible.)

If you want to the use the threads module, please contact the people
who built your Perl.

Cannot continue, aborting.
EOF
    }
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(share cond_wait cond_broadcast cond_signal _refcnt _id _thrcnt);
our $VERSION = '0.90';

if ($Config{'useithreads'}) {
	*cond_wait = \&cond_wait_enabled;
	*cond_signal = \&cond_signal_enabled;
	*cond_broadcast = \&cond_broadcast_enabled;
	require XSLoader;
	XSLoader::load('threads::shared',$VERSION);
}
else {
	*share = \&share_disabled;
	*cond_wait = \&cond_wait_disabled;
	*cond_signal = \&cond_signal_disabled;
	*cond_broadcast = \&cond_broadcast_disabled;
}


sub cond_wait_disabled { return @_ };
sub cond_signal_disabled { return @_};
sub cond_broadcast_disabled { return @_};
sub share_disabled { return @_}

$threads::shared::threads_shared = 1;

sub _thrcnt { 42 }

sub threads::shared::tie::SPLICE
{
 die "Splice not implemented for shared arrays";
}

__END__

=head1 NAME

threads::shared - Perl extension for sharing data structures between threads

=head1 SYNOPSIS

  use threads;
  use threads::shared;

  my $var : shared;

  my($scalar, @array, %hash);
  share($scalar);
  share(@array);
  share(%hash);
  my $bar = share([]);
  $hash{bar} = share({});

  { lock(%hash); ...  }

  cond_wait($scalar);
  cond_broadcast(@array);
  cond_signal(%hash);

=head1 DESCRIPTION

By default, variables are private to each thread, and each newly created
thread gets a private copy of each existing variable.  This module allows
you to share variables across different threads (and pseudoforks on
win32). It is used together with the threads module.

=head1 EXPORT

C<share>, C<lock>, C<cond_wait>, C<cond_signal>, C<cond_broadcast>

=head1 FUNCTIONS

=over 4

=item share VARIABLE

C<share> takes a value and marks it as shared. You can share a scalar, array,
hash, scalar ref, array ref or hash ref. C<share> will return the shared value.

C<share> will traverse up references exactly I<one> level.
C<share(\$a)> is equivalent to C<share($a)>, while C<share(\\$a)> is not.

A variable can also be marked as shared at compile time by using the
C<shared> attribute: C<my $var : shared>.

=item lock VARIABLE

C<lock> places a lock on a variable until the lock goes out of scope.  If
the variable is locked by another thread, the C<lock> call will block until
it's available. C<lock> is recursive, so multiple calls to C<lock> are
safe -- the variable will remain locked until the outermost lock on the
variable goes out of scope.

If a container object, such as a hash or array, is locked, all the elements
of that container are not locked. For example, if a thread does a C<lock
@a>, any other thread doing a C<lock($a[12])> won't block.

C<lock> will traverse up references exactly I<one> level.
C<lock(\$a)> is equivalent to C<lock($a)>, while C<lock(\\$a)> is not.

Note that you cannot explicitly unlock a variable; you can only wait for
the lock to go out of scope. If you need more fine-grained control, see
L<threads::shared::semaphore>.

=item cond_wait VARIABLE

The C<cond_wait> function takes a B<locked> variable as a parameter,
unlocks the variable, and blocks until another thread does a C<cond_signal>
or C<cond_broadcast> for that same locked variable. The variable that
C<cond_wait> blocked on is relocked after the C<cond_wait> is satisfied.
If there are multiple threads C<cond_wait>ing on the same variable, all but
one will reblock waiting to reacquire the lock on the variable. (So if
you're only using C<cond_wait> for synchronisation, give up the lock as
soon as possible). The two actions of unlocking the variable and entering
the blocked wait state are atomic, The two actions of exiting from the
blocked wait state and relocking the variable are not.

It is important to note that the variable can be notified even if no
thread C<cond_signal> or C<cond_broadcast> on the variable. It is therefore
important to check the value of the variable and go back to waiting if the
requirement is not fulfilled.

=item cond_signal VARIABLE

The C<cond_signal> function takes a B<locked> variable as a parameter and
unblocks one thread that's C<cond_wait>ing on that variable. If more than
one thread is blocked in a C<cond_wait> on that variable, only one (and
which one is indeterminate) will be unblocked.

If there are no threads blocked in a C<cond_wait> on the variable, the
signal is discarded. By always locking before signaling, you can (with
care), avoid signaling before another thread has entered cond_wait().

C<cond_signal> will normally generate a warning if you attempt to use it
on an unlocked variable. On the rare occasions where doing this may be
sensible, you can skip the warning with

    { no warnings 'threads'; cond_signal($foo) }

=item cond_broadcast VARIABLE

The C<cond_broadcast> function works similarly to C<cond_signal>.
C<cond_broadcast>, though, will unblock B<all> the threads that are blocked
in a C<cond_wait> on the locked variable, rather than only one.

=back

=head1 NOTES

threads::shared is designed to disable itself silently if threads are
not available. If you want access to threads, you must C<use threads>
before you C<use threads::shared>.  threads will emit a warning if you
use it after threads::shared.

=head1 BUGS

C<bless> is not supported on shared references. In the current version,
C<bless> will only bless the thread local reference and the blessing
will not propagate to the other threads. This is expected to be
implemented in a future version of Perl.

Does not support splice on arrays!

=head1 AUTHOR

Arthur Bergman E<lt>arthur at contiller.seE<gt>

threads::shared is released under the same license as Perl

Documentation borrowed from Thread.pm

=head1 SEE ALSO

L<perl> L<threads>

=cut





