package threads;

use 5.7.2;
use strict;
use warnings;

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
	
);
our $VERSION = '0.05';


sub equal {
    return 1 if($_[0]->tid() == $_[1]->tid());
    return 0;
}

$threads::threads = 1;

bootstrap threads $VERSION;

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

my $thread = threads->new("start_thread","argument");

$thread->new(sub { print "I am a thread"},"argument");

$thread->join();

$thread->detach();

$thread = threads->self();

threads->tid();
threads->self->tid();

$thread->tid();

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

=item $thread = new(function, LIST)

This will create a new thread with the entry point function and give
it LIST as parameters.  It will return the corresponding threads
object.

create() is an alias to new.

=item $thread->join

This will wait for the corresponding thread to join. When it finishes
join will return the return values of the entry point function.  If a
thread has been detached, join will return without wait.

=item $thread->detach

Will throw away the return value from the thread and make it
non-joinable.

=item threads->self

This will return the object for the current thread.

=item $thread->tid

This will return the id of the thread.  threads->self->tid() is a
quick way to get current thread id.

=back


=head1 TODO

=over

=item Fix so the return value is returned when you join.

=item Add join_all.

=item Fix memory leaks!

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

=head1 BUGS

=over

=item creating a thread from within a thread is unsafe under win32

=item PERL_OLD_SIGNALS are not threadsafe, will not be.


=back

=head1 SEE ALSO

L<perl>, L<threads::shared>, L<perlcall>, L<perlembed>, L<perlguts>

=cut
