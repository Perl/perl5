package threads;

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

use overload
    '==' => \&equal,
    'fallback' => 1;

#use threads::Shared;

BEGIN {
    warn "Warning, threads::shared has already been loaded. ".
       "To enable shared variables for these modules 'use threads' ".
       "must be called before any of those modules are loaded\n"
               if($threads::shared::threads_shared);
}

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( all => [qw()]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
async	
);
our $VERSION = '0.99';


sub equal {
    return 1 if($_[0]->tid() == $_[1]->tid());
    return 0;
}

sub async (&;@) {
    my $cref = shift;
    return threads->new($cref,@_);
}

$threads::threads = 1;

bootstrap threads $VERSION;

# why document 'new' then use 'create' in the tests!
*create = \&new;

# Preloaded methods go here.

1;
__END__

=head1 NAME

threads - Perl extension allowing use of interpreter based threads from perl

=head1 SYNOPSIS

use threads;

sub start_thread {
    print "Thread started\n";
}

my $thread = threads->create("start_thread","argument");

$thread->create(sub { print "I am a thread"},"argument");

$thread->join();

$thread->detach();

$thread = threads->self();

threads->tid();
threads->self->tid();

$thread->tid();

threads->yield();

threads->list();

=head1 DESCRIPTION

Perl 5.6 introduced something called interpreter threads.  Interpreter
threads are different from "5005threads" (the thread model of Perl
5.005) by creating a new perl interpreter per thread and not sharing
any data or state between threads.

Prior to perl 5.8 this has only been available to people embedding
perl and for emulating fork() on windows.

The threads API is loosely based on the old Thread.pm API. It is very
important to note that variables are not shared between threads, all
variables are per default thread local.  To use shared variables one
must use threads::shared.

It is also important to note that you preferably enable threads by
doing C<use threads> as early as possible and that it is not possible
to enable threading inside an eval "";  In particular, if you are
intending to share variables with threads::shared, you must
C<use threads> before you C<use threads::shared> and threads will emit
a warning if you do it the other way around.

=over

=item $thread = threads->create(function, LIST)

This will create a new thread with the entry point function and give
it LIST as parameters.  It will return the corresponding threads
object.

=item $thread->join

This will wait for the corresponding thread to join. When it finishes
join will return the return values of the entry point function.  If a
thread has been detached, an error will be thrown..

=item $thread->detach

Will throw away the return value from the thread and make it
non-joinable.

=item threads->self

This will return the object for the current thread.

=item $thread->tid

This will return the id of the thread.  threads->tid() is a quick way 
to get current thread id if you don't have your thread handy.

=item threads->yield();

This will tell the OS to let this thread yield CPU time to other threads.
However this is highly depending on the underlying thread implmentation.

=item threads->list();

This will return a list of all non joined, non detached threads.

=item async BLOCK;

C<async> creates a thread to execute the block immediately following
it.  This block is treated as an anonymous sub, and so must have a
semi-colon after the closing brace. Like C<threads-&gt;new>, C<async>
returns a thread object.

=back

=head1 WARNINGS

=over 4

=item Cleanup skipped %d active threads

The main thread exited while there were still other threads running.
This is not a good sign: you should either explicitly join the threads,
or somehow be certain that all the non-main threads have finished.

=back

=head1 BUGS / TODO

The current implmentation of threads has been an attempt to get
a correct threading system working that could be built on, 
and optimized, in newer versions of perl.

Current the overhead of creating a thread is rather large,
also the cost of returning values can be large. These are areas
were there most likely will be work done to optimize what data
that needs to be cloned.

=over

=item Parent-Child threads.

On some platforms it might not be possible to destroy "parent"
threads while there are still existing child "threads".

This will be possibly be fixed in later versions of perl.

=item tid is I32

The tid is a 32 bit integer, it can potentially overflow. 
This might be fixed in a later version of perl.

=item Returning objects

When you return an object the entire stash that the object is blessed
as well. This will lead to a large memory usage.
The ideal situation would be to detect the original stash if it existed.

=item PERL_OLD_SIGNALS are not threadsafe, will not be.

=back

=head1 AUTHOR and COPYRIGHT

Arthur Bergman E<lt>arthur at contiller.seE<gt>

threads is released under the same license as Perl.

Thanks to

Richard Soderberg E<lt>rs at crystalflame.netE<gt>
Helping me out tons, trying to find reasons for races and other weird bugs!

Simon Cozens E<lt>simon at brecon.co.ukE<gt>
Being there to answer zillions of annoying questions

Rocco Caputo E<lt>troc at netrus.netE<gt>

Vipul Ved Prakash E<lt>mail at vipul.netE<gt>
Helping with debugging.

please join perl-ithreads@perl.org for more information




=head1 SEE ALSO

L<perl>, L<threads::shared>, L<perlcall>, L<perlembed>, L<perlguts>

=cut
