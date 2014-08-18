package Test::Builder::Stream;
use strict;
use warnings;

use Carp qw/confess croak/;
use Scalar::Util qw/reftype blessed/;
use Test::Builder::Threads;
use Test::Builder::Util qw/accessors accessor atomic_deltas try protect/;

accessors qw/plan bailed_out/;
atomic_deltas qw/tests_run tests_failed/;

accessor no_ending    => sub { 0 };
accessor is_passing   => sub { 1 };
accessor _listeners   => sub {{ }};
accessor _mungers     => sub {{ }};
accessor _munge_order => sub {[ ]};
accessor _follow_up   => sub {{ }};

sub pid { shift->{pid} }

{
    my ($root, @shared);

    sub root { $root };

    sub shared {
        $root ||= __PACKAGE__->new;
        push @shared => $root unless @shared;
        return $shared[-1];
    };

    sub clear { $root = undef; @shared = () }

    sub intercept {
        my $class = shift;
        my ($code) = @_;

        confess "argument to intercept must be a coderef, got: $code"
            unless reftype $code eq 'CODE';

        my $orig = $class->intercept_start();
        my ($ok, $error) = try { $code->($shared[-1]) };

        $class->intercept_stop($orig);
        die $error unless $ok;
        return $ok;
    }

    sub intercept_start {
        my $class = shift;
        my $new = $_[0] || $class->new(no_follow => 1) || die "Internal error!";
        push @shared => $new;
        return $new;
    }

    sub intercept_stop {
        my $class = shift;
        my ($orig) = @_;
        confess "intercept nesting inconsistancy!"
            unless $shared[-1] == $orig;
        return pop @shared;
    }
}

sub new {
    my $class = shift;
    my %params = @_;
    my $self = bless { pid => $$ }, $class;

    share($self->{tests_run});
    share($self->{tests_failed});

    $self->use_tap         if $params{use_tap};
    $self->use_lresults    if $params{use_lresults};
    $self->legacy_followup unless $params{no_follow};

    return $self;
}

sub follow_up {
    my $self = shift;
    my ($type, @action) = @_;
    croak "'$type' is not an event type"
        unless $type && $type->isa('Test::Builder::Event');

    if (@action) {
        my ($sub) = @action;
        croak "The second argument to follow_up() must be a coderef, got: $sub"
            if $sub && !(ref $sub && reftype $sub eq 'CODE');

        $self->_follow_up->{$type} = $sub;
    }

    return $self->_follow_up->{$type};
}

sub legacy_followup {
    my $self = shift;
    $self->_follow_up({
        'Test::Builder::Event::Bail' => sub { exit 255 },
        'Test::Builder::Event::Plan' => sub {
            my ($plan) = @_;
            return unless $plan->directive;
            return unless $plan->directive eq 'SKIP';
            exit 0;
        },
    });
}

sub exception_followup {
    my $self = shift;

    $self->_follow_up({
        'Test::Builder::Event::Bail' => sub {die $_[0]},
        'Test::Builder::Event::Plan' => sub {
            my $plan = shift;
            return unless $plan->directive;
            return unless $plan->directive eq 'SKIP';
            die $plan;
        },
    });
}

sub expected_tests {
    my $self = shift;
    my $plan = $self->plan;
    return undef unless $plan;
    return $plan->max;
}

sub listener {
    my $self = shift;
    my ($id) = @_;
    confess("You must provide an ID for your listener") unless $id;

    confess("Listener ID's may not start with 'LEGACY_', those are reserved")
        if $id =~ m/^LEGACY_/ && caller ne __PACKAGE__;

    return $self->_listeners->{$id};
}

sub listen {
    my $self = shift;
    my ($id, $listener) = @_;

    confess("You must provide an ID for your listener") unless $id;

    confess("Listener ID's may not start with 'LEGACY_', those are reserved")
        if $id =~ m/^LEGACY_/ && caller ne __PACKAGE__;

    confess("Listeners must be code refs, or objects that implement handle(), got: $listener")
        unless $listener && (
            (reftype $listener && reftype $listener eq 'CODE')
            ||
            (blessed $listener && $listener->can('handle'))
        );

    my $listeners = $self->_listeners;

    confess("There is already a listener with ID: $id")
        if $listeners->{$id};

    $listeners->{$id} = $listener;
    return sub { $self->unlisten($id) };
}

sub unlisten {
    my $self = shift;
    my ($id) = @_;

    confess("You must provide an ID for your listener") unless $id;

    confess("Listener ID's may not start with 'LEGACY_', those are reserved")
        if $id =~ m/^LEGACY_/ && caller ne __PACKAGE__;

    my $listeners = $self->_listeners;

    confess("There is no listener with ID: $id")
        unless $listeners->{$id};

    delete $listeners->{$id};
}

sub munger {
    my $self = shift;
    my ($id) = @_;
    confess("You must provide an ID for your munger") unless $id;
    return $self->_mungers->{$id};
}

sub munge {
    my $self = shift;
    my ($id, $munger) = @_;

    confess("You must provide an ID for your munger") unless $id;

    confess("Mungers must be code refs, or objects that implement handle(), got: $munger")
        unless $munger && (
            (reftype $munger && reftype $munger eq 'CODE')
            ||
            (blessed $munger && $munger->can('handle'))
        );

    my $mungers = $self->_mungers;

    confess("There is already a munger with ID: $id")
        if $mungers->{$id};

    push @{$self->_munge_order} => $id;
    $mungers->{$id} = $munger;

    return sub { $self->unmunge($id) };
}

sub unmunge {
    my $self = shift;
    my ($id) = @_;
    my $mungers = $self->_mungers;

    confess("You must provide an ID for your munger") unless $id;

    confess("There is no munger with ID: $id")
        unless $mungers->{$id};

    $self->_munge_order([ grep { $_ ne $id } @{$self->_munge_order} ]);
    delete $mungers->{$id};
}

sub send {
    my $self = shift;
    my ($item) = @_;

    # The redirect will return true if it intends to redirect, we should then return.
    # If it returns false that means we do not need to redirect and should act normally.
    if (my $redirect = $self->fork) {
        return if $redirect->handle(@_);
    }

    my $items = [$item];
    for my $munger_id (@{$self->_munge_order}) {
        my $new_items = [];
        my $munger = $self->munger($munger_id) || next;

        for my $item (@$items) {
            push @$new_items => reftype $munger eq 'CODE' ? $munger->($item) : $munger->handle($item);
        }

        $items = $new_items;
    }

    for my $item (@$items) {
        if ($item->isa('Test::Builder::Event::Plan')) {
            $self->plan($item);
        }

        if ($item->isa('Test::Builder::Event::Bail')) {
            $self->bailed_out($item);
        }

        if ($item->isa('Test::Builder::Event::Ok')) {
            $self->tests_run(1);
            $self->tests_failed(1) unless $item->bool;
        }

        for my $listener (values %{$self->_listeners}) {
            protect {
                if (reftype $listener eq 'CODE') {
                    $listener->($item);
                    if ($item->can('diag') && $item->diag) {
                        $listener->($_) for grep {$_} @{$item->diag};
                    }
                }
                else {
                    $listener->handle($item);
                    if ($item->can('diag') && $item->diag) {
                        $listener->handle($_) for grep {$_} @{$item->diag};
                    }
                }
            };
        }
    }

    for my $item (@$items) {
        my $type = blessed $item;
        my $follow = $self->follow_up($type) || next;
        $follow->($item);
    }
}

sub tap { shift->listener('LEGACY_TAP') }

sub use_tap {
    my $self = shift;
    return if $self->tap;
    require Test::Builder::Formatter::TAP;
    $self->listen(LEGACY_TAP => Test::Builder::Formatter::TAP->new());
}

sub no_tap {
    my $self = shift;
    $self->unlisten('LEGACY_TAP') if $self->tap;
    return;
}

sub lresults { shift->listener('LEGACY_RESULTS') }

sub use_lresults {
    my $self = shift;
    return if $self->lresults;
    require Test::Builder::Formatter::LegacyResults;
    $self->listen(LEGACY_RESULTS => Test::Builder::Formatter::LegacyResults->new());
}

sub no_lresults {
    my $self = shift;
    $self->unlisten('LEGACY_RESULTS') if $self->lresults;
    return;
}

sub fork { shift->{'fork'} }

sub use_fork {
    my $self = shift;

    return if $self->{fork};

    require Test::Builder::Fork;
    $self->{fork} = Test::Builder::Fork->new;
}

sub no_fork {
    my $self = shift;

    return unless $self->{fork};

    delete $self->{fork}; # Turn it off.
}

sub spawn {
    my $self = shift;
    my (%params) = @_;

    my $new = blessed($self)->new();

    $new->{fork} = $self->{fork};

    my $refs = {
        listeners => $self->_listeners,
        mungers   => $self->_mungers,
    };

    $new->_munge_order([@{$self->_munge_order}]);

    for my $type (keys %$refs) {
        for my $key (keys %{$refs->{$type}}) {
            next if $key eq 'LEGACY_TAP';
            next if $key eq 'LEGACY_RESULTS';
            $new->{"_$type"}->{$key} = sub {
                my $item = $refs->{$type}->{$key} || return;
                return $item->(@_) if reftype $item eq 'CODE';
                $item->handle(@_);
            };
        }
    }

    if ($self->tap && !$params{no_tap}) {
        $new->use_tap;
        $new->tap->io_sets({%{$self->tap->io_sets}});
    }

    $new->use_lresults if $self->lresults && !$params{no_lresults};

    return $new;
}

1;

__END__

=head1 NAME

Test::Bulder::Stream - The stream between Test::Builder and the formatters.

=head1 TEST COMPONENT MAP

  [Test Script] > [Test Tool] > [Test::Builder] > [Test::Bulder::Stream] > [Event Formatter]
                                                             ^
                                                       You are here

A test script uses a test tool such as L<Test::More>, which uses Test::Builder
to produce events. The events are sent to L<Test::Builder::Stream> which then
forwards them on to one or more formatters. The default formatter is
L<Test::Builder::Fromatter::TAP> which produces TAP output.

=head1 DESCRIPTION

This module is responsible for taking event object from L<Test::Builder> and
forwarding them to the listeners/formatters. It also has facilities for
intercepting the events and munging them. Examples of this are forking support
and L<Test::Tester2>.

=head1 METHODS

=head2 CONSTRUCTION/FETCHING

It is possible to construct an independant stream object using C<new()>. Most
of the time however you do not want an independant stream, you want the shared
stream. The shared stream is the stream to which all test output should be
sent. The shared stream is actually a stack, and the topmost stream should
always be used unless you I<really> know what you are doing.

=over 4

=item $stream = $class->new();

=item $stream = $class->new(use_tap => 1);

=item $stream = $class->new(use_lresults => 1);

=item $stream = $class->new(no_follow => 1);

Create a new/independant stream object. No listeners by default, but you can
specify 'use_tap' and/or 'use_lresults' to add those listeners.

no_follow will disable the legacy behavior of exiting on bailout, or when a
skip_all plan is encountered.

=item $stream = $class->shared()

Get the topmost stream on the shared stream stack.

=item $stream = $class->root()

Get the bottom-most stream in the shared stack.

=item $class->clear()

Remove all streams from the shared stack.

=item $stream->intercept(sub { ... })

Push a new stream onto the stack, run the specified code, then pop the new stream off of the stack.

=item $stream->intercept_start()

=item $stream->intercept_start($stream)

Push a new stream onto the top of the shared stack. Returns the $stream that
was pushed. Optionally you can provide a stream to push instead of letting it
make a new one for you.

=item $stream->intercept_stop($stream)

Pop the topmost stream. You B<must> pass in the stream you expect to be popped.
If the stream you pass in does not match the one popped an exception will be
thrown.

=item $child = $stream->spawn()

=item $child = $stream->spawn(no_tap => 1)

=item $child = $stream->spawn(no_lresults => 1)

Spawn a cloned stream. The clone will have all the same listeners and mungers
as the parent. Removing a listener from the parent will be reflected in the
child, but the reverse is not true.

TAP and legacy results are special, so they are also cloned instead of carrying
them over. Removing them from the parent will not remove them from the child.

=back

=head2 ACCESSORS

=over 4

=item $plan = $stream->plan()

=item $stream->plan($plan)

=item $stream->plan(undef)

Get/Set the plan, usually done for you when a plan object is encountered.

=item $pid = $stream->pid()

Get the original PID in which the stream object was built.

=item $num = $stream->tests_run()

=item $stream->tests_run($delta)

Get the number of tests run. Optionally you can provide a delta, the number of
tests run will be adjusted by the delta.

=item $stream->tests_failed($delta)

Get the number of tests failed. Optionally you can provide a delta, the number of
tests failed will be adjusted by the delta.

=item $bool = $stream->is_passing()

=item $stream->is_padding($bool)

Check if tests are passing, optinally you can pass in a $bool to reset this.

=back

=head2 BEHAVIOR CONTROL

=over 4

=item $bool = $stream->no_ending()

=item $stream->no_ending($bool)

enable/disable endings. Defaults to false.

=item $action = $stream->follow_up('Test::Builder::Event::...')

=item $stream->follow_up('Test::Builder::Event::...' => sub { ($r) = @_; ... })

Fetch or Specify a followup behavior to run after all listeners have gotten an
event of the specified type.

=item $stream->legacy_followup

switch to legacy follow-up behavior. This means exiting for bailout or skip_all.

=item $stream->exception_followup

Switch to exception follow-up behavior. This means throwing an exception on
bailout or skip_all. This is necessary for intercepting events.

=item $fork_handler = $stream->fork

Get the fork handler.

=item $stream->use_fork

Enable forking

=item $stream->no_fork

Disable forking.

=back

=head2 PLANNING

=over 4

=item $count = $stream->expected_tests

Get the expected number of tests, if any.

=back

=head2 LISTENER CONTROL

=head3 NORMAL LISTENERS

=over 4

=item $L = $stream->listener($id)

Get the listener with the given ID.

=item $unlisten = $stream->listen($id, $listener)

Add a listener with the given ID. The listener can either be a coderef that
takes a event object as an argument, or any object that implements a handle()
method.

This method returns a coderef that can be used to remove the listener. It is
better to use this method over unlisten as it will remove the listener from the
original stream object and any child stream objects.

=item $stream->unlisten($id)

Remove a listener by id.

=back

=head3 LEGACY TAP LISTENER

=over 4

=item $L = $stream->tap

Get the tap listener object (if TAP is enabled)

=item $stream->use_tap

Enable the legacy tap listener.

=item $stream->no_tap

Disable the legacy tap listener.

=back

=head3 LEGACY EVENTS LISTENER

=over 4

=item $L = $stream->lresults

Get the Legacy Result lsitener object.

=item $stream->use_lresults

Enable legacy results

=item $stream->no_lresults

Disable legacy results

=back

=head2 MUNGING EVENTS

Mungers are expected to take an event object and return 1 or more event
objects to replace the original. They are also allowed to simply modify the
original, or return nothing to remove it.

Mungers are run in the order they are added, it is possible that the first
munger will remove an event in which case later mungers will never see it.
Listeners get the product of running all the mungers on the original event.

=over 4

=item $M = $stream->munger($id)

Get the munger with the specified ID.

=item $unmunge = $stream->munge($id => $munger)

Add a munger. The munger may be a coderef that takes a single event object as
an argument, or it can be any object that implements a handle() method.

This method returns a coderef that can be used to remove the munger. It is
better to use this method over unmunge as it will remove the munger from the
original stream object and any child stream objects.

=item $stream->unmunge($id)

Remove a munger by id.

=back

=head2 PROVIDING EVENTS

=over 4

=item $stream->send($event)

Send a event to all listeners (also goes through munging and the form handler,
etc.)

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
