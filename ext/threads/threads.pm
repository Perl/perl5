

package threads;

use 5.7.2;
use strict;
use warnings;

use overload 
    '==' => \&equals,
    'fallback' => 1;


#use threads::Shared;

require Exporter;
require DynaLoader;

use Devel::Peek;


our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( all => [qw()]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.05';

sub new {
    my $class = shift;
    print (Dump($_[0]));
    return $class->create(@_);
}


sub equals {
    return 1 if($_[0]->tid() == $_[1]->tid());
    return 0;
}

$Config::threads = 1;

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

thread->tid();



=head1 DESCRIPTION

Perl 5.6 has something called interpreter threads, interpreter threads are built on MULTIPLICITY and allows for several different perl interpreters to run in different threads. This has been used in win32 perl to fake forks, it has also been available to people embedding perl. 

=over

=item new, function, LIST

This will create a new thread with the entry point function and give it LIST as parameters.
It will return the corresponding threads object.

=item $threads->join

This will wait for the corresponding thread to join. When it finishes join will return the return values of the root function.
If a thread has been detached, join will return without wait.

=item $threads->detach

Will throw away the return value from the thread and make non joinable

=item threads->self

This will return the object for the current thread.

=item $threads->tid

This will return the id of the thread.
threads->self->tid() is a quick way to get current thread id

=back


=head1 TODO

=over

=item Fix so the return value is returned when you join

=item Add join_all

=item Fix memory leaks!

=back

=head1 AUTHOR and COPYRIGHT

Artur Bergman <lt>artur at contiller.se<gt>

threads is released under the same license as Perl

Thanks to 

Richard Soderberg <lt>rs at crystalflame.net<gt> 
Helping me out tons, trying to find reasons for races and other wierd bugs!

Simon Cozens <lt>simon at brecon.co.uk<gt>
Being there to answer zillions of annoying questions 

Rocco Caputo <lt>troc at netrus.net<gt>

Vipul Ved Prakash <lt>mail at vipul.net<gt>
Helping with debugging.

please join perl-ithreads@perl.org for more information

=head1 BUGS

=over

=item creating a thread from within a thread is unsafe under win32

=back

=head1 SEE ALSO

L<perl>, L<perlcall>, L<perlembed>, L<perlguts>

=cut




