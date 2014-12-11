package Test::Stream::API;
use strict;
use warnings;

use Test::Stream::Tester qw/intercept/;
use Test::Stream::Carp qw/croak confess/;
use Test::Stream::Meta qw/is_tester init_tester/;
use Test::Stream qw/cull tap_encoding OUT_STD OUT_ERR OUT_TODO/;

use Test::Stream::Exporter qw/import exports export_to/;
exports qw{
    listen munge follow_up
    enable_forking cull
    peek_todo push_todo pop_todo set_todo inspect_todo
    is_tester init_tester
    is_modern set_modern
    context peek_context clear_context set_context
    intercept
    state_count state_failed state_plan state_ended is_passing
    current_stream

    disable_tap enable_tap subtest_tap_instant subtest_tap_delayed tap_encoding
    enable_numbers disable_numbers set_tap_outputs get_tap_outputs
};
Test::Stream::Exporter->cleanup();

BEGIN {
    require Test::Stream::Context;
    Test::Stream::Context->import(qw/context inspect_todo/);
    *peek_context  = \&Test::Stream::Context::peek;
    *clear_context = \&Test::Stream::Context::clear;
    *set_context   = \&Test::Stream::Context::set;
    *push_todo     = \&Test::Stream::Context::push_todo;
    *pop_todo      = \&Test::Stream::Context::pop_todo;
    *peek_todo     = \&Test::Stream::Context::peek_todo;
}

sub listen(&)       { Test::Stream->shared->listen($_[0])      }
sub munge(&)        { Test::Stream->shared->munge($_[0])       }
sub follow_up(&)    { Test::Stream->shared->follow_up($_[0])   }
sub enable_forking  { Test::Stream->shared->use_fork()         }
sub disable_tap     { Test::Stream->shared->set_use_tap(0)     }
sub enable_tap      { Test::Stream->shared->set_use_tap(1)     }
sub enable_numbers  { Test::Stream->shared->set_use_numbers(1) }
sub disable_numbers { Test::Stream->shared->set_use_numbers(0) }
sub current_stream  { Test::Stream->shared()                   }
sub state_count     { Test::Stream->shared->count()            }
sub state_failed    { Test::Stream->shared->failed()           }
sub state_plan      { Test::Stream->shared->plan()             }
sub state_ended     { Test::Stream->shared->ended()            }
sub is_passing      { Test::Stream->shared->is_passing         }

sub subtest_tap_instant {
    Test::Stream->shared->set_subtest_tap_instant(1);
    Test::Stream->shared->set_subtest_tap_delayed(0);
}

sub subtest_tap_delayed {
    Test::Stream->shared->set_subtest_tap_instant(0);
    Test::Stream->shared->set_subtest_tap_delayed(1);
}

sub is_modern {
    my ($package) = @_;
    my $meta = is_tester($package) || croak "'$package' is not a tester package";
    return $meta->modern ? 1 : 0;
}

sub set_modern {
    my $package = shift;
    croak "set_modern takes a package and a value" unless @_;
    my $value = shift;
    my $meta = is_tester($package) || croak "'$package' is not a tester package";
    return $meta->set_modern($value);
}

sub set_todo {
    my ($pkg, $why) = @_;
    my $meta = is_tester($pkg) || croak "'$pkg' is not a tester package";
    $meta->set_todo($why);
}

sub set_tap_outputs {
    my %params = @_;
    my $encoding = delete $params{encoding} || 'legacy';
    my $std      = delete $params{std};
    my $err      = delete $params{err};
    my $todo     = delete $params{todo};

    my @bad = keys %params;
    croak "set_tap_output does not recognise these keys: " . join ", ", @bad
        if @bad;

    my $ioset = Test::Stream->shared->io_sets;
    my $enc = $ioset->init_encoding($encoding);

    $enc->[OUT_STD]  = $std  if $std;
    $enc->[OUT_ERR]  = $err  if $err;
    $enc->[OUT_TODO] = $todo if $todo;

    return $enc;
}

sub get_tap_outputs {
    my ($enc) = @_;
    my $set = Test::Stream->shared->io_sets->init_encoding($enc || 'legacy');
    return {
        encoding => $enc || 'legacy',
        std      => $set->[0],
        err      => $set->[1],
        todo     => $set->[2],
    };
}

1;

__END__

=head1 NAME

Test::Stream::API - Single point of access to Test::Stream extendability
features.

=head1 DESCRIPTION

There are times where you want to extend or alter the bahvior of a test file or
test suite. This module collects all the features and tools that
L<Test::Stream> offers for such actions. Everything in this file is accessible
in other places, but with less sugar coating.

=head1 SYNOPSYS

Nothing is exported by default, you must request it.

    use Test::Stream::API qw/ ... /;

=head2 MODIFYING EVENTS

    use Test::Stream::API qw/ munge /;

    munge {
        my ($stream, $event, @subevents) = @_;

        if($event->isa('Test::Stream::Diag')) {
            $event->set_message( "KILROY WAS HERE: " . $event->message );
        }
    };

=head2 REPLACING TAP WITH ALTERNATIVE OUTPUT

    use Test::Stream::API qw/ disable_tap listen /;

    disable_tap();

    listen {
        my $stream = shift;
        my ($event, @subevents) = @_;

        # Tracking results in a db?
        my $id = log_event_to_db($e);
        log_subevent_to_db($id, $_) for @subevents;
    }

=head2 END OF TEST BEHAVIORS

    use Test::Stream::API qw/ follow_up is_passing /;

    follow_up {
        my ($context) = @_;

        if (is_passing()) {
            print "KILROY Says the test file passed!\n";
        }
        else {
            print "KILROY is not happy with you!\n";
        }
    };

=head2 ENABLING FORKING SUPPORT

    use Test::More;
    use Test::Stream::API qw/ enable_forking /;

    enable_forking();

    # This all just works now!
    my $pid = fork();
    if ($pid) { # Parent
        ok(1, "From Parent");
    }
    else { # child
        ok(1, "From Child");
        exit 0;
    }

    done_testing;

B<Note:> Result order between processes is not guarenteed, but the test number
is handled for you meaning you don't need to care.

Results:

    ok 1 - From Child
    ok 2 - From Parent

Or:

    ok 1 - From Parent
    ok 2 - From Child

=head2 REDIRECTING TAP OUTPUT

You may omit any arguments to leave a specific handle unchanged. It is not
possible to set a handle to undef or 0 or any other false value.

    use Test::Stream::API qw/ set_tap_outputs /;

    set_tap_outputs(
        encoding => 'legacy',           # Default,
        std      => $STD_IO_HANDLE,     # equivilent to $TB->output()
        err      => $ERR_IO_HANDLE,     # equivilent to $TB->failure_output()
        todo     => $TODO_IO_HANDLE,    # equivilent to $TB->todo_output()
    );

B<Note:> Each encoding has independant filehandles.

=head1 GENERATING EVENTS

=head2 EASY WAY

The best way to generate an event is through a L<Test::Stream::Context>
object. All events have a method associated with them on the context object.
The method will be the last part of the evene package name lowercased, for
example L<Test::Stream::Event::Ok> can be issued via C<< $context->ok(...) >>.

    use Test::Stream::API qw/ context /;
    my $context = context();
    $context->EVENT_TYPE(...);

The arguments to the event method are the values for event accessors in order,
excluding the C<context>, C<created>, and C<in_subtest> arguments. For instance
here is how the Ok event is defined:

    package Test::Stream::Event::Ok;
    use Test::Stream::Event(
        accessors  => [qw/real_bool name diag .../],
        ...
    );

This means that the C<< $context->ok >> method takes up to 5 arguments. The
first argument is a boolean true/false, the second is the name of the test, and
the third is an arrayref of diagnostics messages or
L<Test::Stream::Event::Diag> objects.

    $context->ok($bool, $name, [$diag]);

Here are the main event methods, as well as their standard arguments:

=over 4

=item $context->ok($bool, $name, \@diag)

Issue an L<Test::Stream::Event::Ok> event.

=item $context->diag($msg)

Issue an L<Test::Stream::Event::Diag> event.

=item $context->note($msg)

Issue an L<Test::Stream::Event::Note> event.

=item $context->plan($max, $directive, $reason)

Issue an L<Test::Stream::Event::Plan> event. C<$max> is the number of expected
tests. C<$directive> is a plan directive such as 'no_plan' or 'skip_all'.
C<$reason> is the reason for the directive (only applicable to skip_all).

=item $context->bail($reason)

Issue an L<Test::Stream::Event::Bail> event.

=back

=head2 HARD WAY

This is not recommended, but it demonstrates just how much the context shortcut
methods do for you.

    # First make a context
    my $context = Test::Stream::Context->new_from_pairs(
        frame     => ..., # Where to report errors
        stream    => ..., # Test::Stream object to use
        encoding  => ..., # encoding from test package meta-data
        in_todo   => ..., # Are we in a todo?
        todo      => ..., # Which todo message should be used?
        modern    => ..., # Is the test package modern?
        pid       => ..., # Current PID
        skip      => ..., # Are we inside a 'skip' state?
        provider  => ..., # What tool created the context?
    );

    # Make the event
    my $ok = Test::Stream::Event::Ok->new_from_pairs(
        # Should reflect where the event was produced, NOT WHERE ERRORS ARE REPORTED
        created => [__PACKAGE__, __FILE__,              __LINE__],
        context => $context,     # A context is required
        in_subtest => 0,

        bool => $bool,
        name => $name,
        diag => \@diag,
    );

    # Send the event to the stream.
    Test::Stream->shared->send($ok);


=head1 EXPORTED FUNCTIONS

All of these are functions. These functions all effect the current-shared
L<Test::Stream> object only.

=head2 EVENT MANAGEMENT

These let you install a callback that is triggered for all primary events. The
first argument is the L<Test::Stream> object, the second is the primary
L<Test::Stream::Event>, any additional arguments are subevents. All subevents
are L<Test::Stream::Event> objects which are directly tied to the primary one.
The main example of a subevent is the failure L<Test::Stream::Event::Diag>
object associated with a failed L<Test::Stream::Event::Ok>, events within a
subtest are another example.

=over 4

=item listen { my ($stream, $event, @subevents) = @_; ... }

Listen callbacks happen just after TAP is rendered (or just after it would be
rendered if TAP is disabled).

=item munge { my ($stream, $event, @subevents) = @_; ... }

Muinspect_todonge callbacks happen just before TAP is rendered (or just before
it would be rendered if TAP is disabled).

=back

=head2 POST-TEST BEHAVIOR

=over 4

=item follow_up { my ($context) = @_; ... }

A followup callback allows you to install behavior that happens either when
C<done_testing()> is called, or when the test file completes.

B<CAVEAT:> If done_testing is not used, the callback will happen in the
C<END {...}> block used by L<Test::Stream> to enact magic at the end of the
test.

=back

=head2 CONCURRENCY

=over 4

=item enable_forking()

Turns forking support on. This turns on a synchronization method that *just
works* when you fork inside a test. This must be turned on prior to any
forking.

=item cull()

This can only be called in the main process or thread. This is a way to
manually pull in results from other processes or threads. Typically this
happens automatically, but this allows you to ensure results have been gathered
by a specific point.

=back

=head2 CONTROL OVER TAP

=over 4

=item enable_tap()

Turn TAP on (on by default).

=item disable_tap()

Turn TAP off.

=item enable_numbers()

Show test numbers when rendering TAP.

=item disable_numbers()

Do not show test numbers when rendering TAP.

=item subtest_tap_instant()

This is the default way to render subtests:

    # Subtest: a_subtest
        ok 1 - pass
        1..1
    ok 1 - a_subtest

Using this will automatically turn off C<subtest_tap_delayed>

=item subtest_tap_delayed()

This is an alternative way to render subtests, this method waits until the
subtest is complete then renders it in a structured way:

    ok 1 - a_subtest {
        ok 1 - pass
        1..1
    }

Using this will automatically turn off C<subtest_tap_instant>

=item tap_encoding($ENCODING)

This lets you change the encoding for TAP output. This only effects the current
test package.

=item set_tap_outputs(encoding => 'legacy', std => $IO, err => $IO, todo => $IO)

This lets you replace the filehandles used to output TAP for any specific
encoding. All fields are optional, any handles not specified will not be
changed. The C<encoding> parameter defaults to 'legacy'.

B<Note:> The todo handle is used for failure output inside subtests where the
subtest was started already in todo.

=item $hashref = get_tap_outputs($encoding)

'legacy' is used when encoding is not specified.

Returns a hashref with the output handles:

    {
        encoding => $encoding,
        std      => $STD_HANDLE,
        err      => $ERR_HANDLE,
        todo     => $TODO_HANDLE,
    }

B<Note:> The todo handle is used for failure output inside subtests where the
subtest was started already in todo.

=back

=head2 TEST PACKAGE METADATA

=over 4

=item $bool = is_modern($package)

Check if a test package has the 'modern' flag.

B<Note:> Throws an exception if C<$package> is not already a test package.

=item set_modern($package, $value)

Turn on the modern flag for the specified test package.

B<Note:> Throws an exception if C<$package> is not already a test package.

=back

=head2 TODO MANAGEMENT

=over 4

=item push_todo($todo)

=item $todo = pop_todo()

=item $todo = peek_todo()

These can be used to manipulate a global C<todo> state. When a true value is at
the top of the todo stack it will effect any events generated via an
L<Test::Stream::Context> object. Typically all events are generated this way.

=item set_todo($package, $todo)

This lets you set the todo state for the specified test package. This will
throw an exception if the package is not a test package.

=item $todo_hashref = inspect_todo($package)

=item $todo_hashref = inspect_todo()

This lets you inspect the TODO state. Optionally you can specify a package to
inspect. The return is a hashref with several keys:

    {
        TODO => $TODO_STACK_ARRAYREF,
        TB   => $TEST_BUILDER_TODO_STATE,
        META => $PACKAGE_METADATA_TODO_STATE,
        PKG  => $package::TODO,
    }

This lets you see what todo states are set where. This is primarily useful when
debugging to see why something is unexpectedly TODO, or when something is not
TODO despite expectations.

=back

=head2 TEST PACKAGE MANAGEMENT

=over 4

=item $meta = is_tester($package)

Check if a package is a tester, if it is the meta-object for the tester is
returned.

=item $meta = init_tester($package)

Set the package as a tester and return the meta-object. If the package is
already a tester it will return the existing meta-object.

=back

=head2 CONTEXTUAL INFORMATION

=over 4

=item $context = context()

This will get the correct L<Test::Stream::Context> object. This may be one that
was previously initialized, or it may generate a new one. Read the
L<Test::Stream::Context> documentation for more info.

=item $stream = current_stream()

This will return the current L<Test::Stream> Object. L<Test::Stream> objects
typically live on a global stack, the topmost item on the stack is the one that
is normally used.

=back

=head2 CAPTURING EVENTS

=over 4

=item $events_arrayref = intercept { ... };

Any events generated inside the codeblock will be intercepted and returned. No
events within the block will go to the real L<Test::Stream> instance.

B<Note:> This comes from the L<Test::Stream::Tester> package which provides
addiitonal tools that are useful for testing/validating events.

=back

=head2 TEST STATE

=over 4

=item $num = state_count()

Check how many tests have been run.

=item $num = state_failed()

Check how many tests have failed.

=item $plan_event = state_plan()

Check if a plan has been issued, if so the L<Test::Stream::Event::Plan>
instance will be returned.

=item $bool = state_ended()

True if the test is complete (after done_testing).

=item $bool = is_passing()

Check if the test state is passing.

=back

=encoding utf8

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
