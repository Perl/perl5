package threads;

use 5.008;

use strict;
use warnings;

our $VERSION = '1.28';
my $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;


BEGIN {
    # Verify this Perl supports threads
    use Config;
    if (! $Config{useithreads}) {
        die("This Perl not built to support threads\n");
    }

    # Declare that we have been loaded
    $threads::threads = 1;

    # Complain if 'threads' is loaded after 'threads::shared'
    if ($threads::shared::threads_shared) {
        warn <<'_MSG_';
Warning, threads::shared has already been loaded.  To
enable shared variables, 'use threads' must be called
before threads::shared or any module that uses it.
_MSG_
   }
}


# Load the XS code
require XSLoader;
XSLoader::load('threads', $XS_VERSION);


### Export ###

sub import
{
    my $class = shift;   # Not used

    # Exported subroutines
    my @EXPORT = qw(async);

    # Handle args
    while (my $sym = shift) {
        if ($sym =~ /^stack/) {
            threads->set_stack_size(shift);

        } elsif ($sym =~ /all/) {
            push(@EXPORT, qw(yield));

        } else {
            push(@EXPORT, $sym);
        }
    }

    # Export subroutine names
    my $caller = caller();
    foreach my $sym (@EXPORT) {
        no strict 'refs';
        *{$caller.'::'.$sym} = \&{$sym};
    }

    # Set stack size via environment variable
    if (exists($ENV{'PERL5_ITHREADS_STACK_SIZE'})) {
        threads->set_stack_size($ENV{'PERL5_ITHREADS_STACK_SIZE'});
    }
}


### Methods, etc. ###

# 'new' is an alias for 'create'
*new = \&create;

# 'async' is a function alias for the 'threads->create()' method
sub async (&;@)
{
    unshift(@_, 'threads');
    # Use "goto" trick to avoid pad problems from 5.8.1 (fixed in 5.8.2)
    goto &create;
}

# Thread object equality checking
use overload (
    '==' => \&equal,
    '!=' => sub { ! equal(@_) },
    'fallback' => 1
);

1;

__END__

=head1 NAME

threads - Perl interpreter-based threads

=head1 VERSION

This document describes threads version 1.28

=head1 SYNOPSIS

    use threads ('yield', 'stack_size' => 64*4096);

    sub start_thread {
        my @args = @_;
        print "Thread started: @args\n";
    }
    my $thread = threads->create('start_thread', 'argument');
    $thread->join();

    threads->create(sub { print("I am a thread\n"); })->join();

    my $thread3 = async { foreach (@files) { ... } };
    $thread3->join();

    # Invoke thread in list context so it can return a list
    my ($thr) = threads->create(sub { return (qw/a b c/); });
    my @results = $thr->join();

    $thread->detach();

    $thread = threads->self();
    $thread = threads->object($tid);

    $tid = threads->tid();
    $tid = threads->self->tid();
    $tid = $thread->tid();

    threads->yield();
    yield();

    my @threads = threads->list();
    my $thread_count = threads->list();

    if ($thr1 == $thr2) {
        ...
    }

    $stack_size = threads->get_stack_size();
    $old_size = threads->set_stack_size(32*4096);

    $thr->kill('SIGUSR1');

=head1 DESCRIPTION

Perl 5.6 introduced something called interpreter threads.  Interpreter threads
are different from I<5005threads> (the thread model of Perl 5.005) by creating
a new Perl interpreter per thread, and not sharing any data or state between
threads by default.

Prior to Perl 5.8, this has only been available to people embedding Perl, and
for emulating fork() on Windows.

The I<threads> API is loosely based on the old Thread.pm API. It is very
important to note that variables are not shared between threads, all variables
are by default thread local.  To use shared variables one must use
L<threads::shared>.

It is also important to note that you must enable threads by doing C<use
threads> as early as possible in the script itself, and that it is not
possible to enable threading inside an C<eval "">, C<do>, C<require>, or
C<use>.  In particular, if you are intending to share variables with
L<threads::shared>, you must C<use threads> before you C<use threads::shared>.
(C<threads> will emit a warning if you do it the other way around.)

=over

=item $thr = threads->create(FUNCTION, ARGS)

This will create a new thread that will begin execution with the specified
entry point function, and give it the I<ARGS> list as parameters.  It will
return the corresponding threads object, or C<undef> if thread creation failed.

I<FUNCTION> may either be the name of a function, an anonymous subroutine, or
a code ref.

    my $thr = threads->create('func_name', ...);
        # or
    my $thr = threads->create(sub { ... }, ...);
        # or
    my $thr = threads->create(\&func, ...);

The thread may be created in I<list> context, or I<scalar> context as follows:

    # Create thread in list context
    my ($thr) = threads->create(...);

    # Create thread in scalar context
    my $thr = threads->create(...);

This has consequences for the C<-E<gt>join()> method describe below.

Although a thread may be created in I<void> context, to do so you must
I<chain> either the C<-E<gt>join()> or C<-E<gt>detach()> method to the
C<-E<gt>create()> call:

    threads->create(...)->join();

The C<-E<gt>new()> method is an alias for C<-E<gt>create()>.

=item $thr->join()

This will wait for the corresponding thread to complete its execution.  When
the thread finishes, C<-E<gt>join()> will return the return value(s) of the
entry point function.

The context (void, scalar or list) of the thread creation is also the
context for C<-E<gt>join()>.  This means that if you intend to return an array
from a thread, you must use C<my ($thr) = threads->create(...)>, and that
if you intend to return a scalar, you must use C<my $thr = ...>:

    # Create thread in list context
    my ($thr1) = threads->create(sub {
                                    my @results = qw(a b c);
                                    return (@results);
                                 };
    # Retrieve list results from thread
    my @res1 = $thr1->join();

    # Create thread in scalar context
    my $thr2 = threads->create(sub {
                                    my $result = 42;
                                    return ($result);
                                 };
    # Retrieve scalar result from thread
    my $res2 = $thr2->join();

If the program exits without all other threads having been either joined or
detached, then a warning will be issued. (A program exits either because one
of its threads explicitly calls L<exit()|perlfunc/"exit EXPR">, or in the case
of the main thread, reaches the end of the main program file.)

Calling C<-E<gt>join()> or C<-E<gt>detach()> on an already joined thread will
cause an error to be thrown.

=item $thr->detach()

Makes the thread unjoinable, and causes any eventual return value to be
discarded.

Calling C<-E<gt>join()> or C<-E<gt>detach()> on an already detached thread
will cause an error to be thrown.

=item threads->detach()

Class method that allows a thread to detach itself.

=item threads->self()

Class method that allows a thread to obtain its own I<threads> object.

=item $thr->tid()

Returns the ID of the thread.  Thread IDs are unique integers with the main
thread in a program being 0, and incrementing by 1 for every thread created.

=item threads->tid()

Class method that allows a thread to obtain its own ID.

=item threads->object($tid)

This will return the I<threads> object for the I<active> thread associated
with the specified thread ID.  Returns C<undef> if there is no thread
associated with the TID, if the thread is joined or detached, if no TID is
specified or if the specified TID is undef.

=item threads->yield()

This is a suggestion to the OS to let this thread yield CPU time to other
threads.  What actually happens is highly dependent upon the underlying
thread implementation.

You may do C<use threads qw(yield)>, and then just use C<yield()> in your
code.

=item threads->list()

In a list context, returns a list of all non-joined, non-detached I<threads>
objects.  In a scalar context, returns a count of the same.

=item $thr1->equal($thr2)

Tests if two threads objects are the same thread or not.  This is overloaded
to the more natural forms:

    if ($thr1 == $thr2) {
        print("Threads are the same\n");
    }
    # or
    if ($thr1 != $thr2) {
        print("Threads differ\n");
    }

(Thread comparison is based on thread IDs.)

=item async BLOCK;

C<async> creates a thread to execute the block immediately following
it.  This block is treated as an anonymous subroutine, and so must have a
semi-colon after the closing brace.  Like C<threads->create()>, C<async>
returns a I<threads> object.

=item $thr->_handle()

This I<private> method returns the memory location of the internal thread
structure associated with a threads object.  For Win32, this is a pointer to
the C<HANDLE> value returned by C<CreateThread> (i.e., C<HANDLE *>); for other
platforms, it is a pointer to the C<pthread_t> structure used in the
C<pthread_create> call (i.e., C<pthread_t *>).

This method is of no use for general Perl threads programming.  Its intent is
to provide other (XS-based) thread modules with the capability to access, and
possibly manipulate, the underlying thread structure associated with a Perl
thread.

=item threads->_handle()

Class method that allows a thread to obtain its own I<handle>.

=back

=head1 THREAD STACK SIZE

The default per-thread stack size for different platforms varies
significantly, and is almost always far more than is needed for most
applications.  On Win32, Perl's makefile explicitly sets the default stack to
16 MB; on most other platforms, the system default is used, which again may be
much larger than is needed.

By tuning the stack size to more accurately reflect your application's needs,
you may significantly reduce your application's memory usage, and increase the
number of simultaneously running threads.

N.B., on Windows, Address space allocation granularity is 64 KB, therefore,
setting the stack smaller than that on Win32 Perl will not save any more
memory.

=over

=item threads->get_stack_size();

Returns the current default per-thread stack size.  The default is zero, which
means the system default stack size is currently in use.

=item $size = $thr->get_stack_size();

Returns the stack size for a particular thread.  A return value of zero
indicates the system default stack size was used for the thread.

=item $old_size = threads->set_stack_size($new_size);

Sets a new default per-thread stack size, and returns the previous setting.

Some platforms have a minimum thread stack size.  Trying to set the stack size
below this value will result in a warning, and the minimum stack size will be
used.

Some Linux platforms have a maximum stack size.  Setting too large of a stack
size will cause thread creation to fail.

If needed, C<$new_size> will be rounded up to the next multiple of the memory
page size (usually 4096 or 8192).

Threads created after the stack size is set will then either call
C<pthread_attr_setstacksize()> I<(for pthreads platforms)>, or supply the
stack size to C<CreateThread()> I<(for Win32 Perl)>.

(Obviously, this call does not affect any currently extant threads.)

=item use threads ('stack_size' => VALUE);

This sets the default per-thread stack size at the start of the application.

=item $ENV{'PERL5_ITHREADS_STACK_SIZE'}

The default per-thread stack size may be set at the start of the application
through the use of the environment variable C<PERL5_ITHREADS_STACK_SIZE>:

    PERL5_ITHREADS_STACK_SIZE=1048576
    export PERL5_ITHREADS_STACK_SIZE
    perl -e'use threads; print(threads->get_stack_size(), "\n")'

This value overrides any C<stack_size> parameter given to C<use threads>.  Its
primary purpose is to permit setting the per-thread stack size for legacy
threaded applications.

=item threads->create({'stack_size' => VALUE}, FUNCTION, ARGS)

This change to the thread creation method permits specifying the stack size
for an individual thread.

=item $thr2 = $thr1->create(FUNCTION, ARGS)

This creates a new thread (C<$thr2>) that inherits the stack size from an
existing thread (C<$thr1>).  This is shorthand for the following:

    my $stack_size = $thr1->get_stack_size();
    my $thr2 = threads->create({'stack_size' => $stack_size}, FUNCTION, ARGS);

=back

=head1 THREAD SIGNALLING

When safe signals is in effect (the default behavior - see L<Unsafe signals>
for more details), then signals may be sent and acted upon by individual
threads.

=over 4

=item $thr->kill('SIG...');

Sends the specified signal to the thread.  Signal names and (positive) signal
numbers are the same as those supported by
L<kill()|perlfunc/"kill SIGNAL, LIST">.  For example, 'SIGTERM', 'TERM' and
(depending on the OS) 15 are all valid arguments to C<-E<gt>kill()>.

Returns the thread object to allow for method chaining:

    $thr->kill('SIG...')->join();

=back

Signal handlers need to be set up in the threads for the signals they are
expected to act upon.  Here's an example for I<cancelling> a thread:

    use threads;

    # Suppress warning message when thread is 'killed'
    no warnings 'threads';

    sub thr_func
    {
        # Thread 'cancellation' signal handler
        $SIG{'KILL'} = sub { die("Thread killed\n"); };

        ...
    }

    # Create a thread
    my $thr = threads->create('thr_func');

    ...

    # Signal the thread to terminate, and then detach
    # it so that it will get cleaned up automatically
    $thr->kill('KILL')->detach();

Here's another simplistic example that illustrates the use of thread
signalling in conjunction with a semaphore to provide rudimentary I<suspend>
and I<resume> capabilities:

    use threads;
    use Thread::Semaphore;

    sub thr_func
    {
        my $sema = shift;

        # Thread 'suspend/resume' signal handler
        $SIG{'STOP'} = sub {
            $sema->down();      # Thread suspended
            $sema->up();        # Thread resumes
        };

        ...
    }

    # Create a semaphore and send it to a thread
    my $sema = Thread::Semaphore->new();
    my $thr = threads->create('thr_func', $sema);

    # Suspend the thread
    $sema->down();
    $thr->kill('STOP');

    ...

    # Allow the thread to continue
    $sema->up();

CAVEAT:  The thread signalling capability provided by this module does not
actually send signals via the OS.  It I<emulates> signals at the Perl-level
such that signal handlers are called in the appropriate thread.  For example,
sending C<$thr-E<gt>kill('STOP')> does not actually suspend a thread (or the
whole process), but does cause a C<$SIG{'STOP'}> handler to be called in that
thread (as illustrated above).

As such, signals that would normally not be appropriate to use in the
C<kill()> command (e.g., C<kill('KILL', $$)>) are okay to use with the
C<-E<gt>kill()> method (again, as illustrated above).

Correspondingly, sending a signal to a thread does not disrupt the operation
the thread is currently working on:  The signal will be acted upon after the
current operation has completed.  For instance, if the thread is I<stuck> on
an I/O call, sending it a signal will not cause the I/O call to be interrupted
such that the signal is acted up immediately.

=head1 WARNINGS

=over 4

=item A thread exited while # other threads were still running

A thread (not necessarily the main thread) exited while there were still other
threads running.  Usually, it's a good idea to first collect the return values
of the created threads by joining them, and only then exit from the main
thread.

=item Thread creation failed: pthread_create returned #

See the appropriate I<man> page for C<pthread_create> to determine the actual
cause for the failure.

=item Thread # terminated abnormally: ...

A thread terminated in some manner other than just returning from its entry
point function.  For example, the thread may have exited via C<die>.

=item Using minimum thread stack size of #

Some platforms have a minimum thread stack size.  Trying to set the stack size
below this value will result in the above warning, and the stack size will be
set to the minimum.

=item Thread creation failed: pthread_attr_setstacksize(I<SIZE>) returned 22

The specified I<SIZE> exceeds the system's maximum stack size.  Use a smaller
value for the stack size.

=back

If needed, thread warnings can be suppressed by using:

    no warnings 'threads';

in the appropriate scope.

=head1 ERRORS

=over 4

=item This Perl not built to support threads

The particular copy of Perl that you're trying to use was not built using the
C<useithreads> configuration option.

Having threads support requires all of Perl and all of the XS modules in the
Perl installation to be rebuilt; it is not just a question of adding the
L<threads> module (i.e., threaded and non-threaded Perls are binary
incompatible.)

=item Cannot change stack size of an existing thread

The stack size of currently extant threads cannot be changed, therefore, the
following results in the above error:

    $thr->set_stack_size($size);

=item Cannot signal other threads without safe signals

Safe signals must be in effect to use the C<-E<gt>kill()> signalling method.
See L<Unsafe signals> for more details.

=item Unrecognized signal name: ...

The particular copy of Perl that you're trying to use does not support the
specified signal being used in a C<-E<gt>kill()> call.

=back

=head1 BUGS

=over

=item Parent-child threads

On some platforms, it might not be possible to destroy I<parent> threads while
there are still existing I<child> threads.

=item Creating threads inside special blocks

Creating threads inside C<BEGIN>, C<CHECK> or C<INIT> blocks cannot be relied
upon.  Depending on the Perl version and the application code, results may
range from success, to (apparently harmless) warnings of leaked scalar or
attempts to free unreferenced scalars, all the way up to crashing of the Perl
interpreter.

=item Unsafe signals

Since Perl 5.8.0, signals have been made safer in Perl by postponing their
handling until the interpreter is in a I<safe> state.  See
L<perl58delta/"Safe Signals"> and L<perlipc/"Deferred Signals (Safe Signals)">
for more details.

Safe signals is the default behavior, and the old, immediate, unsafe
signalling behavior is only in effect in the following situations:

=over 4

=item * Perl was been built with C<PERL_OLD_SIGNALS> (see C<perl -V>).

=item * The environment variable C<PERL_SIGNALS> is set to C<unsafe> (see L<perlrun/"PERL_SIGNALS">).

=item * The module L<Perl::Unsafe::Signals> is used.

=back

If unsafe signals is in effect, then signal handling is not thread-safe, and
the C<-E<gt>kill()> signalling method cannot be used.

=item Returning closures from threads

Returning closures from threads cannot be relied upon.  Depending of the Perl
version and the application code, results may range from success, to
(apparently harmless) warnings of leaked scalar, all the way up to crashing of
the Perl interpreter.

=item Perl Bugs and the CPAN Version of L<threads>

Support for threads extents beyond the code in this module (i.e.,
F<threads.pm> and F<threads.xs>), and into the Perl iterpreter itself.  Older
versions of Perl contain bugs that may manifest themselves despite using the
latest version of L<threads> from CPAN.  There is no workaround for this other
than upgrading to the lastest version of Perl.

(Before you consider posting a bug report, please consult, and possibly post a
message to the discussion forum to see if what you've encountered is a known
problem.)

=back

=head1 REQUIREMENTS

Perl 5.8.0 or later

=head1 SEE ALSO

L<threads> Discussion Forum on CPAN:
L<http://www.cpanforum.com/dist/threads>

Annotated POD for L<threads>:
L<http://annocpan.org/~JDHEDDEN/threads-1.28/shared.pm>

L<threads::shared>, L<perlthrtut>

L<http://www.perl.com/pub/a/2002/06/11/threads.html> and
L<http://www.perl.com/pub/a/2002/09/04/threads.html>

Perl threads mailing list:
L<http://lists.cpan.org/showlist.cgi?name=iThreads>

Stack size discussion:
L<http://www.perlmonks.org/?node_id=532956>

=head1 AUTHOR

Artur Bergman E<lt>sky AT crucially DOT netE<gt>

threads is released under the same license as Perl.

CPAN version produced by Jerry D. Hedden <jdhedden AT cpan DOT org>

=head1 ACKNOWLEDGEMENTS

Richard Soderberg E<lt>perl AT crystalflame DOT netE<gt> -
Helping me out tons, trying to find reasons for races and other weird bugs!

Simon Cozens E<lt>simon AT brecon DOT co DOT ukE<gt> -
Being there to answer zillions of annoying questions

Rocco Caputo E<lt>troc AT netrus DOT netE<gt>

Vipul Ved Prakash E<lt>mail AT vipul DOT netE<gt> -
Helping with debugging

Dean Arnold E<lt>darnold AT presicient DOT comE<gt> -
Stack size API

=cut
